// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// Fixtures used: pages/lt-y45-save-before-action/Y45Tables.al (tables 92880 "LT Y45 Head", 92881 "LT Y45 Line"; log 92880, subscribers 92881,
//   RunObject codeunit 92882), Y45Pages.al (Card 92880, List 92881, ListPart 92882, Document 92883, Card with part 92884, RunObject target 92885); Probe Observer 69160.
// Probe: written against BC 27.5, 28.5 and 29.0 (corpus CI, Linux containers); every literal was measured there and is the same on all three.
//
// When BC saves a field value set through a TestPage that the page has not saved yet. Log entries: vX = OnValidate of field X;
// pM / pI / pN = page OnModifyRecord / OnInsertRecord / OnNewRecord; eBM / eAM / eBI = OnBeforeModifyEvent / OnAfterModifyEvent /
// OnBeforeInsertEvent subscribers; tM / tI = table OnModify / OnInsert; R / C = OnAfterGetRecord / OnAfterGetCurrRecord; act = action trigger;
// cu = RunObject codeunit; peek = RunObject page; the l-prefixed entries are the same for the part line; db = the stored row read in the trigger.
// - SetValue validates only: nothing is written.
// - The next step saves the row first, then runs: action, RunObject codeunit, RunObject page, Next, Previous, GoToRecord (another row or the same
//   row), GoToKey, OK, Close; on a Card, an editable List, a Document page and a Card with a ListPart. Order: pM, eBM (RunTrigger true), tM
//   (xRec = the stored row), eAM; only eAM sees the new value stored. The action trigger then sees the new value in Rec and in a fresh Get.
//   The same value set again still runs the whole modify chain.
// - Card action: one OnAfterGetRecord between the save and OnAction; RunObject codeunit and page: none.
// - A part line edit is saved (lpM, eBML, lM) before a host action, a part action, a part Next, OK and Close. With a host Next the host moves
//   first and the line is saved after it. A host edit is saved before a part action.
// - New record (OpenNew, List New): SetValue of the key stores nothing; the next SetValue inserts first (pI, eBI, tI), then validates; the
//   action then modifies first. A new card with only Name set inserts a row with a blank key. A new part line is inserted (lpI, eBIL, lI)
//   before the host or part action; on a new document its Line No. is 20000.
// - OnModify error during the save: the chain stops after tM, no error reaches the test (GetLastErrorText holds the error, the page counts
//   one validation error), a host action does not run, Next returns false; a PART action on a Document page still runs. The next SetValue
//   raises 'This field cannot be validated since the key fields are not valid.' (with the Refresh suffix on a Card and a Document page);
//   after that an action and Close run nothing and raise nothing.
// - OnValidate error: SetValue raises TestValidation at once; afterwards the control shows the stored value, and an action or Next runs nothing.
codeunit 92890 "LT Y45 Save Before Action"
{
    Subtype = Test;

    var
        Log: Codeunit "LT Y45 Log";

    local procedure Init(DoCommit: Boolean)
    var
        Head: Record "LT Y45 Head";
        Line: Record "LT Y45 Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."Code" := 'H1';
        Head.Name := 'old';
        Head.Qty := 1;
        Head.Insert();
        Head."Code" := 'H2';
        Head.Name := 'two';
        Head.Qty := 2;
        Head.Insert();
        AddLine('H1', 10000, 'a');
        AddLine('H1', 20000, 'b');
        AddLine('H2', 10000, 'c');
        if DoCommit then
            Commit();
        Log.Take();
    end;

    local procedure AddLine(DocCode: Code[20]; LineNo: Integer; Desc: Text[50])
    var
        Line: Record "LT Y45 Line";
    begin
        Line.Doc := DocCode;
        Line."Line No." := LineNo;
        Line.Desc := Desc;
        Line.Insert();
    end;

    [Test]
    procedure Card_SetName_Action()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H1;act H1 rec=new/1 db=new/1 l1=a;R H1;R H1;C H1');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Card_SetName_RunObjectCodeunit()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.RunCu.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;cu H1 rec=new/1 db=new/1 l1=a;R H1;C H1');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Card_SetName_RunObjectPage()
    var
        TP: TestPage "LT Y45 Head Card";
        Peek: TestPage "LT Y45 Peek";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Peek.Trap();
        TP.RunPg.Invoke();
        Observer.Observe('peek name', Peek.Name.Value);
        Observer.Observe('step', Log.Take());
        Peek.Close();
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('peek name', 'new');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;peek open f=H1 db=new/1;peek C new');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Card_SetName_Next()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('next', 'Yes');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H2;C H2');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'two');
        Observer.Expect('close', 'pQC OK db=two/2;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Card_SetName_Previous()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Last();
        Observer.Observe('last', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H2') + ' l1=' + Log.LineDb('H2', 10000));
        Observer.Observe('previous', Format(TP.Previous()));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H2') + ' l1=' + Log.LineDb('H2', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H2') + ' l1=' + Log.LineDb('H2', 10000));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('last', 'R H2;C H2');
        Observer.Expect('set', 'vName new/two db=two/2');
        Observer.Expect('db after set', 'two/2 l1=c');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('step', 'pM new/two db=two/2;eBM new t=Yes db=two/2;tM new/two db=two/2;eAM db=new/2;R H1;C H1');
        Observer.Expect('db after step', 'new/2 l1=c');
        Observer.Expect('page name', 'old');
        Observer.Expect('close', 'pQC OK db=old/1;pClose');
        Observer.Expect('db end', 'new/2 l1=c');
        Observer.Verify();
    end;

    [Test]
    procedure Card_SetName_GoToRecordOther()
    var
        TP: TestPage "LT Y45 Head Card";
        Head: Record "LT Y45 Head";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Head.Get('H2');
        Observer.Observe('goto', Format(TP.GoToRecord(Head)));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H1;C H1;R H2;C H2');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'two');
        Observer.Expect('close', 'pQC OK db=two/2;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Card_SetName_GoToRecordSame()
    var
        TP: TestPage "LT Y45 Head Card";
        Head: Record "LT Y45 Head";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Head.Get('H1');
        Observer.Observe('goto', Format(TP.GoToRecord(Head)));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H1;C H1');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Card_SetName_GoToKeyOther()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('gotokey', Format(TP.GoToKey('H2')));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('gotokey', 'Yes');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H1;C H1;R H2;C H2');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'two');
        Observer.Expect('close', 'pQC OK db=two/2;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Card_SetName_OK()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.OK().Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;pQC OK db=new/1;pClose');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Card_SetName_Close()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.Close();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;pQC OK db=new/1;pClose');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Card_SetSameName_Action()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('old');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName old/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM old/old db=old/1;eBM old t=Yes db=old/1;tM old/old db=old/1;eAM db=old/1;R H1;act H1 rec=old/1 db=old/1 l1=a;R H1;R H1;C H1');
        Observer.Expect('db after step', 'old/1 l1=a');
        Observer.Expect('page name', 'old');
        Observer.Expect('close', 'pQC OK db=old/1;pClose');
        Observer.Expect('db end', 'old/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure List_SetName_Action()
    var
        TP: TestPage "LT Y45 Head List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H1;act H1 rec=new/1 db=new/1 l1=a;R H1;R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure List_SetName_RunObjectCodeunit()
    var
        TP: TestPage "LT Y45 Head List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.RunCu.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;cu H1 rec=new/1 db=new/1 l1=a;R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure List_SetName_RunObjectPage()
    var
        TP: TestPage "LT Y45 Head List";
        Peek: TestPage "LT Y45 Peek";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Peek.Trap();
        TP.RunPg.Invoke();
        Observer.Observe('peek name', Peek.Name.Value);
        Observer.Observe('step', Log.Take());
        Peek.Close();
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('peek name', 'new');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;peek open f=H1 db=new/1;peek C new');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure List_SetName_Next()
    var
        TP: TestPage "LT Y45 Head List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('next', 'Yes');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H2;R H2;C H2');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'two');
        Observer.Expect('close', 'pQC OK db=two/2;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure List_SetName_Previous()
    var
        TP: TestPage "LT Y45 Head List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Last();
        Observer.Observe('last', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H2') + ' l1=' + Log.LineDb('H2', 10000));
        Observer.Observe('previous', Format(TP.Previous()));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H2') + ' l1=' + Log.LineDb('H2', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H2') + ' l1=' + Log.LineDb('H2', 10000));
        Observer.Expect('open', 'R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('last', 'pN;C ;R H2;R H2;C H2');
        Observer.Expect('set', 'vName new/two db=two/2');
        Observer.Expect('db after set', 'two/2 l1=c');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('step', 'pM new/two db=two/2;eBM new t=Yes db=two/2;tM new/two db=two/2;eAM db=new/2;R H1;R H1;C H1');
        Observer.Expect('db after step', 'new/2 l1=c');
        Observer.Expect('page name', 'old');
        Observer.Expect('close', 'pQC OK db=old/1;pClose');
        Observer.Expect('db end', 'new/2 l1=c');
        Observer.Verify();
    end;

    [Test]
    procedure List_SetName_GoToRecordOther()
    var
        TP: TestPage "LT Y45 Head List";
        Head: Record "LT Y45 Head";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Head.Get('H2');
        Observer.Observe('goto', Format(TP.GoToRecord(Head)));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H2;R H2;C H2');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'two');
        Observer.Expect('close', 'pQC OK db=two/2;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure List_SetName_OK()
    var
        TP: TestPage "LT Y45 Head List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.OK().Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;pQC OK db=new/1;pClose');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure List_SetName_Close()
    var
        TP: TestPage "LT Y45 Head List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.Close();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;pQC OK db=new/1;pClose');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetName_Action()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H1;act H1 rec=new/1 db=new/1 l1=a;R H1;R H1;C H1;lC 10000');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetName_RunObjectCodeunit()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.RunCu.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;cu H1 rec=new/1 db=new/1 l1=a;R H1;C H1;lC 10000');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetName_LineAction()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.Lines.LineAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;lact 10000 rec=a db=a head=new/1;lC 10000');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetName_Next()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('next', 'Yes');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H2;C H2;lC 10000');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'two');
        Observer.Expect('close', 'pQC OK db=two/2;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetName_GoToRecordOther()
    var
        TP: TestPage "LT Y45 Doc";
        Head: Record "LT Y45 Head";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Head.Get('H2');
        Observer.Observe('goto', Format(TP.GoToRecord(Head)));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H1;C H1;R H2;C H2;lC 10000');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'two');
        Observer.Expect('close', 'pQC OK db=two/2;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetName_OK()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.OK().Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;pQC OK db=new/1;pClose');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetLine_Action()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vDesc new/a');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'lpM 10000 new/a db=a;eBML new;lM 10000 new/a db=a;R H1;act H1 rec=old/1 db=old/1 l1=new;R H1;R H1;C H1;lC 10000');
        Observer.Expect('db after step', 'old/1 l1=new');
        Observer.Expect('page name', 'old');
        Observer.Expect('close', 'pQC OK db=old/1;pClose');
        Observer.Expect('db end', 'old/1 l1=new');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetLine_LineAction()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.Lines.LineAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vDesc new/a');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'lpM 10000 new/a db=a;eBML new;lM 10000 new/a db=a;lact 10000 rec=new db=new head=old/1;lC 10000');
        Observer.Expect('db after step', 'old/1 l1=new');
        Observer.Expect('page name', 'old');
        Observer.Expect('close', 'pQC OK db=old/1;pClose');
        Observer.Expect('db end', 'old/1 l1=new');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetLine_LineNext()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('line next', Format(TP.Lines.Next()));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vDesc new/a');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('line next', 'Yes');
        Observer.Expect('step', 'lpM 10000 new/a db=a;eBML new;lM 10000 new/a db=a;lC 20000');
        Observer.Expect('db after step', 'old/1 l1=new');
        Observer.Expect('page name', 'old');
        Observer.Expect('close', 'pQC OK db=old/1;pClose');
        Observer.Expect('db end', 'old/1 l1=new');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetLine_Next()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vDesc new/a');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('next', 'Yes');
        Observer.Expect('step', 'R H2;C H2;lpM 10000 new/a db=a;eBML new;lM 10000 new/a db=a;lC 10000');
        Observer.Expect('db after step', 'old/1 l1=new');
        Observer.Expect('page name', 'two');
        Observer.Expect('close', 'pQC OK db=two/2;pClose');
        Observer.Expect('db end', 'old/1 l1=new');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetLine_OK()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.OK().Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vDesc new/a');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'lpM 10000 new/a db=a;eBML new;lM 10000 new/a db=a;pQC OK db=old/1;pClose');
        Observer.Expect('db after step', 'old/1 l1=new');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_SetLine_Close()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.Close();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vDesc new/a');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'lpM 10000 new/a db=a;eBML new;lM 10000 new/a db=a;pQC OK db=old/1;pClose');
        Observer.Expect('db after step', 'old/1 l1=new');
        Observer.Verify();
    end;

    [Test]
    procedure CardPart_SetName_Action()
    var
        TP: TestPage "LT Y45 Card Part";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;R H1;act H1 rec=new/1 db=new/1 l1=a;R H1;R H1;C H1;lC 10000');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure CardPart_SetName_LineAction()
    var
        TP: TestPage "LT Y45 Card Part";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.Lines.LineAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vName new/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'pM new/old db=old/1;eBM new t=Yes db=old/1;tM new/old db=old/1;eAM db=new/1;lact 10000 rec=a db=a head=new/1;lC 10000');
        Observer.Expect('db after step', 'new/1 l1=a');
        Observer.Expect('page name', 'new');
        Observer.Expect('close', 'pQC OK db=new/1;pClose');
        Observer.Expect('db end', 'new/1 l1=a');
        Observer.Verify();
    end;

    [Test]
    procedure CardPart_SetLine_Action()
    var
        TP: TestPage "LT Y45 Card Part";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vDesc new/a');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'lpM 10000 new/a db=a;eBML new;lM 10000 new/a db=a;R H1;act H1 rec=old/1 db=old/1 l1=new;R H1;R H1;C H1;lC 10000');
        Observer.Expect('db after step', 'old/1 l1=new');
        Observer.Expect('page name', 'old');
        Observer.Expect('close', 'pQC OK db=old/1;pClose');
        Observer.Expect('db end', 'old/1 l1=new');
        Observer.Verify();
    end;

    [Test]
    procedure CardPart_SetLine_LineAction()
    var
        TP: TestPage "LT Y45 Card Part";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.Lines.LineAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vDesc new/a');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'lpM 10000 new/a db=a;eBML new;lM 10000 new/a db=a;lact 10000 rec=new db=new head=old/1;lC 10000');
        Observer.Expect('db after step', 'old/1 l1=new');
        Observer.Expect('page name', 'old');
        Observer.Expect('close', 'pQC OK db=old/1;pClose');
        Observer.Expect('db end', 'old/1 l1=new');
        Observer.Verify();
    end;

    [Test]
    procedure CardPart_SetLine_LineNext()
    var
        TP: TestPage "LT Y45 Card Part";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('line next', Format(TP.Lines.Next()));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vDesc new/a');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('line next', 'Yes');
        Observer.Expect('step', 'lpM 10000 new/a db=a;eBML new;lM 10000 new/a db=a;lC 20000');
        Observer.Expect('db after step', 'old/1 l1=new');
        Observer.Expect('page name', 'old');
        Observer.Expect('close', 'pQC OK db=old/1;pClose');
        Observer.Expect('db end', 'old/1 l1=new');
        Observer.Verify();
    end;

    [Test]
    procedure CardPart_SetLine_Next()
    var
        TP: TestPage "LT Y45 Card Part";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Observe('page name', TP.Name.Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vDesc new/a');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('next', 'Yes');
        Observer.Expect('step', 'R H2;C H2;lpM 10000 new/a db=a;eBML new;lM 10000 new/a db=a;lC 10000');
        Observer.Expect('db after step', 'old/1 l1=new');
        Observer.Expect('page name', 'two');
        Observer.Expect('close', 'pQC OK db=two/2;pClose');
        Observer.Expect('db end', 'old/1 l1=new');
        Observer.Verify();
    end;

    [Test]
    procedure CardPart_SetLine_OK()
    var
        TP: TestPage "LT Y45 Card Part";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        TP.OK().Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vDesc new/a');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step', 'lpM 10000 new/a db=a;eBML new;lM 10000 new/a db=a;pQC OK db=old/1;pClose');
        Observer.Expect('db after step', 'old/1 l1=new');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ModifyError_Action()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('boom');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        asserterror begin
            TP.ReadAct.Invoke();
            Error('no error');
        end;
        Observer.ObserveError('step error');
        Observer.Observe('step', Log.Take());
        Observer.Observe('errors name', Format(TP.Name.ValidationErrorCount()));
        asserterror begin
            TP.Close();
            Error('no error');
        end;
        Observer.ObserveError('close error');
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName boom/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step error|text', 'no error');
        Observer.Expect('step error|code', 'Dialog');
        Observer.Expect('step', 'pM boom/old db=old/1;eBM boom t=Yes db=old/1;tM boom/old db=old/1');
        Observer.Expect('errors name', '0');
        Observer.Expect('close error|text', 'no error');
        Observer.Expect('close error|code', 'Dialog');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ModifyError_Next()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('boom');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        asserterror begin
            Observer.Observe('next', Format(TP.Next()));
            Error('no error');
        end;
        Observer.ObserveError('step error');
        Observer.Observe('step', Log.Take());
        Observer.Observe('errors name', Format(TP.Name.ValidationErrorCount()));
        asserterror begin
            TP.Close();
            Error('no error');
        end;
        Observer.ObserveError('close error');
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName boom/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('next', 'No');
        Observer.Expect('step error|text', 'no error');
        Observer.Expect('step error|code', 'Dialog');
        Observer.Expect('step', 'pM boom/old db=old/1;eBM boom t=Yes db=old/1;tM boom/old db=old/1');
        Observer.Expect('errors name', '0');
        Observer.Expect('close error|text', 'no error');
        Observer.Expect('close error|code', 'Dialog');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ModifyError_OK()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('boom');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        asserterror begin
            TP.OK().Invoke();
            Error('no error');
        end;
        Observer.ObserveError('step error');
        Observer.Observe('step', Log.Take());
        Observer.Observe('errors name', Format(TP.Name.ValidationErrorCount()));
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set', 'vName boom/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step error|text', 'no error');
        Observer.Expect('step error|code', 'Dialog');
        Observer.Expect('step', 'pM boom/old db=old/1;eBM boom t=Yes db=old/1;tM boom/old db=old/1');
        Observer.Expect('errors name', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ValidateError_Action()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        asserterror TP.Qty.SetValue(-1);
        Observer.ObserveError('set qty error');
        Observer.Observe('qty value', TP.Qty.Value);
        Observer.Observe('qty errors', Format(TP.Qty.ValidationErrorCount()));
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        asserterror begin
            TP.ReadAct.Invoke();
            Error('no error');
        end;
        Observer.ObserveError('step error');
        Observer.Observe('step', Log.Take());
        Observer.Observe('errors name', Format(TP.Name.ValidationErrorCount()));
        asserterror begin
            TP.Close();
            Error('no error');
        end;
        Observer.ObserveError('close error');
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set qty error|text', 'Validation error for Field: Qty,  Message = ''Qty must not be negative. (Select Refresh to discard errors)''');
        Observer.Expect('set qty error|code', 'TestValidation');
        Observer.Expect('qty value', '1');
        Observer.Expect('qty errors', '1');
        Observer.Expect('set', 'vName new/old db=old/1;vQty -1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step error|text', 'no error');
        Observer.Expect('step error|code', 'Dialog');
        Observer.Expect('step', '');
        Observer.Expect('errors name', '0');
        Observer.Expect('close error|text', 'no error');
        Observer.Expect('close error|code', 'Dialog');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ValidateError_Next()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        asserterror TP.Qty.SetValue(-1);
        Observer.ObserveError('set qty error');
        Observer.Observe('qty value', TP.Qty.Value);
        Observer.Observe('qty errors', Format(TP.Qty.ValidationErrorCount()));
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        asserterror begin
            Observer.Observe('next', Format(TP.Next()));
            Error('no error');
        end;
        Observer.ObserveError('step error');
        Observer.Observe('step', Log.Take());
        Observer.Observe('errors name', Format(TP.Name.ValidationErrorCount()));
        asserterror begin
            TP.Close();
            Error('no error');
        end;
        Observer.ObserveError('close error');
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'R H1;C H1');
        Observer.Expect('set qty error|text', 'Validation error for Field: Qty,  Message = ''Qty must not be negative. (Select Refresh to discard errors)''');
        Observer.Expect('set qty error|code', 'TestValidation');
        Observer.Expect('qty value', '1');
        Observer.Expect('qty errors', '1');
        Observer.Expect('set', 'vName new/old db=old/1;vQty -1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('next', 'No');
        Observer.Expect('step error|text', 'no error');
        Observer.Expect('step error|code', 'Dialog');
        Observer.Expect('step', '');
        Observer.Expect('errors name', '0');
        Observer.Expect('close error|text', 'no error');
        Observer.Expect('close error|code', 'Dialog');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure List_ModifyError_Action()
    var
        TP: TestPage "LT Y45 Head List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('boom');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        asserterror begin
            TP.ReadAct.Invoke();
            Error('no error');
        end;
        Observer.ObserveError('step error');
        Observer.Observe('step', Log.Take());
        Observer.Observe('errors name', Format(TP.Name.ValidationErrorCount()));
        asserterror begin
            TP.Close();
            Error('no error');
        end;
        Observer.ObserveError('close error');
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('set', 'vName boom/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step error|text', 'no error');
        Observer.Expect('step error|code', 'Dialog');
        Observer.Expect('step', 'pM boom/old db=old/1;eBM boom t=Yes db=old/1;tM boom/old db=old/1');
        Observer.Expect('errors name', '0');
        Observer.Expect('close error|text', 'no error');
        Observer.Expect('close error|code', 'Dialog');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure List_ValidateError_Action()
    var
        TP: TestPage "LT Y45 Head List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        asserterror TP.Qty.SetValue(-1);
        Observer.ObserveError('set qty error');
        Observer.Observe('qty value', TP.Qty.Value);
        Observer.Observe('qty errors', Format(TP.Qty.ValidationErrorCount()));
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        asserterror begin
            TP.ReadAct.Invoke();
            Error('no error');
        end;
        Observer.ObserveError('step error');
        Observer.Observe('step', Log.Take());
        Observer.Observe('errors name', Format(TP.Name.ValidationErrorCount()));
        asserterror begin
            TP.Close();
            Error('no error');
        end;
        Observer.ObserveError('close error');
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('set qty error|text', 'Validation error for Field: Qty,  Message = ''Qty must not be negative.''');
        Observer.Expect('set qty error|code', 'TestValidation');
        Observer.Expect('qty value', '1');
        Observer.Expect('qty errors', '1');
        Observer.Expect('set', 'vName new/old db=old/1;vQty -1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step error|text', 'no error');
        Observer.Expect('step error|code', 'Dialog');
        Observer.Expect('step', '');
        Observer.Expect('errors name', '0');
        Observer.Expect('close error|text', 'no error');
        Observer.Expect('close error|code', 'Dialog');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_ModifyError_LineAction()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('boom');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('H1') + ' l1=' + Log.LineDb('H1', 10000));
        asserterror begin
            TP.Lines.LineAct.Invoke();
            Error('no error');
        end;
        Observer.ObserveError('step error');
        Observer.Observe('step', Log.Take());
        Observer.Observe('errors name', Format(TP.Name.ValidationErrorCount()));
        asserterror begin
            TP.Close();
            Error('no error');
        end;
        Observer.ObserveError('close error');
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'R H1;C H1;lC 10000');
        Observer.Expect('set', 'vName boom/old db=old/1');
        Observer.Expect('db after set', 'old/1 l1=a');
        Observer.Expect('step error|text', 'no error');
        Observer.Expect('step error|code', 'Dialog');
        Observer.Expect('step', 'pM boom/old db=old/1;eBM boom t=Yes db=old/1;tM boom/old db=old/1;lact 10000 rec=a db=a head=old/1;lC 10000');
        Observer.Expect('errors name', '0');
        Observer.Expect('close error|text', 'no error');
        Observer.Expect('close error|code', 'Dialog');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure Card_New_CodeThenName_Action()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenNew();
        Observer.Observe('open', Log.Take());
        TP."Code".SetValue('N1');
        Observer.Observe('set code', Log.Take());
        Observer.Observe('db after code', Log.HeadDb('N1'));
        TP.Name.SetValue('nn');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db after name', Log.HeadDb('N1'));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('N1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('N1'));
        Observer.Expect('open', 'pN;C ');
        Observer.Expect('set code', 'vCode N1');
        Observer.Expect('db after code', 'none');
        Observer.Expect('set name', 'pI N1 ;eBI N1 t=Yes;tI N1  db=none;vName nn/ db=/0');
        Observer.Expect('db after name', '/0');
        Observer.Expect('step', 'pM nn/ db=/0;eBM nn t=Yes db=/0;tM nn/ db=/0;eAM db=nn/0;R N1;act N1 rec=nn/0 db=nn/0 l1=none;R N1;R N1;C N1');
        Observer.Expect('db after step', 'nn/0');
        Observer.Expect('close', 'pQC OK db=nn/0;pClose');
        Observer.Expect('db end', 'nn/0');
        Observer.Verify();
    end;

    [Test]
    procedure Card_New_NameOnly_Action()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenNew();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('nn');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db after name', Log.HeadDb(''));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb(''));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb(''));
        Observer.Expect('open', 'pN;C ');
        Observer.Expect('set name', 'pI  ;eBI  t=Yes;tI   db=none;vName nn/ db=/0');
        Observer.Expect('db after name', '/0');
        Observer.Expect('step', 'pM nn/ db=/0;eBM nn t=Yes db=/0;tM nn/ db=/0;eAM db=nn/0;R ;act  rec=nn/0 db=nn/0 l1=none;R ;R ;C ');
        Observer.Expect('db after step', 'nn/0');
        Observer.Expect('close', 'pQC OK db=nn/0;pClose');
        Observer.Expect('db end', 'nn/0');
        Observer.Verify();
    end;

    [Test]
    procedure Card_New_CodeThenName_OK()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenNew();
        Observer.Observe('open', Log.Take());
        TP."Code".SetValue('N1');
        TP.Name.SetValue('nn');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('N1'));
        TP.OK().Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('N1'));
        Observer.Expect('open', 'pN;C ');
        Observer.Expect('set', 'vCode N1;pI N1 ;eBI N1 t=Yes;tI N1  db=none;vName nn/ db=/0');
        Observer.Expect('db after set', '/0');
        Observer.Expect('step', 'pM nn/ db=/0;eBM nn t=Yes db=/0;tM nn/ db=/0;eAM db=nn/0;pQC OK db=nn/0;pClose');
        Observer.Expect('db after step', 'nn/0');
        Observer.Verify();
    end;

    [Test]
    procedure Card_New_CodeThenName_RunObjectCodeunit()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenNew();
        Observer.Observe('open', Log.Take());
        TP."Code".SetValue('N1');
        TP.Name.SetValue('nn');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('N1'));
        TP.RunCu.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('N1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'pN;C ');
        Observer.Expect('set', 'vCode N1;pI N1 ;eBI N1 t=Yes;tI N1  db=none;vName nn/ db=/0');
        Observer.Expect('db after set', '/0');
        Observer.Expect('step', 'pM nn/ db=/0;eBM nn t=Yes db=/0;tM nn/ db=/0;eAM db=nn/0;cu N1 rec=nn/0 db=nn/0 l1=none;R N1;C N1');
        Observer.Expect('db after step', 'nn/0');
        Observer.Expect('close', 'pQC OK db=nn/0;pClose');
        Observer.Verify();
    end;

    [Test]
    procedure List_New_CodeThenName_Action()
    var
        TP: TestPage "LT Y45 Head List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.New();
        Observer.Observe('new', Log.Take());
        TP."Code".SetValue('N1');
        Observer.Observe('set code', Log.Take());
        Observer.Observe('db after code', Log.HeadDb('N1'));
        TP.Name.SetValue('nn');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db after name', Log.HeadDb('N1'));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('N1'));
        Observer.Observe('page code', TP."Code".Value);
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('N1'));
        Observer.Expect('open', 'R H1;R H2;R H1;R H1;C H1');
        Observer.Expect('new', 'pN;C ');
        Observer.Expect('set code', 'vCode N1');
        Observer.Expect('db after code', 'none');
        Observer.Expect('set name', 'pI N1 ;eBI N1 t=Yes;tI N1  db=none;vName nn/ db=/0');
        Observer.Expect('db after name', '/0');
        Observer.Expect('step', 'pM nn/ db=/0;eBM nn t=Yes db=/0;tM nn/ db=/0;eAM db=nn/0;R N1;act N1 rec=nn/0 db=nn/0 l1=none;R N1;R N1;R H2;R H1;R N1;R N1;C N1');
        Observer.Expect('db after step', 'nn/0');
        Observer.Expect('page code', 'N1');
        Observer.Expect('close', 'pQC OK db=nn/0;pClose');
        Observer.Expect('db end', 'nn/0');
        Observer.Verify();
    end;

    [Test]
    procedure List_New_CodeThenName_Close()
    var
        TP: TestPage "LT Y45 Head List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        TP.New();
        TP."Code".SetValue('N1');
        TP.Name.SetValue('nn');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('N1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('N1'));
        Observer.Expect('set', 'R H1;R H2;R H1;R H1;C H1;pN;C ;vCode N1;pI N1 ;eBI N1 t=Yes;tI N1  db=none;vName nn/ db=/0');
        Observer.Expect('db after set', '/0');
        Observer.Expect('close', 'pM nn/ db=/0;eBM nn t=Yes db=/0;tM nn/ db=/0;eAM db=nn/0;pQC OK db=nn/0;pClose');
        Observer.Expect('db end', 'nn/0');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_New_HeadThenLine_Action()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenNew();
        Observer.Observe('open', Log.Take());
        TP."Code".SetValue('N1');
        TP.Name.SetValue('nn');
        Observer.Observe('set head', Log.Take());
        Observer.Observe('db after head', Log.HeadDb('N1'));
        TP.Lines.New();
        TP.Lines.Desc.SetValue('nl');
        Observer.Observe('set line', Log.Take());
        Observer.Observe('db after line', Log.HeadDb('N1') + ' l1=' + Log.LineDb('N1', 10000));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('N1') + ' l1=' + Log.LineDb('N1', 10000));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('N1') + ' l1=' + Log.LineDb('N1', 10000));
        Observer.Expect('open', 'pN;C ;lpN;lC 0;lpN;lC 0;lpN;lC 0');
        Observer.Expect('set head', 'vCode N1;lpN;lC 0;lpN;lC 0;lpN;lC 0;pI N1 ;eBI N1 t=Yes;tI N1  db=none;lpN;lC 0;lpN;lC 0;lpN;lC 0;vName nn/ db=/0');
        Observer.Expect('db after head', '/0');
        Observer.Expect('set line', 'pM nn/ db=/0;eBM nn t=Yes db=/0;tM nn/ db=/0;eAM db=nn/0;lpN;lC 0;vDesc nl/');
        Observer.Expect('db after line', 'nn/0 l1=none');
        Observer.Expect('step', 'lpI 20000 nl;eBIL nl;lI N1 20000 nl head=nn/0;R N1;act N1 rec=nn/0 db=nn/0 l1=none;R N1;R N1;C N1;lC 20000');
        Observer.Expect('db after step', 'nn/0 l1=none');
        Observer.Expect('close', 'pQC OK db=nn/0;pClose');
        Observer.Expect('db end', 'nn/0 l1=none');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_New_HeadThenLine_LineAction()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenNew();
        TP."Code".SetValue('N1');
        TP.Name.SetValue('nn');
        TP.Lines.New();
        TP.Lines.Desc.SetValue('nl');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.HeadDb('N1') + ' l1=' + Log.LineDb('N1', 10000));
        TP.Lines.LineAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.HeadDb('N1') + ' l1=' + Log.LineDb('N1', 10000));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('N1') + ' l1=' + Log.LineDb('N1', 10000));
        Observer.Expect('set', 'pN;C ;lpN;lC 0;lpN;lC 0;lpN;lC 0;vCode N1;lpN;lC 0;lpN;lC 0;lpN;lC 0;pI N1 ;eBI N1 t=Yes;tI N1  db=none;lpN;lC 0;lpN;lC 0;lpN;lC 0;vName nn/ db=/0;pM nn/ db=/0;eBM nn t=Yes db=/0;tM nn/ db=/0;eAM db=nn/0;lpN;lC 0;vDesc nl/');
        Observer.Expect('db after set', 'nn/0 l1=none');
        Observer.Expect('step', 'lpI 20000 nl;eBIL nl;lI N1 20000 nl head=nn/0;lact 20000 rec=nl db=nl head=nn/0;lC 20000');
        Observer.Expect('db after step', 'nn/0 l1=none');
        Observer.Expect('close', 'pQC OK db=nn/0;pClose');
        Observer.Expect('db end', 'nn/0 l1=none');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_Existing_NewLine_Action()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('new', Log.Take());
        TP.Lines.Desc.SetValue('nl');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.LineDb('H1', 30000));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.LineDb('H1', 30000));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.LineDb('H1', 30000));
        Observer.Expect('new', 'R H1;C H1;lC 10000;lpN;lC 0;lC 20000;lpN;lC 0');
        Observer.Expect('set', 'vDesc nl/');
        Observer.Expect('db after set', 'none');
        Observer.Expect('step', 'lpI 30000 nl;eBIL nl;lI H1 30000 nl head=old/1;R H1;act H1 rec=old/1 db=old/1 l1=a;R H1;R H1;C H1;lC 30000');
        Observer.Expect('db after step', 'nl');
        Observer.Expect('close', 'pQC OK db=old/1;pClose');
        Observer.Expect('db end', 'nl');
        Observer.Verify();
    end;

    [Test]
    procedure CardPart_Existing_NewLine_Action()
    var
        TP: TestPage "LT Y45 Card Part";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('new', Log.Take());
        TP.Lines.Desc.SetValue('nl');
        Observer.Observe('set', Log.Take());
        Observer.Observe('db after set', Log.LineDb('H1', 30000));
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('db after step', Log.LineDb('H1', 30000));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.LineDb('H1', 30000));
        Observer.Expect('new', 'R H1;C H1;lC 10000;lpN;lC 0;lC 20000;lpN;lC 0');
        Observer.Expect('set', 'vDesc nl/');
        Observer.Expect('db after set', 'none');
        Observer.Expect('step', 'lpI 30000 nl;eBIL nl;lI H1 30000 nl head=old/1;R H1;act H1 rec=old/1 db=old/1 l1=a;R H1;R H1;C H1;lC 30000');
        Observer.Expect('db after step', 'nl');
        Observer.Expect('close', 'pQC OK db=old/1;pClose');
        Observer.Expect('db end', 'nl');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ModifyError_Action_PageState()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        TP.Name.SetValue('boom');
        Log.Take();
        ClearLastError();
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('last error', GetLastErrorText());
        Observer.Observe('page errors', Format(TP.ValidationErrorCount()));
        Observer.Observe('db after step', Log.HeadDb('H1'));
        Observer.Observe('page name', TP.Name.Value);
        asserterror TP.Name.SetValue('fine');
        Observer.ObserveError('set again error');
        Observer.Observe('set again', Log.Take());
        asserterror begin
            TP.ReadAct.Invoke();
            Error('no error');
        end;
        Observer.ObserveError('second action error');
        Observer.Observe('second action', Log.Take());
        asserterror begin
            TP.Close();
            Error('no error');
        end;
        Observer.ObserveError('close error');
        Observer.Observe('close', Log.Take());
        Observer.Expect('step', 'pM boom/old db=old/1;eBM boom t=Yes db=old/1;tM boom/old db=old/1');
        Observer.Expect('last error', 'Modify refused for boom.');
        Observer.Expect('page errors', '1');
        Observer.Expect('db after step', 'old/1');
        Observer.Expect('page name', 'boom');
        Observer.Expect('set again error|text', 'Validation error for Field: Name,  Message = ''This field cannot be validated since the key fields are not valid. (Select Refresh to discard errors)''');
        Observer.Expect('set again error|code', 'TestValidation');
        Observer.Expect('set again', '');
        Observer.Expect('second action error|text', 'no error');
        Observer.Expect('second action error|code', 'Dialog');
        Observer.Expect('second action', '');
        Observer.Expect('close error|text', 'no error');
        Observer.Expect('close error|code', 'Dialog');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ModifyError_Next_PageState()
    var
        TP: TestPage "LT Y45 Head Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        TP.Name.SetValue('boom');
        Log.Take();
        ClearLastError();
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('step', Log.Take());
        Observer.Observe('last error', GetLastErrorText());
        Observer.Observe('page errors', Format(TP.ValidationErrorCount()));
        Observer.Observe('db after step', Log.HeadDb('H1'));
        Observer.Observe('page name', TP.Name.Value);
        asserterror TP.Name.SetValue('fine');
        Observer.ObserveError('set again error');
        Observer.Observe('set again', Log.Take());
        asserterror begin
            TP.ReadAct.Invoke();
            Error('no error');
        end;
        Observer.ObserveError('second action error');
        Observer.Observe('second action', Log.Take());
        asserterror begin
            TP.Close();
            Error('no error');
        end;
        Observer.ObserveError('close error');
        Observer.Observe('close', Log.Take());
        Observer.Expect('next', 'No');
        Observer.Expect('step', 'pM boom/old db=old/1;eBM boom t=Yes db=old/1;tM boom/old db=old/1');
        Observer.Expect('last error', 'Modify refused for boom.');
        Observer.Expect('page errors', '1');
        Observer.Expect('db after step', 'old/1');
        Observer.Expect('page name', 'boom');
        Observer.Expect('set again error|text', 'Validation error for Field: Name,  Message = ''This field cannot be validated since the key fields are not valid. (Select Refresh to discard errors)''');
        Observer.Expect('set again error|code', 'TestValidation');
        Observer.Expect('set again', '');
        Observer.Expect('second action error|text', 'no error');
        Observer.Expect('second action error|code', 'Dialog');
        Observer.Expect('second action', '');
        Observer.Expect('close error|text', 'no error');
        Observer.Expect('close error|code', 'Dialog');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure List_ModifyError_Action_PageState()
    var
        TP: TestPage "LT Y45 Head List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        TP.Name.SetValue('boom');
        Log.Take();
        ClearLastError();
        TP.ReadAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('last error', GetLastErrorText());
        Observer.Observe('page errors', Format(TP.ValidationErrorCount()));
        Observer.Observe('db after step', Log.HeadDb('H1'));
        Observer.Observe('page name', TP.Name.Value);
        asserterror TP.Name.SetValue('fine');
        Observer.ObserveError('set again error');
        Observer.Observe('set again', Log.Take());
        asserterror begin
            TP.ReadAct.Invoke();
            Error('no error');
        end;
        Observer.ObserveError('second action error');
        Observer.Observe('second action', Log.Take());
        asserterror begin
            TP.Close();
            Error('no error');
        end;
        Observer.ObserveError('close error');
        Observer.Observe('close', Log.Take());
        Observer.Expect('step', 'pM boom/old db=old/1;eBM boom t=Yes db=old/1;tM boom/old db=old/1');
        Observer.Expect('last error', 'Modify refused for boom.');
        Observer.Expect('page errors', '1');
        Observer.Expect('db after step', 'old/1');
        Observer.Expect('page name', 'boom');
        Observer.Expect('set again error|text', 'Validation error for Field: Name,  Message = ''This field cannot be validated since the key fields are not valid.''');
        Observer.Expect('set again error|code', 'TestValidation');
        Observer.Expect('set again', '');
        Observer.Expect('second action error|text', 'no error');
        Observer.Expect('second action error|code', 'Dialog');
        Observer.Expect('second action', '');
        Observer.Expect('close error|text', 'no error');
        Observer.Expect('close error|code', 'Dialog');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_ModifyError_LineAction_PageState()
    var
        TP: TestPage "LT Y45 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenEdit();
        TP.Name.SetValue('boom');
        Log.Take();
        ClearLastError();
        TP.Lines.LineAct.Invoke();
        Observer.Observe('step', Log.Take());
        Observer.Observe('last error', GetLastErrorText());
        Observer.Observe('page errors', Format(TP.ValidationErrorCount()));
        Observer.Observe('db after step', Log.HeadDb('H1'));
        Observer.Observe('page name', TP.Name.Value);
        asserterror TP.Name.SetValue('fine');
        Observer.ObserveError('set again error');
        Observer.Observe('set again', Log.Take());
        asserterror begin
            TP.ReadAct.Invoke();
            Error('no error');
        end;
        Observer.ObserveError('second action error');
        Observer.Observe('second action', Log.Take());
        asserterror begin
            TP.Close();
            Error('no error');
        end;
        Observer.ObserveError('close error');
        Observer.Observe('close', Log.Take());
        Observer.Expect('step', 'pM boom/old db=old/1;eBM boom t=Yes db=old/1;tM boom/old db=old/1;lact 10000 rec=a db=a head=old/1;lC 10000');
        Observer.Expect('last error', 'Modify refused for boom.');
        Observer.Expect('page errors', '1');
        Observer.Expect('db after step', 'old/1');
        Observer.Expect('page name', 'boom');
        Observer.Expect('set again error|text', 'Validation error for Field: Name,  Message = ''This field cannot be validated since the key fields are not valid. (Select Refresh to discard errors)''');
        Observer.Expect('set again error|code', 'TestValidation');
        Observer.Expect('set again', '');
        Observer.Expect('second action error|text', 'no error');
        Observer.Expect('second action error|code', 'Dialog');
        Observer.Expect('second action', '');
        Observer.Expect('close error|text', 'no error');
        Observer.Expect('close error|code', 'Dialog');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    local procedure InitNextFieldLines()
    var
        Line: Record "LT Y55 Line";
    begin
        Line.DeleteAll();
        Line.Doc := 'H1';
        Line."Line No." := 10000;
        Line.Desc := 'a';
        Line.Qty := 1;
        Line.Insert();
        Line.Doc := 'H1';
        Line."Line No." := 20000;
        Line.Desc := 'b';
        Line.Qty := 2;
        Line.Insert();
        Line.Doc := 'H2';
        Line."Line No." := 10000;
        Line.Desc := 'c';
        Line.Qty := 3;
        Line.Insert();
        Log.Take();
    end;

    local procedure NextFieldLineDb(DocCode: Code[20]; LineNo: Integer): Text
    var
        Line: Record "LT Y55 Line";
    begin
        Line.Doc := DocCode;
        Line."Line No." := LineNo;
        exit(Line.StoredDesc());
    end;

    [Test]
    procedure NextField_Worksheet_NameThenPageVar()
    var
        TP: TestPage "LT Y55 Worksheet";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('H1'));
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Worksheet_NameThenRecField()
    var
        TP: TestPage "LT Y55 Worksheet";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Worksheet_QtyThenName()
    var
        TP: TestPage "LT Y55 Worksheet";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('open', Log.Take());
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Worksheet_NameThenNameAgain()
    var
        TP: TestPage "LT Y55 Worksheet";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Name.SetValue('newer');
        Observer.Observe('set name2', Log.Take());
        Observer.Observe('db set name2', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Worksheet_PageVarThenName()
    var
        TP: TestPage "LT Y55 Worksheet";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('open', Log.Take());
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('H1'));
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Activate.SetValue(true);
        Observer.Observe('set act2', Log.Take());
        Observer.Observe('db set act2', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Card_NameThenPageVar()
    var
        TP: TestPage "LT Y55 Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('H1'));
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Card_NameThenRecField()
    var
        TP: TestPage "LT Y55 Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Card_QtyThenName()
    var
        TP: TestPage "LT Y55 Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Card_NameThenNameAgain()
    var
        TP: TestPage "LT Y55 Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Name.SetValue('newer');
        Observer.Observe('set name2', Log.Take());
        Observer.Observe('db set name2', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Card_PageVarThenName()
    var
        TP: TestPage "LT Y55 Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('H1'));
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Activate.SetValue(true);
        Observer.Observe('set act2', Log.Take());
        Observer.Observe('db set act2', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_List_NameThenPageVar()
    var
        TP: TestPage "LT Y55 List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('H1'));
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_List_NameThenRecField()
    var
        TP: TestPage "LT Y55 List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_List_QtyThenName()
    var
        TP: TestPage "LT Y55 List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Doc_NameThenPageVar()
    var
        TP: TestPage "LT Y55 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('H1'));
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Doc_NameThenRecField()
    var
        TP: TestPage "LT Y55 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Doc_QtyThenName()
    var
        TP: TestPage "LT Y55 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('H1'));
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Worksheet_GoToRecord_NameThenPageVar()
    var
        TP: TestPage "LT Y55 Worksheet";
        Observer: Codeunit "Probe Observer";
        Head: Record "LT Y45 Head";
    begin
        Init(false);
        TP.OpenEdit();
        Head.Get('H1');
        TP.GoToRecord(Head);
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1'));
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Card_New_CodeNamePageVarQty()
    var
        TP: TestPage "LT Y55 Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenNew();
        Observer.Observe('open', Log.Take());
        TP."Code".SetValue('N1');
        Observer.Observe('set code', Log.Take());
        Observer.Observe('db set code', Log.HeadDb('N1'));
        TP.Name.SetValue('nn');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('N1'));
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('N1'));
        TP.Qty.SetValue(5);
        Observer.Observe('set qty', Log.Take());
        Observer.Observe('db set qty', Log.HeadDb('N1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('N1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Card_New_CodePageVarName()
    var
        TP: TestPage "LT Y55 Card";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenNew();
        Observer.Observe('open', Log.Take());
        TP."Code".SetValue('N1');
        Observer.Observe('set code', Log.Take());
        Observer.Observe('db set code', Log.HeadDb('N1'));
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('N1'));
        TP.Name.SetValue('nn');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('N1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('N1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_List_New_CodeNamePageVar()
    var
        TP: TestPage "LT Y55 List";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        TP.New();
        Observer.Observe('open', Log.Take());
        TP."Code".SetValue('N1');
        Observer.Observe('set code', Log.Take());
        Observer.Observe('db set code', Log.HeadDb('N1'));
        TP.Name.SetValue('nn');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('N1'));
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('N1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('N1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Worksheet_New_CodeNamePageVar()
    var
        TP: TestPage "LT Y55 Worksheet Ins";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        TP.OpenEdit();
        TP.New();
        Observer.Observe('open', Log.Take());
        TP."Code".SetValue('N1');
        Observer.Observe('set code', Log.Take());
        Observer.Observe('db set code', Log.HeadDb('N1'));
        TP.Name.SetValue('nn');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('N1'));
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('N1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('N1'));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Part_DescThenPageVar()
    var
        TP: TestPage "LT Y55 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        InitNextFieldLines();
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set desc', Log.Take());
        Observer.Observe('db set desc', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Lines.LAct.SetValue(true);
        Observer.Observe('set lact', Log.Take());
        Observer.Observe('db set lact', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Lines.Qty.SetValue(5);
        Observer.Observe('set lqty', Log.Take());
        Observer.Observe('db set lqty', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Part_DescThenRecField()
    var
        TP: TestPage "LT Y55 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        InitNextFieldLines();
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set desc', Log.Take());
        Observer.Observe('db set desc', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Lines.Qty.SetValue(5);
        Observer.Observe('set lqty', Log.Take());
        Observer.Observe('db set lqty', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Part_QtyThenDesc()
    var
        TP: TestPage "LT Y55 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        InitNextFieldLines();
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Qty.SetValue(5);
        Observer.Observe('set lqty', Log.Take());
        Observer.Observe('db set lqty', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set desc', Log.Take());
        Observer.Observe('db set desc', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Part_HeadNameThenLineDesc()
    var
        TP: TestPage "LT Y55 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        InitNextFieldLines();
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set desc', Log.Take());
        Observer.Observe('db set desc', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Part_LineDescThenHeadName()
    var
        TP: TestPage "LT Y55 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        InitNextFieldLines();
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set desc', Log.Take());
        Observer.Observe('db set desc', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Name.SetValue('new');
        Observer.Observe('set name', Log.Take());
        Observer.Observe('db set name', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Part_LineDescThenHeadPageVar()
    var
        TP: TestPage "LT Y55 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        InitNextFieldLines();
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('new');
        Observer.Observe('set desc', Log.Take());
        Observer.Observe('db set desc', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Activate.SetValue(true);
        Observer.Observe('set act', Log.Take());
        Observer.Observe('db set act', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        Observer.Finish();
    end;

    [Test]
    procedure NextField_Part_New_DescThenPageVar()
    var
        TP: TestPage "LT Y55 Doc";
        Observer: Codeunit "Probe Observer";
    begin
        Init(false);
        InitNextFieldLines();
        TP.OpenEdit();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('open', Log.Take());
        TP.Lines.Desc.SetValue('x');
        Observer.Observe('set desc', Log.Take());
        Observer.Observe('db set desc', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Lines.LAct.SetValue(true);
        Observer.Observe('set lact', Log.Take());
        Observer.Observe('db set lact', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Lines.Qty.SetValue(5);
        Observer.Observe('set lqty', Log.Take());
        Observer.Observe('db set lqty', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1') + ' l1=' + NextFieldLineDb('H1', 10000));
        Observer.Finish();
    end;
}
