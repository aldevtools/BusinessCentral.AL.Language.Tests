// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-triggers-auto-page-onaftergetrecord
// Scope: in-scope
//
// The rows TestModalPageRowLoad.al opens a modal page on. Two of them, so "the row the caller
// positioned on" and "the first row in the table" are different rows.
table 60400 "MRL Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = CustomerContent; }
        field(2; Descr; Text[50]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
