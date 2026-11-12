// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minoccurs-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 75184-75185, xmlports 75186-75189, test codeunit 75190.
// local object: the nested table elements' MinOccurs, MaxOccurs and LinkTable are what is under test.
// Probe: al-runner issue 6924 (an outside reporter's EDI export ports declare MinOccurs = Once on a table element). An Xml export of
//   a header table element with a nested line table element that declares MinOccurs = Once. Ports:
//     Linked Min        LinkTable and LinkFields, MinOccurs = Once, MaxOccurs not set
//     Linked MinMax     LinkTable and LinkFields, MinOccurs = Once, MaxOccurs = Unbounded
//     Unlinked Min      no LinkTable, MinOccurs = Once, MaxOccurs not set
//     Linked Default    LinkTable and LinkFields, neither set (control)
//   Each test exports headers with 0, 1 and 2 lines, and an empty header table, and records the text.
//   Np4XmlPort.al pins MinOccurs = Once with MaxOccurs = Once; QrXpContainerOccurs.al TU_* the unlinked Once/Unbounded pair.
// BC versions: 27, 28, 29 (observe form; the values come from the measurement run)

table 75184 "XP NMO Head"
{
    // local object: the header rows.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 75185 "XP NMO Line"
{
    // local object: the line rows, linked to the header by "Head No.".
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; "Head No.", "Line No.") { Clustered = true; }
    }
}

xmlport 75186 "XP NMO Linked Min"
{
    // local object: linked line table element with MinOccurs = Once and no MaxOccurs.
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Head; "XP NMO Head")
            {
                fieldattribute(No; Head."No.") { }
                tableelement(Line; "XP NMO Line")
                {
                    LinkTable = Head;
                    LinkFields = "Head No." = field("No.");
                    MinOccurs = Once;
                    fieldattribute(LineNo; Line."Line No.") { }
                    fieldelement(Qty; Line.Qty) { }
                }
            }
        }
    }
}

xmlport 75187 "XP NMO Linked MinMax"
{
    // local object: linked line table element with MinOccurs = Once and MaxOccurs = Unbounded.
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Head; "XP NMO Head")
            {
                fieldattribute(No; Head."No.") { }
                tableelement(Line; "XP NMO Line")
                {
                    LinkTable = Head;
                    LinkFields = "Head No." = field("No.");
                    MinOccurs = Once;
                    MaxOccurs = Unbounded;
                    fieldattribute(LineNo; Line."Line No.") { }
                    fieldelement(Qty; Line.Qty) { }
                }
            }
        }
    }
}

xmlport 75188 "XP NMO Unlinked Min"
{
    // local object: unlinked line table element with MinOccurs = Once and no MaxOccurs.
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Head; "XP NMO Head")
            {
                fieldattribute(No; Head."No.") { }
                tableelement(Line; "XP NMO Line")
                {
                    MinOccurs = Once;
                    fieldattribute(LineNo; Line."Line No.") { }
                    fieldelement(Qty; Line.Qty) { }
                }
            }
        }
    }
}

xmlport 75189 "XP NMO Linked Default"
{
    // local object: linked line table element without MinOccurs and MaxOccurs (control).
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Head; "XP NMO Head")
            {
                fieldattribute(No; Head."No.") { }
                tableelement(Line; "XP NMO Line")
                {
                    LinkTable = Head;
                    LinkFields = "Head No." = field("No.");
                    fieldattribute(LineNo; Line."Line No.") { }
                    fieldelement(Qty; Line.Qty) { }
                }
            }
        }
    }
}

codeunit 75190 "XP NMO Tests"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed(WithRows: Boolean)
    var
        Head: Record "XP NMO Head";
        Line: Record "XP NMO Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        if WithRows then begin
            AddHead('H0');
            AddHead('H1');
            AddLine('H1', 10, 5);
            AddHead('H2');
            AddLine('H2', 10, 7);
            AddLine('H2', 20, 8);
        end;
        Commit();
    end;

    local procedure AddHead(No: Code[10])
    var
        Head: Record "XP NMO Head";
    begin
        Head."No." := No;
        Head.Name := 'Name ' + No;
        Head.Insert();
    end;

    local procedure AddLine(HeadNo: Code[10]; LineNo: Integer; Qty: Integer)
    var
        Line: Record "XP NMO Line";
    begin
        Line."Head No." := HeadNo;
        Line."Line No." := LineNo;
        Line.Qty := Qty;
        Line.Insert();
    end;

    local procedure ExportText(XpId: Integer; Name: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Part: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        if not Xmlport.Export(XpId, OutS) then begin
            Observer.ObserveError(Name + ' error');
            exit;
        end;
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Part);
            if Result <> '' then
                Result += '|';
            Result += Part;
        end;
        Observer.Observe(Name, Result);
    end;

    local procedure Measure(XpId: Integer)
    begin
        Seed(true);
        ExportText(XpId, 'rows');
        Seed(false);
        ExportText(XpId, 'no rows');
    end;

    [Test]
    procedure NMO_LinkedMin_Export()
    begin
        Measure(Xmlport::"XP NMO Linked Min");
        Observer.Finish();
    end;

    [Test]
    procedure NMO_LinkedMinMax_Export()
    begin
        Measure(Xmlport::"XP NMO Linked MinMax");
        Observer.Finish();
    end;

    [Test]
    procedure NMO_UnlinkedMin_Export()
    begin
        Measure(Xmlport::"XP NMO Unlinked Min");
        Observer.Finish();
    end;

    [Test]
    procedure NMO_LinkedDefault_Export()
    begin
        Measure(Xmlport::"XP NMO Linked Default");
        Observer.Finish();
    end;
}
