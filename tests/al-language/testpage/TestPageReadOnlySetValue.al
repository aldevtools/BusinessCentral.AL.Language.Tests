// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-openview-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: RSV Row (68010), RSV Probe (68011), RSV Card (68012), RSV Locked Card (68013),
//                RSV Host (68014), Assert (60021)
//
/// <summary>
/// Pins what TestField.SetValue does on a control that is not editable, for each way a
/// control becomes read-only:
///     TestPage.OpenView()
///     an action's RunPageMode = View (the opened page reaches a [PageHandler])
///     Editable = false on the page
///     Editable = false on the control, on a page opened with OpenEdit()
///
/// Every arm types WITHOUT asserterror and asserts ONE string carrying:
///     pageEd=  TestPage.Editable() before typing
///     ctlEd=   the typed control's Editable() before typing
///     err=     GetLastErrorText() after the SetValue (cleared just before it)
///     valErrs= TestPage.ValidationErrorCount() after the SetValue
///     shown=   what the control reads back straight after the SetValue
///     now=     the table's rows straight after the SetValue, before the page closes
///     closed=  the table's rows after the page has closed
///     log=     which OnValidate triggers ran (t = the table field's, p = the page control's)
/// so a failure prints everything BC did rather than stopping at the first difference.
///
/// Two rows are seeded, 'A' and 'B'; every page opens on the first row, 'A'.
///
/// Written by agent stma-auto-5, an automated implementation agent acting on the account
/// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#5002.
/// </summary>

table 68010 "RSV Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50])
        {
            trigger OnValidate()
            var
                Probe: Codeunit "RSV Probe";
            begin
                Probe.Log('t');
            end;
        }
        field(3; Locked; Text[50])
        {
            trigger OnValidate()
            var
                Probe: Codeunit "RSV Probe";
            begin
                Probe.Log('t');
            end;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 68011 "RSV Probe"
{
    SingleInstance = true;

    var
        Trail: Text;
        ShownText: Text;

    procedure Reset()
    begin
        Trail := '';
        ShownText := '';
    end;

    procedure Log(Marker: Text)
    begin
        Trail += Marker;
    end;

    procedure Logged(): Text
    begin
        exit(Trail);
    end;

    procedure RecordShown(NewShown: Text)
    begin
        ShownText := NewShown;
    end;

    procedure GetShown(): Text
    begin
        exit(ShownText);
    end;
}

page 68012 "RSV Card"
{
    PageType = Card;
    SourceTable = "RSV Row";
    ApplicationArea = All;
    Caption = 'RSV Card';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Probe: Codeunit "RSV Probe";
                begin
                    Probe.Log('p');
                end;
            }
            field(NoteCtl; Note)
            {
                ApplicationArea = All;
                Caption = 'Note';
            }
            field(Locked; Rec.Locked)
            {
                ApplicationArea = All;
                Editable = false;

                trigger OnValidate()
                var
                    Probe: Codeunit "RSV Probe";
                begin
                    Probe.Log('p');
                end;
            }
        }
    }

    var
        Note: Text[50];
}

page 68013 "RSV Locked Card"
{
    PageType = Card;
    SourceTable = "RSV Row";
    ApplicationArea = All;
    Caption = 'RSV Locked Card';
    Editable = false;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Probe: Codeunit "RSV Probe";
                begin
                    Probe.Log('p');
                end;
            }
        }
    }
}

page 68014 "RSV Host"
{
    PageType = Card;
    SourceTable = "RSV Row";
    ApplicationArea = All;
    Caption = 'RSV Host';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenCardView)
            {
                ApplicationArea = All;
                Caption = 'Open Card View';
                RunObject = page "RSV Card";
                RunPageMode = View;
            }
        }
    }
}

