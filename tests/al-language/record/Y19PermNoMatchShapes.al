// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modifyall-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y19 Perm Helper (91935, Y19PermObjects.al); Permissions Mock (131006) from the dependency.
// Probe (al-runner issue 8068): which facts decide whether BC denies a ModifyAll or DeleteAll whose filter matches no row of a
//   table that holds rows. Y19PermWrites.al:294-307 (Y19_P2) measured a denial: a filter on the primary key, an Integer field
//   outside the filter written, two rows, in a local procedure of the test codeunit, sets R and RI. The reporter measured no
//   denial on BC 28.5: ModifyAll of the filter field (Code, blank) after a SetRange on a field outside the key, in the OnDelete
//   trigger of another table reached by Delete(true), one row, set R. Each op below changes one of those facts.
// Shape (as Y19PermWrites.al): each case clears the assignment, seeds the target with N rows (Parent Code 'X', none matches the
//   filter), seeds one row of each parent table, assigns the set (Permissions Mock.Set: the set plus All Objects), runs ONE op
//   inside asserterror that ends with the own error 'LT NM ok', observes text and code, clears the assignment.
// Expected values: filled in from the local observation run of each major (BC 27.5, 28.5, 29.0).
// BC versions: 27, 28, 29

table 97300 "LT NM Target"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; "Parent Code"; Code[10]) { }
        field(3; Value; Integer) { }
        field(4; Note; Code[10]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// The reporter's trigger: ModifyAll of the filter field, blank.
table 97301 "LT NM Parent"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        Target: Record "LT NM Target";
    begin
        Target.SetRange("Parent Code", Code);
        Target.ModifyAll("Parent Code", '');
    end;
}

// The trigger writes a field outside the filter (the shape of Base Application's Contact.OnDelete).
table 97302 "LT NM Parent Other"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        Target: Record "LT NM Target";
    begin
        Target.SetRange("Parent Code", Code);
        Target.ModifyAll(Note, '');
    end;
}

// The pinned op (filter on the key, Integer field outside it) in a trigger.
table 97303 "LT NM Parent Key"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        Target: Record "LT NM Target";
    begin
        Target.SetRange(Id, 100);
        Target.ModifyAll(Value, 99);
    end;
}

// DeleteAll in a trigger, filter outside the key.
table 97304 "LT NM Parent Del"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        Target: Record "LT NM Target";
    begin
        Target.SetRange("Parent Code", Code);
        Target.DeleteAll();
    end;
}

// The ops in a codeunit of the app (no Permissions property).
codeunit 97305 "LT NM App Writer"
{
    procedure ClearParentCode(ParentCode: Code[10])
    var
        Target: Record "LT NM Target";
    begin
        Target.SetRange("Parent Code", ParentCode);
        Target.ModifyAll("Parent Code", '');
    end;

    procedure ModifyValueOnKey()
    var
        Target: Record "LT NM Target";
    begin
        Target.SetRange(Id, 100);
        Target.ModifyAll(Value, 99);
    end;
}

permissionset 97306 "LT NM R"
{
    Assignable = true;
    Permissions = tabledata "LT NM Target" = R,
        tabledata "LT NM Parent" = RIMD, tabledata "LT NM Parent Other" = RIMD,
        tabledata "LT NM Parent Key" = RIMD, tabledata "LT NM Parent Del" = RIMD;
}

permissionset 97307 "LT NM RI"
{
    Assignable = true;
    Permissions = tabledata "LT NM Target" = RI,
        tabledata "LT NM Parent" = RIMD, tabledata "LT NM Parent Other" = RIMD,
        tabledata "LT NM Parent Key" = RIMD, tabledata "LT NM Parent Del" = RIMD;
}

