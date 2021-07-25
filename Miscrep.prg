/*

  Rental System - Bluegum Software
  Module Miscrep - Reporting Menu

  Last change:  APG  15 Jun 2004    3:46 pm

      Last change:  TG   14 Mar 2011    9:01 am
*/

#include "winrent.ch"

#define CSV TAB


Procedure MiscRep


local choice, getlist:={}, mfile, nLetterChoice
local x, mhead, level4
local mcount, lPrePrinted, mdays
local oldscr := Box_Save(), mscr
local tchoice
local mcontract
local nuloop
local mcreate
local dbfstru
local medit
local mtest
local aArray
local mdbf
local farr
local mpercent1                 // Percentage increase value in GST related letters
local mpercent2                 // Percentage increase value in GST related letters
local lReminders := TRUE        // Ignore reminders for GST letters
local nGSTStartCont := 0
local oPrinter
local lPrintLetters             // Print letters or Mail Merge?
local sFileName                 // MailMerge File name
local sFileHandle               // Handle to write to
local sHeading                  // Heading row for mailmerge

// local dStartDate, dEndDate

memvar mStartCont, mEndCont, dEndDate, dStartDate, mPrintdate, sStatus  // Needed for Reporter to work

// private dEndDate, dStartDate, mtran, mStartCont := 0, mEndCont := 0, mPrintDate, sStatus

while TRUE

 Box_Restore( oldscr )

 Heading('Reports Menu')

 aArray := {}
 aadd( aArray, { 'Exit', 'Return to contract menu' } )
 aadd( aArray, { 'Collection', 'Collection list by area' } )
 aadd( aArray, { 'Arrears', 'Arrears history report' } )
 aadd( aArray, { 'Labels', 'Mailing labels / Envelope Print' } )
 aadd( aArray, { 'Statements', 'Delinquency letters' } )
 aadd( aArray, { 'Credit Card', 'Credit Card Payments' } )
 aadd( aArray, { 'Contract Ending', 'List Contracts about to end' } )

 choice := MenuGen( aArray, 7, 36, 'Miscellaneous' )

 level4 := Box_Save()

 if choice < 2
  dbcloseall()
  return

 endif

 do case
 case choice = 2
  Collrep()

 case choice = 3

  mscr := Box_Save( 5, 08, 9, 72 )
  dStartDate := Oddvars( SYSDATE ) - 30
  sStatus := "*"
  @ 6,10 say 'Enter starting Date' get dStartDate
  dEndDate := Oddvars( SYSDATE )
  @ 7,10 say '     Enter end Date' get dEndDate
  @ 8,10 say '    Contract Status' get sStatus pict '!' valid( sStatus = '*' .or. dup_chk( sStatus, 'Status' ) )
  read


  if updated() .and. ContSelect( @mStartCont, @mEndCont )
   if NetUse( "master" )
    if NetUse( "hirer" )
     if NetUse( "arrears" )
      set relation to arrears->con_no into hirer,;
                  to arrears->con_no into master
      farr := {}
      aadd( farr, { "left( Trim( hirer->first ) + ' ' + hirer->surname, 29 )", 'Hirer', 30, 0, FALSE } )
      aadd( farr, { 'arrears->amount', 'Amount', 9, 2, FALSE } )
      aadd( farr, { 'arrears->due', 'Due Date', 9, 0, FALSE } )
      aadd( farr, { 'arrears->stat1', 'First;Letter', 9, 0, FALSE } )
      aadd( farr, { 'arrears->stat2', 'Second;Letter', 9, 0, FALSE } )
      aadd( farr, { 'arrears->stat3', 'Third;Letter', 9, 0, FALSE } )
      aadd( farr, { 'arrears->date_paid', 'Date Paid', 9, 0, FALSE } )
      aadd( farr, { 'arrears->amt_paid', 'Amount;Paid', 9, 2, FALSE } )
      aadd( farr, { 'left( arrears->comments, 25 )', 'Comments', 25, 0, FALSE } )
      Reporter( farr, 'Contract Arrears', 'arrears->con_no', ;
                      '"Contract No "+Ns(arrears->con_no)', '', '', FALSE, ;
                      'mStartCont <= arrears->con_no .and. mEndCont >= arrears->con_no ' + ;
                      '.and. arrears->due >= dStartDate .and. arrears->due <= dEndDate .and. ' +;
                      ' (sStatus = "*" .or. master->status = sStatus )', , 80 )

      // EndPrint()

     endif
    endif
   endif
  endif
  dbcloseall()

 case choice = 4

  if NetUse( "hirer" )

   if NetUse( "master" )

    set relation to master->con_no into hirer

    Heading( 'Labels Print Menu' )

    aArray := {}
    aadd( aArray, { 'Quit', 'Return to Misc Reports' } )
    aadd( aArray, { 'Individual', 'Select Customers for label Print' } )
    aadd( aArray, { 'Envelopes', 'Select Customers for Envelope Print' } )
    aadd( aArray, { 'All', 'Print labels for all customers' } )
    tchoice := Menugen( aArray, 11, 37, 'Labels' )

    do case
    case tchoice = 2 .or. tchoice = 3

     while TRUE

      Heading( if( tchoice = 2, 'Individual Labels', 'Address Envelopes' ) )

      if !Con_find()
       exit

      else
       Box_Save( 06, 10, 09, 70 )
       Highlight( 07, 12, 'Hirer Name    -> ', trim( hirer->surname ) )
       Highlight( 08, 12, 'Hirer Suburb  -> ', trim( hirer->suburb ) )
       if Isready( )
        oPrinter := Printcheck( 'Envelopes/Labels for ' + hirer->surname )
        oPrinter:NewLine()
        oPrinter:NewLine()
