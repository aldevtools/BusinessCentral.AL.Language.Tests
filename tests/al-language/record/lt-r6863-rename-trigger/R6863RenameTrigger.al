// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 94970-94973
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
        NextId: Integer;
        UseRef: Boolean;

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

    procedure SetNext(NewId: Integer; NewUseRef: Boolean)
    begin
        NextId := NewId;
        UseRef := NewUseRef;
    end;

    procedure NextRename(var NewId: Integer): Boolean
    begin
        NewId := NextId;
        exit(UseRef);
    end;

    procedure RaiseError(): Boolean
    begin
        exit(Raise);
    end;

    procedure Describe(): Text
    begin
        exit(StrSubstNo('hits=%1 rec=%2 xrec=%3', Hits, LastRec, LastXRec));
    end;
}

codeunit 94973 "LT R6863 Do Rename"
{
    TableNo = "LT R6863 Work";

    trigger OnRun()
    var
        Cfg: Codeunit "LT R6863 Cfg";
        Ref: RecordRef;
        NewId: Integer;
    begin
        if Cfg.NextRename(NewId) then begin
            Ref.GetTable(Rec);
            Ref.Rename(NewId);
            Ref.SetTable(Rec);
        end else
            Rec.Rename(NewId);
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
        Observer.Finish();
    end;

    [Test]
    procedure R6863_Rename_SameValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameSame(Observer, true);
        RenameSame(Observer, false);
        Observer.Finish();
    end;

    [Test]
    procedure R6863_Rename_ToExistingValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameExisting(Observer, true);
        RenameExisting(Observer, false);
        Observer.Finish();
    end;

    [Test]
    procedure R6863_Rename_NeverInserted()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameMissing(Observer, true);
        RenameMissing(Observer, false);
        Observer.Finish();
    end;

    [Test]
    procedure R6863_Rename_ThroughRecordRef()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameRef(Observer, true);
        RenameRef(Observer, false);
        Observer.Finish();
    end;

    [Test]
    procedure R6863_Rename_TemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RenameTemp(Observer, true);
        RenameTemp(Observer, false);
        Observer.Finish();
    end;

    [Test]
    procedure R6863_Rename_AfterTheErrorTheRowIsUntouched()
    var
        Observer: Codeunit "Probe Observer";
        W: Record "LT R6863 Work";
        Cfg: Codeunit "LT R6863 Cfg";
        First: Integer;
    begin
        W.DeleteAll();
        Cfg.Reset(true);
        W.Payload := 'a';
        W.Insert(true);
        First := W.ID;
        Observer.Observe('ok', Format(RunRename(W, W.ID + 1000, false)));
        Observer.ObserveError('rename');
        Observer.Observe('rec.ID changed', Format(W.ID <> First));
        Observer.Observe('old row exists', Format(W.Get(First)));
        Observer.Observe('count', Format(W.Count()));
        W.Payload := 'b';
        W.Modify(true);
        Observer.Observe('modify after error: payload', Format(W.Payload));
        W.Init();
        W.Payload := 'c';
        W.Insert(true);
        Observer.Observe('next id is first + 1', Format(W.ID = First + 1));
        Observer.Finish();
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
        Probe: Record "LT R6863 Work";
    begin
        Observer.ObserveError(Label);
        Observer.Observe(Label + ' trigger', Cfg.Describe());
        Observer.Observe(Label + ' old row exists', Format(Probe.Get(First)));
        Observer.Observe(Label + ' rows', Format(Probe.Count()));
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
        First: Integer;
        Label: Text;
    begin
        Label := 'missing raise=' + Format(Raise);
        Setup(Raise, W, Observer, Label);
        First := W.ID;
        Missing.ID := First + 500;
        Observer.Observe(Label + ' ok', Format(RunRename(Missing, First + 600, false)));
        Observer.ObserveError(Label);
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
        Observer.ObserveError(Label);
        Observer.Observe(Label + ' trigger', Cfg.Describe());
        Observer.Observe(Label + ' rows', Format(T.Count()));
        Observer.Observe(Label + ' rec.ID', Format(T.ID));
    end;

    local procedure RunRename(var W: Record "LT R6863 Work"; NewId: Integer; UseRef: Boolean): Boolean
    var
        Cfg: Codeunit "LT R6863 Cfg";
        DoRename: Codeunit "LT R6863 Do Rename";
    begin
        Cfg.SetNext(NewId, UseRef);
        exit(DoRename.Run(W));
    end;

    local procedure Describe(): Text
    var
        Cfg: Codeunit "LT R6863 Cfg";
    begin
        exit(Cfg.Describe());
    end;
}
