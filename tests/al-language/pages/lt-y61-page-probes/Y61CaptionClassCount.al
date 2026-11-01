// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 93244-93249, log codeunit 93245 (used only by test codeunit 93244), pages 93247-93255,
//   test codeunit 93244
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: how many times a page open, a GoToRecord and a Close run the CaptionClass expressions of a table's fields with an empty record
//   (Id 0) and with a row, for more fields than the pinned one and two: four fields with four different expressions (per field), four and
//   three fields with the same expression text, fifteen fields whose expression reads a Dictionary (per field), on a List page; one
//   field on a Worksheet and a ListPlus page; the four different fields on a Worksheet; and an expression that calls Message (how many
//   messages a MessageHandler sees per step, Card and List). Three cycles of OpenEdit, GoToRecord (row 2 of 3) and Close per test.
//   Log per step: empty=<runs with Id 0> rows=<runs with a row>, and per field f<n>:<empty>/<rows> where the expression tells the field.
// Neighbours: record/lt-sx-captionclass-count/SxCaptionClassCount.al (one and two fields, Card and List),
//   record/lt-qd-captionclass-areas/QdCaptionClassAreas.al (which expressions run; its comments record counts that vary between runs).
// BC versions: all (CI)

table 93244 "LT Y61 CC K4"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; F1; Decimal) { Caption = 'F1'; CaptionClass = Cc(1); }
        field(3; F2; Decimal) { Caption = 'F2'; CaptionClass = Cc(2); }
        field(4; F3; Decimal) { Caption = 'F3'; CaptionClass = Cc(3); }
        field(5; F4; Decimal) { Caption = 'F4'; CaptionClass = Cc(4); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure Cc(n: Integer): Text[80]
    var
        Log: Codeunit "LT Y61 CC Log";
    begin
        Log.Hit(n, Id);
        exit('3,Cap' + Format(n));
    end;
}

table 93245 "LT Y61 CC K4S"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; F1; Decimal) { Caption = 'F1'; CaptionClass = Cc(); }
        field(3; F2; Decimal) { Caption = 'F2'; CaptionClass = Cc(); }
        field(4; F3; Decimal) { Caption = 'F3'; CaptionClass = Cc(); }
        field(5; F4; Decimal) { Caption = 'F4'; CaptionClass = Cc(); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure Cc(): Text[80]
    var
        Log: Codeunit "LT Y61 CC Log";
    begin
        Log.Hit(0, Id);
        exit('3,Same');
    end;
}

table 93246 "LT Y61 CC K3S"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; F1; Decimal) { Caption = 'F1'; CaptionClass = Cc(); }
        field(3; F2; Decimal) { Caption = 'F2'; CaptionClass = Cc(); }
        field(4; F3; Decimal) { Caption = 'F3'; CaptionClass = Cc(); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure Cc(): Text[80]
    var
        Log: Codeunit "LT Y61 CC Log";
    begin
        Log.Hit(0, Id);
        exit('3,Same');
    end;
}

table 93247 "LT Y61 CC K15"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; T2; Text[30]) { Caption = 'T2'; CaptionClass = GetCaption(Rec.FieldNo(T2)); }
        field(3; T3; Text[30]) { Caption = 'T3'; CaptionClass = GetCaption(Rec.FieldNo(T3)); }
        field(4; T4; Text[30]) { Caption = 'T4'; CaptionClass = GetCaption(Rec.FieldNo(T4)); }
        field(5; T5; Text[30]) { Caption = 'T5'; CaptionClass = GetCaption(Rec.FieldNo(T5)); }
        field(6; T6; Text[30]) { Caption = 'T6'; CaptionClass = GetCaption(Rec.FieldNo(T6)); }
        field(7; T7; Text[30]) { Caption = 'T7'; CaptionClass = GetCaption(Rec.FieldNo(T7)); }
        field(8; T8; Text[30]) { Caption = 'T8'; CaptionClass = GetCaption(Rec.FieldNo(T8)); }
        field(9; T9; Text[30]) { Caption = 'T9'; CaptionClass = GetCaption(Rec.FieldNo(T9)); }
        field(10; T10; Text[30]) { Caption = 'T10'; CaptionClass = GetCaption(Rec.FieldNo(T10)); }
        field(11; T11; Text[30]) { Caption = 'T11'; CaptionClass = GetCaption(Rec.FieldNo(T11)); }
        field(12; T12; Text[30]) { Caption = 'T12'; CaptionClass = GetCaption(Rec.FieldNo(T12)); }
        field(13; T13; Text[30]) { Caption = 'T13'; CaptionClass = GetCaption(Rec.FieldNo(T13)); }
        field(14; T14; Text[30]) { Caption = 'T14'; CaptionClass = GetCaption(Rec.FieldNo(T14)); }
        field(15; T15; Text[30]) { Caption = 'T15'; CaptionClass = GetCaption(Rec.FieldNo(T15)); }
        field(16; T16; Text[30]) { Caption = 'T16'; CaptionClass = GetCaption(Rec.FieldNo(T16)); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    var
        Captions: Dictionary of [Integer, Text];

    procedure GetCaption(n: Integer): Text[80]
    var
        Log: Codeunit "LT Y61 CC Log";
    begin
        Log.Hit(n, Id);
        exit(CopyStr(ReadCaption(n), 1, 80));
    end;

    local procedure ReadCaption(n: Integer): Text
    var
        Txt: Text;
    begin
        if not Captions.ContainsKey(n) then
            Captions.Add(n, '3,T' + Format(n));
        Txt := Captions.Get(n);
        exit(Txt);
    end;
}

