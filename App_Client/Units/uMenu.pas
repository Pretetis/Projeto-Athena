unit uMenu;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects, FMX.Layouts;

type
  TfMenu = class(TForm)
    layMenu: TLayout;
    recMenu: TRectangle;
    layContainer: TLayout;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fMenu: TfMenu;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}

end.
