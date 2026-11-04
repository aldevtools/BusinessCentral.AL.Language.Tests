// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: none (own table and helper)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 71751 "LT OutIn Rec"
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

codeunit 71752 "LT OutIn Helper"
{
    procedure Fresh(var Rec: Record "LT OutIn Rec")
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

    procedure Dump(var Rec: Record "LT OutIn Rec"): Text
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
}
