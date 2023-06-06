unit Debug;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Buttons;

type
  TDebugForm = class(TForm)
    ListGroupBox: TGroupBox;
    ListPaintBox: TPaintBox;
    ListScrollBar: TScrollBar;
    ListEdit: TEdit;

    RegGroupBox: TGroupBox;
    RegPaintBox: TPaintBox;
    RegScrollBar: TScrollBar;
    RegEdit: TEdit;

    MainGroupBox: TGroupBox;
    MainPaintBox: TPaintBox;
    MainScrollBar: TScrollBar;
    MainEdit: TEdit;

    BinGroupBox: TGroupBox;
    BinPaintBox: TPaintBox;
    BinScrollBar: TScrollBar;
    BinEdit: TEdit;

    StepGroupBox: TGroupBox;
    StepButton: TButton;

    TraceGroupBox: TGroupBox;
    TraceEdit: TEdit;
    TraceButton: TButton;

    BpGroupBox: TGroupBox;
    BpEdit: TEdit;
    BpButton: TButton;

{ DISASSEMBLY BOX EVENTS }
    procedure ListBoxScroll(Sender: TObject;
      ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure ListGroupBoxClick(Sender: TObject);
    procedure ListPaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListEditChange(Sender: TObject);
    procedure ListPaintBoxPaint(Sender: TObject);

{ REGISTER BOX EVENTS }
    procedure RegBoxScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure RegGroupBoxClick(Sender: TObject);
    procedure RegPaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RegEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure RegEditChange(Sender: TObject);
    procedure RegPaintBoxPaint(Sender: TObject);

{ MAIN REGISTER BOX EVENTS }
    procedure MainBoxScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure MainGroupBoxClick(Sender: TObject);
    procedure MainPaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MainEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MainEditChange(Sender: TObject);
    procedure MainPaintBoxPaint(Sender: TObject);

{ BINARY EDITOR BOX EVENTS }
    procedure BinBoxScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure BinGroupBoxClick(Sender: TObject);
    procedure BinPaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BinEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BinEditChange(Sender: TObject);
    procedure BinPaintBoxPaint(Sender: TObject);

{ GENERAL FORM EVENTS }
    procedure DebugCreate(Sender: TObject);
    procedure DebugShow(Sender: TObject);
    procedure DebugHide(Sender: TObject);

{ MACHINE CODE EXECUTION CONTROL EVENTS }
    procedure StepGroupBoxClick(Sender: TObject);
    procedure StepButtonClick(Sender: TObject);
    procedure TraceGroupBoxClick(Sender: TObject);
    procedure TraceButtonClick(Sender: TObject);
    procedure TraceEditChange(Sender: TObject);
    procedure BpGroupBoxClick(Sender: TObject);
    procedure BpButtonClick(Sender: TObject);
    procedure BpEditChange(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;


var
  DebugForm: TDebugForm;


implementation

{$R *.dfm}

uses
  Def, Dis, Asem, Cpu;

const
  SELECTED = clBlue;

var
  ListAddr: integer;
  ListMem: integer;	{selected memory}
  RegAddr: integer;
  MainAddr: integer;
  BinAddr: integer;
  BinMem: integer;	{selected memory}

  EditState: (NoEditSt, ListAddrEditSt, ListInstrEditSt, RegEditSt,
	FlagEditSt, MainEditSt, BinAddrEditSt, BinDataEditSt,
	BinCharEditSt);
  EditAddr: integer;	{address of edited object - memory location, register}


{ set the font color of all TGrupBox controls to default }
procedure Unselect;
begin
  with DebugForm do
  begin
    ListGroupBox.Font.Color := clWindowText;
    RegGroupBox.Font.Color := clWindowText;
    MainGroupBox.Font.Color := clWindowText;
    BinGroupBox.Font.Color := clWindowText;
    StepGroupBox.Font.Color := clWindowText;
    TraceGroupBox.Font.Color := clWindowText;
    BpGroupBox.Font.Color := clWindowText;
  end {with};
end {Unselect};


procedure BoxEdit (box: TPaintBox; ed: TEdit; Col, Row, W: integer);
var
  cx, cy, L, T: integer;
begin
  with box do
  begin
    cx := Canvas.TextWidth('0');
    cy := Canvas.TextHeight('0');
    L := Left;
    T := Top;
  end {with};
  with ed do
  begin
    Left := L + Col * cx;
    Top := T + Row * cy;
    Width := cx * W;
    Height := cy;
    MaxLength := W;
    Text := '';
  end {with};
end {BoxEdit};


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


{ remove digits out of specified range from the edited string }
procedure CheckEdit (ed: TEdit; limit: integer);
var
  i, x, y: integer;
  s: string;
begin
  with ed do
  begin
    if Modified then
    begin
      s := Text;
      x := SelStart;
      y := SelLength;
      i := 1;
      while i <= Length(s) do
      begin
        if GetDigit(s[i]) >= limit then
        begin
          Delete (s, i, 1);
          if x >= i then Dec(x) else if x+y >= i then Dec(y);
        end
        else
        begin
          Inc (i);
        end {if};
      end {while};
      Text := s;
      SelStart := x;
      SelLength := y;
    end {if};
  end {with};
end {CheckEdit};


procedure CloseEdit;
begin
  EditState := NoEditSt;
  with DebugForm do
  begin
    with ListEdit do
    begin
      Text := '';
      Width := 0;
      Left := 0;
      Top := 0;
    end {with};
    with RegEdit do
    begin
      Text := '';
      Width := 0;
      Left := 0;
      Top := 0;
    end {with};
    with MainEdit do
    begin
      Text := '';
      Width := 0;
      Left := 0;
      Top := 0;
    end {with};
    with BinEdit do
    begin
      Text := '';
      Width := 0;
      Left := 0;
      Top := 0;
    end {with};
    ListPaintBox.Invalidate;
    RegPaintBox.Invalidate;
    MainPaintBox.Invalidate;
    BinPaintBox.Invalidate;
  end {with};
end {CloseEdit};


{ scrolling with the arrow keys,
  returns new value for Position or -1 when Position hasn't changed }
function ArrowKeys (Key: word; sb: TScrollBar) : integer;
begin
  with sb do
  begin
    Result := Position;
    case Key of
      VK_HOME:	Result := Min;
      VK_PRIOR:	Dec (Result, LargeChange);
      VK_UP:	Dec (Result, SmallChange);
      VK_DOWN:	Inc (Result, SmallChange);
      VK_NEXT:	Inc (Result, LargeChange);
      VK_END:	Result := Max;
    end {case};
    if Result < Min then Result := Min
    else if Result > Max then Result := Max;
    if Result = Position then Result := -1;
  end {with};
end;



{ DISASSEMBLY BOX EVENTS }

{ expects the new disassembly address, sets new values of ListAddr, ListMem }
procedure SetListMem (a18: integer);
begin
  ListMem := FindMem (a18);
  ListAddr := a18;
  if ListMem < 0 then
{ out of allowed address space, select ROM0 }
  begin
    ListMem := ROM0;
    ListAddr := FirstAddr (ListMem);
  end {if};
end {SetListMem};


procedure TDebugForm.ListGroupBoxClick(Sender: TObject);
begin
  ListEdit.SetFocus;
  Unselect;
  ListGroupBox.Font.Color := SELECTED;
  CloseEdit;
end;


procedure TDebugForm.ListBoxScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  ListAddr := ScrollPos + FirstAddr (ListMem);
  ListEdit.SetFocus;
  Unselect;
  ListGroupBox.Font.Color := SELECTED;
  CloseEdit;
end;


procedure TDebugForm.ListPaintBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Col, Row, cols, rows, i, w: integer;
  savepc, saveua, savedel: word;
  cx, cy: integer;	{ font size in pixels }
begin
  ListEdit.SetFocus;
  Unselect;
  ListGroupBox.Font.Color := SELECTED;
  CloseEdit;
  EditAddr := ListAddr;
  with ListPaintBox do
  begin
    cx := Canvas.TextWidth ('0');
    cy := Canvas.TextHeight ('0');
    cols := Width div cx;
    rows := Height div cy;
    Col := X div cx;
    Row := Y div cy;
  end {with};
  if Row >= rows then Exit;
  if (Col < 5) and (Row = 0) then
  begin
    EditState := ListAddrEditSt;
    Col := 0;
    w := 5;
    ListEdit.CharCase := ecUpperCase;
  end
  else if (Col >= 7) and (Col < cols) then
  begin
    EditState := ListInstrEditSt;
    savepc := pc;
    saveua := ua;
    savedel := delayed_ua;
    ua := word(ListAddr shr 16);
    delayed_ua := ua;
    i := 0;
    while i < Row do
    begin
      if (EditAddr >= LastAddr (ListMem)) or
	(EditAddr < FirstAddr (ListMem))	{ when pc wraps around }
	then break;
      pc := word(EditAddr);
{ move the 'pc' to the next instruction, i.e. disassemble a single
  instruction without generating any output }
      Arguments (ScanMnemTab);
      EditAddr := Addr18 (ListAddr shr 16, pc);
      Inc (i);
    end {while};
    pc := savepc;
    ua := saveua;
    delayed_ua := savedel;
    if i < Row then Exit;
    Col := 7;
    w := cols - 7;
    ListEdit.CharCase := ecNormal;
  end
  else
  begin
    Exit;
  end {if};
  BoxEdit (ListPaintBox, ListEdit, Col, Row, w);
end;


procedure TDebugForm.ListEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i, a, valcode: integer;
  savepc, saveua, savedel: word;
begin
  i := ArrowKeys (Key, ListScrollBar);
  if (i >= 0) and (EditState = NoEditSt) then
  begin
    ListAddr := i + FirstAddr (ListMem);
    ListPaintBox.Invalidate;
  end

  else if Key = VK_RETURN then
  begin
    if EditState = ListAddrEditSt then
    begin
      Val ('$0'+Trim(ListEdit.Text), a, valcode);
      SetListMem (a);
      CloseEdit;
    end
    else if EditState = ListInstrEditSt then
    begin
{ determine the memory access mode in the 'opforg' variable }
      savepc := pc;
      saveua := ua;
      savedel := delayed_ua;
      pc := word(ListAddr);
      ua := word(ListAddr shr 16);
      delayed_ua := ua;
      FetchOpcode;
      pc := savepc;
      ua := saveua;
      delayed_ua := savedel;
{ assemble the instruction }
      loc := word(EditAddr);
      wmd := opforg;
      InBuf := ListEdit.Text;
      Assemble;
{ when succeeded, copy the assembler output to the memory }
      if InIndex = 0 then
      begin
        i := 0;
        while i < OutIndex do
        begin
          if opforg = 0 then
          begin
            ptrb(SrcPtr(EditAddr + i))^ := OutBuf[i];
            Inc (i);
          end
          else
          begin
            ptrw(SrcPtr(EditAddr + i div 2))^ := ptrw(@OutBuf[i])^;
            Inc (i,2);
          end {if};
        end {while};
        dummysrc[0] := $FF;
        dummysrc[1] := $FF;
        CloseEdit;
      end
{ when failed, position the cursor just before the first offending character }
      else
      begin
        ListEdit.SelStart := InIndex-1;
      end {if};
    end {if};
  end

  else if key = VK_ESCAPE then CloseEdit;
end;


procedure TDebugForm.ListEditChange(Sender: TObject);
begin
  if EditState = ListAddrEditSt then CheckEdit (ListEdit, 16);
end;


procedure TDebugForm.ListPaintBoxPaint(Sender: TObject);
var
  i, rows: integer;
  a: integer;
  savepc, saveua, savedel, index: word;
  cx, cy: integer;	{ font size in pixels }
begin
  savepc := pc;
  saveua := ua;
  savedel := delayed_ua;
  a := ListAddr;
  ua := word(ListAddr shr 16);
  delayed_ua := ua;
  with ListPaintBox do
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Color;
    cx := Canvas.TextWidth ('0');
    cy := Canvas.TextHeight ('0');
    rows := Height div cy;
  end {with};
  with ListPaintBox.Canvas do
  begin
    for i := 0 to rows-1 do
    begin
      if (a >= LastAddr (ListMem)) or
	(a < FirstAddr (ListMem))	{ when pc wraps around }
	then break;
      TextOut (0, i*cy, IntToHex(a, 5) + ':');
      pc := word(a);
      index := ScanMnemTab;
      TextOut (7*cx, i*cy, Mnemonic (index));
      TextOut (13*cx, i*cy, Arguments (index));
      a := Addr18 (ListAddr shr 16, pc);
    end {for};
  end {with};
  pc := savepc;
  ua := saveua;
  delayed_ua := savedel;
{ set the scroll bar }
  with ListScrollBar do
  begin
    SetParams (ListAddr - FirstAddr (ListMem), 0, LastAddr (ListMem) -
	FirstAddr (ListMem) - rows);
    if (a < LastAddr (ListMem)) and
	(a >= FirstAddr (ListMem))	{ when pc wraps around }
	then LargeChange := a - ListAddr;
  end {with};
end;



{ REGISTER BOX EVENTS }

type
  reg_properties = record
    name: string[3];
    ptr: pointer;
    size: integer;
    mask: word;
  end;

  flag_properties = record
    name: array[0..1] of string[3];
    column: integer;
    mask: byte;
  end;

const
  REGROWS = 13;
  regset: array[0..REGROWS-1] of reg_properties = (
    ( name: 'PC:';	ptr: @pc;	size: 4;	mask: $FFFF; ),
    ( name: 'SS:';	ptr: @ss;	size: 4;	mask: $FFFF; ),
    ( name: 'US:';	ptr: @us;	size: 4;	mask: $FFFF; ),
    ( name: 'IX:';	ptr: @ix;	size: 4;	mask: $FFFF; ),
    ( name: 'IY:';	ptr: @iy;	size: 4;	mask: $FFFF; ),
    ( name: 'IZ:';	ptr: @iz;	size: 4;	mask: $FFFF; ),
    ( name: 'SX:';	ptr: @sx;	size: 2;	mask: $001F; ),
    ( name: 'SY:';	ptr: @sy;	size: 2;	mask: $001F; ),
    ( name: 'SZ:';	ptr: @sz;	size: 2;	mask: $001F; ),
    ( name: 'UA:';	ptr: @ua;	size: 2;	mask: $00FF; ),
    ( name: 'IA:';	ptr: @ia;	size: 2;	mask: $00FF; ),
    ( name: 'IB:';	ptr: @ib;	size: 2;	mask: $00FF; ),
    ( name: 'IE:';	ptr: @ie;	size: 2;	mask: $00FF; )
  );

  flagset: array[0..3] of flag_properties = (
    ( name: ('Z ', 'NZ');	column: 2;	mask: Z_bit;	),
    ( name: ('NC', 'C ');	column: 4;	mask: C_bit;	),
    ( name: ('LZ ', 'NLZ');	column: 6;	mask: LZ_bit;	),
    ( name: ('UZ ', 'NUZ');	column: 9;	mask: UZ_bit;	)
  );


procedure TDebugForm.RegGroupBoxClick(Sender: TObject);
begin
  RegEdit.SetFocus;
  Unselect;
  RegGroupBox.Font.Color := SELECTED;
  CloseEdit;
end;


procedure TDebugForm.RegBoxScroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
begin
  RegAddr := ScrollPos;
  RegEdit.SetFocus;
  Unselect;
  RegGroupBox.Font.Color := SELECTED;
  CloseEdit;
end;


procedure TDebugForm.RegPaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Col, Row, rows, w: integer;
  cx, cy: integer;	{ font size in pixels }
begin
  RegEdit.SetFocus;
  Unselect;
  RegGroupBox.Font.Color := SELECTED;
  CloseEdit;
  with RegPaintBox do
  begin
    cx := Canvas.TextWidth ('0');
    cy := Canvas.TextHeight ('0');
    rows := Height div cy;
    Col := X div cx;
    Row := Y div cy;
  end {with};
  if rows > REGROWS+1 then rows := REGROWS+1;
  if (Row > 0) and (Row < rows) and (Col >= 4) then
{ registers other than Flags }
  begin
    EditAddr := Row + RegAddr - 1;
    w := regset[EditAddr].size;
    if Col >= 4+w then Exit;
    EditState := RegEditSt;
    BoxEdit (RegPaintBox, RegEdit, 4, Row, w);
  end
  else if (Row = 0) and (Col >= 2) and (Col < 12) then
{ Flags register }
  begin
    EditState := FlagEditSt;
    EditAddr := 0;
    while (EditAddr < 3) and (Col >= flagset[EditAddr+1].column) do
      Inc (EditAddr);
    flag := flag xor flagset[EditAddr].mask;
    RegPaintBox.Invalidate;
  end {if};
end;


procedure TDebugForm.RegEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i, x, valcode: integer;
begin
  i := ArrowKeys (Key, RegScrollBar);
  if (i >= 0) and (EditState = NoEditSt) then
  begin
    RegAddr := i;
    RegPaintBox.Invalidate;
  end

  else if Key = VK_RETURN then
  begin
    if EditState = RegEditSt then
    begin
      Val ('$0'+Trim(RegEdit.Text), x, valcode);
      with regset[EditAddr] do
      begin
        x := x and integer(mask);
        if size > 2 then ptrw(ptr)^ := word(x) else ptrb(ptr)^ := byte(x);
        if ptr = @ua then delayed_ua := ua;
      end {with};
      CloseEdit;
    end {if};
  end

  else if Key = VK_ESCAPE then CloseEdit;
end;


procedure TDebugForm.RegEditChange(Sender: TObject);
begin
  CheckEdit (RegEdit, 16);
end;


procedure TDebugForm.RegPaintBoxPaint(Sender: TObject);
var
  i, rows: integer;
  x: word;
  cx, cy: integer;	{ font size in pixels }
begin
  with RegPaintBox do
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Color;
    cx := Canvas.TextWidth ('0');
    cy := Canvas.TextHeight ('0');
    rows := Height div cy;
  end {with};
  if rows > REGROWS+1 then rows := REGROWS+1;
  with RegPaintBox.Canvas do
  begin
{ scrollable registers }
    for i := 0 to rows-2 do
    begin
      with regset[i+RegAddr] do
      begin
        TextOut (0, (i+1)*cy, name);
        if size > 2 then x := ptrw(ptr)^ else x := word(ptrb(ptr)^);
        TextOut (4*cx, (i+1)*cy, IntToHex(x and mask, size));
      end {with};
    end {for};
{ unscrollable Flags register }
    TextOut (0, 0, 'F:');
    for i := 0 to 3 do
    begin
      if Odd (i) then Brush.Color := clLtGray else Brush.Color := clWhite;
      with flagset[i] do
      begin
        if (flag and mask) = 0 then x := 0 else x := 1;
        TextOut (column*cx, 0, name[x]);
      end {with};
    end {for};
  end {with};
{ set the scroll bar }
  with RegScrollBar do
  begin
    SetParams (RegAddr, 0, REGROWS+1-rows);
    LargeChange := rows-1;
  end {with};
end;



{ MAIN REGISTER BOX EVENTS }

const
  MAINROWS = 2;
  mrnames: array[0..MAINROWS-1] of string[9] = ('$00..$15:', '$16..$31:');


procedure TDebugForm.MainGroupBoxClick(Sender: TObject);
begin
  MainEdit.SetFocus;
  Unselect;
  MainGroupBox.Font.Color := SELECTED;
  CloseEdit;
end;


procedure TDebugForm.MainBoxScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  MainAddr := ScrollPos*16;
  MainEdit.SetFocus;
  Unselect;
  MainGroupBox.Font.Color := SELECTED;
  CloseEdit;
end;


procedure TDebugForm.MainPaintBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Col, Row, rows: integer;
  cx, cy: integer;	{ font size in pixels }
begin
  MainEdit.SetFocus;
  Unselect;
  MainGroupBox.Font.Color := SELECTED;
  CloseEdit;
  with MainPaintBox do
  begin
    cx := Canvas.TextWidth ('0');
    cy := Canvas.TextHeight ('0');
    rows := Height div cy;
    Col := X div cx;
    Row := Y div cy;
  end {with};
  Dec (Col, 10);
  if (Row >= 0) and (Row < rows) and (Col >= 0) and (Col < 51) and
	((Col mod 13) < 11) and (((Col mod 13) mod 3) < 2) then
  begin
    EditState := MainEditSt;
    Col := (Col - Col div 13) div 3;
    EditAddr := MainAddr + 16*Row + Col;
    Col := 3*Col + Col div 4 + 10;
    BoxEdit (MainPaintBox, MainEdit, Col, Row, 2);
  end {if};
end;


procedure TDebugForm.MainEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i, x, valcode: integer;
begin
  i := ArrowKeys (Key, MainScrollBar);
  if (i >= 0) and (EditState = NoEditSt) then
  begin
    MainAddr := 16*i;
    MainPaintBox.Invalidate;
  end

  else if Key = VK_RETURN then
  begin
    if EditState = MainEditSt then
    begin
      Val ('$0'+Trim(MainEdit.Text), x, valcode);
      mr[EditAddr] := byte(x);
      CloseEdit;
    end {if};
  end

  else if Key = VK_ESCAPE then CloseEdit;
end;


procedure TDebugForm.MainEditChange(Sender: TObject);
begin
  CheckEdit (MainEdit, 16);
end;


procedure TDebugForm.MainPaintBoxPaint(Sender: TObject);
var
  i, j, rows, Col: integer;
  cx, cy: integer;	{ font size in pixels }
begin
  with MainPaintBox do
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Color;
    cx := Canvas.TextWidth ('0');
    cy := Canvas.TextHeight ('0');
    rows := Height div cy;
  end {with};
  if rows > MAINROWS then rows := MAINROWS;
  with MainPaintBox.Canvas do
  begin
    for j := 0 to rows-1 do
    begin
      TextOut (0, j*cy, mrnames[MainAddr div 16 + j]);
      for i := 0 to 15 do
      begin
        Col := 3*i + i div 4 + 10;
        TextOut (Col*cx, j*cy, IntToHex(mr[MainAddr+16*j+i], 2));
      end {for i};
    end {for j};
  end {with};
{ set the scroll bar }
  with MainScrollBar do
  begin
    SetParams (MainAddr div 16, 0, MAINROWS-rows);
    LargeChange := rows;
  end {with};
end;



{ BINARY EDITOR BOX EVENTS }

{ expects the memory address, sets new values of BinAddr, BinMem }
procedure SetBinMem (a18: integer);
begin
  BinMem := FindMem (a18);
  BinAddr := a18 and $3FFF0;
  if (BinMem < 0) or not memdef[BinMem].writable then
{ out of allowed address space, select RAM0 }
  begin
    BinMem := RAM0;
    BinAddr := FirstAddr (BinMem);
  end {if};
end {SetBinMem};


procedure TDebugForm.BinGroupBoxClick(Sender: TObject);
begin
  BinEdit.SetFocus;
  Unselect;
  BinGroupBox.Font.Color := SELECTED;
  CloseEdit;
end;


procedure TDebugForm.BinBoxScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  BinAddr := ScrollPos*16 + FirstAddr (BinMem);
  BinEdit.SetFocus;
  Unselect;
  BinGroupBox.Font.Color := SELECTED;
  CloseEdit;
end;


procedure TDebugForm.BinPaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Col, Row, rows, w: integer;
  cx, cy: integer;	{ font size in pixels }
begin
  BinEdit.SetFocus;
  Unselect;
  BinGroupBox.Font.Color := SELECTED;
  CloseEdit;
  with BinPaintBox do
  begin
    cx := Canvas.TextWidth ('0');
    cy := Canvas.TextHeight ('0');
    rows := Height div cy;
    Col := X div cx;
    Row := Y div cy;
  end {with};
  if Row >= rows then Exit;
  if (Row = 0) and (Col < 5) then
  begin				{select BinAddr edition}
    EditState := BinAddrEditSt;
    EditAddr := 0;
    Col := 0;
    w := 5;
    BinEdit.CharCase := ecUpperCase;
  end
  else if (Col >= 7) and (Col < 55) and (((Col-7) mod 3) < 2) then
  begin				{select byte edition in the BinBox}
    Col := (Col-7) div 3;
    EditAddr := BinAddr + 16*Row + Col;
    if EditAddr >= LastAddr (BinMem) then Exit;
    Col := Col*3 + 7;
    EditState := BinDataEditSt;
    w := 2;
    BinEdit.CharCase := ecUpperCase;
  end
  else if (Col >= 55) and (Col < 71) then
  begin				{select character edition in the BinBox}
    EditAddr := BinAddr + 16*Row + Col - 55;
    if EditAddr >= LastAddr (BinMem) then Exit;
    EditState := BinCharEditSt;
    w := 1;
    BinEdit.CharCase := ecNormal;
  end
  else
  begin
    Exit;
  end {if};
  BoxEdit (BinPaintBox, BinEdit, Col, Row, w);
end;


procedure TDebugForm.BinEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i, x, valcode: integer;
begin
  i := ArrowKeys (Key, BinScrollBar);
  if (i >= 0) and (EditState = NoEditSt) then
  begin
    BinAddr := 16*i + FirstAddr (BinMem);
    BinPaintBox.Invalidate;
  end

  else if Key = VK_RETURN then
  begin
    if EditState = BinAddrEditSt then
    begin
      Val('$0'+Trim(BinEdit.Text), x, valcode);
      SetBinMem (x);
      CloseEdit;
    end
    else if EditState = BinDataEditSt then
    begin
      Val ('$0'+Trim(BinEdit.Text), x, valcode);
      DstPtr(EditAddr)^ := byte(x);
      CloseEdit;
    end
    else if EditState = BinCharEditSt then
    begin
      DstPtr(EditAddr)^ := byte(Ord(BinEdit.Text[1]));
      CloseEdit;
    end {if};
  end

  else if Key = VK_ESCAPE then CloseEdit;
end;


procedure TDebugForm.BinEditChange(Sender: TObject);
begin
  if (EditState = BinAddrEditSt) or (EditState = BinDataEditSt) then
    CheckEdit (BinEdit, 16);
end;


procedure TDebugForm.BinPaintBoxPaint(Sender: TObject);
var
  i, j, rows: integer;
  a: integer;
  x: byte;
  cx, cy: integer;	{ font size in pixels }
begin
  a := BinAddr;
  with BinPaintBox do
  begin

    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Color;
    cx := Canvas.TextWidth ('0');
    cy := Canvas.TextHeight ('0');
    rows := Height div cy;
  end {with};
  with BinPaintBox.Canvas do
  begin
    for i := 0 to rows-1 do
    begin
      if a >= LastAddr (BinMem) then break;
{ address }
      TextOut (0, i*cy, IntToHex(a, 5) + ':');
{ bytes }
      for j := 0 to 15 do
      begin
        TextOut ((7+3*j)*cx, i*cy, IntToHex(SrcPtr(a+j)^, 2));
      end {for};
{ characters }
      for j := 0 to 15 do
      begin
        x := SrcPtr(a+j)^;
        if (x < $20) or (x > $7E) then x := byte(Ord('.'));
        TextOut ((55+j)*cx, i*cy, Chr(x));
      end {for};
      Inc (a, 16);
    end {for};
  end {with};
{ set the scroll bar }
  with BinScrollBar do
  begin
    SetParams ((BinAddr - FirstAddr (BinMem)) div 16, 0,
	(LastAddr (BinMem) - FirstAddr (BinMem)) div 16 - rows);
    LargeChange := rows;
  end {with};
end;



{ MACHINE CODE EXECUTION CONTROL }

procedure TDebugForm.StepGroupBoxClick(Sender: TObject);
begin
  StepGroupBox.SetFocus;
  Unselect;
  StepGroupBox.Font.Color := SELECTED;
  CloseEdit;
end;


procedure TDebugForm.StepButtonClick(Sender: TObject);
begin
  EditState := NoEditSt;
  CpuRun;
  SetListMem (Addr18 (delayed_ua, pc));
  StepGroupBox.SetFocus;
  Unselect;
  StepGroupBox.Font.Color := SELECTED;
  CloseEdit
end;


procedure TDebugForm.TraceGroupBoxClick(Sender: TObject);
begin
  TraceEdit.SetFocus;
  Unselect;
  TraceGroupBox.Font.Color := SELECTED;
  CloseEdit;
end;


procedure TDebugForm.TraceButtonClick(Sender: TObject);
var
  i, valcode: integer;
begin
  with TraceEdit do
  begin
    Val ('0'+Trim(TraceEdit.Text), i, valcode);
    SetFocus;
  end {with};
  Unselect;
  TraceGroupBox.Font.Color := SELECTED;
  CloseEdit;
  if i > 0 then
  begin
    BreakPoint := -1;
    CpuSteps := i;
    Hide;
  end {if};
end;


{ remove digits out of specified range from the edited string }
procedure TDebugForm.TraceEditChange(Sender: TObject);
begin
  CheckEdit (TraceEdit, 10);
end;


procedure TDebugForm.BpGroupBoxClick(Sender: TObject);
begin
  BpEdit.SetFocus;
  Unselect;
  BpGroupBox.Font.Color := SELECTED;
  CloseEdit;
end;


procedure TDebugForm.BpButtonClick(Sender: TObject);
var
  i, valcode: integer;
begin
  with BpEdit do
  begin
    Val ('$0'+Trim(BpEdit.Text), i, valcode);
    SetFocus;
  end {with};
  Unselect;
  BpGroupBox.Font.Color := SELECTED;
  CloseEdit;
  BreakPoint := i;
  CpuSteps := -1;
  Hide;
end;


procedure TDebugForm.BpEditChange(Sender: TObject);
begin
  CheckEdit (BpEdit, 16);
end;



{ GENERAL FORM EVENTS }

procedure TDebugForm.DebugCreate(Sender: TObject);
begin
  CloseEdit;
  RegAddr := 0;
  MainAddr := 0;
  BinMem := RAM0;
  BinAddr := FirstAddr (BinMem);
  ListMem := ROM0;
  ListAddr := FirstAddr (ListMem);
end;


procedure TDebugForm.DebugShow(Sender: TObject);
begin
  CpuStop := True;
  CpuSteps := -1;
  BreakPoint := -1;
  SetListMem (Addr18 (delayed_ua, pc));
  ListEdit.SetFocus;
  Unselect;
  ListGroupBox.Font.Color := SELECTED;
end;


procedure TDebugForm.DebugHide(Sender: TObject);
begin
  CloseEdit;
  Hide;
  CpuDelay := 30;
  CpuStop := False;
end;


end.
