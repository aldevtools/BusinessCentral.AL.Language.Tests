// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Temp Blob (System Application); own table 97023, reports 97023-97024, codeunits 97025-97026.
//   Table 97023 gets three rows in the DataItems tests; the report logs how many it reads.
// Probe: from al-runner issue 7590 (an app builds the parameters XML itself: the XML declaration and a <ReportParameters> root without
//   the name and id attributes that RunRequestPage writes).
// Area: a parameters string whose root has no name and id, handed to Report.SaveAs (Xml), Report.Execute and Report.RunRequestPage:
//   - a Field that sets a Date option, next to a Text option that OnInitReport sets ('init') and no Field names;
//   - self-closing Fields for both options;
//   - a Field next to an unknown Field (a name no control shows), with the root with and without name and id;
//   - under SaveAs with the root without name and id: a Field that names a global no control shows (Hidden), a Field whose name
//     differs from a shown variable only in letter case (startdate), a Field named by the control (StartCtl);
//   - a DataItems view under the root without name and id (SaveAs and Execute);
//   - the same strings without the XML declaration (the error text and code).
//   Observed in OnPreReport (SaveAs, Execute) or in the request page handler (RunRequestPage): the two options, or the error.
// Already pinned elsewhere, not repeated: the bare root under SaveAs as Word and Excel (layouts-saveas/AMRdlcOutput.al:153,
//   AMReportOutputTests.al:24), Execute with a bare root (extensions/Y64XappRunOrder.al:156, triggers only), self-closing Fields under a
//   named root (runtime/Y68SelfClosingParams.al), an unknown Field under Execute with a named root (WdReportExecuteParams.al).
// Values: what BC produced in corpus CI runs 42852007063, 42852095520, 42852195813 (BC 27.5, 28.5, 29.0; the same on all three).
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

table 97023 "LT RPB Row"
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

codeunit 97025 "LT RPB Log"
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

report 97023 "LT RPB Rpt"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RPB Row")
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
        Log.Add('pre start=[' + Format(StartDate, 0, 9) + '] note=[' + NoteText + '] hidden=[' + Hidden + ']');
    end;

    var
        StartDate: Date;
        NoteText: Text[30];
        Hidden: Text[30];
        Rows: Integer;
        Log: Codeunit "LT RPB Log";
}

report 97024 "LT RPB Exec Rpt"
{
    UsageCategory = None;
    ProcessingOnly = true;

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
        Log.Add('pre start=[' + Format(StartDate, 0, 9) + '] note=[' + NoteText + ']');
    end;

    var
        StartDate: Date;
        NoteText: Text[30];
        Log: Codeunit "LT RPB Log";
}

