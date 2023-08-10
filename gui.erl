-module(gui).
-export([start/0]).
-export([handle_click/2, start_sim/5]).
-include_lib("wx/include/wx.hrl").
-author("Shaked Basa").
-define(CELL_SIZE,(40)).
-define(LEAF_SIZE,(20)).
-define(REFRESH_TIME,(250)).

start() ->
	% Start the wxWidgets application
	wx:new(),
	% Create the main frame
	Frame_1 = wxFrame:new(wx:null(), 1, "Life_and_Evolution_of_cells - Menu"),
	% Create static labels
	Label_1 = wxStaticText:new(Frame_1, ?wxID_ANY, "Number of Cells (of each type)"),
	Label_2 = wxStaticText:new(Frame_1, ?wxID_ANY, "World Size"),
	% Create input text fields with initial values and sizes
	Input_1 = wxTextCtrl:new(Frame_1, ?wxID_ANY,[{value, "50"}, {size, {150,50}}]),
	Input_2 = wxTextCtrl:new(Frame_1, ?wxID_ANY,[{value, "800"}, {size, {150,50}}]),
	% Create a font for the text fields
	Font = wxFont:new(38,?wxFONTFAMILY_DEFAULT, ?wxFONTSTYLE_NORMAL, ?wxFONTWEIGHT_BOLD),
	wxTextCtrl:setFont(Input_1, Font),
	wxTextCtrl:setFont(Input_2, Font),
	% Create a button labeled "Start"
	Button = wxButton:new(Frame_1, ?wxID_ANY, [{label, "Start"}, {pos,{0, 64}}, {size, {150, 50}}]),
	% Create a sizer to arrange the elements vertically
	MainSizer = wxBoxSizer:new(?wxVERTICAL),
	wxSizer:add(MainSizer, Label_1, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, Input_1, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, Label_2, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, Input_2, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, Button, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxWindow:setSizer(Frame_1, MainSizer),
	wxSizer:setSizeHints(MainSizer, Frame_1),
	% Connect the button click event to the handle_click function
	wxButton:connect(Button, command_button_clicked, [{callback, fun handle_click/2}, {userData, #{input_1 => Input_1,input_2 => Input_2, env => wx:get_env()}}]),
	% Show the main frame
	wxFrame:show(Frame_1).

%% Function to handle button click events
handle_click(#wx{obj = Button, userData = #{input_1 := Input_1,input_2 := Input_2, env := Env}}, _Event) ->
	% Set the environment
	wx:set_env(Env),
	% Get the label of the clicked button
	Label = wxButton:getLabel(Button),
	% Handle button label
	case Label of

		"Start" ->
			wxTextCtrl:setEditable(Input_2, false),
			% Disable input fields and change button label to "Stop"
			wxTextCtrl:setEditable(Input_1, false),
			wxTextCtrl:setEditable(Input_2, false),
			wxButton:setLabel(Button, "Stop"),
			Val = list_to_integer(wxTextCtrl:getValue(Input_2)),
			if
				Val > 108 ->
					Cell_size = 10,
					wxTextCtrl:setValue(Input_2, integer_to_list(108)),
					UD_Input_2 = 108,
					spawn(?MODULE, start_sim, [Cell_size ,Input_1, UD_Input_2, Button, Env]);
				Val > 54 ->
					% Spawn a new process to start the simulation	
					Cell_size = 10,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,Input_1, UD_Input_2, Button, Env]);	
				Val > 27 ->
					% Spawn a new process to start the simulation	
					Cell_size = 20,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,Input_1, UD_Input_2, Button, Env]);

				true ->
					Cell_size = ?CELL_SIZE,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,Input_1, UD_Input_2, Button, Env])
			end;
		"Stop" ->
			% Enable input fields and change button label to "Start"
			wxTextCtrl:setEditable(Input_1, true),
			wxTextCtrl:setEditable(Input_2, true),
			wxButton:setLabel(Button, "Start")
	end.

