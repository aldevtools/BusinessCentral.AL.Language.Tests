// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optioncaption-property
// Scope: in-scope
// Fixtures for corpus issue #664 item 77 (OptionCaption on a page field bound to an Enum table field, AL0600 is a warning):
// an enum with sparse ordinals 0, 1, 4, 5, a table with a field of that enum, and a card whose field sets
// OptionCaption = ' ,c1,,,c4,c5'. The test is Enum_SparseOrdinals_PageOptionCaption in handlers/TestPageEnumField_Tests.al.

enum 82350 "LT BO Sparse Enum"
{
    Extensible = true;

    value(0; " ") { }
    value(1; value1) { Caption = 'cap1'; }
    value(4; value4) { Caption = 'cap4'; }
    value(5; value5) { Caption = 'cap5'; }
}

table 82351 "LT BO Sparse Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; E; Enum "LT BO Sparse Enum") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 82352 "LT BO Sparse Card"
{
    PageType = Card;
    SourceTable = "LT BO Sparse Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id)
            {
                ApplicationArea = All;
            }
            // AL0600 (warning): OptionCaption on an enum field. Position 2 (' ,c1,,,c4,c5' split on commas) is empty.
            field(E; Rec.E)
            {
                ApplicationArea = All;
                OptionCaption = ' ,c1,,,c4,c5';
            }
        }
    }
}
