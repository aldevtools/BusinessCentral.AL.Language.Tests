// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// XmlPort Format VariableText: delimiter, separators, header line, quoting, malformed rows, round trip.
// BC versions: 29 (27 and 28 by CI)

codeunit 73504 "LT XpT Variable Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Csv_ExportThreeRows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('csv', Helper.ExportText(73413));
        Observer.Expect('csv', '"1","Alpha","10","1.50","Yes"<NL>"2","Beta","20","2.50","No"<NL>"3","Gamma","30","3.50","Yes"');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ExportEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('csv', Helper.ExportText(73413));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('csv', '');
        Observer.Expect('len', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ExportSpecial()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a,b', 1, 1, true, 'C', 0D);
        Helper.AddItem(2, 'say "hi"', 2, 2, false, 'C', 0D);
        Helper.AddItem(3, 'line1' + Helper.Chr(10) + 'x', 3, 3, true, 'C', 0D);
        Helper.AddItem(4, '', 4, 0, false, 'C', 0D);
        Helper.AddItem(5, ' sp ', 5, 0.5, false, 'C', 0D);
        Observer.Observe('csv', Helper.ExportText(73413));
        Observer.Expect('csv', '"1","a,b","1","1.00","Yes"<NL>"2","say "hi"","2","2.00","No"<NL>"3","line1<NL>x","3","3.00","Yes"<NL>"4","","4","0.00","No"<NL>"5"," sp ","5","0.50","No"');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ExportSemicolonNoDelimiter()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('csv', Helper.ExportText(73414));
        Observer.Expect('csv', '1;Alpha;10;1.50;Yes<NL>2;Beta;20;2.50;No<NL>3;Gamma;30;3.50;Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ExportSemicolonWithSeparatorInText()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a;b', 1, 1, true, 'C', 0D);
        Observer.Observe('csv', Helper.ExportText(73414));
        Observer.Expect('csv', '1;a;b;1;1.00;Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ExportHeaderLine()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('csv', Helper.ExportText(73436));
        Observer.Expect('csv', '"1","Alpha","10","1.50","Yes"<NL>"2","Beta","20","2.50","No"<NL>"3","Gamma","30","3.50","Yes"');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportBasic()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73413, '1,A,5,1.5,1' + Helper.Chr(13) + '' + Helper.Chr(10) + '2,B,6,2.5,0'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportBooleanSpellings()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('e1', Helper.TryImport(73413, '1,A,5,1.5,true'));
        Observer.Observe('i1', Helper.DumpItems());
        Observer.Expect('e1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('i1', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportQuoted()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73413, '1,"a,b",5,1.5,1' + Helper.Chr(10) + '2,"say ""hi""",6,2.5,0'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportEmbeddedNewlineInQuotes()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73413, '1,"a' + Helper.Chr(10) + 'b",5,1.5,1'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportTrailingNewline()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73413, '1,A,5,1.5,1' + Helper.Chr(13) + '' + Helper.Chr(10) + ''));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportBlankLineBetween()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73413, '1,A,5,1.5,1' + Helper.Chr(13) + '' + Helper.Chr(10) + '' + Helper.Chr(13) + '' + Helper.Chr(10) + '2,B,6,2.5,0'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73413, ''));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:Cannot import the specified XML document because the file is empty.|XmlPortData');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportShortRow()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73413, '1,A,5'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportExtraFields()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73413, '1,A,5,1.5,1,extra,more'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportBadInteger()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73413, '1,A,x,1.5,1'));
        Observer.Expect('err', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportEmptyFields()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73413, '1,,,,'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportUnbalancedQuote()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73413, '1,"A,5,1.5,1'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportSemicolon()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73414, '1;A;5;1.5;1' + Helper.Chr(10) + '2;B;6;2.5;0'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportSemicolonWithCrLf()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73414, '1;A;5;1.5;1' + Helper.Chr(13) + '' + Helper.Chr(10) + '2;B;6;2.5;0'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_ImportWithHeaderLine()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73436, 'Id,Name,Qty,Amount,Active' + Helper.Chr(13) + '' + Helper.Chr(10) + '1,A,5,1.5,1'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('import1', Helper.TryImport(73413, Helper.ExportText(73413)));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '1|Alpha|10|1.5|true|A|2024-01-15;2|Beta|20|2.5|false|A|2023-12-31;3|Gamma|30|3.5|true|B|;');
        Observer.Verify();
    end;

    [Test]
    procedure Csv_RoundTripAutoReplaceNone()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Commit();
        Observer.Observe('err', Helper.TryImport(73413, Helper.ExportText(73413)));
        Observer.Expect('err', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Verify();
    end;
}
