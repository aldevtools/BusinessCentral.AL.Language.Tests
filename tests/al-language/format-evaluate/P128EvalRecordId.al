// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 73182 and 73183, codeunit 73181
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: a RecordId as the first argument of Evaluate; if it does not compile, drop the file.
// Facts: Evaluate(RecordId, Text) with the text Format(RecordId) gives (table name and key), format 9, a text naming another table, a text with a key that has no row, garbage and the empty text:
// the Boolean result and the RecordId after the call.
// BC versions: 29 (27 and 28 by CI)

table 73182 "LT P128 Eval Rid Code"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Info; Text[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 73183 "LT P128 Eval Rid Int"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; No; Integer) { }
    }

    keys
    {
        key(PK; No) { Clustered = true; }
    }
}

codeunit 73181 "LT P128 Eval RecordId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvalRid(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        Rid: RecordId;
        Ok: Boolean;
    begin
        Ok := Evaluate(Rid, Txt);
        Observer.Observe(Name, Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
    end;

    [Test]
    procedure P128_Evaluate_IntoRecordId_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        RowCode: Record "LT P128 Eval Rid Code";
        RowInt: Record "LT P128 Eval Rid Int";
        Rid: RecordId;
        Ok: Boolean;
    begin
        RowCode.DeleteAll();
        RowInt.DeleteAll();
        RowCode.Code := 'A-1';
        RowCode.Insert();
        RowInt.No := 42;
        RowInt.Insert();
        Ok := Evaluate(Rid, Format(RowCode.RecordId));
        Observer.Observe('code row via Format', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid = RowCode.RecordId));
        Ok := Evaluate(Rid, Format(RowInt.RecordId));
        Observer.Observe('int row via Format', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid = RowInt.RecordId));
        Ok := Evaluate(Rid, Format(RowCode.RecordId, 0, 9));
        Observer.Observe('code row via Format 9', Format(Ok) + '|' + Format(Rid));
        Ok := Evaluate(Rid, Format(RowInt.RecordId, 0, 9));
        Observer.Observe('int row via Format 9', Format(Ok) + '|' + Format(Rid));
        Ok := Evaluate(Rid, Format(RowInt.RecordId), 9);
        Observer.Observe('int row via Format, number 9', Format(Ok) + '|' + Format(Rid));
        Observer.Expect('code row via Format', 'Yes|LT P128 Eval Rid Code: A-1|Yes');
        Observer.Expect('int row via Format', 'Yes|LT P128 Eval Rid Int: 42|Yes');
        Observer.Expect('code row via Format 9', 'Yes|LT P128 Eval Rid Code: A-1');
        Observer.Expect('int row via Format 9', 'Yes|LT P128 Eval Rid Int: 42');
        Observer.Expect('int row via Format, number 9', 'Yes|LT P128 Eval Rid Int: 42');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoRecordId_OtherTexts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalRid(Observer, 'name and key', 'LT P128 Eval Rid Int: 7');
        EvalRid(Observer, 'name and key, no blank', 'LT P128 Eval Rid Int:7');
        EvalRid(Observer, 'code key', 'LT P128 Eval Rid Code: X');
        EvalRid(Observer, 'unknown table', 'No Such Table: 1');
        EvalRid(Observer, 'garbage', 'garbage');
        EvalRid(Observer, 'empty', '');
        EvalRid(Observer, 'table name only', 'LT P128 Eval Rid Int');
        EvalRid(Observer, 'key of wrong type', 'LT P128 Eval Rid Int: abc');
        EvalRid(Observer, 'lower case table', 'lt p128 eval rid int: 7');
        Observer.Expect('name and key', 'Yes|LT P128 Eval Rid Int: 7|73183');
        Observer.Expect('name and key, no blank', 'Yes|LT P128 Eval Rid Int: 7|73183');
        Observer.Expect('code key', 'Yes|LT P128 Eval Rid Code: X|73182');
        Observer.Expect('unknown table', 'No||0');
        Observer.Expect('garbage', 'No||0');
        Observer.Expect('empty', 'Yes||0');
        Observer.Expect('table name only', 'Yes|LT P128 Eval Rid Int|73183');
        Observer.Expect('key of wrong type', 'No||0');
        Observer.Expect('lower case table', 'Yes|LT P128 Eval Rid Int: 7|73183');
        Observer.Verify();
    end;
}
