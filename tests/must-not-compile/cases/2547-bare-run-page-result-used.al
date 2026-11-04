// @expect AL0122 | Cannot implicitly convert type 'None' to 'Boolean'. Use an explicit conversion or change the type.
// The result of a bare Run(Page::X, Rec) inside a page used as a Boolean: Page.Run returns nothing.
// The bare call compiles inside a page and runs as Page.Run: pages/lt-uf-unqualified-runmodal/Y47UnqualifiedRun.al (writer Y47, al-runner issue 6590).
table 50000 "MNC Y47 Run Row"
{
    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 50000 "MNC Y47 Run List"
{
    PageType = List;
    SourceTable = "MNC Y47 Run Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { }
            }
        }
    }
}

page 50001 "MNC Y47 Run Card"
{
    PageType = Card;
    SourceTable = "MNC Y47 Run Row";
    UsageCategory = None;

    trigger OnOpenPage()
    var
        Row: Record "MNC Y47 Run Row";
    begin
        if Run(Page::"MNC Y47 Run List", Row) then;
    end;
}
