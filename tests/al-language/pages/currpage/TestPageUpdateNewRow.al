// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT Page Update New Row (60998), ALT Page Update New Row Card (60992),
//   ALT Page Update New Row Trace (60866); shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: CurrPage.Update on a new row the page has not saved yet does not raise
/// OnAfterGetRecord for it. There is no stored row to re-read, so the refresh a CurrPage.Update
/// asks for cannot load one. Once CurrPage.Update() has SAVED the row, the refresh does
/// re-read it and OnAfterGetRecord runs for the saved row.
///
/// Base Application's "User Card" (page 9807) depends on the first half: its pageextension
/// 9807 calls CurrPage.Update(false) from OnAfterGetCurrRecord, and its OnAfterGetRecord runs
/// Rec.TestField("User Name"), which a blank new User fails. Microsoft's own codeunit 132903
/// "UserCardTest" opens that page with OpenNew in every test's Initialize.
///
///   1. OpenNew raises OnAfterGetCurrRecord for the new row, whose CurrPage.Update(false) asks
///      for a refresh, and no OnAfterGetRecord runs. The AGCR assertion is the control that
///      the request was made at all.
///   2. A SetValue whose OnValidate saves the row with CurrPage.Update() does raise
///      OnAfterGetRecord, for the saved name: the other side of the boundary.
///   3. That save wrote exactly one row, keyed by the Guid OnInsertRecord assigned.
///   4. OpenNew, counted exactly: the trace is one OnAfterGetCurrRecord, so the refresh raises no
///      OnAfterGetCurrRecord of its own on the unsaved row either. Codeunit 60872 measures the
///      same shape over a temporary source table.
/// </summary>
codeunit 60893 "ALT Page Update New Row Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Trace: Codeunit "ALT Page Update New Row Trace";

    local procedure NewName(): Code[50]
    begin
        exit(CopyStr('PUNR' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, 50));
    end;

    [Test]
    procedure OpenNew_CurrPageUpdateOnTheUnsavedRow_RaisesNoOnAfterGetRecord()
    var
        Card: TestPage "ALT Page Update New Row Card";
    begin
        Trace.Reset();

        Card.OpenNew();

        Assert.IsTrue(Trace.CountOf('AGCR') >= 1,
            'control: OnAfterGetCurrRecord must run for the new row; trace: ' + Trace.Get());
        Assert.AreEqual(0, StrPos(Trace.Get(), 'AGR:'),
            'OnAfterGetRecord must not run for the unsaved new row; trace: ' + Trace.Get());
        Card.Close();
    end;

    [Test]
    procedure OpenNew_TraceIsOneOnAfterGetCurrRecord()
    var
        Card: TestPage "ALT Page Update New Row Card";
    begin
        Trace.Reset();

        Card.OpenNew();

        Assert.AreEqual('AGCR;', Trace.Get(),
            'OpenNew raises OnAfterGetCurrRecord once, and the refresh its CurrPage.Update(false) asks for raises no trigger on the unsaved row; trace: ' + Trace.Get());
        Card.Close();
    end;

    [Test]
    procedure SetValue_SavedByCurrPageUpdate_RaisesOnAfterGetRecordForTheSavedRow()
    var
        Card: TestPage "ALT Page Update New Row Card";
        Name: Code[50];
    begin
        Name := NewName();
        Card.OpenNew();
        Trace.Reset();

        Card.NameField.SetValue(Name);

        Assert.AreNotEqual(0, StrPos(Trace.Get(), 'AGR:' + Name + ';'),
            'OnAfterGetRecord must run for the row CurrPage.Update() saved; trace: ' + Trace.Get());
        Card.Close();
    end;

    [Test]
    procedure SetValue_SavedByCurrPageUpdate_WritesOneRowUnderTheAssignedKey()
    var
        Row: Record "ALT Page Update New Row";
        Card: TestPage "ALT Page Update New Row Card";
        Name: Code[50];
    begin
        Name := NewName();
        Card.OpenNew();
        Card.NameField.SetValue(Name);
        Card.Close();

        Row.SetRange(Name, Name);
        Assert.AreEqual(1, Row.Count(), 'exactly one row saved under the name');
        Row.FindFirst();
        Assert.IsFalse(IsNullGuid(Row.Id), 'OnInsertRecord must have assigned the key');
    end;
}
