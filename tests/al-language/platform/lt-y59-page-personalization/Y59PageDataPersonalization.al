// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (gap cycle 6, G6-04b): the stored platform table Page Data Personalization (2000000080) written and read the way Microsoft's apps
//   keep a value per user, object and personalization id: Insert(false) with a BLOB written through BigText, the read with SetAutoCalcFields
//   and five SetRange filters, a second Insert of the same key, Modify(false), the read order of the primary key and of the Date key, the
//   BLOB without CalcFields, the FlowField "User ID", whether the platform fills Date and Time, and an Insert for another User SID.
//   Every test deletes its own keys (Personalization ID starting with LTY59) first.
// BC versions: 27.5, 28.5, 29.0.

// Runs one Insert in its OnRun, called through Codeunit.Run.
codeunit 93206 "LT Y59 PDP Writer"
{
    var
        UserSid: Guid;
        Shown: Text;

    trigger OnRun()
    var
        Personalization: Record "Page Data Personalization";
    begin
        Personalization.Init();
        Personalization."User SID" := UserSid;
        Personalization."Object Type" := Personalization."Object Type"::Page;
        Personalization."Object ID" := 93201;
        Personalization."Personalization ID" := 'LTY59OTHER';
        Personalization.ValueName := 'LTY59NAME';
        Shown := Format(Personalization.Insert(false));
    end;

    procedure RunAndObserve(NewUserSid: Guid; var Observer: Codeunit "Probe Observer"; ObservedName: Text)
    begin
        UserSid := NewUserSid;
        Commit();
        if Run() then
            Observer.Observe(ObservedName, 'ok|' + Shown)
        else
            Observer.ObserveError(ObservedName);
    end;
}

