// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-control-statements
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 72784 and 72785, test codeunit 72786
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: a name that is a record member and also a member of the enclosing codeunit may be refused as ambiguous (compile error) or may bind silently; this file is separate so only it drops.
// Facts: inside "with Rec do", which declaration an unqualified name binds to when a codeunit global variable, a codeunit local variable, a codeunit procedure or a built-in record method has the same name as a field or table procedure.
table 72784 "LT WithAmb Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure Describe(): Text
    begin
        exit('row-describe');
    end;

    procedure Twice(Value: Integer): Integer
    begin
        exit(Value * 2);
    end;
}

table 72785 "LT WithAmb Other"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Integer) { }
        field(3; Qty; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72786 "LT WithAmb"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Name: Text[30];
        Total: Integer;

    local procedure Describe(): Text
    begin
        exit('codeunit-describe');
    end;

    local procedure Twice(Value: Integer): Integer
    begin
        exit(Value * 100);
    end;

    local procedure Count(): Integer
    begin
        exit(-1);
    end;

    [Test]
    procedure P195_With_GlobalVariableSameNameAsField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WithAmb Row";
    begin
        Row.DeleteAll();
        Name := 'global-name';
        Row.Name := 'field-name';
        with Row do begin
            Observer.Observe('inside-read', Name);
            Name := 'written-inside';
        end;
        Observer.Observe('row-field-after', Row.Name);
        Observer.Observe('global-after', Name);
        Observer.Observe('outside-read', Name);
        Observer.Expect('inside-read', 'field-name');
        Observer.Expect('row-field-after', 'written-inside');
        Observer.Expect('global-after', 'global-name');
        Observer.Expect('outside-read', 'global-name');
        Observer.Verify();
    end;

    [Test]
    procedure P195_With_LocalVariableSameNameAsField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WithAmb Row";
        Qty: Integer;
    begin
        Row.DeleteAll();
        Qty := 5;
        Row.Qty := 9;
        with Row do begin
            Observer.Observe('inside-read', Format(Qty));
            Qty := Qty + 1;
        end;
        Observer.Observe('local-after', Format(Qty));
        Observer.Observe('field-after', Format(Row.Qty));
        Observer.Expect('inside-read', '9');
        Observer.Expect('local-after', '5');
        Observer.Expect('field-after', '10');
        Observer.Verify();
    end;

    [Test]
    procedure P195_With_ProcedureSameNameAsTableProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WithAmb Row";
    begin
        Observer.Observe('outside', Describe());
        with Row do begin
            Observer.Observe('inside-describe', Describe());
            Observer.Observe('inside-twice', Format(Twice(3)));
        end;
        Observer.Observe('qualified-row', Row.Describe());
        Observer.Observe('outside-twice', Format(Twice(3)));
        Observer.Expect('outside', 'codeunit-describe');
        Observer.Expect('inside-describe', 'row-describe');
        Observer.Expect('inside-twice', '6');
        Observer.Expect('qualified-row', 'row-describe');
        Observer.Expect('outside-twice', '300');
        Observer.Verify();
    end;

    [Test]
    procedure P195_With_BuiltInMethodSameNameAsCodeunitProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WithAmb Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Observer.Observe('outside-count', Format(Count()));
        with Row do
            Observer.Observe('inside-count', Format(Count()));
        Observer.Expect('outside-count', '-1');
        Observer.Expect('inside-count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P195_NestedWith_DifferentFieldTypes_SameName()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WithAmb Row";
        Other: Record "LT WithAmb Other";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Row.Name := 'text-name';
        Other.Name := 42;
        Row.Qty := 7;
        Other.Qty := 'text-qty';
        with Row do
            with Other do begin
                Observer.Observe('name-inner-int', Format(Name));
                Observer.Observe('qty-inner-text', Format(Qty));
                Total := Name + 1;
            end;
        Observer.Observe('total-from-inner-int', Format(Total));
        with Other do
            with Row do begin
                Observer.Observe('name-inner-text', Format(Name));
                Observer.Observe('qty-inner-int', Format(Qty));
            end;
        Observer.Expect('name-inner-int', '42');
        Observer.Expect('qty-inner-text', 'text-qty');
        Observer.Expect('total-from-inner-int', '43');
        Observer.Expect('name-inner-text', 'text-name');
        Observer.Expect('qty-inner-int', '7');
        Observer.Verify();
    end;

    // corpus issue 664 (writer BN): name lookup inside `with` (microsoft/AL issues 2467, 5752, 3139; Learn: deprecating with statements).
    // The objects are tables and codeunits 82151-82155 below. Observed on BC (probe form: Observer.Finish).
    [Test]
    procedure BN_With_ParameterNamedLikeFieldInTableProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BN With Row";
    begin
        Row.Description := 'field-before';
        Observer.Observe('param|field after `with Rec do description := ...`', Row.AssignInWith('param-before'));
        Observer.Observe('field after the call', Row.Description);
        Observer.Expect('param|field after `with Rec do description := ...`', 'param-before|assigned-in-with');
        Observer.Expect('field after the call', 'assigned-in-with');
        Observer.Verify();
    end;

    [Test]
    procedure BN_With_InitInsideWith()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BN With Row";
        Other: Record "LT BN With Row";
        Helper: Codeunit "LT BN With Init";
    begin
        Row.Id := 1;
        Row.Description := 'rec';
        Other.Id := 2;
        Other.Description := 'other';
        Row.InitOtherInWith(Other);
        Observer.Observe('table: with Other do Init(); Rec', Format(Row.Id) + '|' + Row.Description);
        Observer.Observe('table: with Other do Init(); Other', Format(Other.Id) + '|' + Other.Description);
        Other.Id := 3;
        Other.Description := 'other';
        Observer.Observe('codeunit with own Init: with R do Init()', Helper.Run(Other));
        Observer.Expect('table: with Other do Init(); Rec', '1|rec');
        Observer.Expect('table: with Other do Init(); Other', '2|');
        Observer.Expect('codeunit with own Init: with R do Init()', 'own Init calls=0|3|');
        Observer.Verify();
    end;

    [Test]
    procedure BN_With_ParameterVsGlobalOfWithTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT BN With Param";
        Row: Record "LT BN With Row";
    begin
        Observer.Observe('codeunit: param MyCustomer in with MyTable (table global MyCustomer)', Helper.Param('param-value'));
        Observer.Observe('table: param MyCustomer shadows own global MyCustomer', Row.ParamVsGlobal('param-value'));
        Observer.Expect('codeunit: param MyCustomer in with MyTable (table global MyCustomer)', 'param-value');
        Observer.Expect('table: param MyCustomer shadows own global MyCustomer', 'param-value');
        Observer.Verify();
    end;

    [Test]
    procedure BN_With_ImplicitWithInTableNoCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BN With Row";
        Implicit: Codeunit "LT BN Implicit With";
#if BC29PLUS
        Pragma: Codeunit "LT BN Implicit Pragma";
        Bare: Codeunit "LT BN Implicit IsDirty";
#endif
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Description := 'stored';
        Row.Insert();
        Implicit.Run(Row);
        Observer.Observe('bare field assignment in OnRun', Implicit.Trace());
        Observer.Observe('record after Run', Row.Description);
#if BC29PLUS
        Row.Get(1);
        Pragma.Run(Row);
        Observer.Observe('bare IsDirty() under #pragma implicitwith disable', Pragma.Trace());
        Row.Get(1);
        Bare.Run(Row);
        Observer.Observe('bare IsDirty() with implicit with', Bare.Trace());
#endif
        Observer.Expect('bare field assignment in OnRun', 'set-in-onrun');
        Observer.Expect('record after Run', 'set-in-onrun');
#if BC29PLUS
        // Record.IsDirty (runtime 18.0) wins over the codeunit's local IsDirty, also under #pragma implicitwith disable.
        Observer.Expect('bare IsDirty() under #pragma implicitwith disable', 'IsDirty()=true');
        Observer.Expect('bare IsDirty() with implicit with', 'IsDirty()=true');
#endif
        Observer.Verify();
    end;
}

// corpus issue 664 (writer BN): objects for the BN_With_* tests of codeunit 72786.
table 82151 "LT BN With Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        MyCustomer: Text;

    procedure AssignInWith(description: Text[50]): Text
    begin
        with Rec do
            description := 'assigned-in-with';
        exit(description + '|' + Rec.Description);
    end;

    procedure InitOtherInWith(var Other: Record "LT BN With Row")
    begin
        with Other do
            Init();
    end;

    procedure SetGlobal(Value: Text)
    begin
        MyCustomer := Value;
    end;

    procedure ParamVsGlobal(MyCustomer: Text): Text
    begin
        SetGlobal('table-global');
        exit(MyCustomer);
    end;
}

