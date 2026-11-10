// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope (Cloud). TestPage; ModalPageHandler with a TestPage.
// local object: the pages without a source table (controls over array elements, a wizard whose action flips the step variables) are under test
// Fixtures used: Probe Observer (codeunit 69160); own table 63480, pages 63481 and 63482, test codeunit 63489
// Probe (al-runner issues 7418 and 7432): pages with no source table.
//   7418: a StandardDialog whose controls are bound to elements of page-variable arrays (Text, Date, Decimal), run modally in lookup mode.
//   SetValue on the Text element with a Decimal, an Integer, a Boolean, a Date and a Text; on the Date element with a Date; on the Decimal
//   element with a Text. The reading is whether each is accepted (or the error text and code), the value the control shows, the order of the
//   OnValidate triggers, and the variables the caller reads after OK.
//   7432: a NavigatePage whose controls are bound to a field of a global record and to a global variable; the Next action reads them, gets a
//   record and flips the Visible and Enabled variables. The reading is Enabled() of both actions and Visible() and the values of the controls
//   before the action, after it, and after an action that raises an error.
//   Already pinned: testpage/P146PageExprSetValue.al (SetValue and an action on a card with no source table: a variable and Buffer[1].Name),
//   testpage/no-source-controls/NoSourceGlobalRecordSetValue.al (SetValue of every field kind of a global record),
//   testpage/Y5PartArrayElementControl.al (array elements shown by a ListPart).
// BC versions: 27, 28, 29

table 63480 "PNL NS Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 63481 "PNL NS Input Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(TextInput1; TextInputs[1])
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Trace += 'T1;';
                    end;
                }
                field(DateInput2; DateInputs[2])
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        TextInputs[2] := Format(DateInputs[2], 0, 9);
                        Trace += 'D2;';
                    end;
                }
                field(DecimalInput1; DecimalInputs[1])
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Trace += 'N1;';
                    end;
                }
            }
        }
    }

    procedure Dump(): Text
    begin
        exit('text1=' + TextInputs[1] + ' text2=' + TextInputs[2] + ' date2=' + Format(DateInputs[2], 0, 9) + ' decimal1=' + Format(DecimalInputs[1], 0, 9) + ' trace=' + Trace);
    end;

    var
        TextInputs: array[2] of Text;
        DateInputs: array[2] of Date;
        DecimalInputs: array[2] of Decimal;
        Trace: Text;
}

