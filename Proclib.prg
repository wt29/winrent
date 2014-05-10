/*

 Procedure File - Proclib

 Rentals - Copyright Bluegum Software

       Last change:  TG   26 Jan 2012    7:07 pm
*/

#include "winrent.ch"
#include "error.ch"
#include "setcurs.ch"
#include "box.ch"
#include "set.ch"
#include "fileio.ch"

static mbvars := {}, mlVars := {}
static spfile := 'spool'
static spfile_no := 1
static l_printer := ''
static sc_row
static secmask := ''

procedure heading( cHeading )
local sOldColor := setcolor()

static cOldHeading

if pcount() = 0
 cHeading := cOldHeading

endif

Syscolor( C_INVERSE )
@ 0,0
@ 0,1 say date()
@ 0,40 - len( cHeading )/2 say cHeading
@ 0,61 say 'Sys Date ' + dtoc( Bvars( B_SYSDATE ) )

cOldHeading := cHeading
setcolor( sOldColor )
return

*

function NetUse ( p_file, ex_use, wait, p_alias, lnewarea, aindex ,mtag )
local forever, mcount := 1, ocur := setcursor( 0 ), pfile

default ex_use to SHARED
default wait to 10
default p_alias to NOALIAS
default lnewarea to NEW
default aindex to {}

forever := ( wait = 0 )
lnewarea := ( lnewarea != nil ) .and. lnewarea
pfile :=  p_file + if(  '.' $ p_file, '', '.dbf' )
if !file( pfile )
 if !file( Oddvars( SYSPATH ) + pfile )
  Error( 'File ' + p_file + ' not found in default drive or path', 12 )
  return FALSE

 endif

endif

while ( forever .or. wait > 0 )
 #ifndef SQL
 dbusearea( lnewarea, 'DBFCDX', p_file, p_alias, !ex_use )

 #else
 dbusearea( lnewarea, 'SQLRDD', p_file, p_alias, !ex_use )

 #endif

 if !neterr()
  if mtag != nil
   ordsetfocus( mtag )

  else
   ordsetfocus( 1 )

  endif
  setcursor( ocur )
  return TRUE
 endif
 inkey(1)
 --wait
 mcount++
 if int(mcount/5) = mcount/5
  Error( 'Waiting for file ' + p_file + ' to become Available', 12, 4 )
 endif
enddo
Error( 'File ' + p_file + ' unavailable', 12, 3 )
setcursor( ocur )
return FALSE

*

function fil_lock ( mwait )
local micount := 1, forever := (mwait = 0)

if flock()
 return TRUE
endif

while (forever .or. mwait > 0)
 inkey(.5)
 mwait -= .5
 micount++
 if int(micount/5) = micount/5
  Warning( 'Waiting for file to be unlocked by other users' )
 endif
 if flock()
  return TRUE
 endif
enddo

return FALSE

*

function rec_lock ( mfile, real_name, muser, mwait )
local mret := TRUE
default mfile to alias()
default real_name to mfile
default muser to ''
default mwait to -1
if select( real_name ) = 0
 real_name := mfile
endif
if !( ( mfile )->( eof() ) )
 while !( mfile )->( dbrlock() ) .and. mwait != 0
  Error( 'Waiting for record in ' + real_name + ' to be freed', 12, 5, ;
   if( !empty( muser ), 'Record locked by Workstation ' + trim( muser ), ;
       transform( ( mfile )->( fieldget(1) ), '@!' )+' '+procname( 1 )+' '+Ns( procline( 1 ) ) ) )
  inkey( 1 )
  mwait--
 enddo
 if mwait = 0
  mret := FALSE
 endif
endif
return mret

*

function add_rec ( mfile ) // Add the record or else !!
default mfile to alias()
(mfile)->( dbappend() )
while neterr()             // Error from last attempt
 Error('Attempting to append new record to ' + mfile , 12, 5 ) // Warn 'em
 (mfile)->( dbappend() )   // Attempt to add again
enddo                      // Test and loop ?
return TRUE                // OK so back we go

*

procedure warning ( p_text )
local level_err := savescreen(),p_len,col
??chr(7)
Syscolor(2)
p_len := len(p_text)
col := int((80-p_len)/2) - 2
Box_Save(7,col,9,col+3+p_len)
Center(8,p_text)
set cursor off
inkey(1.5)
set cursor on
Syscolor(1)
restore screen from level_err
return

*

Function Con_Find
local cf := Box_Save()
local got_it := FALSE
local t_flag:=FALSE
local mident
local getlist := {}
local enqobj
local mkey
local mContractNum := 0
local mbysuburb := FALSE
local mbyphone := FALSE
local mbyaddress := FALSE
local mByMobile := FALSE
local nCurWIndow1, nCurWindow2

// Heading('Contract Find')
nCurWindow1 := WVW_nOpenWindow("Contract Search", 4, 1, 6, 78 )

while TRUE
 mident := space( 10 )

// Box_Save( 4, 01, 6, 78, C_GREY )
 @ 5, 02 say 'Contract No,Surname,*Deposit Book,/Address,+Suburb,-Phone,?Mobile' get mident pict '@!'
 Syscolor( C_NORMAL )
 read

 if !updated()
  
  exit

 else

  mBySuburb := ( left( mident, 1 ) = '+' )
  mByPhone := ( left(mident, 1 ) = '-' )
  mByAddress := ( left( mident, 1 ) = '/' )
  mByMobile := ( left( mident, 1 ) = '?' )

  do case
  case left( mident, 1 ) = '*'
   mident := substr( mident, 2, len( trim( mident ) ) -1 )
   master->( ordsetfocus( 'deposit' ) )
   if !master->( dbseek( mident ) )
    Error( 'Deposit book No not on file', 12 )
    master->( ordsetfocus( 'contract' ) )
    loop
   else
    master->( ordsetfocus( 'contract' ) )
    mContractNum := master->con_no
   endif

  case mbyphone .or. mbysuburb .or. mbyaddress .or. mByMobile .or. ( asc( left( mident, 1 ) ) > 64 .and. asc( left( mident, 1 ) ) < 123 )

   t_flag := TRUE
   select hirer

   hirer->( ordsetfocus( if( mbysuburb, 'suburb', ;
                         if( mByPhone, 'phone', ;
                         if( mByMobile, 'mobile', ;
                         if( mByAddress, 'address', 'surname' ) ) ) ) ) )

   mident := upper( trim( mident ) )

   if mbysuburb .or. mbyphone .or. mbyaddress .or. mByMobile
    mident := substr( mident, 2, len( mident ) - 1 )

   endif

   if !hirer->( dbseek( mident ) )
    Error( 'No ' + if( mbysuburb, 'suburb', ;
                   if( mbyphone, 'phone', ;
                   if( mByMobile, 'mobile', ;
                   if( mbyaddress, 'address', 'surname' ) ) ) ) + ' match on file' , 12 )
    hirer->( ordsetfocus( 'contract' ) )
    loop

   endif

   hirer->( dbskip( 1 ) )
   if left( if( mbysuburb, upper( hirer->suburb ), ;
            if( mbyphone, upper( hirer->tele_priv ), ;
            if( mbyaddress, upper( hirer->add1 ), ;
            if( mbyMobile, upper( hirer->tele_mob ), ;
                upper( hirer->surname ) ) ) ) ), len( mident ) ) != mident

    hirer->( dbskip( -1 ) )
    mContractNum := hirer->con_no
    hirer->( ordsetfocus( 'contract' ) )

   else
    hirer->( dbskip( -1 ) )

//    Box_Save( 2, 02, 22, 78 )
    nCurWindow2 := WVW_nOpenWindow("Contract Search", 2, 2, 22, 78 )

//	Heading('Contract no find')
//    altd(1)
    enqobj:=tbrowse():new( 03, 03, 21, 77 )
    enqobj:colorspec := if( iscolor(), TB_COLOR, setcolor() )
    enqobj:HeadSep := HEADSEP
    enqobj:ColSep := COLSEP
    enqobj:goTopBlock := { || jumptotop( mident ) }
    enqobj:goBottomBlock := { || jumptobott( mident, 'hirer' ) }
#ifdef SQL
    bBlock := { || upper( left( hirer->surname, len( mident ) ) ) }
    enqobj:skipBlock := { |SkipCnt| AwSkipIt( SkipCnt, bBlock, mident ) }

#else
    enqobj:skipBlock := { | SkipCnt | AwSkipIt( SkipCnt, ;
    { || upper( left( if( mbysuburb, hirer->suburb, ;
                      if( mbyphone, hirer->tele_priv, ;
                      if( mbyaddress, hirer->add1, ;
                      if( mbyMobile, hirer->tele_mob, ;
                      hirer->surname ) ) ) ), len( mident ) )  ) }, mident ) }

#endif
    enqobj:addColumn(  tbcolumnnew('Contract', { || hirer->con_no } ) )
//    c:colorBlock := { || if( master->inquiry , { 5, 6 }, { 1, 2 } )  }
//    enqobj:addcolumn( c )
#ifdef RENTACENTRE
    enqobj:addcolumn( tbcolumnNew( 'D', { || if( ChkConDel(hirer->con_no), "*", " " ) } ) )
