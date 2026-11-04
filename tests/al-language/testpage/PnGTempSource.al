// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetabletemporary-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG Temp Source (70147), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 81 (SourceTableTemporary): the page's Rec is a temporary record the client reads and writes like a stored one
// Facts: rows read, SetValue through the controls, New, key edits, record count seen by an action, and the stored table staying empty
// BC versions: 29 (27 and 28 by CI)

codeunit 70184 "LT PnG Temp Source"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ReadRowsOfTheTemporarySource()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        List: TestPage "LT PnG Temp Source";
    begin
        Item.DeleteAll();
        List.OpenEdit();
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('first-no', List.NoCtl.Value());
        Observer.Observe('first-name', List.NameCtl.Value());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('second-no', List.NoCtl.Value());
        Observer.Observe('next-again', Format(List.Next()));
        Observer.Observe('stored-count', Format(Item.Count()));
        List.Close();
        Observer.Expect('first', 'Yes');
        Observer.Expect('first-no', 'A');
        Observer.Expect('first-name', 'First');
        Observer.Expect('next', 'Yes');
        Observer.Expect('second-no', 'B');
        Observer.Expect('next-again', 'Yes');
        Observer.Expect('stored-count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure WriteRowsOfTheTemporarySource()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG Temp Source";
    begin
        Item.DeleteAll();
        Log.Reset();
        List.OpenEdit();
        List.First();
        List.NameCtl.SetValue('First changed');
        List.QtyCtl.SetValue(11);
        List.Next();
        List.NameCtl.SetValue('Second changed');
        Observer.Observe('second-name', List.NameCtl.Value());
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('first-name-reread', List.NameCtl.Value());
        Observer.Observe('first-qty-reread', List.QtyCtl.Value());
        List.CountRows.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('stored-count', Format(Item.Count()));
        List.Close();
        Observer.Expect('second-name', 'Second changed');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first-name-reread', 'First changed');
        Observer.Expect('first-qty-reread', '11');
        Observer.Expect('log', 'TblVal(A,First changed);TblVal(B,Second changed);TempCount(2)');
        Observer.Expect('stored-count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NewRowOfTheTemporarySource()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG Temp Source";
    begin
        Item.DeleteAll();
        Log.Reset();
        List.OpenEdit();
        List.New();
        List.NoCtl.SetValue('C');
        List.NameCtl.SetValue('Third');
        Observer.Observe('goto-third', Format(List.GoToKey('C')));
        Observer.Observe('third-name', List.NameCtl.Value());
        List.CountRows.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('last', Format(List.Last()));
        Observer.Observe('last-no', List.NoCtl.Value());
        Observer.Observe('stored-count', Format(Item.Count()));
        asserterror begin List.NoCtl.SetValue('A'); Error('LT-NOERROR'); end;
        Observer.ObserveError('duplicate-key-edit');
        List.Close();
        Observer.Expect('goto-third', 'Yes');
        Observer.Expect('third-name', 'Third');
        Observer.Expect('log', 'TblVal(C,Third);TempCount(3)');
        Observer.Expect('last', 'Yes');
        Observer.Expect('last-no', 'C');
        Observer.Expect('stored-count', '0');
        Observer.Expect('duplicate-key-edit|text', 'LT-NOERROR');
        Observer.Expect('duplicate-key-edit|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ViewModeAndOpenNewOfTheTemporarySource()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG Temp Source";
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        List.OpenView();
        Observer.Observe('view-editable', Format(List.NameCtl.Editable()));
        Observer.Observe('view-first-name', List.NameCtl.Value());
        asserterror begin List.NameCtl.SetValue('x'); Error('LT-NOERROR'); end;
        Observer.ObserveError('view-setvalue');
        List.Close();
        List.OpenNew();
        Observer.Observe('new-no', List.NoCtl.Value());
        Observer.Observe('new-name', List.NameCtl.Value());
        List.NoCtl.SetValue('N');
        Observer.Observe('new-goto-n', Format(List.GoToKey('N')));
        List.Close();
        Observer.Observe('stored-count', Format(Item.Count()));
        Observer.Expect('view-editable', 'No');
        Observer.Expect('view-first-name', 'First');
        Observer.Expect('view-setvalue|text', 'LT-NOERROR');
        Observer.Expect('view-setvalue|code', 'Dialog');
        Observer.Expect('new-no', '');
        Observer.Expect('new-name', '');
        Observer.Expect('new-goto-n', 'Yes');
        Observer.Expect('stored-count', '0');
        Observer.Verify();
    end;
}
