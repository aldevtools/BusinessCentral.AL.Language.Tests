// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT Y68 XP Parent" (93656) and log codeunit "LT Y68 XP Log" (93661) from Y68XmlPortShapes.al;
//   own xmlports 75062-75068, test codeunit 75070
// local object: the schemas of the ports are what is under test
// Probe (observe only): al-runner issue 7396. An xmlport (Format = Xml) whose whole schema is one table element at the root with no child
//   elements: with a namespace prefix (the reported shape), plain, with a default namespace, with MaxOccurs = Once, with MinOccurs = Zero,
//   with table triggers that log, and with one field attribute as the only content (control). Export with 0, 1 and 2 rows in the table,
//   with a record filtered to one row handed to Xmlport.Export, and import of a document that is one empty root element.
//   Each observation is the return value and the exact exported text (lines joined with |), or the error text and code.
// BC versions: 27, 28, 29

xmlport 75062 "LT XRT Prefix"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = v1 = 'http://example.com/v1';

    schema
    {
        tableelement(MyRequest; "LT Y68 XP Parent")
        {
            NamespacePrefix = 'v1';
        }
    }
}

xmlport 75063 "LT XRT Plain"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(MyRequest; "LT Y68 XP Parent")
        {
        }
    }
}

xmlport 75064 "LT XRT Default Ns"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'http://example.com/default';
    UseDefaultNamespace = true;

    schema
    {
        tableelement(MyRequest; "LT Y68 XP Parent")
        {
        }
    }
}

xmlport 75065 "LT XRT Once"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(MyRequest; "LT Y68 XP Parent")
        {
            MaxOccurs = Once;
        }
    }
}

xmlport 75066 "LT XRT Min Zero"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(MyRequest; "LT Y68 XP Parent")
        {
            MinOccurs = Zero;
        }
    }
}

xmlport 75067 "LT XRT Triggers"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(MyRequest; "LT Y68 XP Parent")
        {
            trigger OnPreXmlItem()
            begin
                Log.Add('pre');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('get ' + MyRequest."No.");
            end;

            trigger OnAfterInitRecord()
            begin
                Log.Add('init');
            end;

            trigger OnBeforeInsertRecord()
            begin
                Log.Add('before insert ' + MyRequest."No.");
            end;

            trigger OnAfterInsertRecord()
            begin
                Log.Add('after insert ' + MyRequest."No.");
            end;
        }
    }

    trigger OnPreXmlPort()
    begin
        Log.Add('pre port');
    end;

    trigger OnPostXmlPort()
    begin
        Log.Add('post port');
    end;

    var
        Log: Codeunit "LT Y68 XP Log";
}

xmlport 75068 "LT XRT Attribute"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(MyRequest; "LT Y68 XP Parent")
        {
            fieldattribute(No; MyRequest."No.") { }
        }
    }
}

