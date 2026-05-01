; ModuleID = '/home/chira/ub-detector/testcases/cve_cases/gcc_bug_58640.c'
source_filename = "/home/chira/ub-detector/testcases/cve_cases/gcc_bug_58640.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.Result = type { i32, i32 }

@.str = private unnamed_addr constant [22 x i8] c"mode=1 input=200: %d\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [22 x i8] c"mode=1 input=50 : %d\0A\00", align 1, !dbg !7
@.str.2 = private unnamed_addr constant [22 x i8] c"mode=0 input=50 : %d\0A\00", align 1, !dbg !9
@.str.3 = private unnamed_addr constant [22 x i8] c"uninit flag=1   : %d\0A\00", align 1, !dbg !11
@.str.4 = private unnamed_addr constant [22 x i8] c"uninit flag=0   : %d\0A\00", align 1, !dbg !13

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @process_gcc58640(i32 noundef %mode, i32 noundef %input) #0 !dbg !26 {
entry:
  %retval = alloca i32, align 4
  %mode.addr = alloca i32, align 4
  %input.addr = alloca i32, align 4
  %r = alloca %struct.Result, align 4
  store i32 %mode, ptr %mode.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %mode.addr, metadata !31, metadata !DIExpression()), !dbg !32
  store i32 %input, ptr %input.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %input.addr, metadata !33, metadata !DIExpression()), !dbg !34
  call void @llvm.dbg.declare(metadata ptr %r, metadata !35, metadata !DIExpression()), !dbg !41
  %0 = load i32, ptr %mode.addr, align 4, !dbg !42
  %cmp = icmp sgt i32 %0, 0, !dbg !44
  br i1 %cmp, label %if.then, label %if.end, !dbg !45

if.then:                                          ; preds = %entry
  %1 = load i32, ptr %input.addr, align 4, !dbg !46
  %cmp1 = icmp sgt i32 %1, 100, !dbg !48
  %2 = zext i1 %cmp1 to i64, !dbg !49
  %cond = select i1 %cmp1, i32 1, i32 0, !dbg !49
  %code = getelementptr inbounds %struct.Result, ptr %r, i32 0, i32 0, !dbg !50
  store i32 %cond, ptr %code, align 4, !dbg !51
  %3 = load i32, ptr %input.addr, align 4, !dbg !52
  %value = getelementptr inbounds %struct.Result, ptr %r, i32 0, i32 1, !dbg !53
  store i32 %3, ptr %value, align 4, !dbg !54
  br label %if.end, !dbg !55

if.end:                                           ; preds = %if.then, %entry
  %code2 = getelementptr inbounds %struct.Result, ptr %r, i32 0, i32 0, !dbg !56
  %4 = load i32, ptr %code2, align 4, !dbg !56
  %cmp3 = icmp ne i32 %4, 0, !dbg !58
  br i1 %cmp3, label %if.then4, label %if.end5, !dbg !59

if.then4:                                         ; preds = %if.end
  store i32 -1, ptr %retval, align 4, !dbg !60
  br label %return, !dbg !60

if.end5:                                          ; preds = %if.end
  store i32 0, ptr %retval, align 4, !dbg !62
  br label %return, !dbg !62

return:                                           ; preds = %if.end5, %if.then4
  %5 = load i32, ptr %retval, align 4, !dbg !63
  ret i32 %5, !dbg !63
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @uninit_branch_gcc58640(i32 noundef %flag) #0 !dbg !64 {
entry:
  %flag.addr = alloca i32, align 4
  %status = alloca i32, align 4
  store i32 %flag, ptr %flag.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %flag.addr, metadata !67, metadata !DIExpression()), !dbg !68
  call void @llvm.dbg.declare(metadata ptr %status, metadata !69, metadata !DIExpression()), !dbg !70
  %0 = load i32, ptr %flag.addr, align 4, !dbg !71
  %tobool = icmp ne i32 %0, 0, !dbg !71
  br i1 %tobool, label %if.then, label %if.end, !dbg !73

if.then:                                          ; preds = %entry
  store i32 1, ptr %status, align 4, !dbg !74
  br label %if.end, !dbg !76

if.end:                                           ; preds = %if.then, %entry
  %1 = load i32, ptr %status, align 4, !dbg !77
  ret i32 %1, !dbg !78
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 !dbg !79 {
entry:
  %retval = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  %call = call i32 @process_gcc58640(i32 noundef 1, i32 noundef 200), !dbg !82
  %call1 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %call), !dbg !83
  %call2 = call i32 @process_gcc58640(i32 noundef 1, i32 noundef 50), !dbg !84
  %call3 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, i32 noundef %call2), !dbg !85
  %call4 = call i32 @process_gcc58640(i32 noundef 0, i32 noundef 50), !dbg !86
  %call5 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef %call4), !dbg !87
  %call6 = call i32 @uninit_branch_gcc58640(i32 noundef 1), !dbg !88
  %call7 = call i32 (ptr, ...) @printf(ptr noundef @.str.3, i32 noundef %call6), !dbg !89
  %call8 = call i32 @uninit_branch_gcc58640(i32 noundef 0), !dbg !90
  %call9 = call i32 (ptr, ...) @printf(ptr noundef @.str.4, i32 noundef %call8), !dbg !91
  ret i32 0, !dbg !92
}

