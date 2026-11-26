// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CKK Row" (table 86270) of ClearSharedCodeunitGlobalKinds.al; self-contained objects 86720 to 86734
// Probe: ClearAll in an owner codeunit whose register codeunit another variable shares, in the shape of "Sales-Post" holding
// "Whse. Jnl.-Register Line" (al-runner issues 9194 and 9176), observed first, then asserted.
// singleinstance-shared-on-purpose: the subject is a SingleInstance codeunit held below a register that ClearAll resets.
// BC versions: 27, 28, 29
// What BC did: OBSERVE
codeunit 86720 "CSW Impl"
{
    SingleInstance = true;

    var
        Handled: Boolean;
        N: Integer;

    procedure Prime(V: Integer)
    begin
        Handled := true;
        N := V;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('impl[%1,%2]', Handled, N));
    end;
}

codeunit 86721 "CSW Confirm"
{
    SingleInstance = true;

    var
        Impl: Codeunit "CSW Impl";
        N: Integer;

    procedure Prime(V: Integer)
    begin
        N := V;
        Impl.Prime(V + 1);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('confirm[%1]', N) + Impl.State());
    end;
}

codeunit 86722 "CSW Mid"
{
    var
        Rows: Record "CKK Row";
        Confirm: Codeunit "CSW Confirm";
        N: Integer;

    procedure Prime(V: Integer)
    begin
        N := V;
        Rows.SetRange("No.", V);
        Confirm.Prime(V + 10);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('mid[%1,%2]', N, Rows.GetFilter("No.")) + Confirm.State());
    end;
}

codeunit 86723 "CSW Reg"
{
    TableNo = "CKK Row";

    var
        Loc: Record "CKK Row";
        Mid: Codeunit "CSW Mid";
        EntryNo: Integer;
        Text000: Label 'Qty %1 short', Comment = '%1 = quantity';
        Text001: Label 'Serial %1 found';
        OnMove: Boolean;

    trigger OnRun()
    begin
        EntryNo := Rec."No.";
    end;

    procedure Prime(V: Integer)
    begin
        EntryNo := V;
        OnMove := true;
        Loc.SetRange("No.", V);
        Mid.Prime(V + 100);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('reg[%1,%2,%3,%4,%5]', EntryNo, OnMove, Loc.GetFilter("No."), StrSubstNo(Text000, 1), StrSubstNo(Text001, 2)) + Mid.State());
    end;
}

codeunit 86724 "CSW Owner"
{
    TableNo = "CKK Row";

    var
        Reg: Codeunit "CSW Reg";
        Posted: Integer;

    trigger OnRun()
    begin
        Posted := Rec."No.";
    end;

    procedure SetReg(var R: Codeunit "CSW Reg")
    begin
        Reg := R;
        Posted := 7;
    end;

    procedure PrimeOwn(V: Integer)
    begin
        Reg.Prime(V);
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('owner[%1]', Posted) + Reg.State());
    end;
}

codeunit 86725 "CSW KSi"
{
    SingleInstance = true;

    var
        N: Integer;

    procedure Prime(V: Integer)
    begin
        N := V;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('ksi[%1]', N));
    end;
}

codeunit 86726 "CSW KReg"
{
    TableNo = "CKK Row";

    var
        Si: Codeunit "CSW KSi";
        N: Integer;
        T: Text;
        T30: Text[30];
        C20: Code[20];
        Dec: Decimal;
        Dt: Date;
        Big: BigInteger;
        Opt: Option A,B,C;
        Ch: Char;
        Flag: Boolean;
        LblC: Label 'comment %1', Comment = '%1 = n';
        LblP: Label 'plain %1';
        LblL: Label 'locked', Locked = true;

    trigger OnRun()
    begin
        N := Rec."No.";
    end;

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        T30 := 'u' + Format(V);
        C20 := 'C' + Format(V);
        Dec := V + 0.5;
        Dt := DMY2Date(1, 2, 2020);
        Big := V * 1000;
        Opt := Opt::C;
        Ch := 65;
        Flag := true;
        Si.Prime(V + 1);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('kreg[%1,%2,%3,%4,%5,%6,%7,%8,%9,', N, T, T30, C20, Format(Dec, 0, 9), Format(Dt, 0, 9), Big, Opt, Format(Ch))
            + StrSubstNo('%1,%2,%3,%4]', Flag, StrSubstNo(LblC, 1), StrSubstNo(LblP, 2), LblL) + Si.State());
    end;
}

codeunit 86727 "CSW KOwner"
{
    TableNo = "CKK Row";

    var
        Reg: Codeunit "CSW KReg";

    trigger OnRun()
    begin
    end;

    procedure SetReg(var R: Codeunit "CSW KReg")
    begin
        Reg := R;
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;
}

codeunit 86728 "CSW D3"
{
    var
        Rows: Record "CKK Row";
        N: Integer;
        LblC: Label 'deep %1', Comment = '%1 = n';

    procedure Prime(V: Integer)
    begin
        N := V;
        Rows.SetRange("No.", V);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('d3[%1,%2,%3]', N, Rows.GetFilter("No."), StrSubstNo(LblC, 3)));
    end;
}

