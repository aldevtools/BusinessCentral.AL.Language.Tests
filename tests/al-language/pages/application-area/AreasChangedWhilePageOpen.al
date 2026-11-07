// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-applicationarea-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 95666, card page 95667, test codeunit 95668
// Probe (al-runner issue 7001; Base Application's RefreshExperienceTierCurrentCompany ends in ApplicationArea(Text)): the session's
//   application areas set again while a TestPage is open, from an action of the page (a page trigger) and from the test itself: the same
//   text, the same tags in another order, fewer tags, other tags, and from '' to a tag. Then the fields of the open page are read: one with
//   ApplicationArea = All, one with Basic, one with Suite (a read that fails is logged with its error text). ApplicationArea() is read
//   back after each set. For comparison the page is closed and opened again.
// local object: the page's ApplicationArea properties are under test
// Seen on BC 29 (Linux CI): ApplicationArea() reads back the text as set (no reordering). An open TestPage keeps the controls it had
//   when it opened: a field the new areas remove stays readable, one they add stays not found, until the page is closed and opened again.
// BC versions: 27-29

table 95666 "LT ACW Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { DataClassification = SystemMetadata; }
        field(2; A; Text[10]) { DataClassification = SystemMetadata; }
        field(3; B; Text[10]) { DataClassification = SystemMetadata; }
        field(4; S; Text[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 95667 "LT ACW Card"
{
    PageType = Card;
    SourceTable = "LT ACW Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(AllCtl; Rec.A) { ApplicationArea = All; }
            field(BasicCtl; Rec.B) { ApplicationArea = Basic; }
            field(SuiteCtl; Rec.S) { ApplicationArea = Suite; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetSame)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ApplicationArea(ApplicationArea());
                end;
            }
            action(SetReordered)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ApplicationArea('#Suite,#Basic');
                end;
            }
            action(SetBasic)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ApplicationArea('#Basic');
                end;
            }
            action(SetSuite)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ApplicationArea('#Suite');
                end;
            }
            action(Noop)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

codeunit 95668 "LT ACW Tests"
{
    Subtype = Test;

    var
        Saved: Text;

    local procedure Start(Areas: Text)
    var
        Row: Record "LT ACW Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.A := 'a';
        Row.B := 'b';
        Row.S := 's';
        Row.Insert();
        Saved := ApplicationArea();
        ApplicationArea(Areas);
    end;

    local procedure Restore()
    begin
        ApplicationArea(Saved);
    end;

    [TryFunction]
    local procedure TryRead(var P: TestPage "LT ACW Card"; Which: Integer; var Value: Text)
    begin
        case Which of
            1:
                Value := P.AllCtl.Value();
            2:
                Value := P.BasicCtl.Value();
            3:
                Value := P.SuiteCtl.Value();
        end;
    end;

    local procedure Reads(var P: TestPage "LT ACW Card"): Text
    var
        Result: Text;
        Value: Text;
        Which: Integer;
    begin
        for Which := 1 to 3 do begin
            Value := '';
            if TryRead(P, Which, Value) then
                Result += Value + ';'
            else
                Result += 'ERR(' + GetLastErrorText() + ');';
        end;
        exit(Result);
    end;

    [Test]
    procedure AreasSetInPageTrigger_SameText_FieldsRead()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT ACW Card";
    begin
        Start('#Basic,#Suite');
        P.OpenView();
        Observer.Observe('before', Reads(P));
        P.SetSame.Invoke();
        Observer.Observe('areas', ApplicationArea());
        Observer.Observe('after', Reads(P));
        P.Close();
        Restore();
        Observer.Expect('before', 'a;b;s;');
        Observer.Expect('areas', '#Basic,#Suite');
        Observer.Expect('after', 'a;b;s;');
        Observer.Verify();
    end;

    [Test]
    procedure AreasSetInPageTrigger_Reordered_FieldsRead()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT ACW Card";
    begin
        Start('#Basic,#Suite');
        P.OpenView();
        P.SetReordered.Invoke();
        Observer.Observe('areas', ApplicationArea());
        Observer.Observe('after', Reads(P));
        P.Close();
        Restore();
        Observer.Expect('areas', '#Suite,#Basic');
        Observer.Expect('after', 'a;b;s;');
        Observer.Verify();
    end;

    [Test]
    procedure AreasSetInPageTrigger_FewerTags_FieldsRead()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT ACW Card";
    begin
        Start('#Basic,#Suite');
        P.OpenView();
        P.SetBasic.Invoke();
        Observer.Observe('areas', ApplicationArea());
        Observer.Observe('after', Reads(P));
        P.Noop.Invoke();
        Observer.Observe('after action', Reads(P));
        P.Close();
        P.OpenView();
        Observer.Observe('reopened', Reads(P));
        P.Close();
        Restore();
        Observer.Expect('areas', '#Basic');
        Observer.Expect('after', 'a;b;s;');
        Observer.Expect('after action', 'a;b;s;');
        Observer.Expect('reopened', 'a;b;ERR(The field with ID = n is not found on the page.);');
        Observer.Verify();
    end;

    [Test]
    procedure AreasSetInPageTrigger_OtherTags_FieldsRead()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT ACW Card";
    begin
        Start('#Basic');
        P.OpenView();
        Observer.Observe('before', Reads(P));
        P.SetSuite.Invoke();
        Observer.Observe('areas', ApplicationArea());
        Observer.Observe('after', Reads(P));
        P.Close();
        P.OpenView();
        Observer.Observe('reopened', Reads(P));
        P.Close();
        Restore();
        Observer.Expect('before', 'a;b;ERR(The field with ID = n is not found on the page.);');
        Observer.Expect('areas', '#Suite');
        Observer.Expect('after', 'a;b;ERR(The field with ID = n is not found on the page.);');
        Observer.Expect('reopened', 'a;ERR(The field with ID = n is not found on the page.);s;');
        Observer.Verify();
    end;

    [Test]
    procedure AreasSetInPageTrigger_FromEmpty_FieldsRead()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT ACW Card";
    begin
        Start('');
        P.OpenView();
        Observer.Observe('before', Reads(P));
        P.SetBasic.Invoke();
        Observer.Observe('areas', ApplicationArea());
        Observer.Observe('after', Reads(P));
        P.Close();
        Restore();
        Observer.Expect('before', 'a;b;s;');
        Observer.Expect('areas', '#Basic');
        Observer.Expect('after', 'a;b;s;');
        Observer.Verify();
    end;

    [Test]
    procedure AreasSetInTest_FewerTags_FieldsRead()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT ACW Card";
    begin
        Start('#Basic,#Suite');
        P.OpenView();
        ApplicationArea('#Basic');
        Observer.Observe('areas', ApplicationArea());
        Observer.Observe('after', Reads(P));
        P.Close();
        Restore();
        Observer.Expect('areas', '#Basic');
        Observer.Expect('after', 'a;b;s;');
        Observer.Verify();
    end;
}
