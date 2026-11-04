// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-caption-method
// Scope: in-scope
// Fixtures used: TP Field Caption Row (60993)
//
// Backing table for the TestPage field Caption() suite. "PK" declares no Caption at all (the
// fallback-to-field-name case), Klass declares a field Caption the control does not override,
// and Chosen declares a field Caption the control DOES override.

table 60993 "TP Field Caption Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Klass; Text[30]) { Caption = 'Severity'; }
        field(3; Chosen; Boolean) { Caption = 'Accept'; }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}
