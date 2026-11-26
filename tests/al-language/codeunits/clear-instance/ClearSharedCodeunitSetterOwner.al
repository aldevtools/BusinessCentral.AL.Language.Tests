// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586) of ClearSharedCodeunitTempRef.al;
//   self-contained objects 77209 to 77214
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: a register codeunit with TableNo ("CLR Register") whose globals are of mixed kinds: a temporary record, a
//   record that is not temporary (a filter and a field value), a Decimal, a Boolean, a Code and a nested codeunit.
//   The caller ("CLR Caller", TableNo) holds the register as a global and hands it to an owner through a setter
//   (var parameter, or by value) that assigns it to the owner's global. The owner then runs ClearAll:
//   - TableNoRun: owner with TableNo, ClearAll in its OnRun, reached by Owner.Run(Rec).
//   - TableNoProc: the same owner, ClearAll in a procedure.
//   - PlainRun / PlainProc: an owner without TableNo, ClearAll in OnRun (Owner.Run()) or in a procedure.
//   Before the ClearAll the caller marks the register (dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4)
//   and puts its temporary table in one state: Rows (2 rows now), Emptied (1 row written, then DeleteAll), Never
//   (never written), Shared* (the same three, the table first shared with a temporary record R of the test through
//   R.Copy(Rows, true)). After the ClearAll each test reads through the caller and the owner, writes through the
//   caller (11) and reads through the owner, writes through the owner (12) and reads through the caller, and for a
//   shared table inserts through R (13) and reads both sides.
//   - Unshared*: the owner's own register, nothing shares it; written (Rows) or written then emptied (Emptied).
//   Measured on BC 29.0 (Linux): every owner kind, setter kind and table state gives the same answer. ClearAll in the
//   owner resets the shared register in place: the caller and the owner stay on one instance (a write through either
//   side shows through the other); the Decimal, Boolean and Code go to 0, No and empty; the filter and the field
//   value of the record that is not temporary are cleared; the nested codeunit reads 0; the owner's own Integer goes
//   to 0. The temporary table keeps what it holds now: 2 rows stay 2, written then emptied and never written read 0.
//   A table shared with R by Copy(Rows, true) stays shared: R reads the kept rows, a write through the caller or the
//   owner shows in R, an insert through R shows through the register. Unshared, the owner's own register gives the
//   same values (2 rows kept, emptied 0, the marks cleared).
// BC versions: 27, 28, 29

codeunit 77209 "CLR Nested"
{
    var
        N: Integer;

    procedure Set(V: Integer)
    begin
        N := V;
    end;

    procedure Get(): Integer
    begin
        exit(N);
    end;
}

codeunit 77210 "CLR Register"
{
    TableNo = "CLB Row";

    var
        Rows: Record "CLB Row" temporary;
        Rec: Record "CLB Row";
        Dec: Decimal;
        Flag: Boolean;
        Cd: Code[20];
        Nested: Codeunit "CLR Nested";

    trigger OnRun()
    begin
        Cd := 'RUN';
    end;

    procedure Mark()
    begin
        Dec := 1.5;
        Flag := true;
        Cd := 'MARK';
        Rec.SetRange("No.", 7);
        Rec."No." := 9;
        Nested.Set(4);
    end;

    procedure WriteRow(V: Integer)
    begin
        Rows.Init();
        Rows."No." := V;
        Rows.Insert();
    end;

    procedure EmptyRows()
    begin
        Rows.DeleteAll();
    end;

    procedure ShareRows(var R: Record "CLB Row" temporary)
    begin
        R.Copy(Rows, true);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('rows=%1 dec=%2 flag=%3 code=%4 recfilter=%5 recno=%6 nested=%7',
            Rows.Count(), Format(Dec, 0, 9), Flag, Cd, Rec.GetFilters(), Rec."No.", Nested.Get()));
    end;
}

