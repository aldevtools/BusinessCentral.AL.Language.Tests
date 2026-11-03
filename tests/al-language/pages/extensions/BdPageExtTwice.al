// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table LT Z Row (76000, pages/lt-z-page-props/ZFixtures.al); own pages 81090-81095, page extensions 81100-81111, tests 81096
// Probe: corpus issue 657. Two page extensions of the same app that set the same page property (InsertAllowed, ModifyAllowed, DeleteAllowed) to
// different values, in both orders of object id: what Page Metadata reports and whether a TestPage can add or change a row.
// (One extension: pageext/lt-z-page-ext-props/ZPageExtProps.al. A property value that is not a literal is must-not-compile case 1280.)
// BC versions: 27-29
page 81090 "BD PX Ins FT"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 81100 "BD PX Ins FT A" extends "BD PX Ins FT"
{
    InsertAllowed = false;
}

pageextension 81101 "BD PX Ins FT B" extends "BD PX Ins FT"
{
    InsertAllowed = true;
}
page 81091 "BD PX Ins TF"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 81102 "BD PX Ins TF A" extends "BD PX Ins TF"
{
    InsertAllowed = true;
}

pageextension 81103 "BD PX Ins TF B" extends "BD PX Ins TF"
{
    InsertAllowed = false;
}
page 81092 "BD PX Mod FT"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 81104 "BD PX Mod FT A" extends "BD PX Mod FT"
{
    ModifyAllowed = false;
}

pageextension 81105 "BD PX Mod FT B" extends "BD PX Mod FT"
{
    ModifyAllowed = true;
}
page 81093 "BD PX Mod TF"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 81106 "BD PX Mod TF A" extends "BD PX Mod TF"
{
    ModifyAllowed = true;
}

pageextension 81107 "BD PX Mod TF B" extends "BD PX Mod TF"
{
    ModifyAllowed = false;
}
page 81094 "BD PX Del FT"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 81108 "BD PX Del FT A" extends "BD PX Del FT"
{
    DeleteAllowed = false;
}

pageextension 81109 "BD PX Del FT B" extends "BD PX Del FT"
{
    DeleteAllowed = true;
}
page 81095 "BD PX Del TF"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 81110 "BD PX Del TF A" extends "BD PX Del TF"
{
    DeleteAllowed = true;
}

