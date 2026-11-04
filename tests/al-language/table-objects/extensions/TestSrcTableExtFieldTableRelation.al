// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: tableextension 60406 "ALT Src Ext Relation" (extends Job), table 60028
//   "ALT Relation Parent", Base Application's Job (167); shared Assert (60021)
// BC versions: 27.0+
//
// CLAIM: a TableRelation declared by a tableextension WRITTEN IN THIS CORPUS is enforced by
// Validate, exactly as one contributed by a tableextension shipped inside a precompiled app is.
// Where the extension came from does not change what Validate does.
//
// WHY THIS IS NOT A DUPLICATE OF tableextension/TestTableExtFieldTableRelation.al. That file
// (corpus #207) makes the same claim about Customer 5900 "Service Zone Code" -- a field
// contributed by tableextension 6450 "Serv. Customer", which ships INSIDE the Base Application
// package. Its relation is therefore one this corpus never declares; it is read back out of a
// precompiled app's symbols. Counted across every tableextension this corpus declares in AL --
// 60024 "ALT Triggered Order Ext", 60025 "ALT Universal Validated Ext", 60205 "ALT Internal
// Table Ext", 60390 "TP CurrFieldNo Job Ext" -- exactly ZERO declare a TableRelation, so the
// source-declared half of the claim was pinned nowhere. The two files together cover both.
//
// SUBJECT: Job field 60406 "ALT Src Ext Rel Code" (Code[20], TableRelation = "ALT Relation
// Parent"."Code"), added by tableextension 60406. It carries no OnValidate trigger and no
// ValidateTableRelation property, so the relation check is the only thing in Validate that can
// raise on it.
//
// CONTROL: Job field 60407 "ALT Src Ext No Rel", added by the SAME extension, same type and
// same length, with no TableRelation at all. The two fields differ in exactly one thing: the
// presence of the relation.
//
// WHY THIS CANNOT PASS VACUOUSLY: the same code value is fed to the same field in the first
// two tests and only the existence of the related row changes, so an implementation that
// refused everything fails the accepting test and one that checked nothing fails the refusing
// test. The control field takes that same value and must NOT be refused, which rules out "this
// implementation refuses any write to an extension-added field". The last test pins that a
// direct assignment is not checked at all, so the refusal is Validate's relation check rather
// than the value or the field.
//
// The Job buffer is never inserted -- Init() plus Validate() is the whole scenario -- so no
// number series and no job master data is involved. Initialize() deletes only the related-table
// rows this codeunit creates (filtered on ALTSX*) and never touches Job.
codeunit 60407 "Test Src TableExt Relation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure SrcTableExt_Validate_DeclaredRelation_NoRelatedRow_Throws()
    // CLAIM: Validate on a field whose TableRelation this corpus's own tableextension declared
    // refuses a value that has no row in the related table.
    var
        Job: Record Job;
    begin
        Initialize();

        // [GIVEN] No "ALT Relation Parent" row carries this code (Initialize deleted it).
        Clear(Job);
        Job.Init();

        // [WHEN/THEN] Validating the extension-declared field with it is refused.
        asserterror Job.Validate("ALT Src Ext Rel Code", 'ALTSXREL1');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure SrcTableExt_Validate_DeclaredRelation_RelatedRowExists_AssignsTheValue()
    // CLAIM: the SAME value the test above refused is accepted once the related row exists, so
    // the refusal was the relation check and not a blanket rejection -- and the relation
    // resolved to the RIGHT related table, since a row in any other table would not rescue it.
    var
        Job: Record Job;
    begin
        Initialize();

        // [GIVEN] An "ALT Relation Parent" row with exactly the code the previous test was refused.
        InsertRelationParent('ALTSXREL1');

        // [WHEN] The extension-declared field is validated with it.
        Clear(Job);
        Job.Init();
        Job.Validate("ALT Src Ext Rel Code", 'ALTSXREL1');

        // [THEN] Validate succeeds and the field holds the value.
        Assert.AreEqual(
            'ALTSXREL1', Job."ALT Src Ext Rel Code",
            'Validate must accept a value that exists in the table the tableextension-declared ' +
            'TableRelation points at, and store it');
    end;

    [Test]
    procedure SrcTableExt_Validate_NoRelationField_SameValue_IsAccepted()
    // CLAIM: control -- a field the SAME tableextension adds WITHOUT a TableRelation takes the
    // very value the related field was refused. So the refusal above is the relation, not a
    // blanket refusal of writes to extension-added fields.
    var
        Job: Record Job;
    begin
        Initialize();

        // [GIVEN] No "ALT Relation Parent" row carries this code.
        Clear(Job);
        Job.Init();

        // [WHEN] The relation-less field of the same extension is validated with it.
        Job.Validate("ALT Src Ext No Rel", 'ALTSXREL1');

        // [THEN] Validate succeeds -- there is no relation to check.
        Assert.AreEqual(
            'ALTSXREL1', Job."ALT Src Ext No Rel",
            'A tableextension field with no TableRelation must accept any value of its type');
    end;

    [Test]
    procedure SrcTableExt_Assign_DeclaredRelation_NoRelatedRow_IsNotChecked()
    // CLAIM: a direct assignment bypasses the extension-declared relation entirely, so the
    // refusal in the first test is Validate's relation check -- not the value, not the field.
    var
        Job: Record Job;
    begin
        Initialize();

        // [GIVEN] No "ALT Relation Parent" row carries this code.
        Clear(Job);
        Job.Init();

        // [WHEN] The value is assigned directly rather than validated.
        Job."ALT Src Ext Rel Code" := 'ALTSXREL1';

        // [THEN] The assignment stands -- no relation check ran.
        Assert.AreEqual(
            'ALTSXREL1', Job."ALT Src Ext Rel Code",
            'A direct assignment must not consult the tableextension-declared TableRelation');
    end;

    local procedure Initialize()
    var
        RelParent: Record "ALT Relation Parent";
    begin
        // Only this codeunit's own rows: "ALT Relation Parent" is shared with
        // fieldref/TestFieldRefRelation.al, so a blanket DeleteAll would destroy rows this test
        // did not create. No Job row is ever written, so none has to be removed.
        RelParent.Reset();
        RelParent.SetFilter("Code", 'ALTSX*');
        RelParent.DeleteAll(false);
    end;

    local procedure InsertRelationParent(ParentCode: Code[20])
    var
        RelParent: Record "ALT Relation Parent";
    begin
        RelParent.Init();
        RelParent."Code" := ParentCode;
        RelParent.Insert(false);
    end;
}
