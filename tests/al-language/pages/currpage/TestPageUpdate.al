// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT Page Update Row (60491), ALT Page Update Trace (60492),
//   ALT Page Update Facts (60493), ALT Page Update Card (60494),
//   ALT Page Update Card No Upd (60495); shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: CurrPage.Update() raises the page's OnAfterGetCurrRecord, and raises it AFTER the
/// trigger that called CurrPage.Update has returned -- not inline at the call.
///
/// Nothing in this suite measured that before. CurrPage.Update is normally described only by
/// its effect on the record ("save and re-read"), and the record half is invisible to a test:
/// the page holds the same row before and after, so re-reading it changes nothing anyone can
/// observe. What IS observable is the trigger, because OnAfterGetCurrRecord is where a page
/// derives state that is not in the record at all -- a page global, or a value pushed into a
/// FactBox part through a procedure on the part page. If that trigger does not run again, the
/// derived state keeps answering what the previous row-load computed, however current the
/// record itself is.
///
/// WHAT IS PINNED HERE, and what each test would catch if it broke:
///
///   1. CurrPage.Update IN A FIELD'S OnValidate REFRESHES THE FACTBOX. The FactBox column is
///      fed only from the host's OnAfterGetCurrRecord (see "ALT Page Update Facts" for why
///      nothing else can move it), so reading the new value there is a direct observation of
///      that trigger having run. Asserted as a PAIR against the pre-edit reading, so an
///      implementation answering the new value from the start cannot pass.
///   2. THE REFRESH LANDS AFTER THE CALLING TRIGGER RETURNS. The trace is reset immediately
///      before the edit and then asserted as an EXACT string, so both the order and the count
///      are pinned at once. An implementation refreshing inline would put HostAGCR between
///      ValidateBegin and ValidateEnd and fail; one refreshing twice would fail on the same
///      assertion.
///   3. A PAGE THAT CALLS NO CurrPage.Update GETS NO EXTRA OnAfterGetCurrRecord. This is the
///      control arm and it carries the suite's weight: "ALT Page Update Card No Upd" differs
///      from "ALT Page Update Card" in exactly one respect, the absence of the
///      CurrPage.Update call. Its trace after the same edit holds only the two Validate
///      markers, and its FactBox still reads the pre-edit value. Without this arm, an
///      implementation that raised OnAfterGetCurrRecord after every SetValue -- or after
///      every page trigger -- would pass tests 1 and 2 while being wrong.
///   4. AN ACTION'S OnAction REACHES THE SAME BEHAVIOR. The refresh follows the
///      CurrPage.Update call, not the kind of trigger that made it. Driven with the row
///      changed underneath the open page and no SetValue anywhere, so the FactBox can only
///      move if the trigger ran; the trace is again asserted exactly.
///
/// The FactBox readings are asserted with AreEqual on concrete amounts (20 before, 50 after)
/// rather than on "changed", so an implementation returning a default or an empty value fails
/// rather than passing by accident.
/// </summary>
codeunit 60496 "ALT Page Update Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Trace: Codeunit "ALT Page Update Trace";

    // Every row is cleared first, so the Card can only ever open on the row this test seeded.
    // Without that, a row an earlier test in this codeunit left behind sorts ahead of the new
    // one, the Card opens on it, and the "before" reading measures the wrong row -- which is
    // what the tier reported the first time this suite ran.
    local procedure SeedRow(var Row: Record "ALT Page Update Row"; RowNo: Code[20])
    begin
        Row.Reset();
        Row.DeleteAll();
        Row.Init();
        Row."No." := RowNo;
        Row.Amount := 20;
        Row.Insert();
    end;

    [Test]
    procedure CurrPageUpdateInOnValidate_RefreshesAFactBoxFedFromOnAfterGetCurrRecord()
    var
        Row: Record "ALT Page Update Row";
        Card: TestPage "ALT Page Update Card";
    begin
        // [SCENARIO] A field's OnValidate calls CurrPage.Update(true); the host's
        // OnAfterGetCurrRecord runs again and re-pushes the new amount into the FactBox.
        SeedRow(Row, 'UPD-1');

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Facts.First();
        Assert.AreEqual(20, Card.Facts.Derived.AsDecimal(), 'the FactBox before the edit');

        Card.Amount.SetValue(50);

        Card.Facts.First();
        Assert.AreEqual(50, Card.Facts.Derived.AsDecimal(), 'the FactBox after the edit');
        Card.Close();
    end;

    [Test]
    procedure CurrPageUpdateInOnValidate_RaisesOnAfterGetCurrRecordAfterTheTriggerReturns()
    var
        Row: Record "ALT Page Update Row";
        Card: TestPage "ALT Page Update Card";
    begin
        // [SCENARIO] The refresh is not inline: OnAfterGetCurrRecord lands after OnValidate
        // has returned, so the trace reads ValidateBegin, ValidateEnd, then HostAGCR.
        SeedRow(Row, 'UPD-2');

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Trace.Reset();

        Card.Amount.SetValue(50);

        Assert.AreEqual('ValidateBegin;ValidateEnd;HostAGCR;SetHeader;', Trace.Get(),
            'the trigger order after a SetValue whose OnValidate calls CurrPage.Update');
        Card.Close();
    end;

    [Test]
    procedure NoCurrPageUpdate_RaisesNoExtraOnAfterGetCurrRecord()
    var
        Row: Record "ALT Page Update Row";
        Card: TestPage "ALT Page Update Card No Upd";
    begin
        // [SCENARIO] The control arm. Same edit on a page whose OnValidate calls no
        // CurrPage.Update: no extra OnAfterGetCurrRecord, and the FactBox still shows the
        // pre-edit amount even though the record itself now holds 50.
        SeedRow(Row, 'UPD-3');

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Facts.First();
        Assert.AreEqual(20, Card.Facts.Derived.AsDecimal(), 'the FactBox before the edit');
        Trace.Reset();

        Card.Amount.SetValue(50);

        Assert.AreEqual('ValidateBegin;ValidateEnd;', Trace.Get(),
            'the trigger order with no CurrPage.Update anywhere');
        Card.Facts.First();
        Assert.AreEqual(20, Card.Facts.Derived.AsDecimal(),
            'the FactBox stays on the pre-edit amount without CurrPage.Update');
        Card.Close();
    end;

    [Test]
    procedure CurrPageUpdateInAnAction_RaisesOnAfterGetCurrRecordAfterTheActionReturns()
    var
        Row: Record "ALT Page Update Row";
        Card: TestPage "ALT Page Update Card";
    begin
        // [SCENARIO] The same behavior from an action. The row is changed underneath the open
        // page and the action calls nothing but CurrPage.Update, so the FactBox can only move
        // if the host's OnAfterGetCurrRecord ran -- and it runs after OnAction returned.
        SeedRow(Row, 'UPD-4');

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Facts.First();
        Assert.AreEqual(20, Card.Facts.Derived.AsDecimal(), 'the FactBox before the action');

        Row.Get('UPD-4');
        Row.Amount := 50;
        Row.Modify();
        Trace.Reset();

        Card.RefreshOnly.Invoke();

        Assert.AreEqual('ActionBegin;ActionEnd;HostAGCR;SetHeader;', Trace.Get(),
            'the trigger order after an action that calls CurrPage.Update');
        Card.Facts.First();
        Assert.AreEqual(50, Card.Facts.Derived.AsDecimal(), 'the FactBox after the action');
        Card.Close();
    end;
}
