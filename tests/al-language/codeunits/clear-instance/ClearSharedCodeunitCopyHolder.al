// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586) of ClearSharedCodeunitTempRef.al;
//   "CLR Caller" (77213) of ClearSharedCodeunitSetterOwner.al; "CLV Data", "CLV Post Owner U", "CLV Post Caller U" of
//   ClearSharedCodeunitStoreShapes.al; self-contained objects 77260 to 77265
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: a temporary table of a codeunit shared by Copy(x, true), then ClearAll.
//   - ArrEl2_TestLocal_*: element 2 of an array[2] of temporary records ("CLV Arr Owner", and SingleInstance owners
//     "CLV SI Arr Owner 1" to 3) shared with a temporary record R of the test by R.Copy(A[2], true); written once (1)
//     or never; ClearAll in the owner. a1 / a2 = rows counted through elements 1 and 2.
//   - *_HolderGlobal_*: the sharer is the global R of another codeunit ("CLV Rec Holder"), shared from element 1 or 2
//     of the array, from a single temporary record (One), from T1 of "CLV Table Store" held by "CLV Post Owner U"
//     through a setter, or from the temporary record of "CLR Register" held by "CLR Caller" and handed to its owners;
//     ClearAll in the owner. *_HolderClears: the same share, ClearAll in the holder (the sharer side).
//   Measured on BC 29.0 (Linux): the elements of an array of temporary records read one table (a1 = a2). A
//   Copy(x, true) share stays shared through ClearAll in the owner, whichever element was shared (1 or 2), for a
//   single temporary record and for the register's temporary record, for a sharer that is a test local or another
//   codeunit's global, and for plain and SingleInstance owners: rows written before stay (1, or 2 for a register),
//   never written reads 0, and a write through either side shows through the other. The owner's Integer goes to 0.
//   ClearAll in the holder (the sharer side) leaves the owner as it was (its Integer and the register's marks stay);
//   the holder's R still shares the table (rows and writes cross both ways), the holder's own Integer goes to 0.
// BC versions: 27, 28, 29

interface "CLV Arr Share"
{
    procedure ShareA(Idx: Integer; var R: Record "CLB Row" temporary);
    procedure ShareOne(var R: Record "CLB Row" temporary);
}

codeunit 77260 "CLV Arr Owner" implements "CLV Arr Share"
{
    var
        A: array[2] of Record "CLB Row" temporary;
        One: Record "CLB Row" temporary;
        Cnt: Integer;

    procedure ShareA(Idx: Integer; var R: Record "CLB Row" temporary)
    begin
        R.Copy(A[Idx], true);
    end;

    procedure ShareOne(var R: Record "CLB Row" temporary)
    begin
        R.Copy(One, true);
    end;

    procedure WriteA(Idx: Integer; V: Integer)
    begin
        A[Idx].Init();
        A[Idx]."No." := V;
        A[Idx].Insert();
    end;

    procedure WriteOne(V: Integer)
    begin
        One.Init();
        One."No." := V;
        One.Insert();
    end;

    procedure State(): Text
    begin
        exit('a1=' + Format(A[1].Count()) + ' a2=' + Format(A[2].Count()) + ' one=' + Format(One.Count()) + ' cnt=' + Format(Cnt));
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;
}

codeunit 77261 "CLV Rec Holder"
{
    var
        R: Record "CLB Row" temporary;
        Cnt: Integer;

    procedure TakeA(O: Interface "CLV Arr Share"; Idx: Integer)
    begin
        O.ShareA(Idx, R);
        Cnt := 1;
    end;

    procedure TakeOne(O: Interface "CLV Arr Share")
    begin
        O.ShareOne(R);
        Cnt := 1;
    end;

    procedure TakeReg(var O: Codeunit "CLV Post Owner U")
    begin
        O.ShareT1(R);
        Cnt := 1;
    end;

    procedure TakeClr(var C: Codeunit "CLR Caller")
    begin
        C.ShareRows(R);
        Cnt := 1;
    end;

    procedure Write(V: Integer)
    begin
        R.Init();
        R."No." := V;
        R.Insert();
    end;

    procedure State(): Text
    begin
        exit('r=' + Format(R.Count()) + ' hcnt=' + Format(Cnt));
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;
}

