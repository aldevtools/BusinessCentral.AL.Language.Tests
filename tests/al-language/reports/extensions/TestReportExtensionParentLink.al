// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: behavior-defining local objects
// BC versions: 27.5+

using System.Utilities;

// local object: this fixture defines the table or report shape under test.
table 52000 "RPT Parent Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Payload; Text[100]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// local object: this fixture defines the table or report shape under test.
report 52001 "RPT Parent Link"
{
    ProcessingOnly = false;
    dataset
    {
        dataitem(Header; "RPT Parent Row")
        {
            DataItemTableView = where(Id = const(1));
            column(HeaderKey; Id) { }
            column(Payload; Payload) { }
            dataitem(Line; "RPT Parent Row")
            {
                DataItemTableView = where(Id = const(3));
                column(BaseLineKey; Id) { }
            }
        }
    }
}

// local object: this fixture defines the table or report shape under test.
reportextension 52002 "RPT Parent Link Extension" extends "RPT Parent Link"
{
    dataset
    {
        addbefore(Line)
        {
            dataitem(AddedHeader; "RPT Parent Row")
            {
                DataItemLink = ParentId = field(Id);
                DataItemLinkReference = Header;
                DataItemTableView = where(Id = filter(2|5));
                column(AddedHeaderKey; Id) { }
                dataitem(AddedLine; "RPT Parent Row")
                {
                    DataItemLink = ParentId = field(Id);
                    DataItemLinkReference = AddedHeader;
                    DataItemTableView = where(Id = filter(4|6));
                    column(AddedLineKey; Id) { }
                }
            }
        }
    }
}

codeunit 52003 "RPT Parent Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SaveXml_ExplicitParentLinks_SelectRelatedRows()
    var
        Row: Record "RPT Parent Row";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Xml: XmlDocument;
        Node: XmlNode;
        Raw: Text;
        Ch: Text[1];
        B: Byte;
        Value: Text;
        Cr: Char;
        Lf: Char;
    begin
        Initialize();
        Cr := 13;
        Lf := 10;
        Seed(1, 0, 'Before' + Format(Cr) + 'After' + Format(Cr) + Format(Lf) + 'Pair' + Format(Lf) + 'Done');
        Seed(2, 1, '');
        Seed(3, 1, '');
        Seed(4, 2, '');
        Seed(5, 9, '');
        Seed(6, 9, '');
        Commit();
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"RPT Parent Link", '', ReportFormat::Xml, OutS);
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            Ch[1] := B;
            Raw += Ch;
        end;
        TempBlob.CreateInStream(InS);
        XmlDocument.ReadFrom(InS, Xml);
        if not Xml.SelectSingleNode('//Column[@name = ''Payload'']', Node) then
            Error('Payload was absent. XML tail: %1', Raw);
        Value := Node.AsXmlElement().InnerText();
        if (StrPos(Raw, '<Column name="AddedHeaderKey">2</Column>') = 0) or
           (StrPos(Raw, '<Column name="AddedLineKey">4</Column>') = 0) or
           (StrPos(Raw, '<Column name="AddedHeaderKey">5</Column>') <> 0) or
           (StrPos(Raw, '<Column name="AddedLineKey">6</Column>') <> 0)
        then
            Error('The report did not link its added children to the named enclosing items.');

    end;

    local procedure Seed(Id: Integer; ParentId: Integer; Payload: Text[100])
    var
        Row: Record "RPT Parent Row";
    begin
        Row.Id := Id;
        Row.ParentId := ParentId;
        Row.Payload := Payload;
        Row.Insert();
    end;
    local procedure Initialize()
    var
        Row: Record "RPT Parent Row";
    begin
        Row.DeleteAll();
    end;
}
