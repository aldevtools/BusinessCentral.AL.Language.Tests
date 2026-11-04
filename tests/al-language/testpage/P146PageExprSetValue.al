// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70007, pages 70006 and 70009, codeunits 70008 (log) and 70011
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestPage field SetValue on a page control bound to an expression (Buffer[1].Name, a global variable) on a page with a source table and on a page with no source table: the value read back, OnValidate order, the source record, and OnAfterGetCurrRecord refresh after an action
// BC versions: 29 (27 and 28 by CI)

table 70007 "LT P146 Buf Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P146 Page Log";
            begin
                Log.Add('table-onvalidate-name');
            end;
        }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70008 "LT P146 Page Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Clear()
    begin
        Entries := '';
    end;

    procedure Add(Value: Text)
    begin
        Entries += Value + ';';
    end;

    procedure GetEntries(): Text
    begin
        exit(Entries);
    end;
}

page 70006 "LT P146 Buf Card"
{
    PageType = Card;
    SourceTable = "LT P146 Buf Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(RecName; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "LT P146 Page Log";
                begin
                    Log.Add('rec-name-onvalidate=' + Rec.Name);
                end;
            }
            field(BufName; Buffer[1].Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "LT P146 Page Log";
                begin
                    Log.Add('buf-name-onvalidate=' + Buffer[1].Name);
                end;
            }
            field(BufAmount; Buffer[2].Amount)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "LT P146 Page Log";
                begin
                    Log.Add('buf-amount-onvalidate=' + Format(Buffer[2].Amount));
                end;
            }
            field(Plain; PlainText)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "LT P146 Page Log";
                begin
                    Log.Add('plain-onvalidate=' + PlainText);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowBuffer)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT P146 Page Log";
                begin
                    Log.Add('action buf1=' + Buffer[1].Name + ' buf2amount=' + Format(Buffer[2].Amount) + ' plain=' + PlainText + ' recname=' + Rec.Name);
                end;
            }
            action(ChangeBuffer)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Buffer[1].Name := 'changed by action';
                    PlainText := 'plain changed';
                end;
            }
        }
    }

    var
        Buffer: array[2] of Record "LT P146 Buf Row" temporary;
        PlainText: Text;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P146 Page Log";
    begin
        Buffer[1].Name := 'initial buf';
        PlainText := 'initial plain';
        Log.Add('onopenpage');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P146 Page Log";
    begin
        Log.Add('aftergetcurrrecord');
    end;
}

page 70009 "LT P146 NoSource Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Txt; TxtVar)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "LT P146 Page Log";
                begin
                    Log.Add('txt-onvalidate=' + TxtVar);
                end;
            }
            field(Counter; CounterVar)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Bump)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CounterVar += 1;
                    TxtVar := 'bumped ' + Format(CounterVar);
                end;
            }
        }
    }

    var
        TxtVar: Text;
        CounterVar: Integer;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P146 Page Log";
    begin
        TxtVar := 'start';
        Log.Add('nosource onopenpage');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P146 Page Log";
    begin
        Log.Add('nosource aftergetcurrrecord');
    end;
}

