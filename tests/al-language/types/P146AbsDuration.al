// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-abs-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Abs of a negative, zero and positive Duration, of a Duration expression (-D, D1 - D2, DT - DT), the Format of the result and its assignment to Duration and Decimal
// BC versions: 29 (27 and 28 by CI)

codeunit 70001 "LT P146 Abs Duration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P146_Abs_Duration_Variable()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        Pos: Duration;
        Neg: Duration;
        Zero: Duration;
        R: Duration;
    begin
        Pos := 5000;
        Neg := -5000;
        Zero := 0;
        R := Abs(Neg);
        Observer.Observe('abs neg', Format(R));
        Observer.Observe('abs neg number', Format(R, 0, 9));
        R := Abs(Pos);
        Observer.Observe('abs pos', Format(R));
        R := Abs(Zero);
        Observer.Observe('abs zero', Format(R));
        D := 90061001;
        R := Abs(0 - D);
        Observer.Observe('abs minus d', Format(R));
        Observer.Observe('abs minus d xml', Format(R, 0, 9));
        R := Abs(D);
        Observer.Observe('abs d', Format(R));
        R := 0 - D;
        Observer.Observe('neg d', Format(R));
        Observer.Observe('neg d xml', Format(R, 0, 9));
        R := Abs(Neg - Pos);
        Observer.Observe('abs diff', Format(R));
        R := Abs(Pos - Neg);
        Observer.Observe('abs diff 2', Format(R));
        Observer.Expect('abs neg', '5 seconds');
        Observer.Expect('abs neg number', 'P0DT0H0M5.0S');
        Observer.Expect('abs pos', '5 seconds');
        Observer.Expect('abs zero', '');
        Observer.Expect('abs minus d', '1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('abs minus d xml', 'P1DT1H1M1.001S');
        Observer.Expect('abs d', '1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('neg d', '-1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('neg d xml', '-P1DT1H1M1.001S');
        Observer.Expect('abs diff', '10 seconds');
        Observer.Expect('abs diff 2', '10 seconds');
        Observer.Verify();
    end;

    [Test]
    procedure P146_Abs_Duration_DateTimeDifference()
    var
        Observer: Codeunit "Probe Observer";
        Early: DateTime;
        Late: DateTime;
        R: Duration;
    begin
        Early := CreateDateTime(DMY2Date(1, 1, 2024), 080000T);
        Late := CreateDateTime(DMY2Date(2, 1, 2024), 090000T);
        R := Abs(Early - Late);
        Observer.Observe('abs early minus late', Format(R));
        Observer.Observe('abs early minus late xml', Format(R, 0, 9));
        R := Abs(Late - Early);
        Observer.Observe('abs late minus early', Format(R));
        R := Early - Late;
        Observer.Observe('plain early minus late', Format(R));
        Observer.Observe('plain early minus late xml', Format(R, 0, 9));
        Observer.Expect('abs early minus late', '1 day 1 hour');
        Observer.Expect('abs early minus late xml', 'P1DT1H0M0.0S');
        Observer.Expect('abs late minus early', '1 day 1 hour');
        Observer.Expect('plain early minus late', '-1 day 1 hour');
        Observer.Expect('plain early minus late xml', '-P1DT1H0M0.0S');
        Observer.Verify();
    end;

    [Test]
    procedure P146_Abs_Duration_ResultFormats()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        Dec: Decimal;
        Txt: Text;
    begin
        D := -1500;
        Txt := Format(Abs(D));
        Observer.Observe('format abs', Txt);
        Observer.Observe('format abs xml', Format(Abs(D), 0, 9));
        Observer.Observe('format abs number', Format(Abs(D), 0, '<Integer>'));
        Dec := Abs(D);
        Observer.Observe('decimal assign', Format(Dec));
        Dec := Abs(D) + 0.5;
        Observer.Observe('decimal expression', Format(Dec));
        Observer.Observe('abs plus abs', Format(Abs(D) + Abs(D), 0, 9));
        Observer.Observe('abs compare', Format(Abs(D) = 1500));
        Observer.Observe('abs greater', Format(Abs(D) > D));
        D := Abs(D);
        Observer.Observe('assign back', Format(D, 0, 9));
        Observer.Observe('abs literal negative', Format(Abs(-3600000), 0, 9));
        Observer.Expect('format abs', '1500');
        Observer.Expect('format abs xml', '1500');
        Observer.Expect('format abs number', '1500');
        Observer.Expect('decimal assign', '1,500');
        Observer.Expect('decimal expression', '1,500.5');
        Observer.Expect('abs plus abs', '3000');
        Observer.Expect('abs compare', 'Yes');
        Observer.Expect('abs greater', 'Yes');
        Observer.Expect('assign back', 'P0DT0H0M1.5S');
        Observer.Expect('abs literal negative', '3600000');
        Observer.Verify();
    end;
}
