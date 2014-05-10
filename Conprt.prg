/*

 Rental system - Bluegum Software
 Module Conprt - Contracts Print Menu
 17/12/86 T. Glynn


      Last change:  TG   14 Mar 2011    2:16 pm
*/

#include "winrent.ch"

static page_no
static mrow

Procedure ConPrt

local choice, mdet, oldscr := Box_Save()
local getlist := {}
local mhead1
local mrent
local m_conno
local mans
local aArray
local msite
local aflds
local cForExpr
local oPrinter

memvar mend, mstart, menq

while TRUE

 Box_Restore( oldscr )

 Heading('Contract Print Menu')

 aArray := {}
 aadd( aArray, { 'Exit', 'Return to Reports menu' } )
 aadd( aArray, { 'Numerical', 'List of all contracts by numeric order' } )
 aadd( aArray, { 'Alphabetic', 'List of all contracts by hirer surname' } )
 aadd( aArray, { 'Bond List', 'Listing of all Bonds' } )
 aadd( aArray, { 'Insurance', 'Insurance Listing' } )
 aadd( aArray, { 'Location', 'Contracts Printed by Location' } )
 choice := MenuGen( aArray, 03, 36, 'Contract' )

 if choice < 2
  dbcloseall()
  return

 endif

 *

 do case
 case choice = 2
  if NetUse( 'items' )
   items->( ordsetfocus( 'contract' ) )
   if NetUse( 'hirer' )
    if NetUse( 'master' )
     set relation to master->con_no into hirer,;
                  to master->con_no into items

     Box_Save( 3, 06, 9, 74 )
     Heading( 'Select contracts for Print' )

     mstart := 0
     @ 5,08 say 'Enter start Contract, <Return> for all or <Esc> to exit ' get mstart pict '######'
     read

     if lastkey() = K_ESC
      loop

     else
      if mstart != 0
       mend := 0
       @ 6, 08 say 'Enter ending Contract no' get mend pict '999999' valid( mend >= mstart )
       read

       if !updated()
        loop

       endif

      else
       master->( dbgobottom() )
       mend := master->con_no
       master->( dbgotop() )
       mstart := master->con_no

      endif
      mdet := NO
      menq := NO
      @ 7,08 say 'Details list ?' get mdet pict 'Y'
      @ 7,40 say 'Enquiry Contracts Only' get menq pict 'Y'
      read

      select master

      if !mdet

       aFlds := {}

       aadd( aflds, { 'master->con_no', 'Contract;Number', 9, 0, FALSE } )
       aadd( aflds, RPT_SPACE )
       aadd( aflds, { 'hirer->surname', 'Surname', 20, 0, FALSE } )
       aadd( aflds, { 'hirer->first', 'First Name', 20, 0, FALSE } )
       aadd( aflds, { 'trim(hirer->add1)+" "+trim(hirer->add2)+" "+trim(hirer->suburb)', 'Address', 30, 0, FALSE } )
       aadd( aflds, { 'master->paid_to', 'Paid To', 8, 0, FALSE } )
       aadd( aflds, { 'master->bal_bf', 'Balance;B/F', 10, 2, FALSE } )
#ifdef BYRNES
       aadd( aflds, { 'master->install', 'Install', 10, 2, FALSE } )
       aadd( aflds, RPT_SPACE )
       aadd( aflds, { 'master->EndDate', 'End Date', 8, 0, FALSE } )
