// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope (Cloud-compatible, multi-app fixture required)
// Fixtures used: ALT Internal Table Ext (60205) on ALT Internal Table (61001)
// BC versions: 27.5+
//
// CLAIM: a dependent app can read and write fields that a dependency app's
// tableextension added to an internal fixture table. This exercises the
// symbol-merge of a tableextension loaded as a compiled .app dependency.

codeunit 60203 "Test TableExt Cross App"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Field round-trip ─────────────────────────────────────────────────────

    [Test]
    procedure TableExt_CrossApp_FooField_InsertAndGet_RoundTrips()
    // CLAIM: "ALT Foo" (Integer) added by the fixture app's tableextension persists
    // through Insert and is readable via Get from the dependent test app.
    // DOCS: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
    var
        InternalRec: Record "ALT Internal Table";
        EntryNo: Integer;
    begin
        Initialize();
        InternalRec."Value" := 42;
        InternalRec."ALT Foo" := 42;
        InternalRec.Insert(false);
        EntryNo := InternalRec."Entry No.";

        Clear(InternalRec);
        InternalRec.Get(EntryNo);
        Assert.AreEqual(42, InternalRec."ALT Foo", 'ALT Foo must round-trip through Insert/Get');
    end;

    [Test]
    procedure TableExt_CrossApp_BothFields_PersistAfterModify()
    // CLAIM: both extension fields ("ALT Foo" and "ALT Bar") persist correctly
    // after a Modify — proves that multiple extension fields all survive the update path.
    var
        InternalRec: Record "ALT Internal Table";
        EntryNo: Integer;
    begin
        Initialize();
        InternalRec."Value" := 1;
        InternalRec."ALT Foo" := 1;
        InternalRec."ALT Bar" := 'initial';
        InternalRec.Insert(false);
        EntryNo := InternalRec."Entry No.";

        InternalRec."ALT Foo" := 99;
        InternalRec."ALT Bar" := 'modified';
        InternalRec.Modify(false);

        Clear(InternalRec);
        InternalRec.Get(EntryNo);
        Assert.AreEqual(99, InternalRec."ALT Foo", 'ALT Foo must reflect modified value');
        Assert.AreEqual('modified', InternalRec."ALT Bar", 'ALT Bar must reflect modified value');
    end;

    [Test]
    procedure TableExt_CrossApp_SetRange_OnExtField_FiltersRecords()
    // CLAIM: SetRange on "ALT Foo" (an extension field) narrows the result set,
    // proving filters on extension fields work in the dependent app.
    var
        InternalRec: Record "ALT Internal Table";
    begin
        Initialize();
        InternalRec."Value" := 10;
        InternalRec."ALT Foo" := 10;
        InternalRec.Insert(false);

        Clear(InternalRec);
        InternalRec."Value" := 20;
        InternalRec."ALT Foo" := 20;
        InternalRec.Insert(false);

        InternalRec.Reset();
        InternalRec.SetRange("ALT Foo", 10, 10);
        Assert.AreEqual(1, InternalRec.Count(), 'SetRange on ALT Foo must filter to exactly one record');
    end;

    [Test]
    procedure TableExt_CrossApp_Insert_AssignsAutoIncrementEntryNo()
    // CLAIM: inserting a record on the internal fixture table assigns a non-zero
    // auto-incremented primary key, proving the fixture table and extension are live.
    var
        InternalRec: Record "ALT Internal Table";
    begin
        Initialize();
        InternalRec."Value" := 5;
        InternalRec."ALT Foo" := 5;
        InternalRec.Insert(false);

        Assert.AreNotEqual(0, InternalRec."Entry No.", 'Auto-increment must assign a non-zero Entry No.');
    end;

    local procedure Initialize()
    var
        InternalRec: Record "ALT Internal Table";
    begin
        Cleanup.Initialize();
        InternalRec.DeleteAll(false);
    end;

    // ── Added by writer bs (corpus issue #668, items 89, 92, 93): objects in lt-bs-tableext-leads/BsObjects.al ──

    [Test]
    procedure TableExt_TwoExtensionsOfOneTable_CallEachOther()
    // CLAIM (issue #668 item 92): two tableextensions of one table in one app (83150 and 83151) compile when each one uses a field and calls
    // a procedure of the other. What do the calls return at run time, and are the assigned fields kept on the record?
    var
        Observer: Codeunit "Probe Observer";
        Base: Record "LT BS Base";
    begin
        Base.DeleteAll();
        Base.Init();
        Base.Id := 7;
        Base.Insert();
        Observer.Observe('lower_calls_higher', Base.BsCallTwo());
        Observer.Observe('e3_after_lower_call', Format(Base.E3));
        Observer.Observe('higher_calls_lower', Base.BsCallOne());
        Observer.Observe('e1_after_higher_call', Format(Base.E1));
        Base.Modify();
        Base.Get(7);
        Observer.Observe('stored_e1_e3', Format(Base.E1) + '|' + Format(Base.E3));
        Base.DeleteAll();
        Observer.Expect('lower_calls_higher', 'one>two:70');
        Observer.Expect('e3_after_lower_call', '70');
        Observer.Expect('higher_calls_lower', 'two>one:8');
        Observer.Expect('e1_after_higher_call', '8');
        Observer.Expect('stored_e1_e3', '8|70');
        Observer.Verify();
    end;

    [Test]
    procedure Table_And_TableExtension_SameObjectId_BothWork()
    // CLAIM (issue #668 item 89): table 83153 "LT BS Same Id" and tableextension 83153 (of table 83151 "LT BS Target A") in one app
    // compile. After publish, do Insert and Get work on both tables, and does the extension field store a value?
    var
        Observer: Codeunit "Probe Observer";
        Same: Record "LT BS Same Id";
        Target: Record "LT BS Target A";
        RecRef: RecordRef;
    begin
        Same.DeleteAll();
        Target.DeleteAll();
        Same.Id := 1;
        Same.Txt := 'table row';
        Same.Insert();
        Target.Code := 'T1';
        Target.SameIdExt := 'extension value';
        Target.Insert();
        Same.Get(1);
        Observer.Observe('table_get', Same.Txt);
        Target.Get('T1');
        Observer.Observe('extended_get', Target.SameIdExt);
        RecRef.Open(83153);
        Observer.Observe('recordref_open_83153_name', RecRef.Name());
        Observer.Observe('recordref_open_83153_count', Format(RecRef.Count()));
        RecRef.Close();
        Same.DeleteAll();
        Target.DeleteAll();
        Observer.Expect('table_get', 'table row');
        Observer.Expect('extended_get', 'extension value');
        Observer.Expect('recordref_open_83153_name', 'LT BS Same Id');
        Observer.Expect('recordref_open_83153_count', '1');
        Observer.Verify();
    end;

    local procedure BsSeedDelete()
    var
        Base: Record "LT BS Base";
        Index: Integer;
    begin
        Base.DeleteAll();
        for Index := 1 to 4 do begin
            Base.Init();
            Base.Id := Index;
            Base.A := Index mod 2;
            Base.E1 := Index;
            Base.Insert();
        end;
    end;

    local procedure BsIds(): Text
    var
        Base: Record "LT BS Base";
        Result: Text;
    begin
        if Base.FindSet() then
            repeat
                Result += Format(Base.Id) + ';';
            until Base.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure TableExt_DeleteAllWithFilters_OnExtendedTable()
    // CLAIM (issue #668 item 93): DeleteAll(true) and DeleteAll(false) with a filter on a base field and with a filter on an extension field
    // of a table that two tableextensions extend (its rows have companion rows): which rows remain, and is there an error?
    var
        Observer: Codeunit "Probe Observer";
        Base: Record "LT BS Base";
    begin
        BsSeedDelete();
        Base.SetRange(A, 1);
        Base.DeleteAll(true);
        Observer.Observe('base_filter_true', BsIds());
        BsSeedDelete();
        Base.Reset();
        Base.SetRange(E1, 2, 3);
        Base.DeleteAll(true);
        Observer.Observe('ext_filter_true', BsIds());
        BsSeedDelete();
        Base.Reset();
        Base.SetFilter(E1, '>%1', 2);
        Base.DeleteAll(false);
        Observer.Observe('ext_filter_false', BsIds());
        BsSeedDelete();
        Base.Reset();
        Base.SetRange(A, 0);
        Base.SetRange(E1, 4);
        Base.DeleteAll(true);
        Observer.Observe('both_filters_true', BsIds());
        Base.Reset();
        Base.DeleteAll();
        Observer.Expect('base_filter_true', '2;4;');
        Observer.Expect('ext_filter_true', '1;4;');
        Observer.Expect('ext_filter_false', '1;2;');
        Observer.Expect('both_filters_true', '1;2;3;');
        Observer.Verify();
    end;
}
