// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 94830-94831, codeunits 94832-94835 (log, helper, import runner, run runner)
// Probe: writer Y91. Shared fixtures of the XmlPort probes in this folder (ports in Y91XpPorts.al, tests in Y91XpTests.al): an item table, an input table for the
// import runner (a failed import is run through Codeunit.Run so the database stays as BC leaves it), exports into a stream, row listing.
// BC versions: 27-29

table 94830 "LT Y91 Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Amt; Decimal) { }
        field(4; Amt5; Decimal) { DecimalPlaces = 0 : 5; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The input of the import runner (used as a temporary record, never stored). Content is the document in, the port log out.
table 94831 "LT Y91 Input"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; PortId; Integer) { }
        field(3; Content; Text[2000]) { }
        field(4; Mode; Integer) { }
        field(5; ImportFlag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Hit log of the Xmlport.Run probes. SingleInstance: used by the one test codeunit "LT Y91 Run Tests" only.
codeunit 94832 "LT Y91 Run Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 94833 "LT Y91 Helper"
{
    procedure Seed()
    var
        Item: Record "LT Y91 Item";
    begin
        Item.DeleteAll();
        Item.Init();
        Item.Id := 1;
        Item.Name := 'one';
        Item.Insert();
        Item.Id := 2;
        Item.Name := 'two';
        Item.Insert();
    end;

    procedure Rows(): Text
    var
        Item: Record "LT Y91 Item";
        Result: Text;
    begin
        if Item.FindSet() then
            repeat
                Result += Format(Item.Id) + '/' + Item.Name + '/' + Format(Item.Amt, 0, 9) + ';';
            until Item.Next() = 0;
        exit(Result);
    end;

    // ok log=<port log> rows=<rows>, or error:<text>|<code> (+ rows)
    procedure Import(PortId: Integer; Mode: Integer; Doc: Text): Text
    var
        Input: Record "LT Y91 Input" temporary;
    begin
        Commit();
        Input.Init();
        Input.Id := 1;
        Input.PortId := PortId;
        Input.Mode := Mode;
        Input.Content := CopyStr(Doc, 1, MaxStrLen(Input.Content));
        Input.Insert();
        ClearLastError();
        if Codeunit.Run(Codeunit::"LT Y91 Import Runner", Input) then
            exit('ok log=' + Input.Content + ' rows=' + Rows());
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' rows=' + Rows());
    end;

    [TryFunction]
    local procedure DoExport(PortId: Integer; Mode: Integer; var Result: Text; var PortLog: Text)
    var
        P1: XmlPort "LT Y91 Root Xml";
        P2: XmlPort "LT Y91 Root VT";
        P3: XmlPort "LT Y91 Root Fixed";
        P4: XmlPort "LT Y91 Dec Xml";
        P5: XmlPort "LT Y91 Dec VT";
        P6: XmlPort "LT Y91 Dec Fixed";
        P7: XmlPort "LT Y91 Dec Legacy";
        P8: XmlPort "LT Y91 Width Text";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        case PortId of
            94836:
                begin
                    P1.SetMode(Mode);
                    P1.SetDestination(OutS);
                    P1.Export();
                    PortLog := P1.GetLog();
                end;
            94837:
                begin
                    P2.SetMode(Mode);
                    P2.SetDestination(OutS);
                    P2.Export();
                    PortLog := P2.GetLog();
                end;
            94838:
                begin
                    P3.SetMode(Mode);
                    P3.SetDestination(OutS);
                    P3.Export();
                    PortLog := P3.GetLog();
                end;
            94839:
                begin
                    P4.SetDestination(OutS);
                    P4.Export();
                end;
            94840:
                begin
                    P5.SetDestination(OutS);
                    P5.Export();
                end;
            94841:
                begin
                    P6.SetDestination(OutS);
                    P6.Export();
                end;
            94842:
                begin
                    P7.SetDestination(OutS);
                    P7.Export();
                end;
            94843:
                begin
                    P8.SetDestination(OutS);
                    P8.Export();
                    PortLog := P8.GetLog();
                end;
        end;
        if PortId in [94836, 94839, 94842, 94843] then
            Result := ReadRaw(TempBlob, TextEncoding::UTF16)
        else
            Result := ReadRaw(TempBlob, TextEncoding::UTF8);
    end;

    // The exported text exactly (line ends shown by the observer as \r \n), then " log=<port log>", or error:<text>|<code>.
    procedure Export(PortId: Integer; Mode: Integer): Text
    var
        Result: Text;
        PortLog: Text;
    begin
        ClearLastError();
        if DoExport(PortId, Mode, Result, PortLog) then
            exit(Result + ' log=' + PortLog);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReadRaw(var TempBlob: Codeunit "Temp Blob"; Enc: TextEncoding): Text
    var
        InS: InStream;
        Big: BigText;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, Enc);
        Big.Read(InS);
        if Big.Length() > 0 then
            Big.GetSubText(Result, 1, Big.Length());
        exit(Result);
    end;
}

