/*

 Rentals - Bluegum Software
 Module Collrep - Special Collection List

      Last change:  TG   14 Feb 2012   10:08 pm

*/

#include "winrent.ch"

Procedure CollRep

local ok := FALSE
local msur, mfirst
local moverdue
local msort
local marea
local getlist:={}
local page_number
local page_width
local page_len
local top_mar
local bot_mar
local report_name
local col_head1
local col_head2
local m_conno
local mrent
local int_row
local mrec
local mstr
local mtotowing := 0
local mstart := 'A'
local mfinish := 'Z'
local oPrinter
local sStatus := '*'
local toScreen := FALSE
local cFile
local oFSO, oShell

if NetUse( 'tran' )

 if NetUse( 'arrears' )

  if NetUse( 'hirer'  )

   if NetUse( 'items'  )
    items->( ordsetfocus( 'contract' ) )

    if NetUse( 'master' )
     set relation to master->con_no into items,;
                  to master->con_no into hirer,;
                  to master->con_no into arrears
     ok := TRUE
    endif
   endif
  endif
 endif
endif

if ok

 Box_Save( 02, 08, 11, 72 )
 Heading( 'Collection list' )

 moverdue := 3
#ifdef ARGYLE
 msort := 'C'
#else
 msort := 'A'
#endif
 marea := 'ALL'

 @ 03,10 say '           Days overdue to print' get moverdue pict '999'
 @ 05,10 say '                 Collection Area' get marea pict '!!!'
 @ 07,10 say 'Sort on <A>lpha or <C>ontract no' get msort pict '!' valid( msort $ 'AC' )
 @ 09,10 say '                 Contract Status' get sStatus pict '!' valid( sStatus = '*' .or. dup_chk( sStatus, 'Status' ) )
#ifdef DISCOUNT
 @ 09,10 say '                    Start Letter' get mstart pict '!' when msort = 'A'
 @ 10,10 say '                   Finish Letter' get mfinish pict '!' when msort = 'A'
#endif
 read

 select master

 if msort = 'A'  // Alpha

  if marea != 'ALL'
   indx( 'area + upper( skey )', 'temp' )

  else
   indx( 'upper( skey )', 'temp' )

  endif

 else
  if marea != 'ALL'
   indx( 'area + padl( con_no, 6, "0" )', 'temp' )

  else
   ordsetfocus( 'contract' )

  endif

 endif

 toScreen := Isready( 'Print to Screen' )

 if toScreen
 // TRY
   oFSO := CreateObject( "Scripting.FileSystemObject" )

//  CATCH
//   Alert( "ERROR! Problem with Scripting host FSO [" + Ole2TxtError()+ "]" )

//  END
  cFile := trim( netname() ) + ".txt"
  oPrinter:= oFSO:CreateTextFile( cFile, VBTRUE )

 else  // to Screen
  oPrinter := Printcheck( 'Collection Report' )

 endif

 page_number := 1
 page_width := 119
 page_len := 66
 top_mar := 0
 bot_mar := 5
 report_name := 'Collection List for - ' + dtoc( Oddvars( SYSDATE ) )
 col_head1 := "Account  Hirer's Name & Address     Telephone      Paid to     Amount  Items               Desc                Install"
 col_head2 := "                                    Comments     Commenced    Install"

 PageHead( oPrinter, report_name, page_width, page_number, col_head1, col_head2, toScreen )

 master->( dbgotop() )

#ifdef DISCOUNT

 if marea = 'ALL' .and. msort = 'A'
  set( _SET_SOFTSEEK, TRUE )
  master->( dbseek( mstart ) )
  set( _SET_SOFTSEEK, FALSE )

 endif

#endif

 while !master->( eof() ) .and. inkey() != K_ESC .and. PinWheel()

  if ( master->paid_to + moverdue <= Oddvars( SYSDATE ) ) .and. ;
       master->bal_bf < 0 .and. ;
       !master->inquiry .and. ;
       ( marea = 'ALL' .or. master->area = marea ) .and. ;
       (sStatus = '*' .or. master->status = sStatus )

#ifdef DISCOUNT
  if ( if( msort != 'A', TRUE, upper( master->skey ) >= mstart .and. upper( master->skey ) <= mfinish ) )
