object RemoteForm: TRemoteForm
  Left = 232
  Top = 121
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Remote Control'
  ClientHeight = 36
  ClientWidth = 274
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnHide = FormHide
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object RcConnectedPanel: TPanel
    Left = 3
    Top = 6
    Width = 177
    Height = 25
    Caption = 'Disconnected'
    Color = clRed
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clSilver
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object RcActiveLed: TPanel
    Left = 187
    Top = 6
    Width = 80
    Height = 25
    Caption = 'Activity'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'RcActiveLed'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object RcSocket: TServerSocket
    Active = False
    Port = 0
    ServerType = stNonBlocking
    OnClientConnect = RcSocketClientConnect
    OnClientDisconnect = RcSocketClientDisconnect
    OnClientRead = RcSocketClientRead
    OnClientError = RcSocketClientError
    Left = 32
    Top = 8
  end
  object LedTimer: TTimer
    Enabled = False
    Interval = 300
    OnTimer = LedTimerTimer
    Left = 67
    Top = 6
  end
  object KeyUpTimer: TThreadedTimer
    Interval = 25
    OnTimer = KeyUpTimerTimer
    Left = 99
    Top = 6
  end
  object QueueTimer: TThreadedTimer
    Interval = 50
    OnTimer = QueueTimerTimer
    Left = 131
    Top = 6
  end
end
