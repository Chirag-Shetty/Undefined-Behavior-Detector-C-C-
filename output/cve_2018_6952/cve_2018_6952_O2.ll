; ModuleID = '/home/chira/ub-detector/testcases/cve_cases/cve_2018_6952.c'
source_filename = "/home/chira/ub-detector/testcases/cve_cases/cve_2018_6952.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [18 x i8] c"small hunk  : %d\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [18 x i8] c"large hunk  : %d\0A\00", align 1, !dbg !7
@.str.2 = private unnamed_addr constant [18 x i8] c"huge lines  : %d\0A\00", align 1, !dbg !9

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @another_hunk_simplified(i32 noundef %remaining, i32 noundef %extra_lines) local_unnamed_addr #0 !dbg !22 {
entry:
  tail call void @llvm.dbg.value(metadata i32 %remaining, metadata !27, metadata !DIExpression()), !dbg !31
  tail call void @llvm.dbg.value(metadata i32 %extra_lines, metadata !28, metadata !DIExpression()), !dbg !31
  tail call void @llvm.dbg.value(metadata i32 80, metadata !29, metadata !DIExpression()), !dbg !31
  tail call void @llvm.dbg.value(metadata i32 %extra_lines, metadata !30, metadata !DIExpression(DW_OP_constu, 80, DW_OP_mul, DW_OP_stack_value)), !dbg !31
  %mul = mul nsw i32 %extra_lines, 80, !dbg !32
  %add = add nsw i32 %mul, %remaining, !dbg !32
  %cmp2 = icmp sgt i32 %add, 4096, !dbg !32
  %cmp.inv = icmp slt i32 %extra_lines, 0, !dbg !32
  %narrow = select i1 %cmp.inv, i1 true, i1 %cmp2, !dbg !32
  %retval.0 = sext i1 %narrow to i32, !dbg !32
  ret i32 %retval.0, !dbg !33
}

; Function Attrs: nofree nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #1 !dbg !34 {
entry:
  %call1 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef 0), !dbg !37
  %call3 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, i32 noundef -1), !dbg !38
  %call5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef 0), !dbg !39
  ret i32 0, !dbg !40
}

; Function Attrs: nofree nounwind
declare !dbg !41 noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.dbg.cu = !{!11}
!llvm.module.flags = !{!14, !15, !16, !17, !18, !19, !20}
!llvm.ident = !{!21}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 64, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "testcases/cve_cases/cve_2018_6952.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "046d116b34d8b3bc28598405ad286a56")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 144, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 18)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 65, type: !3, isLocal: true, isDefinition: true)
!9 = !DIGlobalVariableExpression(var: !10, expr: !DIExpression())
!10 = distinct !DIGlobalVariable(scope: null, file: !2, line: 68, type: !3, isLocal: true, isDefinition: true)
!11 = distinct !DICompileUnit(language: DW_LANG_C11, file: !12, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, globals: !13, splitDebugInlining: false, nameTableKind: None)
!12 = !DIFile(filename: "/home/chira/ub-detector/testcases/cve_cases/cve_2018_6952.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "046d116b34d8b3bc28598405ad286a56")
!13 = !{!0, !7, !9}
!14 = !{i32 7, !"Dwarf Version", i32 5}
!15 = !{i32 2, !"Debug Info Version", i32 3}
!16 = !{i32 1, !"wchar_size", i32 4}
!17 = !{i32 8, !"PIC Level", i32 2}
!18 = !{i32 7, !"PIE Level", i32 2}
!19 = !{i32 7, !"uwtable", i32 2}
!20 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!21 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!22 = distinct !DISubprogram(name: "another_hunk_simplified", scope: !2, file: !2, line: 34, type: !23, scopeLine: 35, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !11, retainedNodes: !26)
!23 = !DISubroutineType(types: !24)
!24 = !{!25, !25, !25}
!25 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!26 = !{!27, !28, !29, !30}
!27 = !DILocalVariable(name: "remaining", arg: 1, scope: !22, file: !2, line: 34, type: !25)
!28 = !DILocalVariable(name: "extra_lines", arg: 2, scope: !22, file: !2, line: 34, type: !25)
!29 = !DILocalVariable(name: "bytes_per_line", scope: !22, file: !2, line: 36, type: !25)
!30 = !DILocalVariable(name: "extra", scope: !22, file: !2, line: 50, type: !25)
!31 = !DILocation(line: 0, scope: !22)
!32 = !DILocation(line: 51, column: 9, scope: !22)
!33 = !DILocation(line: 60, column: 1, scope: !22)
!34 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 62, type: !35, scopeLine: 63, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !11)
!35 = !DISubroutineType(types: !36)
!36 = !{!25}
!37 = !DILocation(line: 64, column: 5, scope: !34)
!38 = !DILocation(line: 65, column: 5, scope: !34)
!39 = !DILocation(line: 68, column: 5, scope: !34)
!40 = !DILocation(line: 69, column: 5, scope: !34)
!41 = !DISubprogram(name: "printf", scope: !42, file: !42, line: 363, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DIFile(filename: "/usr/include/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "1e435c46987a169d9f9186f63a512303")
!43 = !DISubroutineType(types: !44)
!44 = !{!25, !45, null}
!45 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !46)
!46 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !47, size: 64)
!47 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
