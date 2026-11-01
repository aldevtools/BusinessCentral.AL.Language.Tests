// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 93656-93657, xmlports 93650-93658, codeunits 93661-93662.
// Probe (writer Y68, NP lane probes Q4 and two of Q6):
//   Q4  The CalcFields property of a table element (real and temporary), export and import: the FlowField value written, read in OnAfterGetRecord,
//       with and without the property, one and two fields, a nested linked table element. XmlFlowFieldElement/Ay tests pin the field element alone.
//   Q6  A fieldattribute and a textattribute below a fieldelement, with Occurrence = Optional and Required (import: missing/present/empty;
//       export: blank and filled).
//   Q6  LinkTableForceInsert = true on a linked table element (import and export) against the same port without it.
// Probe: values recorded on the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix.

table 93656 "LT Y68 XP Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Lang; Text[10]) { }
        field(4; Req; Text[10]) { }
        field(5; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y68 XP Child".Amount where("Parent No." = field("No.")));
            Editable = false;
        }
        field(6; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y68 XP Child" where("Parent No." = field("No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 93657 "LT Y68 XP Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Parent No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Parent No.", "Line No.") { Clustered = true; }
    }
}

codeunit 93661 "LT Y68 XP Log"
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

// Q4: no CalcFields property; the trigger reads the FlowFields without CalcFields.
xmlport 93650 "LT Y68 XP Calc None"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';

                fieldelement(No; P."No.") { }
                fieldelement(Total; P.Total) { }
                fieldelement(Cnt; P.Cnt) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr ' + P."No." + ' total=' + Format(P.Total) + ' cnt=' + Format(P.Cnt));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";
}

xmlport 93651 "LT Y68 XP Calc Total"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                CalcFields = Total;

                fieldelement(No; P."No.") { }
                fieldelement(Total; P.Total) { }
                fieldelement(Cnt; P.Cnt) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr ' + P."No." + ' total=' + Format(P.Total) + ' cnt=' + Format(P.Cnt));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";
}

xmlport 93652 "LT Y68 XP Calc Both Nested"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                CalcFields = Total, Cnt;

                fieldelement(No; P."No.") { }
                tableelement(C; "LT Y68 XP Child")
                {
                    XmlName = 'C';
                    LinkTable = P;
                    LinkFields = "Parent No." = field("No.");

                    fieldelement(Line; C."Line No.") { }
                    fieldelement(Amount; C.Amount) { }
                }
                fieldelement(Total; P.Total) { }
                fieldelement(Cnt; P.Cnt) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr ' + P."No." + ' total=' + Format(P.Total) + ' cnt=' + Format(P.Cnt));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";
}

// Q4 temporary table element: the rows are copied from the real table in OnPreXmlItem.
xmlport 93653 "LT Y68 XP Calc Temp"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                UseTemporary = true;
                CalcFields = Total;

                fieldelement(No; P."No.") { }
                fieldelement(Total; P.Total) { }
                fieldelement(Cnt; P.Cnt) { }

                trigger OnPreXmlItem()
                var
                    Real: Record "LT Y68 XP Parent";
                begin
                    if Real.FindSet() then
                        repeat
                            P := Real;
                            P.Insert();
                        until Real.Next() = 0;
                end;

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr ' + P."No." + ' total=' + Format(P.Total) + ' cnt=' + Format(P.Cnt));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";
}

xmlport 93654 "LT Y68 XP Calc Temp None"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                UseTemporary = true;

                fieldelement(No; P."No.") { }
                fieldelement(Total; P.Total) { }
                fieldelement(Cnt; P.Cnt) { }

                trigger OnPreXmlItem()
                var
                    Real: Record "LT Y68 XP Parent";
                begin
                    if Real.FindSet() then
                        repeat
                            P := Real;
                            P.Insert();
                        until Real.Next() = 0;
                end;

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr ' + P."No." + ' total=' + Format(P.Total) + ' cnt=' + Format(P.Cnt));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";
}

// Q4 import with CalcFields: the FlowField value read in the insert triggers.
xmlport 93655 "LT Y68 XP Calc Import"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                CalcFields = Total, Cnt;

                fieldelement(No; P."No.") { }
                fieldelement(Name; P.Name) { }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('bir ' + P."No." + ' total=' + Format(P.Total) + ' cnt=' + Format(P.Cnt));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('air ' + P."No." + ' total=' + Format(P.Total) + ' cnt=' + Format(P.Cnt));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";
}

