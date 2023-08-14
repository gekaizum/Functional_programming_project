%%Yevgeniy Gluhoy: 336423629
-module(cell_funcs).
-export([leaf_cell/7]).
-export([seed_cell/7]).
-export([antena_cell/7]).
%-export([wood_cell/]).
-export([root_cell/7]).
-define(MAX_ENERGY,30).
-define(MAX_ORGANIC,30).
-define(EVENT_TIME,1000).
%-define(TOTAL_WEIGHT_ACTION,25).
%-define(TOTAL_WEIGHT_TRANSFORM,16).
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%ETS line [{{X_coordinate,Y_coordinate},{{EnvOrganic,EnvEnergy},{cell_type,energy,organic,TTL,cells_created,wooded}}}]
%%parameters with default values: 
		%%general_cell(Energy=0,Organic=0,Cells_created=0,Woodded=0,{x_coordinate,y_coordinate},Ets_name)
		%%Cells_created<=3 always
		%%Woodded can be 1 or 0 only
		%%maximum Energy=15
		%%maximum Organic=15
		%%Dies if Energy>15 || Energy=0 || Organic>15
		%%Cells_created<=3 always
		%%Actions: Move/Create_new_cell/Transform_to_new_cell/Eat_cell/do_nothing
%%ETS line [{{X_coordinate,Y_coordinate},{{EnvOrganic,EnvEnergy},{cell_type,energy,organic,TTL,cells_created,wooded}}}]
%%------------------------------------------------------------------------------------------------------------------------------------
leaf_cell(Energy,Organic,_Cells_created,_Woodded,{X_coordinate,Y_coordinate},ETS_name,Ttl) ->
			[{_,{{EnvEnergy,EnvOrganic},_}}]=ets:lookup(ETS_name,{X_coordinate,Y_coordinate}),%check place in ETS
			if (EnvEnergy>?MAX_ENERGY) or (EnvOrganic>?MAX_ORGANIC) -> %die condition
								cell_manager!{die,X_coordinate,Y_coordinate,Organic,Energy}, %inform manager
						 		exit(self());%die
			true ->
					%Ttl=rand:uniform(15),%calc Time to live
					cell_manager!{new_type,X_coordinate,Y_coordinate,leaf_cell,Ttl},%inform manager to change type in ETS
					leaf_cell_loop(Energy,Organic,{X_coordinate,Y_coordinate},Ttl)
			end.
%%------------------------------------------------------------------------------------------------------------------------------------
leaf_cell_loop(Energy,Organic,{X_coordinate,Y_coordinate},Ttl) -> 
			receive %wait for timeout
				{restart} -> exit(self())
			after ?EVENT_TIME -> ok
			end,
			New_Ttl=Ttl-1,
			if (Ttl==0) or (Energy==0) -> cell_manager!{die,X_coordinate,Y_coordinate,Organic,Energy}, %inform manager
						 			exit(self());%die
				Energy < ?MAX_ENERGY-1 -> %here might be added condition of sun light on/off	
										leaf_cell_loop(Energy,Organic,{X_coordinate,Y_coordinate},New_Ttl);%do nothing
				true -> leaf_cell_loop(Energy-1,Organic,{X_coordinate,Y_coordinate},New_Ttl) %earn energy from sun
			end.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
seed_cell(Energy,Organic,_Cells_created,_Woodded,{X_coordinate,Y_coordinate},ETS_name,_Ttl) -> 
			cell_manager!{new_type,X_coordinate,Y_coordinate,seed_cell,0},%inform manager to change type in ETS
			seed_cell_loop(Energy,Organic,{X_coordinate,Y_coordinate},ETS_name).
