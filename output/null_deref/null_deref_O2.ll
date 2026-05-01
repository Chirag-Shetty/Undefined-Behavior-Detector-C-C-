; ModuleID = '/home/chira/ub-detector/testcases/null_deref.c'
source_filename = "/home/chira/ub-detector/testcases/null_deref.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1, !dbg !0

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @use_ptr(ptr noundef readonly %ptr) local_unnamed_addr #0 !dbg !18 {
entry:
  tail call void @llvm.dbg.value(metadata ptr %ptr, metadata !24, metadata !DIExpression()), !dbg !28
  %tobool.not = icmp eq ptr %ptr, null, !dbg !29
  br i1 %tobool.not, label %return, label %if.then, !dbg !30

if.then:                                          ; preds = %entry
  %0 = load i32, ptr %ptr, align 4, !dbg !31, !tbaa !33
  br label %return, !dbg !37

return:                                           ; preds = %entry, %if.then
  %retval.0 = phi i32 [ %0, %if.then ], [ undef, %entry ], !dbg !38
  ret i32 %retval.0, !dbg !39
}

; Function Attrs: nofree nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #1 !dbg !40 {
entry:
  tail call void @llvm.dbg.value(metadata i32 42, metadata !44, metadata !DIExpression()), !dbg !45
  %call1 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef 42), !dbg !46
  ret i32 0, !dbg !47
}

; Function Attrs: nofree nounwind
declare !dbg !48 noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.dbg.cu = !{!7}
!llvm.module.flags = !{!10, !11, !12, !13, !14, !15, !16}
!llvm.ident = !{!17}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 18, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "testcases/null_deref.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "4f4fb97ed6de826608d414dfeca9216b")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 32, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 4)
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, globals: !9, splitDebugInlining: false, nameTableKind: None)
!8 = !DIFile(filename: "/home/chira/ub-detector/testcases/null_deref.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "4f4fb97ed6de826608d414dfeca9216b")
!9 = !{!0}
!10 = !{i32 7, !"Dwarf Version", i32 5}
!11 = !{i32 2, !"Debug Info Version", i32 3}
!12 = !{i32 1, !"wchar_size", i32 4}
!13 = !{i32 8, !"PIC Level", i32 2}
!14 = !{i32 7, !"PIE Level", i32 2}
!15 = !{i32 7, !"uwtable", i32 2}
!16 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!17 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!18 = distinct !DISubprogram(name: "use_ptr", scope: !2, file: !2, line: 6, type: !19, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !23)
!19 = !DISubroutineType(types: !20)
!20 = !{!21, !22}
!21 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!22 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !21, size: 64)
!23 = !{!24, !25}
!24 = !DILocalVariable(name: "ptr", arg: 1, scope: !18, file: !2, line: 6, type: !22)
!25 = !DILocalVariable(name: "null_ptr", scope: !26, file: !2, line: 11, type: !22)
!26 = distinct !DILexicalBlock(scope: !27, file: !2, line: 9, column: 12)
!27 = distinct !DILexicalBlock(scope: !18, file: !2, line: 7, column: 9)
!28 = !DILocation(line: 0, scope: !18)
!29 = !DILocation(line: 7, column: 9, scope: !27)
!30 = !DILocation(line: 7, column: 9, scope: !18)
!31 = !DILocation(line: 8, column: 16, scope: !32)
!32 = distinct !DILexicalBlock(scope: !27, file: !2, line: 7, column: 14)
!33 = !{!34, !34, i64 0}
!34 = !{!"int", !35, i64 0}
!35 = !{!"omnipotent char", !36, i64 0}
!36 = !{!"Simple C/C++ TBAA"}
!37 = !DILocation(line: 8, column: 9, scope: !32)
!38 = !DILocation(line: 0, scope: !27)
!39 = !DILocation(line: 14, column: 1, scope: !18)
!40 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 16, type: !41, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !43)
!41 = !DISubroutineType(types: !42)
!42 = !{!21}
!43 = !{!44}
!44 = !DILocalVariable(name: "x", scope: !40, file: !2, line: 17, type: !21)
!45 = !DILocation(line: 0, scope: !40)
!46 = !DILocation(line: 18, column: 5, scope: !40)
!47 = !DILocation(line: 19, column: 5, scope: !40)
!48 = !DISubprogram(name: "printf", scope: !49, file: !49, line: 363, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DIFile(filename: "/usr/include/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "1e435c46987a169d9f9186f63a512303")
!50 = !DISubroutineType(types: !51)
!51 = !{!21, !52, null}
!52 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !53)
!53 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !54, size: 64)
!54 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
