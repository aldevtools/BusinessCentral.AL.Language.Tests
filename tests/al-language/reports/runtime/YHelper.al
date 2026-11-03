// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob and Data Compression (System Application)
// Probe: written against BC service tiers of the corpus matrix; every literal asserted in the tests of this folder is what the tier produced.
// Facts: helper and shared state of the writer Y probes (reports 75501-75549): SaveAs wrappers, a zip entry reader, a row dumper and a SingleInstance store for values seen in handlers.
// BC versions: 27-29 (version differences are guarded)

codeunit 75500 "LT Y Helper"
{
    procedure SaveAsText(ReportId: Integer; Format: ReportFormat): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', Format, OutS);
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    // The DataItems part of the SaveAs Xml text (the header before it is not asserted), without systemId and tableId attributes.
    procedure DataItemsXml(ReportId: Integer): Text
    var
        Xml: Text;
        At: Integer;
    begin
        Xml := StripAttribute(StripAttribute(SaveAsText(ReportId, ReportFormat::Xml), ' systemId="', 37), ' tableId="', 0);
        At := StrPos(Xml, '<DataItems>');
        if At = 0 then
            exit('no DataItems element');
        exit(CopyStr(Xml, At));
    end;

    local procedure StripAttribute(Xml: Text; Marker: Text; FixedLength: Integer): Text
    var
        Result: Text;
        At: Integer;
    begin
        At := StrPos(Xml, Marker);
        while At > 0 do begin
            Result += CopyStr(Xml, 1, At - 1);
            if FixedLength > 0 then
                Xml := CopyStr(Xml, At + StrLen(Marker) + FixedLength)
            else begin
                Xml := CopyStr(Xml, At + StrLen(Marker));
                Xml := CopyStr(Xml, StrPos(Xml, '"') + 1);
            end;
            At := StrPos(Xml, Marker);
        end;
        exit(Result + Xml);
    end;

    // Size of the rendered file, the first bytes as text, and nothing else.
    procedure SaveAsSize(ReportId: Integer; Format: ReportFormat): Integer
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', Format, OutS);
        exit(TempBlob.Length());
    end;

    procedure SaveAsHead(ReportId: Integer; Format: ReportFormat; Count: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Buffer: Text;
        Head: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', Format, OutS);
        TempBlob.CreateInStream(InS);
        InS.Read(Buffer, Count);
        Head := Buffer;
        exit(Head);
    end;

    // Facts of the zip file a SaveAs Excel writes: number of worksheet entries, and the sheet names of xl/workbook.xml in order.
    procedure WorkbookFacts(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Entry: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        OutS: OutStream;
        InS: InStream;
        EntryOut: OutStream;
        EntryIn: InStream;
        Names: List of [Text];
        Name: Text;
        Workbook: Text;
        Line: Text;
        Sheets: Text;
        Rest: Text;
        Sheet: Integer;
        Length: Integer;
        Count: Integer;
        At: Integer;
        Marker: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', ReportFormat::Excel, OutS);
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(Names);
        foreach Name in Names do
            if Name.StartsWith('xl/worksheets/sheet') and not Name.Contains('_rels') then
                Count += 1;
        Entry.CreateOutStream(EntryOut);
        DataCompression.ExtractEntry('xl/workbook.xml', EntryOut, Length);
        DataCompression.CloseZipArchive();
        Entry.CreateInStream(EntryIn);
        while not EntryIn.EOS() do begin
            EntryIn.ReadText(Line);
            Workbook += Line;
        end;
        for Sheet := 1 to 2 do begin
            if Sheet = 1 then
                Marker := '<x:sheet '
            else
                Marker := '<sheet ';
            Rest := Workbook;
            At := StrPos(Rest, Marker);
            while At > 0 do begin
                Rest := CopyStr(Rest, At + StrLen(Marker));
                At := StrPos(Rest, 'name="');
                Rest := CopyStr(Rest, At + 6);
                Sheets += CopyStr(Rest, 1, StrPos(Rest, '"') - 1) + ',';
                At := StrPos(Rest, Marker);
            end;
        end;
        exit('worksheet_entries=' + Format(Count) + ' sheets=' + Sheets);
    end;

    // Every character above 126 written as \uXXXX, so a value survives the test result file unchanged.
    procedure AsciiOnly(Value: Text): Text
    var
        i: Integer;
        Code: Integer;
        Hex: Text;
        Result: Text;
    begin
        Hex := '0123456789ABCDEF';
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            if Code > 126 then
                Result += '\u' + CopyStr(Hex, (Code div 4096) + 1, 1) + CopyStr(Hex, ((Code div 256) mod 16) + 1, 1) + CopyStr(Hex, ((Code div 16) mod 16) + 1, 1) + CopyStr(Hex, (Code mod 16) + 1, 1)
            else
                Result += CopyStr(Value, i, 1);
        end;
        exit(Result);
    end;

    // Name=Summary (the Description column of Report Layout List) of the layouts of one report, in the language of the session.
    procedure LayoutSummaries(ReportId: Integer): Text
    var
        LayoutList: Record "Report Layout List";
        Result: Text;
    begin
        LayoutList.SetRange("Report ID", ReportId);
        if LayoutList.FindSet() then
            repeat
                Result += LayoutList.Name + '=' + LayoutList.Description + ';';
            until LayoutList.Next() = 0;
        exit(Result);
    end;

    // Every non-blob column of the current row as name=value; used for system table rows (Report Layout List, Report Metadata, XmlPort Metadata).
    procedure DumpRow(var RR: RecordRef): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if not (FR.Type in [FieldType::Blob, FieldType::Media, FieldType::MediaSet, FieldType::Guid, FieldType::DateTime]) then
                Result += FR.Name + '=' + Format(FR.Value) + ';';
        end;
        exit(Result);
    end;

    // Name=value of the named columns of one row (a column that does not exist on the platform shows as absent).
    procedure Facts(TableNo: Integer; KeyField: Integer; Id: Integer; Names: Text): Text
    var
        RR: RecordRef;
        FR: FieldRef;
        Wanted: Text;
        i: Integer;
        Found: Boolean;
        Result: Text;
    begin
        RR.Open(TableNo);
        FR := RR.Field(KeyField);
        FR.SetRange(Id);
        if not RR.FindFirst() then begin
            RR.Close();
            exit('no row');
        end;
        foreach Wanted in Names.Split(',') do begin
            Found := false;
            for i := 1 to RR.FieldCount() do begin
                FR := RR.FieldIndex(i);
                if FR.Name = Wanted then begin
                    Result += Wanted + '=' + Format(FR.Value) + ';';
                    Found := true;
                end;
            end;
            if not Found then
                Result += Wanted + '=absent;';
        end;
        RR.Close();
        exit(Result);
    end;

    procedure ReportFacts(ReportId: Integer): Text
    begin
        exit(Facts(2000000139, 1, ReportId, 'UseRequestPage,ProcessingOnly,EnableExternalImages,EnableExternalAssemblies,PaperSourceFirstPage,PaperSourceDefaultPage,PaperSourceLastPage,DefaultLayout,DefaultLayoutName,FormatRegion,ExcelLayoutMultipleDataSheets,DefaultHeaderFooterPartName,DefaultThemePartName'));
    end;

    procedure RowOf(TableNo: Integer; KeyField: Integer; Id: Integer): Text
    var
        RR: RecordRef;
        FR: FieldRef;
        Result: Text;
    begin
        RR.Open(TableNo);
        FR := RR.Field(KeyField);
        FR.SetRange(Id);
        if RR.FindFirst() then
            Result := DumpRow(RR)
        else
            Result := 'no row';
        RR.Close();
        exit(Result);
    end;

    // Name, format, Excel sheet setting and subtype of the layouts of one report.
    procedure LayoutFacts(ReportId: Integer): Text
    var
        LayoutList: Record "Report Layout List";
        Result: Text;
    begin
        LayoutList.SetRange("Report ID", ReportId);
        if LayoutList.FindSet() then
            repeat
                Result += '[' + LayoutList.Name + ' ' + Format(LayoutList."Layout Format") + ' multi=' + Format(LayoutList.ExcelLayoutMultipleDataSheets, 0, 2) + ']';
            until LayoutList.Next() = 0
        else
            Result := 'no layouts';
        exit(Result);
    end;

    // The rows of Report Layout List (2000000234) of one report: one entry per layout, all columns.
    procedure LayoutRows(ReportId: Integer): Text
    var
        LayoutList: Record "Report Layout List";
        RR: RecordRef;
        Result: Text;
    begin
        LayoutList.SetRange("Report ID", ReportId);
        if LayoutList.FindSet() then
            repeat
                RR.GetTable(LayoutList);
                Result += '[' + DumpRow(RR) + ']';
            until LayoutList.Next() = 0
        else
            Result := 'no layouts';
        exit(Result);
    end;

    // The rows of Report Data Items of one report: one entry per data item, all columns.
    procedure DataItemRows(ReportId: Integer): Text
    var
        Items: Record "Report Data Items";
        RR: RecordRef;
        Result: Text;
    begin
        Items.SetRange("Report ID", ReportId);
        if Items.FindSet() then
            repeat
                Result += '[' + Items.Name + ' filter_fields=' + Items."Request Filter Fields" + ' view=' + Items."Data Item Table View" + ']';
            until Items.Next() = 0
        else
            Result := 'no data items';
        exit(Result);
    end;

    procedure Failed(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;
}

codeunit 75501 "LT Y Seen"
{
    SingleInstance = true;

    var
        Entries: Dictionary of [Text, Text];

    procedure Put(Name: Text; Value: Text)
    begin
        if Entries.ContainsKey(Name) then
            Entries.Set(Name, Value)
        else
            Entries.Add(Name, Value);
    end;

    procedure Get(Name: Text): Text
    begin
        if Entries.ContainsKey(Name) then
            exit(Entries.Get(Name));
        exit('<none>');
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;
}
