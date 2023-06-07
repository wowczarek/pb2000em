unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IniFiles, ThdTimer, ScktComp;

type
  TMainForm = class(TForm)
    RunTimer: TThreadedTimer;
    RefreshTimer: TTimer;
    SecTimer: TTimer;
    FddSocket: TClientSocket;
    procedure OnRunTimer(Sender: TObject);
    procedure OnRefreshTimer(Sender: TObject);
    procedure OnSecTimer(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormPaint(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure ApplicationDeactivate(Sender: TObject);
  private
        procedure CMDialogKey( Var msg: TCMDialogKey );
        message CM_DIALOGKEY;
    { Private declarations }
  public
        { not serial port as in serial port, but serial port... port. }
        { OK, let's try again: TCP port used for serial communucation }
        SerialPort: Integer;
        { address we listen on for serial connections }
        SerialAddress: String;
        { address we listen on for remote connections }
        RemoteAddress: String;
        { TCP port that the remote control module will listen on }
        RemotePort: Integer;
        { remote key entry interval }
        KeyInterval: Integer;
    { Public declarations }
  end;

var
    MainForm: TMainForm;
    procedure KeyInterrupt;
    function MemSave (fname: string; memory: PChar; fsize: integer) : boolean;
    procedure SaveState(warn: boolean; release: boolean);
    procedure ReleaseKey1 (X, Y: Integer);
    function TogglePower: boolean;
    procedure setpower(p: boolean);
implementation

{$R *.dfm}

uses
    Def, Cpu, Debug, Keyboard, Lcd, Port, Serial, Remote;

const
    FaceName: string = 'face.bmp';
    KeysName: string = 'keys.bmp';
    OverlayName: string = 'overlay.bmp';
    ChrName: string = 'charset.bin';
    IniName: string = 'pb2000c.ini';
    RegName: string = 'register.bin';
    LoadMsg: string = 'Failed to load the file ';
    SaveMsg: string = 'Failed to save the file ';

var
    BitMap, Face, LcdBmp, KeyBmp, OverlayBmp: TBitMap;
    RedrawReq: boolean;		{ true if the LcdBmp image has changed and
				  needs to be redrawn }
{ LCD }
    BkColor: TColor = clWhite;
    ScrMem: array[0..LCDSIZE-1] of nibble; { shadow LCD data memory }
    ScrCtrl: byte;			{ shadow LCD control register }

{ CPU }
    CpuSpeed: integer;		{ how many instructions executes the emulated
				  CPU at each RunTimer event call }
    OnCounter: integer = 0;
    PulseCounter: integer = 0;
    RunTimerFrequency: integer;

{ keyboard }
    keypads1: integer = KEYPADS;
    lastkey1: integer = LASTKEYCODE;

{ Power switch toggle }
function TogglePower: boolean;
begin
        Result := false;
        KeyCode1 := 1;
        flag := flag xor SW_bit;
        ReleaseKey1(-1,-1);
        if (flag and SW_bit) <> 0 then
        begin
                CpuWakeUp (False);
                Result := true;
        end;

end;

procedure SetPower(p: boolean);
var cp: boolean;
begin
        cp := (flag and SW_bit) <> 0;
        if (cp xor p) then TogglePower;

end;

procedure SaveState(warn: boolean; release: boolean);
var
  i, size: integer;
begin
{ save the register file image }
  ptrw(@mr[32])^ := ss;
  ptrw(@mr[34])^ := us;
  if not MemSave (RegName, PChar(@mr[0]), 36) then
  begin
    if warn then MessageDlg (SaveMsg + RegName, mtWarning, [mbOk], 0);
  end {if};
{ save the memory images }
  for i:=0 to MEMORIES-1 do
  begin
    with memdef[i] do
    begin
      size := (last-first) shl memorg;
      if writable and (filename <> '') then
      begin
        if not MemSave (filename, storage, size) then
        begin
          if warn then MessageDlg (SaveMsg + filename, mtWarning, [mbOk], 0);
        end {if};
      end {if};
      if release then
        FreeMem (storage, size);
    end {with};
  end {for};

end;

procedure ResetAll;
begin
  lcdctrl := 0;
  LcdInit;
  pdi := (pdi and $03) or $F8;
  pe := $00;
  IoInit;
  ptrw(memdef[GATEARRAY].storage)^ := 0;
  CpuReset;
end {ResetAll};


{ draws the image of a key from the KeyBmp }
procedure DrawKey (index, x, y: integer; pressed: boolean);
var
  offset: word;
begin
  with keypad[index] do
  begin
    BitMap.Width := W;
    BitMap.Height := H;
    if (pressed) then offset := 0 else offset := W;
    BitMap.Canvas.Draw (-OX - offset, -OY, KeyBmp);
  end {with};
  BitMap.TransparentColor := $00FFFFFF;
  BitMap.Transparent := True;
  Face.Canvas.Draw (x, y, BitMap);
  BitMap.Transparent := False;
  BitMap.Canvas.Draw (-x, -y, Face);
  MainForm.Canvas.Draw (x, y, BitMap);
end {DrawKey};


{ draw the LCD contents }
procedure View;
var
  Bank, Row, Col, Hc, Pixel, Index, X, Y: Integer;
  Data: nibble;
begin
  with LcdBmp.Canvas do
  begin
    Brush.Style := bsSolid;

{ handle the LCD control register }
    if ScrCtrl <> lcdctrl then
    begin
      RedrawReq := True;
      ScrCtrl := lcdctrl;
      if (ScrCtrl and VDD2_bit) <> 0 then
      begin	{turn the display on}
{ it is assummed that the lcdimage is cleared when the LCD is turned off }
        FillChar (ScrMem, LCDSIZE, 0);
        Brush.Color := BkColor;
      end
      else
      begin	{turn the display off}
        Brush.Color := clLtGray;
      end {if};
      FillRect (Rect(0, 0, 384, 64));
    end {if};

{ draw the pixels }
    if (ScrCtrl and VDD2_bit) = 0 then Exit;	{display turned off}
    Index := 0;
    X := 0;
    Y := 0;
    for Bank := 0 to 1 do
    begin
      for Row := 0 to 3 do
      begin
        for Col := 0 to 95 do
        begin
          for Hc := 0 to 1 do
          begin
            Data := lcdimage[Index];
            if ScrMem[Index] <> Data then
            begin
              RedrawReq := True;
              ScrMem[Index] := Data;
              for Pixel := 0 to 3 do
              begin
                if (Data and $8) <> 0 then Brush.Color := clBlack
                                      else Brush.Color := BkColor;
                Data := Data shl 1;
                FillRect (Rect(X, Y, X+2, Y+2));
                Inc (Y, 2);
              end {for Pixel};
            end
            else
            begin
              Inc (Y, 8);
            end {if};
            Inc (Index);
          end {for Hc};
          Dec (Y, 16);
          Inc (X, 2);
        end {for Col};
        Dec (X, 192);
        Inc (Y, 16)
      end {for Row};
      Inc (X, 192);
      Dec (Y, 64);
    end {for Bank};
  end {with};
end; {proc View}


procedure TMainForm.OnRefreshTimer(Sender: TObject);
begin
  LcdRender;
  View;
  if RedrawReq = True then Canvas.Draw (63, 45, LcdBmp);
  RedrawReq := False;
end;


procedure KeyInterrupt;
const
{ table of interrupt capable KY bits for specified IA bits 5,4 }
  ktab: array [0..3] of word = ( $0000, $0080, $00C0, $F0FF );
begin
  if ((ia and $80) <> 0) and	{ key interrupt specified? }
     ((ReadKy (ia and $0F) and ktab[(ia shr 4) and 3]) <> 0) then
	SetIfl (KEYPULSE_bit);
end {KeyInterrupt};


{ release a pressed key if it's placed outside the coordinates X,Y }
procedure ReleaseKey1 (X, Y: Integer);
var
  i, r, c, k: integer;
begin
{ draw a released key if mouse was moved from a pressed key }
  if KeyCode1 = 0 then Exit;

{ locate the "keyblock" the key "KeyCode1" belongs to }
  i := 0;	{ "keyblock" index }
  k := 1;	{ first key code in the "keyblock" }
  while (KeyCode1 >= k + keypad[i].cnt) and (i < keypads1) do
  begin
    Inc (k, keypad[i].cnt);
    Inc (i);
  end {while};

  with keypad[i] do
  begin
    k := KeyCode1 - k;		{ offset of the key in the "keyblock" }
    c := L + SX*(k mod col);	{ X coordinate of the key image }
    r := T + SY*(k div col);	{ Y coordinate of the key image }
    if (X < c) or (X >= c + W) or (Y < r) or (Y >= r + H) then
    begin
      if KeyCode1 = 1 then
{ redraw the power switch according to the current SW_bit state }
      begin
        DrawKey (0, c, r, (flag and SW_bit) <> 0);
      end
      else
{ shift the key label upwards to get an impression of a released key }
      begin
        BitMap.Width := W-8;
        BitMap.Height := H-8;
        BitMap.Transparent := False;
        BitMap.Canvas.Draw (-c-5, -r-5, Face);
        Face.Canvas.Draw (c+4, r+4, BitMap);
        DrawKey (i, c, r, False);
      end {if};
      KeyCode1 := 0;
    end {if};
  end {with};
end {ReleaseKey1};


{ called when mouse button pressed }
procedure TMainForm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i, r, c, k: Integer;
begin
{ proceed only when left mouse button pressed }
  if Button <> mbLeft then Exit;

  ReleaseKey1 (-1, -1);
  KeyCode1 := 1;
  for i := 0 to keypads1 do
  begin
    with keypad[i] do
    begin
      if (X >= L) and (X < L+SX*col) and (((X-L) mod SX) < W) and
	(Y >= T) and (((Y-T) mod SY) < H) then
      begin
        c := (X-L) div SX;
        r := (Y-T) div SY;
        k := col*r + c;
        if k < cnt then
        begin
          Inc (KeyCode1, k);
          c := L+c*SX;
          r := T+r*SY;
          if KeyCode1 = 1 then
{ move the power switch to an opposite position }
          begin
            DrawKey (0, c, r, (flag and SW_bit) = 0);
          end
          else
{ shift the key label down-right to get an impression of a pressed key }
          begin
            BitMap.Width := W-8;
            BitMap.Height := H-8;
            BitMap.Transparent := False;
            BitMap.Canvas.Draw (-c-4, -r-4, Face);
            Face.Canvas.Draw (c+5, r+5, BitMap);
            DrawKey (i, c, r, True);
          end {if};
          break;
        end {if};
      end {if};
      Inc (KeyCode1, cnt);
    end {with};
  end {for};

  if KeyCode1 > lastkey1 then		{ no valid key pressed }
  begin
    KeyCode1 := 0;
{ dragging a captionless form by clicking anywhere on the client area outside
  the controls }
    if BorderStyle = bsNone then
    begin
      ReleaseCapture;
      SendMessage (Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0);
    end {if};
  end {if};

  if (KeyCode1 >= 4) and (KeyCode1 < 82) then KeyInterrupt;
end {proc};


{ called when mouse button released }
procedure TMainForm.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  K: integer;
begin
{ proceed only when left mouse button was pressed }
  if Button <> mbLeft then Exit;

  K := KeyCode1;
{ what to do if the mouse button was released over a pressed ... }
  case K of
    1:  begin				{ ...power switch }
          flag := flag xor SW_bit;
          ReleaseKey1 (-1, -1);
          if (flag and SW_bit) <> 0 then CpuWakeUp (False);
        end;
    2:  begin				{ ...Application Minimize key }
          ReleaseKey1 (-1, -1);
          Application.Minimize;
        end;
    3:  begin				{ ...Application Close key }
          ReleaseKey1 (-1, -1);
          Close;
        end;
    57: begin				{ ...BRK key }
          ReleaseKey1 (-1, -1);
          CpuWakeUp (False);
        end;
    else ReleaseKey1 (-1, -1);
  end {case};
end;


{ called when moving the mouse while the button pressed }
procedure TMainForm.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
{ release a pressed key if mouse was moved from it }
  ReleaseKey1 (X, Y);
end;


procedure TMainForm.FormShow(Sender: TObject);
begin
  KeyCode1 := 0;
  KeyCode2 := 0;
  CpuStop := False;
  CpuSleep := False;
  CpuDelay := 0;
  CpuSteps := -1;
  BreakPoint := -1;
{ load the Keys.bmp image }
  if FileExists (KeysName) then
    KeyBmp.LoadFromFile (KeysName)
  else
    MessageDlg (LoadMsg + KeysName, mtWarning, [mbOk], 0);
  KeyBmp.Transparent := False;
{ load the Overlay.bmp image }
  if FileExists (OverlayName) then
    OverlayBmp.LoadFromFile (OverlayName)
  else
    MessageDlg (LoadMsg + OverlayName, mtWarning, [mbOk], 0);
  OverlayBmp.Transparent := False;
{ draw the background image on the Face.Canvas }
  if FileExists (FaceName) then
  begin
    BitMap.LoadFromFile (FaceName);
    BitMap.Transparent := False;
    Face.Canvas.Draw (0, 0, BitMap);
    MainForm.Invalidate;
  end
  else
    MessageDlg (LoadMsg + FaceName, mtWarning, [mbOk], 0);
  Face.Transparent := False;
{ clear the LCD area }
  with LcdBmp.Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := clLtGray;
    FillRect (Rect(0, 0, 384, 64));
  end {with};
  pdi := $FB;
  if FileExists (memdef[ROM2].filename) or
     FileExists (memdef[ROM3].filename) then pdi := pdi and $FD;
{ select between the English/Japanese version depending on the absence/presence
  of the KANA key }
  with Face.Canvas, keypad[KEYPADS] do
  begin
    if Pixels [L-1, T] = Pixels [L, T] then	{no KANA key present}
    begin
      Dec (keypads1);
      Dec (lastkey1);
      pdi := pdi and $FE;
    end {if};
  end {with};
  CpuSpeed := OscFreq * integer(RunTimer.Interval);
  ResetAll;
  flag := SW_bit;		{ power switch on }
  ScrCtrl := not lcdctrl;	{ invalidate the shadow LCD control register }
  RunTimer.Enabled := True;
  RefreshTimer.Enabled := True;
  SecTimer.Enabled := True;
  RedrawReq := True;
end;


{ load a binary file, returns true if OK }
function MemLoad (fname: string; memory: PChar; fsize: integer) : boolean;
var
  f: file;
  numread: integer;
begin
  numread := 0;
  FillChar (memory^, fsize, $FF);
  if FileExists (fname) then
  begin
    AssignFile (f, fname);
    Reset (f, 1);
    BlockRead(f, memory^, fsize, numread);
    CloseFile (f);
  end;
  MemLoad := numread = fsize;
end {MemLoad};


{ save a binary file, returns True if OK }
function MemSave (fname: string; memory: PChar; fsize: integer) : boolean;
var
  f: file;
begin
  {$I-}
  AssignFile (f, fname);
  Rewrite (f, 1);
  BlockWrite(f, memory^, fsize);
  CloseFile (f);
  {$I+}
  MemSave := IOResult = 0;
end {MemSave};


procedure IniLoad;
var
  Ini1: TIniFile;
  InterfaceType: String;
begin
  Ini1 := TIniFile.Create (ExpandFileName(IniName));
  with Ini1 do
  begin
    OscFreq := ReadInteger ('Settings', 'OscFreq', 910);
    OptionCode := byte (ReadInteger ('Settings', 'OptionCode', OC_NONE));
    InterfaceType := UpperCase(ReadString('Settings','Interface',''));
    if (OptionCode = OC_NONE) and (InterfaceType <> '') then
    begin
                if (InterfaceType = 'FA7') or (InterfaceType = 'FA-7') then OptionCode := OC_FA7;
                if (InterfaceType = 'MD100') or (InterfaceType = 'MD-100') then OptionCode := OC_MD100;
                if (InterfaceType = 'NONE') then OptionCode := OC_NONE;
    end;
    MainForm.FddSocket.Address := ReadString ('Floppy Disk Drive', 'Address', '');
    MainForm.FddSocket.Port := ReadInteger ('Floppy Disk Drive', 'Port', 0);
    { Serial port... port }
    MainForm.SerialPort := ReadInteger ('Serial', 'Port', 0);
    { Serial port listen address }
    MainForm.SerialAddress := ReadString('Serial', 'Listen', '0.0.0.0');
    { Remote control port }
    MainForm.RemotePort := ReadInteger ('Remote', 'Port', 0);
    { Remote control listen address }
    MainForm.RemoteAddress := ReadString('Remote', 'Listen', '0.0.0.0');
    { Remote control key input interval in ms (keyup = half time) }
    MainForm.KeyInterval := ReadInteger ('Remote', 'Interval', 50);
  end {with};
  Ini1.Free;
end {IniLoad};

{ initialise the application }
procedure TMainForm.FormCreate(Sender: TObject);
var
  i, size: integer;
begin
  Brush.Style := bsClear;	{ transparent form }
  BitMap := TBitMap.Create;
  Face := TBitMap.Create;
  Face.Width := 673;
  Face.Height := 294;
  LcdBmp := TBitMap.Create;
  LcdBmp.Width := 384;
  LcdBmp.Height := 64;
  KeyBmp := TBitMap.Create;
  KeyBmp.Width := 168;
  KeyBmp.Height := 99;
  OverlayBmp := TBitMap.Create;
  OverlayBmp.Width := 432;
  OverlayBmp.Height := 12;
  if not MemLoad (ChrName, PChar(@lcdchr[0]), CHRSIZE div 2) then
  begin
    MessageDlg (LoadMsg + ChrName, mtWarning, [mbOk], 0);
  end {if};
{ convert the LCD character ROM image to 4-bit }
  for size := 127 downto 0 do
  begin
    for i := 15 downto 0 do
    begin
      lcdchr[2*size + i div 8, 2*(i mod 8)] := lcdchr[size,i] shr 4;
      lcdchr[2*size + i div 8, 2*(i mod 8) + 1] := lcdchr[size,i] and $F;
    end {for};
  end {for};
{ load the register file image }
  MemLoad (RegName, PChar(@mr[0]), 36);
  ss := ptrw(@mr[32])^;
  us := ptrw(@mr[34])^;
{ load the memory images }
  for i:=0 to MEMORIES-1 do
  begin
    with memdef[i] do
    begin
      size := (last-first) shl memorg;
      GetMem (storage, size);
      if filename <> '' then
      begin
        if not MemLoad (filename, storage, size) then
        begin
          if required then
          begin
            MessageDlg (LoadMsg + filename, mtWarning, [mbOk], 0);
          end {if};
        end {if};
      end {if};
    end {with};
  end {for};
  IniLoad;
  RunTimerFrequency := 1000 div RunTimer.Interval;
end;


{ terminate the application }
procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
{ As the memory appears to be deallocated before destroying the timers, it is
  necessary to prevent the emulated CPU to access the memory after it has been
  freed. }
  CpuStop := True;
  RunTimer.Enabled := False;
  RefreshTimer.Enabled := False;
  SecTimer.Enabled := False;
  IoClose;
  { save registers and memory images }
  SaveState(true, true);
  BitMap.Free;
  Face.Free;
  LcdBmp.Free;
  KeyBmp.Free;
  OverlayBmp.Free;
end;


{ show/hide the keyboard overlay }
procedure OverlayFlip;
var
  Temp: TBitMap;
  i, y, r: integer;
begin
  Temp := TBitMap.Create;
  Temp.Width := 432;
  Temp.Height := 6;
  Temp.Transparent := False;
  BitMap.Width := 432;
  BitMap.Height := 6;
  BitMap.Transparent := False;
  y := 0;
  r := 224;
  for i := 0 to 1 do
  begin
    Temp.Canvas.Draw (-58, -r, Face);
    BitMap.Canvas.Draw (0, -y, OverlayBmp);
    OverlayBmp.Canvas.Draw (0, y, Temp);
    Face.Canvas.Draw (58, r, BitMap);
    MainForm.Canvas.Draw (58, r, BitMap);
    Inc (y, 6);
    Inc (r, 33);
  end {for};
  Temp.Free;
end {OverlayFlip};


procedure TMainForm.FormKeyPress(Sender: TObject; var Key: Char);
{ letter and shift-letter list moved to Def unit }
  var
  n,sn: integer;
begin
  Key := UpCase(Key);
  n := pos(Key, Letters);
  sn := pos(Key, ShiftLetters);
  { key is on key face, send key code }
  if (n > 0) then
  begin
    KeyCode2 := n + LFIRSTCODE - 1;
    KeyInterrupt;
  end
  { key is not on key face and requires shift, send shift (red S) first and send wanted key on release }
  else if (sn > 0) then
  begin
     KeyCode2 := 15;
     DelayedKeyCode2 := sn + LFIRSTCODE - 1;
     KeyInterrupt;
  end;

end;

{ intercepting the VK_TAB key, Delphi FAQ2060D.txt   Detecting tab key press }
procedure TMainForm.CMDialogKey(var msg: TCMDialogKey);
begin
  if msg.Charcode <> VK_TAB then
   inherited;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  save: integer;
  shiftable: boolean;
begin
  save := Key;
  if ssShift in shift then case Key of
    VK_ESCAPE:  CpuWakeUp (False);
    VK_APPS:    KeyCode2 := 56; { CAL } { shift-menu = CAL }
    VK_F1:      KeyCode2 := 76; { M1 = 1st key under LCD }
    VK_F2:      KeyCode2 := 77; { M2 = 2nd key under LCD }
    VK_F3:      KeyCode2 := 78; { M3 = 1st key under LCD }
    VK_F4:      KeyCode2 := 79; { M4 = 2nd key under LCD }
    VK_F5:      KeyCode2 := 80; { ETC }
    VK_F9:      TogglePower;
    VK_F12:     KeyCode2 := 58; { CLS used with Shift - special case }
  end else case Key of
    VK_NEXT:	KeyCode2 := 46;	{ CAPS }
    VK_MENU:    KeyCode2 := 47; { ANS } { ALT key }
    VK_PRIOR:	KeyCode2 := 15;	{ red S }
    VK_ESCAPE:	KeyCode2 := 57;	{ BRK }
    VK_F12:     KeyCode2 := 58; { CLS }
    VK_BACK:	KeyCode2 := 59;	{ BS }
    VK_INSERT:	KeyCode2 := 49;	{ INS }
    VK_DELETE:	KeyCode2 := 51;	{ DEL }
    VK_APPS:    KeyCode2 := 52; { MENU } { menu = menu }
    VK_RETURN:  KeyCode2 := 75;	{ EXE }
    VK_TAB:     KeyCode2 := 4;  { TAB }
    VK_LEFT:	KeyCode2 := 53;	{ <- }
    VK_RIGHT:	KeyCode2 := 55;	{ -> }
    VK_UP:	KeyCode2 := 50;	{ up }
    VK_DOWN:	KeyCode2 := 54;	{ down }
    VK_F2:	OverlayFlip;
    VK_F3:	DebugForm.Show;
    VK_F4:      if (SerialPort > 0) and ((OptionCode = OC_FA7) or (OptionCode = OC_MD100)) then
                begin
                        SerialForm.Visible := not SerialForm.Visible;
                end;
    VK_F5:      if RemotePort > 0 then
                begin
                        RemoteForm.Visible := not SerialForm.Visible;
                end;

    VK_F8:	KeyCode2 := 82;	{ New All }
    VK_F9:      ResetAll;       { RESET }
  end {case};

  case Key of
        VK_NEXT, VK_PRIOR, VK_ESCAPE, VK_F12, VK_BACK, VK_INSERT, VK_DELETE,
        VK_RETURN, VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN: shiftable := true;
  else shiftable := false;
  end {case};

  { key can be used with red S and we have Shift pressed: send red S and send key on release }
  if shiftable and (ssShift in Shift) then
  begin
        DelayedKeyCode2 := KeyCode2;
        KeyCode2 := 15;
        KeyInterrupt;
  end;

  if (save <> Key) then
  begin
   KeyInterrupt;
  end;

end;

procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

  { a cached keycode needs to be emitted on release }
  if (DelayedKeyCode2 <> 0) then
  begin
        KeyCode2 := DelayedKeyCode2;
        KeyInterrupt;
        DelayedKeyCode2 := 0;
  end else KeyCode2 := 0;

end;

procedure TMainForm.FormPaint(Sender: TObject);
begin
  Face.Canvas.Draw (63, 45, LcdBmp);
  Canvas.Draw (0, 0, Face);
  RedrawReq := False;
end;


procedure TMainForm.OnRunTimer(Sender: TObject);
var
  x, y: integer;
begin
  if CpuDelay > 0 then
  begin
    Dec (CpuDelay);
    acycles := 0;
    Exit;
  end {if};
  Inc (acycles, CpuSpeed);
  while acycles > 0 do
  begin
    if CpuStop then
    begin
      acycles := 0;
      break;
    end {if};

    x := CpuRun;
    Dec (acycles, x);

{ INT1 interrupt, edge triggered }
    if (((ky and $0800) = 0) xor ((delayed_ky and $0800) = 0))	{ edge test }
        and
      (((ky and $0800) = 0) xor ((ie and $02) <> 0))		{ level test }
        then
      SetIfl (INT1_bit);
    delayed_ky := ky;

{ INT2 interrupt, level triggered }
    if ((ky and $0400) = 0) xor ((ie and $01) <> 0) then SetIfl (INT2_bit);

{ ON interrupt }
    if (lcdctrl and (VDD2_bit or CLK_bit)) = (VDD2_bit or CLK_bit) then
    begin
      Dec (OnCounter, x);
      if OnCounter < 0 then
      begin
        Inc (OnCounter, onrate);
        if OnCounter < 0 then OnCounter := onrate;
        ky := ky xor $0200;
        if (ky and $0200) = 0 then SetIfl (ONINT_bit);
      end {if};
    end {if};

{ Pulse interrupt }
    if (ia and $40) = 0 then y := 256{Hz} else y := 1{Hz};
    Dec (PulseCounter, x * y);
    if PulseCounter < 0 then
    begin
      Inc (PulseCounter, CpuSpeed * RunTimerFrequency);
      if ((ia and $80) = 0) then SetIfl (KEYPULSE_bit);
    end {if};

    if CpuSteps > 0 then
    begin
      Dec (CpuSteps);
      if CpuSteps = 0 then
      begin
        CpuStop := True;
        acycles := 0;
        DebugForm.Show;
        break;
      end {if};
    end {if};

    if (BreakPoint >= 0) and (BreakPoint = pc) then
    begin
      CpuStop := True;
      acycles := 0;
      DebugForm.Show;
      break;
    end {if};

  end {while};
end;


procedure TMainForm.OnSecTimer(Sender: TObject);
begin
  Inc (tm);
  if (tm and $3F) = 60 then
  begin
    Inc (tm, 4);
{ periodical interrupts asynchronous with the main clock are disabled in
  the debug mode }
    if not CpuStop then SetIfl (MINTIMER_bit);
  end {if};
end;


procedure TMainForm.FormDeactivate(Sender: TObject);
begin
  ReleaseKey1 (-1, -1);
  KeyCode2 := 0;
end;


procedure TMainForm.ApplicationDeactivate(Sender: TObject);
begin
  ReleaseKey1 (-1, -1);
  KeyCode2 := 0;
end;

end.
