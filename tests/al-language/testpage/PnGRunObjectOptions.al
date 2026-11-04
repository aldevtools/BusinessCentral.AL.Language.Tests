// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagemode-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG RunObj Host (70162), LT PnG RunObj Host Head (70163), LT PnG Card (70134), LT PnG List (70135), LT PnG View List (70148), LT PnG Run Cu (70167), LT PnG Run Cu Single (70168), LT PnG Item (70130), LT PnG Head (70131), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 88 (RunObject): RunPageMode = Create together with RunPageOnRec/RunPageLink/RunPageView; RunPageOnRec/Link/View on a target that declares SourceTableView; RunPageOnRec from another table; RunObject of a codeunit with RunPageOnRec, a SingleInstance codeunit target
// Facts: what the target page shows (first row, filter, mode) and the log of the target codeunit for each combination of the run properties
// BC versions: 29 (27 and 28 by CI)

codeunit 70188 "LT PnG RunObject Options"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
    begin
        Item.DeleteAll();
        Item."No." := 'RP1';
        Item.Name := 'One';
        Item.Qty := 1;
        Item.Insert();
        Item."No." := 'RP2';
        Item.Name := 'Two';
        Item.Qty := 2;
        Item.Insert();
        Item."No." := 'RP3';
        Item.Name := 'Three';
        Item.Qty := 3;
        Item.Insert();
        Log.Reset();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure CardOnRecAndPlain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey('RP2');
        Host.RunCard.Invoke();
        Observer.Observe('plain', Log.Dump());
        Log.Reset();
        Host.RunCardOnRec.Invoke();
        Observer.Observe('on-rec', Log.Dump());
        Log.Reset();
        Host.RunCardEdit.Invoke();
        Observer.Observe('edit-mode', Log.Dump());
        Log.Reset();
        Host.RunCardViewMode.Invoke();
        Observer.Observe('view-mode', Log.Dump());
        Host.Close();
        Observer.Expect('plain', 'Card.OnInit;Card.OnOpenPage;Card.AGR(RP1,One);Card.AGCR(RP1,One);Card(RP1|One|editable=Yes);Card.OnQueryClosePage;Card.OnClosePage');
        Observer.Expect('on-rec', 'Card.OnInit;Card.OnOpenPage;Card.AGR(RP2,Two);Card.AGCR(RP2,Two);Card(RP2|Two|editable=Yes);Card.OnQueryClosePage;Card.OnClosePage');
        Observer.Expect('edit-mode', 'Card.OnInit;Card.OnOpenPage;Card.AGR(RP1,One);Card.AGCR(RP1,One);Card(RP1|One|editable=Yes);Card.OnQueryClosePage;Card.OnClosePage');
        Observer.Expect('view-mode', 'Card.OnInit;Card.OnOpenPage;Card.AGR(RP1,One);Card.AGCR(RP1,One);Card(RP1|One|editable=No);Card.OnQueryClosePage;Card.OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure CreateModeCombinations()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey('RP2');
        Host.RunCardCreate.Invoke();
        Observer.Observe('create', Log.Dump());
        Log.Reset();
        Host.RunCardCreateOnRec.Invoke();
        Observer.Observe('create-on-rec', Log.Dump());
        Host.Close();
        Observer.Expect('create', 'Card.OnInit;Card.OnOpenPage;Card.OnNewRecord;Card.AGCR(,);Card(||editable=Yes);Card.OnQueryClosePage;Card.OnClosePage');
        Observer.Expect('create-on-rec', 'Card.OnInit;Card.OnOpenPage;Card.OnNewRecord;Card.AGCR(,);Card(||editable=Yes);Card.OnQueryClosePage;Card.OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure CreateModeWithLinkAndView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey('RP2');
        Host.RunCardCreateLink.Invoke();
        Observer.Observe('create-link', Log.Dump());
        Log.Reset();
        Host.RunCardCreateView.Invoke();
        Observer.Observe('create-view', Log.Dump());
        Host.Close();
        Observer.Expect('create-link', 'List.OnInit;List.OnOpenPage;List.OnNewRecord;List.AGCR(RP2,RP2);List()');
        Observer.Expect('create-view', 'List.OnInit;List.OnOpenPage;List.OnNewRecord;List.AGCR(,);List()');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure LinkAndViewOnAList()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey('RP2');
        Host.RunList.Invoke();
        Observer.Observe('plain-list', Log.Dump());
        Log.Reset();
        Host.RunCardLink.Invoke();
        Observer.Observe('link', Log.Dump());
        Log.Reset();
        Host.RunCardView.Invoke();
        Observer.Observe('view', Log.Dump());
        Host.Close();
        Observer.Expect('plain-list', 'List.OnInit;List.OnOpenPage;List.AGR(RP1,One);List.AGR(RP2,Two);List.AGR(RP3,Three);List.AGR(RP1,One);List.AGR(RP1,One);List.AGCR(RP1,);List.AGR(RP2,Two);List.AGR(RP2,Two);List.AGCR(RP2,RP1);List.AGR(RP3,Three);List.AGR(RP3,Three);List.AGCR(RP3,RP2);List.OnNewRecord;List.AGCR(,);List(RP1,RP2,RP3,,)');
        Observer.Expect('link', 'List.OnInit;List.OnOpenPage;List.AGR(RP2,Two);List.AGR(RP2,Two);List.AGCR(RP2,RP2);List.OnNewRecord;List.AGCR(RP2,RP2);List(RP2,RP2,)');
        Observer.Expect('view', 'List.OnInit;List.OnOpenPage;List.AGR(RP2,Two);List.AGR(RP3,Three);List.AGR(RP2,Two);List.AGR(RP2,Two);List.AGCR(RP2,);List.AGR(RP3,Three);List.AGR(RP3,Three);List.AGCR(RP3,RP2);List.OnNewRecord;List.AGCR(,);List(RP2,RP3,,)');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitTargets()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey('RP2');
        Host.RunCuOnRec.Invoke();
        Observer.Observe('cu-on-rec', Log.Dump());
        Log.Reset();
        asserterror begin Host.RunCuPlain.Invoke(); Error('LT-NOERROR'); end;
        Observer.ObserveError('cu-plain');
        Log.Reset();
        asserterror begin Host.RunCuSingleOnRec.Invoke(); Error('LT-NOERROR'); end;
        Observer.ObserveError('cu-single-instance');
        Host.Close();
        Observer.Expect('cu-on-rec', 'RunCu(RP2)');
        Observer.Expect('cu-plain|text', 'LT-NOERROR');
        Observer.Expect('cu-plain|code', 'Dialog');
        Observer.Expect('cu-single-instance|text', 'LT-NOERROR');
        Observer.Expect('cu-single-instance|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure HostRowNotStored()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Host: TestPage "LT PnG RunObj Host";
    begin
        Seed();
        Host.OpenEdit();
        Host.New();
        Host.NoCtl.SetValue('RPNEW');
        asserterror begin Host.RunCardOnRec.Invoke(); Error('LT-NOERROR'); end;
        Observer.ObserveError('card-on-rec-new-row');
        Host.Close();
        Observer.Expect('card-on-rec-new-row|text', 'LT-NOERROR');
        Observer.Expect('card-on-rec-new-row|code', 'Dialog');
        Observer.Verify();
    end;

    [PageHandler]
    procedure CardHandler(var P: TestPage "LT PnG Card")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Card(' + P.NoCtl.Value() + '|' + P.NameCtl.Value() + '|editable=' + Format(P.Editable()) + ')');
    end;

    [PageHandler]
    procedure ListHandler(var P: TestPage "LT PnG List")
    var
        Log: Codeunit "LT PnG Log";
        Rows: Text;
        More: Boolean;
    begin
        More := P.First();
        while More do begin
            Rows += P.NoCtl.Value() + ',';
            More := P.Next();
        end;
        Log.Add('List(' + Rows + ')');
    end;

    [PageHandler]
    procedure ViewListHandler(var P: TestPage "LT PnG View List")
    var
        Log: Codeunit "LT PnG Log";
        Rows: Text;
        More: Boolean;
    begin
        More := P.First();
        while More do begin
            Rows += P.NoCtl.Value() + ',';
            More := P.Next();
        end;
        Log.Add('ViewList(' + Rows + ')');
    end;
}
