// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-modifyallowed-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88270 - 88276 (writer RM)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: an action that changes nothing in Rec on a List with Editable = false and Insert/Modify/DeleteAllowed false (the shape of page
//   5339 "Integration Synch. Error List"), over a table with a Blob field and over the same table without it: the action runs, its Message
//   shows, no modify trigger runs and the row is unchanged. Variants: OpenView and OpenEdit, an action that only shows a Message, an action
//   that runs CalcFields on a Blob that holds a value. Log: R = OnAfterGetRecord, C = OnAfterGetCurrRecord, M = the page's OnModifyRecord,
//   T = the table's OnModify.
// Result (BC 27.5, 28.5, 29.0 alike): every action runs and its Message shows, with and without the Blob field, with OpenView and OpenEdit,
//   also after CalcFields on a Blob that holds a value. No modify trigger runs (no M or T in the log) and the row is unchanged; the page
//   reads its row again after each action (R;R;R;R;C;).
// Source: al-runner issue 5781.
// BC versions: 27, 28, 29

table 88270 "LT RM Logged Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 88271 "LT RM Blob Error"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Job; Integer) { }
        field(2; "Source Record ID"; RecordId) { }
        field(3; "Error Text"; Text[250]) { }
        field(4; "Run Id"; Guid) { }
        field(5; "Error Call Stack"; Blob) { }
    }

    keys
    {
        key(PK; Job, "Source Record ID") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "LT RM Blob Log";
    begin
        Log.Add('T');
    end;
}

table 88272 "LT RM Plain Error"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Job; Integer) { }
        field(2; "Source Record ID"; RecordId) { }
        field(3; "Error Text"; Text[250]) { }
        field(4; "Run Id"; Guid) { }
    }

    keys
    {
        key(PK; Job, "Source Record ID") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "LT RM Blob Log";
    begin
        Log.Add('T');
    end;
}

page 88273 "LT RM Blob Errors"
{
    PageType = List;
    SourceTable = "LT RM Blob Error";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Errors)
            {
                field(Job; Rec.Job) { }
                field(SourceRecord; SourceRecordText) { Caption = 'Record'; }
                field("Error Text"; Rec."Error Text") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Open)
            {
                Caption = 'Open';
                Enabled = HasRow;

                trigger OnAction()
                var
                    SourceRecordRef: RecordRef;
                begin
                    if not SourceRecordRef.Get(Rec."Source Record ID") then
                        Message(NoLongerExistsMsg, Format(Rec."Source Record ID", 0, 1));
                end;
            }
            action(OnlyMessage)
            {
                Caption = 'Only Message';

                trigger OnAction()
                begin
                    Message('only');
                end;
            }
            action(ReadStack)
            {
                Caption = 'Read Stack';

                trigger OnAction()
                var
                    InStr: InStream;
                    StackText: Text;
                begin
                    Rec.CalcFields("Error Call Stack");
                    Rec."Error Call Stack".CreateInStream(InStr);
                    InStr.ReadText(StackText);
                    Message('stack=%1', StackText);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SourceRecordText := Format(Rec."Source Record ID", 0, 1);
        Log.Add('R');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        HasRow := not IsNullGuid(Rec."Run Id");
        Log.Add('C');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M');
        exit(true);
    end;

    var
        Log: Codeunit "LT RM Blob Log";
        SourceRecordText: Text;
        HasRow: Boolean;
        NoLongerExistsMsg: Label 'The record %1 no longer exists.', Comment = '%1 = the record';
}

page 88274 "LT RM Plain Errors"
{
    PageType = List;
    SourceTable = "LT RM Plain Error";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Errors)
            {
                field(Job; Rec.Job) { }
                field(SourceRecord; SourceRecordText) { Caption = 'Record'; }
                field("Error Text"; Rec."Error Text") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Open)
            {
                Caption = 'Open';
                Enabled = HasRow;

                trigger OnAction()
                var
                    SourceRecordRef: RecordRef;
                begin
                    if not SourceRecordRef.Get(Rec."Source Record ID") then
                        Message(NoLongerExistsMsg, Format(Rec."Source Record ID", 0, 1));
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SourceRecordText := Format(Rec."Source Record ID", 0, 1);
        Log.Add('R');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        HasRow := not IsNullGuid(Rec."Run Id");
        Log.Add('C');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M');
        exit(true);
    end;

    var
        Log: Codeunit "LT RM Blob Log";
        SourceRecordText: Text;
        HasRow: Boolean;
        NoLongerExistsMsg: Label 'The record %1 no longer exists.', Comment = '%1 = the record';
}

