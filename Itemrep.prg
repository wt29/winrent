/*

 Rentals - Bluegum Software

 Module Itemrep - Stock Items Reports
 T. Glynn 13:49:47  8/22/1987

 Last change:  APG  15 Jun 2004    3:46 pm

      Last change:  TG   18 Oct 2010   10:53 pm
*/

#include "winrent.ch"

Procedure Itemrep

local newchoice, mlist, getlist:={}, madvance
local mprod
local mtype
local oldscr := Box_Save()
local msort
local valonhand := 0
local valonrent := 0
local aArray 
local aFlds

memvar mstatus, mowner

while TRUE

 Box_Restore( oldscr )
 Heading('Item file Print menu')

 aArray := {}
 aadd( aArray, { 'Exit', 'Return to Report Menu' } )
 aadd( aArray, { 'Stock' , 'Stock listing' } )
 aadd( aArray, { 'Bailment', 'Stock location ( Bailment ) list' } )
 aadd( aArray, { 'Payout', 'Payout Figure list' } )
 aadd( aArray, { 'Assets', 'Asset/Depreciation Reports' } )
 aadd( aArray, { 'Values', 'Stock Values' }  )
 newchoice := Menugen( aArray, 4, 36, 'Item' )

 do case
 case newchoice = 2
  Heading( 'Print Stock file by Code' )
  Box_Save( 07, 02, 13, 78 )

  mtype = 'S'
  @ 08,05 say 'Print this listing by <I>tem Code, <S>erial no or <P>roduct code';
          get mtype pict '!' valid( mtype $ 'SPI')
  read

  mstatus = 'A'
  @ 10,05 say '<A>ll, <O>nhand, <C>lear Out, <T>heft, <W>rite off, <S>old, <R>epair' get mstatus;
          pict '!' valid( mstatus $ 'AOCTWSR' )
  read

  if mtype = 'P'
   mprod = 'ALL'
   @ 12, 05 say 'Specify product code' get mprod pict '!!!'
   read

  endif

  if Isready()

   if NetUse( "items" )

    do case
    case mtype = 'S'
     ordsetfocus( 'serial' )

    case mtype = 'I'
     ordsetfocus( 'item_code' )

    case mtype = 'P'
     ordsetfocus( 'prod_code' )

    endcase

   // Printcheck()
    // Pitch17()

    items->( dbgotop() )

    if mtype = 'P'

     aFlds := {}
     aadd( aflds, { 'items->prod_code', 'Product;Code', 10, 0, FALSE } )
     aadd( aflds, { 'items->item_code', 'Item;Code', 10, 0, FALSE } )
     aadd( aflds, { 'items->serial', 'Serial No', 10, 0, FALSE } )
     aadd( aflds, { 'items->model', 'Model', 15, 0, FALSE } )
     aadd( aflds, { 'items->desc', 'Description', 30, 0, FALSE } )
     aadd( aflds, { 'items->status', 'St', 2, 0, FALSE } )
     aadd( aflds, { 'items->owner_code', 'Owner;Code', 5, 0, FALSE } )
     aadd( aflds, { 'items->rent_tot', 'Rent;Total', 8, 2, FALSE } )
     aadd( aflds, { 'items->pay_made * items->month_pay', 'Payments;Total', 8, 2, FALSE } )
     aadd( aflds, { 'items->lease_term', 'Term', 4, 0, FALSE } )
     aadd( aflds, { 'items->lease_term - items->pay_made', 'Balance', 7, 0, FALSE } )

     Reporter( aFlds, ;
            'Stock Listing by Product Code',;
            'items->prod_code',;
            'Totals for Product Code : ' ,;
            '',;
            '',;
            FALSE,;
            '',;
            'if( mprod = "ALL", .t., items->prod_code = mprod ) .and. '+ ;
            'if( mstatus = "A", .t., items->status = mstatus )' ,;
            132 ;
             )

   //   report form stkprod to print noconsole while inkey() != K_ESC ;
   //          for if( mprod = 'ALL', TRUE, items->prod_code = mprod ) .and. ;
   //          if( mstatus = 'A', TRUE, items->status = mstatus ) noeject
    else

     aFlds := {}
     aadd( aflds, { 'items->item_code', 'Item;Code', 10, 0, FALSE } )
     aadd( aflds, { 'items->serial', 'Serial No', 10, 0, FALSE } )
     aadd( aflds, { 'items->model', 'Model', 15, 0, FALSE } )
     aadd( aflds, { 'items->desc', 'Description', 30, 0, FALSE } )
     aadd( aflds, { 'items->status', 'St', 2, 0, FALSE } )
     aadd( aflds, { 'items->owner_code', 'Owner;Code', 5, 0, FALSE } )
     aadd( aflds, { 'items->rent_tot', 'Rent;Total', 8, 2, FALSE } )
     aadd( aflds, { 'items->pay_made * items->month_pay', 'Payments;Total', 8, 2, FALSE } )
     aadd( aflds, { 'items->lease_term', 'Term', 4, 0, FALSE } )
     aadd( aflds, { 'items->lease_term - items->pay_made', 'Balance', 7, 0, FALSE } )

     Reporter( aFlds, ;
             ' Stock Listing by ' + if( mtype='I', 'Item Code', 'Serial Number' ),;
             '',;
             '',;
             '',;
             '',;
             FALSE,;
             '',;
             'if( mstatus = "A", .t., items->status = mstatus )',;
             132 ;
             )

     // report form stkser to print noconsole while inkey() != K_ESC ;
     //       for if( mstatus = 'A', TRUE, items->status = mstatus ) noeject

    endif

   endif

   // EndPrint()
   
   dbcloseall()

  endif

 case newchoice = 3
  Heading( 'Stock Location (Bailment) List' )
  Box_Save( 05,02,17,78 )
  mowner := space(3)
  @ 06,10 say 'Code of owner to print ' get mowner pict '@!'
  read

  mlist := 'P'
  @ 07,10 say 'List by <P>roduct code or <A>quisition date (P/A) ? ';
          get mlist pict '!' valid(mlist $ 'PA')
  read

  if NetUse( "owner" )

   if !owner->( dbseek( mowner ) ) 
    Error( 'Owner code not on file', 12 )

   else
    Highlight( 09, 10, 'Owner to print is ', owner->name )
    madvance := FALSE
    Centre( 11, 'The last month the count for this owner was advanced was ' ;
                + cmonth( owner->lastpay ) )
    @ 13,10 say 'Advance the Lease Payment Counter' get madvance pict 'Y'
    read
    if Isready()
     if NetUse( "hirer" )
      if NetUse( "items" )

       if madvance
        items->( dbgotop() )

        while !items->( eof() )
         if items->owner_code = mowner .and. items->pay_made < items->lease_term
          Rec_lock( 'items' )
          @ 16,10 say 'Incrementing count on Item ' + trim( items->desc )
          items->pay_made++
          items->pay_ytd += items->month_pay
          items->pay_tot += items->month_pay
          items->( dbrunlock() )
         endif
         items->( dbskip() )

        enddo

        Rec_lock( 'owner' )
        owner->lastpay := Bvars( B_SYSDATE )
        owner->( dbrunlock() )

       endif

       select items
       Centre( 15, "-=< Reindexing Items file - please wait >=-" )
       if mlist = 'P'
        indx( 'owner_code + prod_code' , 'temp' )

       else
        indx( 'owner_code + dtos( received )' , 'temp' )

       endif

       set relation to items->con_no into hirer

      // Printcheck()
       // Pitch17()

       items->( dbseek( mowner ) )

       aFlds := {}
       aadd( aflds, { 'items->item_code', 'Item;Code', 10, 0, FALSE } )
       aadd( aflds, { 'items->prod_code', 'Product;Code', 10, 0, FALSE } )
       aadd( aflds, { 'items->received', 'Date;Acquired', 8, 0, FALSE } )
       aadd( aflds, { 'items->serial', 'Serial No', 10, 0, FALSE } )
       aadd( aflds, { 'items->model', 'Model', 15, 0, FALSE } )
       aadd( aflds, { 'items->lease_term', 'Term', 4, 0, FALSE } )
       aadd( aflds, { 'items->lease_term - items->pay_made', 'Bal', 4, 0, FALSE } )
       aadd( aflds, { 'items->month_pay', 'Repayment', 10, 2, TRUE } )
       aadd( aflds, { 'if( items->status="H",hirer->surname,"In Stock")', 'Surname', 13, 0, FALSE } )
       aadd( aflds, { 'substr(trim(hirer->add1)+" "+trim(hirer->add2)+" "+trim(hirer->suburb),1,36)', 'Address', 13, 0, FALSE } )
       aadd( aflds, { 'hirer->pcode', '', 13, 0, FALSE } )


       Reporter( aFlds, ;
              'Stock Location (Bailment Listing)',;
              'owner->name',;
              '"Owner"' ,;
              '',;
              '',;
              FALSE,;
              '',;
              'items->owner_code = mowner',;
              132 ;
            )


       //report form stkloc to print noconsole while inkey() != K_ESC ;
       //      .and. items->owner_code = mowner noeject

       // Pitch10()
       // EndPrint()

       items->( orddestroy( 'temp' ) )

      endif
     endif
    endif
   endif
  endif

  dbcloseall() 

 case newchoice = 4
  Heading( 'Print stock payout report' )
  msort := 'I'
  Box_Save( 3, 10, 5, 70 )
  @ 4, 12 say 'Sort by <I>tem code or <O>wner code' get msort pict '!' ;
           valid( msort $ 'OI' )
  read
  if Isready()
   if NetUse( "owner" )
    if NetUse( "items" )

     if msort = 'I'
      indx( 'item_code', 'temp' )

     else
      indx( 'owner_code', 'temp' )

     endif

     set relation to items->owner_code into owner
     // Printcheck()
     // Pitch17()

     aFlds := {}
     aadd( aflds, { 'items->item_code', 'Item;Code', 10, 0, FALSE } )
     aadd( aflds, { 'items->serial', 'Serial No', 15, 0, FALSE } )
     aadd( aflds, { 'items->desc', 'Description', 30, 0, FALSE } )
     aadd( aflds, { 'owner->name', 'Owner Name', 10, 0, FALSE } )
     aadd( aflds, { 'int( items->rent_ytd )', 'Rent;YTD', 5, 0, FALSE } )
     aadd( aflds, { 'int( items->rent_tot )', 'Rent;Tot', 5, 0, FALSE } )
     aadd( aflds, { 'int( items->pay_ytd ) ', 'Pay.;YTD', 5, 0, FALSE } )
     aadd( aflds, { 'int( items->pay_tot ) ', 'Pay.;Total', 5, 0, FALSE } )
     aadd( aflds, { 'items->pay_out', 'Rule 78', 8, 2, TRUE } )

     if msort = 'O'

       Reporter( aFlds, ;
              ' Stock Payout Report',;
              'items->owner_code',;
              'Payout for Owner : ',;
              '',;
              '',;
              FALSE,;
              '',;
              '',;
              132 ;
            )

