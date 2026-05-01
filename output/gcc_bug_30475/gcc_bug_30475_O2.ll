; ModuleID = '/home/chira/ub-detector/testcases/cve_cases/gcc_bug_30475.c'
source_filename = "/home/chira/ub-detector/testcases/cve_cases/gcc_bug_30475.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [19 x i8] c"advance  4   : %s\0A\00", align 1, !dbg !0
@.str.2 = private unnamed_addr constant [19 x i8] c"advance MAX  : %s\0A\00", align 1, !dbg !7
@.str.3 = private unnamed_addr constant [12 x i8] c"(non-null!)\00", align 1, !dbg !9
@.str.4 = private unnamed_addr constant [19 x i8] c"end  10+5    : %d\0A\00", align 1, !dbg !14
@.str.5 = private unnamed_addr constant [19 x i8] c"end MAX+1    : %d\0A\00", align 1, !dbg !16

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local ptr @safe_advance_gcc30475(ptr noundef readnone %base, i32 noundef %offset) local_unnamed_addr #0 !dbg !36 {
entry:
  tail call void @llvm.dbg.value(metadata ptr %base, metadata !41, metadata !DIExpression()), !dbg !43
  tail call void @llvm.dbg.value(metadata i32 %offset, metadata !42, metadata !DIExpression()), !dbg !43
  %cmp = icmp slt i32 %offset, 0, !dbg !44
  %idx.ext = zext nneg i32 %offset to i64, !dbg !46
  %add.ptr = getelementptr inbounds i8, ptr %base, i64 %idx.ext, !dbg !46
  %retval.0 = select i1 %cmp, ptr null, ptr %add.ptr, !dbg !46
  ret ptr %retval.0, !dbg !47
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @compute_end_gcc30475(i32 noundef %start, i32 noundef %length) local_unnamed_addr #0 !dbg !48 {
entry:
  tail call void @llvm.dbg.value(metadata i32 %start, metadata !52, metadata !DIExpression()), !dbg !54
  tail call void @llvm.dbg.value(metadata i32 %length, metadata !53, metadata !DIExpression()), !dbg !54
  %add = add nsw i32 %length, %start, !dbg !55
  %cmp.inv = icmp sgt i32 %length, -1, !dbg !55
  %retval.0 = select i1 %cmp.inv, i32 %add, i32 -1, !dbg !55
  ret i32 %retval.0, !dbg !56
}

; Function Attrs: nofree nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #1 !dbg !57 {
entry:
  %buf = alloca [64 x i8], align 16, !DIAssignID !67
  call void @llvm.dbg.assign(metadata i1 undef, metadata !61, metadata !DIExpression(), metadata !67, metadata ptr %buf, metadata !DIExpression()), !dbg !68
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %buf) #7, !dbg !69
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %buf, i8 0, i64 64, i1 false), !dbg !70, !DIAssignID !71
  call void @llvm.dbg.assign(metadata i8 0, metadata !61, metadata !DIExpression(), metadata !71, metadata ptr %buf, metadata !DIExpression()), !dbg !68
  call void @llvm.dbg.assign(metadata i8 104, metadata !61, metadata !DIExpression(DW_OP_LLVM_fragment, 0, 8), metadata !72, metadata ptr %buf, metadata !DIExpression()), !dbg !68
  call void @llvm.dbg.assign(metadata i8 101, metadata !61, metadata !DIExpression(DW_OP_LLVM_fragment, 8, 8), metadata !72, metadata ptr %buf, metadata !DIExpression(DW_OP_plus_uconst, 1)), !dbg !68
  call void @llvm.dbg.assign(metadata i8 108, metadata !61, metadata !DIExpression(DW_OP_LLVM_fragment, 16, 8), metadata !72, metadata ptr %buf, metadata !DIExpression(DW_OP_plus_uconst, 2)), !dbg !68
  store <4 x i8> <i8 104, i8 101, i8 108, i8 108>, ptr %buf, align 16, !dbg !70, !DIAssignID !72
  call void @llvm.dbg.assign(metadata i8 108, metadata !61, metadata !DIExpression(DW_OP_LLVM_fragment, 24, 8), metadata !72, metadata ptr %buf, metadata !DIExpression(DW_OP_plus_uconst, 3)), !dbg !68
  %0 = getelementptr inbounds [64 x i8], ptr %buf, i64 0, i64 4, !dbg !70
  store i8 111, ptr %0, align 4, !dbg !70, !DIAssignID !73
  call void @llvm.dbg.assign(metadata i8 111, metadata !61, metadata !DIExpression(DW_OP_LLVM_fragment, 32, 8), metadata !73, metadata ptr %0, metadata !DIExpression()), !dbg !68
  tail call void @llvm.dbg.value(metadata ptr %0, metadata !65, metadata !DIExpression()), !dbg !68
  tail call void @llvm.dbg.value(metadata ptr %buf, metadata !66, metadata !DIExpression(DW_OP_plus_uconst, 2147483647, DW_OP_stack_value)), !dbg !68
  %call3 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, ptr noundef nonnull %0), !dbg !74
  %call6 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, ptr noundef nonnull @.str.3), !dbg !75
  %call8 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.4, i32 noundef 15), !dbg !76
  %call10 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.5, i32 noundef -2147483648), !dbg !77
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %buf) #7, !dbg !78
  ret i32 0, !dbg !79
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

; Function Attrs: nofree nounwind
declare !dbg !80 noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.assign(metadata, metadata, metadata, metadata, metadata, metadata) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.value(metadata, metadata, metadata) #6

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #6 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #7 = { nounwind }

