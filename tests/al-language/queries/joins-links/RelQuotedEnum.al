// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enum 70772, own tables 70771 and 70773, test codeunit 70776
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TableRelation where(F = filter(A | "B C")) with a quoted identifier inside filter(): Validate of a value whose F is each member, outside the filter, unknown and blank; error text start and code via TryFunction
// BC versions: 29 (27 and 28 by CI)
// Added by writer BN3 (corpus #664 item 72): table 83868 and BN3_Validate_EnumConstAndFieldRelation (TableRelation where(F = const/field) on an Enum).

enum 70772 "LT P100 Letter"
{
    Extensible = true;
    value(0; A) { }
    value(1; "B C") { }
    value(2; D) { }
}

table 70771 "LT P100 Item En"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; F; Enum "LT P100 Letter") { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

table 70773 "LT P100 Rel En"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; Code[10])
        {
            TableRelation = "LT P100 Item En".Code where(F = filter(A | "B C"));
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70776 "LT P100 Rel Quoted En"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT P100 Item En";
    begin
        Item.DeleteAll();
        Item.Init();
        Item.Code := 'IA';
        Item.F := "LT P100 Letter"::A;
        Item.Insert();
        Item.Init();
        Item.Code := 'IBC';
        Item.F := "LT P100 Letter"::"B C";
        Item.Insert();
        Item.Init();
        Item.Code := 'ID';
        Item.F := "LT P100 Letter"::D;
        Item.Insert();
    end;

    [TryFunction]
    local procedure TryRef(var R: Record "LT P100 Rel En"; V: Code[10])
    begin
        R.Validate(Ref, V);
    end;

    local procedure Outcome(V: Code[10]): Text
    var
        R: Record "LT P100 Rel En";
    begin
        R.Init();
        if TryRef(R, V) then
            exit('ok:' + R.Ref);
        exit('error:' + CopyStr(GetLastErrorText(), 1, 90) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P100_Validate_EachKind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('v_ia', Outcome('IA'));
        Observer.Observe('v_ibc', Outcome('IBC'));
        Observer.Observe('v_id', Outcome('ID'));
        Observer.Observe('v_nope', Outcome('NOPE'));
        Observer.Observe('v_blank', Outcome(''));
        Observer.Expect('v_ia', 'ok:IA');
        Observer.Expect('v_ibc', 'ok:IBC');
        Observer.Expect('v_id', 'error:The field Ref of table LT P100 Rel En contains a value (ID) that cannot be found in the re|DB:NothingInsideFilter');
        Observer.Expect('v_nope', 'error:The field Ref of table LT P100 Rel En contains a value (NOPE) that cannot be found in the |DB:NothingInsideFilter');
        Observer.Expect('v_blank', 'ok:');
        Observer.Verify();
    end;

    [Test]
    procedure P100_Validate_ErrorAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P100 Rel En";
    begin
        Seed();
        R.Validate(Ref, 'IA');
        Observer.Observe('e_ia', 'no error');
        R.Validate(Ref, 'IBC');
        Observer.Observe('e_ibc', 'no error');
        asserterror R.Validate(Ref, 'ID');
        Observer.ObserveError('e_id');
        asserterror R.Validate(Ref, 'NOPE');
        Observer.ObserveError('e_nope');
        Observer.Expect('e_ia', 'no error');
        Observer.Expect('e_ibc', 'no error');
        Observer.Expect('e_id|text', 'The field Ref of table LT P100 Rel En contains a value (ID) that cannot be found in the related table (LT P100 Item En).');
        Observer.Expect('e_id|code', 'DB:NothingInsideFilter');
        Observer.Expect('e_nope|text', 'The field Ref of table LT P100 Rel En contains a value (NOPE) that cannot be found in the related table (LT P100 Item En).');
        Observer.Expect('e_nope|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure P100_Assign_Then_Validate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P100 Rel En";
    begin
        Seed();
        R.Init();
        R.Ref := 'NOPE';
        Observer.Observe('assigned', R.Ref);
        R.Validate(Ref, '');
        Observer.Observe('blank_ok', R.Ref);
        R.Validate(Ref, 'IA');
        Observer.Observe('first_ok', R.Ref);
        asserterror R.Validate(Ref, 'NOPE');
        Observer.ObserveError('then_nope');
        Observer.Observe('kept', R.Ref);
        Observer.Expect('assigned', 'NOPE');
        Observer.Expect('blank_ok', '');
        Observer.Expect('first_ok', 'IA');
        Observer.Expect('then_nope|text', 'The field Ref of table LT P100 Rel En contains a value (NOPE) that cannot be found in the related table (LT P100 Item En).');
        Observer.Expect('then_nope|code', 'DB:NothingInsideFilter');
        Observer.Expect('kept', 'IA');
        Observer.Verify();
    end;

    [Test]
    procedure P100_Item_FilterByHand()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P100 Item En";
    begin
        Seed();
        Observer.Observe('count', Format(Item.Count()));
        Item.SetFilter(F, 'A|B C');
        Observer.Observe('hand_filter_count', Format(Item.Count()));
        Observer.Observe('hand_filter_text', Item.GetFilter(F));
        Observer.Expect('count', '3');
        Observer.Expect('hand_filter_count', '2');
        Observer.Expect('hand_filter_text', 'A|B C');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure BN3_TryValidate(var R: Record "LT BN3 Rel En2"; FieldNo: Integer; V: Code[10])
    begin
        case FieldNo of
            R.FieldNo(RefConst):
                R.Validate(RefConst, V);
            R.FieldNo(RefConstQuoted):
                R.Validate(RefConstQuoted, V);
            R.FieldNo(RefField):
                R.Validate(RefField, V);
        end;
    end;

    local procedure BN3_Outcome(MyF: Enum "LT P100 Letter"; FieldNo: Integer; V: Code[10]): Text
    var
        R: Record "LT BN3 Rel En2";
    begin
        R.Init();
        R.MyF := MyF;
        if BN3_TryValidate(R, FieldNo, V) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Corpus #664 item 72: Validate against TableRelation where(F = const(D)), where(F = const("B C")) and where(F = field(MyF)) on an Enum field.
    [Test]
    procedure BN3_Validate_EnumConstAndFieldRelation()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT BN3 Rel En2";
    begin
        Seed();
        Observer.Observe('const D: ID', BN3_Outcome("LT P100 Letter"::A, R.FieldNo(RefConst), 'ID'));
        Observer.Observe('const D: IA', BN3_Outcome("LT P100 Letter"::A, R.FieldNo(RefConst), 'IA'));
        Observer.Observe('const "B C": IBC', BN3_Outcome("LT P100 Letter"::A, R.FieldNo(RefConstQuoted), 'IBC'));
        Observer.Observe('const "B C": ID', BN3_Outcome("LT P100 Letter"::A, R.FieldNo(RefConstQuoted), 'ID'));
        Observer.Observe('field MyF=A: IA', BN3_Outcome("LT P100 Letter"::A, R.FieldNo(RefField), 'IA'));
        Observer.Observe('field MyF=A: ID', BN3_Outcome("LT P100 Letter"::A, R.FieldNo(RefField), 'ID'));
        Observer.Observe('field MyF=D: ID', BN3_Outcome("LT P100 Letter"::D, R.FieldNo(RefField), 'ID'));
        Observer.Observe('field MyF="B C": IBC', BN3_Outcome("LT P100 Letter"::"B C", R.FieldNo(RefField), 'IBC'));
        Observer.Expect('const D: ID', 'ok');
        Observer.Expect('const D: IA', 'error:The field RefConst of table LT BN3 Rel En2 contains a value (IA) that cannot be found in the related table (LT P100 Item En).|DB:NothingInsideFilter');
        Observer.Expect('const "B C": IBC', 'ok');
        Observer.Expect('const "B C": ID', 'error:The field RefConstQuoted of table LT BN3 Rel En2 contains a value (ID) that cannot be found in the related table (LT P100 Item En).|DB:NothingInsideFilter');
        Observer.Expect('field MyF=A: IA', 'ok');
        Observer.Expect('field MyF=A: ID', 'error:The field RefField of table LT BN3 Rel En2 contains a value (ID) that cannot be found in the related table (LT P100 Item En).|DB:NothingInsideFilter');
        Observer.Expect('field MyF=D: ID', 'ok');
        Observer.Expect('field MyF="B C": IBC', 'ok');
        Observer.Verify();
    end;
}

// Corpus #664 item 72 (microsoft/AL issue 4567): TableRelation where(F = const(enum value)) and where(F = field(enum field)) on an Enum field.
table 83868 "LT BN3 Rel En2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; MyF; Enum "LT P100 Letter") { }
        field(3; RefConst; Code[10])
        {
            TableRelation = "LT P100 Item En".Code where(F = const(D));
        }
        field(4; RefConstQuoted; Code[10])
        {
            TableRelation = "LT P100 Item En".Code where(F = const("B C"));
        }
        field(5; RefField; Code[10])
        {
            TableRelation = "LT P100 Item En".Code where(F = field(MyF));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
