unit GreenTree_Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, MM_ShutDown;

type

  { TGTree }

  TGTree = class(TForm)
    btOk: TButton;
    imgAbout: TImage;
    ImageListTrayXMAS: TImageList;
    imgListMenu: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    menuClose: TMenuItem;
    menuAbout: TMenuItem;
    Separator3: TMenuItem;
    menuPrinters: TMenuItem;
    menuSuspend: TMenuItem;
    menuHibernate: TMenuItem;
    menuLock: TMenuItem;
    menuLogOut: TMenuItem;
    menuReboot: TMenuItem;
    menuShutDown: TMenuItem;
    menuShutDisable: TMenuItem;
    menuShutDownM: TMenuItem;
    PopupMenuMain: TPopupMenu;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    timerShutDown: TTimer;
    TrayIcon: TTrayIcon;
    procedure btOkClick(Sender: TObject);
    procedure menuAboutClick(Sender: TObject);
    procedure menuCloseClick(Sender: TObject);
    procedure menuPrintersClick(Sender: TObject);
    procedure menuShutDisableClick(Sender: TObject);
    procedure menuShutDownClick(Sender: TObject);
    procedure menuPrinterClick(Sender: TObject);
    procedure timerShutDownTimer(Sender: TObject);

  private
    CounterShutDown: QWord;
    ShutDownType: TShutDownMode;
    ShutDownForce: Boolean;

    procedure FillPrintersMenu;

  public

  end;

var
  GTree: TGTree;

implementation

{$R *.lfm}

uses Windows, WinSpool, GreenTree_TimerForm;

{ TGTree }

procedure TGTree.menuCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TGTree.menuPrintersClick(Sender: TObject);
begin
  FillPrintersMenu;
end;

procedure TGTree.menuShutDisableClick(Sender: TObject);
begin
  timerShutDown.Enabled:= False;
end;

procedure TGTree.menuShutDownClick(Sender: TObject);
var
   newCounter: QWord;
   newForce: Boolean;

begin
    if TGTree_TimerForm.Execute(TMenuItem(Sender).Caption, newCounter, newForce) then
    begin
      ShutDownType:= TShutDownMode(TMenuItem(Sender).Tag);
      ShutDownForce:= newForce;
      if (newCounter = 0)
      then begin
             CounterShutDown:= 1;
             timerShutDownTimer(nil);
           end
      else begin
             CounterShutDown:= newCounter;
             timerShutDown.Enabled:= True;
           end;
    end;
end;

procedure TGTree.menuPrinterClick(Sender: TObject);
var
  HPrinter: THandle = 0;
  PrinterInfo2: PPrinterInfo2 =  nil;
  PrinterDefaults: TPrinterDefaults;
  BytesNeeded, BytesReturned: DWORD;
  NomeStampante: String;

begin
  try
    NomeStampante:= TMenuItem(Sender).Caption;

    //Open the printer with the administrative permissions required to modify its status.
    FillChar(PrinterDefaults, sizeof(TPrinterDefaults), 0);
    PrinterDefaults.DesiredAccess:= PRINTER_ALL_ACCESS;

    if not(OpenPrinter(PChar(NomeStampante), @HPrinter, @PrinterDefaults))
    then raise Exception.Create('Impossibile aprire la stampante. Verificare il nome.');

    // Get Memory Size and allocate PrinterInfo2
    GetPrinter(HPrinter, 2, nil, 0, @BytesNeeded);
    if (BytesNeeded = 0) then exit;
    GetMem(PrinterInfo2, BytesNeeded);

    // Get Printer Data
    if not(GetPrinter(HPrinter, 2, PByte(PrinterInfo2), BytesNeeded, @BytesReturned))
    then RaiseLastOSError;

    // Set WORK_OFFLINE Attribute
    if ((PrinterInfo2^.Attributes and PRINTER_ATTRIBUTE_WORK_OFFLINE) <> 0)
    then
        // Rremove "Work Offline"
        PrinterInfo2^.Attributes:= PrinterInfo2^.Attributes and not PRINTER_ATTRIBUTE_WORK_OFFLINE
    else
        // Add "Work Offline"
        PrinterInfo2^.Attributes := PrinterInfo2^.Attributes or PRINTER_ATTRIBUTE_WORK_OFFLINE;

    // Set New Attributes to Printer
    if not SetPrinter(HPrinter, 2, PByte(PrinterInfo2), 0)
    then RaiseLastOSError;

  finally
    // Liberiamo la memoria allocata
    FreeMem(PrinterInfo2);

    // 6. Chiudiamo l'handle della stampante
    ClosePrinter(HPrinter);
  end;
