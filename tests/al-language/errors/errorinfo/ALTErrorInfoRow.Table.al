// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-data-type
// Scope: in-scope
//
// Backing table for the ErrorInfo surface suite (codeunit 60351).
//
// ErrorInfo carries three members that only mean something against a REAL record --
// RecordId(), TableId() and FieldNo() -- and ErrorInfo.Create() has a `var Record`
// overload that populates all three from one argument. A corpus-defined table is used
// rather than a Base Application one because writing a Base Application table is refused
// under the test isolation this suite runs with (issue #223).
//
// Two things about this table are deliberate:
//
//   1. THE FIELD USED FOR FieldNo ASSERTIONS IS NOT FIELD 1. "Entry No." is field 1 and
//      Payload is field 2, so an implementation that returned a hardcoded 1, or that
//      confused a field number with an ordinal position, fails a FieldNo assertion that a
//      field-1 fixture would have let pass.
//
//   2. THE PRIMARY KEY IS A SINGLE INTEGER, so a RecordId taken from a seeded row is
//      cheap to construct and compare, and two DIFFERENT rows produce two DIFFERENT
//      RecordIds -- which is what makes the RecordId round-trip test discriminating
//      rather than a comparison of two things that were always going to be equal.

table 60351 "ALT ErrorInfo Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        // Deliberately field 2, not field 1 -- see note 1 above.
        field(2; Payload; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
