// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-setselectionfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al); tables 93241-93242, pages 93241-93243, test codeunit 93241
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: CurrPage.SetSelectionFilter(Sel) called through a procedure of a Page variable after its RunModal returned, on a table with a
//   TWO-field primary key, when the view came from a filter-group-2 filter on the same record variable that receives the selection
//   (a typed ModalPageHandler SetRecord + LookupOK, a TestPage handler GoToKey + OK, a SetRecord of a record that is not stored), and
//   with a second record variable as destination. Also: what OnAfterGetCurrRecord's CurrPage.SetSelectionFilter hands on an editable
//   DelayedInsert list opened by Page.Run from a Page variable whose Rec a procedure filtered (to no row, and to rows), with and without
//   an OnNewRecord that fills a field.
// Neighbours: pages/lt-y41-page-probes/Y41SelectionAfterClose.al (one-field key, view on another variable, OpenNew),
//   pages/lt-selection-filter-no-row/SelectionFilterNoRow.al.
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): inside a typed handler the page's Rec is blank. SetRecord + LookupOK or GoToKey + OK on
//   the two-field key gives 'Customer No.: C1, Code: B' (count 1); it REPLACES the filters of the destination, so the filter-group-2
//   view filter on that same variable is gone; a second variable as destination leaves the view variable as it was. SetRecord of a
//   record that is not stored gives its key filter and count 0, no error. The editable DelayedInsert list filtered to no row opens on its
//   new line: OnNewRecord and OnAfterGetCurrRecord run twice, the selection is 'Id: 0' count 0, also when OnNewRecord filled a field.
// BC versions: all (CI)

table 93241 "LT Y61 Sel H"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Customer No."; Code[20]) { }
        field(2; Code; Code[10]) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; "Customer No.", Code) { Clustered = true; } }
}

