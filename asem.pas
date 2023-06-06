{ Casio HD61700 assembler }

unit Asem;


interface

  uses
    SysUtils;

  var
{ assembler input }
    loc: word;
    wmd: integer; { 0 if 8-bit memory access, 1 if 16-bit memory access }
    InBuf: string[64];
{ assembler output }
    InIndex: integer;
    OutBuf: array[0..3] of byte;
    OutIndex: integer;

  procedure Assemble;


implementation


type

  t_kind = (
    INHERENT,
    RTN_ARG,
    JR_ARG,
    CAL_ARG,
    JP_ARG,
    REGISTER,
    REGJR,
    REGIM8,
    IM8,
    REGJRIM8,
    REGM,
    AN_ARG,
    AD_ARG,
    ANW_ARG,
    ADW_ARG,
    ANM_ARG,
    ADBM_ARG,
    GRE_ARG,
    PRE_ARG,
    GSR_ARG,
    PSR_ARG,
    PSRM_ARG,
    GST_ARG,
    PST_ARG,
    MOVEB,
    MOVEW,
    MOVEM,
    LDM_ARG,
    LD_ARG,
    LDW_ARG,
    ST_ARG,
    STW_ARG,
    DB_ARG
  );


  tab = record
    str: string[5];
    val2: word;
    case boolean of
      True: (kind: t_kind);
      False: (val1: word);
  end;


const

  PLUS = $0000;
  MINUS = $0080;
  ANYTHING = 0;		{ unused value }

  NMNEM = 137;		{ index of the last item in the 'mnem' array }

