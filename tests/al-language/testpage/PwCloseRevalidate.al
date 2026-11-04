// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 86153, pages 86154 and 86155, SingleInstance log 86156 (used only by test codeunit 86157)
// Probe (writer PW, from al-runtime-rs PR 324): (a) a card whose field OnValidate logs each run: SetValue that OnValidate refuses, then Close.
//   Is OnValidate run again at Close, and how often? (AhPageTests.al Close_AfterRefusedOnValidate shows the error text at Close, not the count.)
//   (b) a list with an entry OnValidate refused, then Close (or a move to another row first): what is stored for that row afterwards?
// BC versions: 27.5, 28.5, 29.0 (CI matrix)

table 86153 "LT PW CR Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Txt; Text[20])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT PW CR Log";
            begin
                Log.Add('VT:' + Txt);
            end;
        }
        field(3; Guard; Text[20])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT PW CR Log";
            begin
                Log.Add('VG:' + Guard);
                if Guard = 'bad' then
                    Error('PW guard refused');
            end;
        }
    }
    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT PW CR Log";
    begin
        Log.Add('I:' + Id);
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT PW CR Log";
    begin
        Log.Add('M:' + Id + '/' + Txt + '/' + Guard);
    end;
}

page 86154 "LT PW CR Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PW CR Row";

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
            field(GuardCtl; Rec.Guard) { ApplicationArea = All; }
        }
    }
}

page 86155 "LT PW CR List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PW CR Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(GuardCtl; Rec.Guard) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 86156 "LT PW CR Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        R: Text;
    begin
        R := Entries;
        Entries := '';
        exit(R);
    end;
}

codeunit 86157 "LT PW Close Revalidate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT PW CR Log";

    local procedure Seed()
    var
        Row: Record "LT PW CR Row";
    begin
        Row.DeleteAll();
        Row.Id := 'R1';
        Row.Txt := 'orig1';
        Row.Insert();
        Row.Id := 'R2';
        Row.Txt := 'orig2';
        Row.Insert();
        Commit();
        Log.Take();
    end;

    local procedure Stored(): Text
    var
        Row: Record "LT PW CR Row";
        R: Text;
    begin
        if Row.FindSet() then
            repeat
                R += Row.Id + '=' + Row.Txt + '/' + Row.Guard + ';';
            until Row.Next() = 0;
        exit(R);
    end;

    [TryFunction]
    local procedure TryCloseCard(var P: TestPage "LT PW CR Card")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryCloseList(var P: TestPage "LT PW CR List")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryNextList(var P: TestPage "LT PW CR List")
    begin
        P.Next();
    end;

    local procedure Outcome(Ok: Boolean): Text
    var
        R: Text;
    begin
        if Ok then
            R := 'ok'
        else
            R := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(R);
    end;

    [Test]
    procedure PW_Card_RefusedOnValidate_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT PW CR Card";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        Observer.Observe('open log', Log.Take());
        asserterror P.GuardCtl.SetValue('bad');
        Observer.Observe('refused', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('close', Outcome(TryCloseCard(P)));
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', Stored());
        Observer.Expect('open log', '');
        Observer.Expect('refused', 'TestValidation');
        Observer.Expect('setvalue log', 'VG:bad;');
        Observer.Expect('close', 'ok');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R1=orig1/;R2=orig2/;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_Card_ValidEdit_RefusedOnValidate_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT PW CR Card";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.TxtCtl.SetValue('new1');
        Observer.Observe('valid log', Log.Take());
        asserterror P.GuardCtl.SetValue('bad');
        ClearLastError();
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('close', Outcome(TryCloseCard(P)));
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', Stored());
        Observer.Expect('valid log', 'VT:new1;');
        Observer.Expect('setvalue log', 'VG:bad;');
        Observer.Expect('close', 'ok');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R1=orig1/;R2=orig2/;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_Card_RefusedTwice_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT PW CR Card";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        asserterror P.GuardCtl.SetValue('bad');
        asserterror P.GuardCtl.SetValue('bad');
        ClearLastError();
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('close', Outcome(TryCloseCard(P)));
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', Stored());
        Observer.Expect('setvalue log', 'VG:bad;VG:bad;');
        Observer.Expect('close', 'ok');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R1=orig1/;R2=orig2/;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_List_RefusedOnValidate_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT PW CR List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        Log.Take();
        P.TxtCtl.SetValue('new1');
        asserterror P.GuardCtl.SetValue('bad');
        ClearLastError();
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('close', Outcome(TryCloseList(P)));
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', Stored());
        Observer.Expect('setvalue log', 'VT:new1;VG:bad;');
        Observer.Expect('close', 'ok');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R1=orig1/;R2=orig2/;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_List_RefusedOnValidate_ThenNext_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT PW CR List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        Log.Take();
        P.TxtCtl.SetValue('new1');
        asserterror P.GuardCtl.SetValue('bad');
        ClearLastError();
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('next', Outcome(TryNextList(P)));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('stored after next', Stored());
        Observer.Observe('close', Outcome(TryCloseList(P)));
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', Stored());
        Observer.Expect('setvalue log', 'VT:new1;VG:bad;');
        Observer.Expect('next', 'ok');
        Observer.Expect('next log', '');
        Observer.Expect('stored after next', 'R1=orig1/;R2=orig2/;');
        Observer.Expect('close', 'ok');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R1=orig1/;R2=orig2/;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_List_NewRow_RefusedOnValidate_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT PW CR List";
    begin
        Seed();
        P.OpenEdit();
        P.New();
        Log.Take();
        P.IdCtl.SetValue('N1');
        P.TxtCtl.SetValue('newrow');
        Observer.Observe('new row log', Log.Take());
        asserterror P.GuardCtl.SetValue('bad');
        ClearLastError();
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('close', Outcome(TryCloseList(P)));
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', Stored());
        Observer.Expect('new row log', 'I:N1;VT:newrow;');
        Observer.Expect('setvalue log', 'VG:bad;');
        Observer.Expect('close', 'ok');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R1=orig1/;R2=orig2/;');
        Observer.Verify();
    end;
}
