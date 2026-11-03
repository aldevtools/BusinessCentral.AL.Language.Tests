// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-setselectionfilter-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-getrecord-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68400, codeunit 68401 (log), pages 68402,
//                68404, 68405, page extension 68403, codeunit 68406 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins:
//  - OnQueryClosePage of a page and of its page extension both run, base first and then the extension,
//    whatever the base answers (a false from the base does not stop the extension). The page closes (its
//    OnClosePage runs, base then extension) only when both answer true; with one false neither
//    OnClosePage runs. TestPage.Close() then raises nothing. CloseAction is OK.
//  - CurrPage.SetSelectionFilter(Rec) on a list page positioned by a TestPage on row 2 filters the record
//    to that row: "Id: 2", one record.
//  - Page.GetRecord(Rec) after RunModal gives the row the page was positioned on when it closed: the
//    picked row after OK (LookupOK), and the last positioned row after Cancel (LookupCancel) too.
//  - "Page Metadata"."CardPageID" is the id the page states in CardPageId, and 0 when it states none.
// BC versions: 27.5

table 68400 "Probe Close Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68401 "Probe Close Log"
{
    SingleInstance = true;

    var
        Log: Text;
        BaseResult: Boolean;
        ExtResult: Boolean;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    procedure SetResults(BaseAnswer: Boolean; ExtAnswer: Boolean)
    begin
        BaseResult := BaseAnswer;
        ExtResult := ExtAnswer;
    end;

    procedure BaseAnswers(): Boolean
    begin
        exit(BaseResult);
    end;

    procedure ExtAnswers(): Boolean
    begin
        exit(ExtResult);
    end;
}

page 68402 "Probe Close Card"
{
    PageType = Card;
    SourceTable = "Probe Close Table";
    ApplicationArea = All;
    UsageCategory = None;
    CardPageId = "Probe Close Card";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CloseLog: Codeunit "Probe Close Log";
    begin
        CloseLog.Add('base QueryClose ' + Format(CloseAction));
        exit(CloseLog.BaseAnswers());
    end;

    trigger OnClosePage()
    var
        CloseLog: Codeunit "Probe Close Log";
    begin
        CloseLog.Add('base Close');
    end;
}

pageextension 68403 "Probe Close Card Ext" extends "Probe Close Card"
{
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CloseLog: Codeunit "Probe Close Log";
    begin
        CloseLog.Add('ext QueryClose ' + Format(CloseAction));
        exit(CloseLog.ExtAnswers());
    end;

    trigger OnClosePage()
    var
        CloseLog: Codeunit "Probe Close Log";
    begin
        CloseLog.Add('ext Close');
    end;
}

page 68404 "Probe Close List"
{
    PageType = List;
    SourceTable = "Probe Close Table";
    ApplicationArea = All;
    UsageCategory = None;
    CardPageId = "Probe Close Card";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectionFilter)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Selected: Record "Probe Close Table";
                    CloseLog: Codeunit "Probe Close Log";
                begin
                    CurrPage.SetSelectionFilter(Selected);
                    CloseLog.Add('filters=[' + Selected.GetFilters() + '] count=' + Format(Selected.Count()));
                end;
            }
        }
    }
}

page 68405 "Probe Close Plain List"
{
    PageType = List;
    SourceTable = "Probe Close Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 68406 "Probe Page Close Selection"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CloseLog: Codeunit "Probe Close Log";

    local procedure Seed()
    var
        CloseRec: Record "Probe Close Table";
    begin
        CloseRec.DeleteAll();
        CloseRec.Id := 1;
        CloseRec.Txt := 'a';
        CloseRec.Insert();
        CloseRec.Id := 2;
        CloseRec.Txt := 'b';
        CloseRec.Insert();
        CloseRec.Id := 3;
        CloseRec.Txt := 'c';
        CloseRec.Insert();
        Commit();
        CloseLog.Take();
    end;

    local procedure CloseWith(BaseAnswer: Boolean; ExtAnswer: Boolean): Text
    var
        Card: TestPage "Probe Close Card";
    begin
        CloseLog.SetResults(BaseAnswer, ExtAnswer);
        CloseLog.Take();
        Card.OpenView();
        Card.Close();
        exit(CloseLog.Take());
    end;

    [Test]
    procedure OnQueryClosePage_PageAndExtension_BothRun_AndBothMustAgreeToClose()
    begin
        Seed();

        Assert.AreEqual('base QueryClose OK;ext QueryClose OK;base Close;ext Close;', CloseWith(true, true), 'both true');
        Assert.AreEqual('base QueryClose OK;ext QueryClose OK;', CloseWith(false, true), 'base false, extension true');
        Assert.AreEqual('base QueryClose OK;ext QueryClose OK;', CloseWith(true, false), 'base true, extension false');
        Assert.AreEqual('base QueryClose OK;ext QueryClose OK;', CloseWith(false, false), 'both false');
    end;

    [Test]
    procedure SetSelectionFilter_OnAListPositionedOnARow_FiltersToThatRow()
    var
        List: TestPage "Probe Close List";
    begin
        Seed();

        List.OpenView();
        List.GoToKey(2);
        List.SelectionFilter.Invoke();

        Assert.AreEqual('filters=[Id: 2] count=1;', CloseLog.Take(), 'selection filter');
        List.Close();
    end;

    [ModalPageHandler]
    procedure PickRowTwoHandler(var PickPage: TestPage "Probe Close Plain List")
    begin
        PickPage.GoToKey(2);
        PickPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelOnRowThreeHandler(var PickPage: TestPage "Probe Close Plain List")
    begin
        PickPage.GoToKey(3);
        PickPage.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('PickRowTwoHandler')]
    procedure GetRecord_AfterOk_IsThePickedRow()
    var
        PlainPage: Page "Probe Close Plain List";
        Picked: Record "Probe Close Table";
        Result: Action;
    begin
        Seed();

        PlainPage.LookupMode(true);
        Result := PlainPage.RunModal();
        PlainPage.GetRecord(Picked);

        Assert.AreEqual(Action::LookupOK, Result, 'result');
        Assert.AreEqual(2, Picked.Id, 'id');
        Assert.AreEqual('b', Picked.Txt, 'text');
        Assert.AreEqual('', Picked.GetFilters(), 'no filters');
    end;

    [Test]
    [HandlerFunctions('CancelOnRowThreeHandler')]
    procedure GetRecord_AfterCancel_IsTheLastPositionedRow()
    var
        PlainPage: Page "Probe Close Plain List";
        Picked: Record "Probe Close Table";
        Result: Action;
    begin
        Seed();

        PlainPage.LookupMode(true);
        Result := PlainPage.RunModal();
        PlainPage.GetRecord(Picked);

        Assert.AreEqual(Action::LookupCancel, Result, 'result');
        Assert.AreEqual(3, Picked.Id, 'the row the handler had moved to');
    end;

    [Test]
    procedure PageMetadata_CardPageId_IsTheStatedPageOrZero()
    var
        PageMeta: Record "Page Metadata";
    begin
        PageMeta.Get(Page::"Probe Close List");
        Assert.AreEqual(Page::"Probe Close Card", PageMeta.CardPageID, 'list with CardPageId');
        PageMeta.Get(Page::"Probe Close Card");
        Assert.AreEqual(Page::"Probe Close Card", PageMeta.CardPageID, 'card naming itself');
        PageMeta.Get(Page::"Probe Close Plain List");
        Assert.AreEqual(0, PageMeta.CardPageID, 'page without CardPageId');
    end;
}
