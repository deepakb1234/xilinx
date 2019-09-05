module mram_dut_top(
				ck,
				reset,
				cs,
				io_inout,
				ds_inout,
				
				dq_out,
				dq_in,
				addr,
				cs_out,
				wr_enable,
				rd_enable
				
						
					);


input ck;
input reset;
input cs;

inout [7:0]io_inout;
inout ds_inout;
input  [15:0]dq_out;
output  [15:0]dq_in;

output [31:0]addr;
output cs_out;

output wr_enable;
output rd_enable;

wire slv_sdr_en;
wire slv_ddr_1_en;
wire slv_ddr_2_en;
//wire slv_switch_mode;

wire [15:0]io_out;
wire [15:0]out;
//wire [7:0]command_code;

//wire [7:0]comm_ext_reg;
//wire [4:0]latency_reg;
wire write_enable;
//wire phy_wr_enable;
wire ds_out;
wire c_ds_out;



slave_xspi_phy 	u0_slave_xspi_phy(	.clk(ck),
            	.reset(reset),
				.io_in(io_out),
	    		.cs_in(cs),
				.rd_en(write_enable),
				//.wr_en(phy_wr_enable),
				.cs_out(cs_out),
				.out(out),//slave_output
				.io_in_out(io_inout),
				.ds_out(c_ds_out),
				.ds_in(ds_out),
				.sdr_en(slv_sdr_en),
				.ddr_1_en(slv_ddr_1_en),
				.ddr_2_en(slv_ddr_2_en),
				.ds_inout(ds_inout)
				
				
				
				);



xspi_slave_ctrl u0_xspi_slave_ctrl(	.cs(cs_out),
									.ck(ck),
									.reset(reset),
									.io_in(out),
									.io_out(io_out),
																		
									.ds_in(c_ds_out),
									.ds_out(ds_out),
									.rd_enable(rd_enable),//rd_enable
									.wr_enable(wr_enable),//wr_enable
																		
									.sdr_en(slv_sdr_en),
									.ddr_1_en(slv_ddr_1_en),
									.ddr_2_en(slv_ddr_2_en),
									//.switch_mode(slv_switch_mode),
									.write_enable(write_enable),
									
									.dq_in(dq_out),
									.dq_out(dq_in),
									
									.addr(addr)//(addr),
									// .command_code(command_code),
									// .comm_ext_reg(comm_ext_reg),
									// .latency_reg(latency_reg)
									
									);
									
									
endmodule