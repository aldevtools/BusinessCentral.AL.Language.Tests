// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 91363, page 91364, SingleInstance log 91365 (used only by test codeunit 91366)
// Probe: observe probe (writer Y7, 2026-10-30, asked by an al-runtime-rs runtime agent); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: a list page opened with Page.RunModal (in lookup mode and not) is handled by a ModalPageHandler that calls GoToKey, then the typed reads AsDate,
//   AsDecimal, AsTime, AsDateTime (shown as Format(..., 0, 9)) and ShowMandatory of a field with and without ShowMandatory, then OK. Observed: the values,
//   the triggers the page ran (R:<code> = OnAfterGetRecord, C:<code> = OnAfterGetCurrRecord) between the steps, the RunModal action and the record GetRecord
//   returns. pages/lt-ai-list-order/QgGoToKeyNextCall.al pins GoToKey then .Value on a page opened with OpenEdit.
// BC versions: 27, 28, 29

table 91363 "LT Y7 Lookup Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Due Date"; Date) { }
        field(3; Amount; Decimal) { }
        field(4; "Start Time"; Time) { }
        field(5; Stamp; DateTime) { }
        field(6; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 91364 "LT Y7 Lookup List"
{
    PageType = List;
    SourceTable = "LT Y7 Lookup Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { }
                field("Due Date"; Rec."Due Date") { }
                field(Amount; Rec.Amount) { }
                field("Start Time"; Rec."Start Time") { }
                field(Stamp; Rec.Stamp) { }
                field(Name; Rec.Name) { ShowMandatory = true; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Code");
    end;

    var
        Log: Codeunit "LT Y7 Lookup Log";
}

codeunit 91365 "LT Y7 Lookup Log"
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

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;
}

codeunit 91366 "LT Y7 Lookup Typed Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y7 Lookup Log";
        Seen: Text;

    local procedure Setup()
    var
        Row: Record "LT Y7 Lookup Row";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row."Due Date" := 20240110D;
        Row.Amount := 1.5;
        Row."Start Time" := 081500T;
        Row.Stamp := CreateDateTime(20240110D, 081500T);
        Row.Name := 'first';
        Row.Insert();
        Row."Code" := 'B';
        Row."Due Date" := 20240315D;
        Row.Amount := 1234.567;
        Row."Start Time" := 103045T;
        Row.Stamp := CreateDateTime(20240315D, 103045T);
        Row.Name := '';
        Row.Insert();
        Row."Code" := 'C';
        Row."Due Date" := 20241231D;
        Row.Amount := -2;
        Row."Start Time" := 235959T;
        Row.Stamp := CreateDateTime(20241231D, 120000T);
        Row.Name := 'third';
        Row.Insert();
        Log.Take();
        Seen := '';
    end;

    local procedure See(Name: Text; Value: Text)
    begin
        Seen += Name + '=' + Value + ';';
    end;

    [ModalPageHandler]
    procedure GoToKeyTypedReadsThenOK(var Lookup: TestPage "LT Y7 Lookup List")
    begin
        See('open', Log.Take());
        See('goto', Format(Lookup.GoToKey('B')));
        See('after goto', Log.Take());
        See('AsDate', Format(Lookup."Due Date".AsDate(), 0, 9));
        See('AsDecimal', Format(Lookup.Amount.AsDecimal(), 0, 9));
        See('AsTime', Format(Lookup."Start Time".AsTime(), 0, 9));
        See('AsDateTime', Format(Lookup.Stamp.AsDateTime(), 0, 9));
        See('ShowMandatory Name', Format(Lookup.Name.ShowMandatory()));
        See('ShowMandatory Code', Format(Lookup."Code".ShowMandatory()));
        See('after reads', Log.Take());
        Lookup.OK().Invoke();
        See('after OK', Log.Take());
    end;

    [Test]
    [HandlerFunctions('GoToKeyTypedReadsThenOK')]
    procedure Y7_LookupMode_GoToKey_TypedReads_OK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y7 Lookup Row";
        LookupPage: Page "LT Y7 Lookup List";
        Result: Action;
    begin
        Setup();
        LookupPage.LookupMode(true);
        Result := LookupPage.RunModal();
        Observer.Observe('handler', Seen);
        Observer.Observe('action', Format(Result));
        LookupPage.GetRecord(Row);
        Observer.Observe('GetRecord', Row."Code");
        Observer.Observe('after RunModal', Log.Take());
        Observer.Expect('handler', 'open=R:A,R:B,R:C,R:A,R:A,C:A;goto=Yes;after goto=R:B,R:B,C:B;AsDate=2024-03-15;AsDecimal=1234.567;AsTime=10:30:45;AsDateTime=2024-03-15T10:30:45Z;ShowMandatory Name=Yes;ShowMandatory Code=No;after reads=;after OK=;');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('GetRecord', 'B');
        Observer.Expect('after RunModal', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GoToKeyTypedReadsThenOK')]
    procedure Y7_NotLookupMode_GoToKey_TypedReads_OK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y7 Lookup Row";
        LookupPage: Page "LT Y7 Lookup List";
        Result: Action;
    begin
        Setup();
        Result := LookupPage.RunModal();
        Observer.Observe('handler', Seen);
        Observer.Observe('action', Format(Result));
        LookupPage.GetRecord(Row);
        Observer.Observe('GetRecord', Row."Code");
        Observer.Observe('after RunModal', Log.Take());
        Observer.Expect('handler', 'open=R:A,R:B,R:C,R:A,R:A,C:A;goto=Yes;after goto=R:B,R:B,C:B;AsDate=2024-03-15;AsDecimal=1234.567;AsTime=10:30:45;AsDateTime=2024-03-15T10:30:45Z;ShowMandatory Name=Yes;ShowMandatory Code=No;after reads=;after OK=;');
        Observer.Expect('action', 'OK');
        Observer.Expect('GetRecord', 'B');
        Observer.Expect('after RunModal', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GoToKeyTypedReadsThenOK')]
    procedure Y7_PageRunModalRecord_GoToKey_TypedReads_OK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y7 Lookup Row";
        Result: Action;
    begin
        Setup();
        Row.Get('A');
        Result := Page.RunModal(Page::"LT Y7 Lookup List", Row);
        Observer.Observe('handler', Seen);
        Observer.Observe('action', Format(Result));
        Observer.Observe('record after', Row."Code");
        Observer.Observe('after RunModal', Log.Take());
        Observer.Expect('handler', 'open=R:A,R:B,R:C,R:A,R:A,C:A;goto=Yes;after goto=R:B,R:B,C:B;AsDate=2024-03-15;AsDecimal=1234.567;AsTime=10:30:45;AsDateTime=2024-03-15T10:30:45Z;ShowMandatory Name=Yes;ShowMandatory Code=No;after reads=;after OK=;');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('record after', 'B');
        Observer.Expect('after RunModal', '');
        Observer.Verify();
    end;
}
