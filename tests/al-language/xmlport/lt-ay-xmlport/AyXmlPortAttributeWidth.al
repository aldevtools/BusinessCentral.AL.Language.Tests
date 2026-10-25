// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-width-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 80519, xmlports 80520-80522, codeunit 80523
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: a fieldattribute with Width compiles in a FixedText and in an Xml XmlPort. The exported text of a FixedText XmlPort whose table element has a
// fieldattribute (Width 4) and fieldelements (Width 6), values shorter and longer than the width; the exported text of an Xml XmlPort with a
// fieldattribute and a fieldelement of Width 3; and a FixedText import through the same layout (the values stored).
// BC versions: 27, 28, 29 (corpus CI)

table 80519 "LT AY Width Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Code; Code[20]) { }
        field(3; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 80520 "LT AY Width Fixed"
{
    Format = FixedText;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT AY Width Row")
            {
                XmlName = 'Row';
                fieldattribute(Code; Rw.Code) { Width = 4; }
                fieldelement(Id; Rw.Id) { Width = 6; }
                fieldelement(Name; Rw.Name) { Width = 6; }
            }
        }
    }
}

xmlport 80521 "LT AY Width Xml"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT AY Width Row")
            {
                XmlName = 'Row';
                fieldattribute(Code; Rw.Code) { Width = 3; }
                fieldelement(Name; Rw.Name) { Width = 3; }
            }
        }
    }
}

xmlport 80522 "LT AY Width Fixed Attr Only"
{
    Format = FixedText;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT AY Width Row")
            {
                XmlName = 'Row';
                fieldattribute(Code; Rw.Code) { Width = 4; }
                fieldattribute(Name; Rw.Name) { Width = 2; }
            }
        }
    }
}

