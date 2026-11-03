//sub:report
// What a request page run keeps: commit of the run (md:217), SaveValues across tests (md:217), the report instance behind the request page (md:222).

codeunit 67731 "W3 RpState Log"
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

// Writes a marker row in the request page, at the start and at the end of the run.
report 67732 "W3 Commit Rpt"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            trigger OnAfterGetRecord()
            var
                Marker: Record "W3 Marker";
            begin
                Marker.Id := 3;
                Marker.Tag := 'row';
                if not Marker.Insert() then
                    Marker.Modify();
            end;
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

        trigger OnOpenPage()
        var
            Marker: Record "W3 Marker";
        begin
            Marker.Id := 1;
            Marker.Tag := 'open page';
            Marker.Insert();
        end;
    }

    var
        CtlVal: Integer;

    trigger OnPreReport()
    var
        Marker: Record "W3 Marker";
    begin
        Marker.Id := 2;
        Marker.Tag := 'pre report';
        Marker.Insert();
    end;

    trigger OnPostReport()
    var
        Marker: Record "W3 Marker";
    begin
        Marker.Id := 4;
        Marker.Tag := 'post report';
        Marker.Insert();
    end;
}

report 67733 "W3 SaveVal Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = true;

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(SvCtl; SvVal)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        SvVal: Integer;
        L: Codeunit "W3 RpState Log";

    trigger OnPreReport()
    begin
        L.Add('PreReport sv=' + Format(SvVal));
    end;
}

report 67734 "W3 Inst Rpt"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            RequestFilterFields = Id;

            trigger OnAfterGetRecord()
            begin
                L.Add('Row ' + Format(Row.Id));
            end;
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

        trigger OnOpenPage()
        begin
            L.Add('OnOpenPage ctl=[' + CtlVal + ']');
        end;
    }

    var
        CtlVal: Text[30];
        L: Codeunit "W3 RpState Log";

    procedure CtlValue(): Text
    begin
        exit(CtlVal);
    end;

    trigger OnPreReport()
    begin
        L.Add('PreReport ctl=[' + CtlVal + '] filter=[' + Row.GetFilter(Id) + ']');
    end;
}

codeunit 67735 "W3 RpState Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "W3 RpState Log";
        SetInHandler: Boolean;

    local procedure Seed()
    var
        Row: Record "W3 Row";
        Marker: Record "W3 Marker";
        I: Integer;
    begin
        Row.DeleteAll();
        Marker.DeleteAll();
        for I := 1 to 3 do begin
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

    [RequestPageHandler]
    procedure CommitHandler(var RP: TestRequestPage "W3 Commit Rpt")
    begin
        RP.OK().Invoke();
    end;

    // md:217: markers that survive an asserterror after the run were committed by the run.
    [Test]
    [HandlerFunctions('CommitHandler')]
    procedure RunRequestPage_Markers_SurviveARollback()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 Commit Rpt");
        Observer.Observe('markers after RunRequestPage', MarkerIds());
        Observer.Observe('parameters returned', Format(Parameters <> ''));
        asserterror Error('rollback');
        ClearLastError();
        Observer.Observe('markers after rollback', MarkerIds());
        Observer.Expect('markers after RunRequestPage', '1:open page,');
        Observer.Expect('parameters returned', 'Yes');
        Observer.Expect('markers after rollback', '1:open page,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CommitHandler')]
    procedure Run_Markers_SurviveARollback()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 Commit Rpt");
        Observer.Observe('markers after Run', MarkerIds());
        asserterror Error('rollback');
        ClearLastError();
        Observer.Observe('markers after rollback', MarkerIds());
        Observer.Expect('markers after Run', '1:open page,2:pre report,3:row,4:post report,');
        Observer.Expect('markers after rollback', '1:open page,2:pre report,3:row,4:post report,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CommitHandler')]
    procedure RunModal_Markers_SurviveARollback()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"W3 Commit Rpt");
        Observer.Observe('markers after RunModal', MarkerIds());
        asserterror Error('rollback');
        ClearLastError();
        Observer.Observe('markers after rollback', MarkerIds());
        Observer.Expect('markers after RunModal', '1:open page,2:pre report,3:row,4:post report,');
        Observer.Expect('markers after rollback', '1:open page,2:pre report,3:row,4:post report,');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SetSaveValueHandler(var RP: TestRequestPage "W3 SaveVal Rpt")
    begin
        L.Add('handler saw sv=' + RP.SvCtl.Value());
        RP.SvCtl.SetValue(42);
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ReadSaveValueHandler(var RP: TestRequestPage "W3 SaveVal Rpt")
    begin
        L.Add('handler saw sv=' + RP.SvCtl.Value());
        RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure SetSaveValueOtherHandler(var RP: TestRequestPage "W3 SaveVal Rpt")
    begin
        RP.SvCtl.SetValue(77);
        RP.OK().Invoke();
    end;

    // md:217, four tests in this order: the saved values live in the session, so a later test of the codeunit sees them.
    [Test]
    [HandlerFunctions('SetSaveValueHandler')]
    procedure SaveValues_1_RunWithOk_Sets42()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 SaveVal Rpt");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'handler saw sv=0;PreReport sv=42;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadSaveValueHandler')]
    procedure SaveValues_2_RunLaterTest_ReadsWhatTheFirstTestConfirmed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 SaveVal Rpt");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'handler saw sv=42;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetSaveValueOtherHandler')]
    procedure SaveValues_3_RunRequestPageWithOk_Sets77()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 SaveVal Rpt");
        Observer.Observe('returned', Format(Parameters <> ''));
        Observer.Observe('log', L.Take());
        Observer.Expect('returned', 'Yes');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadSaveValueHandler')]
    procedure SaveValues_4_RunAfterRunRequestPage_Reads42Or77()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 SaveVal Rpt");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'handler saw sv=42;');
        Observer.Verify();
    end;

    // md:222: the report variable behind the request page.
    [RequestPageHandler]
    procedure InstHandler(var RP: TestRequestPage "W3 Inst Rpt")
    begin
        L.Add('handler ctl=[' + RP.Ctl.Value() + '] view=[' + RP.Row.GetFilter(Id) + ']');
        if SetInHandler then begin
            RP.Ctl.SetValue('v1');
            RP.Row.SetFilter(Id, '2..3');
        end;
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('InstHandler')]
    procedure Instance_AfterRun_TheVariableStartsAgain()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 Inst Rpt";
    begin
        Seed();
        SetInHandler := false;
        Rpt.Run();
        Observer.Observe('first Run', L.Take());
        Observer.Observe('ctl after first Run', Rpt.CtlValue());
        Rpt.Run();
        Observer.Observe('second Run', L.Take());
        Observer.Expect('first Run', 'OnOpenPage ctl=[];handler ctl=[] view=[];PreReport ctl=[] filter=[];Row 1;Row 2;Row 3;');
        Observer.Expect('ctl after first Run', '');
        Observer.Expect('second Run', 'OnOpenPage ctl=[];handler ctl=[] view=[];PreReport ctl=[] filter=[];Row 1;Row 2;Row 3;');
        Observer.Verify();
    end;
}
