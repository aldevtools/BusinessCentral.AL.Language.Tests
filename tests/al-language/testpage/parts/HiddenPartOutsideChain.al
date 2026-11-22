// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 70490 and 70491, log codeunit 70492, part pages 70493 70494 70495,
//   host pages 70496 70497, test codeunit 70498
// Probe: observe-only. A part that a Visible expression hides and that has no Provider and is no Provider (a FactBox with a SubPageLink on the
//   host key), on a host page that does have a Provider chain (Lines and Detail, Detail has Provider = Lines) and on a host page that has none.
//   ProviderLinkedPartsMatrix.al pins what hidden parts inside a Provider chain run. Not pinned: whether the triggers of a hidden part outside
//   every chain run (OnOpenPage, OnAfterGetCurrRecord with the key of the host row) when a key is typed on the new host row (OpenNew, SetValue),
//   on GoToKey, Next and Previous, and at Close. The visible twin of the part is the comparison. Seen in a Data Check FactBox of Sales Credit Memo
//   (al-runner issue 6924): a part with Visible = <page extension variable set false in OnOpenPage> and SubPageLink = SystemId = field(SystemId)
//   whose OnAfterGetCurrRecord raised an event during the first edit of a new document.
// Observed per step: the part triggers and host triggers that ran (log), and whether the new row was stored.
// local object: the host pages are the fixtures under test (their parts and Visible settings); the log records the part triggers.
// BC versions: 27+

table 70490 "LT HO Doc"
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

table 70491 "LT HO Line"
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

codeunit 70492 "LT HO Log"
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
            Entries += ' | ';
        Entries += Line;
    end;

    procedure Dump(): Text
    begin
        exit('[' + Entries + ']');
    end;

    procedure Clear2()
    begin
        Entries := '';
    end;
}

page 70493 "LT HO Lines"
{
    PageType = ListPart;
    SourceTable = "LT HO Line";
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

page 70494 "LT HO Detail"
{
    PageType = ListPart;
    SourceTable = "LT HO Line";
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

page 70495 "LT HO Factbox"
{
    PageType = CardPart;
    SourceTable = "LT HO Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT HO Log";
    begin
        Log.Add('fb-open(' + Rec.GetFilters() + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT HO Log";
    begin
        Log.Add('fb-row(' + Rec."No." + ')');
    end;
}

page 70496 "LT HO Host Chain"
{
    PageType = Card;
    SourceTable = "LT HO Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT HO Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Detail; "LT HO Detail")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line No." = field("Line No.");
            }
            part(Fb; "LT HO Factbox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
                Visible = FbVisible;
            }
        }
    }

    var
        FbVisible: Boolean;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT HO Log";
    begin
        FbVisible := Log.Show();
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT HO Log";
    begin
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

page 70497 "LT HO Host Plain"
{
    PageType = Card;
    SourceTable = "LT HO Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT HO Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Fb; "LT HO Factbox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
                Visible = FbVisible;
            }
        }
    }

    var
        FbVisible: Boolean;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT HO Log";
    begin
        FbVisible := Log.Show();
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT HO Log";
    begin
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

