// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordid/recordid-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a RecordId as %1 of Error, StrSubstNo, Message-free text building, TestField(RecordIdField, Value), TestField(RecordIdField) on an empty one and FieldError on a RecordId field; text keys that need quotes (blank, comma, quote, colon), a two-part key and an integer key; next to Format(RecordId).
// BC versions: 29 (27 and 28 by CI)

table 74839 "LT P168 Rid Row"
{
    fields
    {
        field(1; Name; Text[30]) { }
        field(2; Seq; Integer) { }
        field(3; Ref; RecordId) { }
    }
    keys
    {
        key(PK; Name, Seq) { Clustered = true; }
    }
}

table 74840 "LT P168 Rid Int Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74841 "LT P168 RecordId Message"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Rid(KeyName: Text[30]; Seq: Integer): RecordId
    var
        Row: Record "LT P168 Rid Row";
    begin
        Row.DeleteAll();
        Row.Name := KeyName;
        Row.Seq := Seq;
        Row.Insert();
        exit(Row.RecordId());
    end;

    [Test]
    procedure P168_Error_RecordIdAsArgument_PlainKey()
    var
        Observer: Codeunit "Probe Observer";
        Id: RecordId;
    begin
        Id := Rid('plain', 1);
        Observer.Observe('format', Format(Id));
        asserterror Error('%1', Id);
        Observer.ObserveError('error-only');
        asserterror Error('Row %1 is bad', Id);
        Observer.ObserveError('error-embedded');
        Observer.Observe('substno', StrSubstNo('%1', Id));
        Observer.Observe('substno-embedded', StrSubstNo('x %1 y', Id));
        Observer.Expect('format', 'LT P168 Rid Row: plain,1');
        Observer.Expect('error-only|text', 'LT P168 Rid Row: plain,1');
        Observer.Expect('error-only|code', 'Dialog');
        Observer.Expect('error-embedded|text', 'Row LT P168 Rid Row: plain,1 is bad');
        Observer.Expect('error-embedded|code', 'Dialog');
        Observer.Expect('substno', 'LT P168 Rid Row: plain,1');
        Observer.Expect('substno-embedded', 'x LT P168 Rid Row: plain,1 y');
        Observer.Verify();
    end;

    [Test]
    procedure P168_Error_RecordIdAsArgument_KeysThatNeedQuotes()
    var
        Observer: Codeunit "Probe Observer";
        Id: RecordId;
    begin
        Id := Rid('a b', 2);
        Observer.Observe('format-blank', Format(Id));
        asserterror Error('%1', Id);
        Observer.ObserveError('blank');
        Id := Rid('x,y', 3);
        Observer.Observe('format-comma', Format(Id));
        asserterror Error('%1', Id);
        Observer.ObserveError('comma');
        Id := Rid('it''s', 4);
        Observer.Observe('format-quote', Format(Id));
        asserterror Error('%1', Id);
        Observer.ObserveError('quote');
        Id := Rid('a:b', 5);
        Observer.Observe('format-colon', Format(Id));
        asserterror Error('%1', Id);
        Observer.ObserveError('colon');
        Id := Rid('', 6);
        Observer.Observe('format-emptykey', Format(Id));
        asserterror Error('%1', Id);
        Observer.ObserveError('emptykey');
        Observer.Expect('format-blank', 'LT P168 Rid Row: a b,2');
        Observer.Expect('blank|text', 'LT P168 Rid Row: a b,2');
        Observer.Expect('blank|code', 'Dialog');
        Observer.Expect('format-comma', 'LT P168 Rid Row: "x,y",3');
        Observer.Expect('comma|text', 'LT P168 Rid Row: "x,y",3');
        Observer.Expect('comma|code', 'Dialog');
        Observer.Expect('format-quote', 'LT P168 Rid Row: it''s,4');
        Observer.Expect('quote|text', 'LT P168 Rid Row: it''s,4');
        Observer.Expect('quote|code', 'Dialog');
        Observer.Expect('format-colon', 'LT P168 Rid Row: a:b,5');
        Observer.Expect('colon|text', 'LT P168 Rid Row: a:b,5');
        Observer.Expect('colon|code', 'Dialog');
        Observer.Expect('format-emptykey', 'LT P168 Rid Row: "",6');
        Observer.Expect('emptykey|text', 'LT P168 Rid Row: "",6');
        Observer.Expect('emptykey|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure P168_Error_RecordIdAsArgument_IntegerKeyAndEmptyId()
    var
        Observer: Codeunit "Probe Observer";
        IntRow: Record "LT P168 Rid Int Row";
        Id: RecordId;
        Empty: RecordId;
    begin
        IntRow.DeleteAll();
        IntRow.Id := 42;
        IntRow.Insert();
        Id := IntRow.RecordId();
        Observer.Observe('format-int', Format(Id));
        asserterror Error('%1', Id);
        Observer.ObserveError('int-key');
        Observer.Observe('format-empty', '[' + Format(Empty) + ']');
        asserterror Error('%1', Empty);
        Observer.ObserveError('empty-id');
        Observer.Expect('format-int', 'LT P168 Rid Int Row: 42');
        Observer.Expect('int-key|text', 'LT P168 Rid Int Row: 42');
        Observer.Expect('int-key|code', 'Dialog');
        Observer.Expect('format-empty', '[]');
        Observer.Expect('empty-id|text', '');
        Observer.Expect('empty-id|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure P168_TestField_FieldError_OnRecordIdField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P168 Rid Row";
        Id: RecordId;
        Other: RecordId;
    begin
        Id := Rid('a b', 2);
        Row.Get('a b', 2);
        Other := Rid('x,y', 3);
        Row.Get('x,y', 3);
        Row.Ref := Id;
        asserterror Row.TestField(Ref, Other);
        Observer.ObserveError('testfield-value');
        Row.TestField(Ref, Id);
        Observer.Observe('testfield-same', 'no error');
        asserterror Row.FieldError(Ref);
        Observer.ObserveError('fielderror');
        asserterror Row.FieldError(Ref, 'custom text');
        Observer.ObserveError('fielderror-text');
        Clear(Row.Ref);
        asserterror Row.TestField(Ref);
        Observer.ObserveError('testfield-empty');
        Observer.Expect('testfield-value|text', 'Ref must be equal to ''LT P168 Rid Row: "x,y",3''  in LT P168 Rid Row: Name=x,y, Seq=3. Current value is ''LT P168 Rid Row: a b,2''.');
        Observer.Expect('testfield-value|code', 'TestField');
        Observer.Expect('testfield-same', 'no error');
        Observer.Expect('fielderror|text', 'Ref must not be LT P168 Rid Row: a b,2 in LT P168 Rid Row Name=''x,y'',Seq=''3''.');
        Observer.Expect('fielderror|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror-text|text', 'Ref custom text in LT P168 Rid Row Name=''x,y'',Seq=''3''.');
        Observer.Expect('fielderror-text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('testfield-empty|text', 'Ref must have a value in LT P168 Rid Row: Name=x,y, Seq=3. It cannot be zero or empty.');
        Observer.Expect('testfield-empty|code', 'TestField');
        Observer.Verify();
    end;
}
