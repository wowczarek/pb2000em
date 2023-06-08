unit Utils;

interface

uses
  SysUtils;

type

  TQueueControl = ( QCNone, QCMaintain, QCWait );
  PBytePump = ^TBytePump;

  { The Byte Pump is a FIFO queue, which can be chained with another two queues,        }
  { in a sink-source fashion:                                                           }
  {     - when data is dequeued from the sink, it will pull more from its source,       }
  {     - when data is enqueued to the source, it will push some of it to the sink      }
  { when and how much of the push / pull is done, depends on queue control mode:        }
  {     - QCNone:       nothing happens                                                 }
  {     - QCMaintain:   always maintain sink's fill level as long as source has data    }
  {     - QCWait:       sink is only filled when sink it gets emptied                   }
  { when no sink or source is defined, it works like a regular, single FIFO queue       }

  TBytePump = class
  private
        { ring buffer }
        Data : Array of byte;
        { temporary buffer for pumping data }
        Pipe: Array of byte;
        { cogs }
        _Capacity: Integer;
        _Count: Integer;
        _Left: Integer;
        ReadPos: Integer;
        WritePos: Integer;
        _FillLevel: Integer;
        _Source: PBytePump;
        _Sink: PBytePump;
        { the actual moving of data, but without pumping }
        function _Enqueue(var src; len: Integer): Integer;
        function _Dequeue(var dst; len: Integer): Integer;
        { pump from source }
        procedure Pump;

  public
        ControlType: TQueueControl;

        procedure Flush;
        procedure SetFillLevel(l: integer);

        { move data and trigger a chain of pump actions }
        function Enqueue(var src; len: Integer): Integer;
        function Dequeue(var dst; len: Integer): Integer;

        procedure Source(var src: TBytePump);
        procedure Sink(var snk: TBytePump);
        procedure UnplumbSource;
        procedure UnplumbSink;
        procedure Unplumb;

        property Capacity: Integer read _Capacity;
        property Count: Integer read _Count;
        property Left: Integer read _Left;
        property FillLevel: Integer read _FillLevel;

        constructor Create(Capacity: Integer);
        destructor  Destroy; override;
  end;

  procedure LinkPumps(var Source: TBytePump; var Sink: TBytePump);
  procedure UnlinkPumps(var pa: TBytePump; var pb: TBytePump);

implementation

procedure LinkPumps(var Source: TBytePump; var Sink: TBytePump);
begin

   { do not allow a closed loop - TODO: walk the whole pipage and detect loops }
   if PBytePump(@Sink) = PBytePump(@Source) then exit;
   Source._Sink := PBytePump(@Sink);
   Sink._Source := PBytePump(@Source);

end;

{ detach two pumps if they are connected, in whichever way }
procedure UnlinkPumps(var pa: TBytePump; var pb: TBytePump);
var
        a, b: PBytePump;
begin

        a := PBytePump(@pa);
        b := PBytePump(@pb);

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
        _Capacity       := Capacity;
        ReadPos         := 0;
        WritePos        := 0;
        _Count          := 0;
        _Left           := Capacity;
        _FillLevel      := 0;
        _Source         := Nil;
        _Sink           := Nil;
        ControlType     := QCNone;
end;

destructor TBytePump.Destroy;
begin
        Unplumb;
end;

procedure TBytePump.SetFillLevel(l: Integer);
begin
        if l < 0 then exit;

        if l <= _Capacity then _FillLevel := l
        else _FillLevel := _Capacity;

        SetLength(Pipe, _FillLevel);
end;

{ pull data from source }
procedure TBytePump.Pump;
var
        len: integer;
begin

        if (_Source = Nil) or (_FillLevel <=  0) then exit;

        case ControlType of

                { Maintain: pull more data through rhe pipe as long as we're not up to fill level }
                QCMaintain: if _Count < _FillLevel then begin
                        len := _Source.Dequeue(Pipe, _FillLevel);
                        Self.Enqueue(Pipe, len);
                end;
                { Wait: only pull more data through the pipe if we're empty }
                QCWait: if _Count = 0 then begin
                        len := _Source.Dequeue(Pipe, _FillLevel);
                        Self.Enqueue(Pipe, len);
                end;
                { None: always attempt to pull data from source }
                QCNone: begin
                        len := _Source.Dequeue(Pipe, _FillLevel);
                        Self.Enqueue(Pipe, len);
                end;

        end;

end;

procedure TBytePump.Flush;
begin
        ReadPos := 0;
        WritePos := 0;
        _Count := 0;
        _Left := _Capacity;
end;

procedure TBytePump.Source(var src: TBytePump);
begin
        _Source := PBytePump(@src);
end;

procedure TBytePump.Sink(var snk: TBytePump);
begin
        _Sink := PBytePump(@snk);
end;

{ break linkage towards sink }
procedure TBytePump.UnplumbSink;
begin
        if _Sink <> Nil then
        begin
                _Sink._Source := Nil;
        end;
        _Sink := Nil;
end;

{ break linkage towards source }
procedure TBytePump.UnplumbSource;
begin
        if _Source <> nil then
        begin
                _Source._Sink := Nil;
        end;
        _Source := Nil;
end;

{ breake linkage in both directions but fuse them together }
procedure TBytePump.Unplumb;
begin
{        if (_Source <> Nil) and (_Source._Source <> Nil) then
        begin

        end;
        if (_Sink <> Nil) and (_Sink._Sink <> Nil) then
        begin
        end;
}
end;

function TBytePump._Enqueue(var src; len: Integer): Integer;
type
        asrc = array of byte;
var
        toEnd: Integer;
begin
        Result := 0;

        { no space left }
        if _Left <= 0 then exit;
        { some space left but not enough - only enqueue what we can }
        if _Left < len then len := _Left;

        toEnd := _Capacity - WritePos;
        { we can append to the end }
        if len <= toEnd then
        begin
                Move(src,        Data[WritePos], len);
        end
        { we need to wrap around }
        else begin
                Move(src,        Data[WritePos], toEnd);
                Move(asrc(src)[toEnd], Data,           len - toEnd);
        end;

        Inc(WritePos, len);
        WritePos := WritePos mod _Capacity;
        Inc(_Count, len);
        Dec(_Left, len);

        Result := len;

end;


function TBytePump.Enqueue(var src; len: Integer): Integer;
begin
        Result := _Enqueue(src,len);
        { triger a data pump to sink }
        if (Result > 0) and (_Sink <> Nil) then _Sink.Pump;
end;

function TBytePump._Dequeue(var dst; len: Integer): Integer;
type
        adst = array of byte;
var
        toEnd: Integer;
begin
        Result := 0;

        { no data queued }
        if _Count <= 0 then exit;
        { some dara queued but less than what we wanted - only dequeue what we can }
        if _Count < len then len := _Count;

        toEnd := _Capacity - ReadPos;
        { we can read to the end }
        if len <= toEnd then
        begin
              Move(Data[ReadPos], dst,        len);
        end
        { we need to wrap around }
        else begin
              Move(Data[ReadPos], dst,        toEnd);
              Move(Data,          adst(dst)[toEnd], len - toEnd);
        end;

        Inc(ReadPos, len);
        ReadPos := ReadPos mod _Capacity;
        Dec(_Count, len);
        Inc(_Left, len);

        Result := len;

end;

function TBytePump.Dequeue(var dst; len: Integer): Integer;
begin
        Result := _Dequeue(dst, len);
        { pull from source }
        if (Result <> 0) and (_Source <> Nil) then Pump;

end;

end.
