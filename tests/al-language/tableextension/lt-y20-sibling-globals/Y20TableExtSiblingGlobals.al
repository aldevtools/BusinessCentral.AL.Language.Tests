// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe (writer Y20, al-runner issue 6485): measured on a BC 29 SaaS sandbox; 27 and 28 by the corpus CI matrix.
// Facts: a table extension uses a global variable (a Record and an Integer) that only another extension of the same table in the
//   same app declares with `protected var`, and calls a procedure of that extension: it compiles; a value one extension writes is
//   the one the other reads, for one record variable; a second record variable has its own globals; record assignment, Copy,
//   Init and Clear. With plain `var` it does not compile (must-not-compile 2356, AL0161).
// BC versions: 27, 28, 29

table 92112 "LT Y20 Sib Center"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[50]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

table 92113 "LT Y20 Sib Name"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[50]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }

    procedure InsertName(NewCode: Code[20]; NewName: Text[50])
    begin
        Code := NewCode;
        Name := NewName;
        Insert();
    end;
}

// Uses CostAccName and Counter, which only "LT Y20 Sib Center B" declares (protected var).
tableextension 92114 "LT Y20 Sib Center A" extends "LT Y20 Sib Center"
{
    trigger OnInsert()
    begin
        CostAccName.InsertName(Code, Name);
        Counter := Counter + 1;
    end;

    procedure Y20CounterSeenByB(): Integer
    begin
        exit(Y20ReadCounter());
    end;

    procedure Y20SetCounterFromA(Value: Integer)
    begin
        Counter := Value;
    end;

    procedure Y20NameCodeSeenByA(): Code[20]
    begin
        exit(CostAccName.Code);
    end;
}

tableextension 92115 "LT Y20 Sib Center B" extends "LT Y20 Sib Center"
{
    protected var
        CostAccName: Record "LT Y20 Sib Name";
        Counter: Integer;

    procedure Y20ReadCounter(): Integer
    begin
        exit(Counter);
    end;

    procedure Y20SetCounterFromB(Value: Integer)
    begin
        Counter := Value;
    end;
}

codeunit 92116 "LT Y20 TableExt Sib Globals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Reset()
    var
        C: Record "LT Y20 Sib Center";
        N: Record "LT Y20 Sib Name";
    begin
        C.DeleteAll();
        N.DeleteAll();
    end;

    // The reporter's shape.
    [Test]
    procedure Y20_SiblingGlobal_WrittenByTrigger_ReadBySibling()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "LT Y20 Sib Center";
        N: Record "LT Y20 Sib Name";
    begin
        Reset();
        C.Code := 'CC1';
        C.Name := 'Center one';
        C.Insert(true);
        Observer.Observe('name_row', Format(N.Get('CC1')) + '/' + N.Name);
        Observer.Observe('counter_via_b', Format(C.Y20CounterSeenByB()));
        Observer.Observe('counter_b', Format(C.Y20ReadCounter()));
        Observer.Observe('name_global_code', C.Y20NameCodeSeenByA());
        C.Code := 'CC2';
        C.Name := 'Center two';
        C.Insert(true);
        Observer.Observe('counter_after_second_insert', Format(C.Y20ReadCounter()));
        Observer.Observe('name_global_code_2', C.Y20NameCodeSeenByA());
        Observer.Expect('name_row', 'Yes/Center one');
        Observer.Expect('counter_via_b', '1');
        Observer.Expect('counter_b', '1');
        Observer.Expect('name_global_code', 'CC1');
        Observer.Expect('counter_after_second_insert', '2');
        Observer.Expect('name_global_code_2', 'CC2');
        Observer.Verify();
    end;

    [Test]
    procedure Y20_SiblingGlobal_PerRecordVariable()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "LT Y20 Sib Center";
        Other: Record "LT Y20 Sib Center";
    begin
        Reset();
        C.Y20SetCounterFromA(7);
        Observer.Observe('a_writes_b_reads', Format(C.Y20ReadCounter()));
        C.Y20SetCounterFromB(9);
        Observer.Observe('b_writes_a_reads', Format(C.Y20CounterSeenByB()));
        Observer.Observe('other_variable', Format(Other.Y20ReadCounter()));
        Other := C;
        Observer.Observe('after_assignment', Format(Other.Y20ReadCounter()));
        Other.Y20SetCounterFromA(0);
        Other.Copy(C);
        Observer.Observe('after_copy', Format(Other.Y20ReadCounter()));
        C.Init();
        Observer.Observe('after_init', Format(C.Y20ReadCounter()));
        Clear(C);
        Observer.Observe('after_clear', Format(C.Y20ReadCounter()));
        Observer.Expect('a_writes_b_reads', '7');
        Observer.Expect('b_writes_a_reads', '9');
        Observer.Expect('other_variable', '0');
        Observer.Expect('after_assignment', '0');
        Observer.Expect('after_copy', '0');
        Observer.Expect('after_init', '9');
        Observer.Expect('after_clear', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y20_SiblingGlobal_InsertWithoutTrigger()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "LT Y20 Sib Center";
        N: Record "LT Y20 Sib Name";
    begin
        Reset();
        C.Code := 'CC3';
        C.Insert(false);
        Observer.Observe('name_rows', Format(N.Count()));
        Observer.Observe('counter', Format(C.Y20ReadCounter()));
        Observer.Expect('name_rows', '0');
        Observer.Expect('counter', '0');
        Observer.Verify();
    end;
}
