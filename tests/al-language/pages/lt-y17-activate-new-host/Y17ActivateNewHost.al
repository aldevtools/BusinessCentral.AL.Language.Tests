// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-activate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 91767 - 91773 (writer Y17a)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: gap cycle 1, gap G11 (the LibraryService.CreateServiceOrderHeaderUsingPage shape: OpenNew, Activate a non-key host field,
//   read "No.", OK). The header table assigns "No." := 'AUTO1' in OnInsert when it is blank (the No. Series pattern). Lines with a blank
//   "Document No." exist, so the linked ListPart shows rows while the new host's key is blank (the QH_BlankRows_* shape of
//   PartLineBeforeHostKey.al). Log: H.* table triggers of the header, L.* of the line, HP.* host page triggers, LP.* part page triggers.
// BC versions: 27, 28, 29

table 91767 "LT Y17 AH Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20])
        {
            trigger OnValidate()
            begin
                Log.Add('H.OnValidate(No.):' + "No.");
            end;
        }
        field(2; Name; Text[30]) { }
        field(3; "Customer No."; Code[20])
        {
            trigger OnValidate()
            begin
                Log.Add('H.OnValidate(Customer No.):' + "Customer No.");
            end;
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Log.Add('H.OnInsert:' + "No.");
        if "No." = '' then
            "No." := 'AUTO1';
    end;

    trigger OnModify()
    begin
        Log.Add('H.OnModify:' + "No.");
    end;

    var
        Log: Codeunit "LT Y17 AH Log";
}

table 91768 "LT Y17 AH Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Log.Add('L.OnInsert:' + "Document No." + '|' + Format("Line No."));
    end;

    trigger OnModify()
    begin
        Log.Add('L.OnModify:' + "Document No." + '|' + Format("Line No."));
    end;

    var
        Log: Codeunit "LT Y17 AH Log";
}

page 91770 "LT Y17 AH Lines"
{
    PageType = ListPart;
    SourceTable = "LT Y17 AH Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('LP.OnAfterGetRecord:' + Rec."Document No." + '|' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('LP.OnAfterGetCurrRecord:' + Rec."Document No." + '|' + Format(Rec."Line No."));
    end;

    var
        Log: Codeunit "LT Y17 AH Log";
}

page 91769 "LT Y17 AH Document"
{
    PageType = Document;
    SourceTable = "LT Y17 AH Header";
    DelayedInsert = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
            }
            part(Lines; "LT Y17 AH Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('HP.OnNewRecord:' + Rec."No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('HP.OnInsertRecord:' + Rec."No.");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('HP.OnModifyRecord:' + Rec."No.");
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('HP.OnAfterGetCurrRecord:' + Rec."No.");
    end;

    var
        Log: Codeunit "LT Y17 AH Log";
}

page 91771 "LT Y17 AH Card"
{
    PageType = Card;
    SourceTable = "LT Y17 AH Header";
    DelayedInsert = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
            }
            part(Lines; "LT Y17 AH Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('HP.OnNewRecord:' + Rec."No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('HP.OnInsertRecord:' + Rec."No.");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('HP.OnModifyRecord:' + Rec."No.");
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('HP.OnAfterGetCurrRecord:' + Rec."No.");
    end;

    var
        Log: Codeunit "LT Y17 AH Log";
}

