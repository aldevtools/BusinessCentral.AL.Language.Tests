// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-saveasxml-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables and helper of P105Fix.al; query 72275 of P105QryXml.al
// Facts: the full text Query.SaveAsXml writes for a query with Integer, Text[30] and Decimal columns (the same six calls as P105QryXml.al, whose content is not asserted):
// default, SetRange, empty result, TopNumberOfRows(1), the static form, a SetFilter on the Text column. Lines are read with InStream.ReadText (no encoding) and joined with '|'.
// BC versions: 27, 28, 29

codeunit 89241 "LT SM QryXml Content"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P105 Helper";

    local procedure Fresh(var Store: Record "LT P105 Store"; var OutStr: OutStream)
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
    end;

    // The stream starts with the UTF-8 byte order mark, which ReadText of a stream without encoding reads as three characters: their codes are
    // observed apart, the rest is the text.
    local procedure ObserveContent(var Observer: Codeunit "Probe Observer"; Content: Text)
    var
        i: Integer;
        Code: Integer;
        Codes: Text;
    begin
        for i := 1 to 3 do begin
            Code := Content[i];
            Codes += Format(Code) + ',';
        end;
        Observer.Observe('first three char codes', Codes);
        Observer.Observe('content', CopyStr(Content, 4));
    end;

    [Test]
    procedure SaveAsXml_Default_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Observer.Observe('ok', Format(Qry.SaveAsXml(OutStr)));
        Store.Modify();
        ObserveContent(Observer, Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('first three char codes', '217,8249,143,');
        Observer.Expect('content', '<?xml version="1.0" standalone="yes"?>|<DataSet>|  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">|    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:MainDataTable="Result" msdata:Locale="">|      <xs:complexType>|        <xs:choice minOccurs="0" maxOccurs="unbounded">|          <xs:element name="Result" msdata:Locale="">|            <xs:complexType>|              <xs:sequence>|                <xs:element name="Id" type="xs:int" minOccurs="0" />|                <xs:element name="Grp" type="xs:int" minOccurs="0" />|                <xs:element name="Name" type="xs:string" minOccurs="0" />|                <xs:element name="Amount" type="xs:decimal" minOccurs="0" />|              </xs:sequence>|            </xs:complexType>|          </xs:element>|        </xs:choice>|      </xs:complexType>|    </xs:element>|  </xs:schema>|  <Result>|    <Id>1</Id>|    <Grp>1</Grp>|    <Name>one</Name>|    <Amount>10.5</Amount>|  </Result>|  <Result>|    <Id>2</Id>|    <Grp>1</Grp>|    <Name>two</Name>|    <Amount>20</Amount>|  </Result>|  <Result>|    <Id>3</Id>|    <Grp>2</Grp>|    <Name>three</Name>|    <Amount>30.25</Amount>|  </Result>|  <Result>|    <Id>4</Id>|    <Grp>2</Grp>|    <Name>four</Name>|    <Amount>-5</Amount>|  </Result>|</DataSet>|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsXml_SetRange_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Qry.SetRange(Grp, 2);
        Observer.Observe('ok', Format(Qry.SaveAsXml(OutStr)));
        Store.Modify();
        ObserveContent(Observer, Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('first three char codes', '217,8249,143,');
        Observer.Expect('content', '<?xml version="1.0" standalone="yes"?>|<DataSet>|  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">|    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:MainDataTable="Result" msdata:Locale="">|      <xs:complexType>|        <xs:choice minOccurs="0" maxOccurs="unbounded">|          <xs:element name="Result" msdata:Locale="">|            <xs:complexType>|              <xs:sequence>|                <xs:element name="Id" type="xs:int" minOccurs="0" />|                <xs:element name="Grp" type="xs:int" minOccurs="0" />|                <xs:element name="Name" type="xs:string" minOccurs="0" />|                <xs:element name="Amount" type="xs:decimal" minOccurs="0" />|              </xs:sequence>|            </xs:complexType>|          </xs:element>|        </xs:choice>|      </xs:complexType>|    </xs:element>|  </xs:schema>|  <Result>|    <Id>3</Id>|    <Grp>2</Grp>|    <Name>three</Name>|    <Amount>30.25</Amount>|  </Result>|  <Result>|    <Id>4</Id>|    <Grp>2</Grp>|    <Name>four</Name>|    <Amount>-5</Amount>|  </Result>|</DataSet>|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsXml_EmptyResult_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Qry.SetRange(Grp, 99);
        Observer.Observe('ok', Format(Qry.SaveAsXml(OutStr)));
        Store.Modify();
        ObserveContent(Observer, Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('first three char codes', '217,8249,143,');
        Observer.Expect('content', '<?xml version="1.0" standalone="yes"?>|<DataSet>|  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">|    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:MainDataTable="Result" msdata:Locale="">|      <xs:complexType>|        <xs:choice minOccurs="0" maxOccurs="unbounded">|          <xs:element name="Result" msdata:Locale="">|            <xs:complexType>|              <xs:sequence>|                <xs:element name="Id" type="xs:int" minOccurs="0" />|                <xs:element name="Grp" type="xs:int" minOccurs="0" />|                <xs:element name="Name" type="xs:string" minOccurs="0" />|                <xs:element name="Amount" type="xs:decimal" minOccurs="0" />|              </xs:sequence>|            </xs:complexType>|          </xs:element>|        </xs:choice>|      </xs:complexType>|    </xs:element>|  </xs:schema>|</DataSet>|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsXml_Top1_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Qry.TopNumberOfRows(1);
        Observer.Observe('ok', Format(Qry.SaveAsXml(OutStr)));
        Store.Modify();
        ObserveContent(Observer, Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('first three char codes', '217,8249,143,');
        Observer.Expect('content', '<?xml version="1.0" standalone="yes"?>|<DataSet>|  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">|    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:MainDataTable="Result" msdata:Locale="">|      <xs:complexType>|        <xs:choice minOccurs="0" maxOccurs="unbounded">|          <xs:element name="Result" msdata:Locale="">|            <xs:complexType>|              <xs:sequence>|                <xs:element name="Id" type="xs:int" minOccurs="0" />|                <xs:element name="Grp" type="xs:int" minOccurs="0" />|                <xs:element name="Name" type="xs:string" minOccurs="0" />|                <xs:element name="Amount" type="xs:decimal" minOccurs="0" />|              </xs:sequence>|            </xs:complexType>|          </xs:element>|        </xs:choice>|      </xs:complexType>|    </xs:element>|  </xs:schema>|  <Result>|    <Id>1</Id>|    <Grp>1</Grp>|    <Name>one</Name>|    <Amount>10.5</Amount>|  </Result>|</DataSet>|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsXml_Static_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Observer.Observe('ok', Format(Query.SaveAsXml(Query::"LT P105 XmlQry", OutStr)));
        Store.Modify();
        ObserveContent(Observer, Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('first three char codes', '217,8249,143,');
        Observer.Expect('content', '<?xml version="1.0" standalone="yes"?>|<DataSet>|  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">|    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:MainDataTable="Result" msdata:Locale="">|      <xs:complexType>|        <xs:choice minOccurs="0" maxOccurs="unbounded">|          <xs:element name="Result" msdata:Locale="">|            <xs:complexType>|              <xs:sequence>|                <xs:element name="Id" type="xs:int" minOccurs="0" />|                <xs:element name="Grp" type="xs:int" minOccurs="0" />|                <xs:element name="Name" type="xs:string" minOccurs="0" />|                <xs:element name="Amount" type="xs:decimal" minOccurs="0" />|              </xs:sequence>|            </xs:complexType>|          </xs:element>|        </xs:choice>|      </xs:complexType>|    </xs:element>|  </xs:schema>|  <Result>|    <Id>1</Id>|    <Grp>1</Grp>|    <Name>one</Name>|    <Amount>10.5</Amount>|  </Result>|  <Result>|    <Id>2</Id>|    <Grp>1</Grp>|    <Name>two</Name>|    <Amount>20</Amount>|  </Result>|  <Result>|    <Id>3</Id>|    <Grp>2</Grp>|    <Name>three</Name>|    <Amount>30.25</Amount>|  </Result>|  <Result>|    <Id>4</Id>|    <Grp>2</Grp>|    <Name>four</Name>|    <Amount>-5</Amount>|  </Result>|</DataSet>|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsXml_TextFilter_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Qry.SetFilter(Name, '*o*');
        Observer.Observe('ok', Format(Qry.SaveAsXml(OutStr)));
        Store.Modify();
        ObserveContent(Observer, Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('first three char codes', '217,8249,143,');
        Observer.Expect('content', '<?xml version="1.0" standalone="yes"?>|<DataSet>|  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">|    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:MainDataTable="Result" msdata:Locale="">|      <xs:complexType>|        <xs:choice minOccurs="0" maxOccurs="unbounded">|          <xs:element name="Result" msdata:Locale="">|            <xs:complexType>|              <xs:sequence>|                <xs:element name="Id" type="xs:int" minOccurs="0" />|                <xs:element name="Grp" type="xs:int" minOccurs="0" />|                <xs:element name="Name" type="xs:string" minOccurs="0" />|                <xs:element name="Amount" type="xs:decimal" minOccurs="0" />|              </xs:sequence>|            </xs:complexType>|          </xs:element>|        </xs:choice>|      </xs:complexType>|    </xs:element>|  </xs:schema>|  <Result>|    <Id>1</Id>|    <Grp>1</Grp>|    <Name>one</Name>|    <Amount>10.5</Amount>|  </Result>|  <Result>|    <Id>2</Id>|    <Grp>1</Grp>|    <Name>two</Name>|    <Amount>20</Amount>|  </Result>|  <Result>|    <Id>4</Id>|    <Grp>2</Grp>|    <Name>four</Name>|    <Amount>-5</Amount>|  </Result>|</DataSet>|');
        Observer.Verify();
    end;
}
