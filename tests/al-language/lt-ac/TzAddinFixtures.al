// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-control-addin-object
// Scope: in-scope
// Fixtures for the TZ tests of codeunit 77540 "LT AC ControlAddIn" (ACControlAddIn.al): a control add-in, a card with two usercontrols of it
// (one with Visible = false), a page extension that adds a third usercontrol, and a log. The card calls an add-in procedure from the trigger
// the log's Mode names (OnOpenPage, OnAfterGetRecord, OnAfterGetCurrRecord, OnClosePage), from actions, and from a TryFunction inside an action.
// Not a test file. Only codeunit 77540 uses the SingleInstance log (one owner per SingleInstance fixture).
// BC versions: 27, 28, 29

controladdin "LT TZ Addin"
{
    RequestedHeight = 50;
    RequestedWidth = 50;
    Scripts = 'addin/lt-p121.js';

    procedure Say(Message: Text);
    procedure Count(Value: Integer);
    event ControlAddInReady();
    event Answered(Answer: Text);
}

table 90210 "LT TZ Addin Row"
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

codeunit 90211 "LT TZ Addin Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        CallIn: Text;

    procedure Reset(NewCallIn: Text)
    begin
        Entries := '';
        CallIn := NewCallIn;
    end;

    procedure ShouldCall(Where: Text): Boolean
    begin
        exit(CallIn = Where);
    end;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ' | ';
        Entries += Entry;
    end;

    procedure Dump(): Text
    begin
        exit(Entries);
    end;
}

page 90212 "LT TZ Addin Card"
{
    PageType = Card;
    SourceTable = "LT TZ Addin Row";
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
            usercontrol(Ctl; "LT TZ Addin")
            {
                ApplicationArea = All;

                trigger ControlAddInReady()
                begin
                    Log.Add('Ctl ControlAddInReady');
                end;

                trigger Answered(Answer: Text)
                begin
                    Log.Add('Ctl Answered ' + Answer);
                end;
            }
            usercontrol(HiddenCtl; "LT TZ Addin")
            {
                ApplicationArea = All;
                Visible = false;

                trigger ControlAddInReady()
                begin
                    Log.Add('HiddenCtl ControlAddInReady');
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CallAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('CallAct before');
                    CurrPage.Ctl.Say('hello');
                    Log.Add('CallAct after');
                end;
            }
            action(CountAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('CountAct before');
                    CurrPage.Ctl.Count(7);
                    Log.Add('CountAct after');
                end;
            }
            action(TryCallAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Ok: Boolean;
                begin
                    ClearLastError();
                    Ok := TrySay();
                    Log.Add('TryCallAct ok=' + Format(Ok) + ' text=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                end;
            }
            action(HiddenCallAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('HiddenCallAct before');
                    CurrPage.HiddenCtl.Say('hello');
                    Log.Add('HiddenCallAct after');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage');
        CallIfAsked('OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('OnAfterGetRecord ' + Format(Rec.Id));
        CallIfAsked('OnAfterGetRecord');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('OnAfterGetCurrRecord ' + Format(Rec.Id));
        CallIfAsked('OnAfterGetCurrRecord');
    end;

    trigger OnClosePage()
    begin
        Log.Add('OnClosePage');
        CallIfAsked('OnClosePage');
    end;

    local procedure CallIfAsked(Where: Text)
    begin
        if not Log.ShouldCall(Where) then
            exit;
        CurrPage.Ctl.Say(Where);
        Log.Add(Where + ' after call');
    end;

    [TryFunction]
    local procedure TrySay()
    begin
        CurrPage.Ctl.Say('try');
    end;

    var
        Log: Codeunit "LT TZ Addin Log";
}

pageextension 90213 "LT TZ Addin Card Ext" extends "LT TZ Addin Card"
{
    layout
    {
        addlast(Content)
        {
            usercontrol(ExtCtl; "LT TZ Addin")
            {
                ApplicationArea = All;

                trigger ControlAddInReady()
                begin
                    ExtLog.Add('ExtCtl ControlAddInReady');
                end;

                trigger Answered(Answer: Text)
                begin
                    ExtLog.Add('ExtCtl Answered ' + Answer);
                end;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ExtCallAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ExtLog.Add('ExtCallAct before');
                    CurrPage.ExtCtl.Say('ext');
                    ExtLog.Add('ExtCallAct after');
                end;
            }
            action(ExtCallBaseAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ExtLog.Add('ExtCallBaseAct before');
                    CurrPage.Ctl.Say('from ext');
                    ExtLog.Add('ExtCallBaseAct after');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ExtLog.Add('ext OnOpenPage');
    end;

    var
        ExtLog: Codeunit "LT TZ Addin Log";
}
