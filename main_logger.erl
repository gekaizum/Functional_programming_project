%%Yevgeniy Gluhoy: 336423629
-module(main_logger).

-export([logger_start/0,node_monitoring/2]).

logger_start() -> 
			register(logger_main,self()),
			{ok,LogFile} = file:open("main_log.txt",[write]),%open log file
			%io:format("Logger start~n"),
			io:format(LogFile,"Logger start~n",[]),
			logger_loop(LogFile).

logger_loop(LogFile) -> 
			receive
				{stop,ok} -> io:format(LogFile,"Simulation terminated~n",[]),
							file:close(LogFile);
				{update} -> io:format(LogFile,"ETS table updated~n",[]),
							logger_loop(LogFile);
				{keepalive,Host} -> io:format(LogFile,"Received keepalive from ~p~n",[Host]),
								logger_loop(LogFile);
				{start} -> 
							io:format(LogFile,"Simulation started~n",[]),
							logger_loop(LogFile);
				{"Remote procedure"} -> 
									io:format(LogFile,"Starting remote procedures: starting general nodes~n",[]),
									logger_loop(LogFile);
				{ets_c} -> 
						io:format(LogFile,"ETS table created~n",[]),
						logger_loop(LogFile);
				{terminating,H} ->
						io:format(LogFile,"Node ~s terminated~n",[H]),
						logger_loop(LogFile);
				{node_name,H2,Pid} -> 
						io:format(LogFile,"Node ~s activated: ~p~n",[H2,Pid]),
						logger_loop(LogFile);
				{init} -> 
						io:format(LogFile,"Initialization procedure started~n",[]),
						logger_loop(LogFile);
				{sMsg,Msg,Name} -> io:format(LogFile,"~p: ~s~n",[Name,Msg]),
						logger_loop(LogFile);
				{sMsg,Msg} -> io:format(LogFile,"~s~n",[Msg]),
						logger_loop(LogFile);
				Msg ->  io:format(LogFile,"~p~n",[Msg]),
						logger_loop(LogFile)
			end.
%%------------------------------------------------------------------------------------------------------------------------------------
node_monitoring(ListOfNodeNames,ListOfServerNames) -> 
			register(node_monitoring,self()),
			logger_main!{sMsg,"Node monitor started"},
			%net_kernel:monitor_nodes(true,ListOfNodeNames),
			Almost_map=lists:zip(ListOfNodeNames,ListOfServerNames),
			Map=maps:from_list(Almost_map),
			node_monitoring_loop(Map).
node_monitoring_loop(Map) ->
			receive
				{add,Node} -> erlang:monitor_node(Node,true),
							  %io:format("~nStart monitoring node~n",[]),
							  node_monitoring_loop(Map);
				{'DOWN',_,Node,_,_Reason} -> 
						logger_main!{sMsg,"Connection lost",Node},
						ServerName=maps:get(Node,Map),
						gen_server:call(main_node,{restart,Node,ServerName}),
						NewMap=maps:remove(Node,Map),
						node_monitoring_loop(NewMap);
				{stop} -> logger_main!{sMsg,"Node monitor stoped"},
						ok;
				{nodedown, Node} -> 
						%io:format("~nConnection lost~n",[]),
						logger_main!{sMsg,"Connection lost",Node},
						%io:format("~nLogger informed~n",[]),
						ServerName=maps:get(Node,Map),
						%io:format("~nServer name found in map~n",[]),
						gen_server:call(global:whereis_name(main_node),{restart,Node,ServerName}),
						%io:format("~nMain node restarted~n",[]),
						NewMap=maps:remove(Node,Map),
						%io:format("~nMap updated~n",[]),
						node_monitoring_loop(NewMap);
				_ -> 	io:format("~nUnrecognized message in monitor~n",[]),
						node_monitoring_loop(Map)
			end.
