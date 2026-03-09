{ The code isn't intended to be fool proof. It's only required that invalid
  input data cannot crash the program. }

unit Fdd;

interface

  procedure FddOpen;
  procedure FddClose;
  function FddTransfer (DataIn: byte) : byte;


implementation

  uses Dos;

  type
    Func1 = function (x: byte) : byte;

{ declarations of functions called through a pointer in the cmdtab }
  function SwitchCmd (x: byte) : byte; forward;
  function ExecDir (x: byte) : byte; forward;
  function ExecCloseFile (x: byte) : byte; forward;
  function ExecOpenFile (x: byte) : byte; forward;
  function ExecReadFile (x: byte) : byte; forward;
  function ExecWriteFile (x: byte) : byte; forward;
  function ExecKillFile (x: byte) : byte; forward;
  function ExecRenameFile (x: byte) : byte; forward;
  function ExecReadSector (x: byte) : byte; forward;
  function ExecWriteSector (x: byte) : byte; forward;
  function ExecGetSize (x: byte) : byte; forward;
  function ExecGetFree (x: byte) : byte; forward;
  function ReturnCountLo (x: byte) : byte; forward;
  function ReturnCountHi (x: byte) : byte; forward;
  function ReturnBlock (x: byte) : byte; forward;
  function AcceptCountLo (x: byte) : byte; forward;
  function AcceptCountHi (x: byte) : byte; forward;
  function AcceptBlock (x: byte) : byte; forward;

  const
    SEC_COUNT = 16;	{ number of sectors on the track }
    SEC_BASE = 1;	{ number of the first sector on the track }
    BUFSIZE = 1024;	{ at least 2 * SIZE_RECORD + 4 }

{ MD-100 status codes }
    mdFileNotOpened = $80;
    mdNoRoom = $40;
    mdInvalidCommand = $20;
    mdFileFound = $10;
    mdRenameFailed = $08;
    mdNoData = $04;
    mdWriteProtected = $02;
    mdEndOfFile = $01;
    mdOK = $00;

    cmdtab: array[0..58] of pointer = (
{ index 0: entry point }
	@SwitchCmd,
{ index 1: read directory entry }
	@ExecDir,		{ + return the number of data bytes, LSB }
	@ReturnCountHi,
	@ReturnBlock,
	@SwitchCmd,
{ index 5: close file }
        @ExecCloseFile,
	@SwitchCmd,
{ index 7: open file }
	@AcceptCountLo,
	@AcceptCountHi,
	@AcceptBlock,
	@ExecOpenFile,		{ + return the number of data bytes, LSB }
	@ReturnCountHi,
	@ReturnBlock,
	@SwitchCmd,
{ index 14: read from file }
	@AcceptCountLo,
	@AcceptCountHi,
	@AcceptBlock,
	@ExecReadFile,		{ + return the number of data bytes, LSB }
	@ReturnCountHi,
	@ReturnBlock,
	@SwitchCmd,
{ index 21: read sector }
	@AcceptCountLo,		{ get the track number }
	@ExecReadSector,	{ + get the sector number }
	@ReturnBlock,
	@SwitchCmd,
{ index 25: delete file }
	@AcceptCountLo,
	@AcceptCountHi,
	@AcceptBlock,
	@ExecKillFile,		{ + return the number of data bytes, LSB }
	@ReturnCountHi,
	@ReturnBlock,
	@SwitchCmd,
{ index 32: rename file }
	@AcceptCountLo,
	@AcceptCountHi,
	@AcceptBlock,
	@ExecRenameFile,	{ + return the number of data bytes, LSB }
	@ReturnCountHi,
	@ReturnBlock,
	@SwitchCmd,
{ index 39: write sector }
	@AcceptCountLo,
	@AcceptCountHi,
	@ExecWriteSector,
	@SwitchCmd,
{ index 43: write to file }
	@AcceptCountLo,
	@AcceptCountHi,
	@ExecWriteFile,
	@ReturnCountLo,
	@ReturnCountHi,
	@ReturnBlock,
	@SwitchCmd,
{ index 50: get file size }
	@AcceptCountLo,		{ get the file handle }
	@ExecGetSize,
	@ReturnCountLo,
	@ReturnCountHi,
	@SwitchCmd,
{ index 55: get number of free clusters }
	@ExecGetFree,
	@ReturnCountLo,
	@ReturnCountHi,
	@SwitchCmd	);

  var
    index: cardinal;	{ index to the 'cmdtab' }
    cmdcode: byte;
    opstatus: byte;
    count: integer;
    bufindex: cardinal;
    isdisk: boolean;
    deindex: integer;	{ directory entry index }
    buffer: array [0..BUFSIZE-1] of byte;


