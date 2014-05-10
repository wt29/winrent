/*

 Rental System - Bluegum Software
 Module MainCont - Contract Maintenance

 17/12/86 T. Glynn

      Last change:  TG   26 Jan 2012    6:42 pm
*/

#include "winrent.ch"

Function MainCont
local aArray, fchoice

while TRUE
 Heading('File Maintenance')
 aArray := {}
 aadd( aArray, { 'File', 'Return to File Menu' } )
 aadd( aArray, { 'Add', 'Add New Contracts', { || ConAdd() }, X_ADDFILES } )
 aadd( aArray, { 'Change', 'Change Contract Detail', { || ConEdit() }, X_EDITFILES } )
 aadd( aArray, { 'Delete', 'Delete Contracts', { || ConDel() }, X_DELFILES } )
 fchoice := MenuGen( aArray, 3, 13, 'Contract' )

 if fchoice < 2
  exit

 else
  if Secure( aArray[ fchoice, 4 ] )
   Eval( aArray[ fchoice, 3 ] )

  endif

endif

enddo
return nil

*

procedure conadd

local ok := FALSE, start_con := 0, hirers, mloop, temp_num, getlist := {}
local mloop2, row, mname, mskey, minsure, items_added, newloop, mmonth , mperiod
local mdate, mdate2, mstr, mitem, mscr, mrent, mtrent, madd
local mdep , minstall , mgrace, mcom1, mcom2, marea, mcomm, mdep_no, mterm
local mbank, msite, okf10, oldord
local oldscr := Box_Save()
local dEndDate


#ifndef RENTACENTRE
local mPay, mType
#endif

#ifdef MEDI
local mponum, mfirst
#endif

#ifdef INSURANCE
local nInsAmt, sTotInsure
#endif

#ifdef CREDIT_CARD
local sCardNum, mcardexp, mcardid
#endif

local lgst := TRUE


if NetUse( "tran" )
 if NetUse( "items" )
  if NetUse( "hirer"  )
   if NetUse( "master" )
    ok := YES
   endif
  endif
 endif
endif

while ok

 hirers := NO
 mloop := TRUE

 while mloop

  while TRUE
   Box_Restore( oldscr )

   Heading( 'Add New Contract' )
   temp_num := Sysinc( 'con_no', 'I', 1, 'master' )

   Box_Save( 02, 08, 6, 72 )
   @ 3,10 say 'Next Contract No' get temp_num pict '999999' valid( temp_num > 0 )
   Center( 05, '-=< Hit Esc to exit >=-' )
   read

   if lastkey() = K_ESC
    Oddvars( ENQ_STATUS, TRUE )
    dbcloseall()
    return

   endif

   master->( ordsetfocus( 'contract' ) )
   if master->( dbseek( temp_num ) )
    Error( 'Contract Number ' + Ns( temp_num ) + ' on file already', 12 )
    loop

   else
    start_con := temp_num
    exit

   endif

  enddo
  select master
  if master->( dbseek( start_con ) )
   Error( 'Contract no on file already',12)
   loop

  endif

  mloop2 := TRUE
  Oddvars( ENQ_STATUS, FALSE )

  while mloop2
   Heading( 'Adding Contract no ' + Ns( start_con ) )
   mname := space(20)
   Box_Save( 02, 08, 22, 72 )
   @ 03, 10 say ' Hirer Surname' get mname
   read
   if !updated()
    if !hirers
     Oddvars( ENQ_STATUS, TRUE )
     dbcloseall()
     return

    endif
    mloop := FALSE
    mloop2 := FALSE
    loop

   else
    if !hirers
     mskey := mname

    endif
    hirers := TRUE
    select hirer

    if add_rec( 'hirer' )
     hirer->con_no :=start_con
     hirer->surname := mname
     HirerGet( TRUE )
     hirer->( dbrunlock() )

    endif
   endif
  enddo
 enddo

 if hirers

  items_added := FALSE
  newloop := TRUE
  mmonth := 0
  mperiod := 'M'
  minsure := FALSE
#ifdef INSURANCE
  sTotInsure := 0
#endif
  mdate := Bvars( B_SYSDATE )
  mdate2 := Bvars( B_SYSDATE )
  Heading( 'Add Rental items to Contract #' + Ns( start_con ) )
  Box_Save( 02, 08, 5, 72 )
  @ 3,10 say '<M>onthly,<F>ortnightly,<W>eekly or <D>aily rental period';
         get mperiod pict '!' valid( mperiod $ 'MFWD')

#ifdef INSURANCE
  @ 4,10 say 'Charge Insurance on Contract' get minsure pict 'Y'
#endif

  read

  if lastkey() = K_ESC
   loop

  endif

  Box_Save( 2, 1, 23, 77 )
  row := 4
#ifdef INSURANCE
  @ 3,2 say 'Item code   Serial no       Desc                Ins  '+ perdesc( mperiod )
#else
  @ 3,2 say 'Item code   Serial no       Description              '+ perdesc( mperiod )
#endif

  while newloop
   mstr := '< Total '+ perdesc( mperiod ) + ' Install. $' + ns( mmonth, 9, 2 ) + ' >'
   @ 2,76 - len( mstr ) say mstr
   mitem := space( 10 )
   mscr := It_ord_disp( row )
   @ row, 02 get mitem pict '@!'
   okf10 := setkey( K_F10, { || item_index( row ) } )
   read
   setkey( K_F10, okf10 )
   Box_Restore( mscr )

   if !updated()
    newloop := FALSE
    loop

   else
    if !items->( dbseek( mitem ) )
     Error('Item Code not on File',12)
     loop

    endif

    if items->status != 'O'
     Error( 'Item not available for hire!', 12 )
     loop

    endif

    @ row,12 say space( 65 )
    @ row,02 say items->item_code
    @ row,14 say items->serial
    @ row,26 say left( items->desc, 20 )

    mrent := items->( fieldget( items->( fieldpos( mperiod + '_rent' ) ) ) )
    mtrent := mrent

#ifdef INSURANCE
    nInsAmt := items->insurance
#endif
#ifdef INSURANCE
    @ row,50 get nInsAmt pict '9999.99'
#endif
    @ row,58 get mrent pict '9999.99' valid( mrent > 0 )
    read

    if mrent > 0
     mmonth += mrent

     Rec_lock( 'items' )

     items->status := 'H'
     items->con_no := start_con
     items->last_rent := Bvars( B_SYSDATE )

