%%Yevgeniy Gluhoy: 336423629
-module(cell_manager).
-behaviour(gen_server).
%%------------------------------------------------------------------------------------------------------------------------------------
-export([start/0,init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).
-export([cell_monitor/2]).
%%------------------------------------------------------------------------------------------------------------------------------------
-define(MAX_ENERGY,15).
-define(MAX_ORGANIC,15).
-define(MAX_CHILDREN,3).
-define(EVENT_TIME,1000).
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////gen server init/////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
start() -> gen_server:start({local, cell_manager},?MODULE,[],[]). 
%%------------------------------------------------------------------------------------------------------------------------------------
init(_) -> 	%receive %arguments - ({NumberOfCells2Create,RangeOfCoordinates})
			%	{init,Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name,Node_name} -> %General node must send parameters
			%			Cell_monitor=spawn(cell_manager,cell_monitor,[[],Node_name]),%Need to create cells_monitor and register it locally
			%			register(cell_monitor,Cell_monitor),
			%			create_cells_func(Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name), %creating cells
			%			Node_name!{ready,cell_manager}, %all cells created
			%			{ok,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}}
			%after 10000 -> exit(self()) %something wrong, exit
			%end.
			{ok,{}}.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Not in use but must be exported/////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
code_change(_,_,_) -> {ok,normal}.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Handlers of type call///////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%Coordinates is out of range of current node
handle_call({move,X_axis,Y_axis,FromX,FromY},{From,_Tag},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) when ((Y_axis>Ymax) or (Y_axis<Ymin)) -> %1.Move
		loggerp!{cellInfo,"Cell Manager Handle call: Move out of node"},
		if ((X_axis>Xmax) or (X_axis<Xmin)) -> 
					NewPos_x=x_axisRepair(Xmin,Xmax,X_axis);
		true -> NewPos_x=X_axis
		end,
		%%ETS line [{{X_coordinate,Y_coordinate},{{EnvOrganic,EnvEnergy},{cell_type,energy,organic,TTL,cells_created,wooded}}}]
		[{_,{_,H}}]=ets:lookup(ETS_name,{FromX,FromY}),%check place in ETS %H={Cell_type,Energy,Organic,TTL,Cells_created,Wooded}
		(global:whereis_name(Node_name))!{moveout,From,NewPos_x,Y_axis,FromX,FromY,H}, %send message to general node
		%receive
		%	{ok,New_X_axis,New_Y_axis} -> {reply,{New_X_axis,New_Y_axis},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}};%process will migrate to new position
		%	{reject,_New_X_axis,_New_Y_axis} -> {reply,{FromX,FromY},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}}%rejected
		%after 5000 -> {reply,{FromX,FromY},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}} %no response
		%end;
		{reply,{FromX,FromY},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}};
%%------------------------------------------------------------------------------------------------------------------------------------
%%Coordinates is out of board range
handle_call({move,X_axis,Y_axis,FromX,FromY},_From,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) when ((X_axis>Xmax) or (X_axis<Xmin)) -> %1.Move
		loggerp!{cellInfo,"Cell Manager Handle call: Move out of range"},
		NewPos=x_axisRepair(Xmin,Xmax,X_axis),
		case ets:lookup(ETS_name,{NewPos,Y_axis}) of %check if move can be done
			[{{NewPos,Y_axis},{{EnvOrganic,EnvEnergy},{none,_,_,_,_,_}}}] -> %yes place is empty					
				[{_,{{EnvOrganicOld,EnvEnergyOld},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}]=ets:lookup(ETS_name,{FromX,FromY}),
				ets:delete(ETS_name,{FromX,FromY}), % change ets line
				ets:insert(ETS_name,{{FromX,FromY},{{EnvOrganicOld,EnvEnergyOld},{none,0,0,0,0,0}}}),
				ets:delete(ETS_name,{Xmin,Y_axis}),
				ets:insert(ETS_name,{{Xmin,Y_axis},{{EnvOrganic,EnvEnergy},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}),
				{reply,{NewPos,Y_axis},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}};
		_ ->	{reply,{FromX,FromY},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}} %reject
		end;
