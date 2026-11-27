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
    procedure FormCreate(Sender: TObject);
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
    procedure CheckXMas;

  public

  end;

var
  GTree: TGTree;

implementation

{$R *.lfm}

uses Windows, Registry, WinSpool, StrUtils, DateUtils, GreenTree_TimerForm;


function IsWindows11OrGreater: Boolean;
var
  Reg: TRegistry;
  BuildNum: Integer;
begin
  Result := False;
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows NT\CurrentVersion') then
    begin
      if Reg.ValueExists('CurrentBuildNumber') then
      begin
        BuildNum := StrToIntDef(Reg.ReadString('CurrentBuildNumber'), 0);
        Result := BuildNum >= 22000;
      end;
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

// Decodifica ROT13 usata da Windows 10 per i percorsi in IconStreams
function DecodeROT13(const S: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := S;
  for I := 1 to Length(Result) do
  begin
    C := Result[I];
    if (C >= 'a') and (C <= 'z') then
      Result[I] := Chr(Ord('a') + ((Ord(C) - Ord('a') + 13) mod 26))
    else if (C >= 'A') and (C <= 'Z') then
      Result[I] := Chr(Ord('A') + ((Ord(C) - Ord('A') + 13) mod 26));
  end;
end;

function TrayIconAlwaysVisible(const ARootKey: HKEY; TargetExe: String): Boolean;
const
  // Struttura IconStreams di Windows 10: header 20 byte, blocchi da 1640 byte
  WIN10_HEADER_SIZE = 20;
  WIN10_ITEM_SIZE = 1640;
  WIN10_PATH_OFFSET = 4;      // Percorso Unicode (528 byte = 264 WideChar)
  WIN10_VISIBILITY_OFFSET = 528; // Byte di stato: 0=Auto, 1=Nascondi, 2=Mostra sempre
var
  Reg: TRegistry;
  Sottochiavi: TStringList;
  I, DataSize, ItemOffset: Integer;
  RegExePath, ChiaveBase: string;
  Buffer: TBytes;
  WidePath: WideString;
  Modificato: Boolean;
begin
  Result:= False;

  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := ARootKey;

    if IsWindows11OrGreater then
    begin
      // ================= WINDOWS 11 =================
      ChiaveBase := 'Control Panel\NotifyIconSettings';
      Sottochiavi := TStringList.Create;
      try
        if Reg.OpenKey(ChiaveBase, False) then
        begin
          Reg.GetKeyNames(Sottochiavi);
          Reg.CloseKey;

          for I := 0 to Sottochiavi.Count - 1 do
          begin
            if Reg.OpenKey(ChiaveBase + '\' + Sottochiavi[I], False) then
            begin
              if Reg.ValueExists('ExecutablePath') then
              begin
                RegExePath := Reg.ReadString('ExecutablePath');
                if SameText(RegExePath, TargetExe) then
                  Reg.WriteInteger('IsPromoted', 1);
              end;
              Reg.CloseKey;
            end;
          end;
        end;
      finally
        Sottochiavi.Free;
      end;
    end
    else
    begin
      // ================= WINDOWS 10 =================
      ChiaveBase := 'Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify';
      if Reg.OpenKey(ChiaveBase, False) then
      begin
        if Reg.ValueExists('IconStreams') then
        begin
          DataSize := Reg.GetDataSize('IconStreams');
          if DataSize > WIN10_HEADER_SIZE then
          begin
            SetLength(Buffer, DataSize);
            Reg.ReadBinaryData('IconStreams', Buffer[0], DataSize);

            Modificato := False;
            ItemOffset := WIN10_HEADER_SIZE;

            while (ItemOffset + WIN10_ITEM_SIZE) <= DataSize do
            begin
              // Estrae la stringa Unicode del percorso (max 260 caratteri)
              SetString(WidePath, PWideChar(@Buffer[ItemOffset + WIN10_PATH_OFFSET]), 260);
              // Tronca al terminatore nullo
              WidePath := PWideChar(WidePath);
              RegExePath := DecodeROT13(string(WidePath));

              // Verifica corrispondenza (Windows 10 può salvare percorsi con prefisso \??\ o KnownFolder)
              if SameText(RegExePath, TargetExe) or
                 SameText(RegExePath, '\??\' + TargetExe) or
                 EndsText('\' + ExtractFileName(TargetExe), RegExePath) then
              begin
                if Buffer[ItemOffset + WIN10_VISIBILITY_OFFSET] <> $02 then
                begin
                  Buffer[ItemOffset + WIN10_VISIBILITY_OFFSET] := $02;
                  Modificato := True;
                end;
              end;

              Inc(ItemOffset, WIN10_ITEM_SIZE);
            end;

            if Modificato then
              Reg.WriteBinaryData('IconStreams', Buffer[0], DataSize);
          end;
        end;
        Reg.CloseKey;
      end;
    end;
    Result:= True;

  finally
    Reg.Free;
  end;
end;

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

procedure TGTree.CheckXMas;
var
  Anno, Mese, Giorno: Word;

begin
  DecodeDate(Now, Anno, Mese, Giorno);

  if ((Mese = 12) and (Giorno >= 8)) or
      ((Mese = 1) and (Giorno <= 6)) then
  begin
    TrayIcon.Icons:= ImageListTrayXMAS;
    TrayIcon.AnimateInterval:= 1000;
    TrayIcon.Animate :=True;
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

procedure TGTree.FormCreate(Sender: TObject);
begin
  CheckXMas;
end;

end.