%%------------------------------------------------------------------------------------------------------------------------------------
seed_cell_loop(Energy,Organic,{X_coordinate,Y_coordinate},ETS_name) -> 
			receive %wait for timeout
				{restart} -> exit(self())
			after ?EVENT_TIME -> 
					if Energy < 3 ->
								%spawn general cell
								cell_manager!{new_type,X_coordinate,Y_coordinate,general_cell,-1},%inform manager to change type in ETS
								CellID=spawn(general_cell_funcs,general_cell,[15,Organic,0,0,{X_coordinate,Y_coordinate},ETS_name,0]),
								cell_monitor!{add,CellID},%Send ID to cells_monitor
								exit(self());
						true -> 
								Random=rand:uniform(10),
								if Random>5 ->  %spawn general cell
												cell_manager!{new_type,X_coordinate,Y_coordinate,general_cell,-1},%inform manager to change type in ETS
												CellID=spawn(general_cell_funcs,general_cell,[15,Organic,0,0,{X_coordinate,Y_coordinate},ETS_name,0]),
												cell_monitor!{add,CellID},%Send ID to cells_monitor
												exit(self());
									true -> seed_cell_loop(Energy-1,Organic,{X_coordinate,Y_coordinate},ETS_name)
								end
					end
			end.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
antena_cell(Energy,Organic,_Cells_created,_Woodded,{X_coordinate,Y_coordinate},ETS_name,Ttl) ->
			[{_,{{EnvEnergy,EnvOrganic},_}}]=ets:lookup(ETS_name,{X_coordinate,Y_coordinate}),%check place in ETS
			if EnvOrganic>?MAX_ORGANIC -> %die condition
						cell_manager!{die,X_coordinate,Y_coordinate,Organic,Energy}, %inform manager
						exit(self()); %die
			true ->
					%Ttl=rand:uniform(15),%calc Time to live
					cell_manager!{new_type,X_coordinate,Y_coordinate,antena_cell,Ttl},%inform manager to change type in ETS
					antena_cell_loop(Energy+EnvEnergy,Organic,{X_coordinate,Y_coordinate},Ttl)
			end.
%%------------------------------------------------------------------------------------------------------------------------------------
antena_cell_loop(Energy,Organic,{X_coordinate,Y_coordinate},Ttl) -> 
			receive %wait for timeout
				{restart} -> exit(self())
			after ?EVENT_TIME -> ok
			end,
			New_Ttl=Ttl-1,
			if (Ttl==0) or (Energy==0) -> 
									cell_manager!{die,X_coordinate,Y_coordinate,Organic,Energy}, %inform manager
						 			exit(self());
				true -> 
						antena_cell_loop(Energy-1,Organic,{X_coordinate,Y_coordinate},New_Ttl)
			end.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
root_cell(Energy,Organic,_Cells_created,_Woodded,{X_coordinate,Y_coordinate},ETS_name,Ttl) ->
			[{_,{{EnvEnergy,EnvOrganic},_}}]=ets:lookup(ETS_name,{X_coordinate,Y_coordinate}),%check place in ETS
			if EnvEnergy>?MAX_ENERGY -> %die condition
						cell_manager!{die,X_coordinate,Y_coordinate,Organic,Energy}, %inform manager
						exit(self()); %die
			true ->
					%Ttl=rand:uniform(15),%calc Time to live
					cell_manager!{new_type,X_coordinate,Y_coordinate,root_cell,Ttl},%inform manager to change typy in ETS
					root_cell_loop(Energy,Organic+EnvOrganic,{X_coordinate,Y_coordinate},Ttl)
			end.
%%------------------------------------------------------------------------------------------------------------------------------------
root_cell_loop(Energy,Organic,{X_coordinate,Y_coordinate},Ttl) -> 
			receive %wait for timeout
				{restart} -> exit(self())
			after ?EVENT_TIME -> ok
			end,
			New_Ttl=Ttl-1,
			if (Ttl==0) or (Energy==0) -> 
									cell_manager!{die,X_coordinate,Y_coordinate,Organic,Energy}, %inform manager
						 			exit(self());
				Organic>0 -> 
						 root_cell_loop(Energy,Organic-1,{X_coordinate,Y_coordinate},New_Ttl);
				true -> 
						root_cell_loop(Energy-1,Organic,{X_coordinate,Y_coordinate},New_Ttl)
			end.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
