// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-occurrence-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Temp Blob (System Application); own tables 87740, 87741, 87742
// Probe (writer RA, 2026-10-22):
//   1. fieldattribute Occurrence = Optional / Required on EXPORT with an empty value (Text, Code, Integer 0, Date 0D, Boolean false).
//      The import side is AgXmlPortImport.al FieldAttribute_Occurrence_RequiredAndOptional_Import; a fieldattribute without Occurrence and an
//      empty Text exports as attr="" (AtXmlPortFieldElementEdges.al:205); textattribute Occurrence on export: QrXpContainerOccurs.al:474.
//   2. A requestpage with only Caption = '...' and empty layout and actions: static and instance Import and Export. The same shape without
//      Caption is AgXmlPortImport.al RequestPage_EmptySection_ImportAndExport (empty requestpage { }).
//   3. Export of a temporary tableelement with SourceTableView = sorting(B) (no where) over three rows whose B order differs from the primary key
//      order; the same with order(descending); no SourceTableView (control); SetTableView with another key on the port (which wins); and the
//      same view on a temporary child element linked to a parent element. AgXmlPortImport.al TableElement_SourceTableView_Export exports one row only.
// Facts (CI 27.5, 28.5, 29.0, the same): an Optional fieldattribute is left out when its value is an empty Text, Code or Date, but written for
//   Integer 0 ("0") and Boolean false ("No"); a Required one is always written (attr=""). A Caption in the requestpage changes nothing
//   (Import and Export, static and instance, all succeed). SourceTableView = sorting(B) orders the exported temporary rows by B, order(descending)
//   reverses it, without a view the order is the primary key; SetTableView with another key does not change that order (sorting(B) stays), a
//   filter from SetTableView applies; a linked temporary child element keeps sorting(B) within each parent row.
// Writer RD (DemoTool round 2, export half of "Imp / Exp Data Exch Def & Map"): a linked non-temporary child tableelement exports in the order of
//   its SourceTableView key within each parent; a where(...) part filters it; a where on the link field keeps only the matching parent's rows;
//   Xmlport.Export with a record filters the top element; a parent with no rows gives an empty element (MinOccurs = Zero).
// BC versions: 27, 28, 29

table 87740 "LT RA XP Occ Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Cd; Code[20]) { }
        field(4; Num; Integer) { }
        field(5; Dt; Date) { }
        field(6; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 87741 "LT RA XP Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; HeadId; Integer) { }
        field(3; B; Code[10]) { }
        field(4; Seq; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByB; B) { }
        key(BySeq; Seq) { }
    }
}

table 87742 "LT RA XP Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 87743 "LT RA XP Occ Export"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT RA XP Occ Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldattribute(OptTxt; Row.Txt) { Occurrence = Optional; }
                fieldattribute(ReqTxt; Row.Txt) { Occurrence = Required; }
                fieldattribute(OptCd; Row.Cd) { Occurrence = Optional; }
                fieldattribute(ReqCd; Row.Cd) { Occurrence = Required; }
                fieldattribute(OptNum; Row.Num) { Occurrence = Optional; }
                fieldattribute(ReqNum; Row.Num) { Occurrence = Required; }
                fieldattribute(OptDt; Row.Dt) { Occurrence = Optional; }
                fieldattribute(ReqDt; Row.Dt) { Occurrence = Required; }
                fieldattribute(OptFlag; Row.Flag) { Occurrence = Optional; }
                fieldattribute(ReqFlag; Row.Flag) { Occurrence = Required; }
            }
        }
    }
}

xmlport 87744 "LT RA XP RP Caption"
{
    Direction = Both;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT RA XP Occ Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Txt; Row.Txt) { }
            }
        }
    }

    requestpage
    {
        Caption = 'Some caption';

        layout
        {
        }

        actions
        {
        }
    }
}

