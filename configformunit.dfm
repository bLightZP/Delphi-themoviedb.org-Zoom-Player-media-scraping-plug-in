object ConfigForm: TConfigForm
  Left = 701
  Top = 352
  BorderStyle = bsDialog
  Caption = 'TheMovieDB Scraper Configuration'
  ClientHeight = 171
  ClientWidth = 318
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnKeyPress = FormKeyPress
  DesignSize = (
    318
    171)
  PixelsPerInch = 96
  TextHeight = 13
  object lblMinMediaNameLengthForScrapingByName: TLabel
    Left = 18
    Top = 75
    Width = 220
    Height = 26
    Caption = 
      'Minimum number of characters in the file/folder'#13#10'name for scrapi' +
      'ng using only the name'
  end
  object SecureCommCB: TCheckBox
    Left = 18
    Top = 12
    Width = 283
    Height = 57
    Caption = 
      'Use encrypted communication to hide search queries (not recommen' +
      'ded, searches take much longer to perform)'
    TabOrder = 0
    WordWrap = True
  end
  object OKButton: TButton
    Left = 228
    Top = 136
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 2
  end
  object CancelButton: TButton
    Left = 12
    Top = 136
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
  object edtMinMediaNameLengthForScrapingByName: TEdit
    Left = 251
    Top = 78
    Width = 50
    Height = 21
    TabOrder = 1
    OnKeyPress = edtMinMediaNameLengthForScrapingByNameKeyPress
  end
end
