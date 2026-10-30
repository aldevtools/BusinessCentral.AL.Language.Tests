// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own test codeunit 91351
// Probe: observe probe (writer Y7, 2026-10-30, asked by an al-runtime-rs runtime agent); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: Evaluate(Date, Text, 9) (the XML format) of white space alone (TAB, two TABs, blank, two blanks, CR, LF, CR LF, VT, FF, no-break space, empty) and of
//   white space around the XML date 2026-10-16: the Boolean result and the value after (Format(D, 0, 9); D starts as 2000-01-01), and the same text used as a
//   statement (result unused): the value or the error text and code. misc/lt-np4-probes/Np4Misc.al pins TAB with the default format;
//   errors/lt-ms-refusals-130/P130EvaluateDate.al pins the format 9 forms without white space.
// BC versions: 27, 28, 29

codeunit 91351 "LT Y7 Evaluate Date Fmt9 Space"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Ch(Code: Integer): Text
    var
        C: Text[1];
    begin
        C[1] := Code;
        exit(C);
    end;

    [TryFunction]
    local procedure TryStatement(Txt: Text; var D: Date)
    begin
        Evaluate(D, Txt, 9);
    end;

    local procedure Both(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        D: Date;
        Ok: Boolean;
    begin
        D := 20000101D;
        Ok := Evaluate(D, Txt, 9);
        Observer.Observe(Name + ' fn', Format(Ok) + '|' + Format(D, 0, 9));
        D := 20000101D;
        ClearLastError();
        if TryStatement(Txt, D) then
            Observer.Observe(Name + ' stmt', 'ok|' + Format(D, 0, 9))
        else
            Observer.Observe(Name + ' stmt', CopyStr('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(D, 0, 9), 1, 600));
        ClearLastError();
    end;

    [Test]
    procedure Y7_EvaluateDate_Format9_WhiteSpaceAlone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'tab', Ch(9));
        Both(Observer, 'tab tab', Ch(9) + Ch(9));
        Both(Observer, 'blank', ' ');
        Both(Observer, 'two blanks', '  ');
        Both(Observer, 'cr', Ch(13));
        Both(Observer, 'lf', Ch(10));
        Both(Observer, 'cr lf', Ch(13) + Ch(10));
        Both(Observer, 'vt', Ch(11));
        Both(Observer, 'ff', Ch(12));
        Both(Observer, 'nbsp', Ch(160));
        Both(Observer, 'empty', '');
        Observer.Expect('tab fn', 'Yes|');
        Observer.Expect('tab stmt', 'ok|');
        Observer.Expect('tab tab fn', 'Yes|');
        Observer.Expect('tab tab stmt', 'ok|');
        Observer.Expect('blank fn', 'Yes|');
        Observer.Expect('blank stmt', 'ok|');
        Observer.Expect('two blanks fn', 'Yes|');
        Observer.Expect('two blanks stmt', 'ok|');
        Observer.Expect('cr fn', 'Yes|');
        Observer.Expect('cr stmt', 'ok|');
        Observer.Expect('lf fn', 'Yes|');
        Observer.Expect('lf stmt', 'ok|');
        Observer.Expect('cr lf fn', 'Yes|');
        Observer.Expect('cr lf stmt', 'ok|');
        Observer.Expect('vt fn', 'Yes|');
        Observer.Expect('vt stmt', 'ok|');
        Observer.Expect('ff fn', 'Yes|');
        Observer.Expect('ff stmt', 'ok|');
        Observer.Expect('nbsp fn', 'Yes|');
        Observer.Expect('nbsp stmt', 'ok|');
        Observer.Expect('empty fn', 'Yes|');
        Observer.Expect('empty stmt', 'ok|');
        Observer.Verify();
    end;

    [Test]
    procedure Y7_EvaluateDate_Format9_WhiteSpaceAround()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'tab before', Ch(9) + '2026-10-16');
        Both(Observer, 'tab after', '2026-10-16' + Ch(9));
        Both(Observer, 'blank before', ' 2026-10-16');
        Both(Observer, 'blank after', '2026-10-16 ');
        Both(Observer, 'cr lf after', '2026-10-16' + Ch(13) + Ch(10));
        Both(Observer, 'lf before', Ch(10) + '2026-10-16');
        Both(Observer, 'nbsp after', '2026-10-16' + Ch(160));
        Both(Observer, 'tab inside', '2026-10' + Ch(9) + '-16');
        Observer.Expect('tab before fn', 'Yes|2026-10-16');
        Observer.Expect('tab before stmt', 'ok|2026-10-16');
        Observer.Expect('tab after fn', 'Yes|2026-10-16');
        Observer.Expect('tab after stmt', 'ok|2026-10-16');
        Observer.Expect('blank before fn', 'Yes|2026-10-16');
        Observer.Expect('blank before stmt', 'ok|2026-10-16');
        Observer.Expect('blank after fn', 'Yes|2026-10-16');
        Observer.Expect('blank after stmt', 'ok|2026-10-16');
        Observer.Expect('cr lf after fn', 'Yes|2026-10-16');
        Observer.Expect('cr lf after stmt', 'ok|2026-10-16');
        Observer.Expect('lf before fn', 'Yes|2026-10-16');
        Observer.Expect('lf before stmt', 'ok|2026-10-16');
        Observer.Expect('nbsp after fn', 'Yes|2026-10-16');
        Observer.Expect('nbsp after stmt', 'ok|2026-10-16');
        Observer.Expect('tab inside fn', 'No|2000-01-01');
        Observer.Expect('tab inside stmt', 'error:The format of the Date ''2026-10\t-16'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate|2000-01-01');
        Observer.Verify();
    end;
}
