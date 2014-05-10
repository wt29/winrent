/*

 Rentals - Bluegum Software
 Module Eod - End of Day processing
 31/01/87 T. Glynn

       Last change:  TG   14 Mar 2011    2:33 pm
*/

#include "winrent.ch"

static batch_tot, page_no, head_str

Procedure EOD

local ok := FALSE
local tstr
local elapsed
local finish_time
local start_time
local eoyflag
local getlist := {}
local end_date
local tran_date
local null_date
local minext
local prev_bal
local maudit
#ifdef RENTACENTRE
local mseq
local aFlds
#endif

if NetUse( "items" )
 if NetUse( "arrears" )
  if NetUse( "tran" )
   if NetUse( "master" )
    ok := TRUE
   endif
  endif
 endif
endif

if ok

 Box_Save( 1, 1, 20, 78 )

 Center( 2, 'This Program will Calculate all Outstanding Arrears Amounts' )
 Center( 4, 'It will also advance the system date. Do not use this program unless the' )
 Center( 5, 'payments, contracts etc for this system date have been entered.' )

 Heading('End of Day')

 eoyflag := NO

 @ 07, 10 say 'Last end of day run was ' + dtoc( Bvars( B_SYSDATE ) )

 end_date := Bvars( B_SYSDATE )

 if Isready()

  @ 09, 10 say 'Enter ending date for eod run' get end_date
  read

  if end_date - Bvars( B_SYSDATE )  >= 7
   Center( 11, 'You are about to advance the system date more than 7 days' )

   if !Isready( )
    dbcloseall()
    return

   endif

  endif

  if end_date <= Bvars( B_SYSDATE ) 
   Error( 'An EOD has already been run for this date', 14 )
   dbcloseall()
   return

  endif

  maudit := NO
#ifndef RENTACENTRE
  @ 13, 10 say 'Audit arrears ?' get maudit pict 'Y'
  read
#endif
  tran_date := Bvars( B_SYSDATE ) 

  null_date := ctod('  /  /  ')

  start_time := seconds()

  while tran_date < end_date

   if maudit
    page_no := 1
    prev_bal := 0
    batch_tot := 0
    Arr_audit()
   endif

   @ 15, 2 say space( 75 )
   Center( 15, 'Processing for ' + dtoc( tran_date ) )

   master->( dbgotop() )

   while !master->( eof() )

    @ 17, 10 say 'Contract Number'
    @ 17, 26 say Ns( master->con_no )

#ifdef BYRNES
    if master->next_inst <= tran_date .and. !master->inquiry .and. tran_date <= master->enddate
#else
 #ifdef ARGYLE
    if master->next_inst <= tran_date .and. !master->inquiry .and. master->status != 'F'
 #else
    if master->next_inst <= tran_date .and. !master->inquiry
 #endif
#endif
     minext := Period( master->next_inst, 1, master->term_rent )
     prev_bal := master->bal_bf
     if val( str( master->bal_bf, 10, 2 ) ) - val( str( master->install, 10, 2 ) ) >= 0

      Add_rec( 'tran' )
      tran->con_no := master->con_no
      tran->type := 'Z'
      tran->value := master->install * -1
      tran->date := tran_date
      tran->( dbrunlock() )

     else

      Center( 18, 'Generating arrears for contract #' + Ns( master->con_no ) )
      Add_rec( 'arrears' )
      arrears->con_no := master->con_no
      arrears->paid := NO
      arrears->due := tran_date
      arrears->amount := master->install
      arrears->stat1 := null_date
      arrears->stat2 := null_date
      arrears->stat3 := null_date
      arrears->( dbrunlock() )

      Add_rec( 'tran' )
      tran->con_no := master->con_no
      tran->date := tran_date
      tran->value := master->install * -1
      tran->type := 'E'
      tran->( dbrunlock() )

     endif

     Rec_lock( 'master' )
     master->bal_bf -= master->install
     master->next_inst := minext
     master->( dbrunlock() )

     if maudit

      Arr_audit( prev_bal )

     endif

    endif

    master->( dbskip() )

   enddo

   if maudit

    set device to print
    @ prow() + 2, 10 say 'Batch total ' + str( batch_tot, 8, 2 )
    @ prow() + 1, 0 say head_str
    set device to screen
    eject

   endif

   tran_date++

  enddo

