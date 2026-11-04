// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: SPO Row (67950), SPO View Part (67950), SPO View Desc Part (67951),
//   SPO Key Part (67952), SPO Key Desc Part (67953), SPO Desc Part (67954), SPO Host (67955),
//   SPO Key Desc List (67956), SPO Key Asc False List (67957), Assert (60021)
//
/// <summary>
/// Pins which order a part shows when the PART PAGE sets its own order and the host's part
/// control also names one in its SubPageView.
///
/// The sibling file TestPartSubPageViewSorting.al (67930 "SPS Tests") measures SubPageView
/// sorting on a part page that sets no order of its own. Written for AL Runner issue
/// StefanMaron/BusinessCentral.AL.Runner#4969.
///
/// The part page sets its order in one of three ways: SourceTableView sorting(), OnOpenPage
/// SetCurrentKey (optionally with SetAscending), or OnOpenPage Ascending(false). Each part page
/// appears once with no SubPageView (the control) and once or more with one.
///
/// What the arms show, first measured on the BC 27.5 cloud leg of this file's pull request:
/// the part control's SubPageView sorting is applied FIRST. The part page's own
/// SourceTableView is applied after it and sets only the halves it names -- sorting() sets
/// the key, order() the direction -- and the part's OnOpenPage runs last. So a part view
/// naming a key but no order() keeps the control's direction on the part's key, and an
/// OnOpenPage Ascending(false) with no key reverses the control's key.
///
/// SetAscending(Field, false) in OnOpenPage is not shown in the part's rows at all. The two
/// ListPage arms ask the same of a top-level list page.
///
/// The primary key, Rank and Score orders disagree, and so do their reverses, so every
/// candidate answer is a distinct sequence:
///
///     Entry No.  Rank  Score  Bucket
///         1       30    200    KEEP
///         2       10    400    DROP
///         3       40    300    KEEP
///         4       20    100    KEEP
///
///     PK asc 1,2,3,4   Rank asc 2,4,1,3   Score asc 4,1,3,2
///     PK desc 4,3,2,1  Rank desc 3,1,4,2  Score desc 2,3,1,4
///
/// Each arm reads the part's first n rows into one comma-separated string and compares it
/// once, so a failure message carries the whole order BC showed. It reads exactly as many rows
/// as it seeded: an editable ListPart shows a trailing blank new row (TestPartSubPageView.al).
/// </summary>

table 67950 "SPO Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Rank; Integer) { }
        field(3; Score; Integer) { }
        field(4; Bucket; Code[10]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByRank; Rank) { }
        key(ByScore; Score) { }
    }
}

page 67950 "SPO View Part"
{
    PageType = ListPart;
    SourceTable = "SPO Row";
    SourceTableView = sorting(Score);
    ApplicationArea = All;
    Caption = 'SPO View Part';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
                field(Score; Rec.Score) { ApplicationArea = All; }
            }
        }
    }
}

page 67951 "SPO View Desc Part"
{
    PageType = ListPart;
    SourceTable = "SPO Row";
    SourceTableView = sorting(Score) order(descending);
    ApplicationArea = All;
    Caption = 'SPO View Desc Part';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
                field(Score; Rec.Score) { ApplicationArea = All; }
            }
        }
    }
}

page 67952 "SPO Key Part"
{
    PageType = ListPart;
    SourceTable = "SPO Row";
    ApplicationArea = All;
    Caption = 'SPO Key Part';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
                field(Score; Rec.Score) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Score);
    end;
}

page 67953 "SPO Key Desc Part"
{
    PageType = ListPart;
    SourceTable = "SPO Row";
    ApplicationArea = All;
    Caption = 'SPO Key Desc Part';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
                field(Score; Rec.Score) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Score);
        Rec.SetAscending(Score, false);
    end;
}

page 67954 "SPO Desc Part"
{
    PageType = ListPart;
    SourceTable = "SPO Row";
    ApplicationArea = All;
    Caption = 'SPO Desc Part';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
                field(Score; Rec.Score) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Ascending(false);
    end;
}