procedure FddOpen;
begin
  index := 0;
  cmdcode := 0;
  opstatus := 0;
  count := 1;
  bufindex := 0;
  deindex := 0;
  isdisk := DosInit;
end {FddOpen};


procedure FddClose;
begin
  DosClose;
  isdisk := False;
end {FddClose};


function CnvStatus (x: TDosStatusCode) : byte {MD-100 operation status};
begin
  case x of
    dsNoError:		CnvStatus := mdOK;
    dsRenameFailed:	CnvStatus := mdRenameFailed + mdFileFound;
    dsFileNotFound:	CnvStatus := mdInvalidCommand;
    dsFileNotOpened:	CnvStatus := mdFileNotOpened;
    dsHandleInUse:	CnvStatus := mdInvalidCommand;
    dsNoRoom:		CnvStatus := mdNoRoom;
    dsHandleInvalid:	CnvStatus := mdInvalidCommand; {should never happen}
    dsNoData:		CnvStatus := mdNoData;
    dsIoError:		CnvStatus := mdWriteProtected;
  else
    CnvStatus := mdInvalidCommand; {should never happen}
  end {case};
end {CnvStatus};


function FddTransfer (DataIn: byte) : byte;
begin
  FddTransfer := Func1 (cmdtab[index]) (DataIn);
end {FddTransfer};


function SwitchCmd (x: byte {command code}) : byte {opstatus};
begin
  cmdcode := x;
  opstatus := mdNoData;			{ disk not inserted }
  index := 0;				{ 'cmdtab' entry point }
  if isdisk then
  begin
    opstatus := mdOK;
    case x of
      $00..$02: index := 1;		{ read directory entry }
      $10..$11: index := 43;		{ write to file }
      $20..$21: index := 14;		{ read from file }
      $30..$34: index := 7;		{ open file }
      $40: index := 5;			{ close file }
      $50: index := 25;			{ delete file }
      $60: index := 32;			{ rename file }
      $70: index := 39;			{ write sector }
      $80: index := 21;			{ read sector }
      $90: if not FormatDisk then opstatus := mdNoData;
      $C0: index := 50;			{ get file size }
      $D0: index := 55;			{ get number of free clusters }
    else
      opstatus := mdInvalidCommand;	{ unknown command }
    end {case};
  end {if};
  SwitchCmd := opstatus;
end {SwitchCmd};


function ExecDir (x: byte {dummy data}) : byte {count LSB};
var
  i, step: integer;
  y: TStorageProperty;
begin
  Inc (index);
  bufindex := 0;
  case cmdcode of
    $00: begin
           i := -1;
           step := 1;
         end;
    $01: begin
           i := deindex;
           step := 1;
         end;
    else	{cmdcode=$02}
    begin
      i := deindex;
      step := -1;
    end;
  end {case};
  repeat
    Inc (i, step);
    y := ReadDirEntry (@buffer[1], i);
  until y <> spFree;
  if y = spOccupied then
  begin
    deindex := i;
    buffer[0] := mdFileFound;
    count := SIZE_DIR_ENTRY + 1;
  end
  else
  begin
    buffer[0] := mdEndOfFile;
    count := 1;
  end {if};
  ExecDir := Lo (count);
end {ExecDir};


{ it is allowed to close unopened files,
  actually the command always returns with opstatus = mdOK }
function ExecCloseFile (x: byte {file number}) : byte {opstatus};
begin
  Inc (index);
  CloseDiskFile (cardinal(x) {file number});
  if DosStatus = dsFileNotOpened then opstatus := mdOK else
    opstatus := CnvStatus (DosStatus);
  ExecCloseFile := opstatus;
end {ExecCloseFile};


function ExecOpenFile (x: byte {dummy data}) : byte {count LSB};
var
  file_handle, position: cardinal;
  i: integer;
