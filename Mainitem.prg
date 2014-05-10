/*

 Rentals - Bluegum Software

 Module mainitem - Item maintenance
 
 Last change:  TG   17 May 2001    8:04 am

      Last change:  TG   14 Mar 2011    2:17 pm
*/

#include "winrent.ch"

Function Mainitem

local ok := FALSE, getlist:={}, loopval, choice, mcode, mowner, mowner2

local mowner1, newloop, mnext, aArray

local oldscr := Box_Save()
local mtemp
local cScr

if NetUse( "hirer" )
 if NetUse( "stkhist" )
  if NetUse( "owner" )
   if NetUse( "items" )
    items->( ordsetfocus( 'item_code' ) )
    set relation to items->owner_code into owner,;
                 to items->con_no into hirer
    ok := TRUE
   endif
  endif
 endif
endif

while ok

 Box_Restore( oldscr )
 Heading( 'Stock file maintenance' )

 aArray := {}
 aadd( aArray, { 'Exit', 'Return to main menu' } )
 aadd( aArray, { 'Add', 'Add new stock items' } )
 aadd( aArray, { 'Change', 'Change stock details' } )
 aadd( aArray, { 'Owner', 'Change owner details for item' } )
 aadd( aArray, { 'Delete', 'Delete old stock items' } )
 aadd( aArray, { 'History', 'Modify Stock Histories' } )
 choice := MenuGen( aArray, 04, 13, 'Item' )

 do case
 case choice = 2 .and. Secure( X_ADDFILES )
  loopval := TRUE

  while loopval
   mcode = space(10)

   Box_Save( 02, 08, 12, 72 )
   Heading( 'Add new stock Item' )
   mcode := space( 10 )
   @ 3,10 say 'Enter item code to add' get mcode pict '@!'
   mnext := Ns( Bvars( B_ITEM_NO ), 8 )
   Highlight( 5, 10, 'Next sequential code would be ', mnext )
   read
   if !updated()
    loopval := FALSE

   else
    if items->( dbseek( mcode ) )
     Highlight( 07, 10, 'Description', items->desc )
     Highlight( 09, 10, '     Serial', items->serial )
     Error('Item number already on file',12)

    else
     mowner := Bvars( B_DEF_OWNER )
     while TRUE
      @ 7,10 say 'Enter owner code' get mowner pict '@!'
      read
      if lastkey() = K_ESC
       exit
      endif

      if !owner->( dbseek( mowner ) )
       Error('Owner code not on file ',12)

      else
       Add_rec( 'items' )
       items->owner_code := mowner
       items->item_code := mcode
       items->status := 'O'
       items->con_no := 0
       Itemget()
       if !updated()
        items->( dbdelete() )
       else
        if mcode = mnext
         mtemp := val( mcode )
         Bvars( B_ITEM_NO, ++mtemp )
         BvarSave()
        endif
#ifdef RENTACENTRE
        Audit( 0, 'I', 0, items->item_code )