codeunit 88275 "LT RM Blob Log"
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
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 88276 "LT RM Read Only Blob Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RM Blob Log";
        ShownMessages: Text;

    local procedure GoneRecordId(): RecordId
    var
        LoggedSource: Record "LT RM Logged Source";
    begin
        LoggedSource.Code := 'GONE';
        exit(LoggedSource.RecordId());
    end;

    local procedure InsertBlobRow(var BlobError: Record "LT RM Blob Error"; WithStack: Boolean)
    var
        OutStr: OutStream;
    begin
        BlobError.DeleteAll();
        BlobError.Init();
        BlobError.Job := 1;
        BlobError."Source Record ID" := GoneRecordId();
        BlobError."Error Text" := 'x';
        BlobError."Run Id" := CreateGuid();
        if WithStack then begin
            BlobError."Error Call Stack".CreateOutStream(OutStr);
            OutStr.WriteText('line 1');
        end;
        BlobError.Insert();
        Log.Reset();
        ShownMessages := '';
    end;

    local procedure RowState(): Text
    var
        BlobError: Record "LT RM Blob Error";
    begin
        BlobError.FindFirst();
        BlobError.CalcFields("Error Call Stack");
        exit(Format(BlobError.Count()) + '|' + BlobError."Error Text" + '|' + Format(BlobError."Error Call Stack".HasValue()));
    end;

    [Test]
    [HandlerFunctions('KeepMessageHandler')]
    procedure RM_Blob_OpenView_Open()
    var
        BlobError: Record "LT RM Blob Error";
        Errors: TestPage "LT RM Blob Errors";
    begin
        InsertBlobRow(BlobError, false);
        Errors.OpenView();
        Errors.GoToRecord(BlobError);
        Log.Take();
        Errors.Open.Invoke();
        Observer.Observe('action log', Log.Take());
        Errors.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('messages', ShownMessages);
        Observer.Observe('row', RowState());
        Observer.Expect('action log', 'R;R;R;R;C;');
        Observer.Expect('close log', '');
        Observer.Expect('messages', 'The record LT RM Logged Source: GONE no longer exists.');
        Observer.Expect('row', '1|x|No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('KeepMessageHandler')]
    procedure RM_Plain_OpenView_Open()
    var
        PlainError: Record "LT RM Plain Error";
        Errors: TestPage "LT RM Plain Errors";
    begin
        PlainError.DeleteAll();
        PlainError.Init();
        PlainError.Job := 1;
        PlainError."Source Record ID" := GoneRecordId();
        PlainError."Error Text" := 'x';
        PlainError."Run Id" := CreateGuid();
        PlainError.Insert();
        Log.Reset();
        ShownMessages := '';
        Errors.OpenView();
        Errors.GoToRecord(PlainError);
        Log.Take();
        Errors.Open.Invoke();
        Observer.Observe('action log', Log.Take());
        Errors.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('messages', ShownMessages);
        Observer.Expect('action log', 'R;R;R;R;C;');
        Observer.Expect('close log', '');
        Observer.Expect('messages', 'The record LT RM Logged Source: GONE no longer exists.');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('KeepMessageHandler')]
    procedure RM_Blob_OpenEdit_Open()
    var
        BlobError: Record "LT RM Blob Error";
        Errors: TestPage "LT RM Blob Errors";
    begin
        InsertBlobRow(BlobError, false);
        Errors.OpenEdit();
        Errors.GoToRecord(BlobError);
        Log.Take();
        Errors.Open.Invoke();
        Observer.Observe('action log', Log.Take());
        Errors.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('messages', ShownMessages);
        Observer.Observe('row', RowState());
        Observer.Expect('action log', 'R;R;R;R;C;');
        Observer.Expect('close log', '');
        Observer.Expect('messages', 'The record LT RM Logged Source: GONE no longer exists.');
        Observer.Expect('row', '1|x|No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('KeepMessageHandler')]
    procedure RM_Blob_OpenView_OnlyMessage()
    var
        BlobError: Record "LT RM Blob Error";
        Errors: TestPage "LT RM Blob Errors";
    begin
        InsertBlobRow(BlobError, false);
        Errors.OpenView();
        Errors.First();
        Log.Take();
        Errors.OnlyMessage.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('next', Format(Errors.Next()));
        Errors.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('messages', ShownMessages);
        Observer.Observe('row', RowState());
        Observer.Expect('action log', 'R;R;R;R;C;');
        Observer.Expect('next', 'No');
        Observer.Expect('close log', '');
        Observer.Expect('messages', 'only');
        Observer.Expect('row', '1|x|No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('KeepMessageHandler')]
    procedure RM_Blob_WithValue_OpenView_ReadStack()
    var
        BlobError: Record "LT RM Blob Error";
        Errors: TestPage "LT RM Blob Errors";
    begin
        InsertBlobRow(BlobError, true);
        Errors.OpenView();
        Errors.GoToRecord(BlobError);
        Log.Take();
        Errors.ReadStack.Invoke();
        Observer.Observe('action log', Log.Take());
        Errors.Open.Invoke();
        Observer.Observe('second action log', Log.Take());
        Errors.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('messages', ShownMessages);
        Observer.Observe('row', RowState());
        Observer.Expect('action log', 'R;R;R;R;C;');
        Observer.Expect('second action log', 'R;R;R;R;C;');
        Observer.Expect('close log', '');
        Observer.Expect('messages', 'stack=line 1 / The record LT RM Logged Source: GONE no longer exists.');
        Observer.Expect('row', '1|x|Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('KeepMessageHandler')]
    procedure RM_Blob_WithValue_OpenEdit_ReadStack()
    var
        BlobError: Record "LT RM Blob Error";
        Errors: TestPage "LT RM Blob Errors";
    begin
        InsertBlobRow(BlobError, true);
        Errors.OpenEdit();
        Errors.GoToRecord(BlobError);
        Log.Take();
        Errors.ReadStack.Invoke();
        Observer.Observe('action log', Log.Take());
        Errors.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('messages', ShownMessages);
        Observer.Observe('row', RowState());
        Observer.Expect('action log', 'R;R;R;R;C;');
        Observer.Expect('close log', '');
        Observer.Expect('messages', 'stack=line 1');
        Observer.Expect('row', '1|x|Yes');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure KeepMessageHandler(Message: Text[1024])
    begin
        if ShownMessages <> '' then
            ShownMessages += ' / ';
        ShownMessages += Message;
    end;
}