#else
    enqobj:addcolumn( tbcolumnNew( 'S', { || StatusLookup( hirer->con_no ) } ) )
#endif
    enqobj:addcolumn( tbcolumnNew( 'Surname', { || hirer->surname } ) )
    enqobj:addcolumn( tbcolumnNew( 'Address', { || hirer->add1 } ) )
    enqobj:addcolumn( tbcolumnNew( 'Suburb', { || hirer->suburb } ) )
    enqobj:addcolumn( tbcolumnNew( 'Phone', { || hirer->tele_priv } ) )
    enqobj:addcolumn( tbcolumnNew( 'First Name', { || hirer->first } ) )
    enqobj:addcolumn( tbcolumnNew( 'Mobile', { || hirer->tele_mob } ) )
    enqobj:freeze := 3
    mkey := 0
    while mkey != K_ESC

     enqobj:forcestable()
     mkey := inkey(0)

     if !Navigate( enqobj, mkey )

      if mkey = K_ENTER .or. mkey == K_LDBLCLK
       mContractNum :=  hirer->con_no
       hirer->( ordsetfocus( 'contract' ) )
       exit
      endif

     endif

    enddo

   endif
   
   wvw_lCloseWindow()
   
  otherwise
   mContractNum := val( mident )

  endcase

 endif

 select master

 if lastkey() != K_ESC
  if mContractNum = 0
   Error( 'You cannot use "0" as contract Number' , 12 )

  else
   master->( ordsetfocus( 'contract' ) )
   if !master->( dbseek( mContractNum ) )
    Error( 'Contract #' + Ns( mContractNum ) + ' not found', 12 )

   else

    if t_flag
     hirer->( ordsetfocus( 'contract' ) )
     hirer->( dbseek( mContractNum ) )
     select master
    endif

    Oddvars( LASTCONT, Ns( mContractNum ) )
    got_it := TRUE
    exit

   endif

 endif

 endif

enddo
Oddvars( CONTRACT, mContractNum )
// Box_Restore( cf )

wvw_lCloseWindow()
return got_it

*

function StatusLookup ( nConno )
local nHirerRec := Hirer->( recno() )
master->( dbseek( nConno ) )
hirer->( dbgoto( nHirerRec ) )
return master->status

*

function ChkConDel( mConNo )
local mRet
local nHirer := hirer->( recno() )
local nRecno := master->( recno() )
master->( dbseek( mConno ) )
mRet := if( master->inquiry, TRUE, FALSE )
master->( dbgoto( nRecno ) )
hirer->( dbgoto( nHirer ) )
return mRet

*

function perdesc ( pcode )
local mret := 'Unknown'
do case
case pcode = 'F'
 mret := 'Fortnightly'
case pcode = 'W'
 mret := 'Weekly'
case pcode = 'D'
 mret := 'Daily'
case pcode = 'M'
 mret:= 'Monthly'
endcase
return mret

*

function period ( pcurrent,pnumperiod,pcode )
local new_month, new_day, new_year, pminext
local totmths
do case
case pcode = 'F'
 pminext := pcurrent + ( 14 * pnumperiod )
case pcode = 'W'
 pminext := pcurrent + ( 7 * pnumperiod )
case pcode = 'D'
 pminext := pcurrent + pnumperiod
otherwise
 if empty( pcurrent )
  pcurrent := Bvars( B_SYSDATE )
 endif
 totmths := month( pcurrent ) + pnumperiod
 new_month := Ns( int( totmths % 12 ) )

 if new_month = '0'
  new_month := '12'

 endif

 if len( new_month ) = 1
  new_month := '0'+ new_month

 endif

 if ( new_month = '02' .and. day( pcurrent) > 28 ) .or.;
    ( ( new_month = '04' .or. new_month = '06' .or. new_month = '09' ;
    .or. new_month = '11' ) .and. day( pcurrent ) = 31 )
  totmths++
  new_month := val(new_month) + 1
  new_month := Ns( new_month )
  if len(new_month) = 1
   new_month := '0' + new_month
  endif
  new_day := '01'

 else
  new_day := Ns( day( pcurrent ) )
  if len(new_day) = 1
   new_day := "0" + new_day
  endif

 endif

 if totmths < 13
  new_year := substr(dtoc(pcurrent),7,2)

 else
  new_year := year(pcurrent) + int(totmths/12)
  new_year := substr(ltrim(str(new_year)),3,2)

 endif

 pminext = pcurrent + int(pnumperiod*30.35)
 pminext := ctod(new_day + '/' + new_month + '/' + new_year)

endcase
return pminext

*

function tran_type ( t_code,t_desc )
do case
case t_code = BOND_REFUND      // 'R'
 t_desc := 'Bond Refund'
case t_code = BOND_PAYMENT     // 'B'
 t_desc := 'Bond Payment'
case t_code = RENTAL_PAYMENT   // 'P'
 t_desc := 'Rental Payment'
case t_code = MISC_DEBIT       // 'D'
 t_desc := 'Misc. Debit'
case t_code = MISC_CREDIT      // 'C'
 t_desc := 'Misc. Credit'
case t_code = ARREARS_PAYMENT  // 'A'
 t_desc := 'Arrears Payment'
case t_code = ARREARS_DEBIT    // 'E'
 t_desc := 'Arrears Debit'
case t_code = MISC_PAYMENT     // 'N'
 t_desc := 'Misc Payment'
case t_code = RENTAL_INSTALL   // 'Z'
 t_desc := 'Rental Install.'
case t_code = LATE_PAYMENT_FEE // 'L'
 t_desc := 'Late Payment Fee'
case t_code = ITEM_ADDED       // 'I'
 t_desc := 'Item Added'
case t_code = CONTRACT_DELETED // 'X'
 t_desc := 'Contract Deleted'
case t_code = CONTRACT_ADDED   // 'Y'
 t_desc := 'Contract Added'
case t_code = DELIVERY_FEE     // 'V'
 t_desc := 'Delivery Fee'
case t_code = MACHINE_DELETED  // 'M'
 t_desc := 'Machine Deleted'
case t_code = MACHINE_MOVEMENT // 'T'
 t_desc := 'Machine Movement'
case t_code = ITEM_FILE_CHANGED // 'Q'
 t_desc := 'Item File Changed'
otherwise
 t_desc := 'Unknown (' + t_code + ')'
endcase
return t_desc

*

function st_status ( mstatus )
local mdesc
do case
case mstatus = 'O'
 mdesc := 'On-hand'
case mstatus = 'H'
 mdesc := 'Hirer -> ' + trim( hirer->surname ) + ' ' + Ns( hirer->con_no )
case mstatus = 'R'
 mdesc := 'On Repair'
case mstatus = 'D'
 mdesc := 'Disposed of'
case mstatus = 'T'
 mdesc := 'Theft'
case mstatus = 'S'
 mdesc := 'Sold'
case mstatus = 'C'
 mdesc := 'Clear Out'
otherwise
 mdesc := 'Unknown (' + mstatus + ')'
endcase
return mdesc

*

procedure center ( p_line, p_text )
p_text = trim( p_text )
@ p_line,40-(len(p_text)/2) say p_text
@ 0,0 say ''
return

*

function error ( ertext, errow, erwait, extrainfo )
local mscr, ercol, er_bott, er_right, ocursor:=setcursor(0), nKey
tone( 250, 5 )
ertext := trim( ertext )
ercol := min(24,int((79-( max( len( ertext ),if( extrainfo != nil, len( extrainfo ), 0 ) ) ) )/2)-2)
if errow = nil
 mscr := Box_Save( 24, 0, 24, 79 )
 syscolor( C_INVERSE )
 Line_clear( 24 )
 Center( 24, ertext + ' - Hit any key to continue - ' )

else
 er_right := ercol + max( 27, max( len( ertext ), if( extrainfo != nil, len( extrainfo ), 0 ) ) ) + 4
 er_bott := errow + if( erwait = nil, 2, 1 ) + if( empty( ertext ), 0, 1 ) +;
              if( extrainfo = nil, 0, 1 )
 mscr:=Box_Save( errow, ercol, er_bott, er_right, C_RED )
 Center( errow + 1, ertext )
 if extrainfo != nil
  Center( errow + 2, extrainfo )

 endif

 if erwait = nil
  Center( er_bott - 1, '- Hit any key to continue -' )

 endif

endif

if erwait != nil
 nKey := inkey( erwait, INKEY_KEYBOARD )

else
 nKey := inkey( 0, INKEY_KEYBOARD )

endif

if nkey = K_F12
  Print_Screen()

endif

Syscolor( 1 )
Box_Restore( mscr )
setcursor( ocursor )
return nil

*

function Box_Save ( t, l, b, r, c )
local scbuff1,scbuff2,scmask1,scmask2,oldcolor:=setcolor(), ssave
local colattr := 1

default t to 0, l to 0, b to maxrow(), r to maxcol()

ssave:=savescreen( t, l, min( b+1, 24 ), min( r+2, 79 ) )

if pcount() = 5
 syscolor(c)

endif

