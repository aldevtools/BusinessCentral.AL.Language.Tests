// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CKK Row" (table 86270) of ClearSharedCodeunitGlobalKinds.al; self-contained objects 86890 to 86900
// Probe: ClearAll in a TableNo owner codeunit ("Sales-Post" shape) that a plain holder codeunit ("Whse.-Activity-Post" shape)
// gave its register codeunit through a setter `SetReg(var R)` before `Owner.Run(Header)`, when NO routine of the register ran
// before the ClearAll. The owner calls ClearAll in a local procedure called from a procedure called from OnRun. The register tree
// has the global kinds of "Whse. Jnl.-Register Line" in BC 29: register (TableNo) with 4 non-temporary records, codeunits A and B,
// Integer, Labels and Boolean; A ("Item Tracking Management" shape) with 3 temporary and 2 non-temporary records, SingleInstance
// C and U, Integer, Date, 4 Booleans and Labels; B ("WMS Management" shape) with 5 non-temporary records, 1 temporary record, A,
// plain W (Labels only), U, 2 Booleans, Integer and Labels; U (SingleInstance) with 2 non-temporary records and Labels; C
// (SingleInstance) holding SingleInstance I (one Boolean). U and I are primed through other variables at the start of every test.
// Observed after the ClearAll: every global, whether the instance is still shared by holder and owner (writes both ways, also from
// inside OnRun), and registers run afterwards by the holder (once, twice) and by the owner (in and after OnRun), with a register
// entry row numbered on the first run and modified on later runs. Neighbor cells where the register was written or run before the
// ClearAll separate "reset" from "never set". al-runner issue 8964.
// singleinstance-shared-on-purpose: the subject is SingleInstance codeunits held below a register that ClearAll resets.
// BC versions: 27, 28, 29
// What BC did: see the Expect lines of each test.
table 86890 "CNC Reg Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Runs; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 86891 "CNC I"
{
    SingleInstance = true;

    var
        Flag: Boolean;

    procedure SetFlag(V: Boolean)
    begin
        Flag := V;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('i[%1]', Flag));
    end;
}

codeunit 86892 "CNC C"
{
    SingleInstance = true;

    var
        Impl: Codeunit "CNC I";

    procedure State(): Text
    begin
        exit('c' + Impl.State());
    end;
}

codeunit 86893 "CNC U"
{
    SingleInstance = true;

    var
        Uom: Record "CKK Row";
        Item: Record "CKK Row";
        ULbl: Label 'u label', Comment = 'a comment';
        UPlain: Label 'u plain';

    procedure Set(V: Integer)
    begin
        Uom."No." := V;
        Uom.SetRange("No.", V);
        Item.Txt := 'u' + Format(V);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('u[%1,%2,%3,%4,%5]', Uom."No.", Uom.GetFilters(), Item.Txt, ULbl, UPlain));
    end;
}

codeunit 86894 "CNC W"
{
    var
        WLbl: Label 'w label', Comment = 'a comment';
        WPlain: Label 'w plain';

    procedure State(): Text
    begin
        exit(StrSubstNo('w[%1,%2]', WLbl, WPlain));
    end;
}

codeunit 86895 "CNC A"
{
    var
        TempA1: Record "CKK Row" temporary;
        TempA2: Record "CKK Row" temporary;
        TempA3: Record "CKK Row" temporary;
        N1: Record "CKK Row";
        N2: Record "CKK Row";
        Confirm: Codeunit "CNC C";
        UomMgt: Codeunit "CNC U";
        Cnt: Integer;
        DueDate: Date;
        B1: Boolean;
        B2: Boolean;
        B3: Boolean;
        B4: Boolean;
        ALbl: Label 'a label', Comment = 'a comment';
        APlain: Label 'a plain';

    procedure SetAll(V: Integer)
    begin
        TempA1."No." := V;
        TempA1.Insert();
        TempA2."No." := V;
        TempA2.SetRange("No.", V);
        TempA3.Txt := 't' + Format(V);
        N1."No." := V;
        N1.SetRange("No.", V);
        N2.Txt := 'n' + Format(V);
        Cnt := V;
        DueDate := DMY2Date(1, 1, 2020) + V;
        B1 := true;
        B2 := true;
        B3 := true;
        B4 := true;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('a[%1,%2,%3,%4,%5,%6,', TempA1.Count(), TempA2."No.", TempA2.GetFilters(), TempA3.Txt, N1."No.", N1.GetFilters())
            + StrSubstNo('%1,%2,%3,%4%5%6%7,%8,%9]', N2.Txt, Cnt, Format(DueDate, 0, 9), Format(B1, 0, 9), Format(B2, 0, 9), Format(B3, 0, 9), Format(B4, 0, 9), ALbl, APlain));
    end;

    procedure StateSI(): Text
    begin
        exit(Confirm.State() + UomMgt.State());
    end;
}

