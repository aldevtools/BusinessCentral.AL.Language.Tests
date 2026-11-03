// @expect AL0124 | The property 'AccessByPermission' cannot be used in this context. Verify the property is available for the current object type.
// AccessByPermission on a page group: the property exists on fields, actions, parts, the page and the report, not on a group (writer Y84, permission probes).
table 50000 "MNC Y84 2785 T"
{
    fields { field(1; Id; Integer) { } }
}

page 50001 "MNC Y84 2785 P"
{
    SourceTable = "MNC Y84 2785 T";
    layout
    {
        area(Content)
        {
            group(G)
            {
                AccessByPermission = tabledata "MNC Y84 2785 T" = R;
                field(Id; Rec.Id) { }
            }
        }
    }
}
