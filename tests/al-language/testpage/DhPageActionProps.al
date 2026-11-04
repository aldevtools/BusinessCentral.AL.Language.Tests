// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-infooterbar-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (corpus issue 663 items 20 and 21): InFooterBar set through modify() of an action in a page extension, and FileUploadAction on a page field.
// Both compile. What a TestPage sees: the action still runs, the field still reads and writes, and AssistEdit fails on that field as on a plain one. A TestPage cannot reach a file upload action
// (AL0132, must-not-compile case 1864). Object ids 86100-86104.

table 86100 "LT DH PgAct Row"
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

codeunit 86101 "LT DH PgAct Log"
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
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 86102 "LT DH PgAct Card"
{
    PageType = Card;
    SourceTable = "LT DH PgAct Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
                FileUploadAction = Upload;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Footer)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT DH PgAct Log";
                begin
                    Log.Add('Footer');
                end;
            }
            fileuploadaction(Upload)
            {
                ApplicationArea = All;

                trigger OnAction(Files: List of [FileUpload])
                var
                    Log: Codeunit "LT DH PgAct Log";
                begin
                    Log.Add('Upload');
                end;
            }
        }
    }
}

pageextension 86103 "LT DH PgAct Card Ext" extends "LT DH PgAct Card"
{
    actions
    {
        modify(Footer)
        {
            InFooterBar = true;
        }
    }
}

codeunit 86104 "LT DH PgAct Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ModifyInFooterBar_Action_StillRuns()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DH PgAct Log";
        Row: Record "LT DH PgAct Row";
        Pg: TestPage "LT DH PgAct Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Take();
        Pg.OpenView();
        Observer.Observe('visible', Format(Pg.Footer.Visible()));
        Observer.Observe('enabled', Format(Pg.Footer.Enabled()));
        Pg.Footer.Invoke();
        Pg.Close();
        Observer.Observe('log', Log.Take());
        Observer.Expect('visible', 'Yes');
        Observer.Expect('enabled', 'Yes');
        Observer.Expect('log', 'Footer;');
        Observer.Verify();
    end;

    [Test]
    procedure FileUploadActionField_TestPage_ReadsAndWrites()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DH PgAct Log";
        Row: Record "LT DH PgAct Row";
        Pg: TestPage "LT DH PgAct Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('value', Pg.Name.Value);
        Observer.Observe('editable', Format(Pg.Name.Editable()));
        Observer.Observe('visible', Format(Pg.Name.Visible()));
        Pg.Name.SetValue('two');
        Pg.Close();
        Row.Get(1);
        Observer.Observe('stored', Row.Name);
        Observer.Observe('log', Log.Take());
        Observer.Expect('value', 'one');
        Observer.Expect('editable', 'Yes');
        Observer.Expect('visible', 'Yes');
        Observer.Expect('stored', 'two');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure FileUploadActionField_AssistEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DH PgAct Log";
        Row: Record "LT DH PgAct Row";
        Pg: TestPage "LT DH PgAct Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Take();
        Pg.OpenEdit();
        asserterror Pg.Name.AssistEdit();
        Observer.ObserveError('assistedit');
        asserterror Pg.Id.AssistEdit();
        Observer.ObserveError('assistedit_plain_field');
        Observer.Observe('log', Log.Take());
        Observer.Expect('assistedit|text', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('assistedit|code', 'MethodNotSupported');
        Observer.Expect('assistedit_plain_field|text', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('assistedit_plain_field|code', 'MethodNotSupported');
        Observer.Expect('log', '');
        Observer.Verify();
    end;
}
