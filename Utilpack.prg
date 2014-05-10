/*

  Rentals - Bluegum Software

  Module utilpack - Pack Files

  Last change:  TG    1 May 2008   10:50 pm

      Last change:  TG   26 Jan 2012    7:34 pm
*/

#include "winrent.ch"

Function Utilpack ( goforit, must_index )

local start_time, finish_time, getlist:={}, elapsed, packindx := 'Pack'

default goforit to FALSE
default must_index to FALSE

packindx := if( must_index, 'Index', 'Pack' )

Heading( packindx + ' Files' )

if goforit .or. Isready( )
 
 dbcloseall()

 if must_index
  aeval( directory( '*.' + ordbagext() ), { | del_element | ferase( del_element[ 1 ] ) } )
 endif

 start_time=seconds()

 cls
 Heading( 'File ' + packindx + 'ing in Progress' )
 @ 1, 0 say ''

 if NetUse( "master", EXCLUSIVE, 10 )
  PackStat( packindx, 'Master Contract File' )

  if !file( Oddvars( SYSPATH ) + 'master' + indexext() ) .or. must_index
   indx( 'con_no', 'contract' )
   indx( 'dep_no', 'deposit' )
   indx( 'site' , 'site' )

  else
   pack

  endif 

 endif

 if NetUse( "hirer", EXCLUSIVE, 10 )
  PackStat( packindx, 'Hirer file' )

  if !file( Oddvars( SYSPATH ) + 'hirer' + indexext() ) .or. must_index
   indx( 'con_no', 'contract' )
   #ifndef SQL
   indx( 'upper( surname )', 'surname' )
   indx( 'upper( suburb )', 'suburb' )
   #else
   indx( 'surname', 'surname' )
   indx( 'suburb', 'suburb' )
   #endif
   indx( 'tele_priv', 'phone' )
   indx( 'add1', 'address' )
   indx( 'tele_mob', 'mobile' )

  else
   pack
   
  endif 

 endif

 if NetUse("items",EXCLUSIVE,10)
  PackStat( packindx, 'Items file')

  if !file( Oddvars( SYSPATH ) + 'items' + indexext() ) .or. must_index
   indx( 'item_code', 'item_code' )
   indx( 'serial', 'serial' )
   indx( 'model', 'model' )
   indx( 'con_no', 'contract' )
   indx( 'status + item_code', 'status' )
   indx( 'prod_code', 'prod_code' )

  else
   pack

  endif

 endif

 if NetUse("tran",EXCLUSIVE,10)
  PackStat( packindx, 'Transaction File' )

  if !file( Oddvars( SYSPATH ) + 'tran' + indexext() ) .or. must_index
   indx( 'con_no', 'contract' )
   indx( 'date', 'date' )
#ifdef MEDI
   indx( 'dtos( date ) + paytype', 'paytype' )
