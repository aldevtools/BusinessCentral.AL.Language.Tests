// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); fixtures of Y91XpFixtures.al, ports of Y91XpPorts.al
// Probe: writer Y91. Empty element forms on XML import: <x />, <x></x>, <x> </x> and other spellings of an empty or blank value, for a text element, a text attribute and a field element, with the variable (or the record field) holding an old value, with and without PreserveWhiteSpace.
// BC versions: 27-29

codeunit 94848 "LT Y91 Empty Forms Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y91 Helper";

    [Test]
    procedure Y91_Empty_Default_1()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('selfclosed', Helper.Import(94833, 0, '<Root><A /><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('openclose', Helper.Import(94833, 0, '<Root><A></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('space', Helper.Import(94833, 0, '<Root><A> </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('twospaces', Helper.Import(94833, 0, '<Root><A>  </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('padded', Helper.Import(94833, 0, '<Root><A>  x  </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('charref', Helper.Import(94833, 0, '<Root><A>&#32;</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('cdata_empty', Helper.Import(94833, 0, '<Root><A><![CDATA[]]></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('cdata_space', Helper.Import(94833, 0, '<Root><A><![CDATA[ ]]></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('lf', Helper.Import(94833, 0, '<Root><A>' + Lf() + '</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('comment', Helper.Import(94833, 0, '<Root><A><!-- c --></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Observer.Expect('selfclosed', 'ok log=A(oldA);A(oldA);Att(y);B(z);post A=[oldA] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('openclose', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('space', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('twospaces', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('padded', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('charref', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('cdata_empty', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('cdata_space', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('lf', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('comment', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Empty_Default_2()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('plain', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_selfclosed', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y" /><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_openclose', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y"></B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_space', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y"> </B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_empty', Helper.Import(94833, 0, '<Root><A>x</A><B Att="">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_space', Helper.Import(94833, 0, '<Root><A>x</A><B Att=" ">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_padded', Helper.Import(94833, 0, '<Root><A>x</A><B Att="  p  ">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_empty_selfclosed', Helper.Import(94833, 0, '<Root><A>x</A><B Att="" /><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_missing', Helper.Import(94833, 0, '<Root><A>x</A><B>z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_selfclosed', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name /></Item></Root>'));
        Observer.Expect('plain', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('b_selfclosed', 'ok log=A(x);Att(y);B(oldB);post A=[x] B=[oldB] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('b_openclose', 'ok log=A(x);Att(y);B();post A=[x] B=[] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('b_space', 'ok log=A(x);Att(y);B();post A=[x] B=[] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('att_empty', 'ok log=A(x);Att();B(z);post A=[x] B=[z] Att=[]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('att_space', 'ok log=A(x);Att();B(z);post A=[x] B=[z] Att=[]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('att_padded', 'ok log=A(x);Att(p);B(z);post A=[x] B=[z] Att=[p]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('att_empty_selfclosed', 'ok log=A(x);Att();B(oldB);post A=[x] B=[oldB] Att=[]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('att_missing', 'error:Imported XML cannot validate with the schema: The required attribute ''Att'' is missing.|XmlPortInvalidXml rows=1/one/0;2/two/0;');
        Observer.Expect('n_selfclosed', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Empty_Default_3()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('n_openclose', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name></Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_space', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name> </Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_padded', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>  x  </Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_charref', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>&#32;</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_cdata_space', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name><![CDATA[ ]]></Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_missing', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_plain', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Observer.Expect('n_openclose', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5//0;');
        Observer.Expect('n_space', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5//0;');
        Observer.Expect('n_padded', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/x/0;');
        Observer.Expect('n_charref', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5//0;');
        Observer.Expect('n_cdata_space', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5//0;');
        Observer.Expect('n_missing', 'error:Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Name''.|XmlPortInvalidXml rows=1/one/0;2/two/0;');
        Observer.Expect('n_plain', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Empty_Preserve_1()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('selfclosed', Helper.Import(94834, 0, '<Root><A /><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('openclose', Helper.Import(94834, 0, '<Root><A></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('space', Helper.Import(94834, 0, '<Root><A> </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('twospaces', Helper.Import(94834, 0, '<Root><A>  </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('padded', Helper.Import(94834, 0, '<Root><A>  x  </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('charref', Helper.Import(94834, 0, '<Root><A>&#32;</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('cdata_empty', Helper.Import(94834, 0, '<Root><A><![CDATA[]]></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('cdata_space', Helper.Import(94834, 0, '<Root><A><![CDATA[ ]]></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('lf', Helper.Import(94834, 0, '<Root><A>' + Lf() + '</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('comment', Helper.Import(94834, 0, '<Root><A><!-- c --></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Observer.Expect('selfclosed', 'ok log=A(oldA);A(oldA);Att(y);B(z);post A=[oldA] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('openclose', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('space', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('twospaces', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('padded', 'ok log=A(  x  );Att(y);B(z);post A=[  x  ] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('charref', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('cdata_empty', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('cdata_space', 'ok log=A( );Att(y);B(z);post A=[ ] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('lf', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('comment', 'ok log=A();Att(y);B(z);post A=[] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Empty_Preserve_2()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('plain', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_selfclosed', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y" /><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_openclose', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y"></B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_space', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y"> </B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_empty', Helper.Import(94834, 0, '<Root><A>x</A><B Att="">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_space', Helper.Import(94834, 0, '<Root><A>x</A><B Att=" ">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_padded', Helper.Import(94834, 0, '<Root><A>x</A><B Att="  p  ">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_empty_selfclosed', Helper.Import(94834, 0, '<Root><A>x</A><B Att="" /><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_missing', Helper.Import(94834, 0, '<Root><A>x</A><B>z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_selfclosed', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name /></Item></Root>'));
        Observer.Expect('plain', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('b_selfclosed', 'ok log=A(x);Att(y);B(oldB);post A=[x] B=[oldB] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('b_openclose', 'ok log=A(x);Att(y);B();post A=[x] B=[] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('b_space', 'ok log=A(x);Att(y);B();post A=[x] B=[] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('att_empty', 'ok log=A(x);Att();B(z);post A=[x] B=[z] Att=[]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('att_space', 'ok log=A(x);Att( );B(z);post A=[x] B=[z] Att=[ ]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('att_padded', 'ok log=A(x);Att(  p  );B(z);post A=[x] B=[z] Att=[  p  ]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('att_empty_selfclosed', 'ok log=A(x);Att();B(oldB);post A=[x] B=[oldB] Att=[]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Expect('att_missing', 'error:Imported XML cannot validate with the schema: The required attribute ''Att'' is missing.|XmlPortInvalidXml rows=1/one/0;2/two/0;');
        Observer.Expect('n_selfclosed', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Empty_Preserve_3()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('n_openclose', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name></Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_space', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name> </Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_padded', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>  x  </Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_charref', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>&#32;</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_cdata_space', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name><![CDATA[ ]]></Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_missing', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_plain', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Observer.Expect('n_openclose', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5//0;');
        Observer.Expect('n_space', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5//0;');
        Observer.Expect('n_padded', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/  x  /0;');
        Observer.Expect('n_charref', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5//0;');
        Observer.Expect('n_cdata_space', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/ /0;');
        Observer.Expect('n_missing', 'error:Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Name''.|XmlPortInvalidXml rows=1/one/0;2/two/0;');
        Observer.Expect('n_plain', 'ok log=A(x);Att(y);B(z);post A=[x] B=[z] Att=[y]; rows=1/one/0;2/two/0;5/n/0;');
        Observer.Verify();
    end;

    local procedure Lf(): Text
    var
        Result: Text[1];
    begin
        Result[1] := 10;
        exit(Result);
    end;
}

codeunit 94849 "LT Y91 Root Trigger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y91 Helper";

    [Test]
    procedure Y91_Root_Xml_Export()
    begin
        Helper.Seed();
        Observer.Observe('export mode 0', Helper.Export(94836, 0));
        Observer.Observe('export mode 1', Helper.Export(94836, 1));
        Observer.Observe('export mode 2', Helper.Export(94836, 2));
        Observer.Observe('export mode 3', Helper.Export(94836, 3));
        Observer.Observe('export mode 4', Helper.Export(94836, 4));
        Observer.Expect('export mode 0', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>one</Name>\r\n  </Item>\r\n  <Item>\r\n    <Id>2</Id>\r\n    <Name>two</Name>\r\n  </Item>\r\n</Root> log=pre;root-bpv;agr(1);agr(2);post;');
        Observer.Expect('export mode 1', '<?xml version="1.0" encoding="UTF-16" standalone="no"?> log=pre;root-bpv;post;');
        Observer.Expect('export mode 2', '<?xml version="1.0" encoding="UTF-16" standalone="no"?> log=pre;root-bpv;post;');
        Observer.Expect('export mode 3', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>one</Name>\r\n  </Item>\r\n  <Item>\r\n    <Id>2</Id>\r\n    <Name>two</Name>\r\n  </Item>\r\n</Root> log=pre;root-bpv;agr(1);agr(2);post;');
        Observer.Expect('export mode 4', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Name>one</Name>\r\n  </Item>\r\n  <Item>\r\n    <Id>2</Id>\r\n    <Name>two</Name>\r\n  </Item>\r\n</Root> log=pre;root-bpv;agr(1);agr(2);post;');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Root_Xml_Import()
    begin
        Helper.Seed();
        Observer.Observe('import mode 0', Helper.Import(94836, 0, '<Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('import mode 1', Helper.Import(94836, 1, '<Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('import mode 2', Helper.Import(94836, 2, '<Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('import mode 3', Helper.Import(94836, 3, '<Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('import mode 4', Helper.Import(94836, 4, '<Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Observer.Expect('import mode 0', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 1', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 2', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 3', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 4', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Root_VT_Export()
    begin
        Helper.Seed();
        Observer.Observe('export mode 0', Helper.Export(94837, 0));
        Observer.Observe('export mode 1', Helper.Export(94837, 1));
        Observer.Observe('export mode 2', Helper.Export(94837, 2));
        Observer.Observe('export mode 3', Helper.Export(94837, 3));
        Observer.Observe('export mode 4', Helper.Export(94837, 4));
        Observer.Expect('export mode 0', '"1","one"\r\n"2","two" log=pre;root-bpv;agr(1);agr(2);post;');
        Observer.Expect('export mode 1', ' log=pre;root-bpv;post;');
        Observer.Expect('export mode 2', ' log=pre;root-bpv;post;');
        Observer.Expect('export mode 3', '"1","one"\r\n"2","two" log=pre;root-bpv;agr(1);agr(2);post;');
        Observer.Expect('export mode 4', '"1","one"\r\n"2","two" log=pre;root-bpv;agr(1);agr(2);post;');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Root_VT_Import()
    begin
        Helper.Seed();
        Observer.Observe('import mode 0', Helper.Import(94837, 0, '7,seven'));
        Helper.Seed();
        Observer.Observe('import mode 1', Helper.Import(94837, 1, '7,seven'));
        Helper.Seed();
        Observer.Observe('import mode 2', Helper.Import(94837, 2, '7,seven'));
        Helper.Seed();
        Observer.Observe('import mode 3', Helper.Import(94837, 3, '7,seven'));
        Helper.Seed();
        Observer.Observe('import mode 4', Helper.Import(94837, 4, '7,seven'));
        Observer.Expect('import mode 0', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 1', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 2', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 3', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 4', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Root_Fixed_Export()
    begin
        Helper.Seed();
        Observer.Observe('export mode 0', Helper.Export(94838, 0));
        Observer.Observe('export mode 1', Helper.Export(94838, 1));
        Observer.Observe('export mode 2', Helper.Export(94838, 2));
        Observer.Observe('export mode 3', Helper.Export(94838, 3));
        Observer.Observe('export mode 4', Helper.Export(94838, 4));
        Observer.Expect('export mode 0', '1   one   \r\n2   two    log=pre;root-bpv;agr(1);agr(2);post;');
        Observer.Expect('export mode 1', ' log=pre;root-bpv;post;');
        Observer.Expect('export mode 2', ' log=pre;root-bpv;post;');
        Observer.Expect('export mode 3', '1   one   \r\n2   two    log=pre;root-bpv;agr(1);agr(2);post;');
        Observer.Expect('export mode 4', '1   one   \r\n2   two    log=pre;root-bpv;agr(1);agr(2);post;');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Root_Fixed_Import()
    begin
        Helper.Seed();
        Observer.Observe('import mode 0', Helper.Import(94838, 0, '   7seven '));
        Helper.Seed();
        Observer.Observe('import mode 1', Helper.Import(94838, 1, '   7seven '));
        Helper.Seed();
        Observer.Observe('import mode 2', Helper.Import(94838, 2, '   7seven '));
        Helper.Seed();
        Observer.Observe('import mode 3', Helper.Import(94838, 3, '   7seven '));
        Helper.Seed();
        Observer.Observe('import mode 4', Helper.Import(94838, 4, '   7seven '));
        Observer.Expect('import mode 0', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 1', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 2', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 3', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Expect('import mode 4', 'ok log=pre;bir(7);root-aav;post; rows=1/one/0;2/two/0;7/seven/0;');
        Observer.Verify();
    end;

}

codeunit 94850 "LT Y91 Misc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y91 Helper";

    [Test]
    procedure Y91_Decimal_Export_Negative_Xml()
    begin
        SeedDecimals();
        Observer.Observe('export', Helper.Export(94839, 0));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Amt>-0.01</Amt>\r\n    <Amt5>-0.005</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>2</Id>\r\n    <Amt>0.01</Amt>\r\n    <Amt5>0.005</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>3</Id>\r\n    <Amt>-0.02</Amt>\r\n    <Amt5>-0.015</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>4</Id>\r\n    <Amt>0.02</Amt>\r\n    <Amt5>0.015</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>5</Id>\r\n    <Amt>-0.13</Amt>\r\n    <Amt5>-0.125</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>6</Id>\r\n    <Amt>0.13</Amt>\r\n    <Amt5>0.125</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>7</Id>\r\n    <Amt>-1.01</Amt>\r\n    <Amt5>-1.005</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>8</Id>\r\n    <Amt>-2.00</Amt>\r\n    <Amt5>-2.004</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>9</Id>\r\n    <Amt>-2.50</Amt>\r\n    <Amt5>-2.5</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>10</Id>\r\n    <Amt>-0.00</Amt>\r\n    <Amt5>-0.0049</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>11</Id>\r\n    <Amt>-0.00</Amt>\r\n    <Amt5>-0.001</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>12</Id>\r\n    <Amt>-1,234.57</Amt>\r\n    <Amt5>-1,234.5678</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>13</Id>\r\n    <Amt>-1,234,567.90</Amt>\r\n    <Amt5>-1,234,567.895</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>14</Id>\r\n    <Amt>-1.00</Amt>\r\n    <Amt5>-0.995</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>15</Id>\r\n    <Amt>-100,000,000.00</Amt>\r\n    <Amt5>-99,999,999.995</Amt5>\r\n  </Item>\r\n</Root> log=');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Decimal_Export_Negative_Legacy()
    begin
        SeedDecimals();
        Observer.Observe('export', Helper.Export(94842, 0));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Amt>-0.01</Amt>\r\n    <Amt5>-0.005</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>2</Id>\r\n    <Amt>0.01</Amt>\r\n    <Amt5>0.005</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>3</Id>\r\n    <Amt>-0.02</Amt>\r\n    <Amt5>-0.015</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>4</Id>\r\n    <Amt>0.02</Amt>\r\n    <Amt5>0.015</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>5</Id>\r\n    <Amt>-0.13</Amt>\r\n    <Amt5>-0.125</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>6</Id>\r\n    <Amt>0.13</Amt>\r\n    <Amt5>0.125</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>7</Id>\r\n    <Amt>-1.01</Amt>\r\n    <Amt5>-1.005</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>8</Id>\r\n    <Amt>-2.00</Amt>\r\n    <Amt5>-2.004</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>9</Id>\r\n    <Amt>-2.50</Amt>\r\n    <Amt5>-2.5</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>10</Id>\r\n    <Amt>-0.00</Amt>\r\n    <Amt5>-0.0049</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>11</Id>\r\n    <Amt>-0.00</Amt>\r\n    <Amt5>-0.001</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>12</Id>\r\n    <Amt>-1,234.57</Amt>\r\n    <Amt5>-1,234.5678</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>13</Id>\r\n    <Amt>-1,234,567.90</Amt>\r\n    <Amt5>-1,234,567.895</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>14</Id>\r\n    <Amt>-1.00</Amt>\r\n    <Amt5>-0.995</Amt5>\r\n  </Item>\r\n  <Item>\r\n    <Id>15</Id>\r\n    <Amt>-100,000,000.00</Amt>\r\n    <Amt5>-99,999,999.995</Amt5>\r\n  </Item>\r\n</Root> log=');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Decimal_Export_Negative_VT()
    begin
        SeedDecimals();
        Observer.Observe('export', Helper.Export(94840, 0));
        Observer.Expect('export', '"1","-0.01","-0.005"\r\n"2","0.01","0.005"\r\n"3","-0.02","-0.015"\r\n"4","0.02","0.015"\r\n"5","-0.13","-0.125"\r\n"6","0.13","0.125"\r\n"7","-1.01","-1.005"\r\n"8","-2.00","-2.004"\r\n"9","-2.50","-2.5"\r\n"10","-0.00","-0.0049"\r\n"11","-0.00","-0.001"\r\n"12","-1,234.57","-1,234.5678"\r\n"13","-1,234,567.90","-1,234,567.895"\r\n"14","-1.00","-0.995"\r\n"15","-100,000,000.00","-99,999,999.995" log=');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Decimal_Export_Negative_Fixed()
    begin
        SeedDecimals();
        Observer.Observe('export', Helper.Export(94841, 0));
        Observer.Expect('export', '1   -0.01       -0.005      \r\n2   0.01        0.005       \r\n3   -0.02       -0.015      \r\n4   0.02        0.015       \r\n5   -0.13       -0.125      \r\n6   0.13        0.125       \r\n7   -1.01       -1.005      \r\n8   -2.00       -2.004      \r\n9   -2.50       -2.5        \r\n10  -0.00       -0.0049     \r\n11  -0.00       -0.001      \r\n12  -1,234.57   -1,234.5678 \r\n13  -1,234,567.9-1,234,567.8\r\n14  -1.00       -0.995      \r\n15  -100,000,000-99,999,999. log=');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Width_Text_Xml()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.Export(94843, 0));
        Observer.Observe('import long', Helper.Import(94843, 0, '<Root><T3>abcdefghij</T3><T0>abcdefghij</T0><T5 At4="abcdefghij">abcdefghij</T5></Root>'));
        Observer.Observe('import short', Helper.Import(94843, 0, '<Root><T3>a</T3><T0>a</T0><T5 At4="a">a</T5></Root>'));
        Observer.Observe('import empty', Helper.Import(94843, 0, '<Root><T3 /><T0 /><T5 At4="" /></Root>'));
        Observer.Observe('unbound long', Helper.Import(94844, 0, '<Root><Free>abcdefghij</Free></Root>'));
        Observer.Observe('unbound short', Helper.Import(94844, 0, '<Root><Free>a</Free></Root>'));
        Observer.Observe('unbound none', Helper.Import(94844, 0, '<Root></Root>'));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <T3>abcdefg</T3>\r\n  <T0>abcdefg</T0>\r\n  <T5 At4="abcdefg">ab</T5>\r\n</Root> log=post T3=[abcdefg] T0=[abcdefg] T5=[ab] At4=[abcdefg];');
        Observer.Expect('import long', 'ok log=T3(abcdefghij);T0(abcdefghij);At4(abcdefghij);T5(abcdefghij);post T3=[abcdefghij] T0=[abcdefghij] T5=[abcdefghij] At4=[abcdefghij]; rows=1/one/0;2/two/0;');
        Observer.Expect('import short', 'ok log=T3(a);T0(a);At4(a);T5(a);post T3=[a] T0=[a] T5=[a] At4=[a]; rows=1/one/0;2/two/0;');
        Observer.Expect('import empty', 'ok log=T3(abcdefg);T3(abcdefg);T0(abcdefg);T0(abcdefg);At4();T5(ab);post T3=[abcdefg] T0=[abcdefg] T5=[ab] At4=[]; rows=1/one/0;2/two/0;');
        Observer.Expect('unbound long', 'ok log=Free(abcdefghij);post Free=[abcdefghij]; rows=1/one/0;2/two/0;');
        Observer.Expect('unbound short', 'ok log=Free(a);post Free=[a]; rows=1/one/0;2/two/0;');
        Observer.Expect('unbound none', 'ok log=post Free=[]; rows=1/one/0;2/two/0;');
        Observer.Verify();
    end;

    local procedure SeedDecimals()
    var
        Item: Record "LT Y91 Item";
        Amounts: List of [Decimal];
        Amt: Decimal;
        i: Integer;
    begin
        Item.DeleteAll();
        Amounts.Add(-0.005);
        Amounts.Add(0.005);
        Amounts.Add(-0.015);
        Amounts.Add(0.015);
        Amounts.Add(-0.125);
        Amounts.Add(0.125);
        Amounts.Add(-1.005);
        Amounts.Add(-2.004);
        Amounts.Add(-2.5);
        Amounts.Add(-0.0049);
        Amounts.Add(-0.001);
        Amounts.Add(-1234.5678);
        Amounts.Add(-1234567.895);
        Amounts.Add(-0.995);
        Amounts.Add(-99999999.995);
        foreach Amt in Amounts do begin
            i += 1;
            Item.Init();
            Item.Id := i;
            Item.Name := 'd';
            Item.Amt := Amt;
            Item.Amt5 := Amt;
            Item.Insert();
        end;
        Commit();
    end;
}

codeunit 94851 "LT Y91 Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y91 Helper";
        Log: Codeunit "LT Y91 Run Log";

    [Test]
    procedure Y91_Run_Both()
    begin
        Seed();
        Observer.Observe('both static', RunPort(94845, 1, false));
        Observer.Observe('both static import', RunPort(94845, 1, true));
        Observer.Observe('both instance', RunPort(94845, 2, false));
        Observer.Observe('both view', RunPort(94845, 3, false));
        Observer.Expect('both static', 'no direction error hits=Both pre;Both agr 1;Both agr 2; rows=2');
        Observer.Expect('both static import', 'no direction error hits= rows=2');
        Observer.Expect('both instance', 'no direction error hits= rows=2');
        Observer.Expect('both view', 'no direction error hits= rows=2');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Run_Export()
    begin
        Seed();
        Observer.Observe('export static', RunPort(94846, 1, false));
        Observer.Observe('export static import', RunPort(94846, 1, true));
        Observer.Observe('export instance', RunPort(94846, 2, false));
        Observer.Observe('export view', RunPort(94846, 3, false));
        Observer.Expect('export static', 'no direction error hits=Export pre;Export agr 1;Export agr 2; rows=2');
        Observer.Expect('export static import', 'error:The XMLPort ''LT Y91 Run Export'' is designed for export only.|XmlPortExportDirection hits= rows=2');
        Observer.Expect('export instance', 'no direction error hits=Export pre;Export agr 1;Export agr 2; rows=2');
        Observer.Expect('export view', 'no direction error hits=Export pre;Export agr 2; rows=2');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_Run_Import()
    begin
        Seed();
        Observer.Observe('import static', RunPort(94847, 1, false));
        Observer.Observe('import static import', RunPort(94847, 1, true));
        Observer.Observe('import instance', RunPort(94847, 2, false));
        Observer.Expect('import static', 'error:The XMLPort ''LT Y91 Run Import'' is designed for import only.|XmlPortImportDirection hits= rows=2');
        Observer.Expect('import static import', 'no direction error hits= rows=2');
        Observer.Expect('import instance', 'no direction error hits= rows=2');
        Observer.Verify();
    end;

    local procedure Seed()
    var
        Item: Record "LT Y91 Item";
    begin
        Item.DeleteAll();
        Item.Init();
        Item.Id := 1;
        Item.Name := 'one';
        Item.Insert();
        Item.Id := 2;
        Item.Name := 'two';
        Item.Insert();
        Commit();
        Log.Take();
    end;

    // ok or error:<text>|<code>, then the hits of the port triggers and the number of rows.
    local procedure RunPort(PortId: Integer; Mode: Integer; ImportFlag: Boolean): Text
    var
        Input: Record "LT Y91 Input" temporary;
        Item: Record "LT Y91 Item";
        Result: Text;
    begin
        Commit();
        Input.Init();
        Input.Id := 1;
        Input.PortId := PortId;
        Input.Mode := Mode;
        Input.ImportFlag := ImportFlag;
        Input.Insert();
        ClearLastError();
        // Whether the call can reach a file (download of the export, upload of the import) depends on the host: Windows 27.5 gives
        // CallbackNotAllowed, Windows 28.5 and the Linux export direction go on, the Linux import direction gives NotSupportedFileDialogProvider.
        // So only the error of the port direction is kept; the triggers that ran and the rows are the same everywhere.
        Result := 'no direction error';
        if not Codeunit.Run(Codeunit::"LT Y91 Run Runner", Input) then
            if GetLastErrorCode() in ['XmlPortExportDirection', 'XmlPortImportDirection'] then
                Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        Result += ' hits=' + Log.Take() + ' rows=' + Format(Item.Count());
        exit(Result);
    end;
}

codeunit 94853 "LT Y91 Text In Table Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y91 Helper";

    [Test]
    procedure Y91_TextInTable_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.Export(94852, 0));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Tag>T1</Tag>\r\n    <Name>one</Name>\r\n    <Fixed>fx</Fixed>\r\n    <Blank />\r\n  </Item>\r\n  <Item>\r\n    <Id>2</Id>\r\n    <Tag>T2</Tag>\r\n    <Name>two</Name>\r\n    <Fixed>fx</Fixed>\r\n    <Blank />\r\n  </Item>\r\n</Root> log=agr(1);tag-bpv(1,T1);agr(2);tag-bpv(2,T2);post Tag=[T2] Fixed=[fx] Blank=[];');
        Observer.Verify();
    end;

    [Test]
    procedure Y91_TextInTable_Import()
    begin
        Helper.Seed();
        Observer.Observe('import', Helper.Import(94852, 0, '<Root><Item><Id>7</Id><Tag>a</Tag><Name>seven</Name><Fixed>f7</Fixed></Item><Item><Id>8</Id><Tag /><Name>eight</Name><Fixed></Fixed></Item></Root>'));
        Helper.Seed();
        Observer.Observe('import blank', Helper.Import(94852, 0, '<Root><Item><Id>9</Id><Tag>b</Tag><Name>nine</Name><Fixed>f9</Fixed><Blank>x</Blank></Item></Root>'));
        Helper.Seed();
        Observer.Observe('import missing', Helper.Import(94852, 0, '<Root><Item><Id>10</Id><Name>ten</Name><Fixed>f</Fixed></Item></Root>'));
        Observer.Expect('import', 'ok log=tag-aav(a);bir(7,a,f7);tag-aav(a);tag-aav(a);bir(8,a,);post Tag=[a] Fixed=[] Blank=[]; rows=1/one/0;2/two/0;7/seven/0;8/eight/0;');
        Observer.Expect('import blank', 'ok log=tag-aav(b);bir(9,b,f9);post Tag=[b] Fixed=[f9] Blank=[x]; rows=1/one/0;2/two/0;9/nine/0;');
        Observer.Expect('import missing', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Name''. List of possible elements expected: ''Tag''.|XmlPortInvalidXml rows=1/one/0;2/two/0;');
        Observer.Verify();
    end;
}
