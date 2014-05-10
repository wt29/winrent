/** @package 

        smtp.prg
        
      Last change:  TG    3 Jan 2011    1:14 pm
*/
#include "winrent.ch"
PROCEDURE SMTP_SEND ( testmsg )


      LOCAL oSmtp, oEMail
      LOCAL cSmtpUrl, aTo
      LOCAL cSubject, cFrom, cTo, cBody, cFile

 if testmsg = TRUE

      // preparing data for eMail
      cSmtpUrl := "smtp://3Pulsars:agp27s@mail.tpg.com.au"
      cSubject := "Testing eMail"
      cFrom    := "3Pulsars@tpgi.com.au"
      cTo      := "tglynn@hotmail.com"
      cFile    := "File_Attachment.zip"
      cBody    := "This is a test mail sent at: " + DtoC(Date()) + " " + Time()
      aTo      := { "tglynn@hotmail.com" }


   cSMTPServer   := "mail.tpg.com.au"
   cPopServer    := "pop.tpg.com.au"
   cFrom         := "tony@bluegumsoftware.com"
   cTo           := "tglynn@hotmail.com"
   cSMTPPassWord := "MySmtpPassword"

// hb_SendMail( cServer, nPort, cFrom, xTo, xCC, xBCC, cBody, cSubject, aFiles, cUser, cPass, cPopServer, nPriority, lRead, bTrace, lPopAuth, lNoAuth, nTimeOut, cReplyTo, lTLS, cSMTPPass, cCharset, cEncoding )

   MessageBox( iif(hb_SendMail( cSMTPServer,;
                  NIL,;
                  cFrom,;
                  cTo,;
                  NIL /* CC */,;
                  NIL /* BCC */,;
                  "test: body",;
                  "test: subject",;
                  {"smtp.prg"} /* attachment */,;
                  cFrom,;
                  NIL /* Password */,;
                  NIL /* cPopServer */,;
                  NIL /* nPriority */,;
                  NIL /* lRead */,;
                  .T. /* lTrace */,;
                  .F. /* lPopAuth */,;
                  .F. /* lNoAuth */,;
                  NIL /* nTimeOut */,;
                  NIL /* cReplyTo */,;
                  .F. /* lTLS */,;
                  /*cSMTPPassWord*/ ), "Successfully", "Unsuccessfully"), "Result" )


/*      HB_SendMail( "mail.tpg.com.au", 25, cFrom, aTo, , , cFile, cSubject, , , )

      // preparing eMail object
      oEMail   := TIpMail():new()
      oEMail:setHeader( cSubject, cFrom, cTo )
      oEMail:setBody( cBody )
 //     oEMail:attachFile( cFile )

      // preparing SMTP object
      oSmtp := TIpClientSmtp():new( cSmtpUrl )

      // sending data via internet connection
      IF oSmtp:open()
         oSmtp:sendMail( oEMail )
         oSmtp:close()
         Alert( "Mail sent" )
      ELSE
         Alert(  "Error:" + oSmtp:lastErrorMessage() )
      ENDIF
 */
    endif

   RETURN

