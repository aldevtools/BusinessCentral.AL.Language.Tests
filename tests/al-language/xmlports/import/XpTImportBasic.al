// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// XmlPort import (Format Xml): value conversion, escaping, malformed input and the exact error texts, extra and missing elements, duplicate keys.
// BC versions: 29 (27 and 28 by CI)

codeunit 73501 "LT XpT Import Basic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Import_OneItem()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_WithProlog()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<?xml version="1.0" encoding="utf-8"?><Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_PrologUtf16Declared()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<?xml version="1.0" encoding="utf-16"?><Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:There is no Unicode byte order mark. Cannot switch to Unicode.|XmlPortImport:Xml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_PrettyPrinted()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root>' + Helper.Chr(13) + '' + Helper.Chr(10) + '  <Item>' + Helper.Chr(13) + '' + Helper.Chr(10) + '    <Id>1</Id>' + Helper.Chr(13) + '' + Helper.Chr(10) + '    <Name>A</Name>' + Helper.Chr(13) + '' + Helper.Chr(10) + '    <Qty>5</Qty>' + Helper.Chr(13) + '' + Helper.Chr(10) + '    <Amount>1.5</Amount>' + Helper.Chr(13) + '' + Helper.Chr(10) + '    <Active>true</Active>' + Helper.Chr(13) + '' + Helper.Chr(10) + '    <Category>C</Category>' + Helper.Chr(13) + '' + Helper.Chr(10) + '    <StampDate>2024-01-15</StampDate>' + Helper.Chr(13) + '' + Helper.Chr(10) + '  </Item>' + Helper.Chr(13) + '' + Helper.Chr(10) + '</Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_ThreeItems()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item><Item><Id>2</Id><Name>B</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item><Item><Id>3</Id><Name>C</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;2|B|5|1.5|true|C|2024-01-15;3|C|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_EscapedText()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A&amp;B &lt;x&gt; &quot;q&quot; &apos;s&apos; &#252; &#x20AC;</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A&B <x> "q" ''s'' ü €|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_CData()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name><![CDATA[a<b&c]]></Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|a<b&c|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_SelfClosingEmptyValues()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name/><Qty/><Amount/><Active/><Category/><StampDate/></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1||0|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_EmptyValuesExplicit()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name></Name><Qty></Qty><Amount></Amount><Active></Active><Category></Category><StampDate></StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1||0|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_BooleanSpellings()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Wipe();
        Observer.Observe('b_0_true', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('v_0', Helper.DumpItems());
        Helper.Wipe();
        Observer.Observe('b_1_false', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>false</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('v_1', Helper.DumpItems());
        Helper.Wipe();
        Observer.Observe('b_2_1', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>1</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('v_2', Helper.DumpItems());
        Helper.Wipe();
        Observer.Observe('b_3_0', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>0</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('v_3', Helper.DumpItems());
        Helper.Wipe();
        Observer.Observe('b_4_True', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>True</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('v_4', Helper.DumpItems());
        Helper.Wipe();
        Observer.Observe('b_5_TRUE', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>TRUE</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('v_5', Helper.DumpItems());
        Helper.Wipe();
        Observer.Observe('b_6_yes', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>yes</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('v_6', Helper.DumpItems());
        Helper.Wipe();
        Observer.Observe('b_7_Yes', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>Yes</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('v_7', Helper.DumpItems());
        Helper.Wipe();
        Observer.Observe('b_8_no', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>no</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('v_8', Helper.DumpItems());
        Helper.Wipe();
        Observer.Observe('b_9_Y', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>Y</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('v_9', Helper.DumpItems());
        Helper.Wipe();
        Observer.Observe('b_10_', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active></Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('v_10', Helper.DumpItems());
        Observer.Expect('b_0_true', 'ok');
        Observer.Expect('v_0', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Expect('b_1_false', 'ok');
        Observer.Expect('v_1', '1|A|5|1.5|false|C|2024-01-15;');
        Observer.Expect('b_2_1', 'ok');
        Observer.Expect('v_2', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Expect('b_3_0', 'ok');
        Observer.Expect('v_3', '1|A|5|1.5|false|C|2024-01-15;');
        Observer.Expect('b_4_True', 'ok');
        Observer.Expect('v_4', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Expect('b_5_TRUE', 'ok');
        Observer.Expect('v_5', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Expect('b_6_yes', 'ok');
        Observer.Expect('v_6', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Expect('b_7_Yes', 'ok');
        Observer.Expect('v_7', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Expect('b_8_no', 'ok');
        Observer.Expect('v_8', '1|A|5|1.5|false|C|2024-01-15;');
        Observer.Expect('b_9_Y', 'ok');
        Observer.Expect('v_9', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Expect('b_10_', 'ok');
        Observer.Expect('v_10', '1|A|5|1.5|false|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_ExtraUnknownElement()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Foo>x</Foo><Name>A</Name><Qty>5</Qty><Amount>1</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Foo''. List of possible elements expected: ''Name''.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_ExtraTrailingElement()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate><Extra>1</Extra></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Extra''.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_ExtraRootChild()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item><Other/></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Other''. List of possible elements expected: ''Item''.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_MissingElementQty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Amount>1</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Amount''. List of possible elements expected: ''Qty''.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_ElementsOutOfOrder()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Name>A</Name><Id>1</Id><Qty>5</Qty><Amount>1</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Name''. List of possible elements expected: ''Id''.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_ElementNameCase()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><id>1</id><Name>A</Name><Qty>5</Qty><Amount>1</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''id''. List of possible elements expected: ''Id''.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_NoItemsEmptyRoot()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root/>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Item''.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_NoItemsOpenCloseRoot()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Item''.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_EmptyInput()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, ''));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:Cannot import the specified XML document because the file is empty.|XmlPortData');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_WhitespaceOnlyInput()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '   '));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:Root element is missing.|XmlPortImport:Xml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_NotXml()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, 'this is not xml'));
        Observer.Expect('err', 'error:Data at the root level is invalid. Line 1, position 1.|XmlPortImport:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Csv_AsXml()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '1,A,5'));
        Observer.Expect('err', 'error:Data at the root level is invalid. Line 1, position 1.|XmlPortImport:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Import_UnclosedTag()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id>'));
        Observer.Expect('err', 'error:Unexpected end of file has occurred. The following elements are not closed: Item, Root. Line 1, position 23.|XmlPortImport:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Import_MismatchedTags()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Item></Id></Root>'));
        Observer.Expect('err', 'error:The ''Id'' start tag on line 1 position 14 does not match the end tag of ''Item''. Line 1, position 20.|XmlPortImport:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Import_OnlyProlog()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<?xml version="1.0"?>'));
        Observer.Expect('err', 'error:Root element is missing.|XmlPortImport:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Import_WrongRootName()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Other><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Other>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The ''Other'' element is not declared.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_TwoRoots()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root><Root><Item><Id>2</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:There are multiple root elements. Line 1, position 160.|XmlPortImport:Xml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_UnescapedAmpersand()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A&B</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Expect('err', 'error:''<'' is an unexpected token. The expected token is '';''. Line 1, position 32.|XmlPortImport:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Import_BadQtyText()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>abc</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Expect('err', 'error:The value "abc" can''t be evaluated into type Integer.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Import_QtyDecimalText()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>1.5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Expect('err', 'error:The value "1.5" can''t be evaluated into type Integer.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Import_QtyOverflow()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>99999999999</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Expect('err', 'error:The value "99999999999" can''t be evaluated into type Integer.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Import_BadAmount()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>x</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Expect('err', 'error:The value "x" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Import_BadBoolean()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>maybe</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Expect('err', 'error:The value "maybe" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Import_BadDate()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>notadate</StampDate></Item></Root>'));
        Observer.Expect('err', 'error:The format of the Date ''notadate'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Import_DateWrongFormat()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>15.01.2024</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:The format of the Date ''15.01.2024'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_NameTooLong()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:The length of the string is 51, but it must be less than or equal to 50 characters. Value: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|StringLengthExceeded');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_NameExactlyMax()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('len', Format(StrLen(Helper.DumpItems())));
        Observer.Expect('import1', 'ok');
        Observer.Expect('len', '77');
        Observer.Verify();
    end;

    [Test]
    procedure Import_CategoryTooLong()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>xxxxxxxxxxx</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:The length of the string is 11, but it must be less than or equal to 10 characters. Value: xxxxxxxxxxx|StringLengthExceeded');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_CategoryLowercase()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>abc</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|1.5|true|ABC|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_DuplicateKeyExisting()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'old', 1, 1, true, 'C', 0D);
        Commit();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:The record in table LT XpT Item already exists. Identification fields and values: Id=''1''|DB:RecordExists');
        Observer.Expect('items', '1|old|1|1|true|C|;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_DuplicateKeyWithinInput()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:The record in table LT XpT Item already exists. Identification fields and values: Id=''1''|DB:RecordExists');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_SecondItemInvalidRollsBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Commit();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item><Item><Id>2</Id><Name>A</Name><Qty>bad</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:The value "bad" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_WhitespaceAroundValues()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root><Item><Id> 1 </Id><Name>  A  </Name><Qty> 5 </Qty><Amount> 1.5 </Amount><Active> true </Active><Category> C </Category><StampDate> 2024-01-15 </StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Comments()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<!-- c --><Root><!-- c2 --><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AttributeOnRootIgnored()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root x="1"><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:Imported XML cannot validate with the schema: The ''x'' attribute is not declared.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AttributeOnItem()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item a="1"><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The ''a'' attribute is not declared.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_InstanceSetSource()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Xp: XmlPort "LT XpT Xml Items";
        TB: Record "LT XpT Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Helper.Wipe();
        TB.Data.CreateOutStream(OutS);
        OutS.WriteText('<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>');
        TB.Data.CreateInStream(InS);
        Xp.SetSource(InS);
        Xp.Import();
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_InstanceNoSource()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Xp: XmlPort "LT XpT Xml Items";
    begin
        Helper.Wipe();
        Observer.Verify();
    end;

    [Test]
    procedure Export_InstanceNoDestination()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Xp: XmlPort "LT XpT Xml Items";
    begin
        Helper.Wipe();
        Xp.Export();
        Observer.Observe('err', 'no error');
        Observer.Expect('err', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Import_EmptyBlobStream()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        TB: Record "LT XpT Blob" temporary;
        InS: InStream;
    begin
        Helper.Wipe();
        TB.Data.CreateInStream(InS);
        asserterror Xmlport.Import(73410, InS);
        Observer.ObserveError('err');
        Observer.Expect('err|text', 'Cannot import the specified XML document because the file is empty.');
        Observer.Expect('err|code', 'XmlPortData');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AfterExportRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('import1', Helper.TryImport(73426, Helper.ExportText(73426)));
        Observer.ObserveError('af654');
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('af654|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af654|code', 'InvalidStreamData');
        Observer.Expect('items', '');
        Observer.Verify();
    end;
}
