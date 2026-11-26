// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586) and "CLB Store" (codeunit 75587) of
//   ClearSharedCodeunitTempRef.al; "CLS Arr Store" (codeunit 75596) and "CLS Arr Holder" (codeunit 75597) of
//   ClearSharedCodeunitSIOwner.al; "CLX Store" (codeunit 75580) of ClearSharedCodeunit.al; self-contained objects
//   77173 to 77208
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: ClearAll in owners and of stores next to the ones ClearSharedCodeunitSIOwner.al measured. Each test
//   observes the store after the ClearAll, then writes through the alias (or the owner when nothing shares) and
//   observes again. State text of "CLB Store": rows = temporary rows, ref11 / ref23 = Number of RecordRef elements
//   [1,1] and [2,3] (refrows = rows of [1,1] when it is open), int1 / int3 = Integer elements 1 and 3; of "CLS Arr
//   Store": rows1 / rows2 = rows counted through elements 1 and 2 of its array of temporary records, ref1 = Number of
//   RecordRef element 1, int1 = Integer element 1.
//   - "CLQ Owner Kind Tests": the array store in a plain holder (an alias that wrote nothing; written with nothing
//     sharing; never written); "CLB Store" held by a codeunit with Subtype = Normal, a codeunit with TableNo and a
//     report (used as a variable, never run); a store with one more Integer global; a store held one level deeper
//     (holder -> wrapper -> store); an array[2] of "CLB Store" in the holder; an array of temporary records and a
//     temporary record in a report.
//   - "CLQ SI Arr Clear Tests" and "CLQ SI Arr Lifetime Tests": a SingleInstance owner of the array store; the
//     lifetime steps are test methods that run in the order they are declared (M1 = never made before the first
//     read, M2 = made by calls that write nothing, then written, then ClearAll inside the owner).
//   - "CLQ TG Arr 1" to 3: the array store as a global of a test codeunit, ClearAll() in the test codeunit.
//   - "CLQ SI CLX Clear Tests" and "CLQ TG CLX 1" to 3: the one-Integer store "CLX Store" under a SingleInstance owner
//     and as a test codeunit global.
//   - "CLQ SI VP Tests" and "CLQ TG VP 1" to 3: a by-value codeunit parameter shares X while the owner (a
//     SingleInstance codeunit, a test codeunit) runs ClearAll or Clear(X), then writes through the parameter. The
//     result text is: parameter | x before the write || parameter | x after the write.
//   Measured on BC 29.0 (Linux): in every owner and every store below, ClearAll resets the store's instance in place,
//   as in ClearSharedCodeunitSIOwner.al: an alias (local variable, by-value parameter, wrapper alias) stays on the
//   same instance, temporary rows stay, RecordRefs close, Integers (also the extra Integer of "CLQ Store Plus", the
//   wrapper's Integer and the owner's own) go to 0, and the next write through either side shows through both.
//   - Array store: an alias that wrote nothing sees a later write through X and X sees it (rows1=1 rows2=1); written
//     through the holder, ClearAll keeps rows1=1 rows2=1 and the next write adds to them (2). The same under a
//     SingleInstance owner and as a test codeunit global; under a SingleInstance owner the store never made and the
//     store made by calls that write nothing read the same in a later test method (fresh), and the rows kept by a
//     ClearAll inside the owner are still there in the next test method.
//   - "CLX Store" under a SingleInstance owner and as a test codeunit global: one instance. An alias that wrote
//     nothing: Y.Set(5) after the ClearAll reads 5 through X too; an alias that wrote 3 reads 0 through both after
//     the ClearAll, then 5 through both; X written, ClearAll gives 0.
//   - Owners: a codeunit with Subtype = Normal, a codeunit with TableNo and a report give the same values as the plain
//     holder. Held one level deeper (holder -> wrapper -> store), ClearAll in the holder resets the wrapper's globals
//     and the store in place, seen through a store alias and a wrapper alias. array[2] of "CLB Store": element 1 is
//     reset in place (rows kept), element 2 stays fresh. In a report, an array of temporary records and a single
//     temporary record keep their rows after ClearAll in the report.
//   - By-value parameter P of X: after ClearAll in a SingleInstance owner or in a test codeunit P and X stay one
//     instance (a write through P shows through X, rows kept when X was written). After Clear(X) X gets a fresh
//     instance and P keeps the old one.
// BC versions: 27, 28, 29

