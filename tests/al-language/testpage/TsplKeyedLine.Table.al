// Fixture line table for TestPageSubpagePartConstFilter.al, identical in shape to
// "TSPL Line" (60321) EXCEPT that Kind is part of the PRIMARY KEY. That one difference is
// the whole point: BC's RecordImplementation.InitRecordFromFilters copies a field's filter
// onto a new record only when the filter is a single value AND the field is part of the
// primary key (or the page sets PopulateAllFields, or the caller names the filter's group --
// NavForm.NewRecord passes no groups). So a const(...) SubPageLink on THIS table's Kind is
// stamped by New() while the same link on "TSPL Line"'s Kind is not, and the pair pins the
// rule in both directions.
table 60325 "TSPL Keyed Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header No."; Code[20]) { }
        field(2; Kind; Option) { OptionMembers = Comment,Attachment; }
        field(3; "Line No."; Integer) { }
        field(4; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Header No.", Kind, "Line No.") { Clustered = true; }
    }
}
