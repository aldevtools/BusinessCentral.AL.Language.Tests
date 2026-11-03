// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveaspdf-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (Report.SaveAsPdf to a file name, File and TemporaryPath are Scope = OnPrem)
// Fixtures used: Probe Observer (69160); self-contained tables 98020 and 98021, reports 98022 (ProcessingOnly) and 98023 (RDLC layout
//   ./report/lt-qx-saveaspdf/LtQxPdfRdlc.rdlc), test codeunit 98024
// Probe (writer QX, Microsoft's DemoTool: Clear(Rpt); Rpt.InitializeRequest(...); Rpt.SetTableView(...); Rpt.UseRequestPage(false);
//   Rpt.SaveAsPdf(TemporaryPath + Format(CreateGuid()) + '.pdf') on posting reports): whether SaveAsPdf on a Report variable runs the report's
//   triggers and keeps the rows they write, as Run does, for a ProcessingOnly report and for a report with an RDLC layout; the return value,
//   the last error, whether the file exists and is not empty. The RDLC file forms without writes are pinned in report/lt-am-rdlc-saveas.
// BC versions: 27-29

table 98020 "LT QX Pdf Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 98021 "LT QX Pdf Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Msg; Text[100]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

report 98022 "LT QX Pdf Processing"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(T; "LT QX Pdf Row")
        {
            trigger OnAfterGetRecord()
            begin
                Write(Tag + ' row ' + Format(T.Id));
            end;
        }
    }

    trigger OnPreReport()
    begin
        Write(Tag + ' pre');
    end;

    trigger OnPostReport()
    begin
        Write(Tag + ' post');
    end;

    var
        Tag: Text;

    procedure InitializeRequest(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    local procedure Write(Msg: Text)
    var
        Log: Record "LT QX Pdf Log";
    begin
        Log.Msg := CopyStr(Msg, 1, MaxStrLen(Log.Msg));
        Log.Insert();
    end;
}

