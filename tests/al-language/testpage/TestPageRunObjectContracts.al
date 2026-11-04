// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021),
//                its own log codeunit 68193 "Probe RunObject Log";
//                self-contained pages 68180..68189 and codeunits 68190..68192
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins what a TestPage sees when an action with RunObject opens its target: the error when nobody
// answers a dialog (text, code and that the dialog opens first), how a handler that leaves the page open
// is closed (OK for a card, Cancel for a dialog), which page types a PageHandler or a ModalPageHandler
// answers, whether the host row is read again afterwards (it is after a write and after a codeunit, not
// after a page that wrote nothing), targets with no handler, an action that declares RunObject and OnAction,
// and what an actionref answers.
// BC versions: 27.5

codeunit 68193 "Probe RunObject Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

page 68180 "Probe RO Card"
{
    PageType = Card; SourceTable = "ALT Universal"; ApplicationArea = All;
    layout { area(Content) { field("Entry No."; Rec."Entry No.") { ApplicationArea = All; } field("Text Field"; Rec."Text Field") { ApplicationArea = All; } } }
    var L: Codeunit "Probe RunObject Log";
    trigger OnInit() begin L.Add('card.OnInit'); end;
    trigger OnOpenPage() begin L.Add('card.OnOpenPage'); end;
    trigger OnAfterGetCurrRecord() begin L.Add('card.AGCR(' + Format(Rec."Entry No.") + ')'); end;
    trigger OnQueryClosePage(CloseAction: Action): Boolean begin L.Add('card.OnQueryClosePage(' + Format(CloseAction) + ')'); exit(true); end;
    trigger OnClosePage() begin L.Add('card.OnClosePage'); end;
}

page 68181 "Probe RO Card Plain"
{
    PageType = Card; SourceTable = "ALT Universal"; ApplicationArea = All;
    layout { area(Content) { field("Entry No."; Rec."Entry No.") { ApplicationArea = All; } } }
    var L: Codeunit "Probe RunObject Log";
    trigger OnOpenPage() begin L.Add('plain.OnOpenPage'); end;
}

page 68182 "Probe RO Dialog"
{
    PageType = StandardDialog; ApplicationArea = All;
    var L: Codeunit "Probe RunObject Log";
    trigger OnOpenPage() begin L.Add('dialog.OnOpenPage'); end;
    trigger OnQueryClosePage(CloseAction: Action): Boolean begin L.Add('dialog.OnQueryClosePage(' + Format(CloseAction) + ')'); exit(true); end;
}

page 68183 "Probe RO List"
{
    PageType = List; SourceTable = "ALT Universal"; ApplicationArea = All;
    layout { area(Content) { repeater(R) { field("Entry No."; Rec."Entry No.") { ApplicationArea = All; } } } }
    var L: Codeunit "Probe RunObject Log";
    trigger OnOpenPage() begin L.Add('list.OnOpenPage'); end;
}

page 68184 "Probe RO Document"
{
    PageType = Document; SourceTable = "ALT Universal"; ApplicationArea = All;
    layout { area(Content) { field("Entry No."; Rec."Entry No.") { ApplicationArea = All; } } }
}

page 68185 "Probe RO Worksheet"
{
    PageType = Worksheet; SourceTable = "ALT Universal"; ApplicationArea = All;
    layout { area(Content) { repeater(R) { field("Entry No."; Rec."Entry No.") { ApplicationArea = All; } } } }
}

page 68186 "Probe RO Navigate"
{
    PageType = NavigatePage; ApplicationArea = All;
}

page 68187 "Probe RO ListPlus"
{
    PageType = ListPlus; SourceTable = "ALT Universal"; ApplicationArea = All;
    layout { area(Content) { repeater(R) { field("Entry No."; Rec."Entry No.") { ApplicationArea = All; } } } }
}

codeunit 68190 "Probe RO Cu"
{
    TableNo = "ALT Universal";
    trigger OnRun()
    var L: Codeunit "Probe RunObject Log";
    begin
        L.Add('cu.OnRun(rec=' + Format(Rec."Entry No.") + ')');
        Rec."Text Field" := 'cu-set';
        Rec.Modify();
    end;
}

codeunit 68191 "Probe RO Cu2"
{
    TableNo = "ALT Universal";
    trigger OnRun()
    var L: Codeunit "Probe RunObject Log";
    begin
        L.Add('cu2.OnRun(rec=' + Format(Rec."Entry No.") + ')');
    end;
}

