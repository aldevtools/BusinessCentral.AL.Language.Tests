// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained log 72759, report 72760, test codeunit 72761
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: the report trigger OnPreRendering(var RenderingPayload: JsonObject) may not compile for runtime 16, and a report with columns but no layout may be refused; this file is separate so only it drops.
// Facts: OnPreRendering of Report.SaveAs to ReportFormat::Xml: whether it runs, how often, and its order against OnPreReport and OnPostReport.
codeunit 72759 "LT RptPreRender Xml Log"
{
    SingleInstance = true;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Count(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure Get(Index: Integer): Text
    begin
        if (Index < 1) or (Index > Entries.Count()) then
            exit('<none>');
        exit(Entries.Get(Index));
    end;

    var
        Entries: List of [Text];
}

report 72760 "LT RptPreRender Xml Rpt"
{
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));

            column(Num; Number)
            {
            }

            trigger OnPreDataItem()
            begin
                Trace.Add('Row.OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                Trace.Add('Row.OnAfterGetRecord ' + Format(Row.Number));
            end;

            trigger OnPostDataItem()
            begin
                Trace.Add('Row.OnPostDataItem');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Trace.Add('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        Trace.Add('OnPreReport');
    end;

    trigger OnPostReport()
    begin
        Trace.Add('OnPostReport');
    end;

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    begin
        Trace.Add('OnPreRendering keys=' + Format(RenderingPayload.Keys().Count()));
    end;

    var
        Trace: Codeunit "LT RptPreRender Xml Log";
}


codeunit 72761 "LT RptPreRender Xml"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Trace: Codeunit "LT RptPreRender Xml Log";

    [TryFunction]
    local procedure TrySave(Fmt: ReportFormat; var OutStr: OutStream)
    begin
        Report.SaveAs(Report::"LT RptPreRender Xml Rpt", '', Fmt, OutStr);
    end;

    [Test]
    procedure P195_SaveAsXml_PreRenderingOrder()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Ok: Boolean;
    begin
        Trace.Reset();
        TempBlob.CreateOutStream(OutStr);
        Ok := TrySave(ReportFormat::Xml, OutStr);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('has-output', Format(TempBlob.Length() > 0));
        DumpTrace(Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('has-output', 'Yes');
        Observer.Expect('count', '8');
        Observer.Expect('e1', 'OnInitReport');
        Observer.Expect('e2', 'OnPreReport');
        Observer.Expect('e3', 'Row.OnPreDataItem');
        Observer.Expect('e4', 'Row.OnAfterGetRecord 1');
        Observer.Expect('e5', 'Row.OnAfterGetRecord 2');
        Observer.Expect('e6', 'Row.OnPostDataItem');
        Observer.Expect('e7', 'OnPreRendering keys=0');
        Observer.Expect('e8', 'OnPostReport');
        Observer.Expect('e9', '<none>');
        Observer.Expect('e10', '<none>');
        Observer.Expect('e11', '<none>');
        Observer.Expect('e12', '<none>');
        Observer.Verify();
    end;

    local procedure DumpTrace(var Observer: Codeunit "Probe Observer")
    var
        I: Integer;
    begin
        Observer.Observe('count', Format(Trace.Count()));
        for I := 1 to 12 do
            Observer.Observe('e' + Format(I), Trace.Get(I));
    end;
}
