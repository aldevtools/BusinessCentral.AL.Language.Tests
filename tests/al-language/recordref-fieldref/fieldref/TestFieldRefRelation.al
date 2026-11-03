// FieldRef.Relation — the related table's object id for the arm that currently applies.
//
// BC evaluates a field's TableRelation arms against the CURRENT record buffer and answers the
// id of the first arm whose if() conditions hold; a field with no TableRelation answers 0. The
// where() clause narrows which ROWS of the related table are valid, so it does not change the
// answer here — but a relation that carries one must still answer, and that is the case
// nothing in this corpus covered.
//
// A target may also be NAMESPACE-QUALIFIED -- Base Application writes
// `Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"` -- and in AL a namespace organises
// source rather than the name a relation resolves by, so the qualified form names the same table
// as the bare one. The last three tests pin that, on Base Application's own fields, in both the
// shape where the last name part is the table and the shape where it is a field.
//
// The BC-side answers asserted here are concrete table ids (60480, 60030, 225, 5832, 99000851,
// 2000000058, 0), never "non-zero", so an implementation that answered a fixed value could not
// pass.
//
// The three Validate tests at the end are about the ROLES in `where(A = field(B))`: A is a
// field of the RELATED table, B a field of the REFERENCING one. They can only make that
// distinction because ALTRelationWhereField.al names and numbers the two sides apart --
// "Parent Group" (field 5 of the parent) against "Child Group" (field 2 of the child). While
// both sides were spelled "Group Code" and both were field 2, an implementation that resolved
// each name against the other table produced the same field either way and every test here
// still passed. See that fixture's header for why renaming and renumbering are both needed.

