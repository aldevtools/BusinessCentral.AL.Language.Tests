// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects table 72046, codeunits 72048 72049 72052, page 72047, query 72050, xmlport 72051
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: SessionInformation.Callstack - Probes wanted: Callstack read from a page field trigger, a page event subscriber, a query and an xmlport
// Facts: the frames (split at the backslash) from the reading procedure out to the test procedure of SessionInformation.Callstack read inside a page field OnValidate, a page OnOpenPage, a subscriber of a page integration event, a query OnBeforeOpen and an xmlport OnPreXmlPort. Only the frames from the reading procedure outward to the object that started the call are observed; the runner frames below the test procedure are not.
// BC versions: 29 (27 and 28 by CI)

table 72046 "LT PnD Cs Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                Holder: Codeunit "LT PnD Cs Holder";
            begin
                Holder.Put('table.validate', SessionInformation.Callstack);
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72048 "LT PnD Cs Holder"
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
    begin
        Frames := Stack.Split('\');
        for i := 1 to Frames.Count() do
            if not Stop then
                if Frames.Get(i).Contains('LT PnD Callstack Sources') then begin
                    Stop := true;
                    Result += '<test procedure reached>';
                end else
                    Result += '[' + Frames.Get(i) + ']';
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

page 72047 "LT PnD Cs Card"
{
    PageType = Card;
    SourceTable = "LT PnD Cs Row";
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

                trigger OnValidate()
                var
                    Holder: Codeunit "LT PnD Cs Holder";
                begin
                    Holder.Put('page.fieldvalidate', SessionInformation.Callstack);
                end;
            }
        }
    }

    [IntegrationEvent(false, false)]
    local procedure OnProbeEvent()
    begin
    end;

    trigger OnOpenPage()
    var
        Holder: Codeunit "LT PnD Cs Holder";
    begin
        Holder.Put('page.onopenpage', SessionInformation.Callstack);
        OnProbeEvent();
    end;
}

codeunit 72049 "LT PnD Cs Subscriber"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PnD Cs Card", 'OnProbeEvent', '', false, false)]
    local procedure OnProbeEventSubscriber()
    var
        Holder: Codeunit "LT PnD Cs Holder";
    begin
        Holder.Put('page.eventsubscriber', SessionInformation.Callstack);
    end;
}

query 72050 "LT PnD Cs Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT PnD Cs Row")
        {
            column(Id; Id) { }
        }
    }

    trigger OnBeforeOpen()
    var
        Holder: Codeunit "LT PnD Cs Holder";
    begin
        Holder.Put('query.onbeforeopen', SessionInformation.Callstack);
    end;
}

xmlport 72051 "LT PnD Cs Xmlport"
{
    Direction = Export;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT PnD Cs Row")
            {
                fieldelement(Id; Row.Id) { }
            }
        }
    }

    trigger OnPreXmlPort()
    var
        Holder: Codeunit "LT PnD Cs Holder";
    begin
        Holder.Put('xmlport.onprexmlport', SessionInformation.Callstack);
    end;
}

codeunit 72052 "LT PnD Callstack Sources"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Callstack_PageFieldTrigger_AndPageOnOpen()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Cs Holder";
        Row: Record "LT PnD Cs Row";
        Card: TestPage "LT PnD Cs Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Holder.ResetSeen();
        Card.OpenEdit();
        Card.Name.SetValue('abc');
        Observer.Observe('onOpenPage', Holder.Get('page.onopenpage'));
        Observer.Observe('pageFieldValidate', Holder.Get('page.fieldvalidate'));
        Observer.Observe('tableFieldValidate', Holder.Get('table.validate'));
        Card.Close();
        Observer.Expect('onOpenPage', '["LT PnD Cs Card"(Page 72047).OnOpenPage(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('pageFieldValidate', '["LT PnD Cs Card"(Page 72047)."Name - OnValidate"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('tableFieldValidate', '["LT PnD Cs Row"(Table 72046)."Name - OnValidate"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure Callstack_PageEventSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Cs Holder";
        Row: Record "LT PnD Cs Row";
        Card: TestPage "LT PnD Cs Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Holder.ResetSeen();
        Card.OpenView();
        Observer.Observe('eventSubscriber', Holder.Get('page.eventsubscriber'));
        Card.Close();
        Observer.Expect('eventSubscriber', '["LT PnD Cs Subscriber"(CodeUnit 72049).OnProbeEventSubscriber line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure Callstack_QueryOnBeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Cs Holder";
        Row: Record "LT PnD Cs Row";
        Q: Query "LT PnD Cs Query";
    begin
        Row.DeleteAll();
        Holder.ResetSeen();
        Q.Open();
        Q.Close();
        Observer.Observe('queryOnBeforeOpen', Holder.Get('query.onbeforeopen'));
        Observer.Expect('queryOnBeforeOpen', '["LT PnD Cs Query"(Query 72050).OnBeforeOpen(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure Callstack_XmlportOnPreXmlPort()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Cs Holder";
        Row: Record "LT PnD Cs Row";
        Blob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Row.DeleteAll();
        Holder.ResetSeen();
        Blob.CreateOutStream(OutStr);
        Xmlport.Export(Xmlport::"LT PnD Cs Xmlport", OutStr);
        Observer.Observe('xmlportOnPre', Holder.Get('xmlport.onprexmlport'));
        Observer.Expect('xmlportOnPre', '["LT PnD Cs Xmlport"(XmlPort 72051).OnPreXmlPort(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;
}
