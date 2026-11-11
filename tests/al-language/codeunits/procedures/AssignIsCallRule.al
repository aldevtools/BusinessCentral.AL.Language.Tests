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
// U16 and U17 (al-runner 7714, reporter's shape): `currXMLport.Filename := 'probe.txt'` in OnPreXmlPort of an export that is given an
// OutStream, next to the call form and to an xmlport that does not touch Filename: what Filename() reads before and after, in OnPostXmlPort,
// and whether the exported text is the same; and the same assignment on an XmlPort variable before SetDestination and Export.
// Values measured on BC 27.5, 28.5 and 29.0 (corpus CI runs 42876663156, 42876712578, 42876759234; identical on all three unless a test
// says otherwise). Measured: the assignment form runs the procedure exactly as the call form does in every cell: same log line, same
// value written back to a `var` parameter (Integer and Record), same TryFunction result and error, same subscriber call, same
// implementation of an interface, same order (receiver, right side, call), same conversion errors (StringLengthExceeded, ConversionCast).
// A local variable or a parameter with the name of the procedure takes the assignment: the procedure does not run.
// U15 to U17 (page part procedure, xmlport Filename): measured on BC 27.5, 28.5 and 29.0, identical on all three (corpus CI runs 42882150245, 42882195650, 42882238278).
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
    ApplicationArea = All;
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
    ApplicationArea = All;
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

xmlport 96404 "CU AssignCall Xp Plain"
{
    Direction = Export;
    Format = VariableText;
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "CU AssignCall Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Val; Row.Val) { }
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        Log.Add('pre: ' + currXMLport.Filename());
    end;

    trigger OnPostXmlPort()
    begin
        Log.Add('post: ' + currXMLport.Filename());
    end;

    var
        Log: Codeunit "CU AssignCall Log";
}

xmlport 96406 "CU AssignCall Xp Assign"
{
    Direction = Export;
    Format = VariableText;
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "CU AssignCall Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Val; Row.Val) { }
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        Log.Add('pre: ' + currXMLport.Filename());
        currXMLport.Filename := 'probe.txt';
        Log.Add('pre, after assign: ' + currXMLport.Filename());
    end;

    trigger OnPostXmlPort()
    begin
        Log.Add('post: ' + currXMLport.Filename());
    end;

    var
        Log: Codeunit "CU AssignCall Log";
}

