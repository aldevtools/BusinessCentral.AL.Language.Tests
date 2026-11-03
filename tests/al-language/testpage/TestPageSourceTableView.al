// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Assert (60021), ALT Keyed (60006), ALT Trigger Log (60003),
//   ALT Source Table View List (60821), Base Application page 1710 "Deferral Lines - G/L"
//   over table 1702 "Deferral Line"
//
// A page's SourceTableView property is applied by the platform when the page opens, BEFORE
// the page's own OnOpenPage trigger runs. Nothing in this corpus stated that, and three
// separate things follow from it that a page author relies on:
//
//   1. the rows the page shows are the ones the view's where(...) admits, and no others;
//   2. they arrive in the order the view's sorting(...) / order(...) declare, not in the
//      table's own primary-key order;
//   3. the where(...) filters live in FILTER GROUP 2, not in filter group 0 — so a page's
//      own AL can read them back with FilterGroup(2) + GetFilter, which several Base
//      Application pages do in their OnOpenPage.
//
// The last arm drives a page this app does not declare (Base Application page 1710
// "Deferral Lines - G/L", SourceTableView = where("Deferral Doc. Type" = const("G/L"))), for
// the same reason TestPagePlatformPageSourceTable_Tests drives page 5: a view declared by
// another app must be applied just as one declared here is.
//
// Every arm is gated in both directions. The row asserted first is NOT the one the table's
// own primary key would put first, the excluded rows are reachable in the table and must not
// be reachable through the page, and the filter-group arm asserts a concrete value in group 2
// AND emptiness in group 0 — so a page that applied the view into the wrong group, or applied
// nothing at all, fails.

using Microsoft.Finance.Deferral;

