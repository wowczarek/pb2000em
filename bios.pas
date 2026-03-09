{ functions to handle the storage medium,
  in this version the disk image in a file (diskname) }

unit Bios;

interface

{ all functions return False in case of an error }
  function DiskOpen : boolean;
  function DiskClose : boolean;
  function SectorRead (number: integer) : boolean;
  function SectorWrite (number: integer) : boolean;

  const
    SIZE_SECTOR = 256;

  var
    diskname: string;
    secbuf: array [0..SIZE_SECTOR-1] of byte;
    sectors: integer = -1;	{ available number of sectors }


implementation

  uses SysUtils;

  var
    handle: file of byte;

function DiskOpen : boolean;
begin
  sectors := -1;
  if FileExists (diskname) then
  begin
    AssignFile (handle, diskname);
    Reset (handle);
    sectors := FileSize (handle) div SIZE_SECTOR;
  end {if};
  DiskOpen := sectors >= 0;
end {DiskOpen};


function DiskClose : boolean;
begin
  if sectors >= 0 then CloseFile (handle);
  sectors := -1;
  DiskClose := True;
end {DiskClose};


function SectorRead (number: integer) : boolean;
var
  numread: integer;
begin
  SectorRead := False;
  if number >= sectors then Exit;
  {$I-}
  Seek (handle, number * SIZE_SECTOR);
  if IOResult = 0 then BlockRead (handle, secbuf, SIZE_SECTOR, numread);
  {$I+}
  SectorRead := (numread = SIZE_SECTOR) and (IOResult = 0);
end {SectorRead};


function SectorWrite (number: integer) : boolean;
begin
  SectorWrite := False;
  if number >= sectors then Exit;
  {$I-}
  Seek (handle, number * SIZE_SECTOR);
  if IOResult = 0 then BlockWrite (handle, secbuf, SIZE_SECTOR);
  {$I+}
  SectorWrite := IOResult = 0;
end {SectorWrite};


end.
