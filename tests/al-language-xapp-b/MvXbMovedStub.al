// Moved stub of cross-app fixture A's table 61178 (MvXaLiveTable.al): same id, name and fields, ObsoleteState = Moved and
// MovedTo = fixture A's app id. Fixture B depends on A, as Base Application depends on Business Foundation for its stubs of tables
// 231, 308, 309, 310 and 1263. Test: tests/al-language/table-objects/moved-tables/MvMovedTableTests.al (al-runner issue 7914).
// local object: the Moved stub itself is under test.

table 61178 "LT MV XA Probe Row"
{
    DataClassification = SystemMetadata;
    ObsoleteState = Moved;
    ObsoleteReason = 'Moved to AL Language XApp A';
    ObsoleteTag = '1.0';
    MovedTo = 'cd6a4292-f27b-4af9-89bc-15a5956f5c71';

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
