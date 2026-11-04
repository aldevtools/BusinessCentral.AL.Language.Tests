// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 74282, codeunits 74283 (holder), 74285 (subscribers), 74286 (tests), page 74284
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: the subscribers of the platform page events OnOpenPageEvent, OnAfterGetRecordEvent and OnAfterGetCurrRecordEvent may not compile; if so drop codeunit 74285 and the tests that read them.
// Settles (issue 135, reasons 20-21): "SessionInformation.Callstack with a frame whose format is not pinned (an event of a table, page or the platform, ...)".
// Facts: the frames (split at the backslash, from the reading procedure out to the test codeunit) of SessionInformation.Callstack read inside page triggers (OnInit, OnAfterGetRecord, OnAfterGetCurrRecord, OnNewRecord, OnQueryClosePage, OnClosePage), a field OnLookup, OnAssistEdit and OnDrillDown trigger, and the subscribers of the platform page events and of an integration event the page raises.
// BC versions: 29 (27 and 28 by CI)

table 74282 "LT P135 CS Page Row"
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

codeunit 74283 "LT P135 CS Page Holder"
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
                if Frames.Get(i).Contains('LT P135 CS Tests') then begin
                    Stop := true;
                    Result += '<test reached>';
                end else
                    Result += '[' + Frames.Get(i) + ']';
        Seen.Set(KeyName, Result);
    end;

    procedure Get(KeyName: Text): Text
    begin
        if Seen.ContainsKey(KeyName) then
            exit(Seen.Get(KeyName));
        exit('<not set>');
    end;
}

page 74284 "LT P135 CS Card"
{
    PageType = Card;
    SourceTable = "LT P135 CS Page Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NameCtl; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnLookup(var Text: Text): Boolean
                var
                    Holder: Codeunit "LT P135 CS Page Holder";
                begin
                    Holder.Put('page.field.onlookup', SessionInformation.Callstack);
                    exit(false);
                end;

                trigger OnAssistEdit()
                var
                    Holder: Codeunit "LT P135 CS Page Holder";
                begin
                    Holder.Put('page.field.onassistedit', SessionInformation.Callstack);
                end;

                trigger OnDrillDown()
                var
                    Holder: Codeunit "LT P135 CS Page Holder";
                begin
                    Holder.Put('page.field.ondrilldown', SessionInformation.Callstack);
                end;
            }
        }
    }

    trigger OnInit()
    var
        Holder: Codeunit "LT P135 CS Page Holder";
    begin
        Holder.Put('page.oninit', SessionInformation.Callstack);
    end;

    trigger OnAfterGetRecord()
    var
        Holder: Codeunit "LT P135 CS Page Holder";
    begin
        Holder.Put('page.aftergetrecord', SessionInformation.Callstack);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Holder: Codeunit "LT P135 CS Page Holder";
    begin
        Holder.Put('page.aftergetcurrrecord', SessionInformation.Callstack);
        OnProbePageEvent();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Holder: Codeunit "LT P135 CS Page Holder";
    begin
        Holder.Put('page.onnewrecord', SessionInformation.Callstack);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Holder: Codeunit "LT P135 CS Page Holder";
    begin
        Holder.Put('page.onqueryclosepage', SessionInformation.Callstack);
        exit(true);
    end;

    trigger OnClosePage()
    var
        Holder: Codeunit "LT P135 CS Page Holder";
    begin
        Holder.Put('page.onclosepage', SessionInformation.Callstack);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProbePageEvent()
    begin
    end;
}

codeunit 74285 "LT P135 CS Page Subscribers"
{
    [EventSubscriber(ObjectType::Page, Page::"LT P135 CS Card", 'OnProbePageEvent', '', false, false)]
    local procedure OnProbePage()
    var
        Holder: Codeunit "LT P135 CS Page Holder";
    begin
        Holder.Put('sub.page.integration', SessionInformation.Callstack);
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P135 CS Card", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvt(var Rec: Record "LT P135 CS Page Row")
    var
        Holder: Codeunit "LT P135 CS Page Holder";
    begin
        Holder.Put('sub.page.onopenpageevent', SessionInformation.Callstack);
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P135 CS Card", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvt(var Rec: Record "LT P135 CS Page Row")
    var
        Holder: Codeunit "LT P135 CS Page Holder";
    begin
        Holder.Put('sub.page.aftergetrecordevent', SessionInformation.Callstack);
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P135 CS Card", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvt(var Rec: Record "LT P135 CS Page Row")
    var
        Holder: Codeunit "LT P135 CS Page Holder";
    begin
        Holder.Put('sub.page.aftergetcurrrecordevent', SessionInformation.Callstack);
    end;
}