pageextension 81111 "BD PX Del TF B" extends "BD PX Del TF"
{
    DeleteAllowed = false;
}
codeunit 81096 "BD Page Ext Twice Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Meta(var Observer: Codeunit "Probe Observer"; PageId: Integer)
    var
        PageMeta: Record "Page Metadata";
    begin
        if not PageMeta.Get(PageId) then begin
            Observer.Observe('meta', 'not found');
            exit;
        end;
        Observer.Observe('meta', 'insert=' + Format(PageMeta.InsertAllowed) + ' modify=' + Format(PageMeta.ModifyAllowed) + ' delete=' + Format(PageMeta.DeleteAllowed));
    end;

    local procedure Seed()
    var
        R: Record "LT Z Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'One';
        R.Insert();
    end;

    local procedure Stored(): Text
    var
        R: Record "LT Z Row";
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id) + '/' + R.Name + ';';
            until R.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryNewInsFT(var P: TestPage "BD PX Ins FT")
    begin
        P.New();
        P.Id.SetValue(2);
        P.Name.SetValue('Two');
    end;

    [TryFunction]
    local procedure TryEditInsFT(var P: TestPage "BD PX Ins FT")
    begin
        P.Name.SetValue('Changed');
    end;

    [TryFunction]
    local procedure TryCloseInsFT(var P: TestPage "BD PX Ins FT")
    begin
        P.Close();
    end;

    [Test]
    procedure BdTwoExtensions_InsFT()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "BD PX Ins FT";
    begin
        Seed();
        Meta(Observer, Page::"BD PX Ins FT");
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        ClearLastError();
        Observer.Observe('edit ok', Format(TryEditInsFT(P)));
        Observer.ObserveError('edit');
        ClearLastError();
        Observer.Observe('new ok', Format(TryNewInsFT(P)));
        Observer.ObserveError('new');
        ClearLastError();
        Observer.Observe('close ok', Format(TryCloseInsFT(P)));
        Observer.ObserveError('close');
        Observer.Observe('rows', Stored());
        Observer.Expect('meta', 'insert=Yes modify=Yes delete=Yes');
        Observer.Expect('name editable', 'Yes');
        Observer.Expect('edit ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', '');
        Observer.Expect('new|code', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('rows', '1/Changed;2/Two;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNewInsTF(var P: TestPage "BD PX Ins TF")
    begin
        P.New();
        P.Id.SetValue(2);
        P.Name.SetValue('Two');
    end;

    [TryFunction]
    local procedure TryEditInsTF(var P: TestPage "BD PX Ins TF")
    begin
        P.Name.SetValue('Changed');
    end;

    [TryFunction]
    local procedure TryCloseInsTF(var P: TestPage "BD PX Ins TF")
    begin
        P.Close();
    end;

    [Test]
    procedure BdTwoExtensions_InsTF()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "BD PX Ins TF";
    begin
        Seed();
        Meta(Observer, Page::"BD PX Ins TF");
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        ClearLastError();
        Observer.Observe('edit ok', Format(TryEditInsTF(P)));
        Observer.ObserveError('edit');
        ClearLastError();
        Observer.Observe('new ok', Format(TryNewInsTF(P)));
        Observer.ObserveError('new');
        ClearLastError();
        Observer.Observe('close ok', Format(TryCloseInsTF(P)));
        Observer.ObserveError('close');
        Observer.Observe('rows', Stored());
        Observer.Expect('meta', 'insert=No modify=Yes delete=Yes');
        Observer.Expect('name editable', 'Yes');
        Observer.Expect('edit ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('new ok', 'No');
        Observer.Expect('new|text', 'New method failed because Insert is not allowed. Page = BD PX Ins TF, Id = 81091.');
        Observer.Expect('new|code', 'DB:ClientInsertDenied');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('rows', '1/Changed;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNewModFT(var P: TestPage "BD PX Mod FT")
    begin
        P.New();
        P.Id.SetValue(2);
        P.Name.SetValue('Two');
    end;

    [TryFunction]
    local procedure TryEditModFT(var P: TestPage "BD PX Mod FT")
    begin
        P.Name.SetValue('Changed');
    end;

    [TryFunction]
    local procedure TryCloseModFT(var P: TestPage "BD PX Mod FT")
    begin
        P.Close();
    end;

    [Test]
    procedure BdTwoExtensions_ModFT()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "BD PX Mod FT";
    begin
        Seed();
        Meta(Observer, Page::"BD PX Mod FT");
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        ClearLastError();
        Observer.Observe('edit ok', Format(TryEditModFT(P)));
        Observer.ObserveError('edit');
        ClearLastError();
        Observer.Observe('new ok', Format(TryNewModFT(P)));
        Observer.ObserveError('new');
        ClearLastError();
        Observer.Observe('close ok', Format(TryCloseModFT(P)));
        Observer.ObserveError('close');
        Observer.Observe('rows', Stored());
        Observer.Expect('meta', 'insert=Yes modify=Yes delete=Yes');
        Observer.Expect('name editable', 'Yes');
        Observer.Expect('edit ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', '');
        Observer.Expect('new|code', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('rows', '1/Changed;2/Two;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNewModTF(var P: TestPage "BD PX Mod TF")
    begin
        P.New();
        P.Id.SetValue(2);
        P.Name.SetValue('Two');
    end;

    [TryFunction]
    local procedure TryEditModTF(var P: TestPage "BD PX Mod TF")
    begin
        P.Name.SetValue('Changed');
    end;

    [TryFunction]
    local procedure TryCloseModTF(var P: TestPage "BD PX Mod TF")
    begin
        P.Close();
    end;

    [Test]
    procedure BdTwoExtensions_ModTF()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "BD PX Mod TF";
    begin
        Seed();
        Meta(Observer, Page::"BD PX Mod TF");
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        ClearLastError();
        Observer.Observe('edit ok', Format(TryEditModTF(P)));
        Observer.ObserveError('edit');
        ClearLastError();
        Observer.Observe('new ok', Format(TryNewModTF(P)));
        Observer.ObserveError('new');
        ClearLastError();
        Observer.Observe('close ok', Format(TryCloseModTF(P)));
        Observer.ObserveError('close');
        Observer.Observe('rows', Stored());
        Observer.Expect('meta', 'insert=Yes modify=No delete=Yes');
        Observer.Expect('name editable', 'No');
        Observer.Expect('edit ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', 'Page cannot be saved.');
        Observer.Expect('new|code', 'SaveAbort');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('rows', '1/One;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNewDelFT(var P: TestPage "BD PX Del FT")
    begin
        P.New();
        P.Id.SetValue(2);
        P.Name.SetValue('Two');
    end;

    [TryFunction]
    local procedure TryEditDelFT(var P: TestPage "BD PX Del FT")
    begin
        P.Name.SetValue('Changed');
    end;

    [TryFunction]
    local procedure TryCloseDelFT(var P: TestPage "BD PX Del FT")
    begin
        P.Close();
    end;

    [Test]
    procedure BdTwoExtensions_DelFT()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "BD PX Del FT";
    begin
        Seed();
        Meta(Observer, Page::"BD PX Del FT");
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        ClearLastError();
        Observer.Observe('edit ok', Format(TryEditDelFT(P)));
        Observer.ObserveError('edit');
        ClearLastError();
        Observer.Observe('new ok', Format(TryNewDelFT(P)));
        Observer.ObserveError('new');
        ClearLastError();
        Observer.Observe('close ok', Format(TryCloseDelFT(P)));
        Observer.ObserveError('close');
        Observer.Observe('rows', Stored());
        Observer.Expect('meta', 'insert=Yes modify=Yes delete=Yes');
        Observer.Expect('name editable', 'Yes');
        Observer.Expect('edit ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', '');
        Observer.Expect('new|code', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('rows', '1/Changed;2/Two;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNewDelTF(var P: TestPage "BD PX Del TF")
    begin
        P.New();
        P.Id.SetValue(2);
        P.Name.SetValue('Two');
    end;

    [TryFunction]
    local procedure TryEditDelTF(var P: TestPage "BD PX Del TF")
    begin
        P.Name.SetValue('Changed');
    end;

    [TryFunction]
    local procedure TryCloseDelTF(var P: TestPage "BD PX Del TF")
    begin
        P.Close();
    end;

    [Test]
    procedure BdTwoExtensions_DelTF()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "BD PX Del TF";
    begin
        Seed();
        Meta(Observer, Page::"BD PX Del TF");
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        ClearLastError();
        Observer.Observe('edit ok', Format(TryEditDelTF(P)));
        Observer.ObserveError('edit');
        ClearLastError();
        Observer.Observe('new ok', Format(TryNewDelTF(P)));
        Observer.ObserveError('new');
        ClearLastError();
        Observer.Observe('close ok', Format(TryCloseDelTF(P)));
        Observer.ObserveError('close');
        Observer.Observe('rows', Stored());
        Observer.Expect('meta', 'insert=Yes modify=Yes delete=No');
        Observer.Expect('name editable', 'Yes');
        Observer.Expect('edit ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', '');
        Observer.Expect('new|code', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('rows', '1/Changed;2/Two;');
        Observer.Verify();
    end;
}
