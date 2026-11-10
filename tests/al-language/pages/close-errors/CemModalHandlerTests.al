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
// File: RunModal of a card and a list (static call and Page variable) with a ModalPageHandler, handler mode x error source.
codeunit 99521 "CEM Modal Handler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "CEM Cfg";
        Help: Codeunit "CEM Help";
        Runner: Codeunit "CEM Runner";

    // CLAIM: CardStaticRunModal: handler returns without closing, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 0);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupCancel | Q-card LookupCancel; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card LookupCancel; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler OK.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 1);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupOK | Q-card LookupOK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card LookupOK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler Cancel.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerCancel_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 2);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupCancel | Q-card LookupCancel; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card LookupCancel; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler Close(), no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerClose_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 3);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'The RunModal procedure could not close the page 99504 as it has already been closed.');
        O.Expect('end|code', 'TestCodeUnit');
        O.Expect('log', 'Q-card LookupCancel; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler raises Error, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerError_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 7);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card LookupCancel; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 4);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupCancel | M-card EDIT; T-mod R1 EDIT; Q-card LookupCancel; C-card; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupCancel; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then OK, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 5);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupOK | M-card EDIT; T-mod R1 EDIT; Q-card LookupOK; C-card; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupOK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then Cancel, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditCancel_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 6);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupCancel | M-card EDIT; T-mod R1 EDIT; Q-card LookupCancel; C-card; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupCancel; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler sets the Name the table refuses then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerTableRefusesReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 8);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM table modify refused');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-card FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler sets the Name the table refuses then OK, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerTableRefusesOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 9);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'None | M-card FAILMOD; T-mod R1 FAILMOD; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then Close(), no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditClose_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 10);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'The RunModal procedure could not close the page 99504 as it has already been closed.');
        O.Expect('end|code', 'TestCodeUnit');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupCancel; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler returns without closing, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 0);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | Q-card LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'Q-card LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler OK.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 1);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | Q-card LookupOK; Q-card LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'Q-card LookupOK; Q-card LookupCancel; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card LookupOK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler Cancel.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerCancel_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 2);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | Q-card LookupCancel; Q-card LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'Q-card LookupCancel; Q-card LookupCancel; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card LookupCancel; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler Close(), OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerClose_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 3);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('end|text', 'The RunModal procedure could not close the page 99504 as it has already been closed.');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'TestCodeUnit');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'MissingUIHandler');
#endif
        O.Expect('log', 'Q-card LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler raises Error, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerError_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 7);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('end|text', 'CEM query close error');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'MissingUIHandler');
#endif
        O.Expect('log', 'Q-card LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 4);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | M-card EDIT; T-mod R1 EDIT; Q-card LookupCancel; | R1=EDIT/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then OK, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 5);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | M-card EDIT; T-mod R1 EDIT; Q-card LookupOK; Q-card LookupCancel; | R1=EDIT/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupOK; Q-card LookupCancel; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupOK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then Cancel, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditCancel_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 6);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | M-card EDIT; T-mod R1 EDIT; Q-card LookupCancel; Q-card LookupCancel; | R1=EDIT/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupCancel; Q-card LookupCancel; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupCancel; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler sets the Name the table refuses then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerTableRefusesReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 8);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM table modify refused');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-card FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler sets the Name the table refuses then OK, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerTableRefusesOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 9);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'None | M-card FAILMOD; T-mod R1 FAILMOD; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then Close(), OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditClose_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 10);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('end|text', 'The RunModal procedure could not close the page 99504 as it has already been closed.');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'TestCodeUnit');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'MissingUIHandler');
#endif
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler returns without closing, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'card', 0);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-card LookupCancel; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler OK.Invoke, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'card', 1);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-card LookupOK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler Close(), OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerClose_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'card', 3);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-card LookupCancel; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then OK, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'card', 5);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupOK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler raises Error, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerError_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'card', 7);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-card LookupCancel; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler returns without closing, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerReturns_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('confirm', 'card', 0);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'LookupCancel | Q-card LookupCancel; C-card; C-card confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'Q-card LookupCancel; C-card; C-card confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card LookupCancel; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler OK.Invoke, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerOk_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('confirm', 'card', 1);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'LookupOK | Q-card LookupOK; C-card; C-card confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'Q-card LookupOK; C-card; C-card confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card LookupOK; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler Close(), OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerClose_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('confirm', 'card', 3);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('end|text', 'The RunModal procedure could not close the page 99504 as it has already been closed.');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
#endif
#if BC28PLUS
        O.Expect('end|code', 'TestCodeUnit');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-card LookupCancel; C-card; C-card confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card LookupCancel; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then OK, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditOk_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('confirm', 'card', 5);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'LookupOK | M-card EDIT; T-mod R1 EDIT; Q-card LookupOK; C-card; C-card confirm=No; | R1=EDIT/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupOK; C-card; C-card confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card LookupOK; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler raises Error, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerError_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('confirm', 'card', 7);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('end|text', 'CEM handler error');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'TestWrapped');
