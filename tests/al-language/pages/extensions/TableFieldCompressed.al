// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own table 72294, codeunit 72295
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72294 "LT P123 Compr"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Plain; Blob) { Compressed = false; }
        field(3; Zipped; Blob) { Compressed = true; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72295 "LT P123 Compressed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure WriteText(var T: Record "LT P123 Compr"; FieldNo: Integer; Value: Text)
    var
        OutS: OutStream;
    begin
        if FieldNo = 2 then
            T.Plain.CreateOutStream(OutS)
        else
            T.Zipped.CreateOutStream(OutS);
        OutS.WriteText(Value);
    end;

    local procedure ReadText(var T: Record "LT P123 Compr"; FieldNo: Integer): Text
    var
        InS: InStream;
        Result: Text;
    begin
        if FieldNo = 2 then begin
            T.CalcFields(Plain);
            T.Plain.CreateInStream(InS);
        end else begin
            T.CalcFields(Zipped);
            T.Zipped.CreateInStream(InS);
        end;
        InS.ReadText(Result);
        exit(Result);
    end;

    [Test]
    procedure P123_CompressedBlobRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 Compr";
    begin
        T.DeleteAll();
        T.Init(); T.Id := 1;
        WriteText(T, 2, 'plain text value');
        WriteText(T, 3, 'zipped text value');
        T.Insert();
        Clear(T);
        T.Get(1);
        Observer.Observe('plain', ReadText(T, 2));
        Observer.Observe('zipped', ReadText(T, 3));
        T.CalcFields(Plain, Zipped);
        Observer.Observe('plain hasvalue', Format(T.Plain.HasValue()));
        Observer.Observe('zipped hasvalue', Format(T.Zipped.HasValue()));
        Observer.Observe('plain length', Format(T.Plain.Length()));
        Observer.Observe('zipped length', Format(T.Zipped.Length()));
        Observer.Expect('plain', 'plain text value');
        Observer.Expect('zipped', 'zipped text value');
        Observer.Expect('plain hasvalue', 'Yes');
        Observer.Expect('zipped hasvalue', 'Yes');
        Observer.Expect('plain length', '16');
        Observer.Expect('zipped length', '17');
        Observer.Verify();
    end;
}