if t >= 1
 @ t,l clear to b,r
 @ t,l to b,r color 'B+/' + substr(setcolor(),at("/",setcolor())+1,2)

endif

if ( b < 24 .and. r < ( 79 - 2 ) .and. t >= 1 )
 scbuff1 := savescreen(b+1,l+2,min(24,b+1),min(79,r+2))
 scbuff2 := savescreen(t+1,r+1,min(24,b+1),min(79,r+2))
 scmask1 := replicate("X"+chr( colattr ),len(scbuff1)/2)
 scmask2 := replicate("X"+chr( colattr ),len(scbuff2)/2)
 restscreen(min(24,B+1),L+2,min(24,B+1),min(79,R+2),transform(scbuff1,scmask1))
 restscreen(min(24,t+1),min(79,R+1),min(24,B+1),min(79,R+2),transform(scbuff2,scmask2))

endif
return { t, l, min( 24, b+1 ), min( 79, r+2 ), ssave, oldcolor }

*

Function Box_Restore ( aArrayay )    // the array version of above
restscreen( aArrayay[ 1 ], aArrayay[ 2 ], aArrayay[ 3 ], aArrayay[ 4 ], aArrayay[ 5 ] )
setcolor( aArrayay[ 6 ] )

return nil

*

function line_clear ( line_no )
@ line_no, 0 say replicate( ' ', 80 )
@ line_no, 0 say ''

return ''

*

function syscolor ( p_colour )
local sOldColour := setcolor(), tcolor
// lcolor := iscolor() - Haven't seen a mono monitor for years

static sTColour := 1
sOldcolour := sTcolour

do case
case p_colour = C_NORMAL   // 1
 setcolor( 'gr+/' + C_BACKGROUND + ', w+/r, , , w/r' )

case p_colour = C_INVERSE  // 2
 setcolor( 'n/w, i' )

case p_colour = C_BRIGHT   // 3
 setcolor( 'w+/b, w+' )

case p_colour = C_MAUVE    // 4
 setcolor( 'w/rb, w+/r, , , w/r', 'w+' )

case p_colour = C_GREY     // 5
 setcolor( 'w+/w', 'w+' )

case p_colour = C_YELLOW   // 6
 setcolor( 'w/gr', 'w+' )

case p_colour = C_GREEN    // 7
 setcolor( 'w/g, w+' )

case p_colour = C_CYAN     // 8
 setcolor( 'w/bg+, w+/gr, , , bg+/bg', 'w+' )

case p_colour = C_BLUE     // 9
 setcolor( 'w/b, w+r' )

case p_colour = C_RED      // 10
 setcolor( 'gr+/r, w+r' )

endcase

tcolor := p_colour

return sOldColour

*

function kill ( file_name )
if file( file_name )
 if ferase( file_name ) = -1
  Error( "Error Erasing file " + file_name , 12 )
 endif
endif
return 0

*

function ns ( pnum, plen, pdec )
local mret := ''
do case
case pcount() = 1
 mret := ltrim( str( pnum ) )
case pcount() = 2
 mret := ltrim( str( pnum, plen ) )
case pcount() = 3
 mret := ltrim( str( pnum, plen, pdec ) )
endcase
return mret

*

function isready ( ptext )  // Universal "OK to Proceed" Function
default ptext to  'Ok to Proceed ?'
return ( if( messagebox( , ptext, "Input required", MB_YESNO ) = MB_RET_YES, TRUE, FALSE) )

*

procedure highlight ( r, c, t1, t2, p_pict )
local oc := setcolor()
@ r,c say t1
oc := setcolor( 'w+' + substr( oc, at( '/', oc), len( oc ) ) )
if pcount() = 5
 @ r, c + len( t1 ) + 1 say t2 pict ( p_pict )
else
 @ r, c + len( t1) + 1 say t2
endif
setcolor( oc )
return

*

procedure free_enq
local fr_scr := Box_Save()
local fr_dbf := select()
local enqobj, mkey
if NetUse( "items", SHARED, 10, 'itenq'  )
 itenq->( ordsetfocus( 'status' ) )
 if !itenq->( dbseek( 'O' ) )
  Error( 'No Stock Available for hire' , 12 )

 else
  Heading( 'Stock available for hire' )
  @ 1,1 clear to 24, 79
  enqobj:=tbrowsedb( 01,00, 24, 79 )
  enqobj:colorspec := if( iscolor(), TB_COLOR, setcolor() )
  enqobj:HeadSep := HEADSEP
  enqobj:ColSep := COLSEP
  enqobj:goTopBlock := { || jumptotop( 'O' ) }
  enqobj:goBottomBlock := { || jumptobott( 'O' ) }
  enqobj:skipBlock := { |SkipCnt| AwSkipIt( SkipCnt, { || itenq->status }, 'O' ) }
  enqobj:addcolumn( tbcolumnNew( 'Item Code', { || itenq->item_code } ) )
  enqobj:addcolumn( tbcolumnNew( 'Description', { || itenq->desc } ) )
  enqobj:addcolumn( tbcolumnNew( 'Model' , { || itenq->model } ) )
  enqobj:addcolumn( tbcolumnNew( 'Serial' , { || itenq->serial } ) )
  enqobj:addcolumn( tbcolumnNew( 'Monthly' , { || itenq->m_rent } ) )
  enqobj:addcolumn( tbcolumnNew( 'Last Rent' , { || itenq->last_rent } ) )
  enqobj:addcolumn( tbcolumnNew( 'Last Ret' , { || itenq->last_ret } ) )
  enqobj:freeze := 1
  mkey := 0
  while mkey != K_ESC
   enqobj:forcestable()
   mkey := inkey( 0 )

   if !Navigate( enqobj, mkey )

    if mkey == K_ENTER .or. mkey == K_LDBLCLK
     Itemsay( 'itenq' )  // Pass the item file alias to allow itemsay to work correctly

    endif

   endif

  enddo
 endif
 itenq->( dbclosearea() )

endif
select ( fr_dbf )
Box_Restore( fr_scr )
return

*

function Navigate( br, k )
local moved := TRUE
do case
case k == K_UP
 br:up()
case k == K_DOWN
 br:down()
case k == K_LEFT
 br:left()
case k == K_RIGHT
 br:right()
case k == K_PGUP
 br:pageUp()
case k == K_PGDN
 br:pageDown()
case k == K_CTRL_PGUP
 br:goTop()
case k == K_CTRL_PGDN
 br:goBottom()
 br:refreshcurrent()
case k == K_HOME
 br:home()
case k == K_END
 br:end()
case k == K_CTRL_HOME
 br:panHome()
case k == K_CTRL_END
 br:panEnd()
case k == K_CTRL_RIGHT
 br:panRight()
case k == K_CTRL_LEFT
 br:panLeft()
case k == K_F12
 Print_Screen()
case k == K_MWFORWARD
 br:up()
case k == K_MWBACKWARD
 br:down()
// case k == K_LDBLCLK
otherwise
 moved := FALSE
endcase
return moved

*

Function KeyskipBlock( xkey, mval, mdbf )
return ( { |nmove| Awskipit( nmove, mval, xkey, mdbf ) } )

*

Function Awskipit( nmove, mval, xkey, mdbf )
local nmoved
default mdbf to alias()
nmoved := 0
if nmove == 0 .or. ( mdbf )->( lastrec() ) == 0
 ( mdbf )->( dbskip( 0 ) )
elseif nmove > 0 .and. ( mdbf )->( recno() ) != ( mdbf )->( lastrec() ) + 1
 while nmoved <= nmove .and. !( mdbf )->( eof() ) .and. eval( mval ) = xkey
  ( mdbf )->( dbskip( 1 ) )
  nmoved++
 enddo
 ( mdbf )->( dbskip( -1 ) )
 nmoved--
elseif nmove < 0
 while nmoved >= nmove .and. !( mdbf )->( bof() ) .and. eval( mval ) = xkey
  ( mdbf )->( dbskip( -1 ) )
  nmoved--
 enddo
 if !( mdbf)->( bof() )
  ( mdbf )->( dbskip( 1 ) )
 endif
 nmoved++
endif
return ( nmoved )

*

function jumptotop( mkey, mdbf )
default mdbf to alias()
( mdbf )->( dbseek( mkey ) )
return nil

*

function jumptobott( lowval, mdbf )
local msseek :=set( _SET_SOFTSEEK, TRUE )
local mtype := valtype( lowval )
do case
case mtype = 'C'
 ( mdbf )->( dbseek( lowval + chr(254) ) )
 ( mdbf )->( dbskip( -1 ) )
case mtype = 'N'
 ( mdbf )->( dbseek( lowval + 1 ) )
 ( mdbf )->( dbskip( -1 ) )
case mtype = 'L'
 if lowval = FALSE
  ( mdbf )->( dbseek( TRUE ) )
  ( mdbf )->( dbskip( -1 ) )
 endif
endcase
set( _SET_SOFTSEEK, msseek )
return nil

*

procedure tran_disp ( mContractNum )
local tr_row := 3, mcount, ocolor := setcolor()
select tran
dbseek( mContractNum )
count while tran->con_no = mContractNum to mcount
if mcount > 17
 dbseek( mContractNum )
 mcount -= 17
 dbskip( mcount )
