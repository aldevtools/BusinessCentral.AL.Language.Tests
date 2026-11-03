// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-getsubstitutereportid-method
// Scope: in-scope
// Fixtures used: table LT P91 Row of P91Fix.al; objects for the writer SQ tests in P91Unsure.al (codeunit 71613)
// Facts: whether Report.GetSubstituteReportId raises the platform event SubstituteReport ("Reporting Triggers") and the Base Application event
// OnAfterSubstituteReport (codeunit ReportManagement), with which arguments, and what it returns when a subscriber sets NewReportId.
// BC versions: 27-29

report 89587 "LT SQ Subst Source"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row") { }
    }
}

report 89588 "LT SQ Subst Target"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row") { }
    }
}

// Manual: only a test that binds it sees calls. Each event logs into its own text (the order between subscribers of two apps is not part of the facts).
codeunit 89586 "LT SQ Subst Subscribers"
{
    EventSubscriberInstance = Manual;

    var
        PlatformLog: Text;
        AfterLog: Text;
        ChangeIn: Text;

    procedure SetChange(Where: Text)
    begin
        ChangeIn := Where;
    end;

    procedure Platform(): Text
    begin
        exit(PlatformLog);
    end;

    procedure After(): Text
    begin
        exit(AfterLog);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure OnSubstituteReport(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        if ChangeIn = '' then
            PlatformLog += 'Sub(' + Format(ReportId) + ',' + Format(RunMode) + ',xml=' + RequestPageXml + ',rec=' + Format(RecordRef.Number()) + ',in=' + Format(NewReportId) + ');'
        else
            PlatformLog += 'Sub(' + Format(ReportId) + ');';
        if (ChangeIn = 'platform') and (ReportId = Report::"LT SQ Subst Source") then
            NewReportId := Report::"LT SQ Subst Target";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnAfterSubstituteReport(ReportId: Integer; RunMode: Option; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        if ChangeIn = '' then
            AfterLog += 'After(' + Format(ReportId) + ',' + Format(RunMode) + ',xml=' + RequestPageXml + ',rec=' + Format(RecordRef.Number()) + ',in=' + Format(NewReportId) + ');'
        else
            AfterLog += 'After(' + Format(ReportId) + ');';
        if (ChangeIn = 'after') and (ReportId = Report::"LT SQ Subst Source") then
            NewReportId := Report::"LT SQ Subst Target";
    end;
}
