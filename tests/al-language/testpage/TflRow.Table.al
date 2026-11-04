// Fixture table for TestPageFieldTableLookup.al. Two of its fields declare the TABLE form of
// OnLookup -- the parameterless one that writes into Rec itself, as opposed to a page
// control's trigger OnLookup(var Text: Text): Boolean. Each writes a value naming WHERE it
// ran, so a failing assertion reports which of the two triggers fired rather than only that
// the wrong one did.
table 60314 "TFL Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        // The control over this field on "TFL Card" declares no OnLookup of its own.
        field(2; "Table Only"; Code[20])
        {
            trigger OnLookup()
            begin
                "Table Only" := 'FROM-TABLE';
            end;
        }
        // The control over THIS field declares one too. Both triggers exist; only one may run.
        field(3; Both; Code[20])
        {
            trigger OnLookup()
            begin
                Both := 'FROM-TABLE';
            end;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
