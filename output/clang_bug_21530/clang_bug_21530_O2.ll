; ModuleID = '/home/chira/ub-detector/testcases/cve_cases/clang_bug_21530.c'
source_filename = "/home/chira/ub-detector/testcases/cve_cases/clang_bug_21530.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [48 x i8] c"bits_to_float(0x3f800000) = %f  (expected 1.0)\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [48 x i8] c"reinterpret(0x3f800000)   = %f  (expected 1.0)\0A\00", align 1, !dbg !7
@.str.2 = private unnamed_addr constant [49 x i8] c"fast_inv_sqrt(4.0)        = %f  (expected ~0.5)\0A\00", align 1, !dbg !9

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef float @bits_to_float_clang21530(i32 noundef %bits) local_unnamed_addr #0 !dbg !30 {
entry:
  tail call void @llvm.dbg.value(metadata i32 %bits, metadata !39, metadata !DIExpression()), !dbg !40
  %0 = bitcast i32 %bits to float, !dbg !41
  ret float %0, !dbg !42
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef float @reinterpret_via_memory_clang21530(i32 noundef %x) local_unnamed_addr #0 !dbg !43 {
entry:
  tail call void @llvm.dbg.value(metadata i32 %x, metadata !45, metadata !DIExpression()), !dbg !48
  tail call void @llvm.dbg.value(metadata i32 %x, metadata !46, metadata !DIExpression()), !dbg !48
  %0 = bitcast i32 %x to float, !dbg !49
  tail call void @llvm.dbg.value(metadata float %0, metadata !47, metadata !DIExpression()), !dbg !48
  ret float %0, !dbg !50
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local float @fast_inv_sqrt_clang21530(float noundef %number) local_unnamed_addr #0 !dbg !51 {
entry:
  tail call void @llvm.dbg.value(metadata float %number, metadata !55, metadata !DIExpression()), !dbg !61
  tail call void @llvm.dbg.value(metadata float 1.500000e+00, metadata !59, metadata !DIExpression()), !dbg !61
  tail call void @llvm.dbg.value(metadata float poison, metadata !57, metadata !DIExpression()), !dbg !61
  tail call void @llvm.dbg.value(metadata float %number, metadata !58, metadata !DIExpression()), !dbg !61
  tail call void @llvm.dbg.value(metadata float %number, metadata !56, metadata !DIExpression(DW_OP_LLVM_fragment, 0, 32)), !dbg !61
  tail call void @llvm.dbg.value(metadata i32 poison, metadata !56, metadata !DIExpression(DW_OP_LLVM_fragment, 32, 32)), !dbg !61
  tail call void @llvm.dbg.value(metadata i32 poison, metadata !56, metadata !DIExpression(DW_OP_LLVM_fragment, 0, 32)), !dbg !61
  tail call void @llvm.dbg.value(metadata i64 poison, metadata !56, metadata !DIExpression(DW_OP_LLVM_convert, 64, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_stack_value, DW_OP_LLVM_fragment, 32, 32)), !dbg !61
  tail call void @llvm.dbg.value(metadata float poison, metadata !58, metadata !DIExpression()), !dbg !61
  tail call void @llvm.dbg.value(metadata float poison, metadata !58, metadata !DIExpression()), !dbg !61
  ret float poison, !dbg !62
}

; Function Attrs: nofree nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #1 !dbg !63 {
entry:
  tail call void @llvm.dbg.value(metadata i32 1065353216, metadata !68, metadata !DIExpression()), !dbg !69
  %call1 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, double noundef 1.000000e+00), !dbg !70
  %call4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, double noundef 1.000000e+00), !dbg !71
  %call7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, double noundef undef), !dbg !72
  ret i32 0, !dbg !73
}