table 93248 "LT Y61 CC KM"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; F1; Decimal) { Caption = 'F1'; CaptionClass = CcMsg(); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure CcMsg(): Text[80]
    var
        Log: Codeunit "LT Y61 CC Log";
    begin
        Log.Hit(1, Id);
        Message('cc %1', Id);
        exit('3,Msg');
    end;
}

table 93249 "LT Y61 CC K1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; F1; Decimal) { Caption = 'F1'; CaptionClass = Cc(1); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure Cc(n: Integer): Text[80]
    var
        Log: Codeunit "LT Y61 CC Log";
    begin
        Log.Hit(n, Id);
        exit('3,Cap' + Format(n));
    end;
}

page 93247 "LT Y61 CC K4 List"
{
    PageType = List;
    SourceTable = "LT Y61 CC K4";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(F1Ctl; Rec.F1) { ApplicationArea = All; }
                field(F2Ctl; Rec.F2) { ApplicationArea = All; }
                field(F3Ctl; Rec.F3) { ApplicationArea = All; }
                field(F4Ctl; Rec.F4) { ApplicationArea = All; }
            }
        }
    }
}

page 93248 "LT Y61 CC K4S List"
{
    PageType = List;
    SourceTable = "LT Y61 CC K4S";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(F1Ctl; Rec.F1) { ApplicationArea = All; }
                field(F2Ctl; Rec.F2) { ApplicationArea = All; }
                field(F3Ctl; Rec.F3) { ApplicationArea = All; }
                field(F4Ctl; Rec.F4) { ApplicationArea = All; }
            }
        }
    }
}

page 93249 "LT Y61 CC K3S List"
{
    PageType = List;
    SourceTable = "LT Y61 CC K3S";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(F1Ctl; Rec.F1) { ApplicationArea = All; }
                field(F2Ctl; Rec.F2) { ApplicationArea = All; }
                field(F3Ctl; Rec.F3) { ApplicationArea = All; }
            }
        }
    }
}

page 93250 "LT Y61 CC K15 List"
{
    PageType = List;
    SourceTable = "LT Y61 CC K15";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(T2Ctl; Rec.T2) { ApplicationArea = All; }
                field(T3Ctl; Rec.T3) { ApplicationArea = All; }
                field(T4Ctl; Rec.T4) { ApplicationArea = All; }
                field(T5Ctl; Rec.T5) { ApplicationArea = All; }
                field(T6Ctl; Rec.T6) { ApplicationArea = All; }
                field(T7Ctl; Rec.T7) { ApplicationArea = All; }
                field(T8Ctl; Rec.T8) { ApplicationArea = All; }
                field(T9Ctl; Rec.T9) { ApplicationArea = All; }
                field(T10Ctl; Rec.T10) { ApplicationArea = All; }
                field(T11Ctl; Rec.T11) { ApplicationArea = All; }
                field(T12Ctl; Rec.T12) { ApplicationArea = All; }
                field(T13Ctl; Rec.T13) { ApplicationArea = All; }
                field(T14Ctl; Rec.T14) { ApplicationArea = All; }
                field(T15Ctl; Rec.T15) { ApplicationArea = All; }
                field(T16Ctl; Rec.T16) { ApplicationArea = All; }
            }
        }
    }
}

page 93251 "LT Y61 CC KM Card"
{
    PageType = Card;
    SourceTable = "LT Y61 CC KM";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(F1Ctl; Rec.F1) { ApplicationArea = All; }
            }
        }
    }
}

page 93252 "LT Y61 CC KM List"
{
    PageType = List;
    SourceTable = "LT Y61 CC KM";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(F1Ctl; Rec.F1) { ApplicationArea = All; }
            }
        }
    }
}

page 93253 "LT Y61 CC K1 Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y61 CC K1";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(F1Ctl; Rec.F1) { ApplicationArea = All; }
            }
        }
    }
}

