// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: own tables 71831-71833, helper codeunit 71834, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Shared fixtures of the P112 xmlport probes: not a test codeunit.
// BC versions: 29 (27 and 28 by CI)

table 71831 "LT P112 Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 71832 "LT P112 Blob"
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

table 71833 "LT P112 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ItemId; Integer) { }
        field(3; Note; Text[20]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71834 "LT P112 Helper"
{
    procedure Wipe()
    var
        Item: Record "LT P112 Item";
        Line: Record "LT P112 Line";
        Blob: Record "LT P112 Blob";
    begin
        Item.DeleteAll();
        Line.DeleteAll();
        Blob.DeleteAll();
    end;

    procedure AddItem(Id: Integer; Name: Text; Qty: Integer)
    var
        Item: Record "LT P112 Item";
    begin
        Item.Id := Id;
        Item.Name := CopyStr(Name, 1, MaxStrLen(Item.Name));
        Item.Qty := Qty;
        Item.Insert();
    end;

    procedure AddLine(Id: Integer; ItemId: Integer; Note: Text)
    var
        Line: Record "LT P112 Line";
    begin
        Line.Id := Id;
        Line.ItemId := ItemId;
        Line.Note := CopyStr(Note, 1, MaxStrLen(Line.Note));
        Line.Insert();
    end;

    procedure SeedThree()
    begin
        Wipe();
        AddItem(1, 'Alpha', 10);
        AddItem(2, 'Beta', 20);
        AddItem(3, 'Gamma', 30);
    end;

    procedure DumpItems(): Text
    var
        Item: Record "LT P112 Item";
        Result: Text;
    begin
        if Item.FindSet() then
            repeat
                Result += Format(Item.Id) + '=' + Item.Name + '/' + Format(Item.Qty) + ';';
            until Item.Next() = 0;
        exit('[' + Result + ']');
    end;

    procedure DumpLines(): Text
    var
        Line: Record "LT P112 Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Format(Line.Id) + '=' + Format(Line.ItemId) + '/' + Line.Note + ';';
            until Line.Next() = 0;
        exit('[' + Result + ']');
    end;

    procedure ReadBlob(var Row: Record "LT P112 Blob"): Text
    var
        InS: InStream;
        Big: BigText;
        Result: Text;
    begin
        Row.Data.CreateInStream(InS, TextEncoding::UTF8);
        Big.Read(InS);
        if Big.Length() = 0 then
            exit('');
        Big.GetSubText(Result, 1, Big.Length());
        exit(Flat(Result));
    end;

    procedure Source(var Row: Record "LT P112 Blob"; Content: Text; var InS: InStream)
    var
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        Row.Data.CreateInStream(InS, TextEncoding::UTF8);
    end;

    procedure Chr(Code: Integer): Text
    var
        C: Text[1];
    begin
        C[1] := Code;
        exit(C);
    end;

    procedure Flat(Value: Text): Text
    begin
        exit(Value.Replace(Chr(13), '<CR>').Replace(Chr(10), '<LF>'));
    end;
}
