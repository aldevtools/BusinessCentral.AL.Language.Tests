codeunit 60162 "Test DateTime Contracts"
{
    Subtype = Test;

    trigger OnRun()
    begin
        Cleanup.Initialize();
    end;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure CalcDate_CM_ReturnsEndOfCurrentMonth()
    var
        D: Date;
    begin
        D := CalcDate('<CM>', Today());
        Assert.IsTrue(D >= Today(), 'CalcDate("<CM>") must return a date >= today');
        Assert.IsTrue(Date2DMY(D, 2) = Date2DMY(Today(), 2), 'CalcDate("<CM>") must be in the same month as today');
    end;

    [Test]
    procedure CalcDate_MinusOneMonth_FromMarch1_ReturnsFeb1()
    var
        D: Date;
    begin
        D := CalcDate('<-1M>', 20240301D);
        Assert.AreEqual(20240201D, D, 'CalcDate("<-1M>") from Mar 1 must return Feb 1 (not Feb 29)');
    end;

    [Test]
    procedure CalcDate_PlusOneYear_FromFeb29_ReturnsFeb28()
    var
        D: Date;
    begin
        D := CalcDate('<1Y>', 20240229D);
        Assert.AreEqual(20250228D, D, 'CalcDate("<1Y>") from Feb 29 leap year must return Feb 28 in non-leap year');
    end;

    [Test]
    procedure CalcDate_PlusOneYear_FromFeb28()
    var
        D: Date;
    begin
        D := CalcDate('<1Y>', 20240228D);
        Assert.AreEqual(20250228D, D, 'CalcDate("<1Y>") from Feb 28 must return Feb 28 next year');
    end;

    [Test]
    procedure Duration_OneDayIs86400000Milliseconds()
    var
        Dur: Duration;
        DT1: DateTime;
        DT2: DateTime;
    begin
        Dur := 86400000;
        DT1 := CreateDateTime(20240101D, 000000T);
        DT2 := DT1 + Dur;
        Assert.AreEqual(20240102D, DT2Date(DT2), 'Adding 86400000ms Duration to midnight must advance by exactly 1 day');
    end;

    [Test]
    procedure DateTime_Plus_Duration_AdvancesTime()
    var
        DT: DateTime;
        Dur: Duration;
        DT2: DateTime;
    begin
        DT := CreateDateTime(20240101D, 120000T);
        Dur := 3600000;
        DT2 := DT + Dur;
        Assert.AreEqual(130000T, DT2Time(DT2), 'Adding 3600000ms to 12:00:00 must give 13:00:00');
    end;

    [Test]
    procedure DateTime_Minus_DateTime_GivesDuration()
    var
        DT1: DateTime;
        DT2: DateTime;
        Diff: Duration;
        ExpDur: Duration;
    begin
        DT1 := CreateDateTime(20240101D, 120000T);
        DT2 := CreateDateTime(20240101D, 130000T);
        ExpDur := 3600000;
        Diff := DT2 - DT1;
        Assert.AreEqual(ExpDur, Diff, 'DT2 - DT1 where DT2 is 1 hour later must give Duration of 3600000ms');
    end;

    [Test]
    procedure DT2Date_ZeroDateTime_ReturnsZeroDate()
    begin
        Assert.AreEqual(0D, DT2Date(0DT), 'DT2Date(0DT) must return 0D');
    end;

    [Test]
    procedure DT2Time_ZeroDateTime_ReturnsZeroTime()
    begin
        Assert.AreEqual(0T, DT2Time(0DT), 'DT2Time(0DT) must return 0T');
    end;

    [Test]
    procedure NormalDate_NormalDate_ReturnsSame()
    begin
        Assert.AreEqual(20240315D, NormalDate(20240315D), 'NormalDate on normal date must return unchanged');
    end;

    [Test]
    procedure NormalDate_ClosingDate_ReturnsBase()
    var
        CD: Date;
        ND: Date;
    begin
        CD := ClosingDate(20241231D);
        ND := NormalDate(CD);
        Assert.AreEqual(20241231D, ND, 'NormalDate on closing date must return the underlying normal date');
    end;

    [Test]
    procedure Format_ZeroDate_ReturnsEmpty()
    begin
        Assert.AreEqual('', Format(0D), 'Format(0D) must return empty string');
    end;

    [Test]
    procedure Format_ZeroTime_ReturnsEmpty()
    begin
        Assert.AreEqual('', Format(0T), 'Format(0T) must return empty string');
    end;

    [Test]
    procedure Format_ZeroDateTime_ReturnsEmpty()
    begin
        Assert.AreEqual('', Format(0DT), 'Format(0DT) must return empty string');
    end;

    [Test]
    procedure CreateDateTime_LeapYearFeb29_Works()
    var
        DT: DateTime;
    begin
        DT := CreateDateTime(20240229D, 120000T);
        Assert.AreNotEqual(0DT, DT, 'CreateDateTime with Feb 29 leap year must succeed and return non-zero');
        Assert.AreEqual(20240229D, DT2Date(DT), 'Date part must be Feb 29, 2024');
    end;

    [Test]
    procedure WorkDate_IsSetableAndGettable()
    var
        OldDate: Date;
    begin
        OldDate := WorkDate();
        WorkDate(20240101D);
        Assert.AreEqual(20240101D, WorkDate(), 'WorkDate setter and getter must roundtrip');
        WorkDate(OldDate);
    end;
}
