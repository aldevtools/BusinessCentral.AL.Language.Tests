// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// local object: the field types of the table and the request page controls bound to them are under test (enum 62370, table 62371,
//   report 62372, log 62373).
// Area: TestRequestPage SetValue and Value on a request page control bound to a field of a GLOBAL record variable of the report
//   (al-runner issue 7376: an Option field, SetValue(1)).
//   Bindings: an Option field, an Enum field, a Decimal, a Boolean, a Date and a Text field of a global record; an Option field of
//   an element of an array of records; a plain Option variable and a plain Enum variable as controls.
//   Values: the ordinal as an Integer, the member name, the member name in another case, a prefix of the name, the Enum value
//   itself, an ordinal out of range and a text that is no member (the error text and code).
//   Observed: Value of the control before and after, the error of a refused SetValue, the field values the report sees in
//   OnPreReport after OK, and the Options of the parameters text.
// Already pinned elsewhere: a Text field of a global record and of an array element on a request page
//   (reports/request-page/R6960RequestParamBindings.al).
// No test writes to the database: the record is never stored.
// BC versions: 27-29
enum 62370 "RPT RpOpt Kind"
{
    Extensible = false;

    value(0; None) { Caption = 'None'; }
    value(1; First) { Caption = 'First one'; }
    value(4; Second) { Caption = 'Second one'; }
}

table 62371 "RPT RpOpt Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "Logo Position"; Option)
        {
            OptionMembers = "No Logo",Left,Center,Right;
            OptionCaption = 'No Logo,Left,Center,Right';
        }
        field(3; Kind; Enum "RPT RpOpt Kind") { }
        field(4; Qty; Decimal) { }
        field(5; Flag; Boolean) { }
        field(6; Day; Date) { }
        field(7; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 62373 "RPT RpOpt Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 62372 "RPT RpOpt List"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(LogoPosition; MySetup."Logo Position") { ApplicationArea = All; }
                field(KindCtl; MySetup.Kind) { ApplicationArea = All; }
                field(QtyCtl; MySetup.Qty) { ApplicationArea = All; }
                field(FlagCtl; MySetup.Flag) { ApplicationArea = All; }
                field(DayCtl; MySetup.Day) { ApplicationArea = All; }
                field(NameCtl; MySetup.Name) { ApplicationArea = All; }
                field(ArrLogoPosition; SetupArr[2]."Logo Position") { ApplicationArea = All; }
                field(PlainOption; PlainOptionValue) { ApplicationArea = All; }
                field(PlainEnum; PlainEnumValue) { ApplicationArea = All; }
            }
        }
    }

    trigger OnPreReport()
    begin
        L.Add('pre logo=' + Format(MySetup."Logo Position") + '/' + Format(MySetup."Logo Position", 0, 9) +
            ' kind=' + Format(MySetup.Kind) + '/' + Format(MySetup.Kind.AsInteger()) +
            ' qty=' + Format(MySetup.Qty, 0, 9) + ' flag=' + Format(MySetup.Flag) + ' day=' + Format(MySetup.Day, 0, 9) + ' name=' + MySetup.Name +
            ' arr=' + Format(SetupArr[2]."Logo Position", 0, 9) + ' arr1=' + Format(SetupArr[1]."Logo Position", 0, 9) +
            ' plainoption=' + Format(PlainOptionValue, 0, 9) + ' plainenum=' + Format(PlainEnumValue.AsInteger()));
    end;

    var
        MySetup: Record "RPT RpOpt Setup";
        SetupArr: array[2] of Record "RPT RpOpt Setup";
        PlainOptionValue: Option "No Logo",Left,Center,Right;
        PlainEnumValue: Enum "RPT RpOpt Kind";
        L: Codeunit "RPT RpOpt Log";
}

