// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefiltertestpagefilter-setfilter-method
// Scope: in-scope
// Fixtures used: Test Page Filter Position Row (60692), Test Page Filter Position List (60693)
//
// Applying a filter through TestPage.Filter.SetFilter changes which rows the page has. A page
// left sitting on a row the new filter excludes is not merely stale — it reports values from a
// record that is not on the page at all.
//
// That failure mode is the dangerous kind: the test reads a real, plausible-looking value
// belonging to the wrong row, so it fails claiming the data is wrong rather than the cursor.

codeunit 60694 "Test Page Filter Position"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "Test Page Filter Position Row";
    begin
        Row.DeleteAll();
    end;

    local procedure Seed()
    begin
        Insert1('A', 'Alpha');
        Insert1('B', 'Bravo');
        Insert1('C', 'Charlie');
    end;

    local procedure Insert1(No: Code[20]; Name: Text[50])
    var
        Row: Record "Test Page Filter Position Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := Name;
        Row.Insert();
    end;

    [Test]
    procedure SetFilter_ExcludingTheCurrentRow_MovesToTheFirstMatch()
    var
        List: TestPage "Test Page Filter Position List";
    begin
        Initialize();
        Seed();

        List.OpenEdit();
        List.First();
        if List."No.".Value() <> 'A' then
            Error('Precondition: the page opened on <%1>, expected A.', List."No.".Value());

        // A is now excluded. Reading the page must not still answer from it.
        List.Filter.SetFilter("No.", 'B|C');
        if List."No.".Value() <> 'B' then
            Error('After filtering to B|C the page read <%1>, expected B — the cursor was left ' +
                  'on a row the filter excludes.', List."No.".Value());
        if List.Name.Value() <> 'Bravo' then
            Error('After filtering to B|C the Name read <%1>, expected Bravo.', List.Name.Value());

        List.Close();
    end;

    [Test]
    procedure SetFilter_EvenWhenCurrentRowStillQualifies_RepositionsToTheFirstMatch()
    var
        List: TestPage "Test Page Filter Position List";
    begin
        Initialize();
        Seed();

        List.OpenEdit();
        List.First();
        List.Next();
        if List."No.".Value() <> 'B' then
            Error('Precondition: expected to be on B, was on <%1>.', List."No.".Value());

        // Verified against real BC: SetFilter always repositions to the first row of the NEW
        // filtered set, exactly like the underlying Record.SetFilter — it does not special-case
        // "the current row still qualifies" to leave the cursor in place. The sibling test
        // above already proves the reposition-to-first-match behavior when the current row is
        // EXCLUDED; this proves the same reposition happens even when it would have been valid
        // to stay. A fix that tried to preserve the cursor when possible would fail here.
        List.Filter.SetFilter("No.", 'A|B|C');
        if List."No.".Value() <> 'A' then
            Error('After SetFilter the page read <%1>, expected A — SetFilter must reposition ' +
                  'to the first match even when the previously-current row still qualifies.',
                List."No.".Value());

        List.Close();
    end;

    [Test]
    procedure SetFilter_MatchingNothing_LeavesNoRow()
    var
        List: TestPage "Test Page Filter Position List";
    begin
        Initialize();
        Seed();

        List.OpenEdit();
        List.First();

        // The other direction: an empty result must be reported as empty, not as "still on the
        // last row I remember". This is what stops a repositioning fix from inventing a row.
        List.Filter.SetFilter("No.", 'NOTHING-MATCHES');
        if List.First() then
            Error('First() found a row on a page whose filter matches nothing: <%1>.',
                List."No.".Value());

        List.Close();
    end;
}
