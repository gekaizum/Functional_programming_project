%%Yevgeniy Gluhoy: 336423629
-module(graphic_node).
-behaviour(gen_server).
%%------------------------------------------------------------------------------------------------------------------------------------
-export([init/1,start/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).%
-export([msg_delivery/2]).
%%------------------------------------------------------------------------------------------------------------------------------------
-define(MAX_ENERGY,15).
-define(MAX_ORGANIC,15).
-define(MAX_CHILDREN,3).
-define(EVENT_TIME,1000).
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////gen server init/////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%Arguments: BoardSize - int, board will be square - must be greater than number of hosts
			%%TotalProcNum - Total amount of processes in start of simulation
			%%ListOfNodeNames - List of availible nodes
			%%Energy,Organic - starting parameter for cells
			%%EnvEnergy,EnvOrganic - starting parameter for environment
start(Args) -> gen_server:start_link({global, main_node},?MODULE,Args,[]). 
%%Args = [BoardSize,TotalProcNum,ListOfNodeNames,ListOfServerNames,Energy,Organic,EnvEnergy,EnvOrganic]
%%------------------------------------------------------------------------------------------------------------------------------------
init([BoardSize,TotalProcNum,ListOfNodeNames,ListOfServerNames,Energy,Organic,EnvEnergy,EnvOrganic]) -> 
			spawn(main_logger,logger_start,[]), %Logger start
			spawn(main_logger,node_monitoring,[ListOfNodeNames,ListOfServerNames]),
			global:register_name(main_node,self()),%works now
			ETS_name=ets:new(general_table,[named_table,ordered_set,public]),%New ets
			timer:sleep(1000),
			logger_main!{init},
			ets_creator(1,1,BoardSize,BoardSize,ETS_name,EnvEnergy,EnvOrganic),%starting parametrs for data in ets
			logger_main!{ets_c},
			node_starter(ListOfNodeNames,ListOfServerNames),
			%node starter might be added, it will receive as argument atom and name for each node and will activate them
			%{_Status,Pid}=rpc:call('node1@127.0.0.1', general_node, start, [node1]),%Starting nodes
			%logger_main!Pid,
			{ok,{BoardSize,TotalProcNum,ListOfNodeNames,ListOfServerNames,Energy,Organic,EnvEnergy,EnvOrganic,ETS_name}}.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Not in use but must be exported/////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
code_change(_,_,_) -> {ok,normal}.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Handlers of type call///////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%Here will be restart call because of lost connection with host
handle_call({restart,NodeNameDown,ServerNameDown},_From,{BoardSize,ListOfNodeNames,ListOfServerNames,TotalProcNum,ETS_name}) -> 
			logger_main!{sMsg,"Node down, Restarting simulation",ServerNameDown},
			NewListOfNodeNames = lists:delete(NodeNameDown,ListOfNodeNames),
			NewListOfServerNames = lists:delete(ServerNameDown,ListOfServerNames),
			if (length(NewListOfNodeNames)>0) ->
				restart_function(BoardSize,NewListOfServerNames,[],ETS_name),
				logger_main!{sMsg,"Simulation restarted"},
				{reply,{done},{BoardSize,NewListOfNodeNames,NewListOfServerNames,TotalProcNum,ETS_name}};%all done
			true -> {stop,normal,ok,{BoardSize,NewListOfNodeNames,NewListOfServerNames,TotalProcNum,ETS_name}}
			end.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Handlers of type cast///////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
handle_cast(stop,{Status}) -> 
			{stop,normal,ok,{Status}}.%termination
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Handlers of type info///////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%Init %Graphic node must send parameters
handle_info({start},{BoardSize,TotalProcNum,ListOfNodeNames,ListOfServerNames,Energy,Organic,EnvEnergy,EnvOrganic,ETS_name}) -> 
			logger_main!{"Remote procedure"},
			call_func({BoardSize,TotalProcNum,ListOfServerNames,Energy,Organic,EnvEnergy,EnvOrganic},[],ListOfServerNames),
			logger_main!{start},
			%create process that will check connection
			{noreply,{BoardSize,ListOfNodeNames,ListOfServerNames,TotalProcNum,ETS_name}};%ListOfNodeNames == Active Nodes
%%------------------------------------------------------------------------------------------------------------------------------------
handle_info({stop},Status) -> 
			{stop,normal,Status};
%%------------------------------------------------------------------------------------------------------------------------------------
handle_info({keepalive,Host,From,ETS_List},{BoardSize,ListOfNodeNames,ListOfServerNames,TotalProcNum,ETS_name}) -> %Init %Graphic node must send parameters
			rpc:call(Host, genNode_Mailbox, msg_delivery, [From,{ack}]),
			%{global,From)!{ack},
			logger_main!{keepalive,Host},
			ets_changer(ETS_List,ETS_name),
			logger_main!{update},
			%whereis(sim_gui)!ets:tab2list(ETS_name),
			{noreply,{BoardSize,ListOfNodeNames,ListOfServerNames,TotalProcNum,ETS_name}};
%%------------------------------------------------------------------------------------------------------------------------------------
handle_info({send_me},{BoardSize,ListOfNodeNames,ListOfServerNames,TotalProcNum,ETS_name}) ->
			whereis(sim_gui)!ets:tab2list(ETS_name),
			{noreply,{BoardSize,ListOfNodeNames,ListOfServerNames,TotalProcNum,ETS_name}}.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////termination/////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terminate(_Reason, {_BoardSize,ListOfNodeNames,ListOfServerNames,_TotalProcNum,_ETS_name}) ->   
			node_monitoring!{stop},
			host_terminating(ListOfNodeNames,ListOfServerNames),
			logger_main!{stop,ok},
			ok.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%//////////////////////////////////////////////////////////internal funcs/////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
ets_creator(Xmin,Ymin,Xmax,Ymax,_ETS_name,_EnvEnergy,_EnvOrganic) when ((Xmin > Xmax) and (Ymin > Ymax)) -> ok;
ets_creator(Xmin,Ymin,Xmax,Ymax,ETS_name,EnvEnergy,EnvOrganic) when (Ymin > Ymax) ->
					ets_creator(Xmin+1,1,Xmax,Ymax,ETS_name,EnvEnergy,EnvOrganic);
ets_creator(Xmin,Ymin,Xmax,Ymax,ETS_name,EnvEnergy,EnvOrganic) -> 
					ets:insert(ETS_name,{{Xmin,Ymin},{{EnvEnergy,EnvOrganic},{none,0,0,0,0,0}}}),
					%%ETS line [{{X_coordinate,Y_coordinate},{{EnvOrganic,EnvEnergy},{cell_type,energy,organic,TTL,cells_created,wooded}}}]
					ets_creator(Xmin,Ymin+1,Xmax,Ymax,ETS_name,EnvEnergy,EnvOrganic).
%%------------------------------------------------------------------------------------------------------------------------------------
call_func({_BoardSize,_TotalProcNum,[],_Energy,_Organic,_EnvEnergy,_EnvOrganic},_List,_ActiveHosts) -> ok;
call_func({BoardSize,TotalProcNum,ActiveHosts,Energy,Organic,EnvEnergy,EnvOrganic},[],_ActiveHosts) -> 
		List=field_devider(1,TotalProcNum,length(ActiveHosts),BoardSize,BoardSize,[]),
		call_func({BoardSize,TotalProcNum,ActiveHosts,Energy,Organic,EnvEnergy,EnvOrganic},List,ActiveHosts); 
call_func({BoardSize,TotalProcNum,[H1|T1],Energy,Organic,EnvEnergy,EnvOrganic},[{{Xmin,Ymin,Xmax,Ymax},Cells_Amount}|T2],ActiveHosts) ->
		(global:whereis_name(H1))!{init,ActiveHosts,Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,EnvEnergy,EnvOrganic},
		%io:format("~nMsg to ~s sent~n",[H1]),
		call_func({BoardSize,TotalProcNum,T1,Energy,Organic,EnvEnergy,EnvOrganic},T2,ActiveHosts).
%%------------------------------------------------------------------------------------------------------------------------------------
field_devider(_BoardSize,_TotalProcNum,0,_SizeLeft,_,List) -> List;%lists:reverse(List);
field_devider(Start_y,TotalProcNum,ActiveHosts,SizeLeft,BoardSize,List) -> %List=[{{Xmin,Ymin,Xmax,Ymax},Cells_Amount}]
	Size = SizeLeft div ActiveHosts,
	Amount = (TotalProcNum div ActiveHosts),
	if  ActiveHosts==1 -> %we have only one host
			field_devider(Start_y,TotalProcNum,0,0,BoardSize,List++[{{1,Start_y,BoardSize,Start_y+SizeLeft-1},TotalProcNum}]);
		((Size>0) and (Amount>0)) -> 
			field_devider(Start_y+Size,TotalProcNum-Amount,ActiveHosts-1,SizeLeft-Size,BoardSize,List++[{{1,Start_y,BoardSize,Start_y+Size-1},TotalProcNum-Amount}]);
		true -> %%no processes for other hosts
			field_devider(Start_y+Size,0,ActiveHosts-1,SizeLeft-Size,BoardSize,List++[{{1,Start_y,BoardSize,Start_y+Size-1},TotalProcNum}])
	end.
%%------------------------------------------------------------------------------------------------------------------------------------
ets_changer([],_ETS_name) -> ok;
ets_changer([{{X_axis,Y_axis},H}|T],ETS_name) -> 
				ets:delete(ETS_name,{X_axis,Y_axis}), % change ets line
				ets:insert(ETS_name,{{X_axis,Y_axis},H}),
				ets_changer(T,ETS_name).
%%------------------------------------------------------------------------------------------------------------------------------------
msg_delivery(To,Msg) -> 
						To!Msg.
%%------------------------------------------------------------------------------------------------------------------------------------
node_starter([],_ListOfServerNames) -> ok;
node_starter([H1|T1],[H2|T2]) -> %activates servers at given nodes
			{_Status,Pid}=rpc:call(H1, general_node, start, [{H1,H2}]),%Starting server
			logger_main!{node_name,H2,Pid},
			node_monitoring!{add,H1},
			node_starter(T1,T2).
%%------------------------------------------------------------------------------------------------------------------------------------
host_terminating([],_) -> ok;
host_terminating([H1|T1],[H2|T2]) ->
			rpc:call(H1, general_node, stop, [(global:whereis_name(H2))]),%Starting server
			logger_main!{terminating,H1},
			host_terminating(T1,T2).
%%------------------------------------------------------------------------------------------------------------------------------------
%handle_call({restart,Data,NewYmin,NewYmax}
restart_function(_BoardSize,[],_List,_ETS_name) -> ok;
restart_function(BoardSize,ActiveHosts,[],ETS_name) -> 
			List=field_devider(1,1,length(ActiveHosts),BoardSize,BoardSize,[]),
			ETS_List=ets:tab2list(ETS_name),
			restart_function(ActiveHosts,List,ActiveHosts,ETS_List);
restart_function([H1|T1],[{{_Xmin,Ymin,_Xmax,Ymax},_}|T2],ActiveHosts,ETS_List) ->
%%ETS line [{{X_axis,Y_axis},{{EnvOrganic,EnvEnergy},{cell_type,energy,organic,TTL,cells_created,wooded}}}]
			Data=[{{X_axis,Y_axis},H} || {{X_axis,Y_axis},H} <- ETS_List,((Y_axis=<Ymax) and (Y_axis>=Ymin))], %[{{X_axis,Y_axis},H}|T]
			(global:whereis_name(H1))!{restart,Data,Ymin,Ymax,ActiveHosts},
			restart_function(T1,T2,ActiveHosts,ETS_List).
