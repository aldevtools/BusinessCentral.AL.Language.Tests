// Fixture for "Test Event Quoted Name" (67046): a table whose own code publishes an
// integration event with a quoted name containing spaces.
table 67043 "QEvt Publisher Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    procedure RaiseTableSpaced(var Log: Text)
    begin
        "On Table Quoted"(Log);
    end;

    [IntegrationEvent(false, false)]
    local procedure "On Table Quoted"(var Log: Text)
    begin
    end;
}
