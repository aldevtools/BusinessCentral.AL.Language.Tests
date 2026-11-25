// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); OVB Doc (table 75730, OptionVarMembersCallee.al); own objects 75737..75739
//   (OVB Batch Mgt, OVB Batch Post Mgt, OVB Batch Shape Tests)
// local object: an Option carried through memberless var parameters and an integration event into a var parameter with
//   members, across a loop over rows, is what is under test.
// Probe (al-runner issue 8971): the shape of Base Application's batch posting of documents, with own objects. A batch
//   processor keeps a local Option " ",Skip,Update across the rows and hands it per row to a memberless var parameter of a
//   local procedure, which raises an integration event (IncludeSender) with a memberless var parameter. An automatic
//   subscriber hands its memberless var parameter to a local procedure with a memberless var parameter, which calls a table
//   procedure with a var parameter " ",Skip,Update. The table procedure leaves at Skip; at the blank member it sets Update
//   when the row is confirmed, else Skip. Queued path: a memberless local handed per row to the same local procedure.
//   Three rows; the first row is confirmed or declined.
// Facts: values are Format|ordinal. Event path: row 1 sees the blank member and sets Update (confirmed) or Skip (declined);
//   rows 2 and 3 then see Update, or leave at Skip. Every hop and the processor's local show Update|2 or Skip|1. Queued path:
//   the same decisions, but the hops and the memberless local show the number (2|2 or 1|1).
// BC versions: measured on 29.0 (local BC on Linux). 27.5 and 28.5: the corpus CI run of the pull request.
// The batch processor: a local with the members " ",Skip,Update, handed per row to a memberless var parameter, which hands
// it on to an integration event (IncludeSender) with a memberless var parameter.
codeunit 75737 "OVB Batch Mgt"
{
    procedure RunBatch(): Text
    var
        RecRef: RecordRef;
        Choice: Option " ",Skip,Update;
        Log: Text;
    begin
        RecRef.Open(Database::"OVB Doc");
        if RecRef.FindSet() then
            repeat
                Log += ProcessOne(RecRef, Choice) + ';';
            until RecRef.Next() = 0;
        RecRef.Close();
        exit(Log + 'end ' + Format(Choice) + '|' + Format(Choice, 0, 2));
    end;

    local procedure ProcessOne(var RecRef: RecordRef; var Choice: Option): Text
    begin
        OnBeforeProcessOne(RecRef, Choice);
        RecRef.Modify();
        exit(Format(Choice) + '|' + Format(Choice, 0, 2));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeProcessOne(var RecRef: RecordRef; var Choice: Option)
    begin
    end;
}

// The document side: an automatic subscriber hands its memberless var parameter to a local procedure with a memberless
// var parameter, which calls the table procedure (parameter with members " ",Skip,Update). RunQueued is the queued path:
// a memberless local handed per row to the same local procedure.
codeunit 75738 "OVB Batch Post Mgt"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVB Batch Mgt", 'OnBeforeProcessOne', '', false, false)]
    local procedure PrepareOnBeforeProcessOne(var RecRef: RecordRef; var Choice: Option)
    var
        Doc: Record "OVB Doc";
    begin
        RecRef.SetTable(Doc);
        PrepareDoc(Doc, Choice);
        RecRef.GetTable(Doc);
    end;

    local procedure PrepareDoc(var Doc: Record "OVB Doc"; var Choice: Option)
    begin
        Doc.SeenText := CopyStr(Doc.ConfirmOnce(Choice), 1, MaxStrLen(Doc.SeenText));
        Doc.AfterText := CopyStr(Format(Choice) + '|' + Format(Choice, 0, 2), 1, MaxStrLen(Doc.AfterText));
    end;

    procedure RunQueued(): Text
    var
        Doc: Record "OVB Doc";
        Choice: Option;
    begin
        if Doc.FindSet() then
            repeat
                PrepareDoc(Doc, Choice);
                Doc.Modify();
            until Doc.Next() = 0;
        exit(Format(Choice) + '|' + Format(Choice, 0, 2));
    end;
}

codeunit 75739 "OVB Batch Shape Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BatchEvent_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Batch Mgt";
        PostMgt: Codeunit "OVB Batch Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', BatchMgt.RunBatch());
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', 'Update|2;Update|2;Update|2;end Update|2');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', 'Update|2');
        Observer.Expect('row 2 inside', 'update');
        Observer.Expect('row 2 after', 'Update|2');
        Observer.Expect('row 3 inside', 'update');
        Observer.Expect('row 3 after', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure BatchEvent_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Batch Mgt";
        PostMgt: Codeunit "OVB Batch Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', BatchMgt.RunBatch());
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', 'Skip|1;Skip|1;Skip|1;end Skip|1');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', 'Skip|1');
        Observer.Expect('row 2 inside', 'skip-exit');
        Observer.Expect('row 2 after', 'Skip|1');
        Observer.Expect('row 3 inside', 'skip-exit');
        Observer.Expect('row 3 after', 'Skip|1');
        Observer.Verify();
    end;

    [Test]
    procedure BatchQueued_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Batch Mgt";
        PostMgt: Codeunit "OVB Batch Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunQueued());
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', '2|2');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', '2|2');
        Observer.Expect('row 2 inside', 'update');
        Observer.Expect('row 2 after', '2|2');
        Observer.Expect('row 3 inside', 'update');
        Observer.Expect('row 3 after', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure BatchQueued_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Batch Mgt";
        PostMgt: Codeunit "OVB Batch Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunQueued());
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', '1|1');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', '1|1');
        Observer.Expect('row 2 inside', 'skip-exit');
        Observer.Expect('row 2 after', '1|1');
        Observer.Expect('row 3 inside', 'skip-exit');
        Observer.Expect('row 3 after', '1|1');
        Observer.Verify();
    end;

    local procedure AddRow(NewId: Integer; NewConfirmed: Boolean)
    var
        Doc: Record "OVB Doc";
    begin
        Doc.Init();
        Doc.Id := NewId;
        Doc.Confirmed := NewConfirmed;
        Doc.Insert();
    end;
}
