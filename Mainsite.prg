/*

 Rentals - Bluegum Software
 Module Mainsite - Site Maintenance

 Last change:  TG    9 Apr 2001    7:49 am

      Last change:  TG   18 Oct 2010   10:53 pm
*/

#include "winrent.ch"

Function Mainsite

local ok := FALSE, getlist:={}, msite, choice
local aArray, cNewSite, cOldSite
local oldscr := Box_Save()
local nRepCount

if NetUse( "master" )
 master->( ordsetfocus( "site" ) )

 if NetUse( "sites" )
  set relation to sites->code into master

  ok := TRUE

 endif

endif

while ok

 Box_Restore( oldscr )
 Heading('Site file maintenance')

 aArray := {}
 aadd( aArray, { 'Exit', 'Exit to file menu' } )
 aadd( aArray, { 'Add', 'Add new sites' } )
 aadd( aArray, { 'Change', 'Change Site details' } )
 aadd( aArray, { 'Delete', 'Delete Sites' } )
 aadd( aArray, { 'Master', 'Exchange site codes on the master file' } )
 choice := MenuGen( aArray, 06, 13, 'Sites' )

 if choice < 2
  exit
 
 endif
 
 msite = space( SITELEN )

 do case
 case choice = 2 .and. Secure( X_ADDFILES )
  Heading('Sites File add')
  @ 08,22 say 'ÍÍ¯ New Site Code' get msite pict '@!'
  read
  if !updated()
   exit
    
  else
   if sites->( dbseek( msite ) )
    Error( 'Site ' + trim( sites->name ) + ' already on file', 12 )

   else
    Add_rec( 'sites' )
    sites->code := msite
    Box_Save( 02, 09, 11, 71 )
    @ 03,11 say '          Name' get sites->name
    read
    if !updated() .or. empty( sites->name )
     sites->( dbdelete() )
     Error( 'No name details filled in - record deleted', 12 )

    endif 

    sites->( dbrunlock() )

   endif
  endif

 case choice = 3 .and. Secure( X_EDITFILES )
  Heading('Change sites details')
  @ 09,22 say 'ÍÍÍ¯ Site code' get msite pict '@!'
  read
  if updated()

   if !sites->( dbseek( msite ) )
    Error( 'Site code ' + trim( msite ) + ' not on file', 12 )

   else
    Rec_lock( 'sites' )
    Box_Save( 02, 09, 04, 71 )
    @ 03,11 say '          Name' get sites->name valid !empty( sites->name )
    read
    sites->( dbrunlock() )
    

	endif
  endif
 
 case choice = 4 .and. Secure( X_DELFILES )
  Heading('Delete Sites')
  @ 10,22 say 'ÍÍ¯ Site Code' get msite pict '@!'
  read

  if updated()

   if !sites->( dbseek( msite ) )
    Error('Site code not on file',12)

   else

    sites->( dbseek( msite ) )
    Box_Save( 03, 08, 11, 72 )
    Highlight( 5, 10, 'Site name', sites->name )

    if Isready( 'Is this the site code to delete' )

     Rec_lock( 'sites' )
     sites->( dbdelete() )
     sites->( dbrunlock() )
     Error( "Site code '" + msite + "' Deleted!", 12 )

    endif
   endif
  endif
 

 case choice = 5 .and. Secure( X_EDITFILES )
  Heading('Change Site Codes on master file')
  Box_Save( 02, 09, 06, 71 )
  cOldSite := space( SITELEN )
  cNewSite := space( SITELEN )
  @ 03, 11 say 'Old Site Code' get cOldSite pict '@!' 
  @ 04, 11 say 'New Site Code' get cNewSite pict '@!'
  read

  if updated()

   if !sites->( dbSeek( cNewSite ) )
    Error( 'New Site code not on file',12 )

   else
	nRepCount := 0
    if IsReady( 'You are about to change all occurences of site code ' + cOldSite + ' on the master file with site code ' + cNewSite )
     while master->( dbseek( cOldSite ) )
	  Rec_lock( 'master' )
	  @ 5, 11 say 'Contract ' + Ns( master->con_no )
	  replace master->site with cNewSite
	  nRepCount++
      master->( dbrunlock() )
	   
	 enddo
	 Error( 'Replaced Site code ' + cOldSite + ' with Site code ' + cNewSite + ' on ' + ns( nRepCount ) + ' Master file records', 12 )

    endif 
   
   endif
 
  endif
  
 endcase

enddo
dbcloseall()
return nil
