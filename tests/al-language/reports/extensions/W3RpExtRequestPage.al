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
}
