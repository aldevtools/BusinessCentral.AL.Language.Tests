// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-saverecord-method
// Scope: in-scope
// Fixtures used: Save Record Row (60250), Save Record Card (60251), Assert (60021)
//
// Pins that CurrPage.SaveRecord() — and CurrPage.Update(true) — called from a
// field control's page OnValidate MODIFIES the existing row the page is positioned
// on. The row exists before the page opens and the page reaches it via GoToRecord,
// so the save path has exactly one correct write: Modify. A path that misclassifies
// it as Insert fails loudly on the primary key ("already exists") — which is why
// every test asserts the row COUNT alongside the persisted value: persistence alone
// would also pass on an insert-then-shadow scheme that leaves two rows behind.
//
// The implicit-save control (no trigger, saved on Close) pins that the same edit
// through the same page persists fine without the explicit call — isolating the
// explicit mid-validate save as the only variable.

codeunit 60252 "Save Record OnValidate Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Save Record Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRow(No: Code[20]; var Row: Record "Save Record Row")
    begin
        Row.Init();
        Row."No." := No;
        Row.Description := 'original';
        Row.Insert();
        Row.Get(No);
    end;

    // Control: the identical edit with no page trigger persists via the implicit
    // save on Close. If this fails the page/edit plumbing is broken; if only the
    // explicit-save arms fail, the mid-validate save call is the trigger.
    [Test]
    procedure ImplicitSaveOnCloseModifiesTheExistingRow()
    var
        Row: Record "Save Record Row";
        Card: TestPage "Save Record Card";
    begin
        Initialize();
        SeedRow('A1', Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.DescPlain.SetValue('edited');
        Card.Close();

        Row.Get('A1');
        Assert.AreEqual('edited', Row.Description, 'the implicit save on Close must persist the edit');
        Assert.AreEqual(1, Row.Count(), 'exactly one row must exist after the implicit save');
    end;

    // Positive: CurrPage.SaveRecord() inside the field's OnValidate modifies the
    // existing row in place — the docs' pattern for persisting mid-validate.
    [Test]
    procedure SaveRecordInFieldOnValidateModifiesTheExistingRow()
    var
        Row: Record "Save Record Row";
        Card: TestPage "Save Record Card";
    begin
        Initialize();
        SeedRow('B1', Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.DescSave.SetValue('edited');
        Card.Close();

        Row.Get('B1');
        Assert.AreEqual('edited', Row.Description, 'CurrPage.SaveRecord in OnValidate must persist the edit');
        Assert.AreEqual(1, Row.Count(), 'SaveRecord must Modify the existing row, not Insert a duplicate');
    end;

    // Positive: CurrPage.Update(true) inside the field's OnValidate — the
    // save-then-refresh variant — modifies the existing row the same way.
    [Test]
    procedure UpdateTrueInFieldOnValidateModifiesTheExistingRow()
    var
        Row: Record "Save Record Row";
        Card: TestPage "Save Record Card";
    begin
        Initialize();
        SeedRow('C1', Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.DescUpdate.SetValue('edited');
        Card.Close();

        Row.Get('C1');
        Assert.AreEqual('edited', Row.Description, 'CurrPage.Update(true) in OnValidate must persist the edit');
        Assert.AreEqual(1, Row.Count(), 'Update(true) must Modify the existing row, not Insert a duplicate');
    end;

    // Positive: SaveRecord mid-validate is already durable BEFORE the page closes —
    // a fresh record variable sees the edit while the page is still open. This is
    // the reason AL code calls SaveRecord in OnValidate at all, so the suite pins
    // the observable point of the save, not just its end state.
    [Test]
    procedure SaveRecordInOnValidatePersistsBeforeThePageCloses()
    var
        Row: Record "Save Record Row";
        Fresh: Record "Save Record Row";
        Card: TestPage "Save Record Card";
    begin
        Initialize();
        SeedRow('D1', Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.DescSave.SetValue('edited');

        Fresh.Get('D1');
        Assert.AreEqual('edited', Fresh.Description,
            'the SaveRecord edit must be readable by a fresh record before the page closes');
        Assert.AreEqual(1, Fresh.Count(), 'exactly one row must exist while the page is still open');
        Card.Close();
    end;
}