; Function Attrs: nofree nounwind
declare !dbg !74 noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.dbg.cu = !{!14}
!llvm.module.flags = !{!22, !23, !24, !25, !26, !27, !28}
!llvm.ident = !{!29}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 93, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "testcases/cve_cases/clang_bug_21530.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "2e3c8fc2a6d4cc6e02a3788bf933c289")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 384, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 48)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 96, type: !3, isLocal: true, isDefinition: true)
!9 = !DIGlobalVariableExpression(var: !10, expr: !DIExpression())
!10 = distinct !DIGlobalVariable(scope: null, file: !2, line: 99, type: !11, isLocal: true, isDefinition: true)
!11 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 392, elements: !12)
!12 = !{!13}
!13 = !DISubrange(count: 49)
!14 = distinct !DICompileUnit(language: DW_LANG_C11, file: !15, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !16, globals: !21, splitDebugInlining: false, nameTableKind: None)
!15 = !DIFile(filename: "/home/chira/ub-detector/testcases/cve_cases/clang_bug_21530.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "2e3c8fc2a6d4cc6e02a3788bf933c289")
!16 = !{!17, !19}
!17 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !18, size: 64)
!18 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!19 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !20, size: 64)
!20 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!21 = !{!0, !7, !9}
!22 = !{i32 7, !"Dwarf Version", i32 5}
!23 = !{i32 2, !"Debug Info Version", i32 3}
!24 = !{i32 1, !"wchar_size", i32 4}
!25 = !{i32 8, !"PIC Level", i32 2}
!26 = !{i32 7, !"PIE Level", i32 2}
!27 = !{i32 7, !"uwtable", i32 2}
!28 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!29 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!30 = distinct !DISubprogram(name: "bits_to_float_clang21530", scope: !2, file: !2, line: 31, type: !31, scopeLine: 32, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !14, retainedNodes: !38)
!31 = !DISubroutineType(types: !32)
!32 = !{!18, !33}
!33 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint32_t", file: !34, line: 26, baseType: !35)
!34 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/stdint-uintn.h", directory: "", checksumkind: CSK_MD5, checksum: "256fcabbefa27ca8cf5e6d37525e6e16")
!35 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint32_t", file: !36, line: 42, baseType: !37)
!36 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types.h", directory: "", checksumkind: CSK_MD5, checksum: "e1865d9fe29fe1b5ced550b7ba458f9e")
!37 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!38 = !{!39}
!39 = !DILocalVariable(name: "bits", arg: 1, scope: !30, file: !2, line: 31, type: !33)
!40 = !DILocation(line: 0, scope: !30)
!41 = !DILocation(line: 40, column: 12, scope: !30)
!42 = !DILocation(line: 40, column: 5, scope: !30)
!43 = distinct !DISubprogram(name: "reinterpret_via_memory_clang21530", scope: !2, file: !2, line: 47, type: !31, scopeLine: 48, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !14, retainedNodes: !44)
!44 = !{!45, !46, !47}
!45 = !DILocalVariable(name: "x", arg: 1, scope: !43, file: !2, line: 47, type: !33)
!46 = !DILocalVariable(name: "storage", scope: !43, file: !2, line: 49, type: !33)
!47 = !DILocalVariable(name: "result", scope: !43, file: !2, line: 60, type: !18)
!48 = !DILocation(line: 0, scope: !43)
!49 = !DILocation(line: 60, column: 20, scope: !43)
!50 = !DILocation(line: 61, column: 5, scope: !43)
!51 = distinct !DISubprogram(name: "fast_inv_sqrt_clang21530", scope: !2, file: !2, line: 69, type: !52, scopeLine: 70, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !14, retainedNodes: !54)
!52 = !DISubroutineType(types: !53)
!53 = !{!18, !18}
!54 = !{!55, !56, !57, !58, !59}
!55 = !DILocalVariable(name: "number", arg: 1, scope: !51, file: !2, line: 69, type: !18)
!56 = !DILocalVariable(name: "i", scope: !51, file: !2, line: 71, type: !20)
!57 = !DILocalVariable(name: "x2", scope: !51, file: !2, line: 72, type: !18)
!58 = !DILocalVariable(name: "y", scope: !51, file: !2, line: 72, type: !18)
!59 = !DILocalVariable(name: "threehalfs", scope: !51, file: !2, line: 73, type: !60)
!60 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !18)
!61 = !DILocation(line: 0, scope: !51)
!62 = !DILocation(line: 86, column: 5, scope: !51)
!63 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 89, type: !64, scopeLine: 90, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !14, retainedNodes: !67)
!64 = !DISubroutineType(types: !65)
!65 = !{!66}
!66 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!67 = !{!68}
!68 = !DILocalVariable(name: "ieee_one", scope: !63, file: !2, line: 91, type: !33)
!69 = !DILocation(line: 0, scope: !63)
!70 = !DILocation(line: 93, column: 5, scope: !63)
!71 = !DILocation(line: 96, column: 5, scope: !63)
!72 = !DILocation(line: 99, column: 5, scope: !63)
!73 = !DILocation(line: 102, column: 5, scope: !63)
!74 = !DISubprogram(name: "printf", scope: !75, file: !75, line: 363, type: !76, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!75 = !DIFile(filename: "/usr/include/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "1e435c46987a169d9f9186f63a512303")
!76 = !DISubroutineType(types: !77)
!77 = !{!66, !78, null}
!78 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !79)
!79 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !80, size: 64)
!80 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
