// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modifyall-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y19 Perm Helper (91935, Y19PermObjects.al); Permissions Mock (131006) from the dependency.
// Probe (al-runner issue 8068, second part): neighbors of the reporter's shape, which is ModifyAll of the filter field (blank) after a
//   SetRange on that field in the OnDelete trigger of a parent table reached by Delete(true), one target row, the target granted
//   R only (see Y19PermNoMatchShapes.al). Each case changes one fact:
//   31 Parent.SetRange(Code, 'P1') then DeleteAll(true); 32 Parent.DeleteAll(true) unfiltered; 33 RecordRef.Delete(true);
//   34 a temporary parent record Delete(true); 51 the target variable is used before the ModifyAll (SetCurrentKey, Ascending(false),
//   LockTable, FindFirst, SetRange to 'Z' then cleared, then the reporter's filter); 61 the parent Code is blank; 71 the filter field
//   is in a secondary key of the target; 81 a Code[20] filter field; 91 a Commit between seeding and assigning the set;
//   101 the trigger filters with a literal 'P1'; 102 the trigger filters with another field of the parent;
//   121 the trigger is the OnDelete of a tableextension of the parent; 122 the write is in a subscriber of OnBeforeDeleteEvent;
//   131 Delete(false), Insert, then Delete(true) of the same parent in one transaction.
// Shape (as Y19PermNoMatchShapes.al): each case clears the assignment, seeds, assigns the set, runs ONE op inside asserterror that
//   ends with the own error 'LT NT ok', observes text and code, clears the assignment.
// Expected values: filled in from the observation run of each major (BC 27.5, 28.5, 29.0).
// BC versions: 27, 28, 29

table 97360 "LT NT Target"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; "Parent Code"; Code[10]) { }
        field(3; "Parent Code20"; Code[20]) { }
        field(4; Value; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K2; "Parent Code") { }
    }
}

table 97361 "LT NT P5 Used"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        Target: Record "LT NT Target";
    begin
        Target.SetCurrentKey("Parent Code");
        Target.Ascending(false);
        Target.LockTable();
        if Target.FindFirst() then;
        Target.SetRange("Parent Code", 'Z');
        Target.SetRange("Parent Code");
        Target.SetRange("Parent Code", Code);
        Target.ModifyAll("Parent Code", '');
    end;
}

table 97362 "LT NT P7 SecKey"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        Target: Record "LT NT Target";
    begin
        Target.SetRange("Parent Code", Code);
        Target.ModifyAll("Parent Code", '');
    end;
}

table 97363 "LT NT P8 Code20"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[20]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        Target: Record "LT NT Target";
    begin
        Target.SetRange("Parent Code20", Code);
        Target.ModifyAll("Parent Code20", '');
    end;
}

table 97364 "LT NT P11 Literal"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        Target: Record "LT NT Target";
    begin
        Target.SetRange("Parent Code", 'P1');
        Target.ModifyAll("Parent Code", '');
    end;
}

table 97365 "LT NT P11 OtherField"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; "Other Code"; Code[10]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        Target: Record "LT NT Target";
    begin
        Target.SetRange("Parent Code", "Other Code");
        Target.ModifyAll("Parent Code", '');
    end;
}

table 97366 "LT NT P12 Ext"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

tableextension 97367 "LT NT P12 Ext Ext" extends "LT NT P12 Ext"
{
    trigger OnDelete()
    var
        Target: Record "LT NT Target";
    begin
        Target.SetRange("Parent Code", Rec.Code);
        Target.ModifyAll("Parent Code", '');
    end;
}

table 97368 "LT NT P12 Sub"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 97369 "LT NT P12 Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"LT NT P12 Sub", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteParent(var Rec: Record "LT NT P12 Sub"; RunTrigger: Boolean)
    var
        Target: Record "LT NT Target";
    begin
        Target.SetRange("Parent Code", Rec.Code);
        Target.ModifyAll("Parent Code", '');
    end;
}

permissionset 97370 "LT NT R"
{
    Assignable = true;
    Permissions = tabledata "LT NT Target" = R,
        tabledata "LT NM Target" = R,
        tabledata "LT NM Parent" = RIMD,
        tabledata "LT NT P5 Used" = RIMD, tabledata "LT NT P7 SecKey" = RIMD, tabledata "LT NT P8 Code20" = RIMD,
        tabledata "LT NT P11 Literal" = RIMD, tabledata "LT NT P11 OtherField" = RIMD,
        tabledata "LT NT P12 Ext" = RIMD, tabledata "LT NT P12 Sub" = RIMD;
}

