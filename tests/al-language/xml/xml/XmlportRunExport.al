// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (table 74307, xmlports 74308 and 74309, codeunits 74310 to 74312)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Xmlport.Run(Id, false, false) and Xmlport.Run(Id, false, false, Rec) of an export xmlport with no stream (does it run, which rows its tableelement visits, error text and code), the instance Run, Run after SetTableView, Run with the Import flag on an export-only xmlport, an import-only xmlport run as export, and an import run with no source
// Settles docs/probes-needed.md row "Xmlport.Run (static and instance)" (NP Retail blockers): where a run without a stream writes is not observable in a Cloud test; what is observed is whether the run succeeds, which rows the tableelement visits and the error otherwise
// BC versions: 29 (27 and 28 by CI)

table 74307 "LT P166 XP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74310 "LT P166 XP Log"
{
    SingleInstance = true;

    var
        Ids: Text;

    procedure Hit(Id: Integer)
    begin
        Ids += Format(Id) + ',';
    end;

    procedure Hits(): Text
    begin
        exit(Ids);
    end;

    procedure Reset()
    begin
        Ids := '';
    end;
}

xmlport 74308 "LT P166 XP Export"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT P166 XP Row")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }

                trigger OnAfterGetRecord()
                var
                    Log: Codeunit "LT P166 XP Log";
                begin
                    Log.Hit(T.Id);
                end;
            }
        }
    }
}

xmlport 74309 "LT P166 XP Import"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT P166 XP Row")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }
            }
        }
    }
}

codeunit 74311 "LT P166 XP Run Import"
{
    trigger OnRun()
    begin
        Xmlport.Run(Xmlport::"LT P166 XP Import", false, true);
    end;
}

codeunit 74312 "LT P166 XP Export As Import"
{
    trigger OnRun()
    begin
        Xmlport.Run(Xmlport::"LT P166 XP Export", false, true);
    end;
}

codeunit 74313 "LT P166 Xmlport Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P166 XP Log";

    local procedure Seed()
    var
        Row: Record "LT P166 XP Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Txt := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Txt := 'two';
        Row.Insert();
        Row.Id := 3;
        Row.Txt := 'three';
        Row.Insert();
        Log.Reset();
    end;

    [TryFunction]
    local procedure TryStatic()
    begin
        Xmlport.Run(Xmlport::"LT P166 XP Export", false, false);
    end;

    [TryFunction]
    local procedure TryStaticWithRecord(var Row: Record "LT P166 XP Row")
    begin
        Xmlport.Run(Xmlport::"LT P166 XP Export", false, false, Row);
    end;

    [TryFunction]
    local procedure TryInstance()
    var
        Xp: XmlPort "LT P166 XP Export";
    begin
        Xp.Run();
    end;

    [TryFunction]
    local procedure TryInstanceWithView(var Row: Record "LT P166 XP Row")
    var
        Xp: XmlPort "LT P166 XP Export";
    begin
        Xp.SetTableView(Row);
        Xp.Run();
    end;

    [Test]
    procedure Run_ExportXmlportAsImport()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P166 XP Row";
    begin
        Seed();
        Commit();
        Observer.Observe('ok', Format(Codeunit.Run(Codeunit::"LT P166 XP Export As Import")));
        Observer.ObserveError('run');
        Observer.Observe('rowsVisited', Log.Hits());
        Row.DeleteAll();
        Commit();
        Observer.Expect('ok', 'No');
        Observer.Expect('run|text', 'The XMLPort ''LT P166 XP Export'' is designed for export only.');
        Observer.Expect('run|code', 'XmlPortExportDirection');
        Observer.Expect('rowsVisited', '');
        Observer.Verify();
    end;

    [Test]
    procedure Run_ImportXmlportWithoutSource()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P166 XP Row";
        RunOk: Boolean;
    begin
        Seed();
        Commit();
        RunOk := Codeunit.Run(Codeunit::"LT P166 XP Run Import");
        Observer.Observe('ok', Format(RunOk));
        Observer.ObserveError('run');
        Observer.Observe('rowsAfter', Format(Row.Count()));
        Row.DeleteAll();
        Commit();
        // Windows: ok=No, NotSupportedFileDialogProvider (batch XP); fixed on Linux by bc-linux #141
        Observer.Expect('ok', 'No');
        Observer.Expect('run|text', 'The operation cannot complete because it uses a feature that is not supported (AL File function.)');
        Observer.Expect('run|code', 'NotSupportedFileDialogProvider:NotSupportedFileDialogProvider');
        Observer.Expect('rowsAfter', '3');
        Observer.Verify();
    end;
}