//      report form stkpay to print noconsole while inkey() != K_ESC noeject

     else

      Reporter( aFlds, ;
              ' Stock Payout Report',;
              '',;
              '',;
              '',;
              '',;
              FALSE,;
              '',;
              '',;
              132 ;
            )

//    report form stkpayi to print noconsole while inkey() != K_ESC noeject

     endif

     // Pitch10()
     // EndPrint()

     items->( orddestroy( 'temp' ) )

    endif
   endif
   dbcloseall()

  endif

 case newchoice = 5
#ifndef ASSETS
  Error( 'Asset package not activated', 12 )
#else
   if NetUse( "items" )
    indx( 'owner_code', 'temp' )
    Asset_use()
    mdate := DATE()
    Heading( "Depreciation Reports" )
    mscr := Box_Save( 07, 20, 09, 60 )
    @ 08,21 say 'Enter date for depreciation' get mdate
    read
    if Isready(13)
    //  Printcheck()
     Box_Save( 20, 35, 22, 45 )
     @ 21,36 SAY "Working"
     // Pitch17()
     SET CONSOLE OFF
     SET DEVICE TO PRINT
  * Select title & subtotal fields for depr. report
     sflag :=  FALSE
     sfield := "0"
     stitle := " "
     ssflag :=  FALSE
     ssfield := "0"
     sstitle := " "
     pglen := 55

     title := "Model"
     sflag := TRUE
     sfield := "Model"
     stitle := title

     svalue := model
     ssvalue := model
     pageno := 1

 *LOOP to print depr. report
     cntr := 0
     store 0 to sscost,sssalvage,sscurr,ssytd,ssaccum,scost,ssalvage,scurr,sytd,;
                saccum,tcost,tsalvage,tcurr,tytd,taccum
     store 0 to mcurr,mytd,maccum
     while !eof()

    * Top of page processing
      if cntr=0
       Fadphead( cntr, mdate )
       incr := 0
      endif
    *Print next database record
      @ cntr,  0 say item_code
      @ cntr,  8 say substr( desc, 1, 20 )
      @ cntr, 29 say serial
      @ cntr, 40 say model
 *     @ cntr, 49 say division
      @ cntr, 54 say serv_date
      @ cntr, 63 say cost
      @ cntr, 75 say salvage
      @ cntr, 89 say depr_mthd
      Fadepr(  mdate, mcurr, mytd, maccum )
      @ cntr, 92 say mcurr pict "99999999.99"
      @ cntr,104 say mytd pict "99999999.99"
      @ cntr,116 say maccum pict "99999999.99"
      cntr++
      incr := 1

   * Update subtotals & total
      tcost += cost
      tsalvage += salvage
      tcurr := tcurr+mcurr
      tytd := tytd+mytd
      taccum := taccum+maccum
      scost := scost+cost
      ssalvage := ssalvage+salvage
      scurr := scurr+mcurr
      sytd := sytd+mytd
      saccum := saccum+maccum
      sscost := sscost+cost
      sssalvage := sssalvage+salvage
      sscurr := sscurr+mcurr
      ssytd := ssytd+mytd
      ssaccum := ssaccum+maccum
      skip

  * Subtotal processing
      if sflag
       if svalue != model .or. eof()
        cntr := cntr+incr
        if cntr>pglen
         Fadpbot( pageno, cntr )
         Fadphead( cntr, mdate )
        endif
        @ cntr,  8 SAY "*** Subtotal for model : " + model
        @ cntr, 63 SAY scost     pict "99999999.99"
        @ cntr, 75 SAY ssalvage  pict "99999999.99"
        @ cntr, 92 SAY scurr     pict "99999999.99"
        @ cntr,104 SAY sytd      pict "99999999.99"
        @ cntr,116 SAY saccum    pict "99999999.99"
        store 0 to scost,ssalvage,scurr,sytd,saccum
        cntr := cntr+2
        incr := 0
       endif
       svalue := model
      endif

      if cntr>pglen
       Fadpbot( pageno, cntr )
       incr := 0
      endif

     enddo

     if cntr=0
      Fadphead( cntr, mdate )
      incr := 0
     endif

     @ cntr,  7 say "Grand Total"
     @ cntr, 63 say tcost      pict "99999999.99"
     @ cntr, 75 say tsalvage   pict "99999999.99"
     @ cntr, 92 say tcurr      pict "99999999.99"
     @ cntr,104 say tytd       pict "99999999.99"
     @ cntr,116 say taccum     pict "99999999.99"
  *  @ cntr,116 say tcost-tsalvage-taccum  pict "99999999.99"
     @ pglen+5, 59 say "Page"
     @ pglen+5, 64 say pageno
     eject

