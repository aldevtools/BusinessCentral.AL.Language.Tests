// Fixture for TestPageModalQueryClose_Tests.al.
/// <summary>
/// Ordered observation sink. The pages under test append one row per close-lifecycle trigger
/// they see, so a test can assert the exact SEQUENCE of triggers — which is the claim here,
/// not merely that each one ran at some point.
/// </summary>
table 60271 "MQC Trace"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Event"; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    procedure Log(Ev: Text[50])
    var
        Trace: Record "MQC Trace";
    begin
        Trace.Init();
        Trace."Event" := Ev;
        Trace.Insert();
    end;

    procedure Events(): Text
    var
        Trace: Record "MQC Trace";
        Result: Text;
    begin
        if Trace.FindSet() then
            repeat
                Result += Trace."Event" + ';';
            until Trace.Next() = 0;
        exit(Result);
    end;
}