page 68189 "Probe RO Host"
{
    PageType = Card; SourceTable = "ALT Universal"; ApplicationArea = All;
    layout { area(Content) { field("Entry No."; Rec."Entry No.") { ApplicationArea = All; } field("Text Field"; Rec."Text Field") { ApplicationArea = All; } } }
    actions
    {
        area(Processing)
        {
            action(ActCard) { ApplicationArea = All; RunObject = page "Probe RO Card"; RunPageOnRec = true; }
            action(ActCardPlain) { ApplicationArea = All; RunObject = page "Probe RO Card Plain"; RunPageOnRec = true; }
            action(ActDialog) { ApplicationArea = All; RunObject = page "Probe RO Dialog"; }
            action(ActList) { ApplicationArea = All; RunObject = page "Probe RO List"; }
            action(ActDoc) { ApplicationArea = All; RunObject = page "Probe RO Document"; }
            action(ActWs) { ApplicationArea = All; RunObject = page "Probe RO Worksheet"; }
            action(ActNav) { ApplicationArea = All; RunObject = page "Probe RO Navigate"; }
            action(ActLP) { ApplicationArea = All; RunObject = page "Probe RO ListPlus"; }
            action(ActCu) { ApplicationArea = All; RunObject = codeunit "Probe RO Cu"; }
            action(ActCu2) { ApplicationArea = All; RunObject = codeunit "Probe RO Cu2"; }
            action(ActBoth)
            {
                ApplicationArea = All; RunObject = page "Probe RO Card Plain";
                trigger OnAction() begin L.Add('ActBoth.OnAction'); end;
            }
        }
        area(Promoted) { actionref(RefCard; ActCard) { } }
    }
    var L: Codeunit "Probe RunObject Log";
    trigger OnAfterGetRecord() begin L.Add('host.AGR(' + Format(Rec."Entry No.") + ')'); end;
    trigger OnAfterGetCurrRecord() begin L.Add('host.AGCR(' + Format(Rec."Entry No.") + ')'); end;
}

