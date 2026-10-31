// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); enum 92907, table 92907, codeunit 92908 (log), test codeunit 92909
// Probe (al-runner issue 6591): TargetField.Validate(SourceField) where the value is itself a FieldRef (both fields of rows of the same table,
//   reached through two RecordRefs). Which value the target gets, whether its OnValidate runs (and with what), for the same type (Text, Code,
//   Integer, Decimal, Date, Enum, Option, Boolean), across types (Code/Text, Integer/Decimal, Text/Integer, Enum/Option/Integer, Date/Text) and
//   a value longer than the target (error text and code). Also FieldRef.Value := <FieldRef>, a Variant holding a FieldRef passed to Validate, and
//   FieldRef.SetRange(<FieldRef>). Record.Validate(Field, <FieldRef>) and Rec.Field := <FieldRef> do not compile: must-not-compile 2548, 2549.
//   Source row 'S': Txt 'Hello', Cod 'ABC', Int 42, Dec 12.5, Dat 2024-01-15, Enm Second, Opt B, Long (37 chars), Bool Yes,
//   LongCode 'CODE12345678901' (15 chars), NumTxt '17'. Target row 'T' starts from Init() (blank) and is read back with Get after Modify.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
