// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: tables and helper of PnH1Fix.al; SingleInstance log 70620 is used only by test codeunit 70629
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Probes-needed rows: Report | Reportextension: OnPreReport/OnPostReport after the base's, modify(Item) triggers around the base trigger, an item added with
// addlast(Item) (not pinned: it runs after the parent's own nested items and after OnAfterAfterGetRecord; the extension's views before the base OnPreReport);
// a reportextension that declares a procedure and a global, the other modify triggers, Skip/Break/Quit inside them, a second reportextension of the same report.
// BC versions: 29 (27 and 28 by CI)

codeunit 70620 "LT PnH Ext Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Mode: Text;
        Counter: Integer;

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

    procedure SetMode(NewMode: Text)
    begin
        Mode := NewMode;
    end;

    procedure GetMode(): Text
    begin
        exit(Mode);
    end;

    procedure NextCounter(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;
}

report 70621 "LT PnH ExtBase"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            DataItemTableView = sorting(Id);

            dataitem(Child; "LT PnH Child")
            {
                DataItemLink = ParentId = field(Id);

                trigger OnPreDataItem()
                begin
                    L.Add('base child pre');
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('base child ' + Format(Child.Id));
                end;

                trigger OnPostDataItem()
                begin
                    L.Add('base child post');
                end;
            }

            trigger OnPreDataItem()
            begin
                L.Add('base row pre filters=[' + Row.GetFilters() + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('base row ' + Format(Row.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('base row post');
            end;
        }
    }

    trigger OnInitReport()
    begin
        L.Add('base init');
    end;

    trigger OnPreReport()
    begin
        L.Add('base pre filters=[' + Row.GetFilters() + ']');
    end;

    trigger OnPostReport()
    begin
        L.Add('base post');
    end;

    var
        L: Codeunit "LT PnH Ext Log";
}

reportextension 70622 "LT PnH ExtA" extends "LT PnH ExtBase"
{
    dataset
    {
        modify(Row)
        {
            trigger OnBeforePreDataItem()
            begin
                L.Add('ext before pre');
            end;

            trigger OnAfterPreDataItem()
            begin
                L.Add('ext after pre');
            end;

            trigger OnBeforeAfterGetRecord()
            begin
                L.Add('ext before get ' + Format(Row.Id));
                if Row.Id = 2 then
                    case L.GetMode() of
                        'SkipBefore':
                            CurrReport.Skip();
                        'BreakBefore':
                            CurrReport.Break();
                        'QuitBefore':
                            CurrReport.Quit();
                    end;
            end;

            trigger OnAfterAfterGetRecord()
            begin
                L.Add('ext after get ' + Format(Row.Id));
                if Row.Id = 2 then
                    case L.GetMode() of
                        'SkipAfter':
                            CurrReport.Skip();
                        'BreakAfter':
                            CurrReport.Break();
                        'QuitAfter':
                            CurrReport.Quit();
                    end;
            end;

            trigger OnBeforePostDataItem()
            begin
                L.Add('ext before post');
            end;

            trigger OnAfterPostDataItem()
            begin
                L.Add('ext after post');
            end;
        }

        addlast(Row)
        {
            dataitem(ExtChild; "LT PnH Child")
            {
                DataItemLink = ParentId = field(Id);

                trigger OnPreDataItem()
                begin
                    L.Add('ext child pre');
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('ext child ' + Format(ExtChild.Id));
                end;

                trigger OnPostDataItem()
                begin
                    L.Add('ext child post');
                end;
            }
        }
    }

    trigger OnPreReport()
    begin
        ExtGlobal += 1;
        L.Add('ext pre ' + Describe() + ' filters=[' + Row.GetFilters() + ']');
    end;

    trigger OnPostReport()
    begin
        L.Add('ext post ' + Describe());
    end;

    local procedure Describe(): Text
    begin
        exit('global=' + Format(ExtGlobal));
    end;

    var
        ExtGlobal: Integer;
        L: Codeunit "LT PnH Ext Log";
}

report 70631 "LT PnH ExtBase2"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            DataItemTableView = sorting(Id) where(Id = filter(1 .. 2));

            trigger OnAfterGetRecord()
            begin
                L.Add('base row ' + Format(Row.Id));
            end;
        }
    }

    trigger OnPreReport()
    begin
        L.Add('base pre');
    end;

    trigger OnPostReport()
    begin
        L.Add('base post');
    end;

    var
        L: Codeunit "LT PnH Ext Log";
}

