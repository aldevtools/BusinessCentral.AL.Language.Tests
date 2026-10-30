// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-opennew-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 73270, SingleInstance log 73271 (used only by test codeunit 73276), pages 73272 (card with OnFindRecord), 73273 (list with OnFindRecord and OnNextRecord),
// 73274 (list without), 73275 (card without)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: (1) TestPage.OpenNew on a card and on a list whose page declares OnFindRecord (and OnNextRecord): the order of OnInit, OnOpenPage, OnFindRecord (its Which text), OnNewRecord, OnAfterGetRecord, OnAfterGetCurrRecord,
// what a value typed into the new record does and what Close leaves in the table; the same pages without OnFindRecord as the reference.
// (2) CurrPage.SetSelectionFilter and Page.SetSelectionFilter into a record that ALREADY has filters (on the key field, on another field, in filter group 2, a view): the filters and the count afterwards.
// (3) Page.GetRecord of a Page variable whose RunModal closed on a table with no row, for Cancel and LookupOK, with the record passed in holding values or cleared, and with a Page-typed handler.
// (4) Writer TV: the same on a table that has rows, the page filtered to no row by SetTableView (OK, LookupOK, Cancel in lookup mode, after SetRecord, typed handler).
// (5) Writer Y9 (NP lane 1030e, 2026-10-30; page 91475): TestPage OK() in the handler of a lookup page that shows no row: Page.RunModal(Id, Rec) on an empty table
// (Rec cleared or holding values, list editable or Editable = false), on a table with rows and Rec filtered to no row, and a Page variable in LookupMode: the Action and Rec.
// BC versions: 29 (27 and 28 by CI)

table 73270 "LT P129 Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73271 "LT P129 Log2"
{
    SingleInstance = true;

    var
        Entries: Text;
        Mode: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure SetMode(NewMode: Text)
    begin
        Mode := NewMode;
    end;

    procedure GetMode(): Text
    begin
        exit(Mode);
    end;
}

page 73272 "LT P129 Find Card"
{
    PageType = Card;
    SourceTable = "LT P129 Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    begin
        L.Add('card OnInit');
    end;

    trigger OnOpenPage()
    begin
        L.Add('card OnOpenPage');
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        L.Add('card OnFindRecord(' + Which + ')=' + Format(Found));
        exit(Found);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        L.Add('card OnNewRecord below=' + Format(BelowxRec));
    end;

    trigger OnAfterGetRecord()
    begin
        L.Add('card AGR ' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        L.Add('card AGCR ' + Format(Rec.Id));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        L.Add('card OnInsertRecord ' + Format(Rec.Id));
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        L.Add('card OnQueryClosePage');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        L.Add('card OnClosePage');
    end;

    var
        L: Codeunit "LT P129 Log2";
}

page 73273 "LT P129 Find List"
{
    PageType = List;
    SourceTable = "LT P129 Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    begin
        L.Add('list OnInit');
    end;

    trigger OnOpenPage()
    begin
        L.Add('list OnOpenPage');
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        L.Add('list OnFindRecord(' + Which + ')=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        L.Add('list OnNextRecord(' + Format(Steps) + ')=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        L.Add('list OnNewRecord below=' + Format(BelowxRec));
    end;

    trigger OnAfterGetRecord()
    begin
        L.Add('list AGR ' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        L.Add('list AGCR ' + Format(Rec.Id));
    end;

    var
        L: Codeunit "LT P129 Log2";
}

page 73274 "LT P129 Plain List"
{
    PageType = List;
    SourceTable = "LT P129 Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelFilter)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Sel: Record "LT P129 Item";
                begin
                    case L.GetMode() of
                        'same':
                            Sel.SetRange(Id, 1, 2);
                        'other':
                            Sel.SetRange(Grp, 'B');
                        'group':
                            begin
                                Sel.FilterGroup(2);
                                Sel.SetRange(Grp, 'A');
                                Sel.FilterGroup(0);
                            end;
                        'view':
                            Sel.SetFilter(Qty, '>=1');
                        'key':
                            Sel.SetRange(Id, 2);
                    end;
                    L.Add('before filters=[' + Sel.GetFilters() + ']');
                    CurrPage.SetSelectionFilter(Sel);
                    L.Add('after filters=[' + Sel.GetFilters() + '] count=' + Format(Sel.Count()) + ' id=[' + Sel.GetFilter(Id) + '] grp=[' + Sel.GetFilter(Grp) + '] qty=[' + Sel.GetFilter(Qty) + ']');
                end;
            }
        }
    }

    var
        L: Codeunit "LT P129 Log2";
}

