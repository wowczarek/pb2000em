{ file system handling,
  this version supports the original Casio file system used by the MD-100
  Notes:
  the record numbering starts at 0,
  data can be read and written in record units of size SIZE_SECTOR only,
  the module doesn't care about data contents,
  files can be both read and written, no access restrictions }

unit Dos;

interface

  type

    TStorageProperty = (
	spError,
	spFree,
	spOccupied
      );

    TDosStatusCode = (
	dsNoError,
	dsRenameFailed,		{ file of specified new name already exists }
	dsFileNotFound,		{ open, delete, rename }
	dsFileNotOpened,	{ attempted to access a not opened file }
	dsHandleInUse,		{ attempted to reopen an already opened file }
	dsNoRoom,		{ no room in the directory or data space }
	dsHandleInvalid,	{ invalid file handle }
	dsNoData,		{ attempted to read past the last record }
	dsIoError		{ error in the Bios unit }
      );

  const
    SIZE_DIR_ENTRY = 16;
    SIZE_RECORD = 256;

  var
    DosStatus: TDosStatusCode;

  function DosInit : boolean;
  procedure DosClose;
  function FormatDisk : boolean;
  function ReadDirEntry (ptr: pointer; i: integer) : TStorageProperty;
  function OpenDiskFile (handle: cardinal; filename: pointer) : integer;
  function CreateDiskFile (handle: cardinal; filename: pointer;
	filekind: byte) : integer;
  procedure CloseDiskFile (handle: cardinal);
  function WriteDiskFile (handle: cardinal; data: pointer) : cardinal;
  function ReadDiskFile (handle: cardinal; data: pointer) : cardinal;
  function SizeOfDiskFile (handle: cardinal) : cardinal;
  function IsEndOfDiskFile (handle: cardinal) : boolean;
  procedure SeekAbsDiskFile (handle, position: cardinal);
  procedure SeekRelDiskFile (handle, offset: integer);
  procedure DeleteDiskFile (filename: pointer);
  procedure RenameDiskFile (oldname, newname: pointer);
  function DosSecRead (x: integer; data: pointer) : integer;
  function DosSecWrite (x: integer; data: pointer) : integer;
  function GetDiskFileTag (handle: cardinal) : integer;
  procedure PutDiskFileTag (handle: cardinal; value: integer);
  function GetFreeDiskSpace : cardinal;

implementation

  uses SysUtils, Bios;

  type

{ Structure of directory entry }
    TDirEntry = record
      kind: byte;			{ file type }
      name: array [0..7] of byte;
      ext: array [0..2] of byte;
      unused: byte;
      block: array[0..1] of byte;	{ starting block number, MSB first }
      attribute: byte;
    end;

{ file information }
    TFileInfo = record
      dirindex: integer;		{ index of associated directory entry,
					  value -1 when file not opened }
      nextrec: cardinal;		{ next record number }
      firstsec: cardinal;		{ starting sector }
      lastrec: cardinal;		{ last accessed record... }
      lastsec: cardinal;		{ ...and corresponding sector }
      tag: integer;			{ no predefined meaning }
    end;

  const
    SECTORS_FAT = 4;
    SECTORS_DIR = 12;
    START_FAT = 0;
    START_DIR = 4;
    START_DATA = 16;
    MAX_FILES = 16;			{ number of handles }
    SIZE_FILE_NAME = 8+3;
    SIZE_BLOCK = 4;			{ 4 sectors per block }
    SIZE_FAT_ENTRY = 2;
    MAX_DIR_ENTRY = SECTORS_DIR * SIZE_SECTOR div SIZE_DIR_ENTRY;
    MAX_FAT_ENTRY = SECTORS_FAT * SIZE_SECTOR div SIZE_FAT_ENTRY;

{ Bit mask definitions for FAT entries }
    FB_IN_USE = $8000;	{ marks a used entry }
    FB_LAST = $4000;	{ marks end of chain }
    FB_SECTORS = $3000;	{ number of last sector in last block }
    FB_BLOCK = $01FF;	{ number of block (this or next in chain) }

  var
    fileinfo: array [0..MAX_FILES-1] of TFileInfo;
    direntrybuf: TDirEntry;
    secnum: integer;	{ number of the sector in the 'secbuf', otherwise -1 }


