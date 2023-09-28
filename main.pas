unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, Forms, Controls, Graphics, Dialogs, EditBtn,
  ExtCtrls, Buttons, XMLPropStorage, StdCtrls, AsyncProcess, ComCtrls, Menus,
  ueled, SynEdit, SynHighlighterCpp, SynHighlighterHTML, SynHighlighterPHP,
  SynHighlighterCss, SynHighlighterSQL, SynCompletion;

type

  { TForm1 }

  TForm1 = class(TForm)
    CheckBox1: TCheckBox;
    cbFast: TCheckBox;
    cbPIC: TCheckBox;
    CheckBox4: TCheckBox;
    cHost: TEdit;
    ccmp: TComboBox;
    crk: TComboBox;
    cUser: TEdit;
    cPass: TEdit;
    cDir: TEdit;
    Edit1: TEdit;
    Label10: TLabel;
    Label9: TLabel;
    spassword: TEdit;
    Label8: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Panel2: TPanel;
    ppSendSer: TAsyncProcess;
    BitBtn6: TBitBtn;
    OpenDialog1: TOpenDialog;
    Process2: TAsyncProcess;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    dyrektywy: TEdit;
    Label1: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    Memo1: TMemo;
    PageControl1: TPageControl;
    PopupMenu1: TPopupMenu;
    Process1: TAsyncProcess;
    Process3: TAsyncProcess;
    propstorage: TXMLPropStorage;
    rb1: TRadioButton;
    rb2: TRadioButton;
    rb3: TRadioButton;
    rb4: TRadioButton;
    rb0: TRadioButton;
    SaveDialog1: TSaveDialog;
    Splitter1: TSplitter;
    SynCssSyn1: TSynCssSyn;
    SynEdit1: TSynEdit;
    SynHTMLSyn1: TSynHTMLSyn;
    SynPHPSyn1: TSynPHPSyn;
    SynSQLSyn1: TSynSQLSyn;
    TabSheet1: TTabSheet;
    Timer1: TTimer;
    uELED1: TuELED;
    zrodlo: TFileNameEdit;
    Panel1: TPanel;
    SynCppSyn1: TSynCppSyn;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure BitBtn6Click(Sender: TObject);
    procedure cPassChange(Sender: TObject);
    procedure crkChange(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure PageControl1Changing(Sender: TObject; var AllowChange: Boolean);
    procedure Process1ReadData(Sender: TObject);
    procedure propstorageRestoreProperties(Sender: TObject);
    procedure propstorageSaveProperties(Sender: TObject);
    procedure SynEdit1Change(Sender: TObject);
    procedure Timer1StartTimer(Sender: TObject);
    procedure Timer1StopTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    s_pliki: string;
    last_searching_text: string;
    currdir: string;
    files: TStringList;
    list,list2,list3: TList;
    compile_error: boolean;
    procedure Memo1Compile;
    procedure Memo1Run;
    procedure SetFiles(aIndex: integer; aFilename: string);
    function SaveFiles: boolean;
    function IsFile(aIndex: integer; var aFile: string): boolean;
    procedure TabRestore(aIndex: integer; aFile: string);
    procedure wyszukaj(aStr: string = ''; aWstecz: boolean = false);
    procedure sfocus;
    function GetPlikWynikowy(aDyrektywy,aDefault: string): string;
    procedure NiezapisanePliki;
    function test(aExt: string; var aKompilator: string): boolean;
    function compile: string;
    procedure compile_libraries;
    procedure compile_lib(aFile,aLib,aDyrektywy: string; aDLL: boolean = false; aWin32: boolean = false);
    procedure SetRodzajKodu(aIndex: integer);
    procedure UpdateRodzajCode(aTabIndex: integer = -1);
  public

  end;

var
  Form1: TForm1;

implementation

uses
  lcltype, synedittypes, fileutil, DCPdes, DCPsha1;

{$R *.lfm}

var
  textseparator: char = '"';

function wGetLineToStr(const S: string; N: Integer; const Delims: Char; const wynik: string = ''): string;
var
  cc: boolean = false;
  w,i,l,len: SizeInt;
begin
  w:=0;
  i:=1;
  l:=0;
  len:=Length(S);
  SetLength(Result, 0);
  while (i<=len) and (w<>N) do
  begin
    if s[i] = TextSeparator then cc:=not cc;
    if (s[i] = Delims) and (not cc) then inc(w) else
    begin
      if (N-1)=w then
      begin
        inc(l);
        SetLength(Result,l);
        Result[L]:=S[i];
      end;
    end;
    inc(i);
  end;
  if result='' then result:=wynik;
end;

function wGetLineCount(aStr: string; separator: char): integer;
var
  element_count: integer = 1;
  in_quotes: boolean = false;
  i: integer;
begin
  for i:=1 to length(aStr) do
  begin
    if aStr[i]=textseparator then in_quotes:=not in_quotes;
    if not in_quotes and (aStr[i]=separator) then inc(element_count);
  end;
  if aStr='' then Result:=0 else Result:=element_count;
end;

function wCreateString(c:char;l:integer):string;
var
  s: string;
  i: integer;
begin
  s:='';
  for i:=1 to l do s:=s+c;
  result:=s;
end;

function wEncryptString(s,token: string;force_length:integer=0): string;
var
  Des3: TDCP_3des;
  ss,pom: string;
  a: integer;
begin
  ss:=s;
  a:=length(ss);
  if (force_length>0) and (a<force_length) then ss:=ss+wCreateString(' ',force_length-a);
  Des3:=TDCP_3des.Create(nil);
  try
    Des3.InitStr(token,TDCP_sha1);
    pom:=Des3.EncryptString(ss);
    Des3.Burn;
  finally
    Des3.Free;
  end;
  result:=pom;
end;

function wDecryptString(s,token: string; trim_spaces: boolean = false): string;
var
  Des3: TDCP_3des;
  pom: string;
begin
  Des3:=TDCP_3des.Create(nil);
  try
    Des3.InitStr(token,TDCP_sha1);
    pom:=Des3.DecryptString(s);
    Des3.Burn;
  finally
    Des3.Free;
  end;
  if trim_spaces then result:=trim(pom) else result:=pom;
end;

{ TForm1 }

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  SynEdit1.Lines.LoadFromFile(zrodlo.FileName);
  SynEdit1.Tag:=0;
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  SaveFiles;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  NiezapisanePliki;
  compile;
end;

procedure TForm1.BitBtn4Click(Sender: TObject);
var
  pom,s: string;
begin
  NiezapisanePliki;
  if SaveFiles then
  begin
    s:=compile;
    while Process1.Active do application.ProcessMessages;
  end else begin
    pom:=ChangeFileExt(ExtractFileName(zrodlo.FileName),'');
    s:=GetPlikWynikowy(dyrektywy.Text,pom);
  end;
  if compile_error then exit;
  Memo1Run;
  if Process2.Active then
  begin
    BitBtn5.Click;
    application.ProcessMessages;
    sleep(500);
  end;
  Process2.CurrentDirectory:=ExtractFilePath(zrodlo.FileName);
  Process2.Executable:=s;
  Process2.Execute;
  Timer1.Enabled:=true;
  sfocus;
end;

procedure TForm1.BitBtn5Click(Sender: TObject);
begin
  if Process2.Active then Process2.Terminate(0);
  sfocus;
end;

procedure TForm1.BitBtn6Click(Sender: TObject);
var
  i: integer;
  wd,plik: string;
  ss: TStringList;
begin
  if trim(cHost.Text)='' then exit;
  wd:=ExtractFilePath(zrodlo.FileName);
  Memo1.Clear;
  Memo1.Lines.Add('Katalog roboczy: '+wd);
  Memo1.Lines.Add('Wysyłam pliki źródeł na serwer:');
  ppSendSer.Executable:='lftp';
  ppSendSer.CurrentDirectory:=wd;
  for i:=0 to files.Count-1 do
  begin
    plik:=ExtractFileName(files[i]);
    if FileExists(wd+plik) then Memo1.Lines.Add('  plik: '+plik) else
    begin
      Memo1.Lines.Add('  plik: '+plik+' (IGNORED)');
      continue;
    end;
    ppSendSer.Parameters.Clear;
    ppSendSer.Parameters.Add('-u');
    ppSendSer.Parameters.Add(cUser.Text+','+Edit1.Text);
    ppSendSer.Parameters.Add('-e');
    ppSendSer.Parameters.Add('cd '+cDir.Text+'; mput '+plik+'; quit');
    ppSendSer.Parameters.Add(cHost.Text);
    //writeln(ppSendSer.Parameters.Text);
    ppSendSer.Execute;
    while ppSendSer.Active do application.ProcessMessages;
    ppSendSer.Terminate(0);
  end;
  Memo1.Lines.Add('Wszystko.');
end;

procedure TForm1.cPassChange(Sender: TObject);
begin
  if Edit1.Focused then exit;
  Edit1.Text:=wDecryptString(cPass.Text,'tyreywufdfy736473rg',true);
end;

procedure TForm1.crkChange(Sender: TObject);
begin
  //writeln('crkChange',crk.ItemIndex);
  case PageControl1.ActivePageIndex of
    0: SynEdit1.Tag:=crk.ItemIndex;
    else TSynEdit(list2[PageControl1.ActivePageIndex-1]).Tag:=crk.ItemIndex;
  end;
  UpdateRodzajCode;
end;

procedure TForm1.Edit1Change(Sender: TObject);
begin
  cPass.Text:=wEncryptString(Edit1.Text,'tyreywufdfy736473rg',50);
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if Process1.Active then
  begin
    BitBtn5.Click;
    sleep(500);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  compile_error:=false;
  list:=TList.Create;
  list2:=TList.Create;
  list3:=TList.Create;
  files:=TStringList.Create;
  files.Add('');
  SynEdit1.Tag:=0;
  propstorage.Active:=true;
end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  i: integer;
begin
  for i:=0 to list3.Count-1 do TPanel(list3[i]).Free;
  for i:=0 to list2.Count-1 do TSynEdit(list2[i]).Free;
  for i:=0 to list.Count-1 do TTabSheet(list[i]).Free;
  list.Free;
  list2.Free;
  list3.Free;
  files.Free;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
var
  vShift, vCtrl: boolean;
begin
  vShift:=ssShift in Shift;
  vCtrl:=ssCtrl in Shift;
  if vCtrl and (Key=VK_F) then wyszukaj else
  if Key=VK_F3 then wyszukaj(last_searching_text,vShift);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  if PageControl1.ActivePageIndex=0 then SynEdit1.SetFocus else TSynEdit(list2[PageControl1.ActivePageIndex-1]).SetFocus;
end;

procedure TForm1.MenuItem1Click(Sender: TObject);
var
  a: TTabSheet;
  b: TSynEdit;
  //c: TPanel;
begin
  OpenDialog1.InitialDir:=currdir;
  if OpenDialog1.Execute then
  begin
    files.Add(OpenDialog1.FileName);
    a:=TTabSheet.Create(PageControl1);
    list.Add(a);
    a.Caption:=ExtractFileName(OpenDialog1.FileName);
    a.PageControl:=PageControl1;
    b:=TSynEdit.Create(a);
    list2.Add(b);
    b.Parent:=a;
    b.Align:=alClient;
    b.Highlighter:=SynCppSyn1;
    b.Font.Assign(SynEdit1.Font);
    b.OnChange:=@SynEdit1Change;
    b.Lines.LoadFromFile(OpenDialog1.FileName);
    //c:=TPanel.Create(a);
    //list3.Add(c);
    //c.Parent:=a;
    //c.Align:=alTop;
    //c.BevelInner:=bvRaised;
    //c.BevelOuter:=bvLowered;
    //c.Height:=26;
    PageControl1.TabIndex:=list.Count;
    MenuItem2.Enabled:=true;
  end;
end;

procedure TForm1.MenuItem2Click(Sender: TObject);
var
  a: integer;
begin
  a:=PageControl1.TabIndex;
  TSynEdit(list2[a-1]).Free;
  TTabSheet(list[a-1]).Free;
  files.Delete(a);
end;

procedure TForm1.MenuItem5Click(Sender: TObject);
var
  a: TTabSheet;
  b: TSynEdit;
  //c: TPanel;
begin
  SaveDialog1.InitialDir:=currdir;
  if SaveDialog1.Execute then
  begin
    if (ExtractFileExt(SaveDialog1.FileName)='.') or (ExtractFileExt(SaveDialog1.FileName)='') then exit;
    files.Add(SaveDialog1.FileName);
    a:=TTabSheet.Create(PageControl1);
    list.Add(a);
    a.Caption:=ExtractFileName(SaveDialog1.FileName);
    a.PageControl:=PageControl1;
    b:=TSynEdit.Create(a);
    list2.Add(b);
    b.Parent:=a;
    b.Align:=alClient;
    b.Highlighter:=SynCppSyn1;
    b.Font.Assign(SynEdit1.Font);
    b.OnChange:=@SynEdit1Change;
    //b.Lines.LoadFromFile(SaveDialog1.FileName);
    //c:=TPanel.Create(a);
    //list3.Add(c);
    //c.Parent:=a;
    //c.Align:=alTop;
    //c.BevelInner:=bvRaised;
    //c.BevelOuter:=bvLowered;
    //c.Height:=26;
    PageControl1.TabIndex:=list.Count;
    MenuItem2.Enabled:=true;
  end;
end;

procedure TForm1.PageControl1Change(Sender: TObject);
begin
  //writeln('PageControl1Change',PageControl1.TabIndex);
  SetRodzajKodu(PageControl1.TabIndex);
  MenuItem2.Enabled:=PageControl1.TabIndex>0;
end;

procedure TForm1.PageControl1Changing(Sender: TObject; var AllowChange: Boolean
  );
begin
  sfocus;
end;

procedure TForm1.Process1ReadData(Sender: TObject);
var
  ss: TStringList;
begin
  if (TAsyncProcess(Sender).Name='Process1') and CheckBox1.Checked then exit;
  ss:=TStringList.Create;
  try
    ss.LoadFromStream(TAsyncProcess(Sender).Output);
    Memo1.Lines.AddText(ss.Text);
  finally
    ss.Free;
  end;
  compile_error:=(TAsyncProcess(Sender).Name='Process1') and (Memo1.Lines.Count>0);
end;

procedure TForm1.propstorageRestoreProperties(Sender: TObject);
var
  s: TStringList;
  i: integer;
begin
  (* init *)
  currdir:=GetCurrentDir;
  (* pliki kolejne *)
  propstorage.ReadStrings('def_files',files);
  if files.Count=0 then
  begin
    SynEdit1.Clear;
    exit;
  end;
  (* odtworzenie zakładek i wczytanie plików do nich *)
  for i:=0 to files.Count-1 do TabRestore(i,files[i]);
  (* odtworzenie środowiska pracy *)
  s:=TStringList.Create;
  //środowisko
  propstorage.ReadStrings('def_tabs',s);
  try
    for i:=0 to PageControl1.PageCount-1 do
    begin
      if i=0 then SynEdit1.CaretY:=StrToInt(wGetLineToStr(s[i],2,',')) else
      TSynEdit(list2[i-1]).CaretY:=StrToInt(wGetLineToStr(s[i],2,','));
    end;
    //rodzaj kodu
    propstorage.ReadStrings('def_tabs_rodzaj_code',s);
    for i:=0 to PageControl1.PageCount-1 do
    begin
      if i=0 then SynEdit1.Tag:=StrToInt(s[i]) else
      TSynEdit(list2[i-1]).Tag:=StrToInt(s[i]);
      UpdateRodzajCode(i);
    end;
  finally
    s.Free;
  end;
  PageControl1.ActivePageIndex:=propstorage.ReadInteger('def_ActivePageIndex',0);
  SetRodzajKodu(PageControl1.ActivePageIndex);
end;

procedure TForm1.propstorageSaveProperties(Sender: TObject);
var
  s: TStringList;
  i: integer;
begin
  propstorage.WriteInteger('def_ActivePageIndex',PageControl1.ActivePageIndex);
  propstorage.WriteStrings('def_files',files);
  s:=TStringList.Create;
  try
    //środowisko
    for i:=0 to PageControl1.PageCount-1 do
    begin
      if i=0 then s.Add(IntToStr(SynEdit1.CaretX)+','+IntToStr(SynEdit1.CaretY))
      else        s.Add(IntToStr(TSynEdit(list2[i-1]).CaretX)+','+IntToStr(TSynEdit(list2[i-1]).CaretY));
    end;
    propstorage.WriteStrings('def_tabs',s);
    //rodzaj kodu
    s.Clear;
    for i:=0 to PageControl1.PageCount-1 do
    begin
      if i=0 then s.Add(IntToStr(SynEdit1.Tag))
      else        s.Add(IntToStr(TSynEdit(list2[i-1]).Tag));
    end;
    propstorage.WriteStrings('def_tabs_rodzaj_code',s);
  finally
    s.Free;
  end;
end;

procedure TForm1.SynEdit1Change(Sender: TObject);
begin
  TSynEdit(Sender).Tag:=1;
  //TPanel(list3[PageControl1.ActivePageIndex-1]).Caption:=IntToStr(TSynEdit(list2[PageControl1.ActivePageIndex-1]).MarkupCount);
end;

procedure TForm1.Timer1StartTimer(Sender: TObject);
begin
  BitBtn4.Enabled:=false;
  BitBtn5.Enabled:=true;
  uEled1.Active:=Process2.Active;
end;

procedure TForm1.Timer1StopTimer(Sender: TObject);
begin
  BitBtn4.Enabled:=true;
  BitBtn5.Enabled:=false;
  uEled1.Active:=false;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled:=Process2.Active;
end;

procedure TForm1.Memo1Compile;
begin
  compile_error:=false;
  Memo1.Clear;
  Memo1.Color:=clDefault;
  Memo1.Font.Color:=clDefault;
end;

procedure TForm1.Memo1Run;
begin
  Memo1.Clear;
  Memo1.Color:=clBlack;
  Memo1.Font.Color:=clWhite;
end;

procedure TForm1.SetFiles(aIndex: integer; aFilename: string);
begin
  if aIndex<files.Count then
  begin
    files.Delete(aIndex);
    files.Insert(aIndex,aFilename);
  end else files.Add(aFilename);
end;

function TForm1.SaveFiles: boolean;
var
  i: integer;
begin
  result:=false;
  if SynEdit1.Tag=1 then
  begin
    SynEdit1.Lines.SaveToFile(zrodlo.FileName);
    SynEdit1.Tag:=0;
    result:=true;
  end;
  for i:=0 to list2.Count-1 do if TSynEdit(list2[i]).Tag=1 then
  begin
    TSynEdit(list2[i]).Lines.SaveToFile(files[i+1]);
    TSynEdit(list2[i]).Tag:=0;
    result:=true;
  end;
end;

function TForm1.IsFile(aIndex: integer; var aFile: string): boolean;
var
  b: boolean;
  s: string;
begin
  s:=aFile;
  b:=FileExists(s);
  if not b then
  begin
    s:=ExtractFileName(s);
    s:=currdir+'/'+s;
    b:=FileExists(s);
    if b then
    begin
      (* aktualizacja danych *)
      if aIndex=0 then zrodlo.FileName:=s;
      SetFiles(aIndex,s);
      aFile:=s;
    end;
  end;
  result:=b;
end;

procedure TForm1.TabRestore(aIndex: integer; aFile: string);
var
  a: TTabSheet;
  b: TSynEdit;
  s: string;
begin
  writeln(aFile);
  s:=aFile;
  if aIndex=0 then
  begin
    if IsFile(aIndex,s) then SynEdit1.Lines.LoadFromFile(s);
  end else begin
    IsFile(aIndex,s);
    a:=TTabSheet.Create(PageControl1);
    list.Add(a);
    a.Caption:=ExtractFileName(s);
    a.PageControl:=PageControl1;
    b:=TSynEdit.Create(a);
    list2.Add(b);
    b.Parent:=a;
    b.Align:=alClient;
    b.Highlighter:=SynCppSyn1;
    b.Font.Assign(SynEdit1.Font);
    b.OnChange:=@SynEdit1Change;
    if FileExists(s) then b.Lines.LoadFromFile(s);
  end;
end;

procedure TForm1.wyszukaj(aStr: string; aWstecz: boolean);
var
  s: string;
  o: TSynSearchOptions;
begin
  if aStr='' then s:=InputBox('Wyszukiwanie tekstu','Wpisz wyszukiwany fragment tekstu:','') else s:=last_searching_text;
  if s='' then exit;
  last_searching_text:=s;
  if aWstecz then o:=[ssoBackwards] else o:=[];
  if PageControl1.ActivePageIndex=0 then SynEdit1.SearchReplace(s,s,o) else TSynEdit(list2[PageControl1.ActivePageIndex-1]).SearchReplace(s,s,o);
end;

procedure TForm1.sfocus;
begin
  if PageControl1.ActivePageIndex=0 then SynEdit1.SetFocus else TSynEdit(list2[PageControl1.ActivePageIndex-1]).SetFocus;
end;

function TForm1.GetPlikWynikowy(aDyrektywy, aDefault: string): string;
var
  s: string;
  a: integer;
begin
  s:=aDyrektywy;
  a:=pos('-o',s);
  if a=0 then result:=aDefault else
  begin
    delete(s,1,a+1);
    s:=trim(s);
    result:=wGetLineToStr(s,1,' ');
  end;
end;

procedure TForm1.NiezapisanePliki;
var
  i: integer;
begin
  s_pliki:=',';
  for i:=0 to list2.Count-1 do if TSynEdit(list2[i]).Tag=1 then s_pliki:=s_pliki+IntToStr(i)+',';
  if s_pliki=',' then s_pliki:='';
end;

function TForm1.test(aExt: string; var aKompilator: string): boolean;
var
  x: string[2];
  sc,sd: string;
begin
  case ccmp.ItemIndex of
    0: begin x:='C'; sc:='gcc'; sd:=''; end;
    1: begin x:='D'; sc:=''; sd:='dmd'; end;
    2: begin x:='D'; sc:=''; sd:='gdc'; end;
    3: begin x:='CD'; sc:='gcc'; sd:='dmd'; end;
    4: begin x:='CD'; sc:='gcc'; sd:='gdc'; end;
  end;
  if (aExt='.c') and (sc<>'') then
  begin
    aKompilator:=sc;
    result:=true;
  end else
  if (aExt='.d') and (sd<>'') then
  begin
    aKompilator:=sd;
    result:=true;
  end else begin
    aKompilator:='';
    result:=false;
  end;
end;

function TForm1.compile: string;
var
  i: integer;
  ext,kompilator,s,pom,res: string;
  ok,b: boolean;
begin
  ext:=ExtractFileExt(zrodlo.FileName);
  ok:=test(ext,kompilator);
  if (not ok) or (kompilator='') then
  begin
    MessageDlg('Rozszerzenie plików nie zgadza się z wybraną opcją kompilacji. Przerywam.',mtWarning,[mbOK],0);
    exit;
  end;
  pom:=ChangeFileExt(ExtractFileName(zrodlo.FileName),'');
  res:=pom;
  b:=true;
  Memo1Compile;
  SaveFiles;
  process1.Executable:=kompilator;
  process1.CurrentDirectory:=ExtractFilePath(zrodlo.FileName);
  process1.Parameters.Clear;
  i:=1;
  while true do
  begin
    s:=wGetLineToStr(dyrektywy.Text,i,' ');
    if b then b:=pos('-o',s)=0;
    if s='' then break;
    process1.Parameters.Add(s);
    inc(i);
  end;
  res:=GetPlikWynikowy(dyrektywy.Text,pom);
  //process1.Parameters.Add('-pthread');
  //process1.Parameters.Add('-lsqlite3');
  process1.Parameters.Add(ExtractFileName(zrodlo.FileName));
  if b then
  begin
    if kompilator='dmd' then process1.Parameters.Add('-of='+pom) else
    begin
      process1.Parameters.Add('-o');
      process1.Parameters.Add(pom);
    end;
  end;
  //if (pos(',0,',s_pliki)>0) or (not FileExists(pom)) then
  Memo1.Lines.Add('*** Kompilacja programu głównego ***');
  process1.Execute;
  while process1.Active do application.ProcessMessages;
  process1.Terminate(0);
  compile_libraries;
  Memo1.Lines.Add('Wszystko.');
  sfocus;
  result:=res;
end;

procedure TForm1.compile_libraries;
var
  i,j: integer;
  s,s1,s2,s3,s4: string;
  fsource,fnazwa,x: string;
  win32: boolean;
begin
  Memo1.Lines.Add('*** Kompilacja Bibliotek ***');
  for i:=0 to list2.Count-1 do
  begin
    s:=trim(TSynEdit(list2[i]).Lines[0]);
    if pos('/* NONE */',s)>0 then continue;
    if pos('/* BIBLIOTEKA:',s)>0 then
    begin
      s:=StringReplace(s,'/*','',[]);
      s:=StringReplace(s,'*/','',[]);
      s:=trim(s);
      s1:=trim(wGetLineToStr(s,1,':'));
      s2:=trim(wGetLineToStr(s,2,':'));
      s3:=trim(wGetLineToStr(s2,1,' '));
      fnazwa:=s3+'.so';
      if (s1='BIBLIOTEKA') and ((pos(','+IntToStr(i)+',',s_pliki)>0) or (not FileExists(fnazwa))) then
      begin
        x:='';
        for j:=2 to wGetLineCount(s2,' ') do x:=x+' '+wGetLineToStr(s2,j,' ');
        x:=trim(x);
        fsource:=files[i+1];
        Memo1.Lines.Add(' - '+fsource+' => '+fnazwa);
        compile_lib(fsource,fnazwa,x);
      end;
    end else
    if pos('/* BIBLIOTEKA_DLL:',s)>0 then
    begin
      win32:=false;
      s:=StringReplace(s,'/*','',[]);
      s:=StringReplace(s,'*/','',[]);
      s:=trim(s);
      s1:=trim(wGetLineToStr(s,1,':'));
      s2:=trim(wGetLineToStr(s,2,':'));
      s3:=trim(wGetLineToStr(s,3,':'));
      if s3='' then s4:=trim(wGetLineToStr(s2,1,' ')) else
      begin
        win32:=s2='32';
        s4:=trim(wGetLineToStr(s3,1,' '));
      end;
      fnazwa:=s4+'.dll';
      if (s1='BIBLIOTEKA_DLL') and ((pos(','+IntToStr(i)+',',s_pliki)>0) or (not FileExists(fnazwa))) then
      begin
        x:='';
        for j:=2 to wGetLineCount(s2,' ') do x:=x+' '+wGetLineToStr(s2,j,' ');
        x:=trim(x);
        fsource:=files[i+1];
        Memo1.Lines.Add(' - '+fsource+' => '+fnazwa);
        compile_lib(fsource,fnazwa,x,true,win32);
      end;
    end;
  end;
end;

function wewnCopyFile(src,dest,passwd: string): boolean;
var
  p: TProcess;
begin
  p:=TProcess.Create(nil);
  try
    p.Options:=[poWaitOnExit];
    p.Executable:='/bin/sh';
    p.Parameters.Add('-c');
    p.Parameters.Add('echo '+passwd+' | sudo -S cp -f "'+src+'" "'+dest+'"');
    p.Execute;
  finally
    p.Terminate(0);
    p.Free;
  end;
  result:=p.ExitStatus=0;
end;

{
  Przykłady kompilacji:
  #gcc -O3 -shared -o libtest.so test.c
  #gcc -O3 -shared -o libtest.so -fPIC test.c
  #gcc -O3 -shared -o libtest.so -Wall test.c
}
procedure TForm1.compile_lib(aFile, aLib, aDyrektywy: string; aDLL: boolean;
  aWin32: boolean);
var
  ext,kompilator,pom,s: string;
  es: integer;
  ok,b: boolean;
  i: integer;
begin
  {
  gcc -c -fpic LibECode.c
  gcc -shared -o libecode_c.so LibECode.o -lcjson
  }
  ext:=ExtractFileExt(aFile);
  ok:=test(ext,kompilator);
  if (not ok) or (kompilator='') or ((kompilator<>'gcc') and aDLL) then
  begin
    Memo1.Lines.Add('(!) Biblioteka: '+alib+' - pominięta. (!)');
    exit;
  end;

  pom:=ExtractFilePath(aFile);
  if aDLL then
  begin
    if aWin32 then process3.Executable:='i686-w64-mingw32-gcc' else process3.Executable:='x86_64-w64-mingw32-gcc';
  end else process3.Executable:=kompilator;
  process3.CurrentDirectory:=pom;
  //gcc -c -fpic library.c
  process3.Parameters.Clear;
  process3.Parameters.Add('-c');
  if cbPIC.Checked then process3.Parameters.Add('-fPIC');
  if not rb0.Checked then
  begin
    if rb1.Checked then process3.Parameters.Add('-O1');
    if rb2.Checked then process3.Parameters.Add('-O2');
    if rb3.Checked then process3.Parameters.Add('-O3');
    if rb4.Checked then process3.Parameters.Add('-O4');
    if cbFast.Checked then process3.Parameters.Add('-Ofast');
  end;
  if aDLL then
  begin
    process3.Parameters.Add('-march=native');
  end;
  process3.Parameters.Add(ExtractFileName(aFile));
  process3.Execute;
  while process3.Active do application.ProcessMessages;
  es:=process3.ExitStatus;
  process3.Terminate(0);

  if es=0 then
  begin
    //gcc -shared -o liblibrary.so library.o -lcJSON
    process3.Parameters.Clear;
    process3.Parameters.Add('-shared');
    if aLib<>'' then
    begin
      if kompilator='dmd' then process3.Parameters.Add('-of='+aLib) else
      begin
        process3.Parameters.Add('-o');
        process3.Parameters.Add(aLib);
      end;
    end;
    process3.Parameters.Add(ChangeFileExt(ExtractFileName(aFile),'.o'));
    for i:=1 to wGetLineCount(aDyrektywy,' ') do
    begin
      s:=wGetLineToStr(aDyrektywy,i,' ');
      Memo1.Lines.Add(' + dyrektywa: '+s);
      process3.Parameters.Add(s);
    end;
    process3.Execute;
    while process3.Active do application.ProcessMessages;
    es:=process3.ExitStatus;
    process3.Terminate(0);
  end;

  if (es=0) and CheckBox4.Checked then
  begin
    s:=trim(spassword.Text);
    if s='' then b:=CopyFile(pom+aLib,'/usr/lib/'+aLib) else b:=wewnCopyFile(pom+aLib,'/usr/lib/'+aLib,s);
    if b then Memo1.Lines.Add(' - biblioteka "'+aLib+'" => skopiowana prawidłowo do katalogu LIB.') else
    Memo1.Lines.Add(' - biblioteka "'+aLib+'" => NIE skopiowana prawidłowo do katalogu LIB!');
  end;
end;

procedure TForm1.SetRodzajKodu(aIndex: integer);
begin
  case aIndex of
    0: crk.ItemIndex:=SynEdit1.Tag;
    else crk.ItemIndex:=TSynEdit(list2[aIndex-1]).Tag;
  end;
end;

procedure TForm1.UpdateRodzajCode(aTabIndex: integer);
var
  x,a: integer;
begin
  if aTabIndex=-1 then x:=PageControl1.ActivePageIndex else x:=aTabIndex;
  if x=0 then
  begin
    a:=SynEdit1.Tag;
    case a of
      0: SynEdit1.Highlighter:=SynCppSyn1;
      1: SynEdit1.Highlighter:=SynHTMLSyn1;
      2: SynEdit1.Highlighter:=SynPHPSyn1;
      3: SynEdit1.Highlighter:=SynCssSyn1;
      4: SynEdit1.Highlighter:=SynSQLSyn1;
    end;
  end else begin
    a:=TSynEdit(list2[x-1]).Tag;
    case a of
      0: TSynEdit(list2[x-1]).Highlighter:=SynCppSyn1;
      1: TSynEdit(list2[x-1]).Highlighter:=SynHTMLSyn1;
      2: TSynEdit(list2[x-1]).Highlighter:=SynPHPSyn1;
      3: TSynEdit(list2[x-1]).Highlighter:=SynCssSyn1;
      4: TSynEdit(list2[x-1]).Highlighter:=SynSQLSyn1;
    end;
  end;
end;

end.