#ifdef INSURANCE
     items->insurance := nInsAmt
     mmonth += nInsAmt
     sTotInsure += nInsAmt

#endif

     if mrent != mtrent
      items->( fieldput( fieldpos( mperiod + '_rent' ), mrent ) )

     endif
     items->( dbrunlock() )

     items_added := TRUE
     row++

     if row = 18
      row := 4
      @ 4,2 clear to 18,77
      @ row,02 say mitem
      @ row,14 say items->serial
      @ row,26 say items->desc
      @ row,58 say items->month_pay pict '9999.99'
      row++

     endif

    endif

   endif

  enddo

  madd := NO

  if !items_added

   mscr := Box_Save( row, 21, row+3, 59 )
   @ row+1,22 say ' There are no items on this contract'
   @ row+2,22 say 'Do you wish to add it to the system' get madd pict 'Y'
   read
   Box_Restore( mscr )

   if !madd

    while hirer->( dbseek( start_con ) )
     Rec_lock( 'hirer' )
     hirer->( dbdelete() )
     hirer->( dbrunlock() )
    enddo

    oldord := items->( ordsetfocus( 'contract' ) )

    while items->( dbseek( start_con ) )
     rec_lock( 'items' )
     items->status := 'O'
     items->( dbrunlock() )
    enddo

    items->( ordsetfocus( oldord ) )
    loop

   endif

  endif

  mdep := 0
  minstall := mmonth
  mgrace := Bvars( B_GRACE )
  mcom1 := space( 30 )
  mcom2 := space( 30 )
  marea := space( 3 )
  mcomm := Bvars( B_SYSDATE )
  mdate := Bvars( B_SYSDATE )
  mdep_no := space( DEPNOLEN )
  mterm := space( 8 )
  mbank := space( 40 )
  msite := space( 2 )
  dEndDate := NULL_DATE

  lgst := FALSE

  mscr := Box_Save( row, 04, row+10, 76 )
  @ row+1, 05 say 'Commencement Date' get mcomm
  @ row+1, 34 say 'Paid to Date' get mdate
  @ row+1, 57 say 'Period of Grace' get mgrace pict '99'
  @ row+2, 05 say '    Location Area' get marea pict '!!!'
  @ row+2, 34 say 'Bond Paid' get mdep pict '9999.99'
  @ row+3, 05 say '         Comments' get mcom1
  @ row+4, 05 say '                 ' get mcom2
  @ row+5, 05 say '  Deposit Book No' get mdep_no valid ChkDepBook( mDep_no )
  @ row+5, 40 say 'Rentals Period' get mterm
 #ifdef BYRNES
  @ row+6, 05 say 'Contract End Date' get dEndDate valid dEndDate >= BVars( B_SYSDATE )
 #endif
 #ifdef MEDI
  @ row+6, 05 say 'GST Free Contract' get lgst pict 'Y'
 #endif

 #ifdef MEDI
  mbill := space(1)
  mmyob := space(40)
  mponum := space(10)
  mfirst := ''
  @ row+7, 05 say 'Billing Method' get mbill pict '!' valid( mbill $ 'PIC' )
  @ row+7, 25 say 'Pulsar Acc No' get mmyob pict '999999' valid( if( mbill != 'I', TRUE, dup_chk( mmyob, 'debtor' ) ) )

 #endif

 #ifdef CREDIT_CARD
  sCardNum := space(30)
  mcardexp := NULL_DATE
  mcardid := space(4)
  @ row+8, 05 say 'Card Number' get sCardNum pict '@!'
  @ row+9, 05 say 'Expiry Date' get mcardexp
  @ row+9, 25 say 'Card ID' get mcardid pict '@!'

 #endif

 #ifdef MEDI
  @ row+9, 40 say 'Purc ord Num' get mponum pict '@!'

  if mbill = 'I'
   mfirst := lookitup( 'debtor', mmyob )

  endif
 #endif

#ifdef MULTI_SITE
  @ row+7,05 say 'Site' get msite pict '@!' valid( dup_chk( msite, 'sites' ) )
#endif
  read
  Box_Restore( mscr )

  if !empty( mdep_no )
   oldord := master->( ordsetfocus( 'deposit' ) )
   if dbseek( mdep_no )
    Error( 'Deposit book no already on contract #' + Ns( master->con_no ) )
   endif
   master->( ordsetfocus( oldord ) )

  endif

  Add_rec( 'master' )
  master->con_no := start_con
  master->paid_to := mdate
  master->reminders := TRUE
  master->grace := mgrace
  master->bond_paid := mdep
  master->bond_date := Bvars( B_SYSDATE )
  master->install := mmonth
  master->next_inst := master->paid_to + 1
  master->bal_bf := 0
  master->comments1 := mcom1
  master->comments2 := mcom2
  master->area := marea
  master->term_rent := mperiod
  master->commenced := mcomm
  master->skey := mskey
  master->dep_no := mdep_no
  master->term_len := mterm
  master->inquiry := madd
  master->TaxFree := lgst
  master->status := 'A'   // Active Account
#ifdef BYRNES
  master->EndDate := dEndDate
#endif

#ifdef INSURANCE
  master->insurance := ( sTotInsure > 0 )
#endif

#ifdef MULTI_SITE
  master->site := msite
#endif

#ifdef MEDI
  master->billmethod := mbill
  master->extra_key := mmyob
  if mbill = 'I'
   mfirst := lookitup( 'debtor', mmyob )
//   master->myobfirst := lookitup( 'myobimpo', mmyob )
  endif
  master->ponum := mponum
#endif

#ifdef CREDIT_CARD
  master->cred_card := sCardNum
  master->expirydate := mcardexp
  master->card_id := mcardid
#endif
  master->( dbrunlock() )

  Oddvars( LASTCONT, Ns( start_con ) )  // Last contract used for enquiry ?

#ifdef RENTACENTRE
  Audit( start_con, 'Y', 0 )

#else

  if Isready( 12, 10, 'Add previous transaction history' )
   while TRUE
    mdate := ctod('  /  /  ')
    mpay := 0
    mtype := 'P'
    mcomm := space( 20 )
    Box_Save( 6, 01, 9, 79 )
    Center( 8, '-=< Hit <Esc> to Exit >=-' )
    @ 7, 03 say 'Date' get mdate
    @ 7, 18 say 'Amount' get mpay pict '99999.99'
    @ 7, 35 say 'Type <PCD>' get mtype pict '!' valid( mtype $ 'PCD')
    @ 7, 48 say 'Comment' get mcomm
    read
    if empty( mpay ) .or. lastkey() = K_ESC
     exit
    else
     if mtype = 'D'
      mpay := mpay *-1
     endif
     Add_rec( 'tran' )
     tran->con_no := start_con
     tran->date := mdate
     tran->value := mpay
     tran->type := mtype
     tran->narrative := mcomm
     tran->( dbrunlock() )
    endif

   enddo

  endif
