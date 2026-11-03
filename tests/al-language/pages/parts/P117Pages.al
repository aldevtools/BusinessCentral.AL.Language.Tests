// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: Probe Observer (codeunit 69160); own objects 70792-70798 in this file; log 70793 is SingleInstance and used only by test codeunits 70797/70798
// Facts: Pending obsolete page fields and actions (ObsoleteState/Reason/Tag) still show and run through TestPage; AdditionalSearchTerms on pages has no observable effect (declared)

table 70792 "LT P117 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; OldName; Text[30])
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Use Name instead';
            ObsoleteTag = '29.0';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70793 "LT P117 Log"
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

page 70795 "LT P117 Card"
{
    PageType = Card;
    SourceTable = "LT P117 Row";
    ApplicationArea = All;
    UsageCategory = None;
    AdditionalSearchTerms = 'probe,obsolete,search';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(OldNameF; Rec.OldName)
                {
                    ApplicationArea = All;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Use Name instead';
                    ObsoleteTag = '29.0';
                }
                field(OldInvisible; Rec.OldName)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Hidden and obsolete';
                }
                field(OldNoTag; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Read-only and obsolete';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CurrentAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    L.Add('current');
                end;
            }
            action(ObsAct)
            {
                ApplicationArea = All;
                ObsoleteState = Pending;
                ObsoleteReason = 'Use CurrentAct instead';
                ObsoleteTag = '29.0';
                trigger OnAction()
                begin
                    L.Add('obsolete action id=' + Format(Rec.Id));
                end;
            }
            action(ObsActNoTag)
            {
                ApplicationArea = All;
                ObsoleteState = Pending;
                ObsoleteReason = 'No tag';
                trigger OnAction()
                begin
                    L.Add('obsolete notag');
                end;
            }
            action(ObsActDisabled)
            {
                ApplicationArea = All;
                Enabled = false;
                Visible = true;
                ObsoleteState = Pending;
                ObsoleteReason = 'Disabled and obsolete';
                trigger OnAction()
                begin
                    L.Add('obsolete disabled');
                end;
            }
            action(ObsActHidden)
            {
                ApplicationArea = All;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Hidden and obsolete';
                trigger OnAction()
                begin
                    L.Add('obsolete hidden');
                end;
            }
        }
        area(Promoted)
        {
            actionref(CurrentRef; CurrentAct) { }
            actionref(ObsRef; ObsAct)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Promoted ref is obsolete';
                ObsoleteTag = '29.0';
            }
        }
    }

    var
        L: Codeunit "LT P117 Log";
}

page 70796 "LT P117 List"
{
    PageType = List;
    SourceTable = "LT P117 Row";
    ApplicationArea = All;
    UsageCategory = Lists;
    AdditionalSearchTerms = 'alpha beta,gamma';
    CardPageId = "LT P117 Card";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(OldNameF; Rec.OldName)
                {
                    ApplicationArea = All;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Use Name instead';
                    ObsoleteTag = '29.0';
                }
            }
        }
    }
}

