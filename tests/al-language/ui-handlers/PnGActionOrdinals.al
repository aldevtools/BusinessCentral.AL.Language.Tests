// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/action/action-option
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG Dlg (70159), LT PnG Confirm (70157), LT PnG List (70135), LT PnG Item (70130)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 61 (TestPage): the numeric ordinals of the Action option members (None, OK, Cancel, LookupOK, LookupCancel, Yes, No, RunObject, RunSystem)
// Facts: Format(member, 0, 0/1/2) of every Action member, default of an Action variable, and the Action a modal run returns for each way a handler closes the page
// BC versions: 29 (27 and 28 by CI)

codeunit 70178 "LT PnG Action Ordinals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerMode: Integer;

    local procedure Fact(var Observer: Codeunit "Probe Observer"; Name: Text; A: Action)
    begin
        Observer.Observe(Name, Format(A) + '|' + Format(A, 0, 1) + '|' + Format(A, 0, 2));
    end;

    [Test]
    procedure MemberOrdinals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Fact(Observer, 'None', Action::None);
        Fact(Observer, 'OK', Action::OK);
        Fact(Observer, 'Cancel', Action::Cancel);
        Fact(Observer, 'LookupOK', Action::LookupOK);
        Fact(Observer, 'LookupCancel', Action::LookupCancel);
        Fact(Observer, 'Yes', Action::Yes);
        Fact(Observer, 'No', Action::No);
        Fact(Observer, 'RunObject', Action::RunObject);
        Fact(Observer, 'RunSystem', Action::RunSystem);
        Observer.Expect('None', 'None|None|None');
        Observer.Expect('OK', 'OK|OK|OK');
        Observer.Expect('Cancel', 'Cancel|Cancel|Cancel');
        Observer.Expect('LookupOK', 'LookupOK|LookupOK|LookupOK');
        Observer.Expect('LookupCancel', 'LookupCancel|LookupCancel|LookupCancel');
        Observer.Expect('Yes', 'Yes|Yes|Yes');
        Observer.Expect('No', 'No|No|No');
        Observer.Expect('RunObject', 'RunObject|RunObject|RunObject');
        Observer.Expect('RunSystem', 'RunSystem|RunSystem|RunSystem');
        Observer.Verify();
    end;

    [Test]
    procedure DefaultAndComparisons()
    var
        Observer: Codeunit "Probe Observer";
        A: Action;
    begin
        Fact(Observer, 'default', A);
        Observer.Observe('default-is-none', Format(A = Action::None));
        A := Action::OK;
        Observer.Observe('ok-equals-ok', Format(A = Action::OK));
        Observer.Observe('ok-is-lookupok', Format(A = Action::LookupOK));
        Observer.Expect('default', 'None|None|None');
        Observer.Expect('default-is-none', 'Yes');
        Observer.Expect('ok-equals-ok', 'Yes');
        Observer.Expect('ok-is-lookupok', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure ModalResultsOfAStandardDialog()
    var
        Observer: Codeunit "Probe Observer";
        R: Action;
    begin
        HandlerMode := 1;
        R := Page.RunModal(Page::"LT PnG Dlg");
        Fact(Observer, 'ok-invoked', R);
        HandlerMode := 2;
        R := Page.RunModal(Page::"LT PnG Dlg");
        Fact(Observer, 'cancel-invoked', R);
        HandlerMode := 3;
        R := Page.RunModal(Page::"LT PnG Dlg");
        Fact(Observer, 'nothing-invoked', R);
        Observer.Expect('ok-invoked', 'LookupOK|LookupOK|LookupOK');
        Observer.Expect('cancel-invoked', 'LookupCancel|LookupCancel|LookupCancel');
        Observer.Expect('nothing-invoked', 'LookupCancel|LookupCancel|LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ModalResultsOfAConfirmationDialog()
    var
        Observer: Codeunit "Probe Observer";
        R: Action;
    begin
        HandlerMode := 1;
        R := Page.RunModal(Page::"LT PnG Confirm");
        Fact(Observer, 'yes-invoked', R);
        HandlerMode := 2;
        R := Page.RunModal(Page::"LT PnG Confirm");
        Fact(Observer, 'no-invoked', R);
        HandlerMode := 3;
        R := Page.RunModal(Page::"LT PnG Confirm");
        Fact(Observer, 'nothing-invoked', R);
        Observer.Expect('yes-invoked', 'Yes|Yes|Yes');
        Observer.Expect('no-invoked', 'No|No|No');
        Observer.Expect('nothing-invoked', 'Cancel|Cancel|Cancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure ModalResultsOfALookup()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT PnG List";
        Item: Record "LT PnG Item";
        R: Action;
    begin
        Item.DeleteAll();
        Item."No." := 'O1';
        Item.Insert();
        HandlerMode := 1;
        Pg.LookupMode(true);
        R := Pg.RunModal();
        Fact(Observer, 'lookupok-invoked', R);
        Clear(Pg);
        HandlerMode := 2;
        Pg.LookupMode(true);
        R := Pg.RunModal();
        Fact(Observer, 'lookupcancel-invoked', R);
        Clear(Pg);
        HandlerMode := 3;
        Pg.LookupMode(true);
        R := Pg.RunModal();
        Fact(Observer, 'lookup-nothing-invoked', R);
        Observer.Expect('lookupok-invoked', 'LookupOK|LookupOK|LookupOK');
        Observer.Expect('lookupcancel-invoked', 'LookupCancel|LookupCancel|LookupCancel');
        Observer.Expect('lookup-nothing-invoked', 'LookupCancel|LookupCancel|LookupCancel');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure DialogHandler(var Dlg: TestPage "LT PnG Dlg")
    begin
        case HandlerMode of
            1:
                Dlg.OK().Invoke();
            2:
                Dlg.Cancel().Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure ConfirmHandler(var Dlg: TestPage "LT PnG Confirm")
    begin
        case HandlerMode of
            1:
                Dlg.Yes().Invoke();
            2:
                Dlg.No().Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure LookupHandler(var List: TestPage "LT PnG List")
    begin
        case HandlerMode of
            1:
                List.OK().Invoke();
            2:
                List.Cancel().Invoke();
        end;
    end;
}
