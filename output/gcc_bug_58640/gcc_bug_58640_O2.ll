; ModuleID = '/home/chira/ub-detector/testcases/cve_cases/gcc_bug_58640.c'
source_filename = "/home/chira/ub-detector/testcases/cve_cases/gcc_bug_58640.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [22 x i8] c"mode=1 input=200: %d\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [22 x i8] c"mode=1 input=50 : %d\0A\00", align 1, !dbg !7
@.str.2 = private unnamed_addr constant [22 x i8] c"mode=0 input=50 : %d\0A\00", align 1, !dbg !9
@.str.3 = private unnamed_addr constant [22 x i8] c"uninit flag=1   : %d\0A\00", align 1, !dbg !11
@.str.4 = private unnamed_addr constant [22 x i8] c"uninit flag=0   : %d\0A\00", align 1, !dbg !13

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @process_gcc58640(i32 noundef %mode, i32 noundef %input) local_unnamed_addr #0 !dbg !26 {
entry:
  tail call void @llvm.dbg.value(metadata i32 %mode, metadata !31, metadata !DIExpression()), !dbg !39
  tail call void @llvm.dbg.value(metadata i32 %input, metadata !32, metadata !DIExpression()), !dbg !39
  %cmp1 = icmp sgt i32 %input, 100
  tail call void @llvm.dbg.value(metadata i32 poison, metadata !33, metadata !DIExpression(DW_OP_LLVM_fragment, 0, 32)), !dbg !39
  %retval.0 = sext i1 %cmp1 to i32, !dbg !40
  ret i32 %retval.0, !dbg !41
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @uninit_branch_gcc58640(i32 noundef %flag) local_unnamed_addr #0 !dbg !42 {
entry:
  tail call void @llvm.dbg.value(metadata i32 %flag, metadata !46, metadata !DIExpression()), !dbg !48
  ret i32 1, !dbg !49
}

; Function Attrs: nofree nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #1 !dbg !50 {
entry:
  %call1 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef -1), !dbg !53
  %call3 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, i32 noundef 0), !dbg !54
  %call5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef 0), !dbg !55
  %call7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.3, i32 noundef 1), !dbg !56
  %call9 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.4, i32 noundef 1), !dbg !57
  ret i32 0, !dbg !58
}

; Function Attrs: nofree nounwind
declare !dbg !59 noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.dbg.cu = !{!15}
!llvm.module.flags = !{!18, !19, !20, !21, !22, !23, !24}
!llvm.ident = !{!25}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 75, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "testcases/cve_cases/gcc_bug_58640.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "9fc80c0227541a6e4b5423c38c1013e7")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 176, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 22)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 76, type: !3, isLocal: true, isDefinition: true)
!9 = !DIGlobalVariableExpression(var: !10, expr: !DIExpression())
!10 = distinct !DIGlobalVariable(scope: null, file: !2, line: 79, type: !3, isLocal: true, isDefinition: true)
!11 = !DIGlobalVariableExpression(var: !12, expr: !DIExpression())
!12 = distinct !DIGlobalVariable(scope: null, file: !2, line: 81, type: !3, isLocal: true, isDefinition: true)
!13 = !DIGlobalVariableExpression(var: !14, expr: !DIExpression())
!14 = distinct !DIGlobalVariable(scope: null, file: !2, line: 83, type: !3, isLocal: true, isDefinition: true)
!15 = distinct !DICompileUnit(language: DW_LANG_C11, file: !16, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, globals: !17, splitDebugInlining: false, nameTableKind: None)
!16 = !DIFile(filename: "/home/chira/ub-detector/testcases/cve_cases/gcc_bug_58640.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "9fc80c0227541a6e4b5423c38c1013e7")
!17 = !{!0, !7, !9, !11, !13}
!18 = !{i32 7, !"Dwarf Version", i32 5}
!19 = !{i32 2, !"Debug Info Version", i32 3}
!20 = !{i32 1, !"wchar_size", i32 4}
!21 = !{i32 8, !"PIC Level", i32 2}
!22 = !{i32 7, !"PIE Level", i32 2}
!23 = !{i32 7, !"uwtable", i32 2}
!24 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!25 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!26 = distinct !DISubprogram(name: "process_gcc58640", scope: !2, file: !2, line: 33, type: !27, scopeLine: 34, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !15, retainedNodes: !30)
!27 = !DISubroutineType(types: !28)
!28 = !{!29, !29, !29}
!29 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!30 = !{!31, !32, !33}
!31 = !DILocalVariable(name: "mode", arg: 1, scope: !26, file: !2, line: 33, type: !29)
!32 = !DILocalVariable(name: "input", arg: 2, scope: !26, file: !2, line: 33, type: !29)
!33 = !DILocalVariable(name: "r", scope: !26, file: !2, line: 35, type: !34)
!34 = !DIDerivedType(tag: DW_TAG_typedef, name: "Result", file: !2, line: 26, baseType: !35)
!35 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !2, line: 23, size: 64, elements: !36)
!36 = !{!37, !38}
!37 = !DIDerivedType(tag: DW_TAG_member, name: "code", scope: !35, file: !2, line: 24, baseType: !29, size: 32)
!38 = !DIDerivedType(tag: DW_TAG_member, name: "value", scope: !35, file: !2, line: 25, baseType: !29, size: 32, offset: 32)
!39 = !DILocation(line: 0, scope: !26)
!40 = !DILocation(line: 50, column: 9, scope: !26)
!41 = !DILocation(line: 55, column: 1, scope: !26)
!42 = distinct !DISubprogram(name: "uninit_branch_gcc58640", scope: !2, file: !2, line: 61, type: !43, scopeLine: 62, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !15, retainedNodes: !45)
!43 = !DISubroutineType(types: !44)
!44 = !{!29, !29}
!45 = !{!46, !47}
!46 = !DILocalVariable(name: "flag", arg: 1, scope: !42, file: !2, line: 61, type: !29)
!47 = !DILocalVariable(name: "status", scope: !42, file: !2, line: 63, type: !29)
!48 = !DILocation(line: 0, scope: !42)
!49 = !DILocation(line: 70, column: 5, scope: !42)
!50 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 73, type: !51, scopeLine: 74, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !15)
!51 = !DISubroutineType(types: !52)
!52 = !{!29}
!53 = !DILocation(line: 75, column: 5, scope: !50)
!54 = !DILocation(line: 76, column: 5, scope: !50)
!55 = !DILocation(line: 79, column: 5, scope: !50)
!56 = !DILocation(line: 81, column: 5, scope: !50)
!57 = !DILocation(line: 83, column: 5, scope: !50)
!58 = !DILocation(line: 84, column: 5, scope: !50)
!59 = !DISubprogram(name: "printf", scope: !60, file: !60, line: 363, type: !61, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!60 = !DIFile(filename: "/usr/include/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "1e435c46987a169d9f9186f63a512303")
!61 = !DISubroutineType(types: !62)
!62 = !{!29, !63, null}
!63 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !64)
!64 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !65, size: 64)
!65 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
