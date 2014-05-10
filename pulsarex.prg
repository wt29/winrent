/*
    MYOB Export routines


 Last change:  TG   18 Oct 2010   10:52 pm

*/

#include "winrent.ch"

Procedure PulsarExpo
local aArray, fchoice

while TRUE
 Heading('Pulsar Export')
 aArray := {}
 aadd( aArray, { 'Report', 'Return to Reports Menu' } )
 aadd( aArray, { 'Invoices', 'Export Invoices', { || PulsarInvExport() } } )
 aadd( aArray, { 'Payments', 'Export Payments', { || PulsarPayExport() } } )
 fchoice := MenuGen( aArray, 08, 36, 'Export' )

 if fchoice < 2
  exit
 else
  Eval( aArray[ fchoice, 3 ] )
 endif

enddo
return

*

Procedure PulsarInvExport()

local mdate := Bvars( B_SYSDATE ), mcomment := space( 40 )
local getlist:={}
local minext
local aPayType := {}
// local nArrIndex
// local nArrLen
local nItemNo
// local cInvno
local nSaleno
local nTotGST

if NetUse( 'paytype' )

 if NetUse( 'tran' )

  if NetUse( 'sales' )
   if NetUse( 'salitems' )
    if NetUse( 'debtor' )
     debtor->( ordsetfocus( 'debtno' ) )

     if NetUse( "items" )
      items->( ordsetfocus( 'contract' ) )

      if NetUse( "hirer" )

       if NetUse( "master" )
        set relation to master->con_no into hirer,;
                     to master->con_no into items

        Box_Save( 2, 08, 6, 72 )
        @ 3,10 say 'Date to export' get mdate
        @ 4,10 say 'Comment' get mcomment
        read

        while !master->( eof() )

         if master->next_inst = mdate .and. master->billmethod = 'I'

          minext := Period( master->next_inst, 1, master->term_rent )

          sales->( ordsetfocus( 'saleno' ) )
          sales->( dbgobottom() )

          nSaleNo := sales->saleno++

          debtor->( dbseek( master->Extra_key ) )


          Add_rec( 'sales' )
          sales->saleno := nSaleNo
          sales->debtno := master->extra_Key
          sales->company := debtor->company
          sales->entrydate := mdate
          sales->ftotal := 0


          nItemNo := 0
          nTotGST := 0


          while items->con_no = master->con_no .and. !items->( eof() )
           add_rec( 'salitems' )
           salitems->debtno := master->Extra_Key
           salitems->partno := items->MyobCode
           salitems->item := items->desc
           salitems->qty := 1
           salitems->price := items->m_rent - GSTPAID( items->m_rent )                          // Price
           salitems->taxpaid := if( master->TaxFree, 0, GSTPaid( items->m_rent ) )               // Tax Paid
           salitems->linetotal := salitems->price + salitems->taxpaid
           salitems->entrydate := mdate

           nTotGST += saleitems->taxpaid
           items->( dbskip() )

          enddo

          sales->GST := nTotGST
          sales->( dbrunlock() )

         endif

         master->( dbskip() )

        enddo

       endif
      endif
     endif
    endif
   endif
  endif
 endif
endif

dbcloseall()

return

*

Procedure PulsarPayExport

local mdate := Bvars( B_SYSDATE ), mhandle, mcomment := space( 40 )
local cPayType
local nPercent
local cInvno

local getlist:={}

