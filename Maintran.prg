/*

  Rental - Bluegum Software
  
  Module Trpay - Transaction Payments
  
  11/09/86 Tony Glynn

  Last change:  TG   17 May 2001    8:21 am

      Last change:  TG   14 Feb 2011   10:50 pm
*/

#include "winrent.ch"

Function Trpay

local ok := FALSE
local getlist := {}
local minsure
#ifdef INSURANCE
local minstot
#endif
local mpayment
local mcomment
local mpercent
// local mamt
local cPayMethod
local dPaidTo
local nBalBF

if NetUse( "arrears" )
 if NetUse( "tran" )
  if NetUse( "items" )
   items->( ordsetfocus( 'contract' ) )
   if NetUse( "hirer" )
    if NetUse( "master" )
     set relation to master->con_no into items,;
                  to master->con_no into hirer,;
                  to master->con_no into tran,;
                  to master->con_no into arrears
     ok := TRUE
    endif
   endif
  endif
 endif
endif
while ok

 if !Con_find()
  dbcloseall()
  return nil

 endif
 cls

 Heading( 'Payment on Contract ' + Ns( Oddvars( CONTRACT ) ) )
 Highlight( 02, 05, 'Hirer name ', trim( hirer->first ) + ' ' + hirer->surname )
 Highlight( 04, 05, 'Address    ', hirer->add1 )
 Highlight( 05, 05, 'Suburb     ', hirer->suburb )
 Highlight( 06, 05, 'Telephone  ', hirer->tele_priv )
 Highlight( 07, 05, '           ', hirer->tele_empl )
#ifdef RENTACENTRE
 Highlight( 08, 05, 'Deposit Book #', master->dep_no )
#endif
 Highlight( 09, 05, 'Rental period is' , perdesc( master->term_rent ) )
 Highlight( 10, 05, 'Instalment value' , Ns( master->install, 8, 2 ) )

#ifdef INSURANCE

 minsure := 0
 minstot := 0
 if master->insurance

  items->( dbseek( Oddvars( CONTRACT ) ) )

  while items->con_no = Oddvars( CONTRACT ) .and. !items->( eof() )

   minsure += items->insurance
   items->( dbskip() )

  enddo
  minstot := minsure

 endif
 Highlight( 11, 05, '   Insurance Due', Ns( minsure, 8, 2 ) )

#endif

 Highlight( 12, 05, '    Date paid to', dtoc( master->paid_to ) )
 Highlight( 13, 05, ' Account balance', Ns( master->bal_bf, 8, 2 ) )

 mpayment := 0
 minsure := 0
 mcomment := space(20)
 cPayMethod := 'C'

 @ 14,05 say 'Amount of payment' get mpayment pict '99999.99'
 @ 15,05 say 'Comment' get mcomment


#ifdef INSURANCE
 @ 16,05 say '   Insurance Paid' get minsure pict '99999.99'
#endif

 Tran_disp( master->con_no )

 if master->inquiry
  Error( 'Contract is enquiry only', 12 )
  clear gets
  loop

 endif
 read

 if mpayment > 0

#ifdef RENTACENTRE
  Audit( Oddvars( CONTRACT ), RENTAL_PAYMENT, mpayment, mcomment )

#endif
  select master
  dbseek( Oddvars( CONTRACT ) )

  dPaidTo := Period( master->paid_to, int( mpayment / master->install ), master->term_rent )
  nBalBF := master->bal_bf + mPayment

  Highlight( 19, 05, 'Account balance      ', Ns( nBalBf, 8, 2 ) )

#ifdef BYRNES
  @ 18, 05 say 'Contract paid to     ' get dPaidto
  read

#else
  Highlight( 18, 05, 'Contract paid to     ', dtoc( dPaidTo ) )
  Error( '' )

#endif

  Rec_lock( 'master' )

  master->paid_to := dPaidTo
  master->bal_bf := nBalBF

  master->( dbrunlock() )

  Add_rec( 'tran' )
  tran->con_no := master->con_no
  tran->type := RENTAL_PAYMENT
  tran->value := mpayment
  tran->date := Oddvars( SYSDATE )
  tran->narrative := mcomment
  tran->gst := GSTPaid( mPayment )

#ifdef INSURANCE
  tran->insurance := minsure
