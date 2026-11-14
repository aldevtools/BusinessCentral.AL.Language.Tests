// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 62720-62722, log codeunit 62723, part pages 62724-62726, host pages
//   62727-62732 and 62734, test codeunit 62733
// Probe: observe-only. Area: when a new row of an AutoSplitKey ListPart is inserted (al-runner issue 7402), measured step by step with a
//   log of every part and table trigger after each TestPage call:
//   1. a non-delayed new row with one, two and three controls, values typed in different orders, Activate() of a second control, a move
//      to another row, Close;
//   2. a Document host ListPart with OnNewRecord and OnInsertRecord on the part, on the host, and on neither, opened by OpenEdit,
//      OpenView and OpenNew and by Page.RunModal with a handler;
//   3. a part table with field OnValidate triggers that set another field, and a table OnInsert trigger that changes a field.
// Lines of H1 (Line No. / Seq No.): 10000/20, 20000/40, 30000/10, 40000/30. In Seq No. order: 30000, 10000, 40000, 20000. H2 has no lines.
// Observed: after each step the log (NEW and INS are the part triggers with Rec and xRec line numbers, T-I the table OnInsert, T-V a table
//   OnValidate, H-N and H-I the host triggers), the Line No. the new row shows, errors, and the stored lines.
// local object: the part properties AutoSplitKey and the SubPageView, the host page type and how the host is opened are what the test checks
// BC versions: 27, 28, 29

table 62720 "PG ST Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 62721 "PG ST Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; "Seq No."; Integer) { DataClassification = SystemMetadata; }
        field(4; Descr; Text[30]) { DataClassification = SystemMetadata; }
        field(5; Qty; Decimal) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
        key(Seq; "Head Code", "Seq No.") { }
    }

    trigger OnInsert()
    var
        Log: Codeunit "PG ST Log";
    begin
        Log.Add('T-I ' + Format("Line No."));
    end;
}

table 62722 "PG ST Line W"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; "Seq No."; Integer)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "PG ST Log";
            begin
                Log.Add('T-V Seq ' + Format("Line No."));
                Qty := Qty + 1;
            end;
        }
        field(4; Descr; Text[30])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "PG ST Log";
            begin
                Log.Add('T-V Descr ' + Format("Line No."));
                Qty := 7;
            end;
        }
        field(5; Qty; Decimal) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
        key(Seq; "Head Code", "Seq No.") { }
    }

    trigger OnInsert()
    var
        Log: Codeunit "PG ST Log";
    begin
        Log.Add('T-I ' + Format("Line No."));
        Descr := Descr + '+ins';
    end;
}

codeunit 62723 "PG ST Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' | ';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := '[' + Entries + ']';
        Entries := '';
    end;
}

page 62724 "PG ST Lines"
{
    PageType = ListPart;
    SourceTable = "PG ST Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Seq No."; Rec."Seq No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG ST Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG ST Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
        exit(true);
    end;
}

page 62725 "PG ST Lines Plain"
{
    PageType = ListPart;
    SourceTable = "PG ST Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Seq No."; Rec."Seq No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

page 62726 "PG ST Lines W"
{
    PageType = ListPart;
    SourceTable = "PG ST Line W";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Seq No."; Rec."Seq No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG ST Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG ST Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
        exit(true);
    end;
}

page 62727 "PG ST Card"
{
    PageType = Card;
    SourceTable = "PG ST Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG ST Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.");
                UpdatePropagation = Both;
            }
        }
    }
}

page 62728 "PG ST Card PK"
{
    PageType = Card;
    SourceTable = "PG ST Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG ST Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                UpdatePropagation = Both;
            }
        }
    }
}

page 62729 "PG ST Doc"
{
    PageType = Document;
    SourceTable = "PG ST Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG ST Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.");
                UpdatePropagation = Both;
            }
        }
    }
}

page 62730 "PG ST Doc HostTrig"
{
    PageType = Document;
    SourceTable = "PG ST Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG ST Lines Plain")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG ST Log";
    begin
        Log.Add('H-N');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG ST Log";
    begin
        Log.Add('H-I');
        exit(true);
    end;
}

page 62731 "PG ST Doc Plain"
{
    PageType = Document;
    SourceTable = "PG ST Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG ST Lines Plain")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.");
                UpdatePropagation = Both;
            }
        }
    }
}

