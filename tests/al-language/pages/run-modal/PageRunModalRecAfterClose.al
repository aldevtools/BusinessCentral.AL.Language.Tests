// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), own table 71242, page 71243
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the row that Rec holds, and the returned Action, after Page.RunModal(PageId, Rec) when the ModalPageHandler
//   moved to another row (Next, Last, GoToKey), sat on the new-line row (New, with and without a typed key), closed with OK or Cancel,
//   for a temporary and a non-temporary Rec, with a filter on Rec, and for a Page variable with LookupMode(false).
//   Corpus RunModal_NonTempRecord_ShowsDbRows (P81) pins only the case where the handler does not move.
// BC versions: 29 (27 and 28 by CI)

table 71242 "LT RMR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 71243 "LT RMR List"
{
    PageType = List;
    SourceTable = "LT RMR Row";
    ApplicationArea = All;
    UsageCategory = None;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec.Code) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 71244 "LT Page RunModal Rec Close"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(var Row: Record "LT RMR Row")
    begin
        Row.Reset();
        Row.DeleteAll();
        Row.Init();
        Row.Code := 'A';
        Row.Name := 'alpha';
        Row.Insert();
        Row.Init();
        Row.Code := 'B';
        Row.Name := 'bravo';
        Row.Insert();
        Row.Init();
        Row.Code := 'C';
        Row.Name := 'charlie';
        Row.Insert();
    end;

    local procedure ObserveRec(var Observer: Codeunit "Probe Observer"; Prefix: Text; var Row: Record "LT RMR Row")
    begin
        Observer.Observe(Prefix + 'code', Row.Code);
        Observer.Observe(Prefix + 'name', Row.Name);
        Observer.Observe(Prefix + 'count', Format(Row.Count()));
        Observer.Observe(Prefix + 'filters', Row.GetFilters());
    end;

    local procedure ObserveDb(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Db: Record "LT RMR Row";
    begin
        Observer.Observe(Prefix + 'db_count', Format(Db.Count()));
        Observer.Observe(Prefix + 'db_has_N', Format(Db.Get('N')));
    end;

    // ---------------- non-temporary Rec ----------------

    [Test]
    [HandlerFunctions('NextOkHandler')]
    procedure P174_NonTemp_StartA_HandlerNextThenOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', 'B');
        Observer.Expect('rec_name', 'bravo');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LastOkHandler')]
    procedure P174_NonTemp_StartA_HandlerLastThenOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', 'C');
        Observer.Expect('rec_name', 'charlie');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GoToCOkHandler')]
    procedure P174_NonTemp_StartA_HandlerGoToKeyCThenOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', 'C');
        Observer.Expect('rec_name', 'charlie');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkOnlyHandler')]
    procedure P174_NonTemp_StartB_HandlerOkWithoutMoving()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Act: Action;
    begin
        Seed(Row);
        Row.Get('B');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', 'B');
        Observer.Expect('rec_name', 'bravo');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NextCancelHandler')]
    procedure P174_NonTemp_StartA_HandlerNextThenCancel()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('rec_code', 'B');
        Observer.Expect('rec_name', 'bravo');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NewRowOkHandler')]
    procedure P174_NonTemp_StartA_HandlerNewRowThenOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        ObserveDb(Observer, 'a_');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', '');
        Observer.Expect('rec_name', '');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Expect('a_db_count', '3');
        Observer.Expect('a_db_has_N', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NewRowTypedKeyOkHandler')]
    procedure P174_NonTemp_StartA_HandlerNewRowTypedKeyThenOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        ObserveDb(Observer, 'a_');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', 'N');
        Observer.Expect('rec_name', 'new');
        Observer.Expect('rec_count', '4');
        Observer.Expect('rec_filters', '');
        Observer.Expect('a_db_count', '4');
        Observer.Expect('a_db_has_N', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NewRowCancelHandler')]
    procedure P174_NonTemp_StartA_HandlerNewRowThenCancel()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        ObserveDb(Observer, 'a_');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('rec_code', 'N');
        Observer.Expect('rec_name', '');
        Observer.Expect('rec_count', '4');
        Observer.Expect('rec_filters', '');
        Observer.Expect('a_db_count', '4');
        Observer.Expect('a_db_has_N', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NextOkHandler')]
    procedure P174_NonTemp_FilteredRec_HandlerNextThenOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Act: Action;
    begin
        Seed(Row);
        Row.SetFilter(Code, '>=B');
        Row.FindFirst();
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', 'C');
        Observer.Expect('rec_name', 'charlie');
        Observer.Expect('rec_count', '2');
        Observer.Expect('rec_filters', 'Code: >=B');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NextOkHandler')]
    procedure P174_NonTemp_InitRecNoPosition_HandlerNextThenOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Act: Action;
    begin
        Seed(Row);
        Row.Init();
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', 'B');
        Observer.Expect('rec_name', 'bravo');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Verify();
    end;

    // ---------------- temporary Rec ----------------

    [Test]
    [HandlerFunctions('NextOkHandler')]
    procedure P174_Temp_StartA_HandlerNextThenOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row" temporary;
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', 'B');
        Observer.Expect('rec_name', 'bravo');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LastOkHandler')]
    procedure P174_Temp_StartA_HandlerLastThenOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row" temporary;
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', 'C');
        Observer.Expect('rec_name', 'charlie');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkOnlyHandler')]
    procedure P174_Temp_StartB_HandlerOkWithoutMoving()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row" temporary;
        Act: Action;
    begin
        Seed(Row);
        Row.Get('B');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', 'B');
        Observer.Expect('rec_name', 'bravo');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NextCancelHandler')]
    procedure P174_Temp_StartA_HandlerNextThenCancel()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row" temporary;
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Act := Page.RunModal(Page::"LT RMR List", Row);
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('rec_code', 'B');
        Observer.Expect('rec_name', 'bravo');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Verify();
    end;

    // ---------------- Page variable, LookupMode(false) / (true) ----------------

    [Test]
    [HandlerFunctions('NextOkHandler')]
    procedure P174_PageVar_LookupModeFalse_HandlerNextThenOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Pg: Page "LT RMR List";
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Pg.LookupMode(false);
        Pg.SetRecord(Row);
        Act := Pg.RunModal();
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Pg.GetRecord(Row);
        ObserveRec(Observer, 'got_', Row);
        Observer.Expect('action', 'OK');
        Observer.Expect('rec_code', 'A');
        Observer.Expect('rec_name', 'alpha');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Expect('got_code', 'B');
        Observer.Expect('got_name', 'bravo');
        Observer.Expect('got_count', '3');
        Observer.Expect('got_filters', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NextOkHandler')]
    procedure P174_PageVar_LookupModeTrue_HandlerNextThenOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RMR Row";
        Pg: Page "LT RMR List";
        Act: Action;
    begin
        Seed(Row);
        Row.Get('A');
        Pg.LookupMode(true);
        Pg.SetRecord(Row);
        Act := Pg.RunModal();
        Observer.Observe('action', Format(Act));
        ObserveRec(Observer, 'rec_', Row);
        Pg.GetRecord(Row);
        ObserveRec(Observer, 'got_', Row);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec_code', 'A');
        Observer.Expect('rec_name', 'alpha');
        Observer.Expect('rec_count', '3');
        Observer.Expect('rec_filters', '');
        Observer.Expect('got_code', 'B');
        Observer.Expect('got_name', 'bravo');
        Observer.Expect('got_count', '3');
        Observer.Expect('got_filters', '');
        Observer.Verify();
    end;

    // ---------------- handlers ----------------

    [ModalPageHandler]
    procedure OkOnlyHandler(var Modal: TestPage "LT RMR List")
    begin
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NextOkHandler(var Modal: TestPage "LT RMR List")
    begin
        Modal.First();
        Modal.Next();
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LastOkHandler(var Modal: TestPage "LT RMR List")
    begin
        Modal.Last();
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GoToCOkHandler(var Modal: TestPage "LT RMR List")
    begin
        Modal.GoToKey('C');
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NextCancelHandler(var Modal: TestPage "LT RMR List")
    begin
        Modal.First();
        Modal.Next();
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure NewRowOkHandler(var Modal: TestPage "LT RMR List")
    begin
        Modal.New();
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewRowTypedKeyOkHandler(var Modal: TestPage "LT RMR List")
    begin
        Modal.New();
        Modal.Code.SetValue('N');
        Modal.Name.SetValue('new');
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewRowCancelHandler(var Modal: TestPage "LT RMR List")
    begin
        Modal.New();
        Modal.Code.SetValue('N');
        Modal.Cancel().Invoke();
    end;
}
