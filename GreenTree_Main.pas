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
    timerShutDown: TTimer;
    TrayIcon: TTrayIcon;
    procedure btOkClick(Sender: TObject);
    procedure menuAboutClick(Sender: TObject);
    procedure menuCloseClick(Sender: TObject);
    procedure menuShutDisableClick(Sender: TObject);
    procedure menuShutDownClick(Sender: TObject);
    procedure timerShutDownTimer(Sender: TObject);

  private
    CounterShutDown: QWord;
    ShutDownType: TShutDownMode;
    ShutDownForce: Boolean;

  public

  end;

var
  GTree: TGTree;

implementation

{$R *.lfm}

uses Windows, (*Process,*) GreenTree_TimerForm;

{ TGTree }

procedure TGTree.menuCloseClick(Sender: TObject);
begin
  Close;
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

