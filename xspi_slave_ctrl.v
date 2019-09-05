


module xspi_slave_ctrl(	cs,
						ck,
						reset,
						io_in,
						io_out,
						ds_in,
						ds_out,
						
						rd_enable,
						wr_enable,
																		
						sdr_en,
						ddr_1_en,
						ddr_2_en,
												
						write_enable,
						dq_in,
						dq_out,
						addr
						
						
						);
						
						


input cs;
input ck;
input reset;
input [15:0]io_in;
input ds_in;
input [15:0]dq_in;
output [15:0]dq_out;

output wr_enable;
output rd_enable; 
output [15:0] io_out;

output  ds_out;
output  write_enable;
output [31:0]addr;
output reg sdr_en;
output reg ddr_1_en;
output reg ddr_2_en;

reg[7:0]command_code;
reg[7:0]comm_ext_reg;
reg[47:0]comm_addr_reg;
reg[5:0]latency_reg;
wire switch_mode;



parameter 	IDLE=3'd0,
			COMMAND=3'd1,
			//COMMAND_EXT=3'd2,
			COMMAND_ADDR=3'd3,
			LATENCY_CNT=3'd4,
			READ_DATA=3'd5,
			WRITE_DATA=3'd6;

reg [8:0] data_cnt;
reg [3:0] addr_cnt;
reg [5:0] latency_count;
reg [2:0] address_modifier_byte; 
reg [4:0] latency_cycle_byte; 
reg [7:0] data_cnt_byte; 
reg comm_ext_en; 
wire [15:0] rd_data;
reg [3:0] bit_count;
reg [2:0]ps;
reg [2:0]ns;
reg[7:0]sdr_count;

reg ck_q;
reg ck_2q;
reg [7:0]addr_count;

reg [7:0] sfdp_hdr_reg [0:255];//Sfdp header register
reg [7:0] sccr_reg [256:511];//Status control configuration register
reg [31:0] maxvy_reg [512:767];//Maxvy register
reg [7:0] reg_space [1024:8191];//register space

reg wren1;
reg wren2;
reg ck_ref;
reg e_def_p_mode;
reg sfdp_active;
reg stat_reg_enable;

wire [15:0] data_in;
wire [31:0]addr_start;
wire bit_count_clear; 
wire command_enable;

wire ddr_2a_en;
wire ddr_2b_en;
wire ddr_1a_en;
wire ddr_1b_en;
wire ddr_1c_en;
wire ddr_1d_en;

wire ddr_2_reg;
wire ddr_2_mem;
wire ddr_2_lin;
wire ddr_2_wrp;

wire sdr_0a_en;
wire sdr_0b_en;
wire sdr_0c_en;
wire sdr_0d_en;
wire sdr_0e_en;
wire sdr_0f_en;
wire sdr_0g_en;
wire sdr_0h_en;
wire sdr_0i_en;
wire sdr_0j_en;
wire sdr_0k_en;

wire sdr_0_reg;
wire sdr_0_mem;
wire sdr_0_lin;
wire sdr_0_wrp;

wire cmd_en;
wire addr_en;
wire latency_en;
wire rd_en;
wire wr_en;
wire mem_en;
wire reg_en;
wire wrp_en;
wire lin_en;

wire enter_pwr_down;
wire exit_pwr_down;

wire [31:0]max_config_reg;
wire [31:0]max_status_reg;
wire [31:0]max_intrpt_reg;


assign 	max_config_reg=(command_code==8'h7f)?maxvy_reg[comm_addr_reg[31:0]==32'd512]:max_config_reg;
//assign	maxvy_reg[513]=max_status_reg;
//assign	maxvy_reg[514]=max_intrpt_reg;
		