{ returns the smaller of two numeric values, as Min from the Math unit }
function MyMin (x, y: cardinal) : cardinal;
begin
  if x < y then MyMin := x else MyMin := y;
end {MyMin};


function DosInit : boolean;
begin
  DosInit := DiskOpen;
  secnum := -1;
  CloseDiskFile ($FF);
end {DosInit};


procedure DosClose;
begin
  DiskClose;
  secnum := -1;
end {DosClose};


{ read sector 'x' to the 'secbuf', unless it already contains valid data }
function MySecRead (x {sector}: integer) : boolean;
begin
  if x <> secnum then
  begin
    MySecRead := False;
    secnum := -1;
    if not SectorRead (x) then Exit;
    secnum := x;
  end {if};
  MySecRead := True;
end {MySecRead};


{ write the contents of the 'secbuf' to the sector 'x' }
function MySecWrite (x {sector}: integer) : boolean;
begin
  MySecWrite := False;
  secnum := -1;
  if not SectorWrite (x) then Exit;
  secnum := x;
  MySecWrite := True;
end {MySecWrite};


function FormatDisk : boolean;
var
  i, maxsector: cardinal;
begin
  secnum := -1;
  FormatDisk := False;
  CloseDiskFile ($FF);
  maxsector := MyMin (sectors, SIZE_BLOCK * MAX_FAT_ENTRY);
  FillChar (secbuf[0], SIZE_SECTOR, $00);
  for i := 1 to maxsector - 1 do
  begin
    if not SectorWrite (integer (i)) then Exit;
  end {for};
  FillChar (secbuf[0], START_DATA div SIZE_BLOCK * SIZE_FAT_ENTRY, $FF);
  if not SectorWrite (0) then Exit;
  secnum := 0;
  FormatDisk := True;
end {FormatDisk};


{ read a directory entry 'i' to the memory location pointed to by 'ptr' }
function ReadDirEntry (ptr: pointer; i: integer) : TStorageProperty;
var
  x: integer;
  s: integer;		{ sector containing the directory entry }
begin
  ReadDirEntry := spError;
  if (i < 0) or (i >= MAX_DIR_ENTRY) then Exit;
  x := i * SIZE_DIR_ENTRY;
  s := x div SIZE_SECTOR + START_DIR;
  if not MySecRead (s) then Exit;
  Move (secbuf[x mod SIZE_SECTOR], ptr^, SIZE_DIR_ENTRY);
  with TDirEntry(ptr^) do
  begin
    if (name[0] = 0) and (block[0] = 0) and (block[1] = 0) then
      ReadDirEntry := spFree
    else
      ReadDirEntry := spOccupied;
  end {with};
end {ReadDirEntry};


{ write a directory entry 'i' with data pointed to by 'ptr' }
function WriteDirEntry (ptr: pointer; i: integer) : boolean;
var
  x: integer;
  s: integer;		{ sector containing the directory entry }
begin
  WriteDirEntry := False;
  if (i < 0) or (i >= MAX_DIR_ENTRY) then Exit;
  x := i * SIZE_DIR_ENTRY;
  s := x div SIZE_SECTOR + START_DIR;
  if not MySecRead (s) then Exit;
  Move (ptr^, secbuf[x mod SIZE_SECTOR], SIZE_DIR_ENTRY);
  if not MySecWrite (s) then Exit;
  WriteDirEntry := True;
end {WriteDirEntry};


{ seek the directory for the specified file name, file type ignored,
  returns the index of the directory entry or -1 if not found }
function FindDirEntry (filename: pointer) : integer;
var
  x: TStorageProperty;
begin
  result := 0;
  repeat
    x := ReadDirEntry (@direntrybuf, result);
    if (x = spOccupied) and
      CompareMem (@(direntrybuf.name), filename, SIZE_FILE_NAME) then Exit;
    Inc (result);
  until x = spError;
  result := -1;
end {FindDirEntry};


