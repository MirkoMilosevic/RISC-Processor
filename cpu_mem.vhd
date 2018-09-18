library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;


entity cpu_mem is

port(
clk : in std_logic;
reset : in std_logic;
stop : out std_logic

);	

end cpu_mem;



architecture rtl of cpu_mem is
signal if_instrm : word_t;
signal id_in_dataout : word_t;
signal instr_addr:word_t;


signal rd:std_logic;
signal wr:std_logic;
signal dest_addr_ex_dm:word_t;
signal data_mem_dm: word_t;
signal data_dm_mem: word_t;

begin

cpu:entity work.cpu
port map(

clk =>clk,
reset=>reset,
first_pc => if_instrm,
dataout_im => id_in_dataout, 
address_im=> instr_addr,

rd=>rd,
wr=>wr,
address_dm=>dest_addr_ex_dm,
datain=>data_mem_dm,
dataout_dm => data_dm_mem,
stop=> stop
);


instr_mem:entity work.instr_mem
		port map(
			first_pc => if_instrm,
		   dataout => id_in_dataout, 
			address=> instr_addr
		
		);
		
		
		data_mem:entity work.data_mem
		port map(
		rd=>rd,
		wr=>wr,
		address=>dest_addr_ex_dm,
		datain=>data_mem_dm,
		dataout => data_dm_mem,
		reset=>reset,
		clk=>clk
		);

		
		
		
		
end rtl;
