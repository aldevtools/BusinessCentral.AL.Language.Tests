codeunit 89775 "LT TC Bare Page Methods"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "LT TC Row";
        L: Record "LT TC Log";
    begin
        Row.DeleteAll();
        L.DeleteAll();
        Row.Init(); Row.Code := 'R1'; Row.Name := 'one'; Row.Insert();
        Row.Init(); Row.Code := 'R2'; Row.Name := 'two'; Row.Insert();
        Row.Init(); Row.Code := 'UPD'; Row.Name := 'upd'; Row.Insert();
    end;

    local procedure LogOf(Tag: Text): Text
    var
        L: Record "LT TC Log";
        R: Text;
    begin
        if L.FindSet() then
            repeat
                if L.Msg.StartsWith(Tag) then
                    R += CopyStr(L.Msg, StrLen(Tag) + 1) + ';';
            until L.Next() = 0;
        exit(R);
    end;

    local procedure NameOf(RowCode: Code[10]): Text
    var
        Row: Record "LT TC Row";
    begin
        Row.Get(RowCode);
        exit(Row.Name);
    end;

    local procedure RunUpdateInAfterGetRecordBare(): Text
    var
        P: TestPage "LT TC Bare List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('UPD');
        P.Close();
        exit(LogOf('B:') + '|' + NameOf('R1'));
    end;

    local procedure RunUpdateInAfterGetRecordCurr(): Text
    var
        P: TestPage "LT TC Curr List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('UPD');
        P.Close();
        exit(LogOf('C:') + '|' + NameOf('R1'));
    end;

    [Test]
    procedure UpdateInAfterGetRecord_BareMatchesCurrPage()
    var
        Bare: Text;
        Curr: Text;
    begin
        Bare := RunUpdateInAfterGetRecordBare();
        Curr := RunUpdateInAfterGetRecordCurr();
        Assert.AreEqual(Curr, Bare, 'bare form must behave like the CurrPage. form');
        Assert.AreEqual('OBS', Bare, 'log and R1 name');
    end;

    local procedure RunUpdateFalseActionBare(): Text
    var
        P: TestPage "LT TC Bare List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.UpdateFalse.Invoke();
        P.Close();
        exit(LogOf('B:') + '|' + NameOf('R1'));
    end;

    local procedure RunUpdateFalseActionCurr(): Text
    var
        P: TestPage "LT TC Curr List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.UpdateFalse.Invoke();
        P.Close();
        exit(LogOf('C:') + '|' + NameOf('R1'));
    end;

    [Test]
    procedure UpdateFalseAction_BareMatchesCurrPage()
    var
        Bare: Text;
        Curr: Text;
    begin
        Bare := RunUpdateFalseActionBare();
        Curr := RunUpdateFalseActionCurr();
        Assert.AreEqual(Curr, Bare, 'bare form must behave like the CurrPage. form');
        Assert.AreEqual('OBS', Bare, 'log and R1 name');
    end;

    local procedure RunUpdateTrueActionBare(): Text
    var
        P: TestPage "LT TC Bare List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.UpdateTrue.Invoke();
        P.Close();
        exit(LogOf('B:') + '|' + NameOf('R1'));
    end;

    local procedure RunUpdateTrueActionCurr(): Text
    var
        P: TestPage "LT TC Curr List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.UpdateTrue.Invoke();
        P.Close();
        exit(LogOf('C:') + '|' + NameOf('R1'));
    end;

    [Test]
    procedure UpdateTrueAction_BareMatchesCurrPage()
    var
        Bare: Text;
        Curr: Text;
    begin
        Bare := RunUpdateTrueActionBare();
        Curr := RunUpdateTrueActionCurr();
        Assert.AreEqual(Curr, Bare, 'bare form must behave like the CurrPage. form');
        Assert.AreEqual('OBS', Bare, 'log and R1 name');
    end;

    local procedure RunUpdateDefaultActionBare(): Text
    var
        P: TestPage "LT TC Bare List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.UpdateDefault.Invoke();
        P.Close();
        exit(LogOf('B:') + '|' + NameOf('R1'));
    end;

    local procedure RunUpdateDefaultActionCurr(): Text
    var
        P: TestPage "LT TC Curr List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.UpdateDefault.Invoke();
        P.Close();
        exit(LogOf('C:') + '|' + NameOf('R1'));
    end;

    [Test]
    procedure UpdateDefaultAction_BareMatchesCurrPage()
    var
        Bare: Text;
        Curr: Text;
    begin
        Bare := RunUpdateDefaultActionBare();
        Curr := RunUpdateDefaultActionCurr();
        Assert.AreEqual(Curr, Bare, 'bare form must behave like the CurrPage. form');
        Assert.AreEqual('OBS', Bare, 'log and R1 name');
    end;

    local procedure RunSaveRecordActionBare(): Text
    var
        P: TestPage "LT TC Bare List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.SaveIt.Invoke();
        P.Close();
        exit(LogOf('B:') + '|' + NameOf('R1'));
    end;

    local procedure RunSaveRecordActionCurr(): Text
    var
        P: TestPage "LT TC Curr List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.SaveIt.Invoke();
        P.Close();
        exit(LogOf('C:') + '|' + NameOf('R1'));
    end;

    [Test]
    procedure SaveRecordAction_BareMatchesCurrPage()
    var
        Bare: Text;
        Curr: Text;
    begin
        Bare := RunSaveRecordActionBare();
        Curr := RunSaveRecordActionCurr();
        Assert.AreEqual(Curr, Bare, 'bare form must behave like the CurrPage. form');
        Assert.AreEqual('OBS', Bare, 'log and R1 name');
    end;

    local procedure RunSetSelectionFilterActionBare(): Text
    var
        P: TestPage "LT TC Bare List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.SelFilter.Invoke();
        P.Close();
        exit(LogOf('B:') + '|' + NameOf('R1'));
    end;

    local procedure RunSetSelectionFilterActionCurr(): Text
    var
        P: TestPage "LT TC Curr List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.SelFilter.Invoke();
        P.Close();
        exit(LogOf('C:') + '|' + NameOf('R1'));
    end;

    [Test]
    procedure SetSelectionFilterAction_BareMatchesCurrPage()
    var
        Bare: Text;
        Curr: Text;
    begin
        Bare := RunSetSelectionFilterActionBare();
        Curr := RunSetSelectionFilterActionCurr();
        Assert.AreEqual(Curr, Bare, 'bare form must behave like the CurrPage. form');
        Assert.AreEqual('OBS', Bare, 'log and R1 name');
    end;

    local procedure RunCloseActionBare(): Text
    var
        P: TestPage "LT TC Bare List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.CloseIt.Invoke();
        exit(LogOf('B:') + '|' + NameOf('R1'));
    end;

    local procedure RunCloseActionCurr(): Text
    var
        P: TestPage "LT TC Curr List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.CloseIt.Invoke();
        exit(LogOf('C:') + '|' + NameOf('R1'));
    end;

    [Test]
    procedure CloseAction_BareMatchesCurrPage()
    var
        Bare: Text;
        Curr: Text;
    begin
        Bare := RunCloseActionBare();
        Curr := RunCloseActionCurr();
        Assert.AreEqual(Curr, Bare, 'bare form must behave like the CurrPage. form');
        Assert.AreEqual('OBS', Bare, 'log and R1 name');
    end;

    local procedure RunReadEditableAndCaptionBare(): Text
    var
        P: TestPage "LT TC Bare List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.ReadProps.Invoke();
        P.Close();
        exit(LogOf('B:') + '|' + NameOf('R1'));
    end;

    local procedure RunReadEditableAndCaptionCurr(): Text
    var
        P: TestPage "LT TC Curr List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.ReadProps.Invoke();
        P.Close();
        exit(LogOf('C:') + '|' + NameOf('R1'));
    end;

    [Test]
    procedure ReadEditableAndCaption_BareMatchesCurrPage()
    var
        Bare: Text;
        Curr: Text;
    begin
        Bare := RunReadEditableAndCaptionBare();
        Curr := RunReadEditableAndCaptionCurr();
        Assert.AreEqual(Curr, Bare, 'bare form must behave like the CurrPage. form');
        Assert.AreEqual('OBS', Bare, 'log and R1 name');
    end;

    local procedure RunSetEditableFalseBare(): Text
    var
        P: TestPage "LT TC Bare List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.SetEditableFalse.Invoke();
        P.Close();
        exit(LogOf('B:') + '|' + NameOf('R1'));
    end;

    local procedure RunSetEditableFalseCurr(): Text
    var
        P: TestPage "LT TC Curr List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.SetEditableFalse.Invoke();
        P.Close();
        exit(LogOf('C:') + '|' + NameOf('R1'));
    end;

    [Test]
    procedure SetEditableFalse_BareMatchesCurrPage()
    var
        Bare: Text;
        Curr: Text;
    begin
        Bare := RunSetEditableFalseBare();
        Curr := RunSetEditableFalseCurr();
        Assert.AreEqual(Curr, Bare, 'bare form must behave like the CurrPage. form');
        Assert.AreEqual('OBS', Bare, 'log and R1 name');
    end;

    [Test]
    [HandlerFunctions('BareListHandler')]
    procedure ActivateAction_Bare()
    var
        P: TestPage "LT TC Bare List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.ActivateIt.Invoke();
        P.Close();
        Assert.AreEqual('OBSB', LogOf('B:'), 'bare Activate log');
    end;

    [Test]
    [HandlerFunctions('CurrListHandler')]
    procedure ActivateAction_Curr()
    var
        P: TestPage "LT TC Curr List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        P.ActivateIt.Invoke();
        P.Close();
        Assert.AreEqual('OBSC', LogOf('C:'), 'CurrPage.Activate log');
    end;

    [PageHandler]
    procedure BareListHandler(var P: TestPage "LT TC Bare List")
    begin
    end;

    [PageHandler]
    procedure CurrListHandler(var P: TestPage "LT TC Curr List")
    begin
    end;
}