#endif

  tran->( dbrunlock() )

  Tran_audit( mpayment )

  items->( dbseek( Oddvars( CONTRACT ) ) )
  while items->con_no = Oddvars( CONTRACT ) .and. !items->( eof() )

#ifdef INSURANCE
   mpercent := items->( fieldget( items->( fieldpos( master->term_rent+'_rent' ) ) ) ) * ;
               int( mpayment / ( master->install - minstot ) )
#else
   mpercent := items->( fieldget( items->( fieldpos( master->term_rent + '_rent' ) ) ) )* ;
               int( mpayment / master->install )
#endif
   Rec_lock( 'items' )
   items->rent_ytd += mpercent
   items->rent_tot += mpercent
   items->( dbrunlock() )
   items->( dbskip() )

  enddo

  while arrears->con_no = Oddvars( CONTRACT ) .and. !arrears->( eof() ) .and. mpayment > 0
   if !arrears->paid
    if mpayment >= ( arrears->amount - arrears->amt_paid )
     mpayment -= arrears->amount - arrears->amt_paid
     Rec_lock( 'arrears' )
     arrears->amt_paid := arrears->amount
     arrears->date_paid := Oddvars( SYSDATE )
     arrears->paid := TRUE
     arrears->( dbrunlock() )

    else
     Rec_lock( 'arrears' )
     arrears->amt_paid += mpayment
     arrears->( dbrunlock()  )
     mpayment := 0

    endif

   endif
   arrears->( dbskip() )

  enddo

 endif
enddo
dbcloseall()
return nil

*

Function TrCredit

local ok := FALSE
local getlist := {}
local mpayment
local mreason

if NetUse( "arrears" )
 if NetUse( "tran" )
  if NetUse( "hirer" )
   if NetUse( "master" )
    set relation to master->con_no into hirer,;
                 to master->con_no into tran,;
                 to master->con_no into arrears
    ok := TRUE
   endif
  endif
 endif
endif
while ok

 if !Con_find()
  dbcloseall()
  return nil

 endif

 master->( dbseek( Oddvars( CONTRACT ) ) )
 cls
 Heading( 'Credit Adjustment on Contract #' + Ns( Oddvars( CONTRACT ) ) )
 Highlight( 03, 03, '      Hirer name', trim( hirer->first ) + ' ' + hirer->surname )
 Highlight( 05, 03, '         Address', hirer->add1 )
 Highlight( 06, 03, '          Suburb', hirer->suburb )
 Highlight( 08, 03, 'Rental period is', perdesc( master->term_rent ) )
 Highlight( 10, 03, 'Instalment value', Ns( master->install, 8, 2 ) )
 Highlight( 12, 03, '    Date paid to', dtoc( master->paid_to ) )
 Highlight( 14, 03, ' Account balance', Ns( master->bal_bf, 8, 2 ) )
 mpayment := 0
 mreason := space(20)
 @ 15,03 say 'Amount of Credit' get mpayment pict '99999.99'
 @ 16,03 say '          Reason' get mreason
 Tran_disp( master->con_no )
 read
 if mpayment > 0 .and. lastkey() != K_ESC

#ifdef RENTACENTRE
  Audit( Oddvars( CONTRACT ), MISC_CREDIT, mpayment, mreason )
#endif

  Highlight( 18, 07 , 'Account balance' , str( master->bal_bf + mpayment,8,2) )
  Error( '' )

  Rec_lock( 'master' )
  master->bal_bf += mpayment
  master->( dbrunlock()  )

  Add_rec( 'tran' )
  tran->con_no := master->con_no
  tran->type := MISC_CREDIT
  tran->narrative := mreason
  tran->value := mpayment
  tran->date := Oddvars( SYSDATE )
#ifdef MEDI
  tran->gst := if( master->TaxFree, 0, GSTPaid( mPayment ) )
#else
  tran->gst := GSTPaid( mPayment )
