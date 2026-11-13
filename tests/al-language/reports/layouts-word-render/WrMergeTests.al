// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-howto-report-layout
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables, reports, layouts and WR Helper of WrFixtures.al
// Probe: OBSERVE ROUND
// BC versions: 27 - 29

codeunit 91140 "WR Merge Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "WR Helper";

    local procedure Gate(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        Body: Text;
    begin
        Helper.Lines(2);
        if not Helper.Save(Observer, ReportId, ReportFormat::Word, TempBlob) then
            exit;
        Body := Helper.Body(TempBlob);
        Observer.Observe('WRSTATIC occurrences', Format(Helper.Occurrences(Body, 'WRSTATIC')));
        Observer.Observe('text', Helper.Between(Body, 'WRBODYSTART', 'WRAFTER'));
    end;

    [Test]
    procedure Gate_TableRowRepeater_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Gate(Observer, Report::"WR Gate Rows");
        Observer.Finish();
    end;

    [Test]
    procedure Gate_ParagraphRepeater_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Gate(Observer, Report::"WR Gate Paras");
        Observer.Finish();
    end;

    [Test]
    procedure Gate_PlainBindingRepeater_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Gate(Observer, Report::"WR Gate Plain Binding");
        Observer.Finish();
    end;
}
