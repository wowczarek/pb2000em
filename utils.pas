unit Utils;

interface

uses
  Classes, SysUtils, ThdTimer;

type

  TQueuePolicy = ( QPNone, QPWait );

  { The Byte Pump is a FIFO queue, which can be chained with another two queues,        }
  { in a sink-source fashion:                                                           }
  {     - when data is dequeued from a sink, it will pull more from its source,         }
  {     - when data is enqueued to a source, it will push some of it to the sink        }
  { when and how much of the push / pull is done, depends on queue control mode:        }
  {     - QPNone:       propagate immediately                                           }
  {     - QPWait:       sink is only filled when sink it gets emptied, after an optional delay }
  { when no sink or source is defined, it works like a regular, single FIFO queue       }

  TBytePump = class
  private
        { temporary buffer for pumping data }
        Pipe: Array of byte;
        { ring buffer }
        Data : Array of byte;
        { cogs }
        _Capacity: Integer;
        _Count: Integer;
        _Left: Integer;
        ReadPos: Integer;
        WritePos: Integer;
        _FillLevel: Integer;
        _Source: TBytePump;
        _Sink: TBytePump;
        _Delay: Integer;
        _Ready: Boolean;
        Waiting: Boolean;
        Timer: TThreadedTimer;
        WakeUpTimer: TTHreadedTimer;
        procedure SetFillLevel(l: integer);
        procedure SetDelay(d: integer);
        { the actual moving of data, but without pumping }
        function _Enqueue(var src: array of byte; len: Integer): Integer;
        function _Dequeue(var dst: array of byte; len: Integer): Integer;
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
        property Capacity: Integer read _Capacity;
        property Count: Integer read _Count;
        property Left: Integer read _Left;
        property FillLevel: Integer read _FillLevel write SetFillLevel;
        property Delay: Integer read _Delay write SetDelay;
        property Ready: Boolean read _Ready;
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
   Source._Sink := Sink;
   Sink._Source := Source;

end;

{ detach two pumps if they are connected, in whichever way }
procedure UnlinkPumps(a: TBytePump; b: TBytePump);
begin


        if (a._Source = b) and (b._Sink = a)
        then begin
                a._Source := Nil;
                b._Sink := Nil;
        end;

        if (a._Sink = b) and (b._Source = a)
        then begin
                a._Sink := Nil;
                b._Source := Nil;
        end;

end;

constructor TBytePump.Create(Capacity: Integer);
begin
        _Capacity       := 0;
        if Capacity <= 0 then exit;
        SetLength(Data, Capacity);
        SetLength(Pipe, Capacity);
        _Capacity       := Capacity;
        ReadPos         := 0;
        WritePos        := 0;
        _Count          := 0;
        _Left           := Capacity;
        _FillLevel      := Capacity;
        _Source         := Nil;
        _Sink           := Nil;
        Waiting         := False;
        _Ready          := True;
        QueuePolicy     := QPNone;
        Timer           := TThreadedTimer.Create(nil);
        Timer.Interval  := 1;
        WakeUpTimer     := TThreadedTimer.Create(nil);
        WakeUpTimer.Interval := 1;
        _Delay          := 0;
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
        if l < 0 then l := _Capacity;
        if l <= _Capacity then _FillLevel := l
        else _FillLevel := _Capacity;
        SetLength(Pipe, _FillLevel);
end;

procedure TBytePump.OnTimer(Sender: TObject);
begin
        Timer.Enabled := False;
        _Ready := True;
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
                _Delay := d;
                Timer.Interval := Delay;
                WakeUpTimer.Interval := Delay;
        end else _Delay := 0;
end;

{ flush this queue }
procedure TBytePump.Flush;
begin
        ReadPos := 0;
        WritePos := 0;
        _Count := 0;
        _Left := _Capacity;
        Waiting := False;
        _Ready := True;
end;

{ flush this queue and chain flush downwards }
procedure TBytePump.Purge;
begin
        Flush;
        if assigned(_Sink) then _Sink.Purge;
end;


procedure TBytePump.Source(src: TBytePump);
begin
        _Source := src;
        if assigned(_Source) then _Source._Sink := Self;
end;

procedure TBytePump.Sink(snk: TBytePump);
begin
        _Sink := snk;
        if assigned(_Sink) then _Sink._Source := Self;
