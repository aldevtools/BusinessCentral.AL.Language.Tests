// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CKK Row" (table 86270) of ClearSharedCodeunitGlobalKinds.al; "CNC Reg Entry",
// "CNC U", "CNC I", "CNC Reg" and "CNC Owner" (86890 to 86898) of ClearSharedCodeunitNeverCalledTree.al; own objects 86901 to 86907
// Probe: the call shapes around the ClearAll of ClearSharedCodeunitNeverCalledTree.al. There a plain holder ("CNC Holder") holds
// the register and the owner in globals and runs the owner from a public procedure; the owner's OnRun reaches ClearAll through
// a local RunWithCheck. "Whse.-Activity-Post" running "Sales-Post" (BC 29) differs in four facts, and each cell here changes one
// of them against that shape:
// - TableNo: the holder has a TableNo (called through its public procedure, and entered through its own OnRun by Run).
// - LocalProc: the holder runs the owner from a local procedure (PostSourceDocument).
// - LocalOwner: the holder holds the owner in a local variable of the procedure that runs it.
// - Internal: the owner's RunWithCheck is `internal`, not local.
// - Activity: all four together, entered by Run on the holder; OnRun -> local Code -> local PostSourceDoc -> local
//   PostSourceDocument (owner in a local) -> owner Run -> OnRun -> internal RunWithCheck -> local ClearAllVariables -> ClearAll.
// Each cell observes what the holder (the later reader of the shared register) sees after the owner's ClearAll:
// a register never called before, with a write by the owner right after its ClearAll (Cnt := 21); a register written before
// (every global set through the holder), with the same write; and a register run by the owner right after its ClearAll, then by
// the holder. "ClearAll clears the shared instance" and "ClearAll only drops the owner's reference" predict different values
// in every one of these cells. al-runner issue 8964.
// BC versions: 27, 28, 29
codeunit 86901 "CNC Owner Internal"
{
    TableNo = "CKK Row";

    var
        WhseJnlPostLine: Codeunit "CNC Reg";
        Mode: Integer;

    trigger OnRun()
    begin
        RunWithCheck(Rec);
    end;

    internal procedure RunWithCheck(var Header: Record "CKK Row")
    var
        M: Integer;
    begin
        M := Mode;
        ClearAllVariables();
        case M of
            1:
                WhseJnlPostLine.SetCnt(21);
            2:
                RunReg();
        end;
    end;

    local procedure ClearAllVariables()
    begin
        ClearAll();
    end;

    procedure SetWhseJnlRegisterCU(var R: Codeunit "CNC Reg")
    begin
        WhseJnlPostLine := R;
    end;

    procedure SetMode(M: Integer)
    begin
        Mode := M;
    end;

    procedure State(): Text
    begin
        exit(WhseJnlPostLine.State());
    end;

    procedure RunReg()
    var
        TempRow: Record "CKK Row" temporary;
    begin
        TempRow."No." := 8;
        TempRow.Insert();
        WhseJnlPostLine.Run(TempRow);
    end;
}

codeunit 86902 "CNC Holder TableNo"
{
    TableNo = "CKK Row";

    var
        WhseJnlRegisterLine: Codeunit "CNC Reg";
        SalesPost: Codeunit "CNC Owner";
        Mode: Integer;

    trigger OnRun()
    begin
        Post(Mode);
    end;

    procedure SetMode(M: Integer)
    begin
        Mode := M;
    end;

    procedure Post(M: Integer)
    var
        TempHeader: Record "CKK Row" temporary;
    begin
        SalesPost.SetWhseJnlRegisterCU(WhseJnlRegisterLine);
        SalesPost.SetMode(M);
        TempHeader."No." := 1;
        TempHeader.Insert();
        SalesPost.Run(TempHeader);
    end;

    procedure WriteRegister(V: Integer)
    begin
        WhseJnlRegisterLine.SetAll(V);
    end;

    procedure RunReg()
    var
        TempRow: Record "CKK Row" temporary;
    begin
        TempRow."No." := 7;
        TempRow.Insert();
        WhseJnlRegisterLine.Run(TempRow);
    end;

    procedure State(): Text
    begin
        exit(WhseJnlRegisterLine.State());
    end;

    procedure OwnerState(): Text
    begin
        exit(SalesPost.State());
    end;

    procedure StateA(): Text
    begin
        exit(WhseJnlRegisterLine.StateA());
    end;

    procedure StateB(): Text
    begin
        exit(WhseJnlRegisterLine.StateB());
    end;

    procedure StateSI(): Text
    begin
        exit(WhseJnlRegisterLine.StateSI());
    end;
}

