// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73623, codeunits 73624..73626
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Evaluate into a Code field and a Code variable (empty and blank texts), into a Duration (default format: plain numbers, zero,
//        Format round trip of 0 ms .. 1 day, a Duration field), into a DateTime with format 0 .. 3 and 9 (the 12/30/1899 time-only form,
//        with the plain space and the U+202F space before AM/PM, round trips of Format).
// BC versions: 29 (27 and 28 by CI)

table 73623 "LT P131 Eval Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[20]) { }
        field(3; Du; Duration) { }
        field(4; Dtm; DateTime) { }
        field(5; Cd5; Code[5]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73624 "LT P131 Eval Code"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P131_EvaluateCode_BlankTexts()
    var
        Observer: Codeunit "Probe Observer";
        C20: Code[20];
        C5: Code[5];
        Ok: Boolean;
    begin
        C20 := 'zzz';
        Ok := Evaluate(C20, '');
        Observer.Observe('empty', Format(Ok) + '|[' + C20 + ']');
        C20 := 'zzz';
        Ok := Evaluate(C20, ' ');
        Observer.Observe('one space', Format(Ok) + '|[' + C20 + ']');
        C20 := 'zzz';
        Ok := Evaluate(C20, '   ');
        Observer.Observe('three spaces', Format(Ok) + '|[' + C20 + ']');
        C20 := 'zzz';
        Ok := Evaluate(C20, ' ab ');
        Observer.Observe('padded', Format(Ok) + '|[' + C20 + ']');
        C20 := 'zzz';
        Ok := Evaluate(C20, 'a b');
        Observer.Observe('inner space', Format(Ok) + '|[' + C20 + ']');
        C5 := 'zzz';
        Ok := Evaluate(C5, 'abcde');
        Observer.Observe('c5 exact', Format(Ok) + '|[' + C5 + ']');
        C5 := 'zzz';
        Ok := Evaluate(C5, 'abcdef');
        Observer.Observe('c5 long', Format(Ok) + '|[' + C5 + ']');
        C5 := 'zzz';
        Ok := Evaluate(C5, '');
        Observer.Observe('c5 empty', Format(Ok) + '|[' + C5 + ']');
        Observer.Expect('empty', 'Yes|[]');
        Observer.Expect('one space', 'Yes|[]');
        Observer.Expect('three spaces', 'Yes|[]');
        Observer.Expect('padded', 'Yes|[AB]');
        Observer.Expect('inner space', 'Yes|[A B]');
        Observer.Expect('c5 exact', 'Yes|[ABCDE]');
        Observer.Expect('c5 long', 'No|[ZZZ]');
        Observer.Expect('c5 empty', 'Yes|[]');
        Observer.Verify();
    end;

    [Test]
    procedure P131_EvaluateCode_IntoTableField()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P131 Eval Rec";
        Ok: Boolean;
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Cd := 'KEEP';
        Ok := Evaluate(R.Cd, '');
        Observer.Observe('field empty', Format(Ok) + '|[' + R.Cd + ']');
        R.Cd := 'KEEP';
        Ok := Evaluate(R.Cd, 'new');
        Observer.Observe('field lower', Format(Ok) + '|[' + R.Cd + ']');
        R.Cd5 := 'KEEP';
        Ok := Evaluate(R.Cd5, 'toolongvalue');
        Observer.Observe('field long', Format(Ok) + '|[' + R.Cd5 + ']');
        R.Cd := 'KEEP';
        Ok := Evaluate(R.Cd, '');
        R.Insert();
        R.Get(1);
        Observer.Observe('stored empty', '[' + R.Cd + ']');
        Observer.Observe('count blank', Format(R.Count()));
        R.SetRange(Cd, '');
        Observer.Observe('filter blank', Format(R.Count()));
        R.DeleteAll();
        Observer.Expect('field empty', 'Yes|[]');
        Observer.Expect('field lower', 'Yes|[NEW]');
        Observer.Expect('field long', 'No|[KEEP]');
        Observer.Expect('stored empty', '[]');
        Observer.Expect('count blank', '1');
        Observer.Expect('filter blank', '1');
        Observer.Verify();
    end;
}

codeunit 73625 "LT P131 Eval Dur"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EDU(Txt: Text; Fmt: Integer): Text
    var
        Du: Duration;
        Ok: Boolean;
    begin
        Ok := Evaluate(Du, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(Du, 0, 9) + '|' + Format(Du));
    end;

    local procedure Ms(Value: BigInteger): Duration
    begin
        exit(Value);
    end;

    local procedure RoundTrip(Value: BigInteger): Text
    var
        D: Duration;
        D2: Duration;
        Txt: Text;
        Ok: Boolean;
    begin
        D := Ms(Value);
        Txt := Format(D);
        Ok := Evaluate(D2, Txt);
        exit('[' + Txt + ']|' + Format(Ok) + '|' + Format(D2, 0, 9) + '|' + Format(D = D2));
    end;

    [Test]
    procedure P131_EvaluateDuration_PlainNumbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('0', EDU('0', 0));
        Observer.Observe('1', EDU('1', 0));
        Observer.Observe('999', EDU('999', 0));
        Observer.Observe('1000', EDU('1000', 0));
        Observer.Observe('60000', EDU('60000', 0));
        Observer.Observe('3600000', EDU('3600000', 0));
        Observer.Observe('86400000', EDU('86400000', 0));
        Observer.Observe('2147483647', EDU('2147483647', 0));
        Observer.Observe('-1', EDU('-1', 0));
        Observer.Observe('+5', EDU('+5', 0));
        Observer.Observe('1.5', EDU('1.5', 0));
        Observer.Observe('0.5', EDU('0.5', 0));
        Observer.Observe('00', EDU('00', 0));
        Observer.Observe('padded', EDU('  7 ', 0));
        Observer.Observe('12abc', EDU('12abc', 0));
        Observer.Observe('0 ms', EDU('0 ms', 0));
        Observer.Observe('0 milliseconds', EDU('0 milliseconds', 0));
        Observer.Observe('0 hours', EDU('0 hours', 0));
        Observer.Observe('0 days', EDU('0 days', 0));
        Observer.Observe('1 millisecond', EDU('1 millisecond', 0));
        Observer.Observe('1000 milliseconds', EDU('1000 milliseconds', 0));
        Observer.Observe('1,5', EDU('1,5', 0));
        Observer.Observe('1e3', EDU('1e3', 0));
        Observer.Observe('0 fmt 9', EDU('0', 9));
        Observer.Observe('0 fmt 2', EDU('0', 2));
        Observer.Expect('0', 'Yes|P0DT0H0M0.0S|');
        Observer.Expect('1', 'Yes|P0DT1H0M0.0S|1 hour');
        Observer.Expect('999', 'Yes|P41DT15H0M0.0S|41 days 15 hours');
        Observer.Expect('1000', 'Yes|P41DT16H0M0.0S|41 days 16 hours');
        Observer.Expect('60000', 'Yes|P2500DT0H0M0.0S|2500 days');
        Observer.Expect('3600000', 'Yes|P150000DT0H0M0.0S|150000 days');
        Observer.Expect('86400000', 'Yes|P3600000DT0H0M0.0S|3600000 days');
        Observer.Expect('2147483647', 'Yes|P89478485DT7H0M0.0S|89478485 days 7 hours');
        Observer.Expect('-1', 'Yes|-P0DT1H0M0.0S|-1 hour');
        Observer.Expect('+5', 'No|P0DT0H0M0.0S|');
        Observer.Expect('1.5', 'Yes|P0DT1H30M0.0S|1 hour 30 minutes');
        Observer.Expect('0.5', 'Yes|P0DT0H30M0.0S|30 minutes');
        Observer.Expect('00', 'Yes|P0DT0H0M0.0S|');
        Observer.Expect('padded', 'Yes|P0DT7H0M0.0S|7 hours');
        Observer.Expect('12abc', 'No|P0DT0H0M0.0S|');
        Observer.Expect('0 ms', 'No|P0DT0H0M0.0S|');
        Observer.Expect('0 milliseconds', 'Yes|P0DT0H0M0.0S|');
        Observer.Expect('0 hours', 'Yes|P0DT0H0M0.0S|');
        Observer.Expect('0 days', 'Yes|P0DT0H0M0.0S|');
        Observer.Expect('1 millisecond', 'Yes|P0DT0H0M0.001S|1 millisecond');
        Observer.Expect('1000 milliseconds', 'Yes|P0DT0H0M1.0S|1 second');
        Observer.Expect('1,5', 'No|P0DT0H0M0.0S|');
        Observer.Expect('1e3', 'No|P0DT0H0M0.0S|');
        Observer.Expect('0 fmt 9', 'No|P0DT0H0M0.0S|');
        Observer.Expect('0 fmt 2', 'Yes|P0DT0H0M0.0S|');
        Observer.Verify();
    end;

    [Test]
    procedure P131_EvaluateDuration_FormatRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('0 ms', RoundTrip(0));
        Observer.Observe('1 ms', RoundTrip(1));
        Observer.Observe('999 ms', RoundTrip(999));
        Observer.Observe('1000 ms', RoundTrip(1000));
        Observer.Observe('1500 ms', RoundTrip(1500));
        Observer.Observe('60000 ms', RoundTrip(60000));
        Observer.Observe('3600000 ms', RoundTrip(3600000));
        Observer.Observe('86400000 ms', RoundTrip(86400000));
        Observer.Observe('90061001 ms', RoundTrip(90061001));
        Observer.Observe('-1000 ms', RoundTrip(-1000));
        Observer.Expect('0 ms', '[]|Yes|P0DT0H0M0.0S|Yes');
        Observer.Expect('1 ms', '[1 millisecond]|Yes|P0DT0H0M0.001S|Yes');
        Observer.Expect('999 ms', '[999 milliseconds]|Yes|P0DT0H0M0.999S|Yes');
        Observer.Expect('1000 ms', '[1 second]|Yes|P0DT0H0M1.0S|Yes');
        Observer.Expect('1500 ms', '[1 second 500 milliseconds]|Yes|P0DT0H0M1.5S|Yes');
        Observer.Expect('60000 ms', '[1 minute]|Yes|P0DT0H1M0.0S|Yes');
        Observer.Expect('3600000 ms', '[1 hour]|Yes|P0DT1H0M0.0S|Yes');
        Observer.Expect('86400000 ms', '[1 day]|Yes|P1DT0H0M0.0S|Yes');
        Observer.Expect('90061001 ms', '[1 day 1 hour 1 minute 1 second 1 millisecond]|Yes|P1DT1H1M1.001S|Yes');
        Observer.Expect('-1000 ms', '[-1 second]|Yes|-P0DT0H0M1.0S|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P131_EvaluateDuration_TableField()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P131 Eval Rec";
        Ok: Boolean;
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Du := Ms(5000);
        Ok := Evaluate(R.Du, '0');
        Observer.Observe('field 0', Format(Ok) + '|' + Format(R.Du, 0, 9));
        R.Du := Ms(5000);
        Ok := Evaluate(R.Du, '');
        Observer.Observe('field empty', Format(Ok) + '|' + Format(R.Du, 0, 9));
        R.Du := Ms(5000);
        Ok := Evaluate(R.Du, '2 hours');
        Observer.Observe('field 2 hours', Format(Ok) + '|' + Format(R.Du, 0, 9));
        R.Du := 0;
        Observer.Observe('assigned 0', '[' + Format(R.Du) + ']|' + Format(R.Du, 0, 9));
        R.Insert();
        R.Get(1);
        Observer.Observe('stored', '[' + Format(R.Du) + ']|' + Format(R.Du, 0, 9));
        R.DeleteAll();
        Observer.Expect('field 0', 'Yes|P0DT0H0M0.0S');
        Observer.Expect('field empty', 'Yes|P0DT0H0M0.0S');
        Observer.Expect('field 2 hours', 'Yes|P0DT2H0M0.0S');
        Observer.Expect('assigned 0', '[]|P0DT0H0M0.0S');
        Observer.Expect('stored', '[]|P0DT0H0M0.0S');
        Observer.Verify();
    end;
}

codeunit 73626 "LT P131 Eval DT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EDT(Txt: Text; Fmt: Integer): Text
    var
        DT: DateTime;
        Ok: Boolean;
    begin
        Ok := Evaluate(DT, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(DT, 0, 9));
    end;

    local procedure Nn(Txt: Text): Text
    var
        Sp: Text[1];
    begin
        Sp[1] := 8239;
        exit(Txt.Replace('~', Sp));
    end;

    [Test]
    procedure P131_EvaluateDateTime_TimeOnlyForm()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        for I := 0 to 3 do
            Observer.Observe('plain space fmt ' + Format(I), EDT('12/30/1899 10:00:00 PM', I));
        Observer.Observe('plain space fmt 9', EDT('12/30/1899 10:00:00 PM', 9));
        for I := 0 to 3 do
            Observer.Observe('nnbsp fmt ' + Format(I), EDT(Nn('12/30/1899 10:00:00~PM'), I));
        Observer.Observe('24h', EDT('12/30/1899 22:00:00', 0));
        Observer.Observe('no seconds', EDT('12/30/1899 10:00 PM', 0));
        Observer.Observe('am midnight', EDT('12/30/1899 12:00:00 AM', 0));
        Observer.Observe('date only', EDT('12/30/1899', 0));
        Observer.Observe('1/1/1900', EDT('1/1/1900 12:00:00 AM', 0));
        Observer.Observe('2digit year', EDT('12/30/99 10:00:00 PM', 0));
        Observer.Observe('time only pm', EDT('10:00:00 PM', 0));
        Observer.Observe('iso 1899', EDT('1899-12-30T22:00:00Z', 9));
        Observer.Observe('iso 1899 no z', EDT('1899-12-30T22:00:00', 9));
        Observer.Observe('1899 fmt 1', EDT('1899-12-30T22:00:00Z', 1));
        Observer.Expect('plain space fmt 0', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('plain space fmt 1', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('plain space fmt 2', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('plain space fmt 3', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('plain space fmt 9', 'No|');
        Observer.Expect('nnbsp fmt 0', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('nnbsp fmt 1', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('nnbsp fmt 2', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('nnbsp fmt 3', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('24h', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('no seconds', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('am midnight', 'Yes|1899-12-30T00:00:00Z');
        Observer.Expect('date only', 'Yes|1899-12-30T00:00:00Z');
        Observer.Expect('1/1/1900', 'Yes|1900-01-01T00:00:00Z');
        Observer.Expect('2digit year', 'Yes|1999-12-30T22:00:00Z');
        Observer.Expect('time only pm', 'No|');
        Observer.Expect('iso 1899', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('iso 1899 no z', 'Yes|1899-12-30T22:00:00Z');
        Observer.Expect('1899 fmt 1', 'Yes|1899-12-30T22:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure P131_EvaluateDateTime_FormatRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        D1899: Date;
        T: Text;
        DT: DateTime;
        DT2: DateTime;
        Ok: Boolean;
    begin
        D1899 := DMY2Date(30, 12, 1899);
        DT := CreateDateTime(D1899, 220000T);
        T := Format(DT);
        Ok := Evaluate(DT2, T);
        Observer.Observe('1899 22:00 text', '[' + T + ']');
        Observer.Observe('1899 22:00 back', Format(Ok) + '|' + Format(DT2, 0, 9) + '|' + Format(DT = DT2));
        T := Format(DT, 0, 9);
        Observer.Observe('1899 22:00 iso', '[' + T + ']');
        DT := CreateDateTime(D1899, 0T);
        T := Format(DT);
        Ok := Evaluate(DT2, T);
        Observer.Observe('1899 midnight text', '[' + T + ']');
        Observer.Observe('1899 midnight back', Format(Ok) + '|' + Format(DT2, 0, 9) + '|' + Format(DT = DT2));
        asserterror DT := CreateDateTime(0D, 220000T);
        Observer.ObserveError('af279');
        T := Format(DT);
        Ok := Evaluate(DT2, T);
        Observer.Observe('0D 22:00 text', '[' + T + ']');
        Observer.Observe('0D 22:00 back', Format(Ok) + '|' + Format(DT2, 0, 9));
        Observer.Observe('0D 22:00 iso', '[' + Format(DT, 0, 9) + ']');
        DT := CreateDateTime(DMY2Date(31, 12, 1899), 0T);
        T := Format(DT);
        Ok := Evaluate(DT2, T);
        Observer.Observe('1899-12-31 text', '[' + T + ']');
        Observer.Observe('1899-12-31 back', Format(Ok) + '|' + Format(DT2, 0, 9));
        DT := CreateDateTime(DMY2Date(1, 1, 1900), 0T);
        T := Format(DT);
        Observer.Observe('1900-01-01 text', '[' + T + ']');
        DT := CreateDateTime(DMY2Date(5, 3, 2024), 134506T);
        T := Format(DT);
        Ok := Evaluate(DT2, T);
        Observer.Observe('2024 back', Format(Ok) + '|' + Format(DT2, 0, 9) + '|' + Format(DT = DT2));
        Observer.Expect('1899 22:00 text', '[12/30/1899 10:00 PM]');
        Observer.Expect('1899 22:00 back', 'Yes|1899-12-30T22:00:00Z|Yes');
        Observer.Expect('1899 22:00 iso', '[1899-12-30T22:00:00Z]');
        Observer.Expect('1899 midnight text', '[12/30/1899 12:00 AM]');
        Observer.Expect('1899 midnight back', 'Yes|1899-12-30T00:00:00Z|Yes');
        Observer.Expect('af279|text', 'The date is not valid.');
        Observer.Expect('af279|code', 'DateInvalid');
        Observer.Expect('0D 22:00 text', '[12/30/1899 12:00 AM]');
        Observer.Expect('0D 22:00 back', 'Yes|1899-12-30T00:00:00Z');
        Observer.Expect('0D 22:00 iso', '[1899-12-30T00:00:00Z]');
        Observer.Expect('1899-12-31 text', '[12/31/1899 12:00 AM]');
        Observer.Expect('1899-12-31 back', 'Yes|1899-12-31T00:00:00Z');
        Observer.Expect('1900-01-01 text', '[01/01/1900 12:00 AM]');
        Observer.Expect('2024 back', 'Yes|2024-03-05T13:45:00Z|No');
        Observer.Verify();
    end;
}
