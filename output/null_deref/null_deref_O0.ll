; ModuleID = '/home/chira/ub-detector/testcases/null_deref.c'
source_filename = "/home/chira/ub-detector/testcases/null_deref.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1, !dbg !0

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @use_ptr(ptr noundef %ptr) #0 !dbg !18 {
entry:
  %retval = alloca i32, align 4
  %ptr.addr = alloca ptr, align 8
  %null_ptr = alloca ptr, align 8
  store ptr %ptr, ptr %ptr.addr, align 8
  call void @llvm.dbg.declare(metadata ptr %ptr.addr, metadata !24, metadata !DIExpression()), !dbg !25
  %0 = load ptr, ptr %ptr.addr, align 8, !dbg !26
  %tobool = icmp ne ptr %0, null, !dbg !26
  br i1 %tobool, label %if.then, label %if.else, !dbg !28

if.then:                                          ; preds = %entry
  %1 = load ptr, ptr %ptr.addr, align 8, !dbg !29
  %2 = load i32, ptr %1, align 4, !dbg !31
  store i32 %2, ptr %retval, align 4, !dbg !32
  br label %return, !dbg !32

if.else:                                          ; preds = %entry
  call void @llvm.dbg.declare(metadata ptr %null_ptr, metadata !33, metadata !DIExpression()), !dbg !35
  store ptr null, ptr %null_ptr, align 8, !dbg !35
  %3 = load ptr, ptr %null_ptr, align 8, !dbg !36
  %4 = load i32, ptr %3, align 4, !dbg !37
  store i32 %4, ptr %retval, align 4, !dbg !38
  br label %return, !dbg !38

return:                                           ; preds = %if.else, %if.then
  %5 = load i32, ptr %retval, align 4, !dbg !39
  ret i32 %5, !dbg !39
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 !dbg !40 {
entry:
  %retval = alloca i32, align 4
  %x = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  call void @llvm.dbg.declare(metadata ptr %x, metadata !43, metadata !DIExpression()), !dbg !44
  store i32 42, ptr %x, align 4, !dbg !44
  %call = call i32 @use_ptr(ptr noundef %x), !dbg !45
  %call1 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %call), !dbg !46
  ret i32 0, !dbg !47
}

declare i32 @printf(ptr noundef, ...) #2

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !9, splitDebugInlining: false, nameTableKind: None)
!8 = !DIFile(filename: "/home/chira/ub-detector/testcases/null_deref.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "4f4fb97ed6de826608d414dfeca9216b")
!9 = !{!0}
!10 = !{i32 7, !"Dwarf Version", i32 5}
!11 = !{i32 2, !"Debug Info Version", i32 3}
!12 = !{i32 1, !"wchar_size", i32 4}
!13 = !{i32 8, !"PIC Level", i32 2}
!14 = !{i32 7, !"PIE Level", i32 2}
!15 = !{i32 7, !"uwtable", i32 2}
!16 = !{i32 7, !"frame-pointer", i32 2}
!17 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!18 = distinct !DISubprogram(name: "use_ptr", scope: !2, file: !2, line: 6, type: !19, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !7, retainedNodes: !23)
!19 = !DISubroutineType(types: !20)
!20 = !{!21, !22}
!21 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!22 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !21, size: 64)
!23 = !{}
!24 = !DILocalVariable(name: "ptr", arg: 1, scope: !18, file: !2, line: 6, type: !22)
!25 = !DILocation(line: 6, column: 18, scope: !18)
!26 = !DILocation(line: 7, column: 9, scope: !27)
!27 = distinct !DILexicalBlock(scope: !18, file: !2, line: 7, column: 9)
!28 = !DILocation(line: 7, column: 9, scope: !18)
!29 = !DILocation(line: 8, column: 17, scope: !30)
!30 = distinct !DILexicalBlock(scope: !27, file: !2, line: 7, column: 14)
!31 = !DILocation(line: 8, column: 16, scope: !30)
!32 = !DILocation(line: 8, column: 9, scope: !30)
!33 = !DILocalVariable(name: "null_ptr", scope: !34, file: !2, line: 11, type: !22)
!34 = distinct !DILexicalBlock(scope: !27, file: !2, line: 9, column: 12)
!35 = !DILocation(line: 11, column: 14, scope: !34)
!36 = !DILocation(line: 12, column: 17, scope: !34)
!37 = !DILocation(line: 12, column: 16, scope: !34)
!38 = !DILocation(line: 12, column: 9, scope: !34)
!39 = !DILocation(line: 14, column: 1, scope: !18)
!40 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 16, type: !41, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !7, retainedNodes: !23)
!41 = !DISubroutineType(types: !42)
!42 = !{!21}
!43 = !DILocalVariable(name: "x", scope: !40, file: !2, line: 17, type: !21)
!44 = !DILocation(line: 17, column: 9, scope: !40)
!45 = !DILocation(line: 18, column: 20, scope: !40)
!46 = !DILocation(line: 18, column: 5, scope: !40)
!47 = !DILocation(line: 19, column: 5, scope: !40)
