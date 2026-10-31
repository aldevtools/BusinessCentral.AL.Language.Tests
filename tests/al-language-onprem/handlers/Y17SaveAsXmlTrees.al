// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-saveasxml-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath)
// Fixtures used: Probe Observer (69160), tables "LT TO RP Parent" (98060) and "LT TO RP Child" (98061) of ToRpSaveAsXmlDataItems.al; own tables
//   98625, 98626, reports 98627 - 98633, test codeunit 98634 (writer Y17, gap cycle 1 G1)
// Probe: the report data file that TestRequestPage.SaveAsXml writes for data item trees the TO_* tests do not cover: three levels with a
//   middle row that has no grandchild (A3), one parent with two child items (B2), a parent without columns over a child without columns
//   and an Integer loop with columns (B0, the Planning Availability shape), a nested parent followed by a second top item (C1), no row at
//   all (D1), a nested parent whose child gets no row followed by a second top item (D2), a second child that Breaks in OnPreDataItem (B3).
//   Lines of the file are joined with '|' and the leading spaces of each line are dropped (Compact).
// BC versions: 27, 28, 29

table 98625 "LT Y17 RP Grandchild"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ParentId; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; SubNo; Integer) { }
        field(4; Note; Text[30]) { }
    }

    keys
    {
        key(PK; ParentId, LineNo, SubNo) { Clustered = true; }
    }
}

table 98626 "LT Y17 RP Detail"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ParentId; Integer) { }
        field(2; No; Integer) { }
        field(3; Tag; Text[30]) { }
    }

    keys
    {
        key(PK; ParentId, No) { Clustered = true; }
    }
}

report 98627 "LT Y17 RP Three Levels"
{
    UsageCategory = None;

    dataset
    {
        dataitem(P; "LT TO RP Parent")
        {
            column(PId; Id) { }
            column(PName; Name) { }
            dataitem(C; "LT TO RP Child")
            {
                DataItemLink = ParentId = field(Id);
                column(CLine; LineNo) { }
                column(CQty; Qty) { }
                dataitem(G; "LT Y17 RP Grandchild")
                {
                    DataItemLink = ParentId = field(ParentId), LineNo = field(LineNo);
                    column(GSub; SubNo) { }
                    column(GNote; Note) { }
                }
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MarkField; Mark) { ApplicationArea = All; }
            }
        }
    }

    var
        Mark: Integer;
}

report 98628 "LT Y17 RP Two Children"
{
    UsageCategory = None;

    dataset
    {
        dataitem(P; "LT TO RP Parent")
        {
            column(PId; Id) { }
            column(PName; Name) { }
            dataitem(C; "LT TO RP Child")
            {
                DataItemLink = ParentId = field(Id);
                column(CLine; LineNo) { }
                column(CQty; Qty) { }
            }
            dataitem(D; "LT Y17 RP Detail")
            {
                DataItemLink = ParentId = field(Id);
                column(DNo; No) { }
                column(DTag; Tag) { }
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MarkField; Mark) { ApplicationArea = All; }
            }
        }
    }

    var
        Mark: Integer;
}

report 98629 "LT Y17 RP No Column Parent"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Top; Integer)
        {
            DataItemTableView = where(Number = const(1));
            dataitem(C; "LT TO RP Child")
            {
            }
            dataitem(Loop; Integer)
            {
                DataItemTableView = where(Number = filter(1 ..));
                column(LNum; Number) { }
                column(LText; LoopText) { }

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, 2);
                end;

                trigger OnAfterGetRecord()
                begin
                    LoopText := 'n' + Format(Number);
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MarkField; Mark) { ApplicationArea = All; }
            }
        }
    }

    var
        Mark: Integer;
        LoopText: Text;

}

report 98630 "LT Y17 RP Nested And Top"
{
    UsageCategory = None;

    dataset
    {
        dataitem(P; "LT TO RP Parent")
        {
            column(PId; Id) { }
            column(PName; Name) { }
            dataitem(C; "LT TO RP Child")
            {
                DataItemLink = ParentId = field(Id);
                column(CLine; LineNo) { }
                column(CQty; Qty) { }
            }
        }
        dataitem(T; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(TTotal; Total) { }

            trigger OnAfterGetRecord()
            begin
                Total := 42;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MarkField; Mark) { ApplicationArea = All; }
            }
        }
    }

    var
        Mark: Integer;
        Total: Integer;

}

report 98631 "LT Y17 RP No Row"
{
    UsageCategory = None;

    dataset
    {
        dataitem(P; "LT TO RP Parent")
        {
            column(PId; Id) { }
            column(PName; Name) { }

            trigger OnPreDataItem()
            begin
                SetRange(Id, 999);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MarkField; Mark) { ApplicationArea = All; }
            }
        }
    }

    var
        Mark: Integer;
}

