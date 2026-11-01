// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); enum 92907, table 92907, codeunit 92908 (log), test codeunit 92909
// Probe (al-runner issue 6591): TargetField.Validate(SourceField) where the value is itself a FieldRef (both fields of rows of the same table,
//   reached through two RecordRefs). Which value the target gets, whether its OnValidate runs (and with what), for the same type (Text, Code,
//   Integer, Decimal, Date, Enum, Option, Boolean), across types (Code/Text, Integer/Decimal, Text/Integer, Enum/Option/Integer, Date/Text) and
//   a value longer than the target (error text and code). Also FieldRef.Value := <FieldRef>, a Variant holding a FieldRef passed to Validate, and
//   FieldRef.SetRange(<FieldRef>). Record.Validate(Field, <FieldRef>) and Rec.Field := <FieldRef> do not compile: must-not-compile 2548, 2549.
//   Source row 'S': Txt 'Hello', Cod 'ABC', Int 42, Dec 12.5, Dat 2024-01-15, Enm Second, Opt B, Long (37 chars), Bool Yes,
//   LongCode 'CODE12345678901' (15 chars), NumTxt '17'. BC 27.5 gives another error for Text 'Hello' into an Integer (NotSupportedType).
//   The Date to Text case gives the en-US format of the test servers. Target row 'T' starts from Init() (blank) and is read back with Get after Modify.
// BC versions: 27, 28, 29

enum 92907 "LT Y47 VF Kind"
{
    Extensible = true;

    value(0; First) { }
    value(1; Second) { }
    value(42; Answer) { }
}

