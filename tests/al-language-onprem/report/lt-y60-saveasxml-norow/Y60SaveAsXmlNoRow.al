// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-saveasxml-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath)
// Fixtures used: Probe Observer (codeunit 69160); own tables 98706-98707, enum 98706, reports 98706-98708, codeunits 98706-98707 (writer Y60, gap cycle 6 spec G6-08)
// Probe: the type of a column in the report data file of TestRequestPage.SaveAsXml (a .NET DataSet) when the data item writes no row,
//        for the columns report/lt-y51-saveasxml-time/Y51SaveAsXmlTime.al and report/lt-aq/AqSaveAsXml.al do not cover: Option and Enum
//        table fields, and expression columns (a global of each simple type, Option and Enum globals, an element of a Text array indexed by
//        Number, fields read through a global record variable) in an Integer data item whose OnPreDataItem sets SetRange(Number, 1, N)
//        with N = 0; the same with rows; a 0 Option and the first Enum value; a nested data item with no row below one with rows.
// BC versions: 27, 28, 29

table 98706 "LT Y60 OP Kind Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = A,B,C; }
        field(3; Cat; Enum "LT Y60 OP Cat") { }
        field(4; Cd; Code[10]) { }
        field(5; Tx; Text[20]) { }
        field(6; N; Integer) { }
        field(7; Dc; Decimal) { }
        field(8; Bo; Boolean) { }
        field(9; Dt; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 98707 "LT Y60 OP Kind Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Row Id"; Integer) { }
        field(2; "Line No."; Integer) { }
        field(3; Status; Option) { OptionMembers = Open,Closed; }
        field(4; Cat; Enum "LT Y60 OP Cat") { }
    }

    keys
    {
        key(PK; "Row Id", "Line No.") { Clustered = true; }
    }
}

enum 98706 "LT Y60 OP Cat"
{
    Extensible = false;

    value(0; X) { }
    value(1; Y) { }
}

codeunit 98707 "LT Y60 OP Count"
{
    SingleInstance = true;

    var
        Cnt: Integer;

    procedure Set(NewCnt: Integer)
    begin
        Cnt := NewCnt;
    end;

    procedure Get(): Integer
    begin
        exit(Cnt);
    end;
}

report 98706 "LT Y60 OP Kind Fields"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Item; "LT Y60 OP Kind Row")
        {
            column(KindC; Kind) { }
            column(CatC; Cat) { }
            column(CdC; Cd) { }
            column(TxC; Tx) { }
            column(NC; N) { }
            column(DcC; Dc) { }
            column(BoC; Bo) { }
            column(DtC; Dt) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; Ctl) { ApplicationArea = All; }
            }
        }
    }

    var
        Ctl: Integer;
}

report 98707 "LT Y60 OP Kind Exprs"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Loop; Integer)
        {
            DataItemTableView = sorting(Number);
            column(VarCode; GCode) { }
            column(VarText; GText) { }
            column(VarInt; GInt) { }
            column(VarDec; GDec) { }
            column(VarBool; GBool) { }
            column(VarDate; GDate) { }
            column(VarOpt; GOpt) { }
            column(VarEnum; GEnum) { }
            column(Arr; GArr[Number]) { }
            column(RecField; GRec.Cd) { }
            column(RecOpt; GRec.Kind) { }
            column(RecEnum; GRec.Cat) { }

            trigger OnPreDataItem()
            begin
                Loop.SetRange(Number, 1, Counter.Get());
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; Ctl) { ApplicationArea = All; }
            }
        }
    }

    trigger OnPreReport()
    begin
        GCode := 'CD1';
        GText := 'text one';
        GInt := 7;
        GDec := 2.5;
        GBool := true;
        GDate := DMY2Date(15, 3, 2024);
        GOpt := GOpt::Second;
        GEnum := GEnum::Y;
        GArr[1] := 'first';
        GArr[2] := 'second';
        GArr[3] := 'third';
        GRec.Cd := 'RC';
        GRec.Kind := GRec.Kind::C;
        GRec.Cat := GRec.Cat::Y;
    end;

    var
        Counter: Codeunit "LT Y60 OP Count";
        Ctl: Integer;
        GCode: Code[10];
        GText: Text;
        GInt: Integer;
        GDec: Decimal;
        GBool: Boolean;
        GDate: Date;
        GOpt: Option First,Second,Third;
        GEnum: Enum "LT Y60 OP Cat";
        GArr: array[3] of Text[20];
        GRec: Record "LT Y60 OP Kind Row";
}

report 98708 "LT Y60 OP Kind Nested"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Item; "LT Y60 OP Kind Row")
        {
            column(IdC; Id) { }
            column(KindC; Kind) { }
            column(CatC; Cat) { }
            dataitem(Child; "LT Y60 OP Kind Child")
            {
                DataItemLink = "Row Id" = field(Id);
                column(StatusC; Status) { }
                column(ChildCatC; Cat) { }
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; Ctl) { ApplicationArea = All; }
            }
        }
    }

    var
        Ctl: Integer;
}

