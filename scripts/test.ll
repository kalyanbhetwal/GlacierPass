; ModuleID = 'test_boundary.c'
source_filename = "test_boundary.c"
target datalayout = "e-m:e-p:16:16-i32:16-i64:16-f32:16-f64:16-a:8-n8:16-S16"
target triple = "msp430"

; Function Attrs: noinline nounwind optnone
define dso_local i16 @test_function(i16 noundef %a, i16 noundef %b) #0 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %1 = load i16, ptr %b.addr, align 2
  %add = add nsw i16 %0, %1
  ret i16 %add
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @main() #0 {
entry:
  %retval = alloca i16, align 2
  %result = alloca i16, align 2
  store i16 0, ptr %retval, align 2
  %call = call i16 @test_function(i16 noundef 5, i16 noundef 10)
  store i16 %call, ptr %result, align 2
  %0 = load i16, ptr %result, align 2
  ret i16 %0
}

attributes #0 = { noinline nounwind optnone "no-trapping-math"="true" "stack-protector-buffer-size"="8" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 2}
!1 = !{!"clang version 22.0.0git (git@github.com:llvm/llvm-project.git 7e55a4c9937dfc2184636ad7f3c9f7eccfad6186)"}
