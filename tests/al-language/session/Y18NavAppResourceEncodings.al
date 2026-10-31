// al-runner issue 6492: NavApp.GetResource(Name, InStream, Encoding) with UTF8, UTF16, Windows and MSDos (and no encoding),
// on resources saved in different byte forms. The UTF8 InStream read of an ASCII file is pinned in TestNavAppGetResource.al,
// GetResourceAsText encodings of an ASCII file in W5NavAppResources.al.
// The corpus app packages session/res; the five files in session/res/y18 hold the same two lines, 'Zürich' CR LF 'Größe 5 €'
// (no line break at the end), saved as:
//   utf16le-bom.txt    FF FE + UTF-16LE (36 bytes)
//   utf16le-nobom.txt  UTF-16LE, no byte order mark (34 bytes)
//   utf8-bom.txt       EF BB BF + UTF-8 (25 bytes)
//   utf8-nobom.txt     UTF-8, no byte order mark (22 bytes)
//   windows1252.txt    Windows-1252: ü FC, ö F6, ß DF, € 80 (17 bytes)
// high-bytes.bin holds the bytes 80..FF once each, read with one InStream.Read(Text) in MSDos and in Windows.
// Each test reads one file with every encoding, three ways:
//   lines  ReadText until EOS: per line the count ReadText returned and the line
//   read   one InStream.Read(Text) on a fresh stream: the count it returned and the text
//   copy   CopyStream into the Blob of a temporary record, then ReadText until EOS from CreateInStream(TextEncoding::UTF8)
// 'default' is GetResource(Name, InStream) without an encoding (lines only). A read that raises shows as error:<text>|<code>.
// A character outside 32..126 is shown as <code> (its integer value), so the observed text is plain ASCII.

table 91900 "LT Y18 Res Blob"
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