codeunit 86903 "CNC Holder LocalProc"
{
    var
        WhseJnlRegisterLine: Codeunit "CNC Reg";
        SalesPost: Codeunit "CNC Owner";

    procedure Post(M: Integer)
    begin
        PostSourceDocument(M);
    end;

    local procedure PostSourceDocument(M: Integer)
    var
        TempHeader: Record "CKK Row" temporary;
    begin
        SalesPost.SetWhseJnlRegisterCU(WhseJnlRegisterLine);
        SalesPost.SetMode(M);
        TempHeader."No." := 1;
        TempHeader.Insert();
        SalesPost.Run(TempHeader);
    end;

    procedure WriteRegister(V: Integer)
    begin
        WhseJnlRegisterLine.SetAll(V);
    end;

    procedure RunReg()
    var
        TempRow: Record "CKK Row" temporary;
    begin
        TempRow."No." := 7;
        TempRow.Insert();
        WhseJnlRegisterLine.Run(TempRow);
    end;

    procedure State(): Text
    begin
        exit(WhseJnlRegisterLine.State());
    end;

    procedure OwnerState(): Text
    begin
        exit(SalesPost.State());
    end;

    procedure StateA(): Text
    begin
        exit(WhseJnlRegisterLine.StateA());
    end;

    procedure StateB(): Text
    begin
        exit(WhseJnlRegisterLine.StateB());
    end;

    procedure StateSI(): Text
    begin
        exit(WhseJnlRegisterLine.StateSI());
    end;
}

codeunit 86904 "CNC Holder LocalOwner"
{
    var
        WhseJnlRegisterLine: Codeunit "CNC Reg";
        OwnerView: Text;

    procedure Post(M: Integer)
    var
        TempHeader: Record "CKK Row" temporary;
        SalesPost: Codeunit "CNC Owner";
    begin
        SalesPost.SetWhseJnlRegisterCU(WhseJnlRegisterLine);
        SalesPost.SetMode(M);
        TempHeader."No." := 1;
        TempHeader.Insert();
        SalesPost.Run(TempHeader);
        OwnerView := SalesPost.State();
    end;

    procedure WriteRegister(V: Integer)
    begin
        WhseJnlRegisterLine.SetAll(V);
    end;

    procedure RunReg()
    var
        TempRow: Record "CKK Row" temporary;
    begin
        TempRow."No." := 7;
        TempRow.Insert();
        WhseJnlRegisterLine.Run(TempRow);
    end;

    procedure State(): Text
    begin
        exit(WhseJnlRegisterLine.State());
    end;

    procedure OwnerState(): Text
    begin
        exit(OwnerView);
    end;

    procedure StateA(): Text
    begin
        exit(WhseJnlRegisterLine.StateA());
    end;

    procedure StateB(): Text
    begin
        exit(WhseJnlRegisterLine.StateB());
    end;

    procedure StateSI(): Text
    begin
        exit(WhseJnlRegisterLine.StateSI());
    end;
}

codeunit 86905 "CNC Holder Internal"
{
    var
        WhseJnlRegisterLine: Codeunit "CNC Reg";
        SalesPost: Codeunit "CNC Owner Internal";

    procedure Post(M: Integer)
    var
        TempHeader: Record "CKK Row" temporary;
    begin
        SalesPost.SetWhseJnlRegisterCU(WhseJnlRegisterLine);
        SalesPost.SetMode(M);
        TempHeader."No." := 1;
        TempHeader.Insert();
        SalesPost.Run(TempHeader);
    end;

    procedure WriteRegister(V: Integer)
    begin
        WhseJnlRegisterLine.SetAll(V);
    end;

    procedure RunReg()
    var
        TempRow: Record "CKK Row" temporary;
    begin
        TempRow."No." := 7;
        TempRow.Insert();
        WhseJnlRegisterLine.Run(TempRow);
    end;

    procedure State(): Text
    begin
        exit(WhseJnlRegisterLine.State());
    end;

    procedure OwnerState(): Text
    begin
        exit(SalesPost.State());
    end;

    procedure StateA(): Text
    begin
        exit(WhseJnlRegisterLine.StateA());
    end;

    procedure StateB(): Text
    begin
        exit(WhseJnlRegisterLine.StateB());
    end;

    procedure StateSI(): Text
    begin
        exit(WhseJnlRegisterLine.StateSI());
    end;
}

