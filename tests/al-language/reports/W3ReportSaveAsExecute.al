//sub:report
// Report.SaveAs and Report.Execute runs (md:209, md:201 Execute forms, md:376 second Execute). Parameters text applied after the data item views,
// RecordRef as a view, a second SaveAs on one variable, the globals of the variable, and whether the run commits.

codeunit 67723 "W3 SaveRun Log"
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

report 67724 "W3 SaveRun Rpt"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            DataItemTableView = sorting(Id) where(Id = filter(1..4));
            RequestFilterFields = Id;

            column(Id; Id) { }

            trigger OnPreDataItem()
            begin
                L.Add('pre filter=[' + Row.GetFilter(Id) + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                Counter += 1;
            end;
        }
    }

    var
        Counter: Integer;
        WriteMarker: Boolean;
        L: Codeunit "W3 SaveRun Log";

    procedure SetWriteMarker(NewValue: Boolean)
    begin
        WriteMarker := NewValue;
    end;

    procedure RowCounter(): Integer
    begin
        exit(Counter);
    end;

    trigger OnPreReport()
    begin
        Counter += 100;
    end;

    trigger OnPostReport()
    var
        Marker: Record "W3 Marker";
    begin
        if WriteMarker then begin
            Marker.Id := 1;
            Marker.Tag := 'save';
            Marker.Insert();
        end;
    end;
}

report 67725 "W3 Exec Rpt"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            RequestFilterFields = Id;

            trigger OnPreDataItem()
            begin
                L.Add('pre filter=[' + Row.GetFilter(Id) + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Opt; OptVal)
                {
                    ApplicationArea = All;
                }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('request page opened');
        end;
    }

    var
        OptVal: Integer;
        L: Codeunit "W3 SaveRun Log";

    trigger OnPreReport()
    begin
        L.Add('PreReport opt=' + Format(OptVal));
    end;

    trigger OnPostReport()
    var
        Marker: Record "W3 Marker";
    begin
        Marker.Id := 2;
        Marker.Tag := 'exec';
        if not Marker.Insert() then
            Marker.Modify();
        L.Add('PostReport');
    end;
}

