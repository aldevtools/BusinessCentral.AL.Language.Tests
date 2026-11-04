// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-user-interface
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), TP Field Visible Card (page),
//                ASK Card (60920), ASK Header (60915), ASK Line (60916), shared Assert (60021);
//                self-contained page 68165 and codeunit 68164; its own log codeunit 68166 "Probe TestPage Log"
// Probe: written against a real BC 27.5 service tier (en-US, UTC); every literal below is what that
// tier produced. Other BC versions were not measured.
//
// Pins what a TestPage shows and raises: the text of a Guid, a negative Duration and a Decimal with
// each BlankNumbers value, the number of rows a list reads when it opens, that SetValue of the value a
// field already holds still runs OnValidate, what OnInsertRecord gets as BelowxRec for a row added with
// New(), and the full texts and codes of the TestPage errors (field or part not on the page, key
// arity, row not found, GetValidationError with index 0).
// BC versions: 27.5

codeunit 68166 "Probe TestPage Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

page 68165 "Probe TP List"
{
    PageType = List;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Text Field"; Rec."Text Field")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        PageLog.Add('TextField.OnValidate');
                    end;
                }
                field("Guid Field"; Rec."Guid Field") { ApplicationArea = All; }
                field("Duration Field"; Rec."Duration Field") { ApplicationArea = All; }
                field(BlankNeg; Rec."Decimal Field") { ApplicationArea = All; BlankNumbers = BlankNeg; }
                field(BlankNegAndZero; Rec."Decimal Field") { ApplicationArea = All; BlankNumbers = BlankNegAndZero; }
                field(BlankZero; Rec."Decimal Field") { ApplicationArea = All; BlankNumbers = BlankZero; }
                field(BlankPos; Rec."Decimal Field") { ApplicationArea = All; BlankNumbers = BlankPos; }
                field(BlankZeroAndPos; Rec."Decimal Field") { ApplicationArea = All; BlankNumbers = BlankZeroAndPos; }
                field(Plain; Rec."Decimal Field") { ApplicationArea = All; }
                field(Mandatory; Rec."Amount Field") { ApplicationArea = All; ShowMandatory = true; }
            }
        }
    }

    var
        PageLog: Codeunit "Probe TestPage Log";

    trigger OnAfterGetRecord()
    begin
        PageLog.Add('AGR(' + Format(Rec."Entry No.") + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        PageLog.Add('OnInsertRecord(below=' + Format(BelowxRec) + ')');
        exit(true);
    end;
}

