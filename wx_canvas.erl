-module(wx_canvas).
-export([start/1]).
-include_lib("wx/include/wx.hrl").
-author("Shaked Basa").
-define(x_frame_size,(1000)).
-define(y_frame_size,(1000)).
-define(x_cell_size,(40)).
-define(y_cell_size,(40)).
-define(x_leaf_size,(20)).
-define(y_leaf_size,(20)).

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
	Frame = wxFrame:new(wx:null(), 1, "Life_and_Evolution_of_cells",[{size,{?x_frame_size,?y_frame_size}}]),
	
	% Load and scale the cells images from file
	General = wxImage:new("general.png"),
	Generalc = wxImage:scale(General,?x_cell_size,?y_cell_size),
    	BmpGeneral = wxBitmap:new(Generalc),
  	wxImage:destroy(General),
  	wxImage:destroy(Generalc),

	Ceed = wxImage:new("ceed.png"),
	Ceedc = wxImage:scale(Ceed,?x_cell_size,?y_cell_size),
    	BmpCeed = wxBitmap:new(Ceedc),
  	wxImage:destroy(Ceed),
  	wxImage:destroy(Ceedc),

	Leaf = wxImage:new("leaf.png"),
	Leafc = wxImage:scale(Leaf,?x_leaf_size,?y_leaf_size),
    	BmpLeaf = wxBitmap:new(Leafc),
  	wxImage:destroy(Leaf),
  	wxImage:destroy(Leafc),

	Antena = wxImage:new("antena.png"),
	Antenac = wxImage:scale(Antena,?x_cell_size,?y_cell_size),
    	BmpAntena = wxBitmap:new(Antenac),
  	wxImage:destroy(Antena),
  	wxImage:destroy(Antenac),

	Root = wxImage:new("root.png"),
	Rootc = wxImage:scale(Root,?x_cell_size,?y_cell_size),
    	BmpRoot = wxBitmap:new(Rootc),
  	wxImage:destroy(Root),
  	wxImage:destroy(Rootc),

	% Print cells on the canvas based on the data in 'main_ets' table
	print_cells(main_ets,ets:first(main_ets), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot),
	
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
%        Bmp_x_ (the _x_ bitmap)
%        _x_ = {General, Ceed, Leaf, Antena, Root}
print_cells(main_ets, Key, Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot) ->
	case ets:lookup(main_ets, Key) of
		[] ->	
			finished;
		[{{X,Y},general}] ->
			wxStaticBitmap:new(Frame,?wxID_ANY , BmpGeneral, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot);
		[{{X,Y}, ceed}] ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpCeed, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot);
		[{{X,Y}, leaf}] ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpLeaf, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot);
		[{{X,Y}, antena}] ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpAntena, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot);
		[{{X,Y}, root}] ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpRoot, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot)
	end.

% Function to insert random points (cells) into the 'main_ets' table
% Input: N (number of points to insert)	
insert_cells(0) -> 
	ok;
insert_cells(N) ->
	% Insert a random blue cell and a random green cell into the 'main_ets' table
	ets:insert(main_ets, {{rand:uniform(1000),rand:uniform(1000)}, general}),
	ets:insert(main_ets, {{rand:uniform(1000),rand:uniform(1000)}, ceed}),
	ets:insert(main_ets, {{rand:uniform(1000),rand:uniform(1000)}, leaf}),
	ets:insert(main_ets, {{rand:uniform(1000),rand:uniform(1000)}, antena}),
	ets:insert(main_ets, {{rand:uniform(1000),rand:uniform(1000)}, root}),

	% Recursively insert (N-1) points
	insert_cells(N - 1).


