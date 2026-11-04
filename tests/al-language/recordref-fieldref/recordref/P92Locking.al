// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-recordlevellocking-method
// Scope: in-scope
// Fixtures used: tables 72200-72201, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against BC 29 (draft, measured later by the lead).
// Facts: RecordRef.RecordLevelLocking, ReadConsistency, SecurityFiltering get and set (RecordRef and Record side by side)
// BC versions: 29 (27 and 28 by CI)

codeunit 72217 "LT P92 Locking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RecordLevelLocking_Tables()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        RecRef.Open(72200);
        Observer.Observe('item', Format(RecRef.RecordLevelLocking()));
        Observer.Observe('item_record', Format(Item.RecordLevelLocking()));
        RecRef.Close();
        RecRef.Open(72201);
        Observer.Observe('pair', Format(RecRef.RecordLevelLocking()));
        RecRef.Close();
        RecRef.Open(72200, true);
        Observer.Observe('item_temp', Format(RecRef.RecordLevelLocking()));
        RecRef.Close();
        Observer.Expect('item', 'Yes');
        Observer.Expect('item_record', 'Yes');
        Observer.Expect('pair', 'Yes');
        Observer.Expect('item_temp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordLevelLocking_Unopened()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        B: Boolean;
    begin
        asserterror B := RecRef.RecordLevelLocking();
        Observer.ObserveError('unopened');
        Observer.Expect('unopened|text', 'The record is not open.');
        Observer.Expect('unopened|code', 'RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure ReadConsistency_Tables()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        RecRef.Open(72200);
        Observer.Observe('item', Format(RecRef.ReadConsistency()));
        Observer.Observe('item_record', Format(Item.ReadConsistency()));
        RecRef.Close();
        RecRef.Open(72200, true);
        Observer.Observe('item_temp', Format(RecRef.ReadConsistency()));
        RecRef.Close();
        Observer.Expect('item', 'No');
        Observer.Expect('item_record', 'No');
        Observer.Expect('item_temp', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SecurityFiltering_GetSet()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        RecRef.Open(72200);
        Observer.Observe('recref_default', Format(RecRef.SecurityFiltering()));
        Observer.Observe('record_default', Format(Item.SecurityFiltering()));
        RecRef.SecurityFiltering(SecurityFilter::Filtered);
        Observer.Observe('recref_filtered', Format(RecRef.SecurityFiltering()));
        RecRef.SecurityFiltering(SecurityFilter::Ignored);
        Observer.Observe('recref_ignored', Format(RecRef.SecurityFiltering()));
        RecRef.SecurityFiltering(SecurityFilter::Validated);
        Observer.Observe('recref_validated', Format(RecRef.SecurityFiltering()));
        RecRef.Close();
        Observer.Expect('recref_default', 'Validated');
        Observer.Expect('record_default', 'Validated');
        Observer.Expect('recref_filtered', 'Filtered');
        Observer.Expect('recref_ignored', 'Ignored');
        Observer.Expect('recref_validated', 'Validated');
        Observer.Verify();
    end;
}