begin
  Inc (index);
  file_handle := cardinal(buffer[1] and $0F);
  PutDiskFileTag (file_handle, integer(cardinal(cmdcode)));
  i := -1;
  if cmdcode <> $30 {sequential output} then
    i := OpenDiskFile ( file_handle,
	@buffer[3] {file name});
  if (i < 0) and (cmdcode < $32) then
    i := CreateDiskFile ( file_handle,
	@buffer[3] {file name},
	buffer[2] {file type});
  count := 1;
  if (i >= 0) then
  begin
    if cmdcode <> $30 {sequential output} then
    begin
      if ReadDirEntry (@buffer[1], i) = spOccupied then
      begin
        count := 17;
        if cmdcode = $34 {append} then
        begin
          position := SizeOfDiskFile (file_handle);
          if position > 0 then
          begin
            SeekAbsDiskFile (file_handle, position - 1);
            Inc (count, ReadDiskFile (file_handle, @buffer[17]));
	{ trailing zeros and Ctrl-Z aren't transferred }
            while (count > 17) and (buffer[count] = 0) do Dec (count);
            if (count > 17) and (buffer[count] = $1A) then Dec (count);
          end {if};
        end {if};
      end {if};
    end {if};
  end {if};
  opstatus := CnvStatus (DosStatus);
  if count > 1 then opstatus := opstatus or mdFileFound;
  buffer[0] := opstatus;
  bufindex := 0;
  ExecOpenFile := Lo (count);
end {ExecOpenFile};


function ExecReadFile (x: byte {dummy data}) : byte {count LSB};
var
  file_handle, position: cardinal;
begin
  Inc (index);
  file_handle := cardinal(buffer[1] and $0F);
  if cmdcode = $21 then
  begin
    position := cardinal(buffer[2]) + (cardinal(buffer[3]) shl 8);
    if position = 0 then position := 1;
    SeekAbsDiskFile (file_handle, position - 1);
  end {if};
  count := ReadDiskFile (file_handle,
	@buffer[1] {pointer to the data buffer});
  SeekRelDiskFile (file_handle, 1);
  if DosStatus = dsNoError then
  begin
    if IsEndOfDiskFile (file_handle) then
    begin
{ for the last record skip the trailing zeros and the trailing Ctrl-Z }
      while (count > 0) and (buffer[count] = 0) do Dec (count);
      if (count > 0) and (buffer[count] = $1A) then Dec (count);
      opstatus := mdEndOfFile;
    end {if};
  end
  else opstatus := CnvStatus (DosStatus);
  Inc (count);
  buffer[0] := opstatus;
  bufindex := 0;
  ExecReadFile := Lo (count);
end {ExecReadFile};


function ExecWriteFile (x: byte {written data}) :
  byte {operation status | count LSB};
var
  file_handle, position, i: cardinal;
begin
  if bufindex < BUFSIZE then
  begin
    buffer[bufindex] := x;
    Inc (bufindex);
  end {if};
  Dec (count);

  if count <= 0 then
{ last record }
  begin
    Inc (index);
    if cmdcode = 0 then
    begin
      file_handle := cardinal(buffer[1] and $0F);
      if IsEndOfDiskFile (file_handle) and (bufindex < BUFSIZE - 1) then
      begin
        buffer[bufindex] := $1A;
        Inc (bufindex);
      end {if};
      FillChar (buffer[bufindex], BUFSIZE - bufindex, $00);
      i := 2;
      while i < bufindex do
      begin
        if WriteDiskFile (file_handle, @buffer[i]) <> SIZE_RECORD then Break;
        Inc (i, SIZE_RECORD);
        if i <= bufindex then SeekRelDiskFile (file_handle, 1);
      end {while};
      if opstatus = mdOK then opstatus := CnvStatus (DosStatus);
    end {if};
    buffer[0] := opstatus;
    count := 1;
  end

  else
{ not the last record }
  begin
    if (cmdcode = 0) and (bufindex = SIZE_RECORD + 2) then
    begin
      bufindex := 2;
      file_handle := cardinal(buffer[1] and $0F);
      if WriteDiskFile (file_handle, @buffer[2]) <> SIZE_RECORD then
      begin
        if opstatus = mdOK then opstatus := CnvStatus (DosStatus);
      end {if};
      SeekRelDiskFile (file_handle, 1);
    end
    else if (cmdcode = $10) and (bufindex = 2) then
    begin
      cmdcode := 0;
    end
    else if (cmdcode = $11) and (bufindex = 4) then
    begin
      cmdcode := 0;
      bufindex := 2;
      file_handle := cardinal(buffer[1] and $0F);
      position := cardinal(buffer[2]) + (cardinal(buffer[3]) shl 8);
      if position = 0 then position := 1;
      SeekAbsDiskFile (file_handle, position - 1);
    end {if};
  end {if};

  ExecWriteFile := mdOK;
end {ExecWriteFile};


function ExecKillFile (x: byte {dummy data}) : byte {count LSB};
begin
  Inc (index);
  DeleteDiskFile (@buffer[2] {file name});
  if DosStatus = dsNoError then
    opstatus := mdFileFound
  else if DosStatus = dsFileNotFound then
    opstatus := mdOK
  else
    opstatus := CnvStatus (DosStatus);
  count := 1;
  buffer[0] := opstatus;
  bufindex := 0;
  ExecKillFile := Lo (count);
end {ExecKillFile};


function ExecRenameFile (x: byte {dummy data}) : byte {count LSB};
begin
  Inc (index);
  RenameDiskFile (@buffer[2] {old file name}, @buffer[19] {new file name});
  if DosStatus = dsNoError then
    opstatus := mdFileFound
  else if DosStatus = dsFileNotFound then
    opstatus := mdOK
  else
    opstatus := CnvStatus (DosStatus);
  count := 1;
  buffer[0] := opstatus;
  bufindex := 0;
  ExecRenameFile := Lo (count);
end {ExecRenameFile};


{ the track number specified in 'count' }
function ExecReadSector (x: byte {sector number}) : byte {operation status};
begin
  Inc (index);
  count := DosSecRead (count * SEC_COUNT + integer(cardinal(x)) - SEC_BASE,
    @buffer[0]);
  if count = 0 then
  begin
    opstatus := mdInvalidCommand;
    index := 0;
  end {if};
  bufindex := 0;
  ExecReadSector := opstatus;
end {ExecReadSector};


function ExecWriteSector (x: byte {written data}) : byte {operation status};
begin
  if bufindex < BUFSIZE then
  begin
    buffer[bufindex] := x;
    Inc (bufindex);
  end {if};
  Dec (count);
  if count <= 0 then
  begin
    Inc (index);
    if DosSecWrite (integer(cardinal(buffer[1])) * SEC_COUNT +
	integer(cardinal(buffer[2])) - SEC_BASE, @buffer[3]) = 0 then
      opstatus := mdWriteProtected;
    bufindex := 0;
    count := 0;
  end {if};
  ExecWriteSector := opstatus;
end {ExecWriteSector};


{ expects file handle in buffer[0], returns file size in 'count' }
function ExecGetSize (x: byte {dummy data}) : byte {operation status};
begin
  Inc (index);
  count := SizeOfDiskFile (cardinal(buffer[0]));
  if count = 0 then opstatus := mdFileNotOpened
  else if (GetDiskFileTag (cardinal(buffer[0])) and 1) <> 0 then Dec (count);
  ExecGetSize := opstatus;
end {ExecGetSize};


{ returns the number of free clusters in 'count' }
function ExecGetFree (x: byte {dummy data}) : byte {operation status};
begin
  Inc (index);
  count := GetFreeDiskSpace;
  ExecGetFree := opstatus;
end {ExecGetFree};


function ReturnCountLo (x: byte {dummy data}) : byte {count LSB};
begin
  Inc (index);
  bufindex := 0;
  ReturnCountLo := Lo (count);
end {ReturnCountLo};


function ReturnCountHi (x: byte {dummy data}) : byte {count MSB};
begin
  Inc (index);
  ReturnCountHi := Hi (count);
end {ReturnCountHi};


{ return 'count' bytes from the 'buffer' }
function ReturnBlock (x: byte {dummy data}) : byte {read data};
begin
  ReturnBlock := buffer[bufindex];
  if bufindex < BUFSIZE - 1 then Inc (bufindex);
  Dec (count);
  if count <= 0 then Inc (index);
end {ReturnBlock};


function AcceptCountLo (x: byte {count LSB}) : byte {opstatus};
begin
  Inc (index);
  count := integer (cardinal (x));
  bufindex := 0;
  AcceptCountLo := opstatus;
end {AcceptCountLo};


function AcceptCountHi (x: byte {count LSB}) : byte {opstatus};
begin
  Inc (index);
  Inc (count, integer (cardinal (x) shl 8));
  if count = 0 then
  begin
    opstatus := mdInvalidCommand;
    index := 0;
  end {if};
  AcceptCountHi := opstatus;
end {AcceptCountHi};


{ accept 'count' bytes and store them in the 'buffer' }
function AcceptBlock (x: byte {written data}) : byte {opstatus};
begin
  if bufindex < BUFSIZE then
  begin
    buffer[bufindex] := x;
    Inc (bufindex);
  end {if};
  Dec (count);
  if count <= 0 then Inc (index);
  AcceptBlock := opstatus;
end {AcceptBlock};


end.
