object CommForm: TCommForm
  Left = 192
  Top = 112
  Width = 203
  Height = 378
  Caption = 'Comm. Window'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = CommFormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object DelayLabel: TLabel
    Left = 24
    Top = 100
    Width = 68
    Height = 16
    Caption = 'Char delay:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object SendProgressBar: TProgressBar
    Left = 24
    Top = 24
    Width = 145
    Height = 17
    Min = 0
    Max = 100
    Step = 1
    TabOrder = 0
    Visible = False
  end
  object SendButton: TButton
    Left = 40
    Top = 56
    Width = 113
    Height = 25
    Caption = 'Send'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    TabStop = False
    OnClick = SendButtonClick
  end
  object DelaySpinEdit: TSpinEdit
    Left = 112
    Top = 96
    Width = 57
    Height = 26
    TabStop = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    MaxValue = 250
    MinValue = 0
    ParentFont = False
    TabOrder = 2
    Value = 0
  end
  object FlowCheckBox: TCheckBox
    Left = 24
    Top = 128
    Width = 137
    Height = 17
    TabStop = False
    Alignment = taLeftJustify
    Caption = 'Xon/Xoff'
    Checked = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    State = cbChecked
    TabOrder = 3
  end
  object AppendEofCheckBox: TCheckBox
    Left = 24
    Top = 152
    Width = 137
    Height = 17
    TabStop = False
    Alignment = taLeftJustify
    Caption = 'Append EOF'
    Checked = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    State = cbChecked
    TabOrder = 4
  end
  object RecvButton: TButton
    Left = 40
    Top = 192
    Width = 113
    Height = 25
    Caption = 'Receive'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    TabStop = False
    OnClick = RecvButtonClick
  end
  object StopEofCheckBox: TCheckBox
    Left = 24
    Top = 296
    Width = 137
    Height = 17
    TabStop = False
    Alignment = taLeftJustify
    Caption = 'Stop upon EOF'
    Checked = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    State = cbChecked
    TabOrder = 6
  end
  object StopButton: TButton
    Left = 40
    Top = 256
    Width = 113
    Height = 25
    Caption = 'Stop'
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 7
    TabStop = False
    OnClick = StopButtonClick
  end
  object CommStatusBar: TStatusBar
    Left = 0
    Top = 332
    Width = 195
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = 'Idle'
  end
  object OpenDialog1: TOpenDialog
    Left = 8
    Top = 224
  end
  object SaveDialog1: TSaveDialog
    Left = 40
    Top = 224
  end
end
