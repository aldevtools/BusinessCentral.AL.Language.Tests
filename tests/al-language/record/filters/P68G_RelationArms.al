// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 70705, 70706, 70707, 70708, enum 70713
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: which TableRelation arm applies when several conditions use `Field = const(x)` / `Field = filter(...)`; observed through the error Validate raises for a value missing in the chosen table
// BC versions: 29 (27 and 28 by CI)

codeunit 70726 "LT P68 Relation Arms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryKindRef(var R: Record "LT P68 Rel"; V: Text)
    begin
        R.Validate(RefKind, V);
    end;

    [TryFunction]
    local procedure TryNumRef(var R: Record "LT P68 Rel"; V: Text)
    begin
        R.Validate(RefNum, V);
    end;

    [TryFunction]
    local procedure TryGrpRef(var R: Record "LT P68 Rel"; V: Text)
    begin
        R.Validate(RefGrp, V);
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Seed()
    var
        T1: Record "LT P68 T1";
        T2: Record "LT P68 T2";
        T3: Record "LT P68 T3";
    begin
        T1.DeleteAll();
        T2.DeleteAll();
        T3.DeleteAll();
        T1.Code := 'ONE';
        T1.Insert();
        T2.Code := 'TWO';
        T2.Insert();
        T3.Code := 'THREE';
        T3.Insert();
    end;

    local procedure KindOrdinals(): List of [Integer]
    var
        L: List of [Integer];
    begin
        L.Add(0);
        L.Add(1);
        L.Add(2);
        L.Add(3);
        L.Add(4);
        L.Add(100);
        exit(L);
    end;

    [Test]
    procedure Enum_Arms_Value_ONE()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Rel";
        I: Integer;
    begin
        Seed();
        foreach I in KindOrdinals() do begin
            R.Init();
            R.Kind := "LT P68 Kind".FromInteger(I);
            Observer.Observe('kind' + Format(I) + '-ONE', Outcome(TryKindRef(R, 'ONE')));
        end;
        Observer.Expect('kind0-ONE', 'ok');
        Observer.Expect('kind1-ONE', 'The field RefKind of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('kind2-ONE', 'The field RefKind of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('kind3-ONE', 'The field RefKind of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T3).|DB:PrimRecordNotFound');
        Observer.Expect('kind4-ONE', 'ok');
        Observer.Expect('kind100-ONE', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_Arms_Value_TWO()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Rel";
        I: Integer;
    begin
        Seed();
        foreach I in KindOrdinals() do begin
            R.Init();
            R.Kind := "LT P68 Kind".FromInteger(I);
            Observer.Observe('kind' + Format(I) + '-TWO', Outcome(TryKindRef(R, 'TWO')));
        end;
        Observer.Expect('kind0-TWO', 'The field RefKind of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T1).|DB:PrimRecordNotFound');
        Observer.Expect('kind1-TWO', 'ok');
        Observer.Expect('kind2-TWO', 'ok');
        Observer.Expect('kind3-TWO', 'The field RefKind of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T3).|DB:PrimRecordNotFound');
        Observer.Expect('kind4-TWO', 'ok');
        Observer.Expect('kind100-TWO', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_Arms_Value_THREE()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Rel";
        I: Integer;
    begin
        Seed();
        foreach I in KindOrdinals() do begin
            R.Init();
            R.Kind := "LT P68 Kind".FromInteger(I);
            Observer.Observe('kind' + Format(I) + '-THREE', Outcome(TryKindRef(R, 'THREE')));
        end;
        Observer.Expect('kind0-THREE', 'The field RefKind of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T1).|DB:PrimRecordNotFound');
        Observer.Expect('kind1-THREE', 'The field RefKind of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('kind2-THREE', 'The field RefKind of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('kind3-THREE', 'ok');
        Observer.Expect('kind4-THREE', 'ok');
        Observer.Expect('kind100-THREE', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_Arms_Blank_And_Unknown_Value()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Rel";
        I: Integer;
    begin
        Seed();
        foreach I in KindOrdinals() do begin
            R.Init();
            R.Kind := "LT P68 Kind".FromInteger(I);
            Observer.Observe('kind' + Format(I) + '-blank', Outcome(TryKindRef(R, '')));
            Observer.Observe('kind' + Format(I) + '-NOPE', Outcome(TryKindRef(R, 'NOPE')));
        end;
        Observer.Expect('kind0-blank', 'ok');
        Observer.Expect('kind0-NOPE', 'The field RefKind of table LT P68 Rel contains a value (NOPE) that cannot be found in the related table (LT P68 T1).|DB:PrimRecordNotFound');
        Observer.Expect('kind1-blank', 'ok');
        Observer.Expect('kind1-NOPE', 'The field RefKind of table LT P68 Rel contains a value (NOPE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('kind2-blank', 'ok');
        Observer.Expect('kind2-NOPE', 'The field RefKind of table LT P68 Rel contains a value (NOPE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('kind3-blank', 'ok');
        Observer.Expect('kind3-NOPE', 'The field RefKind of table LT P68 Rel contains a value (NOPE) that cannot be found in the related table (LT P68 T3).|DB:PrimRecordNotFound');
        Observer.Expect('kind4-blank', 'ok');
        Observer.Expect('kind4-NOPE', 'ok');
        Observer.Expect('kind100-blank', 'ok');
        Observer.Expect('kind100-NOPE', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_Arm_Error_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Rel";
    begin
        Seed();
        R.Kind := R.Kind::A;
        asserterror R.Validate(RefKind, 'TWO');
        Observer.ObserveError('A-TWO');
        R.Kind := R.Kind::B;
        asserterror R.Validate(RefKind, 'ONE');
        Observer.ObserveError('B-ONE');
        R.Kind := R.Kind::C;
        asserterror R.Validate(RefKind, 'THREE');
        Observer.ObserveError('C-THREE');
        R.Kind := R.Kind::D;
        asserterror R.Validate(RefKind, 'TWO');
        Observer.ObserveError('D-TWO');
        Observer.Expect('A-TWO|text', 'The field RefKind of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T1).');
        Observer.Expect('A-TWO|code', 'DB:PrimRecordNotFound');
        Observer.Expect('B-ONE|text', 'The field RefKind of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T2).');
        Observer.Expect('B-ONE|code', 'DB:PrimRecordNotFound');
        Observer.Expect('C-THREE|text', 'The field RefKind of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T2).');
        Observer.Expect('C-THREE|code', 'DB:PrimRecordNotFound');
        Observer.Expect('D-TWO|text', 'The field RefKind of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T3).');
        Observer.Expect('D-TWO|code', 'DB:PrimRecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Arms_Overlapping_Ranges()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Rel";
        N: Integer;
    begin
        Seed();
        for N := -1 to 5 do begin
            R.Init();
            R.Num := N;
            Observer.Observe('num' + Format(N) + '-ONE', Outcome(TryNumRef(R, 'ONE')));
            Observer.Observe('num' + Format(N) + '-TWO', Outcome(TryNumRef(R, 'TWO')));
            Observer.Observe('num' + Format(N) + '-THREE', Outcome(TryNumRef(R, 'THREE')));
        end;
        Observer.Expect('num-1-ONE', 'The field RefNum of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T3).|DB:PrimRecordNotFound');
        Observer.Expect('num-1-TWO', 'The field RefNum of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T3).|DB:PrimRecordNotFound');
        Observer.Expect('num-1-THREE', 'ok');
        Observer.Expect('num0-ONE', 'The field RefNum of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T3).|DB:PrimRecordNotFound');
        Observer.Expect('num0-TWO', 'The field RefNum of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T3).|DB:PrimRecordNotFound');
        Observer.Expect('num0-THREE', 'ok');
        Observer.Expect('num1-ONE', 'ok');
        Observer.Expect('num1-TWO', 'The field RefNum of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T1).|DB:PrimRecordNotFound');
        Observer.Expect('num1-THREE', 'The field RefNum of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T1).|DB:PrimRecordNotFound');
        Observer.Expect('num2-ONE', 'ok');
        Observer.Expect('num2-TWO', 'The field RefNum of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T1).|DB:PrimRecordNotFound');
        Observer.Expect('num2-THREE', 'The field RefNum of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T1).|DB:PrimRecordNotFound');
        Observer.Expect('num3-ONE', 'ok');
        Observer.Expect('num3-TWO', 'The field RefNum of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T1).|DB:PrimRecordNotFound');
        Observer.Expect('num3-THREE', 'The field RefNum of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T1).|DB:PrimRecordNotFound');
        Observer.Expect('num4-ONE', 'The field RefNum of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('num4-TWO', 'ok');
        Observer.Expect('num4-THREE', 'The field RefNum of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('num5-ONE', 'The field RefNum of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('num5-TWO', 'ok');
        Observer.Expect('num5-THREE', 'The field RefNum of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Verify();
    end;





    [Test]
    procedure Code_Arms_Const_Blank_Wildcard_Else()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Rel";
        Groups: List of [Text];
        G: Text;
    begin
        Seed();
        Groups.Add('');
        Groups.Add('X');
        Groups.Add('XY');
        Groups.Add('x');
        Groups.Add('Y');
        Groups.Add('AX');
        foreach G in Groups do begin
            R.Init();
            R.Grp := CopyStr(G, 1, 10);
            Observer.Observe('grp[' + G + ']-ONE', Outcome(TryGrpRef(R, 'ONE')));
            Observer.Observe('grp[' + G + ']-TWO', Outcome(TryGrpRef(R, 'TWO')));
            Observer.Observe('grp[' + G + ']-THREE', Outcome(TryGrpRef(R, 'THREE')));
        end;
        Observer.Expect('grp[]-ONE', 'ok');
        Observer.Expect('grp[]-TWO', 'The field RefGrp of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T1).|DB:PrimRecordNotFound');
        Observer.Expect('grp[]-THREE', 'The field RefGrp of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T1).|DB:PrimRecordNotFound');
        Observer.Expect('grp[X]-ONE', 'The field RefGrp of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('grp[X]-TWO', 'ok');
        Observer.Expect('grp[X]-THREE', 'The field RefGrp of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('grp[XY]-ONE', 'The field RefGrp of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('grp[XY]-TWO', 'ok');
        Observer.Expect('grp[XY]-THREE', 'The field RefGrp of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('grp[x]-ONE', 'The field RefGrp of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('grp[x]-TWO', 'ok');
        Observer.Expect('grp[x]-THREE', 'The field RefGrp of table LT P68 Rel contains a value (THREE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('grp[Y]-ONE', 'The field RefGrp of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T3).|DB:PrimRecordNotFound');
        Observer.Expect('grp[Y]-TWO', 'The field RefGrp of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T3).|DB:PrimRecordNotFound');
        Observer.Expect('grp[Y]-THREE', 'ok');
        Observer.Expect('grp[AX]-ONE', 'The field RefGrp of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T3).|DB:PrimRecordNotFound');
        Observer.Expect('grp[AX]-TWO', 'The field RefGrp of table LT P68 Rel contains a value (TWO) that cannot be found in the related table (LT P68 T3).|DB:PrimRecordNotFound');
        Observer.Expect('grp[AX]-THREE', 'ok');
        Observer.Verify();
    end;





    [Test]
    procedure Condition_Change_After_Validate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Rel";
    begin
        Seed();
        R.Init();
        R.Kind := R.Kind::A;
        Observer.Observe('valid-for-A', Outcome(TryKindRef(R, 'ONE')));
        R.Kind := R.Kind::B;
        Observer.Observe('value-kept', R.RefKind);
        Observer.Observe('revalidate-for-B', Outcome(TryKindRef(R, R.RefKind)));
        R.Validate(Kind, R.Kind::A);
        Observer.Observe('validate-kind-keeps-ref', R.RefKind);
        Observer.Expect('valid-for-A', 'ok');
        Observer.Expect('value-kept', 'ONE');
        Observer.Expect('revalidate-for-B', 'The field RefKind of table LT P68 Rel contains a value (ONE) that cannot be found in the related table (LT P68 T2).|DB:PrimRecordNotFound');
        Observer.Expect('validate-kind-keeps-ref', 'ONE');
        Observer.Verify();
    end;
}