codeunit 91901 "LT Y18 Res Encodings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Utf16LeWithBom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadAll(Observer, 'y18/utf16le-bom.txt');
        Observer.Expect('default lines', '3:<160><254>Z|1:<253>|1:r|1:i|1:c|1:h|0:|0:|0:|1:G|1:r|1:<247>|1:<200>|1:e|1: |1:5|1: |2:<188> |');
        Observer.Expect('utf8 lines', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('utf8 read', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('utf8 copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('utf16 lines', '12:Z<252>rich|18:Gr<246><223>e 5 <8364>|');
        Observer.Expect('utf16 read', '36:Z<252>rich<13><10>Gr<246><223>e 5 <8364>|eos=Yes');
        Observer.Expect('utf16 copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('windows lines', '3:<255><254>Z|1:<252>|1:r|1:i|1:c|1:h|0:|0:|0:|1:G|1:r|1:<246>|1:<223>|1:e|1: |1:5|1: |2:<172> |');
        Observer.Expect('windows read', '4:<255><254>Z|eos=No');
        Observer.Expect('windows copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('msdos lines', '3:<160><254>Z|1:<253>|1:r|1:i|1:c|1:h|0:|0:|0:|1:G|1:r|1:<247>|1:<200>|1:e|1: |1:5|1: |2:<188> |');
        Observer.Expect('msdos read', '4:<160><254>Z|eos=No');
        Observer.Expect('msdos copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Utf16LeWithoutBom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadAll(Observer, 'y18/utf16le-nobom.txt');
        Observer.Expect('default lines', '1:Z|1:<253>|1:r|1:i|1:c|1:h|0:|0:|0:|1:G|1:r|1:<247>|1:<200>|1:e|1: |1:5|1: |2:<188> |');
        Observer.Expect('utf8 lines', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('utf8 read', '2:Z|eos=No');
        Observer.Expect('utf8 copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('utf16 lines', '12:Z<252>rich|18:Gr<246><223>e 5 <8364>|');
        Observer.Expect('utf16 read', '36:Z<252>rich<13><10>Gr<246><223>e 5 <8364>|eos=Yes');
        Observer.Expect('utf16 copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('windows lines', '1:Z|1:<252>|1:r|1:i|1:c|1:h|0:|0:|0:|1:G|1:r|1:<246>|1:<223>|1:e|1: |1:5|1: |2:<172> |');
        Observer.Expect('windows read', '2:Z|eos=No');
        Observer.Expect('windows copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('msdos lines', '1:Z|1:<253>|1:r|1:i|1:c|1:h|0:|0:|0:|1:G|1:r|1:<247>|1:<200>|1:e|1: |1:5|1: |2:<188> |');
        Observer.Expect('msdos read', '2:Z|eos=No');
        Observer.Expect('msdos copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Utf8WithBom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadAll(Observer, 'y18/utf8-bom.txt');
        Observer.Expect('default lines', '10:<217><8249><143>Z<8220><338>rich|13:Gr<8220><8224><8220><402>e 5 <203><233><188>|');
        Observer.Expect('utf8 lines', '7:Z<252>rich|13:Gr<246><223>e 5 <8364>|');
        Observer.Expect('utf8 read', '23:Z<252>rich<13><10>Gr<246><223>e 5 <8364>|eos=Yes');
        Observer.Expect('utf8 copy', '7:Z<252>rich|13:Gr<246><223>e 5 <8364>|');
        Observer.Expect('utf16 lines', '24:<48111><23231><48323><26994><26723><2573><29255><46787><40899><8293><8245><33506>|');
        Observer.Expect('utf16 read', '26:<48111><23231><48323><26994><26723><2573><29255><46787><40899><8293><8245><33506>|eos=Yes');
        Observer.Expect('utf16 copy', '7:Z<252>rich|13:Gr<246><223>e 5 <8364>|');
        Observer.Expect('windows lines', '10:<239><187><191>Z<195><188>rich|13:Gr<195><182><195><376>e 5 <226><8218><172>|');
        Observer.Expect('windows read', '25:<239><187><191>Z<195><188>rich<13><10>Gr<195><182><195><376>e 5 <226><8218><172>|eos=Yes');
        Observer.Expect('windows copy', '7:Z<252>rich|13:Gr<246><223>e 5 <8364>|');
        Observer.Expect('msdos lines', '10:<217><8249><143>Z<8220><338>rich|13:Gr<8220><8224><8220><402>e 5 <203><233><188>|');
        Observer.Expect('msdos read', '25:<217><8249><143>Z<8220><338>rich<13><10>Gr<8220><8224><8220><402>e 5 <203><233><188>|eos=Yes');
        Observer.Expect('msdos copy', '7:Z<252>rich|13:Gr<246><223>e 5 <8364>|');
        Observer.Verify();
    end;

    [Test]
    procedure Utf8WithoutBom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadAll(Observer, 'y18/utf8-nobom.txt');
        Observer.Expect('default lines', '7:Z<8220><338>rich|13:Gr<8220><8224><8220><402>e 5 <203><233><188>|');
        Observer.Expect('utf8 lines', '7:Z<252>rich|13:Gr<246><223>e 5 <8364>|');
        Observer.Expect('utf8 read', '23:Z<252>rich<13><10>Gr<246><223>e 5 <8364>|eos=Yes');
        Observer.Expect('utf8 copy', '7:Z<252>rich|13:Gr<246><223>e 5 <8364>|');
        Observer.Expect('utf16 lines', '22:<50010><29372><25449><3432><18186><50034><50102><26015><13600><57888><44162>|');
        Observer.Expect('utf16 read', '24:<50010><29372><25449><3432><18186><50034><50102><26015><13600><57888><44162>|eos=Yes');
        Observer.Expect('utf16 copy', '7:Z<252>rich|13:Gr<246><223>e 5 <8364>|');
        Observer.Expect('windows lines', '7:Z<195><188>rich|13:Gr<195><182><195><376>e 5 <226><8218><172>|');
        Observer.Expect('windows read', '22:Z<195><188>rich<13><10>Gr<195><182><195><376>e 5 <226><8218><172>|eos=Yes');
        Observer.Expect('windows copy', '7:Z<252>rich|13:Gr<246><223>e 5 <8364>|');
        Observer.Expect('msdos lines', '7:Z<8220><338>rich|13:Gr<8220><8224><8220><402>e 5 <203><233><188>|');
        Observer.Expect('msdos read', '22:Z<8220><338>rich<13><10>Gr<8220><8224><8220><402>e 5 <203><233><188>|eos=Yes');
        Observer.Expect('msdos copy', '7:Z<252>rich|13:Gr<246><223>e 5 <8364>|');
        Observer.Verify();
    end;

    [Test]
    procedure Windows1252()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadAll(Observer, 'y18/windows1252.txt');
        Observer.Expect('default lines', '6:Z<253>rich|9:Gr<247><200>e 5 <199>|');
        Observer.Expect('utf8 lines', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('utf8 read', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('utf8 copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('utf16 lines', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('utf16 read', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('utf16 copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('windows lines', '6:Z<252>rich|9:Gr<246><223>e 5 <8364>|');
        Observer.Expect('windows read', '17:Z<252>rich<13><10>Gr<246><223>e 5 <8364>|eos=Yes');
        Observer.Expect('windows copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('msdos lines', '6:Z<253>rich|9:Gr<247><200>e 5 <199>|');
        Observer.Expect('msdos read', '17:Z<253>rich<13><10>Gr<247><200>e 5 <199>|eos=Yes');
        Observer.Expect('msdos copy', 'error:Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure HighBytesMsDos()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('msdos read', Probe('y18/high-bytes.bin', 'read', TextEncoding::MSDos, false));
        Observer.Expect('msdos read', '128:<199><252><233><226><228><224><229><231><234><235><232><239><238><236><196><197><201><230><198><244><246><242><251><249><255><214><220><162><163><165><15><402><225><237><243><250><241><209><170><186><191><20><172><189><188><161><171><187><21><8364><129><8218><8222><8230><8224><8225><710><8240><352><8249><338><141><381><143><144><8216><8217><8220><8221><8226><8211><8212><732><8482><353><8250><339><157><382><376><168><169><173><174><175><179><180><184><185><190><192><193><194><166><195><200><202><223><203><204><205><206><181><207><208><210><211><212><213><215><216><217><218><177><219><221><222><227><247><240><176><245><183><248><253><178><254><160>|eos=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure HighBytesWindows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('windows read', Probe('y18/high-bytes.bin', 'read', TextEncoding::Windows, false));
        Observer.Expect('windows read', '128:<8364><129><8218><402><8222><8230><8224><8225><710><8240><352><8249><338><141><381><143><144><8216><8217><8220><8221><8226><8211><8212><732><8482><353><8250><339><157><382><376><160><161><162><163><164><165><166><167><168><169><170><171><172><173><174><175><176><177><178><179><180><181><182><183><184><185><186><187><188><189><190><191><192><193><194><195><196><197><198><199><200><201><202><203><204><205><206><207><208><209><210><211><212><213><214><215><216><217><218><219><220><221><222><223><224><225><226><227><228><229><230><231><232><233><234><235><236><237><238><239><240><241><242><243><244><245><246><247><248><249><250><251><252><253><254><255>|eos=Yes');
        Observer.Verify();
    end;

    local procedure ReadAll(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.Observe('default lines', Probe(Name, 'lines', TextEncoding::UTF8, true));
        Observer.Observe('utf8 lines', Probe(Name, 'lines', TextEncoding::UTF8, false));
        Observer.Observe('utf8 read', Probe(Name, 'read', TextEncoding::UTF8, false));
        Observer.Observe('utf8 copy', Probe(Name, 'copy', TextEncoding::UTF8, false));
        Observer.Observe('utf16 lines', Probe(Name, 'lines', TextEncoding::UTF16, false));
        Observer.Observe('utf16 read', Probe(Name, 'read', TextEncoding::UTF16, false));
        Observer.Observe('utf16 copy', Probe(Name, 'copy', TextEncoding::UTF16, false));
        Observer.Observe('windows lines', Probe(Name, 'lines', TextEncoding::Windows, false));
        Observer.Observe('windows read', Probe(Name, 'read', TextEncoding::Windows, false));
        Observer.Observe('windows copy', Probe(Name, 'copy', TextEncoding::Windows, false));
        Observer.Observe('msdos lines', Probe(Name, 'lines', TextEncoding::MSDos, false));
        Observer.Observe('msdos read', Probe(Name, 'read', TextEncoding::MSDos, false));
        Observer.Observe('msdos copy', Probe(Name, 'copy', TextEncoding::MSDos, false));
    end;

    // The read as text, or 'error:' + the error text and code when the read raises.
    local procedure Probe(Name: Text; Kind: Text; Encoding: TextEncoding; NoEncoding: Boolean): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryRead(Name, Kind, Encoding, NoEncoding, Result) then
            exit(Result);
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRead(Name: Text; Kind: Text; Encoding: TextEncoding; NoEncoding: Boolean; var Result: Text)
    var
        TempRes: Record "LT Y18 Res Blob" temporary;
        S: InStream;
        Back: InStream;
        O: OutStream;
        Content: Text;
        N: Integer;
    begin
        if NoEncoding then
            NavApp.GetResource(Name, S)
        else
            NavApp.GetResource(Name, S, Encoding);
        case Kind of
            'lines':
                Result := ReadLines(S);
            'read':
                begin
                    N := S.Read(Content);
                    Result := Format(N) + ':' + Shown(Content) + '|eos=' + Format(S.EOS());
                end;
            'copy':
                begin
                    TempRes.Id := 1;
                    TempRes.Data.CreateOutStream(O);
                    CopyStream(O, S);
                    TempRes.Insert();
                    TempRes.Data.CreateInStream(Back, TextEncoding::UTF8);
                    Result := ReadLines(Back);
                end;
        end;
    end;

    local procedure ReadLines(var S: InStream): Text
    var
        Line: Text;
        Result: Text;
        N: Integer;
        Guard: Integer;
    begin
        while (not S.EOS()) and (Guard < 40) do begin
            Guard += 1;
            N := S.ReadText(Line);
            Result += Format(N) + ':' + Shown(Line) + '|';
        end;
        exit(Result);
    end;

    local procedure Shown(Value: Text): Text
    var
        i: Integer;
        Code: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            if (Code < 32) or (Code > 126) then
                Result += '<' + Format(Code, 0, 9) + '>'
            else
                Result += CopyStr(Value, i, 1);
        end;
        exit(Result);
    end;
}
