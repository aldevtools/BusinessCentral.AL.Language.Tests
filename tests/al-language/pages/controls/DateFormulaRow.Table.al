// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dateformula/dateformula-data-type
// Scope: in-scope
// Fixtures used: none
//
// Source table for the DateFormula-control suite. "Period Length" is the DateFormula field a
// Rec-bound page control is written through; "Description" is a plain Text field carried
// alongside it so the suite can pin that a NON-DateFormula control on the same page still
// takes a text value the same way it always did. Without that second field an implementation
// that routed EVERY control through a DateFormula evaluator would pass every DateFormula arm
// and nothing would notice.

table 60604 "ALT DateFormula Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = CustomerContent; }
        field(2; "Period Length"; DateFormula) { DataClassification = CustomerContent; }
        field(3; "Description"; Text[50]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