xmlport 87745 "LT RA XP View Sorting"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Line; "LT RA XP Line")
            {
                UseTemporary = true;
                SourceTableView = sorting(B);
                fieldattribute(Id; Line.Id) { }
                fieldattribute(B; Line.B) { }
            }
        }
    }

    procedure AddLine(NewId: Integer; NewB: Code[10]; NewSeq: Integer)
    begin
        Line.Init();
        Line.Id := NewId;
        Line.B := NewB;
        Line.Seq := NewSeq;
        Line.Insert();
    end;
}

xmlport 87746 "LT RA XP View Descending"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Line; "LT RA XP Line")
            {
                UseTemporary = true;
                SourceTableView = sorting(B) order(descending);
                fieldattribute(Id; Line.Id) { }
                fieldattribute(B; Line.B) { }
            }
        }
    }

    procedure AddLine(NewId: Integer; NewB: Code[10]; NewSeq: Integer)
    begin
        Line.Init();
        Line.Id := NewId;
        Line.B := NewB;
        Line.Seq := NewSeq;
        Line.Insert();
    end;
}

xmlport 87747 "LT RA XP View None"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Line; "LT RA XP Line")
            {
                UseTemporary = true;
                fieldattribute(Id; Line.Id) { }
                fieldattribute(B; Line.B) { }
            }
        }
    }

    procedure AddLine(NewId: Integer; NewB: Code[10]; NewSeq: Integer)
    begin
        Line.Init();
        Line.Id := NewId;
        Line.B := NewB;
        Line.Seq := NewSeq;
        Line.Insert();
    end;
}

xmlport 87748 "LT RA XP View Linked"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Head; "LT RA XP Head")
            {
                UseTemporary = true;
                fieldattribute(Id; Head.Id) { }
                tableelement(Line; "LT RA XP Line")
                {
                    UseTemporary = true;
                    LinkTable = Head;
                    LinkFields = HeadId = field(Id);
                    SourceTableView = sorting(B);
                    fieldattribute(Id; Line.Id) { }
                    fieldattribute(B; Line.B) { }
                }
            }
        }
    }

    procedure AddHead(NewId: Integer)
    begin
        Head.Init();
        Head.Id := NewId;
        Head.Insert();
    end;

    procedure AddLine(NewId: Integer; NewHeadId: Integer; NewB: Code[10])
    begin
        Line.Init();
        Line.Id := NewId;
        Line.HeadId := NewHeadId;
        Line.B := NewB;
        Line.Insert();
    end;
}

// ---- Writer RD (Microsoft's DemoTool, round 2: the export half of Base Application xmlport "Imp / Exp Data Exch Def & Map", run by
// Create Data Exch. Column Def.ExportDataExchDef with a Data Exch. Def record): a non-temporary child tableelement linked to its parent
// (LinkTable, LinkFields, MinOccurs = Zero) with SourceTableView = sorting(<link field>, <second field>) of a secondary key, the same with a
// where(Type = const(...)) part, a where on the link field itself, and a grandchild linked on two fields. Tables 87920 to 87922,
// xmlports 87923 to 87926, tests RD_* in codeunit 87750. ----

table 87920 "LT RD XP Def"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 87921 "LT RD XP Line Def"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; DefCode; Code[20]) { }
        field(2; Code; Code[20]) { }
        field(3; Type; Option) { OptionMembers = Detail,Header,Footer; }
        field(4; ParentCode; Code[20]) { }
    }

    keys
    {
        key(PK; DefCode, Code) { Clustered = true; }
        key(ByParent; DefCode, ParentCode) { }
    }
}

table 87922 "LT RD XP Column Def"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; DefCode; Code[20]) { }
        field(2; LineCode; Code[20]) { }
        field(3; ColumnNo; Integer) { }
        field(4; Show; Boolean) { }
    }

    keys
    {
        key(PK; DefCode, LineCode, ColumnNo) { Clustered = true; }
    }
}

