unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs,
  FMX.Objects, FMX.ListBox, FMX.Layouts, FMX.Edit, FMX.Printer, FMX.TabControl,
  FMX.Memo, FMX.StdCtrls;

type
  TForm1 = class(TForm)
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    Label1: TLabel;
    ComboBox1: TComboBox;
    Path2: TPath;
    Path3: TPath;
    Path1: TPath;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Line1: TLine;
    Line2: TLine;
    Line3: TLine;
    Line4: TLine;
    Line5: TLine;
    Circle2: TCircle;
    Circle3: TCircle;
    Circle4: TCircle;
    Circle5: TCircle;
    Circle6: TCircle;
    Circle7: TCircle;
    Circle8: TCircle;
    Circle9: TCircle;
    TabItem3: TTabItem;
    Ellipse2: TEllipse;
    Ellipse3: TEllipse;
    Ellipse4: TEllipse;
    Ellipse1: TEllipse;
    Circle1: TCircle;
    Circle10: TCircle;
    Circle11: TCircle;
    Circle12: TCircle;
    Circle13: TCircle;
    Circle14: TCircle;
    Circle15: TCircle;
    Circle16: TCircle;
    Path4: TPath;
    Label5: TLabel;
    Memo1: TMemo;
    Rectangle1: TRectangle;
    Text1: TText;
    Rectangle2: TRectangle;
    Rectangle3: TRectangle;
    Text2: TText;
    Text3: TText;
    ComboBox2: TComboBox;
    Label6: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  Label1.Font.Family := Combobox1.Selected.Text;

  Text1.Font.Family := Combobox1.Selected.Text;
  Text2.Font.Family := Combobox1.Selected.Text;
  Text3.Font.Family := Combobox1.Selected.Text;

  Memo1.Font.Family := Combobox1.Selected.Text;

  Canvas.Font.Family := Combobox1.Selected.Text;

  Path4.Data.Clear;
  Canvas.TextToPath(
    Path4.Data,
    Path4.BoundsRect,
    'Text to path',
    False,
    TTextAlign.Center,
    TTextAlign.Center);

  Invalidate;
end;

procedure TForm1.ComboBox2Change(Sender: TObject);
begin
  Text1.Font.Size := StrToInt(Combobox2.Selected.Text);
  Text2.Font.Size := StrToInt(Combobox2.Selected.Text);
  Text3.Font.Size := StrToInt(Combobox2.Selected.Text);

  Memo1.Font.Size := StrToInt(Combobox2.Selected.Text);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Printer.ActivePrinter;
  Combobox1.Items.Assign(Printer.Fonts);
  Combobox2.Items.Add('6');
  Combobox2.Items.Add('8');
  Combobox2.Items.Add('10');
  Combobox2.Items.Add('12');
  Combobox2.Items.Add('24');
  Combobox2.Items.Add('36');
end;

end.
