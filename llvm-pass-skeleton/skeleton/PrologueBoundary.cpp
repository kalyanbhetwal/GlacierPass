#include <llvm/CodeGen/MachineFunction.h>
#include <llvm/CodeGen/MachineFunctionPass.h>
#include <llvm/CodeGen/MachineInstrBuilder.h>
#include <llvm/CodeGen/TargetInstrInfo.h>
#include <llvm/CodeGen/TargetRegisterInfo.h>
#include <llvm/CodeGen/TargetSubtargetInfo.h>
#include <llvm/MC/MCContext.h>
#include <llvm/Support/raw_ostream.h>

using namespace llvm;

namespace {

/// A machine function pass that inserts a custom boundary marker
/// at the beginning of each function before any prologue code
class PrologueBoundaryPass : public MachineFunctionPass {
public:
    static char ID;

    PrologueBoundaryPass() : MachineFunctionPass(ID) {}

    StringRef getPassName() const override {
        return "Prologue Boundary Insertion Pass";
    }

    bool runOnMachineFunction(MachineFunction &MF) override {
        // Skip functions with "discard" attribute - they handle their own boundaries
        const Function &F = MF.getFunction();
        if (F.hasFnAttribute("discard")) {
            outs() << "Skipping prologue boundary for discard function: " << MF.getName() << "\n";
            return false;
        }

        const TargetInstrInfo *TII = MF.getSubtarget().getInstrInfo();
        bool Modified = false;

        // Boundary value for normal functions
        const uint16_t NORMAL_BOUNDARY = 0xBEEF;

        // ============================================================
        // PART 1: Insert ANNOTATION_LABEL at the beginning (before prologue)
        // ============================================================
        MachineBasicBlock &EntryMBB = MF.front();
        MachineBasicBlock::iterator InsertPos = EntryMBB.begin();

        DebugLoc DL;
        if (InsertPos != EntryMBB.end()) {
            DL = InsertPos->getDebugLoc();
        }

        // Insert ANNOTATION_LABEL with normal boundary value at the very beginning
        BuildMI(EntryMBB, InsertPos, DL, TII->get(TargetOpcode::ANNOTATION_LABEL))
            .addImm(NORMAL_BOUNDARY)
            .setMIFlag(MachineInstr::FrameSetup);

        // Get the PUSH16i and PUSH16r opcodes
        unsigned PushImmOpcode = 0, PushRegOpcode = 0;
        for (unsigned i = 0; i < TII->getNumOpcodes(); ++i) {
            StringRef Name = TII->getName(i);
            if (Name == "PUSH16i") {
                PushImmOpcode = i;
            } else if (Name == "PUSH16r") {
                PushRegOpcode = i;
            }
        }

        // Get R4 register
        const TargetRegisterInfo *TRI = MF.getSubtarget().getRegisterInfo();
        unsigned R4Reg = 0;
        for (unsigned Reg = 1; Reg < TRI->getNumRegs(); ++Reg) {
            if (TRI->getName(Reg) == StringRef("R4")) {
                R4Reg = Reg;
                break;
            }
        }

        if (PushImmOpcode) {
            // Push the normal boundary value onto the stack
            BuildMI(EntryMBB, InsertPos, DL, TII->get(PushImmOpcode))
                .addImm(NORMAL_BOUNDARY)
                .setMIFlag(MachineInstr::FrameSetup);

            outs() << "Inserted PUSH " << format("0x%04X", NORMAL_BOUNDARY)
                   << " (" << NORMAL_BOUNDARY << ") for normal function: " << MF.getName() << "\n";
        } else {
            outs() << "Warning: PUSH16i not found, cannot push boundary value\n";
        }

        // Push R4 to save it
        if (PushRegOpcode && R4Reg) {
            BuildMI(EntryMBB, InsertPos, DL, TII->get(PushRegOpcode))
                .addReg(R4Reg)
                .setMIFlag(MachineInstr::FrameSetup);

            outs() << "Inserted PUSH R4 for normal function: " << MF.getName() << "\n";
        } else {
            outs() << "Warning: PUSH16r or R4 not found\n";
        }

        // Get MOV16rm opcode to load from memory
        unsigned MovRmOpcode = 0;
        for (unsigned i = 0; i < TII->getNumOpcodes(); ++i) {
            if (TII->getName(i) == "MOV16rm") {
                MovRmOpcode = i;
                break;
            }
        }

        // Get the stack pointer register (R1/SP)
        unsigned SPReg = 0;
        for (unsigned Reg = 1; Reg < TRI->getNumRegs(); ++Reg) {
            if (TRI->getName(Reg) == StringRef("R1")) {
                SPReg = Reg;
                break;
            }
        }

        // Load return address from SP+6 into R4
        // Stack layout at this point: [boundary][saved R4][return address] <- SP points here
        // SP+0 is current top, SP+2 has saved R4, SP+4 has boundary, SP+6 has return address
        if (MovRmOpcode && R4Reg && SPReg) {
            BuildMI(EntryMBB, InsertPos, DL, TII->get(MovRmOpcode))
                .addReg(R4Reg, RegState::Define)
                .addReg(SPReg)
                .addImm(6)  // Offset of 6 bytes from SP
                .setMIFlag(MachineInstr::FrameSetup);

            outs() << "Inserted MOV 6(SP), R4 to save return address for normal function: "
                   << MF.getName() << "\n";
        } else {
            outs() << "Warning: MOV16rm, R4, or SP not found\n";
        }

        outs() << "Inserted prologue boundary (" << format("0x%04X", NORMAL_BOUNDARY)
               << ") for normal function: " << MF.getName()
               << " at the beginning (before prologue)\n";
        Modified = true;

        // ============================================================
        // PART 2: Insert POP R4 and adjust stack before each RET/RETI instruction
        // ============================================================
        // Get the actual opcodes by name (MSP430-specific)
        unsigned RetOpcode = 0, RetiOpcode = 0;
        for (unsigned i = 0; i < TII->getNumOpcodes(); ++i) {
            StringRef Name = TII->getName(i);
            if (Name == "RET") RetOpcode = i;
            if (Name == "RETI") RetiOpcode = i;
        }

        // Get the ADD16ri opcode for stack pointer adjustment
        unsigned AddOpcode = 0;
        for (unsigned i = 0; i < TII->getNumOpcodes(); ++i) {
            if (TII->getName(i) == "ADD16ri") {
                AddOpcode = i;
                break;
            }
        }

        // Get POP16r opcode
        unsigned PopRegOpcode = 0;
        for (unsigned i = 0; i < TII->getNumOpcodes(); ++i) {
            if (TII->getName(i) == "POP16r") {
                PopRegOpcode = i;
                break;
            }
        }

        if (!AddOpcode || !SPReg || !PopRegOpcode || !R4Reg) {
            outs() << "Warning: Could not find ADD16ri, SP, POP16r, or R4 register\n";
            return Modified;
        }

        // Iterate through all basic blocks
        for (MachineBasicBlock &MBB : MF) {
            // Look for return instructions
            for (MachineBasicBlock::iterator I = MBB.begin(); I != MBB.end(); ++I) {
                MachineInstr &MI = *I;

                // Check if this is a RET or RETI instruction
                if (MI.getOpcode() == RetOpcode || MI.getOpcode() == RetiOpcode) {
                    DebugLoc RetDL = MI.getDebugLoc();

                    // First: Pop R4 to restore it
                    BuildMI(MBB, I, RetDL, TII->get(PopRegOpcode))
                        .addReg(R4Reg, RegState::Define)
                        .setMIFlag(MachineInstr::FrameDestroy);

                    // Second: Insert ADD #2, SP to remove the boundary value from the stack
                    BuildMI(MBB, I, RetDL, TII->get(AddOpcode))
                        .addReg(SPReg, RegState::Define)
                        .addReg(SPReg)
                        .addImm(2)
                        .setMIFlag(MachineInstr::FrameDestroy);

                    outs() << "Inserted POP R4 and ADD #2, SP before return in function: "
                           << MF.getName() << "\n";
                    Modified = true;
                }
            }
        }

        return Modified;
    }
};

} // end anonymous namespace

char PrologueBoundaryPass::ID = 0;

// Register the pass
static RegisterPass<PrologueBoundaryPass> X(
    "prologue-boundary",
    "Insert custom boundary before prologue",
    false, // is CFG only
    false  // is analysis
);