#endif
  tran->( dbrunlock() )

  Tran_audit( mpayment )

  while arrears->con_no = Oddvars( CONTRACT ) .and. !eof() .and. mpayment > 0
   if !arrears->paid
    if mpayment >= ( arrears->amount - arrears->amt_paid )
     mpayment -= ( arrears->amount - arrears->amt_paid )

     Rec_lock( 'arrears' )
     arrears->amt_paid := arrears->amount
     arrears->date_paid := Oddvars( SYSDATE )
     arrears->paid := TRUE
     arrears->( dbrunlock() )
    else

     Rec_lock( 'arrears' )
     arrears->amt_paid += mpayment
     arrears->( dbrunlock() )
     mpayment = 0

    endif
   endif
   arrears->( dbskip() )

  enddo

  if Isready( 'Change paid to date' )
   Rec_lock( 'master' )
   @ 20,01 say space(35)
   @ 20,05 say 'Date paid to          ' get master->paid_to
   @ 22,05 say 'Date next install due ' get master->next_inst
   read
   master->( dbrunlock() )
  endif

 endif

enddo
dbcloseall()
return nil

*

Function TrDebit

local ok := FALSE,newbal
local getlist := {}
local mpayment
local mreason

if NetUse( "tran" )
 if NetUse( "hirer" )
  if NetUse( "master" )
   set relation to master->con_no into hirer
   ok := TRUE
  endif
 endif
endif

while ok
 if !Con_find()
  dbcloseall()
  return nil
 endif
 select master
 seek Oddvars( CONTRACT )
 cls
 Heading( 'Debit contract ' + Ns( Oddvars( CONTRACT ) ) )
 Highlight( 03, 03, '      Hirer name', trim( hirer->first ) + ' ' + hirer->surname )
 Highlight( 05, 03, '         Address', hirer->add1 )
 Highlight( 06, 03, '          Suburb', hirer->suburb )
 Highlight( 08, 03, 'Rental period is', perdesc( master->term_rent ) )
 Highlight( 09, 03, 'Instalment value', Ns( master->install,8,2 ) )
 Highlight( 12, 03, '    Date paid to', dtoc( master->paid_to ) )
 Highlight( 13, 03, ' Account balance', Ns( master->bal_bf,8,2 ) )
 mpayment := 0
 mreason := space(20)
 @ 15,03 say 'Amount of debit' get mpayment pict '99999.99'
 @ 16,03 say '         Reason' get mreason
 Tran_disp( master->con_no )
 read
 if mpayment > 0  .and. lastkey() != K_ESC
#ifdef RENTACENTRE
  Audit( Oddvars( CONTRACT ), MISC_DEBIT, mpayment, mreason )
#endif
  select master
  seek Oddvars( CONTRACT )
  mpayment = mpayment * -1
  newbal := master->bal_bf + mpayment
  Highlight( 18,05, 'Account balance',Ns(newbal,8,2) )
  Error( '' )

  Rec_lock( 'master' )
  master->bal_bf += mpayment
  master->( dbrunlock()  )

  Add_rec( 'tran' )
  tran->con_no := master->con_no
  tran->type := MISC_DEBIT
  tran->narrative := mreason
  tran->value := mpayment
  tran->date := Oddvars( SYSDATE )

#ifdef MEDI
  tran->gst := if( master->TaxFree, 0, GSTPaid( mPayment ) )
#else
  tran->gst := GSTPaid( mPayment )
#endif

  tran->( dbrunlock() )

  Tran_audit( mpayment )

  select master
  if Isready( 'Change paid to date' )
   Rec_lock( 'master' )
   @ 20,01 say space(35)
   @ 20,05 say 'Date paid to          ' get master->paid_to
   @ 22,05 say 'Date next install due ' get master->next_inst
   read
   master->( dbrunlock() )
  endif

 endif
enddo

dbcloseall()
return nil

*

function Trbond

local ok := FALSE
local getlist := {}
local mpayment
local mbonddate

if NetUse( "tran" )
 if NetUse( "hirer" )
  if NetUse( "master" )
   set relation to master->con_no into hirer,;
                to master->con_no into tran
   ok := TRUE
  endif
 endif
endif