#ifndef DISCOUNT
        oPrinter:NewLine()
        oPrinter:NewLine()
#endif
        oPrinter:NewLine()
        oPrinter:TextOUt( space( if( tchoice = 2, 0, 24 ) ) + trim( hirer->first ) + ' ' + hirer->surname )
        oPrinter:NewLine()
        oPrinter:TextOut( space( if( tchoice = 2, 0, 24 ) ) + trim( hirer->add1 ) )
        oPrinter:NewLine()
        oPrinter:TextOut( space( if( tchoice = 2, 0, 24 ) ) + trim( hirer->add2 ) )
        oPrinter:NewLine()
        oPrinter:TextOut( space( if( tchoice = 2, 0, 24 ) ) + trim( hirer->suburb ) + ' ' + hirer->pcode )
        oPrinter:endDoc()
        oPrinter:Destroy()

       endif
      endif
     enddo

    case tchoice = 4
#ifdef __XHARBOUR__
     Error( 'Not supported in Windows Version - yet', 12 )
#else
     Heading( 'Print Labels for all customers' )
     if ContSelect( @mStartCont, @mEndCont )
      Printcheck()
      label form conlabe.frm to print noconsole while inkey() != K_ESC ;
            for master->con_no >= mStartCont .and. master->con_no <= mEndCont ;
            .and. !master->inquiry sample

      // EndPrint()

     endif
#endif
    endcase
   endif
  endif
  dbcloseall()
  
 case choice = 5
  nuloop := FALSE
  if NetUse( "tran" )
   if NetUse( "hirer" )
    if NetUse( "arrears" )
     if NetUse( "master" )
      set relation to master->con_no into arrears,;
                   to master->con_no into hirer

      nuloop := TRUE

     endif
    endif
   endif
  endif

#define FIRSTLETTER      2
#define SECONDLETTER     3
#define THIRDLETTER      4
#define SELCUST          5
#define GSTLETTER        6
#define WORDPROC         7

  while nuloop

   mpercent1 := 0
   mpercent2 := 0

   Box_Restore( level4 )

   Heading( 'Letters Print Menu' )

   aArray := {}
   aadd( aArray, { 'Exit', 'Return to print menu' } )
   aadd( aArray, { '1st Letter', 'First arrears letter' } )
   aadd( aArray, { '2nd Letter', 'Second arrears letter' } )
   aadd( aArray, { '3rd Letter', 'Final arrears letter' } )
   aadd( aArray, { 'Customers', 'Letters to selected customers' } )
   aadd( aArray, { 'GST', 'Send GST increase warning letters' } )
   aadd( aArray, { 'Word Proc', 'Produce single letter' } )

   nLetterChoice := MenuGen( aArray, 11, 37, 'Statements' )

   if nLetterChoice < 2
    exit

   else

    Heading('Prepare Letters')

    Box_Save( 02, 08, 10, 72 )
    lPrintLetters =TRUE
    @ 3,10 say 'Print Letters? (Answering N will generate a Mailmerge File)' get lPrintLetters pict 'Y'
    if nLetterChoice >= FIRSTLETTER .and. nLetterChoice <= THIRDLETTER
     mdays := 0
     @ 4,10 say 'Number of days overdue to print' get mdays pict '999'
     read

    endif

    if nLetterChoice = GSTLETTER
     @ 04, 10 say 'Percentage1 increase' get mpercent1 pict '999.99'
     @ 05, 10 say 'Percentage2 increase' get mpercent2 pict '999.99'
     @ 06, 10 say 'Ignore Reminder Flag' get lReminders pict 'Y'

