// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setascending-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-ascending-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-trap-method
// Scope: in-scope
// Fixtures used: SPR Row (67961), SPR Key Desc List (67961), SPR Key Asc False List (67962),
//   SPR Action List (67963), SPR Probe (67961), Assert (60021)
//
/// <summary>
/// Which order a list page's rows show after a per-field SetAscending, on the routes the
/// sibling file TestPartOwnSortVsSubPageView.al (67950 "SPO Tests") does not measure. Written
/// for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#5000.
///
/// 67950 pins that OnOpenPage `SetCurrentKey(Score); SetAscending(Score, false)` is not shown
/// in the rows of a page the TestPage opens itself, while `Ascending(false)` is. This file
/// asks the same question of:
///
///   - a page opened by Page.RunModal under a [ModalPageHandler],
///   - a page opened by Page.Run under a [PageHandler],
///   - a page opened by Page.Run and caught by TestPage.Trap(),
///   - a per-field SetAscending made by an action's OnAction, read by the TestPage afterwards
///     and by a second action,
///   - the row a page opens on, read before any First().
///
/// Each route has an Ascending(false) control, which must show the descending order, so a
/// route that shows no sort at all cannot pass both arms.
///
///     Entry No.  Score
///         1       200
///         2       400
///         3       300
///         4       100
///
///     PK asc 1,2,3,4   Score asc 4,1,3,2   Score desc 2,3,1,4
/// </summary>

table 67961 "SPR Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Score; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByScore; Score) { }
    }
}

