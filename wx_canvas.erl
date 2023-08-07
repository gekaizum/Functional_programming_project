-module(wx_canvas).
-export([start/1]).
-include_lib("wx/include/wx.hrl").
-author("Shaked Basa").

% Function to start the canvas application
% Input: N (number of Cells to insert)

start(N) ->
	% Start the wxWidgets application
	wx:new(),
	
	% Create a new ETS named 'main_ets'
	ets:new(main_ets,[public,named_table]),
	
	% Insert random cells into the 'main_ets' table	
    	insert_cells(N),
	
	% Create a new frame (window)
	Frame = wxFrame:new(wx:null(), 1, "Life_and_Evolution_of_cells",[{size,{1000,1000}}]),
	
	% Load and scale blue and green images from file
	Blue = wxImage:new("blue.png"),
	Bluec = wxImage:scale(Blue,10,10),
    	BmpBlue = wxBitmap:new(Bluec),
  	wxImage:destroy(Blue),
  	wxImage:destroy(Bluec),
	Green = wxImage:new("green.png"),
	Greenc = wxImage:scale(Green,10,10),
    	BmpGreen = wxBitmap:new(Greenc),
  	wxImage:destroy(Green),
  	wxImage:destroy(Greenc),
	
	% Print cells on the canvas based on the data in 'main_ets' table
	print_cells(main_ets,ets:first(main_ets), Frame, BmpGreen, BmpBlue),
	
	% Show the frame to display the canvas
	wxFrame:show(Frame),
	% Sleep for 10 seconds (delay the termination of the application)
	timer:sleep(10000),
	
	% Destroy the wxWidgets application and cleanup resources	
	wx:destroy(),
	
	% Delete the 'main_ets' table
	ets:delete(main_ets),	
	ok.

% Function to print cells on the canvas based on the data in 'main_ets' table
% Input: Key (the current key in the 'main_ets' table)
%        Frame (the frame where the cells are displayed)
%        BmpGreen (the green bitmap)
%        BmpBlue (the blue bitmap)
print_cells(main_ets, Key, Frame, BmpGreen, BmpBlue) ->
	case ets:lookup(main_ets, Key) of
		[] ->	
			finished;
		[{{X,Y},blue}] ->
			wxStaticBitmap:new(Frame,?wxID_ANY , BmpBlue, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGreen, BmpBlue);
		[{{X,Y}, green}] ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpGreen, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGreen, BmpBlue)
	end.

% Function to insert random points (cells) into the 'main_ets' table
% Input: N (number of points to insert)	
insert_cells(0) -> 
	ok;
insert_cells(N) ->
	% Insert a random blue cell and a random green cell into the 'main_ets' table
	ets:insert(main_ets, {{rand:uniform(1000),rand:uniform(1000)}, blue}),
	ets:insert(main_ets, {{rand:uniform(1000),rand:uniform(1000)}, green}),
	% Recursively insert (N-1) points
	insert_cells(N - 1).



