unit Utils;

interface

uses
  Classes, SysUtils, ThdTimer;

type

  TQueuePolicy = ( QPNone, QPWait );

  { The Byte Pump is a FIFO queue, which can be chained with another two queues,  }
  { in a sink-source fashion:                                                     }
  {     - when data is dequeued from a sink, it will pull more from its source    }
  {     - when data is enqueued to a source, it cause the sink to pull data       }
  { when and how much of the push / pull is done, depends on queue control mode:  }
  {     - QPNone:       propagate immediately                                     }
  {     - QPWait:       sink is only filled when sink it gets emptied, after an   }
  {       optional delay                                                          }
  { when no sink or source is defined, it works like a regular, single FIFO queue }

  TBytePump = class
  private
        { temporary buffer for pumping data }
        Pipe: Array of byte;
        { ring buffer }
        Data : Array of byte;
        { cogs }
        FCapacity: Integer;
        FCount: Integer;
        FLeft: Integer;
        ReadPos: Integer;
        WritePos: Integer;
        FFillLevel: Integer;
        FSource: TBytePump;
        FSink: TBytePump;
        FDelay: Integer;
        FReady: Boolean;
        Waiting: Boolean;
        Timer: TThreadedTimer;
        WakeUpTimer: TTHreadedTimer;
        procedure SetFillLevel(l: integer);
        procedure SetDelay(d: integer);
        { the actual moving of data, but without pumping }
        function FEnqueue(var src: array of byte; len: Integer): Integer;
        function FDequeue(var dst: array of byte; len: Integer): Integer;
        { pump from source }
        procedure Pump;
        procedure OnTimer(Sender: TObject);
        procedure OnWakeUpTimer(Sender: TObject);

  public

        QueuePolicy: TQueuePolicy;
        OnReady: TNotifyEvent;
        Name: String;
        procedure Flush;
        procedure Purge;
        { move data and trigger a chain of pump actions }
        function Enqueue(var src: array of byte; len: Integer): Integer;
        function Dequeue(var dst: array of byte; len: Integer): Integer;
        procedure Source(src: TBytePump);
        procedure Sink(snk: TBytePump);
        procedure UnplumbSource;
        procedure UnplumbSink;
        procedure Unplumb;
        property Capacity: Integer read FCapacity;
        property Count: Integer read FCount;
        property Left: Integer read FLeft;
        property FillLevel: Integer read FFillLevel write SetFillLevel;
        property Delay: Integer read FDelay write SetDelay;
        property Ready: Boolean read FReady;
        constructor Create(Capacity: Integer);
        destructor  Destroy; override;
  end;

  procedure LinkPumps(Source: TBytePump; Sink: TBytePump);
  procedure UnlinkPumps(a: TBytePump; b: TBytePump);

implementation
uses Serial;
procedure LinkPumps(Source: TBytePump; Sink: TBytePump);
begin

   { do not allow a closed loop - TODO: walk the whole pipage and detect loops }
   if Sink = Source then exit;
   Source.FSink := Sink;
   Sink.FSource := Source;

end;

{ detach two pumps if they are connected, in whichever way }
procedure UnlinkPumps(a: TBytePump; b: TBytePump);
begin


        if (a.FSource = b) and (b.FSink = a)
        then begin
                a.FSource := Nil;
                b.FSink := Nil;
        end;

        if (a.FSink = b) and (b.FSource = a)
        then begin
                a.FSink := Nil;
                b.FSource := Nil;
        end;

end;

constructor TBytePump.Create(Capacity: Integer);
begin
        FCapacity       := 0;
        if Capacity <= 0 then exit;
        SetLength(Data, Capacity);
        SetLength(Pipe, Capacity);
        FCapacity       := Capacity;
        ReadPos         := 0;
        WritePos        := 0;
        FCount          := 0;
        FLeft           := Capacity;
        FFillLevel      := Capacity;
        FSource         := Nil;
        FSink           := Nil;
        Waiting         := False;
        FReady          := True;
        QueuePolicy     := QPNone;
        Timer           := TThreadedTimer.Create(nil);
        Timer.Interval  := 1;
        WakeUpTimer     := TThreadedTimer.Create(nil);
        WakeUpTimer.Interval := 1;
        FDelay          := 0;
        Timer.Enabled   := False;
        WakeUpTimer.Enabled := False;
        Timer.OnTimer := OnTimer;
        WakeUpTimer.OnTimer := OnWakeUpTimer;
end;

destructor TBytePump.Destroy;
begin
        Unplumb;
end;

procedure TBytePump.SetFillLevel(l: Integer);
begin
        if l < 0 then l := FCapacity;
        if l <= FCapacity then FFillLevel := l
        else FFillLevel := FCapacity;
        SetLength(Pipe, FFillLevel);
end;

procedure TBytePump.OnTimer(Sender: TObject);
begin
        Timer.Enabled := False;
        FReady := True;
        Pump;
        if assigned(OnReady) then OnReady(Self);

end;

procedure TBytePump.OnWakeUpTimer(Sender: TObject);
begin
        WakeUpTimer.Enabled := False;
        if assigned(OnReady) then OnReady(Self);
end;


procedure TBytePump.SetDelay(d: Integer);
begin
        if d > 0 then
        begin
                FDelay := d;
                Timer.Interval := Delay;
                WakeUpTimer.Interval := Delay;
        end else FDelay := 0;
end;