else
 dbseek( mContractNum )
endif

Box_Save( 1, 39, 21, 79, C_MAUVE )

Highlight(  01, 45, '', '[ Transactions on Cont # ' + Ns( mContractNum ) + ' ]' )

#ifdef INSURANCE
@ 02, 40 say '  Date       Amt.  Insure.  Type'
#else
@ 02, 40 say '  Date       Amt.     Type'
#endif

while mContractNum = tran->con_no .and. tr_row < 20 .and. !tran->( eof() )

 @ tr_row, 41 say dtoc( tran->date ) + ' ' + str( tran->value, 8, 2 )
#ifdef INSURANCE
 @ tr_row, 59 say str( tran->insurance, 6, 2 ) + ' ' + left( tran_type( tran->type ), 12 )
#else
 @ tr_row, 59 say left( tran_type( tran->type ), 17 )
#endif
 tr_row++
 tran->( dbskip() )

enddo
return

*

function zero( num1,num2 )
if num2 != 0
 return (num1/num2)
endif
return 0

*

function rule_78( o_cost,o_term,m_paid,m_pmt )
local gross_debt, curr_bal, charges, mth_to_run, rebate
gross_debt := o_term * m_pmt
curr_bal := gross_debt - (m_paid * m_pmt)
charges  := gross_debt - o_cost
mth_to_run := o_term - m_paid
rebate := zero((mth_to_run * (mth_to_run + 1)) , (o_term * (o_term + 1)))
rebate := rebate * charges
return curr_bal - rebate

*

function LookItUp ( workarea, value, fieldname )
local lastarea := select(), dup_rec
if select( workarea ) = 0
 if !NetUse( workarea, FALSE, 5 )
  return ''                // File not available pack up

 endif

endif
select ( workarea )                  // All cool use the file !!
ordsetfocus( "code" )
dup_rec := ( workarea )->( recno() )        // Hold record no
if !(workarea)->( dbseek( value ) )                 // Seek our test record
 value := if( pcount()=3,fieldget( fieldpos( fieldname ) ),'' )

else
 if pcount() = 2
  value := trim( ( workarea )->name )
 else
  value := fieldget( fieldpos( fieldname ) )
 endif

endif
goto dup_rec
select ( lastarea )
return trim( value )

*

procedure audit ( p_con, p_code, p_amt, p_comment )

default p_comment to ''

if NetUse( "audit" )

 Add_rec( 'audit' )
 audit->con_no := p_con
 audit->code := p_code
 audit->date := date()
 audit->time := time()
 audit->amt := p_amt
 audit->opercode := Oddvars( OPERCODE )
 audit->comments := p_comment
 if select("hirer") != 0
  audit->name := hirer->surname
 endif
 if select( "master" ) != 0
  audit->dep_no := master->dep_no
 endif
 if select( "items" ) != 0
  audit->machine := items->item_code
 endif
 audit->( dbclosearea() )

endif
return

*

#ifdef ASSETS

procedure fadepr (mdate, mcurr, mytd, maccum )
/*******************************************************************
*  Fadepr - Calculate depreciation for specified date.            *
*           Parameters are: mdate - specified date input          *
*                           mcurr - returns depr for current mth  *
*                           mytd  - returns YTD depr for year     *
*                           maccum - returns accum depr thru curr *
*           Also requires BFAFISCALYR from system memory file     *
*           Gets depreciation data from current FIXASSET record   *
*           4/04/89                                               *
*******************************************************************/

private mmonths,curr_mnth

* Number of months since in-service date
mmonths := month(mdate)-month(serv_date)+12*(year(mdate)-year(serv_date))+1

* Number of months YTD in current fiscal year
curr_mnth  :=  mod( month( mdate ) - month( bfafiscalyr ) + 11, 12 ) + 1

* Depreciation routine
mcost  :=  cost
msalvage  :=  salvage
mdepr_life  :=  depr_life

do case
case depr_mthd =  "S"
 Fasldepr( mcost,msalvage,mdepr_life,mmonths,curr_mnth,mcurr,mytd,maccum )

case depr_mthd = "D"
 Fadbdepr( mcost,msalvage,mdepr_life,1.5,mmonths,curr_mnth,mcurr,mytd,maccum )

otherwise
 maccum := 0
 mcurr := 0
 mytd := 0

endcase
return

proc fasldepr ( cost,salvage,life,mtot,mytd,monthdepr,ytddepr,accdepr )
*******************************************************************
*  Fasldepr -  returns straight line depreciation amount          *
*              for current month etc                              *
*              4/04/89                                            *
*******************************************************************
* PARAMETERS ARE:
*      cost    - cost of the asset
*      salvage - salvage value
*      life    - life in years
*      mtot    - total months from start
*      mytd    - number of months since start of fiscal year
*      monthdepr   - return current month depreciation
*      ytddepr     - return year to date depreciation
*      accumdepr   - return accumulated depreciation

local mdepr := (cost-salvage)/(12*life)
do case
case mtot<1
 monthdepr := 0
 ytddepr := 0
 accumdepr := 0

case mtot>12*life
 monthdepr := 0
 ytddepr := max(0,(mytd-(mtot-12*life)))*mdepr
 accdepr := cost-salvage

otherwise
 monthdepr := mdepr
 ytddepr := max(mytd,mtot)*mdepr
 accdepr := mtot*mdepr

endcase
return

proc fadbdepr ( cost, salvage, life, accel, mtot, mytd, monthdepr, ytddepr, accdepr )
**********************************************************************
* Fadbdepr -  returns declining-balance depr. amount for the current *
*             month, year-to-date, and accumulated depreciation      *
*             7/04/89                                                *
**********************************************************************

local mfirst,xm,balance,xm1

* Initialize Variables for depreciation loop
store 0 to monthdepr,ytddepr,accumdepr
balance := cost
rate := accel/(12*life)
xm := 0
xm1 := min( mtot, mod( mtot-mytd-1, 12 ) +1 )

* loop to calc. depr. by year until current date
while xm < mtot
 if balance>salvage.and.xm<12*life
  * Calculate declining balance depr for year
  monthdepr := balance*rate
  ytddepr := min(xm1*monthdepr,balance-salvage)
  accdepr := accdepr+ytddepr
  balance := balance-ytddepr

 else
  * After end of deprec.. Zero current depr. & terminate loop
  ytddepr := 0
  monthdepr := 0
  xm1 := mtot-xm

 endif
 *Setup for next pass through loop
 xm := xm+xm1
 xm1 := min( 12, min( mtot-xm, 12*life-xm ) )

enddo  ( depreciation loop )
return

#endif

*


function printgraph   // Prints the screen
local char:=0
local x
local pgraph := savescreen( 0, 0, 24, 79 )
local mlen := len( pgraph )
local pstr:=''
local oPrinter := Printcheck('Screen Print from ' + LVars( L_NODE ) , , TRUE) // Use the default font
oPrinter:Newline()
// oPrinter:SetFont( 'Lucida Console', 12, {3,-50} )
for x := 1 to mlen step 2
 pstr += substr( pgraph, x, 1 )
 char++
 if char = 80
  char := 0

  pStr := strTran( pstr, chr(196), "-" )
  pStr := strTran( pstr, chr(218), "*" )
  pStr := strTran( pstr, chr(191), "*" )
  pStr := strTran( pstr, chr(179), "|" )
  pStr := strTran( pstr, chr(217), "*" )
  pStr := strTran( pstr, chr(192), "*" )
  pStr := strTran( pstr, HEADSEP, "-" )
  pStr := strTran( pstr, COLSEP, "|" )

  oPrinter:TextOut( pstr )
  oPrinter:NewLine()

  pstr := ''

 endif

next
oPrinter:EndDoc()
oPrinter:Destroy()
return nil

*


function print_screen
Printgraph()
return nil

*

