; ModuleID = '/home/chira/ub-detector/testcases/strict_aliasing.c'
source_filename = "/home/chira/ub-detector/testcases/strict_aliasing.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [4 x i8] c"%f\0A\00", align 1, !dbg !0

; Function Attrs: noinline nounwind optnone uwtable
define dso_local float @int_to_float_bits(i32 noundef %x) #0 !dbg !21 {
entry:
  %x.addr = alloca i32, align 4
  store i32 %x, ptr %x.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %x.addr, metadata !26, metadata !DIExpression()), !dbg !27
  %0 = load float, ptr %x.addr, align 4, !dbg !28
  ret float %0, !dbg !29
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 !dbg !30 {
entry:
  %retval = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  %call = call float @int_to_float_bits(i32 noundef 1065353216), !dbg !33
  %conv = fpext float %call to double, !dbg !33
  %call1 = call i32 (ptr, ...) @printf(ptr noundef @.str, double noundef %conv), !dbg !34
  ret i32 0, !dbg !35
}

declare i32 @printf(ptr noundef, ...) #2

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!7}
!llvm.module.flags = !{!13, !14, !15, !16, !17, !18, !19}
!llvm.ident = !{!20}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 12, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "testcases/strict_aliasing.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "7dc69c2f4986700ad72eae67d9fd2103")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 32, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 4)
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, globals: !12, splitDebugInlining: false, nameTableKind: None)
!8 = !DIFile(filename: "/home/chira/ub-detector/testcases/strict_aliasing.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "7dc69c2f4986700ad72eae67d9fd2103")
!9 = !{!10}
!10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !11, size: 64)
!11 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!12 = !{!0}
!13 = !{i32 7, !"Dwarf Version", i32 5}
!14 = !{i32 2, !"Debug Info Version", i32 3}
!15 = !{i32 1, !"wchar_size", i32 4}
!16 = !{i32 8, !"PIC Level", i32 2}
!17 = !{i32 7, !"PIE Level", i32 2}
!18 = !{i32 7, !"uwtable", i32 2}
!19 = !{i32 7, !"frame-pointer", i32 2}
!20 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!21 = distinct !DISubprogram(name: "int_to_float_bits", scope: !2, file: !2, line: 6, type: !22, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !7, retainedNodes: !25)
!22 = !DISubroutineType(types: !23)
!23 = !{!11, !24}
!24 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!25 = !{}
!26 = !DILocalVariable(name: "x", arg: 1, scope: !21, file: !2, line: 6, type: !24)
!27 = !DILocation(line: 6, column: 29, scope: !21)
!28 = !DILocation(line: 8, column: 12, scope: !21)
!29 = !DILocation(line: 8, column: 5, scope: !21)
!30 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 11, type: !31, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !7)
!31 = !DISubroutineType(types: !32)
!32 = !{!24}
!33 = !DILocation(line: 12, column: 20, scope: !30)
!34 = !DILocation(line: 12, column: 5, scope: !30)
!35 = !DILocation(line: 13, column: 5, scope: !30)