{ flush this queue }
procedure TBytePump.Flush;
begin
        ReadPos := 0;
        WritePos := 0;
        FCount := 0;
        FLeft := FCapacity;
        Waiting := False;
        FReady := True;
end;

{ flush this queue and chain flush downwards }
procedure TBytePump.Purge;
begin
        Flush;
        if assigned(FSink) then FSink.Purge;
end;


procedure TBytePump.Source(src: TBytePump);
begin
        FSource := src;
        if assigned(FSource) then FSource.FSink := Self;
end;

procedure TBytePump.Sink(snk: TBytePump);
begin
        FSink := snk;
        if assigned(FSink) then FSink.FSource := Self;
end;

{ break linkage towards sink }
procedure TBytePump.UnplumbSink;
begin
        if assigned(FSink) then
        begin
                FSink.FSource := Nil;
        end;
        FSink := Nil;
end;

{ break linkage towards source }
procedure TBytePump.UnplumbSource;
begin
        if assigned(FSource) then
        begin
                FSource.FSink := Nil;
        end;
        FSource := Nil;
end;

{ breake linkage in both directions but fuse them together }
procedure TBytePump.Unplumb;
begin
        if assigned(FSource) then
        begin
                if assigned(FSink) then FSource.FSink := FSink;
                FSource := Nil;
        end;

        if assigned(FSink) then
        begin
                if assigned(FSource) then FSink.FSource := FSource;
                FSink := Nil;
        end;
end;

{ pull data from source if ready }
procedure TBytePump.Pump;
var
        FillLeft,len: integer;
begin

        if not assigned(FSource) or (FLeft < 1) then exit;

        case QueuePolicy of

                { Wait: only pull more data through the pipe if we're ready }
                QPWait: begin
                                FillLeft := FFillLevel - FCount;
                                if FillLeft < 1 then FillLeft := 0;
                                if Ready and (FillLeft > 0) then begin
                                        len := FSource.Dequeue(Pipe, FillLeft);
                                        Enqueue(Pipe, len);
                                end;
                end;

                { None: always attempt to pull data from source }
                QPNone: begin
                        len := FSource.Dequeue(Pipe, FLeft);
                        Enqueue(Pipe, len);
                end;

        end;

end;

{ enqueue data }
function TBytePump.FEnqueue(var src: array of byte; len: Integer): Integer;
var
        toEnd: Integer;
begin

        Result := 0;

        if len <  1 then exit;

        if (QueuePolicy = QPWait) and (not Ready) then exit;

        { no space left }
        if FLeft <= 0 then exit;
        { some space left but not enough - only enqueue what we can }
        if FLeft < len then len := FLeft;

        { only fill up to fill level, no more }
        if QueuePolicy = QPWait then
        begin
            if ((len + FCount) >= FFillLevel) then len := FFillLevel - FCount;
            { queue fill level reached }
            if len <= 0 then
            begin
                if assigned(OnReady) then OnReady(Self);
                exit;
            end;
        end;

        toEnd := FCapacity - WritePos;

        { we can append to the end }
        if len <= toEnd then
        begin
                Move(src[0], Data[WritePos], len);
        end
        { we need to wrap around }
        else begin
                Move(src[0], Data[WritePos], toEnd);
                Move(src[toEnd], Data[0], len - toEnd);
        end;

        Inc(WritePos, len);
        WritePos := WritePos mod FCapacity;
        Inc(FCount, len);
        Dec(FLeft, len);

        { we reached our fill level - stop pumping notify }
        if (QueuePolicy = QPWait) and (FCount >= FFillLevel) then
        begin
                FReady := False;
                WakeUpTimer.Enabled := True;
        end;

        if (len > 0) and Ready and assigned(OnReady) then OnReady(Self);

        Result := len;

end;

{ public enqueue - enqueue and pump }
function TBytePump.Enqueue(var src: array of byte; len: Integer): Integer;
begin
        Result := FEnqueue(src,len);
        { triger a data pump to sink }
        if (Result > 0) and assigned(FSink) then FSink.Pump;
end;

{ dequeue some data }
function TBytePump.FDequeue(var dst: array of byte; len: Integer): Integer;
var
        toEnd: Integer;
begin
        Result := 0;

        { no data queued }
        if FCount < 1 then exit;

        { some data queued but less than what we wanted - only dequeue what we can }
        if  len > FCount then len := FCount;

        toEnd := FCapacity - ReadPos;
        { we can read to the end }
        if len <= toEnd then
        begin
              Move(Data[ReadPos], dst[0], len);
        end
        { we need to wrap around }
        else begin
              Move(Data[ReadPos], dst[0], toEnd);
              Move(Data[0], dst[toEnd], len - toEnd);
        end;

        Inc(ReadPos, len);
        ReadPos := ReadPos mod FCapacity;
        Dec(FCount, len);
        Inc(FLeft, len);

        { queue emptied - delay notification if delay specified }
        if (QueuePolicy = QPWait) and (FCount = 0) then
        begin
                if Delay > 0 then
                begin
                        FReady := False;
                         Timer.Enabled := True
                end else begin
                        FReady := True;
                end;
        end;

        Result := len;

end;

{ public dequeue - dequeue and pump }
function TBytePump.Dequeue(var dst: array of byte; len: Integer): Integer;
begin

        Result := FDequeue(dst, len);

        { pull from source }
        if (Result > 0) and assigned(FSource) then Pump;
end;

end.
