// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-maxoccurs-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-linktable-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y83 Helper (Y83XpFixtures.al, import through Codeunit.Run); own tables 95880-95881, xmlports 95882-95886, test codeunit 95887
// Probe: a table element nested in another one, linked to it (LinkTable), with MaxOccurs = Once and no MinOccurs (al-runner issue 7090).
//   The reporter's shape: the parent has MaxOccurs = Once, the child has LinkFields, MaxOccurs = Once and UseTemporary = true, and the
//   parent's OnAfterGetRecord fills the temporary child. Exported with zero, one and two child rows, and with two parents (the parent's
//   MaxOccurs = Once). Neighbours: the same with a parent of MaxOccurs = Unbounded (three parents with 0, 1 and 2 children), a real child
//   table with LinkFields, a real child table with LinkTable and no LinkFields, and the import of the real-table shape (zero, one and
//   two child elements). After an export the test also reads the row the child record holds and its filters.
// Result (BC 27.5, 28.5 and 29.0 alike; corpus CI runs 42026852726, 42026909098, 42026971340): no MinOccurs on the nested linked element is MinOccurs = Once. Export, temporary or real
//   child with LinkFields: the first linked row of each pass; a pass without rows writes the element once with the record as it stands
//   (blank before any row, else the row the record holds); after two rows the record holds the second. The temporary child filled by
//   the parent's OnAfterGetRecord (DeleteAll, then inserts) follows the same rule: a pass whose trigger inserts none writes the row the
//   record held before the DeleteAll. A parent with MaxOccurs = Once writes only its first row. Without LinkFields the child is not
//   filtered: every pass writes the first child row of the table, and after three rows the record holds the second. Import: one child
//   element per parent imports; none fails the schema ("has incomplete content"), two fail it ("has invalid child element").
// BC versions: 27, 28, 29

table 95880 "LT XOM Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry no."; Code[10]) { }
        field(2; Children; Integer) { }
    }

    keys { key(PK; "Entry no.") { Clustered = true; } }
}

table 95881 "LT XOM Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry no. parent"; Code[10]) { }
        field(2; Line; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; "Entry no. parent", Line) { Clustered = true; } }
}

// The reporter's shape: parent MaxOccurs = Once, temporary linked child with MaxOccurs = Once, filled by the parent's OnAfterGetRecord.
xmlport 95882 "LT XOM Temp Once"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(parent; "LT XOM Parent")
            {
                MaxOccurs = Once;
                XmlName = 'Transport';
                fieldattribute(no; parent."Entry no.") { }
                tableelement(child; "LT XOM Child")
                {
                    LinkFields = "Entry no. parent" = field("Entry no.");
                    LinkTable = parent;
                    MaxOccurs = Once;
                    XmlName = 'MainInfo';
                    UseTemporary = true;
                    fieldelement(Name; child.Name) { }
                }

                trigger OnAfterGetRecord()
                var
                    i: Integer;
                begin
                    child.DeleteAll();
                    for i := 1 to parent.Children do begin
                        child."Entry no. parent" := parent."Entry no.";
                        child.Line := i;
                        child.Name := 'CHILD-' + parent."Entry no." + '-' + Format(i);
                        child.Insert();
                    end;
                end;
            }
        }
    }

    procedure HeldChild(): Text
    begin
        exit(child."Entry no. parent" + '/' + Format(child.Line) + '/' + child.Name + '|filters=' + child.GetFilters() + '|count=' + Format(child.Count()));
    end;
}

// The same with a parent of MaxOccurs = Unbounded.
xmlport 95883 "LT XOM Temp Once Unbounded"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(parent; "LT XOM Parent")
            {
                MaxOccurs = Unbounded;
                XmlName = 'Transport';
                fieldattribute(no; parent."Entry no.") { }
                tableelement(child; "LT XOM Child")
                {
                    LinkFields = "Entry no. parent" = field("Entry no.");
                    LinkTable = parent;
                    MaxOccurs = Once;
                    XmlName = 'MainInfo';
                    UseTemporary = true;
                    fieldelement(Name; child.Name) { }
                }

                trigger OnAfterGetRecord()
                var
                    i: Integer;
                begin
                    child.DeleteAll();
                    for i := 1 to parent.Children do begin
                        child."Entry no. parent" := parent."Entry no.";
                        child.Line := i;
                        child.Name := 'CHILD-' + parent."Entry no." + '-' + Format(i);
                        child.Insert();
                    end;
                end;
            }
        }
    }

    procedure HeldChild(): Text
    begin
        exit(child."Entry no. parent" + '/' + Format(child.Line) + '/' + child.Name + '|filters=' + child.GetFilters() + '|count=' + Format(child.Count()));
    end;
}

