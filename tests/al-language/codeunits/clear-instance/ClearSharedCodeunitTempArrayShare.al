// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586) of ClearSharedCodeunitTempRef.al;
//   self-contained objects 77225 to 77234
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: ClearAll in the codeunit that holds an array of temporary records as a direct global.
//   - *SharedByCopy*: element 1 of an array[2] of temporary records (Arr) or a single temporary record (One), never
//     written or written once (1), is shared with a temporary record R of the test by R.Copy(A[1], true); then
//     ClearAll in the owner. The test reads the owner (a1 / a2 = rows counted through elements 1 and 2) and R,
//     inserts through R (10), writes through the owner element 1 (2) and element 2 (3), reading after each step.
//     Owner: a plain codeunit ("CLT Arr Owner") and a SingleInstance codeunit (one per test, "CLT SI Arr Owner 1"
//     to 4).
//   - TwoDim*: an array[2, 2] of temporary records, written through [1,1] or never written, then ClearAll; b11 to b22
//     = rows counted through each element. As a direct global of the owner (plain, and SingleInstance "CLT SI Arr
//     Owner 5"), and inside a store codeunit ("CLT B2 Store", with an array of Integer) held by a plain holder,
//     without and with an alias that wrote before.
//   Measured on BC 29.0 (Linux), plain and SingleInstance owner alike:
//   - After ClearAll the array element and the single temporary record keep the table they share with R, written or
//     not: R reads the kept rows (0 or 1), an insert through R shows through the owner, and a write through the owner
//     (element 1 or element 2) shows in R. The elements of the array read one table (a1 = a2).
//   - The elements of an array[2, 2] of temporary records also read one table (a write through [1,1] gives 1 through
//     every element). ClearAll keeps the rows (1, then 2 after the next write) as a direct global of the owner (plain
//     and SingleInstance) and inside a store under a plain holder; there the store's Integer goes to 0 and an alias
//     that wrote before stays on the same instance. Never written, it reads 0 after ClearAll.
// BC versions: 27, 28, 29

