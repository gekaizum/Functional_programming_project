#!/bin/bash

ssh csestudent@132.72.81.60
	cd Desktop/Shaked_yevgeniy/
	erl -setcookie skey -name node4@132.72.81.60
	c(graphic_node).
	c(main_logger).
	c(general_node).
	c(genNode_Mailbox).
	c(cell_manager).
	c(cell_funcs).
	c(general_cell_funcs).
	exit

ssh csestudent@132.72.81.60
	cd Desktop/Shaked_yevgeniy/
	erl -setcookie skey -name node3@132.72.81.167
	c(graphic_node).
	c(main_logger).
	c(general_node).
	c(genNode_Mailbox).
	c(cell_manager).
	c(cell_funcs).
	c(general_cell_funcs).
	exit

ssh csestudent@132.72.81.60
	cd Desktop/Shaked_yevgeniy/
	erl -setcookie skey -name node2@132.72.81.224
	c(graphic_node).
	c(main_logger).
	c(general_node).
	c(genNode_Mailbox).
	c(cell_manager).
	c(cell_funcs).
	c(general_cell_funcs).
	exit

ssh csestudent@132.72.81.60 
	cd Desktop/Shaked_yevgeniy/
	erl -setcookie skey -name node1@132.72.80.185
	c(graphic_node).
	c(main_logger).
	c(general_node).
	c(genNode_Mailbox).
	c(cell_manager).
	c(cell_funcs).
	c(general_cell_funcs).
	exit

erl -setcookie skey -name graphic_node@132.72.81.85
c(graphic_node).
c(main_logger).
c(general_node).
c(genNode_Mailbox).
c(cell_manager).
c(cell_funcs).
c(general_cell_funcs).
c(n_gui).
n_gui:start().
