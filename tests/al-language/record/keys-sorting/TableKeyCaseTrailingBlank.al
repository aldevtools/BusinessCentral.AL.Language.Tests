// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the uniqueness rule of a primary key: two rows whose Text or Code key differ only in case or in trailing blanks: Insert (error text and code, or the returned Boolean),
//   Rename onto an existing key and onto the same key in another case, Get/SetRange with another case or with trailing blanks, a composite key, the stored value.
// BC versions: 29 (27 and 28 by CI)

table 71952 "LT KCB Text"
{
    fields
    {
        field(1; K; Text[20]) { }
        field(2; Info; Text[20]) { }
        field(3; Pad; Blob) { }
    }
    keys
    {
        key(PK; K) { Clustered = true; }
    }
}

table 71953 "LT KCB Code"
{
    fields
    {
        field(1; K; Code[20]) { }
        field(2; Info; Text[20]) { }
        field(3; Pad; Blob) { }
    }
    keys
    {
        key(PK; K) { Clustered = true; }
    }
}

table 71954 "LT KCB Composite"
{
    fields
    {
        field(1; K1; Code[10]) { }
        field(2; K2; Text[10]) { }
        field(3; Pad; Blob) { }
    }
    keys
    {
        key(PK; K1, K2) { Clustered = true; }
    }
}

codeunit 71955 "LT KCB Key Case Blank"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure InsText(NewKey: Text[20]; NewInfo: Text[20])
    var
        T: Record "LT KCB Text";
    begin
        T.K := NewKey;
        T.Info := NewInfo;
        T.Insert();
    end;

    [Test]
    procedure P184_TextKey_DifferOnlyInCase_Insert()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT KCB Text";
        Ok: Boolean;
    begin
        T.DeleteAll();
        InsText('abc', 'first');
        T.Init();
        T.K := 'ABC';
        T.Insert();
        Observer.Observe('insert upper', 'no error');
        Ok := T.Insert();
        Observer.Observe('insert upper returns', Format(Ok));
        T.K := 'aBc';
        T.Insert();
        Observer.Observe('insert mixed', 'no error');
        Observer.Observe('count', Format(T.Count()));
        T.FindFirst();
        Observer.Observe('stored key', T.K);
        Observer.Observe('stored info', T.Info);
        Observer.Expect('insert upper', 'no error');
        Observer.Expect('insert upper returns', 'No');
        Observer.Expect('insert mixed', 'no error');
        Observer.Expect('count', '3');
        Observer.Expect('stored key', 'abc');
        Observer.Expect('stored info', 'first');
        Observer.Verify();
    end;

    [Test]
    procedure P184_TextKey_Get_And_Filter_OtherCase_Blanks()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT KCB Text";
    begin
        T.DeleteAll();
        InsText('abc', 'first');
        Observer.Observe('get upper', Format(T.Get('ABC')));
        Observer.Observe('found key', T.K);
        Observer.Observe('get blanks', Format(T.Get('abc   ')));
        Observer.Observe('get leading', Format(T.Get(' abc')));
        T.Reset();
        T.SetRange(K, 'ABC');
        Observer.Observe('range upper count', Format(T.Count()));
        T.SetRange(K, 'abc  ');
        Observer.Observe('range blanks count', Format(T.Count()));
        T.SetFilter(K, '@abc');
        Observer.Observe('filter @ count', Format(T.Count()));
        T.SetFilter(K, 'ABC');
        Observer.Observe('filter upper count', Format(T.Count()));
        Observer.Expect('get upper', 'No');
        Observer.Expect('found key', '');
        Observer.Expect('get blanks', 'Yes');
        Observer.Expect('get leading', 'No');
        Observer.Expect('range upper count', '0');
        Observer.Expect('range blanks count', '1');
        Observer.Expect('filter @ count', '1');
        Observer.Expect('filter upper count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P184_CodeKey_Case_And_Blanks()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "LT KCB Code";
        Ok: Boolean;
    begin
        C.DeleteAll();
        C.K := 'abc';
        Observer.Observe('assigned lower', C.K);
        C.Insert();
        C.Init();
        C.K := 'ABC';
        asserterror C.Insert();
        Observer.ObserveError('insert upper');
        C.K := 'abc ';
        Observer.Observe('assigned blank length', Format(StrLen(C.K)));
        C.Insert();
        Observer.Observe('insert blank', 'no error');
        C.K := 'abc  x';
        Ok := C.Insert();
        Observer.Observe('insert inner blanks returns', Format(Ok));
        Observer.Observe('count', Format(C.Count()));
        Observer.Observe('get lower', Format(C.Get('abc')));
        Observer.Observe('found key', C.K);
        Observer.Expect('assigned lower', 'ABC');
        Observer.Expect('insert upper|text', 'The record in table LT KCB Code already exists. Identification fields and values: K=''ABC''');
        Observer.Expect('insert upper|code', 'DB:RecordExists');
        Observer.Expect('assigned blank length', '3');
        Observer.Expect('insert blank', 'no error');
        Observer.Expect('insert inner blanks returns', 'Yes');
        Observer.Expect('count', '2');
        Observer.Expect('get lower', 'Yes');
        Observer.Expect('found key', 'ABC');
        Observer.Verify();
    end;

    [Test]
    procedure P184_CompositeKey_Case_And_Blanks()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT KCB Composite";
    begin
        R.DeleteAll();
        R.K1 := 'A';
        R.K2 := 'x';
        R.Insert();
        R.K2 := 'X';
        R.Insert();
        Observer.Observe('second part case', 'no error');
        R.K2 := 'x ';
        asserterror R.Insert();
        Observer.ObserveError('second part blank');
        R.K1 := 'a';
        R.K2 := 'x';
        R.Insert();
        Observer.Observe('first part case', 'no error');
        R.K2 := 'y';
        R.Insert();
        Observer.Observe('count', Format(R.Count()));
        Observer.Expect('second part case', 'no error');
        Observer.Expect('second part blank|text', 'The record in table LT KCB Composite already exists. Identification fields and values: K1=''A'',K2=''x ''');
        Observer.Expect('second part blank|code', 'DB:RecordExists');
        Observer.Expect('first part case', 'no error');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;
}
