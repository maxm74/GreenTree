unit GreenTree_TimerForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  EditBtn, Spin;

type

  { TGTree_TimerForm }

  TGTree_TimerForm = class(TForm)
    btOk: TButton;
    btOk1: TButton;
    cbInType: TComboBox;
    cbForce: TCheckBox;
    edDate: TDateEdit;
    edIn: TSpinEdit;
    Panel1: TPanel;
    rbNow: TRadioButton;
    rbIn: TRadioButton;
    rbDateTime: TRadioButton;
    edTime: TTimeEdit;
    procedure rbDateTimeChange(Sender: TObject);
    procedure rbInChange(Sender: TObject);
    procedure rbNowChange(Sender: TObject);

  private
     procedure UI_Update;

  public
     class function Execute(ATitle:String; var ASeconds: QWord; var AForce: Boolean): Boolean;
  end;

var
  GTree_TimerForm: TGTree_TimerForm = nil;

implementation

{$R *.lfm}

uses DateUtils;

{ TGTree_TimerForm }

procedure TGTree_TimerForm.rbInChange(Sender: TObject);
begin
  rbDateTime.Checked:= not(rbIn.Checked);
  rbNow.Checked:= rbDateTime.Checked;
  UI_Update;
end;

procedure TGTree_TimerForm.rbNowChange(Sender: TObject);
begin
  rbIn.Checked:= not(rbNow.Checked);
  rbDateTime.Checked:= rbIn.Checked;
  UI_Update;
end;

procedure TGTree_TimerForm.UI_Update;
begin
  edIn.Enabled:= rbIn.Checked;
  cbInType.Enabled:= rbIn.Checked;
  edDate.Enabled:= rbDateTime.Checked;
  edTime.Enabled:= rbDateTime.Checked;
end;

procedure TGTree_TimerForm.rbDateTimeChange(Sender: TObject);
begin
  rbIn.Checked:= not(rbDateTime.Checked);
  rbNow.Checked:= rbIn.Checked;
  UI_Update;
end;

class function TGTree_TimerForm.Execute(ATitle:String; var ASeconds: QWord; var AForce: Boolean): Boolean;
begin
  Result:= False;
  try
     if (GTree_TimerForm = nil)
     then GTree_TimerForm:= TGTree_TimerForm.Create(nil);

     if (GTree_TimerForm <> nil) then
     with GTree_TimerForm do
     try
        Caption:='Timer '+ATitle;
        edDate.Date:= Now;
        Result:= (ShowModal = mrOK);

        if Result then
        begin
          AForce:= cbForce.Checked;

          if rbIn.Checked then
          begin
            Case cbInType.ItemIndex of
            0: ASeconds:= edIn.Value*60;   //minutes
            1: ASeconds:= edIn.Value*3600; //hours
            2: ASeconds:= edIn.Value;      //seconds
            3: ASeconds:= edIn.Value*86400;//days
            end;
          end
          else if rbDateTime.Checked
               then ASeconds:= SecondsBetween(Now, edDate.Date+edTime.Time)
               else ASeconds:= 0;
        end;
     finally
     end;

  finally
    GTree_TimerForm.Free; GTree_TimerForm:= nil;
  end;
end;

end.

