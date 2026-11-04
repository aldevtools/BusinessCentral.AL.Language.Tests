// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: SVM Row (60408), SVM Trace (60409), SVM Card (60410)
//
/// <summary>
/// Does a <c>TestPage</c> <c>SetValue</c> that writes back the value the field ALREADY held
/// still run the table's <c>OnModify</c>?
///
/// The question is not rhetorical and this suite does not presume the answer. What the page's
/// save path decides is whether to issue a <c>Modify</c> at all, and <c>OnModify</c> runs only
/// if it does. Two candidate rules produce different counts, and only a service tier can say
/// which one is real:
///
/// <list type="bullet">
/// <item>"a control was assigned" — the same-value write counts, so the tally reaches 2;</item>
/// <item>"a field value actually differs" — the same-value write does not, so it stays at 1.</item>
/// </list>
///
/// Both tests below assert a concrete integer, so neither passes against an implementation
/// that never fires <c>OnModify</c> (0) nor against one that fires it twice for one edit.
/// The differing-value test is the control: if it does not reach exactly 1, the fixture is
/// broken and the same-value result means nothing.
///
/// Why the tally lives in its own table: a counter FIELD on the row under test would be
/// written by <c>OnModify</c> itself, which would make that field a genuinely changed one
/// and destroy the very condition ("no field value differs") being measured.
/// </summary>
codeunit 60411 "SVM Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure SeedRow(No: Code[20]; NoteValue: Text[50])
    var
        Row: Record "SVM Row";
        Trace: Record "SVM Trace";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := No;
        Row.Note := NoteValue;
        Row.Insert();

        // Reset AFTER the seed insert, so nothing the setup did can be counted as an edit.
        Trace.Reset();
    end;

    [Test]
    procedure SetValue_WithADifferentValue_RunsOnModifyExactlyOnce()
    var
        Row: Record "SVM Row";
        Trace: Record "SVM Trace";
        Card: TestPage "SVM Card";
    begin
        // CONTROL. Establishes that this fixture can observe OnModify at all, and that one
        // genuine edit produces exactly one firing — not zero, and not two.
        SeedRow('SVM-1', 'original');

        Card.OpenEdit();
        Card.GoToKey('SVM-1');
        Card.Note.SetValue('changed');
        Card.Close();

        Assert.AreEqual(1, Trace.Count(),
            'A SetValue writing a DIFFERENT value must run OnModify exactly once.');

        Row.Get('SVM-1');
        Assert.AreEqual('changed', Row.Note,
            'The differing value must have been persisted.');
    end;

    [Test]
    procedure SetValue_WithTheSameValue_DoesNotRunOnModify()
    var
        Row: Record "SVM Row";
        Trace: Record "SVM Trace";
        Card: TestPage "SVM Card";
    begin
        // THE QUESTION. The control assigns the field, but assigns it the value it already
        // holds, so no field value on the row ends up different from the one it was read with.
        SeedRow('SVM-2', 'original');

        Card.OpenEdit();
        Card.GoToKey('SVM-2');
        Card.Note.SetValue('original');
        Card.Close();

        Assert.AreEqual(0, Trace.Count(),
            'A SetValue writing back the value the field already held must NOT run OnModify.');

        Row.Get('SVM-2');
        Assert.AreEqual('original', Row.Note,
            'The value must be unchanged whether or not a Modify was issued.');
    end;

    [Test]
    procedure SetValue_SameThenDifferent_RunsOnModifyOnceForTheDifferingWriteOnly()
    var
        Row: Record "SVM Row";
        Trace: Record "SVM Trace";
        Card: TestPage "SVM Card";
    begin
        // Both writes happen against ONE open page and one row, so this separates
        // "OnModify tracks each assignment" (which would give 2) from "OnModify tracks
        // whether the row's values ended up different" (which gives 1). It also rules out
        // a same-value write POISONING a later genuine one on the same row.
        SeedRow('SVM-3', 'original');

        Card.OpenEdit();
        Card.GoToKey('SVM-3');
        Card.Note.SetValue('original');
        Card.Note.SetValue('final');
        Card.Close();

        Assert.AreEqual(1, Trace.Count(),
            'One same-value write followed by one differing write must run OnModify exactly once.');

        Row.Get('SVM-3');
        Assert.AreEqual('final', Row.Note,
            'The last written value must be the persisted one.');
    end;
}
