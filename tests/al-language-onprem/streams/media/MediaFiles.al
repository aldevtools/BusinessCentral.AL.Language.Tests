// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-exportfile-method
// Scope: in-scope (OnPrem app: Media.ExportFile / ImportFile and MediaSet.ExportFile / ImportFile are Scope = OnPrem)
// Fixtures used: Probe Observer (codeunit 69160), table 61294 "PZ OnPrem Media Row" (session/PZMediaImportFile.al) and codeunit 61286
// Probe: written against BC 29 (runtime 16); the values are measured on the corpus CI service tiers.
// Facts: Media.ImportFile / ExportFile, MediaSet.ImportFile / ExportFile: returned Guid, Tenant Media properties, exported file, export of an empty media, a missing file
// Writer QX: a JPEG file through Media.ImportFile and MediaSet.ImportFile with two arguments (Tenant Media row, File Name form).
// Writer RD: a JPEG and an upper-case .PNG into one MediaSet (returned Guid = MediaId, not Item(1)); a .docx into a Media (mime, exported bytes;
//   BC 29 on the Linux tier stores a re-zipped package, not asserted).
// Writer RJ (DemoTool, Export RapidStart Packages: Config. XML Exchange.ExportMediaSet, ConfigXMLExchange.Codeunit.al:1433-1457, then
//   UpdateConfigPackageMediaSet and ImportMediaSetFromFile, :1505-1563): MediaSet.ExportFile(MediaFolder + '\' + Format(Set)) of a set with one
//   and a set with two items, the files File Management.GetServerDirectoryFilesList lists (names, order), their bytes against the imported files.
// Listing order (Windows check 7, 2026-10-23): GetServerDirectoryFilesList lists in name order, case ignored, also for ExportFile names
//   (RJ_GetServerDirectoryFilesList_ListingOrder).
// BC versions: 27, 28, 29
codeunit 61286 "LT S Media Files"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        RjObserver: Codeunit "Probe Observer";
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;

    local procedure TempName(Suffix: Text): Text
    begin
        exit(TemporaryPath() + 'ltsmedia' + DelChr(Format(CreateGuid()), '=', '{}-') + Suffix);
    end;

    local procedure WritePng(Name: Text)
    var
        F: File;
        OutS: OutStream;
        Base64: Codeunit "Base64 Convert";
    begin
        F.Create(Name);
        F.CreateOutStream(OutS);
        Base64.FromBase64(ValidPngBase64, OutS);
        F.Close();
    end;

    local procedure LenOf(Name: Text): Integer
    var
        F: File;
        L: Integer;
    begin
        F.Open(Name);
        L := F.Len();
        F.Close();
        exit(L);
    end;

    local procedure BaseOf(Name: Text): Text
    begin
        exit(CopyStr(Name, StrLen(TemporaryPath()) + 1));
    end;

    local procedure Cleanup(Name: Text)
    begin
        if File.Exists(Name) then
            File.Erase(Name);
    end;

    local procedure DescribeTenant(Id: Guid; BaseName: Text): Text
    var
        Tenant: Record "Tenant Media";
    begin
        if not Tenant.Get(Id) then
            exit('no tenant media row');
        Tenant.CalcFields(Content);
        exit('description=[' + Tenant.Description + '] mime=[' + Tenant."Mime Type" + '] filename_contains_source_name=' + Format(StrPos(Tenant."File Name", BaseName) > 0) + ' filename_longer_than_name=' + Format(StrLen(Tenant."File Name") > StrLen(BaseName)) + ' width=' + Format(Tenant.Width) + ' height=' + Format(Tenant.Height) + ' hascontent=' + Format(Tenant.Content.HasValue()));
    end;

    [TryFunction]
    local procedure TryExport(var Row: Record "PZ OnPrem Media Row"; Name: Text)
    begin
        Row.Pic.ExportFile(Name);
    end;

    [TryFunction]
    local procedure TryExportSet(var Row: Record "PZ OnPrem Media Row"; Prefix: Text)
    begin
        Row.Set.ExportFile(Prefix);
    end;

    [TryFunction]
    local procedure TryImport(var Row: Record "PZ OnPrem Media Row"; Name: Text; var Id: Guid)
    begin
        Id := Row.Pic.ImportFile(Name, 'desc');
    end;

    [Test]
    procedure Media_ImportFile_ExportFile()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Base64: Codeunit "Base64 Convert";
        Src: Text;
        Dst: Text;
        Id: Guid;
        Id2: Guid;
        InS: InStream;
        F: File;
        Head: Text;
    begin
        Row.SetFilter(Code, 'LTS*');
        Row.DeleteAll();
        Row.Reset();
        Src := TempName('.png');
        Dst := TempName('.png');
        WritePng(Src);
        Row.Code := 'LTSA';
        Id := Row.Pic.ImportFile(Src, 'the description', 'image/png');
        Row.Insert();
        Observer.Observe('import_id_null', Format(IsNullGuid(Id)));
        Observer.Observe('import_id_is_media_id', Format(Id = Row.Pic.MediaId()));
        Observer.Observe('hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('tenant_3args', DescribeTenant(Id, BaseOf(Src)));
        Row.Code := 'LTSB';
        Id2 := Row.Pic.ImportFile(Src, 'second');
        Row.Insert();
        Observer.Observe('tenant_2args', DescribeTenant(Id2, BaseOf(Src)));
        Row.Code := 'LTSC';
        Id2 := Row.Pic.ImportFile(Src, 'third', 'text/plain');
        Row.Insert();
        Observer.Observe('tenant_other_mime', DescribeTenant(Id2, BaseOf(Src)));
        Row.Get('LTSA');
        Observer.Observe('export_return', Format(Row.Pic.ExportFile(Dst)));
        Observer.Observe('source_len', Format(LenOf(Src)));
        Observer.Observe('export_exists', Format(File.Exists(Dst)));
        if File.Exists(Dst) then begin
            Observer.Observe('export_len', Format(LenOf(Dst)));
            F.Open(Dst);
            F.CreateInStream(InS);
            Head := Base64.ToBase64(InS);
            F.Close();
            Observer.Observe('export_base64', Head);
        end;
        Observer.Observe('export_overwrite_ok', Format(TryExport(Row, Dst)));
        Observer.Observe('export_overwrite_len', Format(LenOf(Dst)));
        Cleanup(Src);
        Cleanup(Dst);
        Observer.Expect('import_id_null', 'No');
        Observer.Expect('import_id_is_media_id', 'Yes');
        Observer.Expect('hasvalue', 'Yes');
        Observer.Expect('tenant_3args', 'description=[the description] mime=[image/png] filename_contains_source_name=Yes filename_longer_than_name=Yes width=1 height=1 hascontent=Yes');
        Observer.Expect('tenant_2args', 'description=[second] mime=[image/png] filename_contains_source_name=Yes filename_longer_than_name=Yes width=1 height=1 hascontent=Yes');
        Observer.Expect('tenant_other_mime', 'description=[third] mime=[text/plain] filename_contains_source_name=Yes filename_longer_than_name=Yes width=0 height=0 hascontent=Yes');
        Observer.Expect('export_return', 'Yes');
        Observer.Expect('source_len', '68');
        Observer.Expect('export_exists', 'Yes');
        // Windows re-encodes this 68-byte PNG to 99 bytes: Windows nightly triage 2026-10-16 (codeunit 68571, the same source PNG:
        // 'exported length = 99') and Windows BC 29.0 check 2026-10-20 (29.0 re-encodes a PNG to 99 bytes too, bc-linux #161). The Linux
        // values asserted before (93 on 27/28, 68 on 29) came from the Linux image before bc-linux #135 and #161. The exact Base64 of the
        // re-encoded file is not measured on Windows: not asserted (windows-queue row).
        Observer.Expect('export_len', '99');
        Observer.Ignore('export_base64');
        Observer.Expect('export_overwrite_ok', 'Yes');
        Observer.Expect('export_overwrite_len', '99');
        Observer.Verify();
    end;

    [Test]
    procedure Media_ExportFile_EmptyMedia_AndBadPaths()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Dst: Text;
        Missing: Text;
        Id: Guid;
        Ok: Boolean;
    begin
        Row.SetFilter(Code, 'LTS*');
        Row.DeleteAll();
        Row.Reset();
        Dst := TempName('.png');
        Row.Code := 'LTSE';
        Row.Insert();
        Ok := TryExport(Row, Dst);
        Observer.Observe('empty_export', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('empty_export_file', Format(File.Exists(Dst)));
        ClearLastError();
        Missing := TemporaryPath() + 'ltsmedia-missing-' + DelChr(Format(CreateGuid()), '=', '{}-') + '.png';
        Ok := TryImport(Row, Missing, Id);
        Observer.Observe('missing_import', Format(Ok) + ' [' + GetLastErrorCode() + ']');
        Observer.Observe('missing_import_text', Format(GetLastErrorText().StartsWith('File ')) + ' ' + Format(GetLastErrorText().EndsWith(' was not found.')) + ' ' + Format(StrPos(GetLastErrorText(), BaseOf(Missing)) > 0));
        ClearLastError();
        Ok := TryImport(Row, '', Id);
        Observer.Observe('empty_import', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryExport(Row, '');
        Observer.Observe('empty_name_export', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryExport(Row, '/no/such/dir/out.png');
        Observer.Observe('missing_dir_export', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryExportSet(Row, '/no/such/dir/prefix');
        Observer.Observe('missing_dir_export_set', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryExportSet(Row, '');
        Observer.Observe('empty_prefix_export_set', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Cleanup(Dst);
        Observer.Expect('empty_export', 'Yes |');
        Observer.Expect('empty_export_file', 'No');
        Observer.Expect('missing_import', 'Yes [FileNotFound]');
        Observer.Expect('missing_import_text', 'Yes Yes Yes');
        Observer.Expect('empty_import', 'No The specified path is invalid.|InvalidPath');
        Observer.Expect('empty_name_export', 'No File name was not specified.|MissingFileName');
        Observer.Expect('missing_dir_export', 'No Could not find a part of the path ''/no/such/dir/out.png''.|InvalidPath');
        Observer.Expect('missing_dir_export_set', 'Yes |');
        Observer.Expect('empty_prefix_export_set', 'No File name was not specified.|MissingFileName');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSet_ImportFile_ExportFile()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Src: Text;
        Prefix: Text;
        Dir: Text;
        Id: Guid;
        Id2: Guid;
        Count: Integer;
    begin
        Row.SetFilter(Code, 'LTS*');
        Row.DeleteAll();
        Row.Reset();
        Src := TempName('.png');
        WritePng(Src);
        Row.Code := 'LTSS';
        Id := Row.Set.ImportFile(Src, 'first set item', 'image/png');
        Observer.Observe('set_import_id_null', Format(IsNullGuid(Id)));
        Row.Insert();
        Observer.Observe('set_count_after_one', Format(Row.Set.Count()));
        Id2 := Row.Set.ImportFile(Src, 'second set item');
        Row.Modify();
        Observer.Observe('set_count_after_two', Format(Row.Set.Count()));
        Observer.Observe('set_import_ids_equal', Format(Id = Id2));
        Observer.Observe('set_id_is_media_id', Format(Id2 = Row.Set.MediaId()));
        Observer.Observe('item1', DescribeTenant(Row.Set.Item(1), BaseOf(Src)));
        Observer.Observe('item2', DescribeTenant(Row.Set.Item(2), BaseOf(Src)));
        Row.Get('LTSS');
        Dir := TemporaryPath() + 'ltsmediaset' + DelChr(Format(CreateGuid()), '=', '{}-');
        Prefix := Dir + '-';
        Count := Row.Set.ExportFile(Prefix);
        Observer.Observe('export_count', Format(Count));
        Observer.Observe('prefix_itself_exists', Format(File.Exists(Prefix)));
        Cleanup(Src);
        Observer.Expect('set_import_id_null', 'No');
        Observer.Expect('set_count_after_one', '1');
        Observer.Expect('set_count_after_two', '2');
        Observer.Expect('set_import_ids_equal', 'Yes');
        Observer.Expect('set_id_is_media_id', 'Yes');
        // MediaSet.ImportFile stores the bare file name as the Tenant Media File Name (filename_longer_than_name=No): Windows BC 27.5, 28.5 and
        // 29.0 (windows-check QX item 9, 2026-10-22, and 2026-10-23) and bc-linux dc007079 (bc-linux #176). The older Linux image stored 'TEMP\<name>'.
        Observer.Expect('item1', 'description=[first set item] mime=[image/png] filename_contains_source_name=Yes filename_longer_than_name=No width=1 height=1 hascontent=Yes');
        Observer.Expect('item2', 'description=[second set item] mime=[image/png] filename_contains_source_name=Yes filename_longer_than_name=No width=1 height=1 hascontent=Yes');
        Observer.Expect('export_count', '2');
        Observer.Expect('prefix_itself_exists', 'No');
        Observer.Verify();
    end;

    // ---- Writer QX (Microsoft's DemoTool: Picture.ImportFile(Path + 'cronus.jpg', Desc) on Media and MediaSet fields): a 3 x 2 JPEG file,
    // the Tenant Media row (Mime Type, Description, File Name, Width, Height), HasValue, MediaSet.Count; file name extension .jpg and .JPG. ----

    local procedure QxJpegBase64(): Text
    begin
        exit('/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDABALDA4MChAODQ4SERATGCgaGBYWGDEjJR0oOjM9PDkzODdASFxOQERXRTc4UG1RV19iZ2hnPk1xeXBkeFxlZ2P/2wBDARESEhgVGC8aGi9jQjhCY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2Nj' +
            'Y2NjY2NjY2P/wAARCAACAAMDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVW' +
            'V1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAEC' +
            'AxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq' +
            '8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDAooorgPrT/9k=');
    end;

    local procedure QxWriteJpeg(Name: Text)
    var
        F: File;
        OutS: OutStream;
        Base64: Codeunit "Base64 Convert";
    begin
        F.Create(Name);
        F.CreateOutStream(OutS);
        Base64.FromBase64(QxJpegBase64(), OutS);
        F.Close();
    end;

    local procedure QxFileName(Id: Guid; Src: Text): Text
    var
        Tenant: Record "Tenant Media";
        Name: Text;
    begin
        if not Tenant.Get(Id) then
            exit('no tenant media row');
        Name := Tenant."File Name";
        Name := Name.Replace(TemporaryPath(), '<tmp>');
        Name := Name.Replace(BaseOf(Src), '<name>');
        exit(Name);
    end;

    [Test]
    procedure QX_MediaAndMediaSet_ImportFile_Jpeg()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Src: Text;
        SrcUpper: Text;
        Id: Guid;
    begin
        Row.SetFilter(Code, 'LTQX*');
        Row.DeleteAll();
        Row.Reset();
        Src := TempName('.jpg');
        SrcUpper := TempName('.JPG');
        QxWriteJpeg(Src);
        QxWriteJpeg(SrcUpper);
        Observer.Observe('file length', Format(LenOf(Src)));
        Row.Code := 'LTQXA';
        Id := Row.Pic.ImportFile(Src, 'Cronus picture');
        Row.Insert();
        Observer.Observe('media hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('media tenant', DescribeTenant(Id, BaseOf(Src)));
        Observer.Observe('media file name', QxFileName(Id, Src));
        Row.Code := 'LTQXB';
        Id := Row.Pic.ImportFile(SrcUpper, 'Upper case extension');
        Row.Insert();
        Observer.Observe('media upper tenant', DescribeTenant(Id, BaseOf(SrcUpper)));
        Row.Code := 'LTQXC';
        Clear(Row.Pic);
        Id := Row.Set.ImportFile(Src, 'Item picture');
        Row.Insert();
        Observer.Observe('mediaset count', Format(Row.Set.Count()));
        Observer.Observe('mediaset item 1 tenant', DescribeTenant(Row.Set.Item(1), BaseOf(Src)));
        Observer.Observe('mediaset file name', QxFileName(Row.Set.Item(1), Src));
        Row.Get('LTQXC');
        Observer.Observe('mediaset count after get', Format(Row.Set.Count()));
        Row.SetFilter(Code, 'LTQX*');
        Row.DeleteAll();
        Cleanup(Src);
        Cleanup(SrcUpper);
        Observer.Expect('file length', '632');
        Observer.Expect('media hasvalue', 'Yes');
        Observer.Expect('media tenant', 'description=[Cronus picture] mime=[image/jpeg] filename_contains_source_name=Yes filename_longer_than_name=Yes width=3 height=2 hascontent=Yes');
        Observer.Expect('media file name', '<tmp><name>');
        Observer.Expect('media upper tenant', 'description=[Upper case extension] mime=[image/jpeg] filename_contains_source_name=Yes filename_longer_than_name=Yes width=3 height=2 hascontent=Yes');
        Observer.Expect('mediaset count', '1');
        // The bare file name (filename_longer_than_name=No): Windows BC 27.5, 28.5 and 29.0 (windows-check QX item 9) and bc-linux dc007079 (#176).
        Observer.Expect('mediaset item 1 tenant', 'description=[Item picture] mime=[image/jpeg] filename_contains_source_name=Yes filename_longer_than_name=No width=3 height=2 hascontent=Yes');
        // Windows BC 27.5, 28.5 and 29.0 (windows-check QX item 9, 2026-10-22) and bc-linux dc007079 (bc-linux #176): the bare file name.
        Observer.Expect('mediaset file name', '<name>');
        Observer.Expect('mediaset count after get', '1');
        Observer.Verify();
    end;

    // ---- Writer RD (Microsoft's DemoTool, round 2: Item.Picture.ImportFile(Path, "No.") into a MediaSet with the result unused,
    // Sales Document Icon SetIconFromFile of 'SalesStatusIcons\Quote.PNG' into a MediaSet, Word Template.Template.ImportFile(Path, 'Template')
    // of a .docx into a Media): a JPEG and then a 2 x 3 PNG with an upper-case .PNG extension into the same MediaSet (the returned Guid against
    // MediaId and Item(1), the order of the items, Mime Type, Width, Height); a .docx file into a Media (Tenant Media row, File Name form,
    // the exported bytes). The Tenant Media File Name of a MediaSet item is asserted in QX_MediaAndMediaSet_ImportFile_Jpeg. ----

    local procedure RdPngBase64(): Text
    begin
        exit('iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAIAAAA2iEnWAAAAEElEQVR42mP4zwAE/xlQKAA+1gX7ttb52gAAAABJRU5ErkJggg==');
    end;

    local procedure RdDocxBase64(): Text
    begin
        exit('UEsDBBQAAAAIAAAAIVx5bjPX6AAAAK0BAAATAAAAW0NvbnRlbnRfVHlwZXNdLnhtbH1QyU7DMBD9FWuuKHHggBCK0wPLETiUDxjZk8SqN3nc0v49Tlt6QIXjzFv1+tXeO7GjzDYGBbdt' +
            'B4KCjsaGScHn+rV5AMEFg0EXAyk4EMNq6NeHRCyqNrCCuZT0KCXrmTxyGxOFiowxeyz1zJNMqDc4kbzrunupYygUSlMWDxj6Zxpx64p42df3qUcmxyCeTsQlSwGm5KzGUnG5C+ZXSnNO' +
            'aKvyyOHZJr6pBJBXExbk74Cz7r0Ok60h8YG5vKGvLPkVs5Em6q2vyvZ/mys94zhaTRf94pZy1MRcF/euvSAebfjpL49zD99QSwMEFAAAAAgAAAAhXJv9N+qtAAAAKQEAAAsAAABfcmVs' +
            'cy8ucmVsc43POw7CMAwG4KtE3mlaBoRQ0y4IqSsqB7ASN61oHkrCo7cnAwNFDIy2f3+W6/ZpZnanECdnBVRFCYysdGqyWsClP232wGJCq3B2lgQsFKFt6jPNmPJKHCcfWTZsFDCm5A+c' +
            'RzmSwVg4TzZPBhcMplwGzT3KK2ri27Lc8fBpwNpknRIQOlUB6xdP/9huGCZJRydvhmz6ceIrkWUMmpKAhwuKq3e7yCzwpuarF5sXUEsDBBQAAAAIAAAAIVzXDGLpogAAANcAAAARAAAA' +
            'd29yZC9kb2N1bWVudC54bWxFjkEOwiAQRa9C2FuqC2Oa0m6MK1emHgBhbJvADAG09vZCXbh5PzOT/zJt/3GWvSHEmVDyfVVzBqjJzDhKfh8uuxNnMSk0yhKC5CtE3nft0hjSLweYWBZg' +
            'bBbJp5R8I0TUEzgVK/KA+fak4FTKYxjFQsH4QBpizH5nxaGuj8KpGXlRPsisJX1BKEjddWC3M0vgvFUJWlF2hWGj3/jrif9P3RdQSwECFAMUAAAACAAAACFceW4z1+gAAACtAQAAEwAA' +
            'AAAAAAAAAAAAgAEAAAAAW0NvbnRlbnRfVHlwZXNdLnhtbFBLAQIUAxQAAAAIAAAAIVyb/TfqrQAAACkBAAALAAAAAAAAAAAAAACAARkBAABfcmVscy8ucmVsc1BLAQIUAxQAAAAIAAAA' +
            'IVzXDGLpogAAANcAAAARAAAAAAAAAAAAAACAAe8BAAB3b3JkL2RvY3VtZW50LnhtbFBLBQYAAAAAAwADALkAAADAAgAAAAA=');
    end;

    local procedure RdWriteBase64(Name: Text; Base64Text: Text)
    var
        F: File;
        OutS: OutStream;
        Base64: Codeunit "Base64 Convert";
    begin
        F.Create(Name);
        F.CreateOutStream(OutS);
        Base64.FromBase64(Base64Text, OutS);
        F.Close();
    end;

    local procedure RdTenant(Id: Guid; BaseName: Text): Text
    var
        Tenant: Record "Tenant Media";
    begin
        if not Tenant.Get(Id) then
            exit('no tenant media row');
        Tenant.CalcFields(Content);
        exit('description=[' + Tenant.Description + '] mime=[' + Tenant."Mime Type" + '] filename_contains_source_name=' + Format(StrPos(Tenant."File Name", BaseName) > 0) + ' width=' + Format(Tenant.Width) + ' height=' + Format(Tenant.Height) + ' hascontent=' + Format(Tenant.Content.HasValue()));
    end;

    [Test]
    procedure RD_MediaSet_ImportFile_JpegThenUpperCasePng()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Jpg: Text;
        Png: Text;
        Id1: Guid;
        Id2: Guid;
        IdPic: Guid;
    begin
        Row.SetFilter(Code, 'LTRD*');
        Row.DeleteAll();
        Row.Reset();
        Jpg := TempName('.jpg');
        Png := TempName('.PNG');
        QxWriteJpeg(Jpg);
        RdWriteBase64(Png, RdPngBase64());
        Observer.Observe('png file length', Format(LenOf(Png)));
        Row.Code := 'LTRDA';
        Id1 := Row.Set.ImportFile(Jpg, 'jpeg item');
        Row.Insert();
        Id2 := Row.Set.ImportFile(Png, 'png item');
        Row.Modify();
        Observer.Observe('count', Format(Row.Set.Count()));
        Observer.Observe('returned ids equal', Format(Id1 = Id2));
        Observer.Observe('returned id is MediaId', Format(Id1 = Row.Set.MediaId()));
        Observer.Observe('returned id is Item(1)', Format(Id1 = Row.Set.Item(1)));
        Observer.Observe('returned id is Item(2)', Format(Id1 = Row.Set.Item(2)));
        Observer.Observe('Item(1) is Item(2)', Format(Row.Set.Item(1) = Row.Set.Item(2)));
        Observer.Observe('format returned id length', Format(StrLen(Format(Id1))));
        Observer.Observe('format Item(1) length', Format(StrLen(Format(Row.Set.Item(1)))));
        Observer.Observe('item 1', RdTenant(Row.Set.Item(1), BaseOf(Jpg)));
        Observer.Observe('item 2', RdTenant(Row.Set.Item(2), BaseOf(Png)));
        Row.Get('LTRDA');
        Observer.Observe('count after get', Format(Row.Set.Count()));
        Observer.Observe('item 1 after get', RdTenant(Row.Set.Item(1), BaseOf(Jpg)));
        Observer.Observe('item 2 after get', RdTenant(Row.Set.Item(2), BaseOf(Png)));
        Row.Code := 'LTRDB';
        IdPic := Row.Pic.ImportFile(Png, 'png media');
        Row.Insert();
        Observer.Observe('media png returned id is MediaId', Format(IdPic = Row.Pic.MediaId()));
        Observer.Observe('media png', RdTenant(IdPic, BaseOf(Png)));
        Row.Reset();
        Row.SetFilter(Code, 'LTRD*');
        Row.DeleteAll();
        Cleanup(Jpg);
        Cleanup(Png);
        Observer.Expect('png file length', '73');
        Observer.Expect('count', '2');
        Observer.Expect('returned ids equal', 'Yes');
        Observer.Expect('returned id is MediaId', 'Yes');
        Observer.Expect('returned id is Item(1)', 'No');
        Observer.Expect('returned id is Item(2)', 'No');
        Observer.Expect('Item(1) is Item(2)', 'No');
        Observer.Expect('format returned id length', '38');
        Observer.Expect('format Item(1) length', '38');
        Observer.Expect('item 1', 'description=[jpeg item] mime=[image/jpeg] filename_contains_source_name=Yes width=3 height=2 hascontent=Yes');
        Observer.Expect('item 2', 'description=[png item] mime=[image/png] filename_contains_source_name=Yes width=2 height=3 hascontent=Yes');
        Observer.Expect('count after get', '2');
        Observer.Expect('item 1 after get', 'description=[jpeg item] mime=[image/jpeg] filename_contains_source_name=Yes width=3 height=2 hascontent=Yes');
        Observer.Expect('item 2 after get', 'description=[png item] mime=[image/png] filename_contains_source_name=Yes width=2 height=3 hascontent=Yes');
        Observer.Expect('media png returned id is MediaId', 'Yes');
        Observer.Expect('media png', 'description=[png media] mime=[image/png] filename_contains_source_name=Yes width=2 height=3 hascontent=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RD_Media_ImportFile_Docx()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Tenant: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
        InS: InStream;
        Src: Text;
        Id: Guid;
    begin
        Row.SetFilter(Code, 'LTRD*');
        Row.DeleteAll();
        Row.Reset();
        Src := TempName('.docx');
        RdWriteBase64(Src, RdDocxBase64());
        Observer.Observe('file length', Format(LenOf(Src)));
        Row.Code := 'LTRDD';
        Id := Row.Pic.ImportFile(Src, 'Template');
        Row.Insert();
        Observer.Observe('returned id is MediaId', Format(Id = Row.Pic.MediaId()));
        Observer.Observe('hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('tenant', RdTenant(Id, BaseOf(Src)));
        Observer.Observe('file name', QxFileName(Id, Src));
        if Tenant.Get(Id) then begin
            Tenant.CalcFields(Content);
            Tenant.Content.CreateInStream(InS);
            Observer.Observe('tenant content is the file', Format(Base64.ToBase64(InS) = RdDocxBase64()));
        end;
        Row.Get('LTRDD');
        TempBlob.CreateOutStream(OutS);
        Row.Pic.ExportStream(OutS);
        Observer.Observe('export length', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS);
        Observer.Observe('export is the file', Format(Base64.ToBase64(InS) = RdDocxBase64()));
        Row.Reset();
        Row.SetFilter(Code, 'LTRD*');
        Row.DeleteAll();
        Cleanup(Src);
        Observer.Expect('file length', '911');
        Observer.Expect('returned id is MediaId', 'Yes');
        Observer.Expect('hasvalue', 'Yes');
        Observer.Expect('tenant', 'description=[Template] mime=[application/vnd.openxmlformats-officedocument.wordprocessingml.document] filename_contains_source_name=Yes width=0 height=0 hascontent=Yes');
        Observer.Expect('file name', '<tmp><name>');
#if BC29PLUS
        // BC 29 on the Linux CI tier stores a re-zipped package (same parts, other compressed bytes: 919 bytes); queued for the Windows check.
        Observer.Ignore('tenant content is the file');
        Observer.Ignore('export length');
        Observer.Ignore('export is the file');
#else
        Observer.Expect('tenant content is the file', 'Yes');
        Observer.Expect('export length', '911');
        Observer.Expect('export is the file', 'Yes');
#endif
        Observer.Verify();
    end;

    // ---- Writer RJ (Microsoft's DemoTool, Export RapidStart Packages: Config. XML Exchange.ExportMediaSet copies the field through a FieldRef
    // into a temporary Config. Media Buffer and calls "Media Set".ExportFile(MediaFolder + '\' + Format("Media Set")), MediaFolder being
    // CombinePath(<package folder>, 'Media'); UpdateConfigPackageMediaSet lists that folder with GetServerDirectoryFilesList and reads each file
    // back with BLOBImportFromServerFile, Media Set ID = GetFileNameWithoutExtension(file name)). Names are masked: <dir> is the package
    // folder, <set1>/<set2> the Format of the sets, <s2i1> etc. the Format of an item's media id (also without braces and in lower case). ----

    local procedure RjMask(Value: Text; Id: Guid; Tag: Text): Text
    var
        G: Text;
    begin
        G := Format(Id);
        Value := Value.Replace(G, '<' + Tag + '>');
        Value := Value.Replace(LowerCase(G), '<' + Tag + '>');
        G := DelChr(G, '=', '{}');
        Value := Value.Replace(G, '<' + Tag + '-nobraces>');
        Value := Value.Replace(LowerCase(G), '<' + Tag + '-nobraces-lower>');
        exit(Value);
    end;

    local procedure RjMaskAll(Value: Text; Dir: Text; var Row1: Record "PZ OnPrem Media Row"; var Row2: Record "PZ OnPrem Media Row"): Text
    begin
        Value := Value.Replace(Dir, '<dir>');
        Value := Value.Replace('<dir>/Media', '<media>').Replace('<dir>\Media', '<media>');
        Value := RjMask(Value, Row1.Set.MediaId(), 'set1');
        Value := RjMask(Value, Row2.Set.MediaId(), 'set2');
        Value := RjMask(Value, Row1.Set.Item(1), 's1i1');
        Value := RjMask(Value, Row2.Set.Item(1), 's2i1');
        Value := RjMask(Value, Row2.Set.Item(2), 's2i2');
        exit(Value);
    end;

    local procedure RjTenantBase64(Id: Guid): Text
    var
        Tenant: Record "Tenant Media";
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
    begin
        if not Tenant.Get(Id) then
            exit('');
        Tenant.CalcFields(Content);
        Tenant.Content.CreateInStream(InS);
        exit(Base64.ToBase64(InS));
    end;

    local procedure RjExportSet(var Row: Record "PZ OnPrem Media Row"; MediaFolder: Text): Integer
    var
        TempConfigMediaBuffer: Record "Config. Media Buffer" temporary;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(Row);
        FieldRef := RecRef.Field(Row.FieldNo(Set));
        TempConfigMediaBuffer.Init();
        TempConfigMediaBuffer."Media Set" := FieldRef.Value();
        TempConfigMediaBuffer.Insert();
        exit(TempConfigMediaBuffer."Media Set".ExportFile(MediaFolder + '\' + Format(TempConfigMediaBuffer."Media Set")));
    end;

    local procedure RjListFolder(Folder: Text; Recursive: Boolean; Dir: Text; var Row1: Record "PZ OnPrem Media Row"; var Row2: Record "PZ OnPrem Media Row"; JpgB64: Text; PngB64: Text): Text
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        DummyGuid: Guid;
        InS: InStream;
        B64: Text;
        Same: Text;
        Result: Text;
    begin
        if Recursive then
            FileManagement.GetServerDirectoryFilesListInclSubDirs(TempNameValueBuffer, Folder)
        else
            FileManagement.GetServerDirectoryFilesList(TempNameValueBuffer, Folder);
        if Folder = TemporaryPath() then begin
            // only the entries this test wrote (names that hold a set or item id or the package folder)
            if TempNameValueBuffer.FindSet() then
                repeat
                    if (StrPos(RjMaskAll(TempNameValueBuffer.Name, Dir, Row1, Row2), '<s') = 0) and (StrPos(TempNameValueBuffer.Name, 'ltrjpkg') = 0) then
                        TempNameValueBuffer.Delete();
                until TempNameValueBuffer.Next() = 0;
        end;
        Result := Format(TempNameValueBuffer.Count()) + ':';
        if TempNameValueBuffer.FindSet() then
            repeat
                Clear(TempBlob);
                FileManagement.BLOBImportFromServerFile(TempBlob, TempNameValueBuffer.Name);
                TempBlob.CreateInStream(InS);
                B64 := Base64.ToBase64(InS);
                Same := '';
                if B64 = JpgB64 then
                    Same += ' jpg';
                if B64 = PngB64 then
                    Same += ' png';
                if B64 = RjTenantBase64(Row1.Set.Item(1)) then
                    Same += ' s1i1';
                if B64 = RjTenantBase64(Row2.Set.Item(1)) then
                    Same += ' s2i1';
                if B64 = RjTenantBase64(Row2.Set.Item(2)) then
                    Same += ' s2i2';
                Result += '[' + Format(TempNameValueBuffer.ID) + '|' + RjMaskAll(TempNameValueBuffer.Name, Dir, Row1, Row2) + '|v=' +
                  RjMaskAll(TempNameValueBuffer.Value, Dir, Row1, Row2) + '|id=' +
                  RjMaskAll(CopyStr(FileManagement.GetFileNameWithoutExtension(TempNameValueBuffer.Name), 1, StrLen(Format(DummyGuid))), Dir, Row1, Row2) +
                  '|len=' + Format(TempBlob.Length()) + '|bytes of:' + Same + ']';
            until TempNameValueBuffer.Next() = 0;
        exit(Result);
    end;

    // Which of the likely names (prefix + separator + index + extension) AL File.Exists finds after an export, with the file length.
    local procedure RjCandidates(Prefix: Text; Dir: Text; var Row1: Record "PZ OnPrem Media Row"; var Row2: Record "PZ OnPrem Media Row"): Text
    var
        F: File;
        Seps: List of [Text];
        Exts: List of [Text];
        Sep: Text;
        Ext: Text;
        Name: Text;
        Result: Text;
        i: Integer;
    begin
        Seps.Add('');
        Seps.Add('-');
        Seps.Add('_');
        Seps.Add(' ');
        Seps.Add('.');
        Seps.Add('/');
        Exts.Add('');
        Exts.Add('.jpg');
        Exts.Add('.jpeg');
        Exts.Add('.png');
        Exts.Add('.JPG');
        Exts.Add('.PNG');
        Exts.Add('.bin');
        for i := 0 to 3 do
            foreach Sep in Seps do
                foreach Ext in Exts do begin
                    Name := Prefix + Sep + Format(i) + Ext;
                    if File.Exists(Name) then begin
                        F.Open(Name);
                        Result += '[' + RjMaskAll(Name, Dir, Row1, Row2) + '|len=' + Format(F.Len()) + ']';
                        F.Close();
                    end;
                end;
        foreach Ext in Exts do
            if File.Exists(Prefix + Ext) then
                Result += '[' + RjMaskAll(Prefix + Ext, Dir, Row1, Row2) + ']';
        for i := 1 to Row2.Set.Count() do
            foreach Sep in Seps do
                foreach Ext in Exts do begin
                    Name := Prefix + Sep + Format(Row2.Set.Item(i)) + Ext;
                    if File.Exists(Name) then
                        Result += '[' + RjMaskAll(Name, Dir, Row1, Row2) + ']';
                    Name := Prefix + Sep + DelChr(Format(Row2.Set.Item(i)), '=', '{}') + Ext;
                    if File.Exists(Name) then
                        Result += '[' + RjMaskAll(Name, Dir, Row1, Row2) + ']';
                end;
        exit(Result);
    end;

    // The length of a file AL File opens, and which source its bytes equal: the written files, or the Tenant Media content of an item.
    local procedure RjBytesOf(Name: Text; var Row2: Record "PZ OnPrem Media Row"; JpgB64: Text; PngB64: Text): Text
    var
        F: File;
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
        B64: Text;
        Result: Text;
    begin
        if not File.Exists(Name) then
            exit('missing');
        F.Open(Name);
        Result := 'len=' + Format(F.Len()) + ' bytes of:';
        F.CreateInStream(InS);
        B64 := Base64.ToBase64(InS);
        F.Close();
        if B64 = JpgB64 then
            Result += ' jpg';
        if B64 = PngB64 then
            Result += ' png';
        if B64 = RjTenantBase64(Row2.Set.Item(1)) then
            Result += ' s2i1';
        if B64 = RjTenantBase64(Row2.Set.Item(2)) then
            Result += ' s2i2';
        exit(Result);
    end;

    // Which item of the set (i1 = Item(1), i2 = Item(2)) a Base64 text is the Tenant Media content of.
    local procedure RjWhich(B64: Text; var Row: Record "PZ OnPrem Media Row"): Text
    begin
        if B64 = RjTenantBase64(Row.Set.Item(1)) then
            exit('i1');
        if B64 = RjTenantBase64(Row.Set.Item(2)) then
            exit('i2');
        exit('?');
    end;

    local procedure RjFileB64(Name: Text): Text
    var
        F: File;
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
        B64: Text;
    begin
        if not File.Exists(Name) then
            exit('');
        F.Open(Name);
        F.CreateInStream(InS);
        B64 := Base64.ToBase64(InS);
        F.Close();
        exit(B64);
    end;

    local procedure RjItemOf(MediaId: Guid; var Row: Record "PZ OnPrem Media Row"): Text
    begin
        if MediaId = Row.Set.Item(1) then
            exit('i1');
        if MediaId = Row.Set.Item(2) then
            exit('i2');
        exit('?');
    end;

    // For a set of two items: the items behind <prefix>-1 and -2, the items in the order of the Tenant Media Set primary key (ID, Media ID)
    // and in the order of its Media Index.
    local procedure RjOrders(var Row: Record "PZ OnPrem Media Row"; Prefix: Text; var FileOrder: Text; var KeyOrder: Text; var IndexOrder: Text)
    var
        TenantMediaSet: Record "Tenant Media Set";
    begin
        FileOrder := RjWhich(RjFileB64(Prefix + '-1'), Row) + RjWhich(RjFileB64(Prefix + '-2'), Row);
        KeyOrder := '';
        IndexOrder := '';
        TenantMediaSet.SetRange(ID, Row.Set.MediaId());
        if TenantMediaSet.FindSet() then
            repeat
                KeyOrder += RjItemOf(TenantMediaSet."Media ID".MediaId(), Row);
            until TenantMediaSet.Next() = 0;
        TenantMediaSet.SetCurrentKey("Media Index");
        if TenantMediaSet.FindSet() then
            repeat
                IndexOrder += RjItemOf(TenantMediaSet."Media ID".MediaId(), Row);
            until TenantMediaSet.Next() = 0;
    end;

    [TryFunction]
    local procedure RjTryList(var Result: Text; Folder: Text; Dir: Text; var Row1: Record "PZ OnPrem Media Row"; var Row2: Record "PZ OnPrem Media Row")
    begin
        Result := RjListFolder(Folder, true, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64());
    end;

    // The listing in a form that holds on every tier (no lengths, no item order): the count, the masked Name and Value of each file sorted by
    // the masked name, whether each file equals the Tenant Media content of an item of its set (content=Yes), and whether the listing came in
    // name order (case ignored).
    local procedure RjListShape(Folder: Text; Recursive: Boolean; Dir: Text; var Row1: Record "PZ OnPrem Media Row"; var Row2: Record "PZ OnPrem Media Row"): Text
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        Entries: List of [Text];
        InS: InStream;
        B64: Text;
        Entry: Text;
        Swap: Text;
        Previous: Text;
        Content: Boolean;
        InNameOrder: Boolean;
        Result: Text;
        i: Integer;
        j: Integer;
    begin
        if Recursive then
            FileManagement.GetServerDirectoryFilesListInclSubDirs(TempNameValueBuffer, Folder)
        else
            FileManagement.GetServerDirectoryFilesList(TempNameValueBuffer, Folder);
        InNameOrder := true;
        if TempNameValueBuffer.FindSet() then
            repeat
                if (Folder <> TemporaryPath()) or (StrPos(RjMaskAll(TempNameValueBuffer.Name, Dir, Row1, Row2), '<s') > 0) or (StrPos(TempNameValueBuffer.Name, 'ltrjpkg') > 0) then begin
                    Clear(TempBlob);
                    FileManagement.BLOBImportFromServerFile(TempBlob, TempNameValueBuffer.Name);
                    TempBlob.CreateInStream(InS);
                    B64 := Base64.ToBase64(InS);
                    Content := false;
                    if StrPos(TempNameValueBuffer.Name, Format(Row1.Set)) > 0 then
                        Content := B64 = RjTenantBase64(Row1.Set.Item(1));
                    if StrPos(TempNameValueBuffer.Name, Format(Row2.Set)) > 0 then
                        Content := (B64 = RjTenantBase64(Row2.Set.Item(1))) or (B64 = RjTenantBase64(Row2.Set.Item(2)));
                    if (Previous <> '') and (UpperCase(TempNameValueBuffer.Name) < Previous) then
                        InNameOrder := false;
                    Previous := UpperCase(TempNameValueBuffer.Name);
                    Entries.Add('[' + RjMaskAll(TempNameValueBuffer.Name, Dir, Row1, Row2) + '|v=' + RjMaskAll(TempNameValueBuffer.Value, Dir, Row1, Row2) +
                      '|content=' + Format(Content) + ']');
                end;
            until TempNameValueBuffer.Next() = 0;
        for i := 1 to Entries.Count() do
            for j := i + 1 to Entries.Count() do
                if Entries.Get(j) < Entries.Get(i) then begin
                    Swap := Entries.Get(i);
                    Entries.Set(i, Entries.Get(j));
                    Entries.Set(j, Swap);
                end;
        Result := Format(Entries.Count()) + ':';
        foreach Entry in Entries do
            Result += Entry;
        exit(Result + '|name order=' + Format(InNameOrder));
    end;

    [TryFunction]
    local procedure RjTryListShape(var Result: Text; Folder: Text; Dir: Text; var Row1: Record "PZ OnPrem Media Row"; var Row2: Record "PZ OnPrem Media Row")
    begin
        Result := RjListShape(Folder, true, Dir, Row1, Row2);
    end;

    [Test]
    procedure RJ_MediaSet_ExportFile_ConfigPackageShape()
    var
        Row1: Record "PZ OnPrem Media Row";
        Row2: Record "PZ OnPrem Media Row";
        FileManagement: Codeunit "File Management";
        Jpg: Text;
        Png: Text;
        Dir: Text;
        MediaFolder: Text;
        Count1: Integer;
        Count2: Integer;
        TempList: Text;
        FileOrder: Text;
        KeyOrder: Text;
        IndexOrder: Text;
        AllFiles: Text;
        AllKey: Text;
        AllIndex: Text;
        k: Integer;
    begin
        Row1.SetFilter(Code, 'LTRJ*');
        Row1.DeleteAll();
        Row1.Reset();
        Jpg := TempName('.jpg');
        Png := TempName('.png');
        QxWriteJpeg(Jpg);
        RdWriteBase64(Png, RdPngBase64());
        // A short folder name: on the Linux tier TemporaryPath() is about 45 characters longer than on Windows, and a listed full path over 250
        // characters does not fit the Name of the Name/Value Buffer (error in GetServerDirectoryFilesList).
        Dir := TemporaryPath() + 'ltrjpkg' + CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 8);
        FileManagement.ServerCreateDirectory(Dir);
        MediaFolder := FileManagement.CombinePath(Dir, 'Media');
        FileManagement.ServerCreateDirectory(MediaFolder);
        RjObserver.Observe('media folder', MediaFolder.Replace(Dir, '<dir>'));
        Row1.Code := 'LTRJ1';
        Row1.Set.ImportFile(Png, 'png item');
        Row1.Insert();
        Row2.Code := 'LTRJ2';
        Row2.Set.ImportFile(Jpg, 'jpeg item');
        Row2.Insert();
        Row2.Set.ImportFile(Png, 'png item');
        Row2.Modify();
        Row1.Get('LTRJ1');
        Row2.Get('LTRJ2');
        RjObserver.Observe('set counts', Format(Row1.Set.Count()) + '|' + Format(Row2.Set.Count()));
        RjObserver.Observe('format set length', Format(StrLen(Format(Row1.Set))));
        RjObserver.Observe('format set is MediaId', Format(Format(Row1.Set) = Format(Row1.Set.MediaId())));
        RjObserver.Observe('tenant item bytes same as files', Format(RjTenantBase64(Row1.Set.Item(1)) = RdPngBase64()) + '|' +
          Format(RjTenantBase64(Row2.Set.Item(1)) = QxJpegBase64()) + '|' + Format(RjTenantBase64(Row2.Set.Item(2)) = RdPngBase64()));
        Count1 := RjExportSet(Row1, MediaFolder);
        RjObserver.Observe('export count one item', Format(Count1));
        RjObserver.Observe('media folder after one', RjListFolder(MediaFolder, false, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('package folder after one, with sub folders', RjListFolder(Dir, true, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('media folder after one, shape', RjListShape(MediaFolder, false, Dir, Row1, Row2));
        RjObserver.Observe('package folder after one, with sub folders, shape', RjListShape(Dir, true, Dir, Row1, Row2));
        Count2 := RjExportSet(Row2, MediaFolder);
        RjObserver.Observe('export count two items', Format(Count2));
        RjObserver.Observe('media folder after two', RjListFolder(MediaFolder, false, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('al file names after two', RjCandidates(MediaFolder + '\' + Format(Row2.Set), Dir, Row1, Row2));
        RjObserver.Observe('bytes of -1', RjBytesOf(MediaFolder + '\' + Format(Row2.Set) + '-1', Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('bytes of -2', RjBytesOf(MediaFolder + '\' + Format(Row2.Set) + '-2', Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('package folder after two, with sub folders', RjListFolder(Dir, true, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('media folder after two, shape', RjListShape(MediaFolder, false, Dir, Row1, Row2));
        RjObserver.Observe('package folder after two, with sub folders, shape', RjListShape(Dir, true, Dir, Row1, Row2));
        Count1 := RjExportSet(Row1, MediaFolder);
        RjObserver.Observe('export count one item again', Format(Count1));
        RjObserver.Observe('al file names after again', RjCandidates(MediaFolder + '\' + Format(Row1.Set), Dir, Row1, Row2));
        RjObserver.Observe('bytes of again -1', RjBytesOf(MediaFolder + '\' + Format(Row1.Set) + '-1', Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('again -1 and -2 exist', Format(File.Exists(MediaFolder + '\' + Format(Row1.Set) + '-1')) + '|' + Format(File.Exists(MediaFolder + '\' + Format(Row1.Set) + '-2')));
        RjObserver.Observe('again -1 is the tenant content of its item', Format(RjFileB64(MediaFolder + '\' + Format(Row1.Set) + '-1') = RjTenantBase64(Row1.Set.Item(1))));
        RjObserver.Observe('media folder after again', RjListFolder(MediaFolder, false, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('media folder after again, shape', RjListShape(MediaFolder, false, Dir, Row1, Row2));
        if RjTryList(TempList, TemporaryPath(), Dir, Row1, Row2) then
            RjObserver.Observe('temporary path, with sub folders', TempList)
        else
            RjObserver.Observe('temporary path, with sub folders', 'error ' + GetLastErrorText());
        if RjTryListShape(TempList, TemporaryPath(), Dir, Row1, Row2) then
            RjObserver.Observe('temporary path, with sub folders, shape', TempList)
        else
            RjObserver.Observe('temporary path, with sub folders, shape', 'error ' + GetLastErrorText());
        // the same with a prefix that has no backslash: CombinePath(MediaFolder, Format(Set))
        Count2 := Row2.Set.ExportFile(FileManagement.CombinePath(MediaFolder, Format(Row2.Set)));
        RjObserver.Observe('slash prefix export count', Format(Count2));
        RjObserver.Observe('slash prefix al file names', RjCandidates(FileManagement.CombinePath(MediaFolder, Format(Row2.Set)), Dir, Row1, Row2));
        RjObserver.Observe('slash prefix media folder', RjListFolder(MediaFolder, false, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('slash prefix package folder, with sub folders', RjListFolder(Dir, true, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('slash prefix media folder, shape', RjListShape(MediaFolder, false, Dir, Row1, Row2));
        RjObserver.Observe('slash prefix package folder, with sub folders, shape', RjListShape(Dir, true, Dir, Row1, Row2));
        // Eight more sets of a JPEG then a PNG item: which item each numbered file holds, against the Tenant Media Set orders.
        for k := 1 to 8 do begin
            Clear(Row1);
            Row1.Code := 'LTRJS' + Format(k);
            Row1.Set.ImportFile(Jpg, 'jpeg item');
            Row1.Insert();
            Row1.Set.ImportFile(Png, 'png item');
            Row1.Modify();
            Row1.Get('LTRJS' + Format(k));
            RjObserver.Observe('set ' + Format(k) + ' export count', Format(Row1.Set.ExportFile(FileManagement.CombinePath(MediaFolder, 'k' + Format(k)))));
            RjOrders(Row1, FileManagement.CombinePath(MediaFolder, 'k' + Format(k)), FileOrder, KeyOrder, IndexOrder);
            AllFiles += FileOrder + ' ';
            AllKey += KeyOrder + ' ';
            AllIndex += IndexOrder + ' ';
        end;
        RjObserver.Observe('files', AllFiles);
        RjObserver.Observe('key order', AllKey);
        RjObserver.Observe('media index order', AllIndex);
        RjObserver.Observe('files follow the key order', Format(AllFiles = AllKey));
        RjObserver.Observe('files follow the media index order', Format(AllFiles = AllIndex));
        FileManagement.ServerRemoveDirectory(Dir, true);
        Row1.Reset();
        Row1.SetFilter(Code, 'LTRJ*');
        Row1.DeleteAll();
        Cleanup(Jpg);
        Cleanup(Png);
        // The full listings carry file lengths and which item a file holds: not an oracle (a re-encoded image differs between the Windows and
        // the Linux encoder, corpus issue 723; the item behind a number varies between runs). The ', shape' keys below assert what holds on both.
        RjObserver.Ignore('media folder');
        RjObserver.Ignore('media folder after one');
        RjObserver.Ignore('package folder after one, with sub folders');
        RjObserver.Ignore('media folder after two');
        RjObserver.Ignore('package folder after two, with sub folders');
        RjObserver.Ignore('media folder after again');
        RjObserver.Ignore('temporary path, with sub folders');
        RjObserver.Ignore('slash prefix media folder');
        RjObserver.Ignore('slash prefix package folder, with sub folders');
        // Not an oracle: which item a numbered file holds varies between runs (with it the lengths in the name list); the rule below holds.
        RjObserver.Ignore('al file names after two');
        RjObserver.Ignore('bytes of -1');
        RjObserver.Ignore('bytes of -2');
        RjObserver.Ignore('slash prefix al file names');
        RjObserver.Ignore('files');
        RjObserver.Ignore('key order');
        RjObserver.Ignore('files follow the media index order');
        // ExportFile returns the number of items and writes one file per item, named <prefix>-1, <prefix>-2 ... with no extension ('\' and '/'
        // prefixes alike); file -n holds the content of the n-th Tenant Media Set row of the set in primary key order (ID, Media ID), not
        // Item(n) (Item follows the Media Index, the import order). An imported PNG is re-encoded, a JPEG kept.
        RjObserver.Expect('set counts', '1|2');
        RjObserver.Expect('format set length', '38');
        RjObserver.Expect('format set is MediaId', 'Yes');
        // Whether the Tenant Media content keeps the bytes of the imported file is an image encoder output: Windows BC 29.0 re-encodes the JPEG
        // (No|No|No), the Linux image keeps it on BC 29 (No|Yes|No). Not asserted (corpus issue 723).
        RjObserver.Ignore('tenant item bytes same as files');
        // File Management.GetServerDirectoryFilesList (DotNet Directory.GetFiles) lists the files ExportFile wrote: Name = the full path with
        // backslashes, Value = the file name, no extension, in name order; each file is the Tenant Media content of an item of its set.
        // Windows BC 29.0 (windows-check RJ item B, 2026-10-23); bc-linux dc007079 (bc-linux #181, #183). The older Linux image listed none.
        // InclSubDirs on the package folder, the filtered TemporaryPath listing and a '/' prefix (CombinePath) give the same files.
        RjObserver.Expect('export count one item', '1');
        RjObserver.Expect('media folder after one, shape', '1:[<media>\<set1>-1|v=<set1>-1|content=Yes]|name order=Yes');
        RjObserver.Expect('package folder after one, with sub folders, shape', '1:[<media>\<set1>-1|v=<set1>-1|content=Yes]|name order=Yes');
        RjObserver.Expect('export count two items', '2');
        RjObserver.Expect('media folder after two, shape', '3:[<media>\<set1>-1|v=<set1>-1|content=Yes][<media>\<set2>-1|v=<set2>-1|content=Yes][<media>\<set2>-2|v=<set2>-2|content=Yes]|name order=Yes');
        RjObserver.Expect('package folder after two, with sub folders, shape', '3:[<media>\<set1>-1|v=<set1>-1|content=Yes][<media>\<set2>-1|v=<set2>-1|content=Yes][<media>\<set2>-2|v=<set2>-2|content=Yes]|name order=Yes');
        RjObserver.Expect('export count one item again', '1');
        // The length of the re-encoded 1x1 PNG is an encoder output (Windows 103 bytes, Linux 108): only the names and the content are asserted
        // (corpus issue 723).
        RjObserver.Ignore('al file names after again');
        RjObserver.Ignore('bytes of again -1');
        RjObserver.Expect('again -1 and -2 exist', 'Yes|No');
        RjObserver.Expect('again -1 is the tenant content of its item', 'Yes');
        RjObserver.Expect('media folder after again, shape', '3:[<media>\<set1>-1|v=<set1>-1|content=Yes][<media>\<set2>-1|v=<set2>-1|content=Yes][<media>\<set2>-2|v=<set2>-2|content=Yes]|name order=Yes');
        RjObserver.Expect('temporary path, with sub folders, shape', '3:[<media>\<set1>-1|v=<set1>-1|content=Yes][<media>\<set2>-1|v=<set2>-1|content=Yes][<media>\<set2>-2|v=<set2>-2|content=Yes]|name order=Yes');
        RjObserver.Expect('slash prefix export count', '2');
        RjObserver.Expect('slash prefix media folder, shape', '3:[<media>\<set1>-1|v=<set1>-1|content=Yes][<media>\<set2>-1|v=<set2>-1|content=Yes][<media>\<set2>-2|v=<set2>-2|content=Yes]|name order=Yes');
        RjObserver.Expect('slash prefix package folder, with sub folders, shape', '3:[<media>\<set1>-1|v=<set1>-1|content=Yes][<media>\<set2>-1|v=<set2>-1|content=Yes][<media>\<set2>-2|v=<set2>-2|content=Yes]|name order=Yes');
        RjObserver.Expect('set 1 export count', '2');
        RjObserver.Expect('set 2 export count', '2');
        RjObserver.Expect('set 3 export count', '2');
        RjObserver.Expect('set 4 export count', '2');
        RjObserver.Expect('set 5 export count', '2');
        RjObserver.Expect('set 6 export count', '2');
        RjObserver.Expect('set 7 export count', '2');
        RjObserver.Expect('set 8 export count', '2');
        RjObserver.Expect('media index order', 'i1i2 i1i2 i1i2 i1i2 i1i2 i1i2 i1i2 i1i2 ');
        RjObserver.Expect('files follow the key order', 'Yes');
        RjObserver.Verify();
    end;

    // ---- Listing order (Windows check 7, 2026-10-23, BC 29.0): File Management.GetServerDirectoryFilesList lists a folder in NAME order,
    // case ignored, never in creation order; Value is the file name without its extension. Each case writes its files in an order that
    // differs from the name order (30 ms apart). The same cases through DotNet DirectoryInfo.GetFiles: QxDotNetDemoShapes.al,
    // RJ_DirectoryInfo_GetFiles_ListingOrder. ----

    local procedure RjLoNewDir(Tag: Text): Text
    var
        FileManagement: Codeunit "File Management";
        Dir: Text;
    begin
        Dir := TemporaryPath() + 'ltlo' + Tag + CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 8);
        FileManagement.ServerCreateDirectory(Dir);
        exit(Dir);
    end;

    local procedure RjLoWrite(Name: Text)
    var
        F: File;
    begin
        F.Create(Name);
        F.Write('x');
        F.Close();
        Sleep(30);
    end;

    local procedure RjLoList(Dir: Text; Set1Text: Text; Set2Text: Text): Text
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileManagement: Codeunit "File Management";
        Value: Text;
        Result: Text;
    begin
        FileManagement.GetServerDirectoryFilesList(TempNameValueBuffer, Dir);
        if TempNameValueBuffer.FindSet() then
            repeat
                Value := TempNameValueBuffer.Value;
                if Set1Text <> '' then
                    Value := Value.Replace(Set1Text, '<set1>');
                if Set2Text <> '' then
                    Value := Value.Replace(Set2Text, '<set2>');
                Result += Value + ',';
            until TempNameValueBuffer.Next() = 0;
        FileManagement.ServerRemoveDirectory(Dir, true);
        exit(Result);
    end;

    [Test]
    procedure RJ_GetServerDirectoryFilesList_ListingOrder()
    var
        Observer: Codeunit "Probe Observer";
        Row1: Record "PZ OnPrem Media Row";
        Row2: Record "PZ OnPrem Media Row";
        FileManagement: Codeunit "File Management";
        Dir: Text;
        Png: Text;
        Set1Text: Text;
        Set2Text: Text;
    begin
        // (a) written c, b, a
        Dir := RjLoNewDir('a');
        RjLoWrite(FileManagement.CombinePath(Dir, 'c.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'b.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'a.txt'));
        Observer.Observe('a written c,b,a', RjLoList(Dir, '', ''));
        // (b) MediaSet.ExportFile(Dir + '\' + Format(Set)): set1 (two items) first, then set2 (one item) whose name sorts before set1
        Row1.SetFilter(Code, 'LTLO*');
        Row1.DeleteAll();
        Row1.Reset();
        // Two one-item sets; the one whose id sorts higher gets the second item and becomes set1. The ids are random
        // Guids (seen on OnPrem 27.5 and 28.5, 2026-10-24), so creating set2 until it sorts below set1 failed about once in 41 runs.
        Png := TempName('.png');
        WritePng(Png);
        Row1.Code := 'LTLO0';
        Row1.Set.ImportFile(Png, 'p1');
        Row1.Insert();
        Row2.Code := 'LTLO1';
        Row2.Set.ImportFile(Png, 'p1');
        Row2.Insert();
        Row1.Get('LTLO0');
        Row2.Get('LTLO1');
        if UpperCase(Format(Row2.Set)) < UpperCase(Format(Row1.Set)) then
            Row1.Get('LTLO0')
        else begin
            Row1.Get('LTLO1');
            Row2.Get('LTLO0');
        end;
        Row1.Set.ImportFile(Png, 'p2');
        Row1.Modify();
        Row1.Get(Row1.Code);
        Set1Text := Format(Row1.Set);
        Set2Text := Format(Row2.Set);
        Observer.Observe('b set2 sorts before set1', Format(UpperCase(Set2Text) < UpperCase(Set1Text)));
        Dir := RjLoNewDir('b');
        Observer.Observe('b export set1', Format(Row1.Set.ExportFile(Dir + '\' + Format(Row1.Set))));
        Sleep(30);
        Observer.Observe('b export set2', Format(Row2.Set.ExportFile(Dir + '\' + Format(Row2.Set))));
        Observer.Observe('b exported set1 then set2', RjLoList(Dir, Set1Text, Set2Text));
        Row1.Reset();
        Row1.SetFilter(Code, 'LTLO*');
        Row1.DeleteAll();
        Cleanup(Png);
        // (b2) Guid-shaped names, the high one written first
        Dir := RjLoNewDir('b2');
        RjLoWrite(FileManagement.CombinePath(Dir, '{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}-1'));
        RjLoWrite(FileManagement.CombinePath(Dir, '{00000000-0000-0000-0000-000000000000}-1'));
        Observer.Observe('b2 written FFFF then 0000', RjLoList(Dir, '', ''));
        // (c) mixed case: written B, a
        Dir := RjLoNewDir('c');
        RjLoWrite(FileManagement.CombinePath(Dir, 'B.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'a.txt'));
        Observer.Observe('c written B,a', RjLoList(Dir, '', ''));
        // (c2) written a, C, b: creation order a,C,b; name order with case ignored a,b,C; ordinal order C,a,b
        Dir := RjLoNewDir('c2');
        RjLoWrite(FileManagement.CombinePath(Dir, 'a.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'C.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'b.txt'));
        Observer.Observe('c2 written a,C,b', RjLoList(Dir, '', ''));
        // (d) ten files written in shuffled order
        Dir := RjLoNewDir('d');
        RjLoWrite(FileManagement.CombinePath(Dir, 'f07.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f02.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f09.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f01.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f10.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f05.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f03.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f08.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f04.txt'));
        RjLoWrite(FileManagement.CombinePath(Dir, 'f06.txt'));
        Observer.Observe('d written 07,02,09,01,10,05,03,08,04,06', RjLoList(Dir, '', ''));
        // Windows BC 29.0 (windows-check 7, 2026-10-23); bc-linux dc007079 lists in the same order (bc-linux #183).
        Observer.Expect('a written c,b,a', 'a,b,c,');
        Observer.Expect('b set2 sorts before set1', 'Yes');
        Observer.Expect('b export set1', '2');
        Observer.Expect('b export set2', '1');
        Observer.Expect('b exported set1 then set2', '<set2>-1,<set1>-1,<set1>-2,');
        Observer.Expect('b2 written FFFF then 0000', '{00000000-0000-0000-0000-000000000000}-1,{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}-1,');
        Observer.Expect('c written B,a', 'a,B,');
        Observer.Expect('c2 written a,C,b', 'a,b,C,');
        Observer.Expect('d written 07,02,09,01,10,05,03,08,04,06', 'f01,f02,f03,f04,f05,f06,f07,f08,f09,f10,');
        Observer.Verify();
    end;
}
