%%Yevgeniy Gluhoy: 336423629
-module(general_cell_funcs).
-export([general_cell/7]).
-define(MAX_ENERGY,15).
-define(MAX_ORGANIC,15).
-define(MAX_CHILDREN,3).
-define(TOTAL_WEIGHT_ACTION,25).
-define(TOTAL_WEIGHT_TRANSFORM,16).
-define(EVENT_TIME,1000).
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
		%%TTL=-1 for general cells
%%------------------------------------------------------------------------------------------------------------------------------------
general_cell(Energy,Organic,Cells_created,Woodded,{X_coordinate,Y_coordinate},ETS_name,_Ttl) -> 
			timer:sleep(2000),
			Actions_array=[{"Move",6},{"Transform_to_new_cell",6},{"Eat_cell",1},{"Create_new_cell",6},{"do_nothing",6}],
			Transform_array=[{leaf_cell,4},{seed_cell,4},{antena_cell,4},{root_cell,4}],
			general_cell_loop(Energy,Organic,Cells_created,Woodded,{X_coordinate,Y_coordinate},ETS_name,Actions_array,Transform_array).
%%------------------------------------------------------------------------------------------------------------------------------------
general_cell_loop(Energy,Organic,Cells_created,Woodded,{X_coordinate,Y_coordinate},ETS_name,Actions_array,Transform_array) ->
		[{_,{{EnvEnergy,EnvOrganic},_}}]=ets:lookup(ETS_name,{X_coordinate,Y_coordinate}),%check place in ETS
		receive %wait for timeout
			{restart} -> exit(self())
			after ?EVENT_TIME -> if ((((Energy+EnvEnergy) > ?MAX_ENERGY) or (Organic > ?MAX_ORGANIC)) or (Energy=<0))-> %check if alive
																		cell_manager!{die,X_coordinate,Y_coordinate,Organic,Energy}, %inform manager
																		exit(self()); 
						 true -> ok %keep going
						 end
								
		end,
		{New_Actions_array,New_Transform_array}=weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,Cells_created,Woodded),
		if Organic>0 , Energy=<15 -> 	%transform organic into energy
			NewOrganic=Organic-1,
			NewEnergy=Energy+1;
		true -> NewOrganic=Organic,
			NewEnergy=Energy
		end,
		Random=rand:uniform(?TOTAL_WEIGHT_ACTION),
		Action=select_item(Actions_array,Random), %choose random action
		if  Action == "Move" -> %moove to new position
			{X_move,Y_move} = random_move(),
			{New_X_coordinate,New_Y_coordinate}=gen_server:call(cell_manager,{move,X_coordinate+X_move,Y_coordinate+Y_move,X_coordinate,Y_coordinate}),
			general_cell_loop(NewEnergy-1,NewOrganic+EnvOrganic,Cells_created,Woodded,{New_X_coordinate,New_Y_coordinate},ETS_name,New_Actions_array,New_Transform_array);	
			Action == "Transform_to_new_cell" -> %transform to another cell type
						Random2=rand:uniform(?TOTAL_WEIGHT_TRANSFORM),
						RandomTransform=select_item(Transform_array,Random2),
						Ttl=rand:uniform(15)+5,%calc Time to live
						if  RandomTransform==leaf_cell -> 
										CellID=spawn(cell_funcs,leaf_cell,[Energy,Organic,0,0,{X_coordinate,Y_coordinate},ETS_name,Ttl]);
							RandomTransform==seed_cell ->
										CellID=spawn(cell_funcs,seed_cell,[Energy,Organic,0,0,{X_coordinate,Y_coordinate},ETS_name,Ttl]);
							RandomTransform==antena_cell ->
										CellID=spawn(cell_funcs,antena_cell,[Energy,Organic,0,0,{X_coordinate,Y_coordinate},ETS_name,Ttl]);
							RandomTransform==root_cell -> 
										CellID=spawn(cell_funcs,root_cell,[Energy,Organic,0,0,{X_coordinate,Y_coordinate},ETS_name,Ttl])
						end,
						cell_monitor!{add,CellID},%Send ID to cells_monitor
						exit(self());
			Action == "Eat_cell" -> %eat cell in random position around
						{X_move,Y_move} = random_move(),
						{New_X_coordinate,New_Y_coordinate,Add_energy}=gen_server:call(cell_manager,{eat,X_coordinate+X_move,Y_coordinate+Y_move,X_coordinate,Y_coordinate}),
						%cell_manager!{eat,X_coordinate+X_move,Y_coordinate+Y_move},%ask manager to move cell
						%receive
						%	{ok,New_X_coordinate,New_Y_coordinate,Add_energy} -> ok;
						%	{reject,New_X_coordinate,New_Y_coordinate,Add_energy} ->ok
						%end,
						general_cell_loop(NewEnergy+Add_energy-1,NewOrganic+EnvOrganic,Cells_created,Woodded,{New_X_coordinate,New_Y_coordinate},ETS_name,New_Actions_array,New_Transform_array);	
			Action == "Create_new_cell" ->  %creating new cell in random position around
											Random2=rand:uniform(?TOTAL_WEIGHT_TRANSFORM),
											RandomChild=select_item(Transform_array,Random2),
											{Atom,Add_energy}=gen_server:call(cell_manager,{create,X_coordinate,Y_coordinate,RandomChild}),
											if ((Atom==ok) and (RandomChild==seed_cell)) -> 
												New_Woodded=Woodded,
												New_Cells_created=Cells_created+1;
											Atom==ok ->
												New_Woodded=1,
												New_Cells_created=Cells_created+1;
											true -> New_Woodded=Woodded,
													New_Cells_created=Cells_created
											end,
											general_cell_loop(NewEnergy+Add_energy-1,NewOrganic+EnvOrganic,New_Cells_created,New_Woodded,{X_coordinate,Y_coordinate},ETS_name,New_Actions_array,New_Transform_array);
			Action == "do_nothing" ->  
						general_cell_loop(NewEnergy-1,NewOrganic+EnvOrganic,Cells_created,Woodded,{X_coordinate,Y_coordinate},ETS_name,New_Actions_array,New_Transform_array)
		end.