codeunit 68192 "Probe RunObject Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        PageLog: Codeunit "Probe RunObject Log";

    local procedure Initialize()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal."Text Field" := 'one';
        ALTUniversal.Insert();
        ALTUniversal."Entry No." := 2;
        ALTUniversal."Text Field" := 'two';
        ALTUniversal.Insert();
        Commit();
        PageLog.Take();
    end;

    [Test]
    procedure RunObject_DialogTarget_NoHandler_FullTextAndCode_DialogOpensFirst()
    var
        Host: TestPage "Probe RO Host";
    begin
        Initialize();
        Host.OpenEdit();
        PageLog.Take();

        asserterror Host.ActDialog.Invoke();

        Assert.AreEqual('TestPages that are invoked from a RunObject action must have a handler. Page No. = 68182', GetLastErrorText(), 'text');
        Assert.AreEqual('TestPageInvokedWithoutHandler', GetLastErrorCode(), 'code');
        Assert.AreEqual('dialog.OnOpenPage;', PageLog.Take(), 'the dialog was opened before the refusal');
        Host.Close();
    end;

    [Test]
    [HandlerFunctions('LeaveCardOpen')]
    procedure RunObject_CardHandlerLeavesThePageOpen_PlatformClosesWithOk()
    var
        Host: TestPage "Probe RO Host";
    begin
        Initialize();
        Host.OpenEdit();
        Host.GoToKey(1);
        PageLog.Take();

        Host.ActCard.Invoke();

        Assert.AreEqual('card.OnInit;card.OnOpenPage;card.AGCR(1);handler(card);card.OnQueryClosePage(OK);card.OnClosePage;', PageLog.Take(), 'the host row is not read again: nothing was written');
        Host.Close();
    end;

    [PageHandler]
    procedure LeaveCardOpen(var Card: TestPage "Probe RO Card")
    begin
        PageLog.Add('handler(card)');
    end;

    [Test]
    [HandlerFunctions('LeaveDialogOpen')]
    procedure RunObject_DialogHandlerLeavesThePageOpen_PlatformClosesWithCancel()
    var
        Host: TestPage "Probe RO Host";
    begin
        Initialize();
        Host.OpenEdit();
        PageLog.Take();

        Host.ActDialog.Invoke();

        Assert.AreEqual('dialog.OnOpenPage;handler(dialog);dialog.OnQueryClosePage(Cancel);', PageLog.Take(), 'order and close action');
        Host.Close();
    end;

    [ModalPageHandler]
    procedure LeaveDialogOpen(var Dialog: TestPage "Probe RO Dialog")
    begin
        PageLog.Add('handler(dialog)');
    end;

    [Test]
    [HandlerFunctions('WriteThroughCard')]
    procedure RunObject_PageTargetThatWrote_HostIsReadAgain()
    var
        Host: TestPage "Probe RO Host";
    begin
        Initialize();
        Host.OpenEdit();
        Host.GoToKey(1);
        PageLog.Take();

        Host.ActCard.Invoke();

        Assert.AreEqual('card.OnInit;card.OnOpenPage;card.AGCR(1);card.OnQueryClosePage(OK);card.OnClosePage;host.AGR(1);host.AGCR(1);', PageLog.Take(), 'the host re-reads after the target closed');
        Assert.AreEqual('written', Host."Text Field".Value(), 'and shows the new value');
        Host.Close();
    end;

    [PageHandler]
    procedure WriteThroughCard(var Card: TestPage "Probe RO Card")
    begin
        Card."Text Field".SetValue('written');
    end;

    [Test]
    procedure RunObject_CodeunitTarget_HostIsReadAgain_EvenWhenItWroteNothing()
    var
        Host: TestPage "Probe RO Host";
    begin
        Initialize();
        Host.OpenEdit();
        Host.GoToKey(1);
        PageLog.Take();

        Host.ActCu2.Invoke();
        Assert.AreEqual('cu2.OnRun(rec=1);host.AGR(1);host.AGCR(1);', PageLog.Take(), 'a codeunit that wrote nothing');

        Host.ActCu.Invoke();
        Assert.AreEqual('cu.OnRun(rec=1);host.AGR(1);host.AGCR(1);', PageLog.Take(), 'a codeunit that modified the row');
        Assert.AreEqual('cu-set', Host."Text Field".Value(), 'the host shows the value the codeunit wrote');
        Host.Close();
    end;

    [Test]
    [HandlerFunctions('ListHandler,DocumentHandler,WorksheetHandler,ListPlusHandler,NavigateModalHandler')]
    procedure RunObject_PageTypes_AnsweredByTheirHandlers()
    // CLAIM: List, Document, Worksheet and ListPlus targets are answered by a PageHandler; a NavigatePage by a ModalPageHandler.
    var
        Host: TestPage "Probe RO Host";
    begin
        Initialize();
        Host.OpenEdit();
        PageLog.Take();

        Host.ActList.Invoke();
        Host.ActDoc.Invoke();
        Host.ActWs.Invoke();
        Host.ActLP.Invoke();
        Host.ActNav.Invoke();

        Assert.AreEqual('list.OnOpenPage;handler(list);handler(document);handler(worksheet);handler(listplus);handler(navigate);', PageLog.Take(), 'handlers in order');
        Host.Close();
    end;

    [PageHandler]
    procedure ListHandler(var Target: TestPage "Probe RO List")
    begin
        PageLog.Add('handler(list)');
    end;

    [PageHandler]
    procedure DocumentHandler(var Target: TestPage "Probe RO Document")
    begin
        PageLog.Add('handler(document)');
    end;

    [PageHandler]
    procedure WorksheetHandler(var Target: TestPage "Probe RO Worksheet")
    begin
        PageLog.Add('handler(worksheet)');
    end;

    [PageHandler]
    procedure ListPlusHandler(var Target: TestPage "Probe RO ListPlus")
    begin
        PageLog.Add('handler(listplus)');
    end;

    [ModalPageHandler]
    procedure NavigateModalHandler(var Target: TestPage "Probe RO Navigate")
    begin
        PageLog.Add('handler(navigate)');
    end;

    [Test]
    procedure RunObject_NavigatePageTarget_WithoutAModalHandler_IsRefused()
    var
        Host: TestPage "Probe RO Host";
    begin
        Initialize();
        Host.OpenEdit();

        asserterror Host.ActNav.Invoke();

        Assert.AreEqual('TestPages that are invoked from a RunObject action must have a handler. Page No. = 68186', GetLastErrorText(), 'a NavigatePage is refused like a dialog; a PageHandler would not be executed');
        Assert.AreEqual('TestPageInvokedWithoutHandler', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure RunObject_CardAndListTargets_NoHandler_OpenAndAreDroppedWithoutCloseTriggers()
    var
        Host: TestPage "Probe RO Host";
    begin
        Initialize();
        Host.OpenEdit();
        Host.GoToKey(1);
        PageLog.Take();

        Host.ActCard.Invoke();
        Assert.AreEqual('card.OnInit;card.OnOpenPage;', PageLog.Take(), 'a card that declares OnQueryClosePage and OnClosePage runs neither');

        Host.ActList.Invoke();
        Assert.AreEqual('list.OnOpenPage;', PageLog.Take(), 'a list');
        Host.Close();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure RunObject_ActionWithBothRunObjectAndOnAction_OnlyTheTargetRuns()
    var
        Host: TestPage "Probe RO Host";
    begin
        Initialize();
        Host.OpenEdit();
        Host.GoToKey(1);
        PageLog.Take();

        Host.ActBoth.Invoke();

        Assert.AreEqual('plain.OnOpenPage;handler(plain);', PageLog.Take(), 'OnAction does not run');
        Host.Close();
    end;

    [PageHandler]
    procedure PlainHandler(var Target: TestPage "Probe RO Card Plain")
    begin
        PageLog.Add('handler(plain)');
    end;

    [Test]
    [HandlerFunctions('LeaveCardOpen')]
    procedure RunObject_Actionref_InvokeRunsTheAction_VisibleAndEnabledAnswerYes()
    var
        Host: TestPage "Probe RO Host";
    begin
        Initialize();
        Host.OpenEdit();
        Host.GoToKey(1);
        PageLog.Take();

        Host.RefCard.Invoke();

        Assert.IsTrue(PageLog.Take().Contains('handler(card)'), 'the referenced action ran');
        Assert.IsTrue(Host.RefCard.Visible(), 'Visible');
        Assert.IsTrue(Host.RefCard.Enabled(), 'Enabled');
        Host.Close();
    end;
}
