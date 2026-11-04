// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-class
// Scope: fixture objects for AhPageTests.al (corpus issue 636, items 4 to 8)
// Fixtures used: own tables 78610, 78616, 78617; pages 78611-78615, 78618, 78619

table 78610 "LT AH Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Qty; Integer) { MinValue = 1; MaxValue = 10; }
        field(4; Dec; Decimal) { MinValue = 0; MaxValue = 100; }
        field(5; Name; Text[30]) { }
        field(6; Lvl; Integer) { }
        field(7; Letters; Text[30]) { }
        field(8; Other; Text[30]) { }
        field(9; Guard; Text[30])
        {
            trigger OnValidate()
            begin
                if Guard = 'bad' then
                    Error('LT AH guard refused');
            end;
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 78611 "LT AH Card"
{
    PageType = Card;
    SourceTable = "LT AH Row";

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            field(DecCtl; Rec.Dec) { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(OtherCtl; Rec.Other) { ApplicationArea = All; }
            field(GuardCtl; Rec.Guard) { ApplicationArea = All; }
            field(LettersCtl; Rec.Letters) { ApplicationArea = All; CharAllowed = 'azAZ09'; }
        }
    }
}

page 78612 "LT AH CharAllowed Card"
{
    PageType = Card;
    SourceTable = "LT AH Row";

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(ThreeRanges; Rec.Txt) { ApplicationArea = All; CharAllowed = 'azAZ09'; }
            field(SinglesAndRange; Rec.Name) { ApplicationArea = All; CharAllowed = '09--__'; }
            field(Unordered; Rec.Other) { ApplicationArea = All; CharAllowed = 'zz55aa'; }
            field(NonAscii; Rec.Letters) { ApplicationArea = All; CharAllowed = 'ÄÄaa'; }
            field(OneRangeMany; Rec.Guard) { ApplicationArea = All; CharAllowed = 'AFaf09'; }
        }
    }
}

page 78613 "LT AH Tree"
{
    PageType = List;
    SourceTable = "LT AH Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Lvl;
                ShowAsTree = true;

                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }
}

page 78615 "LT AH Part"
{
    PageType = ListPart;
    SourceTable = "LT AH Row";
    DelayedInsert = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

page 78614 "LT AH Host List"
{
    PageType = List;
    SourceTable = "LT AH Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(SamePart; "LT AH Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }
}

table 78616 "LT AH Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Descr; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 78617 "LT AH Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; HeadId; Code[20]) { }
        field(2; LineNo; Integer) { }
        field(3; Descr; Text[30]) { }
        field(4; Amount; Decimal) { }
    }

    keys { key(PK; HeadId, LineNo) { Clustered = true; } }
}

page 78619 "LT AH Lines Part"
{
    PageType = ListPart;
    SourceTable = "LT AH Line";
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoCtl; Rec.LineNo) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
                field(AmountCtl; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }
}

page 78618 "LT AH Document"
{
    PageType = Document;
    SourceTable = "LT AH Head";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
            part(Lines; "LT AH Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = HeadId = field(Id);
            }
        }
    }
}
