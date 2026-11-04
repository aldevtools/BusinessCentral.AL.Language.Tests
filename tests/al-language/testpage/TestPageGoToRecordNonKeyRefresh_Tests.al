// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-gotorecord-method
// Scope: in-scope
// Fixtures used: Test GTR NonKeyRefresh Row (60045), Test GTR NonKeyRefresh List (60046)
//
// GoToRecord's not-found path must leave the page's fields -- including NON-key fields --
// reading the ORIGINALLY POSITIONED row's own values, even when that row is not the last row
// a forward not-found scan would visit. Companion to codeunit 60044 "Test GoToRecord DupCap
// Tests" (#122), which only asserted the key field (and, for its arm, a row that happened to
// be the last one scanned by the not-found search).
//
// Measured against real BC 27.0/27.3/27.5/28.0/28.1/28.2/28.3/28.4 via an observation probe
// (StefanMaron/BusinessCentral.AL.Language.Tests#123): positioning on row A (the FIRST of
// three rows, NOT the last row a forward not-found scan for an absent key visits) and then
// probing an absent key leaves the page reading key=A desc=Alpha on every leg -- BC keeps
// the originally positioned row's full values, not a partial/stale mix from whichever row
// the internal not-found scan last visited.

codeunit 60047 "Test GTR NonKeyRefresh Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure SeedRows()
    var
        Row: Record "Test GTR NonKeyRefresh Row";
    begin
        Row.DeleteAll();
        Row.Init(); Row."No." := 'A'; Row.Descr := 'Alpha'; Row.Insert();
        Row.Init(); Row."No." := 'B'; Row.Descr := 'Bravo'; Row.Insert();
        Row.Init(); Row."No." := 'C'; Row.Descr := 'Charlie'; Row.Insert();
    end;

    // Negative: a not-found probe after positioning on a row that is NOT the last row the
    // internal forward scan visits must leave BOTH the key field and a non-key field reading
    // the originally positioned row's own values.
    [Test]
    procedure GoToRecord_NotFoundProbe_AfterPositioningOnFirstRow_KeepsFullOriginalRow()
    var
        Row: Record "Test GTR NonKeyRefresh Row";
        Missing: Record "Test GTR NonKeyRefresh Row";
        TgrList: TestPage "Test GTR NonKeyRefresh List";
    begin
        SeedRows();

        Row.Get('A');
        Missing.Init();
        Missing."No." := 'ZZZ';
        Missing.Descr := 'Not inserted';

        TgrList.OpenView();
        Assert.IsTrue(TgrList.GoToRecord(Row), 'row A must be reachable');
        Assert.IsFalse(TgrList.GoToRecord(Missing), 'absent row must not be reachable');
        Assert.AreEqual('A', TgrList."No.".Value(), 'key field must still read row A');
        Assert.AreEqual('Alpha', TgrList.Descr.Value(), 'non-key field must still read row A''s own value, not a later row''s');
        TgrList.Close();
    end;

    // Positive control: positioning on the LAST row a forward not-found scan visits still
    // works -- this is what codeunit 60044's dup-caption not-found arm already exercised, and
    // it must keep passing here as a control for the arm above.
    [Test]
    procedure GoToRecord_NotFoundProbe_AfterPositioningOnLastRow_KeepsFullRow()
    var
        Row: Record "Test GTR NonKeyRefresh Row";
        Missing: Record "Test GTR NonKeyRefresh Row";
        TgrList: TestPage "Test GTR NonKeyRefresh List";
    begin
        SeedRows();

        Row.Get('C');
        Missing.Init();
        Missing."No." := 'ZZZ';
        Missing.Descr := 'Not inserted';

        TgrList.OpenView();
        Assert.IsTrue(TgrList.GoToRecord(Row), 'row C must be reachable');
        Assert.IsFalse(TgrList.GoToRecord(Missing), 'absent row must not be reachable');
        Assert.AreEqual('C', TgrList."No.".Value(), 'key field must still read row C');
        Assert.AreEqual('Charlie', TgrList.Descr.Value(), 'non-key field must still read row C''s own value');
        TgrList.Close();
    end;
}
