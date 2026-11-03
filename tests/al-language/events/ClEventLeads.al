// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: ClEventObjects.al in this folder (84760-84785), Probe Observer (69160).
// Probe: written against BC on the local 29.0 loop and the corpus CI legs; every literal asserted below is what BC produced.
// Facts: corpus issue 669 (odd AL behavior leads, part D), items 16 to 30 (writer CL). Every test binds its own manual subscriber codeunit.
//   - Table events of a temporary record: a subscriber with Rec by value sees IsTemporary = No and the rows of the real table; one with
//     Rec by value declared temporary sees IsTemporary = Yes and an empty table; one with var Rec sees the temporary rows.
//   - A subscriber that declares var R ... temporary for a var Record parameter compiles and runs for a real record (IsTemporary = No, its
//     assignment reaches the caller). A parameter named Finalize and one named ParamWithäöü bind and carry values.
//   - A codeunit passed by value through an event shares the instance (SetValue in the subscriber reaches the caller); Clear on the by-value
//     parameter detaches it. A SingleInstance codeunit is always the same instance.
//   - Assignments to Rec in OnAfterInsert/OnAfterModify (subscriber or table extension trigger) reach the caller's variable, not the stored row.
//     Rec.Modify() inside OnAfterModifyEvent raises the event again (RunTrigger No).
//   - GlobalTriggerManagement: OnAfterOnDatabaseInsert/Modify run only for a table registered in OnAfterGetDatabaseTableTriggerSetup, for
//     Insert/Modify with and without RunTrigger; OnAfterOnGlobalInsert/Modify do not run for writes from code, mask or not.
//   - CurrFieldNo is 0 for code-driven Validate, Insert and Modify; on a TestPage it is the field number in the field's own OnValidate (also a
//     table extension field) and in the validate event parameter, 0 in OnInsert/OnModify and their table extension triggers.
//   - Order on TestPage open: page trigger, page extension A, page extension B, then the page event subscriber, for each trigger.
//   - A page event subscriber (OnAfterGetCurrRecordEvent) with Rec, or a page publisher subscriber with Handled, without var: the
//     assignment does not reach the page (with var Rec the page shows it; nothing is stored). Action subscribers bind
//     the action name in any letter case. The Event Subscription rows of these subscribers are Active with no Error Information.
// BC versions: 27, 28, 29

