// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-requiredtestisolation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (AL Runner issue 7622, "delete-only carry"): a test codeunit whose OnRun trigger only DELETES rows. Does the delete
// reach the next test codeunit? RqIsolationModes.al in this folder measured the same for rows OnRun INSERTS.
//
// Shape: every writer codeunit's OnRun does one delete shape and nothing else; its test observes what the codeunit itself
// sees; the reader codeunit (the next id) observes the same rows. Each group seeds its rows in the OnRun of a seed codeunit
// that runs before the writers (OnRun writes of that seed reach the later codeunits in both groups), plus a <P>-KEEP row
// nobody deletes. Every key has the prefix of its group. The delete shapes (cell numbers of the issue):
//   1 SetFilter + DeleteAll, 2 Get + Delete, 3 Get + Delete + Commit, 4 RecordRef Open + SetView + DeleteAll,
//   5 Delete in an event subscriber that OnRun raises, 7 Insert + DeleteAll on a temporary record (control),
//   8 Truncate without filters. Truncate empties the whole table, so cell 8 uses one table per group ("LT ODC Trunc <P>",
//   rows <P>-TR1 and <P>-TR2 from the group's seed); keep_row of cell 8 is the <P>-KEEP row of "LT ODC Row".
// Groups (see RqIsolationModes.al for the routing of the Linux legs):
//   - Hub group: TestPermissions = Disabled, no handlers. Prefix C: RequiredTestIsolation = Codeunit, F: Function,
//     D: Disabled. Seed "LT ODC Hub Seed" uses Disabled.
//   - 130450 group (prefix W): no TestPermissions property, so the Codeunit test runner runs it on every leg.
//
// Measured on BC 27.5, 28.5 and 29.0 (Linux legs; the hub values below are BC 28 and 29). Cells 1-5 and 7: CI run
// 46089371347 on builds 27.5.54899.59044, 28.5.54976.59048 and 29.0.54011.55816, and local Linux legs on builds
// 27.5.54899.59044, 28.5.54976.59048 and 29.0.54011.59052. Cell 8: local Linux legs on 28.5.54976.59048 and
// 29.0.54011.59052 (identical values); BC 27 and every CI leg: the PR run of the commit that added cell 8.
//   - Inside the writer codeunit, its test sees every OnRun delete (cells 1-5 rows gone, cell 8 table empty) in every group.
//   - Cell 8: Truncate in OnRun raises no error in any group and behaves as a DeleteAll: rolled back for the next codeunit
//     under hub Codeunit and Function isolation, persists under hub Disabled isolation and carries under 130450.
//   - Hub, Codeunit and Function isolation: the next codeunit sees the rows again. The OnRun delete is rolled back with the
//     codeunit, the committed one of cell 3 too.
//   - Hub, Disabled isolation: the next codeunit does not see the rows. The delete persists (cells 1-5).
//   - 130450 runner: the next codeunit does not see the rows. The OnRun delete carries (cells 1-5), as OnRun inserts do.
//   - Cell 7: a DeleteAll on a temporary record never touches the real row (all groups, writer and reader).
//   - BC 27 runs the hub groups under 130450 (CI run 46082141726): there the C and F readers do not see the rows either, the
//     delete carries as in the W group (#else branches). The BC28PLUS guards mark this difference of the test HARNESS, not of
//     the platform, as in RqIsolationModes.al. da2 and rr2 on BC 27 are measured by CI run 46089371347 (Verify compares
//     the whole observation). The cell 8 C and F readers follow the same routing on BC 27 (#else: the W8 values).
// Measured locally, not a test here (it fails the leg): OnRun that deletes and then raises Error. The hub reports a failed
// "OnRun" result with the error text and does not run the codeunit's test; the 130450 runner reports no result for that
// codeunit. In every group the next codeunit sees the row again: the error rolls the delete back. Measured on the local
// Linux legs 27.5.54899.59044, 28.5.54976.59048 and 29.0.54011.59052.
// Object ids 83400-83407, 83410-83474.
// BC versions: 27.5, 28.5, 29.0

