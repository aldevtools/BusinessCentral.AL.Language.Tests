// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 74288, codeunits 74289 (holder), 74291 (tests), xmlport 74290, codeunits 74294-74299 (publisher, manual subscriber, interface implementation, tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles (issue 135, reasons 20-21): "SessionInformation.Callstack with a frame whose format is not pinned (... or an object type not measured)".
// Facts: the frames (split at the backslash, from the reading procedure out to the test codeunit) of SessionInformation.Callstack read inside an xmlport table element OnAfterGetRecord and a field element OnBeforePassField, a subscriber bound manually (BindSubscription) to a codeunit integration event, a procedure called through an interface variable, and a [TryFunction].
// BC versions: 29 (27 and 28 by CI)

table 74288 "LT P135 CS Xml Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74289 "LT P135 CS Xml Holder"
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

xmlport 74290 "LT P135 CS Xmlport"
{
    Direction = Export;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT P135 CS Xml Row")
            {
                fieldelement(Id; Row.Id)
                {
                    trigger OnBeforePassField()
                    var
                        Holder: Codeunit "LT P135 CS Xml Holder";
                    begin
                        Holder.Put('xmlport.fieldelement.onbeforepassfield', SessionInformation.Callstack);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    Holder: Codeunit "LT P135 CS Xml Holder";
                begin
                    Holder.Put('xmlport.tableelement.onaftergetrecord', SessionInformation.Callstack);
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    var
        Holder: Codeunit "LT P135 CS Xml Holder";
    begin
        Holder.Put('xmlport.onpostxmlport', SessionInformation.Callstack);
    end;
}

interface "LT P135 CS Iface"
{
    procedure Probe();
}

codeunit 74294 "LT P135 CS Impl" implements "LT P135 CS Iface"
{
    procedure Probe()
    var
        Holder: Codeunit "LT P135 CS Xml Holder";
    begin
        Holder.Put('interface.implementation', SessionInformation.Callstack);
    end;
}

codeunit 74295 "LT P135 CS Publisher"
{
    procedure Raise()
    begin
        OnProbe();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProbe()
    begin
    end;
}

codeunit 74296 "LT P135 CS Manual Sub"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT P135 CS Publisher", 'OnProbe', '', false, false)]
    local procedure OnProbeManual()
    var
        Holder: Codeunit "LT P135 CS Xml Holder";
    begin
        Holder.Put('manual.subscriber', SessionInformation.Callstack);
    end;
}

codeunit 74297 "LT P135 CS Static Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT P135 CS Publisher", 'OnProbe', '', false, false)]
    local procedure OnProbeStatic()
    var
        Holder: Codeunit "LT P135 CS Xml Holder";
    begin
        Holder.Put('static.subscriber', SessionInformation.Callstack);
    end;
}

codeunit 74291 "LT P135 CS Tests Xml"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRead()
    var
        Holder: Codeunit "LT P135 CS Xml Holder";
    begin
        Holder.Put('tryfunction', SessionInformation.Callstack);
    end;

    [Test]
    procedure P135_Callstack_XmlportElements()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Xml Holder";
        Row: Record "LT P135 CS Xml Row";
        OutStr: OutStream;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Holder.ResetSeen();
        Row.Data.CreateOutStream(OutStr);
        Xmlport.Export(Xmlport::"LT P135 CS Xmlport", OutStr);
        Observer.Observe('tableelement onaftergetrecord', Holder.Get('xmlport.tableelement.onaftergetrecord'));
        Observer.Observe('fieldelement onbeforepassfield', Holder.Get('xmlport.fieldelement.onbeforepassfield'));
        Observer.Observe('onpostxmlport', Holder.Get('xmlport.onpostxmlport'));
        Observer.Expect('tableelement onaftergetrecord', '["LT P135 CS Xmlport"(XmlPort 74290)."Row - OnAfterGetRecord"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('fieldelement onbeforepassfield', '["LT P135 CS Xmlport"(XmlPort 74290)."Id - OnBeforePassField"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('onpostxmlport', '["LT P135 CS Xmlport"(XmlPort 74290).OnPostXmlPort(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Callstack_ManualAndStaticSubscribers()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Xml Holder";
        Publisher: Codeunit "LT P135 CS Publisher";
        Manual: Codeunit "LT P135 CS Manual Sub";
    begin
        Holder.ResetSeen();
        Publisher.Raise();
        Observer.Observe('static before bind', Holder.Get('static.subscriber'));
        Observer.Observe('manual before bind', Holder.Get('manual.subscriber'));
        BindSubscription(Manual);
        Publisher.Raise();
        Observer.Observe('static after bind', Holder.Get('static.subscriber'));
        Observer.Observe('manual after bind', Holder.Get('manual.subscriber'));
        UnbindSubscription(Manual);
        Observer.Expect('static before bind', '["LT P135 CS Static Sub"(CodeUnit 74297).OnProbeStatic line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('manual before bind', '<not set>');
        Observer.Expect('static after bind', '["LT P135 CS Static Sub"(CodeUnit 74297).OnProbeStatic line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('manual after bind', '["LT P135 CS Manual Sub"(CodeUnit 74296).OnProbeManual line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Callstack_InterfaceAndTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Xml Holder";
        Impl: Codeunit "LT P135 CS Impl";
        Iface: Interface "LT P135 CS Iface";
        Ok: Boolean;
    begin
        Holder.ResetSeen();
        Iface := Impl;
        Iface.Probe();
        Observer.Observe('interface implementation', Holder.Get('interface.implementation'));
        Ok := TryRead();
        Observer.Observe('tryfunction result', Format(Ok));
        Observer.Observe('tryfunction', Holder.Get('tryfunction'));
        Observer.Expect('interface implementation', '["LT P135 CS Impl"(CodeUnit 74294).Probe line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('tryfunction result', 'Yes');
        Observer.Expect('tryfunction', '<test reached>');
        Observer.Verify();
    end;
}
