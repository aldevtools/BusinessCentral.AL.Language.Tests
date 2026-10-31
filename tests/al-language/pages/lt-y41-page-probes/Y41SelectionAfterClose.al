// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-setselectionfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 92800 (Y41Log.al); table 92801, pages 92802-92804, test codeunit 92805
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: CurrPage.SetSelectionFilter(Sel) called through a procedure of a Page variable AFTER its RunModal returned, when a typed
//   ModalPageHandler set the page's record with SetRecord and answered LookupOK (also with a filter-group-2 view on Sel, with no
//   SetRecord, with LookupCancel), and when a TestPage handler moved the page with GoToKey and invoked OK. Also: what
//   OnAfterGetCurrRecord's CurrPage.SetSelectionFilter hands on a list opened with TestPage.OpenNew (with and without SourceTableView).
// BC versions: all (CI)

table 92801 "LT Y41 Sel Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Name; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 92802 "LT Y41 Sel List"
{
    PageType = List;
    SourceTable = "LT Y41 Sel Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    procedure GetSelected(var Sel: Record "LT Y41 Sel Row")
    begin
        CurrPage.SetSelectionFilter(Sel);
    end;

    procedure CurrentId(): Integer
    begin
        exit(Rec.Id);
    end;
}

page 92803 "LT Y41 New List"
{
    PageType = List;
    SourceTable = "LT Y41 Sel Row";
    SourceTableView = where(Grp = const('A'));
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('new');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y41 Log";
        L: Record "LT Y41 Sel Row";
    begin
        CurrPage.SetSelectionFilter(L);
        Log.AddLine('agcr id=' + Format(Rec.Id) + ' filters=' + L.GetFilters() + ' count=' + Format(L.Count()));
    end;
}

page 92804 "LT Y41 New List NoView"
{
    PageType = List;
    SourceTable = "LT Y41 Sel Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('new');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y41 Log";
        L: Record "LT Y41 Sel Row";
    begin
        CurrPage.SetSelectionFilter(L);
        Log.AddLine('agcr id=' + Format(Rec.Id) + ' filters=' + L.GetFilters() + ' count=' + Format(L.Count()));
    end;
}

