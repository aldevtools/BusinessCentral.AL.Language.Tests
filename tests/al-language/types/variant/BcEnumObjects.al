// Objects for BcEnumVariant.al (corpus issue 659 item 1, from al-runtime-rs #250): enums with default access and Access = Internal,
// an extensible enum with an enum extension value, a table with enum fields and a table extension of a Base Application table with enum fields.

enum 80950 "BC Kind"
{
    Extensible = false;
    value(0; Normal) { }
    value(1; Other) { }
}

enum 80951 "BC Kind Internal"
{
    Extensible = false;
    Access = Internal;
    value(0; Normal) { }
    value(1; Other) { }
}

enum 80955 "BC Kind Ext"
{
    Extensible = true;
    value(0; Normal) { }
    value(1; Other) { }
}

enumextension 80956 "BC Kind Ext More" extends "BC Kind Ext"
{
    value(80950; Extra) { }
}

table 80953 "BC Enum Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "BC Kind") { }
        field(3; KindInternal; Enum "BC Kind Internal") { }
        field(4; KindExt; Enum "BC Kind Ext") { }
        field(5; Opt; Option)
        {
            OptionMembers = Zero,One,Two;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 80952 "BC Sales Inv Line Ext" extends "Sales Invoice Line"
{
    fields
    {
        field(80950; "BC Kind"; Enum "BC Kind")
        {
            DataClassification = CustomerContent;
        }
        field(80951; "BC Kind Internal"; Enum "BC Kind Internal")
        {
            DataClassification = CustomerContent;
        }
        field(80952; "BC Kind Ext"; Enum "BC Kind Ext")
        {
            DataClassification = CustomerContent;
        }
    }
}
