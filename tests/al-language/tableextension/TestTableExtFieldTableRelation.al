// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none - Base Application's own Customer (18), Service Zone (5957) and
//   Territory (286) tables; shared Assert (60021)
// BC versions: 27.0+
//
// CLAIM: a TableRelation contributed by a TABLEEXTENSION is enforced by Validate exactly as
// one declared on the base table is. Nothing about the enforcement depends on where the
// relation was declared.
//
// The corpus already asserts that BC enforces a TableRelation, but only on fields declared
// on a plain table (fieldref/TestFieldRefRelation.al, access-control/TestUserTableSessionUser.al).
// Neither of those touches a tableextension, so "BC enforces a relation a tableextension added"
// was not pinned anywhere.
//
// SUBJECT: Customer 5900 "Service Zone Code" (Code[10], TableRelation = "Service Zone"),
// contributed by tableextension 6450 "Serv. Customer" shipped INSIDE the Base Application
// package. It is not on Customer's own field list. It is the right subject because it carries
// neither an OnValidate trigger nor a ValidateTableRelation property, so the relation check is
// the only thing in Validate that can raise -- unlike Item."Routing No." (an OnValidate calling
// TestField and PlanningAssignment) or "Requisition Line"."Prod. Order No." (both an OnValidate
// and a ValidateTableRelation), either of which could refuse a value for an unrelated reason.
//
// CONTROL: Customer 15 "Territory Code" (Code[10], TableRelation = Territory), declared on the
// BASE table 18 itself and structurally identical -- Code[10], plain single-arm relation to a
// two-field code table, no trigger, no ValidateTableRelation. The two pairs of tests differ in
// exactly one thing: which object declared the relation. That is what makes "exactly as one
// declared on the base table" an assertion rather than a phrase.
//
// WHY THIS CANNOT PASS VACUOUSLY: within each pair the SAME code value is fed to the SAME
// field, and the only thing that changes between the two tests is whether the related row
// exists. So an implementation that refused every value fails the accepting test, and one that
// checked nothing fails the refusing test. The accepting test also pins that the relation
// resolved to the RIGHT related table -- inserting a "Service Zone" row would not rescue a
// relation that had resolved to some other table. The last test adds the third direction: a
// direct assignment of the same unrelated value is NOT refused, so the refusal above comes from
// Validate's relation check and not from the value, the field length, or the field itself.
//
// The Customer buffer is never inserted -- Init() plus Validate() is the whole scenario -- so no
// number series, no insert trigger and no customer master data is involved. Initialize()
// therefore deletes only the two related-table rows this codeunit creates (filtered on ALTTR*)
// and never touches Customer, whose rows belong to the company, not to this test.
codeunit 60827 "Test TableExt Field Relation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TableExt_Validate_ContributedRelation_NoRelatedRow_Throws()
    // CLAIM: Validate on a field whose TableRelation came from a tableextension refuses a value
    // that has no row in the related table.
    var
        Cust: Record Customer;
    begin
        Initialize();

        // [GIVEN] No "Service Zone" row carries this code (Initialize deleted it).
        Clear(Cust);
        Cust.Init();

        // [WHEN/THEN] Validating the tableextension-contributed field with it is refused.
        asserterror Cust.Validate("Service Zone Code", 'ALTTRZONE1');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure TableExt_Validate_ContributedRelation_RelatedRowExists_AssignsTheValue()
    // CLAIM: the SAME value the test above refused is accepted once the related row exists, so
    // the refusal was the relation check and not a blanket rejection.
    var
        Cust: Record Customer;
    begin
        Initialize();

        // [GIVEN] A "Service Zone" row with exactly the code the previous test was refused.
        InsertServiceZone('ALTTRZONE1');

        // [WHEN] The tableextension-contributed field is validated with it.
        Clear(Cust);
        Cust.Init();
        Cust.Validate("Service Zone Code", 'ALTTRZONE1');

        // [THEN] Validate succeeds and the field holds the value.
        Assert.AreEqual(
            'ALTTRZONE1', Cust."Service Zone Code",
            'Validate must accept a value that exists in the table the tableextension-contributed ' +
            'TableRelation points at, and store it');
    end;

    [Test]
    procedure TableExt_Validate_BaseTableRelation_NoRelatedRow_Throws()
    // CLAIM: control -- a relation declared on the BASE table refuses an unrelated value the
    // same way, so the pair above is measuring the relation and not something about Customer.
    var
        Cust: Record Customer;
    begin
        Initialize();

        // [GIVEN] No Territory row carries this code (Initialize deleted it).
        Clear(Cust);
        Cust.Init();

        // [WHEN/THEN] Validating the base-table-declared field with it is refused, with the
        // same error the tableextension-contributed field raised.
        asserterror Cust.Validate("Territory Code", 'ALTTRTERR1');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure TableExt_Validate_BaseTableRelation_RelatedRowExists_AssignsTheValue()
    // CLAIM: control -- the base-table-declared relation accepts the same value once the
    // related row exists.
    var
        Cust: Record Customer;
    begin
        Initialize();

        // [GIVEN] A Territory row with exactly the code the previous test was refused.
        InsertTerritory('ALTTRTERR1');

        // [WHEN] The base-table-declared field is validated with it.
        Clear(Cust);
        Cust.Init();
        Cust.Validate("Territory Code", 'ALTTRTERR1');

        // [THEN] Validate succeeds and the field holds the value.
        Assert.AreEqual(
            'ALTTRTERR1', Cust."Territory Code",
            'Validate must accept a value that exists in the table the base-table-declared ' +
            'TableRelation points at, and store it');
    end;

    [Test]
    procedure TableExt_Assign_ContributedRelation_NoRelatedRow_IsNotChecked()
    // CLAIM: a direct assignment bypasses the tableextension-contributed relation entirely, so
    // the refusal in the first test is Validate's relation check -- not the value, and not the
    // field.
    var
        Cust: Record Customer;
    begin
        Initialize();

        // [GIVEN] No "Service Zone" row carries this code.
        Clear(Cust);
        Cust.Init();

        // [WHEN] The value is assigned directly rather than validated.
        Cust."Service Zone Code" := 'ALTTRZONE1';

        // [THEN] The assignment stands -- no relation check ran.
        Assert.AreEqual(
            'ALTTRZONE1', Cust."Service Zone Code",
            'A direct assignment must not consult the tableextension-contributed TableRelation');
    end;

    local procedure Initialize()
    var
        ServiceZone: Record "Service Zone";
        Terr: Record Territory;
    begin
        // Only this codeunit's own rows: Customer, Service Zone and Territory are company data,
        // and a blanket DeleteAll on them would destroy rows this test did not create. No
        // Customer row is ever written, so none has to be removed.
        ServiceZone.Reset();
        ServiceZone.SetFilter(Code, 'ALTTR*');
        ServiceZone.DeleteAll(false);

        Terr.Reset();
        Terr.SetFilter(Code, 'ALTTR*');
        Terr.DeleteAll(false);
    end;

    local procedure InsertServiceZone(ZoneCode: Code[10])
    var
        ServiceZone: Record "Service Zone";
    begin
        ServiceZone.Init();
        ServiceZone.Code := ZoneCode;
        ServiceZone.Description := 'Relation subject';
        ServiceZone.Insert(false);
    end;

    local procedure InsertTerritory(TerritoryCode: Code[10])
    var
        Terr: Record Territory;
    begin
        Terr.Init();
        Terr.Code := TerritoryCode;
        Terr.Name := 'Relation control';
        Terr.Insert(false);
    end;

    // ── Added by writer bs (corpus issue #668, item 97): objects in lt-bs-tableext-leads/BsObjects.al ──
    // LT BS Base.Ref has TableRelation = "LT BS Target A"; tableextension LT BS Base Ext One adds modify(Ref) { TableRelation = "LT BS Target B"; }.
    // LT BS Base.Cond has TableRelation = if (Kind = const(X)) "LT BS Target A"; the extension adds if (Kind = const(Y)) "LT BS Target B".
    // Docs: "the first unconditional relation will prevail".

    local procedure BsSeedTargets()
    var
        TA: Record "LT BS Target A";
        TB: Record "LT BS Target B";
    begin
        TA.DeleteAll();
        TB.DeleteAll();
        TA.Code := 'ONLYA';
        TA.Insert();
        TA.Code := 'BOTH';
        TA.Insert();
        TB.Code := 'ONLYB';
        TB.Insert();
        TB.Code := 'BOTH';
        TB.Insert();
    end;

    [TryFunction]
    local procedure BsTryValidate(var Base: Record "LT BS Base"; FieldNo: Integer; Value: Code[20])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Base);
        RecRef.Field(FieldNo).Validate(Value);
        RecRef.SetTable(Base);
    end;

    local procedure BsProbe(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Option; FieldNo: Integer; Value: Code[20])
    var
        Base: Record "LT BS Base";
    begin
        Base.Init();
        Base.Id := 1;
        Base.Kind := Kind;
        ClearLastError();
        Observer.Observe(Name, Format(BsTryValidate(Base, FieldNo, Value)));
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure TableExt_ModifyTableRelation_Unconditional_ValidateUsesWhichTable()
    var
        Observer: Codeunit "Probe Observer";
        Base: Record "LT BS Base";
        FieldRec: Record Field;
    begin
        BsSeedTargets();
        BsProbe(Observer, 'ref_only_a', Base.Kind::X, 5, 'ONLYA');
        BsProbe(Observer, 'ref_only_b', Base.Kind::X, 5, 'ONLYB');
        BsProbe(Observer, 'ref_both', Base.Kind::X, 5, 'BOTH');
        BsProbe(Observer, 'ref_none', Base.Kind::X, 5, 'NONE');
        FieldRec.Get(Database::"LT BS Base", 5);
        Observer.Observe('ref_relation_table_no', Format(FieldRec.RelationTableNo));
        Observer.Expect('ref_only_a', 'Yes');
        Observer.Expect('ref_only_a|text', '');
        Observer.Expect('ref_only_a|code', '');
        Observer.Expect('ref_only_b', 'No');
        Observer.Expect('ref_only_b|text', 'The field Ref of table LT BS Ext Caption contains a value (ONLYB) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('ref_only_b|code', 'DB:PrimRecordNotFound');
        Observer.Expect('ref_both', 'Yes');
        Observer.Expect('ref_both|text', '');
        Observer.Expect('ref_both|code', '');
        Observer.Expect('ref_none', 'No');
        Observer.Expect('ref_none|text', 'The field Ref of table LT BS Ext Caption contains a value (NONE) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('ref_none|code', 'DB:PrimRecordNotFound');
        Observer.Expect('ref_relation_table_no', '83151');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_ModifyTableRelation_Conditional_ValidatePerCondition()
    var
        Observer: Codeunit "Probe Observer";
        Base: Record "LT BS Base";
    begin
        BsSeedTargets();
        BsProbe(Observer, 'x_only_a', Base.Kind::X, 7, 'ONLYA');
        BsProbe(Observer, 'x_only_b', Base.Kind::X, 7, 'ONLYB');
        BsProbe(Observer, 'y_only_a', Base.Kind::Y, 7, 'ONLYA');
        BsProbe(Observer, 'y_only_b', Base.Kind::Y, 7, 'ONLYB');
        BsProbe(Observer, 'z_none', Base.Kind::Z, 7, 'NONE');
        Observer.Expect('x_only_a', 'Yes');
        Observer.Expect('x_only_a|text', '');
        Observer.Expect('x_only_a|code', '');
        Observer.Expect('x_only_b', 'No');
        Observer.Expect('x_only_b|text', 'The field Cond of table LT BS Ext Caption contains a value (ONLYB) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('x_only_b|code', 'DB:PrimRecordNotFound');
        Observer.Expect('y_only_a', 'No');
        Observer.Expect('y_only_a|text', 'The field Cond of table LT BS Ext Caption contains a value (ONLYA) that cannot be found in the related table (LT BS Target B).');
        Observer.Expect('y_only_a|code', 'DB:PrimRecordNotFound');
        Observer.Expect('y_only_b', 'Yes');
        Observer.Expect('y_only_b|text', '');
        Observer.Expect('y_only_b|code', '');
        Observer.Expect('z_none', 'Yes');
        Observer.Expect('z_none|text', '');
        Observer.Expect('z_none|code', '');
        Observer.Verify();
    end;

    // ---- writer PY-D (2026-10-20): more modify(TableRelation) combinations (objects in lt-pyd-relation/PydRelationObjects.al) ----

    [TryFunction]
    local procedure PydTryValidate(var Base: Record "LT PYD Rel Base"; FieldNo: Integer; Value: Code[20])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Base);
        RecRef.Field(FieldNo).Validate(Value);
        RecRef.SetTable(Base);
    end;

    local procedure PydProbe(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Option; FieldNo: Integer; Value: Code[20])
    var
        Base: Record "LT PYD Rel Base";
    begin
        Base.Init();
        Base.Id := 1;
        Base.Kind := Kind;
        ClearLastError();
        Observer.Observe(Name, Format(PydTryValidate(Base, FieldNo, Value)));
        Observer.ObserveError(Name);
    end;

    local procedure PydAll(var Observer: Codeunit "Probe Observer"; Prefix: Text; FieldNo: Integer; Part: Integer)
    var
        Base: Record "LT PYD Rel Base";
    begin
        BsSeedTargets();
        if Part = 2 then begin
            PydProbe(Observer, Prefix + 'z_a', Base.Kind::Z, FieldNo, 'ONLYA');
            PydProbe(Observer, Prefix + 'z_b', Base.Kind::Z, FieldNo, 'ONLYB');
            PydProbe(Observer, Prefix + 'z_none', Base.Kind::Z, FieldNo, 'NONE');
            exit;
        end;
        PydProbe(Observer, Prefix + 'x_a', Base.Kind::X, FieldNo, 'ONLYA');
        PydProbe(Observer, Prefix + 'x_b', Base.Kind::X, FieldNo, 'ONLYB');
        PydProbe(Observer, Prefix + 'y_a', Base.Kind::Y, FieldNo, 'ONLYA');
        PydProbe(Observer, Prefix + 'y_b', Base.Kind::Y, FieldNo, 'ONLYB');
    end;

    local procedure PydRelNo(var Observer: Codeunit "Probe Observer"; FieldNo: Integer)
    var
        FieldRec: Record Field;
    begin
        FieldRec.Get(Database::"LT PYD Rel Base", FieldNo);
        Observer.Observe('relation_table_no', Format(FieldRec.RelationTableNo));
    end;

    [Test]
    procedure PYD_ModifyTableRelation_BaseConditional_ExtUnconditional_XY()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydAll(Observer, 'mix_', 3, 1);
        PydRelNo(Observer, 3);
        Observer.Expect('mix_x_a', 'Yes');
        Observer.Expect('mix_x_a|text', '');
        Observer.Expect('mix_x_a|code', '');
        Observer.Expect('mix_x_b', 'No');
        Observer.Expect('mix_x_b|text', 'The field MixCond of table LT PYD Rel Base contains a value (ONLYB) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('mix_x_b|code', 'DB:PrimRecordNotFound');
        Observer.Expect('mix_y_a', 'No');
        Observer.Expect('mix_y_a|text', 'The field MixCond of table LT PYD Rel Base contains a value (ONLYA) that cannot be found in the related table (LT BS Target B).');
        Observer.Expect('mix_y_a|code', 'DB:PrimRecordNotFound');
        Observer.Expect('mix_y_b', 'Yes');
        Observer.Expect('mix_y_b|text', '');
        Observer.Expect('mix_y_b|code', '');
        Observer.Expect('relation_table_no', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_ModifyTableRelation_BaseConditional_ExtUnconditional_Z()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydAll(Observer, 'mix_', 3, 2);
        Observer.Expect('mix_z_a', 'No');
        Observer.Expect('mix_z_a|text', 'The field MixCond of table LT PYD Rel Base contains a value (ONLYA) that cannot be found in the related table (LT BS Target B).');
        Observer.Expect('mix_z_a|code', 'DB:PrimRecordNotFound');
        Observer.Expect('mix_z_b', 'Yes');
        Observer.Expect('mix_z_b|text', '');
        Observer.Expect('mix_z_b|code', '');
        Observer.Expect('mix_z_none', 'No');
        Observer.Expect('mix_z_none|text', 'The field MixCond of table LT PYD Rel Base contains a value (NONE) that cannot be found in the related table (LT BS Target B).');
        Observer.Expect('mix_z_none|code', 'DB:PrimRecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_ModifyTableRelation_BaseElseArm_ExtConditional_XY()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydAll(Observer, 'else_', 4, 1);
        PydRelNo(Observer, 4);
        Observer.Expect('else_x_a', 'Yes');
        Observer.Expect('else_x_a|text', '');
        Observer.Expect('else_x_a|code', '');
        Observer.Expect('else_x_b', 'No');
        Observer.Expect('else_x_b|text', 'The field ElseArm of table LT PYD Rel Base contains a value (ONLYB) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('else_x_b|code', 'DB:PrimRecordNotFound');
        Observer.Expect('else_y_a', 'No');
        Observer.Expect('else_y_a|text', 'The field ElseArm of table LT PYD Rel Base contains a value (ONLYA) that cannot be found in the related table (LT BS Target B).');
        Observer.Expect('else_y_a|code', 'DB:PrimRecordNotFound');
        Observer.Expect('else_y_b', 'Yes');
        Observer.Expect('else_y_b|text', '');
        Observer.Expect('else_y_b|code', '');
        Observer.Expect('relation_table_no', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_ModifyTableRelation_BaseElseArm_ExtConditional_Z()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydAll(Observer, 'else_', 4, 2);
        Observer.Expect('else_z_a', 'No');
        Observer.Expect('else_z_a|text', 'The field ElseArm of table LT PYD Rel Base contains a value (ONLYA) that cannot be found in the related table (LT BS Target B).');
        Observer.Expect('else_z_a|code', 'DB:PrimRecordNotFound');
        Observer.Expect('else_z_b', 'Yes');
        Observer.Expect('else_z_b|text', '');
        Observer.Expect('else_z_b|code', '');
        Observer.Expect('else_z_none', 'No');
        Observer.Expect('else_z_none|text', 'The field ElseArm of table LT PYD Rel Base contains a value (NONE) that cannot be found in the related table (LT BS Target B).');
        Observer.Expect('else_z_none|code', 'DB:PrimRecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_ModifyTableRelation_TwoExtensions_Conditional_XY()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydAll(Observer, 'two_', 5, 1);
        PydRelNo(Observer, 5);
        Observer.Expect('two_x_a', 'Yes');
        Observer.Expect('two_x_a|text', '');
        Observer.Expect('two_x_a|code', '');
        Observer.Expect('two_x_b', 'No');
        Observer.Expect('two_x_b|text', 'The field TwoExtCond of table LT PYD Rel Base contains a value (ONLYB) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('two_x_b|code', 'DB:PrimRecordNotFound');
        Observer.Expect('two_y_a', 'No');
        Observer.Expect('two_y_a|text', 'The field TwoExtCond of table LT PYD Rel Base contains a value (ONLYA) that cannot be found in the related table (LT BS Target B).');
        Observer.Expect('two_y_a|code', 'DB:PrimRecordNotFound');
        Observer.Expect('two_y_b', 'Yes');
        Observer.Expect('two_y_b|text', '');
        Observer.Expect('two_y_b|code', '');
        Observer.Expect('relation_table_no', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_ModifyTableRelation_TwoExtensions_Conditional_Z()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydAll(Observer, 'two_', 5, 2);
        Observer.Expect('two_z_a', 'Yes');
        Observer.Expect('two_z_a|text', '');
        Observer.Expect('two_z_a|code', '');
        Observer.Expect('two_z_b', 'No');
        Observer.Expect('two_z_b|text', 'The field TwoExtCond of table LT PYD Rel Base contains a value (ONLYB) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('two_z_b|code', 'DB:PrimRecordNotFound');
        Observer.Expect('two_z_none', 'No');
        Observer.Expect('two_z_none|text', 'The field TwoExtCond of table LT PYD Rel Base contains a value (NONE) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('two_z_none|code', 'DB:PrimRecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_ModifyTableRelation_TwoExtensions_Unconditional_XY()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydAll(Observer, 'twou_', 6, 1);
        PydRelNo(Observer, 6);
        Observer.Expect('twou_x_a', 'Yes');
        Observer.Expect('twou_x_a|text', '');
        Observer.Expect('twou_x_a|code', '');
        Observer.Expect('twou_x_b', 'No');
        Observer.Expect('twou_x_b|text', 'The field TwoExtUncond of table LT PYD Rel Base contains a value (ONLYB) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('twou_x_b|code', 'DB:PrimRecordNotFound');
        Observer.Expect('twou_y_a', 'No');
        Observer.Expect('twou_y_a|text', 'The field TwoExtUncond of table LT PYD Rel Base contains a value (ONLYA) that cannot be found in the related table (LT BS Target B).');
        Observer.Expect('twou_y_a|code', 'DB:PrimRecordNotFound');
        Observer.Expect('twou_y_b', 'Yes');
        Observer.Expect('twou_y_b|text', '');
        Observer.Expect('twou_y_b|code', '');
        Observer.Expect('relation_table_no', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_ModifyTableRelation_TwoExtensions_Unconditional_Z()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydAll(Observer, 'twou_', 6, 2);
        Observer.Expect('twou_z_a', 'No');
        Observer.Expect('twou_z_a|text', 'The field TwoExtUncond of table LT PYD Rel Base contains a value (ONLYA) that cannot be found in the related table (LT BS Target B).');
        Observer.Expect('twou_z_a|code', 'DB:PrimRecordNotFound');
        Observer.Expect('twou_z_b', 'Yes');
        Observer.Expect('twou_z_b|text', '');
        Observer.Expect('twou_z_b|code', '');
        Observer.Expect('twou_z_none', 'No');
        Observer.Expect('twou_z_none|text', 'The field TwoExtUncond of table LT PYD Rel Base contains a value (NONE) that cannot be found in the related table (LT BS Target B).');
        Observer.Expect('twou_z_none|code', 'DB:PrimRecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_ModifyTableRelation_BaseUnconditional_ExtElseArm_XY()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydAll(Observer, 'ue_', 7, 1);
        PydRelNo(Observer, 7);
        Observer.Expect('ue_x_a', 'Yes');
        Observer.Expect('ue_x_a|text', '');
        Observer.Expect('ue_x_a|code', '');
        Observer.Expect('ue_x_b', 'No');
        Observer.Expect('ue_x_b|text', 'The field UncondThenElse of table LT PYD Rel Base contains a value (ONLYB) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('ue_x_b|code', 'DB:PrimRecordNotFound');
        Observer.Expect('ue_y_a', 'Yes');
        Observer.Expect('ue_y_a|text', '');
        Observer.Expect('ue_y_a|code', '');
        Observer.Expect('ue_y_b', 'No');
        Observer.Expect('ue_y_b|text', 'The field UncondThenElse of table LT PYD Rel Base contains a value (ONLYB) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('ue_y_b|code', 'DB:PrimRecordNotFound');
        Observer.Expect('relation_table_no', '83151');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_ModifyTableRelation_BaseUnconditional_ExtElseArm_Z()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydAll(Observer, 'ue_', 7, 2);
        Observer.Expect('ue_z_a', 'Yes');
        Observer.Expect('ue_z_a|text', '');
        Observer.Expect('ue_z_a|code', '');
        Observer.Expect('ue_z_b', 'No');
        Observer.Expect('ue_z_b|text', 'The field UncondThenElse of table LT PYD Rel Base contains a value (ONLYB) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('ue_z_b|code', 'DB:PrimRecordNotFound');
        Observer.Expect('ue_z_none', 'No');
        Observer.Expect('ue_z_none|text', 'The field UncondThenElse of table LT PYD Rel Base contains a value (NONE) that cannot be found in the related table (LT BS Target A).');
        Observer.Expect('ue_z_none|code', 'DB:PrimRecordNotFound');
        Observer.Verify();
    end;

    // ---- Writer SH, al-runner issue 5955: the RELATED table of a TableRelation has a tableextension with its own Caption.
    // Which caption does the Validate error text use for the related table (objects at the end of this file)?

    [Test]
    procedure TableExt_CaptionOfRelatedTable_InValidateErrorText()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT SH Rel Source";
        Target: Record "LT SH Rel Target";
        RecRef: RecordRef;
    begin
        Target.DeleteAll();
        Source.Init();
        Source."Entry No." := 1;
        asserterror Source.Validate("Target Code", 'NOWC');
        Observer.ObserveError('Record.Validate');
        RecRef.GetTable(Source);
        asserterror RecRef.Field(2).Validate('NOWC');
        Observer.ObserveError('FieldRef.Validate');
        Observer.Observe('target TableCaption', Target.TableCaption());
        Observer.Observe('source TableCaption', Source.TableCaption());
        Observer.Finish();
    end;
}

table 89426 "LT SH Rel Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

tableextension 89427 "LT SH Rel Target Ext" extends "LT SH Rel Target"
{
    Caption = 'LT SH Rel Target Extension Caption';
}

table 89428 "LT SH Rel Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Target Code"; Code[20]) { TableRelation = "LT SH Rel Target"; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
