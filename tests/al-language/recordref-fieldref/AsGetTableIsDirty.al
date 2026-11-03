// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-isdirty-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsFixtures.al (table 79902, helper 79913)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 644, item 4).
// Facts: RecordRef.GetTable(Rec) on a Record that was read and then changed without Modify, changed and set back, or Init; and on a
//   Record that was never read: is RecordRef.IsDirty measured against what the Record read or against the stored row.
// BC versions: 28-29 (RecordRef.IsDirty exists from runtime 17)

#if BC28PLUS
codeunit 79922 "LT AS GetTable IsDirty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT AS Helper";

    [Test]
    procedure ReadThenChanged()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Ref: RecordRef;
    begin
        Helper.SeedRows();
        Row.Get('A');
        Row.Name := 'changed';
        Ref.GetTable(Row);
        Observer.Observe('dirty', Format(Ref.IsDirty()));
        Observer.Observe('name', Format(Ref.Field(2).Value));
        Observer.Expect('dirty', 'Yes');
        Observer.Expect('name', 'changed');
        Observer.Verify();
    end;

    [Test]
    procedure ReadChangedAndSetBack()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Ref: RecordRef;
    begin
        Helper.SeedRows();
        Row.Get('A');
        Row.Name := 'changed';
        Row.Name := 'alpha';
        Ref.GetTable(Row);
        Observer.Observe('dirty', Format(Ref.IsDirty()));
        Observer.Expect('dirty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReadUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Ref: RecordRef;
    begin
        Helper.SeedRows();
        Row.Get('A');
        Ref.GetTable(Row);
        Observer.Observe('dirty', Format(Ref.IsDirty()));
        Observer.Expect('dirty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReadThenInit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Ref: RecordRef;
    begin
        Helper.SeedRows();
        Row.Get('A');
        Row.Init();
        Ref.GetTable(Row);
        Observer.Observe('dirty', Format(Ref.IsDirty()));
        Observer.Observe('name', Format(Ref.Field(2).Value));
        Observer.Expect('dirty', 'Yes');
        Observer.Expect('name', '');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRowChangedAfterRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Other: Record "LT AS Row";
        Ref: RecordRef;
    begin
        Helper.SeedRows();
        Row.Get('A');
        Other.Get('A');
        Other.Name := 'stored';
        Other.Modify();
        Ref.GetTable(Row);
        Observer.Observe('dirty_unchanged', Format(Ref.IsDirty()));
        Row.Name := 'stored';
        Ref.GetTable(Row);
        Observer.Observe('dirty_equal_stored', Format(Ref.IsDirty()));
        Observer.Expect('dirty_unchanged', 'No');
        Observer.Expect('dirty_equal_stored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NeverRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Ref: RecordRef;
    begin
        Helper.SeedRows();
        Row."No." := 'A';
        Row.Name := 'alpha';
        Row.Amount := 1;
        Row.Cd := 'A';
        Ref.GetTable(Row);
        Observer.Observe('dirty_same_as_stored', Format(Ref.IsDirty()));
        Row.Init();
        Ref.GetTable(Row);
        Observer.Observe('dirty_init', Format(Ref.IsDirty()));
        Observer.Expect('dirty_same_as_stored', 'Yes');
        Observer.Expect('dirty_init', 'Yes');
        Observer.Verify();
    end;
}
#endif