#endif

   m_conno = master->con_no
   mrent = master->term_rent + '_rent'

   for int_row := 1 to 5    // Only showing the first 5 items on a contract

    do case
    case int_row = 1
     select hirer
     hirer->( dbseek( m_conno ) )
     mrec = hirer->( recno() )
     msur = ''
     mfirst = ''
     while hirer->con_no = m_conno .and. !hirer->( eof() )
      msur += trim( hirer->surname ) + '/'
      mfirst += trim( hirer->first ) + '/'
      hirer->( dbskip() )

     enddo
     hirer->( dbseek( m_conno ) )
     msur = left( msur, len( trim( msur ) ) -1 )
     mfirst = left( mfirst, len( trim( mfirst ) ) -1 )
     if !toScreen
      oPrinter:NewLine()
      oPrinter:setpos( 0 )
      oPrinter:textout( Transform( master->con_no, CON_NO_PICT ) )
      oprinter:setpos( 10 * oPrinter:CharWidth )
      oPrinter:textout( left( msur, 26 ) )
      oprinter:setpos( 35 * oPrinter:CharWidth )
      oPrinter:textout( hirer->tele_priv )
      oprinter:setpos( 50 * oPrinter:CharWidth )
      oPrinter:textout( dtoc( master->paid_to ) )
      oprinter:setpos( 60 * oPrinter:CharWidth )
      oPrinter:textout( transform( master->bal_bf, CURRENCY_PICT ) )

  else
      oPrinter:Write( CRLF )
      oPrinter:Write( padr( Transform( master->con_no, CON_NO_PICT ), 10 ) )
      oPrinter:Write( padr( left( msur, 26 ), 27 ) )
      oPrinter:Write( padr( hirer->tele_priv, 15 ) )
      oPrinter:Write( padr( dtoc( master->paid_to ), 9 ) )
      oPrinter:Write( transform( master->bal_bf, CURRENCY_PICT ) )

     endif

    case int_row = 2
     if !toScreen
      oPrinter:NewLine()
      oPrinter:setpos( 0 )
      oPrinter:textout( transform( master->dep_no, CON_NO_PICT ) )
      oprinter:setpos( 10 * oPrinter:CharWidth )
      oPrinter:textout( left( mfirst, 26 ) )
      oprinter:setpos( 35 * oPrinter:CharWidth )
      oPrinter:textout( hirer->tele_empl )
      oprinter:setpos( 50 * oPrinter:CharWidth )
      oPrinter:textout( padr( dtoc( master->commenced ), 9 ) )
      oprinter:setpos( 60 * oPrinter:CharWidth )
      oPrinter:textout( transform( master->install, CURRENCY_PICT ) )

     else
      oPrinter:write( CRLF )
      oPrinter:write( padr( transform( master->dep_no, CON_NO_PICT ), 10 ) )
      oPrinter:write( padr( left( mfirst, 26 ), 27 ) )
      oPrinter:write( padr( hirer->tele_empl, 15 ) )
      oPrinter:write( padr( dtoc( master->commenced ), 9 ) )
      oPrinter:write( transform( master->install, CURRENCY_PICT ) )

     endif

    case int_row = 3
     if !toScreen

      oPrinter:NewLine()
      oprinter:setpos( 10 * oPrinter:CharWidth )
      oPrinter:textout( left( trim( hirer->add1 ) + ' ' + hirer->add2, 26 ) )
      oprinter:setpos( 38 * oPrinter:CharWidth )
      oPrinter:textout( left( master->comments1, 22 ) )

     else
      oPrinter:write( CRLF )
      oPrinter:write( space(10 ) )
      oPrinter:write( padr( left( trim( hirer->add1 ) + ' ' + hirer->add2, 26 ), 27 ) )
      oPrinter:write( padr( left( master->comments1, 30 ), 33 ) )

     endif

    case int_row = 4
     if !toScreen
      oPrinter:NewLine()
      oprinter:setpos( 10 * oPrinter:CharWidth )
      oPrinter:textout( trim( hirer->suburb ) + ' ' + hirer->pcode )
      oprinter:setpos( 38 * oPrinter:CharWidth )
      oPrinter:textout( left( master->comments2, 22 ) )

    else
      oPrinter:Write( CRLF )
      oPrinter:write( space(10) )
      oPrinter:Write( padr( trim( hirer->suburb ) + ' ' + hirer->pcode, 27 ) )
      oPrinter:Write( padr( left( master->comments2, 30 ), 33 ) )

     endif

    case int_row = 5
     select tran
     dbseek( master->con_no+1, TRUE )  // Softseek
     tran->( dbskip( -1 ) )
     mstr := ''
     while tran->con_no = master->con_no .and. !tran->( bof() )
      if tran->type = 'P'
       mstr := 'Last Payment =>' + dtoc( tran->date ) + ' ' + transform( tran->value, CURRENCY_PICT )
       exit

      else
       tran->( dbskip( -1 ) )

      endif

     enddo

     if !empty( mstr )

      if !toScreen
       oPrinter:NewLine()
       oprinter:setpos( 36 * oPrinter:CharWidth )
       oPrinter:textout( mstr )


      else
       oPrinter:write( CRLF )
       oPrinter:write( space( 37 ) )
       oPrinter:Write( mstr )

      endif

     endif

    endcase

    select items
    if items->( dbseek( m_conno ) )

     items->( dbskip ( int_row -1 ) )
     if items->con_no = m_conno .and. items->status = 'H'
      if !toScreen
       oprinter:setpos( 72 * oPrinter:CharWidth )
       oPrinter:textout( items->serial )
       oprinter:setpos( 83 * oPrinter:CharWidth )
       oPrinter:textout( items->model )
       oprinter:setpos( 93 * oPrinter:CharWidth )
       oPrinter:textout( items->desc )
       oprinter:setpos( 120 * oPrinter:CharWidth )
       oPrinter:textout(transform( &mrent, CURRENCY_PICT ) )

      else
       oprinter:write( if( int_row > 4, space( 72), space( 2 ) ) )
       oPrinter:write( padr( items->serial, 10 ) )

       oPrinter:write( padr( items->model, 10 ) )
       oPrinter:write( padr( items->desc, 18 ) )
       oPrinter:write(transform( &mrent, CURRENCY_PICT ) )

      endif

     endif

    endif

    if PageEject( oPrinter, toScreen )
     page_number++
     PageHead( oPrinter, report_name, page_width, page_number, col_head1, col_head2, toScreen )

    endif

   next // int_row

   mtotowing += master->bal_bf

   if !toScreen
    oPrinter:NewLine()

   else
    oPrinter:Write( CRLF )

   endif

  endif

