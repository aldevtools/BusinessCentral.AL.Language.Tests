// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70041, enum 70042, helper codeunit 70043, test codeunits 70044..70048
// Probe: every literal asserted below was observed on BC 29.0 (local Windows container); the corpus CI matrix checks 27.5, 28.5 and 29.0.
//   Media and MediaSet cells whose value holds a new GUID on every run (the Media id, or CreateGuid() as the filter value) are observed, not asserted.
// Facts: a matrix of filter forms crossed with field types. Field types: Integer, BigInteger, Decimal, Duration, Code, Text, Date, Time,
//   DateTime, DateFormula, Boolean, Option, Enum, Guid, RecordId, Blob, Media, MediaSet. Rows: one with the default value, three with
//   ascending values A < B < C (Blob, Media and MediaSet: one row with content). Forms through FieldRef.SetFilter: a, =a, <>a, <a,
//   <=a, >a, >=a, a..b, ..b, a.., a|b, >a&<b, *, ?, @a, a*, empty text, two single quotes, <>'', <> alone, an unterminated quote,
//   the ordinal of an Option or Enum; the same forms with %1 arguments (also an argument with * and ?); SetRange with one and two values
//   and with a text; GetView(true) and GetView(false) and a SetView round trip. Each cell records: whether it raises (the error
//   text), GetFilter, and the rows a FindSet returns. A cell is named <form>.<field>.
//   Asked by al-runner issues 7437, 7426, 7388 (see FieldRefFilterEmptyText.al), 7456 (enum name against ordinal in a view), 7460 (<>%1 with * and ? in the argument),
//   7461 (a Guid text on a MediaSet field), 7462 (an unterminated quote).
// BC versions: 27, 28, 29 by CI

enum 70042 "LT FRM Enum"
{
    Extensible = true;
    value(0; Alpha) { }
    value(1; Beta) { }
    value(2; Gamma) { }
}

table 70041 "LT FRM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(10; FInt; Integer) { }
        field(11; FBig; BigInteger) { }
        field(12; FDec; Decimal) { }
        field(13; FDur; Duration) { }
        field(14; FCode; Code[20]) { }
        field(15; FText; Text[20]) { }
        field(16; FDate; Date) { }
        field(17; FTime; Time) { }
        field(18; FDateTime; DateTime) { }
        field(19; FDf; DateFormula) { }
        field(20; FBool; Boolean) { }
        field(21; FOpt; Option) { OptionMembers = Alpha,Beta,Gamma; }
        field(22; FEnum; Enum "LT FRM Enum") { }
        field(23; FGuid; Guid) { }
        field(24; FRid; RecordId) { }
        field(25; FBlob; Blob) { }
        field(26; FMedia; Media) { }
        field(27; FMediaSet; MediaSet) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 70043 "LT FRM Probe"
{
    // Each test declares its own "LT FRM Probe" variable, so every test starts with an empty observer; the cells observe into Obs here,
    // and the test ends with Probe.Finish() or Probe.Expect(...) and Probe.Verify().
    var
        Obs: Codeunit "Probe Observer";

    procedure Expect(Name: Text; Value: Text)
    begin
        Obs.Expect(Name, Value);
    end;

    procedure Ignore(Name: Text)
    begin
        Obs.Ignore(Name);
    end;

    procedure Verify()
    begin
        Obs.Verify();
    end;

    procedure Finish()
    begin
        Obs.Finish();
    end;

    procedure Rows(var RecRef: RecordRef): Text
    var
        Result: Text;
    begin
        if RecRef.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(RecRef.Field(1).Value());
            until RecRef.Next() = 0;
        exit(Result);
    end;

    procedure Texts(FieldNo: Integer; var Ta: Text; var Tb: Text; var Ord: Text; var Va: Variant)
    var
        Src: RecordRef;
        Vb: Variant;
        G: Guid;
    begin
        Src.Open(Database::"LT FRM Row");
        case FieldNo of
            25:
                begin
                    Ta := 'abc';
                    Tb := 'abd';
                    Ord := '1';
                    Va := Ta;
                end;
            26, 27:
                begin
                    G := CreateGuid();
                    Ta := Format(G);
                    Tb := Format(CreateGuid());
                    Ord := '1';
                    Va := G;
                end;
            else begin
                Src.Field(1).SetRange(2);
                Src.FindFirst();
                Va := Src.Field(FieldNo).Value();
                Ta := Format(Va);
                Ord := Format(Va, 0, 2);
                Src.Field(1).SetRange(3);
                Src.FindFirst();
                Vb := Src.Field(FieldNo).Value();
                Tb := Format(Vb);
            end;
        end;
        Src.Close();
    end;

    [TryFunction]
    local procedure TrySet(var FldRef: FieldRef; Expr: Text)
    begin
        FldRef.SetFilter(Expr);
    end;

    [TryFunction]
    local procedure TrySetArg(var FldRef: FieldRef; Expr: Text; Arg: Variant)
    begin
        FldRef.SetFilter(Expr, Arg);
    end;

    [TryFunction]
    local procedure TryRange1(var FldRef: FieldRef; Arg: Variant)
    begin
        FldRef.SetRange(Arg);
    end;

    [TryFunction]
    local procedure TryRange2(var FldRef: FieldRef; Arg1: Variant; Arg2: Variant)
    begin
        FldRef.SetRange(Arg1, Arg2);
    end;

    [TryFunction]
    local procedure TryView(var RecRef: RecordRef; ViewText: Text)
    begin
        RecRef.SetView(ViewText);
    end;

    local procedure Outcome(Name: Text; var RecRef: RecordRef; FieldNo: Integer; Ok: Boolean)
    var
        Fld: FieldRef;
    begin
        if not Ok then begin
            Obs.Observe(Name, 'E: ' + GetLastErrorText());
            ClearLastError();
            exit;
        end;
        Fld := RecRef.Field(FieldNo);
        Obs.Observe(Name, Fld.GetFilter() + ' | ' + RecRef.GetFilters() + ' | ' + Rows(RecRef));
    end;

    // The filter text Expr with {a}, {b} and {o} replaced by the texts of two values and the ordinal.
    procedure Cell(Name: Text; FieldNo: Integer; Expr: Text)
    var
        RecRef: RecordRef;
        Fld: FieldRef;
        Ta: Text;
        Tb: Text;
        Ord: Text;
        Va: Variant;
    begin
        Texts(FieldNo, Ta, Tb, Ord, Va);
        RecRef.Open(Database::"LT FRM Row");
        Fld := RecRef.Field(FieldNo);
        Outcome(Name, RecRef, FieldNo, TrySet(Fld, Expr.Replace('{a}', Ta).Replace('{b}', Tb).Replace('{o}', Ord)));
        RecRef.Close();
    end;

    // SetFilter(Expr, argument): Arg 'a' is the value of row 2, 'w' is a text with * and ?, 'q' is ?.
    procedure CellArg(Name: Text; FieldNo: Integer; Expr: Text; Arg: Text)
    var
        RecRef: RecordRef;
        Fld: FieldRef;
        Ta: Text;
        Tb: Text;
        Ord: Text;
        Va: Variant;
        Vw: Variant;
    begin
        Texts(FieldNo, Ta, Tb, Ord, Va);
        RecRef.Open(Database::"LT FRM Row");
        Fld := RecRef.Field(FieldNo);
        case Arg of
            'a':
                Outcome(Name, RecRef, FieldNo, TrySetArg(Fld, Expr, Va));
            'w':
                begin
                    Vw := 'a*b?';
                    Outcome(Name, RecRef, FieldNo, TrySetArg(Fld, Expr, Vw));
                end;
            'q':
                begin
                    Vw := '?';
                    Outcome(Name, RecRef, FieldNo, TrySetArg(Fld, Expr, Vw));
                end;
        end;
        RecRef.Close();
    end;

    // Kind 'r1' SetRange(a), 'r2' SetRange(a, b), 'rt' SetRange(text of a).
    procedure CellRange(Name: Text; FieldNo: Integer; Kind: Text)
    var
        RecRef: RecordRef;
        Fld: FieldRef;
        Ta: Text;
        Tb: Text;
        Ord: Text;
        Va: Variant;
        Vb: Variant;
        Vt: Variant;
        Ga: Guid;
        Gb: Guid;
    begin
        Texts(FieldNo, Ta, Tb, Ord, Va);
        RecRef.Open(Database::"LT FRM Row");
        Fld := RecRef.Field(FieldNo);
        case FieldNo of
            25:
                Vb := Tb;
            26, 27:
                begin
                    Evaluate(Gb, Tb);
                    Vb := Gb;
                end;
            else
                Vb := Va;
        end;
        if FieldNo in [26, 27] then begin
            Evaluate(Ga, Ta);
            Va := Ga;
        end;
        case Kind of
            'r1':
                Outcome(Name, RecRef, FieldNo, TryRange1(Fld, Va));
            'r2':
                Outcome(Name, RecRef, FieldNo, TryRange2(Fld, Va, Vb));
            'rt':
                begin
                    Vt := Ta;
                    Outcome(Name, RecRef, FieldNo, TryRange1(Fld, Vt));
                end;
        end;
        RecRef.Close();
    end;

    // GetView(true), GetView(false) after the filter Expr, then the view set on a new RecordRef: GetFilter and rows.
    procedure CellView(Name: Text; FieldNo: Integer; Expr: Text)
    var
        RecRef: RecordRef;
        Rec2: RecordRef;
        Fld: FieldRef;
        Ta: Text;
        Tb: Text;
        Ord: Text;
        Va: Variant;
        ViewTrue: Text;
        ViewFalse: Text;
    begin
        Texts(FieldNo, Ta, Tb, Ord, Va);
        RecRef.Open(Database::"LT FRM Row");
        Fld := RecRef.Field(FieldNo);
        if not TrySet(Fld, Expr.Replace('{a}', Ta).Replace('{b}', Tb).Replace('{o}', Ord)) then begin
            Obs.Observe(Name, 'E: ' + GetLastErrorText());
            ClearLastError();
            RecRef.Close();
            exit;
        end;
        ViewTrue := RecRef.GetView(true);
        ViewFalse := RecRef.GetView(false);
        Rec2.Open(Database::"LT FRM Row");
        if TryView(Rec2, ViewFalse) then
            Obs.Observe(Name, ViewTrue + ' | ' + ViewFalse + ' | ' + Rec2.Field(FieldNo).GetFilter() + ' | ' + Rows(Rec2))
        else begin
            Obs.Observe(Name, ViewTrue + ' | ' + ViewFalse + ' | E: ' + GetLastErrorText());
            ClearLastError();
        end;
        Rec2.Close();
        RecRef.Close();
    end;
}

