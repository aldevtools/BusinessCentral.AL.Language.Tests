// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects: tables 95760-95761, codeunit 95762 (log), xmlports 95763-95764, test codeunit 95765.
// Probe: al-runner issue 6924 (Microsoft's PEPPOL 3.0 sales invoice port: the line-level AllowanceCharge table element over Integer, with
//   SourceTableView = sorting(Number) where(Number = filter(1 ..)), sits inside the invoice line table element and sets SetRange(Number, 1, 1)
//   in OnPreXmlItem at every line). A table element without LinkTable right below another table element, with a SourceTableView that has a
//   sorting and a filter, passed once per row of the element above. Questions: what each pass starts with (filters, count, key, direction)
//   when OnPreXmlItem sets nothing, sets a filter at every pass, sets a filter, a key, a direction or a Reset at the first pass only; which
//   rows each pass writes; the same over Integer as PEPPOL does; and what an import does with the view (rows outside the filter, the
//   filters a trigger sees).
//   Log: pre h<head> f=<GetFilters> n=<Count> k=<CurrentKey> a=<Ascending> = OnPreXmlItem of the inner element, before its own code;
//   get <entry> = OnAfterGetRecord; ins ... = OnBeforeInsertRecord.
// Facts (BC 29.0 on the corpus CI): export: every pass of the inner element starts from its SourceTableView alone, whatever OnPreXmlItem of
//   an earlier pass did: GetFilters is empty (the view's filter does not show) but Count counts only Qty > 0, the key is the view's (Kind),
//   ascending. A filter set at every pass, or only at the first, a SetCurrentKey, Ascending(false) or a Reset at the first pass, all hold for
//   that pass only (after Reset that pass reads every row in primary key order, Qty 0 included). Over Integer with
//   where(Number = filter(1 ..)), SetRange(Number, 1, 1) or SetRange(Number, 1, <head>) in OnPreXmlItem gives each pass its own rows; a Skip
//   in OnAfterGetRecord leaves the head element empty. Import: the view filters nothing (rows with Qty 0 and -1 are stored), the rows below a
//   head are stored before the head, GetFilters is empty in OnBeforeInsertRecord, and CurrentKey there is the view's key (Kind) for the
//   first row of the import and the primary key (Entry) for every later row.
// Neighbours: xmlports/shapes-properties/QrXpContainerOccurs.al TU_* (the same without a SourceTableView), streams/Y72XpEInvoiceShapes.al
//   (an Integer element with this view passed once), xmlports/shapes-properties/TsXpObjects.al (a view on a second export).
// BC versions: all (CI)

table 95760 "LT R6924x Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 95761 "LT R6924x Part"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Entry; Integer) { }
        field(2; Kind; Code[10]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Entry) { Clustered = true; }
        key(ByKind; Kind) { }
    }
}

codeunit 95762 "LT R6924x View Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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
}

