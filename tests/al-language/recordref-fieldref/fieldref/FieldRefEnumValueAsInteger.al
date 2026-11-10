// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-getenumvaluenamefromordinalvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 66390, enum extension 66391, table 66393, test codeunit 66394
// local object: the enum with gaps in its ordinals, its extension and the Enum field are what the tests measure.
// Probe (al-runner issue 7450: `FRef.GetEnumValueNameFromOrdinalValue(FRef.Value())` on an Enum field, a Variant that holds an Enum value
//   passed for an Integer parameter): observation form, the values are read from the corpus CI matrix.
// Area: a Variant that holds an Enum value where an Integer is expected. Sources of the Variant: FieldRef.Value() of an Enum field, an
//   Enum variable assigned to a Variant, a record field assigned to a Variant, and for contrast FieldRef.Value() of an Option field and
//   an Integer. Enum members: ordinal 0, 1, 5 (a gap), 20 (a name with a space and another caption) and a member of an enum extension.
//   Targets: the Integer parameter of FieldRef.GetEnumValueNameFromOrdinalValue and GetEnumValueCaptionFromOrdinalValue, the index
//   parameter of GetEnumValueName, GetEnumValueCaption and GetEnumValueOrdinal, the Integer, Decimal, BigInteger, Text and Option
//   parameters of own procedures (a Variant for an Enum parameter does not compile: AL0133), an assignment to an Integer variable, and Format and the Is* answers of the Variant. Each cell records
//   the result or the error text and code.
// Existing pins: TestFieldRefEnumOrdinalByIndex.al SO_OptionField_ValueAsOrdinalArgument_ReproShape (FieldRef.Value() of an Option field
//   as the ordinal argument and as an Integer argument).
// BC versions: 27, 28, 29 by CI

enum 66390 "RRF EnVar Kind"
{
    Extensible = true;
    value(0; None) { }
    value(1; First) { }
    value(5; Fifth) { }
    value(20; "Twenty Name") { Caption = 'Twenty Cap'; }
}

enumextension 66391 "RRF EnVar Kind Ext" extends "RRF EnVar Kind"
{
    value(66392; "Ext Value") { Caption = 'Ext Cap'; }
}

