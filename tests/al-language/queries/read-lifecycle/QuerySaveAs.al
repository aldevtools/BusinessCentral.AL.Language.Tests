// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-saveasxml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own table 71921, query 71922
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the raw bytes SaveAsXml, SaveAsJson and SaveAsCsv write for Integer, Text, Decimal, Date and Boolean columns: length, the first three bytes (a byte order mark or not), number of CR and LF bytes, the text itself in pieces of 700 characters.
// BC versions: 29 (27 and 28 by CI)

table 71921 "LT P160 QRow"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Amt; Decimal) { }
        field(4; D; Date) { }
        field(5; Flag; Boolean) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 71922 "LT P160 QSave"
{
    QueryType = Normal;
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Rows; "LT P160 QRow")
        {
            column(Id; Id) { }
            column(Name; Name) { }
            column(Amt; Amt) { }
            column(D; D) { }
            column(Flag; Flag) { }
        }
    }
}

codeunit 71923 "LT P160 Query SaveAs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P160 QRow";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'a,b "q" <x>&y';
        Row.Amt := 12.5;
        Row.D := DMY2Date(5, 3, 2024);
        Row.Flag := true;
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Name := '';
        Row.Amt := 0;
        Row.D := 0D;
        Row.Flag := false;
        Row.Insert();
    end;

    local procedure ObserveStream(var Observer: Codeunit "Probe Observer"; var TempBlob: Codeunit "Temp Blob"; Tag: Text)
    var
        InS: InStream;
        Raw: Text;
        Len: Integer;
        i: Integer;
        Crs: Integer;
        Lfs: Integer;
        Pieces: Integer;
        B: Byte;
        First3: Text;
    begin
        Len := TempBlob.Length();
        Observer.Observe(Tag + ' length', Format(Len));
        TempBlob.CreateInStream(InS);
        for i := 1 to 3 do
            if not InS.EOS() then begin
                InS.Read(B);
                First3 += Format(B) + ' ';
            end;
        Observer.Observe(Tag + ' first bytes', First3);
        if Len = 0 then
            exit;
        TempBlob.CreateInStream(InS);
        InS.Read(Raw, Len);
        for i := 1 to StrLen(Raw) do begin
            if Raw[i] = 13 then
                Crs += 1;
            if Raw[i] = 10 then
                Lfs += 1;
        end;
        Observer.Observe(Tag + ' CR count', Format(Crs));
        Observer.Observe(Tag + ' LF count', Format(Lfs));
        i := 1;
        while (i <= StrLen(Raw)) and (Pieces < 10) do begin
            Pieces += 1;
            Observer.Observe(Tag + ' text ' + Format(Pieces), CopyStr(Raw, i, 700));
            i += 700;
        end;
    end;

    [Test]
    procedure SaveAsXml_RawBytes()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P160 QSave";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Ok := Q.SaveAsXml(OutS);
        Observer.Observe('ok', Format(Ok));
        ObserveStream(Observer, TempBlob, 'xml');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('xml length', '1330');
        Observer.Expect('xml first bytes', 'Ù ‹  ');
        Observer.Expect('xml CR count', '34');
        Observer.Expect('xml LF count', '34');
        Observer.Expect('xml text 2', 'urs="0" />\r\n                <xs:element name="D" msdata:DateTimeMode="Local" type="xs:dateTime" minOccurs="0" />\r\n                <xs:element name="Flag" type="xs:boolean" minOccurs="0" />\r\n              </xs:sequence>\r\n            </xs:complexType>\r\n          </xs:element>\r\n        </xs:choice>\r\n      </xs:complexType>\r\n    </xs:element>\r\n  </xs:schema>\r\n  <Result>\r\n    <Id>1</Id>\r\n    <Name>a,b "q" &lt;x&gt;&amp;y</Name>\r\n    <Amt>12.5</Amt>\r\n    <D>2024-03-05T00:00:00+00:00</D>\r\n    <Flag>true</Flag>\r\n  </Result>\r\n  <Result>\r\n    <Id>2</Id>\r\n    <Name />\r\n    <Amt>0</Amt>\r\n    <Flag>false</Flag>\r\n  </Result>\r\n</DataSet>');
        Observer.Ignore('xml text 1'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsJson_RawBytes()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P160 QSave";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Ok := Q.SaveAsJson(OutS);
        Observer.Observe('ok', Format(Ok));
        ObserveStream(Observer, TempBlob, 'json');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('json length', '125');
        Observer.Expect('json first bytes', '[ { " ');
        Observer.Expect('json CR count', '0');
        Observer.Expect('json LF count', '0');
        Observer.Expect('json text 1', '[{"Id":1,"Name":"a,b \"q\" <x>&y","Amt":12.5,"D":"2024-03-05T00:00:00Z","Flag":true},{"Id":2,"Name":"","Amt":0,"Flag":false}]');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_NoRows_RawBytes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P160 QRow";
        Q: Query "LT P160 QSave";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('xml ok', Format(Q.SaveAsXml(OutS)));
        ObserveStream(Observer, TempBlob, 'xml');
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('json ok', Format(Q.SaveAsJson(OutS)));
        ObserveStream(Observer, TempBlob, 'json');
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('csv ok', Format(Q.SaveAsCsv(OutS)));
        ObserveStream(Observer, TempBlob, 'csv');
        Observer.Expect('xml ok', 'Yes');
        Observer.Expect('xml length', '1068');
        Observer.Expect('xml first bytes', 'Ù ‹  ');
        Observer.Expect('xml CR count', '21');
        Observer.Expect('xml LF count', '21');
        Observer.Expect('xml text 2', 'urs="0" />\r\n                <xs:element name="D" msdata:DateTimeMode="Local" type="xs:dateTime" minOccurs="0" />\r\n                <xs:element name="Flag" type="xs:boolean" minOccurs="0" />\r\n              </xs:sequence>\r\n            </xs:complexType>\r\n          </xs:element>\r\n        </xs:choice>\r\n      </xs:complexType>\r\n    </xs:element>\r\n  </xs:schema>\r\n</DataSet>');
        Observer.Expect('json ok', 'Yes');
        Observer.Expect('json length', '2');
        Observer.Expect('json first bytes', '[ ] ');
        Observer.Expect('json CR count', '0');
        Observer.Expect('json LF count', '0');
        Observer.Expect('json text 1', '[]');
        Observer.Expect('csv ok', 'Yes');
        Observer.Expect('csv length', '20');
        Observer.Expect('csv first bytes', 'I d , ');
        Observer.Expect('csv CR count', '1');
        Observer.Expect('csv LF count', '1');
        Observer.Expect('csv text 1', 'Id,Name,Amt,D,Flag\r\n');
        Observer.Ignore('xml text 1'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;
}
