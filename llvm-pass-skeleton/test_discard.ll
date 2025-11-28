; ModuleID = 'test_discard.c'
source_filename = "test_discard.c"
target datalayout = "e-m:e-p:16:16-i32:16-i64:16-f32:16-f64:16-a:8-n8:16-S16"
target triple = "msp430"

@.str = private unnamed_addr constant [8 x i8] c"discard\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [15 x i8] c"test_discard.c\00", section "llvm.metadata"
@llvm.global.annotations = appending global [2 x { ptr, ptr, ptr, i32, ptr }] [{ ptr, ptr, ptr, i32, ptr } { ptr @discard_func, ptr @.str, ptr @.str.1, i32 3, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @discard_func2, ptr @.str, ptr @.str.1, i32 19, ptr null }], section "llvm.metadata"

; Function Attrs: noinline nounwind optnone
define dso_local i16 @discard_func(i16 noundef %a, i16 noundef %b) #0 #1 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  %x = alloca i16, align 2
  %y = alloca i16, align 2
  %z = alloca i16, align 2
  %w = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %1 = load i16, ptr %b.addr, align 2
  %add = add nsw i16 %0, %1
  store i16 %add, ptr %x, align 2
  %2 = load i16, ptr %x, align 2
  %mul = mul nsw i16 %2, 2
  store i16 %mul, ptr %y, align 2
  %3 = load i16, ptr %y, align 2
  %4 = load i16, ptr %a.addr, align 2
  %sub = sub nsw i16 %3, %4
  store i16 %sub, ptr %z, align 2
  %5 = load i16, ptr %z, align 2
  %6 = load i16, ptr %x, align 2
  %add1 = add nsw i16 %5, %6
  store i16 %add1, ptr %w, align 2
  %7 = load i16, ptr %w, align 2
  %8 = load i16, ptr %b.addr, align 2
  %add2 = add nsw i16 %7, %8
  ret i16 %add2
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @normal_func(i16 noundef %a, i16 noundef %b) #0 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  %x = alloca i16, align 2
  %y = alloca i16, align 2
  %z = alloca i16, align 2
  %w = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  %0 = load i16, ptr %a.addr, align 2
  %1 = load i16, ptr %b.addr, align 2
  %add = add nsw i16 %0, %1
  store i16 %add, ptr %x, align 2
  %2 = load i16, ptr %x, align 2
  %mul = mul nsw i16 %2, 2
  store i16 %mul, ptr %y, align 2
  %3 = load i16, ptr %y, align 2
  %4 = load i16, ptr %a.addr, align 2
  %sub = sub nsw i16 %3, %4
  store i16 %sub, ptr %z, align 2
  %5 = load i16, ptr %z, align 2
  %6 = load i16, ptr %x, align 2
  %add1 = add nsw i16 %5, %6
  store i16 %add1, ptr %w, align 2
  %7 = load i16, ptr %w, align 2
  %8 = load i16, ptr %b.addr, align 2
  %add2 = add nsw i16 %7, %8
  ret i16 %add2
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @discard_func2(i16 noundef %a, i16 noundef %b, i16 noundef %c) #0 #1 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  %c.addr = alloca i16, align 2
  %result = alloca i16, align 2
  %i = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  store i16 %c, ptr %c.addr, align 2
  store i16 0, ptr %result, align 2
  store i16 0, ptr %i, align 2
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i16, ptr %i, align 2
  %1 = load i16, ptr %a.addr, align 2
  %cmp = icmp slt i16 %0, %1
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %2 = load i16, ptr %b.addr, align 2
  %3 = load i16, ptr %c.addr, align 2
  %mul = mul nsw i16 %2, %3
  %4 = load i16, ptr %result, align 2
  %add = add nsw i16 %4, %mul
  store i16 %add, ptr %result, align 2
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %5 = load i16, ptr %i, align 2
  %inc = add nsw i16 %5, 1
  store i16 %inc, ptr %i, align 2
  br label %for.cond, !llvm.loop !2

for.end:                                          ; preds = %for.cond
  %6 = load i16, ptr %result, align 2
  ret i16 %6
}

; Function Attrs: noinline nounwind optnone
define dso_local i16 @normal_func2(i16 noundef %a, i16 noundef %b, i16 noundef %c) #0 {
entry:
  %a.addr = alloca i16, align 2
  %b.addr = alloca i16, align 2
  %c.addr = alloca i16, align 2
  %result = alloca i16, align 2
  %i = alloca i16, align 2
  store i16 %a, ptr %a.addr, align 2
  store i16 %b, ptr %b.addr, align 2
  store i16 %c, ptr %c.addr, align 2
  store i16 0, ptr %result, align 2
  store i16 0, ptr %i, align 2
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i16, ptr %i, align 2
  %1 = load i16, ptr %a.addr, align 2
  %cmp = icmp slt i16 %0, %1
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %2 = load i16, ptr %b.addr, align 2
  %3 = load i16, ptr %c.addr, align 2
  %mul = mul nsw i16 %2, %3
  %4 = load i16, ptr %result, align 2
  %add = add nsw i16 %4, %mul
  store i16 %add, ptr %result, align 2
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %5 = load i16, ptr %i, align 2
  %inc = add nsw i16 %5, 1
  store i16 %inc, ptr %i, align 2
  br label %for.cond, !llvm.loop !4

for.end:                                          ; preds = %for.cond
  %6 = load i16, ptr %result, align 2
  ret i16 %6
}

attributes #0 = { noinline nounwind optnone "no-trapping-math"="true" "stack-protector-buffer-size"="8" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 2}
!1 = !{!"clang version 22.0.0git (git@github.com:llvm/llvm-project.git 7e55a4c9937dfc2184636ad7f3c9f7eccfad6186)"}
!2 = distinct !{!2, !3}
!3 = !{!"llvm.loop.mustprogress"}
!4 = distinct !{!4, !3}

attributes #1 = { "discard" }
