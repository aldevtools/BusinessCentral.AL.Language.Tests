// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; SingleInstance log 72236 is used only by test codeunit 72238
// Facts: Report.Run / RunModal (static with Integer id, instance) with the request page: OK and Cancel, RequestWindow false, record filter, UseRequestPage on an instance; each declared handler is started by the Run in the same test

codeunit 72236 "LT P105 RunLog"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 72237 "LT P105 RunRep"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT P105 Row")
        {
            RequestFilterFields = Id;

            trigger OnPreDataItem()
            begin
                L.Add('rows filter=[' + Row.GetFilter(Id) + '] count=' + Format(Row.Count()));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(IntCtl; IntVal)
                {
                    ApplicationArea = All;
                    Caption = 'Integer Control';
                }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('open int=' + Format(IntVal));
        end;
    }

    trigger OnPreReport()
    begin
        L.Add('pre int=' + Format(IntVal));
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;

    var
        IntVal: Integer;
        L: Codeunit "LT P105 RunLog";
}

codeunit 72238 "LT P105 Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P105 RunLog";
        Helper: Codeunit "LT P105 Helper";

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure P105_RunStatic_RequestPageOk()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P105 RunRep");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'open int=0;pre int=0;rows filter=[] count=4;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure P105_RunStatic_RequestPageCancel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P105 RunRep");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'open int=0;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure P105_RunModalStatic_RequestWindowTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.RunModal(Report::"LT P105 RunRep", true, false);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'open int=0;pre int=0;rows filter=[] count=4;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure P105_RunModalStatic_Cancel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.RunModal(Report::"LT P105 RunRep", true, false);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'open int=0;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure P105_RunStatic_WithRecordFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P105 Row";
    begin
        Helper.Seed();
        Row.SetFilter(Id, '2..3');
        L.Take();
        Report.Run(Report::"LT P105 RunRep", true, false, Row);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'open int=0;pre int=0;rows filter=[2..3] count=2;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure P105_RunModalStatic_WithRecordFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P105 Row";
    begin
        Helper.Seed();
        Row.SetRange(Grp, 2);
        L.Take();
        Report.RunModal(Report::"LT P105 RunRep", true, false, Row);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'open int=0;pre int=0;rows filter=[] count=2;post;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_RunStatic_RequestWindowFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P105 RunRep", false, false);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre int=0;rows filter=[] count=4;post;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_RunModalStatic_RequestWindowFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.RunModal(Report::"LT P105 RunRep", false, false);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre int=0;rows filter=[] count=4;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure P105_RunInstance_UseRequestPageTrue()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P105 RunRep";
    begin
        Helper.Seed();
        Observer.Observe('default use', Format(Rpt.UseRequestPage()));
        Rpt.UseRequestPage(true);
        L.Take();
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('default use', 'Yes');
        Observer.Expect('log', 'open int=0;pre int=0;rows filter=[] count=4;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure P105_RunModalInstance_Cancel()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P105 RunRep";
    begin
        Helper.Seed();
        L.Take();
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'open int=0;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_RunInstance_UseRequestPageFalse()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P105 RunRep";
    begin
        Helper.Seed();
        Rpt.UseRequestPage(false);
        Observer.Observe('use after set', Format(Rpt.UseRequestPage()));
        L.Take();
        Rpt.Run();
        Observer.Observe('log run', L.Take());
        asserterror Rpt.RunModal();
        Observer.Observe('log runmodal', L.Take());
        Observer.Expect('use after set', 'No');
        Observer.Expect('log run', 'pre int=0;rows filter=[] count=4;post;');
        Observer.Expect('log runmodal', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetHandler')]
    procedure P105_RunStatic_ValueSetInHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P105 RunRep");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'open int=0;pre int=42;rows filter=[] count=4;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetHandler')]
    procedure P105_RunModalStatic_ValueSetInHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.RunModal(Report::"LT P105 RunRep");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'open int=0;pre int=42;rows filter=[] count=4;post;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OkHandler(var RP: TestRequestPage "LT P105 RunRep")
    begin
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancelHandler(var RP: TestRequestPage "LT P105 RunRep")
    begin
        RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure SetHandler(var RP: TestRequestPage "LT P105 RunRep")
    begin
        RP.IntCtl.SetValue(42);
        RP.OK().Invoke();
    end;
}
