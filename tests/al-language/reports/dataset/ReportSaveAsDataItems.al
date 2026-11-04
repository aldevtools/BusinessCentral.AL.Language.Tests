// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); self-contained tables 74948 to 74950, reports 74951 to 74953, test codeunit 74955
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the DataItems part of the Report.SaveAs Xml dataset (from the <DataItems> element on; the header before it is not asserted): the element tree of a parent with a child data item and of two sibling data items, the row order, and the exact element name written for data item names with a dot, a space, a slash, a hyphen or an ampersand.
// BC versions: 29 (27 and 28 by CI)

table 74948 "LT SD Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 74949 "LT SD Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Note; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 74950 "LT SD Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Label; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

report 74951 "LT SD Parent Child"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Par; "LT SD Parent")
        {
            column(ParId; Id) { }
            column(ParName; Name) { }

            dataitem(Chi; "LT SD Child")
            {
                DataItemLink = ParentId = field(Id);

                column(ChiId; Id) { }
                column(ChiNote; Note) { }
            }
        }
    }
}

report 74952 "LT SD Siblings"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Par; "LT SD Parent")
        {
            column(ParId; Id) { }
        }
        dataitem(Oth; "LT SD Other")
        {
            column(OthId; Id) { }
            column(OthLabel; Label) { }
        }
    }
}

report 74953 "LT SD Special Names"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem("Prod. Order Line"; "LT SD Parent")
        {
            DataItemTableView = where(Id = const(1));
            column(ProdId; Id) { }
        }
        dataitem("Sales/Line"; "LT SD Parent")
        {
            DataItemTableView = where(Id = const(1));
            column(SlashId; Id) { }
        }
        dataitem("Sales-Line"; "LT SD Parent")
        {
            DataItemTableView = where(Id = const(1));
            column(HyphenId; Id) { }
        }
        dataitem("A&B Line"; "LT SD Parent")
        {
            DataItemTableView = where(Id = const(1));
            column(AmpId; Id) { }
        }
    }
}

codeunit 74955 "LT SaveAs Data Items"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Par: Record "LT SD Parent";
        Chi: Record "LT SD Child";
        Oth: Record "LT SD Other";
    begin
        Par.DeleteAll();
        Chi.DeleteAll();
        Oth.DeleteAll();
        Par.Id := 1; Par.Name := 'one'; Par.Insert();
        Par.Id := 2; Par.Name := 'a<b&c'; Par.Insert();
        Chi.Id := 10; Chi.ParentId := 1; Chi.Note := 'c10'; Chi.Insert();
        Chi.Id := 11; Chi.ParentId := 1; Chi.Note := 'c11'; Chi.Insert();
        Chi.Id := 20; Chi.ParentId := 2; Chi.Note := 'c20'; Chi.Insert();
        Oth.Id := 5; Oth.Label := 'five'; Oth.Insert();
        Oth.Id := 6; Oth.Label := 'six'; Oth.Insert();
        Commit();
    end;

    local procedure StripSystemIds(Xml: Text): Text
    var
        Result: Text;
        At: Integer;
        Marker: Text;
    begin
        // systemId (a Guid) and tableId are left out: the attributes exist from BC 28 only (see Gate ReportSaveAsDataItemIdentity).
        Marker := ' systemId="';
        At := StrPos(Xml, Marker);
        while At > 0 do begin
            Result += CopyStr(Xml, 1, At - 1);
            Xml := CopyStr(Xml, At + StrLen(Marker) + 37);
            At := StrPos(Xml, Marker);
        end;
        Xml := Result + Xml;
        Result := '';
        Marker := ' tableId="';
        At := StrPos(Xml, Marker);
        while At > 0 do begin
            Result += CopyStr(Xml, 1, At - 1);
            Xml := CopyStr(Xml, At + StrLen(Marker));
            Xml := CopyStr(Xml, StrPos(Xml, '"') + 1);
            At := StrPos(Xml, Marker);
        end;
        exit(Result + Xml);
    end;

    local procedure DataItemsOf(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Xml: Text;
        Line: Text;
        At: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS);
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        Xml := StripSystemIds(Xml);
        At := StrPos(Xml, '<DataItems>');
        if At = 0 then
            exit('no DataItems element');
        exit(CopyStr(Xml, At));
    end;

    [Test]
    procedure SaveAsXml_ParentWithChild_ElementTree()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('tree', DataItemsOf(Report::"LT SD Parent Child"));
        Observer.Expect('tree', '<DataItems>|    <DataItem language="en-US" formatRegion="en-US" name="Par">|      <Columns>|        <Column name="ParId">1</Column>|        <Column name="ParName">one</Column>|      </Columns>|      <DataItems>|        <DataItem name="Chi">|          <Columns>|            <Column name="ChiId">10</Column>|            <Column name="ChiNote">c10</Column>|          </Columns>|        </DataItem>|        <DataItem name="Chi">|          <Columns>|            <Column name="ChiId">11</Column>|            <Column name="ChiNote">c11</Column>|          </Columns>|        </DataItem>|      </DataItems>|    </DataItem>|    <DataItem language="en-US" formatRegion="en-US" name="Par">|      <Columns>|        <Column name="ParId">2</Column>|        <Column name="ParName">a&lt;b&amp;c</Column>|      </Columns>|      <DataItems>|        <DataItem name="Chi">|          <Columns>|            <Column name="ChiId">20</Column>|            <Column name="ChiNote">c20</Column>|          </Columns>|        </DataItem>|      </DataItems>|    </DataItem>|  </DataItems>|</ReportDataSet>|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsXml_TwoSiblings_ElementTree()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('tree', DataItemsOf(Report::"LT SD Siblings"));
        Observer.Expect('tree', '<DataItems>|    <DataItem language="en-US" formatRegion="en-US" name="Par">|      <Columns>|        <Column name="ParId">1</Column>|      </Columns>|    </DataItem>|    <DataItem language="en-US" formatRegion="en-US" name="Par">|      <Columns>|        <Column name="ParId">2</Column>|      </Columns>|    </DataItem>|    <DataItem language="en-US" formatRegion="en-US" name="Oth">|      <Columns>|        <Column name="OthId">5</Column>|        <Column name="OthLabel">five</Column>|      </Columns>|    </DataItem>|    <DataItem language="en-US" formatRegion="en-US" name="Oth">|      <Columns>|        <Column name="OthId">6</Column>|        <Column name="OthLabel">six</Column>|      </Columns>|    </DataItem>|  </DataItems>|</ReportDataSet>|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsXml_DataItemNames_SpecialCharacters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('tree', DataItemsOf(Report::"LT SD Special Names"));
        Observer.Expect('tree', '<DataItems>|    <DataItem language="en-US" formatRegion="en-US" name="Prod_Order_Line">|      <Columns>|        <Column name="ProdId">1</Column>|      </Columns>|    </DataItem>|    <DataItem language="en-US" formatRegion="en-US" name="Sales_Line">|      <Columns>|        <Column name="SlashId">1</Column>|      </Columns>|    </DataItem>|    <DataItem language="en-US" formatRegion="en-US" name="Sales_Line1">|      <Columns>|        <Column name="HyphenId">1</Column>|      </Columns>|    </DataItem>|    <DataItem language="en-US" formatRegion="en-US" name="A_x0026_B_Line">|      <Columns>|        <Column name="AmpId">1</Column>|      </Columns>|    </DataItem>|  </DataItems>|</ReportDataSet>|');
        Observer.Verify();
    end;
}