#endif   // not RENTACENTRE

 endif
enddo
dbcloseall()
return

*

Procedure conedit

local ok := FALSE, oldscr := Box_Save(), mchoice, getlist := {}, level4
local pos_count, mstr, mkey, single_hire, choice, row, mmonth,  mitem
local mrent, mtrent, nInsAmt, mterm, v_rent, aArray

if NetUse( 'stkhist' )
 if NetUse( "items" )
  items->( ordsetfocus( 'contract' ) )
  if NetUse( "hirer" )
   if NetUse( "master" )
    set relation to master->con_no into items,;
                 to master->con_no into hirer
    ok := TRUE
   endif
  endif
 endif
endif

while ok

 Box_Restore( oldscr )

 if !Con_find()
  exit

 endif

 master->( dbseek( Oddvars( CONTRACT ) ) )

 while TRUE

  Box_Restore( oldscr )

  Heading( 'Edit Contract no. ' + Ns( Oddvars( CONTRACT ) ) )

  aArray := {}
  aadd( aArray, { 'Exit', 'Return to file menu' } )
  aadd( aArray, { 'Hirers', 'Edit who is on contract' } )
  aadd( aArray, { 'Items', 'Change hire items on contract' } )
  aadd( aArray, { 'Details', 'Static details on contract' } )
  mchoice := MenuGen( aArray, 06, 14, 'Change' )

  level4 := Box_Save()

  do case
  case mchoice = 2

   pos_count := 1
   single_hire := NO


   select hirer
   if !hirer->( dbseek( Oddvars( CONTRACT ) ) )

    if Isready( 12, , 'No Hirers found on Contract - Add one?' )

     Add_rec( 'hirer' )
     hirer->con_no := Oddvars( CONTRACT )

     cls
     Heading( 'Hirer details edit' )


     Highlight( 01, 10, '  Hirer number', Ns( pos_count ) )

     Hirerget()

     hirer->( dbrunlock() )

     if !updated()
      Rec_lock( 'hirer' )
      hirer->( dbdelete() )
      hirer->( dbrunlock() )
      hirer->( dbseek( Oddvars( CONTRACT ) ) )
      loop

     endif

     hirer->( dbseek( Oddvars( CONTRACT ) ) )

    endif

   endif

   while hirer->con_no = Oddvars( CONTRACT ) .and. !hirer->( eof() )
    Hirersay( pos_count )
    hirer->( dbskip() )
    if pos_count = 1 .and. hirer->con_no != Oddvars( CONTRACT )
     Line_clear(23)
     Center( 23,'Only Hirer on Contract' )
     single_hire := TRUE
    endif
    hirer->( dbskip( -1 ) )

    Center( 22, 'You may <D>elete, <C>hange this one or <A>ppend a new hirer' )
    Center( 23, 'use '+chr(17)+' + '+chr(16)+' keys to scroll or <Esc> to exit' )

    mkey := inkey(0)

    do case
    case mkey == K_F12
     Print_Screen()

    case mkey = 67 .or. mkey = 99
     Rec_lock( 'hirer' )
     cls
     Heading( 'Hirer details edit' )
     Highlight( 01, 10, '  Hirer number', Ns( pos_count ) )
     Hirerget()

     hirer->( dbrunlock() )

    case mkey = 68 .or. mkey = 100
     if single_hire
      Error( 'Only one Hirer - Deletion not allowed',12 )

     else

      if Isready( 22, 10, 'Ok to delete this hirer' )
       Rec_lock( 'hirer' )
       hirer->( dbdelete() )
       hirer->( dbrunlock() )
       hirer->( dbseek( Oddvars( CONTRACT ) ) )
       mkey := hirer->surname

       master->( dbseek( Oddvars( CONTRACT ) ) )
       Rec_lock( 'master' )
       master->skey := mkey
       master->( dbrunlock() )

       pos_count := 1
      endif
     endif

    case mkey = 65 .or. mkey = 97
     Add_rec( 'hirer' )
     hirer->con_no := Oddvars( CONTRACT )
     cls
     Heading( 'Hirer details edit' )
     Highlight( 01, 10, '  Hirer number', Ns( pos_count ) )
     Hirerget()

     hirer->( dbrunlock() )

     if !updated()
      Rec_lock( 'hirer' )
      hirer->( dbdelete() )
      hirer->( dbrunlock() )
      hirer->( dbseek( Oddvars( CONTRACT ) ) )
      loop

     else
      single_hire := NO
      pos_count++

     endif
     hirer->( dbseek( Oddvars( CONTRACT ) ) )
     hirer->( dbskip( pos_count - 1 ) )

    case mkey = 19
     if pos_count < 2
      Error( 'Attempt to skip past first hirer',12 )
     else
      hirer->( dbskip( -1 ) )
      pos_count--
     endif

    case mkey = 4
     hirer->( dbskip() )
     if Oddvars( CONTRACT ) != hirer->con_no
      Error( 'Attempt to skip past last hirer' ,12 )
      hirer->( dbskip( -1 ) )
     else
      pos_count++
     endif

    otherwise
     hirer->( dbgobottom() )
     hirer->( dbskip() )
    endcase

   enddo

  case mchoice = 3

   while TRUE

    Heading( 'Edit Items on contract no. ' + Ns( Oddvars( CONTRACT ) ) )
    aArray := {}
    aadd( aArray, { 'Exit', 'Return to Edit menu' } )
    aadd( aArray, { 'Add', 'Add an item to Contract' } )
    aadd( aArray, { 'Delete', 'Delete contract item' } )
    choice := MenuGen( aArray, 09, 15, 'Items' )

    master->( dbseek( Oddvars( CONTRACT ) ) )

    do case
    case choice < 2
     exit

    case choice = 2
     cls
     Heading( 'Add items to contract no. ' + Ns( Oddvars( CONTRACT ) ) )
     row := 4
     mmonth := master->install

     while TRUE
#ifdef INSURANCE
  @ 3,2 say 'Item code   Serial no       Desc                Ins  '+ perdesc( master->term_rent )