codeunit 86896 "CNC B"
{
    var
        R1: Record "CKK Row";
        R2: Record "CKK Row";
        R3: Record "CKK Row";
        R4: Record "CKK Row";
        R5: Record "CKK Row";
        TempB: Record "CKK Row" temporary;
        ItemTracking: Codeunit "CNC A";
        WhseMgt: Codeunit "CNC W";
        UomMgt: Codeunit "CNC U";
        B1: Boolean;
        B2: Boolean;
        Cnt: Integer;
        BLbl: Label 'b label', Comment = 'a comment';
        BPlain: Label 'b plain';

    procedure SetAll(V: Integer)
    begin
        R1."No." := V;
        R2.SetRange("No.", V);
        R3.Txt := 'r' + Format(V);
        R4."No." := V + 1;
        R5.SetRange(Txt, 'x');
        TempB."No." := V;
        TempB.Insert();
        ItemTracking.SetAll(V + 1);
        B1 := true;
        B2 := true;
        Cnt := V;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('b[%1,%2,%3,%4,%5,%6,', R1."No.", R2.GetFilters(), R3.Txt, R4."No.", R5.GetFilters(), TempB.Count())
            + StrSubstNo('%1%2,%3,%4,%5]', Format(B1, 0, 9), Format(B2, 0, 9), Cnt, BLbl, BPlain) + WhseMgt.State());
    end;

    procedure StateA(): Text
    begin
        exit(ItemTracking.State());
    end;

    procedure StateSI(): Text
    begin
        exit(UomMgt.State() + ItemTracking.StateSI());
    end;
}

codeunit 86897 "CNC Reg"
{
    TableNo = "CKK Row";

    var
        WhseReg: Record "CNC Reg Entry";
        R2: Record "CKK Row";
        R3: Record "CKK Row";
        R4: Record "CKK Row";
        ItemTracking: Codeunit "CNC A";
        WmsMgt: Codeunit "CNC B";
        Cnt: Integer;
        RLbl: Label 'reg label', Comment = 'a comment';
        RPlain: Label 'reg plain';
        Flag: Boolean;

    trigger OnRun()
    begin
        Cnt += 1;
        if WhseReg."No." = 0 then begin
            WhseReg.Reset();
            if WhseReg.FindLast() then
                WhseReg."No." := WhseReg."No." + 1
            else
                WhseReg."No." := 1;
            WhseReg.Runs := 1;
            WhseReg.Insert();
        end else begin
            WhseReg.Runs += 1;
            WhseReg.Modify();
        end;
        R2."No." := Rec."No.";
        Flag := true;
    end;

    procedure SetAll(V: Integer)
    begin
        R2."No." := V;
        R3.SetRange("No.", V);
        R4.Txt := 'q' + Format(V);
        ItemTracking.SetAll(V);
        WmsMgt.SetAll(V + 10);
        Cnt := V;
        Flag := true;
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('reg[%1,%2,%3,%4,%5,%6,%7,%8,%9]', WhseReg."No.", WhseReg.Runs, R2."No.", R3.GetFilters(), R4.Txt, Cnt, RLbl, RPlain, Format(Flag, 0, 9)));
    end;

    procedure StateA(): Text
    begin
        exit(ItemTracking.State());
    end;

    procedure StateB(): Text
    begin
        exit(WmsMgt.State() + WmsMgt.StateA());
    end;

    procedure StateSI(): Text
    begin
        exit(ItemTracking.StateSI() + '|' + WmsMgt.StateSI());
    end;
}

