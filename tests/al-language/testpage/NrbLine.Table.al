// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-new-method
// Scope: in-scope
// Fixtures used: NRB Line (60650)
//
// Line table for the New()-record-init suite. Two things are load-bearing:
//
//   - "No." is part of the primary key, so it is one of the fields
//     RecordImplementation.InitRecordFromFilters copies from the part's SubPageLink onto a
//     New() row (see StefanMaron/BusinessCentral.AL.Language.Tests#148, which pins the
//     key-membership half of that rule) -- which makes it the field to watch for whether
//     NewRecordAsync also VALIDATES what it copies, not just assigns it.
//   - "No. Validated" is a plain Boolean with no default and no other writer, set only by
//     "No."'s own OnValidate trigger. It is not a copy of "No." -- it answers a different
//     question (was Validate() called, not what value arrived), so a runtime that assigns
//     the field without validating it leaves this at its Init() default while "No." itself
//     already carries the linked value.
//   - "Never Validated" is the control for it: same type, same absence of a default, and
//     NOTHING anywhere writes it. Comparing the two answers "did this flag move off its
//     default" without depending on how a Boolean renders as text, which is a separate
//     question this suite also pins but must not accidentally rest on.

table 60650 "NRB Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            trigger OnValidate()
            begin
                "No. Validated" := true;
            end;
        }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[50]) { }
        field(4; "No. Validated"; Boolean) { }
        field(5; "Never Validated"; Boolean) { }
    }

    keys
    {
        key(PK; "No.", "Line No.") { Clustered = true; }
    }
}