codeunit 91772 "LT Y17 AH Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 91773 "LT Y17 AH Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y17 AH Log";

    local procedure Seed(WithBlankLines: Boolean)
    var
        Header: Record "LT Y17 AH Header";
        Line: Record "LT Y17 AH Line";
    begin
        Header.DeleteAll();
        Line.DeleteAll();
        if WithBlankLines then begin
            SeedLine(10000);
            SeedLine(20000);
        end;
        Log.Take();
    end;

    local procedure SeedLine(LineNo: Integer)
    var
        Line: Record "LT Y17 AH Line";
    begin
        Line."Document No." := '';
        Line."Line No." := LineNo;
        Line.Description := 'seeded';
        Line.Insert();
    end;

    local procedure Stored(Name: Text)
    var
        Header: Record "LT Y17 AH Header";
        Line: Record "LT Y17 AH Line";
        Rows: Text;
    begin
        if Header.FindSet() then
            repeat
                Rows += '[' + Header."No." + '|' + Header.Name + '|' + Header."Customer No." + ']';
            until Header.Next() = 0;
        Observer.Observe(Name + ' headers', Rows);
        Rows := '';
        if Line.FindSet() then
            repeat
                Rows += '[' + Line."Document No." + '|' + Format(Line."Line No.") + '|' + Line.Description + ']';
            until Line.Next() = 0;
        Observer.Observe(Name + ' lines', Rows);
    end;

    local procedure Result(Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name, Format(Ok));
        if not Ok then
            Observer.ObserveError(Name + ' error');
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [TryFunction]
    local procedure TryActivateCustomer(var Host: TestPage "LT Y17 AH Document")
    begin
        Host."Customer No.".Activate();
    end;

    [TryFunction]
    local procedure TryActivateKey(var Host: TestPage "LT Y17 AH Document")
    begin
        Host."No.".Activate();
    end;

    [TryFunction]
    local procedure TrySetCustomer(var Host: TestPage "LT Y17 AH Document")
    begin
        Host."Customer No.".SetValue('C1');
    end;

    [TryFunction]
    local procedure TryOk(var Host: TestPage "LT Y17 AH Document")
    begin
        Host.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryClose(var Host: TestPage "LT Y17 AH Document")
    begin
        Host.Close();
    end;

    [TryFunction]
    local procedure TryPartFirst(var Host: TestPage "LT Y17 AH Document"; var Found: Boolean)
    begin
        Found := Host.Lines.First();
    end;

    [TryFunction]
    local procedure TryNext(var Host: TestPage "LT Y17 AH Document"; var Found: Boolean)
    begin
        Found := Host.Next();
    end;

    [TryFunction]
    local procedure TryLast(var Host: TestPage "LT Y17 AH Document"; var Found: Boolean)
    begin
        Found := Host.Last();
    end;

    [TryFunction]
    local procedure TryActivateCustomerCard(var Host: TestPage "LT Y17 AH Card")
    begin
        Host."Customer No.".Activate();
    end;

    [TryFunction]
    local procedure TryOkCard(var Host: TestPage "LT Y17 AH Card")
    begin
        Host.OK().Invoke();
    end;

    // Must-have: the blocked path. OpenNew, Activate a non-key host field, read "No.", OK.
    [Test]
    procedure QH_BlankRows_ActivateHostField()
    var
        Host: TestPage "LT Y17 AH Document";
    begin
        Seed(true);
        Host.OpenNew();
        Observer.Observe('open_new', Log.Take());
        Result('activate', TryActivateCustomer(Host));
        Observer.Observe('no_after_activate', Host."No.".Value());
        Observer.Observe('read_log', Log.Take());
        Result('ok', TryOk(Host));
        Stored('stored');
        Observer.Expect('open_new', 'HP.OnNewRecord:;HP.OnAfterGetCurrRecord:;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|20000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetCurrRecord:|10000;');
        Observer.Expect('activate', 'Yes');
        Observer.Expect('activate log', 'HP.OnInsertRecord:;H.OnInsert:;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;');
        Observer.Expect('no_after_activate', 'AUTO1');
        Observer.Expect('read_log', '');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('ok log', '');
        Observer.Expect('stored headers', '[AUTO1||]');
        Observer.Expect('stored lines', '[|10000|seeded][|20000|seeded]');
        Observer.Verify();
    end;

    // Must-have: Activate, then read the part.
    [Test]
    procedure QH_BlankRows_ActivateHostField_ThenReadPart()
    var
        Host: TestPage "LT Y17 AH Document";
        Found: Boolean;
    begin
        Seed(true);
        Host.OpenNew();
        Observer.Observe('open_new', Log.Take());
        Result('activate', TryActivateCustomer(Host));
        Result('part_first', TryPartFirst(Host, Found));
        Observer.Observe('part_first_found', Format(Found));
        Observer.Observe('part_description', Host.Lines.Description.Value());
        Observer.Observe('part_read_log', Log.Take());
        Observer.Observe('no', Host."No.".Value());
        Result('close', TryClose(Host));
        Stored('stored');
        Observer.Expect('open_new', 'HP.OnNewRecord:;HP.OnAfterGetCurrRecord:;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|20000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetCurrRecord:|10000;');
        Observer.Expect('activate', 'Yes');
        Observer.Expect('activate log', 'HP.OnInsertRecord:;H.OnInsert:;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;');
        Observer.Expect('part_first', 'Yes');
        Observer.Expect('part_first log', '');
        Observer.Expect('part_first_found', 'No');
        Observer.Expect('part_description', '');
        Observer.Expect('part_read_log', '');
        Observer.Expect('no', 'AUTO1');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close log', '');
        Observer.Expect('stored headers', '[AUTO1||]');
        Observer.Expect('stored lines', '[|10000|seeded][|20000|seeded]');
        Observer.Verify();
    end;

    // Must-have: Activate, then SetValue of the same field (the SetValue variant of the refusal).
    [Test]
    procedure QH_BlankRows_ActivateHostField_ThenSetValue()
    var
        Host: TestPage "LT Y17 AH Document";
    begin
        Seed(true);
        Host.OpenNew();
        Observer.Observe('open_new', Log.Take());
        Result('activate', TryActivateCustomer(Host));
        Result('setvalue', TrySetCustomer(Host));
        Observer.Observe('no', Host."No.".Value());
        Observer.Observe('customer', Host."Customer No.".Value());
        Observer.Observe('read_log', Log.Take());
        Result('ok', TryOk(Host));
        Stored('stored');
        Observer.Expect('open_new', 'HP.OnNewRecord:;HP.OnAfterGetCurrRecord:;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|20000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetCurrRecord:|10000;');
        Observer.Expect('activate', 'Yes');
        Observer.Expect('activate log', 'HP.OnInsertRecord:;H.OnInsert:;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;');
        Observer.Expect('setvalue', 'Yes');
        Observer.Expect('setvalue log', 'H.OnValidate(Customer No.):C1;');
        Observer.Expect('no', 'AUTO1');
        Observer.Expect('customer', 'C1');
        Observer.Expect('read_log', '');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('ok log', 'HP.OnModifyRecord:AUTO1;H.OnModify:AUTO1;');
        Observer.Expect('stored headers', '[AUTO1||C1]');
        Observer.Expect('stored lines', '[|10000|seeded][|20000|seeded]');
        Observer.Verify();
    end;

    // Neighbour: Activate of the KEY control on the same host.
    [Test]
    procedure QH_BlankRows_ActivateKeyControl()
    var
        Host: TestPage "LT Y17 AH Document";
    begin
        Seed(true);
        Host.OpenNew();
        Observer.Observe('open_new', Log.Take());
        Result('activate', TryActivateKey(Host));
        Observer.Observe('no_after_activate', Host."No.".Value());
        Observer.Observe('read_log', Log.Take());
        Result('ok', TryOk(Host));
        Stored('stored');
        Observer.Expect('open_new', 'HP.OnNewRecord:;HP.OnAfterGetCurrRecord:;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|20000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetCurrRecord:|10000;');
        Observer.Expect('activate', 'Yes');
        Observer.Expect('activate log', '');
        Observer.Expect('no_after_activate', '');
        Observer.Expect('read_log', '');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('ok log', '');
        Observer.Expect('stored headers', '');
        Observer.Expect('stored lines', '[|10000|seeded][|20000|seeded]');
        Observer.Verify();
    end;

    // Neighbour: Activate of a host field, then Close instead of OK.
    [Test]
    procedure QH_BlankRows_ActivateHostField_Close()
    var
        Host: TestPage "LT Y17 AH Document";
    begin
        Seed(true);
        Host.OpenNew();
        Observer.Observe('open_new', Log.Take());
        Result('activate', TryActivateCustomer(Host));
        Result('close', TryClose(Host));
        Stored('stored');
        Observer.Expect('open_new', 'HP.OnNewRecord:;HP.OnAfterGetCurrRecord:;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|20000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetCurrRecord:|10000;');
        Observer.Expect('activate', 'Yes');
        Observer.Expect('activate log', 'HP.OnInsertRecord:;H.OnInsert:;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close log', '');
        Observer.Expect('stored headers', '[AUTO1||]');
        Observer.Expect('stored lines', '[|10000|seeded][|20000|seeded]');
        Observer.Verify();
    end;

    // Neighbour: the host is a Card page.
    [Test]
    procedure QH_BlankRows_ActivateHostField_CardHost()
    var
        Host: TestPage "LT Y17 AH Card";
    begin
        Seed(true);
        Host.OpenNew();
        Observer.Observe('open_new', Log.Take());
        Result('activate', TryActivateCustomerCard(Host));
        Observer.Observe('no_after_activate', Host."No.".Value());
        Observer.Observe('read_log', Log.Take());
        Result('ok', TryOkCard(Host));
        Stored('stored');
        Observer.Expect('open_new', 'HP.OnNewRecord:;HP.OnAfterGetCurrRecord:;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|20000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetCurrRecord:|10000;');
        Observer.Expect('activate', 'Yes');
        Observer.Expect('activate log', 'HP.OnInsertRecord:;H.OnInsert:;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;');
        Observer.Expect('no_after_activate', 'AUTO1');
        Observer.Expect('read_log', '');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('ok log', '');
        Observer.Expect('stored headers', '[AUTO1||]');
        Observer.Expect('stored lines', '[|10000|seeded][|20000|seeded]');
        Observer.Verify();
    end;

    // Neighbour (control): no blank-key lines, the part shows no rows.
    [Test]
    procedure QH_NoRows_ActivateHostField()
    var
        Host: TestPage "LT Y17 AH Document";
    begin
        Seed(false);
        Host.OpenNew();
        Observer.Observe('open_new', Log.Take());
        Result('activate', TryActivateCustomer(Host));
        Observer.Observe('no_after_activate', Host."No.".Value());
        Observer.Observe('read_log', Log.Take());
        Result('ok', TryOk(Host));
        Stored('stored');
        Observer.Expect('open_new', 'HP.OnNewRecord:;HP.OnAfterGetCurrRecord:;LP.OnAfterGetCurrRecord:|0;LP.OnAfterGetCurrRecord:|0;LP.OnAfterGetCurrRecord:|0;');
        Observer.Expect('activate', 'Yes');
        Observer.Expect('activate log', 'HP.OnInsertRecord:;H.OnInsert:;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;LP.OnAfterGetCurrRecord:AUTO1|0;');
        Observer.Expect('no_after_activate', 'AUTO1');
        Observer.Expect('read_log', '');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('ok log', '');
        Observer.Expect('stored headers', '[AUTO1||]');
        Observer.Expect('stored lines', '');
        Observer.Verify();
    end;

    // Neighbour: TestPage.Next on the new host with blank-key part rows.
    [Test]
    procedure QH_BlankRows_HostNext()
    var
        Host: TestPage "LT Y17 AH Document";
        Found: Boolean;
    begin
        Seed(true);
        Host.OpenNew();
        Observer.Observe('open_new', Log.Take());
        Result('next', TryNext(Host, Found));
        Observer.Observe('next_found', Format(Found));
        Observer.Observe('no', Host."No.".Value());
        Observer.Observe('read_log', Log.Take());
        Result('close', TryClose(Host));
        Stored('stored');
        Observer.Expect('open_new', 'HP.OnNewRecord:;HP.OnAfterGetCurrRecord:;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|20000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetCurrRecord:|10000;');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next log', '');
        Observer.Expect('next_found', 'No');
        Observer.Expect('no', '');
        Observer.Expect('read_log', '');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close log', '');
        Observer.Expect('stored headers', '');
        Observer.Expect('stored lines', '[|10000|seeded][|20000|seeded]');
        Observer.Verify();
    end;

    // Neighbour: TestPage.Last on the new host with blank-key part rows.
    [Test]
    procedure QH_BlankRows_HostLast()
    var
        Host: TestPage "LT Y17 AH Document";
        Found: Boolean;
    begin
        Seed(true);
        Host.OpenNew();
        Observer.Observe('open_new', Log.Take());
        Result('last', TryLast(Host, Found));
        Observer.Observe('last_found', Format(Found));
        Observer.Observe('no', Host."No.".Value());
        Observer.Observe('read_log', Log.Take());
        Result('close', TryClose(Host));
        Stored('stored');
        Observer.Expect('open_new', 'HP.OnNewRecord:;HP.OnAfterGetCurrRecord:;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|20000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetRecord:|10000;LP.OnAfterGetCurrRecord:|10000;');
        Observer.Expect('last', 'Yes');
        Observer.Expect('last log', '');
        Observer.Expect('last_found', 'No');
        Observer.Expect('no', '');
        Observer.Expect('read_log', '');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close log', '');
        Observer.Expect('stored headers', '');
        Observer.Expect('stored lines', '[|10000|seeded][|20000|seeded]');
        Observer.Verify();
    end;
}
