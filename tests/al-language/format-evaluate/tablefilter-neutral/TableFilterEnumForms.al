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
// Seen on BC 29 (Linux CI): an Enum condition is stored with the member's caption, whether the text gives the name (any casing),
// the caption or the ordinal; a list (`Item|Variant`, names or captions), `<>X` and `X..Y` are stored with captions too, and a
// bad member, also inside a list, gives "'Nope' is not an option. The existing options are: <captions>". An Option field
// takes lists, `<>` and ranges the same way. Format, Format(.., 0, 9), a round trip and a stored row give the same text. The
// "Table Filter" page lists one line per condition with the field number and the stored filter text (`2=Setting Cap`), and its
// lines applied to a RecordRef give the filter back (`<>XYZ`). CurrPage.Update(true) and Update() of the never-run page variable
// insert the new record: OnInsertRecord (BelowxRec No for the first, Yes for the next) and the table's OnInsert run, and
// AutoSplitKey numbers the lines 10000, 20000. Update(false) and no Update insert nothing.
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

    procedure RowsText(): Text
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
            Result := Format(Ok) + '|[' + Format(Row.Flt) + ']|' + ErrorHead(GetLastErrorText());
        ClearLastError();
        exit(Result);
    end;

    // The error text up to its first backslash: the "For more information" link after it is not asserted (as in
    // record/W4PlatformAndMeta.al ErrorHead).
    local procedure ErrorHead(Value: Text): Text
    begin
        if StrPos(Value, '\') > 0 then
            Value := CopyStr(Value, 1, StrPos(Value, '\') - 1);
        exit(DelChr(Value, '>', ' '));
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
        Observer.Expect('name', 'Yes|[LT R6951 Target: Cost Type Cap=Setting Cap]|');
        Observer.Expect('name_lower', 'Yes|[LT R6951 Target: Cost Type Cap=Setting Cap]|');
        Observer.Expect('caption', 'Yes|[LT R6951 Target: Cost Type Cap=Setting Cap]|');
        Observer.Expect('ordinal', 'Yes|[LT R6951 Target: Cost Type Cap=Travel Cap]|');
        Observer.Expect('first_member', 'Yes|[LT R6951 Target: Cost Type Cap=Labor Cap]|');
        Observer.Expect('bad_member', 'No|[]|The value "LT R6951 Target: Cost Type=Nope" can''t be evaluated into type TableFilter. ''Nope'' is not an option. The existing options are: Labor Cap,Setting Cap,Travel Cap');
        Observer.Expect('no_caption_enum', 'Yes|[LT R6951 Target: Config Type=Variant]|');
        Observer.Expect('filter_wrapper', 'No|[]|The value "LT R6951 Target: Cost Type=FILTER(Setting)" can''t be evaluated into type TableFilter. An error occurred while interpreting the filter: Did not expect ''(''.');
        Observer.Verify();
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
        Observer.Expect('list_names', 'Yes|[LT R6951 Target: Config Type=Item|Variant]|');
        Observer.Expect('list_three', 'Yes|[LT R6951 Target: Config Type=Item|Variant|Service]|');
        Observer.Expect('list_captions', 'Yes|[LT R6951 Target: Cost Type Cap=Labor Cap|Travel Cap]|');
        Observer.Expect('list_names_with_captions', 'Yes|[LT R6951 Target: Cost Type Cap=Labor Cap|Travel Cap]|');
        Observer.Expect('not_equal', 'Yes|[LT R6951 Target: Cost Type Cap=<>Setting Cap]|');
        Observer.Expect('range', 'Yes|[LT R6951 Target: Config Type=Item..Variant]|');
        Observer.Expect('list_with_bad', 'No|[]|The value "LT R6951 Target: Config Type=Item|Nope" can''t be evaluated into type TableFilter. ''Nope'' is not an option. The existing options are: Item,Variant,Service');
        Observer.Expect('two_fields', 'Yes|[LT R6951 Target: Code=A,Config Type=Item|Variant]|');
        Observer.Verify();
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
        Observer.Expect('list_names', 'Yes|[LT R6951 Target: Status=Open Cap|Released Cap]|');
        Observer.Expect('list_captions', 'Yes|[LT R6951 Target: Status=Open Cap|Closed Cap]|');
        Observer.Expect('not_equal', 'Yes|[LT R6951 Target: Status=<>Closed Cap]|');
        Observer.Expect('range', 'Yes|[LT R6951 Target: Status=Open Cap..Released Cap]|');
        Observer.Verify();
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
        Observer.Expect('format', 'LT R6951 Target: Config Type=Item|Variant');
        Observer.Expect('format_9', 'LT R6951 Target: Config Type=Item|Variant');
        Observer.Expect('roundtrip', 'Yes|[LT R6951 Target: Config Type=Item|Variant]');
        Observer.Expect('stored', 'LT R6951 Target: Config Type=Item|Variant');
        Observer.Verify();
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
        Observer.Expect('code_not_equal', '[4=<>XYZ;]');
        Observer.Expect('enum_member', '[2=Setting Cap;]');
        Observer.Expect('enum_list', '[3=Item|Variant;]');
        Observer.Expect('two_fields', '[1=A..B;4=<>XYZ;]');
        Observer.Verify();
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
        Observer.Expect('employee_filter', '<>XYZ');
        Observer.Expect('getfilters', 'Employee No.: <>XYZ');
        Observer.Verify();
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
        Observer.Observe(Mode + '_rows', P.RowsText());
    end;

    [Test]
    procedure UpdateNeverRunPage_NewRecord_UpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UpdateNeverRun('true', 2, Observer);
        Observer.Expect('true_first_log', '[P.OnInsertRecord:10000/1 below=No | T.OnInsert:10000/1]');
        Observer.Expect('true_second_log', '[P.OnInsertRecord:20000/4 below=Yes | T.OnInsert:20000/4]');
        Observer.Expect('true_rows', '[10000:1=A..B;20000:4=<>XYZ;]');
        Observer.Verify();
    end;

    [Test]
    procedure UpdateNeverRunPage_NewRecord_UpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UpdateNeverRun('false', 2, Observer);
        Observer.Expect('false_first_log', '[]');
        Observer.Expect('false_second_log', '[]');
        Observer.Expect('false_rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure UpdateNeverRunPage_NewRecord_UpdateNoArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UpdateNeverRun('none', 2, Observer);
        Observer.Expect('none_first_log', '[P.OnInsertRecord:10000/1 below=No | T.OnInsert:10000/1]');
        Observer.Expect('none_second_log', '[P.OnInsertRecord:20000/4 below=Yes | T.OnInsert:20000/4]');
        Observer.Expect('none_rows', '[10000:1=A..B;20000:4=<>XYZ;]');
        Observer.Verify();
    end;

    [Test]
    procedure UpdateNeverRunPage_NewRecord_NoUpdate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UpdateNeverRun('skip', 1, Observer);
        Observer.Expect('skip_first_log', '[]');
        Observer.Expect('skip_rows', '[]');
        Observer.Verify();
    end;

    // BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
    // Fixtures: shared ALT TableFilter Holder and own FMT Blank Filter Row; BC 27.5+.
    [Test]
    procedure TableFilter_Evaluate_QuotedBlankEnum_SelectsBlankMember()
    var
        Holder: Record "ALT TableFilter Holder";
        Row: Record "FMT Blank Filter Row";
    begin
        Initialize();
        Row.Code := 'BLANK42';
        Row.Insert(false);
        Row.Init();
        Row.Code := 'MARKED42';
        Row.Choice := Row.Choice::Marked;
        Row.Insert(false);
        Evaluate(Holder."Filter Value", 'FMT Blank Filter Row: Choice=''''');
        AssertFilteredRow(Format(Holder."Filter Value"), 'BLANK42');
    end;

    [Test]
    procedure TableFilter_Evaluate_NotEqualQuotedBlankCode_SelectsNonemptyCode()
    var
        Holder: Record "ALT TableFilter Holder";
        Row: Record "FMT Blank Filter Row";
    begin
        Initialize();
        Row.Code := '';
        Row.Insert(false);
        Row.Init();
        Row.Code := 'NEUTRAL42';
        Row.Insert(false);
        Evaluate(Holder."Filter Value", 'FMT Blank Filter Row: Code=<>''''');
        AssertFilteredRow(Format(Holder."Filter Value"), 'NEUTRAL42');
    end;

    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
        Row: Record "FMT Blank Filter Row";
    begin
        Cleanup.Initialize(); InitializeCaptionCodeRows();
        Row.DeleteAll(false);
    end;

    local procedure AssertFilteredRow(Value: Text; ExpectedCode: Code[20])
    var
        Row: Record "FMT Blank Filter Row";
        Fields: Record "Table Filter" temporary;
        FilterPage: Page "Table Filter";
        Ref: RecordRef;
        Fld: FieldRef;
    begin
        FilterPage.SetSourceTable(Format(Value), Database::"FMT Blank Filter Row", Row.TableCaption());
        FilterPage.GetFilterFieldsList(Fields);
        Ref.Open(Database::"FMT Blank Filter Row");
        if Fields.FindSet() then
            repeat
                Fld := Ref.Field(Fields."Field Number");
                Fld.SetFilter(Fields."Field Filter");
            until Fields.Next() = 0;
        if Ref.Count() <> 1 then
            Error('Expected exactly one filtered row; actual %1; filter %2.', Ref.Count(), Format(Value));
        if not Ref.FindFirst() then
            Error('Expected the selected row.');
        Fld := Ref.Field(Row.FieldNo(Code));
        if Format(Fld.Value()) <> ExpectedCode then
            Error('Expected selected code %1, actual %2.', ExpectedCode, Format(Fld.Value()));
        Ref.Close();
    end;


    // BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
    // Fixtures: ALT TableFilter Holder, FMT Caption Filter Row, FMT Blank Service Row; BC 27.5+.
    [Test]
    procedure TableFilter_Evaluate_CaptionClassFieldName_SelectsPricedRow()
    var
        Resolver: Codeunit "FMT Filter Caption Resolver";
    begin
        Initialize();
        BindSubscription(Resolver);
        SeedCaptionFilterRows();
        CheckCaptionTableFilter('Nominal Price=>=40', 'PRICE42');
        UnbindSubscription(Resolver);
    end;

    [Test]
    procedure TableFilter_Evaluate_ResolvedCaptionClass_SelectsPricedRow()
    var
        Resolver: Codeunit "FMT Filter Caption Resolver";
    begin
        Initialize();
        BindSubscription(Resolver);
        SeedCaptionFilterRows();
        CheckCaptionTableFilter('Displayed Price=>=40', 'PRICE42');
        UnbindSubscription(Resolver);
    end;

    [Test]
    procedure TableFilter_Evaluate_CodeBesideCaptionClass_SelectsNamedRow()
    var
        Resolver: Codeunit "FMT Filter Caption Resolver";
    begin
        Initialize();
        BindSubscription(Resolver);
        SeedCaptionFilterRows();
        CheckCaptionTableFilter('Code=PRICE42', 'PRICE42');
        UnbindSubscription(Resolver);
    end;

    [Test]
    procedure TableFilter_Evaluate_QuotedBlankCode10_SelectsBlankService()
    begin
        Initialize();
        SeedBlankServiceRows();
        CheckServiceTableFilter('Service Type=''''', 'BLANK42', 2);
    end;

    [Test]
    procedure TableFilter_Evaluate_CompoundQuotedBlankCode10_SelectsBlankService()
    begin
        Initialize();
        SeedBlankServiceRows();
        CheckServiceTableFilter('Batch=KEEP,Service Type=''''', 'BLANK42', 1);
    end;

    local procedure InitializeCaptionCodeRows()
    var
        CaptionRows: Record "FMT Caption Filter Row";
        ServiceRows: Record "FMT Blank Service Row";
    begin
        CaptionRows.DeleteAll(false);
        ServiceRows.DeleteAll(false);
    end;

    local procedure SeedCaptionFilterRows()
    var
        Row: Record "FMT Caption Filter Row";
    begin
        // Precondition: the public caption API resolves the test's manually bound area.
        if Row.FieldCaption("Nominal Price") <> 'Displayed Price' then
            Error('Expected the manually resolved Displayed Price caption.');
        Row.Code := 'PRICE42';
        Row."Nominal Price" := 42.5;
        Row.Insert(false);
        Row.Code := 'PRICE17';
        Row."Nominal Price" := 17.5;
        Row.Insert(false);
    end;

    local procedure SeedBlankServiceRows()
    var
        Row: Record "FMT Blank Service Row";
    begin
        Row.Code := 'BLANK42';
        Row.Batch := 'KEEP';
        Row.Insert(false);
        Row.Code := 'FILLED42';
        Row."Service Type" := 'REPAIR';
        Row.Insert(false);
        Row.Code := 'OTHER42';
        Row."Service Type" := '';
        Row.Batch := 'DROP';
        Row.Insert(false);
    end;

    local procedure CheckCaptionTableFilter(Condition: Text; ExpectedCode: Code[20])
    var
        Holder: Record "ALT TableFilter Holder";
        Row: Record "FMT Caption Filter Row";
    begin
        Evaluate(Holder."Filter Value", 'FMT Caption Filter Row: ' + Condition);
        CheckSelectedTableFilter(Format(Holder."Filter Value"), Database::"FMT Caption Filter Row", Row.TableCaption(), ExpectedCode, 1);
    end;

    local procedure CheckServiceTableFilter(Condition: Text; ExpectedCode: Code[20]; ExpectedCount: Integer)
    var
        Holder: Record "ALT TableFilter Holder";
        Row: Record "FMT Blank Service Row";
    begin
        Evaluate(Holder."Filter Value", 'FMT Blank Service Row: ' + Condition);
        CheckSelectedTableFilter(Format(Holder."Filter Value"), Database::"FMT Blank Service Row", Row.TableCaption(), ExpectedCode, ExpectedCount);
    end;

    local procedure CheckSelectedTableFilter(Value: Text; TableNo: Integer; TableCaption: Text; ExpectedCode: Code[20]; ExpectedCount: Integer)
    var
        Fields: Record "Table Filter" temporary;
        FilterPage: Page "Table Filter";
        Ref: RecordRef;
        Fld: FieldRef;
    begin
        FilterPage.SetSourceTable(Value, TableNo, TableCaption);
        FilterPage.GetFilterFieldsList(Fields);
        Ref.Open(TableNo);
        if Fields.FindSet() then
            repeat
                Fld := Ref.Field(Fields."Field Number");
                Fld.SetFilter(Fields."Field Filter");
            until Fields.Next() = 0;
        if Ref.Count() <> ExpectedCount then
            Error('Expected %1 selected rows, actual %2.', ExpectedCount, Ref.Count());
        if not Ref.FindFirst() then
            Error('Expected the selected row.');
        Fld := Ref.Field(1);
        if Format(Fld.Value()) <> ExpectedCode then
            Error('Expected selected code %1, actual %2.', ExpectedCode, Format(Fld.Value()));
        Ref.Close();
    end;

}