#ifdef RENTACENTRE
     @ 07, 10 say 'Starting Contract Number' get nGSTStartCont pict '999999'

#endif
     read

    endif

    lPrePrinted := NO

    if lPrintLetters              // We want to Print Letters

#ifdef PREPRINTED
     @ 7, 10 say 'Do you have preprinted letters' get lPrePrinted pict 'Y'
     read

#endif

     if !lPrePrinted
      mfile := 'LETTER' + Ns( nLetterChoice - 1 ) + space(8)
      @ 7, 10 say 'File name of letter' get mfile pict '@!R'
      read
      mfile := trim(mfile) + '.txt'

      if !file( mfile )
       Error('File not found',12)
       mcreate := NO
       @ 8, 10 say 'Create a new letter file' get mcreate pict 'Y'
       read

       if !mcreate
        loop

       else
        Edit_let( TRUE,mfile )
        Box_Restore( level4 )

       endif

      else
#ifndef COLOURBOND
       medit := YES

#else
       medit := NO

#endif
       @ 9,10 say 'Re-edit letter file' get medit pict 'Y'
       read
       if medit
        Edit_let( FALSE, mfile )

       endif

      endif

      Kill( "letter.dbf" )
      dbfstru := {}
      aadd( dbfstru , { 'line1', 'C', 78 , 0 } )
      dbcreate( 'Letter' , dbfstru )
      NetUse( "letter" )
      append from ( mfile ) sdf

     endif


     do case
     case nLetterChoice = FIRSTLETTER
      mhead := 'First Letter'
     case nLetterChoice = SECONDLETTER
      mhead := 'Second warning letter'
     case nLetterChoice = THIRDLETTER
      mhead := 'Third warning letter'
     case nLetterChoice = SELCUST
      mhead := 'Letters to selected customers'
     case nLetterChoice = WORDPROC
      mhead := 'Print WP'
     case nLetterChoice = GSTLETTER
      mhead := 'Print GST Notification Letter'
     endcase

     Heading( mhead )
     mtest := Isready( 'Print test sheet' )


     while mtest
      if mtest
       if lPrePrinted

        for x = 1 to 3
         Delinq( x, TRUE )

        next

       else
        mcontract := 0
        Cust_let( FALSE, mpercent1, mpercent2 )

       endif
       mtest := Isready( 'Print test again ?' )

      endif

     enddo

 else
     // '"' +
     sHeading =  'Contract No' + CSV + 'First Name' + CSV + 'Surname' + CSV + 'Address 1' + CSV + 'Address 2' + CSV + 'City' + CSV + ;
                 'PostCode' + CSV + 'Amt Owing' + CSV + 'Date Due' + CSV + 'System Date' + CRLF

    endif     // lPrintLetters

    if Isready( 'Ready to begin ' + if( lPrintLetters,'printing ?','creating Mailmerge file?') )

     do case

     case nLetterChoice = WORDPROC
      if !lPrintLetters
       sFileHandle = fcreate( 'Wordproc.csv' )
       fWrite( sFileHandle, sHeading )


      endif

      Cust_let( FALSE, 0, 0, lPrintLetters, sFileHandle )

     case ( nLetterChoice >= FIRSTLETTER .and. nLetterChoice <= THIRDLETTER ) ;
          .or. nLetterChoice = GSTLETTER

#ifdef ARGYLE
       master->( ordsetfocus( 'contract' ) )

