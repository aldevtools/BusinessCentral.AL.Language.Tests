// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setloadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); XApp A table "XA XRE Load Row" (76391) and subscriber "XA XRE Get Sub" (76392); own subscriber
//   codeunit 76395 and test codeunit 76396
// local object: the subscriber of the dependent app is the thing under test, so it is an own object; the table and the second subscriber
//   live in XApp A so that one subscriber sits in a dependency app.
// Probe (al-runner issue 7408, second report): what xRec holds in an OnBeforeModifyEvent subscriber when the caller read the row with
//   SetLoadFields and a filter the row does not match, assigned a field outside the load list and called Modify() from code. Readings:
//   GetFilters of Rec and xRec, AreFieldsLoaded on xRec and Rec, the fields of xRec, Format(xRec) = Format(Rec), Copy(xRec) then Find, the
//   same through a by-value parameter, and whether a second subscriber in a dependency app (XApp A) that calls xRec.Get runs first and what
//   the subscriber here then sees. Controls: no SetLoadFields, the changed field in the load list, no filter. The caller sequence of the
//   issue (IsEmpty, FindSet, DeleteAll, Reset, then two Modify calls) too.
// Facts: OBSERVE (filled in by the observe run)
// BC versions: 27, 28, 29

codeunit 76395 "LT XRE Load Sub"
{
    SingleInstance = true;

    var
        Log: Text;
        Enabled: Boolean;

    procedure SetEnabled(NewEnabled: Boolean)
    begin
        Enabled := NewEnabled;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Table, Database::"XA XRE Load Row", OnBeforeModifyEvent, '', false, false)]
    local procedure OnBeforeModify(var Rec: Record "XA XRE Load Row"; var xRec: Record "XA XRE Load Row"; RunTrigger: Boolean)
    var
        Other: Codeunit "XA XRE Get Sub";
        Copied: Record "XA XRE Load Row";
    begin
        if not Enabled then
            exit;
        if Rec.IsTemporary() then
            exit;
        Log += 'A: b ran first=' + Format(Other.HasRun()) + ' rfilters=[' + Rec.GetFilters() + '] xfilters=[' + xRec.GetFilters() + ']' +
            ' xloaded member=' + Format(xRec.AreFieldsLoaded(xRec."Member No.")) + ' xloaded name=' + Format(xRec.AreFieldsLoaded(xRec.Name)) +
            ' rloaded member=' + Format(Rec.AreFieldsLoaded(Rec."Member No.")) + ' rloaded name=' + Format(Rec.AreFieldsLoaded(Rec.Name)) + '; ';
        Log += 'A: xno=[' + xRec."No." + '] xcompany=[' + xRec."Company No." + '] xmember=[' + xRec."Member No." + '] xname=[' + xRec.Name +
            '] rmember=[' + Rec."Member No." + '] rname=[' + Rec.Name + '] formats equal=' + Format(Format(xRec) = Format(Rec)) + '; ';
        Copied.Copy(xRec);
        Log += 'A: copy filters=[' + Copied.GetFilters() + '] copy find=' + Format(Copied.Find()) + ' copy member after find=[' + Copied."Member No." + ']; ';
        SaveXRec(Rec, xRec);
    end;

    local procedure SaveXRec(var Contact: Record "XA XRE Load Row"; xContact: Record "XA XRE Load Row")
    var
        Copied: Record "XA XRE Load Row";
    begin
        Copied.Copy(xContact);
        Log += 'A by value: formats equal=' + Format(Format(xContact) = Format(Contact)) + ' xloaded member=' + Format(xContact.AreFieldsLoaded(xContact."Member No.")) +
            ' copy filters=[' + Copied.GetFilters() + '] copy find=' + Format(Copied.Find()) + '; ';
    end;
}

