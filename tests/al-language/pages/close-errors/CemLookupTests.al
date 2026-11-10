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
// File: Lookup of a TableRelation field whose LookupPageId is a list: from a card field and from a ListPart field of a document (al-runner 7479).
codeunit 99524 "CEM Lookup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "CEM Cfg";
        Help: Codeunit "CEM Help";
        Runner: Codeunit "CEM Runner";

    [TryFunction]
    local procedure TryCloseDoc(var Doc: TestPage "CEM Doc")
    begin
        Doc.Close();
    end;

    // CLAIM: CardField: lookup handler returns without closing, no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'codes', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C1 | Q-codes LookupCancel; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler OK.Invoke on the first row, no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerOkFirstRow_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'codes', 1);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C1 | Q-codes LookupOK; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler Cancel.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerCancel_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'codes', 2);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupCancel; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler Close(), no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerClose_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'codes', 3);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C1 | Q-codes LookupCancel; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler raises Error, no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerError_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'codes', 7);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'TestWrapped:Dialog');
        O.Expect('log', 'Q-codes LookupCancel; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler picks C2 then OK, no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerPicksC2Ok_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'codes', 11);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C2 | Q-codes LookupOK; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler picks C2 then returns, no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerPicksC2Returns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'codes', 12);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C2 | Q-codes LookupCancel; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler picks C2 then Close(), no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerPicksC2Close_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'codes', 13);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C2 | Q-codes LookupCancel; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler returns without closing, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'codes', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler OK.Invoke on the first row, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerOkFirstRow_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'codes', 1);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupOK; Q-codes LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; Q-codes LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler Cancel.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerCancel_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'codes', 2);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupCancel; Q-codes LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; Q-codes LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler Close(), OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerClose_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'codes', 3);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler raises Error, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerError_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'codes', 7);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'TestWrapped:Dialog');
        O.Expect('log', 'Q-codes LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler picks C2 then OK, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerPicksC2Ok_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'codes', 11);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupOK; Q-codes LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; Q-codes LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler picks C2 then returns, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerPicksC2Returns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'codes', 12);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler picks C2 then Close(), OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerPicksC2Close_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'codes', 13);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupCancel; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler returns without closing, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('close', 'codes', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupCancel; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler OK.Invoke on the first row, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerOkFirstRow_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('close', 'codes', 1);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler Close(), OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerClose_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('close', 'codes', 3);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-codes LookupCancel; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler picks C2 then OK, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerPicksC2Ok_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('close', 'codes', 11);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler returns without closing, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerReturns_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('confirm', 'codes', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C1 | Q-codes LookupCancel; C-codes; C-codes confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; C-codes; C-codes confirm=No; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler OK.Invoke on the first row, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerOkFirstRow_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('confirm', 'codes', 1);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C1 | Q-codes LookupOK; C-codes; C-codes confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; C-codes confirm=No; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler Close(), OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerClose_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('confirm', 'codes', 3);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C1 | Q-codes LookupCancel; C-codes; C-codes confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupCancel; C-codes; C-codes confirm=No; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: CardField: lookup handler picks C2 then OK, OnClosePage asks a Confirm nobody handles.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure CardField_Lookup_HandlerPicksC2Ok_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('confirm', 'codes', 11);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Ref.Lookup();
            O.Observe('returned', 'value=' + Card.Ref.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C2 | Q-codes LookupOK; C-codes; C-codes confirm=No; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; C-codes confirm=No; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler returns without closing, no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerReturns_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('none', 'codes', 0);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupOK; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler OK.Invoke on the first row, no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerOkFirstRow_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('none', 'codes', 1);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C1 | Q-codes LookupOK; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler Cancel.Invoke, no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerCancel_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('none', 'codes', 2);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupOK; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler Close(), no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerClose_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('none', 'codes', 3);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupOK; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler raises Error, no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerError_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('none', 'codes', 7);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'TestWrapped:Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler picks C2 then OK, no error anywhere.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerPicksC2Ok_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('none', 'codes', 11);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value=C2 | Q-codes LookupOK; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler returns without closing, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerReturns_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('query', 'codes', 0);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupOK; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler OK.Invoke on the first row, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerOkFirstRow_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('query', 'codes', 1);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupOK; Q-codes LookupOK; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; Q-codes LookupOK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler Cancel.Invoke, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerCancel_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('query', 'codes', 2);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupOK; Q-codes LookupOK; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; Q-codes LookupOK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler Close(), OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerClose_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('query', 'codes', 3);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupOK; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler raises Error, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerError_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('query', 'codes', 7);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'TestWrapped:Dialog');
        O.Expect('log', 'Q-codes LookupOK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler picks C2 then OK, OnQueryClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerPicksC2Ok_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('query', 'codes', 11);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupOK; Q-codes LookupOK; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; Q-codes LookupOK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler returns without closing, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerReturns_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('close', 'codes', 0);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        if not TryCloseDoc(Doc) then
            O.ObserveError('close after');
        Cfg.Quiet();
        O.Expect('returned', 'value= | Q-codes LookupOK; C-codes; | R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler OK.Invoke on the first row, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerOkFirstRow_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('close', 'codes', 1);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler Cancel.Invoke, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerCancel_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('close', 'codes', 2);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler Close(), OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerClose_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('close', 'codes', 3);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler raises Error, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerError_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('close', 'codes', 7);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'CEM handler error');
        O.Expect('end|code', 'TestWrapped:Dialog');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: ListPartField: lookup handler picks C2 then OK, OnClosePage raises an error.
    [Test]
    [HandlerFunctions('CemCodesModal')]
    procedure ListPartField_Lookup_HandlerPicksC2Ok_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Doc: TestPage "CEM Doc";
    begin
        Help.Setup('close', 'codes', 11);
        Row.Get('R1');
        Doc.OpenEdit();
        Doc.GoToRecord(Row);
        Doc.Lines.First();
        asserterror begin
            Doc.Lines.RefCode.Lookup();
            O.Observe('returned', 'value=' + Doc.Lines.RefCode.Value() + ' | ' + Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-codes LookupOK; C-codes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    [ModalPageHandler]
    procedure CemCodesModal(var P: TestPage "CEM Codes")
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
            11:
                begin
                    P.GoToKey('C2');
                    P.OK().Invoke();
                end;
            12:
                begin
                    P.GoToKey('C2');
                end;
            13:
                begin
                    P.GoToKey('C2');
                    P.Close();
                end;
        end;
    end;
}
