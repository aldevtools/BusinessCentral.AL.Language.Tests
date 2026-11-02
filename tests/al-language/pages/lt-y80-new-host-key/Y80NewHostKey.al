// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT Y80 Log" (pages/lt-y80-gone-rows/Y80GoneRows.al); own objects 94280 - 94286
// Probe (writer Y80, from the runtime lane rt-pages-1102c): a key field typed on a NEW host row (OpenNew) whose part is linked on that key
//   (SubPageLink "Document No." = field("No.")), after a field outside the key was typed first (the host row is then stored with a blank key, or not),
//   before it, and in between a line typed into the part. pages/lt-new-line-stamps-filters/NewLineStampsFilters.al:264 PartB_OpenNewHeader_TypeThenNo
//   and :289 pin one shape each; the rule behind them is not known. Here the host is a Card and a Document, with a header OnInsert / OnModify / OnNewRecord
//   log, the part's OnNewRecord / OnInsert log, and the rows stored in the tables after each step (key|name for the headers, document/line|text for the lines).
// BC versions: 27, 28, 29

table 94280 "LT Y80 NH Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20])
        {
            trigger OnValidate()
            var
                Log: Record "LT Y80 Log";
            begin
                Log.Add('HV:' + "No.");
            end;
        }
        field(2; Name; Text[30]) { }
        field(3; "Group Code"; Code[20]) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('HI:' + "No." + '|' + Name);
    end;

    trigger OnModify()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('HM:' + "No." + '|' + Name);
    end;
}