page 73275 "LT P129 Plain Card"
{
    PageType = Card;
    SourceTable = "LT P129 Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    begin
        L.Add('card OnInit');
    end;

    trigger OnOpenPage()
    begin
        L.Add('card OnOpenPage');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        L.Add('card OnNewRecord below=' + Format(BelowxRec));
    end;

    trigger OnAfterGetRecord()
    begin
        L.Add('card AGR ' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        L.Add('card AGCR ' + Format(Rec.Id));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        L.Add('card OnInsertRecord ' + Format(Rec.Id));
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        L.Add('card OnQueryClosePage');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        L.Add('card OnClosePage');
    end;

    var
        L: Codeunit "LT P129 Log2";
}

// Writer Y9: the same list with Editable = false (a read-only lookup list).
page 91475 "LT Y9 LK List RO"
{
    PageType = List;
    SourceTable = "LT P129 Item";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 73276 "LT P129 Page Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P129 Log2";

    local procedure Seed()
    var
        Item: Record "LT P129 Item";
    begin
        Item.DeleteAll();
        Item.Id := 1;
        Item.Grp := 'A';
        Item.Qty := 5;
        Item.Insert();
        Item.Id := 2;
        Item.Grp := 'B';
        Item.Qty := 0;
        Item.Insert();
        Item.Id := 3;
        Item.Grp := 'A';
        Item.Qty := 2;
        Item.Insert();
        L.Take();
    end;

    [TryFunction]
    local procedure TryOpenNewFindCard(var Pg: TestPage "LT P129 Find Card")
    begin
        Pg.OpenNew();
    end;

    [TryFunction]
    local procedure TryOpenNewPlainCard(var Pg: TestPage "LT P129 Plain Card")
    begin
        Pg.OpenNew();
    end;

    [TryFunction]
    local procedure TryOpenNewFindList(var Pg: TestPage "LT P129 Find List")
    begin
        Pg.OpenNew();
    end;

    [TryFunction]
    local procedure TryOpenNewPlainList(var Pg: TestPage "LT P129 Plain List")
    begin
        Pg.OpenNew();
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('err|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P129_OpenNew_CardWithOnFindRecord()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P129 Find Card";
        Item: Record "LT P129 Item";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('open', Outcome(TryOpenNewFindCard(Pg)));
        Observer.Observe('log after open', L.Take());
        Observer.Observe('id after open', Pg.Id.Value());
        Pg.Id.SetValue(10);
        Pg.Grp.SetValue('Z');
        Observer.Observe('log after set', L.Take());
        Pg.Close();
        Observer.Observe('log after close', L.Take());
        Observer.Observe('count after close', Format(Item.Count()));
        Observer.Observe('row 10 exists', Format(Item.Get(10)));
        Observer.Expect('open', 'ok');
        Observer.Expect('log after open', 'card OnInit;card OnOpenPage;card OnNewRecord below=Yes;card AGCR 0;');
        Observer.Expect('id after open', '0');
        Observer.Expect('log after set', 'card OnInsertRecord 10;');
        Observer.Expect('log after close', 'card OnQueryClosePage;card OnClosePage;');
        Observer.Expect('count after close', '4');
        Observer.Expect('row 10 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P129_OpenNew_CardWithoutOnFindRecord_Reference()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P129 Plain Card";
        Item: Record "LT P129 Item";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('open', Outcome(TryOpenNewPlainCard(Pg)));
        Observer.Observe('log after open', L.Take());
        Observer.Observe('id after open', Pg.Id.Value());
        Pg.Id.SetValue(10);
        Pg.Grp.SetValue('Z');
        Observer.Observe('log after set', L.Take());
        Pg.Close();
        Observer.Observe('log after close', L.Take());
        Observer.Observe('count after close', Format(Item.Count()));
        Observer.Observe('row 10 exists', Format(Item.Get(10)));
        Observer.Expect('open', 'ok');
        Observer.Expect('log after open', 'card OnInit;card OnOpenPage;card OnNewRecord below=Yes;card AGCR 0;');
        Observer.Expect('id after open', '0');
        Observer.Expect('log after set', 'card OnInsertRecord 10;');
        Observer.Expect('log after close', 'card OnQueryClosePage;card OnClosePage;');
        Observer.Expect('count after close', '4');
        Observer.Expect('row 10 exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P129_OpenNew_ListWithOnFindRecord()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P129 Find List";
        Item: Record "LT P129 Item";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('open', Outcome(TryOpenNewFindList(Pg)));
        Observer.Observe('log after open', L.Take());
        Observer.Observe('id after open', Pg.Id.Value());
        Pg.Close();
        Observer.Observe('log after close', L.Take());
        Observer.Observe('count after close', Format(Item.Count()));
        Observer.Expect('open', 'ok');
        Observer.Expect('log after open', 'list OnInit;list OnOpenPage;list OnNewRecord below=Yes;list AGCR 0;');
        Observer.Expect('id after open', '0');
        Observer.Expect('log after close', '');
        Observer.Expect('count after close', '3');
        Observer.Verify();
    end;

    [Test]
    procedure P129_OpenNew_ListWithoutOnFindRecord_Reference()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P129 Plain List";
        Item: Record "LT P129 Item";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('open', Outcome(TryOpenNewPlainList(Pg)));
        Observer.Observe('id after open', Pg.Id.Value());
        Pg.Close();
        Observer.Observe('count after close', Format(Item.Count()));
        Observer.Expect('open', 'ok');
        Observer.Expect('id after open', '0');
        Observer.Expect('count after close', '3');
        Observer.Verify();
    end;

    local procedure SelectionRun(Mode: Text): Text
    var
        Pg: TestPage "LT P129 Plain List";
    begin
        Seed();
        L.SetMode(Mode);
        Pg.OpenView();
        Pg.GoToKey(2);
        Pg.SelFilter.Invoke();
        Pg.Close();
        L.SetMode('');
        exit(L.Take());
    end;

    [Test]
    procedure P129_CurrPageSetSelectionFilter_IntoRecordWithFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('none', SelectionRun('none'));
        Observer.Observe('same field range', SelectionRun('same'));
        Observer.Observe('key field single', SelectionRun('key'));
        Observer.Observe('other field', SelectionRun('other'));
        Observer.Observe('filter group 2', SelectionRun('group'));
        Observer.Observe('other field view', SelectionRun('view'));
        Observer.Expect('none', 'before filters=[];after filters=[Id: 2] count=1 id=[2] grp=[] qty=[];');
        Observer.Expect('same field range', 'before filters=[Id: 1..2];after filters=[Id: 2] count=1 id=[2] grp=[] qty=[];');
        Observer.Expect('key field single', 'before filters=[Id: 2];after filters=[Id: 2] count=1 id=[2] grp=[] qty=[];');
        Observer.Expect('other field', 'before filters=[Grp: B];after filters=[Id: 2] count=1 id=[2] grp=[] qty=[];');
        Observer.Expect('filter group 2', 'before filters=[];after filters=[Id: 2] count=1 id=[2] grp=[] qty=[];');
        Observer.Expect('other field view', 'before filters=[Qty: >=1];after filters=[Id: 2] count=1 id=[2] grp=[] qty=[];');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure PickSecondHandler(var P: TestPage "LT P129 Plain List")
    begin
        P.GoToKey(2);
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TrySelectionFilter(var Pg: Page "LT P129 Plain List"; var Sel: Record "LT P129 Item")
    begin
        Pg.SetSelectionFilter(Sel);
    end;

    [Test]
    [HandlerFunctions('PickSecondHandler')]
    procedure P129_PageVariable_SetSelectionFilter_IntoRecordWithFilters()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P129 Plain List";
        Sel: Record "LT P129 Item";
    begin
        Seed();
        Pg.RunModal();
        ClearLastError();
        Observer.Observe('none', Outcome(TrySelectionFilter(Pg, Sel)) + '|filters=[' + Sel.GetFilters() + ']|count=' + Format(Sel.Count()));
        Sel.Reset();
        Sel.SetRange(Id, 1, 2);
        ClearLastError();
        Observer.Observe('same field range', Outcome(TrySelectionFilter(Pg, Sel)) + '|filters=[' + Sel.GetFilters() + ']|count=' + Format(Sel.Count()));
        Sel.Reset();
        Sel.SetRange(Grp, 'B');
        ClearLastError();
        Observer.Observe('other field', Outcome(TrySelectionFilter(Pg, Sel)) + '|filters=[' + Sel.GetFilters() + ']|count=' + Format(Sel.Count()));
        Sel.Reset();
        Sel.SetFilter(Qty, '>=1');
        ClearLastError();
        Observer.Observe('other field view', Outcome(TrySelectionFilter(Pg, Sel)) + '|filters=[' + Sel.GetFilters() + ']|count=' + Format(Sel.Count()));
        Observer.Expect('none', 'ok|filters=[Id: 2]|count=1');
        Observer.Expect('same field range', 'ok|filters=[Id: 2]|count=1');
        Observer.Expect('other field', 'ok|filters=[Id: 2]|count=1');
        Observer.Expect('other field view', 'ok|filters=[Id: 2]|count=1');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure CancelHandler(var P: TestPage "LT P129 Plain List")
    begin
        P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure OkHandler(var P: TestPage "LT P129 Plain List")
    begin
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure TypedEmptyHandler(var P: Page "LT P129 Plain List"; var Response: Action)
    var
        Row: Record "LT P129 Item";
    begin
        Row.Id := 77;
        P.GetRecord(Row);
        L.Add('handler getrecord id=' + Format(Row.Id));
        Response := Action::LookupOK;
    end;

    [TryFunction]
    local procedure TryGetRecord(var Pg: Page "LT P129 Plain List"; var Row: Record "LT P129 Item")
    begin
        Pg.GetRecord(Row);
    end;

    local procedure AfterEmptyRun(var Pg: Page "LT P129 Plain List"; Prefill: Boolean): Text
    var
        Row: Record "LT P129 Item";
    begin
        if Prefill then begin
            Row.Id := 5;
            Row.Grp := 'Q';
            Row.Qty := 9;
        end;
        ClearLastError();
        if not TryGetRecord(Pg, Row) then
            exit('err|' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('ok|id=' + Format(Row.Id) + '|grp=' + Row.Grp + '|qty=' + Format(Row.Qty));
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure P129_GetRecord_AfterRunModalCancelledOnEmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P129 Plain List";
        Item: Record "LT P129 Item";
        Result: Action;
    begin
        Item.DeleteAll();
        asserterror Result := Pg.RunModal();
        Observer.ObserveError('af586');
        Observer.Observe('result', Format(Result));
        Observer.Observe('prefilled record', AfterEmptyRun(Pg, true));
        Observer.Observe('cleared record', AfterEmptyRun(Pg, false));
        Observer.Expect('af586|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('af586|code', 'TestActionNotFound');
        Observer.Expect('result', 'None');
        Observer.Expect('prefilled record', 'ok|id=0|grp=|qty=0');
        Observer.Expect('cleared record', 'ok|id=0|grp=|qty=0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure P129_GetRecord_AfterRunModalOkOnEmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P129 Plain List";
        Item: Record "LT P129 Item";
        Result: Action;
    begin
        Item.DeleteAll();
        Result := Pg.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('prefilled record', AfterEmptyRun(Pg, true));
        Observer.Observe('cleared record', AfterEmptyRun(Pg, false));
        Observer.Expect('result', 'OK');
        Observer.Expect('prefilled record', 'ok|id=0|grp=|qty=0');
        Observer.Expect('cleared record', 'ok|id=0|grp=|qty=0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedEmptyHandler')]
    procedure P129_GetRecord_PageTypedHandlerOnEmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P129 Plain List";
        Item: Record "LT P129 Item";
        Result: Action;
    begin
        Item.DeleteAll();
        L.Take();
        Result := Pg.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler log', L.Take());
        Observer.Observe('prefilled record', AfterEmptyRun(Pg, true));
        Observer.Observe('cleared record', AfterEmptyRun(Pg, false));
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('handler log', 'handler getrecord id=0;');
        Observer.Expect('prefilled record', 'ok|id=0|grp=|qty=0');
        Observer.Expect('cleared record', 'ok|id=0|grp=|qty=0');
        Observer.Verify();
    end;

    // ---- Writer TV (NP lane, 2026-10-29): Page.GetRecord of a Page variable whose RunModal closed on no row of a table that HAS rows
    // (SetTableView with a filter no row meets), for OK, LookupOK and Cancel in lookup mode, after SetRecord of a row, and with a Page-typed
    // handler. ----

    // In lookup mode on no row, TestPage OK() is not found (BC 29 SaaS sandbox): the handler records the error and cancels.
    [ModalPageHandler]
    procedure TvLookupOkHandler(var P: TestPage "LT P129 Plain List")
    begin
        L.Add('tv first=' + Format(P.First()));
        asserterror P.OK().Invoke();
        L.Add('ok error=' + GetLastErrorText() + '|' + GetLastErrorCode());
        P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure TvLookupCancelHandler(var P: TestPage "LT P129 Plain List")
    begin
        L.Add('tv first=' + Format(P.First()));
        P.Cancel().Invoke();
    end;

    local procedure TvNoRowView(var Pg: Page "LT P129 Plain List")
    var
        Item: Record "LT P129 Item";
    begin
        Item.SetRange(Grp, 'NONE');
        Pg.SetTableView(Item);
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure TV_GetRecord_AfterRunModalOk_FilteredToNoRow()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P129 Plain List";
        Result: Action;
    begin
        Seed();
        TvNoRowView(Pg);
        Result := Pg.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('prefilled record', AfterEmptyRun(Pg, true));
        Observer.Observe('cleared record', AfterEmptyRun(Pg, false));
        Observer.Expect('result', 'OK');
        Observer.Expect('prefilled record', 'ok|id=0|grp=|qty=0');
        Observer.Expect('cleared record', 'ok|id=0|grp=|qty=0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TvLookupOkHandler')]
    procedure TV_GetRecord_AfterLookupOk_FilteredToNoRow()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P129 Plain List";
        Result: Action;
    begin
        Seed();
        TvNoRowView(Pg);
        Pg.LookupMode(true);
        Result := Pg.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler log', L.Take());
        Observer.Observe('prefilled record', AfterEmptyRun(Pg, true));
        Observer.Observe('cleared record', AfterEmptyRun(Pg, false));
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler log', 'tv first=No;ok error=The built-in action = OK is not found on the page.|TestActionNotFound;');
        Observer.Expect('prefilled record', 'ok|id=0|grp=|qty=0');
        Observer.Expect('cleared record', 'ok|id=0|grp=|qty=0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TvLookupCancelHandler')]
    procedure TV_GetRecord_AfterLookupCancel_FilteredToNoRow()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P129 Plain List";
        Result: Action;
    begin
        Seed();
        TvNoRowView(Pg);
        Pg.LookupMode(true);
        Result := Pg.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler log', L.Take());
        Observer.Observe('prefilled record', AfterEmptyRun(Pg, true));
        Observer.Observe('cleared record', AfterEmptyRun(Pg, false));
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler log', 'tv first=No;');
        Observer.Expect('prefilled record', 'ok|id=0|grp=|qty=0');
        Observer.Expect('cleared record', 'ok|id=0|grp=|qty=0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TvLookupOkHandler')]
    procedure TV_GetRecord_AfterSetRecordAndLookupOk_FilteredToNoRow()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P129 Plain List";
        Item: Record "LT P129 Item";
        Result: Action;
    begin
        Seed();
        Item.Get(2);
        Pg.SetRecord(Item);
        TvNoRowView(Pg);
        Pg.LookupMode(true);
        Result := Pg.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler log', L.Take());
        Observer.Observe('prefilled record', AfterEmptyRun(Pg, true));
        Observer.Observe('cleared record', AfterEmptyRun(Pg, false));
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler log', 'tv first=No;ok error=The built-in action = OK is not found on the page.|TestActionNotFound;');
        Observer.Expect('prefilled record', 'ok|id=0|grp=|qty=0');
        Observer.Expect('cleared record', 'ok|id=0|grp=|qty=0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedEmptyHandler')]
    procedure TV_GetRecord_PageTypedHandler_FilteredToNoRow()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P129 Plain List";
        Result: Action;
    begin
        Seed();
        TvNoRowView(Pg);
        Result := Pg.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler log', L.Take());
        Observer.Observe('prefilled record', AfterEmptyRun(Pg, true));
        Observer.Observe('cleared record', AfterEmptyRun(Pg, false));
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('handler log', 'handler getrecord id=0;');
        Observer.Expect('prefilled record', 'ok|id=0|grp=|qty=0');
        Observer.Expect('cleared record', 'ok|id=0|grp=|qty=0');
        Observer.Verify();
    end;

    // ---- Writer Y9 (NP lane 1030e, 2026-10-30): TestPage OK() in the ModalPageHandler of a lookup page that shows no row. The RunModal call runs inside
    // asserterror and ends with an error of its own, so both outcomes (OK found or not) are recorded: the error text, the Action and the record afterwards. ----

    [ModalPageHandler]
    procedure Y9OkHandler(var P: TestPage "LT P129 Plain List")
    begin
        L.Add('first=' + Format(P.First()));
        P.OK().Invoke();
        L.Add('ok invoked');
    end;

    [ModalPageHandler]
    procedure Y9OkRoHandler(var P: TestPage "LT Y9 LK List RO")
    begin
        L.Add('first=' + Format(P.First()));
        P.OK().Invoke();
        L.Add('ok invoked');
    end;

    local procedure Y9RecText(Row: Record "LT P129 Item"): Text
    begin
        exit('id=' + Format(Row.Id) + '|grp=' + Row.Grp + '|qty=' + Format(Row.Qty) + '|filters=' + Row.GetFilters());
    end;

    local procedure Y9Empty()
    var
        Item: Record "LT P129 Item";
    begin
        Item.DeleteAll();
        Commit();
        L.Take();
    end;

    [Test]
    [HandlerFunctions('Y9OkHandler')]
    procedure Y9_Lookup_RunModalIdRec_EmptyTable_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 Item";
        Result: Action;
    begin
        Y9Empty();
        asserterror begin
            Result := Page.RunModal(Page::"LT P129 Plain List", Row);
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', L.Take());
        Observer.Observe('record', Y9RecText(Row));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('Y9OkHandler')]
    procedure Y9_Lookup_RunModalIdRec_EmptyTable_PrefilledRec_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 Item";
        Result: Action;
    begin
        Y9Empty();
        Row.Id := 5;
        Row.Grp := 'Q';
        Row.Qty := 9;
        asserterror begin
            Result := Page.RunModal(Page::"LT P129 Plain List", Row);
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', L.Take());
        Observer.Observe('record', Y9RecText(Row));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('Y9OkRoHandler')]
    procedure Y9_Lookup_RunModalIdRec_EmptyTable_ReadOnlyList_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 Item";
        Result: Action;
    begin
        Y9Empty();
        asserterror begin
            Result := Page.RunModal(Page::"LT Y9 LK List RO", Row);
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', L.Take());
        Observer.Observe('record', Y9RecText(Row));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('Y9OkHandler')]
    procedure Y9_Lookup_RunModalIdRec_FilteredToNoRow_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 Item";
        Result: Action;
    begin
        Seed();
        Commit();
        Row.SetRange(Grp, 'NONE');
        asserterror begin
            Result := Page.RunModal(Page::"LT P129 Plain List", Row);
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', L.Take());
        Observer.Observe('record', Y9RecText(Row));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('Y9OkHandler')]
    procedure Y9_Lookup_PageVarLookupMode_EmptyTable_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P129 Plain List";
        Row: Record "LT P129 Item";
        Result: Action;
    begin
        Y9Empty();
        Pg.LookupMode(true);
        asserterror begin
            Result := Pg.RunModal();
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', L.Take());
        Row.Id := 5;
        Pg.GetRecord(Row);
        Observer.Observe('getrecord', Y9RecText(Row));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('Y9OkHandler')]
    procedure Y9_Lookup_RunModalIdRec_WithRows_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 Item";
        Result: Action;
    begin
        // reference: the same call on a table that has rows (the handler's OK takes the first row)
        Seed();
        Commit();
        asserterror begin
            Result := Page.RunModal(Page::"LT P129 Plain List", Row);
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', L.Take());
        Observer.Observe('record', Y9RecText(Row));
        Observer.Finish();
    end;
}