#endif

      mcount := 1
      mdbf := {}
      aadd( mdbf, { 'con_no', 'n', 6, 0 } )
      aadd( mdbf, { 'record',  'n', 10, 0 } )
      dbcreate( 'updates', mdbf )

      NetUse( 'updates' )

      master->( dbgotop() )
     
      if !lPrintLetters
       sFileName = if( nLetterChoice = FIRSTLETTER, "Letter1", ;
                   if( nLetterChoice = SECONDLETTER, "Letter2", "Letter3" ) )

       sFileHandle = FCreate( sFilename + ".csv" )
       FWrite( sFileHandle, sHeading )

      endif

      while !master->( eof() ) .and. Pinwheel()

       if ( !master->inquiry .and. master->reminders .and. master->bal_bf < 0 ) ;
            .or. nLetterChoice = GSTLETTER

        do case
        case nLetterChoice = FIRSTLETTER
         select arrears
#ifndef RENTACENTRE
          locate for empty( arrears->stat1 ) .and. !arrears->paid .and. ;
                max( arrears->due + mdays, arrears->due + master->grace ) < Oddvars( SYSDATE );
               .and. !arrears->( eof() ) while arrears->con_no = master->con_no
#else
         // 14/03/11  don't print letter or apply late fee if balance owing < $10

           locate for empty( arrears->stat1 ) .and. !arrears->( eof() ) .and. !arrears->paid ;
               .and. max( arrears->due+mdays, arrears->due+master->grace ) < Oddvars( SYSDATE ) ;
               .and. master->bal_bf < -10 ;
               .and. master->con_no >= nGSTStartCont ;
                while arrears->con_no = master->con_no
#endif

         if found()
          mcontract := arrears->con_no
     
          if !lPrePrinted
           Cust_let( FALSE, mpercent1, mpercent2, lPrintLetters, sFileHandle )  // Don't fudge late fee

          else
           Delinq( mcount, FALSE )
           mcount++

          endif

          Add_rec( 'updates' )
          updates->con_no := master->con_no
          updates->record := arrears->( recno() )
          updates->( dbrunlock() )

         endif

        case nLetterChoice = SECONDLETTER
         select arrears

#ifndef RENTACENTRE
         locate for empty( arrears->stat2 ) .and. !empty( arrears->stat1 ) ;
               .and. !arrears->( eof() ) .and. !arrears->paid;
               .and. max( arrears->due+mdays, arrears->due+master->grace ) < Oddvars( SYSDATE );
                while arrears->con_no = master->con_no
#else

// 27/6/00 JR don't print second letter or apply late fee if balance owing < $10

         locate for empty( arrears->stat2 ) .and. !empty( arrears->stat1 ) ;
               .and. !arrears->( eof() ) .and. !arrears->paid ;
               .and. max( arrears->due+mdays, arrears->due+master->grace ) < Oddvars( SYSDATE ) ;
               .and. master->bal_bf < -10 ;
               .and. master->con_no >= nGSTStartCont ;
                while arrears->con_no = master->con_no
#endif
         if found()

          mcontract := arrears->con_no

          if !lPrePrinted
           Cust_let( TRUE, mpercent1, mpercent2, lPrintLetters, sFileHandle )  // Fudge Late Fee on Print out if required

          else
           Delinq( mcount, FALSE )
           mcount++

          endif

          Add_rec( 'updates' )
          updates->con_no := master->con_no
          updates->record := arrears->( recno() )
          updates->( dbrunlock() )

         endif

        case nLetterChoice = THIRDLETTER
         select arrears
         locate for empty(arrears->stat3) .and. !empty( arrears->stat2 ) .and. !empty(arrears->stat1);
          .and. !arrears->( eof() ) .and. !arrears->paid;
          .and. max(arrears->due+mdays,arrears->due+master->grace) <  Oddvars( SYSDATE );
           while arrears->con_no = master->con_no

         if found()

          if !lPrePrinted
           Cust_let( FALSE, mpercent1, mpercent2, lPrintLetters, sFileHandle )  // Don't Fudge late fee

          else
           Delinq( mcount, FALSE )
//           Delinq( mcount, oPrinter, FALSE )
           mcount++

          endif

          Add_rec( 'updates' )
          updates->con_no := master->con_no
          updates->record := arrears->( recno() )
          updates->( dbrunlock() )

         endif

        case nLetterChoice = GSTLETTER
