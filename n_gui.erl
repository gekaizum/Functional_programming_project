-module(n_gui).
-export([start/0]).
-export([init_handle_click/2,start_handle_click/2,start_sim/6]).
-include_lib("wx/include/wx.hrl").
-author("Shaked Basa").
-define(CELL_SIZE,(40)).
-define(LEAF_SIZE,(20)).
-define(REFRESH_TIME,(250)).




start() ->
	
	%graphic_node:start([BoardSize,TotalProcNum,ListOfNodeNames,Energy,Organic,EnvEnergy,EnvOrganic]), %ListOfNodeNames=[]
	% Start the wxWidgets application
	wx:new(),
	% Create the main frame
	Frame_1 = wxFrame:new(wx:null(), 1, "Life_and_Evolution_of_cells - Menu"),
	% Create a new frame (The stats window)
	Stats_frame = wxFrame:new(wx:null(), 1, "Statistics - Menu"),
	% Create static labels
	Label_1 = wxStaticText:new(Frame_1, ?wxID_ANY, "TotalProcNum"),
	Label_2 = wxStaticText:new(Frame_1, ?wxID_ANY, "BoardSize"),
	Label_3 = wxStaticText:new(Frame_1, ?wxID_ANY, "Host name 1:"),   		%temp
	Label_4 = wxStaticText:new(Frame_1, ?wxID_ANY, "Energy"),
	Label_5 = wxStaticText:new(Frame_1, ?wxID_ANY, "Organic"),
	Label_6 = wxStaticText:new(Frame_1, ?wxID_ANY, "Environment Energy"),
	Label_7 = wxStaticText:new(Frame_1, ?wxID_ANY, "Environment Organic"),

	% Create input text fields with initial values and sizes
	Input_1 = wxTextCtrl:new(Frame_1, ?wxID_ANY,[{value, "10"}, {size, {300,50}}]),
	Input_2 = wxTextCtrl:new(Frame_1, ?wxID_ANY,[{value, "10"}, {size, {300,50}}]),
	Input_3 = wxTextCtrl:new(Frame_1, ?wxID_ANY,[{value, "node1@127.0.0.1"}, {size, {300,50}}]),
	Input_4 = wxTextCtrl:new(Frame_1, ?wxID_ANY,[{value, "9"}, {size, {300,50}}]),
	Input_5 = wxTextCtrl:new(Frame_1, ?wxID_ANY,[{value, "9"}, {size, {300,50}}]),
	Input_6 = wxTextCtrl:new(Frame_1, ?wxID_ANY,[{value, "2"}, {size, {300,50}}]),
	Input_7 = wxTextCtrl:new(Frame_1, ?wxID_ANY,[{value, "2"}, {size, {300,50}}]),

	% Create a font for the text fields
	Font = wxFont:new(38,?wxFONTFAMILY_DEFAULT, ?wxFONTSTYLE_NORMAL, ?wxFONTWEIGHT_BOLD),
	wxTextCtrl:setFont(Input_1, Font),
	wxTextCtrl:setFont(Input_2, Font),
	wxTextCtrl:setFont(Input_3, Font),
	wxTextCtrl:setFont(Input_4, Font),
	wxTextCtrl:setFont(Input_5, Font),
	wxTextCtrl:setFont(Input_6, Font),
	wxTextCtrl:setFont(Input_7, Font),
	
	% Create a button labeled "Start"
	Init_Button = wxButton:new(Frame_1, ?wxID_ANY, [{label, "Init"}, {pos,{0, 64}}, {size, {150, 50}}]),
	
	Start_Button = wxButton:new(Stats_frame, ?wxID_ANY, [{label, "Start"}, {pos,{0, 64}}, {size, {150, 50}}]),

	% Create a button labeled "Start"
	%Button = wxButton:new(Frame_1, ?wxID_ANY, [{label, "Start"}, {pos,{0, 64}}, {size, {150, 50}}]),
	% Create a sizer to arrange the elements vertically
	MainSizer = wxBoxSizer:new(?wxVERTICAL),
	wxSizer:add(MainSizer, Label_1, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, Input_1, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, Label_2, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, Input_2, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, Label_3, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, Input_3, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, Label_4, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, Input_4, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, Label_5, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, Input_5, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, Label_6, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, Input_6, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, Label_7, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, Input_7, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, Init_Button, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxWindow:setSizer(Frame_1, MainSizer),
	wxSizer:setSizeHints(MainSizer, Frame_1),
	


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
	S_Font = wxFont:new(38,?wxFONTFAMILY_DEFAULT, ?wxFONTSTYLE_NORMAL, ?wxFONTWEIGHT_BOLD),
	wxTextCtrl:setFont(S_Stat_1, S_Font),
	wxTextCtrl:setFont(S_Stat_2, S_Font),
	wxTextCtrl:setFont(S_Stat_3, S_Font),
	wxTextCtrl:setFont(S_Stat_4, S_Font),
	wxTextCtrl:setFont(S_Stat_5, S_Font),
	wxTextCtrl:setFont(S_Stat_6, S_Font),

	% Create a sizer to arrange the elements vertically
	S_Sizer = wxBoxSizer:new(?wxHORIZONTAL),
	wxSizer:add(S_Sizer, S_Label_1, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(S_Sizer, S_Stat_1, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(S_Sizer, S_Label_2, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(S_Sizer, S_Stat_2, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(S_Sizer, S_Label_3, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(S_Sizer, S_Stat_3, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(S_Sizer, S_Label_4, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(S_Sizer, S_Stat_4, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(S_Sizer, S_Label_5, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(S_Sizer, S_Stat_5, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(S_Sizer, S_Label_6, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(S_Sizer, S_Stat_6, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(S_Sizer, Start_Button, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),	
	wxWindow:setSizer(Stats_frame, S_Sizer),
	wxSizer:setSizeHints(S_Sizer, Stats_frame),


	% Connect the button click event to the handle_click function
	wxButton:connect(Init_Button, command_button_clicked, [{callback, fun init_handle_click/2}, {userData, #{input_1 => Input_1,input_2 => Input_2,input_3 => Input_3,input_4 => Input_4,input_5 => Input_5,input_6 => Input_6,input_7 => Input_7, env => wx:get_env(), frame_1 => Frame_1, stats_frame => Stats_frame}}]),
	% Show the main frame
	wxFrame:show(Frame_1),

	% Connect the button click event to the handle_click function
	wxButton:connect(Start_Button, command_button_clicked, [{callback, fun start_handle_click/2}, {userData, #{input_2 => Input_2, env => wx:get_env(), stats_frame => Stats_frame, s_stat_1 =>S_Stat_1 }}]).

%% Function to handle button click events
init_handle_click(#wx{obj = _Init_Button, userData = #{input_1 := Input_1,input_2 := Input_2,input_3 := Input_3,input_4 := Input_4,input_5 := Input_5,input_6 := Input_6,input_7 := Input_7, env := Env, frame_1 := Frame_1, stats_frame := Stats_frame}},  _Event) ->
	% Set the environment
	wx:set_env(Env),
	% Get the label of the clicked Init_Button
	%Label = wxButton:getLabel(Init_Button),
	% Handle Init_Button label
	
	BoardSize = list_to_integer(wxTextCtrl:getValue(Input_2)),
	TotalProcNum = list_to_integer(wxTextCtrl:getValue(Input_1)),
	ListOfNodeNames = [list_to_atom(wxTextCtrl:getValue(Input_3))],
	Energy = list_to_integer(wxTextCtrl:getValue(Input_4)),
	Organic = list_to_integer(wxTextCtrl:getValue(Input_5)),
	EnvEnergy = list_to_integer(wxTextCtrl:getValue(Input_6)),
	EnvOrganic = list_to_integer(wxTextCtrl:getValue(Input_7)),
	graphic_node:start([BoardSize,TotalProcNum,ListOfNodeNames,Energy,Organic,EnvEnergy,EnvOrganic]), %ListOfNodeNames=[]
	wxFrame:destroy(Frame_1),
	wxFrame:show(Stats_frame).


start_handle_click(#wx{obj = Start_Button,userData = #{ input_2 := Input_2, env := Env, stats_frame := Stats_frame, s_stat_1 := S_Stat_1 }}, _Event) ->
	wx:set_env(Env),
	Label = wxButton:getLabel(Start_Button),
	case Label of

		"Start" ->	
			(global:whereis_name(main_node)) ! {start},
			wxButton:setLabel(Start_Button, "Stop"),
			Val = list_to_integer(wxTextCtrl:getValue(Input_2)),
			if
				Val > 108 ->
					Cell_size = 10,
					wxTextCtrl:setValue(Input_2, integer_to_list(108)),
					UD_Input_2 = 108,
					spawn(?MODULE, start_sim, [Cell_size , UD_Input_2, Start_Button, Env,Stats_frame,S_Stat_1]);
				Val > 54 ->
					% Spawn a new process to start the simulation	
					Cell_size = 10,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button, Env,Stats_frame,S_Stat_1]);	
				Val > 27 ->
					% Spawn a new process to start the simulation	
					Cell_size = 20,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button, Env,Stats_frame,S_Stat_1]);

				true ->
					Cell_size = ?CELL_SIZE,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button, Env,Stats_frame,S_Stat_1])		
			end;
		"Stop" ->
			wxFrame:destroy(Stats_frame),			

			% Enable input fields and change Start_Button label to "Start"
			sim_gui ! {kill},
			spawn(?MODULE, start, []),
			exit(self())		
	end.



start_sim(Cell_size,Input_2, Button, Env,Stats_frame,S_Stat_1) ->
	
	register(sim_gui, self()),
	% Set the environment
	wx:set_env(Env),

	% get user input 
	Frame_size = Input_2,	

	% Create a new frame (The world window)
	Frame = wxFrame:new(wx:null(), 1, "Life_and_Evolution_of_cells",[{size,{Cell_size*Frame_size,Cell_size*Frame_size}}]),	

	% Load and scale the cells images from file
	General = wxImage:new("general.png"),
	Generalc = wxImage:scale(General,Cell_size,Cell_size),
    	BmpGeneral = wxBitmap:new(Generalc),
  	wxImage:destroy(General),
  	wxImage:destroy(Generalc),

	Seed = wxImage:new("seed.png"),
	Seedc = wxImage:scale(Seed,Cell_size,Cell_size),
    	BmpSeed = wxBitmap:new(Seedc),
  	wxImage:destroy(Seed),
  	wxImage:destroy(Seedc),

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
	
	% Show the frame to display the canvas
	canvas_loop(Frame_size, Cell_size, Button, Frame, Stats_frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf, BmpAntena, BmpRoot,0).

	
%% Function to continuously update and display the canvas

canvas_loop(Frame_size,Cell_size, Button,Frame, Stats_frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, 0) ->
	wxFrame:show(Frame),
	canvas_loop(Frame_size,Cell_size, Button, Frame, Stats_frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf, BmpAntena, BmpRoot, 1);
	
canvas_loop(Frame_size, Cell_size, Button, Frame, Stats_frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf, BmpAntena, BmpRoot, 1) ->
			
			% Clear the canvas by destroying all children of the frame
			wxWindow:destroyChildren(Frame),
			% Print the updated cells on the canvas
			print_cells(Frame, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot), %add arg - list of elements
			% Refresh the canvas to display the changes
			%wxTextCtrl:setValue(S_Stat_1, integer_to_list(Num_of_cells)),
			wxWindow:refresh(Frame),
			wxWindow:refresh(Stats_frame),
			% Introduce a delay for animation effect
			%timer:sleep(?REFRESH_TIME),
			 % Recursive call to continue the loop
			canvas_loop(Frame_size,Cell_size, Button, Frame, Stats_frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf, BmpAntena, BmpRoot, 1).
			


% Function to print cells on the canvas based on the data in 'main_ets' table
% Input: Key (the current key in the 'main_ets' table)
%        Frame (the frame where the cells are displayed)
%        Bmp_x_ (the _x_ bitmap)
%        _x_ = {General, Seed, Leaf, Antena, Root}
print_cells(Frame, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot) ->
	receive
		{kill} -> 
			wxFrame:destroy(Frame),
			exit(self());
		
		%%ETS line [{{X_coordinate,Y_coordinate},{{EnvOrganic,EnvEnergy},{cell_type,energy,organic,TTL,cells_created,wooded}}},{...},{...}] no cell = none
		List -> 
			Counter = insert_cells(List, Frame, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, 0),
			Counter	
			
	end.
	
insert_cells([], _Frame, _BmpGeneral, _BmpSeed, _BmpLeaf , _BmpAntena , _BmpRoot, Counter) ->
	Counter;

insert_cells([{{X_axis,Y_axis},{{_EnvOrganic,_EnvEnergy},{Cell_type,_Energy,_Organic,_TTL,_Cells_created,_Wooded}}}|T], Frame, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter) ->

	case Cell_type of
		none ->	
			insert_cells(T, Frame, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter);
		general ->
			wxStaticBitmap:new(Frame,?wxID_ANY , BmpGeneral, [{pos,{X_axis,Y_axis}}]),
			insert_cells(T, Frame, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		seed_cell ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpSeed, [{pos,{X_axis,Y_axis}}]),
			insert_cells(T, Frame, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		leaf_cell ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpLeaf, [{pos,{X_axis,Y_axis}}]),
			insert_cells(T, Frame, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		antena_cell ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpAntena, [{pos,{X_axis,Y_axis}}]),
			insert_cells(T, Frame, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		root_cell ->
			wxStaticBitmap:new(Frame, ?wxID_ANY, BmpRoot, [{pos,{X_axis,Y_axis}}]),
			insert_cells(T, Frame, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1)
	end.