page 67955 "SPO Host"
{
    PageType = Card;
    SourceTable = "SPO Row";
    ApplicationArea = All;
    Caption = 'SPO Host';

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }

            part(ViewNoSub; "SPO View Part") { ApplicationArea = All; }
            part(ViewSubRank; "SPO View Part")
            {
                ApplicationArea = All;
                SubPageView = sorting(Rank);
            }
            part(ViewSubRankDesc; "SPO View Part")
            {
                ApplicationArea = All;
                SubPageView = sorting(Rank) order(descending);
            }
            part(ViewSubWhere; "SPO View Part")
            {
                ApplicationArea = All;
                SubPageView = where(Bucket = const('KEEP'));
            }
            part(ViewDescNoSub; "SPO View Desc Part") { ApplicationArea = All; }
            part(ViewDescSubRank; "SPO View Desc Part")
            {
                ApplicationArea = All;
                SubPageView = sorting(Rank);
            }
            part(KeyNoSub; "SPO Key Part") { ApplicationArea = All; }
            part(KeySubRank; "SPO Key Part")
            {
                ApplicationArea = All;
                SubPageView = sorting(Rank);
            }
            part(KeyDescNoSub; "SPO Key Desc Part") { ApplicationArea = All; }
            part(KeyDescSubRank; "SPO Key Desc Part")
            {
                ApplicationArea = All;
                SubPageView = sorting(Rank);
            }
            part(DescNoSub; "SPO Desc Part") { ApplicationArea = All; }
            part(DescSubRank; "SPO Desc Part")
            {
                ApplicationArea = All;
                SubPageView = sorting(Rank);
            }
        }
    }
}

page 67956 "SPO Key Desc List"
{
    PageType = List;
    SourceTable = "SPO Row";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'SPO Key Desc List';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Score; Rec.Score) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Score);
        Rec.SetAscending(Score, false);
    end;
}

page 67957 "SPO Key Asc False List"
{
    PageType = List;
    SourceTable = "SPO Row";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'SPO Key Asc False List';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Score; Rec.Score) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Score);
        Rec.Ascending(false);
    end;
}