start_sim(Cell_size, Input_1, Input_2, Button, Env) ->
	%io:format("Size=~p~n",[Cell_size]),
	% Set the environment
	wx:set_env(Env),

	% get user input 
	N = list_to_integer(wxTextCtrl:getValue(Input_1)),
	Frame_size = Input_2,

	% Create a new ETS named 'main_ets'
	ets:new(main_ets,[public,named_table]),
	
	% Insert random cells into the 'main_ets' table	
    	insert_cells(N,Frame_size,Cell_size),		

	% Create a new frame (The world window)
	Frame = wxFrame:new(wx:null(), 1, "Life_and_Evolution_of_cells",[{size,{Cell_size*Frame_size,Cell_size*Frame_size}}]),
	
	% Create a new frame (The stats window)
	Stats_frame = wxFrame:new(wx:null(), 1, "Statistics - Menu"),
	
	% Create static labels
	S_Label_1 = wxStaticText:new(Stats_frame, ?wxID_ANY, "Number of Cells"),
	S_Label_2 = wxStaticText:new(Stats_frame, ?wxID_ANY, "Number of Nodes"),
	S_Label_3 = wxStaticText:new(Stats_frame, ?wxID_ANY, "Stat_3"),
	S_Label_4 = wxStaticText:new(Stats_frame, ?wxID_ANY, "Stat_4"),
	S_Label_5 = wxStaticText:new(Stats_frame, ?wxID_ANY, "Stat_5"),
	S_Label_6 = wxStaticText:new(Stats_frame, ?wxID_ANY, "Stat_6"),

	% Create Stat text fields with initial values and sizes
	S_Stat_1 = wxTextCtrl:new(Stats_frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_2 = wxTextCtrl:new(Stats_frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_3 = wxTextCtrl:new(Stats_frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_4 = wxTextCtrl:new(Stats_frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_5 = wxTextCtrl:new(Stats_frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_6 = wxTextCtrl:new(Stats_frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	
	% Disable stats fields to edit
	wxTextCtrl:setEditable(S_Stat_1, false),
	wxTextCtrl:setEditable(S_Stat_2, false),
	wxTextCtrl:setEditable(S_Stat_3, false),
	wxTextCtrl:setEditable(S_Stat_4, false),
	wxTextCtrl:setEditable(S_Stat_5, false),
	wxTextCtrl:setEditable(S_Stat_6, false),
	
	% Create a font for the stats text fields
	Font = wxFont:new(38,?wxFONTFAMILY_DEFAULT, ?wxFONTSTYLE_NORMAL, ?wxFONTWEIGHT_BOLD),
	wxTextCtrl:setFont(S_Stat_1, Font),
	wxTextCtrl:setFont(S_Stat_2, Font),
	wxTextCtrl:setFont(S_Stat_3, Font),
	wxTextCtrl:setFont(S_Stat_4, Font),
	wxTextCtrl:setFont(S_Stat_5, Font),
	wxTextCtrl:setFont(S_Stat_6, Font),

	% Create a sizer to arrange the elements vertically
	MainSizer = wxBoxSizer:new(?wxHORIZONTAL),
	wxSizer:add(MainSizer, S_Label_1, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, S_Stat_1, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, S_Label_2, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, S_Stat_2, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, S_Label_3, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, S_Stat_3, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, S_Label_4, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, S_Stat_4, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, S_Label_5, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, S_Stat_5, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, S_Label_6, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, S_Stat_6, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxWindow:setSizer(Stats_frame, MainSizer),
	wxSizer:setSizeHints(MainSizer, Stats_frame),

	% Load and scale the cells images from file
	General = wxImage:new("general.png"),
	Generalc = wxImage:scale(General,Cell_size,Cell_size),
    	BmpGeneral = wxBitmap:new(Generalc),
  	wxImage:destroy(General),
  	wxImage:destroy(Generalc),

	Ceed = wxImage:new("ceed.png"),
	Ceedc = wxImage:scale(Ceed,Cell_size,Cell_size),
    	BmpCeed = wxBitmap:new(Ceedc),
  	wxImage:destroy(Ceed),
  	wxImage:destroy(Ceedc),

	Leaf = wxImage:new("leaf.png"),
	Leafc = wxImage:scale(Leaf,Cell_size div 2,Cell_size div 2),
    	BmpLeaf = wxBitmap:new(Leafc),
  	wxImage:destroy(Leaf),
  	wxImage:destroy(Leafc),

	Antena = wxImage:new("antena.png"),
	Antenac = wxImage:scale(Antena,Cell_size,Cell_size),
    	BmpAntena = wxBitmap:new(Antenac),
  	wxImage:destroy(Antena),
  	wxImage:destroy(Antenac),

	Root = wxImage:new("root.png"),
	Rootc = wxImage:scale(Root,Cell_size,Cell_size),
    	BmpRoot = wxBitmap:new(Rootc),
  	wxImage:destroy(Root),
  	wxImage:destroy(Rootc),

	% Print cells on the canvas based on the data in 'main_ets' table
	print_cells(main_ets,ets:first(main_ets), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot, 0),
	
	% Show the frame to display the canvas
	wxFrame:show(Stats_frame),	
	wxFrame:show(Frame),
	canvas_loop(Frame_size, Cell_size, Button, main_ets, Frame, Stats_frame, S_Stat_1, BmpGeneral, BmpCeed, BmpLeaf, BmpAntena, BmpRoot, N, 50).
	
%% Function to continuously update and display the canvas
canvas_loop(_Frame_size,_Cell_size, _Button,_main_ets,Frame, Stats_frame, _S_Stat_1, _BmpGeneral, _BmpCeed, _BmpLeaf , _BmpAntena , _BmpRoot,_N,0) ->
	ets:delete(main_ets),
	wxFrame:destroy(Stats_frame),					
	wxFrame:destroy(Frame),	
	ok;	
canvas_loop(Frame_size, Cell_size, Button,main_ets, Frame, Stats_frame, S_Stat_1, BmpGeneral, BmpCeed, BmpLeaf, BmpAntena, BmpRoot, N, I) ->
	case wxButton:getLabel(Button) of
		"Stop" ->
			% Clear the 'main_ets' table
			ets:delete_all_objects(main_ets),
			% Insert new random cells into the 'main_ets' table
			insert_cells(N,Frame_size,Cell_size),
			% Clear the canvas by destroying all children of the frame
			wxWindow:destroyChildren(Frame),
			% Print the updated cells on the canvas
			Num_of_cells = print_cells(main_ets,ets:first(main_ets), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot, 0),
			% Refresh the canvas to display the changes
			wxTextCtrl:setValue(S_Stat_1, integer_to_list(Num_of_cells)),
			wxWindow:refresh(Frame),
			wxWindow:refresh(Stats_frame),
			% Introduce a delay for animation effect
			timer:sleep(?REFRESH_TIME),
			 % Recursive call to continue the loop
			canvas_loop(Frame_size,Cell_size, Button, main_ets, Frame, Stats_frame, S_Stat_1, BmpGeneral, BmpCeed, BmpLeaf, BmpAntena, BmpRoot, N, I-1);
		"Start" ->
			% Delete the 'main_ets' table
			ets:delete(main_ets),	
			wxFrame:destroy(Stats_frame),			
			wxFrame:destroy(Frame)
	end.

% Function to print cells on the canvas based on the data in 'main_ets' table
% Input: Key (the current key in the 'main_ets' table)
%        Frame (the frame where the cells are displayed)
%        Bmp_x_ (the _x_ bitmap)
%        _x_ = {General, Ceed, Leaf, Antena, Root}
print_cells(main_ets, Key, Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot, Counter) ->
	case ets:lookup(main_ets, Key) of
		[] ->	
			Counter;
		[{{X,Y},general}] ->
			wxStaticBitmap:new(Frame,?wxID_ANY , BmpGeneral, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		[{{X,Y}, ceed}] ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpCeed, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		[{{X,Y}, leaf}] ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpLeaf, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		[{{X,Y}, antena}] ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpAntena, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		[{{X,Y}, root}] ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpRoot, [{pos,{X,Y}}]),
			print_cells(main_ets, ets:next(main_ets,Key), Frame, BmpGeneral, BmpCeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1)
	end.

% Function to insert random points (cells) into the 'main_ets' table
% Input: N (number of points to insert)	
insert_cells(0,_,_) -> 
	ok;
insert_cells(N,Frame_size,Cell_size) ->
	% Insert a random blue cell and a random green cell into the 'main_ets' table
	ets:insert(main_ets, {{rand:uniform(Cell_size*Frame_size-(Cell_size div 2)),rand:uniform(Cell_size*Frame_size-(Cell_size div 2))}, general}),
	ets:insert(main_ets, {{rand:uniform(Cell_size*Frame_size-(Cell_size div 2)),rand:uniform(Cell_size*Frame_size-(Cell_size div 2))}, ceed}),
	ets:insert(main_ets, {{rand:uniform(Cell_size*Frame_size-(Cell_size div 2)),rand:uniform(Cell_size*Frame_size-(Cell_size div 2))}, leaf}),
	ets:insert(main_ets, {{rand:uniform(Cell_size*Frame_size-(Cell_size div 2)),rand:uniform(Cell_size*Frame_size-(Cell_size div 2))}, antena}),
	ets:insert(main_ets, {{rand:uniform(Cell_size*Frame_size-(Cell_size div 2)),rand:uniform(Cell_size*Frame_size-(Cell_size div 2))}, root}),

	% Recursively insert (N-1) points
	insert_cells(N - 1, Frame_size,Cell_size).