xmlport 95763 "LT R6924x Nested View"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Head; "LT R6924x Head")
            {
                fieldattribute(No; Head."No.") { }
                tableelement(Part; "LT R6924x Part")
                {
                    MinOccurs = Zero;
                    SourceTableView = sorting(Kind) where(Qty = filter(> 0));
                    fieldattribute(Entry; Part.Entry) { }
                    fieldattribute(Kind; Part.Kind) { }
                    fieldattribute(Qty; Part.Qty) { }

                    trigger OnPreXmlItem()
                    begin
                        Log.Add('pre h' + Format(Head."No.") + ' f=' + Part.GetFilters() + ' n=' + Format(Part.Count()) + ' k=' + Part.CurrentKey() + ' a=' + Format(Part.Ascending()));
                        case Mode of
                            'each':
                                case Head."No." of
                                    1:
                                        Part.SetRange(Kind, 'A');
                                    2:
                                        Part.SetRange(Kind, 'B');
                                end;
                            'first':
                                if Head."No." = 1 then
                                    Part.SetRange(Kind, 'A');
                            'key':
                                if Head."No." = 1 then
                                    Part.SetCurrentKey(Entry);
                            'desc':
                                if Head."No." = 1 then
                                    Part.Ascending(false);
                            'reset':
                                if Head."No." = 1 then
                                    Part.Reset();
                        end;
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('get ' + Format(Part.Entry));
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        Log.Add('ins p' + Format(Part.Entry) + ' f=' + Part.GetFilters() + ' k=' + Part.CurrentKey());
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins h' + Format(Head."No."));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT R6924x View Log";
        Mode: Text;

    procedure SetMode(NewMode: Text)
    begin
        Mode := NewMode;
    end;
}

xmlport 95764 "LT R6924x Integer View"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Head; "LT R6924x Head")
            {
                fieldattribute(No; Head."No.") { }
                tableelement(ChargeLoop; Integer)
                {
                    MinOccurs = Zero;
                    XmlName = 'Charge';
                    SourceTableView = sorting(Number) where(Number = filter(1 ..));
                    fieldattribute(N; ChargeLoop.Number) { }

                    trigger OnPreXmlItem()
                    begin
                        Log.Add('pre h' + Format(Head."No.") + ' f=' + ChargeLoop.GetFilters());
                        if Grow then
                            ChargeLoop.SetRange(Number, 1, Head."No.")
                        else
                            ChargeLoop.SetRange(Number, 1, 1);
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('get h' + Format(Head."No.") + ' n' + Format(ChargeLoop.Number));
                        if Head."No." = 2 then
                            currXMLport.Skip();
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT R6924x View Log";
        Grow: Boolean;

    procedure SetGrow(NewGrow: Boolean)
    begin
        Grow := NewGrow;
    end;
}

codeunit 95765 "LT R6924x Nested View Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT R6924x View Log";

    local procedure Start()
    var
        Head: Record "LT R6924x Head";
        Part: Record "LT R6924x Part";
    begin
        ClearLastError();
        Log.Take();
        Head.DeleteAll();
        Part.DeleteAll();
    end;

    local procedure Seed()
    var
        Head: Record "LT R6924x Head";
        No: Integer;
    begin
        for No := 1 to 3 do begin
            Head."No." := No;
            Head.Insert();
        end;
        AddPart(1, 'B', 1);
        AddPart(2, 'A', 2);
        AddPart(3, 'A', 0);
        AddPart(4, 'C', 5);
        AddPart(5, 'B', 3);
    end;

    local procedure AddPart(Entry: Integer; Kind: Code[10]; Qty: Integer)
    var
        Part: Record "LT R6924x Part";
    begin
        Part.Entry := Entry;
        Part.Kind := Kind;
        Part.Qty := Qty;
        Part.Insert();
    end;

    local procedure ReadLines(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line.Trim() + '|';
        end;
        exit(Result);
    end;

    local procedure ExportNested(var Observer: Codeunit "Probe Observer"; Mode: Text)
    var
        XP: XmlPort "LT R6924x Nested View";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        XP.SetMode(Mode);
        XP.SetDestination(OutS);
        XP.Export();
        Observer.Observe('xml', ReadLines(TempBlob));
        Observer.Observe('log', Log.Take());
    end;

    local procedure ExportInteger(var Observer: Codeunit "Probe Observer"; Grow: Boolean)
    var
        XP: XmlPort "LT R6924x Integer View";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        XP.SetGrow(Grow);
        XP.SetDestination(OutS);
        XP.Export();
        Observer.Observe('xml', ReadLines(TempBlob));
        Observer.Observe('log', Log.Take());
    end;

    [Test]
    procedure NestedView_Export_NoCode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Seed();
        ExportNested(Observer, '');
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|<Head No="1">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|<Head No="2">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|<Head No="3">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|</Root>|');
        Observer.Expect('log', 'pre h1 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;pre h2 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;pre h3 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;');
        Observer.Verify();
    end;

    [Test]
    procedure NestedView_Export_FilterEachPass()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Seed();
        ExportNested(Observer, 'each');
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|<Head No="1">|<Part Entry="2" Kind="A" Qty="2" />|</Head>|<Head No="2">|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|</Head>|<Head No="3">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|</Root>|');
        Observer.Expect('log', 'pre h1 f= n=4 k=Kind a=Yes;get 2;pre h2 f= n=4 k=Kind a=Yes;get 1;get 5;pre h3 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;');
        Observer.Verify();
    end;

    [Test]
    procedure NestedView_Export_FilterFirstPass()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Seed();
        ExportNested(Observer, 'first');
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|<Head No="1">|<Part Entry="2" Kind="A" Qty="2" />|</Head>|<Head No="2">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|<Head No="3">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|</Root>|');
        Observer.Expect('log', 'pre h1 f= n=4 k=Kind a=Yes;get 2;pre h2 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;pre h3 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;');
        Observer.Verify();
    end;

    [Test]
    procedure NestedView_Export_KeyFirstPass()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Seed();
        ExportNested(Observer, 'key');
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|<Head No="1">|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="4" Kind="C" Qty="5" />|<Part Entry="5" Kind="B" Qty="3" />|</Head>|<Head No="2">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|<Head No="3">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|</Root>|');
        Observer.Expect('log', 'pre h1 f= n=4 k=Kind a=Yes;get 1;get 2;get 4;get 5;pre h2 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;pre h3 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;');
        Observer.Verify();
    end;

    [Test]
    procedure NestedView_Export_DescendingFirstPass()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Seed();
        ExportNested(Observer, 'desc');
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|<Head No="1">|<Part Entry="4" Kind="C" Qty="5" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="2" Kind="A" Qty="2" />|</Head>|<Head No="2">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|<Head No="3">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|</Root>|');
        Observer.Expect('log', 'pre h1 f= n=4 k=Kind a=Yes;get 4;get 5;get 1;get 2;pre h2 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;pre h3 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;');
        Observer.Verify();
    end;

    [Test]
    procedure NestedView_Export_ResetFirstPass()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Seed();
        ExportNested(Observer, 'reset');
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|<Head No="1">|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="3" Kind="A" Qty="0" />|<Part Entry="4" Kind="C" Qty="5" />|<Part Entry="5" Kind="B" Qty="3" />|</Head>|<Head No="2">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|<Head No="3">|<Part Entry="2" Kind="A" Qty="2" />|<Part Entry="1" Kind="B" Qty="1" />|<Part Entry="5" Kind="B" Qty="3" />|<Part Entry="4" Kind="C" Qty="5" />|</Head>|</Root>|');
        Observer.Expect('log', 'pre h1 f= n=4 k=Kind a=Yes;get 1;get 2;get 3;get 4;get 5;pre h2 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;pre h3 f= n=4 k=Kind a=Yes;get 2;get 1;get 5;get 4;');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerView_Export_OneEachPass()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Seed();
        ExportInteger(Observer, false);
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|<Head No="1">|<Charge N="1" />|</Head>|<Head No="2" />|<Head No="3">|<Charge N="1" />|</Head>|</Root>|');
        Observer.Expect('log', 'pre h1 f=;get h1 n1;pre h2 f=;get h2 n1;pre h3 f=;get h3 n1;');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerView_Export_GrowEachPass()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Seed();
        ExportInteger(Observer, true);
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|<Head No="1">|<Charge N="1" />|</Head>|<Head No="2" />|<Head No="3">|<Charge N="1" />|<Charge N="2" />|<Charge N="3" />|</Head>|</Root>|');
        Observer.Expect('log', 'pre h1 f=;get h1 n1;pre h2 f=;get h2 n1;get h2 n2;pre h3 f=;get h3 n1;get h3 n2;get h3 n3;');
        Observer.Verify();
    end;

    [Test]
    procedure NestedView_Import_RowsOutsideTheView()
    var
        Observer: Codeunit "Probe Observer";
        XP: XmlPort "LT R6924x Nested View";
        TempBlob: Codeunit "Temp Blob";
        Head: Record "LT R6924x Head";
        Part: Record "LT R6924x Part";
        OutS: OutStream;
        InS: InStream;
        Rows: Text;
    begin
        Start();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Head No="1"><Part Entry="1" Kind="B" Qty="1" /><Part Entry="3" Kind="A" Qty="0" /></Head><Head No="2"><Part Entry="2" Kind="A" Qty="2" /><Part Entry="4" Kind="C" Qty="-1" /></Head></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        XP.SetSource(InS);
        XP.Import();
        if Head.FindSet() then
            repeat
                Rows += 'H' + Format(Head."No.") + ';';
            until Head.Next() = 0;
        if Part.FindSet() then
            repeat
                Rows += 'P' + Format(Part.Entry) + ' ' + Part.Kind + ' ' + Format(Part.Qty) + ';';
            until Part.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Observe('log', Log.Take());
        Observer.Expect('rows', 'H1;H2;P1 B 1;P2 A 2;P3 A 0;P4 C -1;');
        Observer.Expect('log', 'ins p1 f= k=Kind;ins p3 f= k=Entry;ins h1;ins p2 f= k=Entry;ins p4 f= k=Entry;ins h2;');
        Observer.Verify();
    end;
}
