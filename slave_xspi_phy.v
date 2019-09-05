module slave_xspi_phy(	clk,
            		reset,
					ds_in,
					out,
					cs_in,
					cs_out,
					//wr_en,	
					rd_en,	
					io_in_out,
					ds_inout,
					ds_out,
					sdr_en,
					ddr_1_en,
					io_in,
					ddr_2_en
				 );

	    		
input clk;
input reset;
input cs_in;
//input wr_en;
input rd_en;
input ds_in;
input sdr_en;
input ddr_1_en;
input ddr_2_en;
input [15:0]io_in;


output ds_out;
output [15:0]out;
output cs_out;

inout [7:0]io_in_out;
inout  ds_inout;

reg p_en;
reg n_en;
//reg [7:0]io_in_d;

assign cs_out=cs_in;
assign ds_out=(!rd_en)?ds_inout:1'b0;
assign ds_inout=(rd_en)?ds_in:1'bz;
//assign io_in_out=(rd_en)?io_in_d:8'hz;


always@(clk)
begin
if(clk==1'b1)
begin
p_en<=1'b1;
n_en<=1'b0;
end
else
begin
p_en<=1'b0;
n_en<=1'b1;
end
end

/* 
always@(p_en or n_en)// or rd_en or ddr_1_en or ddr_2_en or io_in_out)//p_en or n_en
begin
if(!reset)
   out = 16'b0;
else if(!rd_en && !cs_in)
begin
	if((ddr_1_en || ddr_2_en) && !n_en  && p_en)        //posedge clk DDR
		out[15:8] = io_in_out;//io_in_out;
		
	else if(sdr_en && p_en && !n_en)               		//posedge clk SDR
		begin
		out[0] = io_in_out[0];//io_in_out[0];
		out[15:1] = 7'bz;
		end
	else if((ddr_1_en || ddr_2_en) && n_en && !p_en) 	//negedge clk DDR
		out[7:0]=io_in_out;//io_in_out;
	//else
		//out=16'b0;
			
end
//else
//out=16'b0;
end */

assign out = (!rd_en && !cs_in && !reset)?(ddr_1_en || ddr_2_en)?(!n_en  && p_en)?{io_in_out,8'h0}:io_in_out:(sdr_en)?(p_en && !n_en)?
				{7'bz,io_in_out[0]}:{7'bz,io_in_out[0]}:16'b0:16'b0;


/* always@(*)//p_en or n_en
begin
if(!reset)
   io_in_d = 8'h0;
else if(rd_en && !cs_in)
begin
	if((ddr_1_en || ddr_2_en) && !n_en && p_en)         //posedge clk DDR
		io_in_d = io_in[7:0];
	else if(sdr_en && p_en && !n_en)               		//posedge clk SDR
		begin
		io_in_d[1] = io_in[1];
		{io_in_d[7:2],io_in_d[0]}= 7'bz;
		end
	else if((ddr_1_en || ddr_2_en) && !p_en && n_en) 	//negedge clk DDR
		io_in_d =io_in[15:8];
	
            
end
else
io_in_d = 8'h0;
end
 */
assign io_in_out=(rd_en && !cs_in && !reset)?(ddr_1_en || ddr_2_en)?(!n_en && p_en)?io_in[7:0]:io_in[15:8]:(sdr_en)?(p_en && !n_en)?
				{6'bz,io_in[1],1'bz}:{6'bz,io_in[1],1'bz}:8'hz:8'hz;
						
endmodule