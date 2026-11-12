// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Dataset (67703); cross-app fixtures tests/al-language-xapp-a/R7358XaOrderRule.al
//   (report 97996, log 97993) and the extensions R7358X<b,d,e,f>OrderRule.al in apps B, D, E and F.
// Area: the rule that orders the report extensions of apps with no dependency path between them (al-runner issue 7358). Four
//   apps extend one report; each candidate rule (app id as text, as Guid bytes, as a SQL Server uniqueidentifier, app name,
//   publisher, publish order, extension object id, extension name) predicts another order of the four (see the fixture file
//   of app A). Observed: the columns of the SaveAs Xml dataset in document order, and the order of the OnPreReport triggers.
// Already pinned elsewhere: two apps, B before D, for the dataset, the triggers, the request page and Report.WordXmlPart
//   (reports/extensions/IndependentAppsReportExtensions.al).
// BC versions: 27-29
codeunit 62361 "RPT Order Rule Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The Column names of a dataset in document order, each followed by a comma.
    local procedure Columns(Xml: Text): Text
    var
        Dataset: Codeunit "W3 Dataset";
        Line: Text;
        Result: Text;
        At: Integer;
    begin
        foreach Line in Xml.Split(Dataset.Lf()) do begin
            Line := Line.Trim();
            if Line.StartsWith('<Column ') then begin
                At := Line.IndexOf('name="');
                if At > 0 then begin
                    Line := Line.Substring(At + StrLen('name="'));
                    Result += Line.Substring(1, Line.IndexOf('"') - 1) + ',';
                end;
            end;
        end;
        exit(Result);
    end;

    [Test]
    procedure OrderRule_DatasetColumns()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "RPT XA Indep Log";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        Log.Take();
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT XA Order Rule", '', Xml)));
        Observer.Observe('columns', Columns(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('columns', 'HeadNo,ECol,BCol,DCol,FCol,');
        Observer.Verify();
    end;

    [Test]
    procedure OrderRule_OnPreReportTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "RPT XA Indep Log";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        Log.Take();
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT XA Order Rule", '', Xml)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('saved', 'Yes');
        Observer.Expect('log', 'A:pre;E:pre;B:pre;D:pre;F:pre;');
        Observer.Verify();
    end;
}
