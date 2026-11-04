// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: Job (Base Application)
//
// CLAIM (arm C of the CurrFieldNo suite): a tableextension field's OWN OnValidate sees
// CurrFieldNo just like a table's own field does, when the write comes through a TestPage
// control bound to the extension field. Distinct from TestTableExtFieldTestPageControl.al
// (which proves a page control bound to a tableextension field writes through and runs
// OnValidate at all) — this is specifically about what CurrFieldNo reads inside that trigger.
// Job is used only as a convenient, always-available Base Application table to extend; the
// claim is about tableextension field dispatch in general, not about Job specifically.

tableextension 60390 "TP CurrFieldNo Job Ext" extends Job
{
    fields
    {
        field(60020; "TP CFN Ext Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                Rec."TP CFN Ext FieldNo" := CurrFieldNo;
            end;
        }
        field(60021; "TP CFN Ext FieldNo"; Integer)
        {
            DataClassification = CustomerContent;
        }
    }
}
