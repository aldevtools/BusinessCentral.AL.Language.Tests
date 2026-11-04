// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 73929 to 73931, codeunit 73932
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "TableRelation = T.F where(X = field(FlowFieldOfTheRecord))" (TableRelation filtered by a FlowField, Pageworks)
// Facts: Validate of a field whose relation is filtered by a FlowField of the same record, with no CalcFields first and after CalcFields: an Integer relation Field."No." where(TableNo = field(Flow)),
//   a Code relation Target.Code where(Grp = field(FlowCode)) and a relation with the FlowField as an if condition
// BC versions: 29 (27 and 28 by CI)

table 73929 "LT PnF FF Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; TargetTableNo; Integer) { }
        field(3; Grp; Code[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 73930 "LT PnF FF Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Grp; Code[20]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 73931 "LT PnF FF Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Flow; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT PnF FF Parent".TargetTableNo where(Id = field(ParentId)));
            Editable = false;
        }
        field(4; FlowCode; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT PnF FF Parent".Grp where(Id = field(ParentId)));
            Editable = false;
        }
        field(5; FieldNoRef; Integer)
        {
            TableRelation = Field."No." where(TableNo = field(Flow));
        }
        field(6; CodeRef; Code[20])
        {
            TableRelation = "LT PnF FF Target"."Code" where(Grp = field(FlowCode));
        }
        field(7; CondRef; Code[20])
        {
            TableRelation = if (FlowCode = const('G1')) "LT PnF FF Target"."Code" where(Grp = const('G1'))
            else
            "LT PnF FF Target"."Code" where(Grp = const('G2'));
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73932 "LT PnF Relation By FlowField"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryValidate(var Child: Record "LT PnF FF Child"; FieldNo: Integer; IntValue: Integer; CodeValue: Code[20])
    begin
        case FieldNo of
            5:
                Child.Validate(FieldNoRef, IntValue);
            6:
                Child.Validate(CodeRef, CodeValue);
            7:
                Child.Validate(CondRef, CodeValue);
        end;
    end;

    local procedure Probe(Name: Text; var Child: Record "LT PnF FF Child"; FieldNo: Integer; IntValue: Integer; CodeValue: Code[20]; var Observer: Codeunit "Probe Observer")
    begin
        if TryValidate(Child, FieldNo, IntValue, CodeValue) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
    end;

    local procedure Seed()
    var
        Parent: Record "LT PnF FF Parent";
        Target: Record "LT PnF FF Target";
        Child: Record "LT PnF FF Child";
    begin
        Parent.DeleteAll();
        Target.DeleteAll();
        Child.DeleteAll();
        Parent.Id := 1;
        Parent.TargetTableNo := Database::"LT PnF FF Parent";
        Parent.Grp := 'G1';
        Parent.Insert();
        Parent.Id := 2;
        Parent.TargetTableNo := Database::"LT PnF FF Target";
        Parent.Grp := 'G2';
        Parent.Insert();
        Target.Code := 'T1';
        Target.Grp := 'G1';
        Target.Insert();
        Target.Code := 'T2';
        Target.Grp := 'G2';
        Target.Insert();
        Child.Id := 1;
        Child.ParentId := 1;
        Child.Insert();
        Child.Id := 2;
        Child.ParentId := 2;
        Child.Insert();
    end;

    [Test]
    procedure FlowRelation_Integer_NoCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "LT PnF FF Child";
    begin
        Seed();
        Child.Get(1);
        Probe('field_1_of_parent', Child, 5, 1, '', Observer);
        Probe('field_3_of_parent', Child, 5, 3, '', Observer);
        Probe('field_4_of_parent', Child, 5, 4, '', Observer);
        Probe('field_999', Child, 5, 999, '', Observer);
        Child.Get(2);
        Probe('child2_field_1', Child, 5, 1, '', Observer);
        Probe('child2_field_3', Child, 5, 3, '', Observer);
        Observer.Expect('field_1_of_parent', 'ok');
        Observer.Expect('field_3_of_parent', 'ok');
        Observer.Expect('field_4_of_parent|text', 'The field FieldNoRef of table LT PnF FF Child contains a value (4) that cannot be found in the related table (Field).');
        Observer.Expect('field_4_of_parent|code', 'DB:RecordNotFound');
        Observer.Expect('field_999|text', 'The field FieldNoRef of table LT PnF FF Child contains a value (999) that cannot be found in the related table (Field).');
        Observer.Expect('field_999|code', 'DB:RecordNotFound');
        Observer.Expect('child2_field_1', 'ok');
        Observer.Expect('child2_field_3|text', 'The field FieldNoRef of table LT PnF FF Child contains a value (3) that cannot be found in the related table (Field).');
        Observer.Expect('child2_field_3|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure FlowRelation_Integer_AfterCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "LT PnF FF Child";
    begin
        Seed();
        Child.Get(1);
        Child.CalcFields(Flow);
        Probe('field_1_of_parent', Child, 5, 1, '', Observer);
        Probe('field_3_of_parent', Child, 5, 3, '', Observer);
        Probe('field_4_of_parent', Child, 5, 4, '', Observer);
        Probe('field_999', Child, 5, 999, '', Observer);
        Child.Get(2);
        Child.CalcFields(Flow);
        Probe('child2_field_1', Child, 5, 1, '', Observer);
        Probe('child2_field_3', Child, 5, 3, '', Observer);
        Observer.Expect('field_1_of_parent', 'ok');
        Observer.Expect('field_3_of_parent', 'ok');
        Observer.Expect('field_4_of_parent|text', 'The field FieldNoRef of table LT PnF FF Child contains a value (4) that cannot be found in the related table (Field).');
        Observer.Expect('field_4_of_parent|code', 'DB:RecordNotFound');
        Observer.Expect('field_999|text', 'The field FieldNoRef of table LT PnF FF Child contains a value (999) that cannot be found in the related table (Field).');
        Observer.Expect('field_999|code', 'DB:RecordNotFound');
        Observer.Expect('child2_field_1', 'ok');
        Observer.Expect('child2_field_3|text', 'The field FieldNoRef of table LT PnF FF Child contains a value (3) that cannot be found in the related table (Field).');
        Observer.Expect('child2_field_3|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure FlowRelation_Code_NoCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "LT PnF FF Child";
    begin
        Seed();
        Child.Get(1);
        Probe('g1_row_T1', Child, 6, 0, 'T1', Observer);
        Probe('g1_row_T2', Child, 6, 0, 'T2', Observer);
        Probe('g1_row_missing', Child, 6, 0, 'NOPE', Observer);
        Child.Get(2);
        Probe('g2_row_T2', Child, 6, 0, 'T2', Observer);
        Probe('g2_row_T1', Child, 6, 0, 'T1', Observer);
        Observer.Expect('g1_row_T1', 'ok');
        Observer.Expect('g1_row_T2|text', 'The field CodeRef of table LT PnF FF Child contains a value (T2) that cannot be found in the related table (LT PnF FF Target).');
        Observer.Expect('g1_row_T2|code', 'DB:NothingInsideFilter');
        Observer.Expect('g1_row_missing|text', 'The field CodeRef of table LT PnF FF Child contains a value (NOPE) that cannot be found in the related table (LT PnF FF Target).');
        Observer.Expect('g1_row_missing|code', 'DB:NothingInsideFilter');
        Observer.Expect('g2_row_T2', 'ok');
        Observer.Expect('g2_row_T1|text', 'The field CodeRef of table LT PnF FF Child contains a value (T1) that cannot be found in the related table (LT PnF FF Target).');
        Observer.Expect('g2_row_T1|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure FlowRelation_Code_AfterCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "LT PnF FF Child";
    begin
        Seed();
        Child.Get(1);
        Child.CalcFields(FlowCode);
        Probe('g1_row_T1', Child, 6, 0, 'T1', Observer);
        Probe('g1_row_T2', Child, 6, 0, 'T2', Observer);
        Probe('g1_row_missing', Child, 6, 0, 'NOPE', Observer);
        Child.Get(2);
        Child.CalcFields(FlowCode);
        Probe('g2_row_T2', Child, 6, 0, 'T2', Observer);
        Probe('g2_row_T1', Child, 6, 0, 'T1', Observer);
        Observer.Expect('g1_row_T1', 'ok');
        Observer.Expect('g1_row_T2|text', 'The field CodeRef of table LT PnF FF Child contains a value (T2) that cannot be found in the related table (LT PnF FF Target).');
        Observer.Expect('g1_row_T2|code', 'DB:NothingInsideFilter');
        Observer.Expect('g1_row_missing|text', 'The field CodeRef of table LT PnF FF Child contains a value (NOPE) that cannot be found in the related table (LT PnF FF Target).');
        Observer.Expect('g1_row_missing|code', 'DB:NothingInsideFilter');
        Observer.Expect('g2_row_T2', 'ok');
        Observer.Expect('g2_row_T1|text', 'The field CodeRef of table LT PnF FF Child contains a value (T1) that cannot be found in the related table (LT PnF FF Target).');
        Observer.Expect('g2_row_T1|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure FlowRelation_Condition_NoCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "LT PnF FF Child";
    begin
        Seed();
        Child.Get(1);
        Probe('row1_T1', Child, 7, 0, 'T1', Observer);
        Probe('row1_T2', Child, 7, 0, 'T2', Observer);
        Child.Get(2);
        Probe('row2_T1', Child, 7, 0, 'T1', Observer);
        Probe('row2_T2', Child, 7, 0, 'T2', Observer);
        Observer.Expect('row1_T1', 'ok');
        Observer.Expect('row1_T2|text', 'The field CondRef of table LT PnF FF Child contains a value (T2) that cannot be found in the related table (LT PnF FF Target).');
        Observer.Expect('row1_T2|code', 'DB:NothingInsideFilter');
        Observer.Expect('row2_T1|text', 'The field CondRef of table LT PnF FF Child contains a value (T1) that cannot be found in the related table (LT PnF FF Target).');
        Observer.Expect('row2_T1|code', 'DB:NothingInsideFilter');
        Observer.Expect('row2_T2', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure FlowRelation_Condition_AfterCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "LT PnF FF Child";
    begin
        Seed();
        Child.Get(1);
        Child.CalcFields(FlowCode);
        Probe('row1_T1', Child, 7, 0, 'T1', Observer);
        Probe('row1_T2', Child, 7, 0, 'T2', Observer);
        Child.Get(2);
        Child.CalcFields(FlowCode);
        Probe('row2_T1', Child, 7, 0, 'T1', Observer);
        Probe('row2_T2', Child, 7, 0, 'T2', Observer);
        Observer.Expect('row1_T1', 'ok');
        Observer.Expect('row1_T2|text', 'The field CondRef of table LT PnF FF Child contains a value (T2) that cannot be found in the related table (LT PnF FF Target).');
        Observer.Expect('row1_T2|code', 'DB:NothingInsideFilter');
        Observer.Expect('row2_T1|text', 'The field CondRef of table LT PnF FF Child contains a value (T1) that cannot be found in the related table (LT PnF FF Target).');
        Observer.Expect('row2_T1|code', 'DB:NothingInsideFilter');
        Observer.Expect('row2_T2', 'ok');
        Observer.Verify();
    end;
}
