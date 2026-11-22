// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-showastree-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects table 73692, page 73694, codeunits 73693, 73695
// Probe: al-runner issue 8523, path P2b. The tree action of pages/extensions/R7168TreeBoardObjects.al (a Worksheet over a temporary table
//   with a collapsed tree and both row triggers; an action leaves Rec on a child row the page does not show, with or without
//   CurrPage.Update(false)), here with a header control whose OnValidate errors, alone or after CurrPage.Update(true) or Update(false),
//   run before the action on the same open page. Rows: 1 WC1 (0), 2 MC1 (1), 3 MC2 (1), 4 WC2 (0), 5 MC3 (1).
// Facts (measured on BC 28.5; 27.5 and 29.0 see the pull request): without an earlier step both actions give the R7168 result. After
//   any failed header OnValidate (error only, or after Update(true) or Update(false)) the action's Invoke raises nothing and its
//   OnAction does not run: no trigger runs, the page stays on WC1 and shows WC1, WC2.
// BC versions: 27, 28, 29

table 73692 "LT FU Tree Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Row ID"; Integer) { }
        field(2; "No."; Code[20]) { }
        field(3; Indentation; Integer) { }
    }

    keys
    {
        key(PK; "Row ID") { Clustered = true; }
    }
}

page 73694 "LT FU Tree Board"
{
    PageType = Worksheet;
    SourceTable = "LT FU Tree Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(Boom; Boom)
                {
                    ApplicationArea = All;

                    // The earlier step: always ends with an error, after the step the test picks.
                    trigger OnValidate()
                    begin
                        Log.Add('B:start ' + Rec."No.");
                        case Log.BoomMode() of
                            1:
                                CurrPage.Update(true);
                            2:
                                CurrPage.Update(false);
                        end;
                        Log.Add('B:error');
                        Error('LT FU boom');
                    end;
                }
            }
            repeater(Rows)
            {
                ShowAsTree = true;
                TreeInitialState = CollapseAll;
                IndentationColumn = Rec.Indentation;

                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(CellCtl; CellText) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetChild)
            {
                ApplicationArea = All;
                Caption = 'Get Child';

                trigger OnAction()
                begin
                    Log.Add('act-get=' + Format(Rec.Get(2)));
                end;
            }
            action(GetChildAndRefresh)
            {
                ApplicationArea = All;
                Caption = 'Get Child And Refresh';

                trigger OnAction()
                begin
                    Log.Add('act-get=' + Format(Rec.Get(2)));
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Fill();
        if Rec.FindFirst() then;
        Log.Add('open n=' + Format(Rec.Count()) + ' cur=' + Rec."No.");
    end;

    trigger OnAfterGetRecord()
    begin
        CellText := 'cell of ' + Rec."No.";
        Log.Add('agr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr' + Rec."No.");
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M:' + Rec."No.");
        exit(true);
    end;

    local procedure Fill()
    begin
        Rec.DeleteAll();
        Add(1, 'WC1', 0);
        Add(2, 'MC1', 1);
        Add(3, 'MC2', 1);
        Add(4, 'WC2', 0);
        Add(5, 'MC3', 1);
    end;

    local procedure Add(RowID: Integer; No: Code[20]; Indentation: Integer)
    begin
        Rec.Init();
        Rec."Row ID" := RowID;
        Rec."No." := No;
        Rec.Indentation := Indentation;
        Rec.Insert();
    end;

    var
        Log: Codeunit "LT FU Tree Log";
        CellText: Text;
        Boom: Integer;
}

// The log and the failing step of page 73694. Used by test codeunit 73695 only.
codeunit 73693 "LT FU Tree Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Boom: Integer;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    // 0: error only, 1: CurrPage.Update(true) then error, 2: CurrPage.Update(false) then error.
    procedure SetBoomMode(NewBoom: Integer)
    begin
        Boom := NewBoom;
    end;

    procedure BoomMode(): Integer
    begin
        exit(Boom);
    end;
}

