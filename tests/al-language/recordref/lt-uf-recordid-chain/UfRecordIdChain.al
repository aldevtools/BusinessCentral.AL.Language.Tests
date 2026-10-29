// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordid/recordid-getrecord-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained enum 90332, table 90333, test codeunit 90334
// Probe (outside issue 6162): call chains that start at the RecordId method of a record and go through GetRecord() (a RecordRef) and Field() (a FieldRef):
//   `Rec.RecordId().GetRecord().Field(Rec.FieldNo(Opt)).Value()`, with `.Value`, `.Name()`, `.Number()`, `.Caption()`, Format of it, in an assignment to a Variant, Text and Integer,
//   and the `Rec.RecordId.GetRecord()` form without parentheses. RecordId.GetRecord on its own (primary key loaded, nothing else) is in recordref/TestRecordIdGetRecordContracts.al.
// BC versions: 27-29

enum 90332 "LT UF Chain Kind"
{
    Extensible = true;

    value(0; None) { }
    value(1; First) { Caption = 'First kind'; }
    value(2; Second) { Caption = 'Second kind'; }
}

table 90333 "LT UF Chain Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = A,B,C; }
        field(3; Kind; Enum "LT UF Chain Kind") { }
        field(4; Txt; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 90334 "LT UF RecordId Chain"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Chain_FieldValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UF Chain Row";
        Value: Variant;
        Txt: Text;
    begin
        Row.DeleteAll();
        Row.Id := 7;
        Row.Opt := Row.Opt::B;
        Row.Kind := Row.Kind::Second;
        Row.Txt := 'text';
        Row.Insert();
        Row.Get(7);

        Value := Row.RecordId().GetRecord().Field(Row.FieldNo(Opt)).Value();
        Observer.Observe('option value', Format(Value));
        Observer.Observe('option is option', Format(Value.IsOption()));
        Observer.Observe('option is integer', Format(Value.IsInteger()));
        Txt := Format(Row.RecordId().GetRecord().Field(Row.FieldNo(Opt)).Value());
        Observer.Observe('option text', Txt);
        Value := Row.RecordId().GetRecord().Field(Row.FieldNo(Id)).Value();
        Observer.Observe('key field value', Format(Value));
        Observer.Observe('key field is integer', Format(Value.IsInteger()));
        Value := Row.RecordId().GetRecord().Field(Row.FieldNo(Txt)).Value();
        Observer.Observe('other field value (not loaded)', '[' + Format(Value) + ']');
        Value := Row.RecordId().GetRecord().Field(Row.FieldNo(Kind)).Value();
        Observer.Observe('enum field value', '[' + Format(Value) + ']');
        Observer.Expect('option value', 'A');
        Observer.Expect('option is option', 'Yes');
        Observer.Expect('option is integer', 'No');
        Observer.Expect('option text', 'A');
        Observer.Expect('key field value', '7');
        Observer.Expect('key field is integer', 'Yes');
        Observer.Expect('other field value (not loaded)', '[]');
        Observer.Expect('enum field value', '[None]');
        Observer.Verify();
    end;

    [Test]
    procedure Chain_FieldMembers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UF Chain Row";
        Number: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 7;
        Row.Insert();
        Row.Get(7);

        Observer.Observe('name', Row.RecordId().GetRecord().Field(Row.FieldNo(Opt)).Name());
        Observer.Observe('caption', Row.RecordId().GetRecord().Field(Row.FieldNo(Opt)).Caption());
        Number := Row.RecordId().GetRecord().Field(Row.FieldNo(Kind)).Number();
        Observer.Observe('number', Format(Number));
        Observer.Observe('type', Format(Row.RecordId().GetRecord().Field(Row.FieldNo(Kind)).Type()));
        Observer.Observe('record name', Row.RecordId().GetRecord().Name());
        Observer.Observe('record number', Format(Row.RecordId().GetRecord().Number()));
        Observer.Observe('field count', Format(Row.RecordId().GetRecord().FieldCount()));
        Observer.Observe('without parentheses', Format(Row.RecordId.GetRecord().Field(Row.FieldNo(Id)).Value));
        Observer.Observe('format of recordid', Format(Row.RecordId().GetRecord().RecordId()));
        Observer.Expect('name', 'Opt');
        Observer.Expect('caption', 'Opt');
        Observer.Expect('number', '3');
        Observer.Expect('type', 'Option');
        Observer.Expect('record name', 'LT UF Chain Row');
        Observer.Expect('record number', '90333');
        Observer.Expect('field count', '4');
        Observer.Expect('without parentheses', '7');
        Observer.Expect('format of recordid', 'LT UF Chain Row: 7');
        Observer.Verify();
    end;

    [Test]
    procedure Chain_AssignThroughFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UF Chain Row";
        Ref: RecordRef;
        Field: FieldRef;
    begin
        Row.DeleteAll();
        Row.Id := 7;
        Row.Insert();
        Row.Get(7);

        Ref := Row.RecordId().GetRecord();
        Field := Ref.Field(Row.FieldNo(Txt));
        Field.Value := 'changed';
        Observer.Observe('through fieldref', Format(Field.Value));
        Observer.Observe('record unchanged', '[' + Row.Txt + ']');
        Observer.Observe('stored unchanged', '[' + Format(Row.RecordId().GetRecord().Field(Row.FieldNo(Txt)).Value()) + ']');
        Ref.Get(Row.RecordId());
        Observer.Observe('after Get', Format(Ref.Field(Row.FieldNo(Txt)).Value));
        Observer.Expect('through fieldref', 'changed');
        Observer.Expect('record unchanged', '[]');
        Observer.Expect('stored unchanged', '[]');
        Observer.Expect('after Get', '');
        Observer.Verify();
    end;
}