codeunit 84790 "LT CL Event Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT CL Log";

    // Item 16: table events of a temporary record; subscribers take Rec by value, by value declared temporary, and var.
    [Test]
    procedure TableEvent_TemporaryRecord_SubscriberRecWithoutVar()
    var
        Real: Record "LT CL Row";
        Temp: Record "LT CL Row" temporary;
        Subs: Codeunit "LT CL Subs";
        O: Codeunit "Probe Observer";
    begin
        Real.DeleteAll();
        Real.Id := 100;
        Real.Insert();
        Real.Id := 101;
        Real.Insert();
        Real.Id := 102;
        Real.Insert();
        Temp.Id := 1;
        Temp.Insert();
        Log.SetMode('');
        Log.Take();
        BindSubscription(Subs);
        Temp.Id := 2;
        Temp.Insert(false);
        O.Observe('tempInsertFalse', Log.Take());
        Temp.Id := 3;
        Temp.Insert(true);
        O.Observe('tempInsertTrue', Log.Take());
        Temp.Get(2);
        Temp.Delete(true);
        O.Observe('tempDeleteTrue', Log.Take());
        Real.Id := 103;
        Real.Insert(true);
        O.Observe('realInsertTrue', Log.Take());
        UnbindSubscription(Subs);
        Real.DeleteAll();
        O.Expect('tempInsertFalse', 'ins.byValue temp=No count=3 id=2;ins.temporary temp=Yes count=0 id=2;ins.var temp=Yes count=2 id=2;');
        O.Expect('tempInsertTrue', 'ins.byValue temp=No count=3 id=3;ins.temporary temp=Yes count=0 id=3;ins.var temp=Yes count=3 id=3;');
        O.Expect('tempDeleteTrue', 'del.byValue temp=No count=3 id=2;del.var temp=Yes count=2 id=2;');
        O.Expect('realInsertTrue', 'ins.byValue temp=No count=4 id=103;ins.temporary temp=Yes count=0 id=103;ins.var temp=No count=4 id=103;');
        O.Verify();
    end;

    // Item 19: a subscriber parameter named Finalize (a C# method name; microsoft/AL issue 5077 saw ErrorParameterMismatch).
    [Test]
    procedure Subscriber_ParameterNamedFinalize()
    var
        Pub: Codeunit "LT CL Pub";
        Subs: Codeunit "LT CL Subs";
        O: Codeunit "Probe Observer";
    begin
        BindSubscription(Subs);
        O.Observe('true', Format(Pub.RaiseFinalize(true)));
        O.Observe('false', Format(Pub.RaiseFinalize(false)));
        UnbindSubscription(Subs);
        O.Expect('true', '11');
        O.Expect('false', '10');
        O.Verify();
    end;

    // Item 19: the publisher passes var R: Record (a real record, then a temporary one); the subscriber declares var R: Record ... temporary.
    [Test]
    procedure Subscriber_TemporaryRecordParameter()
    var
        Real: Record "LT CL Row";
        Temp: Record "LT CL Row" temporary;
        Pub: Codeunit "LT CL Pub";
        Subs: Codeunit "LT CL Subs";
        O: Codeunit "Probe Observer";
    begin
        Real.DeleteAll();
        Real.Id := 100;
        Real.Insert();
        Real.Id := 101;
        Real.Insert();
        Temp.Id := 1;
        Temp.Insert();
        Log.SetMode('');
        Log.Take();
        BindSubscription(Subs);
        ClearLastError();
        if TryTempParam(Pub, Real) then
            O.Observe('real', 'ok name=' + Real.Name)
        else
            O.ObserveError('real');
        O.Observe('realLog', Log.Take());
        if TryTempParam(Pub, Temp) then
            O.Observe('temp', 'ok name=' + Temp.Name)
        else
            O.ObserveError('temp');
        O.Observe('tempLog', Log.Take());
        UnbindSubscription(Subs);
        Real.DeleteAll();
        O.Expect('real', 'ok name=fromSub');
        O.Expect('realLog', 'tempParam temp=No count=2 id=101;');
        O.Expect('temp', 'ok name=fromSub');
        O.Expect('tempLog', 'tempParam temp=Yes count=1 id=1;');
        O.Verify();
    end;

    [TryFunction]
    local procedure TryTempParam(var Pub: Codeunit "LT CL Pub"; var R: Record "LT CL Row")
    begin
        Pub.RaiseTempParam(R);
    end;

    // Item 20: publisher and subscriber parameter named ParamWithäöü.
    [Test]
    procedure Subscriber_NonAsciiParameterName()
    var
        Pub: Codeunit "LT CL Pub";
        Subs: Codeunit "LT CL Subs";
        O: Codeunit "Probe Observer";
    begin
        Log.SetMode('');
        Log.Take();
        BindSubscription(Subs);
        O.Observe('result', Format(Pub.RaiseUmlaut(3)));
        O.Observe('log', Log.Take());
        UnbindSubscription(Subs);
        O.Expect('result', '8');
        O.Expect('log', 'umlaut in=3;');
        O.Verify();
    end;

    // Item 21: a codeunit (not SingleInstance) passed by value to a by-value subscriber; the subscriber calls SetValue(7).
    [Test]
    procedure CodeunitParameter_ByValue()
    var
        Pub: Codeunit "LT CL Pub";
        Subs: Codeunit "LT CL Subs";
        H: Codeunit "LT CL Holder";
        O: Codeunit "Probe Observer";
    begin
        Log.SetMode('');
        Log.Take();
        H.SetValue(1);
        BindSubscription(Subs);
        Pub.RaiseCuByValue(H);
        O.Observe('callerValue', Format(H.Get()));
        O.Observe('log', Log.Take());
        UnbindSubscription(Subs);
        O.Expect('callerValue', '7');
        O.Expect('log', 'cuByValue in=1;');
        O.Verify();
    end;

    // Item 21: the same; the subscriber first calls Clear on its parameter, then SetValue(7).
    [Test]
    procedure CodeunitParameter_ByValue_SubscriberClears()
    var
        Pub: Codeunit "LT CL Pub";
        Subs: Codeunit "LT CL Subs";
        H: Codeunit "LT CL Holder";
        O: Codeunit "Probe Observer";
    begin
        Log.SetMode('clear');
        Log.Take();
        H.SetValue(1);
        BindSubscription(Subs);
        Pub.RaiseCuByValue(H);
        O.Observe('callerValue', Format(H.Get()));
        O.Observe('log', Log.Take());
        UnbindSubscription(Subs);
        Log.SetMode('');
        O.Expect('callerValue', '1');
        O.Expect('log', 'cuByValue in=1;');
        O.Verify();
    end;

    // Item 21: var publisher and var subscriber; SetValue(8), and Clear then SetValue(8).
    [Test]
    procedure CodeunitParameter_ByVar()
    var
        Pub: Codeunit "LT CL Pub";
        Subs: Codeunit "LT CL Subs";
        H: Codeunit "LT CL Holder";
        O: Codeunit "Probe Observer";
    begin
        Log.SetMode('');
        Log.Take();
        H.SetValue(1);
        BindSubscription(Subs);
        Pub.RaiseCuByVar(H);
        O.Observe('callerValue', Format(H.Get()));
        Log.SetMode('clear');
        H.SetValue(2);
        Pub.RaiseCuByVar(H);
        O.Observe('callerValueAfterClear', Format(H.Get()));
        O.Observe('log', Log.Take());
        UnbindSubscription(Subs);
        Log.SetMode('');
        O.Expect('callerValue', '8');
        O.Expect('callerValueAfterClear', '8');
        O.Expect('log', 'cuByVar in=1;cuByVar in=2;');
        O.Verify();
    end;

    // Item 21: a SingleInstance codeunit passed by value; SetValue(9), and Clear then SetValue(9).
    [Test]
    procedure CodeunitParameter_SingleInstanceByValue()
    var
        Pub: Codeunit "LT CL Pub";
        Subs: Codeunit "LT CL Subs";
        H: Codeunit "LT CL Holder SI";
        O: Codeunit "Probe Observer";
    begin
        Log.SetMode('');
        Log.Take();
        H.SetValue(1);
        BindSubscription(Subs);
        Pub.RaiseSiByValue(H);
        O.Observe('callerValue', Format(H.Get()));
        Log.SetMode('clear');
        H.SetValue(2);
        Pub.RaiseSiByValue(H);
        O.Observe('callerValueAfterClear', Format(H.Get()));
        O.Observe('log', Log.Take());
        UnbindSubscription(Subs);
        Log.SetMode('');
        H.SetValue(0);
        O.Expect('callerValue', '9');
        O.Expect('callerValueAfterClear', '9');
        O.Expect('log', 'siByValue in=1;siByValue in=2;');
        O.Verify();
    end;

    // Item 22: an OnAfterInsertEvent / OnAfterModifyEvent subscriber assigns Name without Modify.
    [Test]
    procedure AfterInsertModify_SubscriberAssignsWithoutModify()
    var
        R: Record "LT CL AI Row";
        Stored: Record "LT CL AI Row";
        Subs: Codeunit "LT CL AI Subs";
        O: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        Log.SetMode('sub');
        BindSubscription(Subs);
        R.Id := 1;
        R.Name := 'caller';
        R.Insert(true);
        O.Observe('insert.caller', R.Name);
        Stored.Get(1);
        O.Observe('insert.stored', Stored.Name);
        R.Name := 'callerModify';
        R.Modify(true);
        O.Observe('modify.caller', R.Name);
        Stored.Get(1);
        O.Observe('modify.stored', Stored.Name);
        UnbindSubscription(Subs);
        Log.SetMode('');
        R.DeleteAll();
        O.Expect('insert.caller', 'subAfterInsert');
        O.Expect('insert.stored', 'caller');
        O.Expect('modify.caller', 'subAfterModify');
        O.Expect('modify.stored', 'callerModify');
        O.Verify();
    end;

    // Item 22: the table extension OnAfterInsert / OnAfterModify triggers assign Note without Modify.
    [Test]
    procedure AfterInsertModify_TableExtensionTriggerAssignsWithoutModify()
    var
        R: Record "LT CL AI Row";
        Stored: Record "LT CL AI Row";
        O: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        Log.SetMode('ext');
        R.Id := 1;
        R.Insert(true);
        O.Observe('insert.caller', R.Note);
        Stored.Get(1);
        O.Observe('insert.stored', Stored.Note);
        R.Note := 'callerModify';
        R.Modify(true);
        O.Observe('modify.caller', R.Note);
        Stored.Get(1);
        O.Observe('modify.stored', Stored.Note);
        R.Get(2 - 1);
        R.Note := 'x';
        R.Modify(false);
        Stored.Get(1);
        O.Observe('modifyFalse.caller', R.Note);
        O.Observe('modifyFalse.stored', Stored.Note);
        Log.SetMode('');
        R.DeleteAll();
        O.Expect('insert.caller', 'extAfterInsert');
        O.Expect('insert.stored', '');
        O.Expect('modify.caller', 'extAfterModify');
        O.Expect('modify.stored', 'callerModify');
        O.Expect('modifyFalse.caller', 'x');
        O.Expect('modifyFalse.stored', 'x');
        O.Verify();
    end;

    // Item 22: Rec.Modify() inside an OnAfterModifyEvent subscriber (the subscriber stops itself at depth 3).
    [Test]
    procedure AfterModify_SubscriberCallsModify_Recurses()
    var
        R: Record "LT CL AI Row";
        Stored: Record "LT CL AI Row";
        Subs: Codeunit "LT CL AI Subs";
        O: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        Log.Take();
        Log.SetMode('recurse');
        BindSubscription(Subs);
        R.Name := 'caller';
        R.Modify(true);
        O.Observe('log', Log.Take());
        O.Observe('caller', R.Name);
        Stored.Get(1);
        O.Observe('stored', Stored.Name);
        UnbindSubscription(Subs);
        Log.SetMode('');
        R.DeleteAll();
        O.Expect('log', 'afterModify depth=1 run=Yes;afterModify depth=2 run=No;afterModify depth=3 run=No;');
        O.Expect('caller', 'depth2');
        O.Expect('stored', 'depth2');
        O.Verify();
    end;

    // Item 23: GlobalTriggerManagement OnAfterOnDatabaseInsert/Modify and OnAfterOnGlobalInsert/Modify for a table registered through
    // OnAfterGetDatabaseTableTriggerSetup, one registered through OnAfterGetGlobalTableTriggerMask, and one not registered.
    [Test]
    procedure GlobalTriggerManagement_RegisteredTables()
    var
        Reg: Record "LT CL GT Reg";
        Msk: Record "LT CL GT Mask";
        Non: Record "LT CL GT None";
        GtSubs: Codeunit "LT CL GT Subs";
        O: Codeunit "Probe Observer";
    begin
        BindSubscription(GtSubs);
        Reg.DeleteAll();
        Msk.DeleteAll();
        Non.DeleteAll();
        Log.Take();
        Log.SetMode('gt');
        Reg.Id := 1;
        Reg.Insert(true);
        Reg.Id := 2;
        Reg.Insert(false);
        Reg.Name := 'm';
        Reg.Modify(true);
        Reg.Name := 'n';
        Reg.Modify(false);
        O.Observe('reg', Log.Take());
        Msk.Id := 1;
        Msk.Insert(true);
        Msk.Id := 2;
        Msk.Insert(false);
        Msk.Name := 'm';
        Msk.Modify(true);
        O.Observe('mask', Log.Take());
        Non.Id := 1;
        Non.Insert(true);
        Non.Name := 'm';
        Non.Modify(true);
        O.Observe('none', Log.Take());
        Log.SetMode('');
        Reg.DeleteAll();
        Msk.DeleteAll();
        Non.DeleteAll();
        UnbindSubscription(GtSubs);
        O.Expect('reg', 'dbInsert Reg 1;dbInsert Reg 2;dbModify Reg 2;dbModify Reg 2;');
        O.Expect('mask', '');
        O.Expect('none', '');
        O.Verify();
    end;

    // Items 29 and 30: CurrFieldNo when code validates a table extension field and a base field, then inserts and modifies.
    [Test]
    procedure CurrFieldNo_FromCode_TableAndExtension()
    var
        R: Record "LT CL CFN Row";
        Subs: Codeunit "LT CL CFN Subs";
        O: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        Log.SetMode('');
        Log.Take();
        BindSubscription(Subs);
        R.Id := 'C1';
        R.Validate(E, 4);
        R.Validate(B, 6);
        R.Validate(Qty, 9);
        O.Observe('validate', Log.Take());
        R.Insert(true);
        O.Observe('insert', Log.Take());
        R.Validate(E, 5);
        R.Modify(true);
        O.Observe('modify', Log.Take());
        UnbindSubscription(Subs);
        R.DeleteAll();
        O.Expect('validate', 'E.validate cur=0 xE=0;B.validate cur=0 xB=0;sub.beforeQty param=0;Qty.validate cur=0;sub.afterQty param=0;');
        O.Expect('insert', 'table.OnInsert cur=0;ext.OnInsert cur=0;ext.OnAfterInsert cur=0;sub.AfterInsert;');
        O.Expect('modify', 'E.validate cur=0 xE=4;table.OnModify cur=0;ext.OnModify cur=0;ext.OnAfterModify cur=0;');
        O.Verify();
    end;

    // Items 29 and 30: TestPage.OpenNew, SetValue Id, B and E, Close.
    [Test]
    procedure CurrFieldNo_TestPageNewRecord()
    var
        R: Record "LT CL CFN Row";
        Card: TestPage "LT CL CFN Card";
        Subs: Codeunit "LT CL CFN Subs";
        O: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        Log.SetMode('');
        Log.Take();
        BindSubscription(Subs);
        Card.OpenNew();
        Card.Id.SetValue('N1');
        O.Observe('afterId', Log.Take());
        Card.B.SetValue(2);
        O.Observe('afterB', Log.Take());
        Card.E.SetValue(3);
        O.Observe('afterE', Log.Take());
        Card.Qty.SetValue(4);
        O.Observe('afterQty', Log.Take());
        Card.Close();
        O.Observe('afterClose', Log.Take());
        UnbindSubscription(Subs);
        O.Observe('stored', Format(R.Get('N1')) + ' B=' + Format(R.B) + ' E=' + Format(R.E));
        R.DeleteAll();
        O.Expect('afterId', '');
        O.Expect('afterB', 'table.OnInsert cur=0;ext.OnInsert cur=0;ext.OnAfterInsert cur=0;sub.AfterInsert;B.validate cur=2 xB=0;');
        O.Expect('afterE', 'E.validate cur=84760 xE=0;');
        O.Expect('afterQty', 'sub.beforeQty param=3;Qty.validate cur=3;sub.afterQty param=3;');
        O.Expect('afterClose', 'table.OnModify cur=0;ext.OnModify cur=0;ext.OnAfterModify cur=0;');
        O.Expect('stored', 'Yes B=2 E=3');
        O.Verify();
    end;

    // Items 29 and 30: TestPage.OpenEdit on an existing record, SetValue B then E, Close.
    [Test]
    procedure CurrFieldNo_TestPageEditRecord()
    var
        R: Record "LT CL CFN Row";
        Card: TestPage "LT CL CFN Card";
        Subs: Codeunit "LT CL CFN Subs";
        O: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        R.Id := 'E1';
        R.B := 1;
        R.E := 1;
        R.Insert();
        Log.SetMode('');
        Log.Take();
        BindSubscription(Subs);
        Card.OpenEdit();
        Card.GoToKey('E1');
        Card.B.SetValue(7);
        O.Observe('afterB', Log.Take());
        Card.E.SetValue(8);
        O.Observe('afterE', Log.Take());
        Card.Qty.SetValue(5);
        O.Observe('afterQty', Log.Take());
        Card.Close();
        O.Observe('afterClose', Log.Take());
        UnbindSubscription(Subs);
        R.DeleteAll();
        O.Expect('afterB', 'B.validate cur=2 xB=1;');
        O.Expect('afterE', 'E.validate cur=84760 xE=1;');
        O.Expect('afterQty', 'sub.beforeQty param=3;Qty.validate cur=3;sub.afterQty param=3;');
        O.Expect('afterClose', 'table.OnModify cur=0;ext.OnModify cur=0;ext.OnAfterModify cur=0;');
        O.Verify();
    end;

    // Item 24: order of page triggers, two page extensions and page event subscribers when a TestPage opens a record.
    [Test]
    procedure PageTriggers_ExtensionsAndSubscribers_Order()
    var
        R: Record "LT CL Row";
        Card: TestPage "LT CL Ord Card";
        Subs: Codeunit "LT CL Ord Subs";
        O: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        Log.SetMode('');
        Log.Take();
        BindSubscription(Subs);
        Card.OpenView();
        O.Observe('open', Log.Take());
        Card.Close();
        UnbindSubscription(Subs);
        Log.Take();
        R.DeleteAll();
        O.Expect('open', 'page.OnOpenPage;extA.OnOpenPage;extB.OnOpenPage;sub.OnOpenPageEvent;page.OnAfterGetRecord;extA.OnAfterGetRecord;extB.OnAfterGetRecord;sub.OnAfterGetRecordEvent;page.OnAfterGetCurrRecord;extA.OnAfterGetCurrRecord;extB.OnAfterGetCurrRecord;sub.OnAfterGetCurrRecordEvent;');
        O.Verify();
    end;

    // Item 17: an OnAfterGetCurrRecordEvent subscriber (Rec is passed var) that takes Rec without var and assigns Name.
    [Test]
    procedure PageEvent_RecWithoutVar_Assignment()
    var
        R: Record "LT CL Row";
        Card: TestPage "LT CL PE Card";
        Subs: Codeunit "LT CL PE Subs";
        O: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'stored';
        R.Insert();
        Log.SetMode('');
        Log.Take();
        BindSubscription(Subs);
        Card.OpenView();
        O.Observe('shown', Card.Name.Value());
        O.Observe('log', Log.Take());
        Card.Close();
        UnbindSubscription(Subs);
        R.Get(1);
        O.Observe('stored', R.Name);
        R.DeleteAll();
        O.Expect('shown', 'stored');
        O.Expect('log', 'byValue in=stored;');
        O.Expect('stored', 'stored');
        O.Verify();
    end;

    // Item 17 contrast: the same with var Rec.
    [Test]
    procedure PageEvent_RecWithVar_Assignment()
    var
        R: Record "LT CL Row";
        Card: TestPage "LT CL PE Card";
        Subs: Codeunit "LT CL PE Subs Var";
        O: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'stored';
        R.Insert();
        Log.SetMode('');
        Log.Take();
        BindSubscription(Subs);
        Card.OpenView();
        O.Observe('shown', Card.Name.Value());
        O.Observe('log', Log.Take());
        Card.Close();
        UnbindSubscription(Subs);
        R.Get(1);
        O.Observe('stored', R.Name);
        R.DeleteAll();
        O.Expect('shown', 'fromVar');
        O.Expect('log', 'var in=stored;');
        O.Expect('stored', 'stored');
        O.Verify();
    end;

    // Item 17: a page publisher with var Handled; the subscriber takes Handled without var and assigns true.
    [Test]
    procedure PagePublisher_VarBooleanTakenWithoutVar()
    var
        P: Page "LT CL PE Card";
        Subs: Codeunit "LT CL PE Subs";
        SubsVar: Codeunit "LT CL PE Subs Var";
        O: Codeunit "Probe Observer";
    begin
        Log.SetMode('');
        Log.Take();
        BindSubscription(Subs);
        O.Observe('byValue', P.RaiseHandled());
        O.Observe('log', Log.Take());
        UnbindSubscription(Subs);
        BindSubscription(SubsVar);
        O.Observe('var', P.RaiseHandled());
        UnbindSubscription(SubsVar);
        O.Expect('byValue', 'No');
        O.Expect('log', 'handled in=No;');
        O.Expect('var', 'Yes');
        O.Verify();
    end;

    // Item 25: an action subscriber that names the action in lower case, and one with the exact name.
    [Test]
    procedure ActionSubscriber_NameInOtherCase()
    var
        R: Record "LT CL Row";
        Card: TestPage "LT CL Act Card";
        Subs: Codeunit "LT CL Act Subs";
        O: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        Log.SetMode('');
        Log.Take();
        BindSubscription(Subs);
        Card.OpenView();
        Card.PostShipment.Invoke();
        O.Observe('log', Log.Take());
        Card.Close();
        UnbindSubscription(Subs);
        R.DeleteAll();
        O.Expect('log', 'before(lower case name);OnAction;after(exact name);');
        O.Verify();
    end;

    // Items 19, 20 and 30: the Event Subscription rows of the subscriber codeunits 84776 and 84781 (Active and Error Information).
    [Test]
    procedure EventSubscriptionRows_ClSubscribers()
    var
        Sub: Record "Event Subscription";
        O: Codeunit "Probe Observer";
        Rows: Text;
    begin
        Sub.SetFilter("Subscriber Codeunit ID", '%1|%2', Codeunit::"LT CL Subs", Codeunit::"LT CL CFN Subs");
        if Sub.FindSet() then
            repeat
                Rows += Format(Sub."Subscriber Codeunit ID") + ' ' + Sub."Subscriber Function" + ' -> ' + Sub."Published Function" + ' active=' + Format(Sub.Active) + ' error=' + Sub."Error Information" + ';';
            until Sub.Next() = 0;
        O.Observe('rows', Rows);
        O.Expect('rows', '84776 CuByValue -> OnCuByValue active=Yes error=;84776 CuByVar -> OnCuByVar active=Yes error=;84776 DelByValue -> OnAfterDeleteEvent active=Yes error=;84776 DelVar -> OnAfterDeleteEvent active=Yes error=;84776 Fin -> OnFinalize active=Yes error=;84776 InsByValue -> OnAfterInsertEvent active=Yes error=;84776 InsTemporary -> OnAfterInsertEvent active=Yes error=;84776 InsVar -> OnAfterInsertEvent active=Yes error=;84776 SiByValue -> OnSiByValue active=Yes error=;84776 TempParam -> OnTempParam active=Yes error=;84776 Umlaut -> OnUmlaut active=Yes error=;84781 AfterInsert -> OnAfterInsertEvent active=Yes error=;84781 AfterValidateQty -> OnAfterValidateEvent - Qty active=Yes error=;84781 BeforeValidateQty -> OnBeforeValidateEvent - Qty active=Yes error=;');
        O.Verify();
    end;

    // Item 30, one-letter field: the Event Subscription rows of the never bound subscribers of field 'B' (codeunit 84786). Windows BC
    // 27.5/28.5 (Windows check 2026-10-20) and Linux 29.0 agree: the Published Function is '<event> - 66' (66 = character code of B),
    // Active = No, Error Information = ErrorFieldNotFound.
    [Test]
    procedure EventSubscriptionRows_OneLetterField()
    var
        Sub: Record "Event Subscription";
        O: Codeunit "Probe Observer";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT CL One Letter Subs");
        O.Observe('count', Format(Sub.Count()));
        if Sub.FindSet() then
            repeat
                O.Observe(Sub."Subscriber Function", Sub."Published Function" + ' | active=' + Format(Sub.Active) + ' | err=' + Sub."Error Information");
            until Sub.Next() = 0;
        O.Expect('count', '3');
        O.Expect('AfterValidateB', 'OnAfterValidateEvent - 66 | active=No | err=ErrorFieldNotFound');
        O.Expect('AfterValidateBNoCurrFieldNo', 'OnAfterValidateEvent - 66 | active=No | err=ErrorFieldNotFound');
        O.Expect('BeforeValidateB', 'OnBeforeValidateEvent - 66 | active=No | err=ErrorFieldNotFound');
        O.Verify();
    end;
}
