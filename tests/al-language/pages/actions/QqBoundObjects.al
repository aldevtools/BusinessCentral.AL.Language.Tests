// Objects for QqBoundProps.al (AL Runner issue 3762): actions and an action group whose Visible or Enabled is bound to a procedure call.
// The compiler accepts this on an action with warning AL0573 ("Procedure calls is not valid for client expressions"); on a field control it is
// error AL0322 (must-not-compile case 2000). Every procedure the page names writes to the log codeunit, so a test can see whether it ran.

table 87200 "LT QQ Bound Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The log of the procedures and triggers that ran. SingleInstance: used by the test codeunit "LT QQ Bound Props" only.
codeunit 87201 "LT QQ Bound Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ',';
        Entries += Entry;
    end;

    procedure Read(): Text
    begin
        exit(Entries);
    end;

    procedure Clear()
    begin
        Entries := '';
    end;
}

page 87202 "LT QQ Bound Card"
{
    PageType = Card;
    SourceTable = "LT QQ Bound Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Flag; Rec.Flag) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(VisibleTrueProc)
            {
                ApplicationArea = All;
                Visible = IsAllowed();
                trigger OnAction()
                begin
                    Log.Add('action VisibleTrueProc');
                end;
            }
            action(VisibleFalseProc)
            {
                ApplicationArea = All;
                Visible = IsDenied();
                trigger OnAction()
                begin
                    Log.Add('action VisibleFalseProc');
                end;
            }
            action(EnabledTrueProc)
            {
                ApplicationArea = All;
                Enabled = IsAllowed();
                trigger OnAction()
                begin
                    Log.Add('action EnabledTrueProc');
                end;
            }
            action(EnabledFalseProc)
            {
                ApplicationArea = All;
                Enabled = IsDenied();
                trigger OnAction()
                begin
                    Log.Add('action EnabledFalseProc');
                end;
            }
            action(VisibleVariable)
            {
                ApplicationArea = All;
                Visible = AllowedVar;
                trigger OnAction()
                begin
                    Log.Add('action VisibleVariable');
                end;
            }
            action(EnabledVariable)
            {
                ApplicationArea = All;
                Enabled = AllowedVar;
                trigger OnAction()
                begin
                    Log.Add('action EnabledVariable');
                end;
            }
            action(NoProperty)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('action NoProperty');
                end;
            }
            group(GroupVisibleProc)
            {
                Visible = IsAllowed();
                action(InGroupVisibleProc)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                        Log.Add('action InGroupVisibleProc');
                    end;
                }
            }
            group(GroupVisibleVariable)
            {
                Visible = AllowedVar;
                action(InGroupVisibleVariable)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                        Log.Add('action InGroupVisibleVariable');
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        AllowedVar := true;
        Log.Add('OnOpenPage');
    end;

    var
        Log: Codeunit "LT QQ Bound Log";
        AllowedVar: Boolean;

    procedure IsAllowed(): Boolean
    begin
        Log.Add('IsAllowed');
        exit(true);
    end;

    procedure IsDenied(): Boolean
    begin
        Log.Add('IsDenied');
        exit(false);
    end;
}
