// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-user-interface
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/controls/devenv-systempart-control
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68330, log codeunit 68331, pages 68332..68334
//                and codeunit 68335
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins (1) that a page with systempart controls (Links, Notes, Outlook, MyNotes, also one with
// Visible = false) opens as a card and as a list, reads its fields and moves between rows; the
// compiler gives a TestPage no member for a systempart (AL0132 "does not contain a definition"), so a
// test cannot read, hide or call one; and (2) which rows a list reads when GoToKey goes outside the
// rows read so far.
//
// The window: opening reads rows 1-20 and then the current row again. A GoToKey beyond the rows read
// reads on in blocks of 20 rows, each block preceded by the last two rows of the block before; the first
// block starts at row 19. A GoToKey of a row already read reads nothing. A miss reads on to the end of
// the table and then reads the last two rows again.
// BC versions: 27.5

table 68330 "Probe Win Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68331 "Probe Win Log"
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

page 68332 "Probe Win List"
{
    PageType = List;
    SourceTable = "Probe Win Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }

    var
        WinLog: Codeunit "Probe Win Log";

    trigger OnAfterGetRecord()
    begin
        WinLog.Add(Format(Rec.Id));
    end;
}

page 68333 "Probe SysPart Card"
{
    PageType = Card;
    SourceTable = "Probe Win Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            systempart(LinksPart; Links) { ApplicationArea = All; }
            systempart(NotesPart; Notes) { ApplicationArea = All; }
            systempart(OutlookPart; Outlook) { ApplicationArea = All; }
            systempart(MyNotesPart; MyNotes) { ApplicationArea = All; }
            systempart(HiddenNotes; Notes) { ApplicationArea = All; Visible = false; }
        }
    }
}

page 68334 "Probe SysPart List"
{
    PageType = List;
    SourceTable = "Probe Win Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            systempart(LinksPart; Links) { ApplicationArea = All; }
            systempart(NotesPart; Notes) { ApplicationArea = All; }
        }
    }
}

codeunit 68335 "Probe Page Window"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        WinLog: Codeunit "Probe Win Log";

    local procedure Seed(RowCount: Integer)
    var
        WinTable: Record "Probe Win Table";
        Index: Integer;
    begin
        WinTable.DeleteAll();
        for Index := 1 to RowCount do begin
            WinTable.Id := Index;
            WinTable.Txt := 'row' + Format(Index);
            WinTable.Insert();
        end;
        Commit();
        WinLog.Take();
    end;

    [Test]
    procedure PageWithSystemParts_OpensAsCardAndAsList_FieldsStayReadable()
    var
        Card: TestPage "Probe SysPart Card";
        List: TestPage "Probe SysPart List";
    begin
        Seed(3);

        Card.OpenEdit();
        Card.GoToKey(2);
        Assert.AreEqual('row2', Card.Txt.Value(), 'card field');
        Card.Close();

        List.OpenView();
        Assert.IsTrue(List.GoToKey(3), 'list row');
        Assert.AreEqual('3', List.Id.Value(), 'list field');
        List.Close();
    end;

    local procedure RowsRead(Target: Integer; var AfterOpen: Text): Text
    var
        List: TestPage "Probe Win List";
        Found: Boolean;
        Result: Text;
    begin
        List.OpenView();
        AfterOpen := WinLog.Take();
        Found := List.GoToKey(Target);
        Result := WinLog.Take() + 'found=' + Format(Found);
        List.Close();
        exit(Result);
    end;

    [Test]
    procedure List_Window_AfterGoToKeyOutsideTheRowsRead()
    var
        AfterOpen: Text;
    begin
        Seed(60);
        Assert.AreEqual('19;20;21;22;23;24;25;26;27;28;29;30;31;32;33;34;35;36;37;38;39;40;39;40;41;42;43;44;45;46;47;48;49;50;51;52;53;54;55;56;57;58;59;60;found=Yes', RowsRead(45, AfterOpen), 'key 45');
        Assert.AreEqual('1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;1;', AfterOpen, 'open');

        Assert.AreEqual('19;20;21;22;23;24;25;26;27;28;29;30;31;32;33;34;35;36;37;38;39;40;39;40;41;42;43;44;45;46;47;48;49;50;51;52;53;54;55;56;57;58;59;60;found=Yes', RowsRead(59, AfterOpen), 'key 59');
        Assert.AreEqual('19;20;21;22;23;24;25;26;27;28;29;30;31;32;33;34;35;36;37;38;39;40;39;40;41;42;43;44;45;46;47;48;49;50;51;52;53;54;55;56;57;58;59;60;59;60;found=No', RowsRead(100, AfterOpen), 'key 100 (a miss)');
        Assert.AreEqual('19;20;21;22;23;24;25;26;27;28;29;30;31;32;33;34;35;36;37;38;39;40;found=Yes', RowsRead(21, AfterOpen), 'key 21: the first block');
        Assert.AreEqual('19;20;21;22;23;24;25;26;27;28;29;30;31;32;33;34;35;36;37;38;39;40;found=Yes', RowsRead(22, AfterOpen), 'key 22');
        Assert.AreEqual('19;20;21;22;23;24;25;26;27;28;29;30;31;32;33;34;35;36;37;38;39;40;39;40;41;42;43;44;45;46;47;48;49;50;51;52;53;54;55;56;57;58;59;60;found=Yes', RowsRead(41, AfterOpen), 'key 41: the second block');
    end;

    [Test]
    procedure List_Window_SmallTable()
    var
        AfterOpen: Text;
    begin
        Seed(25);

        Assert.AreEqual('19;20;21;22;23;24;25;found=Yes', RowsRead(24, AfterOpen), 'key 24');
        Assert.AreEqual('19;20;21;22;23;24;25;found=Yes', RowsRead(25, AfterOpen), 'key 25');
        Assert.AreEqual('19;20;21;22;23;24;25;found=Yes', RowsRead(21, AfterOpen), 'key 21');
        Assert.AreEqual('1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;1;', AfterOpen, 'open reads 20 rows and the current one again');
    end;
}
