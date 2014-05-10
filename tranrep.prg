/** @package 

      tranrep.prg

      Last change:  TG   26 Jan 2012    6:47 pm
*/

Procedure TranRep

#include "winrent.ch"

local aMenu, nMenuChoice
local aTotals
local aArray, mdebit, mcredit, toti, page, nRow
local mfirst, notdone
local farr
local mcontract
local mpos, x
local cScr
local getlist := {}
local oPrinter

memvar mStartCont, mEndCont, enddate, mdate  // Needed for Reporter to work

// private mtran, mStartCont := 0, mEndCont := 0  // Just being lazy here!

private mprintdate

aMenu := {}
aadd( aMenu, { 'Exit', 'Return to Misc Reports' } )
aadd( aMenu, { 'Contract', 'Print Transactions on Contract(s)' } )
aadd( aMenu, { 'GST', 'Print GST Transactions by Period' } )
aadd( aMenu, { 'Totals', 'Display totals to Screen' } )
nMenuChoice := Menugen( aMenu, 5, 36, 'Transaction' )

if nMenuchoice > 1

  cScr := Box_Save( 5, 08, 8, 72 )
  mdate := Oddvars( SYSDATE ) - 30
  @ 6,10 say 'Enter starting Date' get mdate
  enddate := Oddvars( SYSDATE )
  @ 7,10 say '     Enter end Date' get enddate valid enddate >= mdate
  read


  do case
  case nMenuChoice = 2

   if ContSelect( @mStartCont, @mEndCont )

    if NetUse( "hirer" )
     if NetUse( "tran" )
      set relation to tran->con_no into hirer
      tran->( dbgotop() )
      oPrinter := Printcheck( 'Transaction Listing' )
      aArray := {}
      mdebit := 0
      mcredit := 0
      toti := 0
      nRow := 0
      page := 1

      while !tran->( eof() ) .and. PinWheel()
       if nRow = 0
        oPrinter:NewLine()
        oPrinter:textout( 'Page ' + Ns( page ) )
        oPrinter:SetPos( 32 * oPrinter:CharWidth )
        oPrinter:textout( 'Transaction Listing' )
        oPrinter:SetPos( 72 * oPrinter:CharWidth )
        oPrinter:textout( dtoc( date() ) )
        oPrinter:NewLine()
        oPrinter:textout( 'Cont.#   Hirer name        Date       Credit    Debit  Tran Type    Comment' )
 #ifdef INSURANCE
        @ 2,72 say 'Ins'
 #endif
        oPrinter:NewLine()
        oPrinter:textout( replicate( chr( 196 ), 80 ) )
        nRow := 5
        page++
        mfirst := TRUE
        mcontract := tran->con_no
        notdone := TRUE

       endif

       while nRow <= 56 .and. !tran->( eof() ) .and. PinWheel()
        if ( tran->date >= mdate .and. tran->date <= enddate ) .and. ;
           ( tran->con_no >= mstartCont .and. tran->con_no <= mEndCont )
         if mfirst .or. notdone
          oPrinter:NewLine()
          oPrinter:textout( transform( tran->con_no, CON_NO_PICT ) )
          oPrinter:setpos( 08 * oPrinter:CharWidth )
          oPrinter:textout( left( hirer->surname, 15 ) )
          mfirst := FALSE
          notdone := FALSE

         endif

         oPrinter:setpos( 25 * oPrinter:CharWidth )
         oPrinter:textout( dtoc( tran->date ) )

         if tran->value > 0
          oPrinter:setpos( 36 * oPrinter:CharWidth )
          oPrinter:textout( transform( tran->value, CURRENCY_PICT ) )

          mcredit += tran->value

         else
          oPrinter:setpos( 45 * oPrinter:CharWidth )
          oPrinter:textout( transform( tran->value * -1, CURRENCY_PICT ) )

          mdebit += tran->value * -1

         endif

         mpos := ascan( aArray, { | x | x[ 1 ] = tran->type } )
         if mpos = 0
          aadd( aArray, { tran->type, tran->value } )

         else 
          aArray[ mpos, 2 ] += tran->value 

         endif 

 #ifdef INSURANCE
         toti += tran->insurance
 #endif
          oPrinter:setpos( 55 * oPrinter:CharWidth )
          oPrinter:textout( left( Tran_type( tran->type, '' ), 10 ) )

          oPrinter:setpos( 66 * oPrinter:CharWidth )
          oPrinter:textout( left( tran->narrative, 13 ) )

 #ifdef INSURANCE
          oPrinter:setpos( 72 * oPrinter:CharWidth )
          oPrinter:textout( Ns( tran->insurance, 7, 2 ) )

 #endif

         nRow++
         oPrinter:NewLine()
         mcontract := tran->con_no

        endif
        tran->( dbskip() )
        mfirst := ( mcontract != tran->con_no )

       enddo

       if nRow > 56
        nRow := 0

       endif

      enddo
      oPrinter:setpos( 36 * oPrinter:CharWidth )
      oPrinter:textout( replicate( ULINE, 8 ) )
      oPrinter:setpos( 45 * oPrinter:CharWidth )
      oPrinter:textout( replicate( ULINE, 8 ) )
      nRow++
      oPrinter:NewLine()
      oPrinter:setpos( 25 * oPrinter:CharWidth )
      oPrinter:textout( 'Totals' )

      oPrinter:setpos( 36 * oPrinter:CharWidth )
      oPrinter:textout( Transform( mcredit, CURRENCY_PICT ) )

      oPrinter:setpos( 45 * oPrinter:CharWidth )
      oPrinter:textout( Transform( mDebit, CURRENCY_PICT ) )

      oPrinter:NewLine()
      oPrinter:TextOut( padl( 'Transaction totals', 25 ) )
      oPrinter:NewLine()
      oPrinter:Textout( padl( replicate( ULINE, 18 ), 25 ) ) // Yeh, Yeh I know its kludgy

      asort( aArray, , , { | x, y | x[ 1 ] < y[ 1 ] } )

      for x := 1 to len( aArray )
       oPrinter:NewLine()
       oPrinter:TextOut( padl( tran_type( aArray[ x, 1 ] ), 25 ) + '  ' + str( aArray[ x, 2 ], 10, 2 ) )

      next 


 #ifdef INSURANCE
      oPrinter:NewLine()
      oPrinter:TextOut( '     Insurance' + Ns( toti, 10, 2 ) )
 #endif

      oPrinter:Enddoc()
      oPrinter:Destroy()

     endif

    endif

    dbcloseall()

   endif

  case nMenuChoice = 3
   if NetUse( "tran" )
    farr := {}
    aadd( farr, { 'tran->date', 'Date', 9, 0, FALSE } )
    aadd( farr, { 'tran->con_no', 'Contract;Number', 9, 0, FALSE } )
    aadd( farr, { 'tran->value', 'Total (Inc GST)', 15, 2, TRUE } )
    aadd( farr, { 'tran->gst', 'GST Amt', 10, 2, TRUE } )
    aadd( farr, { 'tran_type( tran->type) ', 'Transaction Type', 20, 0, FALSE } )
    Reporter(   farr, ;
                'GST Report',;
                '',;
                '',;
                '',;
                '',;
                FALSE,;
                'tran->date >= mdate .and. tran->date <= enddate .and. tran->gst != 0', ;
                ,;
                80 )

    // EndPrint()

    dbcloseall()

   endif 

  case nMenuChoice = 4
   if NetUse( "tran" )

    aTotals := {}
    while !tran->( eof() ) .and. Pinwheel()
     if tran->date >= mdate .and. tran->date <= enddate

      mpos := ascan( aTotals, { | x | x[ 1 ] = tran->type } )
      if mpos = 0
       aadd( aTotals, { tran->type, tran->value, tran->gst } )

      else 
       aTotals[ mpos, 2 ] += tran->value 
       aTotals[ mpos, 3 ] += tran->gst

      endif 
     endif  
     tran->( dbskip() )
      
    enddo
    Box_Save( 3, 2, len( aTotals ) +5, 77 )
    Highlight( 4, 4, 'Transaction totals', dtoc( mdate ) + ' to ' + dtoc( enddate ) + '     GST Collected' )

    for x := 1 to len( aTotals )
     @ row()+1, 4 say padr( tran_type( aTotals[ x, 1 ] ), 25 ) + '  ' + str( aTotals[ x, 2 ], 12, 2 ) +;
                     '     '+  str( aTotals[ x, 3 ], 10, 2 )

    next 
    Error( '' )
    dbcloseall()

   endif 

  endcase

endif

return
