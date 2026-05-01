; ModuleID = '/home/chira/ub-detector/testcases/cve_cases/cve_2018_6952.c'
source_filename = "/home/chira/ub-detector/testcases/cve_cases/cve_2018_6952.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [18 x i8] c"small hunk  : %d\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [18 x i8] c"large hunk  : %d\0A\00", align 1, !dbg !7
@.str.2 = private unnamed_addr constant [18 x i8] c"huge lines  : %d\0A\00", align 1, !dbg !9

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @another_hunk_simplified(i32 noundef %remaining, i32 noundef %extra_lines) #0 !dbg !22 {
entry:
  %retval = alloca i32, align 4
  %remaining.addr = alloca i32, align 4
  %extra_lines.addr = alloca i32, align 4
  %bytes_per_line = alloca i32, align 4
  %extra = alloca i32, align 4
  store i32 %remaining, ptr %remaining.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %remaining.addr, metadata !27, metadata !DIExpression()), !dbg !28
  store i32 %extra_lines, ptr %extra_lines.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %extra_lines.addr, metadata !29, metadata !DIExpression()), !dbg !30
  call void @llvm.dbg.declare(metadata ptr %bytes_per_line, metadata !31, metadata !DIExpression()), !dbg !32
  store i32 80, ptr %bytes_per_line, align 4, !dbg !32
  call void @llvm.dbg.declare(metadata ptr %extra, metadata !33, metadata !DIExpression()), !dbg !34
  %0 = load i32, ptr %extra_lines.addr, align 4, !dbg !35
  %1 = load i32, ptr %bytes_per_line, align 4, !dbg !36
  %mul = mul nsw i32 %0, %1, !dbg !37
  store i32 %mul, ptr %extra, align 4, !dbg !34
  %2 = load i32, ptr %remaining.addr, align 4, !dbg !38
  %3 = load i32, ptr %extra, align 4, !dbg !40
  %add = add nsw i32 %2, %3, !dbg !41
  %4 = load i32, ptr %remaining.addr, align 4, !dbg !42
  %cmp = icmp slt i32 %add, %4, !dbg !43
  br i1 %cmp, label %if.then, label %if.end, !dbg !44

if.then:                                          ; preds = %entry
  store i32 -1, ptr %retval, align 4, !dbg !45
  br label %return, !dbg !45

if.end:                                           ; preds = %entry
  %5 = load i32, ptr %remaining.addr, align 4, !dbg !47
  %6 = load i32, ptr %extra, align 4, !dbg !49
  %add1 = add nsw i32 %5, %6, !dbg !50
  %cmp2 = icmp sgt i32 %add1, 4096, !dbg !51
  br i1 %cmp2, label %if.then3, label %if.end4, !dbg !52

if.then3:                                         ; preds = %if.end
  store i32 -1, ptr %retval, align 4, !dbg !53
  br label %return, !dbg !53

if.end4:                                          ; preds = %if.end
  store i32 0, ptr %retval, align 4, !dbg !55
  br label %return, !dbg !55

return:                                           ; preds = %if.end4, %if.then3, %if.then
  %7 = load i32, ptr %retval, align 4, !dbg !56
  ret i32 %7, !dbg !56
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 !dbg !57 {
entry:
  %retval = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  %call = call i32 @another_hunk_simplified(i32 noundef 100, i32 noundef 10), !dbg !60
  %call1 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %call), !dbg !61
  %call2 = call i32 @another_hunk_simplified(i32 noundef 100, i32 noundef 200), !dbg !62
  %call3 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, i32 noundef %call2), !dbg !63
  %call4 = call i32 @another_hunk_simplified(i32 noundef 1000, i32 noundef 26843545), !dbg !64
  %call5 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef %call4), !dbg !65
  ret i32 0, !dbg !66
}

