// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-using-try-methods
// Scope: in-scope (server setting DisableWriteInsideTryFunctions off, as on BC online)
// Fixtures used: none (the app is self-contained, so it can be published alone to a BC SaaS sandbox).
// Probe (al-runner issue 7143, writer r7143): with writes inside a TryFunction allowed, a procedure that returns the TryFunction's result
//   (`exit(TryX())`, the reporter's shape) is called for Insert, Modify, Delete, DeleteAll followed by Insert, ModifyAll, Rename and Commit,
//   and for an Insert followed by an Error inside the TryFunction. Each test records what the call returned, the last error and the rows
//   afterwards; one test reads what the install codeunit of this app wrote through a TryFunction in OnInstallAppPerDatabase.
//   The values come from BC 29 on a SaaS sandbox; the CI containers deny these writes (tests/al-language/errors/lt-r7143-try-write/).
// BC versions: 29.0 (SaaS sandbox)

table 96000 "LT R7143A Row"
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

table 96001 "LT R7143A Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Description; Text[250]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 96002 "LT R7143A Writer"
{
    procedure InsertRow(): Boolean
    begin
        exit(TryInsertRow());
    end;

    procedure ModifyRow(): Boolean
    begin
        exit(TryModifyRow());
    end;

    procedure DeleteRow(): Boolean
    begin
        exit(TryDeleteRow());
    end;

    procedure DeleteAllThenInsert(): Boolean
    begin
        exit(TryDeleteAllThenInsert());
    end;

    procedure ModifyAllRows(): Boolean
    begin
        exit(TryModifyAllRows());
    end;

    procedure RenameRow(): Boolean
    begin
        exit(TryRenameRow());
    end;

    procedure InsertThenError(): Boolean
    begin
        exit(TryInsertThenError());
    end;

    procedure CommitInside(): Boolean
    begin
        exit(TryCommitInside());
    end;

    [TryFunction]
    local procedure TryInsertRow()
    var
        Row: Record "LT R7143A Row";
    begin
        Row."No." := 3;
        Row.Description := 'three';
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryModifyRow()
    var
        Row: Record "LT R7143A Row";
    begin
        Row.Get(1);
        Row.Description := 'changed';
        Row.Modify();
    end;

    [TryFunction]
    local procedure TryDeleteRow()
    var
        Row: Record "LT R7143A Row";
    begin
        Row.Get(1);
        Row.Delete();
    end;

    [TryFunction]
    local procedure TryDeleteAllThenInsert()
    var
        Row: Record "LT R7143A Row";
    begin
        Row.DeleteAll();
        Row."No." := 10;
        Row.Description := 'ten';
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryModifyAllRows()
    var
        Row: Record "LT R7143A Row";
    begin
        Row.ModifyAll(Description, 'all');
    end;

    [TryFunction]
    local procedure TryRenameRow()
    var
        Row: Record "LT R7143A Row";
    begin
        Row.Get(1);
        Row.Rename(11);
    end;

    [TryFunction]
    local procedure TryInsertThenError()
    var
        Row: Record "LT R7143A Row";
    begin
        Row."No." := 4;
        Row.Description := 'four';
        Row.Insert();
        Error('R7143A error after insert');
    end;

    [TryFunction]
    local procedure TryCommitInside()
    var
        Row: Record "LT R7143A Row";
    begin
        Row."No." := 5;
        Row.Description := 'five';
        Row.Insert();
        Commit();
    end;
}

codeunit 96003 "LT R7143A Install"
{
    Subtype = Install;

    // The shape of al-runner issue 7143: install code creates a row, then writes to it through a TryFunction whose result is used
    // (`if Try() then;`). Writes only into a DataPerCompany = false log.
    trigger OnInstallAppPerDatabase()
    var
        Log: Record "LT R7143A Install Log";
        Ok: Boolean;
    begin
        Log.DeleteAll();
        Log."No." := 1;
        Log.Description := 'created';
        Log.Insert();
        ClearLastError();
        Ok := TrySetDescription(Log);
        Log.Init();
        Log."No." := 2;
        Log.Description := CopyStr('returned=' + Format(Ok) + ';error=' + GetLastErrorText(), 1, 250);
        if Log.Insert() then;
    end;

    [TryFunction]
    local procedure TrySetDescription(var Log: Record "LT R7143A Install Log")
    begin
        Log.Description := 'changed in try';
        Log.Modify();
    end;
}

codeunit 96004 "LT R7143A Try Write Allowed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Writer: Codeunit "LT R7143A Writer";
        Facts: Text;

    [Test]
    procedure R7143A_Insert()
    begin
        Initialize();
        Observe('ok', Format(Writer.InsertRow()));
        Finish();
    end;

    [Test]
    procedure R7143A_Modify()
    begin
        Initialize();
        Observe('ok', Format(Writer.ModifyRow()));
        Finish();
    end;

    [Test]
    procedure R7143A_Delete()
    begin
        Initialize();
        Observe('ok', Format(Writer.DeleteRow()));
        Finish();
    end;

    [Test]
    procedure R7143A_DeleteAllThenInsert()
    begin
        Initialize();
        Observe('ok', Format(Writer.DeleteAllThenInsert()));
        Finish();
    end;

    [Test]
    procedure R7143A_ModifyAll()
    begin
        Initialize();
        Observe('ok', Format(Writer.ModifyAllRows()));
        Finish();
    end;

    [Test]
    procedure R7143A_Rename()
    begin
        Initialize();
        Observe('ok', Format(Writer.RenameRow()));
        Finish();
    end;

    [Test]
    procedure R7143A_InsertThenError()
    begin
        Initialize();
        Observe('ok', Format(Writer.InsertThenError()));
        Finish();
    end;

    [Test]
    procedure R7143A_CommitInside()
    begin
        Initialize();
        Observe('ok', Format(Writer.CommitInside()));
        Finish();
    end;

    [Test]
    procedure R7143A_WriteThenLaterErrorInCaller()
    // The write inside the TryFunction succeeded; an error the caller raises afterwards (caught by asserterror) rolls back what?
    begin
        Initialize();
        asserterror ModifyThenFail();
        Observe('caller error', GetLastErrorText());
        ClearLastError();
        Finish();
    end;

    [Test]
    procedure R7143A_InstallWroteThroughTryFunction()
    var
        Log: Record "LT R7143A Install Log";
        Rows: Text;
    begin
        Facts := '';
        if Log.FindSet() then
            repeat
                Rows += Format(Log."No.") + '=' + Log.Description + ';';
            until Log.Next() = 0;
        Observe('install log', Rows);
        Error('OBSERVE:%1', Facts);
    end;

    local procedure ModifyThenFail()
    begin
        Observe('ok', Format(Writer.ModifyRow()));
        Error('R7143A caller error');
    end;

    local procedure Initialize()
    var
        Row: Record "LT R7143A Row";
    begin
        Facts := '';
        Row.DeleteAll();
        Row."No." := 1;
        Row.Description := 'one';
        Row.Insert();
        Row."No." := 2;
        Row.Description := 'two';
        Row.Insert();
        Commit();
        ClearLastError();
    end;

    local procedure Observe(Name: Text; Value: Text)
    begin
        Facts += Name + '=' + Value + '|';
    end;

    local procedure Finish()
    var
        Row: Record "LT R7143A Row";
        Rows: Text;
    begin
        Observe('last error', GetLastErrorText());
        if Row.FindSet() then
            repeat
                Rows += Format(Row."No.") + '=' + Row.Description + ';';
            until Row.Next() = 0;
        Observe('rows', Rows);
        Error('OBSERVE:%1', Facts);
    end;
}
