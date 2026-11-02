// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in Y20ImplicitFactBoxObjects.al
// Probe (writer Y20, al-runner issue 6490): measured on a BC 29 SaaS sandbox; 27 and 28 by the corpus CI matrix.
// Facts: a page extension may add parts to area(FactBoxes) of a Worksheet, a Document, a ListPlus, a StandardDialog, a
//   ConfirmationDialog and a NavigatePage page that declare none (Card and List are pinned in BcImplicitAreas.al; part pages and
//   RoleCenter do not compile: must-not-compile 2351 to 2354): the test page opens and runs the extension's OnAfterGetCurrRecord,
//   which loads the hidden part; the linked part follows the current row; the hidden part as a TestPage part. On a StandardDialog, a
//   ConfirmationDialog and a NavigatePage the extension compiles and the page opens, but the added part is not on the page.
// BC versions: 27, 28, 29

codeunit 92126 "LT Y20 Implicit FactBoxes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup()
    var
        R: Record "LT Y20 FB Row";
    begin
        R.DeleteAll();
        R.K := 'A';
        R.Name := 'Row A';
        R.Insert();
        R.K := 'B';
        R.Name := 'Row B';
        R.Insert();
    end;

    [Test]
    procedure Y20_Worksheet_FactBoxes_NotDeclared()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y20 FB Sheet";
    begin
        Setup();
        TP.OpenView();
        Observer.Observe('k', TP.K.Value());
        Observer.Observe('linked', TP.LinkedBox.BoxK.Value() + '|' + TP.LinkedBox.LoadedCtl.Value() + '|' + Format(TP.LinkedBox.Visible()));
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('next k', TP.K.Value());
        Observer.Observe('next linked', TP.LinkedBox.BoxK.Value() + '|' + TP.LinkedBox.LoadedCtl.Value());
        // The part added with Visible = false (the reporter's shape, loaded from OnAfterGetCurrRecord).
        asserterror Observer.Observe('hidden box', TP.Box.LoadedCtl.Value());
        Observer.ObserveError('hidden box');
        Observer.Expect('k', 'A');
        Observer.Expect('linked', 'A||Yes');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next k', 'B');
        Observer.Expect('next linked', 'B|');
        Observer.Expect('hidden box|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('hidden box|code', 'TestPartNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y20_Document_FactBoxes_NotDeclared()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y20 FB Doc";
    begin
        Setup();
        TP.OpenView();
        Observer.Observe('k', TP.K.Value());
        Observer.Observe('linked', TP.LinkedBox.BoxK.Value() + '|' + TP.LinkedBox.LoadedCtl.Value() + '|' + Format(TP.LinkedBox.Visible()));
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('next k', TP.K.Value());
        Observer.Observe('next linked', TP.LinkedBox.BoxK.Value() + '|' + TP.LinkedBox.LoadedCtl.Value());
        // The part added with Visible = false (the reporter's shape, loaded from OnAfterGetCurrRecord).
        asserterror Observer.Observe('hidden box', TP.Box.LoadedCtl.Value());
        Observer.ObserveError('hidden box');
        Observer.Expect('k', 'A');
        Observer.Expect('linked', 'A||Yes');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next k', 'B');
        Observer.Expect('next linked', 'B|');
        Observer.Expect('hidden box|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('hidden box|code', 'TestPartNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y20_ListPlus_FactBoxes_NotDeclared()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y20 FB ListPlus";
    begin
        Setup();
        TP.OpenView();
        Observer.Observe('k', TP.K.Value());
        Observer.Observe('linked', TP.LinkedBox.BoxK.Value() + '|' + TP.LinkedBox.LoadedCtl.Value() + '|' + Format(TP.LinkedBox.Visible()));
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('next k', TP.K.Value());
        Observer.Observe('next linked', TP.LinkedBox.BoxK.Value() + '|' + TP.LinkedBox.LoadedCtl.Value());
        // The part added with Visible = false (the reporter's shape, loaded from OnAfterGetCurrRecord).
        asserterror Observer.Observe('hidden box', TP.Box.LoadedCtl.Value());
        Observer.ObserveError('hidden box');
        Observer.Expect('k', 'A');
        Observer.Expect('linked', 'A||Yes');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next k', 'B');
        Observer.Expect('next linked', 'B|');
        Observer.Expect('hidden box|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('hidden box|code', 'TestPartNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y20_StandardDialog_FactBoxes_NotDeclared()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y20 FB Dialog";
    begin
        Setup();
        TP.OpenView();
        Observer.Observe('k', TP.K.Value());
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('next k', TP.K.Value());
        // The part with a SubPageLink, added by addlast(FactBoxes).
        asserterror Observer.Observe('linked', TP.LinkedBox.BoxK.Value());
        Observer.ObserveError('linked');
        Observer.Expect('k', 'A');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next k', 'B');
        Observer.Expect('linked|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('linked|code', 'TestPartNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y20_ConfirmationDialog_FactBoxes_NotDeclared()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y20 FB Confirm";
    begin
        Setup();
        TP.OpenView();
        Observer.Observe('k', TP.K.Value());
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('next k', TP.K.Value());
        // The part with a SubPageLink, added by addlast(FactBoxes).
        asserterror Observer.Observe('linked', TP.LinkedBox.BoxK.Value());
        Observer.ObserveError('linked');
        Observer.Expect('k', 'A');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next k', 'B');
        Observer.Expect('linked|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('linked|code', 'TestPartNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y20_NavigatePage_FactBoxes_NotDeclared()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y20 FB Navigate";
    begin
        Setup();
        TP.OpenView();
        Observer.Observe('k', TP.K.Value());
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('next k', TP.K.Value());
        // The part with a SubPageLink, added by addlast(FactBoxes).
        asserterror Observer.Observe('linked', TP.LinkedBox.BoxK.Value());
        Observer.ObserveError('linked');
        Observer.Expect('k', 'A');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next k', 'B');
        Observer.Expect('linked|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('linked|code', 'TestPartNotFound');
        Observer.Verify();
    end;
}
