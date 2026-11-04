// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-procedure-overloading
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 71158, codeunit 71159
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles GitHub issue #69 (Inferred behaviors waiting for a pin): overload choice, exact type versus Variant
// Facts: which overload runs for a RecordRef, Integer, Text, Record, Decimal, BigInteger argument, observed through a returned tag
// BC versions: 29 (27 and 28 by CI)
// Added by writer BN3 (corpus #664 item 74): enums 83869, 83870 and BN3_Overload_DifferOnlyByEnumType; an Integer argument is ambiguous (must-not-compile 1560).

table 71158 "LT P69 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 71159 "LT P69 Overloads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tag(V: Variant): Text
    begin
        exit('variant');
    end;

    local procedure Tag(R: RecordRef): Text
    begin
        exit('recordref');
    end;

    local procedure Kind(I: Integer): Text
    begin
        exit('integer');
    end;

    local procedure Kind(V: Variant): Text
    begin
        exit('variant');
    end;

    local procedure Txt(T: Text): Text
    begin
        exit('text');
    end;

    local procedure Txt(V: Variant): Text
    begin
        exit('variant');
    end;

    local procedure Rec(R: Record "LT P69 Row"): Text
    begin
        exit('record');
    end;

    local procedure Rec(V: Variant): Text
    begin
        exit('variant');
    end;

    local procedure Num(D: Decimal): Text
    begin
        exit('decimal');
    end;

    local procedure Num(I: Integer): Text
    begin
        exit('integer');
    end;

    local procedure Num(B: BigInteger): Text
    begin
        exit('biginteger');
    end;

    local procedure Cd(C: Code[20]): Text
    begin
        exit('code');
    end;

    local procedure Cd(T: Text): Text
    begin
        exit('text');
    end;

    local procedure Bl(B: Boolean): Text
    begin
        exit('boolean');
    end;

    local procedure Bl(V: Variant): Text
    begin
        exit('variant');
    end;

    [Test]
    procedure Overload_RecordRefVsVariant()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Row: Record "LT P69 Row";
        V: Variant;
        R: Integer;
    begin
        RecRef.Open(Database::"LT P69 Row");
        Observer.Observe('recordref_var', Tag(RecRef));
        V := RecRef;
        Observer.Observe('variant_holding_recordref', Tag(V));
        Observer.Observe('record_var', Tag(Row));
        V := Row;
        Observer.Observe('variant_holding_record', Tag(V));
        R := 5;
        Observer.Observe('integer_var', Tag(R));
        Observer.Observe('text_literal', Tag('abc'));
        Observer.Observe('integer_literal', Tag(7));
        Observer.Expect('recordref_var', 'recordref');
        Observer.Expect('variant_holding_recordref', 'variant');
        Observer.Expect('record_var', 'variant');
        Observer.Expect('variant_holding_record', 'variant');
        Observer.Expect('integer_var', 'variant');
        Observer.Expect('text_literal', 'variant');
        Observer.Expect('integer_literal', 'variant');
        Observer.Verify();
    end;

    [Test]
    procedure Overload_IntegerVsVariant()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        O: Option A,B;
        V: Variant;
    begin
        I := 3;
        B := 3;
        D := 3;
        V := 3;
        Observer.Observe('integer_var', Kind(I));
        Observer.Observe('integer_literal', Kind(3));
        Observer.Observe('negative_literal', Kind(-3));
        Observer.Observe('biginteger_var', Kind(B));
        Observer.Observe('decimal_var', Kind(D));
        Observer.Observe('decimal_literal', Kind(1.5));
        Observer.Observe('option_var', Kind(O));
        Observer.Observe('variant_var', Kind(V));
        Observer.Observe('text_literal', Kind('x'));
        Observer.Observe('boolean_literal', Kind(true));
        Observer.Observe('big_literal', Kind(3000000000L));
        Observer.Expect('integer_var', 'integer');
        Observer.Expect('integer_literal', 'integer');
        Observer.Expect('negative_literal', 'integer');
        Observer.Expect('biginteger_var', 'variant');
        Observer.Expect('decimal_var', 'variant');
        Observer.Expect('decimal_literal', 'variant');
        Observer.Expect('option_var', 'integer');
        Observer.Expect('variant_var', 'variant');
        Observer.Expect('text_literal', 'variant');
        Observer.Expect('boolean_literal', 'variant');
        Observer.Expect('big_literal', 'variant');
        Observer.Verify();
    end;

    [Test]
    procedure Overload_TextVsVariant()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        T10: Text[10];
        C: Code[10];
        Ch: Char;
        V: Variant;
    begin
        T := 'a';
        T10 := 'b';
        C := 'c';
        V := 'd';
        Observer.Observe('text_var', Txt(T));
        Observer.Observe('text_literal', Txt('lit'));
        Observer.Observe('text10_var', Txt(T10));
        Observer.Observe('code_var', Txt(C));
        Observer.Observe('variant_var', Txt(V));
        Observer.Observe('integer_literal', Txt(5));
        Observer.Observe('char_var', Txt(Ch));
        Observer.Observe('concat', Txt('a' + 'b'));
        Observer.Expect('text_var', 'text');
        Observer.Expect('text_literal', 'text');
        Observer.Expect('text10_var', 'text');
        Observer.Expect('code_var', 'text');
        Observer.Expect('variant_var', 'variant');
        Observer.Expect('integer_literal', 'variant');
        Observer.Expect('char_var', 'text');
        Observer.Expect('concat', 'text');
        Observer.Verify();
    end;

    [Test]
    procedure Overload_RecordVsVariant()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P69 Row";
        V: Variant;
    begin
        Observer.Observe('record_var', Rec(Row));
        V := Row;
        Observer.Observe('variant_var', Rec(V));
        Observer.Observe('integer_literal', Rec(1));
        Observer.Expect('record_var', 'record');
        Observer.Expect('variant_var', 'variant');
        Observer.Expect('integer_literal', 'variant');
        Observer.Verify();
    end;

    [Test]
    procedure Overload_DecimalIntegerBigInteger()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bt: Byte;
        Ch: Char;
        O: Option A,B;
    begin
        Observer.Observe('literal_1', Num(1));
        Observer.Observe('literal_1_0', Num(1.0));
        Observer.Observe('literal_1_5', Num(1.5));
        Observer.Observe('literal_big', Num(3000000000L));
        Observer.Observe('literal_neg_big', Num(-3000000000L));
        Observer.Observe('literal_int_max', Num(2147483647));
        Observer.Observe('literal_int_max_plus_1', Num(2147483648L));
        Observer.Observe('var_integer', Num(I));
        Observer.Observe('var_biginteger', Num(B));
        Observer.Observe('var_decimal', Num(D));
        Observer.Observe('var_option', Num(O));
        Observer.Observe('sum_int_int', Num(I + I));
        Observer.Observe('sum_int_big', Num(I + B));
        Observer.Observe('sum_int_dec', Num(I + D));
        Observer.Observe('div', Num(4 div 2));
        Observer.Observe('slash', Num(4 / 2));
        Observer.Observe('strlen', Num(StrLen('abc')));
        Observer.Observe('count_literal_mod', Num(7 mod 2));
        Observer.Expect('literal_1', 'integer');
        Observer.Expect('literal_1_0', 'decimal');
        Observer.Expect('literal_1_5', 'decimal');
        Observer.Expect('literal_big', 'biginteger');
        Observer.Expect('literal_neg_big', 'biginteger');
        Observer.Expect('literal_int_max', 'integer');
        Observer.Expect('literal_int_max_plus_1', 'biginteger');
        Observer.Expect('var_integer', 'integer');
        Observer.Expect('var_biginteger', 'biginteger');
        Observer.Expect('var_decimal', 'decimal');
        Observer.Expect('var_option', 'integer');
        Observer.Expect('sum_int_int', 'integer');
        Observer.Expect('sum_int_big', 'biginteger');
        Observer.Expect('sum_int_dec', 'decimal');
        Observer.Expect('div', 'integer');
        Observer.Expect('slash', 'decimal');
        Observer.Expect('strlen', 'integer');
        Observer.Expect('count_literal_mod', 'integer');
        Observer.Verify();
    end;

    [Test]
    procedure Overload_CodeBooleanPairs()
    var
        Observer: Codeunit "Probe Observer";
        C: Code[20];
        T: Text;
        V: Variant;
    begin
        C := 'x';
        T := 'x';
        V := true;
        Observer.Observe('code_var', Cd(C));
        Observer.Observe('text_var', Cd(T));
        Observer.Observe('boolean_literal', Bl(true));
        Observer.Observe('boolean_expr', Bl(1 = 1));
        Observer.Observe('variant_boolean', Bl(V));
        Observer.Observe('integer_literal', Bl(1));
        Observer.Expect('code_var', 'code');
        Observer.Expect('text_var', 'text');
        Observer.Expect('boolean_literal', 'boolean');
        Observer.Expect('boolean_expr', 'boolean');
        Observer.Expect('variant_boolean', 'variant');
        Observer.Expect('integer_literal', 'variant');
        Observer.Verify();
    end;

    local procedure BN3_Pick(A: Enum "LT BN3 EA"; B: Enum "LT BN3 EB"): Text
    begin
        exit('EA+EB:' + Format(A) + ',' + Format(B));
    end;

    local procedure BN3_Pick(A: Enum "LT BN3 EA"): Text
    begin
        exit('EA:' + Format(A));
    end;

    local procedure BN3_Pick(B: Enum "LT BN3 EB"): Text
    begin
        exit('EB:' + Format(B));
    end;

    // Corpus #664 item 74: overloads M(EA; EB), M(EA), M(EB) compile; which one runs for a value of each enum type.
    [Test]
    procedure BN3_Overload_DifferOnlyByEnumType()
    var
        Observer: Codeunit "Probe Observer";
        A: Enum "LT BN3 EA";
        B: Enum "LT BN3 EB";
    begin
        A := A::A1;
        B := B::B1;
        Observer.Observe('EA literal', BN3_Pick(Enum::"LT BN3 EA"::A1));
        Observer.Observe('EB literal', BN3_Pick(Enum::"LT BN3 EB"::B0));
        Observer.Observe('EA variable', BN3_Pick(A));
        Observer.Observe('EB variable', BN3_Pick(B));
        Observer.Observe('EA and EB', BN3_Pick(A, B));
        Observer.Expect('EA literal', 'EA:A1');
        Observer.Expect('EB literal', 'EB:B0');
        Observer.Expect('EA variable', 'EA:A1');
        Observer.Expect('EB variable', 'EB:B1');
        Observer.Expect('EA and EB', 'EA+EB:A1,B1');
        Observer.Verify();
    end;
}

// Corpus #664 item 74 (microsoft/AL issue 4328): two enum types for overloads that differ only by the enum type.
enum 83869 "LT BN3 EA"
{
    Extensible = false;
    value(0; A0) { }
    value(1; A1) { }
}

enum 83870 "LT BN3 EB"
{
    Extensible = false;
    value(0; B0) { }
    value(1; B1) { }
}
