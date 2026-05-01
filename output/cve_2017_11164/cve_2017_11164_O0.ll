; ModuleID = '/home/chira/ub-detector/testcases/cve_cases/cve_2017_11164.c'
source_filename = "/home/chira/ub-detector/testcases/cve_cases/cve_2017_11164.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@__const.main.subject = private unnamed_addr constant [12 x i8] c"hello world\00", align 1
@.str = private unnamed_addr constant [22 x i8] c"normal offset 3 : %d\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [22 x i8] c"bad offset -1   : %d\0A\00", align 1, !dbg !7
@.str.2 = private unnamed_addr constant [22 x i8] c"overflow offset : %d\0A\00", align 1, !dbg !9

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @pcre_exec_simplified(ptr noundef %subject, i32 noundef %length, i32 noundef %startoffset) #0 !dbg !24 {
entry:
  %retval = alloca i32, align 4
  %subject.addr = alloca ptr, align 8
  %length.addr = alloca i32, align 4
  %startoffset.addr = alloca i32, align 4
  store ptr %subject, ptr %subject.addr, align 8
  call void @llvm.dbg.declare(metadata ptr %subject.addr, metadata !30, metadata !DIExpression()), !dbg !31
  store i32 %length, ptr %length.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %length.addr, metadata !32, metadata !DIExpression()), !dbg !33
  store i32 %startoffset, ptr %startoffset.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %startoffset.addr, metadata !34, metadata !DIExpression()), !dbg !35
  %0 = load i32, ptr %startoffset.addr, align 4, !dbg !36
  %add = add nsw i32 %0, 1024, !dbg !38
  %1 = load i32, ptr %startoffset.addr, align 4, !dbg !39
  %cmp = icmp slt i32 %add, %1, !dbg !40
  br i1 %cmp, label %if.then, label %if.end, !dbg !41

if.then:                                          ; preds = %entry
  store i32 -24, ptr %retval, align 4, !dbg !42
  br label %return, !dbg !42

if.end:                                           ; preds = %entry
  %2 = load i32, ptr %startoffset.addr, align 4, !dbg !44
  %cmp1 = icmp slt i32 %2, 0, !dbg !46
  br i1 %cmp1, label %if.then3, label %lor.lhs.false, !dbg !47

lor.lhs.false:                                    ; preds = %if.end
  %3 = load i32, ptr %startoffset.addr, align 4, !dbg !48
  %4 = load i32, ptr %length.addr, align 4, !dbg !49
  %cmp2 = icmp sgt i32 %3, %4, !dbg !50
  br i1 %cmp2, label %if.then3, label %if.end4, !dbg !51

if.then3:                                         ; preds = %lor.lhs.false, %if.end
  store i32 -24, ptr %retval, align 4, !dbg !52
  br label %return, !dbg !52

if.end4:                                          ; preds = %lor.lhs.false
  %5 = load i32, ptr %startoffset.addr, align 4, !dbg !54
  %6 = load i32, ptr %length.addr, align 4, !dbg !55
  %cmp5 = icmp slt i32 %5, %6, !dbg !56
  %7 = zext i1 %cmp5 to i64, !dbg !57
  %cond = select i1 %cmp5, i32 0, i32 -1, !dbg !57
  store i32 %cond, ptr %retval, align 4, !dbg !58
  br label %return, !dbg !58

return:                                           ; preds = %if.end4, %if.then3, %if.then
  %8 = load i32, ptr %retval, align 4, !dbg !59
  ret i32 %8, !dbg !59
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 !dbg !60 {
entry:
  %retval = alloca i32, align 4
  %subject = alloca [12 x i8], align 1
  %len = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  call void @llvm.dbg.declare(metadata ptr %subject, metadata !62, metadata !DIExpression()), !dbg !66
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %subject, ptr align 1 @__const.main.subject, i64 12, i1 false), !dbg !66
  call void @llvm.dbg.declare(metadata ptr %len, metadata !67, metadata !DIExpression()), !dbg !68
  %arraydecay = getelementptr inbounds [12 x i8], ptr %subject, i64 0, i64 0, !dbg !69
  %call = call i64 @strlen(ptr noundef %arraydecay) #5, !dbg !70
  %conv = trunc i64 %call to i32, !dbg !71
  store i32 %conv, ptr %len, align 4, !dbg !68
  %arraydecay1 = getelementptr inbounds [12 x i8], ptr %subject, i64 0, i64 0, !dbg !72
  %0 = load i32, ptr %len, align 4, !dbg !73
  %call2 = call i32 @pcre_exec_simplified(ptr noundef %arraydecay1, i32 noundef %0, i32 noundef 3), !dbg !74
  %call3 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %call2), !dbg !75
  %arraydecay4 = getelementptr inbounds [12 x i8], ptr %subject, i64 0, i64 0, !dbg !76
  %1 = load i32, ptr %len, align 4, !dbg !77
  %call5 = call i32 @pcre_exec_simplified(ptr noundef %arraydecay4, i32 noundef %1, i32 noundef -1), !dbg !78
  %call6 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, i32 noundef %call5), !dbg !79
  %arraydecay7 = getelementptr inbounds [12 x i8], ptr %subject, i64 0, i64 0, !dbg !80
  %2 = load i32, ptr %len, align 4, !dbg !81
  %call8 = call i32 @pcre_exec_simplified(ptr noundef %arraydecay7, i32 noundef %2, i32 noundef 2147483647), !dbg !82
  %call9 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef %call8), !dbg !83
  ret i32 0, !dbg !84
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #3

declare i32 @printf(ptr noundef, ...) #4

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind willreturn memory(read) }

