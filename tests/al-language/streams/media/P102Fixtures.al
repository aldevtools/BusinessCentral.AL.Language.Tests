// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type
// Scope: in-scope
// Fixtures used: none (own table and helper)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 71615 "LT P102 Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Pic; Media) { }
        field(4; Pics; MediaSet) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71616 "LT P102 Helper"
{
    procedure Fresh(var Rec: Record "LT P102 Rec")
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

    procedure Dump(var Rec: Record "LT P102 Rec"): Text
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

    procedure Png(var Rec: Record "LT P102 Rec")
    var
        Out: OutStream;
        Bytes: List of [Integer];
        B: Integer;
        Bt: Byte;
    begin
        // a valid 1x1 png, built byte by byte
        Bytes.AddRange(137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137);
        Bytes.AddRange(0, 0, 0, 13, 73, 68, 65, 84, 120, 218, 99, 100, 96, 248, 95, 15, 0, 2, 135, 1, 128);
        Bytes.AddRange(235, 71, 186, 146, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130);
        Rec.Data.CreateOutStream(Out);
        foreach B in Bytes do begin
            Bt := B;
            Out.Write(Bt);
        end;
        Rec.Modify();
    end;
}
