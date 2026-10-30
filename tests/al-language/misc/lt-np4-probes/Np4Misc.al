// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 93430, test codeunit 93431
// Writer NP4 (NP lane, 2026-10-30). Probe: (1) Evaluate of a text made of a TAB (alone, around a number) into Integer, Decimal, Date, Boolean and Option, used as a
//   statement: error text and code or the value. (2) Reads under Record.ReadIsolation RepeatableRead and UpdLock (FindSet, Get, Find('-'), IsEmpty, Count, FindFirst) and
//   IsInWriteTransaction after each. (3) Windows Language Get(1078).
// BC versions: 27, 28, 29

table 93430 "LT NP4 Misc Row"
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

codeunit 93431 "LT NP4 Misc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Option Integer,Decimal,Date,Boolean,Option;

    [TryFunction]
    local procedure TryEvaluate(Txt: Text; var Shown: Text)
    var
        IntVar: Integer;
        DecVar: Decimal;
        DateVar: Date;
        BoolVar: Boolean;
        OptVar: Option A,B;
    begin
        case Mode of
            Mode::Integer:
                begin
                    Evaluate(IntVar, Txt);
                    Shown := Format(IntVar);
                end;
            Mode::Decimal:
                begin
                    Evaluate(DecVar, Txt);
                    Shown := Format(DecVar);
                end;
            Mode::Date:
                begin
                    Evaluate(DateVar, Txt);
                    Shown := Format(DateVar, 0, 9);
                end;
            Mode::Boolean:
                begin
                    Evaluate(BoolVar, Txt);
                    Shown := Format(BoolVar);
                end;
            Mode::Option:
                begin
                    Evaluate(OptVar, Txt);
                    Shown := Format(OptVar);
                end;
        end;
    end;

    local procedure Ev(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        Shown: Text;
    begin
        if TryEvaluate(Txt, Shown) then
            Observer.Observe(Name, 'ok|' + Shown)
        else begin
            Observer.Observe(Name, CopyStr('error:' + GetLastErrorText() + '|' + GetLastErrorCode(), 1, 600));
            ClearLastError();
        end;
    end;

    local procedure AllShapes(var Observer: Codeunit "Probe Observer")
    var
        Tab: Text[1];
    begin
        Tab[1] := 9;
        Ev(Observer, 'tab', Tab);
        Ev(Observer, 'tab_one', Tab + '1');
        Ev(Observer, 'one_tab', '1' + Tab);
        Ev(Observer, 'tab_tab', Tab + Tab);
        Ev(Observer, 'empty', '');
        Ev(Observer, 'space', ' ');
    end;

    [Test]
    procedure NP4_Evaluate_Tab_Integer()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := Mode::Integer;
        AllShapes(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure NP4_Evaluate_Tab_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := Mode::Decimal;
        AllShapes(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure NP4_Evaluate_Tab_Date()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := Mode::Date;
        AllShapes(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure NP4_Evaluate_Tab_Boolean()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := Mode::Boolean;
        AllShapes(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure NP4_Evaluate_Tab_Option()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := Mode::Option;
        AllShapes(Observer);
        Observer.Finish();
    end;

    local procedure SeedRows()
    var
        Row: Record "LT NP4 Misc Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Commit();
    end;

    local procedure Reads(var Observer: Codeunit "Probe Observer"; Level: Text; Isolation: IsolationLevel)
    var
        Row: Record "LT NP4 Misc Row";
        Ok: Boolean;
    begin
        Row.ReadIsolation := Isolation;
        Ok := Row.FindSet();
        Observer.Observe(Level + ' findset', Format(Ok) + '|' + Format(Row.Id) + '|' + Format(IsInWriteTransaction()));
        Clear(Row);
        Row.ReadIsolation := Isolation;
        Ok := Row.Get(2);
        Observer.Observe(Level + ' get', Format(Ok) + '|' + Format(Row.Name) + '|' + Format(IsInWriteTransaction()));
        Clear(Row);
        Row.ReadIsolation := Isolation;
        Ok := Row.Find('-');
        Observer.Observe(Level + ' find first', Format(Ok) + '|' + Format(Row.Id) + '|' + Format(IsInWriteTransaction()));
        Clear(Row);
        Row.ReadIsolation := Isolation;
        Observer.Observe(Level + ' isempty', Format(Row.IsEmpty()) + '|' + Format(IsInWriteTransaction()));
        Observer.Observe(Level + ' count', Format(Row.Count()) + '|' + Format(IsInWriteTransaction()));
        Ok := Row.FindFirst();
        Observer.Observe(Level + ' findfirst', Format(Ok) + '|' + Format(Row.Id) + '|' + Format(IsInWriteTransaction()));
        Row.ReadIsolation := Isolation;
        Ok := Row.FindLast();
        Observer.Observe(Level + ' findlast', Format(Ok) + '|' + Format(Row.Id) + '|' + Format(IsInWriteTransaction()));
    end;

    [Test]
    procedure NP4_ReadIsolation_RepeatableRead_Reads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        Reads(Observer, 'repeatable', IsolationLevel::RepeatableRead);
        Observer.Finish();
    end;

    [Test]
    procedure NP4_ReadIsolation_UpdLock_Reads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        Reads(Observer, 'updlock', IsolationLevel::UpdLock);
        Observer.Finish();
    end;

    [Test]
    procedure NP4_ReadIsolation_ReadCommitted_Reads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        Reads(Observer, 'committed', IsolationLevel::ReadCommitted);
        Observer.Finish();
    end;

    [Test]
    procedure NP4_WindowsLanguage_Get1078()
    var
        Observer: Codeunit "Probe Observer";
        Lang: Record "Windows Language";
    begin
        Observer.Observe('get', Format(Lang.Get(1078)));
        Observer.Observe('id', Format(Lang."Language ID"));
        Observer.Observe('name', Lang.Name);
        Observer.Observe('abbreviated', Lang."Abbreviated Name");
        Observer.Observe('codepage', Format(Lang."Primary CodePage"));
        Observer.Observe('tag', Lang."Language Tag");
        Observer.Finish();
    end;
}
