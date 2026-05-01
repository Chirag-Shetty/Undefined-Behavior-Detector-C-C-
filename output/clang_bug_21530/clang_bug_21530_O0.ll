; ModuleID = '/home/chira/ub-detector/testcases/cve_cases/clang_bug_21530.c'
source_filename = "/home/chira/ub-detector/testcases/cve_cases/clang_bug_21530.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [48 x i8] c"bits_to_float(0x3f800000) = %f  (expected 1.0)\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [48 x i8] c"reinterpret(0x3f800000)   = %f  (expected 1.0)\0A\00", align 1, !dbg !7
@.str.2 = private unnamed_addr constant [49 x i8] c"fast_inv_sqrt(4.0)        = %f  (expected ~0.5)\0A\00", align 1, !dbg !9

; Function Attrs: noinline nounwind optnone uwtable
define dso_local float @bits_to_float_clang21530(i32 noundef %bits) #0 !dbg !30 {
entry:
  %bits.addr = alloca i32, align 4
  store i32 %bits, ptr %bits.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %bits.addr, metadata !39, metadata !DIExpression()), !dbg !40
  %0 = load float, ptr %bits.addr, align 4, !dbg !41
  ret float %0, !dbg !42
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local float @reinterpret_via_memory_clang21530(i32 noundef %x) #0 !dbg !43 {
entry:
  %x.addr = alloca i32, align 4
  %storage = alloca i32, align 4
  %result = alloca float, align 4
  store i32 %x, ptr %x.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %x.addr, metadata !44, metadata !DIExpression()), !dbg !45
  call void @llvm.dbg.declare(metadata ptr %storage, metadata !46, metadata !DIExpression()), !dbg !47
  %0 = load i32, ptr %x.addr, align 4, !dbg !48
  store i32 %0, ptr %storage, align 4, !dbg !47
  call void @llvm.dbg.declare(metadata ptr %result, metadata !49, metadata !DIExpression()), !dbg !50
  %1 = load float, ptr %storage, align 4, !dbg !51
  store float %1, ptr %result, align 4, !dbg !50
  %2 = load float, ptr %result, align 4, !dbg !52
  ret float %2, !dbg !53
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local float @fast_inv_sqrt_clang21530(float noundef %number) #0 !dbg !54 {
entry:
  %number.addr = alloca float, align 4
  %i = alloca i64, align 8
  %x2 = alloca float, align 4
  %y = alloca float, align 4
  %threehalfs = alloca float, align 4
  store float %number, ptr %number.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %number.addr, metadata !57, metadata !DIExpression()), !dbg !58
  call void @llvm.dbg.declare(metadata ptr %i, metadata !59, metadata !DIExpression()), !dbg !60
  call void @llvm.dbg.declare(metadata ptr %x2, metadata !61, metadata !DIExpression()), !dbg !62
  call void @llvm.dbg.declare(metadata ptr %y, metadata !63, metadata !DIExpression()), !dbg !64
  call void @llvm.dbg.declare(metadata ptr %threehalfs, metadata !65, metadata !DIExpression()), !dbg !67
  store float 1.500000e+00, ptr %threehalfs, align 4, !dbg !67
  %0 = load float, ptr %number.addr, align 4, !dbg !68
  %mul = fmul float %0, 5.000000e-01, !dbg !69
  store float %mul, ptr %x2, align 4, !dbg !70
  %1 = load float, ptr %number.addr, align 4, !dbg !71
  store float %1, ptr %y, align 4, !dbg !72
  %2 = load i64, ptr %y, align 4, !dbg !73
  store i64 %2, ptr %i, align 8, !dbg !74
  %3 = load i64, ptr %i, align 8, !dbg !75
  %shr = ashr i64 %3, 1, !dbg !76
  %sub = sub nsw i64 1597463007, %shr, !dbg !77
  store i64 %sub, ptr %i, align 8, !dbg !78
  %4 = load float, ptr %i, align 8, !dbg !79
  store float %4, ptr %y, align 4, !dbg !80
  %5 = load float, ptr %y, align 4, !dbg !81
  %6 = load float, ptr %x2, align 4, !dbg !82
  %7 = load float, ptr %y, align 4, !dbg !83
  %mul1 = fmul float %6, %7, !dbg !84
  %8 = load float, ptr %y, align 4, !dbg !85
  %neg = fneg float %mul1, !dbg !86
  %9 = call float @llvm.fmuladd.f32(float %neg, float %8, float 1.500000e+00), !dbg !86
  %mul3 = fmul float %5, %9, !dbg !87
  store float %mul3, ptr %y, align 4, !dbg !88
  %10 = load float, ptr %y, align 4, !dbg !89
  ret float %10, !dbg !90
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 !dbg !91 {
entry:
  %retval = alloca i32, align 4
  %ieee_one = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  call void @llvm.dbg.declare(metadata ptr %ieee_one, metadata !95, metadata !DIExpression()), !dbg !96
  store i32 1065353216, ptr %ieee_one, align 4, !dbg !96
  %0 = load i32, ptr %ieee_one, align 4, !dbg !97
  %call = call float @bits_to_float_clang21530(i32 noundef %0), !dbg !98
  %conv = fpext float %call to double, !dbg !98
  %call1 = call i32 (ptr, ...) @printf(ptr noundef @.str, double noundef %conv), !dbg !99
  %1 = load i32, ptr %ieee_one, align 4, !dbg !100
  %call2 = call float @reinterpret_via_memory_clang21530(i32 noundef %1), !dbg !101
  %conv3 = fpext float %call2 to double, !dbg !101
  %call4 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, double noundef %conv3), !dbg !102
  %call5 = call float @fast_inv_sqrt_clang21530(float noundef 4.000000e+00), !dbg !103
  %conv6 = fpext float %call5 to double, !dbg !103
  %call7 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, double noundef %conv6), !dbg !104
  ret i32 0, !dbg !105
}

