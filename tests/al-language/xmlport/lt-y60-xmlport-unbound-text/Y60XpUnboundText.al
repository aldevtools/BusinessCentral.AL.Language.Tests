// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-unbound-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 93220-93222, xmlports 93220-93223, codeunits 93220-93222.
// Probe (gap cycle 6, G6-06): Unbound = true on a text element. A VariableText import port whose table element holds a text element
// col1 (MaxOccurs = Once) and an unbound text element colx (MinOccurs = Zero), the shape of a generic CSV import port: lines with more
// columns than elements, short lines, empty columns, a quoted value with the separator, a trailing separator; the same port without
// Unbound (control) and with MaxOccurs = Unbounded; an Xml port with an unbound leaf text element below the root (export and import).
// The separator set from OnPreXmlPort is pinned by platform/lt-xmlport-session-navapp-cookie/P94Fixtures.al:356 (not repeated).
// An unbound text element inside a table element on export is pinned by pages/lt-report-page-properties/06-xmlport-unbound.al.
// BC versions: 27-29

table 93220 "LT Y60 UT Cell"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "Col No."; Integer) { }
        field(3; Value; Text[50]) { }
    }

    keys
    {
        key(PK; "Line No.", "Col No.") { Clustered = true; }
    }
}

table 93221 "LT Y60 UT Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 93222 "LT Y60 UT Job"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Content; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93220 "LT Y60 UT Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        LineNo: Integer;
        ColNo: Integer;

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
        LineNo := 0;
        ColNo := 0;
        exit(Result);
    end;

    procedure NextLine()
    begin
        LineNo += 1;
    end;

    procedure StoreColumn(Value: Text)
    var
        Cell: Record "LT Y60 UT Cell";
    begin
        ColNo += 1;
        Cell."Line No." := LineNo;
        Cell."Col No." := ColNo;
        Cell.Value := CopyStr(Value, 1, MaxStrLen(Cell.Value));
        Cell.Insert();
    end;
}

xmlport 93220 "LT Y60 UT Csv Unbound"
{
    Direction = Import;
    Format = VariableText;
    FieldSeparator = ',';
    FieldDelimiter = '"';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            MinOccurs = Zero;
            tableelement(Hdr; "LT Y60 UT Line")
            {
                AutoSave = false;
                textelement(col1)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;

                    trigger OnAfterAssignVariable()
                    begin
                        Log.Add('c1=' + col1);
                    end;
                }
                textelement(colx)
                {
                    MinOccurs = Zero;
                    Unbound = true;

                    trigger OnAfterAssignVariable()
                    begin
                        Log.Add('cx=' + colx);
                        Log.StoreColumn(colx);
                        colx := '';
                    end;
                }

                trigger OnAfterInitRecord()
                begin
                    Log.NextLine();
                    Log.Add('init');
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins');
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        Log.Add('post col1=[' + col1 + '] colx=[' + colx + ']');
    end;

    var
        Log: Codeunit "LT Y60 UT Log";
}

xmlport 93221 "LT Y60 UT Csv Bound"
{
    Direction = Import;
    Format = VariableText;
    FieldSeparator = ',';
    FieldDelimiter = '"';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            MinOccurs = Zero;
            tableelement(Hdr; "LT Y60 UT Line")
            {
                AutoSave = false;
                textelement(col1)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;

                    trigger OnAfterAssignVariable()
                    begin
                        Log.Add('c1=' + col1);
                    end;
                }
                textelement(colx)
                {
                    MinOccurs = Zero;

                    trigger OnAfterAssignVariable()
                    begin
                        Log.Add('cx=' + colx);
                        Log.StoreColumn(colx);
                        colx := '';
                    end;
                }

                trigger OnAfterInitRecord()
                begin
                    Log.NextLine();
                    Log.Add('init');
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins');
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        Log.Add('post col1=[' + col1 + '] colx=[' + colx + ']');
    end;

    var
        Log: Codeunit "LT Y60 UT Log";
}

xmlport 93222 "LT Y60 UT Csv Unbounded"
{
    Direction = Import;
    Format = VariableText;
    FieldSeparator = ',';
    FieldDelimiter = '"';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            MinOccurs = Zero;
            tableelement(Hdr; "LT Y60 UT Line")
            {
                AutoSave = false;
                textelement(col1)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;

                    trigger OnAfterAssignVariable()
                    begin
                        Log.Add('c1=' + col1);
                    end;
                }
                textelement(colx)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Unbounded;
                    Unbound = true;

                    trigger OnAfterAssignVariable()
                    begin
                        Log.Add('cx=' + colx);
                        Log.StoreColumn(colx);
                        colx := '';
                    end;
                }

                trigger OnAfterInitRecord()
                begin
                    Log.NextLine();
                    Log.Add('init');
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins');
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        Log.Add('post col1=[' + col1 + '] colx=[' + colx + ']');
    end;

    var
        Log: Codeunit "LT Y60 UT Log";
}

