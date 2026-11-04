// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT Y83 helpers (Y83XpFixtures.al); ports in Y83XpMiscPorts.al
// Probe: corpus issue (Y83). XmlPort shapes: UseLax in nested table elements, control characters under XmlVersionNo V10 and V11, decimal text, VariableText and FixedText shapes,
// Boolean, Date and Decimal text by session language, an instance run without a stream, an id no XmlPort declares, a TableFilter field, RequestFilterFields, triggers of container text elements.
// BC versions: 27-29

codeunit 94336 "LT Y83 Misc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y83 Helper";

    // Linux suspect, not a test: on the Linux BC containers (27.5, 28.5, 29.0) this call ends the test with 'Unexpected CLR exception thrown.: System.ArgumentNullException: Value cannot be null. (Parameter 'Source')' at NavXmlPort.Import,
    // a CLR exception no AL code can catch. To be verified on Windows before it becomes a test.
    procedure Suspect_Instance_Import_Without_Source()
    begin
        Observer.Observe('import without source', ImportNoSource());
        Observer.Finish();
    end;

    // Linux suspect, not a test: on the Linux BC containers (27.5, 28.5, 29.0) this call ends the test with 'Unexpected CLR exception thrown.: System.ArgumentNullException: Value cannot be null. (Parameter 'Source')' at NavXmlPort.Import,
    // a CLR exception no AL code can catch. To be verified on Windows before it becomes a test.
    procedure Suspect_Instance_Import_After_SetDestination()
    begin
        Observer.Observe('import after setdestination', ImportAfterSetDestination());
        Observer.Finish();
    end;

    [Test]
    procedure Lax_Nested_1()
    begin
        Imp('lax unknown between fields', 94362, '<Root><Item><Id>7</Id><Unknown>x</Unknown><Name>seven</Name></Item></Root>');
        Imp('strict unknown between fields', 94363, '<Root><Item><Id>7</Id><Unknown>x</Unknown><Name>seven</Name></Item></Root>');
        Imp('lax unknown in child before field', 94362, '<Root><Item><Id>7</Id><Name>seven</Name><Child><Unknown>x</Unknown><Txt>t</Txt></Child></Item></Root>');
        Imp('strict unknown in child before field', 94363, '<Root><Item><Id>7</Id><Name>seven</Name><Child><Unknown>x</Unknown><Txt>t</Txt></Child></Item></Root>');
        Imp('lax unknown between children', 94362, '<Root><Item><Id>7</Id><Name>seven</Name><Child><Txt>t</Txt></Child><Unknown>x</Unknown><Child><Txt>u</Txt></Child></Item></Root>');
        Imp('strict unknown between children', 94363, '<Root><Item><Id>7</Id><Name>seven</Name><Child><Txt>t</Txt></Child><Unknown>x</Unknown><Child><Txt>u</Txt></Child></Item></Root>');
        Observer.Expect('lax unknown between fields', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown''. List of possible elements expected: ''Name'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax unknown between fields rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict unknown between fields', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown''. List of possible elements expected: ''Name''.|XmlPortInvalidXml');
        Observer.Expect('strict unknown between fields rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('lax unknown in child before field', 'error:Imported XML cannot validate with the schema: The element ''Child'' has invalid child element ''Unknown''. List of possible elements expected: ''Txt'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax unknown in child before field rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict unknown in child before field', 'error:Imported XML cannot validate with the schema: The element ''Child'' has invalid child element ''Unknown''. List of possible elements expected: ''Txt''.|XmlPortInvalidXml');
        Observer.Expect('strict unknown in child before field rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('lax unknown between children', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown''. List of possible elements expected: ''Child'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax unknown between children rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict unknown between children', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown''. List of possible elements expected: ''Child''.|XmlPortInvalidXml');
        Observer.Expect('strict unknown between children rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure Lax_Nested_2()
    begin
        Imp('lax unknown after last child', 94362, '<Root><Item><Id>7</Id><Name>seven</Name><Child><Txt>t</Txt></Child><Unknown>x</Unknown></Item></Root>');
        Imp('strict unknown after last child', 94363, '<Root><Item><Id>7</Id><Name>seven</Name><Child><Txt>t</Txt></Child><Unknown>x</Unknown></Item></Root>');
        Imp('lax other ns between children', 94362, '<Root><Item><Id>7</Id><Name>seven</Name><Child><Txt>t</Txt></Child><Other xmlns="urn:o"/><Child><Txt>u</Txt></Child></Item></Root>');
        Imp('strict other ns between children', 94363, '<Root><Item><Id>7</Id><Name>seven</Name><Child><Txt>t</Txt></Child><Other xmlns="urn:o"/><Child><Txt>u</Txt></Child></Item></Root>');
        Imp('lax other ns in child before field', 94362, '<Root><Item><Id>7</Id><Name>seven</Name><Child><Other xmlns="urn:o"/><Txt>t</Txt></Child></Item></Root>');
        Imp('strict other ns in child before field', 94363, '<Root><Item><Id>7</Id><Name>seven</Name><Child><Other xmlns="urn:o"/><Txt>t</Txt></Child></Item></Root>');
        Observer.Expect('lax unknown after last child', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown''. List of possible elements expected: ''Child'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax unknown after last child rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict unknown after last child', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown''. List of possible elements expected: ''Child''.|XmlPortInvalidXml');
        Observer.Expect('strict unknown after last child rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('lax other ns between children', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Child''. List of possible elements expected: any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax other ns between children rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict other ns between children', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Other'' in namespace ''urn:o''. List of possible elements expected: ''Child''.|XmlPortInvalidXml');
        Observer.Expect('strict other ns between children rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('lax other ns in child before field', 'ok');
        Observer.Expect('lax other ns in child before field rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/0/false//0;#0/7/t;1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict other ns in child before field', 'error:Imported XML cannot validate with the schema: The element ''Child'' has invalid child element ''Other'' in namespace ''urn:o''. List of possible elements expected: ''Txt''.|XmlPortInvalidXml');
        Observer.Expect('strict other ns in child before field rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure Lax_Nested_3()
    begin
        Imp('lax unknown attribute on item', 94362, '<Root><Item foo="1"><Id>7</Id><Name>seven</Name></Item></Root>');
        Imp('strict unknown attribute on item', 94363, '<Root><Item foo="1"><Id>7</Id><Name>seven</Name></Item></Root>');
        Imp('lax unknown attribute on root', 94362, '<Root foo="1"><Item><Id>7</Id><Name>seven</Name></Item></Root>');
        Imp('strict unknown attribute on root', 94363, '<Root foo="1"><Item><Id>7</Id><Name>seven</Name></Item></Root>');
        Imp('lax unknown before first item', 94362, '<Root><Unknown>x</Unknown><Item><Id>7</Id><Name>seven</Name></Item></Root>');
        Imp('strict unknown before first item', 94363, '<Root><Unknown>x</Unknown><Item><Id>7</Id><Name>seven</Name></Item></Root>');
        Observer.Expect('lax unknown attribute on item', 'error:Imported XML cannot validate with the schema: The ''foo'' attribute is not declared.|XmlPortInvalidXml');
        Observer.Expect('lax unknown attribute on item rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict unknown attribute on item', 'error:Imported XML cannot validate with the schema: The ''foo'' attribute is not declared.|XmlPortInvalidXml');
        Observer.Expect('strict unknown attribute on item rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('lax unknown attribute on root', 'error:Imported XML cannot validate with the schema: The ''foo'' attribute is not declared.|XmlPortInvalidXml');
        Observer.Expect('lax unknown attribute on root rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict unknown attribute on root', 'error:Imported XML cannot validate with the schema: The ''foo'' attribute is not declared.|XmlPortInvalidXml');
        Observer.Expect('strict unknown attribute on root rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('lax unknown before first item', 'error:Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Unknown''. List of possible elements expected: ''Item'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax unknown before first item rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict unknown before first item', 'error:Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Unknown''. List of possible elements expected: ''Item''.|XmlPortInvalidXml');
        Observer.Expect('strict unknown before first item rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure Lax_Nested_4()
    begin
        Imp('lax unknown after last item', 94362, '<Root><Item><Id>7</Id><Name>seven</Name></Item><Unknown>x</Unknown></Root>');
        Imp('strict unknown after last item', 94363, '<Root><Item><Id>7</Id><Name>seven</Name></Item><Unknown>x</Unknown></Root>');
        Imp('lax unknown between items', 94362, '<Root><Item><Id>7</Id><Name>seven</Name></Item><Unknown>x</Unknown><Item><Id>8</Id><Name>eight</Name></Item></Root>');
        Imp('strict unknown between items', 94363, '<Root><Item><Id>7</Id><Name>seven</Name></Item><Unknown>x</Unknown><Item><Id>8</Id><Name>eight</Name></Item></Root>');
        Imp('lax other ns after last item', 94362, '<Root><Item><Id>7</Id><Name>seven</Name></Item><Other xmlns="urn:o"/></Root>');
        Imp('strict other ns after last item', 94363, '<Root><Item><Id>7</Id><Name>seven</Name></Item><Other xmlns="urn:o"/></Root>');
        Observer.Expect('lax unknown after last item', 'error:Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Child'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax unknown after last item rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict unknown after last item', 'error:Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Child''.|XmlPortInvalidXml');
        Observer.Expect('strict unknown after last item rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('lax unknown between items', 'error:Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Child'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax unknown between items rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict unknown between items', 'error:Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Child''.|XmlPortInvalidXml');
        Observer.Expect('strict unknown between items rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('lax other ns after last item', 'error:Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Child'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax other ns after last item rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('strict other ns after last item', 'error:Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Child''.|XmlPortInvalidXml');
        Observer.Expect('strict other ns after last item rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure Xml_ControlChar_Export_1()
    begin
        ExpChar('export v10 char 1', 94364, 1);
        ExpChar('export v11 char 1', 94365, 1);
        ExpChar('export v10 char 8', 94364, 8);
        ExpChar('export v11 char 8', 94365, 8);
        ExpChar('export v10 char 11', 94364, 11);
        ExpChar('export v11 char 11', 94365, 11);
        Observer.Expect('export v10 char 1', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#x1;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v11 char 1', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#x1;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v10 char 8', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#x8;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v11 char 8', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#x8;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v10 char 11', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#xB;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v11 char 11', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#xB;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Xml_ControlChar_Export_2()
    begin
        ExpChar('export v10 char 12', 94364, 12);
        ExpChar('export v11 char 12', 94365, 12);
        ExpChar('export v10 char 14', 94364, 14);
        ExpChar('export v11 char 14', 94365, 14);
        ExpChar('export v10 char 27', 94364, 27);
        ExpChar('export v11 char 27', 94365, 27);
        Observer.Expect('export v10 char 12', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#xC;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v11 char 12', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#xC;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v10 char 14', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#xE;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v11 char 14', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#xE;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v10 char 27', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#x1B;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v11 char 27', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a&#x1B;b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Xml_ControlChar_Export_3()
    begin
        ExpChar('export v10 char 127', 94364, 127);
        ExpChar('export v11 char 127', 94365, 127);
        ExpChar('export v10 char 133', 94364, 133);
        ExpChar('export v11 char 133', 94365, 133);
        ExpChar('export v10 char 8232', 94364, 8232);
        ExpChar('export v11 char 8232', 94365, 8232);
        Observer.Expect('export v10 char 127', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a{127}b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v11 char 127', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a{127}b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v10 char 133', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a{133}b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v11 char 133', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a{133}b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v10 char 8232', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a{8232}b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Expect('export v11 char 8232', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>a{8232}b</Name>\r\n  </Item>\r\n</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Xml_ControlChar_Import_1()
    begin
        Imp('v10 ref 1', 94364, '<Root><Item><Id>7</Id><Name>a&#1;b</Name></Item></Root>');
        Imp('v10 hexref 1', 94364, '<Root><Item><Id>7</Id><Name>a&#x1;b</Name></Item></Root>');
        Imp('v11 ref 1', 94365, '<Root><Item><Id>7</Id><Name>a&#1;b</Name></Item></Root>');
        Imp('v11 hexref 1', 94365, '<Root><Item><Id>7</Id><Name>a&#x1;b</Name></Item></Root>');
        Imp('v10 ref 8', 94364, '<Root><Item><Id>7</Id><Name>a&#8;b</Name></Item></Root>');
        Imp('v10 hexref 8', 94364, '<Root><Item><Id>7</Id><Name>a&#x8;b</Name></Item></Root>');
        Imp('v11 ref 8', 94365, '<Root><Item><Id>7</Id><Name>a&#8;b</Name></Item></Root>');
        Imp('v11 hexref 8', 94365, '<Root><Item><Id>7</Id><Name>a&#x8;b</Name></Item></Root>');
        Imp('v10 ref 11', 94364, '<Root><Item><Id>7</Id><Name>a&#11;b</Name></Item></Root>');
        Imp('v10 hexref 11', 94364, '<Root><Item><Id>7</Id><Name>a&#xB;b</Name></Item></Root>');
        Imp('v11 ref 11', 94365, '<Root><Item><Id>7</Id><Name>a&#11;b</Name></Item></Root>');
        Imp('v11 hexref 11', 94365, '<Root><Item><Id>7</Id><Name>a&#xB;b</Name></Item></Root>');
        Observer.Expect('v10 ref 1', 'ok');
        Observer.Expect('v10 ref 1 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u0001b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 hexref 1', 'ok');
        Observer.Expect('v10 hexref 1 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u0001b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 ref 1', 'ok');
        Observer.Expect('v11 ref 1 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u0001b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 hexref 1', 'ok');
        Observer.Expect('v11 hexref 1 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u0001b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 ref 8', 'ok');
        Observer.Expect('v10 ref 8 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u0008b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 hexref 8', 'ok');
        Observer.Expect('v10 hexref 8 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u0008b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 ref 8', 'ok');
        Observer.Expect('v11 ref 8 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u0008b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 hexref 8', 'ok');
        Observer.Expect('v11 hexref 8 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u0008b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 ref 11', 'ok');
        Observer.Expect('v10 ref 11 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 hexref 11', 'ok');
        Observer.Expect('v10 hexref 11 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 ref 11', 'ok');
        Observer.Expect('v11 ref 11 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 hexref 11', 'ok');
        Observer.Expect('v11 hexref 11 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure Xml_ControlChar_Import_2()
    begin
        Imp('v10 ref 12', 94364, '<Root><Item><Id>7</Id><Name>a&#12;b</Name></Item></Root>');
        Imp('v10 hexref 12', 94364, '<Root><Item><Id>7</Id><Name>a&#xC;b</Name></Item></Root>');
        Imp('v11 ref 12', 94365, '<Root><Item><Id>7</Id><Name>a&#12;b</Name></Item></Root>');
        Imp('v11 hexref 12', 94365, '<Root><Item><Id>7</Id><Name>a&#xC;b</Name></Item></Root>');
        Imp('v10 ref 14', 94364, '<Root><Item><Id>7</Id><Name>a&#14;b</Name></Item></Root>');
        Imp('v10 hexref 14', 94364, '<Root><Item><Id>7</Id><Name>a&#xE;b</Name></Item></Root>');
        Imp('v11 ref 14', 94365, '<Root><Item><Id>7</Id><Name>a&#14;b</Name></Item></Root>');
        Imp('v11 hexref 14', 94365, '<Root><Item><Id>7</Id><Name>a&#xE;b</Name></Item></Root>');
        Imp('v10 ref 27', 94364, '<Root><Item><Id>7</Id><Name>a&#27;b</Name></Item></Root>');
        Imp('v10 hexref 27', 94364, '<Root><Item><Id>7</Id><Name>a&#x1B;b</Name></Item></Root>');
        Imp('v11 ref 27', 94365, '<Root><Item><Id>7</Id><Name>a&#27;b</Name></Item></Root>');
        Imp('v11 hexref 27', 94365, '<Root><Item><Id>7</Id><Name>a&#x1B;b</Name></Item></Root>');
        Observer.Expect('v10 ref 12', 'ok');
        Observer.Expect('v10 ref 12 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 hexref 12', 'ok');
        Observer.Expect('v10 hexref 12 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 ref 12', 'ok');
        Observer.Expect('v11 ref 12 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 hexref 12', 'ok');
        Observer.Expect('v11 hexref 12 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 ref 14', 'ok');
        Observer.Expect('v10 ref 14 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u000Eb/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 hexref 14', 'ok');
        Observer.Expect('v10 hexref 14 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u000Eb/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 ref 14', 'ok');
        Observer.Expect('v11 ref 14 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u000Eb/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 hexref 14', 'ok');
        Observer.Expect('v11 hexref 14 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u000Eb/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 ref 27', 'ok');
        Observer.Expect('v10 ref 27 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u001Bb/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 hexref 27', 'ok');
        Observer.Expect('v10 hexref 27 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u001Bb/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 ref 27', 'ok');
        Observer.Expect('v11 ref 27 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u001Bb/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 hexref 27', 'ok');
        Observer.Expect('v11 hexref 27 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u001Bb/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure Xml_ControlChar_Import_3()
    begin
        Imp('v10 ref 127', 94364, '<Root><Item><Id>7</Id><Name>a&#127;b</Name></Item></Root>');
        Imp('v10 hexref 127', 94364, '<Root><Item><Id>7</Id><Name>a&#x7F;b</Name></Item></Root>');
        Imp('v11 ref 127', 94365, '<Root><Item><Id>7</Id><Name>a&#127;b</Name></Item></Root>');
        Imp('v11 hexref 127', 94365, '<Root><Item><Id>7</Id><Name>a&#x7F;b</Name></Item></Root>');
        Imp('v10 ref 133', 94364, '<Root><Item><Id>7</Id><Name>a&#133;b</Name></Item></Root>');
        Imp('v10 hexref 133', 94364, '<Root><Item><Id>7</Id><Name>a&#x85;b</Name></Item></Root>');
        Imp('v11 ref 133', 94365, '<Root><Item><Id>7</Id><Name>a&#133;b</Name></Item></Root>');
        Imp('v11 hexref 133', 94365, '<Root><Item><Id>7</Id><Name>a&#x85;b</Name></Item></Root>');
        Imp('v10 ref 8232', 94364, '<Root><Item><Id>7</Id><Name>a&#8232;b</Name></Item></Root>');
        Imp('v10 hexref 8232', 94364, '<Root><Item><Id>7</Id><Name>a&#x2028;b</Name></Item></Root>');
        Imp('v11 ref 8232', 94365, '<Root><Item><Id>7</Id><Name>a&#8232;b</Name></Item></Root>');
        Imp('v11 hexref 8232', 94365, '<Root><Item><Id>7</Id><Name>a&#x2028;b</Name></Item></Root>');
        Observer.Expect('v10 ref 127', 'ok');
        Observer.Expect('v10 ref 127 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a{127}b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 hexref 127', 'ok');
        Observer.Expect('v10 hexref 127 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a{127}b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 ref 127', 'ok');
        Observer.Expect('v11 ref 127 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a{127}b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 hexref 127', 'ok');
        Observer.Expect('v11 hexref 127 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a{127}b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 ref 133', 'ok');
        Observer.Expect('v10 ref 133 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 hexref 133', 'ok');
        Observer.Expect('v10 hexref 133 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 ref 133', 'ok');
        Observer.Expect('v11 ref 133 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 hexref 133', 'ok');
        Observer.Expect('v11 hexref 133 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 ref 8232', 'ok');
        Observer.Expect('v10 ref 8232 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 hexref 8232', 'ok');
        Observer.Expect('v10 hexref 8232 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 ref 8232', 'ok');
        Observer.Expect('v11 ref 8232 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 hexref 8232', 'ok');
        Observer.Expect('v11 hexref 8232 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure Xml_ControlChar_Declarations()
    begin
        Imp('v10 decl 1.1 ref 1', 94364, '<?xml version="1.1" encoding="utf-8"?><Root><Item><Id>7</Id><Name>a&#1;b</Name></Item></Root>');
        Imp('v10 decl 1.0 ref 1', 94364, '<?xml version="1.0" encoding="utf-8"?><Root><Item><Id>7</Id><Name>a&#1;b</Name></Item></Root>');
        Imp('v10 decl 1.1 plain', 94364, '<?xml version="1.1" encoding="utf-8"?><Root><Item><Id>7</Id><Name>plain</Name></Item></Root>');
        Imp('v10 decl 1.1 nel', 94364, '<?xml version="1.1" encoding="utf-8"?><Root><Item><Id>7</Id><Name>ab</Name></Item></Root>');
        Imp('v11 decl 1.1 ref 1', 94365, '<?xml version="1.1" encoding="utf-8"?><Root><Item><Id>7</Id><Name>a&#1;b</Name></Item></Root>');
        Imp('v11 decl 1.0 ref 1', 94365, '<?xml version="1.0" encoding="utf-8"?><Root><Item><Id>7</Id><Name>a&#1;b</Name></Item></Root>');
        Imp('v11 decl 1.1 plain', 94365, '<?xml version="1.1" encoding="utf-8"?><Root><Item><Id>7</Id><Name>plain</Name></Item></Root>');
        Imp('v11 decl 1.1 nel', 94365, '<?xml version="1.1" encoding="utf-8"?><Root><Item><Id>7</Id><Name>ab</Name></Item></Root>');
        Observer.Expect('v10 decl 1.1 ref 1', 'error:Version number ''1.1'' is invalid. Line 1, position 16.|XmlPortImport:Xml');
        Observer.Expect('v10 decl 1.1 ref 1 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 decl 1.0 ref 1', 'ok');
        Observer.Expect('v10 decl 1.0 ref 1 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u0001b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 decl 1.1 plain', 'error:Version number ''1.1'' is invalid. Line 1, position 16.|XmlPortImport:Xml');
        Observer.Expect('v10 decl 1.1 plain rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v10 decl 1.1 nel', 'error:Version number ''1.1'' is invalid. Line 1, position 16.|XmlPortImport:Xml');
        Observer.Expect('v10 decl 1.1 nel rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 decl 1.1 ref 1', 'error:Version number ''1.1'' is invalid. Line 1, position 16.|XmlPortImport:Xml');
        Observer.Expect('v11 decl 1.1 ref 1 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 decl 1.0 ref 1', 'ok');
        Observer.Expect('v11 decl 1.0 ref 1 rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/a\u0001b/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 decl 1.1 plain', 'error:Version number ''1.1'' is invalid. Line 1, position 16.|XmlPortImport:Xml');
        Observer.Expect('v11 decl 1.1 plain rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('v11 decl 1.1 nel', 'error:Version number ''1.1'' is invalid. Line 1, position 16.|XmlPortImport:Xml');
        Observer.Expect('v11 decl 1.1 nel rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Export_Xml()
    begin
        SeedDecimals();
        Observer.Observe('export xml', Helper.TryExport(94366, TextEncoding::UTF16));
        Observer.Expect('export xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item AmtA="1.01">|    <Id>1</Id>|    <Amt>1.01</Amt>|  </Item>|  <Item AmtA="0.13">|    <Id>2</Id>|    <Amt>0.13</Amt>|  </Item>|  <Item AmtA="123,456.79">|    <Id>3</Id>|    <Amt>123,456.79</Amt>|  </Item>|  <Item AmtA="-0.50">|    <Id>4</Id>|    <Amt>-0.50</Amt>|  </Item>|  <Item AmtA="0.00">|    <Id>5</Id>|    <Amt>0.00</Amt>|  </Item>|  <Item AmtA="1,234,567.89">|    <Id>6</Id>|    <Amt>1,234,567.89</Amt>|  </Item>|  <Item AmtA="100.00">|    <Id>7</Id>|    <Amt>100.00</Amt>|  </Item>|  <Item AmtA="0.00">|    <Id>8</Id>|    <Amt>0.00</Amt>|  </Item>|  <Item AmtA="2.50">|    <Id>9</Id>|    <Amt>2.50</Amt>|  </Item>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Export_Legacy()
    begin
        SeedDecimals();
        Observer.Observe('export legacy', Helper.TryExport(94367, TextEncoding::UTF16));
        Observer.Expect('export legacy', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item AmtA="1.01">|    <Id>1</Id>|    <Amt>1.01</Amt>|  </Item>|  <Item AmtA="0.13">|    <Id>2</Id>|    <Amt>0.13</Amt>|  </Item>|  <Item AmtA="123,456.79">|    <Id>3</Id>|    <Amt>123,456.79</Amt>|  </Item>|  <Item AmtA="-0.50">|    <Id>4</Id>|    <Amt>-0.50</Amt>|  </Item>|  <Item AmtA="0.00">|    <Id>5</Id>|    <Amt>0.00</Amt>|  </Item>|  <Item AmtA="1,234,567.89">|    <Id>6</Id>|    <Amt>1,234,567.89</Amt>|  </Item>|  <Item AmtA="100.00">|    <Id>7</Id>|    <Amt>100.00</Amt>|  </Item>|  <Item AmtA="0.00">|    <Id>8</Id>|    <Amt>0.00</Amt>|  </Item>|  <Item AmtA="2.50">|    <Id>9</Id>|    <Amt>2.50</Amt>|  </Item>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Export_Text_Formats()
    var
        Raw: Text;
    begin
        SeedDecimals();
        Observer.Observe('export vt', Helper.TryExportRaw(94368, TextEncoding::UTF8));
        Observer.Observe('export fixed', Helper.TryExportRaw(94369, TextEncoding::UTF8));
        Observer.Expect('export vt', '"1","d","1.01"\r\n"2","d","0.13"\r\n"3","d","123,456.79"\r\n"4","d","-0.50"\r\n"5","d","0.00"\r\n"6","d","1,234,567.89"\r\n"7","d","100.00"\r\n"8","d","0.00"\r\n"9","d","2.50"');
        Observer.Expect('export fixed', '1   d         1.01        \r\n2   d         0.13        \r\n3   d         123,456.79  \r\n4   d         -0.50       \r\n5   d         0.00        \r\n6   d         1,234,567.89\r\n7   d         100.00      \r\n8   d         0.00        \r\n9   d         2.50        ');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Import_Xml()
    begin
        Imp('xml import [1.005]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt>1.005</Amt></Item></Root>');
        Imp('xml import [2.5000]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt>2.5000</Amt></Item></Root>');
        Imp('xml import [1e3]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt>1e3</Amt></Item></Root>');
        Imp('xml import [1E-5]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt>1E-5</Amt></Item></Root>');
        Imp('xml import [1,5]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt>1,5</Amt></Item></Root>');
        Imp('xml import [-.5]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt>-.5</Amt></Item></Root>');
        Imp('xml import [+3]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt>+3</Amt></Item></Root>');
        Imp('xml import [ 4.25 ]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt> 4.25 </Amt></Item></Root>');
        Imp('xml import [1 000.5]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt>1 000.5</Amt></Item></Root>');
        Imp('xml import [abc]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt>abc</Amt></Item></Root>');
        Imp('xml import [12345678901234567890.123456789012345678]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt>12345678901234567890.123456789012345678</Amt></Item></Root>');
        Imp('xml import [0.000000000000000001234]', 94366, '<Root><Item AmtA="0"><Id>7</Id><Amt>0.000000000000000001234</Amt></Item></Root>');
        Observer.Expect('xml import [1.005]', 'ok');
        Observer.Expect('xml import [1.005] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//1.005/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('xml import [2.5000]', 'ok');
        Observer.Expect('xml import [2.5000] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//2.5/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('xml import [1e3]', 'ok');
        Observer.Expect('xml import [1e3] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//1000/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('xml import [1E-5]', 'ok');
        Observer.Expect('xml import [1E-5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//0.00001/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('xml import [1,5]', 'ok');
        Observer.Expect('xml import [1,5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//15/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('xml import [-.5]', 'ok');
        Observer.Expect('xml import [-.5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//-0.5/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('xml import [+3]', 'ok');
        Observer.Expect('xml import [+3] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//3/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('xml import [ 4.25 ]', 'ok');
        Observer.Expect('xml import [ 4.25 ] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//4.25/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('xml import [1 000.5]', 'error:The value "1 000.5" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('xml import [1 000.5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('xml import [abc]', 'error:The value "abc" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('xml import [abc] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('xml import [12345678901234567890.123456789012345678]', 'error:The value "12345678901234567890.123456789012345678" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('xml import [12345678901234567890.123456789012345678] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('xml import [0.000000000000000001234]', 'ok');
        Observer.Expect('xml import [0.000000000000000001234] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//0.000000000000000001/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Import_Legacy()
    begin
        Imp('legacy import [1.005]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt>1.005</Amt></Item></Root>');
        Imp('legacy import [2.5000]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt>2.5000</Amt></Item></Root>');
        Imp('legacy import [1e3]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt>1e3</Amt></Item></Root>');
        Imp('legacy import [1E-5]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt>1E-5</Amt></Item></Root>');
        Imp('legacy import [1,5]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt>1,5</Amt></Item></Root>');
        Imp('legacy import [-.5]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt>-.5</Amt></Item></Root>');
        Imp('legacy import [+3]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt>+3</Amt></Item></Root>');
        Imp('legacy import [ 4.25 ]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt> 4.25 </Amt></Item></Root>');
        Imp('legacy import [1 000.5]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt>1 000.5</Amt></Item></Root>');
        Imp('legacy import [abc]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt>abc</Amt></Item></Root>');
        Imp('legacy import [12345678901234567890.123456789012345678]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt>12345678901234567890.123456789012345678</Amt></Item></Root>');
        Imp('legacy import [0.000000000000000001234]', 94367, '<Root><Item AmtA="0"><Id>7</Id><Amt>0.000000000000000001234</Amt></Item></Root>');
        Observer.Expect('legacy import [1.005]', 'ok');
        Observer.Expect('legacy import [1.005] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//1.005/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('legacy import [2.5000]', 'ok');
        Observer.Expect('legacy import [2.5000] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//2.5/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('legacy import [1e3]', 'ok');
        Observer.Expect('legacy import [1e3] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//1000/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('legacy import [1E-5]', 'ok');
        Observer.Expect('legacy import [1E-5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//0.00001/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('legacy import [1,5]', 'ok');
        Observer.Expect('legacy import [1,5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//15/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('legacy import [-.5]', 'ok');
        Observer.Expect('legacy import [-.5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//-0.5/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('legacy import [+3]', 'ok');
        Observer.Expect('legacy import [+3] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//3/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('legacy import [ 4.25 ]', 'ok');
        Observer.Expect('legacy import [ 4.25 ] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//4.25/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('legacy import [1 000.5]', 'error:The value "1 000.5" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('legacy import [1 000.5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('legacy import [abc]', 'error:The value "abc" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('legacy import [abc] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('legacy import [12345678901234567890.123456789012345678]', 'error:The value "12345678901234567890.123456789012345678" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('legacy import [12345678901234567890.123456789012345678] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('legacy import [0.000000000000000001234]', 'ok');
        Observer.Expect('legacy import [0.000000000000000001234] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//0.000000000000000001/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Import_VariableText()
    begin
        Imp('vt import [1.005]', 94368, '7,seven,1.005' + Helper.CrLf());
        Imp('vt import [2.5000]', 94368, '7,seven,2.5000' + Helper.CrLf());
        Imp('vt import [1e3]', 94368, '7,seven,1e3' + Helper.CrLf());
        Imp('vt import [1E-5]', 94368, '7,seven,1E-5' + Helper.CrLf());
        Imp('vt import [1,5]', 94368, '7,seven,1,5' + Helper.CrLf());
        Imp('vt import [-.5]', 94368, '7,seven,-.5' + Helper.CrLf());
        Imp('vt import [+3]', 94368, '7,seven,+3' + Helper.CrLf());
        Imp('vt import [ 4.25 ]', 94368, '7,seven, 4.25 ' + Helper.CrLf());
        Imp('vt import [1 000.5]', 94368, '7,seven,1 000.5' + Helper.CrLf());
        Imp('vt import [abc]', 94368, '7,seven,abc' + Helper.CrLf());
        Imp('vt import [12345678901234567890.123456789012345678]', 94368, '7,seven,12345678901234567890.123456789012345678' + Helper.CrLf());
        Imp('vt import [0.000000000000000001234]', 94368, '7,seven,0.000000000000000001234' + Helper.CrLf());
        Observer.Expect('vt import [1.005]', 'ok');
        Observer.Expect('vt import [1.005] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/1.005/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt import [2.5000]', 'ok');
        Observer.Expect('vt import [2.5000] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/2.5/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt import [1e3]', 'ok');
        Observer.Expect('vt import [1e3] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/1000/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt import [1E-5]', 'ok');
        Observer.Expect('vt import [1E-5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/0.00001/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt import [1,5]', 'ok');
        Observer.Expect('vt import [1,5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/1/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt import [-.5]', 'ok');
        Observer.Expect('vt import [-.5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/-0.5/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt import [+3]', 'ok');
        Observer.Expect('vt import [+3] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/3/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt import [ 4.25 ]', 'ok');
        Observer.Expect('vt import [ 4.25 ] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/4.25/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt import [1 000.5]', 'error:The value "1 000.5" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('vt import [1 000.5] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt import [abc]', 'error:The value "abc" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('vt import [abc] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt import [12345678901234567890.123456789012345678]', 'error:The value "12345678901234567890.123456789012345678" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('vt import [12345678901234567890.123456789012345678] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt import [0.000000000000000001234]', 'ok');
        Observer.Expect('vt import [0.000000000000000001234] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/0.000000000000000001/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Nested()
    var
        Raw: Text;
    begin
        Helper.Seed();
        Raw := Helper.TryExportRaw(94370, TextEncoding::UTF8);
        Observer.Observe('export nested', Raw);
        Helper.DeleteAll();
        Observer.Observe('roundtrip nested', Helper.TryImport(94370, Raw, false));
        Observer.Observe('roundtrip rows', Helper.Rows() + '#' + Helper.ChildRows());
        Imp('nested doc one', 94370, '7,seven' + Helper.CrLf() + 'c7a' + Helper.CrLf());
        Imp('nested doc two', 94370, '7,seven,c7a' + Helper.CrLf());
        Imp('nested doc three', 94370, '7,seven,c7a' + Helper.CrLf() + '8,eight,c8a' + Helper.CrLf());
        Observer.Expect('export nested', '"1","one","c1a"\r\n"c1b"\r\n\r\n\r\n"2","  two  ","c2a"\r\n\r\n');
        Observer.Expect('roundtrip nested', 'error:The Element <Child> is expected by Min Occurs value: Once. Element received: <Item>.|XmlPortMetadata');
        Observer.Expect('roundtrip rows', '#');
        Observer.Expect('nested doc one', 'error:The Element <Child> is expected by Min Occurs value: Once. Element received: <Item>.|XmlPortMetadata');
        Observer.Expect('nested doc one rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('nested doc two', 'error:The Element <Child> is expected by Min Occurs value: Once. Element received: <Item>.|XmlPortMetadata');
        Observer.Expect('nested doc two rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('nested doc three', 'error:The Element <Child> is expected by Min Occurs value: Once. Element received: <Item>.|XmlPortMetadata');
        Observer.Expect('nested doc three rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_TwoTables()
    var
        Raw: Text;
    begin
        Helper.Seed();
        Raw := Helper.TryExportRaw(94371, TextEncoding::UTF8);
        Observer.Observe('export two tables', Raw);
        Helper.DeleteAll();
        Observer.Observe('roundtrip two tables', Helper.TryImport(94371, Raw, false));
        Observer.Observe('roundtrip rows', Helper.Rows() + '#' + Helper.ChildRows());
        Imp('two tables doc one', 94371, '7,seven' + Helper.CrLf() + '#' + Helper.CrLf() + '1,c' + Helper.CrLf());
        Imp('two tables doc two', 94371, '7,seven' + Helper.CrLf() + '#1,c' + Helper.CrLf());
        Imp('two tables doc three', 94371, '7,seven' + Helper.CrLf());
        Observer.Expect('export two tables', '"1","one"\r\n"2","  two  "#"1","c1a"\r\n"2","c1b"\r\n"3","c2a"');
        Observer.Expect('roundtrip two tables', 'ok');
        Observer.Expect('roundtrip rows', '1/one/0/false//0;2/two/0/false//0;#1/0/c1a;2/0/c1b;3/0/c2a;');
        Observer.Expect('two tables doc one', 'error:The Element <Txt> is expected by Min Occurs value: Once. Element received: <Child>.|XmlPortMetadata');
        Observer.Expect('two tables doc one rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('two tables doc two', 'error:The record in table LT Y83 Child already exists. Identification fields and values: Id=''1''|DB:RecordExists');
        Observer.Expect('two tables doc two rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('two tables doc three', 'error:The Element <Child> is expected by Min Occurs value: Once. Element received: <Root>.|XmlPortMetadata');
        Observer.Expect('two tables doc three rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_NewLineSeparator()
    var
        Raw: Text;
    begin
        Helper.Seed();
        Raw := Helper.TryExportRaw(94372, TextEncoding::UTF8);
        Observer.Observe('export newline', Raw);
        Helper.DeleteAll();
        Observer.Observe('roundtrip newline', Helper.TryImport(94372, Raw, false));
        Observer.Observe('roundtrip rows', Helper.Rows());
        Imp('newline doc crlf', 94372, '7' + Helper.CrLf() + 'seven' + Helper.CrLf() + '7.25' + Helper.CrLf());
        Imp('newline doc lf', 94372, '7' + Lf() + 'seven' + Lf() + '7.25' + Lf());
        Imp('newline doc lf one record', 94372, '7' + Lf() + 'seven' + Lf() + '7.25' + Lf() + '8' + Lf() + 'eight' + Lf() + '8.5' + Lf());
        Imp('newline doc short', 94372, '7' + Lf() + 'seven' + Lf());
        Observer.Expect('export newline', '"1"\r\n"one"\r\n"1.50"\n"2"\r\n"  two  "\r\n"2.01"');
        Observer.Expect('roundtrip newline', 'ok');
        Observer.Expect('roundtrip rows', '1/one/1.5/false//0;2/two/2.01/false//0;');
        Observer.Expect('newline doc crlf', 'ok');
        Observer.Expect('newline doc crlf rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/7.25/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('newline doc lf', 'error:The Element <Name> is expected by Min Occurs value: Once. Element received: <Item>.|XmlPortMetadata');
        Observer.Expect('newline doc lf rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('newline doc lf one record', 'error:The Element <Name> is expected by Min Occurs value: Once. Element received: <Item>.|XmlPortMetadata');
        Observer.Expect('newline doc lf one record rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('newline doc short', 'error:The Element <Name> is expected by Min Occurs value: Once. Element received: <Item>.|XmlPortMetadata');
        Observer.Expect('newline doc short rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_ImportValueCount_1()
    begin
        Imp('vt five values', 94368, '7,seven,7.25,extra1,extra2' + Helper.CrLf());
        Imp('vt two values', 94368, '7,seven' + Helper.CrLf());
        Imp('vt trailing separator', 94368, '7,seven,7.25,' + Helper.CrLf());
        Imp('vt one value', 94368, '7' + Helper.CrLf());
        Imp('vt quoted', 94368, '"7","se,ven","7.25"' + Helper.CrLf());
        Imp('vt empty first line', 94368, Helper.CrLf() + '7,seven,7.25' + Helper.CrLf());
        Observer.Expect('vt five values', 'ok');
        Observer.Expect('vt five values rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/7.25/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt two values', 'error:The Element <Amt> is expected by Min Occurs value: Once. Element received: <Item>.|XmlPortMetadata');
        Observer.Expect('vt two values rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt trailing separator', 'ok');
        Observer.Expect('vt trailing separator rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/7.25/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt one value', 'error:The Element <Name> is expected by Min Occurs value: Once. Element received: <Item>.|XmlPortMetadata');
        Observer.Expect('vt one value rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt quoted', 'ok');
        Observer.Expect('vt quoted rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/se,ven/7.25/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt empty first line', 'error:The Element <Name> is expected by Min Occurs value: Once. Element received: <Item>.|XmlPortMetadata');
        Observer.Expect('vt empty first line rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_ImportValueCount_2()
    begin
        Imp('vt no final newline', 94368, '7,seven,7.25');
        Imp('vt lf only', 94368, '7,seven,7.25' + Lf() + '8,eight,8.5' + Lf());
        Imp('vt invalid integer', 94368, 'x,seven,7.25' + Helper.CrLf());
        Imp('vt five values two rows', 94368, '7,seven,7.25,a,b' + Helper.CrLf() + '8,eight,8.5,c,d,e' + Helper.CrLf());
        Imp('vt empty fields', 94368, ',,' + Helper.CrLf());
        Imp('vt blank document', 94368, '');
        Observer.Expect('vt no final newline', 'ok');
        Observer.Expect('vt no final newline rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/7.25/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt lf only', 'error:The value "7.25 8" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('vt lf only rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt invalid integer', 'error:The value "x" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('vt invalid integer rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt five values two rows', 'ok');
        Observer.Expect('vt five values two rows rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/7.25/false//0;8/eight/8.5/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt empty fields', 'ok');
        Observer.Expect('vt empty fields rows', '0//0/false//0;1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('vt blank document', 'error:Cannot import the specified XML document because the file is empty.|XmlPortData');
        Observer.Expect('vt blank document rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_VT_German()
    begin
        ImpLang('vt german flag [Ja]', 94373, '7,Ja,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german flag [Nein]', 94373, '7,Nein,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german flag [Yes]', 94373, '7,Yes,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german flag [No]', 94373, '7,No,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german flag [Wahr]', 94373, '7,Wahr,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german flag [Falsch]', 94373, '7,Falsch,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german flag [true]', 94373, '7,true,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german flag [false]', 94373, '7,false,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german flag [TRUE]', 94373, '7,TRUE,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german flag [1]', 94373, '7,1,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german flag [0]', 94373, '7,0,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german flag [x]', 94373, '7,x,2024-12-31,7.25' + Helper.CrLf(), 1031);
        Observer.Expect('vt german flag [Ja]', 'ok');
        Observer.Expect('vt german flag [Ja] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt german flag [Nein]', 'ok');
        Observer.Expect('vt german flag [Nein] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('vt german flag [Yes]', 'error:Der Wert „Yes“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Expect('vt german flag [Yes] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt german flag [No]', 'error:Der Wert „No“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Expect('vt german flag [No] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt german flag [Wahr]', 'error:Der Wert „Wahr“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Expect('vt german flag [Wahr] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt german flag [Falsch]', 'error:Der Wert „Falsch“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Expect('vt german flag [Falsch] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt german flag [true]', 'ok');
        Observer.Expect('vt german flag [true] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt german flag [false]', 'ok');
        Observer.Expect('vt german flag [false] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('vt german flag [TRUE]', 'ok');
        Observer.Expect('vt german flag [TRUE] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt german flag [1]', 'ok');
        Observer.Expect('vt german flag [1] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt german flag [0]', 'ok');
        Observer.Expect('vt german flag [0] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('vt german flag [x]', 'error:Der Wert „x“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Expect('vt german flag [x] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_VT_English()
    begin
        ImpLang('vt english flag [Ja]', 94373, '7,Ja,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english flag [Nein]', 94373, '7,Nein,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english flag [Yes]', 94373, '7,Yes,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english flag [No]', 94373, '7,No,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english flag [Wahr]', 94373, '7,Wahr,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english flag [Falsch]', 94373, '7,Falsch,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english flag [true]', 94373, '7,true,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english flag [false]', 94373, '7,false,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english flag [TRUE]', 94373, '7,TRUE,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english flag [1]', 94373, '7,1,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english flag [0]', 94373, '7,0,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english flag [x]', 94373, '7,x,2024-12-31,7.25' + Helper.CrLf(), 1033);
        Observer.Expect('vt english flag [Ja]', 'error:The value "Ja" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('vt english flag [Ja] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt english flag [Nein]', 'error:The value "Nein" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('vt english flag [Nein] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt english flag [Yes]', 'ok');
        Observer.Expect('vt english flag [Yes] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt english flag [No]', 'ok');
        Observer.Expect('vt english flag [No] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('vt english flag [Wahr]', 'error:The value "Wahr" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('vt english flag [Wahr] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt english flag [Falsch]', 'error:The value "Falsch" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('vt english flag [Falsch] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt english flag [true]', 'ok');
        Observer.Expect('vt english flag [true] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt english flag [false]', 'ok');
        Observer.Expect('vt english flag [false] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('vt english flag [TRUE]', 'ok');
        Observer.Expect('vt english flag [TRUE] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt english flag [1]', 'ok');
        Observer.Expect('vt english flag [1] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt english flag [0]', 'ok');
        Observer.Expect('vt english flag [0] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('vt english flag [x]', 'error:The value "x" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('vt english flag [x] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_XML_German()
    begin
        ImpLang('xml german flag [Ja]', 94374, '<Root><Item><Id>7</Id><Flag>Ja</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german flag [Nein]', 94374, '<Root><Item><Id>7</Id><Flag>Nein</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german flag [Yes]', 94374, '<Root><Item><Id>7</Id><Flag>Yes</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german flag [No]', 94374, '<Root><Item><Id>7</Id><Flag>No</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german flag [Wahr]', 94374, '<Root><Item><Id>7</Id><Flag>Wahr</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german flag [Falsch]', 94374, '<Root><Item><Id>7</Id><Flag>Falsch</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german flag [true]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german flag [false]', 94374, '<Root><Item><Id>7</Id><Flag>false</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german flag [TRUE]', 94374, '<Root><Item><Id>7</Id><Flag>TRUE</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german flag [1]', 94374, '<Root><Item><Id>7</Id><Flag>1</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german flag [0]', 94374, '<Root><Item><Id>7</Id><Flag>0</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german flag [x]', 94374, '<Root><Item><Id>7</Id><Flag>x</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        Observer.Expect('xml german flag [Ja]', 'ok');
        Observer.Expect('xml german flag [Ja] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml german flag [Nein]', 'ok');
        Observer.Expect('xml german flag [Nein] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('xml german flag [Yes]', 'error:Der Wert „Yes“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Expect('xml german flag [Yes] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml german flag [No]', 'error:Der Wert „No“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Expect('xml german flag [No] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml german flag [Wahr]', 'error:Der Wert „Wahr“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Expect('xml german flag [Wahr] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml german flag [Falsch]', 'error:Der Wert „Falsch“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Expect('xml german flag [Falsch] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml german flag [true]', 'ok');
        Observer.Expect('xml german flag [true] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml german flag [false]', 'ok');
        Observer.Expect('xml german flag [false] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('xml german flag [TRUE]', 'ok');
        Observer.Expect('xml german flag [TRUE] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml german flag [1]', 'ok');
        Observer.Expect('xml german flag [1] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml german flag [0]', 'ok');
        Observer.Expect('xml german flag [0] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('xml german flag [x]', 'error:Der Wert „x“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Expect('xml german flag [x] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_XML_English()
    begin
        ImpLang('xml english flag [Ja]', 94374, '<Root><Item><Id>7</Id><Flag>Ja</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english flag [Nein]', 94374, '<Root><Item><Id>7</Id><Flag>Nein</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english flag [Yes]', 94374, '<Root><Item><Id>7</Id><Flag>Yes</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english flag [No]', 94374, '<Root><Item><Id>7</Id><Flag>No</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english flag [Wahr]', 94374, '<Root><Item><Id>7</Id><Flag>Wahr</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english flag [Falsch]', 94374, '<Root><Item><Id>7</Id><Flag>Falsch</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english flag [true]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english flag [false]', 94374, '<Root><Item><Id>7</Id><Flag>false</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english flag [TRUE]', 94374, '<Root><Item><Id>7</Id><Flag>TRUE</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english flag [1]', 94374, '<Root><Item><Id>7</Id><Flag>1</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english flag [0]', 94374, '<Root><Item><Id>7</Id><Flag>0</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english flag [x]', 94374, '<Root><Item><Id>7</Id><Flag>x</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        Observer.Expect('xml english flag [Ja]', 'error:The value "Ja" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('xml english flag [Ja] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml english flag [Nein]', 'error:The value "Nein" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('xml english flag [Nein] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml english flag [Yes]', 'ok');
        Observer.Expect('xml english flag [Yes] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml english flag [No]', 'ok');
        Observer.Expect('xml english flag [No] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('xml english flag [Wahr]', 'error:The value "Wahr" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('xml english flag [Wahr] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml english flag [Falsch]', 'error:The value "Falsch" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('xml english flag [Falsch] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml english flag [true]', 'ok');
        Observer.Expect('xml english flag [true] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml english flag [false]', 'ok');
        Observer.Expect('xml english flag [false] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('xml english flag [TRUE]', 'ok');
        Observer.Expect('xml english flag [TRUE] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml english flag [1]', 'ok');
        Observer.Expect('xml english flag [1] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml english flag [0]', 'ok');
        Observer.Expect('xml english flag [0] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/false/2024-12-31/0;');
        Observer.Expect('xml english flag [x]', 'error:The value "x" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('xml english flag [x] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure DateDecimal_VT_German()
    begin
        ImpLang('vt german date [31.12.2024]', 94373, '7,true,31.12.2024,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german date [12/31/2024]', 94373, '7,true,12/31/2024,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german date [2024-12-31]', 94373, '7,true,2024-12-31,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german date [31/12/2024]', 94373, '7,true,31/12/2024,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german date [311224]', 94373, '7,true,311224,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german date [31. Dezember 2024]', 94373, '7,true,31. Dezember 2024,7.25' + Helper.CrLf(), 1031);
        ImpLang('vt german amount [7,25]', 94373, '7,true,2024-12-31,"7,25"' + Helper.CrLf(), 1031);
        ImpLang('vt german amount [7.25]', 94373, '7,true,2024-12-31,"7.25"' + Helper.CrLf(), 1031);
        Observer.Expect('vt german date [31.12.2024]', 'error:Das Format Date „31.12.2024“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Evaluate');
        Observer.Expect('vt german date [31.12.2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt german date [12/31/2024]', 'ok');
        Observer.Expect('vt german date [12/31/2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt german date [2024-12-31]', 'ok');
        Observer.Expect('vt german date [2024-12-31] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt german date [31/12/2024]', 'error:Das Format Date „31/12/2024“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Evaluate');
        Observer.Expect('vt german date [31/12/2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt german date [311224]', 'error:Das Format Date „311224“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Evaluate');
        Observer.Expect('vt german date [311224] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt german date [31. Dezember 2024]', 'error:Das Format Date „31. Dezember 2024“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Evaluate');
        Observer.Expect('vt german date [31. Dezember 2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt german amount [7,25]', 'ok');
        Observer.Expect('vt german amount [7,25] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//725/true/2024-12-31/0;');
        Observer.Expect('vt german amount [7.25]', 'ok');
        Observer.Expect('vt german amount [7.25] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Verify();
    end;

    [Test]
    procedure DateDecimal_VT_English()
    begin
        ImpLang('vt english date [31.12.2024]', 94373, '7,true,31.12.2024,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english date [12/31/2024]', 94373, '7,true,12/31/2024,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english date [2024-12-31]', 94373, '7,true,2024-12-31,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english date [31/12/2024]', 94373, '7,true,31/12/2024,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english date [311224]', 94373, '7,true,311224,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english date [31. Dezember 2024]', 94373, '7,true,31. Dezember 2024,7.25' + Helper.CrLf(), 1033);
        ImpLang('vt english amount [7,25]', 94373, '7,true,2024-12-31,"7,25"' + Helper.CrLf(), 1033);
        ImpLang('vt english amount [7.25]', 94373, '7,true,2024-12-31,"7.25"' + Helper.CrLf(), 1033);
        Observer.Expect('vt english date [31.12.2024]', 'error:The format of the Date ''31.12.2024'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate');
        Observer.Expect('vt english date [31.12.2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt english date [12/31/2024]', 'ok');
        Observer.Expect('vt english date [12/31/2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt english date [2024-12-31]', 'ok');
        Observer.Expect('vt english date [2024-12-31] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('vt english date [31/12/2024]', 'error:The format of the Date ''31/12/2024'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate');
        Observer.Expect('vt english date [31/12/2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt english date [311224]', 'error:The format of the Date ''311224'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate');
        Observer.Expect('vt english date [311224] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt english date [31. Dezember 2024]', 'error:The format of the Date ''31. Dezember 2024'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate');
        Observer.Expect('vt english date [31. Dezember 2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('vt english amount [7,25]', 'ok');
        Observer.Expect('vt english amount [7,25] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//725/true/2024-12-31/0;');
        Observer.Expect('vt english amount [7.25]', 'ok');
        Observer.Expect('vt english amount [7.25] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Verify();
    end;

    [Test]
    procedure DateDecimal_XML_German()
    begin
        ImpLang('xml german date [31.12.2024]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>31.12.2024</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german date [12/31/2024]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>12/31/2024</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german date [2024-12-31]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german date [31/12/2024]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>31/12/2024</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german date [311224]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>311224</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german date [31. Dezember 2024]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>31. Dezember 2024</D><Amt>7.25</Amt></Item></Root>', 1031);
        ImpLang('xml german amount [7,25]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>2024-12-31</D><Amt>7,25</Amt></Item></Root>', 1031);
        ImpLang('xml german amount [7.25]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1031);
        Observer.Expect('xml german date [31.12.2024]', 'error:Das Format Date „31.12.2024“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Evaluate');
        Observer.Expect('xml german date [31.12.2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml german date [12/31/2024]', 'ok');
        Observer.Expect('xml german date [12/31/2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml german date [2024-12-31]', 'ok');
        Observer.Expect('xml german date [2024-12-31] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml german date [31/12/2024]', 'error:Das Format Date „31/12/2024“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Evaluate');
        Observer.Expect('xml german date [31/12/2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml german date [311224]', 'error:Das Format Date „311224“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Evaluate');
        Observer.Expect('xml german date [311224] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml german date [31. Dezember 2024]', 'error:Das Format Date „31. Dezember 2024“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Evaluate');
        Observer.Expect('xml german date [31. Dezember 2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml german amount [7,25]', 'ok');
        Observer.Expect('xml german amount [7,25] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//725/true/2024-12-31/0;');
        Observer.Expect('xml german amount [7.25]', 'ok');
        Observer.Expect('xml german amount [7.25] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Verify();
    end;

    [Test]
    procedure DateDecimal_XML_English()
    begin
        ImpLang('xml english date [31.12.2024]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>31.12.2024</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english date [12/31/2024]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>12/31/2024</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english date [2024-12-31]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english date [31/12/2024]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>31/12/2024</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english date [311224]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>311224</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english date [31. Dezember 2024]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>31. Dezember 2024</D><Amt>7.25</Amt></Item></Root>', 1033);
        ImpLang('xml english amount [7,25]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>2024-12-31</D><Amt>7,25</Amt></Item></Root>', 1033);
        ImpLang('xml english amount [7.25]', 94374, '<Root><Item><Id>7</Id><Flag>true</Flag><D>2024-12-31</D><Amt>7.25</Amt></Item></Root>', 1033);
        Observer.Expect('xml english date [31.12.2024]', 'error:The format of the Date ''31.12.2024'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate');
        Observer.Expect('xml english date [31.12.2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml english date [12/31/2024]', 'ok');
        Observer.Expect('xml english date [12/31/2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml english date [2024-12-31]', 'ok');
        Observer.Expect('xml english date [2024-12-31] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Expect('xml english date [31/12/2024]', 'error:The format of the Date ''31/12/2024'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate');
        Observer.Expect('xml english date [31/12/2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml english date [311224]', 'error:The format of the Date ''311224'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate');
        Observer.Expect('xml english date [311224] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml english date [31. Dezember 2024]', 'error:The format of the Date ''31. Dezember 2024'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate');
        Observer.Expect('xml english date [31. Dezember 2024] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('xml english amount [7,25]', 'ok');
        Observer.Expect('xml english amount [7,25] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//725/true/2024-12-31/0;');
        Observer.Expect('xml english amount [7.25]', 'ok');
        Observer.Expect('xml english amount [7.25] rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7//7.25/true/2024-12-31/0;');
        Observer.Verify();
    end;

    [Test]
    procedure Export_German_Session()
    var
        Raw: Text;
    begin
        Helper.Seed();
        Observer.Observe('xml export german', ExpLang(94374, 1031));
        Observer.Observe('xml export english', ExpLang(94374, 1033));
        Observer.Observe('vt export german', ExpLangRaw(94368, 1031));
        Observer.Observe('vt export english', ExpLangRaw(94368, 1033));
        Observer.Expect('xml export german', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Flag>Ja</Flag>|    <D>03/05/24</D>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Flag>Nein</Flag>|    <D />|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('xml export english', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Flag>Yes</Flag>|    <D>03/05/24</D>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Flag>No</Flag>|    <D />|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('vt export german', '"1","one","1.50"\r\n"2","  two  ","2.01"');
        Observer.Expect('vt export english', '"1","one","1.50"\r\n"2","  two  ","2.01"');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_Export_Without_Destination()
    begin
        Observer.Observe('export without destination', ExportNoDestination());
        Observer.Expect('export without destination', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_Export_After_SetSource()
    begin
        Observer.Observe('export after setsource', ExportAfterSetSource());
        Observer.Expect('export after setsource', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_Static_Export_Of_Import_Only_Port()
    begin
        Observer.Observe('static export of import only port', ExportStatic(94373));
        Observer.Expect('static export of import only port', 'error:The XMLPort ''LT Y83 VT Bool Date'' is designed for import only.|XmlPortImportDirection');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_Static_Import_Of_Export_Only_Port()
    begin
        Observer.Observe('static import of export only port', ImportStatic(94369));
        Observer.Expect('static import of export only port', 'error:The XMLPort ''LT Y83 Fixed Export'' is designed for export only.|XmlPortExportDirection');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_Instance_Export_Of_Import_Only_Port()
    begin
        Observer.Observe('instance export of import only port', ExportInstanceImportOnly());
        Observer.Expect('instance export of import only port', 'error:The XMLPort ''LT Y83 VT Bool Date'' is designed for import only.|XmlPortImportDirection');
        Observer.Verify();
    end;

    [Test]
    procedure Static_Undeclared_Id()
    begin
        Observer.Observe('export 94399', ExportStatic(94399));
        Observer.Observe('import 94399', ImportStatic(94399));
        Observer.Observe('run 94399', RunStatic(94399));
        Observer.Observe('export codeunit id', ExportStatic(94333));
        Observer.Observe('import table id', ImportStatic(94330));
        Observer.Observe('export 0', ExportStatic(0));
        Observer.Observe('run codeunit id', RunStatic(94333));
        Observer.Observe('export 2000000000', ExportStatic(2000000000));
        Observer.Expect('export 94399', 'error:You tried to invoke the XmlPort object with the ID 94399 from the object LT Y83 Misc Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('import 94399', 'error:You tried to invoke the XmlPort object with the ID 94399 from the object LT Y83 Misc Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('run 94399', 'error:You tried to invoke the XmlPort object with the ID 94399 from the object LT Y83 Misc Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('export codeunit id', 'error:You tried to invoke the XmlPort object with the ID 94333 from the object LT Y83 Misc Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('import table id', 'error:You tried to invoke the XmlPort object with the ID 94330 from the object LT Y83 Misc Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('export 0', 'error:You tried to invoke the XmlPort object with the ID 0 from the object LT Y83 Misc Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('run codeunit id', 'error:You tried to invoke the XmlPort object with the ID 94333 from the object LT Y83 Misc Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('export 2000000000', 'error:You tried to invoke the XmlPort object with the ID 2000000000 from the object LT Y83 Misc Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Import()
    begin
        ImpTf('tf []', '<Root><Row><Id>7</Id><Tf></Tf></Row></Root>');
        ImpTf('tf [abc]', '<Root><Row><Id>7</Id><Tf>abc</Tf></Row></Root>');
        ImpTf('tf [WHERE(Id=CONST(1))]', '<Root><Row><Id>7</Id><Tf>WHERE(Id=CONST(1))</Tf></Row></Root>');
        ImpTf('tf [Id=1]', '<Root><Row><Id>7</Id><Tf>Id=1</Tf></Row></Root>');
        ImpTf('tf [LT Y83 Item: Id=1]', '<Root><Row><Id>7</Id><Tf>LT Y83 Item: Id=1</Tf></Row></Root>');
        ImpTf('tf [LT Y83 Item: Zz=1]', '<Root><Row><Id>7</Id><Tf>LT Y83 Item: Zz=1</Tf></Row></Root>');
        ImpTf('tf [Id=<abc]', '<Root><Row><Id>7</Id><Tf>Id=&lt;abc</Tf></Row></Root>');
        ImpTf('tf [<&>]', '<Root><Row><Id>7</Id><Tf>&lt;&amp;></Tf></Row></Root>');
        ImpTf('tf [WHERE(Id=FILTER(1..2))]', '<Root><Row><Id>7</Id><Tf>WHERE(Id=FILTER(1..2))</Tf></Row></Root>');
        Observer.Expect('tf []', 'ok');
        Observer.Expect('tf [] rows', '7/;');
        Observer.Expect('tf [abc]', 'error:The value "abc" can''t be evaluated into type TableFilter.|Evaluate');
        Observer.Expect('tf [abc] rows', '');
        Observer.Expect('tf [WHERE(Id=CONST(1))]', 'error:The value "WHERE(Id=CONST(1))" can''t be evaluated into type TableFilter.|Evaluate');
        Observer.Expect('tf [WHERE(Id=CONST(1))] rows', '');
        Observer.Expect('tf [Id=1]', 'error:The value "Id=1" can''t be evaluated into type TableFilter.|Evaluate');
        Observer.Expect('tf [Id=1] rows', '');
        Observer.Expect('tf [LT Y83 Item: Id=1]', 'ok');
        Observer.Expect('tf [LT Y83 Item: Id=1] rows', '7/LT Y83 Item: Id=1;');
        Observer.Expect('tf [LT Y83 Item: Zz=1]', 'error:The value "LT Y83 Item: Zz=1" can''t be evaluated into type TableFilter. The supplied field number ''Zz'' cannot be found in the ''LT Y83 Item'' table.|Evaluate:FieldNotFound');
        Observer.Expect('tf [LT Y83 Item: Zz=1] rows', '');
        Observer.Expect('tf [Id=<abc]', 'error:The value "Id=<abc" can''t be evaluated into type TableFilter.|Evaluate');
        Observer.Expect('tf [Id=<abc] rows', '');
        Observer.Expect('tf [<&>]', 'error:The value "<&>" can''t be evaluated into type TableFilter.|Evaluate');
        Observer.Expect('tf [<&>] rows', '');
        Observer.Expect('tf [WHERE(Id=FILTER(1..2))]', 'error:The value "WHERE(Id=FILTER(1..2))" can''t be evaluated into type TableFilter.|Evaluate');
        Observer.Expect('tf [WHERE(Id=FILTER(1..2))] rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Export()
    begin
        ImpTf('seed', '<Root><Row><Id>1</Id><Tf>LT Y83 Item: Id=1</Tf></Row><Row><Id>2</Id><Tf></Tf></Row></Root>');
        Observer.Observe('export', Helper.TryExport(94375, TextEncoding::UTF16));
        Observer.Expect('seed', 'ok');
        Observer.Expect('seed rows', '1/LT Y83 Item: Id=1;2/;');
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Tf>LT Y83 Item: Id=1</Tf>|  </Row>|  <Row>|    <Id>2</Id>|    <Tf />|  </Row>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure RequestFilterFields_Export()
    begin
        Helper.Seed();
        Observer.Observe('static export', Helper.TryExport(94376, TextEncoding::UTF16));
        Observer.Observe('static export request page', Helper.TryExport(94377, TextEncoding::UTF16));
        Observer.Observe('instance export view id 2', ExportView(2));
        Observer.Observe('instance export view id 2 request page', ExportViewPage(2));
        Observer.Observe('instance export view no match', ExportView(9));
        Observer.Expect('static export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Child>|      <Txt>c1a</Txt>|    </Child>|    <Child>|      <Txt>c1b</Txt>|    </Child>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Child>|      <Txt>c2a</Txt>|    </Child>|  </Item>|</Root>|');
        Observer.Expect('static export request page', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|  </Item>|</Root>|');
        Observer.Expect('instance export view id 2', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Child>|      <Txt>c2a</Txt>|    </Child>|  </Item>|</Root>|');
        Observer.Expect('instance export view id 2 request page', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|  </Item>|</Root>|');
        Observer.Expect('instance export view no match', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>0</Id>|    <Name />|    <Child>|      <Txt />|    </Child>|  </Item>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure RequestFilterFields_Import()
    begin
        Imp('static import', 94376, '<Root><Item><Id>7</Id><Name>seven</Name><Child><Txt>t</Txt></Child></Item></Root>');
        Imp('static import request page', 94377, '<Root><Item><Id>7</Id><Name>seven</Name></Item></Root>');
        Observer.Observe('import with view', ImportView());
        Observer.Observe('import with view rows', Helper.Rows() + '#' + Helper.ChildRows());
        Observer.Expect('static import', 'ok');
        Observer.Expect('static import rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/0/false//0;#0/7/t;1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('static import request page', 'ok');
        Observer.Expect('static import request page rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/0/false//0;#1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Expect('import with view', 'ok');
        Observer.Expect('import with view rows', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/0/false//0;#0/7/t;1/1/c1a;2/1/c1b;3/2/c2a;');
        Observer.Verify();
    end;

    [Test]
    procedure ContainerTriggers_Nested()
    begin
        Observer.Observe('export', ContainerExport(94378));
        Observer.Observe('import full', ContainerImport(94378, '<Root><Item><Id>7</Id><Name>seven</Name></Item><Hdr HAttr="ha2"><HCode>hc2</HCode><Inner><InnerVal>iv2</InnerVal></Inner></Hdr></Root>'));
        Observer.Observe('import empty leaf', ContainerImport(94378, '<Root><Item><Id>8</Id><Name>eight</Name></Item><Hdr HAttr=""><HCode /><Inner><InnerVal /></Inner></Hdr></Root>'));
        Observer.Observe('import empty inner', ContainerImport(94378, '<Root><Hdr HAttr="h"><HCode>hc3</HCode><Inner /></Hdr></Root>'));
        Observer.Observe('import no container', ContainerImport(94378, '<Root><Item><Id>9</Id><Name>nine</Name></Item></Root>'));
        Observer.Observe('import no row', ContainerImport(94378, '<Root><Hdr HAttr="h"><HCode>hc4</HCode><Inner><InnerVal>iv4</InnerVal></Inner></Hdr></Root>'));
        Observer.Expect('export', 'log=root-bpv;rw-agr(1);rw-agr(2);hdr-bpv;hattr-bpv;hcode-bpv;inner-bpv;innerval-bpv; text=<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|  </Item>|  <Hdr HAttr="ha">|    <HCode>hc</HCode>|    <Inner>|      <InnerVal>iv</InnerVal>|    </Inner>|  </Hdr>|</Root>|');
        Observer.Expect('import full', 'ok log=hattr-aav(ha2);hcode-aav(hc2);innerval-aav(iv2);inner-aav;hdr-aav;root-aav;');
        Observer.Expect('import empty leaf', 'ok log=hattr-aav();hcode-aav(hc);hcode-aav(hc);innerval-aav(iv);innerval-aav(iv);inner-aav;hdr-aav;root-aav;');
        Observer.Expect('import empty inner', 'error:Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Hdr''. List of possible elements expected: ''Item''.|XmlPortInvalidXml');
        Observer.Expect('import no container', 'error:Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Item, Hdr''.|XmlPortInvalidXml');
        Observer.Expect('import no row', 'error:Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Hdr''. List of possible elements expected: ''Item''.|XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure ContainerTriggers_AttributeOnly()
    begin
        Observer.Observe('export', ContainerExport(94379));
        Observer.Observe('import full', ContainerImport(94379, '<Root><Endpoint SchemeId="GLN2">0099</Endpoint><Party PartyId="p2" /></Root>'));
        Observer.Observe('import empty endpoint', ContainerImport(94379, '<Root><Endpoint SchemeId="X" /><Party PartyId="p4" /></Root>'));
        Observer.Observe('import no scheme', ContainerImport(94379, '<Root><Endpoint>0100</Endpoint><Party PartyId="p3" /></Root>'));
        Observer.Observe('import party with text', ContainerImport(94379, '<Root><Endpoint SchemeId="X">1</Endpoint><Party PartyId="p5">text</Party></Root>'));
        Observer.Expect('export', 'log=ep-bpv;scheme-bpv;party-bpv;partyid-bpv; text=<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Endpoint SchemeId="GLN">0088</Endpoint>|  <Party PartyId="p1" />|</Root>|');
        Observer.Expect('import full', 'ok log=scheme-aav(GLN2);ep-aav(0099);');
        Observer.Expect('import empty endpoint', 'ok log=scheme-aav(X);ep-aav(0088);');
        Observer.Expect('import no scheme', 'error:Imported XML cannot validate with the schema: The required attribute ''SchemeId'' is missing.|XmlPortInvalidXml');
        Observer.Expect('import party with text', 'ok log=scheme-aav(X);ep-aav(1);');
        Observer.Verify();
    end;

    // Characters from 127 up written as {nnn}, so that no raw control or line separator character reaches the source.
    local procedure Vis(Value: Text): Text
    var
        i: Integer;
        Code: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            if Code >= 127 then
                Result += '{' + Format(Code) + '}'
            else
                Result += CopyStr(Value, i, 1);
        end;
        exit(Result);
    end;

    local procedure Lf(): Text
    var
        Result: Text[1];
    begin
        Result[1] := 10;
        exit(Result);
    end;

    local procedure Imp(Name: Text; PortId: Integer; Doc: Text)
    begin
        Helper.Seed();
        Observer.Observe(Name, Helper.TryImport(PortId, Doc, false));
        Observer.Observe(Name + ' rows', Vis(Helper.Rows() + '#' + Helper.ChildRows()));
    end;

    local procedure ImpLang(Name: Text; PortId: Integer; Doc: Text; Language: Integer)
    begin
        Helper.Seed();
        Observer.Observe(Name, Helper.TryImportIn(PortId, Doc, false, Language));
        Observer.Observe(Name + ' rows', Helper.Rows());
    end;

    local procedure ImpTf(Name: Text; Doc: Text)
    var
        Row: Record "LT Y83 Filter Row";
        Result: Text;
    begin
        Row.DeleteAll();
        Commit();
        Observer.Observe(Name, Helper.TryImport(94375, Doc, false));
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + '/' + Format(Row.Tf) + ';';
            until Row.Next() = 0;
        Observer.Observe(Name + ' rows', Result);
    end;

    local procedure ExpChar(Name: Text; PortId: Integer; Code: Integer)
    var
        Item: Record "LT Y83 Item";
        Ch: Text[1];
    begin
        Item.DeleteAll();
        Ch[1] := Code;
        Item.Init();
        Item.Id := 1;
        Item.Name := 'a' + Ch + 'b';
        Item.Insert();
        Commit();
        Observer.Observe(Name, Vis(Helper.TryExportRaw(PortId, TextEncoding::UTF8)));
    end;

    local procedure SeedDecimals()
    var
        Item: Record "LT Y83 Item";
        Amounts: List of [Decimal];
        Amt: Decimal;
        i: Integer;
    begin
        Item.DeleteAll();
        Amounts.Add(1.005);
        Amounts.Add(0.125);
        Amounts.Add(123456.789);
        Amounts.Add(-0.5);
        Amounts.Add(0.00001);
        Amounts.Add(1234567.891234);
        Amounts.Add(100);
        Amounts.Add(0);
        Amounts.Add(2.5);
        foreach Amt in Amounts do begin
            i += 1;
            Item.Init();
            Item.Id := i;
            Item.Name := 'd';
            Item.Amt := Amt;
            Item.Insert();
        end;
        Commit();
    end;

    local procedure ExpLang(PortId: Integer; Language: Integer): Text
    var
        OldLanguage: Integer;
        Result: Text;
    begin
        OldLanguage := GlobalLanguage();
        GlobalLanguage(Language);
        Result := Helper.TryExport(PortId, TextEncoding::UTF16);
        GlobalLanguage(OldLanguage);
        exit(Result);
    end;

    local procedure ExpLangRaw(PortId: Integer; Language: Integer): Text
    var
        OldLanguage: Integer;
        Result: Text;
    begin
        OldLanguage := GlobalLanguage();
        GlobalLanguage(Language);
        Result := Helper.TryExportRaw(PortId, TextEncoding::UTF8);
        GlobalLanguage(OldLanguage);
        exit(Result);
    end;

    local procedure Failed(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoExportNoDestination()
    var
        XP: XmlPort "LT Y83 Dec Xml";
    begin
        XP.Export();
    end;

    local procedure ExportNoDestination(): Text
    begin
        ClearLastError();
        if DoExportNoDestination() then
            exit('ok');
        exit(Failed());
    end;

    [TryFunction]
    local procedure DoImportNoSource()
    var
        XP: XmlPort "LT Y83 Dec Xml";
    begin
        XP.Import();
    end;

    local procedure ImportNoSource(): Text
    begin
        ClearLastError();
        if DoImportNoSource() then
            exit('ok');
        exit(Failed());
    end;

    [TryFunction]
    local procedure DoExportAfterSetSource()
    var
        XP: XmlPort "LT Y83 Dec Xml";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS);
        XP.SetSource(InS);
        XP.Export();
    end;

    local procedure ExportAfterSetSource(): Text
    begin
        ClearLastError();
        if DoExportAfterSetSource() then
            exit('ok');
        exit(Failed());
    end;

    [TryFunction]
    local procedure DoImportAfterSetDestination()
    var
        XP: XmlPort "LT Y83 Dec Xml";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        XP.SetDestination(OutS);
        XP.Import();
    end;

    local procedure ImportAfterSetDestination(): Text
    begin
        ClearLastError();
        if DoImportAfterSetDestination() then
            exit('ok');
        exit(Failed());
    end;

    [TryFunction]
    local procedure DoExportInstanceImportOnly()
    var
        XP: XmlPort "LT Y83 VT Bool Date";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        XP.SetDestination(OutS);
        XP.Export();
    end;

    local procedure ExportInstanceImportOnly(): Text
    begin
        ClearLastError();
        if DoExportInstanceImportOnly() then
            exit('ok');
        exit(Failed());
    end;

    [TryFunction]
    local procedure DoExportStatic(PortId: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(PortId, OutS);
    end;

    local procedure ExportStatic(PortId: Integer): Text
    begin
        ClearLastError();
        if DoExportStatic(PortId) then
            exit('ok');
        exit(Failed());
    end;

    [TryFunction]
    local procedure DoImportStatic(PortId: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS);
        Xmlport.Import(PortId, InS);
    end;

    local procedure ImportStatic(PortId: Integer): Text
    begin
        ClearLastError();
        if DoImportStatic(PortId) then
            exit('ok');
        exit(Failed());
    end;

    [TryFunction]
    local procedure DoRunStatic(PortId: Integer)
    begin
        Xmlport.Run(PortId, false, false);
    end;

    local procedure RunStatic(PortId: Integer): Text
    begin
        ClearLastError();
        if DoRunStatic(PortId) then
            exit('ok');
        exit(Failed());
    end;

    [TryFunction]
    local procedure DoExportView(Id: Integer; var Result: Text)
    var
        XP: XmlPort "LT Y83 Request Filter";
        Item: Record "LT Y83 Item";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Item.SetRange(Id, Id);
        XP.SetTableView(Item);
        TempBlob.CreateOutStream(OutS);
        XP.SetDestination(OutS);
        XP.Export();
        Result := Helper.ReadStream(TempBlob, TextEncoding::UTF16);
    end;

    local procedure ExportView(Id: Integer): Text
    var
        Result: Text;
    begin
        Helper.Seed();
        ClearLastError();
        if DoExportView(Id, Result) then
            exit(Result);
        exit(Failed());
    end;

    [TryFunction]
    local procedure DoExportViewPage(Id: Integer; var Result: Text)
    var
        XP: XmlPort "LT Y83 Request Filter Page";
        Item: Record "LT Y83 Item";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Item.SetRange(Id, Id);
        XP.SetTableView(Item);
        TempBlob.CreateOutStream(OutS);
        XP.SetDestination(OutS);
        XP.Export();
        Result := Helper.ReadStream(TempBlob, TextEncoding::UTF16);
    end;

    local procedure ExportViewPage(Id: Integer): Text
    var
        Result: Text;
    begin
        Helper.Seed();
        ClearLastError();
        if DoExportViewPage(Id, Result) then
            exit(Result);
        exit(Failed());
    end;

    local procedure ImportView(): Text
    begin
        exit(Helper.ImportView());
    end;

    local procedure ContainerExport(PortId: Integer): Text
    begin
        Helper.Seed();
        exit(Helper.ContainerExport(PortId));
    end;

    local procedure ContainerImport(PortId: Integer; Doc: Text): Text
    begin
        Helper.Seed();
        exit(Helper.ContainerImport(PortId, Doc));
    end;
}