codeunit 80523 "LT AY Width Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup()
    var
        R: Record "LT AY Width Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Code := 'AB';
        R.Name := 'x';
        R.Insert();
        R.Id := 22;
        R.Code := 'ABCDEFG';
        R.Name := 'longer name';
        R.Insert();
    end;

    // CR, LF and spaces made visible
    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        C: Char;
        All: Text;
        Cr: Char;
        Lf: Char;
    begin
        Cr := 13;
        Lf := 10;
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.Read(C);
            case C of
                Cr:
                    All += '\r';
                Lf:
                    All += '\n';
                ' ':
                    All += '_';
                else
                    All += Format(C);
            end;
        end;
        exit(All.Replace('<?xml version="1.0" encoding="UTF-8" standalone="no"?>', '<?decl?>'));
    end;

    // FixedText ports write one byte per character here (the default TextEncoding); InStream.Read into a Char takes two bytes, so read Bytes.
    local procedure ReadBytes(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        B: Byte;
        C: Char;
        All: Text;
    begin
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            case B of
                13:
                    All += '\r';
                10:
                    All += '\n';
                32:
                    All += '_';
                else begin
                    C := B;
                    All += Format(C);
                end;
            end;
        end;
        exit(All);
    end;

    [Test]
    procedure Width_FixedText_FieldAttribute_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Xp: XmlPort "LT AY Width Fixed";
        OutS: OutStream;
    begin
        Setup();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Observer.Observe('ok', Format(Xp.Export()));
        Observer.Observe('text', ReadBytes(TempBlob));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('text', 'AB__1_____x_____\r\nABCD22____longer');
        Observer.Verify();
    end;

    [Test]
    procedure Width_FixedText_AttributesOnly_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Xp: XmlPort "LT AY Width Fixed Attr Only";
        OutS: OutStream;
    begin
        Setup();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Observer.Observe('ok', Format(Xp.Export()));
        Observer.Observe('text', ReadBytes(TempBlob));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('text', 'AB__x_\r\nABCDlo');
        Observer.Verify();
    end;

    [Test]
    procedure Width_Xml_FieldAttribute_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Xp: XmlPort "LT AY Width Xml";
        OutS: OutStream;
    begin
        Setup();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Observer.Observe('ok', Format(Xp.Export()));
        Observer.Observe('text', ReadAll(TempBlob));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('text', '﻿<?xml_version="1.0"_encoding="UTF-16"_standalone="no"?>\r\n<Root>\r\n__<Row_Code="AB">\r\n____<Name>x</Name>\r\n__</Row>\r\n__<Row_Code="ABCDEFG">\r\n____<Name>longer_name</Name>\r\n__</Row>\r\n</Root>');
        Observer.Verify();
    end;

    local procedure DoImport(var Observer: Codeunit "Probe Observer")
    var
        R: Record "LT AY Width Row";
        TempBlob: Codeunit "Temp Blob";
        Xp: XmlPort "LT AY Width Fixed";
        OutS: OutStream;
        InS: InStream;
        All: Text;
    begin
        R.DeleteAll();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('WXYZ000007abcdef');
        OutS.WriteText();
        OutS.WriteText('Q   8     g');
        OutS.WriteText();
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        // statement form: the value-consuming form is refused while the setup rows are uncommitted (TestXmlPortImportWriteTx.al)
        Xp.Import();
        if R.FindSet() then
            repeat
                All += Format(R.Id) + '|' + R.Code + '|' + R.Name + ';';
            until R.Next() = 0;
        Observer.Observe('rows', All);
        Error('FINISHED');
    end;

    [Test]
    procedure Width_FixedText_FieldAttribute_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer);
        Observer.ObserveError('end');
        Observer.Expect('rows', '7|WXYZ|abcdef;8|Q|g;');
        Observer.Expect('end|text', 'FINISHED');
        Observer.Expect('end|code', 'Dialog');
        Observer.Verify();
    end;

    // Writer SL (2026-10-25): ReadAll above reads the UTF-16 export with InStream.Read(Char). These pin Read(Char) itself on known bytes:
    // set 1 = UTF-16 LE with a BOM and an odd last byte (FF FE 41 00 E9 00 0D 00 0A 00 42), set 2 = UTF-8 bytes (41 C3 A9 42 0A 43),
    // for an InStream without and with each TextEncoding. Each read shows its return value and the character code it gave.
    local procedure WriteBytes(var TempBlob: Codeunit "Temp Blob"; SetNo: Integer)
    var
        OutS: OutStream;
        Bytes: List of [Integer];
        V: Integer;
        B: Byte;
    begin
        if SetNo = 1 then
            Bytes.AddRange(255, 254, 65, 0, 233, 0, 13, 0, 10, 0, 66)
        else
            Bytes.AddRange(65, 195, 169, 66, 10, 67);
        TempBlob.CreateOutStream(OutS);
        foreach V in Bytes do begin
            B := V;
            OutS.Write(B);
        end;
    end;

    local procedure ReadChars(var InS: InStream): Text
    var
        C: Char;
        N: Integer;
        I: Integer;
        Result: Text;
        Code: Integer;
    begin
        while (not InS.EOS()) and (I < 12) do begin
            I += 1;
            C := 0;
            N := InS.Read(C);
            Code := C;
            Result += Format(N) + ':' + Format(Code) + ';';
        end;
        exit(Result + 'eos=' + Format(InS.EOS()));
    end;

    [Test]
    procedure ReadChar_Utf16Le_Default()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        WriteBytes(TempBlob, 1);
        TempBlob.CreateInStream(InS);
        Observer.Observe('reads', ReadChars(InS));
        Observer.Expect('reads', '1:160;1:254;1:65;1:0;1:210;1:0;1:13;1:0;1:10;1:0;1:66;eos=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadChar_Utf8Bytes_Default()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        WriteBytes(TempBlob, 2);
        TempBlob.CreateInStream(InS);
        Observer.Observe('reads', ReadChars(InS));
        Observer.Expect('reads', '1:65;1:8220;1:20;1:66;1:10;1:67;eos=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadChar_Utf16Le_Utf8()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        WriteBytes(TempBlob, 1);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('reads', ReadChars(InS));
        Observer.Expect('reads', '2:65279;2:65;2:233;2:13;2:10;1:0;eos=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadChar_Utf8Bytes_Utf8()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        WriteBytes(TempBlob, 2);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('reads', ReadChars(InS));
        Observer.Expect('reads', '2:49985;2:17065;2:17162;eos=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadChar_Utf16Le_Utf16()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        WriteBytes(TempBlob, 1);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('reads', ReadChars(InS));
        Observer.Expect('reads', '2:65279;2:65;2:233;2:13;2:10;1:0;eos=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadChar_Utf8Bytes_Utf16()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        WriteBytes(TempBlob, 2);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('reads', ReadChars(InS));
        Observer.Expect('reads', '2:49985;2:17065;2:17162;eos=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadChar_Utf16Le_Windows()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        WriteBytes(TempBlob, 1);
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        Observer.Observe('reads', ReadChars(InS));
        Observer.Expect('reads', '1:255;1:254;1:65;1:0;1:233;1:0;1:13;1:0;1:10;1:0;1:66;eos=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadChar_Utf8Bytes_Windows()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        WriteBytes(TempBlob, 2);
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        Observer.Observe('reads', ReadChars(InS));
        Observer.Expect('reads', '1:65;1:195;1:169;1:66;1:10;1:67;eos=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadChar_Utf16Le_MsDos()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        WriteBytes(TempBlob, 1);
        TempBlob.CreateInStream(InS, TextEncoding::MSDos);
        Observer.Observe('reads', ReadChars(InS));
        Observer.Expect('reads', '1:160;1:254;1:65;1:0;1:210;1:0;1:13;1:0;1:10;1:0;1:66;eos=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadChar_Utf8Bytes_MsDos()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        WriteBytes(TempBlob, 2);
        TempBlob.CreateInStream(InS, TextEncoding::MSDos);
        Observer.Observe('reads', ReadChars(InS));
        Observer.Expect('reads', '1:65;1:8220;1:20;1:66;1:10;1:67;eos=Yes');
        Observer.Verify();
    end;
}
