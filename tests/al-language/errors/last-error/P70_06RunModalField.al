// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 72065 and page 72066 (P70_01Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Page.RunModal(PageId, Rec, Field) with a field argument, RunModal vs Run, what the handler sees, returned Action
// BC versions: 29 (27 and 28 by CI)

codeunit 72075 "LT P70 RunModal Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HandlerMode: Integer;

    local procedure Seed()
    var
        Row: Record "LT P70 Row";
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

    [ModalPageHandler]
    procedure ListHandler(var ListPage: TestPage "LT P70 Row List")
    var
        n: Integer;
    begin
        Observer.Observe('h_code', ListPage.Code.Value);
        Observer.Observe('h_name', ListPage.Name.Value);
        n := 0;
        if ListPage.First() then
            repeat
                n += 1;
            until not ListPage.Next();
        Observer.Observe('h_rows', Format(n));
        if ListPage.GoToKey('C') then
            Observer.Observe('h_goto_c', ListPage.Name.Value);
        case HandlerMode of
            0:
                ListPage.OK().Invoke();
            1:
                ListPage.Cancel().Invoke();
        end;
    end;

    [PageHandler]
    procedure ListRunHandler(var ListPage: TestPage "LT P70 Row List")
    begin
        Observer.Observe('r_code', ListPage.Code.Value);
        Observer.Observe('r_name', ListPage.Name.Value);
    end;

    [Test]
    procedure RunModal_RecOnly()
    var
        Row: Record "LT P70 Row";
        Act: Action;
    begin
        Seed();
        HandlerMode := 0;
        Row.Get('B');
        asserterror Act := Page.RunModal(Page::"LT P70 Row List", Row);
        Observer.ObserveError('af76');
        Observer.Observe('action', Format(Act));
        Observer.Observe('rec_code_after', Row."Code");
        Observer.Observe('rec_name_after', Row.Name);
        Observer.Expect('af76|text', 'Unhandled UI: ModalPage 72066');
        Observer.Expect('af76|code', 'MissingUIHandler');
        Observer.Expect('action', 'None');
        Observer.Expect('rec_code_after', 'B');
        Observer.Expect('rec_name_after', 'Beta');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_FieldArgument_OK()
    var
        Row: Record "LT P70 Row";
        Act: Action;
    begin
        Seed();
        HandlerMode := 0;
        Row.Get('B');
        Row.Name := 'Mutated';
        asserterror Act := Page.RunModal(Page::"LT P70 Row List", Row, Row.Name);
        Observer.ObserveError('af94');
        Observer.Observe('action', Format(Act));
        Observer.Observe('rec_code_after', Row."Code");
        Observer.Observe('rec_name_after', Row.Name);
        Observer.Observe('db_name_b', GetName('B'));
        Observer.Expect('af94|text', 'Unhandled UI: ModalPage 72066');
        Observer.Expect('af94|code', 'MissingUIHandler');
        Observer.Expect('action', 'None');
        Observer.Expect('rec_code_after', 'B');
        Observer.Expect('rec_name_after', 'Mutated');
        Observer.Expect('db_name_b', '<missing>');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_FieldArgument_Cancel()
    var
        Row: Record "LT P70 Row";
        Act: Action;
    begin
        Seed();
        HandlerMode := 1;
        Row.Get('B');
        asserterror Act := Page.RunModal(Page::"LT P70 Row List", Row, Row.Name);
        Observer.ObserveError('af112');
        Observer.Observe('action', Format(Act));
        Observer.Observe('rec_name_after', Row.Name);
        Observer.Expect('af112|text', 'Unhandled UI: ModalPage 72066');
        Observer.Expect('af112|code', 'MissingUIHandler');
        Observer.Expect('action', 'None');
        Observer.Expect('rec_name_after', 'Beta');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_FieldArgument_LookupOK()
    var
        Row: Record "LT P70 Row";
        Act: Action;
    begin
        Seed();
        HandlerMode := 2;
        Row.Get('A');
        asserterror Act := Page.RunModal(Page::"LT P70 Row List", Row, Row.Qty);
        Observer.ObserveError('af128');
        Observer.Observe('action', Format(Act));
        Observer.Observe('rec_code_after', Row."Code");
        Observer.Observe('rec_qty_after', Format(Row.Qty));
        Observer.Expect('af128|text', 'Unhandled UI: ModalPage 72066');
        Observer.Expect('af128|code', 'MissingUIHandler');
        Observer.Expect('action', 'None');
        Observer.Expect('rec_code_after', 'A');
        Observer.Expect('rec_qty_after', '1');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_WithFilterOnRecord()
    var
        Row: Record "LT P70 Row";
        Act: Action;
    begin
        Seed();
        HandlerMode := 0;
        Row.SetFilter(Qty, '>=2');
        Row.FindFirst();
        asserterror Act := Page.RunModal(Page::"LT P70 Row List", Row, Row.Name);
        Observer.ObserveError('af146');
        Observer.Observe('action', Format(Act));
        Observer.Observe('rec_filter', Row.GetFilters());
        Observer.Expect('af146|text', 'Unhandled UI: ModalPage 72066');
        Observer.Expect('af146|code', 'MissingUIHandler');
        Observer.Expect('action', 'None');
        Observer.Expect('rec_filter', 'Qty: >=2');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_EmptyRecAndMissingKey()
    var
        Row: Record "LT P70 Row";
        Act: Action;
    begin
        Seed();
        HandlerMode := 0;
        Clear(Row);
        asserterror Act := Page.RunModal(Page::"LT P70 Row List", Row, Row.Name);
        Observer.ObserveError('af162');
        Observer.Observe('empty_action', Format(Act));
        Row.Code := 'ZZZ';
        asserterror Act := Page.RunModal(Page::"LT P70 Row List", Row, Row.Name);
        Observer.ObserveError('af166');
        Observer.Observe('missing_action', Format(Act));
        Observer.Expect('af162|text', 'Unhandled UI: ModalPage 72066');
        Observer.Expect('af162|code', 'MissingUIHandler');
        Observer.Expect('empty_action', 'None');
        Observer.Expect('af166|text', 'Unhandled UI: ModalPage 72066');
        Observer.Expect('af166|code', 'MissingUIHandler');
        Observer.Expect('missing_action', 'None');
        Observer.Verify();
    end;

    [Test]
    procedure PageRun_VsRunModal()
    var
        Row: Record "LT P70 Row";
    begin
        Seed();
        Row.Get('C');
        asserterror Page.Run(Page::"LT P70 Row List", Row);
        Observer.ObserveError('af178');
        Observer.Observe('after_run', 'returned');
        Observer.Expect('af178|text', 'Unhandled UI: Page 72066');
        Observer.Expect('af178|code', 'MissingUIHandler');
        Observer.Expect('after_run', 'returned');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_UnknownPageId()
    var
        Row: Record "LT P70 Row";
        Act: Action;
    begin
        Seed();
        Row.Get('A');
        asserterror Act := Page.RunModal(72499, Row, Row.Name);
        Observer.ObserveError('unknown_page');
        asserterror Page.Run(72499, Row);
        Observer.ObserveError('unknown_page_run');
        asserterror Act := Page.RunModal(0, Row, Row.Name);
        Observer.ObserveError('page_zero');
        Observer.Expect('unknown_page|text', 'You tried to invoke the Page object with the ID 72499 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('unknown_page|code', 'AL:MetadataNotFound');
        Observer.Expect('unknown_page_run|text', 'You tried to invoke the Page object with the ID 72499 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('unknown_page_run|code', 'AL:MetadataNotFound');
        Observer.Expect('page_zero|text', 'You tried to invoke the Page object with the ID 0 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('page_zero|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    local procedure GetName(KeyCode: Code[10]): Text
    var
        Row: Record "LT P70 Row";
    begin
        if Row.Get(KeyCode) then
            exit(Row.Name);
        exit('<missing>');
    end;
}
