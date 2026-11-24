// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586) of ClearSharedCodeunitTempRef.al;
//   self-contained objects 77235 to 77255
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: ClearAll in a codeunit that holds a store codeunit as a global. Stores (all codeunits, no SingleInstance):
//   - "CLV Price Store": a temporary record T1, an Enum, an Integer and a Label with Comment.
//   - "CLV Whse Register" (TableNo): three records that are not temporary (after Get, after SetRange + FindSet, after
//     Insert), two nested codeunits ("CLV Inner": own temporary record, own record after Get, own Integer), an Integer,
//     a Boolean and two Labels with Comment; no temporary record.
//   - "CLV Store" and "CLV Table Store" (TableNo): all of these together plus six more temporary records, a Text, a
//     Date, an Option, a Guid and a Label with Locked.
//   - "CLV Late Store": seven temporary records (1 to 7 rows), a nested codeunit and an Integer.
//   Mark sets every value (kind=Beta int=7 flag=Yes txt=MARK dt=2024-02-01 opt=C, a new Guid, get=1 find=2..3 ins=50,
//   nested n3 / n4 with one row each); Fill writes T1 two rows and every other temporary record one row.
//   - Price_* / Union_*_SetLine: a plain owner that implements an interface ("CLV Line Owner", "CLV Line Owner U"), the
//     store its own global and NOT shared; ClearAll in the procedure SetLine (then LineNo := 1), called through the
//     interface or directly. Also never prepared (Fresh), T1 emptied before, twice, with an alias of the store taken
//     before (GetStore), T1 shared with a temporary record R of the test by R.Copy(T1, true), a sharer of the nested
//     codeunit.
//   - Late_*: the late store under a plain owner, ClearAll in a procedure of the owner; also with a nested sharer.
//   - Whse_* / Union_* (77247): the register made by a caller (its global; "CLV Post Caller" plain, "CLV Post Caller T"
//     TableNo) and handed to an owner by a setter (var parameter or by value) that assigns the owner's global (owner
//     "CLV Post Owner" TableNo or "CLV Post Owner P" plain). ClearAll in the owner's procedure DoPost reached by Run,
//     in an owner procedure called directly, or on the caller side (ClearAll in a caller procedure, or in the
//     TableNo caller's OnRun). The test also holds a sharer of nested codeunit 1 (I). Writes: SetInt through the
//     caller (11), the owner (12), the nested sharer (I.Write(21), I.Set(9)).
//   - 77255: other holders of the shared register while the owner runs ClearAll: an interface global of another
//     codeunit ("CLV Face Holder"), a test local alias taken by a var getter, a local alias, a local interface, a
//     by-value parameter of the clearing routine and of the caller of the clearing routine (each writes 40 to 43
//     after reading); ClearAll in the interface holder; the same positions for the owner's own register.
//   Measured on BC 29.0 (Linux):
//   - ClearAll in the owner resets the store global in place, for every store, owner, setter and holder here. Every
//     temporary record (T1 to T7, L1 to L7, and the nested codeunits' own) keeps the rows it holds now: 2 stay 2,
//     written then emptied reads 0, a store never prepared reads 0. Every record that is not temporary loses its
//     field values and filters (get=0: find=:0 ins=0:). Enum, Integer, Boolean, Text, Date, Option and Guid go to
//     their defaults (None, 0, No, '', '' from Format(0D, 0, 9), A, a null Guid). Both Labels keep their text. The
//     nested codeunits are reset in place the same way (n0, own rows kept, rec0).
//   - All holders stay on the one reset instance, and a write through any of them shows through the others: the
//     owner; an alias taken before (a test local through a var getter, a local alias, a local interface, an
//     interface global of another codeunit, a by-value parameter of the clearing routine or of its caller); the
//     caller that made the register; a sharer of a nested codeunit (its writes show in the store's nested state).
//     A temporary table shared by R.Copy(T1, true) stays shared.
//   - SetLine twice: the rows add up (2 kept + 1 written between = 3), the values go to their defaults again.
//   - ClearAll on the caller side (plain caller procedure, TableNo caller OnRun or procedure, var or by-value
//     setter) gives the same reset in place; the owner reads it.
//   - ClearAll in the interface holder ("CLV Face Holder") also resets the register in place: the caller and the
//     owner read the defaults, rows kept.
//   - Late store: l=1/2/3/4/5/6/7 kept, nested n0 rows1 rec0, Integer 0; the nested sharer reads the reset and its
//     writes show through the owner.
// BC versions: 27, 28, 29

table 77235 "CLV Data"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

enum 77236 "CLV Kind"
{
    value(0; None) { }
    value(1; Alpha) { }
    value(2; Beta) { }
}

interface "CLV Store Face"
{
    procedure State(): Text;
    procedure SetInt(V: Integer);
}

interface "CLV Line"
{
    procedure SetLine();
}

codeunit 77237 "CLV Inner"
{
    var
        IRows: Record "CLB Row" temporary;
        IRec: Record "CLV Data";
        N: Integer;

    procedure Mark(V: Integer)
    begin
        N := V;
        Write(V);
        IRec.Get(1);
    end;

    procedure Write(V: Integer)
    begin
        IRows.Init();
        IRows."No." := V;
        IRows.Insert();
    end;

    procedure Set(V: Integer)
    begin
        N := V;
    end;

    procedure State(): Text
    begin
        exit('n' + Format(N) + ',rows' + Format(IRows.Count()) + ',rec' + Format(IRec."No."));
    end;
}

