// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-saveasxml-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath)
// Fixtures used: Probe Observer (codeunit 69160); own table 98730, reports 98731-98734, codeunits 98735-98736 (writer Y67, gap cycle 6 follow-up)
// Probe: the report data file of TestRequestPage.SaveAsXml (schema and rows) for column sources report/lt-y60-saveasxml-norow/Y60SaveAsXmlNoRow.al
//   does not cover, with no row and with rows: Label globals (plain, Locked, with Comment and a placeholder, in an expression) as columns;
//   Format(..) columns (Integer, Decimal, with a picture, Date with format 4, Option, Boolean, a record field, a field with a Filler picture);
//   FieldCaption and TableCaption as columns; a text literal, a number literal and a procedure call as columns; Decimal columns with every
//   DecimalPlaces form (0 : 0, 1, 2 : 4, 0 : 5), AutoFormatType 0, 1, 2 and 10 (with AutoFormatExpression) on a field and on an expression;
//   Media and MediaSet field columns and Pic.HasValue() / Pics.Count() as columns (no row, a row without media, a row with a Media value).
//   Y60 pins the default decimal formatter (#,##0.00) and the type of Option, Enum and variable columns.
// BC versions: 27, 28, 29

table 98730 "LT Y67 RC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { Caption = 'Name cap'; }
        field(3; Amt; Decimal) { DecimalPlaces = 2 : 2; }
        field(4; Qty; Decimal) { DecimalPlaces = 0 : 5; }
        field(5; Pic; Media) { }
        field(6; Pics; MediaSet) { }
        field(7; Kind; Option) { OptionMembers = A,B; }
        field(8; Dt; Date) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
report 98731 "LT Y67 RC Labels"
{
    UsageCategory = None;
    ProcessingOnly = false;
    dataset
    {
        dataitem(Loop; Integer)
        {
            DataItemTableView = sorting(Number);
            column(CapLbl; CapLbl) { }
            column(CapLocked; LockedLbl) { }
            column(CapParam; ParamLbl) { }
            column(CapExpr; CapLbl + '!') { }
            column(FmtInt; Format(GInt)) { }
            column(FmtDec; Format(GDec)) { }
            column(FmtDecPic; Format(GDec, 0, '<Precision,2:2><Standard Format,0>')) { }
            column(FmtDate; Format(GDate)) { }
            column(FmtDate4; Format(GDate, 0, 4)) { }
            column(FmtOpt; Format(GOpt)) { }
            column(FmtBool; Format(GBool)) { }
            column(FmtRecDec; Format(GRec.Amt)) { }
            column(FmtRecKind; Format(GRec.Kind)) { }
            column(Cap_FieldCaption; GRec.FieldCaption(Name)) { }
            column(Cap_TableCaption; GRec.TableCaption()) { }
            column(Lit; 'abc') { }
            column(LitNum; 42) { }
            column(Proc; Describe()) { }
            column(Const; Const) { }

            trigger OnPreDataItem()
            begin
                Loop.SetRange(Number, 1, Counter.Get());
            end;
        }
    }
    requestpage
    {
        layout { area(Content) { field(Ctl; Ctl) { ApplicationArea = All; } } }
    }
    trigger OnPreReport()
    begin
        GInt := 7;
        GDec := 2.5;
        GDate := DMY2Date(15, 3, 2024);
        GOpt := GOpt::Second;
        GBool := true;
        GRec.Amt := 1234.5;
        GRec.Kind := GRec.Kind::B;
        Const := 'const';
    end;

    var
        Counter: Codeunit "LT Y67 RC Count";
        CapLbl: Label 'Dimensions';
        LockedLbl: Label 'Locked cap', Locked = true;
        ParamLbl: Label 'Page %1 of %2', Comment = '%1 = page, %2 = total';
        Const: Text;
        Ctl: Integer;
        GInt: Integer;
        GDec: Decimal;
        GDate: Date;
        GOpt: Option First,Second;
        GBool: Boolean;
        GRec: Record "LT Y67 RC Row";

    local procedure Describe(): Text
    begin
        exit('d');
    end;
}
report 98732 "LT Y67 RC Decimals"
{
    UsageCategory = None;
    ProcessingOnly = false;
    dataset
    {
        dataitem(Item; "LT Y67 RC Row")
        {
            column(Plain; Amt) { }
            column(Dp0; Amt) { DecimalPlaces = 0 : 0; }
            column(Dp1; Amt) { DecimalPlaces = 1; }
            column(Dp24; Amt) { DecimalPlaces = 2 : 4; }
            column(Dp05; Qty) { DecimalPlaces = 0 : 5; }
            column(Af1; Amt) { AutoFormatType = 1; }
            column(Af2; Amt) { AutoFormatType = 2; }
            column(Af10; Amt) { AutoFormatType = 10; AutoFormatExpression = '<Precision,3:3><Standard Format,0>'; }
            column(Af0; Amt) { AutoFormatType = 0; }
            column(ExprDp; Amt * 2) { DecimalPlaces = 3; }
            column(ExprAf; Amt * 2) { AutoFormatType = 1; }
        }
    }
    requestpage
    {
        layout { area(Content) { field(Ctl; Ctl) { ApplicationArea = All; } } }
    }
    var
        Ctl: Integer;
}
report 98734 "LT Y67 RC Row Captions"
{
    UsageCategory = None;
    ProcessingOnly = false;
    dataset
    {
        dataitem(Item; "LT Y67 RC Row")
        {
            column(HdrCap; Item.FieldCaption(Name)) { }
            column(TblCap; Item.TableCaption()) { }
            column(NameC; Name) { IncludeCaption = true; }
            column(LabelRow; CapLbl) { }
            column(FmtAmt; Format(Amt)) { }
            column(FmtAmtPic; Format(Amt, 0, '<Precision,2:2><Standard Format,0>')) { }
            column(FmtKind; Format(Kind)) { }
            column(FmtDt; Format(Dt)) { }
            column(FmtId; Format(Id, 0, '<Integer,4><Filler Character,0>')) { }
        }
    }
    requestpage
    {
        layout { area(Content) { field(Ctl; Ctl) { ApplicationArea = All; } } }
    }
    var
        Ctl: Integer;
        CapLbl: Label 'Row caption';
}

