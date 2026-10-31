// Scope: in-scope
// Fixtures used: none (see the fixture file of this folder)

codeunit 90599 "LT WB Lookup Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure OnePartWithOneLinkedFieldShowsThePickedResource()
    var
        Schedule: TestPage "LT WB Single Link Schedule";
    begin
        Setup();
        Schedule.OpenEdit();
        Schedule.ResourceNo.Lookup();
        AssertPickedResource(Schedule.ResourceNo.Value());
        Schedule.Close();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure OnePartWithTwoLinkedFieldsShowsThePickedResource()
    var
        Schedule: TestPage "LT WB Multi Link Schedule";
    begin
        Setup();
        Schedule.OpenEdit();
        Schedule.ResourceNo.Lookup();
        AssertPickedResource(Schedule.ResourceNo.Value());
        Schedule.Close();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure TwoPartsWithOneLinkedFieldEachShowThePickedResource()
    var
        Schedule: TestPage "LT WB Two Parts Schedule";
    begin
        Setup();
        Schedule.OpenEdit();
        Schedule.ResourceNo.Lookup();
        AssertPickedResource(Schedule.ResourceNo.Value());
        Schedule.Close();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure TwoLinkedFieldsAndPartUpdateShowThePickedResource()
    var
        Schedule: TestPage "LT WB Multi Link Part Update";
    begin
        Setup();
        Schedule.OpenEdit();
        Schedule.ResourceNo.Lookup();
        AssertPickedResource(Schedule.ResourceNo.Value());
        Schedule.Close();
    end;

    [Test]
    [HandlerFunctions('ChooseMachineCenter,PickSecondResource')]
    procedure TwoLinkedFieldsAndMenuShowThePickedResource()
    var
        Schedule: TestPage "LT WB Multi Link Menu";
    begin
        Setup();
        Schedule.OpenEdit();
        Schedule.ResourceNo.Lookup();
        AssertPickedResource(Schedule.ResourceNo.Value());
        Schedule.Close();
    end;

    [ModalPageHandler]
    procedure PickSecondResource(var ResourceList: TestPage "LT WB Lookup Resource List")
    begin
        ResourceList.GoToKey('R2');
        ResourceList.OK().Invoke();
    end;

    [StrMenuHandler]
    procedure ChooseMachineCenter(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 2;
    end;

    local procedure Setup()
    var
        Setting: Record "LT WB Lookup Setting";
        Resource: Record "LT WB Lookup Resource";
    begin
        Setting.DeleteAll();
        Resource.DeleteAll();
        InsertResource(Resource, 'R1', 'G1');
        InsertResource(Resource, 'R2', 'G1');
        InsertResource(Resource, 'R3', 'G2');
    end;

    local procedure InsertResource(var Resource: Record "LT WB Lookup Resource"; ResourceNo: Code[20]; GroupCode: Code[20])
    begin
        Resource.Init();
        Resource."No." := ResourceNo;
        Resource."Group Code" := GroupCode;
        Resource.Insert();
    end;

    local procedure AssertPickedResource(ActualResourceNo: Text)
    begin
        if ActualResourceNo <> 'R2' then
            Error('Resource No. shows [%1] after the lookup.', ActualResourceNo);
    end;
}