codeunit 70044 "LT FRM Numeric Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedInt()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FInt := 10;
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FInt := 20;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FInt := 30;
        R.Insert();
    end;

    [Test]
    procedure Filter_Int_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedInt();
        Probe.Cell('eq.Int', 10, '{a}');
        Probe.Cell('eqop.Int', 10, '={a}');
        Probe.Cell('ne.Int', 10, '<>{a}');
        Probe.Cell('lt.Int', 10, '<{a}');
        Probe.Cell('le.Int', 10, '<={a}');
        Probe.Cell('gt.Int', 10, '>{a}');
        Probe.Cell('ge.Int', 10, '>={a}');
        Probe.Expect('eq.Int', '10 | FInt: 10 | 2');
        Probe.Expect('eqop.Int', '10 | FInt: 10 | 2');
        Probe.Expect('ne.Int', '<>10 | FInt: <>10 | 1,3,4');
        Probe.Expect('lt.Int', '<10 | FInt: <10 | 1');
        Probe.Expect('le.Int', '<=10 | FInt: <=10 | 1,2');
        Probe.Expect('gt.Int', '>10 | FInt: >10 | 3,4');
        Probe.Expect('ge.Int', '>=10 | FInt: >=10 | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Int_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedInt();
        Probe.Cell('rng.Int', 10, '{a}..{b}');
        Probe.Cell('upto.Int', 10, '..{b}');
        Probe.Cell('from.Int', 10, '{a}..');
        Probe.Cell('or.Int', 10, '{a}|{b}');
        Probe.Cell('and.Int', 10, '>{a}&<{b}');
        Probe.Cell('ordinal.Int', 10, '{o}');
        Probe.Cell('neordinal.Int', 10, '<>{o}');
        Probe.Expect('rng.Int', '10..20 | FInt: 10..20 | 2,3');
        Probe.Expect('upto.Int', '..20 | FInt: ..20 | 1,2,3');
        Probe.Expect('from.Int', '10.. | FInt: 10.. | 2,3,4');
        Probe.Expect('or.Int', '10|20 | FInt: 10|20 | 2,3');
        Probe.Expect('and.Int', '>10&<20 | FInt: >10&<20 | ');
        Probe.Expect('ordinal.Int', '10 | FInt: 10 | 2');
        Probe.Expect('neordinal.Int', '<>10 | FInt: <>10 | 1,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Int_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedInt();
        Probe.Cell('star.Int', 10, '*');
        Probe.Cell('q.Int', 10, '?');
        Probe.Cell('at.Int', 10, '@{a}');
        Probe.Cell('prefix.Int', 10, '{a}*');
        Probe.Cell('nstar.Int', 10, '<>*');
        Probe.Cell('suffix.Int', 10, '*{a}');
        Probe.Expect('star.Int', 'E: The filter "*" is not valid for the FInt field on the LT FRM Row table. The value "*" can''t be evaluated into type Integer.');
        Probe.Expect('q.Int', 'E: The filter "?" is not valid for the FInt field on the LT FRM Row table. The value "?" can''t be evaluated into type Integer.');
        Probe.Expect('at.Int', 'E: The filter "@10" is not valid for the FInt field on the LT FRM Row table. The value "@10" can''t be evaluated into type Integer.');
        Probe.Expect('prefix.Int', 'E: The filter "10*" is not valid for the FInt field on the LT FRM Row table. The value "10*" can''t be evaluated into type Integer.');
        Probe.Expect('nstar.Int', 'E: The filter "<>*" is not valid for the FInt field on the LT FRM Row table. The value "*" can''t be evaluated into type Integer.');
        Probe.Expect('suffix.Int', 'E: The filter "*10" is not valid for the FInt field on the LT FRM Row table. The value "*10" can''t be evaluated into type Integer.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Int_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedInt();
        Probe.Cell('empty.Int', 10, '');
        Probe.Cell('quotes.Int', 10, '''''');
        Probe.Cell('nequotes.Int', 10, '<>''''');
        Probe.Cell('bare.Int', 10, '<>');
        Probe.Cell('unterm.Int', 10, '''');
        Probe.Cell('unterm2.Int', 10, '{a}''');
        Probe.Cell('quotedA.Int', 10, '''{a}''');
        Probe.Expect('empty.Int', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Int', 'E: The filter "''''" is not valid for the FInt field on the LT FRM Row table. The value "" can''t be evaluated into type Integer.');
        Probe.Expect('nequotes.Int', 'E: The filter "<>''''" is not valid for the FInt field on the LT FRM Row table. The value "" can''t be evaluated into type Integer.');
        Probe.Expect('bare.Int', 'E: The filter "<>" is not valid for the FInt field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Int', 'E: The filter "''" is not valid for the FInt field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Int', 'E: The filter "10''" is not valid for the FInt field on the LT FRM Row table. The value "10''" can''t be evaluated into type Integer.');
        Probe.Expect('quotedA.Int', '10 | FInt: 10 | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Int_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedInt();
        Probe.CellArg('p1.Int', 10, '%1', 'a');
        Probe.CellArg('pne.Int', 10, '<>%1', 'a');
        Probe.CellArg('pge.Int', 10, '>=%1', 'a');
        Probe.CellArg('pstar.Int', 10, '%1', 'w');
        Probe.CellArg('pnestar.Int', 10, '<>%1', 'w');
        Probe.CellArg('pq.Int', 10, '%1', 'q');
        Probe.CellArg('pnq.Int', 10, '<>%1', 'q');
        Probe.Expect('p1.Int', '10 | FInt: 10 | 2');
        Probe.Expect('pne.Int', '<>10 | FInt: <>10 | 1,3,4');
        Probe.Expect('pge.Int', '>=10 | FInt: >=10 | 2,3,4');
#if BC28PLUS
        Probe.Expect('pstar.Int', 'E: The value "a*b?" can''t be evaluated into type Integer.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Int', 'E: The type NavInteger is unknown.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Int', 'E: The value "a*b?" can''t be evaluated into type Integer.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Int', 'E: The type NavInteger is unknown.');
#endif
        Probe.Expect('pq.Int', '63 | FInt: 63 | ');
        Probe.Expect('pnq.Int', '<>63 | FInt: <>63 | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Int_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedInt();
        Probe.CellRange('r1.Int', 10, 'r1');
        Probe.CellRange('r2.Int', 10, 'r2');
        Probe.CellRange('rtext.Int', 10, 'rt');
        Probe.Expect('r1.Int', '10 | FInt: 10 | 2');
        Probe.Expect('r2.Int', '10 | FInt: 10 | 2');
        Probe.Expect('rtext.Int', '10 | FInt: 10 | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Int_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedInt();
        Probe.CellView('vgt.Int', 10, '>{a}');
        Probe.CellView('vne.Int', 10, '<>{a}');
        Probe.CellView('vrng.Int', 10, '{a}..{b}');
        Probe.CellView('vor.Int', 10, '{a}|{b}');
        Probe.CellView('veq.Int', 10, '{a}');
        Probe.Expect('vgt.Int', 'VERSION(1) SORTING(No.) WHERE(FInt=FILTER(>10)) | VERSION(1) SORTING(Field1) WHERE(Field10=1(>10)) | >10 | 3,4');
        Probe.Expect('vne.Int', 'VERSION(1) SORTING(No.) WHERE(FInt=FILTER(<>10)) | VERSION(1) SORTING(Field1) WHERE(Field10=1(<>10)) | <>10 | 1,3,4');
        Probe.Expect('vrng.Int', 'VERSION(1) SORTING(No.) WHERE(FInt=FILTER(10..20)) | VERSION(1) SORTING(Field1) WHERE(Field10=1(10..20)) | 10..20 | 2,3');
        Probe.Expect('vor.Int', 'VERSION(1) SORTING(No.) WHERE(FInt=FILTER(10|20)) | VERSION(1) SORTING(Field1) WHERE(Field10=1(10|20)) | 10|20 | 2,3');
        Probe.Expect('veq.Int', 'VERSION(1) SORTING(No.) WHERE(FInt=FILTER(10)) | VERSION(1) SORTING(Field1) WHERE(Field10=1(10)) | 10 | 2');
        Probe.Verify();
    end;

    local procedure SeedBig()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FBig := 10;
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FBig := 20;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FBig := 30;
        R.Insert();
    end;

    [Test]
    procedure Filter_Big_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBig();
        Probe.Cell('eq.Big', 11, '{a}');
        Probe.Cell('eqop.Big', 11, '={a}');
        Probe.Cell('ne.Big', 11, '<>{a}');
        Probe.Cell('lt.Big', 11, '<{a}');
        Probe.Cell('le.Big', 11, '<={a}');
        Probe.Cell('gt.Big', 11, '>{a}');
        Probe.Cell('ge.Big', 11, '>={a}');
        Probe.Expect('eq.Big', '10 | FBig: 10 | 2');
        Probe.Expect('eqop.Big', '10 | FBig: 10 | 2');
        Probe.Expect('ne.Big', '<>10 | FBig: <>10 | 1,3,4');
        Probe.Expect('lt.Big', '<10 | FBig: <10 | 1');
        Probe.Expect('le.Big', '<=10 | FBig: <=10 | 1,2');
        Probe.Expect('gt.Big', '>10 | FBig: >10 | 3,4');
        Probe.Expect('ge.Big', '>=10 | FBig: >=10 | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Big_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBig();
        Probe.Cell('rng.Big', 11, '{a}..{b}');
        Probe.Cell('upto.Big', 11, '..{b}');
        Probe.Cell('from.Big', 11, '{a}..');
        Probe.Cell('or.Big', 11, '{a}|{b}');
        Probe.Cell('and.Big', 11, '>{a}&<{b}');
        Probe.Cell('ordinal.Big', 11, '{o}');
        Probe.Cell('neordinal.Big', 11, '<>{o}');
        Probe.Expect('rng.Big', '10..20 | FBig: 10..20 | 2,3');
        Probe.Expect('upto.Big', '..20 | FBig: ..20 | 1,2,3');
        Probe.Expect('from.Big', '10.. | FBig: 10.. | 2,3,4');
        Probe.Expect('or.Big', '10|20 | FBig: 10|20 | 2,3');
        Probe.Expect('and.Big', '>10&<20 | FBig: >10&<20 | ');
        Probe.Expect('ordinal.Big', '10 | FBig: 10 | 2');
        Probe.Expect('neordinal.Big', '<>10 | FBig: <>10 | 1,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Big_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBig();
        Probe.Cell('star.Big', 11, '*');
        Probe.Cell('q.Big', 11, '?');
        Probe.Cell('at.Big', 11, '@{a}');
        Probe.Cell('prefix.Big', 11, '{a}*');
        Probe.Cell('nstar.Big', 11, '<>*');
        Probe.Cell('suffix.Big', 11, '*{a}');
        Probe.Expect('star.Big', 'E: The filter "*" is not valid for the FBig field on the LT FRM Row table. The value "*" can''t be evaluated into type BigInteger.');
        Probe.Expect('q.Big', 'E: The filter "?" is not valid for the FBig field on the LT FRM Row table. The value "?" can''t be evaluated into type BigInteger.');
        Probe.Expect('at.Big', 'E: The filter "@10" is not valid for the FBig field on the LT FRM Row table. The value "@10" can''t be evaluated into type BigInteger.');
        Probe.Expect('prefix.Big', 'E: The filter "10*" is not valid for the FBig field on the LT FRM Row table. The value "10*" can''t be evaluated into type BigInteger.');
        Probe.Expect('nstar.Big', 'E: The filter "<>*" is not valid for the FBig field on the LT FRM Row table. The value "*" can''t be evaluated into type BigInteger.');
        Probe.Expect('suffix.Big', 'E: The filter "*10" is not valid for the FBig field on the LT FRM Row table. The value "*10" can''t be evaluated into type BigInteger.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Big_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBig();
        Probe.Cell('empty.Big', 11, '');
        Probe.Cell('quotes.Big', 11, '''''');
        Probe.Cell('nequotes.Big', 11, '<>''''');
        Probe.Cell('bare.Big', 11, '<>');
        Probe.Cell('unterm.Big', 11, '''');
        Probe.Cell('unterm2.Big', 11, '{a}''');
        Probe.Cell('quotedA.Big', 11, '''{a}''');
        Probe.Expect('empty.Big', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Big', 'E: The filter "''''" is not valid for the FBig field on the LT FRM Row table. The value "" can''t be evaluated into type BigInteger.');
        Probe.Expect('nequotes.Big', 'E: The filter "<>''''" is not valid for the FBig field on the LT FRM Row table. The value "" can''t be evaluated into type BigInteger.');
        Probe.Expect('bare.Big', 'E: The filter "<>" is not valid for the FBig field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Big', 'E: The filter "''" is not valid for the FBig field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Big', 'E: The filter "10''" is not valid for the FBig field on the LT FRM Row table. The value "10''" can''t be evaluated into type BigInteger.');
        Probe.Expect('quotedA.Big', '10 | FBig: 10 | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Big_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBig();
        Probe.CellArg('p1.Big', 11, '%1', 'a');
        Probe.CellArg('pne.Big', 11, '<>%1', 'a');
        Probe.CellArg('pge.Big', 11, '>=%1', 'a');
        Probe.CellArg('pstar.Big', 11, '%1', 'w');
        Probe.CellArg('pnestar.Big', 11, '<>%1', 'w');
        Probe.CellArg('pq.Big', 11, '%1', 'q');
        Probe.CellArg('pnq.Big', 11, '<>%1', 'q');
        Probe.Expect('p1.Big', '10 | FBig: 10 | 2');
        Probe.Expect('pne.Big', '<>10 | FBig: <>10 | 1,3,4');
        Probe.Expect('pge.Big', '>=10 | FBig: >=10 | 2,3,4');
#if BC28PLUS
        Probe.Expect('pstar.Big', 'E: The value "a*b?" can''t be evaluated into type BigInteger.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Big', 'E: The type NavBigInteger is unknown.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Big', 'E: The value "a*b?" can''t be evaluated into type BigInteger.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Big', 'E: The type NavBigInteger is unknown.');
#endif
        Probe.Expect('pq.Big', '63 | FBig: 63 | ');
        Probe.Expect('pnq.Big', '<>63 | FBig: <>63 | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Big_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBig();
        Probe.CellRange('r1.Big', 11, 'r1');
        Probe.CellRange('r2.Big', 11, 'r2');
        Probe.CellRange('rtext.Big', 11, 'rt');
        Probe.Expect('r1.Big', '10 | FBig: 10 | 2');
        Probe.Expect('r2.Big', '10 | FBig: 10 | 2');
        Probe.Expect('rtext.Big', '10 | FBig: 10 | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Big_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBig();
        Probe.CellView('vgt.Big', 11, '>{a}');
        Probe.CellView('vne.Big', 11, '<>{a}');
        Probe.CellView('vrng.Big', 11, '{a}..{b}');
        Probe.CellView('vor.Big', 11, '{a}|{b}');
        Probe.CellView('veq.Big', 11, '{a}');
        Probe.Expect('vgt.Big', 'VERSION(1) SORTING(No.) WHERE(FBig=FILTER(>10)) | VERSION(1) SORTING(Field1) WHERE(Field11=1(>10)) | >10 | 3,4');
        Probe.Expect('vne.Big', 'VERSION(1) SORTING(No.) WHERE(FBig=FILTER(<>10)) | VERSION(1) SORTING(Field1) WHERE(Field11=1(<>10)) | <>10 | 1,3,4');
        Probe.Expect('vrng.Big', 'VERSION(1) SORTING(No.) WHERE(FBig=FILTER(10..20)) | VERSION(1) SORTING(Field1) WHERE(Field11=1(10..20)) | 10..20 | 2,3');
        Probe.Expect('vor.Big', 'VERSION(1) SORTING(No.) WHERE(FBig=FILTER(10|20)) | VERSION(1) SORTING(Field1) WHERE(Field11=1(10|20)) | 10|20 | 2,3');
        Probe.Expect('veq.Big', 'VERSION(1) SORTING(No.) WHERE(FBig=FILTER(10)) | VERSION(1) SORTING(Field1) WHERE(Field11=1(10)) | 10 | 2');
        Probe.Verify();
    end;

    local procedure SeedDec()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FDec := 1.5;
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FDec := 2.5;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FDec := 3.5;
        R.Insert();
    end;

    [Test]
    procedure Filter_Dec_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDec();
        Probe.Cell('eq.Dec', 12, '{a}');
        Probe.Cell('eqop.Dec', 12, '={a}');
        Probe.Cell('ne.Dec', 12, '<>{a}');
        Probe.Cell('lt.Dec', 12, '<{a}');
        Probe.Cell('le.Dec', 12, '<={a}');
        Probe.Cell('gt.Dec', 12, '>{a}');
        Probe.Cell('ge.Dec', 12, '>={a}');
        Probe.Expect('eq.Dec', '1.5 | FDec: 1.5 | 2');
        Probe.Expect('eqop.Dec', '1.5 | FDec: 1.5 | 2');
        Probe.Expect('ne.Dec', '<>1.5 | FDec: <>1.5 | 1,3,4');
        Probe.Expect('lt.Dec', '<1.5 | FDec: <1.5 | 1');
        Probe.Expect('le.Dec', '<=1.5 | FDec: <=1.5 | 1,2');
        Probe.Expect('gt.Dec', '>1.5 | FDec: >1.5 | 3,4');
        Probe.Expect('ge.Dec', '>=1.5 | FDec: >=1.5 | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dec_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDec();
        Probe.Cell('rng.Dec', 12, '{a}..{b}');
        Probe.Cell('upto.Dec', 12, '..{b}');
        Probe.Cell('from.Dec', 12, '{a}..');
        Probe.Cell('or.Dec', 12, '{a}|{b}');
        Probe.Cell('and.Dec', 12, '>{a}&<{b}');
        Probe.Cell('ordinal.Dec', 12, '{o}');
        Probe.Cell('neordinal.Dec', 12, '<>{o}');
        Probe.Expect('rng.Dec', '1.5..2.5 | FDec: 1.5..2.5 | 2,3');
        Probe.Expect('upto.Dec', '..2.5 | FDec: ..2.5 | 1,2,3');
        Probe.Expect('from.Dec', '1.5.. | FDec: 1.5.. | 2,3,4');
        Probe.Expect('or.Dec', '1.5|2.5 | FDec: 1.5|2.5 | 2,3');
        Probe.Expect('and.Dec', '>1.5&<2.5 | FDec: >1.5&<2.5 | ');
        Probe.Expect('ordinal.Dec', '1.5 | FDec: 1.5 | 2');
        Probe.Expect('neordinal.Dec', '<>1.5 | FDec: <>1.5 | 1,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dec_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDec();
        Probe.Cell('star.Dec', 12, '*');
        Probe.Cell('q.Dec', 12, '?');
        Probe.Cell('at.Dec', 12, '@{a}');
        Probe.Cell('prefix.Dec', 12, '{a}*');
        Probe.Cell('nstar.Dec', 12, '<>*');
        Probe.Cell('suffix.Dec', 12, '*{a}');
        Probe.Expect('star.Dec', 'E: The filter "*" is not valid for the FDec field on the LT FRM Row table. The value "*" can''t be evaluated into type Decimal.');
        Probe.Expect('q.Dec', 'E: The filter "?" is not valid for the FDec field on the LT FRM Row table. The value "?" can''t be evaluated into type Decimal.');
        Probe.Expect('at.Dec', 'E: The filter "@1.5" is not valid for the FDec field on the LT FRM Row table. The value "@1.5" can''t be evaluated into type Decimal.');
        Probe.Expect('prefix.Dec', 'E: The filter "1.5*" is not valid for the FDec field on the LT FRM Row table. The value "1.5*" can''t be evaluated into type Decimal.');
        Probe.Expect('nstar.Dec', 'E: The filter "<>*" is not valid for the FDec field on the LT FRM Row table. The value "*" can''t be evaluated into type Decimal.');
        Probe.Expect('suffix.Dec', 'E: The filter "*1.5" is not valid for the FDec field on the LT FRM Row table. The value "*1.5" can''t be evaluated into type Decimal.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dec_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDec();
        Probe.Cell('empty.Dec', 12, '');
        Probe.Cell('quotes.Dec', 12, '''''');
        Probe.Cell('nequotes.Dec', 12, '<>''''');
        Probe.Cell('bare.Dec', 12, '<>');
        Probe.Cell('unterm.Dec', 12, '''');
        Probe.Cell('unterm2.Dec', 12, '{a}''');
        Probe.Cell('quotedA.Dec', 12, '''{a}''');
        Probe.Expect('empty.Dec', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Dec', 'E: The filter "''''" is not valid for the FDec field on the LT FRM Row table. The value "" can''t be evaluated into type Decimal.');
        Probe.Expect('nequotes.Dec', 'E: The filter "<>''''" is not valid for the FDec field on the LT FRM Row table. The value "" can''t be evaluated into type Decimal.');
        Probe.Expect('bare.Dec', 'E: The filter "<>" is not valid for the FDec field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Dec', 'E: The filter "''" is not valid for the FDec field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Dec', 'E: The filter "1.5''" is not valid for the FDec field on the LT FRM Row table. The value "1.5''" can''t be evaluated into type Decimal.');
        Probe.Expect('quotedA.Dec', '1.5 | FDec: 1.5 | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dec_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDec();
        Probe.CellArg('p1.Dec', 12, '%1', 'a');
        Probe.CellArg('pne.Dec', 12, '<>%1', 'a');
        Probe.CellArg('pge.Dec', 12, '>=%1', 'a');
        Probe.CellArg('pstar.Dec', 12, '%1', 'w');
        Probe.CellArg('pnestar.Dec', 12, '<>%1', 'w');
        Probe.CellArg('pq.Dec', 12, '%1', 'q');
        Probe.CellArg('pnq.Dec', 12, '<>%1', 'q');
        Probe.Expect('p1.Dec', '1.5 | FDec: 1.5 | 2');
        Probe.Expect('pne.Dec', '<>1.5 | FDec: <>1.5 | 1,3,4');
        Probe.Expect('pge.Dec', '>=1.5 | FDec: >=1.5 | 2,3,4');
#if BC28PLUS
        Probe.Expect('pstar.Dec', 'E: The value "a*b?" can''t be evaluated into type Decimal.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Dec', 'E: The type NavDecimal is unknown.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Dec', 'E: The value "a*b?" can''t be evaluated into type Decimal.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Dec', 'E: The type NavDecimal is unknown.');
#endif
        Probe.Expect('pq.Dec', '63 | FDec: 63 | ');
        Probe.Expect('pnq.Dec', '<>63 | FDec: <>63 | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dec_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDec();
        Probe.CellRange('r1.Dec', 12, 'r1');
        Probe.CellRange('r2.Dec', 12, 'r2');
        Probe.CellRange('rtext.Dec', 12, 'rt');
        Probe.Expect('r1.Dec', '1.5 | FDec: 1.5 | 2');
        Probe.Expect('r2.Dec', '1.5 | FDec: 1.5 | 2');
        Probe.Expect('rtext.Dec', '1.5 | FDec: 1.5 | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dec_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDec();
        Probe.CellView('vgt.Dec', 12, '>{a}');
        Probe.CellView('vne.Dec', 12, '<>{a}');
        Probe.CellView('vrng.Dec', 12, '{a}..{b}');
        Probe.CellView('vor.Dec', 12, '{a}|{b}');
        Probe.CellView('veq.Dec', 12, '{a}');
        Probe.Expect('vgt.Dec', 'VERSION(1) SORTING(No.) WHERE(FDec=FILTER(>1.5)) | VERSION(1) SORTING(Field1) WHERE(Field12=1(>1.5)) | >1.5 | 3,4');
        Probe.Expect('vne.Dec', 'VERSION(1) SORTING(No.) WHERE(FDec=FILTER(<>1.5)) | VERSION(1) SORTING(Field1) WHERE(Field12=1(<>1.5)) | <>1.5 | 1,3,4');
        Probe.Expect('vrng.Dec', 'VERSION(1) SORTING(No.) WHERE(FDec=FILTER(1.5..2.5)) | VERSION(1) SORTING(Field1) WHERE(Field12=1(1.5..2.5)) | 1.5..2.5 | 2,3');
        Probe.Expect('vor.Dec', 'VERSION(1) SORTING(No.) WHERE(FDec=FILTER(1.5|2.5)) | VERSION(1) SORTING(Field1) WHERE(Field12=1(1.5|2.5)) | 1.5|2.5 | 2,3');
        Probe.Expect('veq.Dec', 'VERSION(1) SORTING(No.) WHERE(FDec=FILTER(1.5)) | VERSION(1) SORTING(Field1) WHERE(Field12=1(1.5)) | 1.5 | 2');
        Probe.Verify();
    end;

    local procedure SeedDur()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FDur := 1000;
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FDur := 60000;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FDur := 3600000;
        R.Insert();
    end;

    [Test]
    procedure Filter_Dur_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDur();
        Probe.Cell('eq.Dur', 13, '{a}');
        Probe.Cell('eqop.Dur', 13, '={a}');
        Probe.Cell('ne.Dur', 13, '<>{a}');
        Probe.Cell('lt.Dur', 13, '<{a}');
        Probe.Cell('le.Dur', 13, '<={a}');
        Probe.Cell('gt.Dur', 13, '>{a}');
        Probe.Cell('ge.Dur', 13, '>={a}');
        Probe.Expect('eq.Dur', '1 second | FDur: 1 second | 2');
        Probe.Expect('eqop.Dur', '1 second | FDur: 1 second | 2');
        Probe.Expect('ne.Dur', '<>1 second | FDur: <>1 second | 1,3,4');
        Probe.Expect('lt.Dur', '<1 second | FDur: <1 second | 1');
        Probe.Expect('le.Dur', '<=1 second | FDur: <=1 second | 1,2');
        Probe.Expect('gt.Dur', '>1 second | FDur: >1 second | 3,4');
        Probe.Expect('ge.Dur', '>=1 second | FDur: >=1 second | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dur_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDur();
        Probe.Cell('rng.Dur', 13, '{a}..{b}');
        Probe.Cell('upto.Dur', 13, '..{b}');
        Probe.Cell('from.Dur', 13, '{a}..');
        Probe.Cell('or.Dur', 13, '{a}|{b}');
        Probe.Cell('and.Dur', 13, '>{a}&<{b}');
        Probe.Cell('ordinal.Dur', 13, '{o}');
        Probe.Cell('neordinal.Dur', 13, '<>{o}');
        Probe.Expect('rng.Dur', '1 second..1 minute | FDur: 1 second..1 minute | 2,3');
        Probe.Expect('upto.Dur', '..1 minute | FDur: ..1 minute | 1,2,3');
        Probe.Expect('from.Dur', '1 second.. | FDur: 1 second.. | 2,3,4');
        Probe.Expect('or.Dur', '1 second|1 minute | FDur: 1 second|1 minute | 2,3');
        Probe.Expect('and.Dur', '>1 second&<1 minute | FDur: >1 second&<1 minute | ');
        Probe.Expect('ordinal.Dur', '1 day 6 hours | FDur: 1 day 6 hours | ');
        Probe.Expect('neordinal.Dur', '<>1 day 6 hours | FDur: <>1 day 6 hours | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dur_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDur();
        Probe.Cell('star.Dur', 13, '*');
        Probe.Cell('q.Dur', 13, '?');
        Probe.Cell('at.Dur', 13, '@{a}');
        Probe.Cell('prefix.Dur', 13, '{a}*');
        Probe.Cell('nstar.Dur', 13, '<>*');
        Probe.Cell('suffix.Dur', 13, '*{a}');
        Probe.Expect('star.Dur', 'E: The filter "*" is not valid for the FDur field on the LT FRM Row table. The value "*" can''t be evaluated into type Duration.');
        Probe.Expect('q.Dur', 'E: The filter "?" is not valid for the FDur field on the LT FRM Row table. The value "?" can''t be evaluated into type Duration.');
        Probe.Expect('at.Dur', 'E: The filter "@1 second" is not valid for the FDur field on the LT FRM Row table. The value "@1 second" can''t be evaluated into type Duration.');
        Probe.Expect('prefix.Dur', 'E: The filter "1 second*" is not valid for the FDur field on the LT FRM Row table. The value "1 second*" can''t be evaluated into type Duration.');
        Probe.Expect('nstar.Dur', 'E: The filter "<>*" is not valid for the FDur field on the LT FRM Row table. The value "*" can''t be evaluated into type Duration.');
        Probe.Expect('suffix.Dur', 'E: The filter "*1 second" is not valid for the FDur field on the LT FRM Row table. The value "*1 second" can''t be evaluated into type Duration.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dur_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDur();
        Probe.Cell('empty.Dur', 13, '');
        Probe.Cell('quotes.Dur', 13, '''''');
        Probe.Cell('nequotes.Dur', 13, '<>''''');
        Probe.Cell('bare.Dur', 13, '<>');
        Probe.Cell('unterm.Dur', 13, '''');
        Probe.Cell('unterm2.Dur', 13, '{a}''');
        Probe.Cell('quotedA.Dur', 13, '''{a}''');
        Probe.Expect('empty.Dur', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Dur', ''''' | FDur: '''' | 1');
        Probe.Expect('nequotes.Dur', '<>'''' | FDur: <>'''' | 2,3,4');
        Probe.Expect('bare.Dur', 'E: The filter "<>" is not valid for the FDur field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Dur', 'E: The filter "''" is not valid for the FDur field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Dur', 'E: The filter "1 second''" is not valid for the FDur field on the LT FRM Row table. The value "1 second''" can''t be evaluated into type Duration.');
        Probe.Expect('quotedA.Dur', '1 second | FDur: 1 second | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dur_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDur();
        Probe.CellArg('p1.Dur', 13, '%1', 'a');
        Probe.CellArg('pne.Dur', 13, '<>%1', 'a');
        Probe.CellArg('pge.Dur', 13, '>=%1', 'a');
        Probe.CellArg('pstar.Dur', 13, '%1', 'w');
        Probe.CellArg('pnestar.Dur', 13, '<>%1', 'w');
        Probe.CellArg('pq.Dur', 13, '%1', 'q');
        Probe.CellArg('pnq.Dur', 13, '<>%1', 'q');
        Probe.Expect('p1.Dur', '1 second | FDur: 1 second | 2');
        Probe.Expect('pne.Dur', '<>1 second | FDur: <>1 second | 1,3,4');
        Probe.Expect('pge.Dur', '>=1 second | FDur: >=1 second | 2,3,4');
#if BC28PLUS
        Probe.Expect('pstar.Dur', 'E: The value "a*b?" can''t be evaluated into type Duration.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Dur', 'E: The type NavDuration is unknown.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Dur', 'E: The value "a*b?" can''t be evaluated into type Duration.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Dur', 'E: The type NavDuration is unknown.');
#endif
        Probe.Expect('pq.Dur', '63 milliseconds | FDur: 63 milliseconds | ');
        Probe.Expect('pnq.Dur', '<>63 milliseconds | FDur: <>63 milliseconds | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dur_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDur();
        Probe.CellRange('r1.Dur', 13, 'r1');
        Probe.CellRange('r2.Dur', 13, 'r2');
        Probe.CellRange('rtext.Dur', 13, 'rt');
        Probe.Expect('r1.Dur', '1 second | FDur: 1 second | 2');
        Probe.Expect('r2.Dur', '1 second | FDur: 1 second | 2');
#if BC28PLUS
        Probe.Expect('rtext.Dur', 'E: The value "1 second" can''t be evaluated into type Duration.');
#else // BC 27.5 words this result differently
        Probe.Expect('rtext.Dur', 'E: The type NavDuration is unknown.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Dur_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDur();
        Probe.CellView('vgt.Dur', 13, '>{a}');
        Probe.CellView('vne.Dur', 13, '<>{a}');
        Probe.CellView('vrng.Dur', 13, '{a}..{b}');
        Probe.CellView('vor.Dur', 13, '{a}|{b}');
        Probe.CellView('veq.Dur', 13, '{a}');
        Probe.Expect('vgt.Dur', 'VERSION(1) SORTING(No.) WHERE(FDur=FILTER(>P0DT0H0M1.0S)) | VERSION(1) SORTING(Field1) WHERE(Field13=1(>P0DT0H0M1.0S)) | >1 second | 3,4');
        Probe.Expect('vne.Dur', 'VERSION(1) SORTING(No.) WHERE(FDur=FILTER(<>P0DT0H0M1.0S)) | VERSION(1) SORTING(Field1) WHERE(Field13=1(<>P0DT0H0M1.0S)) | <>1 second | 1,3,4');
        Probe.Expect('vrng.Dur', 'VERSION(1) SORTING(No.) WHERE(FDur=FILTER(P0DT0H0M1.0S..P0DT0H1M0.0S)) | VERSION(1) SORTING(Field1) WHERE(Field13=1(P0DT0H0M1.0S..P0DT0H1M0.0S)) | 1 second..1 minute | 2,3');
        Probe.Expect('vor.Dur', 'VERSION(1) SORTING(No.) WHERE(FDur=FILTER(P0DT0H0M1.0S|P0DT0H1M0.0S)) | VERSION(1) SORTING(Field1) WHERE(Field13=1(P0DT0H0M1.0S|P0DT0H1M0.0S)) | 1 second|1 minute | 2,3');
        Probe.Expect('veq.Dur', 'VERSION(1) SORTING(No.) WHERE(FDur=FILTER(P0DT0H0M1.0S)) | VERSION(1) SORTING(Field1) WHERE(Field13=1(P0DT0H0M1.0S)) | 1 second | 2');
        Probe.Verify();
    end;

}

codeunit 70045 "LT FRM Text Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedCode()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FCode := 'AB';
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FCode := 'BC';
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FCode := 'CD';
        R.Insert();
    end;

    [Test]
    procedure Filter_Code_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedCode();
        Probe.Cell('eq.Code', 14, '{a}');
        Probe.Cell('eqop.Code', 14, '={a}');
        Probe.Cell('ne.Code', 14, '<>{a}');
        Probe.Cell('lt.Code', 14, '<{a}');
        Probe.Cell('le.Code', 14, '<={a}');
        Probe.Cell('gt.Code', 14, '>{a}');
        Probe.Cell('ge.Code', 14, '>={a}');
        Probe.Expect('eq.Code', 'AB | FCode: AB | 2');
        Probe.Expect('eqop.Code', 'AB | FCode: AB | 2');
        Probe.Expect('ne.Code', '<>AB | FCode: <>AB | 1,3,4');
        Probe.Expect('lt.Code', '<AB | FCode: <AB | 1');
        Probe.Expect('le.Code', '<=AB | FCode: <=AB | 1,2');
        Probe.Expect('gt.Code', '>AB | FCode: >AB | 3,4');
        Probe.Expect('ge.Code', '>=AB | FCode: >=AB | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Code_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedCode();
        Probe.Cell('rng.Code', 14, '{a}..{b}');
        Probe.Cell('upto.Code', 14, '..{b}');
        Probe.Cell('from.Code', 14, '{a}..');
        Probe.Cell('or.Code', 14, '{a}|{b}');
        Probe.Cell('and.Code', 14, '>{a}&<{b}');
        Probe.Cell('ordinal.Code', 14, '{o}');
        Probe.Cell('neordinal.Code', 14, '<>{o}');
        Probe.Expect('rng.Code', 'AB..BC | FCode: AB..BC | 2,3');
        Probe.Expect('upto.Code', '..BC | FCode: ..BC | 1,2,3');
        Probe.Expect('from.Code', 'AB.. | FCode: AB.. | 2,3,4');
        Probe.Expect('or.Code', 'AB|BC | FCode: AB|BC | 2,3');
        Probe.Expect('and.Code', '>AB&<BC | FCode: >AB&<BC | ');
        Probe.Expect('ordinal.Code', 'AB | FCode: AB | 2');
        Probe.Expect('neordinal.Code', '<>AB | FCode: <>AB | 1,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Code_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedCode();
        Probe.Cell('star.Code', 14, '*');
        Probe.Cell('q.Code', 14, '?');
        Probe.Cell('at.Code', 14, '@{a}');
        Probe.Cell('prefix.Code', 14, '{a}*');
        Probe.Cell('nstar.Code', 14, '<>*');
        Probe.Cell('suffix.Code', 14, '*{a}');
        Probe.Expect('star.Code', '* | FCode: * | 1,2,3,4');
        Probe.Expect('q.Code', '? | FCode: ? | ');
        Probe.Expect('at.Code', '@AB | FCode: @AB | 2');
        Probe.Expect('prefix.Code', 'AB* | FCode: AB* | 2');
        Probe.Expect('nstar.Code', '<>* | FCode: <>* | ');
        Probe.Expect('suffix.Code', '*AB | FCode: *AB | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Code_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedCode();
        Probe.Cell('empty.Code', 14, '');
        Probe.Cell('quotes.Code', 14, '''''');
        Probe.Cell('nequotes.Code', 14, '<>''''');
        Probe.Cell('bare.Code', 14, '<>');
        Probe.Cell('unterm.Code', 14, '''');
        Probe.Cell('unterm2.Code', 14, '{a}''');
        Probe.Cell('quotedA.Code', 14, '''{a}''');
        Probe.Expect('empty.Code', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Code', ''''' | FCode: '''' | 1');
        Probe.Expect('nequotes.Code', '<>'''' | FCode: <>'''' | 2,3,4');
        Probe.Expect('bare.Code', 'E: The filter "<>" is not valid for the FCode field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Code', 'E: The filter "''" is not valid for the FCode field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Code', 'AB'' | FCode: AB'' | ');
        Probe.Expect('quotedA.Code', 'AB | FCode: AB | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Code_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedCode();
        Probe.CellArg('p1.Code', 14, '%1', 'a');
        Probe.CellArg('pne.Code', 14, '<>%1', 'a');
        Probe.CellArg('pge.Code', 14, '>=%1', 'a');
        Probe.CellArg('pstar.Code', 14, '%1', 'w');
        Probe.CellArg('pnestar.Code', 14, '<>%1', 'w');
        Probe.CellArg('pq.Code', 14, '%1', 'q');
        Probe.CellArg('pnq.Code', 14, '<>%1', 'q');
        Probe.Expect('p1.Code', 'AB | FCode: AB | 2');
        Probe.Expect('pne.Code', '<>AB | FCode: <>AB | 1,3,4');
        Probe.Expect('pge.Code', '>=AB | FCode: >=AB | 2,3,4');
        Probe.Expect('pstar.Code', 'A*B? | FCode: A*B? | ');
        Probe.Expect('pnestar.Code', '<>A*B? | FCode: <>A*B? | 1,2,3,4');
        Probe.Expect('pq.Code', '=''?'' | FCode: =''?'' | ');
        Probe.Expect('pnq.Code', '<>''?'' | FCode: <>''?'' | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Code_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedCode();
        Probe.CellRange('r1.Code', 14, 'r1');
        Probe.CellRange('r2.Code', 14, 'r2');
        Probe.CellRange('rtext.Code', 14, 'rt');
        Probe.Expect('r1.Code', 'AB | FCode: AB | 2');
        Probe.Expect('r2.Code', 'AB | FCode: AB | 2');
        Probe.Expect('rtext.Code', 'AB | FCode: AB | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Code_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedCode();
        Probe.CellView('vgt.Code', 14, '>{a}');
        Probe.CellView('vne.Code', 14, '<>{a}');
        Probe.CellView('vrng.Code', 14, '{a}..{b}');
        Probe.CellView('vor.Code', 14, '{a}|{b}');
        Probe.CellView('veq.Code', 14, '{a}');
        Probe.Expect('vgt.Code', 'VERSION(1) SORTING(No.) WHERE(FCode=FILTER(>AB)) | VERSION(1) SORTING(Field1) WHERE(Field14=1(>AB)) | >AB | 3,4');
        Probe.Expect('vne.Code', 'VERSION(1) SORTING(No.) WHERE(FCode=FILTER(<>AB)) | VERSION(1) SORTING(Field1) WHERE(Field14=1(<>AB)) | <>AB | 1,3,4');
        Probe.Expect('vrng.Code', 'VERSION(1) SORTING(No.) WHERE(FCode=FILTER(AB..BC)) | VERSION(1) SORTING(Field1) WHERE(Field14=1(AB..BC)) | AB..BC | 2,3');
        Probe.Expect('vor.Code', 'VERSION(1) SORTING(No.) WHERE(FCode=FILTER(AB|BC)) | VERSION(1) SORTING(Field1) WHERE(Field14=1(AB|BC)) | AB|BC | 2,3');
        Probe.Expect('veq.Code', 'VERSION(1) SORTING(No.) WHERE(FCode=FILTER(AB)) | VERSION(1) SORTING(Field1) WHERE(Field14=1(AB)) | AB | 2');
        Probe.Verify();
    end;

    local procedure SeedText()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FText := 'ab';
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FText := 'bc';
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FText := 'cd';
        R.Insert();
    end;

    [Test]
    procedure Filter_Text_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedText();
        Probe.Cell('eq.Text', 15, '{a}');
        Probe.Cell('eqop.Text', 15, '={a}');
        Probe.Cell('ne.Text', 15, '<>{a}');
        Probe.Cell('lt.Text', 15, '<{a}');
        Probe.Cell('le.Text', 15, '<={a}');
        Probe.Cell('gt.Text', 15, '>{a}');
        Probe.Cell('ge.Text', 15, '>={a}');
        Probe.Expect('eq.Text', 'ab | FText: ab | 2');
        Probe.Expect('eqop.Text', 'ab | FText: ab | 2');
        Probe.Expect('ne.Text', '<>ab | FText: <>ab | 1,3,4');
        Probe.Expect('lt.Text', '<ab | FText: <ab | 1');
        Probe.Expect('le.Text', '<=ab | FText: <=ab | 1,2');
        Probe.Expect('gt.Text', '>ab | FText: >ab | 3,4');
        Probe.Expect('ge.Text', '>=ab | FText: >=ab | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Text_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedText();
        Probe.Cell('rng.Text', 15, '{a}..{b}');
        Probe.Cell('upto.Text', 15, '..{b}');
        Probe.Cell('from.Text', 15, '{a}..');
        Probe.Cell('or.Text', 15, '{a}|{b}');
        Probe.Cell('and.Text', 15, '>{a}&<{b}');
        Probe.Cell('ordinal.Text', 15, '{o}');
        Probe.Cell('neordinal.Text', 15, '<>{o}');
        Probe.Expect('rng.Text', 'ab..bc | FText: ab..bc | 2,3');
        Probe.Expect('upto.Text', '..bc | FText: ..bc | 1,2,3');
        Probe.Expect('from.Text', 'ab.. | FText: ab.. | 2,3,4');
        Probe.Expect('or.Text', 'ab|bc | FText: ab|bc | 2,3');
        Probe.Expect('and.Text', '>ab&<bc | FText: >ab&<bc | ');
        Probe.Expect('ordinal.Text', 'ab | FText: ab | 2');
        Probe.Expect('neordinal.Text', '<>ab | FText: <>ab | 1,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Text_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedText();
        Probe.Cell('star.Text', 15, '*');
        Probe.Cell('q.Text', 15, '?');
        Probe.Cell('at.Text', 15, '@{a}');
        Probe.Cell('prefix.Text', 15, '{a}*');
        Probe.Cell('nstar.Text', 15, '<>*');
        Probe.Cell('suffix.Text', 15, '*{a}');
        Probe.Expect('star.Text', '* | FText: * | 1,2,3,4');
        Probe.Expect('q.Text', '? | FText: ? | ');
        Probe.Expect('at.Text', '@ab | FText: @ab | 2');
        Probe.Expect('prefix.Text', 'ab* | FText: ab* | 2');
        Probe.Expect('nstar.Text', '<>* | FText: <>* | ');
        Probe.Expect('suffix.Text', '*ab | FText: *ab | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Text_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedText();
        Probe.Cell('empty.Text', 15, '');
        Probe.Cell('quotes.Text', 15, '''''');
        Probe.Cell('nequotes.Text', 15, '<>''''');
        Probe.Cell('bare.Text', 15, '<>');
        Probe.Cell('unterm.Text', 15, '''');
        Probe.Cell('unterm2.Text', 15, '{a}''');
        Probe.Cell('quotedA.Text', 15, '''{a}''');
        Probe.Expect('empty.Text', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Text', ''''' | FText: '''' | 1');
        Probe.Expect('nequotes.Text', '<>'''' | FText: <>'''' | 2,3,4');
        Probe.Expect('bare.Text', 'E: The filter "<>" is not valid for the FText field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Text', 'E: The filter "''" is not valid for the FText field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Text', 'ab'' | FText: ab'' | ');
        Probe.Expect('quotedA.Text', 'ab | FText: ab | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Text_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedText();
        Probe.CellArg('p1.Text', 15, '%1', 'a');
        Probe.CellArg('pne.Text', 15, '<>%1', 'a');
        Probe.CellArg('pge.Text', 15, '>=%1', 'a');
        Probe.CellArg('pstar.Text', 15, '%1', 'w');
        Probe.CellArg('pnestar.Text', 15, '<>%1', 'w');
        Probe.CellArg('pq.Text', 15, '%1', 'q');
        Probe.CellArg('pnq.Text', 15, '<>%1', 'q');
        Probe.Expect('p1.Text', 'ab | FText: ab | 2');
        Probe.Expect('pne.Text', '<>ab | FText: <>ab | 1,3,4');
        Probe.Expect('pge.Text', '>=ab | FText: >=ab | 2,3,4');
        Probe.Expect('pstar.Text', 'a*b? | FText: a*b? | ');
        Probe.Expect('pnestar.Text', '<>a*b? | FText: <>a*b? | 1,2,3,4');
        Probe.Expect('pq.Text', '=''?'' | FText: =''?'' | ');
        Probe.Expect('pnq.Text', '<>''?'' | FText: <>''?'' | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Text_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedText();
        Probe.CellRange('r1.Text', 15, 'r1');
        Probe.CellRange('r2.Text', 15, 'r2');
        Probe.CellRange('rtext.Text', 15, 'rt');
        Probe.Expect('r1.Text', 'ab | FText: ab | 2');
        Probe.Expect('r2.Text', 'ab | FText: ab | 2');
        Probe.Expect('rtext.Text', 'ab | FText: ab | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Text_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedText();
        Probe.CellView('vgt.Text', 15, '>{a}');
        Probe.CellView('vne.Text', 15, '<>{a}');
        Probe.CellView('vrng.Text', 15, '{a}..{b}');
        Probe.CellView('vor.Text', 15, '{a}|{b}');
        Probe.CellView('veq.Text', 15, '{a}');
        Probe.Expect('vgt.Text', 'VERSION(1) SORTING(No.) WHERE(FText=FILTER(>ab)) | VERSION(1) SORTING(Field1) WHERE(Field15=1(>ab)) | >ab | 3,4');
        Probe.Expect('vne.Text', 'VERSION(1) SORTING(No.) WHERE(FText=FILTER(<>ab)) | VERSION(1) SORTING(Field1) WHERE(Field15=1(<>ab)) | <>ab | 1,3,4');
        Probe.Expect('vrng.Text', 'VERSION(1) SORTING(No.) WHERE(FText=FILTER(ab..bc)) | VERSION(1) SORTING(Field1) WHERE(Field15=1(ab..bc)) | ab..bc | 2,3');
        Probe.Expect('vor.Text', 'VERSION(1) SORTING(No.) WHERE(FText=FILTER(ab|bc)) | VERSION(1) SORTING(Field1) WHERE(Field15=1(ab|bc)) | ab|bc | 2,3');
        Probe.Expect('veq.Text', 'VERSION(1) SORTING(No.) WHERE(FText=FILTER(ab)) | VERSION(1) SORTING(Field1) WHERE(Field15=1(ab)) | ab | 2');
        Probe.Verify();
    end;

    local procedure SeedGuid()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        Evaluate(R.FGuid, '{00000001-0000-0000-0000-000000000000}');
        R.Insert();
        R.Init();
        R."No." := 3;
        Evaluate(R.FGuid, '{00000002-0000-0000-0000-000000000000}');
        R.Insert();
        R.Init();
        R."No." := 4;
        Evaluate(R.FGuid, '{00000003-0000-0000-0000-000000000000}');
        R.Insert();
    end;

    [Test]
    procedure Filter_Guid_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedGuid();
        Probe.Cell('eq.Guid', 23, '{a}');
        Probe.Cell('eqop.Guid', 23, '={a}');
        Probe.Cell('ne.Guid', 23, '<>{a}');
        Probe.Cell('lt.Guid', 23, '<{a}');
        Probe.Cell('le.Guid', 23, '<={a}');
        Probe.Cell('gt.Guid', 23, '>{a}');
        Probe.Cell('ge.Guid', 23, '>={a}');
        Probe.Expect('eq.Guid', '{00000001-0000-0000-0000-000000000000} | FGuid: {00000001-0000-0000-0000-000000000000} | 2');
        Probe.Expect('eqop.Guid', '{00000001-0000-0000-0000-000000000000} | FGuid: {00000001-0000-0000-0000-000000000000} | 2');
        Probe.Expect('ne.Guid', '<>{00000001-0000-0000-0000-000000000000} | FGuid: <>{00000001-0000-0000-0000-000000000000} | 1,3,4');
        Probe.Expect('lt.Guid', '<{00000001-0000-0000-0000-000000000000} | FGuid: <{00000001-0000-0000-0000-000000000000} | 1');
        Probe.Expect('le.Guid', '<={00000001-0000-0000-0000-000000000000} | FGuid: <={00000001-0000-0000-0000-000000000000} | 1,2');
        Probe.Expect('gt.Guid', '>{00000001-0000-0000-0000-000000000000} | FGuid: >{00000001-0000-0000-0000-000000000000} | 3,4');
        Probe.Expect('ge.Guid', '>={00000001-0000-0000-0000-000000000000} | FGuid: >={00000001-0000-0000-0000-000000000000} | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Guid_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedGuid();
        Probe.Cell('rng.Guid', 23, '{a}..{b}');
        Probe.Cell('upto.Guid', 23, '..{b}');
        Probe.Cell('from.Guid', 23, '{a}..');
        Probe.Cell('or.Guid', 23, '{a}|{b}');
        Probe.Cell('and.Guid', 23, '>{a}&<{b}');
        Probe.Cell('ordinal.Guid', 23, '{o}');
        Probe.Cell('neordinal.Guid', 23, '<>{o}');
        Probe.Expect('rng.Guid', '{00000001-0000-0000-0000-000000000000}..{00000002-0000-0000-0000-000000000000} | FGuid: {00000001-0000-0000-0000-000000000000}..{00000002-0000-0000-0000-000000000000} | 2,3');
        Probe.Expect('upto.Guid', '..{00000002-0000-0000-0000-000000000000} | FGuid: ..{00000002-0000-0000-0000-000000000000} | 1,2,3');
        Probe.Expect('from.Guid', '{00000001-0000-0000-0000-000000000000}.. | FGuid: {00000001-0000-0000-0000-000000000000}.. | 2,3,4');
        Probe.Expect('or.Guid', '{00000001-0000-0000-0000-000000000000}|{00000002-0000-0000-0000-000000000000} | FGuid: {00000001-0000-0000-0000-000000000000}|{00000002-0000-0000-0000-000000000000} | 2,3');
        Probe.Expect('and.Guid', '>{00000001-0000-0000-0000-000000000000}&<{00000002-0000-0000-0000-000000000000} | FGuid: >{00000001-0000-0000-0000-000000000000}&<{00000002-0000-0000-0000-000000000000} | ');
        Probe.Expect('ordinal.Guid', '{00000001-0000-0000-0000-000000000000} | FGuid: {00000001-0000-0000-0000-000000000000} | 2');
        Probe.Expect('neordinal.Guid', '<>{00000001-0000-0000-0000-000000000000} | FGuid: <>{00000001-0000-0000-0000-000000000000} | 1,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Guid_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedGuid();
        Probe.Cell('star.Guid', 23, '*');
        Probe.Cell('q.Guid', 23, '?');
        Probe.Cell('at.Guid', 23, '@{a}');
        Probe.Cell('prefix.Guid', 23, '{a}*');
        Probe.Cell('nstar.Guid', 23, '<>*');
        Probe.Cell('suffix.Guid', 23, '*{a}');
        Probe.Expect('star.Guid', 'E: The filter "*" is not valid for the FGuid field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('q.Guid', 'E: The filter "?" is not valid for the FGuid field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('at.Guid', 'E: The filter "@{00000001-0000-0000-0000-000000000000}" is not valid for the FGuid field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('prefix.Guid', 'E: The filter "{00000001-0000-0000-0000-000000000000}*" is not valid for the FGuid field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('nstar.Guid', 'E: The filter "<>*" is not valid for the FGuid field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('suffix.Guid', 'E: The filter "*{00000001-0000-0000-0000-000000000000}" is not valid for the FGuid field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Guid_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedGuid();
        Probe.Cell('empty.Guid', 23, '');
        Probe.Cell('quotes.Guid', 23, '''''');
        Probe.Cell('nequotes.Guid', 23, '<>''''');
        Probe.Cell('bare.Guid', 23, '<>');
        Probe.Cell('unterm.Guid', 23, '''');
        Probe.Cell('unterm2.Guid', 23, '{a}''');
        Probe.Cell('quotedA.Guid', 23, '''{a}''');
        Probe.Expect('empty.Guid', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Guid', 'E: The filter "''''" is not valid for the FGuid field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('nequotes.Guid', 'E: The filter "<>''''" is not valid for the FGuid field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('bare.Guid', 'E: The filter "<>" is not valid for the FGuid field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Guid', 'E: The filter "''" is not valid for the FGuid field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Guid', 'E: The filter "{00000001-0000-0000-0000-000000000000}''" is not valid for the FGuid field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('quotedA.Guid', '{00000001-0000-0000-0000-000000000000} | FGuid: {00000001-0000-0000-0000-000000000000} | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Guid_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedGuid();
        Probe.CellArg('p1.Guid', 23, '%1', 'a');
        Probe.CellArg('pne.Guid', 23, '<>%1', 'a');
        Probe.CellArg('pge.Guid', 23, '>=%1', 'a');
        Probe.CellArg('pstar.Guid', 23, '%1', 'w');
        Probe.CellArg('pnestar.Guid', 23, '<>%1', 'w');
        Probe.CellArg('pq.Guid', 23, '%1', 'q');
        Probe.CellArg('pnq.Guid', 23, '<>%1', 'q');
        Probe.Expect('p1.Guid', '{00000001-0000-0000-0000-000000000000} | FGuid: {00000001-0000-0000-0000-000000000000} | 2');
        Probe.Expect('pne.Guid', '<>{00000001-0000-0000-0000-000000000000} | FGuid: <>{00000001-0000-0000-0000-000000000000} | 1,3,4');
        Probe.Expect('pge.Guid', '>={00000001-0000-0000-0000-000000000000} | FGuid: >={00000001-0000-0000-0000-000000000000} | 2,3,4');
#if BC28PLUS
        Probe.Expect('pstar.Guid', 'E: The value "a*b?" can''t be evaluated into type GUID.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavGuid.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Guid', 'E: The value "a*b?" can''t be evaluated into type GUID.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavGuid.');
#endif
#if BC28PLUS
        Probe.Expect('pq.Guid', 'E: The value "?" can''t be evaluated into type GUID.');
#else // BC 27.5 words this result differently
        Probe.Expect('pq.Guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavGuid.');
#endif
#if BC28PLUS
        Probe.Expect('pnq.Guid', 'E: The value "?" can''t be evaluated into type GUID.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnq.Guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavGuid.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Guid_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedGuid();
        Probe.CellRange('r1.Guid', 23, 'r1');
        Probe.CellRange('r2.Guid', 23, 'r2');
        Probe.CellRange('rtext.Guid', 23, 'rt');
        Probe.Expect('r1.Guid', '{00000001-0000-0000-0000-000000000000} | FGuid: {00000001-0000-0000-0000-000000000000} | 2');
        Probe.Expect('r2.Guid', '{00000001-0000-0000-0000-000000000000} | FGuid: {00000001-0000-0000-0000-000000000000} | 2');
#if BC28PLUS
        Probe.Expect('rtext.Guid', 'E: The value "{00000001-0000-0000-0000-000000000000}" can''t be evaluated into type GUID.');
#else // BC 27.5 words this result differently
        Probe.Expect('rtext.Guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavGuid.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Guid_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedGuid();
        Probe.CellView('vgt.Guid', 23, '>{a}');
        Probe.CellView('vne.Guid', 23, '<>{a}');
        Probe.CellView('vrng.Guid', 23, '{a}..{b}');
        Probe.CellView('vor.Guid', 23, '{a}|{b}');
        Probe.CellView('veq.Guid', 23, '{a}');
        Probe.Expect('vgt.Guid', 'VERSION(1) SORTING(No.) WHERE(FGuid=FILTER(>{00000001-0000-0000-0000-000000000000})) | VERSION(1) SORTING(Field1) WHERE(Field23=1(>{00000001-0000-0000-0000-000000000000})) | >{00000001-0000-0000-0000-000000000000} | 3,4');
        Probe.Expect('vne.Guid', 'VERSION(1) SORTING(No.) WHERE(FGuid=FILTER(<>{00000001-0000-0000-0000-000000000000})) | VERSION(1) SORTING(Field1) WHERE(Field23=1(<>{00000001-0000-0000-0000-000000000000})) | <>{00000001-0000-0000-0000-000000000000} | 1,3,4');
        Probe.Expect('vrng.Guid', 'VERSION(1) SORTING(No.) WHERE(FGuid=FILTER({00000001-0000-0000-0000-000000000000}..{00000002-0000-0000-0000-000000000000})) | VERSION(1) SORTING(Field1) WHERE(Field23=1({00000001-0000-0000-0000-000000000000}..{00000002-0000-0000-0000-000000000000})) | {00000001-0000-0000-0000-000000000000}..{00000002-0000-0000-0000-000000000000} | 2,3');
        Probe.Expect('vor.Guid', 'VERSION(1) SORTING(No.) WHERE(FGuid=FILTER({00000001-0000-0000-0000-000000000000}|{00000002-0000-0000-0000-000000000000})) | VERSION(1) SORTING(Field1) WHERE(Field23=1({00000001-0000-0000-0000-000000000000}|{00000002-0000-0000-0000-000000000000})) | {00000001-0000-0000-0000-000000000000}|{00000002-0000-0000-0000-000000000000} | 2,3');
        Probe.Expect('veq.Guid', 'VERSION(1) SORTING(No.) WHERE(FGuid=FILTER({00000001-0000-0000-0000-000000000000})) | VERSION(1) SORTING(Field1) WHERE(Field23=1({00000001-0000-0000-0000-000000000000})) | {00000001-0000-0000-0000-000000000000} | 2');
        Probe.Verify();
    end;

}

codeunit 70046 "LT FRM DateTime Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedDate()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FDate := 20240101D;
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FDate := 20240201D;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FDate := 20240301D;
        R.Insert();
    end;

    [Test]
    procedure Filter_Date_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDate();
        Probe.Cell('eq.Date', 16, '{a}');
        Probe.Cell('eqop.Date', 16, '={a}');
        Probe.Cell('ne.Date', 16, '<>{a}');
        Probe.Cell('lt.Date', 16, '<{a}');
        Probe.Cell('le.Date', 16, '<={a}');
        Probe.Cell('gt.Date', 16, '>{a}');
        Probe.Cell('ge.Date', 16, '>={a}');
        Probe.Expect('eq.Date', '01/01/24 | FDate: 01/01/24 | 2');
        Probe.Expect('eqop.Date', '01/01/24 | FDate: 01/01/24 | 2');
        Probe.Expect('ne.Date', '<>01/01/24 | FDate: <>01/01/24 | 1,3,4');
        Probe.Expect('lt.Date', '<01/01/24 | FDate: <01/01/24 | 1');
        Probe.Expect('le.Date', '<=01/01/24 | FDate: <=01/01/24 | 1,2');
        Probe.Expect('gt.Date', '>01/01/24 | FDate: >01/01/24 | 3,4');
        Probe.Expect('ge.Date', '>=01/01/24 | FDate: >=01/01/24 | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Date_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDate();
        Probe.Cell('rng.Date', 16, '{a}..{b}');
        Probe.Cell('upto.Date', 16, '..{b}');
        Probe.Cell('from.Date', 16, '{a}..');
        Probe.Cell('or.Date', 16, '{a}|{b}');
        Probe.Cell('and.Date', 16, '>{a}&<{b}');
        Probe.Cell('ordinal.Date', 16, '{o}');
        Probe.Cell('neordinal.Date', 16, '<>{o}');
        Probe.Expect('rng.Date', '01/01/24..02/01/24 | FDate: 01/01/24..02/01/24 | 2,3');
        Probe.Expect('upto.Date', '..02/01/24 | FDate: ..02/01/24 | 1,2,3');
        Probe.Expect('from.Date', '01/01/24.. | FDate: 01/01/24.. | 2,3,4');
        Probe.Expect('or.Date', '01/01/24|02/01/24 | FDate: 01/01/24|02/01/24 | 2,3');
        Probe.Expect('and.Date', '>01/01/24&<02/01/24 | FDate: >01/01/24&<02/01/24 | ');
        Probe.Expect('ordinal.Date', '01/01/24 | FDate: 01/01/24 | 2');
        Probe.Expect('neordinal.Date', '<>01/01/24 | FDate: <>01/01/24 | 1,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Date_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDate();
        Probe.Cell('star.Date', 16, '*');
        Probe.Cell('q.Date', 16, '?');
        Probe.Cell('at.Date', 16, '@{a}');
        Probe.Cell('prefix.Date', 16, '{a}*');
        Probe.Cell('nstar.Date', 16, '<>*');
        Probe.Cell('suffix.Date', 16, '*{a}');
        Probe.Expect('star.Date', Format(Today()) + ' | FDate: ' + Format(Today()) + ' | '); // '*' on a Date field means today
        Probe.Expect('q.Date', Format(Today()) + ' | FDate: ' + Format(Today()) + ' | ');
        Probe.Expect('at.Date', 'E: The filter "@01/01/24" is not valid for the FDate field on the LT FRM Row table. The format of the Date ''@01/01/24'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Probe.Expect('prefix.Date', '01/01/24 | FDate: 01/01/24 | 2');
        Probe.Expect('nstar.Date', '<>' + Format(Today()) + ' | FDate: <>' + Format(Today()) + ' | 1,2,3,4');
        Probe.Expect('suffix.Date', 'E: The filter "*01/01/24" is not valid for the FDate field on the LT FRM Row table. The format of the Date ''*01/01/24'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Date_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDate();
        Probe.Cell('empty.Date', 16, '');
        Probe.Cell('quotes.Date', 16, '''''');
        Probe.Cell('nequotes.Date', 16, '<>''''');
        Probe.Cell('bare.Date', 16, '<>');
        Probe.Cell('unterm.Date', 16, '''');
        Probe.Cell('unterm2.Date', 16, '{a}''');
        Probe.Cell('quotedA.Date', 16, '''{a}''');
        Probe.Expect('empty.Date', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Date', ''''' | FDate: '''' | 1');
        Probe.Expect('nequotes.Date', '<>'''' | FDate: <>'''' | 2,3,4');
        Probe.Expect('bare.Date', 'E: The filter "<>" is not valid for the FDate field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Date', 'E: The filter "''" is not valid for the FDate field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Date', '01/01/24 | FDate: 01/01/24 | 2');
        Probe.Expect('quotedA.Date', '01/01/24 | FDate: 01/01/24 | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Date_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDate();
        Probe.CellArg('p1.Date', 16, '%1', 'a');
        Probe.CellArg('pne.Date', 16, '<>%1', 'a');
        Probe.CellArg('pge.Date', 16, '>=%1', 'a');
        Probe.CellArg('pstar.Date', 16, '%1', 'w');
        Probe.CellArg('pnestar.Date', 16, '<>%1', 'w');
        Probe.CellArg('pq.Date', 16, '%1', 'q');
        Probe.CellArg('pnq.Date', 16, '<>%1', 'q');
        Probe.Expect('p1.Date', '01/01/24 | FDate: 01/01/24 | 2');
        Probe.Expect('pne.Date', '<>01/01/24 | FDate: <>01/01/24 | 1,3,4');
        Probe.Expect('pge.Date', '>=01/01/24 | FDate: >=01/01/24 | 2,3,4');
#if BC28PLUS
        Probe.Expect('pstar.Date', 'E: The format of the Date ''a*b?'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Date', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Date', 'E: The format of the Date ''a*b?'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Date', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
#if BC28PLUS
        Probe.Expect('pq.Date', 'E: The format of the Date ''?'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else // BC 27.5 words this result differently
        Probe.Expect('pq.Date', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavChar to System.DateTime.');
#endif
#if BC28PLUS
        Probe.Expect('pnq.Date', 'E: The format of the Date ''?'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnq.Date', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavChar to System.DateTime.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Date_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDate();
        Probe.CellRange('r1.Date', 16, 'r1');
        Probe.CellRange('r2.Date', 16, 'r2');
        Probe.CellRange('rtext.Date', 16, 'rt');
        Probe.Expect('r1.Date', '01/01/24 | FDate: 01/01/24 | 2');
        Probe.Expect('r2.Date', '01/01/24 | FDate: 01/01/24 | 2');
#if BC28PLUS
        Probe.Expect('rtext.Date', 'E: The format of the Date ''01/01/24'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else // BC 27.5 words this result differently
        Probe.Expect('rtext.Date', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Date_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDate();
        Probe.CellView('vgt.Date', 16, '>{a}');
        Probe.CellView('vne.Date', 16, '<>{a}');
        Probe.CellView('vrng.Date', 16, '{a}..{b}');
        Probe.CellView('vor.Date', 16, '{a}|{b}');
        Probe.CellView('veq.Date', 16, '{a}');
        Probe.Expect('vgt.Date', 'VERSION(1) SORTING(No.) WHERE(FDate=FILTER(>2024-01-01)) | VERSION(1) SORTING(Field1) WHERE(Field16=1(>2024-01-01)) | >01/01/24 | 3,4');
        Probe.Expect('vne.Date', 'VERSION(1) SORTING(No.) WHERE(FDate=FILTER(<>2024-01-01)) | VERSION(1) SORTING(Field1) WHERE(Field16=1(<>2024-01-01)) | <>01/01/24 | 1,3,4');
        Probe.Expect('vrng.Date', 'VERSION(1) SORTING(No.) WHERE(FDate=FILTER(2024-01-01..2024-02-01)) | VERSION(1) SORTING(Field1) WHERE(Field16=1(2024-01-01..2024-02-01)) | 01/01/24..02/01/24 | 2,3');
        Probe.Expect('vor.Date', 'VERSION(1) SORTING(No.) WHERE(FDate=FILTER(2024-01-01|2024-02-01)) | VERSION(1) SORTING(Field1) WHERE(Field16=1(2024-01-01|2024-02-01)) | 01/01/24|02/01/24 | 2,3');
        Probe.Expect('veq.Date', 'VERSION(1) SORTING(No.) WHERE(FDate=FILTER(2024-01-01)) | VERSION(1) SORTING(Field1) WHERE(Field16=1(2024-01-01)) | 01/01/24 | 2');
        Probe.Verify();
    end;

    local procedure SeedTime()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FTime := 100000T;
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FTime := 110000T;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FTime := 120000T;
        R.Insert();
    end;

    [Test]
    procedure Filter_Time_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedTime();
        Probe.Cell('eq.Time', 17, '{a}');
        Probe.Cell('eqop.Time', 17, '={a}');
        Probe.Cell('ne.Time', 17, '<>{a}');
        Probe.Cell('lt.Time', 17, '<{a}');
        Probe.Cell('le.Time', 17, '<={a}');
        Probe.Cell('gt.Time', 17, '>{a}');
        Probe.Cell('ge.Time', 17, '>={a}');
        Probe.Expect('eq.Time', '10:00:00 AM | FTime: 10:00:00 AM | 2');
        Probe.Expect('eqop.Time', '10:00:00 AM | FTime: 10:00:00 AM | 2');
        Probe.Expect('ne.Time', '<>10:00:00 AM | FTime: <>10:00:00 AM | 1,3,4');
        Probe.Expect('lt.Time', '<10:00:00 AM | FTime: <10:00:00 AM | 1');
        Probe.Expect('le.Time', '<=10:00:00 AM | FTime: <=10:00:00 AM | 1,2');
        Probe.Expect('gt.Time', '>10:00:00 AM | FTime: >10:00:00 AM | 3,4');
        Probe.Expect('ge.Time', '>=10:00:00 AM | FTime: >=10:00:00 AM | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Time_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedTime();
        Probe.Cell('rng.Time', 17, '{a}..{b}');
        Probe.Cell('upto.Time', 17, '..{b}');
        Probe.Cell('from.Time', 17, '{a}..');
        Probe.Cell('or.Time', 17, '{a}|{b}');
        Probe.Cell('and.Time', 17, '>{a}&<{b}');
        Probe.Cell('ordinal.Time', 17, '{o}');
        Probe.Cell('neordinal.Time', 17, '<>{o}');
        Probe.Expect('rng.Time', '10:00:00 AM..11:00:00 AM | FTime: 10:00:00 AM..11:00:00 AM | 2,3');
        Probe.Expect('upto.Time', '..11:00:00 AM | FTime: ..11:00:00 AM | 1,2,3');
        Probe.Expect('from.Time', '10:00:00 AM.. | FTime: 10:00:00 AM.. | 2,3,4');
        Probe.Expect('or.Time', '10:00:00 AM|11:00:00 AM | FTime: 10:00:00 AM|11:00:00 AM | 2,3');
        Probe.Expect('and.Time', '>10:00:00 AM&<11:00:00 AM | FTime: >10:00:00 AM&<11:00:00 AM | ');
        Probe.Expect('ordinal.Time', 'E: The filter "100000T" is not valid for the FTime field on the LT FRM Row table. The value "100000T" can''t be evaluated into type Time.');
        Probe.Expect('neordinal.Time', 'E: The filter "<>100000T" is not valid for the FTime field on the LT FRM Row table. The value "100000T" can''t be evaluated into type Time.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Time_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedTime();
        Probe.Cell('star.Time', 17, '*');
        Probe.Cell('q.Time', 17, '?');
        Probe.Cell('at.Time', 17, '@{a}');
        Probe.Cell('prefix.Time', 17, '{a}*');
        Probe.Cell('nstar.Time', 17, '<>*');
        Probe.Cell('suffix.Time', 17, '*{a}');
        Probe.Expect('star.Time', 'E: The filter "*" is not valid for the FTime field on the LT FRM Row table. The value "*" can''t be evaluated into type Time.');
        Probe.Expect('q.Time', 'E: The filter "?" is not valid for the FTime field on the LT FRM Row table. The value "?" can''t be evaluated into type Time.');
        Probe.Expect('at.Time', 'E: The filter "@10:00:00 AM" is not valid for the FTime field on the LT FRM Row table. The value "@10:00:00 AM" can''t be evaluated into type Time.');
        Probe.Expect('prefix.Time', 'E: The filter "10:00:00 AM*" is not valid for the FTime field on the LT FRM Row table. The value "10:00:00 AM*" can''t be evaluated into type Time.');
        Probe.Expect('nstar.Time', 'E: The filter "<>*" is not valid for the FTime field on the LT FRM Row table. The value "*" can''t be evaluated into type Time.');
        Probe.Expect('suffix.Time', 'E: The filter "*10:00:00 AM" is not valid for the FTime field on the LT FRM Row table. The value "*10:00:00 AM" can''t be evaluated into type Time.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Time_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedTime();
        Probe.Cell('empty.Time', 17, '');
        Probe.Cell('quotes.Time', 17, '''''');
        Probe.Cell('nequotes.Time', 17, '<>''''');
        Probe.Cell('bare.Time', 17, '<>');
        Probe.Cell('unterm.Time', 17, '''');
        Probe.Cell('unterm2.Time', 17, '{a}''');
        Probe.Cell('quotedA.Time', 17, '''{a}''');
        Probe.Expect('empty.Time', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Time', ''''' | FTime: '''' | 1');
        Probe.Expect('nequotes.Time', '<>'''' | FTime: <>'''' | 2,3,4');
        Probe.Expect('bare.Time', 'E: The filter "<>" is not valid for the FTime field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Time', 'E: The filter "''" is not valid for the FTime field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Time', 'E: The filter "10:00:00 AM''" is not valid for the FTime field on the LT FRM Row table. The value "10:00:00 AM''" can''t be evaluated into type Time.');
        Probe.Expect('quotedA.Time', '10:00:00 AM | FTime: 10:00:00 AM | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Time_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedTime();
        Probe.CellArg('p1.Time', 17, '%1', 'a');
        Probe.CellArg('pne.Time', 17, '<>%1', 'a');
        Probe.CellArg('pge.Time', 17, '>=%1', 'a');
        Probe.CellArg('pstar.Time', 17, '%1', 'w');
        Probe.CellArg('pnestar.Time', 17, '<>%1', 'w');
        Probe.CellArg('pq.Time', 17, '%1', 'q');
        Probe.CellArg('pnq.Time', 17, '<>%1', 'q');
        Probe.Expect('p1.Time', '10:00:00 AM | FTime: 10:00:00 AM | 2');
        Probe.Expect('pne.Time', '<>10:00:00 AM | FTime: <>10:00:00 AM | 1,3,4');
        Probe.Expect('pge.Time', '>=10:00:00 AM | FTime: >=10:00:00 AM | 2,3,4');
#if BC28PLUS
        Probe.Expect('pstar.Time', 'E: The value "a*b?" can''t be evaluated into type Time.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Time', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Time', 'E: The value "a*b?" can''t be evaluated into type Time.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Time', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
#if BC28PLUS
        Probe.Expect('pq.Time', 'E: The value "?" can''t be evaluated into type Time.');
#else // BC 27.5 words this result differently
        Probe.Expect('pq.Time', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavChar to System.DateTime.');
#endif
#if BC28PLUS
        Probe.Expect('pnq.Time', 'E: The value "?" can''t be evaluated into type Time.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnq.Time', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavChar to System.DateTime.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Time_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedTime();
        Probe.CellRange('r1.Time', 17, 'r1');
        Probe.CellRange('r2.Time', 17, 'r2');
        Probe.CellRange('rtext.Time', 17, 'rt');
        Probe.Expect('r1.Time', '10:00:00 AM | FTime: 10:00:00 AM | 2');
        Probe.Expect('r2.Time', '10:00:00 AM | FTime: 10:00:00 AM | 2');
#if BC28PLUS
        Probe.Expect('rtext.Time', 'E: The value "10:00:00 AM" can''t be evaluated into type Time.');
#else // BC 27.5 words this result differently
        Probe.Expect('rtext.Time', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Time_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedTime();
        Probe.CellView('vgt.Time', 17, '>{a}');
        Probe.CellView('vne.Time', 17, '<>{a}');
        Probe.CellView('vrng.Time', 17, '{a}..{b}');
        Probe.CellView('vor.Time', 17, '{a}|{b}');
        Probe.CellView('veq.Time', 17, '{a}');
        Probe.Expect('vgt.Time', 'VERSION(1) SORTING(No.) WHERE(FTime=FILTER(>10:00:00)) | VERSION(1) SORTING(Field1) WHERE(Field17=1(>10:00:00)) | >10:00:00 AM | 3,4');
        Probe.Expect('vne.Time', 'VERSION(1) SORTING(No.) WHERE(FTime=FILTER(<>10:00:00)) | VERSION(1) SORTING(Field1) WHERE(Field17=1(<>10:00:00)) | <>10:00:00 AM | 1,3,4');
        Probe.Expect('vrng.Time', 'VERSION(1) SORTING(No.) WHERE(FTime=FILTER(10:00:00..11:00:00)) | VERSION(1) SORTING(Field1) WHERE(Field17=1(10:00:00..11:00:00)) | 10:00:00 AM..11:00:00 AM | 2,3');
        Probe.Expect('vor.Time', 'VERSION(1) SORTING(No.) WHERE(FTime=FILTER(10:00:00|11:00:00)) | VERSION(1) SORTING(Field1) WHERE(Field17=1(10:00:00|11:00:00)) | 10:00:00 AM|11:00:00 AM | 2,3');
        Probe.Expect('veq.Time', 'VERSION(1) SORTING(No.) WHERE(FTime=FILTER(10:00:00)) | VERSION(1) SORTING(Field1) WHERE(Field17=1(10:00:00)) | 10:00:00 AM | 2');
        Probe.Verify();
    end;

    local procedure SeedDateTime()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FDateTime := CreateDateTime(20240101D, 100000T);
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FDateTime := CreateDateTime(20240201D, 110000T);
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FDateTime := CreateDateTime(20240301D, 120000T);
        R.Insert();
    end;

    [Test]
    procedure Filter_DateTime_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDateTime();
        Probe.Cell('eq.DateTime', 18, '{a}');
        Probe.Cell('eqop.DateTime', 18, '={a}');
        Probe.Cell('ne.DateTime', 18, '<>{a}');
        Probe.Cell('lt.DateTime', 18, '<{a}');
        Probe.Cell('le.DateTime', 18, '<={a}');
        Probe.Cell('gt.DateTime', 18, '>{a}');
        Probe.Cell('ge.DateTime', 18, '>={a}');
        Probe.Expect('eq.DateTime', '01/01/24 10:00 AM | FDateTime: 01/01/24 10:00 AM | 2');
        Probe.Expect('eqop.DateTime', '01/01/24 10:00 AM | FDateTime: 01/01/24 10:00 AM | 2');
        Probe.Expect('ne.DateTime', '<>01/01/24 10:00 AM | FDateTime: <>01/01/24 10:00 AM | 1,3,4');
        Probe.Expect('lt.DateTime', '<01/01/24 10:00 AM | FDateTime: <01/01/24 10:00 AM | 1');
        Probe.Expect('le.DateTime', '<=01/01/24 10:00 AM | FDateTime: <=01/01/24 10:00 AM | 1,2');
        Probe.Expect('gt.DateTime', '>01/01/24 10:00 AM | FDateTime: >01/01/24 10:00 AM | 3,4');
        Probe.Expect('ge.DateTime', '>=01/01/24 10:00 AM | FDateTime: >=01/01/24 10:00 AM | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_DateTime_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDateTime();
        Probe.Cell('rng.DateTime', 18, '{a}..{b}');
        Probe.Cell('upto.DateTime', 18, '..{b}');
        Probe.Cell('from.DateTime', 18, '{a}..');
        Probe.Cell('or.DateTime', 18, '{a}|{b}');
        Probe.Cell('and.DateTime', 18, '>{a}&<{b}');
        Probe.Cell('ordinal.DateTime', 18, '{o}');
        Probe.Cell('neordinal.DateTime', 18, '<>{o}');
        Probe.Expect('rng.DateTime', '01/01/24 10:00 AM..02/01/24 11:00 AM | FDateTime: 01/01/24 10:00 AM..02/01/24 11:00 AM | 2,3');
        Probe.Expect('upto.DateTime', '..02/01/24 11:00 AM | FDateTime: ..02/01/24 11:00 AM | 1,2,3');
        Probe.Expect('from.DateTime', '01/01/24 10:00 AM.. | FDateTime: 01/01/24 10:00 AM.. | 2,3,4');
        Probe.Expect('or.DateTime', '01/01/24 10:00 AM|02/01/24 11:00 AM | FDateTime: 01/01/24 10:00 AM|02/01/24 11:00 AM | 2,3');
        Probe.Expect('and.DateTime', '>01/01/24 10:00 AM&<02/01/24 11:00 AM | FDateTime: >01/01/24 10:00 AM&<02/01/24 11:00 AM | ');
        Probe.Expect('ordinal.DateTime', '01/01/24 10:00 AM | FDateTime: 01/01/24 10:00 AM | 2');
        Probe.Expect('neordinal.DateTime', '<>01/01/24 10:00 AM | FDateTime: <>01/01/24 10:00 AM | 1,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_DateTime_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDateTime();
        Probe.Cell('star.DateTime', 18, '*');
        Probe.Cell('q.DateTime', 18, '?');
        Probe.Cell('at.DateTime', 18, '@{a}');
        Probe.Cell('prefix.DateTime', 18, '{a}*');
        Probe.Cell('nstar.DateTime', 18, '<>*');
        Probe.Cell('suffix.DateTime', 18, '*{a}');
        Probe.Expect('star.DateTime', 'E: The filter "*" is not valid for the FDateTime field on the LT FRM Row table. The value "*" can''t be evaluated into type DateTime.');
        Probe.Expect('q.DateTime', 'E: The filter "?" is not valid for the FDateTime field on the LT FRM Row table. The value "?" can''t be evaluated into type DateTime.');
        Probe.Expect('at.DateTime', 'E: The filter "@01/01/24 10:00 AM" is not valid for the FDateTime field on the LT FRM Row table. The value "@01/01/24 10:00 AM" can''t be evaluated into type DateTime.');
        Probe.Expect('prefix.DateTime', 'E: The filter "01/01/24 10:00 AM*" is not valid for the FDateTime field on the LT FRM Row table. The value "01/01/24 10:00 AM*" can''t be evaluated into type DateTime.');
        Probe.Expect('nstar.DateTime', 'E: The filter "<>*" is not valid for the FDateTime field on the LT FRM Row table. The value "*" can''t be evaluated into type DateTime.');
        Probe.Expect('suffix.DateTime', 'E: The filter "*01/01/24 10:00 AM" is not valid for the FDateTime field on the LT FRM Row table. The value "*01/01/24 10:00 AM" can''t be evaluated into type DateTime.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_DateTime_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDateTime();
        Probe.Cell('empty.DateTime', 18, '');
        Probe.Cell('quotes.DateTime', 18, '''''');
        Probe.Cell('nequotes.DateTime', 18, '<>''''');
        Probe.Cell('bare.DateTime', 18, '<>');
        Probe.Cell('unterm.DateTime', 18, '''');
        Probe.Cell('unterm2.DateTime', 18, '{a}''');
        Probe.Cell('quotedA.DateTime', 18, '''{a}''');
        Probe.Expect('empty.DateTime', ' |  | 1,2,3,4');
        Probe.Expect('quotes.DateTime', '''''..'''' | FDateTime: ''''..'''' | 1');
        Probe.Expect('nequotes.DateTime', '<>'''' | FDateTime: <>'''' | 2,3,4');
        Probe.Expect('bare.DateTime', 'E: The filter "<>" is not valid for the FDateTime field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.DateTime', 'E: The filter "''" is not valid for the FDateTime field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.DateTime', 'E: The filter "01/01/24 10:00 AM''" is not valid for the FDateTime field on the LT FRM Row table. The value "01/01/24 10:00 AM''" can''t be evaluated into type DateTime.');
        Probe.Expect('quotedA.DateTime', '01/01/24 10:00 AM | FDateTime: 01/01/24 10:00 AM | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_DateTime_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDateTime();
        Probe.CellArg('p1.DateTime', 18, '%1', 'a');
        Probe.CellArg('pne.DateTime', 18, '<>%1', 'a');
        Probe.CellArg('pge.DateTime', 18, '>=%1', 'a');
        Probe.CellArg('pstar.DateTime', 18, '%1', 'w');
        Probe.CellArg('pnestar.DateTime', 18, '<>%1', 'w');
        Probe.CellArg('pq.DateTime', 18, '%1', 'q');
        Probe.CellArg('pnq.DateTime', 18, '<>%1', 'q');
        Probe.Expect('p1.DateTime', '01/01/24 10:00 AM | FDateTime: 01/01/24 10:00 AM | 2');
        Probe.Expect('pne.DateTime', '<>01/01/24 10:00 AM | FDateTime: <>01/01/24 10:00 AM | 1,3,4');
        Probe.Expect('pge.DateTime', '>=01/01/24 10:00 AM | FDateTime: >=01/01/24 10:00 AM | 2,3,4');
#if BC28PLUS
        Probe.Expect('pstar.DateTime', 'E: The value "a*b?" can''t be evaluated into type DateTime.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.DateTime', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.DateTime', 'E: The value "a*b?" can''t be evaluated into type DateTime.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.DateTime', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
#if BC28PLUS
        Probe.Expect('pq.DateTime', 'E: The value "?" can''t be evaluated into type DateTime.');
#else // BC 27.5 words this result differently
        Probe.Expect('pq.DateTime', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavChar to System.DateTime.');
#endif
#if BC28PLUS
        Probe.Expect('pnq.DateTime', 'E: The value "?" can''t be evaluated into type DateTime.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnq.DateTime', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavChar to System.DateTime.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_DateTime_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDateTime();
        Probe.CellRange('r1.DateTime', 18, 'r1');
        Probe.CellRange('r2.DateTime', 18, 'r2');
        Probe.CellRange('rtext.DateTime', 18, 'rt');
        Probe.Expect('r1.DateTime', '01/01/24 10:00 AM | FDateTime: 01/01/24 10:00 AM | 2');
        Probe.Expect('r2.DateTime', '01/01/24 10:00 AM | FDateTime: 01/01/24 10:00 AM | 2');
#if BC28PLUS
        Probe.Expect('rtext.DateTime', 'E: The value "01/01/24 10:00 AM" can''t be evaluated into type DateTime.');
#else // BC 27.5 words this result differently
        Probe.Expect('rtext.DateTime', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_DateTime_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDateTime();
        Probe.CellView('vgt.DateTime', 18, '>{a}');
        Probe.CellView('vne.DateTime', 18, '<>{a}');
        Probe.CellView('vrng.DateTime', 18, '{a}..{b}');
        Probe.CellView('vor.DateTime', 18, '{a}|{b}');
        Probe.CellView('veq.DateTime', 18, '{a}');
        Probe.Expect('vgt.DateTime', 'VERSION(1) SORTING(No.) WHERE(FDateTime=FILTER(>2024-01-01T10:00:00Z)) | VERSION(1) SORTING(Field1) WHERE(Field18=1(>2024-01-01T10:00:00Z)) | >01/01/24 10:00 AM | 3,4');
        Probe.Expect('vne.DateTime', 'VERSION(1) SORTING(No.) WHERE(FDateTime=FILTER(<>2024-01-01T10:00:00Z)) | VERSION(1) SORTING(Field1) WHERE(Field18=1(<>2024-01-01T10:00:00Z)) | <>01/01/24 10:00 AM | 1,3,4');
        Probe.Expect('vrng.DateTime', 'VERSION(1) SORTING(No.) WHERE(FDateTime=FILTER(2024-01-01T10:00:00Z..2024-02-01T11:00:00Z)) | VERSION(1) SORTING(Field1) WHERE(Field18=1(2024-01-01T10:00:00Z..2024-02-01T11:00:00Z)) | 01/01/24 10:00 AM..02/01/24 11:00 AM | 2,3');
        Probe.Expect('vor.DateTime', 'VERSION(1) SORTING(No.) WHERE(FDateTime=FILTER(2024-01-01T10:00:00Z|2024-02-01T11:00:00Z)) | VERSION(1) SORTING(Field1) WHERE(Field18=1(2024-01-01T10:00:00Z|2024-02-01T11:00:00Z)) | 01/01/24 10:00 AM|02/01/24 11:00 AM | 2,3');
        Probe.Expect('veq.DateTime', 'VERSION(1) SORTING(No.) WHERE(FDateTime=FILTER(2024-01-01T10:00:00Z)) | VERSION(1) SORTING(Field1) WHERE(Field18=1(2024-01-01T10:00:00Z)) | 01/01/24 10:00 AM | 2');
        Probe.Verify();
    end;

    local procedure SeedDf()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        Evaluate(R.FDf, '<1D>');
        R.Insert();
        R.Init();
        R."No." := 3;
        Evaluate(R.FDf, '<2D>');
        R.Insert();
        R.Init();
        R."No." := 4;
        Evaluate(R.FDf, '<3D>');
        R.Insert();
    end;

    [Test]
    procedure Filter_Df_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDf();
        Probe.Cell('eq.Df', 19, '{a}');
        Probe.Cell('eqop.Df', 19, '={a}');
        Probe.Cell('ne.Df', 19, '<>{a}');
        Probe.Cell('lt.Df', 19, '<{a}');
        Probe.Cell('le.Df', 19, '<={a}');
        Probe.Cell('gt.Df', 19, '>{a}');
        Probe.Cell('ge.Df', 19, '>={a}');
        Probe.Expect('eq.Df', '1D | FDf: 1D | 2');
        Probe.Expect('eqop.Df', '1D | FDf: 1D | 2');
        Probe.Expect('ne.Df', '<>1D | FDf: <>1D | 1,3,4');
        Probe.Expect('lt.Df', '<1D | FDf: <1D | 1');
        Probe.Expect('le.Df', '<=1D | FDf: <=1D | 1,2');
        Probe.Expect('gt.Df', '>1D | FDf: >1D | 3,4');
        Probe.Expect('ge.Df', '>=1D | FDf: >=1D | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Df_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDf();
        Probe.Cell('rng.Df', 19, '{a}..{b}');
        Probe.Cell('upto.Df', 19, '..{b}');
        Probe.Cell('from.Df', 19, '{a}..');
        Probe.Cell('or.Df', 19, '{a}|{b}');
        Probe.Cell('and.Df', 19, '>{a}&<{b}');
        Probe.Cell('ordinal.Df', 19, '{o}');
        Probe.Cell('neordinal.Df', 19, '<>{o}');
        Probe.Expect('rng.Df', '1D..2D | FDf: 1D..2D | 2,3');
        Probe.Expect('upto.Df', '..2D | FDf: ..2D | 1,2,3');
        Probe.Expect('from.Df', '1D.. | FDf: 1D.. | 2,3,4');
        Probe.Expect('or.Df', '1D|2D | FDf: 1D|2D | 2,3');
        Probe.Expect('and.Df', '>1D&<2D | FDf: >1D&<2D | ');
        Probe.Expect('ordinal.Df', 'E: The filter "<1D>" is not valid for the FDf field on the LT FRM Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Probe.Expect('neordinal.Df', 'E: The filter "<><1D>" is not valid for the FDf field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Df_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDf();
        Probe.Cell('star.Df', 19, '*');
        Probe.Cell('q.Df', 19, '?');
        Probe.Cell('at.Df', 19, '@{a}');
        Probe.Cell('prefix.Df', 19, '{a}*');
        Probe.Cell('nstar.Df', 19, '<>*');
        Probe.Cell('suffix.Df', 19, '*{a}');
        Probe.Expect('star.Df', ''''' | FDf: '''' | 1');
        Probe.Expect('q.Df', ''''' | FDf: '''' | 1');
        Probe.Expect('at.Df', '1D | FDf: 1D | 2');
        Probe.Expect('prefix.Df', '1D | FDf: 1D | 2');
        Probe.Expect('nstar.Df', '<>'''' | FDf: <>'''' | 2,3,4');
        Probe.Expect('suffix.Df', '1D | FDf: 1D | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Df_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDf();
        Probe.Cell('empty.Df', 19, '');
        Probe.Cell('quotes.Df', 19, '''''');
        Probe.Cell('nequotes.Df', 19, '<>''''');
        Probe.Cell('bare.Df', 19, '<>');
        Probe.Cell('unterm.Df', 19, '''');
        Probe.Cell('unterm2.Df', 19, '{a}''');
        Probe.Cell('quotedA.Df', 19, '''{a}''');
        Probe.Expect('empty.Df', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Df', ''''' | FDf: '''' | 1');
        Probe.Expect('nequotes.Df', '<>'''' | FDf: <>'''' | 2,3,4');
        Probe.Expect('bare.Df', 'E: The filter "<>" is not valid for the FDf field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Df', 'E: The filter "''" is not valid for the FDf field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Df', '1D | FDf: 1D | 2');
        Probe.Expect('quotedA.Df', '1D | FDf: 1D | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Df_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDf();
        Probe.CellArg('p1.Df', 19, '%1', 'a');
        Probe.CellArg('pne.Df', 19, '<>%1', 'a');
        Probe.CellArg('pge.Df', 19, '>=%1', 'a');
        Probe.CellArg('pstar.Df', 19, '%1', 'w');
        Probe.CellArg('pnestar.Df', 19, '<>%1', 'w');
        Probe.CellArg('pq.Df', 19, '%1', 'q');
        Probe.CellArg('pnq.Df', 19, '<>%1', 'q');
        Probe.Expect('p1.Df', '1D | FDf: 1D | 2');
        Probe.Expect('pne.Df', '<>1D | FDf: <>1D | 1,3,4');
        Probe.Expect('pge.Df', '>=1D | FDf: >=1D | 2,3,4');
        Probe.Expect('pstar.Df', 'a | FDf: a | ');
        Probe.Expect('pnestar.Df', '<>a | FDf: <>a | 1,2,3,4');
        Probe.Expect('pq.Df', '? | FDf: ? | ');
        Probe.Expect('pnq.Df', '<>? | FDf: <>? | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Df_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDf();
        Probe.CellRange('r1.Df', 19, 'r1');
        Probe.CellRange('r2.Df', 19, 'r2');
        Probe.CellRange('rtext.Df', 19, 'rt');
        Probe.Expect('r1.Df', '1D | FDf: 1D | 2');
        Probe.Expect('r2.Df', '1D | FDf: 1D | 2');
        Probe.Expect('rtext.Df', '1 | FDf: 1 | ');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Df_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedDf();
        Probe.CellView('vgt.Df', 19, '>{a}');
        Probe.CellView('vne.Df', 19, '<>{a}');
        Probe.CellView('vrng.Df', 19, '{a}..{b}');
        Probe.CellView('vor.Df', 19, '{a}|{b}');
        Probe.CellView('veq.Df', 19, '{a}');
        Probe.Expect('vgt.Df', 'VERSION(1) SORTING(No.) WHERE(FDf=FILTER(>1D)) | VERSION(1) SORTING(Field1) WHERE(Field19=1(>1D)) | >1D | 3,4');
        Probe.Expect('vne.Df', 'VERSION(1) SORTING(No.) WHERE(FDf=FILTER(<>1D)) | VERSION(1) SORTING(Field1) WHERE(Field19=1(<>1D)) | <>1D | 1,3,4');
        Probe.Expect('vrng.Df', 'VERSION(1) SORTING(No.) WHERE(FDf=FILTER(1D..2D)) | VERSION(1) SORTING(Field1) WHERE(Field19=1(1D..2D)) | 1D..2D | 2,3');
        Probe.Expect('vor.Df', 'VERSION(1) SORTING(No.) WHERE(FDf=FILTER(1D|2D)) | VERSION(1) SORTING(Field1) WHERE(Field19=1(1D|2D)) | 1D|2D | 2,3');
        Probe.Expect('veq.Df', 'VERSION(1) SORTING(No.) WHERE(FDf=FILTER(1D)) | VERSION(1) SORTING(Field1) WHERE(Field19=1(1D)) | 1D | 2');
        Probe.Verify();
    end;

}

codeunit 70047 "LT FRM Scalar Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedBool()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FBool := false;
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FBool := true;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FBool := true;
        R.Insert();
    end;

    [Test]
    procedure Filter_Bool_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBool();
        Probe.Cell('eq.Bool', 20, '{a}');
        Probe.Cell('eqop.Bool', 20, '={a}');
        Probe.Cell('ne.Bool', 20, '<>{a}');
        Probe.Cell('lt.Bool', 20, '<{a}');
        Probe.Cell('le.Bool', 20, '<={a}');
        Probe.Cell('gt.Bool', 20, '>{a}');
        Probe.Cell('ge.Bool', 20, '>={a}');
        Probe.Expect('eq.Bool', 'No | FBool: No | 1,2');
        Probe.Expect('eqop.Bool', 'No | FBool: No | 1,2');
        Probe.Expect('ne.Bool', '<>No | FBool: <>No | 3,4');
        Probe.Expect('lt.Bool', '<No | FBool: <No | ');
        Probe.Expect('le.Bool', '<=No | FBool: <=No | 1,2');
        Probe.Expect('gt.Bool', '>No | FBool: >No | 3,4');
        Probe.Expect('ge.Bool', '>=No | FBool: >=No | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Bool_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBool();
        Probe.Cell('rng.Bool', 20, '{a}..{b}');
        Probe.Cell('upto.Bool', 20, '..{b}');
        Probe.Cell('from.Bool', 20, '{a}..');
        Probe.Cell('or.Bool', 20, '{a}|{b}');
        Probe.Cell('and.Bool', 20, '>{a}&<{b}');
        Probe.Cell('ordinal.Bool', 20, '{o}');
        Probe.Cell('neordinal.Bool', 20, '<>{o}');
        Probe.Expect('rng.Bool', 'No..Yes | FBool: No..Yes | 1,2,3,4');
        Probe.Expect('upto.Bool', '..Yes | FBool: ..Yes | 1,2,3,4');
        Probe.Expect('from.Bool', 'No.. | FBool: No.. | 1,2,3,4');
        Probe.Expect('or.Bool', 'No|Yes | FBool: No|Yes | 1,2,3,4');
        Probe.Expect('and.Bool', '>No&<Yes | FBool: >No&<Yes | ');
        Probe.Expect('ordinal.Bool', 'No | FBool: No | 1,2');
        Probe.Expect('neordinal.Bool', '<>No | FBool: <>No | 3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Bool_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBool();
        Probe.Cell('star.Bool', 20, '*');
        Probe.Cell('q.Bool', 20, '?');
        Probe.Cell('at.Bool', 20, '@{a}');
        Probe.Cell('prefix.Bool', 20, '{a}*');
        Probe.Cell('nstar.Bool', 20, '<>*');
        Probe.Cell('suffix.Bool', 20, '*{a}');
        Probe.Expect('star.Bool', 'E: The filter "*" is not valid for the FBool field on the LT FRM Row table. The value "*" can''t be evaluated into type Boolean.');
        Probe.Expect('q.Bool', 'E: The filter "?" is not valid for the FBool field on the LT FRM Row table. The value "?" can''t be evaluated into type Boolean.');
        Probe.Expect('at.Bool', 'E: The filter "@No" is not valid for the FBool field on the LT FRM Row table. The value "@No" can''t be evaluated into type Boolean.');
        Probe.Expect('prefix.Bool', 'E: The filter "No*" is not valid for the FBool field on the LT FRM Row table. The value "No*" can''t be evaluated into type Boolean.');
        Probe.Expect('nstar.Bool', 'E: The filter "<>*" is not valid for the FBool field on the LT FRM Row table. The value "*" can''t be evaluated into type Boolean.');
        Probe.Expect('suffix.Bool', 'E: The filter "*No" is not valid for the FBool field on the LT FRM Row table. The value "*No" can''t be evaluated into type Boolean.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Bool_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBool();
        Probe.Cell('empty.Bool', 20, '');
        Probe.Cell('quotes.Bool', 20, '''''');
        Probe.Cell('nequotes.Bool', 20, '<>''''');
        Probe.Cell('bare.Bool', 20, '<>');
        Probe.Cell('unterm.Bool', 20, '''');
        Probe.Cell('unterm2.Bool', 20, '{a}''');
        Probe.Cell('quotedA.Bool', 20, '''{a}''');
        Probe.Expect('empty.Bool', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Bool', 'E: The filter "''''" is not valid for the FBool field on the LT FRM Row table. The value "" can''t be evaluated into type Boolean.');
        Probe.Expect('nequotes.Bool', 'E: The filter "<>''''" is not valid for the FBool field on the LT FRM Row table. The value "" can''t be evaluated into type Boolean.');
        Probe.Expect('bare.Bool', 'E: The filter "<>" is not valid for the FBool field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Bool', 'E: The filter "''" is not valid for the FBool field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Bool', 'E: The filter "No''" is not valid for the FBool field on the LT FRM Row table. The value "No''" can''t be evaluated into type Boolean.');
        Probe.Expect('quotedA.Bool', 'No | FBool: No | 1,2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Bool_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBool();
        Probe.CellArg('p1.Bool', 20, '%1', 'a');
        Probe.CellArg('pne.Bool', 20, '<>%1', 'a');
        Probe.CellArg('pge.Bool', 20, '>=%1', 'a');
        Probe.CellArg('pstar.Bool', 20, '%1', 'w');
        Probe.CellArg('pnestar.Bool', 20, '<>%1', 'w');
        Probe.CellArg('pq.Bool', 20, '%1', 'q');
        Probe.CellArg('pnq.Bool', 20, '<>%1', 'q');
        Probe.Expect('p1.Bool', 'No | FBool: No | 1,2');
        Probe.Expect('pne.Bool', '<>No | FBool: <>No | 3,4');
        Probe.Expect('pge.Bool', '>=No | FBool: >=No | 1,2,3,4');
#if BC28PLUS
        Probe.Expect('pstar.Bool', 'E: The value "a*b?" can''t be evaluated into type Boolean.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Bool', 'E: The type NavBoolean is unknown.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Bool', 'E: The value "a*b?" can''t be evaluated into type Boolean.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Bool', 'E: The type NavBoolean is unknown.');
#endif
        Probe.Expect('pq.Bool', 'Yes | FBool: Yes | 3,4');
        Probe.Expect('pnq.Bool', '<>Yes | FBool: <>Yes | 1,2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Bool_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBool();
        Probe.CellRange('r1.Bool', 20, 'r1');
        Probe.CellRange('r2.Bool', 20, 'r2');
        Probe.CellRange('rtext.Bool', 20, 'rt');
        Probe.Expect('r1.Bool', 'No | FBool: No | 1,2');
        Probe.Expect('r2.Bool', 'No | FBool: No | 1,2');
#if BC28PLUS
        Probe.Expect('rtext.Bool', 'E: The value "No" can''t be evaluated into type Boolean.');
#else // BC 27.5 words this result differently
        Probe.Expect('rtext.Bool', 'E: The type NavBoolean is unknown.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Bool_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBool();
        Probe.CellView('vgt.Bool', 20, '>{a}');
        Probe.CellView('vne.Bool', 20, '<>{a}');
        Probe.CellView('vrng.Bool', 20, '{a}..{b}');
        Probe.CellView('vor.Bool', 20, '{a}|{b}');
        Probe.CellView('veq.Bool', 20, '{a}');
        Probe.Expect('vgt.Bool', 'VERSION(1) SORTING(No.) WHERE(FBool=FILTER(>false)) | VERSION(1) SORTING(Field1) WHERE(Field20=1(>0)) | >No | 3,4');
        Probe.Expect('vne.Bool', 'VERSION(1) SORTING(No.) WHERE(FBool=FILTER(<>false)) | VERSION(1) SORTING(Field1) WHERE(Field20=1(<>0)) | <>No | 3,4');
        Probe.Expect('vrng.Bool', 'VERSION(1) SORTING(No.) WHERE(FBool=FILTER(false..true)) | VERSION(1) SORTING(Field1) WHERE(Field20=1(0..1)) | No..Yes | 1,2,3,4');
        Probe.Expect('vor.Bool', 'VERSION(1) SORTING(No.) WHERE(FBool=FILTER(false|true)) | VERSION(1) SORTING(Field1) WHERE(Field20=1(0|1)) | No|Yes | 1,2,3,4');
        Probe.Expect('veq.Bool', 'VERSION(1) SORTING(No.) WHERE(FBool=FILTER(false)) | VERSION(1) SORTING(Field1) WHERE(Field20=1(0)) | No | 1,2');
        Probe.Verify();
    end;

    local procedure SeedOpt()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FOpt := R.FOpt::Alpha;
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FOpt := R.FOpt::Beta;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FOpt := R.FOpt::Gamma;
        R.Insert();
    end;

    [Test]
    procedure Filter_Opt_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedOpt();
        Probe.Cell('eq.Opt', 21, '{a}');
        Probe.Cell('eqop.Opt', 21, '={a}');
        Probe.Cell('ne.Opt', 21, '<>{a}');
        Probe.Cell('lt.Opt', 21, '<{a}');
        Probe.Cell('le.Opt', 21, '<={a}');
        Probe.Cell('gt.Opt', 21, '>{a}');
        Probe.Cell('ge.Opt', 21, '>={a}');
        Probe.Expect('eq.Opt', 'Alpha | FOpt: Alpha | 1,2');
        Probe.Expect('eqop.Opt', 'Alpha | FOpt: Alpha | 1,2');
        Probe.Expect('ne.Opt', '<>Alpha | FOpt: <>Alpha | 3,4');
        Probe.Expect('lt.Opt', '<Alpha | FOpt: <Alpha | ');
        Probe.Expect('le.Opt', '<=Alpha | FOpt: <=Alpha | 1,2');
        Probe.Expect('gt.Opt', '>Alpha | FOpt: >Alpha | 3,4');
        Probe.Expect('ge.Opt', '>=Alpha | FOpt: >=Alpha | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Opt_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedOpt();
        Probe.Cell('rng.Opt', 21, '{a}..{b}');
        Probe.Cell('upto.Opt', 21, '..{b}');
        Probe.Cell('from.Opt', 21, '{a}..');
        Probe.Cell('or.Opt', 21, '{a}|{b}');
        Probe.Cell('and.Opt', 21, '>{a}&<{b}');
        Probe.Cell('ordinal.Opt', 21, '{o}');
        Probe.Cell('neordinal.Opt', 21, '<>{o}');
        Probe.Expect('rng.Opt', 'Alpha..Beta | FOpt: Alpha..Beta | 1,2,3');
        Probe.Expect('upto.Opt', '..Beta | FOpt: ..Beta | 1,2,3');
        Probe.Expect('from.Opt', 'Alpha.. | FOpt: Alpha.. | 1,2,3,4');
        Probe.Expect('or.Opt', 'Alpha|Beta | FOpt: Alpha|Beta | 1,2,3');
        Probe.Expect('and.Opt', '>Alpha&<Beta | FOpt: >Alpha&<Beta | ');
        Probe.Expect('ordinal.Opt', 'Alpha | FOpt: Alpha | 1,2');
        Probe.Expect('neordinal.Opt', '<>Alpha | FOpt: <>Alpha | 3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Opt_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedOpt();
        Probe.Cell('star.Opt', 21, '*');
        Probe.Cell('q.Opt', 21, '?');
        Probe.Cell('at.Opt', 21, '@{a}');
        Probe.Cell('prefix.Opt', 21, '{a}*');
        Probe.Cell('nstar.Opt', 21, '<>*');
        Probe.Cell('suffix.Opt', 21, '*{a}');
        Probe.Expect('star.Opt', 'E: The filter "*" is not valid for the FOpt field on the LT FRM Row table. ''*'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('q.Opt', 'E: The filter "?" is not valid for the FOpt field on the LT FRM Row table. ''?'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('at.Opt', 'E: The filter "@Alpha" is not valid for the FOpt field on the LT FRM Row table. ''@Alpha'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('prefix.Opt', 'E: The filter "Alpha*" is not valid for the FOpt field on the LT FRM Row table. ''Alpha*'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('nstar.Opt', 'E: The filter "<>*" is not valid for the FOpt field on the LT FRM Row table. ''*'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('suffix.Opt', 'E: The filter "*Alpha" is not valid for the FOpt field on the LT FRM Row table. ''*Alpha'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Opt_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedOpt();
        Probe.Cell('empty.Opt', 21, '');
        Probe.Cell('quotes.Opt', 21, '''''');
        Probe.Cell('nequotes.Opt', 21, '<>''''');
        Probe.Cell('bare.Opt', 21, '<>');
        Probe.Cell('unterm.Opt', 21, '''');
        Probe.Cell('unterm2.Opt', 21, '{a}''');
        Probe.Cell('quotedA.Opt', 21, '''{a}''');
        Probe.Expect('empty.Opt', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Opt', 'E: The filter "''''" is not valid for the FOpt field on the LT FRM Row table. '''' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('nequotes.Opt', 'E: The filter "<>''''" is not valid for the FOpt field on the LT FRM Row table. '''' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('bare.Opt', 'E: The filter "<>" is not valid for the FOpt field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Opt', 'E: The filter "''" is not valid for the FOpt field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Opt', 'E: The filter "Alpha''" is not valid for the FOpt field on the LT FRM Row table. ''Alpha'''' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('quotedA.Opt', 'Alpha | FOpt: Alpha | 1,2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Opt_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedOpt();
        Probe.CellArg('p1.Opt', 21, '%1', 'a');
        Probe.CellArg('pne.Opt', 21, '<>%1', 'a');
        Probe.CellArg('pge.Opt', 21, '>=%1', 'a');
        Probe.CellArg('pstar.Opt', 21, '%1', 'w');
        Probe.CellArg('pnestar.Opt', 21, '<>%1', 'w');
        Probe.CellArg('pq.Opt', 21, '%1', 'q');
        Probe.CellArg('pnq.Opt', 21, '<>%1', 'q');
        Probe.Expect('p1.Opt', 'Alpha | FOpt: Alpha | 1,2');
        Probe.Expect('pne.Opt', '<>Alpha | FOpt: <>Alpha | 3,4');
        Probe.Expect('pge.Opt', '>=Alpha | FOpt: >=Alpha | 1,2,3,4');
#if BC28PLUS
        Probe.Expect('pstar.Opt', 'E: The value "a*b?" can''t be evaluated into type Option.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Opt', 'E: The type NavOption is unknown.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Opt', 'E: The value "a*b?" can''t be evaluated into type Option.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Opt', 'E: The type NavOption is unknown.');
#endif
        Probe.Expect('pq.Opt', '63 | FOpt: 63 | ');
        Probe.Expect('pnq.Opt', '<>63 | FOpt: <>63 | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Opt_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedOpt();
        Probe.CellRange('r1.Opt', 21, 'r1');
        Probe.CellRange('r2.Opt', 21, 'r2');
        Probe.CellRange('rtext.Opt', 21, 'rt');
        Probe.Expect('r1.Opt', 'Alpha | FOpt: Alpha | 1,2');
        Probe.Expect('r2.Opt', 'Alpha | FOpt: Alpha | 1,2');
#if BC28PLUS
        Probe.Expect('rtext.Opt', 'E: The value "Alpha" can''t be evaluated into type Option.');
#else // BC 27.5 words this result differently
        Probe.Expect('rtext.Opt', 'E: The type NavOption is unknown.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Opt_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedOpt();
        Probe.CellView('vgt.Opt', 21, '>{a}');
        Probe.CellView('vne.Opt', 21, '<>{a}');
        Probe.CellView('vrng.Opt', 21, '{a}..{b}');
        Probe.CellView('vor.Opt', 21, '{a}|{b}');
        Probe.CellView('veq.Opt', 21, '{a}');
        Probe.Expect('vgt.Opt', 'VERSION(1) SORTING(No.) WHERE(FOpt=FILTER(>Alpha)) | VERSION(1) SORTING(Field1) WHERE(Field21=1(>0)) | >Alpha | 3,4');
        Probe.Expect('vne.Opt', 'VERSION(1) SORTING(No.) WHERE(FOpt=FILTER(<>Alpha)) | VERSION(1) SORTING(Field1) WHERE(Field21=1(<>0)) | <>Alpha | 3,4');
        Probe.Expect('vrng.Opt', 'VERSION(1) SORTING(No.) WHERE(FOpt=FILTER(Alpha..Beta)) | VERSION(1) SORTING(Field1) WHERE(Field21=1(0..1)) | Alpha..Beta | 1,2,3');
        Probe.Expect('vor.Opt', 'VERSION(1) SORTING(No.) WHERE(FOpt=FILTER(Alpha|Beta)) | VERSION(1) SORTING(Field1) WHERE(Field21=1(0|1)) | Alpha|Beta | 1,2,3');
        Probe.Expect('veq.Opt', 'VERSION(1) SORTING(No.) WHERE(FOpt=FILTER(Alpha)) | VERSION(1) SORTING(Field1) WHERE(Field21=1(0)) | Alpha | 1,2');
        Probe.Verify();
    end;

    local procedure SeedEnum()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FEnum := R.FEnum::Alpha;
        R.Insert();
        R.Init();
        R."No." := 3;
        R.FEnum := R.FEnum::Beta;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.FEnum := R.FEnum::Gamma;
        R.Insert();
    end;

    [Test]
    procedure Filter_Enum_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedEnum();
        Probe.Cell('eq.Enum', 22, '{a}');
        Probe.Cell('eqop.Enum', 22, '={a}');
        Probe.Cell('ne.Enum', 22, '<>{a}');
        Probe.Cell('lt.Enum', 22, '<{a}');
        Probe.Cell('le.Enum', 22, '<={a}');
        Probe.Cell('gt.Enum', 22, '>{a}');
        Probe.Cell('ge.Enum', 22, '>={a}');
        Probe.Expect('eq.Enum', 'Alpha | FEnum: Alpha | 1,2');
        Probe.Expect('eqop.Enum', 'Alpha | FEnum: Alpha | 1,2');
        Probe.Expect('ne.Enum', '<>Alpha | FEnum: <>Alpha | 3,4');
        Probe.Expect('lt.Enum', '<Alpha | FEnum: <Alpha | ');
        Probe.Expect('le.Enum', '<=Alpha | FEnum: <=Alpha | 1,2');
        Probe.Expect('gt.Enum', '>Alpha | FEnum: >Alpha | 3,4');
        Probe.Expect('ge.Enum', '>=Alpha | FEnum: >=Alpha | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Enum_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedEnum();
        Probe.Cell('rng.Enum', 22, '{a}..{b}');
        Probe.Cell('upto.Enum', 22, '..{b}');
        Probe.Cell('from.Enum', 22, '{a}..');
        Probe.Cell('or.Enum', 22, '{a}|{b}');
        Probe.Cell('and.Enum', 22, '>{a}&<{b}');
        Probe.Cell('ordinal.Enum', 22, '{o}');
        Probe.Cell('neordinal.Enum', 22, '<>{o}');
        Probe.Expect('rng.Enum', 'Alpha..Beta | FEnum: Alpha..Beta | 1,2,3');
        Probe.Expect('upto.Enum', '..Beta | FEnum: ..Beta | 1,2,3');
        Probe.Expect('from.Enum', 'Alpha.. | FEnum: Alpha.. | 1,2,3,4');
        Probe.Expect('or.Enum', 'Alpha|Beta | FEnum: Alpha|Beta | 1,2,3');
        Probe.Expect('and.Enum', '>Alpha&<Beta | FEnum: >Alpha&<Beta | ');
        Probe.Expect('ordinal.Enum', 'Alpha | FEnum: Alpha | 1,2');
        Probe.Expect('neordinal.Enum', '<>Alpha | FEnum: <>Alpha | 3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Enum_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedEnum();
        Probe.Cell('star.Enum', 22, '*');
        Probe.Cell('q.Enum', 22, '?');
        Probe.Cell('at.Enum', 22, '@{a}');
        Probe.Cell('prefix.Enum', 22, '{a}*');
        Probe.Cell('nstar.Enum', 22, '<>*');
        Probe.Cell('suffix.Enum', 22, '*{a}');
        Probe.Expect('star.Enum', 'E: The filter "*" is not valid for the FEnum field on the LT FRM Row table. ''*'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('q.Enum', 'E: The filter "?" is not valid for the FEnum field on the LT FRM Row table. ''?'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('at.Enum', 'E: The filter "@Alpha" is not valid for the FEnum field on the LT FRM Row table. ''@Alpha'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('prefix.Enum', 'E: The filter "Alpha*" is not valid for the FEnum field on the LT FRM Row table. ''Alpha*'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('nstar.Enum', 'E: The filter "<>*" is not valid for the FEnum field on the LT FRM Row table. ''*'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('suffix.Enum', 'E: The filter "*Alpha" is not valid for the FEnum field on the LT FRM Row table. ''*Alpha'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Enum_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedEnum();
        Probe.Cell('empty.Enum', 22, '');
        Probe.Cell('quotes.Enum', 22, '''''');
        Probe.Cell('nequotes.Enum', 22, '<>''''');
        Probe.Cell('bare.Enum', 22, '<>');
        Probe.Cell('unterm.Enum', 22, '''');
        Probe.Cell('unterm2.Enum', 22, '{a}''');
        Probe.Cell('quotedA.Enum', 22, '''{a}''');
        Probe.Expect('empty.Enum', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Enum', 'E: The filter "''''" is not valid for the FEnum field on the LT FRM Row table. '''' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('nequotes.Enum', 'E: The filter "<>''''" is not valid for the FEnum field on the LT FRM Row table. '''' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('bare.Enum', 'E: The filter "<>" is not valid for the FEnum field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Enum', 'E: The filter "''" is not valid for the FEnum field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Enum', 'E: The filter "Alpha''" is not valid for the FEnum field on the LT FRM Row table. ''Alpha'''' is not an option. The existing options are: Alpha,Beta,Gamma');
        Probe.Expect('quotedA.Enum', 'Alpha | FEnum: Alpha | 1,2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Enum_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedEnum();
        Probe.CellArg('p1.Enum', 22, '%1', 'a');
        Probe.CellArg('pne.Enum', 22, '<>%1', 'a');
        Probe.CellArg('pge.Enum', 22, '>=%1', 'a');
        Probe.CellArg('pstar.Enum', 22, '%1', 'w');
        Probe.CellArg('pnestar.Enum', 22, '<>%1', 'w');
        Probe.CellArg('pq.Enum', 22, '%1', 'q');
        Probe.CellArg('pnq.Enum', 22, '<>%1', 'q');
        Probe.Expect('p1.Enum', 'Alpha | FEnum: Alpha | 1,2');
        Probe.Expect('pne.Enum', '<>Alpha | FEnum: <>Alpha | 3,4');
        Probe.Expect('pge.Enum', '>=Alpha | FEnum: >=Alpha | 1,2,3,4');
#if BC28PLUS
        Probe.Expect('pstar.Enum', 'E: The value "a*b?" can''t be evaluated into type Option.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Enum', 'E: The type NavOption is unknown.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Enum', 'E: The value "a*b?" can''t be evaluated into type Option.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Enum', 'E: The type NavOption is unknown.');
#endif
        Probe.Expect('pq.Enum', '63 | FEnum: 63 | ');
        Probe.Expect('pnq.Enum', '<>63 | FEnum: <>63 | 1,2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Enum_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedEnum();
        Probe.CellRange('r1.Enum', 22, 'r1');
        Probe.CellRange('r2.Enum', 22, 'r2');
        Probe.CellRange('rtext.Enum', 22, 'rt');
        Probe.Expect('r1.Enum', 'Alpha | FEnum: Alpha | 1,2');
        Probe.Expect('r2.Enum', 'Alpha | FEnum: Alpha | 1,2');
#if BC28PLUS
        Probe.Expect('rtext.Enum', 'E: The value "Alpha" can''t be evaluated into type Option.');
#else // BC 27.5 words this result differently
        Probe.Expect('rtext.Enum', 'E: The type NavOption is unknown.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Enum_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedEnum();
        Probe.CellView('vgt.Enum', 22, '>{a}');
        Probe.CellView('vne.Enum', 22, '<>{a}');
        Probe.CellView('vrng.Enum', 22, '{a}..{b}');
        Probe.CellView('vor.Enum', 22, '{a}|{b}');
        Probe.CellView('veq.Enum', 22, '{a}');
        Probe.Expect('vgt.Enum', 'VERSION(1) SORTING(No.) WHERE(FEnum=FILTER(>Alpha)) | VERSION(1) SORTING(Field1) WHERE(Field22=1(>0)) | >Alpha | 3,4');
        Probe.Expect('vne.Enum', 'VERSION(1) SORTING(No.) WHERE(FEnum=FILTER(<>Alpha)) | VERSION(1) SORTING(Field1) WHERE(Field22=1(<>0)) | <>Alpha | 3,4');
        Probe.Expect('vrng.Enum', 'VERSION(1) SORTING(No.) WHERE(FEnum=FILTER(Alpha..Beta)) | VERSION(1) SORTING(Field1) WHERE(Field22=1(0..1)) | Alpha..Beta | 1,2,3');
        Probe.Expect('vor.Enum', 'VERSION(1) SORTING(No.) WHERE(FEnum=FILTER(Alpha|Beta)) | VERSION(1) SORTING(Field1) WHERE(Field22=1(0|1)) | Alpha|Beta | 1,2,3');
        Probe.Expect('veq.Enum', 'VERSION(1) SORTING(No.) WHERE(FEnum=FILTER(Alpha)) | VERSION(1) SORTING(Field1) WHERE(Field22=1(0)) | Alpha | 1,2');
        Probe.Verify();
    end;

    local procedure SeedRid()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        Evaluate(R.FRid, 'LT FRM Row: 1');
        R.Insert();
        R.Init();
        R."No." := 3;
        Evaluate(R.FRid, 'LT FRM Row: 2');
        R.Insert();
        R.Init();
        R."No." := 4;
        Evaluate(R.FRid, 'LT FRM Row: 3');
        R.Insert();
    end;

    [Test]
    procedure Filter_Rid_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedRid();
        Probe.Cell('eq.Rid', 24, '{a}');
        Probe.Cell('eqop.Rid', 24, '={a}');
        Probe.Cell('ne.Rid', 24, '<>{a}');
        Probe.Cell('lt.Rid', 24, '<{a}');
        Probe.Cell('le.Rid', 24, '<={a}');
        Probe.Cell('gt.Rid', 24, '>{a}');
        Probe.Cell('ge.Rid', 24, '>={a}');
        Probe.Expect('eq.Rid', 'LT FRM Row: 1 | FRid: LT FRM Row: 1 | 2');
        Probe.Expect('eqop.Rid', 'LT FRM Row: 1 | FRid: LT FRM Row: 1 | 2');
        Probe.Expect('ne.Rid', '<>LT FRM Row: 1 | FRid: <>LT FRM Row: 1 | 1,3,4');
        Probe.Expect('lt.Rid', '<LT FRM Row: 1 | FRid: <LT FRM Row: 1 | 1');
        Probe.Expect('le.Rid', '<=LT FRM Row: 1 | FRid: <=LT FRM Row: 1 | 1,2');
        Probe.Expect('gt.Rid', '>LT FRM Row: 1 | FRid: >LT FRM Row: 1 | 3,4');
        Probe.Expect('ge.Rid', '>=LT FRM Row: 1 | FRid: >=LT FRM Row: 1 | 2,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Rid_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedRid();
        Probe.Cell('rng.Rid', 24, '{a}..{b}');
        Probe.Cell('upto.Rid', 24, '..{b}');
        Probe.Cell('from.Rid', 24, '{a}..');
        Probe.Cell('or.Rid', 24, '{a}|{b}');
        Probe.Cell('and.Rid', 24, '>{a}&<{b}');
        Probe.Cell('ordinal.Rid', 24, '{o}');
        Probe.Cell('neordinal.Rid', 24, '<>{o}');
        Probe.Expect('rng.Rid', 'LT FRM Row: 1..LT FRM Row: 2 | FRid: LT FRM Row: 1..LT FRM Row: 2 | 2,3');
        Probe.Expect('upto.Rid', '..LT FRM Row: 2 | FRid: ..LT FRM Row: 2 | 1,2,3');
        Probe.Expect('from.Rid', 'LT FRM Row: 1.. | FRid: LT FRM Row: 1.. | 2,3,4');
        Probe.Expect('or.Rid', 'LT FRM Row: 1|LT FRM Row: 2 | FRid: LT FRM Row: 1|LT FRM Row: 2 | 2,3');
        Probe.Expect('and.Rid', '>LT FRM Row: 1&<LT FRM Row: 2 | FRid: >LT FRM Row: 1&<LT FRM Row: 2 | ');
        Probe.Expect('ordinal.Rid', 'LT FRM Row: 1 | FRid: LT FRM Row: 1 | 2');
        Probe.Expect('neordinal.Rid', '<>LT FRM Row: 1 | FRid: <>LT FRM Row: 1 | 1,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Rid_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedRid();
        Probe.Cell('star.Rid', 24, '*');
        Probe.Cell('q.Rid', 24, '?');
        Probe.Cell('at.Rid', 24, '@{a}');
        Probe.Cell('prefix.Rid', 24, '{a}*');
        Probe.Cell('nstar.Rid', 24, '<>*');
        Probe.Cell('suffix.Rid', 24, '*{a}');
        Probe.Expect('star.Rid', 'Payment Terms | FRid: Payment Terms | ');
        Probe.Expect('q.Rid', 'Payment Terms | FRid: Payment Terms | ');
        Probe.Expect('at.Rid', 'E: The filter "@LT FRM Row: 1" is not valid for the FRid field on the LT FRM Row table. The value "@LT FRM Row: 1" can''t be evaluated into type RecordID.');
        Probe.Expect('prefix.Rid', 'E: The filter "LT FRM Row: 1*" is not valid for the FRid field on the LT FRM Row table. The value "1*" can''t be evaluated into type Integer.');
        Probe.Expect('nstar.Rid', '<>Payment Terms | FRid: <>Payment Terms | 1,2,3,4');
        Probe.Expect('suffix.Rid', 'LT FRM Row: 1 | FRid: LT FRM Row: 1 | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Rid_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedRid();
        Probe.Cell('empty.Rid', 24, '');
        Probe.Cell('quotes.Rid', 24, '''''');
        Probe.Cell('nequotes.Rid', 24, '<>''''');
        Probe.Cell('bare.Rid', 24, '<>');
        Probe.Cell('unterm.Rid', 24, '''');
        Probe.Cell('unterm2.Rid', 24, '{a}''');
        Probe.Cell('quotedA.Rid', 24, '''{a}''');
        Probe.Expect('empty.Rid', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Rid', ''''' | FRid: '''' | 1');
        Probe.Expect('nequotes.Rid', '<>'''' | FRid: <>'''' | 2,3,4');
        Probe.Expect('bare.Rid', 'E: The filter "<>" is not valid for the FRid field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Rid', 'E: The filter "''" is not valid for the FRid field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Rid', 'E: The filter "LT FRM Row: 1''" is not valid for the FRid field on the LT FRM Row table. The value "1''" can''t be evaluated into type Integer.');
        Probe.Expect('quotedA.Rid', 'LT FRM Row: 1 | FRid: LT FRM Row: 1 | 2');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Rid_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedRid();
        Probe.CellArg('p1.Rid', 24, '%1', 'a');
        Probe.CellArg('pne.Rid', 24, '<>%1', 'a');
        Probe.CellArg('pge.Rid', 24, '>=%1', 'a');
        Probe.CellArg('pstar.Rid', 24, '%1', 'w');
        Probe.CellArg('pnestar.Rid', 24, '<>%1', 'w');
        Probe.CellArg('pq.Rid', 24, '%1', 'q');
        Probe.CellArg('pnq.Rid', 24, '<>%1', 'q');
        Probe.Expect('p1.Rid', 'LT FRM Row: 1 | FRid: LT FRM Row: 1 | 2');
        Probe.Expect('pne.Rid', '<>LT FRM Row: 1 | FRid: <>LT FRM Row: 1 | 1,3,4');
        Probe.Expect('pge.Rid', '>=LT FRM Row: 1 | FRid: >=LT FRM Row: 1 | 2,3,4');
        Probe.Expect('pstar.Rid', 'E: Cannot create the specified RecordId of length 10 for table 2752609 because it is invalid.');
        Probe.Expect('pnestar.Rid', 'E: Cannot create the specified RecordId of length 10 for table 2752609 because it is invalid.');
        Probe.Expect('pq.Rid', 'E: Cannot create the specified RecordId of length 2 for table -1 because it is invalid.');
        Probe.Expect('pnq.Rid', 'E: Cannot create the specified RecordId of length 2 for table -1 because it is invalid.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Rid_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedRid();
        Probe.CellRange('r1.Rid', 24, 'r1');
        Probe.CellRange('r2.Rid', 24, 'r2');
        Probe.CellRange('rtext.Rid', 24, 'rt');
        Probe.Expect('r1.Rid', 'LT FRM Row: 1 | FRid: LT FRM Row: 1 | 2');
        Probe.Expect('r2.Rid', 'LT FRM Row: 1 | FRid: LT FRM Row: 1 | 2');
        Probe.Expect('rtext.Rid', 'E: Cannot create the specified RecordId of length 28 for table 5505100 because it is invalid.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Rid_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedRid();
        Probe.CellView('vgt.Rid', 24, '>{a}');
        Probe.CellView('vne.Rid', 24, '<>{a}');
        Probe.CellView('vrng.Rid', 24, '{a}..{b}');
        Probe.CellView('vor.Rid', 24, '{a}|{b}');
        Probe.CellView('veq.Rid', 24, '{a}');
        Probe.Expect('vgt.Rid', 'VERSION(1) SORTING(No.) WHERE(FRid=FILTER(>LT FRM Row: 1)) | VERSION(1) SORTING(Field1) WHERE(Field24=1(>LT FRM Row: 1)) | >LT FRM Row: 1 | 3,4');
        Probe.Expect('vne.Rid', 'VERSION(1) SORTING(No.) WHERE(FRid=FILTER(<>LT FRM Row: 1)) | VERSION(1) SORTING(Field1) WHERE(Field24=1(<>LT FRM Row: 1)) | <>LT FRM Row: 1 | 1,3,4');
        Probe.Expect('vrng.Rid', 'VERSION(1) SORTING(No.) WHERE(FRid=FILTER(LT FRM Row: 1..LT FRM Row: 2)) | VERSION(1) SORTING(Field1) WHERE(Field24=1(LT FRM Row: 1..LT FRM Row: 2)) | LT FRM Row: 1..LT FRM Row: 2 | 2,3');
        Probe.Expect('vor.Rid', 'VERSION(1) SORTING(No.) WHERE(FRid=FILTER(LT FRM Row: 1|LT FRM Row: 2)) | VERSION(1) SORTING(Field1) WHERE(Field24=1(LT FRM Row: 1|LT FRM Row: 2)) | LT FRM Row: 1|LT FRM Row: 2 | 2,3');
        Probe.Expect('veq.Rid', 'VERSION(1) SORTING(No.) WHERE(FRid=FILTER(LT FRM Row: 1)) | VERSION(1) SORTING(Field1) WHERE(Field24=1(LT FRM Row: 1)) | LT FRM Row: 1 | 2');
        Probe.Verify();
    end;

}

codeunit 70048 "LT FRM Binary Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedBlob()
    var
        R: Record "LT FRM Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FBlob.CreateOutStream(OutS);
        OutS.WriteText('abc');
        R.Insert();
        R.Init();
        R."No." := 3;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.Insert();
    end;

    [Test]
    procedure Filter_Blob_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBlob();
        Probe.Cell('eq.Blob', 25, '{a}');
        Probe.Cell('eqop.Blob', 25, '={a}');
        Probe.Cell('ne.Blob', 25, '<>{a}');
        Probe.Cell('lt.Blob', 25, '<{a}');
        Probe.Cell('le.Blob', 25, '<={a}');
        Probe.Cell('gt.Blob', 25, '>{a}');
        Probe.Cell('ge.Blob', 25, '>={a}');
        Probe.Expect('eq.Blob', 'E: The filter "abc" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('eqop.Blob', 'E: The filter "=abc" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('ne.Blob', 'E: The filter "<>abc" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('lt.Blob', 'E: The filter "<abc" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('le.Blob', 'E: The filter "<=abc" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('gt.Blob', 'E: The filter ">abc" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('ge.Blob', 'E: The filter ">=abc" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Blob_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBlob();
        Probe.Cell('rng.Blob', 25, '{a}..{b}');
        Probe.Cell('upto.Blob', 25, '..{b}');
        Probe.Cell('from.Blob', 25, '{a}..');
        Probe.Cell('or.Blob', 25, '{a}|{b}');
        Probe.Cell('and.Blob', 25, '>{a}&<{b}');
        Probe.Cell('ordinal.Blob', 25, '{o}');
        Probe.Cell('neordinal.Blob', 25, '<>{o}');
        Probe.Expect('rng.Blob', 'E: The filter "abc..abd" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('upto.Blob', 'E: The filter "..abd" is not valid for the FBlob field on the LT FRM Row table. The value "abd" can''t be evaluated into type BLOB.');
        Probe.Expect('from.Blob', 'E: The filter "abc.." is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('or.Blob', 'E: The filter "abc|abd" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('and.Blob', 'E: The filter ">abc&<abd" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('ordinal.Blob', '* | FBlob: * | 2');
        Probe.Expect('neordinal.Blob', '<>* | FBlob: <>* | 1,3,4');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Blob_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBlob();
        Probe.Cell('star.Blob', 25, '*');
        Probe.Cell('q.Blob', 25, '?');
        Probe.Cell('at.Blob', 25, '@{a}');
        Probe.Cell('prefix.Blob', 25, '{a}*');
        Probe.Cell('nstar.Blob', 25, '<>*');
        Probe.Cell('suffix.Blob', 25, '*{a}');
        Probe.Expect('star.Blob', '* | FBlob: * | 2');
        Probe.Expect('q.Blob', 'E: The filter "?" is not valid for the FBlob field on the LT FRM Row table. The value "?" can''t be evaluated into type BLOB.');
        Probe.Expect('at.Blob', 'E: The filter "@abc" is not valid for the FBlob field on the LT FRM Row table. The value "@abc" can''t be evaluated into type BLOB.');
        Probe.Expect('prefix.Blob', 'E: The filter "abc*" is not valid for the FBlob field on the LT FRM Row table. The value "abc*" can''t be evaluated into type BLOB.');
        Probe.Expect('nstar.Blob', '<>* | FBlob: <>* | 1,3,4');
        Probe.Expect('suffix.Blob', 'E: The filter "*abc" is not valid for the FBlob field on the LT FRM Row table. The value "*abc" can''t be evaluated into type BLOB.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Blob_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBlob();
        Probe.Cell('empty.Blob', 25, '');
        Probe.Cell('quotes.Blob', 25, '''''');
        Probe.Cell('nequotes.Blob', 25, '<>''''');
        Probe.Cell('bare.Blob', 25, '<>');
        Probe.Cell('unterm.Blob', 25, '''');
        Probe.Cell('unterm2.Blob', 25, '{a}''');
        Probe.Cell('quotedA.Blob', 25, '''{a}''');
        Probe.Expect('empty.Blob', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Blob', ''' '' | FBlob: '' '' | 1,3,4');
        Probe.Expect('nequotes.Blob', '<>'' '' | FBlob: <>'' '' | 2');
        Probe.Expect('bare.Blob', 'E: The filter "<>" is not valid for the FBlob field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Blob', 'E: The filter "''" is not valid for the FBlob field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Expect('unterm2.Blob', 'E: The filter "abc''" is not valid for the FBlob field on the LT FRM Row table. The value "abc''" can''t be evaluated into type BLOB.');
        Probe.Expect('quotedA.Blob', 'E: The filter "''abc''" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Blob_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBlob();
        Probe.CellArg('p1.Blob', 25, '%1', 'a');
        Probe.CellArg('pne.Blob', 25, '<>%1', 'a');
        Probe.CellArg('pge.Blob', 25, '>=%1', 'a');
        Probe.CellArg('pstar.Blob', 25, '%1', 'w');
        Probe.CellArg('pnestar.Blob', 25, '<>%1', 'w');
        Probe.CellArg('pq.Blob', 25, '%1', 'q');
        Probe.CellArg('pnq.Blob', 25, '<>%1', 'q');
#if BC28PLUS
        Probe.Expect('p1.Blob', 'E: The value "abc" can''t be evaluated into type BLOB.');
#else // BC 27.5 words this result differently
        Probe.Expect('p1.Blob', 'E: Invalid Conversion. Source: NavVariant, Destination: NavBLOB.');
#endif
#if BC28PLUS
        Probe.Expect('pne.Blob', 'E: The value "abc" can''t be evaluated into type BLOB.');
#else // BC 27.5 words this result differently
        Probe.Expect('pne.Blob', 'E: Invalid Conversion. Source: NavVariant, Destination: NavBLOB.');
#endif
#if BC28PLUS
        Probe.Expect('pge.Blob', 'E: The value "abc" can''t be evaluated into type BLOB.');
#else // BC 27.5 words this result differently
        Probe.Expect('pge.Blob', 'E: Invalid Conversion. Source: NavVariant, Destination: NavBLOB.');
#endif
#if BC28PLUS
        Probe.Expect('pstar.Blob', 'E: The value "a*b?" can''t be evaluated into type BLOB.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Blob', 'E: Invalid Conversion. Source: NavVariant, Destination: NavBLOB.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Blob', 'E: The value "a*b?" can''t be evaluated into type BLOB.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Blob', 'E: Invalid Conversion. Source: NavVariant, Destination: NavBLOB.');
#endif
#if BC28PLUS
        Probe.Expect('pq.Blob', 'E: The value "?" can''t be evaluated into type BLOB.');
#else // BC 27.5 words this result differently
        Probe.Expect('pq.Blob', 'E: Invalid Conversion. Source: NavVariant, Destination: NavBLOB.');
#endif
#if BC28PLUS
        Probe.Expect('pnq.Blob', 'E: The value "?" can''t be evaluated into type BLOB.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnq.Blob', 'E: Invalid Conversion. Source: NavVariant, Destination: NavBLOB.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Blob_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBlob();
        Probe.CellRange('r1.Blob', 25, 'r1');
        Probe.CellRange('r2.Blob', 25, 'r2');
        Probe.CellRange('rtext.Blob', 25, 'rt');
#if BC28PLUS
        Probe.Expect('r1.Blob', 'E: The value "abc" can''t be evaluated into type BLOB.');
#else // BC 27.5 words this result differently
        Probe.Expect('r1.Blob', 'E: Invalid Conversion. Source: NavVariant, Destination: NavBLOB.');
#endif
#if BC28PLUS
        Probe.Expect('r2.Blob', 'E: The value "abc" can''t be evaluated into type BLOB.');
#else // BC 27.5 words this result differently
        Probe.Expect('r2.Blob', 'E: Invalid Conversion. Source: NavVariant, Destination: NavBLOB.');
#endif
#if BC28PLUS
        Probe.Expect('rtext.Blob', 'E: The value "abc" can''t be evaluated into type BLOB.');
#else // BC 27.5 words this result differently
        Probe.Expect('rtext.Blob', 'E: Invalid Conversion. Source: NavVariant, Destination: NavBLOB.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Blob_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedBlob();
        Probe.CellView('vgt.Blob', 25, '>{a}');
        Probe.CellView('vne.Blob', 25, '<>{a}');
        Probe.CellView('vrng.Blob', 25, '{a}..{b}');
        Probe.CellView('vor.Blob', 25, '{a}|{b}');
        Probe.CellView('veq.Blob', 25, '{a}');
        Probe.Expect('vgt.Blob', 'E: The filter ">abc" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('vne.Blob', 'E: The filter "<>abc" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('vrng.Blob', 'E: The filter "abc..abd" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('vor.Blob', 'E: The filter "abc|abd" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Expect('veq.Blob', 'E: The filter "abc" is not valid for the FBlob field on the LT FRM Row table. The value "abc" can''t be evaluated into type BLOB.');
        Probe.Verify();
    end;

    local procedure SeedMedia()
    var
        R: Record "LT FRM Row";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
        InS: InStream;
    begin
        // The stream comes from a Temp Blob of this procedure: an InStream returned from a helper's own Temp Blob is empty here
        // ("Media object cannot be imported because the InStream object is empty.", first local observation on BC 29.0).
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', OutS);
        TempBlob.CreateInStream(InS);
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FMedia.ImportStream(InS, 'probe', 'image/png');
        R.Insert();
        R.Init();
        R."No." := 3;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.Insert();
    end;

    [Test]
    procedure Filter_Media_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMedia();
        Probe.Cell('eq.Media', 26, '{a}');
        Probe.Cell('eqop.Media', 26, '={a}');
        Probe.Cell('ne.Media', 26, '<>{a}');
        Probe.Cell('lt.Media', 26, '<{a}');
        Probe.Cell('le.Media', 26, '<={a}');
        Probe.Cell('gt.Media', 26, '>{a}');
        Probe.Cell('ge.Media', 26, '>={a}');
        Probe.Ignore('eq.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('eqop.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('ne.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('lt.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('le.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('gt.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('ge.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Media_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMedia();
        Probe.Cell('rng.Media', 26, '{a}..{b}');
        Probe.Cell('upto.Media', 26, '..{b}');
        Probe.Cell('from.Media', 26, '{a}..');
        Probe.Cell('or.Media', 26, '{a}|{b}');
        Probe.Cell('and.Media', 26, '>{a}&<{b}');
        Probe.Cell('ordinal.Media', 26, '{o}');
        Probe.Cell('neordinal.Media', 26, '<>{o}');
        Probe.Ignore('rng.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('upto.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('from.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('or.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('and.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Expect('ordinal.Media', 'E: The filter "1" is not valid for the FMedia field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('neordinal.Media', 'E: The filter "<>1" is not valid for the FMedia field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Media_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMedia();
        Probe.Cell('star.Media', 26, '*');
        Probe.Cell('q.Media', 26, '?');
        Probe.Cell('at.Media', 26, '@{a}');
        Probe.Cell('prefix.Media', 26, '{a}*');
        Probe.Cell('nstar.Media', 26, '<>*');
        Probe.Cell('suffix.Media', 26, '*{a}');
        Probe.Expect('star.Media', 'E: The filter "*" is not valid for the FMedia field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('q.Media', 'E: The filter "?" is not valid for the FMedia field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Ignore('at.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('prefix.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Expect('nstar.Media', 'E: The filter "<>*" is not valid for the FMedia field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Ignore('suffix.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Media_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMedia();
        Probe.Cell('empty.Media', 26, '');
        Probe.Cell('quotes.Media', 26, '''''');
        Probe.Cell('nequotes.Media', 26, '<>''''');
        Probe.Cell('bare.Media', 26, '<>');
        Probe.Cell('unterm.Media', 26, '''');
        Probe.Cell('unterm2.Media', 26, '{a}''');
        Probe.Cell('quotedA.Media', 26, '''{a}''');
        Probe.Expect('empty.Media', ' |  | 1,2,3,4');
        Probe.Expect('quotes.Media', 'E: The filter "''''" is not valid for the FMedia field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('nequotes.Media', 'E: The filter "<>''''" is not valid for the FMedia field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('bare.Media', 'E: The filter "<>" is not valid for the FMedia field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.Media', 'E: The filter "''" is not valid for the FMedia field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Ignore('unterm2.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('quotedA.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Media_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMedia();
        Probe.CellArg('p1.Media', 26, '%1', 'a');
        Probe.CellArg('pne.Media', 26, '<>%1', 'a');
        Probe.CellArg('pge.Media', 26, '>=%1', 'a');
        Probe.CellArg('pstar.Media', 26, '%1', 'w');
        Probe.CellArg('pnestar.Media', 26, '<>%1', 'w');
        Probe.CellArg('pq.Media', 26, '%1', 'q');
        Probe.CellArg('pnq.Media', 26, '<>%1', 'q');
        Probe.Ignore('p1.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('pne.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('pge.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
#if BC28PLUS
        Probe.Expect('pstar.Media', 'E: The value "a*b?" can''t be evaluated into type Media.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.Media', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.Media', 'E: The value "a*b?" can''t be evaluated into type Media.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.Media', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia.');
#endif
#if BC28PLUS
        Probe.Expect('pq.Media', 'E: The value "?" can''t be evaluated into type Media.');
#else // BC 27.5 words this result differently
        Probe.Expect('pq.Media', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia.');
#endif
#if BC28PLUS
        Probe.Expect('pnq.Media', 'E: The value "?" can''t be evaluated into type Media.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnq.Media', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Media_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMedia();
        Probe.CellRange('r1.Media', 26, 'r1');
        Probe.CellRange('r2.Media', 26, 'r2');
        Probe.CellRange('rtext.Media', 26, 'rt');
        Probe.Ignore('r1.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('r2.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('rtext.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Verify();
    end;

    [Test]
    procedure Filter_Media_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMedia();
        Probe.CellView('vgt.Media', 26, '>{a}');
        Probe.CellView('vne.Media', 26, '<>{a}');
        Probe.CellView('vrng.Media', 26, '{a}..{b}');
        Probe.CellView('vor.Media', 26, '{a}|{b}');
        Probe.CellView('veq.Media', 26, '{a}');
        Probe.Ignore('vgt.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('vne.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('vrng.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('vor.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('veq.Media'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Verify();
    end;

    local procedure SeedMediaSet()
    var
        R: Record "LT FRM Row";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
        InS: InStream;
    begin
        // The stream comes from a Temp Blob of this procedure: an InStream returned from a helper's own Temp Blob is empty here
        // ("Media object cannot be imported because the InStream object is empty.", first local observation on BC 29.0).
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', OutS);
        TempBlob.CreateInStream(InS);
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        R.FMediaSet.ImportStream(InS, 'probe', 'image/png');
        R.Insert();
        R.Init();
        R."No." := 3;
        R.Insert();
        R.Init();
        R."No." := 4;
        R.Insert();
    end;

    [Test]
    procedure Filter_MediaSet_Compare()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMediaSet();
        Probe.Cell('eq.MediaSet', 27, '{a}');
        Probe.Cell('eqop.MediaSet', 27, '={a}');
        Probe.Cell('ne.MediaSet', 27, '<>{a}');
        Probe.Cell('lt.MediaSet', 27, '<{a}');
        Probe.Cell('le.MediaSet', 27, '<={a}');
        Probe.Cell('gt.MediaSet', 27, '>{a}');
        Probe.Cell('ge.MediaSet', 27, '>={a}');
        Probe.Ignore('eq.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('eqop.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('ne.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('lt.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('le.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('gt.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('ge.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Verify();
    end;

    [Test]
    procedure Filter_MediaSet_Lists()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMediaSet();
        Probe.Cell('rng.MediaSet', 27, '{a}..{b}');
        Probe.Cell('upto.MediaSet', 27, '..{b}');
        Probe.Cell('from.MediaSet', 27, '{a}..');
        Probe.Cell('or.MediaSet', 27, '{a}|{b}');
        Probe.Cell('and.MediaSet', 27, '>{a}&<{b}');
        Probe.Cell('ordinal.MediaSet', 27, '{o}');
        Probe.Cell('neordinal.MediaSet', 27, '<>{o}');
        Probe.Ignore('rng.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('upto.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('from.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('or.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('and.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Expect('ordinal.MediaSet', 'E: The filter "1" is not valid for the FMediaSet field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('neordinal.MediaSet', 'E: The filter "<>1" is not valid for the FMediaSet field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Verify();
    end;

    [Test]
    procedure Filter_MediaSet_Wild()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMediaSet();
        Probe.Cell('star.MediaSet', 27, '*');
        Probe.Cell('q.MediaSet', 27, '?');
        Probe.Cell('at.MediaSet', 27, '@{a}');
        Probe.Cell('prefix.MediaSet', 27, '{a}*');
        Probe.Cell('nstar.MediaSet', 27, '<>*');
        Probe.Cell('suffix.MediaSet', 27, '*{a}');
        Probe.Expect('star.MediaSet', 'E: The filter "*" is not valid for the FMediaSet field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('q.MediaSet', 'E: The filter "?" is not valid for the FMediaSet field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Ignore('at.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('prefix.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Expect('nstar.MediaSet', 'E: The filter "<>*" is not valid for the FMediaSet field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Ignore('suffix.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Verify();
    end;

    [Test]
    procedure Filter_MediaSet_Empty()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMediaSet();
        Probe.Cell('empty.MediaSet', 27, '');
        Probe.Cell('quotes.MediaSet', 27, '''''');
        Probe.Cell('nequotes.MediaSet', 27, '<>''''');
        Probe.Cell('bare.MediaSet', 27, '<>');
        Probe.Cell('unterm.MediaSet', 27, '''');
        Probe.Cell('unterm2.MediaSet', 27, '{a}''');
        Probe.Cell('quotedA.MediaSet', 27, '''{a}''');
        Probe.Expect('empty.MediaSet', ' |  | 1,2,3,4');
        Probe.Expect('quotes.MediaSet', 'E: The filter "''''" is not valid for the FMediaSet field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('nequotes.MediaSet', 'E: The filter "<>''''" is not valid for the FMediaSet field on the LT FRM Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Probe.Expect('bare.MediaSet', 'E: The filter "<>" is not valid for the FMediaSet field on the LT FRM Row table. A value is expected after the ''<>''.');
        Probe.Expect('unterm.MediaSet', 'E: The filter "''" is not valid for the FMediaSet field on the LT FRM Row table. An single quote ('') is missing.');
        Probe.Ignore('unterm2.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('quotedA.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Verify();
    end;

    [Test]
    procedure Filter_MediaSet_Args()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMediaSet();
        Probe.CellArg('p1.MediaSet', 27, '%1', 'a');
        Probe.CellArg('pne.MediaSet', 27, '<>%1', 'a');
        Probe.CellArg('pge.MediaSet', 27, '>=%1', 'a');
        Probe.CellArg('pstar.MediaSet', 27, '%1', 'w');
        Probe.CellArg('pnestar.MediaSet', 27, '<>%1', 'w');
        Probe.CellArg('pq.MediaSet', 27, '%1', 'q');
        Probe.CellArg('pnq.MediaSet', 27, '<>%1', 'q');
        Probe.Ignore('p1.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('pne.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('pge.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
#if BC28PLUS
        Probe.Expect('pstar.MediaSet', 'E: The value "a*b?" can''t be evaluated into type MediaSet.');
#else // BC 27.5 words this result differently
        Probe.Expect('pstar.MediaSet', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet.');
#endif
#if BC28PLUS
        Probe.Expect('pnestar.MediaSet', 'E: The value "a*b?" can''t be evaluated into type MediaSet.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnestar.MediaSet', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet.');
#endif
#if BC28PLUS
        Probe.Expect('pq.MediaSet', 'E: The value "?" can''t be evaluated into type MediaSet.');
#else // BC 27.5 words this result differently
        Probe.Expect('pq.MediaSet', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet.');
#endif
#if BC28PLUS
        Probe.Expect('pnq.MediaSet', 'E: The value "?" can''t be evaluated into type MediaSet.');
#else // BC 27.5 words this result differently
        Probe.Expect('pnq.MediaSet', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet.');
#endif
        Probe.Verify();
    end;

    [Test]
    procedure Filter_MediaSet_Range()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMediaSet();
        Probe.CellRange('r1.MediaSet', 27, 'r1');
        Probe.CellRange('r2.MediaSet', 27, 'r2');
        Probe.CellRange('rtext.MediaSet', 27, 'rt');
        Probe.Ignore('r1.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('r2.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('rtext.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Verify();
    end;

    [Test]
    procedure Filter_MediaSet_View()
    var
        Probe: Codeunit "LT FRM Probe";
    begin
        SeedMediaSet();
        Probe.CellView('vgt.MediaSet', 27, '>{a}');
        Probe.CellView('vne.MediaSet', 27, '<>{a}');
        Probe.CellView('vrng.MediaSet', 27, '{a}..{b}');
        Probe.CellView('vor.MediaSet', 27, '{a}|{b}');
        Probe.CellView('veq.MediaSet', 27, '{a}');
        Probe.Ignore('vgt.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('vne.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('vrng.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('vor.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Ignore('veq.MediaSet'); // the value holds a GUID that is new on every run (a Media id or CreateGuid()): observed, not asserted
        Probe.Verify();
    end;

}
