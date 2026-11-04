// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enums 95450 and 95451, tables 95452 and 95453, test codeunit 95454; Base Application
// page "Table Filter" and table "Table Filter"
// Probe: (al-runner issue 6951) Evaluate of a text into a TableFilter field whose condition is on an Enum field (names, captions,
// ordinals, lists, ranges, <>, a bad member) and on an Option field (lists, ranges, <>), with what Format of the field gives back.
// Then the Base Application page "Table Filter" fed with Format of such a field (SetSourceTable, GetFilterFieldsList): which
// fields and filter texts it lists, for a Code `<>` condition, an Enum condition and two conditions. The single Option member
// forms are pinned in record/W4PlatformAndMeta.al (TableFilterEvaluate_*).
// BC versions: 27+

enum 95450 "LT R6951 Cost Kind"
{
    Extensible = false;

    value(0; Labor) { Caption = 'Labor Cap'; }
    value(1; Setting) { Caption = 'Setting Cap'; }
    value(5; Travel) { Caption = 'Travel Cap'; }
}

enum 95451 "LT R6951 Config Kind"
{
    Extensible = false;

    value(0; Item) { }
    value(1; Variant) { }
    value(2; Service) { }
}

table 95452 "LT R6951 Target"
{
    Caption = 'LT R6951 Target';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { DataClassification = SystemMetadata; }
        field(2; "Cost Type"; Enum "LT R6951 Cost Kind") { Caption = 'Cost Type Cap'; DataClassification = SystemMetadata; }
        field(3; "Config Type"; Enum "LT R6951 Config Kind") { DataClassification = SystemMetadata; }
        field(4; "Employee No."; Code[20]) { DataClassification = SystemMetadata; }
        field(5; Status; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = Open,Released,Closed;
            OptionCaption = 'Open Cap,Released Cap,Closed Cap';
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 95453 "LT R6951 Holder"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { DataClassification = SystemMetadata; }
        field(2; Flt; TableFilter) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 95454 "LT R6951 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEval(var Row: Record "LT R6951 Holder"; Value: Text; var Ok: Boolean)
    begin
        Ok := Evaluate(Row.Flt, Value);
    end;

    // '<return>|[<Format of the field>]|<last error>', or 'throws:<text>|<code>' when Evaluate raises anyway.
    local procedure Eval(Value: Text): Text
    var
        Row: Record "LT R6951 Holder";
        Ok: Boolean;
        Result: Text;
    begin
        ClearLastError();
        if not TryEval(Row, Value, Ok) then
            Result := 'throws:' + GetLastErrorText() + '|' + GetLastErrorCode()
        else
            Result := Format(Ok) + '|[' + Format(Row.Flt) + ']|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure TableFilterEvaluate_EnumMemberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('name', Eval('LT R6951 Target: Cost Type=Setting'));
        Observer.Observe('name_lower', Eval('LT R6951 Target: Cost Type=setting'));
        Observer.Observe('caption', Eval('LT R6951 Target: Cost Type=Setting Cap'));
        Observer.Observe('ordinal', Eval('LT R6951 Target: Cost Type=5'));
        Observer.Observe('first_member', Eval('LT R6951 Target: Cost Type=Labor'));
        Observer.Observe('bad_member', Eval('LT R6951 Target: Cost Type=Nope'));
        Observer.Observe('no_caption_enum', Eval('LT R6951 Target: Config Type=Variant'));
        Observer.Observe('filter_wrapper', Eval('LT R6951 Target: Cost Type=FILTER(Setting)'));
        Observer.Finish();
    end;

    [Test]
    procedure TableFilterEvaluate_EnumExpressions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('list_names', Eval('LT R6951 Target: Config Type=Item|Variant'));
        Observer.Observe('list_three', Eval('LT R6951 Target: Config Type=Item|Variant|Service'));
        Observer.Observe('list_captions', Eval('LT R6951 Target: Cost Type=Labor Cap|Travel Cap'));
        Observer.Observe('list_names_with_captions', Eval('LT R6951 Target: Cost Type=Labor|Travel'));
        Observer.Observe('not_equal', Eval('LT R6951 Target: Cost Type=<>Setting'));
        Observer.Observe('range', Eval('LT R6951 Target: Config Type=Item..Variant'));
        Observer.Observe('list_with_bad', Eval('LT R6951 Target: Config Type=Item|Nope'));
        Observer.Observe('two_fields', Eval('LT R6951 Target: Code=A,Config Type=Item|Variant'));
        Observer.Finish();
    end;

    [Test]
    procedure TableFilterEvaluate_OptionExpressions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('list_names', Eval('LT R6951 Target: Status=Open|Released'));
        Observer.Observe('list_captions', Eval('LT R6951 Target: Status=Open Cap|Closed Cap'));
        Observer.Observe('not_equal', Eval('LT R6951 Target: Status=<>Closed'));
        Observer.Observe('range', Eval('LT R6951 Target: Status=Open..Released'));
        Observer.Finish();
    end;

    [Test]
    procedure TableFilterEvaluate_EnumRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT R6951 Holder";
        Copy: Record "LT R6951 Holder";
    begin
        Evaluate(Row.Flt, 'LT R6951 Target: Config Type=Item|Variant');
        Observer.Observe('format', Format(Row.Flt));
        Observer.Observe('format_9', Format(Row.Flt, 0, 9));
        Observer.Observe('roundtrip', Format(Evaluate(Copy.Flt, Format(Row.Flt))) + '|[' + Format(Copy.Flt) + ']');
        Row.Id := 1;
        Row.Insert();
        Copy.Get(1);
        Observer.Observe('stored', Format(Copy.Flt));
        Row.Delete();
        Observer.Finish();
    end;

    // The Base Application page "Table Filter", used without opening it, as code that edits a TableFilter field does.
    local procedure FilterFields(Value: Text): Text
    var
        Row: Record "LT R6951 Holder";
        Target: Record "LT R6951 Target";
        Fields: Record "Table Filter" temporary;
        FilterPage: Page "Table Filter";
        Result: Text;
    begin
        Evaluate(Row.Flt, Value);
        FilterPage.SetSourceTable(Format(Row.Flt), Database::"LT R6951 Target", Target.TableCaption());
        FilterPage.GetFilterFieldsList(Fields);
        if Fields.FindSet() then
            repeat
                Result += Format(Fields."Field Number") + '=' + Fields."Field Filter" + ';';
            until Fields.Next() = 0;
        exit('[' + Result + ']');
    end;

    [Test]
    procedure TableFilterPage_FieldsList()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('code_not_equal', FilterFields('LT R6951 Target: Employee No.=<>XYZ'));
        Observer.Observe('enum_member', FilterFields('LT R6951 Target: Cost Type=Setting'));
        Observer.Observe('enum_list', FilterFields('LT R6951 Target: Config Type=Item|Variant'));
        Observer.Observe('two_fields', FilterFields('LT R6951 Target: Code=A..B,Employee No.=<>XYZ'));
        Observer.Finish();
    end;

    [Test]
    procedure TableFilterPage_AppliedToRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT R6951 Holder";
        Target: Record "LT R6951 Target";
        Fields: Record "Table Filter" temporary;
        FilterPage: Page "Table Filter";
        TargetRef: RecordRef;
        TargetField: FieldRef;
    begin
        Evaluate(Row.Flt, 'LT R6951 Target: Employee No.=<>XYZ');
        FilterPage.SetSourceTable(Format(Row.Flt), Database::"LT R6951 Target", Target.TableCaption());
        FilterPage.GetFilterFieldsList(Fields);
        TargetRef.Open(Database::"LT R6951 Target", true);
        if Fields.FindSet() then
            repeat
                TargetField := TargetRef.Field(Fields."Field Number");
                TargetField.SetFilter(Fields."Field Filter");
            until Fields.Next() = 0;
        TargetField := TargetRef.Field(Target.FieldNo("Employee No."));
        Observer.Observe('employee_filter', TargetField.GetFilter());
        Observer.Observe('getfilters', TargetRef.GetFilters());
        TargetRef.Close();
        Observer.Finish();
    end;
}
