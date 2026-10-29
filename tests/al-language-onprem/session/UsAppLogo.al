// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-json-files
// Scope: in-scope (OnPrem app: the Published Application table is OnPrem)
// Fixtures used: Probe Observer (codeunit 69160); the logo of cross-app fixtures C (300 x 300 gray PNG, 90393 bytes) and D (1 x 1 gray PNG, 67 bytes)
// Probe (writer US, outside issue 6148): an app whose app.json declares a logo. What does the Logo (Media) of its Published Application row hold:
//   the file bytes unchanged, which Media columns, and does the Guided Experience Item.Icon an app registers (System Application,
//   GuidedExperienceImpl GetExtensionLogo + Icon.ImportStream) hold the same bytes. Cross-app fixture D registers the items (Codeunit.Run 61161).
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
        Observer.Observe('base64', ReadBase64(Media));
        Observer.Observe('equals file', Format(ReadBase64(Media) = TinyPngBase64));
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure UsLogo_GuidedExperienceIcon_CallerD()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "Guided Experience Item";
        TenantMedia: Record "Tenant Media";
        Id: Guid;
    begin
        Evaluate(Id, AppDId);
        Item.SetRange("Extension ID", Id);
        Item.DeleteAll();
        Codeunit.Run(61161);
        Item.SetRange("Extension ID", Id);
        Observer.Observe('items', Format(Item.Count()));
        if Item.FindSet() then
            repeat
                Observer.Observe(Item.Title + ' type', Format(Item."Guided Experience Type"));
                Observer.Observe(Item.Title + ' icon has value', Format(Item.Icon.HasValue()));
                Observer.Observe(Item.Title + ' icon media id null', Format(IsNullGuid(Item.Icon.MediaId())));
                TenantMedia.SetRange(ID, Item.Icon.MediaId());
                Observer.Observe(Item.Title + ' tenant media found', Format(TenantMedia.FindFirst()));
                TenantMedia.CalcFields(Content);
                Observer.Observe(Item.Title + ' tenant media base64', ReadTenantBase64(TenantMedia));
                Observer.Observe(Item.Title + ' mime', TenantMedia."Mime Type");
                Observer.Observe(Item.Title + ' width x height', Format(TenantMedia.Width) + 'x' + Format(TenantMedia.Height));
            until Item.Next() = 0;
        Item.DeleteAll();
        Observer.Finish();
    end;

    local procedure ReadTenantBase64(var TenantMedia: Record "Tenant Media"): Text
    var
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
    begin
        TenantMedia.Content.CreateInStream(InS);
        exit(Base64.ToBase64(InS));
    end;
}
