// Objects of the TRX probes (tests TRX_* in codeunit 74068 "LT Table Relation Quotes", TableRelationQuotes.al).
// local object: the TableRelation property of these fields, and a where() filter on a field that a tableextension adds, are what the tests check.
// Ids 95380 - 95386.

enum 95380 "LT TRX Type"
{
    Extensible = false;

    value(0; A) { }
    value(1; B) { }
}

table 95381 "LT TRX X"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 95382 "LT TRX Y"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Own Code"; Code[10]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

tableextension 95383 "LT TRX Y Ext" extends "LT TRX Y"
{
    fields
    {
        field(95384; "Ext Code"; Code[10]) { DataClassification = SystemMetadata; }
    }
}

table 95386 "LT TRX Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Type; Enum "LT TRX Type") { }
        field(3; "Source No."; Code[20])
        {
            TableRelation = if (Type = const(A)) "LT TRX X" else
            if (Type = const(B)) "LT TRX Y" where("Ext Code" = filter('<>'''''));
        }
        field(4; ExtNotEmptyQuoted; Code[20]) { TableRelation = "LT TRX Y" where("Ext Code" = filter('<>''''')); }
        field(5; OwnNotEmptyQuoted; Code[20]) { TableRelation = "LT TRX Y" where("Own Code" = filter('<>''''')); }
        field(6; ExtNotQuote; Code[20]) { TableRelation = "LT TRX Y" where("Ext Code" = filter('<>''')); }
        field(7; ExtConstEmpty; Code[20]) { TableRelation = "LT TRX Y" where("Ext Code" = const('')); }
        field(8; ExtNotEmptyBare; Code[20]) { TableRelation = "LT TRX Y" where("Ext Code" = filter(<> '')); }
        field(9; ExtSpaceFilter; Code[20]) { TableRelation = "LT TRX Y" where("Ext Code" = filter('A B')); }
        field(10; ExtSpaceConst; Code[20]) { TableRelation = "LT TRX Y" where("Ext Code" = const('A B')); }
        field(11; ExtEmptyQuoted; Code[20]) { TableRelation = "LT TRX Y" where("Ext Code" = filter('''''')); }
        field(12; OwnNotEmptyBare; Code[20]) { TableRelation = "LT TRX Y" where("Own Code" = filter(<> '')); }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}
