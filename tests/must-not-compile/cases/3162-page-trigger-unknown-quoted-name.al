// @expect AL0118 | The name '"Missing Y"' does not exist in the current context.
// An unknown quoted name in a page trigger: the text shows the name with its quotes.
table 53162 "MNC QN3162 T"
{
    fields { field(1; "Entry No."; Integer) { } }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

page 53163 "MNC QN3162 P"
{
    SourceTable = "MNC QN3162 T";

    trigger OnOpenPage()
    begin
        "Missing Y" := 1;
    end;
}