!llvm.dbg.cu = !{!11}
!llvm.module.flags = !{!16, !17, !18, !19, !20, !21, !22}
!llvm.ident = !{!23}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 64, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "testcases/cve_cases/cve_2017_11164.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "bb58b8127c70a33c639dcb27eeb4209f")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 176, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 22)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 65, type: !3, isLocal: true, isDefinition: true)
!9 = !DIGlobalVariableExpression(var: !10, expr: !DIExpression())
!10 = distinct !DIGlobalVariable(scope: null, file: !2, line: 68, type: !3, isLocal: true, isDefinition: true)
!11 = distinct !DICompileUnit(language: DW_LANG_C11, file: !12, producer: "Ubuntu clang version 18.1.3 (1ubuntu1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !13, globals: !15, splitDebugInlining: false, nameTableKind: None)
!12 = !DIFile(filename: "/home/chira/ub-detector/testcases/cve_cases/cve_2017_11164.c", directory: "/home/chira/ub-detector", checksumkind: CSK_MD5, checksum: "bb58b8127c70a33c639dcb27eeb4209f")
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!0, !7, !9}
!16 = !{i32 7, !"Dwarf Version", i32 5}
!17 = !{i32 2, !"Debug Info Version", i32 3}
!18 = !{i32 1, !"wchar_size", i32 4}
!19 = !{i32 8, !"PIC Level", i32 2}
!20 = !{i32 7, !"PIE Level", i32 2}
!21 = !{i32 7, !"uwtable", i32 2}
!22 = !{i32 7, !"frame-pointer", i32 2}
!23 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
!24 = distinct !DISubprogram(name: "pcre_exec_simplified", scope: !2, file: !2, line: 33, type: !25, scopeLine: 34, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !29)
!25 = !DISubroutineType(types: !26)
!26 = !{!14, !27, !14, !14}
!27 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !28, size: 64)
!28 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
!29 = !{}
!30 = !DILocalVariable(name: "subject", arg: 1, scope: !24, file: !2, line: 33, type: !27)
!31 = !DILocation(line: 33, column: 38, scope: !24)
!32 = !DILocalVariable(name: "length", arg: 2, scope: !24, file: !2, line: 33, type: !14)
!33 = !DILocation(line: 33, column: 51, scope: !24)
!34 = !DILocalVariable(name: "startoffset", arg: 3, scope: !24, file: !2, line: 33, type: !14)
!35 = !DILocation(line: 33, column: 63, scope: !24)
!36 = !DILocation(line: 47, column: 9, scope: !37)
!37 = distinct !DILexicalBlock(scope: !24, file: !2, line: 47, column: 9)
!38 = !DILocation(line: 47, column: 21, scope: !37)
!39 = !DILocation(line: 47, column: 47, scope: !37)
!40 = !DILocation(line: 47, column: 45, scope: !37)
!41 = !DILocation(line: 47, column: 9, scope: !24)
!42 = !DILocation(line: 48, column: 9, scope: !43)
!43 = distinct !DILexicalBlock(scope: !37, file: !2, line: 47, column: 60)
!44 = !DILocation(line: 51, column: 9, scope: !45)
!45 = distinct !DILexicalBlock(scope: !24, file: !2, line: 51, column: 9)
!46 = !DILocation(line: 51, column: 21, scope: !45)
!47 = !DILocation(line: 51, column: 25, scope: !45)
!48 = !DILocation(line: 51, column: 28, scope: !45)
!49 = !DILocation(line: 51, column: 42, scope: !45)
!50 = !DILocation(line: 51, column: 40, scope: !45)
!51 = !DILocation(line: 51, column: 9, scope: !24)
!52 = !DILocation(line: 52, column: 9, scope: !53)
!53 = distinct !DILexicalBlock(scope: !45, file: !2, line: 51, column: 50)
!54 = !DILocation(line: 56, column: 13, scope: !24)
!55 = !DILocation(line: 56, column: 27, scope: !24)
!56 = !DILocation(line: 56, column: 25, scope: !24)
!57 = !DILocation(line: 56, column: 12, scope: !24)
!58 = !DILocation(line: 56, column: 5, scope: !24)
!59 = !DILocation(line: 57, column: 1, scope: !24)
!60 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 59, type: !61, scopeLine: 60, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !11, retainedNodes: !29)
!61 = !DISubroutineType(types: !13)
!62 = !DILocalVariable(name: "subject", scope: !60, file: !2, line: 61, type: !63)
!63 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 96, elements: !64)
!64 = !{!65}
!65 = !DISubrange(count: 12)
!66 = !DILocation(line: 61, column: 10, scope: !60)
!67 = !DILocalVariable(name: "len", scope: !60, file: !2, line: 62, type: !14)
!68 = !DILocation(line: 62, column: 10, scope: !60)
!69 = !DILocation(line: 62, column: 34, scope: !60)
!70 = !DILocation(line: 62, column: 27, scope: !60)
!71 = !DILocation(line: 62, column: 22, scope: !60)
!72 = !DILocation(line: 64, column: 59, scope: !60)
!73 = !DILocation(line: 64, column: 68, scope: !60)
!74 = !DILocation(line: 64, column: 38, scope: !60)
!75 = !DILocation(line: 64, column: 5, scope: !60)
!76 = !DILocation(line: 65, column: 59, scope: !60)
!77 = !DILocation(line: 65, column: 68, scope: !60)
!78 = !DILocation(line: 65, column: 38, scope: !60)
!79 = !DILocation(line: 65, column: 5, scope: !60)
!80 = !DILocation(line: 68, column: 59, scope: !60)
!81 = !DILocation(line: 68, column: 68, scope: !60)
!82 = !DILocation(line: 68, column: 38, scope: !60)
!83 = !DILocation(line: 68, column: 5, scope: !60)
!84 = !DILocation(line: 69, column: 5, scope: !60)