codeunit 67726 "W3 SaveRun Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "W3 SaveRun Log";
        Dataset: Codeunit "W3 Dataset";
        Runner: Codeunit "W3 Runner";

    local procedure Seed()
    var
        Row: Record "W3 Row";
        Marker: Record "W3 Marker";
        I: Integer;
    begin
        Row.DeleteAll();
        Marker.DeleteAll();
        for I := 1 to 6 do begin
            Row.Id := I;
            Row.Insert();
        end;
        Commit();
        L.Take();
    end;

    local procedure MarkerIds(): Text
    var
        Marker: Record "W3 Marker";
        Result: Text;
    begin
        if Marker.FindSet() then
            repeat
                Result += Format(Marker.Id) + ':' + Marker.Tag + ',';
            until Marker.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySaveAs(var Rpt: Report "W3 SaveRun Rpt"; var OutS: OutStream)
    begin
        Rpt.SaveAs('', ReportFormat::Xml, OutS);
    end;

    // md:209: the parameters text from a request page is applied after the item's own view (1..4).
    [Test]
    [HandlerFunctions('FilterHandler')]
    procedure SaveAs_ParametersFromRequestPage_AgainstTheTableView()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 SaveRun Rpt");
        Observer.Observe('handler', L.Take());
        Observer.Observe('dataitems', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Ok := Dataset.Save(Report::"W3 SaveRun Rpt", Parameters, Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('ids', Dataset.ColumnValues(Xml, 'Id'));
        Observer.Observe('log', L.Take());
        Observer.Expect('handler', 'view in handler=[1..4];view after set=[1..4];');
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(3..9))</DataItem>');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('ids', '3,4,');
        Observer.Expect('log', 'pre filter=[3..9];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FilterHandler(var RP: TestRequestPage "W3 SaveRun Rpt")
    begin
        L.Add('view in handler=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '3..9');
        L.Add('view after set=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    // md:209: a parameters text written by hand (not produced by RunRequestPage).
    [Test]
    procedure SaveAs_HandwrittenParameters_FilterAndNoVersionPart()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Parameters := '<?xml version="1.0" standalone="yes"?><ReportParameters name="W3 SaveRun Rpt" id="' + Format(Report::"W3 SaveRun Rpt") +
            '"><Options></Options><DataItems><DataItem name="Row">WHERE(Field1=1(2..3))</DataItem></DataItems></ReportParameters>';
        Ok := Dataset.Save(Report::"W3 SaveRun Rpt", Parameters, Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('ids', Dataset.ColumnValues(Xml, 'Id'));
        Observer.Observe('log', L.Take());
        Observer.Expect('saved', 'Yes');
        Observer.Expect('ids', '2,3,');
        Observer.Expect('log', 'pre filter=[2..3];');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_ParametersWithoutDataItems_KeepsTheTableView()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Parameters := '<?xml version="1.0" standalone="yes"?><ReportParameters name="W3 SaveRun Rpt" id="' + Format(Report::"W3 SaveRun Rpt") +
            '"><Options></Options><DataItems></DataItems></ReportParameters>';
        Ok := Dataset.Save(Report::"W3 SaveRun Rpt", Parameters, Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('ids', Dataset.ColumnValues(Xml, 'Id'));
        Observer.Observe('log', L.Take());
        Observer.Expect('saved', 'Yes');
        Observer.Expect('ids', '1,2,3,4,');
        Observer.Expect('log', 'pre filter=[];');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_NotXmlParameters()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 SaveRun Rpt", 4, 'this is not xml', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('result', Result);
        Observer.ObserveError('error');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('result', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_ParametersOfAnotherReport()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 SaveRun Rpt", 4, '<?xml version="1.0" standalone="yes"?><ReportParameters name="W3 Exec Rpt" id="' + Format(Report::"W3 Exec Rpt") +
            '"><Options></Options><DataItems><DataItem name="Row">WHERE(Field1=1(5))</DataItem></DataItems></ReportParameters>', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('result', Result);
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('result', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'pre filter=[5];');
        Observer.Verify();
    end;

    // md:209: a RecordRef over the item's table sets the view; does it replace or intersect the item's own view (1..4)?
    [Test]
    procedure SaveAs_RecordRef_ReplacesOrIntersectsTheTableView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W3 Row";
        RecRef: RecordRef;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Row.SetFilter(Id, '3..6');
        RecRef.GetTable(Row);
        TempBlob.CreateOutStream(OutS);
        Ok := Report.SaveAs(Report::"W3 SaveRun Rpt", '', ReportFormat::Xml, OutS, RecRef);
        Xml := Dataset.ReadAll(TempBlob);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('ids', Dataset.ColumnValues(Xml, 'Id'));
        Observer.Observe('log', L.Take());
        Observer.Expect('saved', 'Yes');
        Observer.Expect('ids', '3,4,');
        Observer.Expect('log', 'pre filter=[3..6];');
        Observer.Verify();
    end;

    // md:209: the variable after SaveAs keeps its globals; a second SaveAs on the same variable.
    [Test]
    procedure SaveAs_InstanceTwice_GlobalsAndSecondCall()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 SaveRun Rpt";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Rpt.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('counter after first', Format(Rpt.RowCounter()));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Ok := TrySaveAs(Rpt, OutS);
        Xml := Dataset.ReadAll(TempBlob);
        Observer.Observe('second ok', Format(Ok));
        Observer.ObserveError('second error');
        Observer.Observe('second ids', Dataset.ColumnValues(Xml, 'Id'));
        Observer.Observe('counter after second', Format(Rpt.RowCounter()));
        Observer.Observe('log', L.Take());
        Observer.Expect('counter after first', '104');
        Observer.Expect('second ok', 'No');
        Observer.Expect('second error|text', 'The object has been run. Use the function CLEAR(Report).');
        Observer.Expect('second error|code', 'ObjectHasAlreadyBeenRun');
        Observer.Expect('second ids', '');
        Observer.Expect('counter after second', '104');
        Observer.Expect('log', 'pre filter=[];');
        Observer.Verify();
    end;

    // md:209 and md:217: does SaveAs commit? A write in OnPostReport, then asserterror rolls back what is not committed.
    [Test]
    procedure SaveAs_WriteInOnPostReport_SurvivesARollback()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 SaveRun Rpt";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        Rpt.SetWriteMarker(true);
        TempBlob.CreateOutStream(OutS);
        Rpt.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('markers after SaveAs', MarkerIds());
        asserterror Error('rollback');
        ClearLastError();
        Observer.Observe('markers after rollback', MarkerIds());
        Observer.Expect('markers after SaveAs', '1:save,');
        Observer.Expect('markers after rollback', '');
        Observer.Verify();
    end;

    // md:201 and md:376: Report.Execute without a request page.
    [Test]
    procedure Execute_Headless_NoRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 Exec Rpt", 5, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'PreReport opt=0;pre filter=[];row 1;row 2;row 3;row 4;row 5;row 6;PostReport;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ExecFilterHandler')]
    procedure Execute_WithParametersFromRunRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 Exec Rpt");
        Observer.Observe('page log', L.Take());
        Observer.Observe('options', Dataset.Between(Parameters, '<Options>', '</Options>'));
        Ok := Runner.Exec(Report::"W3 Exec Rpt", 5, Parameters, Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('run log', L.Take());
        Observer.Expect('page log', 'request page opened;');
        Observer.Expect('options', '<Field name="OptVal">8</Field>');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('run log', 'request page opened;PreReport opt=8;pre filter=[2..3];row 2;row 3;PostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ExecFilterHandler(var RP: TestRequestPage "W3 Exec Rpt")
    begin
        RP.Row.SetFilter(Id, '2..3');
        RP.Opt.SetValue(8);
        RP.OK().Invoke();
    end;

    [Test]
    procedure Execute_WithRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W3 Row";
        RecRef: RecordRef;
    begin
        Seed();
        Row.SetFilter(Id, '5..6');
        RecRef.GetTable(Row);
        Report.Execute(Report::"W3 Exec Rpt", '', RecRef);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'PreReport opt=0;pre filter=[5..6];row 5;row 6;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Execute_SecondCallOnOneVariable_ErrorAndCode()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 Exec Rpt";
    begin
        Seed();
        Rpt.Execute('');
        Observer.Observe('first log', L.Take());
        asserterror Rpt.Execute('');
        Observer.ObserveError('second');
        Observer.Observe('second log', L.Take());
        Observer.Expect('first log', 'PreReport opt=0;pre filter=[];row 1;row 2;row 3;row 4;row 5;row 6;PostReport;');
        Observer.Expect('second|text', 'The object has been run. Use the function CLEAR(Report).');
        Observer.Expect('second|code', 'ObjectHasAlreadyBeenRun');
        Observer.Expect('second log', '');
        Observer.Verify();
    end;

    // md:217 for Execute: does it commit?
    [Test]
    procedure Execute_WriteInOnPostReport_SurvivesARollback()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Execute(Report::"W3 Exec Rpt", '');
        Observer.Observe('markers after Execute', MarkerIds());
        asserterror Error('rollback');
        ClearLastError();
        Observer.Observe('markers after rollback', MarkerIds());
        Observer.Expect('markers after Execute', '2:exec,');
        Observer.Expect('markers after rollback', '');
        Observer.Verify();
    end;
}
