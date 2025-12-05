program GreenTree;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  AdvancedSingleInstance,
  Interfaces, // this includes the LCL widgetset
  LCLTranslator, gettext, Translations,
  SysUtils, Forms, GreenTree_Main, GreenTree_TimerForm
  { you can add units after this };

{$R *.res}


procedure TranslateLanguage(ForceUpdate: Boolean);
var
  PODirectory, Lang, FallbackLang: String;

begin
//  if (Settings <> nil) and (Settings.Language.Translate) then
//  begin
      PODirectory:=  ExtractFilePath(ParamStr(0))+'languages'+DirectorySeparator;

      (*if (Settings.Language.LangID = '')
      then*) GetLanguageIDs(Lang, FallbackLang);
      (*else begin
             Lang:= Settings.Language.LangID;
             FallbackLang:= '';
           end;*)

      SetDefaultLang(Lang, PODirectory, 'GreenTree', ForceUpdate);
      Translations.TranslateUnitResourceStrings('LCLStrConsts',
                                                PODirectory+'lclstrconsts.%s.po',Lang,FallbackLang);
//  end;
end;

begin
  TranslateLanguage(false);
  Application.Initialize;
  Application.SingleInstanceEnabled := true;
  Application.SingleInstance.Start;
  if Application.SingleInstance.IsServer then
  begin
    RequireDerivedFormResource:=True;
    Application.Scaled:=True;
    {$PUSH}{$WARN 5044 OFF}
    Application.MainFormOnTaskbar:=False;
    {$POP}
    Application.ShowMainForm:=False;
    Application.CreateForm(TGTree, GTree);
    Application.Run;
  end;
end.

