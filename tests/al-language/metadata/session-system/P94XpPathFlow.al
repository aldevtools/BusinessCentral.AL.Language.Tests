// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-data-type
// Scope: in-scope
// Fixtures used: P94Fixtures.al (tables 73057-73059, xmlports 73064, 73065, 73068, helper 73071), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Xmlport.CurrentPath in the triggers of an export and an import, Break, Run (instance and static) of an export without destination
// BC versions: 29 (27 and 28 by CI)

codeunit 73076 "LT P94 Xp Path"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P94 Helper";

    local procedure ImportXml(var Xp: XmlPort "LT P94 Xml Path"; Xml: Text)
    var
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText(Xml);
        Row.Data.CreateInStream(InS);
        Xp.SetSource(InS);
        Xp.Import();
    end;

    [TryFunction]
    local procedure TryPath(var Xp: XmlPort "LT P94 Xml Path"; var Result: Text)
    begin
        Result := Xp.CurrentPath();
    end;

    [Test]
    procedure Export_PathsInTriggers()
    var
        Xp: XmlPort "LT P94 Xml Path";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('xml', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Expect('log', 'pre=[];itemPre=[/Root/Item];itemGet=[/Root/Item];attrBeforePass=[/Root/Item[@Qty]];idBeforePass=[/Root/Item/Id];post=[];');
        Observer.Expect('xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_PathsTwoRows()
    var
        Xp: XmlPort "LT P94 Xml Path";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Helper.AddItem(2, 'Beta', 20);
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('log', Xp.GetLog());
        Observer.Expect('log', 'pre=[];itemPre=[/Root/Item];itemGet=[/Root/Item];attrBeforePass=[/Root/Item[@Qty]];idBeforePass=[/Root/Item/Id];itemGet=[/Root/Item];attrBeforePass=[/Root/Item[@Qty]];idBeforePass=[/Root/Item/Id];post=[];');
        Observer.Verify();
    end;

    [Test]
    procedure Export_PathsNoRows()
    var
        Xp: XmlPort "LT P94 Xml Path";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('log', Xp.GetLog());
        Observer.Expect('log', 'pre=[];itemPre=[/Root/Item];attrBeforePass=[/Root/Item[@Qty]];idBeforePass=[/Root/Item/Id];post=[];');
        Observer.Verify();
    end;

    [Test]
    procedure Import_PathsInTriggers()
    var
        Xp: XmlPort "LT P94 Xml Path";
    begin
        Helper.Wipe();
        ImportXml(Xp, '<?xml version="1.0" encoding="utf-8"?><Root><Item Qty="5"><Id>1</Id><Name>Alpha</Name></Item></Root>');
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('items', Helper.ItemNames());
        Observer.Expect('log', 'pre=[];attrAfterAssign=[];idAfterAssign=[];itemBeforeInsert=[];itemAfterInsert=[];post=[];');
        Observer.Expect('items', '1=Alpha;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_PathsTwoRows()
    var
        Xp: XmlPort "LT P94 Xml Path";
    begin
        Helper.Wipe();
        ImportXml(Xp, '<?xml version="1.0" encoding="utf-8"?><Root><Item Qty="5"><Id>1</Id><Name>Alpha</Name></Item><Item Qty="6"><Id>2</Id><Name>Beta</Name></Item></Root>');
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('items', Helper.ItemNames());
        Observer.Expect('log', 'pre=[];attrAfterAssign=[];idAfterAssign=[];itemBeforeInsert=[];itemAfterInsert=[];attrAfterAssign=[];idAfterAssign=[];itemBeforeInsert=[];itemAfterInsert=[];post=[];');
        Observer.Expect('items', '1=Alpha;2=Beta;');
        Observer.Verify();
    end;

    [Test]
    procedure OutsideRun_CurrentPath()
    var
        Xp: XmlPort "LT P94 Xml Path";
        Result: Text;
    begin
        Result := 'preset';
        if TryPath(Xp, Result) then
            Observer.Observe('path', '[' + Result + ']')
        else
            Observer.Observe('path', Helper.ErrText());
        Observer.Expect('path', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure AfterRun_CurrentPath()
    var
        Xp: XmlPort "LT P94 Xml Path";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
        Result: Text;
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Result := 'preset';
        if TryPath(Xp, Result) then
            Observer.Observe('path', '[' + Result + ']')
        else
            Observer.Observe('path', Helper.ErrText());
        Observer.Expect('path', '[]');
        Observer.Verify();
    end;
}

codeunit 73077 "LT P94 Xp Flow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P94 Helper";

    local procedure ExportMode(Mode: Integer; var Row: Record "LT P94 Blob" temporary; var Log: Text): Boolean
    var
        Xp: XmlPort "LT P94 Xml Flow";
        OutS: OutStream;
        Result: Boolean;
    begin
        Xp.SetMode(Mode);
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Result := Xp.Export();
        Log := Xp.GetLog();
        exit(Result);
    end;

    local procedure ImportMode(Mode: Integer; var Log: Text): Boolean
    var
        Xp: XmlPort "LT P94 Xml Flow";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        Result: Boolean;
    begin
        Xp.SetMode(Mode);
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('<?xml version="1.0" encoding="utf-8"?><Root><Item><Id>1</Id><Name>A</Name></Item><Item><Id>2</Id><Name>B</Name></Item><Item><Id>3</Id><Name>C</Name></Item></Root>');
        Row.Data.CreateInStream(InS);
        Xp.SetSource(InS);
        Result := Xp.Import();
        Log := Xp.GetLog();
        exit(Result);
    end;

    [Test]
    procedure Export_NoFlowControl()
    var
        Row: Record "LT P94 Blob" temporary;
        Log: Text;
        Ok: Boolean;
    begin
        Helper.Wipe();
        Helper.Seed();
        Ok := ExportMode(0, Row, Log);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('log', Log);
        Observer.Observe('xml', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre;hit1;after1;hit2;after2;hit3;after3;post;');
        Observer.Expect('xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Break()
    var
        Row: Record "LT P94 Blob" temporary;
        Log: Text;
        Ok: Boolean;
    begin
        Helper.Wipe();
        Helper.Seed();
        Ok := ExportMode(1, Row, Log);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('log', Log);
        Observer.Observe('xml', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre;hit1;after1;hit2;post;');
        Observer.Expect('xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_BreakUnbound()
    var
        Row: Record "LT P94 Blob" temporary;
        Log: Text;
        Ok: Boolean;
    begin
        Helper.Wipe();
        Helper.Seed();
        Ok := ExportMode(2, Row, Log);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('log', Log);
        Observer.Observe('xml', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre;hit1;after1;hit2;hit3;after3;post;');
        Observer.Expect('xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Quit()
    var
        Row: Record "LT P94 Blob" temporary;
        Log: Text;
        Ok: Boolean;
    begin
        Helper.Wipe();
        Helper.Seed();
        Ok := ExportMode(3, Row, Log);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('log', Log);
        Observer.Observe('xml', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre;hit1;after1;hit2;');
        Observer.Expect('xml', '');
        Observer.Verify();
    end;

}

codeunit 73078 "LT P94 Xp Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P94 Helper";

    [TryFunction]
    local procedure TryRunInstance()
    var
        Xp: XmlPort "LT P94 Xml Marker";
    begin
        Xp.Run();
    end;

    [TryFunction]
    local procedure TryRunStatic(RequestWindow: Boolean; Import: Boolean)
    begin
        Xmlport.Run(Xmlport::"LT P94 Xml Marker", RequestWindow, Import);
    end;

    [TryFunction]
    local procedure TryRunStaticNumber(Number: Integer)
    begin
        Xmlport.Run(Number, false, false);
    end;

    [Test]
    procedure RunStatic_ImportWithoutSource()
    begin
        if TryRunStatic(false, true) then
            Observer.Observe('run', 'ok')
        else
            Observer.Observe('run', Helper.ErrText());
        Observer.Expect('run', 'error:The XMLPort ''LT P94 Xml Marker'' is designed for export only.|XmlPortExportDirection');
        Observer.Verify();
    end;

    [Test]
    procedure RunStatic_UnknownNumbers()
    begin
        if TryRunStaticNumber(0) then
            Observer.Observe('zero', 'ok')
        else
            Observer.Observe('zero', Helper.ErrText());
        if TryRunStaticNumber(-1) then
            Observer.Observe('minusOne', 'ok')
        else
            Observer.Observe('minusOne', Helper.ErrText());
        if TryRunStaticNumber(73999) then
            Observer.Observe('missing', 'ok')
        else
            Observer.Observe('missing', Helper.ErrText());
        Observer.Expect('zero', 'error:You tried to invoke the XmlPort object with the ID 0 from the object LT P94 Xp Run. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('minusOne', 'error:You tried to invoke the XmlPort object with the ID -1 from the object LT P94 Xp Run. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('missing', 'error:You tried to invoke the XmlPort object with the ID 73999 from the object LT P94 Xp Run. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Verify();
    end;
}
