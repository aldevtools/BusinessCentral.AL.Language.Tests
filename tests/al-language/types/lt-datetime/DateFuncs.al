// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Topic: ClosingDate, NormalDate, Date2DMY, Date2DWY, DMY2Date, DWY2Date and Date property-like functions
// BC versions: 29 (27 and 28 by CI)

codeunit 73801 "LT DtT DateFuncs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ClosingNormal()
    var
        Observer: Codeunit "Probe Observer";
        C: Date;
    begin
        C := ClosingDate(20231231D);
        Observer.Observe('closing', Format(C, 0, 9));
        Observer.Observe('closing text', Format(C));
        Observer.Observe('closing <> normal', Format(C <> 20231231D));
        Observer.Observe('closing = normal', Format(C = 20231231D));
        Observer.Observe('closing > normal', Format(C > 20231231D));
        Observer.Observe('closing > next day', Format(C > 20240101D));
        Observer.Observe('closing < next day', Format(C < 20240101D));
        Observer.Observe('normal of closing', Format(NormalDate(C), 0, 9));
        Observer.Observe('normal of normal', Format(NormalDate(20231231D), 0, 9));
        Observer.Observe('normal = original', Format(NormalDate(C) = 20231231D));
        asserterror Observer.Observe('closing 0D', Format(ClosingDate(0D), 0, 9));
        Observer.ObserveError('af30');
        asserterror Observer.Observe('closing 0D = 0D', Format(ClosingDate(0D) = 0D));
        Observer.ObserveError('af32');
        asserterror Observer.Observe('normal 0D', Format(NormalDate(0D), 0, 9));
        Observer.ObserveError('af34');
        Observer.Observe('closing of closing', Format(ClosingDate(ClosingDate(20231231D)) = ClosingDate(20231231D)));
        asserterror Observer.Observe('closing min', Format(ClosingDate(00010101D), 0, 9));
        Observer.ObserveError('af37');
        Observer.Observe('closing max', Format(ClosingDate(99991231D), 0, 9));
        Observer.Observe('normal closing max', Format(NormalDate(ClosingDate(99991231D)), 0, 9));
        Observer.Observe('Date2DMY closing d', Format(Date2DMY(C, 1)));
        Observer.Observe('Date2DMY closing m', Format(Date2DMY(C, 2)));
        Observer.Observe('Date2DMY closing y', Format(Date2DMY(C, 3)));
        Observer.Observe('Date2DWY closing', Format(Date2DWY(C, 1)));
        Observer.Observe('closing sorted after', Format(ClosingDate(20230101D) > 20231231D));
        Observer.Expect('closing', '2023-12-31');
        Observer.Expect('closing text', 'C12/31/23');
        Observer.Expect('closing <> normal', 'Yes');
        Observer.Expect('closing = normal', 'No');
        Observer.Expect('closing > normal', 'Yes');
        Observer.Expect('closing > next day', 'No');
        Observer.Expect('closing < next day', 'Yes');
        Observer.Expect('normal of closing', '2023-12-31');
        Observer.Expect('normal of normal', '2023-12-31');
        Observer.Expect('normal = original', 'Yes');
        Observer.Expect('af30|text', 'The date is not valid.');
        Observer.Expect('af30|code', 'DateInvalid');
        Observer.Expect('af32|text', 'The date is not valid.');
        Observer.Expect('af32|code', 'DateInvalid');
        Observer.Expect('af34|text', 'The date is not valid.');
        Observer.Expect('af34|code', 'DateInvalid');
        Observer.Expect('closing of closing', 'Yes');
        Observer.Expect('af37|text', 'The date is not valid.');
        Observer.Expect('af37|code', 'DateInvalid');
        Observer.Expect('closing max', '9999-12-31');
        Observer.Expect('normal closing max', '9999-12-31');
        Observer.Expect('Date2DMY closing d', '31');
        Observer.Expect('Date2DMY closing m', '12');
        Observer.Expect('Date2DMY closing y', '2023');
        Observer.Expect('Date2DWY closing', '7');
        Observer.Expect('closing sorted after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Date2DMY_Invalid()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        asserterror I := Date2DMY(20240229D, 0);
        Observer.ObserveError('what 0');
        asserterror I := Date2DMY(20240229D, 4);
        Observer.ObserveError('what 4');
        asserterror I := Date2DMY(20240229D, -1);
        Observer.ObserveError('what -1');
        asserterror I := Date2DMY(20240229D, 100);
        Observer.ObserveError('what 100');
        asserterror I := Date2DMY(0D, 0);
        Observer.ObserveError('0D what 0');
        asserterror I := Date2DMY(0D, 4);
        Observer.ObserveError('0D what 4');
        Observer.Expect('what 0|text', 'The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.');
        Observer.Expect('what 0|code', 'OutsidePermittedRange');
        Observer.Expect('what 4|text', 'The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.');
        Observer.Expect('what 4|code', 'OutsidePermittedRange');
        Observer.Expect('what -1|text', 'The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 3.');
        Observer.Expect('what -1|code', 'OutsidePermittedRange');
        Observer.Expect('what 100|text', 'The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 100. The permitted range is: from 1 to 3.');
        Observer.Expect('what 100|code', 'OutsidePermittedRange');
        Observer.Expect('0D what 0|text', 'The date is not valid.');
        Observer.Expect('0D what 0|code', 'DateInvalid');
        Observer.Expect('0D what 4|text', 'The date is not valid.');
        Observer.Expect('0D what 4|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure Date2DWY_Valid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // 2024-01-01 is a Monday, ISO week 1
        Observer.Observe('mon dow', Format(Date2DWY(20240101D, 1)));
        Observer.Observe('mon week', Format(Date2DWY(20240101D, 2)));
        Observer.Observe('mon year', Format(Date2DWY(20240101D, 3)));
        Observer.Observe('sun dow', Format(Date2DWY(20240107D, 1)));
        Observer.Observe('sun week', Format(Date2DWY(20240107D, 2)));
        Observer.Observe('2023-01-01 dow', Format(Date2DWY(20230101D, 1)));
        Observer.Observe('2023-01-01 week', Format(Date2DWY(20230101D, 2)));
        Observer.Observe('2023-01-01 year', Format(Date2DWY(20230101D, 3)));
        Observer.Observe('2020-12-31 week', Format(Date2DWY(20201231D, 2)));
        Observer.Observe('2020-12-31 year', Format(Date2DWY(20201231D, 3)));
        Observer.Observe('2021-01-01 week', Format(Date2DWY(20210101D, 2)));
        Observer.Observe('2021-01-01 year', Format(Date2DWY(20210101D, 3)));
        Observer.Observe('2024-12-30 week', Format(Date2DWY(20241230D, 2)));
        Observer.Observe('2024-12-30 year', Format(Date2DWY(20241230D, 3)));
        Observer.Observe('2026-12-31 week', Format(Date2DWY(20261231D, 2)));
        Observer.Observe('2026-12-31 year', Format(Date2DWY(20261231D, 3)));
        Observer.Observe('2015-12-31 week', Format(Date2DWY(20151231D, 2)));
        Observer.Observe('2016-01-03 week', Format(Date2DWY(20160103D, 2)));
        Observer.Observe('2016-01-03 year', Format(Date2DWY(20160103D, 3)));
        asserterror Observer.Observe('min dow', Format(Date2DWY(00010101D, 1)));
        Observer.ObserveError('af113');
        asserterror Observer.Observe('min week', Format(Date2DWY(00010101D, 2)));
        Observer.ObserveError('af117');
        asserterror Observer.Observe('min year', Format(Date2DWY(00010101D, 3)));
        Observer.ObserveError('af121');
        Observer.Observe('max dow', Format(Date2DWY(99991231D, 1)));
        Observer.Observe('max week', Format(Date2DWY(99991231D, 2)));
        Observer.Observe('max year', Format(Date2DWY(99991231D, 3)));
        Observer.Expect('mon dow', '1');
        Observer.Expect('mon week', '1');
        Observer.Expect('mon year', '2024');
        Observer.Expect('sun dow', '7');
        Observer.Expect('sun week', '1');
        Observer.Expect('2023-01-01 dow', '7');
        Observer.Expect('2023-01-01 week', '52');
        Observer.Expect('2023-01-01 year', '2022');
        Observer.Expect('2020-12-31 week', '53');
        Observer.Expect('2020-12-31 year', '2020');
        Observer.Expect('2021-01-01 week', '53');
        Observer.Expect('2021-01-01 year', '2020');
        Observer.Expect('2024-12-30 week', '1');
        Observer.Expect('2024-12-30 year', '2025');
        Observer.Expect('2026-12-31 week', '53');
        Observer.Expect('2026-12-31 year', '2026');
        Observer.Expect('2015-12-31 week', '53');
        Observer.Expect('2016-01-03 week', '53');
        Observer.Expect('2016-01-03 year', '2015');
        Observer.Expect('af113|text', 'The date is not valid.');
        Observer.Expect('af113|code', 'DateInvalid');
        Observer.Expect('af117|text', 'The date is not valid.');
        Observer.Expect('af117|code', 'DateInvalid');
        Observer.Expect('af121|text', 'The date is not valid.');
        Observer.Expect('af121|code', 'DateInvalid');
        Observer.Expect('max dow', '5');
        Observer.Expect('max week', '52');
        Observer.Expect('max year', '9999');
        Observer.Verify();
    end;

    [Test]
    procedure Date2DWY_Invalid()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        asserterror I := Date2DWY(20240229D, 0);
        Observer.ObserveError('what 0');
        asserterror I := Date2DWY(20240229D, 4);
        Observer.ObserveError('what 4');
        asserterror I := Date2DWY(20240229D, -1);
        Observer.ObserveError('what -1');
        asserterror Observer.Observe('0D dow', Format(Date2DWY(0D, 1)));
        Observer.ObserveError('af135');
        asserterror Observer.Observe('0D week', Format(Date2DWY(0D, 2)));
        Observer.ObserveError('af140');
        asserterror Observer.Observe('0D year', Format(Date2DWY(0D, 3)));
        Observer.ObserveError('af145');
        Observer.Expect('what 0|text', 'The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.');
        Observer.Expect('what 0|code', 'OutsidePermittedRange');
        Observer.Expect('what 4|text', 'The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.');
        Observer.Expect('what 4|code', 'OutsidePermittedRange');
        Observer.Expect('what -1|text', 'The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 3.');
        Observer.Expect('what -1|code', 'OutsidePermittedRange');
        Observer.Expect('af135|text', 'The date is not valid.');
        Observer.Expect('af135|code', 'DateInvalid');
        Observer.Expect('af140|text', 'The date is not valid.');
        Observer.Expect('af140|code', 'DateInvalid');
        Observer.Expect('af145|text', 'The date is not valid.');
        Observer.Expect('af145|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure DMY2Date_Valid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('normal', Format(DMY2Date(15, 1, 2024), 0, 9));
        Observer.Observe('leap day', Format(DMY2Date(29, 2, 2024), 0, 9));
        Observer.Observe('min', Format(DMY2Date(1, 1, 1), 0, 9));
        Observer.Observe('max', Format(DMY2Date(31, 12, 9999), 0, 9));
        Observer.Observe('only day', Format(DMY2Date(15), 0, 9));
        Observer.Observe('day month', Format(DMY2Date(15, 3), 0, 9));
        asserterror Observer.Observe('day 0', Format(DMY2Date(0, 0, 0), 0, 9));
        Observer.ObserveError('af153');
        Observer.Observe('two digit year 24', Format(DMY2Date(1, 1, 24), 0, 9));
        Observer.Observe('year 99', Format(DMY2Date(1, 1, 99), 0, 9));
        Observer.Observe('year 1999', Format(DMY2Date(1, 1, 1999), 0, 9));
        Observer.Observe('year 100', Format(DMY2Date(1, 1, 100), 0, 9));
        Observer.Observe('year 1753', Format(DMY2Date(1, 1, 1753), 0, 9));
        Observer.Observe('year 1752', Format(DMY2Date(1, 1, 1752), 0, 9));
        Observer.Expect('normal', '2024-01-15');
        Observer.Expect('leap day', '2024-02-29');
        Observer.Expect('min', '');
        Observer.Expect('max', '9999-12-31');
        Observer.Expect('only day', Format(DMY2Date(15, Date2DMY(Today(), 2), Date2DMY(Today(), 3)), 0, 9));
        Observer.Expect('day month', Format(DMY2Date(15, 3, Date2DMY(Today(), 3)), 0, 9));
        Observer.Expect('af153|text', 'The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 12.');
        Observer.Expect('af153|code', 'OutsidePermittedRange');
        Observer.Expect('two digit year 24', '0024-01-01');
        Observer.Expect('year 99', '0099-01-01');
        Observer.Expect('year 1999', '1999-01-01');
        Observer.Expect('year 100', '0100-01-01');
        Observer.Expect('year 1753', '1753-01-01');
        Observer.Expect('year 1752', '1752-01-01');
        Observer.Verify();
    end;

    [Test]
    procedure DMY2Date_Invalid()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        asserterror D := DMY2Date(30, 2, 2024);
        Observer.ObserveError('feb 30');
        asserterror D := DMY2Date(29, 2, 2023);
        Observer.ObserveError('feb 29 nonleap');
        asserterror D := DMY2Date(32, 1, 2024);
        Observer.ObserveError('day 32');
        asserterror D := DMY2Date(31, 4, 2024);
        Observer.ObserveError('apr 31');
        asserterror D := DMY2Date(1, 13, 2024);
        Observer.ObserveError('month 13');
        asserterror D := DMY2Date(1, 0, 2024);
        Observer.ObserveError('month 0');
        asserterror D := DMY2Date(0, 1, 2024);
        Observer.ObserveError('day 0');
        asserterror D := DMY2Date(-1, 1, 2024);
        Observer.ObserveError('day -1');
        asserterror D := DMY2Date(1, -1, 2024);
        Observer.ObserveError('month -1');
        asserterror D := DMY2Date(1, 1, -1);
        Observer.ObserveError('year -1');
        asserterror D := DMY2Date(1, 1, 10000);
        Observer.ObserveError('year 10000');
        D := DMY2Date(1, 1, 0);
        Observer.Observe('year 0', 'no error');
        asserterror D := DMY2Date(0, 5, 2024);
        Observer.ObserveError('day 0 month 5');
        asserterror D := DMY2Date(1, 0, 0);
        Observer.ObserveError('month 0 year 0');
        Observer.Expect('feb 30|text', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 30. The permitted range is: from 1 to 29.');
        Observer.Expect('feb 30|code', 'OutsidePermittedRange');
        Observer.Expect('feb 29 nonleap|text', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 29. The permitted range is: from 1 to 28.');
        Observer.Expect('feb 29 nonleap|code', 'OutsidePermittedRange');
        Observer.Expect('day 32|text', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 32. The permitted range is: from 1 to 31.');
        Observer.Expect('day 32|code', 'OutsidePermittedRange');
        Observer.Expect('apr 31|text', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 31. The permitted range is: from 1 to 30.');
        Observer.Expect('apr 31|code', 'OutsidePermittedRange');
        Observer.Expect('month 13|text', 'The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 13. The permitted range is: from 1 to 12.');
        Observer.Expect('month 13|code', 'OutsidePermittedRange');
        Observer.Expect('month 0|text', 'The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 12.');
        Observer.Expect('month 0|code', 'OutsidePermittedRange');
        Observer.Expect('day 0|text', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 31.');
        Observer.Expect('day 0|code', 'OutsidePermittedRange');
        Observer.Expect('day -1|text', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 31.');
        Observer.Expect('day -1|code', 'OutsidePermittedRange');
        Observer.Expect('month -1|text', 'The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 12.');
        Observer.Expect('month -1|code', 'OutsidePermittedRange');
        Observer.Expect('year -1|text', 'The value of DMY2Date parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 9999.');
        Observer.Expect('year -1|code', 'OutsidePermittedRange');
        Observer.Expect('year 10000|text', 'The value of DMY2Date parameter 3 is outside of the permitted range. The current value is: 10000. The permitted range is: from 1 to 9999.');
        Observer.Expect('year 10000|code', 'OutsidePermittedRange');
        Observer.Expect('year 0', 'no error');
        Observer.Expect('day 0 month 5|text', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 31.');
        Observer.Expect('day 0 month 5|code', 'OutsidePermittedRange');
        Observer.Expect('month 0 year 0|text', 'The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 12.');
        Observer.Expect('month 0 year 0|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;





    [Test]
    procedure DWY2Date_Valid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('mon w1 2024', Format(DWY2Date(1, 1, 2024), 0, 9));
        Observer.Observe('sun w1 2024', Format(DWY2Date(7, 1, 2024), 0, 9));
        Observer.Observe('wed w3 2024', Format(DWY2Date(3, 3, 2024), 0, 9));
        Observer.Observe('mon w1 2021', Format(DWY2Date(1, 1, 2021), 0, 9));
        Observer.Observe('mon w1 2020', Format(DWY2Date(1, 1, 2020), 0, 9));
        Observer.Observe('w53 2020', Format(DWY2Date(1, 53, 2020), 0, 9));
        Observer.Observe('sun w53 2020', Format(DWY2Date(7, 53, 2020), 0, 9));
        Observer.Observe('w52 2024', Format(DWY2Date(1, 52, 2024), 0, 9));
        Observer.Observe('sun w52 2024', Format(DWY2Date(7, 52, 2024), 0, 9));
        Observer.Observe('only day', Format(DWY2Date(3), 0, 9));
        Observer.Observe('day week', Format(DWY2Date(3, 10), 0, 9));
        Observer.Observe('w1 1', Format(DWY2Date(1, 1, 1), 0, 9));
        Observer.Observe('w53 2015', Format(DWY2Date(4, 53, 2015), 0, 9));
        Observer.Observe('w1 9999', Format(DWY2Date(1, 1, 9999), 0, 9));
        Observer.Observe('w52 9999', Format(DWY2Date(5, 52, 9999), 0, 9));
        Observer.Expect('mon w1 2024', '2024-01-01');
        Observer.Expect('sun w1 2024', '2024-01-07');
        Observer.Expect('wed w3 2024', '2024-01-17');
        Observer.Expect('mon w1 2021', '2021-01-04');
        Observer.Expect('mon w1 2020', '2019-12-30');
        Observer.Expect('w53 2020', '2020-12-28');
        Observer.Expect('sun w53 2020', '2021-01-03');
        Observer.Expect('w52 2024', '2024-12-23');
        Observer.Expect('sun w52 2024', '2024-12-29');
        Observer.Expect('only day', Format(DWY2Date(3, Date2DWY(Today(), 2), Date2DWY(Today(), 3)), 0, 9));
        Observer.Expect('day week', Format(DWY2Date(3, 10, Date2DWY(Today(), 3)), 0, 9));
        Observer.Expect('w1 1', '');
        Observer.Expect('w53 2015', '2015-12-31');
        Observer.Expect('w1 9999', '9999-01-04');
        Observer.Expect('w52 9999', '9999-12-31');
        Observer.Verify();
    end;

    [Test]
    procedure DWY2Date_Invalid()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        asserterror D := DWY2Date(0, 1, 2024);
        Observer.ObserveError('day 0');
        asserterror D := DWY2Date(8, 1, 2024);
        Observer.ObserveError('day 8');
        asserterror D := DWY2Date(1, 0, 2024);
        Observer.ObserveError('week 0');
        asserterror D := DWY2Date(1, 54, 2024);
        Observer.ObserveError('week 54');
        asserterror D := DWY2Date(1, 53, 2024);
        Observer.ObserveError('week 53 of 52-week year');
        asserterror D := DWY2Date(1, 53, 2023);
        Observer.ObserveError('week 53 2023');
        asserterror D := DWY2Date(1, 1, 0);
        Observer.ObserveError('year 0');
        asserterror D := DWY2Date(1, 1, 10000);
        Observer.ObserveError('year 10000');
        asserterror D := DWY2Date(1, 1, -5);
        Observer.ObserveError('year -5');
        asserterror D := DWY2Date(-1, 1, 2024);
        Observer.ObserveError('day -1');
        asserterror D := DWY2Date(7, 52, 9999);
        Observer.ObserveError('past max');
        Observer.Expect('day 0|text', 'The value of DWY2Date parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 7.');
        Observer.Expect('day 0|code', 'OutsidePermittedRange');
        Observer.Expect('day 8|text', 'The value of DWY2Date parameter 1 is outside of the permitted range. The current value is: 8. The permitted range is: from 1 to 7.');
        Observer.Expect('day 8|code', 'OutsidePermittedRange');
        Observer.Expect('week 0|text', 'The value of DWY2Date parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 53.');
        Observer.Expect('week 0|code', 'OutsidePermittedRange');
        Observer.Expect('week 54|text', 'The value of DWY2Date parameter 2 is outside of the permitted range. The current value is: 54. The permitted range is: from 1 to 53.');
        Observer.Expect('week 54|code', 'OutsidePermittedRange');
        Observer.Expect('week 53 of 52-week year|text', 'The date is not valid.');
        Observer.Expect('week 53 of 52-week year|code', 'DateInvalid');
        Observer.Expect('week 53 2023|text', 'The date is not valid.');
        Observer.Expect('week 53 2023|code', 'DateInvalid');
        Observer.Expect('year 0|text', 'The value of DWY2Date parameter 3 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 9999.');
        Observer.Expect('year 0|code', 'OutsidePermittedRange');
        Observer.Expect('year 10000|text', 'The value of DWY2Date parameter 3 is outside of the permitted range. The current value is: 10000. The permitted range is: from 1 to 9999.');
        Observer.Expect('year 10000|code', 'OutsidePermittedRange');
        Observer.Expect('year -5|text', 'The value of DWY2Date parameter 3 is outside of the permitted range. The current value is: -5. The permitted range is: from 1 to 9999.');
        Observer.Expect('year -5|code', 'OutsidePermittedRange');
        Observer.Expect('day -1|text', 'The value of DWY2Date parameter 1 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 7.');
        Observer.Expect('day -1|code', 'OutsidePermittedRange');
        Observer.Expect('past max|text', 'The date is not valid.');
        Observer.Expect('past max|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Parts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dow mon', Format(Date2DWY(20240115D, 1)));
        Observer.Observe('dow tue', Format(Date2DWY(20240116D, 1)));
        Observer.Observe('dow wed', Format(Date2DWY(20240117D, 1)));
        Observer.Observe('dow thu', Format(Date2DWY(20240118D, 1)));
        Observer.Observe('dow fri', Format(Date2DWY(20240119D, 1)));
        Observer.Observe('dow sat', Format(Date2DWY(20240120D, 1)));
        Observer.Observe('dow sun', Format(Date2DWY(20240121D, 1)));
        Observer.Observe('dow dayname', Format(20240117D, 0, '<Weekday Text>'));
        Observer.Observe('dow dayname short', Format(20240117D, 0, '<Weekday Text,3>'));
        Observer.Observe('dow number', Format(20240117D, 0, '<Weekday>'));
        Observer.Observe('month name', Format(20240117D, 0, '<Month Text>'));
        Observer.Observe('month name short', Format(20240117D, 0, '<Month Text,3>'));
        Observer.Observe('week number', Format(20240117D, 0, '<Week>'));
        Observer.Observe('year', Format(20240117D, 0, '<Year4>'));
        Observer.Observe('year2', Format(20240117D, 0, '<Year>'));
        Observer.Expect('dow mon', '1');
        Observer.Expect('dow tue', '2');
        Observer.Expect('dow wed', '3');
        Observer.Expect('dow thu', '4');
        Observer.Expect('dow fri', '5');
        Observer.Expect('dow sat', '6');
        Observer.Expect('dow sun', '7');
        Observer.Expect('dow dayname', 'Wednesday');
        Observer.Expect('dow dayname short', 'Wed');
        Observer.Expect('dow number', '3');
        Observer.Expect('month name', 'January');
        Observer.Expect('month name short', 'Jan');
        Observer.Expect('week number', '3');
        Observer.Expect('year', '2024');
        Observer.Expect('year2', '24');
        Observer.Verify();
    end;

    // Writer UN (2026-10-29): DMY2Date with year 0 (no error is pinned above; here the value).
    [Test]
    procedure UN_DMY2Date_YearZero_Value()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        Cur: Integer;
    begin
        Cur := Date2DMY(Today(), 3);
        D := DMY2Date(1, 1, 0);
        Observer.Observe('1.1.0 undefined', Format(D = 0D));
        Observer.Observe('1.1.0 format', Format(D, 0, 9));
        Observer.Observe('1.1.0 day', Format(Date2DMY(D, 1)));
        Observer.Observe('1.1.0 month', Format(Date2DMY(D, 2)));
        Observer.Observe('1.1.0 year is current', Format(Date2DMY(D, 3) = Cur));
        Observer.Observe('1.1.0 equals omitted year', Format(D = DMY2Date(1, 1)));
        D := DMY2Date(28, 2, 0);
        Observer.Observe('28.2.0 undefined', Format(D = 0D));
        Observer.Observe('28.2.0 year is current', Format(Date2DMY(D, 3) = Cur));
        D := DMY2Date(31, 12, 0);
        Observer.Observe('31.12.0 undefined', Format(D = 0D));
        Observer.Observe('31.12.0 year is current', Format(Date2DMY(D, 3) = Cur));
        asserterror D := DMY2Date(32, 1, 0);
        Observer.ObserveError('32.1.0');
        asserterror D := DMY2Date(1, 13, 0);
        Observer.ObserveError('1.13.0');
        asserterror D := DMY2Date(1, 1, -5);
        Observer.ObserveError('1.1.-5');
        asserterror D := DMY2Date(1, 1, -2024);
        Observer.ObserveError('1.1.-2024');
        Observer.Finish();
    end;
}