#endif
       endif
       items->( dbrunlock() )
       exit
      endif
     enddo
    endif
   endif
  enddo

 case choice = 3 .and. Secure( X_EDITFILES )

  loopval := TRUE

  while loopval
   mcode = space(10)

   Heading( 'Change item Details' )
   @ 7,21 say 'ÍÍ¯Item no to edit' get mcode pict '@!'
   read
   if !updated()
    loopval := FALSE

   else
    if !items->( dbseek( mcode ) )
     Error( 'Item code not found', 12 )

    else
     Rec_lock( 'items' )
     Itemget()
     items->( dbrunlock() )

    endif

   endif
  enddo

 case choice = 4 .and. Secure( X_EDITFILES )
  loopval := TRUE

  while loopval
   mcode = space(10)

   Heading('Change owner code on item')
   mowner1 = space(3)
   @ 08,21 say 'ÍÍÍ¯ Owner code to change from' get mowner1 pict '@!'
   read
   if !updated()
    loopval := FALSE

   else
    if !owner->( dbseek( mowner1 ) )
     Error( 'Owner code not found', 12 )

    else
     mowner2 = space(3)
     Box_Save( 2, 08, 15, 72 )
     Highlight( 3, 10, 'Old owner ', owner->name )

     @ 5,10 say 'Owner code to change to' get mowner2 pict '@!'
     read

     if updated()
      if !owner->( dbseek( mowner2 ) )
       Error('New owner code is not on file',12)

      else
       Box_Save( 05, 09, 14, 71 )
       Highlight( 5, 10, 'New owner', owner->name )
       newloop := TRUE
       while newloop
        @ 7,09 clear to 14,71
        Heading('Change owner code on item')
        mcode = space(10)
        @ 7,10 say 'Item code to change' get mcode pict '@!'
        read
        if !updated()
         newloop := FALSE

        else
         if !items->( dbseek( mcode ) )
          Error( 'Item Code not on found', 12 )
         else

          if items->owner_code != mowner1
           Error( 'Item owner does not match old owner', 12 )
          else

           Highlight( 09, 10, 'Model       ', items->model )
           Highlight( 11, 10, 'Serial      ', items->serial )
           Highlight( 13, 10,' Description ', items->desc )

           if Isready( 'Ok to change this item' )

            Rec_lock( 'items' )
            items->owner_code := mowner2
            items->( dbrunlock() )

           endif
          endif
         endif
        endif
       enddo
      endif
     endif
    endif
   endif
  enddo
 case choice = 5 .and. Secure( X_DELFILES )
  loopval := TRUE

  while loopval
   mcode = space(10)

   Heading( 'Delete item' )
   @ 9,21 say 'ÍÍÍ¯Item code to delete' get mcode pict '@!'
   read
   if !updated()
    loopval := FALSE
   else
    if !items->( dbseek( mcode ) )
     Error( 'Item code not on file', 12 )

    else
     Box_Save( 04, 08, 15, 72 )
     if items->status != 'O'
      Highlight( 05, 10, '      Model', items->model )
      Highlight( 07, 10, 'Description', items->desc )
      Highlight( 09, 10, '  Serial no', items->serial )
      Highlight( 11, 10, 'This item rented on contract no. ', Ns(items->con_no) )
      @ 13,10 say '    it cannot be deleted'
      Error('Item not on-hand',15)

     else
      Highlight( 05, 10, 'Model       ', items->model )
      Highlight( 07, 10, 'Description ', items->desc )
      Highlight( 09, 10, 'Serial no.  ', items->serial )
      if Isready()
       Rec_lock( 'items' )
       items->( dbdelete() )
       items->( dbrunlock() )

#ifdef RENTACENTRE
       Audit( 0, 'M', 0, '', mcode )
