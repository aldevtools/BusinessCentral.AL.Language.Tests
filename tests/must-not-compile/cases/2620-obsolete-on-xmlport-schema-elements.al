// @expect AL0124 | The property 'ObsoleteState' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteReason' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteTag' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteState' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteReason' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteTag' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteState' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteReason' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteTag' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteState' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteReason' cannot be used in this context. Verify the property is available for the current object type.
// @expect AL0124 | The property 'ObsoleteTag' cannot be used in this context. Verify the property is available for the current object type.
// XmlPort schema elements take none of ObsoleteState, ObsoleteReason and ObsoleteTag (al-runner issue 6652): a textelement, a tableelement, a
// fieldelement and a fieldattribute (AL0124 for each property). A field of the XmlPort request page takes them:
// tests/al-language/misc/lt-y64-obsolete-subelements/Y64ObsoleteSub.al.
table 52620 "MNC Y64 Obs Row" { fields { field(1; Id; Integer) { } field(2; Name; Text[20]) { } } keys { key(PK; Id) { Clustered = true; } } }
xmlport 52620 "MNC Y64 Obs XmlPort"
{
    schema
    {
        textelement(Root)
        {
            ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = '1.0';
            tableelement(Row; "MNC Y64 Obs Row")
            {
                ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = '1.0';
                fieldattribute(Name; Row.Name) { ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
                fieldelement(Id; Row.Id) { ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
            }
        }
    }
}
