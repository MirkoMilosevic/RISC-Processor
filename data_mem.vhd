library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.cpu_pkg.all;


entity data_mem is

port
	(		
			rd: in std_logic;
			wr: in std_logic;
			address: in word_t; --adresa sa koje se cita ili na koju se upisuje podatak
			datain: in word_t; --podatak koji se upisuje
			dataout : out word_t; --procitani podatak
			reset: in std_logic;
			clk : in std_logic
				
	);
end data_mem;


architecture rtl of data_mem is

type line_data_mem is record  
	 d_m_address: word_t;
	 d_m_data:  word_t;
end record;

constant DATA_MEM_SIZE : integer :=  2**7;

constant filename: string := "data_mem.txt";

type storage_array is
    array (natural range 0 to DATA_MEM_SIZE - 1) of line_data_mem;

	 
signal storage_reg : storage_array;
signal storage_next: storage_array;

--indeks do koga je popunjena data memorija
signal storage_size_reg : natural;
signal storage_size_next : natural;

begin

process(reset, clk)

file f : text;
variable l: line;
variable i: integer;
variable storage_size_temp:natural:=0;
variable adr_temp : word_t;
variable data_temp : word_t;

begin

--na reset ucitavamo dati fajl
if(reset= '1') then
	file_open(f,filename,READ_MODE); 
	storage_size_temp:=0;
	for i in 0 to DATA_MEM_SIZE - 1 loop
	if (endfile(f)) then exit; 
	end if;
	readline(f, l);
	hread(l, adr_temp);
	read(l, data_temp);
	storage_size_temp:=storage_size_temp + 1;
	storage_reg(i).d_m_address<=adr_temp;
	storage_reg(i).d_m_data<=data_temp;
	end loop;
	file_close(f);
	storage_size_reg<=storage_size_temp;
	elsif(rising_edge(clk)) then
	storage_reg<=storage_next;
	storage_size_reg<=storage_size_next;
end if;

end process;

process(address, storage_reg, rd, wr, datain, storage_size_reg)

file f : text;
variable l: line;
variable j: integer;
variable k: integer;
variable m: integer;
variable adr_temp : word_t;
variable data_temp : word_t;
--pomocna promenljiva koja sluzi da prekine pretragu cele data memorije ako se podatak nadje ranije
variable found: std_logic:='0';

begin

--da ne bi poslala nulu pa se stavlja high Z
dataout <= (dataout'range => 'Z');
storage_next<=storage_reg;
storage_size_next<=storage_size_reg;

--citanje iz data memorije, trazi se podatak sa zadate adrese
if (rd='1') then		
for j in 0 to DATA_MEM_SIZE -1 loop
if (j>(storage_size_reg-1)) then exit;
end if;
if(storage_reg(j).d_m_address=address) then
dataout<=storage_reg(j).d_m_data;
end if;
end loop;
end if;

--upis u data momoriju
if(wr='1') then 
found:='0';
for k in 0 to DATA_MEM_SIZE-1 loop
if (k>(storage_size_reg-1)) then exit;
end if;

--Ako zadata adresa vec postoji u data memoriji samo se azurira
if(storage_reg(k).d_m_address=address) then
storage_next(k).d_m_data<=datain;
found:='1';
exit;
end if;
end loop;

--ako ne postoji zadata adresa, dodaje se novi red u data memoriju
if(found='0' and storage_size_reg< (DATA_MEM_SIZE - 1)) then
storage_size_next<=storage_size_reg+1;
storage_next(storage_size_reg).d_m_data<=datain;
storage_next(storage_size_reg).d_m_address<=address;
end if;

--azurira se fajl posle svakog upisa
file_open(f,filename,WRITE_MODE); 
for m in 0 to DATA_MEM_SIZE - 1 loop
if (m>(storage_size_reg-1)) then exit;
end if;
--promenljive koje uzimaju vrednost svakog reda i upisuju se u tekstualni fajl
adr_temp:=storage_reg(m).d_m_address;
data_temp:=storage_reg(m).d_m_data;
hwrite(l, adr_temp);
write(l, ' ');
write(l, data_temp);
writeline(f, l);
end loop;
file_close(f);

end if;

end process;

end rtl;
