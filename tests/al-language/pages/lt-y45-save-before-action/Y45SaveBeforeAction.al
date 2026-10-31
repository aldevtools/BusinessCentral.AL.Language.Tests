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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        TP.Qty.SetValue(-1);
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
        TP.Qty.SetValue(-1);
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
        Observer.Finish();
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
        TP.Qty.SetValue(-1);
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}