codeunit 97026 "LT RPB Bare Root"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT RPB Log";
        DeclTxt: Label '<?xml version="1.0" standalone="yes"?>', Locked = true;

    local procedure Bare(Options: Text): Text
    begin
        exit('<ReportParameters><Options>' + Options + '</Options></ReportParameters>');
    end;

    local procedure Named(Name: Text; Id: Integer; Options: Text): Text
    begin
        exit('<ReportParameters name="' + Name + '" id="' + Format(Id) + '"><Options>' + Options + '</Options></ReportParameters>');
    end;

    local procedure SetStart(): Text
    begin
        exit('<Field name="StartDate">2026-01-15</Field>');
    end;

    local procedure Unknown(): Text
    begin
        exit('<Field name="NoSuchOption">x</Field>');
    end;

    [TryFunction]
    local procedure TrySaveAs(Parameters: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT RPB Rpt", Parameters, ReportFormat::Xml, OutS);
    end;

    [TryFunction]
    local procedure TryExecute(Parameters: Text)
    begin
        Report.Execute(Report::"LT RPB Exec Rpt", Parameters);
    end;

    [TryFunction]
    local procedure TryRunRequestPage(Parameters: Text; var Returned: Text)
    begin
        Returned := Report.RunRequestPage(Report::"LT RPB Rpt", Parameters);
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; Parameters: Text; Mode: Text)
    var
        Ok: Boolean;
        Returned: Text;
    begin
        Log.Take();
        ClearLastError();
        case Mode of
            'saveas':
                Ok := TrySaveAs(Parameters);
            'execute':
                Ok := TryExecute(Parameters);
            'runrequestpage':
                Ok := TryRunRequestPage(Parameters, Returned);
        end;
        Observer.Observe(Name + ' ok', Format(Ok));
        if not Ok then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe(Name + ' log', Log.Take());
        if Mode = 'runrequestpage' then
            Observer.Observe(Name + ' returned', Returned);
    end;

    [Test]
    procedure RPB_SaveAs_BareRoot_FieldSelfClosingUnknown()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'empty', '', 'saveas');
        RunCase(Observer, 'bare set', DeclTxt + Bare(SetStart()), 'saveas');
        RunCase(Observer, 'bare self-closing', DeclTxt + Bare('<Field name="StartDate" /><Field name="NoteText" />'), 'saveas');
        RunCase(Observer, 'bare unknown', DeclTxt + Bare(SetStart() + Unknown()), 'saveas');
        RunCase(Observer, 'named unknown', DeclTxt + Named('LT RPB Rpt', 97023, SetStart() + Unknown()), 'saveas');
        Observer.Expect('empty ok', 'Yes');
        Observer.Expect('empty log', 'pre start=[] note=[init] hidden=[];rows=0;');
        Observer.Expect('bare set ok', 'Yes');
        Observer.Expect('bare set log', 'pre start=[2026-01-15] note=[init] hidden=[];rows=0;');
        Observer.Expect('bare self-closing ok', 'Yes');
        Observer.Expect('bare self-closing log', 'pre start=[] note=[] hidden=[];rows=0;');
        Observer.Expect('bare unknown ok', 'Yes');
        Observer.Expect('bare unknown log', 'pre start=[2026-01-15] note=[init] hidden=[];rows=0;');
        Observer.Expect('named unknown ok', 'Yes');
        Observer.Expect('named unknown log', 'pre start=[2026-01-15] note=[init] hidden=[];rows=0;');
        Observer.Verify();
    end;

    [Test]
    procedure RPB_SaveAs_BareRoot_NamesTheReportHasOtherwise()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'hidden global', DeclTxt + Bare('<Field name="Hidden">h</Field>'), 'saveas');
        RunCase(Observer, 'letter case', DeclTxt + Bare('<Field name="startdate">2026-01-15</Field>'), 'saveas');
        RunCase(Observer, 'control name', DeclTxt + Bare('<Field name="StartCtl">2026-01-15</Field>'), 'saveas');
        Observer.Expect('hidden global ok', 'Yes');
        Observer.Expect('hidden global log', 'pre start=[] note=[init] hidden=[];rows=0;');
        Observer.Expect('letter case ok', 'Yes');
        Observer.Expect('letter case log', 'pre start=[] note=[init] hidden=[];rows=0;');
        Observer.Expect('control name ok', 'Yes');
        Observer.Expect('control name log', 'pre start=[] note=[init] hidden=[];rows=0;');
        Observer.Verify();
    end;

    local procedure SeedRows()
    var
        R: Record "LT RPB Row";
        I: Integer;
    begin
        R.DeleteAll();
        for I := 1 to 3 do begin
            R.Id := I;
            R.Insert();
        end;
    end;

    local procedure BareWithView(): Text
    begin
        exit(DeclTxt + '<ReportParameters><Options>' + SetStart() + '</Options><DataItems><DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(2))</DataItem></DataItems></ReportParameters>');
    end;

    [Test]
    procedure RPB_BareRoot_DataItemsView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        RunCase(Observer, 'saveas', BareWithView(), 'saveas');
        RunCase(Observer, 'execute', BareWithView(), 'execute');
        Observer.Expect('saveas ok', 'Yes');
        Observer.Expect('saveas log', 'pre start=[2026-01-15] note=[init] hidden=[];rows=1;');
        Observer.Expect('execute ok', 'Yes');
        Observer.Expect('execute log', 'pre start=[2026-01-15] note=[init];');
        Observer.Verify();
    end;

    [Test]
    procedure RPB_SaveAs_NoDeclaration()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'bare no declaration', Bare(SetStart()), 'saveas');
        RunCase(Observer, 'named no declaration', Named('LT RPB Rpt', 97023, SetStart()), 'saveas');
        Observer.Expect('bare no declaration ok', 'No');
        Observer.Expect('bare no declaration error', 'The filter "<ReportParameters><Options><Field name="StartDate">2026-01-15</Field></Options></ReportParameters>" is not valid for the Parameter Name field on the Object Options table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('bare no declaration code', 'Filter:CSide');
        Observer.Expect('bare no declaration log', '');
        Observer.Expect('named no declaration ok', 'No');
        Observer.Expect('named no declaration error', 'The filter "<ReportParameters name="LT RPB Rpt" id="97023"><Options><Field name="StartDate">2026-01-15</Field></Options></ReportParameters>" is not valid for the Parameter Name field on the Object Options table. An error occurred while interpreting the filter: Did not expect ''=''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('named no declaration code', 'Filter:CSide');
        Observer.Expect('named no declaration log', '');
        Observer.Verify();
    end;

    [Test]
    procedure RPB_Execute_BareRoot_FieldSelfClosingUnknown()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'bare set', DeclTxt + Bare(SetStart()), 'execute');
        RunCase(Observer, 'bare self-closing', DeclTxt + Bare('<Field name="StartDate" /><Field name="NoteText" />'), 'execute');
        RunCase(Observer, 'bare unknown', DeclTxt + Bare(SetStart() + Unknown()), 'execute');
        Observer.Expect('bare set ok', 'Yes');
        Observer.Expect('bare set log', 'pre start=[2026-01-15] note=[init];');
        Observer.Expect('bare self-closing ok', 'Yes');
        Observer.Expect('bare self-closing log', 'pre start=[] note=[];');
        Observer.Expect('bare unknown ok', 'Yes');
        Observer.Expect('bare unknown log', 'pre start=[2026-01-15] note=[init];');
        Observer.Verify();
    end;

    [Test]
    procedure RPB_Execute_NoDeclaration()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'bare no declaration', Bare(SetStart()), 'execute');
        Observer.Expect('bare no declaration ok', 'No');
        Observer.Expect('bare no declaration error', 'The filter "<ReportParameters><Options><Field name="StartDate">2026-01-15</Field></Options></ReportParameters>" is not valid for the Parameter Name field on the Object Options table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('bare no declaration code', 'Filter:CSide');
        Observer.Expect('bare no declaration log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RPB_RunRequestPage_BareRoot_FieldSelfClosingUnknown()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'bare set', DeclTxt + Bare(SetStart()), 'runrequestpage');
        RunCase(Observer, 'bare self-closing', DeclTxt + Bare('<Field name="StartDate" /><Field name="NoteText" />'), 'runrequestpage');
        RunCase(Observer, 'bare unknown', DeclTxt + Bare(SetStart() + Unknown()), 'runrequestpage');
        Observer.Expect('bare set ok', 'Yes');
        Observer.Expect('bare set log', 'handler start=[1/15/2026] note=[init];');
        Observer.Expect('bare set returned', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT RPB Rpt" id="97023"><Options><Field name="StartDate">2026-01-15</Field><Field name="NoteText">init</Field></Options><DataItems><DataItem name="Row">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>');
        Observer.Expect('bare self-closing ok', 'Yes');
        Observer.Expect('bare self-closing log', 'handler start=[] note=[];');
        Observer.Expect('bare self-closing returned', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT RPB Rpt" id="97023"><Options><Field name="StartDate" /><Field name="NoteText" /></Options><DataItems><DataItem name="Row">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>');
        Observer.Expect('bare unknown ok', 'Yes');
        Observer.Expect('bare unknown log', 'handler start=[1/15/2026] note=[init];');
        Observer.Expect('bare unknown returned', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT RPB Rpt" id="97023"><Options><Field name="StartDate">2026-01-15</Field><Field name="NoteText">init</Field></Options><DataItems><DataItem name="Row">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>');
        Observer.Verify();
    end;

    // No handler: the error comes before the request page opens (the handler did not run in the measuring runs), and a declared handler
    // that does not run makes BC fail the test.
    [Test]
    procedure RPB_RunRequestPage_NoDeclaration()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'bare no declaration', Bare(SetStart()), 'runrequestpage');
        Observer.Expect('bare no declaration ok', 'No');
        Observer.Expect('bare no declaration error', 'The filter "<ReportParameters><Options><Field name="StartDate">2026-01-15</Field></Options></ReportParameters>" is not valid for the Parameter Name field on the Object Options table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('bare no declaration code', 'Filter:CSide');
        Observer.Expect('bare no declaration log', '');
        Observer.Expect('bare no declaration returned', '');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OkHandler(var RP: TestRequestPage "LT RPB Rpt")
    begin
        Log.Add('handler start=[' + RP.StartCtl.Value() + '] note=[' + RP.NoteCtl.Value() + ']');
        RP.OK().Invoke();
    end;
}
