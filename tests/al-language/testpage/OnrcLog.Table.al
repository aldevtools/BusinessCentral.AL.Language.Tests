// Fixture log table for TestPagePartOnNewRecordCount.al.
//
// A COUNTING witness, which is the whole reason this table exists. Every fixture in the corpus
// that measures OnNewRecord until now uses an ASSIGNMENT as its witness -- codeunit 60996's
// `Rec."Set By OnNewRecord" := 'NEWREC'` is the closest neighbour -- and an assignment is
// idempotent. It answers "did the trigger run at all" and cannot answer "how many times", so a
// page that raised OnNewRecord once, twice or five times for one row reads identically through
// it.
//
// The trigger appends a row here instead. The count is then a plain Integer a test asserts with
// a concrete value, which is what makes an over-firing implementation distinguishable from a
// correct one -- and, equally, what makes a NON-firing one distinguishable, since 0 and 2 both
// fail an assertion that names 1.
//
// It is a separate table on purpose. The record buffer a part page's OnNewRecord runs against is
// reset by the very platform step that raises the trigger (NavForm.NewRecord does ALInit first),
// and a draft line that nobody types into is never saved at all -- so a counter kept as a field
// on the line row would be wiped, or discarded, before any test could read it. A row inserted
// into a second table survives both.
table 60353 "ONRC Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        // Which fixture page raised the trigger, so one log can serve more than one arm without
        // the arms having to clear it between reads.
        field(2; Source; Code[20]) { }
        // BelowxRec as the trigger received it. Not asserted by the count tests themselves --
        // it is here so a failing count can be explained rather than only observed.
        field(3; "Below xRec"; Boolean) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
