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
// File: Page.Run with a PageHandler (card by object id, card from a Page variable, list, wizard), handler mode x error source.
codeunit 99522 "CEM Page Handler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "CEM Cfg";
        Help: Codeunit "CEM Help";
        Runner: Codeunit "CEM Runner";

    // CLAIM: CardStaticRun: handler returns without closing, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler OK.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler Cancel.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerCancel_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 2);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'The built-in action = Cancel is not found on the page.');
        O.Expect('end|code', 'TestActionNotFound');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler Close(), no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerClose_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler raises Error, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerError_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 7);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler edits Name then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerEditReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 4);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler edits Name then OK, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerEditOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler sets the Name the table refuses then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerTableRefusesReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 8);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'M-card FAILMOD; T-mod R1 FAILMOD; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler returns without closing, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-card OK; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler OK.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; Q-card OK; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped:MissingUIHandler');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-card OK; Q-card OK; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card OK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler Cancel.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerCancel_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 2);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'The built-in action = Cancel is not found on the page.');
        O.Expect('end|code', 'TestActionNotFound');
        O.Expect('log', 'Q-card OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler Close(), OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerClose_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'MissingUIHandler');
#endif
        O.Expect('log', 'Q-card OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler raises Error, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerError_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 7);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'Dialog');
#if BC28PLUS
        O.Expect('log', 'Q-card OK; Q-card OK; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card OK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler edits Name then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerEditReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 4);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; M-card EDIT; T-mod R1 EDIT; Q-card OK; | R1=EDIT/ (1 rows) L1=1 L2=2');
#else // BC 27.5 behaves differently here
        O.Expect('returned', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; | R1=EDIT/ (1 rows) L1=1 L2=2');
#endif
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
#if BC28PLUS
        O.Expect('log', 'Q-card OK; M-card EDIT; T-mod R1 EDIT; Q-card OK; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler edits Name then OK, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerEditOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; M-card EDIT; T-mod R1 EDIT; Q-card OK; Q-card OK; | R1=EDIT/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped:MissingUIHandler');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-card OK; M-card EDIT; T-mod R1 EDIT; Q-card OK; Q-card OK; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler sets the Name the table refuses then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerTableRefusesReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 8);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; M-card FAILMOD; T-mod R1 FAILMOD; | R1=start/ (1 rows) L1=1 L2=2');
#else // BC 27.5 behaves differently here
        O.Expect('returned', 'M-card FAILMOD; T-mod R1 FAILMOD; | R1=start/ (1 rows) L1=1 L2=2');
#endif
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
#if BC28PLUS
        O.Expect('log', 'Q-card OK; M-card FAILMOD; T-mod R1 FAILMOD; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-card FAILMOD; T-mod R1 FAILMOD; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler returns without closing, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('close', 'card', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if not BC28PLUS
        O.Expect('returned', 'Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'CEM_NO_ERROR');
#endif
#if BC28PLUS
        O.Expect('end|code', 'TestWrapped');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'Dialog');
#endif
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler OK.Invoke, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('close', 'card', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler Close(), OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerClose_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('close', 'card', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler edits Name then OK, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerEditOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('close', 'card', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
#if BC28PLUS
        O.Expect('log', 'Q-card OK; C-card; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler returns without closing, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerReturns_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'card', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; C-card; C-card confirm=No; Q-card OK; C-card; C-card confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
#else // BC 27.5 behaves differently here
        O.Expect('returned', 'Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
#endif
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
#if BC28PLUS
        O.Expect('log', 'Q-card OK; C-card; C-card confirm=No; Q-card OK; C-card; C-card confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card OK; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler OK.Invoke, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerOk_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'card', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; C-card; C-card confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-card OK; C-card; C-card confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card OK; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler Close(), OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerClose_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'card', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; C-card; C-card confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-card OK; C-card; C-card confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card OK; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler edits Name then OK, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerEditOk_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'card', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; C-card confirm=No; | R1=EDIT/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped');
#endif
#if BC28PLUS
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; C-card confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler edits Name then returns, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerEditReturns_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('modrec', 'card', 4);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'M-card EDIT; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler edits Name then OK, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerEditOk_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('modrec', 'card', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'M-card EDIT; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRun: handler sets the Name the table refuses then returns, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardStaticRun_HandlerTableRefusesReturns_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('modrec', 'card', 8);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'M-card FAILMOD; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler returns without closing, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler OK.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler Close(), no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerClose_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler edits Name then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerEditReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'card', 4);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler returns without closing, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-card OK; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler OK.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; Q-card OK; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped:MissingUIHandler');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-card OK; Q-card OK; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card OK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler Close(), OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerClose_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'MissingUIHandler');
#endif
        O.Expect('log', 'Q-card OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler edits Name then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerEditReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'card', 4);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; M-card EDIT; T-mod R1 EDIT; Q-card OK; | R1=EDIT/ (1 rows) L1=1 L2=2');
#else // BC 27.5 behaves differently here
        O.Expect('returned', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; | R1=EDIT/ (1 rows) L1=1 L2=2');
#endif
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
#if BC28PLUS
        O.Expect('log', 'Q-card OK; M-card EDIT; T-mod R1 EDIT; Q-card OK; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler returns without closing, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('close', 'card', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if not BC28PLUS
        O.Expect('returned', 'Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'CEM_NO_ERROR');
#endif
#if BC28PLUS
        O.Expect('end|code', 'TestWrapped');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'Dialog');
#endif
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler OK.Invoke, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('close', 'card', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler returns without closing, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerReturns_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'card', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; C-card; C-card confirm=No; Q-card OK; C-card; C-card confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
#else // BC 27.5 behaves differently here
        O.Expect('returned', 'Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
#endif
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
#if BC28PLUS
        O.Expect('log', 'Q-card OK; C-card; C-card confirm=No; Q-card OK; C-card; C-card confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card OK; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRun: handler OK.Invoke, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCardRun')]
    procedure CardVariableRun_HandlerOk_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'card', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunCardVariable(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-card OK; C-card; C-card confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-card OK; C-card; C-card confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card OK; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler returns without closing, no error anywhere.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'list', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-list OK; C-list; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler OK.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'list', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-list OK; C-list; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler Close(), no error anywhere.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerClose_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'list', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-list OK; C-list; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler raises Error, no error anywhere.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerError_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'list', 7);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler returns without closing, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'list', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-list OK; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler OK.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'list', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-list OK; Q-list OK; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped:MissingUIHandler');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-list OK; Q-list OK; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-list OK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler Close(), OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerClose_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'list', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-list OK; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'MissingUIHandler');
#endif
        O.Expect('log', 'Q-list OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler raises Error, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerError_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'list', 7);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler returns without closing, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('close', 'list', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-list OK; C-list; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler OK.Invoke, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('close', 'list', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler returns without closing, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerReturns_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'list', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-list OK; C-list; C-list confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
#else // BC 27.5 behaves differently here
        O.Expect('returned', 'Q-list OK; C-list; | R1=start/ (1 rows) L1=1 L2=2');
#endif
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
#if BC28PLUS
        O.Expect('log', 'Q-list OK; C-list; C-list confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-list OK; C-list; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRun: handler OK.Invoke, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemListRun')]
    procedure ListStaticRun_HandlerOk_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'list', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunListStatic(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-list OK; C-list; C-list confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-list OK; C-list; C-list confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-list OK; C-list; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler returns without closing, no error anywhere.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'wizard', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-wizard OK; C-wizard; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler OK.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'wizard', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-wizard OK; C-wizard; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler Cancel.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerCancel_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'wizard', 2);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'The built-in action = Cancel is not found on the page.');
        O.Expect('end|code', 'TestActionNotFound');
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler Close(), no error anywhere.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerClose_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'wizard', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-wizard OK; C-wizard; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler raises Error, no error anywhere.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerError_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('none', 'wizard', 7);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler returns without closing, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'wizard', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-wizard OK; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-wizard OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler OK.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('query', 'wizard', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-wizard OK; Q-wizard OK; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped:MissingUIHandler');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-wizard OK; Q-wizard OK; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-wizard OK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler returns without closing, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('close', 'wizard', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'Q-wizard OK; C-wizard; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler OK.Invoke, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('close', 'wizard', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler returns without closing, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerReturns_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'wizard', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-wizard OK; C-wizard; C-wizard confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
#else // BC 27.5 behaves differently here
        O.Expect('returned', 'Q-wizard OK; C-wizard; | R1=start/ (1 rows) L1=1 L2=2');
#endif
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
#if BC28PLUS
        O.Expect('log', 'Q-wizard OK; C-wizard; C-wizard confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler OK.Invoke, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerOk_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'wizard', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-wizard OK; C-wizard; C-wizard confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-wizard OK; C-wizard; C-wizard confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler Cancel.Invoke, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerCancel_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'wizard', 2);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'The built-in action = Cancel is not found on the page.');
        O.Expect('end|code', 'TestActionNotFound');
#if BC28PLUS
        O.Expect('log', 'Q-wizard OK; C-wizard; C-wizard confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler Close(), OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerClose_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'wizard', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'Q-wizard OK; C-wizard; C-wizard confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
#endif
#if BC28PLUS
        O.Expect('end|text', 'CEM_NO_ERROR');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-wizard OK; C-wizard; C-wizard confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: WizardRun: handler raises Error, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemWizardRun')]
    procedure WizardRun_HandlerError_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        Help.Setup('confirm', 'wizard', 7);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Runner.RunWizard(Row);
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'Dialog');
#if BC28PLUS
        O.Expect('log', 'Q-wizard OK; C-wizard; C-wizard confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-wizard OK; C-wizard; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    [PageHandler]
    procedure CemCardRun(var P: TestPage "CEM Card")
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
            6:
                begin
                    P.Name.SetValue('EDIT');
                    P.Cancel().Invoke();
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
            10:
                begin
                    P.Name.SetValue('EDIT');
                    P.Close();
                end;
        end;
    end;
    [PageHandler]
    procedure CemListRun(var P: TestPage "CEM List")
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
            6:
                begin
                    P.Name.SetValue('EDIT');
                    P.Cancel().Invoke();
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
            10:
                begin
                    P.Name.SetValue('EDIT');
                    P.Close();
                end;
        end;
    end;
    [PageHandler]
    procedure CemWizardRun(var P: TestPage "CEM Wizard")
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
            7:
                begin
                    Error('CEM handler error');
                end;
        end;
    end;
}
