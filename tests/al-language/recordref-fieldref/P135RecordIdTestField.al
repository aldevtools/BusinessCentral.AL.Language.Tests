// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 74255 and 74256, codeunit 74257
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles (issue 135, reasons 28-29): "TestField of a RecordId field: when it counts as blank, and the error text, are not pinned".
// Facts: Record.TestField(RecordIdField) and TestField(RecordIdField, Value), also through FieldRef, on a never assigned RecordId, one assigned from an initialized-but-not-inserted record, from a stored row and from a row of another table; the error text and code; what Format and equality say about the blank value.
// BC versions: 29 (27 and 28 by CI)

table 74255 "LT P135 Rid Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; RecordId) { }
        field(3; Ref2; RecordId) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 74256 "LT P135 Rid Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Qty; Integer) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 74257 "LT P135 Rid TestField"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    var
        Row: Record "LT P135 Rid Row";
        Target: Record "LT P135 Rid Target";
    begin
        Row.DeleteAll();
        Target.DeleteAll();
        Target.Code := 'T1';
        Target.Qty := 1;
        Target.Insert();
        Target.Code := 'T2';
        Target.Qty := 2;
        Target.Insert();
    end;

    [Test]
    procedure P135_TestField_BlankRecordId()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P135 Rid Row";
        Empty: RecordId;
    begin
        Clean();
        Row.Init();
        Row.Id := 1;
        Observer.Observe('format blank field', '[' + Format(Row.Ref) + ']');
        Observer.Observe('format blank var', '[' + Format(Empty) + ']');
        Observer.Observe('equals blank var', Format(Row.Ref = Empty));
        asserterror Row.TestField(Ref);
        Observer.ObserveError('testfield blank');
        Row.TestField(Ref, Empty);
        Observer.Observe('testfield blank with blank value', 'no error');
        Row.Insert();
        Row.Get(1);
        Observer.Observe('format after insert', '[' + Format(Row.Ref) + ']');
        asserterror Row.TestField(Ref);
        Observer.ObserveError('testfield blank stored');
        asserterror Row.TestField(Ref2);
        Observer.ObserveError('testfield blank second field');
        Observer.Expect('format blank field', '[]');
        Observer.Expect('format blank var', '[]');
        Observer.Expect('equals blank var', 'Yes');
        Observer.Expect('testfield blank|text', 'Ref must have a value in LT P135 Rid Row: Id=1. It cannot be zero or empty.');
        Observer.Expect('testfield blank|code', 'TestField');
        Observer.Expect('testfield blank with blank value', 'no error');
        Observer.Expect('format after insert', '[]');
        Observer.Expect('testfield blank stored|text', 'Ref must have a value in LT P135 Rid Row: Id=1. It cannot be zero or empty.');
        Observer.Expect('testfield blank stored|code', 'TestField');
        Observer.Expect('testfield blank second field|text', 'Ref2 must have a value in LT P135 Rid Row: Id=1. It cannot be zero or empty.');
        Observer.Expect('testfield blank second field|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P135_TestField_AssignedRecordId()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P135 Rid Row";
        Target: Record "LT P135 Rid Target";
        Fresh: Record "LT P135 Rid Target";
        Other: RecordId;
    begin
        Clean();
        Target.Get('T1');
        Row.Init();
        Row.Id := 1;
        Row.Ref := Target.RecordId;
        Observer.Observe('format assigned', Format(Row.Ref));
        Row.TestField(Ref);
        Observer.Observe('testfield assigned', 'ok');
        Row.TestField(Ref, Target.RecordId);
        Observer.Observe('testfield same value', 'ok');
        Other := Fresh.RecordId;
        Observer.Observe('format initialized record id', '[' + Format(Other) + ']');
        asserterror Row.TestField(Ref, Other);
        Observer.ObserveError('testfield other value');
        asserterror Target.Get('T2');
        Observer.ObserveError('af112');
        Row.TestField(Ref, Target.RecordId);
        Observer.Observe('testfield another row', 'no error');
        Row.Ref2 := Fresh.RecordId;
        Observer.Observe('format of an unassigned record id', '[' + Format(Row.Ref2) + ']');
        Row.TestField(Ref2);
        Observer.Observe('testfield record id of an empty record', 'no error');
        Row.Ref2 := Row.RecordId;
        Observer.Observe('format of the own row', Format(Row.Ref2));
        Row.TestField(Ref2);
        Observer.Observe('testfield own row', 'ok');
        Observer.Expect('format assigned', 'LT P135 Rid Target: T1');
        Observer.Expect('testfield assigned', 'ok');
        Observer.Expect('testfield same value', 'ok');
        Observer.Expect('format initialized record id', '[LT P135 Rid Target: ""]');
        Observer.Expect('testfield other value|text', 'Ref must be equal to ''LT P135 Rid Target: ""''  in LT P135 Rid Row: Id=1. Current value is ''LT P135 Rid Target: T1''.');
        Observer.Expect('testfield other value|code', 'TestField');
        Observer.Expect('af112|text', 'The LT P135 Rid Target does not exist. Identification fields and values: Code=''T2''');
        Observer.Expect('af112|code', 'DB:RecordNotFound');
        Observer.Expect('testfield another row', 'no error');
        Observer.Expect('format of an unassigned record id', '[LT P135 Rid Target: ""]');
        Observer.Expect('testfield record id of an empty record', 'no error');
        Observer.Expect('format of the own row', 'LT P135 Rid Row: 1');
        Observer.Expect('testfield own row', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P135_TestField_ThroughFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P135 Rid Row";
        Target: Record "LT P135 Rid Target";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Clean();
        Target.Get('T1');
        Row.Init();
        Row.Id := 1;
        RR.GetTable(Row);
        FR := RR.Field(2);
        asserterror FR.TestField();
        Observer.ObserveError('fieldref blank');
        asserterror FR.TestField(Target.RecordId);
        Observer.ObserveError('fieldref blank with value');
        FR.Value := Target.RecordId;
        FR.TestField();
        Observer.Observe('fieldref assigned', Format(FR.Value));
        FR.TestField(Target.RecordId);
        Observer.Observe('fieldref same value', 'ok');
        asserterror Target.Get('T2');
        Observer.ObserveError('af151');
        FR.TestField(Target.RecordId);
        Observer.Observe('fieldref other value', 'no error');
        Observer.Observe('fieldref class', Format(FR.Type));
        Observer.Expect('fieldref blank|text', 'Ref must have a value in LT P135 Rid Row: Id=1. It cannot be zero or empty.');
        Observer.Expect('fieldref blank|code', 'TestField');
        Observer.Expect('fieldref blank with value|text', 'Ref must be equal to ''LT P135 Rid Target: T1''  in LT P135 Rid Row: Id=1. Current value is ''''.');
        Observer.Expect('fieldref blank with value|code', 'TestField');
        Observer.Expect('fieldref assigned', 'LT P135 Rid Target: T1');
        Observer.Expect('fieldref same value', 'ok');
        Observer.Expect('af151|text', 'The LT P135 Rid Target does not exist. Identification fields and values: Code=''T2''');
        Observer.Expect('af151|code', 'DB:RecordNotFound');
        Observer.Expect('fieldref other value', 'no error');
        Observer.Expect('fieldref class', 'RecordID');
        Observer.Verify();
    end;

    [Test]
    procedure P135_RecordId_FieldError_And_Validate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P135 Rid Row";
        Target: Record "LT P135 Rid Target";
    begin
        Clean();
        Target.Get('T1');
        Row.Init();
        Row.Id := 1;
        asserterror Row.FieldError(Ref);
        Observer.ObserveError('fielderror blank');
        asserterror Row.FieldError(Ref, 'custom text');
        Observer.ObserveError('fielderror custom');
        Row.Validate(Ref, Target.RecordId);
        Observer.Observe('validate assigned', Format(Row.Ref));
        asserterror Row.FieldError(Ref);
        Observer.ObserveError('fielderror assigned');
        Observer.Observe('blank check by comparison', Format(Row.Ref2 = Row.Ref));
        Observer.Observe('count where blank', Format(Row.Count()));
        Observer.Expect('fielderror blank|text', 'Ref must not be  in LT P135 Rid Row Id=''1''.');
        Observer.Expect('fielderror blank|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror custom|text', 'Ref custom text in LT P135 Rid Row Id=''1''.');
        Observer.Expect('fielderror custom|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('validate assigned', 'LT P135 Rid Target: T1');
        Observer.Expect('fielderror assigned|text', 'Ref must not be LT P135 Rid Target: T1 in LT P135 Rid Row Id=''1''.');
        Observer.Expect('fielderror assigned|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('blank check by comparison', 'No');
        Observer.Expect('count where blank', '0');
        Observer.Verify();
    end;
}
