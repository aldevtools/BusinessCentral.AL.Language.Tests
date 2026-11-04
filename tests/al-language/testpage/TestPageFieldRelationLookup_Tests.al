// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: TRL Related (60563), TRL Related List (60564), TRL Host (60565),
//   TRL Card (60566), TRL Pageless (60570);
//   shared Assert (60021)
//
/// <summary>
/// Pins what a TestPage field's Lookup() does when the ONLY thing that can resolve the lookup
/// is the source table field's TableRelation -- neither the page control nor the table field
/// declares an OnLookup trigger of any kind.
///
/// AL puts a lookup in three places, and this suite is about the third. A page control can
/// declare trigger OnLookup(var Text: Text): Boolean; a table field can declare the unrelated
/// parameterless trigger OnLookup(); and a table field can declare neither and instead carry a
/// TableRelation, which is what the overwhelming majority of Base Application fields do. The
/// first two are already pinned by "TFL Tests" (60316). This suite pins the third.
///
/// The claims, each in its own test:
///   - Lookup() on a control whose field declares only a TableRelation opens the RELATED
///     table's LookupPageId page modally, so a declared [ModalPageHandler] for that page runs.
///   - The row the handler leaves selected is written back into the host field, which is how a
///     lookup differs from merely opening a page.
///   - A handler that CANCELS leaves the host field unchanged -- the write-back is conditional
///     on the outcome, not unconditional.
///   - A field with neither a trigger nor a TableRelation has nothing to resolve, and Lookup()
///     then COMPLETES WITHOUT ERROR, leaving the field exactly as it was.
///   - A field whose TableRelation RESOLVES, to a table declaring neither LookupPageId nor
///     DrillDownPageId, STILL OPENS A MODAL PAGE. That was measured, and it refuted the
///     expectation the arm was written with: run 35493508143 answered "Unhandled UI:
///     ModalPage" on 27.0, 27.3 and 27.5, which is raised from inside BC's own
///     NavTestExecution.ShowLookupForm and therefore only once BC has decided to show a form.
///     The arm after it asks WHICH page, since "a page opens" is not yet a rule anything can
///     implement.
///
/// The fourth is the one that keeps the first three honest. An implementation that opened a
/// page for every triggerless lookup -- the first page it found, or the host's own -- fails
/// it, because a page that opened with no handler declared would raise.
///
/// That fourth claim was measured rather than assumed, and the first version of this suite got
/// it wrong. It asserted that BC RAISES for that shape; all eight cloud legs answered
/// "An error was expected inside an ASSERTERROR statement" on run 35445556865, identically on
/// 27.0, 27.3, 27.5, 28.0, 28.1, 28.2, 28.3 and 28.4. So BC does nothing at all here -- no
/// error, no page -- and the assertion now says that. The other five claims below passed on
/// all eight legs of that same run.
/// </summary>
codeunit 60569 "TRL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        HandlerRan: Boolean;

    local procedure OpenOn(var Card: TestPage "TRL Card")
    var
        Host: Record "TRL Host";
        Related: Record "TRL Related";
        Pageless: Record "TRL Pageless";
    begin
        HandlerRan := false;

        Related.DeleteAll();
        Related.Init();
        Related."Code" := 'REL-A';
        Related.Descr := 'Alpha';
        Related.Insert();
        Related.Init();
        Related."Code" := 'REL-B';
        Related.Descr := 'Beta';
        Related.Insert();

        Pageless.DeleteAll();
        Pageless.Init();
        Pageless."Code" := 'PL-A';
        Pageless.Descr := 'Pageless Alpha';
        Pageless.Insert();
        Pageless.Init();
        Pageless."Code" := 'PL-B';
        Pageless.Descr := 'Pageless Beta';
        Pageless.Insert();

        Host.DeleteAll();
        Host.Init();
        Host."No." := 'H1';
        Host.Insert();

        Card.OpenEdit();
        Card.GoToRecord(Host);
    end;

    // CLAIM: the lookup opens the related table's LookupPageId page, modally, so the declared
    // [ModalPageHandler] for THAT page runs. Nothing in the AL under test names the page --
    // the only route to it is "Related Code"'s TableRelation to "TRL Related", whose
    // LookupPageId is "TRL Related List". A handler that never ran leaves HandlerRan false.
    [Test]
    [HandlerFunctions('RelatedListHandler')]
    procedure Lookup_TableRelationOnly_OpensTheRelatedTablesLookupPage()
    var
        Card: TestPage "TRL Card";
    begin
        OpenOn(Card);

        Card."Related Code".Lookup();

        Assert.IsTrue(HandlerRan,
            'a lookup on a field whose only lookup source is a TableRelation must open the related table''s LookupPageId page modally');
        Card.Close();
    end;

    // CLAIM: the row the handler leaves selected is written back into the host field. This is
    // what makes it a LOOKUP rather than just an open: the handler moves to REL-B and presses
    // OK, and the host control afterwards reads REL-B. Asserting the specific value rather
    // than "not blank" is what distinguishes a real write-back from a page that happened to
    // stamp something.
    [Test]
    [HandlerFunctions('RelatedListPicksBHandler')]
    procedure Lookup_TableRelationOnly_WritesTheSelectedRowBack()
    var
        Card: TestPage "TRL Card";
    begin
        OpenOn(Card);

        Card."Related Code".Lookup();

        Assert.AreEqual('REL-B', Card."Related Code".Value,
            'the row the lookup page''s handler left selected must be written back into the host field');
        Card.Close();
    end;

    // CLAIM: the write-back is conditional on the handler's outcome. A handler that CANCELS
    // moves to REL-B exactly as the previous test's does, and the host field must still be
    // blank afterwards -- so an implementation that assigns unconditionally passes the test
    // above and fails this one.
    [Test]
    [HandlerFunctions('RelatedListCancelsHandler')]
    procedure Lookup_TableRelationOnly_CancelLeavesTheFieldUnchanged()
    var
        Card: TestPage "TRL Card";
    begin
        OpenOn(Card);

        Card."Related Code".Lookup();

        Assert.AreEqual('', Card."Related Code".Value,
            'a cancelled lookup must leave the host field unchanged, whatever row the handler moved to');
        Card.Close();
    end;

    // CLAIM: a field with no trigger AND no TableRelation has nothing to resolve a lookup
    // from, and Lookup() then completes without error, having changed nothing. "Plain Code" is
    // "Related Code" minus exactly one property, so this separates "the relation was followed"
    // from "a page was opened for any triggerless lookup".
    //
    // No handler is declared here, deliberately, and that is what carries the "no page opened"
    // half: a modal page opening with no [ModalPageHandler] bound raises on real BC, so if this
    // shape DID open something the call would fail rather than reach the assertion below. The
    // assertion then carries the other half -- that the field is untouched.
    //
    // Measured, not assumed: this test first asserted that BC RAISES here, and all eight cloud
    // legs disagreed (run 35445556865). BC's answer is silence.
    [Test]
    procedure Lookup_NoTriggerAndNoTableRelation_DoesNothing()
    var
        Card: TestPage "TRL Card";
    begin
        OpenOn(Card);
        Card."Plain Code".SetValue('KEEP');

        // No asserterror: this must not raise. An implementation that opened a page here fails
        // on the unhandled-UI refusal before reaching the assertion.
        Card."Plain Code".Lookup();

        Assert.AreEqual('KEEP', Card."Plain Code".Value,
            'a lookup with neither an OnLookup trigger nor a TableRelation must leave the field exactly as it was');
        Card.Close();
    end;

    // CLAIM: a lookup whose TableRelation resolves to a table declaring NEITHER LookupPageId
    // NOR DrillDownPageId is neither silent nor a normal AL error -- BC decides to show a
    // modal form. The observable is the UI signal itself, raised with NO handler bound.
    //
    // MEASURED TWICE, and the second measurement is why this arm no longer binds a handler.
    //
    // 1. The first version asserted BC does nothing, the same shape as the "Plain Code" arm
    //    above. Run 35493508143 answered on all eight cloud legs:
    //
    //        FAIL  Lookup_RelationToTableWithNoLookupPage_DoesNothing - Unhandled UI: ModalPage
    //
    //    "Unhandled UI: ModalPage" comes from BC's own NavTestExecution.ShowLookupForm, which
    //    is reached only once BC has decided to show a form and found no handler for it. A
    //    shape that opens nothing never enters that method -- which is how the "Plain Code"
    //    arm passes on the very same leg. So "there is no page to open" is false.
    //
    // 2. The next version bound a [ModalPageHandler] to ask WHICH page. That cannot work, and
    //    BC's own code says why. Run 35494023689 failed both arms with a NullReferenceException
    //    inside ShowLookupForm rather than with the UI signal. FindHandler's page-id check sits
    //    INSIDE its `if (appObject != null)` guard:
    //
    //        if (appObject != null) { ... if (attr.ObjectId != appObject.ObjectId.ObjectNumber)
    //                                          { continue; } }
    //        return method;
    //
    //    so a null registered form SKIPS the check, returns any handler of the right type, and
    //    registeredForm.ObjectId then dereferences null. That is the only branch producing an
    //    NRE: a non-null form would either match or fall through to "Unhandled UI".
    //
    //    GetRegisteredForm(handle) therefore answers null -- BC decides to open a page and then
    //    does not materialise one. ShowLookupForm is byte-identical on bc270 and bc284
    //    (compare_symbols: bodyChanged false), consistent with every leg agreeing.
    //
    // WHAT THIS ARM DELIBERATELY DOES NOT CLAIM. Which page BC intended is NOT measurable from
    // the corpus: the discriminating id check is skipped exactly when the form is missing, so
    // no [ModalPageHandler] probe can ever name it. That is a property of BC's dispatcher, not
    // a gap in this test, and it is why asking the question again would produce the same NRE.
    // Runner issue #4403 tracks it.
    //
    // asserterror with the message pinned, not a bare one: a bare asserterror would also pass
    // if BC raised something else entirely, and the whole content of this arm is WHICH signal
    // BC produces.
    [Test]
    procedure Lookup_RelationToTableWithNoLookupPage_RaisesTheUnhandledUiSignal()
    var
        Card: TestPage "TRL Card";
    begin
        OpenOn(Card);
        // PL-A, not an arbitrary string: the field carries a TableRelation, so SetValue
        // validates against "TRL Pageless" and any value absent from it would raise here
        // rather than at the Lookup() this test is about.
        Card."Pageless Code".SetValue('PL-A');

        asserterror Card."Pageless Code".Lookup();

        Assert.ExpectedError('Unhandled UI: ModalPage');
        Card.Close();
    end;

    // CLAIM: the field is unchanged after that signal. The lookup did not write anything back
    // on its way to failing.
    //
    // This is the half of the old "which page" arm that IS measurable. It does not ask what BC
    // opened -- it pins that whatever BC did, it did not silently mutate the record, which is
    // the property a caller depends on and the one a runner has to reproduce.
    [Test]
    procedure Lookup_RelationToTableWithNoLookupPage_LeavesTheFieldUnchanged()
    var
        Card: TestPage "TRL Card";
    begin
        OpenOn(Card);
        Card."Pageless Code".SetValue('PL-A');

        asserterror Card."Pageless Code".Lookup();

        Assert.ExpectedError('Unhandled UI: ModalPage');
        Assert.AreEqual('PL-A', Card."Pageless Code".Value,
            'a lookup that raises Unhandled UI must leave the field exactly as it was');
        Card.Close();
    end;

    [ModalPageHandler]
    procedure RelatedListHandler(var Modal: TestPage "TRL Related List")
    begin
        HandlerRan := true;
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure RelatedListPicksBHandler(var Modal: TestPage "TRL Related List")
    begin
        HandlerRan := true;
        Modal.GoToKey('REL-B');
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure RelatedListCancelsHandler(var Modal: TestPage "TRL Related List")
    begin
        HandlerRan := true;
        Modal.GoToKey('REL-B');
        Modal.Cancel().Invoke();
    end;
}
