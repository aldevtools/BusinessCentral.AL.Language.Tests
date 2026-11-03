// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: Job (Base Application), TP CurrFieldNo Job Ext (60390)

page 60391 "TP CurrFieldNo Job Card"
{
    PageType = Card;
    SourceTable = Job;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TP CurrFieldNo Job Card';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
            }
            field("TP CFN Ext Amount"; Rec."TP CFN Ext Amount")
            {
                ApplicationArea = All;
            }
            field("TP CFN Ext FieldNo"; Rec."TP CFN Ext FieldNo")
            {
                ApplicationArea = All;
            }
        }
    }
}
