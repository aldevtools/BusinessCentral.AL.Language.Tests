// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: LT RcA tables and seed codeunit in RcAObjects.al, Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

enum 71520 "LT RcA Enum"
{
    Extensible = true;
    value(0; Zero) { }
    value(1; One) { }
    value(5; Five) { }
    value(9; Nine) { }
}

table 71500 "LT RcA Main"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; No; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Cd; Code[20]) { }
        field(4; Amt; Decimal) { }
        field(5; Dt; Date) { }
        field(6; Flag; Boolean) { }
        field(7; Opt; Option) { OptionMembers = Alpha,Beta,Gamma; }
        field(8; En; Enum "LT RcA Enum") { }
        field(9; Tx; Text[30]) { }
        field(10; Big; Text[2048]) { }
    }
    keys
    {
        key(PK; No) { Clustered = true; }
        key(ByName; Name) { }
        key(ByCd; Cd, No) { }
        key(ByAmt; Amt) { }
    }
}

table 71501 "LT RcA CodeKey"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Cd; Code[10]) { }
        field(2; Info; Text[30]) { }
    }
    keys { key(PK; Cd) { Clustered = true; } }
}

table 71502 "LT RcA TextKey"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Tx; Text[20]) { }
        field(2; Info; Text[30]) { }
    }
    keys { key(PK; Tx) { Clustered = true; } }
}

table 71503 "LT RcA DecKey"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Dc; Decimal) { }
        field(2; Info; Text[30]) { }
    }
    keys { key(PK; Dc) { Clustered = true; } }
}

table 71504 "LT RcA DateKey"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Dt; Date) { }
        field(2; Info; Text[30]) { }
    }
    keys { key(PK; Dt) { Clustered = true; } }
}

table 71505 "LT RcA BoolKey"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Bl; Boolean) { }
        field(2; Info; Text[30]) { }
    }
    keys { key(PK; Bl) { Clustered = true; } }
}

table 71506 "LT RcA OptKey"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Op; Option) { OptionMembers = Alpha,Beta,Gamma; }
        field(2; Info; Text[30]) { }
    }
    keys { key(PK; Op) { Clustered = true; } }
}

table 71507 "LT RcA EnumKey"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; En; Enum "LT RcA Enum") { }
        field(2; Info; Text[30]) { }
    }
    keys { key(PK; En) { Clustered = true; } }
}

table 71508 "LT RcA Multi"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; A; Code[10]) { }
        field(2; B; Integer) { }
        field(3; C; Date) { }
        field(4; Info; Text[30]) { }
    }
    keys { key(PK; A, B, C) { Clustered = true; } }
}

codeunit 71590 "LT RcA Seed"
{
    procedure Main()
    var
        R: Record "LT RcA Main";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 10 do begin
            R.Init();
            R.No := i * 10;
            R.Name := 'N' + Format(11 - i);
            R.Cd := 'C' + Format(i mod 3);
            R.Amt := i * 1.5;
            R.Dt := DMY2Date(i, 1, 2020);
            R.Flag := (i mod 2) = 0;
            R.Opt := i mod 3;
            R.En := Enum::"LT RcA Enum".FromInteger(i mod 2 * 5);
            R.Tx := 'Item ' + Format(i);
            R.Insert();
        end;
    end;

    procedure Texts()
    var
        R: Record "LT RcA Main";
        Vals: List of [Text];
        V: Text;
        i: Integer;
    begin
        R.DeleteAll();
        Vals.Add('apple');
        Vals.Add('Apple pie');
        Vals.Add('banana');
        Vals.Add('it''s');
        Vals.Add('a&b');
        Vals.Add('x|y');
        Vals.Add('50%');
        Vals.Add('');
        Vals.Add('a.b');
        Vals.Add('Zed');
        foreach V in Vals do begin
            i += 1;
            R.Init();
            R.No := i;
            R.Tx := CopyStr(V, 1, 30);
            R.Name := CopyStr(V, 1, 50);
            R.Insert();
        end;
    end;

    procedure Keys()
    var
        CK: Record "LT RcA CodeKey";
        TK: Record "LT RcA TextKey";
        DK: Record "LT RcA DecKey";
        DtK: Record "LT RcA DateKey";
        BK: Record "LT RcA BoolKey";
        OK: Record "LT RcA OptKey";
        EK: Record "LT RcA EnumKey";
        MK: Record "LT RcA Multi";
        i: Integer;
    begin
        CK.DeleteAll();
        TK.DeleteAll();
        DK.DeleteAll();
        DtK.DeleteAll();
        BK.DeleteAll();
        OK.DeleteAll();
        EK.DeleteAll();
        MK.DeleteAll();
        CK.Cd := 'abc';
        CK.Info := 'lower';
        CK.Insert();
        CK.Cd := 'ABD';
        CK.Info := 'upper';
        CK.Insert();
        CK.Cd := 'X1';
        CK.Info := 'x';
        CK.Insert();
        TK.Tx := 'abc';
        TK.Info := 'lower';
        TK.Insert();
        TK.Tx := 'ABD';
        TK.Info := 'upper';
        TK.Insert();
        TK.Tx := 'abc x';
        TK.Info := 'trailing';
        TK.Insert();
        DK.Dc := 1.5;
        DK.Info := 'a';
        DK.Insert();
        DK.Dc := -2;
        DK.Info := 'b';
        DK.Insert();
        DK.Dc := 0;
        DK.Info := 'c';
        DK.Insert();
        DtK.Dt := 0D;
        DtK.Info := 'blank';
        DtK.Insert();
        DtK.Dt := DMY2Date(1, 2, 2021);
        DtK.Info := 'feb';
        DtK.Insert();
        BK.Bl := false;
        BK.Info := 'f';
        BK.Insert();
        BK.Bl := true;
        BK.Info := 't';
        BK.Insert();
        for i := 0 to 2 do begin
            OK.Op := i;
            OK.Info := 'o' + Format(i);
            OK.Insert();
        end;
        EK.En := EK.En::Zero;
        EK.Info := 'z';
        EK.Insert();
        EK.En := EK.En::Five;
        EK.Info := 'f';
        EK.Insert();
        EK.En := EK.En::Nine;
        EK.Info := 'n';
        EK.Insert();
        MK.A := 'A';
        MK.B := 1;
        MK.C := DMY2Date(1, 1, 2020);
        MK.Info := 'a1';
        MK.Insert();
        MK.A := 'A';
        MK.B := 2;
        MK.C := DMY2Date(1, 1, 2020);
        MK.Info := 'a2';
        MK.Insert();
        MK.A := 'B';
        MK.B := 1;
        MK.C := DMY2Date(2, 1, 2020);
        MK.Info := 'b1';
        MK.Insert();
    end;
}
