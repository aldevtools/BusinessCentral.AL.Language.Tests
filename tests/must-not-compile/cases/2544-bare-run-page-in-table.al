// @expect AL0118 | The name 'Run' does not exist in the current context.
// A bare Run(Page::X, Rec) in a table trigger.
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

table 50001 "MNC Y47 Run Host"
{
    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Row: Record "MNC Y47 Run Row";
    begin
        Run(Page::"MNC Y47 Run List", Row);
    end;
}
