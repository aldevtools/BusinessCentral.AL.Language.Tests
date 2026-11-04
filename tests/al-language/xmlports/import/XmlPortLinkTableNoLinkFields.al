// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-linktable-xmlport-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 67503-67504, xmlports 67505-67506, 67525, codeunits 67507-67508, 67519; control xmlports 67523 (LinkTable with LinkFields) and 67524 (no LinkTable)
// Probe: a child table element that sets LinkTable to its parent element and has no LinkFields, on temporary table elements (UseTemporary) and with a persistent child table. The XmlPort compiles; export and import observe which rows are visited and written (issue 580 item 2).
// BC versions: 27+

table 67503 "LT XLT Parent"
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

table 67504 "LT XLT Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Parent Id"; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67508 "LT XLT Log"
{
    SingleInstance = true;

    var
        Lines: Text;
        SeedExport: Boolean;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure SetSeeding(Value: Boolean)
    begin
        SeedExport := Value;
    end;

    procedure Seeding(): Boolean
    begin
        exit(SeedExport);
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;
}

xmlport 67505 "LT XLT Both Temp"
{
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ParentRow; "LT XLT Parent")
            {
                UseTemporary = true;
                fieldelement(Id; ParentRow.Id) { }
                tableelement(ChildRow; "LT XLT Child")
                {
                    LinkTable = ParentRow;
                    UseTemporary = true;
                    fieldelement(Id; ChildRow.Id) { }
                    fieldelement(ParentId; ChildRow."Parent Id") { }

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('export child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('import child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('export parent ' + Format(ParentRow.Id));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('import parent ' + Format(ParentRow.Id));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        if not Log.Seeding() then
            exit;
        ParentRow.Init();
        ParentRow.Id := 1;
        ParentRow.Insert();
        ParentRow.Id := 2;
        ParentRow.Insert();
        ChildRow.Init();
        ChildRow.Id := 10;
        ChildRow."Parent Id" := 1;
        ChildRow.Insert();
        ChildRow.Id := 11;
        ChildRow."Parent Id" := 1;
        ChildRow.Insert();
        ChildRow.Id := 20;
        ChildRow."Parent Id" := 2;
        ChildRow.Insert();
        ChildRow.Id := 30;
        ChildRow."Parent Id" := 0;
        ChildRow.Insert();
    end;

    var
        Log: Codeunit "LT XLT Log";
}

xmlport 67523 "LT XLT Linked"
{
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ParentRow; "LT XLT Parent")
            {
                UseTemporary = true;
                fieldelement(Id; ParentRow.Id) { }
                tableelement(ChildRow; "LT XLT Child")
                {
                    LinkTable = ParentRow;
                    LinkFields = "Parent Id" = field(Id);
                    UseTemporary = true;
                    fieldelement(Id; ChildRow.Id) { }
                    fieldelement(ParentId; ChildRow."Parent Id") { }

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('export child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('import child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('export parent ' + Format(ParentRow.Id));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('import parent ' + Format(ParentRow.Id));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        if not Log.Seeding() then
            exit;
        ParentRow.Init();
        ParentRow.Id := 1;
        ParentRow.Insert();
        ParentRow.Id := 2;
        ParentRow.Insert();
        ChildRow.Init();
        ChildRow.Id := 10;
        ChildRow."Parent Id" := 1;
        ChildRow.Insert();
        ChildRow.Id := 11;
        ChildRow."Parent Id" := 1;
        ChildRow.Insert();
        ChildRow.Id := 20;
        ChildRow."Parent Id" := 2;
        ChildRow.Insert();
        ChildRow.Id := 30;
        ChildRow."Parent Id" := 0;
        ChildRow.Insert();
    end;

    var
        Log: Codeunit "LT XLT Log";
}

xmlport 67524 "LT XLT No Link"
{
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ParentRow; "LT XLT Parent")
            {
                UseTemporary = true;
                fieldelement(Id; ParentRow.Id) { }
                tableelement(ChildRow; "LT XLT Child")
                {
                                        UseTemporary = true;
                    fieldelement(Id; ChildRow.Id) { }
                    fieldelement(ParentId; ChildRow."Parent Id") { }

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('export child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('import child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('export parent ' + Format(ParentRow.Id));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('import parent ' + Format(ParentRow.Id));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        if not Log.Seeding() then
            exit;
        ParentRow.Init();
        ParentRow.Id := 1;
        ParentRow.Insert();
        ParentRow.Id := 2;
        ParentRow.Insert();
        ChildRow.Init();
        ChildRow.Id := 10;
        ChildRow."Parent Id" := 1;
        ChildRow.Insert();
        ChildRow.Id := 11;
        ChildRow."Parent Id" := 1;
        ChildRow.Insert();
        ChildRow.Id := 20;
        ChildRow."Parent Id" := 2;
        ChildRow.Insert();
        ChildRow.Id := 30;
        ChildRow."Parent Id" := 0;
        ChildRow.Insert();
    end;

    var
        Log: Codeunit "LT XLT Log";
}

xmlport 67506 "LT XLT Child Persistent"
{
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ParentRow; "LT XLT Parent")
            {
                UseTemporary = true;
                fieldelement(Id; ParentRow.Id) { }
                tableelement(ChildRow; "LT XLT Child")
                {
                    LinkTable = ParentRow;
                    fieldelement(Id; ChildRow.Id) { }
                    fieldelement(ParentId; ChildRow."Parent Id") { }

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('export child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('import child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('export parent ' + Format(ParentRow.Id));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('import parent ' + Format(ParentRow.Id));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        if not Log.Seeding() then
            exit;
        ParentRow.Init();
        ParentRow.Id := 1;
        ParentRow.Insert();
        ParentRow.Id := 2;
        ParentRow.Insert();
    end;

    var
        Log: Codeunit "LT XLT Log";
}

xmlport 67525 "LT XLT Persistent Both"
{
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ParentRow; "LT XLT Parent")
            {
                fieldelement(Id; ParentRow.Id) { }
                tableelement(ChildRow; "LT XLT Child")
                {
                    LinkTable = ParentRow;
                    fieldelement(Id; ChildRow.Id) { }
                    fieldelement(ParentId; ChildRow."Parent Id") { }

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('export child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('import child ' + Format(ChildRow.Id) + ' under parent ' + Format(ParentRow.Id));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('export parent ' + Format(ParentRow.Id));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('import parent ' + Format(ParentRow.Id));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        if not Log.Seeding() then
            exit;
        ParentRow.Init();
        ParentRow.Id := 1;
        ParentRow.Insert();
        ParentRow.Id := 2;
        ParentRow.Insert();
    end;

    var
        Log: Codeunit "LT XLT Log";
}

// Runs one import in a codeunit of its own so a failure is observed as text. Rec.Id picks the XmlPort (1 both temporary, 2 persistent child, 3 both temporary with LinkFields, 4 both temporary without LinkTable, 5 both persistent with LinkTable only); Rec."Parent Id" 3 is one parent without children,
// Rec."Parent Id" picks the document (1 one parent with one child, 2 two parents with three children). Not a test codeunit.
codeunit 67519 "LT XLT Import Runner"
{
    TableNo = "LT XLT Child";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        BothTemporary: XmlPort "LT XLT Both Temp";
        PersistentChild: XmlPort "LT XLT Child Persistent";
        Linked: XmlPort "LT XLT Linked";
        NoLink: XmlPort "LT XLT No Link";
        PersistentBoth: XmlPort "LT XLT Persistent Both";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF16);
        if Rec."Parent Id" = 3 then
            OutS.WriteText('<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root><ParentRow><Id>1</Id></ParentRow></Root>')
        else if Rec."Parent Id" = 1 then
            OutS.WriteText('<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root><ParentRow><Id>1</Id><ChildRow><Id>10</Id><ParentId>1</ParentId></ChildRow></ParentRow></Root>')
        else
            OutS.WriteText('<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root><ParentRow><Id>1</Id><ChildRow><Id>10</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>11</Id><ParentId>1</ParentId></ChildRow></ParentRow><ParentRow><Id>2</Id><ChildRow><Id>20</Id><ParentId>2</ParentId></ChildRow></ParentRow></Root>');
        TempBlob.CreateInStream(InS);
        case Rec.Id of
            1:
                begin
                    BothTemporary.SetSource(InS);
                    BothTemporary.Import();
                end;
            2:
                begin
                    PersistentChild.SetSource(InS);
                    PersistentChild.Import();
                end;
            3:
                begin
                    Linked.SetSource(InS);
                    Linked.Import();
                end;
            4:
                begin
                    NoLink.SetSource(InS);
                    NoLink.Import();
                end;
            5:
                begin
                    PersistentBoth.SetSource(InS);
                    PersistentBoth.Import();
                end;
        end;
    end;
}

codeunit 67507 "LT XLT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT XLT Log";

    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line;
        end;
        exit(Result.Replace('  ', ''));
    end;

    local procedure Import(var Observer: Codeunit "Probe Observer"; PortNo: Integer; Document: Integer)
    var
        Arg: Record "LT XLT Child" temporary;
        Child: Record "LT XLT Child";
        Parent: Record "LT XLT Parent";
        Rows: Text;
        Ok: Boolean;
    begin
        Child.DeleteAll();
        Parent.DeleteAll();
        Log.Take();
        ClearLastError();
        Arg.Id := PortNo;
        Arg."Parent Id" := Document;
        Arg.Insert();
        Commit();
        Ok := Codeunit.Run(Codeunit::"LT XLT Import Runner", Arg);
        Observer.Observe('result', Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('log', Log.Take());
        if Child.FindSet() then
            repeat
                Rows += Format(Child.Id) + '/' + Format(Child."Parent Id") + ' ';
            until Child.Next() = 0;
        Observer.Observe('persistent_child_rows', Rows);
        Observer.Observe('persistent_parent_count', Format(Parent.Count()));
    end;

    local procedure SeedChildren()
    var
        Child: Record "LT XLT Child";
    begin
        Child.DeleteAll();
        Child.Id := 10;
        Child."Parent Id" := 1;
        Child.Insert();
        Child.Id := 11;
        Child."Parent Id" := 1;
        Child.Insert();
        Child.Id := 20;
        Child."Parent Id" := 2;
        Child.Insert();
        Child.Id := 30;
        Child."Parent Id" := 0;
        Child.Insert();
    end;

    [Test]
    procedure BothTemporary_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT XLT Both Temp";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Log.SetSeeding(true);
        Port.Export();
        Log.SetSeeding(false);
        Observer.Observe('xml', ReadAll(TempBlob));
        Observer.Observe('log', Log.Take());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root><ParentRow><Id>1</Id><ChildRow><Id>10</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>11</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>20</Id><ParentId>2</ParentId></ChildRow><ChildRow><Id>30</Id><ParentId>0</ParentId></ChildRow></ParentRow><ParentRow><Id>2</Id><ChildRow><Id>10</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>11</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>20</Id><ParentId>2</ParentId></ChildRow><ChildRow><Id>30</Id><ParentId>0</ParentId></ChildRow></ParentRow></Root>');
        Observer.Expect('log', 'export parent 1;export child 10 under parent 1;export child 11 under parent 1;export child 20 under parent 1;export child 30 under parent 1;export parent 2;export child 10 under parent 2;export child 11 under parent 2;export child 20 under parent 2;export child 30 under parent 2;');
        Observer.Verify();
    end;



    [Test]
    procedure PersistentChild_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT XLT Child Persistent";
        OutS: OutStream;
    begin
        SeedChildren();
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Log.SetSeeding(true);
        Port.Export();
        Log.SetSeeding(false);
        Observer.Observe('xml', ReadAll(TempBlob));
        Observer.Observe('log', Log.Take());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root><ParentRow><Id>1</Id><ChildRow><Id>10</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>11</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>20</Id><ParentId>2</ParentId></ChildRow><ChildRow><Id>30</Id><ParentId>0</ParentId></ChildRow></ParentRow><ParentRow><Id>2</Id><ChildRow><Id>10</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>11</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>20</Id><ParentId>2</ParentId></ChildRow><ChildRow><Id>30</Id><ParentId>0</ParentId></ChildRow></ParentRow></Root>');
        Observer.Expect('log', 'export parent 1;export child 10 under parent 1;export child 11 under parent 1;export child 20 under parent 1;export child 30 under parent 1;export parent 2;export child 10 under parent 2;export child 11 under parent 2;export child 20 under parent 2;export child 30 under parent 2;');
        Observer.Verify();
    end;



    [Test]
    procedure BothTemporary_Import_OneParentOneChild()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 1, 1);
        Observer.Expect('result', 'Yes||');
        Observer.Expect('log', 'import parent 1;import child 10 under parent 1;');
        Observer.Expect('persistent_child_rows', '');
        Observer.Expect('persistent_parent_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure BothTemporary_Import_TwoParents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 1, 2);
        Observer.Expect('result', 'Yes||');
        Observer.Expect('log', 'import parent 1;import child 10 under parent 1;import child 11 under parent 1;import parent 2;import child 20 under parent 2;');
        Observer.Expect('persistent_child_rows', '');
        Observer.Expect('persistent_parent_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PersistentChild_Import_OneParentOneChild()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 2, 1);
        Observer.Expect('result', 'Yes||');
        Observer.Expect('log', 'import parent 1;import child 10 under parent 1;');
        Observer.Expect('persistent_child_rows', '10/1 ');
        Observer.Expect('persistent_parent_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PersistentChild_Import_TwoParents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 2, 2);
        Observer.Expect('result', 'Yes||');
        Observer.Expect('log', 'import parent 1;import child 10 under parent 1;import child 11 under parent 1;import parent 2;import child 20 under parent 2;');
        Observer.Expect('persistent_child_rows', '10/1 11/1 20/2 ');
        Observer.Expect('persistent_parent_count', '0');
        Observer.Verify();
    end;
    [Test]
    procedure Linked_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT XLT Linked";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Log.SetSeeding(true);
        Port.Export();
        Log.SetSeeding(false);
        Observer.Observe('xml', ReadAll(TempBlob));
        Observer.Observe('log', Log.Take());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root><ParentRow><Id>1</Id><ChildRow><Id>10</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>11</Id><ParentId>1</ParentId></ChildRow></ParentRow><ParentRow><Id>2</Id><ChildRow><Id>20</Id><ParentId>2</ParentId></ChildRow></ParentRow></Root>');
        Observer.Expect('log', 'export parent 1;export child 10 under parent 1;export child 11 under parent 1;export parent 2;export child 20 under parent 2;');
        Observer.Verify();
    end;

    [Test]
    procedure NoLinkTable_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT XLT No Link";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Log.SetSeeding(true);
        Port.Export();
        Log.SetSeeding(false);
        Observer.Observe('xml', ReadAll(TempBlob));
        Observer.Observe('log', Log.Take());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root><ParentRow><Id>1</Id><ChildRow><Id>10</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>11</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>20</Id><ParentId>2</ParentId></ChildRow><ChildRow><Id>30</Id><ParentId>0</ParentId></ChildRow></ParentRow><ParentRow><Id>2</Id><ChildRow><Id>10</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>11</Id><ParentId>1</ParentId></ChildRow><ChildRow><Id>20</Id><ParentId>2</ParentId></ChildRow><ChildRow><Id>30</Id><ParentId>0</ParentId></ChildRow></ParentRow></Root>');
        Observer.Expect('log', 'export parent 1;export child 10 under parent 1;export child 11 under parent 1;export child 20 under parent 1;export child 30 under parent 1;export parent 2;export child 10 under parent 2;export child 11 under parent 2;export child 20 under parent 2;export child 30 under parent 2;');
        Observer.Verify();
    end;

    [Test]
    procedure Linked_Import_OneParentOneChild()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 3, 1);
        Observer.Expect('result', 'Yes||');
        Observer.Expect('log', 'import parent 1;import child 10 under parent 1;');
        Observer.Expect('persistent_child_rows', '');
        Observer.Expect('persistent_parent_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Linked_Import_TwoParents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 3, 2);
        Observer.Expect('result', 'Yes||');
        Observer.Expect('log', 'import parent 1;import child 10 under parent 1;import child 11 under parent 1;import parent 2;import child 20 under parent 2;');
        Observer.Expect('persistent_child_rows', '');
        Observer.Expect('persistent_parent_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NoLinkTable_Import_OneParentOneChild()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 4, 1);
        Observer.Expect('result', 'Yes||');
        Observer.Expect('log', 'import child 10 under parent 1;import parent 1;');
        Observer.Expect('persistent_child_rows', '');
        Observer.Expect('persistent_parent_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NoLinkTable_Import_TwoParents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 4, 2);
        Observer.Expect('result', 'Yes||');
        Observer.Expect('log', 'import child 10 under parent 1;import child 11 under parent 1;import parent 1;import child 20 under parent 2;import parent 2;');
        Observer.Expect('persistent_child_rows', '');
        Observer.Expect('persistent_parent_count', '0');
        Observer.Verify();
    end;
    [Test]
    procedure BothTemporary_Import_ParentOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 1, 3);
        Observer.Expect('result', 'No|Imported XML cannot validate with the schema: The element ''ParentRow'' has incomplete content. List of possible elements expected: ''ChildRow''.|XmlPortInvalidXml');
        Observer.Expect('log', '');
        Observer.Expect('persistent_child_rows', '');
        Observer.Expect('persistent_parent_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NoLinkTable_Import_ParentOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 4, 3);
        Observer.Expect('result', 'No|Imported XML cannot validate with the schema: The element ''ParentRow'' has incomplete content. List of possible elements expected: ''ChildRow''.|XmlPortInvalidXml');
        Observer.Expect('log', '');
        Observer.Expect('persistent_child_rows', '');
        Observer.Expect('persistent_parent_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PersistentBoth_Import_OneParentOneChild()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 5, 1);
        Observer.Expect('result', 'Yes||');
        Observer.Expect('log', 'import parent 1;import child 10 under parent 1;');
        Observer.Expect('persistent_child_rows', '10/1 ');
        Observer.Expect('persistent_parent_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure PersistentBoth_Import_TwoParents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 5, 2);
        Observer.Expect('result', 'Yes||');
        Observer.Expect('log', 'import parent 1;import child 10 under parent 1;import child 11 under parent 1;import parent 2;import child 20 under parent 2;');
        Observer.Expect('persistent_child_rows', '10/1 11/1 20/2 ');
        Observer.Expect('persistent_parent_count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure PersistentBoth_Import_ParentOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 5, 3);
        Observer.Expect('result', 'No|Imported XML cannot validate with the schema: The element ''ParentRow'' has incomplete content. List of possible elements expected: ''ChildRow''.|XmlPortInvalidXml');
        Observer.Expect('log', '');
        Observer.Expect('persistent_child_rows', '');
        Observer.Expect('persistent_parent_count', '0');
        Observer.Verify();
    end;
}