codeunit 94834 "LT Y91 Import Runner"
{
    TableNo = "LT Y91 Input";

    trigger OnRun()
    var
        E1: XmlPort "LT Y91 Empty Forms";
        E2: XmlPort "LT Y91 Empty Forms Preserve";
        R1: XmlPort "LT Y91 Root Xml";
        R2: XmlPort "LT Y91 Root VT";
        R3: XmlPort "LT Y91 Root Fixed";
        W1: XmlPort "LT Y91 Width Text";
        W2: XmlPort "LT Y91 Width Unbound";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Rec.Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        case Rec.PortId of
            94833:
                begin
                    E1.SetSource(InS);
                    E1.Import();
                    Rec.Content := CopyStr(E1.GetLog(), 1, MaxStrLen(Rec.Content));
                end;
            94834:
                begin
                    E2.SetSource(InS);
                    E2.Import();
                    Rec.Content := CopyStr(E2.GetLog(), 1, MaxStrLen(Rec.Content));
                end;
            94836:
                begin
                    R1.SetMode(Rec.Mode);
                    R1.SetSource(InS);
                    R1.Import();
                    Rec.Content := CopyStr(R1.GetLog(), 1, MaxStrLen(Rec.Content));
                end;
            94837:
                begin
                    R2.SetMode(Rec.Mode);
                    R2.SetSource(InS);
                    R2.Import();
                    Rec.Content := CopyStr(R2.GetLog(), 1, MaxStrLen(Rec.Content));
                end;
            94838:
                begin
                    R3.SetMode(Rec.Mode);
                    R3.SetSource(InS);
                    R3.Import();
                    Rec.Content := CopyStr(R3.GetLog(), 1, MaxStrLen(Rec.Content));
                end;
            94843:
                begin
                    W1.SetSource(InS);
                    W1.Import();
                    Rec.Content := CopyStr(W1.GetLog(), 1, MaxStrLen(Rec.Content));
                end;
            94844:
                begin
                    W2.SetSource(InS);
                    W2.Import();
                    Rec.Content := CopyStr(W2.GetLog(), 1, MaxStrLen(Rec.Content));
                end;
        end;
    end;
}

// Static and instance Xmlport.Run without a stream. PortId picks the port, Mode: 1 static, 2 instance, 3 instance with SetTableView.
codeunit 94835 "LT Y91 Run Runner"
{
    TableNo = "LT Y91 Input";

    trigger OnRun()
    var
        Item: Record "LT Y91 Item";
        B: XmlPort "LT Y91 Run Both";
        X: XmlPort "LT Y91 Run Export";
        I: XmlPort "LT Y91 Run Import";
    begin
        case Rec.Mode of
            1:
                Xmlport.Run(Rec.PortId, false, Rec.ImportFlag);
            2:
                case Rec.PortId of
                    94845:
                        B.Run();
                    94846:
                        X.Run();
                    94847:
                        I.Run();
                end;
            3:
                begin
                    Item.SetRange(Id, 2);
                    case Rec.PortId of
                        94845:
                            begin
                                B.SetTableView(Item);
                                B.Run();
                            end;
                        94846:
                            begin
                                X.SetTableView(Item);
                                X.Run();
                            end;
                    end;
                end;
        end;
    end;
}
