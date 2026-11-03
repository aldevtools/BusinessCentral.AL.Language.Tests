// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: P112Fix.al (tables 71831-71833, helper 71834), SingleInstance log 71840 (used only by test codeunit 71843), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlPort (Format VariableText) triggers OnInitXmlPort, OnPreXmlItem, OnBeforePassField, OnAfterAssignField on export and import: order, effect of changing the record in them, and of currXMLport.Skip / Break / BreakUnbound / Quit in them on the exported text and the imported rows
// BC versions: 29 (27 and 28 by CI)

codeunit 71840 "LT P112 Csv Ctl"
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

xmlport 71841 "LT P112 Csv Trig"
{
    Format = VariableText;
    Direction = Both;
    FieldDelimiter = '"';
    FieldSeparator = ',';
    RecordSeparator = '<LF>';
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(ItemRow; "LT P112 Item")
        {
            fieldelement(Id; ItemRow.Id)
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

    var
        Ctl: Codeunit "LT P112 Csv Ctl";

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

xmlport 71875 "LT P112 Csv Root"
{
    Format = VariableText;
    Direction = Both;
    FieldDelimiter = '"';
    FieldSeparator = ',';
    RecordSeparator = '<LF>';
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
        tableelement(ItemRow; "LT P112 Item")
        {
            fieldelement(Id; ItemRow.Id)
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
        Ctl: Codeunit "LT P112 Csv Ctl";

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

xmlport 71842 "LT P112 Csv Mod"
{
    Format = VariableText;
    Direction = Both;
    FieldDelimiter = '"';
    FieldSeparator = ',';
    RecordSeparator = '<LF>';
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(ItemRow; "LT P112 Item")
        {
            fieldelement(Id; ItemRow.Id) { }
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

codeunit 71843 "LT P112 Csv Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Ctl: Codeunit "LT P112 Csv Ctl";
        Helper: Codeunit "LT P112 Helper";

    local procedure ExportTrig(): Text
    var
        Xp: XmlPort "LT P112 Csv Trig";
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
        Xp: XmlPort "LT P112 Csv Trig";
        Row: Record "LT P112 Blob" temporary;
        InS: InStream;
    begin
        Helper.Source(Row, Content, InS);
        Xp.SetSource(InS);
        Xp.Import();
    end;

    local procedure ExportMod(): Text
    var
        Xp: XmlPort "LT P112 Csv Mod";
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
        Xp: XmlPort "LT P112 Csv Mod";
        Row: Record "LT P112 Blob" temporary;
        InS: InStream;
    begin
        Helper.Source(Row, Content, InS);
        Xp.SetSource(InS);
        Xp.Import();
    end;

    local procedure ThreeRowsCsv(): Text
    begin
        exit('1,Alpha' + Helper.Chr(10) + '2,Beta' + Helper.Chr(10) + '3,Gamma');
    end;

    local procedure ArmedExport(var Observer: Codeunit "Probe Observer"; Tag: Text; Site: Text; Action: Text; Hit: Integer)
    var
        Csv: Text;
    begin
        Helper.SeedThree();
        Ctl.Reset();
        Ctl.Arm(Site, Action, Hit);
        Csv := ExportTrig();
        Observer.Observe(Tag + ' log', Ctl.Take());
        Observer.Observe(Tag + ' csv', Csv);
        Ctl.Reset();
    end;

    local procedure ImportRoot(Content: Text)
    var
        Xp: XmlPort "LT P112 Csv Root";
        Row: Record "LT P112 Blob" temporary;
        InS: InStream;
    begin
        Helper.Source(Row, Content, InS);
        Xp.SetSource(InS);
        Xp.Import();
    end;

    local procedure ArmedImport2(var Observer: Codeunit "Probe Observer"; Tag: Text; Site: Text; Action: Text; Hit: Integer)
    begin
        Helper.Wipe();
        Ctl.Reset();
        Ctl.Arm(Site, Action, Hit);
        ImportRoot(ThreeRowsCsv());
        Observer.Observe(Tag + ' log', Ctl.Take());
        Observer.Observe(Tag + ' rows', Helper.DumpItems());
        Ctl.Reset();
    end;

    local procedure ArmedImport(var Observer: Codeunit "Probe Observer"; Tag: Text; Site: Text; Action: Text; Hit: Integer)
    begin
        Helper.Wipe();
        Ctl.Reset();
        Ctl.Arm(Site, Action, Hit);
        ImportTrig(ThreeRowsCsv());
        Observer.Observe(Tag + ' log', Ctl.Take());
        Observer.Observe(Tag + ' rows', Helper.DumpItems());
        Ctl.Reset();
    end;

    [Test]
    procedure P112_Export_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        Csv: Text;
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Helper.AddItem(2, 'Beta', 20);
        Ctl.Reset();
        Csv := ExportTrig();
        Observer.Observe('log', Ctl.Take());
        Observer.Observe('csv', Csv);
        Ctl.Reset();
        Observer.Expect('log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('csv', '"1","Alpha"<LF>"2","Beta"');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Csv: Text;
    begin
        Helper.Wipe();
        Ctl.Reset();
        Csv := ExportTrig();
        Observer.Observe('log', Ctl.Take());
        Observer.Observe('csv', Csv);
        Ctl.Reset();
        Observer.Expect('log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;postPort 1;postPort done;');
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Import_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Wipe();
        Ctl.Reset();
        asserterror ImportTrig('1,Alpha' + Helper.Chr(10) + '2,Beta');
        Observer.ObserveError('af328');
        Observer.Observe('log', Ctl.Take());
        Observer.Observe('rows', Helper.DumpItems());
        Ctl.Reset();
        Observer.Expect('af328|text', 'If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.');
        Observer.Expect('af328|code', 'XmlPortInvalidNodeType');
        Observer.Expect('log', 'init 1;init done;prePort 1;prePort done;');
        Observer.Expect('rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Import_EmptySource()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Wipe();
        Ctl.Reset();
        asserterror ImportTrig('');
        Observer.ObserveError('af343');
        Observer.Observe('log', Ctl.Take());
        Observer.Observe('rows', Helper.DumpItems());
        Ctl.Reset();
        Observer.Expect('af343|text', 'Cannot import the specified XML document because the file is empty.');
        Observer.Expect('af343|code', 'XmlPortData');
        Observer.Expect('log', 'init 1;init done;');
        Observer.Expect('rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Static_Export_Import()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P112 Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        Csv: Text;
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Ctl.Reset();
        Row.Data.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT P112 Csv Trig", OutS);
        Csv := Helper.ReadBlob(Row);
        Observer.Observe('export log', Ctl.Take());
        Observer.Observe('csv', Csv);
        Helper.Wipe();
        Helper.Source(Row, Csv, InS);
        asserterror Xmlport.Import(Xmlport::"LT P112 Csv Trig", InS);
        Observer.ObserveError('af370');
        Observer.Observe('import log', Ctl.Take());
        Observer.Observe('rows', Helper.DumpItems());
        Ctl.Reset();
        Observer.Expect('export log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('csv', '"1","Alpha"');
        Observer.Expect('af370|text', 'If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.');
        Observer.Expect('af370|code', 'XmlPortInvalidNodeType');
        Observer.Expect('import log', 'init 2;init done;prePort 2;prePort done;');
        Observer.Expect('rows', '[]');
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
        Observer.Observe('csv', ExportMod());
        Observer.Observe('rows after', Helper.DumpItems());
        Observer.Expect('csv', '"1","xAlpha","1010"<LF>"2","xBeta","1020"');
        Observer.Expect('rows after', '[1=Alpha/10;2=Beta/20;]');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Mod_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Wipe();
        asserterror ImportMod('1,Alpha,10' + Helper.Chr(10) + '2,Beta,20');
        Observer.ObserveError('af397');
        Observer.Expect('af397|text', 'If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.');
        Observer.Expect('af397|code', 'XmlPortInvalidNodeType');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_Skip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedExport(Observer, 'getRec2', 'getRec', 'skip', 2);
        ArmedExport(Observer, 'preItem1', 'preItem', 'skip', 1);
        ArmedExport(Observer, 'idBefore2', 'idBefore', 'skip', 2);
        ArmedExport(Observer, 'nameBefore2', 'nameBefore', 'skip', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2 skip;getRec 3;getRec done;idBefore 2;idBefore done;nameBefore 2;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('getRec2 csv', '"1","Alpha"<LF>"3","Gamma"');
        Observer.Expect('preItem1 log', 'init 1;init done;prePort 1;prePort done;preItem 1 skip;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('preItem1 csv', '"1","Alpha"<LF>"2","Beta"<LF>"3","Gamma"');
        Observer.Expect('idBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2 skip;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('idBefore2 csv', '"1","Alpha"<LF>"Beta"<LF>"3","Gamma"');
        Observer.Expect('nameBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2 skip;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('nameBefore2 csv', '"1","Alpha"<LF>"2"<LF>"3","Gamma"');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedExport(Observer, 'getRec2', 'getRec', 'break', 2);
        ArmedExport(Observer, 'preItem1', 'preItem', 'break', 1);
        ArmedExport(Observer, 'idBefore2', 'idBefore', 'break', 2);
        ArmedExport(Observer, 'nameBefore2', 'nameBefore', 'break', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2 break;postPort 1;postPort done;');
        Observer.Expect('getRec2 csv', '"1","Alpha"');
        Observer.Expect('preItem1 log', 'init 1;init done;prePort 1;prePort done;preItem 1 break;postPort 1;postPort done;');
        Observer.Expect('preItem1 csv', '');
        Observer.Expect('idBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2 break;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 2;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('idBefore2 csv', '"1","Alpha"<LF><LF>"3","Gamma"');
        Observer.Expect('nameBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2 break;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('nameBefore2 csv', '"1","Alpha"<LF>"2"<LF>"3","Gamma"');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedExport(Observer, 'getRec2', 'getRec', 'unbound', 2);
        ArmedExport(Observer, 'preItem1', 'preItem', 'unbound', 1);
        ArmedExport(Observer, 'idBefore2', 'idBefore', 'unbound', 2);
        ArmedExport(Observer, 'nameBefore2', 'nameBefore', 'unbound', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2 unbound;idBefore 2;idBefore done;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('getRec2 csv', '"1","Alpha"<LF>"2","Beta"<LF>"3","Gamma"');
        Observer.Expect('preItem1 log', 'init 1;init done;prePort 1;prePort done;preItem 1 unbound;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('preItem1 csv', '"1","Alpha"<LF>"2","Beta"<LF>"3","Gamma"');
        Observer.Expect('idBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2 unbound;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('idBefore2 csv', '"1","Alpha"<LF>"2","Beta"<LF>"3","Gamma"');
        Observer.Expect('nameBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2 unbound;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('nameBefore2 csv', '"1","Alpha"<LF>"2","Beta"<LF>"3","Gamma"');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedExport(Observer, 'getRec2', 'getRec', 'quit', 2);
        ArmedExport(Observer, 'preItem1', 'preItem', 'quit', 1);
        ArmedExport(Observer, 'idBefore2', 'idBefore', 'quit', 2);
        ArmedExport(Observer, 'nameBefore2', 'nameBefore', 'quit', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2 quit;');
        Observer.Expect('getRec2 csv', '"1","Alpha"');
        Observer.Expect('preItem1 log', 'init 1;init done;prePort 1;prePort done;preItem 1 quit;');
        Observer.Expect('preItem1 csv', '');
        Observer.Expect('idBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2 quit;');
        Observer.Expect('idBefore2 csv', '"1","Alpha"');
        Observer.Expect('nameBefore2 log', 'init 1;init done;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2 quit;');
        Observer.Expect('nameBefore2 csv', '"1","Alpha"<LF>"2"');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_Init_Skip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedExport(Observer, 'init1', 'init', 'skip', 1);
        Observer.Expect('init1 log', 'init 1 skip;prePort 1;prePort done;preItem 1;preItem done;getRec 1;getRec done;idBefore 1;idBefore done;nameBefore 1;nameBefore done;getRec 2;getRec done;idBefore 2;idBefore done;nameBefore 2;nameBefore done;getRec 3;getRec done;idBefore 3;idBefore done;nameBefore 3;nameBefore done;postPort 1;postPort done;');
        Observer.Expect('init1 csv', '"1","Alpha"<LF>"2","Beta"<LF>"3","Gamma"');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Export_Init_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedExport(Observer, 'init1', 'init', 'quit', 1);
        Observer.Expect('init1 log', 'init 1 quit;');
        Observer.Expect('init1 csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Import_Skip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedImport2(Observer, 'getRec2', 'getRec', 'skip', 2);
        ArmedImport2(Observer, 'beforeIns2', 'beforeIns', 'skip', 2);
        ArmedImport2(Observer, 'afterIns2', 'afterIns', 'skip', 2);
        ArmedImport2(Observer, 'idAfter2', 'idAfter', 'skip', 2);
        ArmedImport2(Observer, 'nameAfter2', 'nameAfter', 'skip', 2);
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
        ArmedImport2(Observer, 'getRec2', 'getRec', 'break', 2);
        ArmedImport2(Observer, 'beforeIns2', 'beforeIns', 'break', 2);
        ArmedImport2(Observer, 'afterIns2', 'afterIns', 'break', 2);
        ArmedImport2(Observer, 'idAfter2', 'idAfter', 'break', 2);
        ArmedImport2(Observer, 'nameAfter2', 'nameAfter', 'break', 2);
        Observer.Expect('getRec2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('getRec2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Expect('beforeIns2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2 break;postPort 1;postPort done;');
        Observer.Expect('beforeIns2 rows', '[1=Alpha/0;]');
        Observer.Expect('afterIns2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2;nameAfter done;beforeIns 2;beforeIns done;afterIns 2 break;postPort 1;postPort done;');
        Observer.Expect('afterIns2 rows', '[1=Alpha/0;2=Beta/0;]');
        Observer.Expect('idAfter2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2 break;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 2;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('idAfter2 rows', '[1=Alpha/0;2=/0;3=Gamma/0;]');
        Observer.Expect('nameAfter2 log', 'init 1;init done;prePort 1;prePort done;idAfter 1;idAfter done;nameAfter 1;nameAfter done;beforeIns 1;beforeIns done;afterIns 1;afterIns done;idAfter 2;idAfter done;nameAfter 2 break;beforeIns 2;beforeIns done;afterIns 2;afterIns done;idAfter 3;idAfter done;nameAfter 3;nameAfter done;beforeIns 3;beforeIns done;afterIns 3;afterIns done;postPort 1;postPort done;');
        Observer.Expect('nameAfter2 rows', '[1=Alpha/0;2=Beta/0;3=Gamma/0;]');
        Observer.Verify();
    end;





    [Test]
    procedure P112_Import_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArmedImport2(Observer, 'getRec2', 'getRec', 'unbound', 2);
        ArmedImport2(Observer, 'beforeIns2', 'beforeIns', 'unbound', 2);
        ArmedImport2(Observer, 'idAfter2', 'idAfter', 'unbound', 2);
        ArmedImport2(Observer, 'nameAfter2', 'nameAfter', 'unbound', 2);
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
        ArmedImport2(Observer, 'getRec2', 'getRec', 'quit', 2);
        ArmedImport2(Observer, 'beforeIns2', 'beforeIns', 'quit', 2);
        ArmedImport2(Observer, 'idAfter2', 'idAfter', 'quit', 2);
        ArmedImport2(Observer, 'nameAfter2', 'nameAfter', 'quit', 2);
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
        ArmedImport2(Observer, 'preItem skip', 'preItem', 'skip', 1);
        ArmedImport2(Observer, 'preItem break', 'preItem', 'break', 1);
        ArmedImport2(Observer, 'preItem quit', 'preItem', 'quit', 1);
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
        asserterror ArmedImport(Observer, 'init skip', 'init', 'skip', 1);
        Observer.ObserveError('af540');
        ArmedImport(Observer, 'init quit', 'init', 'quit', 1);
        Observer.Expect('af540|text', 'If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.');
        Observer.Expect('af540|code', 'XmlPortInvalidNodeType');
        Observer.Expect('init quit log', 'init 1 quit;');
        Observer.Expect('init quit rows', '[]');
        Observer.Verify();
    end;
}