codeunit 97310 "LT NM No Match Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure NM_OneRow_SetR()
    begin
        RunAll('1_r', 'LT NM R', 1);
    end;

    [Test]
    procedure NM_TwoRows_SetR()
    begin
        RunAll('2_r', 'LT NM R', 2);
    end;

    [Test]
    procedure NM_OneRow_SetRI()
    begin
        RunAll('1_ri', 'LT NM RI', 1);
    end;

    [Test]
    procedure NM_TwoRows_SetRI()
    begin
        RunAll('2_ri', 'LT NM RI', 2);
    end;

    local procedure RunAll(Tag: Text; SetName: Code[20]; Rows: Integer)
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
        Ops: List of [Integer];
        Which: Integer;
    begin
        WasStarted := Helper.StartMock(Mock);
        // 1 test: key filter, Integer field outside it (Y19_P2); 2 test: non-key filter, field outside it;
        // 3 test: non-key filter, the filter field blank; 4 test: non-key filter, the filter field set to 'Y';
        // 5 test: as 3 with RunTrigger; 6 test: non-key filter, DeleteAll;
        // 11 trigger: as 3 (the reporter's); 12 trigger: as 2 on a Code field (Note blank); 13 trigger: as 1; 14 trigger: as 6;
        // 21 app codeunit: as 3; 22 app codeunit: as 1.
        Ops.AddRange(1, 2, 3, 4, 5, 6, 11, 12, 13, 14, 21, 22);
        foreach Which in Ops do
            RunCase(Observer, 'op' + Format(Which) + '_' + Tag, SetName, Rows, Which);
        Helper.RestoreMock(Mock, WasStarted);
        // Expect lines: from the local observation run.
        Observer.Verify();
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; SetName: Code[20]; Rows: Integer; Which: Integer)
    begin
        Mock.ClearAssignments();
        Seed(Rows);
        Mock.Set(SetName);
        asserterror Op(Which);
        Observer.ObserveError(Name);
        Mock.ClearAssignments();
    end;

    local procedure Seed(Rows: Integer)
    var
        Target: Record "LT NM Target";
        Parent: Record "LT NM Parent";
        ParentOther: Record "LT NM Parent Other";
        ParentKey: Record "LT NM Parent Key";
        ParentDel: Record "LT NM Parent Del";
        i: Integer;
    begin
        Target.DeleteAll();
        Parent.DeleteAll();
        ParentOther.DeleteAll();
        ParentKey.DeleteAll();
        ParentDel.DeleteAll();
        for i := 1 to Rows do begin
            Target.Id := i;
            Target."Parent Code" := 'X';
            Target.Value := 10 * i;
            Target.Insert();
        end;
        Parent.Code := 'P1';
        Parent.Insert();
        ParentOther.Code := 'P1';
        ParentOther.Insert();
        ParentKey.Code := 'P1';
        ParentKey.Insert();
        ParentDel.Code := 'P1';
        ParentDel.Insert();
    end;

    local procedure Op(Which: Integer)
    var
        Target: Record "LT NM Target";
        Parent: Record "LT NM Parent";
        ParentOther: Record "LT NM Parent Other";
        ParentKey: Record "LT NM Parent Key";
        ParentDel: Record "LT NM Parent Del";
        AppWriter: Codeunit "LT NM App Writer";
    begin
        case Which of
            1:
                begin
                    Target.SetRange(Id, 100);
                    Target.ModifyAll(Value, 99);
                end;
            2:
                begin
                    Target.SetRange("Parent Code", 'P1');
                    Target.ModifyAll(Value, 99);
                end;
            3:
                begin
                    Target.SetRange("Parent Code", 'P1');
                    Target.ModifyAll("Parent Code", '');
                end;
            4:
                begin
                    Target.SetRange("Parent Code", 'P1');
                    Target.ModifyAll("Parent Code", 'Y');
                end;
            5:
                begin
                    Target.SetRange("Parent Code", 'P1');
                    Target.ModifyAll("Parent Code", '', true);
                end;
            6:
                begin
                    Target.SetRange("Parent Code", 'P1');
                    Target.DeleteAll();
                end;
            11:
                begin
                    Parent.Get('P1');
                    Parent.Delete(true);
                end;
            12:
                begin
                    ParentOther.Get('P1');
                    ParentOther.Delete(true);
                end;
            13:
                begin
                    ParentKey.Get('P1');
                    ParentKey.Delete(true);
                end;
            14:
                begin
                    ParentDel.Get('P1');
                    ParentDel.Delete(true);
                end;
            21:
                AppWriter.ClearParentCode('P1');
            22:
                AppWriter.ModifyValueOnKey();
        end;
        Error('LT NM ok');
    end;
}
