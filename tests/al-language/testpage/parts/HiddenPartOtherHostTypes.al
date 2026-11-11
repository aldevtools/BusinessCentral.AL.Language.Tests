// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-types-and-layouts
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 64700 64701 64702, log codeunit 64703, part pages 64704 64705 64706,
//   host pages 64707..64711, test codeunit 64712
// Probe: observe-only. Area: the triggers of a FactBox part that a Visible expression hides, with no Provider (not in a Provider chain),
//   on host page types that HiddenPartExtensionVariable.al and HiddenPartOutsideChain.al do not cover. Those files pin a hidden CardPart
//   on Card and Document hosts; HiddenPartExtensionVariable.al:632 Hidden_OpenEdit_FlipTheVariable_ThenActions shows that an action that
//   turns the Visible variable on makes the part read its row once before the host's refresh (`act-flip(Yes) fb-agr(H1) fb-agcr(H1)
//   host-agcr(H1) ...`). Not pinned: the same on Worksheet, List and ListPlus hosts; a hidden ListPart over a temporary table that a
//   procedure of the part fills, whose answer is the Visible variable (the shape of a journal page's workflow status FactBox, set in an
//   action body); and OpenNew on a Card or Document host with a hidden ListPart that is in no Provider chain.
// Steps: OpenEdit and GoToKey, then actions (turn the variable on, the same with CurrPage.Update(false), fill the temporary part, an
//   action that does nothing), Next and Close; each with the part hidden and with it shown (the comparison). OpenNew: type the key and a
//   name, then Close.
// Observed per step: the number of stored documents and the log: host-* the host's OnOpenPage and OnAfterGetCurrRecord, act-* the
//   action, fb-* the CardPart, wf-* the temporary ListPart, ln-* the lines ListPart (open, agr = OnAfterGetRecord, agcr =
//   OnAfterGetCurrRecord, query = OnQueryClosePage, close = OnClosePage).
// local object: the host pages, their parts and Visible settings are what the test checks; the log records the part triggers
// BC versions: 27, 28, 29

table 64700 "PGA HP Doc"
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