codeunit 86729 "CSW D2Si"
{
    SingleInstance = true;

    var
        D3: Codeunit "CSW D3";
        N: Integer;

    procedure Prime(V: Integer)
    begin
        N := V;
        D3.Prime(V + 1);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('d2si[%1]', N) + D3.State());
    end;
}

codeunit 86730 "CSW D2P"
{
    var
        D3: Codeunit "CSW D3";
        N: Integer;

    procedure Prime(V: Integer)
    begin
        N := V;
        D3.Prime(V + 1);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('d2p[%1]', N) + D3.State());
    end;
}

codeunit 86731 "CSW D1"
{
    var
        Si: Codeunit "CSW D2Si";
        P: Codeunit "CSW D2P";
        N: Integer;

    procedure Prime(V: Integer)
    begin
        N := V;
        Si.Prime(V + 10);
        P.Prime(V + 20);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('d1[%1]', N) + Si.State() + P.State());
    end;
}

codeunit 86732 "CSW DReg"
{
    TableNo = "CKK Row";

    var
        D1: Codeunit "CSW D1";
        N: Integer;

    trigger OnRun()
    begin
        N := Rec."No.";
    end;

    procedure Prime(V: Integer)
    begin
        N := V;
        D1.Prime(V + 100);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('dreg[%1]', N) + D1.State());
    end;
}

codeunit 86733 "CSW DOwner"
{
    TableNo = "CKK Row";

    var
        Reg: Codeunit "CSW DReg";

    trigger OnRun()
    begin
    end;

    procedure SetReg(var R: Codeunit "CSW DReg")
    begin
        Reg := R;
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;
}

codeunit 86734 "CSW Test"
{
    Subtype = Test;

    [Test]
    procedure Whse_OwnerClearAll_EveryLevel()
    var
        Observer: Codeunit "Probe Observer";
        R: Codeunit "CSW Reg";
        Owner: Codeunit "CSW Owner";
        Confirm: Codeunit "CSW Confirm";
        Impl: Codeunit "CSW Impl";
        Mid: Codeunit "CSW Mid";
    begin
        R.Prime(1000);
        Owner.SetReg(R);
        Observer.Observe('before.r', R.State());
        Observer.Observe('before.owner', Owner.State());
        Owner.DoClearAll();
        Observer.Observe('after.r', R.State());
        Observer.Observe('after.owner', Owner.State());
        Observer.Observe('after.confirm', Confirm.State());
        Observer.Observe('after.impl', Impl.State());
        Observer.Observe('after.mid', Mid.State());
        Observer.Finish();
    end;

    [Test]
    procedure Whse_OwnerPrimes_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        R: Codeunit "CSW Reg";
        Owner: Codeunit "CSW Owner";
        Confirm: Codeunit "CSW Confirm";
    begin
        Owner.SetReg(R);
        Owner.PrimeOwn(2000);
        Observer.Observe('before.r', R.State());
        Owner.DoClearAll();
        Observer.Observe('after.r', R.State());
        Observer.Observe('after.owner', Owner.State());
        Confirm.Prime(2500);
        Observer.Observe('direct.r', R.State());
        R.Prime(2600);
        Observer.Observe('reprime.owner', Owner.State());
        Observer.Finish();
    end;

    [Test]
    procedure Whse_DirectSiWrite_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        R: Codeunit "CSW Reg";
        Owner: Codeunit "CSW Owner";
        Impl: Codeunit "CSW Impl";
    begin
        R.Prime(3000);
        Owner.SetReg(R);
        Impl.Prime(3333);
        Owner.DoClearAll();
        Observer.Observe('after.r', R.State());
        Observer.Observe('after.impl', Impl.State());
        Observer.Finish();
    end;

    [Test]
    procedure Kinds_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        R: Codeunit "CSW KReg";
        Owner: Codeunit "CSW KOwner";
        Si: Codeunit "CSW KSi";
    begin
        R.Prime(40);
        Owner.SetReg(R);
        Observer.Observe('before.r', R.State());
        Owner.DoClearAll();
        Observer.Observe('after.r', R.State());
        Observer.Observe('after.si', Si.State());
        Observer.Finish();
    end;

    [Test]
    procedure Deep_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        R: Codeunit "CSW DReg";
        Owner: Codeunit "CSW DOwner";
        D2: Codeunit "CSW D2Si";
        D3: Codeunit "CSW D3";
    begin
        R.Prime(5000);
        Owner.SetReg(R);
        Observer.Observe('before.r', R.State());
        Owner.DoClearAll();
        Observer.Observe('after.r', R.State());
        Observer.Observe('after.d2si', D2.State());
        Observer.Observe('after.d3', D3.State());
        D2.Prime(5500);
        Observer.Observe('direct.r', R.State());
        Observer.Finish();
    end;
}
