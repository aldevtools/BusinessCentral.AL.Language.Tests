// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope (Cloud)
// Fixtures used: Probe Observer (codeunit 69160); table 93343, codeunit 93342 (log, used by test codeunit 93343 only), pages 93343-93349,
//   test codeunit 93343
// Probe (al-runner issues 6670 and 6673; the Card, List, Document, Worksheet and ListPlus Close() = OK is
//   handlers/TestPageCloseActionByPageTypeContracts.al, a Card left open at the end of a test is testpageclose/Y47CloseAtTestEnd.al):
//   which CloseAction OnQueryClosePage gets for the page types not pinned yet (NavigatePage with a temporary and with a real source table,
//   StandardDialog, ConfirmationDialog, CardPart, ListPart) on an explicit Close(), on OK/Cancel/Yes/No/LookupOK actions where the page type
//   has them, and when the TestPage is left open at the end of the test; a Confirm in OnQueryClosePage with a ConfirmHandler, and with NO
//   ConfirmHandler (explicit Close and test end; Confirm with default true, default false and no default); an Error in OnQueryClosePage at the test end; the reporter's NavigatePage that asks
//   through Guided Experience. Each "left open" test is followed by a test that reads the SingleInstance log the first one left behind
//   (tests of one codeunit run in declaration order in one session).
// Results (corpus CI 27.5, 28.5, 29.0; SaaS sandbox BC 29 where it agrees): Close() and the end of the test give OK on NavigatePage
//   (temporary or real table, also after a footer action and with OpenView), CardPart, ListPart and Card, and Cancel on StandardDialog and
//   ConfirmationDialog; their OK/Cancel/Yes/No actions give OK/Cancel/Yes/No. A Confirm in OnQueryClosePage with no ConfirmHandler:
//   Close() raises 'Unhandled UI: Confirm <question>' (TestWrapped) whatever the default; at the end of the test the same happens silently:
//   the test passes, OnClosePage does not run (al-runner issue 6673). An Error in OnQueryClosePage: Close() raises
//   'Unhandled UI: Message <error text>' (MissingUIHandler), OnClosePage does not run; at the end of the test the test passes.
//   (The SaaS sandbox's test session answered such a Confirm with its default and raised nothing: not asserted.)
// BC versions: 27, 28, 29

table 93343 "LT Y65 QC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 93342 "LT Y65 QC Log"
{
    SingleInstance = true;

    var
        Lines: Text;
        AskOnClose: Boolean;
        FailOnClose: Boolean;
        AskDefault: Integer;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;

    procedure SetMode(NewAsk: Boolean; NewFail: Boolean)
    begin
        AskOnClose := NewAsk;
        FailOnClose := NewFail;
        AskDefault := 0;
    end;

    // 0: Confirm(Question, true); 1: Confirm(Question, false); 2: Confirm(Question) without a default.
    procedure SetAskDefault(NewDefault: Integer)
    begin
        AskDefault := NewDefault;
    end;

    procedure QueryClose(Kind: Text; CloseAction: Action): Boolean
    var
        Answer: Boolean;
    begin
        Add('qc ' + Kind + ' ' + Format(CloseAction));
        if AskOnClose then begin
            case AskDefault of
                0:
                    Answer := Confirm('Close the ' + Kind + ' page?', true);
                1:
                    Answer := Confirm('Close the ' + Kind + ' page?', false);
                2:
                    Answer := Confirm('Close the ' + Kind + ' page?');
            end;
            Add('confirm=' + Format(Answer));
            if not Answer then
                exit(false);
        end;
        if FailOnClose then
            Error('Close of %1 refused.', Kind);
        exit(true);
    end;
}

