// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-provider-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); PVD Header (69140), PVD Line (69141), PVD Detail (69142); self-contained log 65401, part pages 65402 65403,
//   host pages 65404..65412, page extension 65413, test codeunit 65414
// Probe: observe-only. TestPartProvider.al pins what a visible Provider-linked part shows. This file records the rest of the Provider chain.
// Facts: a Provider part and the part linked to it (SubPageLink reads a field of the Provider's row) when both, only the Provider, only the linked part or
//   neither is hidden (by a Visible expression that is read per row, and by a Visible = false literal); a Visible expression that turns true after the key of
//   a new record is typed; hosts of PageType Card, Document and ListPlus, a host over a temporary table, a host with two linked parts, and a host that gets
//   both parts from a page extension in the FactBoxes area; an empty Provider; OpenView, OpenEdit, OpenNew with SetValue of the key and Close (insert),
//   GoToKey, GoToRecord, Next, Previous and Page.Run. Observed per scenario: the rows the parts show, the part triggers that ran (OnOpenPage and
//   OnAfterGetCurrRecord with the filter of the part), and the error when a hidden part is reached. A part with Visible = false is not in the control tree
//   of the TestPage (see TestPartHidden.Page.al), so what happens to it is visible only through the log.
// local object: the host pages are the fixtures under test (their Provider and Visible settings), the log records the part triggers.
// BC versions: 27, 28, 29

codeunit 65401 "LT PV Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        Mode: Text;

    procedure Reset(NewMode: Text)
    begin
        Clear(Lines);
        Mode := NewMode;
    end;

    procedure Clear2()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    // Which parts a host shows for a row, by the mode of the test: both, hidden-both, hidden-provider, hidden-linked, by-key.
    procedure Visibility(HostNo: Text; var ShowLines: Boolean; var ShowDetail: Boolean)
    begin
        ShowLines := true;
        ShowDetail := true;
        case Mode of
            'hidden-both':
                begin
                    ShowLines := false;
                    ShowDetail := false;
                end;
            'hidden-provider':
                ShowLines := false;
            'hidden-linked':
                ShowDetail := false;
            'by-key':
                begin
                    ShowLines := HostNo <> '';
                    ShowDetail := HostNo <> '';
                end;
        end;
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}

page 65402 "LT PV Lines Part"
{
    PageType = ListPart;
    SourceTable = "PVD Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(HeaderNo; Rec."Header No.") { ApplicationArea = All; }
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('lines-open(' + Rec.GetFilters() + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('lines-row(' + Format(Rec."Line No.") + ')');
    end;
}

page 65403 "LT PV Detail Part"
{
    PageType = ListPart;
    SourceTable = "PVD Detail";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Details)
            {
                field(LineRef; Rec."Line Ref") { ApplicationArea = All; }
                field(Info; Rec.Info) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('detail-open(' + Rec.GetFilters() + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('detail-row(' + Rec.Info + ')');
    end;
}
page 65404 "LT PV Host"
{
    PageType = Card;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT PV Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                Visible = ShowLines;
            }
        }
        area(FactBoxes)
        {
            part(Detail; "LT PV Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
                Visible = ShowDetail;
            }
        }
    }

    var
        ShowLines: Boolean;
        ShowDetail: Boolean;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Visibility(Rec."No.", ShowLines, ShowDetail);
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

page 65405 "LT PV Host Lit Both"
{
    PageType = Card;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT PV Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                Visible = false;
            }
        }
        area(FactBoxes)
        {
            part(Detail; "LT PV Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
                Visible = false;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

page 65406 "LT PV Host Lit Prov"
{
    PageType = Card;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT PV Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                Visible = false;
            }
        }
        area(FactBoxes)
        {
            part(Detail; "LT PV Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

page 65407 "LT PV Host Lit Linked"
{
    PageType = Card;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT PV Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Detail; "LT PV Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
                Visible = false;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

page 65408 "LT PV Host Document"
{
    PageType = Document;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT PV Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                Visible = ShowLines;
            }
        }
        area(FactBoxes)
        {
            part(Detail; "LT PV Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
                Visible = ShowDetail;
            }
        }
    }

    var
        ShowLines: Boolean;
        ShowDetail: Boolean;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Visibility(Rec."No.", ShowLines, ShowDetail);
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

page 65409 "LT PV Host ListPlus"
{
    PageType = ListPlus;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Headers)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT PV Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                Visible = ShowLines;
            }
        }
        area(FactBoxes)
        {
            part(Detail; "LT PV Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
                Visible = ShowDetail;
            }
        }
    }

    var
        ShowLines: Boolean;
        ShowDetail: Boolean;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Visibility(Rec."No.", ShowLines, ShowDetail);
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

page 65410 "LT PV Host Temp"
{
    PageType = Card;
    SourceTable = "PVD Header";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT PV Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                Visible = ShowLines;
            }
        }
        area(FactBoxes)
        {
            part(Detail; "LT PV Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
                Visible = ShowDetail;
            }
        }
    }

    var
        ShowLines: Boolean;
        ShowDetail: Boolean;

    // The source table is temporary: the page copies the rows of the real table so there is something to show.
    trigger OnOpenPage()
    var
        Log: Codeunit "LT PV Log";
        Source: Record "PVD Header";
    begin
        if Source.FindSet() then
            repeat
                Rec := Source;
                Rec.Insert();
            until Source.Next() = 0;
        if Rec.FindFirst() then;
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Visibility(Rec."No.", ShowLines, ShowDetail);
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

