%%Yevgeniy Gluhoy: 336423629
-module(general_node).
-behaviour(gen_server).
%%------------------------------------------------------------------------------------------------------------------------------------
-export([start/1,stop/1,init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

%%------------------------------------------------------------------------------------------------------------------------------------
-define(MAX_ENERGY,15).
-define(MAX_ORGANIC,15).
-define(MAX_CHILDREN,3).
-define(EVENT_TIME,1000).
%%graphic_node - will be global standart name
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////gen server init/////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
start({Host_name,My_name}) -> gen_server:start({global, My_name},?MODULE,{My_name,Host_name},[]). 
%%------------------------------------------------------------------------------------------------------------------------------------
stop(My_name) -> gen_server:stop(My_name).
%%------------------------------------------------------------------------------------------------------------------------------------
init({My_name,Host_name}) -> 	%MailboxID=spawn(genNode_Mailbox,genNode_Mailbox,[]),%ETS_name,My_name
			%global:register(MailboxID,My_name),
			%register(self(),genNode),
			%receive %arguments - ({NumberOfCells2Create,RangeOfCoordinates})
			%	{init,My_name,Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,EnvEnergy,EnvOrganic} -> %Graphic node must send parameters
			%			ETS_name=ets:new(local_table,[named_table,read_concurency,set,public]),
			%			ets_creator(Xmin,Ymin,Xmax,Ymax,ETS_name,EnvEnergy,EnvOrganic,Xmin,Ymin),
			%			gen_server:start_link({local,cell_manager},cell_manager,[],[]),
			%			%MailboxID=spawn(genNode_Mailbox,genNode_Mailbox,[ETS_name,My_name]),
			%			%link(MailboxID),
			%			%global:register(self(),My_name),
			%			%register(MailboxID,genNode_Mailbox),
			%			%global:register(MailboxID,My_name),
			%			spawn(recovery_system,recovery_mail,[MailboxID,My_name]),
			%			cell_manager!{init,Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name,My_name},
			%			{ok,{Xmin,Ymin,Xmax,Ymax,ETS_name,My_name,MailboxID}}
			%after 10000 -> exit(self()) %something wrong, exit
			%end.
			%register(general_node,self()),
			spawn(genNode_Mailbox,logger_process_start,[self()]),
			{ok,{My_name,Host_name}}.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Not in use but must be exported/////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
code_change(_,_,_) -> {ok,normal}.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Handlers of type call///////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
handle_call({restart,Data,NewYmin,NewYmax,ActiveHosts},_From,{Xmin,_Ymin,Xmax,_Ymax,ETS_name,My_name,_NodeNameList,MailboxID}) -> 
	%{init,NodeNameList,Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,EnvEnergy,EnvOrganic}
	cell_monitor!{restart},%Ask cells_monitor to delete all cells
	ets:delete(ETS_name),%delete old ets
	New_ETS_name=ets:new(local_table,[named_table,read_concurency,set,public]),
	MailboxID!{restart,New_ETS_name},
	ets_update(Data,New_ETS_name),
	gen_server:call(cell_manager,{restart,NewYmin,NewYmax,New_ETS_name}),%handle call to cell manager to restart
	{reply,{done},{Xmin,NewYmin,Xmax,NewYmax,New_ETS_name,My_name,ActiveHosts,MailboxID}}.%all done
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Handlers of type cast///////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
handle_cast(stop,{Xmin,NewYmin,Xmax,NewYmax,New_ETS_name,My_name,NodeNameList,MailboxID}) -> 
			{stop,normal,{Xmin,NewYmin,Xmax,NewYmax,New_ETS_name,My_name,NodeNameList,MailboxID}}.%termination
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////Handlers of type info///////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%Init %Graphic node must send parameters
handle_info({init,NodeNameList,Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,EnvEnergy,EnvOrganic},{My_name,Host_name}) -> 
			loggerp!"Msg Received",
			ETS_name=ets:new(local_table,[named_table,set,public,{read_concurrency,true}]),
			loggerp!"Ets created",
			%timer:sleep(2000),
			ets_creator(Xmin,Ymin,Xmax,Ymax,ETS_name,EnvEnergy,EnvOrganic,Xmin,Ymin),
			loggerp!"Ets full",
			%timer:sleep(2000),
			cell_manager:start(),
			%loggerp!"Cell manager active",
			%timer:sleep(2000),
			MailboxID=spawn(genNode_Mailbox,genNode_Mailbox,[ETS_name,self(),Host_name]),
			loggerp!"Mailbox spawned",
			%timer:sleep(2000),
			register(genNode_Mailbox,MailboxID),
			loggerp!"Mailbox registered",
			%timer:sleep(2000),
			%spawn(recovery_system,recovery_mail,[MailboxID,My_name]),
			cell_manager!{init,Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,ETS_name,My_name},
			loggerp!"Init cell manager done",
			%timer:sleep(2000),
			loggerp!"General Node Active",
			{noreply,{Xmin,Ymin,Xmax,Ymax,ETS_name,My_name,NodeNameList,MailboxID}};
%%------------------------------------------------------------------------------------------------------------------------------------
%%ask node to send a cell to it
handle_info({moveout,ProcID,X_axis,Y_axis,FromX,FromY,H},{Xmin,Ymin,Xmax,Ymax,ETS_name,My_name,NodeNameList,MailboxID}) -> %H={Cell_type,Energy,Organic,TTL,Cells_created,Wooded}
			%%ETS line [{{X_coordinate,Y_coordinate},{{EnvOrganic,EnvEnergy},{cell_type,energy,organic,TTL,cells_created,wooded}}}]
			NextNodeName=check_next_node(Y_axis,Ymax,My_name,NodeNameList),
			Pid=global:whereis_name(NextNodeName),
			if ((NextNodeName == My_name) or (Pid==undefined))-> ok;
			true -> global:whereis_name(NextNodeName)!{movein,ProcID,My_name,X_axis,Y_axis,FromX,FromY,H}
			end,
			{noreply,{Xmin,Ymin,Xmax,Ymax,ETS_name,My_name,NodeNameList,MailboxID}};
%%------------------------------------------------------------------------------------------------------------------------------------
%%somebody want to send us cell
handle_info({movein,ProcID,NodeName,X_axis,Y_axis,FromX,FromY,H},{Xmin,Ymin,Xmax,Ymax,ETS_name,My_name,NodeNameList,MailboxID}) -> 
			if  Y_axis>Ymax -> NewPos_y=Ymin;
				Y_axis<Ymin -> NewPos_y=Ymax;
			true -> NewPos_y=Y_axis
			end,
			{_,Answer,_,_,_,_}=gen_server:call(cell_manager,{movein,X_axis,NewPos_y,FromX,FromY,H}),
			Pid=global:whereis_name(NodeName),
			if Pid==undefined -> ok;
			true -> global:whereis_name(NodeName)!{answer,Answer,ProcID,X_axis,NewPos_y,FromX,FromY,H}
			end,
			{noreply,{Xmin,Ymin,Xmax,Ymax,ETS_name,My_name,NodeNameList,MailboxID}};
%%------------------------------------------------------------------------------------------------------------------------------------
%%node answer about sending a cell to it
handle_info({answer,Answer,ProcID,X_axis,Y_axis,FromX,FromY,_H},{Xmin,Ymin,Xmax,Ymax,ETS_name,My_name,NodeNameList,MailboxID}) -> 
			cell_manager!{Answer,X_axis,Y_axis,ProcID,FromX,FromY},
			{noreply,{Xmin,Ymin,Xmax,Ymax,ETS_name,My_name,NodeNameList,MailboxID}};
%%------------------------------------------------------------------------------------------------------------------------------------
handle_info({restart,Data,NewYmin,NewYmax,ActiveHosts},{Xmin,_Ymin,Xmax,_Ymax,ETS_name,My_name,_NodeNameList,MailboxID}) -> 
	%{init,NodeNameList,Cells_Amount,{Xmin,Ymin,Xmax,Ymax},Energy,Organic,EnvEnergy,EnvOrganic}
	%io:format("~nTrying to restart cell monitor~n",[]),
	cell_monitor!{restart},%Ask cells_monitor to delete all cells
	%io:format("~nCell monitor off~n",[]),
	ets:delete(ETS_name),%delete old ets
	New_ETS_name=ets:new(local_table,[named_table,{read_concurrency,true},set,public]),
	%io:format("~nNew ets created~n",[]),
	MailboxID!{restart,New_ETS_name},
	%io:format("~nMailbox restarted~n",[]),
	ets_update(Data,New_ETS_name),
	%io:format("~nEts updated~n",[]),
	gen_server:call(cell_manager,{restart,NewYmin,NewYmax,New_ETS_name}),%handle call to cell manager to restart
	%io:format("~nCell manager restarted~n",[]),
	{noreply,{Xmin,NewYmin,Xmax,NewYmax,New_ETS_name,My_name,ActiveHosts,MailboxID}};%all done
%%------------------------------------------------------------------------------------------------------------------------------------
%%used for debugging
handle_info(_Any,Status) -> loggerp!"Unknown msg type",
							{noreply,Status}.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////termination/////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terminate(_Reason, {_,_,_,_,_,My_name,_,_}) -> 
							genNode_Mailbox!{stop},
							gen_server:cast(cell_manager,stop), 
							cell_monitor!{termination},
							global:unregister_name(My_name),
							loggerp!{stop,ok},
							ok.
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%%//////////////////////////////////////////////////////////internal funcs/////////////////////////////////////////////////////////////
%%/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
ets_creator(_Xmin,_Ymin,Xmax,Ymax,_ETS_name,_EnvEnergy,_EnvOrganic,Pos_X,Pos_Y) when ((Pos_X > Xmax) and (Pos_Y > Ymax)) -> ok;
ets_creator(Xmin,Ymin,Xmax,Ymax,ETS_name,EnvEnergy,EnvOrganic,Pos_X,Pos_Y) when (Pos_Y > Ymax) ->
					ets_creator(Xmin,Ymin,Xmax,Ymax,ETS_name,EnvEnergy,EnvOrganic,Pos_X+1,Ymin);
ets_creator(Xmin,Ymin,Xmax,Ymax,ETS_name,EnvEnergy,EnvOrganic,Pos_X,Pos_Y) -> 
					ets:insert(ETS_name,{{Pos_X,Pos_Y},{{EnvEnergy,EnvOrganic},{none,0,0,0,0,0}}}),
					%%ETS line [{{X_coordinate,Y_coordinate},{{EnvOrganic,EnvEnergy},{cell_type,energy,organic,TTL,cells_created,wooded}}}]
					ets_creator(Xmin,Ymin,Xmax,Ymax,ETS_name,EnvEnergy,EnvOrganic,Pos_X,Pos_Y+1).
%%------------------------------------------------------------------------------------------------------------------------------------
ets_update([],_New_ETS_name) -> ok;
ets_update([{{X_axis,Y_axis},H}|T],New_ETS_name) -> 
					ets:insert(New_ETS_name,{{X_axis,Y_axis},H}),
					ets_update(T,New_ETS_name).
%%------------------------------------------------------------------------------------------------------------------------------------
check_next_node(Y_axis,Ymax,My_name,NodeNameList) -> 
			%io:format("~nMy_name=~p~n",[My_name]),
			%io:format("~nNodeNameList=~p~n",[NodeNameList]),
			%io:format("~nY_axis=~p,Ymax=~p~n",[Y_axis,Ymax]),
			Index=find_node(My_name,NodeNameList,1),
			if  (length(NodeNameList)==1) -> My_name;
				((Y_axis>Ymax) and (Index<length(NodeNameList))) ->
					list_member(Index+1,NodeNameList,1);
				(Y_axis>Ymax) -> list_member(1,NodeNameList,1);
				(Index==1) -> list_member(length(NodeNameList),NodeNameList,1);
				true -> list_member(Index-1,NodeNameList,1)
			end.
find_node(My_name,[H|T],Counter) -> 
			if H==My_name -> Counter;
			true -> find_node(My_name,T,Counter+1)
			end.
%%------------------------------------------------------------------------------------------------------------------------------------
list_member(Index,[H|_],Counter) when Index==Counter -> H;
list_member(Index,[_|T],Counter) -> list_member(Index,T,Counter+1).
