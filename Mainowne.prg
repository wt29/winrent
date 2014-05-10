/*

 Rentals - Bluegum Software
 Module Mainowne - Owner Maintenance

 Last change:  TG    9 Apr 2001    7:41 am

      Last change:  TG   18 Oct 2010   10:53 pm
*/

#include "winrent.ch"

Function Mainowne

local ok := FALSE, getlist:={}, mown, choice, loopval
local aArray, cOldOwner, cNewOwner
local oldscr := Box_Save()

if NetUse( "items" )

 if NetUse( "owner"  )

  ok := TRUE

 endif
//
endif

while ok

 Box_Restore( oldscr )
 Heading('Owner File Maintenance')

 aArray := {}
 aadd( aArray, { 'Exit', 'Exit to file menu' } )
 aadd( aArray, { 'Add', 'Add new owners' } )
 aadd( aArray, { 'Change', 'Change owner details' } )
 aadd( aArray, { 'Delete', 'Delete old owners' } )
 aadd( aArray, { 'Global', 'Change all items on old owner to new' } )
 choice := MenuGen( aArray, 05, 13, 'Owner' )

 if choice < 2
  exit
 endif
 
 mown = space(3)

 do case
 case choice = 2 .and. Secure( X_ADDFILES )

  Heading('Add New Owner')
  Box_Save( 06, 21, 08, 40 )
  @ 07,22 say 'New Owner Code' get mown pict '@!'
  read
  if !updated()
   exit
    
  else
   if owner->( dbseek( mown ) )
    Error( 'Owner ' + trim( owner->name ) + ' already on file', 12 )

   else

    Add_rec( 'owner' )
    owner->code := mown
    Box_Save( 02, 09, 11, 71 )
    @ 03,11 say '          Name' get owner->name
    @ 05,11 say '       Address' get owner->add1
    @ 06,11 say '              ' get owner->add2
    @ 08,11 say "      Phone No" get owner->phone pict '@!'
    @ 10,11 say '  Contact name' get owner->contact
    read
    if !updated() .or. empty( owner->name )
     owner->( dbdelete() )
     Error( 'No name details filled in - record deleted', 12 )
    endif 

    owner->( dbrunlock() )

   endif
  endif

 case choice = 3 .and. Secure( X_EDITFILES )
  Heading('Change Owner details')
  Box_Save( 07, 21, 09, 40 )
  @ 08,22 say 'Owner code' get mown pict '@!'
  read
  if updated()

   if !owner->( dbseek( mown ) )
    Error( 'Owner code ' + trim( mown ) + ' not on file', 12 )

   else
    Rec_lock( 'owner' )
    Box_Save( 02, 09, 11, 71 )
    @ 03,11 say '          Name' get owner->name valid !empty( owner->name )
    @ 05,11 say '       Address' get owner->add1
    @ 06,11 say '              ' get owner->add2
    @ 08,11 say "      Phone No" get owner->phone pict '@!'
    @ 10,11 say '  Contact name' get owner->contact
    read
    owner->( dbrunlock() )

   endif
  endif

 case choice = 4 .and. Secure( X_DELFILES )
  Heading('Delete owner')
  Box_Save( 08, 21, 10, 40 )
  @ 09,22 say 'Owner code' get mown pict '@!'
  read

  if updated()

   if !owner->( dbseek( mown ) )
    Error('Owner no not on file',12)

   else

    select items
    locate for items->owner_code = mown .and. items->status != 'D'
    if found()
     Error( 'Items still present for owner - cannot delete', 12 )

    else

     owner->( dbseek( mown ) )

     Box_Save( 03, 08, 11, 72 )
     Highlight( 5, 10, 'Owner name', owner->name )
     Highlight( 7, 10, '   Address', owner->add1 )

     if Isready( 'Is this the owner to delete' )

      Rec_lock( 'owner' )
      owner->( dbdelete() )
      owner->( dbrunlock() )
      Error( "Owner '" + mown + "' Deleted!", 12 )

     endif
    endif
   endif
  endif

 case choice = 5 .and. Secure( X_EDITFILES )
  Heading('Change all items on one owner to another')

  cOldOwner = space( OWNER_CODE_LEN )
  Box_Save( 10, 22, 12, 55 )
  @ 11,23 say 'Owner code to change from' get cOldOwner pict '@!'
  read

  if !updated()
   loopval := FALSE

  else
   if !owner->( dbseek( cOldOwner ) )
    Error( 'Owner code not found', 12 )

   else
    cNewOwner = space( OWNER_CODE_LEN )
    Box_Save( 2, 08, 15, 72 )
    Highlight( 3, 10, 'Old owner ', owner->name )

    @ 5,10 say 'Owner code to change to' get cNewOwner pict '@!'
    read

    if updated()
     if !owner->( dbseek( cNewOwner ) )
      Error( 'New owner code is not on file', 12 )

     else
      Highlight( 5, 10, '      New owner code ', owner->name )
      if Isready( 12 )
       items->( dbgotop() )
       while ! items->( eof() )
        Highlight( 7, 10, 'Item Code', items->item_code )
        if items->owner_code = cOldOwner
         Rec_lock( 'items' )
         items->owner_code := cNewOwner
         items->( dbrunlock() )

        endif
        items->( dbskip() )

       enddo

      endif

     endif

    endif

   endif

  endif

 endcase

enddo
dbcloseall()
return nil
