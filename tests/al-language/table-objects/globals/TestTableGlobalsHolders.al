// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: TGL Row (69670), TGL Log (69671), TGL Holder (69674), TGL Row Card (69673),
//                TGL Row List (69676), Assert (60021)
//
// Table globals when the record variable is held somewhere else: a codeunit's global variable
// (across calls on one codeunit instance, and between two instances), a local variable (fresh
// per call), and a page's Rec (across actions, field validation, and rows).

codeunit 69678 "TGL Holder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TGL Row";
        LogRec: Record "TGL Log";
    begin
        Row.DeleteAll(false);
        LogRec.DeleteAll(false);
    end;

    [Test]
    procedure TableGlobals_CodeunitGlobalRecord_PersistsAcrossCalls()
    // CLAIM: a record variable that is a codeunit global keeps the table's globals between calls on the codeunit instance.
    var
        Holder: Codeunit "TGL Holder";
        Seen: Text;
    begin
        Initialize();
        Holder.BumpRow();
        Holder.BumpRow();
        Holder.ValidateRow(8);
        Seen := StrSubstNo('%1|%2', Holder.RowCounter(), Holder.RowTag());
        Assert.AreEqual('3|V8', Seen, 'counter and tag after three calls');
    end;

    [Test]
    procedure TableGlobals_TwoCodeunitInstances_HaveTheirOwn()
    // CLAIM: two instances of one codeunit have separate record variables with separate table globals.
    var
        First: Codeunit "TGL Holder";
        Second: Codeunit "TGL Holder";
        Seen: Text;
    begin
        Initialize();
        First.BumpRow();
        First.BumpRow();
        Second.BumpRow();
        Seen := StrSubstNo('%1|%2', First.RowCounter(), Second.RowCounter());
        Assert.AreEqual('2|1', Seen, 'counters of the two instances');
    end;

    [Test]
    procedure TableGlobals_LocalRecordVariable_IsFreshPerCall()
    // CLAIM: a local record variable starts with fresh table globals at every call of the procedure.
    var
        Holder: Codeunit "TGL Holder";
        Seen: Text;
    begin
        Initialize();
        Seen := StrSubstNo('%1|%2|%3', Holder.LocalBump(), Holder.LocalBump(), Holder.LocalBump());
        Assert.AreEqual('1|1|1', Seen, 'local counters');
    end;

    [Test]
    procedure TableGlobals_AssignmentIntoCodeunitGlobal_WhatHappensToTheGlobals()
    // CLAIM (measured): assigning a record to a codeunit global record variable; its globals.
    var
        Holder: Codeunit "TGL Holder";
        Source: Record "TGL Row";
        Seen: Text;
    begin
        Initialize();
        Source."No." := 'S';
        Source.Bump();
        Source.Bump();
        Holder.BumpRow();
        Holder.SetRowFrom(Source);
        Seen := StrSubstNo('%1', Holder.RowCounter());
        Assert.AreEqual('1', Seen, 'global counter after assignment');
    end;
}

