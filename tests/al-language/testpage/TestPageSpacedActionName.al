// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: Spaced Action Row (60242)
//
// Backing table for the spaced-action-name TestPage suite (companion to
// TestPageActionInvoke / TestPageExtensionActionInvoke, which cover unspaced names).

table 60242 "Spaced Action Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
