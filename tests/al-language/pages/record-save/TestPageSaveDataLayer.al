// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT Page Save Row (60560), ALT Page Save Card (60561); shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: a row saved by a PAGE gets the same data-layer treatment as a row saved by
/// Record.Insert / Record.Modify. The AutoIncrement key is assigned, and SystemCreatedAt,
/// SystemCreatedBy, SystemModifiedAt and SystemModifiedBy are stamped -- by the platform, on
/// the page's own save path, with no AL anywhere assigning any of them.
///
/// The corpus already pins the two halves separately and neither covers this. `pageupdate`
/// (codeunit 60496) drives CurrPage.Update() and asserts TRIGGERS -- it never reads a stored
/// field. `record/TestBCSystemFieldContracts.al` (codeunit 60172) and
/// `record/TestAutoIncrementContracts.al` (codeunit 60201) read exactly these fields but only
/// ever through Record.Insert / Record.Modify -- neither file names TestPage at all. The
/// intersection, a system field or an AutoIncrement value on a row a PAGE saved, is what this
/// file measures.
///
/// WHY IT IS WORTH MEASURING: the page save is a different code path in the platform from the
/// AL record API, and everything read here is contributed by the data layer underneath both.
/// A platform that put the AutoIncrement assignment or the system-field stamp on the AL entry
/// point rather than in the data layer would answer correctly for Record.Insert and leave a
/// page-saved row with Entry No. = 0 and 0DT / null-guid system fields -- observably wrong, and
/// invisible to every test that writes through Record.Insert.
///
/// EACH TEST CARRIES ITS OWN CONTROL:
///
///   1. Every positive read is paired with a negative one -- a filter no row satisfies must
///      find nothing, so "the row exists" cannot be satisfied by a Get that answers true for
///      any key.
///   2. The record-API arm (RecordInsert_*) asserts the SAME values through Record.Insert. It
///      is what makes the claim "the data layer does this, whichever route reached it" rather
///      than "pages do something special".
///   3. The modify arm asserts that a page-driven Modify leaves SystemCreatedAt/SystemCreatedBy
///      exactly as the insert left them, to the MILLISECOND, and that a row the page never
///      opened keeps the SystemModifiedAt its own insert gave it. An implementation that re-ran
///      the INSERT stamp on the page's modify path fails the first; one that re-stamps every row
///      of the table on any save fails the second. What that arm deliberately does NOT assert,
///      and why no assertion there could be made to hold reliably, is written out at the test.
///
/// The AutoIncrement readings are asserted as "> 0" and as distinct between two rows, not as a
/// literal: which value the sequence is at is a property of the tier, not of the platform rule.
/// </summary>
codeunit 60562 "ALT Page Save Data Layer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // Every row is cleared first, so a row an earlier test left behind cannot be the row a
    // later one finds through its Description filter.
    local procedure Initialize()
    var
        Row: Record "ALT Page Save Row";
    begin
        Row.Reset();
        Row.DeleteAll();
    end;

    local procedure SavedRow(var Row: Record "ALT Page Save Row"; Description: Text[50]): Boolean
    begin
        Row.Reset();
        Row.SetRange(Description, Description);
        exit(Row.FindFirst());
    end;

    [Test]
    procedure PageSave_NewRow_GetsAnAutoIncrementEntryNo()
    // CLAIM: a new row saved by CurrPage.Update() from a field's OnValidate carries a positive
    // AutoIncrement key. Nothing in the page or the test assigns "Entry No.", so a positive
    // value can only have come from the platform's sequence.
    var
        Row: Record "ALT Page Save Row";
        Card: TestPage "ALT Page Save Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.DescriptionField.SetValue('PSAVE-AI-1');

        Assert.IsTrue(SavedRow(Row, 'PSAVE-AI-1'),
            'control arm: CurrPage.Update() must have inserted the row');
        Assert.IsTrue(Row."Entry No." > 0,
            'a row saved by a page must get a positive AutoIncrement Entry No. from the platform');

        Assert.IsFalse(SavedRow(Row, 'PSAVE-NO-SUCH-ROW'),
            'a Description no test wrote must match no row');

        Card.Close();
    end;

    [Test]
    procedure PageSave_TwoNewRows_GetDistinctEntryNos()
    // CLAIM: the sequence advances per page-saved row, so two rows saved through the page do
    // not collide on the key. A platform that left both at the default would pass the
    // "> 0" arm only by accident and fails here.
    var
        Row: Record "ALT Page Save Row";
        First: Integer;
        Second: Integer;
        Card: TestPage "ALT Page Save Card";
        SecondCard: TestPage "ALT Page Save Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.DescriptionField.SetValue('PSAVE-AI-A');
        Assert.IsTrue(SavedRow(Row, 'PSAVE-AI-A'), 'control arm: the first page save must have inserted a row');
        First := Row."Entry No.";
        Card.Close();

        SecondCard.OpenNew();
        SecondCard.DescriptionField.SetValue('PSAVE-AI-B');
        Assert.IsTrue(SavedRow(Row, 'PSAVE-AI-B'), 'control arm: the second page save must have inserted a row');
        Second := Row."Entry No.";
        SecondCard.Close();

        Assert.IsTrue(First > 0, 'the first page-saved row must have a positive Entry No.');
        Assert.IsTrue(Second > First,
            'the second page-saved row must get a later sequence value than the first');
    end;

    [Test]
    procedure PageSave_NewRow_StampsAllFourSystemFields()
    // CLAIM: a page-saved new row has SystemCreatedAt and SystemModifiedAt set to a real
    // instant and SystemCreatedBy / SystemModifiedBy set to a non-null user GUID -- the same
    // four values Record.Insert produces (asserted by the control arm below).
    var
        Row: Record "ALT Page Save Row";
        Card: TestPage "ALT Page Save Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.DescriptionField.SetValue('PSAVE-SYS-1');

        Assert.IsTrue(SavedRow(Row, 'PSAVE-SYS-1'),
            'control arm: CurrPage.Update() must have inserted the row');

        Assert.AreNotEqual(0DT, Row.SystemCreatedAt,
            'SystemCreatedAt must be stamped on a row saved by a page');
        Assert.AreNotEqual(0DT, Row.SystemModifiedAt,
            'SystemModifiedAt must be stamped on a row saved by a page');
        Assert.IsFalse(IsNullGuid(Row.SystemCreatedBy),
            'SystemCreatedBy must be a non-null user GUID on a row saved by a page');
        Assert.IsFalse(IsNullGuid(Row.SystemModifiedBy),
            'SystemModifiedBy must be a non-null user GUID on a row saved by a page');
        Assert.IsTrue(Row.SystemCreatedAt <= Row.SystemModifiedAt,
            'SystemCreatedAt must be <= SystemModifiedAt on a row saved by a page');

        Assert.IsFalse(SavedRow(Row, 'PSAVE-NO-SUCH-ROW'),
            'a Description no test wrote must match no row');

        Card.Close();
    end;

    [Test]
    procedure PageSave_ModifiedRow_MovesModifiedStampAndLeavesCreatedStamp()
    // CLAIM: a page-driven Modify -- CurrPage.Update() on a row that already exists -- leaves
    // SystemCreatedAt / SystemCreatedBy exactly as the insert left them, and touches only the
    // row the page opened.
    //
    // WHAT THIS ARM NO LONGER CLAIMS, AND WHY. It used to also assert
    //
    //     Assert.IsTrue(Row.SystemModifiedAt >= ModifiedAtBefore, ...)
    //
    // against a value captured before the page save. That assertion cannot fail. The row is
    // seeded by Record.Insert, so SystemModifiedAt is already a real instant before the page
    // touches it, and '>=' is satisfied by equality: a platform that stamped nothing at all on
    // the page's modify path passes it, and so does the companion AreNotEqual(0DT, ...). Both
    // were measured passing against a runner with the modify stamp disabled outright.
    //
    // Nothing was put in its place, and that is a finding rather than an omission. Every
    // replacement was measured and each failed for its own reason:
    //
    //   - A strict '>' on the same field. The gap between the seed insert and the page save
    //     depends on how fast the tier is, so an assertion on it holds on a slow tier and not
    //     on a fast one. (Re-measured later, the gap was about 180 ms on the tier used; an
    //     earlier note here claimed 0-1 ms and that figure did not reproduce, corpus issue
    //     393.) One formulation of this failed 3 times in 10 runs, which is a separate
    //     observation. An assertion that holds only when the tier is slow enough is not worth
    //     having at any gap size.
    //   - Widening that gap with filler writes between the two. Not pursued: it would still
    //     make the assertion depend on tier speed.
    //   - Two consecutive page saves, comparing the second against the first. Worse -- the
    //     second save is the faster one, and the two collided 9 times in 16.
    //   - SystemRowVersion instead, which is clock-free and advanced on 16 of 16 page saves.
    //     But it advances on the page save whatever the system-field stamp did: it was measured
    //     advancing on all 8 iterations against the same disabled-stamp platform above. It
    //     pins "the write reached the data layer", not "the field was re-stamped".
    //   - SystemModifiedBy, which the platform writes beside SystemModifiedAt. In a
    //     single-user test it holds the same user GUID before and after, so it cannot move.
    //
    // So the re-stamp of SystemModifiedAt is not observable from this codeunit's shape without
    // depending on how fast the tier is. It is left unasserted rather than asserted vacuously.
    //
    // WHAT IT DOES CLAIM IS NOW MEASURED TO THE MILLISECOND. Assert.AreEqual/AreNotEqual compare
    // non-numeric variants as Format(_, 0, 2), which for a DateTime renders to the MINUTE --
    // '09/20/26 01:10 PM'. Measured: a page save 171 ms after its seed insert compared EQUAL
    // through Assert while the raw AL '<>' on those two values answered true. So
    // 'SystemCreatedAt must NOT change' would have held even if SystemCreatedAt had moved by
    // most of a minute. The DateTime comparisons below go through Format(_, 0, 9), the
    // round-trip form ('2026-09-20T11:10:12.851Z'), which carries milliseconds; the claim is
    // unchanged and the resolution is three orders of magnitude finer.
    var
        Row: Record "ALT Page Save Row";
        UntouchedRow: Record "ALT Page Save Row";
        CreatedAt: DateTime;
        CreatedBy: Guid;
        UntouchedModifiedAtBefore: DateTime;
        EntryNo: Integer;
        UntouchedEntryNo: Integer;
        Card: TestPage "ALT Page Save Card";
    begin
        Initialize();

        Row.Init();
        Row."Entry No." := 0;
        Row.Description := 'PSAVE-MOD-BEFORE';
        Row.Insert();

        // Seeded beside the row under test and opened by no page: the negative control below. It
        // has to exist BEFORE the page save for its reading to mean anything.
        UntouchedRow.Init();
        UntouchedRow."Entry No." := 0;
        UntouchedRow.Description := 'PSAVE-MOD-UNTOUCHED';
        UntouchedRow.Insert();
        UntouchedEntryNo := UntouchedRow."Entry No.";
        Assert.IsTrue(UntouchedRow.Get(UntouchedEntryNo),
            'control arm: the untouched row must be readable back under its own key');
        UntouchedModifiedAtBefore := UntouchedRow.SystemModifiedAt;

        Assert.IsTrue(SavedRow(Row, 'PSAVE-MOD-BEFORE'), 'control arm: the seed row must exist');
        EntryNo := Row."Entry No.";
        CreatedAt := Row.SystemCreatedAt;
        CreatedBy := Row.SystemCreatedBy;

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.DescriptionField.SetValue('PSAVE-MOD-AFTER');
        Card.Close();

        Assert.IsTrue(Row.Get(EntryNo), 'control arm: the row must still exist under its own key');
        Assert.AreEqual('PSAVE-MOD-AFTER', Row.Description,
            'control arm: the page save must have written the new value');

        Assert.AreNotEqual(0DT, Row.SystemModifiedAt,
            'SystemModifiedAt must be a real instant after a page-driven Modify');
        Assert.AreEqual(Format(CreatedAt, 0, 9), Format(Row.SystemCreatedAt, 0, 9),
            'SystemCreatedAt must NOT change on a page-driven Modify -- it records creation');
        Assert.AreEqual(Format(CreatedBy), Format(Row.SystemCreatedBy),
            'SystemCreatedBy must NOT change on a page-driven Modify -- it records the creator');

        // The page saved ONE row, so a row of the same table that no page opened must come back
        // with the SystemModifiedAt its own insert gave it. This is what fails an implementation
        // that re-stamps the whole table on any save -- a shape none of the assertions above can
        // see, because each of them reads only the row the page wrote. Unlike the re-stamp
        // assertion this replaces, it does not depend on two writes landing in different
        // milliseconds: nothing should have written this row at all.
        Assert.IsTrue(UntouchedRow.Get(UntouchedEntryNo),
            'control arm: the untouched row must still exist under its own key');
        Assert.AreEqual(Format(UntouchedModifiedAtBefore, 0, 9), Format(UntouchedRow.SystemModifiedAt, 0, 9),
            'a row no page modified must keep the SystemModifiedAt its own insert gave it');
        Assert.AreEqual(Format(UntouchedRow.SystemCreatedAt, 0, 9), Format(UntouchedRow.SystemModifiedAt, 0, 9),
            'a row no page modified must keep the one instant its insert wrote into both fields');

        Assert.IsFalse(SavedRow(Row, 'PSAVE-MOD-BEFORE'),
            'the pre-edit Description must match no row after the page save');
    end;

    [Test]
    procedure RecordInsert_NewRow_GetsTheSameDataLayerTreatment()
    // CLAIM: the control arm. Record.Insert on the same table produces a positive AutoIncrement
    // key and the same four stamped system fields, so the page arms above are measuring one
    // data-layer rule reached by a second route -- not something pages do on their own.
    var
        Row: Record "ALT Page Save Row";
    begin
        Initialize();

        Row.Init();
        Row."Entry No." := 0;
        Row.Description := 'PSAVE-REC-1';
        Row.Insert();

        Assert.IsTrue(SavedRow(Row, 'PSAVE-REC-1'), 'control arm: Record.Insert must have inserted the row');
        Assert.IsTrue(Row."Entry No." > 0,
            'a row inserted by Record.Insert must get a positive AutoIncrement Entry No.');
        Assert.AreNotEqual(0DT, Row.SystemCreatedAt,
            'SystemCreatedAt must be stamped on a row inserted by Record.Insert');
        Assert.AreNotEqual(0DT, Row.SystemModifiedAt,
            'SystemModifiedAt must be stamped on a row inserted by Record.Insert');
        Assert.IsFalse(IsNullGuid(Row.SystemCreatedBy),
            'SystemCreatedBy must be a non-null user GUID on a row inserted by Record.Insert');
        Assert.IsFalse(IsNullGuid(Row.SystemModifiedBy),
            'SystemModifiedBy must be a non-null user GUID on a row inserted by Record.Insert');

        Assert.IsFalse(SavedRow(Row, 'PSAVE-NO-SUCH-ROW'),
            'a Description no test wrote must match no row');
    end;
}
