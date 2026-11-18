// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-setselectionfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); shared table 50006 "ALT Shape 06", page 74871, store 74791, test codeunit 74892
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: CurrPage.SetSelectionFilter(Sel) from a procedure of a list page, called by a typed modal handler, in these states:
//   (1) no current row: the page view is filtered to nothing while the table has rows; (2) called in OnOpenPage, before a row is current;
//   (3) the same call from a typed handler (the page shows no positioned row there) and, for contrast, from an action of a TestPage positioned on a row; and the marks of Sel before the call: (4) marks without MarkedOnly, (5) MarkedOnly(true) without marks,
//   (6) a mark on the selected row, (7) a mark on another row with MarkedOnly(true). After each: row count, GetFilters, MarkedOnly, the Id of the page's current row.
// BC versions: all (CI)

codeunit 74791 "LT SSN Store"
{
    SingleInstance = true;

    var
        Kept: Record "ALT Shape 06";

    procedure Keep(var Sel: Record "ALT Shape 06")
    begin
        Kept.Copy(Sel);
    end;

    procedure Get(var Sel: Record "ALT Shape 06")
    begin
        Sel.Copy(Kept);
    end;
}

page 74871 "LT SSN List"
{
    PageType = List;
    SourceTable = "ALT Shape 06";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CaptureAction)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Store: Codeunit "LT SSN Store";
                    LocalSel: Record "ALT Shape 06";
                begin
                    CurrPage.SetSelectionFilter(LocalSel);
                    Store.Keep(LocalSel);
                end;
            }
        }
    }

    var
        CaptureOnOpen: Boolean;
        OpenSel: Record "ALT Shape 06";

    procedure SetCaptureOnOpen(NewValue: Boolean)
    begin
        CaptureOnOpen := NewValue;
    end;

    procedure Capture(var Sel: Record "ALT Shape 06")
    begin
        CurrPage.SetSelectionFilter(Sel);
    end;

    procedure GetOpenSel(var Sel: Record "ALT Shape 06")
    begin
        Sel.Copy(OpenSel);
    end;

    procedure CurrentId(): Integer
    begin
        exit(Rec.Id);
    end;

    trigger OnOpenPage()
    begin
        if CaptureOnOpen then
            CurrPage.SetSelectionFilter(OpenSel);
    end;
}

