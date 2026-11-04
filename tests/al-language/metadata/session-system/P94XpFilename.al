// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-data-type
// Scope: in-scope
// Fixtures used: P94Fixtures.al (tables 73057-73059, xmlport 73066, helper 73071), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Xmlport.Filename get and set on an instance, its value inside OnPreXmlPort / OnPostXmlPort for export and import
// BC versions: 29 (27 and 28 by CI)

codeunit 73075 "LT P94 Xp Filename"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P94 Helper";

    [Test]
    procedure Fresh_Empty()
    var
        Xp: XmlPort "LT P94 Xml Filename";
    begin
        Observer.Observe('name', '[' + Xp.Filename() + ']');
        Observer.Expect('name', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Set_ReadBack()
    var
        Xp: XmlPort "LT P94 Xml Filename";
    begin
        Xp.Filename('items.xml');
        Observer.Observe('plain', '[' + Xp.Filename() + ']');
        Xp.Filename('');
        Observer.Observe('empty', '[' + Xp.Filename() + ']');
        Xp.Filename('a b.xml');
        Observer.Observe('space', '[' + Xp.Filename() + ']');
        Xp.Filename('dir/sub\name.xml');
        Observer.Observe('slashes', '[' + Xp.Filename() + ']');
        Xp.Filename(PadStr('', 300, 'x'));
        Observer.Observe('longLen', Format(StrLen(Xp.Filename())));
        Xp.Filename('Ä€.xml');
        Observer.Observe('unicode', '[' + Xp.Filename() + ']');
        Observer.Expect('plain', '[items.xml]');
        Observer.Expect('empty', '[]');
        Observer.Expect('space', '[a b.xml]');
        Observer.Expect('slashes', '[dir/sub\name.xml]');
        Observer.Expect('longLen', '300');
        Observer.Expect('unicode', '[Ä€.xml]');
        Observer.Verify();
    end;

    [Test]
    procedure Set_TwoInstancesIndependent()
    var
        A: XmlPort "LT P94 Xml Filename";
        B: XmlPort "LT P94 Xml Filename";
    begin
        A.Filename('a.xml');
        Observer.Observe('a', '[' + A.Filename() + ']');
        Observer.Observe('b', '[' + B.Filename() + ']');
        Observer.Expect('a', '[a.xml]');
        Observer.Expect('b', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Export_FilenameInTriggers_NotSet()
    var
        Xp: XmlPort "LT P94 Xml Filename";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Helper.Seed();
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('after', '[' + Xp.Filename() + ']');
        Observer.Expect('log', 'pre=[];post=[];');
        Observer.Expect('after', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Export_FilenameInTriggers_Set()
    var
        Xp: XmlPort "LT P94 Xml Filename";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.Filename('out.xml');
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('after', '[' + Xp.Filename() + ']');
        Observer.Observe('xml', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Expect('log', 'pre=[out.xml];post=[out.xml];');
        Observer.Expect('after', '[out.xml]');
        Observer.Expect('xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_FilenameInTriggers_NotSet()
    var
        Xp: XmlPort "LT P94 Xml Filename";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Helper.Wipe();
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('<?xml version="1.0" encoding="utf-8"?><Root><Item><Id>7</Id></Item></Root>');
        Row.Data.CreateInStream(InS);
        Xp.SetSource(InS);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('items', Format(Helper.CountItems()));
        Observer.Expect('log', 'pre=[];post=[];');
        Observer.Expect('items', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Import_FilenameInTriggers_Set()
    var
        Xp: XmlPort "LT P94 Xml Filename";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Helper.Wipe();
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('<?xml version="1.0" encoding="utf-8"?><Root><Item><Id>7</Id></Item></Root>');
        Row.Data.CreateInStream(InS);
        Xp.Filename('in.xml');
        Xp.SetSource(InS);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('items', Format(Helper.CountItems()));
        Observer.Expect('log', 'pre=[in.xml];post=[in.xml];');
        Observer.Expect('items', '1');
        Observer.Verify();
    end;
}
