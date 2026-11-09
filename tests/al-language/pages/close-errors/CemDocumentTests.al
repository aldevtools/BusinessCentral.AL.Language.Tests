// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); the CEM fixtures of CemFixtures.al (objects 99500..99512, codeunit 99512 sets the scene)
// Area: errors and unhandled UI when a page closes, matrix of WHERE the error is raised (OnQueryClosePage, OnClosePage, the page's
//   OnModifyRecord or OnInsertRecord while the page saves on close, the table's OnModify or OnInsert, a handler, a Confirm nobody handles)
//   crossed with HOW the page closes (TestPage.Close, OK, Cancel, Close() in a handler, a handler that returns, end of a test) and the
//   page shape (card, list, document with parts, lookup list opened from a TableRelation). Each test states its cell in the CLAIM line
//   and asserts: how the call ended (the RunModal result or the error text and code), the triggers that ran in order, the rows afterwards.
//   Conventions of the observation: 'returned' is written only when the call came back; it holds the result, the trigger log so far and
//   the rows (inside the failed statement the rows are the page's writes). 'end|text' is CEM_NO_ERROR when the call came back, else the
//   error. 'log' and 'rows' are read after the statement; an error rolls the rows back to the last Commit().
// local object: the matrix needs its own pages with switchable failing triggers
// BC versions: 27, 28, 29
// File: RunModal of a document page with a visible part, factbox parts and hidden parts, handler mode x error source (al-runner 7473).
codeunit 99523 "CEM Document Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "CEM Cfg";
        Help: Codeunit "CEM Help";
        Runner: Codeunit "CEM Runner";

    // CLAIM: DocumentStaticRunModal: handler returns without closing, no error anywhere.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'doc', 0);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler OK.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'doc', 1);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler Cancel.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerCancel_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'doc', 2);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler edits Name then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerEditReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'doc', 4);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler edits Name then OK, no error anywhere.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerEditOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'doc', 5);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler raises Error, no error anywhere.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerError_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'doc', 7);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets the Name the table refuses then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerTableRefusesReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'doc', 8);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets the Name the table refuses then OK, no error anywhere.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerTableRefusesOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'doc', 9);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets a line Qty the line table refuses then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerLineRefusesReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'doc', 11);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets a line Qty the line table refuses then OK, no error anywhere.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerLineRefusesOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'doc', 12);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler returns without closing, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'doc', 0);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler OK.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'doc', 1);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler Cancel.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerCancel_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'doc', 2);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler edits Name then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerEditReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'doc', 4);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler edits Name then OK, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerEditOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'doc', 5);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler raises Error, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerError_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'doc', 7);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets the Name the table refuses then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerTableRefusesReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'doc', 8);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets the Name the table refuses then OK, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerTableRefusesOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'doc', 9);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets a line Qty the line table refuses then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerLineRefusesReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'doc', 11);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets a line Qty the line table refuses then OK, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerLineRefusesOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'doc', 12);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler returns without closing, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'doc', 0);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler OK.Invoke, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'doc', 1);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler Cancel.Invoke, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerCancel_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'doc', 2);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler edits Name then returns, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerEditReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'doc', 4);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler edits Name then OK, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerEditOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'doc', 5);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler raises Error, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerError_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'doc', 7);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets the Name the table refuses then returns, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerTableRefusesReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'doc', 8);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets the Name the table refuses then OK, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerTableRefusesOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'doc', 9);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets a line Qty the line table refuses then returns, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerLineRefusesReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'doc', 11);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets a line Qty the line table refuses then OK, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerLineRefusesOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'doc', 12);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler edits Name then returns, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerEditReturns_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'doc', 4);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler edits Name then OK, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerEditOk_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'doc', 5);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: DocumentStaticRunModal: handler sets the Name the table refuses then returns, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemDocModal')]
    procedure DocumentStaticRunModal_HandlerTableRefusesReturns_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'doc', 8);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    [ModalPageHandler]
    procedure CemDocModal(var P: TestPage "CEM Doc")
    begin
        case Cfg.Mode() of
            0:
                ;
            1:
                begin
                    P.OK().Invoke();
                end;
            2:
                begin
                    P.Cancel().Invoke();
                end;
            3:
                begin
                    P.Close();
                end;
            4:
                begin
                    P.Name.SetValue('EDIT');
                end;
            5:
                begin
                    P.Name.SetValue('EDIT');
                    P.OK().Invoke();
                end;
            7:
                begin
                    Error('CEM handler error');
                end;
            8:
                begin
                    P.Name.SetValue('FAILMOD');
                end;
            9:
                begin
                    P.Name.SetValue('FAILMOD');
                    P.OK().Invoke();
                end;
            11:
                begin
                    P.Lines.First();
                    P.Lines.Qty.SetValue(-1);
                end;
            12:
                begin
                    P.Lines.First();
                    P.Lines.Qty.SetValue(-1);
                    P.OK().Invoke();
                end;
        end;
    end;
}
