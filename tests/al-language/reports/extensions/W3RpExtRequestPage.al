//sub:reportext
// Request page of a report extension (docs/probes-needed.md md:15 and md:223).
// Base report "W3 RpExt Base" has one request page control on a protected variable. Two report extensions add controls (addlast, addafter,
// addfirst, addbefore), modify the caption of the base control, bind a control to a protected variable of the base that the base page does not show,
// bind a control to a variable of the extension, and declare OnOpenPage / OnClosePage of their request pages.

codeunit 67704 "W3 RpExt Log"
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

report 67705 "W3 RpExt Base"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            trigger OnPreDataItem()
            begin
                ExtLog.Add('base PreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                ExtLog.Add('base Row ' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Main)
                {
                    field(MainCtl; MainVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Main control';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            ExtLog.Add('base OnOpenPage main=' + Format(MainVal));
        end;

        trigger OnClosePage()
        begin
            ExtLog.Add('base OnClosePage main=' + Format(MainVal));
        end;
    }

    protected var
        MainVal: Integer;
        HiddenText: Text[30];

    var
        ExtLog: Codeunit "W3 RpExt Log";

    trigger OnPreReport()
    begin
        ExtLog.Add('base PreReport main=' + Format(MainVal) + ' hidden=' + HiddenText);
    end;

    trigger OnPostReport()
    begin
        ExtLog.Add('base PostReport');
    end;
}

reportextension 67706 "W3 RpExt Ext1" extends "W3 RpExt Base"
{
    requestpage
    {
        layout
        {
            addlast(Main)
            {
                field(ExtHidden; HiddenText)
                {
                    ApplicationArea = All;
                    Caption = 'Ext hidden';
                }
                field(ExtOwn; OwnVal)
                {
                    ApplicationArea = All;
                    Caption = 'Ext own';
                }
            }
            addafter(MainCtl)
            {
                field(ExtAfterMain; MainVal)
                {
                    ApplicationArea = All;
                    Caption = 'Ext after main';
                }
            }
            modify(MainCtl)
            {
                Caption = 'Main by ext1';
            }
        }

        trigger OnOpenPage()
        begin
            ExtLog.Add('ext1 OnOpenPage own=' + Format(OwnVal) + ' main=' + Format(MainVal));
        end;

        trigger OnClosePage()
        begin
            ExtLog.Add('ext1 OnClosePage own=' + Format(OwnVal));
        end;
    }

    var
        OwnVal: Integer;
        ExtLog: Codeunit "W3 RpExt Log";

    trigger OnPreReport()
    begin
        ExtLog.Add('ext1 PreReport own=' + Format(OwnVal) + ' main=' + Format(MainVal) + ' hidden=' + HiddenText);
    end;
}

reportextension 67707 "W3 RpExt Ext2" extends "W3 RpExt Base"
{
    requestpage
    {
        layout
        {
            addfirst(Content)
            {
                group(Ext2Group)
                {
                    Caption = 'Ext2 group';

                    field(Ext2First; Own2)
                    {
                        ApplicationArea = All;
                        Caption = 'Ext2 first';
                    }
                }
            }
            addbefore(MainCtl)
            {
                field(Ext2Before; MainVal)
                {
                    ApplicationArea = All;
                    Caption = 'Ext2 before main';
                }
            }
            modify(MainCtl)
            {
                Caption = 'Main by ext2';
            }
        }

        trigger OnOpenPage()
        begin
            ExtLog.Add('ext2 OnOpenPage own2=' + Format(Own2));
        end;

        trigger OnClosePage()
        begin
            ExtLog.Add('ext2 OnClosePage own2=' + Format(Own2));
        end;
    }

    var
        Own2: Integer;
        ExtLog: Codeunit "W3 RpExt Log";

    trigger OnPreReport()
    begin
        ExtLog.Add('ext2 PreReport own2=' + Format(Own2));
    end;
}

codeunit 67708 "W3 RpExt Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ExtLog: Codeunit "W3 RpExt Log";
        Dataset: Codeunit "W3 Dataset";

    local procedure Seed()
    var
        Row: Record "W3 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Commit();
        ExtLog.Take();
    end;

    // md:15 and md:223. Run with the extension controls: names, captions, values, which variables they reach, trigger order.
    [Test]
    [HandlerFunctions('SetAllHandler')]
    procedure Run_ExtensionControls_ReachTheVariablesAndTheRunIsUnchanged()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 RpExt Base");
        Observer.Observe('log', ExtLog.Take());
        Observer.Expect('log', 'base OnOpenPage main=0;ext1 OnOpenPage own=0 main=0;ext2 OnOpenPage own2=0;caption main=Main by ext2;start hidden=[] after=[0] before=[0];after main=5: ext after=[5] ext2 before=[5];after ext after=6: main=[5] ext2 before=[5];set done hidden=[abc] own=[7] first=[9];base OnClosePage main=5;ext1 OnClosePage own=7;ext2 OnClosePage own2=9;base PreReport main=5 hidden=abc;ext1 PreReport own=7 main=5 hidden=abc;ext2 PreReport own2=9;base PreDataItem;base Row 1;base Row 2;base PostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SetAllHandler(var RP: TestRequestPage "W3 RpExt Base")
    begin
        ExtLog.Add('caption main=' + RP.MainCtl.Caption());
        ExtLog.Add('start hidden=[' + RP.ExtHidden.Value() + '] after=[' + RP.ExtAfterMain.Value() + '] before=[' + RP.Ext2Before.Value() + ']');
        RP.ExtHidden.SetValue('abc');
        RP.MainCtl.SetValue(5);
        ExtLog.Add('after main=5: ext after=[' + RP.ExtAfterMain.Value() + '] ext2 before=[' + RP.Ext2Before.Value() + ']');
        RP.ExtAfterMain.SetValue(6);
        ExtLog.Add('after ext after=6: main=[' + RP.MainCtl.Value() + '] ext2 before=[' + RP.Ext2Before.Value() + ']');
        RP.ExtOwn.SetValue(7);
        RP.Ext2First.SetValue(9);
        ExtLog.Add('set done hidden=[' + RP.ExtHidden.Value() + '] own=[' + RP.ExtOwn.Value() + '] first=[' + RP.Ext2First.Value() + ']');
        RP.OK().Invoke();
    end;

    // md:223: Cancel leaves only the request page triggers.
    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure Run_Cancel_OnlyTheRequestPageTriggersRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 RpExt Base");
        Observer.Observe('log', ExtLog.Take());
        Observer.Expect('log', 'base OnOpenPage main=0;ext1 OnOpenPage own=0 main=0;ext2 OnOpenPage own2=0;base OnClosePage main=0;ext1 OnClosePage own=3;ext2 OnClosePage own2=0;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure CancelHandler(var RP: TestRequestPage "W3 RpExt Base")
    begin
        RP.ExtOwn.SetValue(3);
        RP.Cancel().Invoke();
    end;

    // md:15: the parameters text names the extension controls by control name; where the values of the shared variable and of the extension variable go.
    [Test]
    [HandlerFunctions('SetAllHandler')]
    procedure RunRequestPage_ParametersText_ListsExtensionControls()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 RpExt Base");
        Observer.Observe('options', Dataset.Between(Parameters, '<Options>', '</Options>'));
        Observer.Observe('dataitems', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Observe('log', ExtLog.Take());
        Observer.Expect('options', '<Field name="MainVal">5</Field><Field name="HiddenText">abc</Field><Field name="OwnVal">7</Field><Field name="Own2">9</Field>');
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field1)</DataItem>');
        Observer.Expect('log', 'base OnOpenPage main=0;ext1 OnOpenPage own=0 main=0;ext2 OnOpenPage own2=0;caption main=Main by ext2;start hidden=[] after=[0] before=[0];after main=5: ext after=[5] ext2 before=[5];after ext after=6: main=[5] ext2 before=[5];set done hidden=[abc] own=[7] first=[9];base OnClosePage main=5;ext1 OnClosePage own=7;ext2 OnClosePage own2=9;');
        Observer.Verify();
    end;

    // md:15 and md:219: a hand written parameters text sets extension controls (control names), the base control and a data item view.
    [Test]
    [HandlerFunctions('ReadHandler')]
    procedure RunRequestPage_SeededWithExtensionControlValues()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Text;
        Parameters: Text;
    begin
        Seed();
        Seed := '<?xml version="1.0" standalone="yes"?><ReportParameters name="W3 RpExt Base" id="' + Format(Report::"W3 RpExt Base") +
            '"><Options><Field name="ExtHidden">zzz</Field><Field name="MainCtl">3</Field><Field name="ExtOwn">4</Field></Options>' +
            '<DataItems><DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(2))</DataItem></DataItems></ReportParameters>';
        Parameters := Report.RunRequestPage(Report::"W3 RpExt Base", Seed);
        Observer.Observe('log', ExtLog.Take());
        Observer.Observe('options', Dataset.Between(Parameters, '<Options>', '</Options>'));
        Observer.Observe('dataitems', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Expect('log', 'base OnOpenPage main=0;ext1 OnOpenPage own=0 main=0;ext2 OnOpenPage own2=0;handler hidden=[] main=[0] after=[0] own=[0] first=[0];handler view=[2];base OnClosePage main=0;ext1 OnClosePage own=0;ext2 OnClosePage own2=0;');
        Observer.Expect('options', '<Field name="MainVal">0</Field><Field name="HiddenText" /><Field name="OwnVal">0</Field><Field name="Own2">0</Field>');
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(2))</DataItem>');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ReadHandler(var RP: TestRequestPage "W3 RpExt Base")
    begin
        ExtLog.Add('handler hidden=[' + RP.ExtHidden.Value() + '] main=[' + RP.MainCtl.Value() + '] after=[' + RP.ExtAfterMain.Value() + '] own=[' + RP.ExtOwn.Value() + '] first=[' + RP.Ext2First.Value() + ']');
        ExtLog.Add('handler view=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    // Al-runner issue 6924 item 2.15: a reportextension that changes the run (it has OnPreReport) adds request page fields bound to a
    // protected variable of the base (ExtBaseCtl on BaseVal, next to the base's own BaseCtl), to a field of the base's data item
    // (ExtRowCtl on BindRow.Name) and to its own variable (ExtOwnCtl on OwnVal). Objects: report 95360, reportextension 95361 below.
    local procedure BindSeed()
    var
        Row: Record "W3 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'first';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'second';
        Row.Insert();
        Commit();
        ExtLog.Take();
    end;

    local procedure BindControls(var RP: TestRequestPage "RPT ExtBind Base"; Step: Text)
    begin
        ExtLog.Add(Step + ': base=[' + RP.BaseCtl.Value() + '] ext=[' + RP.ExtBaseCtl.Value() + '] row=[' + RP.ExtRowCtl.Value() + '] own=[' + RP.ExtOwnCtl.Value() + ']');
    end;

    // (a) Only the extension's control on the base variable is set.
    [Test]
    [HandlerFunctions('BindExtOnlyHandler')]
    procedure Bind_ExtControlOnBaseVariable_SetAlone_ReachesTheRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BindSeed();
        Report.Run(Report::"RPT ExtBind Base");
        Observer.Observe('log', ExtLog.Take());
        Observer.Expect('log', 'open: base=[0] ext=[0] row=[] own=[0];ext=4: base=[0] ext=[0] row=[] own=[0];base OnClosePage base=0 row=;base PreReport base=0 row=;ext PreReport base=0 own=0 row=;base PreDataItem name=;base Row 1 first;base Row 2 second;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure BindExtOnlyHandler(var RP: TestRequestPage "RPT ExtBind Base")
    begin
        BindControls(RP, 'open');
        RP.ExtBaseCtl.SetValue(4);
        BindControls(RP, 'ext=4');
        RP.OK().Invoke();
    end;

    // (b) The extension's control first, then the base's own control on the same variable.
    [Test]
    [HandlerFunctions('BindExtThenBaseHandler')]
    procedure Bind_ExtControlThenBaseControl_SameVariable_ReachesTheRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BindSeed();
        Report.Run(Report::"RPT ExtBind Base");
        Observer.Observe('log', ExtLog.Take());
        Observer.Expect('log', 'ext=4: base=[0] ext=[0] row=[] own=[0];base=8: base=[8] ext=[8] row=[] own=[0];base OnClosePage base=8 row=;base PreReport base=8 row=;ext PreReport base=8 own=0 row=;base PreDataItem name=;base Row 1 first;base Row 2 second;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure BindExtThenBaseHandler(var RP: TestRequestPage "RPT ExtBind Base")
    begin
        RP.ExtBaseCtl.SetValue(4);
        BindControls(RP, 'ext=4');
        RP.BaseCtl.SetValue(8);
        BindControls(RP, 'base=8');
        RP.OK().Invoke();
    end;

    // (b, reversed) The base's own control first, then the extension's control on the same variable.
    [Test]
    [HandlerFunctions('BindBaseThenExtHandler')]
    procedure Bind_BaseControlThenExtControl_SameVariable_ReachesTheRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BindSeed();
        Report.Run(Report::"RPT ExtBind Base");
        Observer.Observe('log', ExtLog.Take());
        Observer.Expect('log', 'base=8: base=[8] ext=[8] row=[] own=[0];ext=4: base=[8] ext=[8] row=[] own=[0];base OnClosePage base=8 row=;base PreReport base=8 row=;ext PreReport base=8 own=0 row=;base PreDataItem name=;base Row 1 first;base Row 2 second;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure BindBaseThenExtHandler(var RP: TestRequestPage "RPT ExtBind Base")
    begin
        RP.BaseCtl.SetValue(8);
        BindControls(RP, 'base=8');
        RP.ExtBaseCtl.SetValue(4);
        BindControls(RP, 'ext=4');
        RP.OK().Invoke();
    end;

    // (c) The extension's control on a field of the base's data item.
    [Test]
    [HandlerFunctions('BindRowFieldHandler')]
    procedure Bind_ExtControlOnDataItemField_ReachesTheRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BindSeed();
        Report.Run(Report::"RPT ExtBind Base");
        Observer.Observe('log', ExtLog.Take());
        Observer.Expect('log', 'row=typed: base=[0] ext=[0] row=[typed] own=[0];base OnClosePage base=0 row=typed;base PreReport base=0 row=typed;ext PreReport base=0 own=0 row=typed;base PreDataItem name=typed;base Row 1 first;base Row 2 second;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure BindRowFieldHandler(var RP: TestRequestPage "RPT ExtBind Base")
    begin
        RP.ExtRowCtl.SetValue('typed');
        BindControls(RP, 'row=typed');
        RP.OK().Invoke();
    end;

    // (d) The extension's control on its own variable.
    [Test]
    [HandlerFunctions('BindOwnHandler')]
    procedure Bind_ExtControlOnOwnVariable_ReachesTheRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BindSeed();
        Report.Run(Report::"RPT ExtBind Base");
        Observer.Observe('log', ExtLog.Take());
        Observer.Expect('log', 'own=7: base=[0] ext=[0] row=[] own=[7];base OnClosePage base=0 row=;base PreReport base=0 row=;ext PreReport base=0 own=7 row=;base PreDataItem name=;base Row 1 first;base Row 2 second;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure BindOwnHandler(var RP: TestRequestPage "RPT ExtBind Base")
    begin
        RP.ExtOwnCtl.SetValue(7);
        BindControls(RP, 'own=7');
        RP.OK().Invoke();
    end;

    // All four controls set, read back as the parameters text of RunRequestPage: which names the values are stored under.
    [Test]
    [HandlerFunctions('BindAllHandler')]
    procedure Bind_RunRequestPage_ParametersText_AllBindings()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        BindSeed();
        Parameters := Report.RunRequestPage(Report::"RPT ExtBind Base");
        Observer.Observe('options', Dataset.Between(Parameters, '<Options>', '</Options>'));
        Observer.Observe('dataitems', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Observe('log', ExtLog.Take());
        Observer.Expect('options', '<Field name="BaseVal">0</Field><Field name="BindRow.Name">typed</Field><Field name="OwnVal">7</Field>');
        Observer.Expect('dataitems', '<DataItem name="BindRow">VERSION(1) SORTING(Field1)</DataItem>');
        Observer.Expect('log', 'all set: base=[0] ext=[0] row=[typed] own=[7];base OnClosePage base=0 row=typed;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure BindAllHandler(var RP: TestRequestPage "RPT ExtBind Base")
    begin
        RP.ExtBaseCtl.SetValue(4);
        RP.ExtRowCtl.SetValue('typed');
        RP.ExtOwnCtl.SetValue(7);
        BindControls(RP, 'all set');
        RP.OK().Invoke();
    end;
}

// local object: the request page of a reportextension that changes the run is what the tests above check (al-runner issue 6924 item 2.15).
report 95360 "RPT ExtBind Base"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(BindRow; "W3 Row")
        {
            trigger OnPreDataItem()
            begin
                ExtLog.Add('base PreDataItem name=' + BindRow.Name);
            end;

            trigger OnAfterGetRecord()
            begin
                ExtLog.Add('base Row ' + Format(BindRow.Id) + ' ' + BindRow.Name);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Opts)
                {
                    field(BaseCtl; BaseVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Base control';
                    }
                }
            }
        }

        trigger OnClosePage()
        begin
            ExtLog.Add('base OnClosePage base=' + Format(BaseVal) + ' row=' + BindRow.Name);
        end;
    }

    protected var
        BaseVal: Integer;

    var
        ExtLog: Codeunit "W3 RpExt Log";

    trigger OnPreReport()
    begin
        ExtLog.Add('base PreReport base=' + Format(BaseVal) + ' row=' + BindRow.Name);
    end;
}

// local object: see report 95360.
reportextension 95361 "RPT ExtBind Ext" extends "RPT ExtBind Base"
{
    requestpage
    {
        layout
        {
            addlast(Opts)
            {
                field(ExtBaseCtl; BaseVal)
                {
                    ApplicationArea = All;
                    Caption = 'Ext on base variable';
                }
                field(ExtRowCtl; BindRow.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Ext on data item field';
                }
                field(ExtOwnCtl; OwnVal)
                {
                    ApplicationArea = All;
                    Caption = 'Ext on own variable';
                }
            }
        }
    }

    var
        OwnVal: Integer;
        ExtLog: Codeunit "W3 RpExt Log";

    trigger OnPreReport()
    begin
        ExtLog.Add('ext PreReport base=' + Format(BaseVal) + ' own=' + Format(OwnVal) + ' row=' + BindRow.Name);
    end;
}

// ---- Extension controls on a variable with no base control, on a data item the extension adds, and on other source expressions (al-runner issue 6924, waldo) ----
// Base report 97040: request page control BaseCtl on BaseVal only; NoCtlVal and NoCtlText are protected variables with no base control.
// Extension 97041 adds controls: ExtNoCtl (NoCtlVal), ExtNoCtlText (NoCtlText), ExtItemCtl (ExtItem.Name, ExtItem is a data item the
// extension adds below BaseRow), ExtRowCtl (BaseRow.Name), ExtRecCtl (ExtRec.Name, a record variable of the extension), ExtOwnCtl (OwnVal).

report 97040 "LT W9 RpExt Base"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(BaseRow; "W3 Row")
        {
            trigger OnPreDataItem()
            begin
                ExtLog.Add('base PreDataItem name=' + BaseRow.Name);
            end;

            trigger OnAfterGetRecord()
            begin
                ExtLog.Add('base Row ' + Format(BaseRow.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Opts)
                {
                    field(BaseCtl; BaseVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Base control';
                    }
                }
            }
        }
    }

    protected var
        BaseVal: Integer;
        NoCtlVal: Integer;
        NoCtlText: Text[30];

    var
        ExtLog: Codeunit "W3 RpExt Log";

    trigger OnPreReport()
    begin
        ExtLog.Add('base PreReport base=' + Format(BaseVal) + ' noCtl=' + Format(NoCtlVal) + ' noCtlText=' + NoCtlText + ' row=' + BaseRow.Name);
    end;
}

reportextension 97041 "LT W9 RpExt Ext" extends "LT W9 RpExt Base"
{
    dataset
    {
        addlast(BaseRow)
        {
            dataitem(ExtItem; "W3 Row")
            {
                DataItemLink = Id = field(Id);

                trigger OnPreDataItem()
                begin
                    ExtLog.Add('ext PreDataItem name=' + ExtItem.Name);
                end;

                trigger OnAfterGetRecord()
                begin
                    ExtLog.Add('ext Item ' + Format(ExtItem.Id));
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            addlast(Opts)
            {
                field(ExtNoCtl; NoCtlVal)
                {
                    ApplicationArea = All;
                    Caption = 'Ext on variable without base control';
                }
                field(ExtNoCtlText; NoCtlText)
                {
                    ApplicationArea = All;
                    Caption = 'Ext on text variable without base control';
                }
                field(ExtItemCtl; ExtItem.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Ext on added data item field';
                }
                field(ExtRowCtl; BaseRow.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Ext on base data item field';
                }
                field(ExtRecCtl; ExtRec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Ext on record variable field';
                }
                field(ExtOwnCtl; OwnVal)
                {
                    ApplicationArea = All;
                    Caption = 'Ext on own variable';
                }
            }
        }
    }

    var
        OwnVal: Integer;
        ExtRec: Record "W3 Row";
        ExtLog: Codeunit "W3 RpExt Log";

    trigger OnPreReport()
    begin
        ExtLog.Add('ext PreReport own=' + Format(OwnVal) + ' rec=' + ExtRec.Name + ' item=' + ExtItem.Name);
    end;
}

codeunit 97042 "LT W9 RpExt Controls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ExtLog: Codeunit "W3 RpExt Log";
        Dataset: Codeunit "W3 Dataset";

    local procedure Seed()
    var
        Row: Record "W3 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'first';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'second';
        Row.Insert();
        Commit();
        ExtLog.Take();
    end;

    local procedure Controls(var RP: TestRequestPage "LT W9 RpExt Base"; Step: Text)
    begin
        ExtLog.Add(Step + ': base=[' + RP.BaseCtl.Value() + '] noCtl=[' + RP.ExtNoCtl.Value() + '] noCtlText=[' + RP.ExtNoCtlText.Value() + '] item=[' + RP.ExtItemCtl.Value() + '] row=[' + RP.ExtRowCtl.Value() + '] rec=[' + RP.ExtRecCtl.Value() + '] own=[' + RP.ExtOwnCtl.Value() + ']');
    end;

    local procedure ObserveParameters(Parameters: Text)
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('options', Dataset.Between(Parameters, '<Options>', '</Options>'));
        Observer.Observe('dataitems', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Observe('log', ExtLog.Take());
        Observer.Finish();
    end;

    // 1. Controls on variables the base page has no control for.
    [Test]
    [HandlerFunctions('NoCtlIntHandler')]
    procedure RunRequestPage_NoBaseControl_IntegerSet()
    begin
        Seed();
        ObserveParameters(Report.RunRequestPage(Report::"LT W9 RpExt Base"));
    end;

    [RequestPageHandler]
    procedure NoCtlIntHandler(var RP: TestRequestPage "LT W9 RpExt Base")
    begin
        Controls(RP, 'open');
        RP.ExtNoCtl.SetValue(4);
        Controls(RP, 'noCtl=4');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('NoCtlBothHandler')]
    procedure RunRequestPage_NoBaseControl_IntegerAndTextSet()
    begin
        Seed();
        ObserveParameters(Report.RunRequestPage(Report::"LT W9 RpExt Base"));
    end;

    [RequestPageHandler]
    procedure NoCtlBothHandler(var RP: TestRequestPage "LT W9 RpExt Base")
    begin
        RP.ExtNoCtl.SetValue(4);
        RP.ExtNoCtlText.SetValue('abc');
        Controls(RP, 'both');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('OkOnlyHandler')]
    procedure RunRequestPage_NothingSet()
    begin
        Seed();
        ObserveParameters(Report.RunRequestPage(Report::"LT W9 RpExt Base"));
    end;

    [RequestPageHandler]
    procedure OkOnlyHandler(var RP: TestRequestPage "LT W9 RpExt Base")
    begin
        Controls(RP, 'open');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('NoCtlBothHandler')]
    procedure Run_NoBaseControl_ReachesTheRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT W9 RpExt Base");
        Observer.Observe('log', ExtLog.Take());
        Observer.Finish();
    end;

    // 2. A control on a data item the extension adds.
    [Test]
    [HandlerFunctions('ItemHandler')]
    procedure RunRequestPage_ControlOnAddedDataItem()
    begin
        Seed();
        ObserveParameters(Report.RunRequestPage(Report::"LT W9 RpExt Base"));
    end;

    [RequestPageHandler]
    procedure ItemHandler(var RP: TestRequestPage "LT W9 RpExt Base")
    begin
        Controls(RP, 'open');
        RP.ExtItemCtl.SetValue('typed');
        Controls(RP, 'item=typed');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemHandler')]
    procedure Run_ControlOnAddedDataItem_ReachesTheRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT W9 RpExt Base");
        Observer.Observe('log', ExtLog.Take());
        Observer.Finish();
    end;

    // 3. Source expressions other than a field of a data item or a plain variable: a field of a record variable of the extension.
    [Test]
    [HandlerFunctions('RecHandler')]
    procedure RunRequestPage_ControlOnRecordVariableField()
    begin
        Seed();
        ObserveParameters(Report.RunRequestPage(Report::"LT W9 RpExt Base"));
    end;

    [RequestPageHandler]
    procedure RecHandler(var RP: TestRequestPage "LT W9 RpExt Base")
    begin
        RP.ExtRecCtl.SetValue('viaRec');
        RP.ExtOwnCtl.SetValue(7);
        RP.ExtRowCtl.SetValue('viaRow');
        Controls(RP, 'rec');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('RecHandler')]
    procedure Run_ControlOnRecordVariableField_ReachesTheRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT W9 RpExt Base");
        Observer.Observe('log', ExtLog.Take());
        Observer.Finish();
    end;

    // 4. The same controls set through a parameters text, by control name and by variable name (no request page handler: the page is not shown).
    local procedure ExecuteWith(Options: Text; Items: Text)
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT W9 RpExt Base" id="' + Format(Report::"LT W9 RpExt Base") +
            '"><Options>' + Options + '</Options><DataItems>' + Items + '</DataItems></ReportParameters>';
        ClearLastError();
        Observer.Observe('ok', Format(TryExecute(Parameters)));
        Observer.ObserveError('execute');
        Observer.Observe('log', ExtLog.Take());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryExecute(Parameters: Text)
    begin
        Report.Execute(Report::"LT W9 RpExt Base", Parameters);
    end;

    [Test]
    procedure Execute_ParametersText_ControlNames()
    begin
        ExecuteWith('<Field name="ExtNoCtl">4</Field><Field name="ExtNoCtlText">abc</Field><Field name="ExtItemCtl">typed</Field><Field name="ExtRowCtl">viaRow</Field><Field name="ExtRecCtl">viaRec</Field><Field name="ExtOwnCtl">7</Field>', '');
    end;

    [Test]
    procedure Execute_ParametersText_VariableNames()
    begin
        ExecuteWith('<Field name="NoCtlVal">4</Field><Field name="NoCtlText">abc</Field><Field name="ExtItem.Name">typed</Field><Field name="BaseRow.Name">viaRow</Field><Field name="ExtRec.Name">viaRec</Field><Field name="OwnVal">7</Field>', '');
    end;

    [Test]
    procedure Execute_ParametersText_DataItemFieldOnly_ByControlName()
    begin
        ExecuteWith('<Field name="ExtItemCtl">typed</Field>', '');
    end;

    [Test]
    procedure Execute_ParametersText_DataItemFieldOnly_ByDataItemField()
    begin
        ExecuteWith('<Field name="ExtItem.Name">typed</Field>', '');
    end;

    [Test]
    procedure Execute_ParametersText_BaseRowFieldOnly_ByControlName()
    begin
        ExecuteWith('<Field name="ExtRowCtl">viaRow</Field>', '');
    end;

    [Test]
    procedure Execute_ParametersText_BaseRowFieldOnly_ByDataItemField()
    begin
        ExecuteWith('<Field name="BaseRow.Name">viaRow</Field>', '');
    end;

    [Test]
    procedure SaveAs_ParametersText_DataItemFieldControl()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Dataset.Save(Report::"LT W9 RpExt Base", '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT W9 RpExt Base" id="' + Format(Report::"LT W9 RpExt Base") +
            '"><Options><Field name="ExtItemCtl">typed</Field><Field name="ExtRowCtl">viaRow</Field></Options><DataItems></DataItems></ReportParameters>', Xml);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('saveas');
        Observer.Observe('xml', Xml);
        Observer.Observe('log', ExtLog.Take());
        Observer.Finish();
    end;
}