codeunit 77228 "CLT SI Arr Owner 1"
{
    SingleInstance = true;

    var
        A: array[2] of Record "CLB Row" temporary;
        One: Record "CLB Row" temporary;
        B: array[2, 2] of Record "CLB Row" temporary;
        Cnt: Integer;

    procedure ShareA1(var R: Record "CLB Row" temporary)
    begin
        R.Copy(A[1], true);
    end;

    procedure ShareOne(var R: Record "CLB Row" temporary)
    begin
        R.Copy(One, true);
    end;

    procedure WriteA(I: Integer; V: Integer)
    begin
        A[I].Init();
        A[I]."No." := V;
        A[I].Insert();
    end;

    procedure WriteOne(V: Integer)
    begin
        One.Init();
        One."No." := V;
        One.Insert();
    end;

    procedure WriteB(I: Integer; J: Integer; V: Integer)
    begin
        B[I, J].Init();
        B[I, J]."No." := V;
        B[I, J].Insert();
    end;

    procedure StateA(): Text
    begin
        exit(StrSubstNo('a1=%1 a2=%2', A[1].Count(), A[2].Count()));
    end;

    procedure StateOne(): Text
    begin
        exit(StrSubstNo('one=%1', One.Count()));
    end;

    procedure StateB(): Text
    begin
        exit(StrSubstNo('b11=%1 b12=%2 b21=%3 b22=%4', B[1, 1].Count(), B[1, 2].Count(), B[2, 1].Count(), B[2, 2].Count()));
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

codeunit 77229 "CLT SI Arr Owner 2"
{
    SingleInstance = true;

    var
        A: array[2] of Record "CLB Row" temporary;
        One: Record "CLB Row" temporary;
        B: array[2, 2] of Record "CLB Row" temporary;
        Cnt: Integer;

    procedure ShareA1(var R: Record "CLB Row" temporary)
    begin
        R.Copy(A[1], true);
    end;

    procedure ShareOne(var R: Record "CLB Row" temporary)
    begin
        R.Copy(One, true);
    end;

    procedure WriteA(I: Integer; V: Integer)
    begin
        A[I].Init();
        A[I]."No." := V;
        A[I].Insert();
    end;

    procedure WriteOne(V: Integer)
    begin
        One.Init();
        One."No." := V;
        One.Insert();
    end;

    procedure WriteB(I: Integer; J: Integer; V: Integer)
    begin
        B[I, J].Init();
        B[I, J]."No." := V;
        B[I, J].Insert();
    end;

    procedure StateA(): Text
    begin
        exit(StrSubstNo('a1=%1 a2=%2', A[1].Count(), A[2].Count()));
    end;

    procedure StateOne(): Text
    begin
        exit(StrSubstNo('one=%1', One.Count()));
    end;

    procedure StateB(): Text
    begin
        exit(StrSubstNo('b11=%1 b12=%2 b21=%3 b22=%4', B[1, 1].Count(), B[1, 2].Count(), B[2, 1].Count(), B[2, 2].Count()));
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

codeunit 77230 "CLT SI Arr Owner 3"
{
    SingleInstance = true;

    var
        A: array[2] of Record "CLB Row" temporary;
        One: Record "CLB Row" temporary;
        B: array[2, 2] of Record "CLB Row" temporary;
        Cnt: Integer;

    procedure ShareA1(var R: Record "CLB Row" temporary)
    begin
        R.Copy(A[1], true);
    end;

    procedure ShareOne(var R: Record "CLB Row" temporary)
    begin
        R.Copy(One, true);
    end;

    procedure WriteA(I: Integer; V: Integer)
    begin
        A[I].Init();
        A[I]."No." := V;
        A[I].Insert();
    end;

    procedure WriteOne(V: Integer)
    begin
        One.Init();
        One."No." := V;
        One.Insert();
    end;

    procedure WriteB(I: Integer; J: Integer; V: Integer)
    begin
        B[I, J].Init();
        B[I, J]."No." := V;
        B[I, J].Insert();
    end;

    procedure StateA(): Text
    begin
        exit(StrSubstNo('a1=%1 a2=%2', A[1].Count(), A[2].Count()));
    end;

    procedure StateOne(): Text
    begin
        exit(StrSubstNo('one=%1', One.Count()));
    end;

    procedure StateB(): Text
    begin
        exit(StrSubstNo('b11=%1 b12=%2 b21=%3 b22=%4', B[1, 1].Count(), B[1, 2].Count(), B[2, 1].Count(), B[2, 2].Count()));
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

codeunit 77231 "CLT SI Arr Owner 4"
{
    SingleInstance = true;

    var
        A: array[2] of Record "CLB Row" temporary;
        One: Record "CLB Row" temporary;
        B: array[2, 2] of Record "CLB Row" temporary;
        Cnt: Integer;

    procedure ShareA1(var R: Record "CLB Row" temporary)
    begin
        R.Copy(A[1], true);
    end;

    procedure ShareOne(var R: Record "CLB Row" temporary)
    begin
        R.Copy(One, true);
    end;

    procedure WriteA(I: Integer; V: Integer)
    begin
        A[I].Init();
        A[I]."No." := V;
        A[I].Insert();
    end;

    procedure WriteOne(V: Integer)
    begin
        One.Init();
        One."No." := V;
        One.Insert();
    end;

    procedure WriteB(I: Integer; J: Integer; V: Integer)
    begin
        B[I, J].Init();
        B[I, J]."No." := V;
        B[I, J].Insert();
    end;

    procedure StateA(): Text
    begin
        exit(StrSubstNo('a1=%1 a2=%2', A[1].Count(), A[2].Count()));
    end;

    procedure StateOne(): Text
    begin
        exit(StrSubstNo('one=%1', One.Count()));
    end;

    procedure StateB(): Text
    begin
        exit(StrSubstNo('b11=%1 b12=%2 b21=%3 b22=%4', B[1, 1].Count(), B[1, 2].Count(), B[2, 1].Count(), B[2, 2].Count()));
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

codeunit 77232 "CLT SI Arr Owner 5"
{
    SingleInstance = true;

    var
        A: array[2] of Record "CLB Row" temporary;
        One: Record "CLB Row" temporary;
        B: array[2, 2] of Record "CLB Row" temporary;
        Cnt: Integer;

    procedure ShareA1(var R: Record "CLB Row" temporary)
    begin
        R.Copy(A[1], true);
    end;

    procedure ShareOne(var R: Record "CLB Row" temporary)
    begin
        R.Copy(One, true);
    end;

    procedure WriteA(I: Integer; V: Integer)
    begin
        A[I].Init();
        A[I]."No." := V;
        A[I].Insert();
    end;

    procedure WriteOne(V: Integer)
    begin
        One.Init();
        One."No." := V;
        One.Insert();
    end;

    procedure WriteB(I: Integer; J: Integer; V: Integer)
    begin
        B[I, J].Init();
        B[I, J]."No." := V;
        B[I, J].Insert();
    end;

    procedure StateA(): Text
    begin
        exit(StrSubstNo('a1=%1 a2=%2', A[1].Count(), A[2].Count()));
    end;

    procedure StateOne(): Text
    begin
        exit(StrSubstNo('one=%1', One.Count()));
    end;

    procedure StateB(): Text
    begin
        exit(StrSubstNo('b11=%1 b12=%2 b21=%3 b22=%4', B[1, 1].Count(), B[1, 2].Count(), B[2, 1].Count(), B[2, 2].Count()));
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

codeunit 77225 "CLT Arr Owner"
{
    var
        A: array[2] of Record "CLB Row" temporary;
        One: Record "CLB Row" temporary;
        B: array[2, 2] of Record "CLB Row" temporary;
        Cnt: Integer;

    procedure ShareA1(var R: Record "CLB Row" temporary)
    begin
        R.Copy(A[1], true);
    end;

    procedure ShareOne(var R: Record "CLB Row" temporary)
    begin
        R.Copy(One, true);
    end;

    procedure WriteA(I: Integer; V: Integer)
    begin
        A[I].Init();
        A[I]."No." := V;
        A[I].Insert();
    end;

    procedure WriteOne(V: Integer)
    begin
        One.Init();
        One."No." := V;
        One.Insert();
    end;

    procedure WriteB(I: Integer; J: Integer; V: Integer)
    begin
        B[I, J].Init();
        B[I, J]."No." := V;
        B[I, J].Insert();
    end;

    procedure StateA(): Text
    begin
        exit(StrSubstNo('a1=%1 a2=%2', A[1].Count(), A[2].Count()));
    end;

    procedure StateOne(): Text
    begin
        exit(StrSubstNo('one=%1', One.Count()));
    end;

    procedure StateB(): Text
    begin
        exit(StrSubstNo('b11=%1 b12=%2 b21=%3 b22=%4', B[1, 1].Count(), B[1, 2].Count(), B[2, 1].Count(), B[2, 2].Count()));
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

codeunit 77226 "CLT B2 Store"
{
    var
        B: array[2, 2] of Record "CLB Row" temporary;
        Ints: array[2] of Integer;

    procedure Write(I: Integer; J: Integer; V: Integer)
    begin
        B[I, J].Init();
        B[I, J]."No." := V;
        B[I, J].Insert();
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('b11=%1 b12=%2 b21=%3 b22=%4 int1=%5', B[1, 1].Count(), B[1, 2].Count(), B[2, 1].Count(), B[2, 2].Count(), Ints[1]));
    end;

    procedure SetInt(V: Integer)
    begin
        Ints[1] := V;
    end;
}

codeunit 77227 "CLT B2 Holder"
{
    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    procedure WriteX(I: Integer; J: Integer; V: Integer)
    begin
        X.Write(I, J, V);
    end;

    procedure SetIntX(V: Integer)
    begin
        X.SetInt(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;
}

codeunit 77233 "CLT Temp Array Share Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ArrNever_SharedByCopy_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT Arr Owner";
        R: Record "CLB Row" temporary;
    begin
        O.ShareA1(R);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateA());
        Observer.Observe('cnt', Format(O.GetCnt()));
        Observer.Observe('r', Format(R.Count()));
        R.Init();
        R."No." := 10;
        R.Insert();
        Observer.Observe('owner after r insert', O.StateA());
        Observer.Observe('r after r insert', Format(R.Count()));
        O.WriteA(1, 2);
        Observer.Observe('owner after owner write', O.StateA());
        Observer.Observe('r after owner write', Format(R.Count()));
        O.WriteA(2, 3);
        Observer.Observe('owner after element 2 write', O.StateA());
        Observer.Observe('r after element 2 write', Format(R.Count()));
        Observer.Expect('owner', 'a1=0 a2=0');
        Observer.Expect('cnt', '0');
        Observer.Expect('r', '0');
        Observer.Expect('owner after r insert', 'a1=1 a2=1');
        Observer.Expect('r after r insert', '1');
        Observer.Expect('owner after owner write', 'a1=2 a2=2');
        Observer.Expect('r after owner write', '2');
        Observer.Expect('owner after element 2 write', 'a1=3 a2=3');
        Observer.Expect('r after element 2 write', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ArrWritten_SharedByCopy_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT Arr Owner";
        R: Record "CLB Row" temporary;
    begin
        O.WriteA(1, 1);
        O.ShareA1(R);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateA());
        Observer.Observe('cnt', Format(O.GetCnt()));
        Observer.Observe('r', Format(R.Count()));
        R.Init();
        R."No." := 10;
        R.Insert();
        Observer.Observe('owner after r insert', O.StateA());
        Observer.Observe('r after r insert', Format(R.Count()));
        O.WriteA(1, 2);
        Observer.Observe('owner after owner write', O.StateA());
        Observer.Observe('r after owner write', Format(R.Count()));
        O.WriteA(2, 3);
        Observer.Observe('owner after element 2 write', O.StateA());
        Observer.Observe('r after element 2 write', Format(R.Count()));
        Observer.Expect('owner', 'a1=1 a2=1');
        Observer.Expect('cnt', '0');
        Observer.Expect('r', '1');
        Observer.Expect('owner after r insert', 'a1=2 a2=2');
        Observer.Expect('r after r insert', '2');
        Observer.Expect('owner after owner write', 'a1=3 a2=3');
        Observer.Expect('r after owner write', '3');
        Observer.Expect('owner after element 2 write', 'a1=4 a2=4');
        Observer.Expect('r after element 2 write', '4');
        Observer.Verify();
    end;

    [Test]
    procedure OneNever_SharedByCopy_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT Arr Owner";
        R: Record "CLB Row" temporary;
    begin
        O.ShareOne(R);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateOne());
        Observer.Observe('cnt', Format(O.GetCnt()));
        Observer.Observe('r', Format(R.Count()));
        R.Init();
        R."No." := 10;
        R.Insert();
        Observer.Observe('owner after r insert', O.StateOne());
        Observer.Observe('r after r insert', Format(R.Count()));
        O.WriteOne(2);
        Observer.Observe('owner after owner write', O.StateOne());
        Observer.Observe('r after owner write', Format(R.Count()));
        Observer.Expect('owner', 'one=0');
        Observer.Expect('cnt', '0');
        Observer.Expect('r', '0');
        Observer.Expect('owner after r insert', 'one=1');
        Observer.Expect('r after r insert', '1');
        Observer.Expect('owner after owner write', 'one=2');
        Observer.Expect('r after owner write', '2');
        Observer.Verify();
    end;

    [Test]
    procedure OneWritten_SharedByCopy_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT Arr Owner";
        R: Record "CLB Row" temporary;
    begin
        O.WriteOne(1);
        O.ShareOne(R);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateOne());
        Observer.Observe('cnt', Format(O.GetCnt()));
        Observer.Observe('r', Format(R.Count()));
        R.Init();
        R."No." := 10;
        R.Insert();
        Observer.Observe('owner after r insert', O.StateOne());
        Observer.Observe('r after r insert', Format(R.Count()));
        O.WriteOne(2);
        Observer.Observe('owner after owner write', O.StateOne());
        Observer.Observe('r after owner write', Format(R.Count()));
        Observer.Expect('owner', 'one=1');
        Observer.Expect('cnt', '0');
        Observer.Expect('r', '1');
        Observer.Expect('owner after r insert', 'one=2');
        Observer.Expect('r after r insert', '2');
        Observer.Expect('owner after owner write', 'one=3');
        Observer.Expect('r after owner write', '3');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDimWritten_OwnerGlobal_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT Arr Owner";
    begin
        O.WriteB(1, 1, 1);
        Observer.Observe('owner before', O.StateB());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateB());
        O.WriteB(2, 2, 2);
        Observer.Observe('owner after write', O.StateB());
        Observer.Expect('owner before', 'b11=1 b12=1 b21=1 b22=1');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1');
        Observer.Expect('owner after write', 'b11=2 b12=2 b21=2 b22=2');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDimNever_OwnerGlobal_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT Arr Owner";
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateB());
        O.WriteB(2, 2, 2);
        Observer.Observe('owner after write', O.StateB());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0');
        Observer.Expect('owner after write', 'b11=1 b12=1 b21=1 b22=1');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDimWritten_InStore_ClearAll_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLT B2 Holder";
    begin
        H.WriteX(1, 1, 1);
        H.SetIntX(7);
        Observer.Observe('x before', H.StateX());
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        H.WriteX(2, 2, 2);
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('x before', 'b11=1 b12=1 b21=1 b22=1 int1=7');
        Observer.Expect('x', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('x after write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDimWritten_InStore_ClearAll_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLT B2 Holder";
        Y: Codeunit "CLT B2 Store";
    begin
        H.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Y.Write(2, 2, 2);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('alias', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('x', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('alias after write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('x after write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;
}

codeunit 77234 "CLT SI Temp Array Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIArrNever_SharedByCopy_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT SI Arr Owner 1";
        R: Record "CLB Row" temporary;
    begin
        O.ShareA1(R);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateA());
        Observer.Observe('cnt', Format(O.GetCnt()));
        Observer.Observe('r', Format(R.Count()));
        R.Init();
        R."No." := 10;
        R.Insert();
        Observer.Observe('owner after r insert', O.StateA());
        Observer.Observe('r after r insert', Format(R.Count()));
        O.WriteA(1, 2);
        Observer.Observe('owner after owner write', O.StateA());
        Observer.Observe('r after owner write', Format(R.Count()));
        O.WriteA(2, 3);
        Observer.Observe('owner after element 2 write', O.StateA());
        Observer.Observe('r after element 2 write', Format(R.Count()));
        Observer.Expect('owner', 'a1=0 a2=0');
        Observer.Expect('cnt', '0');
        Observer.Expect('r', '0');
        Observer.Expect('owner after r insert', 'a1=1 a2=1');
        Observer.Expect('r after r insert', '1');
        Observer.Expect('owner after owner write', 'a1=2 a2=2');
        Observer.Expect('r after owner write', '2');
        Observer.Expect('owner after element 2 write', 'a1=3 a2=3');
        Observer.Expect('r after element 2 write', '3');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrWritten_SharedByCopy_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT SI Arr Owner 2";
        R: Record "CLB Row" temporary;
    begin
        O.WriteA(1, 1);
        O.ShareA1(R);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateA());
        Observer.Observe('cnt', Format(O.GetCnt()));
        Observer.Observe('r', Format(R.Count()));
        R.Init();
        R."No." := 10;
        R.Insert();
        Observer.Observe('owner after r insert', O.StateA());
        Observer.Observe('r after r insert', Format(R.Count()));
        O.WriteA(1, 2);
        Observer.Observe('owner after owner write', O.StateA());
        Observer.Observe('r after owner write', Format(R.Count()));
        O.WriteA(2, 3);
        Observer.Observe('owner after element 2 write', O.StateA());
        Observer.Observe('r after element 2 write', Format(R.Count()));
        Observer.Expect('owner', 'a1=1 a2=1');
        Observer.Expect('cnt', '0');
        Observer.Expect('r', '1');
        Observer.Expect('owner after r insert', 'a1=2 a2=2');
        Observer.Expect('r after r insert', '2');
        Observer.Expect('owner after owner write', 'a1=3 a2=3');
        Observer.Expect('r after owner write', '3');
        Observer.Expect('owner after element 2 write', 'a1=4 a2=4');
        Observer.Expect('r after element 2 write', '4');
        Observer.Verify();
    end;

    [Test]
    procedure SIOneNever_SharedByCopy_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT SI Arr Owner 3";
        R: Record "CLB Row" temporary;
    begin
        O.ShareOne(R);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateOne());
        Observer.Observe('cnt', Format(O.GetCnt()));
        Observer.Observe('r', Format(R.Count()));
        R.Init();
        R."No." := 10;
        R.Insert();
        Observer.Observe('owner after r insert', O.StateOne());
        Observer.Observe('r after r insert', Format(R.Count()));
        O.WriteOne(2);
        Observer.Observe('owner after owner write', O.StateOne());
        Observer.Observe('r after owner write', Format(R.Count()));
        Observer.Expect('owner', 'one=0');
        Observer.Expect('cnt', '0');
        Observer.Expect('r', '0');
        Observer.Expect('owner after r insert', 'one=1');
        Observer.Expect('r after r insert', '1');
        Observer.Expect('owner after owner write', 'one=2');
        Observer.Expect('r after owner write', '2');
        Observer.Verify();
    end;

    [Test]
    procedure SIOneWritten_SharedByCopy_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT SI Arr Owner 4";
        R: Record "CLB Row" temporary;
    begin
        O.WriteOne(1);
        O.ShareOne(R);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateOne());
        Observer.Observe('cnt', Format(O.GetCnt()));
        Observer.Observe('r', Format(R.Count()));
        R.Init();
        R."No." := 10;
        R.Insert();
        Observer.Observe('owner after r insert', O.StateOne());
        Observer.Observe('r after r insert', Format(R.Count()));
        O.WriteOne(2);
        Observer.Observe('owner after owner write', O.StateOne());
        Observer.Observe('r after owner write', Format(R.Count()));
        Observer.Expect('owner', 'one=1');
        Observer.Expect('cnt', '0');
        Observer.Expect('r', '1');
        Observer.Expect('owner after r insert', 'one=2');
        Observer.Expect('r after r insert', '2');
        Observer.Expect('owner after owner write', 'one=3');
        Observer.Expect('r after owner write', '3');
        Observer.Verify();
    end;

    [Test]
    procedure SITwoDimWritten_OwnerGlobal_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT SI Arr Owner 5";
    begin
        O.WriteB(1, 1, 1);
        Observer.Observe('owner before', O.StateB());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateB());
        O.WriteB(2, 2, 2);
        Observer.Observe('owner after write', O.StateB());
        Observer.Expect('owner before', 'b11=1 b12=1 b21=1 b22=1');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1');
        Observer.Expect('owner after write', 'b11=2 b12=2 b21=2 b22=2');
        Observer.Verify();
    end;
}