while TRUE

 if !Con_find( Oddvars( CONTRACT ) )
  dbcloseall()
  return nil
 endif

 master->( dbseek( Oddvars( CONTRACT ) ) )

 cls
 Heading( 'Bond receipt' )
 Highlight( 03, 05, 'Hirer name ', trim(hirer->first) + ' ' + hirer->surname )
 Highlight( 05, 05, 'Address    ', hirer->add1 )
 Highlight( 06, 05, 'Suburb     ', hirer->suburb )
 Highlight( 08, 05, 'Rental period is ', perdesc( master->term_rent ) )
 Highlight( 10, 05, 'Instalment value  ', str( master->install, 8, 2 ) )
 Highlight( 12, 05, 'Date paid to      ', dtoc( master->paid_to ) )
 Highlight( 14, 05, 'Account Balance   ', str( master->bal_bf, 8, 2 ) )
 Highlight( 16, 05, 'Bond paid         ', str( master->bond_paid, 8, 2 ) )
 mpayment := 0
 mbonddate := Oddvars( SYSDATE )

 @ 17,05 say 'Date paid         ' get mbonddate
 @ 18,05 say 'Amount of receipt ' get mpayment pict '99999.99'

 Tran_disp( master->con_no )
 read

 if mpayment != 0

#ifdef RENTACENTRE
  Audit( Oddvars( CONTRACT ), BOND_PAYMENT, mpayment )
#endif

  Add_rec( 'tran' )
  tran->con_no := Oddvars( CONTRACT )
  tran->type := BOND_PAYMENT
  tran->value := mpayment
  tran->date := Oddvars( SYSDATE )

#ifdef MEDI
  tran->gst := if( master->TaxFree, 0, GSTPaid( mPayment ) )
#else
  tran->gst := GSTPaid( mPayment )
#endif

  tran->( dbrunlock() )

  Tran_audit( mpayment )

  Rec_lock( 'master' )
  master->bond_paid += mpayment
  master->bond_date := mbonddate
  master->( dbrunlock() )

 endif

enddo
dbcloseall()
return nil

*

Procedure TrRet

local ok := FALSE
local getlist := {}
local mpayment

if NetUse( "tran" )
 if NetUse( "hirer" )
  if NetUse( "master" )
   set relation to master->con_no into hirer,;
                to master->con_no into tran
   ok := TRUE
  endif
 endif
endif

while ok

 if !Con_find()
  dbcloseall()
  return
 endif

 master->( dbseek( Oddvars( CONTRACT ) ) )
 
 cls
 Heading('Bond Returns')
 Highlight( 03, 05, 'Hirer name ', trim( hirer->first ) + ' ' + hirer->surname )
 Highlight( 05, 05, 'Address    ', hirer->add1 )
 Highlight( 06, 05, 'Suburb     ', hirer->suburb )
 Highlight( 08, 05, 'Rental period is ', perdesc( master->term_rent ) )
 Highlight( 10, 05, 'Instalment value  ', str( master->install, 8, 2 ) )
 Highlight( 12, 05, 'Date paid to      ', dtoc( master->paid_to ) )
 Highlight( 14, 05, 'Account balance   ', str( master->bal_bf, 8, 2 ) )
 Highlight( 16, 05, 'Bond paid         ', str( master->bond_paid, 8, 2 ) )

 mpayment := 0
 @ 18,05 say 'Amount of return ' get mpayment pict '99999.99'
 Tran_disp( master->con_no )
 read

 if mpayment != 0
#ifdef RENTACENTRE
  Audit( Oddvars( CONTRACT ), BOND_REFUND, mpayment )
#endif
  mpayment = mpayment * -1

  Add_rec( 'tran' )
  tran->con_no := Oddvars( CONTRACT )
  tran->type := BOND_REFUND
  tran->value := mpayment
  tran->date := Oddvars( SYSDATE )

#ifdef MEDI
  tran->gst := if( master->TaxFree, 0, GSTPaid( mPayment ) )
#else
  tran->gst := GSTPaid( mPayment )
#endif

  tran->( dbrunlock() )

  Tran_audit( mpayment )

  Rec_lock( 'master' )
  master->bond_paid += mpayment
  master->( dbrunlock() )

 endif
enddo
dbcloseall()
return

*

function TrDel

local ok := TRUE
local getlist := {}
local mpayment
local mreason

if NetUse( "tran" )
 if NetUse( "hirer" )
  if NetUse( "master" )
   set relation to master->con_no into hirer,;
                to master->con_no into tran
   ok := TRUE
  endif
 endif
endif

