{ common stuff, CPU registers, memory, gate array  }

unit Def;

interface

  type
    ptrb = ^byte;		{ unsigned 8-bit }
    ptrw = ^word;		{ unsigned 16-bit }
    nibble = byte;		{ it should be ensured that any returned or
				  stored data of this type have upper four
				  bits cleared }

    mem_properties = record
      storage: PChar;
      first: integer;
      last: integer;
      memorg: integer; { 0 if 8-bit memory access, 1 if 16-bit memory access }
      writable: boolean;
      required: boolean;
      filename: string[12];	{ name of associated file }
    end;

  const

  PLATFORM_ID = 'PB-2000C';
  VERSION_STR = 'V16-WO';

{ status bits of the Flag Register F }
    Z_bit	= $80;
    C_bit	= $40;
    LZ_bit	= $20;
    UZ_bit	= $10;
    SW_bit	= $08;
    APO_bit	= $04;

    MEMORIES = 7;	{ number of entries in the memdef table }

{ indexes to the memdef table }
    ROM0 = 0;
    GATEARRAY = 1;
    ROM1 = 2;
    RAM0 = 3;
    RAM1 = 4;
    ROM2 = 5;
    ROM3 = 6;

    INTVECTORS = 5;

{ interrupt bits }
    INT1_bit            = $10;
    KEYPULSE_bit        = $08;
    INT2_bit            = $04;
    MINTIMER_bit        = $02;
    ONINT_bit           = $01;

    intmask: array[0..INTVECTORS-1] of byte = (
      INT1_bit, KEYPULSE_bit, INT2_bit, MINTIMER_bit, ONINT_bit );

{ iterrupt vectors corresponding to the bits 7..3 of the ie/ifl register }
    intvec: array[0..INTVECTORS-1] of word = (
	$0072,		{ INT1 }
	$0062,		{ KEY/Pulse }
	$0052,		{ INT2 }
	$0042,		{ One-minute timer }
	$0032) ;	{ ON }

{ bits of the port PD }
    PD_RES	= $20;	{ 1=reset, 0=normal_operation }
    PD_PWR	= $10;	{ power control: 1=power_off, 0=power_on }
    PD_STR	= $08;	{ transfer direction strobe: 1=write, 0=read }
    PD_ACK	= $04;	{ transfer direction acknowledge }

{ bits of the LCD control port }
    VDD2_bit	= $80;
    CLK_bit	= $40;
    CE2_bit	= $04;
    CE1_bit	= $02;
    OP_bit	= $01;
    LCDCE	= (CE1_bit or CE2_bit);

{ bits of the serial port status register &H0C00}
    RS_TXFULL   = $01;
    RS_RXFULL   = $02;
    RS_CTS      = $04;
    RS_DSR      = $08;
    RS_DCD      = $10;
    RS_RXERR    = $20;

{ bits of the serial port status register &H0C01}
    RS_PARERR   = $01;
    RS_FRMERR   = $02;

{ bits of the serial port status register &H0C02}
    RS_RXFULLINT = $01;

{ 'Option Code' = identification of a connected peripheral interface }
    OC_NONE     = $FF;
    OC_FA7      = $00;
    OC_MD100    = $55;

{ free adress space, number of bytes determined by the function FetchOpcode }
    dummysrc: array[0..3] of byte = ( $FF, $FF, $FF, $FF );