#ifdef DISCOUNT
  endif
#endif

  master->( dbskip() )

 enddo

 master->( orddestroy( 'temp' ) )

 if !toScreen
  oprinter:setpos( 59 * oPrinter:CharWidth )
  oPrinter:textout( replicate( '=', 11 ) )

  oPrinter:NewLine()
  oprinter:setpos( 59 * oPrinter:CharWidth )
  oPrinter:textout(transform( mtotowing, '99999999.99' ) )

 else
  oprinter:write( space( 59 ) )
  oPrinter:write( replicate( '=', 11 ) )

  oPrinter:write( CRLF )
  oprinter:write( space( 59 ) )
  oPrinter:write( transform( mtotowing, '99999999.99' ) )

 endif

 if toScreen
  oShell := CreateObject( "Wscript.Shell" )
  oShell:Exec( bvars( B_EDITOR ) + ' ' + cFile )

 else
  oPrinter:endDoc()
  oPrinter:Destroy()

 endif

endif

dbcloseall()

return

*

Function PageHead( oPrinter, rptName, page_width, page, col_head1, col_head2, toScreen )
local a := dtoc( date() )
local b := "Page " + Ns( page )
local mlicense := BVars( B_COMPANY )

if !toScreen
 if rptName != nil
  oPrinter:TextOut( mlicense )
  oPrinter:SetPos( (page_width -len(a)) * oPrinter:CharWidth )
  oPrinter:TextOut( a )
  oPrinter:NewLine()
  oPrinter:TextOut( rptName )
  oPrinter:SetPos( (page_width -len(b)) * oPrinter:CharWidth )
  oPrinter:TextOut( b )

 endif

 if col_head1 != nil
  oPrinter:NewLine()
  oPrinter:setPos(1)
  oPrinter:textOut( col_head1 )

 endif

 if col_head2 != nil
  oPrinter:NewLine()
  oPrinter:setPos(1)
  oPrinter:textOut( col_head2 )

 endif

 oPrinter:newline()
 oPrinter:textOut( replicate( '-', page_width ) )

else
 if rptName != nil
  oPrinter:write( mlicense )
  oPrinter:write( space( page_width - len(mLicense) - len(a) ) )
  oPrinter:write( a )
  oPrinter:write( CRLF )
  oPrinter:write( rptName )
  oPrinter:write( space( page_width - len(rptName)- len(b) ) )
  oPrinter:write( b )

 endif

 if col_head1 != nil
  oPrinter:write( CRLF )
  oPrinter:write( space(1) )
  oPrinter:write( col_head1 )

 endif

 if col_head2 != nil
  oPrinter:write( CRLF )
  oPrinter:write( space( 1 ) )
  oPrinter:write( col_head2 )

 endif

 oPrinter:write( CRLF )
 oPrinter:write( replicate( '-', page_width ) )

endif

return nil

*

Function PageEject (  oPrinter, toScreen )
local need_eject := FALSE
default toScreen to FALSE
if !toScreen
 if oPrinter:prow() > oPrinter:MaxRow() - 6  // Could use "oPrinter:NewPage()" to start a new page
  oPrinter:NewPage()
  need_eject = TRUE

 endif
endif

return need_eject

