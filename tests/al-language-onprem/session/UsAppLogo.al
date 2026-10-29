// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-json-files
// Scope: in-scope (OnPrem app: the Published Application table is OnPrem)
// Fixtures used: Probe Observer (codeunit 69160); the logo of cross-app fixtures C (300 x 300 gray PNG, 90393 bytes) and D (1 x 1 gray PNG, 67 bytes)
// Probe (writer US, outside issue 6148): an app whose app.json declares a logo. What does the Logo (Media) of its Published Application row hold:
//   the file bytes unchanged, which Media columns, and does the Guided Experience Item.Icon an app registers (System Application,
//   GuidedExperienceImpl GetExtensionLogo + Icon.ImportStream) hold the same bytes. Cross-app fixture D registers the items (Codeunit.Run 61161).
// Not pinned: the Tenant Media bytes of the Icon differ from the logo file (BC re-encodes the PNG on import; the bytes came from the Linux container).
// BC versions: 27, 28, 29
codeunit 98010 "LT US App Logo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TinyPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR42mNoAAAAggCB2kUIOwAAAABJRU5ErkJggg==', Locked = true;
        BigPngSha256: Label '81b16005cb41c2481566f9d80dcd71a2af23da858b0d3fa3e4291ebcb9125d05', Locked = true;
        AppDId: Label 'e92be076-de11-44ed-895e-17031341df29', Locked = true;
        AppCId: Label '0df0fadc-d339-4b0f-a1d5-51dc51f10900', Locked = true;

    local procedure ColumnDump(var Media: Record Media): Text
    var
        Ref: RecordRef;
        Fld: FieldRef;
        Index: Integer;
        Result: Text;
    begin
        Ref.GetTable(Media);
        for Index := 1 to Ref.FieldCount() do begin
            Fld := Ref.FieldIndex(Index);
            if Fld.Type() = FieldType::Blob then
                Result += Fld.Name() + '=<blob>;'
            else
                if Fld.Type() = FieldType::Guid then
                    Result += Fld.Name() + '=<guid null=' + Format(IsNullGuid(Fld.Value())) + '>;'
                else
                    if Fld.Type() = FieldType::DateTime then
                        Result += Fld.Name() + '=<datetime empty=' + Format(Format(Fld.Value()) = '') + '>;'
                    else
                        Result += Fld.Name() + '=' + Format(Fld.Value()) + ';';
        end;
        exit(Result);
    end;

    local procedure ReadBase64(var Media: Record Media): Text
    var
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
    begin
        Media.CalcFields(Content);
        Media.Content.CreateInStream(InS);
        exit(Base64.ToBase64(InS));
    end;

    local procedure ReadSha256(var Media: Record Media): Text
    var
        Crypto: Codeunit "Cryptography Management";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
    begin
        Media.CalcFields(Content);
        Media.Content.CreateInStream(InS);
        TempBlob.CreateOutStream(OutS);
        CopyStream(OutS, InS);
        TempBlob.CreateInStream(InS);
        exit(LowerCase(Crypto.GenerateHash(InS, 2)));
    end;

    local procedure LenOf(var Media: Record Media): Integer
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
    begin
        Media.CalcFields(Content);
        Media.Content.CreateInStream(InS);
        TempBlob.CreateOutStream(OutS);
        CopyStream(OutS, InS);
        exit(TempBlob.Length());
    end;

    [Test]
    procedure UsLogo_TinyPng_AppD()
    var
        Observer: Codeunit "Probe Observer";
        App: Record "Published Application";
        Media: Record Media;
        Id: Guid;
        First: Guid;
    begin
        Evaluate(Id, AppDId);
        App.SetRange(ID, Id);
        App.SetRange("Tenant Visible", true);
        Observer.Observe('row found', Format(App.FindFirst()));
        Observer.Observe('logo has value', Format(App.Logo.HasValue()));
        Observer.Observe('media id null', Format(IsNullGuid(App.Logo.MediaId())));
        First := App.Logo.MediaId();
        App.FindFirst();
        Observer.Observe('same media id on second FindFirst', Format(App.Logo.MediaId() = First));
        Media.SetRange(ID, App.Logo.MediaId());
        Observer.Observe('media row found', Format(Media.FindFirst()));
        Observer.Observe('columns', ColumnDump(Media));
        Observer.Observe('content has value', Format(Media.Content.HasValue()));
        Media.CalcFields(Content);
        Observer.Observe('content has value after CalcFields', Format(Media.Content.HasValue()));
        Observer.Observe('length', Format(LenOf(Media)));
        Observer.Observe('equals file', Format(ReadBase64(Media) = TinyPngBase64));
        Observer.Expect('row found', 'Yes');
        Observer.Expect('logo has value', 'Yes');
        Observer.Expect('media id null', 'No');
        Observer.Expect('same media id on second FindFirst', 'Yes');
        Observer.Expect('media row found', 'Yes');
        Observer.Expect('columns', 'ID=<guid null=No>;Description=;Content=<blob>;Mime Type=image/png;Height=1;Width=1;Company Name=;Expiration Date=<datetime empty=Yes>;Prohibit Cache=No;File Name=;Security Token=;Creating User=;');
        Observer.Expect('content has value', 'Yes');
        Observer.Expect('content has value after CalcFields', 'Yes');
        Observer.Expect('length', '67');
        Observer.Expect('equals file', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UsLogo_BigPng_AppC()
    var
        Observer: Codeunit "Probe Observer";
        App: Record "Published Application";
        Media: Record Media;
        Id: Guid;
    begin
        Evaluate(Id, AppCId);
        App.SetRange(ID, Id);
        App.SetRange("Tenant Visible", true);
        Observer.Observe('row found', Format(App.FindFirst()));
        Observer.Observe('logo has value', Format(App.Logo.HasValue()));
        Media.SetRange(ID, App.Logo.MediaId());
        Observer.Observe('media row found', Format(Media.FindFirst()));
        Observer.Observe('columns', ColumnDump(Media));
        Observer.Observe('length', Format(LenOf(Media)));
        Observer.Observe('sha256', ReadSha256(Media));
        Observer.Observe('equals file', Format(ReadSha256(Media) = BigPngSha256));
        Observer.Expect('row found', 'Yes');
        Observer.Expect('logo has value', 'Yes');
        Observer.Expect('media row found', 'Yes');
        Observer.Expect('columns', 'ID=<guid null=No>;Description=;Content=<blob>;Mime Type=image/png;Height=300;Width=300;Company Name=;Expiration Date=<datetime empty=Yes>;Prohibit Cache=No;File Name=;Security Token=;Creating User=;');
        Observer.Expect('length', '90393');
        Observer.Expect('sha256', '81b16005cb41c2481566f9d80dcd71a2af23da858b0d3fa3e4291ebcb9125d05');
        Observer.Expect('equals file', 'Yes');
        Observer.Verify();
    end;

    // The Guided Experience Item table is internal to System Application, so the test reads the Tenant Media rows the registration adds:
    // Icon.ImportStream(IconInStream, ExtensionId) stores the logo as a Tenant Media row (Description = the extension id as text).
    [Test]
    procedure UsLogo_GuidedExperienceIcon_CallerD()
    var
        Observer: Codeunit "Probe Observer";
        GuidedExperience: Codeunit "Guided Experience";
        TenantMedia: Record "Tenant Media";
        Before: List of [Guid];
        Added: Integer;
    begin
        if TenantMedia.FindSet() then
            repeat
                Before.Add(TenantMedia.ID);
            until TenantMedia.Next() = 0;
        Codeunit.Run(61161);
        Observer.Observe('assisted exists', Format(GuidedExperience.Exists(Enum::"Guided Experience Type"::"Assisted Setup", ObjectType::Codeunit, 61161)));
        Observer.Observe('manual exists', Format(GuidedExperience.Exists(Enum::"Guided Experience Type"::"Manual Setup", ObjectType::Codeunit, 61161)));
        if TenantMedia.FindSet() then
            repeat
                if not Before.Contains(TenantMedia.ID) then begin
                    Added += 1;
                    TenantMedia.CalcFields(Content);
                    Observer.Observe('added ' + Format(Added) + ' description', TenantMedia.Description);
                    Observer.Observe('added ' + Format(Added) + ' mime', TenantMedia."Mime Type");
                    Observer.Observe('added ' + Format(Added) + ' width x height', Format(TenantMedia.Width) + 'x' + Format(TenantMedia.Height));
                    Observer.Observe('added ' + Format(Added) + ' file name', TenantMedia."File Name");
                end;
            until TenantMedia.Next() = 0;
        Observer.Observe('tenant media rows added', Format(Added));
        Observer.Expect('assisted exists', 'Yes');
        Observer.Expect('manual exists', 'Yes');
        Observer.Expect('added 1 description', '{E92BE076-DE11-44ED-895E-17031341DF29}');
        Observer.Expect('added 1 mime', 'image/png');
        Observer.Expect('added 1 width x height', '1x1');
        Observer.Expect('added 1 file name', '');
        Observer.Expect('added 2 description', '{E92BE076-DE11-44ED-895E-17031341DF29}');
        Observer.Expect('added 2 mime', 'image/png');
        Observer.Expect('added 2 width x height', '1x1');
        Observer.Expect('added 2 file name', '');
        Observer.Expect('tenant media rows added', '2');
        GuidedExperience.Remove(Enum::"Guided Experience Type"::"Assisted Setup", ObjectType::Codeunit, 61161);
        GuidedExperience.Remove(Enum::"Guided Experience Type"::"Manual Setup", ObjectType::Codeunit, 61161);
        Observer.Verify();
    end;
}