declare i32 @printf(ptr noundef, ...) #2

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
!14 = distinct !DICompileUnit(language: DW_LANG_C11, file: !15, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !16, globals: !21, splitDebugInlining: false, nameTableKind: None)
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
!28 = !{i32 7, !"frame-pointer", i32 2}
!29 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!30 = distinct !DISubprogram(name: "bits_to_float_clang21530", scope: !2, file: !2, line: 31, type: !31, scopeLine: 32, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !14, retainedNodes: !38)
!31 = !DISubroutineType(types: !32)
!32 = !{!18, !33}
!33 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint32_t", file: !34, line: 26, baseType: !35)
!34 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/stdint-uintn.h", directory: "", checksumkind: CSK_MD5, checksum: "256fcabbefa27ca8cf5e6d37525e6e16")
!35 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint32_t", file: !36, line: 42, baseType: !37)
!36 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types.h", directory: "", checksumkind: CSK_MD5, checksum: "e1865d9fe29fe1b5ced550b7ba458f9e")
!37 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!38 = !{}
!39 = !DILocalVariable(name: "bits", arg: 1, scope: !30, file: !2, line: 31, type: !33)
!40 = !DILocation(line: 31, column: 41, scope: !30)
!41 = !DILocation(line: 40, column: 12, scope: !30)
!42 = !DILocation(line: 40, column: 5, scope: !30)
!43 = distinct !DISubprogram(name: "reinterpret_via_memory_clang21530", scope: !2, file: !2, line: 47, type: !31, scopeLine: 48, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !14, retainedNodes: !38)
!44 = !DILocalVariable(name: "x", arg: 1, scope: !43, file: !2, line: 47, type: !33)
!45 = !DILocation(line: 47, column: 50, scope: !43)
!46 = !DILocalVariable(name: "storage", scope: !43, file: !2, line: 49, type: !33)
!47 = !DILocation(line: 49, column: 14, scope: !43)
!48 = !DILocation(line: 49, column: 24, scope: !43)
!49 = !DILocalVariable(name: "result", scope: !43, file: !2, line: 60, type: !18)
!50 = !DILocation(line: 60, column: 11, scope: !43)
!51 = !DILocation(line: 60, column: 20, scope: !43)
!52 = !DILocation(line: 61, column: 12, scope: !43)
!53 = !DILocation(line: 61, column: 5, scope: !43)
!54 = distinct !DISubprogram(name: "fast_inv_sqrt_clang21530", scope: !2, file: !2, line: 69, type: !55, scopeLine: 70, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !14, retainedNodes: !38)
!55 = !DISubroutineType(types: !56)
!56 = !{!18, !18}
!57 = !DILocalVariable(name: "number", arg: 1, scope: !54, file: !2, line: 69, type: !18)
!58 = !DILocation(line: 69, column: 38, scope: !54)
!59 = !DILocalVariable(name: "i", scope: !54, file: !2, line: 71, type: !20)
!60 = !DILocation(line: 71, column: 10, scope: !54)
!61 = !DILocalVariable(name: "x2", scope: !54, file: !2, line: 72, type: !18)
!62 = !DILocation(line: 72, column: 11, scope: !54)
!63 = !DILocalVariable(name: "y", scope: !54, file: !2, line: 72, type: !18)
!64 = !DILocation(line: 72, column: 15, scope: !54)
!65 = !DILocalVariable(name: "threehalfs", scope: !54, file: !2, line: 73, type: !66)
!66 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !18)
!67 = !DILocation(line: 73, column: 17, scope: !54)
!68 = !DILocation(line: 75, column: 10, scope: !54)
!69 = !DILocation(line: 75, column: 17, scope: !54)
!70 = !DILocation(line: 75, column: 8, scope: !54)
!71 = !DILocation(line: 76, column: 10, scope: !54)
!72 = !DILocation(line: 76, column: 8, scope: !54)
!73 = !DILocation(line: 80, column: 10, scope: !54)
!74 = !DILocation(line: 80, column: 8, scope: !54)
!75 = !DILocation(line: 81, column: 24, scope: !54)
!76 = !DILocation(line: 81, column: 26, scope: !54)
!77 = !DILocation(line: 81, column: 21, scope: !54)
!78 = !DILocation(line: 81, column: 8, scope: !54)
!79 = !DILocation(line: 82, column: 10, scope: !54)
!80 = !DILocation(line: 82, column: 8, scope: !54)
!81 = !DILocation(line: 85, column: 10, scope: !54)
!82 = !DILocation(line: 85, column: 29, scope: !54)
!83 = !DILocation(line: 85, column: 34, scope: !54)
!84 = !DILocation(line: 85, column: 32, scope: !54)
!85 = !DILocation(line: 85, column: 38, scope: !54)
!86 = !DILocation(line: 85, column: 26, scope: !54)
!87 = !DILocation(line: 85, column: 12, scope: !54)
!88 = !DILocation(line: 85, column: 8, scope: !54)
!89 = !DILocation(line: 86, column: 12, scope: !54)
!90 = !DILocation(line: 86, column: 5, scope: !54)
!91 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 89, type: !92, scopeLine: 90, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !14, retainedNodes: !38)
!92 = !DISubroutineType(types: !93)
!93 = !{!94}
!94 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!95 = !DILocalVariable(name: "ieee_one", scope: !91, file: !2, line: 91, type: !33)
!96 = !DILocation(line: 91, column: 14, scope: !91)
!97 = !DILocation(line: 94, column: 37, scope: !91)
!98 = !DILocation(line: 94, column: 12, scope: !91)
!99 = !DILocation(line: 93, column: 5, scope: !91)
!100 = !DILocation(line: 97, column: 46, scope: !91)
!101 = !DILocation(line: 97, column: 12, scope: !91)
!102 = !DILocation(line: 96, column: 5, scope: !91)
!103 = !DILocation(line: 100, column: 12, scope: !91)
!104 = !DILocation(line: 99, column: 5, scope: !91)
!105 = !DILocation(line: 102, column: 5, scope: !91)
