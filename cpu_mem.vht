-- Copyright (C) 1991-2013 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- ***************************************************************************
-- This file contains a Vhdl test bench template that is freely editable to   
-- suit user's needs .Comments are provided in each section to help the user  
-- fill out necessary details.                                                
-- ***************************************************************************
-- Generated on "05/12/2016 15:43:26"
                                                            
-- Vhdl Test Bench template for design  :  cpu_mem
-- 
-- Simulation tool : ModelSim-Altera (VHDL)
-- 

LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY cpu_mem_vhd_tst IS
END cpu_mem_vhd_tst;
ARCHITECTURE cpu_mem_arch OF cpu_mem_vhd_tst IS
-- constants                                                 
-- signals                                                   
SIGNAL clk : STD_LOGIC;
SIGNAL reset : STD_LOGIC;
signal stop: std_LOGIC;

COMPONENT cpu_mem
	PORT (
	clk : IN STD_LOGIC;
	reset : IN STD_LOGIC;
	stop: out std_LOGIC
	);
END COMPONENT;
BEGIN
	i1 : cpu_mem
	PORT MAP (
-- list connections between master ports and signals
	clk => clk,
	reset => reset,
	stop=>stop 
	);
	

	
PROCESS 
variable clock_next:std_logic :='0';     
variable reset_next:std_logic :='1';
                                                              
BEGIN                                                        
loop
if(stop='1') then clk<='1'; wait;
else 
reset<=reset_next;
reset_next:='0';
clk<=clock_next;
wait for 5 ns;
clock_next:= not clock_next;
end if;
end loop;                                                                           
END PROCESS;                                           

                                           
END cpu_mem_arch;
