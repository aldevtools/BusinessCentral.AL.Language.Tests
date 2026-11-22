// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-json-files
// Scope: in-scope (OnPrem app: the Published Application table is OnPrem)
// Fixtures used: Probe Observer (codeunit 69160); a NEW cross-app fixture E whose app.json declares "logo": "logo.jpg" (an 8 x 8
//   baseline JPEG, 307 bytes; its SHA-256 is in the label below) and that registers an assisted setup in an
//   OnRegisterAssistedSetup subscriber, as fixture D does for its PNG.
// Probe (outside issue al-runner 8061): next to UsAppLogo.al, the Logo (Media) of the Published Application row of an app whose
//   logo is a JPEG: has it a value, which Media columns (Mime Type, Height, Width), are the bytes the file unchanged; and does the
//   login's registration of fixture E's assisted setup (Guided Experience GetExtensionLogo + Icon.ImportStream) run without an error.
// Values: what BC 27.5, 28.5 and 29.0 produced; the Media Mime Type is image/png on 27.5 and 28.5 and image/jpeg on 29.0 (#if BC29PLUS).
// BC versions: 27, 28, 29
codeunit 98012 "LT US App Logo Jpeg"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        AppEId: Label 'b4f0ccbc-b970-4e2c-8d83-94481f40e804', Locked = true;
        JpegSha256: Label 'fe4b2404523616a34f078cf93dfd7d437016df51bf0c3a5ab40d50a70a8f7d20', Locked = true;

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
    procedure UsLogo_Jpeg_AppE()
    var
        Observer: Codeunit "Probe Observer";
        App: Record "Published Application";
        Media: Record Media;
        Id: Guid;
        First: Guid;
    begin
        Evaluate(Id, AppEId);
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
        Observer.Observe('length', Format(LenOf(Media)));
        Observer.Observe('equals file', Format(ReadSha256(Media) = JpegSha256));
        Observer.Expect('row found', 'Yes');
        Observer.Expect('logo has value', 'Yes');
        Observer.Expect('media id null', 'No');
        Observer.Expect('same media id on second FindFirst', 'Yes');
        Observer.Expect('media row found', 'Yes');
#if BC29PLUS
        Observer.Expect('columns', 'ID=<guid null=No>;Description=;Content=<blob>;Mime Type=image/jpeg;Height=8;Width=8;Company Name=;Expiration Date=<datetime empty=Yes>;Prohibit Cache=No;File Name=;Security Token=;Creating User=;');
#else
        Observer.Expect('columns', 'ID=<guid null=No>;Description=;Content=<blob>;Mime Type=image/png;Height=8;Width=8;Company Name=;Expiration Date=<datetime empty=Yes>;Prohibit Cache=No;File Name=;Security Token=;Creating User=;');
#endif
        Observer.Expect('content has value', 'Yes');
        Observer.Expect('length', '307');
        Observer.Expect('equals file', 'Yes');
        Observer.Verify();
    end;

    // The login raised OnRegisterAssistedSetup before this test; fixture E's subscriber registered its wizard with E's logo as the
    // icon (Guided Experience GetExtensionLogo + Icon.ImportStream) without an error. The Tenant Media row counts it adds belong to
    // Microsoft's tables and differ per version (image/jpeg 42, 45, 46 and image/png 130, 138, 138 on 27.5, 28.5, 29.0), so
    // they are not asserted.
    [Test]
    procedure UsLogo_Jpeg_GuidedExperienceIcon_AppE()
    var
        Observer: Codeunit "Probe Observer";
        TenantMedia: Record "Tenant Media";
    begin
        TenantMedia.SetRange("Mime Type", 'image/jpeg');
        Observer.Observe('jpeg tenant media rows', Format(TenantMedia.Count()));
        Observer.Discard();
    end;
}
