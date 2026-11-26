// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 75730..75735 and the interface OVB Confirmer (OVB Doc, OVB Lib,
//   OVB Confirmer Impl, OVB Var Hop Tests, OVB Callee Body Tests, OVB Other Callers Tests)
// local object: an Option handed to a var Option parameter that declares the members " ",Skip,Update, from a caller with
//   another member list, is what is under test.
// Probe (al-runner issue 8971, follow-up of OptionVarMemberLists.al and OptionVarMemberlessDirectCallers.al): the callee is a
//   var parameter Option " ",Skip,Update of a table procedure, a codeunit procedure, a local procedure or an interface method.
//   Cells: (1) the caller is a procedure's memberless var parameter whose own caller holds " ",Skip,Update (0, 1, 2, 5), a
//   memberless Option (0, 1, 5) or First,...,Sixth (1, 5); the hop in the test codeunit, in a table, in another codeunit, or
//   two hops; read only and with Choice := Choice::Update. (2) In the callee: Evaluate of 'Skip', 'Second', '5', 'update' and
//   'Nope' with the result used, Evaluate of 'Nope' and 'Second' as a statement, Clear, := 1, a hand-on to a memberless var
//   parameter and to a memberless by-value parameter, an error after the write; for the memberless var parameter caller and
//   for a memberless local and global caller; the caller's variable used again after Clear. (3) Direct callers: a memberless
//   local, global, by-value parameter and named return value; a local, global, var parameter, by-value parameter and named
//   return value with First,...,Sixth; fields with those members (with and without OptionCaption) of a local and a global
//   record, of a var record parameter and of Rec; an interface method called with a memberless local or global or a local
//   with First,...,Sixth.
// Facts: values are Format|ordinal.
//   A memberless var parameter handed on to the callee: the callee reads the member list the value carries, not its own.
//   From " ",Skip,Update it shows Skip|1 and the case takes Skip; from a memberless Option it shows 1|1 (0|0, 5|5), and the
//   case goes by the ordinal; from First,...,Sixth it shows Second|1 and Sixth|5. Choice := Choice::Update then shows
//   Update|2, 2|2 or Third|2 in the callee, in each hop and in the first caller. The same for a table, codeunit, local or
//   interface callee, and through two hops. Evaluate takes the names of the value's list: 'Skip' fails for a memberless value
//   and for First,...,Sixth, 'Second' succeeds for First,...,Sixth, '5' always succeeds. A failed Evaluate statement raises
//   "'Nope' is not an option. The existing options are: " with the value's list ( ,Skip,Update; empty; First,...,Sixth).
//   Clear gives the blank member ( |0) for a memberless value and for " ",Skip,Update, First|0 for First,...,Sixth. After
//   that Clear the first caller's memberless local keeps the members " ",Skip,Update (:= 1 then shows Skip|1). An error
//   after the write leaves the write in the caller.
//   A direct caller: the callee reads its own list (Skip|1; 5|5 outside it) and the caller keeps its own list after the call
//   (memberless 1|1, and 2|2 after the write; First,...,Sixth Second|1 and Third|2; a caption field Two|1 and Three|2).
//   Evaluate in the callee uses " ",Skip,Update. Clear gives  |0 inside and 0|0 in a memberless caller, which keeps no members.
//   A by-value parameter shows the write (2|2, Third|2); its caller does not.
// BC versions: measured on 29.0 (local BC on Linux). 27.5 and 28.5: the corpus CI run of the pull request.
table 75730 "OVB Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Confirmed; Boolean) { }
        field(3; SeenText; Text[250]) { }
        field(4; AfterText; Text[250]) { }
        field(5; Opt; Option) { OptionMembers = First,Second,Third,Fourth,Fifth,Sixth; }
        field(6; OptCap; Option) { OptionMembers = First,Second,Third,Fourth,Fifth,Sixth; OptionCaption = 'One,Two,Three,Four,Five,Six'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    // The callee: a var Option parameter with the members " ",Skip,Update. Reads it (Format, ordinal, compare, case) and,
    // when Write is true, assigns a member.
    procedure Confirm(var Choice: Option " ",Skip,Update; Write: Boolean) Result: Text
    begin
        Result := Format(Choice) + '|' + Format(Choice, 0, 2) + '|' + Format(Choice = Choice::Skip);
        case Choice of
            Choice::" ":
                Result += '|blank';
            Choice::Skip:
                Result += '|skip';
            Choice::Update:
                Result += '|update';
            else
                Result += '|else';
        end;
        if Write then begin
            Choice := Choice::Update;
            Result += '|' + Format(Choice) + '|' + Format(Choice, 0, 2);
        end;
    end;

    // The callee of the batch shape: leaves at Skip, asks once at the blank member and remembers the answer.
    procedure ConfirmOnce(var Choice: Option " ",Skip,Update) Result: Text
    begin
        if Choice = Choice::Skip then
            exit('skip-exit');
        case Choice of
            Choice::" ":
                begin
                    Result := 'blank';
                    if Confirmed then
                        Choice := Choice::Update
                    else
                        Choice := Choice::Skip;
                end;
            Choice::Update:
                Result := 'update';
            else
                Result := 'else ' + Format(Choice);
        end;
    end;

    // Other statements on the parameter: 1 Evaluate 'Skip', 2 Evaluate 'Second', 3 Evaluate '5', 4 Clear, 5 := 1 (Integer),
    // 6 hand on to a memberless var parameter, 7 hand on to a memberless by-value parameter, 8 Evaluate 'update',
    // 9 Evaluate 'Nope'. Then Format and ordinal.
    procedure ConfirmOp(var Choice: Option " ",Skip,Update; Op: Integer) Result: Text
    var
        Lib: Codeunit "OVB Lib";
    begin
        case Op of
            1:
                Result := Format(Evaluate(Choice, 'Skip'));
            2:
                Result := Format(Evaluate(Choice, 'Second'));
            3:
                Result := Format(Evaluate(Choice, '5'));
            4:
                Clear(Choice);
            5:
                Choice := 1;
            6:
                Result := Lib.HandOnMemberless(Choice);
            7:
                Result := Lib.HandOnByValue(Choice);
            8:
                Result := Format(Evaluate(Choice, 'update'));
            9:
                Result := Format(Evaluate(Choice, 'Nope'));
        end;
        Result += '>' + Format(Choice) + '|' + Format(Choice, 0, 2);
    end;

    procedure EvaluateStatement(var Choice: Option " ",Skip,Update; Txt: Text)
    begin
        Evaluate(Choice, Txt);
    end;

    procedure WriteThenError(var Choice: Option " ",Skip,Update)
    begin
        Choice := Choice::Update;
        Error('stop after the write');
    end;

    // A memberless var parameter of the table handed on to the table's own callee.
    procedure HopInTable(var V: Option; Write: Boolean; var After: Text) Result: Text
    begin
        Result := Confirm(V, Write);
        After := Format(V) + '|' + Format(V, 0, 2);
    end;

    // Rec's own fields handed to the callee.
    procedure RecFieldToConfirm(Write: Boolean) Result: Text
    begin
        Result := Confirm(Opt, Write);
    end;

    procedure RecCaptionFieldToConfirm(Write: Boolean) Result: Text
    begin
        Result := Confirm(OptCap, Write);
    end;
}

// A callee in a codeunit, a memberless var parameter in another codeunit than the caller, and the hand-on targets.
codeunit 75731 "OVB Lib"
{
    procedure Confirm(var Choice: Option " ",Skip,Update; Write: Boolean) Result: Text
    begin
        Result := Format(Choice) + '|' + Format(Choice, 0, 2) + '|' + Format(Choice = Choice::Skip);
        if Write then begin
            Choice := Choice::Update;
            Result += '|' + Format(Choice) + '|' + Format(Choice, 0, 2);
        end;
    end;

    procedure HopToTable(var V: Option; Write: Boolean; var After: Text) Result: Text
    var
        Doc: Record "OVB Doc";
    begin
        Result := Doc.Confirm(V, Write);
        After := Format(V) + '|' + Format(V, 0, 2);
    end;

    procedure HandOnMemberless(var V: Option): Text
    begin
        exit('m ' + Format(V) + '|' + Format(V, 0, 2));
    end;

    procedure HandOnByValue(V: Option): Text
    begin
        exit('b ' + Format(V) + '|' + Format(V, 0, 2));
    end;
}

interface "OVB Confirmer"
{
    procedure Confirm(var Choice: Option " ",Skip,Update; Write: Boolean): Text;
}

codeunit 75732 "OVB Confirmer Impl" implements "OVB Confirmer"
{
    procedure Confirm(var Choice: Option " ",Skip,Update; Write: Boolean) Result: Text
    begin
        Result := Format(Choice) + '|' + Format(Choice, 0, 2) + '|' + Format(Choice = Choice::Skip);
        if Write then begin
            Choice := Choice::Update;
            Result += '|' + Format(Choice) + '|' + Format(Choice, 0, 2);
        end;
    end;
}

