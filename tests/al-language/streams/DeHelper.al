// Fixtures used: System Application codeunit "Temp Blob"
// Plain helper for the LT DE probes (not SingleInstance, no state): hex dump of a Temp Blob and a CR LF text.

codeunit 85909 "LT DE Helper"
{
    procedure HexOf(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        B: Byte;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            if Result <> '' then
                Result += ' ';
            Result += Hex2(B);
        end;
        exit(Result);
    end;

    local procedure Hex2(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, B div 16 + 1, 1) + CopyStr(Digits, B mod 16 + 1, 1));
    end;

    procedure CrLf(): Text
    var
        T: Text[2];
    begin
        T[1] := 13;
        T[2] := 10;
        exit(T);
    end;

    procedure Umlaut(): Text
    var
        T: Text[1];
    begin
        T[1] := 228;
        exit(T);
    end;
}
