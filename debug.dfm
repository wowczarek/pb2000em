object DebugForm: TDebugForm
  Left = 133
  Top = 141
  Width = 633
  Height = 437
  Caption = 'Debug Window'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Pitch = fpFixed
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = DebugCreate
  OnHide = DebugHide
  OnShow = DebugShow
  PixelsPerInch = 96
  TextHeight = 13
  object MainGroupBox: TGroupBox
    Left = 8
    Top = 176
    Width = 609
    Height = 57
    Caption = ' Main Register File '
    TabOrder = 1
    OnClick = MainGroupBoxClick
    object MainPaintBox: TPaintBox
      Left = 8
      Top = 16
      Width = 569
      Height = 33
      Anchors = [akLeft, akTop, akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier'
      Font.Pitch = fpFixed
      Font.Style = []
      ParentFont = False
      OnMouseDown = MainPaintBoxMouseDown
      OnPaint = MainPaintBoxPaint
    end
    object MainScrollBar: TScrollBar
      Left = 584
      Top = 16
      Width = 16
      Height = 33
      Anchors = [akTop, akRight, akBottom]
      Kind = sbVertical
      Max = 0
      PageSize = 0
      TabOrder = 1
      TabStop = False
      OnScroll = MainBoxScroll
    end
    object MainEdit: TEdit
      Left = 32
      Top = 24
      Width = 40
      Height = 21
      TabStop = False
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier'
      Font.Pitch = fpFixed
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 0
      OnChange = MainEditChange
      OnKeyDown = MainEditKeyDown
    end
  end
  object BinGroupBox: TGroupBox
    Left = 8
    Top = 240
    Width = 609
    Height = 161
    Anchors = [akLeft, akTop, akBottom]
    Caption = ' Hex Editor '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Pitch = fpFixed
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = BinGroupBoxClick
    object BinPaintBox: TPaintBox
      Left = 8
      Top = 16
      Width = 569
      Height = 137
      Anchors = [akLeft, akTop, akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier'
      Font.Pitch = fpFixed
      Font.Style = []
      ParentFont = False
      OnMouseDown = BinPaintBoxMouseDown
      OnPaint = BinPaintBoxPaint
    end
    object BinScrollBar: TScrollBar
      Left = 585
      Top = 16
      Width = 16
      Height = 137
      Anchors = [akTop, akRight, akBottom]
      Kind = sbVertical
      PageSize = 0
      TabOrder = 1
      TabStop = False
      OnScroll = BinBoxScroll
    end
    object BinEdit: TEdit
      Left = 32
      Top = 32
      Width = 40
      Height = 21
      TabStop = False
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier'
      Font.Pitch = fpFixed
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 0
      OnChange = BinEditChange
      OnKeyDown = BinEditKeyDown
    end
  end
  object ListGroupBox: TGroupBox
    Left = 8
    Top = 8
    Width = 305
    Height = 161
    Caption = ' Disassembly '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Pitch = fpFixed
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = ListGroupBoxClick
    object ListPaintBox: TPaintBox
      Left = 8
      Top = 16
      Width = 265
      Height = 137
      Anchors = [akLeft, akTop, akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier'
      Font.Pitch = fpFixed
      Font.Style = []
      ParentFont = False
      OnMouseDown = ListPaintBoxMouseDown
      OnPaint = ListPaintBoxPaint
    end
    object ListScrollBar: TScrollBar
      Left = 280
      Top = 16
      Width = 16
      Height = 137
      Anchors = [akTop, akRight, akBottom]
      Kind = sbVertical
      PageSize = 0
      TabOrder = 1
      TabStop = False
      OnScroll = ListBoxScroll
    end
    object ListEdit: TEdit
      Left = 32
      Top = 32
      Width = 40
      Height = 21
      TabStop = False
      BorderStyle = bsNone
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier'
      Font.Pitch = fpFixed
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 0
      OnChange = ListEditChange
      OnKeyDown = ListEditKeyDown
    end
  end
  object RegGroupBox: TGroupBox
    Left = 320
    Top = 8
    Width = 137
    Height = 161
    Caption = ' Registers '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Pitch = fpFixed
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = RegGroupBoxClick
    object RegPaintBox: TPaintBox
      Left = 8
      Top = 16
      Width = 97
      Height = 137
      Anchors = [akLeft, akTop, akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier'
      Font.Pitch = fpFixed
      Font.Style = []
      ParentFont = False
      OnMouseDown = RegPaintBoxMouseDown
      OnPaint = RegPaintBoxPaint
    end
    object RegScrollBar: TScrollBar
      Left = 112
      Top = 16
      Width = 16
      Height = 137
      Anchors = [akTop, akRight, akBottom]
      Kind = sbVertical
      Max = 0
      PageSize = 0
      TabOrder = 1
      TabStop = False
      OnScroll = RegBoxScroll
    end
    object RegEdit: TEdit
      Left = 32
      Top = 32
      Width = 40
      Height = 21
      TabStop = False
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier'
      Font.Pitch = fpFixed
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 0
      OnChange = RegEditChange
      OnKeyDown = RegEditKeyDown
    end
  end
  object StepGroupBox: TGroupBox
    Left = 464
    Top = 8
    Width = 153
    Height = 49
    Caption = ' Single step '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Pitch = fpFixed
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = StepGroupBoxClick
    object StepButton: TButton
      Left = 80
      Top = 16
      Width = 57
      Height = 25
      Caption = 'Run'
      TabOrder = 0
      TabStop = False
      OnClick = StepButtonClick
    end
  end
  object TraceGroupBox: TGroupBox
    Left = 464
    Top = 64
    Width = 153
    Height = 49
    Caption = ' Number of steps (decimal) '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Pitch = fpFixed
    Font.Style = []
    ParentFont = False
    TabOrder = 6
    OnClick = TraceGroupBoxClick
    object TraceEdit: TEdit
      Left = 16
      Top = 16
      Width = 49
      Height = 21
      TabStop = False
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier'
      Font.Pitch = fpFixed
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnChange = TraceEditChange
      OnClick = TraceGroupBoxClick
    end
    object TraceButton: TButton
      Left = 80
      Top = 16
      Width = 57
      Height = 25
      Caption = 'Run'
      TabOrder = 0
      TabStop = False
      OnClick = TraceButtonClick
    end
  end
  object BpGroupBox: TGroupBox
    Left = 464
    Top = 120
    Width = 153
    Height = 49
    Caption = ' Breakpoint address (hex) '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Pitch = fpFixed
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = BpGroupBoxClick
    object BpEdit: TEdit
      Left = 16
      Top = 16
      Width = 49
      Height = 21
      TabStop = False
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier'
      Font.Pitch = fpFixed
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnChange = BpEditChange
      OnClick = BpGroupBoxClick
    end
    object BpButton: TButton
      Left = 80
      Top = 16
      Width = 57
      Height = 25
      Caption = 'Run'
      TabOrder = 0
      TabStop = False
      OnClick = BpButtonClick
    end
  end
end
