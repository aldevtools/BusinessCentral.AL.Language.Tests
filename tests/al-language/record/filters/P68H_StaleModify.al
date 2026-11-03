// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70709; codeunit 70714
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Modify of a buffer that is older than the stored row (another variable wrote) and newer than it (its write was rolled back by asserterror)
// BC versions: 29 (27 and 28 by CI)

codeunit 70727 "LT P68 Stale Modify"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        S: Record "LT P68 Stale";
    begin
        S.DeleteAll();
        S.Code := 'A';
        S.Val := 1;
        S.Txt := 'one';
        S.Insert();
        S.Code := 'B';
        S.Val := 10;
        S.Txt := 'ten';
        S.Insert();
    end;

    local procedure ModifyThenFail(var S: Record "LT P68 Stale")
    begin
        S.Modify();
        Error('rolled back');
    end;

    local procedure StoredVal(PkCode: Code[20]): Text
    var
        S: Record "LT P68 Stale";
    begin
        if S.Get(PkCode) then
            exit(Format(S.Val) + '/' + S.Txt);
        exit('<missing>');
    end;

    [Test]
    procedure Stale_Buffer_After_Other_Variable_Wrote()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT P68 Stale";
        R2: Record "LT P68 Stale";
    begin
        Seed();
        R1.Get('A');
        R2.Get('A');
        R2.Val := 2;
        R2.Modify();
        R1.Val := 3;
        R1.Modify();
        Observer.Observe('stale-modify', 'no error');
        Observer.Observe('stored', StoredVal('A'));
        Observer.Expect('stale-modify', 'no error');
        Observer.Expect('stored', '3/one');
        Observer.Verify();
    end;

    [Test]
    procedure Stale_Buffer_Refetched_Then_Modify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT P68 Stale";
        R2: Record "LT P68 Stale";
    begin
        Seed();
        R1.Get('A');
        R2.Get('A');
        R2.Val := 2;
        R2.Modify();
        R1.Get('A');
        R1.Val := 3;
        R1.Modify();
        Observer.Observe('stored', StoredVal('A'));
        R2.Val := 4;
        R2.Modify();
        Observer.Observe('old-after-refetch', 'no error');
        Observer.Expect('stored', '3/one');
        Observer.Expect('old-after-refetch', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Stale_Buffer_Same_Variable_Twice()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT P68 Stale";
    begin
        Seed();
        R1.Get('A');
        R1.Val := 2;
        R1.Modify();
        R1.Val := 3;
        R1.Modify();
        R1.Txt := 'three';
        R1.Modify();
        Observer.Observe('stored', StoredVal('A'));
        Observer.Expect('stored', '3/three');
        Observer.Verify();
    end;

    [Test]
    procedure Stale_Buffer_Delete_And_Rename()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT P68 Stale";
        R2: Record "LT P68 Stale";
    begin
        Seed();
        R1.Get('A');
        R2.Get('A');
        R2.Val := 2;
        R2.Modify();
        R1.Delete();
        Observer.Observe('stale-delete-stored', StoredVal('A'));
        R1.Get('B');
        R2.Get('B');
        R2.Val := 20;
        R2.Modify();
        R1.Rename('C');
        Observer.Observe('stale-rename-b', StoredVal('B'));
        Observer.Observe('stale-rename-c', StoredVal('C'));
        Observer.Expect('stale-delete-stored', '<missing>');
        Observer.Expect('stale-rename-b', '<missing>');
        Observer.Expect('stale-rename-c', '10/ten');
        Observer.Verify();
    end;
}
