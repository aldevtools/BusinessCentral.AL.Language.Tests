// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
//
// The HOST page's source table for the modal-close part-flush suite (codeunit 60420).
//
// Separate from "TPMF Line" (60415) so the host row's fate and the part row's fate are two
// independent observations. The runner's two close paths differ in exactly that split — one
// flushes the host row and the part rows, the other flushes neither — so a test that could
// not tell "the host row persisted but the part row did not" apart from "nothing persisted"
// would not distinguish the candidate answers.

table 60416 "TPMF Head"
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