declare i32 @printf(ptr noundef, ...) #2

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
!15 = distinct !DICompileUnit(language: DW_LANG_C11, file: !16, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !17, splitDebugInlining: false, nameTableKind: None)
!16 = !DIFile(filename: "/home/chira/ub-detector/testcases/cve_cases/gcc_bug_58640.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "9fc80c0227541a6e4b5423c38c1013e7")
!17 = !{!0, !7, !9, !11, !13}
!18 = !{i32 7, !"Dwarf Version", i32 5}
!19 = !{i32 2, !"Debug Info Version", i32 3}
!20 = !{i32 1, !"wchar_size", i32 4}
!21 = !{i32 8, !"PIC Level", i32 2}
!22 = !{i32 7, !"PIE Level", i32 2}
!23 = !{i32 7, !"uwtable", i32 2}
!24 = !{i32 7, !"frame-pointer", i32 2}
!25 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!26 = distinct !DISubprogram(name: "process_gcc58640", scope: !2, file: !2, line: 33, type: !27, scopeLine: 34, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !15, retainedNodes: !30)
!27 = !DISubroutineType(types: !28)
!28 = !{!29, !29, !29}
!29 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!30 = !{}
!31 = !DILocalVariable(name: "mode", arg: 1, scope: !26, file: !2, line: 33, type: !29)
!32 = !DILocation(line: 33, column: 26, scope: !26)
!33 = !DILocalVariable(name: "input", arg: 2, scope: !26, file: !2, line: 33, type: !29)
!34 = !DILocation(line: 33, column: 36, scope: !26)
!35 = !DILocalVariable(name: "r", scope: !26, file: !2, line: 35, type: !36)
!36 = !DIDerivedType(tag: DW_TAG_typedef, name: "Result", file: !2, line: 26, baseType: !37)
!37 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !2, line: 23, size: 64, elements: !38)
!38 = !{!39, !40}
!39 = !DIDerivedType(tag: DW_TAG_member, name: "code", scope: !37, file: !2, line: 24, baseType: !29, size: 32)
!40 = !DIDerivedType(tag: DW_TAG_member, name: "value", scope: !37, file: !2, line: 25, baseType: !29, size: 32, offset: 32)
!41 = !DILocation(line: 35, column: 12, scope: !26)
!42 = !DILocation(line: 37, column: 9, scope: !43)
!43 = distinct !DILexicalBlock(scope: !26, file: !2, line: 37, column: 9)
!44 = !DILocation(line: 37, column: 14, scope: !43)
!45 = !DILocation(line: 37, column: 9, scope: !26)
!46 = !DILocation(line: 38, column: 20, scope: !47)
!47 = distinct !DILexicalBlock(scope: !43, file: !2, line: 37, column: 19)
!48 = !DILocation(line: 38, column: 26, scope: !47)
!49 = !DILocation(line: 38, column: 19, scope: !47)
!50 = !DILocation(line: 38, column: 11, scope: !47)
!51 = !DILocation(line: 38, column: 17, scope: !47)
!52 = !DILocation(line: 39, column: 19, scope: !47)
!53 = !DILocation(line: 39, column: 11, scope: !47)
!54 = !DILocation(line: 39, column: 17, scope: !47)
!55 = !DILocation(line: 40, column: 5, scope: !47)
!56 = !DILocation(line: 50, column: 11, scope: !57)
!57 = distinct !DILexicalBlock(scope: !26, file: !2, line: 50, column: 9)
!58 = !DILocation(line: 50, column: 16, scope: !57)
!59 = !DILocation(line: 50, column: 9, scope: !26)
!60 = !DILocation(line: 51, column: 9, scope: !61)
!61 = distinct !DILexicalBlock(scope: !57, file: !2, line: 50, column: 22)
!62 = !DILocation(line: 54, column: 5, scope: !26)
!63 = !DILocation(line: 55, column: 1, scope: !26)
!64 = distinct !DISubprogram(name: "uninit_branch_gcc58640", scope: !2, file: !2, line: 61, type: !65, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !15, retainedNodes: !30)
!65 = !DISubroutineType(types: !66)
!66 = !{!29, !29}
!67 = !DILocalVariable(name: "flag", arg: 1, scope: !64, file: !2, line: 61, type: !29)
!68 = !DILocation(line: 61, column: 32, scope: !64)
!69 = !DILocalVariable(name: "status", scope: !64, file: !2, line: 63, type: !29)
!70 = !DILocation(line: 63, column: 9, scope: !64)
!71 = !DILocation(line: 65, column: 9, scope: !72)
!72 = distinct !DILexicalBlock(scope: !64, file: !2, line: 65, column: 9)
!73 = !DILocation(line: 65, column: 9, scope: !64)
!74 = !DILocation(line: 66, column: 16, scope: !75)
!75 = distinct !DILexicalBlock(scope: !72, file: !2, line: 65, column: 15)
!76 = !DILocation(line: 67, column: 5, scope: !75)
!77 = !DILocation(line: 70, column: 12, scope: !64)
!78 = !DILocation(line: 70, column: 5, scope: !64)
!79 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 73, type: !80, scopeLine: 74, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !15)
!80 = !DISubroutineType(types: !81)
!81 = !{!29}
!82 = !DILocation(line: 75, column: 38, scope: !79)
!83 = !DILocation(line: 75, column: 5, scope: !79)
!84 = !DILocation(line: 76, column: 38, scope: !79)
!85 = !DILocation(line: 76, column: 5, scope: !79)
!86 = !DILocation(line: 79, column: 38, scope: !79)
!87 = !DILocation(line: 79, column: 5, scope: !79)
!88 = !DILocation(line: 81, column: 38, scope: !79)
!89 = !DILocation(line: 81, column: 5, scope: !79)
!90 = !DILocation(line: 83, column: 38, scope: !79)
!91 = !DILocation(line: 83, column: 5, scope: !79)
!92 = !DILocation(line: 84, column: 5, scope: !79)
