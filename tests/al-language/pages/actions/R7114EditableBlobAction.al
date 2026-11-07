// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 95960-95965 (PG R7114 *)
// local object: the page's Editable/ModifyAllowed shape and the table's Blob field are what the test checks, and the action's code commits
// Probe: from al-runner issue 7114 (follow-up of testpage/RmReadOnlyBlob.al): an editable List and an editable Card (Editable and ModifyAllowed
//   left true) over a table with a Blob field that no stream writes. An action calls a codeunit that Gets the row into its own record
//   variable, sets Status and Doc No. and runs Modify(true), without and with a Commit after it; the action never touches Rec. Contrast: an
//   action that writes the Blob of Rec through a stream. Observed: the stored row after the action and after Close, and the log of the
//   page's OnModifyRecord (P.MODR) and the table's OnModify (T.MOD).
// Result (BC 27.5, 28.5 and 29.0 alike): an action that changes the row through its own record variable leaves Rec as no change for
//   the page: the page runs no OnModifyRecord and no Modify, after the action or at Close, with and without a Commit in the action, on the
//   List and the Card; the stored row keeps what the action stored, and the page shows it after the action. An action that writes the
//   Blob of Rec through a stream is saved right after the action (P.MODR;T.MOD), and nothing more at Close.
// BC versions: 27+ (tested by the corpus CI matrix)

table 95960 "PG R7114 File"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Status; Option) { OptionMembers = Open,Imported; }
        field(3; "Doc No."; Code[20]) { }
        field(4; Content; Blob) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "PG R7114 Log";
    begin
        Log.Add('T.MOD(' + Format(Status) + '/' + "Doc No." + ')');
    end;
}

page 95961 "PG R7114 List"
{
    PageType = List;
    SourceTable = "PG R7114 File";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Doc No."; Rec."Doc No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportNoCommit)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Import: Codeunit "PG R7114 Import";
                begin
                    Import.Import(Rec."Code", false);
                end;
            }
            action(ImportCommit)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Import: Codeunit "PG R7114 Import";
                begin
                    Import.Import(Rec."Code", true);
                end;
            }
            action(WriteBlob)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    OutS: OutStream;
                begin
                    Rec.Content.CreateOutStream(OutS);
                    OutS.WriteText('written');
                end;
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "PG R7114 Log";
    begin
        Log.Add('P.MODR(' + Format(Rec.Status) + '/' + Rec."Doc No." + ')');
        exit(true);
    end;
}

page 95962 "PG R7114 Card"
{
    PageType = Card;
    SourceTable = "PG R7114 File";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Status; Rec.Status) { ApplicationArea = All; }
            field("Doc No."; Rec."Doc No.") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportNoCommit)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Import: Codeunit "PG R7114 Import";
                begin
                    Import.Import(Rec."Code", false);
                end;
            }
            action(ImportCommit)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Import: Codeunit "PG R7114 Import";
                begin
                    Import.Import(Rec."Code", true);
                end;
            }
            action(WriteBlob)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    OutS: OutStream;
                begin
                    Rec.Content.CreateOutStream(OutS);
                    OutS.WriteText('written');
                end;
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "PG R7114 Log";
    begin
        Log.Add('P.MODR(' + Format(Rec.Status) + '/' + Rec."Doc No." + ')');
        exit(true);
    end;
}

codeunit 95963 "PG R7114 Import"
{
    procedure Import(FileCode: Code[10]; WithCommit: Boolean)
    var
        F: Record "PG R7114 File";
    begin
        F.Get(FileCode);
        F.Status := F.Status::Imported;
        F."Doc No." := 'DOC1';
        F.Modify(true);
        if WithCommit then
            Commit();
    end;
}

