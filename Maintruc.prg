/*

 Rentals - Bluegum Software

 Module mainitem - Item maintenance
 
 Last change:  APG  26 May 2004    8:35 am

      Last change:  TG   16 Jan 2011    6:37 pm
*/

#include "winrent.ch"
#include "setcurs.ch"

Function Maintruck ( nStartrow )

local ok := FALSE, getlist:={}
local lLoop, nMenuChoice, cCode

local oldscr := Box_Save()
local aMenuOpt
local nRowSel
local dPurgeDate
local nRptChoice
local aFieldArr

default nStartRow to 5

if NetUse( "trukbook" )
 if NetUse( "truck" )
  ok := TRUE
 endif
endif

while ok

 Box_Restore( oldscr )
 Heading( 'Truck file maintenance' )

 aMenuOpt := {}
 aadd( aMenuOpt, { 'Exit', 'Return to main menu' } )
 aadd( aMenuOpt, { 'Add', 'Add new Truck' } )
 aadd( aMenuOpt, { 'Change', 'Change Truck details' } )
 aadd( aMenuOpt, { 'Delete', 'Delete old Truck details' } )
 aadd( aMenuOpt, { 'Purge', 'Delete old Booking records' } )
 aadd( aMenuOpt, { 'Report', 'Truck Reports' } )
 nMenuChoice := MenuGen( aMenuOpt, nStartRow, 13, 'Trucks', , , ,@nRowSel )

 if nMenuChoice < 2
  exit

 endif


  do case
  case nMenuChoice = 2 .and. Secure( X_ADDFILES )
   Heading( 'Add new truck' )
   cCode := space( 10 )
   @ nRowSel, 22 say 'ÍÍ¯Truck code to add' get cCode pict '@!'
   read
   if updated()
    if truck->( dbseek( cCode ) )
     Error( 'Truck Code already on file '+ truck->name, 12 )

    else
     Add_rec( 'truck' )
     truck->code := cCode
     Truckget()
     if !updated()
      truck->( dbdelete() )

     endif
     truck->( dbrunlock() )

    endif

   endif

  case nMenuChoice = 3 .and. Secure( X_EDITFILES )
   Heading( 'Change Truck Details' )
   cCode := space( 10 )
   @ nRowSel, 22 say 'ÍÍ¯Truck Code to edit' get cCode pict '@!'
   read
   if updated()
    if !truck->( dbseek( cCode ) )
     Error( 'Truck code not found', 12 )

    else
     Rec_lock( 'truck' )
     TruckGet()
     truck->( dbrunlock() )

    endif

   endif

  case nMenuChoice = 4 .and. Secure( X_DELFILES )

   Heading( 'Delete Truck' )
   cCode := space( 10 )
   @ nRowSel, 21 say 'ÍÍÍ¯Truck code to delete' get cCode pict '@!'
   read
   if updated()
    if !truck->( dbseek( cCode ) )
     Error( 'Truck code not on file', 12 )

    else
     Box_Save( 04, 08, 15, 72 )
     Highlight( 05, 10, '       Code', truck->code )
     Highlight( 07, 10, 'Description', truck->name )

     if Isready(12)
      Rec_lock( 'truck' )
      truck->( dbdelete() )
      truck->( dbrunlock() )

     endif
    endif
   endif

  case nMenuChoice = 5 .and. Secure( X_EDITFILES )
   Heading('Purge Truck Bookings')
   dPurgeDate := Bvars( B_SYSDATE ) - 60
   @ nRowSel, 22 say 'ÍÍ¯Date to delete to' get dPurgeDate
   read

   lLoop := FALSE

   if Isready( 'OK to purge truck record up to ' + dtoc( dPurgeDate ) )
    trukbook->( dbgotop() )
    while !trukbook->( eof() )
     if trukbook->date < dPurgeDate
      rec_lock( 'trukbook' )
      trukbook->( dbdelete() )
      trukbook->( dbunlock() )
     endif
     trukbook->( dbskip() )
    enddo
   endif

  case nMenuChoice = 6
   Heading( 'Truck Reports' )
   aMenuOpt := {}
   aadd( aMenuOpt, { 'Exit', 'Return to Trucks Menu' } )
   aadd( aMenuOpt, { 'Run', 'Print Truck Run' } )
   aadd( aMenuOpt, { 'List', 'Print List of Trucks' } )
   nRptChoice := MenuGen( aMenuOpt, nRowSel, 14, 'Report')
   do case
   case nRptChoice < 2
    lLoop := FALSE

   case nRptChoice = 2

   case nRptChoice = 3
    select truck

    aFieldArr := {}
    aadd( aFieldArr, { 'truck->code', 'Code', 10, 0, FALSE } )
    aadd( aFieldArr, { 'truck->name', 'Description', 9, 0, FALSE } )
    Reporter( aFieldArr, 'Truck List', '', '', '', '', FALSE, '', , 80 )

    dbcloseall()

   endcase

  endcase