{ first opcode in the upper byte of the word 'val2',
  second opcode in bits 6,5 of the lower byte of the word 'val2' }
  mnem: array [0..NMNEM] of tab = (
{ no operands }
    (	str:'bup';	val2:$D800;	kind:INHERENT	),
    (	str:'bdn';	val2:$D900;	kind:INHERENT	),
    (	str:'nop';	val2:$F800;	kind:INHERENT	),
    (	str:'clt';	val2:$F900;	kind:INHERENT	),
    (	str:'fst';	val2:$FA00;	kind:INHERENT	),
    (	str:'slw';	val2:$FB00;	kind:INHERENT	),
    (	str:'cani';	val2:$FC00;	kind:INHERENT	),
    (	str:'rtni';	val2:$FD00;	kind:INHERENT	),
    (	str:'off';	val2:$FE00;	kind:INHERENT	),
    (	str:'trp';	val2:$FF00;	kind:INHERENT	),

{ conditional code }
    (	str:'rtn';	val2:$F000;	kind:RTN_ARG	),

{ conditional relative }
    (	str:'jr';	val2:$B000;	kind:JR_ARG	),

{ conditional absolute }
    (	str:'cal';	val2:$7000;	kind:CAL_ARG	),

{ conditional absolute |
  unconditional with a directly specified register |
  unconditional indirect with a directly specified register }
    (	str:'jp';	val2:$3000;	kind:JP_ARG	),

{ single directly specified register }
    (	str:'phs';	val2:$2600;	kind:REGISTER	),
    (	str:'phu';	val2:$2700;	kind:REGISTER	),
    (	str:'pps';	val2:$2E00;	kind:REGISTER	),
    (	str:'ppu';	val2:$2F00;	kind:REGISTER	),
    (	str:'phsw';	val2:$A600;	kind:REGISTER	),
    (	str:'phuw';	val2:$A700;	kind:REGISTER	),
    (	str:'ppsw';	val2:$AE00;	kind:REGISTER	),
    (	str:'ppuw';	val2:$AF00;	kind:REGISTER	),

{ single directly specified register with an optional relative jump }
    (	str:'ldl';	val2:$1300;	kind:REGJR	),
    (	str:'rod';	val2:$1800;	kind:REGJR	),
    (	str:'rou';	val2:$1820;	kind:REGJR	),
    (	str:'bid';	val2:$1840;	kind:REGJR	),
    (	str:'biu';	val2:$1860;	kind:REGJR	),
    (	str:'did';	val2:$1A00;	kind:REGJR	),
    (	str:'diu';	val2:$1A20;	kind:REGJR	),
    (	str:'byd';	val2:$1A40;	kind:REGJR	),
    (	str:'byu';	val2:$1A60;	kind:REGJR	),
    (	str:'cmp';	val2:$1B00;	kind:REGJR	),
    (	str:'inv';	val2:$1B40;	kind:REGJR	),
    (	str:'gpo';	val2:$1C00;	kind:REGJR	),
    (	str:'gfl';	val2:$1C40;	kind:REGJR	),
    (	str:'stlw';	val2:$9200;	kind:REGJR	),
    (	str:'ldlw';	val2:$9300;	kind:REGJR	),
    (	str:'ppow';	val2:$9400;	kind:REGJR	),
    (	str:'rodw';	val2:$9800;	kind:REGJR	),
    (	str:'rouw';	val2:$9820;	kind:REGJR	),
    (	str:'bidw';	val2:$9840;	kind:REGJR	),
    (	str:'biuw';	val2:$9860;	kind:REGJR	),
    (	str:'didw';	val2:$9A00;	kind:REGJR	),
    (	str:'diuw';	val2:$9A20;	kind:REGJR	),
    (	str:'bydw';	val2:$9A40;	kind:REGJR	),
    (	str:'byuw';	val2:$9A60;	kind:REGJR	),
    (	str:'cmpw';	val2:$9B00;	kind:REGJR	),
    (	str:'invw';	val2:$9B40;	kind:REGJR	),
    (	str:'gpow';	val2:$9C00;	kind:REGJR	),
    (	str:'gflw';	val2:$9C40;	kind:REGJR	),

{ single directly specified register | immediate byte }
    (	str:'sup';	val2:$DC00;	kind:REGIM8	),
    (	str:'sdn';	val2:$DD00;	kind:REGIM8	),
{ only immediate byte }
    (	str:'bups';	val2:$D800;	kind:IM8	),
    (	str:'bdns';	val2:$D900;	kind:IM8	),

{ single directly specified register with an optional relative jump |
  immediate byte }
    (	str:'stl';	val2:$1200;	kind:REGJRIM8	),
    (	str:'ppo';	val2:$1400;	kind:REGJRIM8	),
    (	str:'pfl';	val2:$1440;	kind:REGJRIM8	),

{ single directly specified register, multibyte }
    (	str:'stlm';	val2:$D200;	kind:REGM	),
    (	str:'ldlm';	val2:$D300;	kind:REGM	),
    (	str:'ppom';	val2:$D400;	kind:REGM	),
    (	str:'didm';	val2:$DA00;	kind:REGM	),
    (	str:'dium';	val2:$DA20;	kind:REGM	),
    (	str:'bydm';	val2:$DA40;	kind:REGM	),
    (	str:'byum';	val2:$DA60;	kind:REGM	),
    (	str:'cmpm';	val2:$DB00;	kind:REGM	),
    (	str:'invm';	val2:$DB40;	kind:REGM	),
    (	str:'phsm';	val2:$E600;	kind:REGM	),
    (	str:'phum';	val2:$E700;	kind:REGM	),
    (	str:'ppsm';	val2:$EE00;	kind:REGM	),
    (	str:'ppum';	val2:$EF00;	kind:REGM	),

{ first operand: directly specified register
  second operand: directly or indirectly specified register |
                  immediate byte
  optional third operand: relative jump }
    (	str:'anc';	val2:$0400;	kind:AN_ARG	),
    (	str:'nac';	val2:$0500;	kind:AN_ARG	),
    (	str:'orc';	val2:$0600;	kind:AN_ARG	),
    (	str:'xrc';	val2:$0700;	kind:AN_ARG	),
    (	str:'adb';	val2:$0A00;	kind:AN_ARG	),
    (	str:'sbb';	val2:$0B00;	kind:AN_ARG	),
    (	str:'an';	val2:$0C00;	kind:AN_ARG	),
    (	str:'na';	val2:$0D00;	kind:AN_ARG	),
    (	str:'or';	val2:$0E00;	kind:AN_ARG	),
    (	str:'xr';	val2:$0F00;	kind:AN_ARG	),
{ additional address mode
  first operand: indexed, offset = directly or indirectly specified register
  second operand: directly specified register }
    (	str:'adc';	val2:$0000;	kind:AD_ARG	),
    (	str:'sbc';	val2:$0100;	kind:AD_ARG	),
    (	str:'ad';	val2:$0800;	kind:AD_ARG	),
    (	str:'sb';	val2:$0900;	kind:AD_ARG	),

{ first operand: directly specified register
  second operand: directly or indirectly specified register
  optional third operand: relative jump }
    (	str:'ancw';	val2:$8400;	kind:ANW_ARG	),
    (	str:'nacw';	val2:$8500;	kind:ANW_ARG	),
    (	str:'orcw';	val2:$8600;	kind:ANW_ARG	),
    (	str:'xrcw';	val2:$8700;	kind:ANW_ARG	),
    (	str:'adbw';	val2:$8A00;	kind:ANW_ARG	),
    (	str:'sbbw';	val2:$8B00;	kind:ANW_ARG	),
    (	str:'anw';	val2:$8C00;	kind:ANW_ARG	),
    (	str:'naw';	val2:$8D00;	kind:ANW_ARG	),
    (	str:'orw';	val2:$8E00;	kind:ANW_ARG	),
    (	str:'xrw';	val2:$8F00;	kind:ANW_ARG	),
{ additional address mode
  first operand: indexed, offset = directly or indirectly specified register
  second operand: directly specified register }
    (	str:'adcw';	val2:$8000;	kind:ADW_ARG	),
    (	str:'sbcw';	val2:$8100;	kind:ADW_ARG	),
    (	str:'adw';	val2:$8800;	kind:ADW_ARG	),
    (	str:'sbw';	val2:$8900;	kind:ADW_ARG	),

{ first operand: directly specified register
  second operand: directly or indirectly specified register
  third operand: number of registers
  optional fourth operand: relative jump }
    (	str:'adbcm';	val2:$C000;	kind:ANM_ARG	),
    (	str:'sbbcm';	val2:$C100;	kind:ANM_ARG	),
    (	str:'ancm';	val2:$C400;	kind:ANM_ARG	),
    (	str:'nacm';	val2:$C500;	kind:ANM_ARG	),
    (	str:'orcm';	val2:$C600;	kind:ANM_ARG	),
    (	str:'xrcm';	val2:$C700;	kind:ANM_ARG	),
    (	str:'anm';	val2:$CC00;	kind:ANM_ARG	),
    (	str:'nam';	val2:$CD00;	kind:ANM_ARG	),
    (	str:'orm';	val2:$CE00;	kind:ANM_ARG	),
    (	str:'xrm';	val2:$CF00;	kind:ANM_ARG	),
{ additional address mode
  second operand: 5-bit immediate data }
    (	str:'adbm';	val2:$C800;	kind:ADBM_ARG	),
    (	str:'sbbm';	val2:$C900;	kind:ADBM_ARG	),

{ first operand: word size register
  second operand: single directly specified register
  third operand: optional relative jump }
    (	str:'gre';	val2:$9E00;	kind:GRE_ARG	),
{ additional address mode
  second operand: immediate word without an optional relative jump }
    (	str:'pre';	val2:$9600;	kind:PRE_ARG	),

{ first operand: specific index register
  second operand: directly specified register
  optional third operand: relative jump }
    (	str:'gsr';	val2:$1D00;	kind:GSR_ARG	),
    (	str:'gsrw';	val2:$9D00;	kind:GSR_ARG	),
    (	str:'psrw';	val2:$9500;	kind:GSR_ARG	),
{ additional address mode
  second operand: immediate byte without an optional relative jump }
    (	str:'psr';	val2:$1500;	kind:PSR_ARG	),

{ first operand: specific index register
  second operand: directly specified register
  third operand: number of registers }
    (	str:'psrm';	val2:$D500;	kind:PSRM_ARG	),

{ first operand: status register
  second operand: directly specified register
  optional third operand: relative jump }
    (	str:'gst';	val2:$1E00;	kind:GST_ARG	),
{ additional address mode
  second operand: immediate byte without an optional relative jump }
    (	str:'pst';	val2:$1600;	kind:PST_ARG	),

{ first operand: directly specified register
  second operand: indexed, offset = directly or indirectly specified register }
    (	str:'stiw';	val2:$A200;	kind:MOVEW	),
    (	str:'stdw';	val2:$A400;	kind:MOVEW	),
    (	str:'ldiw';	val2:$AA00;	kind:MOVEW	),
    (	str:'lddw';	val2:$AC00;	kind:MOVEW	),
{ additional address mode: offset = immediate byte }
    (	str:'sti';	val2:$2200;	kind:MOVEB	),
    (	str:'std';	val2:$2400;	kind:MOVEB	),
    (	str:'ldi';	val2:$2A00;	kind:MOVEB	),
    (	str:'ldd';	val2:$2C00;	kind:MOVEB	),

{ first operand: directly specified register
  second operand: indexed, offset = directly or indirectly specified register
  third operand: number of registers }
    (	str:'stm';	val2:$E000;	kind:MOVEM	),
    (	str:'stim';	val2:$E200;	kind:MOVEM	),
    (	str:'stdm';	val2:$E400;	kind:MOVEM	),
    (	str:'ldim';	val2:$EA00;	kind:MOVEM	),
    (	str:'lddm';	val2:$EC00;	kind:MOVEM	),
{ additional address mode
  second operand: directly or indirectly specified register
  third operand: number of registers
  optional fourth operand: relative jump }
    (	str:'ldm';	val2:$E800;	kind:LDM_ARG	),

{ first operand: directly specified register
  second operand: various }
    (	str:'ld';	val2:$2800;	kind:LD_ARG	),
    (	str:'ldw';	val2:$A800;	kind:LDW_ARG	),

{ various operands }
    (	str:'st';	val2:$2000;	kind:ST_ARG	),
    (	str:'stw';	val2:$A000;	kind:STW_ARG	),

{ pseudo instruction }
    (	str:'db';	val2:ANYTHING;	kind:DB_ARG	)
  );


  NCC = 6;	{ index of the last item in the 'cctab' array }

