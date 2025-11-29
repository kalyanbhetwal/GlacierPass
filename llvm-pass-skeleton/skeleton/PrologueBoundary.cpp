//===----------------------------------------------------------------------===//
//
// Prologue Boundary Insertion Pass
//
// This pass inserts task-specific boundary markers and stack size information
// at the beginning of each function for runtime stack tracking and task
// identification.
//
//===----------------------------------------------------------------------===//
//
// OVERVIEW:
// ---------
// This pass instruments MSP430 functions by inserting boundary markers and
// stack size metadata at function entry and cleanup code at function exit.
// The boundary values identify different task types (discard, immediate, normal).
//
// TASK TYPES AND BOUNDARY VALUES:
// --------------------------------
// - discard:   0xDEAD - Functions marked with "discard" attribute
// - immediate: 0xCAFE - Functions marked with "immediate" attribute
// - normal:    0xBEEF - All other functions (default)
//
// STACK LAYOUT AFTER INSTRUMENTATION:
// ------------------------------------
// Prologue (entry):
//   1. PUSH #<boundary_value>             (2 bytes on stack)
//   2. PUSH #<stack_size>                 (2 bytes on stack)
//
//   Total added to stack: 4 bytes
//
// Epilogue (before return):
//   1. ADD #4, SP                         (remove boundary + stack_size)
//
// STACK SIZE INFORMATION:
// -----------------------
// The stack size is obtained from MachineFrameInfo::getStackSize() and includes:
//   - Local variables (compile-time known sizes)
//   - Spilled registers (from register allocation)
//   - Saved callee-saved registers
//   - Alignment padding
//
// The stack size does NOT include:
//   - The 4 bytes added by this pass (boundary + stack_size)
//   - Dynamic allocations (alloca, VLAs)
//   - Stack usage from nested function calls
//
// EXAMPLE GENERATED CODE:
// -----------------------
// For a function with "immediate" attribute and stack size of 8 bytes:
//
//   myFunction:
//       ; Inserted by this pass:
//       PUSH #0xCAFE        ; Boundary marker for immediate task
//       PUSH #8             ; Stack size (does not include the 4 bytes we add)
//
//       ; Original function prologue and body...
//
//       ; Inserted by this pass before return:
//       ADD #4, SP          ; Remove boundary and stack_size from stack
//       RET
//
//===----------------------------------------------------------------------===//

#include <llvm/CodeGen/MachineFunction.h>
#include <llvm/CodeGen/MachineFunctionPass.h>
#include <llvm/CodeGen/MachineInstrBuilder.h>
#include <llvm/CodeGen/MachineFrameInfo.h>
#include <llvm/CodeGen/TargetInstrInfo.h>
#include <llvm/CodeGen/TargetRegisterInfo.h>
#include <llvm/CodeGen/TargetSubtargetInfo.h>
#include <llvm/MC/MCContext.h>
#include <llvm/Support/raw_ostream.h>

using namespace llvm;

namespace {

/// A machine function pass that inserts custom boundary markers and stack size
/// information at the beginning of each function for task identification and
/// stack tracking purposes.
class PrologueBoundaryPass : public MachineFunctionPass {
public:
    static char ID;

    PrologueBoundaryPass() : MachineFunctionPass(ID) {}

    StringRef getPassName() const override {
        return "Prologue Boundary Insertion Pass";
    }

