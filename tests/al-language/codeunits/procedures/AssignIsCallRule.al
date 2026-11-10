// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-methods
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Probe Observer (codeunit 69160); own objects 96400 to 96412
// BC versions: 27.5+
// Probe (al-runner 7597): `X := v` where X is a procedure written in AL with exactly one parameter. The compiler accepts the statement
// (this file compiles); every test records what the assignment form does next to the call form `X(v)`: the log line a procedure
// writes, the value a `var` parameter gets, the error a TryFunction or a conversion raises, which implementation of an interface runs,
// the order of receiver, right side and call. Already pinned and not repeated: a bare procedure with one value parameter, a member of a
// codeunit variable, a procedure with a return value (ProcedureAssignmentOneParameter.al, record/ProbePropertyAssignmentForms.al
// Y29_OwnProcedure_AssignForms). The shapes the compiler refuses are must-not-compile cases 2373 to 2399.
// Observe-only: every value is recorded through "Probe Observer", the test then fails with OBSERVE:name=value;...
// local object: every object below is the subject of the probe (the kind of object that declares the procedure is the question), and the
// log codeunit 96400 must be SingleInstance so a page, a table and a subscriber write to the log the test reads.

codeunit 96400 "CU AssignCall Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Line: Text)
    begin
        Log += Line + ';';
    end;

    // The log so far; the log is empty afterwards.
    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

table 96403 "CU AssignCall Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure TableProc(V: Integer)
    var
        Log: Codeunit "CU AssignCall Log";
    begin
        Val := V;
        Log.Add('TableProc(' + Format(V) + ') on ' + Format(Id));
    end;

    procedure RunBare(V: Integer)
    begin
        TableProc := V;
    end;

    procedure RunRec(V: Integer)
    begin
        Rec.TableProc := V;
    end;
}

codeunit 96401 "CU AssignCall Target"
{
    var
        Log: Codeunit "CU AssignCall Log";

    procedure P1(V: Integer)
    begin
        Log.Add('P1(' + Format(V) + ')');
    end;

    procedure BumpVar(var V: Integer)
    begin
        Log.Add('BumpVar(' + Format(V) + ')');
        V += 10;
    end;

    [TryFunction]
    procedure TrySet(V: Integer)
    begin
        Log.Add('TrySet(' + Format(V) + ')');
        if V < 0 then
            Error('TrySet refuses %1', V);
    end;

    [IntegrationEvent(false, false)]
    procedure OnEv(V: Integer)
    begin
    end;

    procedure SetRec(R: Record "CU AssignCall Row")
    begin
        Log.Add('SetRec(' + Format(R.Id) + '/' + Format(R.Val) + ')');
        R.Val := 99;
    end;

    procedure SetRecVar(var R: Record "CU AssignCall Row")
    begin
        Log.Add('SetRecVar(' + Format(R.Id) + '/' + Format(R.Val) + ')');
        R.Val := 77;
    end;

    procedure SetShort(T: Text[5])
    begin
        Log.Add('SetShort(' + T + ')');
    end;

    procedure SetCode(C: Code[10])
    begin
        Log.Add('SetCode(' + C + ')');
    end;

    // `CountDown := V - 1` inside CountDown: a recursive call whose result is dropped, or the return value?
    procedure CountDown(V: Integer) Result: Integer
    begin
        Log.Add('CountDown(' + Format(V) + ')');
        Result := V * 100;
        if V > 0 then
            CountDown := V - 1;
    end;

    procedure RunThis()
    begin
        this.P1 := 5;
        this.P1(6);
    end;

    procedure RunLocal()
    begin
        PLocal := 1;
        PLocal(2);
    end;

    local procedure PLocal(V: Integer)
    begin
        Log.Add('PLocal(' + Format(V) + ')');
    end;

    // A local variable with the name of the procedure P1.
    procedure RunShadow(): Integer
    var
        P1: Integer;
    begin
        P1 := 1;
        exit(P1);
    end;

    // A parameter with the name of the procedure P1.
    procedure RunShadowParameter(P1: Integer): Integer
    begin
        P1 := P1 + 1;
        exit(P1);
    end;

    procedure RunEventBare()
    begin
        OnEv := 8;
        OnEv(9);
    end;

    procedure RunTryBare(V: Integer)
    begin
        TrySet := V;
        Log.Add('after TrySet');
    end;
}