xmlport 96412 "CU AssignCall Xp Call"
{
    Direction = Export;
    Format = VariableText;
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "CU AssignCall Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Val; Row.Val) { }
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        Log.Add('pre: ' + currXMLport.Filename());
        currXMLport.Filename('probe.txt');
        Log.Add('pre, after call: ' + currXMLport.Filename());
    end;

    trigger OnPostXmlPort()
    begin
        Log.Add('post: ' + currXMLport.Filename());
    end;

    var
        Log: Codeunit "CU AssignCall Log";
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
        Observer.Expect('assign then call', 'PLocal(1);PLocal(2);');
        Observer.Verify();
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
        Observer.Expect('I after assign', '11');
        Observer.Expect('I after call', '21');
        Observer.Expect('log', 'Bump(1);Bump(11);');
        Observer.Verify();
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
        Observer.Expect('I after assign', '11');
        Observer.Expect('I after call', '21');
        Observer.Expect('log', 'BumpVar(1);BumpVar(11);');
        Observer.Verify();
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
        Observer.Expect('assign passes', 'ok');
        Observer.Expect('assign passes log', 'TrySet(1);after assign;');
        Observer.Expect('call passes', 'ok');
        Observer.Expect('call passes log', 'TrySet(1);after call;');
        Observer.Expect('assign raises', 'error:TrySet refuses -1|Dialog');
        Observer.Expect('assign raises log', 'TrySet(-1);');
        Observer.Expect('call raises', 'error:TrySet refuses -1|Dialog');
        Observer.Expect('call raises log', 'TrySet(-1);');
        Observer.Expect('bare assign raises', 'error:TrySet refuses -2|Dialog');
        Observer.Expect('bare assign raises log', 'TrySet(-2);');
        Observer.Verify();
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
        Observer.Expect('member assign', 'subscriber(7);');
        Observer.Expect('member call', 'subscriber(6);');
        Observer.Expect('bare assign then call', 'subscriber(8);subscriber(9);');
        Observer.Expect('unbound assign', '');
        Observer.Verify();
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
        Observer.Expect('record variable assign', '5 TableProc(5) on 1;');
        Observer.Expect('record variable call', '4 TableProc(4) on 1;');
        Observer.Expect('bare in table', '6 TableProc(6) on 1;');
        Observer.Expect('Rec. in table', '7 TableProc(7) on 1;');
        Observer.Verify();
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
        Observer.Expect('assign', 'PageProc(5);');
        Observer.Expect('call', 'PageProc(6);');
        Observer.Verify();
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
        Observer.Expect('A assign', 'A.IProc(5);');
        Observer.Expect('B assign', 'B.IProc(6);');
        Observer.Expect('B call', 'B.IProc(7);');
        Observer.Verify();
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
        Observer.Expect('assign then call', 'P1(5);P1(6);');
        Observer.Verify();
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
        Observer.Expect('local variable', '1');
        Observer.Expect('local variable log', '');
        Observer.Expect('parameter', '5');
        Observer.Expect('parameter log', '');
        Observer.Verify();
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
        Observer.Expect('assign', 'receiver;right side;P1(4);');
        Observer.Expect('call', 'receiver;right side;P1(4);');
        Observer.Verify();
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
        Observer.Expect('fits assign', 'ok SetShort(abcde);');
        Observer.Expect('too long assign', 'error:The length of the string is 16, but it must be less than or equal to 5 characters. Value: longer than five|StringLengthExceeded ');
        Observer.Expect('too long call', 'error:The length of the string is 16, but it must be less than or equal to 5 characters. Value: longer than five|StringLengthExceeded ');
        Observer.Verify();
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
        Observer.Expect('whole decimal assign', 'ok P1(3);');
        Observer.Expect('1.5 assign', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.|ConversionCast ');
        Observer.Expect('1.5 call', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.|ConversionCast ');
        Observer.Expect('2.5 assign', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|ConversionCast ');
        Observer.Expect('2.5 call', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|ConversionCast ');
        Observer.Expect('code assign', 'SetCode(ABC);');
        Observer.Expect('code call', 'SetCode(ABC);');
        Observer.Verify();
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
        Observer.Expect('by value assign', '1 SetRec(3/1);');
        Observer.Expect('by value call', '1 SetRec(3/1);');
        Observer.Expect('var assign', '77 SetRecVar(3/1);');
        Observer.Expect('var call', '77 SetRecVar(3/2);');
        Observer.Verify();
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
        Observer.Expect('result', '300');
        Observer.Expect('log', 'CountDown(3);CountDown(2);CountDown(1);CountDown(0);');
        Observer.Verify();
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
        Observer.Expect('assign', 'Part.SetX(5);');
        Observer.Expect('call', 'Part.SetX(6);');
        Observer.Verify();
    end;

    local procedure XpSeedRows()
    var
        Row: Record "CU AssignCall Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Val := 10;
        Row.Insert();
        Row.Id := 2;
        Row.Val := 20;
        Row.Insert();
    end;

    [TryFunction]
    local procedure XpTryExport(Which: Integer; var TempBlob: Codeunit "Temp Blob")
    var
        Out: OutStream;
    begin
        TempBlob.CreateOutStream(Out, TextEncoding::UTF8);
        case Which of
            1:
                Xmlport.Export(Xmlport::"CU AssignCall Xp Plain", Out);
            2:
                Xmlport.Export(Xmlport::"CU AssignCall Xp Assign", Out);
            3:
                Xmlport.Export(Xmlport::"CU AssignCall Xp Call", Out);
        end;
    end;

    local procedure XpContent(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        if not TempBlob.HasValue() then
            exit('<no data>');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        InStr.Read(Result);
        exit(Result);
    end;

    // U16 (al-runner 7714): `currXMLport.Filename := 'probe.txt'` in OnPreXmlPort of an export to an OutStream, next to the call form and
    // to an xmlport that leaves Filename alone.
    [Test]
    procedure AssignCall_XmlPortFilename_ExportToStream()
    var
        Blobs: array[3] of Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Names: array[3] of Text;
        Content: array[3] of Text;
        I: Integer;
    begin
        XpSeedRows();
        Names[1] := 'plain';
        Names[2] := 'assign';
        Names[3] := 'call';
        Log.Take();
        for I := 1 to 3 do begin
            Observer.Observe(Names[I] + ' export', Outcome(XpTryExport(I, Blobs[I])));
            Observer.Observe(Names[I] + ' log', Log.Take());
            Content[I] := XpContent(Blobs[I]);
            Observer.Observe(Names[I] + ' content', Content[I]);
        end;
        Observer.Observe('assign content equals plain', Format(Content[2] = Content[1]));
        Observer.Observe('call content equals plain', Format(Content[3] = Content[1]));
        Observer.Expect('plain export', 'ok');
        Observer.Expect('plain log', 'pre: ;post: ;');
        Observer.Expect('plain content', '"1","10"\r\n"2","20"');
        Observer.Expect('assign export', 'ok');
        Observer.Expect('assign log', 'pre: ;pre, after assign: probe.txt;post: probe.txt;');
        Observer.Expect('assign content', '"1","10"\r\n"2","20"');
        Observer.Expect('call export', 'ok');
        Observer.Expect('call log', 'pre: ;pre, after call: probe.txt;post: probe.txt;');
        Observer.Expect('call content', '"1","10"\r\n"2","20"');
        Observer.Expect('assign content equals plain', 'Yes');
        Observer.Expect('call content equals plain', 'Yes');
        Observer.Verify();
    end;

    // U17 (al-runner 7714): the assignment on an XmlPort variable, before SetDestination and Export.
    [Test]
    procedure AssignCall_XmlPortFilename_Variable()
    var
        Xp: XmlPort "CU AssignCall Xp Plain";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
    begin
        XpSeedRows();
        Log.Take();
        TempBlob.CreateOutStream(Out, TextEncoding::UTF8);
        Observer.Observe('at start', Xp.Filename());
        Xp.Filename := 'var.txt';
        Observer.Observe('after assign', Xp.Filename());
        Xp.Filename('var2.txt');
        Observer.Observe('after call', Xp.Filename());
        Xp.SetDestination(Out);
        Xp.Export();
        Observer.Observe('after Export', Xp.Filename());
        Observer.Observe('log', Log.Take());
        Observer.Observe('content', XpContent(TempBlob));
        Observer.Expect('at start', '');
        Observer.Expect('after assign', 'var.txt');
        Observer.Expect('after call', 'var2.txt');
        Observer.Expect('after Export', 'var2.txt');
        Observer.Expect('log', 'pre: var2.txt;post: var2.txt;');
        Observer.Expect('content', '"1","10"\r\n"2","20"');
        Observer.Verify();
    end;
}
