// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: behavior-defining local objects
// BC versions: 27.5+

using System.Utilities;

// local object: this fixture defines the table or report shape under test.
table 52010 "RPT Breaks Row"
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
report 52011 "RPT Breaks Link"
{
    ProcessingOnly = false;
    dataset
    {
        dataitem(Header; "RPT Breaks Row")
        {
            DataItemTableView = where(Id = const(1));
            column(HeaderKey; Id) { }
            column(Payload; Payload) { }
            dataitem(Line; "RPT Breaks Row")
            {
                DataItemTableView = where(Id = const(3));
                column(BaseLineKey; Id) { }
            }
        }
    }
}

// local object: this fixture defines the table or report shape under test.
reportextension 52012 "RPT Breaks Link Extension" extends "RPT Breaks Link"
{
    dataset
    {
        addbefore(Line)
        {
            dataitem(AddedHeader; "RPT Breaks Row")
            {
                DataItemLink = ParentId = field(Id);
                DataItemLinkReference = Header;
                DataItemTableView = where(Id = filter(2|5));
                column(AddedHeaderKey; Id) { }
                dataitem(AddedLine; "RPT Breaks Row")
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

codeunit 52013 "RPT Breaks Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SaveXml_LineBreaks_UsesCrLf()
    var
        Row: Record "RPT Breaks Row";
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
        Report.SaveAs(Report::"RPT Breaks Link", '', ReportFormat::Xml, OutS);
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
        if (StrPos(Raw, 'Before' + Format(Cr) + Format(Lf) + 'After') = 0) or
           (StrPos(Raw, 'After' + Format(Cr) + Format(Lf) + 'Pair') = 0) or
           (StrPos(Raw, 'Pair' + Format(Cr) + Format(Lf) + 'Done') = 0) or
           (StrPos(Value, Format(Cr)) <> 0)
        then
            Error('The report XML did not preserve the measured line-break representation.');

    end;

    local procedure Seed(Id: Integer; ParentId: Integer; Payload: Text[100])
    var
        Row: Record "RPT Breaks Row";
    begin
        Row.Id := Id;
        Row.ParentId := ParentId;
        Row.Payload := Payload;
        Row.Insert();
    end;
    local procedure Initialize()
    var
        Row: Record "RPT Breaks Row";
    begin
        Row.DeleteAll();
    end;
}