codeunit 77263 "CLV SI Arr Owner 1" implements "CLV Arr Share"
{
    SingleInstance = true;

    var
        A: array[2] of Record "CLB Row" temporary;
        One: Record "CLB Row" temporary;
        Cnt: Integer;

    procedure ShareA(Idx: Integer; var R: Record "CLB Row" temporary)
    begin
        R.Copy(A[Idx], true);
    end;

    procedure ShareOne(var R: Record "CLB Row" temporary)
    begin
        R.Copy(One, true);
    end;

    procedure WriteA(Idx: Integer; V: Integer)
    begin
        A[Idx].Init();
        A[Idx]."No." := V;
        A[Idx].Insert();
    end;

    procedure WriteOne(V: Integer)
    begin
        One.Init();
        One."No." := V;
        One.Insert();
    end;

    procedure State(): Text
    begin
        exit('a1=' + Format(A[1].Count()) + ' a2=' + Format(A[2].Count()) + ' one=' + Format(One.Count()) + ' cnt=' + Format(Cnt));
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;
}

codeunit 77264 "CLV SI Arr Owner 2" implements "CLV Arr Share"
{
    SingleInstance = true;

    var
        A: array[2] of Record "CLB Row" temporary;
        One: Record "CLB Row" temporary;
        Cnt: Integer;

    procedure ShareA(Idx: Integer; var R: Record "CLB Row" temporary)
    begin
        R.Copy(A[Idx], true);
    end;

    procedure ShareOne(var R: Record "CLB Row" temporary)
    begin
        R.Copy(One, true);
    end;

    procedure WriteA(Idx: Integer; V: Integer)
    begin
        A[Idx].Init();
        A[Idx]."No." := V;
        A[Idx].Insert();
    end;

    procedure WriteOne(V: Integer)
    begin
        One.Init();
        One."No." := V;
        One.Insert();
    end;

    procedure State(): Text
    begin
        exit('a1=' + Format(A[1].Count()) + ' a2=' + Format(A[2].Count()) + ' one=' + Format(One.Count()) + ' cnt=' + Format(Cnt));
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;
}

codeunit 77265 "CLV SI Arr Owner 3" implements "CLV Arr Share"
{
    SingleInstance = true;

    var
        A: array[2] of Record "CLB Row" temporary;
        One: Record "CLB Row" temporary;
        Cnt: Integer;

    procedure ShareA(Idx: Integer; var R: Record "CLB Row" temporary)
    begin
        R.Copy(A[Idx], true);
    end;

    procedure ShareOne(var R: Record "CLB Row" temporary)
    begin
        R.Copy(One, true);
    end;

    procedure WriteA(Idx: Integer; V: Integer)
    begin
        A[Idx].Init();
        A[Idx]."No." := V;
        A[Idx].Insert();
    end;

    procedure WriteOne(V: Integer)
    begin
        One.Init();
        One."No." := V;
        One.Insert();
    end;

    procedure State(): Text
    begin
        exit('a1=' + Format(A[1].Count()) + ' a2=' + Format(A[2].Count()) + ' one=' + Format(One.Count()) + ' cnt=' + Format(Cnt));
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;
}

