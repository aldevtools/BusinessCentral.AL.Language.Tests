// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: SPS Row (67930), SPS Part (67930), SPS Host (67931), Assert (60021)
//
/// <summary>
/// Pins that a part's SubPageView SORTING orders the rows the part shows.
///
/// The sibling file TestPartSubPageView.al pins the view's where() half: which rows a part
/// shows, and that the filter lands in group 4. It says nothing about sorting() or order(),
/// the other half of a view. Written for AL Runner issue
/// StefanMaron/BusinessCentral.AL.Runner#4188, whose runner fix applied the view's filters and
/// left its sorting unapplied.
///
/// The table's primary key order and its Rank order disagree on every row, so each arm's
/// expected sequence differs from every other arm's:
///
///     Entry No.  Rank  Bucket
///         1       30    KEEP
///         2       10    DROP
///         3       40    KEEP
///         4       20    KEEP
///
///     OpenPart         (no view)                                 1, 2, 3, 4
///     RankAscPart      sorting(Rank)                             2, 4, 1, 3
///     RankDescPart     sorting(Rank) order(descending)           3, 1, 4, 2
///     PKDescPart       order(descending)                         1, 2, 3, 4   (measured; see its arm)
///     KeepRankDescPart sorting(Rank) order(descending)
///                      where(Bucket = const('KEEP'))             3, 1, 4
///     LinkedRankDesc   SubPageLink Bucket = field(Bucket)
///                      + sorting(Rank) order(descending)         3, 1, 4   (host on entry 1)
///
/// All six parts show the same page over the same rows on one host, so the OpenPart control
/// separates "the view's sorting was ignored" from "the rows are not there".
///
/// Each arm walks with First/Next and stops at the last seeded row it expects: an editable
/// ListPart shows a trailing blank new row, so walking to the end measures n+1
/// (TestPartSubPageView.al records that finding).
/// </summary>

table 67930 "SPS Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Rank; Integer) { }
        field(3; Bucket; Code[10]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByRank; Rank) { }
    }
}

page 67930 "SPS Part"
{
    PageType = ListPart;
    SourceTable = "SPS Row";
    ApplicationArea = All;
    Caption = 'SPS Part';
    // No SourceTableView: the subject is the SubPageView on each part CONTROL in the host.

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
                field(Bucket; Rec.Bucket) { ApplicationArea = All; }
            }
        }
    }
}

page 67931 "SPS Host"
{
    PageType = Card;
    SourceTable = "SPS Row";
    ApplicationArea = All;
    Caption = 'SPS Host';

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
            field(Bucket; Rec.Bucket) { ApplicationArea = All; }

            // The control: no view, primary key order.
            part(OpenPart; "SPS Part") { ApplicationArea = All; }
            part(RankAscPart; "SPS Part")
            {
                ApplicationArea = All;
                SubPageView = sorting(Rank);
            }
            part(RankDescPart; "SPS Part")
            {
                ApplicationArea = All;
                SubPageView = sorting(Rank) order(descending);
            }
            part(PKDescPart; "SPS Part")
            {
                ApplicationArea = All;
                SubPageView = order(descending);
            }
            part(KeepRankDescPart; "SPS Part")
            {
                ApplicationArea = All;
                SubPageView = sorting(Rank) order(descending) where(Bucket = const('KEEP'));
            }
            part(LinkedRankDescPart; "SPS Part")
            {
                ApplicationArea = All;
                SubPageLink = Bucket = field(Bucket);
                SubPageView = sorting(Rank) order(descending);
            }
        }
    }
}