%%------------------------------------------------------------------------------------------------------------------------------------
select_item([{Action,Weight}|T],Random)->
			if Random =< Weight ->
				Action;
			true ->
				select_item(T,Random-Weight)
			end.
%%------------------------------------------------------------------------------------------------------------------------------------
random_move() -> RandNum1=rand:uniform(),
				 RandNum2=rand:uniform(),
				 if RandNum1 < 0.5 ,RandNum2 < 0.5 -> {1,1};
					RandNum1 < 0.5 ,RandNum2 > 0.5 -> {1,-1};
					RandNum1 > 0.5 ,RandNum2 < 0.5 -> {-1,1};
				 	true -> {-1,-1}
				 end.
%%------------------------------------------------------------------------------------------------------------------------------------
weight_calc([A,B,C,D,E],[F,G,H,J]) -> %Last step in weigth calculation
							{[{"Move",A},{"Transform_to_new_cell",B},{"Eat_cell",C},{"Create_new_cell",D},{"do_nothing",E}],
							[{leaf_cell,F},{seed_cell,G},{antena_cell,H},{root_cell,J}]}.

weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,Cells_created,0) -> %Last argument is "Woodded"
	weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,Cells_created,[6,6,1,6,6]);
weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,5,_Woodded) -> 
	weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,[0,12,1,0,12]);
weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,Cells_created,1) -> 
	weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,Cells_created,[0,8,1,8,8]);
weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,_Cells_created,PrioritiesAct) -> 
	weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,PrioritiesAct).

weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,[A,B,C,D,E]) -> 
													if  (Organic+EnvOrganic) > ?MAX_ORGANIC -> weight_calc([A,B+E/2,C,D,E/2],[2,2,2,10]);
														(Energy+EnvEnergy) > ?MAX_ENERGY -> weight_calc([A,B+E/2,C,D,E/2],[2,2,10,2]);
														(Energy+EnvEnergy) < 3 -> weight_calc([A/2,B+E/2,C+A/2+D/2,D/2,E/2],[4,8,2,2]);
														(Energy+EnvEnergy) >= 10 -> weight_calc([A,B/2,C,D+B/2,E],[3,7,3,3]);
														true -> weight_calc([A,B,C,D,E],[4,8,2,2])
													end.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////				