table 94281 "LT Y80 NH Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[30]) { }
    }
    keys { key(PK; "Document No.", "Line No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('LI:' + "Document No." + '/' + Format("Line No.") + '|' + Descr);
    end;
}

page 94282 "LT Y80 NH Lines"
{
    PageType = ListPart;
    SourceTable = "LT Y80 NH Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(DocCtl; Rec."Document No.") { ApplicationArea = All; }
                field(LineCtl; Rec."Line No.") { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('LN:' + Rec."Document No.");
    end;
}

page 94283 "LT Y80 NH Card"
{
    PageType = Card;
    SourceTable = "LT Y80 NH Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(GroupCtl; Rec."Group Code") { ApplicationArea = All; }
            part(Lines; "LT Y80 NH Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('PN');
    end;
}

page 94284 "LT Y80 NH Doc"
{
    PageType = Document;
    SourceTable = "LT Y80 NH Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(GroupCtl; Rec."Group Code") { ApplicationArea = All; }
            part(Lines; "LT Y80 NH Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('PN');
    end;
}

codeunit 94286 "LT Y80 NH Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Head: Record "LT Y80 NH Head";
        Line: Record "LT Y80 NH Line";
        Log: Record "LT Y80 Log";
    begin
        ClearLastError();
        Head.DeleteAll();
        Line.DeleteAll();
        Log.DeleteAll();
    end;

    local procedure OpenLog(): Text
    var
        Log: Record "LT Y80 Log";
    begin
        exit(Log.Take());
    end;

    local procedure Db(): Text
    var
        Head: Record "LT Y80 NH Head";
        Line: Record "LT Y80 NH Line";
        Result: Text;
    begin
        if Head.FindSet() then
            repeat
                Result += '[' + Head."No." + '|' + Head.Name + '|' + Head."Group Code" + ']';
            until Head.Next() = 0;
        Result += ' lines ';
        if Line.FindSet() then
            repeat
                Result += '[' + Line."Document No." + '/' + Format(Line."Line No.") + '|' + Line.Descr + ']';
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure Step(Name: Text; Ok: Boolean)
    var
        Log: Record "LT Y80 Log";
    begin
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', Log.Take());
        Observer.Observe(Name + ' db', Db());
    end;

    [TryFunction]
    local procedure TryCard(var P: TestPage "LT Y80 NH Card"; Which: Text)
    begin
        case Which of
            'name':
                P.NameCtl.SetValue('N1');
            'group':
                P.GroupCtl.SetValue('G1');
            'no':
                P.NoCtl.SetValue('A1');
            'line':
                P.Lines.DescrCtl.SetValue('d1');
            'newline':
                P.Lines.New();
            'line2':
                P.Lines.DescrCtl.SetValue('d2');
            'close':
                P.Close();
        end;
    end;

    local procedure ShownCard(var P: TestPage "LT Y80 NH Card"): Text
    var
        Result: Text;
    begin
        Result := P.NoCtl.Value() + '|' + P.NameCtl.Value() + '|' + P.GroupCtl.Value() + ' part ';
        if P.Lines.First() then
            repeat
                Result += '[' + P.Lines.DocCtl.Value() + '/' + P.Lines.LineCtl.Value() + '|' + P.Lines.DescrCtl.Value() + ']';
            until not P.Lines.Next();
        exit(Result);
    end;

#if BC28PLUS
    [Test]
    procedure Y80_NH_Card_NameThenNo()
    var
        P: TestPage "LT Y80 NH Card";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownCard(P));
        Observer.Observe('read log at open', OpenLog());
        Step('name', TryCard(P, 'name'));
        Observer.Observe('shown after name', ShownCard(P));
        Observer.Observe('read log after name', OpenLog());
        Step('no', TryCard(P, 'no'));
        Observer.Observe('shown after no', ShownCard(P));
        Observer.Observe('read log after no', OpenLog());
        Step('close', TryCard(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'HV:A1');
        Observer.Expect('no db', '[||] lines ');
        Observer.Expect('shown after no', '|N1| part ');
        Observer.Expect('read log after no', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('close db', '[||] lines ');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure Y80_NH_Card_NoThenName()
    var
        P: TestPage "LT Y80 NH Card";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownCard(P));
        Observer.Observe('read log at open', OpenLog());
        Step('no', TryCard(P, 'no'));
        Observer.Observe('shown after no', ShownCard(P));
        Observer.Observe('read log after no', OpenLog());
        Step('name', TryCard(P, 'name'));
        Observer.Observe('shown after name', ShownCard(P));
        Observer.Observe('read log after name', OpenLog());
        Step('close', TryCard(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'HV:A1');
        Observer.Expect('no db', '[||] lines ');
        Observer.Expect('shown after no', '|| part ');
        Observer.Expect('read log after no', '');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', 'HM:|N1');
        Observer.Expect('close db', '[|N1|] lines ');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure Y80_NH_Card_GroupThenNo()
    var
        P: TestPage "LT Y80 NH Card";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownCard(P));
        Observer.Observe('read log at open', OpenLog());
        Step('group', TryCard(P, 'group'));
        Observer.Observe('shown after group', ShownCard(P));
        Observer.Observe('read log after group', OpenLog());
        Step('no', TryCard(P, 'no'));
        Observer.Observe('shown after no', ShownCard(P));
        Observer.Observe('read log after no', OpenLog());
        Step('close', TryCard(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('group ok', 'Yes');
        Observer.Expect('group|text', '');
        Observer.Expect('group|code', '');
        Observer.Expect('group log', 'LN:;LN:;LN:');
        Observer.Expect('group db', '[||] lines ');
        Observer.Expect('shown after group', '||G1 part ');
        Observer.Expect('read log after group', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'HV:A1');
        Observer.Expect('no db', '[||] lines ');
        Observer.Expect('shown after no', '||G1 part ');
        Observer.Expect('read log after no', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('close db', '[||] lines ');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure Y80_NH_Card_NameLineThenNo()
    var
        P: TestPage "LT Y80 NH Card";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownCard(P));
        Observer.Observe('read log at open', OpenLog());
        Step('name', TryCard(P, 'name'));
        Observer.Observe('shown after name', ShownCard(P));
        Observer.Observe('read log after name', OpenLog());
        Step('line', TryCard(P, 'line'));
        Observer.Observe('shown after line', ShownCard(P));
        Observer.Observe('read log after line', OpenLog());
        Step('no', TryCard(P, 'no'));
        Observer.Observe('shown after no', ShownCard(P));
        Observer.Observe('read log after no', OpenLog());
        Step('close', TryCard(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', 'HM:|N1;LN:;LN:;LN:');
        Observer.Expect('line db', '[|N1|] lines ');
        Observer.Expect('shown after line', '|N1| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'LI:/10000|d1;HV:A1');
        Observer.Expect('no db', '[|N1|] lines [/10000|d1]');
        Observer.Expect('shown after no', '|N1| part [/10000|d1][/0|]');
        Observer.Expect('read log after no', 'LN:');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('close db', '[|N1|] lines [/10000|d1]');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure Y80_NH_Card_NameNoThenLine()
    var
        P: TestPage "LT Y80 NH Card";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownCard(P));
        Observer.Observe('read log at open', OpenLog());
        Step('name', TryCard(P, 'name'));
        Observer.Observe('shown after name', ShownCard(P));
        Observer.Observe('read log after name', OpenLog());
        Step('no', TryCard(P, 'no'));
        Observer.Observe('shown after no', ShownCard(P));
        Observer.Observe('read log after no', OpenLog());
        Step('line', TryCard(P, 'line'));
        Observer.Observe('shown after line', ShownCard(P));
        Observer.Observe('read log after line', OpenLog());
        Step('close', TryCard(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'HV:A1');
        Observer.Expect('no db', '[||] lines ');
        Observer.Expect('shown after no', '|N1| part ');
        Observer.Expect('read log after no', '');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', '');
        Observer.Expect('line db', '[||] lines ');
        Observer.Expect('shown after line', '|N1| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', 'LI:/10000|d1');
        Observer.Expect('close db', '[||] lines [/10000|d1]');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure Y80_NH_Card_NameThenLineOnly()
    var
        P: TestPage "LT Y80 NH Card";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownCard(P));
        Observer.Observe('read log at open', OpenLog());
        Step('name', TryCard(P, 'name'));
        Observer.Observe('shown after name', ShownCard(P));
        Observer.Observe('read log after name', OpenLog());
        Step('line', TryCard(P, 'line'));
        Observer.Observe('shown after line', ShownCard(P));
        Observer.Observe('read log after line', OpenLog());
        Step('close', TryCard(P, 'close'));
#if BC29PLUS
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', 'HM:|N1;LN:;LN:;LN:');
        Observer.Expect('line db', '[|N1|] lines ');
        Observer.Expect('shown after line', '|N1| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', 'LI:/10000|d1');
        Observer.Expect('close db', '[|N1|] lines [/10000|d1]');
#elif BC28PLUS
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', 'HM:|N1;LN:;LN:;LN:');
        Observer.Expect('line db', '[|N1|] lines ');
        Observer.Expect('shown after line', '|N1| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', 'LI:/10000|d1');
        Observer.Expect('close db', '[|N1|] lines [/10000|d1]');
#else
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('group ok', 'Yes');
        Observer.Expect('group|text', '');
        Observer.Expect('group|code', '');
        Observer.Expect('group log', 'LN:;LN:;LN:');
        Observer.Expect('group db', '[||] lines ');
        Observer.Expect('shown after group', '||G1 part ');
        Observer.Expect('read log after group', '');
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', 'HM:|N1;LN:;LN:;LN:');
        Observer.Expect('line db', '[|N1|] lines ');
        Observer.Expect('shown after line', '|N1| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', 'HM:|N1;LN:;LN:;LN:');
        Observer.Expect('line db', '[|N1|] lines ');
        Observer.Expect('shown after line', '|N1| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', 'LI:/10000|d1');
        Observer.Expect('close db', '[|N1|] lines [/10000|d1]');
#endif
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure Y80_NH_Card_LineOnlyThenNo()
    var
        P: TestPage "LT Y80 NH Card";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownCard(P));
        Observer.Observe('read log at open', OpenLog());
        Step('line', TryCard(P, 'line'));
        Observer.Observe('shown after line', ShownCard(P));
        Observer.Observe('read log after line', OpenLog());
        Step('no', TryCard(P, 'no'));
        Observer.Observe('shown after no', ShownCard(P));
        Observer.Observe('read log after no', OpenLog());
        Step('close', TryCard(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', '');
        Observer.Expect('line db', '[||] lines ');
        Observer.Expect('shown after line', '|| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'LI:/10000|d1;HV:A1');
        Observer.Expect('no db', '[||] lines [/10000|d1]');
        Observer.Expect('shown after no', '|| part [/10000|d1][/0|]');
        Observer.Expect('read log after no', 'LN:');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('close db', '[||] lines [/10000|d1]');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure Y80_NH_Card_NameNoLineTwo()
    var
        P: TestPage "LT Y80 NH Card";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownCard(P));
        Observer.Observe('read log at open', OpenLog());
        Step('name', TryCard(P, 'name'));
        Observer.Observe('shown after name', ShownCard(P));
        Observer.Observe('read log after name', OpenLog());
        Step('no', TryCard(P, 'no'));
        Observer.Observe('shown after no', ShownCard(P));
        Observer.Observe('read log after no', OpenLog());
        Step('line', TryCard(P, 'line'));
        Observer.Observe('shown after line', ShownCard(P));
        Observer.Observe('read log after line', OpenLog());
        Step('newline', TryCard(P, 'newline'));
        Observer.Observe('shown after newline', ShownCard(P));
        Observer.Observe('read log after newline', OpenLog());
        Step('line2', TryCard(P, 'line2'));
        Observer.Observe('shown after line2', ShownCard(P));
        Observer.Observe('read log after line2', OpenLog());
        Step('close', TryCard(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'HV:A1');
        Observer.Expect('no db', '[||] lines ');
        Observer.Expect('shown after no', '|N1| part ');
        Observer.Expect('read log after no', '');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', '');
        Observer.Expect('line db', '[||] lines ');
        Observer.Expect('shown after line', '|N1| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('newline ok', 'Yes');
        Observer.Expect('newline|text', '');
        Observer.Expect('newline|code', '');
        Observer.Expect('newline log', 'LI:/10000|d1;LN:');
        Observer.Expect('newline db', '[||] lines [/10000|d1]');
        Observer.Expect('shown after newline', '|N1| part [/10000|d1][/0|]');
        Observer.Expect('read log after newline', 'LN:');
        Observer.Expect('line2 ok', 'Yes');
        Observer.Expect('line2|text', '');
        Observer.Expect('line2|code', '');
        Observer.Expect('line2 log', '');
        Observer.Expect('line2 db', '[||] lines [/10000|d1]');
        Observer.Expect('shown after line2', '|N1| part [/10000|d1][/20000|d2][/0|]');
        Observer.Expect('read log after line2', 'LI:/20000|d2;LN:');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('close db', '[||] lines [/10000|d1][/20000|d2]');
        Observer.Verify();
    end;
#endif

    [TryFunction]
    local procedure TryDoc(var P: TestPage "LT Y80 NH Doc"; Which: Text)
    begin
        case Which of
            'name':
                P.NameCtl.SetValue('N1');
            'group':
                P.GroupCtl.SetValue('G1');
            'no':
                P.NoCtl.SetValue('A1');
            'line':
                P.Lines.DescrCtl.SetValue('d1');
            'newline':
                P.Lines.New();
            'line2':
                P.Lines.DescrCtl.SetValue('d2');
            'close':
                P.Close();
        end;
    end;

    local procedure ShownDoc(var P: TestPage "LT Y80 NH Doc"): Text
    var
        Result: Text;
    begin
        Result := P.NoCtl.Value() + '|' + P.NameCtl.Value() + '|' + P.GroupCtl.Value() + ' part ';
        if P.Lines.First() then
            repeat
                Result += '[' + P.Lines.DocCtl.Value() + '/' + P.Lines.LineCtl.Value() + '|' + P.Lines.DescrCtl.Value() + ']';
            until not P.Lines.Next();
        exit(Result);
    end;

#if BC28PLUS
    [Test]
    procedure Y80_NH_Doc_NameThenNo()
    var
        P: TestPage "LT Y80 NH Doc";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownDoc(P));
        Observer.Observe('read log at open', OpenLog());
        Step('name', TryDoc(P, 'name'));
        Observer.Observe('shown after name', ShownDoc(P));
        Observer.Observe('read log after name', OpenLog());
        Step('no', TryDoc(P, 'no'));
        Observer.Observe('shown after no', ShownDoc(P));
        Observer.Observe('read log after no', OpenLog());
        Step('close', TryDoc(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'HV:A1');
        Observer.Expect('no db', '[||] lines ');
        Observer.Expect('shown after no', '|N1| part ');
        Observer.Expect('read log after no', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('close db', '[||] lines ');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure Y80_NH_Doc_NoThenName()
    var
        P: TestPage "LT Y80 NH Doc";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownDoc(P));
        Observer.Observe('read log at open', OpenLog());
        Step('no', TryDoc(P, 'no'));
        Observer.Observe('shown after no', ShownDoc(P));
        Observer.Observe('read log after no', OpenLog());
        Step('name', TryDoc(P, 'name'));
        Observer.Observe('shown after name', ShownDoc(P));
        Observer.Observe('read log after name', OpenLog());
        Step('close', TryDoc(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'HV:A1');
        Observer.Expect('no db', '[||] lines ');
        Observer.Expect('shown after no', '|| part ');
        Observer.Expect('read log after no', '');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', 'HM:|N1');
        Observer.Expect('close db', '[|N1|] lines ');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure Y80_NH_Doc_GroupThenNo()
    var
        P: TestPage "LT Y80 NH Doc";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownDoc(P));
        Observer.Observe('read log at open', OpenLog());
        Step('group', TryDoc(P, 'group'));
        Observer.Observe('shown after group', ShownDoc(P));
        Observer.Observe('read log after group', OpenLog());
        Step('no', TryDoc(P, 'no'));
        Observer.Observe('shown after no', ShownDoc(P));
        Observer.Observe('read log after no', OpenLog());
        Step('close', TryDoc(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('group ok', 'Yes');
        Observer.Expect('group|text', '');
        Observer.Expect('group|code', '');
        Observer.Expect('group log', 'LN:;LN:;LN:');
        Observer.Expect('group db', '[||] lines ');
        Observer.Expect('shown after group', '||G1 part ');
        Observer.Expect('read log after group', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'HV:A1');
        Observer.Expect('no db', '[||] lines ');
        Observer.Expect('shown after no', '||G1 part ');
        Observer.Expect('read log after no', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('close db', '[||] lines ');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure Y80_NH_Doc_NameLineThenNo()
    var
        P: TestPage "LT Y80 NH Doc";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownDoc(P));
        Observer.Observe('read log at open', OpenLog());
        Step('name', TryDoc(P, 'name'));
        Observer.Observe('shown after name', ShownDoc(P));
        Observer.Observe('read log after name', OpenLog());
        Step('line', TryDoc(P, 'line'));
        Observer.Observe('shown after line', ShownDoc(P));
        Observer.Observe('read log after line', OpenLog());
        Step('no', TryDoc(P, 'no'));
        Observer.Observe('shown after no', ShownDoc(P));
        Observer.Observe('read log after no', OpenLog());
        Step('close', TryDoc(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', 'HM:|N1;LN:;LN:;LN:');
        Observer.Expect('line db', '[|N1|] lines ');
        Observer.Expect('shown after line', '|N1| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'LI:/10000|d1;HV:A1');
        Observer.Expect('no db', '[|N1|] lines [/10000|d1]');
        Observer.Expect('shown after no', '|N1| part [/10000|d1][/0|]');
        Observer.Expect('read log after no', 'LN:');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('close db', '[|N1|] lines [/10000|d1]');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure Y80_NH_Doc_NameNoThenLine()
    var
        P: TestPage "LT Y80 NH Doc";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownDoc(P));
        Observer.Observe('read log at open', OpenLog());
        Step('name', TryDoc(P, 'name'));
        Observer.Observe('shown after name', ShownDoc(P));
        Observer.Observe('read log after name', OpenLog());
        Step('no', TryDoc(P, 'no'));
        Observer.Observe('shown after no', ShownDoc(P));
        Observer.Observe('read log after no', OpenLog());
        Step('line', TryDoc(P, 'line'));
        Observer.Observe('shown after line', ShownDoc(P));
        Observer.Observe('read log after line', OpenLog());
        Step('close', TryDoc(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'HV:A1');
        Observer.Expect('no db', '[||] lines ');
        Observer.Expect('shown after no', '|N1| part ');
        Observer.Expect('read log after no', '');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', '');
        Observer.Expect('line db', '[||] lines ');
        Observer.Expect('shown after line', '|N1| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', 'LI:/10000|d1');
        Observer.Expect('close db', '[||] lines [/10000|d1]');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure Y80_NH_Doc_NameThenLineOnly()
    var
        P: TestPage "LT Y80 NH Doc";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownDoc(P));
        Observer.Observe('read log at open', OpenLog());
        Step('name', TryDoc(P, 'name'));
        Observer.Observe('shown after name', ShownDoc(P));
        Observer.Observe('read log after name', OpenLog());
        Step('line', TryDoc(P, 'line'));
        Observer.Observe('shown after line', ShownDoc(P));
        Observer.Observe('read log after line', OpenLog());
        Step('close', TryDoc(P, 'close'));
        Observer.Finish();
    end;

#if BC28PLUS
    [Test]
    procedure Y80_NH_Doc_LineOnlyThenNo()
    var
        P: TestPage "LT Y80 NH Doc";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownDoc(P));
        Observer.Observe('read log at open', OpenLog());
        Step('line', TryDoc(P, 'line'));
        Observer.Observe('shown after line', ShownDoc(P));
        Observer.Observe('read log after line', OpenLog());
        Step('no', TryDoc(P, 'no'));
        Observer.Observe('shown after no', ShownDoc(P));
        Observer.Observe('read log after no', OpenLog());
        Step('close', TryDoc(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', '');
        Observer.Expect('line db', '[||] lines ');
        Observer.Expect('shown after line', '|| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'LI:/10000|d1;HV:A1');
        Observer.Expect('no db', '[||] lines [/10000|d1]');
        Observer.Expect('shown after no', '|| part [/10000|d1][/0|]');
        Observer.Expect('read log after no', 'LN:');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('close db', '[||] lines [/10000|d1]');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure Y80_NH_Doc_NameNoLineTwo()
    var
        P: TestPage "LT Y80 NH Doc";
    begin
        Seed();
        P.OpenNew();
        Observer.Observe('open log', OpenLog());
        Observer.Observe('shown at open', ShownDoc(P));
        Observer.Observe('read log at open', OpenLog());
        Step('name', TryDoc(P, 'name'));
        Observer.Observe('shown after name', ShownDoc(P));
        Observer.Observe('read log after name', OpenLog());
        Step('no', TryDoc(P, 'no'));
        Observer.Observe('shown after no', ShownDoc(P));
        Observer.Observe('read log after no', OpenLog());
        Step('line', TryDoc(P, 'line'));
        Observer.Observe('shown after line', ShownDoc(P));
        Observer.Observe('read log after line', OpenLog());
        Step('newline', TryDoc(P, 'newline'));
        Observer.Observe('shown after newline', ShownDoc(P));
        Observer.Observe('read log after newline', OpenLog());
        Step('line2', TryDoc(P, 'line2'));
        Observer.Observe('shown after line2', ShownDoc(P));
        Observer.Observe('read log after line2', OpenLog());
        Step('close', TryDoc(P, 'close'));
        Observer.Expect('open log', 'PN;LN:;LN:;LN:');
        Observer.Expect('shown at open', '|| part ');
        Observer.Expect('read log at open', 'HI:|;LN:;LN:;LN:');
        Observer.Expect('name ok', 'Yes');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name log', 'LN:;LN:;LN:');
        Observer.Expect('name db', '[||] lines ');
        Observer.Expect('shown after name', '|N1| part ');
        Observer.Expect('read log after name', '');
        Observer.Expect('no ok', 'Yes');
        Observer.Expect('no|text', '');
        Observer.Expect('no|code', '');
        Observer.Expect('no log', 'HV:A1');
        Observer.Expect('no db', '[||] lines ');
        Observer.Expect('shown after no', '|N1| part ');
        Observer.Expect('read log after no', '');
        Observer.Expect('line ok', 'Yes');
        Observer.Expect('line|text', '');
        Observer.Expect('line|code', '');
        Observer.Expect('line log', '');
        Observer.Expect('line db', '[||] lines ');
        Observer.Expect('shown after line', '|N1| part ');
        Observer.Expect('read log after line', '');
        Observer.Expect('newline ok', 'Yes');
        Observer.Expect('newline|text', '');
        Observer.Expect('newline|code', '');
        Observer.Expect('newline log', 'LI:/10000|d1;LN:');
        Observer.Expect('newline db', '[||] lines [/10000|d1]');
        Observer.Expect('shown after newline', '|N1| part [/10000|d1][/0|]');
        Observer.Expect('read log after newline', 'LN:');
        Observer.Expect('line2 ok', 'Yes');
        Observer.Expect('line2|text', '');
        Observer.Expect('line2|code', '');
        Observer.Expect('line2 log', '');
        Observer.Expect('line2 db', '[||] lines [/10000|d1]');
        Observer.Expect('shown after line2', '|N1| part [/10000|d1][/20000|d2][/0|]');
        Observer.Expect('read log after line2', 'LI:/20000|d2;LN:');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('close db', '[||] lines [/10000|d1][/20000|d2]');
        Observer.Verify();
    end;
#endif
}
