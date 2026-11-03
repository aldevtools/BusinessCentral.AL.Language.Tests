//sub:report
// TransactionType other than Update, and runs started while a write is pending (md:198 of the batch list).

report 67744 "W3 Tx Browse"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    TransactionType = Browse;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            trigger OnAfterGetRecord()
            var
                Marker: Record "W3 Marker";
            begin
                Marker.Id := 1;
                Marker.Tag := 'browse';
                if not Marker.Insert() then
                    Marker.Modify();
            end;
        }
    }
}

report 67745 "W3 Tx Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    TransactionType = Report;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            trigger OnAfterGetRecord()
            var
                Marker: Record "W3 Marker";
            begin
                Marker.Id := 1;
                Marker.Tag := 'report';
                if not Marker.Insert() then
                    Marker.Modify();
            end;
        }
    }
}

report 67746 "W3 Tx Snapshot"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    TransactionType = Snapshot;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            trigger OnAfterGetRecord()
            var
                Marker: Record "W3 Marker";
            begin
                Marker.Id := 1;
                Marker.Tag := 'snapshot';
                if not Marker.Insert() then
                    Marker.Modify();
            end;
        }
    }
}

// Does not write. Used to start a run while a write of the test is pending.
report 67747 "W3 Tx Plain"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
        }
    }
}

report 67748 "W3 Tx Plain Req"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; CtlVal)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        CtlVal: Integer;
}

codeunit 67749 "W3 Tx Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Runner: Codeunit "W3 Runner";

    local procedure Seed()
    var
        Row: Record "W3 Row";
        Marker: Record "W3 Marker";
    begin
        Row.DeleteAll();
        Marker.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Commit();
    end;

    local procedure Markers(): Text
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

    local procedure RunWithWrite(ReportId: Integer; var Observer: Codeunit "Probe Observer")
    var
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(ReportId, 0, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('markers after run', Markers());
        asserterror Error('rollback');
        ClearLastError();
        Observer.Observe('markers after rollback', Markers());
    end;

    [TryFunction]
    local procedure TryRunRequestPage(var Parameters: Text)
    begin
        Parameters := Report.RunRequestPage(Report::"W3 Tx Plain Req");
    end;

    [TryFunction]
    local procedure TryRun()
    begin
        Report.Run(Report::"W3 Tx Plain");
    end;

    [TryFunction]
    local procedure TryRunModal()
    begin
        Report.RunModal(Report::"W3 Tx Plain");
    end;

    [TryFunction]
    local procedure TrySaveAs(var OutS: OutStream)
    begin
        Report.SaveAs(Report::"W3 Tx Plain", '', ReportFormat::Xml, OutS);
    end;

    [TryFunction]
    local procedure TryExecute()
    begin
        Report.Execute(Report::"W3 Tx Plain", '');
    end;

    [TryFunction]
    local procedure TryPrint()
    begin
        Report.Print(Report::"W3 Tx Plain", '', '');
    end;

    local procedure PendingWrite()
    var
        Marker: Record "W3 Marker";
    begin
        Marker.Id := 9;
        Marker.Tag := 'pending';
        Marker.Insert();
    end;

    [Test]
    procedure TransactionTypeBrowse_ReportThatWrites()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWithWrite(Report::"W3 Tx Browse", Observer);
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Write operations in the database (INSERT, DELETE, and MODIFY) are not allowed for the selected transaction type.');
        Observer.Expect('error|code', 'DB:TransActionIsReadOnly');
        Observer.Expect('markers after run', '');
        Observer.Expect('markers after rollback', '');
        Observer.Verify();
    end;

    [Test]
    procedure TransactionTypeReport_ReportThatWrites()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWithWrite(Report::"W3 Tx Report", Observer);
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Write operations in the database (INSERT, DELETE, and MODIFY) are not allowed for the selected transaction type.');
        Observer.Expect('error|code', 'DB:TransActionIsReadOnly');
        Observer.Expect('markers after run', '');
        Observer.Expect('markers after rollback', '');
        Observer.Verify();
    end;

    [Test]
    procedure TransactionTypeSnapshot_ReportThatWrites()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWithWrite(Report::"W3 Tx Snapshot", Observer);
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Write operations in the database (INSERT, DELETE, and MODIFY) are not allowed for the selected transaction type.');
        Observer.Expect('error|code', 'DB:TransActionIsReadOnly');
        Observer.Expect('markers after run', '');
        Observer.Expect('markers after rollback', '');
        Observer.Verify();
    end;

    // The pending-write rule: each statement started while the test has an uncommitted write.
    [Test]
    procedure PendingWrite_RunRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
        Ok: Boolean;
    begin
        Seed();
        PendingWrite();
        Ok := TryRunRequestPage(Parameters);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure PendingWrite_Run()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Seed();
        PendingWrite();
        Ok := TryRun();
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure PendingWrite_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Seed();
        PendingWrite();
        Ok := TryRunModal();
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure PendingWrite_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        Seed();
        PendingWrite();
        TempBlob.CreateOutStream(OutS);
        Ok := TrySaveAs(OutS);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Report 67747 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('error|code', 'ReportProcessingOnly');
        Observer.Verify();
    end;

    [Test]
    procedure PendingWrite_Execute()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Seed();
        PendingWrite();
        Ok := TryExecute();
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure PendingWrite_Print()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Seed();
        PendingWrite();
        Ok := TryPrint();
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoPendingWrite_Print()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Seed();
        Ok := TryPrint();
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Verify();
    end;
}
