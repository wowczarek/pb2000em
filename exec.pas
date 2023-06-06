{ HD61700 instruction execution }

unit Exec;


interface

  procedure IllComm;
  procedure Ld_02;
  procedure AdSb_08;
  procedure AdbSbb_0A;
  procedure Logic_0C;
  procedure St_10;
  procedure Ld_11;
  procedure Stl_12;
  procedure Ldl_13;
  procedure PpoPfl_14;
  procedure Psr_15;
  procedure Pst_16;
  procedure Rod_18;
  procedure Rou_18;
  procedure Bid_18;
  procedure Biu_18;
  procedure Did_1A;
  procedure Diu_1A;
  procedure BydByu_1A;
  procedure CmpInv_1B;
  procedure GpoGfl_1C;
  procedure Gsr_1D;
  procedure Gst_1E;
  procedure StSti_20;
  procedure Std_24;
  procedure PhsPhu_26;
  procedure LdLdi_28;
  procedure Ldd_2C;
  procedure PpsPpu_2E;
  procedure Jp_3x;
  procedure Ld_42;
  procedure AdSb_38;
  procedure St_50;
  procedure Ld_51;
  procedure Stl_52;
  procedure BupsBdns_58;
  procedure SupSdn_5C;
  procedure Cal_7x;
  procedure Ldw_82;
  procedure AdwSbw_88;
  procedure AdbwSbbw_8A;
  procedure LogicW_8C;
  procedure Stw_90;
  procedure Ldw_91;
  procedure Stlw_92;
  procedure Ldlw_93;
  procedure Pre_96;
  procedure Rodw_98;
  procedure Rouw_98;
  procedure Bidw_98;
  procedure Biuw_98;
  procedure Didw_9A;
  procedure Diuw_9A;
  procedure Bydw_9A;
  procedure Byuw_9A;
  procedure CmpwInvw_9B;
  procedure GpowGflw_9C;
  procedure Gre_9E;
  procedure StwStiw_A0;
  procedure Stdw_A4;
  procedure PhswPhuw_A6;
  procedure LdwLdiw_A8;
  procedure Lddw_AC;
  procedure PpswPpuw_AE;
  procedure Jr_Bx;
  procedure AdwSbw_B8;
  procedure Ldm_C2;
  procedure AdbmSbbm_C8;
  procedure AdbmSbbm_CA;
  procedure LogicM_CC;
  procedure Stw_D0;
  procedure Ldw_D1;
  procedure Stlm_D2;
  procedure Ldlm_D3;
  procedure Pre_D6;
  procedure BupBdn_D8;
  procedure Didm_DA;
  procedure Dium_DA;
  procedure Bydm_DA;
  procedure Byum_DA;
  procedure CmpmInvm_DB;
  procedure Jp_DE;
  procedure Jp_DF;
  procedure StmStim_E0;
  procedure Stdm_E4;
  procedure PhsmPhum_E6;
  procedure LdmLdim_E8;
  procedure Lddm_EC;
  procedure PpsmPpum_EE;
  procedure Rtn_Fx;
  procedure Nop_F8;
  procedure Clt_F9;
  procedure Fst_FA;
  procedure Slw_FB;
  procedure Cani_FC;
  procedure Rtni_FD;
  procedure Off_FE;
  procedure Trp_FF;


implementation

  uses Def, Keyboard, Lcd, Port;

type
  Func2 = function : boolean;
  Func3 = function (x1: byte; x2: byte) : byte;

var
  ky1: word;	{ used to prevent the KY register write }

const

{ 8-bit registers, access to the r8tab[6] entry is illegal }
  r8tab: array[0..7] of pointer =
	( @pe, @pd, @ib, @ua, @ia, @ie, @tm, @tm );


{ 16-bit registers }
  r16tab: array[0..7] of pointer =
	( @ix, @iy, @iz, @us, @ss, @ky1, @ky1, @ky1 );


{ specific index registers, access to the last entry is illegal }
  sirtab: array[0..3] of pointer = ( @sx, @sy, @sz, @sz );


{ stack pointers }
  stacktab: array[0..1] of pointer = ( @ss, @us );


{ 8-bit BCD addition }
function AddBcd (addend1: cardinal; addend2: cardinal) : cardinal;
begin
  Result := (addend1 and $0F) + (addend2 and $0F);
  if Result > $09 then Result := ((Result + $06) and $0F) or $10;
  if Result > $1F then Dec(Result,$10);
  Inc(Result, (addend1 and $F0) + (addend2 and $F0));
  if Result > $9F then Result := ((Result + $60) and $FF) or $100;
end {AddBcd};


{ 8-bit BCD subtraction }
function SubBcd (minuend: cardinal; subtrahend: cardinal) : cardinal;
begin
  Result := (minuend and $0F) - (subtrahend and $0F);
  if Result > $09 then Result := (Result - $06) or cardinal (-$10);
  Inc(Result, (minuend and $F0) - (subtrahend and $F0));
  if Result > $9F then Result := (Result - $60) or cardinal (-$100);
end {SubBcd};


procedure SetFlagsB (x: byte);
begin
  flag := flag and not (Z_bit or C_bit or UZ_bit or LZ_bit);
  if x <> 0 then flag := flag or Z_bit;
  if (x and $0F) <> 0 then flag := flag or LZ_bit;
  if (x and $F0) <> 0 then flag := flag or UZ_bit;
end {SetFlagsB};


procedure SetFlagsW (x: word);
begin
  flag := flag and not (Z_bit or C_bit or UZ_bit or LZ_bit);
  if x <> 0 then flag := flag or Z_bit;
  if (x and $0F00) <> 0 then flag := flag or LZ_bit;
  if (x and $F000) <> 0 then flag := flag or UZ_bit;
end {SetFlagsW};


procedure SetFlagsD (x: word);
begin
  flag := flag and not (Z_bit or C_bit or UZ_bit or LZ_bit);
  if x <> 0 then flag := flag or Z_bit;
  if (x and $000F) <> 0 then flag := flag or LZ_bit;
  if (x and $00F0) <> 0 then flag := flag or UZ_bit;
end {SetFlagsW};


procedure SetFlagsM (x: byte);
begin
  flag := flag and not (Z_bit or C_bit or UZ_bit or LZ_bit);
  if (x and $0F) <> 0 then flag := flag or LZ_bit;
  if (x and $F0) <> 0 then flag := flag or UZ_bit;
end {SetFlagsM};


{ set the Carry flag for the NA and OR instructions }
procedure SetLogicC;
var
  x: byte;
begin
  x := opcode[0] and 3;
  if (x = 1) or (x = 2) then flag := flag or C_bit;
end {SetLogicC};


function Imm3Arg (x: byte): byte;
begin
  Result := ((x shr 5) and 7) + 1;
  if Result < 2 then Result := 2;
end {Imm3Arg};


function Imm7Arg : word;
var
  x, y: word;