// A real child table, linked with LinkFields, MaxOccurs = Once and no MinOccurs.
xmlport 95884 "LT XOM Real Once"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(parent; "LT XOM Parent")
            {
                XmlName = 'Transport';
                fieldattribute(no; parent."Entry no.") { }
                tableelement(child; "LT XOM Child")
                {
                    LinkFields = "Entry no. parent" = field("Entry no.");
                    LinkTable = parent;
                    MaxOccurs = Once;
                    XmlName = 'MainInfo';
                    fieldattribute(line; child.Line) { }
                    fieldelement(Name; child.Name) { }
                }
            }
        }
    }

    procedure HeldChild(): Text
    begin
        exit(child."Entry no. parent" + '/' + Format(child.Line) + '/' + child.Name + '|filters=' + child.GetFilters());
    end;
}

// A real child table with LinkTable and no LinkFields, MaxOccurs = Once and no MinOccurs.
xmlport 95885 "LT XOM NoFields Once"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(parent; "LT XOM Parent")
            {
                XmlName = 'Transport';
                fieldattribute(no; parent."Entry no.") { }
                tableelement(child; "LT XOM Child")
                {
                    LinkTable = parent;
                    MaxOccurs = Once;
                    XmlName = 'MainInfo';
                    fieldattribute(line; child.Line) { }
                    fieldelement(Name; child.Name) { }
                }
            }
        }
    }

    procedure HeldChild(): Text
    begin
        exit(child."Entry no. parent" + '/' + Format(child.Line) + '/' + child.Name + '|filters=' + child.GetFilters());
    end;
}

// The import of the real-table shape.
xmlport 95886 "LT XOM Import Once"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(parent; "LT XOM Parent")
            {
                XmlName = 'Transport';
                fieldattribute(no; parent."Entry no.") { }
                tableelement(child; "LT XOM Child")
                {
                    LinkFields = "Entry no. parent" = field("Entry no.");
                    LinkTable = parent;
                    MaxOccurs = Once;
                    XmlName = 'MainInfo';
                    fieldattribute(line; child.Line) { }
                    fieldelement(Name; child.Name) { }
                }
            }
        }
    }
}

