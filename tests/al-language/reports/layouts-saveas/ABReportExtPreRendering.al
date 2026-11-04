// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Fixtures used: Probe Observer (codeunit 69160); table "LT AB Row" (77000), codeunit "LT AB Log" (77050), layout files FixtureLayout_12.rdlc (report) and FixtureLayout_13.rdlc (report extension) of the app root, copies of FixtureLayout.rdlc; own report 77090, report extension 77091, test codeunit 77092
// Facts: OnPreRendering of a report extension: whether and when it runs (against the OnPreReport of the report and the rendering), its RenderingPayload argument, and whether a change to the argument reaches the output.

report 77090 "LT AB Render Report"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RdlcLayout;

    dataset
    {
        dataitem(T; "LT AB Row")
        {
            column(EntryNo; Id) { }
            column(Description; Name) { }
            column(Amount; Level) { }
        }
    }

    rendering
    {
        layout(RdlcLayout)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout_12.rdlc';
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('report OnPreReport');
    end;

    trigger OnPostReport()
    begin
        Log.Add('report OnPostReport');
    end;

    var
        Log: Codeunit "LT AB Log";
}

reportextension 77091 "LT AB Render Report Ext" extends "LT AB Render Report"
{
    trigger OnPreRendering(var RenderingPayload: JsonObject)
    begin
        Log.Add('ext OnPreRendering keys=' + Format(RenderingPayload.Keys().Count()));
        RenderingPayload.Add('LTABKey', 'LTABValue');
    end;

    var
        Log: Codeunit "LT AB Log";
}

report 77093 "LT AB Render Plain Report"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RdlcLayout;

    dataset
    {
        dataitem(T; "LT AB Row")
        {
            column(EntryNo; Id) { }
            column(Description; Name) { }
            column(Amount; Level) { }
        }
    }

    rendering
    {
        layout(RdlcLayout)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout_13.rdlc';
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('plain OnPreReport');
    end;

    var
        Log: Codeunit "LT AB Log";
}

reportextension 77094 "LT AB Render Plain Report Ext" extends "LT AB Render Plain Report"
{
    trigger OnPreRendering(var RenderingPayload: JsonObject)
    begin
        Log.Add('plain ext OnPreRendering keys=' + Format(RenderingPayload.Keys().Count()));
    end;

    var
        Log: Codeunit "LT AB Log";
}
