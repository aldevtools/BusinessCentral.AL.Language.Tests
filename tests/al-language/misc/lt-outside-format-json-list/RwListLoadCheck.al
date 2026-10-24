// Fixture of collections/RefSemantics.al (writer RW, al-runner issue 5810): the reporter's codeunit, which loops foreach over a List
// parameter and passes the same list by value to a local procedure that reads it with Count and Get; plus a variant that adds to the list
// through that by-value parameter inside the loop. Not a test codeunit. Object id 88793.
codeunit 88793 "LT RW List Load Check"
{
    procedure PointsAboveCapacity(Starts: List of [Integer]; Capacity: Integer): Integer
    var
        Point: Integer;
        Count: Integer;
    begin
        foreach Point in Starts do
            if LoadAt(Point, Starts) > Capacity then
                Count += 1;
        exit(Count);
    end;

    local procedure LoadAt(Point: Integer; Starts: List of [Integer]) Load: Integer
    var
        i: Integer;
    begin
        for i := 1 to Starts.Count() do
            if Starts.Get(i) <= Point then
                Load += 1;
    end;

    [TryFunction]
    procedure TryAddThroughByValueParam(Starts: List of [Integer]; var Visited: Text)
    var
        Point: Integer;
    begin
        foreach Point in Starts do begin
            Visited += Format(Point) + ',';
            AddOne(Starts);
        end;
    end;

    local procedure AddOne(Starts: List of [Integer])
    begin
        Starts.Add(99);
    end;
}
