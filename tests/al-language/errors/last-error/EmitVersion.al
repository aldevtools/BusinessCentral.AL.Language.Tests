// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); helper codeunit 71928 (not a test codeunit)
// Probe: the emit version number of the missing-object error. The Observer scrubs it in the text ("emit version n"), so it is cut out of
//   the text and observed on its own: its digits, its value div 1000 (the BC major) and, on BC 29.0, the value itself (the CI pins the
//   29.0 build 29.0.54011.55816; the 27.5 and 28.5 legs take the newest build of the minor, whose number changes with the build: seen
//   27025 on 27.5 and 28015 on 28.5). Also: the same number for a missing codeunit, table (RecordRef.Open), page and report, called
//   from the test method and from a helper codeunit. Only the text from "An object with that ID" on is observed: the caller the text
//   names differs between the CI and a local container with another test runner (a local BC 28.5 named the test codeunit for every
//   kind, where the corpus pins "Test Runner - Mgt", errors/error-texts/AzErrorTexts.al:110-134), and it is not what this file asks.
// Facts wanted by al-runtime-rs (assumption missing-object-emit-version-from-artifact): the number is the constant
//   EmitVersion.CodeEmitVersion of Microsoft.Dynamics.Nav.CodeAnalysis.dll of the build's platform artifact (29022 in 29.0.54011.55816).
// BC versions: 27.5, 28.5, 29.0

codeunit 71928 "LT P160 Missing Caller"
{
    procedure RunMissingCodeunit()
    begin
        Codeunit.Run(71998);
    end;
}

codeunit 71927 "LT P160 Emit Version"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";

    // The text after "compiled with emit version " without the final period; '' when the text has no such ending.
    local procedure NumberOf(Txt: Text): Text
    var
        Tag: Text;
        At: Integer;
    begin
        Tag := 'compiled with emit version ';
        At := StrPos(Txt, Tag);
        if (At = 0) or (CopyStr(Txt, StrLen(Txt), 1) <> '.') then
            exit('');
        exit(CopyStr(Txt, At + StrLen(Tag), StrLen(Txt) - At - StrLen(Tag)));
    end;

    // Observes the text and code of the last error, and the shape of its number; returns the number.
    local procedure ObserveMissing(Name: Text) Number: Text
    var
        Txt: Text;
        N: Integer;
    begin
        Txt := GetLastErrorText();
        Observer.Observe(Name + '|tail', CopyStr(Txt, StrPos(Txt, 'An object with that ID')));
        Observer.Observe(Name + '|code', GetLastErrorCode());
        Number := NumberOf(Txt);
        Observer.Observe(Name + ' digits', Format((Number <> '') and (DelChr(Number, '=', '0123456789') = '')));
        if not Evaluate(N, Number) then
            N := -1;
        Observer.Observe(Name + ' div 1000', Format(N div 1000));
        ClearLastError();
    end;

    local procedure ExpectMajor(Name: Text)
    begin
        Observer.Expect(Name + ' digits', 'Yes');
#if BC29PLUS
        Observer.Expect(Name + ' div 1000', '29');
#elif BC28PLUS
        Observer.Expect(Name + ' div 1000', '28');
#else
        Observer.Expect(Name + ' div 1000', '27');
#endif
    end;

    [Test]
    procedure MissingCodeunit_InTestMethod()
    var
        Number: Text;
    begin
        asserterror Codeunit.Run(71998);
        Number := ObserveMissing('codeunit');
#if BC29PLUS
        Observer.Observe('codeunit number', Number);
#endif
        Observer.Expect('codeunit|tail', 'An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('codeunit|code', 'AL:MetadataNotFound');
        ExpectMajor('codeunit');
#if BC29PLUS
        // The CI's 29.0 build is 29.0.54011.55816.
        Observer.Expect('codeunit number', '29022');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure MissingTablePageReport_SameNumber()
    var
        RR: RecordRef;
        Codeunit_: Text;
        Table_: Text;
        Page_: Text;
        Report_: Text;
    begin
        asserterror Codeunit.Run(71998);
        Codeunit_ := ObserveMissing('codeunit');
        asserterror RR.Open(71998);
        Table_ := ObserveMissing('table');
        asserterror Page.Run(71998);
        Page_ := ObserveMissing('page');
        asserterror Report.Run(71998);
        Report_ := ObserveMissing('report');
        Observer.Observe('same number', Format((Table_ = Codeunit_) and (Page_ = Codeunit_) and (Report_ = Codeunit_)));
        Observer.Expect('codeunit|tail', 'An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('codeunit|code', 'AL:MetadataNotFound');
        ExpectMajor('codeunit');
        Observer.Expect('table|tail', 'An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('table|code', 'AL:MetadataNotFound');
        ExpectMajor('table');
        Observer.Expect('page|tail', 'An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('page|code', 'AL:MetadataNotFound');
        ExpectMajor('page');
        Observer.Expect('report|tail', 'An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('report|code', 'AL:MetadataNotFound');
        ExpectMajor('report');
        Observer.Expect('same number', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MissingCodeunit_FromHelper()
    var
        Helper: Codeunit "LT P160 Missing Caller";
    begin
        asserterror Helper.RunMissingCodeunit();
        ObserveMissing('helper');
        Observer.Expect('helper|tail', 'An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('helper|code', 'AL:MetadataNotFound');
        ExpectMajor('helper');
        Observer.Verify();
    end;
}