{ key code of first letter from list below }
    LFIRSTCODE = 4;
{ characters which can be entered from keyboard as is }
    Letters: string[71] =
	#09'''()[]|aaaaaQWERTYUIOP=ASDFGHJKL;:ZXCVBNM,aa aaaaaaaaaaa/789*456-123+0.';
{ characters which require the [s] key (overlaid onto the above) }
    ShiftLetters: string[71] =
  	   'a!"#$%&aaaaa?@\_`{}~<>^aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
{ TODO: characters which will trigger a Caps switch when entered with Shift }
    CapsLetters: string[71] =
	   'aaaaaaaaaaaaQWERTYUIOPaASDFGHJKLaaZXCVBNMaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  var
    memdef: array[0..MEMORIES-1] of mem_properties = (
      (	storage:	nil;
	first:		$00000;
	last:		$00C00;
	memorg:		1;
	writable:	False;
        required:	True;
	filename:	'rom0.bin' ),
      (	storage:	nil;
	first:		$00C10;
	last:		$00C12;
	memorg:		0;
	writable:	True;
	required:	False;
	filename:	'' ),
      (	storage:	nil;
	first:		$00000;
	last:		$10000;
	memorg:		0;
	writable:	False;
	required:	False;
	filename:	'rom1.bin' ),
      (	storage:	nil;
	first:		$10000;
	last:		$20000;
	memorg:		0;
	writable:	True;
        required:	False;
	filename:	'ram0.bin' ),
      (	storage:	nil;
	first:		$28000;
	last:		$30000;
	memorg:		0;
	writable:	True;
        required:	False;
	filename:	'ram1.bin' ),
{ unaccessible virtual address ranges assigned to ROM2 and ROM3 }
      (	storage:	nil;
	first:		$70000;		{ required A17=1, A16=1 }
	last:		$80000;
	memorg:		0;
	writable:	False;
	required:	False;
	filename:	'rom2.bin' ),
      (	storage:	nil;
	first:		$B0000;		{ required A17=1, A16=1 }
	last:		$C0000;
	memorg:		0;
	writable:	False;
	required:	False;
	filename:	'rom3.bin' )
    );

{ 5-bit registers }
    sx, sy, sz: byte;

{ 8-bit registers, PD and PE are in the Port unit }
    mr: array[0..35] of byte;	{ main register file + saved/loaded SSP, USP }
    ib: byte;
    ua: byte;
    ia: byte;
    ie: byte;
    tm: byte;
    flag: byte;

{ 16-bit registers }
    ix, iy, iz: word;
    us: word;
    ss: word;
    pc: word;
    ky: word;			{ IRQ1/IRQ2 interrupts can be triggered by
				  changing the bits 11/10 of the KY register }

    iserv: byte;		{ interrupt service flags }
    delayed_ua: byte;		{ copy of the UA register, delayed by one
				  instruction cycle }
    delayed_ky: word;		{ copy of the KY register, delayed by one
				  instruction cycle }

    dummydst: byte;		{ free address space }
    opforg: integer;		{ opcode fetch memory access mode }
    opcode: array[0..3] of byte;
    opindex: integer;		{ index to the opcode table }
    cycles: integer;		{ counter of the clock pulses }
    acycles: integer;		{ clock pulse counter accumulator }
    speed: integer;		{ 0 for fast mode, 4 for slow mode }
    procptr: pointer;		{ pointer to a procedure that should be
				  executed after a machine code instruction,
				  usually to complete an I/O register write
				  cycle }
    OscFreq: integer;		{ CPU clock frequency in kHz }
    CpuStop: boolean;		{ True stops the CPU, used in the debug mode }
    CpuDelay: integer;		{ delay after hiding the Debug Window,
				  prevents the program from crashing when the
				  Debug Window was made visible too early }
    CpuSleep : boolean;		{ True if the CPU in the power-off state, can
				  be waken up by an interrupt }
    CpuSteps: integer;		{ ignored when < 0 }
    BreakPoint: integer;	{ ignored when < 0 }


  function Addr18 (segment: byte; offset: word) : integer;
  function SrcPtr (address: integer) : ptrb;
  function DstPtr (address: integer) : ptrb;
  function FetchByte: byte;
  function FetchOpcode: byte;
  function FindMem (address: integer) : integer;
  function FirstAddr (mem_area: integer) : integer;
  function LastAddr (mem_area: integer) : integer;


implementation

uses Port;


{ converts the bank + 16-bit address to the 18-bit address }
function Addr18 (segment: byte; offset: word) : integer;
begin
  if offset < ((ib shl 8) and $C000) then
    segment := 0;		{ UA invalid, bank 0 selected }
  Addr18 := integer(cardinal(offset) + (cardinal(segment and 3) shl 16));
end {Addr18};


{ modifies the address depending on the Gate Array registers to select
 between ROM1, ROM2 and ROM3 }
function SelectRom (address: integer) : integer;
var
  m: byte;
  ga_reg: word;
