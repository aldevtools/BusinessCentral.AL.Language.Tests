// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Assert (60021), TPEDO Kind (67485), TPEDO Kind Ext (67485), TPEDO Row (67485),
//                TPEDO Card (67985) -- and Base Application page 682 "Schedule a Report" with
//                enum "Job Queue Report Output Type", both of which ship PRECOMPILED.
//
// CLAIM: a TestPage field bound to an Enum answers Value() with the caption of the member the
// record HOLDS, and SetValue(<caption>) stores that caption's own ordinal -- also when the enum's
// declared order is not its ordinal order (base value(4) declared before extension values 0..2).
// Real BC looks the ordinal up, never its position in the declared list.
//
// Two arms: an enum this app declares (source-compiled), and a precompiled Base Application enum
// of the same shape on a precompiled page. The precompiled arm fills the page's temporary row the
// way codeunit 67403 does -- a manually bound OnGetReportDescription subscriber assigns the output
// type without validating it, because the field's OnValidate reaches printer and SaaS logic this
// test is not about. It closes through Cancel: an OK close would enqueue a job queue entry.
//
// Written by agent stma-auto2-2, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4788. The expected
// values were written before any BC service tier ran them; this pull request's CI is the first
// real-BC measurement.

codeunit 67520 "TPEDO Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure InsertRow(RowCode: Code[10]; Kind: Enum "TPEDO Kind")
    var
        Row: Record "TPEDO Row";
    begin
        Row.DeleteAll();
        Row."Code" := RowCode;
        Row.Kind := Kind;
        Row.Insert();
    end;

    local procedure ShownKind(RowCode: Code[10]) Shown: Text
    var
        Row: Record "TPEDO Row";
        Card: TestPage "TPEDO Card";
    begin
        Row.Get(RowCode);
        Card.OpenView();
        Card.GoToRecord(Row);
        Shown := Card.Kind.Value();
        Card.Close();
    end;

    [Test]
    procedure DeclaredOutOfOrder_ExtensionValue_ValueShowsItsOwnCaption()
    begin
        InsertRow('A', Enum::"TPEDO Kind"::Beta);

        Assert.AreEqual('Beta caption', ShownKind('A'),
            'Value() must show the caption of the held member Beta (ordinal 1), not the member declared before it');
    end;

    [Test]
    procedure DeclaredOutOfOrder_BaseValue_ValueShowsItsOwnCaption()
    begin
        InsertRow('A', Enum::"TPEDO Kind"::Zulu);

        Assert.AreEqual('Zulu caption', ShownKind('A'),
            'Value() must show the caption of the held member Zulu (ordinal 4, declared first)');
    end;

    [Test]
    procedure DeclaredOutOfOrder_SetValueByCaption_StoresThatMembersOrdinal()
    var
        Row: Record "TPEDO Row";
        Card: TestPage "TPEDO Card";
    begin
        InsertRow('A', Enum::"TPEDO Kind"::Zulu);
        Row.Get('A');

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Kind.SetValue('Gamma caption');
        Card.Close();

        Row.Get('A');
        Assert.AreEqual(Enum::"TPEDO Kind"::Gamma, Row.Kind,
            'SetValue(''Gamma caption'') must store Gamma (ordinal 2), not the member at position 2 of the declared list');
    end;

    [Test]
    procedure DeclaredOutOfOrder_SetValueAnUndeclaredCaption_IsRefused()
    var
        Row: Record "TPEDO Row";
        Card: TestPage "TPEDO Card";
    begin
        InsertRow('A', Enum::"TPEDO Kind"::Zulu);
        Row.Get('A');

        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.Kind.SetValue('Delta caption');

        // No member is captioned 'Delta caption', so the entry is refused and names itself.
        Assert.ExpectedError('Delta caption');
    end;

    local procedure ShownOutputType(OutputType: Enum "Job Queue Report Output Type") Shown: Text
    var
        OutputTypeSetter: Codeunit "TPEDO Output Type Setter";
        ScheduleAReportPage: Page "Schedule a Report";
        ScheduleAReport: TestPage "Schedule a Report";
        PreviousAreas: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');
        OutputTypeSetter.SetOutputType(OutputType);
        BindSubscription(OutputTypeSetter);

        ScheduleAReportPage.SetParameters(Report::"Customer - List", '');
        ScheduleAReport.Trap();
        ScheduleAReportPage.Run();
        Shown := ScheduleAReport."Report Output Type".Value();
        ScheduleAReport.Cancel().Invoke();

        UnbindSubscription(OutputTypeSetter);
        ApplicationArea(PreviousAreas);
    end;

    [Test]
    procedure PrecompiledDeclaredOutOfOrder_Print_ValueShowsPrint()
    begin
        Assert.AreEqual(Format(Enum::"Job Queue Report Output Type"::Print),
            ShownOutputType(Enum::"Job Queue Report Output Type"::Print),
            'Value() of "Report Output Type" must show the held member Print');
    end;

    [Test]
    procedure PrecompiledDeclaredOutOfOrder_Pdf_ValueShowsPdf()
    begin
        Assert.AreEqual(Format(Enum::"Job Queue Report Output Type"::PDF),
            ShownOutputType(Enum::"Job Queue Report Output Type"::PDF),
            'Value() of "Report Output Type" must show the held member PDF');
    end;

    [Test]
    procedure PrecompiledDeclaredOutOfOrder_Excel_ValueShowsExcel()
    begin
        Assert.AreEqual(Format(Enum::"Job Queue Report Output Type"::Excel),
            ShownOutputType(Enum::"Job Queue Report Output Type"::Excel),
            'Value() of "Report Output Type" must show the held member Excel');
    end;
}

codeunit 67521 "TPEDO Output Type Setter"
{
    EventSubscriberInstance = Manual;

    var
        OutputTypeToSet: Enum "Job Queue Report Output Type";

    procedure SetOutputType(OutputType: Enum "Job Queue Report Output Type")
    begin
        OutputTypeToSet := OutputType;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Schedule a Report", 'OnGetReportDescription', '', false, false)]
    local procedure AssignOutputTypeBeforeInsert(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry."Report Output Type" := OutputTypeToSet;
    end;
}