codeunit 96402 "CU AssignCall Sub"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CU AssignCall Target", OnEv, '', false, false)]
    local procedure OnEvHandler(V: Integer)
    var
        Log: Codeunit "CU AssignCall Log";
    begin
        Log.Add('subscriber(' + Format(V) + ')');
    end;
}

page 96405 "CU AssignCall Card"
{
    PageType = Card;
    SourceTable = "CU AssignCall Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Val; Rec.Val) { }
        }
    }

    procedure PageProc(V: Integer)
    var
        Log: Codeunit "CU AssignCall Log";
    begin
        Log.Add('PageProc(' + Format(V) + ')');
    end;
}

page 96408 "CU AssignCall Part"
{
    PageType = ListPart;
    SourceTable = "CU AssignCall Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
            }
        }
    }

    procedure SetX(V: Integer)
    var
        Log: Codeunit "CU AssignCall Log";
    begin
        Log.Add('Part.SetX(' + Format(V) + ')');
    end;
}

page 96409 "CU AssignCall Host"
{
    PageType = Card;
    SourceTable = "CU AssignCall Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            part(Sub; "CU AssignCall Part") { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AssignForm)
            {
                trigger OnAction()
                begin
                    CurrPage.Sub.PAGE.SetX := 5;
                end;
            }
            action(CallForm)
            {
                trigger OnAction()
                begin
                    CurrPage.Sub.PAGE.SetX(6);
                end;
            }
        }
    }
}

interface "CU AssignCall IFace"
{
    procedure IProc(V: Integer);
}

codeunit 96407 "CU AssignCall Impl A" implements "CU AssignCall IFace"
{
    procedure IProc(V: Integer)
    var
        Log: Codeunit "CU AssignCall Log";
    begin
        Log.Add('A.IProc(' + Format(V) + ')');
    end;
}

codeunit 96411 "CU AssignCall Impl B" implements "CU AssignCall IFace"
{
    procedure IProc(V: Integer)
    var
        Log: Codeunit "CU AssignCall Log";
    begin
        Log.Add('B.IProc(' + Format(V) + ')');
    end;
}

