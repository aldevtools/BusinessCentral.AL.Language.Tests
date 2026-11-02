// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 93816-93818 and 93839, enum 93819, report 93820, page 93821, log 93822, test codeunit 93823 (writer Y71, gap cycle 7 spec G7-05)
// Probe: four conversions and one name lookup that Microsoft code relies on.
//        (a) an Option or Enum value handed to Get for a Code key field (which row matches: by name or by ordinal; SetRange, SetFilter, Validate and
//        assignment do not compile: must-not-compile cases 2690 and 2691);
//        (b) a Guid as key and as value of IsolatedStorage (Set, Contains, Get, Delete, SetEncrypted) and the text it is stored as;
//        (c) a FieldRef.Value of an Integer, Text, Date or Guid field assigned to a Blob field, directly and through a Variant;
//        (d) a data item field and a report global with the same name: which one an unqualified read takes in a data item trigger,
//        in SetLoadFields and SetRange, and the same collision in a page trigger.
//        Per call: the result, or the error text and code.

table 93816 "LT Y71 CV Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; U; Code[50]) { }
        field(2; Target; Code[20]) { }
        field(3; Note; Text[30]) { }
    }

    keys
    {
        key(PK; U, Target) { Clustered = true; }
    }
}

table 93817 "LT Y71 CV Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; N; Integer) { }
        field(3; T; Text[30]) { }
        field(4; Data; Blob) { }
        field(5; D; Date) { }
        field(6; G; Guid) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 93818 "LT Y71 CV Gate"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Gateway; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 93839 "LT Y71 CV Gate Tbl"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Gateway; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        Gateway: Text[30];

    procedure Describe(): Text
    begin
        Gateway := 'global';
        exit('unqualified=' + Format(Gateway) + ' rec=' + Format(Rec.Gateway));
    end;

    procedure SetUnqualified(NewValue: Text[30])
    begin
        Gateway := NewValue;
    end;

    procedure ShowAfterSet(): Text
    begin
        exit('field=' + Format(Rec.Gateway) + ' unqualified=' + Format(Gateway));
    end;
}

enum 93819 "LT Y71 CV Mode"
{
    Extensible = false;

    value(0; Web) { }
    value(1; Two) { }
}

report 93820 "LT Y71 CV Gate Report"
{
    ProcessingOnly = true;
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(DI; "LT Y71 CV Gate")
        {
            trigger OnPreDataItem()
            var
                Log: Codeunit "LT Y71 CV Log";
            begin
                SetLoadFields(Amount, Gateway);
                Log.Add('pre field=' + Format(DI.Gateway) + ' unqualified=' + Format(Gateway) + ' this=' + Format(this.Gateway));
                if this.Gateway <> '' then
                    SetRange(Gateway, this.Gateway);
                Log.Add('pre count=' + Format(DI.Count()));
            end;

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT Y71 CV Log";
            begin
                Log.Add('row ' + Format(Id) + ' unqualified=' + Format(Gateway) + ' this=' + Format(this.Gateway) + ' amount=' + Format(Amount) + ' this_amount=' + Format(this.Amount));
            end;
        }
    }

    var
        Gateway: Text[30];
        Amount: Decimal;

    procedure SetGateway(NewGateway: Text[30]; NewAmount: Decimal)
    begin
        Gateway := NewGateway;
        Amount := NewAmount;
    end;
}

page 93821 "LT Y71 CV Gate Card"
{
    PageType = Card;
    SourceTable = "LT Y71 CV Gate";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(GatewayField; Rec.Gateway) { ApplicationArea = All; }
        }
    }

    var
        Gateway: Text[30];

    trigger OnOpenPage()
    begin
        Gateway := 'global';
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT Y71 CV Log";
    begin
        Log.Add('page unqualified=' + Format(Gateway) + ' rec=' + Format(Rec.Gateway) + ' this=' + Format(this.Gateway));
    end;
}

codeunit 93822 "LT Y71 CV Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        if Lines <> '' then
            Lines += ';';
        Lines += Line;
    end;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Text(): Text
    begin
        exit(Lines);
    end;
}

