// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 62670 62671, log codeunit 62672, part pages 62673..62675, host page
//   62676, page extension 62677, test codeunit 62678
// Probe: observe-only. Area: the triggers of a FactBox part that a page extension adds and hides with Visible = <variable of the
//   page extension, set in the extension's OnOpenPage>, with a SubPageLink on SystemId and no Provider (the Data Check FactBox on
//   Sales Credit Memo of al-runner issue 6924). ProviderLinkedPartsMatrix.al pins hidden parts inside a Provider chain;
//   HiddenPartOutsideChain.al records a part hidden by a variable of the page itself at OpenNew, GoToKey, Next, Previous and Close.
//   Not covered there: the variable living in a page extension, OnAfterGetRecord, OnQueryClosePage and OnClosePage of the part,
//   and what runs during an action: an action that does nothing, one that runs CurrPage.Update(false), one that changes Rec and
//   runs CurrPage.Update(true), an extension action whose code calls a procedure of the hidden part (with and without
//   CurrPage.Update(false) inside the part), an action before the key of a new document is typed, and an action that turns the
//   variable on while the page is open. Each test runs with the part hidden and with it shown (the comparison). A second FactBox
//   of the base page with Visible = false as a literal is logged as lit-*.
// Observed per step: the number of stored documents and the triggers of the host, the extension and the two FactBoxes (log).
// local object: the page extension, its variable and the logging triggers of the parts are what the test checks
// BC versions: 27, 28, 29

table 62670 "TP HX Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 62671 "TP HX Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }
}

codeunit 62672 "TP HX Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        ShowPart: Boolean;

    procedure Reset(Show: Boolean)
    begin
        Entries := '';
        ShowPart := Show;
    end;

    procedure Show(): Boolean
    begin
        exit(ShowPart);
    end;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' ';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := '[' + Entries + ']';
        Entries := '';
    end;
}

page 62673 "TP HX Lines"
{
    PageType = ListPart;
    SourceTable = "TP HX Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }
}

page 62674 "TP HX Factbox"
{
    PageType = CardPart;
    SourceTable = "TP HX Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    var
        Log: Codeunit "TP HX Log";

    trigger OnInit()
    begin
        Log.Add('fb-init');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('fb-open');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('fb-agr(' + Rec."No." + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('fb-agcr(' + Rec."No." + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('fb-query');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('fb-close');
    end;

    procedure Touch()
    begin
        Log.Add('fb-touch(' + Rec."No." + ')');
        CurrPage.Update(false);
    end;

    procedure Peek()
    begin
        Log.Add('fb-peek(' + Rec."No." + ')');
    end;
}

page 62675 "TP HX Factbox Literal"
{
    PageType = CardPart;
    SourceTable = "TP HX Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    var
        Log: Codeunit "TP HX Log";

    trigger OnInit()
    begin
        Log.Add('lit-init');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('lit-open');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('lit-agr(' + Rec."No." + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('lit-agcr(' + Rec."No." + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('lit-query');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('lit-close');
    end;

    procedure Touch()
    begin
        Log.Add('lit-touch(' + Rec."No." + ')');
        CurrPage.Update(false);
    end;

    procedure Peek()
    begin
        Log.Add('lit-peek(' + Rec."No." + ')');
    end;
}

page 62676 "TP HX Doc Page"
{
    PageType = Document;
    SourceTable = "TP HX Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "TP HX Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Lit; "TP HX Factbox Literal")
            {
                ApplicationArea = All;
                SubPageLink = SystemId = field(SystemId);
                Visible = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Plain)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('act-plain');
                end;
            }
            action(Upd)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('act-upd');
                    CurrPage.Update(false);
                end;
            }
            action(Save)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('act-save');
                    Rec.Name := 'saved';
                    CurrPage.Update(true);
                end;
            }
        }
    }

    var
        Log: Codeunit "TP HX Log";

    trigger OnOpenPage()
    begin
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('host-agcr(' + Rec."No." + ')');
    end;
}

pageextension 62677 "TP HX Doc Page Ext" extends "TP HX Doc Page"
{
    layout
    {
        addfirst(FactBoxes)
        {
            part(Fb; "TP HX Factbox")
            {
                ApplicationArea = All;
                SubPageLink = SystemId = field(SystemId);
                Visible = FbVisibleExt;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(Touch)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ExtLog.Add('act-touch');
                    CurrPage.Fb.Page.Touch();
                end;
            }
            action(Peek)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ExtLog.Add('act-peek');
                    CurrPage.Fb.Page.Peek();
                end;
            }
            action(Flip)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    FbVisibleExt := not FbVisibleExt;
                    ExtLog.Add('act-flip(' + Format(FbVisibleExt) + ')');
                end;
            }
        }
    }

    var
        ExtLog: Codeunit "TP HX Log";
        FbVisibleExt: Boolean;

    trigger OnOpenPage()
    begin
        FbVisibleExt := ExtLog.Show();
        ExtLog.Add('ext-open');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ExtLog.Add('ext-agcr(' + Rec."No." + ')');
    end;
}