table 83400 "LT ODC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// Cell 8: Truncate empties the whole table, so group C has a table of its own.
table 83404 "LT ODC Trunc C"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// Cell 8: Truncate empties the whole table, so group F has a table of its own.
table 83405 "LT ODC Trunc F"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// Cell 8: Truncate empties the whole table, so group D has a table of its own.
table 83406 "LT ODC Trunc D"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// Cell 8: Truncate empties the whole table, so group W has a table of its own.
table 83407 "LT ODC Trunc W"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// Seeds, writers and readers of every group.
codeunit 83401 "LT ODC Probe"
{
    procedure Put(RowKey: Text)
    var
        Row: Record "LT ODC Row";
    begin
        if Row.Get(RowKey) then
            Row.Delete();
        Row."Key" := CopyStr(RowKey, 1, MaxStrLen(Row."Key"));
        Row.Insert();
    end;

    procedure Has(RowKey: Text): Text
    var
        Row: Record "LT ODC Row";
    begin
        exit(Format(Row.Get(RowKey)));
    end;

    // The rows every cell starts from, for the group with prefix P.
    procedure Seed(P: Text)
    begin
        Put(P + '-KEEP');
        Put(P + '-DA1');
        Put(P + '-DA2');
        Put(P + '-D1');
        Put(P + '-CM1');
        Put(P + '-RR1');
        Put(P + '-RR2');
        Put(P + '-EV1');
        Put(P + '-T1');
        PutTrunc(P, P + '-TR1');
        PutTrunc(P, P + '-TR2');
    end;

    // Cell 1: a filtered DeleteAll.
    procedure DeleteAllFiltered(P: Text)
    var
        Row: Record "LT ODC Row";
    begin
        Row.SetFilter("Key", P + '-DA*');
        Row.DeleteAll();
    end;

    // Cell 2: Get, then Delete.
    procedure DeleteOne(P: Text)
    var
        Row: Record "LT ODC Row";
    begin
        if Row.Get(P + '-D1') then
            Row.Delete();
    end;

    // Cell 3: Delete, then Commit.
    procedure DeleteCommit(P: Text)
    var
        Row: Record "LT ODC Row";
    begin
        if Row.Get(P + '-CM1') then
            Row.Delete();
        Commit();
    end;

    // Cell 4: a RecordRef with a view, DeleteAll.
    procedure DeleteRecRef(P: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LT ODC Row");
        RecRef.SetView(StrSubstNo('WHERE(Key=FILTER(%1-RR*))', P));
        RecRef.DeleteAll();
        RecRef.Close();
    end;

    // Cell 7: DeleteAll on a temporary record that holds the key of a real row.
    procedure DeleteTemp(P: Text)
    var
        TempRow: Record "LT ODC Row" temporary;
    begin
        TempRow."Key" := CopyStr(P + '-T1', 1, MaxStrLen(TempRow."Key"));
        TempRow.Insert();
        TempRow.DeleteAll();
    end;

    // Cell 8: puts a row into the truncate table of group P.
    procedure PutTrunc(P: Text; RowKey: Text)
    var
        TruncC: Record "LT ODC Trunc C";
        TruncF: Record "LT ODC Trunc F";
        TruncD: Record "LT ODC Trunc D";
        TruncW: Record "LT ODC Trunc W";
    begin
        case P of
            'C':
                begin
                    if TruncC.Get(RowKey) then
                        TruncC.Delete();
                    TruncC."Key" := CopyStr(RowKey, 1, MaxStrLen(TruncC."Key"));
                    TruncC.Insert();
                end;
            'F':
                begin
                    if TruncF.Get(RowKey) then
                        TruncF.Delete();
                    TruncF."Key" := CopyStr(RowKey, 1, MaxStrLen(TruncF."Key"));
                    TruncF.Insert();
                end;
            'D':
                begin
                    if TruncD.Get(RowKey) then
                        TruncD.Delete();
                    TruncD."Key" := CopyStr(RowKey, 1, MaxStrLen(TruncD."Key"));
                    TruncD.Insert();
                end;
            'W':
                begin
                    if TruncW.Get(RowKey) then
                        TruncW.Delete();
                    TruncW."Key" := CopyStr(RowKey, 1, MaxStrLen(TruncW."Key"));
                    TruncW.Insert();
                end;
        end;
    end;

    procedure HasTrunc(P: Text; RowKey: Text): Text
    var
        TruncC: Record "LT ODC Trunc C";
        TruncF: Record "LT ODC Trunc F";
        TruncD: Record "LT ODC Trunc D";
        TruncW: Record "LT ODC Trunc W";
    begin
        case P of
            'C':
                exit(Format(TruncC.Get(RowKey)));
            'F':
                exit(Format(TruncF.Get(RowKey)));
            'D':
                exit(Format(TruncD.Get(RowKey)));
            'W':
                exit(Format(TruncW.Get(RowKey)));
        end;
    end;

    // Cell 8: Truncate without filters on the truncate table of group P.
    procedure TruncateAll(P: Text)
    var
        TruncC: Record "LT ODC Trunc C";
        TruncF: Record "LT ODC Trunc F";
        TruncD: Record "LT ODC Trunc D";
        TruncW: Record "LT ODC Trunc W";
    begin
        case P of
            'C':
                TruncC.Truncate();
            'F':
                TruncF.Truncate();
            'D':
                TruncD.Truncate();
            'W':
                TruncW.Truncate();
        end;
    end;

    procedure ObserveCell(P: Text; Cell: Integer; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('keep_row', Has(P + '-KEEP'));
        case Cell of
            1:
                begin
                    Observer.Observe('da1_row', Has(P + '-DA1'));
                    Observer.Observe('da2_row', Has(P + '-DA2'));
                end;
            2:
                Observer.Observe('d1_row', Has(P + '-D1'));
            3:
                Observer.Observe('cm1_row', Has(P + '-CM1'));
            4:
                begin
                    Observer.Observe('rr1_row', Has(P + '-RR1'));
                    Observer.Observe('rr2_row', Has(P + '-RR2'));
                end;
            5:
                Observer.Observe('ev1_row', Has(P + '-EV1'));
            7:
                Observer.Observe('t1_row', Has(P + '-T1'));
            8:
                begin
                    Observer.Observe('tr1_row', HasTrunc(P, P + '-TR1'));
                    Observer.Observe('tr2_row', HasTrunc(P, P + '-TR2'));
                end;
        end;
    end;
}

// Cell 5: the writer's OnRun raises this event; "LT ODC Subscriber" deletes the row.
codeunit 83402 "LT ODC Events"
{
    procedure Raise(RowKey: Text)
    begin
        OnDeleteRequested(CopyStr(RowKey, 1, 30));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRequested(RowKey: Code[30])
    begin
    end;
}

codeunit 83403 "LT ODC Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT ODC Events", 'OnDeleteRequested', '', false, false)]
    local procedure DeleteRequested(RowKey: Code[30])
    var
        Row: Record "LT ODC Row";
    begin
        if Row.Get(RowKey) then
            Row.Delete();
    end;
}