{ table of conditional codes }
  cctab: array[0..NCC] of tab = (
    (	str:'z';	val2:$0000;	val1:ANYTHING	),
    (	str:'nc';	val2:$0100;	val1:ANYTHING	),
    (	str:'lz';	val2:$0200;	val1:ANYTHING	),
    (	str:'uz';	val2:$0300;	val1:ANYTHING	),
    (	str:'nz';	val2:$0400;	val1:ANYTHING	),
    (	str:'c';	val2:$0500;	val1:ANYTHING	),
    (	str:'nlz';	val2:$0600;	val1:ANYTHING	)
  );


  NSREGS = 6;	{ index of the last item in the 'sregs' array }

{ table of status registers }
  sregs: array[0..NSREGS] of tab = (
  { readable/writable registers }
    (	str:'pe';	val2:$0000;	val1:ANYTHING	),
    (	str:'pd';	val2:$0020;	val1:ANYTHING	),
    (	str:'ib';	val2:$0040;	val1:ANYTHING	),
    (	str:'ua';	val2:$0060;	val1:ANYTHING	),
    (	str:'ia';	val2:$0100;	val1:ANYTHING	),
    (	str:'ie';	val2:$0120;	val1:ANYTHING	),
  { read only register }
    (	str:'tm';	val2:$0160;	val1:ANYTHING	)
  );


  NWREGS = 5;	{ index of the last item in the 'wregs' array }
  NIREGS = 1;	{ index of the last index register in the 'wregs' array }

{ table of word size registers, the first two are the index registers }
  wregs: array[0..NWREGS] of tab = (
  { readable/writable registers }
    (	str:'ix';	val2:$0000;	val1:ANYTHING	),
    (	str:'iz';	val2:$0040;	val1:ANYTHING	),
    (	str:'iy';	val2:$0020;	val1:ANYTHING	),
    (	str:'us';	val2:$0060;	val1:ANYTHING	),
    (	str:'ss';	val2:$0100;	val1:ANYTHING	),
  { read only register }
    (	str:'ky';	val2:$0160;	val1:ANYTHING	)
  );


  NSIR = 2;	{ index of the last item in the 'sirtab' array }

{ table of specific index registers }
  sirtab: array[0..NSIR] of tab = (
    (	str:'sx';	val2:$0000;	val1:ANYTHING	),
    (	str:'sy';	val2:$2000;	val1:ANYTHING	),
    (	str:'sz';	val2:$4000;	val1:ANYTHING	)
  );