reportextension 70632 "LT PnH ExtB" extends "LT PnH ExtBase2"
{
    dataset
    {
        modify(Row)
        {
            trigger OnBeforeAfterGetRecord()
            begin
                L.Add('B before ' + Format(Row.Id));
            end;

            trigger OnAfterAfterGetRecord()
            begin
                L.Add('B after ' + Format(Row.Id));
            end;
        }
        addlast(Row)
        {
            dataitem(BChild; "LT PnH Child")
            {
                DataItemLink = ParentId = field(Id);

                trigger OnAfterGetRecord()
                begin
                    L.Add('B child ' + Format(BChild.Id));
                end;
            }
        }
    }

    trigger OnPreReport()
    begin
        L.Add('B pre');
    end;

    trigger OnPostReport()
    begin
        L.Add('B post');
    end;

    var
        L: Codeunit "LT PnH Ext Log";
}

reportextension 70633 "LT PnH ExtC" extends "LT PnH ExtBase2"
{
    dataset
    {
        modify(Row)
        {
            trigger OnBeforeAfterGetRecord()
            begin
                L.Add('C before ' + Format(Row.Id));
            end;

            trigger OnAfterAfterGetRecord()
            begin
                L.Add('C after ' + Format(Row.Id));
            end;
        }
        addlast(Row)
        {
            dataitem(CChild; "LT PnH Child")
            {
                DataItemLink = ParentId = field(Id);

                trigger OnAfterGetRecord()
                begin
                    L.Add('C child ' + Format(CChild.Id));
                end;
            }
        }
    }

    trigger OnPreReport()
    begin
        L.Add('C pre');
    end;

    trigger OnPostReport()
    begin
        L.Add('C post');
    end;

    var
        L: Codeunit "LT PnH Ext Log";
}