#endif

       stkhist->( dbseek( mcode ) )
       while stkhist->item_code = mcode .and. !stkhist->( eof() )
        Rec_lock( 'stkhist' )
        stkhist->( dbdelete() )
        stkhist->( dbrunlock() )
        stkhist->( dbskip() )
       enddo

      endif
     endif
    endif
   endif
  enddo
 case choice = 6 .and. Secure( X_EDITFILES )
  loopval := TRUE
  cScr := Box_Save()
  while loopval
   Box_Restore( cScr )
   mcode = space(10)

   Heading('Update Item History')
   @ 10,22 SAY 'ÍÍ¯Enter Item No to Edit ' get mcode pict '@!'
   read
   if !updated()
    loopval := FALSE
   else
    if !items->( dbseek( mcode ) )
     Error( 'Items Code not on file', 12 )

    else
     cls
     Heading( 'Item File Inquiry' )
     Highlight( 03, 01, '   Item code', items->item_code )
     Highlight( 05, 01, '    Model No', items->model )
     Highlight( 06, 01, ' Description', items->desc )
     Highlight( 07, 01, '   Serial No', items->serial )
     Highlight( 08, 01, 'Product Code', items->prod_code )
     Highlight( 09, 01, '       Owner', items->owner_code )
     Highlight( 11, 01, '      Status', st_status( items->status ) )
     Highlight( 12, 01, 'Contract No.', items->con_no )
     @ 03,54 say 'Rentals'
     @ 04,54 say '-------'
     Highlight( 05, 50, '    Monthly', Ns( items->m_rent ) )
     Highlight( 06, 50, 'Fortnightly', Ns( items->f_rent ) )
     Highlight( 07, 50, '     Weekly', Ns( items->w_rent ) )
     Highlight( 08, 50, '      Daily', Ns( items->d_rent ) )

     Add_rec( 'stkhist' )
     stkhist->item_code := items->item_code
     @ 14,01 say '      Date' get stkhist->returned
     @ 15,01 say ' Invoice #' get stkhist->name
     @ 16,01 say '     Fault' get stkhist->address1
     @ 17,01 say '      Cost' get stkhist->address2
     @ 18,01 say 'Technician' get stkhist->suburb
     @ 19,01 say '   Details' get stkhist->details
     read
     if !updated()
      stkhist->( dbdelete() )
      Error( 'No Data Added - Record not added to History' ,12 )
     endif
     stkhist->( dbrunlock() )

    endif
   endif
  enddo
 case choice < 2
  ok := FALSE
 endcase
enddo

dbcloseall()
return nil

*

procedure itemget
local getlist:={}
local bKF4        // Old F4 Key
local okaf10 := setkey( K_ALT_F10, { || ItemContEdit() } )
local okaf7 := setkey( K_ALT_F10, { || ItemContEdit() } )
local mscr := Box_Save(), cItemStatus := items->status
cls
Heading( 'Item Editing Screen' )
Highlight( 02, 04, 'Item code', items->item_code )
@ 04,01 say '    Model no' get items->model pict '@!'
@ 05,01 say ' Description' get items->desc pict '@!'
@ 06,01 say '   Serial no' get items->serial pict '@!'
#ifdef VALIDATE_PRODCODE
@ 07,01 say 'Product code' get items->prod_code pict '@!' valid( dup_chk( items->prod_code, 'prodcode' ) )
#else
@ 07,01 say 'Product code' get items->prod_code pict '@!'
#endif
#ifdef MEDI
@ 08,01 say 'MYOB Code' get items->MYOBCode pict '@!' valid( dup_chk( items->myobcode, 'myobcode' ) )
#endif
Highlight( 09, 08, 'Owner', Lookitup( "owner" , items->owner_code ) )

#ifdef ARGYLE
@ 10, 07 say 'Status' get items->status valid( dup_chk( items->status, 'status' ) )
Highlight( 10, 18, '', LookItUp( 'status', items->Status ) )

#else
@ 10, 07 say 'Status' get items->status when items->con_no <= 0 pict '!' ;
         valid( items->status $ 'TSCORW' )

HighFirst( 11, 0, 'Theft Sold ClearOut Onhand Repair Writeoff' )

Highlight( 10, 18, '', st_status( items->status ) )

#endif
Highlight( 12, 07, 'Account No', items->con_no )
Highlight( 03, 53, '', 'Rental Amounts' )
@ 04,55 say '    Monthly' get items->m_rent pict '999.99' valid( items->m_rent > 0)
@ 05,55 say 'Fortnightly' get items->f_rent pict '999.99' valid( items->f_rent > 0)
@ 06,55 say '     Weekly' get items->w_rent pict '999.99' valid( items->w_rent > 0)
@ 07,55 say '      Daily' get items->d_rent pict '999.99' valid( items->d_rent > 0)
@ 08,45 say 'All rental Amount fields must have a value!'