#else
  @ 3,2 say 'Item code   Serial no       Description              '+ perdesc( master->term_rent )
#endif
      mstr := 'Total '+ perdesc( master->term_rent) + ' install. $' + Ns( mmonth, 8, 2 )
      @ 1, 78 - len( mstr ) say mstr
      Line_clear( row )
      mitem := space( 10 )
      It_ord_disp( row )
      @ row,2 get mitem pict '@!'

      setkey( K_F10 , { || Item_index( row ) } )
      read
      setkey( K_F10 , nil )

      if !updated()
       exit

      else

       items->( ordsetfocus( 'item_code' ) )
       items->( dbseek( mitem ) )
       items->( ordsetfocus( 'contract' ) )

       if !items->( found() )
        Error( 'Item code not on file',12)
        loop

       endif

       if items->status != ITEM_ONHAND

        if items->status = ITEM_HIRED
         Error( 'Item on hire - contract no.' + Ns( Oddvars( CONTRACT ) ), 12 )

        else
         Error( 'Item not onhand / in-stock. Status code is ' + items->status, 12 )

        endif
        loop

       endif

       @ row,12 say space(65)
       @ row,14 say items->serial
       @ row,26 say items->desc

       mrent := items->( fieldget( items->( fieldpos( master->term_rent + '_rent' ) ) ) )
       mtrent := mrent

#ifdef INSURANCE
       nInsAmt := items->insurance
#endif
#ifdef INSURANCE
       @ row,50 get nInsAmt pict '999.99'
#endif
       @ row,58 get mrent pict '999.99' valid( mrent > 0 )
       read

       if mrent > 0

        mmonth += mrent

        Rec_lock( 'items' )
        items->status := 'H'
        items->con_no := Oddvars( CONTRACT )
        items->last_rent := Bvars( B_SYSDATE )
#ifdef INSURANCE
        items->insurance := nInsAmt
        mmonth += nInsAmt
#endif
        if mrent != mtrent
         items->( fieldput( fieldpos( master->term_rent + '_rent' ), mrent ) )

        endif

        items->( dbrunlock() )

       endif

       row++
       if row = 20
        row := 4
        @ row,2 clear
        @ row,2 say items->item_code
        @ row,14 say items->serial
        @ row,26 say items->desc
        @ row,58 say items->month_pay pict '999.99'
        row++
       endif
      endif

     enddo

     Rec_lock( 'master' )
     master->install := mmonth
     master->inquiry := FALSE
     master->( dbrunlock() )

    case choice = 3
     master->( dbseek( Oddvars( CONTRACT ) ) )
     mterm := master->term_rent
     select items
     pos_count := 1
     cls
     Heading( 'Items on contract # ' + Ns( Oddvars( CONTRACT ) ) )

     while items->con_no = Oddvars( CONTRACT ) .and. !items->( eof() )

      Itemsay2()
      items->( dbskip() )

      if pos_count = 1 .and. ( items->con_no != Oddvars( CONTRACT ) .or. items->( eof() ) )
       Error( 'Only item on contract deletion not allowed', 12 )
      else

       items->( dbskip( -1 ) )
       Line_clear( 23 )
       Center( 23, 'Use ' + chr( 17 ) + ' + ' + chr(16) + ' keys to scroll, ' + ;
               '<D> to delete or <Esc> to exit' )

       mkey := inkey( 0 )

       do case
       case mkey = 68 .or. mkey = 100

        if Isready( 18, 45, 'Delete this item from contract?' )

         if !empty( items->item_code )

          Add_rec( 'stkhist' )
          stkhist->item_code := items->item_code
          stkhist->address1 := hirer->add1
          stkhist->address2 := hirer->add2
          stkhist->name := trim(hirer->first)+ ' '+trim(hirer->surname)
          stkhist->suburb := hirer->suburb
          stkhist->returned := Bvars( B_SYSDATE )
          stkhist->con_no := Oddvars( CONTRACT )
          stkhist->( dbrunlock() )

         endif

#ifdef INSURANCE
         nInsAmt := items->insurance
#else
         nInsAmt := 0
#endif
         Rec_lock( 'items' )
         items->last_ret := Bvars( B_SYSDATE )
         items->status := 'O'
         items->con_no := -1
         items->( dbrunlock()  )

         v_rent := items->( fieldget( items->( fieldpos( master->term_rent + '_rent' ) ) ) )

         Rec_lock( 'master' )
         master->install := master->install - ( v_rent - nInsAmt )
         master->( dbrunlock()  )

         select items
         dbseek( Oddvars( CONTRACT ) )

        endif

       case mkey = K_LEFT
        if pos_count < 2
         Error( 'Attempt to skip past first item' , 12 )
        else
         items->( dbskip( -1 ) )
         pos_count--
        endif

       case mkey = K_RIGHT
        items->( dbskip() )
        if Oddvars( CONTRACT ) != items->con_no .or. items->( eof() )
         Error( 'Attempt to skip past last item' , 12 )
         items->( dbskip( -1 ) )

        else
         pos_count++

        endif

       case mkey == K_F12
        Print_Screen()

       case mkey = K_ESC
        exit

       endcase

      endif
     enddo

    endcase
    Box_Restore( level4 )

   enddo

  case mchoice = 4
   master->( dbseek( Oddvars( CONTRACT ) ) )
   Rec_lock( 'master' )
   ConGet()
   read
   master->( dbrunlock()  )

  case mchoice < 2
   exit

  endcase

 enddo

enddo

dbcloseall()
return

*


Procedure condel

local ok := FALSE, getlist := {}, lRetain, lDetailsPrint
local lStockItems

#ifndef RENTACENTRE
local mrecs, mdeleted

#endif

if NetUse( "stkhist" )
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
      ok := YES
     endif
    endif
   endif
  endif
 endif
endif
while ok

 if !Con_find()
  dbcloseall()
  return

 else
  master->( dbseek( Oddvars( CONTRACT ) ) )
  cls

  Heading( 'Delete Contract no ' + Ns( Oddvars( CONTRACT ) ) )

  @ 03,10 say 'First Hirer on Contract'
  Highlight( 05, 10, '   Name', hirer->surname )
  Highlight( 07, 10, 'Address', hirer->add1 )
  Highlight( 08, 10, '       ', hirer->add2 )
  Highlight( 10, 10, ' Suburb', hirer->suburb )

  if master->inquiry
   @ 12,10 say 'No items on contract'
   @ 14,10 say 'Details are for inquiry only '

  else
   @ 12,10 say 'First item on contract'
   Highlight( 13, 10, 'Item code' , items->item_code )
   Highlight( 14, 10, 'Item desc' , items->desc )

  endif

  if master->bal_bf != 0
   Error( 'Contract not paid out ' + Ns( master->bal_bf, 8, 2 ) + ' balance left', 17 )
   loop

  endif

  if Isready( 16, 10, 'Is this the Contract to delete' )
   lRetain := TRUE   // Everyone seems to want to retain contract details.
   lDetailsPrint := FALSE
   lStockItems = FALSE

