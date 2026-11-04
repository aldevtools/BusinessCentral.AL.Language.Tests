// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-readisolation-method
// Scope: in-scope
// Fixtures used: table 72200, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against BC 29 (draft, measured later by the lead).
// Facts: RecordRef.ReadIsolation get and set (default, each level, after Close/Open, copy of the variable)
// BC versions: 29 (27 and 28 by CI)

codeunit 72216 "LT P92 ReadIsolation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ReadIsolation_AllLevels()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(72200);
        Observer.Observe('default', Format(RecRef.ReadIsolation));
        RecRef.ReadIsolation := IsolationLevel::ReadUncommitted;
        Observer.Observe('ReadUncommitted', Format(RecRef.ReadIsolation));
        RecRef.ReadIsolation := IsolationLevel::ReadCommitted;
        Observer.Observe('ReadCommitted', Format(RecRef.ReadIsolation));
        RecRef.ReadIsolation := IsolationLevel::RepeatableRead;
        Observer.Observe('RepeatableRead', Format(RecRef.ReadIsolation));
        RecRef.ReadIsolation := IsolationLevel::UpdLock;
        Observer.Observe('UpdLock', Format(RecRef.ReadIsolation));
        RecRef.ReadIsolation := IsolationLevel::Default;
        Observer.Observe('back_to_default', Format(RecRef.ReadIsolation));
        RecRef.Close();
        Observer.Expect('default', 'Default');
        Observer.Expect('ReadUncommitted', 'ReadUncommitted');
        Observer.Expect('ReadCommitted', 'ReadCommitted');
        Observer.Expect('RepeatableRead', 'RepeatableRead');
        Observer.Expect('UpdLock', 'UpdLock');
        Observer.Expect('back_to_default', 'Default');
        Observer.Verify();
    end;

    [Test]
    procedure ReadIsolation_FromRecordAndToRecord()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
        Back: Record "LT P92 Item";
    begin
        Item.ReadIsolation := IsolationLevel::RepeatableRead;
        RecRef.GetTable(Item);
        Observer.Observe('gettable_carries', Format(RecRef.ReadIsolation));
        RecRef.ReadIsolation := IsolationLevel::ReadCommitted;
        RecRef.SetTable(Back);
        Observer.Observe('settable_carries', Format(Back.ReadIsolation));
        Observer.Observe('record_unchanged', Format(Item.ReadIsolation));
        RecRef.Close();
        Observer.Expect('gettable_carries', 'RepeatableRead');
        Observer.Expect('settable_carries', 'ReadCommitted');
        Observer.Expect('record_unchanged', 'RepeatableRead');
        Observer.Verify();
    end;

    [Test]
    procedure ReadIsolation_CopyOfVariable()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Copy: RecordRef;
    begin
        RecRef.Open(72200);
        RecRef.ReadIsolation := IsolationLevel::UpdLock;
        Copy := RecRef;
        Observer.Observe('copy', Format(Copy.ReadIsolation));
        Copy.ReadIsolation := IsolationLevel::ReadCommitted;
        Observer.Observe('original_after_copy_change', Format(RecRef.ReadIsolation));
        RecRef.Close();
        Observer.Expect('copy', 'UpdLock');
        Observer.Expect('original_after_copy_change', 'ReadCommitted');
        Observer.Verify();
    end;

    [Test]
    procedure ReadIsolation_Unopened()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        L: IsolationLevel;
    begin
        asserterror L := RecRef.ReadIsolation;
        Observer.ObserveError('get_unopened');
        asserterror RecRef.ReadIsolation := IsolationLevel::UpdLock;
        Observer.ObserveError('set_unopened');
        Observer.Expect('get_unopened|text', 'The record is not open.');
        Observer.Expect('get_unopened|code', 'RecordNotOpened');
        Observer.Expect('set_unopened|text', 'The record is not open.');
        Observer.Expect('set_unopened|code', 'RecordNotOpened');
        Observer.Verify();
    end;
}
