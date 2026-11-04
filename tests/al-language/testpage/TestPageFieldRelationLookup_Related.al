// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: TRL Related (60563), TRL Related List (60564)
//
// The RELATED table a TRL Host field's TableRelation points at. It declares LookupPageId, so
// a lookup on a field related to it has a page to open without the field, the control or the
// table declaring any OnLookup trigger at all -- which is the whole subject of the suite.

table 60563 "TRL Related"
{
    DataClassification = CustomerContent;
    LookupPageId = "TRL Related List";

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
