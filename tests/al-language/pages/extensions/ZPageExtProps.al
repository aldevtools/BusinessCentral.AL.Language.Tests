// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 76000, card 76001, log 76002 (pages/lt-z-page-props/ZFixtures.al); pages 76100-76129, page extensions 76130-76159, codeunit 76160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles corpus issue 617: page extension properties AdditionalSearchTerms(ML), CardPageId, DeleteAllowed, InsertAllowed, ModifyAllowed, PromotedActionCategories(ML).
// Facts: what the Page Metadata table reports for each base page, the page it opens for a built-in Edit action, the error text of New and of an edit on a page that
//   does not allow it, and what a page action that deletes does when DeleteAllowed is false. TestPage has no member for the standard Delete command.
//   Combinations the compiler rejects (AdditionalSearchTerms together with AdditionalSearchTermsML, an unknown CardPageId) are must-not-compile cases.
// BC versions: 29 (27 and 28 by CI)

page 76100 "LT Z XA Base"
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

pageextension 76130 "LT Z XA Ext" extends "LT Z XA Base"
{
    AdditionalSearchTerms = 'zeta,eta';
    CardPageId = "LT Z Card";
    PromotedActionCategories = 'One,Two,Three';
}

page 76101 "LT Z XB Base"
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

pageextension 76131 "LT Z XB Ext" extends "LT Z XB Base"
{
    AdditionalSearchTermsML = ENU = 'zeta', DEU = 'eta', FRA = 'theta';
    PromotedActionCategoriesML = ENU = 'One,Two,Three', DEU = 'Eins,Zwei,Drei';
}

page 76102 "LT Z XD1 Base"
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

pageextension 76132 "LT Z XD1 Ext" extends "LT Z XD1 Base"
{
    DeleteAllowed = false;
}

page 76103 "LT Z XD2 Base"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;
    DeleteAllowed = false;
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

pageextension 76133 "LT Z XD2 Ext" extends "LT Z XD2 Base"
{
    DeleteAllowed = true;
}

page 76104 "LT Z XD3 Base"
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

pageextension 76134 "LT Z XD3 Ext" extends "LT Z XD3 Base"
{
    DeleteAllowed = true;
}

page 76105 "LT Z XD4 Base"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;
    DeleteAllowed = false;
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

page 76106 "LT Z XI1 Base"
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

pageextension 76136 "LT Z XI1 Ext" extends "LT Z XI1 Base"
{
    InsertAllowed = false;
}

page 76107 "LT Z XI2 Base"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

pageextension 76137 "LT Z XI2 Ext" extends "LT Z XI2 Base"
{
    InsertAllowed = true;
}

page 76108 "LT Z XI3 Base"
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

pageextension 76138 "LT Z XI3 Ext" extends "LT Z XI3 Base"
{
    InsertAllowed = true;
}

page 76109 "LT Z XI4 Base"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

page 76110 "LT Z XM1 Base"
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

pageextension 76140 "LT Z XM1 Ext" extends "LT Z XM1 Base"
{
    ModifyAllowed = false;
}

page 76111 "LT Z XM2 Base"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;
    ModifyAllowed = false;
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

pageextension 76141 "LT Z XM2 Ext" extends "LT Z XM2 Base"
{
    ModifyAllowed = true;
}

page 76112 "LT Z XM3 Base"
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

pageextension 76142 "LT Z XM3 Ext" extends "LT Z XM3 Base"
{
    ModifyAllowed = true;
}

page 76113 "LT Z XM4 Base"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;
    ModifyAllowed = false;
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

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}

