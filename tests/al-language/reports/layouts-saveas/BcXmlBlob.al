// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in BcXmlBlobObjects.al
// Corpus issue 659 item 4 (from al-runtime-rs #253): Report.SaveAs with ReportFormat::Xml succeeds for a dataset with a Blob column.
// These tests read the XML text written for Blob, Media and MediaSet columns, empty and with content.

codeunit 80979 "BC Xml Blob"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;

    local procedure Dataset(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        All: Text;
        Lf: Text[1];
        At: Integer;
    begin
        Lf[1] := 10;
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        if not Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS) then
            exit('not saved: ' + GetLastErrorText());
        if not TempBlob.HasValue() then
            exit('empty');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            All += Line + Lf;
        end;
        At := All.IndexOf('<DataItems>');
        if At = 0 then
            exit('no DataItems: ' + All);
        exit(MaskSystemIds(All.Substring(At)));
    end;

    // The systemId attribute of each DataItem is the SystemId of a row inserted by the test, new on every run: only its shape is kept.
    local procedure MaskSystemIds(T: Text): Text
    var
        Marker: Text;
        Result: Text;
        At: Integer;
    begin
        Marker := 'systemId="';
        At := T.IndexOf(Marker);
        while At > 0 do begin
            Result += T.Substring(1, At - 1) + Marker;
            T := T.Substring(At + StrLen(Marker));
            if (StrLen(T) > 36) and (T[37] = '"') then begin
                Result += '<guid36>';
                T := T.Substring(37);
            end;
            At := T.IndexOf(Marker);
        end;
        exit(Result + T);
    end;

    local procedure PngStream(var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64(ValidPngBase64, OutS);
        TempBlob.CreateInStream(InS);
    end;

    local procedure Setup()
    var
        Row: Record "BC Blob Row";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Note := 'empty';
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Note := 'text';
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('Hello BC');
        Row.Insert();
    end;

    [Test]
    procedure Xml_BlobMediaColumns_EmptyAndText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BC Blob Row";
    begin
        Setup();
        Observer.Observe('dataset', Dataset(Report::"BC Xml Blob Columns"));
        Row.DeleteAll();
#if BC28PLUS
        Observer.Expect('dataset', '<DataItems>\n    <DataItem language="en-US" formatRegion="en-US" name="Row" tableId="80975" systemId="<guid36>">\n      <Columns>\n        <Column name="Id">1</Column>\n        <Column name="BlobCol"></Column>\n        <Column name="MediaCol"></Column>\n        <Column name="MediaSetCol"></Column>\n        <Column name="NoteCol">empty</Column>\n      </Columns>\n    </DataItem>\n    <DataItem language="en-US" formatRegion="en-US" name="Row" tableId="80975" systemId="<guid36>">\n      <Columns>\n        <Column name="Id">2</Column>\n        <Column name="BlobCol">SGVsbG8gQkM=</Column>\n        <Column name="MediaCol"></Column>\n        <Column name="MediaSetCol"></Column>\n        <Column name="NoteCol">text</Column>\n      </Columns>\n    </DataItem>\n  </DataItems>\n</ReportDataSet>\n');
#else
        Observer.Expect('dataset', '<DataItems>\n    <DataItem language="en-US" formatRegion="en-US" name="Row">\n      <Columns>\n        <Column name="Id">1</Column>\n        <Column name="BlobCol"></Column>\n        <Column name="MediaCol"></Column>\n        <Column name="MediaSetCol"></Column>\n        <Column name="NoteCol">empty</Column>\n      </Columns>\n    </DataItem>\n    <DataItem language="en-US" formatRegion="en-US" name="Row">\n      <Columns>\n        <Column name="Id">2</Column>\n        <Column name="BlobCol">SGVsbG8gQkM=</Column>\n        <Column name="MediaCol"></Column>\n        <Column name="MediaSetCol"></Column>\n        <Column name="NoteCol">text</Column>\n      </Columns>\n    </DataItem>\n  </DataItems>\n</ReportDataSet>\n');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Xml_BlobColumn_CalcFieldsInTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BC Blob Row";
    begin
        Setup();
        Observer.Observe('dataset', Dataset(Report::"BC Xml Blob CalcFields"));
        Row.DeleteAll();
#if BC28PLUS
        Observer.Expect('dataset', '<DataItems>\n    <DataItem language="en-US" formatRegion="en-US" name="Row" tableId="80975" systemId="<guid36>">\n      <Columns>\n        <Column name="Id">1</Column>\n        <Column name="BlobCol"></Column>\n      </Columns>\n    </DataItem>\n    <DataItem language="en-US" formatRegion="en-US" name="Row" tableId="80975" systemId="<guid36>">\n      <Columns>\n        <Column name="Id">2</Column>\n        <Column name="BlobCol">SGVsbG8gQkM=</Column>\n      </Columns>\n    </DataItem>\n  </DataItems>\n</ReportDataSet>\n');
#else
        Observer.Expect('dataset', '<DataItems>\n    <DataItem language="en-US" formatRegion="en-US" name="Row">\n      <Columns>\n        <Column name="Id">1</Column>\n        <Column name="BlobCol"></Column>\n      </Columns>\n    </DataItem>\n    <DataItem language="en-US" formatRegion="en-US" name="Row">\n      <Columns>\n        <Column name="Id">2</Column>\n        <Column name="BlobCol">SGVsbG8gQkM=</Column>\n      </Columns>\n    </DataItem>\n  </DataItems>\n</ReportDataSet>\n');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Xml_BlobColumn_BinaryBytes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BC Blob Row";
        OutS: OutStream;
        B: Byte;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 3;
        Row.Note := 'bytes';
        Row.Data.CreateOutStream(OutS);
        B := 0;
        OutS.Write(B);
        B := 255;
        OutS.Write(B);
        B := 65;
        OutS.Write(B);
        Row.Insert();
        Observer.Observe('dataset', Dataset(Report::"BC Xml Blob CalcFields"));
        Row.DeleteAll();
#if BC28PLUS
        Observer.Expect('dataset', '<DataItems>\n    <DataItem language="en-US" formatRegion="en-US" name="Row" tableId="80975" systemId="<guid36>">\n      <Columns>\n        <Column name="Id">3</Column>\n        <Column name="BlobCol">AP9B</Column>\n      </Columns>\n    </DataItem>\n  </DataItems>\n</ReportDataSet>\n');
#else
        Observer.Expect('dataset', '<DataItems>\n    <DataItem language="en-US" formatRegion="en-US" name="Row">\n      <Columns>\n        <Column name="Id">3</Column>\n        <Column name="BlobCol">AP9B</Column>\n      </Columns>\n    </DataItem>\n  </DataItems>\n</ReportDataSet>\n');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Xml_CompanyPicture_Repro()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record "Company Information";
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
        Text: Text;
        Expected: Text;
    begin
        // The repro of al-runtime-rs #253: the dataset is written. The picture is the company's own (it depends on the database), so the test
        // compares the column with the Base64 text of that picture instead of a fixed value.
        Company.Get();
        Company.CalcFields(Picture);
        Expected := '<Column name="CompanyPicture"></Column>';
        if Company.Picture.HasValue() then begin
            Company.Picture.CreateInStream(InS);
            Expected := '<Column name="CompanyPicture">' + Base64.ToBase64(InS) + '</Column>';
        end;
        Text := Dataset(Report::"BC Xml Company Picture");
        Observer.Observe('saved', Format(Text.StartsWith('<DataItems>')));
        Observer.Observe('picture column is base64 of the picture', Format(Text.Contains(Expected)));
        Observer.Observe('num column', Format(Text.Contains('<Column name="Num">1</Column>')));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('picture column is base64 of the picture', 'Yes');
        Observer.Expect('num column', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Xml_MediaColumns_WithContent()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BC Blob Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Text: Text;
        SetId: Guid;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 4;
        Row.Note := 'media';
        Row.Insert();
        PngStream(TempBlob, InS);
        Row.Pic.ImportStream(InS, 'bc probe');
        PngStream(TempBlob, InS);
        Row.Pics.ImportStream(InS, 'bc probe set');
        Row.Modify();
        SetId := Row.Pics.MediaId();
        Observer.Observe('media has value', Format(Row.Pic.HasValue()));
        Observer.Observe('media set count', Format(Row.Pics.Count()));
        Text := Dataset(Report::"BC Xml Blob Columns");
        // Media and MediaSet ids are new on every run: they are replaced by placeholders in every spelling the dataset could use.
        Text := Mask(Text, Row.Pic.MediaId(), 'media');
        Text := Mask(Text, SetId, 'mediaset');
        Text := Mask(Text, Row.Pics.Item(1), 'mediaset-item');
        // Windows writes the same re-encoded PNG on every version (Windows BC 27.5/28.5 check 2026-10-20, 27.5/29.0 Windows check 3): the exact
        // Base64 is asserted. Before the bc-linux #135 and #161 fixes the Linux image kept the imported bytes on 29 and re-encoded them differently on 27/28.
        Observer.Observe('dataset', Text);
        Row.DeleteAll();
        Observer.Expect('media has value', 'Yes');
        Observer.Expect('media set count', '1');
#if BC28PLUS
        Observer.Expect('dataset', '<DataItems>\n    <DataItem language="en-US" formatRegion="en-US" name="Row" tableId="80975" systemId="<guid36>">\n      <Columns>\n        <Column name="Id">4</Column>\n        <Column name="BlobCol"></Column>\n        <Column name="MediaCol">iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAANSURBVBhXY2BgYPgPAAEEAQBwIGULAAAAAElFTkSuQmCC</Column>\n        <Column name="MediaSetCol">iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAANSURBVBhXY2BgYPgPAAEEAQBwIGULAAAAAElFTkSuQmCC</Column>\n        <Column name="NoteCol">media</Column>\n      </Columns>\n    </DataItem>\n  </DataItems>\n</ReportDataSet>\n');
#else
        Observer.Expect('dataset', '<DataItems>\n    <DataItem language="en-US" formatRegion="en-US" name="Row">\n      <Columns>\n        <Column name="Id">4</Column>\n        <Column name="BlobCol"></Column>\n        <Column name="MediaCol">iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAANSURBVBhXY2BgYPgPAAEEAQBwIGULAAAAAElFTkSuQmCC</Column>\n        <Column name="MediaSetCol">iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAANSURBVBhXY2BgYPgPAAEEAQBwIGULAAAAAElFTkSuQmCC</Column>\n        <Column name="NoteCol">media</Column>\n      </Columns>\n    </DataItem>\n  </DataItems>\n</ReportDataSet>\n');
#endif
        Observer.Verify();
    end;

    local procedure Mask(T: Text; Id: Guid; Name: Text): Text
    var
        Bare: Text;
    begin
        if IsNullGuid(Id) then
            exit(T);
        Bare := DelChr(Format(Id), '=', '{}');
        T := T.Replace(Format(Id), '<' + Name + '-braced>');
        T := T.Replace(Bare, '<' + Name + '-upper>');
        exit(T.Replace(LowerCase(Bare), '<' + Name + '-lower>'));
    end;

    // A Media or MediaSet column holds the picture as Base64. On some versions the platform writes the imported bytes, on others a
    // re-encoded PNG whose bytes depend on the image library of the server: only that distinction is asserted, not the re-encoded bytes.
    local procedure AnyPng(T: Text): Text
    begin
        T := T.Replace('<png-as-imported>', '<png>');
        exit(T.Replace('<png-re-encoded>', '<png>'));
    end;

    local procedure ClassifyPng(T: Text): Text
    var
        Result: Text;
        Rest: Text;
        At: Integer;
        EndAt: Integer;
    begin
        T := T.Replace('>' + ValidPngBase64 + '<', '><png-as-imported><');
        At := T.IndexOf('>iVBORw0KGgo');
        while At > 0 do begin
            Result += T.Substring(1, At) + '<png-re-encoded>';
            Rest := T.Substring(At + 1);
            EndAt := Rest.IndexOf('<');
            if EndAt = 0 then
                exit(Result + Rest);
            T := Rest.Substring(EndAt);
            At := T.IndexOf('>iVBORw0KGgo');
        end;
        exit(Result + T);
    end;
}
