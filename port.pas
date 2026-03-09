{ 8-bit port and external peripheral devices }

unit Port;

interface

  var
    pd, pe, pdi: byte;
    SerialRate: integer = 10000;	{ value not important, but not 0 }

  function ReadPd : byte;
  procedure WritePd;
  procedure IoInit;
  procedure IoClose;
  function IoWrPtr (index: integer) : pointer;
  function IoRdPtr (index: integer) : pointer;
  procedure OnSerialTick;

implementation

  uses Def, Main, Cpu, Comm, Fdd;

var
  io_wr: array[0..7] of byte = ( 0, 0, 0, 0, 0, $FF, $03, 0 );
  io_rd: array[0..7] of byte = ( $C0, $38, $1A, $55, $06, $00, $00, $00 );
  SerialLength: integer = 0;
  TxCounter: integer = 0;
  RxCounter: integer = 0;
  RxData: integer;
  OldPort: byte;
  OldPrnCtrl: byte;

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
    if (x and PD_RES) = $00 then
    begin
      if (OldPort and PD_RES) <> $00 then { PD_RES has changed from 1 to 0 }
      begin
        io_rd[3] := $55;
      end {if};
      if (x and PD_STR) = $00 then	{ transfer direction strobe }
      begin
        if (OldPort and PD_STR) <> $00 then { PD_STR has changed from 1 to 0 }
        begin
          io_rd[3] := FddTransfer (io_wr[4]);
          pdi := pdi or PD_ACK;
        end {if};
      end
      else
      begin
        pdi := pdi and not PD_ACK;
      end {if};
    end {if};
  end {if};
  OldPort := GetPort;
end {WritePd};


procedure IoInit;
begin
  OldPort := GetPort;
  OldPrnCtrl := io_wr[6];
end {IoInit};


procedure IoClose;
begin
end {IoClose};


procedure OnWriteDataReg;
begin
  if ((io_wr[1] and $01) <> 0)	{transmitter enabled}
  and ((io_wr[0] and $01) = 0)	{no MT}
  then
  begin
    io_rd[0] := io_rd[0] or $01;	{TX buffer full}
    TxCounter := SerialLength;
  end {if};
end {OnWriteDataReg};


procedure SerialSetting;
const
  baud_div: array[0..7] of integer = (
	(1000 * XTAL ) div 9600,
	(1000 * XTAL ) div 4800,
	(1000 * XTAL ) div 2400,
	(1000 * XTAL ) div 1200,
	(1000 * XTAL ) div 600,
	(1000 * XTAL ) div 300,
	(1000 * XTAL ) div 150,
	(1000 * XTAL ) div 75 );
begin
  SerialRate := baud_div[(io_wr[0] shr 5) and 7];
  SerialLength := 9;	{ 1 start bit + 7 data bits + 1 stop bit }
  if (io_wr[0] and $08) = 0 then Inc(SerialLength);	{ 8 data bits }
  if (io_wr[0] and $04) = 0 then Inc(SerialLength);	{ 1 parity bit }
  if (io_wr[0] and $10) = 0 then Inc(SerialLength);	{ 2 stop bits }
end {SerialSetting};


procedure OnWritePrnCtrlReg;
begin
  if (io_wr[6] and $04) <> 0 then io_rd[4] := io_rd[4] and $FB;	{ clear ACK }
  if ((io_wr[6] and $01) <> 0) and ((OldPrnCtrl and $01) = 0) then
{ Printer Strobe has changed from 0 to 1 }
  begin
    CommWrite (io_wr[5]);
    io_rd[4] := io_rd[4] or $04;	{ set ACK }
  end {if};
  OldPrnCtrl := io_wr[6];
end {OnWritePrnCtrlReg};


function IoWrPtr (index: integer) : pointer;
begin
  index := index and 7;
  IoWrPtr := @io_wr[index];
  case index of
    0: begin
         procptr[procindex] := @SerialSetting;
         Inc(procindex);
       end;
    3: begin
         procptr[procindex] := @OnWriteDataReg;
         Inc(procindex);
       end;
    6: begin
         procptr[procindex] := @OnWritePrnCtrlReg;
         Inc(procindex);
       end;
  end {case};
end {IoWrPtr};


function IoRdPtr (index: integer) : pointer;
begin
  IoRdPtr := @io_rd[index and 7];
{ clear the errors and the RX buffer full flag upon reading the data register }
  if index = 2 then
  begin
    io_rd[0] := io_rd[0] and $DD;
    io_rd[1] := io_rd[1] and $F8;
    ky := ky or $0800;		{release INT1}
  end {if};
end {IoRdPtr};


{ called at the serial bit rate }
procedure OnSerialTick;
begin
  if TxCounter > 0 then
  begin
    Dec(TxCounter);
    if TxCounter = 0 then
    begin
      CommWrite (io_wr[3]);
      io_rd[0] := io_rd[0] and $FE;	{transmitter ready}
    end {if};
  end {if};

  if ((io_wr[1] and $02) <> 0)	{receiver enabled}
  and ((io_wr[0] and $01) = 0)	{no MT}
  then
  begin
    if RxCounter = 0 then
    begin
      RxData := CommRead;
      if RxData >= 0 then RxCounter := SerialLength;
    end {if};
    if RxCounter > 0 then
    begin
      Dec(RxCounter);
      if RxCounter = 0 then
      begin
        io_rd[2] := byte(RxData);
        if (io_wr[2] and $01) <> 0 then ky := ky and not $0800;	{trigger INT1}
        if (io_rd[0] and $02) = 0 then	{is RX ready?}
        begin
          io_rd[0] := io_rd[0] or $02;	{RX buffer full}
        end
        else
        begin
          io_rd[0] := io_rd[0] or $20;	{general receive error}
          io_rd[1] := io_rd[1] or $02;	{overrun error}
        end {if};
      end {if};
    end {if};
  end {if};
end {OnSerialTick};

end.

