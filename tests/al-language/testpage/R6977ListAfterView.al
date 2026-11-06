// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-view-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 96060 - 96062 (TP R6977B *)
// local object: a List with no CardPageId, so the built-in View switches the list itself
// Probe: follow-up of al-runner issue 6977 (testpage/R6977ListViewNext.al pins the First/Next walk). An editable List with no card page over
//   2 rows, opened by TestPage.OpenEdit on the first row, then View().Invoke(). Measured after the switch: Editable of a field (and of the
//   page), SetValue on a field (typed without asserterror, as testpage/TestPageReadOnlySetValue.al does: the error text, the validation
//   error count, what the field shows, what is stored), Visible and Enabled of the built-in Edit and View actions, and Edit().Invoke() back
//   (Editable and SetValue after it). Each test also observes the same reads before View as the contrast.
// Result: OBSERVE (filled in from the CI run).
// BC versions: 27, 28, 29

table 96060 "TP R6977B Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Description; Text[30]) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

page 96061 "TP R6977B Lines"
{
    PageType = List;
    SourceTable = "TP R6977B Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 96062 "TP R6977B After View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Line: Record "TP R6977B Line";
    begin
        Line.DeleteAll();
        Line."Line No." := 10000;
        Line.Description := 'a';
        Line.Insert();
        Line."Line No." := 20000;
        Line.Description := 'b';
        Line.Insert();
    end;

    local procedure Stored(LineNo: Integer): Text
    var
        Line: Record "TP R6977B Line";
    begin
        if not Line.Get(LineNo) then
            exit('<none>');
        exit(Line.Description);
    end;

    local procedure StoredCount(): Text
    var
        Line: Record "TP R6977B Line";
    begin
        exit(Format(Line.Count()));
    end;

    local procedure OpenOnFirst(var Lines: TestPage "TP R6977B Lines")
    begin
        Lines.OpenEdit();
        Lines.First();
    end;

    local procedure TypeDescription(var Lines: TestPage "TP R6977B Lines"; var Observer: Codeunit "Probe Observer"; Prefix: Text)
    begin
        ClearLastError();
        Lines.Description.SetValue('x');
        Observer.Observe(Prefix + 'err', GetLastErrorText());
        Observer.Observe(Prefix + 'valErrs', Format(Lines.ValidationErrorCount()));
        Observer.Observe(Prefix + 'shown', Lines.Description.Value());
        Observer.Observe(Prefix + 'now', Stored(10000));
    end;

    [Test]
    procedure TP6977B_View_FieldEditable()
    var
        Lines: TestPage "TP R6977B Lines";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        OpenOnFirst(Lines);
        Observer.Observe('before|page', Format(Lines.Editable()));
        Observer.Observe('before|description', Format(Lines.Description.Editable()));
        Observer.Observe('before|lineNo', Format(Lines."Line No.".Editable()));
        Lines.View().Invoke();
        Observer.Observe('after|page', Format(Lines.Editable()));
        Observer.Observe('after|description', Format(Lines.Description.Editable()));
        Observer.Observe('after|lineNo', Format(Lines."Line No.".Editable()));
        Observer.Observe('after|row', Lines."Line No.".Value());
        Lines.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TP6977B_View_SetValue()
    var
        Lines: TestPage "TP R6977B Lines";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        OpenOnFirst(Lines);
        Lines.View().Invoke();
        TypeDescription(Lines, Observer, 'after|');
        Lines.Close();
        Observer.Observe('closed', Stored(10000));
        Observer.Observe('stored', StoredCount());
        Observer.Finish();
    end;

    [Test]
    procedure TP6977B_View_EditViewActions()
    var
        Lines: TestPage "TP R6977B Lines";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        OpenOnFirst(Lines);
        Observer.Observe('before|editVisible', Format(Lines.Edit().Visible()));
        Observer.Observe('before|editEnabled', Format(Lines.Edit().Enabled()));
        Observer.Observe('before|viewVisible', Format(Lines.View().Visible()));
        Observer.Observe('before|viewEnabled', Format(Lines.View().Enabled()));
        Lines.View().Invoke();
        Observer.Observe('after|editVisible', Format(Lines.Edit().Visible()));
        Observer.Observe('after|editEnabled', Format(Lines.Edit().Enabled()));
        Observer.Observe('after|viewVisible', Format(Lines.View().Visible()));
        Observer.Observe('after|viewEnabled', Format(Lines.View().Enabled()));
        Lines.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TP6977B_View_ThenEditInvoke()
    var
        Lines: TestPage "TP R6977B Lines";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        OpenOnFirst(Lines);
        Lines.View().Invoke();
        Lines.Edit().Invoke();
        Observer.Observe('back|page', Format(Lines.Editable()));
        Observer.Observe('back|description', Format(Lines.Description.Editable()));
        Observer.Observe('back|editEnabled', Format(Lines.Edit().Enabled()));
        Observer.Observe('back|viewEnabled', Format(Lines.View().Enabled()));
        Observer.Observe('back|row', Lines."Line No.".Value());
        TypeDescription(Lines, Observer, 'back|');
        Lines.Close();
        Observer.Observe('closed', Stored(10000));
        Observer.Observe('stored', StoredCount());
        Observer.Finish();
    end;
}
