// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: TGL Row (69670), TGL Log (69671), TGL Row Ext (69672), TGL Subscribers (69675), Assert (60021)
//
// Where a table's global variables live. They belong to the record VARIABLE (the instance), not
// to a call: state one trigger or procedure sets is still there at the next call on the same
// variable. The tests pin what each operation on a record variable does to its globals
// (assignment, Copy, TransferFields, passing, returning, Clear, Init, Reset, Get, Find, Next,
// writes, xRec, events, temporary records, RecordRef, Variant, a table extension's globals).

// MEASURED RESULTS (BC 27.5, local container; every test below asserts one line of this):
//   * Globals live on the record VARIABLE and survive every call on it: procedures, field triggers,
//     OnInsert / OnModify / OnDelete (Insert, Modify, Delete with triggers run on the variable's own
//     instance), Get, Find, FindSet, Next, filters, marks, Init, Validate, ChangeCompany.
//   * Two variables of one table never share globals. A local variable is fresh at every call.
//   * `A := B`, `A.Copy(B)`, `A.TransferFields(B)`, `Rec := Other` (also inside the table), RecordRef
//     GetTable / SetTable and Variant round trips copy FIELD VALUES only: A keeps its own globals and
//     B's are untouched.
//   * By var: the same instance. By value: a copy whose globals start empty; the caller's are untouched.
//     A returned record handed to `X := F()` leaves X's globals untouched (X keeps its own; an
//     `Echo(Source)` receiver sees 0). Codeunit.Run(.., Row) with TableNo runs on the caller's instance.
//   * `Clear(Row)` and `Reset()` (also `Rec.Reset()` inside the table, on temporary records and on a
//     codeunit global) set the globals back to their initial values. No other method does.
//   * xRec is a second, lazily created instance owned by the record variable. Its globals persist across
//     validations and modifies of that variable (one instance for OnValidate and OnModify) and survive
//     Reset and Clear of Rec. In OnModify (no prior write to it) it holds initial globals.
//   * Event subscribers receive the caller's instance (`var Rec`): their changes are visible to the
//     trigger and to the caller.
//   * ModifyAll(.., true) and DeleteAll(true) run OnModify / OnDelete on ONE fresh instance shared by
//     all rows, not on the caller's. ModifyAll runs no field validation.
//   * A global record variable of the table's own table gets its own instance per parent, created on
//     first use (no endless nesting).
//   * A tableextension's globals follow the same rules and are separate from the base table's.
//   * A temporary record behaves like a persistent one.
//   * Pages (headless TestPage): the page's Rec keeps its globals across actions and across rows, and a
//     new page instance starts fresh. A field validation done through the page runs the table triggers
//     on a different instance with initial globals (not the page Rec's): OnInsert / OnModify afterwards
//     see initial globals too, and the page's Rec globals are reset by the validation.

