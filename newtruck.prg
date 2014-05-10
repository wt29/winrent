Procedure NewTruck


local aFldDef:={}, x,nFieldNum


aadd( aFldDef, { "date", "d", 8, 0 } )
aadd( aFldDef, { "truck", "c", 10, 0 } )
aadd( aFldDef, { "drivers", "c", 20, 0 } )
aadd( aFldDef, { "name8393", "c", 12, 0 } )
aadd( aFldDef, { "sub8393", "c", 12, 0 } )
aadd( aFldDef, { "det8393", "c", 50, 0 } )
aadd( aFldDef, { "name0910", "c", 12, 0 } )
aadd( aFldDef, { "sub0910", "c", 12, 0 } )
aadd( aFldDef, { "det0910", "c", 50, 0 } )
aadd( aFldDef, { "name1012a", "c", 12, 0 } )
aadd( aFldDef, { "sub1012a", "c", 12, 0 } )
aadd( aFldDef, { "det1012a", "c", 50, 0 } )
aadd( aFldDef, { "name1012b", "c", 12, 0 } )
aadd( aFldDef, { "sub1012b", "c", 12, 0 } )
aadd( aFldDef, { "det1012b", "c", 50, 0 } )
aadd( aFldDef, { "name1101a", "c", 12, 0 } )
aadd( aFldDef, { "sub1101a", "c", 12, 0 } )
aadd( aFldDef, { "det1101a", "c", 50, 0 } )
aadd( aFldDef, { "name1101b", "c", 12, 0 } )
aadd( aFldDef, { "sub1101b", "c", 12, 0 } )
aadd( aFldDef, { "det1101b", "c", 50, 0 } )
aadd( aFldDef, { "name1202a", "c", 12, 0 } )
aadd( aFldDef, { "sub1202a", "c", 12, 0 } )
aadd( aFldDef, { "det1202a", "c", 50, 0 } )
aadd( aFldDef, { "name1202b", "c", 12, 0 } )
aadd( aFldDef, { "sub1202b", "c", 12, 0 } )
aadd( aFldDef, { "det1202b", "c", 50, 0 } )
aadd( aFldDef, { "name0103a", "c", 12, 0 } )
aadd( aFldDef, { "sub0103a", "c", 12, 0 } )
aadd( aFldDef, { "det0103a", "c", 50, 0 } )
aadd( aFldDef, { "name0103b", "c", 12, 0 } )
aadd( aFldDef, { "sub0103b", "c", 12, 0 } )
aadd( aFldDef, { "det0103b", "c", 50, 0 } )
aadd( aFldDef, { "name0204a", "c", 12, 0 } )
aadd( aFldDef, { "sub0204a", "c", 12, 0 } )
aadd( aFldDef, { "det0204a", "c", 50, 0 } )
aadd( aFldDef, { "name0204b", "c", 12, 0 } )
aadd( aFldDef, { "sub0204b", "c", 12, 0 } )
aadd( aFldDef, { "det0204b", "c", 50, 0 } )
aadd( aFldDef, { "name0304a", "c", 12, 0 } )
aadd( aFldDef, { "sub0304a", "c", 12, 0 } )
aadd( aFldDef, { "det0304a", "c", 50, 0 } )
aadd( aFldDef, { "name0304b", "c", 12, 0 } )
aadd( aFldDef, { "sub0304b", "c", 12, 0 } )
aadd( aFldDef, { "det0304b", "c", 50, 0 } )
aadd( aFldDef, { "name0443", "c", 12, 0 } )
aadd( aFldDef, { "sub0443", "c", 12, 0 } )
aadd( aFldDef, { "det0443", "c", 50, 0 } )
dbcreate( "newtruck", aFldDef )

select 2

use newtruck

select 1

use trukbook

while !eof()
 newtruck->( dbappend() )
 for x:= 1 to trukbook->( fcount() )
  nFieldNum := newtruck->( fieldpos( trukbook->( fieldname( x ) ) ) )
  if nFieldNum != 0
   newtruck->( fieldput( nFieldNum, trukbook->( fieldget( x ) ) ) )
  endif
   next
 trukbook->( dbskip() )
enddo

dbcloseall()

frename( 'trukbook.dbf', 'trukbook.ba1' )
frename( 'newtruck.dbf', 'trukbook.dbf' )