codeunit 69679 "TGL Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TGL Row";
        LogRec: Record "TGL Log";
    begin
        Row.DeleteAll(false);
        LogRec.DeleteAll(false);
    end;

    local procedure MakeRows()
    var
        Row: Record "TGL Row";
    begin
        Row."No." := 'A';
        Row.Insert();
        Row."No." := 'B';
        Row.Insert();
        Row."No." := 'C';
        Row.Insert();
    end;

    [Test]
    procedure TableGlobals_PageRec_PersistsAcrossActions()
    // CLAIM: a card page's Rec keeps the table's globals between two actions.
    var
        Card: TestPage "TGL Row Card";
        Seen: Text;
    begin
        Initialize();
        MakeRows();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.BumpRec.Invoke();
        Seen := Card.LastCount.Value();
        Card.BumpRec.Invoke();
        Seen += '|' + Card.LastCount.Value();
        Card.ReadRec.Invoke();
        Seen += '|' + Card.LastCount.Value();
        Card.Close();
        Assert.AreEqual('1|2|2', Seen, 'bump, bump, read');
    end;

    [Test]
    procedure TableGlobals_PageFieldValidate_ThenAction_SeesTheTriggerGlobals()
    // CLAIM (measured): a global set by a table field trigger run through the page is visible to a later action on the page's Rec.
    var
        Card: TestPage "TGL Row Card";
        Seen: Text;
    begin
        Initialize();
        MakeRows();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.Payload.SetValue(5);
        Card.ReadRec.Invoke();
        Seen := Card.LastCount.Value();
        Card.ReadSeen.Invoke();
        Seen += '|' + Card.LastCount.Value();
        Card.Close();
        Assert.AreEqual('0|0', Seen, 'counter set by OnValidate and length of the tag');
    end;

    [Test]
    procedure TableGlobals_ListPageRec_AcrossRows_WhatHappensToTheGlobals()
    // CLAIM (measured): on a list page, does the table's globals survive moving to the next row.
    var
        List: TestPage "TGL Row List";
        Seen: Text;
    begin
        Initialize();
        MakeRows();
        List.OpenEdit();
        List.GoToKey('A');
        List.BumpRec.Invoke();
        Seen := List.LastCount.Value();
        List.Next();
        List.BumpRec.Invoke();
        Seen += '|' + List.LastCount.Value();
        List.Next();
        List.BumpRec.Invoke();
        Seen += '|' + List.LastCount.Value();
        List.Close();
        Assert.AreEqual('1|2|3', Seen, 'bump on three rows');
    end;

    [Test]
    procedure TableGlobals_PageRec_AfterGetRecordSeesTheGlobals()
    // CLAIM (measured): OnAfterGetRecord on a card sees the globals an earlier action set on Rec.
    var
        Card: TestPage "TGL Row Card";
        Seen: Text;
    begin
        Initialize();
        MakeRows();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.BumpRec.Invoke();
        Card.BumpRec.Invoke();
        Card.GoToKey('B');
        Seen := Card.AfterGetCount.Value();
        Card.Close();
        Assert.AreEqual('2', Seen, 'counter seen in OnAfterGetRecord for the next row');
    end;

    [Test]
    procedure TableGlobals_PageInsert_OnInsertSeesTheValidateGlobals()
    // CLAIM (measured): a row created on a card page; the globals a field trigger set during page validation as OnInsert sees them.
    var
        Card: TestPage "TGL Row Card";
        Row: Record "TGL Row";
    begin
        Initialize();
        Card.OpenNew();
        Card."No.".SetValue('Z');
        Card.Payload.SetValue(5);
        Card.Close();
        Row.Get('Z');
        Assert.AreEqual('0|', Row.Seen, 'Seen written by OnInsert');
        Assert.AreEqual('0|', Row.RecSeen, 'RecSeen written by OnInsert');
    end;

    [Test]
    procedure TableGlobals_PageModify_OnModifySeesTheValidateGlobals()
    // CLAIM (measured): a row edited on a card page twice; the globals as OnModify sees them, and xRec's.
    var
        Card: TestPage "TGL Row Card";
        Row: Record "TGL Row";
    begin
        Initialize();
        MakeRows();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.Payload.SetValue(5);
        Card.Payload.SetValue(6);
        Card.Close();
        Row.Get('A');
        Assert.AreEqual('0|', Row.Seen, 'Seen written by OnModify');
        Assert.AreEqual('0|', Row.XSeen, 'XSeen written by OnModify');
    end;

    [Test]
    procedure TableGlobals_PageRec_ActionGlobalsAreLostAfterPageFieldValidation()
    // CLAIM (measured): a global set by an action on the page's Rec is gone after a field was validated on the page; the next action starts from fresh globals.
    var
        Card: TestPage "TGL Row Card";
        Seen: Text;
    begin
        Initialize();
        MakeRows();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.BumpRec.Invoke();
        Card.Payload.SetValue(5);
        Card.ReadRec.Invoke();
        Seen := Card.LastCount.Value();
        Card.BumpRec.Invoke();
        Seen += '|' + Card.LastCount.Value();
        Card.Close();
        Assert.AreEqual('0|1', Seen, 'counter after bump, validation, read, and bump again');
    end;

    [Test]
    procedure TableGlobals_NewPageInstance_StartsFresh()
    // CLAIM (measured): a second opening of the page starts with fresh globals on its Rec.
    var
        Card: TestPage "TGL Row Card";
        Seen: Text;
    begin
        Initialize();
        MakeRows();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.BumpRec.Invoke();
        Card.Close();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.BumpRec.Invoke();
        Seen := Card.LastCount.Value();
        Card.Close();
        Assert.AreEqual('1', Seen, 'counter after bump on a reopened page');
    end;

    [Test]
    procedure TableGlobals_PageFieldValidate_WhatTheTriggerSeesOfThePageRecGlobals()
    // CLAIM: the OnValidate a page field runs starts with fresh globals; it does not see what an earlier action set on the page's Rec.
    var
        Card: TestPage "TGL Row Card";
        LogRec: Record "TGL Log";
    begin
        Initialize();
        MakeRows();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.BumpRec.Invoke();
        Card.BumpRec.Invoke();
        Card.Probe2.SetValue(1);
        Card.Close();
        LogRec.SetFilter(Note, 'P2:*');
        LogRec.FindFirst();
        Assert.AreEqual('P2:0|', LogRec.Note, 'counter and tag the trigger saw');
    end;
}
