{$DEFINE HD44352A01}

{ LCD controller HD44352A01 (default) or HD44356A01 (when such name defined)
  Main differences against the original:
1. command $8 - scroll not supported
2. ignored bit Clock of the LCD port
}

unit Lcd;

interface

  uses Def;

  const
{ size of the data RAM, 2 banks of $0300 nibbles each }
    LCDSIZE     = $0600;

{ size of the character ROM, 256 characters of 16 nibbles each }
    CHRSIZE	= $1000;

  var
    lcdimage: array[0..LCDSIZE-1] of nibble;	{ data RAM + cursors }
    lcdchr: array[0..255, 0..15] of nibble;	{ character ROM }
    lcdctrl: byte;	{ LCD control port }
    onrate: integer;	{ ON frequency divisor }

  procedure LcdInit;
  procedure LcdSync;
  function LcdTransfer (data: nibble) : nibble;
  procedure LcdRender;

implementation


type

  TCursorParam = record
    mem: array[0..15] of nibble;
    offset: cardinal;
    page: cardinal;	{ 0 or 96 }
    col: cardinal;	{ 0..95 }
    row: cardinal;	{ 0 or 192 or 256 or 384 }
  end;

const
  ontab: array [0..15] of integer = (
	8192, 4, 8, 16, 32, 64, 128, 256,
	512, 1024, 2048, 2048, 4096, 4096, 4096, 4096
  );

var
  param: array[0..5] of nibble;			{ command + parameters }
  lcdmem: array[0..1,0..767] of nibble;		{ data RAM }
  state: cardinal = 0;		{ bits 2..0 count the received command nibbles
				  bit 3 and up count the data nibbles }
  index: cardinal = 0;		{ index to the lcdmem }
  CharWidth: cardinal;		{ character width in the text mode }
  Visible: boolean;
  DataByte: byte;		{ character codes are transferred bytewise,
				  this variable stores the previous nibble }

  cursor: array [0..1] of TCursorParam;
  curmode: cardinal;


procedure LcdInit;
var
  j: cardinal;
begin
  FillChar (lcdmem, LCDSIZE, 0);
  FillChar (param, 6, 0);
  state := 0;
  index := 0;
  onrate := 8192;
  CharWidth := 8;
  Visible := False;
  for j := 0 to 1 do
  begin
    with cursor[j] do
    begin
      FillChar (mem[0], 16, 0);
      offset := 0;
      page := 0;
      col := 0;
      row := 0;
    end {with};
  end {for};
  curmode := 0;
end {LcdInit};


procedure LcdSync;
begin
  state := 0;
end {LcdSync};


{ logical operation between the Old and New pixel value }
procedure Nexus (var x: nibble; y: nibble; kind: nibble);
begin
  case kind of
    $0: x := not x and y;
    $1: x := x xor y;
    $2,6: x := 0;
    $3: x := x and not y;
    $4: x := y;
    $5: x := x or y;
    {else do nothing}
  end {case};
  x := x and $F;
end {Nexus};


function LcdTransfer (data: nibble) : nibble;
var
  i: integer;