#ifdef ARGYLE
         if ( !master->inquiry .and. ( master->reminders .or. lReminders ) ) .and. master->con_no < 800000 .and. master->term_rent = 'M'

#else
         if ( !master->inquiry .and. ( master->reminders .or. lReminders ) )

#endif
          Cust_let( FALSE, mpercent1, mpercent2, lPrintLetters, sFileHandle )

         endif

        endcase

       endif

       master->( dbskip() )

      enddo

      if nLetterChoice >= FIRSTLETTER .and. nLetterChoice <= THIRDLETTER

       if updates->( lastrec() ) > 0
     
        if Isready( 'Ok to update files?' )

         Box_Save( 10, 10, 13, 70 )
         Highlight( 11, 12, 'Records to update', Ns( updates->( lastrec() ) ) )

         updates->( dbgotop() )
         while !updates->( eof() )

          Highlight( 12, 12, 'Records updated', Ns( updates->( recno() ) ) )

          arrears->( dbgoto( updates->record ) )
          Rec_lock( 'arrears' )

          do case
          case nLetterChoice = FIRSTLETTER
           arrears->stat1 := Oddvars( SYSDATE )

           if Bvars( B_LATE_FEE1 )

            if master->( dbseek( updates->con_no ) )
             Rec_lock( 'master' )
             master->bal_bf  -= Bvars( B_LATE_AMT1 )
             master->( dbrunlock() )

            endif
            
            Add_rec( 'tran' )
            tran->con_no := updates->con_no
            tran->type := 'L'
            tran->value := -Bvars( B_LATE_AMT1 )
            tran->date := Oddvars( SYSDATE )
            tran->narrative := 'Late fee for ' + dtoc( Oddvars( SYSDATE ) )
            if Bvars( B_LATE_GST )
             tran->gst += GstPaid( Bvars( B_LATE_AMT1 ) )
            endif
            tran->( dbrunlock() )

           endif

          case nLetterChoice = SECONDLETTER
           arrears->stat2 := Oddvars( SYSDATE )

           if Bvars( B_LATE_FEE )

            if master->( dbseek( updates->con_no ) )
             Rec_lock( 'master' )
             master->bal_bf  -= Bvars( B_LATE_AMT )
             master->( dbrunlock() )

            endif
            
            Add_rec( 'tran' )
            tran->con_no := updates->con_no
            tran->type := 'L'
            tran->value := -Bvars( B_LATE_AMT )
            tran->date := Oddvars( SYSDATE )
            tran->narrative := 'Late fee for ' + dtoc( Oddvars( SYSDATE ) )
            if Bvars( B_LATE_GST )
             tran->gst += GstPaid( Bvars( B_LATE_AMT ) )
            endif
            tran->( dbrunlock() )

           endif

          case nLetterChoice = THIRDLETTER
           arrears->stat3 := Oddvars( SYSDATE )

          endcase

          arrears->( dbrunlock() )

          updates->( dbskip() )

         enddo

        endif

       endif

      endif

      updates->( dbclosearea() )

      Bvars( B_ARR_RUN, Oddvars( SYSDATE ) )

      BvarSave()

      if !lPrintLetters
       fClose( sFileHandle )

      endif

     case nLetterChoice = SELCUST
      if !lPrintLetters
       sFileHandle := fCreate( "wordproc.csv" )

      endif

      while Con_find()
       Cust_let( FALSE, mpercent1, mpercent2, lPrintLetters, sFileHandle )

      enddo

      if !lPrintLetters
       fClose( sFileHandle )

      endif

     endcase


    endif

    if lPrintLetters .and. !lPrePrinted
     letter->( dbclosearea() )

    endif

   endif

  enddo

  dbcloseall()

