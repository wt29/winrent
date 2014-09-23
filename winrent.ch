/** @package

      Rentals.ch

      Last change: APG 12/04/2009 5:42:56 PM

      Last change:  TG   20 Jan 2012   10:50 am

Version History
1.25	Argyle - export function
1.23    RentaCenter - lots of work here
1.22    Errors folder, more work for both Renta and Byrnes Needed this number to get the versions straight
1.21    More work for Wayne Byrnes. Added the letter mailmerge stuff
1.19    Started to align code with BPOS. Some routines, including backup almost the same.
1.18    Enabled some mouse stuff. Adjusted Backup/Restore routines.
1.14    Fixed pre-printed letters
1.13    Some revisions on Item Status fields. Courier new default font for print screen
1.12    Status field added to Items file. Serial number raised to 40 Chars
1.11    Collection Report fixed. Added Print to screent
1.10    Argyle - added 2nd Printer Selection - waste of time in the end as he won't be using preprinted statements

*/
#include "inkey.ch"
#include "dbinfo.ch"
#include "tbrowse.ch"

#define BUILD_NO "1.27"
#define BUILD_DATE "October 2012"

#define SUPPORT_EMAIL 'tglynn@hotmail.com'
#define SUPPORT_PHONE '+61 2 4751-8497'
#define SUPPORT_FAX   'No Fax Number'

#define SYSNAME 'Winrent'

#define DEVELOPER 'Bluegum Software'

#define EVALEXP '01/12/2010'

#define RENTACENTRE
// define BYRNES
// #define ARGYLE
// #define DIRECT

#define CRYPTKEY 'BOLLOCKS'

#define C_BACKGROUND 'BG'

// #define SQL
#define TXTFILES   // uses TXT files as the comments files - abandoned all other comment files. Disk is Soooo.... cheap.

#ifdef SQL
 #include "sqlrdd.ch"

#endif

#define __GTWVW__

#define TEMP_EXT '.r2K'

#define CRLF chr( 13 ) + chr( 10 )
#define CR chr( 13 )
#define FF chr( 12 )
#define LF chr( 10 )   
#define TAB chr( 09 )
#define ULINE chr( 205 )   // '-'
#define NULL_DATE ctod( '  /  /  ' )
#define TRUE .t.
#define FALSE .f.
#define YES .t.
#define NO .f.
#define SHARED .f.
#define EXCLUSIVE .t.
#define SOFTSEEK .t.
#define NOEOF .f.
#define NEW .t.
#define OLD .f.
#define NOALIAS nil
#define UNLOCK .t.    // placeholder for Del_rec unlock function
#define NO_EJECT .t.  // placeholder for EndPrint Function
#define NOINTERUPT .t.
#define UNIQUE .t.
#define ALLOW_WILD .t.
#define GO_TO_EDIT .t.
#define WAIT_FOREVER 0   // Used in Inkey - seems more elegant then inkey( 0 )
#define SEC_CHAR chr(254)
#define MODAL .t.
#define DEPNOLEN  6

#define TOTAL_PICT "9999999.99"
#define CURRENCY_PICT "999999.99"
#define CON_NO_PICT "999999"

#define FORM_A4         9
#define FORM_LETTER     1

#define PS_SOLID        0

#define RGB( nR,nG,nB )   ( nR + ( nG * 256 ) + ( nB * 256 * 256 ) )

// Printing Bits
#define BIGCHARS chr(27) + chr(33) + chr(48)
#define VERYBIGCHARS chr(27) + chr(33) + chr(49)
#define NOBIGCHARS chr(27) + chr(33) + chr(0)

#define PAPERCUT chr(29) + "V" + chr(66) + chr(0)                            // Used in S_CASH

#define ITALICS chr(27)+chr(37)+'G'
#define NOITALICS chr(27)+chr(37)+'H'

#define BOLD chr(27)+'E'
#define NOBOLD chr(27)+'F'

#define FW_NORMAL  400                // Font Weight
#define FW_BOLD    700

#define DRAWLINE  chr(08)                   // Irrevant for ESC/POS but useful for Win32Prn
#define PRN_GREEN 'GREEN'
#define PRN_BLACK 'BLACK'

#define P_BIGFONTSIZE           24
#define P_VERYBIGFONTSIZE       36
#define P_BIGFONTWIDTH          100    // Pixels?

#define P_BLACK          RGB( 0x0 ,0x0 ,0x0  )
#define P_BLUE           RGB( 0x0 ,0x0 ,0x85 )
#define P_GREEN          RGB( 0x0 ,0x85,0x0  )
#define P_CYAN           RGB( 0x0 ,0x85,0x85 )
#define P_RED            RGB( 0x85,0x0 ,0x0  )
#define P_MAGENTA        RGB( 0x85,0x0 ,0x85 )
#define P_BROWN          RGB( 0x85,0x85,0x0  )
#define P_WHITE          RGB( 0xC6,0xC6,0xC6 )

