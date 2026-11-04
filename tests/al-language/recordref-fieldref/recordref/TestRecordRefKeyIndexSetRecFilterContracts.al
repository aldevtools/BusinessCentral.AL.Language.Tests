// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-currentkeyindex-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-setrecfilter-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained tables 68360, 68361 and codeunit 68362
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins RecordRef.CurrentKeyIndex and RecordRef.SetRecFilter:
//  - KeyCount counts the declared keys and the hidden key on $systemId (last). KeyIndex(n) and
//    CurrentKeyIndex(n) number them in declaration order from 1; CurrentKey() names the key's fields
//    separated by a comma ("System ID" for the hidden key).
//  - A new RecordRef is on key 1. CurrentKeyIndex(n) selects key n and keeps the direction set by
//    Ascending. Reset puts the RecordRef back on key 1. An index outside 1..KeyCount raises
//    "The <table> table does not have an active key at index <n>." / DB:KeyNotFound.
//  - GetTable of a Record whose current key is a declared key reports that key's index; a key of
//    fields no declared key starts with reports -1 (CurrentKey() still names those fields).
//  - SetRecFilter filters every primary key field to the value the RecordRef holds ("K1: 1, K2: B"), replaces a
//    filter on a primary key field, keeps filters on other fields, and gives the same text as Record.SetRecFilter.
// BC versions: 27.5

table 68360 "Probe KI Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Integer) { }
        field(3; B; Text[10]) { }
        field(4; C; Code[10]) { }
        field(5; D; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(KA; A) { }
        key(KBA; B, A) { }
        key(KD; D) { }
    }
}

table 68361 "Probe KI Composite"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K1; Integer) { }
        field(2; K2; Code[10]) { }
        field(3; Other; Integer) { }
    }

    keys
    {
        key(PK; K1, K2) { Clustered = true; }
    }
}

