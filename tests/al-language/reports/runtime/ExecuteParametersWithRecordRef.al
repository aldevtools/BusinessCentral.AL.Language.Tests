// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-execute-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Row (67698), W3 Child (67699), W3 Marker (67700)
// local object: the report's data items, request page and triggers are under test (reports 62340 and 62341, log 62342).
// Area: a report run with request page parameters AND a RecordRef (al-runner issue 7446: Parameters := RunRequestPage();
//   Execute(Parameters, RecRef)).
//   Parameters: from RunRequestPage with a handler that only presses OK (no data item filter), that filters the first data item
//   (Id 2..4) and sets an option, and that filters both data items.
//   RecordRef: over the first data item's table without a filter, with a filter on the same field (Id 3..5), with a filter on
//   another field, with another key in descending order, over the second data item's table, over a table the report does not
//   read, and not opened.
//   Calls: Report.Execute(Id, Parameters, RecRef), ReportVariable.Execute(Parameters, RecRef), the same after SetTableView,
//   Report.SaveAs(Id, Parameters, Xml, OutStream, RecRef) and ReportVariable.SaveAs(Parameters, Xml, OutStream, RecRef).
//   Observed: the option value in OnPreReport, the filters of both data items in OnPreDataItem and the rows read.
// Already pinned elsewhere: Execute with empty parameters and a RecordRef, Execute with parameters and no RecordRef, SaveAs with a
//   RecordRef and empty parameters (reports/W3ReportSaveAsExecute.al).
// The parameters are fetched before the test writes rows.
// BC versions: 27-29
codeunit 62342 "RPT ExecRef Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        HandlerMode: Integer;

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

    procedure SetMode(NewMode: Integer)
    begin
        HandlerMode := NewMode;
    end;

    procedure Mode(): Integer
    begin
        exit(HandlerMode);
    end;
}

report 62340 "RPT ExecRef Proc"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            RequestFilterFields = Id;

            trigger OnPreDataItem()
            begin
                L.Add('Row filters=[' + Row.GetFilters() + '] key=[' + Row.CurrentKey() + '] asc=' + Format(Row.Ascending()));
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
        dataitem(Child; "W3 Child")
        {
            RequestFilterFields = Id;

            trigger OnPreDataItem()
            begin
                L.Add('Child filters=[' + Child.GetFilters() + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('child ' + Format(Child.Id));
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
                    Caption = 'Opt';
                }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('request page opened');
        end;
    }

    trigger OnPreReport()
    begin
        L.Add('pre opt=' + Format(OptVal));
    end;

    var
        OptVal: Integer;
        L: Codeunit "RPT ExecRef Log";
}

// The same report with a dataset, for SaveAs.
report 62341 "RPT ExecRef Data"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            RequestFilterFields = Id;

            column(RowId; Id) { }

            trigger OnPreDataItem()
            begin
                L.Add('Row filters=[' + Row.GetFilters() + '] key=[' + Row.CurrentKey() + '] asc=' + Format(Row.Ascending()));
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
        dataitem(Child; "W3 Child")
        {
            RequestFilterFields = Id;

            column(ChildId; Id) { }

            trigger OnPreDataItem()
            begin
                L.Add('Child filters=[' + Child.GetFilters() + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('child ' + Format(Child.Id));
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
                    Caption = 'Opt';
                }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('request page opened');
        end;
    }

    trigger OnPreReport()
    begin
        L.Add('pre opt=' + Format(OptVal));
    end;

    var
        OptVal: Integer;
        L: Codeunit "RPT ExecRef Log";
}