begin
  y := pc;
  if (opforg > 0) and not Odd(opindex) then FetchByte;
  x := FetchByte;
  if (x and $80) <> 0 then x := $80 - x;
  Imm7Arg := x + y;
end {Imm7Arg};


function AbsArg : word;
var
  x: word;
begin
  x := FetchByte;
  if opforg > 0 then FetchByte;
  AbsArg := x or (FetchByte shl 8);
end {AbsArg};


function RegArg (x: byte) : byte;
begin
  RegArg := x and $1F;
end {RegArg};


function SirArg (x: byte) : pointer;
begin
  SirArg := sirtab[(x shr 5) and 3];
end {SirArg};


function ShortRegArg (x: byte) : byte;
begin
  if (x and $60) = $60 then ShortRegArg := RegArg(FetchByte)
  else ShortRegArg := RegArg(ptrb(SirArg(x))^);
end {ShortRegArg};


function ShortRegAr1 (x, y: byte) : byte;
begin
  if (x and $60) = $60 then ShortRegAr1 := RegArg(y)
  else ShortRegAr1 := RegArg(ptrb(SirArg(x))^);
end {ShortRegAr1};


function ShortRegImm8 (x: byte) : byte;
begin
  if (opcode[0] and $40) = 0 then
    ShortRegImm8 := mr[ShortRegArg(x)]
  else
    ShortRegImm8 := FetchByte;
end {ShortRegImm8};


function IndexOffset (x: byte) : word;
begin
  if (opcode[0] and $40) = 0 then
    Result := word(mr[ShortRegArg(x)])
  else
    Result := word(FetchByte);
  if (x and $80) <> 0 then Result := -Result;
end {IndexOffset};


function GetRegPair (x: byte) : word;
begin
  GetRegPair := mr[RegArg(x)] or (mr[RegArg(x+1)] shl 8);
end {GetRegPair};


procedure PutRegPair (x: byte; y: word);
begin
  mr[RegArg(x)] := Lo(y);
  mr[RegArg(x+1)] := Hi(y);
end {PutRegPair};


{ transfer a byte (two nibbles) through the LCD port }
function LcdByte (x: byte) : byte;
begin
  Result := LcdTransfer (x);
  Result := Result or (LcdTransfer (x shr 4) shl 4);
end {LcdByte};


{ condition codes evaluation }

function CC_z : boolean;
begin
  CC_z := (flag and Z_bit) = 0;
end {CC_z};

function CC_nc : boolean;
begin
  CC_nc := (flag and C_bit) = 0;
end {CC_nc};

function CC_lz : boolean;
begin
  CC_lz := (flag and LZ_bit) = 0;
end {CC_lz};

function CC_uz : boolean;
begin
  CC_uz := (flag and UZ_bit) = 0;
end {CC_uz};

function CC_nz : boolean;
begin
  CC_nz := (flag and Z_bit) <> 0;
end {CC_nz};

function CC_c : boolean;
begin
  CC_c := (flag and C_bit) <> 0;
end {CC_c};

function CC_nlz : boolean;
begin
  CC_nlz := (flag and LZ_bit) <> 0;
end {CC_nlz};

function CC_none : boolean;
begin
  CC_none := True;
end {CC_none};

function TestCC : boolean;
const dtab: array[0..7] of pointer = (
	@CC_z,		{ Z }
	@CC_nc,		{ NC }
	@CC_lz,		{ LZ }
	@CC_uz,		{ UZ }
	@CC_nz,		{ NZ }
	@CC_c,		{ C }
	@CC_nlz,	{ NLZ }
	@CC_none );	{ unconditional }
begin
  TestCC := Func2(dtab[opcode[0] and 7]);
end {TestCC};


procedure Push (where: pointer; what: byte);
begin
  Dec (ptrw(where)^);
  DstPtr (Addr18 (ua shr 2, ptrw(where)^))^ := what;
end {Push};


function Pop (from: pointer) : byte;
begin
  Pop := SrcPtr (Addr18 (ua shr 2, ptrw(from)^))^;
  Inc (ptrw(from)^);
end {Push};


procedure OptionalJr (x: byte);
begin
  if (x and $80) <> 0 then
  begin
    pc := Imm7Arg;
    opindex := 0;	{ prevents subsequent PC alignment }
  end {if};
end {OptionalJr};


function AnOp (x1: byte; x2: byte) : byte;
begin
  AnOp := x1 and x2;
end {AnOp};

function NaOp (x1: byte; x2: byte) : byte;
begin
  NaOp := not (x1 and x2);
end {NaOp};

function OrOp (x1: byte; x2: byte) : byte;
begin
  OrOp := x1 or x2;
end {OrOp};

function XrOp (x1: byte; x2: byte) : byte;
begin
  XrOp := x1 xor x2;
end {XrOp};

function LogicOp (x1: byte; x2: byte) : byte;
const
  dtab: array[0..3] of pointer = (@AnOp, @NaOp, @OrOp, @XrOp);
begin
  LogicOp := Func3 (dtab[opcode[0] and 3]) (x1, x2);
end {LogicOp};


procedure IllComm;
begin
  Inc (cycles, 3);
end {Illcomm};


procedure Ld_02;
var
  x: byte;
begin
  x := FetchByte;
  mr[RegArg(x)] := mr[ShortRegArg(x)];
  OptionalJr(x);
  Inc (cycles, 3);
end {Ld_02};


procedure AdSb_08;
var
  x, src, dst: byte;
  y: word;
begin
  x := FetchByte;
  dst := RegArg(x);
  src := ShortRegImm8(x);
  if (opcode[0] and 1) = 0 then
    y := word(mr[dst]) + word(src)
  else
    y := word(mr[dst]) - word(src);
  if (opcode[0] and 8) <> 0 then mr[dst] := byte(y);
  SetFlagsB(byte(y));
  if y > $FF then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 3);
end {AdSb_08};


procedure AdbSbb_0A;
var
  x, src, dst: byte;
  y: cardinal;
begin
  x := FetchByte;
  dst := RegArg(x);
  src := ShortRegImm8(x);
  if (opcode[0] and 1) = 0 then
    y := AddBcd (cardinal(mr[dst]), cardinal(src))
  else
    y := SubBcd (cardinal(mr[dst]), cardinal(src));
  mr[dst] := byte(y);
  SetFlagsB(byte(y));
  if y > $FF then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 3);
end {AdbSbb_0A};


procedure Logic_0C;
var
  x, y, dst: byte;
begin
  x := FetchByte;
  dst := RegArg(x);
  y := LogicOp (mr[dst], ShortRegImm8(x));
  if (opcode[0] and 8) <> 0 then mr[dst] := y;
  SetFlagsB(byte(y));
  SetLogicC;
  OptionalJr(x);
  Inc (cycles, 3);
end {Logic_0C};


procedure St_10;
var
  x: byte;
  o: word;