codeunit 77211 "CLR TableNo Owner"
{
    TableNo = "CLB Row";

    var
        Reg: Codeunit "CLR Register";
        Cnt: Integer;

    trigger OnRun()
    begin
        ClearAll();
    end;

    procedure SetRegister(var NewReg: Codeunit "CLR Register")
    begin
        Reg := NewReg;
    end;

    procedure SetRegisterByValue(NewReg: Codeunit "CLR Register")
    begin
        Reg := NewReg;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure StateReg(): Text
    begin
        exit(Reg.State());
    end;

    procedure WriteReg(V: Integer)
    begin
        Reg.WriteRow(V);
    end;

    procedure EmptyReg()
    begin
        Reg.EmptyRows();
    end;

    procedure MarkReg()
    begin
        Reg.Mark();
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

codeunit 77212 "CLR Plain Owner"
{
    var
        Reg: Codeunit "CLR Register";
        Cnt: Integer;

    trigger OnRun()
    begin
        ClearAll();
    end;

    procedure SetRegister(var NewReg: Codeunit "CLR Register")
    begin
        Reg := NewReg;
    end;

    procedure SetRegisterByValue(NewReg: Codeunit "CLR Register")
    begin
        Reg := NewReg;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure StateReg(): Text
    begin
        exit(Reg.State());
    end;

    procedure WriteReg(V: Integer)
    begin
        Reg.WriteRow(V);
    end;

    procedure EmptyReg()
    begin
        Reg.EmptyRows();
    end;

    procedure MarkReg()
    begin
        Reg.Mark();
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

codeunit 77213 "CLR Caller"
{
    TableNo = "CLB Row";

    var
        Reg: Codeunit "CLR Register";
        TOwner: Codeunit "CLR TableNo Owner";
        POwner: Codeunit "CLR Plain Owner";

    trigger OnRun()
    begin
    end;

    procedure MarkReg()
    begin
        Reg.Mark();
    end;

    procedure WriteReg(V: Integer)
    begin
        Reg.WriteRow(V);
    end;

    procedure EmptyReg()
    begin
        Reg.EmptyRows();
    end;

    procedure ShareRows(var R: Record "CLB Row" temporary)
    begin
        Reg.ShareRows(R);
    end;

    procedure StateReg(): Text
    begin
        exit(Reg.State());
    end;

    procedure Handoff(Kind: Integer; ByValue: Boolean)
    begin
        if Kind in [1, 2] then
            if ByValue then
                TOwner.SetRegisterByValue(Reg)
            else
                TOwner.SetRegister(Reg)
        else
            if ByValue then
                POwner.SetRegisterByValue(Reg)
            else
                POwner.SetRegister(Reg);
    end;

    procedure ClearOwner(Kind: Integer)
    var
        Row: Record "CLB Row";
    begin
        case Kind of
            1:
                TOwner.Run(Row);
            2:
                TOwner.ClearAllGlobals();
            3:
                POwner.Run();
            4:
                POwner.ClearAllGlobals();
        end;
    end;

    procedure OwnerState(Kind: Integer): Text
    begin
        if Kind in [1, 2] then
            exit(TOwner.StateReg());
        exit(POwner.StateReg());
    end;

    procedure OwnerWrite(Kind: Integer; V: Integer)
    begin
        if Kind in [1, 2] then
            TOwner.WriteReg(V)
        else
            POwner.WriteReg(V);
    end;

    procedure SetOwnerCnt(Kind: Integer; V: Integer)
    begin
        if Kind in [1, 2] then
            TOwner.SetCnt(V)
        else
            POwner.SetCnt(V);
    end;

    procedure OwnerCnt(Kind: Integer): Integer
    begin
        if Kind in [1, 2] then
            exit(TOwner.GetCnt());
        exit(POwner.GetCnt());
    end;
}

codeunit 77214 "CLR Setter Owner Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TableNoRun_VarSetter_Rows()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.WriteReg(1);
        C.WriteReg(2);
        C.Handoff(1, false);
        C.SetOwnerCnt(1, 5);
        C.ClearOwner(1);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(1));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(1)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(1));
        C.OwnerWrite(1, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoRun_VarSetter_Emptied()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.WriteReg(1);
        C.EmptyReg();
        C.Handoff(1, false);
        C.SetOwnerCnt(1, 5);
        C.ClearOwner(1);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(1));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(1)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(1));
        C.OwnerWrite(1, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoRun_VarSetter_Never()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.Handoff(1, false);
        C.SetOwnerCnt(1, 5);
        C.ClearOwner(1);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(1));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(1)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(1));
        C.OwnerWrite(1, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoRun_VarSetter_SharedRows()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.WriteReg(1);
        C.Handoff(1, false);
        C.SetOwnerCnt(1, 5);
        C.ClearOwner(1);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(1));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(1)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(1));
        C.OwnerWrite(1, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '1');
        Observer.Expect('owner after caller write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '4');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoRun_VarSetter_SharedNever()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.Handoff(1, false);
        C.SetOwnerCnt(1, 5);
        C.ClearOwner(1);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(1));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(1)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(1));
        C.OwnerWrite(1, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '3');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoRun_VarSetter_SharedEmptied()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.WriteReg(1);
        C.EmptyReg();
        C.Handoff(1, false);
        C.SetOwnerCnt(1, 5);
        C.ClearOwner(1);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(1));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(1)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(1));
        C.OwnerWrite(1, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '3');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoProc_VarSetter_Rows()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.WriteReg(1);
        C.WriteReg(2);
        C.Handoff(2, false);
        C.SetOwnerCnt(2, 5);
        C.ClearOwner(2);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(2));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(2)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(2));
        C.OwnerWrite(2, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoProc_VarSetter_Emptied()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.WriteReg(1);
        C.EmptyReg();
        C.Handoff(2, false);
        C.SetOwnerCnt(2, 5);
        C.ClearOwner(2);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(2));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(2)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(2));
        C.OwnerWrite(2, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoProc_VarSetter_Never()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.Handoff(2, false);
        C.SetOwnerCnt(2, 5);
        C.ClearOwner(2);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(2));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(2)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(2));
        C.OwnerWrite(2, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoProc_VarSetter_SharedRows()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.WriteReg(1);
        C.Handoff(2, false);
        C.SetOwnerCnt(2, 5);
        C.ClearOwner(2);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(2));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(2)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(2));
        C.OwnerWrite(2, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '1');
        Observer.Expect('owner after caller write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '4');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoProc_VarSetter_SharedNever()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.Handoff(2, false);
        C.SetOwnerCnt(2, 5);
        C.ClearOwner(2);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(2));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(2)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(2));
        C.OwnerWrite(2, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '3');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoProc_VarSetter_SharedEmptied()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.WriteReg(1);
        C.EmptyReg();
        C.Handoff(2, false);
        C.SetOwnerCnt(2, 5);
        C.ClearOwner(2);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(2));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(2)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(2));
        C.OwnerWrite(2, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '3');
        Observer.Verify();
    end;

    [Test]
    procedure PlainRun_VarSetter_Rows()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.WriteReg(1);
        C.WriteReg(2);
        C.Handoff(3, false);
        C.SetOwnerCnt(3, 5);
        C.ClearOwner(3);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(3));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(3)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(3));
        C.OwnerWrite(3, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainRun_VarSetter_Emptied()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.WriteReg(1);
        C.EmptyReg();
        C.Handoff(3, false);
        C.SetOwnerCnt(3, 5);
        C.ClearOwner(3);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(3));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(3)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(3));
        C.OwnerWrite(3, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainRun_VarSetter_Never()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.Handoff(3, false);
        C.SetOwnerCnt(3, 5);
        C.ClearOwner(3);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(3));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(3)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(3));
        C.OwnerWrite(3, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainRun_VarSetter_SharedRows()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.WriteReg(1);
        C.Handoff(3, false);
        C.SetOwnerCnt(3, 5);
        C.ClearOwner(3);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(3));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(3)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(3));
        C.OwnerWrite(3, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '1');
        Observer.Expect('owner after caller write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '4');
        Observer.Verify();
    end;

    [Test]
    procedure PlainRun_VarSetter_SharedNever()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.Handoff(3, false);
        C.SetOwnerCnt(3, 5);
        C.ClearOwner(3);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(3));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(3)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(3));
        C.OwnerWrite(3, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '3');
        Observer.Verify();
    end;

    [Test]
    procedure PlainRun_VarSetter_SharedEmptied()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.WriteReg(1);
        C.EmptyReg();
        C.Handoff(3, false);
        C.SetOwnerCnt(3, 5);
        C.ClearOwner(3);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(3));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(3)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(3));
        C.OwnerWrite(3, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '3');
        Observer.Verify();
    end;

    [Test]
    procedure PlainProc_VarSetter_Rows()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.WriteReg(1);
        C.WriteReg(2);
        C.Handoff(4, false);
        C.SetOwnerCnt(4, 5);
        C.ClearOwner(4);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(4));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(4)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(4));
        C.OwnerWrite(4, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainProc_VarSetter_Emptied()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.WriteReg(1);
        C.EmptyReg();
        C.Handoff(4, false);
        C.SetOwnerCnt(4, 5);
        C.ClearOwner(4);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(4));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(4)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(4));
        C.OwnerWrite(4, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainProc_VarSetter_Never()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.Handoff(4, false);
        C.SetOwnerCnt(4, 5);
        C.ClearOwner(4);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(4));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(4)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(4));
        C.OwnerWrite(4, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainProc_VarSetter_SharedRows()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.WriteReg(1);
        C.Handoff(4, false);
        C.SetOwnerCnt(4, 5);
        C.ClearOwner(4);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(4));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(4)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(4));
        C.OwnerWrite(4, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '1');
        Observer.Expect('owner after caller write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '4');
        Observer.Verify();
    end;

    [Test]
    procedure PlainProc_VarSetter_SharedNever()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.Handoff(4, false);
        C.SetOwnerCnt(4, 5);
        C.ClearOwner(4);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(4));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(4)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(4));
        C.OwnerWrite(4, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '3');
        Observer.Verify();
    end;

    [Test]
    procedure PlainProc_VarSetter_SharedEmptied()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.WriteReg(1);
        C.EmptyReg();
        C.Handoff(4, false);
        C.SetOwnerCnt(4, 5);
        C.ClearOwner(4);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(4));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(4)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(4));
        C.OwnerWrite(4, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '3');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoRun_ByValueSetter_Rows()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.WriteReg(1);
        C.WriteReg(2);
        C.Handoff(1, true);
        C.SetOwnerCnt(1, 5);
        C.ClearOwner(1);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(1));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(1)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(1));
        C.OwnerWrite(1, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoRun_ByValueSetter_Never()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
    begin
        C.MarkReg();
        C.Handoff(1, true);
        C.SetOwnerCnt(1, 5);
        C.ClearOwner(1);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(1));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(1)));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(1));
        C.OwnerWrite(1, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoRun_ByValueSetter_SharedNever()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "CLR Caller";
        R: Record "CLB Row" temporary;
    begin
        C.MarkReg();
        C.ShareRows(R);
        C.Handoff(1, true);
        C.SetOwnerCnt(1, 5);
        C.ClearOwner(1);
        Observer.Observe('caller', C.StateReg());
        Observer.Observe('owner', C.OwnerState(1));
        Observer.Observe('owner cnt', Format(C.OwnerCnt(1)));
        Observer.Observe('outside rows', Format(R.Count()));
        C.WriteReg(11);
        Observer.Observe('owner after caller write', C.OwnerState(1));
        C.OwnerWrite(1, 12);
        Observer.Observe('caller after owner write', C.StateReg());
        R.Init();
        R."No." := 13;
        R.Insert();
        Observer.Observe('caller after outside insert', C.StateReg());
        Observer.Observe('outside rows after insert', Format(R.Count()));
        Observer.Expect('caller', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('outside rows', '0');
        Observer.Expect('owner after caller write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller after outside insert', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('outside rows after insert', '3');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoOwner_Unshared_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
    begin
        O.MarkReg();
        O.WriteReg(1);
        O.WriteReg(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        O.WriteReg(11);
        Observer.Observe('owner after write', O.StateReg());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoOwner_Unshared_Emptied()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
    begin
        O.MarkReg();
        O.WriteReg(1);
        O.EmptyReg();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        O.WriteReg(11);
        Observer.Observe('owner after write', O.StateReg());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainOwner_Unshared_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
    begin
        O.MarkReg();
        O.WriteReg(1);
        O.WriteReg(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        O.WriteReg(11);
        Observer.Observe('owner after write', O.StateReg());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainOwner_Unshared_Emptied()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
    begin
        O.MarkReg();
        O.WriteReg(1);
        O.EmptyReg();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        O.WriteReg(11);
        Observer.Observe('owner after write', O.StateReg());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('owner after write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;
}
