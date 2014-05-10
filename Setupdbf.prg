/*
  Setupdbfs will create dbfs for a new site.

      Last change:  TG   14 Mar 2011    2:55 pm
*/

#include "winrent.ch"

function setupdbfs
local lOK := FALSE, mdbfarr
local x, mfilepath := Oddvars( SYSPATH )
local getlist:={}

cls
@ 3, 04 say SYSNAME + ' has detected no Database files on this system.'
@ 5, 04 say 'This section will set up the Database files required to run ' + SYSNAME
@ 6, 04 say SYSNAME + ' will exit after creation - you will need to restart!'
@ 8, 04 say 'Ok to create Database files' get lOK picture "Y"
read

if lOK
 lOK := FALSE
 @ 9, 04 say 'Again - Ok to create Database Files' get lOK picture "Y"
 read

 if lOK
  Create_dbfs()
 // wait
  mdbfarr := Directory( Oddvars( SYSPATH ) + '*.dbf' )

  if len( mdbfarr ) != 0
   Error( 'Existing DBF files detected - cannot proceed', 12 )
   quit

  else
   mdbfarr := Directory( Oddvars( SYSPATH ) + 'dbfstru\*' + TEMP_EXT )
   for x := 1 to len( mdbfarr )
    copy file ( Oddvars( SYSPATH ) + 'dbfstru\' + mdbfarr[ x, 1 ] ) to ( Oddvars( SYSPATH ) + left( mdbfarr[ x, 1 ], at( '.', mdbfarr[ x, 1 ] ) ) + 'dbf' )

   next

  endif

 endif

endif

quit

return nil

*

function setupdirs

if len( directory( Oddvars( SYSPATH ) + 'dbfstru', 'D' ) ) = 0
 makedir( Oddvars( SYSPATH ) + 'dbfstru' )

endif

if len( directory( oddvars( SYSPATH) + 'mcomment', 'D' ) ) = 0      // Master file comments
 makedir( oddvars( SYSPATH) + 'mcomment' )

endif

if len( directory( oddvars( SYSPATH) + 'icomment', 'D' ) ) = 0      // Item Comments
 makedir( oddvars( SYSPATH) + 'icomment' )

endif

if len( directory( Oddvars( SYSPATH ) + 'errors', 'D' ) ) = 0       // Holds error reports
 makeDir( Oddvars( SYSPATH ) + 'errors' )

endif

return nil

*

Function Create_dbfs ( sPath, sFileExtension )
local aFldDef
default spath to Oddvars( SYSPATH ) + "dbfstru\" 
default sFileExtension to TEMP_EXT

// arrears.dbf
aFldDef:={}
aadd( aFldDef, { "con_no", "n", 6, 0 } )
aadd( aFldDef, { "due", "d", 8, 0 } )
aadd( aFldDef, { "amount", "n", 8, 2 } )
aadd( aFldDef, { "paid", "l", 1, 0 } )
aadd( aFldDef, { "stat1", "d", 8, 0 } )
aadd( aFldDef, { "stat2", "d", 8, 0 } )
aadd( aFldDef, { "stat3", "d", 8, 0 } )
aadd( aFldDef, { "date_paid", "d", 8, 0 } )
aadd( aFldDef, { "amt_paid", "n", 8, 2 } )
aadd( aFldDef, { "comments", "c", 30, 0 } )
dbcreate( sPath + "arrears" + sFileExtension, aFldDef )

// audit.r99
aFldDef:={}
aadd( aFldDef, { "con_no", "n", 6, 0 } )
aadd( aFldDef, { "code", "c", 1, 0 } )
aadd( aFldDef, { "name", "c", 20, 0 } )
aadd( aFldDef, { "date", "d", 8, 0 } )
aadd( aFldDef, { "amt", "n", 10, 2 } )
aadd( aFldDef, { "machine", "c", 10, 0 } )
aadd( aFldDef, { "comments", "c", 20, 0 } )
aadd( aFldDef, { "dep_no", "c", 10, 0 } )
aadd( aFldDef, { "time", "c", 8, 0 } )
aadd( aFldDef, { "opercode", "c", 10, 0 } )
dbcreate( sPath + "audit" + sFileExtension, aFldDef )

// backlog.r99
aFldDef:={}
aadd( aFldDef, { "disk_set", "c", 2, 0 } )
aadd( aFldDef, { "date", "d", 8, 0 } )
aadd( aFldDef, { "initials", "c", 2, 0 } )
aadd( aFldDef, { "time", "c", 8, 0 } )
aadd( aFldDef, { "cumulative", "n", 2, 0 } )
dbcreate( sPath + "backlog" + sFileExtension, aFldDef )

// hirer.r99
aFldDef:={}
aadd( aFldDef, { "surname", "c", 20, 0 } )
aadd( aFldDef, { "first", "c", 20, 0 } )
aadd( aFldDef, { "add1", "c", 20, 0 } )
aadd( aFldDef, { "add2", "c", 20, 0 } )
aadd( aFldDef, { "suburb", "c", 20, 0 } )
aadd( aFldDef, { "pcode", "c", 4, 0 } )
aadd( aFldDef, { "dob", "d", 8, 0 } )
aadd( aFldDef, { "car_rego", "c", 10, 0 } )
aadd( aFldDef, { "license", "c", 10, 0 } )
aadd( aFldDef, { "expiry_d", "d", 8, 0 } )
aadd( aFldDef, { "occupation", "c", 15, 0 } )
aadd( aFldDef, { "tele_priv", "c", 15, 0 } )
aadd( aFldDef, { "tele_empl", "c", 15, 0 } )
aadd( aFldDef, { "tele_mob", "c", 15, 0 } )
aadd( aFldDef, { "con_no", "n", 6, 0 } )
aadd( aFldDef, { "agent", "c", 20, 0 } )
aadd( aFldDef, { "agent_no", "c", 20, 0 } )
aadd( aFldDef, { "email", "c", 50, 0 } )
dbcreate( sPath + "hirer" + sFileExtension, aFldDef )

// items.r99
aFldDef:={}
aadd( aFldDef, { "item_code", "c", 10, 0 } )
aadd( aFldDef, { "serial", "c", 40, 0 } )
aadd( aFldDef, { "desc", "c", 40, 0 } )
aadd( aFldDef, { "model", "c", 30, 0 } )
aadd( aFldDef, { "owner_code", "c", 3, 0 } )
aadd( aFldDef, { "con_no", "n", 6, 0 } )
aadd( aFldDef, { "cost", "n", 8, 2 } )
aadd( aFldDef, { "received", "d", 8, 0 } )
aadd( aFldDef, { "status", "c", 1, 0 } )
aadd( aFldDef, { "d_rent", "n", 8, 2 } )
aadd( aFldDef, { "w_rent", "n", 8, 2 } )
aadd( aFldDef, { "f_rent", "n", 8, 2 } )
aadd( aFldDef, { "m_rent", "n", 8, 2 } )
aadd( aFldDef, { "warranty_d", "d", 8, 0 } )
aadd( aFldDef, { "last_rent", "d", 8, 0 } )
aadd( aFldDef, { "rent_ytd", "n", 12, 2 } )
aadd( aFldDef, { "rent_tot", "n", 12, 2 } )
aadd( aFldDef, { "last_ret", "d", 8, 0 } )
aadd( aFldDef, { "pay_ytd", "n", 12, 2 } )
aadd( aFldDef, { "pay_tot", "n", 12, 2 } )
aadd( aFldDef, { "month_pay", "n", 12, 2 } )
aadd( aFldDef, { "disp_date", "d", 8, 0 } )
aadd( aFldDef, { "lease_term", "n", 12, 0 } )
aadd( aFldDef, { "interest", "n", 5, 2 } )
aadd( aFldDef, { "pay_made", "n", 2, 0 } )
aadd( aFldDef, { "pay_out", "n", 8, 2 } )
aadd( aFldDef, { "prod_code", "c", 10, 0 } )
aadd( aFldDef, { "insurance", "n", 12, 2 } )
aadd( aFldDef, { "MYOBCode", "c", 10, 0 } )
aadd( aFldDef, { "PayType", "c", 1, 0 } )
dbcreate( sPath + "items" + sFileExtension, aFldDef )

// Product Code
aFldDef:={}
aadd( aFldDef, { "code", "c", 10, 0 } )
aadd( aFldDef, { "name", "c", 30, 0 } )
dbcreate( sPath + "prodcode" + sFileExtension, aFldDef )

// Contract Status
aFldDef:={}
aadd( aFldDef, { "code", "c", 1, 0 } )
aadd( aFldDef, { "name", "c", 30, 0 } )
dbcreate( sPath + "status" + sFileExtension, aFldDef )

// letter.r99
aFldDef:={}
aadd( aFldDef, { "line1", "c", 78, 0 } )
dbcreate( sPath + "letter" + sFileExtension, aFldDef )

// master.r99
aFldDef:={}
aadd( aFldDef, { "con_no", "n", 6, 0 } )
aadd( aFldDef, { "dep_no", "c", 6, 0 } )
aadd( aFldDef, { "grace", "n", 2, 0 } )
aadd( aFldDef, { "dep_paid", "n", 12, 2 } )
aadd( aFldDef, { "dep_date", "d", 8, 0 } )
aadd( aFldDef, { "bond_paid", "n", 12, 2 } )
aadd( aFldDef, { "bond_date", "d", 8, 0 } )
aadd( aFldDef, { "bond_ret", "n", 12, 2 } )
aadd( aFldDef, { "bond_ret_d", "d", 8, 0 } )
aadd( aFldDef, { "term_rent", "c", 1, 0 } )
aadd( aFldDef, { "term_len", "c", 8, 0 } )
aadd( aFldDef, { "paid_to", "d", 8, 0 } )
aadd( aFldDef, { "next_inst", "d", 8, 0 } )
aadd( aFldDef, { "install", "n", 12, 2 } )
aadd( aFldDef, { "bal_bf", "n", 12, 2 } )
aadd( aFldDef, { "comments1", "c", 60, 0 } )
aadd( aFldDef, { "comments2", "c", 60, 0 } )
aadd( aFldDef, { "area", "c", 3, 0 } )
aadd( aFldDef, { "commenced", "d", 8, 0 } )
aadd( aFldDef, { "EndDate", "d", 8, 0 } )
aadd( aFldDef, { "inquiry", "l", 1, 0 } )
aadd( aFldDef, { "skey", "c", 5, 0 } )
aadd( aFldDef, { "reminders", "l", 1, 0 } )
aadd( aFldDef, { "insurance", "l", 1, 0 } )
aadd( aFldDef, { "vlf", "c", 6, 0 } )
aadd( aFldDef, { "bankdetail", "c", 40, 0 } )
aadd( aFldDef, { "myobfirst", "c", 40, 0 } )
aadd( aFldDef, { "extra_key", "c", 40, 0 } )
aadd( aFldDef, { "billmethod", "c", 1, 0 } )
aadd( aFldDef, { "cred_card", "c", 30, 0 } )
aadd( aFldDef, { "card_id", "c", 4, 0 } )
aadd( aFldDef, { "expirydate", "d", 8, 0 } )
aadd( aFldDef, { "ponum", "c", 10, 0 } )
aadd( aFldDef, { "site", "c", 2, 0 } )
aadd( aFldDef, { "gst", "n", 12, 2 } )
aadd( aFldDef, { "pickup", "d", 8, 0 } )
aadd( aFldDef, { "taxfree", "l", 1, 0 } )
aadd( aFldDef, { "status", "c", 1, 0 } )
dbcreate( sPath + "master" + sFileExtension, aFldDef )

// owner.r99
aFldDef:={}
aadd( aFldDef, { "code", "c", 3, 0 } )
aadd( aFldDef, { "name", "c", 30, 0 } )
aadd( aFldDef, { "add1", "c", 30, 0 } )
aadd( aFldDef, { "add2", "c", 30, 0 } )
aadd( aFldDef, { "phone", "c", 14, 0 } )
aadd( aFldDef, { "contact", "c", 30, 0 } )
aadd( aFldDef, { "lastpay", "d", 8, 0 } )
dbcreate( sPath + "owner" + sFileExtension, aFldDef )

// stkhist.r99
aFldDef:={}
aadd( aFldDef, { "item_code", "c", 10, 0 } )
aadd( aFldDef, { "con_no", "n", 6, 0 } )
aadd( aFldDef, { "returned", "d", 8, 0 } )
aadd( aFldDef, { "name", "c", 20, 0 } )
aadd( aFldDef, { "address1", "c", 25, 0 } )
aadd( aFldDef, { "address2", "c", 25, 0 } )
aadd( aFldDef, { "suburb", "c", 20, 0 } )
aadd( aFldDef, { "disposed", "d", 8, 0 } )
aadd( aFldDef, { "details", "c", 50, 0 } )
dbcreate( sPath + "stkhist" + sFileExtension, aFldDef )

// tran.r99
aFldDef:={}
aadd( aFldDef, { "con_no", "n", 6, 0 } )
aadd( aFldDef, { "date", "d", 8, 0 } )
aadd( aFldDef, { "value", "n", 12, 2 } )
aadd( aFldDef, { "type", "c", 1, 0 } )
aadd( aFldDef, { "narrative", "c", 20, 0 } )
aadd( aFldDef, { "insurance", "n", 12, 2 } )
aadd( aFldDef, { "gst", "n", 12, 2 } )
aadd( aFldDef, { "PayType", "c", 1, 0 } )
dbcreate( sPath + "tran" + sFileExtension, aFldDef )

// bvars.r99
aFldDef:={}
aadd( aFldDef, { "address1", "c", 30, 0 } )
aadd( aFldDef, { "address2", "c", 30, 0 } )
aadd( aFldDef, { "suburb", "c", 30, 0 } )
aadd( aFldDef, { "pcode", "c", 4, 0 } )
aadd( aFldDef, { "phone", "c", 20, 0 } )
aadd( aFldDef, { "arr_run", "d", 8, 0 } )
aadd( aFldDef, { "def_owner", "c", 3, 0 } )
aadd( aFldDef, { "grace", "n", 3, 0 } )
aadd( aFldDef, { "item_no", "n", 6, 0 } )
aadd( aFldDef, { "page_len", "n", 3, 0 } )
aadd( aFldDef, { "print", "c", 3, 0 } )
aadd( aFldDef, { "eom", "d", 8, 0 } )
aadd( aFldDef, { "last_eod", "d", 8, 0 } )
aadd( aFldDef, { "eoy", "c", 2, 0 } )
aadd( aFldDef, { "late_amt", "n", 7, 2 } )
aadd( aFldDef, { "late_fee", "l", 1, 0 } )
aadd( aFldDef, { "seq", "n", 6, 0 } )
aadd( aFldDef, { "date", "d", 8, 0 } )
aadd( aFldDef, { "craa_no", "c", 20, 0 } )
aadd( aFldDef, { "baudrate", "n", 6, 0 } )
aadd( aFldDef, { "com_port", "n", 1, 0 } )
aadd( aFldDef, { "gstrate", "n", 10, 2 } )
aadd( aFldDef, { "lateFeeGst", "l", 1, 0 } )
aadd( aFldDef, { "late_amt1", "n", 7, 2 } )
aadd( aFldDef, { "late_fee1", "l", 1, 0 } )
aadd( aFldDef, { "printer1", "c", 30, 0 } )
aadd( aFldDef, { "printer2", "c", 30, 0 } )
aadd( aFldDef, { "editor", "c", 50, 0 } )   // May need the path as well
aadd( aFldDef, { "company", "c", 30, 0 } )
dbcreate( sPath + "bvars" + sFileExtension, aFldDef )

// sysrec.r99
aFldDef:={}
aadd( aFldDef, { "con_no", "n", 6, 0 } )
aadd( aFldDef, { "audit_seq", "n", 6, 0 } )
aadd( aFldDef, { "MYOBInvno", "n", 6, 0 } )
aadd( aFldDef, { "FileNo", "n", 6, 0 } )
dbcreate( sPath + "sysrec" + sFileExtension, aFldDef )

// System
aFldDef := {}
aadd( aFldDef, { 'details', 'c', 50, 0 }  )
dbcreate( sPath + "system" + sFileExtension, aFldDef )

// nodes
aFldDef := {} 
aadd( aFldDef, { "node", "c", 20, 0 } )
aadd( aFldDef, { "reg", "c", 10, 0 } )
aadd( aFldDef, { "printer", "c", 50, 0 } )
aadd( aFldDef, { "report", "c", 50, 0 } )
aadd( aFldDef, { "barcode", "c", 50, 0 } )
aadd( aFldDef, { "letter", "c", 50, 0 } )
aadd( aFldDef, { "docket", "c", 50, 0 } )
aadd( aFldDef, { "f1", "c", 13, 0 } )
aadd( aFldDef, { "f1n", "c", 9, 0 } )
aadd( aFldDef, { "f1margin", "n", 5, 1 } )
aadd( aFldDef, { "f2", "c", 13, 0 } )
aadd( aFldDef, { "f2n", "c", 9, 0 } )
aadd( aFldDef, { "f2margin", "n", 5, 1 } )
aadd( aFldDef, { "f3", "c", 13, 0 } )
aadd( aFldDef, { "f3n", "c", 9, 0 } )
aadd( aFldDef, { "f3margin", "n", 5, 1 } )
aadd( aFldDef, { "f4", "c", 13, 0 } )
aadd( aFldDef, { "f4n", "c", 9, 0 } )
aadd( aFldDef, { "f4margin", "n", 5, 1 } )
aadd( aFldDef, { "f5", "c", 13, 0 } )
aadd( aFldDef, { "f5n", "c", 9, 0 } )
aadd( aFldDef, { "f5margin", "n", 5, 1 } )
aadd( aFldDef, { "f6", "c", 13, 0 } )
aadd( aFldDef, { "f6n", "c", 9, 0 } )
aadd( aFldDef, { "f6margin", "n", 5, 1 } )
aadd( aFldDef, { "f7", "c", 13, 0 } )
aadd( aFldDef, { "f7n", "c", 9, 0 } )
aadd( aFldDef, { "f7margin", "n", 5, 1 } )
aadd( aFldDef, { "f8", "c", 13, 0 } )
aadd( aFldDef, { "f8n", "c", 9, 0 } )
aadd( aFldDef, { "f8margin", "n", 5, 1 } )
aadd( aFldDef, { "f9", "c", 13, 0 } )
aadd( aFldDef, { "f9n", "c", 9, 0 } )
aadd( aFldDef, { "f9margin", "n", 5, 1 } )
aadd( aFldDef, { "f10", "c", 13, 0 } )
aadd( aFldDef, { "f10n", "c", 9, 0 } )
aadd( aFldDef, { "f10margin", "n", 5, 1 } )
aadd( aFldDef, { "date", "d", 8, 0 } )
aadd( aFldDef, { "cust_no", "n", 5, 0 } )
aadd( aFldDef, { "cdtype", "c", 1, 0 } )
aadd( aFldDef, { "auto_open", "l", 1, 0 } )
aadd( aFldDef, { "cdport", "n", 1, 0 } )
aadd( aFldDef, { "docket", "l", 1, 0 } )
aadd( aFldDef, { "colattr", "n", 2, 0 } )
aadd( aFldDef, { "backgr", "l", 1, 0 } )
aadd( aFldDef, { "shadow", "l", 1, 0 } )
aadd( aFldDef, { "good", "n", 3, 0 } )
aadd( aFldDef, { "bad", "n", 3, 0 } )
aadd( aFldDef, { "memory", "n", 3, 0 } )
aadd( aFldDef, { "speak", "l", 1, 0 } )
aadd( aFldDef, { "speed", "n", 3, 0 } )
aadd( aFldDef, { "space", "n", 3, 0 } )
aadd( aFldDef, { "res", "n", 3, 0 } )
aadd( aFldDef, { "maxrows", "n", 2, 0 } )
aadd( aFldDef, { "c1", "c", 20, 0 } )
aadd( aFldDef, { "c2", "c", 20, 0 } )
aadd( aFldDef, { "c3", "c", 20, 0 } )
aadd( aFldDef, { "c4", "c", 20, 0 } )
aadd( aFldDef, { "c5", "c", 20, 0 } )
aadd( aFldDef, { "c6", "c", 20, 0 } )
aadd( aFldDef, { "c7", "c", 20, 0 } )
aadd( aFldDef, { "c8", "c", 20, 0 } )
aadd( aFldDef, { "c9", "c", 20, 0 } )
aadd( aFldDef, { "color", "l", 1, 0 } )
aadd( aFldDef, { "poz", "l", 1, 0 } )
aadd( aFldDef, { "onp", "l", 1, 0 } )
aadd( aFldDef, { "modem", "l", 1, 0 } )
aadd( aFldDef, { "mport", "n", 1, 0 } )
aadd( aFldDef, { "mbaud", "n", 6, 0 } )
aadd( aFldDef, { "minit", "c", 20, 0 } )
dbcreate( sPath + "nodes" + sFileExtension, aFldDef )

// sites
aFldDef:={}
aadd( aFldDef, { "code", "c", 2, 0 } )
aadd( aFldDef, { "name", "c", 25, 0 } )
dbcreate( sPath + "sites" + sFileExtension, aFldDef)

// MYOBCode
aFldDef:={}
aadd( aFldDef, { "code", "c", 10, 0 } )
aadd( aFldDef, { "name", "c", 25, 0 } )
aadd( aFldDef, { "GSTExempt", "l", 1, 0 } )
dbcreate( sPath + "MYOBCode" + sFileExtension, aFldDef)

// operator
aFldDef:={}
aadd( aFldDef, { "code", "c", 3, 0 } )
aadd( aFldDef, { "name", "c", 25, 0 } )
aadd( aFldDef, { "password", "c", 10, 0 } )
aadd( aFldDef, { "mask", "c", 50, 0 } )
dbcreate( sPath + "operator" + sFileExtension, aFldDef)

//  MYOBImpo   for MEDI
aFldDef:={}
aadd( aFldDef, { "code", "c", 30, 0 } )           // Myob Account Number
aadd( aFldDef, { "name", "c", 60, 0 } )           // Myob Description
dbcreate( sPath + "MYOBImpo" + sFileExtension, aFldDef )

//  Truck   for Renta Centre
aFldDef:={}
aadd( aFldDef, { "code", "c", 10, 0 } )
aadd( aFldDef, { "name", "c", 30, 0 } )
dbcreate( sPath + "truck" + sFileExtension, aFldDef )

//  TrukBook   for Renta Centre
aFldDef:={}
aadd( aFldDef, { "date", "d", 8, 0 } )
aadd( aFldDef, { "truck", "c", 10, 0 } )
aadd( aFldDef, { "drivers", "c", 20, 0 } )

aadd( aFldDef, { "name0809", "c", 12, 0 } )
aadd( aFldDef, { "sub0809", "c", 12, 0 } )
aadd( aFldDef, { "det0809", "c", 50, 0 } )

aadd( aFldDef, { "name0910", "c", 12, 0 } )
aadd( aFldDef, { "sub0910", "c", 12, 0 } )
aadd( aFldDef, { "det0910", "c", 50, 0 } )
aadd( aFldDef, { "name0911a", "c", 12, 0 } )
aadd( aFldDef, { "sub0911a", "c", 12, 0 } )
aadd( aFldDef, { "det0911a", "c", 50, 0 } )
aadd( aFldDef, { "name0911b", "c", 12, 0 } )
aadd( aFldDef, { "sub0911b", "c", 12, 0 } )
aadd( aFldDef, { "det0911b", "c", 50, 0 } )
aadd( aFldDef, { "name1012a", "c", 12, 0 } )
aadd( aFldDef, { "sub1012a", "c", 12, 0 } )
aadd( aFldDef, { "det1012a", "c", 50, 0 } )
aadd( aFldDef, { "name1012b", "c", 12, 0 } )
aadd( aFldDef, { "sub1012b", "c", 12, 0 } )
aadd( aFldDef, { "det1012b", "c", 50, 0 } )
aadd( aFldDef, { "name1101a", "c", 12, 0 } )
aadd( aFldDef, { "sub1101a", "c", 12, 0 } )
aadd( aFldDef, { "det1101a", "c", 50, 0 } )
aadd( aFldDef, { "name1101b", "c", 12, 0 } )
aadd( aFldDef, { "sub1101b", "c", 12, 0 } )
aadd( aFldDef, { "det1101b", "c", 50, 0 } )
aadd( aFldDef, { "name1202a", "c", 12, 0 } )
aadd( aFldDef, { "sub1202a", "c", 12, 0 } )
aadd( aFldDef, { "det1202a", "c", 50, 0 } )
aadd( aFldDef, { "name1202b", "c", 12, 0 } )
aadd( aFldDef, { "sub1202b", "c", 12, 0 } )
aadd( aFldDef, { "det1202b", "c", 50, 0 } )
aadd( aFldDef, { "name0103a", "c", 12, 0 } )
aadd( aFldDef, { "sub0103a", "c", 12, 0 } )
aadd( aFldDef, { "det0103a", "c", 50, 0 } )
aadd( aFldDef, { "name0103b", "c", 12, 0 } )
aadd( aFldDef, { "sub0103b", "c", 12, 0 } )
aadd( aFldDef, { "det0103b", "c", 50, 0 } )
aadd( aFldDef, { "name0204a", "c", 12, 0 } )
aadd( aFldDef, { "sub0204a", "c", 12, 0 } )
aadd( aFldDef, { "det0204a", "c", 50, 0 } )
aadd( aFldDef, { "name0204b", "c", 12, 0 } )
aadd( aFldDef, { "sub0204b", "c", 12, 0 } )
aadd( aFldDef, { "det0204b", "c", 50, 0 } )

aadd( aFldDef, { "name04", "c", 12, 0 } )
aadd( aFldDef, { "sub04", "c", 12, 0 } )
aadd( aFldDef, { "det04", "c", 50, 0 } )

aadd( aFldDef, { "name4353a", "c", 12, 0 } )
aadd( aFldDef, { "sub4353a", "c", 12, 0 } )
aadd( aFldDef, { "det4353a", "c", 50, 0 } )

aadd( aFldDef, { "name4353b", "c", 12, 0 } )
aadd( aFldDef, { "sub4353b", "c", 12, 0 } )
aadd( aFldDef, { "det4353b", "c", 50, 0 } )

aadd( aFldDef, { "name0563a", "c", 12, 0 } )
aadd( aFldDef, { "sub0563a", "c", 12, 0 } )
aadd( aFldDef, { "det0563a", "c", 50, 0 } )

aadd( aFldDef, { "name0563b", "c", 12, 0 } )
aadd( aFldDef, { "sub0563b", "c", 12, 0 } )
aadd( aFldDef, { "det0563b", "c", 50, 0 } )

aadd( aFldDef, { "name0608a", "c", 12, 0 } )
aadd( aFldDef, { "sub0608a", "c", 12, 0 } )
aadd( aFldDef, { "det0608a", "c", 50, 0 } )

aadd( aFldDef, { "name0608b", "c", 12, 0 } )
aadd( aFldDef, { "sub0608b", "c", 12, 0 } )
aadd( aFldDef, { "det0608b", "c", 50, 0 } )

aadd( aFldDef, { "name0608c", "c", 12, 0 } )
aadd( aFldDef, { "sub0608c", "c", 12, 0 } )
aadd( aFldDef, { "det0608c", "c", 50, 0 } )

aadd( aFldDef, { "name089p", "c", 12, 0 } )
aadd( aFldDef, { "sub089p", "c", 12, 0 } )
aadd( aFldDef, { "det089p", "c", 50, 0 } )

dbcreate( sPath + "trukbook" + sFileExtension, aFldDef )

// Payment Types  for MEDI
aFldDef:={}
aadd( aFldDef, { "code", "c", 1, 0 } )
aadd( aFldDef, { "name", "c", 30, 0 } )
aadd( aFldDef, { "MYOBCode", "c", 10, 0 } )
dbcreate( sPath + "paytype" + sFileExtension, aFldDef )

return nil

*

Function ChkDbf ( cDbfName )
local nError, lReturn := FALSE

if !file( Oddvars( SYSPATH ) + cDbfName + '.dbf' )
 Create_dbfs()

 nError := RenameFile(  Oddvars( SYSPATH) + "dbfstru\" + cDbfName + TEMP_EXT, Oddvars( SYSPATH) + "dbfstru\" + cDbfName + '.dbf' )
 if nError != 0
  Error( 'Error renaming file ' + cDbfName + ' - Contact Bluegum ' + SUPPORT_PHONE + ' Error no ' + Ns( nError ), 12 )

 endif

 nError := FileMove(  Oddvars( SYSPATH) + "dbfstru\" + cDbfName + '.dbf',  Oddvars( SYSPATH) + cDbfName + '.dbf' )
 if nError != 0
  Error( 'Error moving new file ' + cDbfName + ' - Contact Bluegum ' + SUPPORT_PHONE + ' Error no ' + Ns( nError ), 12 )

 endif
 lReturn := TRUE

 aeval( directory( '_*.bak' ), { | del_element | ferase( del_element[ 1 ] ) } )

endif
return lReturn

*

/* checks for the presence of a new field and then performs the append */

Function ChkField ( cField, cDbfName )
local cFileName, nNumOfRecs := 0, lUpdated := FALSE

dbcloseall()   // Clean slate

if NetUse( cDbfName )

 if (cDbfName)->( fieldpos( cfield ) ) != 0
 (cDbfname)->( dbclosearea() )

 else
  nNumOfRecs := (cDbfName)->( reccount() )

  (cDbfname)->( dbclosearea() )

  Create_dbfs()   // create all the template dbf's as *.r2k files

  if NetUse( Oddvars( SYSPATH ) + "dbfstru\" +cDbfName + TEMP_EXT, EXCLUSIVE, ,"tempdbf" )

   if nNumOfRecs > 1000
    cls
    @ 3,10 say 'Performing upgrade to ' + cDbfName + ' database file on field ' + cfield

   endif

   cFileName := Oddvars( SYSPATH ) + ( cDbfName )
   append from ( cFileName )

   tempdbf->( dbclosearea() )

   ferase( cFileName + '.old' )  // Kill any old backup files first

   lUpdated := TRUE

   if frename( Oddvars(SYSPATH) + cDbfName + '.dbf',  Oddvars(SYSPATH) + cDbfName + '.old' ) == -1
    Error( 'Error renaming old ' + cDbfName + ' file - Contact ' + DEVELOPER +  '  ' + SUPPORT_PHONE + ' Error no ' + Ns( Ferror() ) , 12 )

   endif

   copy file ( OddVars( SYSPATH ) + "dbfstru\" + cDbfName + TEMP_EXT ) to ( Oddvars( SYSPATH ) + cdbfname + '.dbf' )

  endif

 endif

endif

return lUpdated

*

function Check_fld_len
// A Utility to check the DBFs for required field lengths
local farr := asort( directory( Oddvars( SYSPATH ) + '*.dbf' ), , ,{ |p1,p2| p1[1] < p2[1] } )
local x, y, z, fhandle
local mscr := Box_Save( 20, 10, 23, 40 )
local type_arr := { { 'SITE', SITELEN } }

fhandle := fcreate( 'dberrors.txt' )
@ 22, 12 say 'File - dberrors.txt'
for x := 1 to len( farr )
 if NetUse( farr[ x, 1 ] )
  @ 21, 12 say farr[ x, 1 ]
  for y := 1 to fcount()
   for z := 1 to len( type_arr )
    if fieldname( y ) = type_arr[ z, 1 ] .and. valtype( fieldget( y ) ) = 'C' .and. ;
       len( fieldget( y ) ) !=  type_arr[ z, 2 ]
     fwrite( fhandle, padr( farr[ x, 1 ], 15 ) + padr( fieldname( y ), 15 ) + ;
              padl( len( fieldget( y ) ), 10 ) + padl( type_arr[ z, 2 ], 10 ) + CRLF )
    endif
   next
  next
  dbclosearea()
 endif
next
fclose( fhandle )
Box_Restore( mscr )
mscr := Box_Save( 07, 02, 23, 76 )
memoedit( memoread( 'dberrors.txt' ), 08, 3, 22, 75 )
Box_Restore( mscr )
return nil

*

function Check_new_dbf
// A Utility to check one set of DBFs against another
// First of all get an array of our existing Dbf's
local oarr:= asort( directory( Oddvars( SYSPATH ) + '*.dbf' ), , ,{ |p1,p2| p1[1] < p2[1] } )
local x, y, ddstruct, mstruct, fname
local narr
local mscr := Box_Save( 3, 10, 5, 30 )
local fhandle := fcreate( 'dbdifs.txt' )  // Differences written out here
local oldsyspath := Oddvars( SYSPATH )

@ 04, 12 say 'File - dbdifs.txt'

narr := directory( 'dbfstru\*' + TEMP_EXT )   // Kill old structures in Dir if exist
for x := 1 to len( narr )
 Kill( 'dbfstru\' + narr[ x, 1 ] )

next

Create_dbfs()                         // Create dbf's ( with TEMP_EXT ) extensions

narr := asort( directory( oddvars( SYSPATH) + 'dbfstru\*' + TEMP_EXT ), , ,{ |p1,p2| p1[1] < p2[1] } )  // Sorted Array of DD files

ddstruct := {}                        // Ok our Data Dict ( DD ) is to be built from files in dbcheck
aadd( ddstruct, { "file_name", "C", 10 , 0 } )
aadd( ddstruct, { "field_name", "C", 10 , 0 } )
aadd( ddstruct, { "field_type", "C", 1 , 0 } )
aadd( ddstruct, { "field_len", "N", 3, 0 } )
aadd( ddstruct, { "field_dec", "N", 2, 0 } )
dbcreate( 'datadict.std', ddstruct )

NetUse( 'datadict.std', EXCLUSIVE, , 'std' )

for x := 1 to len( narr )

 NetUse( oddvars( SYSPATH) + 'dbfstru\' + narr[ x, 1 ], EXCLUSIVE )
 mstruct := dbstruct()
 dbclosearea()

 select std

 for y := 1 to len( mstruct )

  fname := narr[ x,1 ]

  if !( left( fname, 1 ) $ 'Z~_' )

   Add_rec( 'std' )
   std->file_name := substr( narr[ x,1 ], 1, at( '.', narr[ x,1] ) -1 )
   std->field_name := mstruct[ y, 1 ]
   std->field_type := mstruct[ y, 2 ]
   std->field_len := mstruct[ y, 3 ]
   std->field_dec := mstruct[ y, 4 ]
   std->( dbrunlock() )

  endif

 next

next
Box_Save( 7, 10, 12, 70 )
select std

@ 8, 12 say 'Data Dictionary built ' + Ns( lastrec() )+ ' records created'

ferase( "datadict.std" )
ddstruct := {}
aadd( ddstruct, { "file_name", "C", 10 , 0 } )
aadd( ddstruct, { "field_name", "C", 10 , 0 } )
aadd( ddstruct, { "field_type", "C", 1 , 0 } )
aadd( ddstruct, { "field_len", "N", 3, 0 } )
aadd( ddstruct, { "field_dec", "N", 2, 0 } )
dbcreate( "datadict.old", ddstruct )
NetUse( 'datadict.old', EXCLUSIVE, ,'ddold' )

for x := 1 to len( oarr )

 NetUse( oarr[ x, 1 ], SHARED )
 mstruct := dbstruct()
 dbclosearea()

 for y := 1 to len( mstruct )
  fname := oarr[ x, 1 ]

  if !( left( fname, 1 ) $ 'Z~_' )  // Don't check temp etc files
   Add_rec( 'ddold' )
   ddold->file_name := substr( oarr[ x, 1 ], 1, at( '.', oarr[ x, 1 ] ) -1 )
   ddold->field_name := mstruct[ y, 1 ]
   ddold->field_type := mstruct[ y, 2 ]
   ddold->field_len := mstruct[ y, 3 ]
   ddold->field_dec := mstruct[ y, 4 ]
   ddold->( dbrunlock() )

  endif
  Pinwheel( NOINTERUPT )

 next
 Pinwheel( NOINTERUPT )
next

select ddold

@ 09, 12 say 'New Data Dictionary built ' + Ns( lastrec() ) + ' records created'
@ 10, 12 say 'Forward Searching - Wait about'

select std
indx( 'file_name+field_name', 'filename' )

select ddold
set relation to ddold->file_name+ddold->field_name into std

dbgotop()
while !eof() .and. Pinwheel( NOINTERUPT )
 do case
 case std->( eof() )  // Field not found in std
  fdisp( fhandle,  'Field not found in standard ' )
 case std->field_type != ddold->field_type
  fdisp( fhandle,  'Field type mismatch  - Standard = ' + std->field_type )
 case std->field_len != ddold->field_len
  fdisp( fhandle,  'Field length mismatch  - Standard = ' + Ns( std->field_len ) )
 case std->field_dec != ddold->field_dec
  fdisp( fhandle,  'Field Decimals mismatch  - Standard = ' + Ns( std->field_dec ) )
 otherwise
  fdisp( fhandle,  '' )
 endcase
 dbskip()
enddo
select std
orddestroy( 'filename' )

@ 11, 12 say 'Backward Searching - Wait about'

select ddold
set relation to
indx( 'file_name+field_name', 'ddold' )
select std
set relation to std->file_name + std->field_name into ddold
std->( dbgotop() )
while !std->( eof() ) .and. Pinwheel( NOINTERUPT )
 if ddold->( eof() )
  fdisp( fhandle, 'File ' + std->file_name + '  Standard field ' + std->field_name + ' not on local dbfs', FALSE )

 endif
 std->( dbskip() )

enddo
ddold->( orddestroy( 'ddold' ) )
dbcloseall()

fclose( fhandle )

ferase( "datadict.bs" )
ferase( "datadict.new" )

Box_Restore( mscr )
mscr := Box_Save( 01, 02, 23, 78 )
memoedit( memoread( 'dbdifs.txt' ), 02, 3, 22, 77 )
Box_Restore( mscr )
return nil

*

function fdisp ( mhandle, mstr, lForwards )
local mscr:=Box_Save( 2,40,8,75 )
default lForwards to TRUE
if lForwards
 @ 3,42 say 'File Name ' + ddold->file_name
 @ 4,42 say 'Field Name ' + ddold->field_name
 @ 5,42 say 'Field Type ' + ddold->field_type
 @ 6,42 say 'Field Len  ' + Ns( ddold->field_len )
 @ 7,42 say 'Field Dec  ' + Ns( ddold->field_dec )

endif

if !empty( mstr )
 if lForwards
  fwrite( mhandle,'File Name ' + ddold->file_name + CRLF )
  fwrite( mhandle,'Field Name ' + ddold->field_name + CRLF )
  fwrite( mhandle,'Field Type ' + ddold->field_type + CRLF )
  fwrite( mhandle,'Field Len  ' + Ns( ddold->field_len ) + CRLF )
  fwrite( mhandle,'Field Dec  ' + Ns( ddold->field_dec ) + CRLF )
  fwrite( mhandle, mstr  + CRLF + replicate( chr( 196 ), 40 ) + CRLF )

 else
  fwrite( mhandle, mstr  + CRLF )

 endif

endif
return nil

*

Procedure FixSchema

local x, oarr, narr, sFileName, xpath

Heading( 'Update the scheme to latest' )
if IsReady( 'Ensure you have copied your ' + SYSNAME + ' folder for backup. Ok to proceed?' )
 Box_Save( 3, 10, 10, 70 )

 if len( directory( Oddvars( SYSPATH ) + 'backup', 'D' ) ) = 0      // Holds a backup of the DBFs
  makeDir( Oddvars( SYSPATH ) + 'backup' )

 else
  narr := directory( Oddvars( SYSPATH ) + 'backup\*.dbf' ) 			// Kill old Backup files if they exist
  for x := 1 to len( narr )
   Kill( Oddvars( SYSPATH ) + 'backup\' + nArr[ x, 1] )

  next

 endif

 oarr:= directory( Oddvars( SYSPATH ) + '*.dbf' )
 @ 4, 12 say 'Moving data files to backup'
 for x := 1 to len( oarr )
  FileMove( Oddvars( SYSPATH ) + oArr[x,1], Oddvars( SYSPATH ) + 'backup\' + oArr[x,1] )

 next

 narr := directory( Oddvars( SYSPATH ) + 'dbfstru\*' + TEMP_EXT )   // Kill old structures in Dir if exist
 for x := 1 to len( narr )
  Kill( Oddvars( SYSPATH ) + 'dbfstru\' + narr[ x, 1 ] )

 next

 Create_dbfs()                         // Create dbf's ( with TEMP_EXT ) extensions

 narr := directory( Oddvars( SYSPATH ) + 'dbfstru\*' + TEMP_EXT )   // Grab the dbf structures again

// Copy the structures into the Winrent folder
 for x := 1 to len( narr )
  sfileName := substr( narr[ x, 1 ], 1, at( '.', narr[ x, 1 ] ) -1 )
  FileMove( Oddvars( SYSPATH ) + 'dbfstru\' + narr[ x, 1 ], Oddvars( SYSPATH ) + sfilename + '.dbf' )

 next

 // Append the data
 oarr:= directory( Oddvars( SYSPATH ) + '*.dbf' )
 for x := 1 to len( narr )
  sfileName := substr( narr[ x, 1 ], 1, at( '.', narr[ x, 1 ] ) -1 )
  @ 5, 12 say 'Appending from backup file -> ' + padr( sFileName, 20 ) 
  if NetUse( sFilename, EXCLUSIVE )
   xPath := Oddvars( SYSPATH ) + 'backup\' + sFileName
   append from &xpath
   dbcloseArea()
   
  endif

 next
 
endif

return