codeunit 68015 "RSV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        Row: Record "RSV Row";
        Probe: Codeunit "RSV Probe";
    begin
        Probe.Reset();
        Row.DeleteAll();
        AddRow('A', 'Alpha');
        AddRow('B', 'Bravo');
    end;

    local procedure AddRow(No: Code[20]; NewName: Text[50])
    var
        Row: Record "RSV Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := NewName;
        Row.Locked := 'L' + No;
        Row.Insert();
    end;

    local procedure Rows(): Text
    var
        Row: Record "RSV Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Row."No." + '=' + Row.Name + '/' + Row.Locked;
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure Editability(PageEditable: Boolean; ControlEditable: Boolean): Text
    begin
        exit('pageEd=' + Format(PageEditable) + ';ctlEd=' + Format(ControlEditable));
    end;

    local procedure AfterSetValue(ShownValue: Text; ValidationErrors: Integer): Text
    begin
        exit(';err=' + GetLastErrorText() + ';valErrs=' + Format(ValidationErrors) +
             ';shown=' + ShownValue + ';now=' + Rows());
    end;

    local procedure Observed(AfterSetValue: Text): Text
    var
        Probe: Codeunit "RSV Probe";
    begin
        exit(AfterSetValue + ';closed=' + Rows() + ';log=' + Probe.Logged());
    end;

    [Test]
    procedure OpenEdit_SetValue_Control()
    // The control: an editable page and an editable control.
    var
        Card: TestPage "RSV Card";
        After: Text;
    begin
        Seed();
        Card.OpenEdit();
        After := Editability(Card.Editable(), Card.Name.Editable());
        ClearLastError();
        Card.Name.SetValue('Typed');
        After += AfterSetValue(Card.Name.Value(), Card.ValidationErrorCount());
        Card.Close();

        Assert.AreEqual(
            'pageEd=Yes;ctlEd=Yes;err=;valErrs=0;shown=Typed;now=A=Alpha/LA,B=Bravo/LB;closed=A=Typed/LA,B=Bravo/LB;log=tp', Observed(After),
            'SetValue on an editable control of a page opened with OpenEdit.');
    end;

    [Test]
    procedure OpenView_SetValue()
    var
        Card: TestPage "RSV Card";
        After: Text;
    begin
        Seed();
        Card.OpenView();
        After := Editability(Card.Editable(), Card.Name.Editable());
        ClearLastError();
        Card.Name.SetValue('Typed');
        After += AfterSetValue(Card.Name.Value(), Card.ValidationErrorCount());
        Card.Close();

        Assert.AreEqual(
            'pageEd=No;ctlEd=No;err=;valErrs=0;shown=Typed;now=A=Alpha/LA,B=Bravo/LB;closed=A=Typed/LA,B=Bravo/LB;log=tp', Observed(After),
            'SetValue on a page opened with OpenView.');
    end;

    [Test]
    [HandlerFunctions('RsvCardTypeHandler')]
    procedure RunPageModeView_SetValue()
    var
        Host: TestPage "RSV Host";
        Probe: Codeunit "RSV Probe";
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey('B');
        Host.OpenCardView.Invoke();
        Host.Close();

        Assert.AreEqual(
            'pageEd=No;ctlEd=No;err=;valErrs=0;shown=Typed;now=A=Alpha/LA,B=Bravo/LB;closed=A=Typed/LA,B=Bravo/LB;log=tp', Observed(Probe.GetShown()),
            'SetValue on a card opened by an action with RunPageMode = View.');
    end;

    [Test]
    procedure PageEditableFalse_OpenEdit_SetValue()
    var
        Card: TestPage "RSV Locked Card";
        After: Text;
    begin
        Seed();
        Card.OpenEdit();
        After := Editability(Card.Editable(), Card.Name.Editable());
        ClearLastError();
        Card.Name.SetValue('Typed');
        After += AfterSetValue(Card.Name.Value(), Card.ValidationErrorCount());
        Card.Close();

        Assert.AreEqual(
            'pageEd=No;ctlEd=No;err=;valErrs=0;shown=Typed;now=A=Alpha/LA,B=Bravo/LB;closed=A=Typed/LA,B=Bravo/LB;log=tp', Observed(After),
            'SetValue on a page declaring Editable = false, opened with OpenEdit.');
    end;

    [Test]
    procedure ControlEditableFalse_OpenEdit_SetValue()
    var
        Card: TestPage "RSV Card";
        After: Text;
    begin
        Seed();
        Card.OpenEdit();
        After := Editability(Card.Editable(), Card.Locked.Editable());
        ClearLastError();
        Card.Locked.SetValue('Typed');
        After += AfterSetValue(Card.Locked.Value(), Card.ValidationErrorCount());
        Card.Close();

        Assert.AreEqual(
            'pageEd=Yes;ctlEd=No;err=;valErrs=0;shown=Typed;now=A=Alpha/LA,B=Bravo/LB;closed=A=Alpha/Typed,B=Bravo/LB;log=tp', Observed(After),
            'SetValue on a control declaring Editable = false, on a page opened with OpenEdit.');
    end;

    [Test]
    procedure OpenView_PageVariableControl_StaysEditable()
    // A control bound to a page variable rather than to a field of Rec: OpenView makes the
    // page and its Rec-bound controls read-only, and leaves this one editable.
    var
        Card: TestPage "RSV Card";
    begin
        Seed();
        Card.OpenView();
        Assert.AreEqual('pageEd=No;ctlEd=Yes', Editability(Card.Editable(), Card.NoteCtl.Editable()),
            'A page-variable control on a page opened with OpenView stays editable.');
        Card.Close();
    end;

    [Test]
    procedure OpenView_ThenEditAction_ControlBecomesEditable()
    var
        Card: TestPage "RSV Card";
    begin
        Seed();
        Card.OpenView();
        Card.Edit().Invoke();
        Assert.AreEqual('pageEd=Yes;ctlEd=Yes', Editability(Card.Editable(), Card.Name.Editable()),
            'The built-in Edit action switches an OpenView card to editable, controls included.');
        Card.Close();
    end;

    [Test]
    procedure OpenEdit_ThenViewAction_ControlBecomesReadOnly()
    var
        Card: TestPage "RSV Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.View().Invoke();
        Assert.AreEqual('pageEd=No;ctlEd=No', Editability(Card.Editable(), Card.Name.Editable()),
            'The built-in View action switches an OpenEdit card to read-only, controls included.');
        Card.Close();
    end;

    [PageHandler]
    procedure RsvCardTypeHandler(var Card: TestPage "RSV Card")
    var
        Probe: Codeunit "RSV Probe";
        After: Text;
    begin
        After := Editability(Card.Editable(), Card.Name.Editable());
        ClearLastError();
        Card.Name.SetValue('Typed');
        After += AfterSetValue(Card.Name.Value(), Card.ValidationErrorCount());
        Probe.RecordShown(After);
        Card.Close();
    end;
}
