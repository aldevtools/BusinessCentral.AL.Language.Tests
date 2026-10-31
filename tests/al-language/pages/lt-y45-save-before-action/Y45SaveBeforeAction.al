// Probe (observe round): what BC does with an unsaved TestPage edit when an action, a move or a close comes next. Header written after measurement.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        TP.Name.SetValue('fine');
        Observer.Observe('set again', Log.Take());
        TP.ReadAct.Invoke();
        Observer.Observe('second action', Log.Take());
        Observer.Observe('db after second', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
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
        TP.Name.SetValue('fine');
        Observer.Observe('set again', Log.Take());
        TP.ReadAct.Invoke();
        Observer.Observe('second action', Log.Take());
        Observer.Observe('db after second', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
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
        TP.Name.SetValue('fine');
        Observer.Observe('set again', Log.Take());
        TP.ReadAct.Invoke();
        Observer.Observe('second action', Log.Take());
        Observer.Observe('db after second', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
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
        TP.Name.SetValue('fine');
        Observer.Observe('set again', Log.Take());
        TP.ReadAct.Invoke();
        Observer.Observe('second action', Log.Take());
        Observer.Observe('db after second', Log.HeadDb('H1'));
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('db end', Log.HeadDb('H1'));
        Observer.Finish();
    end;
}
