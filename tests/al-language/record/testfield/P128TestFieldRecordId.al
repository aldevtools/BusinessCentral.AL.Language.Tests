// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 73185 and 73187, codeunit 73186
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestField on a table field of type RecordId (not a RecordId variable, see types/lt-implicit-conversions/P79RecordId.al): when it counts as blank (never assigned, Clear, a RecordId of a
// row that does not exist, the RecordId of the record itself), the error text and code, TestField(Field, Value) with the same / another RecordId, and FieldError.
// BC versions: 29 (27 and 28 by CI)

table 73185 "LT P128 TF Rid"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; RecordId) { }
        field(3; Note; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73187 "LT P128 TF Rid Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 73186 "LT P128 TF RecordId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryTestField(var Row: Record "LT P128 TF Rid")
    begin
        Row.TestField(Ref);
    end;

    [TryFunction]
    local procedure TryTestFieldValue(var Row: Record "LT P128 TF Rid"; Value: RecordId)
    begin
        Row.TestField(Ref, Value);
    end;

    [TryFunction]
    local procedure TryFieldError(var Row: Record "LT P128 TF Rid")
    begin
        Row.FieldError(Ref);
    end;

    local procedure Check(var Observer: Codeunit "Probe Observer"; Name: Text; var Row: Record "LT P128 TF Rid")
    begin
        if TryTestField(Row) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure P128_TestField_RecordIdField_Blank()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P128 TF Rid";
        Target: Record "LT P128 TF Rid Target";
    begin
        Row.Id := 1;
        Check(Observer, 'never assigned', Row);
        Observer.Observe('format never assigned', '[' + Format(Row.Ref) + ']');
        Row.Ref := Target.RecordId;
        Check(Observer, 'blank target record id', Row);
        Observer.Observe('format blank target', '[' + Format(Row.Ref) + ']');
        Clear(Row.Ref);
        Check(Observer, 'after Clear', Row);
        Observer.Expect('never assigned|text', 'Ref must have a value in LT P128 TF Rid: Id=1. It cannot be zero or empty.');
        Observer.Expect('never assigned|code', 'TestField');
        Observer.Expect('format never assigned', '[]');
        Observer.Expect('blank target record id', 'ok');
        Observer.Expect('format blank target', '[LT P128 TF Rid Target: ""]');
        Observer.Expect('after Clear|text', 'Ref must have a value in LT P128 TF Rid: Id=1. It cannot be zero or empty.');
        Observer.Expect('after Clear|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P128_TestField_RecordIdField_Set()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P128 TF Rid";
        Target: Record "LT P128 TF Rid Target";
    begin
        Target.DeleteAll();
        Target.Code := 'T1';
        Target.Insert();
        Row.Id := 2;
        Row.Ref := Target.RecordId;
        Check(Observer, 'existing target', Row);
        Row.Ref := Row.RecordId;
        Check(Observer, 'own record id', Row);
        Target.Code := 'NOROW';
        Row.Ref := Target.RecordId;
        Check(Observer, 'target without a row', Row);
        Observer.Expect('existing target', 'ok');
        Observer.Expect('own record id', 'ok');
        Observer.Expect('target without a row', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P128_TestField_RecordIdField_WithValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P128 TF Rid";
        Target: Record "LT P128 TF Rid Target";
        Other: Record "LT P128 TF Rid Target";
    begin
        Target.Code := 'T1';
        Other.Code := 'T2';
        Row.Id := 3;
        Row.Ref := Target.RecordId;
        if TryTestFieldValue(Row, Target.RecordId) then
            Observer.Observe('same value', 'ok')
        else
            Observer.ObserveError('same value');
        if TryTestFieldValue(Row, Other.RecordId) then
            Observer.Observe('other value', 'ok')
        else
            Observer.ObserveError('other value');
        Clear(Row.Ref);
        if TryTestFieldValue(Row, Target.RecordId) then
            Observer.Observe('blank against value', 'ok')
        else
            Observer.ObserveError('blank against value');
        Observer.Expect('same value', 'ok');
        Observer.Expect('other value|text', 'Ref must be equal to ''LT P128 TF Rid Target: T2''  in LT P128 TF Rid: Id=3. Current value is ''LT P128 TF Rid Target: T1''.');
        Observer.Expect('other value|code', 'TestField');
        Observer.Expect('blank against value|text', 'Ref must be equal to ''LT P128 TF Rid Target: T1''  in LT P128 TF Rid: Id=3. Current value is ''''.');
        Observer.Expect('blank against value|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P128_FieldError_RecordIdField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P128 TF Rid";
        Target: Record "LT P128 TF Rid Target";
    begin
        Target.Code := 'T1';
        Row.Id := 4;
        Row.Ref := Target.RecordId;
        if TryFieldError(Row) then
            Observer.Observe('field error', 'ok')
        else
            Observer.ObserveError('field error');
        Clear(Row.Ref);
        if TryFieldError(Row) then
            Observer.Observe('field error blank', 'ok')
        else
            Observer.ObserveError('field error blank');
        Observer.Expect('field error|text', 'Ref must not be LT P128 TF Rid Target: T1 in LT P128 TF Rid Id=''4''.');
        Observer.Expect('field error|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('field error blank|text', 'Ref must not be  in LT P128 TF Rid Id=''4''.');
        Observer.Expect('field error blank|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;
}
