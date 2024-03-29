object SerialForm: TSerialForm
  Left = 316
  Top = 423
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
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
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
  object BufferLvlLabel: TLabel
    Left = 299
    Top = 107
    Width = 51
    Height = 13
    Caption = 'Block size:'
    Enabled = False
  end
  object BlockDelayLabel: TLabel
    Left = 402
    Top = 107
    Width = 52
    Height = 13
    Caption = 'Delay (ms):'
    Enabled = False
  end
  object PBMonitor: TGroupBox
    Left = 8
    Top = 8
    Width = 161
    Height = 89
    Caption = 'Casio'
    TabOrder = 0
    object Label3: TLabel
      Left = 47
      Top = 48
      Width = 45
      Height = 13
      Caption = 'RX Total:'
    end
    object Label4: TLabel
      Left = 47
      Top = 64
      Width = 44
      Height = 13
      Caption = 'TX Total:'
    end
    object CasioRxLabel: TLabel
      Left = 97
      Top = 48
      Width = 3
      Height = 13
    end
    object CasioTxLabel: TLabel
      Left = 97
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
      Left = 47
      Top = 19
      Width = 64
      Height = 25
      Caption = 'INT1'
      Color = clRed
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object XoffPanel: TPanel
      Left = 116
      Top = 19
      Width = 39
      Height = 25
      Caption = 'XOFF'
      TabOrder = 3
    end
  end
  object ClientMonitor: TGroupBox
    Left = 335
    Top = 8
    Width = 161
    Height = 89
    Caption = 'TCP Client'
    TabOrder = 1
    object Label1: TLabel
      Left = 46
      Top = 48
      Width = 45
      Height = 13
      Caption = 'RX Total:'
    end
    object Label2: TLabel
      Left = 46
      Top = 64
      Width = 44
      Height = 13
      Caption = 'TX Total:'
    end
    object ClientRxLabel: TLabel
      Left = 94
      Top = 48
      Width = 3
      Height = 13
    end
    object ClientTxLabel: TLabel
      Left = 94
      Top = 64
      Width = 3
      Height = 13
    end
    object ClientConnectedPanel: TPanel
      Left = 47
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
    Left = 175
    Top = 8
    Width = 155
    Height = 89
    Caption = 'RX Buffering'
    TabOrder = 2
    object QueueBar: TProgressBar
      Left = 8
      Top = 36
      Width = 140
      Height = 17
      Min = 0
      Max = 1024
      Smooth = True
      TabOrder = 1
    end
    object QueueFlush: TButton
      Left = 8
      Top = 57
      Width = 41
      Height = 25
      Caption = 'Flush'
      TabOrder = 0
      OnClick = QueueFlushClick
    end
    object CntReset: TButton
      Left = 88
      Top = 57
      Width = 60
      Height = 25
      Caption = 'Res. Cnt.'
      TabOrder = 2
      OnClick = CntResetClick
    end
    object BufferBar: TProgressBar
      Left = 8
      Top = 18
      Width = 140
      Height = 17
      Min = 0
      Max = 65535
      Smooth = True
      TabOrder = 3
    end
    object EofBtn: TButton
      Left = 52
      Top = 57
      Width = 33
      Height = 25
      Hint = 'Send EOF byte'
      Caption = 'EOF'
      ParentShowHint = False
      ShowHint = False
      TabOrder = 4
      OnClick = EofBtnClick
    end
  end
  object BtnToggle: TButton
    Left = 8
    Top = 103
    Width = 128
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
    Top = 128
    Width = 241
    Height = 172
    Caption = 'RX data'
    TabOrder = 4
    Visible = False
    object QueueLabel: TLabel
      Left = 128
      Top = 48
      Width = 58
      Height = 13
      Caption = 'QueueLabel'
    end
    object BufferLabel: TLabel
      Left = 136
      Top = 80
      Width = 54
      Height = 13
      Caption = 'BufferLabel'
      Color = clBtnFace
      ParentColor = False
    end
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
    Top = 128
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
  object BufferLvl: TEdit
    Left = 356
    Top = 104
    Width = 41
    Height = 21
    Enabled = False
    TabOrder = 6
    Text = '32'
    OnChange = BufferLvlChange
  end
  object BlockDelay: TEdit
    Left = 456
    Top = 104
    Width = 39
    Height = 21
    Enabled = False
    TabOrder = 7
    Text = '100'
    OnChange = BlockDelayChange
  end
  object cbBlocks: TCheckBox
    Left = 221
    Top = 106
    Width = 69
    Height = 17
    Caption = 'Block xfer'
    TabOrder = 8
    OnClick = cbBlocksClick
  end
  object cbXonXoff: TCheckBox
    Left = 142
    Top = 106
    Width = 77
    Height = 17
    Caption = 'XOFF/XON'
    TabOrder = 9
    OnClick = cbXonXoffClick
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
  object Int1Timer: TThreadedTimer
    Interval = 1
    OnTimer = Int1TimerTimer
    Left = 80
  end
end