function CheckFileHandle (handle: cardinal) : TDosStatusCode;
begin
  if handle >= MAX_FILES then
    CheckFileHandle := dsHandleInvalid
  else if fileinfo[handle].dirindex < 0 then
    CheckFileHandle := dsFileNotOpened
  else
    CheckFileHandle := dsNoError;
end {CheckFileHandle};


{ the function returns the FAT entry associated with the specified sector,
  or value > $FFFF in case of an error }
function ReadFatEntry (x: cardinal {sector}) : cardinal;
var
  s: integer;			{ sector containing the FAT entry }
begin
  ReadFatEntry := cardinal(-1);
  x := x div SIZE_BLOCK * SIZE_FAT_ENTRY;	{ offset of the FAT entry }
  s := integer (x) div SIZE_SECTOR + START_FAT;
  if s >= START_FAT + SECTORS_FAT then Exit;
  if not MySecRead (s) then Exit;
  x := x mod SIZE_SECTOR;
  ReadFatEntry := cardinal(secbuf[x]) shl 8 + cardinal(secbuf[x+1]);
end {ReadFatEntry};


{ the function writes the FAT entry associated with the specified sector }
function WriteFatEntry (x {sector}, y {new value} : cardinal) : boolean;
var
  s: integer;			{ sector containing the FAT entry }
begin
  WriteFatEntry := False;
  x := x div SIZE_BLOCK * SIZE_FAT_ENTRY;	{ offset of the FAT entry }
  s := integer (x) div SIZE_SECTOR + START_FAT;
  if s >= START_FAT + SECTORS_FAT then Exit;
  if not MySecRead (s) then Exit;
  x := x mod SIZE_SECTOR;
  secbuf[x] := Hi(y);
  secbuf[x+1] := Lo(y);
  if not MySecWrite (s) then Exit;
  WriteFatEntry := True;
end {WriteFatEntry};


{ find first free block,
  returns the number of first sector of the block, or 0 if none found }
function FindFreeBlock : cardinal {sector};
var
  maxsector: cardinal;
begin
  maxsector := MyMin (sectors, SIZE_BLOCK * MAX_FAT_ENTRY);
  result := START_DATA;
  repeat
    if (ReadFatEntry (result) and FB_IN_USE) = 0 then Exit;
    Inc (result, SIZE_BLOCK);
  until result >= maxsector;
  result := 0;
end {FindFreeBlock};


{ find or allocate (if allowed) the next sector in the FAT chain,
  returns 0 if none found }
function FatNextSector (x: cardinal {previous sector}; allocate: boolean) :
  cardinal {next sector};
var
  y {sector of a newly allocated block}, entry {FAT entry}: cardinal;
begin
  FatNextSector := 0;
  if x < START_DATA then

{ new file }
  begin
    if not allocate then Exit;
    y := FindFreeBlock;
    if y = 0 then Exit;
    entry := FB_IN_USE + FB_LAST + y div SIZE_BLOCK;
    if not WriteFatEntry (y, entry) then Exit;
    FatNextSector := y;
  end
  else

{ existing file }
  begin
    entry := ReadFatEntry (x);
    if entry > $FFFF then Exit;			{ no valid FAT entry }
    if (entry and FB_IN_USE) = 0 then Exit;	{ FAT error, sector marked as free }
    if (entry and FB_LAST) <> 0 then

{ last block in the chain }
    begin
      if (x and (SIZE_BLOCK - 1)) >= ((entry and FB_SECTORS) shr 12) then
{ end of file }
      begin
        if not allocate then Exit;
        if (x and (SIZE_BLOCK - 1)) < (SIZE_BLOCK - 1) then
{ allocate next sector in the same block }
        begin
          if not WriteFatEntry (x + 1, entry + $1000) then Exit;
          FatNextSector := x + 1;
        end
        else
{ allocate next sector in a new block }
        begin
          y := FindFreeBlock;
          if y = 0 then Exit;
          entry := FB_IN_USE + y div SIZE_BLOCK;
          if not WriteFatEntry (x, entry) then Exit;	{ previous in chain }
          entry := FB_IN_USE + FB_LAST + y div SIZE_BLOCK;
          if not WriteFatEntry (y, entry) then Exit;	{ last in chain }
          FatNextSector := y;
        end {if};
      end
      else
{ not the end of file }
      begin
        FatNextSector := x + 1;
      end {if};
    end
    else

