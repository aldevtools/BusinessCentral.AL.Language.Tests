// @expect AL0161 | 'RequestOptionsPage' is inaccessible due to its protection level
// RequestOptionsPage through CurrReport. in a report procedure. The bare form (RequestOptionsPage.Caption, RequestOptionsPage.Update(false))
// compiles: report/lt-y40-bare-report-run/Y40BareReportRun.al (writer Y40).
report 50000 "MNC Y40 Options"
{
    UsageCategory = None;
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(NoteCtl; Note) { }
            }
        }
    }

    var
        Note: Text[30];

    procedure Refresh()
    begin
        CurrReport.RequestOptionsPage.Update();
    end;
}