page 93343 "LT Y65 QC Navigate"
{
    PageType = NavigatePage;
    SourceTable = "LT Y65 QC Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionNext)
            {
                ApplicationArea = All;
                InFooterBar = true;
                trigger OnAction()
                begin
                    Rec.Name := 'Next';
                    Rec.Modify();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Rec.Init();
        Rec."Code" := 'W';
        Rec.Insert();
        Log.Add('open nav');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        exit(Log.QueryClose('nav', CloseAction));
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('close nav');
    end;
}

page 93344 "LT Y65 QC Navigate Real"
{
    PageType = NavigatePage;
    SourceTable = "LT Y65 QC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('open navreal');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        exit(Log.QueryClose('navreal', CloseAction));
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('close navreal');
    end;
}

page 93345 "LT Y65 QC StdDialog"
{
    PageType = StandardDialog;
    SourceTable = "LT Y65 QC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('open std');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        exit(Log.QueryClose('std', CloseAction));
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('close std');
    end;
}

page 93346 "LT Y65 QC ConfDialog"
{
    PageType = ConfirmationDialog;
    SourceTable = "LT Y65 QC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('open conf');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        exit(Log.QueryClose('conf', CloseAction));
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('close conf');
    end;
}

page 93347 "LT Y65 QC CardPart"
{
    PageType = CardPart;
    SourceTable = "LT Y65 QC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('open cardpart');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        exit(Log.QueryClose('cardpart', CloseAction));
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('close cardpart');
    end;
}

page 93348 "LT Y65 QC ListPart"
{
    PageType = ListPart;
    SourceTable = "LT Y65 QC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('open listpart');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        exit(Log.QueryClose('listpart', CloseAction));
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('close listpart');
    end;
}

page 93349 "LT Y65 QC Card"
{
    PageType = Card;
    SourceTable = "LT Y65 QC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('open card');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        exit(Log.QueryClose('card', CloseAction));
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('close card');
    end;
}

page 93350 "LT Y65 QC Setup Wizard"
{
    PageType = NavigatePage;
    SourceTable = "LT Y65 QC Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionNext)
            {
                ApplicationArea = All;
                InFooterBar = true;
                trigger OnAction()
                begin
                    Rec.Name := 'Next';
                    Rec.Modify();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec."Code" := 'A';
        Rec.Insert();
    end;

    // The reporter's shape (al-runner issue 6670): ask only on OK and only while the assisted setup is registered and not complete.
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('qc wizard ' + Format(CloseAction) + ' notcomplete=' +
            Format(GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, Page::"LT Y65 QC Setup Wizard")));
        if CloseAction = Action::OK then
            if GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, Page::"LT Y65 QC Setup Wizard") then
                if not Confirm('The setup is not complete. Do you want to exit?') then
                    Error('');
    end;
}

