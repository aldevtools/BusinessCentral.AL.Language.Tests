// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own table 84520, queries 84521 and 84522, log codeunit 84523, test codeunit 84524
// Probe: written against BC on the corpus test loop and CI; every literal asserted below is what the tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts (corpus issue 667, items 113, 114 and 116):
//   Clear: Clear(Query) on a query that is open and partly read, then a new SetRange, Open and Read: the rows the second cycle returns and the filters after Clear.
//   OnBeforeOpen: CurrQuery.Open, CurrQuery.SaveAsXml and CurrQuery.Close called inside the OnBeforeOpen trigger of the query: the error the caller of Open gets, or none.
//   SaveAs: SaveAsXml on a query that is open and read up to the first row: the rows it writes, and what the next Read returns (or the error it raises).
// BC versions: 27, 28, 29 by CI

table 84520 "LT CH Q Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

query 84521 "LT CH Q Rows"
{
    QueryType = Normal;
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Row; "LT CH Q Row")
        {
            column(Id; Id) { }
            column(Grp; Grp) { }
        }
    }
}

query 84522 "LT CH Q Self"
{
    QueryType = Normal;
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Row; "LT CH Q Row")
        {
            column(Id; Id) { }
        }
    }

    trigger OnBeforeOpen()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Depth += 1;
        Log.Add('OnBeforeOpen depth=' + Format(Depth));
        if Depth > 1 then
            exit;
        case Log.Mode() of
            1:
                begin
                    CurrQuery.Open();
                    Log.Add('inner Open returned');
                end;
            2:
                begin
                    TempBlob.CreateOutStream(OutS);
                    Log.Add('inner SaveAsXml=' + Format(CurrQuery.SaveAsXml(OutS)) + ' length=' + Format(TempBlob.Length()));
                end;
            3:
                begin
                    CurrQuery.Close();
                    Log.Add('inner Close returned');
                end;
            4:
                Log.Add('inner Read=' + Format(CurrQuery.Read()));
        end;
    end;

    var
        Log: Codeunit "LT CH Q Log";
        Depth: Integer;
}

codeunit 84523 "LT CH Q Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        CurrentMode: Integer;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    procedure SetMode(NewMode: Integer)
    begin
        CurrentMode := NewMode;
    end;

    procedure Mode(): Integer
    begin
        exit(CurrentMode);
    end;
}