page 63482 "PNL NS Wizard"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Step1)
            {
                Visible = Step1Visible;

                field(ContactNo; Contact."No.") { ApplicationArea = All; }
                field(DocNo; DocNo) { ApplicationArea = All; }
            }
            group(Step2)
            {
                Visible = Step2Visible;

                field(DocDescription; Doc.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionNext)
            {
                ApplicationArea = All;
                Enabled = NextActionEnabled;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Contact.TestField("No.");
                    if DocNo = '' then
                        Error('Doc No. is missing.');
                    Doc.Get(DocNo);
                    Step1Visible := false;
                    Step2Visible := true;
                    NextActionEnabled := false;
                    FinishActionEnabled := true;
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Enabled = FinishActionEnabled;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Step1Visible := true;
        NextActionEnabled := true;
    end;

    var
        Contact: Record "PNL NS Doc";
        Doc: Record "PNL NS Doc";
        DocNo: Code[20];
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        NextActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
}

codeunit 63489 "PNL No Source Array Wizard"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Initialize()
    var
        Doc: Record "PNL NS Doc";
    begin
        Doc.DeleteAll();
        Observer.Discard();
        Doc."No." := 'D1';
        Doc.Description := 'first document';
        Doc.Insert();
        Doc."No." := 'C1';
        Doc.Description := 'a contact';
        Doc.Insert();
    end;

    // ---- issue 7418: SetValue of another kind on a control over an array element ----

    [TryFunction]
    local procedure TryText1(var Dlg: TestPage "PNL NS Input Dialog"; NewValue: Variant)
    begin
        Dlg.TextInput1.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TryDate2(var Dlg: TestPage "PNL NS Input Dialog"; NewValue: Variant)
    begin
        Dlg.DateInput2.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TryDecimal1(var Dlg: TestPage "PNL NS Input Dialog"; NewValue: Variant)
    begin
        Dlg.DecimalInput1.SetValue(NewValue);
    end;

    local procedure Text1(var Dlg: TestPage "PNL NS Input Dialog"; Name: Text; NewValue: Variant)
    begin
        if TryText1(Dlg, NewValue) then
            Observer.Observe(Name, 'accepted, shows [' + Dlg.TextInput1.Value() + ']')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    [HandlerFunctions('InputDialogHandler')]
    procedure InputDialog_ArrayElementControls_SetValueOfOtherKinds()
    var
        Dlg: Page "PNL NS Input Dialog";
        Result: Action;
    begin
        // The reporter's steps of issue 7418: a Decimal to the Text control of slot 1, a Date to the Date control of slot 2.
        Initialize();
        Dlg.LookupMode(true);
        Result := Dlg.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Observe('variables after', Dlg.Dump());
        Observer.Expect('text control, Decimal', 'accepted, shows [12.5]');
        Observer.Expect('text control, Integer', 'accepted, shows [7]');
        Observer.Expect('text control, Boolean', 'accepted, shows [Yes]');
        Observer.Expect('text control, Date', 'accepted, shows [01/15/26]');
        Observer.Expect('text control, Text', 'accepted, shows [plain]');
        Observer.Expect('text control, Decimal again', 'accepted, shows [12.5]');
        Observer.Expect('date control, Date', 'accepted, is the date=Yes');
        Observer.Expect('decimal control, Text', 'accepted, shows [3.00]');
        Observer.Expect('decimal control, Integer', 'accepted, shows [7.00]');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('variables after', 'text1=12.5 text2=2026-01-15 date2=2026-01-15 decimal1=7 trace=T1;T1;T1;T1;T1;T1;D2;N1;N1;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure InputDialogHandler(var Dlg: TestPage "PNL NS Input Dialog")
    var
        DecimalValue: Decimal;
        IntegerValue: Integer;
        BooleanValue: Boolean;
        DateValue: Date;
    begin
        DecimalValue := 12.5;
        IntegerValue := 7;
        BooleanValue := true;
        DateValue := DMY2Date(15, 1, 2026);
        Text1(Dlg, 'text control, Decimal', DecimalValue);
        Text1(Dlg, 'text control, Integer', IntegerValue);
        Text1(Dlg, 'text control, Boolean', BooleanValue);
        Text1(Dlg, 'text control, Date', DateValue);
        Text1(Dlg, 'text control, Text', 'plain');
        Text1(Dlg, 'text control, Decimal again', DecimalValue);
        if TryDate2(Dlg, DateValue) then
            Observer.Observe('date control, Date', 'accepted, is the date=' + Format(Dlg.DateInput2.AsDate() = DateValue))
        else
            Observer.ObserveError('date control, Date');
        if TryDecimal1(Dlg, '3') then
            Observer.Observe('decimal control, Text', 'accepted, shows [' + Dlg.DecimalInput1.Value() + ']')
        else
            Observer.ObserveError('decimal control, Text');
        if TryDecimal1(Dlg, IntegerValue) then
            Observer.Observe('decimal control, Integer', 'accepted, shows [' + Dlg.DecimalInput1.Value() + ']')
        else
            Observer.ObserveError('decimal control, Integer');
        Dlg.OK().Invoke();
    end;

    // ---- issue 7432: an action after SetValue on a wizard with no source table ----

    [TryFunction]
    local procedure TryNext(var Wizard: TestPage "PNL NS Wizard")
    begin
        Wizard.ActionNext.Invoke();
    end;

    [TryFunction]
    local procedure TryWizardState(var Wizard: TestPage "PNL NS Wizard"; var State: Text)
    begin
        State := 'next enabled=' + Format(Wizard.ActionNext.Enabled()) + ' finish enabled=' + Format(Wizard.ActionFinish.Enabled()) +
          ' DocNo visible=' + Format(Wizard.DocNo.Visible()) + ' DocDescription visible=' + Format(Wizard.DocDescription.Visible()) +
          ' ContactNo=' + Wizard.ContactNo.Value() + ' DocNo=' + Wizard.DocNo.Value() + ' DocDescription=' + Wizard.DocDescription.Value();
    end;

    local procedure WizardState(var Wizard: TestPage "PNL NS Wizard"; Name: Text)
    var
        State: Text;
    begin
        if TryWizardState(Wizard, State) then
            Observer.Observe(Name, State)
        else
            Observer.ObserveError(Name + ' error');
    end;

    [Test]
    procedure Wizard_SetValues_ThenNextAction_EnabledAndVisible()
    var
        Wizard: TestPage "PNL NS Wizard";
    begin
        // The reporter's steps of issue 7432.
        Initialize();
        Wizard.OpenEdit();
        WizardState(Wizard, 'after open');
        Wizard.ContactNo.SetValue('C1');
        Wizard.DocNo.SetValue('D1');
        WizardState(Wizard, 'after SetValue');
        if TryNext(Wizard) then
            Observer.Observe('next', 'ok')
        else
            Observer.ObserveError('next error');
        WizardState(Wizard, 'after next');
        Wizard.Close();
        Observer.Expect('after open', 'next enabled=Yes finish enabled=No DocNo visible=Yes DocDescription visible=No ContactNo= DocNo= DocDescription=');
        Observer.Expect('after SetValue', 'next enabled=Yes finish enabled=No DocNo visible=Yes DocDescription visible=No ContactNo=C1 DocNo=D1 DocDescription=');
        Observer.Expect('next', 'ok');
        Observer.Expect('after next', 'next enabled=No finish enabled=Yes DocNo visible=No DocDescription visible=Yes ContactNo=C1 DocNo=D1 DocDescription=first document');
        Observer.Verify();
    end;

    [Test]
    procedure Wizard_SetOneValue_NextActionRaises_ThenSecondValueAndNext()
    var
        Wizard: TestPage "PNL NS Wizard";
    begin
        Initialize();
        Wizard.OpenEdit();
        Wizard.ContactNo.SetValue('C1');
        if TryNext(Wizard) then
            Observer.Observe('first next', 'ok')
        else
            Observer.ObserveError('first next error');
        WizardState(Wizard, 'after the failed next');
        Wizard.DocNo.SetValue('D1');
        if TryNext(Wizard) then
            Observer.Observe('second next', 'ok')
        else
            Observer.ObserveError('second next error');
        WizardState(Wizard, 'after the second next');
        Wizard.Close();
        Observer.Expect('first next error|text', 'Doc No. is missing.');
        Observer.Expect('first next error|code', 'TestWrapped:Dialog');
        Observer.Expect('after the failed next', 'next enabled=Yes finish enabled=No DocNo visible=Yes DocDescription visible=No ContactNo=C1 DocNo= DocDescription=');
        Observer.Expect('second next', 'ok');
        Observer.Expect('after the second next', 'next enabled=No finish enabled=Yes DocNo visible=No DocDescription visible=Yes ContactNo=C1 DocNo=D1 DocDescription=first document');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WizardModalHandler')]
    procedure Wizard_RunModal_SetValues_ThenNextAction_EnabledAndVisible()
    begin
        Initialize();
        Page.RunModal(Page::"PNL NS Wizard");
        Observer.Expect('after SetValue', 'next enabled=Yes finish enabled=No DocNo visible=Yes DocDescription visible=No ContactNo=C1 DocNo=D1 DocDescription=');
        Observer.Expect('next', 'ok');
        Observer.Expect('after next', 'next enabled=No finish enabled=Yes DocNo visible=No DocDescription visible=Yes ContactNo=C1 DocNo=D1 DocDescription=first document');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure WizardModalHandler(var Wizard: TestPage "PNL NS Wizard")
    begin
        Wizard.ContactNo.SetValue('C1');
        Wizard.DocNo.SetValue('D1');
        WizardState(Wizard, 'after SetValue');
        if TryNext(Wizard) then
            Observer.Observe('next', 'ok')
        else
            Observer.ObserveError('next error');
        WizardState(Wizard, 'after next');
    end;
}
