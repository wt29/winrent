/*

  Outputs barcodes as required



	Last change:  TG    5 Jun 2010    1:23 pm
*/

procedure code_print ( cCodetoPrint, nLabelQty )

local miprint := ''
local p_code := trim(cCodetoPrint)
local x

do case
case len(p_code) < 9
 miprint = code39(p_code)

case ! isalpha(cCodetoPrint)
 miprint = CodeEAN(p_code)

endcase

set console off
set print on

while nLabelQty > 0
  ?? chr(27) + '3' + chr(20)
  for x = 1 to 3
   ? miprint
  next x
 nLabelQty--
enddo

set print off

return

*

function CodeEAN ( cEANCode )
local mibars,clg,x,mipos1, ccb, b_bcptr, mipos, miprint

mibars := clg
for x := 2 to 7
 mipos1 := substr(cEANCode,x,1)
 if mipos1 $ '0123456789'
  if x := 2 .or. x = 5 .or. x = 7
   mipos := 'cl_a'+substr(cEANCode,x,1)
  else
   mipos := 'cl_b'+substr(cEANCode,x,1)
  endif
 endif
 mibars = mibars + &mipos
next x
mibars = mibars + ccb
for x = 8 to 13
 mipos = 'cr_'+substr(cEANCode,x,1)
 if substr(cEANCode,x,1) $ '0123456789'
  mibars = mibars + &mipos
 endif
next x
mibars = mibars + clg
if b_bcptr = '2'
 miprint = chr(27) + 'l' + chr(190) + chr(0)
 for x = 1 to 95
  if substr(mibars,x,1) = '1'
   miprint = miprint+chr(255)+chr(255)
  else
   miprint = miprint+chr(0)+chr(0)
  endif
 next x
else
 miprint = chr(27) + '*' + chr(33) + chr(190) + chr(0)
 for x = 1 to 95
  if substr(mibars,x,1) = '1'
   miprint = miprint+chr(255)+chr(255)+chr(255)+chr(255)+chr(255)+chr(255)
  else
   miprint = miprint+chr(0)+chr(0)+chr(0)+chr(0)+chr(0)+chr(0)
  endif
 next x
endif
return miprint
*

function code39 ( p_33code)
local x, mival, cbstart,mibars, cbspace, cbminus
local outstr, strlen, miLong, miShort
local cbslash, cbplus, cbPercent, miPrint, b_bcptr
local cBDot, cBDollar

private mimac

mibars = cbstart + '2'
for x = 1 to len(p_33code)
 mival = asc(substr(p_33code,x,1))
 mimac = substr(p_33code,x,1)
 do case
 case (mival >= 48 .and. mival <= 57) .or. (mival >= 65 .and. mival <= 90)
  mibars = mibars + cb&mimac
 case mival = 32
  mibars = mibars + cbspace
 case mival = 36
  mibars = mibars + cbdollar
 case mival = 45
  mibars = mibars + cbminus
 case mival = 46
  mibars = mibars + cbdot
 case mival = 47
  mibars = mibars + cbslash
 case mival = 43
  mibars = mibars + cbplus
 case mival = 37
  mibars = mibars + cbpercent
 endcase
 mibars = mibars + '2'
next
mibars = mibars + cbstart
strlen = 0
outstr = ''
if b_bcptr = '2'
 mishort = 1
 milong = 3
else
 mishort = 1
 milong = 3
endif
for x = 1 to len(mibars)
 do case
 case substr(mibars,x,1) = '0'
  outstr = outstr + replicate(chr(255),mishort)
  strlen = strlen + mishort
 case substr(mibars,x,1) = '1'
  outstr = outstr + replicate(chr(255),milong)
  strlen = strlen + milong
 case substr(mibars,x,1) = '2'
  outstr = outstr + replicate(chr(0),mishort)
  strlen = strlen + mishort
 case substr(mibars,x,1) = '3'
  outstr = outstr + replicate(chr(0),milong)
  strlen = strlen + milong
 endcase
next x
if b_bcptr = '9'
 miprint = chr(27) + '*' + chr(6) + chr(int(strlen % 256)) + ;
           chr(int(strlen/256)) + outstr
else
 miprint = chr(27)+'l'+chr(int(strlen % 256))+chr(int(strlen/256))+outstr
endif
return miprint