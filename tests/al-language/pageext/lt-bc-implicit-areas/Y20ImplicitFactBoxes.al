// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in Y20ImplicitFactBoxObjects.al
// Probe (writer Y20, al-runner issue 6490): measured on a BC 29 SaaS sandbox; 27 and 28 by the corpus CI matrix.
// Facts: a page extension may add parts to area(FactBoxes) of a Worksheet, a Document, a ListPlus, a StandardDialog, a
//   ConfirmationDialog and a NavigatePage page that declare none (Card and List are pinned in BcImplicitAreas.al; part pages and
//   RoleCenter do not compile: must-not-compile 2351 to 2354): the test page opens, the hidden part loaded from OnAfterGetCurrRecord and the linked part
//   follow the current row.
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
        Observer.Observe('box', TP.Box.LoadedCtl.Value() + '|' + Format(TP.Box.Visible()));
        Observer.Observe('linked', TP.LinkedBox.BoxK.Value() + '|' + Format(TP.LinkedBox.Visible()));
        TP.Next();
        Observer.Observe('next k', TP.K.Value());
        Observer.Observe('next box', TP.Box.LoadedCtl.Value());
        Observer.Observe('next linked', TP.LinkedBox.BoxK.Value());
        TP.Close();
        Observer.Finish();
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
        Observer.Observe('box', TP.Box.LoadedCtl.Value() + '|' + Format(TP.Box.Visible()));
        Observer.Observe('linked', TP.LinkedBox.BoxK.Value() + '|' + Format(TP.LinkedBox.Visible()));
        TP.Next();
        Observer.Observe('next k', TP.K.Value());
        Observer.Observe('next box', TP.Box.LoadedCtl.Value());
        Observer.Observe('next linked', TP.LinkedBox.BoxK.Value());
        TP.Close();
        Observer.Finish();
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
        Observer.Observe('box', TP.Box.LoadedCtl.Value() + '|' + Format(TP.Box.Visible()));
        Observer.Observe('linked', TP.LinkedBox.BoxK.Value() + '|' + Format(TP.LinkedBox.Visible()));
        TP.Next();
        Observer.Observe('next k', TP.K.Value());
        Observer.Observe('next box', TP.Box.LoadedCtl.Value());
        Observer.Observe('next linked', TP.LinkedBox.BoxK.Value());
        TP.Close();
        Observer.Finish();
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
        Observer.Observe('box', TP.Box.LoadedCtl.Value() + '|' + Format(TP.Box.Visible()));
        Observer.Observe('linked', TP.LinkedBox.BoxK.Value() + '|' + Format(TP.LinkedBox.Visible()));
        TP.Next();
        Observer.Observe('next k', TP.K.Value());
        Observer.Observe('next box', TP.Box.LoadedCtl.Value());
        Observer.Observe('next linked', TP.LinkedBox.BoxK.Value());
        TP.Close();
        Observer.Finish();
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
        Observer.Observe('box', TP.Box.LoadedCtl.Value() + '|' + Format(TP.Box.Visible()));
        Observer.Observe('linked', TP.LinkedBox.BoxK.Value() + '|' + Format(TP.LinkedBox.Visible()));
        TP.Next();
        Observer.Observe('next k', TP.K.Value());
        Observer.Observe('next box', TP.Box.LoadedCtl.Value());
        Observer.Observe('next linked', TP.LinkedBox.BoxK.Value());
        TP.Close();
        Observer.Finish();
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
        Observer.Observe('box', TP.Box.LoadedCtl.Value() + '|' + Format(TP.Box.Visible()));
        Observer.Observe('linked', TP.LinkedBox.BoxK.Value() + '|' + Format(TP.LinkedBox.Visible()));
        TP.Next();
        Observer.Observe('next k', TP.K.Value());
        Observer.Observe('next box', TP.Box.LoadedCtl.Value());
        Observer.Observe('next linked', TP.LinkedBox.BoxK.Value());
        TP.Close();
        Observer.Finish();
    end;
}
