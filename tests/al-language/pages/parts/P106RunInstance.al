// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P106 Item/Group/Log tables, LT P106 Log codeunit, pages LT P106 Card / List from P106Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: instance forms Page.Run() and Page.RunModal() of a Page variable (Page.Run#1, Page.RunModal#1) with SetRecord, SetTableView, GetRecord, LookupMode: returned Action, what the handler sees, the record after the call, trigger order
// BC versions: 29 (27 and 28 by CI)

codeunit 72412 "LT P106 Run Instance"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P106 Log";
        H: Text;
        Mode: Integer;

    local procedure Note(T: Text)
    begin
        if H <> '' then
            H += ';';
        H += T;
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Tag: Text; Act: Action)
    begin
        Observer.Observe(Tag + '_action', Format(Act));
        Observer.Observe(Tag + '_h', H);
        Observer.Observe(Tag + '_log', Log.Dump());
        H := '';
        Log.Reset();
    end;

    [ModalPageHandler]
    procedure ListH(var P: TestPage "LT P106 List")
    var
        Nos: Text;
    begin
        Note('cur=' + P.NoCtl.Value());
        if P.First() then
            repeat
                Nos += P.NoCtl.Value();
            until not P.Next();
        Note('rows=' + Nos);
        case Mode of
            0:
                P.OK().Invoke();
            1:
                P.Cancel().Invoke();
            2:
                begin
                    P.GoToKey('C');
                    P.OK().Invoke();
                end;
            3:
                begin
                    P.ActLookupMode.Invoke();
                    P.OK().Invoke();
                end;
        end;
    end;

    [ModalPageHandler]
    procedure CardH(var P: TestPage "LT P106 Card")
    begin
        Note('card=' + P.NoCtl.Value() + '/' + P.NameCtl.Value());
        if Mode = 3 then
            P.ActLookupMode.Invoke();
        if Mode = 1 then
            P.Cancel().Invoke()
        else
            P.OK().Invoke();
    end;

    [PageHandler]
    procedure ListPlain(var P: TestPage "LT P106 List")
    begin
        Note('plain=' + P.NoCtl.Value());
    end;

    [PageHandler]
    procedure CardPlain(var P: TestPage "LT P106 Card")
    begin
        Note('plain=' + P.NoCtl.Value() + '/' + P.NameCtl.Value());
    end;

    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_Inst_RunModal_List()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P106 List";
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Act := Pg.RunModal();
        Report(Observer, 'plain', Act);
        Mode := 1;
        asserterror Act := Pg.RunModal();
        Observer.ObserveError('af100');
        Report(Observer, 'cancel', Act);
        Observer.Expect('plain_action', 'OK');
        Observer.Expect('plain_h', 'cur=A;rows=ABCD');
        Observer.Expect('plain_log', 'List OnOpenPage filter=;List OnQueryClosePage(OK)');
        Observer.Expect('af100|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('af100|code', 'TestActionNotFound');
        Observer.Expect('cancel_action', 'OK');
        Observer.Expect('cancel_h', 'cur=A;rows=ABCD');
        Observer.Expect('cancel_log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_Inst_RunModal_SetRecord()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P106 List";
        Item: Record "LT P106 Item";
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Item.Get('C');
        Pg.SetRecord(Item);
        Act := Pg.RunModal();
        Report(Observer, 'setrecord', Act);
        Mode := 2;
        Item.Get('A');
        Pg.SetRecord(Item);
        Act := Pg.RunModal();
        Report(Observer, 'pick', Act);
        Clear(Item);
        Pg.GetRecord(Item);
        Observer.Observe('getrecord', Item."No.");
        Observer.Expect('setrecord_action', 'OK');
        Observer.Expect('setrecord_h', 'cur=C;rows=ABCD');
        Observer.Expect('setrecord_log', 'List OnOpenPage filter=;List OnQueryClosePage(OK)');
        Observer.Expect('pick_action', 'OK');
        Observer.Expect('pick_h', 'cur=A;rows=ABCD');
        Observer.Expect('pick_log', 'List OnOpenPage filter=;List OnQueryClosePage(OK)');
        Observer.Expect('getrecord', 'C');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_Inst_RunModal_SetTableView()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P106 List";
        Item: Record "LT P106 Item";
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Item.SetRange(Qty, 3);
        Pg.SetTableView(Item);
        Act := Pg.RunModal();
        Report(Observer, 'view_qty3', Act);
        Item.Reset();
        Item.SetFilter("No.", 'A|B');
        Pg.SetTableView(Item);
        Act := Pg.RunModal();
        Report(Observer, 'view_ab', Act);
        Observer.Expect('view_qty3_action', 'OK');
        Observer.Expect('view_qty3_h', 'cur=C;rows=CD');
        Observer.Expect('view_qty3_log', 'List OnOpenPage filter=Qty: 3;List OnQueryClosePage(OK)');
        Observer.Expect('view_ab_action', 'OK');
        Observer.Expect('view_ab_h', 'cur=A;rows=AB');
        Observer.Expect('view_ab_log', 'List OnOpenPage filter=No.: A|B;List OnQueryClosePage(OK)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_Inst_RunModal_LookupMode()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P106 List";
        Act: Action;
    begin
        Log.Seed();
        Observer.Observe('before', Format(Pg.LookupMode()));
        Pg.LookupMode(true);
        Observer.Observe('set_true', Format(Pg.LookupMode()));
        Mode := 3;
        Act := Pg.RunModal();
        Report(Observer, 'lookup_true', Act);
        Pg.LookupMode(false);
        Act := Pg.RunModal();
        Report(Observer, 'lookup_false', Act);
        Observer.Expect('before', 'No');
        Observer.Expect('set_true', 'Yes');
        Observer.Expect('lookup_true_action', 'LookupOK');
        Observer.Expect('lookup_true_h', 'cur=A;rows=ABCD');
        Observer.Expect('lookup_true_log', 'List OnOpenPage filter=;LookupMode=Yes;List OnQueryClosePage(LookupOK)');
        Observer.Expect('lookup_false_action', 'OK');
        Observer.Expect('lookup_false_h', 'cur=D;rows=ABCD');
        Observer.Expect('lookup_false_log', 'List OnOpenPage filter=;LookupMode=No;List OnQueryClosePage(OK)');
        Observer.Verify();
    end;
}