declare i32 @printf(ptr noundef, ...) #2

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
!11 = distinct !DICompileUnit(language: DW_LANG_C11, file: !12, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !13, splitDebugInlining: false, nameTableKind: None)
!12 = !DIFile(filename: "/home/chira/ub-detector/testcases/cve_cases/cve_2018_6952.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "046d116b34d8b3bc28598405ad286a56")
!13 = !{!0, !7, !9}
!14 = !{i32 7, !"Dwarf Version", i32 5}
!15 = !{i32 2, !"Debug Info Version", i32 3}
!16 = !{i32 1, !"wchar_size", i32 4}
!17 = !{i32 8, !"PIC Level", i32 2}
!18 = !{i32 7, !"PIE Level", i32 2}
!19 = !{i32 7, !"uwtable", i32 2}
!20 = !{i32 7, !"frame-pointer", i32 2}
!21 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!22 = distinct !DISubprogram(name: "another_hunk_simplified", scope: !2, file: !2, line: 34, type: !23, scopeLine: 35, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !26)
!23 = !DISubroutineType(types: !24)
!24 = !{!25, !25, !25}
!25 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!26 = !{}
!27 = !DILocalVariable(name: "remaining", arg: 1, scope: !22, file: !2, line: 34, type: !25)
!28 = !DILocation(line: 34, column: 33, scope: !22)
!29 = !DILocalVariable(name: "extra_lines", arg: 2, scope: !22, file: !2, line: 34, type: !25)
!30 = !DILocation(line: 34, column: 48, scope: !22)
!31 = !DILocalVariable(name: "bytes_per_line", scope: !22, file: !2, line: 36, type: !25)
!32 = !DILocation(line: 36, column: 9, scope: !22)
!33 = !DILocalVariable(name: "extra", scope: !22, file: !2, line: 50, type: !25)
!34 = !DILocation(line: 50, column: 9, scope: !22)
!35 = !DILocation(line: 50, column: 17, scope: !22)
!36 = !DILocation(line: 50, column: 31, scope: !22)
!37 = !DILocation(line: 50, column: 29, scope: !22)
!38 = !DILocation(line: 51, column: 9, scope: !39)
!39 = distinct !DILexicalBlock(scope: !22, file: !2, line: 51, column: 9)
!40 = !DILocation(line: 51, column: 21, scope: !39)
!41 = !DILocation(line: 51, column: 19, scope: !39)
!42 = !DILocation(line: 51, column: 29, scope: !39)
!43 = !DILocation(line: 51, column: 27, scope: !39)
!44 = !DILocation(line: 51, column: 9, scope: !22)
!45 = !DILocation(line: 52, column: 9, scope: !46)
!46 = distinct !DILexicalBlock(scope: !39, file: !2, line: 51, column: 40)
!47 = !DILocation(line: 55, column: 9, scope: !48)
!48 = distinct !DILexicalBlock(scope: !22, file: !2, line: 55, column: 9)
!49 = !DILocation(line: 55, column: 21, scope: !48)
!50 = !DILocation(line: 55, column: 19, scope: !48)
!51 = !DILocation(line: 55, column: 27, scope: !48)
!52 = !DILocation(line: 55, column: 9, scope: !22)
!53 = !DILocation(line: 56, column: 9, scope: !54)
!54 = distinct !DILexicalBlock(scope: !48, file: !2, line: 55, column: 45)
!55 = !DILocation(line: 59, column: 5, scope: !22)
!56 = !DILocation(line: 60, column: 1, scope: !22)
!57 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 62, type: !58, scopeLine: 63, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !11)
!58 = !DISubroutineType(types: !59)
!59 = !{!25}
!60 = !DILocation(line: 64, column: 34, scope: !57)
!61 = !DILocation(line: 64, column: 5, scope: !57)
!62 = !DILocation(line: 65, column: 34, scope: !57)
!63 = !DILocation(line: 65, column: 5, scope: !57)
!64 = !DILocation(line: 68, column: 34, scope: !57)
!65 = !DILocation(line: 68, column: 5, scope: !57)
!66 = !DILocation(line: 69, column: 5, scope: !57)
