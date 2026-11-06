// Objects of cross-app fixture A for the cross-app protected variable probe (al-runner issues 6983 and 6984).
// Tests: tests/al-language/table-objects/extensions/ProtectedVarCrossApp.al.
//   95520: a table with protected variables (BaseText, BaseFlag) and procedures that read them.
//   95521: an extension of that table in this app with protected variables (ExtHide, ExtText) and a setter and getters.
//   95522: a page with a protected variable (PageText); 95523: a processing-only report with a protected variable (RepText).
// local object: the protected variable declarations of these objects are under test.

table 95520 "TBL ProtVar XA Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Decimal) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }

    protected var
        BaseText: Text;
        BaseFlag: Boolean;

    procedure XaSetBaseText(Value: Text)
    begin
        BaseText := Value;
    end;

    procedure XaGetBaseText(): Text
    begin
        exit(BaseText);
    end;

    procedure XaGetBaseFlag(): Boolean
    begin
        exit(BaseFlag);
    end;
}

tableextension 95521 "TBL ProtVar XA Ext" extends "TBL ProtVar XA Table"
{
    procedure XaSetExtHide(Hide: Boolean)
    begin
        ExtHide := Hide;
    end;

    procedure XaGetExtHide(): Boolean
    begin
        exit(ExtHide);
    end;

    procedure XaGetExtText(): Text
    begin
        exit(ExtText);
    end;

    protected var
        ExtHide: Boolean;
        ExtText: Text;
}

page 95522 "TBL ProtVar XA Card"
{
    PageType = Card;
    SourceTable = "TBL ProtVar XA Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { }
        }
    }

    protected var
        PageText: Text;

    procedure XaSetPageText(Value: Text)
    begin
        PageText := Value;
    end;

    procedure XaGetPageText(): Text
    begin
        exit(PageText);
    end;
}

report 95523 "TBL ProtVar XA Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    protected var
        RepText: Text;

    procedure XaSetRepText(Value: Text)
    begin
        RepText := Value;
    end;

    procedure XaGetRepText(): Text
    begin
        exit(RepText);
    end;
}
