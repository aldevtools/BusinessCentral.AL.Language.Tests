// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: own tables 73406-73409, helper codeunit 73430, DataTransfer runner 73450
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Shared fixtures for the XmlPort / Query / DataTransfer probes (tag XpT): tables and the helper codeunit (not a test codeunit).
// BC versions: 29 (27 and 28 by CI)

table 73406 "LT XpT Item"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Qty; Integer) { }
        field(4; Amount; Decimal) { }
        field(5; Active; Boolean) { }
        field(6; Category; Code[10]) { }
        field(7; StampDate; Date) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73407 "LT XpT Line"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; ItemId; Integer) { }
        field(3; Descr; Text[50]) { }
        field(4; Qty; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73408 "LT XpT Target"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Qty; Integer) { }
        field(4; Amount; Decimal) { }
        field(5; Active; Boolean) { }
        field(6; Category; Code[10]) { }
        field(7; Note; Text[50]) { }
        field(8; ShortName; Text[3]) { }
        field(9; StampDate; Date) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73409 "LT XpT Blob"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Mode; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73430 "LT XpT Helper"
{
    var
        LenValue: Integer;

    procedure Wipe()
    var
        Item: Record "LT XpT Item";
        Line: Record "LT XpT Line";
        Tgt: Record "LT XpT Target";
        B: Record "LT XpT Blob";
    begin
        Item.DeleteAll();
        Line.DeleteAll();
        Tgt.DeleteAll();
        B.DeleteAll();
    end;

    procedure AddItem(Id: Integer; Name: Text; Qty: Integer; Amount: Decimal; Active: Boolean; Category: Code[10]; StampDate: Date)
    var
        Item: Record "LT XpT Item";
    begin
        Item.Id := Id;
        Item.Name := CopyStr(Name, 1, MaxStrLen(Item.Name));
        Item.Qty := Qty;
        Item.Amount := Amount;
        Item.Active := Active;
        Item.Category := Category;
        Item.StampDate := StampDate;
        Item.Insert();
    end;

    procedure AddLine(Id: Integer; ItemId: Integer; Descr: Text; Qty: Integer)
    var
        Line: Record "LT XpT Line";
    begin
        Line.Id := Id;
        Line.ItemId := ItemId;
        Line.Descr := CopyStr(Descr, 1, MaxStrLen(Line.Descr));
        Line.Qty := Qty;
        Line.Insert();
    end;

    procedure Seed()
    begin
        AddItem(1, 'Alpha', 10, 1.5, true, 'A', 20240115D);
        AddItem(2, 'Beta', 20, 2.5, false, 'A', 20231231D);
        AddItem(3, 'Gamma', 30, 3.5, true, 'B', 0D);
        AddLine(1, 1, 'L1a', 1);
        AddLine(2, 1, 'L1b', 2);
        AddLine(3, 2, 'L2a', 5);
    end;

    procedure ReadAll(var InS: InStream): Text
    var
        Line: Text;
        Result: Text;
        First: Boolean;
    begin
        First := true;
        while not InS.EOS do begin
            InS.ReadText(Line);
            if not First then
                Result += '<NL>';
            Result += Line;
            First := false;
        end;
        exit(Result);
    end;

    procedure ExportText(XmlportId: Integer): Text
    begin
        exit(ExportTextEnc(XmlportId, TextEncoding::UTF8));
    end;

    procedure ExportTextEnc(XmlportId: Integer; Enc: TextEncoding): Text
    var
        TB: Record "LT XpT Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        TB.Data.CreateOutStream(OutS);
        Xmlport.Export(XmlportId, OutS);
        LenValue := TB.Data.Length;
        TB.Data.CreateInStream(InS, Enc);
        exit(ReadAll(InS));
    end;

    procedure ExportWithRec(XmlportId: Integer; var Item: Record "LT XpT Item"): Text
    var
        TB: Record "LT XpT Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        TB.Data.CreateOutStream(OutS);
        Xmlport.Export(XmlportId, OutS, Item);
        TB.Data.CreateInStream(InS);
        exit(ReadAll(InS));
    end;

    procedure ImportText(XmlportId: Integer; Txt: Text)
    begin
        ImportTextEnc(XmlportId, Txt, TextEncoding::UTF8);
    end;

    procedure ImportTextEnc(XmlportId: Integer; Txt: Text; Enc: TextEncoding)
    var
        TB: Record "LT XpT Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        TB.Data.CreateOutStream(OutS, Enc);
        OutS.WriteText(Txt);
        TB.Data.CreateInStream(InS, Enc);
        Xmlport.Import(XmlportId, InS);
    end;

    procedure Chr(Code: Integer): Text
    var
        C: Text[1];
    begin
        C[1] := Code;
        exit(C);
    end;

    procedure TryImport(XmlportId: Integer; Txt: Text): Text
    begin
        exit(TryImportEnc(XmlportId, Txt, TextEncoding::UTF8));
    end;

    procedure TryImportEnc(XmlportId: Integer; Txt: Text; Enc: TextEncoding): Text
    var
        TB: Record "LT XpT Blob" temporary;
        OutS: OutStream;
    begin
        TB.Id := XmlportId;
        case Enc of
            TextEncoding::UTF8:
                TB.Mode := 0;
            TextEncoding::UTF16:
                TB.Mode := 1;
            TextEncoding::Windows:
                TB.Mode := 2;
            TextEncoding::MSDos:
                TB.Mode := 3;
        end;
        TB.Data.CreateOutStream(OutS, Enc);
        OutS.WriteText(Txt);
        Commit();
        if Codeunit.Run(Codeunit::"LT XpT Import Runner", TB) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    procedure SaveXml(QueryId: Integer): Text
    var
        TB: Record "LT XpT Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        TB.Data.CreateOutStream(OutS);
        Query.SaveAsXml(QueryId, OutS);
        LenValue := TB.Data.Length;
        TB.Data.CreateInStream(InS);
        exit(ReadAll(InS));
    end;

    procedure SaveCsv(QueryId: Integer): Text
    var
        TB: Record "LT XpT Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        TB.Data.CreateOutStream(OutS);
        Query.SaveAsCsv(QueryId, OutS);
        LenValue := TB.Data.Length;
        TB.Data.CreateInStream(InS);
        exit(ReadAll(InS));
    end;

    procedure LastLength(): Integer
    begin
        exit(LenValue);
    end;

    procedure DumpItems(): Text
    var
        Item: Record "LT XpT Item";
        Result: Text;
    begin
        if Item.FindSet() then
            repeat
                Result += StrSubstNo('%1|%2|%3|%4|%5|%6|%7;', Item.Id, Item.Name, Item.Qty, Format(Item.Amount, 0, 9), Format(Item.Active, 0, 9), Item.Category, Format(Item.StampDate, 0, 9));
            until Item.Next() = 0;
        exit(Result);
    end;

    procedure DumpLines(): Text
    var
        Line: Record "LT XpT Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += StrSubstNo('%1|%2|%3|%4;', Line.Id, Line.ItemId, Line.Descr, Line.Qty);
            until Line.Next() = 0;
        exit(Result);
    end;

    procedure DumpTargets(): Text
    var
        Tgt: Record "LT XpT Target";
        Result: Text;
    begin
        if Tgt.FindSet() then
            repeat
                Result += StrSubstNo('%1|%2|%3|%4|%5|%6|%7|%8|%9;', Tgt.Id, Tgt.Name, Tgt.Qty, Format(Tgt.Amount, 0, 9), Format(Tgt.Active, 0, 9), Tgt.Category, Tgt.Note, Tgt.ShortName, Format(Tgt.StampDate, 0, 9));
            until Tgt.Next() = 0;
        exit(Result);
    end;

    procedure RunDT(Mode: Integer): Text
    var
        Rec: Record "LT XpT Item" temporary;
    begin
        Commit();
        Rec.Id := Mode;
        if Codeunit.Run(Codeunit::"LT XpT DT Runner", Rec) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;
}

