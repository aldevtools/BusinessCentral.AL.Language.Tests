// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); declares the P99 fixtures (tables 70400 70401, pages 70400 70401)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: fixtures only: a row table, a one-row setup table whose values the list and card pages read in OnOpenPage to set filters in filter group 0 and 2

table 70400 "LT P99 Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Code[10]) { }
        field(2; F; Code[10]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 70401 "LT P99 Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; K; Code[10]) { }
        field(2; G0; Code[10]) { }
        field(3; G2; Code[10]) { }
    }

    keys
    {
        key(PK; K) { Clustered = true; }
    }
}

page 70400 "LT P99 List"
{
    PageType = List;
    SourceTable = "LT P99 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(FCtl; Rec.F) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Record "LT P99 Setup";
    begin
        if not Setup.Get('S') then
            exit;
        if Setup.G0 <> '' then
            Rec.SetRange(F, Setup.G0);
        if Setup.G2 <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetRange(F, Setup.G2);
            Rec.FilterGroup(0);
        end;
    end;
}

page 70401 "LT P99 Card"
{
    PageType = Card;
    SourceTable = "LT P99 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(FCtl; Rec.F) { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Record "LT P99 Setup";
    begin
        if not Setup.Get('S') then
            exit;
        if Setup.G0 <> '' then
            Rec.SetRange(F, Setup.G0);
        if Setup.G2 <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetRange(F, Setup.G2);
            Rec.FilterGroup(0);
        end;
    end;
}
