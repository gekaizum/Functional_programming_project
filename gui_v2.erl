-module(gui_v2).
-export([start/0]).
-export([init_handle_click/2,start_handle_click/2,organic_handle_click/2, energy_handle_click/2, start_sim/10, insert_cells/8, insert_organic/11, insert_energy/11, cells_malibox/2]).
-include_lib("wx/include/wx.hrl").
-author("Shaked Basa").
-define(CELL_SIZE,(40)).
-define(LEAF_SIZE,(20)).
-define(REFRESH_TIME,(1000)).


%%*********************************************************************************************************************%%
%% gui version 2 - Includes all the functions of the first version + heat maps of the organics and energy in the field %%
%% Heavier code than the first version is less suitable for thousands of processes				       %%
%%*********************************************************************************************************************%%

%------------------------------------------------------ start -> the gui and open the init screen of the simulation --------------------------------------------------------------------------

start() ->

	% Start the wxWidgets application
	wx:new(),
	% Create the Init_Frame
	Init_Frame = wxFrame:new(wx:null(), 1, "Life_and_Evolution_of_cells - Menu"),
	% Create a new frame (The stats window)
	Stats_Frame = wxFrame:new(wx:null(), 1, "Statistics - Menu"),
	% Create static labels
	Label_1 = wxStaticText:new(Init_Frame, ?wxID_ANY, "TotalProcNum"),
	Label_2 = wxStaticText:new(Init_Frame, ?wxID_ANY, "BoardSize"),
	Label_4 = wxStaticText:new(Init_Frame, ?wxID_ANY, "Energy"),
	Label_5 = wxStaticText:new(Init_Frame, ?wxID_ANY, "Organic"),
	Label_6 = wxStaticText:new(Init_Frame, ?wxID_ANY, "Environment Energy"),
	Label_7 = wxStaticText:new(Init_Frame, ?wxID_ANY, "Environment Organic"),

	% Create input text fields with initial values and sizes
	Input_1 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "10"}, {size, {300,50}}]),
	Input_2 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "10"}, {size, {300,50}}]),
	Input_4 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "9"}, {size, {300,50}}]),
	Input_5 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "9"}, {size, {300,50}}]),
	Input_6 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "2"}, {size, {300,50}}]),
	Input_7 = wxTextCtrl:new(Init_Frame, ?wxID_ANY,[{value, "2"}, {size, {300,50}}]),

	% Create a font for the text fields
	Font = wxFont:new(38,?wxFONTFAMILY_DEFAULT, ?wxFONTSTYLE_NORMAL, ?wxFONTWEIGHT_BOLD),
	wxTextCtrl:setFont(Input_1, Font),
	wxTextCtrl:setFont(Input_2, Font),
	wxTextCtrl:setFont(Input_4, Font),
	wxTextCtrl:setFont(Input_5, Font),
	wxTextCtrl:setFont(Input_6, Font),
	wxTextCtrl:setFont(Input_7, Font),
	
	% Create a button labeled "Init" on the Init_Frame
	Init_Button = wxButton:new(Init_Frame, ?wxID_ANY, [{label, "Init"}, {pos,{0, 64}}, {size, {150, 50}}]),
	% Create a button labeled "start" on the Stats_Frame	
	Start_Button = wxButton:new(Stats_Frame, ?wxID_ANY, [{label, "Start"}, {pos,{0, 64}}, {size, {150, 50}}]),
	% Create a buttons to show/hide the heatmaps of organic and energy 
	Organic_Button = wxButton:new(Stats_Frame, ?wxID_ANY, [{label, "Show organic"}, {pos,{0, 64}}, {size, {150, 50}}]),	
	Energy_Button = wxButton:new(Stats_Frame, ?wxID_ANY, [{label, "Show energy"}, {pos,{0, 64}}, {size, {150, 50}}]),

	% Create a sizer to arrange the elements vertically
	MainSizer = wxBoxSizer:new(?wxVERTICAL),
	wxSizer:add(MainSizer, Label_1, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, Input_1, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(MainSizer, Label_2, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(MainSizer, Input_2, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
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
	S_Label_7 = wxStaticText:new(Stats_Frame, ?wxID_ANY, "Sun"),

	% Create Stat text fields with initial values and sizes
	S_Stat_1 = wxTextCtrl:new(Stats_Frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_2 = wxTextCtrl:new(Stats_Frame, ?wxID_ANY,[{value, "0"}, {size, {150,50}}]),
	S_Stat_7 = wxTextCtrl:new(Stats_Frame, ?wxID_ANY,[{value, "UP"}, {size, {150,50}}]),
	
	% Disable stats fields to edit
	wxTextCtrl:setEditable(S_Stat_1, false),
	wxTextCtrl:setEditable(S_Stat_2, false),
	wxTextCtrl:setEditable(S_Stat_7, false),
	
	% Create a font for the stats text fields
	S_Font = wxFont:new(38,?wxFONTFAMILY_DEFAULT, ?wxFONTSTYLE_NORMAL, ?wxFONTWEIGHT_BOLD),
	wxTextCtrl:setFont(S_Stat_1, S_Font),
	wxTextCtrl:setFont(S_Stat_2, S_Font),
	wxTextCtrl:setFont(S_Stat_7, S_Font),

	% Create a sizer to arrange the elements vertically
	S_Sizer = wxBoxSizer:new(?wxVERTICAL),
	wxSizer:add(S_Sizer, S_Label_1, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(S_Sizer, S_Stat_1, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(S_Sizer, S_Label_2, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(S_Sizer, S_Stat_2, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(S_Sizer, S_Label_7, [{flag, ?wxALIGN_CENTRE bor ?wxALL}, {border, 5}]),
	wxSizer:add(S_Sizer, S_Stat_7, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),
	wxSizer:add(S_Sizer, Start_Button, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),	
	wxSizer:add(S_Sizer, Organic_Button, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),	
	wxSizer:add(S_Sizer, Energy_Button, [{flag, ?wxEXPAND bor ?wxALL}, {border,5}]),	
	wxWindow:setSizer(Stats_Frame, S_Sizer),
	wxSizer:setSizeHints(S_Sizer, Stats_Frame),

	% Connect the button click event to the handle_click function
	wxButton:connect(Init_Button, command_button_clicked, [{callback, fun init_handle_click/2}, {userData, #{input_1 => Input_1,input_2 => Input_2,input_4 => Input_4,input_5 => Input_5,input_6 => Input_6,input_7 => Input_7, env => wx:get_env(), init_frame => Init_Frame, stats_frame => Stats_Frame}}]),
	% Show the main frame
	wxWindow:show(Init_Frame, [{show, true}]),

	% Connect the button click event to the handle_click function
	wxButton:connect(Start_Button, command_button_clicked, [{callback, fun start_handle_click/2}, {userData, #{input_2 => Input_2, env => wx:get_env(), stats_frame => Stats_Frame, s_stat_1 =>S_Stat_1 ,s_stat_2 =>S_Stat_2 ,organic_button => Organic_Button,energy_button => Energy_Button, init_frame => Init_Frame}}]).
	
%------------------------------------------------------------------- start_sim-------------------------------------------------------------------------------	


%% after click on start button - this func builds the world and start the simulation 
start_sim(Cell_size,Input_2, Start_Button,Organic_Button,Energy_Button, Env, Stats_Frame, Init_Frame, S_Stat_1, S_Stat_2) ->

	register(sim_gui, self()),
	(global:whereis_name(main_node)) ! {start},
	
	% Set the environment
	wx:set_env(Env),

	% get user input for the world size
	Frame_size = Input_2,	

	% Create a new World_Frame
	World_Frame = wxFrame:new(wx:null(), 1, "World Frame",[{size,{Cell_size*Frame_size,Cell_size*Frame_size}}]),
	% Create a new Organic_Frame
	Organic_Frame = wxFrame:new(wx:null(), 2, "Organic Frame",[{size,{Cell_size*Frame_size + Cell_size*Frame_size div 3,Cell_size*Frame_size}}]),
	% Create a new Energy_Frame
	Energy_Frame = wxFrame:new(wx:null(), 3, "Energy Frame",[{size,{Cell_size*Frame_size + Cell_size*Frame_size div 3,Cell_size*Frame_size}}]),
			
	% Load and scale the cells and heatmap images from files
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
  	
  	H1 = wxImage:new("1.png"),
	H1c = wxImage:scale(H1,Cell_size,Cell_size),
    	BmpH1 = wxBitmap:new(H1c),
  	wxImage:destroy(H1),
  	wxImage:destroy(H1c),	
  	
  	H2 = wxImage:new("2.png"),
	H2c = wxImage:scale(H2,Cell_size,Cell_size),
    	BmpH2 = wxBitmap:new(H2c),
  	wxImage:destroy(H2),
  	wxImage:destroy(H2c),	
	
	H3 = wxImage:new("3.png"),
	H3c = wxImage:scale(H3,Cell_size,Cell_size),
    	BmpH3 = wxBitmap:new(H3c),
  	wxImage:destroy(H3),
  	wxImage:destroy(H3c),	
  	
  	H4 = wxImage:new("4.png"),
	H4c = wxImage:scale(H4,Cell_size,Cell_size),
    	BmpH4 = wxBitmap:new(H4c),
  	wxImage:destroy(H4),
  	wxImage:destroy(H4c),	
  	
  	H5 = wxImage:new("5.png"),
	H5c = wxImage:scale(H5,Cell_size,Cell_size),
    	BmpH5 = wxBitmap:new(H5c),
  	wxImage:destroy(H5),
  	wxImage:destroy(H5c),	
  	
  	H6 = wxImage:new("6.png"),
	H6c = wxImage:scale(H6,Cell_size,Cell_size),
    	BmpH6 = wxBitmap:new(H6c),
  	wxImage:destroy(H6),
  	wxImage:destroy(H6c),	
  	
  	Scale = wxImage:new("scale.png"),
	Scalec = wxImage:scale(Scale, Cell_size*Frame_size div 3, Cell_size*Frame_size),
    	BmpScale = wxBitmap:new(Scalec),
  	wxImage:destroy(Scale),
  	wxImage:destroy(Scalec),
  	
  	wxStaticBitmap:new(Organic_Frame,?wxID_ANY , BmpScale, [{pos,{Cell_size*Frame_size + (Cell_size*Frame_size div 3) div 2, 5}}]),
  	wxStaticBitmap:new(Energy_Frame,?wxID_ANY , BmpScale, [{pos,{Cell_size*Frame_size + (Cell_size*Frame_size div 3) div 2, 5}}]),
    	
	% Show the World_Frame to display the canvas
	display_loop(S_Stat_2, Frame_size,Cell_size, Start_Button,Organic_Button,Energy_Button,World_Frame, Organic_Frame, Energy_Frame, Stats_Frame, Init_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, BmpH1, BmpH2, BmpH3, BmpH4, BmpH5, BmpH6,Env, 0).

%--------------------------------------------------------------------display_loop-------------------------------------------------------------------------------	
%% Function to continuously update and display the Sim World
%%starts a chain of events of updating the screen, the function displays the world frame to the screen, 
%%calls the main_mail_box functionand then refreshes the frame

display_loop(S_Stat_2, Frame_size,Cell_size, Start_Button,Organic_Button,Energy_Button,World_Frame, Organic_Frame, Energy_Frame, Stats_Frame, Init_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, BmpH1, BmpH2, BmpH3, BmpH4, BmpH5, BmpH6,Env, 0) ->
	wxFrame:show(World_Frame),
	
	wxButton:connect(Organic_Button, command_button_clicked, [{callback, fun organic_handle_click/2}, {userData, #{env => wx:get_env(), organic_frame => Organic_Frame}}]),
	wxButton:connect(Energy_Button, command_button_clicked, [{callback, fun energy_handle_click/2}, {userData, #{env => wx:get_env(), energy_frame => Energy_Frame}}]),
		
	display_loop(S_Stat_2, Frame_size,Cell_size, Start_Button,Organic_Button,Energy_Button,World_Frame, Organic_Frame, Energy_Frame, Stats_Frame, Init_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, BmpH1, BmpH2, BmpH3, BmpH4, BmpH5, BmpH6,Env, 1);
	
display_loop(S_Stat_2, Frame_size,Cell_size, Start_Button,Organic_Button,Energy_Button,World_Frame, Organic_Frame, Energy_Frame, Stats_Frame, Init_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, BmpH1, BmpH2, BmpH3, BmpH4, BmpH5, BmpH6,Env, 1) ->
			
			% Print the updated windows
			Num_of_cells = main_mail_box(Stats_Frame, Init_Frame, S_Stat_1, S_Stat_2, Start_Button, Env, World_Frame, Organic_Frame, Energy_Frame,Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, BmpH1, BmpH2, BmpH3, BmpH4, BmpH5, BmpH6),
			if Num_of_cells == -1 ->
				wxFrame:destroy(World_Frame),
				ok;
			true ->
				% Refresh the canvas to display the changes
				wxTextCtrl:setValue(S_Stat_1, integer_to_list(Num_of_cells)),
				wxWindow:refresh(World_Frame),
				wxWindow:refresh(Stats_Frame),
				wxWindow:refresh(Energy_Frame),
				wxWindow:refresh(Organic_Frame),
				
				% Recursive call to continue the loop
				display_loop(S_Stat_2, Frame_size,Cell_size, Start_Button,Organic_Button,Energy_Button,World_Frame, Organic_Frame, Energy_Frame, Stats_Frame, Init_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, BmpH1, BmpH2, BmpH3, BmpH4, BmpH5, BmpH6,Env, 1)
			end.
			
%-------------------------------------------------------------------------------main_mail_box ------------------------------------------------------------------------------------


%% function that functions as a receive block and activates methods according to the received messages
%% {kill} - Message received at the end of the simulation or by pressing the stop button in certain cases this message is received by the graphic node
%% {List, Nodes} - message that is received frequently, this message contains a list of "objects" in the simulation world, according to which the graphics are updated
main_mail_box(Stats_Frame, Init_Frame,S_Stat_1, S_Stat_2, Start_Button, Env, World_Frame, Organic_Frame, Energy_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, BmpH1, BmpH2, BmpH3, BmpH4, BmpH5, BmpH6) ->
	receive
		{kill} -> 
			
			wxFrame:destroy(World_Frame),
			wxFrame:destroy(Organic_Frame),
			wxFrame:destroy(Energy_Frame),
			wxTextCtrl:setValue(S_Stat_1,"0"),
			wxTextCtrl:setValue(S_Stat_2,"0"),
			wxFrame:hide(Stats_Frame),
			wxButton:setLabel(Start_Button, "Start"),
			timer:sleep(1000),
			wxFrame:show(Init_Frame),
			exit(self());

		{List, Nodes} -> 
			
			wxTextCtrl:setValue(S_Stat_2, integer_to_list(Nodes)),
			wxWindow:destroyChildren(World_Frame),
			Num_of_cells = frames_update(List, Env, World_Frame, Organic_Frame, Energy_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, BmpH1, BmpH2, BmpH3, BmpH4, BmpH5, BmpH6),		
			Num_of_cells	
		after 900 -> 	
			ID=global:whereis_name(main_node),
			if ID==undefined -> ok;
			true -> ID!{send_me}
			end,
			main_mail_box(Stats_Frame, Init_Frame, S_Stat_1, S_Stat_2, Start_Button, Env, World_Frame, Organic_Frame, Energy_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, BmpH1, BmpH2, BmpH3, BmpH4, BmpH5, BmpH6)	
	end.
	
%-------------------------------------------------------------------------------frame_update ------------------------------------------------------------------------------------

	
%% function that spawn processes into the insert_cells, insert_organic and insert_energy functions (as the number of cell types + 2)
frames_update(List,Env, World_Frame, Organic_Frame, Energy_Frame, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot, BmpH1, BmpH2, BmpH3, BmpH4, BmpH5, BmpH6) ->	

	spawn_monitor(?MODULE, insert_cells, [Env,general_cell,BmpGeneral,World_Frame,Cell_size,List,0,1]),
	spawn_monitor(?MODULE, insert_cells, [Env,seed_cell,BmpSeed,World_Frame,Cell_size,List,0,1]),
	spawn_monitor(?MODULE, insert_cells, [Env,leaf_cell,BmpLeaf,World_Frame,Cell_size,List,0,1]),
	spawn_monitor(?MODULE, insert_cells, [Env,antena_cell,BmpAntena,World_Frame,Cell_size,List,0,1]),
	spawn_monitor(?MODULE, insert_cells, [Env,root_cell,BmpRoot,World_Frame,Cell_size,List,0,1]),
	spawn_monitor(?MODULE, insert_organic, [Env, Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Organic_Frame, List,1]),
	spawn_monitor(?MODULE, insert_energy, [Env, Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Energy_Frame, List,1]),
	cells_malibox(7,0).	

%-------------------------------------------------------------------------------insert_cells ------------------------------------------------------------------------------------

%% function that goes through a list and prints an object to the frame
%%(only the type of cell that the process is responsible for)
insert_cells(Env,Type,ImageType,World_Frame,Cell_size,T, Counter,1) ->
	wx:set_env(Env),
	insert_cells(Env,Type,ImageType,World_Frame,Cell_size,T, Counter,0);

insert_cells(_,_,_,_,_,[], Counter,0) ->
	exit(Counter);
insert_cells(Env,Type,ImageType,World_Frame,Cell_size,[{{X_axis,Y_axis},{{_EnvOrganic,_EnvEnergy},{Cell_type,_Energy,_Organic,_TTL,_Cells_created,_Wooded}}}|T], Counter, 0) ->
	if 
	Type == Cell_type ->
		wxStaticBitmap:new(World_Frame,?wxID_ANY , ImageType, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
		insert_cells(Env,Type,ImageType,World_Frame,Cell_size,T, Counter + 1,0);
	true -> 
		insert_cells(Env,Type,ImageType,World_Frame,Cell_size,T, Counter,0)
	end.

%-------------------------------------------------------------------------------insert_organic ------------------------------------------------------------------------------------
%%Updates the heat map of the organics in the field
insert_organic(Env, Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Organic_Frame, List,1) ->
	wx:set_env(Env),
	insert_organic(Env, Cell_size,BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Organic_Frame,List,0);

insert_organic(_,_,_,_,_,_,_,_,_,[],0) ->
	exit(0);
insert_organic(Env,Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Organic_Frame,[{{X_axis,Y_axis},{{EnvOrganic,_EnvEnergy},{_Cell_type,_Energy,_Organic,_TTL,_Cells_created,_Wooded}}}|T], 0) ->

	if
	EnvOrganic > 25 ->
		wxStaticBitmap:new(Organic_Frame,?wxID_ANY , BmpH1, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),	
		insert_organic(Env, Cell_size,BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Organic_Frame,T,0);		
	EnvOrganic > 20 ->
		wxStaticBitmap:new(Organic_Frame,?wxID_ANY , BmpH2, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
		insert_organic(Env, Cell_size,BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Organic_Frame,T,0);
					
	EnvOrganic > 15 ->
		wxStaticBitmap:new(Organic_Frame,?wxID_ANY , BmpH3, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
		insert_organic(Env, Cell_size,BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Organic_Frame,T,0);
						
	EnvOrganic > 10 ->
		wxStaticBitmap:new(Organic_Frame,?wxID_ANY , BmpH4, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
		insert_organic(Env, Cell_size,BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Organic_Frame,T,0);
					
	EnvOrganic > 5 ->
		wxStaticBitmap:new(Organic_Frame,?wxID_ANY , BmpH5, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
		insert_organic(Env, Cell_size,BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Organic_Frame,T,0);
					
	EnvOrganic > 0 ->
		wxStaticBitmap:new(Organic_Frame,?wxID_ANY , BmpH6, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
		insert_organic(Env, Cell_size,BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Organic_Frame,T,0);
	true ->
		insert_organic(Env, Cell_size,BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Organic_Frame,T,0)
	end.


%-------------------------------------------------------------------------------insert_energy ------------------------------------------------------------------------------------
%%Updates the heat map of the energy in the field
insert_energy(Env, Cell_size,BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Energy_Frame, List,1) ->
	wx:set_env(Env),
	insert_energy(Env, Cell_size,BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Energy_Frame,List,0);

insert_energy(_,_,_,_,_,_,_,_,_,[],0) ->
	exit(0);
insert_energy(Env, Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Energy_Frame,[{{X_axis,Y_axis},{{_EnvOrganic,EnvEnergy},{_Cell_type,_Energy,_Organic,_TTL,_Cells_created,_Wooded}}}|T], 0) ->

	if
	EnvEnergy > 25 ->
		wxStaticBitmap:new(Energy_Frame,?wxID_ANY , BmpH1, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),	
		insert_energy(Env, Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Energy_Frame,T,0);		
	EnvEnergy > 20 ->
		wxStaticBitmap:new(Energy_Frame,?wxID_ANY , BmpH2, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
		insert_energy(Env, Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Energy_Frame,T,0);
						
	EnvEnergy > 15 ->
		wxStaticBitmap:new(Energy_Frame,?wxID_ANY , BmpH3, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
		insert_energy(Env, Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Energy_Frame,T,0);
						
	EnvEnergy > 10 ->
		wxStaticBitmap:new(Energy_Frame,?wxID_ANY , BmpH4, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
		insert_energy(Env, Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Energy_Frame,T,0);
					
	EnvEnergy > 5 ->
		wxStaticBitmap:new(Energy_Frame,?wxID_ANY , BmpH5, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
		insert_energy(Env, Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Energy_Frame,T,0);
					
	EnvEnergy > 0 ->
		wxStaticBitmap:new(Energy_Frame,?wxID_ANY , BmpH6, [{pos,{(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}}]),
		insert_energy(Env, Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Energy_Frame,T,0);
					
	true ->
		insert_energy(Env, Cell_size, BmpH1,BmpH2,BmpH3,BmpH4, BmpH5, BmpH6,Energy_Frame,T,0)
	end.
%-------------------------------------------------------------------------------cells_malibox ------------------------------------------------------------------------------------		
		
		
%%function that receives from each process at the end of its run the number of cells
%%and adds them to the total cells
cells_malibox(Counter,Cells) ->
	receive
		{'DOWN',_,process,_,Num_of_cells} ->
			if 
			Counter == 1 ->
				Cells + Num_of_cells;
			true ->
				cells_malibox(Counter - 1,Cells + Num_of_cells)
			end
	end.

%--------------------------------------------------------------------------------click handlers-------------------------------------------------------------------------------------


%% Function to handle init_button click events
init_handle_click(#wx{obj = _Init_Button, userData = #{input_1 := Input_1,input_2 := Input_2,input_4 := Input_4,input_5 := Input_5,input_6 := Input_6,input_7 := Input_7, env := Env, init_frame := Init_Frame, stats_frame := Stats_Frame}},  _Event) ->
	% Set the environment
	wx:set_env(Env),
	% Get the label of the clicked Init_Button
	% Handle Init_Button label
	BoardSize = list_to_integer(wxTextCtrl:getValue(Input_2)),
	TotalProcNum = list_to_integer(wxTextCtrl:getValue(Input_1)),
	Energy = list_to_integer(wxTextCtrl:getValue(Input_4)),
	Organic = list_to_integer(wxTextCtrl:getValue(Input_5)),
	EnvEnergy = list_to_integer(wxTextCtrl:getValue(Input_6)),
	EnvOrganic = list_to_integer(wxTextCtrl:getValue(Input_7)),
	wxFrame:hide(Init_Frame),
	timer:sleep(1000),
	wxFrame:show(Stats_Frame),
	%graphic_node:start([BoardSize,TotalProcNum,['node1@132.72.80.185','node2@132.72.81.224','node3@132.72.81.167'],[node1,node2,node3],Energy,Organic,EnvEnergy,EnvOrganic]). %ListOfNodeNames=[]
	graphic_node:start([BoardSize,TotalProcNum,['node1@127.0.0.1'],[node1],Energy,Organic,EnvEnergy,EnvOrganic]). %ListOfNodeNames=[]
%% Function to handle start_button click events



start_handle_click(#wx{obj = Start_Button,userData = #{ input_2 := Input_2, env := Env, stats_frame := Stats_Frame, s_stat_1 := S_Stat_1, s_stat_2 := S_Stat_2, organic_button := Organic_Button,energy_button := Energy_Button, init_frame := Init_Frame}}, _Event) ->
	wx:set_env(Env),
	Label = wxButton:getLabel(Start_Button),
	case Label of

		"Start" ->	
			wxButton:setLabel(Start_Button, "Stop"),
			Val = list_to_integer(wxTextCtrl:getValue(Input_2)),
			if
				Val > 108 ->
					Cell_size = 10,
					wxTextCtrl:setValue(Input_2, integer_to_list(108)),
					UD_Input_2 = 108,
					spawn(?MODULE, start_sim, [Cell_size , UD_Input_2, Start_Button,Organic_Button,Energy_Button, Env,Stats_Frame, Init_Frame,S_Stat_1,S_Stat_2]);
				Val > 54 ->
					% Spawn a new process to start the simulation	
					Cell_size = 10,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button,Organic_Button,Energy_Button, Env,Stats_Frame, Init_Frame,S_Stat_1,S_Stat_2]);	
				Val > 27 ->
					% Spawn a new process to start the simulation	
					Cell_size = 20,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button,Organic_Button,Energy_Button, Env,Stats_Frame, Init_Frame,S_Stat_1,S_Stat_2]);

				true ->
					Cell_size = ?CELL_SIZE,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button,Organic_Button,Energy_Button, Env,Stats_Frame, Init_Frame,S_Stat_1,S_Stat_2])		
			end;
		"Stop" ->
			(global:whereis_name(main_node))!{stop},
			timer:sleep(200),		
			whereis(sim_gui) ! {kill}
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