#endif
       Reporter( aFlds, ;                               // Array
              'Contract Listing - Numeric',;            // Report Name
              '',;                                      // Group By
              '' ,;                                     // Group Heading
              '',;                                      // Sub Group By
              '',;                                      // Sub Group head
              FALSE,;                                   // Summary
              "if( menq, master->inquiry, !master->inquiry )",;                                      // For Condition
              '( hirer->con_no >= ' + ns(mstart) + ' .and. hirer->con_no <= ' + ns(mend) + ' )' ,;
              132 ;
            )

      else
       mhead1 := " Contract Hirer's Name & Addr.     Telephone     Due Date"
       mhead1 += '     Balance  Items            Desc'
       oPrinter := PrintCheck( "Contract Listing" )
       page_no := 1
       mrow := 1

       while !master->( eof() ) .and. inkey() != K_ESC .and. PinWheel()

        if ( master->con_no >= mstart .and. master->con_no <= mend ) .and. ;
           if( menq, master->inquiry, !master->inquiry )

         if empty( master->term_rent )
          mrent := 'm_rent'

         else
          mrent := master->term_rent + '_rent'

         endif

         Conout( mhead1, ,oPrinter )

        endif

        if inkey() = K_ESC
         exit

        endif

        master->( dbskip() )

       enddo
       oPrinter:EndDoc()
       oPrinter:Destroy()

      endif

     endif
    endif
   endif
  endif
  dbcloseall()

 case choice = 3
  if NetUse( "items" )
   items->( ordsetfocus( 'contract' ) )
   if NetUse( "master" )
    if NetUse( "hirer" )
     hirer->( ordsetfocus( 'surname' ) )
     set relation to hirer->con_no into master,;
                  to hirer->con_no into items

     Box_Save( 3, 06, 9, 74 )
     Heading('Select contracts for print')
     mans := 'A'
     @ 5, 08 say 'Select a <R>ange or <A>ll contracts' get mans pict '!' valid( mans $ 'AR' )
     read
     mstart := 'AAA'
     mend := 'ZZZ'

     if mans = 'R'
      mstart := space(3)
      @ 6, 08 say 'First three letters of start surname' get mstart pict '!!!'
      read
      @ 7, 08 say '  First three letters of end surname' get mend pict '!!!'
      read
     endif

     mdet := FALSE
     menq := FALSE
     @ 8, 08 say 'Details list ?' get mdet pict 'Y'
     @ 8, 40 say 'Enquiry Contracts Only' get menq pict 'Y'
     read

     if mstart != 'AAA'
      hirer->( dbseek( trim( mstart ) ) )

     else
      hirer->( dbgotop() )

     endif

     if !mdet

      aflds := {}
      aadd( aflds, { 'hirer->surname', 'Surname', 20, 0, FALSE } )
      aadd( aflds, { 'hirer->first', 'First Name', 20, 0, FALSE } )
      aadd( aflds, { "trim(hirer->add1)+' '+trim(hirer->add2)+' '+trim(hirer->suburb)", 'Address', 30, 0, FALSE } )
      aadd( aflds, { 'hirer->con_no', 'Contract;Number', 8, 0, FALSE } )
      aadd( aflds, { 'master->paid_to', 'Paid To', 8, 0, FALSE } )
      aadd( aflds, { 'balanceTot()', 'Balance', 10, 0, FALSE } )

      if menq
       cForExpr :=  'upper( hirer->surname ) >= "' + mstart + '" .and. upper( hirer->surname ) <= "' + mend + '"' +;
                '.and. master->inquiry'
      else
       cForExpr := 'upper( hirer->surname ) >= "' + mstart + '" .and. upper( hirer->surname ) <= "' + mend +  '"' +;
                '.and. !master->inquiry'
      endif

      Reporter( aflds,;
                'Contract Listing by Alpha', ;
                '' ,;
                '' ,;
                '' ,;
                '' ,;
                FALSE,;
                cForExpr,;
                '' ,;
                80  ;
              )

     else
      mhead1 := " Contract  Hirer's  Name & Addr.   Telephone      Due Date"
      mhead1 += '     Balance   Items            Desc'
      oPrinter := PrintCheck( "Contract Listing" )
      page_no := 1
      mrow := 1

      while !hirer->( eof() ) .and. inkey() != K_ESC .and. Pinwheel()

       if ( mans = 'A' .or. ( mans = 'R' .and. upper( hirer->surname ) >= mstart .and. ;
                            upper( hirer->surname) <= mend ) ) .and. ;
                            if( menq, master->inquiry, !master->inquiry )

        if empty( master->term_rent )
         mrent := 'm_rent'
        else
         mrent := master->term_rent + '_rent'
        endif
        m_conno := hirer->con_no

        Conout( mhead1, , oPrinter )

       endif

       if inkey() = K_ESC
        exit
       endif

       hirer->( dbskip() )

      enddo
      oPrinter:EndDoc()
      oPrinter:Destroy()

     endif

    endif
   endif
  endif
  dbcloseall()

 case choice = 4
  if NetUse( "hirer" )
   if NetUse( "master" )
    set relation to master->con_no into hirer
    Heading('Bond Listing')
    if Isready()

     master->( dbgotop() )

     aFlds := {}
     aadd( aflds, { 'transform( master->con_no, "9999999" )', 'Contract;Number', 11, 0, FALSE } )
     aadd( aflds, RPT_SPACE )
     aadd( aflds, { 'left( trim(hirer->first)+" "+trim(hirer->surname), 50 )', 'Hirer Name', 50, 0, FALSE } )
     aadd( aflds, { 'master->bond_paid', 'Bond;Paid', 8, 0, TRUE } )
     aadd( aflds, RPT_SPACE )
     aadd( aflds, { 'master->bond_date', 'Bond Paid;Date', 9, 0, FALSE } )
     aadd( aflds, { 'master->bond_ret', 'Bond;Returned', 8, 0, TRUE } )
     aadd( aflds, RPT_SPACE )
     aadd( aflds, { 'master->bond_ret_d', 'Date Bond;Returned', 9, 0, FALSE } )


     Reporter( aFlds, ;
              'Bond Listing',;
              '',;
              '' ,;
              '',;
              '',;
              FALSE,;
              'master->bond_paid > 0',;
              '',;
              132 ;
             )

    endif
   endif
  endif
  dbcloseall()

 case choice = 5
  if NetUse("items" )
   items->( ordsetfocus( 'contract' ) )
   if NetUse("hirer" )
    if NetUse( "master" )
     set relation to master->con_no into hirer,;
                  to master->con_no into items
     Heading('Insurance Listing')
     if Isready()
       aFlds := {}
       aadd( aflds, { 'master->con_no', 'Contract;Number', 9, 0, FALSE } )
       aadd( aflds, { 'trim(hirer->first)+" "+trim(hirer->surname)', 'Hirer Name', 30, 0, FALSE } )
       aadd( aflds, { 'ins_amt( master->con_no )', 'Insurance;Amt', 10, 2, TRUE } )


       Reporter( aFlds, ;
              'Insurance Listing',;
              '',;
              '' ,;
              '',;
              '',;
              FALSE,;
              '',;
              'master->insurance',;
              80 ;
            )

     endif
    endif
   endif
  endif
  dbcloseall()

 case choice = 6
  if NetUse( 'sites' )
   if NetUse( 'items' )
    items->( ordsetfocus( 'contract' ) )
    if NetUse( 'hirer' )
     if NetUse( 'master' )
      master->( ordsetfocus( 'site' ) )
      set relation to master->con_no into hirer,;
                   to master->con_no into items

      Box_Save( 3, 06, 9, 74 )
      Heading( 'Select contracts for Print' )

      msite := space( SITELEN )
      @ 5,08 say 'Enter site, <Return> for all or <Esc> to exit ' get msite pict '@!'
      read

      if lastkey() = K_ESC
       loop

      else

       if empty( msite )
        master->( dbgotop() )
       else
        master->( dbseek( msite ) )

       endif
        mhead1 := " Contract  Hirer's Name & Addr.   Telephone      Due Date"
        mhead1 += '     Balance   Items            Desc'
        oPrinter := PrintCheck( "Contracts Print by Location" )
        page_no := 1
        mrow := 1

        while !master->( eof() ) .and. inkey() != K_ESC .and. PinWheel()

         if ( master->site = msite .or. empty( msite ) ) .and. !master->inquiry

          if empty( master->term_rent )
           mrent := 'm_rent'

          else
           mrent := master->term_rent + '_rent'

          endif

          Conout( mhead1, master->site, oPrinter )

         endif

         if inkey() = K_ESC
          exit

         endif

         master->( dbskip() )

        enddo

       oPrinter:EndDoc()
       oPrinter:Destroy()
      endif
     endif
    endif
   endif
  endif

  dbcloseall()

 endcase

