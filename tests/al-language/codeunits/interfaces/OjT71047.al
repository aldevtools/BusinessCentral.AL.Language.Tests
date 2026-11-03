// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), interfaces and codeunits of this file, self-contained test codeunit 71051
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Interface variables: implementing codeunits, assignment, shared instance, uninitialized call, default implementation via enum
// BC versions: 29 (27 and 28 by CI)

interface "LT OjT IShape"
{
    procedure GetArea(): Integer;
    procedure ShapeName(): Text;
    procedure Grow(By: Integer);
    procedure Describe(var Info: Text): Boolean;
}

codeunit 71047 "LT OjT Square" implements "LT OjT IShape"
{
    var
        Side: Integer;

    procedure Init(NewSide: Integer)
    begin
        Side := NewSide;
    end;

    procedure GetArea(): Integer
    begin
        exit(Side * Side);
    end;

    procedure ShapeName(): Text
    begin
        exit('Square');
    end;

    procedure Grow(By: Integer)
    begin
        Side += By;
    end;

    procedure Describe(var Info: Text): Boolean
    begin
        Info := 'side=' + Format(Side);
        exit(Side > 0);
    end;
}

codeunit 71048 "LT OjT Rect" implements "LT OjT IShape"
{
    var
        W: Integer;
        H: Integer;

    procedure Init(NewW: Integer; NewH: Integer)
    begin
        W := NewW;
        H := NewH;
    end;

    procedure GetArea(): Integer
    begin
        exit(W * H);
    end;

    procedure ShapeName(): Text
    begin
        exit('Rect');
    end;

    procedure Grow(By: Integer)
    begin
        W += By;
        H += By;
    end;

    procedure Describe(var Info: Text): Boolean
    begin
        Info := 'w=' + Format(W) + ',h=' + Format(H);
        exit(true);
    end;
}

codeunit 71049 "LT OjT Shape Plain" implements "LT OjT IShape"
{
    procedure GetArea(): Integer
    begin
        exit(-1);
    end;

    procedure ShapeName(): Text
    begin
        exit('Plain');
    end;

    procedure Grow(By: Integer)
    begin
    end;

    procedure Describe(var Info: Text): Boolean
    begin
        Info := 'plain';
        exit(false);
    end;
}

enum 71050 "LT OjT Shape" implements "LT OjT IShape"
{
    Extensible = false;
    DefaultImplementation = "LT OjT IShape" = "LT OjT Shape Plain";

    value(0; Plain) { }
    value(1; Square) { Implementation = "LT OjT IShape" = "LT OjT Square"; }
    value(2; Rect) { Implementation = "LT OjT IShape" = "LT OjT Rect"; }
}

