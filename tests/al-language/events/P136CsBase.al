// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74335, table extension 74336, codeunits 74337 74338 74339 74340
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read inside table triggers, table event subscribers (insert, modify, delete, rename, validate), table extension triggers and codeunit Run; the frames from the reader out to the test procedure, with the app suffix of each frame cut
// BC versions: 29 (27 and 28 by CI)

table 74335 "LT P136 CS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P136 CS Log";
            begin
                Log.Capture('tblNameValidate');
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('tblOnInsert');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('tblOnModify');
    end;

    trigger OnDelete()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('tblOnDelete');
    end;

    trigger OnRename()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('tblOnRename');
    end;
}

tableextension 74336 "LT P136 CS Row Ext" extends "LT P136 CS Row"
{
    fields
    {
        field(74336; Note; Text[50])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P136 CS Log";
            begin
                Log.Capture('extNoteValidate');
            end;
        }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('extOnInsert');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('extOnModify');
    end;
}

codeunit 74337 "LT P136 CS Log"
{
    SingleInstance = true;

    var
        Stacks: Dictionary of [Text, Text];

    procedure Reset()
    begin
        Clear(Stacks);
    end;

    procedure Capture(KeyName: Text)
    begin
        if Stacks.ContainsKey(KeyName) then
            Stacks.Set(KeyName, SessionInformation.Callstack())
        else
            Stacks.Add(KeyName, SessionInformation.Callstack());
    end;

    procedure Has(KeyName: Text): Boolean
    begin
        exit(Stacks.ContainsKey(KeyName));
    end;

    // the frames from the reader out to the test procedure (a procedure whose name starts with P136_), each without the app suffix, joined with ' < '
    procedure Frames(KeyName: Text): Text
    var
        Parts: List of [Text];
        Frame: Text;
        Result: Text;
    begin
        if not Stacks.ContainsKey(KeyName) then
            exit('not captured');
        Parts := Stacks.Get(KeyName).Split('\');
        foreach Frame in Parts do
            if Frame <> '' then begin
                if Result <> '' then
                    Result += ' < ';
                Result += StripApp(Frame);
                if Frame.Contains('.P136_') then
                    exit(CopyStr(Result, 1, 890));
            end;
        exit(CopyStr('no test procedure: ' + Result, 1, 890));
    end;

    local procedure StripApp(Frame: Text): Text
    var
        Last: Integer;
        Offset: Integer;
        P: Integer;
    begin
        repeat
            P := StrPos(CopyStr(Frame, Offset + 1), ' - ');
            if P > 0 then begin
                Last := Offset + P;
                Offset := Last;
            end;
        until P = 0;
        if Last > 0 then
            exit(CopyStr(Frame, 1, Last - 1));
        exit(Frame);
    end;
}

codeunit 74338 "LT P136 CS Subs"
{
    var
        Log: Codeunit "LT P136 CS Log";

    [EventSubscriber(ObjectType::Table, Database::"LT P136 CS Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SubBeforeInsert(var Rec: Record "LT P136 CS Row"; RunTrigger: Boolean)
    begin
        Log.Capture('subBeforeInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P136 CS Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure SubAfterInsert(var Rec: Record "LT P136 CS Row"; RunTrigger: Boolean)
    begin
        Log.Capture('subAfterInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P136 CS Row", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SubBeforeModify(var Rec: Record "LT P136 CS Row"; var xRec: Record "LT P136 CS Row"; RunTrigger: Boolean)
    begin
        Log.Capture('subBeforeModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P136 CS Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure SubAfterModify(var Rec: Record "LT P136 CS Row"; var xRec: Record "LT P136 CS Row"; RunTrigger: Boolean)
    begin
        Log.Capture('subAfterModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P136 CS Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SubBeforeDelete(var Rec: Record "LT P136 CS Row"; RunTrigger: Boolean)
    begin
        Log.Capture('subBeforeDelete');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P136 CS Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SubAfterDelete(var Rec: Record "LT P136 CS Row"; RunTrigger: Boolean)
    begin
        Log.Capture('subAfterDelete');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P136 CS Row", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SubBeforeRename(var Rec: Record "LT P136 CS Row"; var xRec: Record "LT P136 CS Row"; RunTrigger: Boolean)
    begin
        Log.Capture('subBeforeRename');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P136 CS Row", 'OnAfterRenameEvent', '', false, false)]
    local procedure SubAfterRename(var Rec: Record "LT P136 CS Row"; var xRec: Record "LT P136 CS Row"; RunTrigger: Boolean)
    begin
        Log.Capture('subAfterRename');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P136 CS Row", 'OnBeforeValidateEvent', 'Name', false, false)]
    local procedure SubBeforeValidate(var Rec: Record "LT P136 CS Row"; var xRec: Record "LT P136 CS Row"; CurrFieldNo: Integer)
    begin
        Log.Capture('subBeforeValidate');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P136 CS Row", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure SubAfterValidate(var Rec: Record "LT P136 CS Row"; var xRec: Record "LT P136 CS Row"; CurrFieldNo: Integer)
    begin
        Log.Capture('subAfterValidate');
    end;
}

codeunit 74339 "LT P136 CS Run"
{
    trigger OnRun()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('cuOnRun');
    end;
}

codeunit 74340 "LT P136 CS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P136 CS Log";

    local procedure Clean()
    var
        Row: Record "LT P136 CS Row";
    begin
        Row.DeleteAll();
        Log.Reset();
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; KeyName: Text)
    begin
        Observer.Observe(KeyName, Log.Frames(KeyName));
    end;

    [TryFunction]
    local procedure TryCapture()
    begin
        Log.Capture('tryFunction');
    end;

    [Test]
    procedure P136_Callstack_TableInsertTriggersAndEvents()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P136 CS Row";
    begin
        Clean();
        Row.Id := 1;
        Row.Insert(true);
        Show(Observer, 'subBeforeInsert');
        Show(Observer, 'tblOnInsert');
        Show(Observer, 'extOnInsert');
        Show(Observer, 'subAfterInsert');
        Clean();
        Row.Id := 2;
        Row.Insert(false);
        Observer.Observe('insertNoTriggerBefore', Format(Log.Has('subBeforeInsert')));
        Observer.Observe('insertNoTriggerTbl', Format(Log.Has('tblOnInsert')));
        Observer.Observe('insertNoTriggerAfter', Format(Log.Has('subAfterInsert')));
        Observer.Expect('subBeforeInsert', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubBeforeInsert line 2 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableInsertTriggersAndEvents line 7');
        Observer.Expect('tblOnInsert', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row"(Table 74335).OnInsert(Trigger) line 4 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableInsertTriggersAndEvents line 7');
        Observer.Expect('extOnInsert', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row Ext"(TableExtension 74336).OnInsert(Trigger) line 4 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableInsertTriggersAndEvents line 7');
        Observer.Expect('subAfterInsert', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubAfterInsert line 2 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableInsertTriggersAndEvents line 7');
        Observer.Expect('insertNoTriggerBefore', 'Yes');
        Observer.Expect('insertNoTriggerTbl', 'No');
        Observer.Expect('insertNoTriggerAfter', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P136_Callstack_TableModifyDeleteRename()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P136 CS Row";
    begin
        Clean();
        Row.Id := 1;
        Row.Insert(false);
        Log.Reset();
        Row.Name := 'x';
        Row.Modify(true);
        Show(Observer, 'subBeforeModify');
        Show(Observer, 'tblOnModify');
        Show(Observer, 'extOnModify');
        Show(Observer, 'subAfterModify');
        Log.Reset();
        Row.Rename(5);
        Show(Observer, 'subBeforeRename');
        Show(Observer, 'tblOnRename');
        Show(Observer, 'subAfterRename');
        Log.Reset();
        Row.Delete(true);
        Show(Observer, 'subBeforeDelete');
        Show(Observer, 'tblOnDelete');
        Show(Observer, 'subAfterDelete');
        Observer.Expect('subBeforeModify', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubBeforeModify line 2 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableModifyDeleteRename line 10');
        Observer.Expect('tblOnModify', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row"(Table 74335).OnModify(Trigger) line 4 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableModifyDeleteRename line 10');
        Observer.Expect('extOnModify', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row Ext"(TableExtension 74336).OnModify(Trigger) line 4 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableModifyDeleteRename line 10');
        Observer.Expect('subAfterModify', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubAfterModify line 2 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableModifyDeleteRename line 10');
        Observer.Expect('subBeforeRename', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubBeforeRename line 2 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableModifyDeleteRename line 16');
        Observer.Expect('tblOnRename', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row"(Table 74335).OnRename(Trigger) line 4 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableModifyDeleteRename line 16');
        Observer.Expect('subAfterRename', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubAfterRename line 2 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableModifyDeleteRename line 16');
        Observer.Expect('subBeforeDelete', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubBeforeDelete line 2 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableModifyDeleteRename line 21');
        Observer.Expect('tblOnDelete', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row"(Table 74335).OnDelete(Trigger) line 4 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableModifyDeleteRename line 21');
        Observer.Expect('subAfterDelete', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubAfterDelete line 2 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableModifyDeleteRename line 21');
        Observer.Verify();
    end;





    [Test]
    procedure P136_Callstack_TableValidateAndExtension()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P136 CS Row";
    begin
        Clean();
        Row.Validate(Name, 'abc');
        Show(Observer, 'subBeforeValidate');
        Show(Observer, 'tblNameValidate');
        Show(Observer, 'subAfterValidate');
        Row.Validate(Note, 'n');
        Show(Observer, 'extNoteValidate');
        Observer.Expect('subBeforeValidate', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubBeforeValidate line 2 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableValidateAndExtension line 6');
        Observer.Expect('tblNameValidate', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row"(Table 74335)."Name - OnValidate"(Trigger) line 4 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableValidateAndExtension line 6');
        Observer.Expect('subAfterValidate', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubAfterValidate line 2 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableValidateAndExtension line 6');
        Observer.Expect('extNoteValidate', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row Ext"(TableExtension 74336)."Note - OnValidate"(Trigger) line 4 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_TableValidateAndExtension line 10');
        Observer.Verify();
    end;

    [Test]
    procedure P136_Callstack_CodeunitRunAndTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Clean();
        Codeunit.Run(Codeunit::"LT P136 CS Run");
        Show(Observer, 'cuOnRun');
        Log.Reset();
        asserterror Ok := Codeunit.Run(Codeunit::"LT P136 CS Run");
        Observer.ObserveError('af335');
        Observer.Observe('cuRunResult', Format(Ok));
        Show(Observer, 'cuOnRun');
        Ok := TryCapture();
        Observer.Observe('tryResult', Format(Ok));
        Show(Observer, 'tryFunction');
        Observer.Expect('cuOnRun', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Run"(CodeUnit 74339).OnRun(Trigger) line 4 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_CodeunitRunAndTryFunction line 6');
        Observer.Expect('af335|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af335|code', 'DB:Ok');
        Observer.Expect('cuRunResult', 'No');
        Observer.Expect('cuOnRun', 'not captured');
        Observer.Expect('tryResult', 'Yes');
        Observer.Expect('tryFunction', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Tests"(CodeUnit 74340).TryCapture line 2 < "LT P136 CS Tests"(CodeUnit 74340).P136_Callstack_CodeunitRunAndTryFunction line 13');
        Observer.Verify();
    end;
}
