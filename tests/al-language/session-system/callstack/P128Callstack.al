// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73130, page 73131, codeunits 73132 (holder, SingleInstance, used only by test codeunit 73136), query 73134, xmlport 73135, test codeunit 73136
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read inside a page control's OnLookup, OnDrillDown and OnAssistEdit (the page field OnValidate and the action are pinned elsewhere), inside a
// procedure (not a trigger) of a table, a page, a query and an xmlport, and inside a procedure called through an interface. The frames from the reading procedure out to the
// test procedure (the frame text of the test codeunit is cut), as in misc/lt-probes-needed-4/PnD09_CallstackSources.al.
// BC versions: 29 (27 and 28 by CI)

table 73130 "LT P128 CS Row"
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

    procedure ProbeTable()
    var
        Holder: Codeunit "LT P128 CS Holder";
    begin
        Holder.Put('table.procedure', SessionInformation.Callstack);
    end;
}

codeunit 73132 "LT P128 CS Holder"
{
    SingleInstance = true;

    var
        Seen: Dictionary of [Text, Text];

    procedure ResetSeen()
    begin
        Clear(Seen);
    end;

    procedure Put(KeyName: Text; Stack: Text)
    var
        Frames: List of [Text];
        Result: Text;
        i: Integer;
        Stop: Boolean;
        Frame: Text;
        Pos: Integer;
    begin
        Frames := Stack.Split('\');
        for i := 1 to Frames.Count() do
            if not Stop then begin
                Frame := Frames.Get(i);
                Pos := Frame.IndexOf(' - AL Language Coverage Tests');
                if Pos > 0 then
                    Frame := Frame.Substring(1, Pos - 1);
                if Frame.Contains('LT P128 CS Tests') then begin
                    Stop := true;
                    Result += '<test procedure reached>';
                end else
                    Result += '[' + Frame + ']';
            end;
        if Seen.ContainsKey(KeyName) then
            Seen.Set(KeyName, Result)
        else
            Seen.Add(KeyName, Result);
    end;

    procedure Get(KeyName: Text): Text
    begin
        if Seen.ContainsKey(KeyName) then
            exit(Seen.Get(KeyName));
        exit('<not set>');
    end;
}

page 73131 "LT P128 CS Card"
{
    PageType = Card;
    SourceTable = "LT P128 CS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id)
            {
                ApplicationArea = All;
            }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnLookup(var Text: Text): Boolean
                var
                    Holder: Codeunit "LT P128 CS Holder";
                begin
                    Holder.Put('page.onlookup', SessionInformation.Callstack);
                    exit(false);
                end;

                trigger OnDrillDown()
                var
                    Holder: Codeunit "LT P128 CS Holder";
                begin
                    Holder.Put('page.ondrilldown', SessionInformation.Callstack);
                end;

                trigger OnAssistEdit()
                var
                    Holder: Codeunit "LT P128 CS Holder";
                begin
                    Holder.Put('page.onassistedit', SessionInformation.Callstack);
                end;
            }
        }
    }

    procedure ProbePage()
    var
        Holder: Codeunit "LT P128 CS Holder";
    begin
        Holder.Put('page.procedure', SessionInformation.Callstack);
    end;
}

query 73134 "LT P128 CS Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT P128 CS Row")
        {
            column(Id; Id) { }
        }
    }

    procedure ProbeQuery()
    var
        Holder: Codeunit "LT P128 CS Holder";
    begin
        Holder.Put('query.procedure', SessionInformation.Callstack);
    end;
}

xmlport 73135 "LT P128 CS Xmlport"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT P128 CS Row")
            {
                fieldelement(Id; Row.Id) { }
            }
        }
    }

    procedure ProbeXmlport()
    var
        Holder: Codeunit "LT P128 CS Holder";
    begin
        Holder.Put('xmlport.procedure', SessionInformation.Callstack);
    end;
}

interface "LT P128 CS Probe"
{
    procedure Probe();
}

codeunit 73137 "LT P128 CS Impl" implements "LT P128 CS Probe"
{
    procedure Probe()
    var
        Holder: Codeunit "LT P128 CS Holder";
    begin
        Holder.Put('interface.procedure', SessionInformation.Callstack);
    end;
}

codeunit 73136 "LT P128 CS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedAndReset()
    var
        Row: Record "LT P128 CS Row";
        Holder: Codeunit "LT P128 CS Holder";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'abc';
        Row.Insert();
        Holder.ResetSeen();
    end;

    [Test]
    procedure P128_Callstack_PageControlTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P128 CS Holder";
        Card: TestPage "LT P128 CS Card";
    begin
        SeedAndReset();
        Card.OpenEdit();
        Card.Name.Lookup();
        Card.Name.Drilldown();
        Card.Name.AssistEdit();
        Card.Close();
        Observer.Observe('onlookup', Holder.Get('page.onlookup'));
        Observer.Observe('ondrilldown', Holder.Get('page.ondrilldown'));
        Observer.Observe('onassistedit', Holder.Get('page.onassistedit'));
        Observer.Expect('onlookup', '["LT P128 CS Card"(Page 73131)."Name - OnLookup"(Trigger) line 4]<test procedure reached>');
        Observer.Expect('ondrilldown', '["LT P128 CS Card"(Page 73131)."Name - OnDrillDown"(Trigger) line 4]<test procedure reached>');
        Observer.Expect('onassistedit', '["LT P128 CS Card"(Page 73131)."Name - OnAssistEdit"(Trigger) line 4]<test procedure reached>');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Callstack_TableAndPageProcedures()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P128 CS Holder";
        Row: Record "LT P128 CS Row";
        Card: Page "LT P128 CS Card";
    begin
        SeedAndReset();
        Row.ProbeTable();
        Card.ProbePage();
        Observer.Observe('table procedure', Holder.Get('table.procedure'));
        Observer.Observe('page procedure', Holder.Get('page.procedure'));
        Observer.Expect('table procedure', '["LT P128 CS Row"(Table 73130).ProbeTable line 4]<test procedure reached>');
        Observer.Expect('page procedure', '["LT P128 CS Card"(Page 73131).ProbePage line 4]<test procedure reached>');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Callstack_QueryAndXmlportProcedures()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P128 CS Holder";
        Qry: Query "LT P128 CS Query";
        Xp: XmlPort "LT P128 CS Xmlport";
    begin
        SeedAndReset();
        Qry.ProbeQuery();
        Xp.ProbeXmlport();
        Observer.Observe('query procedure', Holder.Get('query.procedure'));
        Observer.Observe('xmlport procedure', Holder.Get('xmlport.procedure'));
        Observer.Expect('query procedure', '["LT P128 CS Query"(Query 73134).ProbeQuery line 4]<test procedure reached>');
        Observer.Expect('xmlport procedure', '["LT P128 CS Xmlport"(XmlPort 73135).ProbeXmlport line 4]<test procedure reached>');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Callstack_InterfaceProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P128 CS Holder";
        Impl: Codeunit "LT P128 CS Impl";
        Probe: Interface "LT P128 CS Probe";
    begin
        SeedAndReset();
        Probe := Impl;
        Probe.Probe();
        Observer.Observe('interface procedure', Holder.Get('interface.procedure'));
        Observer.Expect('interface procedure', '["LT P128 CS Impl"(CodeUnit 73137).Probe line 4]<test procedure reached>');
        Observer.Verify();
    end;
}
