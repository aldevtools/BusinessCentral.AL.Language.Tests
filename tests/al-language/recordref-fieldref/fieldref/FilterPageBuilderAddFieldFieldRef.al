// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/filterpagebuilder/filterpagebuilder-addfield-method
// Scope: in-scope
// Fixtures used: table 71717 and codeunit 71718 (FieldRefTestFieldFixture.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FilterPageBuilder.AddField(Name, Field: FieldRef, Filter) with and without a filter text, GetView with the same name, the same name added twice
// BC versions: 29 (27 and 28 by CI)

codeunit 71731 "LT FPB AddField FieldRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAddTwice(var Fpb: FilterPageBuilder; Fld1: FieldRef; Fld2: FieldRef)
    begin
        Fpb.AddField('Rows', Fld1, 'A*');
        Fpb.AddField('Rows', Fld2, 'B*');
    end;

    [Test]
    procedure AddField_FieldRef_WithAndWithoutFilter()
    var
        Observer: Codeunit "Probe Observer";
        Fpb: FilterPageBuilder;
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        RecRef.Open(71717);
        Fpb.AddRecordRef('Rows', RecRef);
        Fld := RecRef.Field(2);
        Fpb.AddField('Rows', Fld);
        Observer.Observe('view_no_filter', Fpb.GetView('Rows'));
        Fpb.AddField('Rows', Fld, 'H*');
        Observer.Observe('view_with_filter', Fpb.GetView('Rows'));
        Fld := RecRef.Field(3);
        Fpb.AddField('Rows', Fld, '>3');
        Observer.Observe('view_second_field', Fpb.GetView('Rows'));
        RecRef.Close();
        Observer.Expect('view_no_filter', 'VERSION(1) SORTING(Code Cap)');
        Observer.Expect('view_with_filter', 'VERSION(1) SORTING(Code Cap) WHERE(Txt Cap=FILTER(H*))');
        Observer.Expect('view_second_field', 'VERSION(1) SORTING(Code Cap) WHERE(Txt Cap=FILTER(H*),Num Cap=FILTER(>3))');
        Observer.Verify();
    end;

    [Test]
    procedure AddField_FieldRef_SameNameTwice()
    var
        Observer: Codeunit "Probe Observer";
        Fpb: FilterPageBuilder;
        RecRef: RecordRef;
        Fld1: FieldRef;
        Fld2: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(71717);
        Fpb.AddRecordRef('Rows', RecRef);
        Fld1 := RecRef.Field(2);
        Fld2 := RecRef.Field(6);
        Ok := TryAddTwice(Fpb, Fld1, Fld2);
        Observer.Observe('twice_ok', Format(Ok));
        Observer.Observe('twice_text', GetLastErrorText());
        Observer.Observe('twice_code', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('view_after', Fpb.GetView('Rows'));
        RecRef.Close();
        Observer.Expect('twice_ok', 'Yes');
        Observer.Expect('twice_text', '');
        Observer.Expect('twice_code', '');
        Observer.Expect('view_after', 'VERSION(1) SORTING(Code Cap) WHERE(Txt Cap=FILTER(A*),Cd Cap=FILTER(B*))');
        Observer.Verify();
    end;
}
