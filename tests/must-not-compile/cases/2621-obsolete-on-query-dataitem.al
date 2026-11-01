// @expect AL0124 | The property 'ObsoleteState' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteReason' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteTag' cannot be used in this context. Verify the property is available for the current object type.
// A query data item takes none of ObsoleteState, ObsoleteReason and ObsoleteTag (al-runner issue 6652; AL0124 for each). Its columns and
// filters take them: tests/al-language/misc/lt-y64-obsolete-subelements/Y64ObsoleteSub.al.
table 52621 "MNC Y64 Obs Row" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
query 52621 "MNC Y64 Obs Query"
{
    elements
    {
        dataitem(Row; "MNC Y64 Obs Row")
        {
            ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = '1.0';
            column(Id; Id) { }
        }
    }
}
