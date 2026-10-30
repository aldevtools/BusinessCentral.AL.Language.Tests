// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-locktable-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 90644, table 90645
// Probe: written against al-runner issue 6312 (RecordRef.LockTable); every value asserted below is what the BC service tier produced.
// Facts: IsInWriteTransaction after RecordRef.LockTable and LockTable(true/false) on an open RecordRef of a database table and of a temporary one,
//        and RecordRef.LockTable on a RecordRef that was never opened, was opened with table 0, or was closed again.
// BC versions: 27, 28, 29

table 90645 "LT WC Lock Entry"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 90644 "LT WC RecordRef Lock Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tx(): Text
    begin
        exit(Format(IsInWriteTransaction()));
    end;

    [Test]
    procedure WC_RecordRef_LockTable_WriteTransaction()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Commit();
        Observer.Observe('start', Tx());
        RecRef.Open(Database::"LT WC Lock Entry");
        Observer.Observe('after open', Tx());
        RecRef.LockTable();
        Observer.Observe('after LockTable', Tx());
        if RecRef.FindFirst() then;
        Observer.Observe('after read', Tx());
        Commit();
        Observer.Observe('after commit', Tx());
        Observer.Finish();
    end;

    [Test]
    procedure WC_RecordRef_LockTable_False()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Commit();
        RecRef.Open(Database::"LT WC Lock Entry");
        asserterror RecRef.LockTable(false);
        Observer.ObserveError('LockTable(false)');
        Observer.Observe('after LockTable(false)', Tx());
        Commit();
        RecRef.LockTable(true);
        Observer.Observe('after LockTable(true)', Tx());
        Commit();
        Observer.Observe('after commit', Tx());
        Observer.Finish();
    end;

    [Test]
    procedure WC_RecordRef_LockTable_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Commit();
        RecRef.Open(Database::"LT WC Lock Entry", true);
        RecRef.LockTable();
        Observer.Observe('after temporary LockTable', Tx());
        Observer.Finish();
    end;

    [Test]
    procedure WC_RecordRef_LockTable_NotOpen()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Commit();
        asserterror RecRef.LockTable();
        Observer.ObserveError('never opened');
        Observer.Observe('tx after never opened', Tx());
        asserterror RecRef.LockTable(true);
        Observer.ObserveError('never opened true');
        Observer.Finish();
    end;

    [Test]
    procedure WC_RecordRef_LockTable_TableZeroAndClosed()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Commit();
        RecRef.Open(0);
        asserterror RecRef.LockTable();
        Observer.ObserveError('table zero');
        asserterror RecRef.LockTable(true);
        Observer.ObserveError('table zero true');
        Observer.Observe('tx after table zero', Tx());
        RecRef.Open(Database::"LT WC Lock Entry");
        RecRef.Close();
        asserterror RecRef.LockTable();
        Observer.ObserveError('closed again');
        Observer.Observe('tx after closed', Tx());
        Observer.Finish();
    end;
}
