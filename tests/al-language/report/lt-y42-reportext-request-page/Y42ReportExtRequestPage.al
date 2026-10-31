//sub:report
// Gap cycle 4, spec G4-10: the request page of a report that a reportextension extends.
// (a) The base report (in AL Language XApp A: tests/al-language-xapp-a/Y42XaEmptyRequestPage.al) declares an empty request
//     page (`layout { }`, no Content area) and the extension does addlast(Content) (the Remittance Advice - Journal /
//     E-Document shape). In the same app this does not compile: must-not-compile case 2525.
// (b) The base request page has SaveValues = true and a field on an element of a protected array global; the extension adds
//     a data item, a field on another element of that array, a field on its own global and a request page OnOpenPage (the
//     Suggest Worksheet Lines / Service shape). Observed: what the handler reads on later runs, after OK and after Cancel,
//     the trigger order, and whether saved values reach the next test.
// SaveValues with an extension field on the extension's own global alone is pinned in
// report/lt-ch-report-leads/ChReportLeads.al:133-146.

table 92825 "LT Y42 Rx Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 92830 "LT Y42 Rx Log"
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

reportextension 92820 "LT Y42 Rx Empty Rp Ext" extends "LT Y42 Xa Empty Rp"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                group(G)
                {
                    field(FlagCtl; Flag) { ApplicationArea = All; }
                }
            }
        }
    }

    trigger OnPostReport()
    begin
        L.Add('ext post flag=' + Format(Flag));
    end;

    var
        L: Codeunit "LT Y42 Rx Log";
        Flag: Boolean;
}

report 92827 "LT Y42 Rx Saved"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT Y42 Rx Row")
        {
            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Row."No.");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(Opt1; Opt[1]) { ApplicationArea = All; }
                }
            }
        }

        trigger OnInit()
        begin
            Opt[1] := true;
            L.Add('base init');
        end;

        trigger OnOpenPage()
        begin
            L.Add('base open opt1=' + Format(Opt[1]) + ' opt3=' + Format(Opt[3]));
        end;
    }

    var
        L: Codeunit "LT Y42 Rx Log";

    protected var
        Opt: array[3] of Boolean;
}

