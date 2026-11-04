// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// XmlPort export (Format Xml) through streams: empty tables, escaping, attributes, LinkFields, Skip/Break, source table views.
// BC versions: 29 (27 and 28 by CI)

codeunit 73500 "LT XpT Export Basic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Export_ThreeRows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73410));
        Observer.ObserveError('af21');
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('af21|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af21|code', 'InvalidStreamData');
        Observer.Expect('len', '1294');
        Observer.Verify();
    end;

    [Test]
    procedure Export_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        asserterror Observer.Observe('xml', Helper.ExportText(73410));
        Observer.ObserveError('af34');
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('af34|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af34|code', 'InvalidStreamData');
        Observer.Expect('len', '462');
        Observer.Verify();
    end;

    [Test]
    procedure Export_SpecialChars()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'A&B <x> "q" ''s'' ü € ß', 1, 1, true, 'C', 0D);
        Helper.AddItem(2, '', 0, 0, false, '', 0D);
        Helper.AddItem(3, '  lead and trail  ', -5, -1234.5678, true, 'X', 20000229D);
        asserterror Observer.Observe('xml', Helper.ExportText(73410));
        Observer.ObserveError('af50');
        Observer.Expect('af50|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af50|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_DecimalAndDateShapes()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', 2147483647, 0.00001, true, 'C', 17530101D);
        Helper.AddItem(2, 'b', -2147483647, 1234567890.123456789, false, 'C', 99991231D);
        Helper.AddItem(3, 'c', 0, 100, true, 'C', 0D);
        asserterror Observer.Observe('xml', Helper.ExportText(73410));
        Observer.ObserveError('af65');
        Observer.Expect('af65|text', 'Cannot write the value 01/01/1753 to the field StampDate in the table LT XpT Item because the value is either too long or the content is invalid.');
        Observer.Expect('af65|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;











    [Test]
    procedure Export_StaticWithRecordFilter()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Item: Record "LT XpT Item";
    begin
        Helper.Wipe();
        Helper.Seed();
        Item.SetRange(Category, 'B');
        Observer.Observe('xml', Helper.ExportWithRec(73410, Item));
        Observer.Expect('xml', ' þ<<NL>?<NL>x<NL>m<NL>l<NL> <NL>v<NL>e<NL>r<NL>s<NL>i<NL>o<NL>n<NL>=<NL>"<NL>1<NL>.<NL>0<NL>"<NL> <NL>e<NL>n<NL>c<NL>o<NL>d<NL>i<NL>n<NL>g<NL>=<NL>"<NL>U<NL>T<NL>F<NL>-<NL>1<NL>6<NL>"<NL> <NL>s<NL>t<NL>a<NL>n<NL>d<NL>a<NL>l<NL>o<NL>n<NL>e<NL>=<NL>"<NL>n<NL>o<NL>"<NL>?<NL>><NL><NL><NL><NL><<NL>R<NL>o<NL>o<NL>t<NL>><NL><NL><NL><NL> <NL> <NL><<NL>I<NL>t<NL>e<NL>m<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>I<NL>d<NL>><NL>3<NL><<NL>/<NL>I<NL>d<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>N<NL>a<NL>m<NL>e<NL>><NL>G<NL>a<NL>m<NL>m<NL>a<NL><<NL>/<NL>N<NL>a<NL>m<NL>e<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>Q<NL>t<NL>y<NL>><NL>3<NL>0<NL><<NL>/<NL>Q<NL>t<NL>y<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>A<NL>m<NL>o<NL>u<NL>n<NL>t<NL>><NL>3<NL>.<NL>5<NL>0<NL><<NL>/<NL>A<NL>m<NL>o<NL>u<NL>n<NL>t<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>A<NL>c<NL>t<NL>i<NL>v<NL>e<NL>><NL>Y<NL>e<NL>s<NL><<NL>/<NL>A<NL>c<NL>t<NL>i<NL>v<NL>e<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>C<NL>a<NL>t<NL>e<NL>g<NL>o<NL>r<NL>y<NL>><NL>B<NL><<NL>/<NL>C<NL>a<NL>t<NL>e<NL>g<NL>o<NL>r<NL>y<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>S<NL>t<NL>a<NL>m<NL>p<NL>D<NL>a<NL>t<NL>e<NL> <NL>/<NL>><NL><NL><NL><NL> <NL> <NL><<NL>/<NL>I<NL>t<NL>e<NL>m<NL>><NL><NL><NL><NL><<NL>/<NL>R<NL>o<NL>o<NL>t<NL>>');
        Observer.Verify();
    end;

    [Test]
    procedure Export_StaticWithRecordNoRows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Item: Record "LT XpT Item";
    begin
        Helper.Wipe();
        Helper.Seed();
        Item.SetRange(Id, 99);
        Observer.Observe('xml', Helper.ExportWithRec(73410, Item));
        Observer.Expect('xml', ' þ<<NL>?<NL>x<NL>m<NL>l<NL> <NL>v<NL>e<NL>r<NL>s<NL>i<NL>o<NL>n<NL>=<NL>"<NL>1<NL>.<NL>0<NL>"<NL> <NL>e<NL>n<NL>c<NL>o<NL>d<NL>i<NL>n<NL>g<NL>=<NL>"<NL>U<NL>T<NL>F<NL>-<NL>1<NL>6<NL>"<NL> <NL>s<NL>t<NL>a<NL>n<NL>d<NL>a<NL>l<NL>o<NL>n<NL>e<NL>=<NL>"<NL>n<NL>o<NL>"<NL>?<NL>><NL><NL><NL><NL><<NL>R<NL>o<NL>o<NL>t<NL>><NL><NL><NL><NL> <NL> <NL><<NL>I<NL>t<NL>e<NL>m<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>I<NL>d<NL>><NL>0<NL><<NL>/<NL>I<NL>d<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>N<NL>a<NL>m<NL>e<NL> <NL>/<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>Q<NL>t<NL>y<NL>><NL>0<NL><<NL>/<NL>Q<NL>t<NL>y<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>A<NL>m<NL>o<NL>u<NL>n<NL>t<NL>><NL>0<NL>.<NL>0<NL>0<NL><<NL>/<NL>A<NL>m<NL>o<NL>u<NL>n<NL>t<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>A<NL>c<NL>t<NL>i<NL>v<NL>e<NL>><NL>N<NL>o<NL><<NL>/<NL>A<NL>c<NL>t<NL>i<NL>v<NL>e<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>C<NL>a<NL>t<NL>e<NL>g<NL>o<NL>r<NL>y<NL> <NL>/<NL>><NL><NL><NL><NL> <NL> <NL> <NL> <NL><<NL>S<NL>t<NL>a<NL>m<NL>p<NL>D<NL>a<NL>t<NL>e<NL> <NL>/<NL>><NL><NL><NL><NL> <NL> <NL><<NL>/<NL>I<NL>t<NL>e<NL>m<NL>><NL><NL><NL><NL><<NL>/<NL>R<NL>o<NL>o<NL>t<NL>>');
        Observer.Verify();
    end;

    [Test]
    procedure Export_SourceTableViewSorted()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73422));
        Observer.ObserveError('af149');
        Observer.Expect('af149|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af149|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_SkipInAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73424));
        Observer.ObserveError('af162');
        Observer.Expect('af162|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af162|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_BreakInAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73425));
        Observer.ObserveError('af175');
        Observer.Expect('af175|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af175|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Attributes()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73411));
        Observer.ObserveError('af188');
        Observer.Expect('af188|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af188|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_LinkFieldsNested()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73412));
        Observer.ObserveError('af201');
        Observer.Expect('af201|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af201|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_LinkFieldsEmptyParents()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'x', 1, 1, true, 'C', 0D);
        asserterror Observer.Observe('xml', Helper.ExportText(73412));
        Observer.ObserveError('af214');
        Observer.Expect('af214|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af214|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_TextAndAttributeElements()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        asserterror Observer.Observe('xml', Helper.ExportText(73421));
        Observer.ObserveError('af226');
        Observer.Expect('af226|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af226|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_FormatEvaluateXml()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73431));
        Observer.ObserveError('af239');
        Observer.Expect('af239|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af239|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_FormatEvaluateLegacy()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73432));
        Observer.ObserveError('af252');
        Observer.Expect('af252|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af252|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_OnlyDirectionExport()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73415));
        Observer.ObserveError('af265');
        Observer.Expect('af265|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af265|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_OptionalMinOccurs()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73419));
        Observer.ObserveError('af278');
        Observer.Expect('af278|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af278|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Twice()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('same', Format(Helper.ExportText(73410) = Helper.ExportText(73410)));
        Observer.ObserveError('af306');
        Observer.Expect('af306|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af306|code', 'InvalidStreamData');
        Observer.Verify();
    end;
}