case choice = 6
  if NetUse( "hirer" )
   if NetUse( "master" )
    set relation to master->con_no into hirer

    Box_Save( 3, 10, 5, 70 )
    mPrintDate := Oddvars( SYSDATE )

    @ 04, 12 say 'Date for print' get mPrintDate
    read

    farr := {}
    aadd( farr, { 'master->con_no', 'Contract;Number', 9, 0, FALSE } )
    aadd( farr, { "left( Trim( hirer->first ) + ' ' + hirer->surname, 29 )", 'Hirer', 22, 0, FALSE } )
    aadd( farr, { 'master->cred_card', 'Card Number', 23, 0, FALSE } )
    aadd( farr, { 'master->expirydate', 'Exp', 4, 0, FALSE } )
    aadd( farr, { 'master->card_id', 'ID', 4, 0, FALSE } )
    aadd( farr, { 'master->install', 'Amount', 8, 2, TRUE } )
  #ifdef MEDI
    Reporter( farr, ' Credit Cards Due on ' + dtoc( mPrintdate), '', '', '', '', FALSE, ;
                    "master->next_inst = mPrintDate .and. master->billmethod = 'C' .and. !master->inquiry", , 80 )
  #else
    Reporter( farr, ' Credit Cards Due on ' + dtoc( mPrintdate), '', '', '', '', FALSE, ;
                     "master->next_inst = mPrintDate .and. !empty( master->cred_card ) .and. !master->inquiry", , 80 )
  #endif
//    EndPrint()

   endif
  endif
  dbcloseall()

case choice = 7
  if NetUse( "hirer" )
   if NetUse( "master" )
    set relation to master->con_no into hirer

    Box_Save( 3, 10, 6, 70 )
    dStartDate := Oddvars( SYSDATE )
    dEndDate := Oddvars( SYSDATE ) + 30

    @ 04, 12 say 'Start Date for print' get dStartDate
    @ 05, 12 say 'End Date for print' get dEndDate
    read

    farr := {}
    aadd( farr, { 'master->con_no', 'Contract;Number', 9, 0, FALSE } )
    aadd( farr, RPT_SPACE )
    aadd( farr, { "left( Trim( hirer->first ) + ' ' + hirer->surname, 29 )", 'Hirer', 31, 0, FALSE } )
    aadd( farr, { 'master->EndDate', 'End Date', 8, 0, FALSE } )
    aadd( farr, { 'master->install', 'Install', 8, 2, TRUE } )
    Reporter( farr, 'Contracts Ending between ' + dtoc( dStartDate) + ' and ' + dtoc( dEndDate ) , '', '', '', '', FALSE, ;
                     "master->EndDate >= dStartDate .and. master->EndDate <= dEndDate .and. !master->inquiry", , 80 )
 //   EndPrint()

   endif
  endif
  dbcloseall()

 endcase

enddo

return

*

procedure cust_let ( add_late_fee, mpercent1, mpercent2, lPrintLetters, sFileHandle, lCustStat, dStart, dFinish )

local mbname := trim( BVars( B_COMPANY ) )
local mbadd1 := trim( Bvars( B_ADDRESS1 ) )
local mbadd2 := trim( Bvars( B_ADDRESS2 ) )
local mfirst := trim( hirer->first )
local msurname := trim( hirer->surname )
local madd1 := trim( hirer->add1 )
local madd2 := trim( hirer->add2 )
local msub := trim( hirer->suburb )
local mpcode := trim( hirer->pcode )
local cEmail := trim(hirer->email )
local cPhone := trim( hirer->tele_priv )

local mamt := master->bal_bf * -1
local mdue := dtoc( master->paid_to )
local mdate := dtoc( Bvars( B_SYSDATE ) )

local mpos
local mline
local oPrinter
local sOut   // Output String

default add_late_fee to FALSE
default mpercent1 to 0
default mpercent2 to 0
default lPrintLetters to TRUE
default lCustStat to FALSE
default dStart to NULL_DATE
default dFinish to NULL_DATE

if add_late_fee .and. Bvars( B_LATE_FEE )
 mamt += Bvars( B_LATE_AMT )

endif
 
Box_Save( 14, 03, 19, 76 )
Highlight( 15, 04, 'Customer->', msurname )
Highlight( 16, 04, 'Contract #', Ns( master->con_no ) )
Highlight( 17, 04, '  Due date', mdue )
Highlight( 18, 04, 'Amount due', Ns( mamt ) )

if !lPrintLetters

 sOut = ns( master->con_no) + CSV + mFirst + CSV + msurname + CSV + madd1 + CSV + madd2 + CSV + msub + CSV + ;
        mpcode + CSV + ns( mamt ) + CSV + mdue + CSV + mdate + CSV + cPhone + CSV + cEmail + CRLF

 FWrite ( sFileHandle, sOut )