enddo

return

*

function ins_amt ( mcon )
local mamt := 0
select items
sum items->insurance to mamt while items->con_no = mcon .and. !items->( eof() )
select master
return mamt

*

procedure conout ( mhead1, msite, oPrinter )

local int_row := 1
local msur
local mfirst
local madd1
local madd2
local msub
local mpc
local mtele
local mempl
local mrecno
local mcontract := hirer->con_no

default msite to space( SITELEN )

while int_row < 5

 if mrow <= 5
  oPrinter:Newline()
  oPrinter:textout( replicate('-',130) )
  oPrinter:Newline()
  oPrinter:setpos( 10 * oPrinter:charWidth )
  oPrinter:textout( trim( BVars( B_COMPANY ) ) )
  oPrinter:setpos( 50 * oPrinter:charWidth )
  oPrinter:textout( 'Contract Details' )
  oPrinter:setpos( 118 * oPrinter:CharWidth )
  oPrinter:textout( 'Page No ' + Ns( page_no ) )
  oPrinter:Newline()
  oPrinter:textout( replicate( '-', 130 ) )
  oPrinter:Newline()
  oPrinter:Newline()
  oPrinter:textout( mhead1 )

  page_no++
  mrow := 7

 endif

 do case
 case int_row = 1
  msur := ''
  mfirst := ''
  madd1 := hirer->add1
  madd2 := hirer->add2
  msub  := hirer->suburb
  mpc   := hirer->pcode
  mtele := hirer->tele_priv
  mempl := hirer->tele_empl

  mrecno := hirer->( recno() )

  while hirer->con_no = mcontract .and. !hirer->( eof() )
   msur += trim( hirer->surname ) + '/'
   mfirst += trim( hirer->first ) + '/'
   hirer->( dbskip() )

  enddo

  hirer->( dbgoto( mrecno ) )

  msur := left( msur, len( trim( msur ) ) -1 )
  mfirst := left( mfirst, len( trim( mfirst ) ) -1 )
  oPrinter:NewLine()