{ compare the string 's' with the 'InBuf' at location 'InIndex' without
  the case sensitivity,
  update the 'InIndex' and return True if both string match }
function ParseString (s: string): boolean;
var
  n: integer;
begin
  ParseString := False;
  if InIndex + Length(s) - 1 > Length(InBuf) then exit;
  n := 0;
  while n < Length(s) do
  begin
    if s[n+1] <> LowerCase(InBuf[InIndex + n]) then exit;
    Inc (n);
  end {while};
  Inc (InIndex, n);
  ParseString := True;
end {ParseString};


{ This function searches the table for a string pointed to by the InIndex,
  and picks from the table the longest matching string.
  Returns index to the table and updates InIndex when string found,
  or leaves InIndex unchanged when not found. }
function ParseTable (
  out x: integer;	{ returned index to the table }
  var t: array of tab;	{ table to be searched }
  last: integer		{ index of the last item }
  ) : boolean;		{ TRUE when string found }
var
  maxindex, save, i: integer;
begin
  maxindex := InIndex;
  save := InIndex;
  ParseTable := FALSE;
  for i := 0 to last do
  begin
    InIndex := save;
    if ParseString (t[i].str) and (InIndex > maxindex) then
    begin
      ParseTable := TRUE;
      x := i;
      maxindex := InIndex;
    end {if};
  end {for};
  InIndex := maxindex;
end {ParseTable};


{ a specified character expected }
function ParseChar (c: char) : boolean;
begin
  result := (InIndex <= Length(InBuf)) and (InBuf[InIndex] = c);
  if result then Inc (InIndex);
end {ParseChar};


{ move the 'InIndex' to the first character different from space }
procedure SkipBlanks;
begin
  while ParseChar (' ') do ;
end {SkipBlanks};


{ comma expected }
function ParseComma : boolean;
begin
  SkipBlanks;
  ParseComma := ParseChar (',');
  SkipBlanks;
end {ParseComma};


{ optional jump/call/return condition }
function ParseCond (out x: word) : boolean;
var
  i: integer;
begin
  SkipBlanks;
  if ParseTable (i, cctab, NCC) then
  begin
    x := cctab[i].val2;
    ParseCond := TRUE;
  end
  else
  begin
    x := $0700;
    ParseCond := FALSE;
  end {if};
end {OptCond};


{ value of a hex digit }
function GetDigit (c: char) : integer;
const
  digits: string[22] = '0123456789ABCDEFabcdef';
var
  i: integer;
begin
  i := 1;
  while (i<=22) and (c <> digits[i]) do Inc (i);
  if i>16 then GetDigit := i-7 else GetDigit := i-1;
end {GetDigit};


{ the function expects a number in base 'radix',
  updates the InIndex }
function ParseNumber (out value: word; radix: word): boolean;
var
  x, y: word;
begin
  value := 0;
  ParseNumber := FALSE;
  while InIndex <= Length(InBuf) do
  begin
    x := word(GetDigit(InBuf[InIndex]));
    if x >= radix then break;	{ stop when not a digit }
    y := value*radix + x;
    if y < value then break;	{ overflow, stop when too much digits }
    value := y;
    Inc (InIndex);
    ParseNumber := TRUE;
  end;
end {ParseNumber};


{ the function expects a hexadecimal (with a prefix &H) or decimal number
  within specified range }
function EvalAndTest (out value: word; range: word) : boolean;
var
  radix: word;
begin
  EvalAndTest := FALSE;
  SkipBlanks;
{ parse for the prefix of a hexadecimal numeral }
  if ParseString ('&h') then radix := 16 else radix := 10;
  if not ParseNumber (value, radix) then exit;	{ failure, missing number }
  EvalAndTest := (value <= range);		{ FALSE when out of range }
end {EvalAndTest};


{ the function expects a main register,
  returns the register index,
  direct index in range $6000..$601F }
function RegArgum (out x: word) : boolean;
var
  i: integer;
begin
  RegArgum := FALSE;
  SkipBlanks;
  if not ParseChar ('$') then exit;	{ failure, invalid register }
  if ParseTable (i, sirtab, NSIR) then
  begin
    RegArgum := TRUE;
    x := sirtab[i].val2;
  end
  else
  begin
    RegArgum := ParseNumber (x, 10) and (x <= 31);
    Inc (x,$6000);
  end {if};
end {RegArgum};


{ expects a sign '+' or '-' }
function ParseSign (out x: word) : boolean;
begin
  SkipBlanks;
  x := PLUS;
  ParseSign := TRUE;
  if not ParseChar ('+') then
  begin
    x := MINUS;
    ParseSign := ParseChar ('-');
  end {if};
end {ParseSign};


{ expects the number of bytes for multibyte instructions }
function NumOfBytes (out x: word) : boolean;
begin
  NumOfBytes := FALSE;
  if not ParseComma then exit;			{ failure, comma expected }
  if InIndex > Length(InBuf) then exit;		{ failure, digit expected }
  x := word(GetDigit(InBuf[InIndex]));
  if (x < 2) or (x > 8) then exit;		{ failure, digit out of range }
  Inc (InIndex);
  x := (x-1) shl 5;
  NumOfBytes := TRUE;
end {NumOfBytes};


{ converts absolute address to relative displacement,
  returns FALSE when out of range }
function AbsToRel (var destination: word; location: word) : boolean;
begin
  Dec (destination,location);
  if destination > $7FFF then destination := $0080 - destination;
  AbsToRel := destination < $0100;
