// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-page-overview
// Scope: in-scope
// Fixtures used: TBA Trace (60332), TBA Prompt Declared (60333), TBA Prompt Bare (60334),
//                TBA Navigate (60335), TBA Confirm (60336), TBA Std Dialog (60337), Assert (60021)
//
// TestPageModalQueryClose_Tests.al (codeunit 60276 "MQC Tests") pins two things about a modal
// the platform closed on a [ModalPageHandler]'s behalf: that a PageType = Worksheet modal has NO
// built-in Cancel, and that a handler which invokes nothing leaves such a modal reporting OK.
// Both are true and both are about ONE page type. This file measures the same two questions
// across the DIALOG page types, because neither answer generalises:
//
//   * which built-in OK()/Cancel() a page has is a property of the chrome its builder puts on
//     the form, and the dialog types do not agree with each other -- a PromptDialog has a
//     Cancel and no OK once it declares one, a NavigatePage has an OK and no Cancel, a
//     ConfirmationDialog has neither;
//   * what RunModal() reports when the handler invokes NOTHING is a separate fact again: a
//     ConfirmationDialog reports Cancel while refusing Cancel() as a built-in, and a
//     NavigatePage reports OK while refusing it.
//
// Every arm therefore carries its own answer rather than being derived from a neighbour, and
// the refusal arms assert the platform's exact text so that "not found" cannot be confused with
// some other failure on the way to the page.
codeunit 60338 "TBA Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        BuiltInOkNotFoundErr: Label 'The built-in action = OK is not found on the page';
        BuiltInCancelNotFoundErr: Label 'The built-in action = Cancel is not found on the page';

    local procedure Initialize()
    var
        Trace: Record "TBA Trace";
    begin
        Trace.DeleteAll();
    end;

    // (a) A PromptDialog HAS a plain Cancel, and it closes the page reporting Cancel -- even
    // though this page declares its own systemaction(Cancel) with a caption of its own.
    [Test]
    [HandlerFunctions('PromptDeclaredCancelHandler')]
    procedure PromptDialogDeclaringCancel_CancelInvoke_ReportsCancel()
    var
        Trace: Record "TBA Trace";
        Modal: Page "TBA Prompt Declared";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual(Format(Action::Cancel), Format(Result),
            'Cancel().Invoke() on a PromptDialog must close it reporting Cancel');
        Assert.AreEqual('QUERYCLOSE:Cancel;', Trace.Events(),
            'OnQueryClosePage must see the cancelling CloseAction');
    end;

    // (b) ...and it has one whether or not the page declares any system action at all, so the
    // Cancel does not come from the declaration. This page has no actions area.
    [Test]
    [HandlerFunctions('PromptBareCancelHandler')]
    procedure PromptDialogDeclaringNothing_CancelInvoke_ReportsCancel()
    var
        Trace: Record "TBA Trace";
        Modal: Page "TBA Prompt Bare";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual(Format(Action::Cancel), Format(Result),
            'a PromptDialog that declares no system actions must still offer a built-in Cancel');
        Assert.AreEqual('QUERYCLOSE:Cancel;', Trace.Events(),
            'OnQueryClosePage must see the cancelling CloseAction');
    end;

    // (c) The OK half is NOT symmetric with (a): declaring systemaction(OK) REPLACES the
    // built-in OK rather than adding one, so OK() has nothing to resolve to.
    [Test]
    [HandlerFunctions('PromptDeclaredOkHandler')]
    procedure PromptDialogDeclaringOk_HasNoBuiltInOkAction()
    var
        Modal: Page "TBA Prompt Declared";
    begin
        Initialize();

        asserterror Modal.RunModal();

        Assert.ExpectedError(BuiltInOkNotFoundErr);
    end;

    // (d) The other side of (c), so it is a statement about the DECLARATION and not about
    // PromptDialog: undeclared, the same OK() resolves and closes the page reporting OK.
    [Test]
    [HandlerFunctions('PromptBareOkHandler')]
    procedure PromptDialogDeclaringNothing_OkInvoke_ReportsOk()
    var
        Trace: Record "TBA Trace";
        Modal: Page "TBA Prompt Bare";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual(Format(Action::OK), Format(Result),
            'a PromptDialog that declares no systemaction(OK) must offer the built-in OK');
        Assert.AreEqual('QUERYCLOSE:OK;', Trace.Events(),
            'OnQueryClosePage must see the confirming CloseAction');
    end;

    // (e) A NavigatePage has no plain Cancel, the way a Worksheet has none (MQC Tests). Its
    // chrome is Back/Next/Finish, not OK/Cancel.
    [Test]
    [HandlerFunctions('NavigateCancelHandler')]
    procedure NavigatePage_HasNoBuiltInCancelAction()
    var
        Modal: Page "TBA Navigate";
    begin
        Initialize();

        asserterror Modal.RunModal();

        Assert.ExpectedError(BuiltInCancelNotFoundErr);
    end;

    // (f) ...but it does have a plain OK, so (e) is not "a NavigatePage has no built-ins".
    [Test]
    [HandlerFunctions('NavigateOkHandler')]
    procedure NavigatePage_OkInvoke_ReportsOk()
    var
        Trace: Record "TBA Trace";
        Modal: Page "TBA Navigate";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual(Format(Action::OK), Format(Result),
            'OK().Invoke() on a NavigatePage must close it reporting OK');
        Assert.AreEqual('QUERYCLOSE:OK;', Trace.Events(),
            'OnQueryClosePage must see the confirming CloseAction');
    end;

    // (g) A ConfirmationDialog has NEITHER built-in: its chrome is Yes/No.
    [Test]
    [HandlerFunctions('ConfirmCancelHandler')]
    procedure ConfirmationDialog_HasNoBuiltInCancelAction()
    var
        Modal: Page "TBA Confirm";
    begin
        Initialize();

        asserterror Modal.RunModal();

        Assert.ExpectedError(BuiltInCancelNotFoundErr);
    end;

    // (h) The half of (g) that a page type alone does not predict -- every other non-lookup
    // page in this file offers OK.
    [Test]
    [HandlerFunctions('ConfirmOkHandler')]
    procedure ConfirmationDialog_HasNoBuiltInOkAction()
    var
        Modal: Page "TBA Confirm";
    begin
        Initialize();

        asserterror Modal.RunModal();

        Assert.ExpectedError(BuiltInOkNotFoundErr);
    end;

    // (i) A handler that invokes nothing leaves a StandardDialog reporting Cancel -- NOT the OK
    // that MQC Tests measures for a Worksheet. The substituted result is per page type.
    [Test]
    [HandlerFunctions('StdDialogNoopHandler')]
    procedure StandardDialog_HandlerInvokesNothing_ReportsCancel()
    var
        Trace: Record "TBA Trace";
        Modal: Page "TBA Std Dialog";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual(Format(Action::Cancel), Format(Result),
            'an unattended StandardDialog must report Cancel');
        Assert.AreEqual('QUERYCLOSE:Cancel;', Trace.Events(),
            'OnQueryClosePage must see the same cancelling CloseAction RunModal reports');
    end;

    // (j) Same for a PromptDialog.
    [Test]
    [HandlerFunctions('PromptDeclaredNoopHandler')]
    procedure PromptDialog_HandlerInvokesNothing_ReportsCancel()
    var
        Trace: Record "TBA Trace";
        Modal: Page "TBA Prompt Declared";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual(Format(Action::Cancel), Format(Result),
            'an unattended PromptDialog must report Cancel');
        Assert.AreEqual('QUERYCLOSE:Cancel;', Trace.Events(),
            'OnQueryClosePage must see the same cancelling CloseAction RunModal reports');
    end;

    // (k) And for a ConfirmationDialog, which reports Cancel although (g) shows it has no
    // built-in Cancel to invoke -- the two facts are independent.
    [Test]
    [HandlerFunctions('ConfirmNoopHandler')]
    procedure ConfirmationDialog_HandlerInvokesNothing_ReportsCancel()
    var
        Trace: Record "TBA Trace";
        Modal: Page "TBA Confirm";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual(Format(Action::Cancel), Format(Result),
            'an unattended ConfirmationDialog must report Cancel');
        Assert.AreEqual('QUERYCLOSE:Cancel;', Trace.Events(),
            'OnQueryClosePage must see the same cancelling CloseAction RunModal reports');
    end;

    // (l) The negative control for (i)-(k): a NavigatePage reports OK unattended, so "Cancel"
    // is not simply what every dialog reports.
    [Test]
    [HandlerFunctions('NavigateNoopHandler')]
    procedure NavigatePage_HandlerInvokesNothing_ReportsOk()
    var
        Trace: Record "TBA Trace";
        Modal: Page "TBA Navigate";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual(Format(Action::OK), Format(Result),
            'an unattended NavigatePage must report OK');
        Assert.AreEqual('QUERYCLOSE:OK;', Trace.Events(),
            'OnQueryClosePage must see the same confirming CloseAction RunModal reports');
    end;

    // (m) A declared systemaction still runs its own OnAction when invoked by name, and leaving
    // the dialog after it is an unattended close: the page reports Cancel, not OK.
    [Test]
    [HandlerFunctions('PromptDeclaredGenerateHandler')]
    procedure PromptDialog_GenerateInvoke_FiresOnActionAndReportsCancel()
    var
        Trace: Record "TBA Trace";
        Modal: Page "TBA Prompt Declared";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual('GENERATE;QUERYCLOSE:Cancel;', Trace.Events(),
            'systemaction(Generate) must run its OnAction, and the unattended close follows it');
        Assert.AreEqual(Format(Action::Cancel), Format(Result),
            'a PromptDialog left after Generate must report Cancel');
    end;

    [ModalPageHandler]
    procedure PromptDeclaredCancelHandler(var Modal: TestPage "TBA Prompt Declared")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure PromptDeclaredOkHandler(var Modal: TestPage "TBA Prompt Declared")
    begin
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PromptDeclaredNoopHandler(var Modal: TestPage "TBA Prompt Declared")
    begin
    end;

    [ModalPageHandler]
    procedure PromptDeclaredGenerateHandler(var Modal: TestPage "TBA Prompt Declared")
    begin
        Modal.Generate.Invoke();
    end;

    [ModalPageHandler]
    procedure PromptBareCancelHandler(var Modal: TestPage "TBA Prompt Bare")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure PromptBareOkHandler(var Modal: TestPage "TBA Prompt Bare")
    begin
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NavigateCancelHandler(var Modal: TestPage "TBA Navigate")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure NavigateOkHandler(var Modal: TestPage "TBA Navigate")
    begin
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NavigateNoopHandler(var Modal: TestPage "TBA Navigate")
    begin
    end;

    [ModalPageHandler]
    procedure ConfirmCancelHandler(var Modal: TestPage "TBA Confirm")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure ConfirmOkHandler(var Modal: TestPage "TBA Confirm")
    begin
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ConfirmNoopHandler(var Modal: TestPage "TBA Confirm")
    begin
    end;

    [ModalPageHandler]
    procedure StdDialogNoopHandler(var Modal: TestPage "TBA Std Dialog")
    begin
    end;
}