codeunit 74286 "LT P135 CS Tests Page"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P135 CS Page Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'one';
        R.Insert();
    end;

    [Test]
    procedure P135_Callstack_PageTriggers_OnOpen()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Page Holder";
        Card: TestPage "LT P135 CS Card";
    begin
        Seed();
        Holder.ResetSeen();
        Card.OpenView();
        Observer.Observe('page oninit', Holder.Get('page.oninit'));
        Observer.Observe('page aftergetrecord', Holder.Get('page.aftergetrecord'));
        Observer.Observe('page aftergetcurrrecord', Holder.Get('page.aftergetcurrrecord'));
        Observer.Observe('page integration subscriber', Holder.Get('sub.page.integration'));
        Card.Close();
        Observer.Observe('page onqueryclosepage', Holder.Get('page.onqueryclosepage'));
        Observer.Observe('page onclosepage', Holder.Get('page.onclosepage'));
        Observer.Expect('page oninit', '["LT P135 CS Card"(Page 74284).OnInit(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('page aftergetrecord', '["LT P135 CS Card"(Page 74284).OnAfterGetRecord(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('page aftergetcurrrecord', '["LT P135 CS Card"(Page 74284).OnAfterGetCurrRecord(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('page integration subscriber', '["LT P135 CS Page Subscribers"(CodeUnit 74285).OnProbePage line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('page onqueryclosepage', '["LT P135 CS Card"(Page 74284).OnQueryClosePage(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('page onclosepage', '["LT P135 CS Card"(Page 74284).OnClosePage(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Callstack_PagePlatformEvents()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Page Holder";
        Card: TestPage "LT P135 CS Card";
    begin
        Seed();
        Holder.ResetSeen();
        Card.OpenView();
        Observer.Observe('onopenpageevent subscriber', Holder.Get('sub.page.onopenpageevent'));
        Observer.Observe('aftergetrecordevent subscriber', Holder.Get('sub.page.aftergetrecordevent'));
        Observer.Observe('aftergetcurrrecordevent subscriber', Holder.Get('sub.page.aftergetcurrrecordevent'));
        Card.Close();
        Observer.Expect('onopenpageevent subscriber', '["LT P135 CS Page Subscribers"(CodeUnit 74285).OnOpenPageEvt line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('aftergetrecordevent subscriber', '["LT P135 CS Page Subscribers"(CodeUnit 74285).OnAfterGetRecordEvt line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('aftergetcurrrecordevent subscriber', '["LT P135 CS Page Subscribers"(CodeUnit 74285).OnAfterGetCurrRecordEvt line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Callstack_PageFieldTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Page Holder";
        Card: TestPage "LT P135 CS Card";
    begin
        Seed();
        Holder.ResetSeen();
        Card.OpenEdit();
        Card.NameCtl.Lookup();
        Observer.Observe('field onlookup', Holder.Get('page.field.onlookup'));
        Card.NameCtl.AssistEdit();
        Observer.Observe('field onassistedit', Holder.Get('page.field.onassistedit'));
        Card.NameCtl.Drilldown();
        Observer.Observe('field ondrilldown', Holder.Get('page.field.ondrilldown'));
        Card.Close();
        Observer.Expect('field onlookup', '["LT P135 CS Card"(Page 74284)."NameCtl - OnLookup"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('field onassistedit', '["LT P135 CS Card"(Page 74284)."NameCtl - OnAssistEdit"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('field ondrilldown', '["LT P135 CS Card"(Page 74284)."NameCtl - OnDrillDown"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Callstack_PageNewRecord()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Page Holder";
        Card: TestPage "LT P135 CS Card";
    begin
        Seed();
        Holder.ResetSeen();
        Card.OpenNew();
        Observer.Observe('page onnewrecord', Holder.Get('page.onnewrecord'));
        Card.Close();
        Observer.Expect('page onnewrecord', '["LT P135 CS Card"(Page 74284).OnNewRecord(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;
}
