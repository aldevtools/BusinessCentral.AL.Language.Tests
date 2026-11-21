// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained reports 75940, 75941, 75942;
//                the platform table "Object Options" (rows of these three reports only; every test deletes them first and commits)
// Probe: written against local BC 27.5, 28.5 and 29.0 service tiers (Windows); every literal asserted below is what those tiers produced.
//        Other builds are checked by the corpus CI matrix. Asked by al-runner issue 8250.
// Facts:
//  - Confirming a SaveValues request page with OK writes one "Object Options" row: Object Type Report, the report's id,
//    Parameter Name 'Last used options and filters', User Name and Created By = UserId, Company Name = CompanyName,
//    Public Visible and Temporary No, and Option Data (UTF-8 text) holds the confirmed value. Cancel writes no row; a request
//    page without SaveValues writes no row.
//  - The next run's request page shows what that row holds: deleting the report's rows (and committing) makes the next run show
//    a blank field; deleting the rows of one report leaves another report's saved value; deleting and inserting the row again
//    shows the value again; editing the value inside Option Data shows the edited value.
//  - The row is only used under its own key: the same row under another User Name, Company Name or Parameter Name gives a blank
//    field.
//  - A run whose request page is confirmed with OK after the rows were deleted writes a new row with the blank value.
// BC versions: 27.5, 28.5, 29.0

report 75940 "OBO Saved A"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(SomeFilter; SomeFilter) { ApplicationArea = All; Caption = 'Some Filter'; }
            }
        }
    }

    var
        SomeFilter: Text;
}

report 75941 "OBO Saved B"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(SomeFilter; SomeFilter) { ApplicationArea = All; Caption = 'Some Filter'; }
            }
        }
    }

    var
        SomeFilter: Text;
}

report 75942 "OBO Unsaved"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(SomeFilter; SomeFilter) { ApplicationArea = All; Caption = 'Some Filter'; }
            }
        }
    }

    var
        SomeFilter: Text;
}