codeunit 93205 "LT Y59 Page Data Personal."
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Cleanup()
    var
        Personalization: Record "Page Data Personalization";
    begin
        Personalization.SetFilter("Personalization ID", 'LTY59*');
        Personalization.DeleteAll();
    end;

    local procedure SetValue(ObjectType: Option; ObjectId: Integer; PersonalizationId: Code[40]; Name: Code[40]; Value: Text): Boolean
    var
        Personalization: Record "Page Data Personalization";
        OutStr: OutStream;
        Big: BigText;
    begin
        Personalization."User SID" := UserSecurityId();
        Personalization."Object Type" := ObjectType;
        Personalization."Object ID" := ObjectId;
        Personalization."Personalization ID" := PersonalizationId;
        Personalization.ValueName := Name;
        Personalization.Value.CreateOutStream(OutStr, TextEncoding::UTF8);
        Big.AddText(Value);
        Big.Write(OutStr);
        exit(Personalization.Insert(false));
    end;

    local procedure GetValue(ObjectType: Option; ObjectId: Integer; PersonalizationId: Code[40]; Name: Code[40]): Text
    var
        Personalization: Record "Page Data Personalization";
        InStr: InStream;
        Big: BigText;
        Result: Text;
    begin
        Personalization.SetRange("User SID", UserSecurityId());
        Personalization.SetRange("Object Type", ObjectType);
        Personalization.SetRange("Object ID", ObjectId);
        Personalization.SetRange("Personalization ID", PersonalizationId);
        Personalization.SetRange(ValueName, Name);
        Personalization.SetAutoCalcFields(Value);
        if not Personalization.FindFirst() then
            exit('not found');
        Personalization.Value.CreateInStream(InStr, TextEncoding::UTF8);
        Big.Read(InStr);
        Big.GetSubText(Result, 1);
        exit(Result);
    end;

    local procedure KeyText(var Personalization: Record "Page Data Personalization"): Text
    begin
        exit(Format(Personalization."Object Type") + ':' + Format(Personalization."Object ID") + ':' + Personalization."Personalization ID" + ':' + Personalization.ValueName);
    end;

    [Test]
    procedure Y59_Personalization_InsertAndRead()
    var
        Personalization: Record "Page Data Personalization";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup();
        Observer.Observe('insert', Format(SetValue(Personalization."Object Type"::Page, 93201, 'LTY59A', 'LTY59NAME', 'hello value')));
        Observer.Observe('read', GetValue(Personalization."Object Type"::Page, 93201, 'LTY59A', 'LTY59NAME'));
        Personalization.SetRange("User SID", UserSecurityId());
        Personalization.SetRange("Personalization ID", 'LTY59A');
        Observer.Observe('found', Format(Personalization.FindFirst()));
        Observer.Observe('user_id_without_calcfields_blank', Format(Personalization."User ID" = ''));
        Personalization.CalcFields("User ID");
        Observer.Observe('user_id_is_user_name', Format(Personalization."User ID" = UserId()));
        Observer.Observe('user_id_blank', Format(Personalization."User ID" = ''));
        Observer.Observe('date_blank', Format(Personalization.Date = 0D));
        Observer.Observe('time_blank', Format(Personalization.Time = 0T));
        Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure Y59_Personalization_DuplicateInsertThenModify()
    var
        Personalization: Record "Page Data Personalization";
        OutStr: OutStream;
        Big: BigText;
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup();
        Observer.Observe('insert_1', Format(SetValue(Personalization."Object Type"::Page, 93201, 'LTY59D', 'LTY59NAME', 'first')));
        Observer.Observe('insert_2', Format(SetValue(Personalization."Object Type"::Page, 93201, 'LTY59D', 'LTY59NAME', 'second')));
        Observer.Observe('read_after_inserts', GetValue(Personalization."Object Type"::Page, 93201, 'LTY59D', 'LTY59NAME'));
        Personalization.Get(UserSecurityId(), Personalization."Object Type"::Page, 93201, 'LTY59D', 'LTY59NAME');
        Personalization.Value.CreateOutStream(OutStr, TextEncoding::UTF8);
        Big.AddText('third');
        Big.Write(OutStr);
        Observer.Observe('modify', Format(Personalization.Modify(false)));
        Observer.Observe('read_after_modify', GetValue(Personalization."Object Type"::Page, 93201, 'LTY59D', 'LTY59NAME'));
        Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure Y59_Personalization_KeyOrder_And_Filters()
    var
        Personalization: Record "Page Data Personalization";
        Order: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup();
        SetValue(Personalization."Object Type"::Page, 93203, 'LTY59B', 'V2', 'b');
        SetValue(Personalization."Object Type"::Report, 93200, 'LTY59A', 'V1', 'a');
        SetValue(Personalization."Object Type"::Page, 93201, 'LTY59C', 'V3', 'c');
        SetValue(Personalization."Object Type"::XMLport, 93200, 'LTY59A', 'V0', 'x');
        SetValue(Personalization."Object Type"::Page, 93201, 'LTY59A', 'V4', 'd');
        Personalization.SetRange("User SID", UserSecurityId());
        Personalization.SetFilter("Personalization ID", 'LTY59*');
        if Personalization.FindSet() then
            repeat
                Order += KeyText(Personalization) + ';';
            until Personalization.Next() = 0;
        Observer.Observe('order_primary_key', Order);
        Observer.Observe('count_user', Format(Personalization.Count()));
        Personalization.SetRange("Object Type", Personalization."Object Type"::Page);
        Observer.Observe('count_page', Format(Personalization.Count()));
        Personalization.SetRange("Object ID", 93201);
        Observer.Observe('count_page_93201', Format(Personalization.Count()));
        Personalization.SetRange("Personalization ID", 'LTY59A');
        Observer.Observe('count_page_93201_a', Format(Personalization.Count()));
        Personalization.SetRange(ValueName, 'V4');
        Observer.Observe('count_all_five', Format(Personalization.Count()));
        Personalization.Reset();
        Personalization.SetCurrentKey(Date);
        Personalization.SetRange("User SID", UserSecurityId());
        Personalization.SetFilter("Personalization ID", 'LTY59*');
        Order := '';
        if Personalization.FindSet() then
            repeat
                Order += KeyText(Personalization) + ';';
            until Personalization.Next() = 0;
        Observer.Observe('order_date_key', Order);
        Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure Y59_Personalization_BlobWithoutAutoCalc()
    var
        Personalization: Record "Page Data Personalization";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup();
        SetValue(Personalization."Object Type"::Page, 93201, 'LTY59E', 'LTY59NAME', 'twelve chars');
        Personalization.SetRange("User SID", UserSecurityId());
        Personalization.SetRange("Personalization ID", 'LTY59E');
        Personalization.FindFirst();
        Observer.Observe('hasvalue_without_calcfields', Format(Personalization.Value.HasValue()));
        Observer.Observe('length_without_calcfields', Format(Personalization.Value.Length()));
        Personalization.CalcFields(Value);
        Observer.Observe('hasvalue_after_calcfields', Format(Personalization.Value.HasValue()));
        Observer.Observe('length_after_calcfields', Format(Personalization.Value.Length()));
        Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure Y59_Personalization_OtherUserSid()
    var
        Personalization: Record "Page Data Personalization";
        Writer: Codeunit "LT Y59 PDP Writer";
        OtherSid: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup();
        OtherSid := '{59595959-5959-4959-8959-595959595959}';
        Writer.RunAndObserve(OtherSid, Observer, 'insert_other_user');
        Personalization.SetRange("User SID", OtherSid);
        Personalization.SetRange("Personalization ID", 'LTY59OTHER');
        Observer.Observe('count_other_user', Format(Personalization.Count()));
        if Personalization.FindFirst() then begin
            Personalization.CalcFields("User ID");
            Observer.Observe('other_user_id', '[' + Personalization."User ID" + ']');
        end;
        Cleanup();
        Observer.Finish();
    end;
}
