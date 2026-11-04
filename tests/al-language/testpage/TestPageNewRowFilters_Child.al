// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-new-method
// Scope: in-scope
// Fixtures used: Test Page New Row Flt Parent (60707), Test Page New Row Flt Child (60708)
//
// Child side. Derived is derived from the PARENT, so it can only be filled if the new row
// already knows which parent it belongs to. This is the shape that fails in the wild: the
// assertion lands on Derived while the actual defect is the blank ParentCode. Category is a
// second filterable field, present so a test can prove a filter on ONE field does not bleed
// into another.

table 60708 "Test Page New Row Flt Child"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; ParentCode; Code[20]) { }
        field(2; LineNo; Integer) { }
        field(3; Note; Text[30]) { }

        field(4; Derived; Text[30])
        {
            Editable = false;
        }

        field(5; Category; Code[10]) { }
    }

    keys
    {
        key(PK; ParentCode, LineNo) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Parent: Record "Test Page New Row Flt Parent";
    begin
        if Parent.Get(Rec.ParentCode) then
            Rec.Derived := 'belongs-to-' + Parent.Label;
    end;
}
