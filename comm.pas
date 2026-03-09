unit Comm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Spin;

type
  TCommForm = class(TForm)
    OpenDialog1: TOpenDialog;
    SendProgressBar: TProgressBar;
    SendButton: TButton;
    RecvButton: TButton;
    DelaySpinEdit: TSpinEdit;
    DelayLabel: TLabel;
    StopEofCheckBox: TCheckBox;
    SaveDialog1: TSaveDialog;
    StopButton: TButton;
    FlowCheckBox: TCheckBox;
    AppendEofCheckBox: TCheckBox;
    CommStatusBar: TStatusBar;
    procedure RecvButtonClick(Sender: TObject);
    procedure SendButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure CommFormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CommForm: TCommForm;
  CommDelayTimer: integer;	{ decremented to 0 at the OscFreq rate }

  function CommRead: integer;
  procedure CommWrite (x: byte);

implementation

{$R *.DFM}

uses
  Def;

var
  CommFile: file of byte;
  Suspend: boolean;	{ affected by the Xon/Xoff characters }
  SendProgBarCnt, SendProgBarX, SendProgBarY, SaveMax: integer;
  TransmittedCharacter: byte;

procedure TCommForm.RecvButtonClick(Sender: TObject);
var
  fname: string;
begin
  if SaveDialog1.Execute then
  begin
    fname := SaveDialog1.FileName;
    {$I-}
    AssignFile (CommFile, fname);
    Rewrite (CommFile);
    {$I+}
    if IOResult = 0 then
    begin
      CommStatusBar.SimpleText := 'Receiving: ' + ExtractFileName (fname);
      SendButton.Enabled := False;
      RecvButton.Enabled := False;
      StopButton.Enabled := True;
    end {if};
  end {if};
end;


procedure TCommForm.SendButtonClick(Sender: TObject);
var
  fname: string;
begin
  if OpenDialog1.Execute then
  begin
    fname := OpenDialog1.FileName;
    if FileExists (fname) then
    begin
      AssignFile (CommFile, fname);
      Reset (CommFile);
      Suspend := False;
      TransmittedCharacter := 0;
      CommStatusBar.SimpleText := 'Sending: ' + ExtractFileName (fname);
      with SendProgressBar do
      begin
        SaveMax := Max;
        SendProgBarY := FileSize (CommFile) * Step;
        if Max < Min + SendProgBarY then Max := Min + SendProgBarY;
        SendProgBarX := Max - Min;
        Position := Min;
        Visible := True;
      end {with};
      SendProgBarCnt := 0;
      SendButton.Enabled := False;
      RecvButton.Enabled := False;
      StopButton.Enabled := True;
    end {if};
  end {if};
end;


procedure CommStop;
begin
  CloseFile (CommFile);
  with CommForm do
  begin
  CommStatusBar.SimpleText := 'Idle';	{must not be empty!}
  with SendProgressBar do
  begin
    Visible := False;
    Max := SaveMax;
  end {with};
  SendButton.Enabled := True;
  RecvButton.Enabled := True;
  StopButton.Enabled := False;
  end {with};
end;


procedure TCommForm.StopButtonClick(Sender: TObject);
begin
  CommStop;
end;


{ read a byte from the CommFile in the Send state with enabled transmission,
  otherwise returns -1 }
function CommRead: integer;
begin
  CommRead := -1;
  if (CommForm.CommStatusBar.SimpleText[1] = 'S') and (CommDelayTimer <= 0)
	and not (CommForm.FlowCheckBox.Checked and Suspend) then
  begin
    if not Eof(CommFile) then
    begin
      Read (CommFile, TransmittedCharacter);
      Inc (SendProgBarCnt, SendProgBarX);
      if SendProgBarCnt >= SendProgBarY then
      begin
        Dec (SendProgBarCnt, SendProgBarY);
        CommForm.SendProgressBar.StepIt;
      end {if};
      CommRead := integer(cardinal(TransmittedCharacter));
      if (TransmittedCharacter = $1A) and CommForm.StopEofCheckBox.Checked
	then CommStop else CommDelayTimer := XTAL * CommForm.DelaySpinEdit.Value;
    end
    else
    begin
      if CommForm.AppendEofCheckBox.Checked and (TransmittedCharacter <> $1A)
	then CommRead := $1A;
      CommStop;
    end {if};
  end {if};
end {CommRead};


{ write a byte to the CommFile in the Receive state,
  process the Xon/Xoff control characters in the Send state,
  discard otherwise }
procedure CommWrite (x: byte);
begin
  if CommForm.CommStatusBar.SimpleText[1] = 'R' then
  begin
    {$I-}
    Write (CommFile, x);
    {$I+}
    if IOResult = 0 then
    begin
      if (x = $1A) and CommForm.StopEofCheckBox.Checked then CommStop;
    end
    else
    begin
      CommStop;
      CommForm.CommStatusBar.SimpleText := 'File access error.';
    end {if};
  end
  else if CommForm.CommStatusBar.SimpleText[1] = 'S' then
  begin
    if x = $13 then Suspend := True else if x = $11 then Suspend := False;
  end {if};
end {CommWrite};


procedure TCommForm.CommFormCreate(Sender: TObject);
begin
  ForceCurrentDirectory := True;
end;

end.