codeunit 77238 "CLV Store" implements "CLV Store Face"
{
    var
        T1: Record "CLB Row" temporary;
        T2: Record "CLB Row" temporary;
        T3: Record "CLB Row" temporary;
        T4: Record "CLB Row" temporary;
        T5: Record "CLB Row" temporary;
        T6: Record "CLB Row" temporary;
        T7: Record "CLV Data" temporary;
        RecGet: Record "CLV Data";
        RecFind: Record "CLV Data";
        RecIns: Record "CLV Data";
        Inner1: Codeunit "CLV Inner";
        Inner2: Codeunit "CLV Inner";
        Kind: Enum "CLV Kind";
        Int: Integer;
        Flag: Boolean;
        Txt: Text;
        Dt: Date;
        Opt: Option A,B,C;
        G: Guid;
        LblC: Label 'store label', Comment = 'a comment';
        LblL: Label 'locked label', Locked = true;

    procedure Mark()
    begin
        RecGet.Get(1);
        RecFind.SetRange("No.", 2, 3);
        RecFind.FindSet();
        RecIns.Init();
        RecIns."No." := 50;
        RecIns.Name := 'INS';
        RecIns.Insert();
        Inner1.Mark(3);
        Inner2.Mark(4);
        Kind := Kind::Beta;
        Int := 7;
        Flag := true;
        Txt := 'MARK';
        Dt := DMY2Date(1, 2, 2024);
        Opt := Opt::C;
        G := CreateGuid();
    end;

    procedure Fill()
    begin
        AddRow(T1, 1);
        AddRow(T1, 2);
        AddRow(T2, 1);
        AddRow(T3, 1);
        AddRow(T4, 1);
        AddRow(T5, 1);
        AddRow(T6, 1);
        T7.Init();
        T7."No." := 1;
        T7.Insert();
    end;

    local procedure AddRow(var T: Record "CLB Row" temporary; V: Integer)
    begin
        T.Init();
        T."No." := V;
        T.Insert();
    end;

    procedure WriteT1(V: Integer)
    begin
        AddRow(T1, V);
    end;

    procedure EmptyT1()
    begin
        T1.DeleteAll();
    end;

    procedure ShareT1(var R: Record "CLB Row" temporary)
    begin
        R.Copy(T1, true);
    end;

    procedure GetInner1(var I: Codeunit "CLV Inner")
    begin
        I := Inner1;
    end;

    procedure SetInt(V: Integer)
    begin
        Int := V;
    end;

    procedure State(): Text
    begin
        exit('t1=' + Format(T1.Count())
            + ' ' + 't2=' + Format(T2.Count())
            + ' ' + 't3=' + Format(T3.Count())
            + ' ' + 't4=' + Format(T4.Count())
            + ' ' + 't5=' + Format(T5.Count())
            + ' ' + 't6=' + Format(T6.Count())
            + ' ' + 't7=' + Format(T7.Count())
            + ' ' + 'get=' + Format(RecGet."No.") + ':' + RecGet.Name
            + ' ' + 'find=' + RecFind.GetFilters() + ':' + Format(RecFind."No.")
            + ' ' + 'ins=' + Format(RecIns."No.") + ':' + RecIns.Name
            + ' ' + 'in1=' + Inner1.State()
            + ' ' + 'in2=' + Inner2.State()
            + ' ' + 'kind=' + Format(Kind)
            + ' ' + 'int=' + Format(Int)
            + ' ' + 'flag=' + Format(Flag)
            + ' ' + 'txt=' + Txt
            + ' ' + 'dt=' + Format(Dt, 0, 9)
            + ' ' + 'opt=' + Format(Opt)
            + ' ' + 'gnull=' + Format(IsNullGuid(G))
            + ' ' + 'lc=' + LblC
            + ' ' + 'll=' + LblL);
    end;
}

codeunit 77239 "CLV Table Store" implements "CLV Store Face"
{
    TableNo = "CLV Data";

    var
        T1: Record "CLB Row" temporary;
        T2: Record "CLB Row" temporary;
        T3: Record "CLB Row" temporary;
        T4: Record "CLB Row" temporary;
        T5: Record "CLB Row" temporary;
        T6: Record "CLB Row" temporary;
        T7: Record "CLV Data" temporary;
        RecGet: Record "CLV Data";
        RecFind: Record "CLV Data";
        RecIns: Record "CLV Data";
        Inner1: Codeunit "CLV Inner";
        Inner2: Codeunit "CLV Inner";
        Kind: Enum "CLV Kind";
        Int: Integer;
        Flag: Boolean;
        Txt: Text;
        Dt: Date;
        Opt: Option A,B,C;
        G: Guid;
        LblC: Label 'store label', Comment = 'a comment';
        LblL: Label 'locked label', Locked = true;

    trigger OnRun()
    begin
        Int := 99;
    end;

    procedure Mark()
    begin
        RecGet.Get(1);
        RecFind.SetRange("No.", 2, 3);
        RecFind.FindSet();
        RecIns.Init();
        RecIns."No." := 50;
        RecIns.Name := 'INS';
        RecIns.Insert();
        Inner1.Mark(3);
        Inner2.Mark(4);
        Kind := Kind::Beta;
        Int := 7;
        Flag := true;
        Txt := 'MARK';
        Dt := DMY2Date(1, 2, 2024);
        Opt := Opt::C;
        G := CreateGuid();
    end;

    procedure Fill()
    begin
        AddRow(T1, 1);
        AddRow(T1, 2);
        AddRow(T2, 1);
        AddRow(T3, 1);
        AddRow(T4, 1);
        AddRow(T5, 1);
        AddRow(T6, 1);
        T7.Init();
        T7."No." := 1;
        T7.Insert();
    end;

    local procedure AddRow(var T: Record "CLB Row" temporary; V: Integer)
    begin
        T.Init();
        T."No." := V;
        T.Insert();
    end;

    procedure WriteT1(V: Integer)
    begin
        AddRow(T1, V);
    end;

    procedure EmptyT1()
    begin
        T1.DeleteAll();
    end;

    procedure ShareT1(var R: Record "CLB Row" temporary)
    begin
        R.Copy(T1, true);
    end;

    procedure GetInner1(var I: Codeunit "CLV Inner")
    begin
        I := Inner1;
    end;

    procedure SetInt(V: Integer)
    begin
        Int := V;
    end;

    procedure State(): Text
    begin
        exit('t1=' + Format(T1.Count())
            + ' ' + 't2=' + Format(T2.Count())
            + ' ' + 't3=' + Format(T3.Count())
            + ' ' + 't4=' + Format(T4.Count())
            + ' ' + 't5=' + Format(T5.Count())
            + ' ' + 't6=' + Format(T6.Count())
            + ' ' + 't7=' + Format(T7.Count())
            + ' ' + 'get=' + Format(RecGet."No.") + ':' + RecGet.Name
            + ' ' + 'find=' + RecFind.GetFilters() + ':' + Format(RecFind."No.")
            + ' ' + 'ins=' + Format(RecIns."No.") + ':' + RecIns.Name
            + ' ' + 'in1=' + Inner1.State()
            + ' ' + 'in2=' + Inner2.State()
            + ' ' + 'kind=' + Format(Kind)
            + ' ' + 'int=' + Format(Int)
            + ' ' + 'flag=' + Format(Flag)
            + ' ' + 'txt=' + Txt
            + ' ' + 'dt=' + Format(Dt, 0, 9)
            + ' ' + 'opt=' + Format(Opt)
            + ' ' + 'gnull=' + Format(IsNullGuid(G))
            + ' ' + 'lc=' + LblC
            + ' ' + 'll=' + LblL);
    end;
}

