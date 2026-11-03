// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: An array indexed by an Option member: A[Opt::Amount] is the element at the member ordinal (assumption array-index-by-option); a member beyond the bound; the same for an Enum ordinal cast and an option field member.
// BC versions: 29 (27 and 28 by CI)

table 70396 "LT ArrOpt Row"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; Kind; Option) { OptionMembers = ,A,B,C,D; }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 70395 "LT ArrOpt Index"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GlobalKind: Option ,A,B,C,D;

    [Test]
    procedure ArrayIndex_OptionMember_Result()
    var
        Observer: Codeunit "Probe Observer";
        Amounts: array[4] of Decimal;
        Kind: Option ,A,B,C,D;
        I: Integer;
    begin
        Amounts[Kind::A] := 11;
        Amounts[Kind::B] := 22;
        Amounts[Kind::C] := 33;
        Amounts[Kind::D] := 44;
        for I := 1 to 4 do
            Observer.Observe('by_int_' + Format(I), Format(Amounts[I]));
        Observer.Observe('by_member_A', Format(Amounts[Kind::A]));
        Observer.Observe('by_member_D', Format(Amounts[Kind::D]));
        Observer.Observe('member_A_ordinal', Format(Kind::A));
        Observer.Expect('by_int_1', '11');
        Observer.Expect('by_int_2', '22');
        Observer.Expect('by_int_3', '33');
        Observer.Expect('by_int_4', '44');
        Observer.Expect('by_member_A', '11');
        Observer.Expect('by_member_D', '44');
        Observer.Expect('member_A_ordinal', 'A');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayIndex_OptionVariable_Result()
    var
        Observer: Codeunit "Probe Observer";
        Amounts: array[4] of Decimal;
        Kind: Option ,A,B,C,D;
        I: Integer;
    begin
        for I := 1 to 4 do
            Amounts[I] := I * 100;
        Kind := Kind::C;
        Observer.Observe('var_C', Format(Amounts[Kind]));
        Amounts[Kind] := 999;
        Observer.Observe('after_write_3', Format(Amounts[3]));
        Observer.Observe('after_write_2', Format(Amounts[2]));
        GlobalKind := GlobalKind::B;
        Observer.Observe('global_B', Format(Amounts[GlobalKind]));
        Observer.Expect('var_C', '300');
        Observer.Expect('after_write_3', '999');
        Observer.Expect('after_write_2', '200');
        Observer.Expect('global_B', '200');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayIndex_OptionBeyondBound_Result()
    var
        Observer: Codeunit "Probe Observer";
        Amounts: array[3] of Decimal;
        Kind: Option ,A,B,C,D;
        Value: Decimal;
    begin
        Amounts[1] := 1;
        Amounts[2] := 2;
        Amounts[3] := 3;
        Kind := Kind::C;
        Observer.Observe('within_bound_C', Format(Amounts[Kind]));
        Kind := Kind::D;
        asserterror Value := Amounts[Kind];
        Observer.ObserveError('beyond_read_D');
        asserterror Amounts[Kind] := 4;
        Observer.ObserveError('beyond_write_D');
        Kind := 0;
        asserterror Value := Amounts[Kind];
        Observer.ObserveError('blank_member_zero_index');
        Observer.Expect('within_bound_C', '3');
        Observer.Expect('beyond_read_D|text', 'Index out of bounds.');
        Observer.Expect('beyond_read_D|code', 'IndexOutOfBounds');
        Observer.Expect('beyond_write_D|text', 'Index out of bounds.');
        Observer.Expect('beyond_write_D|code', 'IndexOutOfBounds');
        Observer.Expect('blank_member_zero_index|text', 'Index out of bounds.');
        Observer.Expect('blank_member_zero_index|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayIndex_OptionFieldValue_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT ArrOpt Row";
        Amounts: array[4] of Text;
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 4 do
            Amounts[I] := 'v' + Format(I);
        Row."No." := 1;
        Row.Kind := Row.Kind::D;
        Row.Insert();
        Observer.Observe('field_D', Amounts[Row.Kind]);
        Row.Kind := Row.Kind::A;
        Observer.Observe('field_A', Amounts[Row.Kind]);
        Observer.Expect('field_D', 'v4');
        Observer.Expect('field_A', 'v1');
        Observer.Verify();
    end;
}
