// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: Probe Observer (codeunit 69160); own objects 70821-70826; RISKY: TestPart state accessors (Visible/Enabled/Editable on a part)
// Facts: Pending obsolete page part: still shown, subpage fields readable through TestPart, state accessors on the part

table 70821 "LT P117 PartRow"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 70822 "LT P117 SubPage"
{
    PageType = ListPart;
    SourceTable = "LT P117 PartRow";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 70823 "LT P117 Host"
{
    PageType = Card;
    SourceTable = "LT P117 PartRow";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            part(CurrentPart; "LT P117 SubPage")
            {
                ApplicationArea = All;
            }
            part(ObsPart; "LT P117 SubPage")
            {
                ApplicationArea = All;
                ObsoleteState = Pending;
                ObsoleteReason = 'Use CurrentPart';
                ObsoleteTag = '29.0';
            }
            part(ObsPartNoTag; "LT P117 SubPage")
            {
                ApplicationArea = All;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Hidden and obsolete';
            }
        }
    }
}

codeunit 70824 "LT P117 Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P117 PartRow";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
    end;

    [Test]
    procedure P117_ObsoletePart_Content()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT P117 Host";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey(1);
        Observer.Observe('host id', Host.Id.Value);
        Observer.Observe('current first id', Host.CurrentPart.Id.Value);
        Observer.Observe('obsolete first id', Host.ObsPart.Id.Value);
        Observer.Observe('obsolete first name', Host.ObsPart.Name.Value);
        Observer.Observe('obsolete next', Format(Host.ObsPart.Next()));
        Observer.Observe('obsolete second name', Host.ObsPart.Name.Value);
        Observer.Observe('obsolete next at end', Format(Host.ObsPart.Next()));
        Observer.Observe('obsolete first again', Format(Host.ObsPart.First()));
        asserterror Observer.Observe('hidden part first id', Host.ObsPartNoTag.Id.Value);
        Observer.ObserveError('af113');
        Host.Close();
        Observer.Expect('host id', '1');
        Observer.Expect('current first id', '1');
        Observer.Expect('obsolete first id', '1');
        Observer.Expect('obsolete first name', 'one');
        Observer.Expect('obsolete next', 'Yes');
        Observer.Expect('obsolete second name', 'two');
        Observer.Expect('obsolete next at end', 'No');
        Observer.Expect('obsolete first again', 'Yes');
        Observer.Expect('af113|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('af113|code', 'TestPartNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P117_ObsoletePart_State()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT P117 Host";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey(1);
        Observer.Observe('current visible', Format(Host.CurrentPart.Visible()));
        Observer.Observe('obsolete visible', Format(Host.ObsPart.Visible()));
        Observer.Observe('obsolete enabled', Format(Host.ObsPart.Enabled()));
        Observer.Observe('obsolete editable', Format(Host.ObsPart.Editable()));
        asserterror Observer.Observe('hidden visible', Format(Host.ObsPartNoTag.Visible()));
        Observer.ObserveError('af132');
        Host.Close();
        Observer.Expect('current visible', 'Yes');
        Observer.Expect('obsolete visible', 'Yes');
        Observer.Expect('obsolete enabled', 'Yes');
        Observer.Expect('obsolete editable', 'No');
        Observer.Expect('af132|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('af132|code', 'TestPartNotFound');
        Observer.Verify();
    end;
}
