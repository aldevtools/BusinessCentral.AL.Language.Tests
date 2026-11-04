// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-triggers-page-oninit
// Scope: in-scope
// Fixtures used: Assert (60021), and the report below
//
// The subject is the REQUEST PAGE's own OnInit trigger, which is not the report's
// OnInitReport. Those are different triggers on different objects, and the corpus already
// covers OnInitReport (Test Rpt ReqPage Ctrl, 60751) while nothing covers this one: parsing
// every `requestpage { ... }` block in the corpus finds no requestpage-scoped OnInit at all.
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4149, which measures the
// runner NOT running it and cites BC's own NavForm.RaiseOnInitAsync carrying an explicit
// `if (IsRequestPage)` branch. Nothing here predicts the runner's answer.
//
// THE DESIGN: three globals, assigned in three different places, all read through the same
// handler. Only one of them isolates the claim.
//
//   ReqInitVar    assigned ONLY in the request page's OnInit   <- the subject
//   ReqOpenVar    assigned ONLY in the request page's OnOpenPage
//   RptInitVar    assigned ONLY in the report's OnInitReport
//
// Reading all three in one handler run is what separates "the request page's OnInit did not
// run" from "no request-page trigger ran at all" and from "the report's own init did not run
// either". A single OnInit arm could not tell those apart, and they call for different fixes.

report 60999 "RPI OnInit Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(I; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReqInitField; ReqInitVar) { ApplicationArea = All; }
                field(ReqOpenField; ReqOpenVar) { ApplicationArea = All; }
                field(RptInitField; RptInitVar) { ApplicationArea = All; }
            }
        }

        // THE SUBJECT. Assigned nowhere else, so the field reading it is blank unless this ran.
        trigger OnInit()
        begin
            ReqInitVar := 'req-oninit';
        end;

        // The discriminator: a DIFFERENT request-page trigger. If this ran and OnInit did not,
        // the request page is live and OnInit specifically is missing.
        trigger OnOpenPage()
        begin
            ReqOpenVar := 'req-onopenpage';
        end;
    }

    // The report's own init, which the corpus already covers elsewhere. Included here so one
    // handler run says whether the report half initialised at all.
    trigger OnInitReport()
    begin
        RptInitVar := 'rpt-oninitreport';
    end;

    var
        ReqInitVar: Text[30];
        ReqOpenVar: Text[30];
        RptInitVar: Text[30];
}
