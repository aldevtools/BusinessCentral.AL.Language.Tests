// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-methods
// Scope: in-scope
// Fixtures used: Probe Observer (69160); SgListKeyObjects.al (table 89094, pages 89095 and 89096, log 89097)
// Probe: writer SG, al-runtime-rs assumption list-other-key-other-moves; facts in SgListKeyObjects.al.
// BC versions: 27, 28, 29

codeunit 89098 "LT SG List Key Moves"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT SG Key Log";

    local procedure Add(No: Code[10]; NewName: Text[30])
    var
        Row: Record "LT SG Key Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := NewName;
        Row.Insert();
    end;

    local procedure SeedFour()
    var
        Row: Record "LT SG Key Row";
    begin
        Row.DeleteAll();
        Add('A', 'delta');
        Add('B', 'charlie');
        Add('C', 'bravo');
        Add('D', 'alpha');
        Log.Take();
    end;

    local procedure SeedOne()
    var
        Row: Record "LT SG Key Row";
    begin
        Row.DeleteAll();
        Add('A', 'delta');
        Log.Take();
    end;

    local procedure SeedThirty()
    var
        Row: Record "LT SG Key Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 30 do
            Add('R' + Format(i, 2, '<Integer,2><Filler Character,0>'), 'n' + Format(100 - i));
        Log.Take();
    end;

    [Test]
    procedure SG_Key_FourRows_Moves()
    var
        P: TestPage "LT SG Key List";
        Row: Record "LT SG Key Row";
    begin
        SeedFour();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.Last();
        Observer.Observe('last', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.GoToKey('B');
        Observer.Observe('gotokey_b', P.NoCtl.Value() + '|' + Log.Take());
        Row.Get('C');
        P.GoToRecord(Row);
        Observer.Observe('gotorecord_c', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Next();
        Observer.Observe('next', P.NoCtl.Value() + '|' + Log.Take());
        P.Previous();
        Observer.Observe('previous', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure SG_Key_OneRow_Open()
    var
        P: TestPage "LT SG Key List";
    begin
        SeedOne();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SG_Key_ThirtyRows_Moves()
    var
        P: TestPage "LT SG Key List";
        Row: Record "LT SG Key Row";
    begin
        SeedThirty();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.Next();
        Observer.Observe('next', P.NoCtl.Value() + '|' + Log.Take());
        P.Last();
        Observer.Observe('last', P.NoCtl.Value() + '|' + Log.Take());
        P.GoToKey('R15');
        Observer.Observe('gotokey_r15', P.NoCtl.Value() + '|' + Log.Take());
        Row.Get('R02');
        P.GoToRecord(Row);
        Observer.Observe('gotorecord_r02', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SG_Pk_FourRows_Moves()
    var
        P: TestPage "LT SG Pk List";
        Row: Record "LT SG Key Row";
    begin
        SeedFour();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.Last();
        Observer.Observe('last', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.GoToKey('B');
        Observer.Observe('gotokey_b', P.NoCtl.Value() + '|' + Log.Take());
        Row.Get('C');
        P.GoToRecord(Row);
        Observer.Observe('gotorecord_c', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Next();
        Observer.Observe('next', P.NoCtl.Value() + '|' + Log.Take());
        P.Previous();
        Observer.Observe('previous', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure SG_Pk_OneRow_Open()
    var
        P: TestPage "LT SG Pk List";
    begin
        SeedOne();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SG_Pk_ThirtyRows_Moves()
    var
        P: TestPage "LT SG Pk List";
        Row: Record "LT SG Key Row";
    begin
        SeedThirty();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.Next();
        Observer.Observe('next', P.NoCtl.Value() + '|' + Log.Take());
        P.Last();
        Observer.Observe('last', P.NoCtl.Value() + '|' + Log.Take());
        P.GoToKey('R15');
        Observer.Observe('gotokey_r15', P.NoCtl.Value() + '|' + Log.Take());
        Row.Get('R02');
        P.GoToRecord(Row);
        Observer.Observe('gotorecord_r02', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Finish();
    end;
}
