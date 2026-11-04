// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-methods
// Scope: in-scope
// Fixtures used: Assert (60021), and the objects declared below.
//
// CLAIM: opening a host page through a TestPage runs each part's OnOpenPage, and an Error() raised
// there fails the host's OpenView with that error. A host whose part opens cleanly opens, and its
// part's OnOpenPage has run by the time OpenView returns.
//
// Written by agent stma-auto2-4, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4903.

table 67010 "POE Row"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Code"; Code[20]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 67011 "POE Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 67010 "POE Error Part"
{
    PageType = CardPart;
    SourceTable = "POE Row";

    layout
    {
        area(Content)
        {
            field(ErrCode; Rec."Code") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "POE Log";
    begin
        Log.Add('ErrorPartOpen');
        Error('POE part refused to open');
    end;
}

page 67011 "POE Clean Part"
{
    PageType = CardPart;
    SourceTable = "POE Row";

    layout
    {
        area(Content)
        {
            field(CleanCode; Rec."Code") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "POE Log";
    begin
        Log.Add('CleanPartOpen');
    end;
}

page 67012 "POE Error Host"
{
    PageType = Card;
    SourceTable = "POE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(HostCode; Rec."Code") { ApplicationArea = All; }
            part(ErrorPart; "POE Error Part") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "POE Log";
    begin
        Log.Add('HostOpen');
    end;
}

page 67013 "POE Clean Host"
{
    PageType = Card;
    SourceTable = "POE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(HostCode; Rec."Code") { ApplicationArea = All; }
            part(CleanPart; "POE Clean Part") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "POE Log";
    begin
        Log.Add('HostOpen');
    end;
}

codeunit 67010 "POE Part Open Error Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure HostWithCleanPart_OpenView_RunsThePartsOnOpenPage()
    var
        Host: TestPage "POE Clean Host";
        Log: Codeunit "POE Log";
        Opened: Text;
    begin
        Log.Take();
        Host.OpenView();
        Opened := Log.Take();
        Host.Close();
        Assert.IsTrue(StrPos(Opened, 'HostOpen;') > 0, 'the host''s OnOpenPage must have run: ' + Opened);
        Assert.IsTrue(StrPos(Opened, 'CleanPartOpen;') > 0, 'the part''s OnOpenPage must have run when the host opened: ' + Opened);
    end;

    [Test]
    procedure HostWithErroringPart_OpenView_FailsWithThePartsError()
    var
        Host: TestPage "POE Error Host";
        Log: Codeunit "POE Log";
    begin
        Log.Take();
        asserterror Host.OpenView();
        Assert.ExpectedError('POE part refused to open');
        Assert.IsTrue(StrPos(Log.Take(), 'ErrorPartOpen;') > 0, 'the part''s OnOpenPage must have run');
    end;

    [Test]
    procedure HostWithErroringPart_OpenEdit_FailsWithThePartsError()
    var
        Host: TestPage "POE Error Host";
    begin
        asserterror Host.OpenEdit();
        Assert.ExpectedError('POE part refused to open');
    end;
}
