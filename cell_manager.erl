%%Yevgeniy Gluhoy: 336423629
-module(cell_manager).
-behaviour(gen_server).
%%------------------------------------------------------------------------------------------------------------------------------------
-export([start_link/0,init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).
%%------------------------------------------------------------------------------------------------------------------------------------
-define(MAX_ENERGY,15).
-define(MAX_ORGANIC,15).
-define(MAX_CHILDREN,3).
-define(EVENT_TIME,200).
%%------------------------------------------------------------------------------------------------------------------------------------
start_link() -> gen_server:start_link({local, cell_manager},?MODULE,[],[]). 
%%------------------------------------------------------------------------------------------------------------------------------------
init(_) -> 	receive %arguments - ({NumberOfCells2Create,RangeOfCoordinates})
				{init,Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name,Node_name} -> %General node must send parameters
												create_cells_func(Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name),
												Node_name!{ready,cell_manager}, %all cells created
												{ok,ETS_name}
			after 10000 -> exit(self()) %something wrong, exit
			end.
%%------------------------------------------------------------------------------------------------------------------------------------
code_change(_,_,_) -> {ok,normal}.
%%------------------------------------------------------------------------------------------------------------------------------------
handle_call({move,X_axis,Y_axis,FromX,FromY},_From,ETS_name) -> %1.Move
		case ets:lookup(ETS_name,{X_axis,Y_axis}) of %check if move can be done
			[{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{none,_,_,_,_,_}}}] -> %yes place is empty					
				[{_,{{EnvOrganicOld,EnvEnergyOld},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}]=ets:lookup(ETS_name,{FromX,FromY}),
					ets:delete(ETS_name,{FromX,FromY}), % change ets line
					ets:insert(ETS_name,{{FromX,FromY},{{EnvOrganicOld,EnvEnergyOld},{none,0,0,0,0,0}}}),
					ets:delete(ETS_name,{X_axis,Y_axis}),
					ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}),
					{reply,{X_axis,Y_axis},ETS_name}; %ok
			_ ->	{reply,{FromX,FromY},ETS_name} %reject
		end;
handle_call({eat,X_axis,Y_axis,FromX,FromY},_From,ETS_name) -> %2.Eat {New_X_coordinate,New_Y_coordinate,Add_energy}
		case ets:lookup(ETS_name,{X_axis,Y_axis}) of %check if there somebody in given coordinates
			%[{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{none,_,_,_,_,_}}}] -> 
			[{{X_axis,Y_axis},{{_,_},{none,_,_,_,_,_}}}] ->						
					{reply,{FromX,FromY,0},ETS_name}; %ok
			_ ->	%in this version there is no ability to eat another cell
					%[{_,{{EnvOrganicOld,EnvEnergyOld},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}]=ets:lookup(ETS_name,{FromX,FromY}),
					%ets:delete(ETS_name,{FromX,FromY}),
					%ets:insert(ETS_name,{{FromX,FromY},{{EnvOrganicOld,EnvEnergyOld},{none,0,0,0,0,0}}}),
					%ets:delete(ETS_name,{X_axis,Y_axis}),
					%ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{Type,EnergyOld,OrganicOld,TTLOld,Cells_createdOld,WoodedOld}}}),
					%{reply,{X_axis,Y_axis},ok} %reject
					{reply,{FromX,FromY,0},ETS_name}
		end;
handle_call({create,X_coordinate,Y_coordinate,Type},_From,ETS_name) -> %create new cell by request from general cell
			{X_axis,Y_axis}=check_place(X_coordinate,Y_coordinate,ETS_name),
			if X_axis == -1 ->
				%From!{reject,0};
				{reply,{reject,0},ETS_name};
			true -> 
				Ttl=rand:uniform(15),
				if Type == general_cell -> Wooded=0;
				true -> Wooded=1
				end,
				[{_,{{EnvOrganic,EnvEnergy},_}}]=ets:lookup(ETS_name,{X_axis,Y_axis}),
				ets:delete(ETS_name,{X_axis,Y_axis}),
				ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{Type,5,5,Ttl,0,Wooded}}}),
				%From!{ok,-1}
				{reply,{ok,-1},ETS_name}
			end.
			%{noreply,ETS_name}.
%%------------------------------------------------------------------------------------------------------------------------------------
handle_cast(_,ETS_name) -> {noreply,ETS_name}.
%%------------------------------------------------------------------------------------------------------------------------------------
handle_info({die,X_axis,Y_axis,Organic,Energy},ETS_name) -> %1.cell dies
			[{_,{{EnvOrganicOld,EnvEnergyOld},_}}]=ets:lookup(ETS_name,{X_axis,Y_axis}),
			ets:delete(ETS_name,{X_axis,Y_axis}),
			ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganicOld+Organic,EnvEnergyOld+Energy},{none,0,0,0,0,0}}}),
			{noreply,ETS_name};
handle_info({new_type,X_axis,Y_axis,Type,Ttl},ETS_name) -> %2.new_type of cell in {X,Y}
			[{_,{{EnvOrganicOld,EnvEnergyOld},{_,Energy,Organic,_,_,Wooded}}}]=ets:lookup(ETS_name,{X_axis,Y_axis}),
			ets:delete(ETS_name,{X_axis,Y_axis}),
			ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganicOld,EnvEnergyOld},{Type,Energy,Organic,Ttl,0,Wooded}}}),
			{noreply,ETS_name}.
%%------------------------------------------------------------------------------------------------------------------------------------
terminate(_Reason, _State) -> ok.
%%------------------------------------------------------------------------------------------------------------------------------------
create_cells_func(0,_,_,_,_) -> ok; %all needed cells created
create_cells_func(Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name) -> %creating new general cell
				X_axis=rand:uniform(Xmax-Xmin)+Xmin, %choose random position
				Y_axis=rand:uniform(Ymax-Ymin)+Ymin,
				case ets:lookup(ETS_name,{X_axis,Y_axis}) of %check if there already exist cell
						[{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{none,_,_,_,_,_}}}] -> %create cell
							%%ETS line [{{X_coordinate,Y_coordinate},{{EnvOrganic,EnvEnergy},{cell_type,energy,organic,TTL,cells_created,wooded}}}]
							ets:delete(ETS_name,{X_axis,Y_axis}),
							ets:insert(ETS_name,{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{general,Energy,Organic,-1,0,0}}}), %update ETS
							spawn(general_cell_funcs,general_cell,[Energy,Organic,0,0,{X_axis,Y_axis},ETS_name]),
							create_cells_func(Cells_Amount-1,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name); 
						_ -> create_cells_func(Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name) %restart
				end.
%%------------------------------------------------------------------------------------------------------------------------------------
check_place(X_axis,Y_axis,ETS_name) -> 
			{New_X_axis,New_Y_axis}=check_place2(X_axis,Y_axis,ETS_name,[[1,1],[1,-1],[-1,1],[-1,-1]]),%ets:lookup(ETS_name,{X_axis,Y_axis})
			{New_X_axis,New_Y_axis}.
check_place2(X_axis,Y_axis,_,[]) -> {X_axis,Y_axis};
check_place2(X_axis,Y_axis,ETS_name,[[Val1,Val2]|T]) ->
			[{_,{_,{Type,_,_,_,_,_}}}]=ets:lookup(ETS_name,{X_axis+Val1,Y_axis+Val2}),
			if Type == none ->
					check_place2(X_axis+Val1,Y_axis+Val2,ETS_name,[]);
			true -> check_place2(X_axis,Y_axis,ETS_name,T)
			end.
%check_place(_,_,_) -> ok.