codeunit 77240 "CLV Line Owner" implements "CLV Line"
{
    var
        S: Codeunit "CLV Price Store";
        Cnt: Integer;
        LineNo: Integer;

    procedure SetLine()
    begin
        ClearAll();
        LineNo := 1;
    end;

    procedure Prepare()
    begin
        S.Mark();
        S.Fill();
        Cnt := 5;
    end;

    procedure State(): Text
    begin
        exit(S.State() + ' cnt=' + Format(Cnt) + ' line=' + Format(LineNo));
    end;

    procedure SetInt(V: Integer)
    begin
        S.SetInt(V);
    end;

    procedure GetStore(var X: Codeunit "CLV Price Store")
    begin
        X := S;
    end;

    procedure WriteT1(V: Integer)
    begin
        S.WriteT1(V);
    end;

    procedure EmptyT1()
    begin
        S.EmptyT1();
    end;

    procedure ShareT1(var R: Record "CLB Row" temporary)
    begin
        S.ShareT1(R);
    end;
}

codeunit 77241 "CLV Late Store"
{
    var
        L1: Record "CLB Row" temporary;
        L2: Record "CLB Row" temporary;
        L3: Record "CLB Row" temporary;
        L4: Record "CLB Row" temporary;
        L5: Record "CLB Row" temporary;
        L6: Record "CLB Row" temporary;
        L7: Record "CLB Row" temporary;
        Nested: Codeunit "CLV Inner";
        Cnt: Integer;

    procedure Prepare()
    begin
        Add(L1, 1);
        Add(L2, 2);
        Add(L3, 3);
        Add(L4, 4);
        Add(L5, 5);
        Add(L6, 6);
        Add(L7, 7);
        Nested.Mark(5);
        Cnt := 6;
    end;

    local procedure Add(var T: Record "CLB Row" temporary; N: Integer)
    var
        I: Integer;
    begin
        for I := 1 to N do begin
            T.Init();
            T."No." := I;
            T.Insert();
        end;
    end;

    procedure GetNested(var I: Codeunit "CLV Inner")
    begin
        I := Nested;
    end;

    procedure State(): Text
    begin
        exit('l=' + Format(L1.Count()) + '/' + Format(L2.Count()) + '/' + Format(L3.Count()) + '/' + Format(L4.Count()) +
            '/' + Format(L5.Count()) + '/' + Format(L6.Count()) + '/' + Format(L7.Count()) +
            ' nested=' + Nested.State() + ' cnt=' + Format(Cnt));
    end;
}

codeunit 77242 "CLV Resv Owner"
{
    var
        Late: Codeunit "CLV Late Store";
        Own: Integer;

    procedure Prepare()
    begin
        Late.Prepare();
        Own := 2;
    end;

    procedure Reset()
    begin
        ClearAll();
    end;

    procedure State(): Text
    begin
        exit(Late.State() + ' own=' + Format(Own));
    end;

    procedure GetNested(var I: Codeunit "CLV Inner")
    begin
        Late.GetNested(I);
    end;
}

codeunit 77243 "CLV Post Owner"
{
    TableNo = "CLV Data";

    var
        Reg: Codeunit "CLV Whse Register";
        Cnt: Integer;

    trigger OnRun()
    begin
        DoPost();
    end;

    local procedure DoPost()
    begin
        ClearAll();
        Cnt := 1;
    end;

    procedure SetReg(var NewReg: Codeunit "CLV Whse Register")
    begin
        Reg := NewReg;
    end;

    procedure SetRegByValue(NewReg: Codeunit "CLV Whse Register")
    begin
        Reg := NewReg;
    end;

    procedure PrepareOwn()
    begin
        Reg.Mark();
        Reg.Fill();
        Cnt := 5;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure State(): Text
    begin
        exit(Reg.State() + ' cnt=' + Format(Cnt));
    end;

    procedure SetInt(V: Integer)
    begin
        Reg.SetInt(V);
    end;

    procedure GetReg(var X: Codeunit "CLV Whse Register")
    begin
        X := Reg;
    end;

    procedure GetInner1(var I: Codeunit "CLV Inner")
    begin
        Reg.GetInner1(I);
    end;

    procedure ShareFace(var H: Codeunit "CLV Face Holder")
    begin
        H.SetFace(Reg);
    end;

    procedure AliasClear(): Text
    var
        L: Codeunit "CLV Whse Register";
        Before: Text;
    begin
        L := Reg;
        ClearAll();
        Before := L.State();
        L.SetInt(40);
        exit(Before);
    end;

    procedure IfaceClear(): Text
    var
        F: Interface "CLV Store Face";
        Before: Text;
    begin
        F := Reg;
        ClearAll();
        Before := F.State();
        F.SetInt(42);
        exit(Before);
    end;

    procedure ByValueClear(): Text
    begin
        exit(ClearWith(Reg));
    end;

    local procedure ClearWith(P: Codeunit "CLV Whse Register"): Text
    var
        Before: Text;
    begin
        ClearAll();
        Before := P.State();
        P.SetInt(41);
        exit(Before);
    end;

    procedure ByValueOuter(): Text
    begin
        exit(Outer(Reg));
    end;

    local procedure Outer(P: Codeunit "CLV Whse Register"): Text
    var
        Before: Text;
    begin
        ClearAllGlobals();
        Before := P.State();
        P.SetInt(43);
        exit(Before);
    end;
}

codeunit 77244 "CLV Post Caller"
{
    var
        Reg: Codeunit "CLV Whse Register";
        Cnt: Integer;

    procedure Prepare()
    begin
        Reg.Mark();
        Reg.Fill();
        Cnt := 3;
    end;

    procedure HandoffTo(var O: Codeunit "CLV Post Owner"; ByValue: Boolean)
    begin
        if ByValue then
            O.SetRegByValue(Reg)
        else
            O.SetReg(Reg);
    end;

    procedure HandoffToPlain(var O: Codeunit "CLV Post Owner P"; ByValue: Boolean)
    begin
        if ByValue then
            O.SetRegByValue(Reg)
        else
            O.SetReg(Reg);
    end;

    procedure GetInner1(var I: Codeunit "CLV Inner")
    begin
        Reg.GetInner1(I);
    end;

    procedure ClearSelf()
    begin
        ClearAll();
    end;

    procedure State(): Text
    begin
        exit(Reg.State() + ' cnt=' + Format(Cnt));
    end;

    procedure SetInt(V: Integer)
    begin
        Reg.SetInt(V);
    end;
}