codeunit 74892 "LT SSN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Sel: Record "ALT Shape 06";
        Obs: Codeunit "Probe Observer";
        Current: Integer;

    local procedure Seed()
    var
        Row: Record "ALT Shape 06";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 5 do begin
            Row.Id := i;
            Row.Name := 'row' + Format(i);
            Row.Insert();
        end;
        Sel.Reset();
        Sel.ClearMarks();
    end;

    local procedure Describe(Prefix: Text; var Rec2: Record "ALT Shape 06")
    begin
        Obs.Observe(Prefix + 'Count', Format(Rec2.Count()));
        Obs.Observe(Prefix + 'Filters', Rec2.GetFilters());
        Obs.Observe(Prefix + 'MarkedOnly', Format(Rec2.MarkedOnly()));
        Obs.Observe(Prefix + 'HasFilter', Format(Rec2.HasFilter()));
    end;

    local procedure MarkIds(Ids: Text)
    var
        Part: Text;
        Id: Integer;
    begin
        foreach Part in Ids.Split(',') do begin
            Evaluate(Id, Part);
            Sel.Get(Id);
            Sel.Mark(true);
        end;
    end;

    [ModalPageHandler]
    procedure CaptureHandler(var P: Page "LT SSN List"; var Response: Action)
    begin
        Current := P.CurrentId();
        P.Capture(Sel);
        Response := Action::Cancel;
    end;

    [ModalPageHandler]
    procedure PlainHandler(var P: Page "LT SSN List"; var Response: Action)
    begin
        Current := P.CurrentId();
        Response := Action::Cancel;
    end;

    [Test]
    [HandlerFunctions('CaptureHandler')]
    procedure NoCurrentRow_FilteredToNothing()
    var
        View: Record "ALT Shape 06";
        P: Page "LT SSN List";
    begin
        Seed();
        View.SetRange(Id, 99);
        P.SetTableView(View);
        P.RunModal();
        Obs.Observe('currentId', Format(Current));
        Describe('', Sel);
        Obs.Expect('currentId', '0');
        Obs.Expect('Count', '0');
        Obs.Expect('Filters', 'Id: 0');
        Obs.Expect('MarkedOnly', 'No');
        Obs.Expect('HasFilter', 'Yes');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure CalledInOnOpenPage()
    var
        View: Record "ALT Shape 06";
        OpenResult: Record "ALT Shape 06";
        P: Page "LT SSN List";
    begin
        Seed();
        P.SetCaptureOnOpen(true);
        P.RunModal();
        P.GetOpenSel(OpenResult);
        Obs.Observe('currentId', Format(Current));
        Describe('', OpenResult);
        Obs.Expect('currentId', '0');
        Obs.Expect('Count', '5');
        Obs.Expect('Filters', '');
        Obs.Expect('MarkedOnly', 'No');
        Obs.Expect('HasFilter', 'No');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('CaptureHandler')]
    procedure HandlerOpened_NoRowPositioned()
    var
        P: Page "LT SSN List";
    begin
        Seed();
        P.RunModal();
        Obs.Observe('currentId', Format(Current));
        Describe('', Sel);
        Obs.Expect('currentId', '0');
        Obs.Expect('Count', '0');
        Obs.Expect('Filters', 'Id: 0');
        Obs.Expect('MarkedOnly', 'No');
        Obs.Expect('HasFilter', 'Yes');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('CaptureHandler')]
    procedure Marks_WithoutMarkedOnly()
    var
        P: Page "LT SSN List";
    begin
        Seed();
        MarkIds('3,4');
        Obs.Observe('beforeMarkedOnly', Format(Sel.MarkedOnly()));
        P.RunModal();
        Obs.Observe('currentId', Format(Current));
        Describe('', Sel);
        Sel.MarkedOnly(true);
        Obs.Observe('markedCountAfter', Format(Sel.Count()));
        Obs.Expect('beforeMarkedOnly', 'No');
        Obs.Expect('currentId', '0');
        Obs.Expect('Count', '0');
        Obs.Expect('Filters', 'Id: 0');
        Obs.Expect('MarkedOnly', 'No');
        Obs.Expect('HasFilter', 'Yes');
        Obs.Expect('markedCountAfter', '0');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('CaptureHandler')]
    procedure MarkedOnly_WithoutMarks()
    var
        P: Page "LT SSN List";
    begin
        Seed();
        Sel.MarkedOnly(true);
        Obs.Observe('beforeCount', Format(Sel.Count()));
        P.RunModal();
        Obs.Observe('currentId', Format(Current));
        Describe('', Sel);
        Obs.Expect('beforeCount', '0');
        Obs.Expect('currentId', '0');
        Obs.Expect('Count', '0');
        Obs.Expect('Filters', 'Marked: Yes, Id: 0');
        Obs.Expect('MarkedOnly', 'Yes');
        Obs.Expect('HasFilter', 'Yes');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('CaptureHandler')]
    procedure Mark_OnSelectedRow()
    var
        P: Page "LT SSN List";
    begin
        Seed();
        MarkIds('1');
        P.RunModal();
        Obs.Observe('currentId', Format(Current));
        Describe('', Sel);
        Obs.Expect('currentId', '0');
        Obs.Expect('Count', '0');
        Obs.Expect('Filters', 'Id: 0');
        Obs.Expect('MarkedOnly', 'No');
        Obs.Expect('HasFilter', 'Yes');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('CaptureHandler')]
    procedure MarkedOnly_MarkOnOtherRow()
    var
        P: Page "LT SSN List";
    begin
        Seed();
        MarkIds('4');
        Sel.MarkedOnly(true);
        P.RunModal();
        Obs.Observe('currentId', Format(Current));
        Describe('', Sel);
        Obs.Expect('currentId', '0');
        Obs.Expect('Count', '0');
        Obs.Expect('Filters', 'Marked: Yes, Id: 0');
        Obs.Expect('MarkedOnly', 'Yes');
        Obs.Expect('HasFilter', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure TestPage_RowSelected()
    var
        Store: Codeunit "LT SSN Store";
        Captured: Record "ALT Shape 06";
        TP: TestPage "LT SSN List";
    begin
        Seed();
        TP.OpenView();
        TP.GoToKey(3);
        TP.CaptureAction.Invoke();
        Store.Get(Captured);
        Describe('', Captured);
        Obs.Expect('Count', '1');
        Obs.Expect('Filters', 'Id: 3');
        Obs.Expect('MarkedOnly', 'No');
        Obs.Expect('HasFilter', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure TestPage_FilteredToNothing()
    var
        Store: Codeunit "LT SSN Store";
        Captured: Record "ALT Shape 06";
        TP: TestPage "LT SSN List";
    begin
        Seed();
        TP.OpenView();
        TP.Filter.SetFilter(Id, '99');
        TP.CaptureAction.Invoke();
        Store.Get(Captured);
        Describe('', Captured);
        Obs.Expect('Count', '0');
        Obs.Expect('Filters', 'Id: 99');
        Obs.Expect('MarkedOnly', 'No');
        Obs.Expect('HasFilter', 'Yes');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('WorksheetHandler')]
    procedure Page_SetSelectionFilter_EmptyModalWorksheet_FiltersDefaultKey()
    var
        Row: Record "ALT Shape 06";
    begin
        Initialize();

        Row.Id := 1;
        Row.Name := 'HIDDEN';
        Row.Insert();
        Page.RunModal(Page::"PAG Empty Selection Worksheet");
    end;

    [ModalPageHandler]
    procedure WorksheetHandler(var Worksheet: TestPage "PAG Empty Selection Worksheet")
    begin
        Worksheet.CheckSelection.Invoke();
    end;

    local procedure Initialize()
    var
        Row: Record "ALT Shape 06";
    begin
        Row.DeleteAll();
    end;

    [Test]
    procedure TestPage_Update_NewWorksheetRow_IsSelectable()
    var
        Row: Record "ALT Universal";
        Worksheet: TestPage "PAG Selection Refresh Sheet";
    begin
        Initialize(Row);
        Worksheet.OpenEdit();
        Worksheet.ImportRow.Invoke();
        Worksheet.CheckSelection.Invoke();
        Worksheet.Close();
    end;

    [Test]
    procedure TestPage_First_AfterWorksheetUpdate_FindsImportedRow()
    var
        Row: Record "ALT Universal";
        Worksheet: TestPage "PAG Selection Refresh Sheet";
    begin
        Initialize(Row);
        Worksheet.OpenEdit();
        Worksheet.ImportRow.Invoke();
        if not Worksheet.First() then
            Error('Expected to find the imported row after Update.');
        Worksheet.CheckSelection.Invoke();
        Worksheet.Close();
    end;

    local procedure Initialize(var Row: Record "ALT Universal")
    begin
        Row.DeleteAll();
        Row."Entry No." := 1;
        Row."Code Field" := 'HIDDEN';
        Row."Boolean Field" := true;
        Row.Insert();
    end;
}

