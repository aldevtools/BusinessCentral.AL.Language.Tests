// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modifyall-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Permissions Mock (131006) from the dependency.
// local object: the reporter's own tables and permission set are what the test checks (no DataClassification, Code keys).
// Probe (al-runner issue 8068, the reporter's shape): the reporter measured on BC 28.5 that a ModifyAll matching no row, in the
//   OnDelete trigger of "Repro Parent" reached by Delete(true), is not denied, with the mock started, Set('D365 BASIC') then
//   Assign of a set with RIMD on the parent and R on the target, one unrelated target row, Code primary keys, no
//   DataClassification, and no asserterror. The corpus (record/Y19PermNoMatchTriggers.al, Y19PermNoMatchShapes.al) measured a
//   denial with Integer target keys, Set of one set, TestPermissions = Disabled and asserterror. The tables here copy the
//   reporter's ("PRM BW Rep Parent", "PRM BW Rep Other"); each cell changes one point:
//   intkey = the target's key is one Integer field; dataclass = both tables have DataClassification = SystemMetadata;
//   setonly = Set('PRM BW REP EDIT') alone; rows0 / rows2 = no or two target rows; direct = the ModifyAll called in a codeunit
//   (the reporter's control 4); intkey_setonly(_direct) = two points at once (the corpus' shape).
//   Plain tests run the same steps without asserterror. The codeunits "PRM BW Rep TP ..." repeat the reporter's shape with
//   TestPermissions not set, Restrictive and NonRestrictive (this app has no Tests-TestLibraries, whose per-test reset reads
//   TestPermissions).
// BC versions: 27, 28, 29

table 77770 "PRM BW Rep Parent"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; "Primary Child No."; Code[10]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        ReproOther: Record "PRM BW Rep Other";
    begin
        // no row of PRM BW Rep Other points to this record
        ReproOther.SetRange("Parent Code", Code);
        ReproOther.ModifyAll("Parent Code", '');
    end;
}

table 77771 "PRM BW Rep Other"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; "Parent Code"; Code[10]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

// One point changed: the target's primary key is one Integer field.
table 77772 "PRM BW Rep Parent Int"
{
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        ReproOther: Record "PRM BW Rep Other Int";
    begin
        ReproOther.SetRange("Parent Code", Code);
        ReproOther.ModifyAll("Parent Code", '');
    end;
}

table 77773 "PRM BW Rep Other Int"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; "Parent Code"; Code[10]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// One point changed: both tables have DataClassification = SystemMetadata.
table 77774 "PRM BW Rep Parent DC"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        ReproOther: Record "PRM BW Rep Other DC";
    begin
        ReproOther.SetRange("Parent Code", Code);
        ReproOther.ModifyAll("Parent Code", '');
    end;
}

table 77775 "PRM BW Rep Other DC"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; "Parent Code"; Code[10]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

// The reporter's set: RIMD on the parent tables, R on the targets.
permissionset 77776 "PRM BW REP EDIT"
{
    Assignable = true;
    Permissions = tabledata "PRM BW Rep Parent" = RIMD, tabledata "PRM BW Rep Other" = R,
        tabledata "PRM BW Rep Parent Int" = RIMD, tabledata "PRM BW Rep Other Int" = R,
        tabledata "PRM BW Rep Parent DC" = RIMD, tabledata "PRM BW Rep Other DC" = R;
}