%%------------------------------------------------------------------------------------------------------------------------------------
handle_call({move,X_axis,Y_axis,FromX,FromY},_From,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) -> %1.Move
		loggerp!{cellInfo,"Cell Manager Handle call: Move"},
		case ets:lookup(ETS_name,{X_axis,Y_axis}) of %check if move can be done
			[{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{none,_,_,_,_,_}}}] -> %yes place is empty					
				[{_,{{EnvOrganicOld,EnvEnergyOld},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}]=ets:lookup(ETS_name,{FromX,FromY}),
					ets:delete(ETS_name,{FromX,FromY}), % change ets line
					ets:insert(ETS_name,{{FromX,FromY},{{EnvOrganicOld,EnvEnergyOld},{none,0,0,0,0,0}}}),
					ets:delete(ETS_name,{X_axis,Y_axis}),
					ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}),
					{reply,{X_axis,Y_axis},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}}; %ok
			_ ->	{reply,{FromX,FromY},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}} %reject
		end;
%%------------------------------------------------------------------------------------------------------------------------------------
%1.Movein from outside
handle_call({movein,X_axis,Y_axis,Prev_x,Prev_y,{Cell_type,Energy,Organic,TTL,Cells_created,Wooded}},_From,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) -> 
			loggerp!"Cell Manager Handle call: Move in",
			case ets:lookup(ETS_name,{X_axis,Y_axis}) of %check if move can be done
			[{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{none,_,_,_,_,_}}}] -> %yes place is empty
					ets:delete(ETS_name,{X_axis,Y_axis}),
					ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{Cell_type,Energy,Organic,TTL,Cells_created,Wooded}}}),
					%spawn process
					CellID=spawn(general_cell_funcs,Cell_type,[Energy,Organic,Cells_created,Wooded,{X_axis,Y_axis},ETS_name,TTL]),
					cell_monitor!{add,CellID},%Send ID to cells_monitor
					{reply,{answer,ok,X_axis,Y_axis,Prev_x,Prev_y},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}}; %ok
			_ ->	{reply,{answer,reject,X_axis,Y_axis,Prev_x,Prev_y},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}} %reject
			end;
%%------------------------------------------------------------------------------------------------------------------------------------
%%------------------------------------------------------------------------------------------------------------------------------------
%%In this version cell cannot eat cell in another node
handle_call({eat,_X_axis,Y_axis,FromX,FromY},_From,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) when ((Y_axis>Ymax) or (Y_axis<Ymax)) -> %2.Eat
		loggerp!{cellInfo,"Cell Manager Handle call: Eat out of node"},
		{reply,{FromX,FromY,0},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}};
%%------------------------------------------------------------------------------------------------------------------------------------
handle_call({eat,X_axis,Y_axis,FromX,FromY},_From,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) when ((X_axis>Xmax) or (X_axis<Xmax)) -> %2.Eat
		loggerp!{cellInfo,"Cell Manager Handle call: Eat out of range"},
		NewPos=x_axisRepair(Xmin,Xmax,X_axis),
		case ets:lookup(ETS_name,{NewPos,Y_axis}) of %check if there somebody in given coordinates
			%[{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{none,_,_,_,_,_}}}] -> 
			[{{NewPos,Y_axis},{{_,_},{none,_,_,_,_,_}}}] ->						
					{reply,{FromX,FromY,0},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}}; %ok
			_ ->	%in this version there is no ability to eat another cell
					%[{_,{{EnvOrganicOld,EnvEnergyOld},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}]=ets:lookup(ETS_name,{FromX,FromY}),
					%ets:delete(ETS_name,{FromX,FromY}),
					%ets:insert(ETS_name,{{FromX,FromY},{{EnvOrganicOld,EnvEnergyOld},{none,0,0,0,0,0}}}),
					%ets:delete(ETS_name,{X_axis,Y_axis}),
					%ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}),
					%{reply,{X_axis,Y_axis},ok} %reject
					{reply,{FromX,FromY,0},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}}
		end;