// local object: the worksheet source view and its action are the behavior under test.
page 67999 "PAG Empty Selection Worksheet"
{
    PageType = Worksheet;
    InsertAllowed = false;
    DelayedInsert = true;
    SourceTable = "ALT Shape 06";
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

    actions
    {
        area(Processing)
        {
            action(CheckSelection)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Selected: Record "ALT Shape 06";
                begin
                    CurrPage.SetSelectionFilter(Selected);
                    if Selected.GetFilter(Id) <> '0' then
                        Error('Expected a primary key filter on the default row. Got %1.', Selected.GetFilters());
                    if not Selected.IsEmpty() then
                        Error('The selection must exclude the hidden row.');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Name, 'VISIBLE');
        Rec.FilterGroup(0);
        if Rec.FindFirst() then;
    end;
}

// local object: the Worksheet action, source view, and group-2 range define the measured refresh.
page 67996 "PAG Selection Refresh Sheet"
{
    PageType = Worksheet;
    SourceTable = "ALT Universal";
    SourceTableView = where("Boolean Field" = const(true));
    DelayedInsert = true;
    InsertAllowed = false;
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec."Entry No.") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ImportRow)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "ALT Universal";
                begin
                    Row."Entry No." := 7;
                    Row."Code Field" := 'SELECTED';
                    Row."Boolean Field" := true;
                    Row.Insert();
                    CurrPage.Update(false);
                end;
            }
            action(CheckSelection)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Selected: Record "ALT Universal";
                begin
                    CurrPage.SetSelectionFilter(Selected);
                    if (Selected.Count() <> 1) or not Selected.FindFirst() then
                        Error('Expected one selected row. Got %1.', Selected.Count());
                    Selected.TestField("Entry No.", 7);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Code Field", 'SELECTED');
        Rec.FilterGroup(0);
        if Rec.FindFirst() then;
    end;
}
