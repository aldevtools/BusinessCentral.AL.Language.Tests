// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080), LT PnC Child (71081), LT PnC Log (71071)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Report "A filter a data item gets in OnPreReport is discarded; a DataItemLink filter is not visible in GetFilters; after Run the variable's globals are back to their defaults ..."
// BC versions: 29 (27 and 28 by CI)

codeunit 71141 "LT PnC Log 2"
{
    SingleInstance = true;

    var
        Items: List of [Text];

    procedure Add(Value: Text)
    begin
        Items.Add(Value);
    end;

    procedure Reset()
    begin
        Clear(Items);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        Item: Text;
    begin
        foreach Item in Items do begin
            if Result <> '' then
                Result += '|';
            Result += Item;
        end;
        exit(Result);
    end;

    procedure Count(): Integer
    begin
        exit(Items.Count());
    end;
}

report 71083 "LT PnC Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Src; "LT PnC Rec")
        {
            DataItemTableView = sorting("No.");

            dataitem(Kid; "LT PnC Child")
            {
                DataItemLink = "Parent No." = field("No.");

                trigger OnPreDataItem()
                begin
                    Log.Add('KidFilters:' + Kid.GetFilters());
                end;

                trigger OnAfterGetRecord()
                begin
                    Log.Add('K' + Format(Kid."Entry No."));
                end;
            }

            trigger OnPreDataItem()
            begin
                Log.Add('PreDI:' + Format(Src.Count()) + ':' + Src.GetFilters());
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('R' + Format(Src."No."));
            end;
        }
    }

    var
        Log: Codeunit "LT PnC Log 2";
        ApplyFilter: Boolean;
        Marker: Text;
        InitCount: Integer;

    trigger OnInitReport()
    begin
        InitCount += 1;
        Log.Add('Init');
    end;

    trigger OnPreReport()
    begin
        if ApplyFilter then
            Src.SetRange("No.", 1);
        Log.Add('PreReport:' + Marker);
    end;

    trigger OnPostReport()
    begin
        Log.Add('PostReport:' + Src.GetFilters());
    end;

    procedure SetApply(NewValue: Boolean)
    begin
        ApplyFilter := NewValue;
    end;

    procedure SetMarker(NewValue: Text)
    begin
        Marker := NewValue;
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    procedure GetInitCount(): Integer
    begin
        exit(InitCount);
    end;
}

report 71084 "LT PnC Rpt Snap"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    TransactionType = Snapshot;

    dataset
    {
        dataitem(Src; "LT PnC Rec")
        {
            trigger OnPreDataItem()
            begin
                Log.Add('SnapPreDI:' + Format(Src.Count()));
            end;
        }
    }

    var
        Log: Codeunit "LT PnC Log 2";
}

