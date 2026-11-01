// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); cross-app fixtures tests/al-language-xapp-a/Y64XaObjects.al (report 61352, its extension
//   61353 in A, run log 61350), xapp-b/Y64XbObjects.al (extension 61355), xapp-c/Y64XcObjects.al (extension 61360); extension 93326 below.
// Probe (writer Y64, al-runner issue 6653): the order in which the triggers of report extensions from different apps run, when a dependency path
//   orders the apps (A <- B <- C <- this app; A's extension is in the same app as the report). Run without a request page (UseRequestPage(false),
//   RunModal, the reporter's shape), with the request page (a RequestPageHandler sets the extension fields and presses OK, and presses Cancel),
//   and through Report.Execute with request parameters.
// BC versions: 27-29

reportextension 93326 "LT Y64 Main Report Ext" extends "LT Y64 XA Report"
{
    dataset
    {
        modify(Row)
        {
            trigger OnBeforePreDataItem()
            begin
                ExtLog.Add('M-ext:beforepredataitem');
            end;

            trigger OnAfterAfterGetRecord()
            begin
                ExtLog.Add('M-ext:afteraftergetrecord');
            end;
        }
    }

    requestpage
    {
        layout
        {
            addafter(MyOption)
            {
                field(MyFieldM; MyVarM)
                {
                    Caption = 'My field M';
                }
            }
        }

        trigger OnOpenPage()
        begin
            ExtLog.Add('M-ext:rp open');
        end;
    }

    trigger OnPreReport()
    begin
        ExtLog.Add('M-ext:prereport');
    end;

    trigger OnPostReport()
    begin
        ExtLog.Add('M-ext:postreport');
    end;

    var
        ExtLog: Codeunit "LT Y64 XA Log";
        MyVarM: Boolean;
}

codeunit 93327 "LT Y64 Xapp Run Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y64 XA Log";
        HandlerLog: Text;

    local procedure Seed()
    var
        Row: Record "LT Y64 XA Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Log.Take();
        HandlerLog := '';
    end;

    [Test]
    procedure Y64_XappReportExtensions_NoRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        MyReport: Report "LT Y64 XA Report";
    begin
        Seed();
        MyReport.UseRequestPage(false);
        MyReport.SetMyOption(true);
        MyReport.RunModal();
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure OkHandler(var RequestPage: TestRequestPage "LT Y64 XA Report")
    begin
        HandlerLog := Log.Take();
        RequestPage.MyFieldA.SetValue(true);
        RequestPage.MyFieldB.SetValue(3);
        RequestPage.MyFieldC.SetValue('c');
        RequestPage.MyFieldM.SetValue(true);
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancelHandler(var RequestPage: TestRequestPage "LT Y64 XA Report")
    begin
        HandlerLog := Log.Take();
        RequestPage.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Y64_XappReportExtensions_RequestPageOk()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"LT Y64 XA Report", true);
        Observer.Observe('until handler', HandlerLog);
        Observer.Observe('after handler', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure Y64_XappReportExtensions_RequestPageCancel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"LT Y64 XA Report", true);
        Observer.Observe('until handler', HandlerLog);
        Observer.Observe('after handler', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y64_XappReportExtensions_Execute()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Execute(Report::"LT Y64 XA Report", '<?xml version="1.0" standalone="yes"?><ReportParameters><Options><Field name="MyOptionValue">true</Field></Options></ReportParameters>');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;
}
