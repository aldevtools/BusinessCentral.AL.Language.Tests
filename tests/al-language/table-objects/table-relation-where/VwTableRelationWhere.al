// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope (Cloud)
// local object: the TableRelation property of the field is what is under test, so each case needs its own field; tables and codeunit are only for this matrix
// Fixtures used: Probe Observer (codeunit 69160), table "VW Row" / enum "VW Kind" are not used here; own objects in 96600..96699 (tables 96602..96605, enum "VW Kind" 96600 is declared in pages/view-properties/VwPageViews.al)
// BC versions: 27, 28, 29
// Area matrix (al-runner issues 7365, 7438, 7454, 7459): the where() conditions and if() conditions of a TableRelation, crossed with the value
//   forms of a filter (const(''), filter(''), filter(equals-empty-text), <> '', const(Database::T), filter(Database::T), enum member plain, type-qualified
//   "VW Kind"::Item, field-qualified Kind::Item, <>, |, quoted member, several where() conditions) and the field type of the compared field
//   (Code, Text, Integer, Enum, Date, Boolean, Option, Decimal). Each case sets the fields the relation depends on, validates the relation field
//   with a value that exists in the related table, with one that is filtered out and with one that does not exist, and observes ok / the error text
//   and code. The lookup cases open the relation through a TestPage and observe which list page the lookup shows and the rows on it.
//   Master rows (No. / kind / valid to / blocked / table no. / region / text / option / decimal):
//   M1 Item 0D false 96604 '' '' A 0 | M2 Resource 2026-01-01 true 96604 EU 'T' B 5 | M3 Item 0D true 1 EU '' A 0 | M4 Fixed Asset 0D false 96604 EU '' C 0
//   | M5 Item 2026-02-01 false 96604 EU '' A 0.   Other rows: O1, M1.   Num rows: 1 (Item), 2 (Resource), 3 (Item).

table 96602 "VW Master"
{
    DataClassification = SystemMetadata;
    LookupPageId = "VW Master List";

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Kind; Enum "VW Kind") { }
        field(3; "Valid To"; Date) { }
        field(4; Blocked; Boolean) { }
        field(5; "Table No."; Integer) { }
        field(6; Region; Code[10]) { }
        field(7; Txt; Text[20]) { }
        field(8; Opt; Option) { OptionMembers = A,B,C; }
        field(9; Dec; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 96603 "VW Other"
{
    DataClassification = SystemMetadata;
    LookupPageId = "VW Other List";

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 96605 "VW Num"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "VW Kind") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 96691 "VW Master List"
{
    PageType = List;
    SourceTable = "VW Master";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }
}

page 96692 "VW Other List"
{
    PageType = List;
    SourceTable = "VW Other";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
            }
        }
    }
}

