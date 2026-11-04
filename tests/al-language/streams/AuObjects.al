// Objects for the LT AU probes (corpus issue 645): a control add-in with events, a page that hosts it, a page that hosts the
// System Application's BusinessChart add-in, and the tables they use.
using System.Integration;
using System.Visualization;

controladdin "LT AU Events Addin"
{
    RequestedHeight = 50;
    RequestedWidth = 50;

    procedure Ping(Message: Text);
    event Ready();
    event Answered(Answer: Text);
}

table 80100 "LT AU Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 80101 "LT AU Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; EntryNo; Integer) { AutoIncrement = true; }
        field(2; What; Text[100]) { }
    }

    keys
    {
        key(PK; EntryNo) { Clustered = true; }
    }
}

page 80102 "LT AU Addin Card"
{
    PageType = Card;
    SourceTable = "LT AU Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NameF; Rec.Name)
            {
                ApplicationArea = All;
            }
            usercontrol(Ctl; "LT AU Events Addin")
            {
                ApplicationArea = All;

                trigger Ready()
                begin
                    AddLog('Ready');
                end;

                trigger Answered(Answer: Text)
                begin
                    AddLog('Answered ' + Answer);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CallPing)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    AddLog('before Ping');
                    CurrPage.Ctl.Ping('hello');
                    AddLog('after Ping');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        AddLog('OnOpenPage');
    end;

    local procedure AddLog(What: Text)
    var
        Log: Record "LT AU Log";
    begin
        Log.Init();
        Log.What := CopyStr(What, 1, MaxStrLen(Log.What));
        Log.Insert(true);
    end;
}

page 80103 "LT AU Chart Card"
{
    PageType = Card;
    SourceTable = "LT AU Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NameF; Rec.Name)
            {
                ApplicationArea = All;
            }
            usercontrol(Chart; BusinessChart)
            {
                ApplicationArea = All;

                trigger AddInReady()
                begin
                    AddLog('AddInReady');
                end;

                trigger Refresh()
                begin
                    AddLog('Refresh');
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Draw)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Buffer: Record "Business Chart Buffer";
                begin
                    Buffer.Initialize();
                    Buffer.AddIntegerMeasure('Count', 1, Enum::"Business Chart Type"::Column);
                    Buffer.SetXAxis('Month', Buffer."Data Type"::String);
                    Buffer.AddColumn('Jan');
                    Buffer.SetValueByIndex(0, 0, 7);
                    AddLog('before UpdateChart');
                    Buffer.UpdateChart(CurrPage.Chart);
                    AddLog('after UpdateChart');
                end;
            }
        }
    }

    local procedure AddLog(What: Text)
    var
        Log: Record "LT AU Log";
    begin
        Log.Init();
        Log.What := CopyStr(What, 1, MaxStrLen(Log.What));
        Log.Insert(true);
    end;
}
