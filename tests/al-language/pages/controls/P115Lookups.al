// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-lookuppageid-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P115 Item/Grp/State and LT P115 Grp List (P115Fixtures.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 70211 "LT P115 Lookup Card"
{
    PageType = Card;
    SourceTable = "LT P115 Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoF; Rec."No.") { ApplicationArea = All; }
            field(RelF; Rec.Grp) { ApplicationArea = All; }
            field(PageIdF; Rec.Name)
            {
                ApplicationArea = All;
                LookupPageId = "LT P115 Grp List";
            }
            field(PageIdRelF; Rec.Other)
            {
                ApplicationArea = All;
                LookupPageId = "LT P115 Grp List";
                TableRelation = "LT P115 Grp".Descr;
            }
            field(AssistF; Rec.Note)
            {
                ApplicationArea = All;
                AssistEdit = true;
                trigger OnAssistEdit()
                var
                    State: Codeunit "LT P115 State";
                begin
                    State.Add('assist:' + Rec.Note);
                    Rec.Note := 'assisted';
                end;
            }
            field(AssistPageF; Rec.Qty)
            {
                ApplicationArea = All;
                LookupPageId = "LT P115 Grp List";
                AssistEdit = true;
                trigger OnAssistEdit()
                var
                    State: Codeunit "LT P115 State";
                begin
                    State.Add('assistqty:' + Format(Rec.Qty));
                    Rec.Qty := 99;
                end;
            }
        }
    }
}

codeunit 70212 "LT P115 Lookups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Item: Record "LT P115 Item";
        Grp: Record "LT P115 Grp";
        State: Codeunit "LT P115 State";
    begin
        Item.DeleteAll();
        Grp.DeleteAll();
        State.Take();
        Grp.Code := 'G1';
        Grp.Descr := 'Group one';
        Grp.Insert();
        Grp.Code := 'G2';
        Grp.Descr := 'Group two';
        Grp.Insert();
        Item."No." := 'L1';
        Item.Name := 'Lookup one';
        Item.Grp := 'G1';
        Item.Note := 'orig';
        Item.Qty := 3;
        Item.Insert();
    end;

    [ModalPageHandler]
    procedure PickG2(var P: TestPage "LT P115 Grp List")
    begin
        Observer.Observe('handler-first-code', P.CodeCtl.Value());
        Observer.Observe('handler-editable', Format(P.Editable()));
        P.GoToKey('G2');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelG(var P: TestPage "LT P115 Grp List")
    begin
        Observer.Observe('handler-first-code', P.CodeCtl.Value());
        P.GoToKey('G2');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('PickG2')]
    procedure P115_Lookup_PageIdAndRelation_OK()
    var
        Card: TestPage "LT P115 Lookup Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        Card.PageIdRelF.Lookup();
        Observer.Observe('after', Card.PageIdRelF.Value());
        Card.Close();
        Observer.Expect('handler-first-code', 'G1');
        Observer.Expect('handler-editable', 'No');
        Observer.Expect('after', 'Group two');
        Observer.Verify();
    end;

    [Test]
    procedure P115_AssistEdit_Trigger()
    var
        Card: TestPage "LT P115 Lookup Card";
        Item: Record "LT P115 Item";
        State: Codeunit "LT P115 State";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        Observer.Observe('before', Card.AssistF.Value());
        Card.AssistF.AssistEdit();
        Observer.Observe('after', Card.AssistF.Value());
        Observer.Observe('log', State.Take());
        Card.AssistF.SetValue('typed');
        Card.AssistF.AssistEdit();
        Observer.Observe('after-typed', Card.AssistF.Value());
        Observer.Observe('log-typed', State.Take());
        Card.Close();
        Item.Get('L1');
        Observer.Observe('saved', Item.Note);
        Observer.Expect('before', 'orig');
        Observer.Expect('after', 'assisted');
        Observer.Expect('log', 'assist:orig;');
        Observer.Expect('after-typed', 'assisted');
        Observer.Expect('log-typed', 'assist:typed;');
        Observer.Expect('saved', 'assisted');
        Observer.Verify();
    end;

    [Test]
    procedure P115_AssistEdit_WithLookupPageId()
    var
        Card: TestPage "LT P115 Lookup Card";
        State: Codeunit "LT P115 State";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        Card.AssistPageF.AssistEdit();
        Observer.Observe('after-assist', Card.AssistPageF.Value());
        Observer.Observe('log', State.Take());
        Card.Close();
        Observer.Expect('after-assist', '99');
        Observer.Expect('log', 'assistqty:3;');
        Observer.Verify();
    end;

    [Test]
    procedure P115_AssistEdit_OnFieldsWithoutTrigger()
    var
        Card: TestPage "LT P115 Lookup Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        asserterror Card.PageIdF.AssistEdit();
        Observer.ObserveError('assist-on-lookuppageid-field');
        asserterror Card.RelF.AssistEdit();
        Observer.ObserveError('assist-on-relation-field');
        Card.Close();
        Observer.Expect('assist-on-lookuppageid-field|text', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('assist-on-lookuppageid-field|code', 'MethodNotSupported');
        Observer.Expect('assist-on-relation-field|text', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('assist-on-relation-field|code', 'MethodNotSupported');
        Observer.Verify();
    end;

    [Test]
    procedure P115_Lookup_OnAssistEditField_NoLookupTarget()
    var
        Card: TestPage "LT P115 Lookup Card";
        State: Codeunit "LT P115 State";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        Card.AssistF.Lookup();
        Observer.Observe('lookup-on-assist-field', 'no error');
        Observer.Observe('log', State.Take());
        Observer.Observe('value', Card.AssistF.Value());
        Card.Close();
        Observer.Expect('lookup-on-assist-field', 'no error');
        Observer.Expect('log', '');
        Observer.Expect('value', 'orig');
        Observer.Verify();
    end;
}