end {AbsToRel};


{ optional relative jump }
procedure OptRelJump;
var
  x: word;
  save: integer;
begin
  SkipBlanks;
  save := InIndex;
  if ParseComma then
  begin
    ParseString ('jr');		{ the 'JR' can be omitted }
    if EvalAndTest (x, $FFFF) and
	AbsToRel (x, loc + (word(OutIndex) shr wmd)) then
{ valid jump present }
    begin
      OutBuf[1] := OutBuf[1] xor $80;
      OutIndex := OutIndex or wmd;
      OutBuf[OutIndex] := byte(x);
      Inc (OutIndex);
      Exit;
    end {if};
  end {if};
{ jump absent or invalid }
  InIndex := save;
end {OptRelJump};


{ assemble the instruction in the InBuf and place the result in the OutBuf,
  on exit InIndex contains the position of an error (warning: it can point
  past the end of the InBuf !), otherwise 0 }
procedure Assemble;
var
  sign: word;
  i, j: integer;	{ index to the tables }
  kod: word;		{ opcode }
  x1, x2, x3: word;
begin
  InIndex := 1;
  OutIndex := 0;
  for i := 0 to 3 do OutBuf[i] := 0;

  SkipBlanks;				{ skip leading blanks }
  if (InIndex > Length(InBuf))		{ empty InBuf? }
	or ParseChar (';') then		{ comment? }
  begin
    InIndex := 0;
    exit;				{ success }
  end {if};

{ parse the mnemonic }
  if not ParseTable (i, mnem, NMNEM) then exit;
					{ failure, mnemonic not recognised }
  kod := mnem[i].val2;

{ parse the arguments }
  case mnem[i].kind of

    INHERENT:	{ no operands }
      begin
        OutIndex := 1;
        OutBuf[0] := Hi(kod);
      end {case INHERENT};


    RTN_ARG:
      begin
        ParseCond (x1);
        OutIndex := 1;
        OutBuf[0] := Hi(kod xor x1);
      end {case RTN_ARG};


    JR_ARG:
      begin
        if ParseCond (x1) and not ParseComma then exit;		{ failure }
        if not EvalAndTest (x2, $FFFF) then exit;		{ failure }
        if not AbsToRel (x2, loc + (1 shr wmd)) then exit;	{ failure }
        OutIndex := 2;
        OutBuf[0] := Hi(kod xor x1);
        OutBuf[1] := byte(x2);
      end {case JR_ARG};


    CAL_ARG,
    JP_ARG:
      begin
        SkipBlanks;
        OutIndex := 2;
        if (mnem[i].kind = JP_ARG) and ParseChar ('(') then
        begin
          if not RegArgum (x2) then exit;	{ failure, register expected }
          if x2 < $6000 then exit;		{ failure, SIR not allowed }
          if not ParseChar (')') then exit;	{ failure, ')' expected }
          x1 := $EF00;
        end
        else if (mnem[i].kind = JP_ARG) and RegArgum (x2) then
        begin
          if x2 < $6000 then exit;		{ failure, SIR not allowed }
          x1 := $EE00;
        end
        else
        begin
          if ParseCond (x1) and not ParseComma then exit;	{ failure }
          if not EvalAndTest (x2, $FFFF) then exit;		{ failure }
          Inc (OutIndex, 1 shl wmd);
        end {if};
        OutBuf[0] := Hi(kod xor x1);
        OutBuf[1] := byte(x2);
        OutBuf[2+wmd] := Hi(x2);
      end {case CAL_ARG, JP_ARG};


    REGISTER,	{ single directly specified register }
    REGJR:	{ ...with an optional relative jump }
      begin
        if not RegArgum (x1) then exit;		{ failure, register expected }
        if x1 < $6000 then exit;		{ failure, SIR not allowed }
        OutIndex := 2;
        OutBuf[0] := Hi(kod);
        OutBuf[1] := byte(kod xor x1);
  { optional relative jump }
        if mnem[i].kind = REGJR then OptRelJump;
      end {case REGISTER, REGJR};


    REGIM8,	{ single directly specified register | immediate byte }
    IM8:	{ only immediate byte }
      begin
  { register }
        if (mnem[i].kind = REGIM8) and RegArgum (x1) then
        begin
          if x1 < $6000 then exit;		{ failure, SIR not allowed }
        end
  { immediate byte }
        else
        begin
          if not EvalAndTest (x1, $FF) then exit;	{ failure }
          kod := kod xor $8000;
        end {if};
        OutIndex := 2;
        OutBuf[0] := Hi(kod);
        OutBuf[1] := byte(x1);
      end {case REGIM8, IM8};


    REGJRIM8:
      begin
  { register }
        if RegArgum (x1) then
        begin
          if x1 < $6000 then exit;		{ failure, SIR not allowed }
          OutIndex := 2;
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod xor x1);
  { optional relative jump }
          OptRelJump;
        end
  { immediate byte }
        else
        begin
          if not EvalAndTest (x1, $FF) then exit;	{ failure }
          kod := kod xor $4000;
          if mnem[i].val2 = $1200 {STL opcode} then
            OutIndex := 2			{ STL }
          else
            OutIndex := 3;			{ PPO, PFL }
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod);
          OutBuf[OutIndex-1] := byte(x1);
        end {if};
      end {case REGJRIM8};


    REGM:	{ single directly specified register, multibyte }
      begin
        if not RegArgum (x1) then exit;		{ failure, register expected }
        if x1 < $6000 then exit;		{ failure, SIR not allowed }
        if not NumOfBytes (x2) then exit; { failure, invalid number of bytes }
        OutIndex := 3;
        OutBuf[0] := Hi(kod);
        OutBuf[1] := byte(kod xor x1);
        OutBuf[2] := byte(x2);
      end {case REGM};


    AN_ARG,
    AD_ARG,
    ANW_ARG,
    ADW_ARG:
      begin
{ first operand: memory pointed to by an index register with an offset }
        SkipBlanks;
        if ParseChar ('(') then
        begin
          if not ParseTable (j, wregs, NIREGS) then exit;
					{ failure, index register expected }
          if not ParseSign (sign) then exit;	{ failure, sign expected }
          if (kod and $0800) <> 0 then Dec (kod, $0600);
          if (kod and $8000) <> 0 then Dec (kod, $4000);
          kod := kod shl 1;
  { register as offset }
          if RegArgum (x2) then
          begin
            if x2 < $6000 then OutIndex := 2 else OutIndex := 3;
            kod := kod xor $3800;
          end
  { immediate offset, supported only by byte size transfers }
          else if (mnem[i].kind = AN_ARG) or (mnem[i].kind = AD_ARG) then
          begin
            if not EvalAndTest (x2, $FF) then exit;
            kod := kod xor $7800;
            OutIndex := 3;
          end {if};
          SkipBlanks;
          if not ParseChar (')') then exit;	{ failure, ')' expected }
          if not ParseComma then exit;		{ failure, comma expected }
{ second operand: directly specified register }
          if not RegArgum (x1) then exit;	{ failure, register expected }
          if x1 < $6000 then exit;		{ failure, SIR not allowed }
          OutBuf[0] := Hi(kod) xor byte(j);
          OutBuf[1] := byte(kod xor x1 xor sign) xor Hi(x2);
          OutBuf[2] := byte(x2);
        end

