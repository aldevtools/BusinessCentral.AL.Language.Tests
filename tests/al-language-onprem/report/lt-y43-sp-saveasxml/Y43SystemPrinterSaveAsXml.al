// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-saveasxml-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath)
// Fixtures used: Probe Observer (69160) and table 92854 "LT Y43 SP Row" from the AL Language Coverage Tests app; own report 98691 and
//   SingleInstance log 98690 (used only by test codeunit 98692)
// Probe (writer Y43, gap cycle 4, G4-11 shape B): Report.Run(Id, true, SystemPrinter, Rec) of a report with an RDLC layout whose request page
//   handler sets a data item filter and calls SaveAsXml: the outcome, the triggers that ran, and the report data file, with SystemPrinter
//   true and with false in the same test. Only the data file is read (the parameters file holds the execution time).
// Probe: values recorded on the corpus CI containers (OnPrem legs).

codeunit 98690 "LT Y43 SPX Log"
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

report 98691 "LT Y43 SPX Layout"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(D; "LT Y43 SP Row")
        {
            RequestFilterFields = "No.";
            column(NoCol; "No.") { }
            column(AmountCol; Amount) { }

            trigger OnPreDataItem()
            begin
                Log.Add('pre-di ' + D.GetFilters());
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('row ' + D."No.");
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(FlagField; Flag) { ApplicationArea = All; Caption = 'Flag'; }
            }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './LtY43SpxLayout.rdl';
            Caption = 'Y43 SPX layout';
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post');
    end;

    var
        Log: Codeunit "LT Y43 SPX Log";
        Flag: Boolean;
}

codeunit 98692 "LT Y43 SPX Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y43 SPX Log";
        ParametersFile: Text;
        DataFile: Text;

    local procedure Seed()
    var
        Row: Record "LT Y43 SP Row";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Amount := 1;
        Row.Insert();
        Row."No." := 'B';
        Row.Amount := 2;
        Row.Insert();
        Row."No." := 'C';
        Row.Amount := 3;
        Row.Insert();
        Commit();
        ParametersFile := TemporaryPath() + 'lt-y43-spx-params.xml';
        DataFile := TemporaryPath() + 'lt-y43-spx-data.xml';
        Log.Take();
    end;

    [TryFunction]
    local procedure TryRun(SystemPrinter: Boolean)
    var
        Row: Record "LT Y43 SP Row";
    begin
        Report.Run(Report::"LT Y43 SPX Layout", true, SystemPrinter, Row);
    end;

    local procedure ReadData(): Text
    var
        SaveFile: File;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        if not Exists(DataFile) then
            exit('<no file>');
        SaveFile.Open(DataFile);
        SaveFile.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        SaveFile.Close();
        exit(Result);
    end;

    local procedure Outcome(SystemPrinter: Boolean): Text
    var
        Result: Text;
    begin
        if Exists(DataFile) then
            Erase(DataFile);
        Log.Take();
        ClearLastError();
        if TryRun(SystemPrinter) then
            Result := 'ok'
        else
            Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        exit(Result + ' / ' + Log.Take());
    end;

    [RequestPageHandler]
    procedure RlSaveXml(var Request: TestRequestPage "LT Y43 SPX Layout")
    begin
        Log.Add('rp');
        Request.D.SetFilter("No.", 'A|B');
        Request.SaveAsXml(ParametersFile, DataFile);
    end;

    [Test]
    [HandlerFunctions('RlSaveXml')]
    procedure Y43_G411_Layout_Run_ReqTrue_Sp_SaveAsXml()
    var
        DataTrue: Text;
    begin
        Seed();
        Observer.Observe('systemPrinterTrue', Outcome(true));
        DataTrue := ReadData();
        Observer.Observe('dataTrue', DataTrue);
        Observer.Observe('systemPrinterFalse', Outcome(false));
        Observer.Observe('dataSame', Format(ReadData() = DataTrue));
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G411_Layout_Run_ReqTrue_Sp_SaveAsXml_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y43_G411_Layout_Run_ReqTrue_Sp_SaveAsXml_More2()
    begin
        Observer.More();
    end;
}
