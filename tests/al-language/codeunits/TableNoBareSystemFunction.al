// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tableno-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Probe Observer (codeunit 69160); own objects 83000 to 83005
// BC versions: 27.5+
// Probe (al-runner 7999, assumption tableno-procedure-bare-system-function): a codeunit with TableNo whose table has fields named
// UserId, Today, WorkDate, CompanyName and Message (BC accepts all five field names). Each read is compared with the field of the record
// given to Codeunit.Run, with the field of a second record (a parameter or a global variable named Rec) and with the system function read
// in a codeunit without TableNo (codeunit 83001); only that relation is asserted, never the user name, company or date.
// What BC did:
// - OnRun: the bare names UserId, Today, WorkDate, CompanyName, Message and the quoted name "UserId" read the field of the run record
//   (the compiler warns AL0604, implicit with). With parentheses (UserId(), Today(), WorkDate(), CompanyName()) they call the system function.
//   Message('...') with arguments calls the system function (the MessageHandler gets the text) although a field is named Message.
// - A global, local or internal procedure, a procedure with a parameter named Rec of the same table, and an event subscriber of the same
//   codeunit: the bare names call the system function (no AL0604; a procedure has no implicit Rec, must-not-compile 3140), the parameter
//   named Rec is not used for them, and bare Message('...') shows the message. The quoted names "UserId", "Today", "WorkDate",
//   "CompanyName" in a procedure also call the system function.
// - A TableNo codeunit that also declares a global variable Rec (BC compiles it): in OnRun the bare and quoted names read the run record,
//   and Rec.UserId also reads the run record (the implicit Rec hides the global one in OnRun). In a procedure the bare and quoted names
//   call the system function and Rec.UserId reads the global variable.
// Compiles but not run here: a test codeunit with TableNo (its bare UserId has no AL0604, so it is the system function) was dropped,
// because Microsoft's test runner session died running it on BC 28.5 ("hub connection closed" twice); an Install codeunit with TableNo
// and OnInstallAppPerCompany reading bare UserId compiles without AL0604, but the corpus gate rejects install codeunits; a TestRunner
// trigger (OnBeforeTestRun) reading bare UserId compiles without AL0604. Compile facts checked with AL 17 and 18.
// Values measured on BC 28.5 (local Windows container); 27.5 and 29.0: see the corpus CI run of the pull request.
// local object: the table must have fields with the names of system functions and every codeunit below is a shape of the question
// (TableNo subject, event publisher, codeunit without TableNo for the system values, TableNo codeunit with a global Rec).