codeunit 97371 "LT NT No Match Triggers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure NT_31_ParentFilteredDeleteAllTrue()
    begin
        Run(31);
        Observer.Finish();
    end;

    [Test]
    procedure NT_32_ParentDeleteAllTrue()
    begin
        Run(32);
        Observer.Finish();
    end;

    [Test]
    procedure NT_33_RecordRefDeleteTrue()
    begin
        Run(33);
        Observer.Finish();
    end;

    [Test]
    procedure NT_34_TemporaryParentDeleteTrue()
    begin
        Run(34);
        Observer.Finish();
    end;

    [Test]
    procedure NT_51_TargetUsedBeforeModifyAll()
    begin
        Run(51);
        Observer.Finish();
    end;

    [Test]
    procedure NT_61_BlankParentCode()
    begin
        Run(61);
        Observer.Finish();
    end;

    [Test]
    procedure NT_71_SecondaryKeyFilterField()
    begin
        Run(71);
        Observer.Finish();
    end;

    [Test]
    procedure NT_81_Code20FilterField()
    begin
        Run(81);
        Observer.Finish();
    end;

    [Test]
    procedure NT_91_CommitBeforeAssign()
    begin
        Run(91);
        Observer.Finish();
    end;

    [Test]
    procedure NT_101_LiteralFilter()
    begin
        Run(101);
        Observer.Finish();
    end;

    [Test]
    procedure NT_102_OtherFieldOfParentFilter()
    begin
        Run(102);
        Observer.Finish();
    end;

    [Test]
    procedure NT_121_TableExtensionOnDelete()
    begin
        Run(121);
        Observer.Finish();
    end;

    [Test]
    procedure NT_122_OnBeforeDeleteSubscriber()
    begin
        Run(122);
        Observer.Finish();
    end;

    [Test]
    procedure NT_131_DeleteFalseInsertDeleteTrue()
    begin
        Run(131);
        Observer.Finish();
    end;

    local procedure Run(Which: Integer)
    var
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        Mock.ClearAssignments();
        Seed();
        if Which = 91 then
            Commit();
        Mock.Set('LT NT R');
        asserterror Op(Which);
        Observer.ObserveError('op' + Format(Which));
        Helper.RestoreMock(Mock, WasStarted);
    end;

    local procedure Seed()
    var
        NmTarget: Record "LT NM Target";
        NmParent: Record "LT NM Parent";
        Target: Record "LT NT Target";
        P5: Record "LT NT P5 Used";
        P7: Record "LT NT P7 SecKey";
        P8: Record "LT NT P8 Code20";
        P11: Record "LT NT P11 Literal";
        P11b: Record "LT NT P11 OtherField";
        P12e: Record "LT NT P12 Ext";
        P12s: Record "LT NT P12 Sub";
    begin
        NmTarget.DeleteAll();
        NmParent.DeleteAll();
        Target.DeleteAll();
        P5.DeleteAll();
        P7.DeleteAll();
        P8.DeleteAll();
        P11.DeleteAll();
        P11b.DeleteAll();
        P12e.DeleteAll();
        P12s.DeleteAll();
        NmTarget.Id := 1;
        NmTarget."Parent Code" := 'X';
        NmTarget.Value := 10;
        NmTarget.Insert();
        Target.Id := 1;
        Target."Parent Code" := 'X';
        Target."Parent Code20" := 'X';
        Target.Value := 10;
        Target.Insert();
        NmParent.Code := 'P1';
        NmParent.Insert();
        P5.Code := 'P1';
        P5.Insert();
        P7.Code := 'P1';
        P7.Insert();
        P7.Code := '';
        P7.Insert();
        P8.Code := 'P1';
        P8.Insert();
        P11.Code := 'P1';
        P11.Insert();
        P11b.Code := 'P1';
        P11b."Other Code" := 'P1';
        P11b.Insert();
        P12e.Code := 'P1';
        P12e.Insert();
        P12s.Code := 'P1';
        P12s.Insert();
    end;

    local procedure Op(Which: Integer)
    var
        NmParent: Record "LT NM Parent";
        TempParent: Record "LT NM Parent" temporary;
        P5: Record "LT NT P5 Used";
        P7: Record "LT NT P7 SecKey";
        P8: Record "LT NT P8 Code20";
        P11: Record "LT NT P11 Literal";
        P11b: Record "LT NT P11 OtherField";
        P12e: Record "LT NT P12 Ext";
        P12s: Record "LT NT P12 Sub";
        RecRef: RecordRef;
    begin
        case Which of
            31:
                begin
                    NmParent.SetRange(Code, 'P1');
                    NmParent.DeleteAll(true);
                end;
            32:
                NmParent.DeleteAll(true);
            33:
                begin
                    RecRef.Open(Database::"LT NM Parent");
                    RecRef.Get('P1');
                    RecRef.Delete(true);
                end;
            34:
                begin
                    TempParent.Code := 'P1';
                    TempParent.Insert();
                    TempParent.Delete(true);
                end;
            51:
                begin
                    P5.Get('P1');
                    P5.Delete(true);
                end;
            61:
                begin
                    P7.Get('');
                    P7.Delete(true);
                end;
            71:
                begin
                    P7.Get('P1');
                    P7.Delete(true);
                end;
            81:
                begin
                    P8.Get('P1');
                    P8.Delete(true);
                end;
            91:
                begin
                    NmParent.Get('P1');
                    NmParent.Delete(true);
                end;
            101:
                begin
                    P11.Get('P1');
                    P11.Delete(true);
                end;
            102:
                begin
                    P11b.Get('P1');
                    P11b.Delete(true);
                end;
            121:
                begin
                    P12e.Get('P1');
                    P12e.Delete(true);
                end;
            122:
                begin
                    P12s.Get('P1');
                    P12s.Delete(true);
                end;
            131:
                begin
                    NmParent.Get('P1');
                    NmParent.Delete(false);
                    NmParent.Insert();
                    NmParent.Delete(true);
                end;
        end;
        Error('LT NT ok');
    end;
}