begin
  x := FetchByte;
  o := GetRegPair (ShortRegArg(x));
  DstPtr(Addr18(ua shr 4,o))^ := mr[RegArg(x)];
  OptionalJr(x);
  Inc (cycles, 8);
end {St_10};


procedure Ld_11;
var
  x: byte;
  o: word;
begin
  x := FetchByte;
  o := GetRegPair (ShortRegArg(x));
  mr[RegArg(x)] := SrcPtr(Addr18(ua shr 4,o))^;
  OptionalJr(x);
  Inc (cycles, 8);
end {Ld_11};


procedure Stl_12;
var
  x: byte;
begin
  x := FetchByte;
  LcdSync;
  LcdByte (mr[RegArg(x)]);
  OptionalJr(x);
  Inc (cycles, 11);
end {Stl_12};


procedure Ldl_13;
var
  x: byte;
begin
  x := FetchByte;
  LcdSync;
  mr[RegArg(x)] := LcdByte (0);
  OptionalJr(x);
  Inc (cycles, 11);
end {Ldl_13};


procedure PpoPfl_14;
var
  x, y: byte;
begin
  x := FetchByte;
  if (opcode[0] and $40) = 0 then
    y := mr[RegArg(x)]
  else
    y := FetchByte;
  if (x and $40) = 0 then
    lcdctrl := y
  else
    flag := (flag and $0F) or (y and $F0);
  if (opcode[0] and $40) = 0 then OptionalJr(x);
  Inc (cycles, 3);
end {PpoPfl_14};


procedure Psr_15;
var
  x, y: byte;
begin
  x := FetchByte;
  if (opcode[0] and $40) = 0 then
    y := mr[RegArg(x)]
  else
    y := x;
  ptrb(SirArg(x))^ := y and $1F;
  if (opcode[0] and $40) = 0 then OptionalJr(x);
  Inc (cycles, 3);
end {Psr_15};


procedure Pst_16;
var
  x, y, i: byte;
begin
  x := FetchByte;
  i := ((opcode[0] shl 2) and 4) + ((x shr 5) and 3);
  if (opcode[0] and $40) = 0 then y := mr[RegArg(x)] else y := FetchByte;
  if i = 2 then			{ IB }
    ib := (ib and $1F) or (y and $E0)
  else if i < 6	then		{ the TM register cannot be written }
    ptrb(r8tab[i])^ := y;
  if i <= 1 then WritePd	{ PE, PD }
  else if i = 5 then		{ IE }
  begin
    y := y shr 3;
    ib := ib and (y or $E0);
    iserv := iserv and y;
  end {if};
  if (opcode[0] and $40) = 0 then OptionalJr(x);
  Inc (cycles, 3);
end {Pst_16};


procedure Rod_18;
var
  x, y, dst: byte;
begin
  x := FetchByte;
  dst := RegArg(x);
  y := mr[dst];
  mr[dst] := mr[dst] shr 1;
  if (flag and C_bit) <> 0 then Inc (mr[dst], $80);
  SetFlagsB(mr[dst]);
  if (y and 1) <> 0 then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 3);
end {Rod_18};


procedure Rou_18;
var
  x, y, dst: byte;
begin
  x := FetchByte;
  dst := RegArg(x);
  y := mr[dst];
  mr[dst] := mr[dst] shl 1;
  if (flag and C_bit) <> 0 then Inc (mr[dst]);
  SetFlagsB(mr[dst]);
  if (y and $80) <> 0 then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 3);
end {Rou_18};


procedure Bid_18;
var
  x, y, dst: byte;
begin
  x := FetchByte;
  dst := RegArg(x);
  y := mr[dst];
  mr[dst] := mr[dst] shr 1;
  SetFlagsB(mr[dst]);
  if (y and 1) <> 0 then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 3);
end {Bid_18};


procedure Biu_18;
var
  x, y, dst: byte;
begin
  x := FetchByte;
  dst := RegArg(x);
  y := mr[dst];
  mr[dst] := mr[dst] shl 1;
  SetFlagsB(mr[dst]);
  if (y and $80) <> 0 then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 3);
end {Biu_18};


procedure Did_1A;
var
  x, dst: byte;
begin
  x := FetchByte;
  dst := RegArg(x);
  mr[dst] := mr[dst] shr 4;
  SetFlagsB(mr[dst]);
  OptionalJr(x);
  Inc (cycles, 3);
end {Did_1A};


procedure Diu_1A;
var
  x, dst: byte;
begin
  x := FetchByte;
  dst := RegArg(x);
  mr[dst] := mr[dst] shl 4;
  SetFlagsB(mr[dst]);
  OptionalJr(x);
  Inc (cycles, 3);
end {Diu_1A};


procedure BydByu_1A;
var
  x: byte;
begin
  x := FetchByte;
  mr[RegArg(x)] := 0;
  flag := flag and not (C_bit or Z_bit or UZ_bit or LZ_bit);
  OptionalJr(x);
  Inc (cycles, 3);
end {BydByu_1A};


procedure CmpInv_1B;
var
  x, y, dst: byte;
begin
  x := FetchByte;
  dst := RegArg(x);
  y := not mr[dst];
  if (x and $40) = 0 then Inc (y);
  mr[dst] := y;
  SetFlagsB(y);
  if (y <> 0) or ((x and $40) <> 0) then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 3);
end {CmpInv_1B};


procedure GpoGfl_1C;
var
  x: byte;
begin
  x := FetchByte;
  if (x and $40) = 0 then
    mr[RegArg(x)] := ReadPd
  else
    mr[RegArg(x)] := flag;
  OptionalJr(x);
  Inc (cycles, 3);
end {GpoGfl_1C};


procedure Gsr_1D;
var
  x: byte;
begin
  x := FetchByte;
  mr[RegArg(x)] := ptrb(SirArg(x))^;
  OptionalJr(x);
  Inc (cycles, 3);
end {Gsr_1D};


procedure Gst_1E;
var
  x, i: byte;
begin
  x := FetchByte;
  i := ((opcode[0] shl 2) and 4) + ((x shr 5) and 3);
  mr[RegArg(x)] := ptrb(r8tab[i])^;
  OptionalJr(x);
  Inc (cycles, 3);
end {Gst_1E};


procedure StSti_20;
var
  x, s: byte;
  irsave: word;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  irsave := ir^;
  x := FetchByte;
  Inc (ir^, IndexOffset (x));
  DstPtr(Addr18(s,ir^))^ := mr[RegArg(x)];
  Inc (ir^);
  if (opcode[0] and 2) = 0 then ir^ := irsave;
  Inc (cycles, 8);
end {StSti_20};


procedure Std_24;
var
  x, s: byte;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  x := FetchByte;
  Inc (ir^, IndexOffset(x));
  DstPtr(Addr18(s,ir^))^ := mr[RegArg(x)];
  Inc (cycles, 6);
end {Std_24};


