// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: P112Fix.al (tables 71831-71833, helper 71834), SingleInstance log 71835 (used only by test codeunit 71839), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlPort (Format Xml) triggers OnInitXmlPort, OnPreXmlItem, OnBeforePassField, OnAfterAssignField on export and import: order, effect of changing the record in them, and of currXMLport.Skip / Break / BreakUnbound / Quit in them on the exported text and the imported rows
// BC versions: 29 (27 and 28 by CI)

codeunit 71835 "LT P112 Xml Ctl"
{
    SingleInstance = true;

    var
        Entries: Text;
        ArmSite: Text;
        ArmAction: Text;
        ArmHit: Integer;
        Hits: Dictionary of [Text, Integer];

    procedure Reset()
    begin
        Entries := '';
        ArmSite := '';
        ArmAction := '';
        ArmHit := 0;
        Clear(Hits);
    end;

    procedure Arm(Site: Text; Action: Text; Hit: Integer)
    begin
        ArmSite := Site;
        ArmAction := Action;
        ArmHit := Hit;
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure Decide(Where: Text): Text
    var
        N: Integer;
        Result: Text;
    begin
        if not Hits.Get(Where, N) then
            N := 0;
        N += 1;
        Hits.Set(Where, N);
        if (Where = ArmSite) and (N = ArmHit) then
            Result := ArmAction;
        if Result = '' then
            Add(Where + ' ' + Format(N))
        else
            Add(Where + ' ' + Format(N) + ' ' + Result);
        exit(Result);
    end;
}

// Logs every trigger and acts on the armed site.
xmlport 71836 "LT P112 Xml Trig"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT P112 Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; ItemRow.Id)
                {
                    trigger OnBeforePassField()
                    begin
                        Act('idBefore');
                    end;

                    trigger OnAfterAssignField()
                    begin
                        Act('idAfter');
                    end;
                }
                fieldelement(Name; ItemRow.Name)
                {
                    trigger OnBeforePassField()
                    begin
                        Act('nameBefore');
                    end;

                    trigger OnAfterAssignField()
                    begin
                        Act('nameAfter');
                    end;
                }
                trigger OnPreXmlItem()
                begin
                    Act('preItem');
                end;

                trigger OnAfterGetRecord()
                begin
                    Act('getRec');
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Act('beforeIns');
                end;

                trigger OnAfterInsertRecord()
                begin
                    Act('afterIns');
                end;
            }
        }
    }

    var
        Ctl: Codeunit "LT P112 Xml Ctl";

    trigger OnInitXmlPort()
    begin
        Act('init');
    end;

    trigger OnPreXmlPort()
    begin
        Act('prePort');
    end;

    trigger OnPostXmlPort()
    begin
        Act('postPort');
    end;

    local procedure Act(Where: Text)
    begin
        case Ctl.Decide(Where) of
            'skip':
                currXMLport.Skip();
            'break':
                currXMLport.Break();
            'unbound':
                currXMLport.BreakUnbound();
            'quit':
                currXMLport.Quit();
        end;
        Ctl.Add(Where + ' done');
    end;
}

// Changes the record in OnBeforePassField (export) and OnAfterAssignField (import).
xmlport 71837 "LT P112 Xml Mod"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT P112 Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name)
                {
                    trigger OnBeforePassField()
                    begin
                        ItemRow.Name := CopyStr('x' + ItemRow.Name, 1, MaxStrLen(ItemRow.Name));
                    end;

                    trigger OnAfterAssignField()
                    begin
                        ItemRow.Name := CopyStr(UpperCase(ItemRow.Name), 1, MaxStrLen(ItemRow.Name));
                    end;
                }
                fieldelement(Qty; ItemRow.Qty)
                {
                    trigger OnBeforePassField()
                    begin
                        ItemRow.Qty := ItemRow.Qty + 1000;
                    end;

                    trigger OnAfterAssignField()
                    begin
                        ItemRow.Qty := ItemRow.Qty * 2;
                    end;
                }
            }
        }
    }
}

