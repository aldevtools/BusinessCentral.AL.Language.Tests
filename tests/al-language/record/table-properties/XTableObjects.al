// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-charallowed-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (issue 611): objects for the table and table extension field and table properties CharAllowed, DateFormula, MaskType, OptionCaptionML,
// SignDisplacement, SqlDataType, SqlTimestamp, Width, AllowInCustomizations, ColumnStoreIndex, LinkedObject, LinkedInTransaction, DataCaptionFields,
// DrillDownPageId and LookupPageId, and the modify() of BlankZero, CaptionClass, ClosingDates, MaskType, OptionCaption, OptionCaptionML and Width.
// modify() of MaskType compiles but BC refuses to publish it ("Modifications to property MaskType are not supported."), so it is not in this app.
// Object ids 75000-75019.
table 75000 "LT X Props"
{
    DataClassification = SystemMetadata;
    AllowInCustomizations = AsReadOnly;

    fields
    {
        field(1; Id; Integer) { AllowInCustomizations = Never; }
        field(2; Digits; Code[20]) { CharAllowed = '09'; }
        field(3; Picky; Text[20]) { CharAllowed = 'admpzz'; }
        field(4; DateText; Text[30]) { DateFormula = true; }
        field(5; Secret; Text[30]) { MaskType = Concealed; }
        field(6; Plain; Text[30]) { MaskType = None; }
        field(7; Op; Option)
        {
            OptionMembers = A,B,C;
            OptionCaptionML = ENU = 'Alpha,Beta,Gamma', DEU = 'Eins,Zwei,Drei';
        }
        field(8; Disp; Decimal) { SignDisplacement = 600; }
        field(9; Stamp; BigInteger) { SQLTimestamp = true; }
        field(10; Wide; Text[30]) { Width = 10; }
        field(11; Bz; Decimal) { BlankZero = true; }
        field(12; Closing; Date) { ClosingDates = true; }
        field(13; CapCls; Integer) { CaptionClass = 'LTX,Base'; }
        field(14; OptCap; Option)
        {
            OptionMembers = A,B,C;
            OptionCaption = 'One,Two,Three';
        }
        field(15; OptMl; Option)
        {
            OptionMembers = A,B,C;
            OptionCaptionML = ENU = 'Red,Green,Blue', DEU = 'Rot,Gruen,Blau';
        }
        field(16; Secret2; Text[30]) { MaskType = Concealed; }
        field(17; Wide2; Text[30]) { Width = 10; }
        field(18; Bz2; Decimal) { BlankZero = false; }
        field(19; Closing2; Date) { ClosingDates = false; }
        field(20; CapCls2; Integer) { CaptionClass = 'LTX,Literal'; }
        field(21; Rel; Integer) { TableRelation = "LT X Props".Id; }
        field(22; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT X Props");
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 75001 "LT X Props Ext" extends "LT X Props"
{
    AllowInCustomizations = AsReadWrite;
    DataCaptionFields = Id, DateText;
    DrillDownPageId = "LT X Drill Target";
    LookupPageId = "LT X Lookup Target";

    fields
    {
        modify(Bz2) { BlankZero = true; }
        modify(Bz) { BlankZero = false; }
        modify(CapCls) { CaptionClass = 'LTX,Modified'; }
        modify(CapCls2) { CaptionClass = 'LTX,Modified2'; }
        modify(Closing) { ClosingDates = false; }
        modify(Closing2) { ClosingDates = true; }
        modify(OptCap) { OptionCaption = 'Uno,Dos,Tres'; }
        modify(OptMl) { OptionCaptionML = ENU = 'Cyan,Magenta,Yellow', DEU = 'Zyan,Magenta,Gelb'; }
        modify(Wide) { Width = 20; }
        modify(Wide2) { Width = 5; }
    }
}

table 75002 "LT X Props Column Store"
{
    DataClassification = SystemMetadata;
    ColumnStoreIndex = Id, Amount;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { }
        field(3; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 75003 "LT X Props Linked"
{
    DataClassification = SystemMetadata;
    LinkedObject = true;
    LinkedInTransaction = false;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 75004 "LT X Props Sql"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; AsInteger; Code[20]) { SQLDataType = Integer; }
        field(3; AsVarchar; Code[20]) { SQLDataType = Varchar; }
        field(4; AsBigInteger; Code[20]) { SQLDataType = BigInteger; }
        field(5; AsDefault; Code[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K1; AsInteger) { }
        key(K2; AsVarchar) { }
        key(K3; AsDefault) { }
    }
}

page 75005 "LT X Props Card"
{
    PageType = Card;
    SourceTable = "LT X Props";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Digits; Rec.Digits) { ApplicationArea = All; }
            field(Picky; Rec.Picky) { ApplicationArea = All; }
            field(DateText; Rec.DateText) { ApplicationArea = All; }
            field(Secret; Rec.Secret) { ApplicationArea = All; }
            field(Plain; Rec.Plain) { ApplicationArea = All; }
            field(Op; Rec.Op) { ApplicationArea = All; }
            field(Disp; Rec.Disp) { ApplicationArea = All; }
            field(Wide; Rec.Wide) { ApplicationArea = All; }
            field(Bz; Rec.Bz) { ApplicationArea = All; }
            field(Bz2; Rec.Bz2) { ApplicationArea = All; }
            field(Closing; Rec.Closing) { ApplicationArea = All; }
            field(Closing2; Rec.Closing2) { ApplicationArea = All; }
            field(CapCls; Rec.CapCls) { ApplicationArea = All; }
            field(CapCls2; Rec.CapCls2) { ApplicationArea = All; }
            field(OptCap; Rec.OptCap) { ApplicationArea = All; }
            field(OptMl; Rec.OptMl) { ApplicationArea = All; }
            field(Rel; Rec.Rel) { ApplicationArea = All; }
            field(Cnt; Rec.Cnt) { ApplicationArea = All; }
        }
    }
}

page 75006 "LT X Drill Target"
{
    PageType = List;
    SourceTable = "LT X Props";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

page 75007 "LT X Lookup Target"
{
    PageType = List;
    SourceTable = "LT X Props";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 75008 "LT X Caption Subscriber"
{
    SingleInstance = true;

    var
        Calls: Text;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Calls;
        Calls := '';
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure OnResolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionArea <> 'LTX' then
            exit;
        Calls += 'resolve(' + CaptionExpr + ')';
        Caption := 'resolved:' + CaptionExpr;
        Resolved := true;
    end;
}

report 75009 "LT X Option Report"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT X Props")
        {
            column(Plain; Op) { }
            column(WithCaptionML; Op) { OptionCaptionML = ENU = 'Col one,Col two,Col three', DEU = 'Spalte eins,Spalte zwei,Spalte drei'; }
            column(EnuOnly; Op) { OptionCaptionML = ENU = 'Only A,Only B,Only C'; }
        }
    }
}
