@echo off
set CC=C:\borland\bcc55
set HB=C:\develop\xharbour\1.2.3


set oldpath=%path%
path=%path%;%cc%\bin;%hb%\bin;%hb%\bin\win\bcc
set include=%cc%\include;%HB%\include;%HB%\obj\b32
set lib=%cc%\lib;%HB%\lib\win\bcc


set HB_ARCHITECTURE=win
set HB_COMPILER=bcc
set HB_GT_LIB=gtwvw

copy makefile.bcc makefile
hbmake makefile 
rem hbmk2 -owinrent *.prg gtwvw.hbc hbtip.hbc xhb.hbc hbct.hbc
rem hbmk2 -owinrent *.prg gtwvw.hbc 
rem hbmk2 

set path=%oldpath%