#endif
#if BC28PLUS
        O.Expect('log', 'Q-card LookupCancel; C-card; C-card confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-card LookupCancel; C-card; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then returns, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditReturns_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'card', 4);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM page modify error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-card EDIT; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then OK, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditOk_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'card', 5);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'None | M-card EDIT; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then Cancel, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditCancel_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'card', 6);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupCancel | M-card EDIT; Q-card LookupCancel; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; Q-card LookupCancel; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler sets the Name the table refuses then returns, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerTableRefusesReturns_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'card', 8);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM page modify error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-card FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler sets the Name the table refuses then OK, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerTableRefusesOk_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'card', 9);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'None | M-card FAILMOD; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardStaticRunModal: handler edits Name then Close(), OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardStaticRunModal_HandlerEditClose_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'card', 10);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM Card", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM page modify error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-card EDIT; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler returns without closing, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupCancel | Q-list LookupCancel; C-list; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list LookupCancel; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler OK.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupOK | Q-list LookupOK; C-list; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list LookupOK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler Cancel.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerCancel_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 2);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupCancel | Q-list LookupCancel; C-list; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list LookupCancel; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler Close(), no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerClose_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'The RunModal procedure could not close the page 99505 as it has already been closed.');
        O.Expect('end|code', 'TestCodeUnit');
        O.Expect('log', 'Q-list LookupCancel; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler raises Error, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerError_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 7);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list LookupCancel; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler edits Name then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerEditReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 4);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupCancel | M-list EDIT; T-mod R1 EDIT; Q-list LookupCancel; C-list; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list LookupCancel; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler edits Name then OK, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerEditOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupOK | M-list EDIT; T-mod R1 EDIT; Q-list LookupOK; C-list; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list LookupOK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler edits Name then Cancel, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerEditCancel_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 6);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupCancel | M-list EDIT; T-mod R1 EDIT; Q-list LookupCancel; C-list; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list LookupCancel; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler sets the Name the table refuses then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerTableRefusesReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 8);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM table modify refused');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-list FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler returns without closing, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | Q-list LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'Q-list LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler OK.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | Q-list LookupOK; Q-list LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'Q-list LookupOK; Q-list LookupCancel; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-list LookupOK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler Cancel.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerCancel_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 2);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | Q-list LookupCancel; Q-list LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'Q-list LookupCancel; Q-list LookupCancel; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-list LookupCancel; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler Close(), OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerClose_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 3);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('end|text', 'The RunModal procedure could not close the page 99505 as it has already been closed.');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'TestCodeUnit');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'MissingUIHandler');