#ifdef INSURANCE
@ 03,69 say 'Ins.'
@ 04,73 get items->insurance pict '999.99'
#endif

@ 13,01 say '  Rentals YTD' get items->rent_ytd pict '99999.99'
@ 14,01 say 'Rentals total' get items->rent_tot pict '99999.99'
@ 16,01 say '  Last rented' get items->last_rent
@ 17,01 say 'Last returned' get items->last_ret
@ 19,01 say 'Original cost' get items->cost
@ 20,01 say 'Purchase date' get items->received
@ 21,01 say 'Warranty exp.' get items->warranty_d

Highlight( 10, 53, '', 'Leasing details' )
@ 11,45 say '    Monthly payments' get items->month_pay pict '99999.99'
@ 12,45 say '   Lease term (mths)' get items->lease_term pict '99'
@ 13,45 say '       Payments made' get items->pay_made pict '99'
@ 14,45 say '    Lease Interest %' get items->interest pict '99.99'
@ 15,45 say '  Lease payments ytd' get items->pay_ytd pict '99999.99'
@ 16,45 say 'Lease payments total' get items->pay_tot pict '99999.99'

#ifdef ASSETS
if assets
 Highlight( 17, 46 , '' , 'Fixed Asset Information' )
 @ 18,40 say "   Date into Service" get items->serv_date
 @ 19,40 say " Depreciation Method" get items->depr_mthd pict "!" valid( items->depr_mthd $ 'SD' )
 @ 19,65 say "<S>tL,<D>ecYear"
 @ 20,40 say "    Depreciable Life" get items->depr_life
 @ 21,40 say "       Salvage Value" get items->salvage pict "9999999.99";
         valid( items->salvage <= items->cost )
 @ 22,37 SAY 'Must be less than or equal to Cost'
endif
#endif

bKF4 := setkey( K_F4, { || Abs_edit( 'items', nil, TRUE ) } )   // Abs with record locked!

read

setkey( K_F4, bKF4 )

#ifdef RENTACENTRE
if cItemStatus != items->Status
 Audit( 0, MACHINE_MOVEMENT, 0, St_Status( items->status ), items->item_code )
endif
if updated()
 Audit( items->con_no, ITEM_FILE_CHANGED, 0, '', items->item_code )
endif
#endif
setkey( K_ALT_F10, okaf10 )
Oddvars( LASTITEM, items->item_code )
Box_Restore( mscr )
return

*

Static Function ItemContEdit
local mscr := Box_Save( 3, 10, 5, 40 )
local getlist := {}
local oldcon := items->con_no
@ 4, 12 say 'New Contract Number' get items->con_no pict '9999999'
read
Box_Restore( mscr )
SysAudit( 'ItemContNumChange' + Ns( oldcon ) + '/' + Ns( items->con_no ) )
return nil


*

procedure itemsay ( mfile )
local mscr := Box_Save()
local owner_not_open := ( select( 'owner' ) = 0 )

default mfile to 'items'
cls