page 65411 "LT PV Host Two"
{
    PageType = Card;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT PV Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                Visible = ShowLines;
            }
        }
        area(FactBoxes)
        {
            part(Detail; "LT PV Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
                Visible = ShowDetail;
            }
            part(Detail2; "LT PV Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Entry No." = field("Line No.");
                Visible = ShowDetail;
            }
        }
    }

    var
        ShowLines: Boolean;
        ShowDetail: Boolean;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('host-open');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Visibility(Rec."No.", ShowLines, ShowDetail);
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

page 65412 "LT PV Host Base"
{
    PageType = Card;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            systempart(RecLinks; Links) { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PV Log";
    begin
        Log.Add('base-row(' + Rec."No." + ')');
    end;
}

pageextension 65413 "LT PV Host Base Ext" extends "LT PV Host Base"
{
    layout
    {
        addfirst(FactBoxes)
        {
            part(Lines; "LT PV Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                UpdatePropagation = Both;
            }
            part(Detail; "LT PV Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
            }
        }
    }
}

codeunit 65414 "LT PV Provider Matrix"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PV Log";

    local procedure Seed()
    var
        Header: Record "PVD Header";
        Line: Record "PVD Line";
        Detail: Record "PVD Detail";
    begin
        Detail.DeleteAll();
        Line.DeleteAll();
        Header.DeleteAll();
        Header.Init();
        Header."No." := 'H1';
        Header."Line No." := 1;
        Header.Insert();
        Header.Init();
        Header."No." := 'H2';
        Header."Line No." := 1;
        Header.Insert();
        InsertLine('H1', 10);
        InsertLine('H1', 20);
        InsertDetail(1, 10, 'ten');
        InsertDetail(2, 20, 'twenty');
        InsertDetail(3, 1, 'decoy');
    end;

    local procedure InsertLine(HeaderNo: Code[20]; LineNo: Integer)
    var
        Line: Record "PVD Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Insert();
    end;

    local procedure InsertDetail(EntryNo: Integer; LineRef: Integer; Info: Text[30])
    var
        Detail: Record "PVD Detail";
    begin
        Detail.Init();
        Detail."Entry No." := EntryNo;
        Detail."Line Ref" := LineRef;
        Detail.Info := Info;
        Detail.Insert();
    end;

    local procedure Header(No: Code[20]) Result: Record "PVD Header"
    begin
        Result.Get(No);
    end;

    local procedure Say(Name: Text; Rows: Text)
    begin
        Observer.Observe(Name, Rows + ' log=' + Log.Dump());
        Log.Clear2();
    end;

    local procedure ErrorOr(Ok: Boolean; Rows: Text): Text
    begin
        if Ok then
            exit(Rows);
        exit('ERR[' + GetLastErrorText() + ']');
    end;

    [TryFunction]
    local procedure TryLinesHost(var Card: TestPage "LT PV Host"; var Rows: Text)
    begin
        Rows := '';
        if Card.Lines.First() then
            repeat
                Rows += Format(Card.Lines.LineNo.AsInteger()) + ',';
            until not Card.Lines.Next();
    end;

    [TryFunction]
    local procedure TryDetailHost(var Card: TestPage "LT PV Host"; var Rows: Text)
    begin
        Rows := '';
        if Card.Detail.First() then
            repeat
                Rows += Card.Detail.Info.Value + ',';
            until not Card.Detail.Next();
    end;

    [TryFunction]
    local procedure TryVisibleHost(var Card: TestPage "LT PV Host"; var Flags: Text)
    begin
        Flags := 'lines=' + Format(Card.Lines.Visible()) + ',detail=' + Format(Card.Detail.Visible());
    end;

    local procedure SnapHost(Name: Text; var Card: TestPage "LT PV Host")
    var
        Rows: Text;
        Flags: Text;
        Result: Text;
    begin
        Result := 'vis(' + ErrorOr(TryVisibleHost(Card, Flags), Flags) + ')';
        Result += ' lines=' + ErrorOr(TryLinesHost(Card, Rows), Rows);
        Result += ' detail=' + ErrorOr(TryDetailHost(Card, Rows), Rows);
        Say(Name, Result);
    end;

    [TryFunction]
    local procedure TryLinesLitBoth(var Card: TestPage "LT PV Host Lit Both"; var Rows: Text)
    begin
        Rows := '';
        if Card.Lines.First() then
            repeat
                Rows += Format(Card.Lines.LineNo.AsInteger()) + ',';
            until not Card.Lines.Next();
    end;

    [TryFunction]
    local procedure TryDetailLitBoth(var Card: TestPage "LT PV Host Lit Both"; var Rows: Text)
    begin
        Rows := '';
        if Card.Detail.First() then
            repeat
                Rows += Card.Detail.Info.Value + ',';
            until not Card.Detail.Next();
    end;

    [TryFunction]
    local procedure TryVisibleLitBoth(var Card: TestPage "LT PV Host Lit Both"; var Flags: Text)
    begin
        Flags := 'lines=' + Format(Card.Lines.Visible()) + ',detail=' + Format(Card.Detail.Visible());
    end;

    local procedure SnapLitBoth(Name: Text; var Card: TestPage "LT PV Host Lit Both")
    var
        Rows: Text;
        Flags: Text;
        Result: Text;
    begin
        Result := 'vis(' + ErrorOr(TryVisibleLitBoth(Card, Flags), Flags) + ')';
        Result += ' lines=' + ErrorOr(TryLinesLitBoth(Card, Rows), Rows);
        Result += ' detail=' + ErrorOr(TryDetailLitBoth(Card, Rows), Rows);
        Say(Name, Result);
    end;

    [TryFunction]
    local procedure TryLinesLitProv(var Card: TestPage "LT PV Host Lit Prov"; var Rows: Text)
    begin
        Rows := '';
        if Card.Lines.First() then
            repeat
                Rows += Format(Card.Lines.LineNo.AsInteger()) + ',';
            until not Card.Lines.Next();
    end;

    [TryFunction]
    local procedure TryDetailLitProv(var Card: TestPage "LT PV Host Lit Prov"; var Rows: Text)
    begin
        Rows := '';
        if Card.Detail.First() then
            repeat
                Rows += Card.Detail.Info.Value + ',';
            until not Card.Detail.Next();
    end;

    [TryFunction]
    local procedure TryVisibleLitProv(var Card: TestPage "LT PV Host Lit Prov"; var Flags: Text)
    begin
        Flags := 'lines=' + Format(Card.Lines.Visible()) + ',detail=' + Format(Card.Detail.Visible());
    end;

    local procedure SnapLitProv(Name: Text; var Card: TestPage "LT PV Host Lit Prov")
    var
        Rows: Text;
        Flags: Text;
        Result: Text;
    begin
        Result := 'vis(' + ErrorOr(TryVisibleLitProv(Card, Flags), Flags) + ')';
        Result += ' lines=' + ErrorOr(TryLinesLitProv(Card, Rows), Rows);
        Result += ' detail=' + ErrorOr(TryDetailLitProv(Card, Rows), Rows);
        Say(Name, Result);
    end;

    [TryFunction]
    local procedure TryLinesLitLinked(var Card: TestPage "LT PV Host Lit Linked"; var Rows: Text)
    begin
        Rows := '';
        if Card.Lines.First() then
            repeat
                Rows += Format(Card.Lines.LineNo.AsInteger()) + ',';
            until not Card.Lines.Next();
    end;

    [TryFunction]
    local procedure TryDetailLitLinked(var Card: TestPage "LT PV Host Lit Linked"; var Rows: Text)
    begin
        Rows := '';
        if Card.Detail.First() then
            repeat
                Rows += Card.Detail.Info.Value + ',';
            until not Card.Detail.Next();
    end;

    [TryFunction]
    local procedure TryVisibleLitLinked(var Card: TestPage "LT PV Host Lit Linked"; var Flags: Text)
    begin
        Flags := 'lines=' + Format(Card.Lines.Visible()) + ',detail=' + Format(Card.Detail.Visible());
    end;

    local procedure SnapLitLinked(Name: Text; var Card: TestPage "LT PV Host Lit Linked")
    var
        Rows: Text;
        Flags: Text;
        Result: Text;
    begin
        Result := 'vis(' + ErrorOr(TryVisibleLitLinked(Card, Flags), Flags) + ')';
        Result += ' lines=' + ErrorOr(TryLinesLitLinked(Card, Rows), Rows);
        Result += ' detail=' + ErrorOr(TryDetailLitLinked(Card, Rows), Rows);
        Say(Name, Result);
    end;

    [TryFunction]
    local procedure TryLinesDoc(var Card: TestPage "LT PV Host Document"; var Rows: Text)
    begin
        Rows := '';
        if Card.Lines.First() then
            repeat
                Rows += Format(Card.Lines.LineNo.AsInteger()) + ',';
            until not Card.Lines.Next();
    end;

    [TryFunction]
    local procedure TryDetailDoc(var Card: TestPage "LT PV Host Document"; var Rows: Text)
    begin
        Rows := '';
        if Card.Detail.First() then
            repeat
                Rows += Card.Detail.Info.Value + ',';
            until not Card.Detail.Next();
    end;

    [TryFunction]
    local procedure TryVisibleDoc(var Card: TestPage "LT PV Host Document"; var Flags: Text)
    begin
        Flags := 'lines=' + Format(Card.Lines.Visible()) + ',detail=' + Format(Card.Detail.Visible());
    end;

    local procedure SnapDoc(Name: Text; var Card: TestPage "LT PV Host Document")
    var
        Rows: Text;
        Flags: Text;
        Result: Text;
    begin
        Result := 'vis(' + ErrorOr(TryVisibleDoc(Card, Flags), Flags) + ')';
        Result += ' lines=' + ErrorOr(TryLinesDoc(Card, Rows), Rows);
        Result += ' detail=' + ErrorOr(TryDetailDoc(Card, Rows), Rows);
        Say(Name, Result);
    end;

    [TryFunction]
    local procedure TryLinesListPlus(var Card: TestPage "LT PV Host ListPlus"; var Rows: Text)
    begin
        Rows := '';
        if Card.Lines.First() then
            repeat
                Rows += Format(Card.Lines.LineNo.AsInteger()) + ',';
            until not Card.Lines.Next();
    end;

    [TryFunction]
    local procedure TryDetailListPlus(var Card: TestPage "LT PV Host ListPlus"; var Rows: Text)
    begin
        Rows := '';
        if Card.Detail.First() then
            repeat
                Rows += Card.Detail.Info.Value + ',';
            until not Card.Detail.Next();
    end;

    [TryFunction]
    local procedure TryVisibleListPlus(var Card: TestPage "LT PV Host ListPlus"; var Flags: Text)
    begin
        Flags := 'lines=' + Format(Card.Lines.Visible()) + ',detail=' + Format(Card.Detail.Visible());
    end;

    local procedure SnapListPlus(Name: Text; var Card: TestPage "LT PV Host ListPlus")
    var
        Rows: Text;
        Flags: Text;
        Result: Text;
    begin
        Result := 'vis(' + ErrorOr(TryVisibleListPlus(Card, Flags), Flags) + ')';
        Result += ' lines=' + ErrorOr(TryLinesListPlus(Card, Rows), Rows);
        Result += ' detail=' + ErrorOr(TryDetailListPlus(Card, Rows), Rows);
        Say(Name, Result);
    end;

    [TryFunction]
    local procedure TryLinesTemp(var Card: TestPage "LT PV Host Temp"; var Rows: Text)
    begin
        Rows := '';
        if Card.Lines.First() then
            repeat
                Rows += Format(Card.Lines.LineNo.AsInteger()) + ',';
            until not Card.Lines.Next();
    end;

    [TryFunction]
    local procedure TryDetailTemp(var Card: TestPage "LT PV Host Temp"; var Rows: Text)
    begin
        Rows := '';
        if Card.Detail.First() then
            repeat
                Rows += Card.Detail.Info.Value + ',';
            until not Card.Detail.Next();
    end;

    [TryFunction]
    local procedure TryVisibleTemp(var Card: TestPage "LT PV Host Temp"; var Flags: Text)
    begin
        Flags := 'lines=' + Format(Card.Lines.Visible()) + ',detail=' + Format(Card.Detail.Visible());
    end;

    local procedure SnapTemp(Name: Text; var Card: TestPage "LT PV Host Temp")
    var
        Rows: Text;
        Flags: Text;
        Result: Text;
    begin
        Result := 'vis(' + ErrorOr(TryVisibleTemp(Card, Flags), Flags) + ')';
        Result += ' lines=' + ErrorOr(TryLinesTemp(Card, Rows), Rows);
        Result += ' detail=' + ErrorOr(TryDetailTemp(Card, Rows), Rows);
        Say(Name, Result);
    end;

    [TryFunction]
    local procedure TryLinesTwo(var Card: TestPage "LT PV Host Two"; var Rows: Text)
    begin
        Rows := '';
        if Card.Lines.First() then
            repeat
                Rows += Format(Card.Lines.LineNo.AsInteger()) + ',';
            until not Card.Lines.Next();
    end;

    [TryFunction]
    local procedure TryDetailTwo(var Card: TestPage "LT PV Host Two"; var Rows: Text)
    begin
        Rows := '';
        if Card.Detail.First() then
            repeat
                Rows += Card.Detail.Info.Value + ',';
            until not Card.Detail.Next();
    end;

    [TryFunction]
    local procedure TryDetail2Two(var Card: TestPage "LT PV Host Two"; var Rows: Text)
    begin
        Rows := '';
        if Card.Detail2.First() then
            repeat
                Rows += Card.Detail2.Info.Value + ',';
            until not Card.Detail2.Next();
    end;

    [TryFunction]
    local procedure TryVisibleTwo(var Card: TestPage "LT PV Host Two"; var Flags: Text)
    begin
        Flags := 'lines=' + Format(Card.Lines.Visible()) + ',detail=' + Format(Card.Detail.Visible());
    end;

    local procedure SnapTwo(Name: Text; var Card: TestPage "LT PV Host Two")
    var
        Rows: Text;
        Flags: Text;
        Result: Text;
    begin
        Result := 'vis(' + ErrorOr(TryVisibleTwo(Card, Flags), Flags) + ')';
        Result += ' lines=' + ErrorOr(TryLinesTwo(Card, Rows), Rows);
        Result += ' detail=' + ErrorOr(TryDetailTwo(Card, Rows), Rows);
        Result += ' detail2=' + ErrorOr(TryDetail2Two(Card, Rows), Rows);
        Say(Name, Result);
    end;

    [TryFunction]
    local procedure TryLinesBase(var Card: TestPage "LT PV Host Base"; var Rows: Text)
    begin
        Rows := '';
        if Card.Lines.First() then
            repeat
                Rows += Format(Card.Lines.LineNo.AsInteger()) + ',';
            until not Card.Lines.Next();
    end;

    [TryFunction]
    local procedure TryDetailBase(var Card: TestPage "LT PV Host Base"; var Rows: Text)
    begin
        Rows := '';
        if Card.Detail.First() then
            repeat
                Rows += Card.Detail.Info.Value + ',';
            until not Card.Detail.Next();
    end;

    [TryFunction]
    local procedure TryVisibleBase(var Card: TestPage "LT PV Host Base"; var Flags: Text)
    begin
        Flags := 'lines=' + Format(Card.Lines.Visible()) + ',detail=' + Format(Card.Detail.Visible());
    end;

    local procedure SnapBase(Name: Text; var Card: TestPage "LT PV Host Base")
    var
        Rows: Text;
        Flags: Text;
        Result: Text;
    begin
        Result := 'vis(' + ErrorOr(TryVisibleBase(Card, Flags), Flags) + ')';
        Result += ' lines=' + ErrorOr(TryLinesBase(Card, Rows), Rows);
        Result += ' detail=' + ErrorOr(TryDetailBase(Card, Rows), Rows);
        Say(Name, Result);
    end;

    [Test]
    procedure Provider_BothVisible_OpenViewAndGoToKey()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        SnapHost('open', Card);
        Card.GoToKey('H1');
        SnapHost('h1', Card);
        Card.GoToKey('H2');
        SnapHost('h2', Card);
        Card.GoToKey('H1');
        SnapHost('h1_again', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=Yes,detail=Yes) lines=10,20, detail=twenty, log=[host-open | lines-open() | detail-open() | host-row(H1) | detail-row() | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h1', 'vis(lines=Yes,detail=Yes) lines=10,20, detail=twenty, log=[host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h2', 'vis(lines=Yes,detail=Yes) lines= detail= log=[host-row(H1) | host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Expect('h1_again', 'vis(lines=Yes,detail=Yes) lines=10,20, detail=twenty, log=[host-row(H1) | lines-row(20) | detail-row(twenty) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_BothHidden_OpenViewAndGoToKey()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('hidden-both');
        Card.OpenView();
        SnapHost('open', Card);
        Card.GoToKey('H1');
        SnapHost('h1', Card);
        Card.GoToKey('H2');
        SnapHost('h2', Card);
        Card.GoToKey('H1');
        SnapHost('h1_again', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=No,detail=No) lines=10,20, detail=twenty, log=[host-open | lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h1', 'vis(lines=No,detail=No) lines=10,20, detail=twenty, log=[host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h2', 'vis(lines=No,detail=No) lines= detail= log=[host-row(H1) | host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Expect('h1_again', 'vis(lines=No,detail=No) lines=10,20, detail=twenty, log=[host-row(H1) | lines-row(20) | detail-row(twenty) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_OnlyProviderHidden_OpenViewAndGoToKey()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('hidden-provider');
        Card.OpenView();
        SnapHost('open', Card);
        Card.GoToKey('H1');
        SnapHost('h1', Card);
        Card.GoToKey('H2');
        SnapHost('h2', Card);
        Card.GoToKey('H1');
        SnapHost('h1_again', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=No,detail=Yes) lines=10,20, detail=twenty, log=[host-open | lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h1', 'vis(lines=No,detail=Yes) lines=10,20, detail=twenty, log=[host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h2', 'vis(lines=No,detail=Yes) lines= detail= log=[host-row(H1) | host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Expect('h1_again', 'vis(lines=No,detail=Yes) lines=10,20, detail=twenty, log=[host-row(H1) | lines-row(20) | detail-row(twenty) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_OnlyLinkedHidden_OpenViewAndGoToKey()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('hidden-linked');
        Card.OpenView();
        SnapHost('open', Card);
        Card.GoToKey('H1');
        SnapHost('h1', Card);
        Card.GoToKey('H2');
        SnapHost('h2', Card);
        Card.GoToKey('H1');
        SnapHost('h1_again', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=Yes,detail=No) lines=10,20, detail=twenty, log=[host-open | lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h1', 'vis(lines=Yes,detail=No) lines=10,20, detail=twenty, log=[host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h2', 'vis(lines=Yes,detail=No) lines= detail= log=[host-row(H1) | host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Expect('h1_again', 'vis(lines=Yes,detail=No) lines=10,20, detail=twenty, log=[host-row(H1) | lines-row(20) | detail-row(twenty) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_BothVisible_OpenEditNextPreviousGoToRecord()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenEdit();
        SnapHost('open', Card);
        Card.Next();
        SnapHost('next', Card);
        Card.Previous();
        SnapHost('previous', Card);
        Card.GoToRecord(Header('H2'));
        SnapHost('gotorecord_h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=Yes,detail=Yes) lines=10,20,0, detail= log=[host-open | lines-open() | detail-open() | host-row(H1) | lines-row(0) | lines-row(0) | detail-row() | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty) | lines-row(0) | detail-row()]');
        Observer.Expect('next', 'vis(lines=Yes,detail=Yes) lines= detail= log=[host-row(H2) | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Expect('previous', 'vis(lines=Yes,detail=Yes) lines=10,20,0, detail= log=[host-row(H1) | lines-row(20) | detail-row(twenty) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty) | lines-row(0) | detail-row()]');
        Observer.Expect('gotorecord_h2', 'vis(lines=Yes,detail=Yes) lines= detail= log=[host-row(H1) | host-row(H2) | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_BothHidden_OpenEditNextPreviousGoToRecord()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('hidden-both');
        Card.OpenEdit();
        SnapHost('open', Card);
        Card.Next();
        SnapHost('next', Card);
        Card.Previous();
        SnapHost('previous', Card);
        Card.GoToRecord(Header('H2'));
        SnapHost('gotorecord_h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=No,detail=No) lines=10,20,0, detail= log=[host-open | lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty) | lines-row(0) | detail-row()]');
        Observer.Expect('next', 'vis(lines=No,detail=No) lines= detail= log=[host-row(H2) | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Expect('previous', 'vis(lines=No,detail=No) lines=10,20,0, detail= log=[host-row(H1) | lines-row(20) | detail-row(twenty) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty) | lines-row(0) | detail-row()]');
        Observer.Expect('gotorecord_h2', 'vis(lines=No,detail=No) lines= detail= log=[host-row(H1) | host-row(H2) | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_OnlyProviderHidden_OpenEditNextPreviousGoToRecord()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('hidden-provider');
        Card.OpenEdit();
        SnapHost('open', Card);
        Card.Next();
        SnapHost('next', Card);
        Card.Previous();
        SnapHost('previous', Card);
        Card.GoToRecord(Header('H2'));
        SnapHost('gotorecord_h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=No,detail=Yes) lines=10,20,0, detail= log=[host-open | lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty) | lines-row(0) | detail-row()]');
        Observer.Expect('next', 'vis(lines=No,detail=Yes) lines= detail= log=[host-row(H2) | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Expect('previous', 'vis(lines=No,detail=Yes) lines=10,20,0, detail= log=[host-row(H1) | lines-row(20) | detail-row(twenty) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty) | lines-row(0) | detail-row()]');
        Observer.Expect('gotorecord_h2', 'vis(lines=No,detail=Yes) lines= detail= log=[host-row(H1) | host-row(H2) | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_OnlyLinkedHidden_OpenEditNextPreviousGoToRecord()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('hidden-linked');
        Card.OpenEdit();
        SnapHost('open', Card);
        Card.Next();
        SnapHost('next', Card);
        Card.Previous();
        SnapHost('previous', Card);
        Card.GoToRecord(Header('H2'));
        SnapHost('gotorecord_h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=Yes,detail=No) lines=10,20,0, detail= log=[host-open | lines-open() | detail-open() | host-row(H1) | lines-row(0) | lines-row(0) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty) | lines-row(0) | detail-row()]');
        Observer.Expect('next', 'vis(lines=Yes,detail=No) lines= detail= log=[host-row(H2) | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Expect('previous', 'vis(lines=Yes,detail=No) lines=10,20,0, detail= log=[host-row(H1) | lines-row(20) | detail-row(twenty) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty) | lines-row(0) | detail-row()]');
        Observer.Expect('gotorecord_h2', 'vis(lines=Yes,detail=No) lines= detail= log=[host-row(H1) | host-row(H2) | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_BothVisible_OpenNewSetKeyClose()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenNew();
        SnapHost('new', Card);
        Card."No.".SetValue('H3');
        SnapHost('keyed', Card);
        Card.Close();
        Observer.Observe('stored', StoredKey('H3') + ' lines=' + Format(CountLines('H3')));
        Observer.Expect('new', 'vis(lines=Yes,detail=Yes) lines= detail= log=[host-open | lines-open() | detail-open() | host-row() | lines-row(0) | lines-row(0) | lines-row(0) | detail-row() | lines-row(0) | lines-row(0) | lines-row(0) | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Expect('keyed', 'vis(lines=Yes,detail=Yes) lines= detail= log=[]');
        Observer.Expect('stored', '<none> lines=0');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_BothHidden_OpenNewSetKeyClose()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('hidden-both');
        Card.OpenNew();
        SnapHost('new', Card);
        Card."No.".SetValue('H3');
        SnapHost('keyed', Card);
        Card.Close();
        Observer.Observe('stored', StoredKey('H3') + ' lines=' + Format(CountLines('H3')));
        Observer.Expect('new', 'vis(lines=No,detail=No) lines= detail= log=[host-open | lines-open() | detail-open() | host-row() | lines-row(0) | lines-row(0) | lines-row(0) | detail-row() | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Expect('keyed', 'vis(lines=No,detail=No) lines= detail= log=[]');
        Observer.Expect('stored', '<none> lines=0');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_OnlyProviderHidden_OpenNewSetKeyClose()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('hidden-provider');
        Card.OpenNew();
        SnapHost('new', Card);
        Card."No.".SetValue('H3');
        SnapHost('keyed', Card);
        Card.Close();
        Observer.Observe('stored', StoredKey('H3') + ' lines=' + Format(CountLines('H3')));
        Observer.Expect('new', 'vis(lines=No,detail=Yes) lines= detail= log=[host-open | lines-open() | detail-open() | host-row() | lines-row(0) | lines-row(0) | lines-row(0) | detail-row() | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Expect('keyed', 'vis(lines=No,detail=Yes) lines= detail= log=[]');
        Observer.Expect('stored', '<none> lines=0');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_OnlyLinkedHidden_OpenNewSetKeyClose()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('hidden-linked');
        Card.OpenNew();
        SnapHost('new', Card);
        Card."No.".SetValue('H3');
        SnapHost('keyed', Card);
        Card.Close();
        Observer.Observe('stored', StoredKey('H3') + ' lines=' + Format(CountLines('H3')));
        Observer.Expect('new', 'vis(lines=Yes,detail=No) lines= detail= log=[host-open | lines-open() | detail-open() | host-row() | lines-row(0) | lines-row(0) | lines-row(0) | lines-row(0) | lines-row(0) | lines-row(0) | detail-row() | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Expect('keyed', 'vis(lines=Yes,detail=No) lines= detail= log=[]');
        Observer.Expect('stored', '<none> lines=0');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_HiddenUntilKeyIsSet_OpenNewSetKeyClose()
    var
        Card: TestPage "LT PV Host";
    begin
        Seed();
        Log.Reset('by-key');
        Card.OpenNew();
        SnapHost('new', Card);
        Card."No.".SetValue('H3');
        SnapHost('keyed', Card);
        Card.Close();
        Observer.Observe('stored', StoredKey('H3') + ' lines=' + Format(CountLines('H3')));
        Observer.Expect('new', 'vis(lines=No,detail=No) lines= detail= log=[host-open | lines-open() | detail-open() | host-row() | lines-row(0) | lines-row(0) | lines-row(0) | detail-row() | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Expect('keyed', 'vis(lines=No,detail=No) lines= detail= log=[]');
        Observer.Expect('stored', '<none> lines=0');
        Observer.Verify();
    end;

    local procedure StoredKey(No: Code[20]): Text
    var
        Row: Record "PVD Header";
    begin
        if Row.Get(No) then
            exit(Row."No.");
        exit('<none>');
    end;

    local procedure CountLines(HeaderNo: Code[20]): Integer
    var
        Line: Record "PVD Line";
    begin
        Line.SetRange("Header No.", HeaderNo);
        exit(Line.Count());
    end;

    [Test]
    procedure Provider_LiteralBothHidden_OpenView()
    var
        Card: TestPage "LT PV Host Lit Both";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        SnapLitBoth('open', Card);
        Card.GoToKey('H1');
        SnapLitBoth('h1', Card);
        Card.GoToKey('H2');
        SnapLitBoth('h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(ERR[The part with ID = n was not found on the page.]) lines=ERR[The part with ID = n was not found on the page.] detail=ERR[The part with ID = n was not found on the page.] log=[host-open | host-row(H1)]');
        Observer.Expect('h1', 'vis(ERR[The part with ID = n was not found on the page.]) lines=ERR[The part with ID = n was not found on the page.] detail=ERR[The part with ID = n was not found on the page.] log=[host-row(H1)]');
        Observer.Expect('h2', 'vis(ERR[The part with ID = n was not found on the page.]) lines=ERR[The part with ID = n was not found on the page.] detail=ERR[The part with ID = n was not found on the page.] log=[host-row(H1) | host-row(H2)]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_LiteralOnlyProviderHidden_OpenView()
    var
        Card: TestPage "LT PV Host Lit Prov";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        SnapLitProv('open', Card);
        Card.GoToKey('H1');
        SnapLitProv('h1', Card);
        Card.GoToKey('H2');
        SnapLitProv('h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=No,detail=Yes) lines=10,20, detail=twenty, log=[host-open | lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h1', 'vis(lines=No,detail=Yes) lines=10,20, detail=twenty, log=[host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h2', 'vis(lines=No,detail=Yes) lines= detail= log=[host-row(H1) | host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_LiteralOnlyLinkedHidden_OpenView()
    var
        Card: TestPage "LT PV Host Lit Linked";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        SnapLitLinked('open', Card);
        Card.GoToKey('H1');
        SnapLitLinked('h1', Card);
        Card.GoToKey('H2');
        SnapLitLinked('h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(ERR[The part with ID = n was not found on the page.]) lines=10,20, detail=ERR[The part with ID = n was not found on the page.] log=[host-open | lines-open() | host-row(H1) | lines-row(10) | lines-row(20)]');
        Observer.Expect('h1', 'vis(ERR[The part with ID = n was not found on the page.]) lines=10,20, detail=ERR[The part with ID = n was not found on the page.] log=[host-row(H1) | lines-row(10) | lines-row(20)]');
        Observer.Expect('h2', 'vis(ERR[The part with ID = n was not found on the page.]) lines= detail=ERR[The part with ID = n was not found on the page.] log=[host-row(H1) | host-row(H2) | lines-row(0)]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_DocumentHost_OpenViewVisibleAndHidden()
    var
        Card: TestPage "LT PV Host Document";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        SnapDoc('open', Card);
        Card.GoToKey('H1');
        SnapDoc('h1', Card);
        Card.GoToKey('H2');
        SnapDoc('h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=Yes,detail=Yes) lines=10,20, detail=twenty, log=[host-open | lines-open() | detail-open() | host-row(H1) | detail-row() | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h1', 'vis(lines=Yes,detail=Yes) lines=10,20, detail=twenty, log=[host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h2', 'vis(lines=Yes,detail=Yes) lines= detail= log=[host-row(H1) | host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_DocumentHost_BothHidden()
    var
        Card: TestPage "LT PV Host Document";
    begin
        Seed();
        Log.Reset('hidden-both');
        Card.OpenView();
        SnapDoc('open', Card);
        Card.GoToKey('H1');
        SnapDoc('h1', Card);
        Card.GoToKey('H2');
        SnapDoc('h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=No,detail=No) lines=10,20, detail=twenty, log=[host-open | lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h1', 'vis(lines=No,detail=No) lines=10,20, detail=twenty, log=[host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h2', 'vis(lines=No,detail=No) lines= detail= log=[host-row(H1) | host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_ListPlusHost_OpenViewVisibleAndHidden()
    var
        Card: TestPage "LT PV Host ListPlus";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        SnapListPlus('open', Card);
        Card.GoToKey('H1');
        SnapListPlus('h1', Card);
        Card.GoToKey('H2');
        SnapListPlus('h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=Yes,detail=Yes) lines=10,20, detail=twenty, log=[host-open | lines-open() | detail-open() | host-row(H1) | detail-row() | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h1', 'vis(lines=Yes,detail=Yes) lines=10,20, detail=twenty, log=[lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h2', 'vis(lines=Yes,detail=Yes) lines= detail= log=[host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_ListPlusHost_BothHidden()
    var
        Card: TestPage "LT PV Host ListPlus";
    begin
        Seed();
        Log.Reset('hidden-both');
        Card.OpenView();
        SnapListPlus('open', Card);
        Card.GoToKey('H1');
        SnapListPlus('h1', Card);
        Card.GoToKey('H2');
        SnapListPlus('h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=No,detail=No) lines=10,20, detail=twenty, log=[host-open | lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h1', 'vis(lines=No,detail=No) lines=10,20, detail=twenty, log=[lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h2', 'vis(lines=No,detail=No) lines= detail= log=[host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_TemporarySourceHost_OpenView()
    var
        Card: TestPage "LT PV Host Temp";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        SnapTemp('open', Card);
        Card.GoToKey('H1');
        SnapTemp('h1', Card);
        Card.GoToKey('H2');
        SnapTemp('h2', Card);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Provider_TwoLinkedParts_OpenViewAndEmptyProvider()
    var
        Card: TestPage "LT PV Host Two";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        SnapTwo('open', Card);
        Card.GoToKey('H1');
        SnapTwo('h1', Card);
        Card.GoToKey('H2');
        SnapTwo('h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=No,detail=No) lines= detail= log=[host-open | lines-open() | detail-open() | lines-row(0) | detail-row()]');
        Observer.Expect('open', 'vis(lines=Yes,detail=Yes) lines=10,20, detail=twenty, detail2= log=[host-open | lines-open() | detail-open() | detail-open() | host-row(H1) | detail-row() | detail-row() | lines-row(10) | detail-row(ten) | detail-row() | lines-row(20) | detail-row(twenty) | detail-row()]');
        Observer.Expect('h1', 'vis(lines=Yes,detail=Yes) lines=10,20, detail=twenty, detail2= log=[host-row(H1) | lines-row(10) | detail-row(ten) | detail-row() | lines-row(20) | detail-row(twenty) | detail-row()]');
        Observer.Expect('h2', 'vis(lines=Yes,detail=Yes) lines= detail= detail2= log=[host-row(H1) | host-row(H2) | lines-row(0) | detail-row() | detail-row()]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_TwoLinkedParts_OpenNew()
    var
        Card: TestPage "LT PV Host Two";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenNew();
        SnapTwo('new', Card);
        Card."No.".SetValue('H3');
        SnapTwo('keyed', Card);
        Card.Close();
        Observer.Expect('new', 'vis(lines=Yes,detail=Yes) lines= detail= detail2= log=[host-open | lines-open() | detail-open() | detail-open() | host-row() | lines-row(0) | lines-row(0) | lines-row(0) | detail-row() | detail-row() | lines-row(0) | lines-row(0) | lines-row(0) | lines-row(0) | lines-row(0) | lines-row(0)]');
        Observer.Expect('keyed', 'vis(lines=Yes,detail=Yes) lines= detail= detail2= log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_PartsAddedByPageExtensionInFactBoxes_OpenView()
    var
        Card: TestPage "LT PV Host Base";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenView();
        SnapBase('open', Card);
        Card.GoToKey('H1');
        SnapBase('h1', Card);
        Card.GoToKey('H2');
        SnapBase('h2', Card);
        Card.Close();
        Observer.Expect('open', 'vis(lines=Yes,detail=Yes) lines=10,20, detail=twenty, log=[lines-open() | detail-open() | base-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h1', 'vis(lines=Yes,detail=Yes) lines=10,20, detail=twenty, log=[base-row(H1) | lines-row(10) | detail-row(ten) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('h2', 'vis(lines=Yes,detail=Yes) lines= detail= log=[base-row(H1) | base-row(H2) | lines-row(0) | detail-row()]');
        Observer.Verify();
    end;

    [Test]
    procedure Provider_PartsAddedByPageExtensionInFactBoxes_OpenNew()
    var
        Card: TestPage "LT PV Host Base";
    begin
        Seed();
        Log.Reset('both');
        Card.OpenNew();
        SnapBase('new', Card);
        Card."No.".SetValue('H3');
        SnapBase('keyed', Card);
        Card.Close();
        Observer.Expect('new', 'vis(lines=Yes,detail=Yes) lines= detail= log=[lines-open() | detail-open() | base-row() | lines-row(0) | detail-row()]');
        Observer.Expect('keyed', 'vis(lines=Yes,detail=Yes) lines= detail= log=[lines-row(0)]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HostHandler')]
    procedure Provider_PageRun_OnRowWithoutLines()
    var
        Row: Record "PVD Header";
    begin
        Seed();
        Log.Reset('both');
        Row.Get('H2');
        Page.Run(Page::"LT PV Host", Row);
        Observer.Observe('run_h2', Log.Dump());
        Observer.Expect('run_h2', '[host-open | lines-open() | detail-open() | host-row(H2) | lines-row(0) | lines-row(0) | detail-row() | lines-row(0) | lines-row(0) | lines-row(0) | handler(H2)]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TwoHandler')]
    procedure Provider_PageRun_OnNewlyInsertedRowWithoutLines()
    var
        Row: Record "PVD Header";
    begin
        Seed();
        Log.Reset('both');
        Row.Init();
        Row."No." := 'H4';
        Row.Insert();
        Page.Run(Page::"LT PV Host Two", Row);
        Observer.Observe('run_h4_two', Log.Dump());
        Observer.Expect('run_h4_two', '[host-open | lines-open() | detail-open() | detail-open() | host-row(H4) | lines-row(0) | lines-row(0) | detail-row() | detail-row() | lines-row(0) | lines-row(0) | lines-row(0) | handler(H4)]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HostHandler')]
    procedure Provider_PageRun_BothHiddenOnRowWithLines()
    var
        Row: Record "PVD Header";
    begin
        Seed();
        Log.Reset('hidden-both');
        Row.Get('H1');
        Page.Run(Page::"LT PV Host", Row);
        Observer.Observe('run_h1_hidden', Log.Dump());
        Observer.Expect('run_h1_hidden', '[host-open | lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | handler(H1)]');
        Observer.Verify();
    end;

    [PageHandler]
    procedure TwoHandler(var Card: TestPage "LT PV Host Two")
    begin
        Log.Add('handler(' + Card."No.".Value + ')');
    end;

    [PageHandler]
    procedure HostHandler(var Card: TestPage "LT PV Host")
    begin
        Log.Add('handler(' + Card."No.".Value + ')');
    end;
}