begin
  SelectRom := address;
  if address >= $00C12 then
  begin
    m := byte(1) shl (cardinal(address) shr 15);
    ga_reg := ptrw(memdef[GATEARRAY].storage)^;
    if (Lo(ga_reg) and m) <> 0 then		{ Gate Array register $0C10 }
      SelectRom := address or $70000		{ ROM2 selected }
    else if (Hi(ga_reg) and m) <> 0 then	{ Gate Array register $0C11 }
      SelectRom := address or $B0000		{ ROM3 selected }
  end {if};
end {SelectRom};


var srcorg: integer;

{ returns pointer to a read-type resource at specified 18-bit address,
  returns memory access mode for this address in the srcorg variable }
function SrcPtr (address: integer) : ptrb;
var
  i: integer;
begin
  address := SelectRom (address);
  if (address and $FFFF0) = $00C00 then
    SrcPtr := IoRdPtr (address and 7)
  else
  begin
    for i:=0 to MEMORIES-1 do
    begin
      with memdef[i] do
      begin
        if (address >= first) and (address < last) then
        begin
          SrcPtr := ptrb(storage + ((address - first) shl memorg));
          srcorg := memorg;
          exit;
        end {if};
      end {with};
    end {for};
    SrcPtr := ptrb(@dummysrc);
  end {if};
  srcorg := 0;
end {SrcPtr};


{ returns pointer to a write-type resource at specified 18-bit address }
function DstPtr (address: integer) : ptrb;
var
  i: integer;
begin
  if (address and $FFFF0) = $00C00 then
    DstPtr := IoWrPtr (address and 7)
  else
  begin
    for i:=0 to MEMORIES-1 do
    begin
      with memdef[i] do
      begin
        if writable and (address >= first) and (address < last) then
        begin
          DstPtr := ptrb(storage + ((address - first) shl memorg));
          exit;
        end {if};
      end {with};
    end {for};
    DstPtr := ptrb(@dummydst);
  end {if};
end {DstPtr};


function FetchByte: byte;
begin
  FetchByte := opcode[opindex];
  if (opforg = 0) then
  begin
    Inc (pc);
    Inc (cycles, 3);
  end
  else if Odd(opindex) then Inc (pc)
  else Inc (cycles, 4);
  Inc (opindex);
end {FetchByte};


function FetchOpcode: byte;
var
  ua1: word;
begin
  if iserv = 0 then ua1 := delayed_ua else ua1 := 0;
  delayed_ua := ua;
  opcode[0] := SrcPtr(Addr18 (ua1, pc))^;
  opforg := srcorg;
  if srcorg = 0 then
  begin
    opcode[1] := SrcPtr(Addr18 (ua1, pc+1))^;
    opcode[2] := SrcPtr(Addr18 (ua1, pc+2))^;
    opcode[3] := SrcPtr(Addr18 (ua1, pc+3))^;
  end
  else
  begin
    ptrw(@opcode[0])^ := ptrw(SrcPtr(Addr18 (ua1, pc)))^;
    ptrw(@opcode[2])^ := ptrw(SrcPtr(Addr18 (ua1, pc+1)))^;
  end {if};
  opindex := 0;
  FetchOpcode := FetchByte;
end {FetchOpcode};


{ Functions used by the debugger }

{ locates the memory area in the memdef table matching the specified 18-bit
 address, or -1 if not found }
function FindMem (address: integer) : integer;
begin
  result := -1;
{ exclude the gate array and peripheral device address range }
  if (address >= $00C00) and (address < $00C12) then Exit;
{ scan remaining areas except the virtual ones }
  for result:=0 to RAM1 do
  begin
    with memdef[result] do
    begin
      if (address >= first) and (address < last) then Exit;
    end {with};
  end {for};
{ not found }
  result := -1;
end {FindMem};


{ lowest address in a memory area }
function FirstAddr (mem_area: integer) : integer;
begin
  if mem_area = ROM1 then
    FirstAddr := $00C12
  else
    FirstAddr := memdef[mem_area].first;
end {FirstAddr};


{ highest address in a memory area }
function LastAddr (mem_area: integer) : integer;
begin
  LastAddr := memdef[mem_area].last;
end {LastAddr};


end.
