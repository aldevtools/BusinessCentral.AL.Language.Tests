// local object: the field shape, enum members or page layout/trigger definition is the behavior under test.
table 69038 "TPG Empty Line"
{
    DataClassification = CustomerContent;
    fields { field(1; "Header Code"; Code[20]) { } field(2; "Line No."; Integer) { } field(3; Description; Text[50]) { } }
    keys { key(PK; "Header Code", "Line No.") { Clustered = true; } }
}
