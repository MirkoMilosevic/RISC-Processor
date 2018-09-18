library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity mem_stage is


	port
	(
	
		clk: in std_logic;
		reset: in std_logic;
		rd: out std_logic;
		wr: out std_logic;
		instruction_is_load: in std_logic;
		instruction_is_store: in std_logic;
		write_in_rd_in: in std_logic;
		write_in_rd_out: out std_logic;
	
		data_mem_wb: out word_t;
		data_in_ex: in word_t;
		data_in_dm: in word_t;
		data_mem_dm: out word_t;
		
		rd_addr_mem_in: in reg_index;
		rd_addr_mem_out: out reg_index;
		
		msg_mem_in: in stage_msg_t;
		msg_mem_out: out stage_msg_t;
		
		ex_mem_jmp_msg: in jump_pred_msg;
		mem_wb_jmp_msg: out jump_pred_msg;
		
		rd_mem_control_unit: out reg_index;
		rd_en_mem: out std_logic;
		data_mem_control_unit: out word_t;
		
		rd_addr_mem_wb: out reg_index;
		
		stop_mem_in: in std_logic;
		stop_mem_out: out std_logic
		
	);
end mem_stage;

architecture rtl of mem_stage is
signal  data_mem_wb_reg: word_t;
signal  data_mem_wb_next: word_t;
signal write_in_rd_out_reg: std_logic;
signal write_in_rd_out_next: std_logic;
signal rd_addr_mem_out_next: reg_index;
signal rd_addr_mem_out_reg:  reg_index;
signal mem_wb_jmp_msg_reg: jump_pred_msg;
signal mem_wb_jmp_msg_next: jump_pred_msg;
signal stop_mem_out_reg: std_logic;
signal stop_mem_out_next: std_logic;
				
begin
process(clk, reset)
begin
if(reset='1') then
data_mem_wb_reg<=(others=>'0');
write_in_rd_out_reg<='0';
rd_addr_mem_out_reg<=(others=>'0');
mem_wb_jmp_msg_reg.pc<=(others=>'0');
mem_wb_jmp_msg_reg.pc_next_pred<=(others=>'0');
mem_wb_jmp_msg_reg.jump<='0';
mem_wb_jmp_msg_reg.state_change<='0';
mem_wb_jmp_msg_reg.unconditional<='0';
stop_mem_out_reg<='0';

elsif(rising_edge(clk)) then
data_mem_wb_reg<=data_mem_wb_next;
rd_addr_mem_out_reg<=rd_addr_mem_out_next;
write_in_rd_out_reg<=write_in_rd_out_next;
mem_wb_jmp_msg_reg<=mem_wb_jmp_msg_next;
stop_mem_out_reg<=stop_mem_out_next;
end if;
end process;

process(stop_mem_in, ex_mem_jmp_msg, mem_wb_jmp_msg_reg,write_in_rd_in, rd_addr_mem_out_reg, rd_addr_mem_in, write_in_rd_out_reg, data_mem_wb_reg, instruction_is_store, msg_mem_in, instruction_is_load, data_in_ex, data_in_dm)
begin

--index rd pamtimo kao registar u svakoj fazi da bi pratio svoju instrukciju
wr<='0';
rd<='0';
rd_addr_mem_out_next<=rd_addr_mem_in;
write_in_rd_out_next<=write_in_rd_in;
data_mem_wb_next<=data_mem_wb_reg;
msg_mem_out<=msg_mem_in;
rd_mem_control_unit<=rd_addr_mem_in;
mem_wb_jmp_msg_next<=ex_mem_jmp_msg;
rd_en_mem<='0';
data_mem_control_unit<=(others=>'0');
stop_mem_out_next<=stop_mem_in;

--ako je instr store pali se wr koji signalizira da se vrsi upis u data mem
if(instruction_is_store='1') then
wr<='1';

--ako je instr load pali se rd koji signalizira da se vrsi citanje iz data mem
elsif(instruction_is_load='1') then
rd<='1';
data_mem_wb_next<=data_in_dm; --vrednost procitana iz data mem-a se salje wb
rd_en_mem<='1'; --kontrolni signal za control unit
data_mem_control_unit<=data_in_dm;--podatak koji se salje u control unit

--u slucaju da su druge instr koje upisuju u reg fajl, wb se salje vrednost iz ex faze
elsif(write_in_rd_in='1') then
data_mem_wb_next<=data_in_ex;
rd_en_mem<='1';
data_mem_control_unit<=data_in_ex;

end if;

end process;

data_mem_wb<=data_mem_wb_reg;
write_in_rd_out<=write_in_rd_out_reg;
data_mem_dm<=data_in_ex;
rd_addr_mem_out<=rd_addr_mem_out_reg;
mem_wb_jmp_msg<=mem_wb_jmp_msg_reg;
rd_addr_mem_wb<=rd_addr_mem_out_reg;
stop_mem_out<=stop_mem_out_reg;

end rtl;

