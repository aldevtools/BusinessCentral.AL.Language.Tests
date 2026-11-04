// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// XmlPort static and instance API: unknown ids, repeated Import/Export, missing source or destination, Temp Blob codeunit and Blob field streams.
// BC versions: 29 (27 and 28 by CI)

codeunit 73506 "LT XpT Static And Instance"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Static_ImportWrongId()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(1, '<a/>'));
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The ''a'' element is not declared.|XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure Static_ExportWrongId()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        asserterror Helper.ExportText(1);
        Observer.ObserveError('err');
        Observer.Expect('err|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('err|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Static_ExportNonexistentId()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        asserterror Helper.ExportText(73799);
        Observer.ObserveError('err');
        Observer.Expect('err|text', 'You tried to invoke the XmlPort object with the ID 73799 from the object LT XpT Helper. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('err|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Static_ImportRecordParam()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Item: Record "LT XpT Item";
        TB: Record "LT XpT Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Helper.Wipe();
        TB.Data.CreateOutStream(OutS);
        OutS.WriteText('<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>');
        TB.Data.CreateInStream(InS);
        Xmlport.Import(73410, InS, Item);
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_ImportTwiceSameSource()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Xp: XmlPort "LT XpT Xml AutoRep";
        TB: Record "LT XpT Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Helper.Wipe();
        TB.Data.CreateOutStream(OutS);
        OutS.WriteText('<Root><Item><Id>1</Id><Name>A</Name><Qty>1</Qty></Item></Root>');
        TB.Data.CreateInStream(InS);
        Xp.SetSource(InS);
        Xp.Import();
        Observer.Observe('items1', Helper.DumpItems());
        Xp.Import();
        Observer.Observe('items2', Helper.DumpItems());
        Observer.Expect('items1', '1|A|1|0|false||;');
        Observer.Expect('items2', '1|A|1|0|false||;');
        Observer.Verify();
    end;






    [Test]
    procedure Instance_ExportAfterImportDirection()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Xp: XmlPort "LT XpT Xml Items";
        TB: Record "LT XpT Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Helper.Wipe();
        Helper.Seed();
        TB.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        TB.Data.CreateInStream(InS);
        Xp.SetSource(InS);
        Helper.Wipe();
        Xp.Import();
        Observer.Observe('err', 'no error');
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'no error');
        Observer.Expect('items', '1|Alpha|10|1.5|true|A|2024-01-15;2|Beta|20|2.5|false|A|2023-12-31;3|Gamma|30|3.5|true|B|;');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_TempBlobCodeunitRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        Helper.Wipe();
        Helper.Seed();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(73410, OutS);
        TempBlob.CreateInStream(InS);
        Observer.Observe('xml', Helper.ReadAll(InS));
        Observer.Observe('len', Format(TempBlob.Length()));
        Observer.Expect('len', '1294');
        Observer.Ignore('xml'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;









}