if NetUse( 'paytype' )

 if NetUse( 'MYOBCode' )

  if NetUse( "items" )
   items->( ordsetfocus( 'contract' ) )
   set relation to items->MYOBCode into MYOBCode

   if NetUse( 'hirer' )

    if NetUse( 'master' )

     if NetUse( 'tran' )
      set relation to tran->con_no into items,;
                   to tran->con_no into hirer,;
                   to tran->con_no into master,;
                   to tran->paytype into paytype

      Box_Save( 2, 08, 6, 72 )
      @ 3,10 say 'Date to export' get mdate
      @ 4,10 say 'Comment' get mcomment
      read

      if lastkey() != K_ESC

       tran->( ordsetfocus( 'paytype' ) )  // Actually indexed by dtos( date ) + paytype

       tran->( dbseek( dtos( mdate ) ) )

       if tran->( found() )

        mhandle := fcreate( 'myobpay.txt' )

        while tran->date = mdate .and. !tran->( eof() )

         cPayType := tran->paytype   // Must be the first one on the list

         cInvno := Ns( SysInc( 'MYOBInvNo', 'I' ) )

         while tran->date = mdate .and. tran->paytype = cPaytype .and. !tran->( eof() )

          if tran->type = RENTAL_PAYMENT

           while items->con_no = tran->con_no .and. !items->( eof() )

            npercent := items->( fieldget( items->( fieldpos( master->term_rent + '_rent' ) ) ) )* ;
                 int( tran->value / master->install )

            fwrite( mhandle, trim( paytype->myobcode ) + TAB )                                   // F1
            fwrite( mhandle, TAB )                                                               // F2
            fwrite( mhandle, TAB )                                                               // F3
            fwrite( mhandle, TAB )                                                               // F4
            fwrite( mhandle, TAB )                                                               // F5
            fwrite( mhandle, TAB )                                                               // F6
            fwrite( mhandle, 'x' + TAB )                                                         // F7 Inclusive
            fwrite( mhandle, 'P' + cInvno + TAB )                                                // F8
            fwrite( mhandle, dtoc( mdate ) + TAB )                                               // F9
            fwrite( mhandle, TAB )                                                               // F10
            fwrite( mhandle, TAB )                                                               // F11
            fwrite( mhandle, TAB )                                                               // F12 Handwritten
            fwrite( mhandle, trim( items->MYOBCode ) + TAB )                                     // F13 Tax Code number

            fwrite( mhandle, '1' + TAB )                                                         // F14 Number of Items

            fwrite( mhandle, Ns( tran->con_no ) + TAB )                                          // F15 Item Description

            fwrite( mhandle, Ns( nPercent - if( !master->TaxFree, GSTPAID( nPercent ), 0), 10, 2 ) + TAB )           // F16 Tax Ex Price
            fwrite( mhandle, Ns( nPercent ) + TAB )                                           // F17 Tax Inc Price
            fwrite( mhandle, '0' + TAB )                                                         // F18 Discount
            fwrite( mhandle, Ns( nPercent - if( !master->TaxFree, GSTPaid( nPercent ), 0), 10, 2 ) + TAB )           // F19 Tax Ex Totals
            fwrite( mhandle, Ns( nPercent ) + TAB )                                           // F20 Tax Inc Totals
            fwrite( mhandle, TAB )                                                               // F21
            fwrite( mhandle, TAB )                                                               // F22
            fwrite( mhandle, Ns( tran->con_no, 10, 0 ) + TAB )                                   // F23
            fwrite( mhandle, TAB )                                                               // F24
            fwrite( mhandle, TAB )                                                               // F25
            fwrite( mhandle, TAB )                                                               // F26 Date Commenced
            fwrite( mhandle, TAB )                                                               // F27
            fwrite( mhandle, if( master->TaxFree, 'FRE', 'GST' ) + TAB )                         // F28 Tax Flag
            fwrite( mhandle, TAB )                                                               // F29
            fwrite( mhandle, if( master->TaxFree, '0', Ns( GSTPaid( nPercent ), 10, 2 ) )+ TAB )    // F30
            fwrite( mhandle, TAB )                                                               // F31
            fwrite( mhandle, TAB )                                                               // F33
            fwrite( mhandle, TAB )                                                               // F34
            fwrite( mhandle, TAB )                                                               // F35
            fwrite( mhandle, TAB )                                                               // F36
            fwrite( mhandle, TAB )                                                               // F37
            fwrite( mhandle, TAB )                                                               // F38
            fwrite( mhandle, TAB )                                                               // F39
            fwrite( mhandle, '0' + TAB )                                                         // F40
            fwrite( mhandle, TAB )                                                               // F41
            fwrite( mhandle, TAB )                                                               // F42
            fwrite( mhandle, TAB )                                                               // F43
            fwrite( mhandle, TAB )                                                               // F44
            fwrite( mhandle, CRLF )                                                              // F45

            items->( dbskip() )

           enddo

          endif

          tran->( dbskip() )

         enddo

         fwrite( mhandle, CRLF )    // Write out extra line to delimit invoice

        enddo

        fclose( mhandle )

       endif
      endif
     endif
    endif
   endif
  endif
 endif
endif

dbcloseall()

return

*

Function StrZero( nVal, nlength )
return padl( ns( nval) , nlength, '0' )
