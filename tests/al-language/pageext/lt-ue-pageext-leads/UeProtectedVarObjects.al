// Objects for UeProtectedVarTests.al (AL Runner issue 6159): page extension "LT UE PV Mid Ext" declares protected variables; a second page extension of the
// same page, "LT UE PV Top Ext", reads and assigns them. Fixtures: page 90346, page extensions 90347 and 90348. Table "LT UE Row" is in UeTriggerObjects.al.

page 90346 "LT UE PV Card"
{
    PageType = Card;
    SourceTable = "LT UE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }
}

pageextension 90347 "LT UE PV Mid Ext" extends "LT UE PV Card"
{
    layout
    {
        addlast(Content)
        {
            field(MidAmount; Rec.Amount)
            {
                Visible = ShowAmount;
            }
        }
        addlast(Content)
        {
            field(TraceField; Trace) { }
        }
    }

    trigger OnOpenPage()
    begin
        Trace += 'mid(' + Format(ShowAmount) + ')';
        ShowAmount := true;
    end;

    protected var
        ShowAmount: Boolean;
        Trace: Text;
}

pageextension 90348 "LT UE PV Top Ext" extends "LT UE PV Card"
{
    layout
    {
        addlast(Content)
        {
            field(TopAmount; Rec.Amount)
            {
                Visible = ShowAmount;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Trace += 'top(' + Format(ShowAmount) + ')';
        ShowAmount := not ShowAmount;
    end;
}
