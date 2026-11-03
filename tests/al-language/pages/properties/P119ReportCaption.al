// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: request page field properties ShowCaption (field and group), Style and ExtendedDatatype on a processing only report; what TestRequestPage exposes (Visible, Caption, Value).

report 71681 "LT P119 Rep Caption"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(NoCaptionGroup)
                {
                    Caption = 'No Caption Group';
                    ShowCaption = false;
                    field(CapCtl; CapVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Cap Ctl';
                        ShowCaption = false;
                    }
                    field(StyleCtl; StyleVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Style Ctl';
                        Style = Strong;
                    }
                }
                group(CaptionGroup)
                {
                    Caption = 'Caption Group';
                    ShowCaption = true;
                    field(MailCtl; MailVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Mail Ctl';
                        ExtendedDatatype = EMail;
                    }
                    field(UrlCtl; UrlVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Url Ctl';
                        ExtendedDatatype = URL;
                    }
                }
            }
        }
    }

    var
        CapVar: Text[30];
        StyleVar: Text[30];
        MailVar: Text[80];
        UrlVar: Text[100];
}

codeunit 71682 "LT P119 RepCaption Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Facts: List of [Text];

    [Test]
    [HandlerFunctions('CaptionHandler')]
    procedure P119_ReportCaptions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Facts);
        Report.Run(Report::"LT P119 Rep Caption");
        Replay(Observer);
        Observer.Expect('cap-visible', 'Yes');
        Observer.Expect('cap-caption', 'Cap Ctl');
        Observer.Expect('style-visible', 'Yes');
        Observer.Expect('style-caption', 'Style Ctl');
        Observer.Expect('mail-visible', 'Yes');
        Observer.Expect('mail-caption', 'Mail Ctl');
        Observer.Expect('url-caption', 'Url Ctl');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ValueHandler')]
    procedure P119_ReportValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Facts);
        Report.Run(Report::"LT P119 Rep Caption");
        Replay(Observer);
        Observer.Expect('cap', 'abc');
        Observer.Expect('style', 'styled');
        Observer.Expect('mail', 'a@b.example');
        Observer.Expect('url', 'https://example.invalid');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure CaptionHandler(var RP: TestRequestPage "LT P119 Rep Caption")
    begin
        Facts.Add('cap-visible=' + Format(RP.CapCtl.Visible()));
        Facts.Add('cap-caption=' + RP.CapCtl.Caption());
        Facts.Add('style-visible=' + Format(RP.StyleCtl.Visible()));
        Facts.Add('style-caption=' + RP.StyleCtl.Caption());
        Facts.Add('mail-visible=' + Format(RP.MailCtl.Visible()));
        Facts.Add('mail-caption=' + RP.MailCtl.Caption());
        Facts.Add('url-caption=' + RP.UrlCtl.Caption());
        RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ValueHandler(var RP: TestRequestPage "LT P119 Rep Caption")
    begin
        RP.CapCtl.SetValue('abc');
        Facts.Add('cap=' + RP.CapCtl.Value());
        RP.StyleCtl.SetValue('styled');
        Facts.Add('style=' + RP.StyleCtl.Value());
        RP.MailCtl.SetValue('a@b.example');
        Facts.Add('mail=' + RP.MailCtl.Value());
        RP.UrlCtl.SetValue('https://example.invalid');
        Facts.Add('url=' + RP.UrlCtl.Value());
        RP.Cancel().Invoke();
    end;

    local procedure Replay(var Observer: Codeunit "Probe Observer")
    var
        Line: Text;
        Pos: Integer;
    begin
        foreach Line in Facts do begin
            Pos := StrPos(Line, '=');
            Observer.Observe(CopyStr(Line, 1, Pos - 1), CopyStr(Line, Pos + 1));
        end;
    end;
}
