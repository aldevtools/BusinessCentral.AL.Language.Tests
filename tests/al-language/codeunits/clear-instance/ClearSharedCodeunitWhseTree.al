// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CKK Row" (table 86270) of ClearSharedCodeunitGlobalKinds.al; self-contained objects 86740 to 86751
// Probe: ClearAll in an owner codeunit over the whole tree of codeunit globals below a TableNo register, in the shape of
// "Whse. Jnl.-Register Line" (BC 29): a plain codeunit at depth 1 holding a SingleInstance codeunit with non-temporary records,
// Labels and a Boolean ("Item Tracking Management" holding "Unit of Measure Management"), a SingleInstance codeunit at depth 1
// ("Sequence No. Mgt."), SingleInstance under SingleInstance, plain under SingleInstance, plain under plain under SingleInstance.
// Every node holds the same global kinds: non-temporary and temporary record, Boolean, Integer, Decimal, BigInteger, Text,
// Code, Date, DateTime, Option, Enum, List, Dictionary, TextBuilder, Guid, RecordRef and Labels (plain, Comment, Locked,
// MaxLength). al-runner issue 9194.
// singleinstance-shared-on-purpose: the subject is SingleInstance codeunits held below a register that ClearAll resets.
// BC versions: 27, 28, 29
// What BC did: OBSERVE
enum 86740 "CWT Kind"
{
    Extensible = false;

    value(0; A) { }
    value(1; B) { }
}

codeunit 86741 "CWT S4"
{
    SingleInstance = true;

    var
        R: Record "CKK Row";
        T: Record "CKK Row" temporary;
        B: Boolean;
        I: Integer;
        Dc: Decimal;
        Bi: BigInteger;
        Tx: Text;
        Cd: Code[20];
        D: Date;
        Dt: DateTime;
        Op: Option A,B,C;
        En: Enum "CWT Kind";
        L: List of [Integer];
        Dict: Dictionary of [Integer, Text];
        Tb: TextBuilder;
        G: Guid;
        RR: RecordRef;
        Lp: Label 'lp';
        Lc: Label 'lc', Comment = 'c';
        Ll: Label 'll', Locked = true;
        Lm: Label 'lm', MaxLength = 10;

    procedure SetAll(Seed: Integer)
    begin
        SetOwn(Seed);
    end;

    procedure SetOwn(Seed: Integer)
    begin
        Clear(R);
        Clear(L);
        Clear(Dict);
        Clear(Tb);
        Clear(G);
        T.Reset();
        T.DeleteAll();
        if RR.Number <> 0 then
            RR.Close();
        B := Seed <> 0;
        I := Seed;
        Dc := Seed / 2;
        Bi := Seed * 1000000000L;
        Tx := Format(Seed);
        Cd := 'C' + Format(Seed);
        D := 0D;
        Dt := 0DT;
        Op := Op::A;
        En := En::A;
        if Seed = 0 then
            exit;
        R.SetRange("No.", Seed);
        R.Txt := 'r' + Format(Seed);
        T.Init();
        T."No." := Seed;
        T.Insert();
        D := DMY2Date(1, 1, 2000 + Seed);
        Dt := CreateDateTime(D, 120000T);
        Op := Op::C;
        En := En::B;
        L.Add(Seed);
        Dict.Add(Seed, Format(Seed));
        Tb.Append('t' + Format(Seed));
        G := CreateGuid();
        RR.Open(Database::"CKK Row");
    end;

    procedure AddStates(var Out: List of [Text])
    begin
        Out.Add('S4.rec=' + R.GetFilters() + '/' + R.Txt);
        Out.Add('S4.tmp=' + Format(T.Count()));
        Out.Add('S4.scalars=' + Format(B) + '/' + Format(I) + '/' + Format(Dc, 0, 9) + '/' + Format(Bi) + '/' + Tx + '/' + Cd);
        Out.Add('S4.time=' + Format(D, 0, 9) + '/' + Format(Dt <> 0DT));
        Out.Add('S4.enum=' + Format(Op) + '/' + Format(En));
        Out.Add('S4.coll=' + Format(L.Count()) + '/' + Format(Dict.Count()) + '/' + Tb.ToText());
        Out.Add('S4.ref=' + Format(IsNullGuid(G)) + '/' + Format(RR.Number));
        Out.Add('S4.labels=' + Lp + '/' + Lc + '/' + Ll + '/' + Lm);
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;
}