procedure PhsPhu_26;
begin
  Push (stacktab[opcode[0] and 1], mr[RegArg(FetchByte)]);
  Inc (cycles, 9);
end {PhsPhu_26};


procedure LdLdi_28;
var
  x, s: byte;
  irsave: word;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  irsave := ir^;
  x := FetchByte;
  Inc (ir^, IndexOffset(x));
  mr[RegArg(x)] := SrcPtr(Addr18(s,ir^))^;
  Inc (ir^);
  if (opcode[0] and 2) = 0 then ir^ := irsave;
  Inc (cycles, 8);
end {LdLdi_28};


procedure Ldd_2C;
var
  x, s: byte;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  x := FetchByte;
  Inc (ir^, IndexOffset(x));
  mr[RegArg(x)] := SrcPtr(Addr18(s,ir^))^;
  Inc (cycles, 6);
end {Ldd_2C};


procedure PpsPpu_2E;
begin
  mr[RegArg(FetchByte)] := Pop (stacktab[opcode[0] and 1]);
  Inc (cycles, 11);
end {PpsPpu_2E};


procedure Jp_3x;
var
  x: word;
begin
  x := AbsArg;
  if TestCC then
  begin
    pc := x;
    opindex := 0;	{ prevents subsequent PC alignment }
  end {if};
  Inc (cycles, 3);
end {Jp_3x};


procedure Ld_42;
var
  x: byte;
begin
  x := FetchByte;
  mr[RegArg(x)] := FetchByte;
  OptionalJr(x);
  Inc (cycles, 3);
end {Ld_42};


procedure AdSb_38;
var
  x, s: byte;
  y, o: word;
  src: ptrb;
begin
  if (opcode[0] and 1) = 0 then
  begin
    o := ix;
    s := ua shr 4;
  end
  else
  begin
    o := iz;
    s := ua shr 6;
  end {if};
  x := FetchByte;
  Inc (o, IndexOffset(x));
  src := SrcPtr(Addr18(s,o));
  if (opcode[0] and 2) = 0 then
    y := word(src^) + word(mr[RegArg(x)])
  else
    y := word(src^) - word(mr[RegArg(x)]);
  if (opcode[0] and 4) <> 0 then DstPtr(Addr18(s,o))^ := byte(y);
  SetFlagsB(byte(y));
  if y > $FF then flag := flag or C_bit;
  Inc (cycles, 9);
end {AdSb_38};


procedure St_50;
var
  x: byte;
  o: word;
begin
  x := FetchByte;
  o := GetRegPair (ptrb(SirArg(x))^);
  DstPtr(Addr18(ua shr 4,o))^ := FetchByte;
  Inc (cycles, 8);
end {St_50};


procedure Ld_51;
var
  x: byte;
begin
  x := FetchByte;
  mr[RegArg(x)] := FetchByte;
  Inc (cycles, 8);
end {Ld_51};


procedure Stl_52;
begin
  LcdSync;
  LcdByte (FetchByte);
  Inc (cycles, 12);
end {Stl_52};


procedure BupsBdns_58;
var
  x1, x2, s1, s2: byte;
  y, step: word;
begin
  x1 := FetchByte;
  s1 := ua shr 6;
  s2 := ua shr 4;
  if (opcode[0] and 1) = 0 then step := 1 else step := word(-1);
  repeat
    x2 := SrcPtr(Addr18(s2,ix))^;
    DstPtr(Addr18(s1,iz))^ := x2;
    y := word(x2) - word(x1);
    Inc (cycles, 6);
    if (y = 0) or (ix = iy) then Break;
    Inc (ix, step);
    Inc (iz, step);
  until False;
  SetFlagsB(byte(y));
  if y > $FF then flag := flag or C_bit;
  Inc (cycles, 3);
end {BupsBdns_58};


procedure SupSdn_5C;
var
  x, s: byte;
  y, step: word;
begin
  x := FetchByte;
  if (opcode[0] and $80) <> 0 then x := mr[RegArg(x)];
  s := ua shr 4;
  if (opcode[0] and 1) = 0 then step := 1 else step := word(-1);
  repeat
    y := word(SrcPtr(Addr18(s,ix))^) - word(x);
    Inc (cycles, 6);
    if (y = 0) or (ix = iy) then Break;
    Inc (ix, step);
  until False;
  SetFlagsB(byte(y));
  if y > $FF then flag := flag or C_bit;
  Inc (cycles, 3);
end {SupSdn_5C};


procedure Cal_7x;
var
  x: word;
begin
  x := AbsArg;
  if TestCC then
  begin
    Dec (pc);
    Push (@ss, Hi (pc));
    Push (@ss, Lo (pc));
    pc := x;
    opindex := 0;	{ prevents subsequent PC alignment }
    Inc (cycles, 6);
  end {if};
  Inc (cycles, 3);
end {Cal_7x};


procedure Ldw_82;
var
  x, src, dst: byte;
begin
  x := FetchByte;
  dst := RegArg(x);
  src := ShortRegArg(x);
  mr[dst] := mr[src];
  dst := RegArg(dst+1);
  src := RegArg(src+1);
  mr[dst] := mr[src];
  OptionalJr(x);
  Inc (cycles, 8);
end {Ldw_82};


procedure AdwSbw_88;
var
  x, src, dst: byte;
  y: cardinal;
begin
  x := FetchByte;
  dst := RegArg(x);
  src := ShortRegArg(x);
  if (opcode[0] and 1) = 0 then
    y := cardinal(GetRegPair(dst)) + cardinal(GetRegPair(src))
  else
    y := cardinal(GetRegPair(dst)) - cardinal(GetRegPair(src));
  if (opcode[0] and 8) <> 0 then PutRegPair(dst, y);
  SetFlagsW(y);
  if y > $FFFF then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 8);
end {AdwSbw_88};


procedure AdbwSbbw_8A;
var
  x, src, dst: byte;
  y1, y2: cardinal;
begin
  x := FetchByte;
  dst := RegArg(x);
  src := ShortRegArg(x);
  if (opcode[0] and 1) = 0 then
    y1 := AddBcd (cardinal(mr[dst]), cardinal(mr[src]))
  else
    y1 := SubBcd (cardinal(mr[dst]), cardinal(mr[src]));
  mr[dst] := byte(y1);
  if y1 > $FF then y2 := 1 else y2 := 0;
  src := RegArg(src+1);
  dst := RegArg(dst+1);
  if (opcode[0] and 1) = 0 then
    y2 := AddBcd (cardinal(mr[dst]), cardinal(mr[src]) + y2)
  else
    y2 := SubBcd (cardinal(mr[dst]), cardinal(mr[src]) + y2);
  mr[dst] := byte(y2);
  SetFlagsM(byte(y2));
  if y2 > $FF then flag := flag or C_bit;
  if (y1 or y2) <> 0 then flag := flag or Z_bit;
  OptionalJr(x);
  Inc (cycles, 8);
end {AdbwSbbw_8A};


