// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minoccurs-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), System Application codeunit "Temp Blob"; own tables 75193-75194, xmlports
//   75195-75196, test codeunit 75197.
// local object: the root table element's MaxOccurs = Once and MinOccurs = Zero, the text element set in OnAfterGetRecord and the
//   ports' schemas are what is under test.
// Probe: al-runner issue 6924, the reporter's two export ports as he described them (issue comment 6821117559): Format = Xml,
//   FormatEvaluate = Legacy, Direction = Export, Encoding = UTF8, no request page, no namespaces, no attributes. The root is the table
//   element itself (MaxOccurs = Once, MinOccurs = Zero):
//     Fields   field elements only (Code, Text, Code), empty OnAfterGetRecord (his "ECME Export Customer")
//     Warning  a text element set in OnAfterGetRecord, then field elements (Integer, Guid, Text, Code) (his "ECME Export Delete")
//   Each port runs through Xmlport.Export(Id, OutStream, Rec) on a record filtered by SetRecFilter to exactly one row (his call), and,
//   as neighbors, on a filter that selects no row and on one that selects two rows. Each test records the exported text (lines joined
//   with |) or the error.
// BC versions: 27, 28, 29 (observe form; the values come from the measurement run)

table 75193 "XP ROZ Party"
{
    // local object: the rows of the Fields port.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[100]) { }
        field(3; City; Text[30]) { }
        field(4; "Country Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 75194 "XP ROZ Queue"
{
    // local object: the rows of the Warning port.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Table No."; Integer) { }
        field(3; "Source SystemId"; Guid) { }
        field(4; "Primary Key String"; Text[250]) { }
        field(5; "Connector Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

xmlport 75195 "XP ROZ Fields"
{
    // local object: root table element with MaxOccurs = Once, MinOccurs = Zero and field elements only.
    Format = Xml;
    FormatEvaluate = Legacy;
    Direction = Export;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(Party; "XP ROZ Party")
        {
            MaxOccurs = Once;
            MinOccurs = Zero;
            fieldelement(No; Party."No.") { }
            fieldelement(Name; Party.Name) { }
            fieldelement(City; Party.City) { }
            fieldelement(CountryRegion; Party."Country Code") { }

            trigger OnAfterGetRecord()
            begin
            end;
        }
    }
}

xmlport 75196 "XP ROZ Warning"
{
    // local object: root table element with MaxOccurs = Once, MinOccurs = Zero, a text element set in OnAfterGetRecord and field elements.
    Format = Xml;
    FormatEvaluate = Legacy;
    Direction = Export;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(RecordDeleted; "XP ROZ Queue")
        {
            MaxOccurs = Once;
            MinOccurs = Zero;
            textelement(Warning) { TextType = Text; }
            fieldelement(TableNo; RecordDeleted."Table No.") { }
            fieldelement(SystemId; RecordDeleted."Source SystemId") { }
            fieldelement(PrimaryKey; RecordDeleted."Primary Key String") { }
            fieldelement(Connector; RecordDeleted."Connector Code") { }

            trigger OnAfterGetRecord()
            begin
                Warning := 'Record Deleted';
            end;
        }
    }
}

codeunit 75197 "XP ROZ Tests"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";

    local procedure SeedParties()
    var
        Party: Record "XP ROZ Party";
    begin
        Party.DeleteAll();
        AddParty('C1', 'First & Co', 'Gent', 'BE');
        AddParty('C2', 'Second', '', 'DE');
        AddParty('C3', 'Third', 'Paris', 'FR');
    end;

    local procedure AddParty(No: Code[20]; Name: Text[100]; City: Text[30]; Country: Code[10])
    var
        Party: Record "XP ROZ Party";
    begin
        Party."No." := No;
        Party.Name := Name;
        Party.City := City;
        Party."Country Code" := Country;
        Party.Insert();
    end;

    local procedure SeedQueue()
    var
        Queue: Record "XP ROZ Queue";
    begin
        Queue.DeleteAll();
        AddQueue(1, 18, '{6F9619FF-8B86-D011-B42D-00C04FC964FF}', 'No.=CONST(C1)', 'ECF');
        AddQueue(2, 27, '{00000000-0000-0000-0000-000000000000}', 'No.=CONST(1000)', 'ECF');
    end;

    local procedure AddQueue(EntryNo: Integer; TableNo: Integer; SysId: Guid; PK: Text[250]; Connector: Code[20])
    var
        Queue: Record "XP ROZ Queue";
    begin
        Queue."Entry No." := EntryNo;
        Queue."Table No." := TableNo;
        Queue."Source SystemId" := SysId;
        Queue."Primary Key String" := PK;
        Queue."Connector Code" := Connector;
        Queue.Insert();
    end;

    local procedure Observed(var TempBlob: Codeunit "Temp Blob"; Name: Text)
    var
        InS: InStream;
        Part: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Part);
            if Result <> '' then
                Result += '|';
            Result += Part;
        end;
        Observer.Observe(Name, Result);
    end;

    local procedure ExportParty(var Party: Record "XP ROZ Party"; Name: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        if not Xmlport.Export(Xmlport::"XP ROZ Fields", OutS, Party) then begin
            Observer.ObserveError(Name + ' error');
            exit;
        end;
        Observed(TempBlob, Name);
    end;

    local procedure ExportQueue(var Queue: Record "XP ROZ Queue"; Name: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        if not Xmlport.Export(Xmlport::"XP ROZ Warning", OutS, Queue) then begin
            Observer.ObserveError(Name + ' error');
            exit;
        end;
        Observed(TempBlob, Name);
    end;

    [Test]
    procedure ROZ_Fields_SetRecFilterOneRow()
    var
        Party: Record "XP ROZ Party";
    begin
        SeedParties();
        Party.Get('C1');
        Party.SetRecFilter();
        ExportParty(Party, 'one row');
        Party.Get('C2');
        Party.SetRecFilter();
        ExportParty(Party, 'one row, blank city');
        Observer.Finish();
    end;

    [Test]
    procedure ROZ_Fields_NoRow()
    var
        Party: Record "XP ROZ Party";
    begin
        SeedParties();
        Party.SetRange("No.", 'NONE');
        ExportParty(Party, 'no row');
        Observer.Finish();
    end;

    [Test]
    procedure ROZ_Fields_TwoRows()
    var
        Party: Record "XP ROZ Party";
    begin
        SeedParties();
        Party.SetFilter("No.", 'C1|C3');
        ExportParty(Party, 'two rows');
        Observer.Finish();
    end;

    [Test]
    procedure ROZ_Warning_SetRecFilterOneRow()
    var
        Queue: Record "XP ROZ Queue";
    begin
        SeedQueue();
        Queue.Get(1);
        Queue.SetRecFilter();
        ExportQueue(Queue, 'one row');
        Queue.Get(2);
        Queue.SetRecFilter();
        ExportQueue(Queue, 'one row, null guid');
        Observer.Finish();
    end;

    [Test]
    procedure ROZ_Warning_NoRow()
    var
        Queue: Record "XP ROZ Queue";
    begin
        SeedQueue();
        Queue.SetRange("Entry No.", 99);
        ExportQueue(Queue, 'no row');
        Observer.Finish();
    end;

    [Test]
    procedure ROZ_Warning_TwoRows()
    var
        Queue: Record "XP ROZ Queue";
    begin
        SeedQueue();
        ExportQueue(Queue, 'two rows');
        Observer.Finish();
    end;
}
