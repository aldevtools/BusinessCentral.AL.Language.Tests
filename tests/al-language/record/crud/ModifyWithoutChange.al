// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 74971, log 74972, test codeunit 74973; writer QD: table 86510, manual subscriber codeunits 86511 and 86512 (ModifyAll over a row that has the value, with and without modify subscribers)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Modify() on a record with no field changed: whether SystemRowVersion changes (in the variable after the call and when the row is read again), whether the OnModify trigger runs, and whether xRec equals Rec in it; Modify(true), Modify(false) and ModifyAll with the same value; Modify with one field changed. Row versions are compared with each other, never asserted as numbers. ModifyAll with the same value is asserted for its trace only: whether it changes the row version differs between the local container (unchanged) and the CI container (changed), so the row version is not asserted for it.
// Writer QF: tables 86647 (no trigger) and 86648 (OnModify trigger), with no modify-event subscriber declared anywhere; tests QF_* in 74973.
//   Result: ModifyAll(Qty, 5, false) writes in bulk: the row that already had Qty 5 gets a new SystemModifiedAt and SystemRowVersion on both
//   tables, and the OnModify trigger does not run.
// BC versions: 29 (27 and 28 by CI)

table 74971 "LT MW Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnModify()
    var
        L: Codeunit "LT MW Log";
    begin
        L.Add('OnModify rec=' + Rec.Name + '/' + Format(Rec.Qty) + ' xrec=' + xRec.Name + '/' + Format(xRec.Qty));
    end;
}