end;

{ break linkage towards sink }
procedure TBytePump.UnplumbSink;
begin
        if assigned(_Sink) then
        begin
                _Sink._Source := Nil;
        end;
        _Sink := Nil;
end;

{ break linkage towards source }
procedure TBytePump.UnplumbSource;
begin
        if assigned(_Source) then
        begin
                _Source._Sink := Nil;
        end;
        _Source := Nil;
end;

{ breake linkage in both directions but fuse them together }
procedure TBytePump.Unplumb;
begin
        if assigned(_Source) then
        begin
                _Sink._Source := _Source;
                if assigned(_Sink) then _Source._Sink := _Sink;
                _Source := Nil;
        end;

        if assigned(_Sink) then
        begin
                if assigned(_Source) then _Sink._Source := _Source;
                _Sink := Nil;
        end;
end;

{ pull data from source if ready }
procedure TBytePump.Pump;
var
        FillLeft,len: integer;
begin

        if not assigned(_Source) or (_Left < 1) then exit;

        case QueuePolicy of

                { Wait: only pull more data through the pipe if we're ready }
                QPWait: begin
                                FillLeft := _FillLevel - _Count;
                                if FillLeft < 1 then FillLeft := 0;
                                if Ready and (FillLeft > 0) then begin
                                        len := _Source.Dequeue(Pipe, FillLeft);
                                        Enqueue(Pipe, len);
                                end;
                end;

                { None: always attempt to pull data from source }
                QPNone: begin
                        len := _Source.Dequeue(Pipe, _Left);
                        Enqueue(Pipe, len);
                end;

        end;

end;

{ enqueue data }
function TBytePump._Enqueue(var src: array of byte; len: Integer): Integer;
var
        toEnd: Integer;
begin

        Result := 0;

        if len <  1 then exit;

        if (QueuePolicy = QPWait) and (not Ready) then exit;

        { no space left }
        if _Left <= 0 then exit;
        { some space left but not enough - only enqueue what we can }
        if _Left < len then len := _Left;

        { only fill up to fill level, no more }
        if QueuePolicy = QPWait then
        begin
            if ((len + _Count) >= _FillLevel) then len := _FillLevel - _Count;
            { queue fill level reached }
            if len <= 0 then
            begin
                if assigned(OnReady) then OnReady(Self);
                exit;
            end;
        end;

        toEnd := _Capacity - WritePos;

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
        WritePos := WritePos mod _Capacity;
        Inc(_Count, len);
        Dec(_Left, len);

        { we reached our fill level - stop pumping notify }
        if (QueuePolicy = QPWait) and (_Count >= _FillLevel) then
        begin
                _Ready := False;
                WakeUpTimer.Enabled := True;
        end;

        if (len > 0) and Ready and assigned(OnReady) then OnReady(Self);

        Result := len;

end;

{ public enqueue - enqueue and pump }
function TBytePump.Enqueue(var src: array of byte; len: Integer): Integer;
begin
        Result := _Enqueue(src,len);
        { triger a data pump to sink }
        if (Result > 0) and assigned(_Sink) then _Sink.Pump;
end;

{ dequeue some data }
function TBytePump._Dequeue(var dst: array of byte; len: Integer): Integer;
var
        toEnd: Integer;
begin
        Result := 0;

        { no data queued }
        if _Count < 1 then exit;

        { some data queued but less than what we wanted - only dequeue what we can }
        if  len > _Count then len := _Count;

        toEnd := _Capacity - ReadPos;
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
        ReadPos := ReadPos mod _Capacity;
        Dec(_Count, len);
        Inc(_Left, len);

        { queue emptied - delay notification if delay specified }
        if (QueuePolicy = QPWait) and (_Count = 0) then
        begin
                if Delay > 0 then
                begin
                        _Ready := False;
                         Timer.Enabled := True
                end else begin
                        _Ready := True;
                end;
        end;

        Result := len;

end;

{ public dequeue - dequeue and pump }
function TBytePump.Dequeue(var dst: array of byte; len: Integer): Integer;
begin

        Result := _Dequeue(dst, len);

        { pull from source }
        if (Result > 0) and assigned(_Source) then Pump;
end;

end.