xmlport 87923 "LT RD XP Linked Sorting"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Def; "LT RD XP Def")
            {
                MinOccurs = Zero;
                fieldattribute(Code; Def.Code) { }
                tableelement(LineDef; "LT RD XP Line Def")
                {
                    LinkTable = Def;
                    LinkFields = DefCode = field(Code);
                    MinOccurs = Zero;
                    SourceTableView = sorting(DefCode, ParentCode);
                    fieldattribute(Code; LineDef.Code) { }
                    fieldattribute(Type; LineDef.Type) { }
                    fieldattribute(Parent; LineDef.ParentCode) { }
                    tableelement(ColDef; "LT RD XP Column Def")
                    {
                        LinkTable = LineDef;
                        LinkFields = DefCode = field(DefCode), LineCode = field(Code);
                        MinOccurs = Zero;
                        fieldattribute(No; ColDef.ColumnNo) { }
                    }
                }
            }
        }
    }
}

xmlport 87924 "LT RD XP Linked Where"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Def; "LT RD XP Def")
            {
                MinOccurs = Zero;
                fieldattribute(Code; Def.Code) { }
                tableelement(LineDef; "LT RD XP Line Def")
                {
                    LinkTable = Def;
                    LinkFields = DefCode = field(Code);
                    MinOccurs = Zero;
                    SourceTableView = sorting(DefCode, ParentCode) where(Type = const(Detail));
                    fieldattribute(Code; LineDef.Code) { }
                    fieldattribute(Type; LineDef.Type) { }
                    fieldattribute(Parent; LineDef.ParentCode) { }
                    tableelement(ColDef; "LT RD XP Column Def")
                    {
                        LinkTable = LineDef;
                        LinkFields = DefCode = field(DefCode), LineCode = field(Code);
                        MinOccurs = Zero;
                        SourceTableView = where(Show = const(true));
                        fieldattribute(No; ColDef.ColumnNo) { }
                    }
                }
            }
        }
    }
}

xmlport 87925 "LT RD XP Linked Where Link"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Def; "LT RD XP Def")
            {
                MinOccurs = Zero;
                fieldattribute(Code; Def.Code) { }
                tableelement(LineDef; "LT RD XP Line Def")
                {
                    LinkTable = Def;
                    LinkFields = DefCode = field(Code);
                    MinOccurs = Zero;
                    SourceTableView = where(DefCode = const('A'));
                    fieldattribute(Code; LineDef.Code) { }
                    fieldattribute(Type; LineDef.Type) { }
                    fieldattribute(Parent; LineDef.ParentCode) { }
                    tableelement(ColDef; "LT RD XP Column Def")
                    {
                        LinkTable = LineDef;
                        LinkFields = DefCode = field(DefCode), LineCode = field(Code);
                        MinOccurs = Zero;
                        fieldattribute(No; ColDef.ColumnNo) { }
                    }
                }
            }
        }
    }
}

xmlport 87926 "LT RD XP Linked None"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Def; "LT RD XP Def")
            {
                MinOccurs = Zero;
                fieldattribute(Code; Def.Code) { }
                tableelement(LineDef; "LT RD XP Line Def")
                {
                    LinkTable = Def;
                    LinkFields = DefCode = field(Code);
                    MinOccurs = Zero;
                    SourceTableView = sorting(DefCode, Code);
                    fieldattribute(Code; LineDef.Code) { }
                    fieldattribute(Type; LineDef.Type) { }
                    fieldattribute(Parent; LineDef.ParentCode) { }
                    tableelement(ColDef; "LT RD XP Column Def")
                    {
                        LinkTable = LineDef;
                        LinkFields = DefCode = field(DefCode), LineCode = field(Code);
                        MinOccurs = Zero;
                        fieldattribute(No; ColDef.ColumnNo) { }
                    }
                }
            }
        }
    }
}

codeunit 87749 "LT RA XP Import Runner"
{
    TableNo = "LT RA XP Occ Row";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Row><Id>10</Id><Txt>ten</Txt></Row></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"LT RA XP RP Caption", InS);
    end;
}

