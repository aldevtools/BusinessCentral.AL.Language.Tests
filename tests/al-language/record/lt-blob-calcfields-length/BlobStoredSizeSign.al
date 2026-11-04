// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/blob/blob-length-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 95040 and 95041 and codeunit 95042 below
// Probe: measured on Windows BC 27.5 and 28.5 (identical); every literal asserted below is what those produced. 29 by CI.
// Question (al-runner issue 6896): is the stored size that Blob.Length gives before CalcFields positive for every non-empty content whenever HasValue is Yes. Answer: yes for every case measured. The exact stored size of a Compressed field is not asserted (Linux and BC 29 compress to other sizes than Windows 27/28); p in an observation means positive. A field with Compressed = false stores the content size on every host. Stage names in the observations: w written (new content in the variable), i inserted, g Get, gc Get then CalcFields, fs FindSet, fsc FindSet then CalcFields, m Modify (content written to a row inserted empty), mg Get after that, mgc CalcFields after that; <length><y|n for HasValue>.
// Facts: Blob.Length and HasValue before CalcFields (after Insert, after Get, after FindSet, after Modify) and after CalcFields, for a Compressed = true and a Compressed = false Blob field, for contents of 1 byte to 5 MB (text, XML, random-looking binary, zero bytes, one repeated byte), an empty Blob and a Blob cleared with Clear and Modify
// BC versions: 29 (27 and 28 by CI)

