// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-actionref-type
// Scope: in-scope
// Fixtures used: TPR Row (60764)
//
// Backing table for the promoted-actionref suite. A logged row is the observable proof that
// one SPECIFIC OnAction trigger ran: "Invoke() did not throw" proves nothing here, because an
// actionref that resolved to nothing would also not throw.

table 60764 "TPR Row"
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
