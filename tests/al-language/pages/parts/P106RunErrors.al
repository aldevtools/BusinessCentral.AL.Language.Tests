// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P106 Item/Group tables, LT P106 Log codeunit, pages LT P106 Card / List from P106Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: error paths of static Page.Run / Page.RunModal: unknown page number, a record of another table, field numbers that do not exist, an uninitialized FieldRef, a FieldRef of another table. No handler is declared: when the call gets as far as opening the page the error is the missing handler, which says the arguments were accepted
// BC versions: 29 (27 and 28 by CI)

codeunit 72411 "LT P106 Run Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P106 Log";

    [Test]
    procedure P106_Err_UnknownPage()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Act: Action;
    begin
        Log.Seed();
        asserterror Act := Page.RunModal(72499);
        Observer.ObserveError('runmodal_num');
        asserterror Page.Run(72499);
        Observer.ObserveError('run_num');
        asserterror Act := Page.RunModal(72499, Item);
        Observer.ObserveError('runmodal_rec');
        asserterror Page.Run(72499, Item);
        Observer.ObserveError('run_rec');
        asserterror Act := Page.RunModal(72499, Item, 1);
        Observer.ObserveError('runmodal_fieldno');
        asserterror Page.Run(72499, Item, 1);
        Observer.ObserveError('run_fieldno');
        asserterror Act := Page.RunModal(0, Item, 1);
        Observer.ObserveError('runmodal_zero');
        asserterror Page.Run(-1, Item, 1);
        Observer.ObserveError('run_negative');
        Observer.Expect('runmodal_num|text', 'You tried to invoke the Page object with the ID 72499 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('runmodal_num|code', 'AL:MetadataNotFound');
        Observer.Expect('run_num|text', 'You tried to invoke the Page object with the ID 72499 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run_num|code', 'AL:MetadataNotFound');
        Observer.Expect('runmodal_rec|text', 'You tried to invoke the Page object with the ID 72499 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('runmodal_rec|code', 'AL:MetadataNotFound');
        Observer.Expect('run_rec|text', 'You tried to invoke the Page object with the ID 72499 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run_rec|code', 'AL:MetadataNotFound');
        Observer.Expect('runmodal_fieldno|text', 'You tried to invoke the Page object with the ID 72499 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('runmodal_fieldno|code', 'AL:MetadataNotFound');
        Observer.Expect('run_fieldno|text', 'You tried to invoke the Page object with the ID 72499 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run_fieldno|code', 'AL:MetadataNotFound');
        Observer.Expect('runmodal_zero|text', 'Unhandled UI: ModalPage 72401');
        Observer.Expect('runmodal_zero|code', 'MissingUIHandler');
        Observer.Expect('run_negative|text', 'You tried to invoke the Page object with the ID -1 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run_negative|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P106_Err_WrongTableRecord()
    var
        Observer: Codeunit "Probe Observer";
        Grp: Record "LT P106 Group";
        Act: Action;
    begin
        Log.Seed();
        Grp.FindFirst();
        asserterror Act := Page.RunModal(Page::"LT P106 List", Grp);
        Observer.ObserveError('runmodal_rec');
        asserterror Page.Run(Page::"LT P106 List", Grp);
        Observer.ObserveError('run_rec');
        asserterror Act := Page.RunModal(Page::"LT P106 List", Grp, 1);
        Observer.ObserveError('runmodal_fieldno');
        asserterror Page.Run(Page::"LT P106 Card", Grp, 1);
        Observer.ObserveError('run_fieldno');
        asserterror Act := Page.RunModal(Page::"LT P106 List", Grp, Grp.Descr);
        Observer.ObserveError('runmodal_any');
        Observer.Expect('runmodal_rec|text', 'The table IDs do not match.');
        Observer.Expect('runmodal_rec|code', 'TableIdMismatch');
        Observer.Expect('run_rec|text', 'The table IDs do not match.');
        Observer.Expect('run_rec|code', 'TableIdMismatch');
        Observer.Expect('runmodal_fieldno|text', 'The table IDs do not match.');
        Observer.Expect('runmodal_fieldno|code', 'TableIdMismatch');
        Observer.Expect('run_fieldno|text', 'The table IDs do not match.');
        Observer.Expect('run_fieldno|code', 'TableIdMismatch');
        Observer.Expect('runmodal_any|text', 'The table IDs do not match.');
        Observer.Expect('runmodal_any|code', 'TableIdMismatch');
        Observer.Verify();
    end;

    [Test]
    procedure P106_Err_FieldNoNotExisting()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Act: Action;
    begin
        Log.Seed();
        Item.Get('A');
        asserterror Act := Page.RunModal(Page::"LT P106 List", Item, 999);
        Observer.ObserveError('runmodal_999');
        asserterror Act := Page.RunModal(Page::"LT P106 List", Item, -1);
        Observer.ObserveError('runmodal_neg');
        asserterror Act := Page.RunModal(Page::"LT P106 List", Item, 0);
        Observer.ObserveError('runmodal_zero');
        asserterror Page.Run(Page::"LT P106 List", Item, 999);
        Observer.ObserveError('run_999');
        asserterror Page.Run(Page::"LT P106 List", Item, -1);
        Observer.ObserveError('run_neg');
        asserterror Page.Run(Page::"LT P106 List", Item, 0);
        Observer.ObserveError('run_zero');
        Observer.Expect('runmodal_999|text', 'The supplied field number ''999'' cannot be found in the ''LT P106 Item'' table.');
        Observer.Expect('runmodal_999|code', 'FieldNotFound');
        Observer.Expect('runmodal_neg|text', 'Unhandled UI: ModalPage 72401');
        Observer.Expect('runmodal_neg|code', 'MissingUIHandler');
        Observer.Expect('runmodal_zero|text', 'Unhandled UI: ModalPage 72401');
        Observer.Expect('runmodal_zero|code', 'MissingUIHandler');
        Observer.Expect('run_999|text', 'The supplied field number ''999'' cannot be found in the ''LT P106 Item'' table.');
        Observer.Expect('run_999|code', 'FieldNotFound');
        Observer.Expect('run_neg|text', 'Unhandled UI: Page 72401');
        Observer.Expect('run_neg|code', 'MissingUIHandler');
        Observer.Expect('run_zero|text', 'Unhandled UI: Page 72401');
        Observer.Expect('run_zero|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    procedure P106_Err_FieldRefVariants()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Grp: Record "LT P106 Group";
        RecRef: RecordRef;
        GrpRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Log.Seed();
        Item.Get('A');
        asserterror Act := Page.RunModal(Page::"LT P106 List", Item, FR);
        Observer.ObserveError('uninitialized');
        asserterror Grp.FindFirst();
        Observer.ObserveError('af104');
        GrpRef.GetTable(Grp);
        FR := GrpRef.Field(Grp.FieldNo(Descr));
        asserterror Act := Page.RunModal(Page::"LT P106 List", Item, FR);
        Observer.ObserveError('other_table');
        RecRef.GetTable(Item);
        FR := RecRef.Field(Item.FieldNo(Name));
        asserterror Act := Page.RunModal(Page::"LT P106 List", Grp, FR);
        Observer.ObserveError('record_other_table');
        asserterror Act := Page.RunModal(72499, Item, FR);
        Observer.ObserveError('unknown_page');
        Observer.Expect('uninitialized|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('uninitialized|code', 'NotInitialized');
        Observer.Expect('af104|text', 'The LT P106 Group table is empty.');
        Observer.Expect('af104|code', 'DB:TableIsEmpty');
        Observer.Expect('other_table|text', 'Unhandled UI: ModalPage 72401');
        Observer.Expect('other_table|code', 'MissingUIHandler');
        Observer.Expect('record_other_table|text', 'The table IDs do not match.');
        Observer.Expect('record_other_table|code', 'TableIdMismatch');
        Observer.Expect('unknown_page|text', 'You tried to invoke the Page object with the ID 72499 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('unknown_page|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;
}
