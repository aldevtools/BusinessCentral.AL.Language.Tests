// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-openview-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 95440 and 95441, log codeunit 95442, pages 95443-95446, test codeunit 95449
// Probe: (al-runner issue 6953) a ListPlus host page whose table holds no row, opened with TestPage.OpenView, with a ListPart
// (DelayedInsert, AutoSplitKey) linked to the host key by SubPageLink. The part declares OnNewRecord and OnAfterGetCurrRecord;
// the host declares OnOpenPage, OnNewRecord, OnAfterGetRecord and OnAfterGetCurrRecord. Which triggers run at OpenView and in
// which order, what the host key and the part field read, which triggers run at Close and what is stored. Three hosts: the part
// directly in the content area, the part hidden (Visible = false), and the part inside a group. The same question is pinned
// for Document and Card hosts in PartLineBeforeHostKey.al (QH_OpenView_NoRow_*).
// BC versions: 27+

table 95440 "LT R6953 Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 95441 "LT R6953 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; Description; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Head No.", "Line No.") { Clustered = true; }
    }
}

codeunit 95442 "LT R6953 Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Take(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        Clear(Lines);
        exit('[' + Result + ']');
    end;
}

page 95443 "LT R6953 Lines"
{
    PageType = ListPart;
    SourceTable = "LT R6953 Line";
    ApplicationArea = All;
    UsageCategory = None;
    DelayedInsert = true;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT R6953 Log";
    begin
        Log.Add('LP.OnNewRecord:' + Rec."Head No." + ' below=' + Format(BelowxRec));
        Rec.Description := 'New-line marker';
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT R6953 Log";
    begin
        Log.Add('LP.OnAfterGetCurrRecord:' + Rec."Head No." + '/' + Format(Rec."Line No.") + ' ' + Rec.Description);
    end;
}

page 95444 "LT R6953 Host"
{
    PageType = ListPlus;
    SourceTable = "LT R6953 Head";
    Caption = 'LT R6953 Host';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT R6953 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT R6953 Log";
    begin
        Log.Add('H.OnOpenPage');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT R6953 Log";
    begin
        Log.Add('H.OnNewRecord');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT R6953 Log";
    begin
        Log.Add('H.OnAfterGetRecord:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT R6953 Log";
    begin
        Log.Add('H.OnAfterGetCurrRecord:' + Rec."No.");
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT R6953 Log";
    begin
        Log.Add('H.OnClosePage');
    end;
}

page 95445 "LT R6953 Host Hidden"
{
    PageType = ListPlus;
    SourceTable = "LT R6953 Head";
    Caption = 'LT R6953 Host Hidden';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT R6953 Lines")
            {
                ApplicationArea = All;
                Visible = false;
                SubPageLink = "Head No." = field("No.");
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT R6953 Log";
    begin
        Log.Add('H.OnOpenPage');
    end;
}

page 95446 "LT R6953 Host Group"
{
    PageType = ListPlus;
    SourceTable = "LT R6953 Head";
    Caption = 'LT R6953 Host Group';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            group(LinesGroup)
            {
                ShowCaption = false;
                part(Lines; "LT R6953 Lines")
                {
                    ApplicationArea = All;
                    SubPageLink = "Head No." = field("No.");
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT R6953 Log";
    begin
        Log.Add('H.OnOpenPage');
    end;
}

codeunit 95449 "LT R6953 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT R6953 Head";
        Line: Record "LT R6953 Line";
        Log: Codeunit "LT R6953 Log";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Log.Reset();
    end;

    local procedure Stored(var Observer: Codeunit "Probe Observer")
    var
        Head: Record "LT R6953 Head";
        Line: Record "LT R6953 Line";
    begin
        Observer.Observe('stored_heads', Format(Head.Count()));
        Observer.Observe('stored_lines', Format(Line.Count()));
    end;

    [Test]
    procedure ListPlusHost_OpenView_NoRow_PartTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT R6953 Log";
        Host: TestPage "LT R6953 Host";
    begin
        Seed();
        Host.OpenView();
        Observer.Observe('open_view', Log.Take());
        Observer.Observe('host_no', '[' + Host."No.".Value() + ']');
        Observer.Observe('part_description', '[' + Host.Lines.Description.Value() + ']');
        Observer.Observe('read_log', Log.Take());
        Observer.Observe('caption', Host.Caption());
        Host.Close();
        Observer.Observe('close', Log.Take());
        Stored(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure ListPlusHost_OpenView_NoRow_PartFirst()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT R6953 Log";
        Host: TestPage "LT R6953 Host";
    begin
        Seed();
        Host.OpenView();
        Log.Take();
        Observer.Observe('part_first', Format(Host.Lines.First()));
        Observer.Observe('first_log', Log.Take());
        Host.Close();
        Observer.Observe('close', Log.Take());
        Stored(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure ListPlusHost_OpenView_NoRow_HiddenPart()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT R6953 Log";
        Host: TestPage "LT R6953 Host Hidden";
    begin
        Seed();
        Host.OpenView();
        Observer.Observe('open_view', Log.Take());
        Observer.Observe('caption', Host.Caption());
        Host.Close();
        Observer.Observe('close', Log.Take());
        Stored(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure ListPlusHost_OpenView_NoRow_PartInGroup()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT R6953 Log";
        Host: TestPage "LT R6953 Host Group";
    begin
        Seed();
        Host.OpenView();
        Observer.Observe('open_view', Log.Take());
        Observer.Observe('part_description', '[' + Host.Lines.Description.Value() + ']');
        Host.Close();
        Observer.Observe('close', Log.Take());
        Stored(Observer);
        Observer.Finish();
    end;
}