%%------------------------------------------------------------------------------------------------------------------------------------
handle_call({eat,X_axis,Y_axis,FromX,FromY},_From,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) -> %2.Eat {New_X_coordinate,New_Y_coordinate,Add_energy}
		loggerp!{cellInfo,"Cell Manager Handle call: Eat out of range"},
		%%add case when X>Xmax or Y>Ymax
		case ets:lookup(ETS_name,{X_axis,Y_axis}) of %check if there somebody in given coordinates
			%[{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{none,_,_,_,_,_}}}] -> 
			[{{X_axis,Y_axis},{{_,_},{none,_,_,_,_,_}}}] ->						
					{reply,{FromX,FromY,0},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}}; %ok
			_ ->	%in this version there is no ability to eat another cell
					%[{_,{{EnvOrganicOld,EnvEnergyOld},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}]=ets:lookup(ETS_name,{FromX,FromY}),
					%ets:delete(ETS_name,{FromX,FromY}),
					%ets:insert(ETS_name,{{FromX,FromY},{{EnvOrganicOld,EnvEnergyOld},{none,0,0,0,0,0}}}),
					%ets:delete(ETS_name,{X_axis,Y_axis}),
					%ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}),
					%{reply,{X_axis,Y_axis},ok} %reject
					{reply,{FromX,FromY,0},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}}
		end;
%%------------------------------------------------------------------------------------------------------------------------------------
%%------------------------------------------------------------------------------------------------------------------------------------
handle_call({create,X_coordinate,Y_coordinate,Type},_From,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) -> %create new cell by request from general cell
			loggerp!{cellInfo,"Cell Manager Handle call: Create"},
			{X_axis,Y_axis}=check_place(X_coordinate,Y_coordinate,ETS_name,{Xmin,Ymin,Xmax,Ymax}),
			if X_axis == -1 ->
				{reply,{reject,0},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}};
			true -> 
				Ttl=rand:uniform(15)+5,
				if Type == general_cell -> Wooded=0,
							Module_type=general_cell_funcs;
				true -> Wooded=1,
						Module_type=cell_funcs
				end,
				[{_,{{EnvOrganic,EnvEnergy},_}}]=ets:lookup(ETS_name,{X_axis,Y_axis}),
				ets:delete(ETS_name,{X_axis,Y_axis}),
				ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{Type,5,5,Ttl,0,Wooded}}}),
				CellID=spawn(Module_type,Type,[5,5,0,Wooded,{X_axis,Y_axis},ETS_name,Ttl]),				
				ID=whereis(cell_monitor),				
				if ID==undefined -> 
					{reply,{reject,0},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}};
				true -> ID!{add,CellID},
					{reply,{ok,-1},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}}
				end
			end;
%%------------------------------------------------------------------------------------------------------------------------------------
%%------------------------------------------------------------------------------------------------------------------------------------
handle_call({restart,NewYmin,NewYmax,New_ETS_name},_From,{Xmin,_Ymin,Xmax,_Ymax,ETS_name,Node_name}) ->
			loggerp!"Cell Manager Handle call: Restart",
			%io:format("~nRestarting mailbox2~n",[]),
			%restart_mailbox2(),%clean mailbox
			%cell_monitor!{restart},
			%io:format("~nRestarting mailbox~n",[]),
			%restart_mailbox(),
			%io:format("~nTry to spawn new cell monitor~n",[]),
			Cell_monitor=spawn(cell_manager,cell_monitor,[[],Node_name]),%Need to create cells_monitor and register it locally
			%io:format("~nTry to register new cell monitor~n",[]),
			register(cell_monitor,Cell_monitor),
			%io:format("~nTry to create cells~n",[]),
			create_cells_func_restart(ets:tab2list(New_ETS_name),ETS_name),%create cells using New ETS
			%io:format("~nAll done~n",[]),
			{reply,{done},{Xmin,NewYmin,Xmax,NewYmax,New_ETS_name,Node_name}};
%%------------------------------------------------------------------------------------------------------------------------------------
handle_call(_Any,_From,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) ->
			loggerp!{cellInfo,"Unknown Handle call in cell manager"},
			{reply,{done},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}}.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Handlers of type cast///////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