{ first operand: register }
        else if RegArgum (x1) then
        begin
          if x1 < $6000 then exit;		{ failure, SIR not allowed }
          if not ParseComma then exit;		{ failure, comma expected }
{ second operand: directly or indirectly specified register }
          if RegArgum (x2) then
          begin
            if x2 < $6000 then OutIndex := 2 else OutIndex := 3;
          end
{ second operand: immediate data, supported only by byte size transfers }
          else if (mnem[i].kind = AN_ARG) or (mnem[i].kind = AD_ARG) then
          begin
            if not EvalAndTest (x2, $FF) then exit;
            kod := kod xor $4000;
            OutIndex := 3;
          end {if};
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod xor x1) xor Hi(x2);
          OutBuf[2] := byte(x2);
  { optional relative jump }
          OptRelJump;
        end {if};

      end {case AN_ARG, AD_ARG, ANW_ARG, ADW_ARG};


    ANM_ARG,
    ADBM_ARG:
      begin
{ first operand: register }
        if not RegArgum (x1) then exit;		{ failure, register expected }
        if x1 < $6000 then exit;		{ failure, SIR not allowed }
        if not ParseComma then exit;		{ failure, comma expected }
{ second operand: directly or indirectly specified register }
        if RegArgum (x2) then
        begin
        end
{ second operand: 5-bit immediate data }
        else if mnem[i].kind = ADBM_ARG then
        begin
          if not EvalAndTest (x2, $1F) then exit;
          kod := kod xor $0200;
        end {if};
{ third operand: number of bytes }
        if not NumOfBytes (x3) then exit; { failure, invalid number of bytes }
        OutIndex := 3;
        OutBuf[0] := Hi(kod);
        OutBuf[1] := byte(kod xor x1) xor Hi(x2);
        OutBuf[2] := byte(x2 xor x3);
{ optional relative jump }
        OptRelJump;
      end {case ANM_ARG, ADBM_ARG};


    GRE_ARG,
    PRE_ARG:
      begin
  { first operand: word size register }
        SkipBlanks;
        j := NWREGS;
        if mnem[i].kind = PRE_ARG then Dec (j);	{ drop the read only reg. KY }
        if not ParseTable (j, wregs, j) then exit;	{ failure }
        kod := kod xor wregs[j].val2;
        if not ParseComma then exit;		{ failure, comma expected }
  { second operand: register }
        if RegArgum (x1) then
        begin
          if x1 < $6000 then exit;		{ failure, SIR not allowed }
          OutIndex := 2;
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod xor x1);
  { optional relative jump }
          OptRelJump;
        end
  { second operand: immediate word }
        else if mnem[i].kind = PRE_ARG then
        begin
          if not EvalAndTest (x1, $FFFF) then exit;	{ failure }
          kod := kod xor $4000;
          OutIndex := 4;
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod);
          OutBuf[2] := byte(x1);
          OutBuf[3] := Hi(x1);
        end {if};
      end {case GRE_ARG, PRE_ARG};


    GSR_ARG,
    PSR_ARG:
      begin
  { first operand: specific index register }
        SkipBlanks;
        if not ParseTable (j, sirtab, NSIR) then exit;	{ failure }
        x1 := sirtab[j].val2;
        if not ParseComma then exit;		{ failure, comma expected }
  { second operand: register }
        if RegArgum (x2) then
        begin
          if x2 < $6000 then exit;		{ failure, SIR not allowed }
          OutIndex := 2;
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod xor x2) xor Hi(x1);
  { optional relative jump }
          OptRelJump;
        end
  { second operand: immediate byte }
        else if mnem[i].kind = PSR_ARG then
        begin
          if not EvalAndTest (x2, $1F) then exit;	{ failure }
          kod := kod xor $4000;
          OutIndex := 2;
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod xor x2) xor Hi(x1);
        end {if};
      end {case GSR_ARG, PSR_ARG};


    PSRM_ARG:
      begin
  { first operand: specific index register }
        SkipBlanks;
        if not ParseTable (j, sirtab, NSIR) then exit;	{ failure }
        x1 := sirtab[j].val2;
        if not ParseComma then exit;		{ failure, comma expected }
  { second operand: register }
        if not RegArgum (x2) then exit;		{ failure, register expected }
        if x2 < $6000 then exit;		{ failure, SIR not allowed }
  { third operand: number of bytes }
        if not NumOfBytes (x3) then exit; { failure, invalid number of bytes }
        OutIndex := 3;
        OutBuf[0] := Hi(kod);
        OutBuf[1] := byte(kod xor x2) xor Hi(x1);
        OutBuf[2] := byte(x3);
      end {case PSRM_ARG};


    GST_ARG,
    PST_ARG:
      begin
  { first operand: specific index register }
        SkipBlanks;
        j := NSREGS;
        if mnem[i].kind = PST_ARG then Dec (j);	{ drop the read only reg. TM }
        if not ParseTable (j, sregs, j) then exit;	{ failure }
        kod := kod xor sregs[j].val2;
        if not ParseComma then exit;		{ failure, comma expected }
  { second operand: register }
        if RegArgum (x1) then
        begin
          if x1 < $6000 then exit;		{ failure, SIR not allowed }
          OutIndex := 2;
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod xor x1);
  { optional relative jump }
          OptRelJump;
        end
  { second operand: immediate byte }
        else if mnem[i].kind = PST_ARG then
        begin
          if not EvalAndTest (x1, $FF) then exit;	{ failure }
          kod := kod xor $4000;
          OutIndex := 3;
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod);
          OutBuf[2] := byte(x1);
        end {if};
      end {case GST_ARG, PST_ARG};


    MOVEB,	{ ldi, ldd, sti, std }
    MOVEW:	{ ldiw, lddw, stiw, stdw }
      begin
{ first operand: register }
        if not RegArgum (x1) then exit;		{ failure, register expected }
        if x1 < $6000 then exit;		{ failure, SIR not allowed }
        if not ParseComma then exit;		{ failure, comma expected }
        if not ParseChar ('(') then exit;	{ failure, '(' expected }
        SkipBlanks;

