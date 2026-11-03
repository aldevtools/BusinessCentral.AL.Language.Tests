// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-methods#parameters
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own codeunits 87140 (host), 87141 (tests)
// Probe: writer QP, observed on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what those tiers produced.
// Facts: a codeunit passes its own GLOBAL Integer and Text by var to its own procedure P. P calls a second procedure Q that changes the
//   globals by their names, then P reads its parameters; and the other way round: P changes its parameters, then Q reads the globals by name.
//   The values P sees, the values Q sees, and the globals after the call (al-runtime-rs "var parameter that is a global of the caller":
//   are the parameter and the global one variable). The event form is pinned in events/lt-event-var-through-sender/EventVarThroughSender.al.
// BC versions: 27, 28, 29 by CI

codeunit 87140 "LT QP Alias Host"
{
    var
        GInt: Integer;
        GTxt: Text;
        Seen: Text;

    procedure GlobalChangedByName(): Text
    begin
        GInt := 1;
        GTxt := 'g1';
        Seen := '';
        P_ReadAfterQ(GInt, GTxt);
        Seen += 'after:' + Format(GInt) + '/' + GTxt;
        exit(Seen);
    end;

    procedure ParamChanged(): Text
    begin
        GInt := 1;
        GTxt := 'g1';
        Seen := '';
        P_ChangeThenQ(GInt, GTxt);
        Seen += 'after:' + Format(GInt) + '/' + GTxt;
        exit(Seen);
    end;

    procedure BothChanged(): Text
    begin
        GInt := 1;
        GTxt := 'g1';
        Seen := '';
        P_Both(GInt, GTxt);
        Seen += 'after:' + Format(GInt) + '/' + GTxt;
        exit(Seen);
    end;

    procedure IntegerOnly(): Text
    begin
        GInt := 5;
        Seen := '';
        P_Int(GInt);
        Seen += 'after:' + Format(GInt);
        exit(Seen);
    end;

    procedure TextOnly(): Text
    begin
        GTxt := 'x';
        Seen := '';
        P_Txt(GTxt);
        Seen += 'after:' + GTxt;
        exit(Seen);
    end;

    local procedure P_ReadAfterQ(var I: Integer; var T: Text)
    begin
        Seen += 'p_in:' + Format(I) + '/' + T + ';';
        Q_SetGlobals(20, 'q20');
        Seen += 'p_after_q:' + Format(I) + '/' + T + ';';
    end;

    local procedure P_ChangeThenQ(var I: Integer; var T: Text)
    begin
        I := 30;
        T := 'p30';
        Seen += 'p_set;';
        Q_ReadGlobals();
    end;

    local procedure P_Both(var I: Integer; var T: Text)
    begin
        Q_SetGlobals(20, 'q20');
        I += 100;
        T += '+p';
        Seen += 'p_after_add:' + Format(I) + '/' + T + ';';
        Q_ReadGlobals();
        Q_SetGlobals(7, 'q7');
        Seen += 'p_end:' + Format(I) + '/' + T + ';';
    end;

    local procedure P_Int(var I: Integer)
    begin
        GInt := GInt + 1;
        Seen += 'p_after_global_inc:' + Format(I) + ';';
        I := I + 10;
        Seen += 'p_global_after_param_inc:' + Format(GInt) + ';';
    end;

    local procedure P_Txt(var T: Text)
    begin
        GTxt += 'G';
        Seen += 'p_after_global_append:' + T + ';';
        T += 'P';
        Seen += 'p_global_after_param_append:' + GTxt + ';';
    end;

    local procedure Q_SetGlobals(NewInt: Integer; NewTxt: Text)
    begin
        GInt := NewInt;
        GTxt := NewTxt;
    end;

    local procedure Q_ReadGlobals()
    begin
        Seen += 'q_sees:' + Format(GInt) + '/' + GTxt + ';';
    end;
}

codeunit 87141 "LT QP Var Global Alias"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure VarGlobal_QChangesGlobal_PReadsParam()
    var
        Observer: Codeunit "Probe Observer";
        Host: Codeunit "LT QP Alias Host";
    begin
        Observer.Observe('trace', Host.GlobalChangedByName());
        Observer.Expect('trace', 'p_in:1/g1;p_after_q:20/q20;after:20/q20');
        Observer.Verify();
    end;

    [Test]
    procedure VarGlobal_PChangesParam_QReadsGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Host: Codeunit "LT QP Alias Host";
    begin
        Observer.Observe('trace', Host.ParamChanged());
        Observer.Expect('trace', 'p_set;q_sees:30/p30;after:30/p30');
        Observer.Verify();
    end;

    [Test]
    procedure VarGlobal_BothChangeInTurn()
    var
        Observer: Codeunit "Probe Observer";
        Host: Codeunit "LT QP Alias Host";
    begin
        Observer.Observe('trace', Host.BothChanged());
        Observer.Expect('trace', 'p_after_add:120/q20+p;q_sees:120/q20+p;p_end:7/q7;after:7/q7');
        Observer.Verify();
    end;

    [Test]
    procedure VarGlobal_IntegerAndTextInsideP()
    var
        Observer: Codeunit "Probe Observer";
        Host: Codeunit "LT QP Alias Host";
    begin
        Observer.Observe('int', Host.IntegerOnly());
        Observer.Observe('text', Host.TextOnly());
        Observer.Expect('int', 'p_after_global_inc:6;p_global_after_param_inc:16;after:16');
        Observer.Expect('text', 'p_after_global_append:xG;p_global_after_param_append:xGP;after:xGP');
        Observer.Verify();
    end;
}
