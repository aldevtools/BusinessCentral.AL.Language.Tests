// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/blob/blob-length-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 93105, test codeunit 93105 (writer Y57)
// Probe: the length of a BLOB field assigned to an Integer, a BigInteger and a Decimal, and the Audit File Export shape
//        `SizeInMbytes := Round(AuditFile."File Content".Length / (1024 * 1024))` into an Integer; also after CalcFields and on an
//        empty field. A .NET Int64 into an Integer (in and out of range) is pinned in
//        al-language-onprem-dotnet/lt-y51-dotnet-int64/Y51DotNetInt64IntoInteger.al; a BigInteger out of the Integer range in
//        misc/lt-au-language-edges/AuEdgeTests.al.
// Facts: Length fits an Integer, BigInteger and Decimal alike (3145735); Round(3 MB / 1 MB) = 3; after Get without CalcFields Length is
//        3072, after CalcFields the real length; a second CreateOutStream on a BLOB that holds data does NOT truncate it (writing 1.5 MB
//        over 3 MB leaves the length at 3 MB). Measured: SaaS sandbox BC 29 (CI containers: see the commit).
// BC versions: 27, 28, 29

table 93105 "LT Y57 Blob Len Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Content; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93105 "LT Y57 Blob Length Integer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fill(var Row: Record "LT Y57 Blob Len Row"; Size: Integer)
    var
        OutS: OutStream;
        Chunk: Text;
        N: Integer;
    begin
        Row.Content.CreateOutStream(OutS);
        Chunk := PadStr('', 1024, 'x');
        for N := 1 to Size div 1024 do
            OutS.WriteText(Chunk);
        OutS.WriteText(PadStr('', Size mod 1024, 'y'));
    end;

    [Test]
    procedure BlobLength_IntoInteger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y57 Blob Len Row";
        I: Integer;
        Big: BigInteger;
        D: Decimal;
        SizeInMbytes: Integer;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Observer.Observe('empty_int', Format(Row.Content.Length));
        Fill(Row, 5);
        I := Row.Content.Length;
        Observer.Observe('five_int', Format(I));
        Fill(Row, 3 * 1024 * 1024 + 7);
        I := Row.Content.Length;
        Big := Row.Content.Length;
        D := Row.Content.Length;
        Observer.Observe('3mb_int', Format(I));
        Observer.Observe('3mb_big', Format(Big));
        Observer.Observe('3mb_dec', Format(D, 0, 9));
        SizeInMbytes := Round(Row.Content.Length / (1024 * 1024));
        Observer.Observe('3mb_round_mb', Format(SizeInMbytes));
        Row.Insert();
        Clear(Row);
        Row.Get(1);
        Observer.Observe('after_get_int', Format(Row.Content.Length));
        Row.CalcFields(Content);
        I := Row.Content.Length;
        Observer.Observe('after_calcfields_int', Format(I));
        Fill(Row, 1536 * 1024);
        SizeInMbytes := Round(Row.Content.Length / (1024 * 1024));
        Observer.Observe('1_5mb_round_mb', Format(SizeInMbytes));
        Observer.Observe('after_refill_len', Format(Row.Content.Length));
        Clear(Row);
        Row.Init();
        Row.Id := 2;
        Fill(Row, 3 * 1024 * 1024);
        Fill(Row, 1536 * 1024);
        Observer.Observe('refill_not_loaded_len', Format(Row.Content.Length));
        Observer.Expect('empty_int', '0');
        Observer.Expect('five_int', '5');
        Observer.Expect('3mb_int', '3145735');
        Observer.Expect('3mb_big', '3145735');
        Observer.Expect('3mb_dec', '3145735');
        Observer.Expect('3mb_round_mb', '3');
        Observer.Expect('after_get_int', '3072');
        Observer.Expect('after_calcfields_int', '3145735');
        Observer.Expect('1_5mb_round_mb', '3');
        Observer.Expect('after_refill_len', '3145735');
        Observer.Expect('refill_not_loaded_len', '3145728');
        Observer.Verify();
    end;
}
