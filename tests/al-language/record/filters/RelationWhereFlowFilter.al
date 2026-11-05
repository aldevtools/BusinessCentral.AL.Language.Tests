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

    // Tests below (al-runner issue 6979): a TableRelation whose where() filters on a FlowField of the related table (a lookup, an
    // exist and a count FlowField, compared with const, filter and field), and a where() on a normal field of the related table for
    // contrast. Tables 95783-95785 at the end of this file. Districts: AA (group G1, Own Group true, weight 10, Active), BB (group
    // G2, Own Group false, weight 1), CC (no group), DD (a group code with no group row). Each cell validates one code into one field
    // and records the value or the error text and code.

    [Test]
    procedure RelationOnRelatedFlowField_OwnTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRelatedFlowField();
        RelatedFlowFieldCells(Observer, 2, false, '');
        Observer.Finish();
    end;

    [Test]
    procedure RelationOnRelatedFlowField_OwnFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRelatedFlowField();
        RelatedFlowFieldCells(Observer, 3, false, '');
        Observer.Finish();
    end;

    [Test]
    procedure RelationOnRelatedFlowField_HasGroup()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRelatedFlowField();
        RelatedFlowFieldCells(Observer, 4, false, '');
        Observer.Finish();
    end;

    [Test]
    procedure RelationOnRelatedFlowField_CountOne()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRelatedFlowField();
        RelatedFlowFieldCells(Observer, 5, false, '');
        Observer.Finish();
    end;

    [Test]
    procedure RelationOnRelatedFlowField_WeightOverFive()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRelatedFlowField();
        RelatedFlowFieldCells(Observer, 6, false, '');
        Observer.Finish();
    end;

    [Test]
    procedure RelationOnRelatedFlowField_ActiveTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRelatedFlowField();
        RelatedFlowFieldCells(Observer, 7, false, '');
        Observer.Finish();
    end;

    [Test]
    procedure RelationOnRelatedFlowField_OwnEqualsWant()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRelatedFlowField();
        RelatedFlowFieldCells(Observer, 8, true, 'want true ');
        RelatedFlowFieldCells(Observer, 8, false, 'want false ');
        Observer.Finish();
    end;

    local procedure SeedRelatedFlowField()
    var
        G: Record "REC RelFF Group";
        D: Record "REC RelFF District";
    begin
        G.DeleteAll();
        D.DeleteAll();
        G.Code := 'G1';
        G."Own Group" := true;
        G.Weight := 10;
        G.Insert();
        G.Code := 'G2';
        G."Own Group" := false;
        G.Weight := 1;
        G.Insert();
        D.Code := 'AA';
        D."Group Code" := 'G1';
        D.Active := true;
        D.Insert();
        D.Code := 'BB';
        D."Group Code" := 'G2';
        D.Active := false;
        D.Insert();
        D.Code := 'CC';
        D."Group Code" := '';
        D.Active := false;
        D.Insert();
        D.Code := 'DD';
        D."Group Code" := 'GX';
        D.Active := false;
        D.Insert();
    end;

    local procedure RelatedFlowFieldCells(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Want: Boolean; Prefix: Text)
    begin
        RelatedFlowFieldCell(Observer, FieldNo, Want, Prefix, 'AA');
        RelatedFlowFieldCell(Observer, FieldNo, Want, Prefix, 'BB');
        RelatedFlowFieldCell(Observer, FieldNo, Want, Prefix, 'CC');
        RelatedFlowFieldCell(Observer, FieldNo, Want, Prefix, 'DD');
        RelatedFlowFieldCell(Observer, FieldNo, Want, Prefix, 'ZZ');
        RelatedFlowFieldCell(Observer, FieldNo, Want, Prefix, '');
    end;

    local procedure RelatedFlowFieldCell(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Want: Boolean; Prefix: Text; Value: Code[20])
    var
        Doc: Record "REC RelFF Document";
    begin
        Doc.Init();
        Doc."Want Own" := Want;
        ClearLastError();
        if TryValidateRelatedFlowField(Doc, FieldNo, Value) then
            Observer.Observe(Prefix + '[' + Value + ']', 'ok=' + ReadRelatedFlowField(Doc, FieldNo))
        else
            Observer.Observe(Prefix + '[' + Value + ']', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryValidateRelatedFlowField(var Doc: Record "REC RelFF Document"; FieldNo: Integer; Value: Code[20])
    begin
        case FieldNo of
            2:
                Doc.Validate("Own True", Value);
            3:
                Doc.Validate("Own False", Value);
            4:
                Doc.Validate("Has Group", Value);
            5:
                Doc.Validate("Count One", Value);
            6:
                Doc.Validate("Weight Over Five", Value);
            7:
                Doc.Validate("Active True", Value);
            8:
                Doc.Validate("Own Equals Want", Value);
        end;
    end;

    local procedure ReadRelatedFlowField(var Doc: Record "REC RelFF Document"; FieldNo: Integer): Code[20]
    begin
        case FieldNo of
            2:
                exit(Doc."Own True");
            3:
                exit(Doc."Own False");
            4:
                exit(Doc."Has Group");
            5:
                exit(Doc."Count One");
            6:
                exit(Doc."Weight Over Five");
            7:
                exit(Doc."Active True");
            8:
                exit(Doc."Own Equals Want");
        end;
    end;
}

// local object: the test checks a TableRelation whose where() names FlowFields of the related table (al-runner issue 6979).
table 95783 "REC RelFF Group"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Own Group"; Boolean) { }
        field(3; Weight; Integer) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

// local object: the related table; its FlowFields are what the relations of table 95785 filter on.
table 95784 "REC RelFF District"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Group Code"; Code[20]) { }
        field(3; Active; Boolean) { }
        field(10; "Own Group"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("REC RelFF Group"."Own Group" where(Code = field("Group Code")));
            Editable = false;
        }
        field(11; "Has Group"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("REC RelFF Group" where(Code = field("Group Code")));
            Editable = false;
        }
        field(12; "Group Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("REC RelFF Group" where(Code = field("Group Code")));
            Editable = false;
        }
        field(13; "Group Weight"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("REC RelFF Group".Weight where(Code = field("Group Code")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

// local object: the relations on FlowFields of table 95784 are what the tests check.
table 95785 "REC RelFF Document"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Own True"; Code[20]) { TableRelation = "REC RelFF District" where("Own Group" = const(true)); }
        field(3; "Own False"; Code[20]) { TableRelation = "REC RelFF District" where("Own Group" = const(false)); }
        field(4; "Has Group"; Code[20]) { TableRelation = "REC RelFF District" where("Has Group" = const(true)); }
        field(5; "Count One"; Code[20]) { TableRelation = "REC RelFF District" where("Group Count" = const(1)); }
        field(6; "Weight Over Five"; Code[20]) { TableRelation = "REC RelFF District" where("Group Weight" = filter(> 5)); }
        field(7; "Active True"; Code[20]) { TableRelation = "REC RelFF District" where(Active = const(true)); }
        field(8; "Own Equals Want"; Code[20]) { TableRelation = "REC RelFF District" where("Own Group" = field("Want Own")); }
        field(9; "Want Own"; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
