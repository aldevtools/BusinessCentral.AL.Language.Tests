// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: (none — this table exists only to give the card page below a SourceTable)
//
// Backing table for the TestPage CurrFieldNo suite. Amount is the control under test; its
// OnValidate records CurrFieldNo into ValidateFieldNo so a test can read, after the fact,
// exactly what the trigger saw. OnModify does the same into ModifyFieldNo, to separate the
// question "what does the VALIDATE trigger see" from "what does the page's own save (Modify)
// see" — real BC answers those two questions differently.

table 60388 "TP CurrFieldNo Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(10; Amount; Decimal)
        {
            trigger OnValidate()
            begin
                Rec.ValidateFieldNo := CurrFieldNo;
            end;
        }
        field(11; ValidateFieldNo; Integer) { }
        field(12; ModifyFieldNo; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnModify()
    begin
        Rec.ModifyFieldNo := CurrFieldNo;
    end;
}