reportextension 92821 "LT Y42 Rx Saved Ext" extends "LT Y42 Rx Saved"
{
    dataset
    {
        addlast(Row)
        {
            dataitem(ExtItem; "LT Y42 Rx Row")
            {
                DataItemLink = "No." = field("No.");

                trigger OnAfterGetRecord()
                begin
                    L.Add('ext item ' + ExtItem."No.");
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            addafter(Opt1)
            {
                field(Opt3; Opt[3]) { ApplicationArea = All; }
            }
            addlast(Options)
            {
                field(NoteCtl; Note) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('ext open opt3=' + Format(Opt[3]) + ' note=' + Note);
        end;
    }

    trigger OnPostReport()
    begin
        L.Add('ext post opt1=' + Format(Opt[1]) + ' opt3=' + Format(Opt[3]) + ' note=' + Note);
    end;

    var
        L: Codeunit "LT Y42 Rx Log";
        Note: Text[20];
}

codeunit 92831 "LT Y42 Rx Runner"
{
    var
        Kind: Integer;
        ReportId: Integer;

    procedure Prepare(NewKind: Integer; NewReportId: Integer)
    begin
        Kind := NewKind;
        ReportId := NewReportId;
    end;

    trigger OnRun()
    begin
        case Kind of
            0:
                Report.Run(ReportId, true);
            1:
                Report.Run(ReportId, false);
            2:
                Report.RunModal(ReportId, true);
        end;
    end;
}

codeunit 92832 "LT Y42 Rx Request Page"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT Y42 Rx Log";
        // Saved report: 0 prime (Opt1 true, Opt3 false, note '' and OK); 2 read, set Opt3 true and note 'x', OK;
        // 3 read and OK; 4 read, set Opt3 false, Cancel.
        HMode: Integer;

    local procedure Seed()
    var
        Row: Record "LT Y42 Rx Row";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Amount := 1;
        Row.Insert();
        Row."No." := 'B';
        Row.Amount := 2;
        Row.Insert();
        Commit();
        L.Take();
    end;

    local procedure Exec(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Integer; ReportId: Integer)
    var
        Runner: Codeunit "LT Y42 Rx Runner";
        Ok: Boolean;
    begin
        ClearLastError();
        Runner.Prepare(Kind, ReportId);
        Ok := Runner.Run();
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.ObserveError(Name + ' error');
        Observer.Observe(Name + ' log', L.Take());
    end;

    local procedure Prime(var Observer: Codeunit "Probe Observer")
    begin
        HMode := 0;
        Exec(Observer, 'prime', 2, Report::"LT Y42 Rx Saved");
    end;

    // T1: addlast(Content) on an empty base request page: can the handler reach the extension's field, what does the run see.
    [Test]
    [HandlerFunctions('EmptyRpHandler')]
    procedure RXR_EmptyBase_AddlastContent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Exec(Observer, 'run', 0, Report::"LT Y42 Xa Empty Rp");
        Observer.Finish();
    end;

    // T2: the same report without the request window.
    [Test]
    procedure RXR_EmptyBase_AddlastContent_NoReqWindow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Exec(Observer, 'run', 1, Report::"LT Y42 Xa Empty Rp");
        Observer.Finish();
    end;

    // T3, T4, T6: first run after a known stored state sets the extension fields; the second run reads them back.
    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure RXR_SaveValues_ExtField_FirstAndSecondRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Prime(Observer);
        HMode := 2;
        Exec(Observer, 'first', 2, Report::"LT Y42 Rx Saved");
        HMode := 3;
        Exec(Observer, 'second', 2, Report::"LT Y42 Rx Saved");
        Observer.Finish();
    end;

    // T5: a run that sets values and Cancels, then a run that reads.
    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure RXR_SaveValues_ExtField_CancelThenRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Prime(Observer);
        HMode := 2;
        Exec(Observer, 'set', 2, Report::"LT Y42 Rx Saved");
        HMode := 4;
        Exec(Observer, 'cancel', 2, Report::"LT Y42 Rx Saved");
        HMode := 3;
        Exec(Observer, 'after cancel', 2, Report::"LT Y42 Rx Saved");
        Observer.Finish();
    end;

    // T7, part 1: leaves Opt3 true and note 'x' stored at the end of this test.
    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure RXR_SaveValues_StoreForNextTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Prime(Observer);
        HMode := 2;
        Exec(Observer, 'store', 2, Report::"LT Y42 Rx Saved");
        Observer.Finish();
    end;

    // T7, part 2: do the values the previous test stored reach this test?
    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure RXR_SaveValues_NewTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 3;
        Exec(Observer, 'next test', 2, Report::"LT Y42 Rx Saved");
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure EmptyRpHandler(var RP: TestRequestPage "LT Y42 Xa Empty Rp")
    begin
        L.Add('h flag=' + RP.FlagCtl.Value());
        RP.FlagCtl.SetValue(true);
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure SavedHandler(var RP: TestRequestPage "LT Y42 Rx Saved")
    begin
        L.Add('h opt1=' + RP.Opt1.Value() + ' opt3=' + RP.Opt3.Value() + ' note=' + RP.NoteCtl.Value());
        case HMode of
            0:
                begin
                    RP.Opt1.SetValue(true);
                    RP.Opt3.SetValue(false);
                    RP.NoteCtl.SetValue('');
                    RP.OK().Invoke();
                end;
            2:
                begin
                    RP.Opt3.SetValue(true);
                    RP.NoteCtl.SetValue('x');
                    RP.OK().Invoke();
                end;
            3:
                RP.OK().Invoke();
            4:
                begin
                    RP.Opt3.SetValue(false);
                    RP.Cancel().Invoke();
                end;
        end;
    end;
}