codeunit 77245 "CLV Face Holder"
{
    var
        F: Interface "CLV Store Face";
        Cnt: Integer;

    procedure SetFace(NewF: Interface "CLV Store Face")
    begin
        F := NewF;
        Cnt := 1;
    end;

    procedure State(): Text
    begin
        exit(F.State() + ' hcnt=' + Format(Cnt));
    end;

    procedure SetInt(V: Integer)
    begin
        F.SetInt(V);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;
}

codeunit 77248 "CLV Line Owner U" implements "CLV Line"
{
    var
        S: Codeunit "CLV Store";
        Cnt: Integer;
        LineNo: Integer;

    procedure SetLine()
    begin
        ClearAll();
        LineNo := 1;
    end;

    procedure Prepare()
    begin
        S.Mark();
        S.Fill();
        Cnt := 5;
    end;

    procedure State(): Text
    begin
        exit(S.State() + ' cnt=' + Format(Cnt) + ' line=' + Format(LineNo));
    end;

    procedure SetInt(V: Integer)
    begin
        S.SetInt(V);
    end;

    procedure GetStore(var X: Codeunit "CLV Store")
    begin
        X := S;
    end;

    procedure WriteT1(V: Integer)
    begin
        S.WriteT1(V);
    end;

    procedure EmptyT1()
    begin
        S.EmptyT1();
    end;

    procedure ShareT1(var R: Record "CLB Row" temporary)
    begin
        S.ShareT1(R);
    end;

    procedure GetInner1(var I: Codeunit "CLV Inner")
    begin
        S.GetInner1(I);
    end;
}

codeunit 77249 "CLV Post Owner P"
{
    var
        Reg: Codeunit "CLV Whse Register";
        Cnt: Integer;

    trigger OnRun()
    begin
        DoPost();
    end;

    local procedure DoPost()
    begin
        ClearAll();
        Cnt := 1;
    end;

    procedure SetReg(var NewReg: Codeunit "CLV Whse Register")
    begin
        Reg := NewReg;
    end;

    procedure SetRegByValue(NewReg: Codeunit "CLV Whse Register")
    begin
        Reg := NewReg;
    end;

    procedure PrepareOwn()
    begin
        Reg.Mark();
        Reg.Fill();
        Cnt := 5;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure State(): Text
    begin
        exit(Reg.State() + ' cnt=' + Format(Cnt));
    end;

    procedure SetInt(V: Integer)
    begin
        Reg.SetInt(V);
    end;

    procedure GetReg(var X: Codeunit "CLV Whse Register")
    begin
        X := Reg;
    end;

    procedure GetInner1(var I: Codeunit "CLV Inner")
    begin
        Reg.GetInner1(I);
    end;

    procedure ShareFace(var H: Codeunit "CLV Face Holder")
    begin
        H.SetFace(Reg);
    end;

    procedure AliasClear(): Text
    var
        L: Codeunit "CLV Whse Register";
        Before: Text;
    begin
        L := Reg;
        ClearAll();
        Before := L.State();
        L.SetInt(40);
        exit(Before);
    end;

    procedure IfaceClear(): Text
    var
        F: Interface "CLV Store Face";
        Before: Text;
    begin
        F := Reg;
        ClearAll();
        Before := F.State();
        F.SetInt(42);
        exit(Before);
    end;

    procedure ByValueClear(): Text
    begin
        exit(ClearWith(Reg));
    end;

    local procedure ClearWith(P: Codeunit "CLV Whse Register"): Text
    var
        Before: Text;
    begin
        ClearAll();
        Before := P.State();
        P.SetInt(41);
        exit(Before);
    end;

    procedure ByValueOuter(): Text
    begin
        exit(Outer(Reg));
    end;

    local procedure Outer(P: Codeunit "CLV Whse Register"): Text
    var
        Before: Text;
    begin
        ClearAllGlobals();
        Before := P.State();
        P.SetInt(43);
        exit(Before);
    end;
}

codeunit 77250 "CLV Post Owner U"
{
    TableNo = "CLV Data";

    var
        Reg: Codeunit "CLV Table Store";
        Cnt: Integer;

    trigger OnRun()
    begin
        DoPost();
    end;

    local procedure DoPost()
    begin
        ClearAll();
        Cnt := 1;
    end;

    procedure SetReg(var NewReg: Codeunit "CLV Table Store")
    begin
        Reg := NewReg;
    end;

    procedure SetRegByValue(NewReg: Codeunit "CLV Table Store")
    begin
        Reg := NewReg;
    end;

    procedure PrepareOwn()
    begin
        Reg.Mark();
        Reg.Fill();
        Cnt := 5;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure State(): Text
    begin
        exit(Reg.State() + ' cnt=' + Format(Cnt));
    end;

    procedure SetInt(V: Integer)
    begin
        Reg.SetInt(V);
    end;

    procedure GetReg(var X: Codeunit "CLV Table Store")
    begin
        X := Reg;
    end;

    procedure ShareT1(var R: Record "CLB Row" temporary)
    begin
        Reg.ShareT1(R);
    end;

    procedure GetInner1(var I: Codeunit "CLV Inner")
    begin
        Reg.GetInner1(I);
    end;

    procedure ShareFace(var H: Codeunit "CLV Face Holder")
    begin
        H.SetFace(Reg);
    end;

    procedure AliasClear(): Text
    var
        L: Codeunit "CLV Table Store";
        Before: Text;
    begin
        L := Reg;
        ClearAll();
        Before := L.State();
        L.SetInt(40);
        exit(Before);
    end;

    procedure IfaceClear(): Text
    var
        F: Interface "CLV Store Face";
        Before: Text;
    begin
        F := Reg;
        ClearAll();
        Before := F.State();
        F.SetInt(42);
        exit(Before);
    end;

    procedure ByValueClear(): Text
    begin
        exit(ClearWith(Reg));
    end;

    local procedure ClearWith(P: Codeunit "CLV Table Store"): Text
    var
        Before: Text;
    begin
        ClearAll();
        Before := P.State();
        P.SetInt(41);
        exit(Before);
    end;

    procedure ByValueOuter(): Text
    begin
        exit(Outer(Reg));
    end;

    local procedure Outer(P: Codeunit "CLV Table Store"): Text
    var
        Before: Text;
    begin
        ClearAllGlobals();
        Before := P.State();
        P.SetInt(43);
        exit(Before);
    end;
}

