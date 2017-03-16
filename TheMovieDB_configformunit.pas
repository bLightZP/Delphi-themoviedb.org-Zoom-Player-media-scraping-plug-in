{$I SCRAPER_DEFINES.INC}

unit TheMovieDB_configformunit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TConfigForm = class(TForm)
    SecureCommCB: TCheckBox;
    OKButton: TButton;
    CancelButton: TButton;
    edtMinMediaNameLengthForScrapingByName: TEdit;
    lblMinMediaNameLengthForScrapingByName: TLabel;
    Label1: TLabel;
    Bevel1: TBevel;
    Image1: TImage;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure edtMinMediaNameLengthForScrapingByNameKeyPress(
      Sender: TObject; var Key: Char);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ConfigForm: TConfigForm = nil;

implementation

{$R *.dfm}

procedure TConfigForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  If Key = #27 then
  Begin
    Key := #0;
    Close;
  End;
end;

procedure TConfigForm.edtMinMediaNameLengthForScrapingByNameKeyPress(
  Sender: TObject; var Key: Char);
begin
  if not(Key in [#0..#31,'0'..'9']) then Key := #0;
end;

procedure TConfigForm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if (Self.ModalResult = mrOK) and (StrToIntDef(edtMinMediaNameLengthForScrapingByName.Text , -1) <= 0) then
  Begin
    edtMinMediaNameLengthForScrapingByName.SetFocus;
    edtMinMediaNameLengthForScrapingByName.SelectAll;
    ShowMessage('Please enter a positive number!');
    CanClose := False;
    Exit;
  End;
end;

end.