procedure LogicW_8C;
var
  x, y1, y2, src, dst: byte;
begin
  x := FetchByte;
  dst := RegArg(x);
  src := ShortRegArg(x);
  y1 := LogicOp (mr[dst], mr[src]);
  if (opcode[0] and 8) <> 0 then mr[dst] := y1;
  y2 := LogicOp (mr[dst+1], mr[src+1]);
  if (opcode[0] and 8) <> 0 then mr[dst+1] := y2;
  SetFlagsM(y2);
  SetLogicC;
  if (y1 or y2) <> 0 then flag := flag or Z_bit;
  OptionalJr(x);
  Inc (cycles, 8);
end {LogicW_8C};


procedure Stw_90;
var
  x, s: byte;
  o: word;
begin
  x := FetchByte;
  s := ua shr 4;
  o := GetRegPair (ShortRegArg(x));
  DstPtr(Addr18(s,o))^ := mr[RegArg(x)];
  DstPtr(Addr18(s,o+1))^ := mr[RegArg(x+1)];
  OptionalJr(x);
  Inc (cycles, 11);
end {Stw_90};


procedure Ldw_91;
var
  x, s: byte;
  o: word;
begin
  x := FetchByte;
  s := ua shr 4;
  o := GetRegPair (ShortRegArg(x));
  mr[RegArg(x)] := SrcPtr(Addr18(s,o))^;
  mr[RegArg(x+1)] := SrcPtr(Addr18(s,o+1))^;
  OptionalJr(x);
  Inc (cycles, 11);
end {Ldw_91};


procedure Stlw_92;
var
  x: byte;
begin
  x := FetchByte;
  LcdSync;
  LcdByte (mr[RegArg(x)]);
  LcdByte (mr[RegArg(x+1)]);
  OptionalJr(x);
  Inc (cycles, 19);
end {Stlw_92};


procedure Ldlw_93;
var
  x: byte;
begin
  x := FetchByte;
  LcdSync;
  mr[RegArg(x)] := LcdByte (0);
  mr[RegArg(x+1)] := LcdByte (0);
  OptionalJr(x);
  Inc (cycles, 19);
end {Ldlw_93};


procedure Pre_96;
var
  x: byte;
  dst: pointer;
begin
  x := FetchByte;
  dst := r16tab[((opcode[0] shl 2) and 4) + ((x shr 5) and 3)];
  ptrb(dst)^ := mr[RegArg(x)];
  ptrb(PChar(dst)+1)^ := mr[RegArg(x+1)];
{ ptrw(dst)^ := GetRegPair(x) would be less efficient }
  OptionalJr(x);
  Inc (cycles, 8);
end {Pre_96};


procedure Rodw_98;
var
  x, dst: byte;
  y1, y2: word;
begin
  x := FetchByte;
  dst := RegArg(x-1);
  y1 := GetRegPair(dst);
  y2 := y1 shr 1;
  if (flag and C_bit) <> 0 then Inc (y2, $8000);
  PutRegPair(dst,y2);
  SetFlagsD(y2);
  if (y1 and 1) <> 0 then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 11);
end {Rodw_98};


procedure Rouw_98;
var
  x, dst: byte;
  y1, y2: word;
begin
  x := FetchByte;
  dst := RegArg(x);
  y1 := GetRegPair(dst);
  y2 := y1 shl 1;
  if (flag and C_bit) <> 0 then Inc (y2);
  PutRegPair(dst,y2);
  SetFlagsW(y2);
  if (y1 and $8000) <> 0 then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 11);
end {Rouw_98};


procedure Bidw_98;
var
  x, dst: byte;
  y1, y2: word;
begin
  x := FetchByte;
  dst := RegArg(x-1);
  y1 := GetRegPair(dst);
  y2 := y1 shr 1;
  PutRegPair(dst,y2);
  SetFlagsD(y2);
  if (y1 and 1) <> 0 then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 11);
end {Bidw_98};


procedure Biuw_98;
var
  x, dst: byte;
  y1, y2: word;
begin
  x := FetchByte;
  dst := RegArg(x);
  y1 := GetRegPair(dst);
  y2 := y1 shl 1;
  PutRegPair(dst,y2);
  SetFlagsW(y2);
  if (y1 and $8000) <> 0 then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 11);
end {Biuw_98};


procedure Didw_9A;
var
  x, dst: byte;
  y: word;
begin
  x := FetchByte;
  dst := RegArg(x-1);
  y := GetRegPair(dst) shr 4;
  PutRegPair(dst,y);
  SetFlagsD(y);
  OptionalJr(x);
  Inc (cycles, 11);
end {Didw_9A};


procedure Diuw_9A;
var
  x, dst: byte;
  y: word;
begin
  x := FetchByte;
  dst := RegArg(x);
  y := GetRegPair(dst) shl 4;
  PutRegPair(dst,y);
  SetFlagsW(y);
  OptionalJr(x);
  Inc (cycles, 11);
end {Diuw_9A};


procedure Bydw_9A;
var
  x, y: byte;
begin
  x := FetchByte;
  y := mr[RegArg(x)];
  mr[RegArg(x-1)] := y;
  mr[RegArg(x)] := 0;
  SetFlagsB(y);		{the low order byte determines the flags}
  OptionalJr(x);
  Inc (cycles, 11);
end {Bydw_9A};


procedure Byuw_9A;
var
  x, y: byte;
begin
  x := FetchByte;
  y := mr[RegArg(x)];
  mr[RegArg(x+1)] := y;
  mr[RegArg(x)] := 0;
  SetFlagsB(y);		{the high order byte determines the flags}
  OptionalJr(x);
  Inc (cycles, 11);
end {Byuw_9A};


procedure CmpwInvw_9B;
var
  x, dst: byte;
  y: word;
begin
  x := FetchByte;
  dst := RegArg(x);
  y := not GetRegPair(dst);
  if (x and $40) = 0 then Inc (y);
  PutRegPair(dst,y);
  SetFlagsW(y);
  if (y <> 0) or ((x and $40) <> 0) then flag := flag or C_bit;
  OptionalJr(x);
  Inc (cycles, 8);
end {CmpwInvw_9B};


procedure GpowGflw_9C;
var
  x: byte;
begin
  x := FetchByte;
  if (x and $40) = 0 then
  begin
    mr[RegArg(x)] := ReadPd;
    mr[RegArg(x+1)] := ReadPd;
  end
  else
  begin
    mr[RegArg(x)] := flag;
    mr[RegArg(x+1)] := flag;
  end {if};
  OptionalJr(x);
  Inc (cycles, 8);
end {GpowGflw_9C};


procedure Gre_9E;
var
  x, i: byte;
  src: pointer;