codeunit 74972 "LT MW Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 74973 "LT Modify Without Change"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT MW Row";
        Other: Record "LT MW Row";
    begin
        Row.DeleteAll();
        Row.Id := 1; Row.Name := 'one'; Row.Qty := 5; Row.Insert();
        Other.Id := 2; Other.Name := 'two'; Other.Qty := 6; Other.Insert();
    end;

    local procedure Version(Id: Integer): BigInteger
    var
        Row: Record "LT MW Row";
    begin
        Row.Get(Id);
        exit(Row.SystemRowVersion);
    end;

    [Test]
    procedure Modify_NoFieldChanged_RowVersionAndTrigger()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        L.Take();
        Row.Get(1);
        Row.Modify();
        Observer.Observe('db_version_same', Format(Version(1) = Before));
        Observer.Observe('db_version_greater', Format(Version(1) > Before));
        Observer.Observe('var_version_same', Format(Row.SystemRowVersion = Before));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_same', 'Yes');
        Observer.Expect('db_version_greater', 'No');
        Observer.Expect('var_version_same', 'Yes');
        Observer.Expect('trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_RunTriggerTrue_NoFieldChanged()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        L.Take();
        Row.Get(1);
        Row.Modify(true);
        Observer.Observe('db_version_same', Format(Version(1) = Before));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_same', 'Yes');
        Observer.Expect('trace', 'OnModify rec=one/5 xrec=one/5;');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_RunTriggerFalse_NoFieldChanged()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        L.Take();
        Row.Get(1);
        Row.Modify(false);
        Observer.Observe('db_version_same', Format(Version(1) = Before));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_same', 'Yes');
        Observer.Expect('trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_FieldAssignedSameValue()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        L.Take();
        Row.Get(1);
        Row.Name := 'one';
        Row.Qty := 5;
        Row.Modify();
        Observer.Observe('db_version_same', Format(Version(1) = Before));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_same', 'Yes');
        Observer.Expect('trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_OneFieldChanged()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Other: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        Other := Version(2);
        L.Take();
        Row.Get(1);
        Row.Qty := 7;
        Row.Modify();
        Observer.Observe('db_version_same', Format(Version(1) = Before));
        Observer.Observe('db_version_greater', Format(Version(1) > Before));
        Observer.Observe('var_version_equals_db', Format(Row.SystemRowVersion = Version(1)));
        Observer.Observe('other_row_same', Format(Version(2) = Other));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_same', 'No');
        Observer.Expect('db_version_greater', 'Yes');
        Observer.Expect('var_version_equals_db', 'Yes');
        Observer.Expect('other_row_same', 'Yes');
        Observer.Expect('trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_TwiceWithoutChange_AfterRealChange()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Changed: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get(1);
        Row.Qty := 7;
        Row.Modify();
        Changed := Version(1);
        L.Take();
        Row.Modify();
        Observer.Observe('second_modify_same', Format(Version(1) = Changed));
        Row.Get(1);
        Row.Modify();
        Observer.Observe('reread_modify_same', Format(Version(1) = Changed));
        Observer.Observe('trace', L.Take());
        Observer.Expect('second_modify_same', 'Yes');
        Observer.Expect('reread_modify_same', 'Yes');
        Observer.Expect('trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_SameValue_And_NewValue()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before1: BigInteger;
        Before2: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before1 := Version(1);
        Before2 := Version(2);
        L.Take();
        Row.SetRange(Id, 1);
        Row.ModifyAll(Qty, 5);
        Observer.Observe('same_value_trace', L.Take());
        Row.ModifyAll(Qty, 5, true);
        Observer.Observe('same_value_trigger_trace', L.Take());
        Row.ModifyAll(Qty, 9);
        Observer.Observe('new_value_row1_same', Format(Version(1) = Before1));
        Observer.Observe('new_value_row2_same', Format(Version(2) = Before2));
        Observer.Observe('new_value_trace', L.Take());
        Observer.Expect('same_value_trace', '');
        Observer.Expect('same_value_trigger_trace', 'OnModify rec=one/5 xrec=one/5;');
        Observer.Expect('new_value_row1_same', 'No');
        Observer.Expect('new_value_row2_same', 'Yes');
        Observer.Expect('new_value_trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_RunTriggerTrue_OneFieldChanged()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        L.Take();
        Row.Get(1);
        Row.Qty := 7;
        Row.Modify(true);
        Observer.Observe('db_version_greater', Format(Version(1) > Before));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_greater', 'Yes');
        Observer.Expect('trace', 'OnModify rec=one/7 xrec=one/7;');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_NewValue_RunTriggerTrue()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before1: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before1 := Version(1);
        L.Take();
        Row.SetRange(Id, 1);
        Row.ModifyAll(Qty, 9, true);
        Observer.Observe('row1_greater', Format(Version(1) > Before1));
        Observer.Observe('trace', L.Take());
        Observer.Expect('row1_greater', 'Yes');
        Observer.Expect('trace', 'OnModify rec=one/9 xrec=one/9;');
        Observer.Verify();
    end;

    // Writer QD (al-runtime-rs assumption modifyall-with-events-unchanged-row): ModifyAll(Qty, 5, false) over two rows of a table without
    // triggers, row 1 already has Qty 5 and row 2 has 6: SystemModifiedAt and SystemRowVersion of each row before and after, with no
    // subscriber bound, with an OnAfterModifyEvent subscriber bound and with an OnBeforeModifyEvent subscriber bound.
    local procedure QdModifyAllSame(Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "LT QD MW Sub Row";
        L: Codeunit "LT MW Log";
        Stamp1: DateTime;
        Stamp2: DateTime;
        Version1: BigInteger;
        Version2: BigInteger;
    begin
        Row.DeleteAll();
        Row.Id := 1; Row.Qty := 5; Row.Insert();
        Row.Id := 2; Row.Qty := 6; Row.Insert();
        Row.Get(1); Stamp1 := Row.SystemModifiedAt; Version1 := Row.SystemRowVersion;
        Row.Get(2); Stamp2 := Row.SystemModifiedAt; Version2 := Row.SystemRowVersion;
        L.Take();
        Sleep(50);
        Row.Reset();
        Row.ModifyAll(Qty, 5, false);
        Observer.Observe(Prefix + '_trace', L.Take());
        Row.Get(1);
        Observer.Observe(Prefix + '_row1_stamp_changed', Format(Row.SystemModifiedAt <> Stamp1));
        Observer.Observe(Prefix + '_row1_version_changed', Format(Row.SystemRowVersion <> Version1));
        Row.Get(2);
        Observer.Observe(Prefix + '_row2_qty', Format(Row.Qty));
        Observer.Observe(Prefix + '_row2_stamp_changed', Format(Row.SystemModifiedAt <> Stamp2));
        Observer.Observe(Prefix + '_row2_version_changed', Format(Row.SystemRowVersion <> Version2));
    end;

    [Test]
    procedure QD_ModifyAll_SameValue_NoSubscriber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QdModifyAllSame('none', Observer);
        Observer.Expect('none_trace', '');
        Observer.Expect('none_row1_stamp_changed', 'No');
        Observer.Expect('none_row1_version_changed', 'No');
        Observer.Expect('none_row2_qty', '5');
        Observer.Expect('none_row2_stamp_changed', 'Yes');
        Observer.Expect('none_row2_version_changed', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QD_ModifyAll_SameValue_AfterModifySubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Subs: Codeunit "LT QD MW After Subs";
    begin
        BindSubscription(Subs);
        QdModifyAllSame('after', Observer);
        UnbindSubscription(Subs);
        Observer.Expect('after_trace', 'after 1 rec=5 xrec=5;after 2 rec=5 xrec=5;');
        Observer.Expect('after_row1_stamp_changed', 'No');
        Observer.Expect('after_row1_version_changed', 'No');
        Observer.Expect('after_row2_qty', '5');
        Observer.Expect('after_row2_stamp_changed', 'Yes');
        Observer.Expect('after_row2_version_changed', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QD_ModifyAll_SameValue_BeforeModifySubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Subs: Codeunit "LT QD MW Before Subs";
    begin
        BindSubscription(Subs);
        QdModifyAllSame('before', Observer);
        UnbindSubscription(Subs);
        Observer.Expect('before_trace', 'before 1 rec=5 xrec=5;before 2 rec=5 xrec=5;');
        Observer.Expect('before_row1_stamp_changed', 'No');
        Observer.Expect('before_row1_version_changed', 'No');
        Observer.Expect('before_row2_qty', '5');
        Observer.Expect('before_row2_stamp_changed', 'Yes');
        Observer.Expect('before_row2_version_changed', 'Yes');
        Observer.Verify();
    end;

    // Writer QF (al-runtime-rs assumption modifyall-bulk-unchanged-row-version): ModifyAll(Qty, 5, false) over two rows of a table with NO
    // modify-event subscriber declared anywhere, row 1 already has Qty 5 and row 2 has 6: SystemModifiedAt and SystemRowVersion of each
    // row, on a table without triggers (86647) and on one with an OnModify trigger (86648).
    [Test]
    procedure QF_ModifyAll_SameValue_NoSubscriberDeclared_NoTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QF MW Plain Row";
        L: Codeunit "LT MW Log";
        Stamp1: DateTime;
        Stamp2: DateTime;
        Version1: BigInteger;
        Version2: BigInteger;
    begin
        Row.DeleteAll();
        Row.Id := 1; Row.Qty := 5; Row.Insert();
        Row.Id := 2; Row.Qty := 6; Row.Insert();
        Row.Get(1); Stamp1 := Row.SystemModifiedAt; Version1 := Row.SystemRowVersion;
        Row.Get(2); Stamp2 := Row.SystemModifiedAt; Version2 := Row.SystemRowVersion;
        L.Take();
        Sleep(50);
        Row.Reset();
        Row.ModifyAll(Qty, 5, false);
        Observer.Observe('trace', L.Take());
        Row.Get(1);
        Observer.Observe('row1_qty', Format(Row.Qty));
        Observer.Observe('row1_stamp_changed', Format(Row.SystemModifiedAt <> Stamp1));
        Observer.Observe('row1_version_changed', Format(Row.SystemRowVersion <> Version1));
        Row.Get(2);
        Observer.Observe('row2_qty', Format(Row.Qty));
        Observer.Observe('row2_stamp_changed', Format(Row.SystemModifiedAt <> Stamp2));
        Observer.Observe('row2_version_changed', Format(Row.SystemRowVersion <> Version2));
        Observer.Expect('trace', '');
        Observer.Expect('row1_qty', '5');
        Observer.Expect('row1_stamp_changed', 'Yes');
        Observer.Expect('row1_version_changed', 'Yes');
        Observer.Expect('row2_qty', '5');
        Observer.Expect('row2_stamp_changed', 'Yes');
        Observer.Expect('row2_version_changed', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QF_ModifyAll_SameValue_NoSubscriberDeclared_OnModifyTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QF MW Trg Row";
        L: Codeunit "LT MW Log";
        Stamp1: DateTime;
        Stamp2: DateTime;
        Version1: BigInteger;
        Version2: BigInteger;
    begin
        Row.DeleteAll();
        Row.Id := 1; Row.Qty := 5; Row.Insert();
        Row.Id := 2; Row.Qty := 6; Row.Insert();
        Row.Get(1); Stamp1 := Row.SystemModifiedAt; Version1 := Row.SystemRowVersion;
        Row.Get(2); Stamp2 := Row.SystemModifiedAt; Version2 := Row.SystemRowVersion;
        L.Take();
        Sleep(50);
        Row.Reset();
        Row.ModifyAll(Qty, 5, false);
        Observer.Observe('trace', L.Take());
        Row.Get(1);
        Observer.Observe('row1_qty', Format(Row.Qty));
        Observer.Observe('row1_stamp_changed', Format(Row.SystemModifiedAt <> Stamp1));
        Observer.Observe('row1_version_changed', Format(Row.SystemRowVersion <> Version1));
        Row.Get(2);
        Observer.Observe('row2_qty', Format(Row.Qty));
        Observer.Observe('row2_stamp_changed', Format(Row.SystemModifiedAt <> Stamp2));
        Observer.Observe('row2_version_changed', Format(Row.SystemRowVersion <> Version2));
        Observer.Expect('trace', '');
        Observer.Expect('row1_qty', '5');
        Observer.Expect('row1_stamp_changed', 'Yes');
        Observer.Expect('row1_version_changed', 'Yes');
        Observer.Expect('row2_qty', '5');
        Observer.Expect('row2_stamp_changed', 'Yes');
        Observer.Expect('row2_version_changed', 'Yes');
        Observer.Verify();
    end;
}

table 86510 "LT QD MW Sub Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 86511 "LT QD MW After Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT QD MW Sub Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModify(var Rec: Record "LT QD MW Sub Row"; var xRec: Record "LT QD MW Sub Row"; RunTrigger: Boolean)
    var
        L: Codeunit "LT MW Log";
    begin
        L.Add('after ' + Format(Rec.Id) + ' rec=' + Format(Rec.Qty) + ' xrec=' + Format(xRec.Qty));
    end;
}

codeunit 86512 "LT QD MW Before Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT QD MW Sub Row", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModify(var Rec: Record "LT QD MW Sub Row"; var xRec: Record "LT QD MW Sub Row"; RunTrigger: Boolean)
    var
        L: Codeunit "LT MW Log";
    begin
        L.Add('before ' + Format(Rec.Id) + ' rec=' + Format(Rec.Qty) + ' xrec=' + Format(xRec.Qty));
    end;
}

table 86647 "LT QF MW Plain Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 86648 "LT QF MW Trg Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnModify()
    var
        L: Codeunit "LT MW Log";
    begin
        L.Add('OnModify ' + Format(Rec.Id));
    end;
}
