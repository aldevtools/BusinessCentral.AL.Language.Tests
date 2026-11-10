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
        Observer.Expect('GetEnumValueNameFromOrdinalValue(FRef.Value())', 'First');
        Observer.Verify();
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
        Observer.Expect('None name from ordinal', 'None');
        Observer.Expect('None caption from ordinal', 'None');
        Observer.Expect('None name by index', '');
        Observer.Expect('None caption by index', '');
        Observer.Expect('None ordinal by index', '-1');
        Observer.Expect('First name from ordinal', 'First');
        Observer.Expect('First caption from ordinal', 'First');
        Observer.Expect('First name by index', 'None');
        Observer.Expect('First caption by index', 'None');
        Observer.Expect('First ordinal by index', '0');
        Observer.Expect('Fifth name from ordinal', 'Fifth');
        Observer.Expect('Fifth caption from ordinal', 'Fifth');
        Observer.Expect('Fifth name by index', 'Ext Value');
        Observer.Expect('Fifth caption by index', 'Ext Cap');
        Observer.Expect('Fifth ordinal by index', '66392');
        Observer.Verify();
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
        Observer.Expect('Twenty name from ordinal', 'Twenty Name');
        Observer.Expect('Twenty caption from ordinal', 'Twenty Cap');
        Observer.Expect('Twenty name by index', '');
        Observer.Expect('Twenty caption by index', '');
        Observer.Expect('Twenty ordinal by index', '-1');
        Observer.Expect('Ext name from ordinal', 'Ext Value');
        Observer.Expect('Ext caption from ordinal', 'Ext Cap');
        Observer.Expect('Ext name by index', '');
        Observer.Expect('Ext caption by index', '');
        Observer.Expect('Ext ordinal by index', '-1');
        Observer.Verify();
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
        Observer.Expect('First integer parameter', '1');
        Observer.Expect('First biginteger parameter', '1');
        Observer.Expect('First decimal parameter', '1');
        Observer.Expect('First text parameter', 'E: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value. [TypeConversion]');
        Observer.Expect('First option parameter', 'One/1');
        Observer.Expect('First integer variable', '1');
        Observer.Expect('First format', 'First|1|1');
        Observer.Expect('First kind', 'IsInteger=No IsOption=Yes IsText=No IsCode=No IsDecimal=No');
        Observer.Verify();
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
        Observer.Expect('Fifth integer parameter', '5');
        Observer.Expect('Fifth biginteger parameter', '5');
        Observer.Expect('Fifth decimal parameter', '5');
        Observer.Expect('Fifth text parameter', 'E: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value. [TypeConversion]');
        Observer.Expect('Fifth option parameter', '5/5');
        Observer.Expect('Fifth integer variable', '5');
        Observer.Expect('Fifth format', 'Fifth|5|5');
        Observer.Expect('Fifth kind', 'IsInteger=No IsOption=Yes IsText=No IsCode=No IsDecimal=No');
        Observer.Verify();
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
        Observer.Expect('Ext integer parameter', '66392');
        Observer.Expect('Ext biginteger parameter', '66392');
        Observer.Expect('Ext decimal parameter', '66392');
        Observer.Expect('Ext text parameter', 'E: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value. [TypeConversion]');
        Observer.Expect('Ext option parameter', '66392/66392');
        Observer.Expect('Ext integer variable', '66392');
        Observer.Expect('Ext format', 'Ext Cap|66392|66392');
        Observer.Expect('Ext kind', 'IsInteger=No IsOption=Yes IsText=No IsCode=No IsDecimal=No');
        Observer.Verify();
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
        Observer.Expect('variable Fifth name from ordinal', 'Fifth');
        Observer.Expect('variable Fifth caption from ordinal', 'Fifth');
        Observer.Expect('variable Fifth name by index', 'Ext Value');
        Observer.Expect('variable Fifth caption by index', 'Ext Cap');
        Observer.Expect('variable Fifth ordinal by index', '66392');
        Observer.Verify();
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
        Observer.Expect('variable Fifth integer parameter', '5');
        Observer.Expect('variable Fifth biginteger parameter', '5');
        Observer.Expect('variable Fifth decimal parameter', '5');
        Observer.Expect('variable Fifth text parameter', 'E: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value. [TypeConversion]');
        Observer.Expect('variable Fifth option parameter', '5/5');
        Observer.Expect('variable Fifth integer variable', '5');
        Observer.Expect('variable Fifth format', 'Fifth|5|5');
        Observer.Expect('variable Fifth kind', 'IsInteger=No IsOption=Yes IsText=No IsCode=No IsDecimal=No');
        Observer.Verify();
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
        Observer.Expect('field Twenty name from ordinal', 'Twenty Name');
        Observer.Expect('field Twenty caption from ordinal', 'Twenty Cap');
        Observer.Expect('field Twenty name by index', '');
        Observer.Expect('field Twenty caption by index', '');
        Observer.Expect('field Twenty ordinal by index', '-1');
        Observer.Verify();
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
        Observer.Expect('field Twenty integer parameter', '20');
        Observer.Expect('field Twenty biginteger parameter', '20');
        Observer.Expect('field Twenty decimal parameter', '20');
        Observer.Expect('field Twenty text parameter', 'E: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value. [TypeConversion]');
        Observer.Expect('field Twenty option parameter', '20/20');
        Observer.Expect('field Twenty integer variable', '20');
        Observer.Expect('field Twenty format', 'Twenty Cap|20|20');
        Observer.Expect('field Twenty kind', 'IsInteger=No IsOption=Yes IsText=No IsCode=No IsDecimal=No');
        Observer.Verify();
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
        Observer.Expect('option One name from ordinal', 'First');
        Observer.Expect('option One caption from ordinal', 'First');
        Observer.Expect('option One name by index', 'None');
        Observer.Expect('option One caption by index', 'None');
        Observer.Expect('option One ordinal by index', '0');
        Observer.Expect('option FieldRef.Value name from ordinal', 'First');
        Observer.Expect('option FieldRef.Value integer parameter', '1');
        Observer.Verify();
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
        Observer.Expect('integer 5 name from ordinal', 'Fifth');
        Observer.Expect('integer 5 caption from ordinal', 'Fifth');
        Observer.Expect('integer 5 name by index', 'Ext Value');
        Observer.Expect('integer 5 caption by index', 'Ext Cap');
        Observer.Expect('integer 5 ordinal by index', '66392');
        Observer.Expect('integer 7 (no member) name from ordinal', '');
        Observer.Expect('integer 7 (no member) caption from ordinal', '7');
        Observer.Verify();
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
        Observer.Expect('enum First on the option field name from ordinal', 'One');
        Observer.Expect('enum First on the option field caption from ordinal', 'One');
        Observer.Expect('enum First on the option field name by index', 'Zero');
        Observer.Expect('enum First on the option field caption by index', 'Zero');
        Observer.Expect('enum First on the option field ordinal by index', '0');
        Observer.Expect('enum First option parameter', 'One/1');
        Observer.Verify();
    end;
}
