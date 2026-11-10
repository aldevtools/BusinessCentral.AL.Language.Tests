// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own log and OnResolveCaptionClass subscriber 62400 (SingleInstance, used only by test codeunit 62409),
//   tables 62400 to 62402, pages 62400 to 62403, test codeunit 62409
// local object: the CaptionClass expression of the table fields is the thing under test, so the tables and pages are own objects (standing rule 2)
// Probe: al-runner issues 7431 (a field caption whose CaptionClass area is not a number, an app's own area resolved by an
//   OnResolveCaptionClass subscriber, built with StrSubstNo over a label: 'AREA,2,1,, mandatory' and 'AREA,2,1, Fixed ') and 7410 (Caption() read
//   twice on a TestPage control over a table field whose CaptionClass a subscriber resolves).
// Area: a TABLE FIELD CaptionClass whose area is the app's own text, with a static subscriber of Caption Class.OnResolveCaptionClass.
//   Text forms (each read through every reader): the two texts of issue 7431, 'AREA,' (nothing after the comma), 'AREA' (no comma),
//   'AREA,,x', an area with a leading space, with a trailing space, in lower case, with a space inside, an area the subscriber sees but does not
//   claim (with spaces in the rest), an area the subscriber resolves to an empty caption, to a caption with spaces around it, an empty area
//   (',text') and a rest that holds %1.
//   Readers: FieldCaption, FieldRef.Caption, CaptionClassTranslate, a Card control (the open, Caption() twice, FieldCaption after), a List
//   control. Per read: the caption in brackets and every OnResolveCaptionClass call as (area|rest|language), language s = the session language.
//   The literal of issue 7410 on a Card: the open, Caption() twice, a SetValue, Caption() again, Close, a second open, FieldCaption and
//   CaptionClassTranslate of the same text afterwards.
// Neighbours (not repeated here): R6985FieldCaptionArea.al (FieldCaption and FieldRef.Caption of a LITERAL own area, claimed and unclaimed, second
//   read), testpage/W2CaptionClass.al (a PAGE CONTROL's own CaptionClass in an own area), CaptionExpressionPlainText.al (an own area with no
//   subscriber), types/PSCaptionClass.al (CaptionClassTranslate), WcExtFieldAfterResolve.al (OnAfterCaptionClassResolve).
// BC resolves a caption class text once per session, so every reader uses its own texts: '#' in a template becomes the reader's letter.
// Observe form: every test ends with Finish(), which reports the observed values.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 62400 "CCA Own Log"
{
    SingleInstance = true;

    var
        Calls: Text;
        CurrentExpr: Text;
        CurrentTag: Text;

    procedure SetExpr(NewExpr: Text)
    begin
        CurrentExpr := NewExpr;
    end;

    procedure Expr(): Text
    begin
        exit(CurrentExpr);
    end;

    procedure SetTag(NewTag: Text)
    begin
        CurrentTag := NewTag;
    end;

    procedure Tag(): Text
    begin
        exit(CurrentTag);
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Calls;
        Calls := '';
        if Result = '' then
            exit('none');
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure OnResolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    var
        AreaKey: Text;
        LanguageText: Text;
    begin
        AreaKey := CaptionArea.Trim().ToUpper();
        if not (AreaKey.StartsWith('CCAO') or CaptionExpr.Contains('ccao')) then
            exit;
        if Language = GlobalLanguage() then
            LanguageText := 's'
        else
            LanguageText := Format(Language);
        Calls += '(' + CaptionArea + '|' + CaptionExpr + '|' + LanguageText + ')';
        if AreaKey.StartsWith('CCAOC') then begin
            Caption := 'R[' + CaptionExpr + ']';
            Resolved := true;
        end;
        if AreaKey.StartsWith('CCAOE') then begin
            Caption := '';
            Resolved := true;
        end;
        if AreaKey.StartsWith('CCAOS') then begin
            Caption := '  padded ' + CaptionExpr + '  ';
            Resolved := true;
        end;
    end;
}

