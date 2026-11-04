// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained: table 70402, SingleInstance log 70403 (used only by test codeunit 70412), subscriber 70404, page 70402
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: a delete issued from a page action (Rec.Delete(true), Rec.Delete(false), Rec.Delete(), DeleteAll(true/false)) runs the OnBeforeDeleteEvent / OnAfterDeleteEvent subscribers of the page's own table, the table OnDelete trigger; the page OnDeleteRecord trigger

table 70402 "LT P99 Del Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnDelete()
    var
        Log: Codeunit "LT P99 Del Log";
    begin
        Log.Add('table-OnDelete:' + Format(Id));
    end;
}

codeunit 70403 "LT P99 Del Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}

codeunit 70404 "LT P99 Del Subs"
{
    [EventSubscriber(ObjectType::Table, Database::"LT P99 Del Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteRow(var Rec: Record "LT P99 Del Row"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT P99 Del Log";
    begin
        Log.Add('before:' + Format(Rec.Id) + ':trigger=' + Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P99 Del Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteRow(var Rec: Record "LT P99 Del Row"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT P99 Del Log";
    begin
        Log.Add('after:' + Format(Rec.Id) + ':trigger=' + Format(RunTrigger));
    end;
}

page 70402 "LT P99 Del List"
{
    PageType = List;
    SourceTable = "LT P99 Del Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DelTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
            action(DelFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(false);
                end;
            }
            action(DelPlain)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete();
                end;
            }
            action(DelAllTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.DeleteAll(true);
                end;
            }
            action(DelAllFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.DeleteAll(false);
                end;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    var
        Log: Codeunit "LT P99 Del Log";
    begin
        Log.Add('page-OnDeleteRecord:' + Format(Rec.Id));
        exit(true);
    end;
}

codeunit 70412 "LT P99 DeleteEvent"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P99 Del Row";
        Log: Codeunit "LT P99 Del Log";
        I: Integer;
    begin
        Row.DeleteAll(false);
        for I := 1 to 3 do begin
            Row.Id := I;
            Row.Name := 'N' + Format(I);
            Row.Insert();
        end;
        Log.Reset();
    end;

    [Test]
    procedure P99_ActionDeleteTrue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P99 Del Log";
        Row: Record "LT P99 Del Row";
        List: TestPage "LT P99 Del List";
    begin
        Seed();
        List.OpenEdit();
        List.First();
        List.DelTrue.Invoke();
        Observer.Observe('log-count', Format(Log.Count()));
        Observer.Observe('log', Log.Dump());
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Observe('row1-exists', Format(Row.Get(1)));
        List.Close();
        Observer.Expect('log-count', '3');
        Observer.Expect('log', '[before:1:trigger=Yes | table-OnDelete:1 | after:1:trigger=Yes]');
        Observer.Expect('rows', '2');
        Observer.Expect('row1-exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P99_ActionDeleteFalse()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P99 Del Log";
        Row: Record "LT P99 Del Row";
        List: TestPage "LT P99 Del List";
    begin
        Seed();
        List.OpenEdit();
        List.First();
        List.DelFalse.Invoke();
        Observer.Observe('log-count', Format(Log.Count()));
        Observer.Observe('log', Log.Dump());
        Observer.Observe('rows', Format(Row.Count()));
        List.Close();
        Observer.Expect('log-count', '2');
        Observer.Expect('log', '[before:1:trigger=No | after:1:trigger=No]');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P99_ActionDeletePlain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P99 Del Log";
        Row: Record "LT P99 Del Row";
        List: TestPage "LT P99 Del List";
    begin
        Seed();
        List.OpenEdit();
        List.Last();
        List.DelPlain.Invoke();
        Observer.Observe('log-count', Format(Log.Count()));
        Observer.Observe('log', Log.Dump());
        Observer.Observe('rows', Format(Row.Count()));
        List.Close();
        Observer.Expect('log-count', '2');
        Observer.Expect('log', '[before:3:trigger=No | after:3:trigger=No]');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P99_ActionDeleteAll()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P99 Del Log";
        Row: Record "LT P99 Del Row";
        List: TestPage "LT P99 Del List";
    begin
        Seed();
        List.OpenEdit();
        List.DelAllTrue.Invoke();
        Observer.Observe('true-log-count', Format(Log.Count()));
        Observer.Observe('true-log', Log.Dump());
        Observer.Observe('true-rows', Format(Row.Count()));
        List.Close();
        Seed();
        List.OpenEdit();
        List.DelAllFalse.Invoke();
        Observer.Observe('false-log-count', Format(Log.Count()));
        Observer.Observe('false-log', Log.Dump());
        Observer.Observe('false-rows', Format(Row.Count()));
        List.Close();
        Observer.Expect('true-log-count', '9');
        Observer.Expect('true-log', '[before:1:trigger=Yes | table-OnDelete:1 | after:1:trigger=Yes | before:2:trigger=Yes | table-OnDelete:2 | after:2:trigger=Yes | before:3:trigger=Yes | table-OnDelete:3 | after:3:trigger=Yes]');
        Observer.Expect('true-rows', '0');
        Observer.Expect('false-log-count', '6');
        Observer.Expect('false-log', '[before:1:trigger=No | after:1:trigger=No | before:2:trigger=No | after:2:trigger=No | before:3:trigger=No | after:3:trigger=No]');
        Observer.Expect('false-rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P99_DeleteFromCodeForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P99 Del Log";
        Row: Record "LT P99 Del Row";
    begin
        Seed();
        Row.Get(1);
        Row.Delete(true);
        Observer.Observe('code-true', Log.Dump());
        Log.Reset();
        Row.Get(2);
        Row.Delete(false);
        Observer.Observe('code-false', Log.Dump());
        Log.Reset();
        Row.Get(3);
        Row.Delete();
        Observer.Observe('code-plain', Log.Dump());
        Observer.Expect('code-true', '[before:1:trigger=Yes | table-OnDelete:1 | after:1:trigger=Yes]');
        Observer.Expect('code-false', '[before:2:trigger=No | after:2:trigger=No]');
        Observer.Expect('code-plain', '[before:3:trigger=No | after:3:trigger=No]');
        Observer.Verify();
    end;
}