codeunit 70797 "LT P117 Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P117 Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'one';
        Row.OldName := 'old one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.OldName := 'old two';
        Row.Insert();
    end;

    [Test]
    procedure P117_ObsoleteField_StateAndValue()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P117 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey(1);
        Observer.Observe('name value', Card.Name.Value);
        Observer.Observe('obs visible', Format(Card.OldNameF.Visible()));
        Observer.Observe('obs enabled', Format(Card.OldNameF.Enabled()));
        Observer.Observe('obs editable', Format(Card.OldNameF.Editable()));
        Observer.Observe('obs value', Card.OldNameF.Value);
        asserterror Observer.Observe('hidden visible', Format(Card.OldInvisible.Visible()));
        Observer.ObserveError('af230');
        asserterror Observer.Observe('hidden value', Card.OldInvisible.Value);
        Observer.ObserveError('af232');
        Observer.Observe('readonly visible', Format(Card.OldNoTag.Visible()));
        Observer.Observe('readonly editable', Format(Card.OldNoTag.Editable()));
        Observer.Observe('readonly value', Card.OldNoTag.Value);
        Card.Close();
        Observer.Expect('name value', 'one');
        Observer.Expect('obs visible', 'Yes');
        Observer.Expect('obs enabled', 'Yes');
        Observer.Expect('obs editable', 'Yes');
        Observer.Expect('obs value', 'old one');
        Observer.Expect('af230|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af230|code', 'TestFieldNotFound');
        Observer.Expect('af232|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af232|code', 'TestFieldNotFound');
        Observer.Expect('readonly visible', 'Yes');
        Observer.Expect('readonly editable', 'No');
        Observer.Expect('readonly value', 'one');
        Observer.Verify();
    end;

    [Test]
    procedure P117_ObsoleteField_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P117 Row";
        Card: TestPage "LT P117 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey(1);
        Card.OldNameF.SetValue('changed');
        Observer.Observe('after setvalue page', Card.OldNameF.Value);
        Card.Close();
        Row.Get(1);
        Observer.Observe('after setvalue table', Row.OldName);
        Card.OpenEdit();
        Card.GoToKey(2);
        Card.OldNoTag.SetValue('x');
        Observer.Observe('setvalue readonly obsolete', 'no error');
        Card.Close();
        Observer.Expect('after setvalue page', 'changed');
        Observer.Expect('after setvalue table', 'changed');
        Observer.Expect('setvalue readonly obsolete', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure P117_ObsoleteAction_State()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P117 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey(1);
        Observer.Observe('current visible', Format(Card.CurrentAct.Visible()));
        Observer.Observe('current enabled', Format(Card.CurrentAct.Enabled()));
        Observer.Observe('obs visible', Format(Card.ObsAct.Visible()));
        Observer.Observe('obs enabled', Format(Card.ObsAct.Enabled()));
        Observer.Observe('notag visible', Format(Card.ObsActNoTag.Visible()));
        Observer.Observe('notag enabled', Format(Card.ObsActNoTag.Enabled()));
        Observer.Observe('disabled visible', Format(Card.ObsActDisabled.Visible()));
        Observer.Observe('disabled enabled', Format(Card.ObsActDisabled.Enabled()));
        Observer.Observe('hidden visible', Format(Card.ObsActHidden.Visible()));
        Observer.Observe('hidden enabled', Format(Card.ObsActHidden.Enabled()));
        Card.Close();
        Observer.Expect('current visible', 'Yes');
        Observer.Expect('current enabled', 'Yes');
        Observer.Expect('obs visible', 'Yes');
        Observer.Expect('obs enabled', 'Yes');
        Observer.Expect('notag visible', 'Yes');
        Observer.Expect('notag enabled', 'Yes');
        Observer.Expect('disabled visible', 'Yes');
        Observer.Expect('disabled enabled', 'No');
        Observer.Expect('hidden visible', 'No');
        Observer.Expect('hidden enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P117_ObsoleteAction_Invoke()
    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT P117 Log";
        Card: TestPage "LT P117 Card";
    begin
        Seed();
        L.Take();
        Card.OpenView();
        Card.GoToKey(2);
        Card.CurrentAct.Invoke();
        Observer.Observe('after current', L.Take());
        Card.ObsAct.Invoke();
        Observer.Observe('after obsolete', L.Take());
        Card.ObsActNoTag.Invoke();
        Observer.Observe('after notag', L.Take());
        Card.ObsActDisabled.Invoke();
        Observer.Observe('invoke disabled obsolete', 'no error');
        Observer.Observe('log after disabled', L.Take());
        Card.Close();
        Observer.Expect('after current', 'current;');
        Observer.Expect('after obsolete', 'obsolete action id=2;');
        Observer.Expect('after notag', 'obsolete notag;');
        Observer.Expect('invoke disabled obsolete', 'no error');
        Observer.Expect('log after disabled', '');
        Observer.Verify();
    end;

    [Test]
    procedure P117_ObsoleteAction_InvokeHidden()
    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT P117 Log";
        Card: TestPage "LT P117 Card";
    begin
        Seed();
        L.Take();
        Card.OpenView();
        Card.GoToKey(1);
        Card.ObsActHidden.Invoke();
        Observer.Observe('invoke hidden obsolete', 'no error');
        Observer.Observe('log after hidden', L.Take());
        Card.Close();
        Observer.Expect('invoke hidden obsolete', 'no error');
        Observer.Expect('log after hidden', 'obsolete hidden;');
        Observer.Verify();
    end;

    [Test]
    procedure P117_ObsoleteField_InListPage()
    var
        Observer: Codeunit "Probe Observer";
        ListPg: TestPage "LT P117 List";
    begin
        Seed();
        ListPg.OpenEdit();
        ListPg.First();
        Observer.Observe('row 1 id', ListPg.Id.Value);
        Observer.Observe('row 1 obs value', ListPg.OldNameF.Value);
        Observer.Observe('obs visible', Format(ListPg.OldNameF.Visible()));
        Observer.Observe('obs editable', Format(ListPg.OldNameF.Editable()));
        ListPg.Next();
        Observer.Observe('row 2 obs value', ListPg.OldNameF.Value);
        ListPg.OldNameF.SetValue('list changed');
        Observer.Observe('row 2 after setvalue', ListPg.OldNameF.Value);
        Observer.Observe('has next', Format(ListPg.Next()));
        ListPg.Close();
        Observer.Expect('row 1 id', '1');
        Observer.Expect('row 1 obs value', 'old one');
        Observer.Expect('obs visible', 'Yes');
        Observer.Expect('obs editable', 'Yes');
        Observer.Expect('row 2 obs value', 'old two');
        Observer.Expect('row 2 after setvalue', 'list changed');
        Observer.Expect('has next', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P117_ObsoleteField_FilterAndOpen()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P117 Row";
        Card: TestPage "LT P117 Card";
    begin
        Seed();
        Row.SetRange(Id, 2);
        Row.SetFilter(OldName, 'old *');
        Observer.Observe('row count obsolete field filter', Format(Row.Count()));
        Card.Trap();
        Page.Run(Page::"LT P117 Card", Row);
        Observer.Observe('trapped id', Card.Id.Value);
        Observer.Observe('trapped obs', Card.OldNameF.Value);
        Card.Close();
        Observer.Expect('row count obsolete field filter', '1');
        Observer.Expect('trapped id', '2');
        Observer.Expect('trapped obs', 'old two');
        Observer.Verify();
    end;
}

codeunit 70798 "LT P117 Search Terms Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P117_AdditionalSearchTerms_PageOpens()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P117 Row";
        Card: TestPage "LT P117 Card";
        ListPg: TestPage "LT P117 List";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'alpha beta';
        Row.Insert();
        // AdditionalSearchTerms is declared on both pages; the only observable thing is that they open and show data as usual
        ListPg.OpenView();
        ListPg.First();
        Observer.Observe('list name', ListPg.Name.Value);
        Observer.Observe('list caption', ListPg.Caption());
        ListPg.Close();
        Card.OpenView();
        Card.First();
        Observer.Observe('card name', Card.Name.Value);
        Observer.Observe('card caption', Card.Caption());
        Card.Close();
        // a text search over the data with the wildcard filter
        Row.SetFilter(Name, '@*ALPHA*');
        Observer.Observe('wildcard count', Format(Row.Count()));
        Row.SetFilter(Name, '@*search*');
        Observer.Observe('search term as value count', Format(Row.Count()));
        Row.Reset();
        Row.DeleteAll();
        Observer.Expect('list name', 'alpha beta');
        Observer.Expect('list caption', 'LT P117 List');
        Observer.Expect('card name', 'alpha beta');
        Observer.Expect('card caption', 'LT P117 Card - 1');
        Observer.Expect('wildcard count', '1');
        Observer.Expect('search term as value count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P117_PageMetadata_ViaRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P117 Row";
        RecRef: RecordRef;
        FRef: FieldRef;
    begin
        Row.DeleteAll();
        RecRef.Open(Database::"LT P117 Row");
        FRef := RecRef.Field(3);
        Observer.Observe('obsolete field name', FRef.Name());
        Observer.Observe('obsolete field type', Format(FRef.Type()));
        Observer.Observe('obsolete field length', Format(FRef.Length()));
        Observer.Observe('obsolete field active', Format(FRef.Active()));
        Observer.Observe('obsolete field class', Format(FRef.Class()));
        Observer.Observe('field count', Format(RecRef.FieldCount()));
        Observer.Expect('obsolete field name', 'OldName');
        Observer.Expect('obsolete field type', 'Text');
        Observer.Expect('obsolete field length', '30');
        Observer.Expect('obsolete field active', 'Yes');
        Observer.Expect('obsolete field class', 'Normal');
        Observer.Expect('field count', '3');
        Observer.Verify();
    end;
}
