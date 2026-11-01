// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160); own table 99398, test codeunit 99393 (writer Y51, gap cycle 5 spec G5-25a)
// Probe: a .NET Int64 result (MemoryStream.Length, Convert.ToInt64, ZipArchiveEntry.Length) assigned straight to an AL Integer, also
//        through a var Integer parameter (the Data Compression ExtractEntry shape), into a Decimal and a BigInteger, and Int64 values
//        outside the Integer range (in a TryFunction: the error, and the Integer after a failed assignment).
//        Already pinned nearby: TestDotNetValueKindsContracts.al (a CLR long reads as BigInteger), lt-dotnet-interop/DotNetTypeScalars.al.
// BC versions: 27, 28, 29

dotnet
{
    assembly("netstandard")
    {
        type("System.IO.MemoryStream"; LtY51DnMem) { }
        type("System.Convert"; LtY51DnConvert) { }
        type("System.IO.Compression.ZipArchive"; LtY51ZipArchive) { }
        type("System.IO.Compression.ZipArchiveMode"; LtY51ZipMode) { }
        type("System.IO.Compression.ZipArchiveEntry"; LtY51ZipEntry) { }
    }
}

table 99398 "LT Y51 Zip Blob"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Content; Blob) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 99393 "LT Y51 DotNet Int64"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure DnInt64_IntoInteger_InRange()
    var
        MS: DotNet LtY51DnMem;
        Conv: DotNet LtY51DnConvert;
        I: Integer;
        N: Integer;
    begin
        MS := MS.MemoryStream();
        for N := 1 to 5 do
            MS.WriteByte(1);
        I := MS.Length;
        Observer.Observe('int_length', Format(I));
        I := Conv.ToInt64('123');
        Observer.Observe('int_123', Format(I));
        I := Conv.ToInt64('-7');
        Observer.Observe('int_minus7', Format(I));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryAssign(Value: Text; var I: Integer)
    var
        Conv: DotNet LtY51DnConvert;
    begin
        I := Conv.ToInt64(Value);
    end;

    local procedure Assign(Name: Text; Value: Text)
    var
        I: Integer;
    begin
        I := 42;
        ClearLastError();
        if TryAssign(Value, I) then
            Observer.Observe('int_' + Name, Format(I))
        else begin
            Observer.ObserveError('err_' + Name);
            Observer.Observe('after_err_' + Name, Format(I));
        end;
    end;

    [Test]
    procedure DnInt64_IntoInteger_OutOfRange()
    begin
        Assign('3e9', '3000000000');
        Assign('minus3e9', '-3000000000');
        Assign('max', '2147483647');
        Assign('max_plus1', '2147483648');
        Assign('min', '-2147483648');
        Assign('min_minus1', '-2147483649');
        Assign('2pow32', '4294967296');
        Observer.Finish();
    end;

    local procedure GetLen(Entry: DotNet LtY51ZipEntry; var L: Integer)
    begin
        L := Entry.Length();
    end;

    [Test]
    procedure DnZipEntryLength_IntoIntegerVarParam()
    var
        ZipFile: Record "LT Y51 Zip Blob" temporary;
        Src: Record "LT Y51 Zip Blob" temporary;
        ZipArchive: DotNet LtY51ZipArchive;
        Mode: DotNet LtY51ZipMode;
        Entry: DotNet LtY51ZipEntry;
        ZipOut: OutStream;
        ZipIn: InStream;
        SrcOut: OutStream;
        SrcIn: InStream;
        L: Integer;
        D: Decimal;
        B: BigInteger;
    begin
        Src."No." := 1;
        Src.Content.CreateOutStream(SrcOut);
        SrcOut.WriteText('hello world');
        Src.Insert();
        Src.CalcFields(Content);
        Src.Content.CreateInStream(SrcIn);

        ZipFile."No." := 1;
        ZipFile.Content.CreateOutStream(ZipOut);
        ZipArchive := ZipArchive.ZipArchive(ZipOut, Mode.Create);
        Entry := ZipArchive.CreateEntry('a.txt');
        CopyStream(Entry.Open(), SrcIn);
        ZipArchive.Dispose();
        ZipFile.Insert();
        ZipFile.CalcFields(Content);
        ZipFile.Content.CreateInStream(ZipIn);

        ZipArchive := ZipArchive.ZipArchive(ZipIn, Mode.Read);
        Entry := ZipArchive.GetEntry('a.txt');
        GetLen(Entry, L);
        Observer.Observe('int_varparam', Format(L));
        L := Entry.Length;
        Observer.Observe('int_direct', Format(L));
        D := Entry.Length;
        Observer.Observe('decimal', Format(D));
        B := Entry.Length;
        Observer.Observe('biginteger', Format(B));
        ZipArchive.Dispose();
        Observer.Finish();
    end;
}
