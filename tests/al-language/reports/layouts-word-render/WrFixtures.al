// Fixtures of WrMergeTests.al: two own tables, the reports with hand-made Word layouts, and the helper that saves a report and reads parts
// of the Word package back. The layouts (Wr*.docx next to this file) start as the compiler's generated layout of their report (the custom XML
// part of the dataset) and get a body of content controls bound to that part: a repeating section (w15:repeatingSection) per data item and
// plain text controls bound to columns, the way Word writes them (storeItemID of the part's itemProps). Markers WR... are static text.

table 91100 "WR Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 91101 "WR Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; HeadId; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; Txt; Text[100]) { }
        field(4; Cd; Code[20]) { }
        field(5; Qty; Integer) { }
        field(6; Amt; Decimal) { AutoFormatType = 1; }
        field(7; Dt; Date) { }
        field(8; Flag; Boolean) { }
        field(9; Opt; Option) { OptionMembers = Alpha,Beta,Gamma; OptionCaption = 'Alpha Cap,Beta Cap,Gamma Cap'; }
        field(10; Pic; Blob) { Subtype = Bitmap; }
    }

    keys
    {
        key(PK; HeadId, LineNo) { Clustered = true; }
    }
}

// Gate: a table row repeats over Line, with static text and one bound column per row.
report 91110 "WR Gate Rows"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = WrGateRows;

    dataset
    {
        dataitem(Line; "WR Line")
        {
            column(LineTxt; Txt) { }
        }
    }

    rendering
    {
        layout(WrGateRows)
        {
            Type = Word;
            LayoutFile = './reports/layouts-word-render/WrGateRows.docx';
        }
    }
}

// The same repeater made of body paragraphs instead of a table row.
report 91111 "WR Gate Paras"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = WrGateParas;

    dataset
    {
        dataitem(Line; "WR Line")
        {
            column(LineTxt; Txt) { }
        }
    }

    rendering
    {
        layout(WrGateParas)
        {
            Type = Word;
            LayoutFile = './reports/layouts-word-render/WrGateParas.docx';
        }
    }
}

// The table row repeater with w:dataBinding instead of w15:dataBinding and no storeItemID.
report 91112 "WR Gate Plain Binding"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = WrGatePlain;

    dataset
    {
        dataitem(Line; "WR Line")
        {
            column(LineTxt; Txt) { }
        }
    }

    rendering
    {
        layout(WrGatePlain)
        {
            Type = Word;
            LayoutFile = './reports/layouts-word-render/WrGatePlain.docx';
        }
    }
}

