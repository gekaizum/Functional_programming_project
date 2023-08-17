-module(gui_v3).
-export([start/0]).
-export([init_handle_click/2, start_handle_click/2, start_sim/8, insert_cells/9, handle_refresh/2,handle_wxErase/2, cells_malibox/2]).
-include_lib("wx/include/wx.hrl").
-author("Shaked Basa").
-define(CELL_SIZE,(40)).
-define(LEAF_SIZE,(20)).
-define(REFRESH_TIME,(1000)).


%%************************************************************************************************%%
%% Experimental version of the gui - supports hundreds of thousands of processes 		  %%
%% a dirty code version, it works but with unused  lines from previous version of the application %%
%%************************************************************************************************%%

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
	wxWindow:setSizer(Stats_Frame, S_Sizer),
	wxSizer:setSizeHints(S_Sizer, Stats_Frame),

	% Connect the button click event to the handle_click function
	wxButton:connect(Init_Button, command_button_clicked, [{callback, fun init_handle_click/2}, {userData, #{input_1 => Input_1,input_2 => Input_2,input_4 => Input_4,input_5 => Input_5,input_6 => Input_6,input_7 => Input_7, env => wx:get_env(), init_frame => Init_Frame, stats_frame => Stats_Frame}}]),
	% Show the main frame
	wxWindow:show(Init_Frame, [{show, true}]),

	% Connect the button click event to the handle_click function
	wxButton:connect(Start_Button, command_button_clicked, [{callback, fun start_handle_click/2}, {userData, #{input_2 => Input_2, env => wx:get_env(), stats_frame => Stats_Frame, s_stat_1 =>S_Stat_1 ,s_stat_2 =>S_Stat_2 , init_frame => Init_Frame}}]).
	
%------------------------------------------------------------------- start_sim-------------------------------------------------------------------------------	


%% after click on start button - this func builds the world and start the simulation 
start_sim(Cell_size,Input_2, Start_Button, Env, Stats_Frame, Init_Frame, S_Stat_1, S_Stat_2) ->

	register(main_sim_gui, self()),
	(global:whereis_name(main_node)) ! {start},
	
	% Set the environment
	wx:set_env(Env),

	% get user input for the world size
	Frame_size = Input_2,	
	% Create a new World_Frame
	World_Frame = wxFrame:new(wx:null(), 1, "World Frame",[{size,{5,5}}]),
	wxWindow:setBackgroundStyle(World_Frame, ?wxBG_STYLE_PAINT),
	%wxWindow:setBackgroundColour(World_Frame,{0,0,0}),
	wxFrame:connect(World_Frame, erase_background, [{callback, fun handle_wxErase/2}]),
		
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
  	wxFrame:show(World_Frame),

  	Panel = wxPanel:new(World_Frame, [{size,{5,5}}]),
	%wxWindow:setBackgroundColour(Panel,{0,0,0}),
	wxWindow:setBackgroundStyle(Panel, ?wxBG_STYLE_PAINT),		
	wxPanel:connect(Panel, paint, [{callback, fun handle_refresh/2}, {userData, #{stats_Frame => Stats_Frame, init_Frame => Init_Frame, s_Stat_1 => S_Stat_1, s_Stat_2 => S_Stat_2, start_Button => Start_Button, env => Env, world_Frame => World_Frame, panel => Panel, cell_size => Cell_size, bmpGeneral => BmpGeneral, bmpSeed => BmpSeed, bmpLeaf => BmpLeaf, bmpAntena => BmpAntena, bmpRoot => BmpRoot}}]),
	wxPanel:connect(Panel, erase_background, [{callback, fun handle_wxErase/2}]),
	%wxWindow:destroyChildren(Panel),
  	
	% Show the World_Frame to display the canvas
	display_loop(S_Stat_2, Frame_size,Cell_size, Start_Button, World_Frame, Panel, Stats_Frame, Init_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot,Env, 0).

%--------------------------------------------------------------------display_loop-------------------------------------------------------------------------------	
		
		
%% Function to continuously update and display the Sim World
%%starts a chain of events of updating the screen, the function displays the world frame to the screen, 
%%calls the main_mail_box functionand then refreshes the frame

display_loop(S_Stat_2, Frame_size,Cell_size, Start_Button, World_Frame, Panel, Stats_Frame, Init_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot,Env, 0) ->	
	display_loop(S_Stat_2, Frame_size,Cell_size, Start_Button, World_Frame, Panel, Stats_Frame, Init_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot,Env, 1);
	
display_loop(S_Stat_2, Frame_size,Cell_size, Start_Button,World_Frame, Panel, Stats_Frame, Init_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot,Env, 1) ->
	
	receive
		{kill} -> 
					
			wxFrame:destroy(World_Frame),
			wxTextCtrl:setValue(S_Stat_1,"0"),
			wxTextCtrl:setValue(S_Stat_2,"0"),
			wxFrame:hide(Stats_Frame),
			wxButton:setLabel(Start_Button, "Start"),
			timer:sleep(1000),
			wxFrame:show(Init_Frame),
			exit(self())
		after 0 ->
			wxWindow:destroyChildren(Panel),
			wxWindow:refresh(World_Frame),
			wxWindow:refresh(Stats_Frame),
			% Recursive call to continue the loop
			display_loop(S_Stat_2, Frame_size,Cell_size, Start_Button,World_Frame, Panel, Stats_Frame, Init_Frame, S_Stat_1, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot,Env, 1)

	end.	

%-------------------------------------------------------------------------------main_mail_box ------------------------------------------------------------------------------------


%% function that functions as a receive block and activates methods according to the received messages
%% {kill} - Message received at the end of the simulation or by pressing the stop button in certain cases this message is received by the graphic node
%% {List, Nodes} - message that is received frequently, this message contains a list of "objects" in the simulation world, according to which the graphics are updated

main_mail_box(Stats_Frame, Init_Frame, S_Stat_1, S_Stat_2, Start_Button, Env, World_Frame, Panel, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot) ->
	receive
		%{kill} -> 
		%			
		%	wxFrame:destroy(World_Frame),
		%	wxTextCtrl:setValue(S_Stat_1,"0"),
		%	wxTextCtrl:setValue(S_Stat_2,"0"),
		%	wxFrame:hide(Stats_Frame),
		%	wxButton:setLabel(Start_Button, "Start"),
		%	timer:sleep(1000),
		%	wxFrame:show(Init_Frame),
		%	(whereis(main_sim_gui)) ! {kill};
		%	exit(self());

		{List, Nodes} -> 
			wxTextCtrl:setValue(S_Stat_2, integer_to_list(Nodes)),
			frame_update(List, Env, Panel, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot)		
		
		after 900 -> 	
			ID = global:whereis_name(main_node),
			if ID == undefined -> ok;
			true -> 
			ID!{send_me},
			main_mail_box(Stats_Frame, Init_Frame, S_Stat_1, S_Stat_2, Start_Button, Env, World_Frame, Panel, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot)	
			end

	end.

%-------------------------------------------------------------------------------frame_update ------------------------------------------------------------------------------------

	
%% function that spawn processes into the insert_cells function (as the number of cell types)
frame_update(List,Env, Panel, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot) ->	
	C_DC = wxClientDC:new(Panel),
	%DC = wxClientDC:new(Panel),
	%C_DC = wxBufferedDC:new(DC),
	spawn_monitor(?MODULE, insert_cells, [Env,general_cell,BmpGeneral,Panel,Cell_size,List,0,1,C_DC]),
	spawn_monitor(?MODULE, insert_cells, [Env,seed_cell,BmpSeed,Panel,Cell_size,List,0,1,C_DC]),
	spawn_monitor(?MODULE, insert_cells, [Env,leaf_cell,BmpLeaf,Panel,Cell_size,List,0,1,C_DC]),
	spawn_monitor(?MODULE, insert_cells, [Env,antena_cell,BmpAntena,Panel,Cell_size,List,0,1,C_DC]),
	spawn_monitor(?MODULE, insert_cells, [Env,root_cell,BmpRoot,Panel,Cell_size,List,0,1,C_DC]),
	cells_malibox(5,0).	


%-------------------------------------------------------------------------------insert_cells ------------------------------------------------------------------------------------

%% function that goes through a list and prints an object to the frame
%%(only the type of cell that the process is responsible for)
insert_cells(Env,Type,ImageType,Panel,Cell_size,T, Counter,1,C_DC) ->
	wx:set_env(Env),
	insert_cells(Env,Type,ImageType,Panel,Cell_size,T, Counter,0,C_DC);

insert_cells(_,_,_,_,_,[], Counter,0,_) ->
	exit(Counter);
	
insert_cells(Env,Type,ImageType,Panel,Cell_size,[{{_X_axis,_Y_axis},{{_EnvOrganic,_EnvEnergy},{Cell_type,_Energy,_Organic,_TTL,_Cells_created,_Wooded}}}|T], Counter, 0, C_DC) ->
	if 
	Type == Cell_type ->
		%wxDC:drawBitmap(C_DC, ImageType, {(X_axis*Cell_size - (Cell_size div 2)), (Y_axis*Cell_size-(Cell_size div 2))}),
		insert_cells(Env,Type,ImageType,Panel,Cell_size,T, Counter + 1, 0, C_DC);
	true -> 
		insert_cells(Env,Type,ImageType,Panel,Cell_size,T, Counter, 0, C_DC)
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

%-------------------------------------------------------------------------------click handlers---------------------------------------------------------------------------------


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
	graphic_node:start([BoardSize,TotalProcNum,['node1@132.72.80.185','node2@132.72.81.224','node3@132.72.81.167','node4@132.72.81.60','node5@132.72.81.139','node6@132.72.80.206'],[node1,node2,node3,node4,node5,node6],Energy,Organic,EnvEnergy,EnvOrganic]). %ListOfNodeNames=[]
	%graphic_node:start([BoardSize,TotalProcNum,['node1@127.0.0.1'],[node1],Energy,Organic,EnvEnergy,EnvOrganic]). %ListOfNodeNames=[]



%% Function to handle start_button click events
start_handle_click(#wx{obj = Start_Button,userData = #{ input_2 := Input_2, env := Env, stats_frame := Stats_Frame, s_stat_1 := S_Stat_1, s_stat_2 := S_Stat_2, init_frame := Init_Frame}}, _Event) ->
	wx:set_env(Env),
	Label = wxButton:getLabel(Start_Button),
	case Label of

		"Start" ->	
			wxButton:setLabel(Start_Button, "Stop"),
			Val = list_to_integer(wxTextCtrl:getValue(Input_2)),
			if
				Val > 108 ->
					Cell_size = 10,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size , UD_Input_2, Start_Button, Env,Stats_Frame, Init_Frame,S_Stat_1,S_Stat_2]);
				Val > 54 ->
					% Spawn a new process to start the simulation	
					Cell_size = 10,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button, Env,Stats_Frame, Init_Frame,S_Stat_1,S_Stat_2]);	
				Val > 27 ->
					% Spawn a new process to start the simulation	
					Cell_size = 20,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button, Env,Stats_Frame, Init_Frame,S_Stat_1,S_Stat_2]);

				true ->
					Cell_size = ?CELL_SIZE,
					UD_Input_2 = list_to_integer(wxTextCtrl:getValue(Input_2)),
					spawn(?MODULE, start_sim, [Cell_size ,UD_Input_2, Start_Button, Env,Stats_Frame, Init_Frame,S_Stat_1,S_Stat_2])		
			end;
		"Stop" ->
			(global:whereis_name(main_node))!{stop},
			timer:sleep(200),		
			whereis(main_sim_gui) ! {kill}
	end.


%% Function to handle wxPaint events (refresh) to reduce flickering 
handle_refresh(#wx{event=#wxPaint{}, userData = #{ stats_Frame := Stats_Frame, init_Frame := Init_Frame, s_Stat_1 := S_Stat_1, s_Stat_2 := S_Stat_2, start_Button := Start_Button, env := Env,world_Frame := World_Frame, panel := Panel, cell_size := Cell_size, bmpGeneral := BmpGeneral, bmpSeed := BmpSeed, bmpLeaf := BmpLeaf, bmpAntena := BmpAntena, bmpRoot := BmpRoot}}, _Event) ->
 	register(sim_gui, self()),	
	%io:format("~nRefresh handler~n",[]),
	%DC2 = wxPaintDC:new(Panel),
	DC2 = wxBufferedPaintDC:new(Panel),
	wxDC:clear(DC2),
	Num_of_cells = main_mail_box(Stats_Frame, Init_Frame,S_Stat_1, S_Stat_2, Start_Button, Env, World_Frame, Panel, Cell_size, BmpGeneral, BmpSeed, BmpLeaf , BmpAntena , BmpRoot),
	unregister(sim_gui),	
	wxTextCtrl:setValue(S_Stat_1, integer_to_list(Num_of_cells)).



handle_wxErase(#wx{event=#wxErase{}}, _Event) ->
	%io:format("in here~n"),
	ok.