begin
  x := FetchByte;
  i := ((opcode[0] shl 2) and 4) + ((x shr 5) and 3);
  if i >= 5 then ky1 := (ky and $0F00) or ReadKy (ia and $0F);
  src := r16tab[i];
  mr[RegArg(x)] := ptrb(src)^;
  mr[RegArg(x+1)] := ptrb(PChar(src)+1)^;
  OptionalJr(x);
  Inc (cycles, 8);
end {Gre_9E};


procedure StwStiw_A0;
var
  x, s: byte;
  d, irsave: word;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  irsave := ir^;
  x := FetchByte;
  d := word(mr[ShortRegArg(x)]);
  if (x and $80) = 0 then Inc (ir^, d) else Dec (ir^, d);
  DstPtr(Addr18(s,ir^))^ := mr[RegArg(x)];
  Inc (ir^);
  DstPtr(Addr18(s,ir^))^ := mr[RegArg(x+1)];
  Inc (ir^);
  if (opcode[0] and 2) = 0 then ir^ := irsave;
  Inc (cycles, 11);
end {StwStiw_A0};


procedure Stdw_A4;
var
  x, s: byte;
  d: word;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  x := FetchByte;
  d := word(mr[ShortRegArg(x)]);
  if (x and $80) = 0 then Inc (ir^, d) else Dec (ir^, d);
  DstPtr(Addr18(s,ir^))^ := mr[RegArg(x)];
  Dec (ir^);
  DstPtr(Addr18(s,ir^))^ := mr[RegArg(x-1)];
  Inc (cycles, 9);
end {Stdw_A4};


procedure PhswPhuw_A6;
var
  x: byte;
  st: pointer;
begin
  st := stacktab[opcode[0] and 1];
  x := FetchByte;
  Push (st, mr[RegArg(x)]);
  Push (st, mr[RegArg(x-1)]);
  Inc (cycles, 12);
end {PhswPhuw_A6};


procedure LdwLdiw_A8;
var
  x, s: byte;
  d, irsave: word;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  irsave := ir^;
  x := FetchByte;
  d := word(mr[ShortRegArg(x)]);
  if (x and $80) = 0 then Inc (ir^, d) else Dec (ir^, d);
  mr[RegArg(x)] := SrcPtr(Addr18(s,ir^))^;
  Inc (ir^);
  mr[RegArg(x+1)] := SrcPtr(Addr18(s,ir^))^;
  Inc (ir^);
  if (opcode[0] and 2) = 0 then ir^ := irsave;
  Inc (cycles, 11);
end {LdwLdiw_A8};


procedure Lddw_AC;
var
  x, s: byte;
  d: word;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  x := FetchByte;
  d := word(mr[ShortRegArg(x)]);
  if (x and $80) = 0 then Inc (ir^, d) else Dec (ir^, d);
  mr[RegArg(x)] := SrcPtr(Addr18(s,ir^))^;
  Dec (ir^);
  mr[RegArg(x-1)] := SrcPtr(Addr18(s,ir^))^;
  Inc (cycles, 9);
end {Lddw_AC};


procedure PpswPpuw_AE;
var
  x: byte;
  st: pointer;
begin
  st := stacktab[opcode[0] and 1];
  x := FetchByte;
  mr[RegArg(x)] := Pop (st);
  mr[RegArg(x+1)] := Pop (st);
  Inc (cycles, 14);
end {PpswPpuw_AE};


procedure Jr_Bx;
var
  x: word;
begin
  x := Imm7Arg;
  if TestCC then
  begin
    pc := x;
    opindex := 0;	{ prevents subsequent PC alignment }
  end {if};
  Inc (cycles, 3);
end {Jr_Bx};


procedure AdwSbw_B8;
var
  x, s: byte;
  o, d, y1, y2: word;
  src1, src2: ptrb;
begin
  if (opcode[0] and 1) = 0 then
  begin
    o := ix;
    s := ua shr 4;
  end
  else
  begin
    o := iz;
    s := ua shr 6;
  end {if};
  x := FetchByte;
  d := word(mr[ShortRegArg(x)]);
  if (x and $80) = 0 then Inc (o,d) else Dec (o,d);
  src1 := SrcPtr(Addr18(s,o));
  src2 := SrcPtr(Addr18(s,o+1));
  if (opcode[0] and 2) = 0 then
  begin
    y1 := word(src1^) + word(mr[RegArg(x)]);
    if y1 > 255 then d := 1 else d := 0;
    y2 := word(src2^) + word(mr[RegArg(x+1)]) + d;
  end
  else
  begin
    y1 := word(src1^) - word(mr[RegArg(x)]);
    if y1 > 255 then d := 1 else d := 0;
    y2 := word(src2^) - word(mr[RegArg(x+1)]) - d;
  end {if};
  if (opcode[0] and 4) <> 0 then
  begin
    DstPtr(Addr18(s,o))^ := byte(y1);
    DstPtr(Addr18(s,o+1))^ := byte(y2);
  end {if};
  SetFlagsM(byte(y2));
  if (y1 or y2) <> 0 then flag := flag or Z_bit;
  if y2 > $FF then flag := flag or C_bit;
  Inc (cycles, 15);
end {AdwSbw_B8};


procedure Ldm_C2;
var
  x, y, src, dst, n: byte;
begin
  x := FetchByte;
  y := FetchByte;
  src := ShortRegAr1(x,y);
  dst := x;
  n := Imm3Arg(y);
  repeat
    mr[RegArg(dst)] := mr[RegArg(src)];
    Inc (dst);
    Inc (src);
    Dec (n);
    Inc (cycles, 5);
  until n = 0;
  OptionalJr(x);
  Dec (cycles, 2);
end {Ldm_C2};


procedure AdbmSbbm_C8;
var
  x, z, src, dst, n: byte;
  y1, y2: cardinal;
begin
  x := FetchByte;
  z := FetchByte;
  src := ShortRegAr1(x,z);
  dst := x;
  n := Imm3Arg(z);
  y1 := 0;
  z := 0;
  repeat
    if (opcode[0] and 1) = 0 then
      y2 := AddBcd (cardinal(mr[RegArg(dst)]), cardinal(mr[RegArg(src)]) + y1)
    else
      y2 := SubBcd (cardinal(mr[RegArg(dst)]), cardinal(mr[RegArg(src)]) + y1);
    if y2 > 255 then y1 := 1 else y1 := 0;
    if (opcode[0] and 8) <> 0 then mr[RegArg(dst)] := byte(y2);
    z := z or byte(y2);
    Inc (dst);
    Inc (src);
    Dec (n);
    Inc (cycles, 5);
  until n = 0;
  SetFlagsM (byte(y2));
  if z <> 0 then flag := flag or Z_bit;
  if y2 > $FF then flag := flag or C_bit;
  OptionalJr(x);
  Dec (cycles, 2);
end {AdbmSbbm_C8};


procedure AdbmSbbm_CA;
var
  x, z, dst, n: byte;
  y1, y2: cardinal;
