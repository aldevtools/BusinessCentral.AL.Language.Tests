// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: Test Page Enum Field Grade (60688), Test Page Enum Field Row (60689)
//
// Backing table for the TestPage enum/option-field suite.

table 60689 "Test Page Enum Field Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        // The control. Same runtime type as Grade, but its members are written on the field, so
        // a runner reading members off the field alone still answers this one correctly.
        field(2; Kind; Option) { OptionMembers = Alpha,Beta,Gamma; }
        // The subject. Non-zero target values throughout, so "the default happened to be right"
        // is never an explanation for a green result.
        field(3; Grade; Enum "Test Page Enum Field Grade") { }
        // Not an option at all. Its only job is to answer "does an edit to an existing row reach
        // the table?" independently of anything to do with option members.
        field(4; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