codeunit 68362 "Probe RecordRef Key Index"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure CurrentKeyIndex_NumbersTheKeysAndTheHiddenSystemIdKey()
    var
        KiRef: RecordRef;
        KeyRefVar: KeyRef;
        Index: Integer;
        Firsts: Text;
        Keys: Text;
    begin
        KiRef.Open(Database::"Probe KI Table");

        Assert.AreEqual(5, KiRef.KeyCount(), 'four declared keys and the hidden one');
        for Index := 1 to KiRef.KeyCount() do begin
            KeyRefVar := KiRef.KeyIndex(Index);
            Firsts += KeyRefVar.FieldIndex(1).Name() + '/' + Format(KeyRefVar.FieldCount()) + ';';
        end;
        Assert.AreEqual('Id/1;A/1;B/2;D/1;$systemId/1;', Firsts, 'first field and field count per key');

        Assert.AreEqual(1, KiRef.CurrentKeyIndex(), 'default key index');
        Assert.AreEqual('Id', KiRef.CurrentKey(), 'default key');
        for Index := 1 to KiRef.KeyCount() do begin
            KiRef.CurrentKeyIndex(Index);
            Keys += Format(KiRef.CurrentKeyIndex()) + '=' + KiRef.CurrentKey() + ';';
        end;
        Assert.AreEqual('1=Id;2=A;3=B,A;4=D;5=System ID;', Keys, 'every key by index');
    end;

    [Test]
    procedure CurrentKeyIndex_OutsideTheKeys_RaisesKeyNotFound()
    var
        KiRef: RecordRef;
    begin
        KiRef.Open(Database::"Probe KI Table");

        asserterror KiRef.CurrentKeyIndex(0);
        Assert.AreEqual('The Probe KI Table table does not have an active key at index 0.', GetLastErrorText(), 'index 0');
        Assert.AreEqual('DB:KeyNotFound', GetLastErrorCode(), 'index 0 code');

        asserterror KiRef.CurrentKeyIndex(6);
        Assert.AreEqual('The Probe KI Table table does not have an active key at index 6.', GetLastErrorText(), 'index 6');
    end;

    [Test]
    procedure CurrentKeyIndex_KeepsTheDirection_AndResetGoesBackToTheFirstKey()
    var
        KiRef: RecordRef;
    begin
        KiRef.Open(Database::"Probe KI Table");

        KiRef.CurrentKeyIndex(2);
        KiRef.Ascending(false);
        Assert.AreEqual(2, KiRef.CurrentKeyIndex(), 'key 2');
        Assert.IsFalse(KiRef.Ascending(), 'descending');
        KiRef.CurrentKeyIndex(1);
        Assert.IsFalse(KiRef.Ascending(), 'the direction stays when the key changes');

        KiRef.Close();
        KiRef.Open(Database::"Probe KI Table");
        Assert.AreEqual(1, KiRef.CurrentKeyIndex(), 'reopened');
        Assert.IsTrue(KiRef.Ascending(), 'reopened ascending');

        KiRef.CurrentKeyIndex(4);
        KiRef.Reset();
        Assert.AreEqual(1, KiRef.CurrentKeyIndex(), 'Reset goes back to the first key');
        Assert.AreEqual('Id', KiRef.CurrentKey(), 'and its fields');
    end;

    [Test]
    procedure CurrentKeyIndex_AfterGetTable_FollowsTheRecordsCurrentKey()
    var
        KiRef: RecordRef;
        KiRec: Record "Probe KI Table";
    begin
        KiRef.Open(Database::"Probe KI Table");

        KiRec.SetCurrentKey(A);
        KiRef.GetTable(KiRec);
        Assert.AreEqual(2, KiRef.CurrentKeyIndex(), 'key A');
        Assert.AreEqual('A', KiRef.CurrentKey(), 'key A fields');

        KiRec.SetCurrentKey(B, A);
        KiRef.GetTable(KiRec);
        Assert.AreEqual(3, KiRef.CurrentKeyIndex(), 'key B,A');
        Assert.AreEqual('B,A', KiRef.CurrentKey(), 'key B,A fields');

        KiRec.SetCurrentKey(C);
        KiRef.GetTable(KiRec);
        Assert.AreEqual(-1, KiRef.CurrentKeyIndex(), 'fields no key starts with');
        Assert.AreEqual('C', KiRef.CurrentKey(), 'still names them');
    end;

    local procedure SeedComposite()
    var
        CompRec: Record "Probe KI Composite";
    begin
        CompRec.DeleteAll();
        CompRec.K1 := 1;
        CompRec.K2 := 'A';
        CompRec.Other := 10;
        CompRec.Insert();
        CompRec.K1 := 1;
        CompRec.K2 := 'B';
        CompRec.Other := 20;
        CompRec.Insert();
        CompRec.K1 := 2;
        CompRec.K2 := 'A';
        CompRec.Other := 30;
        CompRec.Insert();
        Commit();
    end;

    [Test]
    procedure SetRecFilter_FiltersEveryPrimaryKeyFieldToTheCurrentRecord()
    var
        CompRef: RecordRef;
        CompRec: Record "Probe KI Composite";
        FldRef: FieldRef;
    begin
        SeedComposite();
        CompRec.Get(1, 'B');
        CompRef.GetTable(CompRec);

        CompRef.SetRecFilter();

        Assert.AreEqual('K1: 1, K2: B', CompRef.GetFilters(), 'filters');
        Assert.AreEqual(1, CompRef.Count(), 'one row');
        FldRef := CompRef.Field(1);
        Assert.AreEqual('1', FldRef.GetFilter(), 'K1');
        FldRef := CompRef.Field(2);
        Assert.AreEqual('B', FldRef.GetFilter(), 'K2');
        FldRef := CompRef.Field(3);
        Assert.AreEqual('', FldRef.GetFilter(), 'Other');
    end;

    [Test]
    procedure SetRecFilter_ReplacesKeyFilters_AndKeepsFiltersOnOtherFields()
    var
        CompRef: RecordRef;
        CompRec: Record "Probe KI Composite";
        FldRef: FieldRef;
    begin
        SeedComposite();
        CompRec.Get(2, 'A');
        CompRef.GetTable(CompRec);
        FldRef := CompRef.Field(3);
        FldRef.SetFilter('>%1', 5);
        FldRef := CompRef.Field(1);
        FldRef.SetFilter('<%1', 9);

        CompRef.SetRecFilter();

        Assert.AreEqual('K1: 2, K2: A, Other: >5', CompRef.GetFilters(), 'key filters replaced, the other one kept');
        FldRef := CompRef.Field(1);
        Assert.AreEqual('2', FldRef.GetFilter(), 'K1 replaced');
        Assert.AreEqual(1, CompRef.Count(), 'one row');

        CompRec.SetRecFilter();
        Assert.AreEqual('K1: 2, K2: A', CompRec.GetFilters(), 'Record.SetRecFilter gives the same key filters');
    end;
}
