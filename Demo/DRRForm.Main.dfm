object DRRMainForm: TDRRMainForm
  Left = 0
  Top = 0
  Caption = 'Delphi RdRnd Library demo'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object PageControlMain: TPageControl
    Left = 0
    Top = 0
    Width = 624
    Height = 441
    ActivePage = TabSheetAPIDemo
    Align = alClient
    TabOrder = 0
    object TabSheetAPIDemo: TTabSheet
      Caption = 'API demo'
      object PanelTop: TPanel
        Left = 0
        Top = 0
        Width = 616
        Height = 181
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object LabelRDRAND: TLabel
          Left = 16
          Top = 14
          Width = 50
          Height = 15
          Caption = 'RDRAND:'
        end
        object LabelRDSEED: TLabel
          Left = 16
          Top = 35
          Width = 44
          Height = 15
          Caption = 'RDSEED:'
        end
        object ButtonRDRAND64: TButton
          Left = 16
          Top = 64
          Width = 130
          Height = 30
          Caption = 'RDRAND64'
          TabOrder = 0
          OnClick = ButtonRDRAND64Click
        end
        object ButtonRDSEED64: TButton
          Left = 152
          Top = 64
          Width = 130
          Height = 30
          Caption = 'RDSEED64'
          TabOrder = 1
          OnClick = ButtonRDSEED64Click
        end
        object ButtonTryRDRAND64: TButton
          Left = 288
          Top = 64
          Width = 130
          Height = 30
          Caption = 'TryRDRAND64'
          TabOrder = 2
          OnClick = ButtonTryRDRAND64Click
        end
        object ButtonTryRDSEED64: TButton
          Left = 424
          Top = 64
          Width = 130
          Height = 30
          Caption = 'TryRDSEED64'
          TabOrder = 3
          OnClick = ButtonTryRDSEED64Click
        end
        object ButtonRDRAND32: TButton
          Left = 16
          Top = 100
          Width = 130
          Height = 30
          Caption = 'RDRAND32'
          TabOrder = 4
          OnClick = ButtonRDRAND32Click
        end
        object ButtonRDSEED32: TButton
          Left = 152
          Top = 100
          Width = 130
          Height = 30
          Caption = 'RDSEED32'
          TabOrder = 5
          OnClick = ButtonRDSEED32Click
        end
        object ButtonTryRDRAND32: TButton
          Left = 288
          Top = 100
          Width = 130
          Height = 30
          Caption = 'TryRDRAND32'
          TabOrder = 6
          OnClick = ButtonTryRDRAND32Click
        end
        object ButtonTryRDSEED32: TButton
          Left = 424
          Top = 100
          Width = 130
          Height = 30
          Caption = 'TryRDSEED32'
          TabOrder = 7
          OnClick = ButtonTryRDSEED32Click
        end
        object ButtonStressTest: TButton
          Left = 16
          Top = 136
          Width = 266
          Height = 30
          Caption = 'RDSEED entropy stress test'
          TabOrder = 8
          OnClick = ButtonStressTestClick
        end
        object ButtonFillRandom: TButton
          Left = 288
          Top = 136
          Width = 130
          Height = 30
          Caption = 'TryFillRandom'
          TabOrder = 9
          OnClick = ButtonFillRandomClick
        end
        object ButtonClearLog: TButton
          Left = 424
          Top = 136
          Width = 130
          Height = 30
          Caption = 'Clear log'
          TabOrder = 10
          OnClick = ButtonClearLogClick
        end
      end
      object MemoLog: TMemo
        Left = 0
        Top = 181
        Width = 616
        Height = 230
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
    object TabSheetRandomness: TTabSheet
      Caption = 'Randomness bitmaps'
      object LabelBitmapRTL: TLabel
        Left = 16
        Top = 56
        Width = 104
        Height = 15
        Caption = 'Delphi RTL Random'
      end
      object LabelBitmapRDRAND: TLabel
        Left = 336
        Top = 56
        Width = 47
        Height = 15
        Caption = 'RDRAND'
      end
      object ImageRTLRandom: TImage
        Left = 16
        Top = 76
        Width = 256
        Height = 256
      end
      object ImageRDRAND: TImage
        Left = 336
        Top = 76
        Width = 256
        Height = 256
      end
      object ButtonGenerateBitmaps: TButton
        Left = 16
        Top = 12
        Width = 180
        Height = 30
        Caption = 'Generate bitmaps'
        TabOrder = 0
        OnClick = ButtonGenerateBitmapsClick
      end
      object ButtonGenerateColorBitmaps: TButton
        Left = 212
        Top = 12
        Width = 180
        Height = 30
        Caption = 'Generate color bitmaps'
        TabOrder = 1
        OnClick = ButtonGenerateColorBitmapsClick
      end
    end
    object TabSheetStatistics: TTabSheet
      Caption = 'Statistical tests'
      object PanelStatistics: TPanel
        Left = 0
        Top = 0
        Width = 616
        Height = 54
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object ButtonRunStatistics: TButton
          Left = 16
          Top = 12
          Width = 180
          Height = 30
          Caption = 'Run statistical tests'
          TabOrder = 0
          OnClick = ButtonRunStatisticsClick
        end
      end
      object MemoStatistics: TMemo
        Left = 0
        Top = 54
        Width = 616
        Height = 357
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
  end
end