codeunit 86742 "CWT P4"
{
    var
        R: Record "CKK Row";
        T: Record "CKK Row" temporary;
        B: Boolean;
        I: Integer;
        Dc: Decimal;
        Bi: BigInteger;
        Tx: Text;
        Cd: Code[20];
        D: Date;
        Dt: DateTime;
        Op: Option A,B,C;
        En: Enum "CWT Kind";
        L: List of [Integer];
        Dict: Dictionary of [Integer, Text];
        Tb: TextBuilder;
        G: Guid;
        RR: RecordRef;
        Lp: Label 'lp';
        Lc: Label 'lc', Comment = 'c';
        Ll: Label 'll', Locked = true;
        Lm: Label 'lm', MaxLength = 10;

    procedure SetAll(Seed: Integer)
    begin
        SetOwn(Seed);
    end;

    procedure SetOwn(Seed: Integer)
    begin
        Clear(R);
        Clear(L);
        Clear(Dict);
        Clear(Tb);
        Clear(G);
        T.Reset();
        T.DeleteAll();
        if RR.Number <> 0 then
            RR.Close();
        B := Seed <> 0;
        I := Seed;
        Dc := Seed / 2;
        Bi := Seed * 1000000000L;
        Tx := Format(Seed);
        Cd := 'C' + Format(Seed);
        D := 0D;
        Dt := 0DT;
        Op := Op::A;
        En := En::A;
        if Seed = 0 then
            exit;
        R.SetRange("No.", Seed);
        R.Txt := 'r' + Format(Seed);
        T.Init();
        T."No." := Seed;
        T.Insert();
        D := DMY2Date(1, 1, 2000 + Seed);
        Dt := CreateDateTime(D, 120000T);
        Op := Op::C;
        En := En::B;
        L.Add(Seed);
        Dict.Add(Seed, Format(Seed));
        Tb.Append('t' + Format(Seed));
        G := CreateGuid();
        RR.Open(Database::"CKK Row");
    end;

    procedure AddStates(var Out: List of [Text])
    begin
        Out.Add('P4.rec=' + R.GetFilters() + '/' + R.Txt);
        Out.Add('P4.tmp=' + Format(T.Count()));
        Out.Add('P4.scalars=' + Format(B) + '/' + Format(I) + '/' + Format(Dc, 0, 9) + '/' + Format(Bi) + '/' + Tx + '/' + Cd);
        Out.Add('P4.time=' + Format(D, 0, 9) + '/' + Format(Dt <> 0DT));
        Out.Add('P4.enum=' + Format(Op) + '/' + Format(En));
        Out.Add('P4.coll=' + Format(L.Count()) + '/' + Format(Dict.Count()) + '/' + Tb.ToText());
        Out.Add('P4.ref=' + Format(IsNullGuid(G)) + '/' + Format(RR.Number));
        Out.Add('P4.labels=' + Lp + '/' + Lc + '/' + Ll + '/' + Lm);
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;
}