while ok

 if !Con_find()
  dbcloseall()
  return nil
 endif

 master->( dbseek( Oddvars( CONTRACT ) ) )

 cls
 Heading( 'Delivery Fee on Contract #' + Ns( Oddvars( CONTRACT ) ) )
 Highlight( 03, 05, 'Hirer Name ' ,trim( hirer->first ) + ' ' + hirer->surname )
 Highlight( 05, 05, 'Address    ' , hirer->add1 )
 Highlight( 06, 05, 'Suburb     ' , hirer->suburb )
 Highlight( 08, 05, 'Rental Period is ' , perdesc( master->term_rent ) )
 Highlight( 10, 05, 'Instalment Value ' , str( master->install, 8, 2 ) )
 Highlight( 12, 05, 'Date Paid to     ' , dtoc( master->paid_to ) )
 Highlight( 14, 05, 'Account Balance  ' , str( master->bal_bf, 8, 2 ) )
 mpayment := 0
 mreason := space(20)
 @ 15,05 SAY 'Amount of Fee       ' get mpayment pict '99999.99'
 @ 16,05 SAY 'Reason              ' get mreason
 Tran_disp( master->con_no )

 if master->inquiry
  Error('Contract is enquiry only',12)
  clear gets
  loop

 endif
 read

 if mpayment > 0 .and. lastkey() != K_ESC

  mpayment := mpayment * -1

  Audit( Oddvars( CONTRACT ), DELIVERY_FEE, mpayment, mreason)

  Highlight( 18,10, 'Account Balance    ', str( master->bal_bf + mpayment, 8, 2 ) )

  Error('')

  Rec_lock( 'master' )
  master->bal_bf += mpayment
  master->( dbrunlock() )

  Add_rec( 'tran' )
  tran->con_no := master->con_no
  tran->type := DELIVERY_FEE
  tran->narrative := mreason
  tran->value :=  mpayment
  tran->date := Oddvars( SYSDATE )

#ifdef MEDI
  tran->gst := if( master->TaxFree, 0, GSTPaid( mPayment ) )
#else
  tran->gst := GSTPaid( mPayment )
#endif

  tran->( dbrunlock() )

  Tran_audit( mpayment )

 endif
enddo
dbcloseall()
return nil

*

function tran_audit ( value, new_run )

local oPrinter := Oddvars( AUDITPTR )  // Should get the previously stored printer object
static page_no := 1

default new_run to FALSE

if new_run
 page_no := 1

endif

if Oddvars( TRAN_AUDIT )
 if oPrinter:prow() >= 60 .or. new_run
  if oPrinter:prow() > 55
   oPrinter:newpage()

  endif

  oPrinter:NewLine()
  oPrinter:textout( 'Page ' + Ns( page_no ) )
  oPrinter:SetPos( 32 * oPrinter:CharWidth )
  oPrinter:textout( 'Audit Listing' )
  oPrinter:SetPos( 72 * oPrinter:CharWidth )
  oPrinter:textout( dtoc( date() ) )
  oPrinter:NewLine()
  oPrinter:textout( 'Con#   Surname        Reason           Comments            Credit    Debit' )
  oPrinter:NewLine()
  oPrinter:textout( replicate( '-', 80 ) )
//  oPrinter:line( oPrinter:posx, oPrinter:posY, oPrinter:posx+(oPrinter:CharWidth * 80), oPrinter:PosY  )
  page_no++

 endif

 if value != 0
  oPrinter:newLine()
  oPrinter:Setpos( 0 )
  oPrinter:textout( transform( master->con_no, CON_NO_PICT ) )
  oPrinter:SetPos( 11 * oPrinter:CharWidth() )
  oPrinter:TextOut( left(hirer->surname, 15 ) )
  oPrinter:SetPos( 26 * oPrinter:CharWidth() )
  oPrinter:TextOut( left(tran_type( tran->type ), 15 ) )
  oPrinter:SetPos( 42 * oPrinter:CharWidth() )
  oPrinter:TextOut( left(tran->narrative, 39 ) )
  if value >= 0
   oPrinter:SetPos( 63 * oPrinter:CharWidth() )

  else
   oPrinter:SetPos( 73 * oPrinter:CharWidth() )

  endif

  oPrinter:TextOut( transform( tran->value, '99999.99' ) )

  Oddvars( BATCH_TOT, Oddvars( BATCH_TOT ) + value )

 endif

endif

return nil
