// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects table 72036, codeunit 72037
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: Builtins refused until a probe pins them: Assigning FieldRef.Value(x) on a FieldRef that was never assigned - Probe wanted: the setter Value(x) and the other members (IsEnum, Class, Active, Relation, Validate)
// Facts: error text and code (or no error) of every FieldRef member on a FieldRef never assigned; a FieldRef from the RecordRef of an empty table for comparison
// BC versions: 29 (27 and 28 by CI)

table 72036 "LT PnD Unassigned"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72037 "LT PnD Unassigned FieldRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Unassigned_ValueSetter()
    var
        Observer: Codeunit "Probe Observer";
        FldRef: FieldRef;
    begin
        asserterror FldRef.Value(5);
        Observer.ObserveError('valueSet5');
        asserterror FldRef.Value('x');
        Observer.ObserveError('valueSetText');
        asserterror FldRef.Value := 7;
        Observer.ObserveError('valueAssign');
        Observer.Expect('valueSet5|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('valueSet5|code', 'NotInitialized');
        Observer.Expect('valueSetText|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('valueSetText|code', 'NotInitialized');
        Observer.Expect('valueAssign|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('valueAssign|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_ReadMembersForReference()
    var
        Observer: Codeunit "Probe Observer";
        FldRef: FieldRef;
        Dummy: Text;
    begin
        asserterror Dummy := FldRef.Name();
        Observer.ObserveError('name');
        asserterror Dummy := Format(FldRef.Number());
        Observer.ObserveError('number');
        asserterror Dummy := Format(FldRef.Value());
        Observer.ObserveError('valueGet');
        asserterror Dummy := Format(FldRef.Type());
        Observer.ObserveError('type');
        asserterror Dummy := Format(FldRef.Length());
        Observer.ObserveError('length');
        Observer.Expect('name|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('name|code', 'NotInitialized');
        Observer.Expect('number|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('number|code', 'NotInitialized');
        Observer.Expect('valueGet|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('valueGet|code', 'NotInitialized');
        Observer.Expect('type|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('type|code', 'NotInitialized');
        Observer.Expect('length|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('length|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_OtherMembers_A()
    var
        Observer: Codeunit "Probe Observer";
        FldRef: FieldRef;
        Dummy: Text;
    begin
        asserterror Dummy := Format(FldRef.IsEnum());
        Observer.ObserveError('isEnum');
        asserterror Dummy := Format(FldRef.Class());
        Observer.ObserveError('class');
        asserterror Dummy := Format(FldRef.Active());
        Observer.ObserveError('active');
        asserterror Dummy := Format(FldRef.Relation());
        Observer.ObserveError('relation');
        asserterror Dummy := FldRef.Caption();
        Observer.ObserveError('caption');
        asserterror Dummy := Format(FldRef.IsOptimizedForTextSearch());
        Observer.ObserveError('isOptimizedForTextSearch');
        Observer.Expect('isEnum|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('isEnum|code', 'NotInitialized');
        Observer.Expect('class|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('class|code', 'NotInitialized');
        Observer.Expect('active|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('active|code', 'NotInitialized');
        Observer.Expect('relation|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('relation|code', 'NotInitialized');
        Observer.Expect('caption|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('caption|code', 'NotInitialized');
        Observer.Expect('isOptimizedForTextSearch|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('isOptimizedForTextSearch|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_OtherMembers_B()
    var
        Observer: Codeunit "Probe Observer";
        FldRef: FieldRef;
        Dummy: Text;
    begin
        asserterror FldRef.Validate(5);
        Observer.ObserveError('validateValue');
        asserterror FldRef.Validate();
        Observer.ObserveError('validateNoArg');
        asserterror FldRef.SetRange(1, 2);
        Observer.ObserveError('setRange');
        asserterror FldRef.SetFilter('>%1', 1);
        Observer.ObserveError('setFilter');
        asserterror Dummy := FldRef.GetFilter();
        Observer.ObserveError('getFilter');
        asserterror FldRef.CalcField();
        Observer.ObserveError('calcField');
        asserterror Dummy := Format(FldRef.OptionMembers());
        Observer.ObserveError('optionMembers');
        asserterror FldRef.TestField();
        Observer.ObserveError('testField');
        Observer.Expect('validateValue|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('validateValue|code', 'NotInitialized');
        Observer.Expect('validateNoArg|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('validateNoArg|code', 'NotInitialized');
        Observer.Expect('setRange|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('setRange|code', 'NotInitialized');
        Observer.Expect('setFilter|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('setFilter|code', 'NotInitialized');
        Observer.Expect('getFilter|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('getFilter|code', 'NotInitialized');
        Observer.Expect('calcField|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('calcField|code', 'NotInitialized');
        Observer.Expect('optionMembers|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('optionMembers|code', 'NotInitialized');
        Observer.Expect('testField|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('testField|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_AfterRecordRefFindFoundNothing()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Unassigned";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Row.DeleteAll();
        RecRef.Open(Database::"LT PnD Unassigned");
        if RecRef.FindLast() then
            FldRef := RecRef.Field(2);
        asserterror FldRef.Value(5);
        Observer.ObserveError('valueSetAfterEmptyFind');
        asserterror FldRef.Value('abc');
        Observer.ObserveError('valueSetTextAfterEmptyFind');
        Observer.Expect('valueSetAfterEmptyFind|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('valueSetAfterEmptyFind|code', 'NotInitialized');
        Observer.Expect('valueSetTextAfterEmptyFind|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('valueSetTextAfterEmptyFind|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Assigned_FromEmptyTable_ForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Unassigned";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Row.DeleteAll();
        RecRef.Open(Database::"LT PnD Unassigned");
        FldRef := RecRef.Field(2);
        Observer.Observe('isEnum', Format(FldRef.IsEnum()));
        Observer.Observe('class', Format(FldRef.Class()));
        Observer.Observe('active', Format(FldRef.Active()));
        FldRef.Value('abc');
        Observer.Observe('valueAfterSet', Format(FldRef.Value()));
        Observer.Expect('isEnum', 'No');
        Observer.Expect('class', 'Normal');
        Observer.Expect('active', 'Yes');
        Observer.Expect('valueAfterSet', 'abc');
        Observer.Verify();
    end;
}
