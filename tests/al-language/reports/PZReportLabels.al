// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-labels
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Row (67698) and W3 Dataset (67703); self-contained reports 69350, 69351, report extension 69350, codeunit 69350
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816); every literal below is what that tier produced. Other BC versions are checked by the CI matrix.
//
// Report.SaveAs Xml writes the labels of a report (and of its report extensions) as <Labels><Label name="..">text</Label></Labels> between <BCReportInformation> and <DataItems>, in declaration order,
// base report first, then the extension. The text is the label value with the XML escapes undone by the reader (<, >, &). A label with an empty value reads as its own name. Comment, MaxLength and Locked
// do not appear (the element has only the name attribute). A report without labels has no <Labels> element at all.
// BC versions: 29.0
report 69350 "PZ Labels Rpt"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }
        }
    }

    labels
    {
        PlainLabel = 'Plain text';
        CommentLabel = 'With comment', Comment = 'a comment', MaxLength = 30;
        LockedLabel = 'Locked text', Locked = true;
        EmptyLabel = '';
        QuoteLabel = 'It''s <b> & "q"';
        UpperLabel = 'ÄÖÜ ß';
    }
}

report 69351 "PZ Labels Only Rpt"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }
        }
    }

    requestpage
    {
        layout { }
    }

    labels
    {
        OnlyLabel = 'Only one';
    }
}

reportextension 69350 "PZ Labels Ext" extends "PZ Labels Rpt"
{
    labels
    {
        ExtLabel = 'From the extension';
    }
}

codeunit 69350 "PZ Report Labels"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Dataset: Codeunit "W3 Dataset";

    local procedure RootChildren(Xml: Text): Text
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Node: XmlNode;
        Result: Text;
    begin
        XmlDocument.ReadFrom(Xml, Doc);
        Doc.GetRoot(Root);
        foreach Node in Root.GetChildElements() do
            Result += Node.AsXmlElement().Name() + ',';
        exit(Result);
    end;

    local procedure LabelPairs(Xml: Text): Text
    var
        Doc: XmlDocument;
        Nodes: XmlNodeList;
        Node: XmlNode;
        NameAttr: XmlAttribute;
        Result: Text;
    begin
        XmlDocument.ReadFrom(Xml, Doc);
        if Doc.SelectNodes('/ReportDataSet/Labels/Label', Nodes) then
            foreach Node in Nodes do begin
                Node.AsXmlElement().Attributes().Get('name', NameAttr);
                Result += NameAttr.Value() + '=[' + Node.AsXmlElement().InnerText() + '];';
            end;
        exit(Result);
    end;

    local procedure LabelAttributes(Xml: Text): Text
    var
        Doc: XmlDocument;
        Node: XmlNode;
        Attr: XmlAttribute;
        Result: Text;
    begin
        XmlDocument.ReadFrom(Xml, Doc);
        if Doc.SelectSingleNode('/ReportDataSet/Labels/Label', Node) then
            foreach Attr in Node.AsXmlElement().Attributes() do
                Result += Attr.Name() + ',';
        exit(Result);
    end;

    local procedure Seed()
    var
        Row: Record "W3 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
    end;

    [Test]
    procedure Labels_AreWrittenIntoTheDataset()
    var
        Xml: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('saved', Format(Dataset.Save(Report::"PZ Labels Rpt", '', Xml)));
        Observer.Observe('root_children', RootChildren(Xml));
        Observer.Observe('label_pairs', LabelPairs(Xml));
        Observer.Observe('label_attributes', LabelAttributes(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('root_children', 'BCReportInformation,Labels,DataItems,');
        Observer.Expect('label_pairs', 'PlainLabel=[Plain text];CommentLabel=[With comment];LockedLabel=[Locked text];EmptyLabel=[EmptyLabel];QuoteLabel=[It''s <b> & "q"];UpperLabel=[ÄÖÜ ß];ExtLabel=[From the extension];');
        Observer.Expect('label_attributes', 'name,');
        Observer.Verify();
    end;

    [Test]
    procedure NoLabels_NoLabelsElement()
    var
        Xml: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('saved', Format(Dataset.Save(Report::"W3 Hdr Plain", '', Xml)));
        Observer.Observe('root_children', RootChildren(Xml));
        Observer.Observe('label_pairs', LabelPairs(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('root_children', 'BCReportInformation,DataItems,');
        Observer.Expect('label_pairs', '');
        Observer.Verify();
    end;

    [Test]
    procedure LabelsOnly_ReportWithOnlyOneLabel()
    var
        Xml: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('saved', Format(Dataset.Save(Report::"PZ Labels Only Rpt", '', Xml)));
        Observer.Observe('label_pairs', LabelPairs(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('label_pairs', 'OnlyLabel=[Only one];');
        Observer.Verify();
    end;
}