codeunit 95887 "LT XOM Nested Once Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure XOM_TempOnce_OneParent_ZeroChildren()
    var
        Port: XmlPort "LT XOM Temp Once";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        SeedParents(0, -1, -1);
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ReadText(TempBlob));
        Observer.Observe('held', Port.HeldChild());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Transport no="P1">|    <MainInfo>|      <Name />|    </MainInfo>|  </Transport>|</Root>|');
        Observer.Expect('held', '/0/|filters=|count=0');
        Observer.Verify();
    end;

    [Test]
    procedure XOM_TempOnce_OneParent_OneChild()
    var
        Port: XmlPort "LT XOM Temp Once";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        SeedParents(1, -1, -1);
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ReadText(TempBlob));
        Observer.Observe('held', Port.HeldChild());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Transport no="P1">|    <MainInfo>|      <Name>CHILD-P1-1</Name>|    </MainInfo>|  </Transport>|</Root>|');
        Observer.Expect('held', 'P1/1/CHILD-P1-1|filters=|count=1');
        Observer.Verify();
    end;

    [Test]
    procedure XOM_TempOnce_OneParent_TwoChildren()
    var
        Port: XmlPort "LT XOM Temp Once";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        SeedParents(2, -1, -1);
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ReadText(TempBlob));
        Observer.Observe('held', Port.HeldChild());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Transport no="P1">|    <MainInfo>|      <Name>CHILD-P1-1</Name>|    </MainInfo>|  </Transport>|</Root>|');
        Observer.Expect('held', 'P1/2/CHILD-P1-2|filters=|count=2');
        Observer.Verify();
    end;

    [Test]
    procedure XOM_TempOnce_TwoParents()
    var
        Port: XmlPort "LT XOM Temp Once";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        SeedParents(1, 2, -1);
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ReadText(TempBlob));
        Observer.Observe('held', Port.HeldChild());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Transport no="P1">|    <MainInfo>|      <Name>CHILD-P1-1</Name>|    </MainInfo>|  </Transport>|</Root>|');
        Observer.Expect('held', 'P1/1/CHILD-P1-1|filters=|count=1');
        Observer.Verify();
    end;

    [Test]
    procedure XOM_TempOnceUnbounded_ZeroOneTwoChildren()
    var
        Port: XmlPort "LT XOM Temp Once Unbounded";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        SeedParents(0, 1, 2);
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ReadText(TempBlob));
        Observer.Observe('held', Port.HeldChild());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Transport no="P1">|    <MainInfo>|      <Name />|    </MainInfo>|  </Transport>|  <Transport no="P2">|    <MainInfo>|      <Name>CHILD-P2-1</Name>|    </MainInfo>|  </Transport>|  <Transport no="P3">|    <MainInfo>|      <Name>CHILD-P3-1</Name>|    </MainInfo>|  </Transport>|</Root>|');
        Observer.Expect('held', 'P3/2/CHILD-P3-2|filters=|count=2');
        Observer.Verify();
    end;

    [Test]
    procedure XOM_TempOnceUnbounded_TwoOneZeroChildren()
    var
        Port: XmlPort "LT XOM Temp Once Unbounded";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        SeedParents(2, 1, 0);
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ReadText(TempBlob));
        Observer.Observe('held', Port.HeldChild());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Transport no="P1">|    <MainInfo>|      <Name>CHILD-P1-1</Name>|    </MainInfo>|  </Transport>|  <Transport no="P2">|    <MainInfo>|      <Name>CHILD-P2-1</Name>|    </MainInfo>|  </Transport>|  <Transport no="P3">|    <MainInfo>|      <Name>CHILD-P2-1</Name>|    </MainInfo>|  </Transport>|</Root>|');
        Observer.Expect('held', 'P2/1/CHILD-P2-1|filters=|count=0');
        Observer.Verify();
    end;

    [Test]
    procedure XOM_RealOnce_ZeroOneTwoChildren()
    var
        Port: XmlPort "LT XOM Real Once";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        SeedParents(0, 1, 2);
        SeedRealChildren();
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ReadText(TempBlob));
        Observer.Observe('held', Port.HeldChild());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Transport no="P1">|    <MainInfo line="0">|      <Name />|    </MainInfo>|  </Transport>|  <Transport no="P2">|    <MainInfo line="1">|      <Name>R-P2-1</Name>|    </MainInfo>|  </Transport>|  <Transport no="P3">|    <MainInfo line="1">|      <Name>R-P3-1</Name>|    </MainInfo>|  </Transport>|</Root>|');
        Observer.Expect('held', 'P3/2/R-P3-2|filters=');
        Observer.Verify();
    end;

    [Test]
    procedure XOM_RealOnce_TwoOneZeroChildren()
    var
        Port: XmlPort "LT XOM Real Once";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        SeedParents(2, 1, 0);
        SeedRealChildren();
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ReadText(TempBlob));
        Observer.Observe('held', Port.HeldChild());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Transport no="P1">|    <MainInfo line="1">|      <Name>R-P1-1</Name>|    </MainInfo>|  </Transport>|  <Transport no="P2">|    <MainInfo line="1">|      <Name>R-P2-1</Name>|    </MainInfo>|  </Transport>|  <Transport no="P3">|    <MainInfo line="1">|      <Name>R-P2-1</Name>|    </MainInfo>|  </Transport>|</Root>|');
        Observer.Expect('held', 'P2/1/R-P2-1|filters=');
        Observer.Verify();
    end;

    [Test]
    procedure XOM_NoFieldsOnce_ZeroOneTwoChildren()
    var
        Port: XmlPort "LT XOM NoFields Once";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        SeedParents(0, 1, 2);
        SeedRealChildren();
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ReadText(TempBlob));
        Observer.Observe('held', Port.HeldChild());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Transport no="P1">|    <MainInfo line="1">|      <Name>R-P2-1</Name>|    </MainInfo>|  </Transport>|  <Transport no="P2">|    <MainInfo line="1">|      <Name>R-P2-1</Name>|    </MainInfo>|  </Transport>|  <Transport no="P3">|    <MainInfo line="1">|      <Name>R-P2-1</Name>|    </MainInfo>|  </Transport>|</Root>|');
        Observer.Expect('held', 'P3/1/R-P3-1|filters=');
        Observer.Verify();
    end;

    [Test]
    procedure XOM_ImportOnce_OneChild()
    begin
        Observer.Observe('import', TryImport('<Root><Transport no="P1"><MainInfo line="1"><Name>a</Name></MainInfo></Transport></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Expect('import', 'ok');
        Observer.Expect('rows', 'P:P1;C:P1/1/a;');
        Observer.Verify();
    end;

    [Test]
    procedure XOM_ImportOnce_NoChild()
    begin
        Observer.Observe('import', TryImport('<Root><Transport no="P1"></Transport><Transport no="P2"><MainInfo line="1"><Name>b</Name></MainInfo></Transport></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Expect('import', 'error:Imported XML cannot validate with the schema: The element ''Transport'' has incomplete content. List of possible elements expected: ''MainInfo''.|XmlPortInvalidXml');
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure XOM_ImportOnce_TwoChildren()
    begin
        Observer.Observe('import', TryImport('<Root><Transport no="P1"><MainInfo line="1"><Name>a</Name></MainInfo><MainInfo line="2"><Name>b</Name></MainInfo></Transport></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Expect('import', 'error:Imported XML cannot validate with the schema: The element ''Transport'' has invalid child element ''MainInfo''.|XmlPortInvalidXml');
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    // Parents P1, P2, P3 (a negative count leaves the parent out) with that many children each.
    local procedure SeedParents(A: Integer; B: Integer; C: Integer)
    var
        Parent: Record "LT XOM Parent";
        Child: Record "LT XOM Child";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        AddParent('P1', A);
        AddParent('P2', B);
        AddParent('P3', C);
    end;

    local procedure AddParent(No: Code[10]; Children: Integer)
    var
        Parent: Record "LT XOM Parent";
    begin
        if Children < 0 then
            exit;
        Parent."Entry no." := No;
        Parent.Children := Children;
        Parent.Insert();
    end;

    // Real child rows: for each parent as many as its Children field says, named R-<parent>-<line>.
    local procedure SeedRealChildren()
    var
        Parent: Record "LT XOM Parent";
        Child: Record "LT XOM Child";
        i: Integer;
    begin
        if Parent.FindSet() then
            repeat
                for i := 1 to Parent.Children do begin
                    Child."Entry no. parent" := Parent."Entry no.";
                    Child.Line := i;
                    Child.Name := 'R-' + Parent."Entry no." + '-' + Format(i);
                    Child.Insert();
                end;
            until Parent.Next() = 0;
    end;

    local procedure ReadText(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure Rows(): Text
    var
        Parent: Record "LT XOM Parent";
        Child: Record "LT XOM Child";
        Result: Text;
    begin
        if Parent.FindSet() then
            repeat
                Result += 'P:' + Parent."Entry no." + ';';
            until Parent.Next() = 0;
        if Child.FindSet() then
            repeat
                Result += 'C:' + Child."Entry no. parent" + '/' + Format(Child.Line) + '/' + Child.Name + ';';
            until Child.Next() = 0;
        exit(Result);
    end;

    // ok, or error:<text>|<code> (LT Y83 Helper commits and imports through Codeunit.Run).
    local procedure TryImport(Doc: Text): Text
    var
        Parent: Record "LT XOM Parent";
        Child: Record "LT XOM Child";
        Helper: Codeunit "LT Y83 Helper";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        exit(Helper.TryImport(Xmlport::"LT XOM Import Once", Doc, false));
    end;
}