!llvm.dbg.cu = !{!18}
!llvm.module.flags = !{!28, !29, !30, !31, !32, !33, !34}
!llvm.ident = !{!35}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 68, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "testcases/cve_cases/gcc_bug_30475.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "159b6d4a3638c0ef69cc08812ce2de57")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 152, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 19)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 69, type: !3, isLocal: true, isDefinition: true)
!9 = !DIGlobalVariableExpression(var: !10, expr: !DIExpression())
!10 = distinct !DIGlobalVariable(scope: null, file: !2, line: 69, type: !11, isLocal: true, isDefinition: true)
!11 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 96, elements: !12)
!12 = !{!13}
!13 = !DISubrange(count: 12)
!14 = !DIGlobalVariableExpression(var: !15, expr: !DIExpression())
!15 = distinct !DIGlobalVariable(scope: null, file: !2, line: 72, type: !3, isLocal: true, isDefinition: true)
!16 = !DIGlobalVariableExpression(var: !17, expr: !DIExpression())
!17 = distinct !DIGlobalVariable(scope: null, file: !2, line: 73, type: !3, isLocal: true, isDefinition: true)
!18 = distinct !DICompileUnit(language: DW_LANG_C11, file: !19, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !20, globals: !22, splitDebugInlining: false, nameTableKind: None)
!19 = !DIFile(filename: "/home/chira/ub-detector/testcases/cve_cases/gcc_bug_30475.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "159b6d4a3638c0ef69cc08812ce2de57")
!20 = !{!21}
!21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !4, size: 64)
!22 = !{!0, !23, !7, !9, !14, !16}
!23 = !DIGlobalVariableExpression(var: !24, expr: !DIExpression())
!24 = distinct !DIGlobalVariable(scope: null, file: !2, line: 68, type: !25, isLocal: true, isDefinition: true)
!25 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 56, elements: !26)
!26 = !{!27}
!27 = !DISubrange(count: 7)
!28 = !{i32 7, !"Dwarf Version", i32 5}
!29 = !{i32 2, !"Debug Info Version", i32 3}
!30 = !{i32 1, !"wchar_size", i32 4}
!31 = !{i32 8, !"PIC Level", i32 2}
!32 = !{i32 7, !"PIE Level", i32 2}
!33 = !{i32 7, !"uwtable", i32 2}
!34 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!35 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!36 = distinct !DISubprogram(name: "safe_advance_gcc30475", scope: !2, file: !2, line: 32, type: !37, scopeLine: 33, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !18, retainedNodes: !40)
!37 = !DISubroutineType(types: !38)
!38 = !{!21, !21, !39}
!39 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!40 = !{!41, !42}
!41 = !DILocalVariable(name: "base", arg: 1, scope: !36, file: !2, line: 32, type: !21)
!42 = !DILocalVariable(name: "offset", arg: 2, scope: !36, file: !2, line: 32, type: !39)
!43 = !DILocation(line: 0, scope: !36)
!44 = !DILocation(line: 43, column: 23, scope: !45)
!45 = distinct !DILexicalBlock(scope: !36, file: !2, line: 43, column: 9)
!46 = !DILocation(line: 43, column: 9, scope: !36)
!47 = !DILocation(line: 47, column: 1, scope: !36)
!48 = distinct !DISubprogram(name: "compute_end_gcc30475", scope: !2, file: !2, line: 53, type: !49, scopeLine: 54, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !18, retainedNodes: !51)
!49 = !DISubroutineType(types: !50)
!50 = !{!39, !39, !39}
!51 = !{!52, !53}
!52 = !DILocalVariable(name: "start", arg: 1, scope: !48, file: !2, line: 53, type: !39)
!53 = !DILocalVariable(name: "length", arg: 2, scope: !48, file: !2, line: 53, type: !39)
!54 = !DILocation(line: 0, scope: !48)
!55 = !DILocation(line: 55, column: 9, scope: !48)
!56 = !DILocation(line: 59, column: 1, scope: !48)
!57 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 61, type: !58, scopeLine: 62, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !18, retainedNodes: !60)
!58 = !DISubroutineType(types: !59)
!59 = !{!39}
!60 = !{!61, !65, !66}
!61 = !DILocalVariable(name: "buf", scope: !57, file: !2, line: 63, type: !62)
!62 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 512, elements: !63)
!63 = !{!64}
!64 = !DISubrange(count: 64)
!65 = !DILocalVariable(name: "p1", scope: !57, file: !2, line: 66, type: !21)
!66 = !DILocalVariable(name: "p2", scope: !57, file: !2, line: 67, type: !21)
!67 = distinct !DIAssignID()
!68 = !DILocation(line: 0, scope: !57)
!69 = !DILocation(line: 63, column: 5, scope: !57)
!70 = !DILocation(line: 63, column: 10, scope: !57)
!71 = distinct !DIAssignID()
!72 = distinct !DIAssignID()
!73 = distinct !DIAssignID()
!74 = !DILocation(line: 68, column: 5, scope: !57)
!75 = !DILocation(line: 69, column: 5, scope: !57)
!76 = !DILocation(line: 72, column: 5, scope: !57)
!77 = !DILocation(line: 73, column: 5, scope: !57)
!78 = !DILocation(line: 77, column: 1, scope: !57)
!79 = !DILocation(line: 76, column: 5, scope: !57)
!80 = !DISubprogram(name: "printf", scope: !81, file: !81, line: 363, type: !82, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!81 = !DIFile(filename: "/usr/include/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "1e435c46987a169d9f9186f63a512303")
!82 = !DISubroutineType(types: !83)
!83 = !{!39, !84, null}
!84 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !85)
!85 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !86, size: 64)
!86 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