codeunit 86743 "CWT S3"
{
    SingleInstance = true;

    var
        R: Record "CKK Row";
        T: Record "CKK Row" temporary;
        B: Boolean;
        I: Integer;
        Dc: Decimal;
        Bi: BigInteger;
        Tx: Text;
        Cd: Code[20];
        D: Date;
        Dt: DateTime;
        Op: Option A,B,C;
        En: Enum "CWT Kind";
        L: List of [Integer];
        Dict: Dictionary of [Integer, Text];
        Tb: TextBuilder;
        G: Guid;
        RR: RecordRef;
        Lp: Label 'lp';
        Lc: Label 'lc', Comment = 'c';
        Ll: Label 'll', Locked = true;
        Lm: Label 'lm', MaxLength = 10;

    procedure SetAll(Seed: Integer)
    begin
        SetOwn(Seed);
    end;

    procedure SetOwn(Seed: Integer)
    begin
        Clear(R);
        Clear(L);
        Clear(Dict);
        Clear(Tb);
        Clear(G);
        T.Reset();
        T.DeleteAll();
        if RR.Number <> 0 then
            RR.Close();
        B := Seed <> 0;
        I := Seed;
        Dc := Seed / 2;
        Bi := Seed * 1000000000L;
        Tx := Format(Seed);
        Cd := 'C' + Format(Seed);
        D := 0D;
        Dt := 0DT;
        Op := Op::A;
        En := En::A;
        if Seed = 0 then
            exit;
        R.SetRange("No.", Seed);
        R.Txt := 'r' + Format(Seed);
        T.Init();
        T."No." := Seed;
        T.Insert();
        D := DMY2Date(1, 1, 2000 + Seed);
        Dt := CreateDateTime(D, 120000T);
        Op := Op::C;
        En := En::B;
        L.Add(Seed);
        Dict.Add(Seed, Format(Seed));
        Tb.Append('t' + Format(Seed));
        G := CreateGuid();
        RR.Open(Database::"CKK Row");
    end;

    procedure AddStates(var Out: List of [Text])
    begin
        Out.Add('S3.rec=' + R.GetFilters() + '/' + R.Txt);
        Out.Add('S3.tmp=' + Format(T.Count()));
        Out.Add('S3.scalars=' + Format(B) + '/' + Format(I) + '/' + Format(Dc, 0, 9) + '/' + Format(Bi) + '/' + Tx + '/' + Cd);
        Out.Add('S3.time=' + Format(D, 0, 9) + '/' + Format(Dt <> 0DT));
        Out.Add('S3.enum=' + Format(Op) + '/' + Format(En));
        Out.Add('S3.coll=' + Format(L.Count()) + '/' + Format(Dict.Count()) + '/' + Tb.ToText());
        Out.Add('S3.ref=' + Format(IsNullGuid(G)) + '/' + Format(RR.Number));
        Out.Add('S3.labels=' + Lp + '/' + Lc + '/' + Ll + '/' + Lm);
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;
}

codeunit 86744 "CWT P3"
{
    var
        R: Record "CKK Row";
        T: Record "CKK Row" temporary;
        B: Boolean;
        I: Integer;
        Dc: Decimal;
        Bi: BigInteger;
        Tx: Text;
        Cd: Code[20];
        D: Date;
        Dt: DateTime;
        Op: Option A,B,C;
        En: Enum "CWT Kind";
        L: List of [Integer];
        Dict: Dictionary of [Integer, Text];
        Tb: TextBuilder;
        G: Guid;
        RR: RecordRef;
        Lp: Label 'lp';
        Lc: Label 'lc', Comment = 'c';
        Ll: Label 'll', Locked = true;
        Lm: Label 'lm', MaxLength = 10;
        P4: Codeunit "CWT P4";

    procedure SetAll(Seed: Integer)
    begin
        SetOwn(Seed);
        P4.SetAll(Seed);
    end;

    procedure SetOwn(Seed: Integer)
    begin
        Clear(R);
        Clear(L);
        Clear(Dict);
        Clear(Tb);
        Clear(G);
        T.Reset();
        T.DeleteAll();
        if RR.Number <> 0 then
            RR.Close();
        B := Seed <> 0;
        I := Seed;
        Dc := Seed / 2;
        Bi := Seed * 1000000000L;
        Tx := Format(Seed);
        Cd := 'C' + Format(Seed);
        D := 0D;
        Dt := 0DT;
        Op := Op::A;
        En := En::A;
        if Seed = 0 then
            exit;
        R.SetRange("No.", Seed);
        R.Txt := 'r' + Format(Seed);
        T.Init();
        T."No." := Seed;
        T.Insert();
        D := DMY2Date(1, 1, 2000 + Seed);
        Dt := CreateDateTime(D, 120000T);
        Op := Op::C;
        En := En::B;
        L.Add(Seed);
        Dict.Add(Seed, Format(Seed));
        Tb.Append('t' + Format(Seed));
        G := CreateGuid();
        RR.Open(Database::"CKK Row");
    end;

    procedure AddStates(var Out: List of [Text])
    begin
        Out.Add('P3.rec=' + R.GetFilters() + '/' + R.Txt);
        Out.Add('P3.tmp=' + Format(T.Count()));
        Out.Add('P3.scalars=' + Format(B) + '/' + Format(I) + '/' + Format(Dc, 0, 9) + '/' + Format(Bi) + '/' + Tx + '/' + Cd);
        Out.Add('P3.time=' + Format(D, 0, 9) + '/' + Format(Dt <> 0DT));
        Out.Add('P3.enum=' + Format(Op) + '/' + Format(En));
        Out.Add('P3.coll=' + Format(L.Count()) + '/' + Format(Dict.Count()) + '/' + Tb.ToText());
        Out.Add('P3.ref=' + Format(IsNullGuid(G)) + '/' + Format(RR.Number));
        Out.Add('P3.labels=' + Lp + '/' + Lc + '/' + Ll + '/' + Lm);
        P4.AddStates(Out);
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;
}