codeunit 60822 "Test Page Source Table View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // A template name deliberately outside anything a demo company ships, so the Base
    // Application arm neither depends on nor disturbs existing Deferral Line rows.
    local procedure Initialize()
    var
        DeferralLine: Record "Deferral Line";
    begin
        Cleanup.Initialize();
        DeferralLine.SetRange("Gen. Jnl. Template Name", 'ALTSTV');
        DeferralLine.DeleteAll();
    end;

    local procedure SeedKeyed(EntryNo: Integer; NewName: Text[50]; NewAmount: Decimal; NewStatus: Enum "ALT Status")
    var
        ALTKeyed: Record "ALT Keyed";
    begin
        ALTKeyed.Init();
        ALTKeyed."Entry No." := EntryNo;
        ALTKeyed.Name := NewName;
        ALTKeyed.Amount := NewAmount;
        ALTKeyed.Status := NewStatus;
        ALTKeyed.Insert();
    end;

    // Seeds the four rows every ALT Keyed arm below shares:
    //   1  Amount 10  Active   — in the view
    //   2  Amount 20  Active   — in the view, and the one the view's descending Amount
    //                           sorting must put FIRST (the primary key would put 1 first)
    //   3  Amount 30  Closed   — excluded by Status = const(Active)
    //   4  Amount 40  Active   — excluded by "Entry No." = filter(1|2|3)
    local procedure SeedTheFourRows()
    var
        ALTStatus: Enum "ALT Status";
    begin
        SeedKeyed(1, 'One', 10, ALTStatus::Active);
        SeedKeyed(2, 'Two', 20, ALTStatus::Active);
        SeedKeyed(3, 'Three', 30, ALTStatus::Closed);
        SeedKeyed(4, 'Four', 40, ALTStatus::Active);
    end;

    // CLAIM: the page shows exactly the rows the view's where(...) admits.
    [Test]
    procedure TestPage_SourceTableView_ShowsOnlyTheRowsTheWhereClauseAdmits()
    var
        ViewList: TestPage "ALT Source Table View List";
        SeenEntryNos: Text;
    begin
        Initialize();
        SeedTheFourRows();

        ViewList.OpenView();
        Assert.IsTrue(ViewList.First(), 'the view admits rows 1 and 2, so the page must have a first row');
        SeenEntryNos := Format(ViewList."Entry No.".AsInteger());
        while ViewList.Next() do
            SeenEntryNos := SeenEntryNos + ',' + Format(ViewList."Entry No.".AsInteger());
        ViewList.Close();

        // Row 3 fails Status = const(Active) and row 4 fails "Entry No." = filter(1|2|3);
        // an unapplied view would read '1,2,3,4'. The order asserted here is the view's own
        // (descending Amount) — see the sorting arm below for why that is not the table's.
        Assert.AreEqual('2,1', SeenEntryNos,
            'the page must show exactly the rows the SourceTableView where() clause admits');
    end;

    // CLAIM: the rows arrive in the view's declared order, not the table's primary-key order.
    [Test]
    procedure TestPage_SourceTableView_OrdersRowsBySortingAndOrderClauses()
    var
        ViewList: TestPage "ALT Source Table View List";
    begin
        Initialize();
        SeedTheFourRows();

        ViewList.OpenView();

        // "ALT Keyed"'s primary key is "Entry No." ascending, which would put row 1 first.
        // sorting(Amount) order(descending) puts row 2 (Amount 20) there instead, so this
        // assertion cannot be satisfied by a page that ignored the sorting clause.
        Assert.IsTrue(ViewList.First(), 'the view admits two rows');
        Assert.AreEqual(2, ViewList."Entry No.".AsInteger(),
            'order(descending) on sorting(Amount) must put the highest Amount first');
        Assert.IsTrue(ViewList.Next(), 'the second admitted row must be reachable');
        Assert.AreEqual(1, ViewList."Entry No.".AsInteger(),
            'the lower Amount must come second under order(descending)');
        Assert.IsFalse(ViewList.Next(), 'exactly two rows are admitted, so there is no third');
        ViewList.Close();
    end;

    // CLAIM: the view's filters are in filter group 2 at OnOpenPage time, and not in group 0.
    [Test]
    procedure TestPage_SourceTableView_FiltersAreInFilterGroup2WhenOnOpenPageRuns()
    var
        TrigLog: Record "ALT Trigger Log";
        ViewList: TestPage "ALT Source Table View List";
    begin
        Initialize();
        SeedTheFourRows();

        ViewList.OpenView();
        ViewList.Close();

        TrigLog.SetRange("TriggerName", 'OnOpenPage');
        Assert.IsTrue(TrigLog.FindLast(), 'the page''s OnOpenPage trigger must have run');

        // 'Active' is the member name of a value that is neither the enum's first member nor
        // its default, so neither a blank answer nor a zero-ordinal fallback can produce it.
        Assert.AreEqual('Active', TrigLog."NewValue",
            'the SourceTableView const() filter must be readable in filter group 2 from OnOpenPage');
        // The other direction: a view filter belongs to group 2 only. Leaking it into group 0
        // would make it visible as a user filter and removable with a FilterGroup(0) reset.
        Assert.AreEqual('', TrigLog."OldValue",
            'a SourceTableView filter must not appear in filter group 0');
    end;

    local procedure SeedDeferralLine(DocType: Enum "Deferral Document Type"; NewDescription: Text[100])
    var
        DeferralLine: Record "Deferral Line";
    begin
        DeferralLine.Init();
        DeferralLine."Deferral Doc. Type" := DocType;
        DeferralLine."Gen. Jnl. Template Name" := 'ALTSTV';
        DeferralLine."Gen. Jnl. Batch Name" := 'ALTSTVB';
        DeferralLine."Line No." := 10000;
        DeferralLine."Posting Date" := WorkDate();
        DeferralLine.Description := NewDescription;
        DeferralLine.Insert();
    end;

    // CLAIM: a SourceTableView declared by a page in ANOTHER app is applied the same way.
    [Test]
    procedure TestPage_SourceTableView_OnAPageFromAnotherApp_FiltersRows()
    var
        DeferralDocType: Enum "Deferral Document Type";
        DeferralLinesGL: TestPage "Deferral Lines - G/L";
    begin
        Initialize();
        // Sales sorts BEFORE G/L in "Deferral Line"'s primary key (the key starts with
        // "Deferral Doc. Type", whose Sales member is 1 and G/L member is 2), so a page that
        // ignored the view would show the Sales row first — and show two rows, not one.
        SeedDeferralLine(DeferralDocType::Sales, 'ALT Sales row');
        SeedDeferralLine(DeferralDocType::"G/L", 'ALT G/L row');

        DeferralLinesGL.OpenView();
        DeferralLinesGL.Filter.SetFilter("Gen. Jnl. Template Name", 'ALTSTV');

        Assert.IsTrue(DeferralLinesGL.First(), 'the seeded G/L row must be visible on page 1710');
        Assert.AreEqual('ALT G/L row', DeferralLinesGL.Description.Value(),
            'page 1710 declares SourceTableView = where("Deferral Doc. Type" = const("G/L")), ' +
            'so the Sales row must not be the one shown');
        Assert.IsFalse(DeferralLinesGL.Next(),
            'the Sales row must not be reachable through a page whose view excludes it');
        DeferralLinesGL.Close();
    end;
}
