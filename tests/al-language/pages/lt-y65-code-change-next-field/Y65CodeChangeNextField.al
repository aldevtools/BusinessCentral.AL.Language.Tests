// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// Fixtures used: Probe Observer (codeunit 69160); table 93340, pages 93340 (Worksheet, InsertAllowed = false), 93341 (Card), 93342 (List),
//   codeunit 93340 (log, used by test codeunit 93341 only), test codeunit 93341
// Probe (al-runner issue 6669, follow-up to 6629; the SetValue of a page-variable field saves the edited row first is pinned by
//   pages/lt-y45-save-before-action/Y45SaveBeforeAction.al NextField_*): a field's OnValidate changes Rec IN CODE (a page variable's control
//   trigger, a table field trigger, a Rec field's control trigger, an explicit Rec.Modify()), and then the next page-variable field, an
//   action, Next or Close runs. Does the save before it write the change made in code? The probe field Activate (page variable) and the
//   action Peek read the stored row with a fresh Get and log it.
// BC versions: 27, 28, 29

table 93340 "LT Y65 Member"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[50]) { }
        field(3; "Secret Key"; Guid) { }
        field(4; Note; Text[30])
        {
            trigger OnValidate()
            begin
                Counter := 7;
            end;
        }
        field(5; Counter; Integer) { }
        field(6; Tag; Text[30]) { }
        field(7; Tag2; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 93340 "LT Y65 Member Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;

    procedure Db(Where: Text; MemberCode: Code[10])
    var
        Member: Record "LT Y65 Member";
    begin
        if not Member.Get(MemberCode) then begin
            Add(Where + ' no row');
            exit;
        end;
        Add(Where + ' db name=' + Member.Name + ' key=' + Format(not IsNullGuid(Member."Secret Key")) + ' tag=' + Member.Tag +
            ' cnt=' + Format(Member.Counter) + ' tag2=' + Member.Tag2);
    end;
}

page 93340 "LT Y65 Member Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y65 Member";
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
                field(Tag2; Rec.Tag2)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        Rec.Tag := 'rf';
                    end;
                }
                field(Secret; Secret)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        Rec."Secret Key" := CreateGuid();
                        Rec.Tag := 'pv';
                    end;
                }
                field(Mark; Mark)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        Rec.Tag := 'mark';
                        Rec.Modify();
                    end;
                }
                field(Activate; Activate)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    var
                        Log: Codeunit "LT Y65 Member Log";
                    begin
                        Log.Db('activate', Rec."Code");
                        Log.Add('activate rec tag=' + Rec.Tag);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Peek)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT Y65 Member Log";
                begin
                    Log.Db('peek', Rec."Code");
                end;
            }
        }
    }

    var
        Secret: Text[50];
        Mark: Text[30];
        Activate: Boolean;
}

page 93341 "LT Y65 Member Card"
{
    PageType = Card;
    SourceTable = "LT Y65 Member";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(Note; Rec.Note) { ApplicationArea = All; }
            field(Secret; Secret)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Rec."Secret Key" := CreateGuid();
                    Rec.Tag := 'pv';
                end;
            }
            field(Activate; Activate)
            {
                ApplicationArea = All;
                trigger OnValidate()
                var
                    Log: Codeunit "LT Y65 Member Log";
                begin
                    Log.Db('activate', Rec."Code");
                    Log.Add('activate rec tag=' + Rec.Tag);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Peek)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT Y65 Member Log";
                begin
                    Log.Db('peek', Rec."Code");
                end;
            }
        }
    }

    var
        Secret: Text[50];
        Activate: Boolean;
}

page 93342 "LT Y65 Member List"
{
    PageType = List;
    SourceTable = "LT Y65 Member";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Secret; Secret)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        Rec."Secret Key" := CreateGuid();
                        Rec.Tag := 'pv';
                    end;
                }
                field(Activate; Activate)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    var
                        Log: Codeunit "LT Y65 Member Log";
                    begin
                        Log.Db('activate', Rec."Code");
                        Log.Add('activate rec tag=' + Rec.Tag);
                    end;
                }
            }
        }
    }

    var
        Secret: Text[50];
        Activate: Boolean;
}

