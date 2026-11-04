// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Dec Line (60926)
//
// Line table whose split-key field is a Decimal — the third numeric type AutoSplitKey
// supports, and the one where a fractional existing key proves the arithmetic runs in the
// field's own type (an Integer-typed step from 50000.5 could not land on 60000.5). No
// OnInsert, no number series: any "Line No." value came from the page property.

table 60926 "ASK Dec Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Line No."; Decimal) { }
        field(3; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.", "Line No.") { Clustered = true; }
    }
}