#ifndef RENTACENTRE
   @ 19,10 say '           Suppress details print out' get lDetailsPrint pict 'Y'

 #ifdef BYRNES
   lStockItems = TRUE

 #endif
   read

#endif

   if lastkey() != K_ESC

    if master->bond_paid > 0
     Error( 'A bond refund of ' + Ns( master->bond_paid, 4 ) + ' is due!', 12 )

    endif

    if !lDetailsPrint
     Det_print()

    endif

    if !lStockItems

     items->( dbseek( Oddvars( CONTRACT ) ) )
     while items->con_no = Oddvars( CONTRACT ) .and. !items->( eof() )

      Add_rec( 'stkhist' )
      stkhist->item_code := items->item_code
      stkhist->address1 := hirer->add1
      stkhist->address2 := hirer->add2
      stkhist->name := trim(hirer->first)+' '+trim(hirer->surname)
      stkhist->suburb := hirer->suburb
      stkhist->returned := Bvars( B_SYSDATE )
      stkhist->con_no := Oddvars( CONTRACT )
      stkhist->( dbrunlock() )
      items->( dbskip() )

     enddo

     select items
     while items->( dbseek( Oddvars( CONTRACT ) ) )

      Rec_lock( 'items' )
      items->status := 'O'
      items->last_ret := Bvars( B_SYSDATE )
      items->con_no := 0
      items->( dbrunlock() )

     enddo

    endif
    master->( dbseek( Oddvars( CONTRACT ) ) )

    if !lRetain

     Rec_lock( 'master' )
     master->( dbdelete() )
     master->( dbrunlock() )

     while hirer->( dbseek( Oddvars( CONTRACT ) ) )
      Rec_lock( 'hirer' )
      hirer->( dbdelete() )
      hirer->( dbrunlock() )
     enddo

     tran->( dbseek( Oddvars( CONTRACT ) ) )
     while tran->con_no = Oddvars( CONTRACT ) .and. !tran->( eof() ) .and. Pinwheel( NOINTERUPT )
      Rec_lock( 'tran' )
      tran->( dbdelete() )
      tran->( dbrunlock() )
      tran->( dbskip() )
     enddo

     arrears->( dbseek( Oddvars( CONTRACT ) ) )
     while arrears->con_no = Oddvars( CONTRACT ) .and. !arrears->( eof() ) .and. Pinwheel( NOINTERUPT )
      Rec_lock( 'arrears' )
      arrears->( dbdelete() )
      arrears->( dbrunlock() )
      arrears->( dbskip() )

     enddo

    else

     Rec_lock( 'master' )
     master->inquiry := TRUE
     master->dep_no := ''
#ifdef BYRNES
     master->status := 'P'
#endif
     master->( dbrunlock() )

#ifndef BYRNES   // Want to retain all tran/arrears details
 #ifndef RENTACENTRE
     select tran
     dbseek( Oddvars( CONTRACT ) )
     count to mrecs while tran->con_no = Oddvars( CONTRACT ) .and. Pinwheel( NOINTERUPT )
     mdeleted := 0
     tran->( dbseek( Oddvars( CONTRACT ) ) )
     while tran->con_no = Oddvars( CONTRACT ) .and. mdeleted <= ( mrecs - 20 ) ;
          .and. !tran->( eof() ) .and. Pinwheel( NOINTERUPT )
      Rec_lock( 'tran' )
      tran->( dbdelete() )
      tran->( dbrunlock() )
      mdeleted++
      tran->( dbskip() )

     enddo

     select arrears
     seek Oddvars( CONTRACT )
     count to mrecs while arrears->con_no = Oddvars( CONTRACT ) .and. Pinwheel( NOINTERUPT )
     mdeleted := 0
     arrears->( dbseek( Oddvars( CONTRACT ) ) )
     while arrears->con_no = Oddvars( CONTRACT ) .and. mdeleted <= ( mrecs - 20 ) ;
           .and. !arrears->( eof() ) .and. Pinwheel( NOINTERUPT )
      Rec_lock( 'arrears' )
      arrears->( dbdelete() )
      arrears->( dbrunlock() )
      mdeleted++
      arrears->( dbskip() )

     enddo

 #endif

#endif


    endif


#ifdef RENTACENTRE
    Audit( Oddvars( CONTRACT ), 'X' , 0 )
#endif

    Error( 'Contract Deleted', 12 )

   endif

  endif

 endif

enddo
dbcloseall()
return

*

procedure det_print

local page_no := 1
local row := 1
local crlf := chr( 10 ) + chr( 13 )
local uline := replicate( chr(196), 132 )
local mhead1 := " Account   Hirer's name & Addr.   Telephone      Due date"
local mrent := master->term_rent + '_rent'
local int_row := 1, mrec , msur, mfirst
local oPrinter, cFile, toScreen, oFSO, sF1, sF2, sF3, oShell
mhead1 += '     Overdue   Items            Desc'

toScreen := Isready( 12, 10, 'Print to Screen' )

if toScreen
 //TRY
  oFSO := CreateObject( "Scripting.FileSystemObject" )

 //CATCH
 // Alert( "ERROR! Problem with Scripting host FSO [" + Ole2TxtError()+ "]" )

// END
 cFile := trim( netname() ) + ".txt"
 oPrinter:= oFSO:CreateTextFile( cFile, VBTRUE )

else  // to Screen
  oPrinter := Printcheck( 'Contract Deletion Contract No' + ns( master->con_no ) + '  Hirer ' + hirer->surname )

endif