codeunit 62374 "RPT RpOpt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "RPT RpOpt Log";
        Mode: Integer;

    local procedure RunWith(NewMode: Integer)
    begin
        Mode := NewMode;
        L.Take();
        ClearLastError();
        Report.Run(Report::"RPT RpOpt List", true);
        Observer.Observe('report', L.Take());
    end;

    [TryFunction]
    local procedure TrySetLogo(var RP: TestRequestPage "RPT RpOpt List"; NewValue: Variant)
    begin
        RP.LogoPosition.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySetKind(var RP: TestRequestPage "RPT RpOpt List"; NewValue: Variant)
    begin
        RP.KindCtl.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySetArrLogo(var RP: TestRequestPage "RPT RpOpt List"; NewValue: Variant)
    begin
        RP.ArrLogoPosition.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySetPlainOption(var RP: TestRequestPage "RPT RpOpt List"; NewValue: Variant)
    begin
        RP.PlainOption.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySetPlainEnum(var RP: TestRequestPage "RPT RpOpt List"; NewValue: Variant)
    begin
        RP.PlainEnum.SetValue(NewValue);
    end;

    local procedure SetLogo(var RP: TestRequestPage "RPT RpOpt List"; Name: Text; NewValue: Variant)
    begin
        Observer.Observe(Name + ' ok', Format(TrySetLogo(RP, NewValue)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' value', RP.LogoPosition.Value);
    end;

    local procedure SetKind(var RP: TestRequestPage "RPT RpOpt List"; Name: Text; NewValue: Variant)
    begin
        Observer.Observe(Name + ' ok', Format(TrySetKind(RP, NewValue)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' value', RP.KindCtl.Value);
    end;

    // The reporter's shape: SetValue(1) on the Option field of the global record, then OK.
    [Test]
    [HandlerFunctions('Handler')]
    procedure RequestPage_OptionFieldOfGlobalRecord_SetValueInteger()
    begin
        RunWith(1);
        Observer.Expect('before value', 'No Logo');
        Observer.Expect('before integer', '0');
        Observer.Expect('after value', 'Left');
        Observer.Expect('after integer', '1');
        Observer.Expect('report', 'pre logo=Left/1 kind=None/0 qty=0 flag=No day= name= arr=0 arr1=0 plainoption=0 plainenum=0;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Handler')]
    procedure RequestPage_OptionFieldOfGlobalRecord_SetValueMemberNames()
    begin
        RunWith(2);
#if BC28PLUS
        Observer.Expect('name Center ok', 'No');
        Observer.Expect('name Center|text', 'The value "Center" can''t be evaluated into type Option.');
        Observer.Expect('name Center|code', 'Evaluate:Format');
        Observer.Expect('name Center value', 'No Logo');
        Observer.Expect('lower case right ok', 'No');
        Observer.Expect('lower case right|text', 'The value "right" can''t be evaluated into type Option.');
        Observer.Expect('lower case right|code', 'Evaluate:Format');
        Observer.Expect('lower case right value', 'No Logo');
        Observer.Expect('prefix Le ok', 'No');
        Observer.Expect('prefix Le|text', 'The value "Le" can''t be evaluated into type Option.');
        Observer.Expect('prefix Le|code', 'Evaluate:Format');
        Observer.Expect('prefix Le value', 'No Logo');
        Observer.Expect('name with space ok', 'No');
        Observer.Expect('name with space|text', 'The value "No Logo" can''t be evaluated into type Option.');
        Observer.Expect('name with space|code', 'Evaluate:Format');
        Observer.Expect('name with space value', 'No Logo');
        Observer.Expect('integer as text 2 ok', 'Yes');
        Observer.Expect('integer as text 2|text', '');
        Observer.Expect('integer as text 2|code', '');
        Observer.Expect('integer as text 2 value', 'Center');
        Observer.Expect('integer 3 ok', 'Yes');
        Observer.Expect('integer 3|text', '');
        Observer.Expect('integer 3|code', '');
        Observer.Expect('integer 3 value', 'Right');
        Observer.Expect('report', 'pre logo=Right/3 kind=None/0 qty=0 flag=No day= name= arr=0 arr1=0 plainoption=0 plainenum=0;');
        Observer.Verify();
#else
        Observer.Expect('name Center ok', 'No');
        Observer.Expect('name Center|text', 'The type NavOption is unknown.');
        Observer.Expect('name Center|code', 'NotSupportedType');
        Observer.Expect('name Center value', 'No Logo');
        Observer.Expect('lower case right ok', 'No');
        Observer.Expect('lower case right|text', 'The type NavOption is unknown.');
        Observer.Expect('lower case right|code', 'NotSupportedType');
        Observer.Expect('lower case right value', 'No Logo');
        Observer.Expect('prefix Le ok', 'No');
        Observer.Expect('prefix Le|text', 'The type NavOption is unknown.');
        Observer.Expect('prefix Le|code', 'NotSupportedType');
        Observer.Expect('prefix Le value', 'No Logo');
        Observer.Expect('name with space ok', 'No');
        Observer.Expect('name with space|text', 'The type NavOption is unknown.');
        Observer.Expect('name with space|code', 'NotSupportedType');
        Observer.Expect('name with space value', 'No Logo');
        Observer.Expect('integer as text 2 ok', 'Yes');
        Observer.Expect('integer as text 2|text', '');
        Observer.Expect('integer as text 2|code', '');
        Observer.Expect('integer as text 2 value', 'Center');
        Observer.Expect('integer 3 ok', 'Yes');
        Observer.Expect('integer 3|text', '');
        Observer.Expect('integer 3|code', '');
        Observer.Expect('integer 3 value', 'Right');
        Observer.Expect('report', 'pre logo=Right/3 kind=None/0 qty=0 flag=No day= name= arr=0 arr1=0 plainoption=0 plainenum=0;');
        Observer.Verify();
#endif
    end;

    [Test]
    [HandlerFunctions('Handler')]
    procedure RequestPage_OptionFieldOfGlobalRecord_SetValueRefused()
    begin
        RunWith(3);
#if BC28PLUS
        Observer.Expect('integer 2 ok', 'Yes');
        Observer.Expect('integer 2|text', '');
        Observer.Expect('integer 2|code', '');
        Observer.Expect('integer 2 value', 'Center');
        Observer.Expect('integer 9 ok', 'No');
        Observer.Expect('integer 9|text', 'Validation error for Field: LogoPosition,  Message = ''Your entry of ''2'' is not an acceptable value for ''LogoPosition''.''');
        Observer.Expect('integer 9|code', 'TestValidation');
        Observer.Expect('integer 9 value', '2');
        Observer.Expect('integer -1 ok', 'No');
        Observer.Expect('integer -1|text', 'Validation error for Field: LogoPosition,  Message = ''Your entry of ''2'' is not an acceptable value for ''LogoPosition''.''');
        Observer.Expect('integer -1|code', 'TestValidation');
        Observer.Expect('integer -1 value', '2');
        Observer.Expect('no member ok', 'No');
        Observer.Expect('no member|text', 'The value "Nope" can''t be evaluated into type Option.');
        Observer.Expect('no member|code', 'Evaluate:Format');
        Observer.Expect('no member value', '2');
        Observer.Expect('empty text ok', 'No');
        Observer.Expect('empty text|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty text|code', 'Evaluate:Format');
        Observer.Expect('empty text value', '2');
        Observer.Expect('boolean ok', 'Yes');
        Observer.Expect('boolean|text', '');
        Observer.Expect('boolean|code', '');
        Observer.Expect('boolean value', 'Left');
        Observer.Expect('report', 'pre logo=Left/1 kind=None/0 qty=0 flag=No day= name= arr=0 arr1=0 plainoption=0 plainenum=0;');
        Observer.Verify();
#else
        Observer.Expect('integer 2 ok', 'Yes');
        Observer.Expect('integer 2|text', '');
        Observer.Expect('integer 2|code', '');
        Observer.Expect('integer 2 value', 'Center');
        Observer.Expect('integer 9 ok', 'No');
        Observer.Expect('integer 9|text', 'Validation error for Field: LogoPosition,  Message = ''Your entry of ''2'' is not an acceptable value for ''LogoPosition''.''');
        Observer.Expect('integer 9|code', 'TestValidation');
        Observer.Expect('integer 9 value', '2');
        Observer.Expect('integer -1 ok', 'No');
        Observer.Expect('integer -1|text', 'Validation error for Field: LogoPosition,  Message = ''Your entry of ''2'' is not an acceptable value for ''LogoPosition''.''');
        Observer.Expect('integer -1|code', 'TestValidation');
        Observer.Expect('integer -1 value', '2');
        Observer.Expect('no member ok', 'No');
        Observer.Expect('no member|text', 'The type NavOption is unknown.');
        Observer.Expect('no member|code', 'NotSupportedType');
        Observer.Expect('no member value', '2');
        Observer.Expect('empty text ok', 'No');
        Observer.Expect('empty text|text', 'The type NavOption is unknown.');
        Observer.Expect('empty text|code', 'NotSupportedType');
        Observer.Expect('empty text value', '2');
        Observer.Expect('boolean ok', 'Yes');
        Observer.Expect('boolean|text', '');
        Observer.Expect('boolean|code', '');
        Observer.Expect('boolean value', 'Left');
        Observer.Expect('report', 'pre logo=Left/1 kind=None/0 qty=0 flag=No day= name= arr=0 arr1=0 plainoption=0 plainenum=0;');
        Observer.Verify();
#endif
    end;

    [Test]
    [HandlerFunctions('Handler')]
    procedure RequestPage_EnumFieldOfGlobalRecord_SetValueForms()
    begin
        RunWith(4);
#if BC28PLUS
        Observer.Expect('before value', 'None');
        Observer.Expect('integer 1 ok', 'Yes');
        Observer.Expect('integer 1|text', '');
        Observer.Expect('integer 1|code', '');
        Observer.Expect('integer 1 value', 'First one');
        Observer.Expect('integer 4 ok', 'Yes');
        Observer.Expect('integer 4|text', '');
        Observer.Expect('integer 4|code', '');
        Observer.Expect('integer 4 value', 'Second one');
        Observer.Expect('name First ok', 'No');
        Observer.Expect('name First|text', 'The value "First" can''t be evaluated into type Option.');
        Observer.Expect('name First|code', 'Evaluate:Format');
        Observer.Expect('name First value', 'Second one');
        Observer.Expect('caption Second one ok', 'No');
        Observer.Expect('caption Second one|text', 'The value "Second one" can''t be evaluated into type Option.');
        Observer.Expect('caption Second one|code', 'Evaluate:Format');
        Observer.Expect('caption Second one value', 'Second one');
        Observer.Expect('enum value First ok', 'Yes');
        Observer.Expect('enum value First|text', '');
        Observer.Expect('enum value First|code', '');
        Observer.Expect('enum value First value', 'First one');
        Observer.Expect('enum value Second ok', 'Yes');
        Observer.Expect('enum value Second|text', '');
        Observer.Expect('enum value Second|code', '');
        Observer.Expect('enum value Second value', 'Second one');
        Observer.Expect('report', 'pre logo=No Logo/0 kind=Second one/4 qty=0 flag=No day= name= arr=0 arr1=0 plainoption=0 plainenum=0;');
        Observer.Verify();
#else
        Observer.Expect('before value', 'None');
        Observer.Expect('integer 1 ok', 'Yes');
        Observer.Expect('integer 1|text', '');
        Observer.Expect('integer 1|code', '');
        Observer.Expect('integer 1 value', 'First one');
        Observer.Expect('integer 4 ok', 'Yes');
        Observer.Expect('integer 4|text', '');
        Observer.Expect('integer 4|code', '');
        Observer.Expect('integer 4 value', 'Second one');
        Observer.Expect('name First ok', 'No');
        Observer.Expect('name First|text', 'The type NavOption is unknown.');
        Observer.Expect('name First|code', 'NotSupportedType');
        Observer.Expect('name First value', 'Second one');
        Observer.Expect('caption Second one ok', 'No');
        Observer.Expect('caption Second one|text', 'The type NavOption is unknown.');
        Observer.Expect('caption Second one|code', 'NotSupportedType');
        Observer.Expect('caption Second one value', 'Second one');
        Observer.Expect('enum value First ok', 'Yes');
        Observer.Expect('enum value First|text', '');
        Observer.Expect('enum value First|code', '');
        Observer.Expect('enum value First value', 'First one');
        Observer.Expect('enum value Second ok', 'Yes');
        Observer.Expect('enum value Second|text', '');
        Observer.Expect('enum value Second|code', '');
        Observer.Expect('enum value Second value', 'Second one');
        Observer.Expect('report', 'pre logo=No Logo/0 kind=Second one/4 qty=0 flag=No day= name= arr=0 arr1=0 plainoption=0 plainenum=0;');
        Observer.Verify();
#endif
    end;

    [Test]
    [HandlerFunctions('Handler')]
    procedure RequestPage_EnumFieldOfGlobalRecord_SetValueRefused()
    begin
        RunWith(5);
#if BC28PLUS
        Observer.Expect('integer 4 ok', 'Yes');
        Observer.Expect('integer 4|text', '');
        Observer.Expect('integer 4|code', '');
        Observer.Expect('integer 4 value', 'Second one');
        Observer.Expect('integer 2 is no ordinal ok', 'No');
        Observer.Expect('integer 2 is no ordinal|text', 'Validation error for Field: KindCtl,  Message = ''Your entry of ''4'' is not an acceptable value for ''KindCtl''.''');
        Observer.Expect('integer 2 is no ordinal|code', 'TestValidation');
        Observer.Expect('integer 2 is no ordinal value', '4');
        Observer.Expect('integer 9 ok', 'No');
        Observer.Expect('integer 9|text', 'Validation error for Field: KindCtl,  Message = ''Your entry of ''4'' is not an acceptable value for ''KindCtl''.''');
        Observer.Expect('integer 9|code', 'TestValidation');
        Observer.Expect('integer 9 value', '4');
        Observer.Expect('no member ok', 'No');
        Observer.Expect('no member|text', 'The value "Nope" can''t be evaluated into type Option.');
        Observer.Expect('no member|code', 'Evaluate:Format');
        Observer.Expect('no member value', '4');
        Observer.Expect('lower case caption ok', 'No');
        Observer.Expect('lower case caption|text', 'The value "first one" can''t be evaluated into type Option.');
        Observer.Expect('lower case caption|code', 'Evaluate:Format');
        Observer.Expect('lower case caption value', '4');
        Observer.Expect('report', 'pre logo=No Logo/0 kind=Second one/4 qty=0 flag=No day= name= arr=0 arr1=0 plainoption=0 plainenum=0;');
        Observer.Verify();
#else
        Observer.Expect('integer 4 ok', 'Yes');
        Observer.Expect('integer 4|text', '');
        Observer.Expect('integer 4|code', '');
        Observer.Expect('integer 4 value', 'Second one');
        Observer.Expect('integer 2 is no ordinal ok', 'No');
        Observer.Expect('integer 2 is no ordinal|text', 'Validation error for Field: KindCtl,  Message = ''Your entry of ''4'' is not an acceptable value for ''KindCtl''.''');
        Observer.Expect('integer 2 is no ordinal|code', 'TestValidation');
        Observer.Expect('integer 2 is no ordinal value', '4');
        Observer.Expect('integer 9 ok', 'No');
        Observer.Expect('integer 9|text', 'Validation error for Field: KindCtl,  Message = ''Your entry of ''4'' is not an acceptable value for ''KindCtl''.''');
        Observer.Expect('integer 9|code', 'TestValidation');
        Observer.Expect('integer 9 value', '4');
        Observer.Expect('no member ok', 'No');
        Observer.Expect('no member|text', 'The type NavOption is unknown.');
        Observer.Expect('no member|code', 'NotSupportedType');
        Observer.Expect('no member value', '4');
        Observer.Expect('lower case caption ok', 'No');
        Observer.Expect('lower case caption|text', 'The type NavOption is unknown.');
        Observer.Expect('lower case caption|code', 'NotSupportedType');
        Observer.Expect('lower case caption value', '4');
        Observer.Expect('report', 'pre logo=No Logo/0 kind=Second one/4 qty=0 flag=No day= name= arr=0 arr1=0 plainoption=0 plainenum=0;');
        Observer.Verify();
#endif
    end;

    [Test]
    [HandlerFunctions('Handler')]
    procedure RequestPage_OtherFieldTypesOfGlobalRecord_SetValue()
    begin
        RunWith(6);
        Observer.Expect('qty value', '1.50');
        Observer.Expect('flag value', 'Yes');
        Observer.Expect('day value', '1/31/2026');
        Observer.Expect('name value', 'abc');
        Observer.Expect('report', 'pre logo=No Logo/0 kind=None/0 qty=1.5 flag=Yes day=2026-01-31 name=abc arr=0 arr1=0 plainoption=0 plainenum=0;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Handler')]
    procedure RequestPage_OptionFieldOfArrayElement_AndPlainVariables_SetValue()
    begin
        RunWith(7);
