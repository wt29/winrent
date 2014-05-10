/** @package 

        Utilstoc.prg
        
        Copyright(c) DEPT OF FOREIGN AFFAIRS TRADE 2000
        
        Author: DEPT OF FOREIGN AFFAIRS TRADE
        Created: DOF 12/04/2009 4:39:20 PM
      Last change:  TG   18 Oct 2010   10:53 pm
*/
* Asset_scan - Bluegum Software
* Module Asstk - Stocktake Module
* 28/10/86 T. Glynn 11:03:03  9/23/1987
**************************************

#include "winrent.ch"

Procedure UtilStoc

local level1 := Box_Save()
local choice
local mtot
local mstr
local adbf
local mspace
local mscan
local printchoice
local getlist := {}
local aFlds

if !NetUse( 'items' )
 return
endif

*

while TRUE
 Box_Restore( level1 )
 Heading('Rentals Stocktake System')
 Choice = 1
 Box_Save(01,33,06,45)
 @ 02,34 prompt 'Exit     ' message Line_clear(24)+'Return to Main Menu'
 @ 03,34 prompt ' Prepare ' message Line_clear(24)+'Prepare the asset file for Stocktaking'
 @ 04,34 prompt ' Download' message Line_clear(24)+'Load Data from Portable Barcode Reader'
 @ 05,34 prompt ' Reports ' message Line_clear(24)+'Shrinkage etc reports'
 @ 01,34 say 'Stocktake'
 menu to choice
 do case
 case choice = 2
  Box_Save(03,08,09,72)
  Center(04,'This module will prepare the asset file for the stocktake.')
  Center(05,'It clears the stocktake found flag and last stocktake location.')
  Center(07,'It is a mandatory step in the stocktaking process.')
  Heading('Stocktake Preparation')
  if Isready()
   Box_Save(09,19,11,58)
   select items
   @ 10,20 say 'Processing in progress - Please wait'
   go top
   while !items->( eof() )
    Rec_lock()
    items->stocktake := FALSE
    items->( dbrunlock() )
    items->( dbskip() )
   enddo
  endif

 case choice = 3
  Heading('Stocktake Entry')
  if Isready()
   mtot = 1
   Box_Save( 02, 08, 12, 72 )
   @ 03,10 say 'Ready to Append Data from Portable'
   @ 04,10 say 'Hit "Function" followed by "11"'
   @ 06,10 say 'Esc to halt downloading'
   @ 07,10 say 'Portable is Cleared by Hitting "Function" and "19"'
   set alternate to bcr
   set alternate on
   mstr = ""
   while upper(mstr) != "EOF"
    mstr := space(20)
    @ 05,10 say 'Data' get mstr
    read
    if lastkey() = K_ESC
     exit
    endif
    set console off
    ? mstr
    set console on
   enddo
   set alternate to
   if lastkey() != K_ESC

    adbf := {}
    aadd( adbf, { 'scan', 'c', 20, 0 }  )
    dbcreate( 'stoctake', adbf )

    NetUse( 'stoctake' )
    append from bcr.txt sdf
    mspace = space(50)
    Box_Save( 02, 08, 12, 72 )

    stocktake->( dbgotop() )
    while !stoctake->( eof() ) .and. upper( stoctake->scan ) != 'EOF'

     if !empty( stoctake->scan )

      mscan := trim( stoctake->scan )
      Highlight( 5, 10, 'Stock Item Label #', mscan )

      if !items->( dbseek( mscan ) )
       Error( 'Code ' + mscan + ' not on file', 12 )

      else
       Rec_lock('items')
       items->stocktake := TRUE
       items->( dbrunlock() )

       @ 10,10 clear to 12,70
       Highlight( 07, 10, 'Last item scanned -=> ', items->desc )
       Highlight( 08, 10, 'Items scanned this session = ', Ns( mtot, 5 ) )

       mtot++

      endif
     endif

     stoctake->( dbskip() )

    enddo

    stoctake->( dbclosearea() )
    select items

   endif
  endif

 case choice = 4
  Heading('Stocktake Report Menu')
  Printchoice = 1
  Box_Save( 05, 34, 10, 46 )
  @ 06,35 prompt 'Exit      ' message Line_clear(24)+'Return to Stocktake Menu'
  @ 07,35 prompt ' All items' message Line_clear(24)+'All items in Stocktake'
  @ 08,35 prompt ' Not found' message Line_clear(24)+'Items Not found in Location'
  @ 09,35 prompt ' Incorrect' message Line_clear(24)+'Items in Incorrect Location'
  @ 05,35 say 'Reports'
  menu to printchoice

  items->( dbgotop() )

  do case
  case printchoice = 2
   Heading("Print all found items")
   if Isready()
    Box_Save( 12, 20, 14, 60 )
    @ 13,21 say '-=< Processing - Please Wait >=-'
    // Printcheck()
    // Pitch17()

       aFlds := {}
       aadd( aflds, { 'items->item_code', 'Item;Code', 10, 0, FALSE } )
       aadd( aflds, { 'items->serial', 'Serial No', 10, 0, FALSE } )
       aadd( aflds, { 'items->desc', 'Description', 20, 0, FALSE } )


       Reporter( aFlds, ;
              'Complete List Stocktake Items',;
              '',;
              '',;
              '',;
              '',;
              FALSE,;
              '',;
              'items->stocktake',;
              132 ;
            )

//    report form stoctake to print noconsole while inkey() != K_ESC ;
//           for items->stocktake heading 'Complete list of Stocktake Items' noeject

    // Pitch10()
    // EndPrint()

   endif

  case printchoice = 3
   Heading("Print items not found Report")
   if Isready()
    Box_Save( 12, 20, 14, 60 )
    @ 13,21 say '-=< Processing - Please Wait >=-'
    // Printcheck()

       aFlds := {}
       aadd( aflds, { 'items->item_code', 'Item;Code', 10, 0, FALSE } )
       aadd( aflds, { 'items->serial', 'Serial No', 10, 0, FALSE } )
       aadd( aflds, { 'items->desc', 'Description', 20, 0, FALSE } )


       Reporter( aFlds, ;
              'List of Items not found in Stocktake',;
              '',;
              '',;
              '',;
              '',;
              FALSE,;
              '',;
              '!items->stocktake .and. items->status ="O"',;
              132 ;
            )


//    report form stoctake to print noconsole while inkey() != K_ESC ;
//           for ( !items->stocktake .and. items->status = 'O' ) ;
//           Heading 'List of Items not found in Stocktake' noeject

   // EndPrint()

   endif

  case Printchoice = 4
   Heading('Print Incorrect Items found Report')
   if Isready(12)
    Box_Save( 12, 20, 14, 60 )
    @ 13,21 say '-=< Processing - Please Wait >=-'
    //Printcheck()

    aFlds := {}
    aadd( aflds, { 'items->item_code', 'Item;Code', 10, 0, FALSE } )
    aadd( aflds, { 'items->serial', 'Serial No', 10, 0, FALSE } )
    aadd( aflds, { 'items->desc', 'Description', 20, 0, FALSE } )


       Reporter( aFlds, ;
              'List of Items found Incorrectly in Stocktake',;
              '',;
              '',;
              '',;
              '',;
              FALSE,;
              '',;
              'items->stocktake .and. items->status != "O"',;
              132 ;
            )


  //  report form stoctake to print noconsole while inkey() != K_ESC ;
  //         for items->stocktake .and. items->status != 'O' ;
  //         Heading 'List of Items found Incorrectly in Stocktake' noeject

  //  EndPrint()

   endif
  endcase

 case choice < 2
  exit

 endcase
enddo

dbcloseall()

return