codeunit 62678 "TP HX Hidden Ext Part"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "TP HX Log";

    local procedure Seed(Show: Boolean)
    var
        Doc: Record "TP HX Doc";
        Line: Record "TP HX Line";
    begin
        Line.DeleteAll();
        Doc.DeleteAll();
        Doc.Init();
        Doc."No." := 'H1';
        Doc.Insert();
        Doc.Init();
        Doc."No." := 'H2';
        Doc.Insert();
        Line.Init();
        Line."Doc No." := 'H1';
        Line."Line No." := 10;
        Line.Insert();
        Log.Reset(Show);
    end;

    local procedure Say(Name: Text)
    var
        Doc: Record "TP HX Doc";
    begin
        Observer.Observe(Name, Format(Doc.Count()) + ' ' + Log.Take());
    end;

    [Test]
    procedure Hidden_OpenNew_TypeKeyAndName_Close()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(false);
        Card.OpenNew();
        Say('new');
        Card."No.".SetValue('H3');
        Say('keyed');
        Card.Name.SetValue('n');
        Say('named');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Hidden_OpenNew_Key_HostActions()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(false);
        Card.OpenNew();
        Card."No.".SetValue('H3');
        Log.Take();
        Card.Plain.Invoke();
        Say('plain');
        Card.Upd.Invoke();
        Say('upd');
        Card.Save.Invoke();
        Say('save');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Hidden_OpenNew_Key_ActionsThatCallThePart()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(false);
        Card.OpenNew();
        Card."No.".SetValue('H3');
        Log.Take();
        Card.Peek.Invoke();
        Say('peek');
        Card.Touch.Invoke();
        Say('touch');
        Card.Plain.Invoke();
        Say('plain');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Hidden_OpenNew_ActionsBeforeTheKey()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(false);
        Card.OpenNew();
        Say('new');
        Card.Plain.Invoke();
        Say('plain');
        Card.Peek.Invoke();
        Say('peek');
        Card.Touch.Invoke();
        Say('touch');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Hidden_OpenEdit_HostActions()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(false);
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Plain.Invoke();
        Say('plain');
        Card.Upd.Invoke();
        Say('upd');
        Card.Save.Invoke();
        Say('save');
        Card.Name.SetValue('n');
        Say('named');
        Card.Next();
        Say('next');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Hidden_OpenEdit_ActionsThatCallThePart()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(false);
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Peek.Invoke();
        Say('peek');
        Card.Touch.Invoke();
        Say('touch');
        Card.Plain.Invoke();
        Say('plain');
        Card.Next();
        Say('next');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Hidden_OpenEdit_GoToKey_Log()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(false);
        Card.OpenEdit();
        Say('opened');
        Card.GoToKey('H2');
        Say('gotokey');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Hidden_OpenView_Actions()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(false);
        Card.OpenView();
        Card.GoToKey('H1');
        Log.Take();
        Card.Plain.Invoke();
        Say('plain');
        Card.Upd.Invoke();
        Say('upd');
        Card.Peek.Invoke();
        Say('peek');
        Card.Touch.Invoke();
        Say('touch');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Hidden_OpenEdit_FlipTheVariable_ThenActions()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(false);
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Flip.Invoke();
        Say('flip');
        Card.Plain.Invoke();
        Say('plain');
        Card.Upd.Invoke();
        Say('upd');
        Card.Peek.Invoke();
        Say('peek');
        Card.Next();
        Say('next');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Shown_OpenNew_TypeKeyAndName_Close()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(true);
        Card.OpenNew();
        Say('new');
        Card."No.".SetValue('H3');
        Say('keyed');
        Card.Name.SetValue('n');
        Say('named');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Shown_OpenNew_Key_HostActions()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(true);
        Card.OpenNew();
        Card."No.".SetValue('H3');
        Log.Take();
        Card.Plain.Invoke();
        Say('plain');
        Card.Upd.Invoke();
        Say('upd');
        Card.Save.Invoke();
        Say('save');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Shown_OpenNew_Key_ActionsThatCallThePart()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(true);
        Card.OpenNew();
        Card."No.".SetValue('H3');
        Log.Take();
        Card.Peek.Invoke();
        Say('peek');
        Card.Touch.Invoke();
        Say('touch');
        Card.Plain.Invoke();
        Say('plain');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Shown_OpenNew_ActionsBeforeTheKey()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(true);
        Card.OpenNew();
        Say('new');
        Card.Plain.Invoke();
        Say('plain');
        Card.Peek.Invoke();
        Say('peek');
        Card.Touch.Invoke();
        Say('touch');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Shown_OpenEdit_HostActions()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Plain.Invoke();
        Say('plain');
        Card.Upd.Invoke();
        Say('upd');
        Card.Save.Invoke();
        Say('save');
        Card.Name.SetValue('n');
        Say('named');
        Card.Next();
        Say('next');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Shown_OpenEdit_ActionsThatCallThePart()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Peek.Invoke();
        Say('peek');
        Card.Touch.Invoke();
        Say('touch');
        Card.Plain.Invoke();
        Say('plain');
        Card.Next();
        Say('next');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Shown_OpenEdit_GoToKey_Log()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(true);
        Card.OpenEdit();
        Say('opened');
        Card.GoToKey('H2');
        Say('gotokey');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Shown_OpenView_Actions()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(true);
        Card.OpenView();
        Card.GoToKey('H1');
        Log.Take();
        Card.Plain.Invoke();
        Say('plain');
        Card.Upd.Invoke();
        Say('upd');
        Card.Peek.Invoke();
        Say('peek');
        Card.Touch.Invoke();
        Say('touch');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Shown_OpenEdit_FlipTheVariable_ThenActions()
    var
        Card: TestPage "TP HX Doc Page";
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Flip.Invoke();
        Say('flip');
        Card.Plain.Invoke();
        Say('plain');
        Card.Upd.Invoke();
        Say('upd');
        Card.Peek.Invoke();
        Say('peek');
        Card.Next();
        Say('next');
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

}