#if BC28PLUS
        Observer.Expect('array element integer 2 ok', 'Yes');
        Observer.Expect('array element integer 2|text', '');
        Observer.Expect('array element integer 2|code', '');
        Observer.Expect('array element value', 'Center');
        Observer.Expect('array element name Right ok', 'No');
        Observer.Expect('array element name Right|text', 'The value "Right" can''t be evaluated into type Option.');
        Observer.Expect('array element name Right|code', 'Evaluate:Format');
        Observer.Expect('array element value 2', 'Center');
        Observer.Expect('plain option integer 1 ok', 'Yes');
        Observer.Expect('plain option integer 1|text', '');
        Observer.Expect('plain option integer 1|code', '');
        Observer.Expect('plain option value', 'Left');
        Observer.Expect('plain enum integer 4 ok', 'Yes');
        Observer.Expect('plain enum integer 4|text', '');
        Observer.Expect('plain enum integer 4|code', '');
        Observer.Expect('plain enum value', 'Second one');
        Observer.Expect('report', 'pre logo=No Logo/0 kind=None/0 qty=0 flag=No day= name= arr=2 arr1=0 plainoption=1 plainenum=4;');
        Observer.Verify();
#else
        Observer.Expect('array element integer 2 ok', 'Yes');
        Observer.Expect('array element integer 2|text', '');
        Observer.Expect('array element integer 2|code', '');
        Observer.Expect('array element value', 'Center');
        Observer.Expect('array element name Right ok', 'No');
        Observer.Expect('array element name Right|text', 'The type NavOption is unknown.');
        Observer.Expect('array element name Right|code', 'NotSupportedType');
        Observer.Expect('array element value 2', 'Center');
        Observer.Expect('plain option integer 1 ok', 'Yes');
        Observer.Expect('plain option integer 1|text', '');
        Observer.Expect('plain option integer 1|code', '');
        Observer.Expect('plain option value', 'Left');
        Observer.Expect('plain enum integer 4 ok', 'Yes');
        Observer.Expect('plain enum integer 4|text', '');
        Observer.Expect('plain enum integer 4|code', '');
        Observer.Expect('plain enum value', 'Second one');
        Observer.Expect('report', 'pre logo=No Logo/0 kind=None/0 qty=0 flag=No day= name= arr=2 arr1=0 plainoption=1 plainenum=4;');
        Observer.Verify();