codeunit 76160 "LT Z Page Ext Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Meta(PageId: Integer; Prefix: Text)
    var
        PageMeta: Record "Page Metadata";
    begin
        if not PageMeta.Get(PageId) then begin
            Observer.Observe(Prefix + ' meta', 'not found');
            exit;
        end;
        Observer.Observe(Prefix + ' card page id', Format(PageMeta.CardPageID));
        Observer.Observe(Prefix + ' insert allowed', Format(PageMeta.InsertAllowed));
        Observer.Observe(Prefix + ' modify allowed', Format(PageMeta.ModifyAllowed));
        Observer.Observe(Prefix + ' delete allowed', Format(PageMeta.DeleteAllowed));
    end;

    local procedure Seed()
    var
        R: Record "LT Z Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'One';
        R.Insert();
        R.Id := 2;
        R.Name := 'Two';
        R.Insert();
    end;

    [PageHandler]
    procedure CardHandler(var C: TestPage "LT Z Card")
    begin
        Observer.Observe('card id', C.Id.Value());
        Observer.Observe('card name', C.Name.Value());
        Observer.Observe('card editable', Format(C.Name.Editable()));
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure ZCardPageId_EditOpensTheCard()
    var
        P: TestPage "LT Z XA Base";
    begin
        Seed();
        Meta(Page::"LT Z XA Base", 'ext');
        P.OpenEdit();
        P.First();
        P.Next();
        P.Edit().Invoke();
        P.Close();
        Observer.Expect('ext card page id', '76001');
        Observer.Expect('ext insert allowed', 'Yes');
        Observer.Expect('ext modify allowed', 'Yes');
        Observer.Expect('ext delete allowed', 'Yes');
        Observer.Expect('card id', '2');
        Observer.Expect('card name', 'Two');
        Observer.Expect('card editable', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ZSearchTermsML_PageRunsUnchanged()
    var
        P: TestPage "LT Z XB Base";
    begin
        Seed();
        Meta(Page::"LT Z XB Base", 'ml');
        P.OpenEdit();
        P.First();
        Observer.Observe('name', P.Name.Value());
        Observer.Observe('name editable', Format(P.Name.Editable()));
        Observer.Observe('delete it visible', Format(P.DeleteIt.Visible()));
        P.Close();
        Observer.Expect('ml card page id', '0');
        Observer.Expect('ml insert allowed', 'Yes');
        Observer.Expect('ml modify allowed', 'Yes');
        Observer.Expect('ml delete allowed', 'Yes');
        Observer.Expect('name', 'One');
        Observer.Expect('name editable', 'Yes');
        Observer.Expect('delete it visible', 'Yes');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryD1(var P: TestPage "LT Z XD1 Base")
    begin
        P.DeleteIt.Invoke();
    end;

    [Test]
    procedure ZDeleteAllowed_1()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XD1 Base";
    begin
        Seed();
        Meta(Page::"LT Z XD1 Base", 'page');
        P.OpenEdit();
        P.First();
        ClearLastError();
        Observer.Observe('delete ok', Format(TryD1(P)));
        Observer.ObserveError('delete');
        P.Close();
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'No');
        Observer.Expect('delete ok', 'Yes');
        Observer.Expect('delete|text', '');
        Observer.Expect('delete|code', '');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryD2(var P: TestPage "LT Z XD2 Base")
    begin
        P.DeleteIt.Invoke();
    end;

    [Test]
    procedure ZDeleteAllowed_2()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XD2 Base";
    begin
        Seed();
        Meta(Page::"LT Z XD2 Base", 'page');
        P.OpenEdit();
        P.First();
        ClearLastError();
        Observer.Observe('delete ok', Format(TryD2(P)));
        Observer.ObserveError('delete');
        P.Close();
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('delete ok', 'Yes');
        Observer.Expect('delete|text', '');
        Observer.Expect('delete|code', '');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryD3(var P: TestPage "LT Z XD3 Base")
    begin
        P.DeleteIt.Invoke();
    end;

    [Test]
    procedure ZDeleteAllowed_3()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XD3 Base";
    begin
        Seed();
        Meta(Page::"LT Z XD3 Base", 'page');
        P.OpenEdit();
        P.First();
        ClearLastError();
        Observer.Observe('delete ok', Format(TryD3(P)));
        Observer.ObserveError('delete');
        P.Close();
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('delete ok', 'Yes');
        Observer.Expect('delete|text', '');
        Observer.Expect('delete|code', '');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryD4(var P: TestPage "LT Z XD4 Base")
    begin
        P.DeleteIt.Invoke();
    end;

    [Test]
    procedure ZDeleteAllowed_4()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XD4 Base";
    begin
        Seed();
        Meta(Page::"LT Z XD4 Base", 'page');
        P.OpenEdit();
        P.First();
        ClearLastError();
        Observer.Observe('delete ok', Format(TryD4(P)));
        Observer.ObserveError('delete');
        P.Close();
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'No');
        Observer.Expect('delete ok', 'Yes');
        Observer.Expect('delete|text', '');
        Observer.Expect('delete|code', '');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryI1(var P: TestPage "LT Z XI1 Base")
    begin
        P.New();
        P.Id.SetValue(3);
        P.Name.SetValue('Three');
    end;

    [Test]
    procedure ZInsertAllowed_1()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XI1 Base";
    begin
        Seed();
        Meta(Page::"LT Z XI1 Base", 'page');
        P.OpenEdit();
        P.First();
        ClearLastError();
        Observer.Observe('new ok', Format(TryI1(P)));
        Observer.ObserveError('new');
        P.Close();
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'No');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('new ok', 'No');
        Observer.Expect('new|text', 'New method failed because Insert is not allowed. Page = LT Z XI1 Base, Id = 76106.');
        Observer.Expect('new|code', 'DB:ClientInsertDenied');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryI2(var P: TestPage "LT Z XI2 Base")
    begin
        P.New();
        P.Id.SetValue(3);
        P.Name.SetValue('Three');
    end;

    [Test]
    procedure ZInsertAllowed_2()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XI2 Base";
    begin
        Seed();
        Meta(Page::"LT Z XI2 Base", 'page');
        P.OpenEdit();
        P.First();
        ClearLastError();
        Observer.Observe('new ok', Format(TryI2(P)));
        Observer.ObserveError('new');
        P.Close();
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', '');
        Observer.Expect('new|code', '');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryI3(var P: TestPage "LT Z XI3 Base")
    begin
        P.New();
        P.Id.SetValue(3);
        P.Name.SetValue('Three');
    end;

    [Test]
    procedure ZInsertAllowed_3()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XI3 Base";
    begin
        Seed();
        Meta(Page::"LT Z XI3 Base", 'page');
        P.OpenEdit();
        P.First();
        ClearLastError();
        Observer.Observe('new ok', Format(TryI3(P)));
        Observer.ObserveError('new');
        P.Close();
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', '');
        Observer.Expect('new|code', '');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryI4(var P: TestPage "LT Z XI4 Base")
    begin
        P.New();
        P.Id.SetValue(3);
        P.Name.SetValue('Three');
    end;

    [Test]
    procedure ZInsertAllowed_4()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XI4 Base";
    begin
        Seed();
        Meta(Page::"LT Z XI4 Base", 'page');
        P.OpenEdit();
        P.First();
        ClearLastError();
        Observer.Observe('new ok', Format(TryI4(P)));
        Observer.ObserveError('new');
        P.Close();
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'No');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('new ok', 'No');
        Observer.Expect('new|text', 'New method failed because Insert is not allowed. Page = LT Z XI4 Base, Id = 76109.');
        Observer.Expect('new|code', 'DB:ClientInsertDenied');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryM1(var P: TestPage "LT Z XM1 Base")
    begin
        P.Name.SetValue('Changed');
    end;

    [TryFunction]
    local procedure TryCloseM1(var P: TestPage "LT Z XM1 Base")
    begin
        P.Close();
    end;

    [Test]
    procedure ZModifyAllowed_1()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XM1 Base";
    begin
        Seed();
        Meta(Page::"LT Z XM1 Base", 'page');
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        ClearLastError();
        Observer.Observe('edit ok', Format(TryM1(P)));
        Observer.ObserveError('edit');
        ClearLastError();
        Observer.Observe('close ok', Format(TryCloseM1(P)));
        Observer.ObserveError('close');
        R.Get(1);
        Observer.Observe('stored name', R.Name);
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'No');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('name editable', 'No');
        Observer.Expect('edit ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close|text', 'Page cannot be saved.');
        Observer.Expect('close|code', 'TestWrapped');
        Observer.Expect('stored name', 'One');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryM2(var P: TestPage "LT Z XM2 Base")
    begin
        P.Name.SetValue('Changed');
    end;

    [TryFunction]
    local procedure TryCloseM2(var P: TestPage "LT Z XM2 Base")
    begin
        P.Close();
    end;

    [Test]
    procedure ZModifyAllowed_2()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XM2 Base";
    begin
        Seed();
        Meta(Page::"LT Z XM2 Base", 'page');
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        ClearLastError();
        Observer.Observe('edit ok', Format(TryM2(P)));
        Observer.ObserveError('edit');
        ClearLastError();
        Observer.Observe('close ok', Format(TryCloseM2(P)));
        Observer.ObserveError('close');
        R.Get(1);
        Observer.Observe('stored name', R.Name);
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('name editable', 'Yes');
        Observer.Expect('edit ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('stored name', 'Changed');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryM3(var P: TestPage "LT Z XM3 Base")
    begin
        P.Name.SetValue('Changed');
    end;

    [TryFunction]
    local procedure TryCloseM3(var P: TestPage "LT Z XM3 Base")
    begin
        P.Close();
    end;

    [Test]
    procedure ZModifyAllowed_3()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XM3 Base";
    begin
        Seed();
        Meta(Page::"LT Z XM3 Base", 'page');
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        ClearLastError();
        Observer.Observe('edit ok', Format(TryM3(P)));
        Observer.ObserveError('edit');
        ClearLastError();
        Observer.Observe('close ok', Format(TryCloseM3(P)));
        Observer.ObserveError('close');
        R.Get(1);
        Observer.Observe('stored name', R.Name);
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('name editable', 'Yes');
        Observer.Expect('edit ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('stored name', 'Changed');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryM4(var P: TestPage "LT Z XM4 Base")
    begin
        P.Name.SetValue('Changed');
    end;

    [TryFunction]
    local procedure TryCloseM4(var P: TestPage "LT Z XM4 Base")
    begin
        P.Close();
    end;

    [Test]
    procedure ZModifyAllowed_4()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z XM4 Base";
    begin
        Seed();
        Meta(Page::"LT Z XM4 Base", 'page');
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        ClearLastError();
        Observer.Observe('edit ok', Format(TryM4(P)));
        Observer.ObserveError('edit');
        ClearLastError();
        Observer.Observe('close ok', Format(TryCloseM4(P)));
        Observer.ObserveError('close');
        R.Get(1);
        Observer.Observe('stored name', R.Name);
        Observer.Expect('page card page id', '0');
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'No');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('name editable', 'No');
        Observer.Expect('edit ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close|text', 'Page cannot be saved.');
        Observer.Expect('close|code', 'TestWrapped');
        Observer.Expect('stored name', 'One');
        Observer.Verify();
    end;
}
