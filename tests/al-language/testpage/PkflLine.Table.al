// Fixture line table for TestPageSubpagePartFieldLink.al whose primary key is "Line No."
// ALONE -- "Header No.", the field a field(...) SubPageLink targets, is deliberately NOT part
// of it. That is the whole point of this table: BC's
// RecordImplementation.InitRecordFromFilters copies a field's filter onto a new record only
// when the filter is a single value AND either the field is part of the primary key, the page
// sets PopulateAllFields, or the caller names the filter's group. So what New() puts on a row
// through a part linked to THIS table's "Header No." is the open question, and "PKFL Keyed
// Line" (60643) is the same shape with "Header No." moved into the key so the pair pins the
// rule in both directions.
table 60642 "PKFL Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "Header No."; Code[20]) { }
        field(3; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}