table 64701 "PGA HP Wf"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = SystemMetadata; }
        field(2; "Doc No."; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 64702 "PGA HP Line"
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

codeunit 64703 "PGA HP Log"
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

page 64704 "PGA HP Fb"
{
    PageType = CardPart;
    SourceTable = "PGA HP Doc";
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
        Log: Codeunit "PGA HP Log";

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
}

page 64705 "PGA HP Wf Part"
{
    PageType = ListPart;
    SourceTable = "PGA HP Wf";
    SourceTableTemporary = true;
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Doc No."; Rec."Doc No.") { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "PGA HP Log";

    trigger OnOpenPage()
    begin
        Log.Add('wf-open');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('wf-agr(' + Format(Rec."Entry No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('wf-agcr(' + Format(Rec."Entry No.") + ')');
    end;

    trigger OnClosePage()
    begin
        Log.Add('wf-close');
    end;

    // The shape of a workflow status FactBox: refill the temporary rows for a document and answer whether any exist.
    procedure Fill(DocNo: Code[10]): Boolean
    begin
        Rec.DeleteAll();
        if DocNo = 'H1' then begin
            Rec.Init();
            Rec."Entry No." := 1;
            Rec."Doc No." := DocNo;
            Rec.Insert();
        end;
        Log.Add('wf-fill(' + DocNo + ',' + Format(Rec.Count()) + ')');
        exit(not Rec.IsEmpty());
    end;
}

page 64706 "PGA HP Lines"
{
    PageType = ListPart;
    SourceTable = "PGA HP Line";
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

    var
        Log: Codeunit "PGA HP Log";

    trigger OnOpenPage()
    begin
        Log.Add('ln-open');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('ln-agr(' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('ln-agcr(' + Rec."Doc No." + ',' + Format(Rec."Line No.") + ')');
    end;

    trigger OnClosePage()
    begin
        Log.Add('ln-close');
    end;
}

page 64707 "PGA HP Worksheet Host"
{
    PageType = Worksheet;
    SourceTable = "PGA HP Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Fb; "PGA HP Fb")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
                Visible = FbVisible;
            }
            part(Wf; "PGA HP Wf Part")
            {
                ApplicationArea = All;
                Visible = WfVisible;
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
            action(Flip)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    FbVisible := true;
                    Log.Add('act-flip');
                end;
            }
            action(FlipUpd)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    FbVisible := true;
                    Log.Add('act-flipupd');
                    CurrPage.Update(false);
                end;
            }
            action(Fill)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('act-fill');
                    WfVisible := CurrPage.Wf.Page.Fill(Rec."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "PGA HP Log";
        FbVisible: Boolean;
        WfVisible: Boolean;

    trigger OnOpenPage()
    begin
        FbVisible := Log.Show();
        WfVisible := Log.Show();
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('host-agcr(' + Rec."No." + ')');
    end;
}

page 64708 "PGA HP List Host"
{
    PageType = List;
    SourceTable = "PGA HP Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Fb; "PGA HP Fb")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
                Visible = FbVisible;
            }
            part(Wf; "PGA HP Wf Part")
            {
                ApplicationArea = All;
                Visible = WfVisible;
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
            action(Flip)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    FbVisible := true;
                    Log.Add('act-flip');
                end;
            }
            action(FlipUpd)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    FbVisible := true;
                    Log.Add('act-flipupd');
                    CurrPage.Update(false);
                end;
            }
            action(Fill)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('act-fill');
                    WfVisible := CurrPage.Wf.Page.Fill(Rec."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "PGA HP Log";
        FbVisible: Boolean;
        WfVisible: Boolean;

    trigger OnOpenPage()
    begin
        FbVisible := Log.Show();
        WfVisible := Log.Show();
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('host-agcr(' + Rec."No." + ')');
    end;
}

page 64709 "PGA HP ListPlus Host"
{
    PageType = ListPlus;
    SourceTable = "PGA HP Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Fb; "PGA HP Fb")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
                Visible = FbVisible;
            }
            part(Wf; "PGA HP Wf Part")
            {
                ApplicationArea = All;
                Visible = WfVisible;
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
            action(Flip)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    FbVisible := true;
                    Log.Add('act-flip');
                end;
            }
            action(FlipUpd)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    FbVisible := true;
                    Log.Add('act-flipupd');
                    CurrPage.Update(false);
                end;
            }
            action(Fill)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('act-fill');
                    WfVisible := CurrPage.Wf.Page.Fill(Rec."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "PGA HP Log";
        FbVisible: Boolean;
        WfVisible: Boolean;

    trigger OnOpenPage()
    begin
        FbVisible := Log.Show();
        WfVisible := Log.Show();
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('host-agcr(' + Rec."No." + ')');
    end;
}

page 64710 "PGA HP Card Host"
{
    PageType = Card;
    SourceTable = "PGA HP Doc";
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
            part(Lines; "PGA HP Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                Visible = LinesVisible;
            }
        }
    }

    var
        Log: Codeunit "PGA HP Log";
        LinesVisible: Boolean;

    trigger OnOpenPage()
    begin
        LinesVisible := Log.Show();
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('host-agcr(' + Rec."No." + ')');
    end;
}

page 64711 "PGA HP Document Host"
{
    PageType = Document;
    SourceTable = "PGA HP Doc";
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
            part(Lines; "PGA HP Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                Visible = LinesVisible;
            }
        }
    }

    var
        Log: Codeunit "PGA HP Log";
        LinesVisible: Boolean;

    trigger OnOpenPage()
    begin
        LinesVisible := Log.Show();
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('host-agcr(' + Rec."No." + ')');
    end;
}