assign max_status_reg={23'h0,lin_en,wrp_en,reg_en,mem_en,wr_en,rd_en,latency_en,addr_en,cmd_en};
assign max_intrpt_reg={29'h0,enter_pwr_down,exit_pwr_down};

assign wr_enable = (ddr_2_mem && ddr_2b_en && ns==READ_DATA)?1'b0:1'b1;
assign rd_enable = (ddr_2_mem && ddr_2a_en && ns==WRITE_DATA)?1'b0:1'b1;
assign data_in=(ddr_2_mem && ddr_2a_en && ns==WRITE_DATA)?dq_in:16'b0;			
assign dq_out=(ddr_2_mem && ddr_2b_en && ns==READ_DATA)?rd_data:16'b0;

assign addr_start=(ns==LATENCY_CNT)?comm_addr_reg[31:0]:addr_start;//{4'b0,comm_addr_reg[39:16],comm_addr_reg[2:0]}:addr_start;
assign bit_count_clear=(ns==IDLE)?1'b1:1'b0;
assign command_enable=(ps==IDLE)?1'b1:1'b0;

assign cmd_en=(ns==COMMAND)?1'b1:1'b0;
assign addr_en=(ns==COMMAND_ADDR)?1'b1:1'b0;
assign latency_en=(ns==LATENCY_CNT)?1'b1:1'b0;
assign wr_en=(ns==WRITE_DATA)?1'b1:1'b0;
assign rd_en=(ns==READ_DATA)?1'b1:1'b0;

assign lin_en=(command_code[5]==1'b1)?1'b1:1'b0;
assign wrp_en=(command_code[5]==1'b0)?1'b1:1'b0;
assign reg_en=(command_code[6]==1'b1)?1'b1:1'b0;
assign mem_en=(command_code[6]==1'b1)?1'b1:1'b0;


// ********** SDR 1S-1S-1S  ***************** //
assign sdr_0j_en =(sdr_en && (command_code==8'hDF))?1'b1:1'b0; 
assign sdr_0k_en =(sdr_en && (command_code==8'h7F))?1'b1:1'b0; 
assign sdr_0e_en = (sdr_en && (command_code==8'h5A))?1'b1:1'b0;
assign sdr_0c_en = (sdr_en && (command_code==8'h03))?1'b1:1'b0;

assign sdr_0a_en = 1'b0;
assign sdr_0b_en = 1'b0;
assign sdr_0d_en = 1'b0;
assign sdr_0f_en = 1'b0;
assign sdr_0g_en = 1'b0;
assign sdr_0h_en = 1'b0;
assign sdr_0i_en = 1'b0;



assign sdr_0_reg=(sdr_en && command_code[6]==1'b1)?1'b1:1'b0; //maxvy register space
assign sdr_0_mem=(sdr_en && command_code[6]==1'b0)?1'b1:1'b0; //memory space

assign sdr_0_lin=(sdr_en && command_code[5]==1'b1)?1'b1:1'b0; //linear burst
assign sdr_0_wrp=(sdr_en && command_code[5]==1'b0)?1'b1:1'b0; //wrapped burst

// ********** 8D-8D-8D profile 1.0  *********** //
assign ddr_1a_en = (ddr_1_en && ((command_code==8'h06) ||(command_code==8'h04) ||(command_code==8'hB0) ||(command_code==8'h75)||
				(command_code==8'h30) ||(command_code==8'h7A) ||(command_code==8'hD0) ||(command_code==8'hC7) ||
				(command_code==8'h70) ||(command_code==8'h50) ||(command_code==8'hB9) ||(command_code==8'hAB) ||
				(command_code==8'h66) ||(command_code==8'h99) ||(command_code==8'hFF)))?1'b1:1'b0;
				
assign ddr_1b_en = (ddr_1_en && ((command_code==8'h0B) ||(command_code==8'hEE) ||(command_code==8'h05) ||(command_code==8'h5A)||
				(command_code==8'h0C) ||(command_code==8'h15) ||(command_code==8'h65) ||(command_code==8'h85) ||
				(command_code==8'h71) ||(command_code==8'hB5) ||(command_code==8'hF0)))?1'b1:1'b0;

assign ddr_1c_en = (ddr_1_en && ((command_code==8'hD8) ||(command_code==8'hDC) ||(command_code==8'h20) ||(command_code==8'h21)||
				(command_code==8'h52) ||(command_code==8'h53)))?1'b1:1'b0;
			
assign ddr_1d_en = (ddr_1_en && ((command_code==8'h02) ||(command_code==8'h12) ||(command_code==8'hC0) ||(command_code==8'h01)||
				(command_code==8'h81) ||(command_code==8'h72) ||(command_code==8'hB1) ||(command_code==8'h71)))?1'b1:1'b0;

// ********** 8D-8D-8D profile 2.0  *********** //
assign ddr_2a_en=(ddr_2_en && command_code[7]==1'b1)?1'b1:1'b0; // write data
assign ddr_2b_en=(ddr_2_en && command_code[7]==1'b0)?1'b1:1'b0; // read data

assign ddr_2_reg=(ddr_2_en && command_code[6]==1'b1)?1'b1:1'b0; //register space
assign ddr_2_mem=(ddr_2_en && command_code[6]==1'b0)?1'b1:1'b0; //memory space

assign ddr_2_lin=(ddr_2_en && command_code[5]==1'b1)?1'b1:1'b0; //linear burst
assign ddr_2_wrp=(ddr_2_en && command_code[5]==1'b0)?1'b1:1'b0; //wrapped burst

assign switch_mode=(max_config_reg[0])?1'b1:1'b0;

always@(*)
begin
if((!reset) || cs)
 begin
sdr_en= 1'b1;
ddr_1_en= 1'b0;
ddr_2_en= 1'b0;
address_modifier_byte= 3'd3;
latency_cycle_byte= 5'd8;
data_cnt_byte= 8'd2;
comm_ext_en= 1'b0;
end
else if(switch_mode)
begin 
sdr_en= 1'b0;
ddr_1_en= 1'b0;
ddr_2_en= 1'b1;
address_modifier_byte= max_config_reg[3:1];
latency_cycle_byte= max_config_reg[8:4];
data_cnt_byte= max_config_reg[16:9];
comm_ext_en= max_config_reg[17];
end
else if(e_def_p_mode)
begin
sdr_en= 1'b1;
ddr_1_en= 1'b0;
ddr_2_en= 1'b0;
address_modifier_byte= 3'd3;
latency_cycle_byte= 5'd8;
data_cnt_byte= 8'd2;
comm_ext_en= 1'b0;
end 
else
begin
sdr_en= 1'b1;
ddr_1_en= 1'b0;
ddr_2_en= 1'b0;
address_modifier_byte= 3'd3;
latency_cycle_byte= 5'd8;
data_cnt_byte= 8'd2;
comm_ext_en= 1'b0;
end
end


`include "sfdp_hdr_reg.v"
`include "sccr_reg.v"
`include "maxvy_reg.v"
//`include "reg_space.v"


// ************** SFDP ACTIVE ****************//


always@(posedge ck or posedge cs)
begin
if(!reset)
ck_ref <= 1'b0;
else if(cs)
ck_ref <= 1'b0;
else
ck_ref <= ~ck_ref;
end

always@(posedge ck)
begin
if(!reset)
ck_q<=1'b0;
else
ck_q<=ck_ref;
end

always@(posedge ck)
begin
if(!reset)
ck_2q<=1'b0;
else
ck_2q<=ck_q;
end 

always@(posedge ck_2q)
begin
if(!reset)
wren1 <= 1'b0;
else if(comm_addr_reg== 48'h00555 && rd_data==16'h00AA && command_code==8'h3F)
wren1 <= 1'b1;
end

always@(posedge ck_2q)
begin
if(!reset)
wren2 <= 1'b0;
else if(comm_addr_reg== 48'h002AA && rd_data==16'h0055 && command_code==8'h3F)
wren2 <= 1'b1;
end

always@(posedge ck)
begin
if(!reset)
e_def_p_mode <= 1'b0;
else if(wren1 && wren2 && comm_addr_reg== 48'h00555 && rd_data==16'h00F5 && command_code==8'h3F)
e_def_p_mode <= 1'b1;
else
e_def_p_mode <= 1'b0;
end

always@(posedge ck)
begin
if(!reset)
sfdp_active <= 1'b0;
else if(wren1 && wren2 && comm_addr_reg== 48'h00555 && rd_data==16'h0090 && command_code==8'h3F)
sfdp_active <= 1'b1;
else
sfdp_active <= 1'b0;
end

always@(posedge ck_2q)
begin
if(!reset)
stat_reg_enable <= 1'b0;
else if(comm_addr_reg== 48'h00555 && rd_data==16'h0070 && command_code==8'h3F)
stat_reg_enable <= 1'b1;
end

/* always@(posedge ck_2q)
begin
if(!reset)
config_reg_enable <= 1'b0;
else if(comm_addr_reg== 48'h00555 && rd_data==16'h0070 && command_code==8'h3F)
config_reg_enable <= 1'b1;
end */







/////////////////////////////////         SFDP             //////////////////////////////////////

/* always@(posedge ck)
begin
if(!reset)
addr<=32'b0;
else if(ns==LATENCY_CNT)
addr<=addr_start;
else if((ns==READ_DATA || ns==WRITE_DATA) && ddr_2_lin)
addr <= addr+32'd1;
else if((ns==READ_DATA || ns==WRITE_DATA) && ddr_2_wrp && addr[7:0]==8'h07)	
addr <=addr_start;
else if((ns==READ_DATA || ns==WRITE_DATA) && ddr_2_wrp)	
addr <=addr+32'd1;
else
addr <=addr;
end */

assign addr =(!cs)?(ns==READ_DATA || ns==WRITE_DATA)?(ddr_2_lin)?addr+32'd1:(ddr_2_wrp)?(addr[7:0]==8'hFF)?addr_start:addr+32'd1:
					addr:32'b0:32'b0;

always@(posedge ck)
begin
if(!reset)
addr_count <=8'd2;
else if((ns==READ_DATA || ns==WRITE_DATA) && ddr_2_lin && ddr_2_reg)
addr_count <= addr_count+8'd2;
else if((ns==READ_DATA || ns==WRITE_DATA) && ddr_2_wrp && addr[7:0]==8'h07 && ddr_2_reg)
addr_count <= 8'd2;
else if((ns==READ_DATA || ns==WRITE_DATA) && ddr_2_wrp && ddr_2_reg)
addr_count <= addr_count+8'd2;
else
addr_count <= 8'd2;
end


always@(posedge ck)
begin
if(!reset)
sdr_count<=8'b0;
else if(sdr_en && bit_count==4'h0  && ns==WRITE_DATA)
sdr_count<=sdr_count+8'b1;
else if(sdr_en && !cs && ns!=WRITE_DATA)
sdr_count<=8'b0;
/* else
sdr_count<=sdr_count; */
end

always@(posedge ck)
begin
	if(!reset)
     bit_count <= 4'd7;
	else if (bit_count_clear&& !cs)
     bit_count <= 4'd7;  
	else if(sdr_en && bit_count==4'b0 && !cs)
	 bit_count <= 4'd7;
	else if(sdr_en && bit_count>=4'h0  && !cs)
     bit_count <= bit_count-4'b1;
	else if((ddr_1_en || ddr_2_en) && bit_count!=4'b0 && !cs)
     bit_count <= 4'd8;//bit_count=4'd0
	
	else if((ddr_1_en || ddr_2_en) && bit_count==4'b0 && !cs)
	bit_count <= 4'd8;
	else
	bit_count <= 4'd7;
end	




always@(posedge ck)
begin
	if(!reset)
		addr_cnt <=4'd0;
	else if(sdr_en && ns!=COMMAND_ADDR)
		addr_cnt <={1'b0,(address_modifier_byte)};
	else if(sdr_en && bit_count == 4'd0 && ns==COMMAND_ADDR)
		addr_cnt <= addr_cnt-4'b1;
	else if((ddr_1_en || ddr_2_en) && ns==COMMAND_ADDR && ps!=COMMAND_ADDR && !comm_ext_en)
		addr_cnt <={1'b0,(address_modifier_byte-1)};
	else if((ddr_1_en || ddr_2_en) && ns==COMMAND_ADDR && ps!=COMMAND_ADDR && comm_ext_en)
		addr_cnt <={1'b0,address_modifier_byte};
	else if((ddr_2_en) && addr_cnt!=4'h0 && ns==COMMAND_ADDR)
		addr_cnt <= addr_cnt-4'd2;
	else if((ddr_1_en ) && addr_cnt!=4'h0 && ns==COMMAND_ADDR)
		addr_cnt <= addr_cnt-4'd2;
	else
		addr_cnt<=4'd0;
end

always@(posedge ck)
begin
	if(!reset)
		latency_count <=6'd0;
	else if(sdr_en && ns!=LATENCY_CNT)
		latency_count <={1'b0,latency_cycle_byte};
	else if(sdr_en && ns==LATENCY_CNT && latency_count>0)
		latency_count <=latency_count-6'h1;
	else if((ddr_1_en || ddr_2_en) && ns!=LATENCY_CNT)
		latency_count <={1'b0,latency_cycle_byte};
	else if((ddr_1_en || ddr_2_en)  &&latency_count!=6'h0  && ns==LATENCY_CNT)
		latency_count <=latency_count-6'd1;
	else
		latency_count<=6'd0;
end

always@(posedge ck)
begin
	if(!reset)
		data_cnt <= 9'h0;
	else if(sdr_en && ns!=WRITE_DATA)
		data_cnt <= {1'b0,data_cnt_byte};
	else if(sdr_en && bit_count==4'd0  && (ns==READ_DATA || ns==WRITE_DATA))
		data_cnt <= data_cnt-9'h1;
	else if((ddr_1_en || ddr_2_en) && (ns==LATENCY_CNT))
		data_cnt <= {1'b0,data_cnt_byte};
	else if((ddr_1_en || ddr_2_en) && data_cnt!=9'h0 && (ns==READ_DATA || ns==WRITE_DATA))
		data_cnt <= data_cnt-9'd2;
	else
		data_cnt <= 9'h0;
end		


always@(posedge ck or posedge cs)
begin
if(!reset)
ps<= IDLE;
else if(!cs)
ps<= ns;
else
ps<=IDLE;
end


always@(*)
begin
if(!reset)
ns<=IDLE;
else if(!cs)
begin
   case(ps)
    IDLE:
	    if(command_enable)
		   ns <= COMMAND;
		else
		   ns <= IDLE;
    COMMAND:
	   if(bit_count==4'd7 && sdr_en && sdr_0a_en)
		   ns <= IDLE;
		else  if(bit_count==4'd7 && sdr_en && sdr_0g_en)
		   ns <= WRITE_DATA;
        else if(bit_count==4'd7 && sdr_en && sdr_0b_en)
		   ns <= READ_DATA;
		else if(bit_count==4'd7 && sdr_en && (sdr_0c_en || sdr_0d_en || sdr_0e_en||sdr_0f_en||sdr_0h_en||sdr_0i_en||sdr_0j_en||sdr_0k_en))
		   ns <= COMMAND_ADDR;   
		else if(bit_count==4'd8 && (ddr_1_en || ddr_2_en) &&(ddr_1_en||ddr_2_en || ddr_1b_en ||ddr_1c_en || ddr_1d_en))
		   ns <= COMMAND_ADDR;
		else if(bit_count==4'd8 && ddr_1_en && ddr_1a_en)
		  ns <= IDLE; 
	
		else 
		ns <= COMMAND;
 
    COMMAND_ADDR:
	    if(((addr_cnt==4'b0) || addr_cnt[3]) && sdr_en && (sdr_0c_en || sdr_0d_en))
		   ns <= WRITE_DATA;
		else if (((addr_cnt==4'b0) || addr_cnt[3]) && sdr_en && (sdr_0j_en || sdr_0k_en))
		    ns <= READ_DATA;
		else if(((addr_cnt==4'b0) || addr_cnt[3]) && sdr_en && (sdr_0e_en || sdr_0f_en))
		    ns <= LATENCY_CNT;
			else if(((addr_cnt==4'b0) || addr_cnt[3]) && (ddr_1_en || ddr_2_en) && (ddr_2a_en || ddr_2b_en ||ddr_1b_en))
		    ns <= LATENCY_CNT;
	   	else if(((addr_cnt==4'b0) || addr_cnt[3]) &&  (sdr_en || ddr_1_en) &&(ddr_1c_en))
		    ns <= IDLE;
		else if(((addr_cnt==4'b0)|| addr_cnt[3]) &&  (sdr_en || ddr_1_en) && (ddr_1d_en))
		    ns <= READ_DATA;
		else
		    ns <= COMMAND_ADDR;
	WRITE_DATA:
	    if(((data_cnt==9'h0) || (data_cnt[8])) && (ddr_1_en || ddr_2_en ||sdr_en) && (ddr_2a_en|| ddr_1b_en||sdr_0c_en||sdr_0d_en ||sdr_0e_en||sdr_0f_en))
			ns <= IDLE;
		else
			ns <= WRITE_DATA;
				
	READ_DATA:
	    if(((data_cnt==9'h0)|| (data_cnt[8]))&& sdr_en &&(sdr_0g_en||sdr_0j_en||sdr_0k_en) )
		   ns <= IDLE;
		else if(((data_cnt==9'h0)|| (data_cnt[8])) && (ddr_1_en || ddr_2_en) && (ddr_2b_en || ddr_1d_en))
		   ns <= IDLE;
		else
		   ns <= READ_DATA;
		   
	LATENCY_CNT:
	    if(((latency_count ==6'd0) || latency_count[5]) && sdr_en && (sdr_0e_en||sdr_0f_en))
		   ns <= WRITE_DATA;
		else if(((latency_count ==6'd0) || latency_count[5]) &&(ddr_1_en || ddr_2_en) && (ddr_2a_en || ddr_1b_en))
		   ns <= WRITE_DATA;
		else if (((latency_count ==6'd0) || latency_count[5]) && (ddr_1_en || ddr_2_en) && (ddr_2b_en || ddr_1d_en))
		   ns <= READ_DATA;
		else
		   ns <= LATENCY_CNT;
	default:
			ns<=IDLE;
   endcase
end 
else
ns<=IDLE;
end

always@(posedge ck)
begin
if(!reset)
begin
command_code <= 8'b0;
comm_ext_reg <= 8'b0;
end
else if((ns==COMMAND || (ns==COMMAND_ADDR && ps==COMMAND)) && !cs && sdr_en && bit_count>=8'h0)
begin
command_code[bit_count]<=io_in[0];
comm_ext_reg <= 8'b0;
end
else if(ns==COMMAND && !cs && (ddr_1_en||ddr_2_en) && comm_ext_en)
begin
command_code <= io_in[15:8];
comm_ext_reg <= io_in[7:0];
end
else if(ns==COMMAND && !cs && (ddr_1_en||ddr_2_en) && !comm_ext_en)
begin
command_code <= io_in[15:8];
comm_ext_reg <= 8'b0;
end
else
begin
command_code <= command_code;
comm_ext_reg <= comm_ext_reg;
end
end 


always@(posedge ck)
begin
if(!reset)
comm_addr_reg <= 48'b0;
else if(ns==COMMAND_ADDR && !cs && sdr_en && addr_cnt>0)
begin
comm_addr_reg <= comm_addr_reg<<1;
comm_addr_reg[0] <= io_in[0];
//comm_addr_reg[((addr_cnt-1)*8)+bit_count-1] <= io_in[0]; 
end
else if(ns==COMMAND_ADDR && !cs && (ddr_1_en || ddr_2_en)&& addr_cnt>0 && !comm_ext_en)
begin
comm_addr_reg <= comm_addr_reg<<16;
comm_addr_reg <= io_in;
//comm_addr_reg[((addr_cnt*8)-1)-:16] <=io_in;
end
else if(ns==COMMAND_ADDR && !cs && (ddr_1_en || ddr_2_en)&& address_modifier_byte>0 && !comm_ext_en)
comm_addr_reg[39:32] <=io_in[7:0];
else
comm_addr_reg <=comm_addr_reg;
end

always@(posedge ck)
begin
if(!reset)
latency_reg <= 5'b0;
else if(ns==LATENCY_CNT && !cs && sdr_en && latency_count!=6'h0)
latency_reg <= latency_reg+5'b1; 
else if(ns==LATENCY_CNT && !cs && (ddr_1_en || ddr_2_en)&& latency_count!=6'h0)
latency_reg <= latency_reg+5'b1;
else if(cs || ns ==COMMAND)
latency_reg <=5'b0;
else
latency_reg<= latency_reg;
end



assign rd_data=(ns==READ_DATA && !cs)?(ddr_1_en||ddr_2_en)?io_in:(sdr_en)?{15'hz,io_in[0]}:16'd0:16'd0;

/* always@(posedge ck)
begin
if(sdr_en && data_cnt>0 && ns==READ_DATA && command_code==8'h7F)
begin
maxvy_reg[comm_addr_reg[7:0]+sdr_count][(bit_count[2:0])] <= rd_data[0];
//maxvy_reg[comm_addr_reg[31:0]][((addr_cnt-1)*8)+bit_count[2:0]] <= rd_data[0];
end
end
 */
always@(posedge ck)
begin
if((ddr_1_en || ddr_2_en) && ns==READ_DATA && data_cnt==1 && ddr_2_reg && !cs)
{reg_space[(addr_start[12:0]+{5'd0,(addr_count-1)})],reg_space[(addr_start[12:0]+{5'd0,(addr_count-2)})]} <={8'b0,rd_data[7:0]};
else if((ddr_1_en || ddr_2_en) && ns==READ_DATA && data_cnt>0 && ddr_2_reg && !cs)
{reg_space[(addr_start[12:0]+{5'd0,(addr_count-1)})],reg_space[(addr_start[12:0]+{5'd0,(addr_count-2)})]} <= rd_data;
end	


assign io_out=(ns==WRITE_DATA && !cs)?(ddr_1_en || ddr_2_en)?(ddr_2_mem)?((data_cnt==1)?data_in:(data_cnt>0)?data_in:16'd0):
			(ddr_2_reg)?(data_cnt==9'h1)?{reg_space[(addr_start[12:0]+(addr_count-2))],8'b0}:(data_cnt>9'h0)?
			{reg_space[(addr_start[12:0]+(addr_count-2))],reg_space[(addr_start[12:0]+(addr_count-1))]}:16'd0:16'd0:
			
			(sdr_en)?(!sfdp_active)?(data_cnt>0)?{6'hz,(sfdp_hdr_reg[comm_addr_reg[7:0]+sdr_count][bit_count[2:0]]),1'bz}:16'd0:
			(data_cnt>0)?{6'hz,(reg_space[addr_start[12:0]+{5'd0,sdr_count}][(bit_count[2:0])]),1'hz}:16'd0:
			//(data_cnt>0)?{6'hz,(reg_space[comm_addr_reg[7:0]+sdr_count][(bit_count[2:0])]),1'hz}:16'd0:
			//(data_cnt>0)?{6'hz,(reg_space[comm_addr_reg[23:0]+{16'd0,sdr_count}][(bit_count)]),1'hz}:16'd0:
			16'd0:16'd0;
			
assign ds_out=(latency_cycle_byte>0 && !cs && ns==WRITE_DATA)?((ddr_1_en||ddr_2_en)?ck:(sdr_en)?ck:1'b0):1'b0;
assign write_enable=((sdr_en || ddr_1_en || ddr_2_en) && ns==WRITE_DATA && data_cnt>0)?1'b1:1'b0;

endmodule
