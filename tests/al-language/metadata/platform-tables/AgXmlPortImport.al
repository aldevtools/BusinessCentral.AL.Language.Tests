// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own tables 78410-78411, codeunit 78405, xmlports 78420 to 78424, test codeunit 78402;
//   writer QX: tables 87560, 87561, 87570, xmlports 87562 to 87568, runner codeunit 87569 (test procedures QX_*)
// Probe: XmlPort properties that Microsoft's Contoso demo-data xmlports use on import: Occurrence = Optional and Required on field attributes
// (missing and present attribute), SourceTableView on a tableelement (import and export), and an empty requestpage section against none
// (Xmlport.Import and Xmlport.Export from code). MinOccurs on a tableelement, FieldValidate and Encoding on import are pinned in
// xmlport/W7XmlPortTests.al, pages/lt-report-page-properties/06-xmlport-fvat.al and xmlport/lt-af-xmlport/AfXmlPortEncoding.al.
// Writer QX (shapes of Microsoft's DemoTool, which builds the company for Microsoft's Legacy tests; own objects with the same AL shape):
//   request page with empty layout { } and actions { } sections, layout only, actions only (static and XmlPort-variable import and export);
//   Format = Xml whose schema root is a table element (one element, row already there, other root name, two roots, empty root, export of
//   0, 1 and 2 rows); a field element whose field relates to Windows Language with Globally Enabled and STX File Exist filters;
//   Format = VariableText with DefaultFieldsValidation = false, text elements (MinOccurs = Zero) that Evaluate(Decimal, Text, 9), short lines.
// BC versions: 27-29

table 78410 "LT AG XP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Active; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 78420 "LT AG XP Attr Occurrence"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                fieldattribute(Id; Row.Id)
                {
                    Occurrence = Required;
                }
                fieldattribute(Name; Row.Name)
                {
                    Occurrence = Optional;
                }
                fieldattribute(Active; Row.Active)
                {
                    Occurrence = Required;
                }
            }
        }
    }
}

xmlport 78421 "LT AG XP Source Table View"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                SourceTableView = sorting(Id) order(descending) where(Active = const(true));
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
                fieldelement(Active; Row.Active) { }
            }
        }
    }
}

xmlport 78422 "LT AG XP Empty Request Page"
{
    Direction = Both;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }

    requestpage
    {
    }
}

xmlport 78423 "LT AG XP No Request Page"
{
    Direction = Both;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 78424 "LT AG XP Elem MinOccurs Import"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                MinOccurs = Zero;
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

table 78411 "LT AG XP Job"
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

codeunit 78405 "LT AG XP Import Runner"
{
    TableNo = "LT AG XP Job";

    trigger OnRun()
    var
        InS: InStream;
    begin
        Rec.CalcFields(Content);
        Rec.Content.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Rec.Id, InS);
    end;
}

