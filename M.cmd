@echo off

set HB_ARCHITECTURE=W32
set HB_COMPILER=MSVC
set HB_GT_LIB=gtwvw

rem for Multi thread support, un-remark next line
rem set HB_MT=MT

rem nmake
call m_bcc.cmd
if not exist winrent.exe goto noexe
goto end
:noexe 
echo No executable generated
:end


