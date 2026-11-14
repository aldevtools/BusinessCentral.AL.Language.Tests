// @expect AL0118 | The name '"Missing X"' does not exist in the current context.
// An unknown quoted name in a table trigger: the text shows the name with its quotes.
table 53161 "MNC QN3161 T"
{
    fields { field(1; "Entry No."; Integer) { } }
    keys { key(PK; "Entry No.") { Clustered = true; } }

    trigger OnInsert()
    begin
        "Missing X" := 1;
    end;
}