begin
  x := FetchByte;
  z := FetchByte;
  dst := x;
  n := Imm3Arg(z);
  y1 := cardinal(z and $1F);
  z := 0;
  repeat
    if (opcode[0] and 1) = 0 then
      y2 := AddBcd (cardinal(mr[RegArg(dst)]), y1)
    else
      y2 := SubBcd (cardinal(mr[RegArg(dst)]), y1);
    if y2 > 255 then y1 := 1 else y1 := 0;
    if (opcode[0] and 8) <> 0 then mr[RegArg(dst)] := byte(y2);
    z := z or byte(y2);
    Inc (dst);
    Dec (n);
    Inc (cycles, 5);
  until n = 0;
  SetFlagsM (byte(y2));
  if z <> 0 then flag := flag or Z_bit;
  if y2 > $FF then flag := flag or C_bit;
  OptionalJr(x);
  Dec (cycles, 2);
end {AdbmSbbm_CA};


procedure LogicM_CC;
var
  x, y, z, src, dst, n: byte;
begin
  x := FetchByte;
  y := FetchByte;
  src := ShortRegAr1(x,y);
  dst := x;
  n := Imm3Arg(y);
  z := 0;
  repeat
    y := LogicOp (mr[RegArg(dst)], mr[RegArg(src)]);
    if (opcode[0] and 8) <> 0 then mr[RegArg(dst)] := y;
    z := z or y;
    Inc (dst);
    Inc (src);
    Dec (n);
    Inc (cycles, 5);
  until n = 0;
  SetFlagsM (y);
  SetLogicC;
  if z <> 0 then flag := flag or Z_bit;
  OptionalJr(x);
  Dec (cycles, 2);
end {LogicM_CC};


procedure Stw_D0;
var
  x, s: byte;
  o: word;
begin
  x := FetchByte;
  s := ua shr 4;
  o := GetRegPair (ptrb(SirArg(x))^);
  DstPtr(Addr18(s,o))^ := FetchByte;
  DstPtr(Addr18(s,o+1))^ := FetchByte;
  Inc (cycles, 11);
end {Stw_D0};


procedure Ldw_D1;
var
  x: byte;
begin
  x := FetchByte;
  mr[RegArg(x)] := FetchByte;
  mr[RegArg(x+1)] := FetchByte;
  Inc (cycles, 11);
end {Ldw_D1};


procedure Stlm_D2;
var
  x, n: byte;
begin
  x := RegArg (FetchByte);
  n := Imm3Arg (FetchByte);
  LcdSync;
  repeat
    LcdByte (mr[RegArg(x)]);
    Inc (x);
    Dec (n);
    Inc (cycles, 8);
  until n = 0;
  Inc (cycles, 3);
end {Stlm_D2};


procedure Ldlm_D3;
var
  x, n: byte;
begin
  x := FetchByte;
  n := Imm3Arg (FetchByte);
  LcdSync;
  repeat
    mr[RegArg(x)] := LcdByte (0);
    Inc (x);
    Dec (n);
    Inc (cycles, 8);
  until n = 0;
  Inc (cycles, 3);
end {Ldlm_D3};


procedure Pre_D6;
var
  dst: pointer;
begin
  dst := r16tab[((opcode[0] shl 2) and 4) + ((FetchByte shr 5) and 3)];
  ptrb(dst)^ := FetchByte;
  ptrb(PChar(dst)+1)^ := FetchByte;
  Inc (cycles, 8);
end {Pre_D6};


procedure Didm_DA;
var
  x, y1, y2, z, n: byte;
begin
  x := FetchByte;
  n := Imm3Arg (FetchByte);
  y1 := 0;
  z := 0;
  repeat
    y2 := y1;
    y1 := mr[RegArg(x)];
    y2 := (y1 shr 4) or (y2 shl 4);
    mr[RegArg(x)] := y2;
    z := z or y2;
    Dec (x);
    Dec (n);
    Inc (cycles, 5);
  until n = 0;
  SetFlagsM (y2);
  if z <> 0 then flag := flag or Z_bit;
  Dec (cycles, 2);
end {Didm_DA};


procedure Dium_DA;
var
  x, y1, y2, z, n: byte;
begin
  x := FetchByte;
  n := Imm3Arg (FetchByte);
  y1 := 0;
  z := 0;
  repeat
    y2 := y1;
    y1 := mr[RegArg(x)];
    y2 := (y1 shl 4) or (y2 shr 4);
    mr[RegArg(x)] := y2;
    z := z or y2;
    Inc (x);
    Dec (n);
    Inc (cycles, 5);
  until n = 0;
  SetFlagsM (y2);
  if z <> 0 then flag := flag or Z_bit;
  Dec (cycles, 2);
end {Dium_DA};


procedure Bydm_DA;
var
  x, y1, y2, z, n: byte;
begin
  x := FetchByte;
  n := Imm3Arg (FetchByte);
  y1 := 0;
  z := 0;
  repeat
    y2 := y1;
    y1 := mr[RegArg(x)];
    mr[RegArg(x)] := y2;
    z := z or y2;
    Dec (x);
    Dec (n);
    Inc (cycles, 5);
  until n = 0;
  SetFlagsM (y2);
  if z <> 0 then flag := flag or Z_bit;
  Dec (cycles, 2);
end {Bydm_DA};


procedure BupBdn_D8;
var
  s1, s2: byte;
  step: word;
begin
  s1 := ua shr 6;
  s2 := ua shr 4;
  if (opcode[0] and 1) = 0 then step := 1 else step := word(-1);
  repeat
    DstPtr(Addr18(s1,iz))^ := SrcPtr(Addr18(s2,ix))^;
    Inc (cycles, 6);
    if ix = iy then Break;
    Inc (ix, step);
    Inc (iz, step);
  until False;
  Inc (cycles, 3);
end {BupBdn_D8};


procedure Byum_DA;
var
  x, y1, y2, z, n: byte;
begin
  x := FetchByte;
  n := Imm3Arg (FetchByte);
  y1 := 0;
  z := 0;
  repeat
    y2 := y1;
    y1 := mr[RegArg(x)];
    mr[RegArg(x)] := y2;
    z := z or y2;
    Inc (x);
    Dec (n);
    Inc (cycles, 5);
  until n = 0;
  SetFlagsM (y2);
  if z <> 0 then flag := flag or Z_bit;
  Dec (cycles, 2);
end {Byum_DA};


procedure CmpmInvm_DB;
var
  x, y1, y2, z, n: byte;
begin
  x := FetchByte;
  n := Imm3Arg (FetchByte);
  if (x and $40) = 0 then y1 := 1 else y1 := 0;
  z := 0;
  repeat
    y2 := y1 + not mr[RegArg(x)];
    mr[RegArg(x)] := y2;
    if y2 <> 0 then y1 := 0;
    z := z or y2;
    Inc (x);
    Dec (n);
    Inc (cycles, 5);
  until n = 0;
  SetFlagsM (y2);
  if z <> 0 then flag := flag or Z_bit;
  if (z <> 0) or ((opcode[1] and $40) <> 0) then flag := flag or C_bit;
  Dec (cycles, 2);
