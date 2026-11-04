// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 72440 and 72441
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Validate of a field whose TableRelation where() names the validated field itself (Code = field(Variant Code)), with a blank and a non-blank old value, existing and missing codes, a code that exists only for another item.
// BC versions: 29 (27 and 28 by CI)

table 72440 "LT RWV Variant"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Item No."; Code[10]) { }
        field(2; Code; Code[10]) { }
    }
    keys
    {
        key(PK; "Item No.", Code) { Clustered = true; }
    }
}

table 72441 "LT RWV Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Item No."; Code[10]) { }
        field(3; "Variant Code"; Code[10])
        {
            TableRelation = "LT RWV Variant".Code where("Item No." = field("Item No."), Code = field("Variant Code"));
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72442 "LT RWV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        V: Record "LT RWV Variant";
        L: Record "LT RWV Line";
    begin
        V.DeleteAll();
        L.DeleteAll();
        V.Init();
        V."Item No." := 'I1';
        V.Code := 'V1';
        V.Insert();
        V.Init();
        V."Item No." := 'I1';
        V.Code := 'V2';
        V.Insert();
        V.Init();
        V."Item No." := 'I2';
        V.Code := 'V3';
        V.Insert();
    end;

    [Test]
    procedure Validate_OldBlank_ExistingAndMissing()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "LT RWV Line";
    begin
        Seed();
        L.Init();
        L."Item No." := 'I1';
        L.Validate("Variant Code", 'V1');
        Observer.Observe('existing-value', L."Variant Code");
        L.Init();
        L."Item No." := 'I1';
        asserterror L.Validate("Variant Code", 'ZZ');
        Observer.ObserveError('missing');
        Observer.Observe('missing-value', L."Variant Code");
        L.Init();
        L."Item No." := 'I1';
        L.Validate("Variant Code", '');
        Observer.Observe('blank-value', '[' + L."Variant Code" + ']');
        L.Init();
        L."Item No." := 'I1';
        asserterror L.Validate("Variant Code", 'V3');
        Observer.ObserveError('other-item');
        Observer.Observe('other-item-value', L."Variant Code");
        Observer.Expect('existing-value', 'V1');
        Observer.Expect('missing|text', 'The field Variant Code of table LT RWV Line contains a value (ZZ) that cannot be found in the related table (LT RWV Variant).');
        Observer.Expect('missing|code', 'DB:RecordNotFound');
        Observer.Expect('missing-value', '');
        Observer.Expect('blank-value', '[]');
        Observer.Expect('other-item|text', 'The field Variant Code of table LT RWV Line contains a value (V3) that cannot be found in the related table (LT RWV Variant).');
        Observer.Expect('other-item|code', 'DB:RecordNotFound');
        Observer.Expect('other-item-value', '');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OldNonBlank_NewExisting()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "LT RWV Line";
    begin
        Seed();
        L.Init();
        L."Item No." := 'I1';
        L."Variant Code" := 'V1';
        L.Validate("Variant Code", 'V2');
        Observer.Observe('v1-to-v2', L."Variant Code");
        // old value belongs to another item: only the new value can be found for I1
        L.Init();
        L."Item No." := 'I1';
        L."Variant Code" := 'V3';
        L.Validate("Variant Code", 'V1');
        Observer.Observe('v3-to-v1', L."Variant Code");
        Observer.Expect('v1-to-v2', 'V2');
        Observer.Expect('v3-to-v1', 'V1');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OldNonBlank_NewMissing()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "LT RWV Line";
    begin
        Seed();
        L.Init();
        L."Item No." := 'I1';
        L."Variant Code" := 'V1';
        asserterror L.Validate("Variant Code", 'ZZ');
        Observer.ObserveError('v1-to-zz');
        Observer.Observe('v1-to-zz-value', L."Variant Code");
        L.Init();
        L."Item No." := 'I1';
        L."Variant Code" := 'V1';
        asserterror L.Validate("Variant Code", 'V3');
        Observer.ObserveError('v1-to-v3');
        Observer.Observe('v1-to-v3-value', L."Variant Code");
        L.Init();
        L."Item No." := 'I1';
        L."Variant Code" := 'V1';
        L.Validate("Variant Code", '');
        Observer.Observe('v1-to-blank', '[' + L."Variant Code" + ']');
        Observer.Expect('v1-to-zz|text', 'The field Variant Code of table LT RWV Line contains a value (ZZ) that cannot be found in the related table (LT RWV Variant).');
        Observer.Expect('v1-to-zz|code', 'DB:RecordNotFound');
        Observer.Expect('v1-to-zz-value', 'V1');
        Observer.Expect('v1-to-v3|text', 'The field Variant Code of table LT RWV Line contains a value (V3) that cannot be found in the related table (LT RWV Variant).');
        Observer.Expect('v1-to-v3|code', 'DB:RecordNotFound');
        Observer.Expect('v1-to-v3-value', 'V1');
        Observer.Expect('v1-to-blank', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OtherItemNo_SameValue()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "LT RWV Line";
    begin
        Seed();
        L.Init();
        L."Item No." := 'I2';
        L.Validate("Variant Code", 'V3');
        Observer.Observe('i2-v3', L."Variant Code");
        L.Init();
        L."Item No." := 'I2';
        asserterror L.Validate("Variant Code", 'V1');
        Observer.ObserveError('i2-v1');
        L.Init();
        L."Item No." := 'I3';
        asserterror L.Validate("Variant Code", 'V1');
        Observer.ObserveError('i3-v1');
        L.Init();
        L."Item No." := '';
        asserterror L.Validate("Variant Code", 'V1');
        Observer.ObserveError('blank-item-v1');
        Observer.Expect('i2-v3', 'V3');
        Observer.Expect('i2-v1|text', 'The field Variant Code of table LT RWV Line contains a value (V1) that cannot be found in the related table (LT RWV Variant).');
        Observer.Expect('i2-v1|code', 'DB:RecordNotFound');
        Observer.Expect('i3-v1|text', 'The field Variant Code of table LT RWV Line contains a value (V1) that cannot be found in the related table (LT RWV Variant).');
        Observer.Expect('i3-v1|code', 'DB:RecordNotFound');
        Observer.Expect('blank-item-v1|text', 'The field Variant Code of table LT RWV Line contains a value (V1) that cannot be found in the related table (LT RWV Variant).');
        Observer.Expect('blank-item-v1|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;
}
