library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cpu_pkg is

constant WORD_SIZE : integer := 32;
constant CACHE_SIZE: integer :=16; --velicina prediktora
constant REG_NUMBER: integer := 32; --velicina reg fajla
constant OP_SIZE: integer :=3;
constant IMM_SIZE: integer :=11;
constant REG_SIZE : integer := 5;

subtype 	word_t is std_logic_vector(WORD_SIZE - 1 downto 0);
subtype 	reg_index is std_logic_vector(REG_SIZE - 1 downto 0);

--jedan red u branch prediktoru
type BrP_set is record
Tag : word_t; --adresa na kojoj se nalazi instr skoka, po ovom podatku se pretrazuje prediktor
PC_pred : word_t; --predikcija skoka za datu adresu
State : integer range 0 to 3; --stanje koje odredjuje "jacinu" skoka
end record; 

--podaci koji se prenose kroz pipeline za instrukcije skoka
type jump_pred_msg is record
pc: word_t; --vrednost na kojoj se nasla instr skoka 
pc_next_pred: word_t; --predikcija skoka
jump: std_logic; --pomocni bit koji je 1 samo kada je instrukcija skok
state_change: std_logic; --odredjuje kako se azurira prediktor
overF : std_logic; --pomocni bit za prekoracenje, kod uslovnih skokova adresu racunamo u id, a stop u ex
unconditional: std_logic;--da li je bezuslovan skok
end record;

--pomocni tip da se rec iz instr mem izdeli
type instruction_t is record
opcode1 : std_logic_vector(OP_SIZE-1 downto 0);
opcode2 : std_logic_vector(OP_SIZE-1 downto 0);
rd : std_logic_vector(REG_SIZE-1 downto 0);
rs1 : std_logic_vector(REG_SIZE-1 downto 0);
rs2 : std_logic_vector(REG_SIZE-1 downto 0);
imm: std_logic_vector(IMM_SIZE-1 downto 0);
end record;

--pomocni tip koji govori koja je instr u pitanju
type control_t is record
load_o: std_logic;
store_o: std_logic;
mov_o: std_logic;
movi_o: std_logic;
add_o: std_logic;
sub_o: std_logic;
addi_o: std_logic;
subi_o: std_logic;
and_o: std_logic;
xor_o: std_logic;
not_o: std_logic;
or_o: std_logic;
shl_o: std_logic;
shr_o: std_logic;
sar_o: std_logic;
rol_o: std_logic;
ror_o: std_logic;
jmp_o: std_logic;
jsr_o: std_logic;
rts_o: std_logic;
push_o: std_logic;
pop_o: std_logic;
beq_o: std_logic;
bnq_o: std_logic;
bgt_o: std_logic;
blt_o: std_logic;
bge_o: std_logic;
ble_o: std_logic;
halt_o: std_logic;
x: std_logic;  -- greska, op kod ne postoji
end record;

type stage_msg_t is record
pc: word_t; --trenutna vrednost pc
pc_next: word_t; --trenutna vrednost pc next-a
flush:std_logic;
instruction_is_jump: std_logic;
end record;

end package cpu_pkg;