codeunit 93823 "LT Y71 Value Conversions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Log: Codeunit "LT Y71 CV Log";

    // ---- (a) Option and Enum values for a Code key
    local procedure SeedKeys()
    var
        K: Record "LT Y71 CV Key";
    begin
        K.DeleteAll();
        K.U := 'ME';
        K.Target := 'WEB';
        K.Note := 'by name';
        K.Insert();
        K.Target := Format(ClientType::Web, 0, 2);
        K.Note := 'by ordinal';
        K.Insert();
        K.Target := 'WINDOWS';
        K.Note := 'windows name';
        K.Insert();
        K.Target := Format(ClientType::Windows, 0, 2);
        K.Note := 'windows ordinal';
        K.Insert();
        K.Target := 'TWO';
        K.Note := 'two name';
        K.Insert();
        K.Target := '1';
        K.Note := 'one ordinal';
        K.Insert();
        K.Target := '0';
        K.Note := 'zero ordinal';
        K.Insert();
    end;

    local procedure Matched(var K: Record "LT Y71 CV Key"; Found: Boolean): Text
    begin
        if Found then
            exit(StrSubstNo('Yes %1', K.Note));
        exit('No');
    end;

    [TryFunction]
    local procedure TryGetClientType(var K: Record "LT Y71 CV Key"; Which: Integer; var Found: Boolean)
    var
        Mode: Enum "LT Y71 CV Mode";
        OptionValue: Option Web,Two,Three;
    begin
        case Which of
            1:
                Found := K.Get('ME', ClientType::Web);
            2:
                Found := K.Get('ME', ClientType::Windows);
            3:
                begin
                    Mode := Mode::Web;
                    Found := K.Get('ME', Mode);
                end;
            4:
                begin
                    Mode := Mode::Two;
                    Found := K.Get('ME', Mode);
                end;
            5:
                begin
                    OptionValue := OptionValue::Two;
                    Found := K.Get('ME', OptionValue);
                end;
            6:
                begin
                    OptionValue := OptionValue::Web;
                    Found := K.Get('ME', OptionValue);
                end;
            7:
                Found := K.Get('ME', Mode::Two);
            8:
                Found := K.Get('ME', 'Web');
            9:
                Found := K.Get('ME', 1);
        end;
    end;

    local procedure GetForm(Name: Text; Which: Integer)
    var
        K: Record "LT Y71 CV Key";
        Found: Boolean;
    begin
        if TryGetClientType(K, Which, Found) then
            Obs.Observe(Name, Matched(K, Found))
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    [Test]
    procedure Get_OptionAndEnumValueIntoCodeKey()
    begin
        SeedKeys();
        GetForm('clienttype_web', 1);
        GetForm('clienttype_windows', 2);
        GetForm('enum_web', 3);
        GetForm('enum_two', 4);
        GetForm('option_two', 5);
        GetForm('option_web', 6);
        GetForm('enum_member_two', 7);
        GetForm('text_web', 8);
        GetForm('integer_one', 9);
        Obs.Expect('clienttype_web', 'Yes by name');
        Obs.Expect('clienttype_windows', 'Yes windows name');
        Obs.Expect('enum_web', 'Yes by name');
        Obs.Expect('enum_two', 'Yes two name');
        Obs.Expect('option_two', 'Yes two name');
        Obs.Expect('option_web', 'Yes by name');
        Obs.Expect('enum_member_two', 'Yes two name');
        Obs.Expect('text_web', 'Yes by name');
        Obs.Expect('integer_one', 'Yes one ordinal');
        Obs.Verify();
    end;

    // ---- (b) a Guid as key and value of IsolatedStorage
    local procedure DoStorage(Which: Integer; G: Guid; var Answer: Text)
    var
        T: Text;
        Secret: SecretText;
    begin
        case Which of
            1:
                Answer := Format(IsolatedStorage.Set(G, G, DataScope::Module));
            2:
                Answer := Format(IsolatedStorage.Contains(G, DataScope::Module));
            3:
                begin
                    if IsolatedStorage.Get(G, DataScope::Module, T) then
                        Answer := T
                    else
                        Answer := 'not found';
                end;
            4:
                begin
                    if IsolatedStorage.Get(Format(G), DataScope::Module, T) then
                        Answer := T
                    else
                        Answer := 'not found';
                end;
            5:
                begin
                    if IsolatedStorage.Get(LowerCase(Format(G)), DataScope::Module, T) then
                        Answer := T
                    else
                        Answer := 'not found';
                end;
            6:
                Answer := Format(IsolatedStorage.Delete(G, DataScope::Module));
            7:
                Answer := Format(IsolatedStorage.Set(Format(G), G, DataScope::Module));
            8:
                Answer := Format(IsolatedStorage.Set(G, Format(G), DataScope::Module));
            9:
                Answer := Format(IsolatedStorage.SetEncrypted(G, G, DataScope::Module));
            10:
                begin
                    if IsolatedStorage.Get(G, DataScope::Module, Secret) then
                        Answer := 'secret found, empty=' + Format(Secret.IsEmpty())
                    else
                        Answer := 'not found';
                end;
            11:
                Answer := Format(IsolatedStorage.Contains(Format(G), DataScope::Module));
            12:
                Answer := Format(IsolatedStorage.Delete(Format(G), DataScope::Module));
        end;
    end;

    local procedure Storage(Name: Text; Which: Integer; G: Guid)
    var
        Answer: Text;
    begin
        Clear(Answer);
        DoStorage(Which, G, Answer);
        Obs.Observe(Name, Answer);
    end;

    [Test]
    procedure IsolatedStorage_GuidKeyAndValue()
    var
        G: Guid;
    begin
        Evaluate(G, '{A1B2C3D4-0001-0002-0003-ABCDEF012345}');
        Storage('cleanup_delete_missing', 6, G);
        Storage('set_guid_guid', 1, G);
        Storage('contains_guid', 2, G);
        Storage('get_guid_key', 3, G);
        Storage('get_format_key', 4, G);
        Storage('get_lower_key', 5, G);
        Storage('get_secret', 10, G);
        Storage('contains_text_key', 11, G);
        Storage('delete_guid', 6, G);
        Storage('contains_after_delete', 2, G);
        Storage('set_text_key_guid_value', 7, G);
        Storage('get_text_key_stored', 4, G);
        Storage('delete_text_key', 12, G);
        Storage('set_guid_key_text_value', 8, G);
        Storage('get_after_text_value', 3, G);
        Storage('delete_again', 6, G);
        Storage('set_encrypted_guid', 9, G);
        Storage('delete_after_encrypted', 6, G);
        Obs.Finish();
    end;

    // ---- (c) FieldRef.Value of other types into a Blob field
    [TryFunction]
    local procedure TryBlob(var B: Record "LT Y71 CV Blob"; Which: Integer)
    var
        RR: RecordRef;
        FR: FieldRef;
        V: Variant;
    begin
        RR.GetTable(B);
        case Which of
            1:
                FR := RR.Field(2);
            2:
                FR := RR.Field(3);
            3:
                FR := RR.Field(5);
            4:
                FR := RR.Field(6);
            5:
                FR := RR.Field(4);
            6:
                begin
                    FR := RR.Field(2);
                    V := FR.Value;
                end;
        end;
        if Which = 6 then
            B.Data := V
        else
            B.Data := FR.Value;
    end;

    local procedure BlobForm(Name: Text; Which: Integer)
    var
        B: Record "LT Y71 CV Blob";
    begin
        B.Id := 1;
        B.N := 5;
        B.T := 'text';
        B.D := 20240315D;
        Evaluate(B.G, '{A1B2C3D4-0001-0002-0003-ABCDEF012345}');
        if TryBlob(B, Which) then
            Obs.Observe(Name, 'ok')
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
        Obs.Observe(Name + '|has_value', Format(B.Data.HasValue()));
        Obs.Observe(Name + '|length', Format(B.Data.Length()));
    end;

    [Test]
    procedure Blob_FromFieldRefValueOfOtherTypes()
    begin
        BlobForm('integer', 1);
        BlobForm('text', 2);
        BlobForm('date', 3);
        BlobForm('guid', 4);
        BlobForm('blob_itself', 5);
        BlobForm('integer_via_variant', 6);
        Obs.Finish();
    end;

    // ---- (d) a data item field and a report global of the same name
    local procedure RunReport(Name: Text; Gateway: Text[30]; Amount: Decimal)
    var
        Rep: Report "LT Y71 CV Gate Report";
        Row: Record "LT Y71 CV Gate";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Gateway := 'a';
        Row.Amount := 10;
        Row.Insert();
        Row.Id := 2;
        Row.Gateway := 'b';
        Row.Amount := 20;
        Row.Insert();
        Log.Reset();
        Rep.SetGateway(Gateway, Amount);
        Rep.UseRequestPage(false);
        Rep.RunModal();
        Obs.Observe(Name, Log.Text());
    end;

    [Test]
    procedure ReportDataItem_FieldNamedLikeGlobal()
    begin
        RunReport('global_empty', '', 0);
        RunReport('global_b', 'b', 99);
        RunReport('global_a', 'a', 5);
        RunReport('global_none', 'zzz', 1);
        Obs.Expect('global_empty', 'pre field= unqualified= this=;pre count=2;row 1 unqualified=a this= amount=10 this_amount=0;row 2 unqualified=b this= amount=20 this_amount=0');
        Obs.Expect('global_b', 'pre field= unqualified= this=b;pre count=1;row 2 unqualified=b this=b amount=20 this_amount=99');
        Obs.Expect('global_a', 'pre field= unqualified= this=a;pre count=1;row 1 unqualified=a this=a amount=10 this_amount=5');
        Obs.Expect('global_none', 'pre field= unqualified= this=zzz;pre count=0');
        Obs.Verify();
    end;

    [Test]
    procedure TableProcedure_FieldNamedLikeGlobal()
    var
        Row: Record "LT Y71 CV Gate Tbl";
    begin
        Row.Id := 1;
        Row.Gateway := 'field';
        Obs.Observe('describe', Row.Describe());
        Row.Gateway := 'again';
        Row.SetUnqualified('assigned');
        Obs.Observe('after_unqualified_assignment', Row.ShowAfterSet());
        Obs.Expect('describe', 'unqualified=global rec=field');
        Obs.Expect('after_unqualified_assignment', 'field=again unqualified=assigned');
        Obs.Verify();
    end;

    [Test]
    procedure Page_FieldNamedLikeGlobal()
    var
        Row: Record "LT Y71 CV Gate";
        Card: TestPage "LT Y71 CV Gate Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Gateway := 'a';
        Row.Insert();
        Log.Reset();
        Card.OpenView();
        Card.First();
        Obs.Observe('page', Log.Text());
        Card.Close();
        Obs.Expect('page', 'page unqualified=a rec=a this=;page unqualified=a rec=a this=');
        Obs.Verify();
    end;
}