report 98632 "LT Y17 RP Sibling Empty Child"
{
    UsageCategory = None;

    dataset
    {
        dataitem(P; "LT TO RP Parent")
        {
            column(PId; Id) { }
            column(PName; Name) { }
            dataitem(C; "LT TO RP Child")
            {
                DataItemLink = ParentId = field(Id);
                column(CLine; LineNo) { }
                column(CQty; Qty) { }

                trigger OnPreDataItem()
                begin
                    SetRange(LineNo, -1);
                end;
            }
        }
        dataitem(D2Top; "LT Y17 RP Detail")
        {
            column(DNo; No) { }
            column(DTag; Tag) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MarkField; Mark) { ApplicationArea = All; }
            }
        }
    }

    var
        Mark: Integer;
}

report 98633 "LT Y17 RP Second Child Breaks"
{
    UsageCategory = None;

    dataset
    {
        dataitem(P; "LT TO RP Parent")
        {
            column(PId; Id) { }
            column(PName; Name) { }
            dataitem(C; "LT TO RP Child")
            {
                DataItemLink = ParentId = field(Id);
                column(CLine; LineNo) { }
                column(CQty; Qty) { }
            }
            dataitem(D; "LT Y17 RP Detail")
            {
                DataItemLink = ParentId = field(Id);
                column(DNo; No) { }
                column(DTag; Tag) { }

                trigger OnPreDataItem()
                begin
                    CurrReport.Break();
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MarkField; Mark) { ApplicationArea = All; }
            }
        }
    }

    var
        Mark: Integer;
}
codeunit 98634 "LT Y17 RP SaveAsXml Trees"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ParametersFile: Text;
        DataFile: Text;

    local procedure Seed()
    var
        P: Record "LT TO RP Parent";
        C: Record "LT TO RP Child";
        G: Record "LT Y17 RP Grandchild";
        D: Record "LT Y17 RP Detail";
    begin
        P.DeleteAll();
        C.DeleteAll();
        G.DeleteAll();
        D.DeleteAll();
        P.Id := 2;
        P.Name := '';
        P.Insert();
        P.Id := 1;
        P.Name := 'a';
        P.Insert();
        P.Id := 3;
        P.Name := 'c';
        P.Insert();
        AddChild(1, 20, 2);
        AddChild(1, 10, 1.5);
        AddChild(3, 10, 0);
        AddGrandchild(1, 10, 2, 'y');
        AddGrandchild(1, 10, 1, 'x');
        AddGrandchild(3, 10, 1, 'z');
        D.ParentId := 1;
        D.No := 1;
        D.Tag := 'd1';
        D.Insert();
        D.ParentId := 2;
        D.No := 1;
        D.Tag := 'd2';
        D.Insert();
        Commit();
        ParametersFile := TemporaryPath() + 'lt-y17-params.xml';
        DataFile := TemporaryPath() + 'lt-y17-data.xml';
        if Exists(ParametersFile) then
            Erase(ParametersFile);
        if Exists(DataFile) then
            Erase(DataFile);
    end;

    local procedure AddChild(ParentId: Integer; LineNo: Integer; Qty: Decimal)
    var
        C: Record "LT TO RP Child";
    begin
        C.ParentId := ParentId;
        C.LineNo := LineNo;
        C.Qty := Qty;
        C.Insert();
    end;

    local procedure AddGrandchild(ParentId: Integer; LineNo: Integer; SubNo: Integer; Note: Text[30])
    var
        G: Record "LT Y17 RP Grandchild";
    begin
        G.ParentId := ParentId;
        G.LineNo := LineNo;
        G.SubNo := SubNo;
        G.Note := Note;
        G.Insert();
    end;

    local procedure FileText(Name: Text; var HadBom: Boolean): Text
    var
        SaveFile: File;
        InStr: InStream;
        Line: Text;
        Result: Text;
        Bom: Text[3];
    begin
        if not Exists(Name) then
            exit('<no file>');
        SaveFile.Open(Name);
        SaveFile.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line.TrimStart() + '|';
        end;
        SaveFile.Close();
        // The byte order mark reads as three characters (see FileText in TestRequestPageSaveAsXmlContracts.al).
        Bom[1] := 217;
        Bom[2] := 8249;
        Bom[3] := 143;
        HadBom := Result.StartsWith(Bom);
        if HadBom then
            Result := CopyStr(Result, 4);
        exit(Result);
    end;

    local procedure Split(Content: Text; var Schema: Text; var Rows: Text)
    var
        At: Integer;
    begin
        At := StrPos(Content, '</xs:schema>|');
        if At = 0 then begin
            Schema := Content;
            Rows := '';
            exit;
        end;
        Schema := CopyStr(Content, 1, At + StrLen('</xs:schema>|') - 1);
        Rows := CopyStr(Content, At + StrLen('</xs:schema>|'));
    end;

    // Only the part of the schema that lists the columns: the element names between <xs:sequence> and </xs:sequence>.
    local procedure Columns(Schema: Text): Text
    var
        From: Integer;
        Till: Integer;
    begin
        From := StrPos(Schema, '<xs:sequence>|');
        Till := StrPos(Schema, '</xs:sequence>');
        if (From = 0) or (Till = 0) then
            exit('<no sequence>');
        exit(CopyStr(Schema, From + StrLen('<xs:sequence>|'), Till - From - StrLen('<xs:sequence>|')));
    end;


    [RequestPageHandler]
    procedure A3Handler(var RP: TestRequestPage "LT Y17 RP Three Levels")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;


    [RequestPageHandler]
    procedure B2Handler(var RP: TestRequestPage "LT Y17 RP Two Children")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;


    [RequestPageHandler]
    procedure B0Handler(var RP: TestRequestPage "LT Y17 RP No Column Parent")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;


    [RequestPageHandler]
    procedure C1Handler(var RP: TestRequestPage "LT Y17 RP Nested And Top")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;


    [RequestPageHandler]
    procedure D1Handler(var RP: TestRequestPage "LT Y17 RP No Row")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;


    [RequestPageHandler]
    procedure D2Handler(var RP: TestRequestPage "LT Y17 RP Sibling Empty Child")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;


    [RequestPageHandler]
    procedure B3Handler(var RP: TestRequestPage "LT Y17 RP Second Child Breaks")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;


    [Test]
    [HandlerFunctions('A3Handler')]
    procedure Y17_SaveAsXml_A3_Schema()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP Three Levels");
        Observer.Observe('data file exists', Format(Exists(DataFile)));
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('bom', Format(HadBom));
        Observer.Observe('schema head', CopyStr(Schema, 1, StrPos(Schema + '<xs:sequence>', '<xs:sequence>') - 1));
        Observer.Observe('columns', Columns(Schema));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('A3Handler')]
    procedure Y17_SaveAsXml_A3_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP Three Levels");
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;


    [Test]
    [HandlerFunctions('B2Handler')]
    procedure Y17_SaveAsXml_B2_Schema()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP Two Children");
        Observer.Observe('data file exists', Format(Exists(DataFile)));
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('bom', Format(HadBom));
        Observer.Observe('schema head', CopyStr(Schema, 1, StrPos(Schema + '<xs:sequence>', '<xs:sequence>') - 1));
        Observer.Observe('columns', Columns(Schema));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('B2Handler')]
    procedure Y17_SaveAsXml_B2_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP Two Children");
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;


    [Test]
    [HandlerFunctions('B0Handler')]
    procedure Y17_SaveAsXml_B0_Schema()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP No Column Parent");
        Observer.Observe('data file exists', Format(Exists(DataFile)));
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('bom', Format(HadBom));
        Observer.Observe('schema head', CopyStr(Schema, 1, StrPos(Schema + '<xs:sequence>', '<xs:sequence>') - 1));
        Observer.Observe('columns', Columns(Schema));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('B0Handler')]
    procedure Y17_SaveAsXml_B0_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP No Column Parent");
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;


    [Test]
    [HandlerFunctions('C1Handler')]
    procedure Y17_SaveAsXml_C1_Schema()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP Nested And Top");
        Observer.Observe('data file exists', Format(Exists(DataFile)));
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('bom', Format(HadBom));
        Observer.Observe('schema head', CopyStr(Schema, 1, StrPos(Schema + '<xs:sequence>', '<xs:sequence>') - 1));
        Observer.Observe('columns', Columns(Schema));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('C1Handler')]
    procedure Y17_SaveAsXml_C1_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP Nested And Top");
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;


    [Test]
    [HandlerFunctions('D1Handler')]
    procedure Y17_SaveAsXml_D1_Schema()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP No Row");
        Observer.Observe('data file exists', Format(Exists(DataFile)));
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('bom', Format(HadBom));
        Observer.Observe('schema head', CopyStr(Schema, 1, StrPos(Schema + '<xs:sequence>', '<xs:sequence>') - 1));
        Observer.Observe('columns', Columns(Schema));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('D1Handler')]
    procedure Y17_SaveAsXml_D1_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP No Row");
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;


    [Test]
    [HandlerFunctions('D2Handler')]
    procedure Y17_SaveAsXml_D2_Schema()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP Sibling Empty Child");
        Observer.Observe('data file exists', Format(Exists(DataFile)));
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('bom', Format(HadBom));
        Observer.Observe('schema head', CopyStr(Schema, 1, StrPos(Schema + '<xs:sequence>', '<xs:sequence>') - 1));
        Observer.Observe('columns', Columns(Schema));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('D2Handler')]
    procedure Y17_SaveAsXml_D2_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP Sibling Empty Child");
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;


    [Test]
    [HandlerFunctions('B3Handler')]
    procedure Y17_SaveAsXml_B3_Schema()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP Second Child Breaks");
        Observer.Observe('data file exists', Format(Exists(DataFile)));
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('bom', Format(HadBom));
        Observer.Observe('schema head', CopyStr(Schema, 1, StrPos(Schema + '<xs:sequence>', '<xs:sequence>') - 1));
        Observer.Observe('columns', Columns(Schema));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('B3Handler')]
    procedure Y17_SaveAsXml_B3_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        Seed();
        Report.Run(Report::"LT Y17 RP Second Child Breaks");
        Split(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;

}
