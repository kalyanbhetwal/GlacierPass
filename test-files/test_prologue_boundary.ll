; ModuleID = 'test_prologue_boundary.c'
source_filename = "test_prologue_boundary.c"
target datalayout = "e-m:e-p:16:16-i32:16-i64:16-f32:16-f64:16-a:8-n8:16-S16"
target triple = "msp430"

@.str = private unnamed_addr constant [8 x i8] c"discard\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [25 x i8] c"test_prologue_boundary.c\00", section "llvm.metadata"
@.str.2 = private unnamed_addr constant [10 x i8] c"immediate\00", section "llvm.metadata"
@llvm.global.annotations = appending global [9 x { ptr, ptr, ptr, i32, ptr }] [{ ptr, ptr, ptr, i32, ptr } { ptr @discard_no_locals, ptr @.str, ptr @.str.1, i32 71, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @discard_with_locals, ptr @.str, ptr @.str.1, i32 80, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @discard_with_array, ptr @.str, ptr @.str.1, i32 92, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @immediate_no_locals, ptr @.str.2, ptr @.str.1, i32 109, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @immediate_with_locals, ptr @.str.2, ptr @.str.1, i32 118, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @immediate_with_array, ptr @.str.2, ptr @.str.1, i32 129, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @immediate_multiple_returns, ptr @.str.2, ptr @.str.1, i32 143, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @discard_calls_immediate, ptr @.str, ptr @.str.1, i32 170, ptr null }, { ptr, ptr, ptr, i32, ptr } { ptr @immediate_calls_normal, ptr @.str.2, ptr @.str.1, i32 179, ptr null }], section "llvm.metadata"

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i16 @normal_no_locals(i16 noundef %0, i16 noundef %1) local_unnamed_addr #0 {
  %3 = add nsw i16 %1, %0
  ret i16 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i16 @normal_with_small_locals(i16 noundef %0, i16 noundef %1) local_unnamed_addr #0 {
  %3 = shl nsw i16 %0, 1
  %4 = mul nsw i16 %1, 3
  %5 = add nsw i16 %4, %3
  ret i16 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i16 @normal_with_large_locals(i16 noundef %0, i16 noundef %1) local_unnamed_addr #0 {
  %3 = add nsw i16 %1, %0
  %4 = add nsw i16 %3, 5
  ret i16 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local range(i16 -32758, -32768) i16 @normal_with_call(i16 noundef %0, i16 noundef %1) local_unnamed_addr #0 {
  %3 = add i16 %0, 10
  %4 = add i16 %3, %1
  ret i16 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i16 @discard_no_locals(i16 noundef %0, i16 noundef %1) #99 {
  %3 = add nsw i16 %1, %0
  ret i16 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i16 @discard_with_locals(i16 noundef %0, i16 noundef %1) #99 {
  %3 = shl nsw i16 %0, 1
  %4 = mul nsw i16 %1, 3
  %5 = add nsw i16 %4, %3
  ret i16 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i16 @discard_with_array(i16 noundef %0) #99 {
  %2 = add nsw i16 %0, 2
  ret i16 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i16 @immediate_no_locals(i16 noundef %0, i16 noundef %1) #98 {
  %3 = sub nsw i16 %0, %1
  ret i16 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i16 @immediate_with_locals(i16 noundef %0, i16 noundef %1) #98 {
  %3 = shl i16 %0, 1
  %4 = ashr i16 %1, 1
  %5 = add nsw i16 %4, %3
  ret i16 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i16 @immediate_with_array(i16 noundef %0) #98 {
  %2 = mul nsw i16 %0, 7
  ret i16 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local noundef i16 @immediate_multiple_returns(i16 noundef %0, i16 noundef %1) #98 {
  %3 = icmp sgt i16 %0, %1
  %4 = icmp slt i16 %0, %1
  %5 = select i1 %4, i16 %1, i16 0
  %6 = select i1 %3, i16 %0, i16 %5
  ret i16 %6
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i16 @normal_calls_discard(i16 noundef %0) local_unnamed_addr #0 {
  %2 = shl i16 %0, 1
  %3 = or disjoint i16 %2, 1
  ret i16 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local noundef i16 @discard_calls_immediate(i16 %0) #99 {
  ret i16 1
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local noundef i16 @immediate_calls_normal(i16 noundef %0) #98 {
  %2 = shl i16 %0, 1
  %3 = add i16 %2, 2
  ret i16 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local noundef i16 @main() local_unnamed_addr #0 {
  ret i16 431
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) "no-trapping-math"="true" "stack-protector-buffer-size"="8" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 2}
!1 = !{!"Apple clang version 17.0.0 (clang-1700.4.4.1)"}

attributes #99 = { "discard" }
attributes #98 = { "immediate" }
