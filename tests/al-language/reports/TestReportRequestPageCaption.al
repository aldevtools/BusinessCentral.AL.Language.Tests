// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-caption-property
// Scope: in-scope
// Fixtures used: none beyond this file — Base Application report 5207 "Employee - Addresses"
//
// What TestRequestPage.Caption() returns for a report's request page.
//
// A request page may declare its own Caption. When the report also declares one, the request
// page shows the REPORT's caption; the request page's own Caption is what it shows only when
// the report declares none. The same holds for a report that ships precompiled in Base
// Application: report 5207's caption is 'Employee Addresses' and its request page's is
// 'Employee - Addresses'.
//
// Every handler reads the caption and presses Cancel, so no report body runs.
report 67560 "RPC Both Captions"
{
    Caption = 'RPC Report Caption';
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        Caption = 'RPC Request Page Caption';

        layout
        {
            area(Content)
            {
                field(Dummy; DummyTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Dummy';
                }
            }
        }
    }

    var
        DummyTxt: Text[30];
}

report 67561 "RPC Report Caption Only"
{
    Caption = 'RPC Plain Report Caption';
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Dummy; DummyTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Dummy';
                }
            }
        }
    }

    var
        DummyTxt: Text[30];
}

report 67562 "RPC Request Caption Only"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        Caption = 'RPC Only Request Page Caption';

        layout
        {
            area(Content)
            {
                field(Dummy; DummyTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Dummy';
                }
            }
        }
    }

    var
        DummyTxt: Text[30];
}

codeunit 67560 "Rpt RequestPage Caption"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        SeenCaption: Text;
        HandlerCalls: Integer;

    [Test]
    [HandlerFunctions('EmployeeAddressesRequestPage')]
    procedure PrecompiledReport_BothCaptions_ShowsTheReportCaption()
    begin
        SeenCaption := '';
        HandlerCalls := 0;

        Report.RunModal(Report::"Employee - Addresses", true, false);

        Assert.AreEqual(1, HandlerCalls, 'the [RequestPageHandler] should run once');
        Assert.AreEqual('Employee Addresses', SeenCaption,
            'report 5207 declares Caption = ''Employee Addresses'' and its request page ''Employee - Addresses''; the report''s caption should win');
    end;

    [Test]
    [HandlerFunctions('BothCaptionsRequestPage')]
    procedure SourceReport_BothCaptions_ShowsTheReportCaption()
    begin
        SeenCaption := '';
        HandlerCalls := 0;

        Report.RunModal(Report::"RPC Both Captions", true, false);

        Assert.AreEqual(1, HandlerCalls, 'the [RequestPageHandler] should run once');
        Assert.AreEqual('RPC Report Caption', SeenCaption,
            'when the report and its request page both declare a Caption, the report''s should win');
    end;

    [Test]
    [HandlerFunctions('ReportCaptionOnlyRequestPage')]
    procedure SourceReport_OnlyReportCaption_ShowsTheReportCaption()
    begin
        SeenCaption := '';
        HandlerCalls := 0;

        Report.RunModal(Report::"RPC Report Caption Only", true, false);

        Assert.AreEqual(1, HandlerCalls, 'the [RequestPageHandler] should run once');
        Assert.AreEqual('RPC Plain Report Caption', SeenCaption,
            'a request page declaring no Caption should show the report''s caption');
    end;

    [Test]
    [HandlerFunctions('RequestCaptionOnlyRequestPage')]
    procedure SourceReport_OnlyRequestPageCaption_ShowsTheRequestPageCaption()
    begin
        SeenCaption := '';
        HandlerCalls := 0;

        Report.RunModal(Report::"RPC Request Caption Only", true, false);

        Assert.AreEqual(1, HandlerCalls, 'the [RequestPageHandler] should run once');
        Assert.AreEqual('RPC Only Request Page Caption', SeenCaption,
            'when only the request page declares a Caption, the request page should show it');
    end;

    [RequestPageHandler]
    procedure EmployeeAddressesRequestPage(var RequestPage: TestRequestPage "Employee - Addresses")
    begin
        HandlerCalls += 1;
        SeenCaption := RequestPage.Caption();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure BothCaptionsRequestPage(var RequestPage: TestRequestPage "RPC Both Captions")
    begin
        HandlerCalls += 1;
        SeenCaption := RequestPage.Caption();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ReportCaptionOnlyRequestPage(var RequestPage: TestRequestPage "RPC Report Caption Only")
    begin
        HandlerCalls += 1;
        SeenCaption := RequestPage.Caption();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure RequestCaptionOnlyRequestPage(var RequestPage: TestRequestPage "RPC Request Caption Only")
    begin
        HandlerCalls += 1;
        SeenCaption := RequestPage.Caption();
        RequestPage.Cancel().Invoke();
    end;
}
