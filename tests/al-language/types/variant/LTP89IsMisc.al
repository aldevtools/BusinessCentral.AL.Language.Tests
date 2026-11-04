// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Rec (74625), enum LT P89 Color (74626)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

codeunit 74630 "LT P89 Is Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsBinary() then
            R += 'Binary,';
        if V.IsWideChar() then
            R += 'WideChar,';
        if V.IsChar() then
            R += 'Char,';
        if V.IsText() then
            R += 'Text,';
        if V.IsCode() then
            R += 'Code,';
        if V.IsInteger() then
            R += 'Integer,';
        if V.IsBigInteger() then
            R += 'BigInteger,';
        if V.IsByte() then
            R += 'Byte,';
        if V.IsOption() then
            R += 'Option,';
        if V.IsDecimal() then
            R += 'Decimal,';
        if V.IsBoolean() then
            R += 'Boolean,';
        exit(R);
    end;

    [Test]
    procedure Binary_OnManyVariants()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Ins: InStream;
        Outs: OutStream;
        TB: TextBuilder;
        V: Variant;
        I: Integer;
        T: Text;
        Bl: Boolean;
        Bi: BigInteger;
        D: Decimal;
    begin
        V := I; Observer.Observe('integer', Format(V.IsBinary()));
        V := T; Observer.Observe('text', Format(V.IsBinary()));
        V := Bl; Observer.Observe('boolean', Format(V.IsBinary()));
        V := Bi; Observer.Observe('biginteger', Format(V.IsBinary()));
        V := D; Observer.Observe('decimal', Format(V.IsBinary()));
        V := Rec; Observer.Observe('record', Format(V.IsBinary()));
        V := Rec.Data; Observer.Observe('blobfield_value', Format(V.IsBinary()));
        Rec.Data.CreateInStream(Ins);
        V := Ins; Observer.Observe('instream', Format(V.IsBinary()));
        Rec.Data.CreateOutStream(Outs);
        V := Outs; Observer.Observe('outstream', Format(V.IsBinary()));
        V := TB; Observer.Observe('textbuilder', Format(V.IsBinary()));
        Clear(V); Observer.Observe('empty', Format(V.IsBinary()));
        Observer.Observe('empty_flags', Flags(V));
        Observer.Expect('integer', 'No');
        Observer.Expect('text', 'No');
        Observer.Expect('boolean', 'No');
        Observer.Expect('biginteger', 'No');
        Observer.Expect('decimal', 'No');
        Observer.Expect('record', 'No');
        Observer.Expect('blobfield_value', 'No');
        Observer.Expect('instream', 'No');
        Observer.Expect('outstream', 'No');
        Observer.Expect('textbuilder', 'No');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty_flags', '');
        Observer.Verify();
    end;

    [Test]
    procedure Binary_FromBlobFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        RecRef: RecordRef;
        FRef: FieldRef;
        V: Variant;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
        RecRef.GetTable(Rec);
        FRef := RecRef.Field(2);
        V := FRef.Value;
        Observer.Observe('fieldref_value_binary', Format(V.IsBinary()));
        Observer.Observe('fieldref_value_flags', Flags(V));
        V := FRef;
        Observer.Observe('fieldref_binary', Format(V.IsBinary()));
        Observer.Observe('fieldref_flags', Flags(V));
        Observer.Expect('fieldref_value_binary', 'No');
        Observer.Expect('fieldref_value_flags', '');
        Observer.Expect('fieldref_binary', 'No');
        Observer.Expect('fieldref_flags', '');
        Observer.Verify();
    end;

    [Test]
    procedure WideChar_Variants()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Ch: Char;
        By: Byte;
        I: Integer;
        T: Text;
        C: Code[10];
        Bi: BigInteger;
    begin
        V := Ch; Observer.Observe('char0', Flags(V));
        Ch := 65; V := Ch; Observer.Observe('char65', Flags(V));
        Ch := 256; V := Ch; Observer.Observe('char256', Flags(V));
        Ch := 65535; V := Ch; Observer.Observe('char65535', Flags(V));
        By := 65; V := By; Observer.Observe('byte65', Flags(V));
        I := 65; V := I; Observer.Observe('integer65', Flags(V));
        Bi := 65; V := Bi; Observer.Observe('biginteger65', Flags(V));
        T := 'A'; V := T; Observer.Observe('text_A', Flags(V));
        C := 'A'; V := C; Observer.Observe('code_A', Flags(V));
        V := 'A'; Observer.Observe('literal_A', Flags(V));
        V := 'AB'; Observer.Observe('literal_AB', Flags(V));
        Observer.Observe('wide_char65', Format(V.IsWideChar()));
        Observer.Expect('char0', 'WideChar,Char,');
        Observer.Expect('char65', 'WideChar,Char,');
        Observer.Expect('char256', 'WideChar,Char,');
        Observer.Expect('char65535', 'WideChar,Char,');
        Observer.Expect('byte65', 'Byte,');
        Observer.Expect('integer65', 'Integer,');
        Observer.Expect('biginteger65', 'BigInteger,');
        Observer.Expect('text_A', 'Text,');
        Observer.Expect('code_A', 'Code,');
        Observer.Expect('literal_A', 'WideChar,Char,');
        Observer.Expect('literal_AB', 'Text,');
        Observer.Expect('wide_char65', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure NearTypes_TextVsCode_IntegerVsBigInteger()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        T: Text;
        T10: Text[10];
        C10: Code[10];
        C20: Code[20];
        I: Integer;
        Bi: BigInteger;
        D: Decimal;
        O: Option A,B,C;
        E: Enum "LT P89 Color";
    begin
        T := 'abc'; V := T; Observer.Observe('text', Flags(V));
        T10 := 'abc'; V := T10; Observer.Observe('text10', Flags(V));
        C10 := 'abc'; V := C10; Observer.Observe('code10', Flags(V));
        C20 := 'abc'; V := C20; Observer.Observe('code20', Flags(V));
        V := Format(C10); Observer.Observe('format_code', Flags(V));
        V := CopyStr(T, 1, 2); Observer.Observe('copystr_text', Flags(V));
        V := CopyStr(C10, 1, 2); Observer.Observe('copystr_code', Flags(V));
        V := UpperCase(C10); Observer.Observe('uppercase_code', Flags(V));
        I := 5; V := I; Observer.Observe('integer', Flags(V));
        Bi := 5; V := Bi; Observer.Observe('biginteger', Flags(V));
        V := I + Bi; Observer.Observe('int_plus_bigint', Flags(V));
        V := I * 2; Observer.Observe('int_times_2', Flags(V));
        V := I / 2; Observer.Observe('int_div_2', Flags(V));
        V := I div 2; Observer.Observe('int_div_keyword', Flags(V));
        V := D + I; Observer.Observe('dec_plus_int', Flags(V));
        V := Round(1.5, 1); Observer.Observe('round_literal', Flags(V));
        V := Abs(I); Observer.Observe('abs_int', Flags(V));
        V := Abs(Bi); Observer.Observe('abs_bigint', Flags(V));
        O := O::B; V := O; Observer.Observe('option', Flags(V));
        E := E::Green; V := E; Observer.Observe('enum', Flags(V));
        V := O::B; Observer.Observe('option_literal', Flags(V));
        Observer.Expect('text', 'Text,');
        Observer.Expect('text10', 'Text,');
        Observer.Expect('code10', 'Code,');
        Observer.Expect('code20', 'Code,');
        Observer.Expect('format_code', 'Text,');
        Observer.Expect('copystr_text', 'Text,');
        Observer.Expect('copystr_code', 'Text,');
        Observer.Expect('uppercase_code', 'Text,');
        Observer.Expect('integer', 'Integer,');
        Observer.Expect('biginteger', 'BigInteger,');
        Observer.Expect('int_plus_bigint', 'BigInteger,');
        Observer.Expect('int_times_2', 'Integer,');
        Observer.Expect('int_div_2', 'Decimal,');
        Observer.Expect('int_div_keyword', 'Integer,');
        Observer.Expect('dec_plus_int', 'Decimal,');
        Observer.Expect('round_literal', 'Decimal,');
        Observer.Expect('abs_int', 'Integer,');
        Observer.Expect('abs_bigint', 'BigInteger,');
        Observer.Expect('option', 'Option,');
        Observer.Expect('enum', 'Option,');
        Observer.Expect('option_literal', 'Integer,');
        Observer.Verify();
    end;

}
