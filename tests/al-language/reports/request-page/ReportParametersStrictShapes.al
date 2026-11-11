// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-execute-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Temp Blob (System Application); own table 96600, codeunit 96601, reports 96602-96603,
//   reportextension 96604, codeunit 96605.
// Probe: follow-ups of al-runner issue 7590 (reports/request-page/ReportParametersBareRoot.al) and the code-sweep issue about the parameters
//   text reader (al-runner 7633). Observation form: every test ends in Observer.Finish(), so its failure message holds BC's values.
// Area: a parameters string handed to Report.SaveAs (Xml), Report.Execute and Report.RunRequestPage:
//   - a DataItems view under a root without name and id: the rows Execute reads, the filter RunRequestPage shows;
//   - under RunRequestPage: an unknown Field under a named root; a Field that names a global no control shows, a name in another letter
//     case, a control name, all under a root without name and id;
//   - the string without the XML declaration whose root has a name (Execute, RunRequestPage);
//   - an unknown element between two Field elements; a self-closing DataItem next to a DataItem with a view; entities in a value
//     (&apos;, &#39;, &#x41;, &quot; and &amp;);
//   - a Field that names a variable of a reportextension, under a root without name and id (SaveAs, RunRequestPage).
//   Observed in OnPreReport (SaveAs, Execute) or in the request page handler (RunRequestPage): the options, the rows read, the filters, or
//   the error text and code.
// Already pinned elsewhere, not repeated: reports/request-page/ReportParametersBareRoot.al (bare root Options under the three calls, the
//   DataItems view under SaveAs, unknown Fields under SaveAs and Execute, the strings without declaration under SaveAs).
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI)

table 96600 "LT RPS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 96601 "LT RPS Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 96602 "LT RPS Rpt"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RPS Row")
        {
            column(RowId; Id) { }

            trigger OnAfterGetRecord()
            begin
                Rows += 1;
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('rows=' + Format(Rows));
            end;
        }
        dataitem(Second; "LT RPS Row")
        {
            column(SecondId; Id) { }

            trigger OnAfterGetRecord()
            begin
                SecondRows += 1;
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('second=' + Format(SecondRows));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(StartCtl; StartDate) { ApplicationArea = All; }
                field(NoteCtl; NoteText) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInitReport()
    begin
        NoteText := 'init';
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre start=[' + Format(StartDate, 0, 9) + '] note=[' + NoteText + '] hidden=[' + Hidden + '] filter=[' + Row.GetFilters() + '] second=[' + Second.GetFilters() + ']');
    end;

    var
        StartDate: Date;
        NoteText: Text[30];
        Hidden: Text[30];
        Rows: Integer;
        SecondRows: Integer;
        Log: Codeunit "LT RPS Log";
}

report 96603 "LT RPS Ext Rpt"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT RPS Row")
        {
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(NoteCtl; NoteText) { ApplicationArea = All; }
            }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('base note=[' + NoteText + ']');
    end;

    var
        NoteText: Text[30];
        Log: Codeunit "LT RPS Log";
}

reportextension 96604 "LT RPS Ext" extends "LT RPS Ext Rpt"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                field(ExtCtl; ExtNote) { ApplicationArea = All; }
            }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('ext note=[' + ExtNote + ']');
    end;

    var
        ExtNote: Text[30];
        Log: Codeunit "LT RPS Log";
}

