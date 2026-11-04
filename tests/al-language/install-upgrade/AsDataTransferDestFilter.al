// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/methods-auto/datatransfer/datatransfer-adddestinationfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsFixtures.al (tables 79900, 79901, helper 79913)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 644, item 15).
// Facts: DataTransfer.AddDestinationFilter from a test (outside upgrade and install code): SetTables is accepted there, AddDestinationFilter, CopyFields
//   and CopyRows raise (error texts, and no destination row changes); an unknown field number after SetTables, and an unknown and a zero field number without tables.
// BC versions: 28-29 (AddDestinationFilter needs runtime 17; the runtime 16 refusal is must-not-compile case 0365)

#if BC28PLUS
codeunit 79931 "LT AS DataTransfer DestFilter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT AS Helper";

    local procedure Seed()
    var
        I: Record "LT AS Int Key";
        B: Record "LT AS Big Key";
    begin
        I.DeleteAll();
        B.DeleteAll();
        I.Id := 1;
        I.Name := 'src1';
        I.Insert();
        I.Id := 2;
        I.Name := 'src2';
        I.Insert();
        B.Id := 1;
        B.Name := 'dst1';
        B.Insert();
        B.Id := 2;
        B.Name := 'dst2';
        B.Insert();
    end;

    local procedure Targets(): Text
    var
        B: Record "LT AS Big Key";
        Result: Text;
    begin
        if B.FindSet() then
            repeat
                Result += Format(B.Id) + '=' + B.Name + ' ';
            until B.Next() = 0;
        exit(Result.TrimEnd());
    end;

    [TryFunction]
    local procedure TryAddFilter(var DT: DataTransfer; FieldNo: Integer)
    begin
        DT.AddDestinationFilter(FieldNo, '%1', 2);
    end;

    [TryFunction]
    local procedure TryCopyFields(var DT: DataTransfer)
    begin
        DT.CopyFields();
    end;

    [TryFunction]
    local procedure TryCopyRows(var DT: DataTransfer)
    begin
        DT.CopyRows();
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit(Helper.LastError());
    end;

    [TryFunction]
    local procedure TrySetTables(var DT: DataTransfer)
    begin
        DT.SetTables(Database::"LT AS Int Key", Database::"LT AS Big Key");
    end;

    // Outside upgrade and install code SetTables is accepted, AddDestinationFilter and the copies raise. Which destination rows a destination
    // filter keeps needs an upgrade or install context (not reachable from a test).
    [Test]
    procedure SetTables_ThenDestinationFilter_CopyFields_CopyRows()
    var
        Observer: Codeunit "Probe Observer";
        DT: DataTransfer;
    begin
        Seed();
        ClearLastError();
        Observer.Observe('settables', Outcome(TrySetTables(DT)));
        Observer.Observe('add_valid', Outcome(TryAddFilter(DT, 1)));
        Observer.Observe('copyfields', Outcome(TryCopyFields(DT)));
        Observer.Observe('copyrows', Outcome(TryCopyRows(DT)));
        Observer.Observe('targets', Targets());
        Observer.Expect('settables', 'ok');
        Observer.Expect('add_valid', 'DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('copyfields', 'DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('copyrows', 'DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '1=dst1 2=dst2');
        Observer.Verify();
    end;

    [Test]
    procedure UnknownFieldNo_WithoutTables()
    var
        Observer: Codeunit "Probe Observer";
        DT: DataTransfer;
    begin
        Seed();
        ClearLastError();
        Observer.Observe('add999', Outcome(TryAddFilter(DT, 999)));
        Observer.Observe('add_zero', Outcome(TryAddFilter(DT, 0)));
        Observer.Expect('add999', 'SetTables must first be called before calling other methods on DataTransfer.|DB:Ok');
        Observer.Expect('add_zero', 'SetTables must first be called before calling other methods on DataTransfer.|DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure UnknownFieldNo_AfterSetTables()
    var
        Observer: Codeunit "Probe Observer";
        DT: DataTransfer;
    begin
        Seed();
        ClearLastError();
        Observer.Observe('settables', Outcome(TrySetTables(DT)));
        Observer.Observe('add999', Outcome(TryAddFilter(DT, 999)));
        Observer.Expect('settables', 'ok');
        Observer.Expect('add999', 'DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure FilterBeforeSetTables()
    var
        Observer: Codeunit "Probe Observer";
        DT: DataTransfer;
    begin
        Seed();
        ClearLastError();
        Observer.Observe('add_no_tables', Outcome(TryAddFilter(DT, 1)));
        Observer.Expect('add_no_tables', 'SetTables must first be called before calling other methods on DataTransfer.|DB:Ok');
        Observer.Verify();
    end;
}
#endif
