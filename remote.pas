{ remote control module }
unit Remote;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ScktComp, ExtCtrls;
const
        RXBUFSIZE = 1024; { TCP buffer size per received chunk }
        CMDQUEUESIZE = 2048; { max # of queued key entry commands }
        MAXCMDLEN = 25; { maximum length of command name }
        MAXPARAMS = 8; { max # of parameters for a command }
        MAXPARAMLEN = 16; { maximum length of a parameter string }
        MAXCONNECTIONS = 8; { maximum number of concurrent TCP connections }
type

  TCmdParserState  = ( sAny, sToken, sParams, sEsc, sCsi );     { parser states }
  TCmdType = ( cNone, cChar, cKey, cRequest, cCommand );        { remote command types }
  TRequestType = ( RPOWER, RPAUSE, RGETMEM, RVMEM, RVERSION, RMAX );             { request types (ask for something) }
  TCommandType = ( CPOWER, CPAUSE, CSAVEMEM, CMAX );            { command types (do something) }

  { command descriptor }
  TCmd = record
        parserState: TCmdParserState;
        ctype: TCmdType;
        ch: char;
        key: word;
        paramcount: integer;
        connId: integer;
        name: String[MAXCMDLEN];
        params: array [0..MAXPARAMS-1] of String[MAXPARAMLEN];

  end;

  TRemoteForm = class(TForm)
    RcSocket: TServerSocket;
    RcConnectedPanel: TPanel;
    RcActiveLed: TPanel;
    LedTimer: TTimer;
    KeyUpTimer: TTimer;
    QueueTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure RcSocketClientConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure RcSocketClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure RcSocketClientRead(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure RcSocketClientError(Sender: TObject;
      Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
    procedure LedTimerTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KeyUpTimerTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure QueueTimerTimer(Sender: TObject);
    private
    { Private declarations }
        CmdCache: Array [0..MAXCONNECTIONS] of TCmd; { MAXCONNECTIONS + last one for string macros }
        KeyNameStrings: TStringList;
        RequestNameStrings: TStringList;
        CommandNameStrings: TStringList;
        { Command queue }
        CmdQueue: Array[0..CMDQUEUESIZE-1] of TCmd;
        CmdQueueWrite: Integer; { head }
        CmdQueueRead: Integer;  { tail }
        CmdQueued: Integer;     { depth }

        procedure EnqueueCmd( var cmd: TCmd);
        procedure DequeueCmd;
        procedure ExecCmd(var c: TCmd);
        procedure ParseBuf(var buf: array of byte; len: integer; var cmd: TCmd);
        procedure SendResponse(connId: integer; var buf; len: integer);
        procedure DispatchChar(c: char);
        procedure DispatchKey (key: Word;  ss: TShiftState);
  public
        procedure ParseString(s: string);
    { Public declarations }
  end;

  { just a shim to access .Address of a TServerSocket }
  TBindingSocket = Class(TServerSocket);

const
        KEYNCOUNT = 30;
        { list of key command tokens }
        KeyNameList: array [0..KEYNCOUNT-1] of String = (
                'TAB', 'MEMO', 'IN', 'OUT', 'CALC', 'S',
                'CAPS', 'SPC', 'ANS',
                'INS', 'UP', 'DEL', 'MENU',
                'LEFT', 'DOWN', 'RIGHT', 'CAL',
                'BRK', 'CLS', 'BS', 'EXE',
                'M1', 'M2', 'M3', 'M4', 'ETC',
                'RESET', 'NEWALLYESIMSURE','WAKEUP','POWER'
        );
        { list of corresponding VK_ key codes }
        KeyList: array [0..KEYNCOUNT-1] of Word = (
                VK_TAB, 0, 0, 0, 0, VK_PRIOR,
                VK_NEXT, VK_SPACE, VK_MENU,
                VK_INSERT, VK_UP, VK_DELETE, VK_APPS,
                VK_LEFT, VK_DOWN, VK_RIGHT, VK_APPS,
                VK_ESCAPE, VK_F12, VK_BACK, VK_RETURN,
                VK_F1, VK_F2, VK_F3, VK_F4, VK_F5,
                VK_F9, VK_F8, VK_ESCAPE, VK_F9
        );
        { list of corresponding shift states to emulate }
        SsList: array [0..KEYNCOUNT-1] of TShiftState = (
                [], [], [], [], [], [],
                [], [], [],
                [], [], [], [],
                [], [], [], [ssShift],
                [], [], [], [],
                [ssShift], [ssShift], [ssShift], [ssShift], [ssShift],
                [], [], [ssShift], [ssShift]
        );

        { list of request names - this MUST match the order of the TRequestType enum }
        RequestNameList: array [0..Integer(RMAX)-1] of String = (
                'POWER', 'PAUSE', 'GETMEM', 'VMEM', 'VERSION'
        );

        { list of request names - this MUST match the order of the TRequestType enum }
        CommandNameList: array [0..Integer(CMAX)-1] of String = (
                'POWER', 'PAUSE', 'SAVEMEM'
        );

var
  RemoteForm: TRemoteForm;

implementation

uses Main, Def, Lcd, Serial;

{$R *.DFM}

procedure TRemoteForm.FormCreate(Sender: TObject);
var i: integer;
begin

    CmdQueued := 0;
    CmdQueueRead := 0;
    CmdQueueWrite := 0;

   fillchar(cmdCache, Length(cmdCache)* sizeof(TCmd), 0);

   { key entry interval }
   QueueTimer.Interval := MainForm.KeyInterval;
   KeyUpTimer.Interval := round(MainForm.KeyInterval / 2);

   { populate KeyNameStrings with a list of names }
   KeyNameStrings := TStringList.Create;
   for i := 0 to KEYNCOUNT - 1 do KeyNameStrings.Add(KeyNameList[i]);

   { populate RequestNameStrings with a list of names }
   RequestNameStrings := TStringList.Create;
   for i := 0 to Integer(RMAX) - 1 do RequestNameStrings.Add(RequestNameList[i]);

   { populate RequestNameStrings with a list of names }
   CommandNameStrings := TStringList.Create;
   for i := 0 to Integer(CMAX) - 1 do CommandNameStrings.Add(CommandNameList[i]);

   { this module only functions if we told the emulator to listen for remote commands }
    if MainForm.RemotePort <> 0 then
    with RcSocket do
        begin
                TBindingSocket(RcSocket).Address := MainForm.RemoteAddress;
                Port := MainForm.RemotePort;
                Active := True;
                Open;
        end;
end;

procedure TRemoteForm.RcSocketClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
  var s: String;
begin

        RcConnectedPanel.Color := clGreen;
        RcConnectedPanel.Font.Color := clWhite;
        with RcSocket.Socket do
        begin
                { only work with a single connection - close any extra accepted ones }
                if ActiveConnections >  MAXCONNECTIONS then
                begin
                        Connections[ActiveConnections - 1].Close;
                end else
                begin
                        RcConnectedPanel.Caption := IntToStr(ActiveConnections)+' connected (Port: '+IntToStr(MainForm.RemotePort)+')';
                        { display the window when a client connects, but don't take focus away from main window }
                        if not Visible then
                        begin
                                MainForm.Show;
                                Show;
                        end;
                        { send a hello identifier - this also helps some telnet clients that won't echo locally until they see some output }
                        s := 'EMHELLO'+#13+#10;
                        CmdCache[ActiveConnections - 1].ParserState := sAny;
                        CmdCache[ActiveConnections - 1].connId := ActiveConnections - 1;
                        SendResponse(ActiveConnections - 1, s[1],Length(s));
                end;
        end;

end;

procedure TRemoteForm.RcSocketClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
        if RcSocket.Socket.ActiveConnections = 1 then
        begin
                RcConnectedPanel.Caption := 'Disconnected (Port: '+IntToStr(MainForm.RemotePort)+')';
                RcConnectedPanel.Color := clRed;
                RcConnectedPanel.Font.Color := clSilver;
        end else begin
                RcConnectedPanel.Caption := IntToStr(RcSocket.Socket.ActiveConnections - 1)+' connected (Port: '+IntToStr(MainForm.RemotePort)+')';
        end;
end;

{ queue a remote command for dispatch }
procedure TRemoteForm.EnqueueCmd (var cmd: TCmd);
label cleanup;
begin
        if (cmd.ctype = cNone) then goto cleanup;

        { execute requests and commands immediately }
        if cmd.ctype in [ cRequest, cCommand ] then
        begin
                ExecCmd(cmd);
                goto cleanup;
        end;

        QueueTimer.Enabled := True;

        { queue keyboard input }
        if CmdQueued < CMDQUEUESIZE then
        begin
                CmdQueue[CmdQueueWrite] := cmd;
                Inc(CmdQueueWrite);
                CmdQueueWrite := CmdQueueWrite mod CMDQUEUESIZE;
                Inc(CmdQueued);
        end;

cleanup:

        fillchar(cmd, sizeof(cmd), 0);

end;

{ grab the next command and dispatch it }
procedure TRemoteForm.DequeueCmd;
var c: TCmd;
begin
        if CmdQueued > 0 then
        begin
                c := CmdQueue[CmdQueueRead];
                Inc(CmdQueueRead);
                CmdQueueRead := CmdQueueRead mod CMDQUEUESIZE;
                Dec(CmdQueued);
                ExecCmd(c);
        end;

        if CmdQueued = 0 then QueueTimer.Enabled := False;

end;

{ parse and dispatch a remote command }
procedure TRemoteForm.ExecCmd(var c: TCmd);
var
        n: integer;
        ResponseStr: String;
        i: integer;
        vbuf: array[0..LCDSIZE + 4 - 1] of byte; { "VMEM" string + LCD memory }
begin

        if c.paramcount > 0 then begin
                for i:= 0 to c.paramcount do SerialForm.CasioRxHex.Lines.Add(c.params[i]);
        end;

        case c.ctype of
                { a simple character input }
                cChar: dispatchChar(c.ch);

                { virtual key }
                cKey:  begin
                        { key code already specified }
                        if c.key <> 0 then dispatchKey(c.key , []);
                        { symbolic key name specified, look it up and dispatch the vk if found }
                        if c.name <> '' then
                        begin
                                n := KeyNameStrings.IndexOf(c.name);
                                if n >= 0 then dispatchKey(KeyList[n],SsList[n]);

                                { response for 'POWER' key }
                                if c.name = 'POWER' then
                                begin
                                        ResponseStr := 'POWER=';
                                        if (flag and SW_bit) <> 0 then
                                                ResponseStr := ResponseStr + 'ON'
                                        else
                                                ResponseStr := ResponseStr + 'OFF';
                                        SendResponse(c.connId, ResponseStr[1], Length(ResponseStr));
                                end;
                        end;
                end; {cKey}

                { request: ask for some data }
                cRequest: if c.name <> '' then begin
                        { check if we recognise the request, index corresponds to the TRequestType enum }
                        n := RequestNameStrings.IndexOf(c.name);
                        ResponseStr := '';
                        if n >= 0 then case TRequestType(n) of
                                        RPOWER: begin
                                                ResponseStr := 'POWER=';
                                                if (flag and SW_bit) <> 0 then
                                                        ResponseStr := ResponseStr + 'ON'
                                                else
                                                        ResponseStr := ResponseStr + 'OFF';
                                        end; { POWER? }
                                        RPAUSE: begin
                                                ResponseStr := 'PAUSE=';
                                                if CpuStop then
                                                        ResponseStr := ResponseStr + 'ON'
                                                else
                                                        ResponseStr := ResponseStr + 'OFF';
                                        end; { PAUSE? }
                                        RVMEM: begin
                                                ResponseStr := 'VMEM';
                                                Move(ResponseStr[1],vbuf,4);
                                                Move(lcdimage,vbuf[4],LCDSIZE);
                                                SendResponse(c.connId, vbuf, LCDSIZE + 4);
                                                exit;
                                        end; { VMEM? }
                                        RVERSION: begin
                                                 ResponseStr := 'EMVERSION,'+PLATFORM_ID+','+VERSION_STR;
                                        end; { VERSION? }

                        end; {case}
                        { send response }
                        if ResponseStr <> '' then
                                SendResponse(c.connId, ResponseStr[1], Length(ResponseStr));
                end; {cRequest}

                { command: do something }
                cCommand: if c.name <> '' then begin
                        { check if we recognise the request, index corresponds to the TCommandType enum }
                        n := CommandNameStrings.IndexOf(c.name);
                        ResponseStr := '';
                        if n >= 0 then case TCommandType(n) of
                                        CPOWER: begin
                                                ResponseStr := 'POWER=';

                                                if c.paramcount > 0 then
                                                begin
                                                        if c.params[0] = 'ON' then
                                                        begin
                                                                ResponseStr := ResponseStr + 'ON';
                                                                SetPower(true);
                                                        end else if c.params[0] = 'OFF' then
                                                        begin
                                                                SetPower(false);
                                                                ResponseStr := ResponseStr + 'OFF';
                                                        end;
                                                end else if TogglePower then
                                                        ResponseStr := ResponseStr + 'ON'
                                                else
                                                        ResponseStr := ResponseStr + 'OFF';
                                        end; { POWER! }

                                        CPAUSE: begin
                                                ResponseStr := 'PAUSE=';

                                                if c.paramcount > 0 then
                                                begin
                                                        if c.params[0] = 'ON' then
                                                        begin
                                                                ResponseStr := ResponseStr + 'ON';
                                                                CpuStop := True;
                                                        end else if c.params[0] = 'OFF' then
                                                        begin
                                                                CpuStop := False;
                                                                ResponseStr := ResponseStr + 'OFF';
                                                        end;
                                                end else
                                                begin
                                                        CpuStop := not CpuStop;
                                                        if CpuStop then
                                                                ResponseStr := ResponseStr + 'ON'
                                                        else
                                                                ResponseStr := ResponseStr + 'OFF';
                                                end;
                                        end; { PAUSE! }

                                        CSAVEMEM: begin
                                                SaveState(false, false);
                                                ResponseStr := 'SAVEMEM=OK';
                                        end; { SAVEMEM! }
                        end; {case}
                        { send response }
                        if ResponseStr <> '' then
                                SendResponse(c.connId, ResponseStr[1], Length(ResponseStr));

                end; { cCommand }

        end;
end;

procedure TRemoteForm.SendResponse(connId: integer; var buf; len: integer);
begin
  { manually fed strings don't produce any response }
  if connId = MAXCONNECTIONS then exit;

  with RcSocket.Socket do
  begin
        try
                if ActiveConnections > 0 then Connections[connId].SendBuf(buf, len);
        except
                RcSocket.Socket.Connections[connId].Close;
        end;
  end;
end;

{ run command parser over a string, and reset the parser at the end - }
{ one run is meant to be a complete session / set of commands }
procedure TRemoteForm.ParseString(s: string);
var b: array of byte;
begin
   fillchar(cmdCache[MAXCONNECTIONS], sizeof(TCmd), 0);
   SetLength(b, length(s));
   Move(s[1],b[0],length(s));
   QueueTimer.Enabled := true;
   ParseBuf(b, length(s), cmdCache[MAXCONNECTIONS]);
   fillchar(cmdCache[MAXCONNECTIONS], sizeof(TCmd), 0);
end;


{ run command parser over a buffer }
procedure TRemoteForm.ParseBuf(var buf: array of byte; len: integer; var cmd: TCmd);
var
        c: char;
        b: byte;
        i: integer;
label keydone, tokenjump;
begin
    for i:= 0 to len - 1 do
    begin
        b := buf[i];
        c := UpCase(chr(b));

        case cmd.ParserState of
                { looking for any characters }
                sAny: begin
                        cmd.paramcount := 0;
                        cmd.ctype := cNone;
                        cmd.name := '';
                        { simple enter, del, bs }
                        case b of
                                $08: begin cmd.ctype := cKey; cmd.key := VK_BACK; end;
                                $09: begin cmd.ctype := cKey; cmd.key := VK_TAB; end;
                                $0d,$0a: begin cmd.ctype := cKey; cmd.key := VK_RETURN; end;
                                $7f: begin cmd.ctype := cKey; cmd.key := VK_DELETE; end;
                        end;

                        if cmd.ctype <> cNone then goto keydone;

                        { Escape }
                        if c = #27 then
                        begin
                                cmd.name := '';
                                cmd.ParserState := sEsc;
                                continue;
                        end;

                        { non-printable ASCII }
                        if (b < 32) or ( b > 126) then continue;

                        { '<' = beginning of a command token, advance state }
                        if c = '<' then
                        begin
                                cmd.name := '';
                                cmd.ParserState := sToken;
                                continue;
                        end;

                        { a valid keyboard key }
                        if (pos(c, Letters) > 0) or (pos(c, ShiftLetters) > 0)  then
                        begin
                                cmd.ctype := cChar;
                                cmd.ch := c;
                        end;
keydone:
                        { command parsed, queue it for execution }
                        EnqueueCmd(cmd);

                end; {sAny}
                { we are inside a <token> }
                sToken: begin
                        { a-z, 0-9: keep building token = command name }
                        if c in ['A'..'Z', '0'..'9'] then
                        begin
                                if Length(cmd.name) < MAXCMDLEN then cmd.name := cmd.name + c;
                                continue;
                        end;
tokenjump:
                        { other identifiers }
                        case c of
                                { space: we will now be passing parameters or adding parameters}
                                ' ': with cmd do begin
                                        if paramcount < MAXPARAMS then
                                        begin
                                                ParserState:= sParams;
                                                { do not introduce empty parameters with repeated spaces }
                                                if (paramcount = 0) or (params[paramcount - 1] <> '')
                                                        then inc(paramcount);
                                                params[paramcount - 1] := '';
                                                continue;
                                        end;
                                       { reset state from sParams to sToken - this happens if we exceed MAXPARAMS }
                                       ParserState := sToken;

                                        continue;
                                end;

                                { '<' inside a token = we want a '<' entered and we escaped it with another '<' }
                                '<': begin
                                        cmd.ctype := cChar;
                                        cmd.ch := c;
                                        cmd.ParserState := sAny;
                                        EnqueueCmd(cmd);
                                        continue;
                                end;
                                { <NAME?> is a request }
                                '?': begin
                                        cmd.cType := cRequest;
                                        continue;
                                end;


                                { <NAME!> is a command }
                                '!': begin
                                        cmd.cType := cCommand;
                                        continue;
                                end;

                                { end of token }
                                '>': begin
                                        { if it's not a request ('?') or command ('!') then it's a named key }
                                        if not (cmd.cType in [ cRequest, cCommand ]) then cmd.ctype := cKey;
                                        { no key number, work with key name }
                                        cmd.key := 0;
                                        { reset parser state }
                                        cmd.ParserState := sAny;
                                        EnqueueCmd(cmd);
                                end;

                        end; {case}

                        { any other character }
                        cmd.ParserState := sAny;
                end; {sToken}

                sParams: begin
                        { a-z, 0-9: keep building current parameter }
                        if c in ['A'..'Z', '0'..'9'] then with cmd do
                        begin
                                if Length(params[paramcount - 1]) < MAXPARAMLEN then
                                        params[paramcount - 1] := params[paramcount - 1] + c;
                                continue;
                        end;

                        { otherwise short-circuit to token end or extension }
                        goto tokenjump;

                end; {sParams}

                { TODO: parse more complex sequences with parameters }
                sEsc: begin
                        { ESC + '[' = Control Sequence Introducer (CSI) }
                        if c = '[' then
                        begin
                                cmd.ParserState := sCsi;
                                continue;
                        end;
                        { any other chatacter }
                        cmd.ParserState := sAny;
                end; {sEsc}

                { some basic common CSI codes: cursor keys for now }
                sCsi: begin
                        cmd.ctype := cNone;
                        case c of
                                'A': begin cmd.ctype := cKey; cmd.key := VK_UP; end;
                                'B': begin cmd.ctype := cKey; cmd.key := VK_DOWN; end;
                                { I always lauged at how ANSI made sure that RIGHT goes before LEFT. }
                                { It's actually Forward and Backward, but this only emphasises the sentiment }
                                'C': begin cmd.ctype := cKey; cmd.key := VK_RIGHT; end;
                                'D': begin cmd.ctype := cKey; cmd.key := VK_LEFT; end;
                        end;
                        cmd.ParserState := sAny;

                        if cmd.cType <> cNone then EnqueueCmd(cmd);

                end; {sCsi}

        end; {case}
    end; {for}
end;

{ send a character to the keyboard }
procedure TRemoteForm.DispatchChar(c: char);
begin
       MainForm.FormKeyPress(nil, c);
       KeyUpTimer.Enabled := True;
end;

{ send a vk_ to the keyboard }
procedure TRemoteForm.DispatchKey (key: Word; ss: TShiftState);
begin
        MainForm.FormKeyDown(nil, key, ss);
        KeyUpTimer.Enabled := True;
end;

{ data has arrived at the socket }
procedure TRemoteForm.RcSocketClientRead(Sender: TObject;
  Socket: TCustomWinSocket);
var
        hadData: boolean;
        buf: array [0..RXBUFSIZE-1] of byte;
        i,len: integer;
begin
  hadData := false;
  with RcSocket.Socket do
  begin
        if ActiveConnections > 0 then
        for i:= 0 to (ActiveConnections - 1) do
        begin
                try
                        repeat


                                len := Connections[i].ReceiveBuf(buf, RXBUFSIZE);
                                if len > 0 then
                                begin
                                        hadData := true;
                                        CmdCache[i].connId := i;
                                        parseBuf(buf, len, CmdCache[i]);
                                end;
                                until len < 1;
                except

                RcSocket.Socket.Connections[i].Close;

                end;

                if hadData and Visible then
                begin
                        RcActiveLed.Color := clBlue;
                        RcActiveLed.Font.Color := clWhite;
                end;
        end;
  end
end;

procedure TRemoteForm.RcSocketClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
        { silence the error }
        ErrorCode := 0;
        Socket.Close;
end;

procedure TRemoteForm.LedTimerTimer(Sender: TObject);
begin
             RcActiveLed.Color := clBtnFace;
             RcActiveLed.Font.Color := clWindowText;
end;

procedure TRemoteForm.FormShow(Sender: TObject);
begin
        LedTimer.Enabled := True;
end;

procedure TRemoteForm.FormHide(Sender: TObject);
begin
        LedTimer.Enabled := False;
end;

procedure TRemoteForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
        if Key = VK_F5 then Hide; { this is to allow toggling the window if it has focus }
        if Key = VK_ESCAPE then Hide;
end;

procedure TRemoteForm.KeyUpTimerTimer(Sender: TObject);
var key: word;
begin
     KeyUpTimer.Enabled := false;
     key := 0;
     MainForm.FormKeyUp(nil, key, []);
end;

procedure TRemoteForm.FormDestroy(Sender: TObject);
begin
        KeyNameStrings.Free;
        RequestNameStrings.Free;
        CommandNameStrings.Free;
end;

{ keep picking up requests from the queue }
procedure TRemoteForm.QueueTimerTimer(Sender: TObject);
begin
        DequeueCmd;
end;

end.
