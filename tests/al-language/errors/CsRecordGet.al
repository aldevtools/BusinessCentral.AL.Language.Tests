// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: Probe Observer, ALTPermissionSet (grants "ALT Universal" only), "ALT No Subscriber Table" (60590), "Permissions Mock" (System Application Test Library)
// Probe: corpus issue 670 item 15: with "if Rec.Get(...)" (result used), does a missing read permission still raise an error?
//   Every literal asserted below is what BC produced; the CI matrix checks BC 27.5, 28.5 and 29.0.
// BC versions: 27, 28, 29

codeunit 85181 "LT CS Record Get"
{
    Subtype = Test;

    [TryFunction]
    local procedure TryPlainGet(var Row: Record "ALT No Subscriber Table"; EntryNo: Integer)
    begin
        Row.Get(EntryNo);
    end;

    [TryFunction]
    local procedure TryFindFirst(var Row: Record "ALT No Subscriber Table")
    begin
        Row.Reset();
        Row.FindFirst();
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('error: ' + GetLastErrorText() + ' code: ' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryGetUsed(var Row: Record "ALT No Subscriber Table"; EntryNo: Integer; var Found: Boolean)
    begin
        Found := Row.Get(EntryNo);
    end;

    [TryFunction]
    local procedure TryIfGet(var Row: Record "ALT No Subscriber Table"; EntryNo: Integer; var Found: Boolean)
    begin
        Found := false;
        if Row.Get(EntryNo) then
            Found := true;
    end;

    local procedure Used(Ok: Boolean; Found: Boolean): Text
    begin
        if Ok then
            exit('result ' + Format(Found));
        exit('error: ' + GetLastErrorText() + ' code: ' + GetLastErrorCode());
    end;

    [Test]
    procedure RecordGet_ResultUsed_NoReadPermission()
    var
        Observer: Codeunit "Probe Observer";
        PermissionsMock: Codeunit "Permissions Mock";
        Row: Record "ALT No Subscriber Table";
        WasStarted: Boolean;
        Found: Boolean;
    begin
        WasStarted := PermissionsMock.IsStarted();
        if not WasStarted then
            PermissionsMock.Start();
        PermissionsMock.ClearAssignments();
        if Row.Get(851810) then
            Row.Delete();
        Row.Init();
        Row."Entry No." := 851810;
        Row.Value := 1;
        Row.Insert();
        PermissionsMock.Set('ALTPermissionSet');
        ClearLastError();
        Observer.Observe('existing row, result assigned', Used(TryGetUsed(Row, 851810, Found), Found));
        Observer.Observe('missing row, result assigned', Used(TryGetUsed(Row, 851811, Found), Found));
        Observer.Observe('existing row, if Get', Used(TryIfGet(Row, 851810, Found), Found));
        Observer.Observe('plain get', Outcome(TryPlainGet(Row, 851810)));
        Observer.Observe('findfirst', Outcome(TryFindFirst(Row)));
        PermissionsMock.ClearAssignments();
        if not WasStarted then
            PermissionsMock.Stop();
        Observer.Observe('after restore', Format(Row.Get(851810)));
        Row.Delete();
        Observer.Expect('existing row, result assigned', 'error: Sorry, the current permissions prevented the action. (TableData 60590 ALT No Subscriber Table Read: AL Language Coverage Tests) code: DB:ClientReadDenied');
        Observer.Expect('missing row, result assigned', 'result No');
        Observer.Expect('existing row, if Get', 'error: Sorry, the current permissions prevented the action. (TableData 60590 ALT No Subscriber Table Read: AL Language Coverage Tests) code: DB:ClientReadDenied');
        Observer.Expect('plain get', 'error: Sorry, the current permissions prevented the action. (TableData 60590 ALT No Subscriber Table Read: AL Language Coverage Tests) code: DB:ClientReadDenied');
        Observer.Expect('findfirst', 'error: Sorry, the current permissions prevented the action. (TableData 60590 ALT No Subscriber Table Read: AL Language Coverage Tests) code: DB:ClientReadDenied');
        Observer.Expect('after restore', 'Yes');
        Observer.Verify();
    end;
}