page 93254 "LT Y61 CC K1 ListPlus"
{
    PageType = ListPlus;
    SourceTable = "LT Y61 CC K1";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(F1Ctl; Rec.F1) { ApplicationArea = All; }
            }
        }
    }
}

page 93255 "LT Y61 CC K4 Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y61 CC K4";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(F1Ctl; Rec.F1) { ApplicationArea = All; }
                field(F2Ctl; Rec.F2) { ApplicationArea = All; }
                field(F3Ctl; Rec.F3) { ApplicationArea = All; }
                field(F4Ctl; Rec.F4) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 93245 "LT Y61 CC Log"
{
    SingleInstance = true;

    var
        EmptyRuns: Dictionary of [Integer, Integer];
        RowRuns: Dictionary of [Integer, Integer];
        Messages: Integer;

    procedure Hit(n: Integer; RowId: Integer)
    begin
        if RowId = 0 then
            Bump(EmptyRuns, n)
        else
            Bump(RowRuns, n);
    end;

    local procedure Bump(var D: Dictionary of [Integer, Integer]; n: Integer)
    begin
        if D.ContainsKey(n) then
            D.Set(n, D.Get(n) + 1)
        else
            D.Add(n, 1);
    end;

    procedure AddMessage()
    begin
        Messages += 1;
    end;

    // Totals, then (PerField) f<n>:<empty>/<rows> for n = 1 .. MaxField; clears the counts.
    procedure Take(PerField: Boolean; MaxField: Integer): Text
    var
        Result: Text;
        n: Integer;
        E: Integer;
        R: Integer;
        TotalE: Integer;
        TotalR: Integer;
    begin
        foreach n in EmptyRuns.Keys() do
            TotalE += EmptyRuns.Get(n);
        foreach n in RowRuns.Keys() do
            TotalR += RowRuns.Get(n);
        Result := 'empty=' + Format(TotalE) + ' rows=' + Format(TotalR);
        if PerField then
            for n := 1 to MaxField do begin
                E := 0;
                R := 0;
                if EmptyRuns.ContainsKey(n) then
                    E := EmptyRuns.Get(n);
                if RowRuns.ContainsKey(n) then
                    R := RowRuns.Get(n);
                if (E <> 0) or (R <> 0) then
                    Result += ' f' + Format(n) + ':' + Format(E) + '/' + Format(R);
            end;
        if Messages <> 0 then
            Result += ' msgs=' + Format(Messages);
        Clear(EmptyRuns);
        Clear(RowRuns);
        Messages := 0;
        exit(Result);
    end;
}

