// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT Page Find Record Row (60671), ALT Page Find Rec Trace (60672),
//   ALT Page Find Record List (60673), ALT Page Find Record Plain (60674); shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: a page's OnFindRecord/OnNextRecord triggers decide which rows the client shows. The
/// rows a TestPage then walks with First/Next/Last/Previous/GoToKey are the rows those
/// triggers served, not the rows the page's SourceTable holds.
///
/// Nothing in this suite measured that before. The two triggers are the documented way a page
/// presents a rowset the platform cannot produce by filtering Rec -- a temporary buffer, a
/// merged set, a computed order -- and an implementation that navigates the table directly
/// looks correct on every page that does not declare them, which is nearly every page.
///
/// WHAT IS PINNED HERE, and what each test would catch if it broke:
///
///   1. THE ROWSET IS THE TRIGGERS'. "ALT Page Find Record List" serves every SECOND row of the
///      table out of a page-global temporary buffer. The table gives nothing to select those
///      rows on -- every row carries the same Description -- so no filter over the table can
///      produce the walk asserted here, and an implementation that navigates the table cannot
///      pass by coincidence. First/Next, Last/Previous and GoToKey each ask that question from
///      a different direction.
///   2. GoToKey REFUSES A ROW THE TRIGGERS DO NOT SERVE. 'L0004' exists in the table and not in
///      the buffer. This is the negative arm, and it is the one an implementation reading the
///      table answers "true" to while every positive arm above still passes.
///   3. Next() STOPS AT THE END OF THE TRIGGER ROWSET, not at the end of the table. Four rows,
///      then false -- an implementation falling back to the table after the buffer runs out
///      would keep going.
///   4. THE CONTROL ARM. "ALT Page Find Record Plain" differs from the trigger page in exactly
///      one respect: it declares neither trigger. Its First() answers 'L0008', the table's own
///      descending first row. Without this arm, an implementation that got the descending sort
///      or the filters wrong would be indistinguishable from one that got the triggers wrong.
///   5. A MANUAL FILTER STILL NARROWS THE TRIGGER ROWSET. The page copies the host record onto
///      the buffer (TempBuf.Copy(Rec)), which is what carries the user's filters, the current
///      key and the sort direction across. So a filter the test sets through TestPage.Filter is
///      honoured by a rowset the page, not the platform, produced. The properties Copy has to
///      have for that to work are pinned separately over plain records, in
///      TestCopyOntoTemporaryRecord.
///   6. BOTH TRIGGERS ACTUALLY RAN. Rows alone cannot distinguish a client that asked the page
///      from one that read the same rows off the table; the SingleInstance trace can. Asserted
///      as a pair with the rows, never alone -- a call whose answer is discarded would satisfy
///      a count on its own.
///
/// Measured on BC 28.4 while writing this suite, and recorded because it is not obvious and
/// this suite deliberately does NOT assert it: the client does not call a trigger per
/// navigation step. It anchors with OnFindRecord -- Which is the equal-or-either-neighbour
/// form at page open and the equal-or-previous form at a CurrPage.Update refresh -- and then
/// walks with OnNextRecord(1) or OnNextRecord(-1), caching rows as it goes. So a First() or a
/// Next() over rows the client already holds raises nothing at all, which is why the trace
/// assertion below spans the refresh that BUILDS the rowset as well as the navigation that
/// reads it, and asserts only that each trigger was reached at least once.
/// The count and the shape of that prefetch are a client-side detail that a version is free to
/// change, which is why what is asserted here is the rows the walk produces and that the
/// triggers were reached -- not how many times.
/// </summary>
codeunit 60679 "ALT Page Find Record Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Trace: Codeunit "ALT Page Find Rec Trace";

    // Eight rows, every one carrying the SAME Description. The uniformity is the point: the
    // buffer the page serves holds four of these eight, and nothing in the table distinguishes
    // those four, so the walk asserted in this suite is not reachable by filtering.
    local procedure SeedUniform()
    var
        Row: Record "ALT Page Find Record Row";
        I: Integer;
    begin
        Row.Reset();
        Row.DeleteAll();
        for I := 1 to 8 do begin
            Row.Init();
            Row."No." := RowNo(I);
            Row.Description := 'Row';
            Row.Insert();
        end;
        Trace.Reset();
    end;

    // Eight rows whose Description alternates, for the arm that asks whether a manual filter
    // still narrows a rowset the page produced.
    local procedure SeedAlternating()
    var
        Row: Record "ALT Page Find Record Row";
        I: Integer;
    begin
        Row.Reset();
        Row.DeleteAll();
        for I := 1 to 8 do begin
            Row.Init();
            Row."No." := RowNo(I);
            if I mod 2 = 1 then
                Row.Description := 'Included'
            else
                Row.Description := 'Excluded';
            Row.Insert();
        end;
        Trace.Reset();
    end;

    local procedure RowNo(I: Integer): Code[20]
    begin
        exit('L' + PadStr('', 4 - StrLen(Format(I)), '0') + Format(I));
    end;

    [Test]
    procedure OnFindRecord_FirstAnswersTheFirstRowOfTheTriggerRowset()
    var
        List: TestPage "ALT Page Find Record List";
    begin
        // [SCENARIO] The page serves rows 1, 3, 5 and 7 out of a temporary buffer. Descending,
        // the first of those is 'L0007' -- the table's own first row is 'L0008'.
        SeedUniform();

        List.OpenView();
        List.FillTempEveryOther.Invoke();

        Assert.IsTrue(List.First(), 'First() over the trigger rowset');
        Assert.AreEqual('L0007', List."No.".Value, 'the first row the triggers serve');
        List.Close();
    end;

    [Test]
    procedure OnNextRecord_NextWalksTheTriggerRowsetAndStopsAtItsEnd()
    var
        List: TestPage "ALT Page Find Record List";
    begin
        // [SCENARIO] Four buffer rows, descending, and nothing after them -- not the four table
        // rows an implementation falling back to the table would find.
        SeedUniform();

        List.OpenView();
        List.FillTempEveryOther.Invoke();

        Assert.IsTrue(List.First(), 'First()');
        Assert.AreEqual('L0007', List."No.".Value, 'row 1 of the trigger rowset');
        Assert.IsTrue(List.Next(), 'Next() to row 2');
        Assert.AreEqual('L0005', List."No.".Value, 'row 2 of the trigger rowset');
        Assert.IsTrue(List.Next(), 'Next() to row 3');
        Assert.AreEqual('L0003', List."No.".Value, 'row 3 of the trigger rowset');
        Assert.IsTrue(List.Next(), 'Next() to row 4');
        Assert.AreEqual('L0001', List."No.".Value, 'row 4 of the trigger rowset');
        Assert.IsFalse(List.Next(), 'Next() past the last row the triggers serve');
        List.Close();
    end;

    [Test]
    procedure OnFindRecord_LastAndPreviousWalkTheTriggerRowset()
    var
        List: TestPage "ALT Page Find Record List";
    begin
        // [SCENARIO] The other end of the same rowset. Descending, its last row is 'L0001' --
        // the table's own last row is also 'L0001', so the assertion that carries this test is
        // the Previous() step to 'L0003', which the table would answer 'L0002'.
        SeedUniform();

        List.OpenView();
        List.FillTempEveryOther.Invoke();

        Assert.IsTrue(List.Last(), 'Last() over the trigger rowset');
        Assert.AreEqual('L0001', List."No.".Value, 'the last row the triggers serve');
        Assert.IsTrue(List.Previous(), 'Previous() from the last row');
        Assert.AreEqual('L0003', List."No.".Value, 'the row before the last one');
        List.Close();
    end;

    [Test]
    procedure OnFindRecord_GoToKeyRefusesARowTheTriggerRowsetDoesNotServe()
    var
        List: TestPage "ALT Page Find Record List";
    begin
        // [SCENARIO] 'L0003' is in the buffer and 'L0004' is in the table only. The negative arm
        // is the second one: an implementation navigating the table answers true to it.
        SeedUniform();

        List.OpenView();
        List.FillTempEveryOther.Invoke();

        Assert.IsTrue(List.GoToKey('L0003'), 'GoToKey on a row the triggers serve');
        Assert.AreEqual('L0003', List."No.".Value, 'the row GoToKey landed on');
        Assert.IsFalse(List.GoToKey('L0004'), 'GoToKey on a table row the triggers do not serve');
        List.Close();
    end;

    [Test]
    procedure PlainPage_WithoutTheTriggers_WalksTheTableDescending()
    var
        Plain: TestPage "ALT Page Find Record Plain";
    begin
        // [SCENARIO] The control arm: same table, same descending SourceTableView, no triggers.
        // 'L0008' and 'L0007' are what the table answers, so a suite passing here and on the
        // trigger arm cannot be explained by the sort or the filters.
        SeedUniform();

        Plain.OpenView();

        Assert.IsTrue(Plain.First(), 'First() over the table');
        Assert.AreEqual('L0008', Plain."No.".Value, 'the table''s own first row, descending');
        Assert.IsTrue(Plain.Next(), 'Next() over the table');
        Assert.AreEqual('L0007', Plain."No.".Value, 'the table''s own second row, descending');
        Plain.Close();
    end;

    [Test]
    procedure OnFindRecord_AManualFilterStillNarrowsTheTriggerRowset()
    var
        List: TestPage "ALT Page Find Record List";
    begin
        // [SCENARIO] The buffer holds every row, and the page copies the host record onto it, so
        // a filter set through TestPage.Filter narrows the rowset the triggers serve. The
        // action clears the "No." filter in filter group 0 as it activates the buffer; the
        // Description filter the test set survives that.
        SeedAlternating();

        List.OpenView();
        List.Filter.SetFilter(Description, 'Included');
        List.FillTempAll.Invoke();

        Assert.AreEqual('', List.Filter.GetFilter("No."), 'the "No." filter the action cleared');
        Assert.AreEqual('Included', List.Filter.GetFilter(Description), 'the filter the test set');

        Assert.IsTrue(List.First(), 'First() over the filtered trigger rowset');
        Assert.AreEqual('L0007', List."No.".Value, 'row 1');
        Assert.IsTrue(List.Next(), 'Next() to row 2');
        Assert.AreEqual('L0005', List."No.".Value, 'row 2');
        Assert.IsTrue(List.Next(), 'Next() to row 3');
        Assert.AreEqual('L0003', List."No.".Value, 'row 3');
        Assert.IsTrue(List.Next(), 'Next() to row 4');
        Assert.AreEqual('L0001', List."No.".Value, 'row 4');
        Assert.IsFalse(List.Next(), 'Next() past the last matching row');
        List.Close();
    end;

    [Test]
    procedure OnFindRecordAndOnNextRecord_AreBothReachedWhileTheClientBuildsTheRowset()
    var
        List: TestPage "ALT Page Find Record List";
    begin
        // [SCENARIO] The rows are the answer; this is the evidence they came from the page. The
        // counts are asserted as "at least one", never as an exact figure: how many rows the
        // client prefetches is a client-side detail (see the summary), while reaching the two
        // triggers at all is not.
        //
        // The window opens BEFORE the action, and closes after a walk that reaches both ends of
        // the rowset AND steps between them. Both halves of that are deliberate. A window that
        // began after the action would hold no OnNextRecord call on a client that had already
        // cached every row, and a window holding only Last()/First() would hold none either --
        // an end-to-end jump is a find, not a step. The Next() is what makes "OnNextRecord was
        // reached" a claim any implementation of the rowset must satisfy rather than an
        // accident of how far this client happened to prefetch.
        SeedUniform();

        List.OpenView();
        Trace.Reset();
        List.FillTempEveryOther.Invoke();

        Assert.IsTrue(List.Last(), 'Last()');
        Assert.AreEqual('L0001', List."No.".Value, 'the last row the triggers serve');
        Assert.IsTrue(List.First(), 'First()');
        Assert.AreEqual('L0007', List."No.".Value, 'the first row the triggers serve');
        Assert.IsTrue(List.Next(), 'Next() from the first row');
        Assert.AreEqual('L0005', List."No.".Value, 'the row after the first one');

        Assert.IsTrue(Trace.GetFindCalls() > 0, 'the page''s own OnFindRecord was reached');
        Assert.IsTrue(Trace.GetNextCalls() > 0, 'the page''s own OnNextRecord was reached');
        Assert.AreEqual('', Trace.GetUnexpectedSteps(),
          'every Steps value OnNextRecord was passed was 1 or -1');
        List.Close();
    end;
}
