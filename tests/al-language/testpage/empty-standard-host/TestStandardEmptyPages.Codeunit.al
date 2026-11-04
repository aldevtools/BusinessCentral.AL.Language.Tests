// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-openview-method
// Uses the two public Microsoft pages seen in the original refusal, without copying their implementation.
// Run only in a disposable company with no allocation accounts or bank reconciliation headers.
// No Microsoft records are deleted or inserted by these tests.
codeunit 69027 "TPG Standard Empty Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        FixtureCleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure AllocationAccount_OpenView_ExposesCaption()
    var
        View: TestPage "Allocation Account";
    begin
        Initialize();
        View.OpenView();
        if StrPos(View.Caption(), 'Allocation Account') = 0 then
            Error('Expected a non-empty caption after opening Allocation Account.');
        View.Close();
    end;

    [Test]
    procedure BankReconciliation_OpenView_ExposesCaption()
    var
        View: TestPage "Bank Acc. Reconciliation";
    begin
        Initialize();
        View.OpenView();
        if StrPos(View.Caption(), 'Bank Acc. Reconciliation') = 0 then
            Error('Expected a non-empty caption after opening Bank Acc. Reconciliation.');
        View.Close();
    end;

    local procedure Initialize()
    var
        Allocation: Record "Allocation Account";
        Reconciliation: Record "Bank Acc. Reconciliation";
    begin
        FixtureCleanup.Initialize();
        Allocation.DeleteAll(false);
        Reconciliation.DeleteAll(false);
    end;
}
