// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures: tables 94330-94332 and 94337, codeunits 94333 (helper), 94335 (import runner), 94338 and 94339 (runners); test codeunits 94334 (Y83XpNsTests.al) and 94336 (Y83XpMiscTests.al)
// Probe: corpus issue (Y83). Shared helper of the XmlPort shape probes: exports a port into a stream and reads the text back, imports a text through
// Codeunit.Run (so a failed import leaves the database as BC leaves it), lists the rows of the item table.
// BC versions: 27-29

table 94330 "LT Y83 Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Amt; Decimal) { }
        field(4; Flag; Boolean) { }
        field(5; D; Date) { }
        field(6; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 94331 "LT Y83 Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ItemId; Integer) { }
        field(3; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The input of the import runner (used as a temporary record, never stored).
table 94332 "LT Y83 Input"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; PortId; Integer) { }
        field(3; Content; Text[2000]) { }
        field(4; Utf16; Boolean) { }
        field(5; Language; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 94337 "LT Y83 Filter Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tf; TableFilter) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 94335 "LT Y83 Import Runner"
{
    TableNo = "LT Y83 Input";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Enc: TextEncoding;
    begin
        if Rec.Utf16 then
            Enc := TextEncoding::UTF16
        else
            Enc := TextEncoding::UTF8;
        TempBlob.CreateOutStream(OutS, Enc);
        OutS.WriteText(Rec.Content);
        TempBlob.CreateInStream(InS, Enc);
        if Rec.Language <> 0 then
            GlobalLanguage(Rec.Language);
        Xmlport.Import(Rec.PortId, InS);
    end;
}

// Imports through an instance with a table view (the record passed to Codeunit.Run carries its filters).
codeunit 94338 "LT Y83 View Runner"
{
    TableNo = "LT Y83 Item";

    trigger OnRun()
    var
        XP: XmlPort "LT Y83 Request Filter";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        XP.SetTableView(Rec);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Item><Id>7</Id><Name>seven</Name><Child><Txt>t</Txt></Child></Item></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        XP.SetSource(InS);
        XP.Import();
    end;
}

// Imports through an instance of a container trigger port and returns its log in Rec.Content (Rec.PortId picks the port, Rec.Content is the document).
codeunit 94339 "LT Y83 Container Runner"
{
    TableNo = "LT Y83 Input";

    trigger OnRun()
    var
        XP1: XmlPort "LT Y83 Container Triggers";
        XP2: XmlPort "LT Y83 Attr Only Text";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Rec.Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        if Rec.PortId = 94378 then begin
            XP1.SetSource(InS);
            XP1.Import();
            Rec.Content := CopyStr(XP1.GetLog(), 1, MaxStrLen(Rec.Content));
        end else begin
            XP2.SetSource(InS);
            XP2.Import();
            Rec.Content := CopyStr(XP2.GetLog(), 1, MaxStrLen(Rec.Content));
        end;
    end;
}

codeunit 94333 "LT Y83 Helper"
{
    procedure DeleteAll()
    var
        Item: Record "LT Y83 Item";
        Child: Record "LT Y83 Child";
    begin
        Item.DeleteAll();
        Child.DeleteAll();
        Commit();
    end;

    procedure ImportView(): Text
    var
        Item: Record "LT Y83 Item";
    begin
        Seed();
        Item.SetRange(Id, 1);
        Commit();
        ClearLastError();
        if Codeunit.Run(Codeunit::"LT Y83 View Runner", Item) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoContainerExport(PortId: Integer; var Result: Text)
    var
        XP1: XmlPort "LT Y83 Container Triggers";
        XP2: XmlPort "LT Y83 Attr Only Text";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        if PortId = 94378 then begin
            XP1.SetDestination(OutS);
            XP1.Export();
            Result := 'log=' + XP1.GetLog();
        end else begin
            XP2.SetDestination(OutS);
            XP2.Export();
            Result := 'log=' + XP2.GetLog();
        end;
        Result += ' text=' + ReadStream(TempBlob, TextEncoding::UTF16);
    end;

    procedure ContainerExport(PortId: Integer): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if DoContainerExport(PortId, Result) then
            exit(Result);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    procedure ContainerImport(PortId: Integer; Doc: Text): Text
    var
        Input: Record "LT Y83 Input" temporary;
    begin
        Commit();
        Input.Init();
        Input.Id := 1;
        Input.PortId := PortId;
        Input.Content := CopyStr(Doc, 1, MaxStrLen(Input.Content));
        Input.Insert();
        ClearLastError();
        if Codeunit.Run(Codeunit::"LT Y83 Container Runner", Input) then
            exit('ok log=' + Input.Content);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    procedure CrLf(): Text
    var
        Result: Text[2];
    begin
        Result[1] := 13;
        Result[2] := 10;
        exit(Result);
    end;

    procedure Seed()
    var
        Item: Record "LT Y83 Item";
        Child: Record "LT Y83 Child";
    begin
        Item.DeleteAll();
        Child.DeleteAll();
        Item.Init();
        Item.Id := 1;
        Item.Name := 'one';
        Item.Amt := 1.5;
        Item.Flag := true;
        Item.D := DMY2Date(5, 3, 2024);
        Item.Qty := 5;
        Item.Insert();
        Item.Init();
        Item.Id := 2;
        Item.Name := '  two  ';
        Item.Amt := 2.005;
        Item.Qty := 6;
        Item.Insert();
        Child.Init();
        Child.Id := 1;
        Child.ItemId := 1;
        Child.Txt := 'c1a';
        Child.Insert();
        Child.Id := 2;
        Child.ItemId := 1;
        Child.Txt := 'c1b';
        Child.Insert();
        Child.Id := 3;
        Child.ItemId := 2;
        Child.Txt := 'c2a';
        Child.Insert();
        Commit();
    end;

    procedure Rows(): Text
    var
        Item: Record "LT Y83 Item";
        Result: Text;
    begin
        if Item.FindSet() then
            repeat
                Result += Format(Item.Id) + '/' + Item.Name + '/' + Format(Item.Amt, 0, 9) + '/' + Format(Item.Flag, 0, 9) + '/' + Format(Item.D, 0, 9) + '/' + Format(Item.Qty) + ';';
            until Item.Next() = 0;
        exit(Result);
    end;

    procedure ChildRows(): Text
    var
        Child: Record "LT Y83 Child";
        Result: Text;
    begin
        if Child.FindSet() then
            repeat
                Result += Format(Child.Id) + '/' + Format(Child.ItemId) + '/' + Child.Txt + ';';
            until Child.Next() = 0;
        exit(Result);
    end;

    procedure ReadStream(var TempBlob: Codeunit "Temp Blob"; Enc: TextEncoding): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, Enc);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure ExportText(XmlPortId: Integer; Enc: TextEncoding): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlPortId, OutS);
        exit(ReadStream(TempBlob, Enc));
    end;

    local procedure ExportRawText(XmlPortId: Integer; Enc: TextEncoding): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Big: BigText;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlPortId, OutS);
        TempBlob.CreateInStream(InS, Enc);
        Big.Read(InS);
        if Big.Length() > 0 then
            Big.GetSubText(Result, 1, Big.Length());
        exit(Result);
    end;

    [TryFunction]
    local procedure DoExportRaw(XmlPortId: Integer; Enc: TextEncoding; var Result: Text)
    begin
        Result := ExportRawText(XmlPortId, Enc);
    end;

    // The exported text exactly (line ends kept), or error:<text>|<code>.
    procedure TryExportRaw(XmlPortId: Integer; Enc: TextEncoding): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if DoExportRaw(XmlPortId, Enc, Result) then
            exit(Result);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoExport(XmlPortId: Integer; Enc: TextEncoding; var Result: Text)
    begin
        Result := ExportText(XmlPortId, Enc);
    end;

    // The exported text (lines joined by |), or error:<text>|<code>.
    procedure TryExport(XmlPortId: Integer; Enc: TextEncoding): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if DoExport(XmlPortId, Enc, Result) then
            exit(Result);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // ok, or error:<text>|<code>.
    procedure TryImport(XmlPortId: Integer; Content: Text; Utf16: Boolean): Text
    begin
        exit(TryImportIn(XmlPortId, Content, Utf16, 0));
    end;

    procedure TryImportIn(XmlPortId: Integer; Content: Text; Utf16: Boolean; Language: Integer): Text
    var
        Input: Record "LT Y83 Input" temporary;
        OldLanguage: Integer;
        Result: Text;
    begin
        Commit();
        OldLanguage := GlobalLanguage();
        Input.Init();
        Input.Id := 1;
        Input.PortId := XmlPortId;
        Input.Content := CopyStr(Content, 1, MaxStrLen(Input.Content));
        Input.Utf16 := Utf16;
        Input.Language := Language;
        Input.Insert();
        ClearLastError();
        if Codeunit.Run(Codeunit::"LT Y83 Import Runner", Input) then
            Result := 'ok'
        else
            Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        GlobalLanguage(OldLanguage);
        exit(Result);
    end;
}
