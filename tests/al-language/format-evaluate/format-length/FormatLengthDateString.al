// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper codeunit 96388 "FLN Fmt" (FormatLengthHelper.al)
// Probe: runner issue 8890. Measured by the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what BC produced.
// Facts: Format(Value, Length, FormatString) of a Date, a Time and a DateTime, defined and undefined, under format strings with and without
//   separators, for positive and negative lengths shorter than, as long as and longer than the text the same string gives with Length 0.
//   The reporter's shape is Format(D, 8, '<Year4><Month,2><Day,2>'). FormatLengthDates.al measures the string '<Year4>-<Month,2>-<Day,2>'
//   for some lengths; this file adds its other lengths and the other strings.
// Results (BC 27.5, 28.5, 29.0, all three agree): let T be the text the same format string gives with Length 0. For a Date, a Time and a DateTime,
//   with or without separators, a length L with |L| shorter than T cuts T to its first |L| characters (positive and negative L alike).
//   A positive L longer than T pads T on the left with blanks to L characters; a negative L as long as or longer than T keeps T.
//   An undefined Date or DateTime (T = '') gives L blanks for a positive L and '' for a negative L. A closing Date formats as the plain date.

codeunit 75961 "FLN Date String Lengths"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The reporter's shape: a literal format string without separators, Length 8 as long as the text.
    [Test]
    procedure Date_Compact_Literal()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(23, 11, 2026);
        Observer.Observe('Format(D, 8, S)', '[' + Format(D, 8, '<Year4><Month,2><Day,2>') + ']');
        Observer.Observe('Format(D, 0, S)', '[' + Format(D, 0, '<Year4><Month,2><Day,2>') + ']');
        Observer.Observe('Format(D, 6, S)', '[' + Format(D, 6, '<Year4><Month,2><Day,2>') + ']');
        Observer.Observe('Format(D, 10, S)', '[' + Format(D, 10, '<Year4><Month,2><Day,2>') + ']');
        Observer.Observe('Format(D, -8, S)', '[' + Format(D, -8, '<Year4><Month,2><Day,2>') + ']');
        Observer.Observe('Format(D, -6, S)', '[' + Format(D, -6, '<Year4><Month,2><Day,2>') + ']');
        Observer.Observe('Format(D, -10, S)', '[' + Format(D, -10, '<Year4><Month,2><Day,2>') + ']');
        Observer.Expect('Format(D, 8, S)', '[20261123]');
        Observer.Expect('Format(D, 0, S)', '[20261123]');
        Observer.Expect('Format(D, 6, S)', '[202611]');
        Observer.Expect('Format(D, 10, S)', '[  20261123]');
        Observer.Expect('Format(D, -8, S)', '[20261123]');
        Observer.Expect('Format(D, -6, S)', '[202611]');
        Observer.Expect('Format(D, -10, S)', '[20261123]');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Compact()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
        S: Text;
    begin
        D := 20240105D;
        S := '<Year4><Month,2><Day,2>';
        Observer.Observe('L=0', F.DateS(D, 0, S));
        Observer.Observe('L=8', F.DateS(D, 8, S));
        Observer.Observe('L=7', F.DateS(D, 7, S));
        Observer.Observe('L=3', F.DateS(D, 3, S));
        Observer.Observe('L=1', F.DateS(D, 1, S));
        Observer.Observe('L=9', F.DateS(D, 9, S));
        Observer.Observe('L=10', F.DateS(D, 10, S));
        Observer.Observe('L=30', F.DateS(D, 30, S));
        Observer.Observe('L=-8', F.DateS(D, -8, S));
        Observer.Observe('L=-7', F.DateS(D, -7, S));
        Observer.Observe('L=-3', F.DateS(D, -3, S));
        Observer.Observe('L=-1', F.DateS(D, -1, S));
        Observer.Observe('L=-9', F.DateS(D, -9, S));
        Observer.Observe('L=-10', F.DateS(D, -10, S));
        Observer.Observe('L=-30', F.DateS(D, -30, S));
        Observer.Observe('closing L=8', F.DateS(ClosingDate(D), 8, S));
        Observer.Observe('closing L=10', F.DateS(ClosingDate(D), 10, S));
        Observer.Observe('closing L=-8', F.DateS(ClosingDate(D), -8, S));
        Observer.Observe('0D L=0', F.DateS(0D, 0, S));
        Observer.Observe('0D L=8', F.DateS(0D, 8, S));
        Observer.Observe('0D L=3', F.DateS(0D, 3, S));
        Observer.Observe('0D L=10', F.DateS(0D, 10, S));
        Observer.Observe('0D L=-8', F.DateS(0D, -8, S));
        Observer.Observe('0D L=-10', F.DateS(0D, -10, S));
        Observer.Expect('L=0', '[20240105]');
        Observer.Expect('L=8', '[20240105]');
        Observer.Expect('L=7', '[2024010]');
        Observer.Expect('L=3', '[202]');
        Observer.Expect('L=1', '[2]');
        Observer.Expect('L=9', '[ 20240105]');
        Observer.Expect('L=10', '[  20240105]');
        Observer.Expect('L=30', '[                      20240105]');
        Observer.Expect('L=-8', '[20240105]');
        Observer.Expect('L=-7', '[2024010]');
        Observer.Expect('L=-3', '[202]');
        Observer.Expect('L=-1', '[2]');
        Observer.Expect('L=-9', '[20240105]');
        Observer.Expect('L=-10', '[20240105]');
        Observer.Expect('L=-30', '[20240105]');
        Observer.Expect('closing L=8', '[20240105]');
        Observer.Expect('closing L=10', '[  20240105]');
        Observer.Expect('closing L=-8', '[20240105]');
        Observer.Expect('0D L=0', '[]');
        Observer.Expect('0D L=8', '[        ]');
        Observer.Expect('0D L=3', '[   ]');
        Observer.Expect('0D L=10', '[          ]');
        Observer.Expect('0D L=-8', '[]');
        Observer.Expect('0D L=-10', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Date_OtherStrings()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
        S: Text;
        Y: Text;
    begin
        D := 20240105D;
        S := '<Day,2>.<Month,2>.<Year4>';
        Observer.Observe('DMY L=0', F.DateS(D, 0, S));
        Observer.Observe('DMY L=10', F.DateS(D, 10, S));
        Observer.Observe('DMY L=8', F.DateS(D, 8, S));
        Observer.Observe('DMY L=3', F.DateS(D, 3, S));
        Observer.Observe('DMY L=12', F.DateS(D, 12, S));
        Observer.Observe('DMY L=-10', F.DateS(D, -10, S));
        Observer.Observe('DMY L=-8', F.DateS(D, -8, S));
        Observer.Observe('DMY L=-12', F.DateS(D, -12, S));
        Y := '<Year><Month,2><Day,2>';
        Observer.Observe('Y2 L=0', F.DateS(D, 0, Y));
        Observer.Observe('Y2 L=6', F.DateS(D, 6, Y));
        Observer.Observe('Y2 L=4', F.DateS(D, 4, Y));
        Observer.Observe('Y2 L=8', F.DateS(D, 8, Y));
        Observer.Observe('Y2 L=-6', F.DateS(D, -6, Y));
        Observer.Observe('Y2 L=-4', F.DateS(D, -4, Y));
        Observer.Observe('Y2 L=-8', F.DateS(D, -8, Y));
        S := '<Year4>-<Month,2>-<Day,2>';
        Observer.Observe('ISO L=1', F.DateS(D, 1, S));
        Observer.Observe('ISO L=30', F.DateS(D, 30, S));
        Observer.Observe('ISO L=-1', F.DateS(D, -1, S));
        Observer.Observe('ISO L=-3', F.DateS(D, -3, S));
        Observer.Observe('ISO L=-9', F.DateS(D, -9, S));
        Observer.Observe('ISO L=-11', F.DateS(D, -11, S));
        Observer.Observe('ISO L=-30', F.DateS(D, -30, S));
        Observer.Expect('DMY L=0', '[05.01.2024]');
        Observer.Expect('DMY L=10', '[05.01.2024]');
        Observer.Expect('DMY L=8', '[05.01.20]');
        Observer.Expect('DMY L=3', '[05.]');
        Observer.Expect('DMY L=12', '[  05.01.2024]');
        Observer.Expect('DMY L=-10', '[05.01.2024]');
        Observer.Expect('DMY L=-8', '[05.01.20]');
        Observer.Expect('DMY L=-12', '[05.01.2024]');
        Observer.Expect('Y2 L=0', '[240105]');
        Observer.Expect('Y2 L=6', '[240105]');
        Observer.Expect('Y2 L=4', '[2401]');
        Observer.Expect('Y2 L=8', '[  240105]');
        Observer.Expect('Y2 L=-6', '[240105]');
        Observer.Expect('Y2 L=-4', '[2401]');
        Observer.Expect('Y2 L=-8', '[240105]');
        Observer.Expect('ISO L=1', '[2]');
        Observer.Expect('ISO L=30', '[                    2024-01-05]');
        Observer.Expect('ISO L=-1', '[2]');
        Observer.Expect('ISO L=-3', '[202]');
        Observer.Expect('ISO L=-9', '[2024-01-0]');
        Observer.Expect('ISO L=-11', '[2024-01-05]');
        Observer.Expect('ISO L=-30', '[2024-01-05]');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Strings()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        T: Time;
        S: Text;
    begin
        T := 093005T;
        S := '<Hours24,2><Minutes,2><Seconds,2>';
        Observer.Observe('HMS L=0', F.TimeS(T, 0, S));
        Observer.Observe('HMS L=6', F.TimeS(T, 6, S));
        Observer.Observe('HMS L=4', F.TimeS(T, 4, S));
        Observer.Observe('HMS L=1', F.TimeS(T, 1, S));
        Observer.Observe('HMS L=8', F.TimeS(T, 8, S));
        Observer.Observe('HMS L=30', F.TimeS(T, 30, S));
        Observer.Observe('HMS L=-6', F.TimeS(T, -6, S));
        Observer.Observe('HMS L=-4', F.TimeS(T, -4, S));
        Observer.Observe('HMS L=-8', F.TimeS(T, -8, S));
        Observer.Observe('0T L=0', F.TimeS(0T, 0, S));
        Observer.Observe('0T L=6', F.TimeS(0T, 6, S));
        Observer.Observe('0T L=3', F.TimeS(0T, 3, S));
        Observer.Observe('0T L=8', F.TimeS(0T, 8, S));
        Observer.Observe('0T L=-6', F.TimeS(0T, -6, S));
        Observer.Observe('0T L=-8', F.TimeS(0T, -8, S));
        S := '<Hours24,2>:<Minutes,2>';
        Observer.Observe('HM L=0', F.TimeS(T, 0, S));
        Observer.Observe('HM L=5', F.TimeS(T, 5, S));
        Observer.Observe('HM L=3', F.TimeS(T, 3, S));
        Observer.Observe('HM L=7', F.TimeS(T, 7, S));
        Observer.Observe('HM L=-5', F.TimeS(T, -5, S));
        Observer.Observe('HM L=-3', F.TimeS(T, -3, S));
        Observer.Observe('HM L=-7', F.TimeS(T, -7, S));
        Observer.Expect('HMS L=0', '[ 93005]');
        Observer.Expect('HMS L=6', '[ 93005]');
        Observer.Expect('HMS L=4', '[ 930]');
        Observer.Expect('HMS L=1', '[ ]');
        Observer.Expect('HMS L=8', '[   93005]');
        Observer.Expect('HMS L=30', '[                         93005]');
        Observer.Expect('HMS L=-6', '[ 93005]');
        Observer.Expect('HMS L=-4', '[ 930]');
        Observer.Expect('HMS L=-8', '[ 93005]');
        Observer.Expect('0T L=0', '[ 00000]');
        Observer.Expect('0T L=6', '[ 00000]');
        Observer.Expect('0T L=3', '[ 00]');
        Observer.Expect('0T L=8', '[   00000]');
        Observer.Expect('0T L=-6', '[ 00000]');
        Observer.Expect('0T L=-8', '[ 00000]');
        Observer.Expect('HM L=0', '[ 9:30]');
        Observer.Expect('HM L=5', '[ 9:30]');
        Observer.Expect('HM L=3', '[ 9:]');
        Observer.Expect('HM L=7', '[   9:30]');
        Observer.Expect('HM L=-5', '[ 9:30]');
        Observer.Expect('HM L=-3', '[ 9:]');
        Observer.Expect('HM L=-7', '[ 9:30]');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Compact()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        DT: DateTime;
        S: Text;
    begin
        DT := CreateDateTime(20240105D, 093005T);
        S := '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>';
        Observer.Observe('L=0', F.DateTimeS(DT, 0, S));
        Observer.Observe('L=14', F.DateTimeS(DT, 14, S));
        Observer.Observe('L=8', F.DateTimeS(DT, 8, S));
        Observer.Observe('L=1', F.DateTimeS(DT, 1, S));
        Observer.Observe('L=16', F.DateTimeS(DT, 16, S));
        Observer.Observe('L=30', F.DateTimeS(DT, 30, S));
        Observer.Observe('L=-14', F.DateTimeS(DT, -14, S));
        Observer.Observe('L=-8', F.DateTimeS(DT, -8, S));
        Observer.Observe('L=-16', F.DateTimeS(DT, -16, S));
        Observer.Observe('0DT L=0', F.DateTimeS(0DT, 0, S));
        Observer.Observe('0DT L=14', F.DateTimeS(0DT, 14, S));
        Observer.Observe('0DT L=3', F.DateTimeS(0DT, 3, S));
        Observer.Observe('0DT L=16', F.DateTimeS(0DT, 16, S));
        Observer.Observe('0DT L=-14', F.DateTimeS(0DT, -14, S));
        Observer.Observe('0DT L=-3', F.DateTimeS(0DT, -3, S));
        Observer.Expect('L=0', '[20240105093005]');
        Observer.Expect('L=14', '[20240105093005]');
        Observer.Expect('L=8', '[20240105]');
        Observer.Expect('L=1', '[2]');
        Observer.Expect('L=16', '[  20240105093005]');
        Observer.Expect('L=30', '[                20240105093005]');
        Observer.Expect('L=-14', '[20240105093005]');
        Observer.Expect('L=-8', '[20240105]');
        Observer.Expect('L=-16', '[20240105093005]');
        Observer.Expect('0DT L=0', '[]');
        Observer.Expect('0DT L=14', '[              ]');
        Observer.Expect('0DT L=3', '[   ]');
        Observer.Expect('0DT L=16', '[                ]');
        Observer.Expect('0DT L=-14', '[]');
        Observer.Expect('0DT L=-3', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Separated()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        DT: DateTime;
        S: Text;
    begin
        DT := CreateDateTime(20240105D, 093005T);
        S := '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>';
        Observer.Observe('L=0', F.DateTimeS(DT, 0, S));
        Observer.Observe('L=16', F.DateTimeS(DT, 16, S));
        Observer.Observe('L=10', F.DateTimeS(DT, 10, S));
        Observer.Observe('L=18', F.DateTimeS(DT, 18, S));
        Observer.Observe('L=-16', F.DateTimeS(DT, -16, S));
        Observer.Observe('L=-10', F.DateTimeS(DT, -10, S));
        Observer.Observe('L=-18', F.DateTimeS(DT, -18, S));
        Observer.Expect('L=0', '[2024-01-05 09:30]');
        Observer.Expect('L=16', '[2024-01-05 09:30]');
        Observer.Expect('L=10', '[2024-01-05]');
        Observer.Expect('L=18', '[  2024-01-05 09:30]');
        Observer.Expect('L=-16', '[2024-01-05 09:30]');
        Observer.Expect('L=-10', '[2024-01-05]');
        Observer.Expect('L=-18', '[2024-01-05 09:30]');
        Observer.Verify();
    end;
}
