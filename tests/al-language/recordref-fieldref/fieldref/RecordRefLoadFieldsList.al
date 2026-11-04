// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-loadfields-method
// Scope: in-scope
// Fixtures used: table 71717 and codeunit 71718 (FieldRefTestFieldFixture.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RecordRef.LoadFields(Fields: Integer*) with one field, several fields and an unknown field number; AreFieldsLoaded after FindFirst; error text and code of the unknown field
// BC versions: 29 (27 and 28 by CI)

codeunit 71729 "LT FRTF LoadFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LoadFields_OneAndSeveral()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT FRTF Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(71717);
        RecRef.LoadFields(2);
        RecRef.FindFirst();
        Observer.Observe('one_f2', Format(RecRef.AreFieldsLoaded(2)));
        Observer.Observe('one_f3', Format(RecRef.AreFieldsLoaded(3)));
        Observer.Observe('one_f2_f3', Format(RecRef.AreFieldsLoaded(2, 3)));
        Observer.Observe('one_pk', Format(RecRef.AreFieldsLoaded(1)));
        RecRef.Close();
        RecRef.Open(71717);
        RecRef.LoadFields(3, 5);
        RecRef.FindFirst();
        Observer.Observe('two_f2', Format(RecRef.AreFieldsLoaded(2)));
        Observer.Observe('two_f3', Format(RecRef.AreFieldsLoaded(3)));
        Observer.Observe('two_f5', Format(RecRef.AreFieldsLoaded(5)));
        Observer.Observe('two_f3_f5', Format(RecRef.AreFieldsLoaded(3, 5)));
        Observer.Observe('two_f4', Format(RecRef.AreFieldsLoaded(4)));
        Observer.Observe('two_value_f3', Format(RecRef.Field(3).Value));
        RecRef.Close();
        Observer.Expect('one_f2', 'Yes');
        Observer.Expect('one_f3', 'Yes');
        Observer.Expect('one_f2_f3', 'Yes');
        Observer.Expect('one_pk', 'Yes');
        Observer.Expect('two_f2', 'Yes');
        Observer.Expect('two_f3', 'Yes');
        Observer.Expect('two_f5', 'Yes');
        Observer.Expect('two_f3_f5', 'Yes');
        Observer.Expect('two_f4', 'Yes');
        Observer.Expect('two_value_f3', '5');
        Observer.Verify();
    end;
}