codeunit 75733 "OVB Var Hop Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure VarHop_Same_Table()
    var
        Observer: Codeunit "Probe Observer";
        V: Option " ",Skip,Update;
        Inside: Text;
        Hop: Text;
    begin
        V := 0;
        Inside := HopToTable(V, false, Hop);
        Observer.Observe('0 read inside', Inside);
        Observer.Observe('0 read hop', Hop);
        Observer.Observe('0 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 0;
        Inside := HopToTable(V, true, Hop);
        Observer.Observe('0 write inside', Inside);
        Observer.Observe('0 write hop', Hop);
        Observer.Observe('0 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToTable(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToTable(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 2;
        Inside := HopToTable(V, false, Hop);
        Observer.Observe('2 read inside', Inside);
        Observer.Observe('2 read hop', Hop);
        Observer.Observe('2 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 2;
        Inside := HopToTable(V, true, Hop);
        Observer.Observe('2 write inside', Inside);
        Observer.Observe('2 write hop', Hop);
        Observer.Observe('2 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToTable(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToTable(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('0 read inside', ' |0|No|blank');
        Observer.Expect('0 read hop', ' |0');
        Observer.Expect('0 read caller', ' |0');
        Observer.Expect('0 write inside', ' |0|No|blank|Update|2');
        Observer.Expect('0 write hop', 'Update|2');
        Observer.Expect('0 write caller', 'Update|2');
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read hop', 'Skip|1');
        Observer.Expect('1 read caller', 'Skip|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write hop', 'Update|2');
        Observer.Expect('1 write caller', 'Update|2');
        Observer.Expect('2 read inside', 'Update|2|No|update');
        Observer.Expect('2 read hop', 'Update|2');
        Observer.Expect('2 read caller', 'Update|2');
        Observer.Expect('2 write inside', 'Update|2|No|update|Update|2');
        Observer.Expect('2 write hop', 'Update|2');
        Observer.Expect('2 write caller', 'Update|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write hop', 'Update|2');
        Observer.Expect('5 write caller', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Memberless_Table()
    var
        Observer: Codeunit "Probe Observer";
        V: Option;
        Inside: Text;
        Hop: Text;
    begin
        V := 0;
        Inside := HopToTable(V, false, Hop);
        Observer.Observe('0 read inside', Inside);
        Observer.Observe('0 read hop', Hop);
        Observer.Observe('0 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 0;
        Inside := HopToTable(V, true, Hop);
        Observer.Observe('0 write inside', Inside);
        Observer.Observe('0 write hop', Hop);
        Observer.Observe('0 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToTable(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToTable(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToTable(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToTable(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('0 read inside', '0|0|No|blank');
        Observer.Expect('0 read hop', '0|0');
        Observer.Expect('0 read caller', '0|0');
        Observer.Expect('0 write inside', '0|0|No|blank|2|2');
        Observer.Expect('0 write hop', '2|2');
        Observer.Expect('0 write caller', '2|2');
        Observer.Expect('1 read inside', '1|1|Yes|skip');
        Observer.Expect('1 read hop', '1|1');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', '1|1|Yes|skip|2|2');
        Observer.Expect('1 write hop', '2|2');
        Observer.Expect('1 write caller', '2|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|2|2');
        Observer.Expect('5 write hop', '2|2');
        Observer.Expect('5 write caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Other_Table()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopToTable(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToTable(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToTable(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToTable(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Second|1|Yes|skip');
        Observer.Expect('1 read hop', 'Second|1');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Second|1|Yes|skip|Third|2');
        Observer.Expect('1 write hop', 'Third|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', 'Sixth|5|No|else');
        Observer.Expect('5 read hop', 'Sixth|5');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', 'Sixth|5|No|else|Third|2');
        Observer.Expect('5 write hop', 'Third|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Same_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
        V: Option " ",Skip,Update;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopToLib(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToLib(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLib(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLib(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes');
        Observer.Expect('1 read hop', 'Skip|1');
        Observer.Expect('1 read caller', 'Skip|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|Update|2');
        Observer.Expect('1 write hop', 'Update|2');
        Observer.Expect('1 write caller', 'Update|2');
        Observer.Expect('5 read inside', '5|5|No');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|Update|2');
        Observer.Expect('5 write hop', 'Update|2');
        Observer.Expect('5 write caller', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Memberless_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
        V: Option;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopToLib(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToLib(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLib(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLib(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', '1|1|Yes');
        Observer.Expect('1 read hop', '1|1');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', '1|1|Yes|2|2');
        Observer.Expect('1 write hop', '2|2');
        Observer.Expect('1 write caller', '2|2');
        Observer.Expect('5 read inside', '5|5|No');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|2|2');
        Observer.Expect('5 write hop', '2|2');
        Observer.Expect('5 write caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Other_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopToLib(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToLib(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLib(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLib(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Second|1|Yes');
        Observer.Expect('1 read hop', 'Second|1');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Second|1|Yes|Third|2');
        Observer.Expect('1 write hop', 'Third|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', 'Sixth|5|No');
        Observer.Expect('5 read hop', 'Sixth|5');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', 'Sixth|5|No|Third|2');
        Observer.Expect('5 write hop', 'Third|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Same_Local()
    var
        Observer: Codeunit "Probe Observer";
        V: Option " ",Skip,Update;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopToLocal(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToLocal(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLocal(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLocal(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes');
        Observer.Expect('1 read hop', 'Skip|1');
        Observer.Expect('1 read caller', 'Skip|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|Update|2');
        Observer.Expect('1 write hop', 'Update|2');
        Observer.Expect('1 write caller', 'Update|2');
        Observer.Expect('5 read inside', '5|5|No');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|Update|2');
        Observer.Expect('5 write hop', 'Update|2');
        Observer.Expect('5 write caller', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Memberless_Local()
    var
        Observer: Codeunit "Probe Observer";
        V: Option;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopToLocal(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToLocal(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLocal(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLocal(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', '1|1|Yes');
        Observer.Expect('1 read hop', '1|1');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', '1|1|Yes|2|2');
        Observer.Expect('1 write hop', '2|2');
        Observer.Expect('1 write caller', '2|2');
        Observer.Expect('5 read inside', '5|5|No');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|2|2');
        Observer.Expect('5 write hop', '2|2');
        Observer.Expect('5 write caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Other_Local()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopToLocal(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToLocal(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLocal(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToLocal(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Second|1|Yes');
        Observer.Expect('1 read hop', 'Second|1');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Second|1|Yes|Third|2');
        Observer.Expect('1 write hop', 'Third|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', 'Sixth|5|No');
        Observer.Expect('5 read hop', 'Sixth|5');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', 'Sixth|5|No|Third|2');
        Observer.Expect('5 write hop', 'Third|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Same_TableHop()
    var
        Observer: Codeunit "Probe Observer";
        V: Option " ",Skip,Update;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopInTableProc(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopInTableProc(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopInTableProc(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopInTableProc(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read hop', 'Skip|1');
        Observer.Expect('1 read caller', 'Skip|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write hop', 'Update|2');
        Observer.Expect('1 write caller', 'Update|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write hop', 'Update|2');
        Observer.Expect('5 write caller', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Memberless_TableHop()
    var
        Observer: Codeunit "Probe Observer";
        V: Option;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopInTableProc(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopInTableProc(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopInTableProc(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopInTableProc(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', '1|1|Yes|skip');
        Observer.Expect('1 read hop', '1|1');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', '1|1|Yes|skip|2|2');
        Observer.Expect('1 write hop', '2|2');
        Observer.Expect('1 write caller', '2|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|2|2');
        Observer.Expect('5 write hop', '2|2');
        Observer.Expect('5 write caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Other_TableHop()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopInTableProc(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopInTableProc(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopInTableProc(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopInTableProc(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Second|1|Yes|skip');
        Observer.Expect('1 read hop', 'Second|1');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Second|1|Yes|skip|Third|2');
        Observer.Expect('1 write hop', 'Third|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', 'Sixth|5|No|else');
        Observer.Expect('5 read hop', 'Sixth|5');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', 'Sixth|5|No|else|Third|2');
        Observer.Expect('5 write hop', 'Third|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Same_LibHop()
    var
        Observer: Codeunit "Probe Observer";
        V: Option " ",Skip,Update;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopViaLib(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopViaLib(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopViaLib(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopViaLib(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read hop', 'Skip|1');
        Observer.Expect('1 read caller', 'Skip|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write hop', 'Update|2');
        Observer.Expect('1 write caller', 'Update|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write hop', 'Update|2');
        Observer.Expect('5 write caller', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Memberless_LibHop()
    var
        Observer: Codeunit "Probe Observer";
        V: Option;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopViaLib(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopViaLib(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopViaLib(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopViaLib(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', '1|1|Yes|skip');
        Observer.Expect('1 read hop', '1|1');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', '1|1|Yes|skip|2|2');
        Observer.Expect('1 write hop', '2|2');
        Observer.Expect('1 write caller', '2|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|2|2');
        Observer.Expect('5 write hop', '2|2');
        Observer.Expect('5 write caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Other_LibHop()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopViaLib(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopViaLib(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopViaLib(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopViaLib(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Second|1|Yes|skip');
        Observer.Expect('1 read hop', 'Second|1');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Second|1|Yes|skip|Third|2');
        Observer.Expect('1 write hop', 'Third|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', 'Sixth|5|No|else');
        Observer.Expect('5 read hop', 'Sixth|5');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', 'Sixth|5|No|else|Third|2');
        Observer.Expect('5 write hop', 'Third|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Same_Interface()
    var
        Observer: Codeunit "Probe Observer";
        V: Option " ",Skip,Update;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopToInterface(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToInterface(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToInterface(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToInterface(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes');
        Observer.Expect('1 read hop', 'Skip|1');
        Observer.Expect('1 read caller', 'Skip|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|Update|2');
        Observer.Expect('1 write hop', 'Update|2');
        Observer.Expect('1 write caller', 'Update|2');
        Observer.Expect('5 read inside', '5|5|No');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|Update|2');
        Observer.Expect('5 write hop', 'Update|2');
        Observer.Expect('5 write caller', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Memberless_Interface()
    var
        Observer: Codeunit "Probe Observer";
        V: Option;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopToInterface(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToInterface(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToInterface(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToInterface(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', '1|1|Yes');
        Observer.Expect('1 read hop', '1|1');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', '1|1|Yes|2|2');
        Observer.Expect('1 write hop', '2|2');
        Observer.Expect('1 write caller', '2|2');
        Observer.Expect('5 read inside', '5|5|No');
        Observer.Expect('5 read hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|2|2');
        Observer.Expect('5 write hop', '2|2');
        Observer.Expect('5 write caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Other_Interface()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopToInterface(V, false, Hop);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read hop', Hop);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopToInterface(V, true, Hop);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write hop', Hop);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToInterface(V, false, Hop);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read hop', Hop);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopToInterface(V, true, Hop);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write hop', Hop);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Second|1|Yes');
        Observer.Expect('1 read hop', 'Second|1');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Second|1|Yes|Third|2');
        Observer.Expect('1 write hop', 'Third|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', 'Sixth|5|No');
        Observer.Expect('5 read hop', 'Sixth|5');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', 'Sixth|5|No|Third|2');
        Observer.Expect('5 write hop', 'Third|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Same_TwoHops()
    var
        Observer: Codeunit "Probe Observer";
        V: Option " ",Skip,Update;
        Inside: Text;
        Hop1: Text;
        Hop2: Text;
    begin
        V := 1;
        Inside := HopTwice(V, false, Hop1, Hop2);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read inner hop', Hop2);
        Observer.Observe('1 read outer hop', Hop1);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopTwice(V, true, Hop1, Hop2);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write inner hop', Hop2);
        Observer.Observe('1 write outer hop', Hop1);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopTwice(V, false, Hop1, Hop2);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read inner hop', Hop2);
        Observer.Observe('5 read outer hop', Hop1);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopTwice(V, true, Hop1, Hop2);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write inner hop', Hop2);
        Observer.Observe('5 write outer hop', Hop1);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read inner hop', 'Skip|1');
        Observer.Expect('1 read outer hop', 'Skip|1');
        Observer.Expect('1 read caller', 'Skip|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write inner hop', 'Update|2');
        Observer.Expect('1 write outer hop', 'Update|2');
        Observer.Expect('1 write caller', 'Update|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read inner hop', '5|5');
        Observer.Expect('5 read outer hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write inner hop', 'Update|2');
        Observer.Expect('5 write outer hop', 'Update|2');
        Observer.Expect('5 write caller', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Memberless_TwoHops()
    var
        Observer: Codeunit "Probe Observer";
        V: Option;
        Inside: Text;
        Hop1: Text;
        Hop2: Text;
    begin
        V := 1;
        Inside := HopTwice(V, false, Hop1, Hop2);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read inner hop', Hop2);
        Observer.Observe('1 read outer hop', Hop1);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopTwice(V, true, Hop1, Hop2);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write inner hop', Hop2);
        Observer.Observe('1 write outer hop', Hop1);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopTwice(V, false, Hop1, Hop2);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read inner hop', Hop2);
        Observer.Observe('5 read outer hop', Hop1);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopTwice(V, true, Hop1, Hop2);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write inner hop', Hop2);
        Observer.Observe('5 write outer hop', Hop1);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', '1|1|Yes|skip');
        Observer.Expect('1 read inner hop', '1|1');
        Observer.Expect('1 read outer hop', '1|1');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', '1|1|Yes|skip|2|2');
        Observer.Expect('1 write inner hop', '2|2');
        Observer.Expect('1 write outer hop', '2|2');
        Observer.Expect('1 write caller', '2|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read inner hop', '5|5');
        Observer.Expect('5 read outer hop', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|2|2');
        Observer.Expect('5 write inner hop', '2|2');
        Observer.Expect('5 write outer hop', '2|2');
        Observer.Expect('5 write caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarHop_Other_TwoHops()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        Hop1: Text;
        Hop2: Text;
    begin
        V := 1;
        Inside := HopTwice(V, false, Hop1, Hop2);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read inner hop', Hop2);
        Observer.Observe('1 read outer hop', Hop1);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := HopTwice(V, true, Hop1, Hop2);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write inner hop', Hop2);
        Observer.Observe('1 write outer hop', Hop1);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopTwice(V, false, Hop1, Hop2);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read inner hop', Hop2);
        Observer.Observe('5 read outer hop', Hop1);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := HopTwice(V, true, Hop1, Hop2);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write inner hop', Hop2);
        Observer.Observe('5 write outer hop', Hop1);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Second|1|Yes|skip');
        Observer.Expect('1 read inner hop', 'Second|1');
        Observer.Expect('1 read outer hop', 'Second|1');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Second|1|Yes|skip|Third|2');
        Observer.Expect('1 write inner hop', 'Third|2');
        Observer.Expect('1 write outer hop', 'Third|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', 'Sixth|5|No|else');
        Observer.Expect('5 read inner hop', 'Sixth|5');
        Observer.Expect('5 read outer hop', 'Sixth|5');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', 'Sixth|5|No|else|Third|2');
        Observer.Expect('5 write inner hop', 'Third|2');
        Observer.Expect('5 write outer hop', 'Third|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    local procedure HopToTable(var V: Option; Write: Boolean; var After: Text) Result: Text
    var
        Doc: Record "OVB Doc";
    begin
        Result := Doc.Confirm(V, Write);
        After := Format(V) + '|' + Format(V, 0, 2);
    end;

    local procedure HopToLib(var V: Option; Write: Boolean; var After: Text) Result: Text
    var
        Lib: Codeunit "OVB Lib";
    begin
        Result := Lib.Confirm(V, Write);
        After := Format(V) + '|' + Format(V, 0, 2);
    end;

    local procedure HopToLocal(var V: Option; Write: Boolean; var After: Text) Result: Text
    begin
        Result := LocalConfirm(V, Write);
        After := Format(V) + '|' + Format(V, 0, 2);
    end;

    local procedure LocalConfirm(var Choice: Option " ",Skip,Update; Write: Boolean) Result: Text
    begin
        Result := Format(Choice) + '|' + Format(Choice, 0, 2) + '|' + Format(Choice = Choice::Skip);
        if Write then begin
            Choice := Choice::Update;
            Result += '|' + Format(Choice) + '|' + Format(Choice, 0, 2);
        end;
    end;

    local procedure HopInTableProc(var V: Option; Write: Boolean; var After: Text): Text
    var
        Doc: Record "OVB Doc";
    begin
        exit(Doc.HopInTable(V, Write, After));
    end;

    local procedure HopViaLib(var V: Option; Write: Boolean; var After: Text): Text
    var
        Lib: Codeunit "OVB Lib";
    begin
        exit(Lib.HopToTable(V, Write, After));
    end;

    local procedure HopToInterface(var V: Option; Write: Boolean; var After: Text) Result: Text
    var
        Impl: Codeunit "OVB Confirmer Impl";
        Confirmer: Interface "OVB Confirmer";
    begin
        Confirmer := Impl;
        Result := Confirmer.Confirm(V, Write);
        After := Format(V) + '|' + Format(V, 0, 2);
    end;

    local procedure HopTwice(var V: Option; Write: Boolean; var Outer: Text; var Inner: Text) Result: Text
    begin
        Result := HopToTable(V, Write, Inner);
        Outer := Format(V) + '|' + Format(V, 0, 2);
    end;
}

codeunit 75734 "OVB Callee Body Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CalleeOps_VarHop_Same()
    var
        Observer: Codeunit "Probe Observer";
        V1, V2, V3, V5, V6, V7, V8, V9, V4: Option " ",Skip,Update;
        Inside: Text;
        Hop: Text;
    begin
        V1 := 2;
        Inside := HopOp(V1, 1, Hop);
        Observer.Observe('Evaluate Skip inside', Inside);
        Observer.Observe('Evaluate Skip hop', Hop);
        Observer.Observe('Evaluate Skip caller', Format(V1) + '|' + Format(V1, 0, 2));
        V2 := 2;
        Inside := HopOp(V2, 2, Hop);
        Observer.Observe('Evaluate Second inside', Inside);
        Observer.Observe('Evaluate Second hop', Hop);
        Observer.Observe('Evaluate Second caller', Format(V2) + '|' + Format(V2, 0, 2));
        V3 := 2;
        Inside := HopOp(V3, 3, Hop);
        Observer.Observe('Evaluate 5 inside', Inside);
        Observer.Observe('Evaluate 5 hop', Hop);
        Observer.Observe('Evaluate 5 caller', Format(V3) + '|' + Format(V3, 0, 2));
        V5 := 2;
        Inside := HopOp(V5, 5, Hop);
        Observer.Observe('Integer 1 inside', Inside);
        Observer.Observe('Integer 1 hop', Hop);
        Observer.Observe('Integer 1 caller', Format(V5) + '|' + Format(V5, 0, 2));
        V6 := 2;
        Inside := HopOp(V6, 6, Hop);
        Observer.Observe('hand on var inside', Inside);
        Observer.Observe('hand on var hop', Hop);
        Observer.Observe('hand on var caller', Format(V6) + '|' + Format(V6, 0, 2));
        V7 := 2;
        Inside := HopOp(V7, 7, Hop);
        Observer.Observe('hand on by value inside', Inside);
        Observer.Observe('hand on by value hop', Hop);
        Observer.Observe('hand on by value caller', Format(V7) + '|' + Format(V7, 0, 2));
        V8 := 2;
        Inside := HopOp(V8, 8, Hop);
        Observer.Observe('Evaluate update inside', Inside);
        Observer.Observe('Evaluate update hop', Hop);
        Observer.Observe('Evaluate update caller', Format(V8) + '|' + Format(V8, 0, 2));
        V9 := 2;
        Inside := HopOp(V9, 9, Hop);
        Observer.Observe('Evaluate Nope inside', Inside);
        Observer.Observe('Evaluate Nope hop', Hop);
        Observer.Observe('Evaluate Nope caller', Format(V9) + '|' + Format(V9, 0, 2));
        V4 := 2;
        Inside := HopOp(V4, 4, Hop);
        Observer.Observe('Clear inside', Inside);
        Observer.Observe('Clear hop', Hop);
        Observer.Observe('Clear caller', Format(V4) + '|' + Format(V4, 0, 2));
        Observer.Expect('Evaluate Skip inside', 'Yes>Skip|1');
        Observer.Expect('Evaluate Skip hop', 'Skip|1');
        Observer.Expect('Evaluate Skip caller', 'Skip|1');
        Observer.Expect('Evaluate Second inside', 'No>Update|2');
        Observer.Expect('Evaluate Second hop', 'Update|2');
        Observer.Expect('Evaluate Second caller', 'Update|2');
        Observer.Expect('Evaluate 5 inside', 'Yes>5|5');
        Observer.Expect('Evaluate 5 hop', '5|5');
        Observer.Expect('Evaluate 5 caller', '5|5');
        Observer.Expect('Integer 1 inside', '>Skip|1');
        Observer.Expect('Integer 1 hop', 'Skip|1');
        Observer.Expect('Integer 1 caller', 'Skip|1');
        Observer.Expect('hand on var inside', 'm Update|2>Update|2');
        Observer.Expect('hand on var hop', 'Update|2');
        Observer.Expect('hand on var caller', 'Update|2');
        Observer.Expect('hand on by value inside', 'b 2|2>Update|2');
        Observer.Expect('hand on by value hop', 'Update|2');
        Observer.Expect('hand on by value caller', 'Update|2');
        Observer.Expect('Evaluate update inside', 'Yes>Update|2');
        Observer.Expect('Evaluate update hop', 'Update|2');
        Observer.Expect('Evaluate update caller', 'Update|2');
        Observer.Expect('Evaluate Nope inside', 'No>Update|2');
        Observer.Expect('Evaluate Nope hop', 'Update|2');
        Observer.Expect('Evaluate Nope caller', 'Update|2');
        Observer.Expect('Clear inside', '> |0');
        Observer.Expect('Clear hop', ' |0');
        Observer.Expect('Clear caller', ' |0');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeErrors_VarHop_Same()
    var
        Observer: Codeunit "Probe Observer";
        V: Option " ",Skip,Update;
    begin
        V := 2;
        asserterror HopEvaluate(V, 'Nope');
        Observer.ObserveError('Evaluate Nope statement');
        Observer.Observe('Evaluate Nope caller', Format(V) + '|' + Format(V, 0, 2));
        V := 2;
        asserterror HopEvaluate(V, 'Second');
        Observer.ObserveError('Evaluate Second statement');
        Observer.Observe('Evaluate Second caller', Format(V) + '|' + Format(V, 0, 2));
        V := 2;
        asserterror HopWriteThenError(V);
        Observer.ObserveError('write then error');
        Observer.Observe('write then error caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('Evaluate Nope statement|text', '''Nope'' is not an option. The existing options are:  ,Skip,Update');
        Observer.Expect('Evaluate Nope statement|code', 'InvalidOptionString');
        Observer.Expect('Evaluate Nope caller', 'Update|2');
        Observer.Expect('Evaluate Second statement|text', '''Second'' is not an option. The existing options are:  ,Skip,Update');
        Observer.Expect('Evaluate Second statement|code', 'InvalidOptionString');
        Observer.Expect('Evaluate Second caller', 'Update|2');
        Observer.Expect('write then error|text', 'stop after the write');
        Observer.Expect('write then error|code', 'Dialog');
        Observer.Expect('write then error caller', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeOps_VarHop_Memberless()
    var
        Observer: Codeunit "Probe Observer";
        V1, V2, V3, V5, V6, V7, V8, V9, V4: Option;
        Inside: Text;
        Hop: Text;
    begin
        V1 := 1;
        Inside := HopOp(V1, 1, Hop);
        Observer.Observe('Evaluate Skip inside', Inside);
        Observer.Observe('Evaluate Skip hop', Hop);
        Observer.Observe('Evaluate Skip caller', Format(V1) + '|' + Format(V1, 0, 2));
        V2 := 1;
        Inside := HopOp(V2, 2, Hop);
        Observer.Observe('Evaluate Second inside', Inside);
        Observer.Observe('Evaluate Second hop', Hop);
        Observer.Observe('Evaluate Second caller', Format(V2) + '|' + Format(V2, 0, 2));
        V3 := 1;
        Inside := HopOp(V3, 3, Hop);
        Observer.Observe('Evaluate 5 inside', Inside);
        Observer.Observe('Evaluate 5 hop', Hop);
        Observer.Observe('Evaluate 5 caller', Format(V3) + '|' + Format(V3, 0, 2));
        V5 := 1;
        Inside := HopOp(V5, 5, Hop);
        Observer.Observe('Integer 1 inside', Inside);
        Observer.Observe('Integer 1 hop', Hop);
        Observer.Observe('Integer 1 caller', Format(V5) + '|' + Format(V5, 0, 2));
        V6 := 1;
        Inside := HopOp(V6, 6, Hop);
        Observer.Observe('hand on var inside', Inside);
        Observer.Observe('hand on var hop', Hop);
        Observer.Observe('hand on var caller', Format(V6) + '|' + Format(V6, 0, 2));
        V7 := 1;
        Inside := HopOp(V7, 7, Hop);
        Observer.Observe('hand on by value inside', Inside);
        Observer.Observe('hand on by value hop', Hop);
        Observer.Observe('hand on by value caller', Format(V7) + '|' + Format(V7, 0, 2));
        V8 := 1;
        Inside := HopOp(V8, 8, Hop);
        Observer.Observe('Evaluate update inside', Inside);
        Observer.Observe('Evaluate update hop', Hop);
        Observer.Observe('Evaluate update caller', Format(V8) + '|' + Format(V8, 0, 2));
        V9 := 1;
        Inside := HopOp(V9, 9, Hop);
        Observer.Observe('Evaluate Nope inside', Inside);
        Observer.Observe('Evaluate Nope hop', Hop);
        Observer.Observe('Evaluate Nope caller', Format(V9) + '|' + Format(V9, 0, 2));
        V4 := 1;
        Inside := HopOp(V4, 4, Hop);
        Observer.Observe('Clear inside', Inside);
        Observer.Observe('Clear hop', Hop);
        Observer.Observe('Clear caller', Format(V4) + '|' + Format(V4, 0, 2));
        Observer.Expect('Evaluate Skip inside', 'No>1|1');
        Observer.Expect('Evaluate Skip hop', '1|1');
        Observer.Expect('Evaluate Skip caller', '1|1');
        Observer.Expect('Evaluate Second inside', 'No>1|1');
        Observer.Expect('Evaluate Second hop', '1|1');
        Observer.Expect('Evaluate Second caller', '1|1');
        Observer.Expect('Evaluate 5 inside', 'Yes>5|5');
        Observer.Expect('Evaluate 5 hop', '5|5');
        Observer.Expect('Evaluate 5 caller', '5|5');
        Observer.Expect('Integer 1 inside', '>1|1');
        Observer.Expect('Integer 1 hop', '1|1');
        Observer.Expect('Integer 1 caller', '1|1');
        Observer.Expect('hand on var inside', 'm 1|1>1|1');
        Observer.Expect('hand on var hop', '1|1');
        Observer.Expect('hand on var caller', '1|1');
        Observer.Expect('hand on by value inside', 'b 1|1>1|1');
        Observer.Expect('hand on by value hop', '1|1');
        Observer.Expect('hand on by value caller', '1|1');
        Observer.Expect('Evaluate update inside', 'No>1|1');
        Observer.Expect('Evaluate update hop', '1|1');
        Observer.Expect('Evaluate update caller', '1|1');
        Observer.Expect('Evaluate Nope inside', 'No>1|1');
        Observer.Expect('Evaluate Nope hop', '1|1');
        Observer.Expect('Evaluate Nope caller', '1|1');
        Observer.Expect('Clear inside', '> |0');
        Observer.Expect('Clear hop', ' |0');
        Observer.Expect('Clear caller', ' |0');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeErrors_VarHop_Memberless()
    var
        Observer: Codeunit "Probe Observer";
        V: Option;
    begin
        V := 1;
        asserterror HopEvaluate(V, 'Nope');
        Observer.ObserveError('Evaluate Nope statement');
        Observer.Observe('Evaluate Nope caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        asserterror HopEvaluate(V, 'Second');
        Observer.ObserveError('Evaluate Second statement');
        Observer.Observe('Evaluate Second caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        asserterror HopWriteThenError(V);
        Observer.ObserveError('write then error');
        Observer.Observe('write then error caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('Evaluate Nope statement|text', '''Nope'' is not an option. The existing options are: ');
        Observer.Expect('Evaluate Nope statement|code', 'InvalidOptionString');
        Observer.Expect('Evaluate Nope caller', '1|1');
        Observer.Expect('Evaluate Second statement|text', '''Second'' is not an option. The existing options are: ');
        Observer.Expect('Evaluate Second statement|code', 'InvalidOptionString');
        Observer.Expect('Evaluate Second caller', '1|1');
        Observer.Expect('write then error|text', 'stop after the write');
        Observer.Expect('write then error|code', 'Dialog');
        Observer.Expect('write then error caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeOps_VarHop_Other()
    var
        Observer: Codeunit "Probe Observer";
        V1, V2, V3, V5, V6, V7, V8, V9, V4: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        Hop: Text;
    begin
        V1 := 4;
        Inside := HopOp(V1, 1, Hop);
        Observer.Observe('Evaluate Skip inside', Inside);
        Observer.Observe('Evaluate Skip hop', Hop);
        Observer.Observe('Evaluate Skip caller', Format(V1) + '|' + Format(V1, 0, 2));
        V2 := 4;
        Inside := HopOp(V2, 2, Hop);
        Observer.Observe('Evaluate Second inside', Inside);
        Observer.Observe('Evaluate Second hop', Hop);
        Observer.Observe('Evaluate Second caller', Format(V2) + '|' + Format(V2, 0, 2));
        V3 := 4;
        Inside := HopOp(V3, 3, Hop);
        Observer.Observe('Evaluate 5 inside', Inside);
        Observer.Observe('Evaluate 5 hop', Hop);
        Observer.Observe('Evaluate 5 caller', Format(V3) + '|' + Format(V3, 0, 2));
        V5 := 4;
        Inside := HopOp(V5, 5, Hop);
        Observer.Observe('Integer 1 inside', Inside);
        Observer.Observe('Integer 1 hop', Hop);
        Observer.Observe('Integer 1 caller', Format(V5) + '|' + Format(V5, 0, 2));
        V6 := 4;
        Inside := HopOp(V6, 6, Hop);
        Observer.Observe('hand on var inside', Inside);
        Observer.Observe('hand on var hop', Hop);
        Observer.Observe('hand on var caller', Format(V6) + '|' + Format(V6, 0, 2));
        V7 := 4;
        Inside := HopOp(V7, 7, Hop);
        Observer.Observe('hand on by value inside', Inside);
        Observer.Observe('hand on by value hop', Hop);
        Observer.Observe('hand on by value caller', Format(V7) + '|' + Format(V7, 0, 2));
        V8 := 4;
        Inside := HopOp(V8, 8, Hop);
        Observer.Observe('Evaluate update inside', Inside);
        Observer.Observe('Evaluate update hop', Hop);
        Observer.Observe('Evaluate update caller', Format(V8) + '|' + Format(V8, 0, 2));
        V9 := 4;
        Inside := HopOp(V9, 9, Hop);
        Observer.Observe('Evaluate Nope inside', Inside);
        Observer.Observe('Evaluate Nope hop', Hop);
        Observer.Observe('Evaluate Nope caller', Format(V9) + '|' + Format(V9, 0, 2));
        V4 := 4;
        Inside := HopOp(V4, 4, Hop);
        Observer.Observe('Clear inside', Inside);
        Observer.Observe('Clear hop', Hop);
        Observer.Observe('Clear caller', Format(V4) + '|' + Format(V4, 0, 2));
        Observer.Expect('Evaluate Skip inside', 'No>Fifth|4');
        Observer.Expect('Evaluate Skip hop', 'Fifth|4');
        Observer.Expect('Evaluate Skip caller', 'Fifth|4');
        Observer.Expect('Evaluate Second inside', 'Yes>Second|1');
        Observer.Expect('Evaluate Second hop', 'Second|1');
        Observer.Expect('Evaluate Second caller', 'Second|1');
        Observer.Expect('Evaluate 5 inside', 'Yes>Sixth|5');
        Observer.Expect('Evaluate 5 hop', 'Sixth|5');
        Observer.Expect('Evaluate 5 caller', 'Sixth|5');
        Observer.Expect('Integer 1 inside', '>Second|1');
        Observer.Expect('Integer 1 hop', 'Second|1');
        Observer.Expect('Integer 1 caller', 'Second|1');
        Observer.Expect('hand on var inside', 'm Fifth|4>Fifth|4');
        Observer.Expect('hand on var hop', 'Fifth|4');
        Observer.Expect('hand on var caller', 'Fifth|4');
        Observer.Expect('hand on by value inside', 'b 4|4>Fifth|4');
        Observer.Expect('hand on by value hop', 'Fifth|4');
        Observer.Expect('hand on by value caller', 'Fifth|4');
        Observer.Expect('Evaluate update inside', 'No>Fifth|4');
        Observer.Expect('Evaluate update hop', 'Fifth|4');
        Observer.Expect('Evaluate update caller', 'Fifth|4');
        Observer.Expect('Evaluate Nope inside', 'No>Fifth|4');
        Observer.Expect('Evaluate Nope hop', 'Fifth|4');
        Observer.Expect('Evaluate Nope caller', 'Fifth|4');
        Observer.Expect('Clear inside', '>First|0');
        Observer.Expect('Clear hop', 'First|0');
        Observer.Expect('Clear caller', 'First|0');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeErrors_VarHop_Other()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
    begin
        V := 4;
        asserterror HopEvaluate(V, 'Nope');
        Observer.ObserveError('Evaluate Nope statement');
        Observer.Observe('Evaluate Nope caller', Format(V) + '|' + Format(V, 0, 2));
        V := 4;
        HopEvaluate(V, 'Second');
        Observer.Observe('Evaluate Second statement', 'no error');
        Observer.Observe('Evaluate Second caller', Format(V) + '|' + Format(V, 0, 2));
        V := 4;
        asserterror HopWriteThenError(V);
        Observer.ObserveError('write then error');
        Observer.Observe('write then error caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('Evaluate Nope statement|text', '''Nope'' is not an option. The existing options are: First,Second,Third,Fourth,Fifth,Sixth');
        Observer.Expect('Evaluate Nope statement|code', 'InvalidOptionString');
        Observer.Expect('Evaluate Nope caller', 'Fifth|4');
        Observer.Expect('Evaluate Second statement', 'no error');
        Observer.Expect('Evaluate Second caller', 'Second|1');
        Observer.Expect('write then error|text', 'stop after the write');
        Observer.Expect('write then error|code', 'Dialog');
        Observer.Expect('write then error caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeOps_MemberlessLocal()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        V1, V2, V3, V5, V6, V7, V8, V9, V4: Option;
        Inside: Text;
    begin
        V1 := 1;
        Inside := Doc.ConfirmOp(V1, 1);
        Observer.Observe('Evaluate Skip inside', Inside);
        Observer.Observe('Evaluate Skip caller', Format(V1) + '|' + Format(V1, 0, 2));
        V2 := 1;
        Inside := Doc.ConfirmOp(V2, 2);
        Observer.Observe('Evaluate Second inside', Inside);
        Observer.Observe('Evaluate Second caller', Format(V2) + '|' + Format(V2, 0, 2));
        V3 := 1;
        Inside := Doc.ConfirmOp(V3, 3);
        Observer.Observe('Evaluate 5 inside', Inside);
        Observer.Observe('Evaluate 5 caller', Format(V3) + '|' + Format(V3, 0, 2));
        V5 := 1;
        Inside := Doc.ConfirmOp(V5, 5);
        Observer.Observe('Integer 1 inside', Inside);
        Observer.Observe('Integer 1 caller', Format(V5) + '|' + Format(V5, 0, 2));
        V6 := 1;
        Inside := Doc.ConfirmOp(V6, 6);
        Observer.Observe('hand on var inside', Inside);
        Observer.Observe('hand on var caller', Format(V6) + '|' + Format(V6, 0, 2));
        V7 := 1;
        Inside := Doc.ConfirmOp(V7, 7);
        Observer.Observe('hand on by value inside', Inside);
        Observer.Observe('hand on by value caller', Format(V7) + '|' + Format(V7, 0, 2));
        V8 := 1;
        Inside := Doc.ConfirmOp(V8, 8);
        Observer.Observe('Evaluate update inside', Inside);
        Observer.Observe('Evaluate update caller', Format(V8) + '|' + Format(V8, 0, 2));
        V9 := 1;
        Inside := Doc.ConfirmOp(V9, 9);
        Observer.Observe('Evaluate Nope inside', Inside);
        Observer.Observe('Evaluate Nope caller', Format(V9) + '|' + Format(V9, 0, 2));
        V4 := 1;
        Inside := Doc.ConfirmOp(V4, 4);
        Observer.Observe('Clear inside', Inside);
        Observer.Observe('Clear caller', Format(V4) + '|' + Format(V4, 0, 2));
        Observer.Expect('Evaluate Skip inside', 'Yes>Skip|1');
        Observer.Expect('Evaluate Skip caller', '1|1');
        Observer.Expect('Evaluate Second inside', 'No>Skip|1');
        Observer.Expect('Evaluate Second caller', '1|1');
        Observer.Expect('Evaluate 5 inside', 'Yes>5|5');
        Observer.Expect('Evaluate 5 caller', '5|5');
        Observer.Expect('Integer 1 inside', '>Skip|1');
        Observer.Expect('Integer 1 caller', '1|1');
        Observer.Expect('hand on var inside', 'm Skip|1>Skip|1');
        Observer.Expect('hand on var caller', '1|1');
        Observer.Expect('hand on by value inside', 'b 1|1>Skip|1');
        Observer.Expect('hand on by value caller', '1|1');
        Observer.Expect('Evaluate update inside', 'Yes>Update|2');
        Observer.Expect('Evaluate update caller', '2|2');
        Observer.Expect('Evaluate Nope inside', 'No>Skip|1');
        Observer.Expect('Evaluate Nope caller', '1|1');
        Observer.Expect('Clear inside', '> |0');
        Observer.Expect('Clear caller', '0|0');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeErrors_MemberlessLocal()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        V: Option;
    begin
        V := 1;
        asserterror Doc.EvaluateStatement(V, 'Nope');
        Observer.ObserveError('Evaluate Nope statement');
        Observer.Observe('Evaluate Nope caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        asserterror Doc.EvaluateStatement(V, 'Second');
        Observer.ObserveError('Evaluate Second statement');
        Observer.Observe('Evaluate Second caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        asserterror Doc.WriteThenError(V);
        Observer.ObserveError('write then error');
        Observer.Observe('write then error caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('Evaluate Nope statement|text', '''Nope'' is not an option. The existing options are:  ,Skip,Update');
        Observer.Expect('Evaluate Nope statement|code', 'InvalidOptionString');
        Observer.Expect('Evaluate Nope caller', '1|1');
        Observer.Expect('Evaluate Second statement|text', '''Second'' is not an option. The existing options are:  ,Skip,Update');
        Observer.Expect('Evaluate Second statement|code', 'InvalidOptionString');
        Observer.Expect('Evaluate Second caller', '1|1');
        Observer.Expect('write then error|text', 'stop after the write');
        Observer.Expect('write then error|code', 'Dialog');
        Observer.Expect('write then error caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeOps_MemberlessGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        Inside: Text;
    begin
        GlobalMemberless := 1;
        Inside := Doc.ConfirmOp(GlobalMemberless, 1);
        Observer.Observe('Evaluate Skip inside', Inside);
        Observer.Observe('Evaluate Skip caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        Inside := Doc.ConfirmOp(GlobalMemberless, 2);
        Observer.Observe('Evaluate Second inside', Inside);
        Observer.Observe('Evaluate Second caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        Inside := Doc.ConfirmOp(GlobalMemberless, 3);
        Observer.Observe('Evaluate 5 inside', Inside);
        Observer.Observe('Evaluate 5 caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        Inside := Doc.ConfirmOp(GlobalMemberless, 5);
        Observer.Observe('Integer 1 inside', Inside);
        Observer.Observe('Integer 1 caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        Inside := Doc.ConfirmOp(GlobalMemberless, 6);
        Observer.Observe('hand on var inside', Inside);
        Observer.Observe('hand on var caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        Inside := Doc.ConfirmOp(GlobalMemberless, 7);
        Observer.Observe('hand on by value inside', Inside);
        Observer.Observe('hand on by value caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        Inside := Doc.ConfirmOp(GlobalMemberless, 8);
        Observer.Observe('Evaluate update inside', Inside);
        Observer.Observe('Evaluate update caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        Inside := Doc.ConfirmOp(GlobalMemberless, 9);
        Observer.Observe('Evaluate Nope inside', Inside);
        Observer.Observe('Evaluate Nope caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        Inside := Doc.ConfirmOp(GlobalMemberless, 4);
        Observer.Observe('Clear inside', Inside);
        Observer.Observe('Clear caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        Observer.Expect('Evaluate Skip inside', 'Yes>Skip|1');
        Observer.Expect('Evaluate Skip caller', '1|1');
        Observer.Expect('Evaluate Second inside', 'No>Skip|1');
        Observer.Expect('Evaluate Second caller', '1|1');
        Observer.Expect('Evaluate 5 inside', 'Yes>5|5');
        Observer.Expect('Evaluate 5 caller', '5|5');
        Observer.Expect('Integer 1 inside', '>Skip|1');
        Observer.Expect('Integer 1 caller', '1|1');
        Observer.Expect('hand on var inside', 'm Skip|1>Skip|1');
        Observer.Expect('hand on var caller', '1|1');
        Observer.Expect('hand on by value inside', 'b 1|1>Skip|1');
        Observer.Expect('hand on by value caller', '1|1');
        Observer.Expect('Evaluate update inside', 'Yes>Update|2');
        Observer.Expect('Evaluate update caller', '2|2');
        Observer.Expect('Evaluate Nope inside', 'No>Skip|1');
        Observer.Expect('Evaluate Nope caller', '1|1');
        Observer.Expect('Clear inside', '> |0');
        Observer.Expect('Clear caller', '0|0');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeErrors_MemberlessGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        V: Option;
    begin
        GlobalMemberless := 1;
        asserterror Doc.EvaluateStatement(GlobalMemberless, 'Nope');
        Observer.ObserveError('Evaluate Nope statement');
        Observer.Observe('Evaluate Nope caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        asserterror Doc.EvaluateStatement(GlobalMemberless, 'Second');
        Observer.ObserveError('Evaluate Second statement');
        Observer.Observe('Evaluate Second caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        asserterror Doc.WriteThenError(GlobalMemberless);
        Observer.ObserveError('write then error');
        Observer.Observe('write then error caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        Observer.Expect('Evaluate Nope statement|text', '''Nope'' is not an option. The existing options are:  ,Skip,Update');
        Observer.Expect('Evaluate Nope statement|code', 'InvalidOptionString');
        Observer.Expect('Evaluate Nope caller', '1|1');
        Observer.Expect('Evaluate Second statement|text', '''Second'' is not an option. The existing options are:  ,Skip,Update');
        Observer.Expect('Evaluate Second statement|code', 'InvalidOptionString');
        Observer.Expect('Evaluate Second caller', '1|1');
        Observer.Expect('write then error|text', 'stop after the write');
        Observer.Expect('write then error|code', 'Dialog');
        Observer.Expect('write then error caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeClear_VarHop_Memberless_ThenReuse()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        Lib: Codeunit "OVB Lib";
        V: Option;
        W: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := HopOp(V, 4, Hop);
        Observer.Observe('Clear inside', Inside);
        Observer.Observe('Clear caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Observer.Observe('then 1', Format(V) + '|' + Format(V, 0, 2));
        V := 2;
        Observer.Observe('then 2', Format(V) + '|' + Format(V, 0, 2));
        Observer.Observe('then by value', Lib.HandOnByValue(V));
        Observer.Observe('then memberless var', Lib.HandOnMemberless(V));
        Inside := Doc.Confirm(V, false);
        Observer.Observe('then to the callee', Inside);
        Observer.Observe('then caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('Clear inside', '> |0');
        Observer.Expect('Clear caller', ' |0');
        Observer.Expect('then 1', 'Skip|1');
        Observer.Expect('then 2', 'Update|2');
        Observer.Expect('then by value', 'b 2|2');
        Observer.Expect('then memberless var', 'm Update|2');
        Observer.Expect('then to the callee', 'Update|2|No|update');
        Observer.Expect('then caller', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeClear_MemberlessLocal_ThenReuse()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        Lib: Codeunit "OVB Lib";
        V: Option;
        W: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        Hop: Text;
    begin
        V := 1;
        Inside := Doc.ConfirmOp(V, 4);
        Observer.Observe('Clear inside', Inside);
        Observer.Observe('Clear caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Observer.Observe('then 1', Format(V) + '|' + Format(V, 0, 2));
        V := 2;
        Observer.Observe('then 2', Format(V) + '|' + Format(V, 0, 2));
        Observer.Observe('then by value', Lib.HandOnByValue(V));
        Observer.Observe('then memberless var', Lib.HandOnMemberless(V));
        Inside := Doc.Confirm(V, false);
        Observer.Observe('then to the callee', Inside);
        Observer.Observe('then caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('Clear inside', '> |0');
        Observer.Expect('Clear caller', '0|0');
        Observer.Expect('then 1', '1|1');
        Observer.Expect('then 2', '2|2');
        Observer.Expect('then by value', 'b 2|2');
        Observer.Expect('then memberless var', 'm 2|2');
        Observer.Expect('then to the callee', 'Update|2|No|update');
        Observer.Expect('then caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure CalleeClear_VarHop_Other_ThenReuse()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        Lib: Codeunit "OVB Lib";
        V: Option;
        W: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        Hop: Text;
    begin
        W := 1;
        Inside := HopOp(W, 4, Hop);
        Observer.Observe('Clear inside', Inside);
        Observer.Observe('Clear caller', Format(W) + '|' + Format(W, 0, 2));
        W := 1;
        Observer.Observe('then 1', Format(W) + '|' + Format(W, 0, 2));
        W := 2;
        Observer.Observe('then 2', Format(W) + '|' + Format(W, 0, 2));
        Observer.Observe('then by value', Lib.HandOnByValue(W));
        Observer.Observe('then memberless var', Lib.HandOnMemberless(W));
        Inside := Doc.Confirm(W, false);
        Observer.Observe('then to the callee', Inside);
        Observer.Observe('then caller', Format(W) + '|' + Format(W, 0, 2));
        Observer.Expect('Clear inside', '>First|0');
        Observer.Expect('Clear caller', 'First|0');
        Observer.Expect('then 1', 'Second|1');
        Observer.Expect('then 2', 'Third|2');
        Observer.Expect('then by value', 'b 2|2');
        Observer.Expect('then memberless var', 'm Third|2');
        Observer.Expect('then to the callee', 'Update|2|No|update');
        Observer.Expect('then caller', 'Third|2');
        Observer.Verify();
    end;

    var
        GlobalMemberless: Option;

    local procedure HopOp(var V: Option; Op: Integer; var After: Text) Result: Text
    var
        Doc: Record "OVB Doc";
    begin
        Result := Doc.ConfirmOp(V, Op);
        After := Format(V) + '|' + Format(V, 0, 2);
    end;

    local procedure HopEvaluate(var V: Option; Txt: Text)
    var
        Doc: Record "OVB Doc";
    begin
        Doc.EvaluateStatement(V, Txt);
    end;

    local procedure HopWriteThenError(var V: Option)
    var
        Doc: Record "OVB Doc";
    begin
        Doc.WriteThenError(V);
    end;
}

codeunit 75735 "OVB Other Callers Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Direct_MemberlessLocal()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        V: Option;
        Inside: Text;
    begin
        V := 0;
        Inside := Doc.Confirm(V, false);
        Observer.Observe('0 read inside', Inside);
        Observer.Observe('0 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 0;
        Inside := Doc.Confirm(V, true);
        Observer.Observe('0 write inside', Inside);
        Observer.Observe('0 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := Doc.Confirm(V, false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := Doc.Confirm(V, true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := Doc.Confirm(V, false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := Doc.Confirm(V, true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('0 read inside', ' |0|No|blank');
        Observer.Expect('0 read caller', '0|0');
        Observer.Expect('0 write inside', ' |0|No|blank|Update|2');
        Observer.Expect('0 write caller', '2|2');
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write caller', '2|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_MemberlessGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        Inside: Text;
    begin
        GlobalMemberless := 1;
        Inside := Doc.Confirm(GlobalMemberless, false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        Inside := Doc.Confirm(GlobalMemberless, true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 5;
        Inside := Doc.Confirm(GlobalMemberless, false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 5;
        Inside := Doc.Confirm(GlobalMemberless, true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write caller', '2|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_MemberlessByValue()
    var
        Observer: Codeunit "Probe Observer";
        V: Option;
        Inside: Text;
        InParam: Text;
    begin
        V := 1;
        Inside := ByValueMemberless(V, false, InParam);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read in parameter', InParam);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := ByValueMemberless(V, true, InParam);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write in parameter', InParam);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := ByValueMemberless(V, false, InParam);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read in parameter', InParam);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := ByValueMemberless(V, true, InParam);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write in parameter', InParam);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read in parameter', '1|1');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write in parameter', '2|2');
        Observer.Expect('1 write caller', '1|1');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read in parameter', '5|5');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write in parameter', '2|2');
        Observer.Expect('5 write caller', '5|5');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_MemberlessNamedReturn()
    var
        Observer: Codeunit "Probe Observer";
        V: Option;
        Inside: Text;
    begin
        V := NamedReturnMemberless(1, false, Inside);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read returned', Format(V) + '|' + Format(V, 0, 2));
        V := NamedReturnMemberless(1, true, Inside);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write returned', Format(V) + '|' + Format(V, 0, 2));
        V := NamedReturnMemberless(5, false, Inside);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read returned', Format(V) + '|' + Format(V, 0, 2));
        V := NamedReturnMemberless(5, true, Inside);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write returned', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read returned', '1|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write returned', '2|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read returned', '5|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write returned', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_OtherMembersLocal()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
    begin
        V := 1;
        Inside := Doc.Confirm(V, false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := Doc.Confirm(V, true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := Doc.Confirm(V, false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := Doc.Confirm(V, true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_OtherMembersGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        Inside: Text;
    begin
        GlobalOther := 1;
        Inside := Doc.Confirm(GlobalOther, false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(GlobalOther) + '|' + Format(GlobalOther, 0, 2));
        GlobalOther := 1;
        Inside := Doc.Confirm(GlobalOther, true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(GlobalOther) + '|' + Format(GlobalOther, 0, 2));
        GlobalOther := 5;
        Inside := Doc.Confirm(GlobalOther, false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(GlobalOther) + '|' + Format(GlobalOther, 0, 2));
        GlobalOther := 5;
        Inside := Doc.Confirm(GlobalOther, true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(GlobalOther) + '|' + Format(GlobalOther, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_OtherMembersVarParam()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        InParam: Text;
    begin
        V := 1;
        Inside := VarParamOther(V, false, InParam);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read in parameter', InParam);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := VarParamOther(V, true, InParam);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write in parameter', InParam);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := VarParamOther(V, false, InParam);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read in parameter', InParam);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := VarParamOther(V, true, InParam);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write in parameter', InParam);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Second|1|Yes|skip');
        Observer.Expect('1 read in parameter', 'Second|1');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Second|1|Yes|skip|Third|2');
        Observer.Expect('1 write in parameter', 'Third|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', 'Sixth|5|No|else');
        Observer.Expect('5 read in parameter', 'Sixth|5');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', 'Sixth|5|No|else|Third|2');
        Observer.Expect('5 write in parameter', 'Third|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_OtherMembersByValue()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
        InParam: Text;
    begin
        V := 1;
        Inside := ByValueOther(V, false, InParam);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read in parameter', InParam);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := ByValueOther(V, true, InParam);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write in parameter', InParam);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := ByValueOther(V, false, InParam);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read in parameter', InParam);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := ByValueOther(V, true, InParam);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write in parameter', InParam);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read in parameter', 'Second|1');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write in parameter', 'Third|2');
        Observer.Expect('1 write caller', 'Second|1');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read in parameter', 'Sixth|5');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write in parameter', 'Third|2');
        Observer.Expect('5 write caller', 'Sixth|5');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_OtherMembersNamedReturn()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
    begin
        V := NamedReturnOther(1, false, Inside);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read returned', Format(V) + '|' + Format(V, 0, 2));
        V := NamedReturnOther(1, true, Inside);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write returned', Format(V) + '|' + Format(V, 0, 2));
        V := NamedReturnOther(5, false, Inside);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read returned', Format(V) + '|' + Format(V, 0, 2));
        V := NamedReturnOther(5, true, Inside);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write returned', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read returned', 'Second|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write returned', 'Third|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read returned', 'Sixth|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write returned', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Field_LocalRecord()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        Row: Record "OVB Doc";
        Inside: Text;
    begin
        Row.Opt := 1;
        Inside := Doc.Confirm(Row.Opt, false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := 1;
        Inside := Doc.Confirm(Row.Opt, true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := 5;
        Inside := Doc.Confirm(Row.Opt, false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := 5;
        Inside := Doc.Confirm(Row.Opt, true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Field_LocalRecordCaption()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        Row: Record "OVB Doc";
        Inside: Text;
    begin
        Row.OptCap := 1;
        Inside := Doc.Confirm(Row.OptCap, false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := 1;
        Inside := Doc.Confirm(Row.OptCap, true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := 5;
        Inside := Doc.Confirm(Row.OptCap, false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := 5;
        Inside := Doc.Confirm(Row.OptCap, true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read caller', 'Two|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write caller', 'Three|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read caller', 'Six|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write caller', 'Three|2');
        Observer.Verify();
    end;

    [Test]
    procedure Field_GlobalRecord()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        Inside: Text;
    begin
        GlobalRow.Opt := 1;
        Inside := Doc.Confirm(GlobalRow.Opt, false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        GlobalRow.Opt := 1;
        Inside := Doc.Confirm(GlobalRow.Opt, true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        GlobalRow.Opt := 5;
        Inside := Doc.Confirm(GlobalRow.Opt, false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        GlobalRow.Opt := 5;
        Inside := Doc.Confirm(GlobalRow.Opt, true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Field_VarRecordParam()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVB Doc";
        Inside: Text;
        InParam: Text;
    begin
        Row.Opt := 1;
        Inside := VarRecordField(Row, false, InParam);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read in parameter', InParam);
        Observer.Observe('1 read caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := 1;
        Inside := VarRecordField(Row, true, InParam);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write in parameter', InParam);
        Observer.Observe('1 write caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := 5;
        Inside := VarRecordField(Row, false, InParam);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read in parameter', InParam);
        Observer.Observe('5 read caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := 5;
        Inside := VarRecordField(Row, true, InParam);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write in parameter', InParam);
        Observer.Observe('5 write caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read in parameter', 'Second|1');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write in parameter', 'Third|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read in parameter', 'Sixth|5');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write in parameter', 'Third|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Field_Rec()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVB Doc";
        Inside: Text;
    begin
        Row.Opt := 1;
        Inside := Row.RecFieldToConfirm(false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := 1;
        Inside := Row.RecFieldToConfirm(true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := 5;
        Inside := Row.RecFieldToConfirm(false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := 5;
        Inside := Row.RecFieldToConfirm(true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Field_RecCaption()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVB Doc";
        Inside: Text;
    begin
        Row.OptCap := 1;
        Inside := Row.RecCaptionFieldToConfirm(false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := 1;
        Inside := Row.RecCaptionFieldToConfirm(true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := 5;
        Inside := Row.RecCaptionFieldToConfirm(false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := 5;
        Inside := Row.RecCaptionFieldToConfirm(true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes|skip');
        Observer.Expect('1 read caller', 'Two|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|skip|Update|2');
        Observer.Expect('1 write caller', 'Three|2');
        Observer.Expect('5 read inside', '5|5|No|else');
        Observer.Expect('5 read caller', 'Six|5');
        Observer.Expect('5 write inside', '5|5|No|else|Update|2');
        Observer.Expect('5 write caller', 'Three|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_MemberlessLocal()
    var
        Observer: Codeunit "Probe Observer";
        Impl: Codeunit "OVB Confirmer Impl";
        Confirmer: Interface "OVB Confirmer";
        V: Option;
        Inside: Text;
    begin
        Confirmer := Impl;
        V := 1;
        Inside := Confirmer.Confirm(V, false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := Confirmer.Confirm(V, true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := Confirmer.Confirm(V, false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := Confirmer.Confirm(V, true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|Update|2');
        Observer.Expect('1 write caller', '2|2');
        Observer.Expect('5 read inside', '5|5|No');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|Update|2');
        Observer.Expect('5 write caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_MemberlessGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Impl: Codeunit "OVB Confirmer Impl";
        Confirmer: Interface "OVB Confirmer";
        Inside: Text;
    begin
        Confirmer := Impl;
        GlobalMemberless := 1;
        Inside := Confirmer.Confirm(GlobalMemberless, false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 1;
        Inside := Confirmer.Confirm(GlobalMemberless, true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 5;
        Inside := Confirmer.Confirm(GlobalMemberless, false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        GlobalMemberless := 5;
        Inside := Confirmer.Confirm(GlobalMemberless, true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(GlobalMemberless) + '|' + Format(GlobalMemberless, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes');
        Observer.Expect('1 read caller', '1|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|Update|2');
        Observer.Expect('1 write caller', '2|2');
        Observer.Expect('5 read inside', '5|5|No');
        Observer.Expect('5 read caller', '5|5');
        Observer.Expect('5 write inside', '5|5|No|Update|2');
        Observer.Expect('5 write caller', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_OtherMembersLocal()
    var
        Observer: Codeunit "Probe Observer";
        Impl: Codeunit "OVB Confirmer Impl";
        Confirmer: Interface "OVB Confirmer";
        V: Option First,Second,Third,Fourth,Fifth,Sixth;
        Inside: Text;
    begin
        Confirmer := Impl;
        V := 1;
        Inside := Confirmer.Confirm(V, false);
        Observer.Observe('1 read inside', Inside);
        Observer.Observe('1 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 1;
        Inside := Confirmer.Confirm(V, true);
        Observer.Observe('1 write inside', Inside);
        Observer.Observe('1 write caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := Confirmer.Confirm(V, false);
        Observer.Observe('5 read inside', Inside);
        Observer.Observe('5 read caller', Format(V) + '|' + Format(V, 0, 2));
        V := 5;
        Inside := Confirmer.Confirm(V, true);
        Observer.Observe('5 write inside', Inside);
        Observer.Observe('5 write caller', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('1 read inside', 'Skip|1|Yes');
        Observer.Expect('1 read caller', 'Second|1');
        Observer.Expect('1 write inside', 'Skip|1|Yes|Update|2');
        Observer.Expect('1 write caller', 'Third|2');
        Observer.Expect('5 read inside', '5|5|No');
        Observer.Expect('5 read caller', 'Sixth|5');
        Observer.Expect('5 write inside', '5|5|No|Update|2');
        Observer.Expect('5 write caller', 'Third|2');
        Observer.Verify();
    end;

    var
        GlobalMemberless: Option;
        GlobalOther: Option First,Second,Third,Fourth,Fifth,Sixth;
        GlobalRow: Record "OVB Doc";

    local procedure ByValueMemberless(V: Option; Write: Boolean; var InParam: Text) Result: Text
    var
        Doc: Record "OVB Doc";
    begin
        Result := Doc.Confirm(V, Write);
        InParam := Format(V) + '|' + Format(V, 0, 2);
    end;

    local procedure NamedReturnMemberless(Start: Integer; Write: Boolean; var Inside: Text) V: Option
    var
        Doc: Record "OVB Doc";
    begin
        V := Start;
        Inside := Doc.Confirm(V, Write);
    end;

    local procedure VarParamOther(var V: Option First,Second,Third,Fourth,Fifth,Sixth; Write: Boolean; var InParam: Text) Result: Text
    var
        Doc: Record "OVB Doc";
    begin
        Result := Doc.Confirm(V, Write);
        InParam := Format(V) + '|' + Format(V, 0, 2);
    end;

    local procedure ByValueOther(V: Option First,Second,Third,Fourth,Fifth,Sixth; Write: Boolean; var InParam: Text) Result: Text
    var
        Doc: Record "OVB Doc";
    begin
        Result := Doc.Confirm(V, Write);
        InParam := Format(V) + '|' + Format(V, 0, 2);
    end;

    local procedure NamedReturnOther(Start: Integer; Write: Boolean; var Inside: Text) V: Option First,Second,Third,Fourth,Fifth,Sixth
    var
        Doc: Record "OVB Doc";
    begin
        V := Start;
        Inside := Doc.Confirm(V, Write);
    end;

    local procedure VarRecordField(var Row: Record "OVB Doc"; Write: Boolean; var InParam: Text) Result: Text
    var
        Doc: Record "OVB Doc";
    begin
        Result := Doc.Confirm(Row.Opt, Write);
        InParam := Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2);
    end;
}