table 83000 "TNBSF Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; UserId; Code[50]) { }
        field(3; Today; Date) { }
        field(4; WorkDate; Date) { }
        field(5; CompanyName; Text[30]) { }
        field(6; Message; Text[100]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// The system functions, read where no record field can be meant (no TableNo).
codeunit 83001 "TNBSF Plain"
{
    procedure SysUserId(): Text
    begin
        exit(Format(UserId()));
    end;

    procedure SysToday(): Text
    begin
        exit(Format(Today(), 0, 9));
    end;

    procedure SysWorkDate(): Text
    begin
        exit(Format(WorkDate(), 0, 9));
    end;

    procedure SysCompanyName(): Text
    begin
        exit(Format(CompanyName()));
    end;
}

codeunit 83002 "TNBSF Publisher"
{
    procedure Raise(var Res: Dictionary of [Text, Text])
    begin
        OnReadNames(Res);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReadNames(var Res: Dictionary of [Text, Text])
    begin
    end;
}

// The subject: a TableNo codeunit whose table has fields named UserId, Today, WorkDate, CompanyName and Message.
// OnRun reads the names itself and calls procedures of every kind that read the same names bare.
codeunit 83003 "TNBSF Subject"
{
    TableNo = "TNBSF Table";

    trigger OnRun()
    begin
        Results.Add('OnRun.UserId', Format(UserId));
        Results.Add('OnRun.UserIdParens', Format(UserId()));
        Results.Add('OnRun.QuotedUserId', Format("UserId"));
        Results.Add('OnRun.Today', Format(Today, 0, 9));
        Results.Add('OnRun.TodayParens', Format(Today(), 0, 9));
        Results.Add('OnRun.WorkDate', Format(WorkDate, 0, 9));
        Results.Add('OnRun.WorkDateParens', Format(WorkDate(), 0, 9));
        Results.Add('OnRun.CompanyName', Format(CompanyName));
        Results.Add('OnRun.CompanyNameParens', Format(CompanyName()));
        Results.Add('OnRun.MessageRead', Format(Message));
        Message('TNBSF OnRun');
        GlobalRead(Results);
        LocalRead(Results);
        InternalRead(Results);
        ParamRecRead(ParamRec, Results);
        QuotedRead(Results);
    end;

    var
        Results: Dictionary of [Text, Text];
        ParamRec: Record "TNBSF Table";

    procedure SetParamRec(NewParamRec: Record "TNBSF Table")
    begin
        ParamRec := NewParamRec;
    end;

    procedure GetResults(): Dictionary of [Text, Text]
    begin
        exit(Results);
    end;

    procedure GlobalRead(var Res: Dictionary of [Text, Text])
    begin
        Res.Add('Global.UserId', Format(UserId));
        Res.Add('Global.UserIdParens', Format(UserId()));
        Res.Add('Global.Today', Format(Today, 0, 9));
        Res.Add('Global.WorkDate', Format(WorkDate, 0, 9));
        Res.Add('Global.CompanyName', Format(CompanyName));
        Message('TNBSF Global');
    end;

    local procedure LocalRead(var Res: Dictionary of [Text, Text])
    begin
        Res.Add('Local.UserId', Format(UserId));
        Res.Add('Local.UserIdParens', Format(UserId()));
        Res.Add('Local.Today', Format(Today, 0, 9));
        Res.Add('Local.WorkDate', Format(WorkDate, 0, 9));
        Res.Add('Local.CompanyName', Format(CompanyName));
        Message('TNBSF Local');
    end;

    internal procedure InternalRead(var Res: Dictionary of [Text, Text])
    begin
        Res.Add('Internal.UserId', Format(UserId));
        Res.Add('Internal.UserIdParens', Format(UserId()));
        Res.Add('Internal.Today', Format(Today, 0, 9));
        Res.Add('Internal.WorkDate', Format(WorkDate, 0, 9));
        Res.Add('Internal.CompanyName', Format(CompanyName));
        Message('TNBSF Internal');
    end;

    // A parameter named Rec of the same table, with other field values than the OnRun record.
    procedure ParamRecRead(Rec: Record "TNBSF Table"; var Res: Dictionary of [Text, Text])
    begin
        Res.Add('ParamRec.UserId', Format(UserId));
        Res.Add('ParamRec.UserIdParens', Format(UserId()));
        Res.Add('ParamRec.Today', Format(Today, 0, 9));
        Res.Add('ParamRec.WorkDate', Format(WorkDate, 0, 9));
        Res.Add('ParamRec.CompanyName', Format(CompanyName));
        Message('TNBSF ParamRec');
    end;

    // The quoted names in a procedure.
    procedure QuotedRead(var Res: Dictionary of [Text, Text])
    begin
        Res.Add('Quoted.UserId', Format("UserId"));
        Res.Add('Quoted.Today', Format("Today", 0, 9));
        Res.Add('Quoted.WorkDate', Format("WorkDate", 0, 9));
        Res.Add('Quoted.CompanyName', Format("CompanyName"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TNBSF Publisher", 'OnReadNames', '', false, false)]
    local procedure HandleReadNames(var Res: Dictionary of [Text, Text])
    begin
        Res.Add('Subscriber.UserId', Format(UserId));
        Res.Add('Subscriber.UserIdParens', Format(UserId()));
        Res.Add('Subscriber.Today', Format(Today, 0, 9));
        Res.Add('Subscriber.WorkDate', Format(WorkDate, 0, 9));
        Res.Add('Subscriber.CompanyName', Format(CompanyName));
        Message('TNBSF Subscriber');
    end;
}

// A TableNo codeunit that also declares a global variable named Rec.
codeunit 83004 "TNBSF Global Rec"
{
    TableNo = "TNBSF Table";

    trigger OnRun()
    begin
        Results.Add('OnRun.UserId', Format(UserId));
        Results.Add('OnRun.QuotedUserId', Format("UserId"));
        Results.Add('OnRun.UserIdParens', Format(UserId()));
        Results.Add('OnRun.Today', Format(Today, 0, 9));
        Results.Add('OnRun.RecUserId', Format(Rec.UserId));
        ProcRead(Results);
    end;

    var
        Rec: Record "TNBSF Table";
        Results: Dictionary of [Text, Text];

    procedure SetGlobalRec(NewRec: Record "TNBSF Table")
    begin
        Rec := NewRec;
    end;

    procedure GetResults(): Dictionary of [Text, Text]
    begin
        exit(Results);
    end;

    procedure ProcRead(var Res: Dictionary of [Text, Text])
    begin
        Res.Add('Proc.UserId', Format(UserId));
        Res.Add('Proc.QuotedUserId', Format("UserId"));
        Res.Add('Proc.Today', Format(Today, 0, 9));
        Res.Add('Proc.RecUserId', Format(Rec.UserId));
    end;
}

codeunit 83005 "TNBSF Tests"
{
    Subtype = Test;

    var
        Messages: Text;

    local procedure MakeRec(var R: Record "TNBSF Table"; Tag: Text; Year: Integer)
    begin
        R.Init();
        R."Entry No." := Year;
        R.UserId := CopyStr('TNBSF-' + Tag + '-USER', 1, 50);
        R.Today := DMY2Date(1, 1, Year);
        R.WorkDate := DMY2Date(2, 2, Year);
        R.CompanyName := CopyStr('TNBSF ' + Tag + ' Co', 1, 30);
        R.Message := CopyStr('TNBSF ' + Tag + ' Msg', 1, 100);
    end;

    local procedure FieldText(R: Record "TNBSF Table"; Name: Text): Text
    begin
        case Name of
            'UserId', 'UserIdParens', 'QuotedUserId', 'RecUserId':
                exit(Format(R.UserId));
            'Today', 'TodayParens':
                exit(Format(R.Today, 0, 9));
            'WorkDate', 'WorkDateParens':
                exit(Format(R.WorkDate, 0, 9));
            'CompanyName', 'CompanyNameParens':
                exit(Format(R.CompanyName));
            'MessageRead':
                exit(Format(R.Message));
        end;
        exit('<no field>');
    end;

    local procedure SysText(Name: Text): Text
    var
        Plain: Codeunit "TNBSF Plain";
    begin
        case Name of
            'UserId', 'UserIdParens', 'QuotedUserId', 'RecUserId':
                exit(Plain.SysUserId());
            'Today', 'TodayParens':
                exit(Plain.SysToday());
            'WorkDate', 'WorkDateParens':
                exit(Plain.SysWorkDate());
            'CompanyName', 'CompanyNameParens':
                exit(Plain.SysCompanyName());
        end;
        exit('<no system function>');
    end;

    // Which source a read gave: the OnRun record's field, the other record's field, or the system function.
    local procedure Classify(Got: Text; Name: Text; RunRec: Record "TNBSF Table"; OtherRec: Record "TNBSF Table"; OtherLabel: Text): Text
    begin
        if Got = FieldText(RunRec, Name) then
            exit('run record field');
        if Got = FieldText(OtherRec, Name) then
            exit(OtherLabel + ' field');
        if Got = SysText(Name) then
            exit('system function');
        exit('other value');
    end;

    local procedure ObserveGroup(var Observer: Codeunit "Probe Observer"; Res: Dictionary of [Text, Text]; Prefix: Text; RunRec: Record "TNBSF Table"; OtherRec: Record "TNBSF Table"; OtherLabel: Text)
    var
        K: Text;
        Name: Text;
    begin
        foreach K in Res.Keys() do
            if K.StartsWith(Prefix + '.') then begin
                Name := CopyStr(K, StrLen(Prefix) + 2);
                Observer.Observe(K, Classify(Res.Get(K), Name, RunRec, OtherRec, OtherLabel));
            end;
    end;

    local procedure RunSubject(var RunRec: Record "TNBSF Table"; var OtherRec: Record "TNBSF Table"): Dictionary of [Text, Text]
    var
        Subject: Codeunit "TNBSF Subject";
    begin
        MakeRec(RunRec, 'RUN', 2001);
        MakeRec(OtherRec, 'PARAM', 2002);
        Messages := '';
        Subject.SetParamRec(OtherRec);
        Subject.Run(RunRec);
        exit(Subject.GetResults());
    end;

    [Test]
    [HandlerFunctions('CollectMessage')]
    procedure OnRun_BareAndParensNames_Source()
    var
        Observer: Codeunit "Probe Observer";
        RunRec: Record "TNBSF Table";
        OtherRec: Record "TNBSF Table";
    begin
        ObserveGroup(Observer, RunSubject(RunRec, OtherRec), 'OnRun', RunRec, OtherRec, 'parameter Rec');
        Observer.Expect('OnRun.UserId', 'run record field');
        Observer.Expect('OnRun.UserIdParens', 'system function');
        Observer.Expect('OnRun.QuotedUserId', 'run record field');
        Observer.Expect('OnRun.Today', 'run record field');
        Observer.Expect('OnRun.TodayParens', 'system function');
        Observer.Expect('OnRun.WorkDate', 'run record field');
        Observer.Expect('OnRun.WorkDateParens', 'system function');
        Observer.Expect('OnRun.CompanyName', 'run record field');
        Observer.Expect('OnRun.CompanyNameParens', 'system function');
        Observer.Expect('OnRun.MessageRead', 'run record field');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CollectMessage')]
    procedure GlobalProcedure_BareNames_Source()
    var
        Observer: Codeunit "Probe Observer";
        RunRec: Record "TNBSF Table";
        OtherRec: Record "TNBSF Table";
    begin
        ObserveGroup(Observer, RunSubject(RunRec, OtherRec), 'Global', RunRec, OtherRec, 'parameter Rec');
        Observer.Expect('Global.UserId', 'system function');
        Observer.Expect('Global.UserIdParens', 'system function');
        Observer.Expect('Global.Today', 'system function');
        Observer.Expect('Global.WorkDate', 'system function');
        Observer.Expect('Global.CompanyName', 'system function');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CollectMessage')]
    procedure LocalProcedure_BareNames_Source()
    var
        Observer: Codeunit "Probe Observer";
        RunRec: Record "TNBSF Table";
        OtherRec: Record "TNBSF Table";
    begin
        ObserveGroup(Observer, RunSubject(RunRec, OtherRec), 'Local', RunRec, OtherRec, 'parameter Rec');
        Observer.Expect('Local.UserId', 'system function');
        Observer.Expect('Local.UserIdParens', 'system function');
        Observer.Expect('Local.Today', 'system function');
        Observer.Expect('Local.WorkDate', 'system function');
        Observer.Expect('Local.CompanyName', 'system function');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CollectMessage')]
    procedure InternalProcedure_BareNames_Source()
    var
        Observer: Codeunit "Probe Observer";
        RunRec: Record "TNBSF Table";
        OtherRec: Record "TNBSF Table";
    begin
        ObserveGroup(Observer, RunSubject(RunRec, OtherRec), 'Internal', RunRec, OtherRec, 'parameter Rec');
        Observer.Expect('Internal.UserId', 'system function');
        Observer.Expect('Internal.UserIdParens', 'system function');
        Observer.Expect('Internal.Today', 'system function');
        Observer.Expect('Internal.WorkDate', 'system function');
        Observer.Expect('Internal.CompanyName', 'system function');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CollectMessage')]
    procedure ParamRecProcedure_BareNames_Source()
    var
        Observer: Codeunit "Probe Observer";
        RunRec: Record "TNBSF Table";
        OtherRec: Record "TNBSF Table";
    begin
        ObserveGroup(Observer, RunSubject(RunRec, OtherRec), 'ParamRec', RunRec, OtherRec, 'parameter Rec');
        Observer.Expect('ParamRec.UserId', 'system function');
        Observer.Expect('ParamRec.UserIdParens', 'system function');
        Observer.Expect('ParamRec.Today', 'system function');
        Observer.Expect('ParamRec.WorkDate', 'system function');
        Observer.Expect('ParamRec.CompanyName', 'system function');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CollectMessage')]
    procedure Procedure_QuotedNames_Source()
    var
        Observer: Codeunit "Probe Observer";
        RunRec: Record "TNBSF Table";
        OtherRec: Record "TNBSF Table";
    begin
        ObserveGroup(Observer, RunSubject(RunRec, OtherRec), 'Quoted', RunRec, OtherRec, 'parameter Rec');
        Observer.Expect('Quoted.UserId', 'system function');
        Observer.Expect('Quoted.Today', 'system function');
        Observer.Expect('Quoted.WorkDate', 'system function');
        Observer.Expect('Quoted.CompanyName', 'system function');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CollectMessage')]
    procedure Message_BareCallInEveryRoutine_Raised()
    var
        Observer: Codeunit "Probe Observer";
        RunRec: Record "TNBSF Table";
        OtherRec: Record "TNBSF Table";
    begin
        RunSubject(RunRec, OtherRec);
        Observer.Observe('messages', Messages);
        Observer.Expect('messages', 'TNBSF OnRun;TNBSF Global;TNBSF Local;TNBSF Internal;TNBSF ParamRec;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CollectMessage')]
    procedure Subscriber_BareNames_Source()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "TNBSF Publisher";
        RunRec: Record "TNBSF Table";
        OtherRec: Record "TNBSF Table";
        Res: Dictionary of [Text, Text];
    begin
        MakeRec(RunRec, 'RUN', 2001);
        MakeRec(OtherRec, 'PARAM', 2002);
        Messages := '';
        Publisher.Raise(Res);
        ObserveGroup(Observer, Res, 'Subscriber', RunRec, OtherRec, 'parameter Rec');
        Observer.Observe('messages', Messages);
        Observer.Expect('Subscriber.UserId', 'system function');
        Observer.Expect('Subscriber.UserIdParens', 'system function');
        Observer.Expect('Subscriber.Today', 'system function');
        Observer.Expect('Subscriber.WorkDate', 'system function');
        Observer.Expect('Subscriber.CompanyName', 'system function');
        Observer.Expect('messages', 'TNBSF Subscriber;');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalRecVariable_BareNames_Source()
    var
        Observer: Codeunit "Probe Observer";
        Subject: Codeunit "TNBSF Global Rec";
        RunRec: Record "TNBSF Table";
        GlobalRec: Record "TNBSF Table";
    begin
        MakeRec(RunRec, 'RUN', 2001);
        MakeRec(GlobalRec, 'GLOBAL', 2003);
        Subject.SetGlobalRec(GlobalRec);
        Subject.Run(RunRec);
        ObserveGroup(Observer, Subject.GetResults(), 'OnRun', RunRec, GlobalRec, 'global Rec');
        ObserveGroup(Observer, Subject.GetResults(), 'Proc', RunRec, GlobalRec, 'global Rec');
        Observer.Expect('OnRun.UserId', 'run record field');
        Observer.Expect('OnRun.QuotedUserId', 'run record field');
        Observer.Expect('OnRun.UserIdParens', 'system function');
        Observer.Expect('OnRun.Today', 'run record field');
        Observer.Expect('OnRun.RecUserId', 'run record field');
        Observer.Expect('Proc.UserId', 'system function');
        Observer.Expect('Proc.QuotedUserId', 'system function');
        Observer.Expect('Proc.Today', 'system function');
        Observer.Expect('Proc.RecUserId', 'global Rec field');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure CollectMessage(Msg: Text[1024])
    begin
        Messages += Msg + ';';
    end;
}