xmlport 93223 "LT Y60 UT Xml Unbound"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Plain)
            {
                MinOccurs = Zero;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('plain=' + Plain);
                end;
            }
            textelement(Free)
            {
                MinOccurs = Zero;
                Unbound = true;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('free=' + Free);
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        if currXMLport.ImportFile() then
            exit;
        Plain := 'p-out';
        Free := 'f-out';
    end;

    trigger OnPostXmlPort()
    begin
        Log.Add('post plain=[' + Plain + '] free=[' + Free + ']');
    end;

    var
        Log: Codeunit "LT Y60 UT Log";
}

codeunit 93221 "LT Y60 UT Import Runner"
{
    TableNo = "LT Y60 UT Job";

    trigger OnRun()
    var
        InS: InStream;
    begin
        Rec.CalcFields(Content);
        Rec.Content.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Rec.Id, InS);
    end;
}

codeunit 93222 "LT Y60 UT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y60 UT Log";

    local procedure CrLf(): Text
    var
        C: Char;
        Result: Text;
    begin
        C := 13;
        Result += C;
        C := 10;
        Result += C;
        exit(Result);
    end;

    local procedure Cells(): Text
    var
        Cell: Record "LT Y60 UT Cell";
        Result: Text;
    begin
        if Cell.FindSet() then
            repeat
                Result += Format(Cell."Line No.") + '/' + Format(Cell."Col No.") + '=' + Cell.Value + ',';
            until Cell.Next() = 0;
        exit(Result);
    end;

    local procedure Clean()
    var
        Cell: Record "LT Y60 UT Cell";
        Line: Record "LT Y60 UT Line";
    begin
        Cell.DeleteAll();
        Line.DeleteAll();
        Log.Take();
        Commit();
    end;

    local procedure RunImport(XmlportId: Integer; Content: Text): Boolean
    var
        Job: Record "LT Y60 UT Job" temporary;
        OutS: OutStream;
    begin
        Job.Id := XmlportId;
        Job.Insert();
        Job.Content.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        Job.Modify();
        Commit();
        exit(Codeunit.Run(Codeunit::"LT Y60 UT Import Runner", Job));
    end;

    local procedure ObserveImport(var Observer: Codeunit "Probe Observer"; Name: Text; XmlportId: Integer; Content: Text)
    var
        Line: Record "LT Y60 UT Line";
    begin
        Clean();
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(RunImport(XmlportId, Content)));
        if GetLastErrorText() <> '' then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe(Name + ' log', Log.Take());
        Observer.Observe(Name + ' cells', Cells());
        Observer.Observe(Name + ' lines', Format(Line.Count()));
    end;

    [Test]
    procedure Unbound_Text_Import_ManyColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'two lines', Xmlport::"LT Y60 UT Csv Unbound", 'a,b,c,d' + CrLf() + 'e,f,g,h' + CrLf());
        ObserveImport(Observer, 'no last line end', Xmlport::"LT Y60 UT Csv Unbound", 'a,b,c');
        Observer.Finish();
    end;

    [Test]
    procedure Unbound_Text_Import_ShortAndEmptyColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'short and empty', Xmlport::"LT Y60 UT Csv Unbound", 'a' + CrLf() + 'b,,d' + CrLf() + 'e,f' + CrLf());
        ObserveImport(Observer, 'empty last', Xmlport::"LT Y60 UT Csv Unbound", 'a,b,' + CrLf());
        Observer.Finish();
    end;

    [Test]
    procedure Unbound_Text_Import_WithoutUnbound_SameFile()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'bound', Xmlport::"LT Y60 UT Csv Bound", 'a,b,c,d' + CrLf() + 'e,f,g,h' + CrLf());
        ObserveImport(Observer, 'bound two columns', Xmlport::"LT Y60 UT Csv Bound", 'a,b' + CrLf() + 'e,f' + CrLf());
        Observer.Finish();
    end;

    [Test]
    procedure Unbound_Text_MaxOccursUnbounded()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'unbounded', Xmlport::"LT Y60 UT Csv Unbounded", 'a,b,c,d' + CrLf() + 'e,f,g,h' + CrLf());
        Observer.Finish();
    end;

    [Test]
    procedure Unbound_Text_Import_TrailingSeparator_QuotedValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'quoted', Xmlport::"LT Y60 UT Csv Unbound", 'a,"b,x",c,' + CrLf());
        Observer.Finish();
    end;

    [Test]
    procedure Unbound_Text_Xml_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'both', Xmlport::"LT Y60 UT Xml Unbound", '<Root><Plain>p</Plain><Free>f</Free></Root>');
        ObserveImport(Observer, 'free only', Xmlport::"LT Y60 UT Xml Unbound", '<Root><Free>f</Free></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure Unbound_Text_Xml_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        Clean();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT Y60 UT Xml Unbound", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        Observer.Observe('export', Result);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;
}