codeunit 68164 "Probe TestPage Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        PageLog: Codeunit "Probe TestPage Log";

    local procedure Initialize()
    var
        ALTUniversal: Record "ALT Universal";
        EntryNo: Integer;
    begin
        Cleanup.Initialize();
        for EntryNo := 1 to 60 do begin
            ALTUniversal.Init();
            ALTUniversal."Entry No." := EntryNo;
            ALTUniversal."Text Field" := 'row' + Format(EntryNo);
            ALTUniversal."Amount Field" := EntryNo;
            case EntryNo of
                1:
                    begin
                        ALTUniversal."Decimal Field" := -5;
                        ALTUniversal."Duration Field" := -90061001;
                        Evaluate(ALTUniversal."Guid Field", '{ABCDEF01-2345-6789-ABCD-EF0123456789}');
                    end;
                2:
                    ALTUniversal."Decimal Field" := 0;
                3:
                    ALTUniversal."Decimal Field" := 7;
            end;
            ALTUniversal.Insert();
        end;
        Commit();
        PageLog.Take();
    end;

    local procedure CountOf(Entries: Text; Marker: Text): Integer
    var
        Parts: List of [Text];
    begin
        Parts := Entries.Split(Marker);
        exit(Parts.Count() - 1);
    end;

    [Test]
    procedure TestPage_List_OpenReads21Rows()
    var
        List: TestPage "Probe TP List";
        Entries: Text;
    begin
        Initialize();

        List.OpenView();
        Entries := PageLog.Take();

        Assert.AreEqual(21, CountOf(Entries, 'AGR('), 'rows read when the list opens');
        Assert.IsTrue(Entries.StartsWith('AGR(1);AGR(2);AGR(3);'), 'in key order from the first row: ' + Entries);
        List.Close();
    end;

    [Test]
    procedure TestPage_Control_Texts_GuidDurationAndBlankNumbers()
    var
        List: TestPage "Probe TP List";
    begin
        Initialize();
        List.OpenView();

        List.GoToKey(1);
        Assert.AreEqual('{abcdef01-2345-6789-abcd-ef0123456789}', List."Guid Field".Value(), 'a Guid is lower case in braces');
        Assert.AreEqual('-1 day -1 hour -1 minute -1 second -1 millisecond', List."Duration Field".Value(), 'a negative Duration: every unit is negative');
        Assert.AreEqual('', List.BlankNeg.Value(), 'BlankNeg of -5');
        Assert.AreEqual('', List.BlankNegAndZero.Value(), 'BlankNegAndZero of -5');
        Assert.AreEqual('-5.00', List.BlankZero.Value(), 'BlankZero of -5');
        Assert.AreEqual('-5.00', List.BlankPos.Value(), 'BlankPos of -5');
        Assert.AreEqual('-5.00', List.BlankZeroAndPos.Value(), 'BlankZeroAndPos of -5');
        Assert.AreEqual('-5.00', List.Plain.Value(), 'no BlankNumbers');

        List.GoToKey(2);
        Assert.AreEqual('0.00', List.BlankNeg.Value(), 'BlankNeg of 0');
        Assert.AreEqual('', List.BlankNegAndZero.Value(), 'BlankNegAndZero of 0');
        Assert.AreEqual('', List.BlankZero.Value(), 'BlankZero of 0');
        Assert.AreEqual('0.00', List.BlankPos.Value(), 'BlankPos of 0');
        Assert.AreEqual('', List.BlankZeroAndPos.Value(), 'BlankZeroAndPos of 0');

        List.GoToKey(3);
        Assert.AreEqual('7.00', List.BlankNeg.Value(), 'BlankNeg of 7');
        Assert.AreEqual('7.00', List.BlankNegAndZero.Value(), 'BlankNegAndZero of 7');
        Assert.AreEqual('7.00', List.BlankZero.Value(), 'BlankZero of 7');
        Assert.AreEqual('', List.BlankPos.Value(), 'BlankPos of 7');
        Assert.AreEqual('', List.BlankZeroAndPos.Value(), 'BlankZeroAndPos of 7');

        Assert.IsTrue(List.Mandatory.ShowMandatory(), 'ShowMandatory');
        Assert.IsFalse(List.IsExpanded(), 'IsExpanded on a list');
        List.Close();
    end;

    [Test]
    procedure TestPage_SetValue_OfTheValueAlreadyHeld_StillRunsOnValidate()
    var
        List: TestPage "Probe TP List";
    begin
        Initialize();
        List.OpenEdit();
        List.GoToKey(5);
        PageLog.Take();

        List."Text Field".SetValue('row5');
        Assert.IsTrue(PageLog.Take().Contains('TextField.OnValidate;'), 'OnValidate ran for the same value');

        List."Text Field".SetValue('changed');
        Assert.AreEqual('TextField.OnValidate;', PageLog.Take(), 'and for a new value');
        List.Close();
    end;

    [Test]
    procedure TestPage_New_AtTheEnd_PassesBelowxRecTrueToOnInsertRecord()
    var
        List: TestPage "Probe TP List";
    begin
        Initialize();
        List.OpenEdit();
        List.New();
        List."Entry No.".SetValue(100);
        PageLog.Take();

        List.Close();

        Assert.AreEqual('OnInsertRecord(below=Yes);', PageLog.Take(), 'the row is saved when the page closes');
    end;

    [Test]
    procedure TestPage_GetValidationError_Index0_Throws()
    var
        List: TestPage "Probe TP List";
        Message: Text;
    begin
        Initialize();
        List.OpenEdit();

        asserterror Message := List.GetValidationError(0);

        Assert.AreEqual('Index out of bounds.', GetLastErrorText(), 'text');
        Assert.AreEqual('IndexOutOfBounds', GetLastErrorCode(), 'code');
        List.Close();
    end;

    [Test]
    procedure TestPage_FieldNotOnThePage_FullTextShapeAndCode()
    // CLAIM: "The field with ID = <n> is not found on the page." with code TestFieldNotFound; the id is generated.
    var
        Card: TestPage "TP Field Visible Card";
        Dummy: Boolean;
        Text: Text;
        IdText: Text;
        Id: Integer;
    begin
        Initialize();
        Card.OpenEdit();

        asserterror Dummy := Card.FieldInStaticHiddenGroup.Visible();

        Text := GetLastErrorText();
        Assert.IsTrue(Text.StartsWith('The field with ID = '), 'prefix: ' + Text);
        Assert.IsTrue(Text.EndsWith(' is not found on the page.'), 'suffix: ' + Text);
        IdText := Text.Substring(StrLen('The field with ID = ') + 1);
        IdText := IdText.Substring(1, StrLen(IdText) - StrLen(' is not found on the page.'));
        Assert.IsTrue(Evaluate(Id, IdText), 'the id is a number: ' + IdText);
        Assert.AreEqual('TestFieldNotFound', GetLastErrorCode(), 'code');
        Card.Close();
    end;

    [Test]
    procedure TestPage_GetField_WithAnIdThatIsNotThere_NamesTheId()
    var
        Card: TestPage "ASK Card";
        Value: Text;
    begin
        Initialize();
        Card.OpenEdit();

        asserterror Value := Card.GetField(99999).Value();
        Assert.AreEqual('The field with ID = 99999 is not found on the page.', GetLastErrorText(), 'on the page');
        Assert.AreEqual('TestFieldNotFound', GetLastErrorCode(), 'code');

        asserterror Value := Card.Lines.GetField(1).Value();
        Assert.AreEqual('The field with ID = 1 is not found on the page.', GetLastErrorText(), 'on the part: a table field number is not a control id');
        Card.Close();
    end;

    [Test]
    procedure TestPart_GoToKey_Arity_AndMissingKey()
    var
        Card: TestPage "ASK Card";
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        Found: Boolean;
    begin
        Initialize();
        Line.DeleteAll();
        Header.DeleteAll();
        Header.Init();
        Header."No." := 'H1';
        Header.Insert();
        Line.Init();
        Line."No." := 'H1';
        Line."Line No." := 10000;
        Line.Insert();
        Commit();
        Card.OpenEdit();
        Card.GoToKey('H1');

        asserterror Card.Lines.GoToKey('H1');
        Assert.AreEqual('The number of arguments does not match the number of primary key fields.', GetLastErrorText(), 'arity');
        Assert.AreEqual('TestInvalidNumberOfKeyFieldValues', GetLastErrorCode(), 'arity code');

        Found := Card.Lines.GoToKey('H1', 99999);
        Assert.IsFalse(Found, 'a missing key with the result used');

        asserterror Card.Lines.GoToKey('H1', 99999);
        Assert.AreEqual('The row does not exist on the TestPage.', GetLastErrorText(), 'a missing key with the result discarded');
        Assert.AreEqual('TestRowNotFound', GetLastErrorCode(), 'code');
        Card.Close();
    end;

    local procedure Rows(Entries: Text): Text
    var
        Parts: List of [Text];
        Part: Text;
        Result: Text;
    begin
        Parts := Entries.Split(';');
        foreach Part in Parts do
            if Part <> '' then
                Result += Part.Replace('AGR(', '').Replace(')', '') + ' ';
        exit(Result);
    end;

    [Test]
    procedure TestPage_List_Window_IsRepopulatedAroundAGoToKeyOutsideIt()
    // CLAIM: opening reads rows 1-20 and then the current row again; a GoToKey inside the window reads nothing; one outside reads a new window of about 22 rows starting 11 before the target; rows already read are not read again.
    var
        List: TestPage "Probe TP List";
    begin
        Initialize();
        PageLog.Take();

        List.OpenView();
        Assert.AreEqual('1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 1 ', Rows(PageLog.Take()), 'open');

        List.GoToKey(3);
        Assert.AreEqual('', Rows(PageLog.Take()), 'inside the window');

        List.GoToKey(30);
        Assert.AreEqual('19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 ', Rows(PageLog.Take()), 'row 30');

        List.GoToKey(60);
        Assert.AreEqual('39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 59 60 ', Rows(PageLog.Take()), 'row 60 (the last row, read twice at the end)');

        List.GoToKey(2);
        Assert.AreEqual('', Rows(PageLog.Take()), 'going back to a row that was read');
        List.Last();
        List.First();
        Assert.AreEqual('', Rows(PageLog.Take()), 'Last and First');
        Assert.IsFalse(List.GoToKey(999), 'a miss');
        Assert.AreEqual('', Rows(PageLog.Take()), 'a miss reads nothing');
        List.Close();
    end;
}