codeunit 86745 "CWT S2"
{
    SingleInstance = true;

    var
        R: Record "CKK Row";
        T: Record "CKK Row" temporary;
        B: Boolean;
        I: Integer;
        Dc: Decimal;
        Bi: BigInteger;
        Tx: Text;
        Cd: Code[20];
        D: Date;
        Dt: DateTime;
        Op: Option A,B,C;
        En: Enum "CWT Kind";
        L: List of [Integer];
        Dict: Dictionary of [Integer, Text];
        Tb: TextBuilder;
        G: Guid;
        RR: RecordRef;
        Lp: Label 'lp';
        Lc: Label 'lc', Comment = 'c';
        Ll: Label 'll', Locked = true;
        Lm: Label 'lm', MaxLength = 10;
        S4: Codeunit "CWT S4";

    procedure SetAll(Seed: Integer)
    begin
        SetOwn(Seed);
        S4.SetAll(Seed);
    end;

    procedure SetOwn(Seed: Integer)
    begin
        Clear(R);
        Clear(L);
        Clear(Dict);
        Clear(Tb);
        Clear(G);
        T.Reset();
        T.DeleteAll();
        if RR.Number <> 0 then
            RR.Close();
        B := Seed <> 0;
        I := Seed;
        Dc := Seed / 2;
        Bi := Seed * 1000000000L;
        Tx := Format(Seed);
        Cd := 'C' + Format(Seed);
        D := 0D;
        Dt := 0DT;
        Op := Op::A;
        En := En::A;
        if Seed = 0 then
            exit;
        R.SetRange("No.", Seed);
        R.Txt := 'r' + Format(Seed);
        T.Init();
        T."No." := Seed;
        T.Insert();
        D := DMY2Date(1, 1, 2000 + Seed);
        Dt := CreateDateTime(D, 120000T);
        Op := Op::C;
        En := En::B;
        L.Add(Seed);
        Dict.Add(Seed, Format(Seed));
        Tb.Append('t' + Format(Seed));
        G := CreateGuid();
        RR.Open(Database::"CKK Row");
    end;

    procedure AddStates(var Out: List of [Text])
    begin
        Out.Add('S2.rec=' + R.GetFilters() + '/' + R.Txt);
        Out.Add('S2.tmp=' + Format(T.Count()));
        Out.Add('S2.scalars=' + Format(B) + '/' + Format(I) + '/' + Format(Dc, 0, 9) + '/' + Format(Bi) + '/' + Tx + '/' + Cd);
        Out.Add('S2.time=' + Format(D, 0, 9) + '/' + Format(Dt <> 0DT));
        Out.Add('S2.enum=' + Format(Op) + '/' + Format(En));
        Out.Add('S2.coll=' + Format(L.Count()) + '/' + Format(Dict.Count()) + '/' + Tb.ToText());
        Out.Add('S2.ref=' + Format(IsNullGuid(G)) + '/' + Format(RR.Number));
        Out.Add('S2.labels=' + Lp + '/' + Lc + '/' + Ll + '/' + Lm);
        S4.AddStates(Out);
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;
}