report 98023 "LT QX Pdf Rdlc"
{
    UsageCategory = None;
    DefaultRenderingLayout = LtQxPdfRdlc;

    dataset
    {
        dataitem(T; "LT QX Pdf Row")
        {
            column(Id; Id) { }
            column(Txt; Txt) { }

            trigger OnAfterGetRecord()
            begin
                Write(Tag + ' row ' + Format(T.Id));
            end;
        }
    }

    rendering
    {
        layout(LtQxPdfRdlc)
        {
            Type = RDLC;
            LayoutFile = './reports/layouts-saveas/LtQxPdfRdlc.rdlc';
        }
    }

    trigger OnPreReport()
    begin
        Write(Tag + ' pre');
    end;

    trigger OnPostReport()
    begin
        Write(Tag + ' post');
    end;

    var
        Tag: Text;

    procedure InitializeRequest(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    local procedure Write(Msg: Text)
    var
        Log: Record "LT QX Pdf Log";
    begin
        Log.Msg := CopyStr(Msg, 1, MaxStrLen(Log.Msg));
        Log.Insert();
    end;
}

codeunit 98024 "LT QX Pdf Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT QX Pdf Row";
        Log: Record "LT QX Pdf Log";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        Row.Id := 1;
        Row.Txt := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Txt := 'two';
        Row.Insert();
    end;

    local procedure TakeLog(): Text
    var
        Log: Record "LT QX Pdf Log";
        Result: Text;
    begin
        if Log.FindSet() then
            repeat
                Result += Log.Msg + ',';
            until Log.Next() = 0;
        Log.DeleteAll();
        exit(Result);
    end;

    local procedure FileState(Name: Text): Text
    var
        F: File;
        Len: Integer;
    begin
        if not File.Exists(Name) then
            exit('no file');
        F.Open(Name);
        Len := F.Len();
        F.Close();
        File.Erase(Name);
        exit('exists, length > 0: ' + Format(Len > 0));
    end;

    local procedure Outcome(Name: Text; Saved: Boolean; FileName: Text)
    begin
        Observer.Observe(Name + ' saved', Format(Saved));
        Observer.Observe(Name + ' last error', GetLastErrorText());
        ClearLastError();
        Observer.Observe(Name + ' file', FileState(FileName));
        Observer.Observe(Name + ' log', TakeLog());
    end;

    [Test]
    procedure QX_SaveAsPdf_ProcessingOnly_Variable()
    var
        Rpt: Report "LT QX Pdf Processing";
        Row: Record "LT QX Pdf Row";
        Name: Text;
        Saved: Boolean;
    begin
        Seed();
        Clear(Rpt);
        Rpt.InitializeRequest('a');
        Rpt.UseRequestPage(false);
        Name := TemporaryPath() + Format(CreateGuid()) + '.pdf';
        Saved := Rpt.SaveAsPdf(Name);
        Outcome('variable', Saved, Name);
        Clear(Rpt);
        Rpt.InitializeRequest('b');
        Row.SetRange(Id, 2);
        Rpt.SetTableView(Row);
        Rpt.UseRequestPage(false);
        Name := TemporaryPath() + Format(CreateGuid()) + '.pdf';
        Saved := Rpt.SaveAsPdf(Name);
        Outcome('variable with view', Saved, Name);
        Name := TemporaryPath() + Format(CreateGuid()) + '.pdf';
        Saved := Report.SaveAsPdf(Report::"LT QX Pdf Processing", Name);
        Outcome('static', Saved, Name);
        Clear(Rpt);
        Rpt.InitializeRequest('c');
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('run log', TakeLog());
        Observer.Expect('variable saved', 'No');
        Observer.Expect('variable last error', 'Report 98022 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('variable file', 'no file');
        Observer.Expect('variable log', '');
        Observer.Expect('variable with view saved', 'No');
        Observer.Expect('variable with view last error', 'Report 98022 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('variable with view file', 'no file');
        Observer.Expect('variable with view log', '');
        Observer.Expect('static saved', 'No');
        Observer.Expect('static last error', 'Report 98022 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('static file', 'no file');
        Observer.Expect('static log', '');
        Observer.Expect('run log', 'c pre,c row 1,c row 2,c post,');
        Observer.Verify();
    end;

    [Test]
    procedure QX_SaveAsPdf_RdlcLayout_Variable()
    var
        Rpt: Report "LT QX Pdf Rdlc";
        Row: Record "LT QX Pdf Row";
        Name: Text;
        Saved: Boolean;
    begin
        Seed();
        Clear(Rpt);
        Rpt.InitializeRequest('a');
        Rpt.UseRequestPage(false);
        Name := TemporaryPath() + Format(CreateGuid()) + '.pdf';
        Saved := Rpt.SaveAsPdf(Name);
        Outcome('variable', Saved, Name);
        Clear(Rpt);
        Rpt.InitializeRequest('b');
        Row.SetRange(Id, 2);
        Rpt.SetTableView(Row);
        Rpt.UseRequestPage(false);
        Name := TemporaryPath() + Format(CreateGuid()) + '.pdf';
        Saved := Rpt.SaveAsPdf(Name);
        Outcome('variable with view', Saved, Name);
        Observer.Expect('variable saved', 'Yes');
        Observer.Expect('variable last error', '');
        Observer.Expect('variable file', 'exists, length > 0: Yes');
        Observer.Expect('variable log', 'a pre,a row 1,a row 2,a post,');
        Observer.Expect('variable with view saved', 'Yes');
        Observer.Expect('variable with view last error', '');
        Observer.Expect('variable with view file', 'exists, length > 0: Yes');
        Observer.Expect('variable with view log', 'b pre,b row 2,b post,');
        Observer.Verify();
    end;

    // The DemoTool form: the result of SaveAsPdf unused. For the ProcessingOnly report it raises the error (asserterror; the code is not
    // asserted, it was not observed), and no trigger ran.
    [Test]
    procedure QX_SaveAsPdf_ProcessingOnly_ResultUnused()
    var
        Rpt: Report "LT QX Pdf Processing";
        Name: Text;
    begin
        Seed();
        Clear(Rpt);
        Rpt.InitializeRequest('u');
        Rpt.UseRequestPage(false);
        Name := TemporaryPath() + Format(CreateGuid()) + '.pdf';
        asserterror Rpt.SaveAsPdf(Name);
        Observer.ObserveError('result unused');
        Observer.Observe('result unused file', FileState(Name));
        Observer.Observe('result unused log', TakeLog());
        Observer.Expect('result unused|text', 'Report 98022 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Ignore('result unused|code');
        Observer.Expect('result unused file', 'no file');
        Observer.Expect('result unused log', '');
        Observer.Verify();
    end;

    [Test]
    procedure QX_SaveAsPdf_RdlcLayout_ResultUnused()
    var
        Rpt: Report "LT QX Pdf Rdlc";
        Name: Text;
    begin
        Seed();
        Clear(Rpt);
        Rpt.InitializeRequest('u');
        Rpt.UseRequestPage(false);
        Name := TemporaryPath() + Format(CreateGuid()) + '.pdf';
        Rpt.SaveAsPdf(Name);
        Outcome('result unused', true, Name);
        Observer.Expect('result unused saved', 'Yes');
        Observer.Expect('result unused last error', '');
        Observer.Expect('result unused file', 'exists, length > 0: Yes');
        Observer.Expect('result unused log', 'u pre,u row 1,u row 2,u post,');
        Observer.Verify();
    end;
}