table 95040 "LT BSS Compressed"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { Compressed = true; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 95041 "LT BSS Plain"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { Compressed = false; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 95042 "LT BSS Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // One stage as "name=<length><y if HasValue, n if not>;".
    local procedure Snap(Stage: Text; Size: Integer; Has: Boolean): Text
    var
        Mark: Text;
    begin
        Mark := 'n';
        if Has then
            Mark := 'y';
        exit(Stage + '=' + Format(Size) + Mark + ';');
    end;

    // The same for a stored size of a Compressed field, which depends on the host's compression: only "positive" (p) or the number 0.
    local procedure SnapPositive(Stage: Text; Size: Integer; Has: Boolean): Text
    var
        Shown: Text;
    begin
        Shown := Format(Size);
        if Size > 0 then
            Shown := 'p';
        exit(Snap(Stage, 0, Has).Replace('=0', '=' + Shown));
    end;

    local procedure Xml(Target: Integer): Text
    var
        Tb: TextBuilder;
        I: Integer;
    begin
        Tb.Append('<?xml version="1.0" encoding="utf-8"?><Import>');
        while Tb.Length() < Target - 9 do begin
            I += 1;
            Tb.Append('<Line><No>' + PadStr('', 5 - StrLen(Format(I)), '0') + Format(I) + '</No><Desc>Item description</Desc></Line>');
        end;
        Tb.Append('</Import>');
        exit(Tb.ToText());
    end;

    // Kind 1 text of one repeated letter, 2 XML text, 3 random-looking binary, 4 zero bytes, 5 one repeated non-text byte, 6 random-looking text.
    local procedure WriteContent(var OutS: OutStream; Kind: Integer; N: Integer)
    var
        Big: BigInteger;
        Value: Integer;
        I: Integer;
        Letter: Integer;
        Tb: TextBuilder;
    begin
        Big := 12345;
        case Kind of
            1:
                OutS.WriteText(PadStr('', N, 'x'));
            2:
                OutS.WriteText(Xml(N));
            3:
                for I := 1 to N div 4 do begin
                    Big := (Big * 16807) mod 2147483647;
                    Value := Big;
                    OutS.Write(Value);
                end;
            4:
                begin
                    Value := 0;
                    for I := 1 to N div 4 do
                        OutS.Write(Value);
                end;
            5:
                begin
                    Value := 16843009;
                    for I := 1 to N div 4 do
                        OutS.Write(Value);
                end;
            6:
                begin
                    for I := 1 to N do begin
                        Big := (Big * 16807) mod 2147483647;
                        Letter := Big mod 26;
                        Tb.Append(CopyStr('abcdefghijklmnopqrstuvwxyz', Letter + 1, 1));
                    end;
                    OutS.WriteText(Tb.ToText());
                end;
        end;
    end;

    local procedure MeasureCompressed(var Observer: Codeunit "Probe Observer"; Tag: Text; Kind: Integer; N: Integer)
    var
        Rec: Record "LT BSS Compressed";
        Got: Record "LT BSS Compressed";
        Got2: Record "LT BSS Compressed";
        OutS: OutStream;
        Line: Text;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        if N > 0 then begin
            Rec.Data.CreateOutStream(OutS);
            WriteContent(OutS, Kind, N);
        end;
        Line += Snap('w', Rec.Data.Length(), Rec.Data.HasValue());
        Rec.Insert();
        Line += Snap('i', Rec.Data.Length(), Rec.Data.HasValue());
        Got.Get(1);
        Line += SnapPositive('g', Got.Data.Length(), Got.Data.HasValue());
        Got.CalcFields(Data);
        Line += Snap('gc', Got.Data.Length(), Got.Data.HasValue());
        Got2.SetRange(Id, 1);
        Got2.FindSet();
        Line += SnapPositive('fs', Got2.Data.Length(), Got2.Data.HasValue());
        Got2.CalcFields(Data);
        Line += Snap('fsc', Got2.Data.Length(), Got2.Data.HasValue());
        Clear(Rec);
        Clear(Got);
        Rec.Id := 2;
        Rec.Insert();
        if N > 0 then begin
            Rec.Data.CreateOutStream(OutS);
            WriteContent(OutS, Kind, N);
        end;
        Rec.Modify();
        Line += Snap('m', Rec.Data.Length(), Rec.Data.HasValue());
        Got.Get(2);
        Line += SnapPositive('mg', Got.Data.Length(), Got.Data.HasValue());
        Got.CalcFields(Data);
        Line += Snap('mgc', Got.Data.Length(), Got.Data.HasValue());
        Observer.Observe('C-' + Tag, Line);
        Rec.DeleteAll();
    end;

    local procedure MeasurePlain(var Observer: Codeunit "Probe Observer"; Tag: Text; Kind: Integer; N: Integer)
    var
        Rec: Record "LT BSS Plain";
        Got: Record "LT BSS Plain";
        Got2: Record "LT BSS Plain";
        OutS: OutStream;
        Line: Text;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        if N > 0 then begin
            Rec.Data.CreateOutStream(OutS);
            WriteContent(OutS, Kind, N);
        end;
        Line += Snap('w', Rec.Data.Length(), Rec.Data.HasValue());
        Rec.Insert();
        Line += Snap('i', Rec.Data.Length(), Rec.Data.HasValue());
        Got.Get(1);
        Line += Snap('g', Got.Data.Length(), Got.Data.HasValue());
        Got.CalcFields(Data);
        Line += Snap('gc', Got.Data.Length(), Got.Data.HasValue());
        Got2.SetRange(Id, 1);
        Got2.FindSet();
        Line += Snap('fs', Got2.Data.Length(), Got2.Data.HasValue());
        Got2.CalcFields(Data);
        Line += Snap('fsc', Got2.Data.Length(), Got2.Data.HasValue());
        Clear(Rec);
        Clear(Got);
        Rec.Id := 2;
        Rec.Insert();
        if N > 0 then begin
            Rec.Data.CreateOutStream(OutS);
            WriteContent(OutS, Kind, N);
        end;
        Rec.Modify();
        Line += Snap('m', Rec.Data.Length(), Rec.Data.HasValue());
        Got.Get(2);
        Line += Snap('mg', Got.Data.Length(), Got.Data.HasValue());
        Got.CalcFields(Data);
        Line += Snap('mgc', Got.Data.Length(), Got.Data.HasValue());
        Observer.Observe('U-' + Tag, Line);
        Rec.DeleteAll();
    end;

    local procedure Both(var Observer: Codeunit "Probe Observer"; Tag: Text; Kind: Integer; N: Integer)
    begin
        MeasureCompressed(Observer, Tag, Kind, N);
        MeasurePlain(Observer, Tag, Kind, N);
    end;

    [Test]
    procedure StoredSize_SmallText_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'text1', 1, 1);
        Both(Observer, 'text2', 1, 2);
        Both(Observer, 'text5', 1, 5);
        Observer.Expect('C-text1', 'w=1y;i=1y;g=py;gc=1y;fs=py;fsc=1y;m=1y;mg=py;mgc=1y;');
        Observer.Expect('U-text1', 'w=1y;i=1y;g=1y;gc=1y;fs=1y;fsc=1y;m=1y;mg=1y;mgc=1y;');
        Observer.Expect('C-text2', 'w=2y;i=2y;g=py;gc=2y;fs=py;fsc=2y;m=2y;mg=py;mgc=2y;');
        Observer.Expect('U-text2', 'w=2y;i=2y;g=2y;gc=2y;fs=2y;fsc=2y;m=2y;mg=2y;mgc=2y;');
        Observer.Expect('C-text5', 'w=5y;i=5y;g=py;gc=5y;fs=py;fsc=5y;m=5y;mg=py;mgc=5y;');
        Observer.Expect('U-text5', 'w=5y;i=5y;g=5y;gc=5y;fs=5y;fsc=5y;m=5y;mg=5y;mgc=5y;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredSize_MediumText_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'text100', 1, 100);
        Both(Observer, 'text1000', 1, 1000);
        Both(Observer, 'text4000', 1, 4000);
        Observer.Expect('C-text100', 'w=100y;i=100y;g=py;gc=100y;fs=py;fsc=100y;m=100y;mg=py;mgc=100y;');
        Observer.Expect('U-text100', 'w=100y;i=100y;g=100y;gc=100y;fs=100y;fsc=100y;m=100y;mg=100y;mgc=100y;');
        Observer.Expect('C-text1000', 'w=1000y;i=1000y;g=py;gc=1000y;fs=py;fsc=1000y;m=1000y;mg=py;mgc=1000y;');
        Observer.Expect('U-text1000', 'w=1000y;i=1000y;g=1000y;gc=1000y;fs=1000y;fsc=1000y;m=1000y;mg=1000y;mgc=1000y;');
        Observer.Expect('C-text4000', 'w=4000y;i=4000y;g=py;gc=4000y;fs=py;fsc=4000y;m=4000y;mg=py;mgc=4000y;');
        Observer.Expect('U-text4000', 'w=4000y;i=4000y;g=4000y;gc=4000y;fs=4000y;fsc=4000y;m=4000y;mg=4000y;mgc=4000y;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredSize_Xml_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'xml600', 2, 600);
        Both(Observer, 'xml3800', 2, 3800);
        Observer.Expect('C-xml600', 'w=615y;i=615y;g=py;gc=615y;fs=py;fsc=615y;m=615y;mg=py;mgc=615y;');
        Observer.Expect('U-xml600', 'w=615y;i=615y;g=615y;gc=615y;fs=615y;fsc=615y;m=615y;mg=615y;mgc=615y;');
        Observer.Expect('C-xml3800', 'w=3807y;i=3807y;g=py;gc=3807y;fs=py;fsc=3807y;m=3807y;mg=py;mgc=3807y;');
        Observer.Expect('U-xml3800', 'w=3807y;i=3807y;g=3807y;gc=3807y;fs=3807y;fsc=3807y;m=3807y;mg=3807y;mgc=3807y;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredSize_Binary_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'rand1000', 3, 1000);
        Both(Observer, 'rand100000', 3, 100000);
        Both(Observer, 'zero1000', 4, 1000);
        Both(Observer, 'zero100000', 4, 100000);
        Observer.Expect('C-rand1000', 'w=1000y;i=1000y;g=py;gc=1000y;fs=py;fsc=1000y;m=1000y;mg=py;mgc=1000y;');
        Observer.Expect('U-rand1000', 'w=1000y;i=1000y;g=1000y;gc=1000y;fs=1000y;fsc=1000y;m=1000y;mg=1000y;mgc=1000y;');
        Observer.Expect('C-rand100000', 'w=100000y;i=100000y;g=py;gc=100000y;fs=py;fsc=100000y;m=100000y;mg=py;mgc=100000y;');
        Observer.Expect('U-rand100000', 'w=100000y;i=100000y;g=100000y;gc=100000y;fs=100000y;fsc=100000y;m=100000y;mg=100000y;mgc=100000y;');
        Observer.Expect('C-zero1000', 'w=1000y;i=1000y;g=py;gc=1000y;fs=py;fsc=1000y;m=1000y;mg=py;mgc=1000y;');
        Observer.Expect('U-zero1000', 'w=1000y;i=1000y;g=1000y;gc=1000y;fs=1000y;fsc=1000y;m=1000y;mg=1000y;mgc=1000y;');
        Observer.Expect('C-zero100000', 'w=100000y;i=100000y;g=py;gc=100000y;fs=py;fsc=100000y;m=100000y;mg=py;mgc=100000y;');
        Observer.Expect('U-zero100000', 'w=100000y;i=100000y;g=100000y;gc=100000y;fs=100000y;fsc=100000y;m=100000y;mg=100000y;mgc=100000y;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredSize_RepeatedByte_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'byte1000', 5, 1000);
        Both(Observer, 'byte100000', 5, 100000);
        Observer.Expect('C-byte1000', 'w=1000y;i=1000y;g=py;gc=1000y;fs=py;fsc=1000y;m=1000y;mg=py;mgc=1000y;');
        Observer.Expect('U-byte1000', 'w=1000y;i=1000y;g=1000y;gc=1000y;fs=1000y;fsc=1000y;m=1000y;mg=1000y;mgc=1000y;');
        Observer.Expect('C-byte100000', 'w=100000y;i=100000y;g=py;gc=100000y;fs=py;fsc=100000y;m=100000y;mg=py;mgc=100000y;');
        Observer.Expect('U-byte100000', 'w=100000y;i=100000y;g=100000y;gc=100000y;fs=100000y;fsc=100000y;m=100000y;mg=100000y;mgc=100000y;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredSize_RandomText_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'rtext1000', 6, 1000);
        Both(Observer, 'rtext100000', 6, 100000);
        Observer.Expect('C-rtext1000', 'w=1000y;i=1000y;g=py;gc=1000y;fs=py;fsc=1000y;m=1000y;mg=py;mgc=1000y;');
        Observer.Expect('U-rtext1000', 'w=1000y;i=1000y;g=1000y;gc=1000y;fs=1000y;fsc=1000y;m=1000y;mg=1000y;mgc=1000y;');
        Observer.Expect('C-rtext100000', 'w=100000y;i=100000y;g=py;gc=100000y;fs=py;fsc=100000y;m=100000y;mg=py;mgc=100000y;');
        Observer.Expect('U-rtext100000', 'w=100000y;i=100000y;g=100000y;gc=100000y;fs=100000y;fsc=100000y;m=100000y;mg=100000y;mgc=100000y;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredSize_OneMegabyte_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'text1m', 1, 1048576);
        Both(Observer, 'rand1m', 3, 1048576);
        Both(Observer, 'zero1m', 4, 1048576);
        Both(Observer, 'rtext1m', 6, 1048576);
        Observer.Expect('C-text1m', 'w=1048576y;i=1048576y;g=py;gc=1048576y;fs=py;fsc=1048576y;m=1048576y;mg=py;mgc=1048576y;');
        Observer.Expect('U-text1m', 'w=1048576y;i=1048576y;g=1048576y;gc=1048576y;fs=1048576y;fsc=1048576y;m=1048576y;mg=1048576y;mgc=1048576y;');
        Observer.Expect('C-rand1m', 'w=1048576y;i=1048576y;g=py;gc=1048576y;fs=py;fsc=1048576y;m=1048576y;mg=py;mgc=1048576y;');
        Observer.Expect('U-rand1m', 'w=1048576y;i=1048576y;g=1048576y;gc=1048576y;fs=1048576y;fsc=1048576y;m=1048576y;mg=1048576y;mgc=1048576y;');
        Observer.Expect('C-zero1m', 'w=1048576y;i=1048576y;g=py;gc=1048576y;fs=py;fsc=1048576y;m=1048576y;mg=py;mgc=1048576y;');
        Observer.Expect('U-zero1m', 'w=1048576y;i=1048576y;g=1048576y;gc=1048576y;fs=1048576y;fsc=1048576y;m=1048576y;mg=1048576y;mgc=1048576y;');
        Observer.Expect('C-rtext1m', 'w=1048576y;i=1048576y;g=py;gc=1048576y;fs=py;fsc=1048576y;m=1048576y;mg=py;mgc=1048576y;');
        Observer.Expect('U-rtext1m', 'w=1048576y;i=1048576y;g=1048576y;gc=1048576y;fs=1048576y;fsc=1048576y;m=1048576y;mg=1048576y;mgc=1048576y;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredSize_FiveMegabytes_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'text5m', 1, 5242880);
        Both(Observer, 'rand5m', 3, 5242880);
        Observer.Expect('C-text5m', 'w=5242880y;i=5242880y;g=py;gc=5242880y;fs=py;fsc=5242880y;m=5242880y;mg=py;mgc=5242880y;');
        Observer.Expect('U-text5m', 'w=5242880y;i=5242880y;g=5242880y;gc=5242880y;fs=5242880y;fsc=5242880y;m=5242880y;mg=5242880y;mgc=5242880y;');
        Observer.Expect('C-rand5m', 'w=5242880y;i=5242880y;g=py;gc=5242880y;fs=py;fsc=5242880y;m=5242880y;mg=py;mgc=5242880y;');
        Observer.Expect('U-rand5m', 'w=5242880y;i=5242880y;g=5242880y;gc=5242880y;fs=5242880y;fsc=5242880y;m=5242880y;mg=5242880y;mgc=5242880y;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredSize_EmptyAndCleared_Result()
    var
        Observer: Codeunit "Probe Observer";
        RecC: Record "LT BSS Compressed";
        GotC: Record "LT BSS Compressed";
        RecU: Record "LT BSS Plain";
        GotU: Record "LT BSS Plain";
        OutS: OutStream;
    begin
        RecC.DeleteAll();
        RecU.DeleteAll();
        // Empty: the Blob is never written.
        RecC.Id := 1;
        RecC.Insert();
        RecU.Id := 1;
        RecU.Insert();
        GotC.Get(1);
        Observer.Observe('C-empty-get', Format(GotC.Data.Length()) + '|' + Format(GotC.Data.HasValue()));
        GotU.Get(1);
        Observer.Observe('U-empty-get', Format(GotU.Data.Length()) + '|' + Format(GotU.Data.HasValue()));
        // Cleared: content stored, then Clear and Modify.
        RecC.Id := 2;
        RecC.Data.CreateOutStream(OutS);
        OutS.WriteText(PadStr('', 100, 'x'));
        RecC.Insert();
        Clear(GotC);
        GotC.Get(2);
        Observer.Observe('C-before-clear-get', Format(GotC.Data.Length() > 0) + '|' + Format(GotC.Data.HasValue()));
        Clear(GotC.Data);
        Observer.Observe('C-cleared-var', Format(GotC.Data.Length()) + '|' + Format(GotC.Data.HasValue()));
        GotC.Modify();
        Observer.Observe('C-cleared-modified', Format(GotC.Data.Length()) + '|' + Format(GotC.Data.HasValue()));
        Clear(GotC);
        GotC.Get(2);
        Observer.Observe('C-cleared-get', Format(GotC.Data.Length()) + '|' + Format(GotC.Data.HasValue()));
        GotC.CalcFields(Data);
        Observer.Observe('C-cleared-getcalc', Format(GotC.Data.Length()) + '|' + Format(GotC.Data.HasValue()));
        RecU.Id := 2;
        RecU.Data.CreateOutStream(OutS);
        OutS.WriteText(PadStr('', 100, 'x'));
        RecU.Insert();
        Clear(GotU);
        GotU.Get(2);
        Observer.Observe('U-before-clear-get', Format(GotU.Data.Length()) + '|' + Format(GotU.Data.HasValue()));
        Clear(GotU.Data);
        Observer.Observe('U-cleared-var', Format(GotU.Data.Length()) + '|' + Format(GotU.Data.HasValue()));
        GotU.Modify();
        Observer.Observe('U-cleared-modified', Format(GotU.Data.Length()) + '|' + Format(GotU.Data.HasValue()));
        Clear(GotU);
        GotU.Get(2);
        Observer.Observe('U-cleared-get', Format(GotU.Data.Length()) + '|' + Format(GotU.Data.HasValue()));
        GotU.CalcFields(Data);
        Observer.Observe('U-cleared-getcalc', Format(GotU.Data.Length()) + '|' + Format(GotU.Data.HasValue()));
        RecC.DeleteAll();
        RecU.DeleteAll();
        Observer.Expect('C-empty-get', '0|No');
        Observer.Expect('U-empty-get', '0|No');
        Observer.Expect('C-before-clear-get', 'Yes|Yes');
        Observer.Expect('C-cleared-var', '0|No');
        Observer.Expect('C-cleared-modified', '0|No');
        Observer.Expect('C-cleared-get', '0|No');
        Observer.Expect('C-cleared-getcalc', '0|No');
        Observer.Expect('U-before-clear-get', '100|Yes');
        Observer.Expect('U-cleared-var', '0|No');
        Observer.Expect('U-cleared-modified', '0|No');
        Observer.Expect('U-cleared-get', '0|No');
        Observer.Expect('U-cleared-getcalc', '0|No');
        Observer.Verify();
    end;
}