end {CmpmInvm_DB};


procedure Jp_DE;
begin
  pc := GetRegPair (FetchByte);
  opindex := 0;		{ prevents subsequent PC alignment }
  Inc (cycles, 5);
end {Jp_DE};


procedure Jp_DF;
var
  s: byte;
  o: word;
begin
  s := ua shr 4;
  o := GetRegPair (FetchByte);
  pc := SrcPtr(Addr18(s,o))^ or (SrcPtr(Addr18(s,o+1))^ shl 8);
  opindex := 0;		{ prevents subsequent PC alignment }
  Inc (cycles, 5);
end {Jp_DF};


procedure StmStim_E0;
var
  x, y, s, n: byte;
  d, irsave: word;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  irsave := ir^;
  x := FetchByte;
  y := FetchByte;
  d := word(mr[ShortRegAr1(x,y)]);
  if (x and $80) = 0 then Inc (ir^, d) else Dec (ir^, d);
  n := Imm3Arg(y);
  repeat
    DstPtr(Addr18(s,ir^))^ := mr[RegArg(x)];
    Inc (x);
    Inc (ir^);
    Dec (n);
    Inc (cycles, 3);
  until n = 0;
  if (opcode[0] and 2) = 0 then ir^ := irsave;
  Inc (cycles, 5);
end {StmStim_E0};


procedure Stdm_E4;
var
  x, y, s, n: byte;
  d: word;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  x := FetchByte;
  y := FetchByte;
  d := word(mr[ShortRegAr1(x,y)]);
  if (x and $80) = 0 then Inc (ir^, d) else Dec (ir^, d);
  n := Imm3Arg(y);
  repeat
    DstPtr(Addr18(s,ir^))^ := mr[RegArg(x)];
    Dec (x);
    Dec (ir^);
    Dec (n);
    Inc (cycles, 3);
  until n = 0;
  Inc (ir^);
  Inc (cycles, 3);
end {Stdm_E4};


procedure PhsmPhum_E6;
var
  x, n: byte;
  st: pointer;
begin
  st := stacktab[opcode[0] and 1];
  x := FetchByte;
  n := Imm3Arg (FetchByte);
  repeat
    Push (st, mr[RegArg(x)]);
    Dec (x);
    Dec (n);
    Inc (cycles, 3);
  until n = 0;
  Inc (cycles, 3);
end {PhsmPhum_E6};


procedure LdmLdim_E8;
var
  x, y, s, n: byte;
  d, irsave: word;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  irsave := ir^;
  x := FetchByte;
  y := FetchByte;
  d := word(mr[ShortRegAr1(x,y)]);
  if (x and $80) = 0 then Inc (ir^, d) else Dec (ir^, d);
  n := Imm3Arg(y);
  repeat
    mr[RegArg(x)] := SrcPtr(Addr18(s,ir^))^;
    Inc (x);
    Inc (ir^);
    Dec (n);
    Inc (cycles, 3);
  until n = 0;
  if (opcode[0] and 2) = 0 then ir^ := irsave;
  Inc (cycles, 5);
end {LdmLdim_E8};


procedure Lddm_EC;
var
  x, y, s, n: byte;
  d: word;
  ir: ptrw;
begin
  if (opcode[0] and 1) = 0 then
  begin
    ir := ptrw(@ix);
    s := ua shr 4;
  end
  else
  begin
    ir := ptrw(@iz);
    s := ua shr 6;
  end {if};
  x := FetchByte;
  y := FetchByte;
  d := word(mr[ShortRegAr1(x,y)]);
  if (x and $80) = 0 then Inc (ir^, d) else Dec (ir^, d);
  n := Imm3Arg(y);
  repeat
    mr[RegArg(x)] := SrcPtr(Addr18(s,ir^))^;
    Dec (x);
    Dec (ir^);
    Dec (n);
    Inc (cycles, 3);
  until n = 0;
  Inc (ir^);
  Inc (cycles, 3);
end {Lddm_EC};


procedure PpsmPpum_EE;
var
  x, n: byte;
  st: pointer;
begin
  st := stacktab[opcode[0] and 1];
  x := FetchByte;
  n := Imm3Arg (FetchByte);
  repeat
    mr[RegArg(x)] := Pop (st);
    Inc (x);
    Dec (n);
    Inc (cycles, 3);
  until n = 0;
  Inc (cycles, 5);
end {PpsmPpum_EE};


procedure Rtn_Fx;
begin
  if TestCC then
  begin
    pc := Pop (@ss);
    pc := pc or (Pop (@ss) shl 8);
    Inc (pc);
    opindex := 0;	{ prevents subsequent PC alignment }
    Inc (cycles, 8);
  end {if};
  Inc (cycles, 3);
end {Rtn_Fx};


procedure Nop_F8;
begin
  Inc (cycles, 3);
end {Nop_F8};


procedure Clt_F9;
begin
  tm := 0;
  Inc (cycles, 3);
end {Clt_F9};


procedure Fst_FA;
begin
  speed := 0;
  Inc (cycles, 3);
end {Fst_FA};


procedure Slw_FB;
begin
  speed := 4;
  Inc (cycles, 3);
end {Slw_FB};


procedure Cani_FC;
var
  mask: byte;
begin
  mask := $10;
  repeat
    if (ib and mask) <> 0 then
    begin
      ib := ib and not mask;
      iserv := iserv and not mask;
      Break;
    end {if};
    mask := mask shr 1;
  until mask < $01;
  Inc (cycles, 3);
end {Cani_FC};


procedure Rtni_FD;
begin
  pc := Pop (@ss);
  pc := pc or (Pop (@ss) shl 8);
  opindex := 0;		{ prevents subsequent PC alignment }
  Cani_FC;
  Inc (cycles, 8);
  if (ua and 3) <> 0 then Inc (cycles);
end {Rtni_FD};


procedure Off_FE;
begin
  ua := 0;
  pc := $0010;
  opindex := 0;		{ prevents subsequent PC alignment }
  ie := ie and $1C;
  ia := 0;
  ib := ib and $E3;
  iserv := 0;
  ix := 0;
  iy := 0;
  iz := 0;
  sx := 0;
  sy := 0;
  sz := 0;
  pe := 0;
  WritePd;
  lcdctrl := 0;
  LcdInit;
  IoInit;
  CpuSleep := True;
  if (flag and SW_bit) <> 0 then flag := flag or APO_bit
	else flag := flag and not APO_bit;
  Inc (cycles, 3);
end {Off_FE};


procedure Trp_FF;
begin
  Dec (pc);
  Push (@ss, Hi (pc));
  Push (@ss, Lo (pc));
  pc := $0022;
  opindex := 0;		{ prevents subsequent PC alignment }
  Inc (cycles, 9);
end {Trp_FF};


end.