codeunit 75070 "LT XRT Root Table No Children"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y68 XP Log";

    local procedure Clean()
    var
        P: Record "LT Y68 XP Parent";
    begin
        P.DeleteAll();
        Log.Take();
        ClearLastError();
    end;

    local procedure Seed(Rows: Integer)
    var
        P: Record "LT Y68 XP Parent";
        Index: Integer;
    begin
        Clean();
        for Index := 1 to Rows do begin
            P.Init();
            P."No." := 'P' + Format(Index);
            P.Name := 'name ' + Format(Index);
            P.Insert();
        end;
    end;

    local procedure ReadLines(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryExport(XmlportId: Integer; var Result: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        TempBlob.CreateOutStream(OutS);
        Ok := Xmlport.Export(XmlportId, OutS);
        Result := 'returned ' + Format(Ok) + ': ' + ReadLines(TempBlob);
    end;

    [TryFunction]
    local procedure TryExportFiltered(XmlportId: Integer; No: Code[10]; var Result: Text)
    var
        P: Record "LT Y68 XP Parent";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        P.Get(No);
        P.SetRecFilter();
        TempBlob.CreateOutStream(OutS);
        Ok := Xmlport.Export(XmlportId, OutS, P);
        Result := 'returned ' + Format(Ok) + ': ' + ReadLines(TempBlob);
    end;

    [TryFunction]
    local procedure TryImport(XmlportId: Integer; Content: Text; var Result: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Ok: Boolean;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Ok := Xmlport.Import(XmlportId, InS);
        Result := 'returned ' + Format(Ok);
    end;

    local procedure Rows() Result: Text
    var
        P: Record "LT Y68 XP Parent";
    begin
        if P.FindSet() then
            repeat
                Result += '[' + P."No." + '|' + P.Name + ']';
            until P.Next() = 0;
    end;

    local procedure ObserveExport(var Observer: Codeunit "Probe Observer"; Name: Text; XmlportId: Integer; RowCount: Integer)
    var
        Result: Text;
    begin
        Seed(RowCount);
        if TryExport(XmlportId, Result) then
            Observer.Observe(Name, Result)
        else
            Observer.ObserveError(Name);
    end;

    local procedure ObserveExportFiltered(var Observer: Codeunit "Probe Observer"; Name: Text; XmlportId: Integer)
    var
        Result: Text;
    begin
        Seed(2);
        if TryExportFiltered(XmlportId, 'P2', Result) then
            Observer.Observe(Name, Result)
        else
            Observer.ObserveError(Name);
    end;

    local procedure ObserveImport(var Observer: Codeunit "Probe Observer"; Name: Text; XmlportId: Integer; Content: Text)
    var
        Result: Text;
    begin
        Clean();
        if TryImport(XmlportId, Content, Result) then
            Observer.Observe(Name, Result)
        else
            Observer.ObserveError(Name);
        Observer.Observe(Name + ' rows', Rows());
    end;

    local procedure ObserveAllExports(var Observer: Codeunit "Probe Observer"; XmlportId: Integer)
    begin
        ObserveExport(Observer, '0 rows', XmlportId, 0);
        ObserveExport(Observer, '1 row', XmlportId, 1);
        ObserveExport(Observer, '2 rows', XmlportId, 2);
        ObserveExportFiltered(Observer, 'record filtered to P2 of 2 rows', XmlportId);
    end;

    [Test]
    procedure RootTableNoChildren_NamespacePrefix_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAllExports(Observer, Xmlport::"LT XRT Prefix");
        Observer.Finish();
    end;

    [Test]
    procedure RootTableNoChildren_Plain_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAllExports(Observer, Xmlport::"LT XRT Plain");
        Observer.Finish();
    end;

    [Test]
    procedure RootTableNoChildren_DefaultNamespace_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAllExports(Observer, Xmlport::"LT XRT Default Ns");
        Observer.Finish();
    end;

    [Test]
    procedure RootTableNoChildren_MaxOccursOnce_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAllExports(Observer, Xmlport::"LT XRT Once");
        Observer.Finish();
    end;

    [Test]
    procedure RootTableNoChildren_MinOccursZero_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAllExports(Observer, Xmlport::"LT XRT Min Zero");
        Observer.Finish();
    end;

    [Test]
    procedure RootTableNoChildren_Triggers_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveExport(Observer, '0 rows', Xmlport::"LT XRT Triggers", 0);
        Observer.Observe('0 rows log', Log.Take());
        ObserveExport(Observer, '1 row', Xmlport::"LT XRT Triggers", 1);
        Observer.Observe('1 row log', Log.Take());
        ObserveExport(Observer, '2 rows', Xmlport::"LT XRT Triggers", 2);
        Observer.Observe('2 rows log', Log.Take());
        ObserveExportFiltered(Observer, 'record filtered to P2 of 2 rows', Xmlport::"LT XRT Triggers");
        Observer.Observe('filtered log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure RootTableOnlyAttribute_Export_Control()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAllExports(Observer, Xmlport::"LT XRT Attribute");
        Observer.Finish();
    end;

    [Test]
    procedure RootTableNoChildren_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'plain empty root', Xmlport::"LT XRT Plain", '<MyRequest />');
        ObserveImport(Observer, 'plain root with text', Xmlport::"LT XRT Plain", '<MyRequest>x</MyRequest>');
        ObserveImport(Observer, 'plain other root name', Xmlport::"LT XRT Plain", '<Other />');
        Observer.Finish();
    end;

    [Test]
    procedure RootTableNoChildren_Import_Namespaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'prefix empty root', Xmlport::"LT XRT Prefix", '<v1:MyRequest xmlns:v1="http://example.com/v1" />');
        ObserveImport(Observer, 'prefix root without namespace', Xmlport::"LT XRT Prefix", '<MyRequest />');
        ObserveImport(Observer, 'default namespace empty root', Xmlport::"LT XRT Default Ns", '<MyRequest xmlns="http://example.com/default" />');
        Observer.Finish();
    end;

    [Test]
    procedure RootTableNoChildren_Import_MinZeroTriggersAttribute()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'min zero empty root', Xmlport::"LT XRT Min Zero", '<MyRequest />');
        ObserveImport(Observer, 'triggers empty root', Xmlport::"LT XRT Triggers", '<MyRequest />');
        Observer.Observe('triggers import log', Log.Take());
        ObserveImport(Observer, 'attribute root', Xmlport::"LT XRT Attribute", '<MyRequest No="A1" />');
        Observer.Finish();
    end;
}
