// Helper for tests/al-language-testlibraries/lt-y3-setup-order/Y3SetupOrderTests.al (corpus writer Y3): the test app depends only on this app, so it
// reaches the XApp A log table 61139 and the XApp C table 61152 through this codeunit. See tests/al-language-xapp-a/Y3XaSetupOrder.al.

codeunit 90827 "LT Y3 Setup Order Helper"
{
    procedure InsertRowAndReadLog(): Text
    var
        L: Record "LT Y3 Order Log";
        R: Record "LT Y3 XC Order Row";
    begin
        L.DeleteAll();
        R.DeleteAll();
        R.Id := 1;
        R.Insert(true);
        exit('C: ' + Entry('C') + ' | A: ' + Entry('A'));
    end;

    local procedure Entry(Who: Text): Text
    var
        L: Record "LT Y3 Order Log";
    begin
        if not L.Get(Who) then
            exit('not called');
        exit(L.Detail);
    end;

    procedure InsertMainRowAndReadLog(): Text
    var
        L: Record "LT Y3 Order Log";
        R: Record "LT Y3 M Order Row";
    begin
        L.DeleteAll();
        R.DeleteAll();
        R.Id := 1;
        R.Insert(true);
        exit('M: ' + Entry('M') + ' | D: ' + Entry('D') + ' | Final: ' + Entry('Final'));
    end;
}
