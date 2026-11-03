// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: TP CurrFieldNo Row (60388), TP CurrFieldNo Card (60389),
//   TP CurrFieldNo Job Ext (60390) on Job (Base Application),
//   TP CurrFieldNo Job Card (60391), Assert (60021)
//
// CLAIM: a table field's OnValidate trigger reads CurrFieldNo equal to the bound field's
// number when the write comes from a TestPage control's SetValue — for both a table's own
// field (arm A) and a tableextension field (arm C) — while a Rec.Validate from AL code
// leaves CurrFieldNo at 0 (arm B), and the row's own OnModify trigger (run when the page
// saves on Close) also sees CurrFieldNo = 0, never the field that was last validated (arm D).

codeunit 60392 "TP CurrFieldNo Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure MakeRow(No: Code[20]) Row: Record "TP CurrFieldNo Row"
    begin
        if Row.Get(No) then
            Row.Delete();
        Row.Init();
        Row."No." := No;
        Row.Insert();
    end;

    // Positive (arm A): a TestPage SetValue on a control bound to the table's own field runs
    // that field's OnValidate with CurrFieldNo equal to the field's own number, and the value
    // the trigger recorded persists to the underlying row after Close().
    [Test]
    procedure SetValue_OwnTableField_OnValidateSeesCurrFieldNo()
    var
        Row: Record "TP CurrFieldNo Row";
        Card: TestPage "TP CurrFieldNo Card";
    begin
        Row := MakeRow('A');

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Amount.SetValue(50);
        Assert.AreEqual(Format(Row.FieldNo(Amount)), Card.ValidateFieldNo.Value(),
            'a TestPage SetValue on the table''s own field must run OnValidate with CurrFieldNo = the field''s own number');
        Card.Close();

        Row.Get('A');
        Assert.AreEqual(Row.FieldNo(Amount), Row.ValidateFieldNo,
            'the CurrFieldNo the trigger recorded must persist to the underlying row');
    end;

    // Negative (arm B): the same field's OnValidate, triggered by Rec.Validate from AL code
    // instead of a page write, must see CurrFieldNo = 0 — proves the field number is not
    // stamped unconditionally on every validate, only on a page-originated one.
    [Test]
    procedure Validate_FromCode_OnValidateSeesZero()
    var
        Row: Record "TP CurrFieldNo Row";
    begin
        Row := MakeRow('B');
        Row.Validate(Amount, 50);
        Assert.AreEqual(0, Row.ValidateFieldNo,
            'Rec.Validate from AL code must leave CurrFieldNo at 0 inside the field''s own OnValidate');
    end;

    // Positive (arm C): the same claim as arm A, but for a field a TABLEEXTENSION adds —
    // proves the field-number stamping is not special-cased to a table's own declared fields.
    [Test]
    procedure SetValue_TableExtensionField_OnValidateSeesCurrFieldNo()
    var
        Job: Record Job;
        Card: TestPage "TP CurrFieldNo Job Card";
    begin
        if Job.Get('TP-CFN-C') then
            Job.Delete();
        Job.Init();
        Job."No." := 'TP-CFN-C';
        Job.Insert(false);

        Card.OpenEdit();
        Card.GoToRecord(Job);
        Card."TP CFN Ext Amount".SetValue(50);
        Assert.AreEqual(Format(Job.FieldNo("TP CFN Ext Amount")), Card."TP CFN Ext FieldNo".Value(),
            'a TestPage SetValue on a tableextension field must run its OnValidate with CurrFieldNo = that field''s own number');
        Card.Close();

        Job.Get('TP-CFN-C');
        Assert.AreEqual(Job.FieldNo("TP CFN Ext Amount"), Job."TP CFN Ext FieldNo",
            'the CurrFieldNo the tableextension field''s trigger recorded must persist to the underlying row');
    end;

    // Negative (arm D): after a TestPage SetValue + Close(), the row's OWN OnModify trigger —
    // run when the page saves — must see CurrFieldNo = 0, not the field number the earlier
    // OnValidate saw. Proves the stamped field number does not outlive the single Validate
    // call that set it.
    [Test]
    procedure SetValue_ThenClose_OnModifySeesZero()
    var
        Row: Record "TP CurrFieldNo Row";
        Card: TestPage "TP CurrFieldNo Card";
    begin
        Row := MakeRow('D');

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Amount.SetValue(50);
        Card.Close();

        Row.Get('D');
        Assert.AreEqual(0, Row.ModifyFieldNo,
            'the row''s own OnModify, run by the page''s save on Close, must see CurrFieldNo = 0, not the field OnValidate stamped earlier');
    end;
}
