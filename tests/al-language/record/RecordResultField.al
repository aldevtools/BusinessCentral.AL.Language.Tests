// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-methods
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// A field read off a procedure's record result: P().Field as an rvalue; also a RecordRef result.
// BC versions: 29 (27 and 28 by CI)

table 70336 "LT P98 FieldRow"
{
    fields
    {
        field(1; Id; Code[10]) { }
        field(2; "Some Name"; Text[50]) { }
        field(3; Amount; Decimal) { }
        field(4; Kind; Option) { OptionMembers = Zero,One,Two; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70337 "LT P98 RecResultField"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure GetRow(): Record "LT P98 FieldRow"
    var
        R: Record "LT P98 FieldRow";
    begin
        R.Id := 'R1';
        R."Some Name" := 'Alpha';
        R.Amount := 12.5;
        R.Kind := R.Kind::Two;
        exit(R);
    end;

    local procedure GetRowId(RowKey: Code[10]): Record "LT P98 FieldRow"
    var
        R: Record "LT P98 FieldRow";
    begin
        R.DeleteAll();
        R.Id := RowKey;
        R."Some Name" := 'N-' + RowKey;
        R.Insert();
        exit(R);
    end;

    local procedure GetRef(): RecordRef
    var
        R: Record "LT P98 FieldRow";
        Ref: RecordRef;
    begin
        R.Id := 'R2';
        R."Some Name" := 'Beta';
        R.Amount := 3;
        Ref.GetTable(R);
        exit(Ref);
    end;

    [Test]
    procedure P98_FieldOfResult_Rvalue()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        D: Decimal;
        C: Code[10];
    begin
        T := GetRow()."Some Name";
        Observer.Observe('text', T);
        D := GetRow().Amount;
        Observer.Observe('dec', Format(D));
        C := GetRow().Id;
        Observer.Observe('code', C);
        Observer.Observe('format', Format(GetRow().Kind));
        Observer.Observe('quoted', GetRow()."Some Name");
        Observer.Observe('len', Format(StrLen(GetRow()."Some Name")));
        Observer.Observe('expr', Format(GetRow().Amount * 2));
        Observer.Observe('cmp', Format(GetRow()."Some Name" = 'Alpha'));
        Observer.Observe('opt', Format(GetRow().Kind = GetRow().Kind::Two));
        Observer.Expect('text', 'Alpha');
        Observer.Expect('dec', '12.5');
        Observer.Expect('code', 'R1');
        Observer.Expect('format', 'Two');
        Observer.Expect('quoted', 'Alpha');
        Observer.Expect('len', '5');
        Observer.Expect('expr', '25');
        Observer.Expect('cmp', 'Yes');
        Observer.Expect('opt', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P98_FieldOfResult_FromDatabase()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 FieldRow";
    begin
        R.DeleteAll();
        Observer.Observe('name', GetRowId('DB1')."Some Name");
        Observer.Observe('count', Format(R.Count()));
        R.DeleteAll();
        Observer.Expect('name', 'N-DB1');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P98_FieldOfRecordRefResult()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', Format(GetRef().Field(2).Value));
        Observer.Observe('name', GetRef().Field(2).Name);
        Observer.Observe('count', Format(GetRef().FieldCount()));
        Observer.Observe('numval', Format(GetRef().Field(3).Value));
        Observer.Expect('value', 'Beta');
        Observer.Expect('name', 'Some Name');
        Observer.Expect('count', '4');
        Observer.Expect('numval', '3');
        Observer.Verify();
    end;


    // Corpus issue 668 item 35 (writer BQ): a table (and table extension) procedure whose return type is the table's own record type, with
    // no named return value, after Rec.FindFirst() (microsoft/AL issue 6529); a named return value; exit(Rec). The caller filters Id = 2.
    local procedure BqDescribe(var R: Record "LT BQ Ret Row"): Text
    begin
        exit('id=' + Format(R.Id) + ' name=' + R.Name + ' filters=' + R.GetFilters());
    end;

    [Test]
    procedure P98_TableProcedure_Returning_Own_Record_Type_BQ()
    var
        R: Record "LT BQ Ret Row";
        Got: Record "LT BQ Ret Row";
        Observer: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Name := 'first';
        R.Insert();
        R.Init();
        R.Id := 2;
        R.Name := 'second';
        R.Insert();
        Clear(R);
        R.SetRange(Id, 2);
        Got := R.FirstUnnamed();
        Observer.Observe('unnamed', BqDescribe(Got));
        Observer.Observe('unnamedCaller', BqDescribe(R));
        Clear(R);
        R.SetRange(Id, 2);
        Got := R.FirstNamed();
        Observer.Observe('named', BqDescribe(Got));
        Observer.Observe('namedCaller', BqDescribe(R));
        Clear(R);
        R.SetRange(Id, 2);
        Got := R.FirstExitRec();
        Observer.Observe('exitRec', BqDescribe(Got));
        Clear(R);
        R.SetRange(Id, 2);
        Got := R.ExtFirstUnnamed();
        Observer.Observe('extUnnamed', BqDescribe(Got));
        Observer.Observe('extUnnamedCaller', BqDescribe(R));
        Clear(R);
        R.SetRange(Id, 2);
        Got := R.ExtFirstExitRec();
        Observer.Observe('extExitRec', BqDescribe(Got));
        Observer.Expect('unnamed', 'id=0 name= filters=');
        Observer.Expect('unnamedCaller', 'id=2 name=second filters=Id: 2');
        Observer.Expect('named', 'id=1 name=first filters=');
        Observer.Expect('namedCaller', 'id=0 name= filters=Id: 2');
        Observer.Expect('exitRec', 'id=2 name=second filters=');
        Observer.Expect('extUnnamed', 'id=0 name= filters=');
        Observer.Expect('extUnnamedCaller', 'id=2 name=second filters=Id: 2');
        Observer.Expect('extExitRec', 'id=2 name=second filters=');
        Observer.Verify();
    end;
}