handle_cast(stop,{Xmin,_Ymin,Xmax,_Ymax,ETS_name,Node_name}) -> 
			%exit(self(),ok),
			%gen_server:terminate(cell_manager,ok),
			{stop,normal,{Xmin,_Ymin,Xmax,_Ymax,ETS_name,Node_name}}.%termination
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Handlers of type info///////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
handle_info({die,X_axis,Y_axis,Organic,Energy},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) -> %1.cell dies
			loggerp!{cellInfo,"Cell Manager Handle info: Die"},
			[{_,{{EnvOrganicOld,EnvEnergyOld},_}}]=ets:lookup(ETS_name,{X_axis,Y_axis}),
			ets:delete(ETS_name,{X_axis,Y_axis}),%delete ets line
			ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganicOld+Organic,EnvEnergyOld+Energy},{none,0,0,0,0,0}}}),
			{noreply,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}};
%%------------------------------------------------------------------------------------------------------------------------------------
handle_info({new_type,X_axis,Y_axis,Type,Ttl},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) -> %2.new_type of cell in {X,Y}
			loggerp!{cellInfo,"Cell Manager Handle info: New type"},
			[{_,{{EnvOrganicOld,EnvEnergyOld},{_,Energy,Organic,_,_,Wooded}}}]=ets:lookup(ETS_name,{X_axis,Y_axis}),
			ets:delete(ETS_name,{X_axis,Y_axis}),
			ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganicOld,EnvEnergyOld},{Type,Energy,Organic,Ttl,0,Wooded}}}),
			{noreply,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}};
%%------------------------------------------------------------------------------------------------------------------------------------
handle_info({init,Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name,Node_name},_) -> %initialization	%General node must send parameters
			loggerp!"Cell Manager Handle info: Init",
			Cell_monitor=spawn(cell_manager,cell_monitor,[[],Node_name]),%Need to create cells_monitor and register it locally
			register(cell_monitor,Cell_monitor),
			%register(cell_manager,self()),
			loggerp!"Cell Monitor Active",
			create_cells_func(Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name), %creating cells
			%Node_name!{ready,cell_manager}, %all cells created
			loggerp!{cell_manager,ok},
			{noreply,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}};
%%------------------------------------------------------------------------------------------------------------------------------------
handle_info({Answer,_X_axis,_Y_axis,ID,Prev_x,Prev_y},{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}) -> %transport process answer
			loggerp!"Cell Manager Handle info: Answer",
			if  Answer==reject -> ok;%rejected
				Answer==ok -> %process will migrate to new position
					cell_monitor!{delete,ID},%delete process
					%clean ets:line
					[{_,{{EnvOrganicOld,EnvEnergyOld},_}}]=ets:lookup(ETS_name,{Prev_x,Prev_y}),
					ets:delete(ETS_name,{Prev_x,Prev_y}),
					ets:insert(ETS_name,{{Prev_x,Prev_y},{{EnvOrganicOld,EnvEnergyOld},{none,0,0,0,0,0}}})
			end,
			{noreply,{Xmin,Ymin,Xmax,Ymax,ETS_name,Node_name}}.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////termination/////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terminate(_Reason, _State) -> 	loggerp!"Cell manager terminated",
								%loggerp!Reason,
								ok.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%//////////////////////////////////////////////////////////internal funcs/////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
create_cells_func_restart([],_ETS_name) -> ok;
create_cells_func_restart([{{X_axis,Y_axis},{{_EnvOrganic,_EnvEnergy},{Cell_type,Energy,Organic,TTL,Cells_created,Wooded}}}|T],ETS_name) -> 
				if Cell_type == none ->
					create_cells_func_restart(T,ETS_name);
				true ->
					if Cell_type == general_cell -> 
						CellID=spawn(general_cell_funcs,Cell_type,[Energy,Organic,Cells_created,Wooded,{X_axis,Y_axis},ETS_name,0]);
					true -> 
						CellID=spawn(cell_funcs,Cell_type,[Energy,Organic,0,1,{X_axis,Y_axis},ETS_name,TTL])
					end,
					cell_monitor!{add,CellID},%Send ID to cells_monitor
					create_cells_func_restart(T,ETS_name)
				end.