codeunit 67950 "SPO Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        Row: Record "SPO Row";
    begin
        Row.DeleteAll();
        AddRow(1, 30, 200, 'KEEP');
        AddRow(2, 10, 400, 'DROP');
        AddRow(3, 40, 300, 'KEEP');
        AddRow(4, 20, 100, 'KEEP');
    end;

    local procedure AddRow(EntryNo: Integer; NewRank: Integer; NewScore: Integer; NewBucket: Code[10])
    var
        Row: Record "SPO Row";
    begin
        Row.Init();
        Row."Entry No." := EntryNo;
        Row.Rank := NewRank;
        Row.Score := NewScore;
        Row.Bucket := NewBucket;
        Row.Insert();
    end;

    local procedure OpenHost(var Host: TestPage "SPO Host")
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey(1);
    end;

    [Test]
    procedure PartSourceTableView_NoSubPageView_OrdersByThePartsKey()
    // The control for the SourceTableView part: sorting(Score) alone, Score ascending.
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.ViewNoSub.First(), 'the part has a first row');
        Seq := Host.ViewNoSub."Entry No.".Value();
        Host.ViewNoSub.Next();
        Seq += ',' + Host.ViewNoSub."Entry No.".Value();
        Host.ViewNoSub.Next();
        Seq += ',' + Host.ViewNoSub."Entry No.".Value();
        Host.ViewNoSub.Next();
        Seq += ',' + Host.ViewNoSub."Entry No.".Value();
        Assert.AreEqual('4,1,3,2', Seq, 'the entry numbers the ViewNoSub part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure PartSourceTableView_WithSubPageViewSorting_ThePartsKeyWins()
    // Part: sorting(Score). Control: sorting(Rank). The part's key wins: Score ascending,
    // not Rank ascending (2,4,1,3).
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.ViewSubRank.First(), 'the part has a first row');
        Seq := Host.ViewSubRank."Entry No.".Value();
        Host.ViewSubRank.Next();
        Seq += ',' + Host.ViewSubRank."Entry No.".Value();
        Host.ViewSubRank.Next();
        Seq += ',' + Host.ViewSubRank."Entry No.".Value();
        Host.ViewSubRank.Next();
        Seq += ',' + Host.ViewSubRank."Entry No.".Value();
        Assert.AreEqual('4,1,3,2', Seq, 'the entry numbers the ViewSubRank part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure PartSourceTableView_WithSubPageViewSortingDescending_KeyFromPartDirectionFromView()
    // Part: sorting(Score), no order(). Control: sorting(Rank) order(descending).
    // The part's view sets only the key it names, so the control's direction survives:
    // Score DESCENDING. Neither Rank descending (3,1,4,2) nor Score ascending (4,1,3,2).
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.ViewSubRankDesc.First(), 'the part has a first row');
        Seq := Host.ViewSubRankDesc."Entry No.".Value();
        Host.ViewSubRankDesc.Next();
        Seq += ',' + Host.ViewSubRankDesc."Entry No.".Value();
        Host.ViewSubRankDesc.Next();
        Seq += ',' + Host.ViewSubRankDesc."Entry No.".Value();
        Host.ViewSubRankDesc.Next();
        Seq += ',' + Host.ViewSubRankDesc."Entry No.".Value();
        Assert.AreEqual('2,3,1,4', Seq, 'the entry numbers the ViewSubRankDesc part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure PartSourceTableView_WithFilterOnlySubPageView_KeepsThePartsKey()
    // Part: sorting(Score). Control: where(Bucket = const('KEEP')), no sorting().
    // Score ascending over the KEEP rows; primary key order would be 1,3,4.
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.ViewSubWhere.First(), 'the part has a first row');
        Seq := Host.ViewSubWhere."Entry No.".Value();
        Host.ViewSubWhere.Next();
        Seq += ',' + Host.ViewSubWhere."Entry No.".Value();
        Host.ViewSubWhere.Next();
        Seq += ',' + Host.ViewSubWhere."Entry No.".Value();
        Assert.AreEqual('4,1,3', Seq, 'the entry numbers the ViewSubWhere part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure PartSourceTableViewDescending_NoSubPageView()
    // The control for the descending SourceTableView part: Score descending.
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.ViewDescNoSub.First(), 'the part has a first row');
        Seq := Host.ViewDescNoSub."Entry No.".Value();
        Host.ViewDescNoSub.Next();
        Seq += ',' + Host.ViewDescNoSub."Entry No.".Value();
        Host.ViewDescNoSub.Next();
        Seq += ',' + Host.ViewDescNoSub."Entry No.".Value();
        Host.ViewDescNoSub.Next();
        Seq += ',' + Host.ViewDescNoSub."Entry No.".Value();
        Assert.AreEqual('2,3,1,4', Seq, 'the entry numbers the ViewDescNoSub part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure PartSourceTableViewDescending_WithSubPageViewSorting_ThePartsViewWins()
    // Part: sorting(Score) order(descending). Control: sorting(Rank), no order().
    // The part's view names both halves and both win: Score descending.
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.ViewDescSubRank.First(), 'the part has a first row');
        Seq := Host.ViewDescSubRank."Entry No.".Value();
        Host.ViewDescSubRank.Next();
        Seq += ',' + Host.ViewDescSubRank."Entry No.".Value();
        Host.ViewDescSubRank.Next();
        Seq += ',' + Host.ViewDescSubRank."Entry No.".Value();
        Host.ViewDescSubRank.Next();
        Seq += ',' + Host.ViewDescSubRank."Entry No.".Value();
        Assert.AreEqual('2,3,1,4', Seq, 'the entry numbers the ViewDescSubRank part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure PartOnOpenPageSetCurrentKey_NoSubPageView()
    // The control for the OnOpenPage SetCurrentKey(Score) part: Score ascending.
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.KeyNoSub.First(), 'the part has a first row');
        Seq := Host.KeyNoSub."Entry No.".Value();
        Host.KeyNoSub.Next();
        Seq += ',' + Host.KeyNoSub."Entry No.".Value();
        Host.KeyNoSub.Next();
        Seq += ',' + Host.KeyNoSub."Entry No.".Value();
        Host.KeyNoSub.Next();
        Seq += ',' + Host.KeyNoSub."Entry No.".Value();
        Assert.AreEqual('4,1,3,2', Seq, 'the entry numbers the KeyNoSub part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure PartOnOpenPageSetCurrentKey_WithSubPageViewSorting_OnOpenPageWins()
    // Part: OnOpenPage SetCurrentKey(Score). Control: sorting(Rank). OnOpenPage runs after
    // the view is applied: Score ascending, not Rank ascending (2,4,1,3).
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.KeySubRank.First(), 'the part has a first row');
        Seq := Host.KeySubRank."Entry No.".Value();
        Host.KeySubRank.Next();
        Seq += ',' + Host.KeySubRank."Entry No.".Value();
        Host.KeySubRank.Next();
        Seq += ',' + Host.KeySubRank."Entry No.".Value();
        Host.KeySubRank.Next();
        Seq += ',' + Host.KeySubRank."Entry No.".Value();
        Assert.AreEqual('4,1,3,2', Seq, 'the entry numbers the KeySubRank part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure PartOnOpenPageSetAscending_NoSubPageView_ShowsAscending()
    // Part: OnOpenPage SetCurrentKey(Score) then SetAscending(Score, false). The part shows
    // Score ASCENDING, not descending (2,3,1,4): the per-field direction does not reach the
    // rows a part shows. See ListPageOnOpenPageSetAscending for a top-level page.
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.KeyDescNoSub.First(), 'the part has a first row');
        Seq := Host.KeyDescNoSub."Entry No.".Value();
        Host.KeyDescNoSub.Next();
        Seq += ',' + Host.KeyDescNoSub."Entry No.".Value();
        Host.KeyDescNoSub.Next();
        Seq += ',' + Host.KeyDescNoSub."Entry No.".Value();
        Host.KeyDescNoSub.Next();
        Seq += ',' + Host.KeyDescNoSub."Entry No.".Value();
        Assert.AreEqual('4,1,3,2', Seq, 'the entry numbers the KeyDescNoSub part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure PartOnOpenPageSetAscending_WithSubPageViewSorting()
    // Part: as KeyDescNoSub. Control: sorting(Rank). SetCurrentKey(Score) wins, and the
    // SetAscending is again not shown: Score ascending.
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.KeyDescSubRank.First(), 'the part has a first row');
        Seq := Host.KeyDescSubRank."Entry No.".Value();
        Host.KeyDescSubRank.Next();
        Seq += ',' + Host.KeyDescSubRank."Entry No.".Value();
        Host.KeyDescSubRank.Next();
        Seq += ',' + Host.KeyDescSubRank."Entry No.".Value();
        Host.KeyDescSubRank.Next();
        Seq += ',' + Host.KeyDescSubRank."Entry No.".Value();
        Assert.AreEqual('4,1,3,2', Seq, 'the entry numbers the KeyDescSubRank part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure PartOnOpenPageAscendingFalse_NoSubPageView()
    // The control for the OnOpenPage Ascending(false) part: primary key descending.
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.DescNoSub.First(), 'the part has a first row');
        Seq := Host.DescNoSub."Entry No.".Value();
        Host.DescNoSub.Next();
        Seq += ',' + Host.DescNoSub."Entry No.".Value();
        Host.DescNoSub.Next();
        Seq += ',' + Host.DescNoSub."Entry No.".Value();
        Host.DescNoSub.Next();
        Seq += ',' + Host.DescNoSub."Entry No.".Value();
        Assert.AreEqual('4,3,2,1', Seq, 'the entry numbers the DescNoSub part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure PartOnOpenPageAscendingFalse_WithSubPageViewSorting_KeyFromViewDirectionFromOnOpenPage()
    // Part: OnOpenPage Ascending(false), no key. Control: sorting(Rank). The view's key
    // survives and OnOpenPage's direction applies to it: Rank descending. Neither Rank
    // ascending (2,4,1,3) nor primary key descending (4,3,2,1).
    var
        Host: TestPage "SPO Host";
        Seq: Text;
    begin
        OpenHost(Host);

        Assert.IsTrue(Host.DescSubRank.First(), 'the part has a first row');
        Seq := Host.DescSubRank."Entry No.".Value();
        Host.DescSubRank.Next();
        Seq += ',' + Host.DescSubRank."Entry No.".Value();
        Host.DescSubRank.Next();
        Seq += ',' + Host.DescSubRank."Entry No.".Value();
        Host.DescSubRank.Next();
        Seq += ',' + Host.DescSubRank."Entry No.".Value();
        Assert.AreEqual('3,1,4,2', Seq, 'the entry numbers the DescSubRank part shows, in order');

        Host.Close();
    end;

    [Test]
    procedure ListPageOnOpenPageAscendingFalse_ShowsDescending()
    // The control for the next arm, on a top-level list page: OnOpenPage SetCurrentKey(Score)
    // then Ascending(false) shows Score descending.
    var
        ListPage: TestPage "SPO Key Asc False List";
        Seq: Text;
    begin
        Seed();
        ListPage.OpenView();

        Assert.IsTrue(ListPage.First(), 'the list has a first row');
        Seq := ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        Assert.AreEqual('2,3,1,4', Seq, 'the entry numbers the list page shows, in order');

        ListPage.Close();
    end;

    [Test]
    procedure ListPageOnOpenPageSetAscending()
    // The same question as the KeyDesc part arms, on a top-level list page: OnOpenPage
    // SetCurrentKey(Score) then SetAscending(Score, false). Score descending is 2,3,1,4.
    var
        ListPage: TestPage "SPO Key Desc List";
        Seq: Text;
    begin
        Seed();
        ListPage.OpenView();

        Assert.IsTrue(ListPage.First(), 'the list has a first row');
        Seq := ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        Assert.AreEqual('4,1,3,2', Seq, 'the entry numbers the list page shows, in order');

        ListPage.Close();
    end;
}
