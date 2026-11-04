// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/mediaset/mediaset-importfile-method
// Scope: in-scope (OnPrem app: Media.ImportFile and MediaSet.ImportFile are Scope = OnPrem)
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 98040 and test codeunit 98041
// Probe (writer RE, Microsoft's DemoTool: 5 of its 20 item pictures are files named .jpg that hold PNG data, imported with
//   Item.Picture.ImportFile(Path, Description) on a MediaSet field): a 3 x 2 PNG file named .jpg through Media.ImportFile and MediaSet.ImportFile
//   with two arguments: the returned Guid, HasValue, MediaSet.Count, and the Tenant Media row (Mime Type, Description, File Name, Width, Height).
//   A .jpg file that holds JPEG data is pinned in media/MediaFiles.al (QX_MediaAndMediaSet_ImportFile_Jpeg).
// BC versions: 27, 28, 29
table 98040 "LT RE Media Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Pic; Media) { }
        field(3; Set; MediaSet) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 98041 "LT RE Media Jpg Holding Png"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        // A 3 x 2 RGB PNG (73 bytes).
        PngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAMAAAACCAIAAAASFvFNAAAAEElEQVR42mP4z8DAAMFwFgA72AX7NhGY6gAAAABJRU5ErkJggg==', Locked = true;

    local procedure TempName(Suffix: Text): Text
    begin
        exit(TemporaryPath() + 'ltremedia' + DelChr(Format(CreateGuid()), '=', '{}-') + Suffix);
    end;

    local procedure WritePng(Name: Text)
    var
        F: File;
        OutS: OutStream;
        Base64: Codeunit "Base64 Convert";
    begin
        F.Create(Name);
        F.CreateOutStream(OutS);
        Base64.FromBase64(PngBase64, OutS);
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

    local procedure Cleanup(Name: Text)
    begin
        if File.Exists(Name) then
            File.Erase(Name);
    end;

    local procedure DescribeTenant(Id: Guid; Src: Text): Text
    var
        Tenant: Record "Tenant Media";
        Name: Text;
    begin
        if not Tenant.Get(Id) then
            exit('no tenant media row');
        Tenant.CalcFields(Content);
        exit('description=[' + Tenant.Description + '] mime=[' + Tenant."Mime Type" + '] width=' + Format(Tenant.Width) +
            ' height=' + Format(Tenant.Height) + ' hascontent=' + Format(Tenant.Content.HasValue()));
    end;

    local procedure TenantFileName(Id: Guid; Src: Text): Text
    var
        Tenant: Record "Tenant Media";
        Name: Text;
    begin
        if not Tenant.Get(Id) then
            exit('no tenant media row');
        Name := Tenant."File Name";
        Name := Name.Replace(TemporaryPath(), '<tmp>');
        Name := Name.Replace(CopyStr(Src, StrLen(TemporaryPath()) + 1), '<name>');
        exit(Name);
    end;

    local procedure ContentLength(Id: Guid): Integer
    var
        Tenant: Record "Tenant Media";
        InS: InStream;
        B: Byte;
        Total: Integer;
    begin
        if not Tenant.Get(Id) then
            exit(-1);
        Tenant.CalcFields(Content);
        Tenant.Content.CreateInStream(InS);
        while not InS.EOS() do
            Total += InS.Read(B);
        exit(Total);
    end;

    [Test]
    procedure RE_MediaAndMediaSet_ImportFile_JpgHoldingPng()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RE Media Row";
        Src: Text;
        Id: Guid;
    begin
        Row.DeleteAll();
        Src := TempName('.jpg');
        WritePng(Src);
        Observer.Observe('file length', Format(LenOf(Src)));
        Row.Code := 'LTREA';
        Id := Row.Pic.ImportFile(Src, 'Item picture');
        Observer.Observe('media id is null', Format(IsNullGuid(Id)));
        Observer.Observe('media id = MediaId', Format(Id = Row.Pic.MediaId()));
        Observer.Observe('media hasvalue', Format(Row.Pic.HasValue()));
        Row.Insert();
        Observer.Observe('media tenant', DescribeTenant(Id, Src));
        Observer.Observe('media file name', TenantFileName(Id, Src));
        Observer.Observe('media content length', Format(ContentLength(Id)));
        Row.Code := 'LTREB';
        Clear(Row.Pic);
        Id := Row.Set.ImportFile(Src, 'Item picture');
        Observer.Observe('mediaset id is null', Format(IsNullGuid(Id)));
        Observer.Observe('mediaset count', Format(Row.Set.Count()));
        Observer.Observe('mediaset id = Item(1)', Format(Id = Row.Set.Item(1)));
        Observer.Observe('mediaset id = MediaId', Format(Id = Row.Set.MediaId()));
        Row.Insert();
        Observer.Observe('mediaset item 1 tenant', DescribeTenant(Row.Set.Item(1), Src));
        Observer.Observe('mediaset file name', TenantFileName(Row.Set.Item(1), Src));
        Observer.Observe('mediaset return tenant', DescribeTenant(Id, Src));
        Observer.Observe('mediaset content length', Format(ContentLength(Row.Set.Item(1))));
        Row.Get('LTREB');
        Observer.Observe('mediaset count after get', Format(Row.Set.Count()));
        Row.DeleteAll();
        Cleanup(Src);
        Observer.Expect('file length', '73');
        Observer.Expect('media id is null', 'No');
        Observer.Expect('media id = MediaId', 'Yes');
        Observer.Expect('media hasvalue', 'Yes');
        // The Mime Type follows the .jpg file name, not the PNG data; Width and Height are read from the PNG data.
        Observer.Expect('media tenant', 'description=[Item picture] mime=[image/jpeg] width=3 height=2 hascontent=Yes');
        Observer.Expect('media file name', '<tmp><name>');
        // The stored content is re-encoded (111 bytes on the Linux tiers); Windows re-encodes images differently (see MediaFiles.al), not asserted.
        Observer.Ignore('media content length');
        Observer.Expect('mediaset id is null', 'No');
        Observer.Expect('mediaset count', '1');
        // MediaSet.ImportFile returns the MediaSet id, not the id of the media it adds: no Tenant Media row has that id.
        Observer.Expect('mediaset id = Item(1)', 'No');
        Observer.Expect('mediaset id = MediaId', 'Yes');
        Observer.Expect('mediaset item 1 tenant', 'description=[Item picture] mime=[image/jpeg] width=3 height=2 hascontent=Yes');
        // MediaSet.ImportFile stores the bare file name: Windows BC 27.5, 28.5 and 29.0 (Windows check of QX_MediaAndMediaSet_ImportFile_Jpeg,
        // 2026-10-22, same call) and bc-linux dc007079 (bc-linux #176). The older Linux image stored 'TEMP\<name>'.
        Observer.Expect('mediaset file name', '<name>');
        Observer.Expect('mediaset return tenant', 'no tenant media row');
        Observer.Ignore('mediaset content length');
        Observer.Expect('mediaset count after get', '1');
        Observer.Verify();
    end;
}