codeunit 86906 "CNC Holder Activity"
{
    TableNo = "CKK Row";

    var
        WhseJnlRegisterLine: Codeunit "CNC Reg";
        Mode: Integer;
        RegisterAfter: Boolean;
        OwnerView: Text;
        InsideView: Text;

    trigger OnRun()
    begin
        Code();
    end;

    local procedure Code()
    begin
        PostSourceDoc();
        if RegisterAfter then begin
            RunReg();
            InsideView := WhseJnlRegisterLine.State();
        end;
    end;

    local procedure PostSourceDoc()
    begin
        PostSourceDocument();
    end;

    local procedure PostSourceDocument()
    var
        SalesHeader: Record "CKK Row" temporary;
        SalesPost: Codeunit "CNC Owner Internal";
    begin
        SalesHeader."No." := 1;
        SalesHeader.Insert();
        SalesPost.SetWhseJnlRegisterCU(WhseJnlRegisterLine);
        SalesPost.SetMode(Mode);
        SalesPost.Run(SalesHeader);
        OwnerView := SalesPost.State();
    end;

    procedure SetMode(M: Integer; RunAfter: Boolean)
    begin
        Mode := M;
        RegisterAfter := RunAfter;
    end;

    procedure WriteRegister(V: Integer)
    begin
        WhseJnlRegisterLine.SetAll(V);
    end;

    procedure RunReg()
    var
        TempRow: Record "CKK Row" temporary;
    begin
        TempRow."No." := 7;
        TempRow.Insert();
        WhseJnlRegisterLine.Run(TempRow);
    end;

    procedure State(): Text
    begin
        exit(WhseJnlRegisterLine.State());
    end;

    procedure OwnerState(): Text
    begin
        exit(OwnerView);
    end;

    procedure InsideState(): Text
    begin
        exit(InsideView);
    end;

    procedure StateA(): Text
    begin
        exit(WhseJnlRegisterLine.StateA());
    end;

    procedure StateB(): Text
    begin
        exit(WhseJnlRegisterLine.StateB());
    end;

    procedure StateSI(): Text
    begin
        exit(WhseJnlRegisterLine.StateSI());
    end;
}