codeunit 70498 "LT HO Outside Chain"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT HO Log";

    local procedure Seed()
    var
        Doc: Record "LT HO Doc";
        Line: Record "LT HO Line";
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
    end;

    local procedure Say(Name: Text)
    var
        Doc: Record "LT HO Doc";
    begin
        Observer.Observe(Name, 'docs=' + Format(Doc.Count()) + ' log=' + Log.Dump());
        Log.Clear2();
    end;

    local procedure NewDoc(var Card: TestPage "LT HO Host Chain")
    begin
        Card.OpenNew();
        Say('new');
        Card."No.".SetValue('H3');
        Say('keyed');
        Card.Close();
        Say('closed');
    end;

    local procedure NewDocPlain(var Card: TestPage "LT HO Host Plain")
    begin
        Card.OpenNew();
        Say('new');
        Card."No.".SetValue('H3');
        Say('keyed');
        Card.Close();
        Say('closed');
    end;

    [Test]
    procedure Chain_FbHidden_OpenNewTypeKey()
    var
        Card: TestPage "LT HO Host Chain";
    begin
        Seed();
        Log.Reset(false);
        NewDoc(Card);
        Observer.Expect('new', 'docs=2 log=[host-open | fb-open() | host-row() | fb-row()]');
        Observer.Expect('keyed', 'docs=2 log=[fb-row()]');
        Observer.Expect('closed', 'docs=3 log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Chain_FbShown_OpenNewTypeKey()
    var
        Card: TestPage "LT HO Host Chain";
    begin
        Seed();
        Log.Reset(true);
        NewDoc(Card);
        Observer.Expect('new', 'docs=2 log=[host-open | fb-open() | host-row() | fb-row()]');
        Observer.Expect('keyed', 'docs=2 log=[fb-row()]');
        Observer.Expect('closed', 'docs=3 log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_FbHidden_OpenNewTypeKey()
    var
        Card: TestPage "LT HO Host Plain";
    begin
        Seed();
        Log.Reset(false);
        NewDocPlain(Card);
        Observer.Expect('new', 'docs=2 log=[host-open | fb-open() | host-row() | fb-row()]');
        Observer.Expect('keyed', 'docs=2 log=[fb-row()]');
        Observer.Expect('closed', 'docs=3 log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_FbShown_OpenNewTypeKey()
    var
        Card: TestPage "LT HO Host Plain";
    begin
        Seed();
        Log.Reset(true);
        NewDocPlain(Card);
        Observer.Expect('new', 'docs=2 log=[host-open | fb-open() | host-row() | fb-row()]');
        Observer.Expect('keyed', 'docs=2 log=[fb-row()]');
        Observer.Expect('closed', 'docs=3 log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Chain_FbHidden_OpenEditGoToKeyNext()
    var
        Card: TestPage "LT HO Host Chain";
    begin
        Seed();
        Log.Reset(false);
        Card.OpenEdit();
        Say('open');
        Card.GoToKey('H2');
        Say('gotokey_h2');
        Card.Previous();
        Say('previous');
        Card.Next();
        Say('next');
        Card.Close();
        Observer.Expect('open', 'docs=2 log=[host-open | fb-open() | host-row(H1) | fb-row(H1)]');
        Observer.Expect('gotokey_h2', 'docs=2 log=[host-row(H1) | host-row(H2) | fb-row(H2)]');
        Observer.Expect('previous', 'docs=2 log=[host-row(H1) | fb-row(H1)]');
        Observer.Expect('next', 'docs=2 log=[host-row(H2) | fb-row(H2)]');
        Observer.Verify();
    end;

    [Test]
    procedure Chain_FbShown_OpenEditGoToKeyNext()
    var
        Card: TestPage "LT HO Host Chain";
    begin
        Seed();
        Log.Reset(true);
        Card.OpenEdit();
        Say('open');
        Card.GoToKey('H2');
        Say('gotokey_h2');
        Card.Previous();
        Say('previous');
        Card.Next();
        Say('next');
        Card.Close();
        Observer.Expect('open', 'docs=2 log=[host-open | fb-open() | host-row(H1) | fb-row(H1)]');
        Observer.Expect('gotokey_h2', 'docs=2 log=[host-row(H1) | host-row(H2) | fb-row(H2)]');
        Observer.Expect('previous', 'docs=2 log=[host-row(H1) | fb-row(H1)]');
        Observer.Expect('next', 'docs=2 log=[host-row(H2) | fb-row(H2)]');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_FbHidden_OpenEditGoToKeyNext()
    var
        Card: TestPage "LT HO Host Plain";
    begin
        Seed();
        Log.Reset(false);
        Card.OpenEdit();
        Say('open');
        Card.GoToKey('H2');
        Say('gotokey_h2');
        Card.Previous();
        Say('previous');
        Card.Next();
        Say('next');
        Card.Close();
        Observer.Expect('open', 'docs=2 log=[host-open | fb-open() | host-row(H1) | fb-row(H1)]');
        Observer.Expect('gotokey_h2', 'docs=2 log=[host-row(H1) | host-row(H2) | fb-row(H2)]');
        Observer.Expect('previous', 'docs=2 log=[host-row(H1) | fb-row(H1)]');
        Observer.Expect('next', 'docs=2 log=[host-row(H2) | fb-row(H2)]');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_FbShown_OpenEditGoToKeyNext()
    var
        Card: TestPage "LT HO Host Plain";
    begin
        Seed();
        Log.Reset(true);
        Card.OpenEdit();
        Say('open');
        Card.GoToKey('H2');
        Say('gotokey_h2');
        Card.Previous();
        Say('previous');
        Card.Next();
        Say('next');
        Card.Close();
        Observer.Expect('open', 'docs=2 log=[host-open | fb-open() | host-row(H1) | fb-row(H1)]');
        Observer.Expect('gotokey_h2', 'docs=2 log=[host-row(H1) | host-row(H2) | fb-row(H2)]');
        Observer.Expect('previous', 'docs=2 log=[host-row(H1) | fb-row(H1)]');
        Observer.Expect('next', 'docs=2 log=[host-row(H2) | fb-row(H2)]');
        Observer.Verify();
    end;
}
