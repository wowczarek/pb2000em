{ 8-bit port and external peripheral devices }

unit Port;

interface

  var
    pd, pe, pdi: byte;
    OptionCode: byte;
  function ReadPd : byte;
  procedure WritePd;
  procedure IoInit;
  procedure IoClose;
  function IoWrPtr (index: integer) : pointer;
  function IoRdPtr (index: integer) : pointer;
  { serial port support }
  procedure SerialTxByte;
  procedure SerialPoll;


implementation

  uses Def, Main, SysUtils,Serial;

var
  RegRdData, RegWrData, FddWrData, FddRdData, SerialWrData, SerialRdData, OldPort: byte;
  SerialRxBuffer: Array[0..255] of byte;

function GetPort: byte;
begin
  GetPort := (pd and pe) or (pdi and not pe);
end {GetPort};


function ReadPd : byte;
begin
  ReadPd := GetPort;
end {ReadPd};


procedure WritePd;
var
  x: byte;
begin
  x := GetPort;
  if (x and PD_PWR) = $00 then		{ interface is powered }
  begin

    if (OldPort and PD_PWR) <> $00 then	{ PD_PWR has changed from 1 to 0 }
    begin
      with MainForm.FddSocket do
      begin
        if (OptionCode = OC_MD100)
		and (Address <> '') and (Port <> 0) then Open;
      end {with};
    end {if};

    if (x and PD_RES) = $00 then
    begin
      if (OldPort and PD_RES) <> $00 then { PD_RES has changed from 1 to 0 }
        FddRdData := OptionCode;

      with MainForm.FddSocket.Socket do
      begin
        if Connected then
        begin
          if (x and PD_STR) = $00 then	{ transfer direction strobe }
          begin
            if (OldPort and PD_STR) <> $00 then { PD_STR has changed from 1 to 0 }
            begin
              SendBuf (FddWrData, 1);
              ReceiveBuf (FddRdData, 1);
              pdi := pdi or PD_ACK;
            end {if};
          end
          else
          begin
            pdi := pdi and not PD_ACK;
          end {if};
        end {if};
      end {with}
    end {if};
  end

  else				{ PD_PWR = 1, interface is not powered }
  begin
    if (OldPort and PD_PWR) = $00 then	{ PD_PWR has changed from 0 to 1 }
      IoClose;
  end {if};

  OldPort := GetPort;
end {WritePd};


procedure IoInit;
begin
  OldPort := GetPort;
  FddRdData := OptionCode;
  with MainForm.FddSocket do
  begin
    if ((Address = '') or (Port = 0)) and (MainForm.SerialPort = 0) then OptionCode := OC_NONE;
  end {with};
end {IoInit};


procedure IoClose;
begin
  MainForm.FddSocket.Close;
end {IoClose};

{ transmit a byte out through serial port }
procedure SerialTxByte;
begin
        SerialForm.txByte(SerialWrData);
end;

{ ask to be notified of incoming serial port data }
procedure SerialPoll;
begin
        { execute a delayed serial poll }
        SerialForm.RxPoll(true);
end;

function IoWrPtr (index: integer) : pointer;
begin
  IoWrPtr := @dummydst;
  if (GetPort and (PD_PWR or PD_RES)) = $00 then
  begin
    case index of
      { address 3, write: transmit a byte via serial port, but only if using MD-100 or FA-7 }
      3: if (OptionCode = OC_FA7) or (OptionCode = OC_MD100) then
        begin
                IoWrPtr := @SerialWrData;
                procptr := @SerialTxByte;
        end;
      { address 4, write: FDD output port }
      4: IoWrPtr := @FddWrData;
    end {case};
  end {if};
end {IoWrPtr};


function IoRdPtr (index: integer) : pointer;
begin
  IoRdPtr := @dummysrc;
  if (GetPort and (PD_PWR or PD_RES)) = $00 then
  begin
    case index of
      { address 0, read: advertise CTS+DSR+DCD on RS-232 }
      0: if (OptionCode = OC_FA7) or (OptionCode = OC_MD100) then
        begin
                RegRdData := RS_CTS or RS_DSR or RS_DCD;
                IoRdPtr := @RegRdData;
        end;
      { address 1, read: no errors, SW1..SW3 = 111, low = 000 (9600 baud ) }
      1: begin
                RegRdData := $00; { $38; when SW1..SW3 = 000 }
                IoRdPtr := @RegRdData;
        end;
      { address 2, read: serial port data }
      2: if (OptionCode = OC_FA7) or (OptionCode = OC_MD100) then
         begin
                { only read from serial port if INT1 unmasked, dequeue a byte if there is one to dequeue }
                if ((ib and INT1_bit) <> 0) and SerialForm.RxDequeue(SerialRdData) then
                begin
                        IoRdPtr := @SerialRdData;
                end;
         end;
      { address 3, read: FDD input port, will have the OptionCode on device reset }
      3: IoRdPtr := @FddRdData;
    end {case};
  end {if};
end {IoRdPtr};

end.
