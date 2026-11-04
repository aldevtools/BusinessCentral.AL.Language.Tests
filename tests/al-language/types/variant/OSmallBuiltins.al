// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 67220 (also used by the OnPrem app), codeunits 67221 and 67222
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: Variant.IsDataClassificationType and Variant.IsSecurityFiltering over many value kinds;
// Database.CopyCompany (errors for a missing source and an existing destination; a successful copy cannot run inside the test runner).
// BC versions: 27, 28, 29

table 67220 "LT O Blob Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67221 "LT O Small Builtins"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure VariantKinds(var Observer: Codeunit "Probe Observer"; Tag: Text; V: Variant)
    begin
        Observer.Observe(Tag + '|IsDataClassificationType', Format(V.IsDataClassificationType));
        Observer.Observe(Tag + '|IsSecurityFiltering', Format(V.IsSecurityFiltering));
    end;

    [Test]
    procedure O_Variant_IsDataClassificationType_IsSecurityFiltering()
    var
        Observer: Codeunit "Probe Observer";
        DC: DataClassification;
        SF: SecurityFilter;
        Int: Integer;
        Txt: Text;
        Bool: Boolean;
        Opt: Option A,B;
        Vb: Verbosity;
        Empty: Variant;
    begin
        DC := DataClassification::CustomerContent;
        VariantKinds(Observer, 'DataClassification', DC);
        SF := SecurityFilter::Filtered;
        VariantKinds(Observer, 'SecurityFilter', SF);
        VariantKinds(Observer, 'Integer', Int);
        VariantKinds(Observer, 'Text', Txt);
        VariantKinds(Observer, 'Boolean', Bool);
        VariantKinds(Observer, 'Option', Opt);
        VariantKinds(Observer, 'Verbosity', Vb);
        VariantKinds(Observer, 'empty variant', Empty);
        Observer.Expect('DataClassification|IsDataClassificationType', 'Yes');
        Observer.Expect('DataClassification|IsSecurityFiltering', 'No');
        Observer.Expect('SecurityFilter|IsDataClassificationType', 'No');
        Observer.Expect('SecurityFilter|IsSecurityFiltering', 'Yes');
        Observer.Expect('Integer|IsDataClassificationType', 'No');
        Observer.Expect('Integer|IsSecurityFiltering', 'No');
        Observer.Expect('Text|IsDataClassificationType', 'No');
        Observer.Expect('Text|IsSecurityFiltering', 'No');
        Observer.Expect('Boolean|IsDataClassificationType', 'No');
        Observer.Expect('Boolean|IsSecurityFiltering', 'No');
        Observer.Expect('Option|IsDataClassificationType', 'No');
        Observer.Expect('Option|IsSecurityFiltering', 'No');
        Observer.Expect('Verbosity|IsDataClassificationType', 'No');
        Observer.Expect('Verbosity|IsSecurityFiltering', 'No');
        Observer.Expect('empty variant|IsDataClassificationType', 'No');
        Observer.Expect('empty variant|IsSecurityFiltering', 'No');
        Observer.Verify();
    end;

    local procedure CopyIt(Source: Text; Destination: Text): Boolean
    var
        Runner: Codeunit "LT O Copy Runner";
    begin
        Runner.Setup(Source, Destination);
        exit(Runner.Run());
    end;

    // Only the two error arms of CopyCompany: a copy that succeeds cannot run inside the test runner (corpus issue 654). Copying the session
    // company also copies the runner's own row in table "Test Method Line", which the runner holds in its open transaction (Windows 27.5 and
    // 29.0 and Linux 27: "a record in table 'Test Method Line' is being updated in a transaction done by another session"); copying a company
    // the test creates hung the BC 29.0 session until the CI timeout (corpus CI run 39170558346).
    [Test]
    procedure O_Database_CopyCompany()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
    begin
        if CopyIt('LT O No Such Company', 'LT O Copy Target') then
            Observer.Observe('missing source', 'no error')
        else
            Observer.ObserveError('missing source');
        Observer.Observe('missing source|destination exists', Format(Company.Get('LT O Copy Target')));
        if CopyIt(CompanyName(), CompanyName()) then
            Observer.Observe('existing destination', 'no error')
        else
            Observer.ObserveError('existing destination');
        Observer.Expect('missing source|text', 'The Company does not exist. Identification fields and values: Name=''LT O No Such Company''');
        Observer.Expect('missing source|code', 'DB:RecordNotFound');
        Observer.Expect('missing source|destination exists', 'No');
        Observer.Expect('existing destination|text', 'The record in table Company already exists. Identification fields and values: Name=''<Company>''');
        Observer.Expect('existing destination|code', 'DB:RecordExists');
        Observer.Verify();
    end;
}

codeunit 67222 "LT O Copy Runner"
{
    var
        SourceName: Text;
        DestinationName: Text;

    procedure Setup(Source: Text; Destination: Text)
    begin
        SourceName := Source;
        DestinationName := Destination;
    end;

    trigger OnRun()
    begin
        Database.CopyCompany(SourceName, DestinationName);
    end;
}
