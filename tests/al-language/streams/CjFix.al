// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: none; shared by the test codeunits of report/lt-cj-report-leads (corpus issue 667, items 145-158)
// Facts: the table, table extension, log and helper the LT CJ report tests use.
// BC versions: 27-29

table 84640 "LT CJ Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "My Date"; Date) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure Foo(): Text
    begin
        exit('table ' + Format(Id));
    end;
}

tableextension 84641 "LT CJ Row Ext" extends "LT CJ Row"
{
    fields
    {
        field(84640; "LT CJ Ext Code"; Code[10]) { DataClassification = SystemMetadata; }
    }
}

// Used only by the reports of CjDataset.al and its test codeunit 84650 (SingleInstance: one test codeunit per log).
codeunit 84642 "LT CJ Log"
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

codeunit 84643 "LT CJ Helper"
{
    procedure Seed()
    var
        Row: Record "LT CJ Row";
    begin
        Row.DeleteAll();
        Add(1, 0D, 'One', 'A');
        Add(2, DMY2Date(1, 2, 2024), 'Two', 'B');
        Add(3, 0D, 'Three', '');
    end;

    local procedure Add(Id: Integer; D: Date; Name: Text[30]; ExtCode: Code[10])
    var
        Row: Record "LT CJ Row";
    begin
        Row.Id := Id;
        Row."My Date" := D;
        Row.Name := Name;
        Row."LT CJ Ext Code" := ExtCode;
        Row.Insert();
    end;

    procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: TextBuilder;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result.Append(Line);
            Result.Append(Lf());
        end;
        exit(Result.ToText());
    end;

    // The values of every <Column name="ColumnName"> in document order, joined with ','.
    procedure Values(Xml: Text; ColumnName: Text): Text
    var
        Line: Text;
        Prefix: Text;
        Result: Text;
        EndAt: Integer;
    begin
        Prefix := '<Column name="' + ColumnName + '"';
        foreach Line in Xml.Split(Lf()) do begin
            Line := Line.Trim();
            if Line.StartsWith(Prefix) then begin
                Line := Line.Substring(Line.IndexOf('>') + 1);
                EndAt := Line.IndexOf('</Column>');
                if EndAt > 0 then
                    Line := Line.Substring(1, EndAt - 1);
                Result += Line + ',';
            end;
        end;
        exit(Result);
    end;

    // The first four bytes of the stream as numbers, e.g. '37,80,68,70,' for %PDF and '80,75,3,4,' for a zip package.
    procedure Head(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        B: Byte;
        I: Integer;
        Code: Integer;
        Result: Text;
    begin
        if TempBlob.Length() = 0 then
            exit('empty');
        TempBlob.CreateInStream(InS);
        for I := 1 to 4 do
            if not InS.EOS() then begin
                InS.Read(B);
                Code := B;
                Result += Format(Code) + ',';
            end;
        exit(Result);
    end;
}
