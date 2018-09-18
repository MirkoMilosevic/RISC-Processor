library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;


	entity control_unit is

	port
	(	
		reset: std_logic;
		clk: std_logic;
		
		--signali koje salje id
		rs1_id_control_unit: in reg_index;
		rs2_id_control_unit: in reg_index;
		use_rs1: in std_logic;
		use_rs2: in std_logic;	
		
		--signali koje salje ex
		rd_ex_control_unit: in reg_index;
		rd_en_ex: in std_logic;
		is_ready: in std_logic;
		data_ex_control_unit: in word_t;
		
		--signali koje salje mem
		rd_mem_control_unit: in reg_index;
		rd_en_mem: in std_logic;
		data_mem_control_unit: in word_t;
		
		--signali koje salje wb
		rd_wb_control_unit: in reg_index;
		rd_en_wb: in std_logic;
		data_wb_control_unit: in word_t;
		
		stall: out std_logic;
		
		--signali koji se salju ex fazi
		data_control_unit_out1: out word_t;
		data_control_unit_out2: out word_t;
		rs1_found: out std_logic;
		rs2_found: out std_logic
		
	);
end control_unit;



architecture rtl of control_unit is
signal 	data_control_unit_out1_reg: word_t;
signal	data_control_unit_out2_reg: word_t;
signal	rs1_found_reg: std_logic;
signal	rs2_found_reg: std_logic;
signal 	data_control_unit_out1_next: word_t;
signal	data_control_unit_out2_next: word_t;
signal	rs1_found_next: std_logic;
signal	rs2_found_next: std_logic;
signal stall_reg: std_logic;
signal stall_next:std_logic;

begin
process(clk, reset)
begin
if(reset='1') then
data_control_unit_out1_reg<=(others=>'0');
data_control_unit_out2_reg<=(others=>'0');
rs1_found_reg<='0';
rs2_found_reg<='0';
stall_reg<='0';

elsif(rising_edge(clk)) then

data_control_unit_out1_reg<=data_control_unit_out1_next;
data_control_unit_out2_reg<=data_control_unit_out2_next;
rs1_found_reg<=rs1_found_next;
rs2_found_reg<=rs2_found_next;
stall_reg<=stall_next;
end if;
end process;


process(data_control_unit_out2_reg, use_rs2,rs2_id_control_unit, data_control_unit_out1_reg, use_rs1, rs1_id_control_unit, rd_ex_control_unit, rd_en_ex, is_ready, data_ex_control_unit, rd_mem_control_unit, rd_en_mem, data_mem_control_unit, rd_wb_control_unit, rd_en_wb, data_wb_control_unit)
begin
stall_next<='0';
rs1_found_next<='0';
data_control_unit_out1_next<=data_control_unit_out1_reg;
rs2_found_next<='0';
data_control_unit_out2_next<=data_control_unit_out2_reg;

--instrukcija koja je u id fazi koristi rs1
if(use_rs1='1') then

   --ispituju se redom ex,mem i wb koja od njih upisuje u trazeni registar
	--ako se pronadje vrednost registra se prosledjuje ex fazi
	if(rs1_id_control_unit=rd_ex_control_unit and rd_en_ex='1') then
	
	--ako podatak nije spreman, generise se stall(instr je load)
	if(is_ready='1') then data_control_unit_out1_next<=data_ex_control_unit; rs1_found_next<='1';
	else stall_next<='1';
	end if;
	--mem
	elsif( rs1_id_control_unit=rd_mem_control_unit and rd_en_mem='1') then
	data_control_unit_out1_next<=data_mem_control_unit;
	rs1_found_next<='1';
	--wb
	elsif( rs1_id_control_unit=rd_wb_control_unit and rd_en_wb='1') then
	data_control_unit_out1_next<=data_wb_control_unit;
	rs1_found_next<='1';
	end if;
end if;

if(use_rs2='1') then
	if(rs2_id_control_unit=rd_ex_control_unit and rd_en_ex='1') then
	if(is_ready='1') then data_control_unit_out2_next<=data_ex_control_unit; rs2_found_next<='1';
	else stall_next<='1';
	end if;
	elsif( rs2_id_control_unit=rd_mem_control_unit and rd_en_mem='1') then
	data_control_unit_out2_next<=data_mem_control_unit;
	rs2_found_next<='1';
	elsif( rs2_id_control_unit=rd_wb_control_unit and rd_en_wb='1') then
	data_control_unit_out2_next<=data_wb_control_unit;
	rs2_found_next<='1';
	end if;
end if;

end process;

rs1_found<=rs1_found_reg;
data_control_unit_out1<=data_control_unit_out1_reg;
rs2_found<=rs2_found_reg;
data_control_unit_out2<=data_control_unit_out2_reg;
stall<=stall_reg;

end rtl;