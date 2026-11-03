// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-value-method
// Scope: in-scope
// Fixtures used: (none — this table exists only to give the card page below a SourceTable,
//   and to give the page a global temporary Record of its own to bind controls to)
//
// Backing table for the "two controls, one binding" suite. Value is what the Rec-bound
// controls show; the page's own temporary Record global is of this same table, so a control
// bound to <global record>.Value is a different binding from one bound to Rec.Value even
// though both name the same field.

table 60771 "TP Shared Bind Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Value; Text[30]) { }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}
