// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-json-files
// Scope: in-scope (OnPrem app: the Published Application table is OnPrem)
// Fixtures used: Probe Observer (codeunit 69160); cross-app fixtures E (8 x 8 baseline JPEG logo, see UsAppLogoJpeg.al), G, H, J
//   and K (CONTRIBUTING.md, "Multi-app fixtures"). Each of G, H, J and K declares "logo": "logo.jpg" in its app.json and registers
//   an assisted setup in an OnRegisterAssistedSetup subscriber, as fixture E does. The SHA-256 of each logo file is in a label below.
// Probe (outside issue al-runner 9111): next to UsAppLogoJpeg.al (8 x 8 only), the Logo (Media) of the Published Application row of
//   apps whose logo is a JPEG of another size or encoding, and the Icon that the Guided Experience stores when it registers each
//   app's assisted setup (GetExtensionLogo + Icon.ImportStream). The Guided Experience Item table is Internal, so it is read here
//   through a RecordRef.
// What BC did (27.5 and 29.0 measured locally; 28.5 by the corpus CI run):
//   - Logo: for each of the four logos the Media row has Mime Type image/jpeg, Height and Width of the image, and the file's bytes
//     unchanged. (The 8 x 8 logo of fixture E is image/png on 27.5 and 28.5, see UsAppLogoJpeg.al; these sizes are image/jpeg on
//     every version.)
//   - The test session's login does not raise OnRegisterAssistedSetup: without the call below the app has no Guided Experience
//     Item. Guided Experience.SetupForExtensionExists raises it (it returns false: the fixtures register a codeunit, not a page).
//   - Icon: one item per app; the Icon is a Tenant Media row of its own (not the logo's Media id), Mime Type image/jpeg, Height and
//     Width of the image, Description = the app id, same length as the file. Its bytes differ from the file in exactly 3 bytes of
//     the JFIF header: byte 14 (density units) 0 -> 1, bytes 16 and 18 (low bytes of the X and Y density) 1 -> 0. This holds for
//     every logo here, the 8 x 8 one included, baseline and progressive.
//   - No error in any registration (the regression of 9111 was an error there for JPEG logos other than 8 x 8).
// Not measured: JPEG logos whose JFIF header already has density units 1 or another density, JPEG without a JFIF header (EXIF
//   only), CMYK or grayscale JPEG, EXIF orientation, PNG, GIF or BMP logos of other sizes, the Icon of a manual setup
//   (InsertManualSetup), and a second registration that modifies an existing item.
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

    // Lists the 1-based positions where A and B differ as position:byte of A/byte of B (at most 12), then the count.
    local procedure Differences(var A: Codeunit "Temp Blob"; var B: Codeunit "Temp Blob"): Text
    var
        InA: InStream;
        InB: InStream;
        ByteA: Byte;
        ByteB: Byte;
        IntA: Integer;
        IntB: Integer;
        Position: Integer;
        Count: Integer;
        Result: Text;
    begin
        if A.Length() <> B.Length() then
            exit(StrSubstNo('lengths %1 vs %2', A.Length(), B.Length()));
        A.CreateInStream(InA);
        B.CreateInStream(InB);
        while not InA.EOS() do begin
            Position += 1;
            InA.Read(ByteA);
            InB.Read(ByteB);
            if ByteA <> ByteB then begin
                Count += 1;
                IntA := ByteA;
                IntB := ByteB;
                if Count <= 12 then
                    Result += StrSubstNo('%1:%2/%3 ', Position, IntA, IntB);
            end;
        end;
        exit(Result + StrSubstNo('count %1', Count));
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
        Media: Record Media;
        TempBlob: Codeunit "Temp Blob";
        LogoBlob: Codeunit "Temp Blob";
        LogoInS: InStream;
        GuidedExperience: Codeunit "Guided Experience";
        Item: RecordRef;
        IconField: FieldRef;
        InS: InStream;
        Id: Guid;
        IconId: Guid;
    begin
        Evaluate(Id, AppIdText);
        // SetupForExtensionExists raises OnRegisterAssistedSetup (the test session's login does not), so the app's subscriber
        // calls InsertAssistedSetup, which reads the app logo (GetExtensionLogo) and imports it as the item's Icon.
        Observer.Observe('setup for extension exists (page setups only)', Format(GuidedExperience.SetupForExtensionExists(Id)));
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
        Media.SetRange(ID, App.Logo.MediaId());
        if Media.FindFirst() then begin
            Media.CalcFields(Content);
            Media.Content.CreateInStream(LogoInS);
            CopyToBlob(LogoInS, LogoBlob);
        end;
        Observer.Observe('logo media equals file', Format(Sha256Of(LogoBlob) = Sha));
        Observer.Observe('icon vs logo media, differing bytes', Differences(TempBlob, LogoBlob));
        Item.Close();
    end;

    [Test]
    procedure UsLogo_Jpeg535x534_AppG()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLogo(Observer, AppGId, ShaG);
        Observer.Expect('row found', 'Yes');
        Observer.Expect('logo has value', 'Yes');
        Observer.Expect('logo media id null', 'No');
        Observer.Expect('media row found', 'Yes');
        Observer.Expect('mime type', 'image/jpeg');
        Observer.Expect('height', '534');
        Observer.Expect('width', '535');
        Observer.Expect('content has value', 'Yes');
        Observer.Expect('length', '14191');
        Observer.Expect('equals file', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UsLogo_Jpeg16x8_AppH()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLogo(Observer, AppHId, ShaH);
        Observer.Expect('row found', 'Yes');
        Observer.Expect('logo has value', 'Yes');
        Observer.Expect('logo media id null', 'No');
        Observer.Expect('media row found', 'Yes');
        Observer.Expect('mime type', 'image/jpeg');
        Observer.Expect('height', '8');
        Observer.Expect('width', '16');
        Observer.Expect('content has value', 'Yes');
        Observer.Expect('length', '633');
        Observer.Expect('equals file', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UsLogo_Jpeg400x300_AppJ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLogo(Observer, AppJId, ShaJ);
        Observer.Expect('row found', 'Yes');
        Observer.Expect('logo has value', 'Yes');
        Observer.Expect('logo media id null', 'No');
        Observer.Expect('media row found', 'Yes');
        Observer.Expect('mime type', 'image/jpeg');
        Observer.Expect('height', '300');
        Observer.Expect('width', '400');
        Observer.Expect('content has value', 'Yes');
        Observer.Expect('length', '62851');
        Observer.Expect('equals file', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UsLogo_JpegProgressive535x534_AppK()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveLogo(Observer, AppKId, ShaK);
        Observer.Expect('row found', 'Yes');
        Observer.Expect('logo has value', 'Yes');
        Observer.Expect('logo media id null', 'No');
        Observer.Expect('media row found', 'Yes');
        Observer.Expect('mime type', 'image/jpeg');
        Observer.Expect('height', '534');
        Observer.Expect('width', '535');
        Observer.Expect('content has value', 'Yes');
        Observer.Expect('length', '9857');
        Observer.Expect('equals file', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UsLogo_GuidedExperienceIcon_Jpeg8x8_AppE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveIcon(Observer, AppEId, ShaE);
        Observer.Expect('setup for extension exists (page setups only)', 'No');
        Observer.Expect('items of the app', '1');
        Observer.Expect('item found', 'Yes');
        Observer.Expect('icon text empty', 'No');
        Observer.Expect('icon evaluates to guid', 'Yes');
        Observer.Expect('icon media id null', 'No');
        Observer.Expect('icon media id equals logo media id', 'No');
        Observer.Expect('tenant media row found', 'Yes');
        Observer.Expect('icon mime type', 'image/jpeg');
        Observer.Expect('icon height', '8');
        Observer.Expect('icon width', '8');
        Observer.Expect('icon description is the app id', 'Yes');
        Observer.Expect('icon description has the app id', 'Yes');
        Observer.Expect('icon content has value', 'Yes');
        Observer.Expect('icon length', '307');
        Observer.Expect('icon equals file', 'No');
        Observer.Expect('logo media equals file', 'Yes');
        Observer.Expect('icon vs logo media, differing bytes', '14:1/0 16:0/1 18:0/1 count 3');
        Observer.Verify();
    end;

    [Test]
    procedure UsLogo_GuidedExperienceIcon_Jpeg535x534_AppG()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveIcon(Observer, AppGId, ShaG);
        Observer.Expect('setup for extension exists (page setups only)', 'No');
        Observer.Expect('items of the app', '1');
        Observer.Expect('item found', 'Yes');
        Observer.Expect('icon text empty', 'No');
        Observer.Expect('icon evaluates to guid', 'Yes');
        Observer.Expect('icon media id null', 'No');
        Observer.Expect('icon media id equals logo media id', 'No');
        Observer.Expect('tenant media row found', 'Yes');
        Observer.Expect('icon mime type', 'image/jpeg');
        Observer.Expect('icon height', '534');
        Observer.Expect('icon width', '535');
        Observer.Expect('icon description is the app id', 'Yes');
        Observer.Expect('icon description has the app id', 'Yes');
        Observer.Expect('icon content has value', 'Yes');
        Observer.Expect('icon length', '14191');
        Observer.Expect('icon equals file', 'No');
        Observer.Expect('logo media equals file', 'Yes');
        Observer.Expect('icon vs logo media, differing bytes', '14:1/0 16:0/1 18:0/1 count 3');
        Observer.Verify();
    end;

    [Test]
    procedure UsLogo_GuidedExperienceIcon_Jpeg16x8_AppH()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveIcon(Observer, AppHId, ShaH);
        Observer.Expect('setup for extension exists (page setups only)', 'No');
        Observer.Expect('items of the app', '1');
        Observer.Expect('item found', 'Yes');
        Observer.Expect('icon text empty', 'No');
        Observer.Expect('icon evaluates to guid', 'Yes');
        Observer.Expect('icon media id null', 'No');
        Observer.Expect('icon media id equals logo media id', 'No');
        Observer.Expect('tenant media row found', 'Yes');
        Observer.Expect('icon mime type', 'image/jpeg');
        Observer.Expect('icon height', '8');
        Observer.Expect('icon width', '16');
        Observer.Expect('icon description is the app id', 'Yes');
        Observer.Expect('icon description has the app id', 'Yes');
        Observer.Expect('icon content has value', 'Yes');
        Observer.Expect('icon length', '633');
        Observer.Expect('icon equals file', 'No');
        Observer.Expect('logo media equals file', 'Yes');
        Observer.Expect('icon vs logo media, differing bytes', '14:1/0 16:0/1 18:0/1 count 3');
        Observer.Verify();
    end;

    [Test]
    procedure UsLogo_GuidedExperienceIcon_Jpeg400x300_AppJ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveIcon(Observer, AppJId, ShaJ);
        Observer.Expect('setup for extension exists (page setups only)', 'No');
        Observer.Expect('items of the app', '1');
        Observer.Expect('item found', 'Yes');
        Observer.Expect('icon text empty', 'No');
        Observer.Expect('icon evaluates to guid', 'Yes');
        Observer.Expect('icon media id null', 'No');
        Observer.Expect('icon media id equals logo media id', 'No');
        Observer.Expect('tenant media row found', 'Yes');
        Observer.Expect('icon mime type', 'image/jpeg');
        Observer.Expect('icon height', '300');
        Observer.Expect('icon width', '400');
        Observer.Expect('icon description is the app id', 'Yes');
        Observer.Expect('icon description has the app id', 'Yes');
        Observer.Expect('icon content has value', 'Yes');
        Observer.Expect('icon length', '62851');
        Observer.Expect('icon equals file', 'No');
        Observer.Expect('logo media equals file', 'Yes');
        Observer.Expect('icon vs logo media, differing bytes', '14:1/0 16:0/1 18:0/1 count 3');
        Observer.Verify();
    end;

    [Test]
    procedure UsLogo_GuidedExperienceIcon_JpegProgressive535x534_AppK()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveIcon(Observer, AppKId, ShaK);
        Observer.Expect('setup for extension exists (page setups only)', 'No');
        Observer.Expect('items of the app', '1');
        Observer.Expect('item found', 'Yes');
        Observer.Expect('icon text empty', 'No');
        Observer.Expect('icon evaluates to guid', 'Yes');
        Observer.Expect('icon media id null', 'No');
        Observer.Expect('icon media id equals logo media id', 'No');
        Observer.Expect('tenant media row found', 'Yes');
        Observer.Expect('icon mime type', 'image/jpeg');
        Observer.Expect('icon height', '534');
        Observer.Expect('icon width', '535');
        Observer.Expect('icon description is the app id', 'Yes');
        Observer.Expect('icon description has the app id', 'Yes');
        Observer.Expect('icon content has value', 'Yes');
        Observer.Expect('icon length', '9857');
        Observer.Expect('icon equals file', 'No');
        Observer.Expect('logo media equals file', 'Yes');
        Observer.Expect('icon vs logo media, differing bytes', '14:1/0 16:0/1 18:0/1 count 3');
        Observer.Verify();
    end;
}