// The reporter's steps, shared by the test codeunits below (TestPermissions differs per codeunit).
codeunit 77777 "PRM BW Rep Steps"
{
    var
        Mock: Codeunit "Permissions Mock";
        WasStarted: Boolean;

    procedure StartMock()
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
        Mock.ClearAssignments();
    end;

    procedure StopMock()
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;

    procedure IsStarted(): Boolean
    begin
        exit(Mock.IsStarted());
    end;

    procedure ClearAssignments()
    begin
        Mock.ClearAssignments();
    end;

    // Kind: 'basic+assign' = Set('D365 BASIC') then Assign('PRM BW REP EDIT') (the reporter's); 'set' = Set('PRM BW REP EDIT').
    procedure AssignSets(Kind: Text)
    begin
        case Kind of
            'basic+assign':
                begin
                    Mock.Set('D365 BASIC');
                    Mock.Assign('PRM BW REP EDIT');
                end;
            'set':
                Mock.Set('PRM BW REP EDIT');
        end;
    end;

    // Table: 'code' (the reporter's tables), 'int' (Integer key on the target), 'dc' (DataClassification set).
    // OtherRows: rows in the target, Parent Code 'X' (none matches the parent P1).
    procedure Seed(Table: Text; OtherRows: Integer)
    var
        Parent: Record "PRM BW Rep Parent";
        Other: Record "PRM BW Rep Other";
        ParentInt: Record "PRM BW Rep Parent Int";
        OtherInt: Record "PRM BW Rep Other Int";
        ParentDC: Record "PRM BW Rep Parent DC";
        OtherDC: Record "PRM BW Rep Other DC";
        Index: Integer;
    begin
        Parent.DeleteAll();
        Other.DeleteAll();
        ParentInt.DeleteAll();
        OtherInt.DeleteAll();
        ParentDC.DeleteAll();
        OtherDC.DeleteAll();
        case Table of
            'code':
                begin
                    Parent.Code := 'P1';
                    Parent.Insert();
                    for Index := 1 to OtherRows do begin
                        Other.Code := 'O' + Format(Index);
                        Other."Parent Code" := 'X';
                        Other.Insert();
                    end;
                end;
            'int':
                begin
                    ParentInt.Code := 'P1';
                    ParentInt.Insert();
                    for Index := 1 to OtherRows do begin
                        OtherInt.Id := Index;
                        OtherInt."Parent Code" := 'X';
                        OtherInt.Insert();
                    end;
                end;
            'dc':
                begin
                    ParentDC.Code := 'P1';
                    ParentDC.Insert();
                    for Index := 1 to OtherRows do begin
                        OtherDC.Code := 'O' + Format(Index);
                        OtherDC."Parent Code" := 'X';
                        OtherDC.Insert();
                    end;
                end;
        end;
    end;

    // Where: 'trigger' = Delete(true) of the parent P1; 'direct' = the ModifyAll in this codeunit (the reporter's control 4).
    procedure Op(Table: Text; Where: Text)
    var
        Parent: Record "PRM BW Rep Parent";
        Other: Record "PRM BW Rep Other";
        ParentInt: Record "PRM BW Rep Parent Int";
        OtherInt: Record "PRM BW Rep Other Int";
        ParentDC: Record "PRM BW Rep Parent DC";
        OtherDC: Record "PRM BW Rep Other DC";
    begin
        case Table + '/' + Where of
            'code/trigger':
                begin
                    Parent.Get('P1');
                    Parent.Delete(true);
                end;
            'code/direct':
                begin
                    Other.SetRange("Parent Code", 'NOROW');
                    Other.ModifyAll("Parent Code", '');
                end;
            'int/trigger':
                begin
                    ParentInt.Get('P1');
                    ParentInt.Delete(true);
                end;
            'int/direct':
                begin
                    OtherInt.SetRange("Parent Code", 'NOROW');
                    OtherInt.ModifyAll("Parent Code", '');
                end;
            'dc/trigger':
                begin
                    ParentDC.Get('P1');
                    ParentDC.Delete(true);
                end;
            'dc/direct':
                begin
                    OtherDC.SetRange("Parent Code", 'NOROW');
                    OtherDC.ModifyAll("Parent Code", '');
                end;
        end;
    end;

    // The state after a plain run: parent P1 still there, target rows with Parent Code 'X'.
    [InherentPermissions(PermissionObjectType::TableData, Database::"PRM BW Rep Parent", 'R')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"PRM BW Rep Other", 'R')]
    procedure State(): Text
    var
        Parent: Record "PRM BW Rep Parent";
        Other: Record "PRM BW Rep Other";
    begin
        Other.SetRange("Parent Code", 'X');
        exit('parent P1 exists=' + Format(Parent.Get('P1')) + ';target rows X=' + Format(Other.Count()));
    end;
}

