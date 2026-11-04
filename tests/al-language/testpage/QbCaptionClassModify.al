// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures of TestPageCaptionClass.al (writer QB, corpus issue #668 item 99, the part about a modified base field): a table whose fields have
// a Caption, one of them also a CaptionClass, a tableextension that sets CaptionClass on them with modify(), and a card page over the table.

table 86388 "LT QB Cc Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Remark; Text[50]) { Caption = 'QB Remark Caption'; }
        field(3; Amount; Decimal) { Caption = 'QB Amount Caption'; CaptionClass = '3,QB Base Class'; }
        field(4; Plain; Text[50]) { Caption = 'QB Plain Caption'; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

tableextension 86389 "LT QB Cc Row Ext" extends "LT QB Cc Row"
{
    fields
    {
        modify(Remark) { CaptionClass = '3,QB Modified Class'; }
        modify(Amount) { CaptionClass = '3,QB Modified Over Base'; }
    }
}

page 86390 "LT QB Cc Card"
{
    PageType = Card;
    SourceTable = "LT QB Cc Row";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(RemarkCtl; Rec.Remark) { }
            field(RemarkPageClass; Rec.Remark) { CaptionClass = '3,QB Page Class'; }
            field(AmountCtl; Rec.Amount) { }
            field(PlainCtl; Rec.Plain) { }
        }
    }
}