// Two nested table elements, OnPreXmlItem on both.
xmlport 71838 "LT P112 Xml Nested"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT P112 Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; ItemRow.Id) { }
                tableelement(LineRow; "LT P112 Line")
                {
                    XmlName = 'Line';
                    LinkFields = ItemId = field(Id);
                    LinkTable = ItemRow;
                    fieldattribute(Id; LineRow.Id)
                    {
                        trigger OnBeforePassField()
                        begin
                            Ctl.Add('lineIdBefore');
                        end;

                        trigger OnAfterAssignField()
                        begin
                            Ctl.Add('lineIdAfter');
                        end;
                    }
                    fieldelement(Note; LineRow.Note) { }
                    trigger OnPreXmlItem()
                    begin
                        Ctl.Add('linePre');
                    end;
                }
                trigger OnPreXmlItem()
                begin
                    Ctl.Add('itemPre');
                end;
            }
        }
    }

    var
        Ctl: Codeunit "LT P112 Xml Ctl";

    trigger OnInitXmlPort()
    begin
        Ctl.Add('init');
    end;
}

codeunit 71839 "LT P112 Xml Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Ctl: Codeunit "LT P112 Xml Ctl";
        Helper: Codeunit "LT P112 Helper";

    local procedure ExportTrig(): Text
    var
        Xp: XmlPort "LT P112 Xml Trig";
        Row: Record "LT P112 Blob" temporary;
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        exit(Helper.ReadBlob(Row));
    end;

    local procedure ImportTrig(Content: Text)
    var
        Xp: XmlPort "LT P112 Xml Trig";
        Row: Record "LT P112 Blob" temporary;
        InS: InStream;
    begin
        Helper.Source(Row, Content, InS);
        Xp.SetSource(InS);
        Xp.Import();
    end;

    local procedure ExportMod(): Text
    var
        Xp: XmlPort "LT P112 Xml Mod";
        Row: Record "LT P112 Blob" temporary;
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        exit(Helper.ReadBlob(Row));
    end;

    local procedure ImportMod(Content: Text)
    var
        Xp: XmlPort "LT P112 Xml Mod";
        Row: Record "LT P112 Blob" temporary;
        InS: InStream;
    begin
        Helper.Source(Row, Content, InS);
        Xp.SetSource(InS);
        Xp.Import();
    end;

    local procedure ExportNested(): Text
    var
        Xp: XmlPort "LT P112 Xml Nested";
        Row: Record "LT P112 Blob" temporary;
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        exit(Helper.ReadBlob(Row));
    end;

    local procedure ImportNested(Content: Text)
    var
        Xp: XmlPort "LT P112 Xml Nested";
        Row: Record "LT P112 Blob" temporary;
        InS: InStream;
    begin
        Helper.Source(Row, Content, InS);
        Xp.SetSource(InS);
        Xp.Import();
    end;

    local procedure ThreeItemsXml(): Text
    begin
        exit('<Root><Item Id="1"><Name>Alpha</Name></Item><Item Id="2"><Name>Beta</Name></Item><Item Id="3"><Name>Gamma</Name></Item></Root>');
    end;

    local procedure ArmedExport(var Observer: Codeunit "Probe Observer"; Tag: Text; Site: Text; Action: Text; Hit: Integer)
    var
        Xml: Text;
    begin
        Helper.SeedThree();
        Ctl.Reset();
        Ctl.Arm(Site, Action, Hit);
        Xml := ExportTrig();
        Observer.Observe(Tag + ' log', Ctl.Take());
        Observer.Observe(Tag + ' xml', Xml);
        Ctl.Reset();
    end;

    local procedure ExportTrigLen(): Integer
    var
        Xp: XmlPort "LT P112 Xml Trig";
        Row: Record "LT P112 Blob" temporary;
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        exit(Row.Data.Length());
    end;

    local procedure ArmedExport2(var Observer: Codeunit "Probe Observer"; Tag: Text; Site: Text; Action: Text; Hit: Integer)
    var
        Len: Integer;
    begin
        Helper.SeedThree();
        Ctl.Reset();
        Ctl.Arm(Site, Action, Hit);
        Len := ExportTrigLen();
        Observer.Observe(Tag + ' log', Ctl.Take());
        Observer.Observe(Tag + ' nonempty', Format(Len > 0));
        Observer.Observe(Tag + ' rows', Helper.DumpItems());
        Ctl.Reset();
    end;

    local procedure ArmedImport(var Observer: Codeunit "Probe Observer"; Tag: Text; Site: Text; Action: Text; Hit: Integer)
    begin
        Helper.Wipe();
        Ctl.Reset();
        Ctl.Arm(Site, Action, Hit);
        ImportTrig(ThreeItemsXml());
        Observer.Observe(Tag + ' log', Ctl.Take());
        Observer.Observe(Tag + ' rows', Helper.DumpItems());
        Ctl.Reset();
    end;

    [Test]
    procedure P112_Export_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Helper.AddItem(2, 'Beta', 20);
        Ctl.Reset();
        asserterror Xml := ExportTrig();
        Observer.ObserveError('af379');
        Observer.Observe('log', Ctl.Take());
        Observer.Observe('xml', Xml);
        Ctl.Reset();
        Observer.Expect('af379|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af379|code', 'InvalidStreamData');
        Observer.Expect('log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Helper.Wipe();
        Ctl.Reset();
        asserterror Xml := ExportTrig();
        Observer.ObserveError('af395');
        Observer.Observe('log', Ctl.Take());
        Observer.Observe('xml', Xml);
        Ctl.Reset();
        Observer.Expect('af395|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af395|code', 'InvalidStreamData');
        Observer.Expect('log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Import_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Wipe();
        Ctl.Reset();
        ImportTrig('<Root><Item Id="1"><Name>Alpha</Name></Item><Item Id="2"><Name>Beta</Name></Item></Root>');
        Observer.Observe('log', Ctl.Take());
        Observer.Observe('rows', Helper.DumpItems());
        Ctl.Reset();
        Observer.Expect('log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;postPort 1;postPort done;');
        Observer.Expect('rows', '[1=Alpha/0;2=Beta/0;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Import_EmptyRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Wipe();
        Ctl.Reset();
        asserterror ImportTrig('<Root/>');
        Observer.ObserveError('af424');
        Observer.Observe('log', Ctl.Take());
        Ctl.Reset();
        Observer.Expect('af424|text', 'Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Item''.');
        Observer.Expect('af424|code', 'XmlPortInvalidXml');
        Observer.Expect('log', 'init 1;init done;prePort 1;prePort done;');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Import_ElementOrderSwapped()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Wipe();
        Ctl.Reset();
        ImportTrig('<Root><Item Id="5"><Name>Five</Name></Item></Root>');
        Observer.Observe('log one row', Ctl.Take());
        Ctl.Reset();
        asserterror ImportTrig('<Root><Item Id="6"></Item></Root>');
        Observer.ObserveError('af442');
        Observer.Observe('log missing name', Ctl.Take());
        Ctl.Reset();
        Observer.Expect('log one row', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;postPort 1;postPort done;');
        Observer.Expect('af442|text', 'Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Name''.');
        Observer.Expect('af442|code', 'XmlPortInvalidXml');
        Observer.Expect('log missing name', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Static_Export_Import()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P112 Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        Xml: Text;
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Ctl.Reset();
        Row.Data.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT P112 Xml Trig", OutS);
        asserterror Xml := Helper.ReadBlob(Row);
        Observer.ObserveError('af464');
        Observer.Observe('export log', Ctl.Take());
        Observer.Observe('xml', Xml);
        Helper.Wipe();
        Helper.Source(Row, Xml, InS);
        Xmlport.Import(Xmlport::"LT P112 Xml Trig", InS);
        Observer.Observe('import log', Ctl.Take());
        Observer.Observe('rows', Helper.DumpItems());
        Ctl.Reset();
        Observer.Expect('af464|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af464|code', 'InvalidStreamData');
        Observer.Expect('export log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('xml', '');
        Observer.Expect('import log', 'init 2;init done;prePort 2;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;postPort 2;postPort done;');
        Observer.Expect('rows', '[1=Alpha/0;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_RoundTrip_SameInstance()
    var
        Observer: Codeunit "Probe Observer";
        Xp: XmlPort "LT P112 Xml Trig";
        Row: Record "LT P112 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Ctl.Reset();
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('first log', Ctl.Take());
        Xp.Export();
        Observer.Observe('second log', Ctl.Take());
        Ctl.Reset();
        Observer.Expect('first log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('second log', 'prePort 2;prePort done;preItem 2;preItem done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2;nameBefore done;postPort 2;postPort done;');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Mod_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Helper.AddItem(2, 'Beta', 20);
        asserterror Observer.Observe('xml', ExportMod());
        Observer.ObserveError('af506');
        Observer.Expect('af506|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af506|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Mod_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Wipe();
        ImportMod('<Root><Item Id="1"><Name>Alpha</Name><Qty>10</Qty></Item><Item Id="2"><Name>Beta</Name><Qty>20</Qty></Item></Root>');
        Observer.Observe('rows', Helper.DumpItems());
        Observer.Expect('rows', '[1=ALPHA/20;2=BETA/40;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Nested_Export()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Helper.AddItem(2, 'Beta', 20);
        Helper.AddLine(11, 1, 'a1');
        Helper.AddLine(12, 1, 'a2');
        Helper.AddLine(21, 2, 'b1');
        Ctl.Reset();
        asserterror Xml := ExportNested();
        Observer.ObserveError('af536');
        Observer.Observe('log', Ctl.Take());
        Observer.Observe('xml', Xml);
        Ctl.Reset();
        Observer.Expect('af536|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af536|code', 'InvalidStreamData');
        Observer.Expect('log', 'init;itemPre;linePre;lineIdBefore;lineIdBefore;linePre;lineIdBefore;');
        Observer.Expect('xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Nested_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Wipe();
        Ctl.Reset();
        ImportNested('<Root><Item Id="1"><Line Id="11"><Note>a1</Note></Line><Line Id="12"><Note>a2</Note></Line></Item><Item Id="2"><Line Id="21"><Note>b1</Note></Line></Item></Root>');
        Observer.Observe('log', Ctl.Take());
        Observer.Observe('items', Helper.DumpItems());
        Observer.Observe('lines', Helper.DumpLines());
        Ctl.Reset();
        Observer.Expect('log', 'init;lineIdAfter;lineIdAfter;lineIdAfter;');
        Observer.Expect('items', '[1=/0;2=/0;]');
        Observer.Expect('lines', '[11=1/a1;12=0/a2;21=2/b1;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_Skip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedExport2(Observer, 'getRec2', 'getRec', 'skip', 2);
        ArmedExport2(Observer, 'preItem1', 'preItem', 'skip', 1);
        ArmedExport2(Observer, 'idBefore2', 'idBefore', 'skip', 2);
        ArmedExport2(Observer, 'nameBefore2', 'nameBefore', 'skip', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2 skip;getRec 3;getRec done;idBefore 2;idBefore done;nameBefore 2;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('getRec2 nonempty', 'Yes');
        Observer.Expect('getRec2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('preItem1 log', 'init 1;init done;prePort 1;prePort done;preItem 1 skip;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('preItem1 nonempty', 'Yes');
        Observer.Expect('preItem1 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('idBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2 skip;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('idBefore2 nonempty', 'Yes');
        Observer.Expect('idBefore2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('nameBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2 skip;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('nameBefore2 nonempty', 'Yes');
        Observer.Expect('nameBefore2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedExport2(Observer, 'getRec2', 'getRec', 'break', 2);
        ArmedExport2(Observer, 'preItem1', 'preItem', 'break', 1);
        ArmedExport2(Observer, 'idBefore2', 'idBefore', 'break', 2);
        ArmedExport2(Observer, 'nameBefore2', 'nameBefore', 'break', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2 break;postPort 1;postPort done;');
        Observer.Expect('getRec2 nonempty', 'Yes');
        Observer.Expect('getRec2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('preItem1 log', 'init 1;init done;prePort 1;prePort done;preItem 1 break;postPort 1;postPort done;');
        Observer.Expect('preItem1 nonempty', 'Yes');
        Observer.Expect('preItem1 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('idBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2 break;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('idBefore2 nonempty', 'Yes');
        Observer.Expect('idBefore2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('nameBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2 break;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('nameBefore2 nonempty', 'Yes');
        Observer.Expect('nameBefore2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedExport2(Observer, 'getRec2', 'getRec', 'unbound', 2);
        ArmedExport2(Observer, 'preItem1', 'preItem', 'unbound', 1);
        ArmedExport2(Observer, 'idBefore2', 'idBefore', 'unbound', 2);
        ArmedExport2(Observer, 'nameBefore2', 'nameBefore', 'unbound', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2 unbound;idBefore 2;idBefore done;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('getRec2 nonempty', 'Yes');
        Observer.Expect('getRec2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('preItem1 log', 'init 1;init done;prePort 1;prePort done;preItem 1 unbound;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('preItem1 nonempty', 'Yes');
        Observer.Expect('preItem1 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('idBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2 unbound;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('idBefore2 nonempty', 'Yes');
        Observer.Expect('idBefore2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('nameBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2 unbound;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('nameBefore2 nonempty', 'Yes');
        Observer.Expect('nameBefore2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedExport2(Observer, 'getRec2', 'getRec', 'quit', 2);
        ArmedExport2(Observer, 'preItem1', 'preItem', 'quit', 1);
        ArmedExport2(Observer, 'idBefore2', 'idBefore', 'quit', 2);
        ArmedExport2(Observer, 'nameBefore2', 'nameBefore', 'quit', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2 quit;');
        Observer.Expect('getRec2 nonempty', 'Yes');
        Observer.Expect('getRec2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('preItem1 log', 'init 1;init done;prePort 1;prePort done;preItem 1 quit;');
        Observer.Expect('preItem1 nonempty', 'Yes');
        Observer.Expect('preItem1 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('idBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2 quit;');
        Observer.Expect('idBefore2 nonempty', 'Yes');
        Observer.Expect('idBefore2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Expect('nameBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2 quit;');
        Observer.Expect('nameBefore2 nonempty', 'Yes');
        Observer.Expect('nameBefore2 rows', '[1=Alpha/10;2=Beta/20;3=Gamma/30;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_Init_Skip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror ArmedExport(Observer, 'init1', 'init', 'skip', 1);
        Observer.ObserveError('af616');
        Observer.Expect('af616|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af616|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_Init_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror ArmedExport(Observer, 'init1', 'init', 'break', 1);
        Observer.ObserveError('af626');
        Observer.Expect('af626|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af626|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_Init_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedExport(Observer, 'init1', 'init', 'quit', 1);
        Observer.Expect('init1 log', 'init 1 quit;');
        Observer.Expect('init1 xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Import_Skip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedImport(Observer, 'getRec2', 'getRec', 'skip', 2);
        ArmedImport(Observer, 'beforeIns2', 'beforeIns', 'skip', 2);
        ArmedImport(Observer, 'afterIns2', 'afterIns', 'skip', 2);
        ArmedImport(Observer, 'idAfter2', 'idAfter', 'skip', 2);
        ArmedImport(Observer, 'nameAfter2', 'nameAfter', 'skip', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('getRec2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('beforeIns2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2 skip;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 2;afterIns done;postPort 1;postPort done;');
        Observer.Expect('beforeIns2 rows', '[1=Alpha/0;3=Gamma/0;]');
        Observer.Expect('afterIns2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2 skip;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('afterIns2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('idAfter2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2 skip;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('idAfter2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('nameAfter2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2 skip;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('nameAfter2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Verify();
    end;





    [Test]
    procedure P112_Import_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedImport(Observer, 'getRec2', 'getRec', 'break', 2);
        ArmedImport(Observer, 'beforeIns2', 'beforeIns', 'break', 2);
        ArmedImport(Observer, 'afterIns2', 'afterIns', 'break', 2);
        ArmedImport(Observer, 'idAfter2', 'idAfter', 'break', 2);
        ArmedImport(Observer, 'nameAfter2', 'nameAfter', 'break', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('getRec2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('beforeIns2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2 break;postPort 1;postPort done;');
        Observer.Expect('beforeIns2 rows', '[1=Alpha/0;]');
        Observer.Expect('afterIns2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2 break;postPort 1;postPort done;');
        Observer.Expect('afterIns2 rows', '[1=Alpha/0;2=Beta/0;]');
        Observer.Expect('idAfter2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2 break;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('idAfter2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('nameAfter2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2 break;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('nameAfter2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Verify();
    end;





    [Test]
    procedure P112_Import_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedImport(Observer, 'getRec2', 'getRec', 'unbound', 2);
        ArmedImport(Observer, 'beforeIns2', 'beforeIns', 'unbound', 2);
        ArmedImport(Observer, 'idAfter2', 'idAfter', 'unbound', 2);
        ArmedImport(Observer, 'nameAfter2', 'nameAfter', 'unbound', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('getRec2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('beforeIns2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2 unbound;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 2;afterIns done;postPort 1;postPort done;');
        Observer.Expect('beforeIns2 rows', '[1=Alpha/0;3=Gamma/0;]');
        Observer.Expect('idAfter2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2 unbound;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('idAfter2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('nameAfter2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2 unbound;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('nameAfter2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Import_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedImport(Observer, 'getRec2', 'getRec', 'quit', 2);
        ArmedImport(Observer, 'beforeIns2', 'beforeIns', 'quit', 2);
        ArmedImport(Observer, 'idAfter2', 'idAfter', 'quit', 2);
        ArmedImport(Observer, 'nameAfter2', 'nameAfter', 'quit', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('getRec2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('beforeIns2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2 quit;');
        Observer.Expect('beforeIns2 rows', '[1=Alpha/0;]');
        Observer.Expect('idAfter2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2 quit;');
        Observer.Expect('idAfter2 rows', '[1=Alpha/0;]');
        Observer.Expect('nameAfter2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2 quit;');
        Observer.Expect('nameAfter2 rows', '[1=Alpha/0;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Import_PreItem_Actions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedImport(Observer, 'preItem skip', 'preItem', 'skip', 1);
        ArmedImport(Observer, 'preItem break', 'preItem', 'break', 1);
        ArmedImport(Observer, 'preItem quit', 'preItem', 'quit', 1);
        Observer.Expect('preItem skip log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('preItem skip rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('preItem break log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('preItem break rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('preItem quit log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('preItem quit rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Import_Init_Actions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedImport(Observer, 'init skip', 'init', 'skip', 1);
        ArmedImport(Observer, 'init quit', 'init', 'quit', 1);
        Observer.Expect('init skip log', 'init 1 skip;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('init skip rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('init quit log', 'init 1 quit;');
        Observer.Expect('init quit rows', '[]');
        Observer.Verify();
    end;
}
