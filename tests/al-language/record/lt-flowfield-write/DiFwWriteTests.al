// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfields
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 86260..86263 (DiFwTables.al)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: writing a value into a FlowField (corpus issue #665): assignment then Modify/Get/CalcFields, assignment then Insert, Validate,
// Modify(true) when only a FlowField changed (OnModify, xRec, SystemRowVersion, SystemModifiedAt),
// RecordRef/FieldRef Value, Validate and Modify, TransferFields and record assignment, Init/Clear/Reset/Find/Next/Get, SetAutoCalcFields,
// temporary records, Exist (Boolean) and Lookup (Text) FlowFields, assignment to a FlowFilter field, CalcFields after an assignment.
// Results: an assigned value stays in the variable until Get/Find/Next/Init/Clear (Reset keeps it); Modify and Insert accept it, write
// nothing (SystemRowVersion and SystemModifiedAt unchanged) and Get returns 0; Modify(true) still runs OnModify, with xRec = Rec.
// Validate on a Count, Exist or Lookup FlowField raises FlowFieldValidation ("The type of the <field> FlowField in the <table> table must be
// Decimal."), from Record.Validate and FieldRef.Validate, before OnValidate runs. Validate on a Sum FlowField inserts a row into the
// CalcFormula source table: next Entry No., the where-field set, Amount = new value - current sum (no row when they are equal), the
// Date Filter value (or the start of a range) in the field it filters. TransferFields and := copy FlowField values within the same table, not
// to or from normal fields of another table. CalcFields replaces an assigned value. ModifyAll on a FlowField does not compile (AL0779).
// Every test also reads the CalcFormula source table (LT DI FW Child) and the trigger log before and after the write ('src' and 'log').
// A call that may raise runs as `asserterror begin <call>; Error(NoErrorTok); end;` so both outcomes are observed; when it did not raise,
// the call runs again outside asserterror (asserterror rolls the database back to the Commit() just before it).
// BC versions: 27, 28, 29

codeunit 86264 "LT DI FW Write Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        NoErrorTok: Label 'DI-NO-ERROR', Locked = true;

    local procedure Seed()
    var
        Parent: Record "LT DI FW Parent";
        Child: Record "LT DI FW Child";
        LogRow: Record "LT DI FW Log";
        CopyRow: Record "LT DI FW Copy";
    begin
        Parent.DeleteAll(false);
        Child.DeleteAll(false);
        LogRow.DeleteAll(false);
        CopyRow.DeleteAll(false);
        AddParent(1, 'P1');
        AddParent(2, 'P2');
        AddParent(3, 'P3');
        AddChild(1, 1, 'A', 10, 20260110D);
        AddChild(2, 1, 'B', 20, 20260210D);
        AddChild(3, 1, 'C', 30, 20260310D);
        AddChild(4, 3, 'D', 5, 20260115D);
        LogRow.DeleteAll(false);
    end;

    local procedure AddParent(No: Integer; NewName: Text[30])
    var
        Parent: Record "LT DI FW Parent";
    begin
        Parent.Init();
        Parent."No." := No;
        Parent.Name := NewName;
        Parent.Insert(false);
    end;

    local procedure AddChild(EntryNo: Integer; ParentNo: Integer; NewCode: Text[30]; NewAmount: Decimal; PostingDate: Date)
    var
        Child: Record "LT DI FW Child";
    begin
        Child.Init();
        Child."Entry No." := EntryNo;
        Child."Parent No." := ParentNo;
        Child.Code := NewCode;
        Child.Amount := NewAmount;
        Child."Posting Date" := PostingDate;
        Child.Insert(false);
    end;

    // The CalcFormula source table: row count, then every row as entry|parent|code|amount|date.
    local procedure Src(): Text
    var
        Child: Record "LT DI FW Child";
        Result: Text;
    begin
        Result := 'n=' + Format(Child.Count());
        if Child.FindSet() then
            repeat
                Result += ';' + Format(Child."Entry No.") + '|' + Format(Child."Parent No.") + '|' + Child.Code + '|' + Format(Child.Amount, 0, 9) + '|' + Format(Child."Posting Date", 0, 9);
            until Child.Next() = 0;
        exit(Result);
    end;

    // The stored parent rows: no|name for every row.
    local procedure Parents(): Text
    var
        Parent: Record "LT DI FW Parent";
        Result: Text;
    begin
        Result := 'n=' + Format(Parent.Count());
        if Parent.FindSet() then
            repeat
                Result += ';' + Format(Parent."No.") + '|' + Parent.Name;
            until Parent.Next() = 0;
        exit(Result);
    end;

    // The trigger log since the last call (then emptied).
    local procedure TakeLog(): Text
    var
        LogRow: Record "LT DI FW Log";
        Result: Text;
    begin
        Result := 'n=' + Format(LogRow.Count());
        if LogRow.FindSet() then
            repeat
                Result += ';' + LogRow.Msg;
            until LogRow.Next() = 0;
        LogRow.DeleteAll(false);
        exit(Result);
    end;

    local procedure Outcome(): Text
    begin
        if GetLastErrorText() = NoErrorTok then begin
            ClearLastError();
            exit('ok');
        end;
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure StoredCount(No: Integer): Text
    var
        Parent: Record "LT DI FW Parent";
    begin
        Parent.Get(No);
        exit(Format(Parent."Child Count"));
    end;

    local procedure CalcCount(No: Integer): Text
    var
        Parent: Record "LT DI FW Parent";
    begin
        Parent.Get(No);
        Parent.CalcFields("Child Count");
        exit(Format(Parent."Child Count"));
    end;

    // ---- item 1: assignment to a FlowField on a row that has children, then Modify, Get and CalcFields ----
    [Test]
    procedure DI_AssignThenModify()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Other: Record "LT DI FW Parent";
        Result: Text;
    begin
        Seed();
        Observer.Observe('src before', Src());
        Parent.Get(1);
        Observer.Observe('after Get', Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent."Child Amount" := 99;
        Observer.Observe('read at once', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Commit();
        asserterror begin
            Parent.Modify();
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Modify()', Result);
        if Result = 'ok' then
            Parent.Modify();
        Observer.Observe('after Modify', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Other.Get(1);
        Observer.Observe('other var Get', Format(Other."Child Count") + '/' + Format(Other."Child Amount"));
        Parent.Get(1);
        Observer.Observe('same var Get', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Parent."Child Count" := 7;
        Parent.CalcFields("Child Count", "Child Amount");
        Observer.Observe('CalcFields', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Observer.Observe('src after', Src());
        Observer.Observe('parents', Parents());
        Observer.Observe('log', TakeLog());
        Observer.Expect('src before', 'n=4;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15');
        Observer.Expect('after Get', '0');
        Observer.Expect('read at once', '7/99');
        Observer.Expect('Modify()', 'ok');
        Observer.Expect('after Modify', '7/99');
        Observer.Expect('other var Get', '0/0');
        Observer.Expect('same var Get', '0/0');
        Observer.Expect('CalcFields', '3/60');
        Observer.Expect('src after', 'n=4;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15');
        Observer.Expect('parents', 'n=3;1|P1;2|P2;3|P3');
        Observer.Expect('log', 'n=0');
        Observer.Verify();
    end;

    // ---- item 2: assignment on a new record, then Insert, Get and CalcFields ----
    [Test]
    procedure DI_AssignThenInsert()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Other: Record "LT DI FW Parent";
        Result: Text;
    begin
        Seed();
        AddChild(5, 10, 'E', 1, 20260101D);
        Observer.Observe('src before', Src());
        Parent.Init();
        Parent."No." := 10;
        Parent.Name := 'P10';
        Parent."Child Count" := 7;
        Parent."Child Amount" := 99;
        Parent."Has Children" := false;
        Parent."First Child Code" := 'ZZ';
        Commit();
        asserterror begin
            Parent.Insert(true);
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Insert(true)', Result);
        if Result = 'ok' then
            Parent.Insert(true);
        Observer.Observe('after Insert', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount") + '/' + Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Observer.Observe('log', TakeLog());
        Other.Get(10);
        Observer.Observe('Get', Format(Other."Child Count") + '/' + Format(Other."Child Amount") + '/' + Format(Other."Has Children") + '/' + Other."First Child Code");
        Other.CalcFields("Child Count", "Child Amount", "Has Children", "First Child Code");
        Observer.Observe('CalcFields', Format(Other."Child Count") + '/' + Format(Other."Child Amount") + '/' + Format(Other."Has Children") + '/' + Other."First Child Code");
        Observer.Observe('src after', Src());
        Observer.Observe('parents', Parents());
        Observer.Expect('src before', 'n=5;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15;5|10|E|1|2026-01-01');
        Observer.Expect('Insert(true)', 'ok');
        Observer.Expect('after Insert', '7/99/No/ZZ');
        Observer.Expect('log', 'n=1;OnInsert Child Count=7');
        Observer.Expect('Get', '0/0/No/');
        Observer.Expect('CalcFields', '1/1/Yes/E');
        Observer.Expect('src after', 'n=5;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15;5|10|E|1|2026-01-01');
        Observer.Expect('parents', 'n=4;1|P1;2|P2;3|P3;10|P10');
        Observer.Verify();
    end;

    // ---- item 3: Validate on a FlowField (Count with an OnValidate trigger, Sum without one) ----
    [Test]
    procedure DI_ValidateFlowField()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Result: Text;
    begin
        Seed();
        Parent.Get(1);
        Commit();
        asserterror begin
            Parent.Validate("Child Count", 7);
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Validate count', Result);
        Observer.Observe('log in asserterror', TakeLog());
        Parent.Get(1);
        if Result = 'ok' then
            Parent.Validate("Child Count", 7);
        Observer.Observe('count after', Format(Parent."Child Count"));
        Observer.Observe('log', TakeLog());
        Commit();
        asserterror begin
            Parent.Validate("Child Amount", 99);
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Validate amount', Result);
        if Result = 'ok' then
            Parent.Validate("Child Amount", 99);
        Observer.Observe('amount after', Format(Parent."Child Amount"));
        Commit();
        asserterror begin
            Parent.Modify(true);
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Modify(true)', Result);
        if Result = 'ok' then
            Parent.Modify(true);
        Observer.Observe('log after modify', TakeLog());
        Observer.Observe('stored', StoredCount(1) + ' calc ' + CalcCount(1));
        Observer.Observe('src after', Src());
        Observer.Expect('Validate count', 'error:The type of the Child Count FlowField in the LT DI FW Parent table must be Decimal.|FlowFieldValidation');
        Observer.Expect('log in asserterror', 'n=0');
        Observer.Expect('count after', '0');
        Observer.Expect('log', 'n=0');
        Observer.Expect('Validate amount', 'ok');
        Observer.Expect('amount after', '99');
        Observer.Expect('Modify(true)', 'ok');
        Observer.Expect('log after modify', 'n=1;OnModify Rec.Child Count=0 xRec.Child Count=0 Rec.Name=P1 xRec.Name=P1');
        Observer.Expect('stored', '0 calc 4');
        Observer.Expect('src after', 'n=5;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15;5|1||39|');
        Observer.Verify();
    end;

    // item 4 (ModifyAll on a FlowField) does not compile: AL0779, must-not-compile cases 1370 and 1888.

    local procedure Snap(var Versions: Dictionary of [Integer, BigInteger]; var Stamps: Dictionary of [Integer, DateTime])
    var
        Parent: Record "LT DI FW Parent";
    begin
        Clear(Versions);
        Clear(Stamps);
        if Parent.FindSet() then
            repeat
                Versions.Add(Parent."No.", Parent.SystemRowVersion);
                Stamps.Add(Parent."No.", Parent.SystemModifiedAt);
            until Parent.Next() = 0;
    end;

    // For every parent row: no:rowversion changed (yes/no), SystemModifiedAt changed (yes/no).
    local procedure ChangedRows(Versions: Dictionary of [Integer, BigInteger]; Stamps: Dictionary of [Integer, DateTime]): Text
    var
        Parent: Record "LT DI FW Parent";
        Result: Text;
    begin
        if Parent.FindSet() then
            repeat
                Result += Format(Parent."No.") + ':rv ' + Format(Parent.SystemRowVersion <> Versions.Get(Parent."No.")) + ' at ' + Format(Parent.SystemModifiedAt <> Stamps.Get(Parent."No.")) + ';';
            until Parent.Next() = 0;
        exit(Result);
    end;

    // ---- item 5: Modify(true) when only a FlowField was changed: OnModify, xRec, SystemRowVersion, SystemModifiedAt ----
    [Test]
    procedure DI_ModifyOnlyFlowFieldChanged()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Versions: Dictionary of [Integer, BigInteger];
        Stamps: Dictionary of [Integer, DateTime];
    begin
        Seed();
        // a: Get, assign, Modify(true)
        Snap(Versions, Stamps);
        Sleep(30);
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.Modify(true);
        Observer.Observe('a changed', ChangedRows(Versions, Stamps));
        Observer.Observe('a log', TakeLog());
        // b: Get, CalcFields, assign, Modify(true)
        Snap(Versions, Stamps);
        Sleep(30);
        Parent.Get(1);
        Parent.CalcFields("Child Count");
        Parent."Child Count" := 7;
        Parent.Modify(true);
        Observer.Observe('b changed', ChangedRows(Versions, Stamps));
        Observer.Observe('b log', TakeLog());
        // c: Get, nothing changed, Modify(true)
        Snap(Versions, Stamps);
        Sleep(30);
        Parent.Get(1);
        Parent.Modify(true);
        Observer.Observe('c changed', ChangedRows(Versions, Stamps));
        Observer.Observe('c log', TakeLog());
        // d: Get, assign, Modify(false)
        Snap(Versions, Stamps);
        Sleep(30);
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.Modify(false);
        Observer.Observe('d changed', ChangedRows(Versions, Stamps));
        Observer.Observe('d log', TakeLog());
        Observer.Observe('src after', Src());
        Observer.Expect('a changed', '1:rv No at No;2:rv No at No;3:rv No at No;');
        Observer.Expect('a log', 'n=1;OnModify Rec.Child Count=7 xRec.Child Count=7 Rec.Name=P1 xRec.Name=P1');
        Observer.Expect('b changed', '1:rv No at No;2:rv No at No;3:rv No at No;');
        Observer.Expect('b log', 'n=1;OnModify Rec.Child Count=7 xRec.Child Count=7 Rec.Name=P1 xRec.Name=P1');
        Observer.Expect('c changed', '1:rv No at No;2:rv No at No;3:rv No at No;');
        Observer.Expect('c log', 'n=1;OnModify Rec.Child Count=0 xRec.Child Count=0 Rec.Name=P1 xRec.Name=P1');
        Observer.Expect('d changed', '1:rv No at No;2:rv No at No;3:rv No at No;');
        Observer.Expect('d log', 'n=0');
        Observer.Expect('src after', 'n=4;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15');
        Observer.Verify();
    end;

    // ---- item 6: RecordRef / FieldRef on a FlowField: Class, Value :=, Validate, RecRef.Modify ----
    [Test]
    procedure DI_FieldRefWrite()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        RecRef: RecordRef;
        FRef: FieldRef;
        Result: Text;
    begin
        Seed();
        Parent.Get(1);
        RecRef.GetTable(Parent);
        FRef := RecRef.Field(3);
        Observer.Observe('class', Format(FRef.Class()) + '/' + Format(RecRef.Field(4).Class()) + '/' + Format(RecRef.Field(7).Class()));
        Observer.Observe('value before', Format(FRef.Value()));
        Commit();
        asserterror begin
            FRef.Value := 7;
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Value :=', Result);
        if Result = 'ok' then
            FRef.Value := 7;
        Observer.Observe('value after', Format(FRef.Value()) + '/' + Format(RecRef.Field(3).Value()));
        Commit();
        asserterror begin
            RecRef.Modify();
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('RecRef.Modify', Result);
        if Result = 'ok' then
            RecRef.Modify();
        Observer.Observe('value after modify', Format(RecRef.Field(3).Value()));
        Observer.Observe('stored', StoredCount(1) + ' calc ' + CalcCount(1));
        Commit();
        asserterror begin
            FRef.Validate(8);
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Validate(8)', Result);
        Observer.Observe('log in asserterror', TakeLog());
        if Result = 'ok' then
            FRef.Validate(8);
        Observer.Observe('value after validate', Format(FRef.Value()));
        Observer.Observe('log', TakeLog());
        FRef.CalcField();
        Observer.Observe('CalcField', Format(FRef.Value()));
        Observer.Observe('src after', Src());
        Observer.Expect('class', 'FlowField/FlowField/FlowFilter');
        Observer.Expect('value before', '0');
        Observer.Expect('Value :=', 'ok');
        Observer.Expect('value after', '7/7');
        Observer.Expect('RecRef.Modify', 'ok');
        Observer.Expect('value after modify', '7');
        Observer.Expect('stored', '0 calc 3');
        Observer.Expect('Validate(8)', 'error:The type of the Child Count FlowField in the LT DI FW Parent table must be Decimal.|FlowFieldValidation');
        Observer.Expect('log in asserterror', 'n=0');
        Observer.Expect('value after validate', '7');
        Observer.Expect('log', 'n=0');
        Observer.Expect('CalcField', '3');
        Observer.Expect('src after', 'n=4;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15');
        Observer.Verify();
    end;

    // ---- item 7: TransferFields and record assignment with an assigned and with a calculated FlowField ----
    [Test]
    procedure DI_TransferFieldsAndAssign()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT DI FW Parent";
        Target: Record "LT DI FW Parent";
        CopyRow: Record "LT DI FW Copy";
    begin
        Seed();
        // assigned value
        Source.Get(1);
        Source."Child Count" := 7;
        Target.Get(2);
        Target.TransferFields(Source);
        Observer.Observe('assigned TF', Format(Target."No.") + '/' + Format(Target."Child Count"));
        Clear(Target);
        Target.Init();
        Target.TransferFields(Source);
        Observer.Observe('assigned Init TF', Format(Target."No.") + '/' + Format(Target."Child Count"));
        Clear(Target);
        Target.Get(2);
        Target.TransferFields(Source, false);
        Observer.Observe('assigned TF false', Format(Target."No.") + '/' + Format(Target."Child Count"));
        Clear(Target);
        Target := Source;
        Observer.Observe('assigned :=', Format(Target."No.") + '/' + Format(Target."Child Count"));
        CopyRow.Init();
        CopyRow.TransferFields(Source);
        Observer.Observe('assigned to normal', Format(CopyRow."No.") + '/' + Format(CopyRow."Child Count"));
        // calculated value
        Source.Get(1);
        Source.CalcFields("Child Count", "Child Amount");
        Clear(Target);
        Target.Get(2);
        Target.TransferFields(Source);
        Observer.Observe('calc TF', Format(Target."No.") + '/' + Format(Target."Child Count") + '/' + Format(Target."Child Amount"));
        Clear(Target);
        Target.Init();
        Target.TransferFields(Source);
        Observer.Observe('calc Init TF', Format(Target."No.") + '/' + Format(Target."Child Count") + '/' + Format(Target."Child Amount"));
        Clear(Target);
        Target := Source;
        Observer.Observe('calc :=', Format(Target."No.") + '/' + Format(Target."Child Count") + '/' + Format(Target."Child Amount"));
        Clear(CopyRow);
        CopyRow.Init();
        CopyRow.TransferFields(Source);
        Observer.Observe('calc to normal', Format(CopyRow."No.") + '/' + Format(CopyRow."Child Count") + '/' + Format(CopyRow."Child Amount"));
        // normal field into a FlowField
        Clear(CopyRow);
        CopyRow."No." := 5;
        CopyRow."Child Count" := 9;
        CopyRow."Child Amount" := 4.5;
        Clear(Target);
        Target.TransferFields(CopyRow);
        Observer.Observe('normal to flow', Format(Target."No.") + '/' + Format(Target."Child Count") + '/' + Format(Target."Child Amount"));
        Observer.Observe('src after', Src());
        Observer.Observe('parents', Parents());
        Observer.Expect('assigned TF', '1/7');
        Observer.Expect('assigned Init TF', '1/7');
        Observer.Expect('assigned TF false', '2/7');
        Observer.Expect('assigned :=', '1/7');
        Observer.Expect('assigned to normal', '1/0');
        Observer.Expect('calc TF', '1/3/60');
        Observer.Expect('calc Init TF', '1/3/60');
        Observer.Expect('calc :=', '1/3/60');
        Observer.Expect('calc to normal', '1/0/0');
        Observer.Expect('normal to flow', '5/0/0');
        Observer.Expect('src after', 'n=4;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15');
        Observer.Expect('parents', 'n=3;1|P1;2|P2;3|P3');
        Observer.Verify();
    end;

    // ---- item 8: an assigned FlowField value after Init, Clear, Reset, Find, Next, Get and SetAutoCalcFields ----
    [Test]
    procedure DI_AssignedValueLifetime()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
    begin
        Seed();
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.Init();
        Observer.Observe('Init', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent.Get(1);
        Parent."Child Count" := 7;
        Clear(Parent);
        Observer.Observe('Clear', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.Reset();
        Observer.Observe('Reset', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.SetRange("No.", 1);
        Parent.Find('-');
        Observer.Observe('Find', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent.Reset();
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.Next();
        Observer.Observe('Next', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent.Get(1);
        Observer.Observe('Get', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent.Get(3);
        Observer.Observe('Get other', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Clear(Parent);
        Parent.SetAutoCalcFields("Child Count");
        Parent.Get(1);
        Parent."Child Count" := 7;
        Observer.Observe('auto assigned', Format(Parent."Child Count"));
        Parent.Get(1);
        Observer.Observe('auto Get', Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent.SetRange("No.", 1, 3);
        Parent.FindFirst();
        Observer.Observe('auto FindFirst', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent.Next();
        Observer.Observe('auto Next', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent.Modify();
        Observer.Observe('auto after Modify', Format(Parent."Child Count"));
        Observer.Observe('src after', Src());
        Observer.Expect('Init', '1/0');
        Observer.Expect('Clear', '0/0');
        Observer.Expect('Reset', '1/7');
        Observer.Expect('Find', '1/0');
        Observer.Expect('Next', '2/0');
        Observer.Expect('Get', '1/0');
        Observer.Expect('Get other', '3/0');
        Observer.Expect('auto assigned', '7');
        Observer.Expect('auto Get', '3');
        Observer.Expect('auto FindFirst', '1/3');
        Observer.Expect('auto Next', '2/0');
        Observer.Expect('auto after Modify', '7');
        Observer.Expect('src after', 'n=4;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15');
        Observer.Verify();
    end;

    // ---- item 9: a temporary record: assignment, Modify, Get, CalcFields ----
    [Test]
    procedure DI_TemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
        TempParent: Record "LT DI FW Parent" temporary;
    begin
        Seed();
        TempParent.Init();
        TempParent."No." := 1;
        TempParent."Child Count" := 5;
        TempParent.Insert();
        TempParent.Get(1);
        Observer.Observe('insert then Get', Format(TempParent."Child Count"));
        TempParent."Child Count" := 7;
        TempParent.Modify();
        Observer.Observe('after Modify', Format(TempParent."Child Count"));
        Clear(TempParent."Child Count");
        TempParent.Get(1);
        Observer.Observe('after Get', Format(TempParent."Child Count"));
        TempParent.FindFirst();
        Observer.Observe('after FindFirst', Format(TempParent."Child Count"));
        TempParent.CalcFields("Child Count");
        Observer.Observe('CalcFields', Format(TempParent."Child Count"));
        TempParent.Get(1);
        Observer.Observe('Get after CalcFields', Format(TempParent."Child Count"));
        TempParent.Init();
        TempParent."No." := 2;
        TempParent."Child Count" := 4;
        TempParent.Insert();
        TempParent.CalcFields("Child Count");
        Observer.Observe('row 2 CalcFields', Format(TempParent."Child Count"));
        Observer.Observe('log', TakeLog());
        Observer.Observe('src after', Src());
        Observer.Observe('parents', Parents());
        Observer.Expect('insert then Get', '0');
        Observer.Expect('after Modify', '7');
        Observer.Expect('after Get', '7');
        Observer.Expect('after FindFirst', '7');
        Observer.Expect('CalcFields', '3');
        Observer.Expect('Get after CalcFields', '7');
        Observer.Expect('row 2 CalcFields', '0');
        Observer.Expect('log', 'n=0');
        Observer.Expect('src after', 'n=4;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15');
        Observer.Expect('parents', 'n=3;1|P1;2|P2;3|P3');
        Observer.Verify();
    end;

    // ---- item 10: Exist (Boolean) and Lookup (Text) FlowFields with an assigned value ----
    [Test]
    procedure DI_ExistAndLookupAssigned()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Result: Text;
    begin
        Seed();
        Parent.Get(1);
        Observer.Observe('Get', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Parent."Has Children" := false;
        Parent."First Child Code" := 'ZZ';
        Observer.Observe('read at once', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Parent.Get(2);
        Parent."Has Children" := true;
        Parent."First Child Code" := 'YY';
        Observer.Observe('row 2 assigned', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Commit();
        asserterror begin
            Parent.Modify();
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Modify()', Result);
        if Result = 'ok' then
            Parent.Modify();
        Observer.Observe('after Modify', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Parent.Get(2);
        Observer.Observe('after Get', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Parent."Has Children" := true;
        Parent."First Child Code" := 'YY';
        Parent.CalcFields("Has Children", "First Child Code");
        Observer.Observe('CalcFields', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Commit();
        asserterror begin
            Parent.Validate("Has Children", true);
            Error(NoErrorTok);
        end;
        Observer.Observe('Validate exist', Outcome());
        Commit();
        asserterror begin
            Parent.Validate("First Child Code", 'QQ');
            Error(NoErrorTok);
        end;
        Observer.Observe('Validate lookup', Outcome());
        Observer.Observe('src after', Src());
        Observer.Expect('Get', 'No/');
        Observer.Expect('read at once', 'No/ZZ');
        Observer.Expect('row 2 assigned', 'Yes/YY');
        Observer.Expect('Modify()', 'ok');
        Observer.Expect('after Modify', 'Yes/YY');
        Observer.Expect('after Get', 'No/');
        Observer.Expect('CalcFields', 'No/');
        Observer.Expect('Validate exist', 'error:The type of the Has Children FlowField in the LT DI FW Parent table must be Decimal.|FlowFieldValidation');
        Observer.Expect('Validate lookup', 'error:The type of the First Child Code FlowField in the LT DI FW Parent table must be Decimal.|FlowFieldValidation');
        Observer.Expect('src after', 'n=4;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15');
        Observer.Verify();
    end;

    // ---- item 11: assignment to a FlowFilter field, then Modify, Get and CalcFields ----
    [Test]
    procedure DI_FlowFilterAssigned()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Result: Text;
    begin
        Seed();
        Parent.Get(1);
        Parent.CalcFields("Child Amount");
        Observer.Observe('no filter', Format(Parent."Child Amount"));
        Parent."Date Filter" := 20260110D;
        Observer.Observe('read at once', Format(Parent."Date Filter", 0, 9) + ' getfilter=' + Parent.GetFilter("Date Filter"));
        Parent.CalcFields("Child Amount");
        Observer.Observe('CalcFields with assigned', Format(Parent."Child Amount"));
        Commit();
        asserterror begin
            Parent.Modify();
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Modify()', Result);
        if Result = 'ok' then
            Parent.Modify();
        Observer.Observe('after Modify', Format(Parent."Date Filter", 0, 9));
        Parent.Get(1);
        Observer.Observe('after Get', Format(Parent."Date Filter", 0, 9));
        Parent.CalcFields("Child Amount");
        Observer.Observe('CalcFields after Get', Format(Parent."Child Amount"));
        Parent.SetRange("Date Filter", 20260110D);
        Parent.CalcFields("Child Amount");
        Observer.Observe('CalcFields with SetRange', Format(Parent."Child Amount") + ' field=' + Format(Parent."Date Filter", 0, 9));
        Observer.Observe('src after', Src());
        Observer.Observe('parents', Parents());
        Observer.Expect('no filter', '60');
        Observer.Expect('read at once', '2026-01-10 getfilter=');
        Observer.Expect('CalcFields with assigned', '60');
        Observer.Expect('Modify()', 'ok');
        Observer.Expect('after Modify', '2026-01-10');
        Observer.Expect('after Get', '');
        Observer.Expect('CalcFields after Get', '60');
        Observer.Expect('CalcFields with SetRange', '10 field=');
        Observer.Expect('src after', 'n=4;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15');
        Observer.Expect('parents', 'n=3;1|P1;2|P2;3|P3');
        Observer.Verify();
    end;

    // ---- item 13: CalcFields on a record whose FlowField was assigned, then Modify ----
    [Test]
    procedure DI_CalcFieldsAfterAssign()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Versions: Dictionary of [Integer, BigInteger];
        Stamps: Dictionary of [Integer, DateTime];
    begin
        Seed();
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent."Child Amount" := 99;
        Parent.CalcFields("Child Count");
        Observer.Observe('CalcFields one', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Parent.CalcFields("Child Amount");
        Observer.Observe('CalcFields both', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Snap(Versions, Stamps);
        Sleep(30);
        Parent.Modify(true);
        Observer.Observe('changed', ChangedRows(Versions, Stamps));
        Observer.Observe('log', TakeLog());
        Observer.Observe('after Modify', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Observer.Observe('stored', StoredCount(1) + ' calc ' + CalcCount(1));
        Observer.Observe('src after', Src());
        Observer.Expect('CalcFields one', '3/99');
        Observer.Expect('CalcFields both', '3/60');
        Observer.Expect('changed', '1:rv No at No;2:rv No at No;3:rv No at No;');
        Observer.Expect('log', 'n=1;OnModify Rec.Child Count=3 xRec.Child Count=3 Rec.Name=P1 xRec.Name=P1');
        Observer.Expect('after Modify', '3/60');
        Observer.Expect('stored', '0 calc 3');
        Observer.Expect('src after', 'n=4;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15');
        Observer.Verify();
    end;

    // ---- item 3 (continued): Validate on a Sum FlowField writes a row into the CalcFormula source table ----
    [Test]
    procedure DI_ValidateSumFlowFieldSourceRow()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
    begin
        Seed();
        AddChild(100, 3, 'X', 1, 20260115D);
        // parent 2 has no rows; a Date Filter value is set
        Parent.Get(2);
        Parent.SetRange("Date Filter", 20260401D);
        Parent.Validate("Child Amount", 7);
        Observer.Observe('p2 value', Format(Parent."Child Amount"));
        Observer.Observe('p2 src', Src());
        Parent.CalcFields("Child Amount");
        Observer.Observe('p2 CalcFields', Format(Parent."Child Amount"));
        // parent 1: an assigned value in memory, then Validate
        Parent.Reset();
        Parent.Get(1);
        Parent."Child Amount" := 1000;
        Parent.Validate("Child Amount", 70);
        Observer.Observe('p1 value', Format(Parent."Child Amount"));
        Observer.Observe('p1 src', Src());
        // parent 1: the value it already has
        Parent.Get(1);
        Parent.CalcFields("Child Amount");
        Parent.Validate("Child Amount", 70);
        Observer.Observe('p1 same src', Src());
        // parent 3: a Date Filter range
        Parent.Get(3);
        Parent.SetRange("Date Filter", 20260101D, 20260131D);
        Parent.Validate("Child Amount", 2);
        Observer.Observe('p3 range src', Src());
        Observer.Observe('log', TakeLog());
        Observer.Observe('parents', Parents());
        Observer.Expect('p2 value', '7');
        Observer.Expect('p2 src', 'n=6;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15;100|3|X|1|2026-01-15;101|2||7|2026-04-01');
        Observer.Expect('p2 CalcFields', '7');
        Observer.Expect('p1 value', '70');
        Observer.Expect('p1 src', 'n=7;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15;100|3|X|1|2026-01-15;101|2||7|2026-04-01;102|1||10|');
        Observer.Expect('p1 same src', 'n=7;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15;100|3|X|1|2026-01-15;101|2||7|2026-04-01;102|1||10|');
        Observer.Expect('p3 range src', 'n=8;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15;100|3|X|1|2026-01-15;101|2||7|2026-04-01;102|1||10|;103|3||-4|2026-01-01');
        Observer.Expect('log', 'n=0');
        Observer.Expect('parents', 'n=3;1|P1;2|P2;3|P3');
        Observer.Verify();
    end;

    // ---- writer QB, #665 question 14: the one-argument Validate(Field) on FlowFields that have an OnValidate trigger (table 86380) ----
    local procedure QbValidate(var QbParent: Record "LT QB FW Parent"; Which: Text)
    begin
        case Which of
            'count':
                QbParent.Validate("Child Count");
            'amount':
                QbParent.Validate("Child Amount");
            'exist':
                QbParent.Validate("Has Children");
            'lookup':
                QbParent.Validate("First Child Code");
        end;
    end;

    local procedure QbTry(var QbParent: Record "LT QB FW Parent"; Which: Text): Text
    var
        Result: Text;
    begin
        Commit();
        asserterror begin
            QbValidate(QbParent, Which);
            Error(NoErrorTok);
        end;
        Result := Outcome();
        if Result = 'ok' then
            QbValidate(QbParent, Which);
        exit(Result);
    end;

    [Test]
    procedure QB_ValidateOneArgFlowFieldWithOnValidate()
    var
        Observer: Codeunit "Probe Observer";
        QbParent: Record "LT QB FW Parent";
    begin
        Seed();
        QbParent.DeleteAll(false);
        QbParent.Init();
        QbParent."No." := 1;
        QbParent.Insert(false);
        TakeLog();
        // no CalcFields: the FlowFields hold their initial values in the variable
        QbParent.Get(1);
        Observer.Observe('count', QbTry(QbParent, 'count'));
        Observer.Observe('count value', Format(QbParent."Child Count"));
        Observer.Observe('count log', TakeLog());
        Observer.Observe('amount', QbTry(QbParent, 'amount'));
        Observer.Observe('amount value', Format(QbParent."Child Amount"));
        Observer.Observe('amount log', TakeLog());
        Observer.Observe('amount src', Src());
        Observer.Observe('exist', QbTry(QbParent, 'exist'));
        Observer.Observe('exist log', TakeLog());
        Observer.Observe('lookup', QbTry(QbParent, 'lookup'));
        Observer.Observe('lookup log', TakeLog());
        // after CalcFields: the Sum FlowField holds the current sum
        Seed();
        QbParent.Get(1);
        QbParent.CalcFields("Child Amount", "Child Count");
        Observer.Observe('calc amount before', Format(QbParent."Child Amount"));
        Observer.Observe('calc amount', QbTry(QbParent, 'amount'));
        Observer.Observe('calc amount value', Format(QbParent."Child Amount"));
        Observer.Observe('calc amount log', TakeLog());
        Observer.Observe('calc amount src', Src());
        Observer.Observe('calc count', QbTry(QbParent, 'count'));
        Observer.Observe('calc count log', TakeLog());
        // an assigned value in the Sum FlowField, then the one-argument Validate
        Seed();
        QbParent.Get(1);
        QbParent."Child Amount" := 100;
        Observer.Observe('assigned amount', QbTry(QbParent, 'amount'));
        Observer.Observe('assigned amount value', Format(QbParent."Child Amount"));
        Observer.Observe('assigned amount log', TakeLog());
        Observer.Observe('assigned amount src', Src());
        Observer.Expect('count', 'error:The type of the Child Count FlowField in the LT QB FW Parent table must be Decimal.|FlowFieldValidation');
        Observer.Expect('count value', '0');
        Observer.Expect('count log', 'n=0');
        Observer.Expect('amount', 'ok');
        Observer.Expect('amount value', '0');
        Observer.Expect('amount log', 'n=1;OnValidate Child Amount Rec=0 xRec=0');
        Observer.Expect('amount src', 'n=5;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15;5|1||-60|');
        Observer.Expect('exist', 'error:The type of the Has Children FlowField in the LT QB FW Parent table must be Decimal.|FlowFieldValidation');
        Observer.Expect('exist log', 'n=0');
        Observer.Expect('lookup', 'error:The type of the First Child Code FlowField in the LT QB FW Parent table must be Decimal.|FlowFieldValidation');
        Observer.Expect('lookup log', 'n=0');
        Observer.Expect('calc amount before', '60');
        Observer.Expect('calc amount', 'ok');
        Observer.Expect('calc amount value', '60');
        Observer.Expect('calc amount log', 'n=1;OnValidate Child Amount Rec=60 xRec=60');
        Observer.Expect('calc amount src', 'n=4;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15');
        Observer.Expect('calc count', 'error:The type of the Child Count FlowField in the LT QB FW Parent table must be Decimal.|FlowFieldValidation');
        Observer.Expect('calc count log', 'n=0');
        Observer.Expect('assigned amount', 'ok');
        Observer.Expect('assigned amount value', '100');
        Observer.Expect('assigned amount log', 'n=1;OnValidate Child Amount Rec=100 xRec=100');
        Observer.Expect('assigned amount src', 'n=5;1|1|A|10|2026-01-10;2|1|B|20|2026-02-10;3|1|C|30|2026-03-10;4|3|D|5|2026-01-15;5|1||40|');
        Observer.Verify();
    end;

    // ---- Writer SF, al-runner issue 5857: a value assigned to a FlowFilter field of a TEMPORARY record, then Insert and a read back
    // (FindFirst, Get, Next), on a TableType = Temporary table (89330, the shape of Base Application table 265 "Document Entry") and on a
    // temporary variable of a normal table (LT DI FW Parent "Date Filter").

    [Test]
    procedure SF_FlowFilter_TemporaryTableType_InsertThenRead()
    var
        Observer: Codeunit "Probe Observer";
        TempBuffer: Record "LT SF FF Temp Buffer";
    begin
        TempBuffer.Init();
        TempBuffer."Entry No." := 1;
        TempBuffer."Document No." := 'DOC-001';
        TempBuffer.Description := 'First';
        TempBuffer.Insert();
        TempBuffer.Init();
        TempBuffer."Entry No." := 2;
        TempBuffer."Document No." := 'DOC-002';
        TempBuffer.Description := 'Second';
        TempBuffer.Insert();
        Observer.Observe('after Init and Insert', TempBuffer."Document No.");
        TempBuffer.FindFirst();
        Observer.Observe('FindFirst', TempBuffer.Description + '|' + TempBuffer."Document No." + '|getfilter=' + TempBuffer.GetFilter("Document No."));
        TempBuffer.Next();
        Observer.Observe('Next', TempBuffer.Description + '|' + TempBuffer."Document No.");
        TempBuffer.Get(1);
        Observer.Observe('Get(1)', TempBuffer.Description + '|' + TempBuffer."Document No.");
        TempBuffer."Document No." := 'DOC-009';
        TempBuffer.Modify();
        TempBuffer.Get(2);
        TempBuffer.Get(1);
        Observer.Observe('Get(1) after Modify', TempBuffer.Description + '|' + TempBuffer."Document No.");
        Observer.Observe('count', Format(TempBuffer.Count()));
        Observer.Expect('after Init and Insert', 'DOC-002');
        Observer.Expect('FindFirst', 'First|DOC-001|getfilter=');
        Observer.Expect('Next', 'Second|DOC-002');
        Observer.Expect('Get(1)', 'First|DOC-001');
        Observer.Expect('Get(1) after Modify', 'First|DOC-009');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure SF_FlowFilter_TemporaryVariable_InsertThenRead()
    var
        Observer: Codeunit "Probe Observer";
        TempParent: Record "LT DI FW Parent" temporary;
    begin
        TempParent.Init();
        TempParent."No." := 1;
        TempParent."Date Filter" := 20260110D;
        TempParent.Insert();
        TempParent.Init();
        TempParent."No." := 2;
        TempParent."Date Filter" := 20260210D;
        TempParent.Insert();
        TempParent.FindFirst();
        Observer.Observe('FindFirst', Format(TempParent."No.") + '|' + Format(TempParent."Date Filter", 0, 9));
        TempParent.Get(2);
        Observer.Observe('Get(2)', Format(TempParent."No.") + '|' + Format(TempParent."Date Filter", 0, 9));
        Observer.Expect('FindFirst', '1|2026-01-10');
        Observer.Expect('Get(2)', '2|2026-02-10');
        Observer.Verify();
    end;
}