codeunit 93244 "LT Y61 CaptionClass Count"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y61 CC Log";
        Observer: Codeunit "Probe Observer";

    [MessageHandler]
    procedure CountMessages(Msg: Text[1024])
    begin
        Log.AddMessage();
    end;

    [Test]
    procedure G615_List_4DifferentFields()
    var
        P: TestPage "LT Y61 CC K4 List";
        Row: Record "LT Y61 CC K4";
        Got: Text;
        Round: Integer;
    begin
        SeedK4();
        for Round := 1 to 3 do begin
            Log.Take(false, 0);
            P.OpenEdit();
            Got += 'open ' + Log.Take(true, 4);
            Row.Get(2);
            P.GoToRecord(Row);
            Got += ' goto ' + Log.Take(true, 4);
            P.Close();
            Got += ' close ' + Log.Take(true, 4) + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Finish();
    end;

    [Test]
    procedure G615_Worksheet_4DifferentFields()
    var
        P: TestPage "LT Y61 CC K4 Worksheet";
        Row: Record "LT Y61 CC K4";
        Got: Text;
        Round: Integer;
    begin
        SeedK4();
        for Round := 1 to 3 do begin
            Log.Take(false, 0);
            P.OpenEdit();
            Got += 'open ' + Log.Take(true, 4);
            Row.Get(2);
            P.GoToRecord(Row);
            Got += ' goto ' + Log.Take(true, 4);
            P.Close();
            Got += ' close ' + Log.Take(true, 4) + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Finish();
    end;

    [Test]
    procedure G615_List_4SameTextFields()
    var
        P: TestPage "LT Y61 CC K4S List";
        Row: Record "LT Y61 CC K4S";
        Got: Text;
        Round: Integer;
    begin
        SeedK4S();
        for Round := 1 to 3 do begin
            Log.Take(false, 0);
            P.OpenEdit();
            Got += 'open ' + Log.Take(false, 0);
            Row.Get(2);
            P.GoToRecord(Row);
            Got += ' goto ' + Log.Take(false, 0);
            P.Close();
            Got += ' close ' + Log.Take(false, 0) + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Finish();
    end;

    [Test]
    procedure G615_List_3Fields_SameText()
    var
        P: TestPage "LT Y61 CC K3S List";
        Row: Record "LT Y61 CC K3S";
        Got: Text;
        Round: Integer;
    begin
        SeedK3S();
        for Round := 1 to 3 do begin
            Log.Take(false, 0);
            P.OpenEdit();
            Got += 'open ' + Log.Take(false, 0);
            Row.Get(2);
            P.GoToRecord(Row);
            Got += ' goto ' + Log.Take(false, 0);
            P.Close();
            Got += ' close ' + Log.Take(false, 0) + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Finish();
    end;

    [Test]
    procedure G615_List_15Fields_DictRead()
    var
        P: TestPage "LT Y61 CC K15 List";
        Row: Record "LT Y61 CC K15";
        Got: Text;
        Round: Integer;
    begin
        SeedK15();
        for Round := 1 to 3 do begin
            Log.Take(false, 0);
            P.OpenEdit();
            Got += 'open ' + Log.Take(true, 16);
            Row.Get(2);
            P.GoToRecord(Row);
            Got += ' goto ' + Log.Take(true, 16);
            P.Close();
            Got += ' close ' + Log.Take(true, 16) + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Finish();
    end;

    [Test]
    procedure G615_List_15Fields_DictRead_More1()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('CountMessages')]
    procedure G615_Card_KM_MessageInExpression()
    var
        P: TestPage "LT Y61 CC KM Card";
        Row: Record "LT Y61 CC KM";
        Got: Text;
        Round: Integer;
    begin
        SeedKM();
        for Round := 1 to 3 do begin
            Log.Take(false, 0);
            P.OpenEdit();
            Got += 'open ' + Log.Take(false, 0);
            Row.Get(2);
            P.GoToRecord(Row);
            Got += ' goto ' + Log.Take(false, 0);
            P.Close();
            Got += ' close ' + Log.Take(false, 0) + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CountMessages')]
    procedure G615_List_KM_MessageInExpression()
    var
        P: TestPage "LT Y61 CC KM List";
        Row: Record "LT Y61 CC KM";
        Got: Text;
        Round: Integer;
    begin
        SeedKM();
        for Round := 1 to 3 do begin
            Log.Take(false, 0);
            P.OpenEdit();
            Got += 'open ' + Log.Take(false, 0);
            Row.Get(2);
            P.GoToRecord(Row);
            Got += ' goto ' + Log.Take(false, 0);
            P.Close();
            Got += ' close ' + Log.Take(false, 0) + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Finish();
    end;

    [Test]
    procedure G615_Worksheet_1Field()
    var
        P: TestPage "LT Y61 CC K1 Worksheet";
        Row: Record "LT Y61 CC K1";
        Got: Text;
        Round: Integer;
    begin
        SeedK1();
        for Round := 1 to 3 do begin
            Log.Take(false, 0);
            P.OpenEdit();
            Got += 'open ' + Log.Take(false, 0);
            Row.Get(2);
            P.GoToRecord(Row);
            Got += ' goto ' + Log.Take(false, 0);
            P.Close();
            Got += ' close ' + Log.Take(false, 0) + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Finish();
    end;

    [Test]
    procedure G615_ListPlus_1Field()
    var
        P: TestPage "LT Y61 CC K1 ListPlus";
        Row: Record "LT Y61 CC K1";
        Got: Text;
        Round: Integer;
    begin
        SeedK1();
        for Round := 1 to 3 do begin
            Log.Take(false, 0);
            P.OpenEdit();
            Got += 'open ' + Log.Take(false, 0);
            Row.Get(2);
            P.GoToRecord(Row);
            Got += ' goto ' + Log.Take(false, 0);
            P.Close();
            Got += ' close ' + Log.Take(false, 0) + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Finish();
    end;

    local procedure SeedK4()
    var
        Row: Record "LT Y61 CC K4";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
        end;
        Log.Take(false, 0);
    end;

    local procedure SeedK4S()
    var
        Row: Record "LT Y61 CC K4S";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
        end;
        Log.Take(false, 0);
    end;

    local procedure SeedK3S()
    var
        Row: Record "LT Y61 CC K3S";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
        end;
        Log.Take(false, 0);
    end;

    local procedure SeedK15()
    var
        Row: Record "LT Y61 CC K15";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
        end;
        Log.Take(false, 0);
    end;

    local procedure SeedKM()
    var
        Row: Record "LT Y61 CC KM";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
        end;
        Log.Take(false, 0);
    end;

    local procedure SeedK1()
    var
        Row: Record "LT Y61 CC K1";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
        end;
        Log.Take(false, 0);
    end;
}
