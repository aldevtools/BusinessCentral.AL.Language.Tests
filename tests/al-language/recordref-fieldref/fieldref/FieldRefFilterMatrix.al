// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70041, enum 70042, helper codeunit 70043, test codeunits 70044..70048
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
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
        Probe.Finish();
    end;

}
