// local object: the field shape, enum members or page layout/trigger definition is the behavior under test.
table 69024 "PAG Layout Row"
{
    DataClassification = CustomerContent;
    fields { field(1; Code; Code[20]) { } field(2; Description; Text[50]) { } }
    keys { key(PK; Code) { Clustered = true; } }
}
