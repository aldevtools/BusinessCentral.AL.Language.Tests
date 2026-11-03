// Objects for BcImplicitAreas.al (corpus issue 659 item 3, from al-runtime-rs #252): page extensions that add to area(FactBoxes) of a card
// that declares only area(Content), and to area(Content) and area(FactBoxes) of a card that declares no layout at all.
// The pages use a small table of their own (not Integer: a test page over Integer did not finish within the CI time limit).

table 80973 "BC Implicit Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Number; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Number) { Clustered = true; }
    }
}

page 80965 "BC Implicit FB Card"
{
    PageType = Card;
    SourceTable = "BC Implicit Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Number; Rec.Number) { ApplicationArea = All; }
            }
        }
    }
}

page 80968 "BC Implicit FB Part"
{
    PageType = ListPart;
    SourceTable = "BC Implicit Row";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(PartNumber; Rec.Number) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 80966 "BC Implicit FB Links" extends "BC Implicit FB Card"
{
    layout
    {
        addfirst(FactBoxes)
        {
            systempart(BCLinks; Links) { ApplicationArea = All; }
        }
    }
}

pageextension 80967 "BC Implicit FB Part Ext" extends "BC Implicit FB Card"
{
    layout
    {
        addlast(FactBoxes)
        {
            part(BCPart; "BC Implicit FB Part")
            {
                ApplicationArea = All;
                SubPageLink = Number = field(Number);
            }
        }
    }
}

pageextension 80971 "BC Implicit FB After Ext" extends "BC Implicit FB Card"
{
    layout
    {
        addafter(BCLinks)
        {
            part(BCPartAfter; "BC Implicit FB Part")
            {
                ApplicationArea = All;
                SubPageLink = Number = field(Number);
            }
        }
    }
}

page 80969 "BC No Layout Card"
{
    PageType = Card;
    SourceTable = "BC Implicit Row";
    ApplicationArea = All;
    UsageCategory = None;
}

pageextension 80970 "BC No Layout Ext" extends "BC No Layout Card"
{
    layout
    {
        addfirst(Content)
        {
            field(BCNumber; Rec.Number) { ApplicationArea = All; }
        }
        addlast(FactBoxes)
        {
            part(BCNoLayoutPart; "BC Implicit FB Part")
            {
                ApplicationArea = All;
                SubPageLink = Number = field(Number);
            }
        }
    }
}

// Writer QV (AL Runner issue 5674): the same page extensions on a List page that declares only area(Content), and the reporter's
// extension of Base Application's List page 7500 "Item Attributes" (which declares no FactBoxes area either).
page 87466 "LT QV Implicit FB List"
{
    PageType = List;
    SourceTable = "BC Implicit Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Number; Rec.Number) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 87467 "LT QV Implicit FB List Links" extends "LT QV Implicit FB List"
{
    layout
    {
        addfirst(FactBoxes)
        {
            systempart(QVLinks; Links) { ApplicationArea = All; }
        }
    }
}

pageextension 87468 "LT QV Implicit FB List Part" extends "LT QV Implicit FB List"
{
    layout
    {
        addlast(FactBoxes)
        {
            part(QVPart; "BC Implicit FB Part")
            {
                ApplicationArea = All;
                SubPageLink = Number = field(Number);
            }
        }
    }
}

pageextension 87469 "LT QV Item Attr. FactBoxes" extends "Item Attributes"
{
    layout
    {
        addfirst(FactBoxes)
        {
            systempart(QVItemAttrLinks; Links) { ApplicationArea = All; }
        }
    }
}