codeunit 87750 "LT RA XP Export Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure StaticExport(XmlportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlportId, OutS);
        exit(ReadAll(TempBlob));
    end;

    local procedure OccRows(): Text
    var
        Row: Record "LT RA XP Occ Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row.Txt + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure SeedOcc()
    var
        Row: Record "LT RA XP Occ Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Txt := 'two';
        Row.Cd := 'C2';
        Row.Num := 7;
        Row.Dt := DMY2Date(3, 4, 2025);
        Row.Flag := true;
        Row.Insert();
    end;

    [Test]
    procedure RA_FieldAttribute_Occurrence_Export_EmptyValues()
    begin
        SeedOcc();
        Observer.Observe('export', StaticExport(Xmlport::"LT RA XP Occ Export"));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row Id="1" ReqTxt="" ReqCd="" OptNum="0" ReqNum="0" ReqDt="" OptFlag="No" ReqFlag="No" />|  <Row Id="2" OptTxt="two" ReqTxt="two" OptCd="C2" ReqCd="C2" OptNum="7" ReqNum="7" OptDt="04/03/25" ReqDt="04/03/25" OptFlag="Yes" ReqFlag="Yes" />|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure RA_RequestPage_CaptionOnly_ImportAndExport()
    var
        Row: Record "LT RA XP Occ Row";
        Job: Record "LT RA XP Occ Row" temporary;
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT RA XP RP Caption";
        OutS: OutStream;
        InS: InStream;
    begin
        SeedOcc();
        Observer.Observe('export static', StaticExport(Xmlport::"LT RA XP RP Caption"));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        ClearLastError();
        Observer.Observe('export instance ok', Format(Port.Export()));
        Observer.Observe('export instance', ReadAll(TempBlob));
        // static import through Codeunit.Run, so an error is caught
        Job.Insert();
        Commit();
        ClearLastError();
        Observer.Observe('import static ok', Format(Codeunit.Run(Codeunit::"LT RA XP Import Runner", Job)));
        Observer.Observe('import static error', GetLastErrorText());
        Observer.Observe('import static rows', OccRows());
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Row><Id>11</Id><Txt>eleven</Txt></Row></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Clear(Port);
        Port.SetSource(InS);
        ClearLastError();
        Observer.Observe('import instance ok', Format(Port.Import()));
        Observer.Observe('import instance rows', OccRows());
        Row.DeleteAll();
        Observer.Expect('export static', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Txt />|  </Row>|  <Row>|    <Id>2</Id>|    <Txt>two</Txt>|  </Row>|</Root>|');
        Observer.Expect('export instance ok', 'Yes');
        Observer.Expect('export instance', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Txt />|  </Row>|  <Row>|    <Id>2</Id>|    <Txt>two</Txt>|  </Row>|</Root>|');
        Observer.Expect('import static ok', 'Yes');
        Observer.Expect('import static error', '');
        Observer.Expect('import static rows', '1:,2:two,10:ten,');
        Observer.Expect('import instance ok', 'Yes');
        Observer.Expect('import instance rows', '1:,2:two,10:ten,11:eleven,');
        Observer.Verify();
    end;

    local procedure ExportSorting(var Port: XmlPort "LT RA XP View Sorting"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Port.AddLine(1, 'C', 2);
        Port.AddLine(2, 'A', 3);
        Port.AddLine(3, 'B', 1);
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ReadAll(TempBlob));
    end;

    [Test]
    procedure RA_TempTableElement_SourceTableViewSorting_ExportOrder()
    var
        Sorting: XmlPort "LT RA XP View Sorting";
        Descending: XmlPort "LT RA XP View Descending";
        NoView: XmlPort "LT RA XP View None";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        // rows: Id 1 B=C Seq 2, Id 2 B=A Seq 3, Id 3 B=B Seq 1
        Observer.Observe('sorting(B)', ExportSorting(Sorting));
        Descending.AddLine(1, 'C', 2);
        Descending.AddLine(2, 'A', 3);
        Descending.AddLine(3, 'B', 1);
        TempBlob.CreateOutStream(OutS);
        Descending.SetDestination(OutS);
        Descending.Export();
        Observer.Observe('sorting(B) order(descending)', ReadAll(TempBlob));
        NoView.AddLine(1, 'C', 2);
        NoView.AddLine(2, 'A', 3);
        NoView.AddLine(3, 'B', 1);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        NoView.SetDestination(OutS);
        NoView.Export();
        Observer.Observe('no SourceTableView', ReadAll(TempBlob));
        Observer.Expect('sorting(B)', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line Id="2" B="A" />|  <Line Id="3" B="B" />|  <Line Id="1" B="C" />|</Root>|');
        Observer.Expect('sorting(B) order(descending)', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line Id="1" B="C" />|  <Line Id="3" B="B" />|  <Line Id="2" B="A" />|</Root>|');
        Observer.Expect('no SourceTableView', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line Id="1" B="C" />|  <Line Id="2" B="A" />|  <Line Id="3" B="B" />|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure RA_TempTableElement_SourceTableViewSorting_WithSetTableView()
    var
        SortingSeq: XmlPort "LT RA XP View Sorting";
        SortingSeqDesc: XmlPort "LT RA XP View Sorting";
        SortingFilter: XmlPort "LT RA XP View Sorting";
        ViewSeq: Record "LT RA XP Line";
        ViewSeqDesc: Record "LT RA XP Line";
        ViewFilter: Record "LT RA XP Line";
    begin
        ViewSeq.SetCurrentKey(Seq);
        SortingSeq.SetTableView(ViewSeq);
        Observer.Observe('SetTableView sorting(Seq)', ExportSorting(SortingSeq));
        ViewSeqDesc.SetCurrentKey(Seq);
        ViewSeqDesc.Ascending(false);
        SortingSeqDesc.SetTableView(ViewSeqDesc);
        Observer.Observe('SetTableView sorting(Seq) descending', ExportSorting(SortingSeqDesc));
        ViewFilter.SetRange(B, 'B', 'C');
        SortingFilter.SetTableView(ViewFilter);
        Observer.Observe('SetTableView filter only', ExportSorting(SortingFilter));
        Observer.Expect('SetTableView sorting(Seq)', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line Id="2" B="A" />|  <Line Id="3" B="B" />|  <Line Id="1" B="C" />|</Root>|');
        Observer.Expect('SetTableView sorting(Seq) descending', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line Id="2" B="A" />|  <Line Id="3" B="B" />|  <Line Id="1" B="C" />|</Root>|');
        Observer.Expect('SetTableView filter only', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Line Id="3" B="B" />|  <Line Id="1" B="C" />|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure RA_TempChildTableElement_Linked_SourceTableViewSorting_ExportOrder()
    var
        Port: XmlPort "LT RA XP View Linked";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Port.AddHead(1);
        Port.AddHead(2);
        Port.AddLine(1, 1, 'C');
        Port.AddLine(2, 2, 'B');
        Port.AddLine(3, 1, 'A');
        Port.AddLine(4, 2, 'A');
        Port.AddLine(5, 1, 'B');
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('linked sorting(B)', ReadAll(TempBlob));
        Observer.Expect('linked sorting(B)', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Head Id="1">|    <Line Id="3" B="A" />|    <Line Id="5" B="B" />|    <Line Id="1" B="C" />|  </Head>|  <Head Id="2">|    <Line Id="4" B="A" />|    <Line Id="2" B="B" />|  </Head>|</Root>|');
        Observer.Verify();
    end;

    // ---- Writer RD: linked non-temporary tableelements with SourceTableView on export (xmlports 87923 to 87926). ----

    local procedure RdSeed()
    var
        Def: Record "LT RD XP Def";
        LineDef: Record "LT RD XP Line Def";
        ColDef: Record "LT RD XP Column Def";
    begin
        RdWipe();
        Def.Code := 'A';
        Def.Insert();
        Def.Code := 'B';
        Def.Insert();
        Def.Code := 'C';
        Def.Insert();
        RdLine('A', 'L1', LineDef.Type::Footer, 'Z');
        RdLine('A', 'L2', LineDef.Type::Detail, 'M');
        RdLine('A', 'L3', LineDef.Type::Detail, '');
        RdLine('A', 'L4', LineDef.Type::Header, 'B');
        RdLine('B', 'L1', LineDef.Type::Detail, 'Q');
        RdLine('B', 'L2', LineDef.Type::Header, '');
        RdColumn('A', 'L2', 2, true);
        RdColumn('A', 'L2', 1, false);
        RdColumn('A', 'L3', 1, true);
        RdColumn('B', 'L1', 3, true);
        RdColumn('B', 'L2', 1, true);
    end;

    local procedure RdLine(DefCode: Code[20]; Code: Code[20]; LineType: Option; ParentCode: Code[20])
    var
        LineDef: Record "LT RD XP Line Def";
    begin
        LineDef.DefCode := DefCode;
        LineDef.Code := Code;
        LineDef.Type := LineType;
        LineDef.ParentCode := ParentCode;
        LineDef.Insert();
    end;

    local procedure RdColumn(DefCode: Code[20]; LineCode: Code[20]; ColumnNo: Integer; Show: Boolean)
    var
        ColDef: Record "LT RD XP Column Def";
    begin
        ColDef.DefCode := DefCode;
        ColDef.LineCode := LineCode;
        ColDef.ColumnNo := ColumnNo;
        ColDef.Show := Show;
        ColDef.Insert();
    end;

    local procedure RdWipe()
    var
        Def: Record "LT RD XP Def";
        LineDef: Record "LT RD XP Line Def";
        ColDef: Record "LT RD XP Column Def";
    begin
        Def.DeleteAll();
        LineDef.DeleteAll();
        ColDef.DeleteAll();
    end;

    local procedure RdExport(XmlportId: Integer; DefFilter: Text): Text
    var
        Def: Record "LT RD XP Def";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        if DefFilter = '' then
            Xmlport.Export(XmlportId, OutS)
        else begin
            Def.SetFilter(Code, DefFilter);
            Xmlport.Export(XmlportId, OutS, Def);
        end;
        Result := ReadAll(TempBlob);
        exit(Result.Replace('<?xml version="1.0" encoding="UTF-16" standalone="no"?>|', '<decl>|'));
    end;

    [Test]
    procedure RD_LinkedTableElement_SourceTableViewSorting_Export()
    begin
        RdSeed();
        Observer.Observe('sorting(DefCode, ParentCode)', RdExport(Xmlport::"LT RD XP Linked Sorting", ''));
        Observer.Observe('sorting(DefCode, Code)', RdExport(Xmlport::"LT RD XP Linked None", ''));
        RdWipe();
        Observer.Expect('sorting(DefCode, ParentCode)', '<decl>|<Root>|  <Def Code="A">|    <LineDef Code="L3" Type="Detail" Parent="">|      <ColDef No="1" />|    </LineDef>|    <LineDef Code="L4" Type="Header" Parent="B" />|    <LineDef Code="L2" Type="Detail" Parent="M">|      <ColDef No="1" />|      <ColDef No="2" />|    </LineDef>|    <LineDef Code="L1" Type="Footer" Parent="Z" />|  </Def>|  <Def Code="B">|    <LineDef Code="L2" Type="Header" Parent="">|      <ColDef No="1" />|    </LineDef>|    <LineDef Code="L1" Type="Detail" Parent="Q">|      <ColDef No="3" />|    </LineDef>|  </Def>|  <Def Code="C" />|</Root>|');
        Observer.Expect('sorting(DefCode, Code)', '<decl>|<Root>|  <Def Code="A">|    <LineDef Code="L1" Type="Footer" Parent="Z" />|    <LineDef Code="L2" Type="Detail" Parent="M">|      <ColDef No="1" />|      <ColDef No="2" />|    </LineDef>|    <LineDef Code="L3" Type="Detail" Parent="">|      <ColDef No="1" />|    </LineDef>|    <LineDef Code="L4" Type="Header" Parent="B" />|  </Def>|  <Def Code="B">|    <LineDef Code="L1" Type="Detail" Parent="Q">|      <ColDef No="3" />|    </LineDef>|    <LineDef Code="L2" Type="Header" Parent="">|      <ColDef No="1" />|    </LineDef>|  </Def>|  <Def Code="C" />|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure RD_LinkedTableElement_SourceTableViewWhere_Export()
    begin
        RdSeed();
        Observer.Observe('where(Type = const(Detail))', RdExport(Xmlport::"LT RD XP Linked Where", ''));
        Observer.Observe('where on the link field', RdExport(Xmlport::"LT RD XP Linked Where Link", ''));
        RdWipe();
        Observer.Expect('where(Type = const(Detail))', '<decl>|<Root>|  <Def Code="A">|    <LineDef Code="L3" Type="Detail" Parent="">|      <ColDef No="1" />|    </LineDef>|    <LineDef Code="L2" Type="Detail" Parent="M">|      <ColDef No="2" />|    </LineDef>|  </Def>|  <Def Code="B">|    <LineDef Code="L1" Type="Detail" Parent="Q">|      <ColDef No="3" />|    </LineDef>|  </Def>|  <Def Code="C" />|</Root>|');
        Observer.Expect('where on the link field', '<decl>|<Root>|  <Def Code="A">|    <LineDef Code="L1" Type="Footer" Parent="Z" />|    <LineDef Code="L2" Type="Detail" Parent="M">|      <ColDef No="1" />|      <ColDef No="2" />|    </LineDef>|    <LineDef Code="L3" Type="Detail" Parent="">|      <ColDef No="1" />|    </LineDef>|    <LineDef Code="L4" Type="Header" Parent="B" />|  </Def>|  <Def Code="B" />|  <Def Code="C" />|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure RD_LinkedTableElement_SourceTableView_ExportWithRecord()
    begin
        RdSeed();
        Observer.Observe('sorting, record B', RdExport(Xmlport::"LT RD XP Linked Sorting", 'B'));
        Observer.Observe('where, record A|C', RdExport(Xmlport::"LT RD XP Linked Where", 'A|C'));
        Observer.Observe('where on the link field, record B', RdExport(Xmlport::"LT RD XP Linked Where Link", 'B'));
        Observer.Observe('sorting, record D (no row)', RdExport(Xmlport::"LT RD XP Linked Sorting", 'D'));
        RdWipe();
        Observer.Expect('sorting, record B', '<decl>|<Root>|  <Def Code="B">|    <LineDef Code="L2" Type="Header" Parent="">|      <ColDef No="1" />|    </LineDef>|    <LineDef Code="L1" Type="Detail" Parent="Q">|      <ColDef No="3" />|    </LineDef>|  </Def>|</Root>|');
        Observer.Expect('where, record A|C', '<decl>|<Root>|  <Def Code="A">|    <LineDef Code="L3" Type="Detail" Parent="">|      <ColDef No="1" />|    </LineDef>|    <LineDef Code="L2" Type="Detail" Parent="M">|      <ColDef No="2" />|    </LineDef>|  </Def>|  <Def Code="C" />|</Root>|');
        Observer.Expect('where on the link field, record B', '<decl>|<Root>|  <Def Code="B" />|</Root>|');
        Observer.Expect('sorting, record D (no row)', '<decl>|<Root />|');
        Observer.Verify();
    end;
}
