// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT Page Update Temp New Row (60963), ALT Page Update Temp New Card (60974),
//   ALT Page Update Temp Trace (60871); shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: on a page whose source table is TEMPORARY, CurrPage.Update on a new row the page has
/// not saved yet does not raise OnAfterGetRecord for it, exactly as on a normal source table.
/// Once CurrPage.Update() has saved the row into the temporary buffer, the refresh does re-read
/// it and OnAfterGetRecord runs for the saved row.
///
///   1. OpenNew raises OnAfterGetCurrRecord for the new row, whose CurrPage.Update(false) asks
///      for a refresh, and no OnAfterGetRecord runs. The AGCR assertion is the control that
///      the request was made at all.
///   2. The same OpenNew, counted exactly: the trace is one OnAfterGetCurrRecord. The refresh
///      the CurrPage.Update(false) asked for raises neither trigger for the unsaved row, so
///      OnAfterGetCurrRecord is not raised a second time either (all nine cloud legs, corpus
///      PR #434's first run, answered `AGCR;`).
///   3. A SetValue whose OnValidate saves the row with CurrPage.Update() does raise
///      OnAfterGetRecord, for the saved name: the other side of the boundary.
/// </summary>
codeunit 60872 "ALT Page Update Temp New Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Trace: Codeunit "ALT Page Update Temp Trace";

    local procedure NewName(): Code[50]
    begin
        exit(CopyStr('PUTN' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, 50));
    end;

    [Test]
    procedure TempSource_OpenNew_CurrPageUpdateOnTheUnsavedRow_RaisesNoOnAfterGetRecord()
    var
        Card: TestPage "ALT Page Update Temp New Card";
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
    procedure TempSource_OpenNew_TraceIsOneOnAfterGetCurrRecord()
    var
        Card: TestPage "ALT Page Update Temp New Card";
    begin
        Trace.Reset();

        Card.OpenNew();

        Assert.AreEqual('AGCR;', Trace.Get(),
            'OpenNew raises OnAfterGetCurrRecord once, and the refresh its CurrPage.Update(false) asks for raises no trigger on the unsaved row; trace: ' + Trace.Get());
        Card.Close();
    end;

    [Test]
    procedure TempSource_SetValue_SavedByCurrPageUpdate_RaisesOnAfterGetRecordForTheSavedRow()
    var
        Card: TestPage "ALT Page Update Temp New Card";
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
}