Heading( 'Item Details' )
Highlight( 02, 01, '    Item Code', ( mfile )->item_code )
Highlight( 04, 01, '     Model no', ( mfile )->model )
Highlight( 05, 01, '  Description', ( mfile )->desc )
Highlight( 06, 01, '    Serial no', ( mfile )->serial )
Highlight( 07, 01, ' Product code', ( mfile )->prod_code )
#ifdef MEDI
Highlight( 08, 01, '    MYOB Code', Trim( ( mfile )->MYOBCode ) + ' ' + lookitup( 'MyobCode', (mfile)->MyobCode ) )
#endif
Highlight( 09, 01, '        Owner', LookItup( "owner" , ( mfile )->owner_code ) )
#ifdef ARGYLE
Highlight( 10, 01, '       Status', LookItUp( "status", ( mfile )->status ) )
#else
Highlight( 10, 01, '       Status', st_status( ( mfile )->status ) )
#endif
Highlight( 11, 01, '  Contract no', Ns( ( mfile )->con_no ) )
Highlight( 01, 54, 'Rentals' , '' )
Highlight( 02, 54, 'ÄÄÄÄÄÄÄ' , '' )
Highlight( 03, 50, '    Monthly', Ns( ( mfile )->m_rent ) )
Highlight( 04, 50, 'Fortnightly', Ns( ( mfile )->f_rent ) )
Highlight( 05, 50, '     Weekly', Ns( ( mfile )->w_rent ) )
Highlight( 06, 50, '      Daily', Ns( ( mfile )->d_rent ) )
#ifdef INSURANCE
Highlight( 04, 69,'Ins.',Ns( ( mfile )->insurance ) )
#endif
Highlight( 13, 01, '  Rentals YTD', Ns( ( mfile )->rent_ytd ) )
Highlight( 14, 01, 'Rentals Total', Ns( ( mfile )->rent_tot ) )
Highlight( 16, 01, '  Last rented', dtoc( ( mfile )->last_rent ) )
Highlight( 17, 01, 'Last returned', dtoc( ( mfile )->last_ret ) )
Highlight( 19, 01, 'Original cost', Ns( ( mfile )->cost ) )
Highlight( 20, 01, 'Purchase date', dtoc( ( mfile )->received ) )
Highlight( 21, 01, 'Warranty exp.', dtoc( ( mfile )->warranty_d ) )
Highlight( 08, 48, 'Leasing Details', '' )
Highlight( 09, 40, '    Monthly payments', Ns( ( mfile )->month_pay ) )
Highlight( 10, 40, '   Lease term (mths)', Ns( ( mfile )->lease_term ) )
Highlight( 11, 40, '       Payments made', Ns( ( mfile )->pay_made ) )
Highlight( 12, 40, '    Lease interest %', Ns( ( mfile )->interest ) )
Highlight( 13, 40, '  Lease payments ytd', Ns( ( mfile )->pay_ytd ) )
Highlight( 14, 40, 'Lease payments total', Ns( ( mfile )->pay_tot ) )
Highlight( 15, 40, '   Rule of 78 payout', Ns( Rule_78( ( mfile )->cost, ( mfile )->lease_term, ;
          ( mfile )->pay_made, ( mfile )->month_pay ) ) )

#ifdef ASSETS
 store 0 TO mcurr,mytd,maccum
 mdate := bdate
 Fadepr( mdate, mcurr, mytd, maccum )

//-----* Calculate month and year that depreciation ends
 end_mnth  :=  if( month( serv_date ) = 1, 12, month( serv_date )-1 )
 end_year  :=  year( serv_date ) + depr_life + if( month( serv_date ) = 1, -1, 0 )
 end_date  :=  str( end_mnth, 2 ) + "/" + str( end_year, 4 )

//-----* Calculate remaining undepreciated balance for asset
 mremain  :=  cost - maccum - salvage

//-----* Display dep. info for asset
 Highlight( 17, 34, "             Current Month", cmonth(mdate)+" "+str( year( mdate ) ) )
 Highlight( 18, 34, "   End of Depreciable Life", end_date )
 Highlight( 19, 34, "Current Month Depreciation", Ns( mcurr, 10, 2 ) )
 Highlight( 20, 34, "              Year to Date", Ns( mytd, 10, 2 ) )
 Highlight( 21, 34, "  Accumulated Depreciation", Ns( maccum, 10, 2 ) )
 Highlight( 22, 34, "     Undepreciated Balance", Ns( mremain, 10, 2 ) )

#endif

Error('')

if lastkey() = K_F12
 Print_screen()

endif

if lastkey() = K_F4
 abs_edit( 'items' )

endif

Box_Restore( mscr )

if owner_not_open .and. ( select( 'owner' ) != 0 )

 owner->( dbclosearea() )

endif

oddvars( LASTITEM, (mfile)->item_code )

return


