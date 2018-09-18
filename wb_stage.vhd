library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity wb_stage is
	port
	(
		write_in_rd: in std_logic;
		write_in_bp: out std_logic;
		
		msg_wb_in: in stage_msg_t;
		msg_wb_out: out stage_msg_t;
		
		data_in: in word_t; --podatak primljen iz mem faze
		data_out: out word_t; --podatak koji se salje registarskom fajlu za upis
		
		rd_en: out std_logic; -- kontrolni za upis u reg fajl
		
		mem_wb_jmp_msg: in jump_pred_msg;
		wb_bp_jmp_msg: out jump_pred_msg;
		
		--signali koji komuniciraju sa control unit-om
		rd_addr_mem_wb: in reg_index;
		rd_wb_control_unit: out reg_index;
		rd_en_wb: out std_logic;
		data_wb_control_unit: out word_t;
		
		stop_wb_in: in std_logic;
		stop:  out std_logic		
	);
end wb_stage;

architecture rtl of wb_stage is 

begin

process(msg_wb_in, write_in_rd, data_in, mem_wb_jmp_msg)

begin 
write_in_bp<='0';
rd_en<='0'; --kontrolni za reg fajl
msg_wb_out<=msg_wb_in;
rd_en_wb<='0'; --kontrolni za control unit
if(write_in_rd='1') then
rd_en<='1';
rd_en_wb<='1';
end if;

--ako je instrukcija skok, azurira se branch prediktor
if(mem_wb_jmp_msg.jump='1')then
write_in_bp<='1';
end if;
end process;

data_out<=data_in;
wb_bp_jmp_msg<=mem_wb_jmp_msg;
rd_wb_control_unit<=rd_addr_mem_wb;
data_wb_control_unit<=data_in;
stop<=stop_wb_in;
end rtl;
