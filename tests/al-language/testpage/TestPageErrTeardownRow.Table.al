table 60796 "TestPage ErrTeardown Row"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; FailOnGet; Boolean) { }
        field(4; FailOnValidate; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