codeunit 62343 "RPT ExecRef Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "RPT ExecRef Log";

    // Rows 1..6 named n1..n6 (Flag on the even ones), children 11..14 of the parents 1, 1, 2, 5.
    local procedure Seed()
    var
        Row: Record "W3 Row";
        Child: Record "W3 Child";
        Marker: Record "W3 Marker";
        I: Integer;
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        Marker.DeleteAll();
        for I := 1 to 6 do begin
            Row.Init();
            Row.Id := I;
            Row.Name := 'n' + Format(I);
            Row.Flag := I mod 2 = 0;
            Row.Insert();
        end;
        AddChild(11, 1);
        AddChild(12, 1);
        AddChild(13, 2);
        AddChild(14, 5);
        Marker.Init();
        Marker.Id := 1;
        Marker.Insert();
        L.Take();
        ClearLastError();
    end;

    local procedure AddChild(Id: Integer; ParentId: Integer)
    var
        Child: Record "W3 Child";
    begin
        Child.Init();
        Child.Id := Id;
        Child.ParentId := ParentId;
        Child.Insert();
    end;

    // Mode 0: OK only. Mode 1: Row Id 2..4 and Opt 8. Mode 2: Row Id 2..4, Child Id 12..13 and Opt 9.
    local procedure Parameters(ReportId: Integer; Mode: Integer): Text
    var
        Result: Text;
    begin
        L.SetMode(Mode);
        Result := Report.RunRequestPage(ReportId);
        L.Take();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryExecute(ReportId: Integer; Parameters: Text; var RecRef: RecordRef)
    begin
        Report.Execute(ReportId, Parameters, RecRef);
    end;

    [TryFunction]
    local procedure TryExecuteVariable(Parameters: Text; var RecRef: RecordRef; WithTableView: Boolean)
    var
        Rpt: Report "RPT ExecRef Proc";
        Row: Record "W3 Row";
    begin
        if WithTableView then begin
            Row.SetRange(Id, 1, 3);
            Rpt.SetTableView(Row);
        end;
        Rpt.Execute(Parameters, RecRef);
    end;

    [TryFunction]
    local procedure TrySaveAs(Parameters: Text; var RecRef: RecordRef; UseVariable: Boolean)
    var
        Rpt: Report "RPT ExecRef Data";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        if UseVariable then
            Rpt.SaveAs(Parameters, ReportFormat::Xml, OutS, RecRef)
        else
            Report.SaveAs(Report::"RPT ExecRef Data", Parameters, ReportFormat::Xml, OutS, RecRef);
    end;

    local procedure RowRef(var RecRef: RecordRef; IdFilter: Text; NameFilter: Text)
    var
        Row: Record "W3 Row";
    begin
        if IdFilter <> '' then
            Row.SetFilter(Id, IdFilter);
        if NameFilter <> '' then
            Row.SetFilter(Name, NameFilter);
        RecRef.GetTable(Row);
    end;

    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure Execute_ParametersWithoutFilter_RecordRefFiltered()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 0);
        Seed();
        RowRef(RecRef, '3..5', '');
        Observer.Observe('ok', Format(TryExecute(Report::"RPT ExecRef Proc", P, RecRef)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=0;Row filters=[Id: 3..5] key=[Id] asc=Yes;row 3;row 4;row 5;Child filters=[];child 11;child 12;child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure Execute_ParametersWithFilter_RecordRefWithoutFilter()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 1);
        Seed();
        RowRef(RecRef, '', '');
        Observer.Observe('ok', Format(TryExecute(Report::"RPT ExecRef Proc", P, RecRef)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=8;Row filters=[] key=[Id] asc=Yes;row 1;row 2;row 3;row 4;row 5;row 6;Child filters=[];child 11;child 12;child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure Execute_ParametersWithFilter_RecordRefFilterOnSameField()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 1);
        Seed();
        RowRef(RecRef, '3..5', '');
        Observer.Observe('ok', Format(TryExecute(Report::"RPT ExecRef Proc", P, RecRef)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=8;Row filters=[Id: 3..5] key=[Id] asc=Yes;row 3;row 4;row 5;Child filters=[];child 11;child 12;child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure Execute_ParametersWithFilter_RecordRefFilterOnOtherField()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 1);
        Seed();
        RowRef(RecRef, '', 'n1|n3|n5');
        Observer.Observe('ok', Format(TryExecute(Report::"RPT ExecRef Proc", P, RecRef)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=8;Row filters=[Name: n1|n3|n5] key=[Id] asc=Yes;row 1;row 3;row 5;Child filters=[];child 11;child 12;child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure Execute_ParametersWithFilter_RecordRefOtherKeyDescending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W3 Row";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 1);
        Seed();
        Row.SetCurrentKey(Name, Id);
        Row.Ascending(false);
        Row.SetRange(Flag, true);
        RecRef.GetTable(Row);
        Observer.Observe('ok', Format(TryExecute(Report::"RPT ExecRef Proc", P, RecRef)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=8;Row filters=[Flag: Yes] key=[Name,Id] asc=No;row 6;row 4;row 2;Child filters=[];child 11;child 12;child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure Execute_ParametersWithFilter_RecordRefOnSecondDataItemTable()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "W3 Child";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 1);
        Seed();
        Child.SetRange(Id, 13, 14);
        RecRef.GetTable(Child);
        Observer.Observe('ok', Format(TryExecute(Report::"RPT ExecRef Proc", P, RecRef)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=8;Row filters=[Id: 2..4] key=[Id] asc=Yes;row 2;row 3;row 4;Child filters=[Id: 13..14];child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure Execute_ParametersFilterBothItems_RecordRefOnSecondDataItemTable()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "W3 Child";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 2);
        Seed();
        Child.SetRange(Id, 13, 14);
        RecRef.GetTable(Child);
        Observer.Observe('ok', Format(TryExecute(Report::"RPT ExecRef Proc", P, RecRef)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=9;Row filters=[Id: 2..4] key=[Id] asc=Yes;row 2;row 3;row 4;Child filters=[Id: 13..14];child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure Execute_ParametersWithFilter_RecordRefOnTableTheReportDoesNotRead()
    var
        Observer: Codeunit "Probe Observer";
        Marker: Record "W3 Marker";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 1);
        Seed();
        Marker.SetRange(Id, 1);
        RecRef.GetTable(Marker);
        Observer.Observe('ok', Format(TryExecute(Report::"RPT ExecRef Proc", P, RecRef)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'The RPT ExecRef Proc report does not have a DataItem that uses the table (Table 67700 W3 Marker) specified in the function SetTableView.');
        Observer.Expect('error|code', 'ReportNoDataItem');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure Execute_ParametersWithFilter_RecordRefNotOpened()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 1);
        Seed();
        Observer.Observe('ok', Format(TryExecute(Report::"RPT ExecRef Proc", P, RecRef)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=8;Row filters=[Id: 2..4] key=[Id] asc=Yes;row 2;row 3;row 4;Child filters=[];child 11;child 12;child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    procedure Execute_EmptyParameters_RecordRefOtherKeyDescending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W3 Row";
        RecRef: RecordRef;
    begin
        Seed();
        Row.SetCurrentKey(Name, Id);
        Row.Ascending(false);
        Row.SetRange(Flag, true);
        RecRef.GetTable(Row);
        Observer.Observe('ok', Format(TryExecute(Report::"RPT ExecRef Proc", '', RecRef)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'pre opt=0;Row filters=[Flag: Yes] key=[Name,Id] asc=No;row 6;row 4;row 2;Child filters=[];child 11;child 12;child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure ExecuteOnVariable_ParametersWithFilter_RecordRefFiltered()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 1);
        Seed();
        RowRef(RecRef, '3..5', '');
        Observer.Observe('ok', Format(TryExecuteVariable(P, RecRef, false)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=8;Row filters=[Id: 3..5] key=[Id] asc=Yes;row 3;row 4;row 5;Child filters=[];child 11;child 12;child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure ExecuteOnVariable_SetTableView_ParametersWithFilter_RecordRefFiltered()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 1);
        Seed();
        RowRef(RecRef, '3..5', '');
        Observer.Observe('ok', Format(TryExecuteVariable(P, RecRef, true)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=8;Row filters=[Id: 3..5] key=[Id] asc=Yes;row 3;row 4;row 5;Child filters=[];child 11;child 12;child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DataHandler')]
    procedure SaveAs_ParametersWithFilter_RecordRefFiltered()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Data", 1);
        Seed();
        RowRef(RecRef, '3..5', '');
        Observer.Observe('ok', Format(TrySaveAs(P, RecRef, false)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=8;Row filters=[Id: 3..5] key=[Id] asc=Yes;row 3;row 4;row 5;Child filters=[];child 11;child 12;child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DataHandler')]
    procedure SaveAsOnVariable_ParametersWithFilter_RecordRefFiltered()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Data", 1);
        Seed();
        RowRef(RecRef, '3..5', '');
        Observer.Observe('ok', Format(TrySaveAs(P, RecRef, true)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=8;Row filters=[Id: 3..5] key=[Id] asc=Yes;row 3;row 4;row 5;Child filters=[];child 11;child 12;child 13;child 14;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DataHandler')]
    procedure SaveAs_ParametersWithFilter_RecordRefOnSecondDataItemTable()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "W3 Child";
        RecRef: RecordRef;
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Data", 1);
        Seed();
        Child.SetRange(Id, 13, 14);
        RecRef.GetTable(Child);
        Observer.Observe('ok', Format(TrySaveAs(P, RecRef, false)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'request page opened;pre opt=8;Row filters=[Id: 2..4] key=[Id] asc=Yes;row 2;row 3;row 4;Child filters=[Id: 13..14];child 13;child 14;');
        Observer.Verify();
    end;

    // The text of the parameters the three handler modes produce (the data item views are part of what Execute gets).
    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure RunRequestPage_ParametersText_OfTheThreeHandlerModes()
    var
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := Parameters(Report::"RPT ExecRef Proc", 0);
        Observer.Observe('ok only', P.Substring(P.IndexOf('<Options>')));
        P := Parameters(Report::"RPT ExecRef Proc", 1);
        Observer.Observe('row filter and option', P.Substring(P.IndexOf('<Options>')));
        P := Parameters(Report::"RPT ExecRef Proc", 2);
        Observer.Observe('both filters and option', P.Substring(P.IndexOf('<Options>')));
        Observer.Expect('ok only', '<Options><Field name="OptVal">0</Field></Options><DataItems><DataItem name="Row">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Child">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>');
        Observer.Expect('row filter and option', '<Options><Field name="OptVal">8</Field></Options><DataItems><DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(2..4))</DataItem><DataItem name="Child">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>');
        Observer.Expect('both filters and option', '<Options><Field name="OptVal">9</Field></Options><DataItems><DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(2..4))</DataItem><DataItem name="Child">VERSION(1) SORTING(Field1) WHERE(Field1=1(12..13))</DataItem></DataItems></ReportParameters>');
        Observer.Verify();
    end;

    local procedure Fill(Mode: Integer; var RowFilterSet: Boolean; var ChildFilterSet: Boolean; var Opt: Integer)
    begin
        RowFilterSet := Mode >= 1;
        ChildFilterSet := Mode = 2;
        case Mode of
            1:
                Opt := 8;
            2:
                Opt := 9;
        end;
    end;

    [RequestPageHandler]
    procedure ProcHandler(var RP: TestRequestPage "RPT ExecRef Proc")
    var
        RowFilterSet: Boolean;
        ChildFilterSet: Boolean;
        Opt: Integer;
    begin
        Fill(L.Mode(), RowFilterSet, ChildFilterSet, Opt);
        if RowFilterSet then
            RP.Row.SetFilter(Id, '2..4');
        if ChildFilterSet then
            RP.Child.SetFilter(Id, '12..13');
        if Opt <> 0 then
            RP.Opt.SetValue(Opt);
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure DataHandler(var RP: TestRequestPage "RPT ExecRef Data")
    var
        RowFilterSet: Boolean;
        ChildFilterSet: Boolean;
        Opt: Integer;
    begin
        Fill(L.Mode(), RowFilterSet, ChildFilterSet, Opt);
        if RowFilterSet then
            RP.Row.SetFilter(Id, '2..4');
        if ChildFilterSet then
            RP.Child.SetFilter(Id, '12..13');
        if Opt <> 0 then
            RP.Opt.SetValue(Opt);
        RP.OK().Invoke();
    end;
}
