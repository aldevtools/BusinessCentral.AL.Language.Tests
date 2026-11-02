// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 67171 - 67176
// Probe: TableRelation arms. (1) An Option with a blank first member (" ") used as const(" ") in an if/else chain of two tables: Validate of a value of each table with
// the option at each member; (2) rename of a parent row that rows of different kinds reference, where the relation is `if (Kind = filter(<> C)) Parent.Code`:
// the reference field of every row afterwards; (3) a relation with two where() conditions on non-key fields of the target: Validate with a value that fails
// none, one or both conditions, and its error text and code. Settles: relation-option-blank-const, rename-follows-filter-condition-arms,
// table-relation-several-where-non-key. Object ids 67171 - 67177.

table 67171 "LT TR One"
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

table 67172 "LT TR Two"
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

table 67173 "LT TR Option Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = " ",A; }
        field(3; Ref; Code[10])
        {
            TableRelation = if (Opt = const(" ")) "LT TR One" else
            if (Opt = const(A)) "LT TR Two";
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 67174 "LT TR Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Active; Boolean) { }
        field(3; Kind; Option) { OptionMembers = A,B; }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 67175 "LT TR Kind Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = A,B,C; }
        field(3; Ref; Code[10]) { TableRelation = if (Kind = filter(<> C)) "LT TR Parent".Code; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 67176 "LT TR Where Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; Code[10]) { TableRelation = "LT TR Parent".Code where(Active = const(true), Kind = const(A)); }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Writer Y76 (al-runtime-rs assumptions rename-follows-filter-condition-arms and table-relation-several-where-non-key): more filter forms in the
// condition of an arm, and a relation with where() conditions on key and non-key fields of the target. Object ids 94050 - 94055.
table 94050 "LT Y76 Rel Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 94051 "LT Y76 Rel Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
        field(3; Kind; Option) { OptionMembers = A,B,C,D; }
        field(4; Amt; Decimal) { }
        field(10; RefNegative; Code[10]) { TableRelation = if (Qty = filter(< 0)) "LT Y76 Rel Parent".Code; }
        field(11; RefNotBAndC; Code[10]) { TableRelation = if (Kind = filter(<> B & <> C)) "LT Y76 Rel Parent".Code; }
        field(12; RefRange; Code[10]) { TableRelation = if (Qty = filter(1..3)) "LT Y76 Rel Parent".Code; }
        field(13; RefOr; Code[10]) { TableRelation = if (Kind = filter(A | C)) "LT Y76 Rel Parent".Code; }
        field(14; RefDecimal; Code[10]) { TableRelation = if (Amt = filter(>=0.5 & <3)) "LT Y76 Rel Parent".Code; }
        field(15; RefAtLeast; Code[10]) { TableRelation = if (Qty = filter(>= 5)) "LT Y76 Rel Parent".Code; }
        field(16; RefElse; Code[10]) { TableRelation = if (Qty = filter(< 0)) "LT Y76 Rel Parent".Code else "LT Y76 Rel Parent".Code where(Name = const('')); }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 94052 "LT Y76 Rel Keyed"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Grp; Code[10]) { }
        field(2; Code; Code[10]) { }
        field(3; Active; Boolean) { }
        field(4; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Grp, Code) { Clustered = true; }
    }
}

