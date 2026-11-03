// @expect AL0126 | No overload for method 'Run' takes 2 arguments. Candidates: built-in method 'Run()'
// A bare Run(Page::X, Rec) in a report trigger: Run names the report's own Run().
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

report 50001 "MNC Y47 Run Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    trigger OnPreReport()
    var
        Row: Record "MNC Y47 Run Row";
    begin
        Run(Page::"MNC Y47 Run List", Row);
    end;
}