* Clean up & return
     // // Pitch10()
     set console on
     set print off
     set device to screen
     set deleted off
     items->( orddestroy( 'items' ) )
    endif
    close databases
   endif
#endif

 case newchoice = 6
  if NetUse( 'Items' )
   valonhand := 0
   valonrent := 0
   while !eof()
    if items->status = 'H'
     valonrent += items->cost
    else
     valonhand += items->cost
    endif
    skip
   enddo
   Box_Save( 7, 10, 10, 70 )
   Highlight( 8, 12, 'On Hand at Cost', Ns( valonhand ) )
   Highlight( 9, 12, 'On Rent at Cost', Ns( valonrent ) )
   Error( '', 12 )
  endif
  items->( dbclosearea() )

 case newchoice < 2
  return
 endcase
enddo
return

*

#ifdef ASSETS
proc fadpbot
@ pglen+5, 59 say "Page "
@ pglen+5, 64 say pageno pict "99"
pageno++
eject
cntr := 0
return

proc fadphead

******************************************************
* FADPHEAD  - Print title & heading for depr. report *
*             10/04/89                               *
******************************************************

PRIVATE i,j
@ 03,(126-LEN(TRIM(BVars( B_COMPANY ))))/2 SAY BVars( B_COMPANY )
@ 03,106 SAY "Report Date: " + DTOC(DATE())
@ 04, 49 SAY "Fixed Asset Tracking System"
@ 05,(101-LEN(title))/2 SAY "Depereciation Report by "+title
i := CMONTH(mdate)+" "+STR(YEAR(mdate))
@ 06,(126-len(i)-4)/2 SAY "For "+i
j := MAX(27,23+LEN(title))
@ 07,(126-j)/2 SAY REPLICATE("-",j)
@ 09,0 SAY " Asset                                                 ";
          +"In Serv.                        Depr  Curr Month         ";
          +"YTD Accumulated"
@ 10,0 SAY "  Id    Description                   Type  Loc  Div   ";
          +"Date           Cost     Salvage Meth        Depr        ";
          +"Depr        Depr"
@ 11,0 SAY "컴컴컴� 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 컴컴 컴컴 컴컴 컴컴컴컴 ";
          +"컴컴컴컴컴� 컴컴컴컴컴� 컴컴 컴컴컴컴컴� 컴컴컴컴컴� 컴컴컴컴컴�"
cntr := 12
return
#endif
