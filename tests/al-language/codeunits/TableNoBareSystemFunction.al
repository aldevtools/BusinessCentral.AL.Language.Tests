// HEADER-PLACEHOLDER

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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [MessageHandler]
    procedure CollectMessage(Msg: Text[1024])
    begin
        Messages += Msg + ';';
    end;
}

// A test codeunit with TableNo: BC compiles it. Its test procedures have no record at all.
codeunit 83006 "TNBSF TableNo Tests"
{
    Subtype = Test;
    TableNo = "TNBSF Table";

    var
        Messages: Text;

    local procedure Classify(Got: Text; Sys: Text): Text
    begin
        if Got = Sys then
            exit('system function');
        exit('other value');
    end;

    [Test]
    [HandlerFunctions('CollectMessage')]
    procedure TestProcedure_BareNames_Source()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "TNBSF Plain";
    begin
        Messages := '';
        Observer.Observe('UserId', Classify(Format(UserId), Plain.SysUserId()));
        Observer.Observe('QuotedUserId', Classify(Format("UserId"), Plain.SysUserId()));
        Observer.Observe('Today', Classify(Format(Today, 0, 9), Plain.SysToday()));
        Observer.Observe('WorkDate', Classify(Format(WorkDate, 0, 9), Plain.SysWorkDate()));
        Observer.Observe('CompanyName', Classify(Format(CompanyName), Plain.SysCompanyName()));
        Message('TNBSF Test');
        Observer.Observe('messages', Messages);
        Observer.Finish();
    end;

    [MessageHandler]
    procedure CollectMessage(Msg: Text[1024])
    begin
        Messages += Msg + ';';
    end;
}
