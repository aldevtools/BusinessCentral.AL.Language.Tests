// Fixture table for TestPageBgTask_Tests.al's temporary-write probes. TableType = Temporary
// means every Record variable of this table is temporary whether or not the AL author wrote
// `temporary` on the variable -- so a write to it is a session-memory write, never a database
// write, and the read-only-session refusal the WriteWorker measures cannot apply to it.

table 60783 "Test Page BgTask Temp Row"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