codeunit 91139 "WR Helper"
{
    procedure Lines(N: Integer)
    var
        Line: Record "WR Line";
        I: Integer;
    begin
        Line.DeleteAll();
        for I := 1 to N do begin
            Line.Init();
            Line.HeadId := 1;
            Line.LineNo := I;
            Line.Txt := 'WRROW' + Format(I);
            Line.Insert();
        end;
    end;

    [TryFunction]
    local procedure TrySave(ReportId: Integer; Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob"; var Ok: Boolean)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Ok := Report.SaveAs(ReportId, '', Fmt, OutS);
    end;

    // Saves the report; observes whether it completed, what SaveAs returned, the error, the first four bytes and whether the stream is not empty.
    procedure Save(var Observer: Codeunit "Probe Observer"; ReportId: Integer; Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        Ok: Boolean;
        Completed: Boolean;
    begin
        ClearLastError();
        Completed := TrySave(ReportId, Fmt, TempBlob, Ok);
        Observer.Observe('completed', Format(Completed));
        Observer.Observe('returned', Format(Ok));
        Observer.ObserveError('err');
        Observer.Observe('head', Head(TempBlob));
        Observer.Observe('length > 0', Format(TempBlob.Length() > 0));
        exit(Completed and Ok and (TempBlob.Length() > 0));
    end;

    procedure Head(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        B: Byte;
        I: Integer;
        Code: Integer;
        Result: Text;
    begin
        if TempBlob.Length() = 0 then
            exit('empty');
        TempBlob.CreateInStream(InS);
        for I := 1 to 4 do
            if not InS.EOS() then begin
                InS.Read(B);
                Code := B;
                Result += Format(Code) + ',';
            end;
        exit(Result);
    end;

    // The entry names of the zip package, sorted, joined by ';'. Entries under package/services/metadata/core-properties/ are folded to that folder
    // name plus '*' (System.IO.Packaging names the file by a new GUID on every save).
    procedure Entries(var TempBlob: Codeunit "Temp Blob"): Text
    var
        DataCompression: Codeunit "Data Compression";
        InS: InStream;
        Names: List of [Text];
        Sorted: List of [Text];
        Name: Text;
        Result: Text;
        I: Integer;
        Done: Boolean;
    begin
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(Names);
        DataCompression.CloseZipArchive();
        foreach Name in Names do begin
            if Name.StartsWith('package/services/metadata/core-properties/') then
                Name := 'package/services/metadata/core-properties/*' + CopyStr(Name, StrLen(Name) - 6);
            Done := false;
            for I := 1 to Sorted.Count() do
                if (not Done) and (Name < Sorted.Get(I)) then begin
                    Sorted.Insert(I, Name);
                    Done := true;
                end;
            if not Done then
                Sorted.Add(Name);
        end;
        foreach Name in Sorted do
            Result += Name + ';';
        exit(Result);
    end;

    // The whole text of one entry of the zip package (UTF-8); 'missing' when the package has no such entry.
    procedure Part(var TempBlob: Codeunit "Temp Blob"; EntryName: Text): Text
    var
        DataCompression: Codeunit "Data Compression";
        Entry: Codeunit "Temp Blob";
        InS: InStream;
        EntryOut: OutStream;
        EntryIn: InStream;
        Names: List of [Text];
        Line: Text;
        Doc: Text;
        Length: Integer;
    begin
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(Names);
        if not Names.Contains(EntryName) then begin
            DataCompression.CloseZipArchive();
            exit('missing');
        end;
        Entry.CreateOutStream(EntryOut);
        DataCompression.ExtractEntry(EntryName, EntryOut, Length);
        DataCompression.CloseZipArchive();
        Entry.CreateInStream(EntryIn, TextEncoding::UTF8);
        while not EntryIn.EOS() do begin
            EntryIn.ReadText(Line);
            Doc += Line;
        end;
        exit(Doc);
    end;

    // The text of a WordprocessingML part without its markup: the text of every element is kept as it stands in the XML (entities are not
    // decoded), a paragraph end (</w:p>) becomes '/', a tab (<w:tab/>) becomes '~', a break (<w:br/>) becomes '^'.
    procedure PlainText(Xml: Text): Text
    var
        Result: TextBuilder;
        Tag: Text;
        I: Integer;
        J: Integer;
    begin
        I := 1;
        while I <= StrLen(Xml) do
            if Xml[I] = '<' then begin
                J := Xml.IndexOf('>', I);
                if J = 0 then
                    J := StrLen(Xml);
                Tag := CopyStr(Xml, I, J - I + 1);
                if Tag = '</w:p>' then
                    Result.Append('/');
                if Tag.StartsWith('<w:tab/') or Tag.StartsWith('<w:tab ') then
                    Result.Append('~');
                if Tag.StartsWith('<w:br/') or Tag.StartsWith('<w:br ') then
                    Result.Append('^');
                I := J + 1;
            end else begin
                Result.Append(Xml[I]);
                I += 1;
            end;
        exit(Result.ToText());
    end;

    // The text from StartMarker up to and including EndMarker; 'no start' or 'no end' when a marker is missing.
    procedure Between(Txt: Text; StartMarker: Text; EndMarker: Text): Text
    var
        S: Integer;
        E: Integer;
    begin
        S := Txt.IndexOf(StartMarker);
        if S = 0 then
            exit('no start');
        E := Txt.IndexOf(EndMarker, S + StrLen(StartMarker));
        if E = 0 then
            exit('no end');
        exit(CopyStr(Txt, S, E - S + StrLen(EndMarker)));
    end;

    procedure Occurrences(Txt: Text; Marker: Text): Integer
    var
        At: Integer;
        Count: Integer;
    begin
        At := Txt.IndexOf(Marker);
        while At > 0 do begin
            Count += 1;
            At := Txt.IndexOf(Marker, At + StrLen(Marker));
        end;
        exit(Count);
    end;

    // The plain text of word/document.xml of a saved Word package.
    procedure Body(var TempBlob: Codeunit "Temp Blob"): Text
    begin
        exit(PlainText(Part(TempBlob, 'word/document.xml')));
    end;
}
