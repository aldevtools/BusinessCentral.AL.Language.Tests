// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-methods
// Scope: in-scope
// Fixtures used: Probe Observer (69160); SgListKeyObjects.al (table 89094, pages 89095 and 89096, log 89097)
// Probe: writer SG, al-runtime-rs assumption list-other-key-other-moves; facts in SgListKeyObjects.al.
// BC versions: 27, 28, 29

codeunit 89098 "LT SG List Key Moves"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT SG Key Log";

    local procedure Add(No: Code[10]; NewName: Text[30])
    var
        Row: Record "LT SG Key Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := NewName;
        Row.Insert();
    end;

    local procedure SeedFour()
    var
        Row: Record "LT SG Key Row";
    begin
        Row.DeleteAll();
        Add('A', 'delta');
        Add('B', 'charlie');
        Add('C', 'bravo');
        Add('D', 'alpha');
        Log.Take();
    end;

    local procedure SeedOne()
    var
        Row: Record "LT SG Key Row";
    begin
        Row.DeleteAll();
        Add('A', 'delta');
        Log.Take();
    end;

    local procedure SeedThirty()
    var
        Row: Record "LT SG Key Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 30 do
            Add('R' + Format(i, 2, '<Integer,2><Filler Character,0>'), 'n' + Format(100 - i));
        Log.Take();
    end;

    [Test]
    procedure SG_Key_FourRows_Moves()
    var
        P: TestPage "LT SG Key List";
        Row: Record "LT SG Key Row";
    begin
        SeedFour();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.Last();
        Observer.Observe('last', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.GoToKey('B');
        Observer.Observe('gotokey_b', P.NoCtl.Value() + '|' + Log.Take());
        Row.Get('C');
        P.GoToRecord(Row);
        Observer.Observe('gotorecord_c', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Next();
        Observer.Observe('next', P.NoCtl.Value() + '|' + Log.Take());
        P.Previous();
        Observer.Observe('previous', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'D|R:D;R:C;R:B;R:A;R:D;R:D;R:D;C:D;');
        Observer.Expect('last', 'A|R:A;R:A;R:A;C:A;');
        Observer.Expect('first', 'D|R:D;R:D;R:D;C:D;');
        Observer.Expect('gotokey_b', 'B|R:C;R:C;R:C;C:C;R:B;R:B;R:B;C:B;');
        Observer.Expect('gotorecord_c', 'C|R:D;R:D;R:D;C:D;R:C;R:C;R:C;C:C;');
        Observer.Expect('update', 'C|R:C;U;R:C;R:C;R:C;R:B;R:A;R:C;R:D;R:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'B|R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'C|R:C;R:C;R:C;C:C;');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure SG_Key_OneRow_Open()
    var
        P: TestPage "LT SG Key List";
    begin
        SeedOne();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Expect('open', 'A|R:A;R:A;R:A;C:A;');
        Observer.Expect('first', 'A|');
        Observer.Expect('update', 'A|R:A;U;R:A;R:A;R:A;R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure SG_Key_ThirtyRows_Moves()
    var
        P: TestPage "LT SG Key List";
        Row: Record "LT SG Key Row";
    begin
        SeedThirty();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.Next();
        Observer.Observe('next', P.NoCtl.Value() + '|' + Log.Take());
        P.Last();
        Observer.Observe('last', P.NoCtl.Value() + '|' + Log.Take());
        P.GoToKey('R15');
        Observer.Observe('gotokey_r15', P.NoCtl.Value() + '|' + Log.Take());
        Row.Get('R02');
        P.GoToRecord(Row);
        Observer.Observe('gotorecord_r02', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Expect('open', 'R30|R:R30;R:R29;R:R28;R:R27;R:R26;R:R25;R:R24;R:R23;R:R22;R:R21;R:R20;R:R19;R:R18;R:R17;R:R16;R:R15;R:R14;R:R13;R:R12;R:R11;R:R30;R:R30;R:R30;C:R30;');
        Observer.Expect('next', 'R29|R:R29;R:R29;R:R29;C:R29;');
        Observer.Expect('last', 'R01|R:R11;R:R10;R:R09;R:R08;R:R07;R:R06;R:R05;R:R04;R:R03;R:R02;R:R01;R:R01;R:R01;C:R01;');
        Observer.Expect('gotokey_r15', 'R15|R:R30;R:R30;R:R30;C:R30;R:R29;R:R29;R:R29;C:R29;R:R28;R:R28;R:R28;C:R28;R:R27;R:R27;R:R27;C:R27;R:R26;R:R26;R:R26;C:R26;R:R25;R:R25;R:R25;C:R25;R:R24;R:R24;R:R24;C:R24;R:R23;R:R23;R:R23;C:R23;R:R22;R:R22;R:R22;C:R22;R:R21;R:R21;R:R21;C:R21;R:R20;R:R20;R:R20;C:R20;R:R19;R:R19;R:R19;C:R19;R:R18;R:R18;R:R18;C:R18;R:R17;R:R17;R:R17;C:R17;R:R16;R:R16;R:R16;C:R16;R:R15;R:R15;R:R15;C:R15;');
        Observer.Expect('gotorecord_r02', 'R02|R:R30;R:R30;R:R30;C:R30;R:R29;R:R29;R:R29;C:R29;R:R28;R:R28;R:R28;C:R28;R:R27;R:R27;R:R27;C:R27;R:R26;R:R26;R:R26;C:R26;R:R25;R:R25;R:R25;C:R25;R:R24;R:R24;R:R24;C:R24;R:R23;R:R23;R:R23;C:R23;R:R22;R:R22;R:R22;C:R22;R:R21;R:R21;R:R21;C:R21;R:R20;R:R20;R:R20;C:R20;R:R19;R:R19;R:R19;C:R19;R:R18;R:R18;R:R18;C:R18;R:R17;R:R17;R:R17;C:R17;R:R16;R:R16;R:R16;C:R16;R:R15;R:R15;R:R15;C:R15;R:R14;R:R14;R:R14;C:R14;R:R13;R:R13;R:R13;C:R13;R:R12;R:R12;R:R12;C:R12;R:R11;R:R11;R:R11;C:R11;R:R10;R:R10;R:R10;C:R10;R:R09;R:R09;R:R09;C:R09;R:R08;R:R08;R:R08;C:R08;R:R07;R:R07;R:R07;C:R07;R:R06;R:R06;R:R06;C:R06;R:R05;R:R05;R:R05;C:R05;R:R04;R:R04;R:R04;C:R04;R:R03;R:R03;R:R03;C:R03;R:R02;R:R02;R:R02;C:R02;');
        Observer.Expect('first', 'R30|R:R30;R:R30;R:R30;C:R30;');
        Observer.Expect('update', 'R30|R:R30;U;R:R30;R:R30;R:R30;R:R29;R:R28;R:R27;R:R26;R:R25;R:R24;R:R23;R:R22;R:R21;R:R20;R:R19;R:R18;R:R17;R:R16;R:R15;R:R14;R:R13;R:R12;R:R11;R:R30;R:R30;R:R30;C:R30;');
        Observer.Verify();
    end;

    [Test]
    procedure SG_Pk_FourRows_Moves()
    var
        P: TestPage "LT SG Pk List";
        Row: Record "LT SG Key Row";
    begin
        SeedFour();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.Last();
        Observer.Observe('last', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.GoToKey('B');
        Observer.Observe('gotokey_b', P.NoCtl.Value() + '|' + Log.Take());
        Row.Get('C');
        P.GoToRecord(Row);
        Observer.Observe('gotorecord_c', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Next();
        Observer.Observe('next', P.NoCtl.Value() + '|' + Log.Take());
        P.Previous();
        Observer.Observe('previous', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'A|R:A;R:B;R:C;R:D;R:A;R:A;C:A;');
        Observer.Expect('last', 'D|R:D;R:D;C:D;');
        Observer.Expect('first', 'A|R:A;R:A;C:A;');
        Observer.Expect('gotokey_b', 'B|R:B;R:B;C:B;');
        Observer.Expect('gotorecord_c', 'C|R:A;R:A;C:A;R:B;R:B;C:B;R:C;R:C;C:C;');
        Observer.Expect('update', 'C|R:C;U;R:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'D|R:D;R:D;C:D;');
        Observer.Expect('previous', 'C|R:C;R:C;C:C;');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure SG_Pk_OneRow_Open()
    var
        P: TestPage "LT SG Pk List";
    begin
        SeedOne();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Expect('open', 'A|R:A;R:A;C:A;');
        Observer.Expect('first', 'A|');
        Observer.Expect('update', 'A|R:A;U;R:A;R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure SG_Pk_ThirtyRows_Moves()
    var
        P: TestPage "LT SG Pk List";
        Row: Record "LT SG Key Row";
    begin
        SeedThirty();
        P.OpenView();
        Observer.Observe('open', P.NoCtl.Value() + '|' + Log.Take());
        P.Next();
        Observer.Observe('next', P.NoCtl.Value() + '|' + Log.Take());
        P.Last();
        Observer.Observe('last', P.NoCtl.Value() + '|' + Log.Take());
        P.GoToKey('R15');
        Observer.Observe('gotokey_r15', P.NoCtl.Value() + '|' + Log.Take());
        Row.Get('R02');
        P.GoToRecord(Row);
        Observer.Observe('gotorecord_r02', P.NoCtl.Value() + '|' + Log.Take());
        P.First();
        Observer.Observe('first', P.NoCtl.Value() + '|' + Log.Take());
        P.UpdateAct.Invoke();
        Observer.Observe('update', P.NoCtl.Value() + '|' + Log.Take());
        P.Close();
        Observer.Expect('open', 'R01|R:R01;R:R02;R:R03;R:R04;R:R05;R:R06;R:R07;R:R08;R:R09;R:R10;R:R11;R:R12;R:R13;R:R14;R:R15;R:R16;R:R17;R:R18;R:R19;R:R20;R:R01;R:R01;C:R01;');
        Observer.Expect('next', 'R02|R:R02;R:R02;C:R02;');
        Observer.Expect('last', 'R30|R:R20;R:R21;R:R22;R:R23;R:R24;R:R25;R:R26;R:R27;R:R28;R:R29;R:R30;R:R30;C:R30;');
        Observer.Expect('gotokey_r15', 'R15|R:R01;R:R01;C:R01;R:R02;R:R02;C:R02;R:R03;R:R03;C:R03;R:R04;R:R04;C:R04;R:R05;R:R05;C:R05;R:R06;R:R06;C:R06;R:R07;R:R07;C:R07;R:R08;R:R08;C:R08;R:R09;R:R09;C:R09;R:R10;R:R10;C:R10;R:R11;R:R11;C:R11;R:R12;R:R12;C:R12;R:R13;R:R13;C:R13;R:R14;R:R14;C:R14;R:R15;R:R15;C:R15;');
        Observer.Expect('gotorecord_r02', 'R02|R:R01;R:R01;C:R01;R:R02;R:R02;C:R02;');
        Observer.Expect('first', 'R01|R:R01;R:R01;C:R01;');
        Observer.Expect('update', 'R01|R:R01;U;R:R01;R:R01;R:R02;R:R03;R:R04;R:R05;R:R06;R:R07;R:R08;R:R09;R:R10;R:R11;R:R12;R:R13;R:R14;R:R15;R:R16;R:R17;R:R18;R:R19;R:R20;R:R01;R:R01;C:R01;');
        Observer.Verify();
    end;
}