codeunit 95964 "PG R7114 Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        F: Record "PG R7114 File";
        Log: Codeunit "PG R7114 Log";
    begin
        F.DeleteAll();
        F."Code" := 'F1';
        F.Insert();
        F."Code" := 'F2';
        F.Insert();
        Log.Reset();
    end;

    local procedure Stored(): Text
    var
        F: Record "PG R7114 File";
    begin
        F.Get('F1');
        F.CalcFields(Content);
        exit(Format(F.Status) + '/' + F."Doc No." + '/blob=' + Format(F.Content.HasValue()));
    end;

    // Act: 1 = ImportNoCommit, 2 = ImportCommit, 3 = WriteBlob.
    local procedure RunList(var Observer: Codeunit "Probe Observer"; Act: Integer)
    var
        P: TestPage "PG R7114 List";
        Log: Codeunit "PG R7114 Log";
    begin
        P.OpenEdit();
        P.GoToKey('F1');
        Log.Reset();
        case Act of
            1:
                P.ImportNoCommit.Invoke();
            2:
                P.ImportCommit.Invoke();
            3:
                P.WriteBlob.Invoke();
        end;
        Observer.Observe('stored after action', Stored());
        Observer.Observe('log action', Log.Get());
        Observer.Observe('shown after action', P.Status.Value() + '/' + P."Doc No.".Value());
        Log.Reset();
        P.Close();
        Observer.Observe('stored after close', Stored());
        Observer.Observe('log close', Log.Get());
    end;

    local procedure RunCard(var Observer: Codeunit "Probe Observer"; Act: Integer)
    var
        P: TestPage "PG R7114 Card";
        Log: Codeunit "PG R7114 Log";
    begin
        P.OpenEdit();
        P.GoToKey('F1');
        Log.Reset();
        case Act of
            1:
                P.ImportNoCommit.Invoke();
            2:
                P.ImportCommit.Invoke();
            3:
                P.WriteBlob.Invoke();
        end;
        Observer.Observe('stored after action', Stored());
        Observer.Observe('log action', Log.Get());
        Observer.Observe('shown after action', P.Status.Value() + '/' + P."Doc No.".Value());
        Log.Reset();
        P.Close();
        Observer.Observe('stored after close', Stored());
        Observer.Observe('log close', Log.Get());
    end;

    [Test]
    procedure PG7114_EditableList_ActionModifiesOwnVar_NoCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunList(Observer, 1);
        Observer.Expect('stored after action', 'Imported/DOC1/blob=No');
        Observer.Expect('log action', 'T.MOD(Imported/DOC1)');
        Observer.Expect('shown after action', 'Imported/DOC1');
        Observer.Expect('stored after close', 'Imported/DOC1/blob=No');
        Observer.Expect('log close', '');
        Observer.Verify();
    end;

    [Test]
    procedure PG7114_EditableList_ActionModifiesOwnVar_Commit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunList(Observer, 2);
        Observer.Expect('stored after action', 'Imported/DOC1/blob=No');
        Observer.Expect('log action', 'T.MOD(Imported/DOC1)');
        Observer.Expect('shown after action', 'Imported/DOC1');
        Observer.Expect('stored after close', 'Imported/DOC1/blob=No');
        Observer.Expect('log close', '');
        Observer.Verify();
    end;

    [Test]
    procedure PG7114_EditableList_ActionWritesBlobOfRec()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunList(Observer, 3);
        Observer.Expect('stored after action', 'Open//blob=Yes');
        Observer.Expect('log action', 'P.MODR(Open/);T.MOD(Open/)');
        Observer.Expect('shown after action', 'Open/');
        Observer.Expect('stored after close', 'Open//blob=Yes');
        Observer.Expect('log close', '');
        Observer.Verify();
    end;

    [Test]
    procedure PG7114_EditableCard_ActionModifiesOwnVar_NoCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 1);
        Observer.Expect('stored after action', 'Imported/DOC1/blob=No');
        Observer.Expect('log action', 'T.MOD(Imported/DOC1)');
        Observer.Expect('shown after action', 'Imported/DOC1');
        Observer.Expect('stored after close', 'Imported/DOC1/blob=No');
        Observer.Expect('log close', '');
        Observer.Verify();
    end;

    [Test]
    procedure PG7114_EditableCard_ActionModifiesOwnVar_Commit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 2);
        Observer.Expect('stored after action', 'Imported/DOC1/blob=No');
        Observer.Expect('log action', 'T.MOD(Imported/DOC1)');
        Observer.Expect('shown after action', 'Imported/DOC1');
        Observer.Expect('stored after close', 'Imported/DOC1/blob=No');
        Observer.Expect('log close', '');
        Observer.Verify();
    end;

    [Test]
    procedure PG7114_EditableCard_ActionWritesBlobOfRec()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 3);
        Observer.Expect('stored after action', 'Open//blob=Yes');
        Observer.Expect('log action', 'P.MODR(Open/);T.MOD(Open/)');
        Observer.Expect('shown after action', 'Open/');
        Observer.Expect('stored after close', 'Open//blob=Yes');
        Observer.Expect('log close', '');
        Observer.Verify();
    end;
}

codeunit 95965 "PG R7114 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}