codeunit 73450 "LT XpT DT Runner"
{
    TableNo = "LT XpT Item";

    trigger OnRun()
    var
        Src: Record "LT XpT Item";
        Tgt: Record "LT XpT Target";
        DT: DataTransfer;
    begin
        case Rec.Id of
            1:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddFieldValue(Src.FieldNo(Name), Tgt.FieldNo(Name));
                    DT.AddFieldValue(Src.FieldNo(Qty), Tgt.FieldNo(Qty));
                    DT.CopyRows();
                end;
            2:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddFieldValue(Src.FieldNo(Name), Tgt.FieldNo(Name));
                    DT.AddFieldValue(Src.FieldNo(Qty), Tgt.FieldNo(Qty));
                    DT.AddFieldValue(Src.FieldNo(Amount), Tgt.FieldNo(Amount));
                    DT.AddFieldValue(Src.FieldNo(Active), Tgt.FieldNo(Active));
                    DT.AddFieldValue(Src.FieldNo(Category), Tgt.FieldNo(Category));
                    DT.AddFieldValue(Src.FieldNo(StampDate), Tgt.FieldNo(StampDate));
                    DT.CopyRows();
                end;
            3:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddConstantValue('const', Tgt.FieldNo(Note));
                    DT.AddConstantValue(7, Tgt.FieldNo(Qty));
                    DT.CopyRows();
                end;
            4:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddSourceFilter(Src.FieldNo(Qty), '>=%1', 20);
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddFieldValue(Src.FieldNo(Qty), Tgt.FieldNo(Qty));
                    DT.CopyRows();
                end;
            5:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddSourceFilter(Src.FieldNo(Name), '%1|%2', 'Alpha', 'Gamma');
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddFieldValue(Src.FieldNo(Name), Tgt.FieldNo(Name));
                    DT.CopyRows();
                end;
            6:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.CopyRows();
                end;
            7:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Item");
                    DT.AddFieldValue(Src.FieldNo(Id), Src.FieldNo(Id));
                    DT.CopyRows();
                end;
            8:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.CopyRows();
                    DT.CopyRows();
                end;
            9:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.UpdateAuditFields(false);
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddFieldValue(Src.FieldNo(Name), Tgt.FieldNo(Name));
                    DT.CopyRows();
                end;
            10:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddFieldValue(Src.FieldNo(Name), Tgt.FieldNo(ShortName));
                    DT.CopyRows();
                end;
            11:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddFieldValue(Src.FieldNo(Name), Tgt.FieldNo(Qty));
                    DT.CopyRows();
                end;
            12:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddJoin(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddFieldValue(Src.FieldNo(Qty), Tgt.FieldNo(Qty));
                    DT.AddFieldValue(Src.FieldNo(Name), Tgt.FieldNo(Name));
                    DT.CopyFields();
                end;
            13:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddFieldValue(Src.FieldNo(Qty), Tgt.FieldNo(Qty));
                    DT.CopyFields();
                end;
            14:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddConstantValue('text', Tgt.FieldNo(Qty));
                    DT.CopyRows();
                end;
            15:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddSourceFilter(9999, '>=%1', 20);
                end;
            16:
                begin
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                end;
            18:
                begin
                    DT.SetTables(Database::"LT XpT Item", 99999999);
                end;
            19:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddConstantValue('first', Tgt.FieldNo(Note));
                    DT.AddConstantValue('second', Tgt.FieldNo(Note));
                    DT.CopyRows();
                end;
            20:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddFieldValue(Src.FieldNo(Name), Tgt.FieldNo(Name));
                    DT.AddFieldValue(Src.FieldNo(Qty), Tgt.FieldNo(Name));
                    DT.CopyRows();
                end;
            21:
                begin
                    DT.SetTables(Database::"LT XpT Item", Database::"LT XpT Target");
                    DT.AddFieldValue(Src.FieldNo(Id), Tgt.FieldNo(Id));
                    DT.AddFieldValue(Src.FieldNo(Qty), Tgt.FieldNo(Qty));
                    DT.AddSourceFilter(Src.FieldNo(Qty), '>%1', 1000);
                    DT.CopyRows();
                end;
        end;
    end;
}

codeunit 73451 "LT XpT Import Runner"
{
    TableNo = "LT XpT Blob";

    trigger OnRun()
    var
        InS: InStream;
    begin
        case Rec.Mode of
            0:
                Rec.Data.CreateInStream(InS, TextEncoding::UTF8);
            1:
                Rec.Data.CreateInStream(InS, TextEncoding::UTF16);
            2:
                Rec.Data.CreateInStream(InS, TextEncoding::Windows);
            3:
                Rec.Data.CreateInStream(InS, TextEncoding::MSDos);
        end;
        Xmlport.Import(Rec.Id, InS);
    end;
}