// Q6: attributes below a field element.
xmlport 93656 "LT Y68 XP Elem Attr"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';

                fieldelement(No; P."No.") { }
                fieldelement(Name; P.Name)
                {
                    fieldattribute(Lang; P.Lang) { Occurrence = Optional; }
                    fieldattribute(Req; P.Req) { }
                    textattribute(Tag)
                    {
                        Occurrence = Optional;

                        trigger OnAfterAssignVariable()
                        begin
                            Log.Add('tag=' + Tag);
                        end;
                    }
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('bir ' + P."No." + ' name=' + P.Name + ' lang=' + P.Lang + ' req=' + P.Req);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";
}

// Q6: LinkTableForceInsert.
xmlport 93657 "LT Y68 XP Link Force"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                MinOccurs = Zero;

                fieldelement(No; P."No.") { }
                tableelement(C; "LT Y68 XP Child")
                {
                    XmlName = 'C';
                    MinOccurs = Zero;
                    LinkTable = P;
                    LinkFields = "Parent No." = field("No.");
                    LinkTableForceInsert = true;

                    fieldelement(Line; C."Line No.") { }
                    fieldelement(Amount; C.Amount) { }

                    trigger OnBeforeInsertRecord()
                    begin
                        Log.Add('child bir ' + C."Parent No." + '/' + Format(C."Line No."));
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('parent bir ' + P."No.");
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('parent air ' + P."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";
}

xmlport 93658 "LT Y68 XP Link NoForce"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                MinOccurs = Zero;

                fieldelement(No; P."No.") { }
                tableelement(C; "LT Y68 XP Child")
                {
                    XmlName = 'C';
                    MinOccurs = Zero;
                    LinkTable = P;
                    LinkFields = "Parent No." = field("No.");

                    fieldelement(Line; C."Line No.") { }
                    fieldelement(Amount; C.Amount) { }

                    trigger OnBeforeInsertRecord()
                    begin
                        Log.Add('child bir ' + C."Parent No." + '/' + Format(C."Line No."));
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('parent bir ' + P."No.");
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('parent air ' + P."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";
}

codeunit 93662 "LT Y68 XP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y68 XP Log";

    local procedure Clean()
    var
        P: Record "LT Y68 XP Parent";
        C: Record "LT Y68 XP Child";
    begin
        P.DeleteAll();
        C.DeleteAll();
        Log.Take();
        ClearLastError();
        Commit();
    end;

    local procedure AddParent(No: Code[10]; Name: Text[30])
    var
        P: Record "LT Y68 XP Parent";
    begin
        P."No." := No;
        P.Name := Name;
        P.Insert();
    end;

    local procedure AddChild(ParentNo: Code[10]; LineNo: Integer; Amount: Decimal)
    var
        C: Record "LT Y68 XP Child";
    begin
        C."Parent No." := ParentNo;
        C."Line No." := LineNo;
        C.Amount := Amount;
        C.Insert();
    end;

    local procedure Seed()
    begin
        Clean();
        AddParent('P1', 'one');
        AddParent('P2', 'two');
        AddParent('P3', 'three');
        AddChild('P1', 10, 1.5);
        AddChild('P1', 20, 2);
        AddChild('P3', 10, 7);
    end;

    local procedure ExportText(XmlportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlportId, OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryImport(XmlportId: Integer; Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(XmlportId, InS);
    end;

    local procedure ParentRows() Result: Text
    var
        P: Record "LT Y68 XP Parent";
    begin
        if P.FindSet() then
            repeat
                Result += '[' + P."No." + '|' + P.Name + '|' + P.Lang + '|' + P.Req + ']';
            until P.Next() = 0;
    end;

    local procedure ChildRows() Result: Text
    var
        C: Record "LT Y68 XP Child";
    begin
        if C.FindSet() then
            repeat
                Result += '[' + C."Parent No." + '/' + Format(C."Line No.") + '/' + Format(C.Amount) + ']';
            until C.Next() = 0;
    end;

    local procedure ObserveImport(var Observer: Codeunit "Probe Observer"; Name: Text; XmlportId: Integer; Content: Text)
    var
        Ok: Boolean;
    begin
        Clean();
        Ok := TryImport(XmlportId, Content);
        Observer.Observe(Name + ' ok', Format(Ok));
        if not Ok then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe(Name + ' log', Log.Take());
        Observer.Observe(Name + ' parents', ParentRows());
        Observer.Observe(Name + ' children', ChildRows());
    end;

    [Test]
    procedure Q4_CalcFields_Export_RealTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('none xml', ExportText(Xmlport::"LT Y68 XP Calc None"));
        Observer.Observe('none log', Log.Take());
        Observer.Observe('total xml', ExportText(Xmlport::"LT Y68 XP Calc Total"));
        Observer.Observe('total log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Q4_CalcFields_Export_NestedLinkedTableElement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('both nested xml', ExportText(Xmlport::"LT Y68 XP Calc Both Nested"));
        Observer.Observe('both nested log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Q4_CalcFields_Export_TemporaryTableElement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('temp total xml', ExportText(Xmlport::"LT Y68 XP Calc Temp"));
        Observer.Observe('temp total log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Q4_CalcFields_Export_TemporaryTableElement_NoProperty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('temp none xml', ExportText(Xmlport::"LT Y68 XP Calc Temp None"));
        Observer.Observe('temp none log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Q4_CalcFields_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        AddChild('P1', 10, 4);
        AddChild('P1', 20, 5);
        Commit();
        Log.Take();
        TryImport(Xmlport::"LT Y68 XP Calc Import", '<Root><P><No>P1</No><Name>n1</Name></P><P><No>P2</No><Name>n2</Name></P></Root>');
        Observer.Observe('import log', Log.Take());
        Observer.Observe('import parents', ParentRows());
        Clean();
        Observer.Finish();
    end;

    [Test]
    procedure Q6_FieldElement_Attributes_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'all present', Xmlport::"LT Y68 XP Elem Attr", '<Root><P><No>A</No><Name Lang="en" Req="r" Tag="t">x</Name></P></Root>');
        ObserveImport(Observer, 'lang missing', Xmlport::"LT Y68 XP Elem Attr", '<Root><P><No>A</No><Name Req="r">x</Name></P></Root>');
        ObserveImport(Observer, 'tag missing', Xmlport::"LT Y68 XP Elem Attr", '<Root><P><No>A</No><Name Lang="en" Req="r">x</Name></P></Root>');
        ObserveImport(Observer, 'req missing', Xmlport::"LT Y68 XP Elem Attr", '<Root><P><No>A</No><Name Lang="en">x</Name></P></Root>');
        ObserveImport(Observer, 'all empty', Xmlport::"LT Y68 XP Elem Attr", '<Root><P><No>A</No><Name Lang="" Req="" Tag="">x</Name></P></Root>');
        ObserveImport(Observer, 'empty element', Xmlport::"LT Y68 XP Elem Attr", '<Root><P><No>A</No><Name Lang="de" Req="b" /></P></Root>');
        ObserveImport(Observer, 'element missing', Xmlport::"LT Y68 XP Elem Attr", '<Root><P><No>A</No></P></Root>');
        ObserveImport(Observer, 'two rows', Xmlport::"LT Y68 XP Elem Attr", '<Root><P><No>A</No><Name Lang="en" Req="r">x</Name></P><P><No>B</No><Name Req="s">y</Name></P></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure Q6_FieldElement_Attributes_Export()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "LT Y68 XP Parent";
    begin
        Clean();
        AddParent('A', 'filled');
        P.Get('A');
        P.Lang := 'en';
        P.Req := 'r';
        P.Modify();
        AddParent('B', 'blank');
        Observer.Observe('export xml', ExportText(Xmlport::"LT Y68 XP Elem Attr"));
        Observer.Observe('export log', Log.Take());
        Clean();
        Observer.Finish();
    end;

    [Test]
    procedure Q6_LinkTableForceInsert_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'force two children', Xmlport::"LT Y68 XP Link Force",
            '<Root><P><No>P1</No><C><Line>1</Line><Amount>5</Amount></C><C><Line>2</Line><Amount>6</Amount></C></P></Root>');
        ObserveImport(Observer, 'noforce two children', Xmlport::"LT Y68 XP Link NoForce",
            '<Root><P><No>P1</No><C><Line>1</Line><Amount>5</Amount></C><C><Line>2</Line><Amount>6</Amount></C></P></Root>');
        ObserveImport(Observer, 'force no child', Xmlport::"LT Y68 XP Link Force", '<Root><P><No>P1</No></P></Root>');
        ObserveImport(Observer, 'noforce no child', Xmlport::"LT Y68 XP Link NoForce", '<Root><P><No>P1</No></P></Root>');
        ObserveImport(Observer, 'force child without parent key', Xmlport::"LT Y68 XP Link Force", '<Root><P><C><Line>1</Line><Amount>5</Amount></C></P></Root>');
        ObserveImport(Observer, 'noforce child without parent key', Xmlport::"LT Y68 XP Link NoForce", '<Root><P><C><Line>1</Line><Amount>5</Amount></C></P></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure Q6_LinkTableForceInsert_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('force xml', ExportText(Xmlport::"LT Y68 XP Link Force"));
        Observer.Observe('force log', Log.Take());
        Observer.Observe('noforce xml', ExportText(Xmlport::"LT Y68 XP Link NoForce"));
        Observer.Observe('noforce log', Log.Take());
        Clean();
        Observer.Finish();
    end;
}
