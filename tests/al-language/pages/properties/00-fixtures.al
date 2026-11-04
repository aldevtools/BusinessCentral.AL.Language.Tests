// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72087 "LT P121 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P121 Log";
            begin
                Log.Add('val Txt=' + Txt);
            end;
        }
        field(3; Qty; Integer)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P121 Log";
            begin
                Log.Add('val Qty=' + Format(Qty));
            end;
        }
        field(4; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT P121 Line".Amount where(RowId = field(Id)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72088 "LT P121 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; RowId; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; RowId, LineNo) { Clustered = true; }
    }
}

table 72089 "LT P121 Blob"
{
    DataClassification = SystemMetadata;

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

table 74989 "LT P121 Log Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Entries; Text[2048]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72090 "LT P121 Log"
{
    procedure Add(Entry: Text)
    var
        Row: Record "LT P121 Log Row";
    begin
        if not Row.Get(1) then begin
            Row.Id := 1;
            Row.Insert();
        end;
        Row.Entries := CopyStr(Row.Entries + Entry + ';', 1, MaxStrLen(Row.Entries));
        Row.Modify();
    end;

    procedure Take(): Text
    var
        Row: Record "LT P121 Log Row";
        Result: Text;
    begin
        if not Row.Get(1) then
            exit('');
        Result := Row.Entries;
        Row.Delete();
        exit(Result);
    end;
}

codeunit 72091 "LT P121 Helper"
{
    procedure Seed()
    var
        Row: Record "LT P121 Row";
        Line: Record "LT P121 Line";
        Log: Codeunit "LT P121 Log";
    begin
        Row.DeleteAll();
        Line.DeleteAll();
        Row.Id := 1;
        Row.Txt := 'a';
        Row.Qty := 10;
        Row.Insert();
        Row.Id := 2;
        Row.Txt := 'b';
        Row.Qty := 20;
        Row.Insert();
        Line.RowId := 1;
        Line.LineNo := 1;
        Line.Amount := 5;
        Line.Insert();
        Line.LineNo := 2;
        Line.Amount := 7;
        Line.Insert();
        Log.Take();
    end;

    procedure ExportText(XmlportId: Integer): Text
    var
        Buf: Record "LT P121 Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        Buf.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Xmlport.Export(XmlportId, OutS);
        Buf.Data.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    procedure ImportText(XmlportId: Integer; Content: Text)
    var
        Buf: Record "LT P121 Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Buf.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        Buf.Data.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(XmlportId, InS);
    end;

    procedure Rows(): Text
    var
        Row: Record "LT P121 Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row.Txt + ':' + Format(Row.Qty) + ',';
            until Row.Next() = 0;
        exit(Result);
    end;
}