#endif
    end;

    [Test]
    [HandlerFunctions('Handler')]
    procedure RequestPage_FieldsOfGlobalRecord_ParametersText()
    var
        Parameters: Text;
        At: Integer;
    begin
        Mode := 8;
        Parameters := Report.RunRequestPage(Report::"RPT RpOpt List");
        At := Parameters.IndexOf('<Options>');
        if At > 0 then
            Parameters := Parameters.Substring(At);
        Observer.Observe('parameters', Parameters);
        Observer.Expect('parameters', '<Options><Field name="MySetup.&quot;Logo Position&quot;">2</Field><Field name="MySetup.Kind">4</Field><Field name="MySetup.Qty">1.5</Field><Field name="MySetup.Flag">true</Field><Field name="MySetup.Day" /><Field name="MySetup.Name" /><Field name="SetupArr[2].&quot;Logo Position&quot;">3</Field><Field name="PlainOptionValue">1</Field><Field name="PlainEnumValue">1</Field></Options><DataItems><DataItem name="One">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure Handler(var RP: TestRequestPage "RPT RpOpt List")
    var
        Kind: Enum "RPT RpOpt Kind";
    begin
        case Mode of
            1:
                begin
                    Observer.Observe('before value', RP.LogoPosition.Value);
                    Observer.Observe('before integer', Format(RP.LogoPosition.AsInteger()));
                    RP.LogoPosition.SetValue(1);
                    Observer.Observe('after value', RP.LogoPosition.Value);
                    Observer.Observe('after integer', Format(RP.LogoPosition.AsInteger()));
                end;
            2:
                begin
                    SetLogo(RP, 'name Center', 'Center');
                    SetLogo(RP, 'lower case right', 'right');
                    SetLogo(RP, 'prefix Le', 'Le');
                    SetLogo(RP, 'name with space', 'No Logo');
                    SetLogo(RP, 'integer as text 2', '2');
                    SetLogo(RP, 'integer 3', 3);
                end;
            3:
                begin
                    SetLogo(RP, 'integer 2', 2);
                    SetLogo(RP, 'integer 9', 9);
                    SetLogo(RP, 'integer -1', -1);
                    SetLogo(RP, 'no member', 'Nope');
                    SetLogo(RP, 'empty text', '');
                    SetLogo(RP, 'boolean', true);
                end;
            4:
                begin
                    Observer.Observe('before value', RP.KindCtl.Value);
                    SetKind(RP, 'integer 1', 1);
                    SetKind(RP, 'integer 4', 4);
                    SetKind(RP, 'name First', 'First');
                    SetKind(RP, 'caption Second one', 'Second one');
                    Kind := Kind::First;
                    SetKind(RP, 'enum value First', Kind);
                    Kind := Kind::Second;
                    SetKind(RP, 'enum value Second', Kind);
                end;
            5:
                begin
                    SetKind(RP, 'integer 4', 4);
                    SetKind(RP, 'integer 2 is no ordinal', 2);
                    SetKind(RP, 'integer 9', 9);
                    SetKind(RP, 'no member', 'Nope');
                    SetKind(RP, 'lower case caption', 'first one');
                end;
            6:
                begin
                    RP.QtyCtl.SetValue(1.5);
                    RP.FlagCtl.SetValue(true);
                    RP.DayCtl.SetValue(20260131D);
                    RP.NameCtl.SetValue('abc');
                    Observer.Observe('qty value', RP.QtyCtl.Value);
                    Observer.Observe('flag value', RP.FlagCtl.Value);
                    Observer.Observe('day value', RP.DayCtl.Value);
                    Observer.Observe('name value', RP.NameCtl.Value);
                end;
            7:
                begin
                    Observer.Observe('array element integer 2 ok', Format(TrySetArrLogo(RP, 2)));
                    Observer.ObserveError('array element integer 2');
                    Observer.Observe('array element value', RP.ArrLogoPosition.Value);
                    Observer.Observe('array element name Right ok', Format(TrySetArrLogo(RP, 'Right')));
                    Observer.ObserveError('array element name Right');
                    Observer.Observe('array element value 2', RP.ArrLogoPosition.Value);
                    Observer.Observe('plain option integer 1 ok', Format(TrySetPlainOption(RP, 1)));
                    Observer.ObserveError('plain option integer 1');
                    Observer.Observe('plain option value', RP.PlainOption.Value);
                    Observer.Observe('plain enum integer 4 ok', Format(TrySetPlainEnum(RP, 4)));
                    Observer.ObserveError('plain enum integer 4');
                    Observer.Observe('plain enum value', RP.PlainEnum.Value);
                end;
            8:
                begin
                    RP.LogoPosition.SetValue(2);
                    RP.KindCtl.SetValue(4);
                    RP.QtyCtl.SetValue(1.5);
                    RP.FlagCtl.SetValue(true);
                    RP.ArrLogoPosition.SetValue(3);
                    RP.PlainOption.SetValue(1);
                    RP.PlainEnum.SetValue(1);
                end;
        end;
        RP.OK().Invoke();
    end;
}