codeunit 86746 "CWT P2"
{
    var
        R: Record "CKK Row";
        T: Record "CKK Row" temporary;
        B: Boolean;
        I: Integer;
        Dc: Decimal;
        Bi: BigInteger;
        Tx: Text;
        Cd: Code[20];
        D: Date;
        Dt: DateTime;
        Op: Option A,B,C;
        En: Enum "CWT Kind";
        L: List of [Integer];
        Dict: Dictionary of [Integer, Text];
        Tb: TextBuilder;
        G: Guid;
        RR: RecordRef;
        Lp: Label 'lp';
        Lc: Label 'lc', Comment = 'c';
        Ll: Label 'll', Locked = true;
        Lm: Label 'lm', MaxLength = 10;

    procedure SetAll(Seed: Integer)
    begin
        SetOwn(Seed);
    end;

    procedure SetOwn(Seed: Integer)
    begin
        Clear(R);
        Clear(L);
        Clear(Dict);
        Clear(Tb);
        Clear(G);
        T.Reset();
        T.DeleteAll();
        if RR.Number <> 0 then
            RR.Close();
        B := Seed <> 0;
        I := Seed;
        Dc := Seed / 2;
        Bi := Seed * 1000000000L;
        Tx := Format(Seed);
        Cd := 'C' + Format(Seed);
        D := 0D;
        Dt := 0DT;
        Op := Op::A;
        En := En::A;
        if Seed = 0 then
            exit;
        R.SetRange("No.", Seed);
        R.Txt := 'r' + Format(Seed);
        T.Init();
        T."No." := Seed;
        T.Insert();
        D := DMY2Date(1, 1, 2000 + Seed);
        Dt := CreateDateTime(D, 120000T);
        Op := Op::C;
        En := En::B;
        L.Add(Seed);
        Dict.Add(Seed, Format(Seed));
        Tb.Append('t' + Format(Seed));
        G := CreateGuid();
        RR.Open(Database::"CKK Row");
    end;

    procedure AddStates(var Out: List of [Text])
    begin
        Out.Add('P2.rec=' + R.GetFilters() + '/' + R.Txt);
        Out.Add('P2.tmp=' + Format(T.Count()));
        Out.Add('P2.scalars=' + Format(B) + '/' + Format(I) + '/' + Format(Dc, 0, 9) + '/' + Format(Bi) + '/' + Tx + '/' + Cd);
        Out.Add('P2.time=' + Format(D, 0, 9) + '/' + Format(Dt <> 0DT));
        Out.Add('P2.enum=' + Format(Op) + '/' + Format(En));
        Out.Add('P2.coll=' + Format(L.Count()) + '/' + Format(Dict.Count()) + '/' + Tb.ToText());
        Out.Add('P2.ref=' + Format(IsNullGuid(G)) + '/' + Format(RR.Number));
        Out.Add('P2.labels=' + Lp + '/' + Lc + '/' + Ll + '/' + Lm);
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;
}

