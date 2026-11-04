// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
//
// Fixture table for the Report Metadata / Report Data Items column tests below. Three fields
// and two keys, because the assertions are about how BC reports a data item's table view, its
// sorting fields and its request filter fields, and all three are stated in terms of FIELD
// NUMBERS. Each aspect of the shape rules out one wrong answer:
//
//   more than one field   -> "the first field" is distinguishable from "field number 1"
//   a field numbered 5    -> the numbers are field numbers, not positions in the field list
//   a non-primary key     -> "the primary key" is distinguishable from the declared sorting
//   that key not in field order ("Alt Code" is 5, Description is 2) -> the reported order is
//                            the KEY's order, not ascending field-number order

table 60359 "Test Rpt Meta Cols Sample"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = CustomerContent; }
        field(2; Description; Text[50]) { DataClassification = CustomerContent; }
        // Deliberately 5, not 3: a column reporting field NUMBERS must be distinguishable
        // from one reporting the field's position among the declared fields.
        field(5; "Alt Code"; Code[20]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        // A secondary key whose fields are neither field 1 nor in ascending field order.
        key(Alt; "Alt Code", Description) { }
    }
}