codeunit 96605 "LT RPS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT RPS Log";
        DeclTxt: Label '<?xml version="1.0" standalone="yes"?>', Locked = true;
        HandlerLog: Text;

    local procedure SeedRows()
    var
        R: Record "LT RPS Row";
        I: Integer;
    begin
        R.DeleteAll();
        for I := 1 to 3 do begin
            R.Id := I;
            R.Insert();
        end;
    end;

    local procedure Bare(Inner: Text): Text
    begin
        exit('<ReportParameters>' + Inner + '</ReportParameters>');
    end;

    local procedure Named(Inner: Text): Text
    begin
        exit('<ReportParameters name="LT RPS Rpt" id="96602">' + Inner + '</ReportParameters>');
    end;

    local procedure Opts(Fields: Text): Text
    begin
        exit('<Options>' + Fields + '</Options>');
    end;

    local procedure SetStart(): Text
    begin
        exit('<Field name="StartDate">2026-01-15</Field>');
    end;

    local procedure RowView(): Text
    begin
        exit('<DataItems><DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(2))</DataItem></DataItems>');
    end;

    [TryFunction]
    local procedure TrySaveAs(ReportId: Integer; Parameters: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, Parameters, ReportFormat::Xml, OutS);
    end;

    [TryFunction]
    local procedure TryExecute(ReportId: Integer; Parameters: Text)
    begin
        Report.Execute(ReportId, Parameters);
    end;

    [TryFunction]
    local procedure TryRunRequestPage(ReportId: Integer; Parameters: Text; var Returned: Text)
    begin
        Returned := Report.RunRequestPage(ReportId, Parameters);
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer; Parameters: Text; Mode: Text)
    var
        Ok: Boolean;
        Returned: Text;
    begin
        Log.Take();
        HandlerLog := '';
        ClearLastError();
        case Mode of
            'saveas':
                Ok := TrySaveAs(ReportId, Parameters);
            'execute':
                Ok := TryExecute(ReportId, Parameters);
            'runrequestpage':
                Ok := TryRunRequestPage(ReportId, Parameters, Returned);
        end;
        Observer.Observe(Name + ' ok', Format(Ok));
        if not Ok then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe(Name + ' log', Log.Take());
        if Mode = 'runrequestpage' then begin
            Observer.Observe(Name + ' handler', HandlerLog);
            Observer.Observe(Name + ' returned', Returned);
        end;
    end;

    [Test]
    procedure RPS_Execute_BareRoot_DataItemsView_RowsRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        RunCase(Observer, 'execute bare view', Report::"LT RPS Rpt", DeclTxt + Bare(Opts(SetStart()) + RowView()), 'execute');
        RunCase(Observer, 'execute named view', Report::"LT RPS Rpt", DeclTxt + Named(Opts(SetStart()) + RowView()), 'execute');
        RunCase(Observer, 'saveas bare view', Report::"LT RPS Rpt", DeclTxt + Bare(Opts(SetStart()) + RowView()), 'saveas');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReadHandler')]
    procedure RPS_RunRequestPage_BareRoot_DataItemsView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        RunCase(Observer, 'rrp bare view', Report::"LT RPS Rpt", DeclTxt + Bare(Opts(SetStart()) + RowView()), 'runrequestpage');
        RunCase(Observer, 'rrp named view', Report::"LT RPS Rpt", DeclTxt + Named(Opts(SetStart()) + RowView()), 'runrequestpage');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReadHandler')]
    procedure RPS_RunRequestPage_FieldNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'rrp named unknown', Report::"LT RPS Rpt", DeclTxt + Named(Opts(SetStart() + '<Field name="NoSuchOption">x</Field>')), 'runrequestpage');
        RunCase(Observer, 'rrp bare hidden', Report::"LT RPS Rpt", DeclTxt + Bare(Opts('<Field name="Hidden">h</Field>' + SetStart())), 'runrequestpage');
        RunCase(Observer, 'rrp bare letter case', Report::"LT RPS Rpt", DeclTxt + Bare(Opts('<Field name="startdate">2026-02-16</Field>')), 'runrequestpage');
        RunCase(Observer, 'rrp bare control name', Report::"LT RPS Rpt", DeclTxt + Bare(Opts('<Field name="StartCtl">2026-03-17</Field>')), 'runrequestpage');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReadHandler')]
    procedure RPS_NoDeclaration_NamedRoot_ExecuteAndRunRequestPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'execute no decl named', Report::"LT RPS Rpt", Named(Opts(SetStart())), 'execute');
        RunCase(Observer, 'rrp no decl named', Report::"LT RPS Rpt", Named(Opts(SetStart())), 'runrequestpage');
        RunCase(Observer, 'execute no decl options', Report::"LT RPS Rpt", Opts(SetStart()), 'execute');
        RunCase(Observer, 'saveas no decl options', Report::"LT RPS Rpt", Opts(SetStart()), 'saveas');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReadHandler')]
    procedure RPS_UnknownElementBetweenFields()
    var
        Observer: Codeunit "Probe Observer";
        Inner: Text;
    begin
        Inner := Opts(SetStart() + '<Unexpected>x</Unexpected><Field name="NoteText">after</Field>');
        RunCase(Observer, 'saveas', Report::"LT RPS Rpt", DeclTxt + Named(Inner), 'saveas');
        RunCase(Observer, 'execute', Report::"LT RPS Rpt", DeclTxt + Named(Inner), 'execute');
        RunCase(Observer, 'rrp', Report::"LT RPS Rpt", DeclTxt + Named(Inner), 'runrequestpage');
        Observer.Finish();
    end;

    [Test]
    procedure RPS_SelfClosingDataItem_NextToAView()
    var
        Observer: Codeunit "Probe Observer";
        Inner: Text;
    begin
        SeedRows();
        Inner := Opts(SetStart()) + '<DataItems><DataItem name="Row" /><DataItem name="Second">VERSION(1) SORTING(Field1) WHERE(Field1=1(3))</DataItem></DataItems>';
        RunCase(Observer, 'saveas', Report::"LT RPS Rpt", DeclTxt + Named(Inner), 'saveas');
        RunCase(Observer, 'execute', Report::"LT RPS Rpt", DeclTxt + Named(Inner), 'execute');
        Inner := Opts(SetStart()) + '<DataItems><DataItem name="Row" /></DataItems>';
        RunCase(Observer, 'saveas alone', Report::"LT RPS Rpt", DeclTxt + Named(Inner), 'saveas');
        Observer.Finish();
    end;

    [Test]
    procedure RPS_EntitiesInAValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'apos', Report::"LT RPS Rpt", DeclTxt + Named(Opts('<Field name="NoteText">a&apos;b</Field>')), 'saveas');
        RunCase(Observer, 'decimal ref', Report::"LT RPS Rpt", DeclTxt + Named(Opts('<Field name="NoteText">a&#39;b</Field>')), 'saveas');
        RunCase(Observer, 'hex ref', Report::"LT RPS Rpt", DeclTxt + Named(Opts('<Field name="NoteText">a&#x41;b</Field>')), 'saveas');
        RunCase(Observer, 'quot amp', Report::"LT RPS Rpt", DeclTxt + Named(Opts('<Field name="NoteText">a&quot;b&amp;c</Field>')), 'saveas');
        RunCase(Observer, 'execute apos', Report::"LT RPS Rpt", DeclTxt + Named(Opts('<Field name="NoteText">a&apos;b</Field>')), 'execute');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ExtHandler')]
    procedure RPS_ReportExtensionVariable_BareRoot()
    var
        Observer: Codeunit "Probe Observer";
        Inner: Text;
    begin
        Inner := Opts('<Field name="NoteText">base</Field><Field name="ExtNote">ext</Field>');
        RunCase(Observer, 'saveas bare', Report::"LT RPS Ext Rpt", DeclTxt + Bare(Inner), 'saveas');
        RunCase(Observer, 'execute bare', Report::"LT RPS Ext Rpt", DeclTxt + Bare(Inner), 'execute');
        RunCase(Observer, 'rrp bare', Report::"LT RPS Ext Rpt", DeclTxt + Bare(Inner), 'runrequestpage');
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure ReadHandler(var RP: TestRequestPage "LT RPS Rpt")
    begin
        HandlerLog := 'start=[' + RP.StartCtl.Value + '] note=[' + RP.NoteCtl.Value + '] row=[' + RP.Row.GetFilter(Id) + '] second=[' + RP.Second.GetFilter(Id) + ']';
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ExtHandler(var RP: TestRequestPage "LT RPS Ext Rpt")
    begin
        HandlerLog := 'note=[' + RP.NoteCtl.Value + '] ext=[' + RP.ExtCtl.Value + ']';
        RP.OK().Invoke();
    end;
}
