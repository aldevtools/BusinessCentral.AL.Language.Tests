// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-layout-custom
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 70825, 70826, 70835, 70882-70884; layout files ./ReportMergerLayoutA.rlblayout and ./ReportMergerLayoutB.rlblayout of the app root (the same convention as handlers/TestReportLayoutByNameReport.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// every OnCustomDocumentMergerEx call, and the helper that turns a call into observable text.
// Masking (the same for every test file of this topic): in the flattened ObjectPayload every value whose key path contains user, company, tenant, session,
// environment, correlation, timestamp or guid is written as <masked>; a value shaped like a GUID is written as <guid>; a value shaped like an ISO date time is
// written as <datetime>. The keys themselves are never masked. Line breaks of XmlData and LayoutData are written as <NL>.
// BC versions: 29 (the final facts get added later)

table 70825 "LT RptMrg Blob"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

enum 70882 "LT RptMrg Kind"
{
    Extensible = true;
    value(0; Alpha) { Caption = 'Alpha cap'; }
    value(1; Beta) { Caption = 'Beta cap'; }
}

table 70826 "LT RptMrg Row"
{
    fields
    {
        field(1; Id; Integer) { Caption = 'Row Id'; }
        field(2; Name; Text[100]) { Caption = 'Row Name'; }
        field(3; Amount; Decimal) { Caption = 'Row Amount'; }
        field(4; BigAmount; Decimal) { }
        field(5; "When"; Date) { Caption = 'Row When'; }
        field(6; Flag; Boolean) { Caption = 'Row Flag'; }
        field(7; Kind; Enum "LT RptMrg Kind") { }
        field(8; Stamp; DateTime) { }
        field(9; Clock; Time) { }
        field(10; Note; Text[50]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 70883 "LT RptMrg Report"
{
    Caption = 'LT Merger Main';
    UseRequestPage = false;
    DefaultRenderingLayout = CustomA;

    dataset
    {
        dataitem(Rows; "LT RptMrg Row")
        {
            column(RowId; Id) { IncludeCaption = true; }
            column(RowName; Name) { }
            column(RowAmount; Amount) { IncludeCaption = true; }
            column(RowBig; BigAmount) { }
            column(RowWhen; "When") { IncludeCaption = true; }
            column(RowFlag; Flag) { IncludeCaption = true; }
            column(RowKind; Kind) { }
            column(RowStamp; Stamp) { }
            column(RowClock; Clock) { }
            column(RowNote; Note) { }
            column(ModeColumn; ModeVal) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ModeVal; ModeVal)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    rendering
    {
        layout(CustomA)
        {
            Type = Custom;
            LayoutFile = './_fixtures/layouts/ReportMergerLayoutA_2.rlblayout';
            MimeType = 'application/x-lmc-layout';
            Caption = 'Merger layout A';
            Summary = 'First custom layout, the default.';
        }
        layout(CustomB)
        {
            Type = Custom;
            LayoutFile = './_fixtures/layouts/ReportMergerLayoutB.rlblayout';
            MimeType = 'application/x-lmc-layout-b';
            Caption = 'Merger layout B';
            Summary = 'Second custom layout.';
        }
    }

    labels
    {
        TitleLbl = 'Merger title';
        NoteLbl = 'Merger note', Comment = 'a comment', MaxLength = 30;
    }

    var
        ModeVal: Integer;
}

report 70884 "LT RptMrg NoDefault"
{
    Caption = 'LT Merger No Default';
    DefaultRenderingLayout = CustomB;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "LT RptMrg Row")
        {
            column(RowId; Id) { }
        }
    }

    rendering
    {
        layout(CustomB)
        {
            Type = Custom;
            LayoutFile = './_fixtures/layouts/ReportMergerLayoutB_2.rlblayout';
            MimeType = 'application/x-lmc-layout-b';
            Caption = 'Merger layout B';
        }
        layout(CustomA)
        {
            Type = Custom;
            LayoutFile = './_fixtures/layouts/ReportMergerLayoutA_3.rlblayout';
            MimeType = 'application/x-lmc-layout';
            Caption = 'Merger layout A';
        }
    }
}

codeunit 70835 "LT RptMrg Helper"
{
    procedure SeedRows(Count: Integer)
    var
        Row: Record "LT RptMrg Row";
    begin
        Row.DeleteAll();
        if Count >= 1 then begin
            Row.Init();
            Row.Id := 1;
            Row.Name := 'Alpha';
            Row.Amount := 12.5;
            Row.BigAmount := 1234567.891;
            Row."When" := 20240131D;
            Row.Flag := true;
            Row.Kind := Row.Kind::Beta;
            Row.Stamp := CreateDateTime(20240131D, 134500T);
            Row.Clock := 134500T;
            Row.Note := '';
            Row.Insert();
        end;
        if Count >= 2 then begin
            Row.Init();
            Row.Id := 2;
            Row.Name := 'A&B <x> "q" ''s'' é';
            Row.Amount := -3.14159;
            Row.BigAmount := 0;
            Row."When" := 0D;
            Row.Flag := false;
            Row.Kind := Row.Kind::Alpha;
            Row.Stamp := 0DT;
            Row.Clock := 0T;
            Row.Note := 'n';
            Row.Insert();
        end;
    end;

    procedure Describe(var InS: InStream; var TextOut: Text; var Info: Text)
    var
        Tmp: Record "LT RptMrg Blob" temporary;
        OutS: OutStream;
        InB: InStream;
        InT: InStream;
        B: Byte;
        Cr: Integer;
        Lf: Integer;
        Len: Integer;
        First: Text;
        Line: Text;
        FirstLine: Boolean;
    begin
        TextOut := '';
        Info := '';
        Tmp.Init();
        Tmp.Id := 1;
        Tmp.Data.CreateOutStream(OutS);
        CopyStream(OutS, InS);
        Tmp.Insert();
        Tmp.Get(1);
        Tmp.CalcFields(Data);
        Tmp.Data.CreateInStream(InB);
        while not InB.EOS() do begin
            InB.Read(B);
            Len += 1;
            if B = 13 then
                Cr += 1;
            if B = 10 then
                Lf += 1;
            if Len <= 3 then begin
                if First <> '' then
                    First += ',';
                First += Format(B);
            end;
        end;
        Info := StrSubstNo('cr=%1 lf=%2 first=%3', Cr, Lf, First);
        Tmp.Data.CreateInStream(InT, TextEncoding::UTF8);
        FirstLine := true;
        while not InT.EOS() do begin
            InT.ReadText(Line);
            if not FirstLine then
                TextOut += '<NL>';
            TextOut += Line;
            FirstLine := false;
        end;
    end;

    procedure ReadAll(var Tmp: Record "LT RptMrg Blob" temporary): Text
    var
        InT: InStream;
        Line: Text;
        Result: Text;
        FirstLine: Boolean;
    begin
        if not Tmp.Get(1) then
            exit('<no blob>');
        Tmp.CalcFields(Data);
        Tmp.Data.CreateInStream(InT, TextEncoding::UTF8);
        FirstLine := true;
        while not InT.EOS() do begin
            InT.ReadText(Line);
            if not FirstLine then
                Result += '<NL>';
            Result += Line;
            FirstLine := false;
        end;
        exit(Result);
    end;

    procedure Flatten(Token: JsonToken): Text
    var
        Result: Text;
    begin
        FlattenToken('', Token, Result);
        exit(Result);
    end;

    local procedure FlattenToken(Prefix: Text; Token: JsonToken; var Result: Text)
    var
        Obj: JsonObject;
        Arr: JsonArray;
        Child: JsonToken;
        KeyName: Text;
        Val: Text;
        i: Integer;
    begin
        if Token.IsObject() then begin
            Obj := Token.AsObject();
            if Obj.Keys().Count() = 0 then
                AddLine(Result, Prefix, '{}');
            foreach KeyName in Obj.Keys() do begin
                Obj.Get(KeyName, Child);
                FlattenToken(Join(Prefix, KeyName), Child, Result);
            end;
        end else
            if Token.IsArray() then begin
                Arr := Token.AsArray();
                if Arr.Count() = 0 then
                    AddLine(Result, Prefix, '[]');
                for i := 0 to Arr.Count() - 1 do begin
                    Arr.Get(i, Child);
                    FlattenToken(Prefix + '[' + Format(i) + ']', Child, Result);
                end;
            end else begin
                Token.WriteTo(Val);
                AddLine(Result, Prefix, Mask(Prefix, Val));
            end;
    end;

    local procedure Join(Prefix: Text; KeyName: Text): Text
    begin
        if Prefix = '' then
            exit(KeyName);
        exit(Prefix + '.' + KeyName);
    end;

    local procedure AddLine(var Result: Text; Path: Text; Value: Text)
    begin
        if Result <> '' then
            Result += ' ; ';
        Result += Path + '=' + Value;
    end;

    local procedure Mask(Path: Text; Val: Text): Text
    var
        Low: Text;
        Bare: Text;
        Needle: Text;
        Needles: Text;
    begin
        Low := LowerCase(Path);
        Needles := 'user,company,tenant,session,environment,correlation,timestamp,guid';
        foreach Needle in Needles.Split(',') do
            if StrPos(Low, Needle) > 0 then
                exit('<masked>');
        Bare := DelChr(Val, '=', '"');
        if (StrLen(Bare) = 36) and (CopyStr(Bare, 9, 1) = '-') and (CopyStr(Bare, 14, 1) = '-') then
            exit('<guid>');
        if (StrLen(Bare) = 38) and (CopyStr(Bare, 10, 1) = '-') and (CopyStr(Bare, 15, 1) = '-') then
            exit('<guid>');
        if (StrLen(Bare) >= 19) and (CopyStr(Bare, 5, 1) = '-') and (CopyStr(Bare, 11, 1) = 'T') then
            exit('<datetime>');
        exit(Val);
    end;

    procedure ObserveLong(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text)
    var
        Chunk: Integer;
        Total: Integer;
    begin
        Observer.Observe(Name + ' length', Format(StrLen(Value)));
        Total := (StrLen(Value) + 799) div 800;
        if Total > 8 then
            Total := 8;
        for Chunk := 1 to Total do
            Observer.Observe(Name + ' part ' + Format(Chunk), CopyStr(Value, (Chunk - 1) * 800 + 1, 800));
    end;

    procedure ProbeSave(var Observer: Codeunit "Probe Observer"; Fmt: ReportFormat; RequestXml: Text; var Cap: Codeunit "LT RptMrg Capture")
    var
        Output: Text;
        Saved: Boolean;
        Completed: Boolean;
    begin
        ClearLastError();
        BindSubscription(Cap);
        Completed := TrySaveAs(Fmt, RequestXml, Output, Saved);
        UnbindSubscription(Cap);
        Observer.Observe('try completed', Format(Completed));
        Observer.Observe('saved', Format(Saved));
        Observer.Observe('error', CopyStr(GetLastErrorText(), 1, 200));
        Observer.Observe('output', Output);
        Observer.Observe('calls', Format(Cap.CallCount()));
    end;

    [TryFunction]
    procedure TrySaveAs(Fmt: ReportFormat; RequestXml: Text; var Output: Text; var Saved: Boolean)
    var
        Rep: Report "LT RptMrg Report";
        Tmp: Record "LT RptMrg Blob" temporary;
        OutS: OutStream;
    begin
        Output := '';
        Tmp.Init();
        Tmp.Id := 1;
        Tmp.Data.CreateOutStream(OutS);
        Saved := Rep.SaveAs(RequestXml, Fmt, OutS);
        Tmp.Insert();
        Output := ReadAll(Tmp);
    end;

    [TryFunction]
    procedure TrySaveAsNoDefault(Fmt: ReportFormat; var Output: Text; var Saved: Boolean)
    var
        Rep: Report "LT RptMrg NoDefault";
        Tmp: Record "LT RptMrg Blob" temporary;
        OutS: OutStream;
    begin
        Output := '';
        Tmp.Init();
        Tmp.Id := 1;
        Tmp.Data.CreateOutStream(OutS);
        Saved := Rep.SaveAs('', Fmt, OutS);
        Tmp.Insert();
        Output := ReadAll(Tmp);
    end;
}
