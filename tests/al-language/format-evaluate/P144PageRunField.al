// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 74810, pages 74800 and 74801
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Page.Run(Page, Rec, Field) and Page.RunModal(Page, Rec, Field) under a PageHandler / ModalPageHandler: what the handler sees through the TestPage
// (current record, field values, Editable and Visible of fields, returned Action, record after the call); the focus control is not observable.
// BC versions: 29 (27 and 28 by CI)

table 70237 "LT P144 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Hidden; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 70239 "LT P144 Row List"
{
    PageType = List;
    SourceTable = "LT P144 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; Editable = false; }
                field(Hidden; Rec.Hidden) { ApplicationArea = All; Visible = false; }
            }
        }
    }
}

page 70240 "LT P144 Row Card"
{
    PageType = Card;
    SourceTable = "LT P144 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; Editable = false; }
                field(Hidden; Rec.Hidden) { ApplicationArea = All; Visible = false; }
            }
        }
    }
}

codeunit 70235 "LT P144 Page Run Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT P144 Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Code := 'A';
        Row.Name := 'Alpha';
        Row.Qty := 1;
        Row.Insert();
        Row.Code := 'B';
        Row.Name := 'Beta';
        Row.Qty := 2;
        Row.Insert();
        Row.Code := 'C';
        Row.Name := 'Gamma';
        Row.Qty := 3;
        Row.Insert();
    end;

    local procedure ObserveList(Prefix: Text; var ListPage: TestPage "LT P144 Row List")
    begin
        Observer.Observe(Prefix + 'code', ListPage.Code.Value);
        Observer.Observe(Prefix + 'name', ListPage.Name.Value);
        Observer.Observe(Prefix + 'qty', ListPage.Qty.Value);
        Observer.Observe(Prefix + 'name_editable', Format(ListPage.Name.Editable()));
        Observer.Observe(Prefix + 'qty_editable', Format(ListPage.Qty.Editable()));
        Observer.Observe(Prefix + 'hidden_visible', Format(ListPage.Hidden.Visible()));
        Observer.Observe(Prefix + 'name_visible', Format(ListPage.Name.Visible()));
    end;

    local procedure ObserveCard(Prefix: Text; var CardPage: TestPage "LT P144 Row Card")
    begin
        Observer.Observe(Prefix + 'code', CardPage.Code.Value);
        Observer.Observe(Prefix + 'name', CardPage.Name.Value);
        Observer.Observe(Prefix + 'qty', CardPage.Qty.Value);
        Observer.Observe(Prefix + 'name_editable', Format(CardPage.Name.Editable()));
        Observer.Observe(Prefix + 'qty_editable', Format(CardPage.Qty.Editable()));
        Observer.Observe(Prefix + 'hidden_visible', Format(CardPage.Hidden.Visible()));
    end;

    [PageHandler]
    procedure ListRunHandler(var ListPage: TestPage "LT P144 Row List")
    var
        n: Integer;
    begin
        ObserveList('h_', ListPage);
        n := 0;
        if ListPage.First() then
            repeat
                n += 1;
            until not ListPage.Next();
        Observer.Observe('h_rows', Format(n));
    end;

    [PageHandler]
    procedure CardRunHandler(var CardPage: TestPage "LT P144 Row Card")
    begin
        ObserveCard('h_', CardPage);
    end;

    [ModalPageHandler]
    procedure ListModalOkHandler(var ListPage: TestPage "LT P144 Row List")
    begin
        ObserveList('h_', ListPage);
        ListPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ListModalCancelHandler(var ListPage: TestPage "LT P144 Row List")
    begin
        ObserveList('h_', ListPage);
        ListPage.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure CardModalOkHandler(var CardPage: TestPage "LT P144 Row Card")
    begin
        ObserveCard('h_', CardPage);
        CardPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CardModalEditHandler(var CardPage: TestPage "LT P144 Row Card")
    begin
        ObserveCard('h_before_', CardPage);
        CardPage.Name.SetValue('Changed');
        ObserveCard('h_after_', CardPage);
        CardPage.OK().Invoke();
    end;

    local procedure DbName(KeyCode: Code[10]): Text
    var
        Row: Record "LT P144 Row";
    begin
        if Row.Get(KeyCode) then
            exit(Row.Name);
        exit('<missing>');
    end;

    [Test]
    [HandlerFunctions('ListRunHandler')]
    procedure P144_PageRun_ListWithField()
    var
        Row: Record "LT P144 Row";
    begin
        Seed();
        Row.Get('B');
        asserterror Page.Run(Page::"LT P144 Row List", Row, Row.Name);
        Observer.ObserveError('af182');
        Observer.Expect('h_code', 'B');
        Observer.Expect('h_name', 'Beta');
        Observer.Expect('h_qty', '2');
        Observer.Expect('h_name_editable', 'Yes');
        Observer.Expect('h_qty_editable', 'No');
        Observer.Expect('af182|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af182|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListRunHandler')]
    procedure P144_PageRun_ListWithQtyField()
    var
        Row: Record "LT P144 Row";
    begin
        Seed();
        Row.Get('B');
        asserterror Page.Run(Page::"LT P144 Row List", Row, Row.Qty);
        Observer.ObserveError('af195');
        Observer.Expect('h_code', 'B');
        Observer.Expect('h_name', 'Beta');
        Observer.Expect('h_qty', '2');
        Observer.Expect('h_name_editable', 'Yes');
        Observer.Expect('h_qty_editable', 'No');
        Observer.Expect('af195|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af195|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListRunHandler')]
    procedure P144_PageRun_ListWithoutField()
    var
        Row: Record "LT P144 Row";
    begin
        Seed();
        Row.Get('B');
        asserterror Page.Run(Page::"LT P144 Row List", Row);
        Observer.ObserveError('af208');
        Observer.Expect('h_code', 'B');
        Observer.Expect('h_name', 'Beta');
        Observer.Expect('h_qty', '2');
        Observer.Expect('h_name_editable', 'Yes');
        Observer.Expect('h_qty_editable', 'No');
        Observer.Expect('af208|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af208|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListRunHandler')]
    procedure P144_PageRun_FilteredRecordWithField()
    var
        Row: Record "LT P144 Row";
    begin
        Seed();
        Row.SetFilter(Qty, '>=2');
        Row.FindFirst();
        asserterror Page.Run(Page::"LT P144 Row List", Row, Row.Name);
        Observer.ObserveError('af222');
        Observer.Observe('rec_filter_after', Row.GetFilters());
        Observer.Expect('h_code', 'B');
        Observer.Expect('h_name', 'Beta');
        Observer.Expect('h_qty', '2');
        Observer.Expect('h_name_editable', 'Yes');
        Observer.Expect('h_qty_editable', 'No');
        Observer.Expect('af222|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af222|code', 'TestFieldNotFound');
        Observer.Expect('rec_filter_after', 'Qty: >=2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardRunHandler')]
    procedure P144_PageRun_CardWithField()
    var
        Row: Record "LT P144 Row";
    begin
        Seed();
        Row.Get('C');
        asserterror Page.Run(Page::"LT P144 Row Card", Row, Row.Name);
        Observer.ObserveError('af236');
        Observer.Expect('h_code', 'C');
        Observer.Expect('h_name', 'Gamma');
        Observer.Expect('h_qty', '3');
        Observer.Expect('h_name_editable', 'Yes');
        Observer.Expect('h_qty_editable', 'No');
        Observer.Expect('af236|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af236|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModalOkHandler')]
    procedure P144_RunModal_ListWithField_OK()
    var
        Row: Record "LT P144 Row";
        Act: Action;
    begin
        Seed();
        Row.Get('B');
        asserterror Act := Page.RunModal(Page::"LT P144 Row List", Row, Row.Name);
        Observer.ObserveError('af250');
        Observer.Observe('action', Format(Act));
        Observer.Observe('rec_after', Row.Code + '/' + Row.Name);
        Observer.Expect('h_code', 'B');
        Observer.Expect('h_name', 'Beta');
        Observer.Expect('h_qty', '2');
        Observer.Expect('h_name_editable', 'No');
        Observer.Expect('h_qty_editable', 'No');
        Observer.Expect('af250|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af250|code', 'TestFieldNotFound');
        Observer.Expect('action', 'None');
        Observer.Expect('rec_after', 'B/Beta');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModalCancelHandler')]
    procedure P144_RunModal_ListWithField_Cancel()
    var
        Row: Record "LT P144 Row";
        Act: Action;
    begin
        Seed();
        Row.Get('B');
        asserterror Act := Page.RunModal(Page::"LT P144 Row List", Row, Row.Qty);
        Observer.ObserveError('af266');
        Observer.Observe('action', Format(Act));
        Observer.Observe('rec_after', Row.Code + '/' + Row.Name);
        Observer.Expect('h_code', 'B');
        Observer.Expect('h_name', 'Beta');
        Observer.Expect('h_qty', '2');
        Observer.Expect('h_name_editable', 'No');
        Observer.Expect('h_qty_editable', 'No');
        Observer.Expect('af266|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af266|code', 'TestFieldNotFound');
        Observer.Expect('action', 'None');
        Observer.Expect('rec_after', 'B/Beta');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardModalOkHandler')]
    procedure P144_RunModal_CardWithField_OK()
    var
        Row: Record "LT P144 Row";
        Act: Action;
    begin
        Seed();
        Row.Get('A');
        asserterror Act := Page.RunModal(Page::"LT P144 Row Card", Row, Row.Name);
        Observer.ObserveError('af282');
        Observer.Observe('action', Format(Act));
        Observer.Observe('rec_after', Row.Code + '/' + Row.Name);
        Observer.Expect('h_code', 'A');
        Observer.Expect('h_name', 'Alpha');
        Observer.Expect('h_qty', '1');
        Observer.Expect('h_name_editable', 'Yes');
        Observer.Expect('h_qty_editable', 'No');
        Observer.Expect('af282|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af282|code', 'TestFieldNotFound');
        Observer.Expect('action', 'None');
        Observer.Expect('rec_after', 'A/Alpha');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardModalOkHandler')]
    procedure P144_RunModal_CardWithoutField_OK()
    var
        Row: Record "LT P144 Row";
        Act: Action;
    begin
        Seed();
        Row.Get('A');
        asserterror Act := Page.RunModal(Page::"LT P144 Row Card", Row);
        Observer.ObserveError('af298');
        Observer.Observe('action', Format(Act));
        Observer.Observe('rec_after', Row.Code + '/' + Row.Name);
        Observer.Expect('h_code', 'A');
        Observer.Expect('h_name', 'Alpha');
        Observer.Expect('h_qty', '1');
        Observer.Expect('h_name_editable', 'Yes');
        Observer.Expect('h_qty_editable', 'No');
        Observer.Expect('af298|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af298|code', 'TestFieldNotFound');
        Observer.Expect('action', 'None');
        Observer.Expect('rec_after', 'A/Alpha');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardModalEditHandler')]
    procedure P144_RunModal_CardWithField_Edit()
    var
        Row: Record "LT P144 Row";
        Act: Action;
    begin
        Seed();
        Row.Get('A');
        asserterror Act := Page.RunModal(Page::"LT P144 Row Card", Row, Row.Name);
        Observer.ObserveError('af314');
        Observer.Observe('action', Format(Act));
        Observer.Observe('rec_after', Row.Code + '/' + Row.Name);
        Observer.Observe('db_a', DbName('A'));
        Observer.Expect('h_before_code', 'A');
        Observer.Expect('h_before_name', 'Alpha');
        Observer.Expect('h_before_qty', '1');
        Observer.Expect('h_before_name_editable', 'Yes');
        Observer.Expect('h_before_qty_editable', 'No');
        Observer.Expect('af314|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af314|code', 'TestFieldNotFound');
        Observer.Expect('action', 'None');
        Observer.Expect('rec_after', 'A/Alpha');
        Observer.Expect('db_a', '<missing>');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModalOkHandler')]
    procedure P144_RunModal_EmptyRecWithField()
    var
        Row: Record "LT P144 Row";
        Act: Action;
    begin
        Seed();
        Clear(Row);
        asserterror Act := Page.RunModal(Page::"LT P144 Row List", Row, Row.Name);
        Observer.ObserveError('af331');
        Observer.Observe('action', Format(Act));
        Observer.Expect('h_code', 'A');
        Observer.Expect('h_name', 'Alpha');
        Observer.Expect('h_qty', '1');
        Observer.Expect('h_name_editable', 'No');
        Observer.Expect('h_qty_editable', 'No');
        Observer.Expect('af331|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af331|code', 'TestFieldNotFound');
        Observer.Expect('action', 'None');
        Observer.Verify();
    end;

    [Test]
    procedure P144_FieldIsInvisibleOnPage_NoHandler()
    var
        Row: Record "LT P144 Row";
    begin
        Seed();
        Row.Get('B');
        asserterror Page.Run(Page::"LT P144 Row List", Row, Row.Hidden);
        Observer.ObserveError('run_hidden_field_no_handler');
        Observer.Expect('run_hidden_field_no_handler|text', 'Unhandled UI: Page 70239');
        Observer.Expect('run_hidden_field_no_handler|code', 'MissingUIHandler');
        Observer.Verify();
    end;
}
