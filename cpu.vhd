library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;


entity cpu is
	port (
		clk : in std_logic;
		reset : in std_logic;
		
		rd : out std_logic;
		wr : out std_logic;
		address_dm : out word_t;
		datain: out word_t;
		dataout_dm : in word_t;
		
		first_pc : in word_t;
		dataout_im: in word_t; 
	   address_im: out word_t;
		
		stop: out std_logic
		
	);
end entity cpu;

architecture RTL of cpu is
	
	signal if_id_msg:stage_msg_t;
	signal rs1_addr: reg_index;
	signal rs2_addr: reg_index;
	signal operand1_in: word_t;
	signal operand2_in: word_t;
	signal if_wb_msg : stage_msg_t;
	signal id_ex_msg: stage_msg_t;
	signal ex_mem_msg: stage_msg_t;
	signal mem_wb_msg:stage_msg_t;
	signal ctrl: control_t;
	signal operand1_out: word_t;
	signal operand2_out:word_t;
	signal dest_addr:word_t;
	signal address_mem_dm:word_t;
	signal regd_en: std_logic;
	signal regd_addr_mem_rf:reg_index;
	signal regd_addr_id_ex:reg_index;
	signal regd_addr_ex_mem:reg_index;
	signal regd: word_t;
	signal instruction_is_load: std_logic;
	signal instruction_is_store: std_logic;
   signal write_in_rd_ex_mem: std_logic;
	signal write_in_rd_mem_wb: std_logic;
	signal result_ex_mem:word_t;
	signal data_mem_wb:word_t;--MOZDA GRESKA!!!
	
	signal write_in_bp: std_logic;
	signal mispred:std_logic;
	signal branch_addr: word_t;
	signal BrP_tag_in: word_t;
	
	signal if_id_jmp_msg: jump_pred_msg;
	signal id_ex_jmp_msg: jump_pred_msg;
	signal ex_mem_jmp_msg: jump_pred_msg;
	signal mem_wb_jmp_msg: jump_pred_msg;
	signal wb_bp_jmp_msg: jump_pred_msg;
	
	
	signal use_rs1: std_logic;
	signal use_rs2: std_logic;
	
	signal rd_ex_control_unit: reg_index;
	signal rd_en_ex: std_logic;
	signal is_ready:std_logic;
	signal data_ex_control_unit: word_t;
	
	signal rd_mem_control_unit: reg_index;
	signal rd_en_mem: std_logic;
	signal data_mem_control_unit: word_t;
	
	signal rd_wb_control_unit: reg_index;
	signal rd_en_wb: std_logic;
	signal data_wb_control_unit: word_t;
	
	signal stall: std_logic;
	signal data_control_unit_out1: word_t;
	signal data_control_unit_out2: word_t;
	signal rs1_found: std_logic;
	signal rs2_found: std_logic;
	
	signal rd_addr_mem_wb: reg_index;
	
	
	signal stop_ex_mem: std_logic;
	signal stop_mem_wb: std_logic;

	
	begin
	if_stage:entity work.if_stage
		port map(
			clk => clk,
			reset => reset,
			mispred =>mispred,
			branch_addr => branch_addr,
			if_msg => if_id_msg,
			if_in => first_pc,
			if_msg_in=>if_wb_msg,
			if_id_jmp_msg=>if_id_jmp_msg,
			pc=>BrP_tag_in,
			
			stall=>stall
		);
		id_stage:entity work.id_stage
		port map(
			reset=>reset,
			clk => clk,
			msg_id_in => if_id_msg,
			msg_id=>id_ex_msg,
			ctrl_out => ctrl,
			id_in => dataout_im,  
			rs1_addr=> rs1_addr,
			rs2_addr=> rs2_addr,
			rd_addr_id => regd_addr_id_ex,
			operand1_in=> operand1_in,
			operand2_in=> operand2_in,
			operand1_out=> operand1_out,
			operand2_out=> operand2_out,
			instr_addr=>address_im,
			dest_addr=>dest_addr,
			if_id_jmp_msg=>if_id_jmp_msg,
			id_ex_jmp_msg=>id_ex_jmp_msg,
			use_rs1=>use_rs1,
		   use_rs2=>use_rs2,
			
			stall=>stall
		);
		

		
		
	registarski_fajl:entity work.registarski_fajl --Mirko je ovo imenovao
	port map(
		clk => clk,
		reset => reset,
		regs1_addr=> rs1_addr,
		regs2_addr=> rs2_addr,
		regs1=> operand1_in,
		regs2=> operand2_in,
		regd_en=> regd_en,
		regd_addr=> regd_addr_mem_rf,
		regd=> regd
		);
		
		ex_stage: entity work.ex_stage
		port map(
		msg_ex_in => id_ex_msg,
		msg_ex_out => ex_mem_msg,
		ctrl_in =>ctrl,
		clk => clk,
		reset => reset,
		instruction_is_load=> instruction_is_load,
		instruction_is_store=> instruction_is_store,
		write_in_rd=> write_in_rd_ex_mem,
		operand1=>operand1_out,
		operand2=>operand2_out,
		dest_address_in => dest_addr,
		dest_address_out => address_dm,
		rd_addr_ex_in => regd_addr_id_ex,
		rd_addr_ex_out => regd_addr_ex_mem,
		result => result_ex_mem,
		id_ex_jmp_msg=>id_ex_jmp_msg,
		ex_mem_jmp_msg=>ex_mem_jmp_msg,
		
		rd_ex_control_unit=>rd_ex_control_unit,
		rd_en_ex =>rd_en_ex,
		is_ready => is_ready,
		data_ex_control_unit =>data_ex_control_unit,
		
		
		stall=>stall,
		data_control_unit_in1=>data_control_unit_out1,
		data_control_unit_in2=>data_control_unit_out2,
		rs1_found=>rs1_found,
		rs2_found=>rs2_found,
		
		stop_ex_out=>stop_ex_mem
		
		);
		
		
		mem_stage: entity work.mem_stage
		port map(
		clk=>clk,
		reset=>reset,
		rd=>rd,
		wr=>wr,
		instruction_is_load=> instruction_is_load,
		instruction_is_store=> instruction_is_store,
		write_in_rd_in=>write_in_rd_ex_mem,
		write_in_rd_out=>write_in_rd_mem_wb,
		
		
		rd_addr_mem_in => regd_addr_ex_mem,
		rd_addr_mem_out => regd_addr_mem_rf,
		data_mem_wb=>data_mem_wb,
		data_mem_dm =>datain,
		data_in_ex=>result_ex_mem,
		data_in_dm=>dataout_dm,
		
		
		msg_mem_in=> ex_mem_msg,
		msg_mem_out=>mem_wb_msg,
		ex_mem_jmp_msg=>ex_mem_jmp_msg,
		mem_wb_jmp_msg=>mem_wb_jmp_msg,
		
		
		rd_mem_control_unit => rd_mem_control_unit,
		rd_en_mem => rd_en_mem,
		data_mem_control_unit=> data_mem_control_unit,
		
		
		rd_addr_mem_wb=>rd_addr_mem_wb,
		
		stop_mem_in=>stop_ex_mem,
		stop_mem_out=>stop_mem_wb
		);
		

		
		wb_stage:entity work.wb_stage
		port map(
		--clk=>clk,
		--reset=>reset,
		write_in_rd=>write_in_rd_mem_wb,
		
		msg_wb_in=>mem_wb_msg,
		msg_wb_out=>if_wb_msg,
		
		data_in=>data_mem_wb,
		data_out=>regd,
		
		rd_en=>regd_en,
		
		write_in_bp=>write_in_bp,
		
		mem_wb_jmp_msg=>mem_wb_jmp_msg,
		wb_bp_jmp_msg=>wb_bp_jmp_msg,
		
		rd_wb_control_unit => rd_wb_control_unit,
		rd_en_wb => rd_en_wb,
		data_wb_control_unit => data_wb_control_unit,
		
		rd_addr_mem_wb=>rd_addr_mem_wb,
		
		
		stop_wb_in=>stop_mem_wb,
		stop=> stop
		
		);
		
		
		
		Branch_pred:entity work.Branch_pred
		port map(
		clk => clk,
		reset => reset,
		wr=> write_in_bp,
		BrP_tag_in =>BrP_tag_in,
		BrP_pred_out=>branch_addr,
		mispred=>mispred,
		wb_bp_jmp_msg=>wb_bp_jmp_msg
		
		);
		
		
		control_unit:entity work.control_unit
		
		port map(
		reset=>reset,
		clk=>clk,
		rs1_id_control_unit=>rs1_addr, 
		rs2_id_control_unit=>rs2_addr,
		
		use_rs1=>use_rs1,
		use_rs2=>use_rs2,	
		
		rd_ex_control_unit=>rd_ex_control_unit,
		rd_en_ex =>rd_en_ex,
		is_ready => is_ready,
		data_ex_control_unit =>data_ex_control_unit,
		
		rd_mem_control_unit => rd_mem_control_unit,
		rd_en_mem => rd_en_mem,
		data_mem_control_unit=> data_mem_control_unit,
		
		rd_wb_control_unit => rd_wb_control_unit,
		rd_en_wb => rd_en_wb,
		data_wb_control_unit => data_wb_control_unit,
		
		stall=>stall,
		data_control_unit_out1=>data_control_unit_out1,
		data_control_unit_out2=>data_control_unit_out2,
		rs1_found=>rs1_found,
		rs2_found=>rs2_found
		
		
		
		);
		

end architecture RTL;