{ not the last block in the chain }
    begin
      if (x and (SIZE_BLOCK - 1)) < (SIZE_BLOCK - 1) then
{ next sector is in the same block }
      begin
        FatNextSector := x + 1;
      end
      else
{ next sector is in another block }
      begin
        x := (entry and FB_BLOCK) * SIZE_BLOCK;	{ follow the FAT chain }
        entry := ReadFatEntry (x);
        if entry > $FFFF then Exit;		{ no valid FAT entry }
        if (entry and FB_IN_USE) <> 0 then FatNextSector := x;
      end {if}
    end {if};

  end {if};
end;


{ free the FAT chain starting from the specified sector }
function FatFreeChain (x: cardinal {sector}) : boolean;
var
  entry: cardinal;	{ FAT entry }
begin
  FatFreeChain := False;
  repeat
    entry := ReadFatEntry (x);
    if entry > $FFFF then Exit;			{ no valid FAT entry }
    if not WriteFatEntry (x, entry and $00FF) then Exit;
    x := (entry and FB_BLOCK) * SIZE_BLOCK;
  until ((entry and FB_IN_USE) = 0)	{ FAT error, sector marked as free }
	or ((entry and FB_LAST) <> 0);
  FatFreeChain := True;
end {FatFreeChain};


function OpenDiskFile (handle: cardinal; filename: pointer) :
  integer {index of the directory entry};
begin
  OpenDiskFile := -1;
  DosStatus := dsHandleInvalid;
  if handle >= MAX_FILES then Exit;
  with fileinfo[handle], direntrybuf do
  begin
    DosStatus := dsHandleInUse;
    if dirindex >= 0 then Exit;
    DosStatus := dsFileNotFound;
    dirindex := FindDirEntry (filename);
    OpenDiskFile := dirindex;
    if dirindex < 0 then Exit;
    nextrec := 0;
    firstsec := SIZE_BLOCK * (cardinal(block[0]) shl 8 + cardinal(block[1]));
    lastrec := 0;
    lastsec := firstsec;
  end {with};
  DosStatus := dsNoError;
end {OpenDiskFile};


function CreateDiskFile (handle: cardinal; filename: pointer; filekind: byte)
  : integer {index of the directory entry};
var
  i: integer;
  ensec, enblk: cardinal;
  x: TStorageProperty;
begin
  CreateDiskFile := -1;
  DosStatus := dsHandleInvalid;
  if handle >= MAX_FILES then Exit;
{ delete existing file of specified name }
  DeleteDiskFile (filename);
{ find free directory entry }
  i := -1;
  repeat
    Inc (i);
    x := ReadDirEntry (@direntrybuf, i);
  until x <> spOccupied;
  DosStatus := dsNoRoom;
  if x <> spFree then Exit;
{ allocate a FAT entry }
  ensec := FatNextSector (0, True);
  if ensec = 0 then Exit;
  DosStatus := dsIoError;
  enblk := ensec div SIZE_BLOCK;
  if not WriteFatEntry (ensec, FB_IN_USE or FB_LAST or enblk) then Exit;
{ create the directory entry }
  with direntrybuf do
  begin
    kind := filekind;
    Move (filename^, name, SIZE_FILE_NAME);
    block[0] := Hi (enblk);
    block[1] := Lo (enblk);
  end {with};
  if not WriteDirEntry (@direntrybuf, i) then Exit;
{ fill in the 'fileinfo' entry }
  with fileinfo[handle] do
  begin
    dirindex := i;
    nextrec := 0;
    firstsec := ensec;
    lastrec := 0;
    lastsec := ensec;
  end {with};
  CreateDiskFile := i;
  DosStatus := dsNoError;
end {CreateDiskFile};