codeunit 86747 "CWT P1"
{
    var
        R: Record "CKK Row";
        T: Record "CKK Row" temporary;
        B: Boolean;
        I: Integer;
        Dc: Decimal;
        Bi: BigInteger;
        Tx: Text;
        Cd: Code[20];
        D: Date;
        Dt: DateTime;
        Op: Option A,B,C;
        En: Enum "CWT Kind";
        L: List of [Integer];
        Dict: Dictionary of [Integer, Text];
        Tb: TextBuilder;
        G: Guid;
        RR: RecordRef;
        Lp: Label 'lp';
        Lc: Label 'lc', Comment = 'c';
        Ll: Label 'll', Locked = true;
        Lm: Label 'lm', MaxLength = 10;
        S2: Codeunit "CWT S2";
        P2: Codeunit "CWT P2";

    procedure SetAll(Seed: Integer)
    begin
        SetOwn(Seed);
        S2.SetAll(Seed);
        P2.SetAll(Seed);
    end;

    procedure SetOwn(Seed: Integer)
    begin
        Clear(R);
        Clear(L);
        Clear(Dict);
        Clear(Tb);
        Clear(G);
        T.Reset();
        T.DeleteAll();
        if RR.Number <> 0 then
            RR.Close();
        B := Seed <> 0;
        I := Seed;
        Dc := Seed / 2;
        Bi := Seed * 1000000000L;
        Tx := Format(Seed);
        Cd := 'C' + Format(Seed);
        D := 0D;
        Dt := 0DT;
        Op := Op::A;
        En := En::A;
        if Seed = 0 then
            exit;
        R.SetRange("No.", Seed);
        R.Txt := 'r' + Format(Seed);
        T.Init();
        T."No." := Seed;
        T.Insert();
        D := DMY2Date(1, 1, 2000 + Seed);
        Dt := CreateDateTime(D, 120000T);
        Op := Op::C;
        En := En::B;
        L.Add(Seed);
        Dict.Add(Seed, Format(Seed));
        Tb.Append('t' + Format(Seed));
        G := CreateGuid();
        RR.Open(Database::"CKK Row");
    end;

    procedure AddStates(var Out: List of [Text])
    begin
        Out.Add('P1.rec=' + R.GetFilters() + '/' + R.Txt);
        Out.Add('P1.tmp=' + Format(T.Count()));
        Out.Add('P1.scalars=' + Format(B) + '/' + Format(I) + '/' + Format(Dc, 0, 9) + '/' + Format(Bi) + '/' + Tx + '/' + Cd);
        Out.Add('P1.time=' + Format(D, 0, 9) + '/' + Format(Dt <> 0DT));
        Out.Add('P1.enum=' + Format(Op) + '/' + Format(En));
        Out.Add('P1.coll=' + Format(L.Count()) + '/' + Format(Dict.Count()) + '/' + Tb.ToText());
        Out.Add('P1.ref=' + Format(IsNullGuid(G)) + '/' + Format(RR.Number));
        Out.Add('P1.labels=' + Lp + '/' + Lc + '/' + Ll + '/' + Lm);
        S2.AddStates(Out);
        P2.AddStates(Out);
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;
}

codeunit 86748 "CWT S1"
{
    SingleInstance = true;

    var
        R: Record "CKK Row";
        T: Record "CKK Row" temporary;
        B: Boolean;
        I: Integer;
        Dc: Decimal;
        Bi: BigInteger;
        Tx: Text;
        Cd: Code[20];
        D: Date;
        Dt: DateTime;
        Op: Option A,B,C;
        En: Enum "CWT Kind";
        L: List of [Integer];
        Dict: Dictionary of [Integer, Text];
        Tb: TextBuilder;
        G: Guid;
        RR: RecordRef;
        Lp: Label 'lp';
        Lc: Label 'lc', Comment = 'c';
        Ll: Label 'll', Locked = true;
        Lm: Label 'lm', MaxLength = 10;
        S3: Codeunit "CWT S3";
        P3: Codeunit "CWT P3";

    procedure SetAll(Seed: Integer)
    begin
        SetOwn(Seed);
        S3.SetAll(Seed);
        P3.SetAll(Seed);
    end;

    procedure SetOwn(Seed: Integer)
    begin
        Clear(R);
        Clear(L);
        Clear(Dict);
        Clear(Tb);
        Clear(G);
        T.Reset();
        T.DeleteAll();
        if RR.Number <> 0 then
            RR.Close();
        B := Seed <> 0;
        I := Seed;
        Dc := Seed / 2;
        Bi := Seed * 1000000000L;
        Tx := Format(Seed);
        Cd := 'C' + Format(Seed);
        D := 0D;
        Dt := 0DT;
        Op := Op::A;
        En := En::A;
        if Seed = 0 then
            exit;
        R.SetRange("No.", Seed);
        R.Txt := 'r' + Format(Seed);
        T.Init();
        T."No." := Seed;
        T.Insert();
        D := DMY2Date(1, 1, 2000 + Seed);
        Dt := CreateDateTime(D, 120000T);
        Op := Op::C;
        En := En::B;
        L.Add(Seed);
        Dict.Add(Seed, Format(Seed));
        Tb.Append('t' + Format(Seed));
        G := CreateGuid();
        RR.Open(Database::"CKK Row");
    end;

    procedure AddStates(var Out: List of [Text])
    begin
        Out.Add('S1.rec=' + R.GetFilters() + '/' + R.Txt);
        Out.Add('S1.tmp=' + Format(T.Count()));
        Out.Add('S1.scalars=' + Format(B) + '/' + Format(I) + '/' + Format(Dc, 0, 9) + '/' + Format(Bi) + '/' + Tx + '/' + Cd);
        Out.Add('S1.time=' + Format(D, 0, 9) + '/' + Format(Dt <> 0DT));
        Out.Add('S1.enum=' + Format(Op) + '/' + Format(En));
        Out.Add('S1.coll=' + Format(L.Count()) + '/' + Format(Dict.Count()) + '/' + Tb.ToText());
        Out.Add('S1.ref=' + Format(IsNullGuid(G)) + '/' + Format(RR.Number));
        Out.Add('S1.labels=' + Lp + '/' + Lc + '/' + Ll + '/' + Lm);
        S3.AddStates(Out);
        P3.AddStates(Out);
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;
}