#define NEWLINE        .t.
#define NONEWLINE      .f.

#define RPT_SPACE   { 'space(10)', ' ', 1, 0, FALSE}

#define VBTRUE          -1
#define VBFALSE          0
#define VBUSEDEFAULT    -2

#define C_NORMAL        1
#define C_INVERSE       2
#define C_BRIGHT        3
#define C_MAUVE         4
#define C_GREY          5
#define C_YELLOW        6
#define C_GREEN         7
#define C_CYAN          8
#define C_BLUE          9
#define C_RED           10

#define BY_CONNO        1
#define BY_DEPOSIT      2
#define BY_NATURAL      0


// Global Colour defines for Tbrowse objs
#define TB_COLOR  'W/BG, N/W, W/R, +GR/R, N/BG, +W/BG, W/RB, +GR/RB,' + ;
                  'R/B, +W/B, W/G, +GR/G, R/W, B/W, W/GR, +GR/GR'

#define HEADSEP 'Í'
#define COLSEP '³'

#xcommand DEFAULT <v1> TO <x1> [, <vn> TO <xn> ]                 ;
   =>                                                            ;
   IF <v1> == NIL ; <v1> := <x1> ; END                           ;
   [; IF <vn> == NIL ; <vn> := <xn> ; END ]
  
#define SITELEN 2                // Length of Site Code
#define OWNER_CODE_LEN 3         // Length of Owner Code

#define ITEM_ONHAND "O"
#define ITEM_HIRED  "H"

#ifdef ARGYLE
 #define PREPRINTED
 #define LICENSEE "Argyle Rentals"
 #define NOAUDIT

#endif

#ifdef BYRNES
 #define LICENSEE "Rent Buy Appliances"
 #define BYRNES_PWD "Letmein123"
 #define VALIDATE_PRODCODE

#endif

#ifdef DIRECT
 #define LICENSEE "Direct Appliance Rentals"
// #define BYRNES_PWD "Letmein123"
 #define VALIDATE_PRODCODE

#endif

#ifdef COLOURBOND
 #define LICENSEE "Colourbond TV"
 #define SUPPORT_NUMBER "02 9389 8533"

#endif

#ifdef COMBINED
 #define LICENSEE "Combined Television" 
 #define SUPPORT_NUMBER "02 9389 8533"

#endif

#ifdef DEBUG
 #define LICENSEE "Debug"
 #define INSURANCE
 #define STOCKTAKE

#endif

#ifdef EVALUATION
 #define LICENSEE "Evaluation - Expires 01/04/2011"

#endif

#ifdef DISCOUNT
 #define LICENSEE "Discount Rentals"
 #define SUPPORT_NUMBER "02 9975 5911"

#endif

#ifdef HAWKS
 #define LICENSEE "Hawkesbury Washing Machine Rental"

#endif
 
#ifdef HT
 #define LICENSEE "H.T. Appliance Rentals"
 #define SUPPORT_NUMBER "02 890 2399"

#endif

#ifdef MEDI
 #define LICENSEE "Medi Rent"
 #define SUPPORT_NUMBER "02 9700-1744"
 #define CREDIT_CARD
 #define PULSAR
 #define FPT

#endif

#ifdef RENTACENTRE
 #define LICENSEE "Renta Centre"
 #define INSURANCE
 #define SUPPORT_NUMBER "02 9369-2311"
 #define SECURITY
 #define MULTI_SITE
 #define CREDIT_CARD
 #define DBFV2
#endif

#ifdef RENTALSTOGO
 #define LICENSEE "Rentals to Go"
 #define INSURANCE
 #define SUPPORT_NUMBER "07 3856-4666"
 #define RENTACENTRE
#endif

#ifdef STRATHDEE
 #define LICENSEE "Strathdees Appliance Rentals"

#endif

#ifdef VALTEL
 #define LICENSEE "Valtel Retravision"
 #define SUPPORT_NUMBER "02 9873-3377"
 #define CREDIT_CARD

#endif

#ifdef WINRENT
 #define LICENSEE "Winrent Development"
 #define INSURANCE
 #define SUPPORT_NUMBER "02 369-2311"

#endif

#ifndef LICENSEE
 #define LICENSEE "Bluegum Software"

#endif
 
