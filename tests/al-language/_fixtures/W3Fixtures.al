//sub:fixtures
// Shared fixtures of batch 3 (reports, request pages, report extensions): four tables, a runner and a dataset helper.
// Every other file of this batch uses them. None of them is a test codeunit and none is SingleInstance.

table 67698 "W3 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
        field(4; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name, Id) { }
    }
}

table 67699 "W3 Child"
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

table 67700 "W3 Marker"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tag; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Parameter record of the runner. Only used as a temporary record.
table 67701 "W3 Param"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ReportId; Integer) { }
        field(3; Mode; Integer) { }
        field(4; Text1; Text[2048]) { }
        field(5; Result; Text[2048]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Runs one report statement inside Codeunit.Run so that a test can observe an error without asserterror.
// Mode 0 Report.Run, 1 Report.RunModal, 2 Report.RunRequestPage (Result = the text), 3 Report.RunRequestPage(Id, Text1),
// 4 Report.SaveAs Xml with Text1 as parameters (Result = the answer), 5 Report.Execute(Id, Text1), 6 Hyperlink(Text1).
codeunit 67702 "W3 Runner"
{
    TableNo = "W3 Param";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        case Rec.Mode of
            0:
                Report.Run(Rec.ReportId);
            1:
                Report.RunModal(Rec.ReportId);
            2:
                Rec.Result := CopyStr(Report.RunRequestPage(Rec.ReportId), 1, 2048);
            3:
                Rec.Result := CopyStr(Report.RunRequestPage(Rec.ReportId, Rec.Text1), 1, 2048);
            4:
                begin
                    TempBlob.CreateOutStream(OutS);
                    Ok := Report.SaveAs(Rec.ReportId, Rec.Text1, ReportFormat::Xml, OutS);
                    Rec.Result := Format(Ok);
                end;
            5:
                Report.Execute(Rec.ReportId, Rec.Text1);
            6:
                Hyperlink(Rec.Text1);
        end;
    end;

    // Call after Commit(). The last error stays readable for the caller.
    procedure Exec(ReportId: Integer; Mode: Integer; Text1: Text; var Result: Text): Boolean
    var
        Param: Record "W3 Param" temporary;
        Ok: Boolean;
    begin
        Param.Init();
        Param.Id := 1;
        Param.ReportId := ReportId;
        Param.Mode := Mode;
        Param.Text1 := CopyStr(Text1, 1, MaxStrLen(Param.Text1));
        ClearLastError();
        Ok := Codeunit.Run(Codeunit::"W3 Runner", Param);
        Result := Param.Result;
        exit(Ok);
    end;
}

codeunit 67703 "W3 Dataset"
{
    procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    // Report.SaveAs Xml of a report; Xml holds the whole text with LF line ends (the byte order mark is dropped by the UTF8 read).
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

    // The Column and Label lines of a dataset, trimmed, joined with '|'.
    procedure ColumnLines(Xml: Text): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Xml.Split(Lf()) do begin
            Line := Line.Trim();
            if Line.StartsWith('<Column ') or Line.StartsWith('<Label ') then
                Result += Line + '|';
        end;
        exit(Result);
    end;

    // The values of every <Column name="ColumnName"> in document order, joined with ','.
    procedure ColumnValues(Xml: Text; ColumnName: Text): Text
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

    // The structure of the data items: DIs = DataItems, DI = DataItem, c:Name = Column, closing tags with a slash.
    procedure Tokens(Xml: Text): Text
    var
        Line: Text;
        Result: Text;
        NameEnd: Integer;
    begin
        foreach Line in Xml.Split(Lf()) do begin
            Line := Line.Trim();
            if Line.StartsWith('<DataItems') then
                Result += 'DIs '
            else
                if Line.StartsWith('</DataItems') then
                    Result += '/DIs '
                else
                    if Line.StartsWith('<DataItem ') or (Line = '<DataItem>') then
                        Result += 'DI '
                    else
                        if Line.StartsWith('</DataItem>') then
                            Result += '/DI '
                        else
                            if Line.StartsWith('<Column name="') then begin
                                Line := Line.Substring(15);
                                NameEnd := Line.IndexOf('"');
                                if NameEnd > 0 then
                                    Line := Line.Substring(1, NameEnd - 1);
                                Result += 'c:' + Line + ' ';
                            end;
        end;
        exit(Result.TrimEnd());
    end;

    // Text between two markers (empty when a marker is missing).
    procedure Between(Value: Text; StartTag: Text; EndTag: Text): Text
    var
        StartAt: Integer;
        Rest: Text;
        EndAt: Integer;
    begin
        StartAt := Value.IndexOf(StartTag);
        if StartAt = 0 then
            exit('');
        Rest := Value.Substring(StartAt + StrLen(StartTag));
        EndAt := Rest.IndexOf(EndTag);
        if EndAt = 0 then
            exit('');
        exit(Rest.Substring(1, EndAt - 1));
    end;

    // Element tree of the dataset header down to the given depth, children in brackets. DataItems and Labels are not opened.
    procedure HeaderShape(Xml: Text; Depth: Integer): Text
    var
        Doc: XmlDocument;
        Root: XmlElement;
    begin
        Xml := Xml.Substring(Xml.IndexOf('<?xml'));
        if not XmlDocument.ReadFrom(Xml, Doc) then
            exit('unreadable');
        Doc.GetRoot(Root);
        exit(Describe(Root, Depth));
    end;

    local procedure Describe(El: XmlElement; Depth: Integer): Text
    var
        Children: XmlNodeList;
        Node: XmlNode;
        Child: XmlElement;
        Result: Text;
    begin
        Result := El.Name();
        if (Depth <= 0) or (El.Name() = 'DataItems') or (El.Name() = 'Labels') then
            exit(Result);
        Children := El.GetChildElements();
        if Children.Count() = 0 then
            exit(Result);
        Result += '(';
        foreach Node in Children do begin
            Child := Node.AsXmlElement();
            Result += Describe(Child, Depth - 1) + ',';
        end;
        exit(Result.TrimEnd(',') + ')');
    end;

    // The text of a header element somewhere under the root (first match), empty when absent.
    procedure HeaderValue(Xml: Text; ElementName: Text): Text
    var
        Doc: XmlDocument;
        Node: XmlNode;
    begin
        Xml := Xml.Substring(Xml.IndexOf('<?xml'));
        if not XmlDocument.ReadFrom(Xml, Doc) then
            exit('unreadable');
        if not Doc.SelectSingleNode('//' + ElementName, Node) then
            exit('<absent>');
        exit(Node.AsXmlElement().InnerText());
    end;

    // Attribute names of every DataItem element, in document order: DataItem[name,tableId] ...
    procedure ItemAttributes(Xml: Text): Text
    var
        Doc: XmlDocument;
        Nodes: XmlNodeList;
        Node: XmlNode;
        Attr: XmlAttribute;
        Result: Text;
    begin
        Xml := Xml.Substring(Xml.IndexOf('<?xml'));
        if not XmlDocument.ReadFrom(Xml, Doc) then
            exit('unreadable');
        if not Doc.SelectNodes('//DataItem', Nodes) then
            exit('');
        foreach Node in Nodes do begin
            Result += '[';
            foreach Attr in Node.AsXmlElement().Attributes() do
                Result += Attr.Name() + ',';
            Result := Result.TrimEnd(',') + '] ';
        end;
        exit(Result.TrimEnd());
    end;

    // The value of an attribute of the Nth DataItem element (1 based), '<absent>' when there is none.
    procedure ItemAttribute(Xml: Text; Index: Integer; AttrName: Text): Text
    var
        Doc: XmlDocument;
        Nodes: XmlNodeList;
        Node: XmlNode;
        Attr: XmlAttribute;
    begin
        Xml := Xml.Substring(Xml.IndexOf('<?xml'));
        if not XmlDocument.ReadFrom(Xml, Doc) then
            exit('unreadable');
        if not Doc.SelectNodes('//DataItem', Nodes) then
            exit('<absent>');
        if Nodes.Count() < Index then
            exit('<absent>');
        Nodes.Get(Index, Node);
        if not Node.AsXmlElement().Attributes().Get(AttrName, Attr) then
            exit('<absent>');
        exit(Attr.Value());
    end;
}
