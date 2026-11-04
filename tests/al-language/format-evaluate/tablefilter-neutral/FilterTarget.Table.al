// local object: the field shape, enum members or page layout/trigger definition is the behavior under test.
table 69006 "FMT Filter Target"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Cost Type"; Enum "FMT Cost Kind") { }
        field(3; "Config Type"; Enum "FMT Config Kind") { }
        field(4; "Employee No."; Code[20]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
