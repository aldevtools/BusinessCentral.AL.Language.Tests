// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects table 73686, pages 73688 - 73689, codeunits 73687, 73690
// Probe: al-runner issue 8523, path P2a. The CardPart drilldown of pages/parts/TestCardPartDrilldownRefresh.al (a Document host, a CardPart
//   with UpdatePropagation = Both whose drilldown changes the stored header and calls CurrPage.Update(false); the host's next SetValue
//   validates against the stored header), here after an earlier step on the host: a host control whose OnValidate errors, alone or after
//   CurrPage.Update(true) or Update(false). What the host shows after the drilldown, which package the scan used, and what is stored.
// Facts (measured on BC 28.5; 27.5 and 29.0 see the pull request): the earlier failed step changes nothing. In every variant the host
//   shows FIRST after the drilldown, the scan uses SECOND (the stored header), and the host shows SECOND after the scan.
// BC versions: 27, 28, 29

table 73686 "LT FU Packing"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; PackageCode; Code[20]) { }
        field(3; LastScannedPackage; Code[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 73688 "LT FU Package Actions"
{
    PageType = CardPart;
    SourceTable = "LT FU Packing";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            cuegroup(Commands)
            {
                field(NewPackage; Count)
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        Header: Record "LT FU Packing";
                    begin
                        Rec.FilterGroup(4);
                        Header.Get(Rec.GetRangeMax(Id));
                        Rec.FilterGroup(0);
                        Header.PackageCode := 'SECOND';
                        Header.Modify(true);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    var
        Count: Integer;
}

page 73689 "LT FU Packing Document"
{
    PageType = Document;
    SourceTable = "LT FU Packing";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(PackageCode; Rec.PackageCode) { ApplicationArea = All; }
                field(Scan; ScanValue)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.LastScannedPackage := Rec.PackageCode;
                        Rec.Modify();
                        CurrPage.Update(false);
                    end;
                }
                field(Boom; Boom)
                {
                    ApplicationArea = All;

                    // The earlier step: always ends with an error, after the step the test picks.
                    trigger OnValidate()
                    begin
                        case Setting.BoomMode() of
                            1:
                                CurrPage.Update(true);
                            2:
                                CurrPage.Update(false);
                        end;
                        Error('LT FU boom');
                    end;
                }
            }
            part(PackageActions; "LT FU Package Actions")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
                UpdatePropagation = Both;
            }
        }
    }

    var
        Setting: Codeunit "LT FU Packing Setting";
        ScanValue: Text[20];
        Boom: Integer;
}

// The step of the failing host control. Used by test codeunit 73690 only.
codeunit 73687 "LT FU Packing Setting"
{
    SingleInstance = true;

    var
        Boom: Integer;

    // 0: error only, 1: CurrPage.Update(true) then error, 2: CurrPage.Update(false) then error.
    procedure SetBoomMode(NewBoom: Integer)
    begin
        Boom := NewBoom;
    end;

    procedure BoomMode(): Integer
    begin
        exit(Boom);
    end;
}

codeunit 73690 "LT FU Drilldown Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Setting: Codeunit "LT FU Packing Setting";

    [TryFunction]
    local procedure TryBoom(var Document: TestPage "LT FU Packing Document")
    begin
        Document.Boom.SetValue(1);
    end;

    [TryFunction]
    local procedure TryScan(var Document: TestPage "LT FU Packing Document")
    begin
        Document.Scan.SetValue('SCAN');
    end;

    local procedure Stored(): Text
    var
        Row: Record "LT FU Packing";
    begin
        if not Row.Get('ORDER') then
            exit('none');
        exit(Row.PackageCode + '/' + Row.LastScannedPackage);
    end;

    local procedure Run(WithBoom: Boolean; BoomMode: Integer)
    var
        Row: Record "LT FU Packing";
        Document: TestPage "LT FU Packing Document";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row.Id := 'ORDER';
        Row.PackageCode := 'FIRST';
        Row.Insert();
        Setting.SetBoomMode(BoomMode);
        Document.OpenEdit();
        Document.GoToRecord(Row);
        if WithBoom then begin
            Ok := TryBoom(Document);
            Observer.Observe('boom', Format(Ok));
            if not Ok then
                Observer.ObserveError('boom error');
            Observer.Observe('stored after boom', Stored());
        end;
        Document.PackageActions.NewPackage.DrillDown();
        Observer.Observe('shown after drilldown', Document.PackageCode.Value());
        Observer.Observe('stored after drilldown', Stored());
        Ok := TryScan(Document);
        Observer.Observe('scan', Format(Ok));
        if not Ok then
            Observer.ObserveError('scan error');
        Observer.Observe('shown after scan', Document.PackageCode.Value());
        Observer.Observe('stored after scan', Stored());
        Document.Close();
        Observer.Observe('stored', Stored());
    end;

    // The pinned shape (TestCardPartDrilldownRefresh.al), no earlier step.
    [Test]
    procedure Drilldown_NoEarlierStep()
    begin
        Run(false, 0);
        Observer.Expect('shown after drilldown', 'FIRST');
        Observer.Expect('stored after drilldown', 'SECOND/');
        Observer.Expect('scan', 'Yes');
        Observer.Expect('shown after scan', 'SECOND');
        Observer.Expect('stored after scan', 'SECOND/SECOND');
        Observer.Expect('stored', 'SECOND/SECOND');
        Observer.Verify();
    end;

    // Earlier step: a host OnValidate that only errors.
    [Test]
    procedure Drilldown_AfterErrorOnly()
    begin
        Run(true, 0);
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('stored after boom', 'FIRST/');
        Observer.Expect('shown after drilldown', 'FIRST');
        Observer.Expect('stored after drilldown', 'SECOND/');
        Observer.Expect('scan', 'Yes');
        Observer.Expect('shown after scan', 'SECOND');
        Observer.Expect('stored after scan', 'SECOND/SECOND');
        Observer.Expect('stored', 'SECOND/SECOND');
        Observer.Verify();
    end;

    // Earlier step: a host OnValidate that calls CurrPage.Update(true), then errors.
    [Test]
    procedure Drilldown_AfterFailedUpdateTrue()
    begin
        Run(true, 1);
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('stored after boom', 'FIRST/');
        Observer.Expect('shown after drilldown', 'FIRST');
        Observer.Expect('stored after drilldown', 'SECOND/');
        Observer.Expect('scan', 'Yes');
        Observer.Expect('shown after scan', 'SECOND');
        Observer.Expect('stored after scan', 'SECOND/SECOND');
        Observer.Expect('stored', 'SECOND/SECOND');
        Observer.Verify();
    end;

    // Earlier step: a host OnValidate that calls CurrPage.Update(false), then errors.
    [Test]
    procedure Drilldown_AfterFailedUpdateFalse()
    begin
        Run(true, 2);
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('stored after boom', 'FIRST/');
        Observer.Expect('shown after drilldown', 'FIRST');
        Observer.Expect('stored after drilldown', 'SECOND/');
        Observer.Expect('scan', 'Yes');
        Observer.Expect('shown after scan', 'SECOND');
        Observer.Expect('stored after scan', 'SECOND/SECOND');
        Observer.Expect('stored', 'SECOND/SECOND');
        Observer.Verify();
    end;
}
