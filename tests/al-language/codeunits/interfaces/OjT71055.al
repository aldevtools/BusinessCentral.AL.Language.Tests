// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 71055, helper codeunits 71056-71058, self-contained test codeunit 71059
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Codeunit.Run, OnRun, TableNo, rollback on error, SingleInstance state
// BC versions: 29 (27 and 28 by CI)

table 71055 "LT OjT Cu Tab"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Txt; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 71056 "LT OjT Run Plain"
{
    SingleInstance = false;

    trigger OnRun()
    var
        Row: Record "LT OjT Cu Tab";
    begin
        Row.Init();
        Row."No." := 1;
        Row.Txt := 'written by OnRun';
        Row.Insert();
        if Mode = 1 then
            Error('failure in OnRun');
    end;

    var
        Mode: Integer;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetMode(): Integer
    begin
        exit(Mode);
    end;
}

codeunit 71057 "LT OjT Run TableNo"
{
    TableNo = "LT OjT Cu Tab";

    trigger OnRun()
    begin
        Rec.Txt := 'changed:' + Rec.Txt;
        Rec."No." := Rec."No." + 100;
        if Rec.Txt = 'changed:fail' then
            Error('failing with %1', Rec."No.");
    end;
}

codeunit 71058 "LT OjT Counter SI"
{
    SingleInstance = true;

    var
        Count: Integer;
        Items: List of [Text];

    procedure Bump(): Integer
    begin
        Count += 1;
        exit(Count);
    end;

    procedure AddItem(Item: Text)
    begin
        Items.Add(Item);
    end;

    procedure ItemCount(): Integer
    begin
        exit(Items.Count());
    end;

    procedure Reset()
    begin
        Clear(Count);
        Clear(Items);
    end;
}

codeunit 71059 "LT OjT Codeunit Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ScrubCaller(Value: Text): Text
    var
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartPos := StrPos(Value, ' from the object ');
        EndPos := StrPos(Value, '. An object with that ID');
        if (StartPos = 0) or (EndPos < StartPos) then
            exit(Value);
        exit(CopyStr(Value, 1, StartPos - 1) + ' from the object <caller>' + CopyStr(Value, EndPos));
    end;

    [Test]
    procedure Run_ErrorRollsBackAndReturnsFalse()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT OjT Cu Tab";
        Plain: Codeunit "LT OjT Run Plain";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Plain.SetMode(1);
        asserterror Ok := Plain.Run();
        Observer.ObserveError('af130');
        Observer.Observe('result', Format(Ok));
        Observer.Observe('lastError', GetLastErrorText());
        Observer.Observe('rows', Format(Row.Count()));
        ClearLastError();
        Observer.Expect('af130|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af130|code', 'DB:Ok');
        Observer.Expect('result', 'No');
        Observer.Expect('lastError', '');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Run_VariableKeepsState()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT OjT Cu Tab";
        Plain: Codeunit "LT OjT Run Plain";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Plain.SetMode(7);
        asserterror Ok := Plain.Run();
        Observer.ObserveError('af149');
        Observer.Observe('result', Format(Ok));
        Observer.Observe('modeAfter', Format(Plain.GetMode()));
        Observer.Expect('af149|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af149|code', 'DB:Ok');
        Observer.Expect('result', 'No');
        Observer.Expect('modeAfter', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Run_AsserterrorOnErrorStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT OjT Cu Tab";
        Plain: Codeunit "LT OjT Run Plain";
    begin
        Row.DeleteAll();
        Plain.SetMode(1);
        asserterror Plain.Run();
        Observer.ObserveError('run');
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Expect('run|text', 'failure in OnRun');
        Observer.Expect('run|code', 'Dialog');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Run_WithTableNo()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT OjT Cu Tab";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row."No." := 5;
        Row.Txt := 'abc';
        asserterror Ok := Codeunit.Run(Codeunit::"LT OjT Run TableNo", Row);
        Observer.ObserveError('af181');
        Observer.Observe('result', Format(Ok));
        Observer.Observe('no', Format(Row."No."));
        Observer.Observe('txt', Row.Txt);
        Observer.Expect('af181|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af181|code', 'DB:Ok');
        Observer.Expect('result', 'No');
        Observer.Expect('no', '5');
        Observer.Expect('txt', 'abc');
        Observer.Verify();
    end;

    [Test]
    procedure Run_WithTableNo_Failure()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT OjT Cu Tab";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row."No." := 5;
        Row.Txt := 'fail';
        asserterror Ok := Codeunit.Run(Codeunit::"LT OjT Run TableNo", Row);
        Observer.ObserveError('af199');
        Observer.Observe('result', Format(Ok));
        Observer.Observe('lastError', GetLastErrorText());
        Observer.Observe('no', Format(Row."No."));
        Observer.Observe('txt', Row.Txt);
        ClearLastError();
        Observer.Expect('af199|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af199|code', 'DB:Ok');
        Observer.Expect('result', 'No');
        Observer.Expect('lastError', '');
        Observer.Expect('no', '5');
        Observer.Expect('txt', 'fail');
        Observer.Verify();
    end;

    [Test]
    procedure Run_ByIdOfUnknownCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        asserterror Ok := Codeunit.Run(71499);
        Observer.Observe('unknownId|text', ScrubCaller(GetLastErrorText()));
        Observer.Observe('unknownId|code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('unknownId|text', 'You tried to invoke the CodeUnit object with the ID 71499 from the object <caller>. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('unknownId|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure SingleInstance_StateAcrossVariables()
    var
        Observer: Codeunit "Probe Observer";
        A: Codeunit "LT OjT Counter SI";
        B: Codeunit "LT OjT Counter SI";
    begin
        A.Reset();
        Observer.Observe('a1', Format(A.Bump()));
        Observer.Observe('a2', Format(A.Bump()));
        Observer.Observe('b3', Format(B.Bump()));
        A.AddItem('x');
        B.AddItem('y');
        Observer.Observe('itemsA', Format(A.ItemCount()));
        Observer.Observe('itemsB', Format(B.ItemCount()));
        Observer.Observe('viaHelper', Format(HelperBump()));
        Observer.Expect('a1', '1');
        Observer.Expect('a2', '2');
        Observer.Expect('b3', '3');
        Observer.Expect('itemsA', '2');
        Observer.Expect('itemsB', '2');
        Observer.Expect('viaHelper', '4');
        Observer.Verify();
    end;

    [Test]
    procedure SingleInstance_StateAcrossTests()
    var
        Observer: Codeunit "Probe Observer";
        A: Codeunit "LT OjT Counter SI";
    begin
        Observer.Observe('continued', Format(A.Bump()));
        Observer.Observe('items', Format(A.ItemCount()));
        A.Reset();
        Observer.Observe('afterReset', Format(A.Bump()));
        A.Reset();
        Observer.Expect('continued', '5');
        Observer.Expect('items', '2');
        Observer.Expect('afterReset', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SingleInstance_ClearOfVariable()
    var
        Observer: Codeunit "Probe Observer";
        A: Codeunit "LT OjT Counter SI";
        B: Codeunit "LT OjT Counter SI";
    begin
        A.Reset();
        A.Bump();
        Clear(A);
        Observer.Observe('afterClearA', Format(B.Bump()));
        A.Reset();
        Observer.Expect('afterClearA', '2');
        Observer.Verify();
    end;

    local procedure HelperBump(): Integer
    var
        C: Codeunit "LT OjT Counter SI";
    begin
        exit(C.Bump());
    end;
}
