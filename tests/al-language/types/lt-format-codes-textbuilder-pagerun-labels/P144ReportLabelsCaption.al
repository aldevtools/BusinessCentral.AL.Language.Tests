// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-labels
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Dataset (codeunit 67703); own table 74811 and reports 74800, 74801; writer SQ: SqReportLabelsObjects.al (tables 89581, 89582, reports 89583, 89585, report extension 89584)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Report.SaveAs Xml of a report with a labels section and columns with IncludeCaption = true: order of the Label and caption lines in the dataset
// (report/PZReportLabels.al pins labels alone, handlers/PWReportSaveAsColumns.al IncludeCaption alone).
// BC versions: 29 (27 and 28 by CI)

table 70238 "LT P144 Rpt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Row Id'; }
        field(2; Txt; Text[30]) { Caption = 'Row Text'; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

report 70241 "LT P144 Labels Caption Rpt"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "LT P144 Rpt Row")
        {
            column(IdC; Id) { IncludeCaption = true; }
            column(TxtC; Txt) { IncludeCaption = true; }
            column(PlainC; Id) { }
        }
    }

    labels
    {
        FirstLabel = 'First label';
        SecondLabel = 'Second label';
    }
}

report 70242 "LT P144 Caption Only Rpt"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "LT P144 Rpt Row")
        {
            column(IdC; Id) { IncludeCaption = true; }
            column(TxtC; Txt) { IncludeCaption = true; }
            column(PlainC; Id) { }
        }
    }
}

codeunit 70236 "LT P144 Report Labels Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P144 Rpt Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Txt := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Txt := 'two';
        Row.Insert();
    end;

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

    [Test]
    procedure P144_LabelsAndIncludeCaption_Order()
    var
        Dataset: Codeunit "W3 Dataset";
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed();
        Observer.Observe('saved', Format(Dataset.Save(Report::"LT P144 Labels Caption Rpt", '', Xml)));
        Observer.Observe('root_children', RootChildren(Xml));
        Observer.Observe('column_and_label_lines', Dataset.ColumnLines(Xml));
        Observer.Observe('tokens', Dataset.Tokens(Xml));
        Observer.Observe('idc_values', Dataset.ColumnValues(Xml, 'IdC'));
        Observer.Observe('idc_caption_values', Dataset.ColumnValues(Xml, 'IdC_Caption'));
        Observer.Observe('txtc_caption_values', Dataset.ColumnValues(Xml, 'TxtC_Caption'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('root_children', 'BCReportInformation,Labels,DataItems,');
        Observer.Expect('column_and_label_lines', '<Label name="IdCCaption">Row Id</Label>|<Label name="TxtCCaption">Row Text</Label>|<Label name="FirstLabel">First label</Label>|<Label name="SecondLabel">Second label</Label>|<Column name="IdC">1</Column>|<Column name="TxtC">one</Column>|<Column name="PlainC">1</Column>|<Column name="IdC">2</Column>|<Column name="TxtC">two</Column>|<Column name="PlainC">2</Column>|');
        Observer.Expect('tokens', 'DIs DI c:IdC c:TxtC c:PlainC /DI DI c:IdC c:TxtC c:PlainC /DI /DIs');
        Observer.Expect('idc_values', '1,2,');
        Observer.Expect('idc_caption_values', '');
        Observer.Expect('txtc_caption_values', '');
        Observer.Verify();
    end;

    [Test]
    procedure P144_IncludeCaptionOnly_Order()
    var
        Dataset: Codeunit "W3 Dataset";
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed();
        Observer.Observe('saved', Format(Dataset.Save(Report::"LT P144 Caption Only Rpt", '', Xml)));
        Observer.Observe('root_children', RootChildren(Xml));
        Observer.Observe('column_and_label_lines', Dataset.ColumnLines(Xml));
        Observer.Observe('tokens', Dataset.Tokens(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('root_children', 'BCReportInformation,Labels,DataItems,');
        Observer.Expect('column_and_label_lines', '<Label name="IdCCaption">Row Id</Label>|<Label name="TxtCCaption">Row Text</Label>|<Column name="IdC">1</Column>|<Column name="TxtC">one</Column>|<Column name="PlainC">1</Column>|<Column name="IdC">2</Column>|<Column name="TxtC">two</Column>|<Column name="PlainC">2</Column>|');
        Observer.Expect('tokens', 'DIs DI c:IdC c:TxtC c:PlainC /DI DI c:IdC c:TxtC c:PlainC /DI /DIs');
        Observer.Verify();
    end;

    // Writer SQ (NP lane 2026-10-28): two data items (nested and a second top-level one) with IncludeCaption columns, labels, and a report extension (SqReportLabelsObjects.al).
    local procedure SqSeed()
    var
        Head: Record "LT SQ Rpt Head";
        Line: Record "LT SQ Rpt Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head.Id := 1;
        Head.Name := 'H1';
        Head.Insert();
        Line.HeadId := 1;
        Line.LineNo := 10;
        Line.Descr := 'L10';
        Line.Qty := 2;
        Line.Insert();
    end;

    [Test]
    procedure Sq_TwoDataItems_Labels_Order()
    var
        Dataset: Codeunit "W3 Dataset";
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        SqSeed();
        Observer.Observe('saved', Format(Dataset.Save(Report::"LT SQ Labels Two Items", '', Xml)));
        Observer.Observe('root_children', RootChildren(Xml));
        Observer.Observe('column_and_label_lines', Dataset.ColumnLines(Xml));
        Observer.Observe('tokens', Dataset.Tokens(Xml));
        Observer.Finish();
    end;

    [Test]
    procedure Sq_TwoDataItems_ExtensionLabels_Order()
    var
        Dataset: Codeunit "W3 Dataset";
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        SqSeed();
        Observer.Observe('saved', Format(Dataset.Save(Report::"LT SQ Labels Two Items Ext", '', Xml)));
        Observer.Observe('root_children', RootChildren(Xml));
        Observer.Observe('column_and_label_lines', Dataset.ColumnLines(Xml));
        Observer.Observe('tokens', Dataset.Tokens(Xml));
        Observer.Finish();
    end;
}