codeunit 71051 "LT OjT Interface Basics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Assign_FromCodeunitVariable()
    var
        Observer: Codeunit "Probe Observer";
        Sq: Codeunit "LT OjT Square";
        Shape: Interface "LT OjT IShape";
        Info: Text;
        Ok: Boolean;
    begin
        Sq.Init(3);
        Shape := Sq;
        Observer.Observe('area', Format(Shape.GetArea()));
        Observer.Observe('name', Shape.ShapeName());
        Shape.Grow(2);
        Observer.Observe('areaAfterGrow', Format(Shape.GetArea()));
        Observer.Observe('codeunitSeesGrow', Format(Sq.GetArea()));
        Ok := Shape.Describe(Info);
        Observer.Observe('describe', Format(Ok) + '|' + Info);
        Observer.Expect('area', '9');
        Observer.Expect('name', 'Square');
        Observer.Expect('areaAfterGrow', '25');
        Observer.Expect('codeunitSeesGrow', '25');
        Observer.Expect('describe', 'Yes|side=5');
        Observer.Verify();
    end;

    [Test]
    procedure Assign_SharedInstance()
    var
        Observer: Codeunit "Probe Observer";
        Sq: Codeunit "LT OjT Square";
        S1: Interface "LT OjT IShape";
        S2: Interface "LT OjT IShape";
    begin
        Sq.Init(1);
        S1 := Sq;
        S2 := S1;
        S1.Grow(4);
        Observer.Observe('s1', Format(S1.GetArea()));
        Observer.Observe('s2', Format(S2.GetArea()));
        Observer.Observe('sq', Format(Sq.GetArea()));
        Sq.Grow(1);
        Observer.Observe('s1AfterCodeunitGrow', Format(S1.GetArea()));
        Observer.Expect('s1', '25');
        Observer.Expect('s2', '25');
        Observer.Expect('sq', '25');
        Observer.Expect('s1AfterCodeunitGrow', '36');
        Observer.Verify();
    end;

    [Test]
    procedure Assign_Reassign()
    var
        Observer: Codeunit "Probe Observer";
        Sq: Codeunit "LT OjT Square";
        Rc: Codeunit "LT OjT Rect";
        Shape: Interface "LT OjT IShape";
    begin
        Sq.Init(2);
        Rc.Init(2, 5);
        Shape := Sq;
        Observer.Observe('first', Shape.ShapeName() + ':' + Format(Shape.GetArea()));
        Shape := Rc;
        Observer.Observe('second', Shape.ShapeName() + ':' + Format(Shape.GetArea()));
        Shape.Grow(1);
        Observer.Observe('grown', Format(Shape.GetArea()));
        Observer.Observe('squareUnchanged', Format(Sq.GetArea()));
        Observer.Expect('first', 'Square:4');
        Observer.Expect('second', 'Rect:10');
        Observer.Expect('grown', '18');
        Observer.Expect('squareUnchanged', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Uninitialized_Call()
    var
        Observer: Codeunit "Probe Observer";
        Shape: Interface "LT OjT IShape";
        N: Integer;
        T: Text;
    begin
        asserterror N := Shape.GetArea();
        Observer.ObserveError('area');
        asserterror T := Shape.ShapeName();
        Observer.ObserveError('name');
        asserterror Shape.Grow(1);
        Observer.ObserveError('grow');
        Observer.Expect('area|text', 'Interface not initialized');
        Observer.Expect('area|code', 'InvalidOperation');
        Observer.Expect('name|text', 'Interface not initialized');
        Observer.Expect('name|code', 'InvalidOperation');
        Observer.Expect('grow|text', 'Interface not initialized');
        Observer.Expect('grow|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Uninitialized_AfterClear()
    var
        Observer: Codeunit "Probe Observer";
        Sq: Codeunit "LT OjT Square";
        Shape: Interface "LT OjT IShape";
        N: Integer;
    begin
        Sq.Init(2);
        Shape := Sq;
        Observer.Observe('before', Format(Shape.GetArea()));
        Clear(Shape);
        asserterror N := Shape.GetArea();
        Observer.ObserveError('afterClear');
        Observer.Expect('before', '4');
        Observer.Expect('afterClear|text', 'Interface not initialized');
        Observer.Expect('afterClear|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Uninitialized_AssignedFromUninitialized()
    var
        Observer: Codeunit "Probe Observer";
        A: Interface "LT OjT IShape";
        B: Interface "LT OjT IShape";
        N: Integer;
    begin
        asserterror B := A;
        Observer.ObserveError('af224');
        asserterror N := B.GetArea();
        Observer.ObserveError('copyOfEmpty');
        Observer.Expect('af224|text', 'Interface not initialized');
        Observer.Expect('af224|code', 'InvalidOperation');
        Observer.Expect('copyOfEmpty|text', 'Interface not initialized');
        Observer.Expect('copyOfEmpty|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_ImplementationSelection()
    var
        Observer: Codeunit "Probe Observer";
        Kind: Enum "LT OjT Shape";
        Shape: Interface "LT OjT IShape";
        Info: Text;
        Ok: Boolean;
    begin
        Kind := Kind::Square;
        Shape := Kind;
        Observer.Observe('square.name', Shape.ShapeName());
        Observer.Observe('square.area', Format(Shape.GetArea()));
        Kind := Kind::Rect;
        Shape := Kind;
        Observer.Observe('rect.name', Shape.ShapeName());
        Observer.Observe('rect.area', Format(Shape.GetArea()));
        Kind := Kind::Plain;
        Shape := Kind;
        Observer.Observe('plain.name', Shape.ShapeName());
        Ok := Shape.Describe(Info);
        Observer.Observe('plain.describe', Format(Ok) + '|' + Info);
        Observer.Expect('square.name', 'Square');
        Observer.Expect('square.area', '0');
        Observer.Expect('rect.name', 'Rect');
        Observer.Expect('rect.area', '0');
        Observer.Expect('plain.name', 'Plain');
        Observer.Expect('plain.describe', 'No|plain');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_ImplementationIsFreshInstance()
    var
        Observer: Codeunit "Probe Observer";
        Kind: Enum "LT OjT Shape";
        S1: Interface "LT OjT IShape";
        S2: Interface "LT OjT IShape";
    begin
        Kind := Kind::Square;
        S1 := Kind;
        S1.Grow(3);
        S2 := Kind;
        Observer.Observe('s1', Format(S1.GetArea()));
        Observer.Observe('s2', Format(S2.GetArea()));
        S2.Grow(2);
        Observer.Observe('s1again', Format(S1.GetArea()));
        Observer.Observe('s2again', Format(S2.GetArea()));
        Observer.Expect('s1', '9');
        Observer.Expect('s2', '0');
        Observer.Expect('s1again', '9');
        Observer.Expect('s2again', '4');
        Observer.Verify();
    end;

    [Test]
    procedure VarParameter_ThroughInterface()
    var
        Observer: Codeunit "Probe Observer";
        Rc: Codeunit "LT OjT Rect";
        Shape: Interface "LT OjT IShape";
        Info: Text;
    begin
        Rc.Init(4, 6);
        Shape := Rc;
        Info := 'unchanged';
        Observer.Observe('result', Format(Shape.Describe(Info)));
        Observer.Observe('info', Info);
        Observer.Expect('result', 'Yes');
        Observer.Expect('info', 'w=4,h=6');
        Observer.Verify();
    end;

    [Test]
    procedure PassInterface_ToProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Sq: Codeunit "LT OjT Square";
        Shape: Interface "LT OjT IShape";
    begin
        Sq.Init(2);
        Observer.Observe('byValue', Format(AreaOf(Sq)));
        Observer.Observe('grew', Format(Sq.GetArea()));
        Shape := Sq;
        Observer.Observe('viaVar', Format(GrowAndArea(Shape)));
        Observer.Expect('byValue', '9');
        Observer.Expect('grew', '9');
        Observer.Expect('viaVar', '169');
        Observer.Verify();
    end;

    local procedure AreaOf(Shape: Interface "LT OjT IShape"): Integer
    begin
        Shape.Grow(1);
        exit(Shape.GetArea());
    end;

    local procedure GrowAndArea(var Shape: Interface "LT OjT IShape"): Integer
    begin
        Shape.Grow(10);
        exit(Shape.GetArea());
    end;
}
