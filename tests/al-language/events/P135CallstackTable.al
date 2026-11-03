// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 74275, table extension 74276, codeunits 74277 (holder), 74278 (subscribers), 74279 (tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles (issue 135, reasons 20-21): "SessionInformation.Callstack with a frame whose format is not pinned (an event of a table, page or the platform, or an object type not measured)".
// Facts: the frames (split at the backslash, from the reading procedure out to the test codeunit, the runner's frames not observed) of SessionInformation.Callstack read inside: the subscribers of the table events OnBeforeInsertEvent, OnAfterInsertEvent, OnAfterValidateEvent and of an integration event a table procedure raises; the table's own OnInsert/OnModify triggers; a table extension's field OnValidate and OnInsert; the subscribers reached through Validate on a field of the extension.
// BC versions: 29 (27 and 28 by CI)

table 74275 "LT P135 CS Row"
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

    trigger OnInsert()
    var
        Holder: Codeunit "LT P135 CS Holder";
    begin
        Holder.Put('table.oninsert', SessionInformation.Callstack);
    end;

    trigger OnModify()
    var
        Holder: Codeunit "LT P135 CS Holder";
    begin
        Holder.Put('table.onmodify', SessionInformation.Callstack);
    end;

    procedure RaiseProbe()
    begin
        OnProbeTableEvent();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProbeTableEvent()
    begin
    end;
}

tableextension 74276 "LT P135 CS Row Ext" extends "LT P135 CS Row"
{
    fields
    {
        field(50; Extra; Text[20])
        {
            trigger OnValidate()
            var
                Holder: Codeunit "LT P135 CS Holder";
            begin
                Holder.Put('tableext.field.onvalidate', SessionInformation.Callstack);
            end;
        }
    }

    trigger OnInsert()
    var
        Holder: Codeunit "LT P135 CS Holder";
    begin
        Holder.Put('tableext.oninsert', SessionInformation.Callstack);
    end;
}

codeunit 74277 "LT P135 CS Holder"
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

codeunit 74278 "LT P135 CS Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"LT P135 CS Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsert(var Rec: Record "LT P135 CS Row")
    var
        Holder: Codeunit "LT P135 CS Holder";
    begin
        Holder.Put('sub.table.beforeinsert', SessionInformation.Callstack);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P135 CS Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsert(var Rec: Record "LT P135 CS Row")
    var
        Holder: Codeunit "LT P135 CS Holder";
    begin
        Holder.Put('sub.table.afterinsert', SessionInformation.Callstack);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P135 CS Row", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure OnAfterValidateName(var Rec: Record "LT P135 CS Row")
    var
        Holder: Codeunit "LT P135 CS Holder";
    begin
        Holder.Put('sub.table.aftervalidate', SessionInformation.Callstack);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P135 CS Row", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModify(var Rec: Record "LT P135 CS Row")
    var
        Holder: Codeunit "LT P135 CS Holder";
    begin
        Holder.Put('sub.table.beforemodify', SessionInformation.Callstack);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P135 CS Row", 'OnProbeTableEvent', '', false, false)]
    local procedure OnProbeTable()
    var
        Holder: Codeunit "LT P135 CS Holder";
    begin
        Holder.Put('sub.table.integration', SessionInformation.Callstack);
    end;
}

codeunit 74279 "LT P135 CS Tests Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P135_Callstack_TableInsert_Events()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Holder";
        Row: Record "LT P135 CS Row";
    begin
        Row.DeleteAll();
        Holder.ResetSeen();
        Row.Id := 1;
        Row.Insert(true);
        Observer.Observe('table oninsert', Holder.Get('table.oninsert'));
        Observer.Observe('tableext oninsert', Holder.Get('tableext.oninsert'));
        Observer.Observe('before insert subscriber', Holder.Get('sub.table.beforeinsert'));
        Observer.Observe('after insert subscriber', Holder.Get('sub.table.afterinsert'));
        Observer.Expect('table oninsert', '["LT P135 CS Row"(Table 74275).OnInsert(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('tableext oninsert', '["LT P135 CS Row Ext"(TableExtension 74276).OnInsert(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('before insert subscriber', '["LT P135 CS Subscribers"(CodeUnit 74278).OnBeforeInsert line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('after insert subscriber', '["LT P135 CS Subscribers"(CodeUnit 74278).OnAfterInsert line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Callstack_TableInsert_NoRunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Holder";
        Row: Record "LT P135 CS Row";
    begin
        Row.DeleteAll();
        Holder.ResetSeen();
        Row.Id := 1;
        Row.Insert(false);
        Observer.Observe('table oninsert', Holder.Get('table.oninsert'));
        Observer.Observe('before insert subscriber', Holder.Get('sub.table.beforeinsert'));
        Observer.Observe('after insert subscriber', Holder.Get('sub.table.afterinsert'));
        Observer.Expect('table oninsert', '<not set>');
        Observer.Expect('before insert subscriber', '["LT P135 CS Subscribers"(CodeUnit 74278).OnBeforeInsert line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('after insert subscriber', '["LT P135 CS Subscribers"(CodeUnit 74278).OnAfterInsert line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Callstack_TableModify_AndValidate()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Holder";
        Row: Record "LT P135 CS Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Holder.ResetSeen();
        Row.Validate(Name, 'x');
        Observer.Observe('validate name subscriber', Holder.Get('sub.table.aftervalidate'));
        Row.Modify(true);
        Observer.Observe('table onmodify', Holder.Get('table.onmodify'));
        Observer.Observe('before modify subscriber', Holder.Get('sub.table.beforemodify'));
        Observer.Expect('validate name subscriber', '["LT P135 CS Subscribers"(CodeUnit 74278).OnAfterValidateName line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('table onmodify', '["LT P135 CS Row"(Table 74275).OnModify(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Expect('before modify subscriber', '["LT P135 CS Subscribers"(CodeUnit 74278).OnBeforeModify line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Callstack_TableExtension_FieldValidate()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Holder";
        Row: Record "LT P135 CS Row";
    begin
        Row.DeleteAll();
        Holder.ResetSeen();
        Row.Validate(Extra, 'y');
        Observer.Observe('tableext field onvalidate', Holder.Get('tableext.field.onvalidate'));
        Observer.Expect('tableext field onvalidate', '["LT P135 CS Row Ext"(TableExtension 74276)."Extra - OnValidate"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Callstack_TableIntegrationEvent()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT P135 CS Holder";
        Row: Record "LT P135 CS Row";
    begin
        Holder.ResetSeen();
        Row.RaiseProbe();
        Observer.Observe('table integration event subscriber', Holder.Get('sub.table.integration'));
        Observer.Expect('table integration event subscriber', '["LT P135 CS Subscribers"(CodeUnit 74278).OnProbeTable line 4 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;
}
