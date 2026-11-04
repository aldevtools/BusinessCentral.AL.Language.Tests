// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-notblank-property
// Scope: in-scope
// Fixtures for the QZ_* tests in codeunit "LT BE Enum SetValue Tests" (BeEnumSetValueBlank.al): enum 87704, table 87705, page 87706.
// Facts: TestPage SetValue('') and SetValue of the blank member's caption on an Enum field with NotBlank = true whose value 0 is " ",
//   on a List page, next to a field of the same enum without NotBlank: the error text and code, the value shown and stored.

enum 87704 "LT QZ NB Kind"
{
    Extensible = false;
    value(0; " ") { }
    value(1; Person) { }
    value(2; Company) { }
}

table 87705 "LT QZ NB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; KindNB; Enum "LT QZ NB Kind") { NotBlank = true; }
        field(3; Kind; Enum "LT QZ NB Kind") { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

page 87706 "LT QZ NB List"
{
    PageType = List;
    SourceTable = "LT QZ NB Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(KindNB; Rec.KindNB) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }
}
