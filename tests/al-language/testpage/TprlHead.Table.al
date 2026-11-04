// Fixture host table for TestPageActionRunPageLink.al: the "one" side of a header/line shape
// an action's RunPageLink filters the "many" side by.
table 60462 "TPRL Head"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
