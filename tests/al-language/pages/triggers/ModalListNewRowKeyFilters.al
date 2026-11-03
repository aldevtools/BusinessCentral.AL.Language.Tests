// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: LT MLK Ref (70371), LT MLK List (70372)
//
// Does the blank new-row line of an editable list opened with Page.RunModal(PageId, Rec) survive
// equality filters on two key fields (shape of "Item Reference List": Reference Type + Reference
// Type No.), a filter on a non-key field, a range, an empty result, and TestPage.Filter.SetFilter
// called by the handler before it loops with Next()? Plain list control:
// handlers/TestPageModalNewRowLine_Tests.al.
//
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 70371 "LT MLK Ref"
{
    DataClassification = CustomerContent;
    LookupPageId = "LT MLK List";

    fields
    {
        field(1; "Ref Type"; Integer) { }
        field(2; "Ref No."; Code[20]) { }
        field(3; "Item No."; Code[20]) { }
        field(4; Active; Boolean) { }
        field(5; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; "Ref Type", "Ref No.", "Item No.") { Clustered = true; }
    }
}

page 70372 "LT MLK List"
{
    PageType = List;
    SourceTable = "LT MLK Ref";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RefType; Rec."Ref Type") { ApplicationArea = All; }
                field(RefNo; Rec."Ref No.") { ApplicationArea = All; }
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 70373 "LT MLK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Text;
        Rows: Integer;
        FirstResult: Boolean;
        AfterWalkNext: Boolean;
        FilterToApply: Text;

    local procedure Seed()
    begin
        Seen := '';
        Rows := 0;
        FilterToApply := '';
        Clear(FirstResult);
        Clear(AfterWalkNext);
        Add(1, 'R1', 'I1', true);
        Add(1, 'R1', 'I2', false);
        Add(1, 'R1', 'I3', true);
        Add(1, 'R2', 'I1', true);
        Add(2, 'R1', 'I1', false);
        Add(2, 'R2', 'I4', true);
    end;

    local procedure Add(RefType: Integer; RefNo: Code[20]; ItemNo: Code[20]; IsActive: Boolean)
    var
        Ref: Record "LT MLK Ref";
    begin
        Ref.Init();
        Ref."Ref Type" := RefType;
        Ref."Ref No." := RefNo;
        Ref."Item No." := ItemNo;
        Ref.Active := IsActive;
        Ref.Descr := 'D' + Format(RefType) + RefNo + ItemNo;
        Ref.Insert();
    end;

    local procedure Reset()
    var
        Ref: Record "LT MLK Ref";
    begin
        Ref.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_NoFilter_RunModalById()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('firstResult', Format(FirstResult));
        Observer.Observe('nextAfterWalk', Format(AfterWalkNext));
        Observer.Expect('seen', '[1/R1/I1/Yes/D1R1I1][1/R1/I2/No/D1R1I2][1/R1/I3/Yes/D1R1I3][1/R2/I1/Yes/D1R2I1][2/R1/I1/No/D2R1I1][2/R2/I4/Yes/D2R2I4][0///No/]');
        Observer.Expect('rows', '7');
        Observer.Expect('firstResult', 'Yes');
        Observer.Expect('nextAfterWalk', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_NoFilter_RunModalZero()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Page.RunModal(0, Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[1/R1/I1/Yes/D1R1I1][1/R1/I2/No/D1R1I2][1/R1/I3/Yes/D1R1I3][1/R2/I1/Yes/D1R2I1][2/R1/I1/No/D2R1I1][2/R2/I4/Yes/D2R2I4][0///No/]');
        Observer.Expect('rows', '7');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_TwoKeyEqualityFilters_RunModalById()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Ref.SetRange("Ref Type", 1);
        Ref.SetRange("Ref No.", 'R1');
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('firstResult', Format(FirstResult));
        Observer.Observe('nextAfterWalk', Format(AfterWalkNext));
        Observer.Expect('seen', '[1/R1/I1/Yes/D1R1I1][1/R1/I2/No/D1R1I2][1/R1/I3/Yes/D1R1I3][1/R1//No/]');
        Observer.Expect('rows', '4');
        Observer.Expect('firstResult', 'Yes');
        Observer.Expect('nextAfterWalk', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_TwoKeyEqualityFilters_RunModalZero()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Ref.SetRange("Ref Type", 1);
        Ref.SetRange("Ref No.", 'R1');
        Page.RunModal(0, Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[1/R1/I1/Yes/D1R1I1][1/R1/I2/No/D1R1I2][1/R1/I3/Yes/D1R1I3][1/R1//No/]');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_TwoKeyFiltersWithSetFilterText()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Ref.SetFilter("Ref Type", '1');
        Ref.SetFilter("Ref No.", 'R1');
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[1/R1/I1/Yes/D1R1I1][1/R1/I2/No/D1R1I2][1/R1/I3/Yes/D1R1I3][1/R1//No/]');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_ThreeKeyEqualityFilters()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Ref.SetRange("Ref Type", 1);
        Ref.SetRange("Ref No.", 'R1');
        Ref.SetRange("Item No.", 'I3');
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[1/R1/I3/Yes/D1R1I3][1/R1/I3/No/]');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_OneKeyEqualityFilter()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Ref.SetRange("Ref Type", 2);
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[2/R1/I1/No/D2R1I1][2/R2/I4/Yes/D2R2I4][2///No/]');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_KeyRangeFilter()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Ref.SetRange("Ref Type", 1, 2);
        Ref.SetRange("Ref No.", 'R2');
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[1/R2/I1/Yes/D1R2I1][2/R2/I4/Yes/D2R2I4][0/R2//No/]');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_NonKeyFilter()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Ref.SetRange(Active, true);
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[1/R1/I1/Yes/D1R1I1][1/R1/I3/Yes/D1R1I3][1/R2/I1/Yes/D1R2I1][2/R2/I4/Yes/D2R2I4][0///No/]');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_TwoKeyFiltersAndNonKeyFilter()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Ref.SetRange("Ref Type", 1);
        Ref.SetRange("Ref No.", 'R1');
        Ref.SetRange(Active, true);
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[1/R1/I1/Yes/D1R1I1][1/R1/I3/Yes/D1R1I3][1/R1//No/]');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_FilterMatchesNoRow()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Ref.SetRange("Ref Type", 9);
        Ref.SetRange("Ref No.", 'R9');
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('firstResult', Format(FirstResult));
        Observer.Observe('nextAfterWalk', Format(AfterWalkNext));
        Observer.Expect('seen', '');
        Observer.Expect('rows', '0');
        Observer.Expect('firstResult', 'No');
        Observer.Expect('nextAfterWalk', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_NoRowsAtAll_NoFilter()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seen := '';
        Rows := 0;
        Clear(FirstResult);
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('firstResult', Format(FirstResult));
        Observer.Expect('seen', '');
        Observer.Expect('rows', '0');
        Observer.Expect('firstResult', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('FilterThenWalkHandler')]
    procedure P157_HandlerSetFilter_NoRecFilters()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        FilterToApply := 'true';
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[1/R1/I1/Yes/D1R1I1][1/R1/I2/No/D1R1I2][1/R1/I3/Yes/D1R1I3][1/R2/I1/Yes/D1R2I1][2/R1/I1/No/D2R1I1][2/R2/I4/Yes/D2R2I4][0///No/]');
        Observer.Expect('rows', '7');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('FilterThenWalkHandler')]
    procedure P157_HandlerSetFilter_WithTwoKeyFilters()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        FilterToApply := 'true';
        Ref.SetRange("Ref Type", 1);
        Ref.SetRange("Ref No.", 'R1');
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[1/R1/I1/Yes/D1R1I1][1/R1/I2/No/D1R1I2][1/R1/I3/Yes/D1R1I3][1/R1//No/]');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('FilterThenWalkHandler')]
    procedure P157_HandlerSetFilter_MatchesNothing()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        FilterToApply := 'false';
        Ref.SetRange("Ref Type", 2);
        Ref.SetRange("Ref No.", 'R2');
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('firstResult', Format(FirstResult));
        Observer.Expect('seen', '[2/R2/I4/Yes/D2R2I4][2/R2//No/]');
        Observer.Expect('rows', '2');
        Observer.Expect('firstResult', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('FilterThenWalkHandler')]
    procedure P157_HandlerSetFilter_NonKeyRecFilter()
    var
        Ref: Record "LT MLK Ref";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        FilterToApply := 'false';
        Ref.SetRange(Active, true);
        Page.RunModal(Page::"LT MLK List", Ref);
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[1/R1/I1/Yes/D1R1I1][1/R1/I3/Yes/D1R1I3][1/R2/I1/Yes/D1R2I1][2/R2/I4/Yes/D2R2I4][0///No/]');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure P157_PageVariable_TwoKeyFilters_SetTableView()
    var
        Ref: Record "LT MLK Ref";
        ListPage: Page "LT MLK List";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Seed();
        Ref.SetRange("Ref Type", 1);
        Ref.SetRange("Ref No.", 'R1');
        ListPage.SetTableView(Ref);
        ListPage.RunModal();
        Observer.Observe('seen', Seen);
        Observer.Observe('rows', Format(Rows));
        Observer.Expect('seen', '[1/R1/I1/Yes/D1R1I1][1/R1/I2/No/D1R1I2][1/R1/I3/Yes/D1R1I3][1/R1//No/]');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure WalkHandler(var TP: TestPage "LT MLK List")
    begin
        Walk(TP);
    end;

    [ModalPageHandler]
    procedure FilterThenWalkHandler(var TP: TestPage "LT MLK List")
    begin
        TP.Filter.SetFilter(Active, FilterToApply);
        Walk(TP);
    end;

    local procedure Walk(var TP: TestPage "LT MLK List")
    begin
        FirstResult := TP.First();
        if FirstResult then
            repeat
                Rows += 1;
                Seen += '[' + TP.RefType.Value() + '/' + TP.RefNo.Value() + '/' + TP.ItemNo.Value() + '/' + TP.Active.Value() + '/' + TP.Descr.Value() + ']';
            until not TP.Next();
        AfterWalkNext := TP.Next();
    end;
}