codeunit 77173 "CLQ Normal Owner"
{
    Subtype = Normal;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77174 "CLQ TableNo Owner"
{
    TableNo = "CLB Row";

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

report 77175 "CLQ Report Owner"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77196 "CLQ Store Plus"
{
    var
        Rows: Record "CLB Row" temporary;
        Refs: array[2, 3] of RecordRef;
        Ints: array[3] of Integer;
        N: Integer;

    procedure Write(V: Integer)
    begin
        Rows.Init();
        Rows."No." := V;
        Rows.Insert();
        if Refs[1, 1].Number = 0 then
            Refs[1, 1].Open(Database::"CLB Row", true);
        Refs[1, 1].Init();
        Refs[1, 1].Field(1).Value := V;
        Refs[1, 1].Insert();
        Ints[1] := V;
    end;

    procedure State(): Text
    var
        RefRows: Text;
    begin
        RefRows := '-';
        if Refs[1, 1].Number <> 0 then
            RefRows := Format(Refs[1, 1].Count());
        exit(StrSubstNo('rows=%1 ref11=%2 refrows=%3 ref23=%4 int1=%5 int3=%6 n=%7',
            Rows.Count(), Refs[1, 1].Number, RefRows, Refs[2, 3].Number, Ints[1], Ints[3], N));
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;
}

codeunit 77197 "CLQ Plus Holder"
{
    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;

    procedure SetXN(V: Integer)
    begin
        X.SetN(V);
    end;
}

codeunit 77198 "CLQ Wrapper"
{
    var
        X: Codeunit "CLB Store";
        WCnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetWCnt(V: Integer)
    begin
        WCnt := V;
    end;

    procedure GetWCnt(): Integer
    begin
        exit(WCnt);
    end;
}

codeunit 77199 "CLQ Deep Holder"
{
    var
        W: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        W.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(W.StateX());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        W.ShareAlias(Y);
    end;

    procedure ShareWrapper(var V: Codeunit "CLQ Wrapper")
    begin
        V := W;
    end;

    procedure SetWCnt(V: Integer)
    begin
        W.SetWCnt(V);
    end;

    procedure GetWCnt(): Integer
    begin
        exit(W.GetWCnt());
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77200 "CLQ Arr2 Holder"
{
    var
        Xs: array[2] of Codeunit "CLB Store";

    procedure WriteX(E: Integer; V: Integer)
    begin
        Xs[E].Write(V);
    end;

    procedure StateX(E: Integer): Text
    begin
        exit(Xs[E].State());
    end;

    procedure ShareAlias(E: Integer; var Y: Codeunit "CLB Store")
    begin
        Y := Xs[E];
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;
}

report 77201 "CLQ Report Rows"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    var
        Rows: array[2] of Record "CLB Row" temporary;
        One: Record "CLB Row" temporary;

    procedure Write(E: Integer; V: Integer)
    begin
        Rows[E].Init();
        Rows[E]."No." := V;
        Rows[E].Insert();
    end;

    procedure WriteOne(V: Integer)
    begin
        One.Init();
        One."No." := V;
        One.Insert();
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('rows1=%1 rows2=%2 one=%3', Rows[1].Count(), Rows[2].Count(), One.Count()));
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;
}

codeunit 77176 "CLQ Owner Kind Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ArrStore_ClearAll_UnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
    begin
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(1, 5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('alias', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('x after write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('alias after write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Verify();
    end;

    [Test]
    procedure ArrStore_ClearAll_InHolder_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLS Arr Holder";
    begin
        H.WriteX(1, 3);
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        H.WriteX(2, 4);
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('x', 'rows1=1 rows2=1 ref1=0 refrows=- int1=0');
        Observer.Expect('x after write', 'rows1=2 rows2=2 ref1=75586 refrows=1 int1=4');
        Observer.Verify();
    end;

    [Test]
    procedure ArrStore_ClearAll_InHolder_Unused()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLS Arr Holder";
    begin
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        H.WriteX(1, 5);
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('x', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('x after write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Verify();
    end;

    [Test]
    procedure NormalSubtypeOwner_Written_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ Normal Owner";
    begin
        H.WriteX(3);
        H.SetCnt(4);
        H.ClearAllGlobals();
        Observer.Observe('cnt', Format(H.GetCnt()));
        Observer.Observe('x', H.StateX());
        H.WriteX(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalSubtypeOwner_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ Normal Owner";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalSubtypeOwner_UnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ Normal Owner";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoOwner_Written_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ TableNo Owner";
    begin
        H.WriteX(3);
        H.SetCnt(4);
        H.ClearAllGlobals();
        Observer.Observe('cnt', Format(H.GetCnt()));
        Observer.Observe('x', H.StateX());
        H.WriteX(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoOwner_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ TableNo Owner";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoOwner_UnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ TableNo Owner";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportOwner_Written_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Report "CLQ Report Owner";
    begin
        H.WriteX(3);
        H.SetCnt(4);
        H.ClearAllGlobals();
        Observer.Observe('cnt', Format(H.GetCnt()));
        Observer.Observe('x', H.StateX());
        H.WriteX(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportOwner_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Report "CLQ Report Owner";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportOwner_UnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Report "CLQ Report Owner";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure StorePlus_Written_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ Plus Holder";
    begin
        H.WriteX(3);
        H.SetXN(6);
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        H.WriteX(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure StorePlus_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ Plus Holder";
        Y: Codeunit "CLQ Store Plus";
    begin
        H.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure StorePlus_UnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ Plus Holder";
        Y: Codeunit "CLQ Store Plus";
    begin
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Deep_Written_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ Deep Holder";
    begin
        H.WriteX(3);
        H.SetWCnt(2);
        H.SetCnt(4);
        H.ClearAllGlobals();
        Observer.Observe('cnt', Format(H.GetCnt()));
        Observer.Observe('wrapper cnt', Format(H.GetWCnt()));
        Observer.Observe('x', H.StateX());
        H.WriteX(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('cnt', '0');
        Observer.Expect('wrapper cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Deep_StoreAliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ Deep Holder";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Deep_WrapperAliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ Deep Holder";
        V: Codeunit "CLQ Wrapper";
    begin
        H.ShareWrapper(V);
        V.WriteX(3);
        V.SetWCnt(2);
        H.ClearAllGlobals();
        Observer.Observe('wrapper alias', V.StateX());
        Observer.Observe('wrapper alias cnt', Format(V.GetWCnt()));
        Observer.Observe('x', H.StateX());
        V.WriteX(5);
        Observer.Observe('wrapper alias after write', V.StateX());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('wrapper alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('wrapper alias cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('wrapper alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Arr2_Element1Written_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ Arr2 Holder";
    begin
        H.WriteX(1, 3);
        H.ClearAllGlobals();
        Observer.Observe('x1', H.StateX(1));
        Observer.Observe('x2', H.StateX(2));
        H.WriteX(1, 5);
        Observer.Observe('x1 after write', H.StateX(1));
        Observer.Observe('x2 after write', H.StateX(2));
        Observer.Expect('x1', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x2', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x1 after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x2 after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Arr2_Element1AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLQ Arr2 Holder";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(1, Y);
        Y.Write(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x1', H.StateX(1));
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x1 after write', H.StateX(1));
        Observer.Observe('x2 after write', H.StateX(2));
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x1', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x1 after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x2 after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportRows_ArrayElement1Written()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "CLQ Report Rows";
    begin
        R.Write(1, 3);
        R.WriteOne(4);
        R.ClearAllGlobals();
        Observer.Observe('state', R.State());
        R.Write(2, 5);
        Observer.Observe('state after write', R.State());
        Observer.Expect('state', 'rows1=1 rows2=1 one=1');
        Observer.Expect('state after write', 'rows1=2 rows2=2 one=1');
        Observer.Verify();
    end;
}

codeunit 77177 "CLQ SI Arr Owner 1"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure Touch()
    begin
        X.SecondNo();
        X.State();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77178 "CLQ SI Arr Owner 2"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure Touch()
    begin
        X.SecondNo();
        X.State();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77179 "CLQ SI Arr Owner 3"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure Touch()
    begin
        X.SecondNo();
        X.State();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77180 "CLQ SI Arr Clear Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIArr_ClearAll_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Owner 1";
        Y: Codeunit "CLS Arr Store";
    begin
        S.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        S.SetCnt(4);
        S.ClearAllGlobals();
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', S.StateX());
        Y.Write(2, 5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', S.StateX());
        Observer.Expect('cnt', '0');
        Observer.Expect('alias', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('x', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('alias after write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('x after write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ClearAll_Written_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Owner 2";
    begin
        S.WriteX(1, 3);
        S.ClearAllGlobals();
        Observer.Observe('x', S.StateX());
        S.WriteX(2, 4);
        Observer.Observe('x after write', S.StateX());
        Observer.Expect('x', 'rows1=1 rows2=1 ref1=0 refrows=- int1=0');
        Observer.Expect('x after write', 'rows1=2 rows2=2 ref1=75586 refrows=1 int1=4');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ClearAll_UnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Owner 3";
        Y: Codeunit "CLS Arr Store";
    begin
        S.ShareAlias(Y);
        S.ClearAllGlobals();
        Y.Write(1, 5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', S.StateX());
        Observer.Expect('alias after write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('x after write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Verify();
    end;
}

codeunit 77181 "CLQ SI Arr Life 1"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure Touch()
    begin
        X.SecondNo();
        X.State();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77182 "CLQ SI Arr Life 2"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure Touch()
    begin
        X.SecondNo();
        X.State();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77183 "CLQ SI Arr Lifetime Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure M1_Step1_OwnerOnly_XNeverMade()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Life 1";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(4);
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('start cnt', '0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;

    [Test]
    procedure M1_Step2_FirstReadOfX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Life 1";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('x', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;

    [Test]
    procedure M1_Step3_SecondReadOfX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Life 1";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure M2_Step1_MadeByCallsThatWriteNothing()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Life 2";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.Touch();
        S.SetCnt(2);
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('start cnt', '0');
        Observer.Expect('cnt', '2');
        Observer.Verify();
    end;

    [Test]
    procedure M2_Step2_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Life 2";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('x', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('cnt', '2');
        Observer.Verify();
    end;

    [Test]
    procedure M2_Step3_Write()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Life 2";
    begin
        S.WriteX(1, 3);
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=3');
        Observer.Verify();
    end;

    [Test]
    procedure M2_Step4_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Life 2";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=3');
        Observer.Verify();
    end;

    [Test]
    procedure M2_Step5_ClearAllInOwner()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Life 2";
    begin
        S.ClearAllGlobals();
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('x', 'rows1=1 rows2=1 ref1=0 refrows=- int1=0');
        Observer.Expect('cnt', '0');
        Observer.Verify();
    end;

    [Test]
    procedure M2_Step6_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI Arr Life 2";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows1=1 rows2=1 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;
}

codeunit 77184 "CLQ TG Arr 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLS Arr Store";
        GCnt: Integer;

    [Test]
    procedure ClearAll_TestGlobalArrWritten_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GX.Write(1, 3);
        GCnt := 4;
        ClearAll();
        Observer.Observe('cnt', Format(GCnt));
        Observer.Observe('x', GX.State());
        GX.Write(2, 4);
        Observer.Observe('x after write', GX.State());
        Observer.Expect('cnt', '0');
        Observer.Expect('x', 'rows1=1 rows2=1 ref1=0 refrows=- int1=0');
        Observer.Expect('x after write', 'rows1=2 rows2=2 ref1=75586 refrows=1 int1=4');
        Observer.Verify();
    end;
}

codeunit 77185 "CLQ TG Arr 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLS Arr Store";

    [Test]
    procedure ClearAll_TestGlobalArr_LocalAliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
    begin
        Y := GX;
        Y.Write(1, 3);
        ClearAll();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', GX.State());
        Y.Write(1, 5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', GX.State());
        Observer.Expect('alias', 'rows1=1 rows2=1 ref1=0 refrows=- int1=0');
        Observer.Expect('x', 'rows1=1 rows2=1 ref1=0 refrows=- int1=0');
        Observer.Expect('alias after write', 'rows1=2 rows2=2 ref1=75586 refrows=1 int1=5');
        Observer.Expect('x after write', 'rows1=2 rows2=2 ref1=75586 refrows=1 int1=5');
        Observer.Verify();
    end;
}

codeunit 77186 "CLQ TG Arr 3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLS Arr Store";

    [Test]
    procedure ClearAll_TestGlobalArrUnused_LocalAlias()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
    begin
        Y := GX;
        ClearAll();
        Y.Write(1, 5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', GX.State());
        Observer.Expect('alias after write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('x after write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Verify();
    end;
}

codeunit 77187 "CLQ SI CLX Owner 1"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure SetX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure GetX(): Integer
    begin
        exit(X.Get());
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77188 "CLQ SI CLX Owner 2"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure SetX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure GetX(): Integer
    begin
        exit(X.Get());
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77189 "CLQ SI CLX Owner 3"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure SetX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure GetX(): Integer
    begin
        exit(X.Get());
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77190 "CLQ SI CLX Clear Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SICLX_ClearAll_UnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI CLX Owner 1";
        Y: Codeunit "CLX Store";
    begin
        S.ShareAlias(Y);
        S.SetCnt(4);
        S.ClearAllGlobals();
        Y.Set(5);
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Observe('x', Format(S.GetX()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('cnt', '0');
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ClearAll_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI CLX Owner 2";
        Y: Codeunit "CLX Store";
    begin
        S.ShareAlias(Y);
        Y.Set(3);
        S.ClearAllGlobals();
        Observer.Observe('x', Format(S.GetX()));
        Observer.Observe('alias', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('x after write', Format(S.GetX()));
        Observer.Observe('alias after write', Format(Y.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '0');
        Observer.Expect('x after write', '5');
        Observer.Expect('alias after write', '5');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ClearAll_Written_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI CLX Owner 3";
    begin
        S.SetX(3);
        S.ClearAllGlobals();
        Observer.Observe('x', Format(S.GetX()));
        S.SetX(5);
        Observer.Observe('x after write', Format(S.GetX()));
        Observer.Expect('x', '0');
        Observer.Expect('x after write', '5');
        Observer.Verify();
    end;
}

codeunit 77191 "CLQ TG CLX 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLX Store";
        GCnt: Integer;

    [Test]
    procedure ClearAll_TestGlobalCLXUnused_LocalAlias()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
    begin
        Y := GX;
        GCnt := 4;
        ClearAll();
        Y.Set(5);
        Observer.Observe('cnt', Format(GCnt));
        Observer.Observe('x', Format(GX.Get()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('cnt', '0');
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;
}

codeunit 77192 "CLQ TG CLX 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLX Store";

    [Test]
    procedure ClearAll_TestGlobalCLX_LocalAliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
    begin
        Y := GX;
        Y.Set(3);
        ClearAll();
        Observer.Observe('x', Format(GX.Get()));
        Observer.Observe('alias', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('x after write', Format(GX.Get()));
        Observer.Observe('alias after write', Format(Y.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '0');
        Observer.Expect('x after write', '5');
        Observer.Expect('alias after write', '5');
        Observer.Verify();
    end;
}

codeunit 77193 "CLQ TG CLX 3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLX Store";

    [Test]
    procedure ClearAll_TestGlobalCLXWritten_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GX.Set(3);
        ClearAll();
        Observer.Observe('x', Format(GX.Get()));
        GX.Set(5);
        Observer.Observe('x after write', Format(GX.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('x after write', '5');
        Observer.Verify();
    end;
}

codeunit 77202 "CLQ SI VP Owner 1"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;

    procedure ValueParam(UseClearAll: Boolean): Text
    begin
        exit(ClearThenWrite(X, UseClearAll));
    end;

    local procedure ClearThenWrite(P: Codeunit "CLB Store"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(X);
        Before := P.State() + ' | x: ' + X.State();
        P.Write(5);
        exit(Before + ' || ' + P.State() + ' | x: ' + X.State());
    end;
}

codeunit 77203 "CLQ SI VP Owner 2"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;

    procedure ValueParam(UseClearAll: Boolean): Text
    begin
        exit(ClearThenWrite(X, UseClearAll));
    end;

    local procedure ClearThenWrite(P: Codeunit "CLB Store"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(X);
        Before := P.State() + ' | x: ' + X.State();
        P.Write(5);
        exit(Before + ' || ' + P.State() + ' | x: ' + X.State());
    end;
}

codeunit 77204 "CLQ SI VP Owner 3"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;

    procedure ValueParam(UseClearAll: Boolean): Text
    begin
        exit(ClearThenWrite(X, UseClearAll));
    end;

    local procedure ClearThenWrite(P: Codeunit "CLB Store"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(X);
        Before := P.State() + ' | x: ' + X.State();
        P.Write(5);
        exit(Before + ' || ' + P.State() + ' | x: ' + X.State());
    end;
}

codeunit 77205 "CLQ SI VP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIValueParam_ClearAll_Unused()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI VP Owner 1";
    begin
        Observer.Observe('result', S.ValueParam(true));
        Observer.Observe('x', S.StateX());
        Observer.Expect('result', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIValueParam_ClearAll_Written()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI VP Owner 2";
    begin
        S.WriteX(3);
        Observer.Observe('result', S.ValueParam(true));
        Observer.Observe('x', S.StateX());
        Observer.Expect('result', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIValueParam_Clear_Unused()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLQ SI VP Owner 3";
    begin
        Observer.Observe('result', S.ValueParam(false));
        Observer.Observe('x', S.StateX());
        Observer.Expect('result', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;
}

codeunit 77206 "CLQ TG VP 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLB Store";

    [Test]
    procedure TestGlobalValueParam_ClearAll_Unused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('result', ClearThenWrite(GX, true));
        Observer.Observe('x', GX.State());
        Observer.Expect('result', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    local procedure ClearThenWrite(P: Codeunit "CLB Store"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(GX);
        Before := P.State() + ' | x: ' + GX.State();
        P.Write(5);
        exit(Before + ' || ' + P.State() + ' | x: ' + GX.State());
    end;
}

codeunit 77207 "CLQ TG VP 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLB Store";

    [Test]
    procedure TestGlobalValueParam_ClearAll_Written()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GX.Write(3);
        Observer.Observe('result', ClearThenWrite(GX, true));
        Observer.Observe('x', GX.State());
        Observer.Expect('result', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    local procedure ClearThenWrite(P: Codeunit "CLB Store"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(GX);
        Before := P.State() + ' | x: ' + GX.State();
        P.Write(5);
        exit(Before + ' || ' + P.State() + ' | x: ' + GX.State());
    end;
}

codeunit 77208 "CLQ TG VP 3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLB Store";

    [Test]
    procedure TestGlobalValueParam_Clear_Unused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('result', ClearThenWrite(GX, false));
        Observer.Observe('x', GX.State());
        Observer.Expect('result', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    local procedure ClearThenWrite(P: Codeunit "CLB Store"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(GX);
        Before := P.State() + ' | x: ' + GX.State();
        P.Write(5);
        exit(Before + ' || ' + P.State() + ' | x: ' + GX.State());
    end;
}