%%------------------------------------------------------------------------------------------------------------------------------------
create_cells_func(0,_,_,_,_) -> ok; %all needed cells created
create_cells_func(Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name) -> %creating new general cell
				X_axis=rand:uniform(Xmax-Xmin)+Xmin, %choose random position
				Y_axis=rand:uniform(Ymax-Ymin)+Ymin,
				case ets:lookup(ETS_name,{X_axis,Y_axis}) of %check if there already exist cell
						[{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{none,_,_,_,_,_}}}] -> %create cell
							%%ETS line [{{X_coordinate,Y_coordinate},{{EnvOrganic,EnvEnergy},{cell_type,energy,organic,TTL,cells_created,wooded}}}]
							ets:delete(ETS_name,{X_axis,Y_axis}),
							ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{general_cell,Energy,Organic,-1,0,0}}}), %update ETS
							CellID=spawn(general_cell_funcs,general_cell,[Energy,Organic,0,0,{X_axis,Y_axis},ETS_name,0]),
							cell_monitor!{add,CellID},%Send ID to cells_monitor
							create_cells_func(Cells_Amount-1,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name); 
						_ -> create_cells_func(Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name) 
				end.
%%------------------------------------------------------------------------------------------------------------------------------------
check_place(X_axis,Y_axis,ETS_name,{Xmin,Ymin,Xmax,Ymax}) -> 
			{New_X_axis,New_Y_axis}=check_place2(X_axis,Y_axis,ETS_name,[[1,1],[1,-1],[-1,1],[-1,-1]],{Xmin,Ymin,Xmax,Ymax}), %ets:lookup(ETS_name,{X_axis,Y_axis})
			{New_X_axis,New_Y_axis}.
check_place2(_X_axis,_Y_axis,_,[],_) -> {-1,-1};
check_place2(X_axis,Y_axis,ETS_name,[[Val1,Val2]|T],{Xmin,Ymin,Xmax,Ymax}) ->
			if ((((X_axis+Val1)>Xmax) or ((X_axis+Val1)<Xmin)) or (((Y_axis+Val2)>Ymax) or ((Y_axis+Val2)<Ymin))) ->%%case when X>Xmax or Y>Ymax
				check_place2(X_axis,Y_axis,ETS_name,T,{Xmin,Ymin,Xmax,Ymax});
			true -> 
				[{_,{_,{Type,_,_,_,_,_}}}]=ets:lookup(ETS_name,{X_axis+Val1,Y_axis+Val2}),
				if Type == none ->
					%check_place2(X_axis+Val1,Y_axis+Val2,ETS_name,[]);
					{X_axis+Val1,Y_axis+Val2};
				true -> check_place2(X_axis,Y_axis,ETS_name,T,{Xmin,Ymin,Xmax,Ymax})
				end
			end.
			%loggerp!{prin,X_axis+Val1},
			%loggerp!{prin,Y_axis+Val2},
			
%%------------------------------------------------------------------------------------------------------------------------------------
x_axisRepair(Xmin,Xmax,X_axis) -> 
	if X_axis>Xmax -> Xmin; %right border
	true -> Xmax %left border
	end.
%%------------------------------------------------------------------------------------------------------------------------------------
cell_monitor(List,Node_name) -> %monitors cell processes
		receive
			{add,ID} -> erlang:monitor(process,ID),%new process created
						cell_monitor([ID]++List,Node_name);%add to total list
			{delete,ID} ->  ID!{restart},
							NewList=lists:delete(ID,List),
							cell_monitor(NewList,Node_name);
			{restart} -> delete_all_cells(List),%delete all cells, restarting node
						loggerp!"Node was restarted, new ETS received",
						global:whereis_name(Node_name)!{restart,done},
						ok;
			{termination} -> delete_all_cells(List),%delete all cells, restarting node
							loggerp!"All cells deleted";
			{'DOWN',_Monitor,process,Proc,_Info} -> %cell down, delete from list
						NewList=lists:delete(Proc,List),
						cell_monitor(NewList,Node_name);
			_ -> cell_monitor(List,Node_name) %clean mailbox
		after 1000 -> loggerp!{prin,length(List)},
						cell_monitor(List,Node_name)
		end.
delete_all_cells([]) -> ok;
delete_all_cells([H|T]) ->  H!{restart},
							delete_all_cells(T).
%%------------------------------------------------------------------------------------------------------------------------------------
%restart_mailbox() -> 
%		receive
%			{restart,done} -> ok;
%			_ -> restart_mailbox()
%		end.
%restart_mailbox2() -> 
%		receive
%			_ -> restart_mailbox2()
%		after 0 -> ok
%		end.
%%------------------------------------------------------------------------------------------------------------------------------------