codeunit 93343 "LT Y65 QC Page Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Start(Ask: Boolean; Fail: Boolean)
    var
        Row: Record "LT Y65 QC Row";
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Take();
        Log.SetMode(Ask, Fail);
        Row.DeleteAll();
        Row."Code" := 'R1';
        Row.Insert();
    end;

    local procedure ReadLog()
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.SetMode(false, false);
        Observer.Observe('log', Log.Take());
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RegisterWizard()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        if GuidedExperience.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"LT Y65 QC Setup Wizard") then
            exit;
        GuidedExperience.InsertAssistedSetup('LT Y65 setup', 'LT Y65 setup', 'Set up the probe.', 0,
            ObjectType::Page, Page::"LT Y65 QC Setup Wizard", AssistedSetupGroup::Extensions, '', VideoCategory::Extensions, '');
    end;

    [TryFunction]
    local procedure TryCloseCard(var Card: TestPage "LT Y65 QC Card")
    begin
        Card.Close();
    end;

    [TryFunction]
    local procedure TryCloseNav(var Nav: TestPage "LT Y65 QC Navigate")
    begin
        Nav.Close();
    end;

    // Explicit Close() and the close actions, per page type.

    [Test]
    procedure Y65_Close_Navigate()
    var
        Nav: TestPage "LT Y65 QC Navigate";
    begin
        Start(false, false);
        Nav.OpenEdit();
        Nav.Close();
        ReadLog();
        Observer.Expect('log', 'open nav;qc nav OK;close nav;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_Navigate_AfterFooterAction()
    var
        Nav: TestPage "LT Y65 QC Navigate";
    begin
        Start(false, false);
        Nav.OpenEdit();
        Nav.ActionNext.Invoke();
        Nav.Close();
        ReadLog();
        Observer.Expect('log', 'open nav;qc nav OK;close nav;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_Navigate_OpenView()
    var
        Nav: TestPage "LT Y65 QC Navigate";
    begin
        Start(false, false);
        Nav.OpenView();
        Nav.Close();
        ReadLog();
        Observer.Expect('log', 'open nav;qc nav OK;close nav;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_NavigateRealTable()
    var
        Nav: TestPage "LT Y65 QC Navigate Real";
    begin
        Start(false, false);
        Nav.OpenEdit();
        Nav.Close();
        ReadLog();
        Observer.Expect('log', 'open navreal;qc navreal OK;close navreal;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_StandardDialog()
    var
        Dlg: TestPage "LT Y65 QC StdDialog";
    begin
        Start(false, false);
        Dlg.OpenEdit();
        Dlg.Close();
        ReadLog();
        Observer.Expect('log', 'open std;qc std Cancel;close std;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_StandardDialog_OK()
    var
        Dlg: TestPage "LT Y65 QC StdDialog";
    begin
        Start(false, false);
        Dlg.OpenEdit();
        Dlg.OK().Invoke();
        ReadLog();
        Observer.Expect('log', 'open std;qc std OK;close std;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_StandardDialog_Cancel()
    var
        Dlg: TestPage "LT Y65 QC StdDialog";
    begin
        Start(false, false);
        Dlg.OpenEdit();
        Dlg.Cancel().Invoke();
        ReadLog();
        Observer.Expect('log', 'open std;qc std Cancel;close std;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_ConfirmationDialog()
    var
        Dlg: TestPage "LT Y65 QC ConfDialog";
    begin
        Start(false, false);
        Dlg.OpenEdit();
        Dlg.Close();
        ReadLog();
        Observer.Expect('log', 'open conf;qc conf Cancel;close conf;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_ConfirmationDialog_Yes()
    var
        Dlg: TestPage "LT Y65 QC ConfDialog";
    begin
        Start(false, false);
        Dlg.OpenEdit();
        Dlg.Yes().Invoke();
        ReadLog();
        Observer.Expect('log', 'open conf;qc conf Yes;close conf;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_ConfirmationDialog_No()
    var
        Dlg: TestPage "LT Y65 QC ConfDialog";
    begin
        Start(false, false);
        Dlg.OpenEdit();
        Dlg.No().Invoke();
        ReadLog();
        Observer.Expect('log', 'open conf;qc conf No;close conf;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_CardPart()
    var
        Part: TestPage "LT Y65 QC CardPart";
    begin
        Start(false, false);
        Part.OpenEdit();
        Part.Close();
        ReadLog();
        Observer.Expect('log', 'open cardpart;qc cardpart OK;close cardpart;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_ListPart()
    var
        Part: TestPage "LT Y65 QC ListPart";
    begin
        Start(false, false);
        Part.OpenEdit();
        Part.Close();
        ReadLog();
        Observer.Expect('log', 'open listpart;qc listpart OK;close listpart;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_Card_OK()
    var
        Card: TestPage "LT Y65 QC Card";
    begin
        Start(false, false);
        Card.OpenEdit();
        Card.OK().Invoke();
        ReadLog();
        Observer.Expect('log', 'open card;qc card OK;close card;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Y65_Close_Navigate_Ask_ConfirmYes()
    var
        Nav: TestPage "LT Y65 QC Navigate";
    begin
        Start(true, false);
        Nav.OpenEdit();
        Nav.ActionNext.Invoke();
        Nav.Close();
        ReadLog();
        Observer.Expect('log', 'open nav;qc nav OK;handler yes: Close the nav page?;confirm=Yes;close nav;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_Card_Ask_NoHandler()
    var
        Card: TestPage "LT Y65 QC Card";
    begin
        Start(true, false);
        Card.OpenEdit();
        Observer.Observe('close', Outcome(TryCloseCard(Card)));
        ReadLog();
        Observer.Expect('close', 'error:Unhandled UI: Confirm Close the card page?|TestWrapped');
        Observer.Expect('log', 'open card;qc card OK;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_Navigate_Ask_NoHandler()
    var
        Nav: TestPage "LT Y65 QC Navigate";
    begin
        Start(true, false);
        Nav.OpenEdit();
        Observer.Observe('close', Outcome(TryCloseNav(Nav)));
        ReadLog();
        Observer.Expect('close', 'error:Unhandled UI: Confirm Close the nav page?|TestWrapped');
        Observer.Expect('log', 'open nav;qc nav OK;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_Card_ErrorInQueryClose()
    var
        Card: TestPage "LT Y65 QC Card";
    begin
        Start(false, true);
        Card.OpenEdit();
        Observer.Observe('close', Outcome(TryCloseCard(Card)));
        ReadLog();
        Observer.Expect('close', 'error:Unhandled UI: Message Close of card refused.|MissingUIHandler');
        Observer.Expect('log', 'open card;qc card OK;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Y65_Close_Wizard_Registered()
    var
        Wizard: TestPage "LT Y65 QC Setup Wizard";
    begin
        Start(false, false);
        RegisterWizard();
        Wizard.OpenEdit();
        Wizard.ActionNext.Invoke();
        Wizard.Close();
        ReadLog();
        Observer.Expect('log', 'qc wizard OK notcomplete=Yes;handler yes: The setup is not complete. Do you want to exit?;');
        Observer.Verify();
    end;

    // Left open at the end of the test: the next test reads the log.

    [Test]
    procedure Y65_Open01_Navigate()
    var
        Nav: TestPage "LT Y65 QC Navigate";
    begin
        Start(false, false);
        Nav.OpenEdit();
        Nav.ActionNext.Invoke();
    end;

    [Test]
    procedure Y65_Open01_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open nav;qc nav OK;close nav;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Open02_NavigateRealTable()
    var
        Nav: TestPage "LT Y65 QC Navigate Real";
    begin
        Start(false, false);
        Nav.OpenEdit();
    end;

    [Test]
    procedure Y65_Open02_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open navreal;qc navreal OK;close navreal;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Open03_StandardDialog()
    var
        Dlg: TestPage "LT Y65 QC StdDialog";
    begin
        Start(false, false);
        Dlg.OpenEdit();
    end;

    [Test]
    procedure Y65_Open03_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open std;qc std Cancel;close std;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Open04_ConfirmationDialog()
    var
        Dlg: TestPage "LT Y65 QC ConfDialog";
    begin
        Start(false, false);
        Dlg.OpenEdit();
    end;

    [Test]
    procedure Y65_Open04_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open conf;qc conf Cancel;close conf;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Open05_CardPart()
    var
        Part: TestPage "LT Y65 QC CardPart";
    begin
        Start(false, false);
        Part.OpenEdit();
    end;

    [Test]
    procedure Y65_Open05_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open cardpart;qc cardpart OK;close cardpart;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Open06_ListPart()
    var
        Part: TestPage "LT Y65 QC ListPart";
    begin
        Start(false, false);
        Part.OpenEdit();
    end;

    [Test]
    procedure Y65_Open06_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open listpart;qc listpart OK;close listpart;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Open07_Card_Ask_NoHandler()
    var
        Card: TestPage "LT Y65 QC Card";
    begin
        // al-runner issue 6673: a Confirm in OnQueryClosePage, no ConfirmHandler, the page left open.
        Start(true, false);
        Card.OpenEdit();
    end;

    [Test]
    procedure Y65_Open07_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open card;qc card OK;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Open08_Navigate_Ask_NoHandler()
    var
        Nav: TestPage "LT Y65 QC Navigate";
    begin
        Start(true, false);
        Nav.OpenEdit();
    end;

    [Test]
    procedure Y65_Open08_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open nav;qc nav OK;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Y65_Open09_Navigate_Ask_ConfirmYes()
    var
        Nav: TestPage "LT Y65 QC Navigate";
    begin
        Start(true, false);
        Nav.OpenEdit();
        Nav.ActionNext.Invoke();
    end;

    [Test]
    procedure Y65_Open09_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open nav;qc nav OK;handler yes: Close the nav page?;confirm=Yes;close nav;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Open10_Card_ErrorInQueryClose()
    var
        Card: TestPage "LT Y65 QC Card";
    begin
        Start(false, true);
        Card.OpenEdit();
    end;

    [Test]
    procedure Y65_Open10_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open card;qc card OK;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Y65_Open11_Wizard_Registered()
    var
        Wizard: TestPage "LT Y65 QC Setup Wizard";
    begin
        // al-runner issue 6670, the reporter's shape: a registered assisted setup that is not complete, left open after the footer action.
        Start(false, false);
        RegisterWizard();
        Wizard.OpenEdit();
        Wizard.ActionNext.Invoke();
    end;

    [Test]
    procedure Y65_Open11_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'qc wizard OK notcomplete=Yes;handler yes: The setup is not complete. Do you want to exit?;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_Card_AskDefaultFalse_NoHandler()
    var
        Card: TestPage "LT Y65 QC Card";
        Log: Codeunit "LT Y65 QC Log";
    begin
        Start(true, false);
        Log.SetAskDefault(1);
        Card.OpenEdit();
        Observer.Observe('close', Outcome(TryCloseCard(Card)));
        ReadLog();
        Observer.Expect('close', 'error:Unhandled UI: Confirm Close the card page?|TestWrapped');
        Observer.Expect('log', 'open card;qc card OK;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Close_Card_AskNoDefault_NoHandler()
    var
        Card: TestPage "LT Y65 QC Card";
        Log: Codeunit "LT Y65 QC Log";
    begin
        Start(true, false);
        Log.SetAskDefault(2);
        Card.OpenEdit();
        Observer.Observe('close', Outcome(TryCloseCard(Card)));
        ReadLog();
        Observer.Expect('close', 'error:Unhandled UI: Confirm Close the card page?|TestWrapped');
        Observer.Expect('log', 'open card;qc card OK;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Open12_Card_AskDefaultFalse_NoHandler()
    var
        Card: TestPage "LT Y65 QC Card";
        Log: Codeunit "LT Y65 QC Log";
    begin
        Start(true, false);
        Log.SetAskDefault(1);
        Card.OpenEdit();
    end;

    [Test]
    procedure Y65_Open12_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open card;qc card OK;');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_Open13_Card_AskNoDefault_NoHandler()
    var
        Card: TestPage "LT Y65 QC Card";
        Log: Codeunit "LT Y65 QC Log";
    begin
        Start(true, false);
        Log.SetAskDefault(2);
        Card.OpenEdit();
    end;

    [Test]
    procedure Y65_Open13_Read()
    begin
        ReadLog();
        Observer.Expect('log', 'open card;qc card OK;');
        Observer.Verify();
    end;

    [ConfirmHandler]
    procedure ConfirmYes(Question: Text; var Reply: Boolean)
    var
        Log: Codeunit "LT Y65 QC Log";
    begin
        Log.Add('handler yes: ' + Question);
        Reply := true;
    end;
}
