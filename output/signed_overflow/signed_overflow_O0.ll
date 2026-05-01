; ModuleID = '/home/chira/ub-detector/testcases/signed_overflow.c'
source_filename = "/home/chira/ub-detector/testcases/signed_overflow.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [19 x i8] c"INT_MAX check: %d\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [19 x i8] c"Normal check:  %d\0A\00", align 1, !dbg !7

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @check_overflow(i32 noundef %x) #0 !dbg !20 {
entry:
  %retval = alloca i32, align 4
  %x.addr = alloca i32, align 4
  store i32 %x, ptr %x.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %x.addr, metadata !25, metadata !DIExpression()), !dbg !26
  %0 = load i32, ptr %x.addr, align 4, !dbg !27
  %add = add nsw i32 %0, 1, !dbg !29
  %1 = load i32, ptr %x.addr, align 4, !dbg !30
  %cmp = icmp sgt i32 %add, %1, !dbg !31
  br i1 %cmp, label %if.then, label %if.else, !dbg !32

if.then:                                          ; preds = %entry
  store i32 1, ptr %retval, align 4, !dbg !33
  br label %return, !dbg !33

if.else:                                          ; preds = %entry
  store i32 0, ptr %retval, align 4, !dbg !35
  br label %return, !dbg !35

return:                                           ; preds = %if.else, %if.then
  %2 = load i32, ptr %retval, align 4, !dbg !37
  ret i32 %2, !dbg !37
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 !dbg !38 {
entry:
  %retval = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  %call = call i32 @check_overflow(i32 noundef 2147483647), !dbg !41
  %call1 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %call), !dbg !42
  %call2 = call i32 @check_overflow(i32 noundef 42), !dbg !43
  %call3 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, i32 noundef %call2), !dbg !44
  ret i32 0, !dbg !45
}

declare i32 @printf(ptr noundef, ...) #2

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!9}
!llvm.module.flags = !{!12, !13, !14, !15, !16, !17, !18}
!llvm.ident = !{!19}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 19, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "testcases/signed_overflow.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "2da889180b1cbfb807ff176490ae9224")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 152, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 19)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 20, type: !3, isLocal: true, isDefinition: true)
!9 = distinct !DICompileUnit(language: DW_LANG_C11, file: !10, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !11, splitDebugInlining: false, nameTableKind: None)
!10 = !DIFile(filename: "/home/chira/ub-detector/testcases/signed_overflow.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "2da889180b1cbfb807ff176490ae9224")
!11 = !{!0, !7}
!12 = !{i32 7, !"Dwarf Version", i32 5}
!13 = !{i32 2, !"Debug Info Version", i32 3}
!14 = !{i32 1, !"wchar_size", i32 4}
!15 = !{i32 8, !"PIC Level", i32 2}
!16 = !{i32 7, !"PIE Level", i32 2}
!17 = !{i32 7, !"uwtable", i32 2}
!18 = !{i32 7, !"frame-pointer", i32 2}
!19 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!20 = distinct !DISubprogram(name: "check_overflow", scope: !2, file: !2, line: 7, type: !21, scopeLine: 7, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !9, retainedNodes: !24)
!21 = !DISubroutineType(types: !22)
!22 = !{!23, !23}
!23 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!24 = !{}
!25 = !DILocalVariable(name: "x", arg: 1, scope: !20, file: !2, line: 7, type: !23)
!26 = !DILocation(line: 7, column: 24, scope: !20)
!27 = !DILocation(line: 11, column: 9, scope: !28)
!28 = distinct !DILexicalBlock(scope: !20, file: !2, line: 11, column: 9)
!29 = !DILocation(line: 11, column: 11, scope: !28)
!30 = !DILocation(line: 11, column: 17, scope: !28)
!31 = !DILocation(line: 11, column: 15, scope: !28)
!32 = !DILocation(line: 11, column: 9, scope: !20)
!33 = !DILocation(line: 12, column: 9, scope: !34)
!34 = distinct !DILexicalBlock(scope: !28, file: !2, line: 11, column: 20)
!35 = !DILocation(line: 14, column: 9, scope: !36)
!36 = distinct !DILexicalBlock(scope: !28, file: !2, line: 13, column: 12)
!37 = !DILocation(line: 16, column: 1, scope: !20)
!38 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 18, type: !39, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !9)
!39 = !DISubroutineType(types: !40)
!40 = !{!23}
!41 = !DILocation(line: 19, column: 35, scope: !38)
!42 = !DILocation(line: 19, column: 5, scope: !38)
!43 = !DILocation(line: 20, column: 35, scope: !38)
!44 = !DILocation(line: 20, column: 5, scope: !38)
!45 = !DILocation(line: 21, column: 5, scope: !38)
