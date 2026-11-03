// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/blob/blob-length-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 95040 and 95041 and codeunit 95042 below
// Probe: PROBE IN PROGRESS (observe first). Question (al-runner issue 6896): is the stored size that Blob.Length gives before CalcFields positive for every non-empty content whenever HasValue is Yes.
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
                        Tb.Append(CopyStr('abcdefghijklmnopqrstuvwxyz', (Big mod 26) + 1, 1));
                    end;
                    OutS.WriteText(Tb.ToText());
                end;
        end;
    end;

    local procedure MeasureCompressed(var Observer: Codeunit "Probe Observer"; Key: Text; Kind: Integer; N: Integer)
    var
        Rec: Record "LT BSS Compressed";
        Got: Record "LT BSS Compressed";
        Got2: Record "LT BSS Compressed";
        OutS: OutStream;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        if N > 0 then begin
            Rec.Data.CreateOutStream(OutS);
            WriteContent(OutS, Kind, N);
        end;
        Observer.Observe('C-' + Key + '-written', Format(Rec.Data.Length()) + '|' + Format(Rec.Data.HasValue()));
        Rec.Insert();
        Observer.Observe('C-' + Key + '-inserted', Format(Rec.Data.Length()) + '|' + Format(Rec.Data.HasValue()));
        Got.Get(1);
        Observer.Observe('C-' + Key + '-get', Format(Got.Data.Length()) + '|' + Format(Got.Data.HasValue()));
        Got.CalcFields(Data);
        Observer.Observe('C-' + Key + '-getcalc', Format(Got.Data.Length()) + '|' + Format(Got.Data.HasValue()));
        Got2.SetRange(Id, 1);
        Got2.FindSet();
        Observer.Observe('C-' + Key + '-findset', Format(Got2.Data.Length()) + '|' + Format(Got2.Data.HasValue()));
        Got2.CalcFields(Data);
        Observer.Observe('C-' + Key + '-findsetcalc', Format(Got2.Data.Length()) + '|' + Format(Got2.Data.HasValue()));
        Clear(Rec);
        Clear(Got);
        Rec.Id := 2;
        Rec.Insert();
        if N > 0 then begin
            Rec.Data.CreateOutStream(OutS);
            WriteContent(OutS, Kind, N);
        end;
        Rec.Modify();
        Observer.Observe('C-' + Key + '-modified', Format(Rec.Data.Length()) + '|' + Format(Rec.Data.HasValue()));
        Got.Get(2);
        Observer.Observe('C-' + Key + '-modget', Format(Got.Data.Length()) + '|' + Format(Got.Data.HasValue()));
        Got.CalcFields(Data);
        Observer.Observe('C-' + Key + '-modgetcalc', Format(Got.Data.Length()) + '|' + Format(Got.Data.HasValue()));
        Rec.DeleteAll();
    end;

    local procedure MeasurePlain(var Observer: Codeunit "Probe Observer"; Key: Text; Kind: Integer; N: Integer)
    var
        Rec: Record "LT BSS Plain";
        Got: Record "LT BSS Plain";
        Got2: Record "LT BSS Plain";
        OutS: OutStream;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        if N > 0 then begin
            Rec.Data.CreateOutStream(OutS);
            WriteContent(OutS, Kind, N);
        end;
        Observer.Observe('U-' + Key + '-written', Format(Rec.Data.Length()) + '|' + Format(Rec.Data.HasValue()));
        Rec.Insert();
        Observer.Observe('U-' + Key + '-inserted', Format(Rec.Data.Length()) + '|' + Format(Rec.Data.HasValue()));
        Got.Get(1);
        Observer.Observe('U-' + Key + '-get', Format(Got.Data.Length()) + '|' + Format(Got.Data.HasValue()));
        Got.CalcFields(Data);
        Observer.Observe('U-' + Key + '-getcalc', Format(Got.Data.Length()) + '|' + Format(Got.Data.HasValue()));
        Got2.SetRange(Id, 1);
        Got2.FindSet();
        Observer.Observe('U-' + Key + '-findset', Format(Got2.Data.Length()) + '|' + Format(Got2.Data.HasValue()));
        Got2.CalcFields(Data);
        Observer.Observe('U-' + Key + '-findsetcalc', Format(Got2.Data.Length()) + '|' + Format(Got2.Data.HasValue()));
        Clear(Rec);
        Clear(Got);
        Rec.Id := 2;
        Rec.Insert();
        if N > 0 then begin
            Rec.Data.CreateOutStream(OutS);
            WriteContent(OutS, Kind, N);
        end;
        Rec.Modify();
        Observer.Observe('U-' + Key + '-modified', Format(Rec.Data.Length()) + '|' + Format(Rec.Data.HasValue()));
        Got.Get(2);
        Observer.Observe('U-' + Key + '-modget', Format(Got.Data.Length()) + '|' + Format(Got.Data.HasValue()));
        Got.CalcFields(Data);
        Observer.Observe('U-' + Key + '-modgetcalc', Format(Got.Data.Length()) + '|' + Format(Got.Data.HasValue()));
        Rec.DeleteAll();
    end;

    local procedure Both(var Observer: Codeunit "Probe Observer"; Key: Text; Kind: Integer; N: Integer)
    begin
        MeasureCompressed(Observer, Key, Kind, N);
        MeasurePlain(Observer, Key, Kind, N);
    end;

    [Test]
    procedure Probe_SmallText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'text1', 1, 1);
        Both(Observer, 'text2', 1, 2);
        Both(Observer, 'text5', 1, 5);
        Both(Observer, 'text100', 1, 100);
        Both(Observer, 'text1000', 1, 1000);
        Both(Observer, 'text4000', 1, 4000);
        Observer.Finish();
    end;

    [Test]
    procedure Probe_Xml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'xml600', 2, 600);
        Both(Observer, 'xml3800', 2, 3800);
        Observer.Finish();
    end;

    [Test]
    procedure Probe_Binary()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'rand1000', 3, 1000);
        Both(Observer, 'rand100000', 3, 100000);
        Both(Observer, 'zero1000', 4, 1000);
        Both(Observer, 'zero100000', 4, 100000);
        Both(Observer, 'byte1000', 5, 1000);
        Both(Observer, 'byte100000', 5, 100000);
        Both(Observer, 'rtext1000', 6, 1000);
        Both(Observer, 'rtext100000', 6, 100000);
        Observer.Finish();
    end;

    [Test]
    procedure Probe_OneMegabyte()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'text1m', 1, 1048576);
        Both(Observer, 'rand1m', 3, 1048576);
        Both(Observer, 'zero1m', 4, 1048576);
        Both(Observer, 'rtext1m', 6, 1048576);
        Observer.Finish();
    end;

    [Test]
    procedure Probe_FiveMegabytes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'text5m', 1, 5242880);
        Both(Observer, 'rand5m', 3, 5242880);
        Observer.Finish();
    end;

    [Test]
    procedure Probe_EmptyAndCleared()
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
        Observer.Observe('C-before-clear-get', Format(GotC.Data.Length()) + '|' + Format(GotC.Data.HasValue()));
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
        Observer.Finish();
    end;
}
