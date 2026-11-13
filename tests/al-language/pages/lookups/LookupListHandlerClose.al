// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-lookup-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-lookuppageid-property
// Scope: in-scope (Cloud). TestField.Lookup with a ModalPageHandler.
// Fixtures used: Probe Observer (codeunit 69160); own tables 64765 64767 64768, list page 64766, part page 64769, host page 64770, log
//   codeunit 64771, test codeunit 64772
// Probe (values from the CI runs on BC 27.5, 28.5 and 29.0, the same on all three). Area: the ModalPageHandler of a TableRelation lookup whose LookupPageId is a List page, reached by Lookup() on a
//   field of a Card and on a field of a ListPart in a Document page (al-runner issue 7479). The handler ends the lookup page with
//   TestPage.Close(), with Cancel().Invoke(), or with GoToKey and OK().Invoke(). Pinned elsewhere: TestPage.Close() in the handler of a
//   static RunModal of a StandardDialog and of a Page variable's RunModal of a Card (ui-handlers). Not pinned: a lookup page.
// Observed: whether Lookup() raises (text and code), the value the control shows after it, the stored value after Close, and the log
//   of the lookup page (open, query(<action>), close).
// local object: the TableRelation, the LookupPageId and the pages are what the test checks
// BC versions: 27, 28, 29

table 64765 "PGA LC Code"
{
    DataClassification = SystemMetadata;
    LookupPageId = "PGA LC Codes";
    DrillDownPageId = "PGA LC Codes";

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 64766 "PGA LC Codes"
{
    PageType = List;
    SourceTable = "PGA LC Code";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "PGA LC Log";

    trigger OnOpenPage()
    begin
        Log.Add('open');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('query(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('close');
    end;
}

table 64767 "PGA LC Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "My Code"; Code[10]) { DataClassification = SystemMetadata; TableRelation = "PGA LC Code"; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 64768 "PGA LC Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; "My Code"; Code[10]) { DataClassification = SystemMetadata; TableRelation = "PGA LC Code"; }
    }

    keys
    {
        key(PK; "No.", "Line No.") { Clustered = true; }
    }
}

page 64769 "PGA LC Lines"
{
    PageType = ListPart;
    SourceTable = "PGA LC Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("My Code"; Rec."My Code") { ApplicationArea = All; }
            }
        }
    }
}

page 64770 "PGA LC Doc"
{
    PageType = Document;
    SourceTable = "PGA LC Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("My Code"; Rec."My Code") { ApplicationArea = All; }
            }
            part(Lines; "PGA LC Lines")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }
}