#ifdef MULTI_SITE
  oPrinter:textout( trim( msite ) + transform( mContract, CON_NO_PICT ) )

#else
  oPrinter:textout( transform( master->con_no, CON_NO_PICT ) )

#endif
  oPrinter:setpos( 12 * oPrinter:CharWidth )
  oPrinter:textout( left( msur, 26 ) )
#ifdef BYRNES
  oPrinter:setpos( 38 * oPrinter:CharWidth )
  oPrinter:textout( dtoc( master->commenced ) )

#else
  oPrinter:setpos( 38 * oPrinter:CharWidth )
  oPrinter:textout( mtele )

#endif
  oPrinter:setpos( 50 * oPrinter:CharWidth )
  oPrinter:textout( dtoc( master->paid_to ) )
  oPrinter:setpos( 60 * oPrinter:CharWidth )
  oPrinter:textout( transform( master->bal_bf, TOTAL_PICT ) )
#ifdef BYRNES
  oPrinter:setpos( 70 * oPrinter:CharWidth )
  oPrinter:textout( transform( master->install, TOTAL_PICT ) )
  oPrinter:setpos( 82 * oPrinter:CharWidth )
  oPrinter:textout( dtoc( master->EndDate ) )

#endif
 case int_row = 2
  oPrinter:NewLine()
  if master->inquiry
   oPrinter:textout( 'Enquiry' )

  endif
  oPrinter:setpos( 12 * oPrinter:CharWidth )
  oPrinter:textout( left( mfirst, 26 ) )
#ifdef BYRNES
  oPrinter:setpos( 38 * oPrinter:CharWidth )
  oPrinter:textout( transform( master->install, TOTAL_PICT ) )

#else
  oPrinter:setpos( 38 * oPrinter:CharWidth )
  oPrinter:textout( mempl )

#endif

 case int_row = 3
  oPrinter:NewLine()
  if master->inquiry
   oPrinter:textout( replicate( '*', 7 ) )

  endif
  oPrinter:setpos( 12 * oPrinter:CharWidth )
  oPrinter:textout( trim( madd1 ) + ' ' + madd2 )
  oPrinter:setpos( 38 * oPrinter:CharWidth )
  oPrinter:textout( master->comments1 )

 case int_row = 4
  oPrinter:NewLine()
  oPrinter:setpos( 12 * oPrinter:CharWidth )
  oPrinter:textout( trim( msub ) + ' ' + mpc )
  oPrinter:setpos( 38 * oPrinter:CharWidth )
  oPrinter:textout( master->comments2 )

 endcase
 items->( dbseek( mcontract ) )
 items->( dbskip( int_row -1 ) )

 if items->con_no = mcontract
  oPrinter:setpos( 72 * oPrinter:CharWidth )
  oPrinter:textout( items->item_code )
  oPrinter:setpos( 90 * oPrinter:CharWidth )
  oPrinter:textout( items->desc )
  oPrinter:setpos( 120 * oPrinter:CharWidth )
  oPrinter:textout( transform( items->( fieldget( items->( fieldpos( master->term_rent + '_rent' ) ) ) ), CURRENCY_PICT ) )

 endif

 int_row++
 mrow++

 if mrow > 60
  oPrinter:NewPage()
  mrow := 1

 endif

enddo
oPrinter:NewLine()
mrow++
return

*

Function BalanceTot  // Fixes installment total on ConAlpha.frm
local mamt := master->bal_bf, mrec := hirer->( recno() )
// Determine if selected hirer is first in line.
local oldord := hirer->( ordsetfocus( 'contract' ) )
hirer->( dbseek( hirer->con_no ) )
if hirer->( recno() ) != mrec   // Must have been second ( or greater ) hirer
 mamt := 0

endif
hirer->( ordsetfocus( oldord ) )
hirer->( dbgoto( mrec ) )
return mamt
