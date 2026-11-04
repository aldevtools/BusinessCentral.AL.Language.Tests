// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: Test Page OnValidate Row (60711)
//
// Backing table for the TestPage SetValue-must-validate suite.

table 60711 "Test Page OnValidate Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }

        // The realistic shape: setting a code fills in the name that belongs to it.
        field(2; Source; Code[20])
        {
            trigger OnValidate()
            begin
                if Rec.Source = '' then
                    Rec.Derived := ''
                else
                    Rec.Derived := 'derived-from-' + Rec.Source;
            end;
        }
        field(3; Derived; Text[30]) { Editable = false; }

        // No trigger at all — the control for "the runner did not simply start running
        // something on every write".
        field(4; Manual; Text[30]) { }

        // Refuses a value outright, so the write must not land.
        field(5; Guarded; Integer)
        {
            trigger OnValidate()
            begin
                if Rec.Guarded < 0 then
                    Error('Guarded may not be negative, but %1 was entered.', Rec.Guarded);
            end;
        }

        // Written only by the PAGE control's OnValidate, never by the table's.
        field(6; PageEcho; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
