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
// File: TestPage.Close() on a card, a list and a new card, plus a TestPage left open at the end of a test.
codeunit 99520 "CEM TestPage Close Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "CEM Cfg";
        Help: Codeunit "CEM Help";
        Runner: Codeunit "CEM Runner";

    [TryFunction]
    local procedure TryCloseCard(var Card: TestPage "CEM Card")
    begin
        Card.Close();
    end;

    // CLAIM: TestPage.Close() on a Card with no edit: no error anywhere.
    [Test]
    procedure Card_Close_NoEdit_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Close();
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

    // CLAIM: TestPage.Close() on a Card after Name was edited: no error anywhere.
    [Test]
    procedure Card_Close_AfterEdit_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('EDIT');
        asserterror begin
            Card.Close();
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

    // CLAIM: TestPage.Close() on a Card with no edit: OnQueryClosePage raises an error.
    [Test]
    procedure Card_Close_NoEdit_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
        O.Expect('end|code', 'MissingUIHandler');
        O.Expect('log', 'Q-card OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a Card after Name was edited: OnQueryClosePage raises an error.
    [Test]
    procedure Card_Close_AfterEdit_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('EDIT');
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
        O.Expect('end|code', 'MissingUIHandler');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a Card with no edit: OnClosePage raises an error.
    [Test]
    procedure Card_Close_NoEdit_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('close', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Close();
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

    // CLAIM: TestPage.Close() on a Card after Name was edited: OnClosePage raises an error.
    [Test]
    procedure Card_Close_AfterEdit_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('close', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('EDIT');
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
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

    // CLAIM: TestPage.Close() on a Card with no edit: OnClosePage asks a Confirm nobody handles.
    [Test]
    procedure Card_Close_NoEdit_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('confirm', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a Card after Name was edited: OnClosePage asks a Confirm nobody handles.
    [Test]
    procedure Card_Close_AfterEdit_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('confirm', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('EDIT');
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a Card after Name was edited: OnModifyRecord of the page raises an error.
    [Test]
    procedure Card_Close_AfterEdit_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('modrec', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('EDIT');
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
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

    // CLAIM: TestPage.Close() on a List with no edit: no error anywhere.
    [Test]
    procedure List_Close_NoEdit_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        List: TestPage "CEM List";
    begin
        Help.Setup('none', 'list', 0);
        Row.Get('R1');
        List.OpenEdit();
        List.GoToRecord(Row);
        asserterror begin
            List.Close();
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

    // CLAIM: TestPage.Close() on a List after Name was edited: no error anywhere.
    [Test]
    procedure List_Close_AfterEdit_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        List: TestPage "CEM List";
    begin
        Help.Setup('none', 'list', 0);
        Row.Get('R1');
        List.OpenEdit();
        List.GoToRecord(Row);
        List.Name.SetValue('EDIT');
        asserterror begin
            List.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'M-list EDIT; T-mod R1 EDIT; Q-list OK; C-list; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a List with no edit: OnQueryClosePage raises an error.
    [Test]
    procedure List_Close_NoEdit_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        List: TestPage "CEM List";
    begin
        Help.Setup('query', 'list', 0);
        Row.Get('R1');
        List.OpenEdit();
        List.GoToRecord(Row);
        asserterror begin
            List.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
        O.Expect('end|code', 'MissingUIHandler');
        O.Expect('log', 'Q-list OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a List after Name was edited: OnQueryClosePage raises an error.
    [Test]
    procedure List_Close_AfterEdit_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        List: TestPage "CEM List";
    begin
        Help.Setup('query', 'list', 0);
        Row.Get('R1');
        List.OpenEdit();
        List.GoToRecord(Row);
        List.Name.SetValue('EDIT');
        asserterror begin
            List.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
        O.Expect('end|code', 'MissingUIHandler');
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a List with no edit: OnClosePage raises an error.
    [Test]
    procedure List_Close_NoEdit_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        List: TestPage "CEM List";
    begin
        Help.Setup('close', 'list', 0);
        Row.Get('R1');
        List.OpenEdit();
        List.GoToRecord(Row);
        asserterror begin
            List.Close();
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

    // CLAIM: TestPage.Close() on a List after Name was edited: OnClosePage raises an error.
    [Test]
    procedure List_Close_AfterEdit_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        List: TestPage "CEM List";
    begin
        Help.Setup('close', 'list', 0);
        Row.Get('R1');
        List.OpenEdit();
        List.GoToRecord(Row);
        List.Name.SetValue('EDIT');
        asserterror begin
            List.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a List with no edit: OnClosePage asks a Confirm nobody handles.
    [Test]
    procedure List_Close_NoEdit_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        List: TestPage "CEM List";
    begin
        Help.Setup('confirm', 'list', 0);
        Row.Get('R1');
        List.OpenEdit();
        List.GoToRecord(Row);
        asserterror begin
            List.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a List after Name was edited: OnClosePage asks a Confirm nobody handles.
    [Test]
    procedure List_Close_AfterEdit_ClosePageConfirmUnhandled()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        List: TestPage "CEM List";
    begin
        Help.Setup('confirm', 'list', 0);
        Row.Get('R1');
        List.OpenEdit();
        List.GoToRecord(Row);
        List.Name.SetValue('EDIT');
        asserterror begin
            List.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\Unhandled UI: Confirm CEM close confirm?');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'M-list EDIT; T-mod R1 EDIT; Q-list OK; C-list; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a List after Name was edited: OnModifyRecord of the page raises an error.
    [Test]
    procedure List_Close_AfterEdit_PageModifyRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        List: TestPage "CEM List";
    begin
        Help.Setup('modrec', 'list', 0);
        Row.Get('R1');
        List.OpenEdit();
        List.GoToRecord(Row);
        List.Name.SetValue('EDIT');
        asserterror begin
            List.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
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

    // CLAIM: TestPage.Close() on a card after Name was set to a value the table's OnModify refuses.
    [Test]
    procedure Card_Close_AfterEditTableRefuses()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('FAILMOD');
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
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

    // CLAIM: TestPage.Close() on a list after Name was set to a value the table's OnModify refuses.
    [Test]
    procedure List_Close_AfterEditTableRefuses()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        List: TestPage "CEM List";
    begin
        Help.Setup('none', 'list', 0);
        Row.Get('R1');
        List.OpenEdit();
        List.GoToRecord(Row);
        List.Name.SetValue('FAILMOD');
        asserterror begin
            List.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
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

    // CLAIM: TestPage.Close() on a card whose OnClosePage asks a Confirm that a ConfirmHandler answers true.
    [Test]
    [HandlerFunctions('CemConfirmTrue')]
    procedure Card_Close_ClosePageConfirmHandledWithTrue()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('confirm', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('EDIT');
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; H-confirm CEM close confirm?; C-card confirm=Yes; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; H-confirm CEM close confirm?; C-card confirm=Yes; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a card whose OnClosePage asks a Confirm that a ConfirmHandler answers false.
    [Test]
    [HandlerFunctions('CemConfirmFalse')]
    procedure Card_Close_ClosePageConfirmHandledWithFalse()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('confirm', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('EDIT');
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; H-confirm CEM close confirm?; C-card confirm=No; | R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; H-confirm CEM close confirm?; C-card confirm=No; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a new card (OpenNew, key and Name set): no error anywhere.
    [Test]
    procedure CardNew_Close_NoError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'card', 0);
        Card.OpenNew();
        Card.Code.SetValue('N1');
        Card.Name.SetValue('NEW');
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'I-card ; T-ins N1 ; M-card NEW; T-mod N1 NEW; Q-card OK; C-card; | N1=NEW/ R1=start/ (2 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'I-card ; T-ins N1 ; M-card NEW; T-mod N1 NEW; Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a new card (OpenNew, key and Name set): OnInsertRecord of the page raises an error.
    [Test]
    procedure CardNew_Close_PageInsertRecordError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('insrec', 'card', 0);
        Card.OpenNew();
        asserterror begin
            Card.Code.SetValue('N1');
            O.Observe('after key', Cfg.Peek() + '| ' + Help.Names());
            Card.Name.SetValue('NEW');
            O.Observe('after name', Cfg.Peek() + '| ' + Help.Names());
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('after key', '| R1=start/ (1 rows) L1=1 L2=2');
        O.Expect('end|text', 'Validation error for Field: ,  Message = ''CEM page insert error''');
        O.Expect('end|code', 'TestValidation');
        O.Expect('log', 'I-card ; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a new card (OpenNew, key and Name set): OnQueryClosePage raises an error.
    [Test]
    procedure CardNew_Close_QueryCloseError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'card', 0);
        Card.OpenNew();
        Card.Code.SetValue('N1');
        Card.Name.SetValue('NEW');
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'Unhandled UI: Message CEM query close error');
        O.Expect('end|code', 'MissingUIHandler');
        O.Expect('log', 'I-card ; T-ins N1 ; M-card NEW; T-mod N1 NEW; Q-card OK; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a new card (OpenNew, key and Name set): OnClosePage raises an error.
    [Test]
    procedure CardNew_Close_ClosePageError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('close', 'card', 0);
        Card.OpenNew();
        Card.Code.SetValue('N1');
        Card.Name.SetValue('NEW');
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('end|text', 'One or more errors occurred while closing the page.\\CEM close page error');
        O.Expect('end|code', 'TestWrapped');
        O.Expect('log', 'I-card ; T-ins N1 ; M-card NEW; T-mod N1 NEW; Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: TestPage.Close() on a new card whose Name the table's OnInsert refuses.
    [Test]
    procedure CardNew_Close_TableInsertRefuses()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'card', 0);
        Card.OpenNew();
        Card.Code.SetValue('N1');
        Card.Name.SetValue('FAILINS');
        asserterror begin
            Card.Close();
            O.Observe('returned', Cfg.Peek() + '| ' + Help.Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('returned', 'I-card ; T-ins N1 ; M-card FAILINS; T-mod N1 FAILINS; Q-card OK; C-card; | N1=FAILINS/ R1=start/ (2 rows) L1=1 L2=2');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'I-card ; T-ins N1 ; M-card FAILINS; T-mod N1 FAILINS; Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: Card.Close() with no asserterror around it: OnClosePage raises an error; what GetLastErrorText and GetLastErrorCode hold afterwards (al-runner 7457).
    // A Close that raises with no asserterror around it ends the test with a failure, which CI cannot hold: the Close runs inside a TryFunction, so the error is caught and what GetLastErrorText and GetLastErrorCode hold is observed.
    [Test]
    procedure Card_CloseWithoutAsserterror_ClosePageError_LastError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('close', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        ClearLastError();
        O.Observe('close ok', Format(TryCloseCard(Card)));
        O.Observe('last error', GetLastErrorText() + '|' + GetLastErrorCode());
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('close ok', 'No');
        O.Expect('last error', 'One or more errors occurred while closing the page.\\CEM close page error|TestWrapped');
        O.Expect('log', 'Q-card OK; C-card; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // CLAIM: Card.Close() with no asserterror around it: OnModifyRecord of the page raises an error; what GetLastErrorText and GetLastErrorCode hold afterwards (al-runner 7457).
    // A Close that raises with no asserterror around it ends the test with a failure, which CI cannot hold: the Close runs inside a TryFunction, so the error is caught and what GetLastErrorText and GetLastErrorCode hold is observed.
    [Test]
    procedure Card_CloseWithoutAsserterror_PageModifyRecordError_LastError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('modrec', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('EDIT');
        ClearLastError();
        O.Observe('close ok', Format(TryCloseCard(Card)));
        O.Observe('last error', GetLastErrorText() + '|' + GetLastErrorCode());
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('close ok', 'No');
        O.Expect('last error', 'CEM page modify error|TestWrapped');
        O.Expect('log', 'M-card EDIT; ');
        O.Expect('rows', 'R1=start/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    // Card_LeftOpenAtTestEnd_QueryCloseError: a card edited and left open at the end of the test, whose close raises at the end of the test: the test then ends in a failure (real BC), which CI cannot hold, so it is not pinned here.
    // Card_LeftOpenAtTestEnd_ClosePageError: a card edited and left open at the end of the test, whose close raises at the end of the test: the test then ends in a failure (real BC), which CI cannot hold, so it is not pinned here.
#if BC28PLUS // On BC 27.5 the close at the end of the Write test raises ('One or more errors occurred while closing the page.') and the test fails, which CI cannot hold; the Read test then has nothing to read.
    // CLAIM: A card edited and left open at the end of the test: OnClosePage asks a Confirm nobody handles. This test only leaves the page open and keeps the log; the next test reads it.
    [Test]
    procedure Card_LeftOpenAtTestEnd_ClosePageConfirmUnhandled_Write()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('confirm', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('EDIT');
        Cfg.Add('test body end');
        O.Verify();
    end;

    // CLAIM: What the test end of the previous test did (log) and whether the edit was saved (rows): OnClosePage asks a Confirm nobody handles.
    [Test]
    procedure Card_LeftOpenAtTestEnd_ClosePageConfirmUnhandled_Read()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('log', 'test body end; M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; ');
        O.Expect('rows', 'R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;
#endif

    // CLAIM: A card edited and left open at the end of the test: no error anywhere. This test only leaves the page open and keeps the log; the next test reads it.
    [Test]
    procedure Card_LeftOpenAtTestEnd_NoError_Write()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('none', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('EDIT');
        Cfg.Add('test body end');
        O.Verify();
    end;

    // CLAIM: What the test end of the previous test did (log) and whether the edit was saved (rows): no error anywhere.
    [Test]
    procedure Card_LeftOpenAtTestEnd_NoError_Read()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Expect('log', 'test body end; M-card EDIT; T-mod R1 EDIT; Q-card OK; C-card; ');
        O.Expect('rows', 'R1=EDIT/ (1 rows) L1=1 L2=2');
        O.Verify();
    end;

    [ConfirmHandler]
    procedure CemConfirmTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Cfg.Add('H-confirm ' + Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure CemConfirmFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Cfg.Add('H-confirm ' + Question);
        Reply := false;
    end;
}