table 93242 "LT Y61 Sel D"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "File Name"; Text[30]) { }
        field(3; Grp; Code[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 93241 "LT Y61 Sel H List"
{
    PageType = List;
    SourceTable = "LT Y61 Sel H";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CustCtl; Rec."Customer No.") { ApplicationArea = All; }
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    procedure GetSelected(var Sel: Record "LT Y61 Sel H")
    begin
        CurrPage.SetSelectionFilter(Sel);
    end;

    procedure CurrentKey(): Text
    begin
        exit(Rec."Customer No." + '/' + Rec.Code);
    end;
}

page 93242 "LT Y61 Sel D List"
{
    PageType = List;
    SourceTable = "LT Y61 Sel D";
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(FileNameCtl; Rec."File Name") { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y61 Log";
    begin
        Rec."File Name" := 'New';
        Log.AddLine('new');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y61 Log";
        Sel: Record "LT Y61 Sel D";
    begin
        CurrPage.SetSelectionFilter(Sel);
        Log.AddLine('agcr id=' + Format(Rec.Id) + ' name=' + Rec."File Name" + ' count=' + Format(Sel.Count()) + ' filters=' + Sel.GetFilters());
    end;

    procedure Fill(G: Code[10])
    begin
        Rec.SetRange(Grp, G);
    end;
}

page 93243 "LT Y61 Sel D List2"
{
    PageType = List;
    SourceTable = "LT Y61 Sel D";
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(FileNameCtl; Rec."File Name") { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('new');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y61 Log";
        Sel: Record "LT Y61 Sel D";
    begin
        CurrPage.SetSelectionFilter(Sel);
        Log.AddLine('agcr id=' + Format(Rec.Id) + ' name=' + Rec."File Name" + ' count=' + Format(Sel.Count()) + ' filters=' + Sel.GetFilters());
    end;

    procedure Fill(G: Code[10])
    begin
        Rec.SetRange(Grp, G);
    end;
}

codeunit 93241 "LT Y61 Sel Composite"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HandlerRow: Record "LT Y61 Sel H";
        HandlerSawKey: Text;

    local procedure SeedH()
    var
        H: Record "LT Y61 Sel H";
    begin
        ClearLastError();
        Observer.Discard();
        H.DeleteAll();
        AddH('C1', 'A');
        AddH('C1', 'B');
        AddH('C2', 'A');
        HandlerSawKey := '-';
        Clear(HandlerRow);
    end;

    local procedure AddH(C: Code[20]; K: Code[10])
    var
        H: Record "LT Y61 Sel H";
    begin
        H.Init();
        H."Customer No." := C;
        H.Code := K;
        H.Name := C + K;
        H.Insert();
    end;

    local procedure SeedD()
    var
        D: Record "LT Y61 Sel D";
        Log: Record "LT Y61 Log";
    begin
        ClearLastError();
        Observer.Discard();
        D.DeleteAll();
        AddD(1, 'X');
        AddD(2, 'X');
        AddD(3, 'Y');
        Log.ClearLog();
    end;

    local procedure AddD(Id: Integer; G: Code[10])
    var
        D: Record "LT Y61 Sel D";
    begin
        D.Init();
        D.Id := Id;
        D."File Name" := 'f' + Format(Id);
        D.Grp := G;
        D.Insert();
    end;

    local procedure Describe(Prefix: Text; var Sel: Record "LT Y61 Sel H")
    var
        Keys: Text;
    begin
        Observer.Observe(Prefix + 'filters', Sel.GetFilters());
        Sel.FilterGroup(2);
        Observer.Observe(Prefix + 'group2 filters', Sel.GetFilters());
        Sel.FilterGroup(0);
        Observer.Observe(Prefix + 'count', Format(Sel.Count()));
        Observer.Observe(Prefix + 'markedonly', Format(Sel.MarkedOnly()));
        if Sel.FindSet() then
            repeat
                Keys += Sel."Customer No." + '/' + Sel.Code + ',';
            until Sel.Next() = 0;
        Observer.Observe(Prefix + 'keys', Keys);
    end;

    [TryFunction]
    local procedure TryGetSelected(var P: Page "LT Y61 Sel H List"; var Sel: Record "LT Y61 Sel H")
    begin
        P.GetSelected(Sel);
    end;

    local procedure Pick(C: Code[20]; var R: Record "LT Y61 Sel H"; var R2: Record "LT Y61 Sel H"; IntoOther: Boolean)
    var
        P: Page "LT Y61 Sel H List";
        Act: Action;
        Ok: Boolean;
    begin
        R.FilterGroup(2);
        R.SetRange("Customer No.", C);
        R.FilterGroup(0);
        P.SetTableView(R);
        P.LookupMode(true);
        Act := P.RunModal();
        Observer.Observe('action', Format(Act));
        Observer.Observe('handlerSawKey', HandlerSawKey);
        Observer.Observe('currentKey', P.CurrentKey());
        if Act = Action::LookupOK then begin
            if IntoOther then
                Ok := TryGetSelected(P, R2)
            else
                Ok := TryGetSelected(P, R);
            Observer.Observe('getselected ok', Format(Ok));
            if not Ok then
                Observer.ObserveError('getselected');
        end;
    end;

    [ModalPageHandler]
    procedure SetRecordOk(var P: Page "LT Y61 Sel H List"; var Response: Action)
    begin
        HandlerSawKey := P.CurrentKey();
        P.SetRecord(HandlerRow);
        Response := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure GoToOk(var P: TestPage "LT Y61 Sel H List")
    begin
        Observer.Observe('handler goto', Format(P.GoToKey('C1', 'B')));
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetRecordOk')]
    procedure G612_Composite_ViewIsDestination_SetRecordOk()
    var
        R: Record "LT Y61 Sel H";
        R2: Record "LT Y61 Sel H";
    begin
        SeedH();
        HandlerRow.Get('C1', 'B');
        Pick('C1', R, R2, false);
        Describe('r ', R);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('handlerSawKey', '/');
        Observer.Expect('currentKey', 'C1/B');
        Observer.Expect('getselected ok', 'Yes');
        Observer.Expect('r filters', 'Customer No.: C1, Code: B');
        Observer.Expect('r group2 filters', '');
        Observer.Expect('r count', '1');
        Observer.Expect('r markedonly', 'No');
        Observer.Expect('r keys', 'C1/B,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetRecordOk')]
    procedure G612_Composite_OtherDestination()
    var
        R: Record "LT Y61 Sel H";
        R2: Record "LT Y61 Sel H";
    begin
        SeedH();
        HandlerRow.Get('C1', 'B');
        Pick('C1', R, R2, true);
        Describe('r ', R);
        Describe('r2 ', R2);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('handlerSawKey', '/');
        Observer.Expect('currentKey', 'C1/B');
        Observer.Expect('getselected ok', 'Yes');
        Observer.Expect('r filters', '');
        Observer.Expect('r group2 filters', 'Customer No.: C1');
        Observer.Expect('r count', '2');
        Observer.Expect('r markedonly', 'No');
        Observer.Expect('r keys', 'C1/A,C1/B,');
        Observer.Expect('r2 filters', 'Customer No.: C1, Code: B');
        Observer.Expect('r2 group2 filters', '');
        Observer.Expect('r2 count', '1');
        Observer.Expect('r2 markedonly', 'No');
        Observer.Expect('r2 keys', 'C1/B,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GoToOk')]
    procedure G612_Composite_TestPageGoToOk()
    var
        R: Record "LT Y61 Sel H";
        R2: Record "LT Y61 Sel H";
    begin
        SeedH();
        Pick('C1', R, R2, false);
        Describe('r ', R);
        Observer.Expect('handler goto', 'Yes');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('handlerSawKey', '-');
        Observer.Expect('currentKey', 'C1/B');
        Observer.Expect('getselected ok', 'Yes');
        Observer.Expect('r filters', 'Customer No.: C1, Code: B');
        Observer.Expect('r group2 filters', '');
        Observer.Expect('r count', '1');
        Observer.Expect('r markedonly', 'No');
        Observer.Expect('r keys', 'C1/B,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetRecordOk')]
    procedure G612_Composite_SetRecord_NoRowOnPage()
    var
        R: Record "LT Y61 Sel H";
        R2: Record "LT Y61 Sel H";
    begin
        SeedH();
        HandlerRow.Init();
        HandlerRow."Customer No." := 'C9';
        HandlerRow.Code := 'Q';
        Pick('C1', R, R2, false);
        Describe('r ', R);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('handlerSawKey', '/');
        Observer.Expect('currentKey', 'C9/Q');
        Observer.Expect('getselected ok', 'Yes');
        Observer.Expect('r filters', 'Customer No.: C9, Code: Q');
        Observer.Expect('r group2 filters', '');
        Observer.Expect('r count', '0');
        Observer.Expect('r markedonly', 'No');
        Observer.Expect('r keys', '');
        Observer.Verify();
    end;

    [Test]
    procedure G612_EditableList_NewLine_OnNewRecordFills_NoRow()
    var
        Log: Record "LT Y61 Log";
        Pg: Page "LT Y61 Sel D List";
        TP: TestPage "LT Y61 Sel D List";
    begin
        SeedD();
        Pg.Fill('Z');
        TP.Trap();
        Pg.Run();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('shown id', TP.IdCtl.Value());
        Observer.Observe('shown name', TP.FileNameCtl.Value());
        TP.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored count', Format(StoredD()));
        Observer.Expect('open log', 'new;agcr id=0 name=New count=0 filters=Id: 0;new;agcr id=0 name=New count=0 filters=Id: 0');
        Observer.Expect('shown id', '0');
        Observer.Expect('shown name', 'New');
        Observer.Expect('close log', '');
        Observer.Expect('stored count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure G612_EditableList_NewLine_OnNewRecordFills_Rows()
    var
        Log: Record "LT Y61 Log";
        Pg: Page "LT Y61 Sel D List";
        TP: TestPage "LT Y61 Sel D List";
    begin
        SeedD();
        Pg.Fill('X');
        TP.Trap();
        Pg.Run();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('shown id', TP.IdCtl.Value());
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('next id', TP.IdCtl.Value());
        Observer.Observe('next2', Format(TP.Next()));
        Observer.Observe('next2 log', Log.Take());
        Observer.Observe('next2 id', TP.IdCtl.Value());
        Observer.Observe('next2 name', TP.FileNameCtl.Value());
        TP.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored count', Format(StoredD()));
        Observer.Expect('open log', 'agcr id=1 name=f1 count=1 filters=Id: 1');
        Observer.Expect('shown id', '1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next log', 'agcr id=2 name=f2 count=1 filters=Id: 2');
        Observer.Expect('next id', '2');
        Observer.Expect('next2', 'Yes');
        Observer.Expect('next2 log', 'new;agcr id=0 name=New count=0 filters=Id: 0');
        Observer.Expect('next2 id', '0');
        Observer.Expect('next2 name', 'New');
        Observer.Expect('close log', '');
        Observer.Expect('stored count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure G612_EditableList_NewLine_NoOnNewRecord_NoRow()
    var
        Log: Record "LT Y61 Log";
        Pg: Page "LT Y61 Sel D List2";
        TP: TestPage "LT Y61 Sel D List2";
    begin
        SeedD();
        Pg.Fill('Z');
        TP.Trap();
        Pg.Run();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('shown id', TP.IdCtl.Value());
        Observer.Observe('shown name', TP.FileNameCtl.Value());
        TP.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored count', Format(StoredD()));
        Observer.Expect('open log', 'new;agcr id=0 name= count=0 filters=Id: 0;new;agcr id=0 name= count=0 filters=Id: 0');
        Observer.Expect('shown id', '0');
        Observer.Expect('shown name', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored count', '3');
        Observer.Verify();
    end;

    local procedure StoredD(): Integer
    var
        D: Record "LT Y61 Sel D";
    begin
        exit(D.Count());
    end;
}
