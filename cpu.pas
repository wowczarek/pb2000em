unit Cpu;

interface

  procedure CpuReset;
  procedure ResetAll;
  procedure CpuWakeUp (apo_value: boolean);
  procedure SetIfl (int_bit: byte);
  function CpuRun : integer;


implementation

  uses Def, Decoder, Port, Serial, Lcd;

  type Proc1 = procedure;

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

  procedure CpuReset;
  begin
    procptr := nil;
    pc := $0000;
    ua := 0;
    delayed_ua := ua;
    ky := $0C00;
    delayed_ky := ky;
    ie := 0;
    ia := 0;
    ib := 0;
    iserv := 0;
    speed := 0;
    acycles := 0;
  end {CpuReset};


  procedure CpuWakeUp (apo_value: boolean);
  begin
    if not CpuSleep then Exit;

    if apo_value then
      flag := flag or APO_bit
    else
      flag := flag and not APO_bit;
    speed := 0;
    acycles := 0;
    CpuSleep := False;
    { HACK: tell the serial port module we've woken up }
    SerialForm.SerialEnabled(true);
  end {CpuWakeUp};


{ set the interrupt request flag in the IB register if the interrupt is
  enabled }
  procedure SetIfl (int_bit: byte);
  begin
    if ((ie shr 3) and int_bit) <> 0 then
      ib := ib or int_bit;
{ the system can be waken-up by an One-Minute Timer interrupt ... }
    if ((ib and (MINTIMER_bit or $20)) = (MINTIMER_bit or $20)) or
{ ... or through the ON terminal }
    ((int_bit = ONINT_bit) and ((ie and $04) <> 0)) then
      CpuWakeUp (True);
  end {SetIfl};

{ execute a single instruction, returns number of clock cycles }
  function CpuRun : integer;
  var
    i: integer;
  begin

    cycles := 0;
    if CpuSleep then Inc (cycles, 6) else
    begin
{ is there a pending interrupt request of higher priority than currently serviced? }
      if (ib and $1F and not iserv) > iserv then
{ handle an interrupt }
      begin
        Dec (ss);		{ push the return address on the stack }
        DstPtr(Addr18(ua shr 2, ss))^ := Hi (pc);
        Dec (ss);
        DstPtr(Addr18(ua shr 2, ss))^ := Lo (pc);
        for i:=0 to INTVECTORS-1 do
        begin
          if (ib and intmask[i]) <> 0 then
          begin
            iserv := iserv or intmask[i];
            pc := intvec[i];
            opindex := 0;	{prevents subsequent PC alignment}
            Break;
          end {if};
        end {for};
        Inc (cycles, 11);
        if (ua and 3) <> 0 then Inc (cycles);
      end
      else
      begin
{ execute an instruction }
        ExecInstr;
{ complete an optional I/O device write }
        if procptr <> nil then
        begin
          Proc1(procptr);
          procptr := nil;
        end {if};
      end {if};
    end {if};
    if iserv = 0 then cycles := cycles shl speed;
    CpuRun := cycles;
  end {CpuRun};

end.
