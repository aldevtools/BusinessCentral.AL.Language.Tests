// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-inherentpermissions-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y19 Perm Helper (91935, record/Y19PermObjects.al); Permissions Mock (131006) from the dependency.
// Probe (al-runner issue 8066): a lower-case letter in [InherentPermissions(PermissionObjectType::TableData, T, 'x')] under a set
//   that grants nothing on T. Only upper-case letters are pinned (BiInherentPerms.al, CpPermLeads.al:155-189). Cells: letters
//   i, m, d, r; the attribute on the routine that writes and on its caller (a public procedure that calls a local writer);
//   the codeunit with Permissions = tabledata T = rimd and without it. Microsoft's No. Series ("No. Series - Stateless Impl.",
//   Permissions = tabledata "No. Series Line" = rimd, local GetNextNoInternal with 'm') has the first shape.
// Shape: each case clears the assignment, seeds T with row 1, assigns the set (Permissions Mock.Set: "LT IA None" plus All
//   Objects), runs ONE op inside asserterror that ends with the own error 'LT IA ok', observes text and code, clears it.
// Expected values: observed on BC 27.5, 28.5 and 29.0 (corpus CI run); 27.5 and 28.5 agree.
// BC versions: 27, 28, 29

table 97320 "LT IA Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 97321 "LT IA Other" { DataClassification = SystemMetadata; fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }

// A set that grants nothing on "LT IA Row".
permissionset 97322 "LT IA None"
{
    Assignable = true;
    Permissions = tabledata "LT IA Other" = R;
}

// With Permissions = rimd on the table.
codeunit 97323 "LT IA With Perms"
{
    Permissions = tabledata "LT IA Row" = rimd;

    procedure InsertOnWriter() begin InsertI(5); end;
    procedure ModifyOnWriter() begin ModifyM(); end;
    procedure DeleteOnWriter() begin DeleteD(); end;
    procedure ReadOnWriter() begin ReadR(); end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT IA Row", 'i')]
    procedure InsertOnCaller() begin InsertPlain(6); end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT IA Row", 'm')]
    procedure ModifyOnCaller() begin ModifyPlain(); end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT IA Row", 'i')]
    local procedure InsertI(NewId: Integer)
    var
        Row: Record "LT IA Row";
    begin
        Row.Id := NewId;
        Row.Insert();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT IA Row", 'm')]
    local procedure ModifyM()
    var
        Row: Record "LT IA Row";
    begin
        Row.Get(1);
        Row.Value := 7;
        Row.Modify();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT IA Row", 'd')]
    local procedure DeleteD()
    var
        Row: Record "LT IA Row";
    begin
        Row.SetRange(Id, 1);
        Row.FindFirst();
        Row.Delete();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT IA Row", 'r')]
    local procedure ReadR()
    var
        Row: Record "LT IA Row";
    begin
        Row.FindFirst();
    end;

    local procedure InsertPlain(NewId: Integer)
    var
        Row: Record "LT IA Row";
    begin
        Row.Id := NewId;
        Row.Insert();
    end;

    local procedure ModifyPlain()
    var
        Row: Record "LT IA Row";
    begin
        Row.Get(1);
        Row.Value := 8;
        Row.Modify();
    end;
}

// The same without a Permissions property.
codeunit 97324 "LT IA No Perms"
{
    procedure InsertOnWriter() begin InsertI(5); end;
    procedure ModifyOnWriter() begin ModifyM(); end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT IA Row", 'i')]
    procedure InsertOnCaller() begin InsertPlain(6); end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT IA Row", 'i')]
    local procedure InsertI(NewId: Integer)
    var
        Row: Record "LT IA Row";
    begin
        Row.Id := NewId;
        Row.Insert();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT IA Row", 'm')]
    local procedure ModifyM()
    var
        Row: Record "LT IA Row";
    begin
        Row.Get(1);
        Row.Value := 7;
        Row.Modify();
    end;

    local procedure InsertPlain(NewId: Integer)
    var
        Row: Record "LT IA Row";
    begin
        Row.Id := NewId;
        Row.Insert();
    end;
}

codeunit 97325 "LT IA Inherent Lower Case"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure IA_LowerCaseAttribute()
    var
        WasStarted: Boolean;
        Ops: List of [Integer];
        Which: Integer;
    begin
        WasStarted := Helper.StartMock(Mock);
        // 1-4 with Permissions: i, m, d, r on the writer; 5-6 with Permissions: i, m on the caller;
        // 11-12 without Permissions: i, m on the writer; 13 without Permissions: i on the caller.
        Ops.AddRange(1, 2, 3, 4, 5, 6, 11, 12, 13);
        foreach Which in Ops do
            RunCase('op' + Format(Which), Which);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('op1|text', 'LT IA ok');
        Observer.Expect('op1|code', 'Dialog');
        Observer.Expect('op2|text', 'Sorry, the current permissions prevented the action. (TableData 97320 LT IA Row IndirectRead: AL Language Coverage Tests)');
        Observer.Expect('op2|code', 'DB:ClientReadDenied');
        Observer.Expect('op3|text', 'Sorry, the current permissions prevented the action. (TableData 97320 LT IA Row IndirectRead: AL Language Coverage Tests)');
        Observer.Expect('op3|code', 'DB:ClientReadDenied');
        Observer.Expect('op4|text', 'LT IA ok');
        Observer.Expect('op4|code', 'Dialog');
        Observer.Expect('op5|text', 'LT IA ok');
        Observer.Expect('op5|code', 'Dialog');
        Observer.Expect('op6|text', 'Sorry, the current permissions prevented the action. (TableData 97320 LT IA Row IndirectRead: AL Language Coverage Tests)');
        Observer.Expect('op6|code', 'DB:ClientReadDenied');
        Observer.Expect('op11|text', 'Sorry, the current permissions prevented the action. (TableData 97320 LT IA Row Insert: AL Language Coverage Tests)');
        Observer.Expect('op11|code', 'DB:ClientInsertDenied');
        Observer.Expect('op12|text', 'Sorry, the current permissions prevented the action. (TableData 97320 LT IA Row Read: AL Language Coverage Tests)');
        Observer.Expect('op12|code', 'DB:ClientReadDenied');
        Observer.Expect('op13|text', 'Sorry, the current permissions prevented the action. (TableData 97320 LT IA Row Insert: AL Language Coverage Tests)');
        Observer.Expect('op13|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;



    local procedure RunCase(Name: Text; Which: Integer)
    var
        Row: Record "LT IA Row";
    begin
        Mock.ClearAssignments();
        Row.DeleteAll();
        Row.Id := 1;
        Row.Value := 10;
        Row.Insert();
        Mock.Set('LT IA None');
        asserterror Op(Which);
        Observer.ObserveError(Name);
        Mock.ClearAssignments();
    end;

    local procedure Op(Which: Integer)
    var
        WithPerms: Codeunit "LT IA With Perms";
        NoPerms: Codeunit "LT IA No Perms";
    begin
        case Which of
            1:
                WithPerms.InsertOnWriter();
            2:
                WithPerms.ModifyOnWriter();
            3:
                WithPerms.DeleteOnWriter();
            4:
                WithPerms.ReadOnWriter();
            5:
                WithPerms.InsertOnCaller();
            6:
                WithPerms.ModifyOnCaller();
            11:
                NoPerms.InsertOnWriter();
            12:
                NoPerms.ModifyOnWriter();
            13:
                NoPerms.InsertOnCaller();
        end;
        Error('LT IA ok');
    end;
}