#ifdef RENTACENTRE

   if NetUse( "audit", EXCLUSIVE, 10 )
    indx( 'code + dep_no', 'code' )

    do while TRUE
     audit->( dbgotop() )

     mseq := Sysinc( 'audit_seq', 'I' )

     aFlds := {}
     aadd( aflds, { 'transform( audit->con_no, "9999999" )', 'Contract;Number', 11, 0, FALSE } )
     aadd( aflds, { 'audit->amt', 'Amount', 10, 2, TRUE } )
     aadd( aflds, { 'audit->date', 'Date', 8, 0, FALSE } )
     aadd( aflds, { 'audit->machine', 'Item Code', 10, 0, FALSE } )
     aadd( aflds, { 'substr(audit->comments, 1, 20)', 'Comments', 21, 0, FALSE } )
     aadd( aflds, { 'audit->name', 'Customer Name', 20, 0, FALSE } )
     aadd( aflds, { 'audit->dep_no', 'Deposit', 8, 0, FALSE } )
     aadd( aflds, { 'audit->opercode', 'Operator', 10, 0, FALSE } )


     Reporter( aFlds,    ;
               BVars( B_COMPANY ) + ' Audit Trail - Sequence '+ Ns( mseq ),;
               'tran_type(audit->code)',;
               '"Transaction Type "+tran_type(audit->code)' ,;
               '',       ;
               '',       ;
               FALSE,    ;
               'audit->code != "Z"',;
               '',       ;
               80,       ;
               FALSE     ;   // Don't allow print to screen
             )

     if IsReady( 12, 10, "Has the Audit Trail Printed OK" )
      exit    // Out of the loop

     endif

    enddo

    zap
    dbclosearea()
    Kill( 'audit' + ordbagext() )

   endif

#endif

  finish_time = seconds()
  if finish_time < start_time
   elapsed:=(86399-finish_time)+start_time

  else
   elapsed:=finish_time-start_time

  endif

  if elapsed > 60
   tstr := "Time for eod run = " + str( elapsed/60, 2 ) + " minutes " + ;
        str( elapsed % 60 , 2 ) + "  seconds "

  else
   tstr := "Time for eod run = " + str( elapsed % 60 ,2 )+"  seconds "

  endif

  Bvars( B_SYSDATE, end_date )
  Oddvars( SYSDATE, end_date )
  BvarSave()

  Error( tstr, 19 )

 endif

endif
dbcloseall()
return

*

Procedure EOM

local arr_date := Oddvars( SYSDATE ) - 1000
local tran_date := Oddvars( SYSDATE ) - 1000
local getlist := {}

if NetUse( "arrears", EXCLUSIVE )
 if NetUse( "tran", EXCLUSIVE )

  Heading('Eom procedure')
  Box_Save( 3, 2, 9, 78 )
  Center( 4, 'This program will allow you to clear old transaction and arrears details' )
  @ 06, 12 say '     Last date for arrears' get arr_date
  @ 07, 12 say 'Last date for transactions' get tran_date
  read

  if Isready( 12 )

   select arrears
   delete for arrears->date_paid <= arr_date .and. arrears->paid .and. ! empty( arrears->date_paid )
   select tran
   delete for tran->date <= tran_date

  endif

 endif

endif

dbcloseall()
return

*

Procedure EOY

Heading( "Run end of Year procedure" )

if NetUse( "items", EXCLUSIVE, 10 )
 Box_Save( 03, 03, 09, 76 )
 Center( 04, 'End of Year Requested' )
 Center( 06, 'This program will zero the year to date rentals and payments in the' )
 Center( 07, 'item file. If you wish to print these details first then answer "N".' )

 if Isready( 10 )
  replace all items->rent_ytd with 0, ;
              items->pay_ytd with 0
 endif

endif

dbcloseall()
return

*

Procedure EOMRepTot

local nst_cont, nst_rent, nst_mach, nst_arr, mscr, mrow := 6
local ncont_t:=0, nrent_t:=0, nmach_t:=0, narr_t:=0
local nForeCast, nForeCast_t:=0