report 98733 "LT Y67 RC Media"
{
    UsageCategory = None;
    ProcessingOnly = false;
    dataset
    {
        dataitem(Item; "LT Y67 RC Row")
        {
            column(IdC; Id) { }
            column(PicC; Pic) { }
            column(PicsC; Pics) { }
            column(PicHas; Pic.HasValue()) { }
            column(PicsCount; Pics.Count()) { }
        }
    }
    requestpage
    {
        layout { area(Content) { field(Ctl; Ctl) { ApplicationArea = All; } } }
    }
    var
        Ctl: Integer;
}

codeunit 98735 "LT Y67 RC Count"
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

codeunit 98736 "LT Y67 RC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Counter: Codeunit "LT Y67 RC Count";
        ParametersFile: Text;
        DataFile: Text;

    local procedure Prepare()
    begin
        Commit();
        ParametersFile := TemporaryPath() + 'lt-y67-params.xml';
        DataFile := TemporaryPath() + 'lt-y67-data.xml';
        if Exists(ParametersFile) then
            Erase(ParametersFile);
        if Exists(DataFile) then
            Erase(DataFile);
    end;

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

    // The columns of the data set schema as name=type (a date time column as name=Local-dateTime), separated by spaces.
    local procedure Columns(Content: Text): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Content.Split('|') do
            if Line.Contains(' type="') then begin
                Line := Line.Trim().Replace(' minOccurs="0" />', '').Replace('<xs:element name="', '');
                Line := Line.Replace('" msdata:DateTimeMode="Local" type="xs:', '=Local-').Replace('" type="xs:', '=').Replace('"', '');
                Result += Line + ' ';
            end;
        exit(Result);
    end;

    // The rows after the schema: <Tag>value</Tag> is written Tag=value, a row starts with R: and ends with ;
    local procedure IsSelfClosing(Line: Text): Boolean
    begin
        if StrLen(Line) < 4 then
            exit(false);
        exit(CopyStr(Line, StrLen(Line) - 1) = '/>');
    end;

    local procedure Rows(Content: Text): Text
    var
        Line: Text;
        Result: Text;
        After: Boolean;
        At: Integer;
        Tag: Text;
    begin
        foreach Line in Content.Split('|') do begin
            if After then begin
                Line := Line.Trim();
                if Line = '<Result>' then
                    Result += 'R:'
                else
                    if Line = '</Result>' then
                        Result += '; '
                    else
                        if IsSelfClosing(Line) then
                            Result += CopyStr(Line, 2, StrLen(Line) - 3).Trim() + '= '
                        else
                            if (Line <> '') and (Line <> '</DataSet>') and (CopyStr(Line, 1, 1) = '<') then begin
                            At := StrPos(Line, '>');
                            Tag := CopyStr(Line, 2, At - 2);
                            Result += Tag + '=' + CopyStr(Line, At + 1, StrLen(Line) - At - StrLen(Tag) - 3) + ' ';
                        end;
            end;
            if Line.Contains('</xs:schema>') then
                After := true;
        end;
        exit(Result);
    end;

    local procedure InsertRow(Id: Integer)
    var
        Row: Record "LT Y67 RC Row";
    begin
        Row.Id := Id;
        Row.Name := 'name ' + Format(Id);
        Row.Amt := 1234.5;
        Row.Qty := 0.12;
        Row.Kind := Row.Kind::B;
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
    [HandlerFunctions('LabelsHandler')]
    procedure Columns_LabelsAndFormat_NoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Counter.Set(0);
        ObserveRun(Observer, 'no row', Report::"LT Y67 RC Labels");
        Observer.Expect('no row schema', 'CapLbl=string CapLocked=string CapParam=string CapExpr=string FmtInt=string FmtDec=string FmtDecPic=string FmtDate=string FmtDate4=string FmtOpt=string FmtBool=string FmtRecDec=string FmtRecKind=string Cap_FieldCaption=string Cap_TableCaption=string Lit=string LitNum=int Proc=string Const=string ');
        Observer.Expect('no row rows', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LabelsHandler')]
    procedure Columns_LabelsAndFormat_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Counter.Set(2);
        ObserveRun(Observer, 'two rows', Report::"LT Y67 RC Labels");
        Observer.Expect('two rows schema', 'CapLbl=string CapLocked=string CapParam=string CapExpr=string FmtInt=string FmtDec=string FmtDecPic=string FmtDate=string FmtDate4=string FmtOpt=string FmtBool=string FmtRecDec=string FmtRecKind=string Cap_FieldCaption=string Cap_TableCaption=string Lit=string LitNum=int Proc=string Const=string ');
        Observer.Expect('two rows rows', 'R:CapLbl=Dimensions CapLocked=Locked cap CapParam=Page %1 of %2 CapExpr=Dimensions! FmtInt=7 FmtDec=2.5 FmtDecPic=2.50 FmtDate=03/15/24 FmtDate4=March 15, 2024 FmtOpt=Second FmtBool=Yes FmtRecDec=1,234.50 FmtRecKind=B Cap_FieldCaption=Name cap Cap_TableCaption=LT Y67 RC Row Lit=abc LitNum=42 Proc=d Const=const ; R:CapLbl=Dimensions CapLocked=Locked cap CapParam=Page %1 of %2 CapExpr=Dimensions! FmtInt=7 FmtDec=2.5 FmtDecPic=2.50 FmtDate=03/15/24 FmtDate4=March 15, 2024 FmtOpt=Second FmtBool=Yes FmtRecDec=1,234.50 FmtRecKind=B Cap_FieldCaption=Name cap Cap_TableCaption=LT Y67 RC Row Lit=abc LitNum=42 Proc=d Const=const ; ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RowCaptionsHandler')]
    procedure Columns_FieldCaptionFormat_RowItem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 RC Row";
    begin
        Row.DeleteAll();
        ObserveRun(Observer, 'no row', Report::"LT Y67 RC Row Captions");
        InsertRow(1);
        ObserveRun(Observer, 'one row', Report::"LT Y67 RC Row Captions");
        Observer.Expect('no row schema', 'HdrCap=string TblCap=string NameC=string LabelRow=string FmtAmt=string FmtAmtPic=string FmtKind=string FmtDt=string FmtId=string ');
        Observer.Expect('no row rows', '');
        Observer.Expect('one row schema', 'HdrCap=string TblCap=string NameC=string LabelRow=string FmtAmt=string FmtAmtPic=string FmtKind=string FmtDt=string FmtId=string ');
        Observer.Expect('one row rows', 'R:HdrCap=Name cap TblCap=LT Y67 RC Row NameC=name 1 LabelRow=Row caption FmtAmt=1,234.50 FmtAmtPic=1,234.50 FmtKind=B FmtDt=02/01/24 FmtId=0001 ; ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DecimalsHandler')]
    procedure Columns_DecimalFormatters()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 RC Row";
    begin
        Row.DeleteAll();
        ObserveRun(Observer, 'no row', Report::"LT Y67 RC Decimals");
        InsertRow(1);
        ObserveRun(Observer, 'one row', Report::"LT Y67 RC Decimals");
        Observer.Expect('no row schema', 'Plain=decimal PlainFormat=string Dp0=decimal Dp0Format=string Dp1=decimal Dp1Format=string Dp24=decimal Dp24Format=string Dp05=decimal Dp05Format=string Af1=decimal Af1Format=string Af2=decimal Af2Format=string Af10=decimal Af10Format=string Af0=decimal Af0Format=string ExprDp=decimal ExprDpFormat=string ExprAf=decimal ExprAfFormat=string ');
        Observer.Expect('no row rows', '');
        Observer.Expect('one row schema', 'Plain=decimal PlainFormat=string Dp0=decimal Dp0Format=string Dp1=decimal Dp1Format=string Dp24=decimal Dp24Format=string Dp05=decimal Dp05Format=string Af1=decimal Af1Format=string Af2=decimal Af2Format=string Af10=decimal Af10Format=string Af0=decimal Af0Format=string ExprDp=decimal ExprDpFormat=string ExprAf=decimal ExprAfFormat=string ');
        Observer.Expect('one row rows', 'R:Plain=1234.5 PlainFormat=#,##0.00 Dp0=1234.5 Dp0Format=#,##0 Dp1=1234.5 Dp1Format=#,##0.0 Dp24=1234.5 Dp24Format=#,##0.00## Dp05=0.12 Dp05Format=#,##0.##### Af1=1234.5 Af1Format=#,##0.00 Af2=1234.5 Af2Format=#,##0.00### Af10=1234.5 Af10Format=#,##0.000 Af0=1234.5 Af0Format=#,##0.00 ExprDp=2469.0 ExprDpFormat=#,##0.000 ExprAf=2469.0 ExprAfFormat=#,##0.00 ; ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MediaHandler')]
    procedure Columns_MediaAndMediaSet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 RC Row";
    begin
        Row.DeleteAll();
        ObserveRun(Observer, 'no row', Report::"LT Y67 RC Media");
        InsertRow(1);
        ObserveRun(Observer, 'row no media', Report::"LT Y67 RC Media");
