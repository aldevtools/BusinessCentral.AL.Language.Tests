// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: (none — this table exists only to back the card page below)
//
// Backing table for the "does a same-value SetValue still run OnModify" suite.
//
// The counter lives in a SEPARATE table (SVM Trace), not in a field of this one. A counter
// field on the row itself would be written by OnModify and so would itself become a changed
// field — the very thing under measurement — and the second write would then have something
// genuine to compare unequal. Keeping the tally outside the row keeps the row's field values
// identical across a same-value write.

table 60408 "SVM Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Note; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnModify()
    var
        Trace: Record "SVM Trace";
    begin
        Trace.Bump();
    end;
}
