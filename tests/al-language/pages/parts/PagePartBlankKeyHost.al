// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 74769 and 74770, log 74794, pages 74768-74769, test codeunit 74793
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: a card opened with TestPage.OpenNew whose list part is linked on the card's key (SubPageLink "Host Code" = field(Code)), where the key is left BLANK: a line is
//   written in the part (a) with nothing else typed in the host, (b) after another host field was typed, (c) twice. Is the host row saved first, with which key, and the
//   order of the table triggers (host OnInsert, line OnInsert) and page triggers (host OnNewRecord, line OnNewRecord) in the log; rows in each table afterwards, and the
//   link value of the line. Contrast with PagePartLinkUnsavedHost.al, where the key is typed before the line.
// BC versions: all (CI)

table 74769 "LT PBK Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Descr; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT PBK Log";
    begin
        Log.Add('HostOnInsert code=[' + "Code" + '] descr=[' + Descr + ']');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT PBK Log";
    begin
        Log.Add('HostOnModify code=[' + "Code" + ']');
    end;
}

table 74770 "LT PBK Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Host Code"; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[30]) { }
    }

    keys { key(PK; "Host Code", "Line No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT PBK Log";
    begin
        Log.Add('LineOnInsert host=[' + "Host Code" + '] no=' + Format("Line No."));
    end;
}

codeunit 74794 "LT PBK Log"
{
    SingleInstance = true;

    var
        Buffer: Text;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;
}

page 74768 "LT PBK Lines"
{
    PageType = ListPart;
    SourceTable = "LT PBK Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT PBK Log";
    begin
        Log.Add('LineOnNewRecord host=[' + Rec."Host Code" + ']');
    end;
}

page 74769 "LT PBK Card"
{
    PageType = Card;
    SourceTable = "LT PBK Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
            part(Lines; "LT PBK Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Host Code" = field("Code");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT PBK Log";
    begin
        Log.Add('HostOnNewRecord');
    end;
}

codeunit 74793 "LT PBK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT PBK Log";

    local procedure Seed()
    var
        Host: Record "LT PBK Host";
        Line: Record "LT PBK Line";
    begin
        Host.DeleteAll();
        Line.DeleteAll();
        Log.Take();
    end;

    local procedure ObserveDb(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Host: Record "LT PBK Host";
        Line: Record "LT PBK Line";
    begin
        Observer.Observe(Prefix + 'Hosts', Format(Host.Count()));
        Observer.Observe(Prefix + 'Lines', Format(Line.Count()));
        if Host.FindFirst() then
            Observer.Observe(Prefix + 'HostKey', '[' + Host."Code" + ']');
        if Line.FindFirst() then
            Observer.Observe(Prefix + 'LineHostCode', '[' + Line."Host Code" + '] no=' + Format(Line."Line No."));
    end;

    [Test]
    procedure BlankKey_LineWrittenFirst()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PBK Card";
    begin
        Seed();
        TP.OpenNew();
        Observer.Observe('afterOpen', Log.Take());
        TP.Lines."Line No.".SetValue(1);
        Observer.Observe('afterLineNo', Log.Take());
        TP.Lines.Descr.SetValue('line');
        Observer.Observe('afterLineDescr', Log.Take());
        TP.Close();
        Observer.Observe('afterClose', Log.Take());
        ObserveDb(Observer, 'db');
        Observer.Expect('afterOpen', 'HostOnNewRecord;LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];');
        Observer.Expect('afterLineNo', 'HostOnInsert code=[] descr=[];LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];');
        Observer.Expect('afterLineDescr', 'LineOnInsert host=[] no=1;');
        Observer.Expect('afterClose', '');
        Observer.Expect('dbHosts', '1');
        Observer.Expect('dbLines', '1');
        Observer.Expect('dbHostKey', '[]');
        Observer.Expect('dbLineHostCode', '[] no=1');
        Observer.Verify();
    end;

    [Test]
    procedure BlankKey_HostFieldTypedThenLine()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PBK Card";
    begin
        Seed();
        TP.OpenNew();
        TP.Descr.SetValue('host descr');
        Observer.Observe('afterHostDescr', Log.Take());
        TP.Lines."Line No.".SetValue(1);
        Observer.Observe('afterLineNo', Log.Take());
        TP.Lines.Descr.SetValue('line');
        TP.Close();
        Observer.Observe('afterClose', Log.Take());
        ObserveDb(Observer, 'db');
        Observer.Expect('afterHostDescr', 'HostOnNewRecord;LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];HostOnInsert code=[] descr=[];LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];');
        Observer.Expect('afterLineNo', 'HostOnModify code=[];LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];');
        Observer.Expect('afterClose', 'LineOnInsert host=[] no=1;');
        Observer.Expect('dbHosts', '1');
        Observer.Expect('dbLines', '1');
        Observer.Expect('dbHostKey', '[]');
        Observer.Expect('dbLineHostCode', '[] no=1');
        Observer.Verify();
    end;

    [Test]
    procedure BlankKey_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PBK Card";
    begin
        Seed();
        TP.OpenNew();
        TP.Lines."Line No.".SetValue(1);
        TP.Lines.Descr.SetValue('first');
        TP.Lines.New();
        Observer.Observe('afterNewLine', Log.Take());
        TP.Lines."Line No.".SetValue(2);
        TP.Lines.Descr.SetValue('second');
        TP.Close();
        Observer.Observe('afterClose', Log.Take());
        ObserveDb(Observer, 'db');
        Observer.Expect('afterNewLine', 'HostOnNewRecord;LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];HostOnInsert code=[] descr=[];LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnInsert host=[] no=1;LineOnNewRecord host=[];');
        Observer.Expect('afterClose', 'LineOnInsert host=[] no=2;');
        Observer.Expect('dbHosts', '1');
        Observer.Expect('dbLines', '2');
        Observer.Expect('dbHostKey', '[]');
        Observer.Expect('dbLineHostCode', '[] no=1');
        Observer.Verify();
    end;

    [Test]
    procedure TypedKey_ThenLine_Contrast()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PBK Card";
    begin
        Seed();
        TP.OpenNew();
        TP."Code".SetValue('H1');
        Observer.Observe('afterKey', Log.Take());
        TP.Lines."Line No.".SetValue(1);
        TP.Lines.Descr.SetValue('line');
        TP.Close();
        Observer.Observe('afterClose', Log.Take());
        ObserveDb(Observer, 'db');
        Observer.Expect('afterKey', 'HostOnNewRecord;LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];LineOnNewRecord host=[];');
        Observer.Expect('afterClose', 'HostOnInsert code=[H1] descr=[];LineOnNewRecord host=[H1];LineOnNewRecord host=[H1];LineOnNewRecord host=[H1];LineOnInsert host=[H1] no=1;');
        Observer.Expect('dbHosts', '1');
        Observer.Expect('dbLines', '1');
        Observer.Expect('dbHostKey', '[H1]');
        Observer.Expect('dbLineHostCode', '[H1] no=1');
        Observer.Verify();
    end;
}