codeunit 77251 "CLV Post Caller T"
{
    TableNo = "CLV Data";

    var
        Reg: Codeunit "CLV Whse Register";
        Cnt: Integer;

    trigger OnRun()
    begin
        ClearAll();
    end;

    procedure Prepare()
    begin
        Reg.Mark();
        Reg.Fill();
        Cnt := 3;
    end;

    procedure HandoffTo(var O: Codeunit "CLV Post Owner"; ByValue: Boolean)
    begin
        if ByValue then
            O.SetRegByValue(Reg)
        else
            O.SetReg(Reg);
    end;

    procedure GetInner1(var I: Codeunit "CLV Inner")
    begin
        Reg.GetInner1(I);
    end;

    procedure ClearSelf()
    begin
        ClearAll();
    end;

    procedure State(): Text
    begin
        exit(Reg.State() + ' cnt=' + Format(Cnt));
    end;

    procedure SetInt(V: Integer)
    begin
        Reg.SetInt(V);
    end;
}

codeunit 77252 "CLV Post Caller U"
{
    var
        Reg: Codeunit "CLV Table Store";
        Cnt: Integer;

    procedure Prepare()
    begin
        Reg.Mark();
        Reg.Fill();
        Cnt := 3;
    end;

    procedure HandoffTo(var O: Codeunit "CLV Post Owner U"; ByValue: Boolean)
    begin
        if ByValue then
            O.SetRegByValue(Reg)
        else
            O.SetReg(Reg);
    end;

    procedure GetInner1(var I: Codeunit "CLV Inner")
    begin
        Reg.GetInner1(I);
    end;

    procedure ClearSelf()
    begin
        ClearAll();
    end;

    procedure State(): Text
    begin
        exit(Reg.State() + ' cnt=' + Format(Cnt));
    end;

    procedure SetInt(V: Integer)
    begin
        Reg.SetInt(V);
    end;
}

codeunit 77253 "CLV Price Store" implements "CLV Store Face"
{
    var
        T1: Record "CLB Row" temporary;
        Kind: Enum "CLV Kind";
        Int: Integer;
        LblC: Label 'store label', Comment = 'a comment';

    procedure Mark()
    begin
        Kind := Kind::Beta;
        Int := 7;
    end;

    procedure Fill()
    begin
        AddRow(T1, 1);
        AddRow(T1, 2);
    end;

    local procedure AddRow(var T: Record "CLB Row" temporary; V: Integer)
    begin
        T.Init();
        T."No." := V;
        T.Insert();
    end;

    procedure WriteT1(V: Integer)
    begin
        AddRow(T1, V);
    end;

    procedure EmptyT1()
    begin
        T1.DeleteAll();
    end;

    procedure ShareT1(var R: Record "CLB Row" temporary)
    begin
        R.Copy(T1, true);
    end;

    procedure SetInt(V: Integer)
    begin
        Int := V;
    end;

    procedure State(): Text
    begin
        exit('t1=' + Format(T1.Count())
            + ' ' + 'kind=' + Format(Kind)
            + ' ' + 'int=' + Format(Int)
            + ' ' + 'lc=' + LblC);
    end;
}

codeunit 77254 "CLV Whse Register" implements "CLV Store Face"
{
    TableNo = "CLV Data";

    var
        RecGet: Record "CLV Data";
        RecFind: Record "CLV Data";
        RecIns: Record "CLV Data";
        Inner1: Codeunit "CLV Inner";
        Inner2: Codeunit "CLV Inner";
        Int: Integer;
        Flag: Boolean;
        LblC: Label 'store label', Comment = 'a comment';
        LblC2: Label 'second label', Comment = 'another comment';

    trigger OnRun()
    begin
        Int := 99;
    end;

    procedure Mark()
    begin
        RecGet.Get(1);
        RecFind.SetRange("No.", 2, 3);
        RecFind.FindSet();
        RecIns.Init();
        RecIns."No." := 50;
        RecIns.Name := 'INS';
        RecIns.Insert();
        Inner1.Mark(3);
        Inner2.Mark(4);
        Int := 7;
        Flag := true;
    end;

    procedure Fill()
    begin
        Int := Int;
    end;

    procedure GetInner1(var I: Codeunit "CLV Inner")
    begin
        I := Inner1;
    end;

    procedure SetInt(V: Integer)
    begin
        Int := V;
    end;

    procedure State(): Text
    begin
        exit('get=' + Format(RecGet."No.") + ':' + RecGet.Name
            + ' ' + 'find=' + RecFind.GetFilters() + ':' + Format(RecFind."No.")
            + ' ' + 'ins=' + Format(RecIns."No.") + ':' + RecIns.Name
            + ' ' + 'in1=' + Inner1.State()
            + ' ' + 'in2=' + Inner2.State()
            + ' ' + 'int=' + Format(Int)
            + ' ' + 'flag=' + Format(Flag)
            + ' ' + 'lc=' + LblC
            + ' ' + 'lc2=' + LblC2);
    end;
}

