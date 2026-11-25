// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-json-files
// Scope: in-scope (OnPrem app: the Published Application table is OnPrem)
// Fixtures used: Probe Observer (codeunit 69160); cross-app fixtures E (8 x 8 baseline JPEG logo, see UsAppLogoJpeg.al), G, H, J
//   and K (CONTRIBUTING.md, "Multi-app fixtures"). Each of G, H, J and K declares "logo": "logo.jpg" in its app.json and registers
//   an assisted setup in an OnRegisterAssistedSetup subscriber, as fixture E does. The SHA-256 of each logo file is in a label below.
// Probe (outside issue al-runner 9111): next to UsAppLogoJpeg.al (8 x 8 only), the Logo (Media) of the Published Application row of
//   apps whose logo is a JPEG of another size or encoding, and the Icon that the login's registration of each app's assisted setup
//   stores (Guided Experience GetExtensionLogo + Icon.ImportStream, read here through a RecordRef: the table is Internal).
// OBSERVE FORM: values not yet measured.
// BC versions: 27, 28, 29
codeunit 98084 "LT US App Logo Jpeg Sizes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        AppEId: Label 'b4f0ccbc-b970-4e2c-8d83-94481f40e804', Locked = true;
        AppGId: Label '58c27790-73f6-4cdc-a683-e2cc5dce44d3', Locked = true;
        AppHId: Label 'f985f602-d5a4-4fe8-acd8-6b725247f273', Locked = true;
        AppJId: Label '9b24c778-d90f-4ea0-b941-baeda98e3ef4', Locked = true;
        AppKId: Label 'd6d4ac8f-10f6-42aa-9f09-139650c9ec53', Locked = true;
        // SHA-256 of the logo.jpg files: E 8 x 8 baseline (307 bytes), G 535 x 534 baseline (14191 bytes), H 16 x 8 baseline
        // (633 bytes), J 400 x 300 baseline (62851 bytes), K 535 x 534 progressive (9857 bytes).
        ShaE: Label 'fe4b2404523616a34f078cf93dfd7d437016df51bf0c3a5ab40d50a70a8f7d20', Locked = true;
        ShaG: Label 'ad3b0b5be06ae48b184f3a740d8c32bb7a0ac66db5929ca22f9b22acbd71c3cf', Locked = true;
        ShaH: Label '40c431dff5fda382fd9b7abf1fc1a0d43b7d838199b55ea95ed976c792f4330c', Locked = true;
        ShaJ: Label '193d251937728862753a712815ec62c4f1c60e190695f274455d890523f121b6', Locked = true;
        ShaK: Label '6c0912dfa89f471a8e5398e4479ea27a0d2720fea266203f416afa68497ee4b1', Locked = true;

    local procedure CopyToBlob(var InS: InStream; var TempBlob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        CopyStream(OutS, InS);
    end;

    local procedure Sha256Of(var TempBlob: Codeunit "Temp Blob"): Text
    var
        Crypto: Codeunit "Cryptography Management";
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS);
        exit(LowerCase(Crypto.GenerateHash(InS, 2)));
    end;

    local procedure ObserveLogo(var Observer: Codeunit "Probe Observer"; AppIdText: Text; Sha: Text)
    var
        App: Record "Published Application";
        Media: Record Media;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Id: Guid;
    begin
        Evaluate(Id, AppIdText);
        App.SetRange(ID, Id);
        App.SetRange("Tenant Visible", true);
        Observer.Observe('row found', Format(App.FindFirst()));
        Observer.Observe('logo has value', Format(App.Logo.HasValue()));
        Observer.Observe('logo media id null', Format(IsNullGuid(App.Logo.MediaId())));
        Media.SetRange(ID, App.Logo.MediaId());
        Observer.Observe('media row found', Format(Media.FindFirst()));
        Observer.Observe('mime type', Media."Mime Type");
        Observer.Observe('height', Format(Media.Height));
        Observer.Observe('width', Format(Media.Width));
        Media.CalcFields(Content);
        Observer.Observe('content has value', Format(Media.Content.HasValue()));
        Media.Content.CreateInStream(InS);
        CopyToBlob(InS, TempBlob);
        Observer.Observe('length', Format(TempBlob.Length()));
        Observer.Observe('equals file', Format(Sha256Of(TempBlob) = Sha));
    end;

    local procedure ObserveIcon(var Observer: Codeunit "Probe Observer"; AppIdText: Text; Sha: Text)
    var
        App: Record "Published Application";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        Item: RecordRef;
        IconField: FieldRef;
        InS: InStream;
        Id: Guid;
        IconId: Guid;
    begin
        Evaluate(Id, AppIdText);
        Item.Open(1990); // Guided Experience Item (System Application, Access = Internal)
        Item.Field(10).SetRange(Id); // Extension ID
        Observer.Observe('items of the app', Format(Item.Count()));
        Observer.Observe('item found', Format(Item.FindFirst()));
        IconField := Item.Field(20); // Icon (Media)
        Observer.Observe('icon text empty', Format(Format(IconField.Value()) = ''));
        Observer.Observe('icon evaluates to guid', Format(Evaluate(IconId, Format(IconField.Value()))));
        Observer.Observe('icon media id null', Format(IsNullGuid(IconId)));
        App.SetRange(ID, Id);
        App.SetRange("Tenant Visible", true);
        if App.FindFirst() then
            Observer.Observe('icon media id equals logo media id', Format(IconId = App.Logo.MediaId()));
        TenantMedia.SetRange(ID, IconId);
        Observer.Observe('tenant media row found', Format(TenantMedia.FindFirst()));
        Observer.Observe('icon mime type', TenantMedia."Mime Type");
        Observer.Observe('icon height', Format(TenantMedia.Height));
        Observer.Observe('icon width', Format(TenantMedia.Width));
        Observer.Observe('icon description is the app id', Format(TenantMedia.Description = Format(Id)));
        Observer.Observe('icon description has the app id', Format(StrPos(LowerCase(TenantMedia.Description), LowerCase(DelChr(Format(Id), '=', '{}'))) > 0));
        TenantMedia.CalcFields(Content);
        Observer.Observe('icon content has value', Format(TenantMedia.Content.HasValue()));
        TenantMedia.Content.CreateInStream(InS);
        CopyToBlob(InS, TempBlob);
        Observer.Observe('icon length', Format(TempBlob.Length()));
        Observer.Observe('icon equals file', Format(Sha256Of(TempBlob) = Sha));
        Item.Close();
    end;

    [Test]
    procedure UsLogo_Jpeg535x534_AppG()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLogo(Observer, AppGId, ShaG);
        Observer.Finish();
    end;

    [Test]
    procedure UsLogo_Jpeg16x8_AppH()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLogo(Observer, AppHId, ShaH);
        Observer.Finish();
    end;

    [Test]
    procedure UsLogo_Jpeg400x300_AppJ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLogo(Observer, AppJId, ShaJ);
        Observer.Finish();
    end;

    [Test]
    procedure UsLogo_JpegProgressive535x534_AppK()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLogo(Observer, AppKId, ShaK);
        Observer.Finish();
    end;

    [Test]
    procedure UsLogo_GuidedExperienceIcon_Jpeg8x8_AppE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveIcon(Observer, AppEId, ShaE);
        Observer.Finish();
    end;

    [Test]
    procedure UsLogo_GuidedExperienceIcon_Jpeg535x534_AppG()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveIcon(Observer, AppGId, ShaG);
        Observer.Finish();
    end;

    [Test]
    procedure UsLogo_GuidedExperienceIcon_Jpeg16x8_AppH()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveIcon(Observer, AppHId, ShaH);
        Observer.Finish();
    end;

    [Test]
    procedure UsLogo_GuidedExperienceIcon_Jpeg400x300_AppJ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveIcon(Observer, AppJId, ShaJ);
        Observer.Finish();
    end;

    [Test]
    procedure UsLogo_GuidedExperienceIcon_JpegProgressive535x534_AppK()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveIcon(Observer, AppKId, ShaK);
        Observer.Finish();
    end;
}