codeunit 77262 "CLV Copy Holder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ArrEl2_TestLocal_Written_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Arr Owner";
        R: Record "CLB Row" temporary;
    begin
        Setup();
        O.SetCnt(5);
        O.WriteA(2, 1);
        O.ShareA(2, R);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('r', Format(R.Count()));
        R.Init();
        R."No." := 10;
        R.Insert();
        Observer.Observe('owner after r insert', O.State());
        O.WriteA(2, 3);
        Observer.Observe('r after owner write el.2', Format(R.Count()));
        O.WriteA(1, 4);
        Observer.Observe('r after owner write el.1', Format(R.Count()));
        Observer.Expect('owner', 'a1=1 a2=1 one=0 cnt=0');
        Observer.Expect('r', '1');
        Observer.Expect('owner after r insert', 'a1=2 a2=2 one=0 cnt=0');
        Observer.Expect('r after owner write el.2', '3');
        Observer.Expect('r after owner write el.1', '4');
        Observer.Verify();
    end;

    [Test]
    procedure ArrEl2_TestLocal_Never_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Arr Owner";
        R: Record "CLB Row" temporary;
    begin
        Setup();
        O.SetCnt(5);
        O.ShareA(2, R);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('r', Format(R.Count()));
        R.Init();
        R."No." := 10;
        R.Insert();
        Observer.Observe('owner after r insert', O.State());
        O.WriteA(2, 3);
        Observer.Observe('r after owner write el.2', Format(R.Count()));
        O.WriteA(1, 4);
        Observer.Observe('r after owner write el.1', Format(R.Count()));
        Observer.Expect('owner', 'a1=0 a2=0 one=0 cnt=0');
        Observer.Expect('r', '0');
        Observer.Expect('owner after r insert', 'a1=1 a2=1 one=0 cnt=0');
        Observer.Expect('r after owner write el.2', '2');
        Observer.Expect('r after owner write el.1', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ArrEl1_HolderGlobal_Written_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Arr Owner";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        O.SetCnt(5);
        O.WriteA(1, 1);
        H.TakeA(O, 1);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('owner after holder write', O.State());
        O.WriteA(1, 3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'a1=1 a2=1 one=0 cnt=0');
        Observer.Expect('holder', 'r=1 hcnt=1');
        Observer.Expect('owner after holder write', 'a1=2 a2=2 one=0 cnt=0');
        Observer.Expect('holder after owner write', 'r=3 hcnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure ArrEl2_HolderGlobal_Written_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Arr Owner";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        O.SetCnt(5);
        O.WriteA(2, 1);
        H.TakeA(O, 2);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('owner after holder write', O.State());
        O.WriteA(2, 3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'a1=1 a2=1 one=0 cnt=0');
        Observer.Expect('holder', 'r=1 hcnt=1');
        Observer.Expect('owner after holder write', 'a1=2 a2=2 one=0 cnt=0');
        Observer.Expect('holder after owner write', 'r=3 hcnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure ArrEl1_HolderGlobal_Never_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Arr Owner";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        O.SetCnt(5);
        H.TakeA(O, 1);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('owner after holder write', O.State());
        O.WriteA(1, 3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'a1=0 a2=0 one=0 cnt=0');
        Observer.Expect('holder', 'r=0 hcnt=1');
        Observer.Expect('owner after holder write', 'a1=1 a2=1 one=0 cnt=0');
        Observer.Expect('holder after owner write', 'r=2 hcnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure ArrEl2_HolderGlobal_Never_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Arr Owner";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        O.SetCnt(5);
        H.TakeA(O, 2);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('owner after holder write', O.State());
        O.WriteA(2, 3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'a1=0 a2=0 one=0 cnt=0');
        Observer.Expect('holder', 'r=0 hcnt=1');
        Observer.Expect('owner after holder write', 'a1=1 a2=1 one=0 cnt=0');
        Observer.Expect('holder after owner write', 'r=2 hcnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure One_HolderGlobal_Written_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Arr Owner";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        O.SetCnt(5);
        O.WriteOne(1);
        H.TakeOne(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('owner after holder write', O.State());
        O.WriteOne(3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'a1=0 a2=0 one=1 cnt=0');
        Observer.Expect('holder', 'r=1 hcnt=1');
        Observer.Expect('owner after holder write', 'a1=0 a2=0 one=2 cnt=0');
        Observer.Expect('holder after owner write', 'r=3 hcnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure One_HolderGlobal_Never_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Arr Owner";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        O.SetCnt(5);
        H.TakeOne(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('owner after holder write', O.State());
        O.WriteOne(3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'a1=0 a2=0 one=0 cnt=0');
        Observer.Expect('holder', 'r=0 hcnt=1');
        Observer.Expect('owner after holder write', 'a1=0 a2=0 one=1 cnt=0');
        Observer.Expect('holder after owner write', 'r=2 hcnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure ArrEl1_HolderGlobal_Written_HolderClears()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Arr Owner";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        O.SetCnt(5);
        O.WriteA(1, 1);
        H.TakeA(O, 1);
        H.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('owner after holder write', O.State());
        O.WriteA(1, 3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'a1=1 a2=1 one=0 cnt=5');
        Observer.Expect('holder', 'r=1 hcnt=0');
        Observer.Expect('owner after holder write', 'a1=2 a2=2 one=0 cnt=5');
        Observer.Expect('holder after owner write', 'r=3 hcnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure ArrEl2_HolderGlobal_Written_HolderClears()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Arr Owner";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        O.SetCnt(5);
        O.WriteA(2, 1);
        H.TakeA(O, 2);
        H.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('owner after holder write', O.State());
        O.WriteA(2, 3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'a1=1 a2=1 one=0 cnt=5');
        Observer.Expect('holder', 'r=1 hcnt=0');
        Observer.Expect('owner after holder write', 'a1=2 a2=2 one=0 cnt=5');
        Observer.Expect('holder after owner write', 'r=3 hcnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure One_HolderGlobal_Written_HolderClears()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Arr Owner";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        O.SetCnt(5);
        O.WriteOne(1);
        H.TakeOne(O);
        H.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('owner after holder write', O.State());
        O.WriteOne(3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'a1=0 a2=0 one=1 cnt=5');
        Observer.Expect('holder', 'r=1 hcnt=0');
        Observer.Expect('owner after holder write', 'a1=0 a2=0 one=2 cnt=5');
        Observer.Expect('holder after owner write', 'r=3 hcnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure UnionT1_HolderGlobal_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller U";
        O: Codeunit "CLV Post Owner U";
        H: Codeunit "CLV Rec Holder";
        R: Record "CLB Row" temporary;
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        H.TakeReg(O);
        O.ClearAllGlobals();
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('caller after holder write', C.State());
        C.SetInt(11);
        O.ShareT1(R);
        Observer.Observe('t1 after holder write', Format(R.Count()));
        Observer.Expect('caller', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=3');
        Observer.Expect('owner', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0');
        Observer.Expect('holder', 'r=2 hcnt=1');
        Observer.Expect('caller after holder write', 't1=3 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=3');
        Observer.Expect('t1 after holder write', '3');
        Observer.Verify();
    end;

    [Test]
    procedure UnionT1_HolderGlobal_HolderClears()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller U";
        O: Codeunit "CLV Post Owner U";
        H: Codeunit "CLV Rec Holder";
        R: Record "CLB Row" temporary;
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        H.TakeReg(O);
        H.ClearAllGlobals();
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('caller after holder write', C.State());
        C.SetInt(11);
        O.ShareT1(R);
        Observer.Observe('t1 after holder write', Format(R.Count()));
        Observer.Expect('caller', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=1:ONE find=No.: 2..3:2 ins=50:INS in1=n3,rows1,rec1 in2=n4,rows1,rec1 kind=Beta int=7 flag=Yes txt=MARK dt=2024-02-01 opt=C gnull=No lc=store label ll=locked label cnt=3');
        Observer.Expect('owner', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=1:ONE find=No.: 2..3:2 ins=50:INS in1=n3,rows1,rec1 in2=n4,rows1,rec1 kind=Beta int=7 flag=Yes txt=MARK dt=2024-02-01 opt=C gnull=No lc=store label ll=locked label cnt=0');
        Observer.Expect('holder', 'r=2 hcnt=0');
        Observer.Expect('caller after holder write', 't1=3 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=1:ONE find=No.: 2..3:2 ins=50:INS in1=n3,rows1,rec1 in2=n4,rows1,rec1 kind=Beta int=7 flag=Yes txt=MARK dt=2024-02-01 opt=C gnull=No lc=store label ll=locked label cnt=3');
        Observer.Expect('t1 after holder write', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ClrRows_HolderGlobal_TableNoOwnerRunClearAll()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        C.MarkReg();
        C.WriteReg(1);
        C.WriteReg(2);
        C.Handoff(1, false);
        H.TakeClr(C);
        C.ClearOwner(1);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(1));
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('caller after holder write', C.StateReg());
        C.OwnerWrite(1, 11);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('caller', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder', 'r=2 hcnt=1');
        Observer.Expect('caller after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'r=4 hcnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure ClrRows_HolderGlobal_PlainOwnerProcClearAll()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        C.MarkReg();
        C.WriteReg(1);
        C.WriteReg(2);
        C.Handoff(4, false);
        H.TakeClr(C);
        C.ClearOwner(4);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(4));
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('caller after holder write', C.StateReg());
        C.OwnerWrite(4, 11);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('caller', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder', 'r=2 hcnt=1');
        Observer.Expect('caller after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'r=4 hcnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure ClrRows_HolderGlobal_HolderClears()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        C.MarkReg();
        C.WriteReg(1);
        C.WriteReg(2);
        C.Handoff(4, false);
        H.TakeClr(C);
        H.ClearAllGlobals();
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(4));
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('caller after holder write', C.StateReg());
        C.OwnerWrite(4, 11);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('caller', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('holder', 'r=2 hcnt=0');
        Observer.Expect('caller after holder write', 'rows=3 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('holder after owner write', 'r=4 hcnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrEl2_TestLocal_Written_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV SI Arr Owner 1";
        R: Record "CLB Row" temporary;
    begin
        Setup();
        O.SetCnt(5);
        O.WriteA(2, 1);
        O.ShareA(2, R);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('r', Format(R.Count()));
        R.Init();
        R."No." := 10;
        R.Insert();
        Observer.Observe('owner after r insert', O.State());
        O.WriteA(2, 3);
        Observer.Observe('r after owner write el.2', Format(R.Count()));
        O.WriteA(1, 4);
        Observer.Observe('r after owner write el.1', Format(R.Count()));
        Observer.Expect('owner', 'a1=1 a2=1 one=0 cnt=0');
        Observer.Expect('r', '1');
        Observer.Expect('owner after r insert', 'a1=2 a2=2 one=0 cnt=0');
        Observer.Expect('r after owner write el.2', '3');
        Observer.Expect('r after owner write el.1', '4');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrEl1_HolderGlobal_Written_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV SI Arr Owner 2";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        O.SetCnt(5);
        O.WriteA(1, 1);
        H.TakeA(O, 1);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('owner after holder write', O.State());
        O.WriteA(1, 3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'a1=1 a2=1 one=0 cnt=0');
        Observer.Expect('holder', 'r=1 hcnt=1');
        Observer.Expect('owner after holder write', 'a1=2 a2=2 one=0 cnt=0');
        Observer.Expect('holder after owner write', 'r=3 hcnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure SIOne_HolderGlobal_Written_ClearAll()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV SI Arr Owner 3";
        H: Codeunit "CLV Rec Holder";
    begin
        Setup();
        O.SetCnt(5);
        O.WriteOne(1);
        H.TakeOne(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.Write(10);
        Observer.Observe('owner after holder write', O.State());
        O.WriteOne(3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'a1=0 a2=0 one=1 cnt=0');
        Observer.Expect('holder', 'r=1 hcnt=1');
        Observer.Expect('owner after holder write', 'a1=0 a2=0 one=2 cnt=0');
        Observer.Expect('holder after owner write', 'r=3 hcnt=1');
        Observer.Verify();
    end;

    local procedure Setup()
    var
        D: Record "CLV Data";
    begin
        D.DeleteAll();
        D.Init();
        D."No." := 1;
        D.Name := 'ONE';
        D.Insert();
        D."No." := 2;
        D.Name := 'TWO';
        D.Insert();
        D."No." := 3;
        D.Name := 'THREE';
        D.Insert();
    end;
}