table 96604 "VW Rel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; SourceType; Integer) { }
        field(3; KindSel; Enum "VW Kind") { }
        field(4; CdSel; Code[20]) { }
        field(5; DtSel; Date) { }
        field(6; Region; Code[10]) { }
        field(7; BlSel; Boolean) { }
        field(10; DateEqualsBlank; Code[20]) { TableRelation = "VW Master"."No." where("Valid To" = filter('=''''')); }
        field(11; DateFilterBlank; Code[20]) { TableRelation = "VW Master"."No." where("Valid To" = filter('')); }
        field(12; DateFilterNotBlank; Code[20]) { TableRelation = "VW Master"."No." where("Valid To" = filter(<> '')); }
        field(13; BoolConstFalse; Code[20]) { TableRelation = "VW Master"."No." where(Blocked = const(false)); }
        field(14; BoolConstTrue; Code[20]) { TableRelation = "VW Master"."No." where(Blocked = const(true)); }
        field(15; EnumConst; Code[20]) { TableRelation = "VW Master"."No." where(Kind = const(Item)); }
        field(16; EnumFilter; Code[20]) { TableRelation = "VW Master"."No." where(Kind = filter(Item)); }
        field(17; EnumFilterTypeQualified; Code[20]) { TableRelation = "VW Master"."No." where(Kind = filter("VW Kind"::Item)); }
        field(18; EnumFilterFieldQualified; Code[20]) { TableRelation = "VW Master"."No." where(Kind = filter(KindSel::Item)); }
        field(19; EnumFilterNotTypeQualified; Code[20]) { TableRelation = "VW Master"."No." where(Kind = filter(<> "VW Kind"::Item)); }
        field(20; EnumFilterNotFieldQualified; Code[20]) { TableRelation = "VW Master"."No." where(Kind = filter(<> KindSel::Item)); }
        field(21; EnumFilterOr; Code[20]) { TableRelation = "VW Master"."No." where(Kind = filter(Item | Resource)); }
        field(22; EnumConstQuotedMember; Code[20]) { TableRelation = "VW Master"."No." where(Kind = const("Fixed Asset")); }
        field(23; DatabaseConst; Code[20]) { TableRelation = "VW Master"."No." where("Table No." = const(Database::"VW Rel")); }
        field(24; DatabaseFilter; Code[20]) { TableRelation = "VW Master"."No." where("Table No." = filter(Database::"VW Rel")); }
        field(25; DatabaseFilterNot; Code[20]) { TableRelation = "VW Master"."No." where("Table No." = filter(<> Database::"VW Rel")); }
        field(26; CodeConstBlank; Code[20]) { TableRelation = "VW Master"."No." where(Region = const('')); }
        field(27; CodeField; Code[20]) { TableRelation = "VW Master"."No." where(Region = field(Region)); }
        field(28; TextConstBlank; Code[20]) { TableRelation = "VW Master"."No." where(Txt = const('')); }
        field(29; OptionConst; Code[20]) { TableRelation = "VW Master"."No." where(Opt = const(B)); }
        field(30; DecimalFilterPositive; Code[20]) { TableRelation = "VW Master"."No." where(Dec = filter(> 0)); }
        field(31; SeveralConditions; Code[20]) { TableRelation = "VW Master"."No." where(Blocked = const(false), Kind = const(Item), Region = field(Region)); }
        field(32; SeveralConditionsDatabase; Code[20]) { TableRelation = "VW Master"."No." where("Table No." = const(Database::"VW Rel"), "Valid To" = filter('='''''), Blocked = const(false)); }
        field(33; TextHolder; Text[20]) { TableRelation = "VW Master"."No." where(Blocked = const(false)); }
        field(34; IfDatabaseConst; Code[20]) { TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." else if (SourceType = const(Database::"VW Other")) "VW Other".Code; }
        field(35; IfDatabaseConstWhere; Code[20]) { TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Kind = field(KindSel)); }
        field(36; IfDatabaseFilter; Code[20]) { TableRelation = if (SourceType = filter(Database::"VW Master" | Database::"VW Other")) "VW Other".Code; }
        field(37; IfEnumConst; Code[20]) { TableRelation = if (KindSel = const(Item)) "VW Master"."No." else if (KindSel = const(Resource)) "VW Other".Code; }
        field(38; IfEnumFilterOr; Code[20]) { TableRelation = if (KindSel = filter(Item | Resource)) "VW Master"."No."; }
        field(39; IfEnumFilterNot; Code[20]) { TableRelation = if (KindSel = filter(<> Item)) "VW Master"."No."; }
        field(40; IfEnumFilterTypeQualified; Code[20]) { TableRelation = if (KindSel = filter("VW Kind"::Item)) "VW Master"."No."; }
        field(41; IfEnumFilterFieldQualified; Code[20]) { TableRelation = if (KindSel = filter(KindSel::Item)) "VW Master"."No."; }
        field(42; IfCodeConstBlank; Code[20]) { TableRelation = if (CdSel = const('')) "VW Master"."No." else if (CdSel = filter(<> '')) "VW Other".Code; }
        field(43; IfCodeFilterBlank; Code[20]) { TableRelation = if (CdSel = filter('')) "VW Master"."No."; }
        field(44; IfDateEqualsBlank; Code[20]) { TableRelation = if (DtSel = filter('=''''')) "VW Master"."No." else "VW Other".Code; }
        field(45; IfBoolConst; Code[20]) { TableRelation = if (BlSel = const(true)) "VW Master"."No." else "VW Other".Code; }
        field(46; IfWhereSeveral; Code[20]) { TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Blocked = const(false), Kind = field(KindSel)) else if (SourceType = const(Database::"VW Other")) "VW Other".Code; }
        field(47; IntHolder; Integer) { TableRelation = "VW Num".Id where(Kind = filter("VW Kind"::Item)); }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 96693 "VW Rel Card"
{
    PageType = Card;
    SourceTable = "VW Rel";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(DateEqualsBlank; Rec.DateEqualsBlank) { ApplicationArea = All; }
            field(DateFilterBlank; Rec.DateFilterBlank) { ApplicationArea = All; }
            field(DateFilterNotBlank; Rec.DateFilterNotBlank) { ApplicationArea = All; }
            field(BoolConstFalse; Rec.BoolConstFalse) { ApplicationArea = All; }
            field(BoolConstTrue; Rec.BoolConstTrue) { ApplicationArea = All; }
            field(EnumConst; Rec.EnumConst) { ApplicationArea = All; }
            field(EnumFilter; Rec.EnumFilter) { ApplicationArea = All; }
            field(EnumFilterTypeQualified; Rec.EnumFilterTypeQualified) { ApplicationArea = All; }
            field(EnumFilterFieldQualified; Rec.EnumFilterFieldQualified) { ApplicationArea = All; }
            field(EnumFilterNotTypeQualified; Rec.EnumFilterNotTypeQualified) { ApplicationArea = All; }
            field(EnumFilterNotFieldQualified; Rec.EnumFilterNotFieldQualified) { ApplicationArea = All; }
            field(EnumFilterOr; Rec.EnumFilterOr) { ApplicationArea = All; }
            field(EnumConstQuotedMember; Rec.EnumConstQuotedMember) { ApplicationArea = All; }
            field(DatabaseConst; Rec.DatabaseConst) { ApplicationArea = All; }
            field(DatabaseFilter; Rec.DatabaseFilter) { ApplicationArea = All; }
            field(DatabaseFilterNot; Rec.DatabaseFilterNot) { ApplicationArea = All; }
            field(CodeConstBlank; Rec.CodeConstBlank) { ApplicationArea = All; }
            field(CodeField; Rec.CodeField) { ApplicationArea = All; }
            field(TextConstBlank; Rec.TextConstBlank) { ApplicationArea = All; }
            field(OptionConst; Rec.OptionConst) { ApplicationArea = All; }
            field(DecimalFilterPositive; Rec.DecimalFilterPositive) { ApplicationArea = All; }
            field(SeveralConditions; Rec.SeveralConditions) { ApplicationArea = All; }
            field(SeveralConditionsDatabase; Rec.SeveralConditionsDatabase) { ApplicationArea = All; }
            field(TextHolder; Rec.TextHolder) { ApplicationArea = All; }
            field(IfDatabaseConst; Rec.IfDatabaseConst) { ApplicationArea = All; }
            field(IfDatabaseConstWhere; Rec.IfDatabaseConstWhere) { ApplicationArea = All; }
            field(IfDatabaseFilter; Rec.IfDatabaseFilter) { ApplicationArea = All; }
            field(IfEnumConst; Rec.IfEnumConst) { ApplicationArea = All; }
            field(IfEnumFilterOr; Rec.IfEnumFilterOr) { ApplicationArea = All; }
            field(IfEnumFilterNot; Rec.IfEnumFilterNot) { ApplicationArea = All; }
            field(IfEnumFilterTypeQualified; Rec.IfEnumFilterTypeQualified) { ApplicationArea = All; }
            field(IfEnumFilterFieldQualified; Rec.IfEnumFilterFieldQualified) { ApplicationArea = All; }
            field(IfCodeConstBlank; Rec.IfCodeConstBlank) { ApplicationArea = All; }
            field(IfCodeFilterBlank; Rec.IfCodeFilterBlank) { ApplicationArea = All; }
            field(IfDateEqualsBlank; Rec.IfDateEqualsBlank) { ApplicationArea = All; }
            field(IfBoolConst; Rec.IfBoolConst) { ApplicationArea = All; }
            field(IfWhereSeveral; Rec.IfWhereSeveral) { ApplicationArea = All; }
            field(IntHolder; Rec.IntHolder) { ApplicationArea = All; }
        }
    }
}

codeunit 96606 "VW Table Relation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Capture: Codeunit "VW Capture";
        HandlerNote: Text;

    local procedure Initialize()
    var
        Master: Record "VW Master";
        Other: Record "VW Other";
        Num: Record "VW Num";
        Rel: Record "VW Rel";
    begin
        Master.DeleteAll();
        Other.DeleteAll();
        Num.DeleteAll();
        Rel.DeleteAll();
        InsertMaster('M1', "VW Kind"::Item, 0D, false, 96604, '', '', 0, 0);
        InsertMaster('M2', "VW Kind"::Resource, DMY2Date(1, 1, 2026), true, 96604, 'EU', 'T', 1, 5);
        InsertMaster('M3', "VW Kind"::Item, 0D, true, 1, 'EU', '', 0, 0);
        InsertMaster('M4', "VW Kind"::"Fixed Asset", 0D, false, 96604, 'EU', '', 2, 0);
        InsertMaster('M5', "VW Kind"::Item, DMY2Date(1, 2, 2026), false, 96604, 'EU', '', 0, 0);
        Other.Code := 'O1';
        Other.Insert();
        Other.Code := 'M1';
        Other.Insert();
        InsertNum(1, "VW Kind"::Item);
        InsertNum(2, "VW Kind"::Resource);
        InsertNum(3, "VW Kind"::Item);
        Capture.Reset();
        HandlerNote := '';
    end;

    local procedure InsertMaster(No: Code[20]; KindValue: Enum "VW Kind"; ValidTo: Date; IsBlocked: Boolean; TableNo: Integer; RegionCode: Code[10]; TextValue: Text[20]; OptionValue: Integer; DecimalValue: Decimal)
    var
        Master: Record "VW Master";
    begin
        Master."No." := No;
        Master.Kind := KindValue;
        Master."Valid To" := ValidTo;
        Master.Blocked := IsBlocked;
        Master."Table No." := TableNo;
        Master.Region := RegionCode;
        Master.Txt := TextValue;
        Master.Opt := OptionValue;
        Master.Dec := DecimalValue;
        Master.Insert();
    end;

    local procedure InsertNum(Id: Integer; KindValue: Enum "VW Kind")
    var
        Num: Record "VW Num";
    begin
        Num.Id := Id;
        Num.Kind := KindValue;
        Num.Insert();
    end;

    [TryFunction]
    local procedure TryValidate(var FieldRefToCheck: FieldRef; Value: Text)
    begin
        FieldRefToCheck.Validate(Value);
    end;

    local procedure CheckAll(var Observer: Codeunit "Probe Observer"; var Rel: Record "VW Rel"; FieldNo: Integer; Prefix: Text)
    var
        RecRef: RecordRef;
        FieldRefToCheck: FieldRef;
        Value: Text;
        Values: List of [Text];
        Outcome: Text;
    begin
        Values.Add('M1');
        Values.Add('M2');
        Values.Add('M3');
        Values.Add('M4');
        Values.Add('M5');
        Values.Add('O1');
        Values.Add('NOPE');
        Values.Add('');
        foreach Value in Values do begin
            RecRef.GetTable(Rel);
            FieldRefToCheck := RecRef.Field(FieldNo);
            if TryValidate(FieldRefToCheck, Value) then
                Observer.Observe(Prefix + '|' + Value, 'ok:' + Format(FieldRefToCheck.Value()))
            else begin
                Observer.Observe(Prefix + '|' + Value, 'error');
                Observer.ObserveError(Prefix + '|' + Value);
            end;
        end;
    end;

    // CLAIM: Validate of DateEqualsBlank (TableRelation = "VW Master"."No." where("Valid To" = filter('='''''))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_DateEqualsBlank_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(DateEqualsBlank), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of DateFilterBlank (TableRelation = "VW Master"."No." where("Valid To" = filter(''))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_DateFilterBlank_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(DateFilterBlank), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of DateFilterNotBlank (TableRelation = "VW Master"."No." where("Valid To" = filter(<> ''))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_DateFilterNotBlank_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(DateFilterNotBlank), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of BoolConstFalse (TableRelation = "VW Master"."No." where(Blocked = const(false))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_BoolConstFalse_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(BoolConstFalse), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of BoolConstTrue (TableRelation = "VW Master"."No." where(Blocked = const(true))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_BoolConstTrue_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(BoolConstTrue), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of EnumConst (TableRelation = "VW Master"."No." where(Kind = const(Item))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_EnumConst_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(EnumConst), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of EnumFilter (TableRelation = "VW Master"."No." where(Kind = filter(Item))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_EnumFilter_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(EnumFilter), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of EnumFilterTypeQualified (TableRelation = "VW Master"."No." where(Kind = filter("VW Kind"::Item))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_EnumFilterTypeQualified_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(EnumFilterTypeQualified), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of EnumFilterFieldQualified (TableRelation = "VW Master"."No." where(Kind = filter(Kind::Item))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_EnumFilterFieldQualified_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(EnumFilterFieldQualified), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of EnumFilterNotTypeQualified (TableRelation = "VW Master"."No." where(Kind = filter(<> "VW Kind"::Item))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_EnumFilterNotTypeQualified_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(EnumFilterNotTypeQualified), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of EnumFilterNotFieldQualified (TableRelation = "VW Master"."No." where(Kind = filter(<> Kind::Item))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_EnumFilterNotFieldQualified_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(EnumFilterNotFieldQualified), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of EnumFilterOr (TableRelation = "VW Master"."No." where(Kind = filter(Item | Resource))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_EnumFilterOr_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(EnumFilterOr), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of EnumConstQuotedMember (TableRelation = "VW Master"."No." where(Kind = const("Fixed Asset"))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_EnumConstQuotedMember_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(EnumConstQuotedMember), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of DatabaseConst (TableRelation = "VW Master"."No." where("Table No." = const(Database::"VW Rel"))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_DatabaseConst_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(DatabaseConst), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of DatabaseFilter (TableRelation = "VW Master"."No." where("Table No." = filter(Database::"VW Rel"))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_DatabaseFilter_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(DatabaseFilter), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of DatabaseFilterNot (TableRelation = "VW Master"."No." where("Table No." = filter(<> Database::"VW Rel"))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_DatabaseFilterNot_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(DatabaseFilterNot), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of CodeConstBlank (TableRelation = "VW Master"."No." where(Region = const(''))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_CodeConstBlank_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(CodeConstBlank), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of CodeField (TableRelation = "VW Master"."No." where(Region = field(Region))) behaves as recorded below (setup: RegionBlank).
    [Test]
    procedure Validate_CodeField_RegionBlank()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(CodeField), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of CodeField (TableRelation = "VW Master"."No." where(Region = field(Region))) behaves as recorded below (setup: RegionEU).
    [Test]
    procedure Validate_CodeField_RegionEU()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Region := 'EU';
        CheckAll(Observer, Rel, Rel.FieldNo(CodeField), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of TextConstBlank (TableRelation = "VW Master"."No." where(Txt = const(''))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_TextConstBlank_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(TextConstBlank), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of OptionConst (TableRelation = "VW Master"."No." where(Opt = const(B))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_OptionConst_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(OptionConst), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of DecimalFilterPositive (TableRelation = "VW Master"."No." where(Dec = filter(> 0))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_DecimalFilterPositive_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(DecimalFilterPositive), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of SeveralConditions (TableRelation = "VW Master"."No." where(Blocked = const(false), Kind = const(Item), Region = field(Region))) behaves as recorded below (setup: RegionBlank).
    [Test]
    procedure Validate_SeveralConditions_RegionBlank()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(SeveralConditions), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of SeveralConditions (TableRelation = "VW Master"."No." where(Blocked = const(false), Kind = const(Item), Region = field(Region))) behaves as recorded below (setup: RegionEU).
    [Test]
    procedure Validate_SeveralConditions_RegionEU()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Region := 'EU';
        CheckAll(Observer, Rel, Rel.FieldNo(SeveralConditions), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of SeveralConditionsDatabase (TableRelation = "VW Master"."No." where("Table No." = const(Database::"VW Rel"), "Valid To" = filter('='''''), Blocked = const(false))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_SeveralConditionsDatabase_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(SeveralConditionsDatabase), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of TextHolder (TableRelation = "VW Master"."No." where(Blocked = const(false))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_TextHolder_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(TextHolder), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDatabaseConst (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." else if (SourceType = const(Database::"VW Other")) "VW Other".Code) behaves as recorded below (setup: TableMaster).
    [Test]
    procedure Validate_IfDatabaseConst_TableMaster()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Master";
        CheckAll(Observer, Rel, Rel.FieldNo(IfDatabaseConst), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDatabaseConst (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." else if (SourceType = const(Database::"VW Other")) "VW Other".Code) behaves as recorded below (setup: TableOther).
    [Test]
    procedure Validate_IfDatabaseConst_TableOther()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Other";
        CheckAll(Observer, Rel, Rel.FieldNo(IfDatabaseConst), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDatabaseConst (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." else if (SourceType = const(Database::"VW Other")) "VW Other".Code) behaves as recorded below (setup: TableZero).
    [Test]
    procedure Validate_IfDatabaseConst_TableZero()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := 0;
        CheckAll(Observer, Rel, Rel.FieldNo(IfDatabaseConst), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDatabaseConstWhere (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Kind = field(KindSel))) behaves as recorded below (setup: TableMasterKindItem).
    [Test]
    procedure Validate_IfDatabaseConstWhere_TableMasterKindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Master";
        Rel.KindSel := "VW Kind"::Item;
        CheckAll(Observer, Rel, Rel.FieldNo(IfDatabaseConstWhere), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDatabaseConstWhere (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Kind = field(KindSel))) behaves as recorded below (setup: TableMasterKindResource).
    [Test]
    procedure Validate_IfDatabaseConstWhere_TableMasterKindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Master";
        Rel.KindSel := "VW Kind"::Resource;
        CheckAll(Observer, Rel, Rel.FieldNo(IfDatabaseConstWhere), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDatabaseConstWhere (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Kind = field(KindSel))) behaves as recorded below (setup: TableOtherKindItem).
    [Test]
    procedure Validate_IfDatabaseConstWhere_TableOtherKindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Other";
        Rel.KindSel := "VW Kind"::Item;
        CheckAll(Observer, Rel, Rel.FieldNo(IfDatabaseConstWhere), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDatabaseConstWhere (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Kind = field(KindSel))) behaves as recorded below (setup: TableOtherKindResource).
    [Test]
    procedure Validate_IfDatabaseConstWhere_TableOtherKindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Other";
        Rel.KindSel := "VW Kind"::Resource;
        CheckAll(Observer, Rel, Rel.FieldNo(IfDatabaseConstWhere), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDatabaseFilter (TableRelation = if (SourceType = filter(Database::"VW Master" | Database::"VW Other")) "VW Other".Code) behaves as recorded below (setup: TableMaster).
    [Test]
    procedure Validate_IfDatabaseFilter_TableMaster()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Master";
        CheckAll(Observer, Rel, Rel.FieldNo(IfDatabaseFilter), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDatabaseFilter (TableRelation = if (SourceType = filter(Database::"VW Master" | Database::"VW Other")) "VW Other".Code) behaves as recorded below (setup: TableOther).
    [Test]
    procedure Validate_IfDatabaseFilter_TableOther()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Other";
        CheckAll(Observer, Rel, Rel.FieldNo(IfDatabaseFilter), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDatabaseFilter (TableRelation = if (SourceType = filter(Database::"VW Master" | Database::"VW Other")) "VW Other".Code) behaves as recorded below (setup: TableZero).
    [Test]
    procedure Validate_IfDatabaseFilter_TableZero()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := 0;
        CheckAll(Observer, Rel, Rel.FieldNo(IfDatabaseFilter), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumConst (TableRelation = if (KindSel = const(Item)) "VW Master"."No." else if (KindSel = const(Resource)) "VW Other".Code) behaves as recorded below (setup: KindItem).
    [Test]
    procedure Validate_IfEnumConst_KindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::Item;
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumConst), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumConst (TableRelation = if (KindSel = const(Item)) "VW Master"."No." else if (KindSel = const(Resource)) "VW Other".Code) behaves as recorded below (setup: KindResource).
    [Test]
    procedure Validate_IfEnumConst_KindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::Resource;
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumConst), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumConst (TableRelation = if (KindSel = const(Item)) "VW Master"."No." else if (KindSel = const(Resource)) "VW Other".Code) behaves as recorded below (setup: KindFixedAsset).
    [Test]
    procedure Validate_IfEnumConst_KindFixedAsset()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::"Fixed Asset";
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumConst), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterOr (TableRelation = if (KindSel = filter(Item | Resource)) "VW Master"."No.") behaves as recorded below (setup: KindItem).
    [Test]
    procedure Validate_IfEnumFilterOr_KindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::Item;
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterOr), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterOr (TableRelation = if (KindSel = filter(Item | Resource)) "VW Master"."No.") behaves as recorded below (setup: KindResource).
    [Test]
    procedure Validate_IfEnumFilterOr_KindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::Resource;
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterOr), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterOr (TableRelation = if (KindSel = filter(Item | Resource)) "VW Master"."No.") behaves as recorded below (setup: KindFixedAsset).
    [Test]
    procedure Validate_IfEnumFilterOr_KindFixedAsset()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::"Fixed Asset";
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterOr), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterNot (TableRelation = if (KindSel = filter(<> Item)) "VW Master"."No.") behaves as recorded below (setup: KindItem).
    [Test]
    procedure Validate_IfEnumFilterNot_KindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::Item;
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterNot), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterNot (TableRelation = if (KindSel = filter(<> Item)) "VW Master"."No.") behaves as recorded below (setup: KindResource).
    [Test]
    procedure Validate_IfEnumFilterNot_KindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::Resource;
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterNot), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterNot (TableRelation = if (KindSel = filter(<> Item)) "VW Master"."No.") behaves as recorded below (setup: KindFixedAsset).
    [Test]
    procedure Validate_IfEnumFilterNot_KindFixedAsset()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::"Fixed Asset";
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterNot), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterTypeQualified (TableRelation = if (KindSel = filter("VW Kind"::Item)) "VW Master"."No.") behaves as recorded below (setup: KindItem).
    [Test]
    procedure Validate_IfEnumFilterTypeQualified_KindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::Item;
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterTypeQualified), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterTypeQualified (TableRelation = if (KindSel = filter("VW Kind"::Item)) "VW Master"."No.") behaves as recorded below (setup: KindResource).
    [Test]
    procedure Validate_IfEnumFilterTypeQualified_KindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::Resource;
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterTypeQualified), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterTypeQualified (TableRelation = if (KindSel = filter("VW Kind"::Item)) "VW Master"."No.") behaves as recorded below (setup: KindFixedAsset).
    [Test]
    procedure Validate_IfEnumFilterTypeQualified_KindFixedAsset()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::"Fixed Asset";
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterTypeQualified), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterFieldQualified (TableRelation = if (KindSel = filter(KindSel::Item)) "VW Master"."No.") behaves as recorded below (setup: KindItem).
    [Test]
    procedure Validate_IfEnumFilterFieldQualified_KindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::Item;
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterFieldQualified), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterFieldQualified (TableRelation = if (KindSel = filter(KindSel::Item)) "VW Master"."No.") behaves as recorded below (setup: KindResource).
    [Test]
    procedure Validate_IfEnumFilterFieldQualified_KindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::Resource;
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterFieldQualified), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfEnumFilterFieldQualified (TableRelation = if (KindSel = filter(KindSel::Item)) "VW Master"."No.") behaves as recorded below (setup: KindFixedAsset).
    [Test]
    procedure Validate_IfEnumFilterFieldQualified_KindFixedAsset()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.KindSel := "VW Kind"::"Fixed Asset";
        CheckAll(Observer, Rel, Rel.FieldNo(IfEnumFilterFieldQualified), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfCodeConstBlank (TableRelation = if (CdSel = const('')) "VW Master"."No." else if (CdSel = filter(<> '')) "VW Other".Code) behaves as recorded below (setup: CodeBlank).
    [Test]
    procedure Validate_IfCodeConstBlank_CodeBlank()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(IfCodeConstBlank), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfCodeConstBlank (TableRelation = if (CdSel = const('')) "VW Master"."No." else if (CdSel = filter(<> '')) "VW Other".Code) behaves as recorded below (setup: CodeX).
    [Test]
    procedure Validate_IfCodeConstBlank_CodeX()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.CdSel := 'X';
        CheckAll(Observer, Rel, Rel.FieldNo(IfCodeConstBlank), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfCodeFilterBlank (TableRelation = if (CdSel = filter('')) "VW Master"."No.") behaves as recorded below (setup: CodeBlank).
    [Test]
    procedure Validate_IfCodeFilterBlank_CodeBlank()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(IfCodeFilterBlank), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfCodeFilterBlank (TableRelation = if (CdSel = filter('')) "VW Master"."No.") behaves as recorded below (setup: CodeX).
    [Test]
    procedure Validate_IfCodeFilterBlank_CodeX()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.CdSel := 'X';
        CheckAll(Observer, Rel, Rel.FieldNo(IfCodeFilterBlank), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDateEqualsBlank (TableRelation = if (DtSel = filter('=''''')) "VW Master"."No." else "VW Other".Code) behaves as recorded below (setup: DateBlank).
    [Test]
    procedure Validate_IfDateEqualsBlank_DateBlank()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(IfDateEqualsBlank), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfDateEqualsBlank (TableRelation = if (DtSel = filter('=''''')) "VW Master"."No." else "VW Other".Code) behaves as recorded below (setup: DateSet).
    [Test]
    procedure Validate_IfDateEqualsBlank_DateSet()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.DtSel := DMY2Date(1, 1, 2026);
        CheckAll(Observer, Rel, Rel.FieldNo(IfDateEqualsBlank), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfBoolConst (TableRelation = if (BlSel = const(true)) "VW Master"."No." else "VW Other".Code) behaves as recorded below (setup: BoolFalse).
    [Test]
    procedure Validate_IfBoolConst_BoolFalse()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckAll(Observer, Rel, Rel.FieldNo(IfBoolConst), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfBoolConst (TableRelation = if (BlSel = const(true)) "VW Master"."No." else "VW Other".Code) behaves as recorded below (setup: BoolTrue).
    [Test]
    procedure Validate_IfBoolConst_BoolTrue()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.BlSel := true;
        CheckAll(Observer, Rel, Rel.FieldNo(IfBoolConst), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfWhereSeveral (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Blocked = const(false), Kind = field(KindSel)) else if (SourceType = const(Database::"VW Other")) "VW Other".Code) behaves as recorded below (setup: TableMasterKindItem).
    [Test]
    procedure Validate_IfWhereSeveral_TableMasterKindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Master";
        Rel.KindSel := "VW Kind"::Item;
        CheckAll(Observer, Rel, Rel.FieldNo(IfWhereSeveral), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfWhereSeveral (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Blocked = const(false), Kind = field(KindSel)) else if (SourceType = const(Database::"VW Other")) "VW Other".Code) behaves as recorded below (setup: TableMasterKindResource).
    [Test]
    procedure Validate_IfWhereSeveral_TableMasterKindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Master";
        Rel.KindSel := "VW Kind"::Resource;
        CheckAll(Observer, Rel, Rel.FieldNo(IfWhereSeveral), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfWhereSeveral (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Blocked = const(false), Kind = field(KindSel)) else if (SourceType = const(Database::"VW Other")) "VW Other".Code) behaves as recorded below (setup: TableOtherKindItem).
    [Test]
    procedure Validate_IfWhereSeveral_TableOtherKindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Other";
        Rel.KindSel := "VW Kind"::Item;
        CheckAll(Observer, Rel, Rel.FieldNo(IfWhereSeveral), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IfWhereSeveral (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Blocked = const(false), Kind = field(KindSel)) else if (SourceType = const(Database::"VW Other")) "VW Other".Code) behaves as recorded below (setup: TableOtherKindResource).
    [Test]
    procedure Validate_IfWhereSeveral_TableOtherKindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.SourceType := Database::"VW Other";
        Rel.KindSel := "VW Kind"::Resource;
        CheckAll(Observer, Rel, Rel.FieldNo(IfWhereSeveral), 'v');
        Observer.Finish();
    end;

    // CLAIM: Validate of IntHolder (TableRelation = "VW Num".Id where(Kind = filter("VW Kind"::Item))) behaves as recorded below (setup: NoSetup).
    [Test]
    procedure Validate_IntHolder_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        CheckIntegers(Observer, Rel);
        Observer.Finish();
    end;

    local procedure CheckIntegers(var Observer: Codeunit "Probe Observer"; var Rel: Record "VW Rel")
    var
        RecRef: RecordRef;
        FieldRefToCheck: FieldRef;
        Value: Text;
        Values: List of [Text];
    begin
        Values.Add('1');
        Values.Add('2');
        Values.Add('3');
        Values.Add('4');
        Values.Add('0');
        foreach Value in Values do begin
            RecRef.GetTable(Rel);
            FieldRefToCheck := RecRef.Field(Rel.FieldNo(IntHolder));
            if TryValidate(FieldRefToCheck, Value) then
                Observer.Observe('v|' + Value, 'ok:' + Format(FieldRefToCheck.Value()))
            else begin
                Observer.Observe('v|' + Value, 'error');
                Observer.ObserveError('v|' + Value);
            end;
        end;
    end;

    [TryFunction]
    local procedure TryLookup_DateEqualsBlank_NoSetup()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.DateEqualsBlank.Lookup();
    end;

    // CLAIM: Lookup of DateEqualsBlank (TableRelation = "VW Master"."No." where("Valid To" = filter('='''''))) shows the list page and the rows recorded below (setup: NoSetup).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_DateEqualsBlank_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.Insert();
        if TryLookup_DateEqualsBlank_NoSetup() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_BoolConstFalse_NoSetup()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.BoolConstFalse.Lookup();
    end;

    // CLAIM: Lookup of BoolConstFalse (TableRelation = "VW Master"."No." where(Blocked = const(false))) shows the list page and the rows recorded below (setup: NoSetup).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_BoolConstFalse_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.Insert();
        if TryLookup_BoolConstFalse_NoSetup() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_EnumConst_NoSetup()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.EnumConst.Lookup();
    end;

    // CLAIM: Lookup of EnumConst (TableRelation = "VW Master"."No." where(Kind = const(Item))) shows the list page and the rows recorded below (setup: NoSetup).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_EnumConst_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.Insert();
        if TryLookup_EnumConst_NoSetup() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_EnumFilterNotTypeQualified_NoSetup()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.EnumFilterNotTypeQualified.Lookup();
    end;

    // CLAIM: Lookup of EnumFilterNotTypeQualified (TableRelation = "VW Master"."No." where(Kind = filter(<> "VW Kind"::Item))) shows the list page and the rows recorded below (setup: NoSetup).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_EnumFilterNotTypeQualified_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.Insert();
        if TryLookup_EnumFilterNotTypeQualified_NoSetup() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_DatabaseConst_NoSetup()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.DatabaseConst.Lookup();
    end;

    // CLAIM: Lookup of DatabaseConst (TableRelation = "VW Master"."No." where("Table No." = const(Database::"VW Rel"))) shows the list page and the rows recorded below (setup: NoSetup).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_DatabaseConst_NoSetup()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.Insert();
        if TryLookup_DatabaseConst_NoSetup() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_SeveralConditions_RegionBlank()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.SeveralConditions.Lookup();
    end;

    // CLAIM: Lookup of SeveralConditions (TableRelation = "VW Master"."No." where(Blocked = const(false), Kind = const(Item), Region = field(Region))) shows the list page and the rows recorded below (setup: RegionBlank).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_SeveralConditions_RegionBlank()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.Insert();
        if TryLookup_SeveralConditions_RegionBlank() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_SeveralConditions_RegionEU()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.SeveralConditions.Lookup();
    end;

    // CLAIM: Lookup of SeveralConditions (TableRelation = "VW Master"."No." where(Blocked = const(false), Kind = const(Item), Region = field(Region))) shows the list page and the rows recorded below (setup: RegionEU).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_SeveralConditions_RegionEU()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.Region := 'EU';
        Rel.Insert();
        if TryLookup_SeveralConditions_RegionEU() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_CodeField_RegionBlank()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.CodeField.Lookup();
    end;

    // CLAIM: Lookup of CodeField (TableRelation = "VW Master"."No." where(Region = field(Region))) shows the list page and the rows recorded below (setup: RegionBlank).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_CodeField_RegionBlank()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.Insert();
        if TryLookup_CodeField_RegionBlank() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_CodeField_RegionEU()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.CodeField.Lookup();
    end;

    // CLAIM: Lookup of CodeField (TableRelation = "VW Master"."No." where(Region = field(Region))) shows the list page and the rows recorded below (setup: RegionEU).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_CodeField_RegionEU()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.Region := 'EU';
        Rel.Insert();
        if TryLookup_CodeField_RegionEU() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfDatabaseConst_TableMaster()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfDatabaseConst.Lookup();
    end;

    // CLAIM: Lookup of IfDatabaseConst (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." else if (SourceType = const(Database::"VW Other")) "VW Other".Code) shows the list page and the rows recorded below (setup: TableMaster).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfDatabaseConst_TableMaster()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.SourceType := Database::"VW Master";
        Rel.Insert();
        if TryLookup_IfDatabaseConst_TableMaster() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfDatabaseConst_TableOther()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfDatabaseConst.Lookup();
    end;

    // CLAIM: Lookup of IfDatabaseConst (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." else if (SourceType = const(Database::"VW Other")) "VW Other".Code) shows the list page and the rows recorded below (setup: TableOther).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfDatabaseConst_TableOther()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.SourceType := Database::"VW Other";
        Rel.Insert();
        if TryLookup_IfDatabaseConst_TableOther() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfDatabaseConst_TableZero()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfDatabaseConst.Lookup();
    end;

    // CLAIM: Lookup of IfDatabaseConst (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." else if (SourceType = const(Database::"VW Other")) "VW Other".Code) shows the list page and the rows recorded below (setup: TableZero).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfDatabaseConst_TableZero()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.SourceType := 0;
        Rel.Insert();
        if TryLookup_IfDatabaseConst_TableZero() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfDatabaseConstWhere_TableMasterKindItem()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfDatabaseConstWhere.Lookup();
    end;

    // CLAIM: Lookup of IfDatabaseConstWhere (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Kind = field(KindSel))) shows the list page and the rows recorded below (setup: TableMasterKindItem).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfDatabaseConstWhere_TableMasterKindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.SourceType := Database::"VW Master";
        Rel.KindSel := "VW Kind"::Item;
        Rel.Insert();
        if TryLookup_IfDatabaseConstWhere_TableMasterKindItem() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfDatabaseConstWhere_TableMasterKindResource()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfDatabaseConstWhere.Lookup();
    end;

    // CLAIM: Lookup of IfDatabaseConstWhere (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Kind = field(KindSel))) shows the list page and the rows recorded below (setup: TableMasterKindResource).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfDatabaseConstWhere_TableMasterKindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.SourceType := Database::"VW Master";
        Rel.KindSel := "VW Kind"::Resource;
        Rel.Insert();
        if TryLookup_IfDatabaseConstWhere_TableMasterKindResource() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfDatabaseConstWhere_TableOtherKindItem()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfDatabaseConstWhere.Lookup();
    end;

    // CLAIM: Lookup of IfDatabaseConstWhere (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Kind = field(KindSel))) shows the list page and the rows recorded below (setup: TableOtherKindItem).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfDatabaseConstWhere_TableOtherKindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.SourceType := Database::"VW Other";
        Rel.KindSel := "VW Kind"::Item;
        Rel.Insert();
        if TryLookup_IfDatabaseConstWhere_TableOtherKindItem() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfDatabaseConstWhere_TableOtherKindResource()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfDatabaseConstWhere.Lookup();
    end;

    // CLAIM: Lookup of IfDatabaseConstWhere (TableRelation = if (SourceType = const(Database::"VW Master")) "VW Master"."No." where(Kind = field(KindSel))) shows the list page and the rows recorded below (setup: TableOtherKindResource).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfDatabaseConstWhere_TableOtherKindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.SourceType := Database::"VW Other";
        Rel.KindSel := "VW Kind"::Resource;
        Rel.Insert();
        if TryLookup_IfDatabaseConstWhere_TableOtherKindResource() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfEnumConst_KindItem()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfEnumConst.Lookup();
    end;

    // CLAIM: Lookup of IfEnumConst (TableRelation = if (KindSel = const(Item)) "VW Master"."No." else if (KindSel = const(Resource)) "VW Other".Code) shows the list page and the rows recorded below (setup: KindItem).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfEnumConst_KindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.KindSel := "VW Kind"::Item;
        Rel.Insert();
        if TryLookup_IfEnumConst_KindItem() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfEnumConst_KindResource()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfEnumConst.Lookup();
    end;

    // CLAIM: Lookup of IfEnumConst (TableRelation = if (KindSel = const(Item)) "VW Master"."No." else if (KindSel = const(Resource)) "VW Other".Code) shows the list page and the rows recorded below (setup: KindResource).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfEnumConst_KindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.KindSel := "VW Kind"::Resource;
        Rel.Insert();
        if TryLookup_IfEnumConst_KindResource() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfEnumConst_KindFixedAsset()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfEnumConst.Lookup();
    end;

    // CLAIM: Lookup of IfEnumConst (TableRelation = if (KindSel = const(Item)) "VW Master"."No." else if (KindSel = const(Resource)) "VW Other".Code) shows the list page and the rows recorded below (setup: KindFixedAsset).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfEnumConst_KindFixedAsset()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.KindSel := "VW Kind"::"Fixed Asset";
        Rel.Insert();
        if TryLookup_IfEnumConst_KindFixedAsset() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfEnumFilterNot_KindItem()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfEnumFilterNot.Lookup();
    end;

    // CLAIM: Lookup of IfEnumFilterNot (TableRelation = if (KindSel = filter(<> Item)) "VW Master"."No.") shows the list page and the rows recorded below (setup: KindItem).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfEnumFilterNot_KindItem()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.KindSel := "VW Kind"::Item;
        Rel.Insert();
        if TryLookup_IfEnumFilterNot_KindItem() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfEnumFilterNot_KindResource()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfEnumFilterNot.Lookup();
    end;

    // CLAIM: Lookup of IfEnumFilterNot (TableRelation = if (KindSel = filter(<> Item)) "VW Master"."No.") shows the list page and the rows recorded below (setup: KindResource).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfEnumFilterNot_KindResource()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.KindSel := "VW Kind"::Resource;
        Rel.Insert();
        if TryLookup_IfEnumFilterNot_KindResource() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfEnumFilterNot_KindFixedAsset()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfEnumFilterNot.Lookup();
    end;

    // CLAIM: Lookup of IfEnumFilterNot (TableRelation = if (KindSel = filter(<> Item)) "VW Master"."No.") shows the list page and the rows recorded below (setup: KindFixedAsset).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfEnumFilterNot_KindFixedAsset()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.KindSel := "VW Kind"::"Fixed Asset";
        Rel.Insert();
        if TryLookup_IfEnumFilterNot_KindFixedAsset() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfCodeConstBlank_CodeBlank()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfCodeConstBlank.Lookup();
    end;

    // CLAIM: Lookup of IfCodeConstBlank (TableRelation = if (CdSel = const('')) "VW Master"."No." else if (CdSel = filter(<> '')) "VW Other".Code) shows the list page and the rows recorded below (setup: CodeBlank).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfCodeConstBlank_CodeBlank()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.Insert();
        if TryLookup_IfCodeConstBlank_CodeBlank() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLookup_IfCodeConstBlank_CodeX()
    var
        Card: TestPage "VW Rel Card";
    begin
        Card.OpenEdit();
        Card.IfCodeConstBlank.Lookup();
    end;

    // CLAIM: Lookup of IfCodeConstBlank (TableRelation = if (CdSel = const('')) "VW Master"."No." else if (CdSel = filter(<> '')) "VW Other".Code) shows the list page and the rows recorded below (setup: CodeX).
    [Test]
    [HandlerFunctions('MasterListHandler,OtherListHandler')]
    procedure Lookup_IfCodeConstBlank_CodeX()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "VW Rel";
    begin
        Initialize();

        Rel.Init();
        Rel.Id := 1;
        Rel.CdSel := 'X';
        Rel.Insert();
        if TryLookup_IfCodeConstBlank_CodeX() then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('handlers', HandlerNote);
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure MasterListHandler(var List: TestPage "VW Master List")
    var
        Rows: Text;
    begin
        if List.First() then
            repeat
                Rows += List."No.".Value() + ',';
            until not List.Next();
        HandlerNote += 'Master[' + Rows + ']';
        List.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure OtherListHandler(var List: TestPage "VW Other List")
    var
        Rows: Text;
    begin
        if List.First() then
            repeat
                Rows += List.Code.Value() + ',';
            until not List.Next();
        HandlerNote += 'Other[' + Rows + ']';
        List.Cancel().Invoke();
    end;
}
