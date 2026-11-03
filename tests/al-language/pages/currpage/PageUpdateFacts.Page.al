// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: ALT Page Update Row (60491)
//
// The FactBox the suite reads its answer out of, and it is built so that the HOST's
// OnAfterGetCurrRecord is the ONLY thing that can change what it displays.
//
// Its rowset is a temporary Integer table seeded once in OnOpenPage, so moving around in it
// can never re-read the database. Its single column reads a PAGE GLOBAL array, and that array
// is written only by SetHeader, an internal procedure the host calls from its own
// OnAfterGetCurrRecord. There is no SubPageLink, so nothing links the part to the host's row
// either -- if the host's trigger does not run again, the displayed value cannot change, and
// a stale reading is therefore attributable to that trigger and to nothing else.

page 60493 "ALT Page Update Facts"
{
    PageType = ListPart;
    SourceTable = Integer;
    SourceTableTemporary = true;
    Editable = false;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Derived; Derived[Rec.Number])
                {
                    ApplicationArea = All;
                    Caption = 'Derived';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Number := 1;
        Rec.Insert();
        Rec.Number := 2;
        Rec.Insert();
        Rec.FindFirst();
    end;

    var
        Derived: array[20] of Decimal;

    internal procedure SetHeader(RowNo: Code[20])
    var
        Row: Record "ALT Page Update Row";
        Trace: Codeunit "ALT Page Update Trace";
    begin
        Trace.Note('SetHeader');
        Clear(Derived);
        if Row.Get(RowNo) then begin
            Derived[1] := Row.Amount;
            Derived[2] := Row.Amount * 2;
        end;
    end;
}
