// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73140, page 73141, subscriber codeunit 73142, holder 73143 (SingleInstance, used only by test codeunit 73144)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: subscribers to the platform events of a page (OnOpenPageEvent, OnAfterGetRecordEvent, OnBeforeActionEvent, OnAfterActionEvent, OnAfterValidateEvent of a control) are written with the
// parameter lists Microsoft's own code uses; if one does not compile, drop that subscriber.
// Facts: SessionInformation.Callstack read inside a subscriber to a PLATFORM event of a page: the frames from the subscriber out to the test procedure (the test codeunit's frame text is cut).
// BC versions: 29 (27 and 28 by CI)

table 73140 "LT P128 PE Row"
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

codeunit 73143 "LT P128 PE Holder"
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
                if Frame.Contains('LT P128 PE Tests') then begin
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

page 73141 "LT P128 PE Card"
{
    PageType = Card;
    SourceTable = "LT P128 PE Row";
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
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}

codeunit 73142 "LT P128 PE Subs"
{
    [EventSubscriber(ObjectType::Page, Page::"LT P128 PE Card", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageSub()
    var
        Holder: Codeunit "LT P128 PE Holder";
    begin
        Holder.Put('page.onopenpageevent', SessionInformation.Callstack);
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P128 PE Card", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordSub(var Rec: Record "LT P128 PE Row")
    var
        Holder: Codeunit "LT P128 PE Holder";
    begin
        Holder.Put('page.onaftergetrecordevent', SessionInformation.Callstack);
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P128 PE Card", 'OnBeforeActionEvent', 'Act', false, false)]
    local procedure OnBeforeActionSub()
    var
        Holder: Codeunit "LT P128 PE Holder";
    begin
        Holder.Put('page.onbeforeactionevent', SessionInformation.Callstack);
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P128 PE Card", 'OnAfterActionEvent', 'Act', false, false)]
    local procedure OnAfterActionSub()
    var
        Holder: Codeunit "LT P128 PE Holder";
    begin
        Holder.Put('page.onafteractionevent', SessionInformation.Callstack);
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P128 PE Card", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure OnAfterValidateSub(var Rec: Record "LT P128 PE Row"; var xRec: Record "LT P128 PE Row")
    var
        Holder: Codeunit "LT P128 PE Holder";
    begin
        Holder.Put('page.onaftervalidateevent', SessionInformation.Callstack);
    end;
}

codeunit 73144 "LT P128 PE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedAndReset()
    var
        Row: Record "LT P128 PE Row";
        Holder: Codeunit "LT P128 PE Holder";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'abc';
        Row.Insert();
        Holder.ResetSeen();
    end;

    [Test]
    procedure P128_Callstack_PagePlatformEvents()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P128 PE Holder";
        Card: TestPage "LT P128 PE Card";
    begin
        SeedAndReset();
        Card.OpenEdit();
        Card.Name.SetValue('xyz');
        Card.Act.Invoke();
        Card.Close();
        Observer.Observe('onopenpageevent', Holder.Get('page.onopenpageevent'));
        Observer.Observe('onaftergetrecordevent', Holder.Get('page.onaftergetrecordevent'));
        Observer.Observe('onaftervalidateevent', Holder.Get('page.onaftervalidateevent'));
        Observer.Observe('onbeforeactionevent', Holder.Get('page.onbeforeactionevent'));
        Observer.Observe('onafteractionevent', Holder.Get('page.onafteractionevent'));
        Observer.Expect('onopenpageevent', '["LT P128 PE Subs"(CodeUnit 73142).OnOpenPageSub line 4]<test procedure reached>');
        Observer.Expect('onaftergetrecordevent', '["LT P128 PE Subs"(CodeUnit 73142).OnAfterGetRecordSub line 4]<test procedure reached>');
        Observer.Expect('onaftervalidateevent', '["LT P128 PE Subs"(CodeUnit 73142).OnAfterValidateSub line 4]<test procedure reached>');
        Observer.Expect('onbeforeactionevent', '["LT P128 PE Subs"(CodeUnit 73142).OnBeforeActionSub line 4]<test procedure reached>');
        Observer.Expect('onafteractionevent', '["LT P128 PE Subs"(CodeUnit 73142).OnAfterActionSub line 4]<test procedure reached>');
        Observer.Verify();
    end;
}
