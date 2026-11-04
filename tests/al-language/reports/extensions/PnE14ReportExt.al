// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72621, tables 72990-72991, report 72624, report extension 72625
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "NP Retail blockers - A reportextension that declares procedures and adds data items or global variables" (a public procedure
// next to an added data item and a variable, called through a base report variable before and after Run, and from a second variable)
// Facts: state a reportextension procedure sees through a base report variable: variable set by a trigger, added data item records, second instance
// BC versions: 29 (27 and 28 by CI)

table 72990 "LT PnE Rx Parent"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72991 "LT PnE Rx Child"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 72624 "LT PnE Rx Base"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;

    dataset
    {
        dataitem(Parent; "LT PnE Rx Parent")
        {
        }
    }

    var
        BaseRuns: Integer;

    trigger OnPreReport()
    begin
        BaseRuns += 1;
    end;

    procedure BaseState(): Text
    begin
        exit('baseRuns=' + Format(BaseRuns));
    end;
}

reportextension 72625 "LT PnE Rx Ext" extends "LT PnE Rx Base"
{
    dataset
    {
        addlast(Parent)
        {
            dataitem(Kid; "LT PnE Rx Child")
            {
                DataItemLink = ParentId = field(Id);

                trigger OnAfterGetRecord()
                begin
                    KidRows += 1;
                    LastKid := Kid.Id;
                end;
            }
        }
    }

    var
        V: Integer;
        KidRows: Integer;
        LastKid: Integer;

    trigger OnPreReport()
    begin
        V := 42;
    end;

    trigger OnPostReport()
    begin
        V += 1;
    end;

    procedure ExtState(): Text
    begin
        exit('V=' + Format(V) + ';kidRows=' + Format(KidRows) + ';lastKid=' + Format(LastKid) + ';kidCountNow=' + Format(Kid.Count()));
    end;
}

codeunit 72621 "LT PnE Report Ext Proc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        P: Record "LT PnE Rx Parent";
        C: Record "LT PnE Rx Child";
    begin
        P.DeleteAll();
        C.DeleteAll();
        P.Id := 1;
        P.Insert();
        P.Id := 2;
        P.Insert();
        C.Id := 10;
        C.ParentId := 1;
        C.Insert();
        C.Id := 11;
        C.ParentId := 1;
        C.Insert();
        C.Id := 12;
        C.ParentId := 2;
        C.Insert();
    end;

    local procedure Clean()
    var
        P: Record "LT PnE Rx Parent";
        C: Record "LT PnE Rx Child";
    begin
        P.DeleteAll();
        C.DeleteAll();
    end;

    [Test]
    procedure ExtensionProcedure_BeforeAndAfterRun()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT PnE Rx Base";
    begin
        Seed();
        Observer.Observe('base_before', Rep.BaseState());
        Observer.Observe('ext_before', Rep.ExtState());
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('base_after', Rep.BaseState());
        Observer.Observe('ext_after', Rep.ExtState());
        Clean();
        Observer.Expect('base_before', 'baseRuns=0');
        Observer.Expect('ext_before', 'V=0;kidRows=0;lastKid=0;kidCountNow=3');
        Observer.Expect('base_after', 'baseRuns=0');
        Observer.Expect('ext_after', 'V=0;kidRows=0;lastKid=0;kidCountNow=3');
        Observer.Verify();
    end;

    [Test]
    procedure ExtensionProcedure_SecondVariable()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT PnE Rx Base";
        Rep2: Report "LT PnE Rx Base";
    begin
        Seed();
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('first_after', Rep.ExtState());
        Observer.Observe('second_untouched', Rep2.ExtState());
        Observer.Observe('second_base', Rep2.BaseState());
        Rep2.UseRequestPage(false);
        Rep2.Run();
        Observer.Observe('second_after', Rep2.ExtState());
        Observer.Observe('first_still', Rep.ExtState());
        Rep.Run();
        Observer.Observe('first_twice', Rep.ExtState());
        Clean();
        Observer.Expect('first_after', 'V=0;kidRows=0;lastKid=0;kidCountNow=3');
        Observer.Expect('second_untouched', 'V=0;kidRows=0;lastKid=0;kidCountNow=3');
        Observer.Expect('second_base', 'baseRuns=0');
        Observer.Expect('second_after', 'V=0;kidRows=0;lastKid=0;kidCountNow=3');
        Observer.Expect('first_still', 'V=0;kidRows=0;lastKid=0;kidCountNow=3');
        Observer.Expect('first_twice', 'V=0;kidRows=0;lastKid=0;kidCountNow=3');
        Observer.Verify();
    end;

    [Test]
    procedure ExtensionProcedure_StaticRunDoesNotTouchVariable()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT PnE Rx Base";
    begin
        Seed();
        Report.Run(Report::"LT PnE Rx Base", false);
        Observer.Observe('variableAfterStaticRun', Rep.ExtState());
        Clean();
        Observer.Expect('variableAfterStaticRun', 'V=0;kidRows=0;lastKid=0;kidCountNow=3');
        Observer.Verify();
    end;
}
