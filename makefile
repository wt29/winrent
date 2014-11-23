VERSION=BCB.01
CC_DIR = C:\Program Files\Microsoft Visual Studio 9.0\VC
HB_DIR = c:\develop\xharbour\1.20
#HB_DIR = c:\hb30
 
RECURSE= NO 
 
COMPRESS = NO
EXTERNALLIB = NO
XFWH = NO
FILESTOADD =  5
WARNINGLEVEL =  0
USERDEFINE = 
USERINCLUDE = 
USERLIBS = 
EDITOR = edit
GTWVW = YES
GUI = NO
MT = NO
SRC09 = 
CF = CFiles
PROJECT = winrent.exe $(PR)

OBJFILES = winrent.obj Collrep.obj Conprt.obj Enquire.obj Itemrep.obj Maincont.obj \
 Mainitem.obj Mainowne.obj Mainperi.obj Mainsite.obj Maintran.obj Maintruc.obj \
 Miscrep.obj newtruck.obj Proclib.obj pulsarex.obj Setupdbf.obj tranrep.obj \
 Utilback.obj Utillabe.obj Utilpack.obj Utilsppa.obj Utilstoc.obj printfunc.obj errorsys.obj arglexpo.obj

PRGFILES = winrent.prg Collrep.prg Conprt.prg Enquire.prg Itemrep.prg Maincont.prg \
 Mainitem.prg Mainowne.prg Mainperi.prg Mainsite.prg Maintran.prg Maintruc.prg \
 Miscrep.prg newtruck.prg Proclib.prg pulsarex.prg Setupdbf.prg tranrep.prg \
 Utilback.prg Utillabe.prg Utilpack.prg Utilsppa.prg Utilstoc.prg printfunc.prg errorsys.prg arglexpo.prg

CFILES = winrent.c Collrep.c Conprt.c Enquire.c Itemrep.c Maincont.c \
 Mainitem.c Mainowne.c Mainperi.c Mainsite.c Maintran.c Maintruc.c \
 Miscrep.c newtruck.c Proclib.c pulsarex.c Setupdbf.c tranrep.c \
 Utilback.c Utillabe.c Utilpack.c Utilsppa.c Utilstoc.c printfunc.c errorsys.c arglexpo.c

TOPMODULE = WINRENT.PRG

RESFILES = WINRENT.RES
RESDEPEN = 

GTLIB = gtwvw.lib

HBLIBS = lang.lib vm.lib rtl.lib rdd.lib macro.lib pp.lib dbfntx.lib dbfcdx.lib dbffpt.lib \
         pcrepos.lib ct.lib common.lib codepage.lib hbsix.lib hbzip.lib tip.lib zlib.lib debug.lib $(GTLIB)

CLIBS = user32.lib winspool.lib gdi32.lib ole32.lib oleaut32.lib ws2_32.lib comctl32.lib advapi32.lib

#winspool.lib odbc32.lib odbccp32.lib  advapi32.lib vfw32.lib mpr.lib winmm.lib uuid.lib uuid.lib shell32.lib  kernel32.lib   
#comdlg32.lib  	
EXTLIBFILES =
DEFFILE = 
HARBOURFLAGS = /w2 /b /n /gc

#CFLAGS = /c /MT /W3
CFLAGS = /c /W3 /MT

RFLAGS =
LFLAGS= /NODEFAULTLIB:LIBC /NODEFAULTLIB:LIBCP
#LFLAGS = /Nodefaultlib:LIBCMT
#LFLAGS = $(LFLAGS) /MERGE:.CRT=.data

IFLAGS = 

LINKER = link
.SUFFIXES: .c .obj .prg 

ALLOBJ = $(OBJFILES) $(OBJCFILES)
ALLRES = $(RESDEPEN) $(RESFILES)
ALLLIB = $(HBLIBS) $(CLIBS)

#DEPENDS
 
#COMMANDS
#{}.c{$(SRC09)}.obj:
#.c{$(SRC09)}.obj:

.c.obj:
 cl -I$(HB)\include $(CFLAGS) -Fo$* $**

.prg.c:
 $(HB)\bin\harbour /D__EXPORT__ /I$(HB)\include $(HARBOURFLAGS) $** -O$*
 
.rc.res:
 $(CC_DIR)\rc $(RFLAGS) $<
 
#BUILD
#$(CFILES) $(RESDEPEN) $(DEFFILE)
winrent.exe: $(PRGFILES) $(CFILES) $(OBJFILES)
		link $(OBJFILES) $(HB)\obj\vc\mainwin.obj $(ALLLIB) $(ALLRES) /out:winrent.exe $(LFLAGS)

#        link $(OBJFILES) $(ALLLIB) /out:winrent.exe /map:winrent.map $(LFLAGS)