codeunit 84524 "LT CH Query Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Log: Codeunit "LT CH Q Log";
        Q: Query "LT CH Q Rows";
        Rows: Text;

    local procedure Seed()
    var
        R: Record "LT CH Q Row";
    begin
        R.DeleteAll();
        R.Id := 1; R.Grp := 'A'; R.Insert();
        R.Id := 2; R.Grp := 'A'; R.Insert();
        R.Id := 3; R.Grp := 'B'; R.Insert();
        R.Id := 4; R.Grp := 'B'; R.Insert();
        Clear(Q);
        Log.Take();
        Log.SetMode(0);
    end;

    [TryFunction]
    local procedure TryReadAll()
    begin
        Rows := '';
        while Q.Read() do
            Rows += Format(Q.Id) + ',';
    end;

    [TryFunction]
    local procedure TryReadOne()
    begin
        Rows := '';
        if Q.Read() then
            Rows := Format(Q.Id)
        else
            Rows := 'false';
    end;

    [TryFunction]
    local procedure TryOpen()
    begin
        Q.Open();
    end;

    local procedure Step(Name: Text; Ok: Boolean)
    begin
        if Ok then
            Obs.Observe(Name, 'ok')
        else begin
            Obs.Observe(Name, GetLastErrorText());
            ClearLastError();
        end;
    end;

    // Item 113: Clear while the query is open and one row was read; then a filter on the other group, Open, Read.
    [Test]
    procedure Clear_WhileOpen_SecondCycleReturnsTheSecondFilter()
    begin
        Seed();
        Q.SetRange(Grp, 'A');
        Q.Open();
        Step('read1', TryReadOne());
        Obs.Observe('read1.rows', Rows);
        Clear(Q);
        Obs.Observe('filters after clear', Q.GetFilters());
        Step('read after clear', TryReadOne());
        Obs.Observe('read after clear.rows', Rows);
        Q.SetRange(Grp, 'B');
        Step('open2', TryOpen());
        Step('read2', TryReadAll());
        Obs.Observe('read2.rows', Rows);
        Obs.Observe('filters2', Q.GetFilters());
        Obs.Expect('read1', 'ok');
        Obs.Expect('read1.rows', '1');
        Obs.Expect('filters after clear', '');
        Obs.Expect('read after clear', 'ok');
        Obs.Expect('read after clear.rows', 'false');
        Obs.Expect('open2', 'ok');
        Obs.Expect('read2', 'ok');
        Obs.Expect('read2.rows', '3,4,');
        Obs.Expect('filters2', 'Grp: B');
        Obs.Verify();
    end;

    // Item 113: the same cycle without Clear: Close, SetRange on the other group, Open, Read.
    [Test]
    procedure Close_SecondCycleWithoutClear()
    begin
        Seed();
        Q.SetRange(Grp, 'A');
        Q.Open();
        Step('read1', TryReadOne());
        Obs.Observe('read1.rows', Rows);
        Q.Close();
        Q.SetRange(Grp, 'B');
        Step('open2', TryOpen());
        Step('read2', TryReadAll());
        Obs.Observe('read2.rows', Rows);
        Obs.Observe('filters2', Q.GetFilters());
        Obs.Expect('read1', 'ok');
        Obs.Expect('read1.rows', '1');
        Obs.Expect('open2', 'ok');
        Obs.Expect('read2', 'ok');
        Obs.Expect('read2.rows', '3,4,');
        Obs.Expect('filters2', 'Grp: B');
        Obs.Verify();
    end;

    local procedure SelfOpen(NewMode: Integer)
    var
        S: Query "LT CH Q Self";
    begin
        Seed();
        Log.SetMode(NewMode);
        Rows := '';
        if TrySelfOpenRead(S) then
            Obs.Observe('open', 'ok')
        else begin
            Obs.Observe('open', GetLastErrorText());
            Obs.Observe('open code', GetLastErrorCode());
            ClearLastError();
        end;
        Obs.Observe('rows', Rows);
        Obs.Observe('log', Log.Take());
        Log.SetMode(0);
    end;

    [TryFunction]
    local procedure TrySelfOpenRead(var S: Query "LT CH Q Self")
    begin
        S.Open();
        while S.Read() do
            Rows += Format(S.Id) + ',';
    end;

    // Item 114: CurrQuery.Open inside OnBeforeOpen.
    [Test]
    procedure OnBeforeOpen_CallsOpen()
    begin
        SelfOpen(1);
        Obs.Expect('open', 'It is not possible to execute the current query from within the ''OnBeforeOpen'' trigger.');
        Obs.Expect('open code', 'QueryIllegalCallInTrigger');
        Obs.Expect('rows', '');
        Obs.Expect('log', 'OnBeforeOpen depth=1;');
        Obs.Verify();
    end;

    // Item 114: CurrQuery.SaveAsXml inside OnBeforeOpen.
    [Test]
    procedure OnBeforeOpen_CallsSaveAsXml()
    begin
        SelfOpen(2);
        Obs.Expect('open', 'ok');
        Obs.Expect('rows', '1,2,3,4,');
        Obs.Expect('log', 'OnBeforeOpen depth=1;inner SaveAsXml=No length=740;');
        Obs.Verify();
    end;

    // Item 114: CurrQuery.Close inside OnBeforeOpen.
    [Test]
    procedure OnBeforeOpen_CallsClose()
    begin
        SelfOpen(3);
        Obs.Expect('open', 'It is not possible to execute the current query from within the ''OnBeforeOpen'' trigger.');
        Obs.Expect('open code', 'QueryIllegalCallInTrigger');
        Obs.Expect('rows', '');
        Obs.Expect('log', 'OnBeforeOpen depth=1;');
        Obs.Verify();
    end;

    // Item 114: CurrQuery.Read inside OnBeforeOpen.
    [Test]
    procedure OnBeforeOpen_CallsRead()
    begin
        SelfOpen(4);
        Obs.Expect('open', 'ok');
        Obs.Expect('rows', '1,2,3,4,');
        Obs.Expect('log', 'OnBeforeOpen depth=1;inner Read=No;');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TrySaveXml(var TempBlob: Codeunit "Temp Blob"; var Ok: Boolean)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Ok := Q.SaveAsXml(OutS);
    end;

    local procedure ObserveSave(Name: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Xml: Text;
        Line: Text;
        Ok: Boolean;
    begin
        Step(Name, TrySaveXml(TempBlob, Ok));
        Obs.Observe(Name + '.result', Format(Ok));
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line.Trim();
        end;
        if Xml.IndexOf('</xs:schema>') > 0 then
            Xml := CopyStr(Xml, Xml.IndexOf('</xs:schema>') + StrLen('</xs:schema>'));
        Obs.Observe(Name + '.xml', Xml);
    end;

    // Item 116: SaveAsXml after Open and one Read, then Read again.
    [Test]
    procedure SaveAsXml_AfterOpenAndOneRead_ThenRead()
    begin
        Seed();
        Q.SetRange(Grp, 'B');
        Q.Open();
        Step('read1', TryReadOne());
        Obs.Observe('read1.rows', Rows);
        ObserveSave('save');
        Step('read2', TryReadOne());
        Obs.Observe('read2.rows', Rows);
        Step('read rest', TryReadAll());
        Obs.Observe('read rest.rows', Rows);
        Obs.Expect('read1', 'ok');
        Obs.Expect('read1.rows', '3');
        Obs.Expect('save', 'ok');
        Obs.Expect('save.result', 'Yes');
        Obs.Expect('save.xml', '<Result><Id>3</Id><Grp>B</Grp></Result><Result><Id>4</Id><Grp>B</Grp></Result></DataSet>');
        Obs.Expect('read2', 'ok');
        Obs.Expect('read2.rows', 'false');
        Obs.Expect('read rest', 'ok');
        Obs.Expect('read rest.rows', '');
        Obs.Verify();
    end;

    // Item 116: SaveAsXml without Open, then Read without Open.
    [Test]
    procedure SaveAsXml_WithoutOpen_ThenRead()
    begin
        Seed();
        Q.SetRange(Grp, 'A');
        ObserveSave('save');
        Step('read1', TryReadOne());
        Obs.Observe('read1.rows', Rows);
        Obs.Expect('save', 'ok');
        Obs.Expect('save.result', 'Yes');
        Obs.Expect('save.xml', '<Result><Id>1</Id><Grp>A</Grp></Result><Result><Id>2</Id><Grp>A</Grp></Result></DataSet>');
        Obs.Expect('read1', 'ok');
        Obs.Expect('read1.rows', 'false');
        Obs.Verify();
    end;

    // Item 116: SaveAsXml twice on one open query.
    [Test]
    procedure SaveAsXml_Twice()
    begin
        Seed();
        Q.SetRange(Grp, 'A');
        Q.Open();
        ObserveSave('save1');
        ObserveSave('save2');
        Obs.Expect('save1', 'ok');
        Obs.Expect('save1.result', 'Yes');
        Obs.Expect('save1.xml', '<Result><Id>1</Id><Grp>A</Grp></Result><Result><Id>2</Id><Grp>A</Grp></Result></DataSet>');
        Obs.Expect('save2', 'ok');
        Obs.Expect('save2.result', 'Yes');
        Obs.Expect('save2.xml', '<Result><Id>1</Id><Grp>A</Grp></Result><Result><Id>2</Id><Grp>A</Grp></Result></DataSet>');
        Obs.Verify();
    end;
}