{ closes all files if the specified file handle has bit 7 set }
procedure CloseDiskFile (handle: cardinal);
var
  i: integer;
begin
  if handle >= $80 then			{ close all files }
  begin
    DosStatus := dsNoError;
    for i := 0 to MAX_FILES-1 do fileinfo[i].dirindex := -1;
  end
  else
  begin
    DosStatus := CheckFileHandle (handle);
    if handle < MAX_FILES then fileinfo[handle].dirindex := -1;
  end {if};
end {CloseDiskFile};


{ write data pointed to by 'data' to the record of number 'nextrec',
  returns the number of written bytes }
function WriteDiskFile (handle: cardinal; data: pointer) : cardinal;
var
  fromrec, fromsec: cardinal;
begin
  WriteDiskFile := 0;
  DosStatus := CheckFileHandle (handle);
  if DosStatus <> dsNoError then Exit;
  with fileinfo[handle] do
  begin
{ scan/update the FAT chain for the record number 'nextrec',
  new sectors appended to the file aren't initialised }
    if nextrec >= lastrec then
    begin
      fromrec := lastrec;
      fromsec := lastsec;
    end
    else
    begin
      fromrec := 0;
      fromsec := firstsec;
    end {if};
    while fromrec < nextrec do
    begin
      fromsec := FatNextSector (fromsec, True);
      Inc (fromrec);
      DosStatus := dsNoData;
      if fromsec = 0 then Exit;
    end {while};
{ transfer data }
    Move (data^, secbuf[0], SIZE_SECTOR);
    DosStatus := dsIoError;
    if not MySecWrite (integer (fromsec)) then Exit;
    lastrec := fromrec;
    lastsec := fromsec;
  end {with};
  WriteDiskFile := SIZE_SECTOR;
  DosStatus := dsNoError;
end {WriteDiskFile};


{ read a record of number 'nextrec' to the memory location pointed to by
  'data', returns the number of read bytes }
function ReadDiskFile (handle: cardinal; data: pointer) : cardinal;
var
  fromrec, fromsec: cardinal;
begin
  ReadDiskFile := 0;
  DosStatus := CheckFileHandle (handle);
  if DosStatus <> dsNoError then Exit;
  with fileinfo[handle] do
  begin
{ scan the FAT chain for the record number 'nextrec' }
    if nextrec >= lastrec then
    begin
      fromrec := lastrec;
      fromsec := lastsec;
    end
    else
    begin
      fromrec := 0;
      fromsec := firstsec;
    end {if};
    while fromrec < nextrec do
    begin
      fromsec := FatNextSector (fromsec, False);
      Inc (fromrec);
      DosStatus := dsNoData;
      if fromsec = 0 then Exit;
    end {while};
{ transfer data }
    DosStatus := dsIoError;
    if not MySecRead (integer (fromsec)) then Exit;
    Move (secbuf[0], data^, SIZE_SECTOR);
    lastrec := fromrec;
    lastsec := fromsec;
  end {with};
  ReadDiskFile := SIZE_SECTOR;
  DosStatus := dsNoError;
end {ReadDiskFile};


{ returns the file size in records or 0 in case of an error,
  'DosStatus' isn't modified }
function SizeOfDiskFile (handle: cardinal) : cardinal {number of records};
var
  fromrec, fromsec: cardinal;
begin
  SizeOfDiskFile := 0;
  if CheckFileHandle (handle) <> dsNoError then Exit;
{ scan the FAT chain for the last record number }
  with fileinfo[handle] do
  begin
    fromrec := lastrec;
    fromsec := lastsec;
    repeat
      fromsec := FatNextSector (fromsec, False);
      Inc (fromrec);
    until fromsec = 0;
  end {with};
  SizeOfDiskFile := fromrec;
end {SizeOfDiskFile};


{ true if last record of the file accessed }
function IsEndOfDiskFile (handle: cardinal) : boolean;
var
  sector, entry: cardinal;
begin
  IsEndOfDiskFile := False;
  if CheckFileHandle (handle) <> dsNoError then Exit;
  sector := fileinfo[handle].lastsec;
  entry := ReadFatEntry (sector);
  if entry > $FFFF then Exit;
  if (entry and FB_LAST) = 0 then Exit;
  IsEndOfDiskFile :=
	(sector and (SIZE_BLOCK - 1)) = ((entry and FB_SECTORS) shr 12);
end {IsEndOfDiskFile};


{ both following functions only set the new record number in the 'fileinfo'
  table, they don't modify the 'DosStatus' }

procedure SeekAbsDiskFile (handle, position: cardinal {absolute position});
begin
  if CheckFileHandle (handle) <> dsNoError then Exit;
  fileinfo[handle].nextrec := position;
end {SeekAbsDiskFile};


procedure SeekRelDiskFile (handle, offset: integer {relative position});
begin
  if CheckFileHandle (handle) <> dsNoError then Exit;
  offset := offset + integer(fileinfo[handle].nextrec);
  if offset >= 0 then fileinfo[handle].nextrec := cardinal(offset);
end {SeekRelDiskFile};


procedure DeleteDiskFile (filename: pointer);
var
  i, x: integer;
begin
  DosStatus := dsFileNotFound;
  x := FindDirEntry (filename);
  if x < 0 then Exit;
  for i:=0 to MAX_FILES-1 do
  begin
    if fileinfo[i].dirindex = x then fileinfo[i].dirindex := -1;
  end {for};
  case ReadDirEntry (@direntrybuf, x) of
    spOccupied: begin
        DosStatus := dsNoError;
        if not FatFreeChain ((cardinal(direntrybuf.block[0]) shl 8 +
		cardinal(direntrybuf.block[1])) * SIZE_BLOCK) then
          DosStatus := dsIoError;
        FillChar (direntrybuf, SIZE_DIR_ENTRY, $00);
        if not WriteDirEntry (@direntrybuf, x) then
          DosStatus := dsIoError;
      end;
    spFree: DosStatus := dsNoError;
    else DosStatus := dsIoError;
  end {case};
end {DeleteDiskFile};


{ the file being renamed is allowed to be opened }
procedure RenameDiskFile (oldname, newname: pointer);
var
  x, y: integer;
begin
  y := FindDirEntry (newname);
  DosStatus := dsFileNotFound;
  x := FindDirEntry (oldname);
  if x < 0 then Exit;
  DosStatus := dsRenameFailed;
  if y >= 0 then Exit;
  DosStatus := dsNoError;
  Move (newname^, direntrybuf.name, SIZE_FILE_NAME);
  if not WriteDirEntry (@direntrybuf, x) then DosStatus := dsIoError;
end {RenameDiskFile};


{ returns the number of read bytes }
function DosSecRead (x: integer; data: pointer) : integer;
begin
  DosSecRead := 0;
  if MySecRead (x) then DosSecRead := SIZE_SECTOR;
  Move (secbuf[0], data^, SIZE_SECTOR);
end {DosSecRead};


{ returns the number of written bytes }
function DosSecWrite (x: integer; data: pointer) : integer;
begin
  DosSecWrite := 0;
  Move (data^, secbuf[0], SIZE_SECTOR);
  if MySecWrite (x) then DosSecWrite := SIZE_SECTOR;
end {DosSecWrite};


function GetDiskFileTag (handle: cardinal) : integer;
begin
  GetDiskFileTag := 0;
  if handle < MAX_FILES then GetDiskFileTag := fileinfo[handle].tag;
end {GetDiskFileTag};


procedure PutDiskFileTag (handle: cardinal; value: integer);
begin
  if handle < MAX_FILES then fileinfo[handle].tag := value;
end {PuttDiskFileTag};


{ returns the number of free clusters }
function GetFreeDiskSpace : cardinal;
var
  maxsector, x: cardinal;
begin
  maxsector := MyMin (sectors, SIZE_BLOCK * MAX_FAT_ENTRY);
  x := START_DATA;
  result := 0;
  while x < maxsector do
  begin
    if (ReadFatEntry (x) and FB_IN_USE) = 0 then Inc (result);
    Inc (x, SIZE_BLOCK);
  end {while};
end {GetFreeDiskSpace};


end.