{ second operand: memory pointed to by an index register with an offset }
        if not ParseTable (j, wregs, NIREGS) then exit;
					{ failure, index register expected }
        if not ParseSign (sign) then exit;	{ failure, sign expected }
  { register as offset }
        if RegArgum (x2) then
        begin
          if x2 < $6000 then OutIndex := 2 else OutIndex := 3;
        end
  { immediate offset, supported only by byte size transfers }
        else if mnem[i].kind = MOVEB then
        begin
          if not EvalAndTest (x2, $FF) then exit;
          kod := kod xor $4000;
          OutIndex := 3;
        end {if};
        SkipBlanks;
        if not ParseChar (')') then exit;	{ failure, ')' expected }
        OutBuf[0] := Hi(kod) xor byte(j);
        OutBuf[1] := byte(kod xor x1 xor sign) xor Hi(x2);
        OutBuf[2] := byte(x2);
      end {case MOVEB, MOVEW};


    MOVEM,
    LDM_ARG:
      begin
{ first operand: register }
        if not RegArgum (x1) then exit;		{ failure, register expected }
        if x1 < $6000 then exit;		{ failure, SIR not allowed }
        if not ParseComma then exit;		{ failure, comma expected }

{ second operand: memory pointed to by an index register with an offset }
        if ParseChar ('(') then
        begin
          SkipBlanks;
          if not ParseTable (j, wregs, NIREGS) then exit;
					{ failure, index register expected }
          if not ParseSign (sign) then exit;	{ failure, sign expected }
          if not RegArgum (x2) then exit;		{ failure, register expected }
          SkipBlanks;
          if not ParseChar (')') then exit;	{ failure, ')' expected }
{ third operand: number of bytes }
          if not NumOfBytes (x3) then exit; { failure, invalid number of bytes }
          OutIndex := 3;
          OutBuf[0] := Hi(kod) xor byte(j);
          OutBuf[1] := byte(kod xor x1 xor sign) xor Hi(x2);
          OutBuf[2] := byte(x2 xor x3);
        end

{ second operand: directly or indirectly specified register }
        else if (mnem[i].kind = LDM_ARG) and RegArgum (x2) then
        begin
{ third operand: number of bytes }
          if not NumOfBytes (x3) then exit; { failure, invalid number of bytes }
          kod := kod xor $2A00;
          OutIndex := 3;
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod xor x1) xor Hi(x2);
          OutBuf[2] := byte(x2 xor x3);
{ optional relative jump }
          OptRelJump;
        end {if};

      end {case MOVEM, LDM_ARG};


    LD_ARG,
    LDW_ARG:
      begin
{ first operand: register }
        if not RegArgum (x1) then exit;		{ failure, register expected }
        if x1 < $6000 then exit;		{ failure, SIR not allowed }
        if not ParseComma then exit;		{ failure, comma expected }

