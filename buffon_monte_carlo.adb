with Interfaces.C; use Interfaces.C;
with Ada.Numerics; use Ada.Numerics;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Float_Random; use Ada.Numerics.Float_Random;
with Ada.Assertions; use Ada.Assertions;
with Ada.Containers.Vectors;

procedure Buffon_Monte_Carlo is
    type Raylib_Color is record
	R, G, B, A: Unsigned_Char;
    end record
	with Convention => C_Pass_By_Copy;

    type Needle is record
	X, Y, End_X, End_Y: Integer;
	Color: Raylib_Color;
    end record;

    procedure Init_Window (Width, Height: Integer; Title: Char_Array)
	with Import => True, Convention => C, External_Name => "InitWindow";
    function Window_Should_Close return C_bool
	with Import => True, Convention => C, External_Name => "WindowShouldClose";
    procedure Begin_Drawing
	with Import => True, Convention => C, External_Name => "BeginDrawing";
    procedure End_Drawing
	with Import => True, Convention => C, External_Name => "EndDrawing";
    procedure Clear_Background(Col: Raylib_Color)
	with Import => True, Convention => C, External_Name => "ClearBackground";
    procedure Close_Window
	with Import => True, Convention => C, External_Name => "CloseWindow";
    procedure Draw_Line (Start_X, Start_Y, End_X, End_Y: Integer; Col: Raylib_Color)
	with Import => True, Convention => C, External_Name => "DrawLine";
    procedure Draw_Rectangle (Start_X, Start_Y, Width, Height: Integer; Col: Raylib_Color)
	with Import => True, Convention => C, External_Name => "DrawRectangle";
    procedure Set_Target_FPS (FPS: Integer)
	with Import => True, Convention => C, External_Name => "SetTargetFPS";
    procedure Draw_Text (Text: char_array; X,Y,Font_Size: Integer; Col: Raylib_Color)
	with Import => True, Convention => C, External_Name => "DrawText";

    Window_Width: constant Integer := 800;
    Window_Height: constant Integer := 600;

    Bg_Color: constant Raylib_Color := (R => 0, G => 0, B => 0, A => 255);
    Fg_Color: constant Raylib_Color := (R => 0, G => 0, B => 255, A => 255);
    Grid_Color: constant Raylib_Color := (R => 80, G => 80, B => 80, A => 255);
    Text_Color: constant Raylib_Color := (R => 40, G => 120, B => 80, A => 255);

    Grid_Line: Integer;
    Nb_Grid_Lines: Integer := 6;
    Grid_Size: Integer := Window_Width / (Nb_Grid_Lines + 1);

    Needle_Size: Integer := Grid_Size;
    Needle_Color: constant Raylib_Color := (R => 0, G => 180, B => 0, A => 255);

    -- prepare the Needles vector
    package Integer_Vectors is new
    Ada.Containers.Vectors
	(Index_Type   => Natural,
	Element_Type => Needle);
    use Integer_Vectors;
    Needles: Vector;

    -- just count the Needles that cross the grid
    Needles_Crossing: Integer := 0;

    -- The sub window defines the space where Needles are allowed to be thrown.
    -- This avoids Needles to overflow off of the screen but could be bad for Monte Carlo method. -- sleep needed
    Sub_Window_Width: Integer := Window_Width - 2 * Needle_Size;
    Sub_Window_Height: Integer := Window_Height - 2 * Needle_Size;
    Sub_Window_Offset: Integer := Needle_Size;

    procedure Draw_Background_Grid is
    begin
	for Grid_Line in 1 .. Nb_Grid_Lines loop
	    Draw_Line(Grid_Line * Grid_Size, 0, Grid_Line * Grid_Size, Window_Height, Grid_Color);
	end loop;
    end Draw_Background_Grid;

    Seed: Generator;
    function Random_Float return Float is
    begin
	Reset(Seed);
	return Random(Seed);
    end Random_Float;

    function Random_In_Range(Min, Max: Integer) return Integer is
    begin
	if Max < Min then
	    raise Assertion_Error with "ERROR: Max must be greater than min.";
	end if;
	return Min + Integer(Random_Float * Float(Max - Min));
    end Random_In_Range;

    function Random_Needle return Needle is
	Random_Gen: Generator;
	Random_Angle: Float := 360.0 * Random_Float;
	Random_Start_X: Integer := Random_In_Range(Sub_Window_Offset, Window_Width - Sub_Window_Offset);
	Random_Start_Y: Integer := Random_In_Range(Sub_Window_Offset, Window_Height - Sub_Window_Offset);
	End_X: Integer := Random_Start_X + Integer(Cos(Random_Angle * (Pi / 180.0)) * Float(Needle_Size));
	End_Y: Integer := Random_Start_Y + Integer(Sin(Random_Angle * (Pi / 180.0)) * Float(Needle_Size));
    begin
	return (X => Random_Start_X, Y => Random_Start_Y, End_X => End_X, End_Y => End_Y, Color => Needle_Color);
    end Random_Needle;

    procedure Check_If_Needle_Crosses(N: Needle) is
    begin
	for Grid_Line in 1 .. Nb_Grid_Lines loop
	    if (N.X <= Grid_Line * Grid_Size and Grid_Line * Grid_Size <= N.End_X) then
		Needles_Crossing := Needles_Crossing + 1;
	    end if;
	end loop;
    end Check_If_Needle_Crosses;

    procedure Add_Needle is
	N: Needle := Random_Needle;
    begin
	Check_If_Needle_Crosses(N);
	Needles.Append(N);
    end Add_Needle;

    procedure Draw_Needles is
    begin
	For N of Needles loop
	    Draw_Line(N.X, N.Y, N.End_X, N.End_Y, N.Color);
	end loop;
    end Draw_Needles;

    procedure Draw_Infos is
    begin
	Draw_Text("Needles: " & To_C(String(Needles.Length'Image)), 0, 0, 32, Text_Color);
	Draw_Text("Cross: " & To_C(String(Needles_Crossing'Image)), 0, 32, 32, Text_Color);
	Draw_Text("Ratio: " & To_C(String(Float(Float(Needles.Length)/Float(Needles_Crossing))'Image)), 0, 64, 32, Text_Color);
    end Draw_Infos;

begin
    Init_Window(Window_Width, Window_Height, To_C("buffon-monte-carlo"));
    Set_Target_FPS(20);
    while not Window_Should_Close loop
	Clear_Background(Bg_Color);
	Begin_Drawing;
	Draw_Background_Grid;
	    Add_Needle;
	    Draw_Infos;
	    Draw_Needles;
	End_Drawing;
    end loop;
    Close_Window;
end Buffon_Monte_Carlo;