codeunit 86749 "CWT Reg"
{
    TableNo = "CKK Row";

    trigger OnRun()
    begin
    end;

    var
        R: Record "CKK Row";
        T: Record "CKK Row" temporary;
        B: Boolean;
        I: Integer;
        Dc: Decimal;
        Bi: BigInteger;
        Tx: Text;
        Cd: Code[20];
        D: Date;
        Dt: DateTime;
        Op: Option A,B,C;
        En: Enum "CWT Kind";
        L: List of [Integer];
        Dict: Dictionary of [Integer, Text];
        Tb: TextBuilder;
        G: Guid;
        RR: RecordRef;
        Lp: Label 'lp';
        Lc: Label 'lc', Comment = 'c';
        Ll: Label 'll', Locked = true;
        Lm: Label 'lm', MaxLength = 10;
        P1: Codeunit "CWT P1";
        S1: Codeunit "CWT S1";

    procedure SetAll(Seed: Integer)
    begin
        SetOwn(Seed);
        P1.SetAll(Seed);
        S1.SetAll(Seed);
    end;

    procedure SetOwn(Seed: Integer)
    begin
        Clear(R);
        Clear(L);
        Clear(Dict);
        Clear(Tb);
        Clear(G);
        T.Reset();
        T.DeleteAll();
        if RR.Number <> 0 then
            RR.Close();
        B := Seed <> 0;
        I := Seed;
        Dc := Seed / 2;
        Bi := Seed * 1000000000L;
        Tx := Format(Seed);
        Cd := 'C' + Format(Seed);
        D := 0D;
        Dt := 0DT;
        Op := Op::A;
        En := En::A;
        if Seed = 0 then
            exit;
        R.SetRange("No.", Seed);
        R.Txt := 'r' + Format(Seed);
        T.Init();
        T."No." := Seed;
        T.Insert();
        D := DMY2Date(1, 1, 2000 + Seed);
        Dt := CreateDateTime(D, 120000T);
        Op := Op::C;
        En := En::B;
        L.Add(Seed);
        Dict.Add(Seed, Format(Seed));
        Tb.Append('t' + Format(Seed));
        G := CreateGuid();
        RR.Open(Database::"CKK Row");
    end;

    procedure AddStates(var Out: List of [Text])
    begin
        Out.Add('Reg.rec=' + R.GetFilters() + '/' + R.Txt);
        Out.Add('Reg.tmp=' + Format(T.Count()));
        Out.Add('Reg.scalars=' + Format(B) + '/' + Format(I) + '/' + Format(Dc, 0, 9) + '/' + Format(Bi) + '/' + Tx + '/' + Cd);
        Out.Add('Reg.time=' + Format(D, 0, 9) + '/' + Format(Dt <> 0DT));
        Out.Add('Reg.enum=' + Format(Op) + '/' + Format(En));
        Out.Add('Reg.coll=' + Format(L.Count()) + '/' + Format(Dict.Count()) + '/' + Tb.ToText());
        Out.Add('Reg.ref=' + Format(IsNullGuid(G)) + '/' + Format(RR.Number));
        Out.Add('Reg.labels=' + Lp + '/' + Lc + '/' + Ll + '/' + Lm);
        P1.AddStates(Out);
        S1.AddStates(Out);
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;

    procedure ClearInP1()
    begin
        P1.DoClearAll();
    end;
}

codeunit 86750 "CWT Owner"
{
    var
        Reg: Codeunit "CWT Reg";

    procedure Prime(Seed: Integer)
    begin
        Reg.SetAll(Seed);
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;

    procedure ClearInReg()
    begin
        Reg.DoClearAll();
    end;

    procedure ClearInP1()
    begin
        Reg.ClearInP1();
    end;

    procedure AddStates(var Out: List of [Text])
    begin
        Reg.AddStates(Out);
    end;
}

