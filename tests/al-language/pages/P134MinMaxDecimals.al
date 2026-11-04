// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minvalue-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74121, pages 74122 74123, test codeunit 74124 (P134)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestPage SetValue on a Decimal control bound to a TABLE field with MinValue/MaxValue (and on a control with its own MinValue/MaxValue) with values that have more than two decimals, outside and inside the bounds: the error text (how the value is shown), the stored and displayed value afterwards
// BC versions: 29 (27 and 28 by CI)

table 74121 "LT P134 MinMax"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Dec; Decimal)
        {
            MinValue = 0;
            MaxValue = 100;
        }
        field(3; DecNeg; Decimal)
        {
            MinValue = -0.5;
            MaxValue = 2.5;
        }
        field(4; DecPl; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 1;
            MaxValue = 10;
        }
        field(5; DecPl0; Decimal)
        {
            DecimalPlaces = 0 : 0;
            MinValue = 1;
            MaxValue = 10;
        }
        field(6; DecFree; Decimal) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 74122 "LT P134 MinMax Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P134 MinMax";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Dec; Rec.Dec) { ApplicationArea = All; }
                field(DecNeg; Rec.DecNeg) { ApplicationArea = All; }
                field(DecPl; Rec.DecPl) { ApplicationArea = All; }
                field(DecPl0; Rec.DecPl0) { ApplicationArea = All; }
            }
        }
    }
}

page 74123 "LT P134 MinMax Free Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P134 MinMax";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(DecFree; Rec.DecFree)
                {
                    ApplicationArea = All;
                    MinValue = 1;
                    MaxValue = 10;
                }
            }
        }
    }
}

