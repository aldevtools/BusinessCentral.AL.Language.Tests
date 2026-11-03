// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
// Scope: in-scope
// Fixtures used: TPF Row (69932), TPF Enum (69932)

page 69935 "TPF List"
{
    PageType = List;
    SourceTable = "TPF Row";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'TPF List';
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(PK; Rec.PK) { ApplicationArea = All; }
                field(Num; Rec.Num) { ApplicationArea = All; }
                field(Dec2; Rec.Dec2) { ApplicationArea = All; DecimalPlaces = 2 : 2; }
                field(Flag; Rec.Flag) { ApplicationArea = All; }
                field(Opt; Rec.Opt) { ApplicationArea = All; }
                field(Enm; Rec.Enm) { ApplicationArea = All; }
                field(Dt; Rec.Dt) { ApplicationArea = All; }
                field(Tm; Rec.Tm) { ApplicationArea = All; }
                field(DtTm; Rec.DtTm) { ApplicationArea = All; }
                field(Gd; Rec.Gd) { ApplicationArea = All; }
                field(Dur; Rec.Dur) { ApplicationArea = All; }
            }
        }
    }
}
