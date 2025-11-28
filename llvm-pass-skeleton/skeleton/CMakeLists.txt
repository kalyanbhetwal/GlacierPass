cmake_minimum_required(VERSION 3.13)
project(SkeletonPass LANGUAGES CXX)

find_package(LLVM REQUIRED CONFIG)

include_directories(${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

add_llvm_pass_plugin(SkeletonPass
    # List your source files here.
    Skeleton.cpp
    PrologueBoundary.cpp
)

# This line makes sure the pass links against the required LLVM components
target_link_libraries(SkeletonPass PRIVATE
    LLVMCore
    LLVMSupport
    LLVMIRReader
    LLVMBitReader
    LLVMCodeGen
    LLVMTarget
    LLVMSelectionDAG
    LLVMAsmPrinter
    LLVMGlobalISel
    LLVMX86CodeGen 
)