codeunit 67930 "SPS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        Row: Record "SPS Row";
    begin
        Row.DeleteAll();
        AddRow(1, 30, 'KEEP');
        AddRow(2, 10, 'DROP');
        AddRow(3, 40, 'KEEP');
        AddRow(4, 20, 'KEEP');
    end;

    local procedure AddRow(EntryNo: Integer; NewRank: Integer; NewBucket: Code[10])
    var
        Row: Record "SPS Row";
    begin
        Row.Init();
        Row."Entry No." := EntryNo;
        Row.Rank := NewRank;
        Row.Bucket := NewBucket;
        Row.Insert();
    end;

    local procedure OpenHost(var Host: TestPage "SPS Host")
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey(1);
    end;

    [Test]
    procedure PartWithoutSubPageView_ShowsPrimaryKeyOrder()
    // The control. Without it, a runner that ignored every view and one that sorted every
    // part the same way would be indistinguishable from the arms below.
    var
        Host: TestPage "SPS Host";
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.OpenPart.First(), 'the open part has a first row');
        Assert.AreEqual('1', Host.OpenPart."Entry No.".Value(), 'row 1 of the open part');
        Assert.IsTrue(Host.OpenPart.Next(), 'the open part has a second row');
        Assert.AreEqual('2', Host.OpenPart."Entry No.".Value(), 'row 2 of the open part');
        Assert.IsTrue(Host.OpenPart.Next(), 'the open part has a third row');
        Assert.AreEqual('3', Host.OpenPart."Entry No.".Value(), 'row 3 of the open part');
        Assert.IsTrue(Host.OpenPart.Next(), 'the open part has a fourth row');
        Assert.AreEqual('4', Host.OpenPart."Entry No.".Value(), 'row 4 of the open part');

        Host.Close();
    end;

    [Test]
    procedure SubPageViewSorting_OrdersThePartByTheViewKeyAscending()
    // sorting(Rank) with no order(): ascending by Rank, 10/20/30/40.
    var
        Host: TestPage "SPS Host";
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.RankAscPart.First(), 'the ascending part has a first row');
        Assert.AreEqual('2', Host.RankAscPart."Entry No.".Value(), 'row 1 is entry 2 (Rank 10)');
        Assert.IsTrue(Host.RankAscPart.Next(), 'the ascending part has a second row');
        Assert.AreEqual('4', Host.RankAscPart."Entry No.".Value(), 'row 2 is entry 4 (Rank 20)');
        Assert.IsTrue(Host.RankAscPart.Next(), 'the ascending part has a third row');
        Assert.AreEqual('1', Host.RankAscPart."Entry No.".Value(), 'row 3 is entry 1 (Rank 30)');
        Assert.IsTrue(Host.RankAscPart.Next(), 'the ascending part has a fourth row');
        Assert.AreEqual('3', Host.RankAscPart."Entry No.".Value(), 'row 4 is entry 3 (Rank 40)');

        Host.Close();
    end;

    [Test]
    procedure SubPageViewSortingDescending_OrdersThePartByTheViewKeyDescending()
    // sorting(Rank) order(descending): 40/30/20/10.
    var
        Host: TestPage "SPS Host";
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.RankDescPart.First(), 'the descending part has a first row');
        Assert.AreEqual('3', Host.RankDescPart."Entry No.".Value(), 'row 1 is entry 3 (Rank 40)');
        Assert.IsTrue(Host.RankDescPart.Next(), 'the descending part has a second row');
        Assert.AreEqual('1', Host.RankDescPart."Entry No.".Value(), 'row 2 is entry 1 (Rank 30)');
        Assert.IsTrue(Host.RankDescPart.Next(), 'the descending part has a third row');
        Assert.AreEqual('4', Host.RankDescPart."Entry No.".Value(), 'row 3 is entry 4 (Rank 20)');
        Assert.IsTrue(Host.RankDescPart.Next(), 'the descending part has a fourth row');
        Assert.AreEqual('2', Host.RankDescPart."Entry No.".Value(), 'row 4 is entry 2 (Rank 10)');

        Host.Close();
    end;

    [Test]
    procedure SubPageViewOrderOnly_KeepsPrimaryKeyOrder()
    // order(descending) with no sorting(): the part stays in primary key order, ASCENDING.
    //
    // Measured, and it falsified the first version of this arm, which expected 4, 3, 2, 1.
    // Every cloud leg (27.0 through 28.5) and the official Windows container (28.4.53241.55369,
    // nightly run 36585163649) answered `Expected:<4> Actual:<1>`. On a part, a view's order()
    // takes effect only together with a sorting() key -- the RankDescPart arm, which names one,
    // does descend.
    var
        Host: TestPage "SPS Host";
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.PKDescPart.First(), 'the order-only part has a first row');
        Assert.AreEqual('1', Host.PKDescPart."Entry No.".Value(), 'row 1 is entry 1');
        Assert.IsTrue(Host.PKDescPart.Next(), 'the order-only part has a second row');
        Assert.AreEqual('2', Host.PKDescPart."Entry No.".Value(), 'row 2 is entry 2');
        Assert.IsTrue(Host.PKDescPart.Next(), 'the order-only part has a third row');
        Assert.AreEqual('3', Host.PKDescPart."Entry No.".Value(), 'row 3 is entry 3');
        Assert.IsTrue(Host.PKDescPart.Next(), 'the order-only part has a fourth row');
        Assert.AreEqual('4', Host.PKDescPart."Entry No.".Value(), 'row 4 is entry 4');

        Host.Close();
    end;

    [Test]
    procedure SubPageViewSortingAndWhere_FiltersAndOrdersTogether()
    // A view with both halves: entry 2 (DROP) is excluded, the rest descend by Rank.
    var
        Host: TestPage "SPS Host";
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.KeepRankDescPart.First(), 'the filtered sorted part has a first row');
        Assert.AreEqual('3', Host.KeepRankDescPart."Entry No.".Value(), 'row 1 is entry 3 (Rank 40)');
        Assert.IsTrue(Host.KeepRankDescPart.Next(), 'the filtered sorted part has a second row');
        Assert.AreEqual('1', Host.KeepRankDescPart."Entry No.".Value(), 'row 2 is entry 1 (Rank 30)');
        Assert.IsTrue(Host.KeepRankDescPart.Next(), 'the filtered sorted part has a third row');
        Assert.AreEqual('4', Host.KeepRankDescPart."Entry No.".Value(), 'row 3 is entry 4 (Rank 20) -- entry 2 is a DROP row the view excludes');

        Host.Close();
    end;

    [Test]
    procedure SubPageViewSortingWithSubPageLink_LinksAndOrdersTogether()
    // The link selects the host row's Bucket (entry 1: KEEP), the view orders what it selects.
    var
        Host: TestPage "SPS Host";
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.LinkedRankDescPart.First(), 'the linked sorted part has a first row');
        Assert.AreEqual('3', Host.LinkedRankDescPart."Entry No.".Value(), 'row 1 is entry 3 (Rank 40)');
        Assert.IsTrue(Host.LinkedRankDescPart.Next(), 'the linked sorted part has a second row');
        Assert.AreEqual('1', Host.LinkedRankDescPart."Entry No.".Value(), 'row 2 is entry 1 (Rank 30)');
        Assert.IsTrue(Host.LinkedRankDescPart.Next(), 'the linked sorted part has a third row');
        Assert.AreEqual('4', Host.LinkedRankDescPart."Entry No.".Value(), 'row 3 is entry 4 (Rank 20) -- entry 2 is in another Bucket than the host row');

        Host.Close();
    end;
}
