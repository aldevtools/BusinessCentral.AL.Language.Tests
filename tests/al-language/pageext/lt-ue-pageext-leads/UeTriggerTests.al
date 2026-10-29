// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects in UeTriggerObjects.al (table 90330, log 90331, page 90332, extensions 90333 and 90334), test codeunit 90335
// Probe: written against the Windows BC 29 container; the compile-only check of the trigger forms is pageext/POPageExtTriggers.al.
// BC versions: 29 (27 and 28 by CI)
// Facts (AL Runner issue 6149): when the triggers OnNewRecord, OnInsertRecord, OnModifyRecord and OnAfterGetRecord of a base list page and of two
//   page extensions of it run, in which order, and what an extension's false answer from OnInsertRecord / OnModifyRecord does to the rest and to the row.
// Observed: for each trigger the base page runs first, then the extensions in the order they were published (ext1, ext2). A false answer of one extension does not stop
//   the other triggers of that call. OnInsertRecord runs when the new row's first edit completes; the later edit of Amount then runs OnModifyRecord. A false answer from
//   an extension's OnInsertRecord leaves the row unstored (the following modify fails with DB:RecordNotFound); a false answer from OnModifyRecord leaves the old Amount.
// OnAfterAction in modify(action): already pinned by pages/lt-pageext-action-after/PageExtensionActionOnAfterAction.al.
codeunit 90335 "LT UE Trigger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT UE Log";

    local procedure Initialize()
    var
        Row: Record "LT UE Row";
    begin
        Row.DeleteAll();
        Log.Reset();
    end;

    local procedure SeedRow(Id: Integer; Amount: Integer)
    var
        Row: Record "LT UE Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Amount := Amount;
        Row.Insert();
    end;

    [Test]
    procedure NewRow_BaseThenExtensionsInOrder()
    var
        Row: Record "LT UE Row";
        List: TestPage "LT UE List";
    begin
        Initialize();
        List.OpenEdit();
        Observer.Observe('open log', Log.Take());
        List.New();
        Observer.Observe('new log', Log.Take());
        List.Id.SetValue(5);
        Observer.Observe('id log', Log.Take());
        List.Amount.SetValue(7);
        Observer.Observe('amount log', Log.Take());
        List.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', Format(Row.Get(5)));
        Observer.Observe('stored amount', Format(Row.Amount));
        Observer.Expect('open log', 'base.OnNewRecord;ext1.OnNewRecord;ext2.OnNewRecord;base.OnNewRecord;ext1.OnNewRecord;ext2.OnNewRecord;');
        Observer.Expect('new log', 'base.OnNewRecord;ext1.OnNewRecord;ext2.OnNewRecord;');
        Observer.Expect('id log', '');
        Observer.Expect('amount log', 'base.OnInsertRecord id=5;ext1.OnInsertRecord id=5;ext2.OnInsertRecord id=5;');
        Observer.Expect('close log', 'base.OnModifyRecord id=5 amount=7;ext1.OnModifyRecord id=5 amount=7;ext2.OnModifyRecord id=5 amount=7;');
        Observer.Expect('stored', 'Yes');
        Observer.Expect('stored amount', '7');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyRow_BaseThenExtensionsInOrder()
    var
        Row: Record "LT UE Row";
        List: TestPage "LT UE List";
    begin
        Initialize();
        SeedRow(3, 10);
        List.OpenEdit();
        Observer.Observe('open log', Log.Take());
        List.GoToKey(3);
        Observer.Observe('goto log', Log.Take());
        List.Amount.SetValue(11);
        Observer.Observe('amount log', Log.Take());
        List.Close();
        Observer.Observe('close log', Log.Take());
        Row.Get(3);
        Observer.Observe('stored amount', Format(Row.Amount));
        Observer.Expect('open log', 'base.OnAfterGetRecord id=3;ext1.OnAfterGetRecord id=3;ext2.OnAfterGetRecord id=3;');
        Observer.Expect('goto log', '');
        Observer.Expect('amount log', '');
        Observer.Expect('close log', 'base.OnModifyRecord id=3 amount=11;ext1.OnModifyRecord id=3 amount=11;ext2.OnModifyRecord id=3 amount=11;');
        Observer.Expect('stored amount', '11');
        Observer.Verify();
    end;

    [Test]
    procedure NewRow_FirstExtensionAnswersFalse()
    var
        Row: Record "LT UE Row";
    begin
        Initialize();
        Log.SetExt1InsertAnswer(false);
        Observer.Observe('try', Format(TryNewRow()));
        Observer.ObserveError('try');
        Observer.Observe('log', Log.Take());
        Observer.Observe('stored', Format(Row.Get(5)));
        Observer.Expect('try', 'No');
        Observer.Expect('try|text', 'The LT UE Row does not exist. Identification fields and values: Id=''5''');
        Observer.Expect('try|code', 'DB:RecordNotFound');
        Observer.Expect('log', 'base.OnNewRecord;ext1.OnNewRecord;ext2.OnNewRecord;base.OnNewRecord;ext1.OnNewRecord;ext2.OnNewRecord;base.OnNewRecord;ext1.OnNewRecord;ext2.OnNewRecord;base.OnInsertRecord id=5;ext1.OnInsertRecord id=5;ext2.OnInsertRecord id=5;base.OnModifyRecord id=5 amount=7;ext1.OnModifyRecord id=5 amount=7;ext2.OnModifyRecord id=5 amount=7;');
        Observer.Expect('stored', 'No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNewRow()
    var
        List: TestPage "LT UE List";
    begin
        List.OpenEdit();
        List.New();
        List.Id.SetValue(5);
        List.Amount.SetValue(7);
        List.Close();
    end;

    [Test]
    procedure ModifyRow_SecondExtensionAnswersFalse()
    var
        Row: Record "LT UE Row";
        List: TestPage "LT UE List";
    begin
        Initialize();
        SeedRow(3, 10);
        Log.SetExt2ModifyAnswer(false);
        List.OpenEdit();
        List.GoToKey(3);
        Log.Take();
        List.Amount.SetValue(11);
        Observer.Observe('amount log', Log.Take());
        List.Close();
        Observer.Observe('close log', Log.Take());
        Row.Get(3);
        Observer.Observe('stored amount', Format(Row.Amount));
        Observer.Expect('amount log', '');
        Observer.Expect('close log', 'base.OnModifyRecord id=3 amount=11;ext1.OnModifyRecord id=3 amount=11;ext2.OnModifyRecord id=3 amount=11;');
        Observer.Expect('stored amount', '10');
        Observer.Verify();
    end;
}
