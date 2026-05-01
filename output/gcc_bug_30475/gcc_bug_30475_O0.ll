; ModuleID = '/home/chira/ub-detector/testcases/cve_cases/gcc_bug_30475.c'
source_filename = "/home/chira/ub-detector/testcases/cve_cases/gcc_bug_30475.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [19 x i8] c"advance  4   : %s\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [7 x i8] c"(null)\00", align 1, !dbg !7
@.str.2 = private unnamed_addr constant [19 x i8] c"advance MAX  : %s\0A\00", align 1, !dbg !12
@.str.3 = private unnamed_addr constant [12 x i8] c"(non-null!)\00", align 1, !dbg !14
@.str.4 = private unnamed_addr constant [19 x i8] c"end  10+5    : %d\0A\00", align 1, !dbg !19
@.str.5 = private unnamed_addr constant [19 x i8] c"end MAX+1    : %d\0A\00", align 1, !dbg !21

; Function Attrs: noinline nounwind optnone uwtable
define dso_local ptr @safe_advance_gcc30475(ptr noundef %base, i32 noundef %offset) #0 !dbg !36 {
entry:
  %retval = alloca ptr, align 8
  %base.addr = alloca ptr, align 8
  %offset.addr = alloca i32, align 4
  store ptr %base, ptr %base.addr, align 8
  call void @llvm.dbg.declare(metadata ptr %base.addr, metadata !41, metadata !DIExpression()), !dbg !42
  store i32 %offset, ptr %offset.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %offset.addr, metadata !43, metadata !DIExpression()), !dbg !44
  %0 = load ptr, ptr %base.addr, align 8, !dbg !45
  %1 = load i32, ptr %offset.addr, align 4, !dbg !47
  %idx.ext = sext i32 %1 to i64, !dbg !48
  %add.ptr = getelementptr inbounds i8, ptr %0, i64 %idx.ext, !dbg !48
  %2 = load ptr, ptr %base.addr, align 8, !dbg !49
  %cmp = icmp ult ptr %add.ptr, %2, !dbg !50
  br i1 %cmp, label %if.then, label %if.end, !dbg !51

if.then:                                          ; preds = %entry
  store ptr null, ptr %retval, align 8, !dbg !52
  br label %return, !dbg !52

if.end:                                           ; preds = %entry
  %3 = load ptr, ptr %base.addr, align 8, !dbg !54
  %4 = load i32, ptr %offset.addr, align 4, !dbg !55
  %idx.ext1 = sext i32 %4 to i64, !dbg !56
  %add.ptr2 = getelementptr inbounds i8, ptr %3, i64 %idx.ext1, !dbg !56
  store ptr %add.ptr2, ptr %retval, align 8, !dbg !57
  br label %return, !dbg !57

return:                                           ; preds = %if.end, %if.then
  %5 = load ptr, ptr %retval, align 8, !dbg !58
  ret ptr %5, !dbg !58
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @compute_end_gcc30475(i32 noundef %start, i32 noundef %length) #0 !dbg !59 {
entry:
  %retval = alloca i32, align 4
  %start.addr = alloca i32, align 4
  %length.addr = alloca i32, align 4
  store i32 %start, ptr %start.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %start.addr, metadata !62, metadata !DIExpression()), !dbg !63
  store i32 %length, ptr %length.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %length.addr, metadata !64, metadata !DIExpression()), !dbg !65
  %0 = load i32, ptr %start.addr, align 4, !dbg !66
  %1 = load i32, ptr %length.addr, align 4, !dbg !68
  %add = add nsw i32 %0, %1, !dbg !69
  %2 = load i32, ptr %start.addr, align 4, !dbg !70
  %cmp = icmp slt i32 %add, %2, !dbg !71
  br i1 %cmp, label %if.then, label %if.end, !dbg !72

if.then:                                          ; preds = %entry
  store i32 -1, ptr %retval, align 4, !dbg !73
  br label %return, !dbg !73