codeunit 75945 "OBO Object Options Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        // Set: the handler sets SetTxt and presses OK. SetCancel: sets SetTxt and presses Cancel.
        // Read: the handler stores the shown value in SeenTxt and presses Cancel. ReadOk: the same, then OK.
        Mode: Option Set,SetCancel,Read,ReadOk;
        SetTxt: Text;
        SeenTxt: Text;

    local procedure ClearRows(ReportId: Integer)
    var
        ObjectOptions: Record "Object Options";
    begin
        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetRange("Object ID", ReportId);
        ObjectOptions.DeleteAll();
        Commit();
    end;

    local procedure RunSet(ReportId: Integer; Value: Text)
    begin
        Mode := Mode::Set;
        SetTxt := Value;
        Commit();
        Report.RunModal(ReportId);
    end;

    local procedure RunRead(ReportId: Integer): Text
    begin
        Mode := Mode::Read;
        SeenTxt := 'not read';
        Commit();
        Report.RunModal(ReportId);
        exit(SeenTxt);
    end;

    local procedure RowCount(ReportId: Integer): Integer
    var
        ObjectOptions: Record "Object Options";
    begin
        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetRange("Object ID", ReportId);
        exit(ObjectOptions.Count());
    end;

    local procedure OptionDataText(var ObjectOptions: Record "Object Options"): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        ObjectOptions.CalcFields("Option Data");
        if not ObjectOptions."Option Data".HasValue() then
            exit('');
        ObjectOptions."Option Data".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.Read(Result);
        exit(Result);
    end;

    local procedure FindRow(ReportId: Integer; var ObjectOptions: Record "Object Options"): Boolean
    begin
        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetRange("Object ID", ReportId);
        exit(ObjectOptions.FindFirst());
    end;

    // Deletes the report's saved row and inserts it again; What 1, 2, 3 change User Name, Company Name or Parameter Name to NewValue first.
    local procedure MoveRow(ReportId: Integer; What: Integer; NewValue: Text): Text
    var
        ObjectOptions: Record "Object Options";
        Copy: Record "Object Options";
    begin
        if not FindRow(ReportId, ObjectOptions) then
            exit('none');
        ObjectOptions.CalcFields("Option Data");
        Copy := ObjectOptions;
        case What of
            1:
                Copy."User Name" := CopyStr(NewValue, 1, MaxStrLen(Copy."User Name"));
            2:
                Copy."Company Name" := CopyStr(NewValue, 1, MaxStrLen(Copy."Company Name"));
            3:
                Copy."Parameter Name" := CopyStr(NewValue, 1, MaxStrLen(Copy."Parameter Name"));
        end;
        ClearRows(ReportId);
        Copy.Insert();
        Commit();
        exit('moved');
    end;

    [Test]
    [HandlerFunctions('HandlerA,HandlerU')]
    procedure SavedRun_WritesOneRow()
    var
        Observer: Codeunit "Probe Observer";
        ObjectOptions: Record "Object Options";
    begin
        ClearRows(Report::"OBO Saved A");
        ClearRows(Report::"OBO Unsaved");
        Observer.Observe('rows before', Format(RowCount(Report::"OBO Saved A")));
        RunSet(Report::"OBO Saved A", 'OBO-ABC');
        Observer.Observe('rows after OK', Format(RowCount(Report::"OBO Saved A")));
        if FindRow(Report::"OBO Saved A", ObjectOptions) then begin
            Observer.Observe('Parameter Name', ObjectOptions."Parameter Name");
            Observer.Observe('User Name is UserId', Format(ObjectOptions."User Name" = UserId()));
            Observer.Observe('User Name is blank', Format(ObjectOptions."User Name" = ''));
            Observer.Observe('Company Name is CompanyName', Format(ObjectOptions."Company Name" = CompanyName()));
            Observer.Observe('Company Name is blank', Format(ObjectOptions."Company Name" = ''));
            Observer.Observe('Created By is UserId', Format(ObjectOptions."Created By" = UserId()));
            Observer.Observe('Public Visible', Format(ObjectOptions."Public Visible"));
            Observer.Observe('Temporary', Format(ObjectOptions.Temporary));
            Observer.Observe('Option Data holds the value (UTF-8)', Format(OptionDataText(ObjectOptions).Contains('OBO-ABC')));
        end;
        RunSet(Report::"OBO Unsaved", 'OBO-UNSAVED');
        Observer.Observe('rows of the report without SaveValues', Format(RowCount(Report::"OBO Unsaved")));
        Observer.Expect('rows before', '0');
        Observer.Expect('rows after OK', '1');
        Observer.Expect('Parameter Name', 'Last used options and filters');
        Observer.Expect('User Name is UserId', 'Yes');
        Observer.Expect('User Name is blank', 'No');
        Observer.Expect('Company Name is CompanyName', 'Yes');
        Observer.Expect('Company Name is blank', 'No');
        Observer.Expect('Created By is UserId', 'Yes');
        Observer.Expect('Public Visible', 'No');
        Observer.Expect('Temporary', 'No');
        Observer.Expect('Option Data holds the value (UTF-8)', 'Yes');
        Observer.Expect('rows of the report without SaveValues', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA')]
    procedure SavedRun_NoDelete_NextRunShowsTheValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearRows(Report::"OBO Saved A");
        RunSet(Report::"OBO Saved A", 'OBO-KEEP');
        Observer.Observe('next run shows', RunRead(Report::"OBO Saved A"));
        Observer.Expect('next run shows', 'OBO-KEEP');
        Observer.Verify();
    end;

    // The reported shape: delete the report's rows, commit, run again; the handler reads the value and presses OK.
    [Test]
    [HandlerFunctions('HandlerA')]
    procedure DeleteRows_NextRunShowsBlank()
    var
        Observer: Codeunit "Probe Observer";
        ObjectOptions: Record "Object Options";
    begin
        ClearRows(Report::"OBO Saved A");
        RunSet(Report::"OBO Saved A", 'OBO-ABC');
        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetRange("Object ID", Report::"OBO Saved A");
        Observer.Observe('had a row', Format(not ObjectOptions.IsEmpty()));
        ObjectOptions.DeleteAll();
        Commit();
        Mode := Mode::ReadOk;
        SeenTxt := 'not read';
        Report.RunModal(Report::"OBO Saved A");
        Observer.Observe('next run shows', SeenTxt);
        Observer.Observe('rows after the OK of that run', Format(RowCount(Report::"OBO Saved A")));
        Observer.Observe('the run after shows', RunRead(Report::"OBO Saved A"));
        Observer.Expect('had a row', 'Yes');
        Observer.Expect('next run shows', '');
        Observer.Expect('rows after the OK of that run', '1');
        Observer.Expect('the run after shows', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA,HandlerB')]
    procedure DeleteRowsOfOneReport_OtherReportKeepsItsValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearRows(Report::"OBO Saved A");
        ClearRows(Report::"OBO Saved B");
        RunSet(Report::"OBO Saved A", 'OBO-A1');
        RunSet(Report::"OBO Saved B", 'OBO-B1');
        ClearRows(Report::"OBO Saved A");
        Observer.Observe('A shows', RunRead(Report::"OBO Saved A"));
        Observer.Observe('B shows', RunRead(Report::"OBO Saved B"));
        Observer.Expect('A shows', '');
        Observer.Expect('B shows', 'OBO-B1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA')]
    procedure DeleteAndInsertTheRowAgain_NextRunShowsTheValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearRows(Report::"OBO Saved A");
        RunSet(Report::"OBO Saved A", 'OBO-AGAIN');
        Observer.Observe('row', MoveRow(Report::"OBO Saved A", 0, ''));
        Observer.Observe('rows', Format(RowCount(Report::"OBO Saved A")));
        Observer.Observe('next run shows', RunRead(Report::"OBO Saved A"));
        Observer.Expect('row', 'moved');
        Observer.Expect('rows', '1');
        Observer.Expect('next run shows', 'OBO-AGAIN');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA')]
    procedure EditOptionData_NextRunShowsTheEditedValue()
    var
        Observer: Codeunit "Probe Observer";
        ObjectOptions: Record "Object Options";
        OutStr: OutStream;
        Data: Text;
    begin
        ClearRows(Report::"OBO Saved A");
        RunSet(Report::"OBO Saved A", 'OBO-OLD');
        FindRow(Report::"OBO Saved A", ObjectOptions);
        Data := OptionDataText(ObjectOptions);
        Observer.Observe('Option Data holds the value (UTF-8)', Format(Data.Contains('OBO-OLD')));
        if Data.Contains('OBO-OLD') then begin
            ObjectOptions."Option Data".CreateOutStream(OutStr, TextEncoding::UTF8);
            OutStr.WriteText(Data.Replace('OBO-OLD', 'OBO-NEW'));
            ObjectOptions.Modify();
            Commit();
        end;
        Observer.Observe('next run shows', RunRead(Report::"OBO Saved A"));
        Observer.Expect('Option Data holds the value (UTF-8)', 'Yes');
        Observer.Expect('next run shows', 'OBO-NEW');
        Observer.Verify();
    end;

    // Per user: the saved row moved to another user name.
    [Test]
    [HandlerFunctions('HandlerA')]
    procedure RowOfAnotherUser_NextRunShows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearRows(Report::"OBO Saved A");
        RunSet(Report::"OBO Saved A", 'OBO-USER');
        Observer.Observe('row', MoveRow(Report::"OBO Saved A", 1, 'OBO OTHER USER'));
        Observer.Observe('next run shows', RunRead(Report::"OBO Saved A"));
        Observer.Observe('rows after', Format(RowCount(Report::"OBO Saved A")));
        Observer.Expect('row', 'moved');
        Observer.Expect('next run shows', '');
        Observer.Expect('rows after', '1');
        Observer.Verify();
    end;

    // Per company: the saved row moved to another company name.
    [Test]
    [HandlerFunctions('HandlerA')]
    procedure RowOfAnotherCompany_NextRunShows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearRows(Report::"OBO Saved A");
        RunSet(Report::"OBO Saved A", 'OBO-COMPANY');
        Observer.Observe('row', MoveRow(Report::"OBO Saved A", 2, 'OBO Other Company'));
        Observer.Observe('next run shows', RunRead(Report::"OBO Saved A"));
        Observer.Observe('rows after', Format(RowCount(Report::"OBO Saved A")));
        Observer.Expect('row', 'moved');
        Observer.Expect('next run shows', '');
        Observer.Expect('rows after', '1');
        Observer.Verify();
    end;

    // The saved row under another Parameter Name.
    [Test]
    [HandlerFunctions('HandlerA')]
    procedure RowUnderAnotherParameterName_NextRunShows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearRows(Report::"OBO Saved A");
        RunSet(Report::"OBO Saved A", 'OBO-NAME');
        Observer.Observe('row', MoveRow(Report::"OBO Saved A", 3, 'OBO Other Name'));
        Observer.Observe('next run shows', RunRead(Report::"OBO Saved A"));
        Observer.Observe('rows after', Format(RowCount(Report::"OBO Saved A")));
        Observer.Expect('row', 'moved');
        Observer.Expect('next run shows', '');
        Observer.Expect('rows after', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA')]
    procedure CancelledRun_RowsAndNextRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearRows(Report::"OBO Saved A");
        Mode := Mode::SetCancel;
        SetTxt := 'OBO-CANCEL';
        Commit();
        Report.RunModal(Report::"OBO Saved A");
        Observer.Observe('rows after Cancel', Format(RowCount(Report::"OBO Saved A")));
        Observer.Observe('next run shows', RunRead(Report::"OBO Saved A"));
        Observer.Expect('rows after Cancel', '0');
        Observer.Expect('next run shows', '');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure HandlerA(var RequestPage: TestRequestPage "OBO Saved A")
    begin
        case Mode of
            Mode::Set:
                begin
                    RequestPage.SomeFilter.SetValue(SetTxt);
                    RequestPage.OK().Invoke();
                end;
            Mode::SetCancel:
                begin
                    RequestPage.SomeFilter.SetValue(SetTxt);
                    RequestPage.Cancel().Invoke();
                end;
            Mode::Read:
                begin
                    SeenTxt := RequestPage.SomeFilter.Value();
                    RequestPage.Cancel().Invoke();
                end;
            Mode::ReadOk:
                begin
                    SeenTxt := RequestPage.SomeFilter.Value();
                    RequestPage.OK().Invoke();
                end;
        end;
    end;

    [RequestPageHandler]
    procedure HandlerB(var RequestPage: TestRequestPage "OBO Saved B")
    begin
        case Mode of
            Mode::Set:
                begin
                    RequestPage.SomeFilter.SetValue(SetTxt);
                    RequestPage.OK().Invoke();
                end;
            else begin
                SeenTxt := RequestPage.SomeFilter.Value();
                RequestPage.Cancel().Invoke();
            end;
        end;
    end;

    [RequestPageHandler]
    procedure HandlerU(var RequestPage: TestRequestPage "OBO Unsaved")
    begin
        RequestPage.SomeFilter.SetValue(SetTxt);
        RequestPage.OK().Invoke();
    end;
}