begin
  LcdTransfer := $F;
  data := data and $F;
  if (lcdctrl and VDD2_bit) = 0 then		{ unpowered }
  begin
    LcdInit;
  end
  else if (lcdctrl and LCDCE) <> 0 then		{ selected }
  begin

    if (lcdctrl and OP_bit) <> 0 then		{ command }
    begin
      if state < 6 then
      begin
        param[state] := data;
        Inc(state);
      end {if};

      case param[0] of

        $1,			{ Graphic Input }
        $2,			{ Graphic Output }
        $3: begin		{ Character Output }
              if state = 3 then index := cardinal (data)
              else if state = 4 then
              begin
                Inc (index, (data and 7) shl 4);
                if index >= 96 then Dec (index, 32);
                if data > 7 then Inc (index, 96);
              end
              else if state = 5 then Inc (index, 192 * (data and 3));
            end {case $1,$2,$3};

        $4: begin		{ LCD Visibility }
              if state = 2 then Visible := (data and 1) <> 0;
            end {case $4};

        $6,			{ Cursor Definition by Graphic }
        $7: begin		{ Cursor Definition by Character }
              index := 0;
              if state = 3 then cursor[param[1] and 1].offset := data;
            end {case $6,$7};

        $8: begin		{ Scroll, Character Width }
              if state = 2 then
              begin
                CharWidth := 8 - (data and 3);
              end {if};
            end {case $8};

        $9: begin		{ Cursor Visibility }
              if state = 2 then curmode := data;
            end {case $9};

        $B: begin		{ User Character Definition }
              index := 0;
            end {case $D};

        $D: begin		{ Timer Frequency Control }
              if state = 2 then onrate := ontab[data];
            end {case $D};

        $E: begin		{ Cursor Position }
              with cursor[param[1] and 1] do
              begin
                if state = 3 then col := data
                else if state = 4 then
                begin
                  Inc (col, (data and 7) shl 4);
                  if data > 7 then page := 96 else page := 0;
                end
                else if state = 5 then row := 192 * (data and 3);
              end {with};
            end {case $E};

        {else do nothing}

      end {case selector};
    end

    else					{ data }
    begin
      case param[0] of

        $1: begin		{ Graphic Input }
              index := index mod 768;
              if (param[1] shr 1) = 7 then
                LcdTransfer := lcdmem[param[1] and 1,index];
              Inc (index);
            end {case $1};

        $2: begin		{ Graphic Output }
              index := index mod 768;
              Nexus (lcdmem[param[1] and 1,
{$IfDef HD44356A01}
		index
{$else}	{ LCD controller HD44352A01 }
		index xor 1
{$endif}
		], data, param[1] shr 1);
              Inc (index);
            end {case $2};

        $3: begin		{ Character Output }
              if (state and 8) = 0 then DataByte := data else
              begin
{$IfDef HD44356A01}
                Inc (DataByte, data shl 4);
{$else}	{ LCD controller HD44352A01 }
		DataByte := DataByte shl 4;
		Inc (DataByte, data);
{$endif}
                for i := 0 to 2*CharWidth-1 do
                begin
                  index := index mod 768;
                  Nexus (lcdmem[param[1] and 1, index],
			lcdchr[DataByte,i], param[1] shr 1);
                  Inc (index);
                end {for};
              end {if};
              state := state xor 8;
            end {case $3};

        $6: begin		{ Cursor Definition by Graphic }
              index := index and $F;
              cursor[param[1] and 1].mem[
{$IfDef HD44356A01}
		index
{$else}	{ LCD controller HD44352A01 }
		index xor 1
{$endif}
		] := data;
              Inc (index);
            end {case $6};

        $7: begin		{ Cursor Definition by Character }
              if (state and 8) = 0 then DataByte := data else
              begin
{$IfDef HD44356A01}
                Inc (DataByte, data shl 4);
{$else}	{ LCD controller HD44352A01 }
		DataByte := DataByte shl 4;
		Inc (DataByte, data);
{$endif}
                Move (lcdchr[DataByte,0], cursor[param[1] and 1].mem[0], 16);
              end {if};
              state := state xor 8;
            end {case $7};

        $B: begin		{ User Character Definition }
              lcdchr[$FC or param[2],
{$IfDef HD44356A01}
		index and $F
{$else}	{ LCD controller HD44352A01 }
		(index and $F) xor 1
{$endif}
		] := data;
              Inc (index);
            end {case $B};

        {else do nothing}

      end {case selector};
    end {if};

  end {if};
end {LcdTransfer};


procedure LcdRender;
var
  i,j,n: cardinal;
  m: byte;
{$IfDef HD44356A01}
  x, extra: cardinal;
{$endif}
begin
  if Visible then
  begin
    Move (lcdmem, lcdimage, LCDSIZE);
    if (curmode and 1) <> 0 then
    begin
      for j := 0 to 1 do
      begin
{$IfDef HD44356A01}
        if j = 0 then extra := (CharWidth - 1) shl 1 else extra := 0;
{$endif}
        with cursor[j] do
        begin
          m := curmode shr 1;
{$IfDef HD44356A01}
          x := col - extra;
          n := 768*j + row + page + x;
{$else}
          n := 768*j + row + page + col;
{$endif}
          for i := 0 to (CharWidth shl 1) - 1 do
          begin
{$IfDef HD44356A01}
            if integer (x+i) >= 0 then
            begin
              if x+i > 95 then Break;
              Nexus (lcdimage[n+i], mem[(offset-x+i) and $F], m);
            end {if};
{$else}
            if col+i > 95 then Break;
            Nexus (lcdimage[n+i], mem[(offset-col+i) and $F], m);
{$endif}
          end {for};
        end {with};
      end {for};
    end {if};
  end
  else
  begin
    FillChar (lcdimage, LCDSIZE, 0);
  end {if};
end {LcdRender};


end.