codeunit 64712 "PGA HP Hidden Part Hosts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PGA HP Log";

    local procedure Initialize(Show: Boolean)
    var
        Doc: Record "PGA HP Doc";
        Line: Record "PGA HP Line";
    begin
        Observer.Discard();
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
        Doc: Record "PGA HP Doc";
    begin
        Observer.Observe(Name, Format(Doc.Count()) + ' ' + Log.Take());
    end;

    [Test]
    procedure Worksheet_FbHidden_FlipThenPlainNextClose()
    var
        P: TestPage "PGA HP Worksheet Host";
    begin
        Initialize(false);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.Flip.Invoke();
        Say('flip');
        P.Plain.Invoke();
        Say('plain');
        P.Next();
        Say('next');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_FbShown_FlipThenPlainNextClose()
    var
        P: TestPage "PGA HP Worksheet Host";
    begin
        Initialize(true);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.Flip.Invoke();
        Say('flip');
        P.Plain.Invoke();
        Say('plain');
        P.Next();
        Say('next');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_FbHidden_FlipWithUpdateThenClose()
    var
        P: TestPage "PGA HP Worksheet Host";
    begin
        Initialize(false);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.FlipUpd.Invoke();
        Say('flipupd');
        P.Plain.Invoke();
        Say('plain');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_WfHidden_FillByActionThenNextAndFillAgain()
    var
        P: TestPage "PGA HP Worksheet Host";
    begin
        Initialize(false);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.Fill.Invoke();
        Say('fill-h1');
        P.Plain.Invoke();
        Say('plain');
        P.Next();
        Say('next');
        P.Fill.Invoke();
        Say('fill-h2');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure List_FbHidden_FlipThenPlainNextClose()
    var
        P: TestPage "PGA HP List Host";
    begin
        Initialize(false);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.Flip.Invoke();
        Say('flip');
        P.Plain.Invoke();
        Say('plain');
        P.Next();
        Say('next');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure List_FbShown_FlipThenPlainNextClose()
    var
        P: TestPage "PGA HP List Host";
    begin
        Initialize(true);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.Flip.Invoke();
        Say('flip');
        P.Plain.Invoke();
        Say('plain');
        P.Next();
        Say('next');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure List_FbHidden_FlipWithUpdateThenClose()
    var
        P: TestPage "PGA HP List Host";
    begin
        Initialize(false);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.FlipUpd.Invoke();
        Say('flipupd');
        P.Plain.Invoke();
        Say('plain');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure List_WfHidden_FillByActionThenNextAndFillAgain()
    var
        P: TestPage "PGA HP List Host";
    begin
        Initialize(false);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.Fill.Invoke();
        Say('fill-h1');
        P.Plain.Invoke();
        Say('plain');
        P.Next();
        Say('next');
        P.Fill.Invoke();
        Say('fill-h2');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_FbHidden_FlipThenPlainNextClose()
    var
        P: TestPage "PGA HP ListPlus Host";
    begin
        Initialize(false);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.Flip.Invoke();
        Say('flip');
        P.Plain.Invoke();
        Say('plain');
        P.Next();
        Say('next');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_FbShown_FlipThenPlainNextClose()
    var
        P: TestPage "PGA HP ListPlus Host";
    begin
        Initialize(true);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.Flip.Invoke();
        Say('flip');
        P.Plain.Invoke();
        Say('plain');
        P.Next();
        Say('next');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_FbHidden_FlipWithUpdateThenClose()
    var
        P: TestPage "PGA HP ListPlus Host";
    begin
        Initialize(false);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.FlipUpd.Invoke();
        Say('flipupd');
        P.Plain.Invoke();
        Say('plain');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_WfHidden_FillByActionThenNextAndFillAgain()
    var
        P: TestPage "PGA HP ListPlus Host";
    begin
        Initialize(false);
        P.OpenEdit();
        P.GoToKey('H1');
        Say('open');
        P.Fill.Invoke();
        Say('fill-h1');
        P.Plain.Invoke();
        Say('plain');
        P.Next();
        Say('next');
        P.Fill.Invoke();
        Say('fill-h2');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Card_LinesHidden_OpenNewTypeKeyAndNameThenClose()
    var
        P: TestPage "PGA HP Card Host";
    begin
        Initialize(false);
        P.OpenNew();
        Say('opennew');
        P."No.".SetValue('N1');
        Say('key');
        P.Name.SetValue('n');
        Say('name');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Card_LinesShown_OpenNewTypeKeyAndNameThenClose()
    var
        P: TestPage "PGA HP Card Host";
    begin
        Initialize(true);
        P.OpenNew();
        Say('opennew');
        P."No.".SetValue('N1');
        Say('key');
        P.Name.SetValue('n');
        Say('name');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Document_LinesHidden_OpenNewTypeKeyAndNameThenClose()
    var
        P: TestPage "PGA HP Document Host";
    begin
        Initialize(false);
        P.OpenNew();
        Say('opennew');
        P."No.".SetValue('N1');
        Say('key');
        P.Name.SetValue('n');
        Say('name');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Document_LinesShown_OpenNewTypeKeyAndNameThenClose()
    var
        P: TestPage "PGA HP Document Host";
    begin
        Initialize(true);
        P.OpenNew();
        Say('opennew');
        P."No.".SetValue('N1');
        Say('key');
        P.Name.SetValue('n');
        Say('name');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;
}