page 67961 "SPR Key Desc List"
{
    PageType = List;
    SourceTable = "SPR Row";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'SPR Key Desc List';
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

page 67962 "SPR Key Asc False List"
{
    PageType = List;
    SourceTable = "SPR Row";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'SPR Key Asc False List';
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

page 67963 "SPR Action List"
{
    PageType = List;
    SourceTable = "SPR Row";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'SPR Action List';
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

    actions
    {
        area(Processing)
        {
            action(SortPerField)
            {
                ApplicationArea = All;
                Caption = 'Sort per field';

                trigger OnAction()
                begin
                    Rec.SetCurrentKey(Score);
                    Rec.SetAscending(Score, false);
                end;
            }
            action(SortDescending)
            {
                ApplicationArea = All;
                Caption = 'Sort descending';

                trigger OnAction()
                begin
                    Rec.SetCurrentKey(Score);
                    Rec.Ascending(false);
                end;
            }
            action(SortPerFieldAndRead)
            {
                ApplicationArea = All;
                Caption = 'Sort per field and read';

                trigger OnAction()
                var
                    Probe: Codeunit "SPR Probe";
                begin
                    Rec.SetCurrentKey(Score);
                    Rec.SetAscending(Score, false);
                    if Rec.FindFirst() then
                        Probe.SetEntryNo(Rec."Entry No.");
                end;
            }
            action(ReadFirst)
            {
                ApplicationArea = All;
                Caption = 'Read first';

                trigger OnAction()
                var
                    Probe: Codeunit "SPR Probe";
                begin
                    if Rec.FindFirst() then
                        Probe.SetEntryNo(Rec."Entry No.");
                end;
            }
        }
    }
}

codeunit 67961 "SPR Probe"
{
    SingleInstance = true;

    var
        EntryNo: Integer;

    procedure SetEntryNo(NewEntryNo: Integer)
    begin
        EntryNo := NewEntryNo;
    end;

    procedure GetEntryNo(): Integer
    begin
        exit(EntryNo);
    end;
}

codeunit 67962 "SPR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        HandlerSeq: Text;

    local procedure Seed()
    var
        Row: Record "SPR Row";
        Probe: Codeunit "SPR Probe";
    begin
        Row.DeleteAll();
        AddRow(1, 200);
        AddRow(2, 400);
        AddRow(3, 300);
        AddRow(4, 100);
        Probe.SetEntryNo(0);
        HandlerSeq := '';
    end;

    local procedure AddRow(EntryNo: Integer; NewScore: Integer)
    var
        Row: Record "SPR Row";
    begin
        Row.Init();
        Row."Entry No." := EntryNo;
        Row.Score := NewScore;
        Row.Insert();
    end;

    // ---- Page.RunModal under a [ModalPageHandler] ----

    [Test]
    [HandlerFunctions('KeyDescModalHandler')]
    procedure ModalHandler_OnOpenPageSetAscending()
    // OnOpenPage SetCurrentKey(Score) then SetAscending(Score, false), the page opened by
    // Page.RunModal and read by the handler.
    begin
        Seed();
        Page.RunModal(Page::"SPR Key Desc List");
        Assert.AreEqual('4,1,3,2', HandlerSeq, 'the entry numbers the modal page shows, in order');
    end;

    [Test]
    [HandlerFunctions('KeyAscFalseModalHandler')]
    procedure ModalHandler_OnOpenPageAscendingFalse_ShowsDescending()
    // The control: OnOpenPage SetCurrentKey(Score) then Ascending(false).
    begin
        Seed();
        Page.RunModal(Page::"SPR Key Asc False List");
        Assert.AreEqual('2,3,1,4', HandlerSeq, 'the entry numbers the modal page shows, in order');
    end;

    [ModalPageHandler]
    procedure KeyDescModalHandler(var ListPage: TestPage "SPR Key Desc List")
    begin
        Assert.IsTrue(ListPage.First(), 'the list has a first row');
        HandlerSeq := ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
    end;

    [ModalPageHandler]
    procedure KeyAscFalseModalHandler(var ListPage: TestPage "SPR Key Asc False List")
    begin
        Assert.IsTrue(ListPage.First(), 'the list has a first row');
        HandlerSeq := ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
    end;

    // ---- Page.Run under a [PageHandler] ----

    [Test]
    [HandlerFunctions('KeyDescPageHandler')]
    procedure PageHandler_OnOpenPageSetAscending()
    begin
        Seed();
        Page.Run(Page::"SPR Key Desc List");
        Assert.AreEqual('4,1,3,2', HandlerSeq, 'the entry numbers the page shows, in order');
    end;

    [Test]
    [HandlerFunctions('KeyAscFalsePageHandler')]
    procedure PageHandler_OnOpenPageAscendingFalse_ShowsDescending()
    begin
        Seed();
        Page.Run(Page::"SPR Key Asc False List");
        Assert.AreEqual('2,3,1,4', HandlerSeq, 'the entry numbers the page shows, in order');
    end;

    [PageHandler]
    procedure KeyDescPageHandler(var ListPage: TestPage "SPR Key Desc List")
    begin
        Assert.IsTrue(ListPage.First(), 'the list has a first row');
        HandlerSeq := ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
    end;

    [PageHandler]
    procedure KeyAscFalsePageHandler(var ListPage: TestPage "SPR Key Asc False List")
    begin
        Assert.IsTrue(ListPage.First(), 'the list has a first row');
        HandlerSeq := ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        HandlerSeq += ',' + ListPage."Entry No.".Value();
    end;

    // ---- Page.Run caught by TestPage.Trap() ----

    [Test]
    procedure Trap_OnOpenPageSetAscending()
    var
        ListPage: TestPage "SPR Key Desc List";
        Seq: Text;
    begin
        Seed();
        ListPage.Trap();
        Page.Run(Page::"SPR Key Desc List");

        Assert.IsTrue(ListPage.First(), 'the list has a first row');
        Seq := ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        Assert.AreEqual('4,1,3,2', Seq, 'the entry numbers the trapped page shows, in order');

        ListPage.Close();
    end;

    [Test]
    procedure Trap_OnOpenPageAscendingFalse_ShowsDescending()
    var
        ListPage: TestPage "SPR Key Asc False List";
        Seq: Text;
    begin
        Seed();
        ListPage.Trap();
        Page.Run(Page::"SPR Key Asc False List");

        Assert.IsTrue(ListPage.First(), 'the list has a first row');
        Seq := ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        Assert.AreEqual('2,3,1,4', Seq, 'the entry numbers the trapped page shows, in order');

        ListPage.Close();
    end;

    // ---- a per-field SetAscending made by an action ----

    [Test]
    procedure Action_SetAscending_ThenTestPageReadsRows()
    // The action runs SetCurrentKey(Score) then SetAscending(Score, false); the TestPage
    // reads the rows after Invoke().
    var
        ListPage: TestPage "SPR Action List";
        Seq: Text;
    begin
        Seed();
        ListPage.OpenView();
        ListPage.SortPerField.Invoke();

        Assert.IsTrue(ListPage.First(), 'the list has a first row');
        Seq := ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        Assert.AreEqual('4,1,3,2', Seq, 'the entry numbers the list shows after the action, in order');

        ListPage.Close();
    end;

    [Test]
    procedure Action_AscendingFalse_ThenTestPageReadsRows_ShowsDescending()
    // The control: the action runs SetCurrentKey(Score) then Ascending(false).
    var
        ListPage: TestPage "SPR Action List";
        Seq: Text;
    begin
        Seed();
        ListPage.OpenView();
        ListPage.SortDescending.Invoke();

        Assert.IsTrue(ListPage.First(), 'the list has a first row');
        Seq := ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        ListPage.Next();
        Seq += ',' + ListPage."Entry No.".Value();
        Assert.AreEqual('2,3,1,4', Seq, 'the entry numbers the list shows after the action, in order');

        ListPage.Close();
    end;

    [Test]
    procedure Action_SetAscending_ReadInTheSameTrigger_IsDescending()
    // Inside the trigger that set it, the per-field direction holds: FindFirst on Score
    // descending is entry 2.
    var
        ListPage: TestPage "SPR Action List";
        Probe: Codeunit "SPR Probe";
    begin
        Seed();
        ListPage.OpenView();
        ListPage.SortPerFieldAndRead.Invoke();

        Assert.AreEqual(2, Probe.GetEntryNo(), 'the entry FindFirst returned in the action that set the order');

        ListPage.Close();
    end;

    [Test]
    procedure Action_SetAscending_ReadByALaterAction()
    // One action sets the per-field direction, a second action runs Rec.FindFirst().
    var
        ListPage: TestPage "SPR Action List";
        Probe: Codeunit "SPR Probe";
    begin
        Seed();
        ListPage.OpenView();
        ListPage.SortPerField.Invoke();
        ListPage.ReadFirst.Invoke();

        Assert.AreEqual(4, Probe.GetEntryNo(), 'the entry FindFirst returned in the later action');

        ListPage.Close();
    end;

    [Test]
    procedure Action_AscendingFalse_ReadByALaterAction_IsDescending()
    // The control: Ascending(false) in the first action.
    var
        ListPage: TestPage "SPR Action List";
        Probe: Codeunit "SPR Probe";
    begin
        Seed();
        ListPage.OpenView();
        ListPage.SortDescending.Invoke();
        ListPage.ReadFirst.Invoke();

        Assert.AreEqual(2, Probe.GetEntryNo(), 'the entry FindFirst returned in the later action');

        ListPage.Close();
    end;

    // ---- the row a page opens on, before any First() ----

    [Test]
    procedure OpenView_CurrentRow_OnOpenPageSetAscending()
    var
        ListPage: TestPage "SPR Key Desc List";
    begin
        Seed();
        ListPage.OpenView();

        Assert.AreEqual('4', ListPage."Entry No.".Value(), 'the entry number of the row the page opens on');

        ListPage.Close();
    end;

    [Test]
    procedure OpenView_CurrentRow_OnOpenPageAscendingFalse()
    var
        ListPage: TestPage "SPR Key Asc False List";
    begin
        Seed();
        ListPage.OpenView();

        Assert.AreEqual('2', ListPage."Entry No.".Value(), 'the entry number of the row the page opens on');

        ListPage.Close();
    end;
}
