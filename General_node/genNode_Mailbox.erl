%%Yevgeniy Gluhoy: 336423629
-module(genNode_Mailbox).
-export([genNode_Mailbox/3]).
-export([logger_process_start/1]).
-export([msg_delivery/2]).

genNode_Mailbox(ETS_name,Node_name,Host_name) -> 
		erlang:monitor(process,Node_name),
		%register(genNode_Mailbox,self()),
		loggerp!"General Node Mailbox Active",
		genNode_Mailbox_loop(ETS_name,Node_name,5,Host_name).

genNode_Mailbox_loop(ETS_name,Node_name,AckStatus,Host_name) -> 
		receive
			{stop} -> loggerp!"General Node Mailbox terminated",
					ok;
			{ack} -> NewAckStatus=AckStatus+1,
					 loggerp!"Ack received",
					 genNode_Mailbox_loop(ETS_name,Node_name,NewAckStatus,Host_name);
			{'DOWN',_Monitor,process,_Proc,_Info} -> ok;
			{restart,New_ETS_name} -> genNode_Mailbox_loop(New_ETS_name,Node_name,AckStatus,Host_name)
		after 1000 -> %send ets to graphic node, it is also keepalive message
					NewAckStatus=AckStatus-1,
					ID=(global:whereis_name(main_node)),
					if (NewAckStatus=<0) -> 
						loggerp!{no_c},
						gen_server:stop(Node_name),%terminate general_node
						genNode_Mailbox_loop(ETS_name,Node_name,20,Host_name);
					(ID==undefined) -> genNode_Mailbox_loop(ETS_name,Node_name,NewAckStatus,Host_name);
					true -> %no connetion
						ID!{keepalive,Host_name,genNode_Mailbox,ets:tab2list(ETS_name)},
						loggerp!"Keepalive sent",
						genNode_Mailbox_loop(ETS_name,Node_name,NewAckStatus,Host_name)	
					end
		end.
%%------------------------------------------------------------------------------------------------------------------------------------
logger_process_start(Pid) -> 
			{ok,LogFile} = file:open("log.txt",[write]),%open log file
			{ok,Cell_log} = file:open("cell_log.txt",[write]),%open log file
			io:format(LogFile,"Logger start~n",[]),
			erlang:monitor(process,Pid),
			register(loggerp,self()),
			logger_loop(LogFile,Cell_log).

logger_loop(LogFile,Cell_log) -> 
			receive
				{'DOWN',_Monitor,process,Proc,Info} -> io:format(LogFile,"Module down: Pid: ~p Info: ~p~n",[Proc,Info]),
														logger_loop(LogFile,Cell_log);
				{stop,ok} -> io:format(LogFile,"Node terminated~n",[]),
							file:close(Cell_log),
							file:close(LogFile);
				{no_c} -> io:format(LogFile,"Connection with graphic node lost~n",[]),
							logger_loop(LogFile,Cell_log);
				{cell_manager,ok} -> 
									erlang:monitor(process,cell_manager),
									io:format(LogFile,"Cell Manager Active~n",[]),
									logger_loop(LogFile,Cell_log);
				{prin,Msg} -> io:format(LogFile,"~p~n",[Msg]),
							logger_loop(LogFile,Cell_log);
				{cellInfo,Msg} -> io:format(Cell_log,"~s~n",[Msg]),
						logger_loop(LogFile,Cell_log);
				{Msg1,Msg2} -> io:format(Cell_log,"~s:~s~n",[Msg1,Msg2]),
						logger_loop(LogFile,Cell_log);
				Msg ->  io:format(LogFile,"~s~n",[Msg]),
						logger_loop(LogFile,Cell_log)
			end.
%%------------------------------------------------------------------------------------------------------------------------------------
msg_delivery(To,Msg) -> %loggerp!"Message received by delivery",
						%io:format("~nSending to ~s~n",[To]),
						To!Msg.
						%loggerp!"Message sent by delivery".