codeunit 73695 "LT FU Tree Action Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT FU Tree Log";

    [TryFunction]
    local procedure TryBoom(var P: TestPage "LT FU Tree Board")
    begin
        P.Boom.SetValue(1);
    end;

    local procedure Walk(var P: TestPage "LT FU Tree Board") Result: Text
    begin
        if P.First() then
            repeat
                Result += P.NoCtl.Value() + ' ';
            until not P.Next();
        Result := Result.TrimEnd();
    end;

    local procedure Run(WithBoom: Boolean; BoomMode: Integer; Refresh: Boolean)
    var
        P: TestPage "LT FU Tree Board";
        Ok: Boolean;
    begin
        Log.SetBoomMode(BoomMode);
        Log.Take();
        P.OpenEdit();
        Observer.Observe('open-log', Log.Take());
        Observer.Observe('first', Format(P.First()) + '/' + P.NoCtl.Value());
        Log.Take();
        if WithBoom then begin
            Ok := TryBoom(P);
            Observer.Observe('boom', Format(Ok));
            if not Ok then
                Observer.ObserveError('boom error');
            Observer.Observe('boom-log', Log.Take());
        end;
        if Refresh then
            P.GetChildAndRefresh.Invoke()
        else
            P.GetChild.Invoke();
        Observer.Observe('action-log', Log.Take());
        Observer.Observe('current', P.NoCtl.Value());
        Observer.Observe('current-cell', P.CellCtl.Value());
        Observer.Observe('current-expanded', Format(P.IsExpanded()));
        Observer.Observe('walk', Walk(P));
        Log.Take();
        P.Close();
        Observer.Observe('close-log', Log.Take());
    end;

    // The pinned shape (Y28CollapsedTreeTests.al R7168_ActionGetChildWithoutRefresh), no earlier step.
    [Test]
    procedure TreeGetChild_NoEarlierStep()
    begin
        Run(false, 0, false);
        Observer.Expect('open-log', 'open n=5 cur=WC1;agrWC1;agrMC1;agrMC2;agrWC2;agrMC3;agrWC1;agrWC1;agcrWC1;');
        Observer.Expect('first', 'Yes/WC1');
        Observer.Expect('action-log', 'agrWC1;act-get=Yes;agrMC1;agrMC1;agrMC2;agrWC2;agrMC3;agrMC1;agrWC1;agrMC1;agrMC1;agcrMC1;');
        Observer.Expect('current', 'MC1');
        Observer.Expect('current-cell', 'cell of MC1');
        Observer.Expect('current-expanded', 'No');
        Observer.Expect('walk', 'WC1 MC1 MC2 WC2');
        Observer.Expect('close-log', '');
        Observer.Verify();
    end;

    // Earlier step: a header OnValidate that only errors.
    [Test]
    procedure TreeGetChild_AfterErrorOnly()
    begin
        Run(true, 0, false);
        Observer.Expect('open-log', 'open n=5 cur=WC1;agrWC1;agrMC1;agrMC2;agrWC2;agrMC3;agrWC1;agrWC1;agcrWC1;');
        Observer.Expect('first', 'Yes/WC1');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom-log', 'B:start WC1;B:error;');
        Observer.Expect('action-log', '');
        Observer.Expect('current', 'WC1');
        Observer.Expect('current-cell', 'cell of WC1');
        Observer.Expect('current-expanded', 'No');
        Observer.Expect('walk', 'WC1 WC2');
        Observer.Expect('close-log', '');
        Observer.Verify();
    end;

    // Earlier step: a header OnValidate that calls CurrPage.Update(true), then errors.
    [Test]
    procedure TreeGetChild_AfterFailedUpdateTrue()
    begin
        Run(true, 1, false);
        Observer.Expect('open-log', 'open n=5 cur=WC1;agrWC1;agrMC1;agrMC2;agrWC2;agrMC3;agrWC1;agrWC1;agcrWC1;');
        Observer.Expect('first', 'Yes/WC1');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom-log', 'B:start WC1;B:error;');
        Observer.Expect('action-log', '');
        Observer.Expect('current', 'WC1');
        Observer.Expect('current-cell', 'cell of WC1');
        Observer.Expect('current-expanded', 'No');
        Observer.Expect('walk', 'WC1 WC2');
        Observer.Expect('close-log', '');
        Observer.Verify();
    end;

    // Earlier step: a header OnValidate that calls CurrPage.Update(false), then errors.
    [Test]
    procedure TreeGetChild_AfterFailedUpdateFalse()
    begin
        Run(true, 2, false);
        Observer.Expect('open-log', 'open n=5 cur=WC1;agrWC1;agrMC1;agrMC2;agrWC2;agrMC3;agrWC1;agrWC1;agcrWC1;');
        Observer.Expect('first', 'Yes/WC1');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom-log', 'B:start WC1;B:error;');
        Observer.Expect('action-log', '');
        Observer.Expect('current', 'WC1');
        Observer.Expect('current-cell', 'cell of WC1');
        Observer.Expect('current-expanded', 'No');
        Observer.Expect('walk', 'WC1 WC2');
        Observer.Expect('close-log', '');
        Observer.Verify();
    end;

    // The action with CurrPage.Update(false), no earlier step.
    [Test]
    procedure TreeGetChildRefresh_NoEarlierStep()
    begin
        Run(false, 0, true);
        Observer.Expect('open-log', 'open n=5 cur=WC1;agrWC1;agrMC1;agrMC2;agrWC2;agrMC3;agrWC1;agrWC1;agcrWC1;');
        Observer.Expect('first', 'Yes/WC1');
        Observer.Expect('action-log', 'agrWC1;act-get=Yes;agrMC1;agrMC1;agrMC2;agrWC2;agrMC3;agrMC1;agrWC1;agrMC1;agrMC1;agcrMC1;');
        Observer.Expect('current', 'MC1');
        Observer.Expect('current-cell', 'cell of MC1');
        Observer.Expect('current-expanded', 'No');
        Observer.Expect('walk', 'WC1 MC1 MC2 WC2');
        Observer.Expect('close-log', '');
        Observer.Verify();
    end;

    // The action with CurrPage.Update(false), after a header OnValidate that calls CurrPage.Update(true), then errors.
    [Test]
    procedure TreeGetChildRefresh_AfterFailedUpdateTrue()
    begin
        Run(true, 1, true);
        Observer.Expect('open-log', 'open n=5 cur=WC1;agrWC1;agrMC1;agrMC2;agrWC2;agrMC3;agrWC1;agrWC1;agcrWC1;');
        Observer.Expect('first', 'Yes/WC1');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom-log', 'B:start WC1;B:error;');
        Observer.Expect('action-log', '');
        Observer.Expect('current', 'WC1');
        Observer.Expect('current-cell', 'cell of WC1');
        Observer.Expect('current-expanded', 'No');
        Observer.Expect('walk', 'WC1 WC2');
        Observer.Expect('close-log', '');
        Observer.Verify();
    end;
}