codeunit 82152 "LT BN With Init"
{
    var
        Calls: Integer;

    procedure Init()
    begin
        Calls += 1;
    end;

    procedure Run(var R: Record "LT BN With Row"): Text
    begin
        Calls := 0;
        with R do
            Init();
        exit('own Init calls=' + Format(Calls) + '|' + Format(R.Id) + '|' + R.Description);
    end;
}

codeunit 82153 "LT BN With Param"
{
    procedure Param(MyCustomer: Text): Text
    var
        MyTable: Record "LT BN With Row";
    begin
        MyTable.SetGlobal('table-global');
        with MyTable do
            exit(MyCustomer);
    end;
}

// TableNo codeunit: OnRun has an implicit `with Rec` (the app has no NoImplicitWith feature).
codeunit 82154 "LT BN Implicit With"
{
    TableNo = "LT BN With Row";

    var
        Log: Text;

    trigger OnRun()
    begin
        Description := 'set-in-onrun';
        Log := Rec.Description;
    end;

    procedure Trace(): Text
    begin
        exit(Log);
    end;
}

#if BC29PLUS
// Record.IsDirty exists from runtime 18.0. On BC 27 and 28 the bare IsDirty() below does not compile (AL0666) although the codeunit
// declares its own IsDirty: tests/must-not-compile/cases/1407.
codeunit 82155 "LT BN Implicit Pragma"
{
    TableNo = "LT BN With Row";

    var
        Log: Text;

#pragma implicitwith disable
    trigger OnRun()
    begin
        Rec.Description := 'changed';
        if IsDirty() then
            Log += 'IsDirty()=true'
        else
            Log += 'IsDirty()=false';
    end;
#pragma implicitwith restore

    local procedure IsDirty(): Boolean
    begin
        Log += 'local IsDirty;';
        exit(false);
    end;

    procedure Trace(): Text
    begin
        exit(Log);
    end;
}
codeunit 82156 "LT BN Implicit IsDirty"
{
    TableNo = "LT BN With Row";

    var
        Log: Text;

    trigger OnRun()
    begin
        Rec.Description := 'changed';
        if IsDirty() then
            Log += 'IsDirty()=true'
        else
            Log += 'IsDirty()=false';
    end;

    local procedure IsDirty(): Boolean
    begin
        Log += 'local IsDirty;';
        exit(false);
    end;

    procedure Trace(): Text
    begin
        exit(Log);
    end;
}
#endif