codeunit 69677 "TGL Record Variable Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TGL Row";
        LogRec: Record "TGL Log";
    begin
        Row.DeleteAll(false);
        LogRec.DeleteAll(false);
    end;

    local procedure LogText(): Text
    var
        LogRec: Record "TGL Log";
        Result: Text;
    begin
        if LogRec.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ; ';
                Result += LogRec.Note;
            until LogRec.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure TableGlobals_PersistAcrossProcedureCalls_OnTheSameVariable()
    // CLAIM: a table's global variables keep their values between calls of its procedures on one record variable.
    var
        Row: Record "TGL Row";
    begin
        Initialize();
        Row.Bump();
        Row.Bump();
        Row.SetTag('abc');
        Assert.AreEqual(2, Row.GetCounter(), 'counter');
        Assert.AreEqual('abc', Row.GetTag(), 'tag');
    end;

    [Test]
    procedure TableGlobals_FieldTriggerAndProcedure_ShareTheGlobals()
    // CLAIM: a global set in a field's OnValidate is visible to a later procedure call and to the next OnValidate.
    var
        Row: Record "TGL Row";
    begin
        Initialize();
        Row.Validate(Payload, 5);
        Assert.AreEqual(1, Row.GetCounter(), 'after first validate');
        Assert.AreEqual('V5', Row.GetTag(), 'tag after first validate');
        Row.Validate(Payload, 7);
        Assert.AreEqual(2, Row.GetCounter(), 'after second validate');
        Assert.AreEqual('V7', Row.GetTag(), 'tag after second validate');
    end;

    [Test]
    procedure TableGlobals_SetByValidate_AreSeenByOnInsert()
    // CLAIM: a global set in a field trigger is visible in OnInsert of the same record variable, and Rec.Proc() in the trigger sees the same globals.
    var
        Row: Record "TGL Row";
    begin
        Initialize();
        Row."No." := 'A';
        Row.Validate(Payload, 5);
        Row.Insert(true);
        Assert.AreEqual('1|V5', Row.Seen, 'unqualified globals in OnInsert');
        Assert.AreEqual('1|V5', Row.RecSeen, 'Rec.Proc() in OnInsert');
    end;

    [Test]
    procedure TableGlobals_SecondVariable_HasItsOwnGlobals()
    // CLAIM: two record variables of one table do not share globals.
    var
        First: Record "TGL Row";
        Second: Record "TGL Row";
    begin
        Initialize();
        First.Bump();
        First.SetTag('first');
        Assert.AreEqual(0, Second.GetCounter(), 'second counter');
        Assert.AreEqual('', Second.GetTag(), 'second tag');
        Second.Bump();
        Second.Bump();
        Assert.AreEqual(1, First.GetCounter(), 'first counter is untouched');
    end;

    [Test]
    procedure TableGlobals_Assignment_WhatHappensToBothSides()
    // CLAIM (measured): `Target := Source` copies the fields; the globals of the target are (see expected text).
    var
        Source: Record "TGL Row";
        Target: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Source."No." := 'S';
        Source.Bump();
        Source.Bump();
        Source.Bump();
        Source.SetTag('src');
        Target.Bump();
        Target.SetTag('tgt');
        Target := Source;
        Seen := StrSubstNo('%1|%2|%3|%4|%5', Target."No.", Target.GetCounter(), Target.GetTag(), Source.GetCounter(), Source.GetTag());
        Assert.AreEqual('S|1|tgt|3|src', Seen, 'target and source after assignment');
    end;

    [Test]
    procedure TableGlobals_Copy_WhatHappensToBothSides()
    // CLAIM (measured): `Target.Copy(Source)` copies fields and filters; the globals of the target are (see expected text).
    var
        Source: Record "TGL Row";
        Target: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Source."No." := 'S';
        Source.Bump();
        Source.Bump();
        Source.Bump();
        Source.SetTag('src');
        Target.Bump();
        Target.SetTag('tgt');
        Target.Copy(Source);
        Seen := StrSubstNo('%1|%2|%3|%4|%5', Target."No.", Target.GetCounter(), Target.GetTag(), Source.GetCounter(), Source.GetTag());
        Assert.AreEqual('S|1|tgt|3|src', Seen, 'target and source after Copy');
    end;

    [Test]
    procedure TableGlobals_TransferFields_WhatHappensToBothSides()
    // CLAIM (measured): `Target.TransferFields(Source)` moves field values; the globals of the target are (see expected text).
    var
        Source: Record "TGL Row";
        Target: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Source."No." := 'S';
        Source.Bump();
        Source.Bump();
        Source.Bump();
        Source.SetTag('src');
        Target.Bump();
        Target.SetTag('tgt');
        Target.TransferFields(Source);
        Seen := StrSubstNo('%1|%2|%3|%4|%5', Target."No.", Target.GetCounter(), Target.GetTag(), Source.GetCounter(), Source.GetTag());
        Assert.AreEqual('S|1|tgt|3|src', Seen, 'target and source after TransferFields');
    end;

    [Test]
    procedure TableGlobals_PassedByVar_IsTheSameInstance()
    // CLAIM: a record passed by var is the caller's instance, so a global changed by the callee is visible to the caller.
    var
        Row: Record "TGL Row";
        Helper: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Bump();
        Seen := StrSubstNo('%1|%2', Helper.ByVar(Row), Row.GetCounter());
        Assert.AreEqual('2|2', Seen, 'callee result and caller counter');
    end;

    [Test]
    procedure TableGlobals_PassedByValue_WhatTheCalleeSeesAndLeaves()
    // CLAIM (measured): a record passed by value is a copy; what the copy starts with in its globals and whether the caller sees the callee's change.
    var
        Row: Record "TGL Row";
        Helper: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Bump();
        Row.Bump();
        Row.SetTag('caller');
        Seen := StrSubstNo('%1|%2', Helper.ByValue(Row), Row.GetCounter());
        Assert.AreEqual('1|2', Seen, 'callee result and caller counter');
    end;

    [Test]
    procedure TableGlobals_RecPassedByValueInsideTable_WhatTheCalleeSees()
    // CLAIM (measured): Rec passed by value from a table procedure to a table procedure.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Bump();
        Row.Bump();
        Seen := StrSubstNo('%1|%2', Row.SelfByValue(), Row.GetCounter());
        Assert.AreEqual('1|2', Seen, 'callee result and caller counter');
    end;

    [Test]
    procedure TableGlobals_ReturnedRecord_WhatTheReceiverSees()
    // CLAIM (measured): a record returned from a procedure and assigned to a variable; what the globals are.
    var
        Row: Record "TGL Row";
        Maker: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Bump();
        Row := Maker.Make();
        Seen := StrSubstNo('%1', Row.GetCounter());
        Assert.AreEqual('1', Seen, 'receiver counter');
    end;

    [Test]
    procedure TableGlobals_EchoedRecord_WhatTheReceiverSees()
    // CLAIM (measured): a record passed by value and returned; what the receiver's globals are.
    var
        Source: Record "TGL Row";
        Receiver: Record "TGL Row";
        Maker: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Source.Bump();
        Source.Bump();
        Source.Bump();
        Receiver := Maker.Echo(Source);
        Seen := StrSubstNo('%1|%2', Receiver.GetCounter(), Source.GetCounter());
        Assert.AreEqual('0|3', Seen, 'receiver and source counter');
    end;

    [Test]
    procedure TableGlobals_Clear_WhatHappensToTheGlobals()
    // CLAIM (measured): Clear(Rec) on a record variable with globals set.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Bump();
        Row.SetTag('x');
        Clear(Row);
        Seen := StrSubstNo('%1|%2', Row.GetCounter(), Row.GetTag());
        Assert.AreEqual('0|', Seen, 'counter and tag after Clear');
    end;

    [Test]
    procedure TableGlobals_Init_WhatHappensToTheGlobals()
    // CLAIM (measured): Init on a record variable with globals set.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Bump();
        Row.SetTag('x');
        Row.Init();
        Seen := StrSubstNo('%1|%2', Row.GetCounter(), Row.GetTag());
        Assert.AreEqual('1|x', Seen, 'counter and tag after Init');
    end;

    [Test]
    procedure TableGlobals_Reset_WhatHappensToTheGlobals()
    // CLAIM (measured): Reset on a record variable with globals set.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Bump();
        Row.SetTag('x');
        Row.Reset();
        Seen := StrSubstNo('%1|%2', Row.GetCounter(), Row.GetTag());
        Assert.AreEqual('0|', Seen, 'counter and tag after Reset');
    end;

    [Test]
    procedure TableGlobals_ClearAll_WhatHappensToTheGlobals()
    // CLAIM (measured): ClearAll in the test procedure does not touch a local record variable's globals? (record variables are not cleared by ClearAll in a procedure).
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Bump();
        ClearAll();
        Seen := StrSubstNo('%1', Row.GetCounter());
        Assert.AreEqual('1', Seen, 'counter after ClearAll');
    end;

    [Test]
    procedure TableGlobals_OtherOperations_WhichOnesResetTheGlobals()
    // CLAIM (measured): which record methods leave the globals alone and which reset them.
    var
        Row: Record "TGL Row";
        Writer: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Writer."No." := 'A';
        Writer.Insert();
        Row.SetTag('x');
        Row.SetRange("No.", 'A');
        Seen := Kept(Row, 'SetRange');
        Row.SetFilter("No.", 'A');
        Seen += Kept(Row, 'SetFilter');
        Row.SetCurrentKey("No.");
        Seen += Kept(Row, 'SetCurrentKey');
        Row.Mark(true);
        Seen += Kept(Row, 'Mark');
        Row.MarkedOnly(true);
        Seen += Kept(Row, 'MarkedOnly');
        Row.MarkedOnly(false);
        Row.ClearMarks();
        Seen += Kept(Row, 'ClearMarks');
        Row.SetLoadFields("No.");
        Seen += Kept(Row, 'SetLoadFields');
        Row.SetAutoCalcFields();
        Seen += Kept(Row, 'SetAutoCalcFields');
        Row.LockTable();
        Seen += Kept(Row, 'LockTable');
        if Row.Count() < 0 then
            exit;
        Seen += Kept(Row, 'Count');
        if Row.IsEmpty() then
            exit;
        Seen += Kept(Row, 'IsEmpty');
        Row.FindFirst();
        Seen += Kept(Row, 'FindFirst');
        Row.SetRecFilter();
        Seen += Kept(Row, 'SetRecFilter');
        Row.CopyFilters(Writer);
        Seen += Kept(Row, 'CopyFilters');
        Row.Validate("No.", 'A');
        Seen += Kept(Row, 'Validate');
        Row.ChangeCompany(CompanyName());
        Seen += Kept(Row, 'ChangeCompany');
        Row.Reset();
        Seen += Kept(Row, 'Reset');
        Assert.AreEqual(
            'SetRange:kept SetFilter:kept SetCurrentKey:kept Mark:kept MarkedOnly:kept ClearMarks:kept SetLoadFields:kept SetAutoCalcFields:kept LockTable:kept Count:kept IsEmpty:kept FindFirst:kept SetRecFilter:kept CopyFilters:kept Validate:kept ChangeCompany:kept Reset:reset ',
            Seen, 'methods and whether the globals were kept');
    end;

    local procedure Kept(var Row: Record "TGL Row"; MethodName: Text): Text
    var
        Result: Text;
    begin
        if Row.GetTag() = 'x' then
            Result := MethodName + ':kept '
        else
            Result := MethodName + ':reset ';
        Row.SetTag('x');
        exit(Result);
    end;

    [Test]
    procedure TableGlobals_ResetInsideTable_ResetsTheCallersGlobals()
    // CLAIM (measured): `Rec.Reset()` in a table procedure acts on the caller's instance.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Bump();
        Row.SetTag('x');
        Row.ResetSelf();
        Seen := StrSubstNo('%1|%2', Row.GetCounter(), Row.GetTag());
        Assert.AreEqual('0|', Seen, 'counter and tag after Rec.Reset() inside the table');
    end;

    [Test]
    procedure TableGlobals_ResetOnTemporaryRecord_WhatHappensToTheGlobals()
    // CLAIM (measured): Reset on a temporary record variable.
    var
        Temp: Record "TGL Row" temporary;
        Seen: Text;
    begin
        Initialize();
        Temp.Bump();
        Temp.SetTag('x');
        Temp.Reset();
        Seen := StrSubstNo('%1|%2', Temp.GetCounter(), Temp.GetTag());
        Assert.AreEqual('0|', Seen, 'counter and tag after Reset on a temporary record');
    end;

    [Test]
    procedure TableGlobals_ResetOnCodeunitGlobalRecord_WhatHappensToTheGlobals()
    // CLAIM (measured): Reset on a record that is a codeunit global.
    var
        Holder: Codeunit "TGL Holder";
        Seen: Text;
    begin
        Initialize();
        Holder.BumpRow();
        Holder.ResetRow();
        Seen := StrSubstNo('%1', Holder.RowCounter());
        Assert.AreEqual('0', Seen, 'counter after Reset on the global');
    end;

    [Test]
    procedure TableGlobals_GetFindNext_WhatHappensToTheGlobals()
    // CLAIM (measured): Get, Find, FindSet and Next load other rows into the same variable; what the globals do.
    var
        Row: Record "TGL Row";
        Writer: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Writer."No." := 'A';
        Writer.Insert();
        Writer."No." := 'B';
        Writer.Insert();
        Writer."No." := 'C';
        Writer.Insert();
        Row.Bump();
        Row.Get('A');
        Seen := StrSubstNo('get:%1', Row.GetCounter());
        Row.Bump();
        Row."No." := 'B';
        Row.Find('=');
        Seen += StrSubstNo(' find:%1', Row.GetCounter());
        Row.Bump();
        Row.FindSet();
        Seen += StrSubstNo(' findset:%1', Row.GetCounter());
        Row.Bump();
        Row.Next();
        Seen += StrSubstNo(' next:%1', Row.GetCounter());
        Row.Reset();
        Row.FindLast();
        Seen += StrSubstNo(' findlast:%1', Row.GetCounter());
        Assert.AreEqual('get:1 find:2 findset:3 next:4 findlast:0', Seen, 'counter after each read');
    end;

    [Test]
    procedure TableGlobals_InsertModifyDelete_WhatHappensToTheGlobals()
    // CLAIM (measured): Insert, Modify and Delete (with triggers) on a variable; what the globals do.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row."No." := 'A';
        Row.Bump();
        Row.Insert(true);
        Seen := StrSubstNo('ins:%1', Row.GetCounter());
        Row.Bump();
        Row.Modify(true);
        Seen += StrSubstNo(' mod:%1', Row.GetCounter());
        Row.Bump();
        Row.Delete(true);
        Seen += StrSubstNo(' del:%1', Row.GetCounter());
        Assert.AreEqual('ins:1 mod:2 del:4', Seen, 'counter after each write');
        Assert.AreEqual('BI:1| ; AI:1| ; BM:2|/0| ; AM:2|/0| ; D:3|', LogText(), 'subscribers and OnDelete saw the globals');
    end;

    [Test]
    procedure TableGlobals_ModifyAll_WhatTheTriggersAndSubscribersSee()
    // CLAIM (measured): ModifyAll with validation runs the field trigger, subscribers and OnModify per row; which instance they run on and whether the rows share it.
    var
        Row: Record "TGL Row";
        Writer: Record "TGL Row";
        Check: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Writer."No." := 'A';
        Writer.Insert();
        Writer."No." := 'B';
        Writer.Insert();
        LogRec_Clear();
        Row.Bump();
        Row.Bump();
        Row.SetTag('t');
        Row.ModifyAll(Probe, 1, true);
        Seen := StrSubstNo('mod:%1|%2', Row.GetCounter(), Row.GetTag());
        Check.Get('A');
        Seen += StrSubstNo(' A:%1/%2/%3', Check.Seen, Check.XSeen, Check.ModSeq);
        Check.Get('B');
        Seen += StrSubstNo(' B:%1/%2/%3', Check.Seen, Check.XSeen, Check.ModSeq);
        Assert.AreEqual('mod:2|t A:0|/0|/1 B:0|/0|/2', Seen, 'caller globals after ModifyAll, and what OnModify saw per row');
        Assert.AreEqual('BM:0|/0| ; AM:0|/0| ; BM:0|/0| ; AM:0|/0|', LogText(), 'subscribers per row (no field validation runs)');
    end;

    [Test]
    procedure TableGlobals_ModifyTwice_OnModifyKeepsItsOwnGlobals()
    // CLAIM (measured): two Modify calls on one variable run OnModify on that instance, so a global the trigger counts in goes on counting.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row."No." := 'A';
        Row.Insert();
        Row.Modify(true);
        Seen := Format(Row.ModSeq);
        Row.Modify(true);
        Seen += '|' + Format(Row.ModSeq);
        Assert.AreEqual('1|2', Seen, 'ModSeq after two Modify calls');
    end;

    [Test]
    procedure TableGlobals_Modify_OnAnotherVariableOfTheSameRow_CountsFromZero()
    // CLAIM (measured): a second variable that reads the same row and modifies it starts counting from zero.
    var
        Row: Record "TGL Row";
        Other: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row."No." := 'A';
        Row.Insert();
        Row.Modify(true);
        Row.Modify(true);
        Other.Get('A');
        Other.Modify(true);
        Seen := StrSubstNo('%1|%2', Row.ModSeq, Other.ModSeq);
        Assert.AreEqual('2|1', Seen, 'ModSeq of the two variables');
    end;

    [Test]
    procedure TableGlobals_DeleteAll_TriggersRunOnOneInstanceForAllRows()
    // CLAIM (measured): DeleteAll with triggers runs OnDelete on a fresh instance (not the caller's), shared by all rows.
    var
        Row: Record "TGL Row";
        Writer: Record "TGL Row";
    begin
        Initialize();
        Writer."No." := 'A';
        Writer.Insert();
        Writer."No." := 'B';
        Writer.Insert();
        Row.Bump();
        Row.Bump();
        Row.SetTag('t');
        LogRec_Clear();
        Row.DeleteAll(true);
        Assert.AreEqual('2|t', StrSubstNo('%1|%2', Row.GetCounter(), Row.GetTag()), 'caller globals after DeleteAll');
        Assert.AreEqual('D:0| ; D:1|', LogText(), 'OnDelete globals per row');
    end;

    [Test]
    procedure TableGlobals_XRecInOnModify_WhichGlobalsItHas()
    // CLAIM (measured): in OnModify, xRec is its own instance; its globals are not Rec's.
    var
        Row: Record "TGL Row";
    begin
        Initialize();
        Row."No." := 'A';
        Row.Insert();
        Row.Bump();
        Row.Bump();
        Row.Bump();
        Row.SetTag('t');
        Row.Modify(true);
        Assert.AreEqual('3|t', Row.Seen, 'Rec globals in OnModify (unqualified)');
        Assert.AreEqual('3|t', Row.RecSeen, 'Rec globals in OnModify (Rec.Proc)');
        Assert.AreEqual('0|', Row.XSeen, 'xRec globals in OnModify');
    end;

    [Test]
    procedure TableGlobals_XRecInOnValidate_WhichGlobalsItHas()
    // CLAIM (measured): in a field's OnValidate, xRec is its own instance; its globals are not Rec's.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Bump();
        Row.Bump();
        Row.SetTag('t');
        Row.Validate(Payload, 4);
        Seen := StrSubstNo('%1|%2', Row.GetXCounterInValidate(), Row.GetXTagInValidate());
        Assert.AreEqual('0|', Seen, 'xRec globals in OnValidate');
    end;

    [Test]
    procedure TableGlobals_XRecAcrossTwoModifies_WhetherItsGlobalsPersist()
    // CLAIM (measured): across two Modify calls on one variable, does xRec keep its own globals.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row."No." := 'A';
        Row.Insert();
        Row.Modify(true);
        Seen := Row.XSeen;
        Row.Modify(true);
        Seen += ' ; ' + Row.XSeen;
        Assert.AreEqual('0| ; 0|', Seen, 'xRec in two modifies');
    end;

    [Test]
    procedure TableGlobals_XRecInOnValidate_KeepsItsGlobalsBetweenValidations()
    // CLAIM (measured): across two Validate calls on one variable, does the xRec a subscriber bumped keep what it was given.
    var
        Row: Record "TGL Row";
    begin
        Initialize();
        Row.Validate(Probe, 1);
        LogRec_Clear();
        Row.Validate(Probe, 2);
        Assert.AreEqual('BV:12/1 ; AV:22/2', LogText(), 'second validation: Rec and xRec as the subscriber sees them');
    end;

    [Test]
    procedure TableGlobals_XRecIsOneInstanceForValidateAndModify()
    // CLAIM (measured): the xRec a field validation used and the xRec Modify uses are one instance per record variable.
    var
        Row: Record "TGL Row";
    begin
        Initialize();
        Row."No." := 'A';
        Row.Insert();
        Row.Validate(Probe, 1);
        LogRec_Clear();
        Row.Modify(true);
        Assert.AreEqual('BM:11|/1| ; AM:11|/1|', LogText(), 'Modify: Rec and xRec as the subscribers see them');
    end;

    [Test]
    procedure TableGlobals_XRecGlobals_AfterResetAndClear()
    // CLAIM (measured): whether Reset and Clear also reset the globals of the variable's xRec.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Validate(Probe, 1);
        LogRec_Clear();
        Row.Reset();
        Row.Validate(Probe, 2);
        Seen := LogText();
        LogRec_Clear();
        Clear(Row);
        Row.Validate(Probe, 3);
        Seen += ' || ' + LogText();
        Assert.AreEqual('BV:1/1 ; AV:11/2 || BV:1/2 ; AV:11/3', Seen, 'subscriber view after Reset, then after Clear');
    end;

    [Test]
    procedure TableGlobals_CodeunitRunWithRecord_RunsOnTheCallersInstance()
    // CLAIM (measured): Codeunit.Run(Codeunit::X, Row) with TableNo: whether the codeunit's Rec sees and changes the caller's globals.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.Bump();
        Row.Bump();
        Codeunit.Run(Codeunit::"TGL Runner", Row);
        Seen := StrSubstNo('%1|%2', Row.GetCounter(), Row.GetTag());
        Assert.AreEqual('3|ran', Seen, 'counter and tag after the codeunit ran');
    end;

    [Test]
    procedure TableGlobals_Events_RecIsTheCallersInstance()
    // CLAIM (measured): the Rec an event subscriber receives sees the caller variable's globals; a change it makes to them is visible to the trigger and the caller.
    var
        Row: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row."No." := 'A';
        Row.Validate(Payload, 3);
        Row.Insert(true);
        Row.Bump();
        Row.Modify(true);
        Assert.AreEqual('BI:1|V3 ; AI:1|V3 ; BM:2|V3/0| ; AM:2|V3/0|', LogText(), 'subscriber view of Rec and xRec');
        LogRec_Clear();
        Row.Validate(Probe, 1);
        Seen := StrSubstNo('%1', Row.GetCounter());
        Assert.AreEqual('BV:3/0 ; AV:13/1', LogText(), 'subscriber bump before the trigger, view after it');
        Assert.AreEqual('13', Seen, 'caller counter after subscriber bump and trigger');
    end;

    local procedure LogRec_Clear()
    var
        LogRec: Record "TGL Log";
    begin
        LogRec.DeleteAll(false);
    end;

    [Test]
    procedure TableGlobals_TemporaryRecord_KeepsGlobalsBetweenCalls()
    // CLAIM: a temporary record variable keeps its table globals between calls like any other.
    var
        Temp: Record "TGL Row" temporary;
        Seen: Text;
    begin
        Initialize();
        Temp."No." := 'T';
        Temp.Validate(Payload, 6);
        Temp.Insert(true);
        Temp.Bump();
        Seen := StrSubstNo('%1|%2|%3', Temp.GetCounter(), Temp.GetTag(), Temp.Seen);
        Assert.AreEqual('2|V6|1|V6', Seen, 'temporary record counter, tag, Seen');
    end;

    [Test]
    procedure TableGlobals_TemporaryRecord_AssignedFromPersistent()
    // CLAIM (measured): copying a persistent record into a temporary record variable; globals of the target.
    var
        Source: Record "TGL Row";
        Temp: Record "TGL Row" temporary;
        Seen: Text;
    begin
        Initialize();
        Source."No." := 'S';
        Source.Bump();
        Temp.Bump();
        Temp.Bump();
        Temp := Source;
        Seen := StrSubstNo('%1|%2', Temp.GetCounter(), Temp."No.");
        Assert.AreEqual('2|S', Seen, 'temporary target after assignment');
    end;

    [Test]
    procedure TableGlobals_RecAssignedInsideTable_WhatHappensToTheGlobals()
    // CLAIM (measured): `Rec := Other` inside a table procedure.
    var
        Target: Record "TGL Row";
        Other: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Other."No." := 'O';
        Other.Bump();
        Other.Bump();
        Other.Bump();
        Target.Bump();
        Target.TakeFrom(Other);
        Seen := StrSubstNo('%1|%2|%3', Target."No.", Target.GetCounter(), Other.GetCounter());
        Assert.AreEqual('O|1|3', Seen, 'target and other after Rec := Other');
    end;

    [Test]
    procedure TableGlobals_RecCopyInsideTable_WhatHappensToTheGlobals()
    // CLAIM (measured): `Rec.Copy(Other)` inside a table procedure.
    var
        Target: Record "TGL Row";
        Other: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Other."No." := 'O';
        Other.Bump();
        Other.Bump();
        Other.Bump();
        Target.Bump();
        Target.CopyFromRow(Other);
        Seen := StrSubstNo('%1|%2|%3', Target."No.", Target.GetCounter(), Other.GetCounter());
        Assert.AreEqual('O|1|3', Seen, 'target and other after Rec.Copy(Other)');
    end;

    [Test]
    procedure TableGlobals_RecTransferFieldsInsideTable_WhatHappensToTheGlobals()
    // CLAIM (measured): `Rec.TransferFields(Other)` inside a table procedure.
    var
        Target: Record "TGL Row";
        Other: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Other."No." := 'O';
        Other.Bump();
        Other.Bump();
        Other.Bump();
        Target.Bump();
        Target.TransferFromRow(Other);
        Seen := StrSubstNo('%1|%2|%3', Target."No.", Target.GetCounter(), Other.GetCounter());
        Assert.AreEqual('O|1|3', Seen, 'target and other after Rec.TransferFields(Other)');
    end;

    [Test]
    procedure TableGlobals_RecordGlobalOfOwnTable_IsPerInstanceAndLazy()
    // CLAIM: a table with a global record variable of its own table works (no endless nesting); each parent instance has its own child, whose globals persist.
    var
        First: Record "TGL Row";
        Second: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        First.ChildBump();
        First.ChildBump();
        Second.ChildBump();
        Seen := StrSubstNo('%1|%2|%3|%4', First.ChildCounter(), Second.ChildCounter(), First.GetCounter(), Second.GetCounter());
        Assert.AreEqual('2|1|0|0', Seen, 'children counters and own counters');
    end;

    [Test]
    procedure TableGlobals_RecordRef_GetTableSetTable_WhatHappensToTheGlobals()
    // CLAIM (measured): RecordRef.GetTable(Row) and SetTable(Other); what the globals of Row, the RecordRef's record and Other are.
    var
        Row: Record "TGL Row";
        Other: Record "TGL Row";
        RecRef: RecordRef;
        Seen: Text;
    begin
        Initialize();
        Row."No." := 'R';
        Row.Bump();
        Row.Bump();
        Other.Bump();
        RecRef.GetTable(Row);
        RecRef.SetTable(Other);
        Seen := StrSubstNo('%1|%2|%3', Other."No.", Other.GetCounter(), Row.GetCounter());
        Assert.AreEqual('R|1|2', Seen, 'other and row after GetTable and SetTable');
    end;

    [Test]
    procedure TableGlobals_RecordRef_ValidateAndInsert_RunTriggersOnItsOwnInstance()
    // CLAIM (measured): a RecordRef opened on the table runs field and insert triggers; globals set by the field trigger are seen by OnInsert.
    var
        Row: Record "TGL Row";
        RecRef: RecordRef;
        Seen: Text;
    begin
        Initialize();
        RecRef.Open(Database::"TGL Row");
        RecRef.Field(1).Value := 'RR';
        RecRef.Field(2).Validate(5);
        RecRef.Insert(true);
        Row.Get('RR');
        Seen := Row.Seen;
        Assert.AreEqual('1|V5', Seen, 'Seen written by OnInsert');
    end;

    [Test]
    procedure TableGlobals_Variant_WhatHappensToTheGlobals()
    // CLAIM (measured): a record put into a Variant and taken out; what the globals of the receiver are.
    var
        Row: Record "TGL Row";
        Other: Record "TGL Row";
        V: Variant;
        Seen: Text;
    begin
        Initialize();
        Row."No." := 'V';
        Row.Bump();
        Row.Bump();
        Other.Bump();
        V := Row;
        Other := V;
        Seen := StrSubstNo('%1|%2|%3', Other."No.", Other.GetCounter(), Row.GetCounter());
        Assert.AreEqual('V|1|2', Seen, 'other and row after Variant round trip');
    end;

    [Test]
    procedure TableExtensionGlobals_PersistAcrossCallsOnTheSameVariable()
    // CLAIM: a table extension's own globals persist per record variable, apart from the base table's.
    var
        Row: Record "TGL Row";
        Second: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Row.ExtBump();
        Row.ExtBump();
        Row.Validate(ExtPayload, 3);
        Row.Bump();
        Seen := StrSubstNo('%1|%2|%3|%4|%5', Row.ExtGetCounter(), Row.ExtGetTag(), Row.GetCounter(), Second.ExtGetCounter(), Second.GetCounter());
        Assert.AreEqual('3|E3|1|0|0', Seen, 'extension and base counters, second variable');
    end;

    [Test]
    procedure TableExtensionGlobals_CopyAndClear_WhatHappensToThem()
    // CLAIM (measured): extension globals under assignment and Clear, as for the base table's.
    var
        Source: Record "TGL Row";
        Target: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Source."No." := 'S';
        Source.ExtBump();
        Source.ExtBump();
        Target.ExtBump();
        Target := Source;
        Seen := StrSubstNo('%1|%2', Target.ExtGetCounter(), Source.ExtGetCounter());
        Clear(Target);
        Seen += StrSubstNo(' clear:%1', Target.ExtGetCounter());
        Assert.AreEqual('1|2 clear:0', Seen, 'extension globals');
    end;

    [Test]
    procedure TableGlobals_RecordRef_GetTable_ThenFieldValidate_SeesWhichGlobals()
    // CLAIM (corpus issue 668 item 45, writer br): after RecordRef.GetTable(Row) of a record whose globals were set by a procedure,
    // FieldRef.Validate and Insert(true) on the RecordRef run on an instance that does or does not carry those globals; SetTable back
    // to the same variable keeps or resets its globals.
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TGL Row";
        Stored: Record "TGL Row";
        RecRef: RecordRef;
    begin
        Initialize();
        Row."No." := 'G';
        Row.Bump();
        Row.Bump();
        RecRef.GetTable(Row);
        RecRef.Field(2).Validate(7);
        RecRef.Insert(true);
        Stored.Get('G');
        Observer.Observe('seen by OnInsert through the RecordRef', Stored.Seen);
        Observer.Observe('row counter after GetTable', Format(Row.GetCounter()));
        RecRef.SetTable(Row);
        Observer.Observe('row after SetTable back', Format(Row.GetCounter()) + '|' + Format(Row.Payload));
        Observer.Expect('seen by OnInsert through the RecordRef', '1|V7');
        Observer.Expect('row counter after GetTable', '2');
        Observer.Expect('row after SetTable back', '2|7');
        Observer.Verify();
    end;
}
