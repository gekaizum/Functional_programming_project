%%Yevgeniy Gluhoy: 336423629
-module(general_cell_funcs).
-export([general_cell/6]).
-define(MAX_ENERGY,15).
-define(MAX_ORGANIC,15).
-define(MAX_CHILDREN,3).
-define(TOTAL_WEIGHT_ACTION,25).
-define(TOTAL_WEIGHT_TRANSFORM,16).
-define(EVENT_TIME,200).
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%ETS line [{X_coordinate,Y_coordinate},cell_type,energy,organic,TTL,cells_created,wooded]
%%parameters with default values: 
		%%general_cell(Energy=0,Organic=0,Cells_created=0,Woodded=0,{x_coordinate,y_coordinate},Ets_name)
		%%Cells_created<=3 always
		%%Woodded can be 1 or 0 only
		%%maximum Energy=15
		%%maximum Organic=15
		%%Dies if Energy>15 || Energy=0 || Organic>15
		%%Cells_created<=3 always
		%%Actions: Move/Create_new_cell/Transform_to_new_cell/Eat_cell/do_nothing
%%------------------------------------------------------------------------------------------------------------------------------------
general_cell(Energy,Organic,Cells_created,Woodded,{X_coordinate,Y_coordinate},ETS_name) ->
			Actions_array=[{"Move",6},{"Transform_to_new_cell",6},{"Eat_cell",1},{"Create_new_cell",6},{"do_nothing",6}],
			Transform_array=[{"Leaf",4},{"Seed",4},{"Antena",4},{"Root",4}],
			general_cell_loop(Energy,Organic,Cells_created,Woodded,{X_coordinate,Y_coordinate},ETS_name,Actions_array,Transform_array).
%%------------------------------------------------------------------------------------------------------------------------------------
general_cell_loop(Energy,Organic,Cells_created,Woodded,{X_coordinate,Y_coordinate},ETS_name,Actions_array,Transform_array) ->
		[_,_,EnvEnergy,EnvOrganic,_,_,_]=ets:lookup(ETS_name,{X_coordinate,Y_coordinate}),%check place in ETS
		receive %wait for timeout
			after ?EVENT_TIME -> if ((Energy+EnvEnergy) > ?MAX_ENERGY) or (Organic > ?MAX_ORGANIC) or (Energy==0)-> %check if alive
																		cell_manager!{die,X_coordinate,Y_coordinate,Organic,Energy}, %inform manager
																		exit(self()); 
						 true -> ok %keep going
						 end
								
		end,
		{New_Actions_array,New_Transform_array}=weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,Cells_created,Woodded),
		if Organic>0 , Energy=<10 -> 	%transform organic into energy
										NewOrganic=Organic-1,
										NewEnergy=Energy+1
		end,
		Random=rand:uniform(?TOTAL_WEIGHT_ACTION),
		Action=select_item(Actions_array,Random), %choose random action
		if  Action == "Move" -> %moove to new position
								{X_move,Y_move} = random_move(),
								cell_manager!{move,X_coordinate+X_move,Y_coordinate+Y_move},%ask manager to move cell
								receive
									{ok,New_X_coordinate,New_Y_coordinate} -> ok;
									{reject,New_X_coordinate,New_Y_coordinate} ->ok
								end,
								general_cell_loop(NewEnergy-1,NewOrganic+EnvOrganic,Cells_created,Woodded,{New_X_coordinate,New_Y_coordinate},ETS_name,New_Actions_array,New_Transform_array);	
			Action == "Transform_to_new_cell" -> %transform to another cell type
												Random2=rand:uniform(?TOTAL_WEIGHT_TRANSFORM),
												RandomTransform=select_item(Transform_array,Random2),
												Ttl=rand:uniform(15),%calc Time to live
												%-export([leaf_cell/5]).
												%-export([seed_cell/3]).
												%-export([antena_cell/5]).
												%-export([root_cell/5]).
												%leaf_cell(Energy,Organic,{X_coordinate,Y_coordinate},ETS_name,Ttl)
												if  RandomTransform=="Leaf" -> 
																spawn(cell_funcs,leaf_cell,[Energy,Organic,{X_coordinate,Y_coordinate},ETS_name,Ttl]);
													RandomTransform=="Seed" ->
																spawn(cell_funcs,seed_cell,[Energy,Organic,{X_coordinate,Y_coordinate}]);
													RandomTransform=="Antena" ->
																spawn(cell_funcs,antena_cell,[Energy,Organic,{X_coordinate,Y_coordinate},ETS_name,Ttl]);
													RandomTransform=="Root" -> 
																spawn(cell_funcs,root_cell,[Energy,Organic,{X_coordinate,Y_coordinate},ETS_name,Ttl])
												end,
												exit(self());
			Action == "Eat_cell" -> %eat cell in random position around
									{X_move,Y_move} = random_move(),
									cell_manager!{eat,X_coordinate+X_move,Y_coordinate+Y_move},%ask manager to move cell
									receive
										{ok,New_X_coordinate,New_Y_coordinate,Add_energy} -> ok;
										{reject,New_X_coordinate,New_Y_coordinate,Add_energy} ->ok
									end,
									general_cell_loop(NewEnergy+Add_energy-1,NewOrganic+EnvOrganic,Cells_created,Woodded,{New_X_coordinate,New_Y_coordinate},ETS_name,New_Actions_array,New_Transform_array);	
			Action == "Create_new_cell" ->  %creating new cell in random position around
											Random2=rand:uniform(?TOTAL_WEIGHT_TRANSFORM),
											RandomChild=select_item(Transform_array,Random2),
											cell_manager!{create,X_coordinate,Y_coordinate,RandomChild},
											receive
												{ok,Add_energy} ->  New_Woodded=1,
																	New_Cells_created=Cells_created+1;
												{reject,Add_energy} ->  New_Woodded=Woodded,
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
weight_calc([A,B,C,D,E],[F,G,H,J]) -> 
							{[{"Move",A},{"Transform_to_new_cell",B},{"Eat_cell",C},{"Create_new_cell",D},{"do_nothing",E}],
							[{"Leaf",F},{"Seed",G},{"Antena",H},{"Root",J}]}.
weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,Cells_created,0) -> 
	weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,Cells_created,[6,6,1,6,6]);
weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,Cells_created,1) -> 
	weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,Cells_created,[0,8,1,8,8]);
weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,3,_PrioritiesAct) -> 
	weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,[0,12,1,0,12]);
weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,_Cells_created,PrioritiesAct) -> 
	weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,PrioritiesAct).
weight_calc(EnvEnergy,EnvOrganic,Energy,Organic,[A,B,C,D,E]) -> 
													if  (Organic+EnvOrganic) > ?MAX_ORGANIC -> weight_calc([A,B+E/2,C,D,E/2],[2,2,2,10]);
														(Energy+EnvEnergy) > ?MAX_ENERGY -> weight_calc([A,B+E/2,C,D,E/2],[2,2,10,2]);
														(Energy+EnvEnergy) < 3 -> weight_calc([A/2,B+E/2,C+A/2+D/2,D/2,E/2],[5,5,3,3]);
														(Energy+EnvEnergy) >= 10 -> weight_calc([A,B/2,C,D+B/2,E],[4,4,4,4])
													end.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////				