#endif
        O.Expect('log', 'Q-list LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler raises Error, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerError_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 7);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('end|text', 'CEM query close error');
#else // BC 27.5 behaves differently here
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
#endif
#if BC28PLUS
        O.Expect('end|code', 'Dialog');
#else // BC 27.5 behaves differently here
        O.Expect('end|code', 'MissingUIHandler');
#endif
        O.Expect('log', 'Q-list LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler edits Name then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerEditReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 4);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | M-list EDIT; T-mod R1 EDIT; Q-list LookupCancel; | R1=EDIT/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler edits Name then OK, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerEditOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | M-list EDIT; T-mod R1 EDIT; Q-list LookupOK; Q-list LookupCancel; | R1=EDIT/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list LookupOK; Q-list LookupCancel; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list LookupOK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler edits Name then Cancel, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerEditCancel_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 6);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | M-list EDIT; T-mod R1 EDIT; Q-list LookupCancel; Q-list LookupCancel; | R1=EDIT/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list LookupCancel; Q-list LookupCancel; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list LookupCancel; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler sets the Name the table refuses then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerTableRefusesReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 8);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM table modify refused');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-list FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler returns without closing, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'list', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-list LookupCancel; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler OK.Invoke, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'list', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-list LookupOK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler edits Name then OK, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerEditOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'list', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list LookupOK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler returns without closing, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerReturns_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('confirm', 'list', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'LookupCancel | Q-list LookupCancel; C-list; C-list confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'Q-list LookupCancel; C-list; C-list confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-list LookupCancel; C-list; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler OK.Invoke, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerOk_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('confirm', 'list', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'LookupOK | Q-list LookupOK; C-list; C-list confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'Q-list LookupOK; C-list; C-list confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'Q-list LookupOK; C-list; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler edits Name then OK, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerEditOk_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('confirm', 'list', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'LookupOK | M-list EDIT; T-mod R1 EDIT; Q-list LookupOK; C-list; C-list confirm=No; | R1=EDIT/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list LookupOK; C-list; C-list confirm=No; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list LookupOK; C-list; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler edits Name then returns, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerEditReturns_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'list', 4);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM page modify error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-list EDIT; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler edits Name then OK, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerEditOk_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'list', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'None | M-list EDIT; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-list EDIT; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler edits Name then Cancel, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerEditCancel_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'list', 6);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'LookupCancel | M-list EDIT; Q-list LookupCancel; C-list; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-list EDIT; Q-list LookupCancel; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListStaticRunModal: handler sets the Name the table refuses then returns, OnModifyRecord of the page raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListStaticRunModal_HandlerTableRefusesReturns_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('modrec', 'list', 8);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Page.RunModal(Page::"CEM List", Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM page modify error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-list FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRunModal: handler returns without closing, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 0);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'OK | Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRunModal: handler OK.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 1);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'OK | Q-card OK; C-card; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRunModal: handler edits Name then OK, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerEditOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 5);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'OK | M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRunModal: handler sets the Name the table refuses then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerTableRefusesReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'card', 8);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM table modify refused');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-card FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRunModal: handler returns without closing, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 0);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | Q-card OK; | R1=start/ (1 rows) L1=1 L2=2');
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

    // CLAIM: CardVariableRunModal: handler OK.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 1);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | Q-card OK; Q-card OK; | R1=start/ (1 rows) L1=1 L2=2');
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

    // CLAIM: CardVariableRunModal: handler edits Name then OK, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerEditOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 5);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | M-card EDIT; T-mod R1 EDIT; Q-card OK; Q-card OK; | R1=EDIT/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; Q-card OK; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRunModal: handler sets the Name the table refuses then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerTableRefusesReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'card', 8);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM table modify refused');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-card FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRunModal: handler returns without closing, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'card', 0);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
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

    // CLAIM: CardVariableRunModal: handler OK.Invoke, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'card', 1);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
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

    // CLAIM: CardVariableRunModal: handler edits Name then OK, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerEditOk_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'card', 5);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardVariableRunModal: handler sets the Name the table refuses then returns, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCardModal')]
    procedure CardVariableRunModal_HandlerTableRefusesReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('close', 'card', 8);
        Row.Get('R1');
        asserterror begin
            Res := Runner.ModalCardVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM table modify refused');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-card FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListVariableRunModal: handler returns without closing, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListVariableRunModal_HandlerReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Runner.ModalListVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'OK | Q-list OK; C-list; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListVariableRunModal: handler OK.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListVariableRunModal_HandlerOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Runner.ModalListVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'OK | Q-list OK; C-list; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListVariableRunModal: handler edits Name then OK, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListVariableRunModal_HandlerEditOk_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Runner.ModalListVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'OK | M-list EDIT; T-mod R1 EDIT; Q-list OK; C-list; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListVariableRunModal: handler sets the Name the table refuses then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListVariableRunModal_HandlerTableRefusesReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('none', 'list', 8);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Runner.ModalListVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM table modify refused');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-list FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListVariableRunModal: handler returns without closing, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListVariableRunModal_HandlerReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 0);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Runner.ModalListVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | Q-list OK; | R1=start/ (1 rows) L1=1 L2=2');
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

    // CLAIM: ListVariableRunModal: handler OK.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListVariableRunModal_HandlerOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 1);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Runner.ModalListVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | Q-list OK; Q-list OK; | R1=start/ (1 rows) L1=1 L2=2');
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

    // CLAIM: ListVariableRunModal: handler edits Name then OK, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListVariableRunModal_HandlerEditOk_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 5);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Runner.ModalListVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
#if BC28PLUS
        O.Expect('returned', 'None | M-list EDIT; T-mod R1 EDIT; Q-list OK; Q-list OK; | R1=EDIT/ (1 rows) L1=1 L2=2');
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
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list OK; Q-list OK; ');
#else // BC 27.5 behaves differently here
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list OK; ');
#endif
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListVariableRunModal: handler sets the Name the table refuses then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemListModal')]
    procedure ListVariableRunModal_HandlerTableRefusesReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Res: Action;
    begin
        Help.Setup('query', 'list', 8);
        Row.Get('R1');
        Row.SetRange("Code", 'R1');
        asserterror begin
            Res := Runner.ModalListVariable(Row);
            O.Observe('returned', Format(Res) + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM table modify refused');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-list FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    [ModalPageHandler]
    procedure CemCardModal(var P: TestPage "CEM Card")
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
    [ModalPageHandler]
    procedure CemListModal(var P: TestPage "CEM List")
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
}