codeunit 86751 "CWT Test"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";

    local procedure ResetSingleInstances()
    var
        S1: Codeunit "CWT S1";
        S2: Codeunit "CWT S2";
    begin
        // S1 also resets S3, P3 and P4; S2 also resets S4.
        S1.SetAll(0);
        S2.SetAll(0);
    end;

    local procedure ObserveList(Prefix: Text; Out: List of [Text])
    var
        Line: Text;
    begin
        foreach Line in Out do
            Observer.Observe(Prefix + CopyStr(Line, 1, StrPos(Line, '=') - 1), CopyStr(Line, StrPos(Line, '=') + 1));
    end;

    local procedure ObserveOwner(Prefix: Text; var Owner: Codeunit "CWT Owner")
    var
        Out: List of [Text];
    begin
        Owner.AddStates(Out);
        ObserveList(Prefix, Out);
    end;

    local procedure ObserveDirect(Prefix: Text)
    var
        S1: Codeunit "CWT S1";
        S2: Codeunit "CWT S2";
        Out: List of [Text];
    begin
        S1.AddStates(Out);
        S2.AddStates(Out);
        ObserveList(Prefix, Out);
    end;

    [Test]
    procedure Tree_OwnerClearAll_Before()
    var
        Owner: Codeunit "CWT Owner";
    begin
        ResetSingleInstances();
        Owner.Prime(1);
        ObserveOwner('before.', Owner);
        Observer.Finish();
    end;

    [Test]
    procedure Tree_OwnerClearAll_After()
    var
        Owner: Codeunit "CWT Owner";
    begin
        ResetSingleInstances();
        Owner.Prime(1);
        Owner.DoClearAll();
        ObserveOwner('after.', Owner);
        Observer.Finish();
    end;

    [Test]
    procedure Tree_OwnerClearAll_DirectSi()
    var
        Owner: Codeunit "CWT Owner";
    begin
        ResetSingleInstances();
        Owner.Prime(1);
        Owner.DoClearAll();
        ObserveDirect('direct.');
        Observer.Finish();
    end;

    [Test]
    procedure Tree_OwnerClearAll_Reprimed()
    var
        Owner: Codeunit "CWT Owner";
    begin
        ResetSingleInstances();
        Owner.Prime(1);
        Owner.DoClearAll();
        Owner.Prime(2);
        ObserveOwner('reprimed.', Owner);
        Observer.Finish();
    end;

    [Test]
    procedure Tree_DirectSiWriteBefore_OwnerClearAll()
    var
        Owner: Codeunit "CWT Owner";
        S1: Codeunit "CWT S1";
        S2: Codeunit "CWT S2";
    begin
        ResetSingleInstances();
        Owner.Prime(1);
        S1.SetAll(3);
        S2.SetAll(4);
        Owner.DoClearAll();
        ObserveOwner('after.', Owner);
        Observer.Finish();
    end;

    [Test]
    procedure Tree_DirectSiWriteAfter_OwnerClearAll()
    var
        Owner: Codeunit "CWT Owner";
        S1: Codeunit "CWT S1";
        S2: Codeunit "CWT S2";
    begin
        ResetSingleInstances();
        Owner.Prime(1);
        Owner.DoClearAll();
        S1.SetAll(5);
        S2.SetAll(6);
        ObserveOwner('after.', Owner);
        Observer.Finish();
    end;

    [Test]
    procedure Tree_RegisterClearAll()
    var
        Owner: Codeunit "CWT Owner";
    begin
        ResetSingleInstances();
        Owner.Prime(1);
        Owner.ClearInReg();
        ObserveOwner('after.', Owner);
        Observer.Finish();
    end;

    [Test]
    procedure Tree_PlainHolderOfSiClearAll()
    var
        Owner: Codeunit "CWT Owner";
    begin
        ResetSingleInstances();
        Owner.Prime(1);
        Owner.ClearInP1();
        ObserveOwner('after.', Owner);
        Observer.Finish();
    end;
}
