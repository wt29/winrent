#BCC
VERSION=BCB.01
!ifndef CC_DIR
CC_DIR = $(MAKE_DIR)
!endif

!ifndef HB_DIR
HB_DIR = $(HARBOUR_DIR)
!endif
 
RECURSE= NO 
 
SHELL = 
COMPRESS = NO
EXTERNALLIB = NO
XFWH = NO
FILESTOADD =  5
WARNINGLEVEL =  0
USERDEFINE = 
USERINCLUDE = 
USERLIBS = 
EDITOR = notepad
GTWVW = 
CGI = NO
GUI = YES
MT = NO
SRC04 = obj 
PROJECT = winrent.exe $(PR) 

OBJFILES = $(SRC04)\winrent.obj $(SRC04)\collrep.obj $(SRC04)\conprt.obj $(SRC04)\enquire.obj $(SRC04)\errorsys.obj //
 $(SRC04)\itemrep.obj $(SRC04)\maincont.obj $(SRC04)\mainitem.obj $(SRC04)\mainowne.obj $(SRC04)\mainperi.obj //
 $(SRC04)\mainsite.obj $(SRC04)\maintran.obj $(SRC04)\maintruc.obj $(SRC04)\mediexpo.obj $(SRC04)\mediimpo.obj //
 $(SRC04)\miscrep.obj $(SRC04)\newtruck.obj $(SRC04)\printfunc.obj $(SRC04)\proclib.obj $(SRC04)\pulsarex.obj //
 $(SRC04)\setupdbf.obj $(SRC04)\tranrep.obj $(SRC04)\utilback.obj $(SRC04)\arglexpo.obj //
 $(SRC04)\utillabe.obj $(SRC04)\utilpack.obj $(SRC04)\utilsppa.obj $(SRC04)\utilstoc.obj $(OB)
 
PRGFILES = winrent.prg collrep.prg conprt.prg enquire.prg errorsys.prg //
 itemrep.prg maincont.prg mainitem.prg mainowne.prg mainperi.prg //
 mainsite.prg maintran.prg maintruc.prg mediexpo.prg mediimpo.prg //
 miscrep.prg newtruck.prg printfunc.prg proclib.prg pulsarex.prg //
 setupdbf.prg tranrep.prg utilback.prg arglexpo.prg //
 utillabe.prg utilpack.prg utilsppa.prg utilstoc.prg $(PS)
 
OBJCFILES = $(OBC) 
CFILES = $(CF)
RESFILES = winrent.res
RESDEPEN = winrent.res
TOPMODULE = winrent.prg
LIBFILES = lang.lib vm.lib rtl.lib rdd.lib macro.lib pp.lib dbfntx.lib dbfcdx.lib dbffpt.lib common.lib //
           gtwvw.lib codepage.lib ct.lib tip.lib pcrepos.lib hsx.lib hbsix.lib zlib.lib telepath.lib
#LIBFILES = lang.lib vm.lib rtl.lib rdd.lib macro.lib pp.lib dbfcdx.lib common.lib gtwvw.lib codepage.lib ct.lib tip.lib pcrepos.lib hsx.lib zlib.lib
EXTLIBFILES =
DEFFILE = 
HARBOURFLAGS = -w1
CFLAG1 = -OS $(SHELL)  $(CFLAGS) -d -c -L$(HB_DIR)\lib 
CFLAG2 = -I$(HB_DIR)\include;$(CC_DIR)\include
RFLAGS = 
LFLAGS = -L$(CC_DIR)\lib\obj;$(CC_DIR)\lib;$(HB_DIR)\lib -Gn -M -m -s -Tpe -x -aa
IFLAGS = 
LINKER = ilink32
 
ALLOBJ = c0w32.obj $(OBJFILES) $(OBJCFILES)
ALLRES = $(RESDEPEN)
ALLLIB = $(USERLIBS) $(LIBFILES) import32.lib cw32.lib
.autodepend
 
#DEPENDS
 
#COMMANDS
.cpp.obj:
$(CC_DIR)\BIN\bcc32 $(CFLAG1) $(CFLAG2) -o$* $**
 
.c.obj:
$(CC_DIR)\BIN\bcc32 -I$(HB_DIR)\include $(CFLAG1) $(CFLAG2) -o$* $**
 
.prg.obj:
$(HB_DIR)\bin\harbour -D__EXPORT__ -n -go -I$(HB_DIR)\include $(HARBOURFLAGS) -o$* $**
 
#.rc.res:
# $(CC_DIR)\BIN\brcc32 $(RFLAGS) $<
 
#BUILD
 
$(PROJECT): $(CFILES) $(OBJFILES) $(RESDEPEN) $(DEFFILE)
    $(CC_DIR)\BIN\$(LINKER) @&&!  
    $(LFLAGS) +
    $(ALLOBJ), +
    $(PROJECT),, +
    $(ALLLIB), +
    $(DEFFILE), +
    $(ALLRES) 
!
