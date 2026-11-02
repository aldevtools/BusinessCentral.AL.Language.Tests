// TEMPORARY debug (writer Y69), removed before the PR.
codeunit 93739 "LT Y69 Debug"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y69_Debug_Ops()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y69 Helper";
        i: Integer;
        Kind: Integer;
    begin
        asserterror Helper.SeedMoved();
        Observer.ObserveError('seed');
        for i := 1 to Helper.MovedTableCount() do
            for Kind := 1 to 4 do
                Observer.Observe(Format(Helper.MovedTableId(i)) + '|' + Format(Kind), Helper.ErrorOf(Kind, Helper.MovedTableId(i)));
        Observer.Finish();
    end;
}
