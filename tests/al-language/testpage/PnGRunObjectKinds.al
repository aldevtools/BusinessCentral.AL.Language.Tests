// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG RunObj Host (70162), run-object targets LT PnG Card (70134), LT PnG List (70135), LT PnG Worksheet (70154), LT PnG ListPlus (70155), LT PnG Navigate (70156), LT PnG Confirm (70157), LT PnG Prompt (70158), LT PnG Dlg (70159), LT PnG No Type (70160), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 87 (RunObject): which kind of handler answers an action with RunObject, by the PageType of the target
// Facts: for every PageType which kind of handler answers an action with RunObject; the test declares only the handler that ran (a declared handler that does not run fails the test as 'not executed')
// BC versions: 29 (27 and 28 by CI)

codeunit 70187 "LT PnG RunObject Kinds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Open(var Host: TestPage "LT PnG RunObj Host")
    var
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
    begin
        Item.DeleteAll();
        Item."No." := 'RO1';
        Item.Name := 'Run object';
        Item.Qty := 5;
        Item.Insert();
        Log.Reset();
        Host.OpenView();
    end;

    [Test]
    [HandlerFunctions('PhCard')]
    procedure RunCardPageType()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Open(Host);
        Host.RunCard.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'Card.OnInit;Card.OnOpenPage;Card.AGR(RO1,Run object);Card.AGCR(RO1,Run object);PageHandler:Card;Card.OnQueryClosePage;Card.OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhList')]
    procedure RunListPageType()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Open(Host);
        Host.RunList.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'List.OnInit;List.OnOpenPage;List.AGR(RO1,Run object);List.AGR(RO1,Run object);List.AGCR(RO1,);PageHandler:List');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhWorksheet')]
    procedure RunWorksheetPageType()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Open(Host);
        Host.RunWorksheet.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'PageHandler:Worksheet');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhListPlus')]
    procedure RunListPlusPageType()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Open(Host);
        Host.RunListPlus.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'PageHandler:ListPlus');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhConfirm')]
    procedure RunConfirmationDialogPageType()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Open(Host);
        Host.RunConfirm.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'PageHandler:Confirm');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhPrompt')]
    procedure RunPromptDialogPageType()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Open(Host);
        Host.RunPrompt.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'PageHandler:Prompt');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhNoType')]
    procedure RunUndeclaredPageType()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Open(Host);
        Host.RunNoType.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'PageHandler:NoType');
        Observer.Verify();
    end;

    [PageHandler]
    procedure PhCard(var P: TestPage "LT PnG Card")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('PageHandler:Card');
    end;

    [ModalPageHandler]
    procedure MhCard(var P: TestPage "LT PnG Card")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('ModalHandler:Card');
    end;

    [PageHandler]
    procedure PhList(var P: TestPage "LT PnG List")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('PageHandler:List');
    end;

    [ModalPageHandler]
    procedure MhList(var P: TestPage "LT PnG List")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('ModalHandler:List');
    end;

    [PageHandler]
    procedure PhWorksheet(var P: TestPage "LT PnG Worksheet")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('PageHandler:Worksheet');
    end;

    [ModalPageHandler]
    procedure MhWorksheet(var P: TestPage "LT PnG Worksheet")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('ModalHandler:Worksheet');
    end;

    [PageHandler]
    procedure PhListPlus(var P: TestPage "LT PnG ListPlus")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('PageHandler:ListPlus');
    end;

    [ModalPageHandler]
    procedure MhListPlus(var P: TestPage "LT PnG ListPlus")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('ModalHandler:ListPlus');
    end;

    [PageHandler]
    procedure PhNavigate(var P: TestPage "LT PnG Navigate")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('PageHandler:Navigate');
    end;

    [ModalPageHandler]
    procedure MhNavigate(var P: TestPage "LT PnG Navigate")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('ModalHandler:Navigate');
    end;

    [PageHandler]
    procedure PhConfirm(var P: TestPage "LT PnG Confirm")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('PageHandler:Confirm');
    end;

    [ModalPageHandler]
    procedure MhConfirm(var P: TestPage "LT PnG Confirm")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('ModalHandler:Confirm');
    end;

    [PageHandler]
    procedure PhPrompt(var P: TestPage "LT PnG Prompt")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('PageHandler:Prompt');
    end;

    [ModalPageHandler]
    procedure MhPrompt(var P: TestPage "LT PnG Prompt")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('ModalHandler:Prompt');
    end;

    [PageHandler]
    procedure PhDlg(var P: TestPage "LT PnG Dlg")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('PageHandler:Dlg');
    end;

    [ModalPageHandler]
    procedure MhDlg(var P: TestPage "LT PnG Dlg")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('ModalHandler:Dlg');
    end;

    [PageHandler]
    procedure PhNoType(var P: TestPage "LT PnG No Type")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('PageHandler:NoType');
    end;

    [ModalPageHandler]
    procedure MhNoType(var P: TestPage "LT PnG No Type")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('ModalHandler:NoType');
    end;
}
