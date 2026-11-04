// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 72430 and 72431
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Validate of a field whose TableRelation where() names a FlowFilter of the related table (compared with field() and with const), for existing, non-existing and blank values; a where() on a normal field of the target for contrast.
// BC versions: 29 (27 and 28 by CI)

table 72430 "LT RelFF Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Kind; Code[10]) { }
        field(3; "Item Filter"; Code[10]) { FieldClass = FlowFilter; }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 72431 "LT RelFF Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Item No."; Code[10]) { }
        field(3; "Bin Field"; Code[10])
        {
            TableRelation = "LT RelFF Target".Code where("Item Filter" = field("Item No."));
        }
        field(4; "Const Field"; Code[10])
        {
            TableRelation = "LT RelFF Target".Code where("Item Filter" = const('I1'));
        }
        field(5; "Kind Field"; Code[10])
        {
            TableRelation = "LT RelFF Target".Code where(Kind = const('K1'));
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72433 "LT RelFF Where Flowfilter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        T: Record "LT RelFF Target";
    begin
        T.DeleteAll();
        T.Init();
        T.Code := 'A';
        T.Kind := 'K1';
        T.Insert();
        T.Init();
        T.Code := 'B';
        T.Kind := 'K2';
        T.Insert();
        T.Init();
        T.Code := 'C';
        T.Kind := 'K1';
        T."Item Filter" := 'I1';
        T.Insert();
    end;

    [Test]
    procedure ValidateFlowFilterFieldRelation_ExistingValue()
    var
        Observer: Codeunit "Probe Observer";
        S: Record "LT RelFF Source";
    begin
        Seed();
        S.Init();
        S."Item No." := 'I1';
        S.Validate("Bin Field", 'A');
        Observer.Observe('a_with_item_i1', 'no error');
        Observer.Observe('value_after_a', S."Bin Field");
        S.Validate("Bin Field", 'C');
        Observer.Observe('c_with_item_i1', 'no error');
        Observer.Observe('value_after_c', S."Bin Field");
        S.Validate("Bin Field", 'B');
        Observer.Observe('b_ok_value', S."Bin Field");
        Observer.Expect('a_with_item_i1', 'no error');
        Observer.Expect('value_after_a', 'A');
        Observer.Expect('c_with_item_i1', 'no error');
        Observer.Expect('value_after_c', 'C');
        Observer.Expect('b_ok_value', 'B');
        Observer.Verify();
    end;

    [Test]
    procedure ValidateFlowFilterConstRelation()
    var
        Observer: Codeunit "Probe Observer";
        S: Record "LT RelFF Source";
    begin
        Seed();
        S.Init();
        S.Validate("Const Field", 'A');
        Observer.Observe('const_a', 'no error');
        Observer.Observe('value_after_a', S."Const Field");
        S.Validate("Const Field", 'C');
        Observer.Observe('const_c', 'no error');
        Observer.Observe('value_after_c', S."Const Field");
        asserterror S.Validate("Const Field", 'ZZ');
        Observer.ObserveError('const_zz');
        Observer.Expect('const_a', 'no error');
        Observer.Expect('value_after_a', 'A');
        Observer.Expect('const_c', 'no error');
        Observer.Expect('value_after_c', 'C');
        Observer.Expect('const_zz|text', 'The field Const Field of table LT RelFF Source contains a value (ZZ) that cannot be found in the related table (LT RelFF Target).');
        Observer.Expect('const_zz|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure ValidateNormalFieldRelation_Contrast()
    var
        Observer: Codeunit "Probe Observer";
        S: Record "LT RelFF Source";
    begin
        Seed();
        S.Init();
        S.Validate("Kind Field", 'A');
        Observer.Observe('kind_a_k1', 'no error');
        Observer.Observe('value_after_a', S."Kind Field");
        asserterror S.Validate("Kind Field", 'B');
        Observer.ObserveError('kind_b_k2');
        Observer.Observe('value_after_b', S."Kind Field");
        asserterror S.Validate("Kind Field", 'ZZ');
        Observer.ObserveError('kind_zz');
        Observer.Expect('kind_a_k1', 'no error');
        Observer.Expect('value_after_a', 'A');
        Observer.Expect('kind_b_k2|text', 'The field Kind Field of table LT RelFF Source contains a value (B) that cannot be found in the related table (LT RelFF Target).');
        Observer.Expect('kind_b_k2|code', 'DB:NothingInsideFilter');
        Observer.Expect('value_after_b', 'A');
        Observer.Expect('kind_zz|text', 'The field Kind Field of table LT RelFF Source contains a value (ZZ) that cannot be found in the related table (LT RelFF Target).');
        Observer.Expect('kind_zz|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure ValidateFlowFilterRelation_InsertWithValidate()
    var
        Observer: Codeunit "Probe Observer";
        S: Record "LT RelFF Source";
    begin
        Seed();
        S.DeleteAll();
        S.Init();
        S.Id := 1;
        S.Validate("Item No.", 'I1');
        asserterror S.Validate("Bin Field", 'ZZ');
        Observer.ObserveError('zz_before_insert');
        S.Insert(true);
        Observer.Observe('count', Format(S.Count()));
        Observer.Expect('zz_before_insert|text', 'The field Bin Field of table LT RelFF Source contains a value (ZZ) that cannot be found in the related table (LT RelFF Target).');
        Observer.Expect('zz_before_insert|code', 'DB:NothingInsideFilter');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;
}
