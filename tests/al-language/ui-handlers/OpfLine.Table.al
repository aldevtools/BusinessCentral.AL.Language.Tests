// Fixture for "Opf Ok Part Flush Tests" (60663): the rows a [ModalPageHandler] types into
// "Opf Lines Part" (60639). Temporary-sourced on the part, so nothing here reaches the database.
table 60637 "Opf Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "Value"; Text[30]) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}