table 94053 "LT Y76 Rel Mix Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; KeyAndNonKey; Code[10]) { TableRelation = "LT Y76 Rel Keyed".Code where(Grp = const('G1'), Active = const(true)); }
        field(3; KeyOnly; Code[10]) { TableRelation = "LT Y76 Rel Keyed".Code where(Grp = const('G1')); }
        field(4; TwoKeys; Code[10]) { TableRelation = "LT Y76 Rel Keyed".Code where(Grp = const('G1'), Code = filter(<> 'Z')); }
        field(5; ThreeNonKey; Code[10]) { TableRelation = "LT Y76 Rel Keyed".Code where(Active = const(true), Flag = const(false), Grp = filter(<> '')); }
        field(6; TwoNonKey; Code[10]) { TableRelation = "LT Y76 Rel Keyed".Code where(Active = const(true), Flag = const(false)); }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67177 "LT TR Arms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        One: Record "LT TR One";
        Two: Record "LT TR Two";
        Parent: Record "LT TR Parent";
    begin
        One.DeleteAll();
        Two.DeleteAll();
        Parent.DeleteAll();
        One.Code := 'ONE';
        One.Insert();
        Two.Code := 'TWO';
        Two.Insert();
        AddParent('P1', true, 0);
        AddParent('ACTIVEB', true, 1);
        AddParent('INACTIVEA', false, 0);
        AddParent('INACTIVEB', false, 1);
    end;

    local procedure AddParent(Code: Code[10]; Active: Boolean; Kind: Integer)
    var
        Parent: Record "LT TR Parent";
    begin
        Parent.Init();
        Parent.Code := Code;
        Parent.Active := Active;
        Parent.Kind := Kind;
        Parent.Insert();
    end;

    [TryFunction]
    local procedure TryValidateOption(Opt: Integer; Value: Code[10])
    var
        Child: Record "LT TR Option Child";
    begin
        Child.Init();
        Child.Opt := Opt;
        Child.Validate(Ref, Value);
    end;

    local procedure OptionOutcome(Opt: Integer; Value: Code[10]): Text
    begin
        ClearLastError();
        if TryValidateOption(Opt, Value) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure OptionBlankConst_ArmPerMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('blank_opt_value_of_one', OptionOutcome(0, 'ONE'));
        Observer.Observe('blank_opt_value_of_two', OptionOutcome(0, 'TWO'));
        Observer.Observe('blank_opt_missing', OptionOutcome(0, 'NONE'));
        Observer.Observe('a_opt_value_of_one', OptionOutcome(1, 'ONE'));
        Observer.Observe('a_opt_value_of_two', OptionOutcome(1, 'TWO'));
        Observer.Observe('a_opt_missing', OptionOutcome(1, 'NONE'));
        Observer.Observe('blank_opt_blank_value', OptionOutcome(0, ''));
        Observer.Expect('blank_opt_value_of_one', 'ok');
        Observer.Expect('blank_opt_value_of_two', 'error:The field Ref of table LT TR Option Child contains a value (TWO) that cannot be found in the related table (LT TR One).|DB:PrimRecordNotFound');
        Observer.Expect('blank_opt_missing', 'error:The field Ref of table LT TR Option Child contains a value (NONE) that cannot be found in the related table (LT TR One).|DB:PrimRecordNotFound');
        Observer.Expect('a_opt_value_of_one', 'error:The field Ref of table LT TR Option Child contains a value (ONE) that cannot be found in the related table (LT TR Two).|DB:PrimRecordNotFound');
        Observer.Expect('a_opt_value_of_two', 'ok');
        Observer.Expect('a_opt_missing', 'error:The field Ref of table LT TR Option Child contains a value (NONE) that cannot be found in the related table (LT TR Two).|DB:PrimRecordNotFound');
        Observer.Expect('blank_opt_blank_value', 'ok');
        Observer.Verify();
    end;

    local procedure KindChild(Id: Integer; Kind: Integer; Ref: Code[10])
    var
        Child: Record "LT TR Kind Child";
    begin
        Child.Init();
        Child.Id := Id;
        Child.Kind := Kind;
        Child.Ref := Ref;
        Child.Insert();
    end;

    local procedure RefOf(Id: Integer): Text
    var
        Child: Record "LT TR Kind Child";
    begin
        if not Child.Get(Id) then
            exit('<missing>');
        exit(Child.Ref);
    end;

    [Test]
    procedure Rename_FollowsOnlyTheArmsThatApply()
    var
        Parent: Record "LT TR Parent";
        Child: Record "LT TR Kind Child";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Child.DeleteAll();
        KindChild(1, 0, 'P1');
        KindChild(2, 1, 'P1');
        KindChild(3, 2, 'P1');
        Parent.Get('P1');
        Parent.Rename('P2');
        Observer.Observe('kind_a_ref', RefOf(1));
        Observer.Observe('kind_b_ref', RefOf(2));
        Observer.Observe('kind_c_ref', RefOf(3));
        Observer.Expect('kind_a_ref', 'P2');
        Observer.Expect('kind_b_ref', 'P2');
        Observer.Expect('kind_c_ref', 'P1');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryValidateWhere(Value: Code[10])
    var
        Child: Record "LT TR Where Child";
    begin
        Child.Init();
        Child.Validate(Ref, Value);
    end;

    local procedure WhereOutcome(Value: Code[10]): Text
    begin
        ClearLastError();
        if TryValidateWhere(Value) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure SeveralWhere_NonKeyFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('active_and_kind_a', WhereOutcome('P1'));
        Observer.Observe('active_kind_b', WhereOutcome('ACTIVEB'));
        Observer.Observe('inactive_kind_a', WhereOutcome('INACTIVEA'));
        Observer.Observe('inactive_kind_b', WhereOutcome('INACTIVEB'));
        Observer.Observe('missing', WhereOutcome('MISSING'));
        Observer.Observe('blank', WhereOutcome(''));
        Observer.Expect('active_and_kind_a', 'ok');
        Observer.Expect('active_kind_b', 'error:The field Ref of table LT TR Where Child contains a value (ACTIVEB) that cannot be found in the related table (LT TR Parent).|DB:NothingInsideFilter');
        Observer.Expect('inactive_kind_a', 'error:The field Ref of table LT TR Where Child contains a value (INACTIVEA) that cannot be found in the related table (LT TR Parent).|DB:NothingInsideFilter');
        Observer.Expect('inactive_kind_b', 'error:The field Ref of table LT TR Where Child contains a value (INACTIVEB) that cannot be found in the related table (LT TR Parent).|DB:NothingInsideFilter');
        Observer.Expect('missing', 'error:The field Ref of table LT TR Where Child contains a value (MISSING) that cannot be found in the related table (LT TR Parent).|DB:NothingInsideFilter');
        Observer.Expect('blank', 'ok');
        Observer.Verify();
    end;

    local procedure Y76ChildRow(Id: Integer; Qty: Integer; Kind: Integer; Amt: Decimal)
    var
        Child: Record "LT Y76 Rel Child";
    begin
        Child.Init();
        Child.Id := Id;
        Child.Qty := Qty;
        Child.Kind := Kind;
        Child.Amt := Amt;
        Child.RefNegative := 'P1';
        Child.RefNotBAndC := 'P1';
        Child.RefRange := 'P1';
        Child.RefOr := 'P1';
        Child.RefDecimal := 'P1';
        Child.RefAtLeast := 'P1';
        Child.RefElse := 'P1';
        Child.Insert();
    end;

    local procedure Y76Refs(Id: Integer): Text
    var
        Child: Record "LT Y76 Rel Child";
        Result: Text;
    begin
        if not Child.Get(Id) then
            exit('<missing>');
        Result := Child.RefNegative + ',' + Child.RefNotBAndC + ',' + Child.RefRange + ',' + Child.RefOr + ',' + Child.RefDecimal + ',' + Child.RefAtLeast + ',' + Child.RefElse;
        exit(Result);
    end;

    [Test]
    procedure Y76_Rename_FollowsFilterArms()
    var
        Parent: Record "LT Y76 Rel Parent";
        Child: Record "LT Y76 Rel Child";
        Observer: Codeunit "Probe Observer";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Parent.Code := 'P1';
        Parent.Insert();
        // Id, Qty, Kind (0=A 1=B 2=C 3=D), Amt
        Y76ChildRow(1, -1, 0, 0.5);
        Y76ChildRow(2, 0, 1, 0);
        Y76ChildRow(3, 2, 2, 2.9);
        Y76ChildRow(4, 7, 3, 3);
        Parent.Get('P1');
        Parent.Rename('P2');
        Observer.Observe('row1_qty-1_A_0.5', Y76Refs(1));
        Observer.Observe('row2_qty0_B_0', Y76Refs(2));
        Observer.Observe('row3_qty2_C_2.9', Y76Refs(3));
        Observer.Observe('row4_qty7_D_3', Y76Refs(4));
        Observer.Finish();
    end;

    local procedure Y76SeedKeyed()
    var
        Keyed: Record "LT Y76 Rel Keyed";
    begin
        Keyed.DeleteAll();
        Y76AddKeyed('G1', 'A', true, false);
        Y76AddKeyed('G1', 'B', false, false);
        Y76AddKeyed('G2', 'C', true, false);
        Y76AddKeyed('G2', 'D', false, true);
        Y76AddKeyed('G1', 'Z', true, false);
        Y76AddKeyed('G1', 'F', true, true);
    end;

    local procedure Y76AddKeyed(Grp: Code[10]; Code: Code[10]; Active: Boolean; Flag: Boolean)
    var
        Keyed: Record "LT Y76 Rel Keyed";
    begin
        Keyed.Init();
        Keyed.Grp := Grp;
        Keyed.Code := Code;
        Keyed.Active := Active;
        Keyed.Flag := Flag;
        Keyed.Insert();
    end;

    [TryFunction]
    local procedure Y76TryValidate(FieldNo: Integer; Value: Code[10])
    var
        Child: Record "LT Y76 Rel Mix Child";
    begin
        Child.Init();
        case FieldNo of
            2:
                Child.Validate(KeyAndNonKey, Value);
            3:
                Child.Validate(KeyOnly, Value);
            4:
                Child.Validate(TwoKeys, Value);
            5:
                Child.Validate(ThreeNonKey, Value);
            6:
                Child.Validate(TwoNonKey, Value);
        end;
    end;

    local procedure Y76Outcome(FieldNo: Integer; Value: Code[10]): Text
    begin
        ClearLastError();
        if Y76TryValidate(FieldNo, Value) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Y76_SeveralWhere_KeyAndNonKey_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y76SeedKeyed();
        Observer.Observe('keynonkey_A', Y76Outcome(2, 'A'));
        Observer.Observe('keynonkey_B_inactive', Y76Outcome(2, 'B'));
        Observer.Observe('keynonkey_C_other_group', Y76Outcome(2, 'C'));
        Observer.Observe('keynonkey_missing', Y76Outcome(2, 'MISSING'));
        Observer.Observe('keyonly_A', Y76Outcome(3, 'A'));
        Observer.Observe('keyonly_C_other_group', Y76Outcome(3, 'C'));
        Observer.Observe('keyonly_missing', Y76Outcome(3, 'MISSING'));
        Observer.Observe('twokeys_A', Y76Outcome(4, 'A'));
        Observer.Observe('twokeys_Z_excluded', Y76Outcome(4, 'Z'));
        Observer.Observe('twokeys_C_other_group', Y76Outcome(4, 'C'));
        Observer.Finish();
    end;

    [Test]
    procedure Y76_SeveralWhere_NonKeyOnly_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y76SeedKeyed();
        Observer.Observe('three_A', Y76Outcome(5, 'A'));
        Observer.Observe('three_D_flag', Y76Outcome(5, 'D'));
        Observer.Observe('three_B_inactive', Y76Outcome(5, 'B'));
        Observer.Observe('three_missing', Y76Outcome(5, 'MISSING'));
        Observer.Observe('two_A', Y76Outcome(6, 'A'));
        Observer.Observe('two_F_flag', Y76Outcome(6, 'F'));
        Observer.Observe('two_missing', Y76Outcome(6, 'MISSING'));
        Observer.Observe('two_blank', Y76Outcome(6, ''));
        Observer.Finish();
    end;
}