codeunit 77780 "PRM BW Rep Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "PRM BW Rep Steps";

    [Test]
    procedure BWRep_OnePointChanged_AsserterrorCells()
    begin
        Cell('r0', 'code', 1, 'basic+assign', 'trigger');
        Cell('intkey', 'int', 1, 'basic+assign', 'trigger');
        Cell('dataclass', 'dc', 1, 'basic+assign', 'trigger');
        Cell('setonly', 'code', 1, 'set', 'trigger');
        Cell('rows0', 'code', 0, 'basic+assign', 'trigger');
        Cell('rows2', 'code', 2, 'basic+assign', 'trigger');
        Cell('direct', 'code', 1, 'basic+assign', 'direct');
        Cell('intkey_setonly', 'int', 1, 'set', 'trigger');
        Cell('intkey_setonly_direct', 'int', 1, 'set', 'direct');
        Cell('dataclass_direct', 'dc', 1, 'basic+assign', 'direct');
        Observer.Finish();
    end;

    [Test]
    procedure BWRep_Plain_ReporterShape()
    begin
        Steps.StartMock();
        Steps.Seed('code', 1);
        Steps.AssignSets('basic+assign');
        Steps.Op('code', 'trigger');
        Observer.Observe('plain run', 'no error');
        Observer.Observe('state', Steps.State());
        Steps.StopMock();
        Observer.Finish();
    end;

    [Test]
    procedure BWRep_Plain_Direct()
    begin
        Steps.StartMock();
        Steps.Seed('code', 1);
        Steps.AssignSets('basic+assign');
        Steps.Op('code', 'direct');
        Observer.Observe('plain run', 'no error');
        Observer.Observe('state', Steps.State());
        Steps.StopMock();
        Observer.Finish();
    end;

    [Test]
    procedure BWRep_Plain_SetOnly()
    begin
        Steps.StartMock();
        Steps.Seed('code', 1);
        Steps.AssignSets('set');
        Steps.Op('code', 'trigger');
        Observer.Observe('plain run', 'no error');
        Observer.Observe('state', Steps.State());
        Steps.StopMock();
        Observer.Finish();
    end;

    [Test]
    procedure BWRep_Plain_IntKey()
    begin
        Steps.StartMock();
        Steps.Seed('int', 1);
        Steps.AssignSets('basic+assign');
        Steps.Op('int', 'trigger');
        Observer.Observe('plain run', 'no error');
        Steps.StopMock();
        Observer.Finish();
    end;

    [Test]
    procedure BWRep_Plain_IntKeySetOnly()
    begin
        Steps.StartMock();
        Steps.Seed('int', 1);
        Steps.AssignSets('set');
        Steps.Op('int', 'trigger');
        Observer.Observe('plain run', 'no error');
        Steps.StopMock();
        Observer.Finish();
    end;

    [Test]
    procedure BWRep_Plain_DataClass()
    begin
        Steps.StartMock();
        Steps.Seed('dc', 1);
        Steps.AssignSets('basic+assign');
        Steps.Op('dc', 'trigger');
        Observer.Observe('plain run', 'no error');
        Steps.StopMock();
        Observer.Finish();
    end;

    local procedure Cell(Name: Text; Table: Text; OtherRows: Integer; Sets: Text; Where: Text)
    begin
        Steps.StartMock();
        Steps.Seed(Table, OtherRows);
        Steps.AssignSets(Sets);
        asserterror OpThenOk(Table, Where);
        Observer.ObserveError(Name);
        Steps.StopMock();
    end;

    local procedure OpThenOk(Table: Text; Where: Text)
    begin
        Steps.Op(Table, Where);
        Error('PRM BW ok');
    end;
}

