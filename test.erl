-module(test).
-export([start/0]).
-export([handle_sync_event/2]).
-include_lib("wx/include/wx.hrl").

-author("Shaked Basa").


start() ->


	wx:new(),
	Frame = wxFrame:new(wx:null(), 1, "TEST", [{size,{1000,1000}}]),
	Panel = wxPanel:new(Frame, [{size,{1000,1000}}]),
  	%DC = wxPaintDC:new(Panel),
  	%Paint = wxBufferedPaintDC:new(Panel),
  	
  	% Load and scale the cells and heatmap images from files
	General = wxImage:new("general.png"),
	Generalc = wxImage:scale(General,40,40),
    	BmpGeneral = wxBitmap:new(Generalc),
  	wxImage:destroy(General),
  	wxImage:destroy(Generalc),
  	
  	
  	wxFrame:show(Frame),
  

  	% connect panel
	wxPanel:connect(Panel, paint, [{callback, fun handle_sync_event/2}, {userData, #{panel => Panel, bmpgeneral => BmpGeneral}}]),
	wxWindow:destroyChildren(Panel),
  	refresh_frame(Frame).
  
  
refresh_frame(Frame) ->
	wxWindow:refresh(Frame), 
	timer:sleep(300),
	refresh_frame(Frame).
 
 handle_sync_event(#wx{event=#wxPaint{}, userData = #{ panel := Panel, bmpgeneral := BmpGeneral}}, _Event) ->
 	
	DC2 = wxPaintDC:new(Panel),
	wxDC:clear(DC2),
	%wxDC:drawBitmap(DC2, BmpGeneral, {100,100}),
	print_cells(Panel,BmpGeneral).
  
  
 print_cells(Panel,BmpGeneral) ->
 	DI = wxClientDC:new(Panel),	
  	wxDC:drawBitmap(DI, BmpGeneral, {100, 100}).
  
  
  
  
  

  
  
  
  
  
  
  
  
  	
  	
  