codeunit 96410 "CU AssignCall Rule"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "CU AssignCall Log";
        Targets: array[2] of Codeunit "CU AssignCall Target";

    local procedure Bump(var V: Integer)
    begin
        Log.Add('Bump(' + Format(V) + ')');
        V += 10;
    end;

    local procedure Outcome(Ok: Boolean): Text
    var
        Result: Text;
    begin
        if Ok then
            exit('ok');
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    // U1: a local procedure.
    [Test]
    procedure AssignCall_LocalProcedure()
    var
        Target: Codeunit "CU AssignCall Target";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Target.RunLocal();
        Observer.Observe('assign then call', Log.Take());
        Observer.Finish();
    end;

    // U2: a `var` parameter, bare name.
    [Test]
    procedure AssignCall_VarParameter_Bare()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        Log.Take();
        I := 1;
        Bump := I;
        Observer.Observe('I after assign', Format(I));
        Bump(I);
        Observer.Observe('I after call', Format(I));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    // U3: a `var` parameter, member of a codeunit variable.
    [Test]
    procedure AssignCall_VarParameter_CodeunitVariable()
    var
        Target: Codeunit "CU AssignCall Target";
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        Log.Take();
        I := 1;
        Target.BumpVar := I;
        Observer.Observe('I after assign', Format(I));
        Target.BumpVar(I);
        Observer.Observe('I after call', Format(I));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetAssign(V: Integer)
    var
        Target: Codeunit "CU AssignCall Target";
    begin
        Target.TrySet := V;
        Log.Add('after assign');
    end;

    [TryFunction]
    local procedure TrySetCall(V: Integer)
    var
        Target: Codeunit "CU AssignCall Target";
    begin
        Target.TrySet(V);
        Log.Add('after call');
    end;

    [TryFunction]
    local procedure TrySetBare(V: Integer)
    var
        Target: Codeunit "CU AssignCall Target";
    begin
        Target.RunTryBare(V);
    end;

    // U4: a TryFunction whose result is dropped, with a body that passes and one that raises.
    [Test]
    procedure AssignCall_TryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Log.Take();
        Ok := TrySetAssign(1);
        Observer.Observe('assign passes', Outcome(Ok));
        Observer.Observe('assign passes log', Log.Take());
        Ok := TrySetCall(1);
        Observer.Observe('call passes', Outcome(Ok));
        Observer.Observe('call passes log', Log.Take());
        Ok := TrySetAssign(-1);
        Observer.Observe('assign raises', Outcome(Ok));
        Observer.Observe('assign raises log', Log.Take());
        Ok := TrySetCall(-1);
        Observer.Observe('call raises', Outcome(Ok));
        Observer.Observe('call raises log', Log.Take());
        Ok := TrySetBare(-2);
        Observer.Observe('bare assign raises', Outcome(Ok));
        Observer.Observe('bare assign raises log', Log.Take());
        Observer.Finish();
    end;

    // U5: an event publisher; a manual subscriber is bound.
    [Test]
    procedure AssignCall_EventPublisher()
    var
        Target: Codeunit "CU AssignCall Target";
        Sub: Codeunit "CU AssignCall Sub";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        BindSubscription(Sub);
        Target.OnEv := 7;
        Observer.Observe('member assign', Log.Take());
        Target.OnEv(6);
        Observer.Observe('member call', Log.Take());
        Target.RunEventBare();
        Observer.Observe('bare assign then call', Log.Take());
        UnbindSubscription(Sub);
        Target.OnEv := 5;
        Observer.Observe('unbound assign', Log.Take());
        Observer.Finish();
    end;

    // U6: a procedure of a table, on a Record variable and bare inside the table.
    [Test]
    procedure AssignCall_TableProcedure()
    var
        Row: Record "CU AssignCall Row";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Row.Id := 1;
        Row.TableProc := 5;
        Observer.Observe('record variable assign', Format(Row.Val) + ' ' + Log.Take());
        Row.TableProc(4);
        Observer.Observe('record variable call', Format(Row.Val) + ' ' + Log.Take());
        Row.RunBare(6);
        Observer.Observe('bare in table', Format(Row.Val) + ' ' + Log.Take());
        Row.RunRec(7);
        Observer.Observe('Rec. in table', Format(Row.Val) + ' ' + Log.Take());
        Observer.Finish();
    end;

    // U7: a procedure of a page, on a Page variable.
    [Test]
    procedure AssignCall_PageProcedure()
    var
        Card: Page "CU AssignCall Card";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Card.PageProc := 5;
        Observer.Observe('assign', Log.Take());
        Card.PageProc(6);
        Observer.Observe('call', Log.Take());
        Observer.Finish();
    end;

    // U8: a procedure of an interface: which implementation runs.
    [Test]
    procedure AssignCall_InterfaceProcedure()
    var
        ImplA: Codeunit "CU AssignCall Impl A";
        ImplB: Codeunit "CU AssignCall Impl B";
        IFace: Interface "CU AssignCall IFace";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        IFace := ImplA;
        IFace.IProc := 5;
        Observer.Observe('A assign', Log.Take());
        IFace := ImplB;
        IFace.IProc := 6;
        Observer.Observe('B assign', Log.Take());
        IFace.IProc(7);
        Observer.Observe('B call', Log.Take());
        Observer.Finish();
    end;

    // U9: `this.P1 := v`.
    [Test]
    procedure AssignCall_ThisQualifier()
    var
        Target: Codeunit "CU AssignCall Target";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Target.RunThis();
        Observer.Observe('assign then call', Log.Take());
        Observer.Finish();
    end;

    // U10: a local variable or a parameter named like the procedure: the variable is written, or the procedure is called?
    [Test]
    procedure AssignCall_VariableNamedLikeProcedure()
    var
        Target: Codeunit "CU AssignCall Target";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Observer.Observe('local variable', Format(Target.RunShadow()));
        Observer.Observe('local variable log', Log.Take());
        Observer.Observe('parameter', Format(Target.RunShadowParameter(4)));
        Observer.Observe('parameter log', Log.Take());
        Observer.Finish();
    end;

    local procedure Index(): Integer
    begin
        Log.Add('receiver');
        exit(2);
    end;

    local procedure NextValue(): Integer
    begin
        Log.Add('right side');
        exit(4);
    end;

    // U11: the order of the receiver, the right side and the call, and how often the right side is evaluated.
    [Test]
    procedure AssignCall_EvaluationOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Targets[Index()].P1 := NextValue();
        Observer.Observe('assign', Log.Take());
        Targets[Index()].P1(NextValue());
        Observer.Observe('call', Log.Take());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure ShortAssign(Value: Text)
    var
        Target: Codeunit "CU AssignCall Target";
    begin
        Target.SetShort := Value;
    end;

    [TryFunction]
    local procedure ShortCall(Value: Text)
    var
        Target: Codeunit "CU AssignCall Target";
    begin
        Target.SetShort(Value);
    end;

    [TryFunction]
    local procedure DecimalAssign(Value: Decimal)
    var
        Target: Codeunit "CU AssignCall Target";
    begin
        Target.P1 := Value;
    end;

    [TryFunction]
    local procedure DecimalCall(Value: Decimal)
    var
        Target: Codeunit "CU AssignCall Target";
    begin
        Target.P1(Value);
    end;

    // U12: the right side is converted as an argument: a text longer than the Text[5] parameter.
    [Test]
    procedure AssignCall_ArgumentConversion_TextTooLong()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Log.Take();
        Ok := ShortAssign('abcde');
        Observer.Observe('fits assign', Outcome(Ok) + ' ' + Log.Take());
        Ok := ShortAssign('longer than five');
        Observer.Observe('too long assign', Outcome(Ok) + ' ' + Log.Take());
        Ok := ShortCall('longer than five');
        Observer.Observe('too long call', Outcome(Ok) + ' ' + Log.Take());
        Observer.Finish();
    end;

    // U12: a Decimal for an Integer parameter, and a lower-case text for a Code parameter.
    [Test]
    procedure AssignCall_ArgumentConversion_DecimalAndCode()
    var
        Target: Codeunit "CU AssignCall Target";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Log.Take();
        Ok := DecimalAssign(3);
        Observer.Observe('whole decimal assign', Outcome(Ok) + ' ' + Log.Take());
        Ok := DecimalAssign(1.5);
        Observer.Observe('1.5 assign', Outcome(Ok) + ' ' + Log.Take());
        Ok := DecimalCall(1.5);
        Observer.Observe('1.5 call', Outcome(Ok) + ' ' + Log.Take());
        Ok := DecimalAssign(2.5);
        Observer.Observe('2.5 assign', Outcome(Ok) + ' ' + Log.Take());
        Ok := DecimalCall(2.5);
        Observer.Observe('2.5 call', Outcome(Ok) + ' ' + Log.Take());
        Target.SetCode := 'abc';
        Observer.Observe('code assign', Log.Take());
        Target.SetCode('abc');
        Observer.Observe('code call', Log.Take());
        Observer.Finish();
    end;

    // U13: a Record passed by value and by `var`.
    [Test]
    procedure AssignCall_RecordParameter()
    var
        Target: Codeunit "CU AssignCall Target";
        Row: Record "CU AssignCall Row";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Row.Id := 3;
        Row.Val := 1;
        Target.SetRec := Row;
        Observer.Observe('by value assign', Format(Row.Val) + ' ' + Log.Take());
        Target.SetRec(Row);
        Observer.Observe('by value call', Format(Row.Val) + ' ' + Log.Take());
        Target.SetRecVar := Row;
        Observer.Observe('var assign', Format(Row.Val) + ' ' + Log.Take());
        Row.Val := 2;
        Target.SetRecVar(Row);
        Observer.Observe('var call', Format(Row.Val) + ' ' + Log.Take());
        Observer.Finish();
    end;

    // U14: the assignment to the procedure's own name inside the procedure.
    [Test]
    procedure AssignCall_OwnNameInsideProcedure()
    var
        Target: Codeunit "CU AssignCall Target";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Observer.Observe('result', Format(Target.CountDown(3)));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    // U15: a procedure of a part's page, from the host page: `CurrPage.Sub.PAGE.SetX := 5`.
    [Test]
    procedure AssignCall_PartPageProcedure()
    var
        Row: Record "CU AssignCall Row";
        Host: TestPage "CU AssignCall Host";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Take();
        Host.OpenView();
        Host.AssignForm.Invoke();
        Observer.Observe('assign', Log.Take());
        Host.CallForm.Invoke();
        Observer.Observe('call', Log.Take());
        Host.Close();
        Observer.Finish();
    end;
}
