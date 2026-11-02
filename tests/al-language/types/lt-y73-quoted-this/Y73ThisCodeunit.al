// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunits 93900-93903 and 93912 (publisher, subject, log, tests)
// Probe: observe probe (writer Y73, 2026-11-02); every literal asserted below is what the BC service tier produced.
// Facts: a variable (global, local, parameter, var parameter, return value) named "this" in quotes next to the `this` keyword (unquoted this is always the keyword,
//   whatever a variable is called). In a codeunit with a global "this": Codeunit of its own type: member calls, BindSubscription / UnbindSubscription, by value and
//   var parameters, exit, assignment both ways, Clear, and a parameter / local / return value that shadows the global. Each instance has its own Tag so the answers
//   say which instance ran.
// BC versions: 27, 28, 29

codeunit 93900 "LT Y73 Pub"
{
    procedure Fire(): Text
    var
        Seen: Text;
    begin
        OnProbe(Seen);
        exit(Seen);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProbe(var Seen: Text)
    begin
    end;
}

codeunit 93901 "LT Y73 Subject"
{
    EventSubscriberInstance = Manual;

    var
        "this": Codeunit "LT Y73 Subject";
        Tag: Text;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    procedure GetTag(): Text
    begin
        exit(Tag);
    end;

    procedure MemberCalls(): Text
    begin
        Tag := 'S';
        "this".SetTag('V');
        exit(Tag + '|' + "this".GetTag() + '|' + this.GetTag());
    end;

    procedure KeywordCalls(): Text
    begin
        Tag := 'S';
        this.SetTag('K');
        exit(Tag + '|' + "this".GetTag() + '|' + this.GetTag());
    end;

    procedure BindQuoted(): Text
    var
        Pub: Codeunit "LT Y73 Pub";
        Bound: Text;
    begin
        Tag := 'S';
        "this".SetTag('V');
        BindSubscription("this");
        Bound := Pub.Fire();
        UnbindSubscription("this");
        exit(Bound + '|after=' + Pub.Fire());
    end;

    procedure BindKeyword(): Text
    var
        Pub: Codeunit "LT Y73 Pub";
        Bound: Text;
    begin
        Tag := 'S';
        "this".SetTag('V');
        BindSubscription(this);
        Bound := Pub.Fire();
        UnbindSubscription(this);
        exit(Bound + '|after=' + Pub.Fire());
    end;

    procedure BindBothUnbindQuoted(): Text
    var
        Pub: Codeunit "LT Y73 Pub";
        Both: Text;
        Rest: Text;
    begin
        Tag := 'S';
        "this".SetTag('V');
        BindSubscription(this);
        BindSubscription("this");
        Both := Pub.Fire();
        UnbindSubscription("this");
        Rest := Pub.Fire();
        UnbindSubscription(this);
        exit(Both + '|afterQuoted=' + Rest + '|afterBoth=' + Pub.Fire());
    end;

    procedure BindBothUnbindKeyword(): Text
    var
        Pub: Codeunit "LT Y73 Pub";
        Rest: Text;
    begin
        Tag := 'S';
        "this".SetTag('V');
        BindSubscription(this);
        BindSubscription("this");
        UnbindSubscription(this);
        Rest := Pub.Fire();
        UnbindSubscription("this");
        exit('afterKeyword=' + Rest + '|afterBoth=' + Pub.Fire());
    end;

    procedure ByValue(): Text
    begin
        Tag := 'S';
        "this".SetTag('V');
        TakeByValue("this");
        exit(Tag + '|' + "this".GetTag());
    end;

    procedure ByValueKeyword(): Text
    begin
        Tag := 'S';
        "this".SetTag('V');
        TakeByValue(this);
        exit(Tag + '|' + "this".GetTag());
    end;

    procedure ByVar(): Text
    begin
        Tag := 'S';
        "this".SetTag('V');
        TakeByVar("this");
        exit(Tag + '|' + "this".GetTag());
    end;

    local procedure TakeByValue(Other: Codeunit "LT Y73 Subject")
    begin
        Other.SetTag('P');
    end;

    local procedure TakeByVar(var Other: Codeunit "LT Y73 Subject")
    begin
        Other.SetTag('P');
    end;

    procedure ExitQuoted(): Text
    var
        Got: Codeunit "LT Y73 Subject";
    begin
        Tag := 'S';
        "this".SetTag('V');
        Got := ReturnQuoted();
        Got.SetTag('R');
        exit(Tag + '|' + "this".GetTag() + '|' + Got.GetTag());
    end;

    procedure ExitKeyword(): Text
    var
        Got: Codeunit "LT Y73 Subject";
    begin
        Tag := 'S';
        "this".SetTag('V');
        Got := ReturnKeyword();
        Got.SetTag('R');
        exit(Tag + '|' + "this".GetTag() + '|' + Got.GetTag());
    end;

    local procedure ReturnQuoted(): Codeunit "LT Y73 Subject"
    begin
        exit("this");
    end;

    local procedure ReturnKeyword(): Codeunit "LT Y73 Subject"
    begin
        exit(this);
    end;

    procedure AssignFromQuoted(): Text
    var
        Other: Codeunit "LT Y73 Subject";
    begin
        Tag := 'S';
        "this".SetTag('V');
        Other := "this";
        Other.SetTag('O');
        exit(Tag + '|' + "this".GetTag() + '|' + Other.GetTag());
    end;

    procedure AssignToQuoted(): Text
    var
        Other: Codeunit "LT Y73 Subject";
    begin
        Tag := 'S';
        "this".SetTag('V');
        Other.SetTag('O');
        "this" := Other;
        "this".SetTag('W');
        exit(Tag + '|' + "this".GetTag() + '|' + Other.GetTag());
    end;

    procedure AssignKeywordToQuoted(): Text
    begin
        Tag := 'S';
        "this".SetTag('V');
        "this" := this;
        "this".SetTag('W');
        exit(Tag + '|' + "this".GetTag());
    end;

    procedure ClearQuoted(): Text
    var
        Before: Text;
    begin
        Tag := 'S';
        "this".SetTag('V');
        Before := "this".GetTag();
        Clear("this");
        exit(Before + '|' + Tag + '|' + "this".GetTag());
    end;

    procedure ParameterShadows("this": Codeunit "LT Y73 Subject"): Text
    begin
        Tag := 'S';
        "this".SetTag('PAR');
        exit(Tag + '|' + "this".GetTag() + '|' + this.GetTag());
    end;

    procedure VarParameterShadows(var "this": Codeunit "LT Y73 Subject"): Text
    begin
        Tag := 'S';
        "this".SetTag('VPAR');
        exit(Tag + '|' + "this".GetTag() + '|' + this.GetTag());
    end;

    procedure LocalShadows(): Text
    var
        "this": Codeunit "LT Y73 Subject";
    begin
        Tag := 'S';
        "this".SetTag('LOC');
        exit(Tag + '|' + "this".GetTag() + '|' + this.GetTag());
    end;

    procedure ReturnValueNamed() "this": Codeunit "LT Y73 Subject"
    begin
        Tag := 'S';
        "this".SetTag('RET');
    end;

    procedure GlobalOnlyAfterReturnNamed(): Text
    var
        Got: Codeunit "LT Y73 Subject";
    begin
        Got := ReturnValueNamed();
        exit(Tag + '|' + Got.GetTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT Y73 Pub", OnProbe, '', false, false)]
    local procedure OnProbeSub(var Seen: Text)
    begin
        Seen += '[' + Tag + ']';
    end;
}

codeunit 93902 "LT Y73 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 93912 "LT Y73 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Codeunit_MemberCalls()
    var
        Observer: Codeunit "Probe Observer";
        Subject: Codeunit "LT Y73 Subject";
    begin
        Observer.Observe('member_quoted', Subject.MemberCalls());
        Clear(Subject);
        Observer.Observe('member_keyword', Subject.KeywordCalls());
        Observer.Finish();
    end;

    [Test]
    procedure Codeunit_BindSubscription()
    var
        Observer: Codeunit "Probe Observer";
        Subject: Codeunit "LT Y73 Subject";
    begin
        Observer.Observe('bind_quoted', Subject.BindQuoted());
        Clear(Subject);
        Observer.Observe('bind_keyword', Subject.BindKeyword());
        Clear(Subject);
        Observer.Observe('bind_both_unbind_quoted', Subject.BindBothUnbindQuoted());
        Clear(Subject);
        Observer.Observe('bind_both_unbind_keyword', Subject.BindBothUnbindKeyword());
        Observer.Finish();
    end;

    [Test]
    procedure Codeunit_Parameters_Exit_Assignment_Clear()
    var
        Observer: Codeunit "Probe Observer";
        Subject: Codeunit "LT Y73 Subject";
    begin
        Observer.Observe('byvalue_quoted', Subject.ByValue());
        Clear(Subject);
        Observer.Observe('byvalue_keyword', Subject.ByValueKeyword());
        Clear(Subject);
        Observer.Observe('byvar_quoted', Subject.ByVar());
        Clear(Subject);
        Observer.Observe('exit_quoted', Subject.ExitQuoted());
        Clear(Subject);
        Observer.Observe('exit_keyword', Subject.ExitKeyword());
        Clear(Subject);
        Observer.Observe('assign_from_quoted', Subject.AssignFromQuoted());
        Clear(Subject);
        Observer.Observe('assign_to_quoted', Subject.AssignToQuoted());
        Clear(Subject);
        Observer.Observe('assign_keyword_to_quoted', Subject.AssignKeywordToQuoted());
        Clear(Subject);
        Observer.Observe('clear_quoted', Subject.ClearQuoted());
        Observer.Finish();
    end;

    [Test]
    procedure Codeunit_Shadowing()
    var
        Observer: Codeunit "Probe Observer";
        Subject: Codeunit "LT Y73 Subject";
        Passed: Codeunit "LT Y73 Subject";
        PassedVar: Codeunit "LT Y73 Subject";
    begin
        Observer.Observe('parameter', Subject.ParameterShadows(Passed) + '|passed=' + Passed.GetTag());
        Clear(Subject);
        Observer.Observe('var_parameter', Subject.VarParameterShadows(PassedVar) + '|passed=' + PassedVar.GetTag());
        Clear(Subject);
        Observer.Observe('local', Subject.LocalShadows());
        Clear(Subject);
        Observer.Observe('return_value', Subject.GlobalOnlyAfterReturnNamed());
        Observer.Finish();
    end;
}