// One field whose CaptionClass expression gives the text the test set in the log codeunit.
table 62400 "CCA Own Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Dyn; Decimal) { Caption = 'Dyn Caption'; CaptionClass = DynCc(); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    var
        Log: Codeunit "CCA Own Log";

    local procedure DynCc(): Text
    begin
        exit(Log.Expr());
    end;
}

// The shape of al-runner issue 7431: StrSubstNo over a label of the table, and a text that ends with a space.
table 62401 "CCA Own Issue Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Mandatory; Boolean)
        {
            Caption = 'Dimension 1 mandatory';
            CaptionClass = StrSubstNo(MandatoryTxt, 'CCAOC' + Log.Tag() + ',2,1,');
        }
        field(3; "Fixed Value"; Decimal)
        {
            Caption = 'Dimension 1';
            CaptionClass = 'CCAOC' + Log.Tag() + ',2,1, Fixed ';
        }
    }

    keys { key(PK; Id) { Clustered = true; } }

    var
        Log: Codeunit "CCA Own Log";
        MandatoryTxt: Label '%1, mandatory';
}

// The shape of al-runner issue 7410: a literal own area. Field 3 has no control on the card.
table 62402 "CCA Own Literal Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Dimension 1"; Decimal) { CaptionClass = 'CCAOCL,2,1'; }
        field(3; "Not Shown"; Decimal) { CaptionClass = 'CCAOCM,2,1'; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 62400 "CCA Own Card"
{
    PageType = Card;
    SourceTable = "CCA Own Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Dyn; Rec.Dyn) { ApplicationArea = All; }
        }
    }
}

page 62401 "CCA Own List"
{
    PageType = List;
    SourceTable = "CCA Own Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Dyn; Rec.Dyn) { ApplicationArea = All; }
            }
        }
    }
}

page 62402 "CCA Own Issue Card"
{
    PageType = Card;
    SourceTable = "CCA Own Issue Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Mandatory; Rec.Mandatory) { ApplicationArea = All; }
            field(FixedValue; Rec."Fixed Value") { ApplicationArea = All; }
        }
    }
}

page 62403 "CCA Own Literal Card"
{
    PageType = Card;
    SourceTable = "CCA Own Literal Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field("Dimension 1"; Rec."Dimension 1") { ApplicationArea = All; }
        }
    }
}