else
 oPrinter := PrintCheck( 'Customer Letter' )
// oPrinter:SetFont('Arial', 12, {3, 50} )

 letter->( dbgotop() )

 while !letter->( eof() )

  mline := trim( letter->line1 )

  if '%SURNAME' $ mline
   mpos := at( '%SURNAME', mline )
   mline := trim( left( mline, mpos-1 ) + msurname + trim( substr(mline, mpos+8, 78 ) ) )

  endif

  if '%FIRST' $ mline
  mpos := at('%FIRST',mline)
  mline := trim( left( mline, mpos-1 ) + mfirst + trim( substr( mline, mpos+6, 78 ) ) )

  endif

  if '%ADD1' $ mline
   mpos := at('%ADD1',mline)
   mline := trim( left( mline, mpos-1 ) + madd1 + trim( substr( mline, mpos+5, 78 ) ) )

  endif

  if '%ADD2' $ mline
   mpos := at('%ADD2',mline)
   mline := trim( left( mline, mpos-1 ) + madd2 + trim( substr( mline, mpos+5, 78 ) ) )

  endif

  if '%SUBURB' $ mline
   mpos := at('%SUBURB',mline)
   mline := trim( left( mline, mpos-1 ) + msub + trim( substr( mline, mpos+7, 78 ) ) )

  endif

  if '%PCODE' $ mline
   mpos := at('%PCODE',mline)
   mline := trim( left( mline, mpos-1 ) + mpcode + trim( substr( mline, mpos+6, 78 ) ) )

  endif

  if '%AMT' $ mline
   mpos := at('%AMT',mline)
   mline := trim( left( mline, mpos-1 ) + Ns( mamt, 7, 2 ) + trim( substr( mline, mpos+4, 78 ) ) )

  endif

  if '%DUE' $ mline
   mpos := at('%DUE',mline)
   mline := trim( left( mline, mpos-1 ) + mdue + trim( substr( mline, mpos+4, 78 ) ) )

  endif

  if '%DATE' $ mline
   mpos := at('%DATE',mline)
   mline := trim( left( mline, mpos-1 ) + mdate + trim( substr( mline, mpos+5, 78 ) ) )

  endif

  if '%CONTRACT' $ mline
   mpos := at('%CONTRACT',mline)
   mline := trim( left( mline, mpos-1 ) + Ns( master->con_no, 6, 0 ) + ;
            trim( substr( mline, mpos+9, 78 ) ) )
  endif

  if '%INSTALL' $ mline
   mpos := at('%INSTALL',mline)
   mline := trim( left( mline, mpos-1 ) + Ns( master->install, 7, 2 ) + trim( substr( mline, mpos + 8, 78 ) ) )

  endif

  if '%PERCENT1' $ mline
   mpos := at( '%PERCENT1', mline )
   mline := trim( left( mline, mpos-1 ) + Ns( master->install + ( ( master->install / 100 ) * mPercent1 ), 6, 2 ) +;
           trim( substr( mline, mpos+9, 78 )))

  endif

  if '%PERCENT2' $ mline
   mpos := at( '%PERCENT2', mline )
   mline := trim( left( mline, mpos-1 ) + Ns( master->install + ( ( master->install / 100 ) * mPercent2 ), 6, 2 ) +;
            trim( substr( mline, mpos+9, 78 )))

  endif

  if '%PAGE' $ mline
   oPrinter:NewPage()
   mline := 0
   exit

  else
   oPrinter:newLine()
   oPrinter:TextOut( trim( mline ) )

  endif

  letter->( dbskip() )

 enddo

 oPrinter:endDoc()
 oPrinter:Destroy()

endif
select arrears

return

*

procedure edit_let ( new, mfile )
local dummy, mscr := Box_Save( 02, 02, 24, 78 )
local okf10 := setkey( K_F10, { || let_help() } )
set scoreboard on
if new
 Heading('Create new letter file')
 @ 02,05 say '[ ' + mfile + ' ]'

else
 Heading('Edit letter file')
 @ 02,05 say '[ Edit file ' + mfile + ' ]'

endif
@ 02,38 say '[ Use <Ctrl-W> to save this file ]'
@ 24,05 say '[ Hit F10 for help ]'
syscolor(2)
dummy := memoedit( memoread( mfile ), 3, 3, 23, 77, TRUE )
syscolor(1)
memowrit( mfile, hardcr( dummy ) )
setkey( K_F10, okf10 )
set scoreboard off
Box_Restore( mscr )
return

