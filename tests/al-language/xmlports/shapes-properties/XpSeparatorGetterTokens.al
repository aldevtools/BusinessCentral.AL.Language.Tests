// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-fieldseparator-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 50001 "ALT Shape 01"; Temp Blob (System Application); the xmlports 95480-95493 of
//   xmlports/shapes-properties/XpSeparatorTokens.al (their export bytes are pinned there); own xmlports 96650-96651, codeunit 96652.
// Probe: from the code-sweep issue al-runner 7635 (the separator getters decode the declared tokens by another rule than export and
//   import). Observation form: every test ends in Observer.Finish(), so its failure message holds BC's values.
// Area: FieldDelimiter(), FieldSeparator(), RecordSeparator() and TableSeparator() of a fresh xmlport variable, for the declared tokens
//   <>, <None>, <none>, <TAB>, <tab>, <LF>, <CR>, <CR/LF>, <NewLine>, ;<TAB> and <TAB><TAB>; RecordSeparator and TableSeparator declared
//   as <none>, <tab>, ;<LF> and <None>, with the export of two rows through those two ports. CR, LF and TAB show as \r, \n and \t.
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI)

xmlport 96650 "XP SepG Rec Lower"
{
    // local object: its RecordSeparator and TableSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = ',';
    RecordSeparator = '<none>';
    TableSeparator = '<tab>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 96651 "XP SepG Rec Semi LF"
{
    // local object: its RecordSeparator and TableSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = ',';
    RecordSeparator = ';<LF>';
    TableSeparator = '<None>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

codeunit 96652 "XP SepG Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Getters(var Observer: Codeunit "Probe Observer"; Name: Text; Delim: Text; Sep: Text; Rec: Text; Tbl: Text)
    begin
        Observer.Observe(Name, 'delim=[' + Delim + '] sep=[' + Sep + '] rec=[' + Rec + '] table=[' + Tbl + ']');
    end;

    [Test]
    procedure SepG_FieldDelimiterAndSeparatorTokens()
    var
        Observer: Codeunit "Probe Observer";
        X80: XmlPort "XP Sep Delim Empty Sep Tab";
        X81: XmlPort "XP Sep Delim Empty Sep Comma";
        X82: XmlPort "XP Sep Delim Tab Sep Semi";
        X83: XmlPort "XP Sep Delim None Sep Empty";
        X84: XmlPort "XP Sep Sep LF";
        X85: XmlPort "XP Sep Sep CR";
        X86: XmlPort "XP Sep Sep CRLF";
        X87: XmlPort "XP Sep Sep NewLine";
        X88: XmlPort "XP Sep Sep Tab Lower";
        X89: XmlPort "XP Sep Sep Semi Tab";
        X90: XmlPort "XP Sep Sep Tab Tab";
        X91: XmlPort "XP Sep Sep None";
        X92: XmlPort "XP Sep Delim Empty Sep None";
        X93: XmlPort "XP Sep Delim None Lower";
    begin
        Getters(Observer, '<> <TAB>', X80.FieldDelimiter(), X80.FieldSeparator(), X80.RecordSeparator(), X80.TableSeparator());
        Getters(Observer, '<> default', X81.FieldDelimiter(), X81.FieldSeparator(), X81.RecordSeparator(), X81.TableSeparator());
        Getters(Observer, '<TAB> ;', X82.FieldDelimiter(), X82.FieldSeparator(), X82.RecordSeparator(), X82.TableSeparator());
        Getters(Observer, '<None> <>', X83.FieldDelimiter(), X83.FieldSeparator(), X83.RecordSeparator(), X83.TableSeparator());
        Getters(Observer, '<None> <LF>', X84.FieldDelimiter(), X84.FieldSeparator(), X84.RecordSeparator(), X84.TableSeparator());
        Getters(Observer, '<None> <CR>', X85.FieldDelimiter(), X85.FieldSeparator(), X85.RecordSeparator(), X85.TableSeparator());
        Getters(Observer, '<None> <CR/LF>', X86.FieldDelimiter(), X86.FieldSeparator(), X86.RecordSeparator(), X86.TableSeparator());
        Getters(Observer, '<None> <NewLine>', X87.FieldDelimiter(), X87.FieldSeparator(), X87.RecordSeparator(), X87.TableSeparator());
        Getters(Observer, '<None> <tab>', X88.FieldDelimiter(), X88.FieldSeparator(), X88.RecordSeparator(), X88.TableSeparator());
        Getters(Observer, '<None> ;<TAB>', X89.FieldDelimiter(), X89.FieldSeparator(), X89.RecordSeparator(), X89.TableSeparator());
        Getters(Observer, '<None> <TAB><TAB>', X90.FieldDelimiter(), X90.FieldSeparator(), X90.RecordSeparator(), X90.TableSeparator());
        Getters(Observer, '<None> <None>', X91.FieldDelimiter(), X91.FieldSeparator(), X91.RecordSeparator(), X91.TableSeparator());
        Getters(Observer, '<> <None>', X92.FieldDelimiter(), X92.FieldSeparator(), X92.RecordSeparator(), X92.TableSeparator());
        Getters(Observer, '<none> <TAB>', X93.FieldDelimiter(), X93.FieldSeparator(), X93.RecordSeparator(), X93.TableSeparator());
        Observer.Expect('<> <TAB>', 'delim=[<>] sep=[\t] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<> default', 'delim=[<>] sep=[,] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<TAB> ;', 'delim=[\t] sep=[;] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<None> <>', 'delim=[] sep=[<>] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<None> <LF>', 'delim=[] sep=[\n] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<None> <CR>', 'delim=[] sep=[\r] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<None> <CR/LF>', 'delim=[] sep=[\r\n] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<None> <NewLine>', 'delim=[] sep=[\r\n] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<None> <tab>', 'delim=[] sep=[<tab>] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<None> ;<TAB>', 'delim=[] sep=[;\t] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<None> <TAB><TAB>', 'delim=[] sep=[\t\t] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<None> <None>', 'delim=[] sep=[] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<> <None>', 'delim=[<>] sep=[] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Expect('<none> <TAB>', 'delim=[<none>] sep=[\t] rec=[\r\n] table=[\r\n\r\n]');
        Observer.Verify();
    end;

    local procedure ExportRows(PortId: Integer): Text
    var
        Shape: Record "ALT Shape 01";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Result: Text;
    begin
        Shape.DeleteAll();
        Shape.Id := 1;
        Shape.Name := 'Alpha';
        Shape.Insert();
        Shape.Id := 2;
        Shape.Name := 'Beta';
        Shape.Insert();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(PortId, OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        InS.Read(Result);
        exit(Result);
    end;

    [Test]
    procedure SepG_RecordAndTableSeparatorTokens()
    var
        Observer: Codeunit "Probe Observer";
        XLower: XmlPort "XP SepG Rec Lower";
        XSemi: XmlPort "XP SepG Rec Semi LF";
    begin
        Getters(Observer, 'rec <none> table <tab>', XLower.FieldDelimiter(), XLower.FieldSeparator(), XLower.RecordSeparator(), XLower.TableSeparator());
        Getters(Observer, 'rec ;<LF> table <None>', XSemi.FieldDelimiter(), XSemi.FieldSeparator(), XSemi.RecordSeparator(), XSemi.TableSeparator());
        Observer.Observe('export rec <none>', ExportRows(Xmlport::"XP SepG Rec Lower"));
        Observer.Observe('export rec ;<LF>', ExportRows(Xmlport::"XP SepG Rec Semi LF"));
        Observer.Expect('rec <none> table <tab>', 'delim=[] sep=[,] rec=[<none>] table=[<tab>]');
        Observer.Expect('rec ;<LF> table <None>', 'delim=[] sep=[,] rec=[;\n] table=[]');
        Observer.Expect('export rec <none>', '1,Alpha<none>2,Beta');
        Observer.Expect('export rec ;<LF>', '1,Alpha;\n2,Beta');
        Observer.Verify();
    end;
}
