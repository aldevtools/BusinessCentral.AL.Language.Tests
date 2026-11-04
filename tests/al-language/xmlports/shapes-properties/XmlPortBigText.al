// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-texttype-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); log 74962, xmlports 74963 and 74964, test codeunit 74965
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a text element with TextType = BigText on Export and Import: the exported XML text of short, empty, long (5000 characters) and special-character values, the BigText length after import, Format of the BigText, and whether a value above 2048 and 4096 characters survives the round trip.
// BC versions: 29 (27 and 28 by CI)

codeunit 74962 "LT XB Log"
{
    SingleInstance = true;

    var
        Input: Text;
        Entries: Text;

    procedure SetInput(NewInput: Text)
    begin
        Input := NewInput;
    end;

    procedure GetInput(): Text
    begin
        exit(Input);
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

xmlport 74963 "LT XB Export"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Big)
            {
                TextType = BigText;
            }
            textelement(Small) { }
        }
    }

    trigger OnPreXmlPort()
    begin
        Big.AddText(L.GetInput());
        Small := 'tail';
        L.Add('pre length=' + Format(Big.Length()));
    end;

    var
        L: Codeunit "LT XB Log";
}

xmlport 74964 "LT XB Import"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Big)
            {
                TextType = BigText;
            }
            textelement(Small) { MinOccurs = Zero; }
        }
    }

    trigger OnPostXmlPort()
    var
        Head: Text;
    begin
        Big.GetSubText(Head, 1, 12);
        L.Add('length=' + Format(Big.Length()));
        L.Add('head=' + Head);
        L.Add('format_length=' + Format(StrLen(Format(Big))));
        L.Add('small=' + Small);
    end;

    var
        L: Codeunit "LT XB Log";
}

codeunit 74965 "LT XmlPort BigText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure LongText(Length: Integer): Text
    var
        Result: TextBuilder;
        i: Integer;
    begin
        for i := 1 to Length do
            Result.Append(Format(i mod 10));
        exit(Result.ToText());
    end;

    local procedure ExportText(Input: Text): Text
    var
        L: Codeunit "LT XB Log";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
        Line: Text;
    begin
        L.SetInput(Input);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xmlport.Export(Xmlport::"LT XB Export", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Txt += Line;
        end;
        exit(Txt);
    end;

    local procedure ImportText(Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"LT XB Import", InS);
    end;

    [Test]
    procedure Export_BigText_ShortEmptyAndSpecial()
    var
        L: Codeunit "LT XB Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        Observer.Observe('short', ExportText('hello'));
        Observer.Observe('empty', ExportText(''));
        Observer.Observe('special', ExportText('a<b>&"c''d'));
        Observer.Observe('unicode', ExportText('äöü€'));
        Observer.Observe('trace', L.Take());
        Observer.Expect('short', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Big>hello</Big>  <Small>tail</Small></Root>');
        Observer.Expect('empty', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Big />  <Small>tail</Small></Root>');
        Observer.Expect('special', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Big>a&lt;b&gt;&amp;"c''d</Big>  <Small>tail</Small></Root>');
        Observer.Expect('unicode', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Big>äöü€</Big>  <Small>tail</Small></Root>');
        Observer.Expect('trace', 'pre length=5;pre length=0;pre length=9;pre length=4;');
        Observer.Verify();
    end;

    [Test]
    procedure Export_BigText_LongValue_Length()
    var
        L: Codeunit "LT XB Log";
        Xml: Text;
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        Xml := ExportText(LongText(5000));
        Observer.Observe('xml_length', Format(StrLen(Xml)));
        Observer.Observe('contains_tail', Format(Xml.Contains('<Small>tail</Small>')));
        Observer.Observe('contains_all', Format(Xml.Contains('<Big>' + LongText(5000) + '</Big>')));
        Observer.Observe('trace', L.Take());
        Observer.Expect('xml_length', '5101');
        Observer.Expect('contains_tail', 'Yes');
        Observer.Expect('contains_all', 'Yes');
        Observer.Expect('trace', 'pre length=5000;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_BigText_ShortAndEmpty()
    var
        L: Codeunit "LT XB Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        ImportText('<Root><Big>hello</Big><Small>s</Small></Root>');
        Observer.Observe('short', L.Take());
        ImportText('<Root><Big></Big><Small>s</Small></Root>');
        Observer.Observe('empty', L.Take());
        ImportText('<Root><Big>a&lt;b&amp;c</Big></Root>');
        Observer.Observe('escaped', L.Take());
        Observer.Expect('short', 'length=5;head=hello;format_length=5;small=s;');
        Observer.Expect('empty', 'length=0;head=;format_length=0;small=s;');
        Observer.Expect('escaped', 'length=5;head=a<b&c;format_length=5;small=;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_BigText_LongValues_Length()
    var
        L: Codeunit "LT XB Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        ImportText('<Root><Big>' + LongText(2048) + '</Big></Root>');
        Observer.Observe('len_2048', L.Take());
        ImportText('<Root><Big>' + LongText(2049) + '</Big></Root>');
        Observer.Observe('len_2049', L.Take());
        ImportText('<Root><Big>' + LongText(4097) + '</Big></Root>');
        Observer.Observe('len_4097', L.Take());
        ImportText('<Root><Big>' + LongText(50000) + '</Big></Root>');
        Observer.Observe('len_50000', L.Take());
        Observer.Expect('len_2048', 'length=2048;head=123456789012;format_length=2048;small=;');
        Observer.Expect('len_2049', 'length=2049;head=123456789012;format_length=2049;small=;');
        Observer.Expect('len_4097', 'length=4097;head=123456789012;format_length=4097;small=;');
        Observer.Expect('len_50000', 'length=50000;head=123456789012;format_length=50000;small=;');
        Observer.Verify();
    end;

    [Test]
    procedure RoundTrip_BigText_LongValue()
    var
        L: Codeunit "LT XB Log";
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        L.Take();
        Xml := ExportText(LongText(6000));
        L.Take();
        ImportText(Xml);
        Observer.Observe('imported', L.Take());
        Observer.Expect('imported', 'length=6000;head=123456789012;format_length=6000;small=tail;');
        Observer.Verify();
    end;
}