codeunit 70011 "LT P146 Page Expr SetValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P146 Buf Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'stored';
        R.Amount := 5;
        R.Insert();
    end;

    [Test]
    procedure P146_SetValue_BufferField_WithSourceTable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P146 Page Log";
        P: TestPage "LT P146 Buf Card";
        R: Record "LT P146 Buf Row";
    begin
        Seed();
        Log.Clear();
        P.OpenEdit();
        Observer.Observe('log after open', Log.GetEntries());
        Observer.Observe('recname initial', P.RecName.Value());
        Observer.Observe('bufname initial', P.BufName.Value());
        Observer.Observe('bufamount initial', P.BufAmount.Value());
        Observer.Observe('plain initial', P.Plain.Value());
        Log.Clear();
        P.BufName.SetValue('typed buf');
        Observer.Observe('log after bufname', Log.GetEntries());
        Observer.Observe('bufname after', P.BufName.Value());
        Observer.Observe('recname after', P.RecName.Value());
        Log.Clear();
        P.BufAmount.SetValue(12.5);
        Observer.Observe('log after bufamount', Log.GetEntries());
        Observer.Observe('bufamount after', P.BufAmount.Value());
        Log.Clear();
        P.Plain.SetValue('typed plain');
        Observer.Observe('log after plain', Log.GetEntries());
        Observer.Observe('plain after', P.Plain.Value());
        Log.Clear();
        P.ShowBuffer.Invoke();
        Observer.Observe('log after action', Log.GetEntries());
        P.Close();
        R.Get(1);
        Observer.Observe('stored name after close', R.Name);
        Observer.Observe('stored amount after close', Format(R.Amount));
        R.DeleteAll();
        Observer.Expect('log after open', 'onopenpage;aftergetcurrrecord;');
        Observer.Expect('recname initial', 'stored');
        Observer.Expect('bufname initial', 'initial buf');
        Observer.Expect('bufamount initial', '0.00');
        Observer.Expect('plain initial', 'initial plain');
        Observer.Expect('log after bufname', 'buf-name-onvalidate=typed buf;');
        Observer.Expect('bufname after', 'typed buf');
        Observer.Expect('recname after', 'stored');
        Observer.Expect('log after bufamount', 'buf-amount-onvalidate=12.5;');
        Observer.Expect('bufamount after', '12.50');
        Observer.Expect('log after plain', 'plain-onvalidate=typed plain;');
        Observer.Expect('plain after', 'typed plain');
        Observer.Expect('log after action', 'action buf1=typed buf buf2amount=12.5 plain=typed plain recname=stored;aftergetcurrrecord;');
        Observer.Expect('stored name after close', 'stored');
        Observer.Expect('stored amount after close', '5');
        Observer.Verify();
    end;

    [Test]
    procedure P146_SetValue_Buffer_ThenRecordField_Order()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P146 Page Log";
        P: TestPage "LT P146 Buf Card";
        R: Record "LT P146 Buf Row";
    begin
        Seed();
        Log.Clear();
        P.OpenEdit();
        Log.Clear();
        P.RecName.SetValue('rec typed');
        Observer.Observe('log after recname', Log.GetEntries());
        P.BufName.SetValue('buf typed');
        Observer.Observe('log after bufname', Log.GetEntries());
        Observer.Observe('bufname', P.BufName.Value());
        Observer.Observe('recname', P.RecName.Value());
        P.Close();
        R.Get(1);
        Observer.Observe('stored name', R.Name);
        R.DeleteAll();
        Observer.Expect('log after recname', 'table-onvalidate-name;rec-name-onvalidate=rec typed;');
        Observer.Expect('log after bufname', 'table-onvalidate-name;rec-name-onvalidate=rec typed;buf-name-onvalidate=buf typed;');
        Observer.Expect('bufname', 'buf typed');
        Observer.Expect('recname', 'rec typed');
        Observer.Expect('stored name', 'rec typed');
        Observer.Verify();
    end;

    [Test]
    procedure P146_Action_ChangesExpressionControls()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P146 Page Log";
        P: TestPage "LT P146 Buf Card";
    begin
        Seed();
        P.OpenEdit();
        Log.Clear();
        P.ChangeBuffer.Invoke();
        Observer.Observe('log after action', Log.GetEntries());
        Observer.Observe('bufname after action', P.BufName.Value());
        Observer.Observe('plain after action', P.Plain.Value());
        P.Close();
        Observer.Expect('log after action', 'aftergetcurrrecord;');
        Observer.Expect('bufname after action', 'changed by action');
        Observer.Expect('plain after action', 'plain changed');
        Observer.Verify();
    end;

    [Test]
    procedure P146_NoSourceTable_SetValue_And_Action()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P146 Page Log";
        P: TestPage "LT P146 NoSource Card";
    begin
        Log.Clear();
        P.OpenEdit();
        Observer.Observe('log after open', Log.GetEntries());
        Observer.Observe('txt initial', P.Txt.Value());
        Observer.Observe('counter initial', P.Counter.Value());
        Log.Clear();
        P.Txt.SetValue('typed');
        Observer.Observe('log after setvalue', Log.GetEntries());
        Observer.Observe('txt after setvalue', P.Txt.Value());
        Log.Clear();
        P.Bump.Invoke();
        Observer.Observe('log after bump', Log.GetEntries());
        Observer.Observe('txt after bump', P.Txt.Value());
        Observer.Observe('counter after bump', P.Counter.Value());
        Log.Clear();
        P.Counter.SetValue(41);
        Observer.Observe('log after counter setvalue', Log.GetEntries());
        P.Bump.Invoke();
        Observer.Observe('counter after second bump', P.Counter.Value());
        Observer.Observe('txt after second bump', P.Txt.Value());
        Observer.Observe('log total', Log.GetEntries());
        P.Close();
        Observer.Expect('log after open', 'nosource onopenpage;nosource aftergetcurrrecord;');
        Observer.Expect('txt initial', 'start');
        Observer.Expect('counter initial', '0');
        Observer.Expect('log after setvalue', 'txt-onvalidate=typed;');
        Observer.Expect('txt after setvalue', 'typed');
        Observer.Expect('log after bump', 'nosource aftergetcurrrecord;');
        Observer.Expect('txt after bump', 'bumped 1');
        Observer.Expect('counter after bump', '1');
        Observer.Expect('log after counter setvalue', '');
        Observer.Expect('counter after second bump', '42');
        Observer.Expect('txt after second bump', 'bumped 42');
        Observer.Expect('log total', 'nosource aftergetcurrrecord;');
        Observer.Verify();
    end;

    // Writer QG (runtime PR 380, lane-old-fails): P146_NoSourceTable_SetValue_And_Action shows OnAfterGetCurrRecord after each action on a
    // card without a source table. These pin, per step, which of OnAfterGetRecord, OnAfterGetCurrRecord and OnNewRecord such a page runs on
    // open (edit, view; OpenNew fails), after an action that does nothing, after an action with CurrPage.Update(false), after SetValue and at Close.
    local procedure QGNoSourceSteps(var Observer: Codeunit "Probe Observer"; var P: TestPage "LT QG NoSource Card")
    var
        Log: Codeunit "LT P146 Page Log";
    begin
        Observer.Observe('log after open', Log.GetEntries());
        Log.Clear();
        Observer.Observe('txt', P.Txt.Value());
        Observer.Observe('log after read', Log.GetEntries());
        Log.Clear();
        P.Noop.Invoke();
        Observer.Observe('log after noop', Log.GetEntries());
        Log.Clear();
        P.Noop.Invoke();
        Observer.Observe('log after second noop', Log.GetEntries());
        Log.Clear();
        P.UpdFalse.Invoke();
        Observer.Observe('log after update action', Log.GetEntries());
        Log.Clear();
        P.Close();
        Observer.Observe('log after close', Log.GetEntries());
    end;

    [Test]
    procedure QG_NoSource_OpenEdit_StepLog()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P146 Page Log";
        P: TestPage "LT QG NoSource Card";
    begin
        Log.Clear();
        P.OpenEdit();
        QGNoSourceSteps(Observer, P);
        Observer.Expect('log after open', 'qg open;qg agcr;');
        Observer.Expect('txt', 'start');
        Observer.Expect('log after read', '');
        Observer.Expect('log after noop', 'qg action;qg agcr;');
        Observer.Expect('log after second noop', 'qg action;qg agcr;');
        Observer.Expect('log after update action', 'qg update;qg update done;qg agcr;');
        Observer.Expect('log after close', 'qg close;');
        Observer.Verify();
    end;

    [Test]
    procedure QG_NoSource_OpenView_StepLog()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P146 Page Log";
        P: TestPage "LT QG NoSource Card";
    begin
        Log.Clear();
        P.OpenView();
        QGNoSourceSteps(Observer, P);
        Observer.Expect('log after open', 'qg open;qg agcr;');
        Observer.Expect('txt', 'start');
        Observer.Expect('log after read', '');
        Observer.Expect('log after noop', 'qg action;qg agcr;');
        Observer.Expect('log after second noop', 'qg action;qg agcr;');
        Observer.Expect('log after update action', 'qg update;qg update done;qg agcr;');
        Observer.Expect('log after close', 'qg close;');
        Observer.Verify();
    end;

    [Test]
    procedure QG_NoSource_OpenNew_StepLog()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P146 Page Log";
        P: TestPage "LT QG NoSource Card";
    begin
        Log.Clear();
        asserterror P.OpenNew();
        Observer.Observe('open new error', GetLastErrorText());
        Observer.Observe('open new error code', GetLastErrorCode());
        Observer.Observe('log after open new', Log.GetEntries());
        Observer.Expect('open new error', 'Sorry, the current permissions prevented the action. (Page 86704 LT QG NoSource Card Insert: AL Language Coverage Tests)');
        Observer.Expect('open new error code', 'DB:ClientInsertDenied');
        Observer.Expect('log after open new', 'qg open;');
        Observer.Verify();
    end;

    [Test]
    procedure QG_NoSource_SetValue_ThenAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P146 Page Log";
        P: TestPage "LT QG NoSource Card";
    begin
        Log.Clear();
        P.OpenEdit();
        Log.Clear();
        P.Txt.SetValue('typed');
        Observer.Observe('log after setvalue', Log.GetEntries());
        Log.Clear();
        P.Noop.Invoke();
        Observer.Observe('log after noop', Log.GetEntries());
        Observer.Observe('txt', P.Txt.Value());
        Log.Clear();
        P.Close();
        Observer.Observe('log after close', Log.GetEntries());
        Observer.Expect('log after setvalue', 'qg validate=typed;');
        Observer.Expect('log after noop', 'qg action;qg agcr;');
        Observer.Expect('txt', 'typed');
        Observer.Expect('log after close', 'qg close;');
        Observer.Verify();
    end;

    // Writer QZ: SetValue on controls bound to a procedure call, an arithmetic expression and a text function on a page without a source table
    // (fixture page 87695 in QzExprControlNoSource.al).
    [Test]
    procedure QZ_NoSourceTable_SetValue_OnExpressionControls()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QZ Expr NoSource";
    begin
        P.OpenEdit();
        Observer.Observe('values', P.Total.Value() + '|' + P.SumCtl.Value() + '|' + P.UpperCtl.Value() + '|' + P.Plain.Value());
        Observer.Observe('editable', Format(P.Total.Editable()) + '|' + Format(P.SumCtl.Editable()) + '|' + Format(P.UpperCtl.Editable()) + '|' + Format(P.Plain.Editable()));
        ClearLastError();
        asserterror begin
            P.Total.SetValue('5');
            Error('no error');
        end;
        Observer.ObserveError('total');
        Observer.Observe('total after', P.Total.Value());
        asserterror begin
            P.SumCtl.SetValue('9');
            Error('no error');
        end;
        Observer.ObserveError('sum');
        Observer.Observe('sum after', P.SumCtl.Value());
        asserterror begin
            P.UpperCtl.SetValue('xyz');
            Error('no error');
        end;
        Observer.ObserveError('upper');
        Observer.Observe('upper after', P.UpperCtl.Value());
        P.Plain.SetValue('def');
        Observer.Observe('after plain', P.UpperCtl.Value() + '|' + P.Plain.Value());
        P.Close();
        Observer.Expect('values', '42.00|5|ABC|abc');
        Observer.Expect('editable', 'No|No|No|Yes');
        Observer.Expect('total|text', 'no error');
        Observer.Expect('total|code', 'Dialog');
        Observer.Expect('total after', '42.00');
        Observer.Expect('sum|text', 'no error');
        Observer.Expect('sum|code', 'Dialog');
        Observer.Expect('sum after', '5');
        Observer.Expect('upper|text', 'no error');
        Observer.Expect('upper|code', 'Dialog');
        Observer.Expect('upper after', 'ABC');
        Observer.Expect('after plain', 'DEF|def');
        Observer.Verify();
    end;
}

page 86704 "LT QG NoSource Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Txt; TxtVar)
            {
                ApplicationArea = All;
                trigger OnValidate()
                var
                    Log: Codeunit "LT P146 Page Log";
                begin
                    Log.Add('qg validate=' + TxtVar);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Noop)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P146 Page Log";
                begin
                    Log.Add('qg action');
                end;
            }
            action(UpdFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P146 Page Log";
                begin
                    Log.Add('qg update');
                    CurrPage.Update(false);
                    Log.Add('qg update done');
                end;
            }
        }
    }

    var
        TxtVar: Text;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P146 Page Log";
    begin
        TxtVar := 'start';
        Log.Add('qg open');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P146 Page Log";
    begin
        Log.Add('qg agr');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P146 Page Log";
    begin
        Log.Add('qg agcr');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT P146 Page Log";
    begin
        Log.Add('qg new');
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT P146 Page Log";
    begin
        Log.Add('qg close');
    end;
}