codeunit 86907 "CNC Shape Test"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Prime(Seed: Integer)
    var
        UomMgt: Codeunit "CNC U";
        Impl: Codeunit "CNC I";
    begin
        UomMgt.Set(Seed);
        Impl.SetFlag(true);
    end;

    local procedure ResetEntries(WithRow: Boolean)
    var
        Entry: Record "CNC Reg Entry";
    begin
        Entry.DeleteAll();
        if WithRow then begin
            Entry."No." := 4;
            Entry.Runs := 0;
            Entry.Insert();
        end;
    end;

    local procedure Entries(): Text
    var
        Entry: Record "CNC Reg Entry";
        Result: Text;
    begin
        if Entry.FindSet() then
            repeat
                Result += StrSubstNo('%1:%2;', Entry."No.", Entry.Runs);
            until Entry.Next() = 0;
        exit('entries[' + Result + ']');
    end;

    local procedure Header(var Row: Record "CKK Row" temporary)
    begin
        Row."No." := 1;
        Row.Insert();
    end;

    // TableNo holder, called through its public procedure

    [Test]
    procedure TableNo_NeverCalled_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder TableNo";
    begin
        ResetEntries(false);
        Prime(71);
        H.Post(1);
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('entries', Entries());
        Observer.Finish();
    end;

    [Test]
    procedure TableNo_WrittenBefore_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder TableNo";
    begin
        ResetEntries(false);
        Prime(72);
        H.WriteRegister(5);
        H.Post(1);
        Observer.Observe('holder', H.State());
        Observer.Observe('a', H.StateA());
        Observer.Observe('b', H.StateB());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('owner', H.OwnerState());
        Observer.Finish();
    end;

    [Test]
    procedure TableNo_NeverCalled_OwnerRunsInOnRun_ThenHolderRuns()
    var
        H: Codeunit "CNC Holder TableNo";
    begin
        ResetEntries(true);
        Prime(73);
        H.Post(2);
        Observer.Observe('first.holder', H.State());
        Observer.Observe('first.entries', Entries());
        H.RunReg();
        Observer.Observe('second.holder', H.State());
        Observer.Observe('second.owner', H.OwnerState());
        Observer.Observe('second.entries', Entries());
        Observer.Finish();
    end;

    // TableNo holder, entered through its own OnRun by Run

    [Test]
    procedure TableNoRun_NeverCalled_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder TableNo";
        Row: Record "CKK Row" temporary;
    begin
        ResetEntries(false);
        Prime(74);
        H.SetMode(1);
        Header(Row);
        H.Run(Row);
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('entries', Entries());
        Observer.Finish();
    end;

    [Test]
    procedure TableNoRun_WrittenBefore_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder TableNo";
        Row: Record "CKK Row" temporary;
    begin
        ResetEntries(false);
        Prime(75);
        H.WriteRegister(5);
        H.SetMode(1);
        Header(Row);
        H.Run(Row);
        Observer.Observe('holder', H.State());
        Observer.Observe('a', H.StateA());
        Observer.Observe('b', H.StateB());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('owner', H.OwnerState());
        Observer.Finish();
    end;

    [Test]
    procedure TableNoRun_NeverCalled_OwnerRunsInOnRun_ThenHolderRuns()
    var
        H: Codeunit "CNC Holder TableNo";
        Row: Record "CKK Row" temporary;
    begin
        ResetEntries(true);
        Prime(76);
        H.SetMode(2);
        Header(Row);
        H.Run(Row);
        Observer.Observe('first.holder', H.State());
        Observer.Observe('first.entries', Entries());
        H.RunReg();
        Observer.Observe('second.holder', H.State());
        Observer.Observe('second.owner', H.OwnerState());
        Observer.Observe('second.entries', Entries());
        Observer.Finish();
    end;

    // Holder runs the owner from a local procedure

    [Test]
    procedure LocalProc_NeverCalled_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder LocalProc";
    begin
        ResetEntries(false);
        Prime(77);
        H.Post(1);
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('entries', Entries());
        Observer.Finish();
    end;

    [Test]
    procedure LocalProc_WrittenBefore_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder LocalProc";
    begin
        ResetEntries(false);
        Prime(78);
        H.WriteRegister(5);
        H.Post(1);
        Observer.Observe('holder', H.State());
        Observer.Observe('a', H.StateA());
        Observer.Observe('b', H.StateB());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('owner', H.OwnerState());
        Observer.Finish();
    end;

    [Test]
    procedure LocalProc_NeverCalled_OwnerRunsInOnRun_ThenHolderRuns()
    var
        H: Codeunit "CNC Holder LocalProc";
    begin
        ResetEntries(true);
        Prime(79);
        H.Post(2);
        Observer.Observe('first.holder', H.State());
        Observer.Observe('first.entries', Entries());
        H.RunReg();
        Observer.Observe('second.holder', H.State());
        Observer.Observe('second.owner', H.OwnerState());
        Observer.Observe('second.entries', Entries());
        Observer.Finish();
    end;

    // Holder holds the owner in a local variable (owner view read right after Run, inside that procedure)

    [Test]
    procedure LocalOwner_NeverCalled_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder LocalOwner";
    begin
        ResetEntries(false);
        Prime(81);
        H.Post(1);
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('entries', Entries());
        Observer.Finish();
    end;

    [Test]
    procedure LocalOwner_WrittenBefore_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder LocalOwner";
    begin
        ResetEntries(false);
        Prime(82);
        H.WriteRegister(5);
        H.Post(1);
        Observer.Observe('holder', H.State());
        Observer.Observe('a', H.StateA());
        Observer.Observe('b', H.StateB());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('owner', H.OwnerState());
        Observer.Finish();
    end;

    [Test]
    procedure LocalOwner_NeverCalled_OwnerRunsInOnRun_ThenHolderRuns()
    var
        H: Codeunit "CNC Holder LocalOwner";
    begin
        ResetEntries(true);
        Prime(83);
        H.Post(2);
        Observer.Observe('first.holder', H.State());
        Observer.Observe('first.owner', H.OwnerState());
        Observer.Observe('first.entries', Entries());
        H.RunReg();
        Observer.Observe('second.holder', H.State());
        Observer.Observe('second.entries', Entries());
        Observer.Finish();
    end;

    // Owner's RunWithCheck is internal

    [Test]
    procedure Internal_NeverCalled_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder Internal";
    begin
        ResetEntries(false);
        Prime(84);
        H.Post(1);
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('entries', Entries());
        Observer.Finish();
    end;

    [Test]
    procedure Internal_WrittenBefore_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder Internal";
    begin
        ResetEntries(false);
        Prime(85);
        H.WriteRegister(5);
        H.Post(1);
        Observer.Observe('holder', H.State());
        Observer.Observe('a', H.StateA());
        Observer.Observe('b', H.StateB());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('owner', H.OwnerState());
        Observer.Finish();
    end;

    [Test]
    procedure Internal_NeverCalled_OwnerRunsInOnRun_ThenHolderRuns()
    var
        H: Codeunit "CNC Holder Internal";
    begin
        ResetEntries(true);
        Prime(86);
        H.Post(2);
        Observer.Observe('first.holder', H.State());
        Observer.Observe('first.entries', Entries());
        H.RunReg();
        Observer.Observe('second.holder', H.State());
        Observer.Observe('second.owner', H.OwnerState());
        Observer.Observe('second.entries', Entries());
        Observer.Finish();
    end;

    // All four facts: the "Whse.-Activity-Post" -> "Sales-Post" shape

    [Test]
    procedure Activity_NeverCalled_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder Activity";
        Row: Record "CKK Row" temporary;
    begin
        ResetEntries(false);
        Prime(87);
        H.SetMode(1, false);
        Header(Row);
        H.Run(Row);
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('entries', Entries());
        Observer.Finish();
    end;

    [Test]
    procedure Activity_WrittenBefore_OwnerWritesInOnRun()
    var
        H: Codeunit "CNC Holder Activity";
        Row: Record "CKK Row" temporary;
    begin
        ResetEntries(false);
        Prime(88);
        H.WriteRegister(5);
        H.SetMode(1, false);
        Header(Row);
        H.Run(Row);
        Observer.Observe('holder', H.State());
        Observer.Observe('a', H.StateA());
        Observer.Observe('b', H.StateB());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('owner', H.OwnerState());
        Observer.Finish();
    end;

    [Test]
    procedure Activity_NeverCalled_OwnerRunsInOnRun_ThenHolderRuns()
    var
        H: Codeunit "CNC Holder Activity";
        Row: Record "CKK Row" temporary;
    begin
        ResetEntries(true);
        Prime(89);
        H.SetMode(2, false);
        Header(Row);
        H.Run(Row);
        Observer.Observe('first.holder', H.State());
        Observer.Observe('first.owner', H.OwnerState());
        Observer.Observe('first.entries', Entries());
        H.RunReg();
        Observer.Observe('second.holder', H.State());
        Observer.Observe('second.entries', Entries());
        Observer.Finish();
    end;

    [Test]
    procedure Activity_NeverCalled_OwnerRunsInOnRun_HolderRunsInOnRun()
    var
        H: Codeunit "CNC Holder Activity";
        Row: Record "CKK Row" temporary;
    begin
        ResetEntries(true);
        Prime(90);
        H.SetMode(2, true);
        Header(Row);
        H.Run(Row);
        Observer.Observe('owner', H.OwnerState());
        Observer.Observe('inside', H.InsideState());
        Observer.Observe('holder', H.State());
        Observer.Observe('si', H.StateSI());
        Observer.Observe('entries', Entries());
        Observer.Finish();
    end;
}
