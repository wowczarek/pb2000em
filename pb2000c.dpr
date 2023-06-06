program PB2000C;

uses
  Forms,
  Windows,
  Main in 'main.pas' {MainForm},
  Debug in 'debug.pas' {DebugForm},
  Def in 'def.pas',
  Dis in 'dis.pas',
  Asem in 'asem.pas',
  Cpu in 'cpu.pas',
  Keyboard in 'keyboard.pas',
  Lcd in 'lcd.pas',
  Port in 'port.pas',
  Decoder in 'decoder.pas',
  Exec in 'exec.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Casio PB-2000C Emulator';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TDebugForm, DebugForm);
  Application.Run;
end.
