-module(n_gui).
-export([start/0]).
-export([init_handle_click/2,start_handle_click/2,organic_handle_click/2, energy_handle_click/2, start_sim/8]).
-include_lib("wx/include/wx.hrl").
-author("Shaked Basa").
-define(CELL_SIZE,(40)).
-define(LEAF_SIZE,(20)).
-define(REFRESH_TIME,(1000)).


%-----------------------------------------------------------start the gui and init screen of the simulation------------------------------------------------------------------------------------	


start() ->
	
	%graphic_node:start([BoardSize,TotalProcNum,ListOfNodeNames,Energy,Organic,EnvEnergy,EnvOrganic]), %ListOfNodeNames=[]
	% Start the wxWidgets application
	wx:new(),
	% Create the Init_Frame
	Init_Frame = wxFrame:new(wx:null(), 1, "Life_and_Evolution_of_cells - Menu"),
	% Create a new frame (The stats window)
	Stats_Frame = wxFrame:new(wx:null(), 1, "Statistics - Menu"),
	% Create static labels
	Label_1 = wxStaticText:new(Init_Frame, ?wxID_ANY, "TotalProcNum"),
	Label_2 = wxStaticText:new(Init_Frame, ?wxID_ANY, "BoardSize"),
	Label_3 = wxStaticText:new(Init_Frame, ?wxID_ANY, "Host name 1:"),   		%temp
	Label_4 = wxStaticText:new(Init_Frame, ?wxID_ANY, "Energy"),
	Label_5 = wxStaticText:new(Init_Frame, ?wxID_ANY, "Organic"),
	Label_6 = wxStaticText:new(Init_Frame, ?wxID_ANY, "Environment Energy"),
	Label_7 = wxStaticText:new(Init_Frame, ?wxID_ANY, "Environment Organic"),

	% Create input text fields with initial values and sizes
	Input_1 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "10"}, {size, {300,50}}]),
	Input_2 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "10"}, {size, {300,50}}]),
	Input_3 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "node1@127.0.0.1"}, {size, {300,50}}]),
	Input_4 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "9"}, {size, {300,50}}]),
	Input_5 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "9"}, {size, {300,50}}]),
	Input_6 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "2"}, {size, {300,50}}]),
	Input_7 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "2"}, {size, {300,50}}]),

	% Create a font for the text fields
	Font = wxFont:new(38,?wxFONTFAMILY_DEFAULT, ?wxFONTSTYLE_NORMAL, ?wxFONTWEIGHT_BOLD),
	wxTextCtrl:setFont(Input_1, Font),
	wxTextCtrl:setFont(Input_2, Font),
	wxTextCtrl:setFont(Input_3, Font),
	wxTextCtrl:setFont(Input_4, Font),
	wxTextCtrl:setFont(Input_5, Font),
	wxTextCtrl:setFont(Input_6, Font),
	wxTextCtrl:setFont(Input_7, Font),
	
	% Create a button labeled "Init" on the Init_Frame
	Init_Button = wxButton:new(Init_Frame, ?wxID_ANY, [{label, "Init"}, {pos,{0, 64}}, {size, {150, 50}}]),
	% Create a button labeled "start" on the Stats_far,e	
	Start_Button = wxButton:new(Stats_Frame, ?wxID_ANY, [{label, "Start"}, {pos,{0, 64}}, {size, {150, 50}}]),
	
	Organic_Button = wxButton:new(Stats_Frame, ?wxID_ANY, [{label, "Show organic"}, {pos,{0, 64}}, {size, {150, 50}}]),	
	Energy_Button = wxButton:new(Stats_Frame, ?wxID_ANY, [{label, "Show energy"}, {pos,{0, 64}}, {size, {150, 50}}]),

	% Create a button labeled "Start"
	%Button = wxButton:new(Init_Frame, ?wxID_ANY, [{label, "Start"}, {pos,{0, 64}}, {size, {150, 50}}]),
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
	wxWindow:setSizer(Init_Frame, MainSizer),
	wxSizer:setSizeHints(MainSizer, Init_Frame),
	
	% Create static labels
	S_Label_1 = wxStaticText:new(Stats_Frame, ?wxID_ANY, "Number of Cells"),
	S_Label_2 = wxStaticText:new(Stats_Frame, ?wxID_ANY, "Number of Nodes"),
	S_Label_3 = wxStaticText:new(Stats_Frame, ?wxID_ANY, "Stat_3"),
	S_Label_4 = wxStaticText:new(Stats_Frame, ?wxID_ANY, "Stat_4"),
	S_Label_5 = wxStaticText:new(Stats_Frame, ?wxID_ANY, "Stat_5"),
	S_Label_6 = wxStaticText:new(Stats_Frame, ?wxID_ANY, "Stat_6"),

	% Create Stat text fields with initial values and sizes
	S_Stat_1 = wxTextCtrl:new(Stats_Frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_2 = wxTextCtrl:new(Stats_Frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_3 = wxTextCtrl:new(Stats_Frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_4 = wxTextCtrl:new(Stats_Frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_5 = wxTextCtrl:new(Stats_Frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_6 = wxTextCtrl:new(Stats_Frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	
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
	S_Sizer = wxBoxSizer:new(?wxVERTICAL),
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
	wxSizer:add(S_Sizer, Organic_Button, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),	
	wxSizer:add(S_Sizer, Energy_Button, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),	
	wxWindow:setSizer(Stats_Frame, S_Sizer),
	wxSizer:setSizeHints(S_Sizer, Stats_Frame),

	% Connect the button click event to the handle_click function
	wxButton:connect(Init_Button, command_button_clicked, [{callback, fun init_handle_click/2}, {userData, #{input_1 => Input_1,input_2 => Input_2,input_3 => Input_3,input_4 => Input_4,input_5 => Input_5,input_6 => Input_6,input_7 => Input_7, env => wx:get_env(), init_frame => Init_Frame, stats_frame => Stats_Frame}}]),
	% Show the main frame
	wxFrame:show(Init_Frame),

	% Connect the button click event to the handle_click function
	wxButton:connect(Start_Button, command_button_clicked, [{callback, fun start_handle_click/2}, {userData, #{input_2 => Input_2, env => wx:get_env(), stats_frame => Stats_Frame, s_stat_1 =>S_Stat_1 ,organic_button => Organic_Button,energy_button => Energy_Button}}]).
	
%-----------------------------------------------------------builds the world and start the simulation------------------------------------------------------------------------------------	


%% after click on start button - this func builds the world and start the simulation 
start_sim(Cell_size,Input_2, Start_Button,Organic_Button,Energy_Button, Env, Stats_Frame, S_Stat_1) ->
	io:format("~nSimulation started~n",[]),
	register(sim_gui, self()),
	(global:whereis_name(main_node)) ! {start},
	% Set the environment
	wx:set_env(Env),

	% get user input 
	Frame_size = Input_2,	

	% Create a new World_Frame
	World_Frame = wxFrame:new(wx:null(), 1, "World_Frame",[{size,{Cell_size*Frame_size,Cell_size*Frame_size}}]),
	% Create a new Organic_Frame
	Organic_Frame = wxFrame:new(wx:null(), 2, "Organic_Frame",[{size,{Cell_size*Frame_size,Cell_size*Frame_size}}]),
	% Create a new Organic_Frame
	Energy_Frame = wxFrame:new(wx:null(), 3, "Energy_Frame",[{size,{Cell_size*Frame_size,Cell_size*Frame_size}}]),	
	
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
	
	% Show the World_Frame to display the canvas
	display_loop(Frame_size, Cell_size, Start_Button,Organic_Button,Energy_Button, World_Frame, Organic_Frame, Energy_Frame, Stats_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf, BmpAntena, BmpRoot,0).

%------------------------------------------------------------------display_loop ------------------------------------------------------------------------------------	
		
		
%% Function to continuously update and display the Sim World

display_loop(Frame_size,Cell_size, Start_Button,Organic_Button,Energy_Button,World_Frame, Organic_Frame, Energy_Frame, Stats_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, 0) ->
	wxFrame:show(World_Frame),
	
	wxButton:connect(Organic_Button, command_button_clicked, [{callback, fun organic_handle_click/2}, {userData, #{env => wx:get_env(), organic_frame => Organic_Frame}}]),
	wxButton:connect(Energy_Button, command_button_clicked, [{callback, fun energy_handle_click/2}, {userData, #{env => wx:get_env(), energy_frame => Energy_Frame}}]),
	
	
	display_loop(Frame_size,Cell_size, Start_Button,Organic_Button,Energy_Button, World_Frame, Organic_Frame, Energy_Frame, Stats_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf, BmpAntena, BmpRoot, 1);
	
display_loop(Frame_size, Cell_size, Start_Button,Organic_Button,Energy_Button, World_Frame, Organic_Frame, Energy_Frame, Stats_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf, BmpAntena, BmpRoot, 1) ->
			
			% Clear the canvas by destroying all children of the World_Frame
			% Print the updated cells on the canvas
			Num_of_cells = print_cells(World_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot), %add arg - list of elements
			% Refresh the canvas to display the changes
			wxTextCtrl:setValue(S_Stat_1, integer_to_list(Num_of_cells)),
			wxWindow:refresh(World_Frame),
			wxWindow:refresh(Stats_Frame),
			% Introduce a delay for animation effect
			% Recursive call to continue the loop
			display_loop(Frame_size,Cell_size, Start_Button,Organic_Button,Energy_Button, World_Frame, Organic_Frame, Energy_Frame, Stats_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf, BmpAntena, BmpRoot, 1).
			
%-------------------------------------------------receive block and printing the cells on the frame ---------------------------------------------------------------------


%% Function to print cells on the canvas based on received from the graphic node
print_cells(World_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot) ->
	receive
		{kill} -> 
			wxFrame:destroy(World_Frame),
			exit(self());
		
		%%ETS line [{{X_coordinate,Y_coordinate},{{EnvOrganic,EnvEnergy},{cell_type,energy,organic,TTL,cells_created,wooded}}},{...},{...}] no cell = none
		List -> 
			wxWindow:destroyChildren(World_Frame),
			Counter = insert_cells(List, World_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, 0),
			Counter			
	end.
	

%%Function to create and print the cell objs on the world frame
insert_cells([], _World_Frame, _Cell_size, _BmpGeneral, _BmpSeed, _BmpLeaf , _BmpAntena , _BmpRoot, Counter) ->
	Counter;

insert_cells([{{X_axis,Y_axis},{{_EnvOrganic,_EnvEnergy},{Cell_type,_Energy,_Organic,_TTL,_Cells_created,_Wooded}}}|T], World_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter) ->

	case Cell_type of
		none ->	
			insert_cells(T, World_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter);
		general_cell ->
			wxStaticBitmap:new(World_Frame,?wxID_ANY , BmpGeneral, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
			insert_cells(T, World_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		seed_cell ->
			wxStaticBitmap:new(World_Frame, ?wxID_ANY, BmpSeed, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
			insert_cells(T, World_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		leaf_cell ->
			wxStaticBitmap:new(World_Frame, ?wxID_ANY, BmpLeaf, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
			insert_cells(T, World_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		antena_cell ->
			wxStaticBitmap:new(World_Frame, ?wxID_ANY, BmpAntena, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
			insert_cells(T, World_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1);
		root_cell ->
			wxStaticBitmap:new(World_Frame, ?wxID_ANY, BmpRoot, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
			insert_cells(T, World_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, Counter + 1)
	end.





%-----------------------------------------------------click handlers---------------------------------------------------------------------------------


%% Function to handle init_button click events
init_handle_click(#wx{obj = _Init_Button, userData = #{input_1 := Input_1,input_2 := Input_2,input_3 := Input_3,input_4 := Input_4,input_5 := Input_5,input_6 := Input_6,input_7 := Input_7, env := Env, init_frame := Init_Frame, stats_frame := Stats_Frame}},  _Event) ->
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
	graphic_node:start([BoardSize,TotalProcNum,ListOfNodeNames,[node1],Energy,Organic,EnvEnergy,EnvOrganic]), %ListOfNodeNames=[]
	wxFrame:hide(Init_Frame),
	wxFrame:show(Stats_Frame).

%% Function to handle start_button click events
start_handle_click(#wx{obj = Start_Button,userData = #{ input_2 := Input_2, env := Env, stats_frame := Stats_Frame, s_stat_1 := S_Stat_1, organic_button := Organic_Button,energy_button := Energy_Button }}, _Event) ->
	wx:set_env(Env),
	Label = wxButton:getLabel(Start_Button),
	io:format("~nButton handler, Input 2 = ~p~n",[Input_2]),
	case Label of

		"Start" ->	
			wxButton:setLabel(Start_Button, "Stop"),
			Val = list_to_integer(wxTextCtrl:getValue(Input_2)),
			io:format("~nBoardSize= ~w~n",[Val]),
			io:format("~nStart Pressed,Val=~n",[]),
			if
				Val > 108 ->
					io:format("~n108~n",[]),
					Cell_size = 10,
					wxTextCtrl:setValue(Input_2, integer_to_list(108)),
					UD_Input_2 = 108,
					io:format("~nSpawn start sim~n",[]),
					spawn(?MODULE, start_sim, [Cell_size , UD_Input_2, Start_Button,Organic_Button,Energy_Button, Env,Stats_Frame,S_Stat_1]);
				Val > 54 ->
					io:format("~n54~n",[]),
					% Spawn a new process to start the simulation	
					Cell_size = 10,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					io:format("~nSpawn start sim~n",[]),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button,Organic_Button,Energy_Button, Env,Stats_Frame,S_Stat_1]);	
				Val > 27 ->
					io:format("~n27~n",[]),
					% Spawn a new process to start the simulation	
					Cell_size = 20,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					io:format("~nSpawn start sim~n",[]),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button,Organic_Button,Energy_Button, Env,Stats_Frame,S_Stat_1]);

				true ->
					io:format("~n < 27~n",[]),
					Cell_size = ?CELL_SIZE,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					io:format("~nSpawn start sim~n",[]),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button,Organic_Button,Energy_Button, Env,Stats_Frame,S_Stat_1])		
			end;
		"Stop" ->
			wxFrame:destroy(Stats_Frame),			
			%io:format("~nStop sim~n",[]),
			% Enable input fields and change Start_Button label to "Start"
			whereis(sim_gui) ! {kill},
			io:format("~nMessage to stop frame sent~n",[]),
			(global:whereis_name(main_node))!{stop},
			io:format("~nMessage to stop main_node sent~n",[]),
			spawn(?MODULE, start, []),
			exit(self())		
	end.

%% Function to handle organic_button click events
organic_handle_click(#wx{obj = Organic_Button,userData = #{env := Env, organic_frame := Organic_Frame}}, _Event) ->
	wx:set_env(Env),
	Label = wxButton:getLabel(Organic_Button),
	case Label of

		"Show organic" ->	
			wxButton:setLabel(Organic_Button, "Hide organic"),
			wxFrame:show(Organic_Frame);
		"Hide organic" ->
			wxButton:setLabel(Organic_Button, "Show organic"),
			wxFrame:hide(Organic_Frame)
	end.

%% Function to handle energy_button click events
energy_handle_click(#wx{obj = Energy_Button,userData = #{env := Env, energy_frame := Energy_Frame}}, _Event) ->
	wx:set_env(Env),
	Label = wxButton:getLabel(Energy_Button),
	case Label of

		"Show energy" ->	
			wxButton:setLabel(Energy_Button, "Hide energy"),
			wxFrame:show(Energy_Frame);
		"Hide energy" ->
			wxButton:setLabel(Energy_Button, "Show energy"),
			wxFrame:hide(Energy_Frame)
	end.
