// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160); reports 91851 and 91854 (Y17LayoutExportObjects.al); layout files copied to session/res/trl
// Probe: Tenant Report Layout (draft, observation form).

codeunit 97000 "LT TRL Resource Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Hex(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1));
    end;

    local procedure DescribeStream(var Observer: Codeunit "Probe Observer"; Name: Text; var Source: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
        Crypto: Codeunit "Cryptography Management";
        OutS: OutStream;
        InS: InStream;
        B: Byte;
        First: Text;
        i: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        CopyStream(OutS, Source);
        Observer.Observe(Name + ' length', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS);
        for i := 1 to 4 do begin
            InS.Read(B);
            First += Hex(B);
        end;
        Observer.Observe(Name + ' first bytes', First);
        TempBlob.CreateInStream(InS);
        Observer.Observe(Name + ' sha256', Crypto.GenerateHash(InS, 2));
    end;

    [TryFunction]
    local procedure TryLayout(Kind: Text; ReportId: Integer; var InS: InStream; var Got: Boolean)
    begin
        case Kind of
            'word':
                Got := Report.WordLayout(ReportId, InS);
            'rdlc':
                Got := Report.RdlcLayout(ReportId, InS);
            'excel':
                Got := Report.ExcelLayout(ReportId, InS);
        end;
    end;

    local procedure DescribeLayoutFor(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Text; ReportId: Integer; ResourceName: Text)
    var
        InS: InStream;
        Got: Boolean;
    begin
        if not TryLayout(Kind, ReportId, InS, Got) then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end else begin
            Observer.Observe(Name + ' returned', Format(Got));
            if Got then
                DescribeStream(Observer, Name + ' report', InS);
        end;
        if ResourceName <> '' then begin
            NavApp.GetResource(ResourceName, InS);
            DescribeStream(Observer, Name + ' file', InS);
        end;
    end;

    [Test]
    procedure FreshTenant_AllRows()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        Line: Text;
    begin
        Observer.Observe('count', Format(Layout.Count()));
        if Layout.FindSet() then
            repeat
                Line += Format(Layout."Report ID") + ':' + Layout.Name + ':' + CopyStr(Format(Layout."App ID"), 1, 9) + ':' + Format(Layout."Layout Format") + ':' + Format(Layout."Company Name" = '') + '|';
            until Layout.Next() = 0;
        Observer.Observe('rows', Line);
        Observer.Finish();
    end;

    [Test]
    procedure WordLayout_Stream_VsFile()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DescribeLayoutFor(Observer, 'word R1', 'word', Report::"LT Y17 Lay R1", 'trl/Y17LayR1.docx');
        Observer.Finish();
    end;

    [Test]
    procedure RdlcAndExcelLayout_Stream_VsFile()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DescribeLayoutFor(Observer, 'rdlc R1', 'rdlc', Report::"LT Y17 Lay R1", 'trl/Y17LayR1.rdl');
        DescribeLayoutFor(Observer, 'excel R4', 'excel', Report::"LT Y17 Lay R4", 'trl/Y17LayR4.xlsx');
        Observer.Finish();
    end;

    [Test]
    procedure LayoutOfWrongKind_Returned()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DescribeLayoutFor(Observer, 'word R4', 'word', Report::"LT Y17 Lay R4", '');
        DescribeLayoutFor(Observer, 'rdlc R4', 'rdlc', Report::"LT Y17 Lay R4", '');
        DescribeLayoutFor(Observer, 'excel R1', 'excel', Report::"LT Y17 Lay R1", '');
        Observer.Finish();
    end;

    local procedure DoInsert(var Observer: Codeunit "Probe Observer"; Tag: Text; ReportId: Integer; Kind: Option; ResourceName: Text; CustomType: Guid)
    var
        Layout: Record "Tenant Report Layout";
        Reader: Record "Tenant Report Layout";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        LayoutName: Text[250];
        Ok: Boolean;
    begin
        LayoutName := CopyStr(Delchr(Format(CreateGuid()), '=', '{}'), 1, 250);
        Layout.Init();
        Layout."Report ID" := ReportId;
        Layout.Name := LayoutName;
        Layout."Layout Format" := Kind;
        Layout."Custom Type" := CustomType;
        NavApp.GetResource(ResourceName, InS);
        Layout.Layout.ImportStream(InS, 'trl');
        Ok := Codeunit.Run(Codeunit::"LT TRL Insert", Layout);
        Observer.Observe(Tag + ' insert', Format(Ok));
        if not Ok then begin
            Observer.Observe(Tag + ' error', GetLastErrorText());
            Observer.Observe(Tag + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Reader.SetRange(Name, LayoutName);
        Observer.Observe(Tag + ' rows', Format(Reader.Count()));
        if Reader.FindFirst() then begin
            Observer.Observe(Tag + ' stored', Format(Reader."Report ID") + '|' + Format(Reader."Layout Format") + '|' + Format(IsNullGuid(Reader."App ID")) + '|' + Format(IsNullGuid(Reader."Custom Type")) + '|' + Reader."MIME Type" + '|' + Reader.Description + '|' + Format(Reader."Company Name" = ''));
            Observer.Observe(Tag + ' has value', Format(Reader.Layout.HasValue()));
            TempBlob.CreateOutStream(OutS);
            Observer.Observe(Tag + ' export', Format(Reader.Layout.ExportStream(OutS)));
            Observer.Observe(Tag + ' length', Format(TempBlob.Length()));
            Reader.DeleteAll();
        end;
    end;

    [Test]
    procedure Insert_Word_EmptyBody_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'word', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Word, 'trl/Y67BaseDoc.docx', NoType);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Word_Bindings_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'bindings', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Word, 'trl/Y17LayR1.docx', NoType);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Word_Bindings_OwnReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'own', Report::"LT Y17 Lay R1", Layout."Layout Format"::Word, 'trl/Y17LayR1.docx', NoType);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Rdlc_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'rdlc', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::RDLC, 'trl/Y17LayR1.rdl', NoType);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Rdlc_OwnReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'rdlc own', Report::"LT Y17 Lay R1", Layout."Layout Format"::RDLC, 'trl/Y17LayR1.rdl', NoType);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Excel_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'excel', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Excel, 'trl/Y17LayR4.xlsx', NoType);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Excel_OwnReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'excel own', Report::"LT Y17 Lay R4", Layout."Layout Format"::Excel, 'trl/Y17LayR4.xlsx', NoType);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Custom_NoType_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'custom no type', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Custom, 'trl/Y67BaseDoc.docx', NoType);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Custom_UnknownType_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'custom unknown type', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Custom, 'trl/Y67BaseDoc.docx', CreateGuid());
        Observer.Finish();
    end;
}

codeunit 97001 "LT TRL Insert"
{
    TableNo = "Tenant Report Layout";

    trigger OnRun()
    begin
        Rec.Insert();
    end;
}