enddo

dbcloseall()
return nil

*

procedure truckget
local getlist:={}
local mscr := Box_Save( 2, 10, 5, 70)
Heading( 'Truck Editing Screen' )
Highlight( 03, 12, 'Truck code', truck->code )
@ 04,12 say 'Description' get truck->name
read
Box_Restore( mscr )
return

*

Function Truck_proc ( dDate)

local oTrukbrow
local nKey
local cScr
local cScr1
local oCol
local nCol
local nCursor
local cSuburb, cName, cDetails
local aMenu, nChoice
local cTruck, aFld, nX, cDBName
local getlist:={}
local cScr2 := Box_Save()

if NetUse( 'Truck' )
 if NetUse( 'trukbook' )

  truck->( dbgotop() )
  while !truck->( eof() )
   select trukbook
   trukbook->( dbseek( dtos( dDate ) ) )
   locate for trukbook->truck = truck->code while trukbook->date = dDate
   if !found()
    add_rec( 'trukbook' )
    trukbook->date := dDate
    trukbook->truck := truck->code
    trukbook->( dbunlock() )

   endif
   truck->( dbskip () )

  enddo

// Reposition the trukbook file
  select trukbook
  set relation to trukbook->truck into truck

  trukbook->( dbseek( dtos( dDate ) ) )

  Heading('Truck Booking menu')
  aMenu := {}
  aadd( aMenu, { 'Exit', 'Return to Calendar' } )
  aadd( aMenu, { 'Summary', 'Truck Summary' } )
  aadd( aMenu, { 'Truck', 'Individual Truck' } )
  nChoice := MenuGen( aMenu, 01, 01, 'Trucks' )

  do case
  case nChoice = 2
   cScr1 := Box_Save()
   cls
   Heading( 'Truck Bookings' )
   oTrukBrow:=tbrowsedb( 03, 03, 24-2, 77 )
   oTrukBrow:colorspec := TB_COLOR // if( iscolor(), TB_COLOR, setcolor() )
   oTrukBrow:HeadSep := HEADSEP
   oTrukBrow:ColSep := COLSEP
   oTrukBrow:goTopBlock := { || jumptotop( dtos( dDate ) ) }
   oTrukBrow:goBottomBlock := { || jumptobott( dtos( dDate ), 'trukbook' ) }
   oTrukBrow:skipBlock := Keyskipblock( dDate, { || trukbook->date }, 'trukbook' )
   oTrukBrow:addcolumn( tbcolumnNew( 'Truck', fieldWblock( 'truck', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '8-9', fieldWblock( 'sub0809', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '9-10', fieldWblock( 'sub0910', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '10-11 A', fieldWblock( 'sub0911a', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '10-11 B', fieldWblock( 'sub0911b', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '10-12 A', fieldWblock( 'sub1012a', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '10-12 B', fieldWblock( 'sub1012b', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '11-01 A', fieldWblock( 'sub1101a', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '11-01 B', fieldWblock( 'sub1101b', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '12-02 A', fieldWblock( 'sub1202a', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '12-02 B', fieldWblock( 'sub1202b', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '01-03 A', fieldWblock( 'sub0103a', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '01-03 B', fieldWblock( 'sub0103b', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '02-04 A', fieldWblock( 'sub0204a', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '02-04 B', fieldWblock( 'sub0204b', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '4-430PM', fieldWblock( 'sub04', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '04-530A', fieldWblock( 'sub4353a', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '04-530B', fieldWblock( 'sub4353b', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '05-630A', fieldWblock( 'sub0563a', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '05-630B', fieldWblock( 'sub0563b', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '6-8  A ', fieldWblock( 'sub0608a', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '6-8  B ', fieldWblock( 'sub0608b', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '6-8  C ', fieldWblock( 'sub0608c', select( 'trukbook' ) ) ) )
   oTrukBrow:addcolumn( tbcolumnNew( '8-9  PM', fieldWblock( 'sub089P', select( 'trukbook' ) ) ) )
   oTrukBrow:freeze := 1
   oTrukBrow:colpos := 2
   nkey := 0
   while nkey != K_ESC
    oTrukbrow:refreshall():forcestable()
    nkey := inkey(0)
    if Navigate( oTrukbrow, nkey )
     if ( oTrukBrow:colPos <= oTrukBrow:freeze )
      oTrukBrow:colPos := ( oTrukBrow:freeze + 1 )
      endif
     else
     if nkey = K_ENTER .or. nkey == K_LDBLCLK
      rec_lock( 'trukbook' )
      nCol := oTrukBrow:colPos // What column are we in?
      cScr := Box_Save( 3, 10 , 9, 70 )
      ncol := (ncol * 3) - 1
      cSuburb := fieldget( nCol  )
      cName := fieldget( nCol - 1 )
      cDetails := fieldget( nCol + 1 )
      nCursor := setcursor( SC_NORMAL )
      Highlight( 4, 12, '      Truck ', trim( truck->name ) )
      Highlight( 5, 12, 'Pickup Time ', substr( trukbook->( fieldname( nCol ) ), 5, 6 ) )
      @ 6, 12 say ' Suburb' get cSuburb
      @ 7, 12 say '   Name' get cName
      @ 8, 12 say 'Details' get cDetails
      read
      setcursor( nCursor )
      if updated()
       select trukbook
       fieldput( ncol, cSuburb )
       fieldput( ncol-1, cName )
       fieldput( ncol+1, cDetails )
      endif
      trukbook->( dbrunlock() )
     endif
    endif
   enddo
   Box_Restore( cScr1 )

  case nChoice = 3
   cTruck := space( 10 )
   cScr1 := Box_Save( 3, 10, 5, 60 )
   @ 4, 12 say 'Truck' get cTruck pict '@!' valid ( Dup_chk( cTruck, 'truck' ) )
   read
   Box_Restore( cScr1 )
   if updated()
    cDbName := Oddvars( TEMPFILE )
    aFld := {}
    aadd( aFld, { 'timeslice', 'c', 10, 0 } )
    aadd( aFld, { 'name', 'c', 12, 0 } )
    aadd( aFld, { 'suburb', 'c', 12, 0 } )
    aadd( aFld, { 'Details', 'c', 50, 0 } )
    dbcreate( Oddvars( SYSPATH ) + cDbName , aFld )
    if NetUse( cDbName )
     select trukbook
     trukbook->( dbseek( dtos( dDate ) ) )
     locate for trukbook->truck = cTruck while trukbook->date = dDate

     if !found()
      Error( 'No record found for truck ' + trim( cTruck ) + ' on ' + dtoc( dDate ), 12 )

     else
      for nX := 4 to trukbook->( fcount() ) step 3
       Add_rec( cDBName )
       ( cDBName )->( fieldput( 1, substr( trukbook->( fieldname( nX ) ), 5, 6 ) ) )
       ( cDBName )->( fieldput( 2, trukbook->( fieldget( nX ) ) ) )
       ( cDBName )->( fieldput( 3, trukbook->( fieldget( nX + 1 ) ) ) )
       ( cDBName )->( fieldput( 4, trukbook->( fieldget( nX + 2 ) ) ) )
       ( cDbname )->( dbrunlock() )

      next

      ( cDBName )->( dbgotop() )
      cScr1 := Box_Save()
      cls
      Heading( 'Truck Bookings' )
      select ( cDBName )
      Highlight( 2, 3, 'Truck ', cTruck )
      Highlight( 3, 3, ' Date ', dtoc( dDate ) )
      oTrukBrow:=tbrowsedb( 05, 00, 24-2, 79 )
      oTrukBrow:colorspec := TB_COLOR
      oTrukBrow:HeadSep := HEADSEP
      oTrukBrow:ColSep := COLSEP
      oCol := tbcolumnNew( 'Time', fieldWblock( 'timeslice', select( cDBName ) ) )
      oCol:width := 6
      oTrukBrow:addcolumn( oCol )
      oCol := tbcolumnNew( 'Name', fieldWblock( 'Name', select( cDBName ) ) )
      oCol:width := 15
      oTrukBrow:addcolumn( oCol )
      oCol := tbcolumnNew( 'Suburb', fieldWblock( 'Suburb', select( cDBName ) ) )
      oCol:width := 15
      oTrukBrow:addcolumn( oCol )
      ocol := tbcolumnNew( 'Details', fieldWblock( 'Details', select( cDBName ) ) )
      ocol:width := 40
      oTrukBrow:addcolumn( ocol )
      nkey := 0
      while nkey != K_ESC
       oTrukbrow:forcestable()
       nkey := inkey(0)
       if !Navigate( oTrukbrow, nkey )

        if nkey = K_ENTER .or. nkey == K_LDBLCLK
         rec_lock( 'trukbook' )
         nCol := oTrukBrow:colPos // What column are we in?
         cScr := Box_Save( 3, 10 , 09, 70 )
         Rec_lock( cDBName )
         nCursor := setcursor( SC_NORMAL )
         Highlight( 4, 12, '      Truck ', trim( truck->name ) )
         Highlight( 5, 12, 'Pickup Time ', (cDbname)->timeslice )
         @ 6, 12 say '   Name' get (cDBName)->name
         @ 7, 12 say ' Suburb' get (cDBName)->suburb
         @ 8, 12 say 'Details' get (cDBName)->details
         read
         ( cDBName )->( dbRunlock() )
         Box_Restore( cScr )
         setcursor( nCursor )

         if updated()
          select trukbook
          trukbook->( dbseek( dtos( dDate ) ) )
          locate for trukbook->truck = cTruck while trukbook->date = dDate

          if !found()
           Error( 'Problem locating Truck booking Record for truck ' + trim( cTruck ), 12 )

          else
           Rec_lock( 'trukbook' )
           nCol := fieldpos( 'Name' + trim( (cDBName)->timeslice ) )
           fieldput( ncol, (cDBName)->name )
           fieldput( ncol+1, (cDBName)->suburb )
           fieldput( ncol+2, (cDBName)->details )
           trukbook->( dbrunlock() )

          endif
          select (cDBName)
          otrukbrow:refreshall()

         endif
        endif
       endif

      enddo
      Box_Restore( cScr1 )

     endif
     ( cDBName )->( dbclosearea() )

    endif

   endif

  endcase
  trukbook->( dbclosearea() )

 endif
 truck->( dbclosearea() )

endif
Box_Restore( cScr2 )
return nil
