// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-visible-method
// Scope: in-scope
// Fixtures used: (none — this table exists only to give the card page below a SourceTable)
//
// Backing table for the TestPage field-Visible-inherits-from-group suite. The single Value
// field gives every control on the page something to bind to; none of the tests care about its
// actual content, only about whether the control showing it reports Visible() true or false.

table 60964 "TP Field Visible Row"
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