#endif

  else
   pack

  endif

 endif

 if NetUse( "arrears", EXCLUSIVE, 10 )
  PackStat( packindx, 'Arrears file' )

  if !file( Oddvars( SYSPATH ) + 'arrears' + indexext() ) .or. must_index
   indx( 'con_no', 'contract' )

  else
   pack
   
  endif

 endif

 if NetUse( "owner", EXCLUSIVE, 10 )
  PackStat( packindx, 'Owner file' )

  if !file( Oddvars( SYSPATH ) + 'owner' + indexext() ) .or. must_index
   indx( 'code', 'code' )

  else
   pack

  endif
 endif

 if NetUse( "prodcode", EXCLUSIVE, 10 )
  PackStat( packindx, 'Product Code file' )

  if !file( Oddvars( SYSPATH ) + 'prodcode' + indexext() ) .or. must_index
   indx( 'code', 'code' )

  else
   pack

  endif
 endif

 if NetUse( "Status", EXCLUSIVE, 10 )
  PackStat( packindx, 'Contract Status' )

  if !file( Oddvars( SYSPATH ) + 'status' + indexext() ) .or. must_index
   indx( 'code', 'code' )

  else
   pack

  endif
 endif


 if NetUse("stkhist",EXCLUSIVE,10)
  PackStat( packindx, 'Stock history file' )

  if !file( Oddvars( SYSPATH ) + 'stkhist' + indexext() ) .or. must_index
   indx( 'item_code', 'item_code' )

  else
   pack

  endif 

 endif

 if NetUse( "audit", EXCLUSIVE, 10 )
  PackStat( packindx, 'Audit History file' )

  if !file( Oddvars( SYSPATH ) + 'audit' + indexext() ) .or. must_index
   indx( 'con_no', 'contract' )

  else
   pack

  endif 

 endif

 if NetUse("operator",EXCLUSIVE,10)
  PackStat( packindx, 'Operator File file' )

  if !file( Oddvars( SYSPATH ) + 'operator' + indexext() ) .or. must_index
   indx( 'code', 'code' )

  else
   pack

  endif 

 endif

 if NetUse( "sites", EXCLUSIVE, 10 )
  PackStat( packindx, 'Sites file' )

  if !file( Oddvars( SYSPATH ) + 'sites' + indexext() ) .or. must_index
   indx( 'code', 'code' )

  else
   pack

  endif 

 endif

 if NetUse( "truck", EXCLUSIVE, 10 )
  Packstat( packindx, 'Trucks file' )

  if !file( Oddvars( SYSPATH ) + 'truck' + indexext() ) .or. must_index
   indx( 'code', 'code' )

  else
   pack

  endif 

 endif

 if NetUse( "trukbook", EXCLUSIVE, 10 )
  PackStat( packindx, 'Truck Booking file' )

  if !file( Oddvars( SYSPATH ) + 'trukbook' + indexext() ) .or. must_index
   indx( 'dtos( date ) + truck', 'date' )

  else
   pack

  endif 

 endif

 if NetUse( "PayType", EXCLUSIVE, 10 )
  PackStat( packindx, 'Payment Types file' )

  if !file( Oddvars( SYSPATH ) + 'PayType' + indexext() ) .or. must_index
   indx( 'code', 'code' )

  else
   pack

  endif 

 endif



#ifdef MEDI

 if NetUse( "MyobImpo", EXCLUSIVE, 10 )
  PackStat( packindx, 'MYOB Lookup file' )

  if !file( Oddvars( SYSPATH ) + 'MYOBImpo' + indexext() ) .or. must_index
   indx( 'code', 'code' )

  else
   pack

  endif 

 endif

 if NetUse( "MYOBCode", EXCLUSIVE, 10 )
  PackStat( packindx, 'MYOB Code file' )

  if !file( Oddvars( SYSPATH ) + 'MYOBCode' + indexext() ) .or. must_index
   indx( 'code', 'code' )

  else
   pack

  endif 

 endif

#endif

 dbcloseall()

 finish_time := seconds()
 if finish_time < start_time
  elapsed := ( 86399-finish_time ) + start_time

 else
  elapsed := finish_time-start_time

 endif
 if elapsed > 60
  ?
  ? "Time for " + packindx + " = " + str( elapsed / 60, 2 ) + " minutes " + ;
     str( elapsed % 60, 2 )+" seconds"

 else
  ?
  ? "Time for " + packindx + " = " + str( elapsed % 60 , 2 ) + " seconds"

 endif
 Error("")
// cls
 set escape on
endif

return nil

*

// function indx ( mindexkey, mtag, munique )

// default munique to FALSE

function indx ( mindexkey, mtag, cAlias, lIsUnique )

default lIsUnique to FALSE
default cAlias to alias()
//index on (mindexkey) tag (mtag) to (calias)
 Ordcreate( oddvars( SYSPATH ) + cAlias, mtag, mindexkey, { || &mindexkey }, lIsUnique )


return nil

*

Function PackStat ( cType, cDesc )
? cType + Padr( 'ing ' + cDesc, 25 ) + str( reccount() ) + ' records'
return nil