// Hub group (BC 28+: TestPermissions = Disabled, no handlers). Seeds in OnRun under Disabled isolation, which persists.
codeunit 83410 "LT ODC Hub Seed"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.Seed('C');
        Probe.Seed('F');
        Probe.Seed('D');
    end;

    [Test]
    procedure ODC_Hub00_SeedRuns()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('c_keep_row', Probe.Has('C-KEEP'));
        Observer.Observe('f_keep_row', Probe.Has('F-KEEP'));
        Observer.Observe('d_keep_row', Probe.Has('D-KEEP'));
        Observer.Expect('c_keep_row', 'Yes');
        Observer.Expect('f_keep_row', 'Yes');
        Observer.Expect('d_keep_row', 'Yes');
        Observer.Verify();
    end;
}

// Hub group, RequiredTestIsolation = Codeunit.

codeunit 83411 "LT ODC C1 DeleteAll Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteAllFiltered('C');
    end;

    [Test]
    procedure ODC_C1_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 1, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('da1_row', 'No');
        Observer.Expect('da2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83412 "LT ODC C1 DeleteAll Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure ODC_C1_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 1, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('da1_row', 'Yes');
        Observer.Expect('da2_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('da1_row', 'No');
        Observer.Expect('da2_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 83413 "LT ODC C2 Delete Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteOne('C');
    end;

    [Test]
    procedure ODC_C2_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 2, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('d1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83414 "LT ODC C2 Delete Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure ODC_C2_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 2, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('d1_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('d1_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 83415 "LT ODC C3 Commit Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteCommit('C');
    end;

    [Test]
    procedure ODC_C3_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 3, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('cm1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83416 "LT ODC C3 Commit Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure ODC_C3_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 3, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('cm1_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('cm1_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 83417 "LT ODC C4 RecRef Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteRecRef('C');
    end;

    [Test]
    procedure ODC_C4_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 4, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('rr1_row', 'No');
        Observer.Expect('rr2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83418 "LT ODC C4 RecRef Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure ODC_C4_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 4, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('rr1_row', 'Yes');
        Observer.Expect('rr2_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('rr1_row', 'No');
        Observer.Expect('rr2_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 83419 "LT ODC C5 Event Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    trigger OnRun()
    var
        Events: Codeunit "LT ODC Events";
    begin
        Events.Raise('C-EV1');
    end;

    [Test]
    procedure ODC_C5_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 5, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('ev1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83420 "LT ODC C5 Event Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure ODC_C5_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 5, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('ev1_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('ev1_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 83421 "LT ODC C7 Temp Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteTemp('C');
    end;

    [Test]
    procedure ODC_C7_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 7, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('t1_row', 'Yes');
        Observer.Verify();
    end;
}

codeunit 83422 "LT ODC C7 Temp Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure ODC_C7_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 7, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('t1_row', 'Yes');
        Observer.Verify();
    end;
}

codeunit 83423 "LT ODC C8 Truncate Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.TruncateAll('C');
    end;

    [Test]
    procedure ODC_C8_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 8, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('tr1_row', 'No');
        Observer.Expect('tr2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83424 "LT ODC C8 Truncate Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure ODC_C8_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('C', 8, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('tr1_row', 'Yes');
        Observer.Expect('tr2_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('tr1_row', 'No');
        Observer.Expect('tr2_row', 'No');
#endif
        Observer.Verify();
    end;
}

// Hub group, RequiredTestIsolation = Function.

codeunit 83425 "LT ODC F1 DeleteAll Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteAllFiltered('F');
    end;

    [Test]
    procedure ODC_F1_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 1, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('da1_row', 'No');
        Observer.Expect('da2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83426 "LT ODC F1 DeleteAll Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    [Test]
    procedure ODC_F1_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 1, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('da1_row', 'Yes');
        Observer.Expect('da2_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('da1_row', 'No');
        Observer.Expect('da2_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 83427 "LT ODC F2 Delete Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteOne('F');
    end;

    [Test]
    procedure ODC_F2_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 2, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('d1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83428 "LT ODC F2 Delete Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    [Test]
    procedure ODC_F2_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 2, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('d1_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('d1_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 83429 "LT ODC F3 Commit Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteCommit('F');
    end;

    [Test]
    procedure ODC_F3_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 3, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('cm1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83430 "LT ODC F3 Commit Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    [Test]
    procedure ODC_F3_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 3, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('cm1_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('cm1_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 83431 "LT ODC F4 RecRef Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteRecRef('F');
    end;

    [Test]
    procedure ODC_F4_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 4, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('rr1_row', 'No');
        Observer.Expect('rr2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83432 "LT ODC F4 RecRef Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    [Test]
    procedure ODC_F4_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 4, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('rr1_row', 'Yes');
        Observer.Expect('rr2_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('rr1_row', 'No');
        Observer.Expect('rr2_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 83433 "LT ODC F5 Event Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    var
        Events: Codeunit "LT ODC Events";
    begin
        Events.Raise('F-EV1');
    end;

    [Test]
    procedure ODC_F5_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 5, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('ev1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83434 "LT ODC F5 Event Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    [Test]
    procedure ODC_F5_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 5, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('ev1_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('ev1_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 83435 "LT ODC F7 Temp Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteTemp('F');
    end;

    [Test]
    procedure ODC_F7_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 7, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('t1_row', 'Yes');
        Observer.Verify();
    end;
}

codeunit 83436 "LT ODC F7 Temp Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    [Test]
    procedure ODC_F7_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 7, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('t1_row', 'Yes');
        Observer.Verify();
    end;
}

codeunit 83437 "LT ODC F8 Truncate Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.TruncateAll('F');
    end;

    [Test]
    procedure ODC_F8_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 8, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('tr1_row', 'No');
        Observer.Expect('tr2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83438 "LT ODC F8 Truncate Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    [Test]
    procedure ODC_F8_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('F', 8, Observer);
#if BC28PLUS
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('tr1_row', 'Yes');
        Observer.Expect('tr2_row', 'Yes');
#else
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('tr1_row', 'No');
        Observer.Expect('tr2_row', 'No');
#endif
        Observer.Verify();
    end;
}

// Hub group, RequiredTestIsolation = Disabled.

codeunit 83439 "LT ODC D1 DeleteAll Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteAllFiltered('D');
    end;

    [Test]
    procedure ODC_D1_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 1, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('da1_row', 'No');
        Observer.Expect('da2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83440 "LT ODC D1 DeleteAll Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure ODC_D1_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 1, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('da1_row', 'No');
        Observer.Expect('da2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83441 "LT ODC D2 Delete Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteOne('D');
    end;

    [Test]
    procedure ODC_D2_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 2, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('d1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83442 "LT ODC D2 Delete Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure ODC_D2_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 2, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('d1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83443 "LT ODC D3 Commit Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteCommit('D');
    end;

    [Test]
    procedure ODC_D3_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 3, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('cm1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83444 "LT ODC D3 Commit Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure ODC_D3_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 3, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('cm1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83445 "LT ODC D4 RecRef Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteRecRef('D');
    end;

    [Test]
    procedure ODC_D4_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 4, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('rr1_row', 'No');
        Observer.Expect('rr2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83446 "LT ODC D4 RecRef Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure ODC_D4_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 4, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('rr1_row', 'No');
        Observer.Expect('rr2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83447 "LT ODC D5 Event Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    trigger OnRun()
    var
        Events: Codeunit "LT ODC Events";
    begin
        Events.Raise('D-EV1');
    end;

    [Test]
    procedure ODC_D5_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 5, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('ev1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83448 "LT ODC D5 Event Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure ODC_D5_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 5, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('ev1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83449 "LT ODC D7 Temp Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteTemp('D');
    end;

    [Test]
    procedure ODC_D7_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 7, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('t1_row', 'Yes');
        Observer.Verify();
    end;
}

codeunit 83450 "LT ODC D7 Temp Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure ODC_D7_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 7, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('t1_row', 'Yes');
        Observer.Verify();
    end;
}

codeunit 83451 "LT ODC D8 Truncate Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.TruncateAll('D');
    end;

    [Test]
    procedure ODC_D8_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 8, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('tr1_row', 'No');
        Observer.Expect('tr2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83452 "LT ODC D8 Truncate Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure ODC_D8_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('D', 8, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('tr1_row', 'No');
        Observer.Expect('tr2_row', 'No');
        Observer.Verify();
    end;
}

// 130450 group (no TestPermissions = Disabled: the Codeunit test runner on every leg). OnRun inserts carry (RqIsolationModes.al).
codeunit 83460 "LT ODC W Seed"
{
    Subtype = Test;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.Seed('W');
    end;

    [Test]
    procedure ODC_W00_SeedRuns()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('w_keep_row', Probe.Has('W-KEEP'));
        Observer.Expect('w_keep_row', 'Yes');
        Observer.Verify();
    end;
}

codeunit 83461 "LT ODC W1 DeleteAll Writer"
{
    Subtype = Test;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteAllFiltered('W');
    end;

    [Test]
    procedure ODC_W1_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 1, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('da1_row', 'No');
        Observer.Expect('da2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83462 "LT ODC W1 DeleteAll Reader"
{
    Subtype = Test;

    [Test]
    procedure ODC_W1_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 1, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('da1_row', 'No');
        Observer.Expect('da2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83463 "LT ODC W2 Delete Writer"
{
    Subtype = Test;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteOne('W');
    end;

    [Test]
    procedure ODC_W2_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 2, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('d1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83464 "LT ODC W2 Delete Reader"
{
    Subtype = Test;

    [Test]
    procedure ODC_W2_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 2, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('d1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83465 "LT ODC W3 Commit Writer"
{
    Subtype = Test;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteCommit('W');
    end;

    [Test]
    procedure ODC_W3_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 3, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('cm1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83466 "LT ODC W3 Commit Reader"
{
    Subtype = Test;

    [Test]
    procedure ODC_W3_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 3, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('cm1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83467 "LT ODC W4 RecRef Writer"
{
    Subtype = Test;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteRecRef('W');
    end;

    [Test]
    procedure ODC_W4_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 4, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('rr1_row', 'No');
        Observer.Expect('rr2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83468 "LT ODC W4 RecRef Reader"
{
    Subtype = Test;

    [Test]
    procedure ODC_W4_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 4, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('rr1_row', 'No');
        Observer.Expect('rr2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83469 "LT ODC W5 Event Writer"
{
    Subtype = Test;

    trigger OnRun()
    var
        Events: Codeunit "LT ODC Events";
    begin
        Events.Raise('W-EV1');
    end;

    [Test]
    procedure ODC_W5_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 5, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('ev1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83470 "LT ODC W5 Event Reader"
{
    Subtype = Test;

    [Test]
    procedure ODC_W5_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 5, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('ev1_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83471 "LT ODC W7 Temp Writer"
{
    Subtype = Test;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.DeleteTemp('W');
    end;

    [Test]
    procedure ODC_W7_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 7, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('t1_row', 'Yes');
        Observer.Verify();
    end;
}

codeunit 83472 "LT ODC W7 Temp Reader"
{
    Subtype = Test;

    [Test]
    procedure ODC_W7_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 7, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('t1_row', 'Yes');
        Observer.Verify();
    end;
}

codeunit 83473 "LT ODC W8 Truncate Writer"
{
    Subtype = Test;

    trigger OnRun()
    var
        Probe: Codeunit "LT ODC Probe";
    begin
        Probe.TruncateAll('W');
    end;

    [Test]
    procedure ODC_W8_WriterSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 8, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('tr1_row', 'No');
        Observer.Expect('tr2_row', 'No');
        Observer.Verify();
    end;
}

codeunit 83474 "LT ODC W8 Truncate Reader"
{
    Subtype = Test;

    [Test]
    procedure ODC_W8_ReaderSees()
    var
        Probe: Codeunit "LT ODC Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveCell('W', 8, Observer);
        Observer.Expect('keep_row', 'Yes');
        Observer.Expect('tr1_row', 'No');
        Observer.Expect('tr2_row', 'No');
        Observer.Verify();
    end;
}