codeunit 77781 "PRM BW Rep TP Default"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "PRM BW Rep Steps";

    [Test]
    procedure BWRep_TP_AsserterrorCells()
    begin
        Cell('r0', 'code', 1, 'basic+assign', 'trigger');
        Cell('direct', 'code', 1, 'basic+assign', 'direct');
        Observer.Finish();
    end;

    [Test]
    procedure BWRep_TP_Plain_ReporterShape()
    begin
        Steps.StartMock();
        Steps.Seed('code', 1);
        Steps.AssignSets('basic+assign');
        Steps.Op('code', 'trigger');
        Observer.Observe('plain run', 'no error');
        Observer.Observe('state', Steps.State());
        Steps.StopMock();
        Observer.Finish();
    end;

    local procedure Cell(Name: Text; Table: Text; OtherRows: Integer; Sets: Text; Where: Text)
    begin
        Steps.StartMock();
        Steps.Seed(Table, OtherRows);
        Steps.AssignSets(Sets);
        asserterror OpThenOk(Table, Where);
        Observer.ObserveError(Name);
        Steps.StopMock();
    end;

    local procedure OpThenOk(Table: Text; Where: Text)
    begin
        Steps.Op(Table, Where);
        Error('PRM BW ok');
    end;
}

codeunit 77782 "PRM BW Rep TP Restrictive"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "PRM BW Rep Steps";

    [Test]
    procedure BWRep_TP_AsserterrorCells()
    begin
        Cell('r0', 'code', 1, 'basic+assign', 'trigger');
        Cell('direct', 'code', 1, 'basic+assign', 'direct');
        Observer.Finish();
    end;

    [Test]
    procedure BWRep_TP_Plain_ReporterShape()
    begin
        Steps.StartMock();
        Steps.Seed('code', 1);
        Steps.AssignSets('basic+assign');
        Steps.Op('code', 'trigger');
        Observer.Observe('plain run', 'no error');
        Observer.Observe('state', Steps.State());
        Steps.StopMock();
        Observer.Finish();
    end;

    local procedure Cell(Name: Text; Table: Text; OtherRows: Integer; Sets: Text; Where: Text)
    begin
        Steps.StartMock();
        Steps.Seed(Table, OtherRows);
        Steps.AssignSets(Sets);
        asserterror OpThenOk(Table, Where);
        Observer.ObserveError(Name);
        Steps.StopMock();
    end;

    local procedure OpThenOk(Table: Text; Where: Text)
    begin
        Steps.Op(Table, Where);
        Error('PRM BW ok');
    end;
}

codeunit 77783 "PRM BW Rep TP NonRestrictive"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "PRM BW Rep Steps";

    [Test]
    procedure BWRep_TP_AsserterrorCells()
    begin
        Cell('r0', 'code', 1, 'basic+assign', 'trigger');
        Cell('direct', 'code', 1, 'basic+assign', 'direct');
        Observer.Finish();
    end;

    [Test]
    procedure BWRep_TP_Plain_ReporterShape()
    begin
        Steps.StartMock();
        Steps.Seed('code', 1);
        Steps.AssignSets('basic+assign');
        Steps.Op('code', 'trigger');
        Observer.Observe('plain run', 'no error');
        Observer.Observe('state', Steps.State());
        Steps.StopMock();
        Observer.Finish();
    end;

    local procedure Cell(Name: Text; Table: Text; OtherRows: Integer; Sets: Text; Where: Text)
    begin
        Steps.StartMock();
        Steps.Seed(Table, OtherRows);
        Steps.AssignSets(Sets);
        asserterror OpThenOk(Table, Where);
        Observer.ObserveError(Name);
        Steps.StopMock();
    end;

    local procedure OpThenOk(Table: Text; Where: Text)
    begin
        Steps.Op(Table, Where);
        Error('PRM BW ok');
    end;
}
