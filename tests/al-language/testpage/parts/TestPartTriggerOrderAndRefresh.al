// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021);
//                self-contained pages 68130..68133 and codeunits 68134, 68135
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins, for a host page with a ListPart: the order of OnInit and OnOpenPage between host and part,
// that CurrPage.Update on the host re-reads the part, that OnNewRecord runs when a top-level list
// lands on its blank line (as a part's does), and the full text and code of the error for a part
// that is not on the page (the id inside it is generated per compilation).
// BC versions: 27.5

codeunit 68134 "Probe Page Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

page 68130 "Probe Log Part"
{
    PageType = ListPart;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Text Field"; Rec."Text Field") { ApplicationArea = All; }
            }
        }
    }

    var
        PageLog: Codeunit "Probe Page Log";

    trigger OnInit()
    begin
        PageLog.Add('part.OnInit');
    end;

    trigger OnOpenPage()
    begin
        PageLog.Add('part.OnOpenPage');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        PageLog.Add('part.AGCR(' + Format(Rec."Entry No.") + ')');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        PageLog.Add('part.OnNewRecord');
    end;
}

page 68131 "Probe Log Host"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
            part(Lines; "Probe Log Part")
            {
                ApplicationArea = All;
                SubPageLink = "Integer Field" = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshAction)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    PageLog.Add('host.Action');
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        PageLog: Codeunit "Probe Page Log";

    trigger OnInit()
    begin
        PageLog.Add('host.OnInit');
    end;

    trigger OnOpenPage()
    begin
        PageLog.Add('host.OnOpenPage');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        PageLog.Add('host.AGCR(' + Format(Rec."Entry No.") + ')');
    end;
}

page 68132 "Probe Hidden Part Host"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
            part(HiddenLines; "Probe Log Part")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }
}

page 68133 "Probe Log List"
{
    PageType = List;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
            }
        }
    }

    var
        PageLog: Codeunit "Probe Page Log";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        PageLog.Add('list.OnNewRecord');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        PageLog.Add('list.AGCR(' + Format(Rec."Entry No.") + ')');
    end;
}

codeunit 68135 "Probe Part Triggers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        PageLog: Codeunit "Probe Page Log";

    local procedure Initialize()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        AddRow(1, 1, '');
        AddRow(2, 2, '');
        AddRow(11, 1, 'p1');
        AddRow(12, 1, 'p2');
        AddRow(21, 2, 'q1');
        PageLog.Take();
    end;

    local procedure AddRow(EntryNo: Integer; LinkValue: Integer; TextValue: Text[100])
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := EntryNo;
        ALTUniversal."Integer Field" := LinkValue;
        ALTUniversal."Text Field" := TextValue;
        ALTUniversal.Insert();
    end;

    local procedure OnlyInitAndOpen(Entries: Text): Text
    var
        Parts: List of [Text];
        Part: Text;
        Result: Text;
    begin
        Parts := Entries.Split(';');
        foreach Part in Parts do
            if Part.Contains('OnInit') or Part.Contains('OnOpenPage') then
                Result += Part + ';';
        exit(Result);
    end;

    [Test]
    procedure PartPage_OnInitRunsBetweenHostOnInitAndHostOnOpenPage()
    // CLAIM: host.OnInit, part.OnInit, host.OnOpenPage, part.OnOpenPage, in that order.
    var
        Host: TestPage "Probe Log Host";
    begin
        Initialize();

        Host.OpenEdit();

        Assert.AreEqual('host.OnInit;part.OnInit;host.OnOpenPage;part.OnOpenPage;', OnlyInitAndOpen(PageLog.Take()), 'order');
    end;

    [Test]
    procedure PartPage_FirstRecordTriggers_FollowHostOpenPage()
    // CLAIM: the host reads its first row before the part reads its rows; the part ends on the last of its rows.
    var
        Host: TestPage "Probe Log Host";
        Entries: Text;
    begin
        Initialize();

        Host.OpenEdit();
        Entries := PageLog.Take();

        Assert.IsTrue(Entries.Contains('host.OnInit;part.OnInit;host.OnOpenPage;part.OnOpenPage;host.AGCR(1);'), 'host AGCR after both OnOpenPage: ' + Entries);
        Assert.IsTrue(Entries.EndsWith('part.AGCR(1);'), 'the part ends on its current row: ' + Entries);
    end;

    [Test]
    procedure HostCurrPageUpdate_ReReadsThePart()
    // CLAIM: after CurrPage.Update(false) in a host action the part triggers run again for the linked rows.
    var
        Host: TestPage "Probe Log Host";
        Entries: Text;
    begin
        Initialize();
        Host.OpenEdit();
        Host.GoToKey(2);
        PageLog.Take();

        Host.RefreshAction.Invoke();
        Entries := PageLog.Take();

        Assert.IsTrue(Entries.Contains('host.Action;'), 'the action ran: ' + Entries);
        Assert.IsTrue(Entries.EndsWith('host.AGCR(2);part.AGCR(2);'), 'host then part current-record triggers run after the Update: ' + Entries);
        Assert.IsFalse(Entries.Contains('part.OnOpenPage'), 'the part is not opened again: ' + Entries);
    end;

    [Test]
    procedure TopLevelList_BlankLine_RunsOnNewRecord()
    // CLAIM: Next() past the last row of a top-level list returns true, lands on the blank line, and runs OnNewRecord there.
    var
        List: TestPage "Probe Log List";
        Entries: Text;
    begin
        Initialize();
        List.OpenEdit();
        List.Last();
        PageLog.Take();

        Assert.IsTrue(List.Next(), 'Next past the last data row lands on the blank line');

        Entries := PageLog.Take();
        Assert.AreEqual('list.OnNewRecord;list.AGCR(0);', Entries, 'OnNewRecord then the current-record trigger on the blank line');
    end;

    [Test]
    procedure Part_BlankLine_RunsOnNewRecord()
    var
        Host: TestPage "Probe Log Host";
    begin
        Initialize();
        Host.OpenEdit();
        Host.GoToKey(1);
        Host.Lines.Last();
        PageLog.Take();

        Assert.IsTrue(Host.Lines.Next(), 'Next past the last data row lands on the blank line');

        Assert.AreEqual('part.OnNewRecord;part.AGCR(0);', PageLog.Take(), 'part');
    end;

    [Test]
    procedure TestPart_NotOnThePage_FullTextShapeAndCode()
    // CLAIM: a part declared Visible = false is reached with "The part with ID = <n> was not found on the page." and code TestPartNotFound; the id is generated.
    var
        Host: TestPage "Probe Hidden Part Host";
        Text: Text;
        IdText: Text;
        Id: Integer;
    begin
        Initialize();
        Host.OpenEdit();

        asserterror Host.HiddenLines.First();

        Text := GetLastErrorText();
        Assert.IsTrue(Text.StartsWith('The part with ID = '), 'prefix: ' + Text);
        Assert.IsTrue(Text.EndsWith(' was not found on the page.'), 'suffix: ' + Text);
        IdText := Text.Substring(StrLen('The part with ID = ') + 1);
        IdText := IdText.Substring(1, StrLen(IdText) - StrLen(' was not found on the page.'));
        Assert.IsTrue(Evaluate(Id, IdText), 'the id is a number: ' + IdText);
        Assert.AreNotEqual(0, Id, 'and it is not 0');
        Assert.AreEqual('TestPartNotFound', GetLastErrorCode(), 'code');
    end;
}
