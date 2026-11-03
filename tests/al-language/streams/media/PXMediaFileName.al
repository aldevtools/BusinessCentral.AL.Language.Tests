// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-importstream-method
// Scope: in-scope
// Fixtures used: self-contained table 69189, codeunit 69187
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// Media.ImportStream in 27 takes (InStream, Description, [MimeType]); a form with a file name (4 arguments) does not exist (AL0126, must-not-compile case 0076).
// The "Tenant Media" row of the imported picture: Description is the second argument (also when it looks like a file name, 'picture.png'), "Mime Type" is the third
// ('image/png', also when it is omitted), "File Name" stays empty, Width and Height are those of the picture (1 x 1); an empty Description stays empty.
// BC versions: 27.5

table 69189 "PX Media Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Pic; Media) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 69187 "PX Media Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;

    local procedure PngStream(var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64(ValidPngBase64, OutS);
        TempBlob.CreateInStream(InS);
    end;

    [Test]
    procedure ImportStream_DescriptionAndMimeType_TenantMediaRow()
    var
        Row: Record "PX Media Row";
        Tenant: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        PngStream(TempBlob, InS);
        Row.Code := 'A';
        Row.Pic.ImportStream(InS, 'the description', 'image/png');
        Row.Insert();
        Tenant.Get(Row.Pic.MediaId());
        Observer.Observe('tenant_description', Tenant.Description);
        Observer.Observe('tenant_mime', Tenant."Mime Type");
        Observer.Observe('tenant_filename', Tenant."File Name");
        Observer.Observe('tenant_width', Format(Tenant.Width));
        Observer.Observe('tenant_height', Format(Tenant.Height));
        Observer.Expect('tenant_description', 'the description');
        Observer.Expect('tenant_mime', 'image/png');
        Observer.Expect('tenant_filename', '');
        Observer.Expect('tenant_width', '1');
        Observer.Expect('tenant_height', '1');
        Observer.Verify();
    end;

    [Test]
    procedure ImportStream_DescriptionOnly_AndEmptyDescription()
    var
        Row: Record "PX Media Row";
        Tenant: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        PngStream(TempBlob, InS);
        Row.Code := 'A';
        Row.Pic.ImportStream(InS, 'picture.png');
        Row.Insert();
        Tenant.Get(Row.Pic.MediaId());
        Observer.Observe('description_only_description', Tenant.Description);
        Observer.Observe('description_only_mime', Tenant."Mime Type");
        Observer.Observe('description_only_filename', Tenant."File Name");
        PngStream(TempBlob, InS);
        Row.Code := 'B';
        Row.Pic.ImportStream(InS, '');
        Row.Insert();
        Tenant.Get(Row.Pic.MediaId());
        Observer.Observe('empty_description_description', Tenant.Description);
        Observer.Observe('empty_description_mime', Tenant."Mime Type");
        Observer.Observe('empty_description_filename', Tenant."File Name");
        Observer.Expect('description_only_description', 'picture.png');
        Observer.Expect('description_only_mime', 'image/png');
        Observer.Expect('description_only_filename', '');
        Observer.Expect('empty_description_description', '');
        Observer.Expect('empty_description_mime', 'image/png');
        Observer.Expect('empty_description_filename', '');
        Observer.Verify();
    end;
}