codeunit 60482 "Test FieldRef Relation"
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

    [Test]
    procedure FieldRef_Relation_PlainRelation_ReturnsRelatedTableId()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Rel Where Child");
        FldRef := RecRef.Field(6);

        Assert.AreEqual(
            Database::"ALT Rel Where Parent", FldRef.Relation(),
            'a field declaring TableRelation = "ALT Rel Where Parent"."Code" must answer table 60480');
    end;

    [Test]
    procedure FieldRef_Relation_RelationWithWhereFieldLink_ReturnsRelatedTableId()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();

        // The subject. The where() clause restricts which parent ROWS are valid; it does not
        // make the relation itself unanswerable, so Relation is the same table id the plain
        // shape above answers.
        RecRef.Open(Database::"ALT Rel Where Child");
        FldRef := RecRef.Field(4);

        Assert.AreEqual(
            Database::"ALT Rel Where Parent", FldRef.Relation(),
            'a TableRelation narrowed by where("Parent Group" = field("Child Group")) must still ' +
            'answer the related table id 60480');
    end;

    [Test]
    procedure FieldRef_Relation_FieldWithoutTableRelation_ReturnsZero()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();

        // The negative direction, and the reason the assertions above have to name concrete
        // ids: 0 is what "no relation declared" means, so it must stay reachable.
        RecRef.Open(Database::"ALT Rel Where Child");
        FldRef := RecRef.Field(7);

        Assert.AreEqual(
            0, FldRef.Relation(),
            'a field declaring no TableRelation must answer 0');
    end;

    [Test]
    procedure FieldRef_Relation_ConditionalWithWhereFieldLink_SelectsTheIfArm()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        KindRef: FieldRef;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Rel Where Child");
        KindRef := RecRef.Field(3);
        KindRef.Value := 0; // Kind::A — the if() arm, which is the one carrying the where()

        FldRef := RecRef.Field(5);

        Assert.AreEqual(
            Database::"ALT Rel Where Parent", FldRef.Relation(),
            'with Kind = A the if() arm applies, so Relation must answer its target (60480)');
    end;

    [Test]
    procedure FieldRef_Relation_ConditionalWithWhereFieldLink_SelectsTheElseArm()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        KindRef: FieldRef;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Rel Where Child");
        KindRef := RecRef.Field(3);
        KindRef.Value := 1; // Kind::B — the else arm, a different target table

        FldRef := RecRef.Field(5);

        // A different id from the test above, on the same field of the same record — so an
        // implementation that answered the first arm regardless of the record's state fails
        // exactly one of the two.
        Assert.AreEqual(
            Database::"ALT Relation Parent B", FldRef.Relation(),
            'with Kind = B the else arm applies, so Relation must answer its target (60030)');
    end;

    [Test]
    procedure FieldRef_Relation_BaseApplicationFieldWithWhereFieldLink_ReturnsRelatedTableId()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Cust: Record Customer;
    begin
        Initialize();

        // The same shape on a table this app does not declare. Customer.City is
        //   if ("Country/Region Code" = const('')) "Post Code".City
        //   else if ("Country/Region Code" = filter(<> '')) "Post Code".City
        //        where("Country/Region Code" = field("Country/Region Code"))
        // and on a blank record the FIRST arm applies. Both arms name Post Code, so the answer
        // does not depend on which one BC picks — only on the whole property being readable.
        RecRef.Open(Database::Customer);
        FldRef := RecRef.Field(Cust.FieldNo(City));

        Assert.AreEqual(
            Database::"Post Code", FldRef.Relation(),
            'Customer.City declares TableRelation = "Post Code".City in both arms, so ' +
            'FieldRef.Relation must answer table 225');
    end;

    [Test]
    procedure FieldRef_Relation_BaseApplicationFieldWithoutTableRelation_ReturnsZero()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Cust: Record Customer;
    begin
        Initialize();

        // Control for the test above on the same table: Customer.Name declares no
        // TableRelation, so "every Base Application field answers non-zero" cannot pass.
        RecRef.Open(Database::Customer);
        FldRef := RecRef.Field(Cust.FieldNo(Name));

        Assert.AreEqual(
            0, FldRef.Relation(),
            'Customer.Name declares no TableRelation, so FieldRef.Relation must answer 0');
    end;

    [Test]
    procedure Validate_RelationWithWhereFieldLink_RefusesARowOutsideTheFilter()
    var
        Parent: Record "ALT Rel Where Parent";
        Child: Record "ALT Rel Where Child";
    begin
        Initialize();

        Parent.Init();
        Parent."Code" := 'P-OTHER';
        Parent."Parent Group" := 'G2';
        Parent.Insert();

        Child.Init();
        Child."Entry No." := 1;
        Child."Child Group" := 'G1';

        // P-OTHER exists, so this can only be refused because the where() clause narrowed the
        // related rows to Parent Group = G1 — which is what makes the field() link observable
        // rather than decorative.
        asserterror Child.Validate("Where Field Ref", 'P-OTHER');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure Validate_RelationWithWhereFieldLink_AcceptsARowInsideTheFilter()
    var
        Parent: Record "ALT Rel Where Parent";
        Child: Record "ALT Rel Where Child";
    begin
        Initialize();

        Parent.Init();
        Parent."Code" := 'P-SAME';
        Parent."Parent Group" := 'G1';
        Parent.Insert();

        Child.Init();
        Child."Entry No." := 1;
        Child."Child Group" := 'G1';

        // The positive direction of the test above: a relation that refused everything would
        // pass that one and fail this one.
        Child.Validate("Where Field Ref", 'P-SAME');

        Assert.AreEqual('P-SAME', Child."Where Field Ref",
            'a parent row inside the where() filter must be accepted and stored');
    end;

    [Test]
    procedure Validate_RelationWithWhereFieldLink_NarrowsToTheReferencingRowsOwnGroup()
    // CLAIM: where("Parent Group" = field("Child Group")) reads "Child Group" off the
    // REFERENCING row and matches it against "Parent Group" on the related rows — that
    // direction, not the reverse.
    //
    // The two tests above each put exactly ONE parent row in the table, so between them they
    // establish that the clause narrows at all, but not which row it narrows to: "refuses
    // everything when the groups differ" and "picks the caller's group" fit both equally. This
    // one has both candidate parents present at the same time and asks the field to choose,
    // which is the assertion the other two cannot make.
    //
    // The child sits in G2, the SECOND group inserted, so an implementation that ignored the
    // clause and took the first available parent row would answer P-G1 and fail here.
    var
        Parent: Record "ALT Rel Where Parent";
        Child: Record "ALT Rel Where Child";
    begin
        Initialize();

        Parent.Init();
        Parent."Code" := 'P-G1';
        Parent."Parent Group" := 'G1';
        Parent.Insert();

        Parent.Init();
        Parent."Code" := 'P-G2';
        Parent."Parent Group" := 'G2';
        Parent.Insert();

        Child.Init();
        Child."Entry No." := 1;
        Child."Child Group" := 'G2';

        // The parent whose "Parent Group" equals the child's "Child Group" is accepted...
        Child.Validate("Where Field Ref", 'P-G2');
        Assert.AreEqual('P-G2', Child."Where Field Ref",
            'the parent row whose "Parent Group" matches the referencing row''s "Child Group" ' +
            'must be accepted');

        // ...and the other one is refused, though it exists and is a perfectly good "Code".
        asserterror Child.Validate("Where Field Ref", 'P-G1');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure FieldRef_Relation_NamespaceQualifiedTarget_ReturnsRelatedTableId()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        ItemReg: Record "Item Register";
    begin
        Initialize();

        // A TableRelation may name its target through the target's NAMESPACE, and Base
        // Application does:
        //   Item Register."From Capacity Entry No."
        //     = Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"
        // The namespace is a source-organisation device; object names are global, so the
        // qualified name means the same table as the bare one and Relation must answer that
        // table's id. Nothing in this corpus covered a target with more than two name parts.
        RecRef.Open(Database::"Item Register");
        FldRef := RecRef.Field(ItemReg.FieldNo("From Capacity Entry No."));

        Assert.AreEqual(
            Database::"Capacity Ledger Entry", FldRef.Relation(),
            'a TableRelation naming Microsoft.Manufacturing.Capacity."Capacity Ledger Entry" ' +
            'must answer that table id (5832)');
    end;

    [Test]
    procedure FieldRef_Relation_NamespaceQualifiedTargetNamingAField_ReturnsRelatedTableId()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        InvtSetup: Record "Inventory Setup";
    begin
        Initialize();

        // The other namespace-qualified shape, and it disagrees with the one above about what
        // the LAST name part means:
        //   Inventory Setup."Current Demand Forecast"
        //     = Microsoft.Manufacturing.Forecast."Production Forecast Name".Name
        // Here the last part is the FIELD and the last-but-one is the table, where in the test
        // above the last part IS the table. Asserting both, with different expected ids, is
        // what stops a reading that always takes the last part one way from passing.
        RecRef.Open(Database::"Inventory Setup");
        FldRef := RecRef.Field(InvtSetup.FieldNo("Current Demand Forecast"));

        Assert.AreEqual(
            Database::"Production Forecast Name", FldRef.Relation(),
            'a TableRelation naming Microsoft.Manufacturing.Forecast."Production Forecast Name".Name ' +
            'must answer the TABLE id (99000851), not the field');
    end;

    [Test]
    procedure FieldRef_Relation_NamespaceQualifiedTargetWithWhere_ReturnsRelatedTableId()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        ReqLine: Record "Requisition Line";
    begin
        Initialize();

        // A namespace-qualified target narrowed by a where() clause:
        //   Requisition Line."Demand Type"
        //     = System.Reflection.AllObjWithCaption."Object ID" where("Object Type" = const(Table))
        // The where() narrows which ROWS are valid and does not change the answer, exactly as
        // FieldRef_Relation_RelationWithWhereFieldLink_ReturnsRelatedTableId establishes for the
        // unqualified case — so this pins that the two features compose rather than one
        // cancelling the other. The target is a virtual system table, which also keeps the claim
        // off Base Application's own object numbering.
        RecRef.Open(Database::"Requisition Line");
        FldRef := RecRef.Field(ReqLine.FieldNo("Demand Type"));

        Assert.AreEqual(
            Database::AllObjWithCaption, FldRef.Relation(),
            'a namespace-qualified target narrowed by where() must still answer the related ' +
            'table id (2000000058)');
    end;
}
