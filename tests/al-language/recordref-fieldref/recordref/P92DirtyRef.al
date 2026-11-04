// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: tables 72200, 72202, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against BC 29 (draft, measured later by the lead).
// Facts: IsDirty of a RecordRef (unsure the member exists: drop this file when it does not compile)
// BC versions: 29 (27 and 28 by CI)

#if BC28PLUS
codeunit 72220 "LT P92 Dirty Ref"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure IsDirty_FieldChanges()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        Observer.Observe('fresh', Format(RecRef.IsDirty()));
        RecRef.Field(1).SetRange('A1');
        RecRef.FindFirst();
        Observer.Observe('after_find', Format(RecRef.IsDirty()));
        RecRef.Field(2).Value := 'Alpha';
        Observer.Observe('same_value', Format(RecRef.IsDirty()));
        RecRef.Field(2).Value := 'Changed';
        Observer.Observe('changed_value', Format(RecRef.IsDirty()));
        RecRef.Modify();
        Observer.Observe('after_modify', Format(RecRef.IsDirty()));
        RecRef.Field(3).Value := 99;
        Observer.Observe('changed_qty', Format(RecRef.IsDirty()));
        RecRef.FindFirst();
        Observer.Observe('after_refind', Format(RecRef.IsDirty()));
        RecRef.Close();
        Observer.Expect('fresh', 'No');
        Observer.Expect('after_find', 'No');
        Observer.Expect('same_value', 'No');
        Observer.Expect('changed_value', 'Yes');
        Observer.Expect('after_modify', 'No');
        Observer.Expect('changed_qty', 'Yes');
        Observer.Expect('after_refind', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsDirty_AfterValidate()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(72202);
        RecRef.DeleteAll();
        RecRef.Init();
        RecRef.Field(1).Value := 1;
        RecRef.Insert();
        Observer.Observe('after_insert', Format(RecRef.IsDirty()));
        RecRef.Field(2).Validate(5);
        Observer.Observe('after_validate', Format(RecRef.IsDirty()));
        Observer.Observe('name_set_by_trigger', Format(RecRef.Field(3).Value));
        RecRef.Modify();
        Observer.Observe('after_modify', Format(RecRef.IsDirty()));
        RecRef.Field(4).Validate(0);
        Observer.Observe('validate_same_default', Format(RecRef.IsDirty()));
        RecRef.Close();
        Observer.Expect('after_insert', 'No');
        Observer.Expect('after_validate', 'Yes');
        Observer.Expect('name_set_by_trigger', 'v5');
        Observer.Expect('after_modify', 'No');
        Observer.Expect('validate_same_default', 'No');
        Observer.Verify();
    end;
}
#endif
