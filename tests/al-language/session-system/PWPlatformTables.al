// Probe writer-c: "Probe round 6, platform tables" open points (docs/probes-needed.md). Observe-only.
// Fixtures: tables 69741, 69742; report 69743; codeunits 69744 (subscriber), 69745 (publisher), 69746 (tests).
// The report reuses table "RSS Sample" (60872 neighbours) and the layout file ./FixtureLayout.rdlc of the corpus app.

table 69741 "PW PT Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 69742 "PW PT Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option)
        {
            OptionMembers = A,B,C;
        }
        field(3; Ref; Code[10])
        {
            TableRelation = if (Kind = filter(A | B)) "PW PT Target".Id;
        }
        field(4; Ref2; Code[10])
        {
            TableRelation = if (Kind = const(A)) "PW PT Target".Id else if (Kind = const(B)) "PW PT Target".Txt;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 69743 "PW PT Layout Report"
{
    UsageCategory = None;
    ProcessingOnly = false;
    DefaultRenderingLayout = NoCaptionLayout;

    dataset
    {
        dataitem(Sample; "RSS Sample")
        {
            column(EntryNo; "Entry No.") { }
        }
    }

    rendering
    {
        layout(NoCaptionLayout)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout_10.rdlc';
        }
        layout(CaptionedLayout)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout_11.rdlc';
            Caption = 'Layout caption text';
            Summary = 'Layout summary text';
        }
    }
}

codeunit 69745 "PW PT Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnNobodyRaisesThis()
    begin
    end;

    procedure Raise()
    begin
        OnNobodyRaisesThis();
    end;
}

codeunit 69744 "PW PT Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PW PT Publisher", 'OnNobodyRaisesThis', '', false, false)]
    local procedure HandleIt()
    begin
    end;
}

codeunit 69746 "PW Platform Tables Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure TableRelationsMetadata_FilterCondition()
    var
        Rel: Record "Table Relations Metadata";
        Result: Text;
    begin
        Rel.SetRange("Table ID", Database::"PW PT Source");
        if Rel.FindSet() then
            repeat
                Result += StrSubstNo('[field %1 -> table %2 field %3 condfield %4 condtype %5 condvalue "%6"] ',
                    Rel."Field No.", Rel."Related Table ID", Rel."Related Field No.", Rel."Condition Field No.", Rel."Condition Type", Rel."Condition Value");
            until Rel.Next() = 0;
        Observer.Observe('relations', Result);
        Observer.Expect('relations', '[field 3 -> table 69741 field 1 condfield 2 condtype FILTER condvalue "0|1"] [field 4 -> table 69741 field 1 condfield 2 condtype CONST condvalue "0"] [field 4 -> table 69741 field 2 condfield 2 condtype CONST condvalue "1"] [field 2000000002 -> table 2000000120 field 1 condfield 0 condtype CONST condvalue ""] [field 2000000004 -> table 2000000120 field 1 condfield 0 condtype CONST condvalue ""] ');
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_LayoutWithAndWithoutCaption()
    var
        LayoutList: Record "Report Layout List";
        Result: Text;
    begin
        LayoutList.SetRange("Report ID", Report::"PW PT Layout Report");
        if LayoutList.FindSet() then
            repeat
                Result += StrSubstNo('[name=%1 caption="%2" description="%3"] ', LayoutList.Name, LayoutList.Caption, LayoutList.Description);
            until LayoutList.Next() = 0;
        Observer.Observe('layouts', Result);
        Observer.Expect('layouts', '[name=CaptionedLayout caption="Layout caption text" description="Layout summary text"] [name=NoCaptionLayout caption="NoCaptionLayout" description="NoCaptionLayout"] ');
        Observer.Verify();
    end;

    [Test]
    procedure EventSubscription_NumberOfCalls_FreshSessionNobodyRaised()
    var
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"PW PT Subscriber");
        Sub.SetRange("Subscriber Function", 'HandleIt');
        Observer.Observe('rows', Format(Sub.Count()));
        if Sub.FindFirst() then begin
            Observer.Observe('number_of_calls', Format(Sub."Number of Calls"));
            Observer.Observe('active_manual_instances', Format(Sub."Active Manual Instances"));
        end;
        Observer.Expect('rows', '1');
        Observer.Expect('number_of_calls', '0');
        Observer.Expect('active_manual_instances', '0');
        Observer.Verify();
    end;

    [Test]
    procedure EventSubscription_NumberOfCalls_AfterOneRaise()
    var
        Sub: Record "Event Subscription";
        Pub: Codeunit "PW PT Publisher";
    begin
        Pub.Raise();
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"PW PT Subscriber");
        Sub.SetRange("Subscriber Function", 'HandleIt');
        if Sub.FindFirst() then
            Observer.Observe('number_of_calls_after_one_raise', Format(Sub."Number of Calls"));
        Observer.Expect('number_of_calls_after_one_raise', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EventSubscription_FilterOnNumberOfCalls()
    var
        Sub: Record "Event Subscription";
    begin
        Sub.SetFilter("Number of Calls", '>0');
        Observer.Observe('count_filter_gt0', Format(Sub.Count()));
        Sub.Reset();
        Sub.SetRange("Active Manual Instances", 0);
        Observer.Observe('count_active_manual_0', Format(Sub.Count()));
        Observer.Discard(); // tier dependent: recorded in the manifest, not asserted
    end;

    [Test]
    procedure TenantLicenseState_DeleteOneRow()
    var
        State: Record "Tenant License State";
        Before: Integer;
    begin
        State.Init();
        State."Start Date" := CurrentDateTime();
        State.Insert();
        Before := State.Count();
        asserterror State.Delete();
        Observer.ObserveError('delete_one_row');
        Observer.Observe('count_before', Format(Before));
        Observer.Observe('count_after', Format(State.Count()));
        Observer.Expect('delete_one_row|text', 'It is not possible to delete any record in the Tenant License State table.');
        Observer.Expect('delete_one_row|code', 'DB:Ok');
        Observer.Expect('count_before', '1');
        Observer.Expect('count_after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure UserPersonalization_RowOfSessionUser()
    var
        UserPers: Record "User Personalization";
    begin
        Observer.Observe('get', Format(UserPers.Get(UserSecurityId())));
        Observer.Observe('profile_id', UserPers."Profile ID");
        Observer.Observe('company', UserPers.Company);
        Observer.Observe('time_zone', UserPers."Time Zone");
        Observer.Expect('get', 'Yes');
        Observer.Expect('profile_id', 'BUSINESS MANAGER');
        Observer.Expect('company', '<Company>');
        Observer.Expect('time_zone', 'UTC');
        Observer.Verify();
    end;
}