codeunit 64771 "PGA LC Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Mode: Text;

    procedure Reset(NewMode: Text)
    begin
        Entries := '';
        Mode := NewMode;
    end;

    procedure GetMode(): Text
    begin
        exit(Mode);
    end;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' ';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 64772 "PGA LC Lookup Handler Close"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PGA LC Log";

    local procedure Initialize(Mode: Text)
    var
        C: Record "PGA LC Code";
        Head: Record "PGA LC Head";
        Line: Record "PGA LC Line";
    begin
        Observer.Discard();
        Line.DeleteAll();
        Head.DeleteAll();
        C.DeleteAll();
        C."Code" := 'W';
        C.Insert();
        C."Code" := 'X';
        C.Insert();
        Head.Init();
        Head."No." := 'R1';
        Head."My Code" := 'W';
        Head.Insert();
        Line.Init();
        Line."No." := 'R1';
        Line."Line No." := 10000;
        Line."My Code" := 'W';
        Line.Insert();
        Log.Reset(Mode);
    end;

    local procedure Stored(): Text
    var
        Head: Record "PGA LC Head";
        Line: Record "PGA LC Line";
    begin
        Head.Get('R1');
        Line.Get('R1', 10000);
        exit('head=' + Head."My Code" + ' line=' + Line."My Code");
    end;

    [TryFunction]
    local procedure TryHeadLookup(var P: TestPage "PGA LC Doc")
    begin
        P."My Code".Lookup();
    end;

    [TryFunction]
    local procedure TryLineLookup(var P: TestPage "PGA LC Doc")
    begin
        P.Lines."My Code".Lookup();
    end;

    local procedure RunHead(Mode: Text)
    var
        P: TestPage "PGA LC Doc";
    begin
        Initialize(Mode);
        P.OpenEdit();
        P.GoToKey('R1');
        if TryHeadLookup(P) then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('log', Log.Take());
        Observer.Observe('shown', P."My Code".Value());
        P.Close();
        Observer.Observe('stored', Stored());
    end;

    local procedure RunLine(Mode: Text)
    var
        P: TestPage "PGA LC Doc";
    begin
        Initialize(Mode);
        P.OpenEdit();
        P.GoToKey('R1');
        P.Lines.First();
        if TryLineLookup(P) then
            Observer.Observe('lookup', 'ok')
        else
            Observer.ObserveError('lookup');
        Observer.Observe('log', Log.Take());
        Observer.Observe('shown', P.Lines."My Code".Value());
        P.Close();
        Observer.Observe('stored', Stored());
    end;

    [Test]
    [HandlerFunctions('CodesHandler')]
    procedure CardField_Lookup_HandlerClose()
    begin
        RunHead('CLOSE');
        Observer.Expect('lookup', 'ok');
        Observer.Expect('log', 'open open handler-on(W) query(LookupCancel) close');
        Observer.Expect('shown', 'W');
        Observer.Expect('stored', 'head=W line=W');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CodesHandler')]
    procedure CardField_Lookup_HandlerCancel()
    begin
        RunHead('CANCEL');
        Observer.Expect('lookup', 'ok');
        Observer.Expect('log', 'open open handler-on(W) query(LookupCancel) close');
        Observer.Expect('shown', 'W');
        Observer.Expect('stored', 'head=W line=W');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CodesHandler')]
    procedure CardField_Lookup_HandlerOkOnOtherRow()
    begin
        RunHead('OK');
        Observer.Expect('lookup', 'ok');
        Observer.Expect('log', 'open open handler-on(W) query(LookupOK) close');
        Observer.Expect('shown', 'X');
        Observer.Expect('stored', 'head=X line=W');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CodesHandler')]
    procedure PartField_Lookup_HandlerClose()
    begin
        RunLine('CLOSE');
        Observer.Expect('lookup|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('lookup|code', 'TestFieldNotFound');
        Observer.Expect('log', 'open query(LookupOK) close');
        Observer.Expect('shown', 'W');
        Observer.Expect('stored', 'head=W line=W');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CodesHandler')]
    procedure PartField_Lookup_HandlerCancel()
    begin
        RunLine('CANCEL');
        Observer.Expect('lookup|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('lookup|code', 'TestFieldNotFound');
        Observer.Expect('log', 'open query(LookupOK) close');
        Observer.Expect('shown', 'W');
        Observer.Expect('stored', 'head=W line=W');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CodesHandler')]
    procedure PartField_Lookup_HandlerOkOnOtherRow()
    begin
        RunLine('OK');
        Observer.Expect('lookup|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('lookup|code', 'TestFieldNotFound');
        Observer.Expect('log', 'open query(LookupOK) close');
        Observer.Expect('shown', 'W');
        Observer.Expect('stored', 'head=W line=W');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure CodesHandler(var Codes: TestPage "PGA LC Codes")
    begin
        Log.Add('handler-on(' + Codes."Code".Value() + ')');
        case Log.GetMode() of
            'CLOSE':
                Codes.Close();
            'CANCEL':
                Codes.Cancel().Invoke();
            'OK':
                begin
                    Codes.GoToKey('X');
                    Codes.OK().Invoke();
                end;
        end;
    end;
}
