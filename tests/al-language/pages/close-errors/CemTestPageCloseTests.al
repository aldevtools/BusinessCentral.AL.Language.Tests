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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
    end;

    // CLAIM: Card.Close() with no asserterror around it: OnQueryClosePage raises an error; what GetLastErrorText and GetLastErrorCode hold afterwards (al-runner 7457).
    [Test]
    procedure Card_CloseWithoutAsserterror_QueryCloseError_LastError()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
        Card: TestPage "CEM Card";
    begin
        Help.Setup('query', 'card', 0);
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        ClearLastError();
        Card.Close();
        O.Observe('last error', GetLastErrorText() + '|' + GetLastErrorCode());
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: Card.Close() with no asserterror around it: OnClosePage raises an error; what GetLastErrorText and GetLastErrorCode hold afterwards (al-runner 7457).
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
        Card.Close();
        O.Observe('last error', GetLastErrorText() + '|' + GetLastErrorCode());
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: Card.Close() with no asserterror around it: OnModifyRecord of the page raises an error; what GetLastErrorText and GetLastErrorCode hold afterwards (al-runner 7457).
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
        Card.Close();
        O.Observe('last error', GetLastErrorText() + '|' + GetLastErrorCode());
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: A card edited and left open at the end of the test: OnQueryClosePage raises an error. This test only leaves the page open and keeps the log; the next test reads it.
    [Test]
    procedure Card_LeftOpenAtTestEnd_QueryCloseError_Write()
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
        Cfg.Add('test body end');
        O.Finish();
    end;

    // CLAIM: What the test end of the previous test did (log) and whether the edit was saved (rows): OnQueryClosePage raises an error.
    [Test]
    procedure Card_LeftOpenAtTestEnd_QueryCloseError_Read()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

    // CLAIM: A card edited and left open at the end of the test: OnClosePage raises an error. This test only leaves the page open and keeps the log; the next test reads it.
    [Test]
    procedure Card_LeftOpenAtTestEnd_ClosePageError_Write()
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
        Cfg.Add('test body end');
        O.Finish();
    end;

    // CLAIM: What the test end of the previous test did (log) and whether the edit was saved (rows): OnClosePage raises an error.
    [Test]
    procedure Card_LeftOpenAtTestEnd_ClosePageError_Read()
    var
        O: Codeunit "Probe Observer";
        Row: Record "CEM Row";
    begin
        O.Observe('log', Cfg.Take());
        O.Observe('rows', Help.Names());
        Cfg.Quiet();
        O.Finish();
    end;

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
        O.Finish();
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
        O.Finish();
    end;

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
        O.Finish();
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
        O.Finish();
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