#ifdef BYRNES
local DateDiff
local cStatus := 'A'
local sPassword

#endif
local getlist := {}

#ifdef MULTI_SITE
local msite, sLongSite
#endif

if NetUse( "items" )
 items->( ordsetfocus( 'contract' ) )

 if NetUse( 'master' )
  set relation to master->con_no into items

  Heading( "Calculate revenue totals" )
#ifdef BYRNES
  mscr := Box_Save( 03, 03, 05, 75 )
  sPassword := space( 10 )
  sPassWord := GetSecret( sPassword, 04, 05, .T., "Enter password for report ")
  if upper( trim( sPassword ) ) != upper( BYRNES_PWD )
   Error( "Password incorrect", 12 )

  else
   mscr := Box_Save( 03, 03, 05, 75 )
   @ 4, 45 say "'*' = All Status"
   @ 4, 05 say 'Calculate for contracts with status' get cStatus pict '@!' valid ( cStatus = '*' .or. dup_chk( cStatus, 'status' )  )
   read

#endif

   mscr := Box_Save( 03, 03, maxrow()-1, 75 )
   @ 4, 18 say 'Contracts'
   @ 4, 32 say 'Arrears'
   @ 4, 40 say 'Revenue/Mth'
   @ 4, 53 say 'Items'

#ifdef BYRNES
   @ 4, 66 say 'Forecast'

#endif
   select master
 #ifdef MULTI_SITE
   @ 4, 05 say 'Site Name'
   ordsetfocus( 'site' )
 #endif

   @ 05, 04 say replicate( chr( 196 ), 70 )

   master->( dbgotop() )
   while !master->( eof() ) .and. Pinwheel( TRUE )
 #ifdef MULTI_SITE
    msite := master->site
    sLongSite := lookitup( 'sites', master->site )
    @ mrow, 04 say substr( if( len( trim( sLongSite ) ) > 0, sLongSite, mSite ), 1, 15 )

 #endif
    nst_arr := 0
    nst_rent := 0
    nst_mach := 0
    nst_cont := 0
    nForeCast := 0

 #ifdef MULTI_SITE
    while master->site = msite .and. !master->( eof() ) .and. Pinwheel( TRUE )

 #else
    while !master->( eof() ) .and. Pinwheel( TRUE )

 #endif

 #ifdef BYRNES
     if !master->inquiry .and. ( master->status = cStatus .or. cStatus = '*' )

 #else
     if !master->inquiry

 #endif
      if master->con_no > 0
       if master->bal_bf < 0
        nst_arr += master->bal_bf

       endif

       do case
       case master->term_rent = "M"
        nst_rent += master->install

       case master->term_rent = "F"
        nst_rent += ( ( master->install * 26 ) / 12 )

       case master->term_rent = "W"
        nst_rent += ( ( master->install * 52 ) / 12 )

       case master->term_rent = "D"
        nst_rent += ( ( master->install * 365 ) / 12 )

       endcase

 #ifdef BYRNES
       if abs( master->install ) > 1000
        error( "Contract #" + ns( master->con_no ) + " has an install of $" + Ns( master->install, 8, 2 ), 15 )

       endif

       if empty( master->Enddate )
         Error( "Contract #" + ns( master->con_no ) + " has no Contract End Date - totals will be invalid", 15 )

       endif

       dateDiff := int( master->EndDate - Bvars( B_SYSDATE )  )
       nforecast += ( master->install * ( datediff / 30.41 )  )
 #endif
       while items->con_no = master->con_no .and. !items->( eof() )
        nst_mach += 1
        items->( dbskip() )

       enddo
       nst_cont++

      endif

     endif
     master->( dbskip() )

    enddo
    @ mrow, 20 say nst_cont pict '9999999'
    @ mrow, 28 say nst_arr pict '99999999.99'
    @ mrow, 41 say nst_rent pict '9999999.99'
    @ mrow, 52 say nst_mach pict '999999'
#ifdef BYRNES
    @ mrow, 62 say nForeCast pict "999999999.99"
