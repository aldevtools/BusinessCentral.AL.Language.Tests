// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-settableview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), ALT Shape 00, 01, 14 and 15 (tables 50000, 50001, 50014, 50015); local xmlports 95190-95192
// local object: the schema of each xmlport (which table elements it has, in which order and nesting) is what the tests check
// Probe: written against BC 29.0.54011.55816 on the corpus CI (al-runner issue 6919); every literal asserted below is what BC produced.
// Facts: XmlPort.SetTableView with a record whose table is not the table of the first table element: the record of a later
// sibling element (the first element is a temporary table of another table), of a nested child element, of a table no element
// uses, and on a port whose two table elements use the same table; which element the view filters in the export.
// Measured on BC 29.0: the view goes to the first table element (in schema order, nested ones included) whose table is the
// record's table, and filters that element only (a second element of the same table exports all rows; a nested child keeps its
// link and gets the filter too); a record of a table no element uses raises XmlPortNodeNotFound: "The <port> XmlPort does not
// have a XmlItem that uses the table (Table <id> <name>) specified in the function SetTableView."
// BC versions: 27.5, 28.5, 29.0 (corpus CI)

xmlport 95190 "XP STV Siblings"
{
    Direction = Export;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(receivers; "ALT Shape 01")
            {
                UseTemporary = true;
                fieldelement(Id; receivers.Id) { }
            }
            tableelement(transport; "ALT Shape 14")
            {
                fieldelement(Code; transport.Code) { }
                fieldelement(Name; transport.Name) { }
            }
        }
    }
}

xmlport 95191 "XP STV Nested"
{
    Direction = Export;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(header; "ALT Shape 14")
            {
                fieldattribute(Code; header.Code) { }
                tableelement(line; "ALT Shape 15")
                {
                    LinkTable = header;
                    LinkFields = Grp = field(Code);
                    fieldattribute(Id; line.Id) { }
                }
            }
        }
    }
}

xmlport 95192 "XP STV Same Table"
{
    Direction = Export;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(first; "ALT Shape 14")
            {
                XmlName = 'First';
                fieldattribute(Code; first.Code) { }
            }
            tableelement(second; "ALT Shape 14")
            {
                XmlName = 'Second';
                fieldattribute(Code; second.Code) { }
            }
        }
    }
}

codeunit 95193 "XP SetTableView Element"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Transport: Record "ALT Shape 14";
        Line: Record "ALT Shape 15";
    begin
        Transport.DeleteAll();
        Line.DeleteAll();
        Transport.Code := 'T1';
        Transport.Name := 'S1';
        Transport.Insert();
        Transport.Code := 'T2';
        Transport.Name := 'S2';
        Transport.Insert();
        Line.Id := 1;
        Line.Grp := 'T1';
        Line.Insert();
        Line.Id := 2;
        Line.Grp := 'T2';
        Line.Insert();
        Line.Id := 3;
        Line.Grp := 'T1';
        Line.Insert();
    end;

    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [Test]
    procedure SetTableView_RecordOfLaterSiblingElement_Export()
    var
        Observer: Codeunit "Probe Observer";
        Transport: Record "ALT Shape 14";
        Port: XmlPort "XP STV Siblings";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Seed();
        Transport.Get('T1');
        Transport.SetRecFilter();
        TempBlob.CreateOutStream(OutStr);
        Port.SetTableView(Transport);
        Port.SetDestination(OutStr);
        Port.Export();
        Observer.Observe('export', ReadAll(TempBlob));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <receivers>|    <Id>0</Id>|  </receivers>|  <transport>|    <Code>T1</Code>|    <Name>S1</Name>|  </transport>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_RecordOfLaterSiblingElement_RangeFilter()
    var
        Observer: Codeunit "Probe Observer";
        Transport: Record "ALT Shape 14";
        Port: XmlPort "XP STV Siblings";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Seed();
        Transport.SetRange(Name, 'S2');
        TempBlob.CreateOutStream(OutStr);
        Port.SetTableView(Transport);
        Port.SetDestination(OutStr);
        Port.Export();
        Observer.Observe('export', ReadAll(TempBlob));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <receivers>|    <Id>0</Id>|  </receivers>|  <transport>|    <Code>T2</Code>|    <Name>S2</Name>|  </transport>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_NoView_SiblingsExportAll()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "XP STV Siblings";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutStr);
        Port.SetDestination(OutStr);
        Port.Export();
        Observer.Observe('export', ReadAll(TempBlob));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <receivers>|    <Id>0</Id>|  </receivers>|  <transport>|    <Code>T1</Code>|    <Name>S1</Name>|  </transport>|  <transport>|    <Code>T2</Code>|    <Name>S2</Name>|  </transport>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_RecordOfNestedChildElement_Export()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "ALT Shape 15";
        Port: XmlPort "XP STV Nested";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Seed();
        Line.SetFilter(Id, '<>3');
        TempBlob.CreateOutStream(OutStr);
        Port.SetTableView(Line);
        Port.SetDestination(OutStr);
        Port.Export();
        Observer.Observe('export', ReadAll(TempBlob));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <header Code="T1">|    <line Id="1" />|  </header>|  <header Code="T2">|    <line Id="2" />|  </header>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_RecordOfFirstElement_NestedPort_Export()
    var
        Observer: Codeunit "Probe Observer";
        Transport: Record "ALT Shape 14";
        Port: XmlPort "XP STV Nested";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Seed();
        Transport.SetRange(Code, 'T2');
        TempBlob.CreateOutStream(OutStr);
        Port.SetTableView(Transport);
        Port.SetDestination(OutStr);
        Port.Export();
        Observer.Observe('export', ReadAll(TempBlob));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <header Code="T2">|    <line Id="2" />|  </header>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_RecordOfTableNoElementUses()
    var
        Observer: Codeunit "Probe Observer";
        Unused: Record "ALT Shape 00";
        Port: XmlPort "XP STV Siblings";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Seed();
        Unused.SetRange(Id, 1);
        TempBlob.CreateOutStream(OutStr);
        asserterror begin
            Port.SetTableView(Unused);
            Error('no error');
        end;
        Observer.ObserveError('settableview');
        Observer.Expect('settableview|text', 'The XP STV Siblings XmlPort does not have a XmlItem that uses the table (Table 50000 ALT Shape 00) specified in the function SetTableView.');
        Observer.Expect('settableview|code', 'XmlPortNodeNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_TwoElementsOfTheSameTable_Export()
    var
        Observer: Codeunit "Probe Observer";
        Transport: Record "ALT Shape 14";
        Port: XmlPort "XP STV Same Table";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Seed();
        Transport.SetRange(Code, 'T2');
        TempBlob.CreateOutStream(OutStr);
        Port.SetTableView(Transport);
        Port.SetDestination(OutStr);
        Port.Export();
        Observer.Observe('export', ReadAll(TempBlob));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <First Code="T2" />|  <Second Code="T1" />|  <Second Code="T2" />|</Root>|');
        Observer.Verify();
    end;
}