table 92907 "LT Y47 VF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Txt; Text[20])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT Y47 VF Log";
            begin
                Log.Add('vTxt=' + Txt + ' x=' + xRec.Txt);
            end;
        }
        field(3; Cod; Code[10])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT Y47 VF Log";
            begin
                Log.Add('vCod=' + Cod);
            end;
        }
        field(4; Int; Integer)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT Y47 VF Log";
            begin
                Log.Add('vInt=' + Format(Int));
            end;
        }
        field(5; Dec; Decimal)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT Y47 VF Log";
            begin
                Log.Add('vDec=' + Format(Dec, 0, 9));
            end;
        }
        field(6; Dat; Date)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT Y47 VF Log";
            begin
                Log.Add('vDat=' + Format(Dat, 0, 9));
            end;
        }
        field(7; Enm; Enum "LT Y47 VF Kind")
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT Y47 VF Log";
            begin
                Log.Add('vEnm=' + Format(Enm.AsInteger()));
            end;
        }
        field(8; Opt; Option)
        {
            OptionMembers = A,B,C;

            trigger OnValidate()
            var
                Log: Codeunit "LT Y47 VF Log";
            begin
                Log.Add('vOpt=' + Format(Opt, 0, 9));
            end;
        }
        field(9; Long; Text[50]) { }
        field(10; Bool; Boolean)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT Y47 VF Log";
            begin
                Log.Add('vBool=' + Format(Bool));
            end;
        }
        field(11; LongCode; Code[20]) { }
        field(12; NumTxt; Text[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 92908 "LT Y47 VF Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;
}

codeunit 92909 "LT Y47 Validate FieldRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y47 VF Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'S';
        Row.Txt := 'Hello';
        Row.Cod := 'ABC';
        Row.Int := 42;
        Row.Dec := 12.5;
        Row.Dat := 20240115D;
        Row.Enm := Row.Enm::Second;
        Row.Opt := Row.Opt::B;
        Row.Long := 'This text is longer than twenty chars';
        Row.Bool := true;
        Row.LongCode := 'CODE12345678901';
        Row.NumTxt := '17';
        Row.Insert();
        Row.Init();
        Row."No." := 'T';
        Row.Insert();
    end;

    local procedure Show(FieldNo: Integer): Text
    var
        Row: Record "LT Y47 VF Row";
        Ref: RecordRef;
    begin
        Row.Get('T');
        Ref.GetTable(Row);
        exit(Format(Ref.Field(FieldNo).Value, 0, 9));
    end;

    // The TryFunctions only validate or assign (no database write inside a TryFunction); the caller modifies when they succeed.
    [TryFunction]
    local procedure TryValidate(var TargetField: FieldRef; SourceField: FieldRef)
    begin
        TargetField.Validate(SourceField);
    end;

    [TryFunction]
    local procedure TryValue(var TargetField: FieldRef; SourceField: FieldRef)
    begin
        TargetField.Value := SourceField;
    end;

    local procedure Copy(SourceNo: Integer; TargetNo: Integer; UseValidate: Boolean): Text
    var
        Log: Codeunit "LT Y47 VF Log";
        Source: Record "LT Y47 VF Row";
        Target: Record "LT Y47 VF Row";
        SourceRef: RecordRef;
        TargetRef: RecordRef;
        SourceField: FieldRef;
        TargetField: FieldRef;
        Ok: Boolean;
    begin
        Seed();
        Log.Take();
        Source.Get('S');
        Target.Get('T');
        SourceRef.GetTable(Source);
        TargetRef.GetTable(Target);
        SourceField := SourceRef.Field(SourceNo);
        TargetField := TargetRef.Field(TargetNo);
        ClearLastError();
        if UseValidate then
            Ok := TryValidate(TargetField, SourceField)
        else
            Ok := TryValue(TargetField, SourceField);
        if Ok then begin
            TargetRef.Modify();
            exit('ok [' + Show(TargetNo) + '] ' + Log.Take());
        end;
        exit('error ' + GetLastErrorText() + '|' + GetLastErrorCode() + ' [' + Show(TargetNo) + '] ' + Log.Take());
    end;

    local procedure CopyValidate(SourceNo: Integer; TargetNo: Integer): Text
    begin
        exit(Copy(SourceNo, TargetNo, true));
    end;

    local procedure CopyValue(SourceNo: Integer; TargetNo: Integer): Text
    begin
        exit(Copy(SourceNo, TargetNo, false));
    end;

    [Test]
    procedure Y47_ValidateFieldRef_ReporterShape()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT Y47 VF Row";
        Target: Record "LT Y47 VF Row";
        SourceRef: RecordRef;
        TargetRef: RecordRef;
        SourceField: FieldRef;
        TargetField: FieldRef;
    begin
        Seed();
        Source.Get('S');
        Target.Get('T');
        SourceRef.GetTable(Source);
        TargetRef.GetTable(Target);
        SourceField := SourceRef.Field(2);
        TargetField := TargetRef.Field(2);
        TargetField.Validate(SourceField);
        Observer.Observe('beforeModify', Format(TargetField.Value));
        TargetRef.Modify();
        Target.Get('T');
        Observer.Observe('stored', Target.Txt);
        SourceField := SourceRef.Field(5);
        TargetField := TargetRef.Field(5);
        TargetField.Validate(SourceField);
        TargetRef.Modify();
        Target.Get('T');
        Observer.Observe('storedDec', Format(Target.Dec, 0, 9));
        Observer.Expect('beforeModify', 'Hello');
        Observer.Expect('stored', 'Hello');
        Observer.Expect('storedDec', '12.5');
        Observer.Verify();
    end;

    [Test]
    procedure Y47_ValidateFieldRef_Matrix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('same_text', CopyValidate(2, 2));
        Observer.Observe('same_code', CopyValidate(3, 3));
        Observer.Observe('same_int', CopyValidate(4, 4));
        Observer.Observe('same_dec', CopyValidate(5, 5));
        Observer.Observe('same_date', CopyValidate(6, 6));
        Observer.Observe('same_enum', CopyValidate(7, 7));
        Observer.Observe('same_option', CopyValidate(8, 8));
        Observer.Observe('same_bool', CopyValidate(10, 10));
        Observer.Observe('code_to_text', CopyValidate(3, 2));
        Observer.Observe('text_to_code', CopyValidate(2, 3));
        Observer.Observe('int_to_dec', CopyValidate(4, 5));
        Observer.Observe('dec_to_int', CopyValidate(5, 4));
        Observer.Observe('int_to_text', CopyValidate(4, 2));
        Observer.Observe('text_to_int', CopyValidate(2, 4));
        Observer.Observe('numtext_to_int', CopyValidate(12, 4));
        Observer.Observe('enum_to_int', CopyValidate(7, 4));
        Observer.Observe('option_to_enum', CopyValidate(8, 7));
        Observer.Observe('enum_to_option', CopyValidate(7, 8));
        Observer.Observe('int_to_enum', CopyValidate(4, 7));
        Observer.Observe('date_to_text', CopyValidate(6, 2));
        Observer.Observe('bool_to_int', CopyValidate(10, 4));
        Observer.Observe('dec_to_text', CopyValidate(5, 2));
        Observer.Observe('long_to_text20', CopyValidate(9, 2));
        Observer.Observe('longcode_to_code10', CopyValidate(11, 3));
        Observer.Observe('long_to_code10', CopyValidate(9, 3));
        Observer.Expect('same_text', 'ok [Hello] vTxt=Hello x=;');
        Observer.Expect('same_code', 'ok [ABC] vCod=ABC;');
        Observer.Expect('same_int', 'ok [42] vInt=42;');
        Observer.Expect('same_dec', 'ok [12.5] vDec=12.5;');
        Observer.Expect('same_date', 'ok [2024-01-15] vDat=2024-01-15;');
        Observer.Expect('same_enum', 'ok [1] vEnm=1;');
        Observer.Expect('same_option', 'ok [1] vOpt=1;');
        Observer.Expect('same_bool', 'ok [true] vBool=Yes;');
        Observer.Expect('code_to_text', 'ok [ABC] vTxt=ABC x=;');
        Observer.Expect('text_to_code', 'ok [HELLO] vCod=HELLO;');
        Observer.Expect('int_to_dec', 'ok [42] vDec=42;');
        Observer.Expect('dec_to_int', 'error Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 12.5 to System.Int32.|ConversionCast [0] ');
        Observer.Expect('int_to_text', 'ok [42] vTxt=42 x=;');
#if BC28PLUS
        Observer.Expect('text_to_int', 'error The value "Hello" can''t be evaluated into type Integer.|Evaluate:Format [0] ');
#else
        Observer.Expect('text_to_int', 'error The type NavInteger is unknown.|NotSupportedType [0] ');
#endif
        Observer.Expect('numtext_to_int', 'ok [17] vInt=17;');
        Observer.Expect('enum_to_int', 'ok [1] vInt=1;');
        Observer.Expect('option_to_enum', 'ok [1] vEnm=1;');
        Observer.Expect('enum_to_option', 'ok [1] vOpt=1;');
        Observer.Expect('int_to_enum', 'ok [42] vEnm=42;');
        Observer.Expect('date_to_text', 'ok [01/15/24] vTxt=01/15/24 x=;');
        Observer.Expect('bool_to_int', 'ok [1] vInt=1;');
        Observer.Expect('dec_to_text', 'ok [12.5] vTxt=12.5 x=;');
        Observer.Expect('long_to_text20', 'error The length of the string is 37, but it must be less than or equal to 20 characters. Value: This text is longer than twenty chars|StringLengthExceeded [] ');
        Observer.Expect('longcode_to_code10', 'error The length of the string is 15, but it must be less than or equal to 10 characters. Value: CODE12345678901|StringLengthExceeded [] ');
        Observer.Expect('long_to_code10', 'error The length of the string is 37, but it must be less than or equal to 10 characters. Value: This text is longer than twenty chars|StringLengthExceeded [] ');
        Observer.Verify();
    end;

    [Test]
    procedure Y47_ValueFieldRef()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('val_same_text', CopyValue(2, 2));
        Observer.Observe('val_long_to_text20', CopyValue(9, 2));
        Observer.Observe('val_int_to_dec', CopyValue(4, 5));
        Observer.Observe('val_text_to_int', CopyValue(2, 4));
        Observer.Expect('val_same_text', 'ok [Hello] ');
        Observer.Expect('val_long_to_text20', 'error The length of the string is 37, but it must be less than or equal to 20 characters. Value: This text is longer than twenty chars|StringLengthExceeded [] ');
        Observer.Expect('val_int_to_dec', 'ok [42] ');
#if BC28PLUS
        Observer.Expect('val_text_to_int', 'error The value "Hello" can''t be evaluated into type Integer.|Evaluate:Format [0] ');
#else
        Observer.Expect('val_text_to_int', 'error The type NavInteger is unknown.|NotSupportedType [0] ');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Y47_ValidateVariantHoldingFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y47 VF Log";
        Source: Record "LT Y47 VF Row";
        Target: Record "LT Y47 VF Row";
        SourceRef: RecordRef;
        TargetRef: RecordRef;
        TargetField: FieldRef;
        V: Variant;
    begin
        Seed();
        Log.Take();
        Source.Get('S');
        Target.Get('T');
        SourceRef.GetTable(Source);
        TargetRef.GetTable(Target);
        V := SourceRef.Field(2);
        Observer.Observe('isFieldRef', Format(V.IsFieldRef()));
        TargetField := TargetRef.Field(2);
        ClearLastError();
        if TryValidateVariant(TargetField, V) then
            Observer.Observe('validate', 'ok [' + Format(TargetField.Value) + '] ' + Log.Take())
        else
            Observer.Observe('validate', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('isFieldRef', 'Yes');
        Observer.Expect('validate', 'ok [Hello] vTxt=Hello x=;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryValidateVariant(var TargetField: FieldRef; V: Variant)
    begin
        TargetField.Validate(V);
    end;

    [Test]
    procedure Y47_SetRangeFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT Y47 VF Row";
        SourceRef: RecordRef;
        TargetRef: RecordRef;
        TargetField: FieldRef;
    begin
        Seed();
        Source.Get('S');
        SourceRef.GetTable(Source);
        TargetRef.Open(Database::"LT Y47 VF Row");
        TargetField := TargetRef.Field(2);
        TargetField.SetRange(SourceRef.Field(2));
        Observer.Observe('filter', TargetField.GetFilter());
        Observer.Observe('count', Format(TargetRef.Count()));
        TargetField := TargetRef.Field(4);
        TargetField.SetFilter('>%1', SourceRef.Field(4));
        Observer.Observe('filterInt', TargetField.GetFilter());
        Observer.Expect('filter', 'Hello');
        Observer.Expect('count', '1');
        Observer.Expect('filterInt', '>42');
        Observer.Verify();
    end;

    // Writer Y57: the Quality Management QltyTraversal shape. The Variant holds the VALUE of a field (FromVariantValue := FromFieldRef.Value),
    // or a literal, and goes into a Text or Code field with FieldRef.Validate(Variant) or FieldRef.Value := Variant.
    [TryFunction]
    local procedure TryValueVariant(var TargetField: FieldRef; V: Variant)
    begin
        TargetField.Value := V;
    end;

    local procedure PutVariant(V: Variant; TargetNo: Integer; UseValidate: Boolean): Text
    var
        Log: Codeunit "LT Y47 VF Log";
        Target: Record "LT Y47 VF Row";
        TargetRef: RecordRef;
        TargetField: FieldRef;
        Ok: Boolean;
    begin
        Log.Take();
        Target.Get('T');
        TargetRef.GetTable(Target);
        TargetField := TargetRef.Field(TargetNo);
        ClearLastError();
        if UseValidate then
            Ok := TryValidateVariant(TargetField, V)
        else
            Ok := TryValueVariant(TargetField, V);
        if Ok then begin
            TargetRef.Modify();
            exit('ok [' + Show(TargetNo) + '] ' + Log.Take());
        end;
        exit('error ' + GetLastErrorText() + '|' + GetLastErrorCode() + ' [' + Show(TargetNo) + '] ' + Log.Take());
    end;

    local procedure FieldVariant(SourceNo: Integer; TargetNo: Integer; UseValidate: Boolean): Text
    var
        Source: Record "LT Y47 VF Row";
        SourceRef: RecordRef;
        V: Variant;
    begin
        Seed();
        Source.Get('S');
        SourceRef.GetTable(Source);
        V := SourceRef.Field(SourceNo).Value;
        exit(PutVariant(V, TargetNo, UseValidate));
    end;

    [Test]
    procedure Y57_ValidateVariantValue_IntoText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('int_txt', FieldVariant(4, 2, true));
        Observer.Observe('dec_txt', FieldVariant(5, 2, true));
        Observer.Observe('dat_txt', FieldVariant(6, 2, true));
        Observer.Observe('bool_txt', FieldVariant(10, 2, true));
        Observer.Observe('opt_txt', FieldVariant(8, 2, true));
        Observer.Observe('enm_txt', FieldVariant(7, 2, true));
        Observer.Observe('cod_txt', FieldVariant(3, 2, true));
        Observer.Observe('int_cod', FieldVariant(4, 3, true));
        Observer.Observe('dec_cod', FieldVariant(5, 3, true));
        Observer.Observe('dat_cod', FieldVariant(6, 3, true));
        Observer.Observe('bool_cod', FieldVariant(10, 3, true));
        Observer.Observe('txt_cod', FieldVariant(2, 3, true));
        Observer.Observe('int_numtxt', FieldVariant(4, 12, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y57_ValueVariantValue_IntoText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('int_txt', FieldVariant(4, 2, false));
        Observer.Observe('dec_txt', FieldVariant(5, 2, false));
        Observer.Observe('dat_txt', FieldVariant(6, 2, false));
        Observer.Observe('bool_txt', FieldVariant(10, 2, false));
        Observer.Observe('opt_txt', FieldVariant(8, 2, false));
        Observer.Observe('int_cod', FieldVariant(4, 3, false));
        Observer.Observe('dec_cod', FieldVariant(5, 3, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y57_ValidateVariantLiteral_IntoText()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        I: Integer;
        D: Decimal;
        Big: BigInteger;
        Dt: Date;
        B: Boolean;
    begin
        Seed();
        I := 5;
        V := I;
        Observer.Observe('int5_txt', PutVariant(V, 2, true));
        Observer.Observe('int5_cod', PutVariant(V, 3, true));
        I := -12;
        V := I;
        Observer.Observe('intminus12_txt', PutVariant(V, 2, true));
        D := 2.5;
        V := D;
        Observer.Observe('dec2_5_txt', PutVariant(V, 2, true));
        D := 1234.5;
        V := D;
        Observer.Observe('dec1234_5_txt', PutVariant(V, 2, true));
        Big := 3000000000L;
        V := Big;
        Observer.Observe('big3e9_txt', PutVariant(V, 2, true));
        Big := 12345678901L;
        V := Big;
        Observer.Observe('big11digits_numtxt', PutVariant(V, 12, true));
        Observer.Observe('big11digits_cod', PutVariant(V, 3, true));
        Dt := 20240115D;
        V := Dt;
        Observer.Observe('date_txt', PutVariant(V, 2, true));
        B := false;
        V := B;
        Observer.Observe('false_txt', PutVariant(V, 2, true));
        I := 7;
        V := I;
        Observer.Observe('int7_value_txt', PutVariant(V, 2, false));
        Observer.Finish();
    end;
}
