// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/filterpagebuilder/filterpagebuilder-addfield-method
// Scope: in-scope
// Fixtures used: tables 72694-72695, codeunit 72696 (P107Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FilterPageBuilder.AddField(Name, FieldRef, Filter) with a FieldRef
// BC versions: 29 (27 and 28 by CI)

codeunit 72702 "LT P107 FilterPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P107_AddFieldFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
        RecRef: RecordRef;
        FldRef: FieldRef;
        Added: Boolean;
        Flt: Text;
    begin
        RecRef.Open(72694);
        FPB.AddRecordRef('Ref', RecRef);
        FldRef := RecRef.Field(3);
        Added := FPB.AddField('Ref', FldRef);
        Observer.Observe('added', Format(Added));
        Observer.Observe('count', Format(FPB.Count()));
        Flt := '>5';
        Added := FPB.AddField('Ref', FldRef, Flt);
        Observer.Observe('added_filter', Format(Added));
        Observer.Observe('count_after', Format(FPB.Count()));
        Observer.Observe('filter_after', FPB.GetView('Ref'));
        FldRef := RecRef.Field(2);
        Added := FPB.AddField('Ref', FldRef, '');
        Observer.Observe('added_empty_filter', Format(Added));
        asserterror FPB.AddField('Missing', FldRef);
        Observer.ObserveError('missing_name');
        asserterror FPB.AddField('Ref', FldRef, '<<<');
        Observer.ObserveError('bad_filter');
        RecRef.Close();
        Observer.Expect('added', 'Yes');
        Observer.Expect('count', '1');
        Observer.Expect('added_filter', 'Yes');
        Observer.Expect('count_after', '1');
        Observer.Expect('filter_after', 'VERSION(1) SORTING(Code Cap) WHERE(Qty=FILTER(>5))');
        Observer.Expect('added_empty_filter', 'Yes');
        Observer.Expect('missing_name|text', 'Filter control Missing is not defined in the FilterPageBuilder variable.');
        Observer.Expect('missing_name|code', 'Argument');
        Observer.Expect('bad_filter|text', 'The filter "<<<" is not valid for the Name Cap field on the LT P107 Rec table. A value is expected after the ''<''.');
        Observer.Expect('bad_filter|code', 'Filter:CSide');
        Observer.Verify();
    end;
}
