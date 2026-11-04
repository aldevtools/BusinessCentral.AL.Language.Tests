// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
//
// The PART's own source table for the modal-close part-flush suite (codeunit 60420).
//
// Deliberately has no OnInsert trigger and no AutoSplitKey feeding it: a row appears here
// only because the test client's part buffer was written back to the table. That is the
// whole observable — the suite asks whether closing the host page persists a part row the
// handler started with New() and never committed, so anything that could insert a row for
// another reason would destroy the measurement.

table 60415 "TPMF Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Head No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "Head No.", "Line No.") { Clustered = true; }
    }
}
