// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type
// Scope: in-scope
// Fixtures used: none (own table, enum, helper)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

table 74625 "LT P89 Rec"
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

enum 74626 "LT P89 Color"
{
    Extensible = true;
    value(0; Red) { }
    value(1; Green) { }
}

codeunit 74627 "LT P89 Helper"
{
    procedure Fresh(var Rec: Record "LT P89 Rec")
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
    end;

    procedure ByteHex(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1));
    end;

    // length, then every byte as hex
    procedure Dump(var Rec: Record "LT P89 Rec"): Text
    var
        Ins: InStream;
        B: Byte;
        Hex: Text;
    begin
        Rec.Get(1);
        Rec.CalcFields(Data);
        Hex := Format(Rec.Data.Length()) + ':';
        Rec.Data.CreateInStream(Ins);
        while not Ins.EOS() do begin
            Ins.Read(B);
            Hex += ByteHex(B);
        end;
        exit(Hex);
    end;

    procedure Join(L: List of [Text]): Text
    var
        T: Text;
        R: Text;
    begin
        foreach T in L do
            R += '[' + T + ']';
        exit(Format(L.Count()) + R);
    end;
}
