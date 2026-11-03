// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: TXN Log (69420), Shipment Method (69422), TXN Local Own Ext (69423),
//   TXN Local Qualified Ext (69424), TXN Base Qualified Ext (69425), TXN Base Imported Ext (69427),
//   TXN Own Namespace Ext (69429),
//   Assert (60021) -- and Base Application table "Shipment Method"
//
// A tableextension extends ONE table: the one its `extends` clause names, with the namespace
// written out or resolved from the file's own namespace and `using`s. This app's "Shipment Method"
// and Base Application's table of that name are two tables, so an extension of one must not take
// effect on the other, however it spells the name. Each arm reads what the extension contributed:
// the trigger it runs, the fields and keys it adds, the field caption it modifies.

codeunit 69428 "TXN Target Namespace Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        LogRec: Record ALLanguage.Coverage.TxnShared."TXN Log";
    begin
        LogRec.DeleteAll();
    end;

    local procedure CountOf(TriggerName: Text): Integer
    var
        LogRec: Record ALLanguage.Coverage.TxnShared."TXN Log";
    begin
        LogRec.SetRange("Trigger Name", TriggerName);
        exit(LogRec.Count());
    end;

    // How many keys of the table are made of exactly these two fields, in this order.
    local procedure KeysOver(var RecRef: RecordRef; FirstField: Text; SecondField: Text): Integer
    var
        KeyRef: KeyRef;
        I: Integer;
        Result: Integer;
    begin
        for I := 1 to RecRef.KeyCount() do begin
            KeyRef := RecRef.KeyIndex(I);
            if KeyRef.FieldCount() = 2 then
                if (KeyRef.FieldIndex(1).Name() = FirstField) and (KeyRef.FieldIndex(2).Name() = SecondField) then
                    Result += 1;
        end;
        exit(Result);
    end;

    // Positive: both extensions of this app's table run once, whether one writes the namespace or
    // is declared inside it. Negative: the two extensions of Base Application's table do not.
    [Test]
    procedure InsertIntoTheLocalTableRunsOnlyItsOwnExtensions()
    var
        Entry: Record ALLanguage.Coverage.TxnLocal."Shipment Method";
    begin
        Initialize();
        Entry.DeleteAll();

        Entry.Code := 'TXN-L';
        Entry."TXN Local Only" := 5;
        Entry.Insert(true);

        Assert.AreEqual(1, CountOf('local-own'), 'the extension declared in the local namespace must run once');
        Assert.AreEqual(1, CountOf('local-qualified'), 'the extension qualifying the local table must run once');
        Assert.AreEqual(0, CountOf('base-qualified'), 'an extension of Base Application''s table must not run for the local table');
        Assert.AreEqual(0, CountOf('base-imported'), 'an extension reaching Base Application''s table through a using must not run for the local table');
        Entry.Get('TXN-L');
        Assert.AreEqual(5, Entry."TXN Local Only", 'the field the local extension adds must be stored');
    end;

    // The mirror image: a write to Base Application's table runs only the extensions that name it.
    [Test]
    procedure InsertIntoTheBaseTableRunsOnlyItsOwnExtensions()
    var
        Entry: Record Microsoft.Foundation.Shipping."Shipment Method";
    begin
        Initialize();
        if Entry.Get('TXN-B') then
            Entry.Delete();

        Entry.Code := 'TXN-B';
        Entry."TXN Base Only" := 6;
        Entry.Insert(true);

        Assert.AreEqual(1, CountOf('base-qualified'), 'the extension qualifying Base Application''s table must run once');
        Assert.AreEqual(1, CountOf('base-imported'), 'the extension reaching Base Application''s table through a using must run once');
        Assert.AreEqual(0, CountOf('local-own'), 'an extension declared in the local namespace must not run for Base Application''s table');
        Assert.AreEqual(0, CountOf('local-qualified'), 'an extension of the local table must not run for Base Application''s table');
        Entry.Get('TXN-B');
        Assert.AreEqual(6, Entry."TXN Base Only", 'the field the base extension adds must be stored');
        Entry.Delete();
    end;

    // Each table has the fields of its own extensions and none of the other's. Field 69423 is
    // declared by an extension of each table, as a different field of a different type.
    [Test]
    procedure ExtensionFieldsBelongToTheTableTheExtensionExtends()
    var
        LocalRef: RecordRef;
        BaseRef: RecordRef;
    begin
        LocalRef.Open(Database::ALLanguage.Coverage.TxnLocal."Shipment Method");
        BaseRef.Open(Database::Microsoft.Foundation.Shipping."Shipment Method");

        Assert.IsTrue(LocalRef.FieldExist(69424), 'the local table must have the field its own extension adds');
        Assert.IsTrue(LocalRef.FieldExist(69426), 'the local table must have the field its qualified extension adds');
        Assert.IsFalse(LocalRef.FieldExist(69425), 'the local table must not have a field Base Application''s extension adds');
        Assert.IsFalse(LocalRef.FieldExist(69427), 'the local table must not have a field the imported extension adds');
        Assert.IsTrue(BaseRef.FieldExist(69425), 'Base Application''s table must have the field its qualified extension adds');
        Assert.IsTrue(BaseRef.FieldExist(69427), 'Base Application''s table must have the field its imported extension adds');
        Assert.IsFalse(BaseRef.FieldExist(69424), 'Base Application''s table must not have a field the local extension adds');
        Assert.IsFalse(BaseRef.FieldExist(69426), 'Base Application''s table must not have a field the qualified local extension adds');

        Assert.AreEqual('TXN Local Shared Id', LocalRef.Field(69423).Name(), 'field 69423 of the local table is the local extension''s');
        Assert.AreEqual(FieldType::Integer, LocalRef.Field(69423).Type(), 'the local field 69423 is an Integer');
        Assert.AreEqual('TXN Base Shared Id', BaseRef.Field(69423).Name(), 'field 69423 of Base Application''s table is its own extension''s');
        Assert.AreEqual(FieldType::Text, BaseRef.Field(69423).Type(), 'the base field 69423 is a Text');
    end;

    // The OnValidate of an extension field runs for the table that has the field, and the one of the
    // other table's field of the same id does not.
    [Test]
    procedure ExtensionFieldValidateRunsOnlyForTheTableTheExtensionExtends()
    var
        LocalEntry: Record ALLanguage.Coverage.TxnLocal."Shipment Method";
        BaseEntry: Record Microsoft.Foundation.Shipping."Shipment Method";
    begin
        Initialize();

        LocalEntry.Validate("TXN Local Shared Id", 3);
        Assert.AreEqual(1, CountOf('local-validate'), 'the local extension field''s OnValidate must run once for the local table');
        Assert.AreEqual(0, CountOf('base-validate'), 'the base extension field''s OnValidate must not run for the local table');
        Assert.AreEqual(3, LocalEntry."TXN Local Shared Id", 'the local field must hold the validated value');

        BaseEntry.Validate("TXN Base Shared Id", 'abc');
        Assert.AreEqual(1, CountOf('base-validate'), 'the base extension field''s OnValidate must run once for Base Application''s table');
        Assert.AreEqual(1, CountOf('local-validate'), 'the local extension field''s OnValidate must not run again for Base Application''s table');
        Assert.AreEqual('abc', BaseEntry."TXN Base Shared Id", 'the base field must hold the validated value');
    end;

    // A key an extension declares is a key of the table it extends. Both keys are made of fields
    // both tables have, so a table that took the other extension's key would show it.
    [Test]
    procedure ExtensionKeysBelongToTheTableTheExtensionExtends()
    var
        LocalRef: RecordRef;
        BaseRef: RecordRef;
    begin
        LocalRef.Open(Database::ALLanguage.Coverage.TxnLocal."Shipment Method");
        BaseRef.Open(Database::Microsoft.Foundation.Shipping."Shipment Method");

        Assert.AreEqual(1, KeysOver(LocalRef, 'Code', 'Description'), 'the local table must carry the key its own extension declares');
        Assert.AreEqual(0, KeysOver(LocalRef, 'Description', 'Code'), 'the local table must not carry the key Base Application''s extension declares');
        Assert.AreEqual(1, KeysOver(BaseRef, 'Description', 'Code'), 'Base Application''s table must carry the key its own extension declares');
        Assert.AreEqual(0, KeysOver(BaseRef, 'Code', 'Description'), 'Base Application''s table must not carry the key the local extension declares');
    end;

    // A modify() of a field's caption applies to the table it extends only.
    [Test]
    procedure ModifiedCaptionBelongsToTheTableTheExtensionExtends()
    var
        LocalEntry: Record ALLanguage.Coverage.TxnLocal."Shipment Method";
        BaseEntry: Record Microsoft.Foundation.Shipping."Shipment Method";
    begin
        Assert.AreEqual('TXN Local Code', LocalEntry.FieldCaption("Code"), 'the local extension''s modify must set the local table''s caption');
        Assert.AreEqual('TXN Base Code', BaseEntry.FieldCaption("Code"), 'the base extension''s modify must set Base Application''s caption');
    end;

    // A bare clause resolves in the file's own namespace first, so an extension declared in Base
    // Application's namespace extends its table although the file imports this app's same-named
    // table: the trigger runs for Base Application's table and its field is stored there.
    [Test]
    procedure BareClauseFromTheBaseNamespaceExtendsTheBaseTableDespiteAnImportedLocalTable()
    var
        Entry: Record Microsoft.Foundation.Shipping."Shipment Method";
    begin
        Initialize();
        if Entry.Get('TXN-O') then
            Entry.Delete();

        Entry.Code := 'TXN-O';
        Entry."TXN Own Namespace Added" := 7;
        Entry.Insert(true);

        Assert.AreEqual(1, CountOf('base-own-namespace'), 'the extension declared in Base Application''s namespace must run once for Base Application''s table');
        Entry.Get('TXN-O');
        Assert.AreEqual(7, Entry."TXN Own Namespace Added", 'the field that extension adds must be stored on Base Application''s table');
        Entry.Delete();
    end;
}