while int_row < 5

 if row <=  5
  Det_head( oPrinter, mhead1, @page_no, toScreen )
  row := 7

 endif

 do case
 case int_row = 1
  hirer->( dbseek( Oddvars( CONTRACT ) ) )
  mrec := hirer->( recno() )
  msur := ''
  mfirst := ''
  while Oddvars( CONTRACT ) = hirer->con_no .and. !hirer->( eof() )
   msur += trim( hirer->surname ) + '/'
   mfirst += trim( hirer->first ) + '/'
   hirer->( dbskip() )

  enddo
  hirer->( dbgoto( mrec ) )
  msur := left( msur, len( trim( msur ) ) -1 )
  mfirst := left( mfirst, len( trim( mfirst ) ) -1 )

  if toScreen
   oPrinter:Write( CRLF )
   oPrinter:Write( padr( Transform( master->con_no, CON_NO_PICT ), 10 ) )
   oPrinter:Write( padr( left( msur, 26 ), 27 ) )
   oPrinter:Write( padr( hirer->tele_priv, 15 ) )
   oPrinter:Write( padr( dtoc( master->paid_to ), 9 ) )
   oPrinter:Write( transform( master->bal_bf, CURRENCY_PICT ) )

  else
   oPrinter:NewLine()
   oprinter:setpos( 0 )
   oPrinter:TextOut( Ns( master->con_no ) )
   oprinter:setpos( 08 * oPrinter:CharWidth )
   oPrinter:TextOut( left( msur, 26 ) )
   oprinter:setpos( 35 * oPrinter:CharWidth )
   oPrinter:TextOut( hirer->tele_priv )
   oprinter:setpos( 50 * oPrinter:CharWidth )
   oPrinter:TextOut( dtoc( master->paid_to ) )
   oprinter:setpos( 60 * oPrinter:CharWidth )
   oPrinter:TextOut( transform( master->bal_bf * -1, '######.##' ) )

  endif

 case int_row = 2
  if toScreen
   oPrinter:Write( CRLF )
   oPrinter:Write( space(8) )
   oPrinter:Write( padr( left( mFirst, 26 ), 27 ) )
   oPrinter:Write( hirer->tele_empl )

  else
   oPrinter:NewLine()
   oPrinter:setpos( 8 * oPrinter:CharWidth )
   oPrinter:TextOut( left( mfirst, 26 ) )
   oPrinter:setpos( 35 * oPrinter:CharWidth )
   oPrinter:TextOut( hirer->tele_empl )

  endif

 case int_row = 3
  sF1 := trim( hirer->add1 ) + ' ' + hirer->add2
  sF2 := master->comments1
  if toScreen
   oPrinter:Write( CRLF )
   oPrinter:Write( space( 8 ) )
   oPrinter:Write( sF1 )
   oPrinter:Write( sF2 )

  else
   oPrinter:NewLine()
   oPrinter:setpos( 8 * oPrinter:CharWidth )
   oPrinter:TextOut( sF1 )
   oPrinter:setpos( 35 * oPrinter:CharWidth )
   oPrinter:TextOut( sF2 )

  endif

 case int_row = 4
  sF1 = trim( hirer->suburb ) + ' ' + hirer->pcode
  sF2 :=master->comments2

  if toScreen
   oPrinter:Write( CRLF )
   oPrinter:Write( space( 8 ) )
   oPrinter:Write( padr( sF1, 25)  )
   oPrinter:Write( sF2 )

  else
   oPrinter:NewLine()
   oPrinter:setpos( 8 * oPrinter:CharWidth )
   oPrinter:TextOut( sF1 )
   oPrinter:setpos( 35 * oPrinter:CharWidth )
   oPrinter:TextOut( sF2 )

  endif

 endcase
 items->( dbseek( Oddvars( CONTRACT ) ) )
 items->( dbskip( int_row -1 ) )

 if items->con_no = Oddvars( CONTRACT )
  sF1 := transform( items->( fieldget( items->( fieldpos( master->term_rent + '_rent' ) ) ) ),  '99999.99' )

  if toScreen
   oPrinter:Write( CRLF )
   oPrinter:write( padl( items->item_code, 72 ) )
   oPrinter:Write( padr( items->desc, 30 ) )
   oPrinter:Write( sF1 )

  else
   oPRinter:NewLine()
   oPrinter:setpos( 72 * oPrinter:CharWidth )
   oPrinter:TextOut( items->item_code )
   oPrinter:setpos( 90 * oPrinter:CharWidth )
   oPrinter:TextOut( items->desc )
   oPrinter:setpos( 120 * oPrinter:CharWidth )
   oPrinter:TextOut( sF1 )

  endif

 endif

 int_row++
 row++

enddo
row++

sF1 :=  'Commencement date ' + dtoc( master->commenced )
sF2 :=  'Bond  $' + Ns( master->bond_paid, 7, 2 )
sF3 :=  'Bond date '  + dtoc( master->bond_date )

if toScreen
 oPrinter:Write( CRLF )
 oPrinter:Write( padr( sF1, 30 ) )
 oPrinter:Write( padr( sF2, 25 ) )
 oPrinter:Write( sF3 )

else
 oPrinter:NewLine()
 oPrinter:setpos( 0 * oPrinter:CharWidth )
 oPrinter:TextOut( sF1 )
 oPrinter:setpos( 30 * oPrinter:CharWidth )
 oPrinter:TextOut( sF2 )
 oPrinter:setpos( 55 * oPrinter:CharWidth )
 oPrinter:TextOut( sF3 )

endif

if tran->( dbseek( Oddvars( CONTRACT ) ) )
 mhead1 := ' Date       Credit       Debit    Trans. type    Comments'
 if toScreen
  oPrinter:Write( CRLF + CRLF )
  oPrinter:Write( mhead1 )

 else
  oPrinter:NewLine()
  oPrinter:NewLine()
  oPrinter:setpos( 0 )
  oPrinter:TextOut( mhead1 )

 endif

 while tran->con_no = Oddvars( CONTRACT ) .and. !tran->( eof() )
  if toScreen
   oPrinter:Write( CRLF )
   oPrinter:Write( padr( dtoc( tran->date ), 10 ) )
   if tran->value >= 0
    oPrinter:write( transform( tran->value, '99999.99' ) )
    oPrinter:write( space ( 13 ) )

   else
    oPrinter:write( space( 13 ) )
    oPrinter:write( transform( tran->value*-1, '99999.99' ) )

   endif
   oPrinter:Write( space( 2 ) )
   oPrinter:write( padr( tran_type( tran->type ), 18 ) )
   oPrinter:write( tran->narrative )

  else
   oPrinter:NewLine()
   oPrinter:setpos( 1 * oPrinter:CharWidth )
   oPrinter:TextOut( dtoc( tran->date ) )
   if tran->value >= 0
    oPrinter:setpos( 11 * oPrinter:CharWidth )
    oPrinter:TextOut( transform( tran->value, '99999.99' ) )

   else
    oPrinter:setpos( 22 * oPrinter:CharWidth )
    oPrinter:TextOut( transform( tran->value*-1, '99999.99' ) )

   endif
   oPrinter:setpos( 33 * oPrinter:CharWidth )
   oPrinter:TextOut( tran_type( tran->type ) )
   oPrinter:setpos( 51 * oPrinter:CharWidth )
   oPrinter:TextOut( left( tran->narrative, 17 ) )

  endif

  row++
  tran->( dbskip() )
  if row >= 56 .and. tran->con_no = Oddvars( CONTRACT )
   if !toScreen
    oPrinter:NewPage()

   endif
   row := Det_head( oPrinter, mhead1, @page_no, toScreen )

  endif

 enddo

