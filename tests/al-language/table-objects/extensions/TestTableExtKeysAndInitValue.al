// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-initvalue-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Keyed (60006) and ALT Keyed Ext (60330), the tableextension that adds
//   "Ext Rank" (60340, Integer, InitValue = 7), "Ext Tag" (60341, Code[20], no InitValue),
//   key(ExtRank; "Ext Rank") and key(ExtMixed; "Status", "Ext Rank").
// BC versions: 27.5+
//
// CLAIM (the file's subject): a tableextension extends the table's KEY list and its field
// PROPERTIES, not only its column list. Everything the corpus pinned about tableextensions
// before this was a column: TestTableExtCrossApp proves Insert/Get/SetRange on an extension
// field, TestTableExtFieldValidate and TestTableExtFieldTestPageControl prove an extension
// field's OnValidate runs. None of them asks whether a key declared in a tableextension
// actually sorts, whether InitValue declared there is applied by Init(), or whether the
// extension key is visible in the table's metadata.
//
// Every ordering claim below is paired with a CONTROL ARM reading the same rows under a
// different key, so a pass cannot come from insertion order, primary-key order, or the rows
// happening to already be in the asserted sequence.
//
// Written by agent impl-26.

codeunit 60331 "TableExt Keys And InitValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    // Three rows whose primary-key order (1, 2, 3) and "Ext Rank" order (2, 3, 1) are
    // deliberately different sequences, so the two orderings below cannot be confused.
    local procedure SeedRankedRows()
    var
        Keyed: Record "ALT Keyed";
    begin
        Keyed.Init();
        Keyed."Entry No." := 1;
        Keyed."Ext Rank" := 30;
        Keyed.Insert(false);

        Keyed.Init();
        Keyed."Entry No." := 2;
        Keyed."Ext Rank" := 10;
        Keyed.Insert(false);

        Keyed.Init();
        Keyed."Entry No." := 3;
        Keyed."Ext Rank" := 20;
        Keyed.Insert(false);
    end;

    // ── A key declared in a tableextension sorts ──────────────────────────────────────────

    [Test]
    procedure TableExt_Key_ExtensionFieldOnly_SetCurrentKey_OrdersByTheExtensionField()
    // CLAIM: key(ExtRank; "Ext Rank"), declared in a tableextension and built entirely from a
    // field that tableextension added, is a real key — SetCurrentKey on it walks the rows in
    // "Ext Rank" order (10, 20, 30), which is NOT their primary-key order.
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        SeedRankedRows();

        Keyed.SetCurrentKey("Ext Rank");

        Assert.IsTrue(Keyed.FindSet(), 'FindSet after SetCurrentKey("Ext Rank") must find the seeded rows');
        Assert.AreEqual(10, Keyed."Ext Rank", 'the first row under the extension key must be the lowest Ext Rank');
        Assert.AreEqual(2, Keyed."Entry No.", 'the lowest Ext Rank (10) belongs to Entry No. 2');

        Assert.AreEqual(1, Keyed.Next(), 'Next() must step to the second row of the extension key');
        Assert.AreEqual(20, Keyed."Ext Rank", 'the second row under the extension key must be Ext Rank 20');
        Assert.AreEqual(3, Keyed."Entry No.", 'Ext Rank 20 belongs to Entry No. 3');

        Assert.AreEqual(1, Keyed.Next(), 'Next() must step to the third row of the extension key');
        Assert.AreEqual(30, Keyed."Ext Rank", 'the third row under the extension key must be Ext Rank 30');
        Assert.AreEqual(1, Keyed."Entry No.", 'Ext Rank 30 belongs to Entry No. 1');

        Assert.AreEqual(0, Keyed.Next(), 'the extension key must expose exactly the three seeded rows');
    end;

    [Test]
    procedure TableExt_Key_DefaultPrimaryKey_SameRows_OrdersByEntryNo()
    // CONTROL ARM for the test above. Same three rows, no SetCurrentKey: the table still
    // walks in primary-key order (Ext Rank 30, 10, 20). Without this, the ordering asserted
    // above could have come from insertion order or from the default key rather than from the
    // tableextension's key being honoured.
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        SeedRankedRows();

        Assert.IsTrue(Keyed.FindSet(), 'FindSet under the default key must find the seeded rows');
        Assert.AreEqual(1, Keyed."Entry No.", 'the default key is the primary key, so Entry No. 1 comes first');
        Assert.AreEqual(30, Keyed."Ext Rank", 'Entry No. 1 carries Ext Rank 30 — proof this is NOT extension-key order');

        Assert.AreEqual(1, Keyed.Next(), 'Next() must step to Entry No. 2');
        Assert.AreEqual(2, Keyed."Entry No.", 'primary-key order puts Entry No. 2 second');
        Assert.AreEqual(10, Keyed."Ext Rank", 'Entry No. 2 carries Ext Rank 10');
    end;

    // ── A key mixing a base-table field with an extension field ──────────────────────────

    // Status order (Draft = 1 before Active = 2) and "Ext Rank" order disagree on purpose:
    // by rank alone the sequence is 1, 5, 9; by (Status, Ext Rank) it is 5, 9, 1.
    local procedure SeedMixedRows()
    var
        Keyed: Record "ALT Keyed";
    begin
        Keyed.Init();
        Keyed."Entry No." := 1;
        Keyed.Status := Keyed.Status::Active;
        Keyed."Ext Rank" := 1;
        Keyed.Insert(false);

        Keyed.Init();
        Keyed."Entry No." := 2;
        Keyed.Status := Keyed.Status::Draft;
        Keyed."Ext Rank" := 9;
        Keyed.Insert(false);

        Keyed.Init();
        Keyed."Entry No." := 3;
        Keyed.Status := Keyed.Status::Draft;
        Keyed."Ext Rank" := 5;
        Keyed.Insert(false);
    end;

    [Test]
    procedure TableExt_Key_MixedBaseAndExtensionField_SortsByBaseFieldFirst()
    // CLAIM: key(ExtMixed; "Status", "Ext Rank") — a base-table field followed by an
    // extension field — sorts on Status first and only then on the extension field, exactly
    // as a key declared on the table itself would. The two Draft rows come out ranked 5 then
    // 9, ahead of the Active row ranked 1.
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        SeedMixedRows();

        Keyed.SetCurrentKey(Status, "Ext Rank");

        Assert.IsTrue(Keyed.FindSet(), 'FindSet after SetCurrentKey(Status, "Ext Rank") must find the seeded rows');
        Assert.AreEqual(Keyed.Status::Draft, Keyed.Status, 'Draft (1) sorts ahead of Active (2) on the leading key field');
        Assert.AreEqual(5, Keyed."Ext Rank", 'inside Draft the lower Ext Rank comes first');
        Assert.AreEqual(3, Keyed."Entry No.", 'Draft with Ext Rank 5 is Entry No. 3');

        Assert.AreEqual(1, Keyed.Next(), 'Next() must stay inside Draft before moving on');
        Assert.AreEqual(Keyed.Status::Draft, Keyed.Status, 'the second row must still be Draft');
        Assert.AreEqual(9, Keyed."Ext Rank", 'the second Draft row is the higher Ext Rank');

        Assert.AreEqual(1, Keyed.Next(), 'Next() must move on to the Active row');
        Assert.AreEqual(Keyed.Status::Active, Keyed.Status, 'Active sorts last on the leading key field');
        Assert.AreEqual(1, Keyed."Ext Rank", 'the Active row ranks 1 — lowest overall, yet last under the mixed key');
    end;

    [Test]
    procedure TableExt_Key_ExtensionFieldOnly_SameRows_SortsByRankAlone()
    // CONTROL ARM for the test above. The identical rows read under key(ExtRank) come out
    // 1, 5, 9 — a different first row and a different sequence. That is what makes the test
    // above a statement about the LEADING base field rather than about "Ext Rank" happening
    // to order the rows either way.
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        SeedMixedRows();

        Keyed.SetCurrentKey("Ext Rank");

        Assert.IsTrue(Keyed.FindSet(), 'FindSet after SetCurrentKey("Ext Rank") must find the seeded rows');
        Assert.AreEqual(1, Keyed."Ext Rank", 'by rank alone the Active row ranked 1 comes first');
        Assert.AreEqual(Keyed.Status::Active, Keyed.Status, 'and it is the Active row, unlike under the mixed key');

        Assert.AreEqual(1, Keyed.Next(), 'Next() must step to Ext Rank 5');
        Assert.AreEqual(5, Keyed."Ext Rank", 'rank 5 is second when Status is not part of the key');
    end;

    // ── InitValue declared on a tableextension field ─────────────────────────────────────

    [Test]
    procedure TableExt_Field_InitValue_Init_OverwritesAnAlreadyAssignedValue()
    // CLAIM: InitValue = 7 declared on a field that a tableextension added is applied by
    // Init(). The field is assigned 99 first, so a pass cannot come from the field merely
    // never having been written — Init() has to actively put 7 there.
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();

        Keyed."Ext Rank" := 99;
        Assert.AreEqual(99, Keyed."Ext Rank", 'precondition: the extension field holds 99 before Init()');

        Keyed.Init();

        Assert.AreEqual(7, Keyed."Ext Rank", 'Init() must apply the tableextension field''s InitValue of 7');
    end;

    [Test]
    procedure TableExt_Field_NoInitValue_Init_ResetsToTheTypeDefault()
    // CONTROL ARM for the test above. "Ext Tag" is added by the same tableextension and
    // declares no InitValue, so the same Init() call clears it. Without this, the 7 above
    // could have come from Init() stamping some blanket value across extension fields.
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();

        Keyed."Ext Tag" := 'TAGGED';
        Keyed."Ext Rank" := 99;
        Assert.AreEqual('TAGGED', Keyed."Ext Tag", 'precondition: the extension field holds a value before Init()');

        Keyed.Init();

        Assert.AreEqual('', Keyed."Ext Tag", 'an extension field with no InitValue must be reset to the empty Code value');
        Assert.AreEqual(7, Keyed."Ext Rank", 'the same Init() call must still apply the OTHER field''s InitValue');
    end;

    [Test]
    procedure TableExt_Field_InitValue_InsertThenGet_PersistsTheInitValue()
    // CLAIM: the InitValue an extension field received from Init() is what gets stored, so a
    // row inserted without ever touching "Ext Rank" reads back as 7 rather than 0.
    var
        Keyed: Record "ALT Keyed";
        Reread: Record "ALT Keyed";
    begin
        Initialize();

        Keyed.Init();
        Keyed."Entry No." := 1;
        Keyed.Insert(false);

        Assert.IsTrue(Reread.Get(1), 'the inserted row must be readable');
        Assert.AreEqual(7, Reread."Ext Rank", 'the stored value must be the InitValue, not the Integer default 0');
        Assert.AreEqual('', Reread."Ext Tag", 'the extension field without an InitValue must have stored the empty value');
    end;

    // ── The extension field in an error message and in metadata ──────────────────────────

    [Test]
    procedure TableExt_Field_TestField_BlankExtensionField_ErrorNamesTheExtensionField()
    // CLAIM (negative direction): TestField on a blank field added by a tableextension raises
    // the platform's own "must have a value" error and names the extension field, exactly as
    // it does for a field declared on the table. Asserting the phrase rather than merely that
    // something threw is what makes this a statement about the extension field's caption
    // reaching BC's message builder.
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();

        Keyed.Init();
        Keyed."Entry No." := 1;
        Keyed."Ext Rank" := 0;
        Keyed.Insert(false);
        Keyed.Get(1);
        Assert.AreEqual(0, Keyed."Ext Rank", 'precondition: the extension field must be blank for TestField to reject it');

        asserterror Keyed.TestField("Ext Rank");

        Assert.ExpectedError('Ext Rank must have a value');
    end;

    [Test]
    procedure TableExt_Field_TestField_NonBlankExtensionField_DoesNotThrow()
    // CONTROL ARM for the test above, on the same row and through the same call: TestField
    // accepts the extension field once it holds 42, and rejects it again the moment the value
    // goes back to blank. That pairing is what makes the error above a statement about the
    // VALUE rather than about TestField refusing tableextension fields outright.
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();

        Keyed.Init();
        Keyed."Entry No." := 1;
        Keyed."Ext Rank" := 42;
        Keyed.Insert(false);
        Keyed.Get(1);

        Keyed.TestField("Ext Rank");
        Assert.AreEqual(42, Keyed."Ext Rank", 'TestField must accept and preserve a non-blank extension field');

        Keyed."Ext Rank" := 0;
        asserterror Keyed.TestField("Ext Rank");
        Assert.ExpectedError('Ext Rank must have a value');
    end;

    [Test]
    procedure TableExt_Key_ExtensionKeys_AreListedAmongTheExtendedTablesKeys()
    // CLAIM: a key a tableextension declares is part of the extended table's key list as the
    // platform reports it through RecordRef — both the key built only from the extension field
    // and the one mixing a base field with it, each with the field composition it was declared
    // with. The keys are located by scanning rather than by index, because the platform also
    // exposes keys nobody declared (the implicit SystemId key), so a positional assertion would
    // be a claim about that rather than about the tableextension.
    var
        RecRef: RecordRef;
        KRef: KeyRef;
        i: Integer;
        ExtRankKeyIndex: Integer;
        ExtMixedKeyIndex: Integer;
    begin
        Initialize();

        RecRef.Open(60006); // ALT Keyed, extended by tableextension "ALT Keyed Ext" (60330)

        // 4 keys ALT Keyed declares itself + the 2 the tableextension declares. A lower bound,
        // because the platform's own implicit keys are not this test's subject.
        Assert.IsTrue(RecRef.KeyCount() >= 6,
            'the extended table must expose at least its own 4 keys plus the 2 the tableextension declares');

        // The field-count check has to guard the index call from OUTSIDE the boolean
        // expression. AL evaluates both operands of `and`, so writing
        // `(KRef.FieldCount() = 2) and (KRef.FieldIndex(2).Name() = 'Ext Rank')` calls
        // FieldIndex(2) on every one-field key in the list and raises "Index out of bounds"
        // before the scan reaches the keys this test is about. Nesting is what actually
        // guards it. Pinned by
        // Boolean_AND_FalseLeftOperand_RightOperandThatRaises_StillRaises in
        // "Test Type System Contracts".
        for i := 1 to RecRef.KeyCount() do begin
            KRef := RecRef.KeyIndex(i);
            if KRef.FieldCount() = 1 then
                if KRef.FieldIndex(1).Name() = 'Ext Rank' then
                    ExtRankKeyIndex := i;
            if KRef.FieldCount() = 2 then
                if (KRef.FieldIndex(1).Name() = 'Status') and (KRef.FieldIndex(2).Name() = 'Ext Rank') then
                    ExtMixedKeyIndex := i;
        end;

        Assert.AreNotEqual(0, ExtRankKeyIndex,
            'key(ExtRank; "Ext Rank") declared by the tableextension must appear in the key list');
        Assert.AreNotEqual(0, ExtMixedKeyIndex,
            'key(ExtMixed; "Status", "Ext Rank") declared by the tableextension must appear in the key list, '
            + 'with the base field leading and the extension field second');
        Assert.AreNotEqual(ExtRankKeyIndex, ExtMixedKeyIndex,
            'the two tableextension keys must be two distinct entries, not one entry matched twice');

        RecRef.Close();
    end;

    // ── Added by writer bs (corpus issue #668, items 90 and 91): objects in lt-bs-tableext-leads/BsObjects.al ──

    local procedure BsSeedBase()
    var
        Base: Record "LT BS Base";
    begin
        Base.DeleteAll();
        BsInsertBase(1, 30, 'c', 1.5, 1, 10);
        BsInsertBase(2, 10, 'b', 2.25, 1, 20);
        BsInsertBase(3, 20, 'a', 4, 2, 40);
        BsInsertBase(4, 10, 'a', 8, 2, 80);
    end;

    local procedure BsInsertBase(Id: Integer; A: Integer; Name: Text[30]; B: Decimal; E1: Integer; E2: Decimal)
    var
        Base: Record "LT BS Base";
    begin
        Base.Init();
        Base.Id := Id;
        Base.A := A;
        Base.Name := Name;
        Base.B := B;
        Base.E1 := E1;
        Base.E2 := E2;
        Base.Insert();
    end;

    local procedure BsOrder(var Base: Record "LT BS Base"): Text
    var
        Result: Text;
    begin
        if Base.FindSet() then
            repeat
                Result += Format(Base.Id) + ';';
            until Base.Next() = 0;
        exit(Result);
    end;

    local procedure BsKeyList(TableNo: Integer): Text
    var
        RecRef: RecordRef;
        KRef: KeyRef;
        Index: Integer;
        FieldIndex: Integer;
        Result: Text;
    begin
        RecRef.Open(TableNo);
        for Index := 1 to RecRef.KeyCount() do begin
            KRef := RecRef.KeyIndex(Index);
            Result += Format(Index) + ':' + Format(KRef.FieldCount()) + ':';
            for FieldIndex := 1 to KRef.FieldCount() do
                Result += KRef.FieldIndex(FieldIndex).Name() + ',';
            Result += ';';
        end;
        RecRef.Close();
        exit(Result);
    end;

    [Test]
    procedure TableExt_Key_BaseFieldsOnly_SetCurrentKeyAndKeyList()
    // CLAIM (issue #668 items 90, 91): a tableextension key that lists only fields of the base table (key(BsBaseOnly; A, Name)) compiles.
    // Does SetCurrentKey(A, Name) sort by it, what does CurrentKey answer, and does the key show in the key list?
    var
        Observer: Codeunit "Probe Observer";
        Base: Record "LT BS Base";
    begin
        BsSeedBase();
        Base.SetCurrentKey(A, Name);
        Observer.Observe('current_key', Base.CurrentKey());
        Observer.Observe('order', BsOrder(Base));
        Base.SetCurrentKey(E1);
        Observer.Observe('current_key_ext_sum_key', Base.CurrentKey());
        Observer.Observe('key_list', BsKeyList(Database::"LT BS Base"));
        Observer.Expect('current_key', 'A,Name');
        Observer.Expect('order', '4;2;3;1;');
        Observer.Expect('current_key_ext_sum_key', 'E1');
        Observer.Expect('key_list', '1:1:Id,;2:2:A,Name,;3:1:E1,;4:1:$systemId,;');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_Key_SumIndexFieldsBaseAndExtension_CalcSums()
    // CLAIM (issue #668 item 90): key(BsExtSum; E1) { SumIndexFields = B, E2; } in a tableextension names a base field and an extension
    // field (warning AL0836 only). What do CalcSums(B, E2) give per E1 filter?
    var
        Observer: Codeunit "Probe Observer";
        Base: Record "LT BS Base";
    begin
        BsSeedBase();
        Base.SetCurrentKey(E1);
        Base.SetRange(E1, 1);
        Base.CalcSums(B, E2);
        Observer.Observe('e1_1_sum_b', Format(Base.B, 0, 9));
        Observer.Observe('e1_1_sum_e2', Format(Base.E2, 0, 9));
        Base.SetRange(E1, 2);
        Base.CalcSums(B, E2);
        Observer.Observe('e1_2_sum_b', Format(Base.B, 0, 9));
        Observer.Observe('e1_2_sum_e2', Format(Base.E2, 0, 9));
        Base.SetRange(E1);
        Base.SetRange(A, 10);
        Base.CalcSums(B);
        Observer.Observe('a_10_sum_b', Format(Base.B, 0, 9));
        Observer.Expect('e1_1_sum_b', '3.75');
        Observer.Expect('e1_1_sum_e2', '30');
        Observer.Expect('e1_2_sum_b', '12');
        Observer.Expect('e1_2_sum_e2', '120');
        Observer.Expect('a_10_sum_b', '10.25');
        Observer.Verify();
    end;

    [Test]
    procedure Table_Key_MoreThan16Fields_SetCurrentKeyAndKeyList()
    // CLAIM (issue #668 item 91): the docs say only the first 16 fields of a key are used. A table with a 17-field and a 19-field key
    // compiles and publishes(?). What does the key list hold, and does SetCurrentKey over all 17 fields sort by them (the rows differ only in
    // F18, the 17th field of key K17)?
    var
        Observer: Codeunit "Probe Observer";
        Wide: Record "LT BS Wide Key";
        Index: Integer;
        Result: Text;
    begin
        Wide.DeleteAll();
        for Index := 1 to 3 do begin
            Wide.Init();
            Wide.F1 := Index;
            Wide.F18 := 10 - Index;
            Wide.F19 := Index * 2;
            Wide.Insert();
        end;
        Wide.SetCurrentKey(F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16, F17, F18);
        Observer.Observe('current_key_17', Wide.CurrentKey());
        if Wide.FindSet() then
            repeat
                Result += Format(Wide.F1) + ';';
            until Wide.Next() = 0;
        Observer.Observe('order_17', Result);
        Wide.SetCurrentKey(F20, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16, F17, F18, F19, F2);
        Observer.Observe('current_key_19', Wide.CurrentKey());
        Observer.Observe('key_list', BsKeyList(Database::"LT BS Wide Key"));
        Observer.Expect('current_key_17', 'F2,F3,F4,F5,F6,F7,F8,F9,F10,F11,F12,F13,F14,F15,F16,F17,F18');
        Observer.Expect('order_17', '3;2;1;');
        Observer.Expect('current_key_19', 'F20,F3,F4,F5,F6,F7,F8,F9,F10,F11,F12,F13,F14,F15,F16,F17,F18,F19,F2');
        Observer.Expect('key_list', '1:1:F1,;2:17:F2,F3,F4,F5,F6,F7,F8,F9,F10,F11,F12,F13,F14,F15,F16,F17,F18,;3:19:F20,F3,F4,F5,F6,F7,F8,F9,F10,F11,F12,F13,F14,F15,F16,F17,F18,F19,F2,;4:1:$systemId,;');
        Observer.Verify();
    end;

    // Writer QB (corpus issue #664 item 97): a tableextension that runs addlast(Brick; ...) on a table without a Brick field group
    // (QbFieldGroupBrick.al) compiles and publishes. Field groups have no AL API, so the test reads the row and the field list only.
    [Test]
    procedure TableExt_FieldGroups_AddLastBrickWithoutBaseBrick_Publishes_QB()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QB Fg Base";
        RecRef: RecordRef;
    begin
        Row.DeleteAll();
        Row."No." := 'QB1';
        Row.Description := 'Desc';
        Row."QB Extra" := 'Extra';
        Row.Insert();
        Row.Get('QB1');
        Observer.Observe('row', Row."No." + '|' + Row.Description + '|' + Row."QB Extra");
        RecRef.Open(Database::"LT QB Fg Base");
        Observer.Observe('field 86393', RecRef.Field(86393).Name());
        RecRef.Close();
        Observer.Expect('row', 'QB1|Desc|Extra');
        Observer.Expect('field 86393', 'QB Extra');
        Observer.Verify();
    end;
}
