unit UMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Math, Jpeg, ExtDlgs;

type
  TFMain = class(TForm)
    BtOpen: TButton;
    ScrollBox1: TScrollBox;
    Label1: TLabel;
    Image1: TImage;
    OpenPictureDialog1: TOpenPictureDialog;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure BtOpenClick(Sender: TObject);
  private
    { Déclarations privées }
    procedure GetInfos;
  public
    { Déclarations publiques }
  end;

var
  FMain: TFMain;

implementation

{$R *.dfm}


// gestion de la recherche du nombre de couleur et de la couleur la plus présente
//===============================================================================
type
 PQuadArray = ^TQuadArray;
 TQuadArray = array [Byte] of longint;

 PArbreCouleur=^TArbreCouleur;
 TArbreCouleur=record
                count:integer;
                bit0,bit1:PArbreCouleur;

               end;

procedure nouvellefeuille(var feuille:PArbreCouleur);
begin
 new(feuille);
 feuille.count:=0;
 feuille.bit0:=nil;
 feuille.bit1:=nil;
end;

function ClasseCouleur(c:dword;level:byte;feuille:PArbreCouleur):integer;
begin
 if level=0 then
  begin
   inc(feuille.count);
   result:=feuille.count;
   exit;
  end;

 if c and 1=0 then
  begin
   if feuille.bit0=nil then nouvellefeuille(feuille.bit0);
   result:=ClasseCouleur(c shr 1,level-1,feuille.bit0);
  end
 else
  begin
   if feuille.bit1=nil then nouvellefeuille(feuille.bit1);
   result:=ClasseCouleur(c shr 1,level-1,feuille.bit1);
  end;
end;

procedure EffaceArbre(feuille:PArbreCouleur);
begin
 if feuille=nil then exit;
 EffaceArbre(feuille.bit0);
 EffaceArbre(feuille.bit1);
 dispose(feuille);
end;

function ChercheMin(bitmap:tbitmap):integer;
var
 i:integer;
 q:PQuadArray;
 n,m:integer;
 arbre:PArbreCouleur;
 tmpPF: TPixelFormat;
begin
 nouvellefeuille(arbre);
 tmpPF:=bitmap.PixelFormat;
 bitmap.PixelFormat:=pf32bit;
 q:=bitmap.scanline[bitmap.height-1];

 m:=$7FFFFFFF;
 result:=$000000;

 for i:=0 to bitmap.height*bitmap.Width-1 do
  begin
   n:=ClasseCouleur(q[i],32,arbre);
   if n>m then begin m:=n;result:=q[i]; end;
  end;
 EffaceArbre(arbre);

 bitmap.PixelFormat:=tmpPF;
end;

function ChercheMax(bitmap:tbitmap):integer;
var
 i:integer;
 q:PQuadArray;
 n,m:integer;
 arbre:PArbreCouleur;
 tmpPF: TPixelFormat;
begin
 nouvellefeuille(arbre);
 tmpPF:=bitmap.PixelFormat;
 bitmap.PixelFormat:=pf32bit;
 q:=bitmap.scanline[bitmap.height-1];

 m:=0;
 result:=$FFFFFF;

 for i:=0 to bitmap.height*bitmap.Width-1 do
  begin
   n:=ClasseCouleur(q[i],32,arbre);
   if n>m then begin m:=n;result:=q[i]; end;
  end;
 EffaceArbre(arbre);

 bitmap.PixelFormat:=tmpPF;
end;

function CompteCouleurs(bitmap:tbitmap):integer;
var
 i:integer;
 q:PQuadArray;
 arbre:PArbreCouleur;
 tmpPF: TPixelFormat;
begin
 nouvellefeuille(arbre);
 tmpPF:=bitmap.PixelFormat;
 bitmap.PixelFormat:=pf32bit;
 q:=bitmap.scanline[bitmap.height-1];

 result:=0;
 for i:=0 to bitmap.height*bitmap.Width-1 do
  begin
   if ClasseCouleur(q[i],32,arbre)=1 then inc(result);
  end;
 EffaceArbre(arbre);

 bitmap.PixelFormat:=tmpPF;
end;

procedure TFMain.GetInfos;
begin
 label1.Caption:=
    'Size = '+inttostr(image1.Picture.Bitmap.Width)+
    'x'+inttostr(image1.Picture.Bitmap.Height)+
    ' = '+inttostr(image1.Picture.Bitmap.Width*image1.Picture.Bitmap.Height)+' pixels';

 label2.Caption:=
    'Colors count = '+inttostr(CompteCouleurs(image1.Picture.Bitmap))+
    ', Min = $'+inttohex(ChercheMin(image1.Picture.Bitmap),8)+
    ' - Max = $'+inttohex(ChercheMax(image1.Picture.Bitmap),8);
end;

procedure TFMain.FormCreate(Sender: TObject);
begin
 GetInfos;
end;

procedure TFMain.BtOpenClick(Sender: TObject);
var
 name:string;
 jpg:tjpegimage;
begin
  if not OpenPictureDialog1.Execute then exit;
  name:=OpenPictureDialog1.FileName;

  if lowercase(extractfileext(name))='.bmp' then
    image1.Picture.Bitmap.LoadFromFile(Name);
  if lowercase(extractfileext(name))='.jpg' then
   begin
    jpg:=tjpegimage.Create;
    jpg.LoadFromFile(name);

    image1.Picture.Bitmap.Assign(jpg);
    jpg.Free;
   end;

 GetInfos;
end;

end.
