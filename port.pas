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


implementation

  uses Def, Main;

var
  FddWrData, FddRdData, OldPort: byte;

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
        if (OptionCode = $55)
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
    if (Address = '') or (Port = 0) then OptionCode := $FF;
  end {with};
end {IoInit};


procedure IoClose;
begin
  MainForm.FddSocket.Close;
end {IoClose};


function IoWrPtr (index: integer) : pointer;
begin
  IoWrPtr := @dummydst;
  if (GetPort and (PD_PWR or PD_RES)) = $00 then
  begin
    case index of
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
      3: IoRdPtr := @FddRdData;
    end {case};
  end {if};
end {IoRdPtr};


end.
