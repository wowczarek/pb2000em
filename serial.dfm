object SerialForm: TSerialForm
  Left = 199
  Top = 271
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Serial Port Monitor'
  ClientHeight = 303
  ClientWidth = 505
  Color = clBtnFace
  Constraints.MaxHeight = 330
  Constraints.MinHeight = 150
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnCreate = FormCreate
  OnHide = FormHide
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object TestLabel: TLabel
    Left = 80
    Top = 128
    Width = 3
    Height = 13
  end
  object PBMonitor: TGroupBox
    Left = 8
    Top = 8
    Width = 169
    Height = 89
    Caption = 'Casio'
    TabOrder = 0
    object Label3: TLabel
      Left = 52
      Top = 48
      Width = 45
      Height = 13
      Caption = 'Total RX:'
    end
    object Label4: TLabel
      Left = 52
      Top = 64
      Width = 44
      Height = 13
      Caption = 'Total TX:'
    end
    object CasioRxLabel: TLabel
      Left = 102
      Top = 48
      Width = 3
      Height = 13
    end
    object CasioTxLabel: TLabel
      Left = 102
      Top = 64
      Width = 3
      Height = 13
    end
    object CasioRxLed: TPanel
      Left = 8
      Top = 20
      Width = 33
      Height = 25
      Caption = 'RX'
      TabOrder = 0
    end
    object CasioTxLed: TPanel
      Left = 8
      Top = 51
      Width = 33
      Height = 25
      Caption = 'TX'
      TabOrder = 1
    end
    object PBOpenPanel: TPanel
      Left = 52
      Top = 19
      Width = 105
      Height = 25
      Caption = 'Port Closed (INT1)'
      Color = clRed
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
  end
  object ClientMonitor: TGroupBox
    Left = 328
    Top = 8
    Width = 169
    Height = 89
    Caption = 'TCP Client'
    TabOrder = 1
    object Label1: TLabel
      Left = 51
      Top = 48
      Width = 45
      Height = 13
      Caption = 'Total RX:'
    end
    object Label2: TLabel
      Left = 51
      Top = 64
      Width = 44
      Height = 13
      Caption = 'Total TX:'
    end
    object ClientRxLabel: TLabel
      Left = 99
      Top = 48
      Width = 3
      Height = 13
    end
    object ClientTxLabel: TLabel
      Left = 99
      Top = 64
      Width = 3
      Height = 13
    end
    object ClientConnectedPanel: TPanel
      Left = 52
      Top = 19
      Width = 105
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
    object ClientRxLed: TPanel
      Left = 8
      Top = 20
      Width = 33
      Height = 25
      Caption = 'RX'
      TabOrder = 1
    end
    object ClientTxLed: TPanel
      Left = 8
      Top = 51
      Width = 33
      Height = 25
      Caption = 'TX'
      TabOrder = 2
    end
  end
  object QueueMonitor: TGroupBox
    Left = 184
    Top = 8
    Width = 137
    Height = 89
    Caption = 'RX Queue'
    TabOrder = 2
    object Label5: TLabel
      Left = 8
      Top = 40
      Width = 41
      Height = 13
      Caption = 'Queued:'
    end
    object QueueLabel: TLabel
      Left = 56
      Top = 40
      Width = 3
      Height = 13
    end
    object QueueFlush: TButton
      Left = 8
      Top = 56
      Width = 57
      Height = 25
      Caption = 'Flush Q'
      TabOrder = 0
      OnClick = QueueFlushClick
    end
    object QueueBar: TProgressBar
      Left = 8
      Top = 18
      Width = 121
      Height = 17
      Min = 0
      Max = 1024
      Smooth = True
      TabOrder = 1
    end
    object CntReset: TButton
      Left = 72
      Top = 56
      Width = 57
      Height = 25
      Caption = 'Res. Cnt.'
      TabOrder = 2
      OnClick = CntResetClick
    end
  end
  object BtnToggle: TButton
    Left = 8
    Top = 103
    Width = 489
    Height = 21
    Caption = 'More...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = BtnToggleClick
  end
  object GbRx: TGroupBox
    Left = 8
    Top = 125
    Width = 241
    Height = 172
    Caption = 'RX data'
    TabOrder = 4
    Visible = False
    object RxCaptureStart: TButton
      Left = 8
      Top = 141
      Width = 180
      Height = 25
      Caption = 'Start capture'
      TabOrder = 0
      OnClick = RxCaptureStartClick
    end
    object RxCaptureClear: TButton
      Left = 192
      Top = 141
      Width = 41
      Height = 25
      Caption = 'Clear'
      TabOrder = 1
      OnClick = RxCaptureClearClick
    end
    object CasioRxAsc: TMemo
      Left = 8
      Top = 16
      Width = 73
      Height = 121
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 2
    end
    object CasioRxHex: TMemo
      Left = 80
      Top = 16
      Width = 153
      Height = 121
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 3
    end
  end
  object GbTx: TGroupBox
    Left = 256
    Top = 125
    Width = 241
    Height = 172
    Caption = 'TX data'
    TabOrder = 5
    Visible = False
    object CasioTxAsc: TMemo
      Left = 8
      Top = 16
      Width = 73
      Height = 121
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object CasioTxHex: TMemo
      Left = 80
      Top = 16
      Width = 153
      Height = 121
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 1
    end
    object TxCaptureStart: TButton
      Left = 8
      Top = 141
      Width = 180
      Height = 25
      Caption = 'Start capture'
      TabOrder = 2
      OnClick = TxCaptureStartClick
    end
    object TxCaptureClear: TButton
      Left = 192
      Top = 141
      Width = 41
      Height = 25
      Caption = 'Clear'
      TabOrder = 3
      OnClick = TxCaptureClearClick
    end
  end
  object LedTimer: TTimer
    Interval = 300
    OnTimer = LedTimerTimer
    Left = 144
  end
  object SerialSocket: TServerSocket
    Active = False
    Port = 0
    ServerType = stNonBlocking
    OnClientConnect = SerialSocketClientConnect
    OnClientDisconnect = SerialSocketClientDisconnect
    OnClientRead = SerialSocketClientRead
    OnClientError = SerialSocketClientError
    Left = 112
  end
  object Int1Timer: TTimer
    Enabled = False
    Interval = 1
    OnTimer = Int1TimerTimer
    Left = 80
  end
end