page 62732 "PG ST Card W"
{
    PageType = Card;
    SourceTable = "PG ST Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG ST Lines W")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.");
                UpdatePropagation = Both;
            }
        }
    }
}

page 62734 "PG ST Doc W"
{
    PageType = Document;
    SourceTable = "PG ST Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG ST Lines W")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.");
                UpdatePropagation = Both;
            }
        }
    }
}

codeunit 62733 "PG ST Insert Timing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PG ST Log";
        TypeThree: Boolean;

    local procedure Seed()
    var
        Head: Record "PG ST Head";
        Line: Record "PG ST Line";
        LineW: Record "PG ST Line W";
    begin
        Line.DeleteAll();
        LineW.DeleteAll();
        Head.DeleteAll();
        Head.Code := 'H1';
        Head.Insert();
        Head.Code := 'H2';
        Head.Insert();
        AddLine(10000, 20);
        AddLine(20000, 40);
        AddLine(30000, 10);
        AddLine(40000, 30);
        TypeThree := false;
        Log.Take();
    end;

    local procedure AddLine(LineNo: Integer; SeqNo: Integer)
    var
        Line: Record "PG ST Line";
        LineW: Record "PG ST Line W";
    begin
        Line.Init();
        Line."Head Code" := 'H1';
        Line."Line No." := LineNo;
        Line."Seq No." := SeqNo;
        Line.Descr := 'old';
        Line.Insert();
        LineW.TransferFields(Line);
        LineW.Insert();
    end;

    local procedure Lines(HeadCode: Code[10]) Result: Text
    var
        Line: Record "PG ST Line";
    begin
        Line.SetRange("Head Code", HeadCode);
        if Line.FindSet() then
            repeat
                Result += Format(Line."Line No.") + '/' + Format(Line."Seq No.") + '=' + Line.Descr + ':' + Format(Line.Qty) + ' ';
            until Line.Next() = 0;
        Result := '[' + Result + ']';
    end;

    local procedure LinesW(HeadCode: Code[10]) Result: Text
    var
        Line: Record "PG ST Line W";
    begin
        Line.SetRange("Head Code", HeadCode);
        if Line.FindSet() then
            repeat
                Result += Format(Line."Line No.") + '/' + Format(Line."Seq No.") + '=' + Line.Descr + ':' + Format(Line.Qty) + ' ';
            until Line.Next() = 0;
        Result := '[' + Result + ']';
    end;

    [Test]
    procedure Timing_Card_Descr_Only()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('shown', '0 0 a 0.00');
        Observer.Expect('close', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/0=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_Seq_Only()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('2 Seq No  SetValue 25', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Seq No  SetValue 25', '[]');
        Observer.Expect('shown', '0 25  0.00');
        Observer.Expect('close', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_Two_DescrSeq()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Seq No  SetValue 25', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('shown', '35000 25 a 0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_Two_SeqDescr()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('2 Seq No  SetValue 25', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('3 Descr SetValue a', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Seq No  SetValue 25', '[]');
        Observer.Expect('3 Descr SetValue a', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('shown', '35000 25 a 0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_Two_QtyDescr()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Qty.SetValue(3);
        Observer.Observe('2 Qty SetValue 3', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('3 Descr SetValue a', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Qty SetValue 3', '[]');
        Observer.Expect('3 Descr SetValue a', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('shown', '35000 0 a 3.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/0=a:3 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_Three()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Card.Lines.Qty.SetValue(3);
        Observer.Observe('4 Qty SetValue 3', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Seq No  SetValue 25', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('4 Qty SetValue 3', '[]');
        Observer.Expect('shown', '35000 25 a 3.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a:3 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_Activate_Second()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Card.Lines.Qty.Activate();
        Observer.Observe('3 Qty Activate', Log.Take());
        Card.Lines."Seq No.".Activate();
        Observer.Observe('4 Seq No  Activate', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Qty Activate', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('4 Seq No  Activate', '[]');
        Observer.Expect('shown', '35000 0 a 0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/0=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_Activate_Only()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.Activate();
        Observer.Observe('2 Descr Activate', Log.Take());
        Card.Lines.Qty.Activate();
        Observer.Observe('3 Qty Activate', Log.Take());
        Card.Lines."Seq No.".Activate();
        Observer.Observe('4 Seq No  Activate', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr Activate', '[]');
        Observer.Expect('3 Qty Activate', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('4 Seq No  Activate', '[]');
        Observer.Expect('shown', '35000 0  0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/0=:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_OneValue_ThenFirst()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Card.Lines.First();
        Observer.Observe('3 First', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 First', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('shown', '30000 10 old 0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/0=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_OneValue_ThenPrevious()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Card.Lines.Previous();
        Observer.Observe('3 Previous', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Previous', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('shown', '20000 40 old 0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/0=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_TwoValues_ThenFirst()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Card.Lines.First();
        Observer.Observe('4 First', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Seq No  SetValue 25', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('4 First', '[]');
        Observer.Expect('shown', '30000 10 old 0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_NewOnly_ThenFirst()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.First();
        Observer.Observe('2 First', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 First', '[]');
        Observer.Expect('shown', '30000 10 old 0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Card_NewTwice()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Card.Lines.New();
        Observer.Observe('3 New', Log.Take());
        Card.Lines.Descr.SetValue('b');
        Observer.Observe('4 Descr SetValue b', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 New', '[INS 35000 x=20000 below=Yes | T-I 35000 | NEW 0 x=20000 below=Yes]');
        Observer.Expect('4 Descr SetValue b', '[]');
        Observer.Expect('shown', '0 0 b 0.00');
        Observer.Expect('close', '[INS 45000 x=35000 below=Yes | T-I 45000]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/0=a:0 40000/30=old:0 45000/0=b:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_CardPK_Descr_Only()
    var
        Card: TestPage "PG ST Card PK";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=40000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('shown', '0 0 a 0.00');
        Observer.Expect('close', '[INS 50000 x=40000 below=Yes | T-I 50000]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 40000/30=old:0 50000/0=a:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_CardPK_Two()
    var
        Card: TestPage "PG ST Card PK";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Card.Lines.Qty.SetValue(3);
        Observer.Observe('3 Qty SetValue 3', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=40000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Qty SetValue 3', '[INS 50000 x=40000 below=Yes | T-I 50000]');
        Observer.Expect('shown', '50000 0 a 3.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 40000/30=old:0 50000/0=a:3 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_CardPK_Three()
    var
        Card: TestPage "PG ST Card PK";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Card.Lines.Qty.SetValue(3);
        Observer.Observe('4 Qty SetValue 3', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=40000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Seq No  SetValue 25', '[INS 50000 x=40000 below=Yes | T-I 50000]');
        Observer.Expect('4 Qty SetValue 3', '[]');
        Observer.Expect('shown', '50000 25 a 3.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 40000/30=old:0 50000/25=a:3 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Doc_Descr_Only()
    var
        Doc: TestPage "PG ST Doc";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Log.Take();
        Doc.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Doc.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Observer.Observe('shown', Doc.Lines."Line No.".Value + ' ' + Doc.Lines."Seq No.".Value + ' ' + Doc.Lines.Descr.Value + ' ' + Doc.Lines.Qty.Value);
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('shown', '0 0 a 0.00');
        Observer.Expect('close', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/0=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Doc_Two()
    var
        Doc: TestPage "PG ST Doc";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Log.Take();
        Doc.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Doc.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Doc.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Observer.Observe('shown', Doc.Lines."Line No.".Value + ' ' + Doc.Lines."Seq No.".Value + ' ' + Doc.Lines.Descr.Value + ' ' + Doc.Lines.Qty.Value);
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Seq No  SetValue 25', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('shown', '35000 25 a 0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Timing_Doc_Three()
    var
        Doc: TestPage "PG ST Doc";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Log.Take();
        Doc.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Doc.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Doc.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Doc.Lines.Qty.SetValue(3);
        Observer.Observe('4 Qty SetValue 3', Log.Take());
        Observer.Observe('shown', Doc.Lines."Line No.".Value + ' ' + Doc.Lines."Seq No.".Value + ' ' + Doc.Lines.Descr.Value + ' ' + Doc.Lines.Qty.Value);
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Seq No  SetValue 25', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('4 Qty SetValue 3', '[]');
        Observer.Expect('shown', '35000 25 a 3.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a:3 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_PartTriggers_OpenEdit()
    var
        Doc: TestPage "PG ST Doc";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Log.Take();
        Doc.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Doc.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Doc.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Observer.Observe('shown', Doc.Lines."Line No.".Value + ' ' + Doc.Lines."Seq No.".Value + ' ' + Doc.Lines.Descr.Value + ' ' + Doc.Lines.Qty.Value);
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Seq No  SetValue 25', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('shown', '35000 25 a 0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_HostTriggers_PlainPart()
    var
        Doc: TestPage "PG ST Doc HostTrig";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Log.Take();
        Doc.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Doc.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Doc.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Observer.Observe('shown', Doc.Lines."Line No.".Value + ' ' + Doc.Lines."Seq No.".Value + ' ' + Doc.Lines.Descr.Value + ' ' + Doc.Lines.Qty.Value);
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Seq No  SetValue 25', '[T-I 35000]');
        Observer.Expect('shown', '35000 25 a 0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_NoTriggers()
    var
        Doc: TestPage "PG ST Doc Plain";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Log.Take();
        Doc.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Doc.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Doc.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Observer.Observe('shown', Doc.Lines."Line No.".Value + ' ' + Doc.Lines."Seq No.".Value + ' ' + Doc.Lines.Descr.Value + ' ' + Doc.Lines.Qty.Value);
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Seq No  SetValue 25', '[T-I 35000]');
        Observer.Expect('shown', '35000 25 a 0.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_NoTriggers_Three()
    var
        Doc: TestPage "PG ST Doc Plain";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Log.Take();
        Doc.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Doc.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Doc.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Doc.Lines.Qty.SetValue(3);
        Observer.Observe('4 Qty SetValue 3', Log.Take());
        Observer.Observe('shown', Doc.Lines."Line No.".Value + ' ' + Doc.Lines."Seq No.".Value + ' ' + Doc.Lines.Descr.Value + ' ' + Doc.Lines.Qty.Value);
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('1 New', '[]');
        Observer.Expect('2 Descr SetValue a', '[]');
        Observer.Expect('3 Seq No  SetValue 25', '[T-I 35000]');
        Observer.Expect('4 Qty SetValue 3', '[]');
        Observer.Expect('shown', '35000 25 a 3.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a:3 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure TableTrig_Card_DescrSeq()
    var
        Card: TestPage "PG ST Card W";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', LinesW('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[T-V Descr 0]');
        Observer.Expect('3 Seq No  SetValue 25', '[INS 35000 x=20000 below=Yes | T-I 35000 | T-V Seq 35000]');
        Observer.Expect('shown', '35000 25 a+ins 8.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a+ins:8 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure TableTrig_Card_SeqDescr()
    var
        Card: TestPage "PG ST Card W";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('2 Seq No  SetValue 25', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('3 Descr SetValue a', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', LinesW('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Seq No  SetValue 25', '[T-V Seq 0]');
        Observer.Expect('3 Descr SetValue a', '[INS 35000 x=20000 below=Yes | T-I 35000 | T-V Descr 35000]');
        Observer.Expect('shown', '35000 25 a 7.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a:7 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure TableTrig_Card_Descr_Only()
    var
        Card: TestPage "PG ST Card W";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', LinesW('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[T-V Descr 0]');
        Observer.Expect('shown', '0 0 a 7.00');
        Observer.Expect('close', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/0=a+ins:7 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure TableTrig_Card_Three()
    var
        Card: TestPage "PG ST Card W";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Card.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Card.Lines.Qty.SetValue(3);
        Observer.Observe('4 Qty SetValue 3', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ' ' + Card.Lines."Seq No.".Value + ' ' + Card.Lines.Descr.Value + ' ' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', LinesW('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[T-V Descr 0]');
        Observer.Expect('3 Seq No  SetValue 25', '[INS 35000 x=20000 below=Yes | T-I 35000 | T-V Seq 35000]');
        Observer.Expect('4 Qty SetValue 3', '[]');
        Observer.Expect('shown', '35000 25 a+ins 3.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a+ins:3 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure TableTrig_Doc_DescrSeq()
    var
        Doc: TestPage "PG ST Doc W";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Log.Take();
        Doc.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Doc.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Doc.Lines."Seq No.".SetValue(25);
        Observer.Observe('3 Seq No  SetValue 25', Log.Take());
        Observer.Observe('shown', Doc.Lines."Line No.".Value + ' ' + Doc.Lines."Seq No.".Value + ' ' + Doc.Lines.Descr.Value + ' ' + Doc.Lines.Qty.Value);
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', LinesW('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[T-V Descr 0]');
        Observer.Expect('3 Seq No  SetValue 25', '[INS 35000 x=20000 below=Yes | T-I 35000 | T-V Seq 35000]');
        Observer.Expect('shown', '35000 25 a+ins 8.00');
        Observer.Expect('close', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/25=a+ins:8 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    procedure TableTrig_Doc_Descr_Only()
    var
        Doc: TestPage "PG ST Doc W";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Log.Take();
        Doc.Lines.New();
        Observer.Observe('1 New', Log.Take());
        Doc.Lines.Descr.SetValue('a');
        Observer.Observe('2 Descr SetValue a', Log.Take());
        Observer.Observe('shown', Doc.Lines."Line No.".Value + ' ' + Doc.Lines."Seq No.".Value + ' ' + Doc.Lines.Descr.Value + ' ' + Doc.Lines.Qty.Value);
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('lines', LinesW('H1'));
        Observer.Expect('1 New', '[NEW 0 x=20000 below=Yes]');
        Observer.Expect('2 Descr SetValue a', '[T-V Descr 0]');
        Observer.Expect('shown', '0 0 a 7.00');
        Observer.Expect('close', '[INS 35000 x=20000 below=Yes | T-I 35000]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 35000/0=a+ins:7 40000/30=old:0 ]');
        Observer.Verify();
    end;

    // Cell 2: the Document host opened in view mode (the part is not editable, or New raises).
    [Test]
    procedure Doc_OpenView_New()
    var
        Doc: TestPage "PG ST Doc";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenView();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Log.Take();
        Observer.Observe('editable', Format(Doc.Lines.Descr.Editable()));
        asserterror
        begin
            Doc.Lines.New();
            Log.Add('after New');
            Doc.Lines.Descr.SetValue('a');
            Log.Add('after Descr');
            Error('');
        end;
        Observer.ObserveError('view');
        Observer.Observe('log', Log.Take());
        Doc.Close();
        Observer.Expect('editable', 'No');
        Observer.Expect('view|text', 'New method failed because Insert is not allowed. Page = PG ST Lines, Id = 62724.');
        Observer.Expect('view|code', 'DB:ClientInsertDenied');
        Observer.Expect('log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenView_New()
    var
        Card: TestPage "PG ST Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenView();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Observer.Observe('editable', Format(Card.Lines.Descr.Editable()));
        asserterror
        begin
            Card.Lines.New();
            Log.Add('after New');
            Card.Lines.Descr.SetValue('a');
            Log.Add('after Descr');
            Error('');
        end;
        Observer.ObserveError('view');
        Observer.Observe('log', Log.Take());
        Card.Close();
        Observer.Expect('editable', 'No');
        Observer.Expect('view|text', 'New method failed because Insert is not allowed. Page = PG ST Lines, Id = 62724.');
        Observer.Expect('view|code', 'DB:ClientInsertDenied');
        Observer.Expect('log', '[]');
        Observer.Verify();
    end;

    // Cell 2: a new host record (OpenNew) with the part. The page is closed inside the asserterror block so that nothing is left pending
    // after the rollback.
    [Test]
    procedure Doc_OpenNew_CodeOnly()
    var
        Doc: TestPage "PG ST Doc";
        Head: Record "PG ST Head";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenNew();
        Doc.Code.SetValue('H3');
        Doc.Close();
        Observer.Observe('log', Log.Take());
        Observer.Observe('head', Format(Head.Get('H3')));
        Observer.Expect('log', '[NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes]');
        Observer.Expect('head', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_OpenNew_NewRow()
    var
        Doc: TestPage "PG ST Doc";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenNew();
        Doc.Code.SetValue('H3');
        Log.Take();
        asserterror
        begin
            Doc.Lines.New();
            Log.Add('after New');
            Doc.Lines.Descr.SetValue('a');
            Log.Add('after Descr');
            Doc.Lines."Seq No.".SetValue(25);
            Log.Add('after Seq ' + Lines('H3'));
            Doc.Close();
            Log.Add('after Close ' + Lines('H3'));
            Error('');
        end;
        Observer.ObserveError('opennew');
        Observer.Observe('log', Log.Take());
        Observer.Expect('opennew|text', '');
        Observer.Expect('opennew|code', 'Dialog');
        Observer.Expect('log', '[NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes | after New | after Descr | INS 20000 x=0 below=Yes | T-I 20000 | after Seq [20000/0=a:0 ] | after Close [20000/25=a:0 ]]');
        Observer.Verify();
    end;

    [Test]
    procedure Doc_HostTrig_OpenNew_NewRow()
    var
        Doc: TestPage "PG ST Doc HostTrig";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenNew();
        Observer.Observe('log open', Log.Take());
        Doc.Code.SetValue('H3');
        Observer.Observe('log code', Log.Take());
        asserterror
        begin
            Doc.Lines.New();
            Log.Add('after New');
            Doc.Lines.Descr.SetValue('a');
            Log.Add('after Descr');
            Doc.Lines."Seq No.".SetValue(25);
            Log.Add('after Seq ' + Lines('H3'));
            Doc.Close();
            Log.Add('after Close ' + Lines('H3'));
            Error('');
        end;
        Observer.ObserveError('opennew');
        Observer.Observe('log', Log.Take());
        Observer.Expect('log open', '[H-N]');
        Observer.Expect('log code', '[]');
        Observer.Expect('opennew|text', '');
        Observer.Expect('opennew|code', 'Dialog');
        Observer.Expect('log', '[H-I | after New | after Descr | T-I 20000 | after Seq [20000/0=a:0 ] | after Close [20000/25=a:0 ]]');
        Observer.Verify();
    end;

    // Cell 2: the Document host run by Page.RunModal with a handler, on rows and on the empty part.
    [Test]
    [HandlerFunctions('DocHandler')]
    procedure Doc_RunModal_RowsErr()
    var
        Head: Record "PG ST Head";
    begin
        Observer.Discard();
        Seed();
        Head.Get('H1');
        asserterror
        begin
            Page.RunModal(Page::"PG ST Doc", Head);
            Error('');
        end;
        Observer.ObserveError('RunModal');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Expect('RunModal|text', 'The line cannot be split.');
        Observer.Expect('RunModal|code', 'TestWrapped');
        Observer.Expect('log', '[]');
        Observer.Expect('lines', '[10000/20=old:0 20000/40=old:0 30000/10=old:0 40000/30=old:0 ]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DocHandler')]
    procedure Doc_RunModal_EmptyPart()
    var
        Head: Record "PG ST Head";
    begin
        Observer.Discard();
        Seed();
        Head.Get('H2');
        Page.RunModal(Page::"PG ST Doc", Head);
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Expect('handler New', '[NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes]');
        Observer.Expect('handler Descr', '[]');
        Observer.Expect('handler Seq', '[INS 20000 x=0 below=Yes | T-I 20000]');
        Observer.Expect('handler shown', '20000');
        Observer.Expect('log', '[]');
        Observer.Expect('lines', '[20000/25=modal:0 ]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DocHandler')]
    procedure Doc_RunModal_EmptyPart_ThreeValues()
    var
        Head: Record "PG ST Head";
    begin
        Observer.Discard();
        Seed();
        TypeThree := true;
        Head.Get('H2');
        Page.RunModal(Page::"PG ST Doc", Head);
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Expect('handler New', '[NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes | NEW 0 x=0 below=Yes]');
        Observer.Expect('handler Descr', '[]');
        Observer.Expect('handler Seq', '[INS 20000 x=0 below=Yes | T-I 20000]');
        Observer.Expect('handler Qty', '[]');
        Observer.Expect('handler shown', '20000');
        Observer.Expect('log', '[]');
        Observer.Expect('lines', '[20000/25=modal:3 ]');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure DocHandler(var Doc: TestPage "PG ST Doc")
    begin
        Doc.Lines.New();
        Observer.Observe('handler New', Log.Take());
        Doc.Lines.Descr.SetValue('modal');
        Observer.Observe('handler Descr', Log.Take());
        Doc.Lines."Seq No.".SetValue(25);
        Observer.Observe('handler Seq', Log.Take());
        if TypeThree then begin
            Doc.Lines.Qty.SetValue(3);
            Observer.Observe('handler Qty', Log.Take());
        end;
        Observer.Observe('handler shown', Doc.Lines."Line No.".Value);
        Doc.OK().Invoke();
    end;
}
