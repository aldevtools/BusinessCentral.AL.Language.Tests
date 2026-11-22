// Live table of cross-app fixture A whose Moved stub (same id, name and fields, ObsoleteState = Moved, MovedTo = this app) is in
// cross-app fixture B (MvXbMovedStub.al): the shape of Base Application's stubs of tables that moved to Business Foundation.
// Test: tests/al-language/table-objects/moved-tables/MvMovedTableTests.al (al-runner issue 7914).
// local object: the owner app of the table is under test.

table 61178 "LT MV XA Probe Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