codeunit 92805 "LT Y41 Sel After Close"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        HandlerRowId: Integer;
        HandlerSawId: Integer;

    local procedure Seed()
    var
        Row: Record "LT Y41 Sel Row";
        Log: Record "LT Y41 Log";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 5 do begin
            Row.Id := i;
            if i <= 3 then
                Row.Grp := 'A'
            else
                Row.Grp := 'B';
            Row.Name := 'row' + Format(i);
            Row.Insert();
        end;
        Log.ClearLog();
        HandlerSawId := -1;
    end;

    local procedure Describe(Prefix: Text; var Sel: Record "LT Y41 Sel Row")
    var
        Ids: Text;
    begin
        Obs.Observe(Prefix + 'count', Format(Sel.Count()));
        Obs.Observe(Prefix + 'filters', Sel.GetFilters());
        Obs.Observe(Prefix + 'markedonly', Format(Sel.MarkedOnly()));
        if Sel.FindSet() then
            repeat
                Ids += Format(Sel.Id) + ',';
            until Sel.Next() = 0;
        Obs.Observe(Prefix + 'ids', Ids);
    end;

    [ModalPageHandler]
    procedure SetRecordOkHandler(var P: Page "LT Y41 Sel List"; var Response: Action)
    var
        Row: Record "LT Y41 Sel Row";
    begin
        HandlerSawId := P.CurrentId();
        Row.Get(HandlerRowId);
        P.SetRecord(Row);
        Response := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure SetRecordCancelHandler(var P: Page "LT Y41 Sel List"; var Response: Action)
    var
        Row: Record "LT Y41 Sel Row";
    begin
        HandlerSawId := P.CurrentId();
        Row.Get(HandlerRowId);
        P.SetRecord(Row);
        Response := Action::LookupCancel;
    end;

    [ModalPageHandler]
    procedure PlainOkHandler(var P: Page "LT Y41 Sel List"; var Response: Action)
    begin
        HandlerSawId := P.CurrentId();
        Response := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure TestPageGoToOk(var P: TestPage "LT Y41 Sel List")
    begin
        P.GoToKey(3);
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetRecordOkHandler')]
    procedure G401_PageVar_HandlerSetRecord_LookupOK()
    var
        Sel: Record "LT Y41 Sel Row";
        P: Page "LT Y41 Sel List";
    begin
        Seed();
        HandlerRowId := 3;
        P.LookupMode(true);
        Obs.Observe('action', Format(P.RunModal()));
        Obs.Observe('handlerSawId', Format(HandlerSawId));
        Obs.Observe('currentId', Format(P.CurrentId()));
        P.GetSelected(Sel);
        Describe('sel ', Sel);
        Obs.Expect('action', 'LookupOK');
        Obs.Expect('handlerSawId', '0');
        Obs.Expect('currentId', '3');
        Obs.Expect('sel count', '1');
        Obs.Expect('sel filters', 'Id: 3');
        Obs.Expect('sel markedonly', 'No');
        Obs.Expect('sel ids', '3,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SetRecordOkHandler')]
    procedure G401_PageVar_HandlerSetRecord_FilterGroup2View()
    var
        Sel: Record "LT Y41 Sel Row";
        P: Page "LT Y41 Sel List";
    begin
        Seed();
        HandlerRowId := 2;
        Sel.FilterGroup(2);
        Sel.SetRange(Grp, 'A');
        Sel.FilterGroup(0);
        P.SetTableView(Sel);
        P.LookupMode(true);
        Obs.Observe('action', Format(P.RunModal()));
        Obs.Observe('handlerSawId', Format(HandlerSawId));
        Obs.Observe('currentId', Format(P.CurrentId()));
        P.GetSelected(Sel);
        Describe('sel ', Sel);
        Sel.FilterGroup(2);
        Obs.Observe('sel group2 filters', Sel.GetFilters());
        Sel.FilterGroup(0);
        Obs.Expect('action', 'LookupOK');
        Obs.Expect('handlerSawId', '0');
        Obs.Expect('currentId', '2');
        Obs.Expect('sel count', '1');
        Obs.Expect('sel filters', 'Id: 2');
        Obs.Expect('sel markedonly', 'No');
        Obs.Expect('sel ids', '2,');
        Obs.Expect('sel group2 filters', '');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainOkHandler')]
    procedure G401_PageVar_HandlerOk_NoSetRecord()
    var
        Sel: Record "LT Y41 Sel Row";
        P: Page "LT Y41 Sel List";
    begin
        Seed();
        P.LookupMode(true);
        Obs.Observe('action', Format(P.RunModal()));
        Obs.Observe('handlerSawId', Format(HandlerSawId));
        Obs.Observe('currentId', Format(P.CurrentId()));
        P.GetSelected(Sel);
        Describe('sel ', Sel);
        Obs.Expect('action', 'LookupOK');
        Obs.Expect('handlerSawId', '0');
        Obs.Expect('currentId', '0');
        Obs.Expect('sel count', '0');
        Obs.Expect('sel filters', 'Id: 0');
        Obs.Expect('sel markedonly', 'No');
        Obs.Expect('sel ids', '');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SetRecordCancelHandler')]
    procedure G401_PageVar_HandlerSetRecord_Cancel()
    var
        Sel: Record "LT Y41 Sel Row";
        P: Page "LT Y41 Sel List";
    begin
        Seed();
        HandlerRowId := 3;
        P.LookupMode(true);
        Obs.Observe('action', Format(P.RunModal()));
        Obs.Observe('handlerSawId', Format(HandlerSawId));
        Obs.Observe('currentId', Format(P.CurrentId()));
        P.GetSelected(Sel);
        Describe('sel ', Sel);
        Obs.Expect('action', 'LookupCancel');
        Obs.Expect('handlerSawId', '0');
        Obs.Expect('currentId', '3');
        Obs.Expect('sel count', '1');
        Obs.Expect('sel filters', 'Id: 3');
        Obs.Expect('sel markedonly', 'No');
        Obs.Expect('sel ids', '3,');
        Obs.Verify();
    end;

    [Test]
    procedure G401_OpenNew_List_SourceTableView()
    var
        Log: Record "LT Y41 Log";
        TP: TestPage "LT Y41 New List";
    begin
        Seed();
        TP.OpenNew();
        Obs.Observe('log', Log.Dump());
        Obs.Observe('shownId', TP.IdCtl.Value());
        TP.Close();
        Obs.Expect('log', 'agcr id=1 filters=Id: 1 count=1');
        Obs.Expect('shownId', '1');
        Obs.Verify();
    end;

    [Test]
    procedure G401_OpenNew_List_NoView()
    var
        Log: Record "LT Y41 Log";
        TP: TestPage "LT Y41 New List NoView";
    begin
        Seed();
        TP.OpenNew();
        Obs.Observe('log', Log.Dump());
        Obs.Observe('shownId', TP.IdCtl.Value());
        TP.Close();
        Obs.Expect('log', 'new;agcr id=0 filters=Id: 0 count=0');
        Obs.Expect('shownId', '0');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('TestPageGoToOk')]
    procedure G401_PageVar_TestPageHandler_GoToKeyOk()
    var
        Sel: Record "LT Y41 Sel Row";
        P: Page "LT Y41 Sel List";
    begin
        Seed();
        P.LookupMode(true);
        Obs.Observe('action', Format(P.RunModal()));
        Obs.Observe('currentId', Format(P.CurrentId()));
        P.GetSelected(Sel);
        Describe('sel ', Sel);
        Obs.Expect('action', 'LookupOK');
        Obs.Expect('currentId', '3');
        Obs.Expect('sel count', '1');
        Obs.Expect('sel filters', 'Id: 3');
        Obs.Expect('sel markedonly', 'No');
        Obs.Expect('sel ids', '3,');
        Obs.Verify();
    end;
}