endif

 if toScreen
  oShell := CreateObject( "Wscript.Shell" )
  oShell:Exec( bvars( B_EDITOR ) + ' ' + cFile )

 else
  oPrinter:endDoc()
  oPrinter:Destroy()

 endif

return

*

function det_head ( oPrinter, mhead1, page_no, toScreen )
if toScreen
 oPrinter:Write( CRLF )
 oPrinter:Write( replicate( '-', 118 ) )
 oPrinter:Write( CRLF )
 oPrinter:Write( padr( space( 10 ) + trim( BVars( B_COMPANY ) ), 49 ) )
 oPrinter:Write( padr( 'Contract Details for - ' + Ns( Oddvars( CONTRACT ), 68 ) ) )
 oPrinter:Write( 'Page no ' + Ns( page_no ) )
 oPrinter:Write( CRLF )
 oPrinter:Write( replicate( '-', 118 ) )
 oPrinter:Write( CRLF )
 oPrinter:Write( mHead1 )

else
 oPrinter:NewLine()
 oPrinter:setpos( 1 * oPrinter:CharWidth )
 oPrinter:TextOut( replicate( '-', 118 ) )
 oPrinter:NewLine()
 oprinter:setpos( 10 * oPrinter:CharWidth )
 oPrinter:TextOut( trim( BVars( B_COMPANY ) ) )
 oprinter:setpos( 50 * oPrinter:CharWidth )
 oPrinter:TextOut( 'Contract details for - ' + Ns( Oddvars( CONTRACT ) ) )
 oprinter:setpos( 118 * oPrinter:CharWidth )
 oPrinter:TextOut( 'Page no ' + Ns( page_no ) )
 oPrinter:NewLine()
 oprinter:setpos( 1 * oPrinter:CharWidth )
 oPrinter:TextOut( replicate( '-', 118 )  )
 oPrinter:NewLine()
 oprinter:setpos( 1 * oPrinter:CharWidth )
 oPrinter:TextOut( mhead1 )
 oPrinter:NewLine()

endif
page_no++
return 6

*

procedure hirerget ( lNewCont )
local getlist := {}
default lNewCont to FALSE

if !lNewCont
 @ 03, 10 say ' Hirer Surname' get hirer->surname
endif

@ 05, 10 say '    First name' get hirer->first
@ 07, 10 say 'Address line 1' get hirer->add1
@ 08, 10 say '        line 2' get hirer->add2
@ 09, 10 say '        Suburb' get hirer->suburb
@ 09, 44 say '      Postcode' get hirer->pcode
@ 11, 10 say ' Date of Birth' get hirer->dob
@ 12, 10 say '    License no' get hirer->license pict '@!'
@ 12, 44 say '   Expiry date' get hirer->expiry_d
#ifdef DISCOUNT
@ 14, 10 say ' Map Reference' get hirer->car_rego
#else
 #ifndef RENTACENTRE
  #ifndef ARGYLE
   #ifndef BYRNES
  @ 14, 10 say '  Car rego no.' get hirer->car_rego
   #else
  @ 14, 10 say '           CRN' get hirer->car_rego
   #endif
  #else
  @ 14, 10 say 'Contr. Penalty' get hirer->car_rego
  @ 15, 10 say '        E-Mail' get hirer->email pict '@S40'

  #endif

#else
@ 14, 10 say '        E-Mail' get hirer->email pict '@S40'
 #endif
#endif
@ 16, 10 say 'Priv telephone' get hirer->tele_priv pict '@!'
@ 17, 10 say '  Mobile Phone' get hirer->tele_mob pict '@!'
@ 18, 10 say 'Empl telephone' get hirer->tele_empl pict '@!'
@ 19, 10 say '    Occupation' get hirer->occupation
#ifdef RENTACENTRE
@ 20, 10 say '  Estate Agent' get hirer->agent
@ 21, 10 say '   Agent Phone' get hirer->agent_no
#else
 #ifdef ARGYLE
@ 21, 10 say '  Mobile Phone' get hirer->agent_no
 #endif
#endif
read
return

*

procedure hirersay ( pos_count )
cls
Heading( 'Hirer details on #' + Ns( hirer->con_no) )
Highlight( 01, 10, '  Hirer number', Ns( pos_count ) )
Highlight( 03, 10, ' Hirer Surname', hirer->surname )
Highlight( 05, 10, '    First name', hirer->first )
Highlight( 07, 10, 'Address line 1', hirer->add1 )
Highlight( 08, 10, '        line 2', hirer->add2 )
Highlight( 09, 10, '        Suburb', hirer->suburb )
Highlight( 09, 44, '      Postcode', hirer->pcode )
Highlight( 11, 10, ' Date of Birth', dtoc( hirer->dob ) )
Highlight( 12, 10, '    License no', hirer->license )
Highlight( 12, 44, '   Expiry date', dtoc( hirer->expiry_d ) )
#ifdef DISCOUNT
Highlight( 14, 10, ' Map Reference', hirer->car_rego )
#else
 #ifndef RENTACENTRE
  #ifndef ARGYLE
   #ifndef BYRNES
Highlight( 14, 10, '  Car rego no.', hirer->car_rego )
   #else
Highlight( 14, 10, '           CRN', hirer->car_rego )
   #endif
  #else
Highlight( 14, 10, 'Contr. Penalty', hirer->car_rego )
Highlight( 15, 10, '        E-Mail', hirer->email )
  #endif
 #else
Highlight( 14, 10, '        E-Mail', hirer->email )
 #endif