codeunit 76396 "LT XRE Load Modify Event"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SubA: Codeunit "LT XRE Load Sub";
        SubB: Codeunit "XA XRE Get Sub";

    local procedure Seed(WithB: Boolean)
    var
        Row: Record "XA XRE Load Row";
    begin
        SubA.SetEnabled(false);
        SubB.SetEnabled(false);
        Row.DeleteAll();
        AddRow('M1', '', '', 'Member One');
        AddRow('E1', '0002', '', 'Employer One');
        AddRow('E2', '0001', '', 'Employer Two');
        SubA.Take();
        SubB.Take();
        SubA.SetEnabled(true);
        SubB.SetEnabled(WithB);
    end;

    local procedure AddRow(No: Code[20]; Company: Code[20]; Member: Code[20]; Name: Text[50])
    var
        Row: Record "XA XRE Load Row";
    begin
        Row."No." := No;
        Row."Company No." := Company;
        Row."Member No." := Member;
        Row.Name := Name;
        Row.Insert();
    end;

    local procedure ObserveResult(var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "XA XRE Load Row";
    begin
        SubA.SetEnabled(false);
        SubB.SetEnabled(false);
        Observer.Observe('B log', SubB.Take());
        Observer.Observe('A log', SubA.Take());
        Stored.Get('M1');
        Observer.Observe('stored M1', Stored."Company No." + '|' + Stored."Member No." + '|' + Stored.Name);
    end;

    [Test]
    procedure LoadFieldsFilter_AssignUnloaded_Modify_OneSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Contact: Record "XA XRE Load Row";
    begin
        Seed(false);
        Contact.SetLoadFields("No.", "Company No.");
        Contact.SetRange("Company No.", '0001');
        Contact.Get('M1');
        Contact."Member No." := 'X-1';
        Contact.Modify();
        ObserveResult(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure LoadFieldsFilter_AssignUnloaded_Modify_DependencySubscriberGetsXRec()
    var
        Observer: Codeunit "Probe Observer";
        Contact: Record "XA XRE Load Row";
    begin
        Seed(true);
        Contact.SetLoadFields("No.", "Company No.");
        Contact.SetRange("Company No.", '0001');
        Contact.Get('M1');
        Contact."Member No." := 'X-1';
        Contact.Modify();
        ObserveResult(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure NoLoadFieldsFilter_Assign_Modify_DependencySubscriberGetsXRec()
    var
        Observer: Codeunit "Probe Observer";
        Contact: Record "XA XRE Load Row";
    begin
        Seed(true);
        Contact.SetRange("Company No.", '0001');
        Contact.Get('M1');
        Contact."Member No." := 'X-1';
        Contact.Modify();
        ObserveResult(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure LoadFieldsWithChangedField_Filter_Modify_OneSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Contact: Record "XA XRE Load Row";
    begin
        Seed(false);
        Contact.SetLoadFields("No.", "Company No.", "Member No.");
        Contact.SetRange("Company No.", '0001');
        Contact.Get('M1');
        Contact."Member No." := 'X-1';
        Contact.Modify();
        ObserveResult(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure LoadFieldsNoFilter_AssignUnloaded_Modify_OneSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Contact: Record "XA XRE Load Row";
    begin
        Seed(false);
        Contact.SetLoadFields("No.", "Company No.");
        Contact.Get('M1');
        Contact."Member No." := 'X-1';
        Contact.Modify();
        ObserveResult(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure IssueCallerSequence_TwoModifies_DependencySubscriberGetsXRec()
    var
        Observer: Codeunit "Probe Observer";
        Contact: Record "XA XRE Load Row";
        Stored: Record "XA XRE Load Row";
    begin
        Seed(true);
        Contact.SetLoadFields("No.", "Member No.", "Company No.");
        Contact.SetRange("Member No.", 'X-1');
        if not Contact.IsEmpty() then begin
            Contact.FindSet();
            Contact.DeleteAll();
        end;
        Contact.Reset();
        Contact.SetLoadFields("No.", "Company No.");
        Contact.SetRange("Company No.", '0001');
        if not Contact.IsEmpty() then begin
            Contact.FindSet();
            Contact.DeleteAll();
        end;
        Contact.Get('M1');
        Contact."Member No." := 'X-1';
        Contact.Modify();
        Observer.Observe('first modify B log', SubB.Take());
        Observer.Observe('first modify A log', SubA.Take());
        Contact.Get('E1');
        Contact."Company No." := '0001';
        Contact.Modify();
        Observer.Observe('second modify B log', SubB.Take());
        Observer.Observe('second modify A log', SubA.Take());
        SubA.SetEnabled(false);
        SubB.SetEnabled(false);
        Observer.Observe('rows left', Format(Stored.Count()));
        Stored.Get('M1');
        Observer.Observe('stored M1', Stored."Company No." + '|' + Stored."Member No." + '|' + Stored.Name);
        Stored.Get('E1');
        Observer.Observe('stored E1', Stored."Company No." + '|' + Stored."Member No." + '|' + Stored.Name);
        Observer.Finish();
    end;
}