#if BC29PLUS
        Observer.Expect('no row schema', 'IdC=int PicC msdata:DataType=System.Guid, System.Private.CoreLib, Version=10.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e=string PicsC msdata:DataType=System.Guid, System.Private.CoreLib, Version=10.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e=string PicHas=boolean PicsCount=int ');
#else
        Observer.Expect('no row schema', 'IdC=int PicC msdata:DataType=System.Guid, System.Private.CoreLib, Version=8.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e=string PicsC msdata:DataType=System.Guid, System.Private.CoreLib, Version=8.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e=string PicHas=boolean PicsCount=int ');
#endif
        Observer.Expect('no row rows', '');
#if BC29PLUS
        Observer.Expect('row no media schema', 'IdC=int PicC msdata:DataType=System.Guid, System.Private.CoreLib, Version=10.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e=string PicsC msdata:DataType=System.Guid, System.Private.CoreLib, Version=10.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e=string PicHas=boolean PicsCount=int ');
#else
        Observer.Expect('row no media schema', 'IdC=int PicC msdata:DataType=System.Guid, System.Private.CoreLib, Version=8.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e=string PicsC msdata:DataType=System.Guid, System.Private.CoreLib, Version=8.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e=string PicHas=boolean PicsCount=int ');
#endif
        Observer.Expect('row no media rows', 'R:IdC=1 PicHas=false PicsCount=0 ; ');
        Observer.Verify();
    end;

    // Suspect (Linux): the Media column of a row with a value gives a GUID made of the first bytes of the imported stream, not an id.
    [HandlerFunctions('MediaHandler')]
    procedure Suspect_Columns_MediaWithValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 RC Row";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
        InS: InStream;
    begin
        Row.DeleteAll();
        InsertRow(1);
        Row.Get(1);
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==', OutS);
        TempBlob.CreateInStream(InS);
        Row.Pic.ImportStream(InS, 'x.png');
        Row.Modify();
        ObserveRun(Observer, 'row with media', Report::"LT Y67 RC Media");
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure LabelsHandler(var RP: TestRequestPage "LT Y67 RC Labels")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;

    [RequestPageHandler]
    procedure RowCaptionsHandler(var RP: TestRequestPage "LT Y67 RC Row Captions")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;

    [RequestPageHandler]
    procedure DecimalsHandler(var RP: TestRequestPage "LT Y67 RC Decimals")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;

    [RequestPageHandler]
    procedure MediaHandler(var RP: TestRequestPage "LT Y67 RC Media")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;
}
