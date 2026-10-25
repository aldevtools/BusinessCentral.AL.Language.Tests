// @expect AL0139 | Since 'OnAction' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in the OnAction trigger of a page action.
table 50000 "MNC SH Base Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC SH Page"
{
    SourceTable = "MNC SH Base Table";

    actions
    {
        area(Processing)
        {
            action(Go)
            {
                trigger OnAction()
                begin
                    exit(1);
                end;
            }
        }
    }
}