codeunit 62409 "CCA Own Area Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "CCA Own Log";

    // The text forms of the area. '#' becomes the reader's letter, so no two readers share a text.
    local procedure Template(Index: Integer): Text
    begin
        case Index of
            1:
                exit('CCAOC#,2,1,, mandatory');
            2:
                exit('CCAOC#,2,1, Fixed ');
            3:
                exit('CCAOC#,');
            4:
                exit('CCAOC#');
            5:
                exit('CCAOC#,,x');
            6:
                exit(' CCAOC#,lead');
            7:
                exit('CCAOC# ,trail');
            8:
                exit('ccaoc#,lower');
            9:
                exit('CCAOU#,2,1, unclaimed ');
            10:
                exit('CCAOE#,empty');
            11:
                exit('CCAOS#,spaces');
            12:
                exit(',ccao# noarea');
            13:
                exit('CCAOC#,%1 percent');
            14:
                exit('CCAO C#,space in area');
        end;
    end;

    local procedure ExprText(Index: Integer; Reader: Text): Text
    begin
        exit(Template(Index).Replace('#', Reader));
    end;

    local procedure Seed()
    var
        Row: Record "CCA Own Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    local procedure ReadFieldCaption(Index: Integer; Reader: Text): Text
    var
        Row: Record "CCA Own Row";
        Got: Text;
    begin
        Log.SetExpr(ExprText(Index, Reader));
        Log.Take();
        Got := Row.FieldCaption(Dyn);
        exit('cap=[' + Got + '] ev=' + Log.Take());
    end;

    local procedure ReadFieldRefCaption(Index: Integer; Reader: Text): Text
    var
        RecRef: RecordRef;
        Got: Text;
    begin
        Log.SetExpr(ExprText(Index, Reader));
        RecRef.Open(Database::"CCA Own Row");
        Log.Take();
        Got := RecRef.Field(2).Caption();
        exit('cap=[' + Got + '] ev=' + Log.Take());
    end;

    local procedure ReadTranslate(Index: Integer; Reader: Text): Text
    var
        Got: Text;
    begin
        Log.Take();
        Got := CaptionClassTranslate(ExprText(Index, Reader));
        exit('cap=[' + Got + '] ev=' + Log.Take());
    end;

    local procedure ReadCard(Index: Integer; Reader: Text): Text
    var
        Row: Record "CCA Own Row";
        Card: TestPage "CCA Own Card";
        Got: Text;
        CaptionText: Text;
    begin
        Seed();
        Log.SetExpr(ExprText(Index, Reader));
        Log.Take();
        Card.OpenEdit();
        Got := 'open=' + Log.Take();
        CaptionText := Card.Dyn.Caption();
        Got += ' cap1=[' + CaptionText + '] ev=' + Log.Take();
        CaptionText := Card.Dyn.Caption();
        Got += ' cap2=[' + CaptionText + '] ev=' + Log.Take();
        Card.Close();
        Got += ' close=' + Log.Take();
        CaptionText := Row.FieldCaption(Dyn);
        Got += ' fc=[' + CaptionText + '] ev=' + Log.Take();
        exit(Got);
    end;

    local procedure ReadList(Index: Integer; Reader: Text): Text
    var
        List: TestPage "CCA Own List";
        Got: Text;
        CaptionText: Text;
    begin
        Seed();
        Log.SetExpr(ExprText(Index, Reader));
        Log.Take();
        List.OpenView();
        Got := 'open=' + Log.Take();
        CaptionText := List.Dyn.Caption();
        Got += ' cap1=[' + CaptionText + '] ev=' + Log.Take();
        CaptionText := List.Dyn.Caption();
        Got += ' cap2=[' + CaptionText + '] ev=' + Log.Take();
        List.Close();
        Got += ' close=' + Log.Take();
        exit(Got);
    end;

    [Test]
    procedure OwnArea_FieldCaption_TextForms()
    var
        Observer: Codeunit "Probe Observer";
        Index: Integer;
    begin
        for Index := 1 to 14 do
            Observer.Observe(Format(Index), ReadFieldCaption(Index, 'A'));
        Observer.Expect('1', 'cap=[R[2,1,, mandatory]] ev=(CCAOCA|2,1,, mandatory|s)');
        Observer.Expect('2', 'cap=[R[2,1, Fixed ]] ev=(CCAOCA|2,1, Fixed |s)');
        Observer.Expect('3', 'cap=[R[]] ev=(CCAOCA||s)');
        Observer.Expect('4', 'cap=[CCAOCA] ev=none');
        Observer.Expect('5', 'cap=[R[,x]] ev=(CCAOCA|,x|s)');
        Observer.Expect('6', 'cap=[R[lead]] ev=( CCAOCA|lead|s)');
        Observer.Expect('7', 'cap=[R[trail]] ev=(CCAOCA |trail|s)');
        Observer.Expect('8', 'cap=[R[lower]] ev=(ccaocA|lower|s)');
        Observer.Expect('9', 'cap=[CCAOUA,2,1, unclaimed ] ev=(CCAOUA|2,1, unclaimed |s)');
        Observer.Expect('10', 'cap=[Dyn Caption] ev=(CCAOEA|empty|s)');
        Observer.Expect('11', 'cap=[  padded spaces  ] ev=(CCAOSA|spaces|s)');
        Observer.Expect('12', 'cap=[,ccaoA noarea] ev=(|ccaoA noarea|s)');
        Observer.Expect('13', 'cap=[R[%1 percent]] ev=(CCAOCA|%1 percent|s)');
        Observer.Expect('14', 'cap=[CCAO CA,space in area] ev=(CCAO CA|space in area|s)');
        Observer.Verify();
    end;

    [Test]
    procedure OwnArea_FieldCaption_SecondReadOfTheSameText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('first', ReadFieldCaption(1, 'H'));
        Observer.Observe('second', ReadFieldCaption(1, 'H'));
        Observer.Observe('unclaimed first', ReadFieldCaption(9, 'H'));
        Observer.Observe('unclaimed second', ReadFieldCaption(9, 'H'));
        Observer.Expect('first', 'cap=[R[2,1,, mandatory]] ev=(CCAOCH|2,1,, mandatory|s)');
        Observer.Expect('second', 'cap=[R[2,1,, mandatory]] ev=none');
        Observer.Expect('unclaimed first', 'cap=[CCAOUH,2,1, unclaimed ] ev=(CCAOUH|2,1, unclaimed |s)');
        Observer.Expect('unclaimed second', 'cap=[CCAOUH,2,1, unclaimed ] ev=none');
        Observer.Verify();
    end;

    [Test]
    procedure OwnArea_FieldRefCaption_TextForms()
    var
        Observer: Codeunit "Probe Observer";
        Index: Integer;
    begin
        for Index := 1 to 14 do
            Observer.Observe(Format(Index), ReadFieldRefCaption(Index, 'E'));
        Observer.Expect('1', 'cap=[R[2,1,, mandatory]] ev=(CCAOCE|2,1,, mandatory|s)');
        Observer.Expect('2', 'cap=[R[2,1, Fixed ]] ev=(CCAOCE|2,1, Fixed |s)');
        Observer.Expect('3', 'cap=[R[]] ev=(CCAOCE||s)');
        Observer.Expect('4', 'cap=[CCAOCE] ev=none');
        Observer.Expect('5', 'cap=[R[,x]] ev=(CCAOCE|,x|s)');
        Observer.Expect('6', 'cap=[R[lead]] ev=( CCAOCE|lead|s)');
        Observer.Expect('7', 'cap=[R[trail]] ev=(CCAOCE |trail|s)');
        Observer.Expect('8', 'cap=[R[lower]] ev=(ccaocE|lower|s)');
        Observer.Expect('9', 'cap=[CCAOUE,2,1, unclaimed ] ev=(CCAOUE|2,1, unclaimed |s)');
        Observer.Expect('10', 'cap=[Dyn Caption] ev=(CCAOEE|empty|s)');
        Observer.Expect('11', 'cap=[  padded spaces  ] ev=(CCAOSE|spaces|s)');
        Observer.Expect('12', 'cap=[,ccaoE noarea] ev=(|ccaoE noarea|s)');
        Observer.Expect('13', 'cap=[R[%1 percent]] ev=(CCAOCE|%1 percent|s)');
        Observer.Expect('14', 'cap=[CCAO CE,space in area] ev=(CCAO CE|space in area|s)');
        Observer.Verify();
    end;

    [Test]
    procedure OwnArea_CaptionClassTranslate_TextForms()
    var
        Observer: Codeunit "Probe Observer";
        Index: Integer;
    begin
        for Index := 1 to 14 do
            Observer.Observe(Format(Index), ReadTranslate(Index, 'B'));
        Observer.Expect('1', 'cap=[R[2,1,, mandatory]] ev=(CCAOCB|2,1,, mandatory|s)');
        Observer.Expect('2', 'cap=[R[2,1, Fixed ]] ev=(CCAOCB|2,1, Fixed |s)');
        Observer.Expect('3', 'cap=[R[]] ev=(CCAOCB||s)');
        Observer.Expect('4', 'cap=[CCAOCB] ev=none');
        Observer.Expect('5', 'cap=[R[,x]] ev=(CCAOCB|,x|s)');
        Observer.Expect('6', 'cap=[R[lead]] ev=( CCAOCB|lead|s)');
        Observer.Expect('7', 'cap=[R[trail]] ev=(CCAOCB |trail|s)');
        Observer.Expect('8', 'cap=[R[lower]] ev=(ccaocB|lower|s)');
        Observer.Expect('9', 'cap=[CCAOUB,2,1, unclaimed ] ev=(CCAOUB|2,1, unclaimed |s)');
        Observer.Expect('10', 'cap=[] ev=(CCAOEB|empty|s)');
        Observer.Expect('11', 'cap=[  padded spaces  ] ev=(CCAOSB|spaces|s)');
        Observer.Expect('12', 'cap=[,ccaoB noarea] ev=(|ccaoB noarea|s)');
        Observer.Expect('13', 'cap=[R[%1 percent]] ev=(CCAOCB|%1 percent|s)');
        Observer.Expect('14', 'cap=[CCAO CB,space in area] ev=(CCAO CB|space in area|s)');
        Observer.Verify();
    end;

    [Test]
    procedure OwnArea_CardControl_TextForms1To5()
    var
        Observer: Codeunit "Probe Observer";
        Index: Integer;
    begin
        for Index := 1 to 5 do
            Observer.Observe(Format(Index), ReadCard(Index, 'C'));
        Observer.Expect('1', 'open=(CCAOCC|2,1,, mandatory|s) cap1=[R[2,1,, mandatory]] ev=none cap2=[R[2,1,, mandatory]] ev=none close=none fc=[R[2,1,, mandatory]] ev=none');
        Observer.Expect('2', 'open=(CCAOCC|2,1, Fixed |s) cap1=[R[2,1, Fixed ]] ev=none cap2=[R[2,1, Fixed ]] ev=none close=none fc=[R[2,1, Fixed ]] ev=none');
        Observer.Expect('3', 'open=(CCAOCC||s) cap1=[R[]] ev=none cap2=[R[]] ev=none close=none fc=[R[]] ev=none');
        Observer.Expect('4', 'open=none cap1=[CCAOCC] ev=none cap2=[CCAOCC] ev=none close=none fc=[CCAOCC] ev=none');
        Observer.Expect('5', 'open=(CCAOCC|,x|s) cap1=[R[,x]] ev=none cap2=[R[,x]] ev=none close=none fc=[R[,x]] ev=none');
        Observer.Verify();
    end;

    [Test]
    procedure OwnArea_CardControl_TextForms6To10()
    var
        Observer: Codeunit "Probe Observer";
        Index: Integer;
    begin
        for Index := 6 to 10 do
            Observer.Observe(Format(Index), ReadCard(Index, 'C'));
        Observer.Expect('6', 'open=( CCAOCC|lead|s) cap1=[R[lead]] ev=none cap2=[R[lead]] ev=none close=none fc=[R[lead]] ev=none');
        Observer.Expect('7', 'open=(CCAOCC |trail|s) cap1=[R[trail]] ev=none cap2=[R[trail]] ev=none close=none fc=[R[trail]] ev=none');
        Observer.Expect('8', 'open=(ccaocC|lower|s) cap1=[R[lower]] ev=none cap2=[R[lower]] ev=none close=none fc=[R[lower]] ev=none');
        Observer.Expect('9', 'open=(CCAOUC|2,1, unclaimed |s) cap1=[CCAOUC,2,1, unclaimed ] ev=none cap2=[CCAOUC,2,1, unclaimed ] ev=none close=none fc=[CCAOUC,2,1, unclaimed ] ev=none');
        Observer.Expect('10', 'open=(CCAOEC|empty|s) cap1=[] ev=none cap2=[] ev=none close=none fc=[Dyn Caption] ev=none');
        Observer.Verify();
    end;

    [Test]
    procedure OwnArea_CardControl_TextForms11To14()
    var
        Observer: Codeunit "Probe Observer";
        Index: Integer;
    begin
        for Index := 11 to 14 do
            Observer.Observe(Format(Index), ReadCard(Index, 'C'));
        Observer.Expect('11', 'open=(CCAOSC|spaces|s) cap1=[  padded spaces  ] ev=none cap2=[  padded spaces  ] ev=none close=none fc=[  padded spaces  ] ev=none');
        Observer.Expect('12', 'open=(|ccaoC noarea|s) cap1=[,ccaoC noarea] ev=none cap2=[,ccaoC noarea] ev=none close=none fc=[,ccaoC noarea] ev=none');
        Observer.Expect('13', 'open=(CCAOCC|%1 percent|s) cap1=[R[%1 percent]] ev=none cap2=[R[%1 percent]] ev=none close=none fc=[R[%1 percent]] ev=none');
        Observer.Expect('14', 'open=(CCAO CC|space in area|s) cap1=[CCAO CC,space in area] ev=none cap2=[CCAO CC,space in area] ev=none close=none fc=[CCAO CC,space in area] ev=none');
        Observer.Verify();
    end;

    [Test]
    procedure OwnArea_ListControl_TextForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1', ReadList(1, 'D'));
        Observer.Observe('2', ReadList(2, 'D'));
        Observer.Observe('3', ReadList(3, 'D'));
        Observer.Observe('4', ReadList(4, 'D'));
        Observer.Observe('9', ReadList(9, 'D'));
        Observer.Observe('10', ReadList(10, 'D'));
        Observer.Expect('1', 'open=(CCAOCD|2,1,, mandatory|s) cap1=[R[2,1,, mandatory]] ev=none cap2=[R[2,1,, mandatory]] ev=none close=none');
        Observer.Expect('2', 'open=(CCAOCD|2,1, Fixed |s) cap1=[R[2,1, Fixed ]] ev=none cap2=[R[2,1, Fixed ]] ev=none close=none');
        Observer.Expect('3', 'open=(CCAOCD||s) cap1=[R[]] ev=none cap2=[R[]] ev=none close=none');
        Observer.Expect('4', 'open=none cap1=[CCAOCD] ev=none cap2=[CCAOCD] ev=none close=none');
        Observer.Expect('9', 'open=(CCAOUD|2,1, unclaimed |s) cap1=[CCAOUD,2,1, unclaimed ] ev=none cap2=[CCAOUD,2,1, unclaimed ] ev=none close=none');
        Observer.Expect('10', 'open=(CCAOED|empty|s) cap1=[] ev=none cap2=[] ev=none close=none');
        Observer.Verify();
    end;

    // al-runner issue 7431: FieldCaption of the two fields, read twice.
    [Test]
    procedure OwnArea_Issue7431_FieldCaption_StrSubstNoOverLabel()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CCA Own Issue Row";
        Got: Text;
    begin
        Log.SetTag('F');
        Log.Take();
        Got := Row.FieldCaption(Mandatory);
        Observer.Observe('mandatory', '[' + Got + '] ev=' + Log.Take());
        Got := Row.FieldCaption("Fixed Value");
        Observer.Observe('fixed', '[' + Got + '] ev=' + Log.Take());
        Got := Row.FieldCaption(Mandatory);
        Observer.Observe('mandatory again', '[' + Got + '] ev=' + Log.Take());
        Got := Row.FieldCaption("Fixed Value");
        Observer.Observe('fixed again', '[' + Got + '] ev=' + Log.Take());
        Observer.Expect('mandatory', '[R[2,1,, mandatory]] ev=(CCAOCF|2,1,, mandatory|s)');
        Observer.Expect('fixed', '[R[2,1, Fixed ]] ev=(CCAOCF|2,1, Fixed |s)');
        Observer.Expect('mandatory again', '[R[2,1,, mandatory]] ev=none');
        Observer.Expect('fixed again', '[R[2,1, Fixed ]] ev=none');
        Observer.Verify();
    end;

    // al-runner issue 7431: a card that shows the two fields.
    [Test]
    procedure OwnArea_Issue7431_Card_StrSubstNoOverLabel()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CCA Own Issue Row";
        Card: TestPage "CCA Own Issue Card";
        Got: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.SetTag('G');
        Log.Take();
        Card.OpenEdit();
        Observer.Observe('open', Log.Take());
        Got := Card.Mandatory.Caption();
        Observer.Observe('mandatory', '[' + Got + '] ev=' + Log.Take());
        Got := Card.FixedValue.Caption();
        Observer.Observe('fixed', '[' + Got + '] ev=' + Log.Take());
        Got := Card.Mandatory.Caption();
        Observer.Observe('mandatory again', '[' + Got + '] ev=' + Log.Take());
        Got := Card.FixedValue.Caption();
        Observer.Observe('fixed again', '[' + Got + '] ev=' + Log.Take());
        Card.Mandatory.SetValue(true);
        Observer.Observe('after SetValue', Log.Take());
        Got := Card.Mandatory.Caption();
        Observer.Observe('mandatory after SetValue', '[' + Got + '] ev=' + Log.Take());
        Card.Close();
        Observer.Observe('close', Log.Take());
        Got := Row.FieldCaption(Mandatory);
        Observer.Observe('FieldCaption after the page', '[' + Got + '] ev=' + Log.Take());
        Observer.Expect('open', '(CCAOCG|2,1,, mandatory|s)(CCAOCG|2,1, Fixed |s)');
        Observer.Expect('mandatory', '[R[2,1,, mandatory]] ev=none');
        Observer.Expect('fixed', '[R[2,1, Fixed ]] ev=none');
        Observer.Expect('mandatory again', '[R[2,1,, mandatory]] ev=none');
        Observer.Expect('fixed again', '[R[2,1, Fixed ]] ev=none');
        Observer.Expect('after SetValue', 'none');
        Observer.Expect('mandatory after SetValue', '[R[2,1,, mandatory]] ev=none');
        Observer.Expect('close', 'none');
        Observer.Expect('FieldCaption after the page', '[R[2,1,, mandatory]] ev=none');
        Observer.Verify();
    end;

    // al-runner issue 7410: Caption() read twice on the control of a field with a literal own area.
    [Test]
    procedure OwnArea_Issue7410_Card_LiteralCaptionReadTwice()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CCA Own Literal Row";
        Card: TestPage "CCA Own Literal Card";
        Got: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Take();
        Card.OpenEdit();
        Observer.Observe('open', Log.Take());
        Got := Card."Dimension 1".Caption();
        Observer.Observe('first read', '[' + Got + '] ev=' + Log.Take());
        Got := Card."Dimension 1".Caption();
        Observer.Observe('second read', '[' + Got + '] ev=' + Log.Take());
        Card."Dimension 1".SetValue(5);
        Observer.Observe('after SetValue', Log.Take());
        Got := Card."Dimension 1".Caption();
        Observer.Observe('read after SetValue', '[' + Got + '] ev=' + Log.Take());
        Card.Close();
        Observer.Observe('close', Log.Take());
        Card.OpenView();
        Observer.Observe('second open', Log.Take());
        Got := Card."Dimension 1".Caption();
        Observer.Observe('read on the second open', '[' + Got + '] ev=' + Log.Take());
        Card.Close();
        Log.Take();
        Got := Row.FieldCaption("Dimension 1");
        Observer.Observe('FieldCaption after the page', '[' + Got + '] ev=' + Log.Take());
        Got := Row.FieldCaption("Not Shown");
        Observer.Observe('FieldCaption of the field without a control', '[' + Got + '] ev=' + Log.Take());
        Got := CaptionClassTranslate('CCAOCL,2,1');
        Observer.Observe('CaptionClassTranslate of the same text', '[' + Got + '] ev=' + Log.Take());
        Observer.Expect('open', '(CCAOCL|2,1|s)(CCAOCM|2,1|s)');
        Observer.Expect('first read', '[R[2,1]] ev=none');
        Observer.Expect('second read', '[R[2,1]] ev=none');
        Observer.Expect('after SetValue', 'none');
        Observer.Expect('read after SetValue', '[R[2,1]] ev=none');
        Observer.Expect('close', 'none');
        Observer.Expect('second open', 'none');
        Observer.Expect('read on the second open', '[R[2,1]] ev=none');
        Observer.Expect('FieldCaption after the page', '[R[2,1]] ev=none');
        Observer.Expect('FieldCaption of the field without a control', '[R[2,1]] ev=none');
        Observer.Expect('CaptionClassTranslate of the same text', '[R[2,1]] ev=none');
        Observer.Verify();
    end;
}