*

procedure let_help
local help:=savescreen(),mrow:=row(),mcol:=col(),oldcur:=setcursor(0)
cls
text
                           Editing Commands

 <Ctrl-W>  Write out text   <Ctrl-Y> Delete line    <Ins> Toggle insert mode

 <Esc> Abandon editing      <Ctrl-N> Insert a new line

 <Ctrl-T> Delete Word

endtext
Centre( 15, '[  Rentals Substitute Variables  ]' )
@ 17,04 say '%FIRST   -> first name   %ADD1 -> address line 1  %SUBURB   -> suburb'
@ 18,04 say '%SURNAME -> surname      %ADD2 -> address line 2  %PAGE     -> new page'
@ 19,04 say '%AMT     -> amount due   %DUE  -> date due        %CONTRACT -> cont. no'
@ 20,04 say '%DATE    -> system date  %PCODE-> postcode        %GST      -> Install+GST'
@ 21,04 say '%PERCENT1 -> % Install   %PERCENT2 % of install   %INSTALL  ->Install.'
@ mrow, mcol say ''
inkey(0)
restscreen( 0, 0, 24, 79, help )
setcursor( oldcur )
return

*

procedure delinq ( stat_num, lTest )
// procedure delinq ( stat_num, oPrinter, lTest )
local cAmt := if( lTest, "9999.99", Ns( master->bal_bf * -1, 7, 2 ) )
local mdue := if( lTest, "99/99/99", dtoc( master->paid_to ) )
local nlet_conno := if( lTest, '999999', Ns( master->con_no, 6 ) )
local cTestSpace := 'XXXXXXXXXXXXXXXXXXXXXXXX'

if !lTest
 Box_Save( 14, 03, 19, 76 )
 Highlight( 15, 04, 'Customer->', hirer->surname )
 Highlight( 16, 04, 'Contract #', nLet_Conno )
 Highlight( 17, 04, '  Due date', mdue )
 Highlight( 18, 04, 'Amount due', cAmt )

endif

Print_find('letter')

set console off
set print on

?
?
? space(28) + cAmt
? space(13) + 'Account no ' + nLet_Conno
? space(13) + mdue
?
?
? space(15) + if( ltest, ctestSpace, trim(hirer->first)+' '+hirer->surname )
? space(15) + if( ltest, ctestSpace, hirer->add1 )
? space(15) + if( ltest, ctestSpace, hirer->add2 )
? space(15) + if( ltest, ctestSpace, trim(hirer->suburb) + ' ' + hirer->pcode )
?
?
?
?
?
?
?
?
?
if int(stat_num/3) = stat_num/3
 ? chr(12)

endif

set console on
set print off

set printer to

return

*

Procedure OwnerRep

local aFlds

Heading('Print owners by code')

if Isready(12)

 if NetUse( "owner" )
  aFlds := {}
  aadd( aflds, { 'owner->code', 'Owner;Code', 6, 0, FALSE } )
  aadd( aflds, { 'trim(owner->add1)+" "+trim(owner->add2)', 'Address', 30, 0, FALSE } )
  aadd( aflds, { 'owner->phone', 'Phone No', 14, 0, FALSE } )
  aadd( aflds, { 'owner->contact', 'Contact Name', 30, 0, FALSE } )

  Reporter( aFlds, ;
           'List of Owners',;
           '',;
           '' ,;
           '',;
           '',;
           FALSE,;
           '',;
           '',;
           132 ;
          )

  dbcloseall()

 endif
endif
return

*

function ContSelect ( mStartCont, mEndCont )
local getlist := {}
local mret := FALSE

Heading('Select Contracts to Print')
Box_Save( 2, 08, 05, 72 )

mStartCont := 0
mEndCont := 999999
@ 3,10 say 'Start contract # or <Enter> for all contracts' get mStartCont pict '999999'
read

mret := !( lastkey() = K_ESC )
 
if mret .and. updated()
 @ 4,10 say 'Last contract # or <enter> for remainder' get mEndCont pict '@k' ;
        valid mEndCont >= mStartCont
 read
endif

mret := Isready(12)

return mret

