// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope. A Variant that holds the value of a Media field, empty and imported.
// Fixtures used: Probe Observer (69160) and ALT Media (60980) from the AL Language Coverage Tests app; self-contained codeunit 67378
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: IsGuid and Format (Variant has no IsMedia method: AL0132) of a Variant assigned from Rec.Picture, for an empty field and for an imported one. The imported value is a media id (a new Guid on every
//   run), so only relations to it are asserted: Format(Variant) = Format(Rec.Picture.MediaId), its length, and the answers of the Is... methods.
//   Corpus issue 576 item 5.
// BC versions: 27, 28, 29

codeunit 67378 "LT VM Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;

    local procedure Describe(Name: Text; V: Variant; var Rec: Record "ALT Media"; var Observer: Codeunit "Probe Observer")
    var
        Text1: Text;
    begin
        Text1 := Format(V);
        Observer.Observe(Name + '_isGuid', Format(V.IsGuid()));
        Observer.Observe(Name + '_isCode', Format(V.IsCode()));
        Observer.Observe(Name + '_isBoolean', Format(V.IsBoolean()));
        Observer.Observe(Name + '_isText', Format(V.IsText()));
        Observer.Observe(Name + '_isInteger', Format(V.IsInteger()));
        Observer.Observe(Name + '_isRecord', Format(V.IsRecord()));
        Observer.Observe(Name + '_formatLength', Format(StrLen(Text1)));
        Observer.Observe(Name + '_formatEqualsMediaId', Format(Text1 = Format(Rec.Picture.MediaId)));
        Observer.Observe(Name + '_hasValue', Format(Rec.Picture.HasValue));
    end;

    [Test]
    procedure Variant_HoldingEmptyMediaField()
    var
        Rec: Record "ALT Media";
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        Rec.Init();
        Rec.Code := 'VM1';
        Rec.Insert();
        V := Rec.Picture;
        Describe('empty', V, Rec, Observer);
        Observer.Expect('empty_isGuid', 'No');
        Observer.Expect('empty_isCode', 'No');
        Observer.Expect('empty_isBoolean', 'No');
        Observer.Expect('empty_isText', 'No');
        Observer.Expect('empty_isInteger', 'No');
        Observer.Expect('empty_isRecord', 'No');
        Observer.Expect('empty_formatLength', '38');
        Observer.Expect('empty_formatEqualsMediaId', 'Yes');
        Observer.Expect('empty_hasValue', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_HoldingImportedMediaField()
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
        InStr: InStream;
        OutStr: OutStream;
        V: Variant;
    begin
        Rec.Init();
        Rec.Code := 'VM2';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(ValidPngBase64, OutStr);
        TempBlob.CreateInStream(InStr);
        Rec.Picture.ImportStream(InStr, 'vm');
        Rec.Modify();
        V := Rec.Picture;
        Describe('imported', V, Rec, Observer);
        Observer.Expect('imported_isGuid', 'No');
        Observer.Expect('imported_isCode', 'No');
        Observer.Expect('imported_isBoolean', 'No');
        Observer.Expect('imported_isText', 'No');
        Observer.Expect('imported_isInteger', 'No');
        Observer.Expect('imported_isRecord', 'No');
        Observer.Expect('imported_formatLength', '38');
        Observer.Expect('imported_formatEqualsMediaId', 'Yes');
        Observer.Expect('imported_hasValue', 'Yes');
        Observer.Verify();
    end;
}
