// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: request page label properties MultiLine, ShowCaption and Visible. A label is a TestRequestPage member like on a page (TestPageLabelControlContracts.al): Visible, Caption and Value are observed.

report 71683 "LT P119 Rep Labels"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    label(HintMulti)
                    {
                        ApplicationArea = All;
                        Caption = 'Multi line hint';
                        MultiLine = true;
                    }
                    label(HintNoCaption)
                    {
                        ApplicationArea = All;
                        Caption = 'No caption hint';
                        ShowCaption = false;
                    }
                    label(HintHidden)
                    {
                        ApplicationArea = All;
                        Caption = 'Hidden hint';
                        Visible = false;
                    }
                    field(TxtCtl; TxtVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Txt Ctl';
                    }
                }
            }
        }
    }

    var
        TxtVar: Text[30];
}

codeunit 71684 "LT P119 RepLabels Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Facts: List of [Text];

    [Test]
    [HandlerFunctions('LabelHandler')]
    procedure P119_ReportLabels()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Facts);
        asserterror Report.Run(Report::"LT P119 Rep Labels");
        Observer.ObserveError('af69');
        Replay(Observer);
        Observer.Expect('af69|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af69|code', 'TestFieldNotFound');
        Observer.Expect('multi-visible', 'Yes');
        Observer.Expect('multi-caption', 'Multi line hint');
        Observer.Expect('multi-value', 'Multi line hint');
        Observer.Expect('nocaption-visible', 'Yes');
        Observer.Expect('nocaption-caption', 'No caption hint');
        Observer.Expect('nocaption-value', 'No caption hint');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure LabelHandler(var RP: TestRequestPage "LT P119 Rep Labels")
    begin
        Facts.Add('multi-visible=' + Format(RP.HintMulti.Visible()));
        Facts.Add('multi-caption=' + RP.HintMulti.Caption());
        Facts.Add('multi-value=' + RP.HintMulti.Value());
        Facts.Add('nocaption-visible=' + Format(RP.HintNoCaption.Visible()));
        Facts.Add('nocaption-caption=' + RP.HintNoCaption.Caption());
        Facts.Add('nocaption-value=' + RP.HintNoCaption.Value());
        Facts.Add('hidden-visible=' + Format(RP.HintHidden.Visible()));
        Facts.Add('hidden-caption=' + RP.HintHidden.Caption());
        Facts.Add('txt-visible=' + Format(RP.TxtCtl.Visible()));
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
