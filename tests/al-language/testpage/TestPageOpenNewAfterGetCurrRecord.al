// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onaftergetcurrrecord-page-trigger
// Scope: in-scope
// Fixtures used: ONG Row (60950), ONG Card (60950), TRT Row (60839), TRT Card (60841),
//                 TRT Echo (60840), shared Assert (60021)
//
// A page opened with OpenNew() — or moved to a new record with New() — runs its
// OnAfterGetCurrRecord for that new record, after OnNewRecord and before the test types
// anything. Base Application's Customer, Vendor and Item cards depend on it: their OnNewRecord
// only arms a flag, and OnAfterGetCurrRecord is what inserts the record from a template.
// "ONG Card" reproduces that shape without the Base Application.
//
// Written for StefanMaron/BusinessCentral.AL.Runner#2394 (Tests-SINGLESERVER's plan-based E2E
// tests, whose CreateCustomer helper opens the Customer Card with OpenNew()).
codeunit 60927 "ONG Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure OpenNew_RunsOnAfterGetCurrRecordAfterOnNewRecord()
    var
        Row: Record "ONG Row";
        Card: TestPage "ONG Card";
    begin
        Initialize();

        Card.OpenNew();

        // Nothing typed yet. OnNewRecord armed the flag and OnAfterGetCurrRecord acted on it,
        // so the template step ran exactly once and its row exists already.
        Assert.AreEqual(1, Hits('ONG-NEWREC'), 'OnNewRecord runs once on OpenNew');
        Assert.IsTrue(Hits('ONG-CURR') >= 1, 'OnAfterGetCurrRecord must run on OpenNew, before any field is set');
        Assert.AreEqual(1, Hits('ONG-TEMPL'), 'OnAfterGetCurrRecord must see the flag OnNewRecord set, so it ran after it');
        Assert.RecordCount(Row, 1);
        Row.FindFirst();
        Assert.IsTrue(Row."Made By Template", 'the only row is the one the template step inserted');
        Card.Close();
    end;

    [Test]
    procedure OpenNew_ThenTyping_EditsTheTemplateRowRatherThanInsertingAnother()
    var
        Row: Record "ONG Row";
        Card: TestPage "ONG Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Name.SetValue('typed');
        Card.OK().Invoke();

        // The Customer Card's own path: Rec.Copy + CurrPage.Update() hand the page the row the
        // template step inserted, and the field the test types lands on THAT row.
        Assert.RecordCount(Row, 1);
        Row.FindFirst();
        Assert.AreEqual('ONG-1', Row."No.", 'the template step numbered the row');
        Assert.IsTrue(Row."Made By Template", 'the row is the template row');
        Assert.AreEqual('typed', Row.Name, 'the typed value reached the template row');
        Assert.AreEqual(1, Hits('ONG-TEMPL'), 'typing does not run the template step again');
        Assert.AreEqual(1, Hits('ONG-ONINSERT'), 'the table''s OnInsert runs once, for the template insert only');
    end;

    [Test]
    procedure OpenEdit_OnAnExistingRow_DoesNotRunTheNewRecordPath()
    var
        Row: Record "ONG Row";
        Card: TestPage "ONG Card";
    begin
        Initialize();
        Row.Init();
        Row."No." := 'X1';
        Row.Insert();

        Card.OpenEdit();
        Card.GoToKey('X1');

        // The negative: OnAfterGetCurrRecord runs for an existing row too, but OnNewRecord
        // does not, so nothing arms the flag and no row is created.
        Assert.IsTrue(Hits('ONG-CURR') >= 1, 'OnAfterGetCurrRecord runs for an existing row');
        Assert.AreEqual(0, Hits('ONG-NEWREC'), 'OnNewRecord does not run for an existing row');
        Assert.AreEqual(0, Hits('ONG-TEMPL'), 'the template step does not run for an existing row');
        Card.Close();
        Assert.RecordCount(Row, 1);
    end;

    [Test]
    procedure New_OnAnOpenCard_RunsOnAfterGetCurrRecordForTheNewRecord()
    var
        Row: Record "ONG Row";
        Card: TestPage "ONG Card";
    begin
        Initialize();
        Row.Init();
        Row."No." := 'X1';
        Row.Insert();

        Card.OpenEdit();
        Card.GoToKey('X1');
        Card.New();

        Assert.AreEqual(1, Hits('ONG-NEWREC'), 'New() runs OnNewRecord once');
        Assert.AreEqual(1, Hits('ONG-TEMPL'), 'New() runs OnAfterGetCurrRecord for the new record, after OnNewRecord');
        Assert.RecordCount(Row, 2);
        Card.Close();
    end;

    [Test]
    procedure OpenNew_WhenABlankKeyedRowIsStored_StillInsertsTheNewRow()
    var
        Row: Record "TRT Row";
        Card: TestPage "TRT Card";
    begin
        // The negative side of the template case. "TRT Card" runs OnAfterGetCurrRecord but hands
        // the page no row. A stored row whose key equals the new row's starting (blank) key is
        // not the new row: typing a key and pressing OK inserts a second row and leaves the
        // blank-keyed one as it was.
        Initialize();
        Row.DeleteAll();
        Row.Init();
        Row."No." := '';
        Row.Note := 'blank';
        Row.Insert();

        Card.OpenNew();
        Card."No.".SetValue('ONG-N2');
        Card.Note.SetValue('typed');
        Card.OK().Invoke();

        Assert.RecordCount(Row, 2);
        Row.Get('');
        Assert.AreEqual('blank', Row.Note, 'the stored blank-keyed row is untouched');
        Row.Get('ONG-N2');
        Assert.AreEqual('typed', Row.Note, 'the new row carries the typed value');
        Row.DeleteAll();
    end;

    local procedure Initialize()
    var
        Row: Record "ONG Row";
        Echo: Record "TRT Echo";
    begin
        Row.DeleteAll();
        Echo.SetFilter("Key", 'ONG-*');
        Echo.DeleteAll();
        Commit();
    end;

    local procedure Hits(Name: Code[20]): Integer
    var
        Echo: Record "TRT Echo";
    begin
        if Echo.Get(Name) then
            exit(Echo.Hits);
        exit(0);
    end;
}