    bool runOnMachineFunction(MachineFunction &MF) override {
        const Function &F = MF.getFunction();
        const TargetInstrInfo *TII = MF.getSubtarget().getInstrInfo();
        bool Modified = false;

        // Boundary values for different task types
        // These are pushed onto the stack and can be used at runtime to identify
        // the task type and track stack usage.
        const uint16_t NORMAL_BOUNDARY = 0xBEEF;      // Default functions
        const uint16_t IMMEDIATE_BOUNDARY = 0xCAFE;   // "immediate" attribute
        const uint16_t DISCARD_BOUNDARY = 0xDEAD;     // "discard" attribute

        // Determine which boundary to use based on function attribute
        bool isDiscard = F.hasFnAttribute("discard");
        bool isImmediate = F.hasFnAttribute("immediate");

        uint16_t boundaryValue;
        const char* taskType;

        if (isDiscard) {
            boundaryValue = DISCARD_BOUNDARY;
            taskType = "discard";
        } else if (isImmediate) {
            boundaryValue = IMMEDIATE_BOUNDARY;
            taskType = "immediate";
        } else {
            boundaryValue = NORMAL_BOUNDARY;
            taskType = "normal";
        }

        // ============================================================
        // PART 1: Insert boundary marker and stack size at the beginning
        // ============================================================
        MachineBasicBlock &EntryMBB = MF.front();

        // Find the first non-FrameSetup instruction to insert BEFORE all frame setup
        // This ensures our boundary is truly at the top of the function
        auto InsertPos = EntryMBB.begin();

        // Skip any existing FrameSetup instructions and insert at the very beginning
        // We want to insert before the standard prologue
        InsertPos = EntryMBB.begin();

        DebugLoc DL;
        if (InsertPos != EntryMBB.end()) {
            DL = InsertPos->getDebugLoc();
        }

        // Get the PUSH16i opcode
        unsigned PushImmOpcode = 0;
        for (unsigned i = 0; i < TII->getNumOpcodes(); ++i) {
            StringRef Name = TII->getName(i);
            if (Name == "PUSH16i") {
                PushImmOpcode = i;
                break;
            }
        }

        // Get the stack pointer register
        // For MSP430, SP is R1 - we need to find it by name or use the known register number
        const TargetRegisterInfo *TRI = MF.getSubtarget().getRegisterInfo();
        unsigned SPReg = 0;

        // Try to find SP by iterating through all registers
        for (unsigned Reg = 1; Reg < TRI->getNumRegs(); ++Reg) {
            const char* RegName = TRI->getName(Reg);
            // Check for SP, R1, or r1
            if (RegName && (strcmp(RegName, "SP") == 0 || strcmp(RegName, "R1") == 0 || strcmp(RegName, "r1") == 0)) {
                SPReg = Reg;
                outs() << "Found stack pointer register: " << RegName << " (" << Reg << ")\n";
                break;
            }
        }

        if (!SPReg) {
            outs() << "Warning: Could not get stack pointer register\n";
            return Modified;
        }

        if (PushImmOpcode) {
            // Push the appropriate boundary value onto the stack
            BuildMI(EntryMBB, InsertPos, DL, TII->get(PushImmOpcode))
                .addImm(boundaryValue)
                .setMIFlag(MachineInstr::FrameSetup);

            outs() << "Inserted PUSH " << format("0x%04X", boundaryValue)
                   << " (" << boundaryValue << ") for " << taskType
                   << " function: " << MF.getName() << "\n";
        } else {
            outs() << "Warning: PUSH16i not found, cannot push boundary value\n";
        }

        // Get stack size and push it
        // NOTE: This stack size is the statically-determined frame size and does NOT
        // include the 4 bytes we're adding (boundary + stack_size itself).
        // It includes: local variables, spilled registers, saved registers, and padding.
        const MachineFrameInfo &MFI = MF.getFrameInfo();
        uint64_t stackSize = MFI.getStackSize();

        if (PushImmOpcode) {
            // Push the stack size onto the stack
            // This allows runtime code to know how much stack this function allocated
            BuildMI(EntryMBB, InsertPos, DL, TII->get(PushImmOpcode))
                .addImm(stackSize)
                .setMIFlag(MachineInstr::FrameSetup);

            outs() << "Inserted PUSH stack size (" << stackSize << ") for " << taskType
                   << " function: " << MF.getName() << "\n";
        }

        outs() << "Inserted prologue boundary (" << format("0x%04X", boundaryValue)
               << ") for " << taskType << " function: " << MF.getName()
               << " at the beginning (before prologue)\n";
        Modified = true;

        // ============================================================
        // PART 2: Adjust stack before each return instruction
        // ============================================================
        // Get the ADD16ri opcode for stack pointer adjustment
        unsigned AddOpcode = 0;
        for (unsigned i = 0; i < TII->getNumOpcodes(); ++i) {
            if (TII->getName(i) == "ADD16ri") {
                AddOpcode = i;
                break;
            }
        }

        if (!AddOpcode || !SPReg) {
            outs() << "Warning: Could not find ADD16ri or SP register\n";
            outs() << "  AddOpcode=" << AddOpcode << ", SPReg=" << SPReg << "\n";
            return Modified;
        }

        outs() << "Found ADD16ri opcode: " << AddOpcode << "\n";

        // Iterate through all basic blocks
        for (MachineBasicBlock &MBB : MF) {
            // Look for return instructions
            for (auto I = MBB.begin(); I != MBB.end(); ++I) {
                MachineInstr &MI = *I;

                // Check if this is a return instruction using the isReturn() method
                if (MI.isReturn()) {
                    DebugLoc RetDL = MI.getDebugLoc();

                    outs() << "Found return instruction in " << MF.getName() << "\n";

                    // Insert ADD #4, SP to remove the stack_size and boundary value from the stack
                    // Stack layout before epilogue: [boundary][stack_size][...] <- SP
                    // We need to remove 2 bytes for stack_size + 2 bytes for boundary = 4 bytes
                    BuildMI(MBB, I, RetDL, TII->get(AddOpcode))
                        .addReg(SPReg, RegState::Define)
                        .addReg(SPReg)
                        .addImm(4)  // Remove 2 bytes for stack_size + 2 bytes for boundary
                        .setMIFlag(MachineInstr::FrameDestroy);

                    outs() << "Inserted ADD #4, SP before return in function: "
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
