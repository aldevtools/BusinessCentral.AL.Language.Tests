// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Fixtures used: Probe Observer (codeunit 69160); table "LT AB Row" (77000), codeunit "LT AB Flags" (77001), codeunit "LT AB Log" (77050); own page 77080, page extension 77081, test codeunit 77082
// Facts: OnBeforeAction of an action extension (page extension modify block): when it runs against the OnAction of the base page, and that an error in it stops OnAction.
// OnControlAddIn of a page field and a user control: what a TestPage sees (the add-in cannot be loaded or raise an event from a test; the log shows which triggers run on open, SetValue and close).

controladdin "LT AB AddIn"
{
    RequestedHeight = 50;
    RequestedWidth = 50;
    Scripts = 'controladdins/lt-p121.js';

    event ControlAddInReady();
    event Raised(Index: Integer; Data: Text);
}

page 77080 "LT AB Action Card"
{
    PageType = Card;
    SourceTable = "LT AB Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NameF; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    Log.Add('field OnValidate ' + Rec.Name);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('base OnAction');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('page OnOpenPage');
    end;

    var
        Log: Codeunit "LT AB Log";
}

page 77083 "LT AB AddIn Card"
{
    PageType = Card;
    SourceTable = "LT AB Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NameF; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    Log.Add('field OnValidate ' + Rec.Name);
                end;

                trigger OnControlAddIn(Index: Integer; Data: Text)
                begin
                    Log.Add('field OnControlAddIn ' + Format(Index) + ' ' + Data);
                end;
            }
            usercontrol(UC; "LT AB AddIn")
            {
                ApplicationArea = All;

                trigger ControlAddInReady()
                begin
                    Log.Add('usercontrol ControlAddInReady');
                end;

                trigger Raised(Index: Integer; Data: Text)
                begin
                    Log.Add('usercontrol Raised ' + Format(Index) + ' ' + Data);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('page OnOpenPage');
    end;

    var
        Log: Codeunit "LT AB Log";
}

pageextension 77081 "LT AB Action Card Ext" extends "LT AB Action Card"
{
    actions
    {
        modify(Act)
        {
            trigger OnBeforeAction()
            begin
                Log.Add('ext OnBeforeAction');
                if Flags.Veto() then
                    Error('LT AB before action error');
            end;
        }
    }

    var
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
}
