// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: TestPage SubErr Row (60823)
//
// The row "TP SubErr Guard" (60824) refuses to let go of. `Guarded` is what the subscriber
// reads, so both arms of TestPageSubscriberRefusal_Tests drive the SAME code path and differ
// only in the data — an implementation that refused (or accepted) unconditionally fails one of
// them.
table 60823 "TestPage SubErr Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = CustomerContent; }
        field(2; Guarded; Boolean) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