table 66393 "RRF EnVar Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "RRF EnVar Kind") { }
        field(3; Opt; Option) { OptionMembers = Zero,One,Two; }
        field(4; Num; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 66394 "RRF EnVar Tests"
{
    Subtype = Test;

    local procedure Initialize()
    var
        R: Record "RRF EnVar Row";
    begin
        R.DeleteAll();
    end;

    local procedure TakesInteger(Value: Integer): Text
    begin
        exit(Format(Value));
    end;

    local procedure TakesBigInteger(Value: BigInteger): Text
    begin
        exit(Format(Value));
    end;

    local procedure TakesDecimal(Value: Decimal): Text
    begin
        exit(Format(Value, 0, 9));
    end;

    local procedure TakesText(Value: Text): Text
    begin
        exit(Value);
    end;

    local procedure TakesOption(Value: Option Zero,One,Two): Text
    begin
        exit(Format(Value) + '/' + Format(Value, 0, 9));
    end;

    [TryFunction]
    local procedure TryCall(Target: Text; var Fld: FieldRef; V: Variant; var Result: Text)
    var
        I: Integer;
    begin
        case Target of
            'name from ordinal':
                Result := Fld.GetEnumValueNameFromOrdinalValue(V);
            'caption from ordinal':
                Result := Fld.GetEnumValueCaptionFromOrdinalValue(V);
            'name by index':
                Result := Fld.GetEnumValueName(V);
            'caption by index':
                Result := Fld.GetEnumValueCaption(V);
            'ordinal by index':
                Result := Format(Fld.GetEnumValueOrdinal(V));
            'integer parameter':
                Result := TakesInteger(V);
            'biginteger parameter':
                Result := TakesBigInteger(V);
            'decimal parameter':
                Result := TakesDecimal(V);
            'text parameter':
                Result := TakesText(V);
            'option parameter':
                Result := TakesOption(V);
            'integer variable':
                begin
                    I := V;
                    Result := Format(I);
                end;
            'format':
                Result := Format(V) + '|' + Format(V, 0, 2) + '|' + Format(V, 0, 9);
            'kind':
                Result := StrSubstNo('IsInteger=%1 IsOption=%2 IsText=%3 IsCode=%4 IsDecimal=%5', V.IsInteger(), V.IsOption(), V.IsText(), V.IsCode(), V.IsDecimal());
            else
                Error('unknown target %1', Target);
        end;
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; Name: Text; Target: Text; var Fld: FieldRef; V: Variant)
    var
        Result: Text;
    begin
        if TryCall(Target, Fld, V, Result) then
            Observer.Observe(Name + ' ' + Target, Result)
        else begin
            Observer.Observe(Name + ' ' + Target, 'E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
            ClearLastError();
        end;
    end;

    local procedure FieldRefMethods(var Observer: Codeunit "Probe Observer"; Name: Text; var Fld: FieldRef; V: Variant)
    begin
        Cell(Observer, Name, 'name from ordinal', Fld, V);
        Cell(Observer, Name, 'caption from ordinal', Fld, V);
        Cell(Observer, Name, 'name by index', Fld, V);
        Cell(Observer, Name, 'caption by index', Fld, V);
        Cell(Observer, Name, 'ordinal by index', Fld, V);
    end;

    local procedure OwnParameters(var Observer: Codeunit "Probe Observer"; Name: Text; var Fld: FieldRef; V: Variant)
    begin
        Cell(Observer, Name, 'integer parameter', Fld, V);
        Cell(Observer, Name, 'biginteger parameter', Fld, V);
        Cell(Observer, Name, 'decimal parameter', Fld, V);
        Cell(Observer, Name, 'text parameter', Fld, V);
        Cell(Observer, Name, 'option parameter', Fld, V);
        Cell(Observer, Name, 'integer variable', Fld, V);
        Cell(Observer, Name, 'format', Fld, V);
        Cell(Observer, Name, 'kind', Fld, V);
    end;

    local procedure OpenKind(var Ref: RecordRef; var Fld: FieldRef; Kind: Enum "RRF EnVar Kind")
    var
        R: Record "RRF EnVar Row";
    begin
        R.Init();
        R.Kind := Kind;
        Ref.GetTable(R);
        Fld := Ref.Field(R.FieldNo(Kind));
    end;

    [Test]
    procedure EnumFieldRefValue_AsOrdinalArgument_ReportedShape()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "RRF EnVar Row";
        Ref: RecordRef;
        Fld: FieldRef;
        Result: Text;
    begin
        Initialize();
        R.Kind := R.Kind::First;
        Ref.GetTable(R);
        Fld := Ref.Field(R.FieldNo(Kind));
        if TryReported(Fld, Result) then
            Observer.Observe('GetEnumValueNameFromOrdinalValue(FRef.Value())', Result)
        else
            Observer.ObserveError('GetEnumValueNameFromOrdinalValue(FRef.Value())');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryReported(var Fld: FieldRef; var Result: Text)
    begin
        Result := Fld.GetEnumValueNameFromOrdinalValue(Fld.Value());
    end;

    [Test]
    procedure EnumFieldRefValue_FieldRefEnumMethods_EveryMember()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
        Fld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
    begin
        Initialize();
        OpenKind(Ref, Fld, Kind::None);
        FieldRefMethods(Observer, 'None', Fld, Fld.Value());
        OpenKind(Ref, Fld, Kind::First);
        FieldRefMethods(Observer, 'First', Fld, Fld.Value());
        OpenKind(Ref, Fld, Kind::Fifth);
        FieldRefMethods(Observer, 'Fifth', Fld, Fld.Value());
        Observer.Finish();
    end;

    [Test]
    procedure EnumFieldRefValue_FieldRefEnumMethods_CaptionedAndExtensionMember()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
        Fld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
    begin
        Initialize();
        OpenKind(Ref, Fld, Kind::"Twenty Name");
        FieldRefMethods(Observer, 'Twenty', Fld, Fld.Value());
        OpenKind(Ref, Fld, Kind::"Ext Value");
        FieldRefMethods(Observer, 'Ext', Fld, Fld.Value());
        Observer.Finish();
    end;

    [Test]
    procedure EnumFieldRefValue_OwnParameters_FirstMember()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
        Fld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
    begin
        Initialize();
        OpenKind(Ref, Fld, Kind::First);
        OwnParameters(Observer, 'First', Fld, Fld.Value());
        Observer.Finish();
    end;

    [Test]
    procedure EnumFieldRefValue_OwnParameters_GapMember()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
        Fld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
    begin
        Initialize();
        OpenKind(Ref, Fld, Kind::Fifth);
        OwnParameters(Observer, 'Fifth', Fld, Fld.Value());
        Observer.Finish();
    end;

    [Test]
    procedure EnumFieldRefValue_OwnParameters_ExtensionMember()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
        Fld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
    begin
        Initialize();
        OpenKind(Ref, Fld, Kind::"Ext Value");
        OwnParameters(Observer, 'Ext', Fld, Fld.Value());
        Observer.Finish();
    end;

    [Test]
    procedure EnumVariableInVariant_FieldRefEnumMethods()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
        Fld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
        V: Variant;
    begin
        Initialize();
        OpenKind(Ref, Fld, Kind::None);
        Kind := Kind::Fifth;
        V := Kind;
        FieldRefMethods(Observer, 'variable Fifth', Fld, V);
        Observer.Finish();
    end;

    [Test]
    procedure EnumVariableInVariant_OwnParameters()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
        Fld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
        V: Variant;
    begin
        Initialize();
        OpenKind(Ref, Fld, Kind::None);
        Kind := Kind::Fifth;
        V := Kind;
        OwnParameters(Observer, 'variable Fifth', Fld, V);
        Observer.Finish();
    end;

    [Test]
    procedure EnumRecordFieldInVariant_FieldRefEnumMethods()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "RRF EnVar Row";
        Ref: RecordRef;
        Fld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
        V: Variant;
    begin
        Initialize();
        OpenKind(Ref, Fld, Kind::None);
        R.Kind := R.Kind::"Twenty Name";
        V := R.Kind;
        FieldRefMethods(Observer, 'field Twenty', Fld, V);
        Observer.Finish();
    end;

    [Test]
    procedure EnumRecordFieldInVariant_OwnParameters()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "RRF EnVar Row";
        Ref: RecordRef;
        Fld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
        V: Variant;
    begin
        Initialize();
        OpenKind(Ref, Fld, Kind::None);
        R.Kind := R.Kind::"Twenty Name";
        V := R.Kind;
        OwnParameters(Observer, 'field Twenty', Fld, V);
        Observer.Finish();
    end;

    [Test]
    procedure OptionValueInVariant_OnTheEnumField_Contrast()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "RRF EnVar Row";
        Ref: RecordRef;
        Fld: FieldRef;
        OptFld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
        V: Variant;
    begin
        Initialize();
        OpenKind(Ref, Fld, Kind::None);
        R.Opt := R.Opt::One;
        V := R.Opt;
        FieldRefMethods(Observer, 'option One', Fld, V);
        OptFld := Ref.Field(R.FieldNo(Opt));
        OptFld.Value := 1;
        Cell(Observer, 'option FieldRef.Value', 'name from ordinal', Fld, OptFld.Value());
        Cell(Observer, 'option FieldRef.Value', 'integer parameter', Fld, OptFld.Value());
        Observer.Finish();
    end;

    [Test]
    procedure IntegerInVariant_OnTheEnumField_Contrast()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
        Fld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
        V: Variant;
    begin
        Initialize();
        OpenKind(Ref, Fld, Kind::None);
        V := 5;
        FieldRefMethods(Observer, 'integer 5', Fld, V);
        V := 7;
        Cell(Observer, 'integer 7 (no member)', 'name from ordinal', Fld, V);
        Cell(Observer, 'integer 7 (no member)', 'caption from ordinal', Fld, V);
        Observer.Finish();
    end;

    [Test]
    procedure EnumFieldRefValue_OnTheOptionField_Contrast()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "RRF EnVar Row";
        Ref: RecordRef;
        KindFld: FieldRef;
        OptFld: FieldRef;
        Kind: Enum "RRF EnVar Kind";
    begin
        Initialize();
        OpenKind(Ref, KindFld, Kind::First);
        OptFld := Ref.Field(R.FieldNo(Opt));
        FieldRefMethods(Observer, 'enum First on the option field', OptFld, KindFld.Value());
        Cell(Observer, 'enum First', 'option parameter', OptFld, KindFld.Value());
        Observer.Finish();
    end;
}
