// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 70307, pages 70308 and 70309, codeunit 70310
// Probe: written against BC 29 (tag P81, GitHub issue 81); every literal asserted later is what a local BC 29 tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: running a page with a temporary record as source (Page.RunModal(Id, TempRec), Page.Run(Id, TempRec), SetTableView, SetRecord): which rows the page shows and what it writes back to the temporary record and to the table
// BC versions: 29 (27 and 28 by CI)

table 70307 "LT P81 PG Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 70308 "LT P81 PG List"
{
    PageType = List;
    SourceTable = "LT P81 PG Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { }
                field(Name; Rec.Name) { }
                field(Qty; Rec.Qty) { }
            }
        }
    }
}

page 70309 "LT P81 PG TempList"
{
    PageType = List;
    SourceTable = "LT P81 PG Row";
    SourceTableTemporary = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { }
                field(Name; Rec.Name) { }
                field(Qty; Rec.Qty) { }
            }
        }
    }
}

codeunit 70310 "LT P81 Page Temp Source"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed(var Temp: Record "LT P81 PG Row" temporary)
    var
        Row: Record "LT P81 PG Row";
    begin
        Row.DeleteAll();
        Row.Code := 'D1';
        Row.Name := 'db-one';
        Row.Qty := 10;
        Row.Insert();
        Row.Code := 'D2';
        Row.Name := 'db-two';
        Row.Qty := 20;
        Row.Insert();
        Temp.DeleteAll();
        Temp.Code := 'T1';
        Temp.Name := 'temp-one';
        Temp.Qty := 1;
        Temp.Insert();
        Temp.Code := 'T2';
        Temp.Name := 'temp-two';
        Temp.Qty := 2;
        Temp.Insert();
        Temp.Code := 'T3';
        Temp.Name := 'temp-three';
        Temp.Qty := 3;
        Temp.Insert();
        Temp.FindFirst();
    end;

    local procedure ObserveRows(var P: TestPage "LT P81 PG List"; Prefix: Text)
    var
        n: Integer;
    begin
        if P.First() then
            repeat
                n += 1;
                Observer.Observe(Prefix + '_row' + Format(n), P.Code.Value() + '|' + P.Name.Value() + '|' + P.Qty.Value());
            until not P.Next();
        Observer.Observe(Prefix + '_rows', Format(n));
    end;

    local procedure ObserveDb(Prefix: Text)
    var
        Row: Record "LT P81 PG Row";
    begin
        Observer.Observe(Prefix + '_db_count', Format(Row.Count()));
        Observer.Observe(Prefix + '_db_has_t1', Format(Row.Get('T1')));
    end;

    [ModalPageHandler]
    procedure ReadRowsHandler(var P: TestPage "LT P81 PG List")
    begin
        ObserveRows(P, 'page');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditFirstHandler(var P: TestPage "LT P81 PG List")
    begin
        P.First();
        Observer.Observe('page_first_before', P.Code.Value() + '|' + P.Name.Value());
        P.Name.SetValue('edited');
        P.Qty.SetValue(42);
        ObserveRows(P, 'page');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewRowHandler(var P: TestPage "LT P81 PG List")
    begin
        P.New();
        P.Code.SetValue('N1');
        P.Name.SetValue('new-row');
        P.Qty.SetValue(5);
        ObserveRows(P, 'page');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelAfterEditHandler(var P: TestPage "LT P81 PG List")
    begin
        P.First();
        P.Name.SetValue('edited-cancel');
        P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure CurrentRowHandler(var P: TestPage "LT P81 PG List")
    begin
        Observer.Observe('page_current', P.Code.Value() + '|' + P.Name.Value());
        ObserveRows(P, 'page');
        P.OK().Invoke();
    end;

    [PageHandler]
    procedure NonModalHandler(var P: TestPage "LT P81 PG List")
    begin
        ObserveRows(P, 'page');
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure RunModal_TempRecord_ShowsTempRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Result: Action;
    begin
        Seed(Temp);
        Result := Page.RunModal(Page::"LT P81 PG List", Temp);
        Observer.Observe('result', Format(Result));
        Observer.Observe('temp_count', Format(Temp.Count()));
        ObserveDb('a');
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_rows', '3');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('temp_count', '3');
        Observer.Expect('a_db_count', '2');
        Observer.Expect('a_db_has_t1', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EditFirstHandler')]
    procedure RunModal_TempRecord_EditWritesToTemp()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Page.RunModal(Page::"LT P81 PG List", Temp);
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('temp_t1_found', Format(Temp.Get('T1')));
        Observer.Observe('temp_t1_name', Temp.Name);
        Observer.Observe('temp_t1_qty', Format(Temp.Qty));
        Row.Get('D1');
        Observer.Observe('db_d1_name', Row.Name);
        ObserveDb('a');
        Observer.Expect('page_first_before', 'T1|temp-one');
        Observer.Expect('page_row1', 'T1|edited|42');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_row4', '||0');
        Observer.Expect('page_rows', '4');
        Observer.Expect('temp_count', '3');
        Observer.Expect('temp_t1_found', 'Yes');
        Observer.Expect('temp_t1_name', 'edited');
        Observer.Expect('temp_t1_qty', '42');
        Observer.Expect('db_d1_name', 'db-one');
        Observer.Expect('a_db_count', '2');
        Observer.Expect('a_db_has_t1', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NewRowHandler')]
    procedure RunModal_TempRecord_NewRow()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Page.RunModal(Page::"LT P81 PG List", Temp);
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('temp_n1_found', Format(Temp.Get('N1')));
        Observer.Observe('temp_n1_name', Temp.Name);
        ObserveDb('a');
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'N1|new-row|5');
        Observer.Expect('page_row3', 'T2|temp-two|2');
        Observer.Expect('page_row4', 'T3|temp-three|3');
        Observer.Expect('page_row5', '||0');
        Observer.Expect('page_rows', '5');
        Observer.Expect('temp_count', '4');
        Observer.Expect('temp_n1_found', 'Yes');
        Observer.Expect('temp_n1_name', 'new-row');
        Observer.Expect('a_db_count', '2');
        Observer.Expect('a_db_has_t1', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelAfterEditHandler')]
    procedure RunModal_TempRecord_CancelAfterEdit()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Result: Action;
    begin
        Seed(Temp);
        Result := Page.RunModal(Page::"LT P81 PG List", Temp);
        Observer.Observe('result', Format(Result));
        Observer.Observe('temp_t1_found', Format(Temp.Get('T1')));
        Observer.Observe('temp_t1_name', Temp.Name);
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('temp_t1_found', 'Yes');
        Observer.Expect('temp_t1_name', 'edited-cancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure RunModal_TempRecord_WithFilter()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Temp.SetFilter(Qty, '>=2');
        Page.RunModal(Page::"LT P81 PG List", Temp);
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('temp_filters', Temp.GetFilters());
        Observer.Expect('page_row1', 'T2|temp-two|2');
        Observer.Expect('page_row2', 'T3|temp-three|3');
        Observer.Expect('page_row3', '||0');
        Observer.Expect('page_rows', '3');
        Observer.Expect('temp_count', '2');
        Observer.Expect('temp_filters', 'Qty: >=2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure RunModal_NonTempRecord_ShowsDbRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Row.FindFirst();
        Page.RunModal(Page::"LT P81 PG List", Row);
        Observer.Observe('row_code', Row.Code);
        Observer.Expect('page_row1', 'D1|db-one|10');
        Observer.Expect('page_row2', 'D2|db-two|20');
        Observer.Expect('page_row3', '||0');
        Observer.Expect('page_rows', '3');
        Observer.Expect('row_code', 'D1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PageVar_SetTableView_TempRecord()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Temp.SetRange(Qty, 2, 3);
        Pg.SetTableView(Temp);
        Pg.RunModal();
        Observer.Observe('temp_count', Format(Temp.Count()));
        ObserveDb('a');
        Observer.Expect('page_rows', '0');
        Observer.Expect('temp_count', '2');
        Observer.Expect('a_db_count', '2');
        Observer.Expect('a_db_has_t1', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PageVar_SetTableView_NonTempFilter()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Row.SetRange(Qty, 20);
        Pg.SetTableView(Row);
        Pg.RunModal();
        Observer.Expect('page_row1', 'D2|db-two|20');
        Observer.Expect('page_row2', '||0');
        Observer.Expect('page_rows', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure PageVar_SetRecord_TempRecord()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Temp.Get('T2');
        Pg.SetRecord(Temp);
        Pg.RunModal();
        Observer.Expect('page_current', 'D2|db-two');
        Observer.Expect('page_row1', 'D1|db-one|10');
        Observer.Expect('page_row2', 'D2|db-two|20');
        Observer.Expect('page_row3', '||0');
        Observer.Expect('page_rows', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure PageVar_SetRecord_NonTempRecord()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Row.Get('D2');
        Pg.SetRecord(Row);
        Pg.RunModal();
        Observer.Expect('page_current', 'D2|db-two');
        Observer.Expect('page_row1', 'D1|db-one|10');
        Observer.Expect('page_row2', 'D2|db-two|20');
        Observer.Expect('page_row3', '||0');
        Observer.Expect('page_rows', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure PageVar_SetRecord_ThenSetTableView_Temp()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Temp.Get('T3');
        Pg.SetRecord(Temp);
        Temp.SetFilter(Qty, '<=2');
        Pg.SetTableView(Temp);
        Pg.RunModal();
        Observer.Expect('page_current', '|');
        Observer.Expect('page_rows', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NonModalHandler')]
    procedure PageRun_TempRecord_NonModal()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Page.Run(Page::"LT P81 PG List", Temp);
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_row4', '||0');
        Observer.Expect('page_rows', '4');
        Observer.Expect('temp_count', '3');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure TempListHandler(var P: TestPage "LT P81 PG TempList")
    var
        n: Integer;
    begin
        if P.First() then
            repeat
                n += 1;
                Observer.Observe('page_row' + Format(n), P.Code.Value() + '|' + P.Name.Value());
            until not P.Next();
        Observer.Observe('page_rows', Format(n));
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure TempListNewHandler(var P: TestPage "LT P81 PG TempList")
    begin
        P.New();
        P.Code.SetValue('PN');
        P.Name.SetValue('page-new');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('TempListHandler')]
    procedure SourceTableTemporaryPage_ShowsNoDbRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Page.RunModal(Page::"LT P81 PG TempList");
        Observer.Expect('page_rows', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempListHandler')]
    procedure SourceTableTemporaryPage_GivenRecord()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Page.RunModal(Page::"LT P81 PG TempList", Temp);
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Expect('page_row1', 'T1|temp-one');
        Observer.Expect('page_row2', 'T2|temp-two');
        Observer.Expect('page_row3', 'T3|temp-three');
        Observer.Expect('page_row4', '|');
        Observer.Expect('page_rows', '4');
        Observer.Expect('temp_count', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempListNewHandler')]
    procedure SourceTableTemporaryPage_NewRow_NotInDb()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Page.RunModal(Page::"LT P81 PG TempList");
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Observe('db_has_pn', Format(Row.Get('PN')));
        Observer.Observe('temp_has_pn', Format(Temp.Get('PN')));
        Observer.Expect('db_count', '2');
        Observer.Expect('db_has_pn', 'No');
        Observer.Expect('temp_has_pn', 'No');
        Observer.Verify();
    end;
    // Writer PW: RunModal_TempRecord_ShowsTempRows again, later in the codeunit (does the first page run of the codeunit differ?). failure-triage "blank new line for a temp record" (70310 RunModal_TempRecord_ShowsTempRows, corpus #642 item 5).
    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_TempRunModal_ThreeRows_Again()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);

        Observer.Observe('result', Format(Page.RunModal(Page::"LT P81 PG List", Temp)));
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_rows', '3');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('temp_count', '3');
        Observer.Expect('db_count', '2');
        Observer.Verify();
    end;

    // Writer PW: two temporary rows, positioned on the first.
    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_TempRunModal_TwoRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Temp.Get('T3');
        Temp.Delete();
        Temp.FindFirst();
        Observer.Observe('result', Format(Page.RunModal(Page::"LT P81 PG List", Temp)));
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_rows', '2');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('temp_count', '2');
        Observer.Expect('db_count', '2');
        Observer.Verify();
    end;

    // Writer PW: one temporary row.
    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_TempRunModal_OneRow()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Temp.Get('T3');
        Temp.Delete();
        Temp.Get('T2');
        Temp.Delete();
        Temp.FindFirst();
        Observer.Observe('result', Format(Page.RunModal(Page::"LT P81 PG List", Temp)));
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_rows', '1');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('temp_count', '1');
        Observer.Expect('db_count', '2');
        Observer.Verify();
    end;

    // Writer PW: three temporary rows, positioned on the last.
    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_TempRunModal_PositionedOnLast()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Temp.FindLast();
        Observer.Observe('result', Format(Page.RunModal(Page::"LT P81 PG List", Temp)));
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_rows', '3');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('temp_count', '3');
        Observer.Expect('db_count', '2');
        Observer.Verify();
    end;

    // Writer PW: three temporary rows, the record holds a key before every row.
    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_TempRunModal_KeyBeforeAllRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Temp.Init();
        Temp.Code := 'A0';
        Observer.Observe('result', Format(Page.RunModal(Page::"LT P81 PG List", Temp)));
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_rows', '3');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('temp_count', '3');
        Observer.Expect('db_count', '2');
        Observer.Verify();
    end;

    // Writer PW: three temporary rows, the record holds a key after every row.
    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_TempRunModal_KeyAfterAllRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Temp.Init();
        Temp.Code := 'Z9';
        Observer.Observe('result', Format(Page.RunModal(Page::"LT P81 PG List", Temp)));
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_rows', '3');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('temp_count', '3');
        Observer.Expect('db_count', '2');
        Observer.Verify();
    end;

    // Writer PW: three temporary rows, the stored table empty.
    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_TempRunModal_TableEmpty()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Row.DeleteAll();
        Observer.Observe('result', Format(Page.RunModal(Page::"LT P81 PG List", Temp)));
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_rows', '3');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('temp_count', '3');
        Observer.Expect('db_count', '0');
        Observer.Verify();
    end;

    // Writer PW: three temporary rows, a filter that keeps all three.
    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_TempRunModal_FilterKeepsAll()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Temp.SetFilter(Qty, '>=1');
        Observer.Observe('result', Format(Page.RunModal(Page::"LT P81 PG List", Temp)));
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_rows', '3');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('temp_count', '3');
        Observer.Expect('db_count', '2');
        Observer.Verify();
    end;

    // Writer PW: three temporary rows, a filter on the key that keeps all three.
    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_TempRunModal_KeyFilterKeepsAll()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Temp.SetFilter(Code, 'T*');
        Observer.Observe('result', Format(Page.RunModal(Page::"LT P81 PG List", Temp)));
        Observer.Observe('temp_count', Format(Temp.Count()));
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_rows', '3');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('temp_count', '3');
        Observer.Expect('db_count', '2');
        Observer.Verify();
    end;

    // Writer PW: the stored table with three rows (D1, D2, D3), no filter: RunModal_NonTempRecord_ShowsDbRows has two and shows the new line.
    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_NonTempRunModal_ThreeRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Row.Code := 'D3';
        Row.Name := 'db-three';
        Row.Qty := 30;
        Row.Insert();
        Row.FindFirst();
        Observer.Observe('result', Format(Page.RunModal(Page::"LT P81 PG List", Row)));
        Observer.Expect('page_row1', 'D1|db-one|10');
        Observer.Expect('page_row2', 'D2|db-two|20');
        Observer.Expect('page_row3', 'D3|db-three|30');
        Observer.Expect('page_rows', '3');
        Observer.Expect('result', 'LookupOK');
        Observer.Verify();
    end;

    // Writer PW: Page.Run (not modal) of the same three temporary rows.
    [Test]
    [HandlerFunctions('NonModalHandler')]
    procedure PW_TempRun_ThreeRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Page.Run(Page::"LT P81 PG List", Temp);
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_row4', '||0');
        Observer.Expect('page_rows', '4');
        Observer.Verify();
    end;
    // Writer PW: the tests above suggest the new line depends on whether the result of RunModal is used (ShowsTempRows and the PW_ tests use
    // it: no new line; EditWritesToTemp, WithFilter, NonTempRecord_ShowsDbRows run it as a statement: a new line). The same page and rows
    // with RunModal as a statement, inside an if, and on a page variable with and without its result used and with LookupMode.
    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_TempRunModal_Statement()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        Page.RunModal(Page::"LT P81 PG List", Temp);
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_row4', '||0');
        Observer.Expect('page_rows', '4');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_TempRunModal_InIf()
    var
        Temp: Record "LT P81 PG Row" temporary;
    begin
        Seed(Temp);
        if Page.RunModal(Page::"LT P81 PG List", Temp) = Action::LookupOK then
            Observer.Observe('if', 'LookupOK')
        else
            Observer.Observe('if', 'other');
        Observer.Expect('page_row1', 'T1|temp-one|1');
        Observer.Expect('page_row2', 'T2|temp-two|2');
        Observer.Expect('page_row3', 'T3|temp-three|3');
        Observer.Expect('page_rows', '3');
        Observer.Expect('if', 'LookupOK');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_NonTempRunModal_Statement_ThreeRows()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Row: Record "LT P81 PG Row";
    begin
        Seed(Temp);
        Row.Code := 'D3';
        Row.Name := 'db-three';
        Row.Qty := 30;
        Row.Insert();
        Row.FindFirst();
        Page.RunModal(Page::"LT P81 PG List", Row);
        Observer.Expect('page_row1', 'D1|db-one|10');
        Observer.Expect('page_row2', 'D2|db-two|20');
        Observer.Expect('page_row3', 'D3|db-three|30');
        Observer.Expect('page_row4', '||0');
        Observer.Expect('page_rows', '4');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_PageVar_RunModal_ResultUsed()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Pg.SetTableView(Temp);
        Observer.Observe('result', Format(Pg.RunModal()));
        Observer.Expect('page_row1', 'D1|db-one|10');
        Observer.Expect('page_row2', 'D2|db-two|20');
        Observer.Expect('page_row3', '||0');
        Observer.Expect('page_rows', '3');
        Observer.Expect('result', 'OK');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_PageVar_RunModal_Statement()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Pg.SetTableView(Temp);
        Pg.RunModal();
        Observer.Expect('page_row1', 'D1|db-one|10');
        Observer.Expect('page_row2', 'D2|db-two|20');
        Observer.Expect('page_row3', '||0');
        Observer.Expect('page_rows', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_PageVar_RunModal_LookupModeStatement()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Pg.LookupMode(true);
        Pg.RunModal();
        Observer.Expect('page_row1', 'D1|db-one|10');
        Observer.Expect('page_row2', 'D2|db-two|20');
        Observer.Expect('page_rows', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadRowsHandler')]
    procedure PW_PageVar_RunModal_NoLookupModeResultUsed()
    var
        Temp: Record "LT P81 PG Row" temporary;
        Pg: Page "LT P81 PG List";
    begin
        Seed(Temp);
        Pg.LookupMode(false);
        Observer.Observe('result', Format(Pg.RunModal()));
        Observer.Expect('page_row1', 'D1|db-one|10');
        Observer.Expect('page_row2', 'D2|db-two|20');
        Observer.Expect('page_row3', '||0');
        Observer.Expect('page_rows', '3');
        Observer.Expect('result', 'OK');
        Observer.Verify();
    end;
}