function pinwheel ( nointerupt )
local mret
static mchr := {'|','/','-','\'}, mcount := 0
mcount++
if mcount = 5
 mcount := 1
endif
@ 24, 79 say mchr[ mcount ]
if nointerupt = nil
 mret := ( inkey() != K_ESC )

else
 mret := TRUE

endif
return mret

*

Function MenuGen ( aArray, mrow, mcol, mdesc, mchoice, mcolor, mscr_rest, nSelRow )
local x, mwidth, mscr
default mchoice to 0
default mdesc to ''
default mscr_rest to FALSE
default mcolor to C_NORMAL
mwidth := len( mdesc )
for x := 1 to len( aArray )
 mwidth := max( mwidth, len( aArray[ x, 1 ] ) + 1 )

next
mscr := Box_Save( mrow, mcol, mrow+len( aArray )+1, mcol+mwidth+2, mcolor )
for x := 1 to len( aArray )
 @ mrow + x, mcol+1 prompt if(x!=1.and.!empty(mdesc),' ','') + padr( aArray[ x, 1 ], mwidth + if(x=1,1,0) ) message if( aArray[ x, 2] = nil, '', line_clear( 24 ) + aArray[ x, 2 ] )

next
Highlight( mrow, mcol, '', mdesc )
menu to mchoice
if mscr_rest
 Box_Restore( mscr )

endif
nSelRow := mrow + mchoice
return mchoice

*

function oddvars ( mindex, mval )
static aArrayay
default aArrayay to array( 30 )
if mval != nil
 aArrayay[ mindex ] := mval

endif
return aArrayay[ mindex ]

*

function bvarget ( mrefresh )
local x
default mrefresh to FALSE

if mrefresh
 mbvars := {}
endif

if len( mbvars ) = 0

 if NetUse( "bvars", FALSE )                    // All of our 'B_' Variables
  if bvars->( reccount() ) = 0
   Add_rec()
  endif
  for x := 1 to bvars->( fcount() )              // Loop for num fields
   aadd( mbvars, bvars->( fieldget( x ) ) )
  next                                           // And Again for more fields
  bvars->( dbclosearea() )
 endif

endif

return mbvars

*

function bvarsave
local x
if len( mbvars ) = 0
 Bvars()

endif
if NetUse( "bvars", EXCLUSIVE )                   // All of our 'B_' Variables
 for x := 1 to fcount()                            // Loop for num fields
  fieldput( x, mbvars[ x ] )

 next                                              // And Again for more fields
 bvars->( dbclosearea() )

endif
return nil

*

function bvars ( mindex, mval )
if mval != nil
 mbvars[ mindex ] := mval

endif
return mbvars[ mindex ]

*

function lvarget
local x, mnode
if len( mlvars ) = 0
 if NetUse( "nodes" )
  mnode := upper( if( !empty( netname() ), netname(), 'NONET' ) )  // Connected to Lan ?
  if trim( mnode ) = 'NONET' .and. gete( 'NETNAME' ) != ''
   mnode := gete( 'NETNAME' )

  endif 
  locate for nodes->node = mnode                                   // Locate record for logged in node

  if !found()                                  
   Add_rec( 'nodes' )
   nodes->node := mnode

  endif                            
  for x := 1 to fcount()                    // Loop for num fields 
   aadd( mlvars, fieldget(x) )

  next                                      // And Again for more fields
  nodes->( dbclosearea() )                  // Close Node list file

 endif

endif 
return mlvars

*

function lvarsave
local x, mnode

if len( mlvars ) = 0
 Lvars()
endif

if NetUse( "nodes", EXCLUSIVE )                         // All of our 'L_' Variables
 mnode:=upper(if(!empty(netname()),netname(),'NONET'))  // Connected to Lan ?
 locate for nodes->node = mnode                         // Locate record for logged in node
 if found()                                  
  for x := 1 to fcount()                                // Loop for num fields 
   fieldput( x, mlvars[ x ] ) 
  next                                                  // And Again for more fields
 else
  Error( 'Trouble locating Node Address in Nodes file - Notify Bluegum Software', 12 )
 endif
 nodes->( dbclosearea() )
endif
return nil

* 

function lvars ( mindex, mval )
if len( mlvars ) = 0
 mlvars = array( 100 )
endif
if mval != nil
 mlvars[ mindex ] := mval

endif
return mlvars[ mindex ] 

*

function Sysinc ( sysval, action, value, chkdbf )
local olddbf:=select(), retval:=0, mfieldpos, firstwarn:=FALSE, oldord
default value to 1
if NetUse( 'sysrec', SHARED, 0 )
 if sysrec->( reccount() ) = 0      // Strathdees?
  Add_rec( 'sysrec' )
  sysrec->( dbrunlock() )

 endif
 mfieldpos := fieldpos( sysval )
 Rec_lock()
 do case
 case action = 'I'    // Increment system value
  if fieldget( mfieldpos ) + value >= 1000000
   fieldput( mfieldpos, 1 )

  else
   fieldput( mfieldpos, fieldget( mfieldpos ) + value )

  endif
 case action = 'R'    // Replace System value
  fieldput( mfieldpos, value )

 case action = 'A'    // Add to system value
  fieldput( mfieldpos, fieldget( mfieldpos ) + value )

 endcase
 retval := fieldget( mfieldpos )
 if chkdbf != nil .and. action $ 'IR'
  oldord := ( chkdbf )->( ordsetfocus( 'contract' ) )
  while TRUE .and. Pinwheel( NOINTERUPT )
   if !( chkdbf )->( dbseek( retval ) )
    exit

   else
    if !firstwarn
     Error( 'System value detected on file already', 12, 2,'Looking for next free number' )
     firstwarn := TRUE
    endif
    if fieldget( mfieldpos ) + value >= 1000000
     fieldput( mfieldpos, 1 )

    else
     fieldput( mfieldpos, fieldget( mfieldpos ) + value )

    endif
    retval := fieldget( mfieldpos )
   endif
  enddo
  ( chkdbf )->( ordsetfocus( oldord ) )
 endif
 dbcommit()
 dbclosearea()
endif
select ( olddbf )
return ( retval )

*

Function Build_help ( aArray, wait )
local mwidth := 0, x, mscr, oldcur := setcursor( SC_NONE )
default wait to len( aArray )
for x := 1 to len( aArray )
 mwidth := max( mwidth, len( aArray[ x, 1 ] ) + len( aArray[ x, 2 ] ) )
next
mscr := Box_Save( 24-2-len( aArray ) , 79-4-mwidth, 24-1, 79-2, C_RED )
for x := 1 to len( aArray )
 @ 24-2-len( aArray )+x, 79-3-mwidth say aArray[ x, 1 ]
 @ 24-2-len( aArray )+x, 79-2-len( aArray[ x, 2 ] ) say aArray[ x, 2 ]
next
if inkey( wait ) = K_SPACE
 @ 24-2-len( aArray ), 79-3-mwidth say '< Help locked - Hit Space >'
 while inkey( 0 ) != K_SPACE
 enddo
endif
Box_Restore( mscr )
setcursor( oldcur )
return nil

*

procedure SysAudit( p_det )
local olddbf := select()
if !file( Oddvars( SYSPATH ) + "system.dbf" )
 dbcreate( Oddvars( SYSPATH ) + 'system', { { 'details', 'c', 50, 0 } } )
endif
if NetUse( "system" )
 Add_rec()
 system->details := p_det + dtoc( date() ) + time() + netname() + ' ' + Oddvars( OPERNAME )
 system->( dbclosearea() )
endif
select ( olddbf )
return

*

Func BrowSystem
local mscr, keypress:=0, mbrow, tscr, getlist:={}, mfilter
if NetUse( 'System' )
 mscr:=Box_Save( 2, 10, 21, 70 )
 mbrow:=TbrowseDb( 3, 11, 20, 69 )
 mbrow:headsep := HEADSEP
 mbrow:addcolumn( tbcolumnnew( 'Entry',{ || system->details } ) )
 while keypress != K_ESC .and. keypress != K_END
  mbrow:forcestable()
  keypress := inkey( 0 )
  if !Navigate( mbrow,keypress)
   if keypress == K_F3
    tscr := Box_Save( 3,0,5,40 )
    mfilter := space( 20 )
    @ 4, 1 say 'String to filter' get mfilter
    read
    if !updated()
     dbclearfilter()
    else
     mfilter := trim( mfilter )
     dbsetfilter( { || upper( system->details ) = upper( mfilter ) } )
     mbrow:refreshall()
    endif
    Box_Restore( tscr )
   endif
  endif
 enddo
 Box_Restore( mscr )
 system->( dbclosearea() )
endif
return nil

/*

 Function Highfirst - TG 05/02/96

 When passed a string containing spaces will Highlight the first letter of the
 next word.

 Receives - row + column to print the string, string to print.
 Calls - Syscolor() in Proclib to setup colours
 Returns - nil

*/

Function HighFirst ( mrow, mcol, mstr )
local mpos
while len( mstr ) > 0
 Syscolor( 3 )
 @ mrow, mcol say left( mstr, 1 )
 Syscolor( 1 )
 mpos := at( ' ', mstr )
 if mpos = 0
  mpos := len( mstr )
 endif
 @ mrow, mcol+1 say substr( mstr, 2, mpos - 1 )
 mrow := row()
 mcol := col()
 mstr := substr( mstr, mpos + 1, len( mstr ) - mpos + 1 )
enddo
return nil

*

function backspace ( mpos, mstr )
local x
default mstr to ''
default mpos to 40
for x := mpos to 1 step -1
 if substr( mstr, x, 1 ) = ' '
  return( x )
 endif
next
return( mpos )  // No spaces return string pos

/*

function Quality
local mprinter, mrow, mcol, ocons := set( _SET_CONSOLE, FALSE )
local mval := ''
mprinter := set( _SET_PRINTER, TRUE )
mrow := prow()
mcol := pcol()
if empty( mval )
 ?? QUALITY_PRINT
else
 ?? mval
endif
setprc( mrow, mcol )
set( _SET_CONSOLE, ocons )
set( _SET_PRINTER, mprinter )
return ''

*

function Draft
local mprinter, mrow, mcol, ocons := set( _SET_CONSOLE, FALSE )
local mval := ''
mprinter := set( _SET_PRINTER, TRUE )
mrow := prow()
mcol := pcol()
if empty( mval )
 ?? DRAFT_PRINT
else
 ?? mval
endif
setprc( mrow, mcol )
set( _SET_PRINTER, mprinter )
set( _SET_CONSOLE, ocons )
return ''

*/

function del_rec( sfile, lUnLock )
default sfile to alias()
Rec_lock( sfile )
( sfile )->( dbdelete() )
if lUnLock != nil
 ( sfile )->( dbrunlock() )

endif
return nil

*

function BrowHelp
local aArray := {}
aadd( aArray, { 'Up Arrow', 'Move Up one Line' } )
aadd( aArray, { 'Down Arrow', 'Move Down one Line' } )
aadd( aArray, { 'Right Arrow', 'Move Right one field' } )
aadd( aArray, { 'Left Arrow', 'Move left one field' } )
aadd( aArray, { 'Page Up', 'Move up one Page' } )
aadd( aArray, { 'Page Down', 'Move Down one Page' } )
aadd( aArray, { 'Ctrl Page Up', 'Move to top of Browse' } )
aadd( aArray, { 'Ctrl Page Down', 'Move to Bottom of Browse' } )
aadd( aArray, { 'Ctrl Home', 'Move to furthest left Column' } )
aadd( aArray, { 'Ctrl End', 'Move to furthest right Column' } )
aadd( aArray, { 'Ctrl Left Arrow', 'Pan the browse left' } )
aadd( aArray, { 'Ctrl Right Arrow', 'Pan the display right' } )
aadd( aArray, { 'Ctrl P', 'Print Screen to "Report" printer' } )
return aArray

*


#ifdef SECURITY
function SetupSec
local tscr, getlist:={}, x,mstr
local sa := array( len( operator->mask ) ) // security array
Heading( 'Set Security Profile' )
 for x := 1 to len( operator->mask )
  sa[ x ] := if( substr( operator->mask, x, 1 ) == SEC_CHAR, TRUE, FALSE )
 next
 tscr:=Box_Save( 02, 01, 21, 78, C_GREY )
 @ 02, 02 say ' Security Profile for ' + trim( operator->name )
 @ 03, 02 say '      Supervisor' get sa[ X_SUPERVISOR ] pict 'Y'
 @ 04, 02 say '    Enquiry Menu' get sa[ X_ENQUIRE ] pict 'Y'
 @ 05, 02 say '       File Menu' get sa[ X_FILE ] pict 'Y'
 @ 06, 02 say 'Transaction Menu' get sa[ X_TRANSACTION ] pict 'Y'
 @ 07, 02 say '    Reports Menu' get sa[ X_REPORT ] pict 'Y'
 @ 08, 02 say '        EOD Menu' get sa[ X_EOD ] pict 'Y'
 @ 09, 02 say '    Utility Menu' get sa[ X_UTILITY ] pict 'Y'

 @ 03, 40 say 'Add to Files' get sa[ X_ADDFILES ] pict 'Y'
 @ 04, 40 say '  Edit Files' get sa[ X_EDITFILES ] pict 'Y'
 @ 05, 40 say 'Delete Files' get sa[ X_DELFILES ] pict 'Y'

 read

 mstr := ''
 for x := 1 to len( operator->mask )
  mstr += if( sa[ x ] , SEC_CHAR, ' ' )
 next
 operator->mask := mstr
return tscr
#endif

*

function login ( allow_add )
local mret:=FALSE,mpass,ocode,mscr,getlist:={},x,mfound
local oc:=setcursor(1),okf10,okf9,olddbf:=select(),backdoor:=FALSE
default allow_add to FALSE
setkey( K_ALT_L, nil )  // Don't want to call twice
if NetUse( 'operator' )
 if operator->( lastrec() ) = 0 .or. operator->( dbseek( "XX" ) ) = FALSE  // Operator file is Empty - Create Default Supervisor
  Add_rec( 'operator' )
  operator->code := 'XX'
  operator->name := 'Supervisor'
  operator->mask := replicate( SEC_CHAR, 10 ) // Will give supervisor security
  operator->( dbrunlock() )
 endif
 for x:=1 to 3
  mscr := Box_Save( 14, 25, 17, 55 )
  ocode := '  '
  okf9 := setkey( K_ALT_F9, { || BackDoor( @backdoor ) } )
  okf10 := setkey( K_F10, { || if( !allow_add, nil, Dup_Chk( '^%&^', 'operator' ) ) } )
  @ 15,27 say 'Operator Code' get ocode pict '!!' ;
   valid( if( allow_add, dup_chk( ocode, 'operator' ), TRUE ) )
  read
  setkey( K_ALT_F9, okf9 )
  setkey( K_F10, okf10 )
  mfound := operator->( dbseek( ocode ) )
  if (mfound .and. !empty( operator->password ) ) .and. !backdoor // .or. !mfound
   @ 16, 27 say 'Enter Your Password'
   set console off
   accept to mpass
   set console on
   if mfound .and. ( upper( padr( mpass, 10 ) ) = HB_Decrypt( operator->password, CRYPTKEY ) )

    Oddvars( OPERCODE, operator->code )
    secmask := operator->mask
    x := 4
    mret := TRUE

   else
//  Audit("PWordVio" +trim( ocode ) +'|'+trim(mpass)+'|')
    if x = 3
     Error( 'Security Violation - Bye Bye' , 12 )
     close databases
     cls
     quit

    else
     Error('Invalid Login Attempt - try again',12)

    endif

   endif
  else
   if backdoor
    Oddvars( OPERCODE, '!!' )
    secmask := replicate( SEC_CHAR, 10 )

   else
    Oddvars( OPERCODE, operator->code )
    secmask := operator->mask

   endif
   Oddvars( OPERNAME, operator->name )
   x := 4
   mret := TRUE
  endif
  Box_Restore( mscr )
 next
 // restscreen( 14, 25, 18, 57, mscr )
 operator->( dbclosearea() )
endif
select ( olddbf )
setcursor( oc )
setkey(K_ALT_L,{||login( TRUE )})
return mret

*

function backdoor ( backdoor )
local mpass, getlist := {}
set console off
accept to mpass
set console on
backdoor := ( upper( mpass ) == '0AKUR4' )
keyboard chr( 13 )
return nil

*

#ifndef SECURITY
function secure
return TRUE
#else
function secure ( area )
default area to X_SUPERVISOR
if area = X_SUPERVISOR .or. substr( secmask, area, 1 ) = SEC_CHAR .or. ;
   substr( secmask, X_SUPERVISOR, 1 ) = SEC_CHAR
 return TRUE
else
 if area != X_EDITFILES .and. area != X_DELFILES .and. area != X_ADDFILES
  Error( 'No Security Rights for this Area' , 12 )
 else
  Error( 'No Security Rights for this Operation' , 12 )
 endif
endif
return FALSE
#endif


function dup_chk ( dup_no, workarea )
local sscr,key:=0,auto_close:=FALSE,lastarea:=select()
local dup_rec,dupbrow,validation:=FALSE,oc,mhlparr
local getlist:={},mcat,mscr,mwork:=upper(workarea),keybuff,waopen:=FALSE
#ifdef SECURITY
local x, page_number:=1, page_width, page_len, top_mar, bot_mar, col_head1, col_head2,report_name, oPrinter
local newpass, newpass2
#endif

if select( workarea ) = 0
 if !NetUse( workarea )
  select (lastarea)
  return FALSE                               // File not available pack up
 endif
else
 waopen := TRUE
endif
select (workarea)          // All cool use the file !!
dup_rec:=recno()           // Hold record no
seek dup_no                // Seek our test record
if !found()
 (workarea)->( dbseek( upper( substr( dup_no, 1, 1 ) ) , TRUE ) ) // Soft
 sscr := Box_Save( 1, 39, 22, 77, C_MAUVE )
 dupbrow:=tbrowsedb( 2, 40, 21, 76 )
 dupbrow:HeadSep := HEADSEP
 dupbrow:ColSep := COLSEP
 if mwork != 'DEBTOR'
  dupbrow:addcolumn( tbcolumnnew( "Code",{ || ( workarea )->code } ))
  dupbrow:addcolumn( tbcolumnnew( "Name",{ || left( ( workarea )->name, 20 ) } ))
  if mwork == 'MYOBCODE'
   dupbrow:addcolumn( tbcolumnnew( "GST Exempt",{ || ( workarea )->GSTExempt } ))
  endif
 #ifdef MEDI
  if mwork == 'PAYTYPE'
   dupbrow:addcolumn( tbcolumnnew( "MYOB Code",{ || ( workarea )->MYOBCode } ))
  endif
 #endif

 else
  dupbrow:addcolumn( tbcolumnnew( "Company",{ || ( workarea )->company } ))
  dupbrow:addcolumn( tbcolumnnew( "Address 1",{ || left( ( workarea )->add1, 20 ) } ))
  dupbrow:addcolumn( tbcolumnnew( "Address 2",{ || ( workarea )->add2 } ))

 endif

 go top

 keybuff:=''
 while TRUE
  dupbrow:forcestable()
  key := inkey(0)
  if !navigate( dupbrow, key )
   do case
   case key == K_F1
    mhlparr := {}
    aadd( mhlparr, { '<Esc/End>', 'Exit' } )
    aadd( mhlparr, { '<Enter>', 'Select Item' } )
    if mwork != 'SUPPLIER' .and. mwork != 'DEPT'
     aadd( mhlparr, { '<Del>', 'Delete Item' } )
    endif
    aadd( mhlparr, { '<F10>', 'Edit Details' } )
    aadd( mhlparr, { '<Ins>', 'Add New Item' } )
#ifdef SECURITY
    if mwork = 'OPERATOR'
     aadd( mhlparr, { '<F9>', 'Setup Profile' } )
     aadd( mhlparr, { '<F8>', 'Print Profile' } )
    endif
#endif
    Build_help( mhlparr )

   case key == K_ESC .or. key == K_END
    exit

   case key == K_ENTER .or. key == K_LDBLCLK
    if mwork != 'DEBTOR'
     keyboard chr( K_HOME )+chr( K_CTRL_Y )+trim( (mwork)->code )+chr( K_ENTER )

    else
     keyboard chr( K_HOME )+chr( K_CTRL_Y )+trim( (mwork)->debtno )+chr( K_ENTER )

    endif
    exit

   case key == K_DEL
    if Secure( X_DELFILES )
     if mwork == 'DEBTOR'
      Error( 'Cannot delete debtor from here... Use Pulsar', 12 )
     else
      if Isready( 'Ok to delete '+trim((mwork)->code)+' from file')
       select ( mwork )
       Del_rec( mwork, UNLOCK )
       eval( dupbrow:skipblock , -1 )
       dupbrow:refreshall()

      endif

     endif

    endif

   case key == K_F10
    if Secure( X_EDITFILES )
     if mwork == 'DEBTOR'
      Error( 'Cannot edit debtor from here... Use Pulsar', 12 )
     else
      oc:=setcolor()
      Rec_lock()
      mscr := Box_Save( 08, 01, 13, 72, C_GREY )
      Highlight( 09, 07, 'Code', (mwork)->code )
      @ 10, 03 say '    Name' get name pict '@s40' valid !empty( (mwork)->name )
      if mwork == 'MYOBCODE'
       @ 12, 03 say 'GST Exempt' get (mwork)->GSTExempt pict 'Y'

      endif
      if mwork == 'PAYTYPE'
       @ 12, 03 say 'MYOB Code' get (mwork)->MYOBCode pict '@!'

      endif
#ifdef SECURITY
      if mwork == 'OPERATOR'
       if substr( secmask, X_SUPERVISOR, 1 ) != SEC_CHAR
          Error( 'You do not have supervisor equivalance - you cannot setup users', 12 )
       else
          Box_Restore( SetupSec() )
       endif
      endif
#endif
      read
      dbrunlock()
      Box_Restore( mscr )
      Setcolor(oc)
      dupbrow:refreshcurrent()
     endif
    endif

   case key == K_INS
    if Secure( X_ADDFILES )
     if mwork == 'DEBTOR'
      Error( 'Cannot add debtor from here... Use Pulsar', 12 )

     else
      mcat := space( len( ( mwork )->code ) )
      mscr:=Box_Save( 06, 08, 09, 32+len( mcat ), C_GREEN )
      @ 7,10 say 'New ' + lower( mwork ) + ' Code' get mcat pict '@!' valid !empty( mcat )
      read
      Box_Restore( mscr )
      if updated()
       if dbseek( mcat )
        mscr:=Box_Save( 11, 08, 13, 72, C_GREY )
        Center( 12, 'Name ÍÍÍ¯ ' + (mwork)->name )
        Error( 'Code already on file',12 )
        Box_Restore( mscr )

       else
        Add_rec( mwork )
        ( mwork )->code := mcat
         mscr:=Box_Save( 08, 01, 15, 72, C_GREEN )
         Highlight( 09, 03, 'Code' , mcat )
         @ 11,03 say '    Name' get (mwork)->name pict '@S40'
         if mwork == 'MYOBCODE'
          @ 12, 03 say 'GST Exempt' get (mwork)->GSTExempt pict 'Y'
         endif
         if mwork == 'PAYTYPE'
          @ 12, 03 say 'MYOB Code' get (mwork)->MYOBCode pict '@!'
         endif
         read

#ifdef SECURITY
         if mwork == 'OPERATOR'
          if substr( secmask, X_SUPERVISOR, 1 ) != SEC_CHAR
           Error( 'You do not have supervisor equivalance You cannot setup users', 12 )
           operator->name := ''  // Force system to delete login
          else
           Box_Restore( SetupSec() )
          endif
         endif
#endif
         Box_Restore( mscr )
         if empty((mwork)->name) .or. empty((mwork)->code )
          Error( 'Code or Name Empty - record deleted' , 12 )
          Del_rec( mwork, UNLOCK )
         endif
         ( mwork )->( dbrunlock() )
        endif
       endif
      endif
     dupbrow:refreshall()
    endif

#ifdef SECURITY
   case key = K_F8
    if mwork = 'OPERATOR'
     if substr( secmask, X_SUPERVISOR, 1 ) != SEC_CHAR
      Error( 'You must be a supervisor to perform this!', 12 )
     else
      if Isready( 'Print Security Listing' )
       page_number:=1
       page_width:=132
       page_len:=66
       top_mar:=0
       bot_mar:=10
       col_head1 := '                      S E F T R P U A E D'
       col_head2 := '  Name                U N I R E E T F F F'
       report_name := 'Security Flags Listing'
       oPrinter := Printcheck( report_name )
       PageHead( oPrinter, report_name, page_width, page_number, col_head1, col_head2, FALSE )
       operator->( dbgotop() )
       while !operator->( eof() ) .and. Pinwheel()          // Start print Routine
        if PageEject( oPrinter, FALSE )                     // !toScreen
         page_number++
         PageHead( oPrinter, report_name, page_width, page_number, col_head1, col_head2, FALSE )   // !toScreen

        endif
        oPrinter:NewLine()
        oPrinter:TextOut( operator->name )
        for x := 1 to len( operator->mask )
//         LP( oprinter:setpos( 20 + ( x * 2 ) * oPrinter:CharWidth )
         LP( oprinter, if( substr( operator->mask, x, 1 ) = SEC_CHAR, 'X', ' ' ), 20 + (x*2), NONEWLINE )

        next
        operator->( dbskip() )

       enddo
       oPrinter:EndDoc()
       oPrinter:Destroy()

      endif

     endif

    endif

   case key = K_F9
    if mwork = 'OPERATOR'
     if substr( secmask, X_SUPERVISOR, 1 ) != SEC_CHAR .and.  Oddvars( OPERCODE ) != operator->code
      Error( "You cannot set Somebody else's Password!", 12 )

     else
      mscr := Box_Save( 3, 01, 5, 40 )
      @ 3, 2 say 'Setting Password for ' + trim( operator->name )
      set console off
      @ 4, 2 say 'Enter new password'
      accept to newpass
      @ 4, 2 say 'Retype new password'
      accept to newpass2
      set console on
      if newpass != newpass2
       Error( 'Passwords do not match - password not changed', 12 )

      else
       Rec_lock( 'operator' )
       operator->password := Hb_Crypt( upper( padr( newpass, 10 ) ), CRYPTKEY )
       operator->( dbrunlock() )

      endif
      Box_Restore( mscr )

     endif

    endif
#endif

   otherwise
    if key = K_BS .or. key > 32
     if key = K_BS
      keybuff:=substr(keybuff,1,max(len(keybuff)-1,0))
     else
      keybuff+=upper(chr(key))
     endif
     dbseek( keybuff, TRUE )
     if !empty( keybuff )
      @ 1, 42 say '< ' + keybuff + ' >-'
     else
      @ 1, 42 say replicate('Ä', 20 ) color if(iscolor(), 'B+/', 'W/' ) + substr(syscolor(),at("/",syscolor())+1,2)
     endif
     dupbrow:refreshall()
    endif
   endcase

  endif

 enddo
 Box_Restore( sscr )

else
 validation := TRUE

endif
goto dup_rec
select ( lastarea )
if !waopen
 ( workarea )->( dbclosearea() )
endif
return validation

*

function ShowCallStack()

local aStack := {}
local nCnt   := 0
local cStr   := ''
local lFirst := .t.

for nCnt := 2 to 15
 if empty(procname( nCnt))
  nCnt := 16
 else
  cStr := ' ' + pad( procname( nCnt), 15) + 'L ' + str( procline( nCnt), 5) + ' '
  aadd( aStack, { iif( lFirst, ' ', '')+cStr, 'Function:' + cStr})
  lFirst := .f.
 endif
next

MenuGen( aStack, 3, 10 , 'Call Stack', , , TRUE )

return nil

*

Function GSTCalc ( nAmt, nRate )
default nRate to Bvars( B_GSTRATE )
return ( ( nAmt ) / 100 ) * nRate

*

Function GSTPaid ( mAmt, nRate )
default nRate to Bvars( B_GSTRATE )
return mamt - ( ( mAmt / ( 100 + nRate ) ) * 100 )

*

Function GSTUpdate
local lUpdateMast := FALSE
local lUpdateItems := FALSE
local nUpdate := Bvars( B_GSTRATE )
local cScr := Box_Save( 3, 10, 9, 70 )
local getlist := {}
local nCursor
Center( 4, 'Be extremely careful here. This routine will increase prices' )
Center( 5, 'on all Contract Installments & Item Rental values.')
Center( 6, 'Backup the System First !!!' )
if IsReady( )
 if NetUse( 'master', EXCLUSIVE )
  if NetUse( 'items', EXCLUSIVE )
   nCursor := setcursor( SC_NORMAL )
   Box_Save( 3, 07, 9, 73 )
   @ 4, 12 say 'Update Items file' get lUpdateItems pict 'Y'
   @ 5, 12 say 'Update Contract file' get lUpdateMast pict 'Y'
   @ 6, 12 say 'Update Amount' get nUpdate pict '999.9999'
   read
   setcursor( nCursor )
   if updated()
    if IsReady( 'Are you absolutely sure' )
     if lUpdateItems
      select items
      items->( dbgotop() )
      while !items->( eof() )
       replace items->m_rent with items->m_rent + GstCalc( items->m_rent, nUpdate ),;
               items->f_rent with items->f_rent + GstCalc( items->f_rent, nUpdate ),;
               items->w_rent with items->w_rent + GstCalc( items->w_rent, nUpdate ),;
               items->d_rent with items->d_rent + GstCalc( items->d_rent, nUpdate )
#ifdef INSURANCE
       replace items->insurance with items->insurance + GstCalc( items->insurance, nUpdate )
#endif
       items->( dbskip() )
       enddo
      SysAudit( 'GSTIncItems' + Ns( nUpdate, 6, 2 ) )
     endif
     if lUpdateMast
      select master
      master->( dbgotop() )
      while !master->( eof() )
       replace master->install with master->install + GstCalc( master->install, nUpdate )
       master->( dbskip() )
      enddo
      SysAudit( 'GSTIncMast' + Ns( nUpdate, 6, 2 ) )
     endif
    endif
   endif
  endif
 endif
 dbCloseall()
endif
Box_Restore( cScr )
return nil

*

function get_search_str()
local getlist:={}, sString := space(14)
local oc := setcursor(1), cscr := Box_Save( 8, 53, 10, 76 )
@9,54 say 'String:' get sString picture "@!"
read
setcursor( oc )
Box_Restore( cscr )
return ( sString )

*

function search_calend( )
local oldcurs := setcursor(0), rDate, found:=FALSE
return (rDate)

*

function draw_cal( mDate )
local jj,tt,pday:=0
local start:=dow(ctod("01/"+str(Month(mDate),2)+"/"+substr(ns(year(mdate)),3,2))-1)
local last:=day(ctod("01/"+str(if(month(mDate)<12,month(mdate)+1,1),2)+"/"+substr(ns(year(mdate)),3,2))-1)
Box_Save(02,20,11,50)
@ 03,21 say padc(ns(day(mdate))+' '+cmonth(mdate)+' '+Ns(year(mdate)),28)
@ 4,21 say " Sun Mon Tue Wed Thu Fri Sat"
for jj:=1 to 6
 Devpos(4+jj,21)
 for tt:=1 to 7
  if ((tt<start+1) .and. jj=1) .or. pday >= last
   ?? space(4)
  else
   if pday+1 = day( mdate )
    syscolor( C_INVERSE )
   endif
   ?? str(++pday,4)
   syscolor( C_NORMAL )
  endif
 next
next
return NIL

*

Function abs_edit ( mfile, sAlias, lIsLocked, sFileKey )
local mscr
local msel := select()
local okalta := setkey( K_ALT_A, nil )
local okalts := setkey( K_ALT_S, nil )
local oktab := setkey( K_TAB, nil )
local okf10 := setkey( K_F10, nil )
local okf6 := setkey( K_F6, nil )
local okshf6 := setkey( K_SH_F6, nil )
local okcp := setkey( K_CTRL_P, nil )
local cFileName
default lIsLocked to FALSE

sAlias := lower( if( sAlias == nil, mfile, sAlias ) )

do case
case sAlias = 'master'
 cFileName = Oddvars( SYSPATH) + "mcomment\" + ns( master->con_no ) + ".txt"

case sAlias = 'items'
 cFileName = Oddvars( SYSPATH) + "icomment\" + trim( items->item_code ) + ".txt"

case sAlias = 'diary'
 cFileName = Oddvars( SYSPATH) + "dcomment\" + sFileKey + ".txt"

otherwise
 error( "Problem with comments 'alias' - Contact " + DEVELOPER, 12)
 return nil

endcase

if !lIsLocked
 rec_lock( sAlias )

endif 
mscr := Box_Save( 09, 04, 24, 76, C_RED )
@ 9, 10 say '< Hit Esc to abandon Changes - Ctrl-W to save Changes>'
MemoWrit( cFileName, MemoEdit( MemoRead( cFilename ), 10, 5, 23, 75 ) )

Box_Restore( mscr )

if !lIsLocked
 (sAlias)->( dbunlock() )

endif
 
setkey( K_SH_F6, okshf6 )
setkey( K_F6, okf6 )
setkey( K_F10, okf10 )
setkey( K_ALT_A, okalta )
setkey( K_ALT_S, okalts )
setkey( K_TAB, oktab )
setkey( K_CTRL_P, okcp )
select ( msel )

return nil

*

function calendar()
local back_scr := Box_Save(02,20,11,50)
local wdate := date(), nkey := 1,olddbf:=select()
local oldcurs := setcursor(SC_NORMAL)
local cscr,sStr
local getlist:={}, aHlp

Draw_cal( wdate )
while !empty(nKey)
 nKey := inkey(0)
 do case
 case nKey == K_F1
   aHlp := {}
   aadd( aHlp, { 'Esc', 'Escape from this Screen' } )
   aadd( aHlp, { 'Enter', 'Process Trucks' } )
   aadd( aHlp, { 'PgUp-PgDn', 'Up a year / Back a Year' } )
   aadd( aHlp, { 'DnArrow-UpArrow', 'Down a Month / Up a Month' } )
   aadd( aHlp, { 'Left-Right Arrow', 'Back a Day / Forward a Day' } )
   aadd( aHlp, { 'F10', 'Modify Diary Entry' } )
   Build_help( aHlp )

 case nKey == K_ENTER .or. nKey == K_LDBLCLK
  truck_proc( wdate )

 case nKey == K_F10
   Abs_edit( 'diary',,,strtran( dtoc( wdate ), "/" ) )

 case nKey == K_ESC
  nKey := 0
  loop

 case chr(nKey) $ 'Ss' // == 115 // 's'
  sStr := get_search_str()
  if !empty( sStr )
   wdate := search_calend( wdate, FALSE, sStr )
  endif

 case chr(nKey) $ 'Cc' // == 99 // 'c'
  if !empty( sStr )
   wdate := search_calend( wdate, TRUE, sStr )
  endif

 case nKey == K_END
  cscr := Box_Save( 05, 30, 07, 50 )
  @ 06,32 say 'Date' get wdate
  read
  Box_Restore( cscr )

 case nKey == K_PGUP
  wdate := wdate + 365
 case nkey == K_PGDN
  wdate := wdate - 365
 case nKey == K_DOWN
  wdate := wdate - 30
 case nKey == K_UP
  wdate := wdate + 30
 case nKey == K_HOME
  wdate := date()
 case nKey == K_RIGHT
  wdate++
 case nKey == K_LEFT
  wdate--
 endcase
 Draw_cal( wdate )
enddo
Box_Restore( back_scr )
setcursor( oldcurs )
select ( olddbf )
return NIL

*

Function MasterDupl
local sBox, nKey, oBrowse
If NetUse( 'master', EXCLUSIVE )
 master->( ordsetfocus( BY_NATURAL ) )
 SBox := Box_Save( 2, 02, 22, 78 )
 Heading('List of master file records')
 oBrowse:=tbrowsedb():new( 03, 03, 21, 77 )
 oBrowse:colorspec := if( iscolor(), TB_COLOR, setcolor() )
 oBrowse:HeadSep := HEADSEP
 oBrowse:ColSep := COLSEP
 oBrowse:addColumn( tbcolumnnew( 'Contract', { || master->con_no } ) )
 oBrowse:addcolumn( tbcolumnNew( 'Installment', { || master->install } ) )
 oBrowse:addcolumn( tbcolumnNew( 'Record No', { || master->( recno() ) } ) )
 nKey := 0
 master->( dbgotop() )

 while nKey != K_ESC

  oBrowse:forcestable()
  nkey := inkey(0)

  if !Navigate( oBrowse, nkey )

   if nkey = K_DEL
    if Isready( 'Ok to delete Contract No ' + ns( master->con_no ) )
     Del_Rec( 'master' )
     SysAudit( 'MasterRecDel:' + ns( Master->con_no )  )

    endif

   endif

  endif

 enddo

endif

dbcloseall()

return nil
