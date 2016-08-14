/*
    MYOB Export routines


 Last change:  TG   18 Oct 2010   10:51 pm

*/

#include "winrent.ch"
#define DL '","'
#define RE '"'

Function ArglExpo
local aArray, fchoice

while TRUE
 Heading('Contract Export')
 aArray := {}
 aadd( aArray, { 'Report', 'Return to Reports Menu' } )
 aadd( aArray, { 'CSV', 'Export selected Contracts as CSV file', { || ArgCSVExport( TRUE ) } } )  // Write out CSV
 aadd( aArray, { 'DataBases', 'Export selected contracts to new database', { || ArgCSVExport( FALSE ) } } )  // Write out DB
 fchoice := MenuGen( aArray, 07, 59, 'Export' )

 if fchoice < 2
  exit
 else
  Eval( aArray[ fchoice, 3 ] )
 endif

enddo
return nil

*

Procedure ArgCSVExport ( lCSV )

local mdate := Bvars( B_SYSDATE ), mhandle, mcomment := space( 40 )
local getlist:={}, spath
local nConNo, nKey, oBrowse
local mSur, mFirst, sBox

local aExport := {}
local aFldDef := {}

if NetUse( "items" )
 items->( ordsetfocus( 'contract' ) )
 if NetUse( "hirer" )
  if NetUse( "master" )
   aadd( aFldDef, { "con_no", "n", 6, 0 } )
   dbcreate( Oddvars( SYSPATH ) + Oddvars( TEMPFILE ), aFldDef )

   if NetUse( Oddvars( SYSPATH ) +  Oddvars( TEMPFILE ), EXCLUSIVE , , 'tempfile' )  
    set relation to tempfile->con_no into hirer,;
	         to tempfile->con_no into items

    SBox := Box_Save( 2, 02, 22, 78 )

    Heading('List of Contracts for Export')
    select tempfile
    oBrowse:=tbrowsedb( 03, 03, 21, 77 ) 
    oBrowse:colorspec := if( iscolor(), TB_COLOR, setcolor() )
    oBrowse:HeadSep := HEADSEP
    oBrowse:ColSep := COLSEP
    oBrowse:goTopBlock := { || tempfile->( dbgotop() ) }
    oBrowse:goBottomBlock := { || tempfile->( dbgoBottom() ) }
    oBrowse:skipBlock     := {|n| DbSkipper(n) }
    oBrowse:addColumn( tbcolumnnew( 'Contract', { || tempfile->con_no } ) )
    oBrowse:addcolumn( tbcolumnNew( 'Hirer Surname', { || hirer->surname } ) )
    oBrowse:addcolumn( tbcolumnNew( 'First Item', { || items->desc } ) )
    nKey := 0
    @ 23, 3 say "<Ins> to add a contract, <Del> to remove (from list) <Esc> to complete/exit"
    while nKey != K_ESC

     oBrowse:forcestable()
     nkey := inkey(0)

     if !Navigate( oBrowse, nkey )

      do case
      case nkey = K_DEL
       if Isready( 'Ok to delete Contract No from listing ' + ns( tempfile->con_no ) )
        Del_Rec( 'tempfile' )
        oBrowse:refreshall()
	    oBrowse:goTop()
	
       endif
    
      case nKey = K_INS
       if Con_find()
        select tempfile
        add_Rec( 'tempfile' )
        tempfile->con_no := OddVars( CONTRACT )
        oBrowse:refreshall()
	
       endif
      endcase
   
     endif

    enddo
    Box_Restore( SBox )

    if tempfile->( reccount() ) > 0
	 if !lCSV
	  while TRUE
	   sPath := space( 40 )
	   box_save( 2, 4, 6, 77 )
	   @ 3, 5 say 'About to export ' + Ns( tempfile->( reccount() ) ) + ' contracts' 
	   @ 4, 5 say 'Path the target folder' get sPath
	   read
	   if Updated()
	    sPath := trim( spath )
	    if !IsDirectory( spath )
	     if IsReady( "Folder " + spath + " does not exist!" + CRLF + ;
                             "You must create this and run the new users 'Winrent' first" + CRLF +;
							 "Hit 'No' to exit or 'Yes' after running up the new user program" ) 
	      // MakeDir( sPath )
         else
          exit
         
		 endif
	    
	    endif
		sPath += "\"
		// Create_dbfs ( sPath, ".dbf" ) Shouldn't need to do this new version will create DBF files
	    
		@ 5, 5 say "Appending - Please wait"

		tempfile->( dbgotop() )
	    while !tempfile->( eof() )
       	 nConNo := tempfile->con_no 
 	     @ 5, 5 say "Appending Contract No " + ns( nConNo ) + space(5)

		 if NetUse( sPath + 'master', , ,'tempmast' )
		  append from ( Oddvars( SYSPATH ) + 'master' ) for ( con_no = nConNo )
		  tempmast->( dbCloseArea() )
	     endif

		 if NetUse( sPath + 'hirer', , ,'temphirer' )
		  append from ( Oddvars( SYSPATH ) + 'hirer' ) for ( con_no = nConNo )
		  temphirer->( dbCloseArea() )
		 endif
		 
		 if NetUse( sPath + 'items', , ,'tempitems' )
		  append from ( Oddvars( SYSPATH ) + 'items' ) for ( con_no = nConNo )
		  tempItems->( dbCloseArea() )
		 endif

		 if NetUse( sPath + 'tran', , ,'temptran' )
		  append from ( Oddvars( SYSPATH ) + 'tran' ) for ( con_no = nConNo )
		  temptran->( dbCloseArea() )
		 endif

		 if NetUse( sPath + 'arrears', , ,'temparr' )
		  append from ( Oddvars( SYSPATH ) + 'arrears' ) for ( con_no = nConNo )
		  tempArr->( dbCloseArea() )
		 
		 endif
         
		 tempfile->( dbskip() )

		enddo
		error( "Export Completed" )
		exit
	   endif 	// Updated
	  enddo

     else       // CSV
	  if Isready( "Ok to write " + Ns( tempfile->( reccount() ) ) + " contracts to file?" )
       mhandle := fcreate( 'export.csv' )
       fWrite( mHandle, RE + "Contract No" + DL + "Surname" + DL + "First Name" + DL )
       fWrite( mHandle, "Address 1" + DL + "Address 2" + DL + "Suburb" + DL )
       fWrite( mHandle, "PostCode" + DL + "Date of Birth" + DL + "Car rego" + DL )
       fWrite( mHandle, "License" + DL + "Expiry Date" + DL + "Occupation" + DL )
       fWrite( mHandle, "Tele Priv" + DL + "Tele Empl" + DL + "Tele Mobile" + DL )
       fwrite( mhandle, "Agent" + DL + "Agent Phone" + DL + "Email" + DL )
       fWrite( mHandle, "Paid To" + DL + "Install" + DL + "Balance BF" + DL )
       fwrite( mHandle, "Location" + DL + "Rent Period" + DL + "Term Rent" + DL + "Commenced" + DL )
       fwrite( mHandle, "Dep Book No" + DL + "Days Grace" + DL + "Bond Paid" + DL + "Reminders" + DL )
       fWrite( mHandle, "Status" + DL + "Comments" + DL )
       fwrite( mhandle, "Item Code" + DL + "Serial No" + DL + "Description" + DL )
       fwrite( mhandle, "Model" + DL + "Owner Code" + DL + "Cost" + DL + "Received" + DL  )
       fwrite( mhandle, "Status" + DL + "D Rent" + DL + "W Rent" + DL + "F Rent" + "M Rent" + DL )
       fwrite( mhandle, "Warranty" + DL + "Last rent" + DL + "Rent YTD" + DL + "Rent Total" + DL )
       fwrite( mhandle, "Last Return" + DL + "Pay YTD" + DL + "Pay Tot" + DL + "Month Pay" + DL )
       fwrite( mHandle, "Disposal" + DL + "Lease Term" + DL + "Interest" + DL + "Pay Made" + DL )
       fwrite( mHandle, "Pay Out" + DL + "Prod Code" + DL + "Insurance" + DL + "MYOB Code" + DL )
       fwrite( mHandle, "Payment type" + RE + CRLF )
 
       tempfile->( dbgotop() )
       while !( tempfile->( eof() ) )
        nConNo = tempfile->con_no
        master->( dbseek( nConNo ) )		 
        hirer->( dbseek( nConNo ) )
   
        msur = ''
        mfirst = ''

        while hirer->con_no = nConNo .and. !hirer->( eof() )
         msur += trim( hirer->surname ) + '/'
         mfirst += trim( hirer->first ) + '/'
         hirer->( dbskip() )

        enddo

        msur = left( msur, len( trim( msur ) ) -1 )
        mfirst = left( mfirst, len( trim( mfirst ) ) -1 )
  
        hirer->( dbseek( nConNo ) )
        items->( dbseek( nConNo ) )
  
        while items->con_no = nConNo .and. !items->( eof() )
         fwrite( mhandle, RE + ns( nConNo ) + DL ) 
         fwrite( mhandle, msur + DL )          
         fwrite( mHandle, mfirst + DL )		
         fwrite( mhandle, trim( hirer->add1 ) + DL ) 
         fwrite( mhandle, trim( hirer->add2 ) + DL ) 
         fwrite( mhandle, trim( hirer->suburb ) + DL )
	     fwrite( mHandle, trim( hirer->pcode ) + DL )    
	     fwrite( mhandle, dtoc( hirer->dob ) + DL  )
	     fwrite( mhandle, trim( hirer->car_rego) + DL )
	     fwrite( mhandle, trim( hirer->license ) + DL )
	     fwrite( mhandle, dtoc( hirer->expiry_d ) + DL )
	     fwrite( mhandle, trim( hirer->occupation ) + DL  )
	     fwrite( mhandle, trim( hirer->tele_priv ) + DL  )
	     fwrite( mhandle, trim( hirer->tele_empl ) + DL  )
	     fwrite( mhandle, trim( hirer->tele_mob ) + DL  )
	     fwrite( mhandle, trim( hirer->agent ) + DL  )
	     fwrite( mhandle, trim( hirer->agent_no ) + DL  )
	     fwrite( mhandle, trim( hirer->email ) + DL  )
	     fwrite( mhandle, dtoc( master->paid_to ) + DL  )
	     fwrite( mhandle, ns( master->install ) + DL  )
	     fwrite( mhandle, ns( master->bal_bf ) + DL  )
	     fwrite( mhandle, trim( master->area ) + DL  )
	     fwrite( mhandle, trim( master->term_len ) + DL  )
	     fwrite( mhandle, dtoc( master->commenced ) + DL  )
	     fwrite( mhandle, trim( master->dep_no ) + DL  )
	     fwrite( mhandle, ns( master->grace ) + DL  )
	     fwrite( mhandle, ns( master->bond_paid ) + DL  )
	     fwrite( mhandle, trim( master->status ) + DL  )
	     fwrite( mhandle, trim( master->comments1 ) + " " + trim( master->comments2 ) + DL  )
         fwrite( mhandle, trim( items->item_code ) + DL  )
	     fwrite( mhandle, trim( items->serial ) + DL  )
		 fwrite( mhandle, trim( items->desc ) + DL  )
		 fwrite( mhandle, trim( items->model ) + DL  )
		 fwrite( mhandle, trim( items->owner_code ) + DL  )
		 fwrite( mhandle, ns( items->cost ) + DL  )
		 fwrite( mhandle, dtoc( items->received ) + DL  )
		 fwrite( mhandle, trim( items->status ) + DL  )
		 fwrite( mhandle, ns( items->d_rent ) + DL  )
		 fwrite( mhandle, ns( items->w_rent ) + DL  )
		 fwrite( mhandle, ns( items->f_rent ) + DL  )
		 fwrite( mhandle, ns( items->m_rent ) + DL  )
		 fwrite( mhandle, dtoc( items->warranty_d ) + DL  )
		 fwrite( mhandle, dtoc( items->last_rent ) + DL  )
		 fwrite( mhandle, ns( items->rent_ytd ) + DL  )
		 fwrite( mhandle, ns( items->rent_tot ) + DL  )
		 fwrite( mhandle, dtoc( items->last_ret ) + DL  )
		 fwrite( mhandle, ns( items->pay_ytd ) + DL  )
		 fwrite( mhandle, ns( items->pay_tot ) + DL  )
		 fwrite( mhandle, ns( items->month_pay ) + DL  )
		 fwrite( mhandle, dtoc( items->disp_date ) + DL  )
		 fwrite( mhandle, ns( items->lease_term ) + DL  )
		 fwrite( mhandle, ns( items->interest ) + DL  )
		 fwrite( mhandle, ns( items->pay_made ) + DL  )
		 fwrite( mhandle, ns( items->pay_out ) + DL  )
		 fwrite( mhandle, trim( items->prod_code ) + DL  )
		 fwrite( mhandle, ns( items->insurance ) + DL  )
		 fwrite( mhandle, trim( items->MYOBCode ) + DL  )
		 fwrite( mhandle, trim( items->PayType ) + DL  )
		 fwrite( mhandle, dtoc( master->commenced ) + RE ) 
         fwrite( mhandle, CRLF )                         

         items->( dbskip() )

        enddo

        tempfile->( dbskip() )
       
       enddo

       fclose( mhandle )
       Error( "Written file 'Export.csv'", 12 )
	  
      endif   // lCSV
	 endif
    endif
   endif
  endif
 endif
endif

dbcloseall()

return

