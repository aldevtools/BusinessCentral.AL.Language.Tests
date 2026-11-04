// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-keycount-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-keyindex-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: KRV Row (68540), KRV Modified Row (68541) with KRV Modified Row Ext (68542),
//   KRV Bank Account Ext (68540) over "Customer Bank Account",
//   KRV Item Ext (68541) over Item, ALT Universal (60000) as a control.
// BC versions: 27.5+
//
// CLAIM: the key list RecordRef.KeyCount()/KeyIndex() walks
//   (1) contains a key declared on SystemRowVersion or SystemModifiedAt: on a table's own key
//       list, whether or not a tableextension modifies one of its fields; in a tableextension
//       over a Base Application table; and on a Base Application table's own key list while a
//       tableextension extends that table; and
//   (2) does not contain a key declared ObsoleteState = Removed, while a Pending key stays:
//       KeyIndex() skips the Removed key's position, and a walk calling KeyRef.FieldIndex on
//       every key never reaches the Removed field.
//
// Every "found once" assertion has a control: a table that declares no such key answers 0,
// and the Pending key answers 1, so a pass cannot come from a walk that matches everything
// or from one that hides every obsolete key.
//
// Written by agent stma-auto-4 (AL Runner issues #5135, #5136).

codeunit 68540 "Test Key RowVersion Removed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // How many keys of TableId consist of exactly one field, numbered FieldNo.
    // Calls KeyRef.FieldIndex on every field of every key, so a key whose field cannot be
    // read through a RecordRef fails the walk.
    local procedure CountSingleFieldKeys(TableId: Integer; FieldNo: Integer): Integer
    var
        TableRef: RecordRef;
        KeyReference: KeyRef;
        FieldReference: FieldRef;
        KeyNo: Integer;
        FieldPos: Integer;
        Found: Integer;
    begin
        TableRef.Open(TableId);
        for KeyNo := 1 to TableRef.KeyCount() do begin
            KeyReference := TableRef.KeyIndex(KeyNo);
            for FieldPos := 1 to KeyReference.FieldCount() do
                FieldReference := KeyReference.FieldIndex(FieldPos);
            if KeyReference.FieldCount() = 1 then
                if KeyReference.FieldIndex(1).Number() = FieldNo then
                    Found += 1;
        end;
        TableRef.Close();
        exit(Found);
    end;

    // How many keys of TableId name FieldNo at any position.
    local procedure CountKeysNamingField(TableId: Integer; FieldNo: Integer): Integer
    var
        TableRef: RecordRef;
        KeyReference: KeyRef;
        KeyNo: Integer;
        FieldPos: Integer;
        Found: Integer;
    begin
        TableRef.Open(TableId);
        for KeyNo := 1 to TableRef.KeyCount() do begin
            KeyReference := TableRef.KeyIndex(KeyNo);
            for FieldPos := 1 to KeyReference.FieldCount() do
                if KeyReference.FieldIndex(FieldPos).Number() = FieldNo then
                    Found += 1;
        end;
        TableRef.Close();
        exit(Found);
    end;

    // The own-key assertions, asked of one table. "KRV Row" and "KRV Modified Row" declare
    // the same keys, so each test below runs this against both.

    local procedure AssertRowVersionKey(TableId: Integer)
    var
        Row: Record "KRV Row";
    begin
        Assert.AreEqual(1, CountSingleFieldKeys(TableId, Row.FieldNo(SystemRowVersion)),
            StrSubstNo('table %1: key(RowVersionKey; SystemRowVersion) must be in its key list exactly once', TableId));
    end;

    local procedure AssertModifiedAtKey(TableId: Integer)
    var
        Row: Record "KRV Row";
    begin
        Assert.AreEqual(1, CountSingleFieldKeys(TableId, Row.FieldNo(SystemModifiedAt)),
            StrSubstNo('table %1: key(ModifiedAtKey; SystemModifiedAt) must be in its key list exactly once', TableId));
    end;

    local procedure AssertRemovedKeyNotWalked(TableId: Integer)
    begin
        Assert.AreEqual(0, CountKeysNamingField(TableId, 4),
            StrSubstNo('table %1: no enumerated key may name the Removed field 4 "Removed Value"', TableId));
    end;

    local procedure AssertPendingKeyWalked(TableId: Integer)
    begin
        Assert.AreEqual(1, CountKeysNamingField(TableId, 3),
            StrSubstNo('table %1: the Pending key on field 3 "Pending Value" must stay in the key list', TableId));
    end;

    local procedure AssertRemovedKeyTakesNoIndex(TableId: Integer)
    var
        TableRef: RecordRef;
        KeyReference: KeyRef;
        KeyNo: Integer;
        PendingKeyNo: Integer;
        LiveKeyNo: Integer;
    begin
        // PendingKey, RemovedKey and LiveKey are declared in that order. LiveKey directly
        // follows PendingKey in the KeyIndex() numbering only when the Removed key between
        // them takes no index position.
        TableRef.Open(TableId);
        for KeyNo := 1 to TableRef.KeyCount() do begin
            KeyReference := TableRef.KeyIndex(KeyNo);
            if KeyReference.FieldCount() = 1 then
                case KeyReference.FieldIndex(1).Number() of
                    3:
                        PendingKeyNo := KeyNo;
                    2:
                        LiveKeyNo := KeyNo;
                end;
        end;
        TableRef.Close();
        Assert.AreNotEqual(0, PendingKeyNo, StrSubstNo('table %1: PendingKey on field 3 must be enumerated', TableId));
        Assert.AreEqual(PendingKeyNo + 1, LiveKeyNo,
            StrSubstNo('table %1: LiveKey must take the KeyIndex() position right after PendingKey; the Removed key between them takes none', TableId));
    end;

    // ── (1) keys on system fields ──────────────────────────────────────────────────────

    [Test]
    procedure TableKey_OnSystemRowVersion_IsEnumerated()
    begin
        AssertRowVersionKey(Database::"KRV Row");
    end;

    [Test]
    procedure TableKey_OnSystemRowVersion_TableWithModifyExtension_IsEnumerated()
    begin
        AssertRowVersionKey(Database::"KRV Modified Row");
    end;

    [Test]
    procedure TableKey_OnSystemModifiedAt_IsEnumerated()
    begin
        AssertModifiedAtKey(Database::"KRV Row");
    end;

    [Test]
    procedure TableKey_OnSystemModifiedAt_TableWithModifyExtension_IsEnumerated()
    begin
        AssertModifiedAtKey(Database::"KRV Modified Row");
    end;

    [Test]
    procedure TableExtensionKey_OnSystemRowVersion_OverBaseAppTable_IsEnumerated()
    var
        BankAccount: Record "Customer Bank Account";
    begin
        Assert.AreEqual(1,
            CountSingleFieldKeys(Database::"Customer Bank Account", BankAccount.FieldNo(SystemRowVersion)),
            'the tableextension''s key(KRVRowVersionKey; SystemRowVersion) must be in Customer Bank Account''s key list exactly once');
    end;

    [Test]
    procedure BaseAppTableKey_OnSystemModifiedAt_ExtendedTable_IsEnumerated()
    var
        Item: Record Item;
    begin
        // Item declares its own single-field key on SystemModifiedAt; KRV Item Ext extends
        // Item, and that must not change Item's own key list.
        Assert.AreEqual(1, CountSingleFieldKeys(Database::Item, Item.FieldNo(SystemModifiedAt)),
            'Item''s own key on SystemModifiedAt must be in its key list exactly once');
    end;

    [Test]
    procedure Control_TableWithoutRowVersionKey_HasNone()
    var
        Universal: Record "ALT Universal";
    begin
        Assert.AreEqual(0, CountSingleFieldKeys(Database::"ALT Universal", Universal.FieldNo(SystemRowVersion)),
            'a table that declares no SystemRowVersion key must not report one');
    end;

    // ── (2) Removed keys are not enumerated ────────────────────────────────────────────

    [Test]
    procedure TableKey_Removed_WalkNeverReachesItsField()
    begin
        AssertRemovedKeyNotWalked(Database::"KRV Row");
    end;

    [Test]
    procedure TableKey_Removed_TableWithModifyExtension_WalkNeverReachesItsField()
    begin
        AssertRemovedKeyNotWalked(Database::"KRV Modified Row");
    end;

    [Test]
    procedure TableKey_Pending_IsStillEnumerated()
    begin
        AssertPendingKeyWalked(Database::"KRV Row");
    end;

    [Test]
    procedure TableKey_Pending_TableWithModifyExtension_IsStillEnumerated()
    begin
        AssertPendingKeyWalked(Database::"KRV Modified Row");
    end;

    [Test]
    procedure TableKey_Removed_IndexSkipsIt()
    begin
        AssertRemovedKeyTakesNoIndex(Database::"KRV Row");
    end;

    [Test]
    procedure TableKey_Removed_TableWithModifyExtension_IndexSkipsIt()
    begin
        AssertRemovedKeyTakesNoIndex(Database::"KRV Modified Row");
    end;

    [Test]
    procedure TableExtensionKey_Removed_OverBaseAppTable_IsNotEnumerated()
    begin
        Assert.AreEqual(0, CountKeysNamingField(Database::Item, 68540),
            'the tableextension''s Removed key on field 68540 must not be in Item''s key list');
    end;

    [Test]
    procedure TableExtensionKey_Live_OverBaseAppTable_IsEnumerated()
    begin
        // Control for the test above: the same tableextension's live key is enumerated, so
        // the zero above is not a walk that never sees tableextension keys.
        Assert.AreEqual(1, CountKeysNamingField(Database::Item, 68541),
            'the tableextension''s key(KRVLiveKey; "KRV Live Value") must be in Item''s key list exactly once');
    end;

    // ── (3) CurrentKeyIndex with Removed keys (corpus issue 668 item 51, writer br) ─────────────

    local procedure BrKeyIndexOfField(var TableRef: RecordRef; FieldNo: Integer): Integer
    var
        KeyReference: KeyRef;
        KeyNo: Integer;
    begin
        for KeyNo := 1 to TableRef.KeyCount() do begin
            KeyReference := TableRef.KeyIndex(KeyNo);
            if KeyReference.FieldCount() = 1 then
                if KeyReference.FieldIndex(1).Number() = FieldNo then
                    exit(KeyNo);
        end;
        exit(0);
    end;

    [Test]
    procedure CurrentKeyIndex_WithRemovedKeys_MatchesKeyIndexNumbering()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "KRV Row";
        Item: Record Item;
        TableRef: RecordRef;
        LiveIndex: Integer;
    begin
        Row.SetCurrentKey("Live Value");
        TableRef.GetTable(Row);
        LiveIndex := BrKeyIndexOfField(TableRef, 2);
        Observer.Observe('row keycount', Format(TableRef.KeyCount()));
        Observer.Observe('row live keyindex', Format(LiveIndex));
        Observer.Observe('row currentkeyindex after SetCurrentKey', Format(TableRef.CurrentKeyIndex()));
        TableRef.CurrentKeyIndex(LiveIndex);
        Observer.Observe('row currentkey after CurrentKeyIndex(live)', TableRef.CurrentKey());
        TableRef.Close();

        Item.SetCurrentKey("KRV Live Value");
        TableRef.GetTable(Item);
        LiveIndex := BrKeyIndexOfField(TableRef, 68541);
        Observer.Observe('item currentkeyindex equals keyindex', Format(TableRef.CurrentKeyIndex() = LiveIndex));
        TableRef.CurrentKeyIndex(LiveIndex);
        Observer.Observe('item currentkey after CurrentKeyIndex(live)', TableRef.CurrentKey());
        Observer.Expect('row keycount', '6');
        Observer.Expect('row live keyindex', '5');
        Observer.Expect('row currentkeyindex after SetCurrentKey', '5');
        Observer.Expect('row currentkey after CurrentKeyIndex(live)', 'Live Value');
        Observer.Expect('item currentkeyindex equals keyindex', 'Yes');
        Observer.Expect('item currentkey after CurrentKeyIndex(live)', 'KRV Live Value');
        Observer.Verify();
    end;
}
