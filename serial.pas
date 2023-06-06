{ serial port module }
unit Serial;

interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ScktComp, ComCtrls, ThdTimer;

const

 RXBUFSIZE = 1024;   { TCP maximum grabbable chunk }
 RXQUEUESIZE = 1024; { serial port max queue depth }

 _MinHeight = 158; { simplistic window state info for toggling the 'more' section }
 _MaxHeight = 330;

type
  TSerialForm = class(TForm)
    PBMonitor: TGroupBox;
    ClientMonitor: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    ClientRxLabel: TLabel;
    ClientTxLabel: TLabel;
    ClientConnectedPanel: TPanel;
    ClientRxLed: TPanel;
    ClientTxLed: TPanel;
    CasioRxLed: TPanel;
    CasioTxLed: TPanel;
    LedTimer: TTimer;
    SerialSocket: TServerSocket;
    Label3: TLabel;
    Label4: TLabel;
    CasioRxLabel: TLabel;
    CasioTxLabel: TLabel;
    QueueMonitor: TGroupBox;
    QueueFlush: TButton;
    QueueBar: TProgressBar;
    Label5: TLabel;
    QueueLabel: TLabel;
    TestLabel: TLabel;
    Int1Timer: TTimer;
    CntReset: TButton;
    PBOpenPanel: TPanel;
    BtnToggle: TButton;
    GbRx: TGroupBox;
    GbTx: TGroupBox;
    RxCaptureStart: TButton;
    RxCaptureClear: TButton;
    CasioRxAsc: TMemo;
    CasioRxHex: TMemo;
    CasioTxAsc: TMemo;
    CasioTxHex: TMemo;
    TxCaptureStart: TButton;
    TxCaptureClear: TButton;
    procedure FormCreate(Sender: TObject);
    procedure RefreshCounters;
    procedure LedTimerTimer(Sender: TObject);
    procedure SerialSocketClientConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure SerialSocketClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure SerialSocketClientRead(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ClientRxIncrement(count: Integer);
    procedure ClientTxIncrement(count: Integer);
    procedure CasioRxIncrement(count: Integer);
    procedure CasioTxIncrement(count: Integer);
    procedure CaptureByte(var amemo: TMemo; var hmemo: TMemo; b: byte);
    procedure RxQueueFlush;
    procedure RxEnqueue(var buf: array of byte; len: integer);
    procedure QueueFlushClick(Sender: TObject);
    procedure Int1TimerTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure CntResetClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SerialSocketClientError(Sender: TObject;
      Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
    procedure BtnToggleClick(Sender: TObject);
    procedure RxCaptureClearClick(Sender: TObject);
    procedure TxCaptureClearClick(Sender: TObject);
    procedure RxCaptureStartClick(Sender: TObject);
    procedure TxCaptureStartClick(Sender: TObject);
  private
    { Private declarations }

        { counters }
        ClientRxTotal: Integer;
        ClientTxTotal: Integer;
        CasioRxTotal: Integer;
        CasioTxTotal: Integer;

        { ring buffer }
        RxQueue: Array[0..RXQUEUESIZE-1] of byte;
        RxQueueWrite: Integer; { head }
        RxQueueRead: Integer;  { tail }
        RxQueued: Integer;     { depth }
        RxQueueLeft: Integer;  { free }

        { host notification / readiness flags }
        Int1Enabled: Boolean;
        Int1Set: Boolean;

        { is this thing on? }
        Enabled: Boolean;

  public
    { Public declarations }
        RxCapture: Boolean;
        TxCapture: Boolean;
        procedure SerialEnabled(en: Boolean);
        procedure PBOpened(opened: Boolean);
        procedure RxPoll(delayed: Boolean);
        function RxDequeue(var b: byte): Boolean;
        procedure TxByte(b: byte);
  end;

  { just a shim to access .Address of a TServerSocket }
  TBindingSocket = Class(TServerSocket);

var
  SerialForm: TSerialForm;

implementation

uses Def, Cpu, Port, Main;

{$R *.DFM}

{ capture a byte of data into an Ascii and Hex TMemo  pair }
procedure TSerialForm.CaptureByte(var amemo: TMemo; var hmemo: TMemo; b: byte);
var hex, asc: String;
begin
        hex := IntToHex(Integer(b),2);
        if Length(hmemo.Lines[hmemo.Lines.Count - 1]) < 23 then begin
                hmemo.Lines[hmemo.Lines.Count - 1] := hmemo.Lines[hmemo.Lines.Count - 1] + hex + ' ';
        end else begin
                hmemo.Lines.Add(hex + ' ');
        end;

        if (b > 31) and (b < 126) then asc:=chr(b) else asc := '.';
        if Length(amemo.Lines[amemo.Lines.Count - 1]) < 8 then begin
                amemo.Lines[amemo.Lines.Count - 1] := amemo.Lines[amemo.Lines.Count - 1] + asc;
        end else begin
                amemo.Lines.Add(asc);
        end;

end;

{ visual indication of port being active / inactive on sleep / wake up }
procedure TSerialForm.SerialEnabled(en: Boolean);
begin
        Enabled := en;
        PBMonitor.Enabled := Enabled;
        QueueMonitor.Enabled := Enabled;
        ClientMonitor.Enabled := Enabled;
        if Enabled
                then SerialForm.Caption := 'Serial Port Monitor'
                else SerialForm.Caption := 'Serial Port Monitor (CPU sleeping - not forwarding data)';
end;

{ enable / disable forwarding data to PB as INT1 becomes masked or unmasked }
procedure TSerialForm.PBOpened(opened: Boolean);
begin

        if Int1Enabled = opened then exit;

        if opened then
        begin
              RxPoll(true);
              PBOpenPanel.Color := clGreen;
              PBOpenPanel.Caption := 'Port Open (INT1)';
              PBOpenPanel.Font.Color := clWhite;
        end else
        begin
              PBOpenPanel.Color := clRed;
              PBOpenPanel.Caption := 'Port Closed (INT1)';
              PBOpenPanel.Font.Color := clSilver;

        end;

        Int1Enabled := opened;
end;

{ if data available, signal an INT1 either immediately or after a one-shot timer run }
procedure TSerialForm.RxPoll(delayed: Boolean);
begin
 if RxQueued > 0 then
 begin
       if delayed then
       begin
                { trigger INT1 after a delay }
                Int1Timer.Enabled:=True;
       end else begin
                { trigger INT1 immediately }
                Int1Set := True;
                SetIfl(INT1_bit);
       end;
 end;
end;

{ transmit a byte of data to the outside world }
procedure TSerialForm.TxByte(b: byte);
begin
        with SerialSocket.Socket do
        begin
                if ActiveConnections = 1 then
                begin
                        if Connections[0].SendBuf(b,1) = 1 then ClientTxIncrement(1);
                end;
        end;

        if TxCapture then CaptureByte(CasioTxAsc, CasioTxHex, b);

        CasioTxIncrement(1);
end;

{ queue an incoming chunk of data onto the RxQueue ring buffer }
procedure TSerialForm.RxEnqueue(var buf: array of byte; len: integer);
var
        i,toEnd: integer;
begin

        if not Enabled then exit;

        if RxQueueLeft >= len then
        begin
                toEnd := RXQUEUESIZE - RxQueueWrite;
                { we can append to the queue }
                if len <= toEnd then
                begin
                        Move(buf, RxQueue[RxQueueWrite], len);
                { wrap around }
                end else begin
                        Move(buf, RxQueue[RxQueueWrite], toEnd);
                        Move(buf[toEnd], RxQueue[0], len - toEnd);
                end;

                Inc(RxQueueWrite, len);
                RxQueueWrite := RxQueueWrite mod RXQUEUESIZE;
                Inc(RxQueued, len);
                Dec(RxQueueLeft, len);
                RxPoll(false);
                RefreshCounters;
                if RxCapture then
                begin
                    for i := 0 to len - 1 do
                        CaptureByte(CasioRxAsc, CasioRxHex, buf[i]);
                end;
        end;
end;

{ read a byte from the RxQueue ring buffer into b - the PB does this byte by byte }
function TSerialForm.RxDequeue(var b: byte): Boolean;
begin
        RxDequeue := False;
        if RxQueued > 0 then
        begin
                Int1Set := False;
                RxDequeue := True;
                b := RxQueue[RxQueueRead];
                Inc(RxQueueRead);
                RxQueueRead := RxQueueRead mod RXQUEUESIZE;
                Dec(RxQueued);
                Inc(RxQueueLeft);
                CasioRxIncrement(1);
                RefreshCounters;
        end;
end;

{ refresh counter labels }
procedure TSerialForm.RefreshCounters;
begin

        { no point wasting cycles if the window is hidden }
        if Visible then
        begin
                ClientRxLabel.Caption := IntToStr(ClientRxTotal);
                ClientTxLabel.Caption := IntToStr(ClientTxTotal);
                CasioRxLabel.Caption := IntToStr(CasioRxTotal);
                CasioTxLabel.Caption := IntToStr(CasioTxTotal);
                QueueLabel.Caption := IntToStr(RxQueued)+'/'+IntToStr(RXQUEUESIZE);
                QueueBar.Position := RxQueued;
        end;
end;

{ flush RX queue }
procedure TSerialForm.RxQueueFlush;
begin
        RxQueued := 0;
        RxQueueRead := 0;
        RxQueueWrite := 0;
        RxQueueLeft := RXQUEUESIZE;
        RefreshCounters;
end;

{ Blinken lights + counter increments }
procedure TSerialForm.ClientRxIncrement(count: Integer);
begin
        Inc(ClientRxTotal,count);
        ClientRxLed.Color := clRed;
        ClientRxLed.Font.Color := clWhite;
        RefreshCounters;
end;

procedure TSerialForm.ClientTxIncrement(count: Integer);
begin
        Inc(ClientTxTotal,count);
        ClientTxLed.Color := clBlue;
        ClientTxLed.Font.Color := clWhite;
        RefreshCounters;
end;

procedure TSerialForm.CasioRxIncrement(count: Integer);
begin
        Inc(CasioRxTotal,count);
        CasioRxLed.Color := clRed;
        CasioRxLed.Font.Color := clWhite;
        RefreshCounters;
end;

procedure TSerialForm.CasioTxIncrement(count: Integer);
begin
        Inc(CasioTxTotal,count);
        CasioTxLed.Color := clBlue;
        CasioTxLed.Font.Color := clWhite;
        RefreshCounters;
end;

{ initialisation tasks }
procedure TSerialForm.FormCreate(Sender: TObject);
begin
        SerialEnabled(True);
        Int1Set := False;
        Int1Enabled := False;
        RxQueueFlush;
        ClientRxTotal := 0;
        ClientTxTotal := 0;
        CasioRxTotal := 0;
        CasioTxTotal := 0;
        QueueBar.Max := RXQUEUESIZE;
        RefreshCounters;
        LedTimer.Enabled := False;
        Height := _MinHeight;
        RxCapture := False;
        TxCapture := False;

    { this module only functions if we told the emulator we have an FA-7 ($00) or MD-100 ($55) }
    if ((OptionCode = OC_FA7) or (OptionCode = OC_MD100)) and (MainForm.SerialPort <> 0) then
    with SerialSocket do
        begin
                TBindingSocket(SerialSocket).Address := MainForm.SerialAddress;
                Port := MainForm.SerialPort;
                Active := True;
                Open;
                ClientMonitor.Caption := 'TCP Client (Port: '+IntToStr(Port)+')';
        end;

end;

{ a trivial way to blink LEDs. Incoming data lights them up, this periodically switches them all off }
procedure TSerialForm.LedTimerTimer(Sender: TObject);
begin
             ClientRxLed.Color := clBtnFace;
             ClientRxLed.Font.Color := clWindowText;

             ClientTxLed.Color := clBtnFace;
             ClientTxLed.Font.Color := clWindowText;

             CasioRxLed.Color := clBtnFace;
             CasioRxLed.Font.Color := clWindowText;

             CasioTxLed.Color := clBtnFace;
             CasioTxLed.Font.Color := clWindowText;
end;

{ a TCP client was connected }
procedure TSerialForm.SerialSocketClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
  begin
        ClientConnectedPanel.Caption := 'Connected';
        ClientConnectedPanel.Color := clGreen;
        ClientConnectedPanel.Font.Color := clWhite;
        with SerialSocket.Socket do
        begin
                { only work with a single connection - close any extra accepted ones }
                if ActiveConnections > 1 then
                begin
                        Connections[1].Close;
                end else
                begin
                        { display the window when a client connects, but don't take focus away from main window }
                        if not Visible then
                        begin
                                MainForm.Show;
                                Show;
                        end;
                end;
        end;

end;

{ TCP client disconnected }
procedure TSerialForm.SerialSocketClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
        if SerialSocket.Socket.ActiveConnections = 1 then
        begin
                ClientConnectedPanel.Caption := 'Disconnected';
                ClientConnectedPanel.Color := clRed;
                ClientConnectedPanel.Font.Color := clSilver;
                ClientRxTotal := 0;
                ClientTxTotal := 0;
                RefreshCounters;
        end;
end;

{ we have data to read - read all of it and enqueue }
procedure TSerialForm.SerialSocketClientRead(Sender: TObject;
  Socket: TCustomWinSocket);
var buf: array [0..RXBUFSIZE-1] of byte;
    len: integer;
begin
  with SerialSocket.Socket do
  begin
        if ActiveConnections > 0 then
        begin
                repeat
                        len:=Connections[0].ReceiveBuf(buf, RXBUFSIZE);
                        if len > 0 then
                        begin
                                RxEnqueue(buf, len);
                                ClientRxIncrement(len);
                        end;
                until len < 1;
        end;
  end

end;

{ flush RX queue button clicked }
procedure TSerialForm.QueueFlushClick(Sender: TObject);
begin
        RxQueueFlush;
end;

{ delayed INT1 trigger }
procedure TSerialForm.Int1TimerTimer(Sender: TObject);
begin
       Int1Timer.Enabled:=False;
       Int1Set := True;
       SetIfl(INT1_bit);
end;

{ refresh counters and restart LEDs when form shows }
procedure TSerialForm.FormShow(Sender: TObject);
begin
        LedTimer.Enabled := True;
        RefreshCounters;
end;

{ stop blinking LEDs when window is hidden }
procedure TSerialForm.FormHide(Sender: TObject);
begin
        LedTimer.Enabled := False;
end;

{ reset the counters }
procedure TSerialForm.CntResetClick(Sender: TObject);
begin
        ClientRxTotal := 0;
        ClientTxTotal := 0;
        CasioRxTotal := 0;
        CasioTxTotal := 0;
        RefreshCounters;
end;

{ hide on ESC or F4 }
procedure TSerialForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
        if Key = VK_F4 then Hide; { this is to allow toggling the window if it has focus }
        if Key = VK_ESCAPE then Hide;
end;

procedure TSerialForm.SerialSocketClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
        { do nothing, should probably also do an exception wrapper to make things even more awkward }
end;

{ toggle the 'more' section }
procedure TSerialForm.BtnToggleClick(Sender: TObject);
begin
        if Height = _MinHeight then
        begin
                GbTx.Visible := true;
                GbRx.Visible := true;
                Height := _MaxHeight;
                BtnToggle.Caption := 'Less...';
        end else
        begin
                Height := _MinHeight;
                GbTx.Visible := false;
                GbRx.Visible := false;
                BtnToggle.Caption := 'More...';
        end;
end;

{ clear the RX side TMemos }
procedure TSerialForm.RxCaptureClearClick(Sender: TObject);
begin
        CasioRxAsc.Lines.Clear;
        CasioRxHex.Lines.Clear;
end;

{ clear the TX side TMemos }
procedure TSerialForm.TxCaptureClearClick(Sender: TObject);
begin
        CasioTxAsc.Lines.Clear;
        CasioTxHex.Lines.Clear;
end;

{ toggle capture states }
procedure TSerialForm.RxCaptureStartClick(Sender: TObject);
begin
       RxCapture := not RxCapture;
       if RxCapture then RxCaptureStart.Caption := 'Stop capture'
       else RxCaptureStart.Caption := 'Start capture'
end;

procedure TSerialForm.TxCaptureStartClick(Sender: TObject);
begin
       TxCapture := not TxCapture;
       if TxCapture then TxCaptureStart.Caption := 'Stop capture'
       else TxCaptureStart.Caption := 'Start capture'
end;

{ all she wrote }
end.