if.end:                                           ; preds = %entry
  %3 = load i32, ptr %start.addr, align 4, !dbg !75
  %4 = load i32, ptr %length.addr, align 4, !dbg !76
  %add1 = add nsw i32 %3, %4, !dbg !77
  store i32 %add1, ptr %retval, align 4, !dbg !78
  br label %return, !dbg !78

return:                                           ; preds = %if.end, %if.then
  %5 = load i32, ptr %retval, align 4, !dbg !79
  ret i32 %5, !dbg !79
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 !dbg !80 {
entry:
  %retval = alloca i32, align 4
  %buf = alloca [64 x i8], align 16
  %p1 = alloca ptr, align 8
  %p2 = alloca ptr, align 8
  store i32 0, ptr %retval, align 4
  call void @llvm.dbg.declare(metadata ptr %buf, metadata !83, metadata !DIExpression()), !dbg !87
  call void @llvm.memset.p0.i64(ptr align 16 %buf, i8 0, i64 64, i1 false), !dbg !87
  %0 = getelementptr inbounds [64 x i8], ptr %buf, i32 0, i32 0, !dbg !87
  store i8 104, ptr %0, align 16, !dbg !87
  %1 = getelementptr inbounds [64 x i8], ptr %buf, i32 0, i32 1, !dbg !87
  store i8 101, ptr %1, align 1, !dbg !87
  %2 = getelementptr inbounds [64 x i8], ptr %buf, i32 0, i32 2, !dbg !87
  store i8 108, ptr %2, align 2, !dbg !87
  %3 = getelementptr inbounds [64 x i8], ptr %buf, i32 0, i32 3, !dbg !87
  store i8 108, ptr %3, align 1, !dbg !87
  %4 = getelementptr inbounds [64 x i8], ptr %buf, i32 0, i32 4, !dbg !87
  store i8 111, ptr %4, align 4, !dbg !87
  call void @llvm.dbg.declare(metadata ptr %p1, metadata !88, metadata !DIExpression()), !dbg !89
  %arraydecay = getelementptr inbounds [64 x i8], ptr %buf, i64 0, i64 0, !dbg !90
  %call = call ptr @safe_advance_gcc30475(ptr noundef %arraydecay, i32 noundef 4), !dbg !91
  store ptr %call, ptr %p1, align 8, !dbg !89
  call void @llvm.dbg.declare(metadata ptr %p2, metadata !92, metadata !DIExpression()), !dbg !93
  %arraydecay1 = getelementptr inbounds [64 x i8], ptr %buf, i64 0, i64 0, !dbg !94
  %call2 = call ptr @safe_advance_gcc30475(ptr noundef %arraydecay1, i32 noundef 2147483647), !dbg !95
  store ptr %call2, ptr %p2, align 8, !dbg !93
  %5 = load ptr, ptr %p1, align 8, !dbg !96
  %tobool = icmp ne ptr %5, null, !dbg !96
  br i1 %tobool, label %cond.true, label %cond.false, !dbg !96

cond.true:                                        ; preds = %entry
  %6 = load ptr, ptr %p1, align 8, !dbg !97
  br label %cond.end, !dbg !96

cond.false:                                       ; preds = %entry
  br label %cond.end, !dbg !96

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi ptr [ %6, %cond.true ], [ @.str.1, %cond.false ], !dbg !96
  %call3 = call i32 (ptr, ...) @printf(ptr noundef @.str, ptr noundef %cond), !dbg !98
  %7 = load ptr, ptr %p2, align 8, !dbg !99
  %tobool4 = icmp ne ptr %7, null, !dbg !99
  %8 = zext i1 %tobool4 to i64, !dbg !99
  %cond5 = select i1 %tobool4, ptr @.str.3, ptr @.str.1, !dbg !99
  %call6 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, ptr noundef %cond5), !dbg !100
  %call7 = call i32 @compute_end_gcc30475(i32 noundef 10, i32 noundef 5), !dbg !101
  %call8 = call i32 (ptr, ...) @printf(ptr noundef @.str.4, i32 noundef %call7), !dbg !102
  %call9 = call i32 @compute_end_gcc30475(i32 noundef 2147483647, i32 noundef 1), !dbg !103
  %call10 = call i32 (ptr, ...) @printf(ptr noundef @.str.5, i32 noundef %call9), !dbg !104
  ret i32 0, !dbg !105
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare i32 @printf(ptr noundef, ...) #3

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!23}
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
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 68, type: !9, isLocal: true, isDefinition: true)
!9 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 56, elements: !10)
!10 = !{!11}
!11 = !DISubrange(count: 7)
!12 = !DIGlobalVariableExpression(var: !13, expr: !DIExpression())
!13 = distinct !DIGlobalVariable(scope: null, file: !2, line: 69, type: !3, isLocal: true, isDefinition: true)
!14 = !DIGlobalVariableExpression(var: !15, expr: !DIExpression())
!15 = distinct !DIGlobalVariable(scope: null, file: !2, line: 69, type: !16, isLocal: true, isDefinition: true)
!16 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 96, elements: !17)
!17 = !{!18}
!18 = !DISubrange(count: 12)
!19 = !DIGlobalVariableExpression(var: !20, expr: !DIExpression())
!20 = distinct !DIGlobalVariable(scope: null, file: !2, line: 72, type: !3, isLocal: true, isDefinition: true)
!21 = !DIGlobalVariableExpression(var: !22, expr: !DIExpression())
!22 = distinct !DIGlobalVariable(scope: null, file: !2, line: 73, type: !3, isLocal: true, isDefinition: true)
!23 = distinct !DICompileUnit(language: DW_LANG_C11, file: !24, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !25, globals: !27, splitDebugInlining: false, nameTableKind: None)
!24 = !DIFile(filename: "/home/chira/ub-detector/testcases/cve_cases/gcc_bug_30475.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "159b6d4a3638c0ef69cc08812ce2de57")
!25 = !{!26}
!26 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !4, size: 64)
!27 = !{!0, !7, !12, !14, !19, !21}
!28 = !{i32 7, !"Dwarf Version", i32 5}
!29 = !{i32 2, !"Debug Info Version", i32 3}
!30 = !{i32 1, !"wchar_size", i32 4}
!31 = !{i32 8, !"PIC Level", i32 2}
!32 = !{i32 7, !"PIE Level", i32 2}
!33 = !{i32 7, !"uwtable", i32 2}
!34 = !{i32 7, !"frame-pointer", i32 2}
!35 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!36 = distinct !DISubprogram(name: "safe_advance_gcc30475", scope: !2, file: !2, line: 32, type: !37, scopeLine: 33, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !23, retainedNodes: !40)
!37 = !DISubroutineType(types: !38)
!38 = !{!26, !26, !39}
!39 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!40 = !{}
!41 = !DILocalVariable(name: "base", arg: 1, scope: !36, file: !2, line: 32, type: !26)
!42 = !DILocation(line: 32, column: 35, scope: !36)
!43 = !DILocalVariable(name: "offset", arg: 2, scope: !36, file: !2, line: 32, type: !39)
!44 = !DILocation(line: 32, column: 45, scope: !36)
!45 = !DILocation(line: 43, column: 9, scope: !46)
!46 = distinct !DILexicalBlock(scope: !36, file: !2, line: 43, column: 9)
!47 = !DILocation(line: 43, column: 16, scope: !46)
!48 = !DILocation(line: 43, column: 14, scope: !46)
!49 = !DILocation(line: 43, column: 25, scope: !46)
!50 = !DILocation(line: 43, column: 23, scope: !46)
!51 = !DILocation(line: 43, column: 9, scope: !36)
!52 = !DILocation(line: 44, column: 9, scope: !53)
!53 = distinct !DILexicalBlock(scope: !46, file: !2, line: 43, column: 31)
!54 = !DILocation(line: 46, column: 12, scope: !36)
!55 = !DILocation(line: 46, column: 19, scope: !36)
!56 = !DILocation(line: 46, column: 17, scope: !36)
!57 = !DILocation(line: 46, column: 5, scope: !36)
!58 = !DILocation(line: 47, column: 1, scope: !36)
!59 = distinct !DISubprogram(name: "compute_end_gcc30475", scope: !2, file: !2, line: 53, type: !60, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !23, retainedNodes: !40)
!60 = !DISubroutineType(types: !61)
!61 = !{!39, !39, !39}
!62 = !DILocalVariable(name: "start", arg: 1, scope: !59, file: !2, line: 53, type: !39)
!63 = !DILocation(line: 53, column: 30, scope: !59)
!64 = !DILocalVariable(name: "length", arg: 2, scope: !59, file: !2, line: 53, type: !39)
!65 = !DILocation(line: 53, column: 41, scope: !59)
!66 = !DILocation(line: 55, column: 9, scope: !67)
!67 = distinct !DILexicalBlock(scope: !59, file: !2, line: 55, column: 9)
!68 = !DILocation(line: 55, column: 17, scope: !67)
!69 = !DILocation(line: 55, column: 15, scope: !67)
!70 = !DILocation(line: 55, column: 26, scope: !67)
!71 = !DILocation(line: 55, column: 24, scope: !67)
!72 = !DILocation(line: 55, column: 9, scope: !59)
!73 = !DILocation(line: 56, column: 9, scope: !74)
!74 = distinct !DILexicalBlock(scope: !67, file: !2, line: 55, column: 33)
!75 = !DILocation(line: 58, column: 12, scope: !59)
!76 = !DILocation(line: 58, column: 20, scope: !59)
!77 = !DILocation(line: 58, column: 18, scope: !59)
!78 = !DILocation(line: 58, column: 5, scope: !59)
!79 = !DILocation(line: 59, column: 1, scope: !59)
!80 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 61, type: !81, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !23, retainedNodes: !40)
!81 = !DISubroutineType(types: !82)
!82 = !{!39}
!83 = !DILocalVariable(name: "buf", scope: !80, file: !2, line: 63, type: !84)
!84 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 512, elements: !85)
!85 = !{!86}
!86 = !DISubrange(count: 64)
!87 = !DILocation(line: 63, column: 10, scope: !80)
!88 = !DILocalVariable(name: "p1", scope: !80, file: !2, line: 66, type: !26)
!89 = !DILocation(line: 66, column: 11, scope: !80)
!90 = !DILocation(line: 66, column: 38, scope: !80)
!91 = !DILocation(line: 66, column: 16, scope: !80)
!92 = !DILocalVariable(name: "p2", scope: !80, file: !2, line: 67, type: !26)
!93 = !DILocation(line: 67, column: 11, scope: !80)
!94 = !DILocation(line: 67, column: 38, scope: !80)
!95 = !DILocation(line: 67, column: 16, scope: !80)
!96 = !DILocation(line: 68, column: 36, scope: !80)
!97 = !DILocation(line: 68, column: 41, scope: !80)
!98 = !DILocation(line: 68, column: 5, scope: !80)
!99 = !DILocation(line: 69, column: 36, scope: !80)
!100 = !DILocation(line: 69, column: 5, scope: !80)
!101 = !DILocation(line: 72, column: 36, scope: !80)
!102 = !DILocation(line: 72, column: 5, scope: !80)
!103 = !DILocation(line: 73, column: 36, scope: !80)
!104 = !DILocation(line: 73, column: 5, scope: !80)
!105 = !DILocation(line: 76, column: 5, scope: !80)
