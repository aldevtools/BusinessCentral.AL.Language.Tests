// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemlink-property
// Scope: in-scope
// Fixtures used: none (Base Application report 508 "Change Log Setup List" and its two tables)
//
// A nested data item with DataItemLink and NO DataItemLinkReference joins to the data item that
// encloses it: each parent row sees only its own child rows. Base Application report 508 is
// written exactly that way — "Change Log Setup (Field)" nested under "Change Log Setup (Table)"
// with DataItemLink = "Table No." = field("Table No.") and no reference — and it runs from the
// Base Application's shipped code, so the join is exercised on a precompiled report, not only on
// a report this app compiles.
//
// Asserted through Report.SaveAs(Xml), which serialises the dataset with child rows nested under
// their parent row, so the test reads which child rows each parent row carries.

codeunit 60224 "Test Report Nested Link Parent"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        FirstTableNo: Integer;
        SecondTableNo: Integer;

    local procedure Initialize()
    var
        ChangeLogSetup: Record "Change Log Setup";
        SetupTable: Record "Change Log Setup (Table)";
        SetupField: Record "Change Log Setup (Field)";
    begin
        // The report's OnPreDataItem reads the singleton setup record with Get().
        if not ChangeLogSetup.Get() then begin
            ChangeLogSetup.Init();
            ChangeLogSetup.Insert(false);
        end;

        FirstTableNo := Database::Customer;
        SecondTableNo := Database::Vendor;

        SetupField.SetFilter("Table No.", '%1|%2', FirstTableNo, SecondTableNo);
        SetupField.DeleteAll(false);
        SetupTable.SetFilter("Table No.", '%1|%2', FirstTableNo, SecondTableNo);
        SetupTable.DeleteAll(false);

        InsertTable(FirstTableNo);
        InsertTable(SecondTableNo);
        // Two field rows under the first table, one under the second.
        InsertField(FirstTableNo, 2);
        InsertField(FirstTableNo, 3);
        InsertField(SecondTableNo, 5);
    end;

    local procedure InsertTable(TableNo: Integer)
    var
        SetupTable: Record "Change Log Setup (Table)";
    begin
        SetupTable.Init();
        SetupTable."Table No." := TableNo;
        SetupTable.Insert(false);
    end;

    local procedure InsertField(TableNo: Integer; FieldNo: Integer)
    var
        SetupField: Record "Change Log Setup (Field)";
    begin
        SetupField.Init();
        SetupField."Table No." := TableNo;
        SetupField."Field No." := FieldNo;
        SetupField.Insert(false);
    end;

    local procedure RenderDataset(TableFilter: Text) Dataset: XmlDocument
    var
        SetupTable: Record "Change Log Setup (Table)";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        DataOut: OutStream;
        DataIn: InStream;
    begin
        SetupTable.SetFilter("Table No.", TableFilter);
        RecRef.GetTable(SetupTable);
        TempBlob.CreateOutStream(DataOut);
        Report.SaveAs(Report::"Change Log Setup List", '', ReportFormat::Xml, DataOut, RecRef);
        TempBlob.CreateInStream(DataIn);
        XmlDocument.ReadFrom(DataIn, Dataset);
    end;

    // For every "Change Log Setup (Table)" row in the dataset: "<parent table no>:<child table no>,<child table no>,..."
    // separated by '|', in dataset order.
    local procedure DescribeJoin(Dataset: XmlDocument) Result: Text
    var
        Parents: XmlNodeList;
        Children: XmlNodeList;
        ParentNode: XmlNode;
        ChildNode: XmlNode;
        ValueNode: XmlNode;
        Part: Text;
    begin
        Dataset.SelectNodes('//DataItem[@name="Change_Log_Setup_Table"]', Parents);
        foreach ParentNode in Parents do begin
            ParentNode.SelectSingleNode('Columns/Column[@name="Change_Log_Setup__Table___Table_No__"]', ValueNode);
            Part := ValueNode.AsXmlElement().InnerText() + ':';
            ParentNode.SelectNodes('DataItems/DataItem[@name="Change_Log_Setup_Field"]/Columns/Column[@name="Change_Log_Setup__Field__Table_No_"]', Children);
            foreach ChildNode in Children do
                Part += ChildNode.AsXmlElement().InnerText() + ',';
            if Result <> '' then
                Result += '|';
            Result += Part.TrimEnd(',');
        end;
    end;

    [Test]
    procedure NestedLink_NoReference_EachParentRowGetsOnlyItsOwnChildRows()
    begin
        // Two field rows under table 18, one under table 23. Without the join, both parents
        // would carry all three field rows: '18:18,18,23|23:18,18,23'.
        Initialize();
        Assert.AreEqual(
            StrSubstNo('%1:%1,%1|%2:%2', FirstTableNo, SecondTableNo),
            DescribeJoin(RenderDataset(StrSubstNo('%1|%2', FirstTableNo, SecondTableNo))),
            'A nested data item with DataItemLink and no DataItemLinkReference must join to its enclosing data item');
    end;

    [Test]
    procedure NestedLink_NoReference_ParentFilteredOut_ItsChildRowsDoNotAppear()
    begin
        // Only table 23's parent row is in the view. Its one field row appears; table 18's two
        // field rows, whose parent is filtered out, must not appear under it.
        Initialize();
        Assert.AreEqual(
            StrSubstNo('%1:%1', SecondTableNo),
            DescribeJoin(RenderDataset(Format(SecondTableNo))),
            'The child rows of a parent outside the report view must not appear under another parent');
    end;
}