codeunit 78402 "LT AG XP Import"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Rows(): Text
    var
        Row: Record "LT AG XP Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row.Name + ':' + Format(Row.Active) + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure Seed()
    var
        Row: Record "LT AG XP Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'seed-one';
        Row.Active := true;
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'seed-two';
        Row.Active := false;
        Row.Insert();
    end;

    local procedure RunImport(XmlportId: Integer; Content: Text): Boolean
    var
        Job: Record "LT AG XP Job" temporary;
        OutS: OutStream;
    begin
        Job.Id := XmlportId;
        Job.Insert();
        Job.Content.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        Job.Modify();
        Commit();
        exit(Codeunit.Run(Codeunit::"LT AG XP Import Runner", Job));
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

    local procedure ObserveImport(Name: Text; XmlportId: Integer; Content: Text)
    begin
        Seed();
        Observer.Observe(Name + ' ok', Format(RunImport(XmlportId, Content)));
        if GetLastErrorText() <> '' then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe(Name + ' rows', Rows());
    end;

    [Test]
    procedure FieldAttribute_Occurrence_RequiredAndOptional_Import()
    begin
        ObserveImport('all present', Xmlport::"LT AG XP Attr Occurrence", '<Root><Row Id="10" Name="ten" Active="1"/></Root>');
        ObserveImport('optional missing', Xmlport::"LT AG XP Attr Occurrence", '<Root><Row Id="10" Active="1"/></Root>');
        ObserveImport('required Id missing', Xmlport::"LT AG XP Attr Occurrence", '<Root><Row Name="ten" Active="1"/></Root>');
        ObserveImport('required Active missing', Xmlport::"LT AG XP Attr Occurrence", '<Root><Row Id="10" Name="ten"/></Root>');
        ObserveImport('all missing', Xmlport::"LT AG XP Attr Occurrence", '<Root><Row/></Root>');
        ObserveImport('no row element', Xmlport::"LT AG XP Attr Occurrence", '<Root/>');
        Observer.Expect('all present ok', 'Yes');
        Observer.Expect('all present rows', '1:seed-one:Yes,2:seed-two:No,10:ten:Yes,');
        Observer.Expect('optional missing ok', 'Yes');
        Observer.Expect('optional missing rows', '1:seed-one:Yes,2:seed-two:No,10::Yes,');
        Observer.Expect('required Id missing ok', 'No');
        Observer.Expect('required Id missing error', 'Imported XML cannot validate with the schema: The required attribute ''Id'' is missing.');
        Observer.Expect('required Id missing code', 'XmlPortInvalidXml');
        Observer.Expect('required Id missing rows', '1:seed-one:Yes,2:seed-two:No,');
        Observer.Expect('required Active missing ok', 'No');
        Observer.Expect('required Active missing error', 'Imported XML cannot validate with the schema: The required attribute ''Active'' is missing.');
        Observer.Expect('required Active missing code', 'XmlPortInvalidXml');
        Observer.Expect('required Active missing rows', '1:seed-one:Yes,2:seed-two:No,');
        Observer.Expect('all missing ok', 'No');
        Observer.Expect('all missing error', 'Imported XML cannot validate with the schema: The required attribute ''Id'' is missing.');
        Observer.Expect('all missing code', 'XmlPortInvalidXml');
        Observer.Expect('all missing rows', '1:seed-one:Yes,2:seed-two:No,');
        Observer.Expect('no row element ok', 'No');
        Observer.Expect('no row element error', 'Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Row''.');
        Observer.Expect('no row element code', 'XmlPortInvalidXml');
        Observer.Expect('no row element rows', '1:seed-one:Yes,2:seed-two:No,');
        Observer.Verify();
    end;

    [Test]
    procedure TableElement_MinOccursZero_Import()
    begin
        ObserveImport('no row element', Xmlport::"LT AG XP Elem MinOccurs Import", '<Root/>');
        ObserveImport('one row', Xmlport::"LT AG XP Elem MinOccurs Import", '<Root><Row><Id>10</Id><Name>ten</Name></Row></Root>');
        Observer.Expect('no row element ok', 'Yes');
        Observer.Expect('no row element rows', '1:seed-one:Yes,2:seed-two:No,');
        Observer.Expect('one row ok', 'Yes');
        Observer.Expect('one row rows', '1:seed-one:Yes,2:seed-two:No,10:ten:No,');
        Observer.Verify();
    end;

    [Test]
    procedure TableElement_SourceTableView_Import()
    begin
        ObserveImport('active and inactive', Xmlport::"LT AG XP Source Table View", '<Root><Row><Id>3</Id><Name>three</Name><Active>1</Active></Row><Row><Id>4</Id><Name>four</Name><Active>0</Active></Row></Root>');
        ObserveImport('replace seeded row', Xmlport::"LT AG XP Source Table View", '<Root><Row><Id>1</Id><Name>again</Name><Active>1</Active></Row></Root>');
        Observer.Expect('active and inactive ok', 'Yes');
        Observer.Expect('active and inactive rows', '1:seed-one:Yes,2:seed-two:No,3:three:Yes,4:four:No,');
        Observer.Expect('replace seeded row ok', 'No');
        Observer.Expect('replace seeded row error', 'The record in table LT AG XP Row already exists. Identification fields and values: Id=''1''');
        Observer.Expect('replace seeded row code', 'DB:RecordExists');
        Observer.Expect('replace seeded row rows', '1:seed-one:Yes,2:seed-two:No,');
        Observer.Verify();
    end;

    [Test]
    procedure TableElement_SourceTableView_Export()
    begin
        Seed();
        Observer.Observe('export', ExportText(Xmlport::"LT AG XP Source Table View"));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Name>seed-one</Name>|    <Active>Yes</Active>|  </Row>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure RequestPage_EmptySection_ImportAndExport()
    begin
        ObserveImport('empty requestpage import', Xmlport::"LT AG XP Empty Request Page", '<Root><Row><Id>10</Id><Name>ten</Name></Row></Root>');
        ObserveImport('no requestpage import', Xmlport::"LT AG XP No Request Page", '<Root><Row><Id>10</Id><Name>ten</Name></Row></Root>');
        Seed();
        Observer.Observe('empty requestpage export', ExportText(Xmlport::"LT AG XP Empty Request Page"));
        Observer.Observe('no requestpage export', ExportText(Xmlport::"LT AG XP No Request Page"));
        Observer.Expect('empty requestpage import ok', 'Yes');
        Observer.Expect('empty requestpage import rows', '1:seed-one:Yes,2:seed-two:No,10:ten:No,');
        Observer.Expect('no requestpage import ok', 'Yes');
        Observer.Expect('no requestpage import rows', '1:seed-one:Yes,2:seed-two:No,10:ten:No,');
        Observer.Expect('empty requestpage export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Name>seed-one</Name>|  </Row>|  <Row>|    <Id>2</Id>|    <Name>seed-two</Name>|  </Row>|</Root>|');
        Observer.Expect('no requestpage export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Name>seed-one</Name>|  </Row>|  <Row>|    <Id>2</Id>|    <Name>seed-two</Name>|  </Row>|</Root>|');
        Observer.Verify();
    end;
    // ---- Writer QX (DemoTool items 1, 2, 3, 6): objects 87560-87570 below ----

    local procedure QxRunInstanceImport(XmlportId: Integer; Content: Text): Boolean
    var
        Job: Record "LT AG XP Job" temporary;
        OutS: OutStream;
    begin
        Job.Id := XmlportId;
        Job.Insert();
        Job.Content.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        Job.Modify();
        Commit();
        exit(Codeunit.Run(Codeunit::"LT QX XP Instance Runner", Job));
    end;

    local procedure QxOutcome(Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name + ' ok', Format(Ok));
        if GetLastErrorText() <> '' then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
    end;

    local procedure QxObserveStaticImport(Name: Text; XmlportId: Integer; Content: Text)
    begin
        Seed();
        QxOutcome(Name, RunImport(XmlportId, Content));
        Observer.Observe(Name + ' rows', Rows());
    end;

    local procedure QxObserveInstanceImport(Name: Text; XmlportId: Integer; Content: Text)
    begin
        Seed();
        QxOutcome(Name, QxRunInstanceImport(XmlportId, Content));
        Observer.Observe(Name + ' rows', Rows());
    end;

    [TryFunction]
    local procedure QxTryExportInstance(XmlportId: Integer; var Result: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        RpLayoutActions: XmlPort "LT QX XP RP Layout Actions";
        RpLayoutOnly: XmlPort "LT QX XP RP Layout Only";
        RpActionsOnly: XmlPort "LT QX XP RP Actions Only";
        RootTable: XmlPort "LT QX XP Root Table";
        RootTablePlain: XmlPort "LT QX XP Root Table Plain";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Enc: TextEncoding;
    begin
        Result := '';
        TempBlob.CreateOutStream(OutS);
        Enc := TextEncoding::UTF16;
        case XmlportId of
            Xmlport::"LT QX XP RP Layout Actions":
                begin
                    RpLayoutActions.SetDestination(OutS);
                    RpLayoutActions.Export();
                end;
            Xmlport::"LT QX XP RP Layout Only":
                begin
                    RpLayoutOnly.SetDestination(OutS);
                    RpLayoutOnly.Export();
                end;
            Xmlport::"LT QX XP RP Actions Only":
                begin
                    RpActionsOnly.SetDestination(OutS);
                    RpActionsOnly.Export();
                end;
            Xmlport::"LT QX XP Root Table":
                begin
                    RootTable.SetDestination(OutS);
                    RootTable.Export();
                    Enc := TextEncoding::UTF8;
                end;
            Xmlport::"LT QX XP Root Table Plain":
                begin
                    RootTablePlain.SetDestination(OutS);
                    RootTablePlain.Export();
                end;
        end;
        TempBlob.CreateInStream(InS, Enc);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
    end;

    local procedure QxObserveExport(Name: Text; XmlportId: Integer)
    var
        Result: Text;
    begin
        QxOutcome(Name, QxTryExportInstance(XmlportId, Result));
        Observer.Observe(Name + ' text', Result);
    end;

    local procedure QxSetupRows(): Text
    var
        Setup: Record "LT QX XP Setup";
        Result: Text;
    begin
        if Setup.FindSet() then
            repeat
                Result += '[' + Setup."Primary Key" + '|' + Format(Setup."Starting Year") + '|' + Format(Setup."Working Date", 0, 9) + '|' +
                    Format(Setup."Company Type") + '|' + Format(Setup."Advanced Setup") + '|' + Setup."Currency Code" + '|' +
                    Setup."Additional Currency" + '|' + Format(Setup."Data Type") + ']';
            until Setup.Next() = 0;
        exit(Result);
    end;

    local procedure QxSetupXml(RootName: Text; Year: Text): Text
    begin
        exit('<' + RootName + '><StartingYear>' + Year + '</StartingYear><CompanyType>VAT</CompanyType><AdvancedSetup>FALSE</AdvancedSetup>' +
            '<CurrencyCode>GBP</CurrencyCode><AdditionalCurrency/><DataType>Extended</DataType></' + RootName + '>');
    end;

    local procedure QxObserveSetupImport(Name: Text; XmlportId: Integer; Content: Text; Static: Boolean)
    begin
        if Static then
            QxOutcome(Name, RunImport(XmlportId, Content))
        else
            QxOutcome(Name, QxRunInstanceImport(XmlportId, Content));
        Observer.Observe(Name + ' rows', QxSetupRows());
    end;

    local procedure QxClearSetup()
    var
        Setup: Record "LT QX XP Setup";
    begin
        Setup.DeleteAll();
        Commit();
    end;

    // Item 1: a request page with empty layout and actions sections (layout { } actions { }), layout { } alone and actions { } alone,
    // imported and exported from code, with Xmlport.Import/Export and with SetSource/Import, SetDestination/Export on a variable.
    [Test]
    procedure QX_RequestPage_EmptyLayoutAndActions_ImportAndExport()
    begin
        QxObserveStaticImport('layout+actions static', Xmlport::"LT QX XP RP Layout Actions", '<Root><Row><Id>10</Id><Name>ten</Name></Row></Root>');
        QxObserveInstanceImport('layout+actions instance', Xmlport::"LT QX XP RP Layout Actions", '<Root><Row><Id>11</Id><Name>eleven</Name></Row></Root>');
        QxObserveStaticImport('layout static', Xmlport::"LT QX XP RP Layout Only", '<Root><Row><Id>12</Id><Name>twelve</Name></Row></Root>');
        QxObserveInstanceImport('layout instance', Xmlport::"LT QX XP RP Layout Only", '<Root><Row><Id>13</Id><Name>thirteen</Name></Row></Root>');
        QxObserveStaticImport('actions static', Xmlport::"LT QX XP RP Actions Only", '<Root><Row><Id>14</Id><Name>fourteen</Name></Row></Root>');
        QxObserveInstanceImport('actions instance', Xmlport::"LT QX XP RP Actions Only", '<Root><Row><Id>15</Id><Name>fifteen</Name></Row></Root>');
        Seed();
        Observer.Observe('layout+actions export static', ExportText(Xmlport::"LT QX XP RP Layout Actions"));
        QxObserveExport('layout+actions export instance', Xmlport::"LT QX XP RP Layout Actions");
        QxObserveExport('layout export instance', Xmlport::"LT QX XP RP Layout Only");
        QxObserveExport('actions export instance', Xmlport::"LT QX XP RP Actions Only");
        Observer.Expect('layout+actions static ok', 'Yes');
        Observer.Expect('layout+actions static rows', '1:seed-one:Yes,2:seed-two:No,10:ten:No,');
        Observer.Expect('layout+actions instance ok', 'Yes');
        Observer.Expect('layout+actions instance rows', '1:seed-one:Yes,2:seed-two:No,11:eleven:No,');
        Observer.Expect('layout static ok', 'Yes');
        Observer.Expect('layout static rows', '1:seed-one:Yes,2:seed-two:No,12:twelve:No,');
        Observer.Expect('layout instance ok', 'Yes');
        Observer.Expect('layout instance rows', '1:seed-one:Yes,2:seed-two:No,13:thirteen:No,');
        Observer.Expect('actions static ok', 'Yes');
        Observer.Expect('actions static rows', '1:seed-one:Yes,2:seed-two:No,14:fourteen:No,');
        Observer.Expect('actions instance ok', 'Yes');
        Observer.Expect('actions instance rows', '1:seed-one:Yes,2:seed-two:No,15:fifteen:No,');
        Observer.Expect('layout+actions export static', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Name>seed-one</Name>|  </Row>|  <Row>|    <Id>2</Id>|    <Name>seed-two</Name>|  </Row>|</Root>|');
        Observer.Expect('layout+actions export instance ok', 'Yes');
        Observer.Expect('layout+actions export instance text', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Name>seed-one</Name>|  </Row>|  <Row>|    <Id>2</Id>|    <Name>seed-two</Name>|  </Row>|</Root>|');
        Observer.Expect('layout export instance ok', 'Yes');
        Observer.Expect('layout export instance text', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Name>seed-one</Name>|  </Row>|  <Row>|    <Id>2</Id>|    <Name>seed-two</Name>|  </Row>|</Root>|');
        Observer.Expect('actions export instance ok', 'Yes');
        Observer.Expect('actions export instance text', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Name>seed-one</Name>|  </Row>|  <Row>|    <Id>2</Id>|    <Name>seed-two</Name>|  </Row>|</Root>|');
        Observer.Verify();
    end;

    // Item 2: Format = Xml with a table element as the schema root (XmlName differs from the table name), on import: one element, the same
    // element again (the row is there), another root name, two root elements, an empty root element; field validation on import.
    [Test]
    procedure QX_RootTableElement_Import()
    begin
        QxClearSetup();
        QxObserveSetupImport('one element instance', Xmlport::"LT QX XP Root Table", '<?xml version="1.0" encoding="UTF-8" standalone="no"?>' + QxSetupXml('QxSetup', '2008'), false);
        QxObserveSetupImport('again with the row there', Xmlport::"LT QX XP Root Table", QxSetupXml('QxSetup', '2009'), false);
        QxClearSetup();
        QxObserveSetupImport('one element static', Xmlport::"LT QX XP Root Table", QxSetupXml('QxSetup', '2010'), true);
        QxClearSetup();
        QxObserveSetupImport('other root name', Xmlport::"LT QX XP Root Table", QxSetupXml('Other', '2011'), false);
        QxClearSetup();
        QxObserveSetupImport('two root elements', Xmlport::"LT QX XP Root Table", QxSetupXml('QxSetup', '2012') + QxSetupXml('QxSetup', '2013'), false);
        QxClearSetup();
        QxObserveSetupImport('empty root element', Xmlport::"LT QX XP Root Table", '<QxSetup/>', false);
        QxClearSetup();
        QxObserveSetupImport('plain one element', Xmlport::"LT QX XP Root Table Plain", QxSetupXml('QxSetup', '2014'), false);
        QxClearSetup();
        Observer.Expect('one element instance ok', 'Yes');
        Observer.Expect('one element instance rows', '[|2008|2008-01-01|VAT|No|GBP||Extended]');
        Observer.Expect('again with the row there ok', 'No');
        Observer.Expect('again with the row there error', 'The record in table LT QX XP Setup already exists. Identification fields and values: Primary Key=''''');
        Observer.Expect('again with the row there code', 'DB:RecordExists');
        Observer.Expect('again with the row there rows', '[|2008|2008-01-01|VAT|No|GBP||Extended]');
        Observer.Expect('one element static ok', 'Yes');
        Observer.Expect('one element static rows', '[|2010|2010-01-01|VAT|No|GBP||Extended]');
        Observer.Expect('other root name ok', 'No');
        Observer.Expect('other root name error', 'Imported XML cannot validate with the schema: The ''Other'' element is not declared.');
        Observer.Expect('other root name code', 'XmlPortInvalidXml');
        Observer.Expect('other root name rows', '');
        Observer.Expect('two root elements ok', 'No');
        Observer.Expect('two root elements error', 'There are multiple root elements. Line 1, position 202.');
        Observer.Expect('two root elements code', 'XmlPortImport:Xml');
        Observer.Expect('two root elements rows', '');
        Observer.Expect('empty root element ok', 'No');
        Observer.Expect('empty root element error', 'Imported XML cannot validate with the schema: The element ''QxSetup'' has incomplete content. List of possible elements expected: ''StartingYear''.');
        Observer.Expect('empty root element code', 'XmlPortInvalidXml');
        Observer.Expect('empty root element rows', '');
        Observer.Expect('plain one element ok', 'Yes');
        Observer.Expect('plain one element rows', '[|2014|2014-01-01|VAT|No|GBP||Extended]');
        Observer.Verify();
    end;

    // Item 2, export: the same ports with no row, one row and two rows.
    [Test]
    procedure QX_RootTableElement_Export()
    var
        Setup: Record "LT QX XP Setup";
    begin
        QxClearSetup();
        QxObserveExport('no row', Xmlport::"LT QX XP Root Table");
        Setup."Primary Key" := '';
        Setup."Starting Year" := 2008;
        Setup."Working Date" := DMY2Date(1, 1, 2008);
        Setup."Company Type" := Setup."Company Type"::VAT;
        Setup."Currency Code" := 'GBP';
        Setup."Data Type" := Setup."Data Type"::Extended;
        Setup.Insert();
        QxObserveExport('one row', Xmlport::"LT QX XP Root Table");
        QxObserveExport('one row plain', Xmlport::"LT QX XP Root Table Plain");
        QxClearSetup();
        Observer.Expect('no row ok', 'Yes');
        Observer.Expect('no row text', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<QxSetup>|  <StartingYear>0</StartingYear>|  <CompanyType>VAT</CompanyType>|  <AdvancedSetup>No</AdvancedSetup>|  <CurrencyCode />|  <AdditionalCurrency />|  <DataType>Standard</DataType>|</QxSetup>|');
        Observer.Expect('one row ok', 'Yes');
        Observer.Expect('one row text', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<QxSetup>|  <StartingYear>2008</StartingYear>|  <CompanyType>VAT</CompanyType>|  <AdvancedSetup>No</AdvancedSetup>|  <CurrencyCode>GBP</CurrencyCode>|  <AdditionalCurrency />|  <DataType>Extended</DataType>|</QxSetup>|');
        Observer.Expect('one row plain ok', 'Yes');
        Observer.Expect('one row plain text', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<QxSetup>|  <StartingYear>2008</StartingYear>|  <CompanyType>VAT</CompanyType>|  <AdvancedSetup>No</AdvancedSetup>|  <CurrencyCode>GBP</CurrencyCode>|  <AdditionalCurrency />|  <DataType>Extended</DataType>|</QxSetup>|');
        Observer.Verify();
    end;

    // Item 2, export of two rows: the port writes one root element per row (the document has two roots).
    [Test]
    procedure QX_RootTableElement_Export_TwoRows()
    var
        Setup: Record "LT QX XP Setup";
    begin
        QxClearSetup();
        Setup."Starting Year" := 2008;
        Setup."Working Date" := DMY2Date(1, 1, 2008);
        Setup."Company Type" := Setup."Company Type"::VAT;
        Setup."Currency Code" := 'GBP';
        Setup."Data Type" := Setup."Data Type"::Extended;
        Setup.Insert();
        Setup."Primary Key" := 'B';
        Setup.Insert();
        QxObserveExport('two rows', Xmlport::"LT QX XP Root Table");
        QxObserveExport('two rows plain', Xmlport::"LT QX XP Root Table Plain");
        QxClearSetup();
        Observer.Expect('two rows ok', 'Yes');
        Observer.Expect('two rows text', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<QxSetup>|  <StartingYear>2008</StartingYear>|  <CompanyType>VAT</CompanyType>|  <AdvancedSetup>No</AdvancedSetup>|  <CurrencyCode>GBP</CurrencyCode>|  <AdditionalCurrency />|  <DataType>Extended</DataType>|</QxSetup>|<QxSetup>|  <StartingYear>2008</StartingYear>|  <CompanyType>VAT</CompanyType>|  <AdvancedSetup>No</AdvancedSetup>|  <CurrencyCode>GBP</CurrencyCode>|  <AdditionalCurrency />|  <DataType>Extended</DataType>|</QxSetup>|');
        Observer.Expect('two rows plain ok', 'Yes');
        Observer.Expect('two rows plain text', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<QxSetup>|  <StartingYear>2008</StartingYear>|  <CompanyType>VAT</CompanyType>|  <AdvancedSetup>No</AdvancedSetup>|  <CurrencyCode>GBP</CurrencyCode>|  <AdditionalCurrency />|  <DataType>Extended</DataType>|</QxSetup>|<QxSetup>|  <StartingYear>2008</StartingYear>|  <CompanyType>VAT</CompanyType>|  <AdvancedSetup>No</AdvancedSetup>|  <CurrencyCode>GBP</CurrencyCode>|  <AdditionalCurrency />|  <DataType>Extended</DataType>|</QxSetup>|');
        Observer.Verify();
    end;

    // Item 3, in an import: a field element whose field has TableRelation = "Windows Language" where("Globally Enabled" = const(true),
    // "STX File Exist" = const(true)), imported with 1033, 1031 and an id no culture uses.
    [Test]
    procedure QX_RootTableElement_WindowsLanguageRelation_Import()
    var
        LangSetup: Record "LT QX XP Lang Setup";
    begin
        LangSetup.DeleteAll();
        Commit();
        QxOutcome('1033', QxRunInstanceImport(Xmlport::"LT QX XP Lang Setup", '<QxLangSetup><DataLanguageID>1033</DataLanguageID></QxLangSetup>'));
        Observer.Observe('1033 rows', QxLangRows());
        LangSetup.DeleteAll();
        Commit();
        QxOutcome('1031', QxRunInstanceImport(Xmlport::"LT QX XP Lang Setup", '<QxLangSetup><DataLanguageID>1031</DataLanguageID></QxLangSetup>'));
        Observer.Observe('1031 rows', QxLangRows());
        LangSetup.DeleteAll();
        Commit();
        QxOutcome('999999', QxRunInstanceImport(Xmlport::"LT QX XP Lang Setup", '<QxLangSetup><DataLanguageID>999999</DataLanguageID></QxLangSetup>'));
        Observer.Observe('999999 rows', QxLangRows());
        LangSetup.DeleteAll();
        Commit();
        Observer.Expect('1033 ok', 'Yes');
        Observer.Expect('1033 rows', '[|1033|English (United States)]');
        Observer.Expect('1031 ok', 'Yes');
        Observer.Expect('1031 rows', '[|1031|German (Germany)]');
        Observer.Expect('999999 ok', 'No');
        Observer.Expect('999999 error', 'The field Data Language ID of table LT QX XP Lang Setup contains a value (999999) that cannot be found in the related table (Windows Language).');
        Observer.Expect('999999 code', 'DB:NothingInsideFilter');
        Observer.Expect('999999 rows', '');
        Observer.Verify();
    end;

    local procedure QxLangRows(): Text
    var
        LangSetup: Record "LT QX XP Lang Setup";
        Result: Text;
    begin
        if LangSetup.FindSet() then
            repeat
                Result += '[' + LangSetup."Primary Key" + '|' + Format(LangSetup."Data Language ID") + '|' + LangSetup."Validated Name" + ']';
            until LangSetup.Next() = 0;
        exit(Result);
    end;

    local procedure QxCurrencyRows(): Text
    var
        Cur: Record "LT QX XP Currency";
        Result: Text;
    begin
        if Cur.FindSet() then
            repeat
                Result += '[' + Cur.Code + '|' + Cur.Iso + '|' + Format(Cur.LocPrec, 0, 9) + '|' + Format(Cur.AmtRnd, 0, 9) + '|' + Format(Cur.RndType) + '|' +
                    Format(Cur.XRate) + '|' + Format(Cur.Emu) + '|' + Cur.DecPl + '|' + Format(Cur.Validated) + ']';
            until Cur.Next() = 0;
        exit(Result);
    end;

    local procedure QxObserveCurrencyImport(Name: Text; Content: Text)
    var
        Cur: Record "LT QX XP Currency";
    begin
        Cur.DeleteAll();
        Commit();
        QxOutcome(Name, QxRunInstanceImport(Xmlport::"LT QX XP Currency", Content));
        Observer.Observe(Name + ' rows', QxCurrencyRows());
    end;

    // Item 6: Format = VariableText, DefaultFieldsValidation = false, FieldSeparator ';', FieldDelimiter '<None>': text elements with
    // MinOccurs = Zero whose OnAfterAssignVariable does Evaluate(Decimal field, text, 9), field elements with MinOccurs = Zero; a line with
    // every column, a line that ends early, empty columns, a comma decimal, a CR LF line end, a last line without a line end.
    [Test]
    procedure QX_VariableText_TextElementEvaluateAndShortLines()
    var
        Cr: Char;
        Lf: Text;
        CrLf: Text;
    begin
        Cr := 10;
        Lf += Cr;
        Cr := 13;
        CrLf += Cr;
        CrLf += Lf;
        QxObserveCurrencyImport('full and short', 'AED;784;0.25;0.01;0;100;0;02:02' + Lf + 'AUD;036;1;0.01' + Lf + 'BGN;975' + Lf);
        QxObserveCurrencyImport('no last line end', 'AED;784;0.25;0.01;2;100;1;02:05');
        QxObserveCurrencyImport('crlf', 'AED;784;0.25;0.01;0;100;0;02:02' + CrLf + 'AUD;036;1;0.01' + CrLf);
        QxObserveCurrencyImport('empty text column', 'AED;784;;0.01;0;100;0;02:02' + Lf);
        QxObserveCurrencyImport('comma decimal', 'AED;784;0,25;0.01;0;100;0;02:02' + Lf);
        QxObserveCurrencyImport('option by name', 'AED;784;0.25;0.01;Up;100;No;02:02' + Lf);
        QxObserveCurrencyImport('too many columns', 'AED;784;0.25;0.01;0;100;0;02:02;extra' + Lf);
        QxObserveCurrencyImport('empty line between', 'AED;784;0.25;0.01;0;100;0;02:02' + Lf + Lf + 'AUD;036;1;0.01' + Lf);
        Observer.Ignore('full and short ok');
        Observer.Ignore('full and short error');
        Observer.Ignore('full and short code');
        Observer.Ignore('full and short rows');
        Observer.Expect('no last line end ok', 'Yes');
        Observer.Expect('no last line end rows', '[AED|784|0.25|0.01|Down|100|Yes|02:05|No]');
        Observer.Expect('crlf ok', 'Yes');
        Observer.Expect('crlf rows', '[AED|784|0.25|0.01|Nearest|100|No|02:02|No][AUD|036|1|0.01|Nearest|0|No||No]');
        Observer.Expect('empty text column ok', 'No');
        Observer.Expect('empty text column error', 'The value "" can''t be evaluated into type Decimal.');
        Observer.Expect('empty text column code', 'Evaluate');
        Observer.Expect('empty text column rows', '');
        Observer.Expect('comma decimal ok', 'No');
        Observer.Expect('comma decimal error', 'The value "0,25" can''t be evaluated into type Decimal.');
        Observer.Expect('comma decimal code', 'Evaluate');
        Observer.Expect('comma decimal rows', '');
        Observer.Expect('option by name ok', 'Yes');
        Observer.Expect('option by name rows', '[AED|784|0.25|0.01|Up|100|No|02:02|No]');
        Observer.Expect('too many columns ok', 'Yes');
        Observer.Expect('too many columns rows', '[AED|784|0.25|0.01|Nearest|100|No|02:02|No]');
        Observer.Ignore('empty line between ok');
        Observer.Ignore('empty line between error');
        Observer.Ignore('empty line between code');
        Observer.Ignore('empty line between rows');
        Observer.Verify();
    end;
}

// ---- Writer QX objects (DemoTool items 1, 2, 3, 6; test procedures QX_* in codeunit 78402 above) ----

table 87560 "LT QX XP Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Starting Year"; Integer)
        {
            trigger OnValidate()
            begin
                "Working Date" := DMY2Date(1, 1, "Starting Year");
            end;
        }
        field(3; "Working Date"; Date) { }
        field(4; "Company Type"; Option) { OptionMembers = VAT,"Sales Tax"; }
        field(5; "Advanced Setup"; Boolean) { }
        field(6; "Currency Code"; Code[10]) { }
        field(7; "Additional Currency"; Code[10]) { }
        field(8; "Data Type"; Option) { OptionMembers = Standard,Evaluation,Extended; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

table 87561 "LT QX XP Currency"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Iso; Code[3])
        {
            trigger OnValidate()
            begin
                Validated := true;
            end;
        }
        field(3; LocPrec; Decimal) { }
        field(4; AmtRnd; Decimal) { }
        field(5; RndType; Option) { OptionMembers = Nearest,Up,Down; }
        field(6; XRate; Integer) { }
        field(7; Emu; Boolean) { }
        field(8; DecPl; Text[5]) { }
        field(9; Validated; Boolean) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

xmlport 87562 "LT QX XP Root Table"
{
    Encoding = UTF8;
    Format = Xml;

    schema
    {
        tableelement(Setup; "LT QX XP Setup")
        {
            XmlName = 'QxSetup';
            fieldelement(StartingYear; Setup."Starting Year") { }
            fieldelement(CompanyType; Setup."Company Type") { }
            fieldelement(AdvancedSetup; Setup."Advanced Setup") { }
            fieldelement(CurrencyCode; Setup."Currency Code") { }
            fieldelement(AdditionalCurrency; Setup."Additional Currency") { }
            fieldelement(DataType; Setup."Data Type") { }
        }
    }

    requestpage
    {
        layout
        {
        }

        actions
        {
        }
    }
}

xmlport 87563 "LT QX XP Root Table Plain"
{
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        tableelement(Setup; "LT QX XP Setup")
        {
            XmlName = 'QxSetup';
            fieldelement(StartingYear; Setup."Starting Year") { }
            fieldelement(CompanyType; Setup."Company Type") { }
            fieldelement(AdvancedSetup; Setup."Advanced Setup") { }
            fieldelement(CurrencyCode; Setup."Currency Code") { }
            fieldelement(AdditionalCurrency; Setup."Additional Currency") { }
            fieldelement(DataType; Setup."Data Type") { }
        }
    }
}

xmlport 87564 "LT QX XP RP Layout Actions"
{
    Direction = Both;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }

    requestpage
    {
        layout
        {
        }

        actions
        {
        }
    }
}

xmlport 87565 "LT QX XP RP Layout Only"
{
    Direction = Both;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }

    requestpage
    {
        layout
        {
        }
    }
}

xmlport 87566 "LT QX XP RP Actions Only"
{
    Direction = Both;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AG XP Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }

    requestpage
    {
        actions
        {
        }
    }
}

xmlport 87567 "LT QX XP Currency"
{
    DefaultFieldsValidation = false;
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = ';';
    Format = VariableText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Cur; "LT QX XP Currency")
            {
                XmlName = 'QxCurrency';
                fieldelement(cc; Cur.Code) { }
                fieldelement(IsoCode; Cur.Iso) { }
                textelement(locprec)
                {
                    MinOccurs = Zero;
                    XmlName = 'LocPrec';

                    trigger OnAfterAssignVariable()
                    begin
                        Evaluate(Cur.LocPrec, locprec, 9);
                    end;
                }
                textelement(amtrnd)
                {
                    MinOccurs = Zero;
                    XmlName = 'AmtRnd';

                    trigger OnAfterAssignVariable()
                    begin
                        Evaluate(Cur.AmtRnd, amtrnd, 9);
                    end;
                }
                fieldelement(RndType; Cur.RndType) { MinOccurs = Zero; }
                fieldelement(XRate; Cur.XRate) { MinOccurs = Zero; }
                fieldelement(Emu; Cur.Emu) { MinOccurs = Zero; }
                fieldelement(DecPl; Cur.DecPl) { MinOccurs = Zero; }
            }
        }
    }

    requestpage
    {
        layout
        {
        }

        actions
        {
        }
    }
}

table 87570 "LT QX XP Lang Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Data Language ID"; Integer)
        {
            TableRelation = "Windows Language" where("Globally Enabled" = const(true), "STX File Exist" = const(true));

            trigger OnValidate()
            var
                WindowsLanguage: Record "Windows Language";
            begin
                WindowsLanguage.Get("Data Language ID");
                "Validated Name" := CopyStr(WindowsLanguage.Name, 1, MaxStrLen("Validated Name"));
            end;
        }
        field(3; "Validated Name"; Text[80]) { }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

xmlport 87568 "LT QX XP Lang Setup"
{
    Encoding = UTF8;
    Format = Xml;

    schema
    {
        tableelement(LangSetup; "LT QX XP Lang Setup")
        {
            XmlName = 'QxLangSetup';
            fieldelement(DataLanguageID; LangSetup."Data Language ID") { }
        }
    }

    requestpage
    {
        layout
        {
        }

        actions
        {
        }
    }
}

// Runs an import on an XmlPort variable (SetSource, then Import), as Microsoft's DemoTool does; Codeunit.Run keeps a failed import's writes out.
codeunit 87569 "LT QX XP Instance Runner"
{
    TableNo = "LT AG XP Job";

    trigger OnRun()
    var
        RpLayoutActions: XmlPort "LT QX XP RP Layout Actions";
        RpLayoutOnly: XmlPort "LT QX XP RP Layout Only";
        RpActionsOnly: XmlPort "LT QX XP RP Actions Only";
        RootTable: XmlPort "LT QX XP Root Table";
        RootTablePlain: XmlPort "LT QX XP Root Table Plain";
        Currency: XmlPort "LT QX XP Currency";
        LangSetup: XmlPort "LT QX XP Lang Setup";
        InS: InStream;
    begin
        Rec.CalcFields(Content);
        Rec.Content.CreateInStream(InS, TextEncoding::UTF8);
        case Rec.Id of
            Xmlport::"LT QX XP RP Layout Actions":
                begin
                    RpLayoutActions.SetSource(InS);
                    RpLayoutActions.Import();
                end;
            Xmlport::"LT QX XP RP Layout Only":
                begin
                    RpLayoutOnly.SetSource(InS);
                    RpLayoutOnly.Import();
                end;
            Xmlport::"LT QX XP RP Actions Only":
                begin
                    RpActionsOnly.SetSource(InS);
                    RpActionsOnly.Import();
                end;
            Xmlport::"LT QX XP Root Table":
                begin
                    RootTable.SetSource(InS);
                    RootTable.Import();
                end;
            Xmlport::"LT QX XP Root Table Plain":
                begin
                    RootTablePlain.SetSource(InS);
                    RootTablePlain.Import();
                end;
            Xmlport::"LT QX XP Currency":
                begin
                    Currency.SetSource(InS);
                    Currency.Import();
                end;
            Xmlport::"LT QX XP Lang Setup":
                begin
                    LangSetup.SetSource(InS);
                    LangSetup.Import();
                end;
        end;
    end;
}