codeunit 77246 "CLV Price Shape Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Price_ViaInterface_Filled_SetLine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        L: Interface "CLV Line";
    begin
        Setup();
        O.Prepare();
        L := O;
        L.SetLine();
        Observer.Observe('owner', O.State());
        O.WriteT1(10);
        Observer.Observe('owner after write', O.State());
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('owner after write', 't1=3 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_Direct_Filled_SetLine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
    begin
        Setup();
        O.Prepare();
        O.SetLine();
        Observer.Observe('owner', O.State());
        O.WriteT1(10);
        Observer.Observe('owner after write', O.State());
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('owner after write', 't1=3 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ViaInterface_Fresh_SetLine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        L: Interface "CLV Line";
    begin
        Setup();
        L := O;
        L.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ViaInterface_Emptied_SetLine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        L: Interface "CLV Line";
    begin
        Setup();
        O.Prepare();
        O.EmptyT1();
        L := O;
        L.SetLine();
        Observer.Observe('owner', O.State());
        O.WriteT1(10);
        Observer.Observe('owner after write', O.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('owner after write', 't1=1 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ViaInterface_SetLineTwice()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        L: Interface "CLV Line";
    begin
        Setup();
        O.Prepare();
        L := O;
        L.SetLine();
        O.WriteT1(10);
        O.SetInt(8);
        L.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Expect('owner', 't1=3 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_StoreAlias_SetLine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        L: Interface "CLV Line";
        X: Codeunit "CLV Price Store";
    begin
        Setup();
        O.Prepare();
        O.GetStore(X);
        L := O;
        L.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('alias', X.State());
        X.SetInt(10);
        Observer.Observe('owner after alias write', O.State());
        O.SetInt(11);
        Observer.Observe('alias after owner write', X.State());
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('alias', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after alias write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('alias after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_T1SharedByCopy_SetLine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        L: Interface "CLV Line";
        R: Record "CLB Row" temporary;
    begin
        Setup();
        O.Prepare();
        O.ShareT1(R);
        L := O;
        L.SetLine();
        Observer.Observe('r', Format(R.Count()));
        Observer.Observe('owner', O.State());
        R.Init();
        R."No." := 30;
        R.Insert();
        Observer.Observe('owner after r insert', O.State());
        O.WriteT1(31);
        Observer.Observe('r after owner write', Format(R.Count()));
        Observer.Expect('r', '2');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('owner after r insert', 't1=3 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('r after owner write', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Union_ViaInterface_Filled_SetLine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner U";
        L: Interface "CLV Line";
    begin
        Setup();
        O.Prepare();
        L := O;
        L.SetLine();
        Observer.Observe('owner', O.State());
        O.WriteT1(10);
        Observer.Observe('owner after write', O.State());
        Observer.Expect('owner', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0 line=1');
        Observer.Expect('owner after write', 't1=3 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Union_StoreAlias_SetLine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner U";
        L: Interface "CLV Line";
        X: Codeunit "CLV Store";
    begin
        Setup();
        O.Prepare();
        O.GetStore(X);
        L := O;
        L.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('alias', X.State());
        X.SetInt(10);
        Observer.Observe('owner after alias write', O.State());
        O.SetInt(11);
        Observer.Observe('alias after owner write', X.State());
        Observer.Expect('owner', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0 line=1');
        Observer.Expect('alias', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label');
        Observer.Expect('owner after alias write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=10 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0 line=1');
        Observer.Expect('alias after owner write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=11 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label');
        Observer.Verify();
    end;

    [Test]
    procedure Union_T1SharedByCopy_SetLine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner U";
        L: Interface "CLV Line";
        R: Record "CLB Row" temporary;
    begin
        Setup();
        O.Prepare();
        O.ShareT1(R);
        L := O;
        L.SetLine();
        Observer.Observe('r', Format(R.Count()));
        Observer.Observe('owner', O.State());
        R.Init();
        R."No." := 30;
        R.Insert();
        Observer.Observe('owner after r insert', O.State());
        O.WriteT1(31);
        Observer.Observe('r after owner write', Format(R.Count()));
        Observer.Expect('r', '2');
        Observer.Expect('owner', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0 line=1');
        Observer.Expect('owner after r insert', 't1=3 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0 line=1');
        Observer.Expect('r after owner write', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Union_InnerSharer_SetLine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner U";
        L: Interface "CLV Line";
        I: Codeunit "CLV Inner";
    begin
        Setup();
        O.Prepare();
        O.GetInner1(I);
        L := O;
        L.SetLine();
        Observer.Observe('sharer', I.State());
        Observer.Observe('owner', O.State());
        I.Write(20);
        I.Set(9);
        Observer.Observe('owner after sharer write', O.State());
        Observer.Expect('sharer', 'n0,rows1,rec0');
        Observer.Expect('owner', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0 line=1');
        Observer.Expect('owner after sharer write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Late_SevenTemps_Reset()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Resv Owner";
    begin
        Setup();
        O.Prepare();
        Observer.Observe('before', O.State());
        O.Reset();
        Observer.Observe('after', O.State());
        Observer.Expect('before', 'l=1/2/3/4/5/6/7 nested=n5,rows1,rec1 cnt=6 own=2');
        Observer.Expect('after', 'l=1/2/3/4/5/6/7 nested=n0,rows1,rec0 cnt=0 own=0');
        Observer.Verify();
    end;

    [Test]
    procedure Late_NestedSharer_Reset()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Resv Owner";
        I: Codeunit "CLV Inner";
    begin
        Setup();
        O.Prepare();
        O.GetNested(I);
        O.Reset();
        Observer.Observe('sharer', I.State());
        Observer.Observe('owner', O.State());
        I.Write(9);
        I.Set(8);
        Observer.Observe('owner after sharer write', O.State());
        Observer.Expect('sharer', 'n0,rows1,rec0');
        Observer.Expect('owner', 'l=1/2/3/4/5/6/7 nested=n0,rows1,rec0 cnt=0 own=0');
        Observer.Expect('owner after sharer write', 'l=1/2/3/4/5/6/7 nested=n8,rows2,rec0 cnt=0 own=0');
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

codeunit 77247 "CLV Register Shape Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Whse_TableNoOwner_VarSetter_ClearInProcFromRun()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
        I: Codeunit "CLV Inner";
        D: Record "CLV Data";
    begin
        Setup();
        C.Prepare();
        C.GetInner1(I);
        C.HandoffTo(O, false);
        D.Get(1);
        O.Run(D);
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('nested sharer', I.State());
        C.SetInt(11);
        Observer.Observe('owner after caller write', O.State());
        O.SetInt(12);
        Observer.Observe('caller after owner write', C.State());
        I.Write(21);
        I.Set(9);
        Observer.Observe('caller after nested write', C.State());
        Observer.Observe('owner after nested write', O.State());
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=1');
        Observer.Expect('nested sharer', 'n0,rows1,rec0');
        Observer.Expect('owner after caller write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=11 flag=No lc=store label lc2=second label cnt=1');
        Observer.Expect('caller after owner write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('caller after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_TableNoOwner_VarSetter_ClearInProc()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
        I: Codeunit "CLV Inner";
    begin
        Setup();
        C.Prepare();
        C.GetInner1(I);
        C.HandoffTo(O, false);
        O.ClearAllGlobals();
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('nested sharer', I.State());
        C.SetInt(11);
        Observer.Observe('owner after caller write', O.State());
        O.SetInt(12);
        Observer.Observe('caller after owner write', C.State());
        I.Write(21);
        I.Set(9);
        Observer.Observe('caller after nested write', C.State());
        Observer.Observe('owner after nested write', O.State());
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('nested sharer', 'n0,rows1,rec0');
        Observer.Expect('owner after caller write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=11 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('caller after owner write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('caller after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_TableNoOwner_ByValueSetter_ClearInProcFromRun()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
        I: Codeunit "CLV Inner";
        D: Record "CLV Data";
    begin
        Setup();
        C.Prepare();
        C.GetInner1(I);
        C.HandoffTo(O, true);
        D.Get(1);
        O.Run(D);
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('nested sharer', I.State());
        C.SetInt(11);
        Observer.Observe('owner after caller write', O.State());
        O.SetInt(12);
        Observer.Observe('caller after owner write', C.State());
        I.Write(21);
        I.Set(9);
        Observer.Observe('caller after nested write', C.State());
        Observer.Observe('owner after nested write', O.State());
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=1');
        Observer.Expect('nested sharer', 'n0,rows1,rec0');
        Observer.Expect('owner after caller write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=11 flag=No lc=store label lc2=second label cnt=1');
        Observer.Expect('caller after owner write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('caller after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_PlainOwner_VarSetter_ClearInProcFromRun()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner P";
        I: Codeunit "CLV Inner";
    begin
        Setup();
        C.Prepare();
        C.GetInner1(I);
        C.HandoffToPlain(O, false);
        O.Run();
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('nested sharer', I.State());
        C.SetInt(11);
        Observer.Observe('owner after caller write', O.State());
        O.SetInt(12);
        Observer.Observe('caller after owner write', C.State());
        I.Write(21);
        I.Set(9);
        Observer.Observe('caller after nested write', C.State());
        Observer.Observe('owner after nested write', O.State());
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=1');
        Observer.Expect('nested sharer', 'n0,rows1,rec0');
        Observer.Expect('owner after caller write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=11 flag=No lc=store label lc2=second label cnt=1');
        Observer.Expect('caller after owner write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('caller after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_PlainOwner_VarSetter_ClearInProc()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner P";
        I: Codeunit "CLV Inner";
    begin
        Setup();
        C.Prepare();
        C.GetInner1(I);
        C.HandoffToPlain(O, false);
        O.ClearAllGlobals();
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('nested sharer', I.State());
        C.SetInt(11);
        Observer.Observe('owner after caller write', O.State());
        O.SetInt(12);
        Observer.Observe('caller after owner write', C.State());
        I.Write(21);
        I.Set(9);
        Observer.Observe('caller after nested write', C.State());
        Observer.Observe('owner after nested write', O.State());
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('nested sharer', 'n0,rows1,rec0');
        Observer.Expect('owner after caller write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=11 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('caller after owner write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('caller after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_PlainCaller_CallerSideClearAll_VarSetter()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
        I: Codeunit "CLV Inner";
    begin
        Setup();
        C.Prepare();
        C.GetInner1(I);
        C.HandoffTo(O, false);
        C.ClearSelf();
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('nested sharer', I.State());
        C.SetInt(11);
        Observer.Observe('owner after caller write', O.State());
        O.SetInt(12);
        Observer.Observe('caller after owner write', C.State());
        I.Write(21);
        I.Set(9);
        Observer.Observe('caller after nested write', C.State());
        Observer.Observe('owner after nested write', O.State());
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('nested sharer', 'n0,rows1,rec0');
        Observer.Expect('owner after caller write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=11 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('caller after owner write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('caller after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('owner after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_PlainCaller_CallerSideClearAll_ByValueSetter()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
        I: Codeunit "CLV Inner";
    begin
        Setup();
        C.Prepare();
        C.GetInner1(I);
        C.HandoffTo(O, true);
        C.ClearSelf();
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('nested sharer', I.State());
        C.SetInt(11);
        Observer.Observe('owner after caller write', O.State());
        O.SetInt(12);
        Observer.Observe('caller after owner write', C.State());
        I.Write(21);
        I.Set(9);
        Observer.Observe('caller after nested write', C.State());
        Observer.Observe('owner after nested write', O.State());
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('nested sharer', 'n0,rows1,rec0');
        Observer.Expect('owner after caller write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=11 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('caller after owner write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('caller after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('owner after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_TableNoCaller_CallerSideClearAllInRun()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller T";
        O: Codeunit "CLV Post Owner";
        I: Codeunit "CLV Inner";
        D: Record "CLV Data";
    begin
        Setup();
        C.Prepare();
        C.GetInner1(I);
        C.HandoffTo(O, false);
        D.Get(1);
        C.Run(D);
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('nested sharer', I.State());
        C.SetInt(11);
        Observer.Observe('owner after caller write', O.State());
        O.SetInt(12);
        Observer.Observe('caller after owner write', C.State());
        I.Write(21);
        I.Set(9);
        Observer.Observe('caller after nested write', C.State());
        Observer.Observe('owner after nested write', O.State());
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('nested sharer', 'n0,rows1,rec0');
        Observer.Expect('owner after caller write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=11 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('caller after owner write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('caller after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('owner after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_TableNoCaller_CallerSideClearAllInProc()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller T";
        O: Codeunit "CLV Post Owner";
        I: Codeunit "CLV Inner";
    begin
        Setup();
        C.Prepare();
        C.GetInner1(I);
        C.HandoffTo(O, false);
        C.ClearSelf();
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('nested sharer', I.State());
        C.SetInt(11);
        Observer.Observe('owner after caller write', O.State());
        O.SetInt(12);
        Observer.Observe('caller after owner write', C.State());
        I.Write(21);
        I.Set(9);
        Observer.Observe('caller after nested write', C.State());
        Observer.Observe('owner after nested write', O.State());
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('nested sharer', 'n0,rows1,rec0');
        Observer.Expect('owner after caller write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=11 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('caller after owner write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('caller after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Expect('owner after nested write', 'get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 int=12 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Union_TableNoOwner_VarSetter_ClearInProcFromRun()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller U";
        O: Codeunit "CLV Post Owner U";
        I: Codeunit "CLV Inner";
        D: Record "CLV Data";
    begin
        Setup();
        C.Prepare();
        C.GetInner1(I);
        C.HandoffTo(O, false);
        D.Get(1);
        O.Run(D);
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('nested sharer', I.State());
        C.SetInt(11);
        Observer.Observe('owner after caller write', O.State());
        O.SetInt(12);
        Observer.Observe('caller after owner write', C.State());
        I.Write(21);
        I.Set(9);
        Observer.Observe('caller after nested write', C.State());
        Observer.Observe('owner after nested write', O.State());
        Observer.Expect('caller', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=3');
        Observer.Expect('owner', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=1');
        Observer.Expect('nested sharer', 'n0,rows1,rec0');
        Observer.Expect('owner after caller write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=11 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=1');
        Observer.Expect('caller after owner write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=12 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=3');
        Observer.Expect('caller after nested write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 kind=None int=12 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=3');
        Observer.Expect('owner after nested write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 kind=None int=12 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=1');
        Observer.Verify();
    end;

    [Test]
    procedure Union_PlainCaller_CallerSideClearAll_VarSetter()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller U";
        O: Codeunit "CLV Post Owner U";
        I: Codeunit "CLV Inner";
    begin
        Setup();
        C.Prepare();
        C.GetInner1(I);
        C.HandoffTo(O, false);
        C.ClearSelf();
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Observe('nested sharer', I.State());
        C.SetInt(11);
        Observer.Observe('owner after caller write', O.State());
        O.SetInt(12);
        Observer.Observe('caller after owner write', C.State());
        I.Write(21);
        I.Set(9);
        Observer.Observe('caller after nested write', C.State());
        Observer.Observe('owner after nested write', O.State());
        Observer.Expect('caller', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0');
        Observer.Expect('owner', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0');
        Observer.Expect('nested sharer', 'n0,rows1,rec0');
        Observer.Expect('owner after caller write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=11 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0');
        Observer.Expect('caller after owner write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=12 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0');
        Observer.Expect('caller after nested write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 kind=None int=12 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0');
        Observer.Expect('owner after nested write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n9,rows2,rec0 in2=n0,rows1,rec0 kind=None int=12 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0');
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

codeunit 77255 "CLV Register Holder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Whse_InterfaceHolder_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
        H: Codeunit "CLV Face Holder";
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        O.ShareFace(H);
        O.ClearAllGlobals();
        Observer.Observe('interface holder', H.State());
        Observer.Observe('caller', C.State());
        H.SetInt(13);
        Observer.Observe('caller after holder write', C.State());
        Observer.Observe('owner after holder write', O.State());
        Observer.Expect('interface holder', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label hcnt=1');
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('caller after holder write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=13 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner after holder write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=13 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_TestLocalAlias_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
        X: Codeunit "CLV Whse Register";
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        O.GetReg(X);
        O.ClearAllGlobals();
        Observer.Observe('alias', X.State());
        Observer.Observe('caller', C.State());
        X.SetInt(14);
        Observer.Observe('caller after alias write', C.State());
        Observer.Observe('owner after alias write', O.State());
        Observer.Expect('alias', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label');
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('caller after alias write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=14 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner after alias write', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=14 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_LocalAlias_InClearingRoutine()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        Observer.Observe('alias', O.AliasClear());
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Expect('alias', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label');
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=40 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=40 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_ByValueParam_OfClearingRoutine()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        Observer.Observe('param', O.ByValueClear());
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Expect('param', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label');
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=41 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=41 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_InterfaceHolder_HolderClearAll()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
        H: Codeunit "CLV Face Holder";
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        O.ShareFace(H);
        H.ClearAllGlobals();
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_LocalInterface_InClearingRoutine()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        Observer.Observe('interface', O.IfaceClear());
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Expect('interface', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label');
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=42 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=42 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_ByValueParam_OfCallerOfClearingRoutine()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller";
        O: Codeunit "CLV Post Owner";
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        Observer.Observe('param', O.ByValueOuter());
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Expect('param', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label');
        Observer.Expect('caller', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=43 flag=No lc=store label lc2=second label cnt=3');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=43 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_OwnRegister_LocalAlias_InClearingRoutine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Post Owner";
    begin
        Setup();
        O.PrepareOwn();
        Observer.Observe('holder', O.AliasClear());
        Observer.Observe('owner', O.State());
        Observer.Expect('holder', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=40 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_OwnRegister_LocalInterface_InClearingRoutine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Post Owner";
    begin
        Setup();
        O.PrepareOwn();
        Observer.Observe('holder', O.IfaceClear());
        Observer.Observe('owner', O.State());
        Observer.Expect('holder', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=42 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_OwnRegister_ByValueParam_OfClearingRoutine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Post Owner";
    begin
        Setup();
        O.PrepareOwn();
        Observer.Observe('holder', O.ByValueClear());
        Observer.Observe('owner', O.State());
        Observer.Expect('holder', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=41 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Whse_OwnRegister_ByValueParam_OfCallerOfClearingRoutine()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Post Owner";
    begin
        Setup();
        O.PrepareOwn();
        Observer.Observe('holder', O.ByValueOuter());
        Observer.Observe('owner', O.State());
        Observer.Expect('holder', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=0 flag=No lc=store label lc2=second label');
        Observer.Expect('owner', 'get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 int=43 flag=No lc=store label lc2=second label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Union_InterfaceHolder_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller U";
        O: Codeunit "CLV Post Owner U";
        H: Codeunit "CLV Face Holder";
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        O.ShareFace(H);
        O.ClearAllGlobals();
        Observer.Observe('interface holder', H.State());
        Observer.Observe('caller', C.State());
        H.SetInt(13);
        Observer.Observe('caller after holder write', C.State());
        Observer.Observe('owner after holder write', O.State());
        Observer.Expect('interface holder', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label hcnt=1');
        Observer.Expect('caller', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=3');
        Observer.Expect('caller after holder write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=13 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=3');
        Observer.Expect('owner after holder write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=13 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Union_TestLocalAlias_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller U";
        O: Codeunit "CLV Post Owner U";
        X: Codeunit "CLV Table Store";
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        O.GetReg(X);
        O.ClearAllGlobals();
        Observer.Observe('alias', X.State());
        Observer.Observe('caller', C.State());
        X.SetInt(14);
        Observer.Observe('caller after alias write', C.State());
        Observer.Observe('owner after alias write', O.State());
        Observer.Expect('alias', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label');
        Observer.Expect('caller', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=3');
        Observer.Expect('caller after alias write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=14 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=3');
        Observer.Expect('owner after alias write', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=14 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Union_LocalAlias_InClearingRoutine()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller U";
        O: Codeunit "CLV Post Owner U";
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        Observer.Observe('alias', O.AliasClear());
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Expect('alias', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label');
        Observer.Expect('caller', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=40 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=3');
        Observer.Expect('owner', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=40 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0');
        Observer.Verify();
    end;

    [Test]
    procedure Union_ByValueParam_OfClearingRoutine()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLV Post Caller U";
        O: Codeunit "CLV Post Owner U";
    begin
        Setup();
        C.Prepare();
        C.HandoffTo(O, false);
        Observer.Observe('param', O.ByValueClear());
        Observer.Observe('caller', C.State());
        Observer.Observe('owner', O.State());
        Observer.Expect('param', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=0 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label');
        Observer.Expect('caller', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=41 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=3');
        Observer.Expect('owner', 't1=2 t2=1 t3=1 t4=1 t5=1 t6=1 t7=1 get=0: find=:0 ins=0: in1=n0,rows1,rec0 in2=n0,rows1,rec0 kind=None int=41 flag=No txt= dt= opt=A gnull=Yes lc=store label ll=locked label cnt=0');
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