codeunit 71106 "LT PnC Report Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT PnC Rec";
        C: Record "LT PnC Child";
        i: Integer;
    begin
        R.DeleteAll();
        C.DeleteAll();
        for i := 1 to 3 do begin
            R.Init();
            R."No." := i;
            R.Insert();
            C.Init();
            C."Entry No." := i * 10;
            C."Parent No." := i;
            C.Insert();
        end;
    end;

    [Test]
    procedure PreReportFilter_DiscardedOrKept()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 2";
        Rpt: Report "LT PnC Rpt";
    begin
        Seed();
        Log.Reset();
        Rpt.Run();
        Observer.Observe('noFilter', Log.Joined());
        Log.Reset();
        Clear(Rpt);
        Rpt.SetApply(true);
        Rpt.Run();
        Observer.Observe('filterInOnPreReport', Log.Joined());
        Observer.Expect('noFilter', 'Init|PreReport:|PreDI:3:|R1|KidFilters:|K10|R2|KidFilters:|K20|R3|KidFilters:|K30|PostReport:');
        Observer.Expect('filterInOnPreReport', 'Init|PreReport:|PreDI:3:|R1|KidFilters:|K10|R2|KidFilters:|K20|R3|KidFilters:|K30|PostReport:');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalsAfterRun_AndInitReport()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 2";
        Rpt: Report "LT PnC Rpt";
    begin
        Seed();
        Log.Reset();
        Rpt.SetMarker('first');
        Observer.Observe('markerBeforeRun', Rpt.GetMarker());
        Observer.Observe('initBeforeRun', Format(Rpt.GetInitCount()));
        Rpt.Run();
        Observer.Observe('markerAfterRun', Rpt.GetMarker());
        Observer.Observe('initAfterRun', Format(Rpt.GetInitCount()));
        Observer.Observe('logFirstRun', Log.Joined());
        Log.Reset();
        Rpt.Run();
        Observer.Observe('logSecondRun', Log.Joined());
        Observer.Observe('initAfterSecondRun', Format(Rpt.GetInitCount()));
        Clear(Rpt);
        Log.Reset();
        Rpt.Run();
        Observer.Observe('initAfterClear', Format(Rpt.GetInitCount()));
        Observer.Observe('logAfterClear', Log.Joined());
        Observer.Expect('markerBeforeRun', 'first');
        Observer.Expect('initBeforeRun', '1');
        Observer.Expect('markerAfterRun', '');
        Observer.Expect('initAfterRun', '1');
        Observer.Expect('logFirstRun', 'Init|PreReport:first|PreDI:3:|R1|KidFilters:|K10|R2|KidFilters:|K20|R3|KidFilters:|K30|PostReport:|Init');
        Observer.Expect('logSecondRun', 'PreReport:|PreDI:3:|R1|KidFilters:|K10|R2|KidFilters:|K20|R3|KidFilters:|K30|PostReport:');
        Observer.Expect('initAfterSecondRun', '1');
        Observer.Expect('initAfterClear', '1');
        Observer.Expect('logAfterClear', 'Init|PreReport:|PreDI:3:|R1|KidFilters:|K10|R2|KidFilters:|K20|R3|KidFilters:|K30|PostReport:|Init');
        Observer.Verify();
    end;

    [Test]
    procedure SecondExecute_OnOneVariable()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnC Rpt";
    begin
        Seed();
        Rpt.Run();
        Rpt.Run();
        Observer.Observe('secondRun', 'no error');
        Report.Execute(71083, '');
        Observer.Observe('staticExecuteEmptyXml', 'no error');
        Observer.Expect('secondRun', 'no error');
        Observer.Expect('staticExecuteEmptyXml', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure UseRequestPage_Getter()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnC Rpt";
    begin
        Observer.Observe('declaredFalse', Format(Rpt.UseRequestPage()));
        Rpt.UseRequestPage(true);
        Observer.Observe('afterSetTrue', Format(Rpt.UseRequestPage()));
        Rpt.UseRequestPage(false);
        Observer.Observe('afterSetFalse', Format(Rpt.UseRequestPage()));
        Observer.Expect('declaredFalse', 'No');
        Observer.Expect('afterSetTrue', 'Yes');
        Observer.Expect('afterSetFalse', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_Forms()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 2";
        Rpt: Report "LT PnC Rpt";
        R: Record "LT PnC Rec";
    begin
        Seed();
        Log.Reset();
        R.SetRange("No.", 2, 3);
        Rpt.SetTableView(R);
        Rpt.Run();
        Observer.Observe('range', Log.Joined());
        Clear(Rpt);
        Log.Reset();
        R.Reset();
        R.SetCurrentKey(Name);
        Rpt.SetTableView(R);
        Rpt.Run();
        Observer.Observe('keyOnly', Log.Joined());
        Clear(Rpt);
        Log.Reset();
        R.Reset();
        R.SetFilter("No.", '<>2');
        R.SetCurrentKey("No.");
        Rpt.SetTableView(R);
        Rpt.Run();
        Observer.Observe('filterAndKey', Log.Joined());
        Observer.Expect('range', 'Init|PreReport:|PreDI:2:No.: 2..3|R2|KidFilters:|K20|R3|KidFilters:|K30|PostReport:No.: 2..3');
        Observer.Expect('keyOnly', 'Init|PreReport:|PreDI:3:|R1|KidFilters:|K10|R2|KidFilters:|K20|R3|KidFilters:|K30|PostReport:');
        Observer.Expect('filterAndKey', 'Init|PreReport:|PreDI:2:No.: <>2|R1|KidFilters:|K10|R3|KidFilters:|K30|PostReport:No.: <>2');
        Observer.Verify();
    end;

    [Test]
    procedure TransactionTypeSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 2";
        Rpt: Report "LT PnC Rpt Snap";
    begin
        Seed();
        Log.Reset();
        asserterror Rpt.Run();
        Observer.ObserveError('af253');
        Observer.Observe('withPendingWrites', Log.Joined());
        Observer.Expect('af253|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af253|code', 'DB:Ok');
        Observer.Expect('withPendingWrites', '');
        Observer.Verify();
    end;

    [Test]
    procedure TransactionTypeSnapshot_ThenWrite()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 2";
        Rpt: Report "LT PnC Rpt Snap";
        R: Record "LT PnC Rec";
    begin
        Seed();
        asserterror Rpt.Run();
        Observer.ObserveError('af268');
        Log.Reset();
        R."No." := 99;
        R.Insert();
        asserterror Rpt.Run();
        Observer.ObserveError('af273');
        Observer.Observe('afterAnotherWrite', Log.Joined());
        Observer.Expect('af268|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af268|code', 'DB:Ok');
        Observer.Expect('af273|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af273|code', 'DB:Ok');
        Observer.Expect('afterAnotherWrite', '');
        Observer.Verify();
    end;
}
