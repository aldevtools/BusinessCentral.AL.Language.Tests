// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: self-contained (tables 73806-73808, helper codeunit 73809); not a test codeunit
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73806 "LT RpT Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp, Id) { }
    }
}

table 73807 "LT RpT Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByParent; ParentId, Id) { }
    }
}

table 73808 "LT RpT Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73809 "LT RpT Helper"
{
    procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    // Report.SaveAs to Xml; Xml gets the whole text with LF line ends.
    procedure Save(ReportId: Integer; Parameters: Text; var Xml: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        Ok := Report.SaveAs(ReportId, Parameters, ReportFormat::Xml, OutS);
        Xml := ReadAll(TempBlob);
        exit(Ok);
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

    procedure Between(Value: Text; StartTag: Text; EndTag: Text): Text
    var
        StartAt: Integer;
        EndAt: Integer;
        Rest: Text;
    begin
        StartAt := Value.IndexOf(StartTag);
        if StartAt = 0 then
            exit('<no start>');
        Rest := Value.Substring(StartAt + StrLen(StartTag));
        EndAt := Rest.IndexOf(EndTag);
        if EndAt = 0 then
            exit('<no end>');
        exit(Rest.Substring(1, EndAt - 1));
    end;
}
