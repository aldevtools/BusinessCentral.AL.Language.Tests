// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method
// Scope: in-scope
// Fixtures for the QZ_* tests in codeunit "LT QI EE Tests" (QiEmptyErrorPages.al): table 87702, pages 87703 and 87704.
// Facts: Error('') raised from the TABLE field's OnValidate (not the page control's) during TestPage SetValue, on a List page and on a Card page,
//   directly and after a Confirm answered No by a ConfirmHandler (the shape "if not Confirm(..) then Error('')"): whether the test goes on,
//   GetLastErrorText / GetLastErrorCode, the value the control shows and the stored row.

table 87702 "LT QZ EE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; AutoGen; Boolean)
        {
            trigger OnValidate()
            begin
                if not AutoGen then
                    if not Confirm('LT QZ really disable?') then
                        Error('');
            end;
        }
        field(3; Name; Text[30])
        {
            trigger OnValidate()
            begin
                if Name = 'empty' then
                    Error('');
            end;
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 87703 "LT QZ EE List"
{
    PageType = List;
    SourceTable = "LT QZ EE Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(AutoGen; Rec.AutoGen) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 87704 "LT QZ EE Card"
{
    PageType = Card;
    SourceTable = "LT QZ EE Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(AutoGen; Rec.AutoGen) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}
