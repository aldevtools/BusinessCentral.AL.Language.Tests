// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own pages 81880-81886, page extensions 81881-81887, codeunit 81890 (ImplicitCreationObjects.al)
// Probe: corpus issue 673 item 6 (al-runtime-rs #297). Every literal asserted below is what BC 27.5, 28.5 and 29.0 produced in the corpus CI.
// Facts: a page extension adds actions to the implicit Creation area (and Processing, Navigation, Reporting) of pages that declare no actions or only area(Processing): List with a temporary Integer source and Worksheet (a ListPart has no implicit Creation area: must-not-compile case 1360); does a TestPage open with OpenView, OpenEdit and OpenNew, and do the added actions run with Invoke (Visible, Enabled, the OnAction log).
// BC versions: 27+


page 81880 "LT BL Creation List"
{
    PageType = List;
    SourceTable = Integer;
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Number; Rec.Number) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 81881 "LT BL Creation List Ext" extends "LT BL Creation List"
{
    actions
    {
        addlast(Creation)
        {
            action(ProbeAction)
            {
                ApplicationArea = All;
                Caption = 'ProbeAction';

                trigger OnAction()
                var
                    Log: Codeunit "LT BL Creation Log";
                begin
                    Log.Add('ProbeAction');
                end;
            }
        }
    }
}

page 81882 "LT BL Creation Areas"
{
    PageType = List;
    SourceTable = Integer;
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Number; Rec.Number) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 81883 "LT BL Creation Areas Ext" extends "LT BL Creation Areas"
{
    actions
    {
        addfirst(Creation)
        {
            action(CreFirst)
            {
                ApplicationArea = All;
                Caption = 'CreFirst';

                trigger OnAction()
                var
                    Log: Codeunit "LT BL Creation Log";
                begin
                    Log.Add('CreFirst');
                end;
            }
        }
        addlast(Processing)
        {
            action(ProcLast)
            {
                ApplicationArea = All;
                Caption = 'ProcLast';

                trigger OnAction()
                var
                    Log: Codeunit "LT BL Creation Log";
                begin
                    Log.Add('ProcLast');
                end;
            }
        }
        addfirst(Navigation)
        {
            action(NavFirst)
            {
                ApplicationArea = All;
                Caption = 'NavFirst';

                trigger OnAction()
                var
                    Log: Codeunit "LT BL Creation Log";
                begin
                    Log.Add('NavFirst');
                end;
            }
        }
        addlast(Reporting)
        {
            action(RepLast)
            {
                ApplicationArea = All;
                Caption = 'RepLast';

                trigger OnAction()
                var
                    Log: Codeunit "LT BL Creation Log";
                begin
                    Log.Add('RepLast');
                end;
            }
        }
    }
}

page 81884 "LT BL Creation Proc Only"
{
    PageType = List;
    SourceTable = Integer;
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Number; Rec.Number) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BaseProc)
            {
                ApplicationArea = All;
                Caption = 'BaseProc';

                trigger OnAction()
                var
                    Log: Codeunit "LT BL Creation Log";
                begin
                    Log.Add('BaseProc');
                end;
            }
        }
    }
}

pageextension 81885 "LT BL Creation Proc Only Ext" extends "LT BL Creation Proc Only"
{
    actions
    {
        addlast(Creation)
        {
            action(CreLast)
            {
                ApplicationArea = All;
                Caption = 'CreLast';

                trigger OnAction()
                var
                    Log: Codeunit "LT BL Creation Log";
                begin
                    Log.Add('CreLast');
                end;
            }
        }
    }
}

page 81886 "LT BL Creation Worksheet"
{
    PageType = Worksheet;
    SourceTable = Integer;
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Number; Rec.Number) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 81887 "LT BL Creation Worksheet Ext" extends "LT BL Creation Worksheet"
{
    actions
    {
        addlast(Creation)
        {
            action(WsCreLast)
            {
                ApplicationArea = All;
                Caption = 'WsCreLast';

                trigger OnAction()
                var
                    Log: Codeunit "LT BL Creation Log";
                begin
                    Log.Add('WsCreLast');
                end;
            }
        }
    }
}

codeunit 81890 "LT BL Creation Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}
