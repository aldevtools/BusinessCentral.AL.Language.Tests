// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 90760-90764
// Probe: written against al-runner issue 6304. pages/lt-ai-list-order/QgGoToKeyNextCall.al pins the sequence GoToKey, field .Value read, action on a list with OnAfterGetRecord
//        and no OnAfterGetCurrRecord. Here the field read is AsBoolean() / AsInteger() / AsDecimal(), and the control property reads Enabled(), Visible(), Editable() and Caption(),
//        then the action. Log: R:<code> = OnAfterGetRecord, A:<name> = the action trigger. Every value asserted below is what the BC service tier produced.
// BC versions: 27, 28, 29

table 90760 "LT WD Module"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Active; Boolean) { }
        field(3; Amount; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 90761 "LT WD Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        if Lines <> '' then
            Lines += ',';
        Lines += Line;
    end;

    procedure Dump(): Text
    begin
        exit(Lines);
    end;

    procedure Reset()
    begin
        Lines := '';
    end;
}

page 90762 "LT WD Modules"
{
    PageType = List;
    SourceTable = "LT WD Module";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { }
                field(Active; Rec.Active) { }
                field(Amount; Rec.Amount) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Activate)
            {
                Enabled = not IsActive;

                trigger OnAction()
                var
                    Log: Codeunit "LT WD Log";
                begin
                    Log.Add('A:' + Rec."Code");
                    Rec.Active := true;
                    Rec.Modify();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT WD Log";
    begin
        Log.Add('R:' + Rec."Code");
        IsActive := Rec.Active;
    end;

    var
        IsActive: Boolean;
}

codeunit 90764 "LT WD GoToKey Typed Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup()
    var
        Module: Record "LT WD Module";
        Log: Codeunit "LT WD Log";
    begin
        Module.DeleteAll();
        Module."Code" := 'A';
        Module.Amount := 1;
        Module.Insert();
        Module."Code" := 'B';
        Module.Amount := 2;
        Module.Insert();
        Log.Reset();
    end;

    [Test]
    procedure WD_GoToKey_AsBoolean_ThenAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WD Log";
        Modules: TestPage "LT WD Modules";
    begin
        Setup();
        Modules.OpenEdit();
        Observer.Observe('open', Log.Dump());
        Observer.Observe('goto', Format(Modules.GoToKey('B')));
        Observer.Observe('after goto', Log.Dump());
        Observer.Observe('active', Format(Modules.Active.AsBoolean()));
        Observer.Observe('after AsBoolean', Log.Dump());
        Modules.Activate.Invoke();
        Observer.Observe('after action', Log.Dump());
        Observer.Observe('active now', Format(Modules.Active.AsBoolean()));
        Modules.Close();
        Observer.Expect('open', 'R:A,R:B,R:A');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after goto', 'R:A,R:B,R:A');
        Observer.Expect('active', 'No');
        Observer.Expect('after AsBoolean', 'R:A,R:B,R:A');
        Observer.Expect('after action', 'R:A,R:B,R:A,R:B,R:B,A:B,R:B,R:B,R:A');
        Observer.Expect('active now', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WD_GoToKey_AsBooleanEnabled_ThenAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WD Log";
        Modules: TestPage "LT WD Modules";
    begin
        Setup();
        Modules.OpenEdit();
        Modules.GoToKey('B');
        Log.Reset();
        Observer.Observe('active', Format(Modules.Active.AsBoolean()));
        Observer.Observe('after AsBoolean', Log.Dump());
        Observer.Observe('enabled', Format(Modules.Activate.Enabled()));
        Observer.Observe('after Enabled', Log.Dump());
        Modules.Activate.Invoke();
        Observer.Observe('after action', Log.Dump());
        Modules.Close();
        Observer.Expect('active', 'No');
        Observer.Expect('after AsBoolean', '');
        Observer.Expect('enabled', 'Yes');
        Observer.Expect('after Enabled', '');
        Observer.Expect('after action', 'R:B,R:B,A:B,R:B,R:B,R:A');
        Observer.Verify();
    end;

    [Test]
    procedure WD_GoToKey_Enabled_ThenAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WD Log";
        Modules: TestPage "LT WD Modules";
    begin
        Setup();
        Modules.OpenEdit();
        Modules.GoToKey('B');
        Log.Reset();
        Observer.Observe('enabled', Format(Modules.Activate.Enabled()));
        Observer.Observe('after Enabled', Log.Dump());
        Modules.Activate.Invoke();
        Observer.Observe('after action', Log.Dump());
        Modules.Close();
        Observer.Expect('enabled', 'Yes');
        Observer.Expect('after Enabled', '');
        Observer.Expect('after action', 'R:B,R:B,A:B,R:B,R:B,R:A');
        Observer.Verify();
    end;

    [Test]
    procedure WD_GoToKey_AsInteger_ThenAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WD Log";
        Modules: TestPage "LT WD Modules";
    begin
        Setup();
        Modules.OpenEdit();
        Modules.GoToKey('B');
        Log.Reset();
        Observer.Observe('amount', Format(Modules.Amount.AsInteger()));
        Observer.Observe('after AsInteger', Log.Dump());
        Modules.Activate.Invoke();
        Observer.Observe('after action', Log.Dump());
        Modules.Close();
        Observer.Expect('amount', '2');
        Observer.Expect('after AsInteger', '');
        Observer.Expect('after action', 'R:B,R:B,A:B,R:B,R:B,R:A');
        Observer.Verify();
    end;

    [Test]
    procedure WD_GoToKey_ControlProperties_ThenAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WD Log";
        Modules: TestPage "LT WD Modules";
    begin
        Setup();
        Modules.OpenEdit();
        Modules.GoToKey('B');
        Log.Reset();
        Observer.Observe('visible', Format(Modules.Active.Visible()));
        Observer.Observe('after Visible', Log.Dump());
        Observer.Observe('editable', Format(Modules.Active.Editable()));
        Observer.Observe('after Editable', Log.Dump());
        Observer.Observe('caption', Modules.Active.Caption());
        Observer.Observe('after Caption', Log.Dump());
        Modules.Activate.Invoke();
        Observer.Observe('after action', Log.Dump());
        Modules.Close();
        Observer.Expect('visible', 'Yes');
        Observer.Expect('after Visible', '');
        Observer.Expect('editable', 'Yes');
        Observer.Expect('after Editable', '');
        Observer.Expect('caption', 'Active');
        Observer.Expect('after Caption', '');
        Observer.Expect('after action', 'R:B,R:B,A:B,R:B,R:B,R:A');
        Observer.Verify();
    end;
}
