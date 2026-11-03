// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-saverecord-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT Chg Head (71490), LT Chg Line (71491), LT Chg Lines (71492), LT Chg Card (71493) from ChangedByOtherFixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a card with SetValue on a header field, a line added in the part whose table code modifies the header (Info, Counter), then a step on the card (an action that saves the row, an action that calls Modify, a second field edit): does BC raise 'changed by another user' or save? Observes the error text and code, the card values and the stored header.
// BC versions: 29 (27 and 28 by CI)

codeunit 71495 "LT Chg Asserterror"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Stored(): Text
    var
        Head: Record "LT Chg Head";
    begin
        if not Head.Get('H1') then
            exit('<no header>');
        exit('descr=' + Head.Descr + ' info=' + Head.Info + ' counter=' + Format(Head.Counter));
    end;

    local procedure Prepare(var Observer: Codeunit "Probe Observer"; var TP: TestPage "LT Chg Card")
    var
        Head: Record "LT Chg Head";
        Line: Record "LT Chg Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head.Code := 'H1';
        Head.Descr := 'orig';
        Head.Info := 'orig';
        Head.Insert();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.DescrF.SetValue('typed');
        Observer.Observe('stored-after-card-edit', Stored());
        TP.Lines.New();
        TP.Lines.LineNoF.SetValue(1);
        TP.Lines.DescrF.SetValue('line one');
        TP.Lines.New();
        Observer.Observe('stored-after-line', Stored());
        Observer.Observe('card-counter-before', TP.CounterF.Value());
        Observer.Observe('card-info-before', TP.InfoF.Value());
    end;

    [Test]
    procedure P182b_Asserterror_SaveRecordAction()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Chg Card";
    begin
        Prepare(Observer, TP);
        TP.SaveRow.Invoke();
        Observer.Observe('step', 'no error');
        Observer.Observe('card-descr-after', TP.DescrF.Value());
        Observer.Observe('card-info-after', TP.InfoF.Value());
        Observer.Observe('card-counter-after', TP.CounterF.Value());
        Observer.Observe('stored-after-step', Stored());
        TP.Close();
        Observer.Observe('stored-after-close', Stored());
        Observer.Expect('stored-after-card-edit', 'descr=orig info=orig counter=0');
        Observer.Expect('stored-after-line', 'descr=typed info=by line insert counter=1');
        Observer.Expect('card-counter-before', '1');
        Observer.Expect('card-info-before', 'by line insert');
        Observer.Expect('step', 'no error');
        Observer.Expect('card-descr-after', 'typed');
        Observer.Expect('card-info-after', 'by line insert');
        Observer.Expect('card-counter-after', '1');
        Observer.Expect('stored-after-step', 'descr=typed info=by line insert counter=1');
        Observer.Expect('stored-after-close', 'descr=typed info=by line insert counter=1');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_Asserterror_ModifyAction()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Chg Card";
    begin
        Prepare(Observer, TP);
        TP.ModifyRow.Invoke();
        Observer.Observe('step', 'no error');
        Observer.Observe('card-descr-after', TP.DescrF.Value());
        Observer.Observe('card-info-after', TP.InfoF.Value());
        Observer.Observe('card-counter-after', TP.CounterF.Value());
        Observer.Observe('stored-after-step', Stored());
        TP.Close();
        Observer.Observe('stored-after-close', Stored());
        Observer.Expect('stored-after-card-edit', 'descr=orig info=orig counter=0');
        Observer.Expect('stored-after-line', 'descr=typed info=by line insert counter=1');
        Observer.Expect('card-counter-before', '1');
        Observer.Expect('card-info-before', 'by line insert');
        Observer.Expect('step', 'no error');
        Observer.Expect('card-descr-after', 'by action');
        Observer.Expect('card-info-after', 'by line insert');
        Observer.Expect('card-counter-after', '1');
        Observer.Expect('stored-after-step', 'descr=by action info=by line insert counter=1');
        Observer.Expect('stored-after-close', 'descr=by action info=by line insert counter=1');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_Asserterror_SecondFieldEdit()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Chg Card";
    begin
        Prepare(Observer, TP);
        TP.InfoF.SetValue('typed info');
        Observer.Observe('step', 'no error');
        Observer.Observe('card-descr-after', TP.DescrF.Value());
        Observer.Observe('card-info-after', TP.InfoF.Value());
        Observer.Observe('card-counter-after', TP.CounterF.Value());
        Observer.Observe('stored-after-step', Stored());
        TP.Close();
        Observer.Observe('stored-after-close', Stored());
        Observer.Expect('stored-after-card-edit', 'descr=orig info=orig counter=0');
        Observer.Expect('stored-after-line', 'descr=typed info=by line insert counter=1');
        Observer.Expect('card-counter-before', '1');
        Observer.Expect('card-info-before', 'by line insert');
        Observer.Expect('step', 'no error');
        Observer.Expect('card-descr-after', 'typed');
        Observer.Expect('card-info-after', 'typed info');
        Observer.Expect('card-counter-after', '1');
        Observer.Expect('stored-after-step', 'descr=typed info=by line insert counter=1');
        Observer.Expect('stored-after-close', 'descr=typed info=typed info counter=1');
        Observer.Verify();
    end;
}