end;

procedure TGTree.timerShutDownTimer(Sender: TObject);
//var
//   cmdProcess: TProcess;

begin
  dec(CounterShutDown);
  if (CounterShutDown = 0) then
  begin
    timerShutDown.Enabled:= False;
    ShutDown(ShutDownType, ShutDownForce);
    //LockWorkStation();
(*    try
       cmdProcess:= TProcess.Create(nil);
       cmdProcess.CurrentDirectory:= ExtractFilePath(ParamStr(0));
       cmdProcess.StartupOptions:=[suoUseShowWindow];
       {$ifopt D+}
       cmdProcess.Executable :='c:\Windows\notepad.exe';
       cmdProcess.ShowWindow := swoShow;
       {$else}
       cmdProcess.Executable :='c:\Windows\System32\shutdown.exe -s -f -t now';
       cmdProcess.Options:=[poDetached];
       cmdProcess.ShowWindow := swoHIDE;
       {$endif}
       //cmdProcess.Parameters:='-s -f -t now';
       //cmdProcess.Executable:= cmdProcess.CurrentDirectory+cmdProcess.Executable; //+' -s -f -t now';
       cmdProcess.Execute;

    finally
      cmdProcess.Free;
    end;
    *)
  end;
end;

procedure TGTree.FillPrintersMenu;
var
  Flags: DWORD;
  BytesNeeded, PrintersReturned: DWORD;
  PrinterInfo2: PPrinterInfo2;
  I: Integer;
  CurrentPrinter: PPrinterInfo2;
  curPrinterName: String;
  curItem: TMenuItem;

begin
  // PRINTER_ENUM_LOCAL find local, PRINTER_ENUM_CONNECTIONS find networks
  Flags:= PRINTER_ENUM_LOCAL or PRINTER_ENUM_CONNECTIONS;

  // Get Num of Printers and Memory size
  EnumPrinters(Flags, nil, 2, nil, 0, @BytesNeeded, @PrintersReturned);
  if (BytesNeeded = 0) then exit;

  try
    GetMem(PrinterInfo2, BytesNeeded);

    // Get Printers List
    if EnumPrinters(Flags, nil, 2, PByte(PrinterInfo2), BytesNeeded, @BytesNeeded, @PrintersReturned) then
    begin
      CurrentPrinter:= PrinterInfo2;
      for i:=0 to PrintersReturned-1 do
      begin
        curPrinterName:= StrPas(CurrentPrinter^.pPrinterName);

        curItem:= menuPrinters.Find(curPrinterName);
        //If not Finded in Menu Add it
        if (curItem = nil) then
        begin
          curItem:= TMenuItem.Create(Self);
          curItem.Caption:= curPrinterName;
          curItem.OnClick:= @menuPrinterClick;
          menuPrinters.Add(curItem);
        end;

        curItem.Tag:= CurrentPrinter^.Attributes;

        if ((CurrentPrinter^.Attributes and PRINTER_ATTRIBUTE_WORK_OFFLINE) <> 0)
        then curItem.ImageIndex:= 14
        else curItem.ImageIndex:= -1;

        //Move Pointer to Next Printer
        Inc(CurrentPrinter);
      end;
    end
    else menuPrinters.Clear;

  finally
    FreeMem(PrinterInfo2);
  end;
end;

procedure TGTree.menuAboutClick(Sender: TObject);
begin
  Visible:= True;
  Application.BringToFront;
end;

procedure TGTree.btOkClick(Sender: TObject);
begin
  Visible:= False;
end;

end.

