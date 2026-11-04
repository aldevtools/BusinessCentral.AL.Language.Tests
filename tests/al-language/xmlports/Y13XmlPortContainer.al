// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-schema-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 91600, xmlports 91601-91602, test codeunit 91603
// Probe: observe probe (writer Y13, 2026-10-31, runtime asks from partner-app triage); every literal asserted below is what the BC service tier produced.
// Facts: XmlPort import where a textelement that only holds child elements (a container) is nested in a tableelement, with the container's
//   MinOccurs at its default (Once) and at Zero: which records and field values result for complete rows, an empty row, a row with the
//   container missing, a row with the fields outside the container, a row with one field missing, and a container that appears twice.
// BC versions: 27, 28, 29

table 91600 "LT Y13 XC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Xml; Blob) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 91601 "LT Y13 XC Once"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y13 XC Row")
            {
                XmlName = 'Row';
                UseTemporary = false;
                textelement(Info)
                {
                    fieldelement(Name; Row.Name) { }
                    fieldelement(Qty; Row.Qty) { }
                }
            }
        }
    }
}

xmlport 91602 "LT Y13 XC Zero"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y13 XC Row")
            {
                XmlName = 'Row';
                UseTemporary = false;
                textelement(Info)
                {
                    MinOccurs = Zero;
                    fieldelement(Name; Row.Name) { }
                    fieldelement(Qty; Row.Qty) { }
                }
            }
        }
    }
}

codeunit 91603 "LT Y13 XC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryImport(PortId: Integer; Body: Text)
    var
        Holder: Record "LT Y13 XC Row" temporary;
        InS: InStream;
        OutS: OutStream;
    begin
        Holder.Xml.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<?xml version="1.0" encoding="utf-8"?><Root>' + Body + '</Root>');
        Holder.Xml.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(PortId, InS);
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT Y13 XC Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += '[' + Row.Name + '|' + Format(Row.Qty) + ']';
            until Row.Next() = 0;
        exit(Format(Row.Count()) + ' rows ' + Result);
    end;

    local procedure Outcome(PortId: Integer; Body: Text): Text
    var
        Row: Record "LT Y13 XC Row";
        Ok: Boolean;
        Head: Text;
    begin
        Row.DeleteAll();
        Ok := TryImport(PortId, Body);
        if Ok then
            Head := 'ok'
        else
            Head := 'error ' + GetLastErrorText() + ' (' + GetLastErrorCode() + ')';
        exit(Head + ' / ' + Rows());
    end;

    [Test]
    procedure Y13_XC_Once_Complete_And_Missing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('complete', Outcome(91601, '<Row><Info><Name>A</Name><Qty>1</Qty></Info></Row><Row><Info><Name>B</Name><Qty>2</Qty></Info></Row>'));
        Observer.Observe('empty row', Outcome(91601, '<Row></Row>'));
        Observer.Observe('empty row second', Outcome(91601, '<Row><Info><Name>A</Name><Qty>1</Qty></Info></Row><Row></Row>'));
        Observer.Observe('fields outside', Outcome(91601, '<Row><Name>A</Name><Qty>1</Qty></Row>'));
        Observer.Observe('qty missing', Outcome(91601, '<Row><Info><Name>A</Name></Info></Row>'));
        Observer.Observe('twice', Outcome(91601, '<Row><Info><Name>A</Name><Qty>1</Qty></Info><Info><Name>B</Name><Qty>2</Qty></Info></Row>'));
        Observer.Observe('no rows', Outcome(91601, ''));
        Observer.Expect('complete', 'ok / 2 rows [A|1][B|2]');
        Observer.Expect('empty row', 'error Imported XML cannot validate with the schema: The element ''Row'' has incomplete content. List of possible elements expected: ''Info''. (XmlPortInvalidXml) / 0 rows ');
        Observer.Expect('empty row second', 'error Imported XML cannot validate with the schema: The element ''Row'' has incomplete content. List of possible elements expected: ''Info''. (XmlPortInvalidXml) / 1 rows [A|1]');
        Observer.Expect('fields outside', 'error Imported XML cannot validate with the schema: The element ''Row'' has invalid child element ''Name''. List of possible elements expected: ''Info''. (XmlPortInvalidXml) / 0 rows ');
        Observer.Expect('qty missing', 'error Imported XML cannot validate with the schema: The element ''Info'' has incomplete content. List of possible elements expected: ''Qty''. (XmlPortInvalidXml) / 0 rows ');
        Observer.Expect('twice', 'ok / 1 rows [B|2]');
        Observer.Expect('no rows', 'error Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Row''. (XmlPortInvalidXml) / 0 rows ');
        Observer.Verify();
    end;

    [Test]
    procedure Y13_XC_Zero_Complete_And_Missing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('complete', Outcome(91602, '<Row><Info><Name>A</Name><Qty>1</Qty></Info></Row><Row><Info><Name>B</Name><Qty>2</Qty></Info></Row>'));
        Observer.Observe('empty row', Outcome(91602, '<Row></Row>'));
        Observer.Observe('empty row second', Outcome(91602, '<Row><Info><Name>A</Name><Qty>1</Qty></Info></Row><Row></Row>'));
        Observer.Observe('fields outside', Outcome(91602, '<Row><Name>A</Name><Qty>1</Qty></Row>'));
        Observer.Observe('qty missing', Outcome(91602, '<Row><Info><Name>A</Name></Info></Row>'));
        Observer.Observe('twice', Outcome(91602, '<Row><Info><Name>A</Name><Qty>1</Qty></Info><Info><Name>B</Name><Qty>2</Qty></Info></Row>'));
        Observer.Observe('no rows', Outcome(91602, ''));
        Observer.Expect('complete', 'ok / 2 rows [A|1][B|2]');
        Observer.Expect('empty row', 'ok / 1 rows [|0]');
        Observer.Expect('empty row second', 'ok / 2 rows [A|1][|0]');
        Observer.Expect('fields outside', 'error Imported XML cannot validate with the schema: The element ''Row'' has invalid child element ''Name''. List of possible elements expected: ''Info''. (XmlPortInvalidXml) / 0 rows ');
        Observer.Expect('qty missing', 'error Imported XML cannot validate with the schema: The element ''Info'' has incomplete content. List of possible elements expected: ''Qty''. (XmlPortInvalidXml) / 0 rows ');
        Observer.Expect('twice', 'ok / 1 rows [B|2]');
        Observer.Expect('no rows', 'error Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Row''. (XmlPortInvalidXml) / 0 rows ');
        Observer.Verify();
    end;
}

