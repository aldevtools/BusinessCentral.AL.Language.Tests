// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Log (71071)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Report "CurrReport.Language := n is kept and reads back at once; FormatRegion := t ... Probe wanted: whether Format of a date or number changes after Language := 1031" (probe batch 4)
// BC versions: 29 (27 and 28 by CI)
// Added by writer BV (2026-10-19, Windows check 3 item AQ): CurrReport.Language := -2 raises 'Unexpected CLR exception thrown.: System.ArgumentOutOfRangeException:
// culture (''-2'') must be a non-negative and non-zero value. (Parameter ''culture'')' on real BC (Windows 27.5 and 29.0) and on the Linux tiers. Neither asserterror
// around Report.Run nor a TryFunction around the assignment catches it: a test that does it ends with that error. Codeunit.Run does not catch it either
// (Linux BC 29.0, corpus CI run 39233212960: the test ended with the same CLR text). So no passing test can show it; report 83754 and codeunit 83755 are kept as
// the probe source, and Language_MinusTwo_CodeunitRun has no [Test] attribute (a runtime models -2 as an error no AL statement catches).

codeunit 71142 "LT PnC Log 3"
{
    SingleInstance = true;

    var
        Items: List of [Text];

    procedure Add(Value: Text)
    begin
        Items.Add(Value);
    end;

    procedure Reset()
    begin
        Clear(Items);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        Item: Text;
    begin
        foreach Item in Items do begin
            if Result <> '' then
                Result += '|';
            Result += Item;
        end;
        exit(Result);
    end;

    procedure Count(): Integer
    begin
        exit(Items.Count());
    end;
}

report 71085 "LT PnC Rpt Lang"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    var
        Log: Codeunit "LT PnC Log 3";
        Mode: Integer;

    trigger OnPreReport()
    begin
        case Mode of
            0:
                begin
                    Log.Add('lang0:' + Format(CurrReport.Language));
                    CurrReport.Language := 1031;
                    Log.Add('lang1:' + Format(CurrReport.Language));
                    Log.Add('date:' + Format(DMY2Date(5, 3, 2024)));
                    Log.Add('num:' + Format(1234.5));
                    Log.Add('region0:' + CurrReport.FormatRegion);
                    CurrReport.FormatRegion := 'de-DE';
                    Log.Add('region1:' + CurrReport.FormatRegion);
                    Log.Add('date2:' + Format(DMY2Date(5, 3, 2024)));
                    Log.Add('num2:' + Format(1234.5));
                    CurrReport.Language := 1033;
                    Log.Add('lang2:' + Format(CurrReport.Language));
                end;
            1:
                CurrReport.Language := 0;
            2:
                CurrReport.Language := -1;
            3:
                CurrReport.Language := 99999;
            4:
                begin
                    CurrReport.Language := 1031;
                    CurrReport.Language := 0;
                end;
        end;
    end;

    trigger OnPostReport()
    begin
        Log.Add('post:' + Format(CurrReport.Language));
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;
}

report 83754 "LT BV Rpt Lang Minus Two"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    var
        Log: Codeunit "LT PnC Log 3";

    trigger OnPreReport()
    begin
        Log.Add('pre:' + Format(CurrReport.Language));
        CurrReport.Language := -2;
        Log.Add('after:' + Format(CurrReport.Language));
    end;
}

codeunit 83755 "LT BV Lang Minus Two Runner"
{
    trigger OnRun()
    begin
        Report.Run(Report::"LT BV Rpt Lang Minus Two", false);
    end;
}

codeunit 71107 "LT PnC Report Language"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Language_SetAndRead()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 3";
        Rpt: Report "LT PnC Rpt Lang";
    begin
        Log.Reset();
        Rpt.Run();
        Observer.Observe('log', Log.Joined());
        Observer.Expect('log', 'lang0:1033|lang1:1031|date:03/05/24|num:1,234.5|region0:|region1:de-DE|date2:05.03.24|num2:1.234,5|lang2:1033|post:1033');
        Observer.Verify();
    end;

    [Test]
    procedure Language_Invalid()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 3";
        Rpt: Report "LT PnC Rpt Lang";
    begin
        Log.Reset();
        Rpt.SetMode(1);
        asserterror Rpt.Run();
        Observer.ObserveError('zero');
        Observer.Observe('logZero', Log.Joined());
        Clear(Rpt);
        Log.Reset();
        Rpt.SetMode(2);
        Rpt.Run();
        Observer.Observe('negative', 'no error');
        Observer.Observe('logNegative', Log.Joined());
        Clear(Rpt);
        Log.Reset();
        Rpt.SetMode(3);
        asserterror Rpt.Run();
        Observer.ObserveError('large');
        Observer.Observe('logLarge', Log.Joined());
        Clear(Rpt);
        Log.Reset();
        Rpt.SetMode(4);
        asserterror Rpt.Run();
        Observer.ObserveError('validThenZero');
        Observer.Observe('logValidThenZero', Log.Joined());
        Observer.Expect('zero|text', 'Invalid language ID supplied: 0.');
        Observer.Expect('zero|code', 'Argument');
        Observer.Expect('logZero', '');
        Observer.Expect('negative', 'no error');
        Observer.Expect('logNegative', 'post:1033');
        Observer.Expect('large|text', 'An unsupported language was selected (''99999'' - ''Requested culture is not supported by the current platform'').');
        Observer.Expect('large|code', 'ReportLanguageNotFound');
        Observer.Expect('logLarge', '');
        Observer.Expect('validThenZero|text', 'Invalid language ID supplied: 0.');
        Observer.Expect('validThenZero|code', 'Argument');
        Observer.Expect('logValidThenZero', '');
        Observer.Verify();
    end;

    // Not a [Test]: ends with the uncatchable CLR error (see the header).
    procedure Language_MinusTwo_CodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 3";
        Ok: Boolean;
        ErrText: Text;
    begin
        Log.Reset();
        ClearLastError();
        Ok := Codeunit.Run(Codeunit::"LT BV Lang Minus Two Runner");
        Observer.Observe('ok', Format(Ok));
        ErrText := GetLastErrorText();
        Observer.Observe('text_start', CopyStr(ErrText, 1, 220));
        Observer.Observe('code', GetLastErrorCode());
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;
}
