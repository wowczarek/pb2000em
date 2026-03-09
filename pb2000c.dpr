program PB2000C;

uses
  Forms,
  Windows,
  Main in 'main.pas' {MainForm},
  Debug in 'debug.pas' {DebugForm},
  Comm in 'comm.pas' {CommForm},
  Def in 'def.pas',
  Dis in 'dis.pas',
  Asem in 'asem.pas',
  Cpu in 'cpu.pas',
  Keyboard in 'keyboard.pas',
  Lcd in 'lcd.pas',
  Port in 'port.pas',
  Decoder in 'decoder.pas',
  Exec in 'exec.pas',
  Fdd in 'fdd.pas',
  Dos in 'dos.pas',
  Bios in 'bios.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Casio PB-2000C Emulator';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TDebugForm, DebugForm);
  Application.CreateForm(TCommForm, CommForm);
  Application.Run;
end.
