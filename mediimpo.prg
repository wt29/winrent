#include "winrent.ch"

Procedure MediImpo

local aArray := {}, mbuff, mstr, mstr2
local getlist:={}, mfile := 'cust.txt                   '

if NetUse( "myobimpo", EXCLUSIVE )

 zap
 aArray := { { 'buffer', 'c', 254, 0 } }
 dbcreate( Oddvars( SYSPATH ) + 'tabimpo', aArray )

 if NetUse( 'tabimpo', EXCLUSIVE )

  Box_Save( 2, 08, 4, 72 )
  @ 3,10 say 'File to import' get mfile
  read

  mfile := trim( mfile )
  if !file( mfile )
   error( "Sorry, can't find " + mfile, 12 )

  else
   append from (mfile) delimited

   tabimpo->( dbgotop() )
   while !tabimpo->( eof() )
    mbuff := tabimpo->buffer
    mstr := substr( mbuff, 1, at( TAB, mbuff ) -1 )
    mbuff := strtran( mbuff, mstr + TAB )
    mstr2 := substr( mbuff, 1, at( TAB, mbuff ) -1 )
    myobimpo->( dbappend() )
    myobimpo->code := mstr
    myobimpo->name := mstr2
    tabimpo->( dbskip() )
   enddo
   error( 'Import completed - ' + Ns( myobimpo->( reccount() ) ) + ' imported ', 12 )
  endif
 endif

endif

dbcloseall()

return

