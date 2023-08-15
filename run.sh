#!/bin/bash

ssh -T csestudent@132.72.81.60 << EOF
	cd Desktop/Shaked_yevgeniy/ 
	erl -setcookie skey -name node4@132.72.81.60
	c(graphic_node).
	c(main_logger).
	c(general_node).
	c(genNode_Mailbox).
	c(cell_manager).
	c(cell_funcs).
	c(general_cell_funcs).
EOF
ssh -T csestudent@132.72.81.167 << EOF
	cd Desktop/Shaked_yevgeniy/
	erl -setcookie skey -name node3@132.72.81.167
	c(graphic_node).
	c(main_logger).
	c(general_node).
	c(genNode_Mailbox).
	c(cell_manager).
	c(cell_funcs).
	c(general_cell_funcs).
EOF
ssh -T csestudent@132.72.81.224 << EOF
	cd Desktop/Shaked_yevgeniy/
	erl -setcookie skey -name node2@132.72.81.224
	c(graphic_node).
	c(main_logger).
	c(general_node).
	c(genNode_Mailbox).
	c(cell_manager).
	c(cell_funcs).
	c(general_cell_funcs).
EOF
ssh -T csestudent@132.72.80.185 << EOF
	cd Desktop/Shaked_yevgeniy/
	erl -setcookie skey -name node1@132.72.80.185
	c(graphic_node).
	c(main_logger).
	c(general_node).
	c(genNode_Mailbox).
	c(cell_manager).
	c(cell_funcs).
	c(general_cell_funcs).
EOF
erl -setcookie skey -name graphic_node@132.72.81.85 << EOF
c(graphic_node).
c(main_logger).
c(general_node).
c(genNode_Mailbox).
c(cell_manager).
c(cell_funcs).
c(general_cell_funcs).
c(n_gui).
n_gui:start().
EOF
