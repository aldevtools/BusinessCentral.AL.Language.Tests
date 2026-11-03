// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minvalue-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 71332, page 71333, test codeunit 71334
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestPage SetValue on a Decimal control with MinValue 0.5 / MaxValue 2.5 (page variable and table field) for values just outside the bound that round to the bound or inside it.
// BC versions: 29 (27 and 28 by CI)
table 71332 "LT P158 Bounds Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amt; Decimal)
        {
            MinValue = 0.5;
            MaxValue = 2.5;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 71333 "LT P158 Bounds Page"
{
    PageType = Card;
    SourceTable = "LT P158 Bounds Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Amt; Rec.Amt) { ApplicationArea = All; }
            field(DecVar; DecVar)
            {
                ApplicationArea = All;
                MinValue = 0.5;
                MaxValue = 2.5;
            }
        }
    }

    var
        DecVar: Decimal;
}

