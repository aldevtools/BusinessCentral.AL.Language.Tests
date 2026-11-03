// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 94970-94972
// Probe (al-runner issue 6863, follow-up to 5517): the order of the checks in Rename on a table whose primary key is an AutoIncrement field
//   and that has an OnRename trigger. Pinned elsewhere: without a trigger, Rename of the AutoIncrement key raises the AutoIncrement error
//   (record/TestAutoIncrementExplicitKey.al:211). Not pinned: with a trigger, which of the two runs and raises first (the trigger has a
//   counter, and raises an error or not); Rename to the same value, to a value that exists, of a record that was never inserted; the same
//   through a RecordRef and a temporary record; and whether the row is untouched afterwards.
// BC versions: 27, 28, 29

table 94970 "LT R6863 Work"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ID; Integer) { AutoIncrement = true; }
        field(2; Payload; Text[30]) { }
    }

    keys
    {
        key(PK; ID) { Clustered = true; }
    }

    trigger OnRename()
    var
        Cfg: Codeunit "LT R6863 Cfg";
    begin
        Cfg.Hit(Rec.ID, xRec.ID);
        if Cfg.RaiseError() then
            Error('LT R6863 trigger error');
    end;
}

codeunit 94971 "LT R6863 Cfg"
{
    SingleInstance = true;

    var
        Raise: Boolean;
        Hits: Integer;
        LastRec: Integer;
        LastXRec: Integer;
        LastText: Text;
        LastCode: Text;

    procedure Reset(NewRaise: Boolean)
    begin
        Raise := NewRaise;
        Hits := 0;
        LastRec := -1;
        LastXRec := -1;
    end;

    procedure Hit(NewId: Integer; OldId: Integer)
    begin
        Hits += 1;
        LastRec := NewId;
        LastXRec := OldId;
    end;

    procedure RememberError(OldId: Integer; NewId: Integer)
    begin
        LastText := GetLastErrorText().Replace('''' + Format(OldId) + '''', '''<old>''').Replace('''' + Format(NewId) + '''', '''<new>''');
        LastCode := GetLastErrorCode();
    end;

    procedure LastErrorText(): Text
    begin
        exit(LastText);
    end;

    procedure LastErrorCode(): Text
    begin
        exit(LastCode);
    end;

    procedure RaiseError(): Boolean
    begin
        exit(Raise);
    end;

    procedure Describe(): Text
    begin
        exit(StrSubstNo('hits=%1 rec-xrec=%2', Hits, LastRec - LastXRec));
    end;
}

codeunit 94972 "LT R6863 Rename Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure R6863_Rename_NewValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameNew(Observer, true);
        RenameNew(Observer, false);
        Observer.Expect('new raise=Yes ok', 'No');
        Observer.Expect('new raise=Yes|text', 'LT R6863 trigger error');
        Observer.Expect('new raise=Yes|code', 'Dialog');
        Observer.Expect('new raise=Yes trigger', 'hits=1 rec-xrec=1000');
        Observer.Expect('new raise=Yes rec.ID is old', 'No');
        Observer.Expect('new raise=No ok', 'No');
        Observer.Expect('new raise=No|text', 'You cannot change the value of an AutoIncrement field.\\Field: ID\Table: LT R6863 Work\\Identification fields and values:\ID=''<new>''');
        Observer.Expect('new raise=No|code', 'DB:ModifyOnIdentityField');
        Observer.Expect('new raise=No trigger', 'hits=1 rec-xrec=1000');
        Observer.Expect('new raise=No rec.ID is old', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure R6863_Rename_SameValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameSame(Observer, true);
        RenameSame(Observer, false);
        Observer.Expect('same raise=Yes ok', 'No');
        Observer.Expect('same raise=Yes|text', 'LT R6863 trigger error');
        Observer.Expect('same raise=Yes|code', 'Dialog');
        Observer.Expect('same raise=Yes trigger', 'hits=1 rec-xrec=0');
        Observer.Expect('same raise=Yes rec.ID is old', 'Yes');
        Observer.Expect('same raise=No ok', 'Yes');
        Observer.Expect('same raise=No|text', 'LT R6863 no error');
        Observer.Expect('same raise=No|code', 'Dialog');
        Observer.Expect('same raise=No trigger', 'hits=1 rec-xrec=0');
        Observer.Expect('same raise=No rec.ID is old', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure R6863_Rename_ToExistingValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameExisting(Observer, true);
        RenameExisting(Observer, false);
        Observer.Expect('existing raise=Yes ok', 'No');
        Observer.Expect('existing raise=Yes|text', 'LT R6863 trigger error');
        Observer.Expect('existing raise=Yes|code', 'Dialog');
        Observer.Expect('existing raise=Yes trigger', 'hits=1 rec-xrec=1');
        Observer.Expect('existing raise=Yes rec.ID is old', 'No');
        Observer.Expect('existing raise=No ok', 'No');
        Observer.Expect('existing raise=No|text', 'You cannot change the value of an AutoIncrement field.\\Field: ID\Table: LT R6863 Work\\Identification fields and values:\ID=''<new>''');
        Observer.Expect('existing raise=No|code', 'DB:ModifyOnIdentityField');
        Observer.Expect('existing raise=No trigger', 'hits=1 rec-xrec=1');
        Observer.Expect('existing raise=No rec.ID is old', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure R6863_Rename_NeverInserted()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameMissing(Observer, true);
        RenameMissing(Observer, false);
        Observer.Expect('missing raise=Yes ok', 'No');
        Observer.Expect('missing raise=Yes|text', 'LT R6863 trigger error');
        Observer.Expect('missing raise=Yes|code', 'Dialog');
        Observer.Expect('missing raise=Yes trigger', 'hits=1 rec-xrec=100');
        Observer.Expect('missing raise=No ok', 'No');
        Observer.Expect('missing raise=No|text', 'The LT R6863 Work does not exist. Identification fields and values: ID=''<old>''');
        Observer.Expect('missing raise=No|code', 'DB:RecordNotFound');
        Observer.Expect('missing raise=No trigger', 'hits=1 rec-xrec=100');
        Observer.Verify();
    end;

    [Test]
    procedure R6863_Rename_ThroughRecordRef_TriggerRaises()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameRef(Observer, true);
        Observer.Expect('recordref raise=Yes ok', 'No');
        Observer.Expect('recordref raise=Yes|text', 'LT R6863 trigger error');
        Observer.Expect('recordref raise=Yes|code', 'Dialog');
        Observer.Expect('recordref raise=Yes trigger', 'hits=1 rec-xrec=1000');
        Observer.Expect('recordref raise=Yes rec.ID is old', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure R6863_Rename_ThroughRecordRef_TriggerQuiet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameRef(Observer, false);
        Observer.Expect('recordref raise=No ok', 'No');
        Observer.Expect('recordref raise=No|text', 'You cannot change the value of an AutoIncrement field.\\Field: ID\Table: LT R6863 Work\\Identification fields and values:\ID=''<new>''');
        Observer.Expect('recordref raise=No|code', 'DB:ModifyOnIdentityField');
        Observer.Expect('recordref raise=No trigger', 'hits=1 rec-xrec=1000');
        Observer.Expect('recordref raise=No rec.ID is old', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure R6863_Rename_TemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameTemp(Observer, true);
        RenameTemp(Observer, false);
        Observer.Expect('temporary raise=Yes ok', 'No');
        Observer.Expect('temporary raise=Yes|text', 'LT R6863 trigger error');
        Observer.Expect('temporary raise=Yes|code', 'Dialog');
        Observer.Expect('temporary raise=Yes trigger', 'hits=1 rec-xrec=1');
        Observer.Expect('temporary raise=Yes rows', '1');
        Observer.Expect('temporary raise=Yes rec.ID', '8');
        Observer.Expect('temporary raise=No ok', 'Yes');
        Observer.Expect('temporary raise=No|text', 'LT R6863 no error');
        Observer.Expect('temporary raise=No|code', 'Dialog');
        Observer.Expect('temporary raise=No trigger', 'hits=1 rec-xrec=1');
        Observer.Expect('temporary raise=No rows', '1');
        Observer.Expect('temporary raise=No rec.ID', '8');
        Observer.Verify();
    end;

    local procedure Setup(Raise: Boolean; var W: Record "LT R6863 Work"; var Observer: Codeunit "Probe Observer"; Label: Text)
    var
        Cfg: Codeunit "LT R6863 Cfg";
    begin
        W.DeleteAll();
        Cfg.Reset(Raise);
        W.Init();
        W.ID := 0;
        W.Payload := 'a';
        W.Insert(true);
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Label: Text; var W: Record "LT R6863 Work"; First: Integer)
    var
        Cfg: Codeunit "LT R6863 Cfg";
    begin
        Observer.Observe(Label + '|text', Cfg.LastErrorText());
        Observer.Observe(Label + '|code', Cfg.LastErrorCode());
        Observer.Observe(Label + ' trigger', Cfg.Describe());
        Observer.Observe(Label + ' rec.ID is old', Format(W.ID = First));
    end;

    local procedure RenameNew(var Observer: Codeunit "Probe Observer"; Raise: Boolean)
    var
        W: Record "LT R6863 Work";
        First: Integer;
        Label: Text;
    begin
        Label := 'new raise=' + Format(Raise);
        Setup(Raise, W, Observer, Label);
        First := W.ID;
        Observer.Observe(Label + ' ok', Format(RunRename(W, W.ID + 1000, false)));
        Report(Observer, Label, W, First);
    end;

    local procedure RenameSame(var Observer: Codeunit "Probe Observer"; Raise: Boolean)
    var
        W: Record "LT R6863 Work";
        First: Integer;
        Label: Text;
    begin
        Label := 'same raise=' + Format(Raise);
        Setup(Raise, W, Observer, Label);
        First := W.ID;
        Observer.Observe(Label + ' ok', Format(RunRename(W, W.ID, false)));
        Report(Observer, Label, W, First);
    end;

    local procedure RenameExisting(var Observer: Codeunit "Probe Observer"; Raise: Boolean)
    var
        W: Record "LT R6863 Work";
        Other: Record "LT R6863 Work";
        First: Integer;
        Label: Text;
    begin
        Label := 'existing raise=' + Format(Raise);
        Setup(Raise, W, Observer, Label);
        First := W.ID;
        Other.Init();
        Other.ID := 0;
        Other.Payload := 'b';
        Other.Insert(true);
        Observer.Observe(Label + ' ok', Format(RunRename(W, Other.ID, false)));
        Report(Observer, Label, W, First);
    end;

    local procedure RenameMissing(var Observer: Codeunit "Probe Observer"; Raise: Boolean)
    var
        W: Record "LT R6863 Work";
        Missing: Record "LT R6863 Work";
        Cfg: Codeunit "LT R6863 Cfg";
        First: Integer;
        Label: Text;
    begin
        Label := 'missing raise=' + Format(Raise);
        Setup(Raise, W, Observer, Label);
        First := W.ID;
        Missing.ID := First + 500;
        Observer.Observe(Label + ' ok', Format(RunRename(Missing, First + 600, false)));
        Observer.Observe(Label + '|text', Cfg.LastErrorText());
        Observer.Observe(Label + '|code', Cfg.LastErrorCode());
        Observer.Observe(Label + ' trigger', Describe());
    end;

    local procedure RenameRef(var Observer: Codeunit "Probe Observer"; Raise: Boolean)
    var
        W: Record "LT R6863 Work";
        Ref: RecordRef;
        First: Integer;
        Label: Text;
    begin
        Label := 'recordref raise=' + Format(Raise);
        Setup(Raise, W, Observer, Label);
        First := W.ID;
        Ref.GetTable(W);
        Observer.Observe(Label + ' ok', Format(RunRename(W, First + 1000, true)));
        Report(Observer, Label, W, First);
    end;

    local procedure RenameTemp(var Observer: Codeunit "Probe Observer"; Raise: Boolean)
    var
        T: Record "LT R6863 Work" temporary;
        Cfg: Codeunit "LT R6863 Cfg";
        Label: Text;
    begin
        Label := 'temporary raise=' + Format(Raise);
        Cfg.Reset(Raise);
        T.Init();
        T.ID := 7;
        T.Payload := 'a';
        T.Insert(false);
        Observer.Observe(Label + ' ok', Format(RunRename(T, 8, false)));
        Observer.Observe(Label + '|text', Cfg.LastErrorText());
        Observer.Observe(Label + '|code', Cfg.LastErrorCode());
        Observer.Observe(Label + ' trigger', Cfg.Describe());
        Observer.Observe(Label + ' rows', Format(T.Count()));
        Observer.Observe(Label + ' rec.ID', Format(T.ID));
    end;

    // True when the Rename ended without an error. The error text and code are kept in the Cfg codeunit.
    local procedure RunRename(var W: Record "LT R6863 Work"; NewId: Integer; UseRef: Boolean): Boolean
    var
        Ref: RecordRef;
        Cfg: Codeunit "LT R6863 Cfg";
        OldId: Integer;
    begin
        OldId := W.ID;
        if UseRef then begin
            Ref.GetTable(W);
            asserterror begin
                Ref.Rename(NewId);
                Error('LT R6863 no error');
            end;
            Ref.SetTable(W);
        end else
            asserterror begin
                W.Rename(NewId);
                Error('LT R6863 no error');
            end;
        Cfg.RememberError(OldId, NewId);
        exit(Cfg.LastErrorText() = 'LT R6863 no error');
    end;

    local procedure Describe(): Text
    var
        Cfg: Codeunit "LT R6863 Cfg";
    begin
        exit(Cfg.Describe());
    end;
}