codeunit 98706 "LT Y60 OP SaveAsXml NoRow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Counter: Codeunit "LT Y60 OP Count";
        ParametersFile: Text;
        DataFile: Text;

    local procedure Prepare()
    begin
        Commit();
        ParametersFile := TemporaryPath() + 'lt-y60-params.xml';
        DataFile := TemporaryPath() + 'lt-y60-data.xml';
        if Exists(ParametersFile) then
            Erase(ParametersFile);
        if Exists(DataFile) then
            Erase(DataFile);
    end;

    // The file as text, lines joined by |, without the byte order mark.
    local procedure FileText(Name: Text): Text
    var
        SaveFile: File;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        SaveFile.Open(Name);
        SaveFile.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        SaveFile.Close();
        exit(CopyStr(Result, 4));
    end;

    local procedure Columns(Content: Text): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Content.Split('|') do
            if Line.Contains(' type="') then
                Result += Line.Trim().Replace(' minOccurs="0" />', '') + '|';
        exit(Result);
    end;

    local procedure Rows(Content: Text): Text
    var
        Line: Text;
        Result: Text;
        After: Boolean;
    begin
        foreach Line in Content.Split('|') do begin
            if After then
                Result += Line.Trim() + '|';
            if Line.Contains('</xs:schema>') then
                After := true;
        end;
        exit(Result);
    end;

    local procedure InsertRow(Id: Integer; Kind: Option A,B,C; Cat: Enum "LT Y60 OP Cat")
    var
        Row: Record "LT Y60 OP Kind Row";
    begin
        Row.Id := Id;
        Row.Kind := Kind;
        Row.Cat := Cat;
        Row.Cd := 'C' + Format(Id);
        Row.Tx := 'text ' + Format(Id);
        Row.N := Id * 10;
        Row.Dc := Id + 0.25;
        Row.Bo := true;
        Row.Dt := DMY2Date(1, 2, 2024);
        Row.Insert();
    end;

    local procedure ObserveRun(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer)
    var
        Content: Text;
    begin
        Prepare();
        Report.Run(ReportId);
        Content := FileText(DataFile);
        Observer.Observe(Name + ' schema', Columns(Content));
        Observer.Observe(Name + ' rows', Rows(Content));
    end;

    [Test]
    [HandlerFunctions('FieldsHandler')]
    procedure Columns_TableFields_NoRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y60 OP Kind Row";
    begin
        Row.DeleteAll();
        ObserveRun(Observer, 'no row', Report::"LT Y60 OP Kind Fields");
        InsertRow(1, 1, "LT Y60 OP Cat"::Y);
        ObserveRun(Observer, 'one row', Report::"LT Y60 OP Kind Fields");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ExprsHandler')]
    procedure Columns_Expressions_NoRow()
    var
        Observer: Codeunit "Probe Observer";
        Content: Text;
    begin
        Counter.Set(0);
        Prepare();
        Report.Run(Report::"LT Y60 OP Kind Exprs");
        Content := FileText(DataFile);
        Observer.Observe('schema', Columns(Content));
        Observer.Observe('rows', Rows(Content));
        Observer.Observe('full', Content);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ExprsHandler')]
    procedure Columns_Expressions_WithRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Counter.Set(2);
        ObserveRun(Observer, 'two rows', Report::"LT Y60 OP Kind Exprs");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('FieldsHandler')]
    procedure Columns_OptionEnum_BlankAndNonBlank()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y60 OP Kind Row";
    begin
        Row.DeleteAll();
        InsertRow(1, 0, "LT Y60 OP Cat"::X);
        InsertRow(2, 2, "LT Y60 OP Cat"::Y);
        ObserveRun(Observer, 'first and last', Report::"LT Y60 OP Kind Fields");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('NestedHandler')]
    procedure Columns_NestedItem_NoRow_Option()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y60 OP Kind Row";
        Child: Record "LT Y60 OP Kind Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        InsertRow(1, 1, "LT Y60 OP Cat"::Y);
        ObserveRun(Observer, 'no child', Report::"LT Y60 OP Kind Nested");
        Child."Row Id" := 1;
        Child."Line No." := 1;
        Child.Status := Child.Status::Closed;
        Child.Cat := Child.Cat::X;
        Child.Insert();
        ObserveRun(Observer, 'one child', Report::"LT Y60 OP Kind Nested");
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure FieldsHandler(var RP: TestRequestPage "LT Y60 OP Kind Fields")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;

    [RequestPageHandler]
    procedure ExprsHandler(var RP: TestRequestPage "LT Y60 OP Kind Exprs")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;

    [RequestPageHandler]
    procedure NestedHandler(var RP: TestRequestPage "LT Y60 OP Kind Nested")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;
}
