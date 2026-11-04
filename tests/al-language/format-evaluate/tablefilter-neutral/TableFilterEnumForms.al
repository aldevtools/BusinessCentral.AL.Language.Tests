// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enums 95450 and 95451, tables 95452, 95453 and 95456, test codeunit 95454, page 95455,
// log codeunit 95457; Base Application
// page "Table Filter" and table "Table Filter"
// Probe: (al-runner issue 6951) Evaluate of a text into a TableFilter field whose condition is on an Enum field (names, captions,
// ordinals, lists, ranges, <>, a bad member) and on an Option field (lists, ranges, <>), with what Format of the field gives back.
// Then the Base Application page "Table Filter" fed with Format of such a field (SetSourceTable, GetFilterFieldsList): which
// fields and filter texts it lists, for a Code `<>` condition, an Enum condition and two conditions. The single Option member
// forms are pinned in record/W4PlatformAndMeta.al (TableFilterEvaluate_*).
// Also: what CurrPage.Update(true), Update(false) and Update() do when a procedure of a Page variable that was never run calls them
// after setting the fields of a new record of the page's temporary source table, on a List page with AutoSplitKey and
// DelayedInsert (the shape of "Table Filter", whose SetSourceTable fills its lines this way): which rows the source table then
// holds, with which "Line No.", and which page and table triggers run.
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

table 95456 "LT R6951 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Table Number"; Integer) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; "Field Number"; Integer) { DataClassification = SystemMetadata; }
        field(4; "Field Filter"; Text[250]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Table Number", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT R6951 Log";
    begin
        Log.Add('T.OnInsert:' + Format("Line No.") + '/' + Format("Field Number"));
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT R6951 Log";
    begin
        Log.Add('T.OnModify:' + Format("Line No.") + '/' + Format("Field Number"));
    end;
}

codeunit 95457 "LT R6951 Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        if Lines <> '' then
            Lines += ' | ';
        Lines += Line;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := '[' + Lines + ']';
        Lines := '';
        exit(Result);
    end;
}

page 95455 "LT R6951 Lines"
{
    PageType = List;
    SourceTable = "LT R6951 Line";
    SourceTableTemporary = true;
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Field Number"; Rec."Field Number") { ApplicationArea = All; }
                field("Field Filter"; Rec."Field Filter") { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT R6951 Log";
    begin
        Log.Add('P.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT R6951 Log";
    begin
        Log.Add('P.OnInsertRecord:' + Format(Rec."Line No.") + '/' + Format(Rec."Field Number") + ' below=' + Format(BelowxRec));
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT R6951 Log";
    begin
        Log.Add('P.OnModifyRecord:' + Format(Rec."Line No.") + '/' + Format(Rec."Field Number"));
    end;

    // As "Table Filter" does it: a new record of the source table, its fields set, then CurrPage.Update. Mode: 'true', 'false',
    // 'none' (Update without an argument) or 'skip' (no Update).
    procedure AddLine(FieldNumber: Integer; FieldFilter: Text; Mode: Text)
    begin
        Rec.SetRange("Field Number");
        Rec.Init();
        Rec."Table Number" := 95452;
        Rec."Field Number" := FieldNumber;
        Rec."Line No." := 0;
        Rec."Field Filter" := CopyStr(FieldFilter, 1, 250);
        case Mode of
            'true':
                CurrPage.Update(true);
            'false':
                CurrPage.Update(false);
            'none':
                CurrPage.Update();
        end;
    end;

    procedure Rows(): Text
    var
        Result: Text;
    begin
        Rec.Reset();
        if Rec.FindSet() then
            repeat
                Result += Format(Rec."Line No.") + ':' + Format(Rec."Field Number") + '=' + Rec."Field Filter" + ';';
            until Rec.Next() = 0;
        exit('[' + Result + ']');
    end;
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

    local procedure UpdateNeverRun(Mode: Text; Lines: Integer; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT R6951 Log";
        P: Page "LT R6951 Lines";
    begin
        Log.Take();
        P.AddLine(1, 'A..B', Mode);
        Observer.Observe(Mode + '_first_log', Log.Take());
        if Lines > 1 then begin
            P.AddLine(4, '<>XYZ', Mode);
            Observer.Observe(Mode + '_second_log', Log.Take());
        end;
        Observer.Observe(Mode + '_rows', P.Rows());
    end;

    [Test]
    procedure UpdateNeverRunPage_NewRecord_UpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UpdateNeverRun('true', 2, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure UpdateNeverRunPage_NewRecord_UpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UpdateNeverRun('false', 2, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure UpdateNeverRunPage_NewRecord_UpdateNoArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UpdateNeverRun('none', 2, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure UpdateNeverRunPage_NewRecord_NoUpdate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UpdateNeverRun('skip', 1, Observer);
        Observer.Finish();
    end;
}
