// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-view-method
// Scope: in-scope
// Fixtures used: Assert (60021); own objects 96060 - 96062 (TP R6977B *)
// local object: a List with no CardPageId, so the built-in View switches the list itself
// Probe: follow-up of al-runner issue 6977 (testpage/R6977ListViewNext.al pins the First/Next walk). An editable List with no card page over
//   2 rows, opened by TestPage.OpenEdit on the first row, then View().Invoke(). Measured after the switch: Editable of a field (and of the
//   page), SetValue on a field (typed without asserterror, as testpage/TestPageReadOnlySetValue.al does: the error text, the validation
//   error count, what the field shows, what is stored), Visible and Enabled of the built-in Edit and View actions, and Edit().Invoke() back
//   (Editable and SetValue after it). Each test also observes the same reads before View as the contrast.
// Result (BC 27.5, 28.5 and 29.0 alike): after View().Invoke() the page and its fields are not Editable (Yes before), yet SetValue on
//   Description raises no error, leaves 0 validation errors, shows the typed value and does not change the stored row until the page closes,
//   then the typed value is stored (nothing is inserted: 2 rows). Edit is enabled and View disabled after View (the reverse before).
//   Edit().Invoke() afterwards makes the page and fields Editable again and SetValue behaves the same.
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

    local procedure Observe(Name: Text; Shown: Text): Text
    begin
        exit(Name + '=' + Shown + ';');
    end;

    local procedure OpenOnFirst(var Lines: TestPage "TP R6977B Lines")
    begin
        Lines.OpenEdit();
        Lines.First();
    end;

    local procedure TypeDescription(var Lines: TestPage "TP R6977B Lines"; var Log: Text; Prefix: Text)
    begin
        ClearLastError();
        Lines.Description.SetValue('x');
        Log += Observe(Prefix + 'err', GetLastErrorText());
        Log += Observe(Prefix + 'valErrs', Format(Lines.ValidationErrorCount()));
        Log += Observe(Prefix + 'shown', Lines.Description.Value());
        Log += Observe(Prefix + 'now', Stored(10000));
    end;

    [Test]
    procedure TP6977B_View_FieldEditable()
    var
        Lines: TestPage "TP R6977B Lines";
        Log: Text;
        Assert: Codeunit Assert;
    begin
        Initialize();
        OpenOnFirst(Lines);
        Log += Observe('before|page', Format(Lines.Editable()));
        Log += Observe('before|description', Format(Lines.Description.Editable()));
        Log += Observe('before|lineNo', Format(Lines."Line No.".Editable()));
        Lines.View().Invoke();
        Log += Observe('after|page', Format(Lines.Editable()));
        Log += Observe('after|description', Format(Lines.Description.Editable()));
        Log += Observe('after|lineNo', Format(Lines."Line No.".Editable()));
        Log += Observe('after|row', Lines."Line No.".Value());
        Lines.Close();
        Assert.AreEqual('before|page=Yes;before|description=Yes;before|lineNo=Yes;after|page=No;after|description=No;after|lineNo=No;after|row=10000;', Log, 'FieldEditable');
    end;

    [Test]
    procedure TP6977B_View_SetValue()
    var
        Lines: TestPage "TP R6977B Lines";
        Log: Text;
        Assert: Codeunit Assert;
    begin
        Initialize();
        OpenOnFirst(Lines);
        Lines.View().Invoke();
        TypeDescription(Lines, Log, 'after|');
        Lines.Close();
        Log += Observe('closed', Stored(10000));
        Log += Observe('stored', StoredCount());
        Assert.AreEqual('after|err=;after|valErrs=0;after|shown=x;after|now=a;closed=x;stored=2;', Log, 'View_SetValue');
    end;

    [Test]
    procedure TP6977B_View_EditViewActions()
    var
        Lines: TestPage "TP R6977B Lines";
        Log: Text;
        Assert: Codeunit Assert;
    begin
        Initialize();
        OpenOnFirst(Lines);
        Log += Observe('before|editVisible', Format(Lines.Edit().Visible()));
        Log += Observe('before|editEnabled', Format(Lines.Edit().Enabled()));
        Log += Observe('before|viewVisible', Format(Lines.View().Visible()));
        Log += Observe('before|viewEnabled', Format(Lines.View().Enabled()));
        Lines.View().Invoke();
        Log += Observe('after|editVisible', Format(Lines.Edit().Visible()));
        Log += Observe('after|editEnabled', Format(Lines.Edit().Enabled()));
        Log += Observe('after|viewVisible', Format(Lines.View().Visible()));
        Log += Observe('after|viewEnabled', Format(Lines.View().Enabled()));
        Lines.Close();
        Assert.AreEqual('before|editVisible=Yes;before|editEnabled=No;before|viewVisible=Yes;before|viewEnabled=Yes;after|editVisible=Yes;after|editEnabled=Yes;after|viewVisible=Yes;after|viewEnabled=No;', Log, 'EditViewActions');
    end;

    [Test]
    procedure TP6977B_View_ThenEditInvoke()
    var
        Lines: TestPage "TP R6977B Lines";
        Log: Text;
        Assert: Codeunit Assert;
    begin
        Initialize();
        OpenOnFirst(Lines);
        Lines.View().Invoke();
        Lines.Edit().Invoke();
        Log += Observe('back|page', Format(Lines.Editable()));
        Log += Observe('back|description', Format(Lines.Description.Editable()));
        Log += Observe('back|editEnabled', Format(Lines.Edit().Enabled()));
        Log += Observe('back|viewEnabled', Format(Lines.View().Enabled()));
        Log += Observe('back|row', Lines."Line No.".Value());
        TypeDescription(Lines, Log, 'back|');
        Lines.Close();
        Log += Observe('closed', Stored(10000));
        Log += Observe('stored', StoredCount());
        Assert.AreEqual('back|page=Yes;back|description=Yes;back|editEnabled=No;back|viewEnabled=Yes;back|row=10000;back|err=;back|valErrs=0;back|shown=x;back|now=a;closed=x;stored=2;', Log, 'ThenEditInvoke');
    end;
}