codeunit 93341 "LT Y65 Code Change Next Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
    begin
        Log.Take();
        Member.DeleteAll();
        Member."Code" := 'A';
        Member.Insert();
        Member."Code" := 'B';
        Member.Insert();
        Member.Get('A');
    end;

    local procedure TryActivate(var Worksheet: TestPage "LT Y65 Member Worksheet"): Text
    begin
        ClearLastError();
        if TryActivateWs(Worksheet) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryMark(var Worksheet: TestPage "LT Y65 Member Worksheet")
    begin
        Worksheet.Mark.SetValue('m');
    end;

    [TryFunction]
    local procedure TryActivateWs(var Worksheet: TestPage "LT Y65 Member Worksheet")
    begin
        Worksheet.Activate.SetValue(true);
    end;

    [Test]
    procedure Y65_Worksheet_Reporter_NameSecretActivate()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Worksheet: TestPage "LT Y65 Member Worksheet";
    begin
        Seed();
        Member.Get('A');
        Worksheet.OpenEdit();
        Worksheet.GoToRecord(Member);
        Worksheet.Name.SetValue('Alice');
        Worksheet.Secret.SetValue('x');
        Observer.Observe('activate', TryActivate(Worksheet));
        Worksheet.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Worksheet_SecretOnlyThenActivate()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Worksheet: TestPage "LT Y65 Member Worksheet";
    begin
        Seed();
        Member.Get('A');
        Worksheet.OpenEdit();
        Worksheet.GoToRecord(Member);
        Worksheet.Secret.SetValue('x');
        Observer.Observe('activate', TryActivate(Worksheet));
        Worksheet.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Worksheet_TableTriggerChangeThenActivate()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Worksheet: TestPage "LT Y65 Member Worksheet";
    begin
        Seed();
        Member.Get('A');
        Worksheet.OpenEdit();
        Worksheet.GoToRecord(Member);
        Worksheet.Note.SetValue('n1');
        Observer.Observe('activate', TryActivate(Worksheet));
        Worksheet.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Worksheet_RecFieldControlTriggerChangeThenActivate()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Worksheet: TestPage "LT Y65 Member Worksheet";
    begin
        Seed();
        Member.Get('A');
        Worksheet.OpenEdit();
        Worksheet.GoToRecord(Member);
        Worksheet.Tag2.SetValue('t2');
        Observer.Observe('activate', TryActivate(Worksheet));
        Worksheet.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Worksheet_SecretThenNameThenAction()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Worksheet: TestPage "LT Y65 Member Worksheet";
    begin
        Seed();
        Member.Get('A');
        Worksheet.OpenEdit();
        Worksheet.GoToRecord(Member);
        Worksheet.Secret.SetValue('x');
        Log.Db('after secret', 'A');
        Worksheet.Name.SetValue('Bob');
        Log.Db('after name', 'A');
        Worksheet.Peek.Invoke();
        Worksheet.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Worksheet_SecretThenAction()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Worksheet: TestPage "LT Y65 Member Worksheet";
    begin
        Seed();
        Member.Get('A');
        Worksheet.OpenEdit();
        Worksheet.GoToRecord(Member);
        Worksheet.Secret.SetValue('x');
        Worksheet.Peek.Invoke();
        Worksheet.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Worksheet_SecretThenClose()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Worksheet: TestPage "LT Y65 Member Worksheet";
    begin
        Seed();
        Member.Get('A');
        Worksheet.OpenEdit();
        Worksheet.GoToRecord(Member);
        Worksheet.Secret.SetValue('x');
        Worksheet.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Worksheet_SecretThenNext()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Worksheet: TestPage "LT Y65 Member Worksheet";
    begin
        Seed();
        Member.Get('A');
        Worksheet.OpenEdit();
        Worksheet.GoToRecord(Member);
        Worksheet.Secret.SetValue('x');
        Observer.Observe('next', Format(Worksheet.Next()));
        Observer.Observe('now on', Worksheet."Code".Value());
        Log.Db('after next', 'A');
        Worksheet.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Worksheet_ModifyInOnValidateThenActivate()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Worksheet: TestPage "LT Y65 Member Worksheet";
    begin
        Seed();
        Member.Get('A');
        Worksheet.OpenEdit();
        Worksheet.GoToRecord(Member);
        Worksheet.Name.SetValue('Carl');
        ClearLastError();
        if TryMark(Worksheet) then
            Observer.Observe('mark', 'ok')
        else
            Observer.Observe('mark', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Log.Db('after mark', 'A');
        Observer.Observe('activate', TryActivate(Worksheet));
        Worksheet.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Worksheet_ModifyInOnValidate_NoEditBefore()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Worksheet: TestPage "LT Y65 Member Worksheet";
    begin
        Seed();
        Member.Get('A');
        Worksheet.OpenEdit();
        Worksheet.GoToRecord(Member);
        ClearLastError();
        if TryMark(Worksheet) then
            Observer.Observe('mark', 'ok')
        else
            Observer.Observe('mark', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Log.Db('after mark', 'A');
        Observer.Observe('activate', TryActivate(Worksheet));
        Worksheet.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Worksheet_SecretTwiceThenActivate()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Worksheet: TestPage "LT Y65 Member Worksheet";
    begin
        Seed();
        Member.Get('A');
        Worksheet.OpenEdit();
        Worksheet.GoToRecord(Member);
        Worksheet.Secret.SetValue('x');
        Worksheet.Secret.SetValue('y');
        Observer.Observe('activate', TryActivate(Worksheet));
        Worksheet.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Card_NameSecretActivate()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Card: TestPage "LT Y65 Member Card";
    begin
        Seed();
        Member.Get('A');
        Card.OpenEdit();
        Card.GoToRecord(Member);
        Card.Name.SetValue('Alice');
        Card.Secret.SetValue('x');
        Card.Activate.SetValue(true);
        Card.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Card_SecretOnlyThenActivate()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Card: TestPage "LT Y65 Member Card";
    begin
        Seed();
        Member.Get('A');
        Card.OpenEdit();
        Card.GoToRecord(Member);
        Card.Secret.SetValue('x');
        Card.Activate.SetValue(true);
        Card.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Card_TableTriggerChangeThenAction()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        Card: TestPage "LT Y65 Member Card";
    begin
        Seed();
        Member.Get('A');
        Card.OpenEdit();
        Card.GoToRecord(Member);
        Card.Note.SetValue('n1');
        Card.Peek.Invoke();
        Card.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_List_NameSecretActivate()
    var
        Member: Record "LT Y65 Member";
        Log: Codeunit "LT Y65 Member Log";
        List: TestPage "LT Y65 Member List";
    begin
        Seed();
        Member.Get('A');
        List.OpenEdit();
        List.GoToRecord(Member);
        List.Name.SetValue('Alice');
        List.Secret.SetValue('x');
        List.Activate.SetValue(true);
        List.Close();
        Log.Db('after close', 'A');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;
}
