// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-data-type
// Scope: in-scope
// Fixtures used: P94Fixtures.al (tables 73057-73059, xmlports 73060-73061, 73067, helper 73071), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Xmlport.TextEncoding get and set on an instance and in OnPreXmlPort, effect on the bytes of a variable text export
// BC versions: 29 (27 and 28 by CI)

codeunit 73074 "LT P94 Xp Encoding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P94 Helper";

    local procedure ExportLen(var Xp: XmlPort "LT P94 Csv Plain"; var Row: Record "LT P94 Blob" temporary): Integer
    var
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Row.CalcFields(Data);
        exit(Row.Data.Length());
    end;

    [Test]
    procedure Getter_Defaults()
    var
        Plain: XmlPort "LT P94 Csv Plain";
        Declared: XmlPort "LT P94 Csv Declared";
    begin
        Observer.Observe('plain', Format(Plain.TextEncoding()));
        Observer.Observe('declared', Format(Declared.TextEncoding()));
        Observer.Expect('plain', 'MSDos');
        Observer.Expect('declared', 'UTF8');
        Observer.Verify();
    end;

    [Test]
    procedure Setter_ReadBack()
    var
        Xp: XmlPort "LT P94 Csv Plain";
    begin
        Xp.TextEncoding(TextEncoding::UTF16);
        Observer.Observe('utf16', Format(Xp.TextEncoding()));
        Xp.TextEncoding(TextEncoding::Windows);
        Observer.Observe('windows', Format(Xp.TextEncoding()));
        Xp.TextEncoding(TextEncoding::MSDos);
        Observer.Observe('msdos', Format(Xp.TextEncoding()));
        Xp.TextEncoding(TextEncoding::UTF8);
        Observer.Observe('utf8', Format(Xp.TextEncoding()));
        Observer.Expect('utf16', 'UTF16');
        Observer.Expect('windows', 'Windows');
        Observer.Expect('msdos', 'MSDos');
        Observer.Expect('utf8', 'UTF8');
        Observer.Verify();
    end;

    [Test]
    procedure Export_AsciiLengthPerEncoding()
    var
        Xp1: XmlPort "LT P94 Csv Plain";
        Xp2: XmlPort "LT P94 Csv Plain";
        Xp3: XmlPort "LT P94 Csv Plain";
        Xp4: XmlPort "LT P94 Csv Plain";
        Row1: Record "LT P94 Blob" temporary;
        Row2: Record "LT P94 Blob" temporary;
        Row3: Record "LT P94 Blob" temporary;
        Row4: Record "LT P94 Blob" temporary;
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp1.TextEncoding(TextEncoding::UTF8);
        Observer.Observe('utf8Len', Format(ExportLen(Xp1, Row1)));
        Xp2.TextEncoding(TextEncoding::UTF16);
        Observer.Observe('utf16Len', Format(ExportLen(Xp2, Row2)));
        Xp3.TextEncoding(TextEncoding::Windows);
        Observer.Observe('windowsLen', Format(ExportLen(Xp3, Row3)));
        Xp4.TextEncoding(TextEncoding::MSDos);
        Observer.Observe('msdosLen', Format(ExportLen(Xp4, Row4)));
        Observer.Observe('utf8Text', Helper.ReadBlob(Row1, TextEncoding::UTF8));
        Observer.Observe('utf16Text', Helper.ReadBlob(Row2, TextEncoding::UTF16));
        Observer.Observe('windowsText', Helper.ReadBlob(Row3, TextEncoding::Windows));
        Observer.Observe('msdosText', Helper.ReadBlob(Row4, TextEncoding::MSDos));
        Observer.Expect('utf8Len', '0');
        Observer.Expect('utf16Len', '0');
        Observer.Expect('windowsLen', '0');
        Observer.Expect('msdosLen', '0');
        Observer.Expect('utf8Text', '');
        Observer.Expect('utf16Text', '');
        Observer.Expect('windowsText', '');
        Observer.Expect('msdosText', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_NonAsciiRoundTrip()
    var
        Xp1: XmlPort "LT P94 Csv Plain";
        Xp2: XmlPort "LT P94 Csv Plain";
        Xp3: XmlPort "LT P94 Csv Plain";
        Xp4: XmlPort "LT P94 Csv Plain";
        Row1: Record "LT P94 Blob" temporary;
        Row2: Record "LT P94 Blob" temporary;
        Row3: Record "LT P94 Blob" temporary;
        Row4: Record "LT P94 Blob" temporary;
        Name: Text;
    begin
        Helper.Wipe();
        Name := 'a' + Helper.Chr(228) + Helper.Chr(246) + 'z';
        Helper.AddItem(1, Name, 1);
        Xp1.TextEncoding(TextEncoding::UTF8);
        Observer.Observe('utf8Len', Format(ExportLen(Xp1, Row1)));
        Xp2.TextEncoding(TextEncoding::UTF16);
        Observer.Observe('utf16Len', Format(ExportLen(Xp2, Row2)));
        Xp3.TextEncoding(TextEncoding::Windows);
        Observer.Observe('windowsLen', Format(ExportLen(Xp3, Row3)));
        Xp4.TextEncoding(TextEncoding::MSDos);
        Observer.Observe('msdosLen', Format(ExportLen(Xp4, Row4)));
        Observer.Observe('utf8Same', Format(Helper.ReadBlob(Row1, TextEncoding::UTF8).Contains(Name)));
        Observer.Observe('utf16Same', Format(Helper.ReadBlob(Row2, TextEncoding::UTF16).Contains(Name)));
        Observer.Observe('windowsSame', Format(Helper.ReadBlob(Row3, TextEncoding::Windows).Contains(Name)));
        Observer.Observe('msdosSame', Format(Helper.ReadBlob(Row4, TextEncoding::MSDos).Contains(Name)));
        Observer.Observe('utf8AsWindowsSame', Format(Helper.ReadBlob(Row1, TextEncoding::Windows).Contains(Name)));
        Observer.Expect('utf8Len', '0');
        Observer.Expect('utf16Len', '0');
        Observer.Expect('windowsLen', '0');
        Observer.Expect('msdosLen', '0');
        Observer.Expect('utf8Same', 'No');
        Observer.Expect('utf16Same', 'No');
        Observer.Expect('windowsSame', 'No');
        Observer.Expect('msdosSame', 'No');
        Observer.Expect('utf8AsWindowsSame', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Export_EuroSign()
    var
        Xp1: XmlPort "LT P94 Csv Plain";
        Xp2: XmlPort "LT P94 Csv Plain";
        Xp3: XmlPort "LT P94 Csv Plain";
        Row1: Record "LT P94 Blob" temporary;
        Row2: Record "LT P94 Blob" temporary;
        Row3: Record "LT P94 Blob" temporary;
        Name: Text;
    begin
        Helper.Wipe();
        Name := 'e' + Helper.Chr(8364);
        Helper.AddItem(1, Name, 1);
        Xp1.TextEncoding(TextEncoding::UTF8);
        Observer.Observe('utf8Len', Format(ExportLen(Xp1, Row1)));
        Xp2.TextEncoding(TextEncoding::Windows);
        Observer.Observe('windowsLen', Format(ExportLen(Xp2, Row2)));
        Xp3.TextEncoding(TextEncoding::MSDos);
        Observer.Observe('msdosLen', Format(ExportLen(Xp3, Row3)));
        Observer.Observe('utf8Same', Format(Helper.ReadBlob(Row1, TextEncoding::UTF8).Contains(Name)));
        Observer.Observe('windowsSame', Format(Helper.ReadBlob(Row2, TextEncoding::Windows).Contains(Name)));
        Observer.Observe('msdosSame', Format(Helper.ReadBlob(Row3, TextEncoding::MSDos).Contains(Name)));
        Observer.Expect('utf8Len', '0');
        Observer.Expect('windowsLen', '0');
        Observer.Expect('msdosLen', '0');
        Observer.Expect('utf8Same', 'No');
        Observer.Expect('windowsSame', 'No');
        Observer.Expect('msdosSame', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Export_DeclaredUtf8_ThenOverrideUtf16()
    var
        Plain: XmlPort "LT P94 Csv Declared";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
        LenUtf8: Integer;
        LenUtf16: Integer;
    begin
        Helper.Wipe();
        Helper.Seed();
        Row.Data.CreateOutStream(OutS);
        Plain.SetDestination(OutS);
        Plain.Export();
        Row.CalcFields(Data);
        LenUtf8 := Row.Data.Length();
        Clear(Plain);
        Plain.TextEncoding(TextEncoding::UTF16);
        Clear(Row);
        Row.Data.CreateOutStream(OutS);
        Plain.SetDestination(OutS);
        Plain.Export();
        Row.CalcFields(Data);
        LenUtf16 := Row.Data.Length();
        Observer.Observe('utf8Len', Format(LenUtf8));
        Observer.Observe('utf16Len', Format(LenUtf16));
        Observer.Observe('utf16Larger', Format(LenUtf16 > LenUtf8));
        Observer.Expect('utf8Len', '0');
        Observer.Expect('utf16Len', '0');
        Observer.Expect('utf16Larger', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure InTrigger_SetEncoding()
    var
        Xp: XmlPort "LT P94 Csv Props Trig";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.SetMode(4);
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Row.CalcFields(Data);
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('len', Format(Row.Data.Length()));
        Observer.Observe('utf8Read', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Observe('utf16Read', Helper.ReadBlob(Row, TextEncoding::UTF16));
        Observer.Expect('log', 'delim=[~];sep=[|];rec=[\n];table=[];enc=UTF8;after=[||~|\n|UTF16]');
        Observer.Expect('len', '0');
        Observer.Expect('utf8Read', '');
        Observer.Expect('utf16Read', '');
        Observer.Verify();
    end;
}