#endif
    mrow++

    ncont_t += nst_cont
    narr_t += nst_arr
    nrent_t += nst_rent
    nmach_t += nst_mach
    nForeCast_t += nForeCast

   enddo

   @ mrow, 04 say replicate( ULINE, 70 )

   mrow++
   @ mrow, 20 say ncont_t pict '9999999'
   @ mrow, 28 say narr_t pict '99999999.99'
   @ mrow, 41 say nrent_t pict '9999999.99'
   @ mrow, 52 say nmach_t pict '999999'
 #ifdef BYRNES
   @ mrow, 62 say nForeCast_t pict "999999999.99"
 #endif
   Error( "Calculation Finished" )
 #ifdef BYRNES
   endif   // Password
 #endif
   dbcloseall()

  endif

 endif

return

*

Procedure EOMRepProd

local p_onhire, p_onhand, p_hirerev
local t_onhire := 0, t_onhand := 0, t_hirerev := 0
local mprod, mrow, mscr

if NetUse( "items" )

 items->( ordsetfocus( 'prod_code' ) )

 Heading( "Calculate revenue totals by Product Code" )
 mscr := Box_Save( 03, 08, 23, 72 )
 mrow := 5
 @ 4, 10 say 'Prod Code         On Hire      On Hand   Hired Revenue/Mth'

 mprod := items->prod_code

 items->( dbgotop() )
 while !items->( eof() )

  p_onhand := 0
  p_onhire := 0
  p_hirerev := 0

  while items->prod_code = mprod .and. !items->( eof() )
   if items->status != 'H'
    p_onhand++

   else
    p_onhire++
    p_hirerev += items->m_rent

   endif

   items->( dbskip() )

  enddo
  mprod := items->prod_code

  @ mrow, 10 say mprod
  @ mrow, 28 say p_onhire pict '9999999'
  @ mrow, 41 say p_onhand pict '9999999'
  @ mrow, 58 say p_hirerev pict '999999.99'
  mrow++

  t_onhire += p_onhire
  t_onhand += p_onhand
  t_hirerev += p_hirerev

  if mrow = 22
   Error( 'More' )
   mrow := 5

  endif

 enddo

 @ 22, 10 say replicate( '=', 58 )
 @ 23, 28 say t_onhire pict '9999999'
 @ 23, 41 say t_onhand pict '9999999'
 @ 23, 58 say t_hirerev pict '999999.99'

 Error( "Calculation Finished" )

 dbcloseall()
endif
return

*

procedure arr_audit ( prev_bal )

local cent_space, oPrinter := PrintCheck( "Arrears Audit" )

default page_no to 1

if oPrinter:prow() >= 60 .or. oPrinter:prow() < 2
 cent_space = space( 28-( len( BVars( B_COMPANY ) + ' Audit trail ')/ 2 ) )
 head_str = 'Page no . ' + Ns(page_no,3) + cent_space + BVars( B_COMPANY ) + ;
            ' Audit Trail ' + cent_space + dtoc( Oddvars( SYSDATE ) )
 if oPrinter:prow() >= 60
  oPrinter:NewLine()
  oPrinter:TextOut( head_str )
  oPrinter:NewPage()

 endif
 oPrinter:NewLine()
 oPrinter:TextOut( head_str )
 oPrinter:NewLine()
 oPrinter:TextOut( 'Contract #   Type        Previous       New     Value' )
 oPrinter:NewLine()
 oPrinter:TextOut( replicate( ULINE, 55 ) )
 page_no++

else
 oPrinter:NewLine()
 oPrinter:TextOut( transform( master->con_no, CON_NO_PICT ) )
 oPrinter:SetPos( 08 * oPrinter:CharWidth )
 oPrinter:TextOut( left( Tran_type( tran->type ), 15 ) )
 oPrinter:SetPos( 08 * oPrinter:CharWidth )
 oPrinter:TextOut( transform( prev_bal, CURRENCY_PICT ) )
 oPrinter:SetPos( 08 * oPrinter:CharWidth )
 oPrinter:TextOut( transform( prev_bal, CURRENCY_PICT ) )
 oPrinter:SetPos( 08 * oPrinter:CharWidth )
 oPrinter:TextOut( transform( tran->val, CURRENCY_PICT ) )
 batch_tot += tran->value

endif
oPrinter:EndDoc()
oPrinter:Destroy()
return