codeunit 70629 "LT PnH Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT PnH Ext Log";
        Helper: Codeunit "LT PnH Helper";

    local procedure Start()
    begin
        Helper.Seed();
        L.Take();
        L.SetMode('');
    end;

    [Test]
    procedure One_Extension_FullOrder_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.Run(Report::"LT PnH ExtBase");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'base init;base pre filters=[];ext pre global=1 filters=[];ext before pre;base row pre filters=[];ext after pre;ext before get 1;base row 1;ext after get 1;base child pre;base child 10;base child 11;base child post;ext child pre;ext child 10;ext child 11;ext child post;ext before get 2;base row 2;ext after get 2;base child pre;base child 12;base child post;ext child pre;ext child 12;ext child post;ext before get 3;base row 3;ext after get 3;base child pre;base child 13;base child post;ext child pre;ext child 13;ext child post;ext before post;base row post;ext after post;base post;ext post global=1;');
        Observer.Verify();
    end;

    [Test]
    procedure One_Extension_FullOrder_Execute_And_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Start();
        Report.Execute(Report::"LT PnH ExtBase", '');
        Observer.Observe('execute', L.Take());
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saveas', Format(Report.SaveAs(Report::"LT PnH ExtBase", '', ReportFormat::Xml, OutS)));
        Observer.Observe('saveas log', L.Take());
        Observer.Expect('execute', 'base init;base pre filters=[];ext pre global=1 filters=[];ext before pre;base row pre filters=[];ext after pre;ext before get 1;base row 1;ext after get 1;base child pre;base child 10;base child 11;base child post;ext child pre;ext child 10;ext child 11;ext child post;ext before get 2;base row 2;ext after get 2;base child pre;base child 12;base child post;ext child pre;ext child 12;ext child post;ext before get 3;base row 3;ext after get 3;base child pre;base child 13;base child post;ext child pre;ext child 13;ext child post;ext before post;base row post;ext after post;base post;ext post global=1;');
        Observer.Expect('saveas', 'No');
        Observer.Expect('saveas log', 'base init;');
        Observer.Verify();
    end;

    [Test]
    procedure One_Extension_Variable_RunTwice_ExtensionGlobals()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH ExtBase";
    begin
        Start();
        Rpt.Run();
        Observer.Observe('first', L.Take());
        Rpt.Run();
        Observer.Observe('second', L.Take());
        Observer.Expect('first', 'base init;base pre filters=[];ext pre global=1 filters=[];ext before pre;base row pre filters=[];ext after pre;ext before get 1;base row 1;ext after get 1;base child pre;base child 10;base child 11;base child post;ext child pre;ext child 10;ext child 11;ext child post;ext before get 2;base row 2;ext after get 2;base child pre;base child 12;base child post;ext child pre;ext child 12;ext child post;ext before get 3;base row 3;ext after get 3;base child pre;base child 13;base child post;ext child pre;ext child 13;ext child post;ext before post;base row post;ext after post;base post;ext post global=1;');
        Observer.Expect('second', 'base init;base pre filters=[];ext pre global=1 filters=[];ext before pre;base row pre filters=[];ext after pre;ext before get 1;base row 1;ext after get 1;base child pre;base child 10;base child 11;base child post;ext child pre;ext child 10;ext child 11;ext child post;ext before get 2;base row 2;ext after get 2;base child pre;base child 12;base child post;ext child pre;ext child 12;ext child post;ext before get 3;base row 3;ext after get 3;base child pre;base child 13;base child post;ext child pre;ext child 13;ext child post;ext before post;base row post;ext after post;base post;ext post global=1;');
        Observer.Verify();
    end;

    [Test]
    procedure One_Extension_ViewsBeforeBasePreReport()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH ExtBase";
        Row: Record "LT PnH Row";
    begin
        Start();
        Row.SetRange(Grp, 1);
        Rpt.SetTableView(Row);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'base init;base pre filters=[Grp: 1];ext pre global=1 filters=[Grp: 1];ext before pre;base row pre filters=[Grp: 1];ext after pre;ext before get 1;base row 1;ext after get 1;base child pre;base child 10;base child 11;base child post;ext child pre;ext child 10;ext child 11;ext child post;ext before get 2;base row 2;ext after get 2;base child pre;base child 12;base child post;ext child pre;ext child 12;ext child post;ext before post;base row post;ext after post;base post;ext post global=1;');
        Observer.Verify();
    end;

    [Test]
    procedure One_Extension_SkipBreakQuit_InModifyTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Modes: List of [Text];
        Mode: Text;
    begin
        Start();
        Modes.Add('SkipBefore');
        Modes.Add('BreakBefore');
        Modes.Add('QuitBefore');
        Modes.Add('SkipAfter');
        Modes.Add('BreakAfter');
        Modes.Add('QuitAfter');
        foreach Mode in Modes do begin
            L.SetMode(Mode);
            Report.Run(Report::"LT PnH ExtBase");
            Observer.Observe(Mode, L.Take());
        end;
        L.SetMode('');
        Observer.Expect('SkipBefore', 'base init;base pre filters=[];ext pre global=1 filters=[];ext before pre;base row pre filters=[];ext after pre;ext before get 1;base row 1;ext after get 1;base child pre;base child 10;base child 11;base child post;ext child pre;ext child 10;ext child 11;ext child post;ext before get 2;base row 2;ext after get 2;ext before get 3;base row 3;ext after get 3;base child pre;base child 13;base child post;ext child pre;ext child 13;ext child post;ext before post;base row post;ext after post;base post;ext post global=1;');
        Observer.Expect('BreakBefore', 'base init;base pre filters=[];ext pre global=1 filters=[];ext before pre;base row pre filters=[];ext after pre;ext before get 1;base row 1;ext after get 1;base child pre;base child 10;base child 11;base child post;ext child pre;ext child 10;ext child 11;ext child post;ext before get 2;base row 2;ext after get 2;ext before post;base row post;ext after post;base post;ext post global=1;');
        Observer.Expect('QuitBefore', 'base init;base pre filters=[];ext pre global=1 filters=[];ext before pre;base row pre filters=[];ext after pre;ext before get 1;base row 1;ext after get 1;base child pre;base child 10;base child 11;base child post;ext child pre;ext child 10;ext child 11;ext child post;ext before get 2;');
        Observer.Expect('SkipAfter', 'base init;base pre filters=[];ext pre global=1 filters=[];ext before pre;base row pre filters=[];ext after pre;ext before get 1;base row 1;ext after get 1;base child pre;base child 10;base child 11;base child post;ext child pre;ext child 10;ext child 11;ext child post;ext before get 2;base row 2;ext after get 2;ext before get 3;base row 3;ext after get 3;base child pre;base child 13;base child post;ext child pre;ext child 13;ext child post;ext before post;base row post;ext after post;base post;ext post global=1;');
        Observer.Expect('BreakAfter', 'base init;base pre filters=[];ext pre global=1 filters=[];ext before pre;base row pre filters=[];ext after pre;ext before get 1;base row 1;ext after get 1;base child pre;base child 10;base child 11;base child post;ext child pre;ext child 10;ext child 11;ext child post;ext before get 2;base row 2;ext after get 2;ext before post;base row post;ext after post;base post;ext post global=1;');
        Observer.Expect('QuitAfter', 'base init;base pre filters=[];ext pre global=1 filters=[];ext before pre;base row pre filters=[];ext after pre;ext before get 1;base row 1;ext after get 1;base child pre;base child 10;base child 11;base child post;ext child pre;ext child 10;ext child 11;ext child post;ext before get 2;base row 2;ext after get 2;');
        Observer.Verify();
    end;





    [Test]
    procedure Two_Extensions_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.Run(Report::"LT PnH ExtBase2");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'base pre;B pre;C pre;B before 1;C before 1;base row 1;B after 1;C after 1;B child 10;B child 11;C child 10;C child 11;B before 2;C before 2;base row 2;B after 2;C after 2;B child 12;C child 12;base post;B post;C post;');
        Observer.Verify();
    end;
}