#endif
Highlight( 16, 10, 'Priv telephone', hirer->tele_priv )
Highlight( 17, 10, '  Mobile Phone', hirer->tele_mob )
Highlight( 18, 10, 'Empl telephone', hirer->tele_empl )
Highlight( 19, 10, '    Occupation', hirer->occupation )
#ifdef RENTACENTRE
Highlight( 20, 10, '  Estate Agent', hirer->agent )
Highlight( 21, 10, '   Agent Phone', hirer->agent_no )
#else
 #ifdef ARGYLE
Highlight( 21, 10, '  Mobile Phone', hirer->agent_no )
 #endif
#endif
return

*

procedure conget
local getlist := {}
Box_Save( 01, 02, 23, 78)
Heading( 'Contract Details' )
Highlight( 02, 03, '   Contract no' , Ns( master->con_no ) )
@ 03, 03 say '  Deposit book' get master->dep_no
@ 04, 03 say '    Days grace' get master->grace
@ 05, 03 say '     Commenced' get master->commenced
@ 06, 03 say '     Bond paid' get master->bond_paid
@ 07, 03 say '     Bond date' get master->bond_date
@ 08, 03 say '     Term rent' get master->term_rent pict '!' valid( master->term_rent $ 'MFDW')
@ 08, 30 say '<D,W,F,M>'
@ 09, 03 say 'Rentals period' get master->term_len
@ 10, 03 say '       Paid to' get master->paid_to
@ 11, 03 say ' Next inst due' get master->next_inst
@ 12, 03 say '    Instalment' get master->install
Highlight( 13, 03 ,'       Balance' , Ns( master->bal_bf ) )
@ 14, 03 say '      Location' get master->area
@ 15, 03 say '      Comments' get master->comments1
@ 16, 18 get master->comments2
@ 17, 03 say '     Reminders' get master->reminders pict 'Y'
#ifdef BYRNES
@ 18, 03 say 'Contract End Date' get master->EndDate
@ 19, 03 say 'Status' get master->status pict '@!' valid dup_chk( master->status, 'status' )
#endif

#ifdef INSURANCE
@ 18, 03 say '     Insurance' get master->insurance pict 'Y'
#endif

#ifdef MULTI_SITE
@ 19, 24 say Lookitup( 'sites', master->site )
@ 19, 03 say '          Site' get master->site pict '@!';
         valid( dup_chk( master->site, 'sites' ) )
#endif

#ifdef CREDIT_CARD
@ 20,03 say 'Card Number' get master->cred_card pict '@!'
@ 21,03 say 'Expiry Date' get master->expirydate pict '@!'
@ 21,25 say 'Card ID' get master->card_id pict '@!'
#endif

#ifdef MEDI
@ 21,45 say 'PO Number' get master->ponum pict '@!'
#endif

read
#ifdef MEDI
if master->billmethod = 'I'
 master->myobfirst := Lookitup( 'debtor', master->extra_key )

endif
#endif

return

*

procedure itemsay2
local level4:=savescreen()
cls
Heading( 'Item display screen' )
Highlight( 02, 01, '    Item Code', items->item_code )
Highlight( 04, 01, '     Model no', items->model )
Highlight( 05, 01, '  Description', items->desc )
Highlight( 06, 01, '    Serial no', items->serial )
Highlight( 07, 01, ' Product code', items->prod_code )
Highlight( 09, 01, '        Owner', LookItup( "owner" , items->owner_code ) )
Highlight( 10, 01, '       Status', st_status( items->status ) )
Highlight( 11, 01, '  Contract no', Ns( items->con_no ) )
Highlight( 03, 54, 'Rentals', '' )
Highlight( 04, 54, 'ÄÄÄÄÄÄÄ', '' )
Highlight( 05, 50, '    Monthly', Ns( items->m_rent ) )
Highlight( 06, 50, 'Fortnightly', Ns( items->f_rent ) )
Highlight( 07, 50, '     Weekly', Ns( items->w_rent ) )
Highlight( 08, 50, '      Daily', Ns( items->d_rent ) )
Highlight( 13, 01, '  Rentals YTD', Ns( items->rent_ytd ) )
Highlight( 14, 01, 'Rentals Total', Ns( items->rent_tot ) )
Highlight( 16, 01, '  Last rented', dtoc( items->last_rent ) )
Highlight( 17, 01, 'Last returned', dtoc( items->last_ret ) )
Highlight( 19, 01, 'Original cost', Ns( items->cost ) )
Highlight( 20, 01, 'Purchase date', dtoc( items->received ) )
Highlight( 21, 01, 'Warranty exp.', dtoc( items->warranty_d ) )
Highlight( 12, 48, 'Leasing Details', '' )
Highlight( 13, 40, '    Monthly payments', Ns( items->month_pay ) )
Highlight( 14, 40, '   Lease term (mths)', Ns( items->lease_term ) )
Highlight( 15, 40, '       Payments made', Ns( items->pay_made ) )
Highlight( 16, 40, '    Lease interest %', Ns( items->interest ) )
Highlight( 18, 40, '  Lease payments ytd', Ns( items->pay_ytd ) )
Highlight( 19, 40, 'Lease payments total', Ns( items->pay_tot ) )
Highlight( 21, 40, '   Rule of 78 payout', Ns( Rule_78( items->cost, items->lease_term, items->pay_made, items->month_pay ) ) )
return

*

static function item_index ( row )
if items->( indexord() ) = 1
 items->( ordsetfocus( 'serial' ) )
else
 items->( ordsetfocus( 'item_code' ) )
endif
It_ord_disp( row )
return nil

*
function it_ord_disp ( row )
local mscr := Box_Save( row+1, 2, row+4, 24 )
if items->( indexord() ) = 1
 @ row+2,3 say 'Seek using Item no'
else
 @ row+2,3 say 'Seek using Serial no'
endif
@ row+3,3 say 'Hit <F10> to Switch'
return mscr

*

Function ChkDepBook ( cDepBook )
local lOK := TRUE
local nIndexOrd := master->( indexord() )
local nRecord := master->( recno() )
master->( ordsetfocus( 'deposit' ) )
#ifdef ARGYLE
if !empty( cDepBook ) .and. master->( dbseek( cDepBook ) )
#else
if master->( dbseek( cDepBook ) )
#endif
 lOk := Isready( 12, 10, 'Deposit Book No ' + trim( cDepBook ) + ' is already on Contract #';
              + Ns( master->con_no ) + ' Accept anyway?' )

endif
master->( dbsetorder( nIndexOrd ) )
master->( dbgoto( nRecord ) )
return lOK
