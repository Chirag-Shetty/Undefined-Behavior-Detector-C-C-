; ModuleID = '/home/chira/ub-detector/testcases/cve_cases/cve_2017_11164.c'
source_filename = "/home/chira/ub-detector/testcases/cve_cases/cve_2017_11164.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [22 x i8] c"normal offset 3 : %d\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [22 x i8] c"bad offset -1   : %d\0A\00", align 1, !dbg !7
@.str.2 = private unnamed_addr constant [22 x i8] c"overflow offset : %d\0A\00", align 1, !dbg !9

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @pcre_exec_simplified(ptr nocapture noundef readnone %subject, i32 noundef %length, i32 noundef %startoffset) local_unnamed_addr #0 !dbg !24 {
entry:
  tail call void @llvm.dbg.value(metadata ptr %subject, metadata !30, metadata !DIExpression()), !dbg !33
  tail call void @llvm.dbg.value(metadata i32 %length, metadata !31, metadata !DIExpression()), !dbg !33
  tail call void @llvm.dbg.value(metadata i32 %startoffset, metadata !32, metadata !DIExpression()), !dbg !33
  %cmp1 = icmp slt i32 %startoffset, 0, !dbg !34
  %cmp2 = icmp sgt i32 %startoffset, %length
  %or.cond = or i1 %cmp1, %cmp2, !dbg !36
  %cmp5 = icmp sge i32 %startoffset, %length, !dbg !36
  %cond = sext i1 %cmp5 to i32, !dbg !36
  %retval.0 = select i1 %or.cond, i32 -24, i32 %cond, !dbg !36
  ret i32 %retval.0, !dbg !37
}

; Function Attrs: nofree nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #1 !dbg !38 {
entry:
  call void @llvm.dbg.assign(metadata i1 undef, metadata !41, metadata !DIExpression(), metadata !46, metadata !47, metadata !DIExpression()), !dbg !48
  call void @llvm.dbg.assign(metadata i1 undef, metadata !41, metadata !DIExpression(), metadata !49, metadata !47, metadata !DIExpression()), !dbg !48
  tail call void @llvm.dbg.value(metadata i32 11, metadata !45, metadata !DIExpression()), !dbg !48
  %call3 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef 0), !dbg !50
  %call6 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, i32 noundef -24), !dbg !51
  %call9 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef -24), !dbg !52
  ret i32 0, !dbg !53
}

; Function Attrs: nofree nounwind
declare !dbg !54 noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.assign(metadata, metadata, metadata, metadata, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.value(metadata, metadata, metadata) #4

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.dbg.cu = !{!11}
!llvm.module.flags = !{!16, !17, !18, !19, !20, !21, !22}
!llvm.ident = !{!23}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 64, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "testcases/cve_cases/cve_2017_11164.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "bb58b8127c70a33c639dcb27eeb4209f")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 176, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 22)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 65, type: !3, isLocal: true, isDefinition: true)
!9 = !DIGlobalVariableExpression(var: !10, expr: !DIExpression())
!10 = distinct !DIGlobalVariable(scope: null, file: !2, line: 68, type: !3, isLocal: true, isDefinition: true)
!11 = distinct !DICompileUnit(language: DW_LANG_C11, file: !12, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !13, globals: !15, splitDebugInlining: false, nameTableKind: None)
!12 = !DIFile(filename: "/home/chira/ub-detector/testcases/cve_cases/cve_2017_11164.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "bb58b8127c70a33c639dcb27eeb4209f")
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!0, !7, !9}
!16 = !{i32 7, !"Dwarf Version", i32 5}
!17 = !{i32 2, !"Debug Info Version", i32 3}
!18 = !{i32 1, !"wchar_size", i32 4}
!19 = !{i32 8, !"PIC Level", i32 2}
!20 = !{i32 7, !"PIE Level", i32 2}
!21 = !{i32 7, !"uwtable", i32 2}
!22 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!23 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!24 = distinct !DISubprogram(name: "pcre_exec_simplified", scope: !2, file: !2, line: 33, type: !25, scopeLine: 34, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !11, retainedNodes: !29)
!25 = !DISubroutineType(types: !26)
!26 = !{!14, !27, !14, !14}
!27 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !28, size: 64)
!28 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
!29 = !{!30, !31, !32}
!30 = !DILocalVariable(name: "subject", arg: 1, scope: !24, file: !2, line: 33, type: !27)
!31 = !DILocalVariable(name: "length", arg: 2, scope: !24, file: !2, line: 33, type: !14)
!32 = !DILocalVariable(name: "startoffset", arg: 3, scope: !24, file: !2, line: 33, type: !14)
!33 = !DILocation(line: 0, scope: !24)
!34 = !DILocation(line: 51, column: 21, scope: !35)
!35 = distinct !DILexicalBlock(scope: !24, file: !2, line: 51, column: 9)
!36 = !DILocation(line: 51, column: 25, scope: !35)
!37 = !DILocation(line: 57, column: 1, scope: !24)
!38 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 59, type: !39, scopeLine: 60, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !11, retainedNodes: !40)
!39 = !DISubroutineType(types: !13)
!40 = !{!41, !45}
!41 = !DILocalVariable(name: "subject", scope: !38, file: !2, line: 61, type: !42)
!42 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 96, elements: !43)
!43 = !{!44}
!44 = !DISubrange(count: 12)
!45 = !DILocalVariable(name: "len", scope: !38, file: !2, line: 62, type: !14)
!46 = distinct !DIAssignID()
!47 = !{}
!48 = !DILocation(line: 0, scope: !38)
!49 = distinct !DIAssignID()
!50 = !DILocation(line: 64, column: 5, scope: !38)
!51 = !DILocation(line: 65, column: 5, scope: !38)
!52 = !DILocation(line: 68, column: 5, scope: !38)
!53 = !DILocation(line: 69, column: 5, scope: !38)
!54 = !DISubprogram(name: "printf", scope: !55, file: !55, line: 363, type: !56, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DIFile(filename: "/usr/include/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "1e435c46987a169d9f9186f63a512303")
!56 = !DISubroutineType(types: !57)
!57 = !{!14, !58, null}
!58 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !27)
