// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 72065
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: table and pages shared by the P70 drafts
// BC versions: 29 (27 and 28 by CI)

table 72065 "LT P70 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[10]) { }
        field(3; Qty; Integer) { }
        field(4; Amount; Decimal) { }
        field(5; Descr; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 72066 "LT P70 Row List"
{
    PageType = List;
    SourceTable = "LT P70 Row";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}
