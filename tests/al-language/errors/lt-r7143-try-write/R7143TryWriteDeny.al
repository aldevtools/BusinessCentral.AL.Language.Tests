// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-using-try-methods
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 95991, helper codeunit 95993.
// Probe (al-runner issue 7143, writer r7143): the write methods that were not pinned yet inside a TryFunction whose result is used, on the
//   CI containers (server setting DisableWriteInsideTryFunctions at its default): Delete, DeleteAll (with rows and on an empty table), ModifyAll
//   and Rename. Each test calls a procedure that returns the TryFunction's result (`exit(TryX())`, the reporter's shape) under asserterror and
//   records the error text (the scope name masked as <scope>), the error code, the value the call returned and the rows afterwards.
//   Insert, Modify and Commit are pinned in errors/CuTryTests.al and errors/Y68Small.al.
// BC versions: 27.0+

table 95991 "LT R7143 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 95993 "LT R7143 Writer"
{
    procedure DeleteOne(): Boolean
    begin
        exit(TryDeleteOne());
    end;

    procedure DeleteAllRows(): Boolean
    begin
        exit(TryDeleteAllRows());
    end;

    procedure ModifyAllRows(): Boolean
    begin
        exit(TryModifyAllRows());
    end;

    procedure RenameOne(): Boolean
    begin
        exit(TryRenameOne());
    end;

    [TryFunction]
    local procedure TryDeleteOne()
    var
        Row: Record "LT R7143 Row";
    begin
        Row.Get(1);
        Row.Delete();
    end;

    [TryFunction]
    local procedure TryDeleteAllRows()
    var
        Row: Record "LT R7143 Row";
    begin
        Row.DeleteAll();
    end;

    [TryFunction]
    local procedure TryModifyAllRows()
    var
        Row: Record "LT R7143 Row";
    begin
        Row.ModifyAll(Description, 'all');
    end;

    [TryFunction]
    local procedure TryRenameOne()
    var
        Row: Record "LT R7143 Row";
    begin
        Row.Get(1);
        Row.Rename(10);
    end;
}

codeunit 95992 "LT R7143 Try Write Deny"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure R7143_Delete_InTryFunction_ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        Writer: Codeunit "LT R7143 Writer";
        Ok: Boolean;
    begin
        Initialize(true);
        asserterror Ok := Writer.DeleteOne();
        ObserveOutcome(Observer, Ok);
        Observer.Finish();
    end;

    [Test]
    procedure R7143_DeleteAll_InTryFunction_ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        Writer: Codeunit "LT R7143 Writer";
        Ok: Boolean;
    begin
        Initialize(true);
        asserterror Ok := Writer.DeleteAllRows();
        ObserveOutcome(Observer, Ok);
        Observer.Finish();
    end;

    [Test]
    procedure R7143_DeleteAll_EmptyTable_InTryFunction_ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        Writer: Codeunit "LT R7143 Writer";
        Ok: Boolean;
    begin
        Initialize(false);
        asserterror Ok := Writer.DeleteAllRows();
        ObserveOutcome(Observer, Ok);
        Observer.Finish();
    end;

    [Test]
    procedure R7143_ModifyAll_InTryFunction_ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        Writer: Codeunit "LT R7143 Writer";
        Ok: Boolean;
    begin
        Initialize(true);
        asserterror Ok := Writer.ModifyAllRows();
        ObserveOutcome(Observer, Ok);
        Observer.Finish();
    end;

    [Test]
    procedure R7143_Rename_InTryFunction_ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        Writer: Codeunit "LT R7143 Writer";
        Ok: Boolean;
    begin
        Initialize(true);
        asserterror Ok := Writer.RenameOne();
        ObserveOutcome(Observer, Ok);
        Observer.Finish();
    end;

    local procedure Initialize(WithRows: Boolean)
    var
        Row: Record "LT R7143 Row";
    begin
        Row.DeleteAll();
        if WithRows then begin
            Row."No." := 1;
            Row.Description := 'one';
            Row.Insert();
            Row."No." := 2;
            Row.Description := 'two';
            Row.Insert();
        end;
        Commit();
        ClearLastError();
    end;

    local procedure ObserveOutcome(var Observer: Codeunit "Probe Observer"; Ok: Boolean)
    var
        Row: Record "LT R7143 Row";
        Rows: Text;
    begin
        Observer.Observe('text', MaskScope(GetLastErrorText()));
        Observer.Observe('code', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('ok', Format(Ok));
        if Row.FindSet() then
            repeat
                Rows += Format(Row."No.") + '=' + Row.Description + ';';
            until Row.Next() = 0;
        Observer.Observe('rows after', Rows);
    end;

    local procedure MaskScope(ErrorText: Text): Text
    var
        Marker: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        Marker := 'inside the call to ''';
        StartPos := ErrorText.IndexOf(Marker);
        if StartPos = 0 then
            exit(ErrorText);
        StartPos += StrLen(Marker);
        EndPos := ErrorText.Substring(StartPos).IndexOf('''');
        if EndPos = 0 then
            exit(ErrorText);
        exit(ErrorText.Substring(1, StartPos - 1) + '<scope>' + ErrorText.Substring(StartPos + EndPos - 1));
    end;
}