codeunit 86898 "CNC Owner"
{
    TableNo = "CKK Row";

    var
        WhseJnlPostLine: Codeunit "CNC Reg";
        Mode: Integer;

    trigger OnRun()
    var
        M: Integer;
    begin
        M := Mode;
        RunWithCheck(M);
    end;

    local procedure RunWithCheck(M: Integer)
    begin
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

    procedure SetCnt(V: Integer)
    begin
        WhseJnlPostLine.SetCnt(V);
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

codeunit 86899 "CNC Holder"
{
    var
        WhseJnlRegisterLine: Codeunit "CNC Reg";
        SalesPost: Codeunit "CNC Owner";

    procedure WriteRegister(V: Integer)
    begin
        WhseJnlRegisterLine.SetAll(V);
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

    procedure RunReg()
    var
        TempRow: Record "CKK Row" temporary;
    begin
        TempRow."No." := 7;
        TempRow.Insert();
        WhseJnlRegisterLine.Run(TempRow);
    end;

    procedure SetCnt(V: Integer)
    begin
        WhseJnlRegisterLine.SetCnt(V);
    end;

    procedure OwnerSetCnt(V: Integer)
    begin
        SalesPost.SetCnt(V);
    end;

    procedure OwnerRunReg()
    begin
        SalesPost.RunReg();
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

codeunit 86900 "CNC Test"
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

    local procedure ObserveTree(Prefix: Text; var H: Codeunit "CNC Holder")
    begin
        Observer.Observe(Prefix + '.reg', H.State());
        Observer.Observe(Prefix + '.a', H.StateA());
        Observer.Observe(Prefix + '.b', H.StateB());
        Observer.Observe(Prefix + '.si', H.StateSI());
    end;

    [Test]
    procedure NeverCalled_OwnerClearAll_EveryGlobal()
    var
        H: Codeunit "CNC Holder";
        UomMgt: Codeunit "CNC U";
    begin
        ResetEntries(false);
        Prime(31);
        H.Post(0);
        ObserveTree('after', H);
        Observer.Observe('after.owner', H.OwnerState());
        UomMgt.Set(32);
        Observer.Observe('siwrite.si', H.StateSI());
        Observer.Observe('entries', Entries());
        Observer.Finish();
    end;

    [Test]
    procedure WrittenBefore_OwnerClearAll_EveryGlobal()
    var
        H: Codeunit "CNC Holder";
    begin
        ResetEntries(false);
        Prime(41);
        H.WriteRegister(5);
        ObserveTree('before', H);
        H.Post(0);
        ObserveTree('after', H);
        Observer.Observe('after.owner', H.OwnerState());
        Observer.Finish();
    end;

    [Test]
    procedure NeverCalled_OwnerWritesAfter_HolderReads()
    var
        H: Codeunit "CNC Holder";
    begin
        ResetEntries(false);
        Prime(51);
        H.Post(0);
        H.OwnerSetCnt(11);
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Finish();
    end;

    [Test]
    procedure NeverCalled_HolderWritesAfter_OwnerReads()
    var
        H: Codeunit "CNC Holder";
    begin
        ResetEntries(false);
        Prime(52);
        H.Post(0);
        H.SetCnt(12);
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Finish();
    end;

    [Test]
    procedure NeverCalled_OwnerWritesInOnRun_HolderReads()
    var
        H: Codeunit "CNC Holder";
    begin
        ResetEntries(false);
        Prime(53);
        H.Post(1);
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Finish();
    end;

    [Test]
    procedure NeverCalled_HolderRunsOnce_EntryAndCounter()
    var
        H: Codeunit "CNC Holder";
    begin
        ResetEntries(true);
        Prime(61);
        H.Post(0);
        H.RunReg();
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Observe('entries', Entries());
        Observer.Observe('si', H.StateSI());
        Observer.Finish();
    end;

    [Test]
    procedure NeverCalled_HolderRunsTwice_EntryAndCounter()
    var
        H: Codeunit "CNC Holder";
    begin
        ResetEntries(true);
        Prime(62);
        H.Post(0);
        H.RunReg();
        H.RunReg();
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Observe('entries', Entries());
        Observer.Finish();
    end;

    [Test]
    procedure NeverCalled_HolderRunsThenOwnerRuns_EntryAndCounter()
    var
        H: Codeunit "CNC Holder";
    begin
        ResetEntries(true);
        Prime(63);
        H.Post(0);
        H.RunReg();
        H.OwnerRunReg();
        Observer.Observe('holder', H.State());
        Observer.Observe('owner', H.OwnerState());
        Observer.Observe('entries', Entries());
        Observer.Finish();
    end;

    [Test]
    procedure NeverCalled_OwnerRunsInOnRun_ThenHolderRuns()
    var
        H: Codeunit "CNC Holder";
    begin
        ResetEntries(true);
        Prime(64);
        H.Post(2);
        Observer.Observe('first.holder', H.State());
        Observer.Observe('first.entries', Entries());
        H.RunReg();
        Observer.Observe('second.holder', H.State());
        Observer.Observe('second.owner', H.OwnerState());
        Observer.Observe('second.entries', Entries());
        Observer.Finish();
    end;

    [Test]
    procedure RunBefore_OwnerClearAll_HolderRunsAgain()
    var
        H: Codeunit "CNC Holder";
    begin
        ResetEntries(true);
        Prime(65);
        H.RunReg();
        Observer.Observe('before.holder', H.State());
        Observer.Observe('before.entries', Entries());
        H.Post(0);
        Observer.Observe('after.holder', H.State());
        Observer.Observe('after.owner', H.OwnerState());
        H.RunReg();
        Observer.Observe('again.holder', H.State());
        Observer.Observe('again.owner', H.OwnerState());
        Observer.Observe('again.entries', Entries());
        Observer.Finish();
    end;
}