{ second operand: memory }
        if ParseChar ('(') then
        begin
          SkipBlanks;

  { memory pointed to by an index register with an offset }
          if ParseTable (j, wregs, NIREGS) then
          begin
            if not ParseSign (sign) then exit;	{ failure, sign expected }
  { register as offset }
            if RegArgum (x2) then
            begin
              if x2 < $6000 then OutIndex := 2 else OutIndex := 3;
            end
  { immediate offset, supported only by byte size transfers }
            else if mnem[i].kind = LD_ARG then
            begin
              if not EvalAndTest (x2, $FF) then exit;
              kod := kod xor $4000;
              OutIndex := 3;
            end {if};
            SkipBlanks;
            if not ParseChar (')') then exit;	{ failure, ')' expected }
            OutBuf[0] := Hi(kod) xor byte(j);
            OutBuf[1] := byte(kod xor x1 xor sign) xor Hi(x2);
            OutBuf[2] := byte(x2);
          end

  { memory pointed to by a directly or indirectly specified register }
          else
          begin
            if not RegArgum (x2) then exit;	{ failure, register expected }
            if x2 < $6000 then OutIndex := 2 else OutIndex := 3;
            SkipBlanks;
            if not ParseChar (')') then exit;	{ failure, ')' expected }
            kod := kod xor $3900;
            OutBuf[0] := Hi(kod);
            OutBuf[1] := byte(kod xor x1) xor Hi(x2);
            OutBuf[2] := byte(x2);
  { optional relative jump }
            OptRelJump;
          end {if};

        end

{ second operand: directly or indirectly specified register }
        else if RegArgum (x2) then
        begin
          if x2 < $6000 then OutIndex := 2 else OutIndex := 3;
          kod := kod xor $2A00;
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod xor x1) xor Hi(x2);
          OutBuf[2] := byte(x2);
  { optional relative jump }
          OptRelJump;
        end

{ second operand: immediate data }
        else
        begin
          if mnem[i].kind = LDW_ARG then
          begin
            OutIndex := 4;
            x3 := $FFFF;
            kod := kod xor $7900;
          end
          else
          begin
            OutIndex := 3;
            x3 := $FF;
            kod := kod xor $6A00;
          end {if};
          if not EvalAndTest (x2, x3) then exit;
          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod xor x1);
          OutBuf[2] := byte(x2);
          OutBuf[3] := Hi(x2);
  { optional relative jump for byte size transfers }
          if (mnem[i].kind = LD_ARG) then OptRelJump;
        end {if};

      end {case LD_ARG, LDW_ARG};


    ST_ARG,
    STW_ARG:
      begin
{ first operand: register }
        if RegArgum (x1) and (x1 >= $6000) then
        begin
          if not ParseComma then exit;		{ failure, comma expected }
          if not ParseChar ('(') then exit;	{ failure, '(' expected }
          SkipBlanks;

  { memory pointed to by an index register with an offset }
          if ParseTable (j, wregs, NIREGS) then
          begin
            if not ParseSign (sign) then exit;	{ failure, sign expected }
  { register as offset }
            if RegArgum (x2) then
            begin
              if x2 < $6000 then OutIndex := 2 else OutIndex := 3;
            end
  { immediate offset, supported only by byte size transfers }
            else if mnem[i].kind = ST_ARG then
            begin
              if not EvalAndTest (x2, $FF) then exit;
              kod := kod xor $4000;
              OutIndex := 3;
            end {if};
            SkipBlanks;
            if not ParseChar (')') then exit;	{ failure, ')' expected }
            OutBuf[0] := Hi(kod) xor byte(j);
            OutBuf[1] := byte(kod xor x1 xor sign) xor Hi(x2);
            OutBuf[2] := byte(x2);
          end

  { memory pointed to by a directly or indirectly specified register }
          else
          begin
            if not RegArgum (x2) then exit;	{ failure, register expected }
            if x2 < $6000 then OutIndex := 2 else OutIndex := 3;
            SkipBlanks;
            if not ParseChar (')') then exit;	{ failure, ')' expected }
            kod := kod xor $3000;
            OutBuf[0] := Hi(kod);
            OutBuf[1] := byte(kod xor x1) xor Hi(x2);
            OutBuf[2] := byte(x2);
  { optional relative jump }
            OptRelJump;
          end {if};

        end

{ first operand: immediate data }
        else
        begin
          if mnem[i].kind = STW_ARG then
          begin
            OutIndex := 4;
            x3 := $FFFF
          end
          else
          begin
            OutIndex := 3;
            x3 := $FF;
          end {if};
          if not EvalAndTest (x2, x3) then exit;
          if not ParseComma then exit;		{ failure, comma expected }
  { memory pointed to by a SIR }
          if not ParseChar ('(') then exit;	{ failure, '(' expected }
          if not RegArgum (x1) then exit;	{ failure, register expected }
          if x1 >= $6000 then exit;		{ failure, SIR expected }
          SkipBlanks;
          if not ParseChar (')') then exit;	{ failure, ')' expected }
          kod := kod xor $7000;

          OutBuf[0] := Hi(kod);
          OutBuf[1] := byte(kod) xor Hi(x1);
          OutBuf[2] := byte(x2);
          OutBuf[3] := Hi(x2);
        end {if};

      end {case ST_ARG, STW_ARG};


    DB_ARG:		{ up to 4 data bytes }
      begin
        while (OutIndex < 4) and EvalAndTest (x1, $FF) do
        begin
          OutBuf[OutIndex] := x1;
          Inc (OutIndex);
          if not ParseComma then break;
        end {while};
      end {case DB_ARG};


{ else an internal error }

  end {case};

{ the rest of the InBuf is allowed to be padded with spaces only }
  SkipBlanks;
  if (InIndex > Length(InBuf))	 	{ end of line? }
	or ParseChar (';') then		{ comment? }
    InIndex := 0;			{ success }
{ otherwise failure, extra characters encountered }

end {Assemble};


end.