#define SYSPATH      1
#define ENQ_STATUS   2
#define IS_SPOOLING  3
#define SYSDATE      4
#define TRAN_AUDIT   5
#define BDATE        6 
#define HEAD_STR     7 
#define LINE_CNT     8 
#define PAGE_NO      9 
#define BATCH_TOT    10
#define CONTRACT     11
#define OPERCODE     12
#define OPERNAME     13
#define TEMPFILE     14   // Creates a unique tempfile name for each session
#define LASTITEM     15   // Last Item code used
#define LASTCONT     16   // Last Contract Number
#define AUDITPTR     17

#define B_ADDRESS1     1
#define B_ADDRESS2     2
#define B_SUBURB       3
#define B_PCODE        4
#define B_PHONE        5
#define B_ARR_RUN      6
#define B_DEF_OWNER    7
#define B_GRACE        8
#define B_ITEM_NO      9 
#define B_PAGE_LEN     10
#define B_PRINT        11
#define B_EOM          12
#define B_SYSDATE      13    // This is the Last_eod
#define B_EOY          14
#define B_LATE_AMT     15
#define B_LATE_FEE     16
#define B_SEQ          17
#define B_DATE         18   // This is the last day that rentals was run
#define B_CRAA_NO      19
#define B_BAUDRATE     20
#define B_COM_PORT     21
#define B_GSTRATE      22
#define B_LATE_GST     23
#define B_LATE_AMT1    24
#define B_LATE_FEE1    25   // Late fee on Letter 1
#define B_PRINTER1     26
#define B_PRINTER2     27
#define B_EDITOR       28   // Name of Editor to use for Print to screen
#define B_COMPANY      29   // Company Name

#define L_NODE           1
#define L_REGISTER       2
#define L_PRINTER        3
#define L_REPORT_NAME    4
#define L_BARCODE_NAME   5
#define L_LETTER_NAME    6
#define L_DOCKET_NAME    7
#define L_F1             8
#define L_F1N            9
#define L_F1MARGIN      10
#define L_F2            11
#define L_F2N           12
#define L_F2MARGIN      13
#define L_F3            14
#define L_F3N           15
#define L_F3MARGIN      16
#define L_F4            17
#define L_F4N           18
#define L_F4MARGIN      19
#define L_F5            20
#define L_F5N           21
#define L_F5MARGIN      22
#define L_F6            23
#define L_F6N           24
#define L_F6MARGIN      25
#define L_F7            26
#define L_F7N           27
#define L_F7MARGIN      28
#define L_F8            29
#define L_F8N           30
#define L_F8MARGIN      31
#define L_F9            32
#define L_F9N           33
#define L_F9MARGIN      34
#define L_F10           35
#define L_F10N          36
#define L_F10MARGIN     37
#define L_DATE          38
#define L_CUST_NO       39
#define L_CDTYPE        40
#define L_AUTO_OPEN     41
#define L_CDPORT        42
#define L_DOCKET        43
#define L_COLATTR       44
#define L_BACKGR        45
#define L_SHADOW        46
#define L_GOOD          47
#define L_BAD           48
#define L_MEMORY        49
#define L_CUTTER        50
#define L_SPEED         51
#define L_SPACE         52
#define L_RES           53
#define L_MAXROWS       54
#define L_C1            55
#define L_C2            56
#define L_C3            57
#define L_C4            58
#define L_C5            59
#define L_C6            60
#define L_C7            61
#define L_C8            62
#define L_C9            63
#define L_COLOR         64
#define L_POZ           65
#define L_ONP           66

#define BOND_REFUND      'R'
#define BOND_PAYMENT     'B'
#define RENTAL_PAYMENT   'P'
#define MISC_DEBIT       'D'
#define MISC_CREDIT      'C'
#define ARREARS_PAYMENT  'A'
#define ARREARS_DEBIT    'E'
#define MISC_PAYMENT     'N'
#define RENTAL_INSTALL   'Z'
#define LATE_PAYMENT_FEE 'L'
#define ITEM_ADDED       'I'
#define CONTRACT_DELETED 'X'
#define CONTRACT_ADDED   'Y'
#define DELIVERY_FEE     'V'
#define MACHINE_DELETED  'M'
#define MACHINE_MOVEMENT 'T'
#define ITEM_FILE_CHANGED 'Q'

#define X_SUPERVISOR   1
#define X_ENQUIRE      2
#define X_FILE         3
#define X_TRANSACTION  4
#define X_REPORT       5
#define X_EOD          6
#define X_UTILITY      7
#define X_ADDFILES     8
#define X_EDITFILES    9
#define X_DELFILES     10

#define MB_OK                       0
#define MB_OKCANCEL                 1
#define MB_ABORTRETRYIGNORE         2
#define MB_YESNOCANCEL              3
#define MB_YESNO                    4
#define MB_RETRYCANCEL              5

#define MB_RET_OK                   1
#define MB_RET_YES                  6
#define MB_RET_NO                   7

