// Fixture line table for TestPageSubpagePartConstFilter.al. Kind and Status are the fields
// the host's parts pin with const(...) / filter(...); "Table ID" is pinned with
// const(Database::...) so a table-reference constant is covered too, and Category with a
// quoted text constant so a Code-typed const(...) is covered. Status deliberately
// starts with a "None" member that no part's filter selects, so a row created through a
// filter(...)-linked part has an observable "not stamped" value distinct from the first
// selected member.
table 60321 "TSPL Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Kind; Option) { OptionMembers = Comment,Attachment; }
        field(4; Status; Option) { OptionMembers = "None",Open,Released,Closed; }
        field(5; Name; Text[50]) { }
        field(6; "Table ID"; Integer) { }
        field(7; Category; Code[10]) { }
    }

    keys
    {
        key(PK; "Header No.", "Line No.") { Clustered = true; }
    }
}
