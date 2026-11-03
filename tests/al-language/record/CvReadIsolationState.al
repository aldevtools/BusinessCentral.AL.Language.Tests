// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-read-isolation
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 85370
// Facts: corpus issue 670 (odd AL behavior leads, part E): the Record.ReadIsolation getter after Reset, Init, LockTable, Clear, Copy,
//   record assignment and TransferFields, and a CalcFields of a FlowField on a record instance with ReadUncommitted after another
//   instance took LockTable. What the lock does to a second session is not run here (it needs two sessions).
// Probe: values observed on a local BC 29.0 tier; 27.5 and 28.5 checked by the corpus CI.
// BC versions: 27, 28, 29
table 85370 "LT CV Iso Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { }
        field(3; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT CV Iso Row".Amount);
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 85370 "LT CV Read Isolation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure GetterAfterRecordOperations()
    var
        Rec: Record "LT CV Iso Row";
        Other: Record "LT CV Iso Row";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.ReadIsolation := IsolationLevel::ReadUncommitted;
        Rec.Reset();
        Observer.Observe('after_reset', Format(Rec.ReadIsolation));
        Rec.ReadIsolation := IsolationLevel::ReadUncommitted;
        Rec.Init();
        Observer.Observe('after_init', Format(Rec.ReadIsolation));
        Rec.LockTable();
        Observer.Observe('after_locktable', Format(Rec.ReadIsolation));
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
        Other.Copy(Rec);
        Observer.Observe('copy|target', Format(Other.ReadIsolation));
        Clear(Other);
        Rec.ReadIsolation := IsolationLevel::RepeatableRead;
        Other := Rec;
        Observer.Observe('assign|target', Format(Other.ReadIsolation));
        Clear(Other);
        Other.TransferFields(Rec);
        Observer.Observe('transferfields|target', Format(Other.ReadIsolation));
        Clear(Rec);
        Observer.Observe('after_clear', Format(Rec.ReadIsolation));
        Observer.Expect('after_reset', 'Default');
        Observer.Expect('after_init', 'ReadUncommitted');
        Observer.Expect('after_locktable', 'Default');
        Observer.Expect('copy|target', 'ReadCommitted');
        Observer.Expect('assign|target', 'Default');
        Observer.Expect('transferfields|target', 'Default');
        Observer.Expect('after_clear', 'Default');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFieldsWithReadUncommittedAfterLockTable()
    var
        Locker: Record "LT CV Iso Row";
        Curr: Record "LT CV Iso Row";
        Observer: Codeunit "Probe Observer";
    begin
        Locker.DeleteAll();
        Locker.Id := 1;
        Locker.Amount := 2.5;
        Locker.Insert();
        Locker.Id := 2;
        Locker.Amount := 4;
        Locker.Insert();
        Locker.LockTable();
        Curr.ReadIsolation := IsolationLevel::ReadUncommitted;
        Curr.Get(1);
        Curr.CalcFields(Total);
        Observer.Observe('total', Format(Curr.Total));
        Observer.Observe('curr_iso', Format(Curr.ReadIsolation));
        Observer.Observe('locker_iso', Format(Locker.ReadIsolation));
        Observer.Expect('total', '6.5');
        Observer.Expect('curr_iso', 'ReadUncommitted');
        Observer.Expect('locker_iso', 'Default');
        Observer.Verify();
    end;
}
