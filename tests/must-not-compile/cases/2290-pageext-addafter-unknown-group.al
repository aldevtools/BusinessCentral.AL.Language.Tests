// @expect AL0271 | The action 'NoSuchGroup' is not found in the target 'MNC UP List 2290'
// addafter() of a group name that is neither declared on the page nor a standard promoted category (al-runner issue 6217): AL0271.
table 50000 "MNC UP Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC UP List 2290"
{
    PageType = List;
    SourceTable = "MNC UP Table";

    layout
    {
        area(Content)
        {
            repeater(Lines) { field(Id; Rec.Id) { } }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Post) { }
        }
    }
}

pageextension 50002 "MNC UP List Ext 2290" extends "MNC UP List 2290"
{
    actions
    {
        addafter(NoSuchGroup)
        {
            action(MyAction) { }
        }
    }
}
