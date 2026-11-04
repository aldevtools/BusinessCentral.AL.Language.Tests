// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Fixtures used: tables of RptFixtures.al; the SingleInstance log 73840 of RptRequestPage.al (its tests are in codeunit 73850 only)
// Probe (writer PX, al-runtime-rs probes-needed "Request page" after PR 333): a request page handler that raises an error it does not
//   catch, on request pages with a source table, with a part, with close triggers in a report extension, with an OnQueryClosePage that
//   answers false or raises, with an OnClosePage that raises, and on a SaveValues request page. The tests are in RptRequestPage.al
//   (codeunit 73850, procedures PX_*). Not a test codeunit.
// BC versions: 27, 28, 29

page 86215 "LT PX Rp Part"
{
    PageType = ListPart;
    SourceTable = "LT RpT Child";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(ChildId; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        L.Add('part OnOpenPage');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        L.Add('part OnAfterGetCurrRecord ' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        L.Add('part OnQueryClosePage action=' + Format(CloseAction));
        exit(true);
    end;

    trigger OnClosePage()
    begin
        L.Add('part OnClosePage');
    end;

    var
        L: Codeunit "LT RpT Request Log";
}

report 86216 "LT PX Rp Source"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        SourceTable = "LT RpT Row";

        layout
        {
            area(Content)
            {
                field(SrcId; Rec.Id) { ApplicationArea = All; }
                field(SrcName; Rec.Name) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('RP OnOpenPage');
        end;

        trigger OnAfterGetRecord()
        begin
            L.Add('RP OnAfterGetRecord ' + Format(Rec.Id));
        end;

        trigger OnAfterGetCurrRecord()
        begin
            L.Add('RP OnAfterGetCurrRecord ' + Format(Rec.Id));
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('RP OnQueryClosePage action=' + Format(CloseAction));
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('RP OnClosePage');
        end;
    }

    trigger OnInitReport()
    begin
        L.Add('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        L.Add('OnPreReport');
    end;

    var
        L: Codeunit "LT RpT Request Log";
}

report 86217 "LT PX Rp Parts"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RpT Row") { }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TextCtl; TextVal) { ApplicationArea = All; }
                part(ChildPart; "LT PX Rp Part") { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('RP OnOpenPage');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('RP OnQueryClosePage action=' + Format(CloseAction));
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('RP OnClosePage');
        end;
    }

    trigger OnPreReport()
    begin
        L.Add('OnPreReport');
    end;

    var
        TextVal: Text[30];
        L: Codeunit "LT RpT Request Log";
}

report 86218 "LT PX Rp ExtBase"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RpT Row") { }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TextCtl; TextVal) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('RP OnOpenPage');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('RP OnQueryClosePage action=' + Format(CloseAction));
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('RP OnClosePage');
        end;
    }

    trigger OnPreReport()
    begin
        L.Add('OnPreReport');
    end;

    var
        TextVal: Text[30];
        L: Codeunit "LT RpT Request Log";
}

reportextension 86219 "LT PX Rp Ext" extends "LT PX Rp ExtBase"
{
    requestpage
    {
        trigger OnOpenPage()
        begin
            XL.Add('ext RP OnOpenPage');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            XL.Add('ext RP OnQueryClosePage action=' + Format(CloseAction));
            exit(true);
        end;

        trigger OnClosePage()
        begin
            XL.Add('ext RP OnClosePage');
        end;
    }

    var
        XL: Codeunit "LT RpT Request Log";
}

// Mode: 1 = OnQueryClosePage answers false, 2 = OnQueryClosePage raises, 3 = OnClosePage raises.
report 86220 "LT PX Rp CloseMode"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RpT Row") { }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TextCtl; TextVal) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('RP OnOpenPage');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('RP OnQueryClosePage action=' + Format(CloseAction));
            if Mode = 1 then
                exit(false);
            if Mode = 2 then
                Error('px query close raised');
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('RP OnClosePage');
            if Mode = 3 then
                Error('px close raised');
        end;
    }

    trigger OnPreReport()
    begin
        L.Add('OnPreReport');
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    var
        TextVal: Text[30];
        Mode: Integer;
        L: Codeunit "LT RpT Request Log";
}

report 86221 "LT PX Rp SaveValues"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RpT Row") { }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(TextCtl; TextVal) { ApplicationArea = All; }
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('RP OnQueryClosePage action=' + Format(CloseAction) + ' text=[' + TextVal + ']');
            exit(true);
        end;
    }

    trigger OnPreReport()
    begin
        L.Add('OnPreReport text=[' + TextVal + ']');
    end;

    var
        TextVal: Text[30];
        L: Codeunit "LT RpT Request Log";
}
