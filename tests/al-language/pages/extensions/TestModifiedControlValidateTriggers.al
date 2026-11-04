// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: MCV Row (60510)
//
// A pageextension `modify(Control)` block may declare OnBeforeValidate and OnAfterValidate
// for a control the BASE page declares. Nothing in the corpus pinned the order they run in
// relative to the base control's own OnValidate, so this suite does.
//
// The trace is accumulated into a field of the row itself rather than a separate log table:
// the whole claim is about ORDER, and appending to one string makes the order the value
// under assertion instead of something reconstructed from entry numbers.

table 60510 "MCV Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        // A second validatable field, so the suite can pin that a modify() block on ANOTHER
        // control is not raised for this one.
        field(3; Other; Text[50]) { }
        // A third field, carrying no trigger of its own, for the drilldown/lookup arms.
        field(4; Extra; Text[50]) { }
        // Long enough that no arm below can silently truncate the trace it asserts on.
        field(5; Trace; Text[250]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
