module vga_driver_to_frame_buf	(
    	//////////// ADC //////////
	//output		          		ADC_CONVST,
	//output		          		ADC_DIN,
	//input 		          		ADC_DOUT,
	//output		          		ADC_SCLK,

	//////////// Audio //////////
	//input 		          		AUD_ADCDAT,
	//inout 		          		AUD_ADCLRCK,
	//inout 		          		AUD_BCLK,
	//output		          		AUD_DACDAT,
	//inout 		          		AUD_DACLRCK,
	//output		          		AUD_XCK,

	//////////// CLOCK //////////
	//input 		          		CLOCK2_50,
	//input 		          		CLOCK3_50,
	//input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// SDRAM //////////
	//output		    [12:0]		DRAM_ADDR,
	//output		     [1:0]		DRAM_BA,
	//output		          		DRAM_CAS_N,
	//output		          		DRAM_CKE,
	//output		          		DRAM_CLK,
	//output		          		DRAM_CS_N,
	//inout 		    [15:0]		DRAM_DQ,
	//output		          		DRAM_LDQM,
	//output		          		DRAM_RAS_N,
	//output		          		DRAM_UDQM,
	//output		          		DRAM_WE_N,

	//////////// I2C for Audio and Video-In //////////
	//output		          		FPGA_I2C_SCLK,
	//inout 		          		FPGA_I2C_SDAT,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	//output		     [6:0]		HEX4,
	//output		     [6:0]		HEX5,

	//////////// IR //////////
	//input 		          		IRDA_RXD,
	//output		          		IRDA_TXD,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// PS2 //////////
	//inout 		          		PS2_CLK,
	//inout 		          		PS2_CLK2,
	//inout 		          		PS2_DAT,
	//inout 		          		PS2_DAT2,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// Video-In //////////
	//input 		          		TD_CLK27,
	//input 		     [7:0]		TD_DATA,
	//input 		          		TD_HS,
	//output		          		TD_RESET_N,
	//input 		          		TD_VS,

	//////////// VGA //////////
	output		          		VGA_BLANK_N,
	output		     [7:0]		VGA_B,
	output		          		VGA_CLK,
	output		     [7:0]		VGA_G,
	output		          		VGA_HS,
	output		     [7:0]		VGA_R,
	output		          		VGA_SYNC_N,
	output		          		VGA_VS

	//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_0,

	//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_1

);

// Turn off all displays.
assign	HEX0		=	7'h00;
assign	HEX1		=	7'h00;
assign	HEX2		=	7'h00;
assign	HEX3		=	7'h00;

// DONE STANDARD PORT DECLARATION ABOVE
/* HANDLE SIGNALS FOR CIRCUIT */
wire clk;
wire rst;

assign clk = CLOCK_50;
assign rst = KEY[0];

wire [9:0]SW_db;

debounce_switches db(
.clk(clk),
.rst(rst),
.SW(SW), 
.SW_db(SW_db)
);

// VGA DRIVER
wire active_pixels; // is on when we're in the active draw space
wire frame_done;
wire [9:0]x; // current x
wire [9:0]y; // current y - 10 bits = 1024 ... a little bit more than we need

/* the 3 signals to set to write to the picture */
reg [14:0] the_vga_draw_frame_write_mem_address;
reg [23:0] the_vga_draw_frame_write_mem_data;
reg the_vga_draw_frame_write_a_pixel;

/* This is the frame driver point that you can write to the draw_frame */
vga_frame_driver my_frame_driver(
	.clk(clk),
	.rst(rst),

	.active_pixels(active_pixels),
	.frame_done(frame_done),

	.x(x),
	.y(y),

	.VGA_BLANK_N(VGA_BLANK_N),
	.VGA_CLK(VGA_CLK),
	.VGA_HS(VGA_HS),
	.VGA_SYNC_N(VGA_SYNC_N),
	.VGA_VS(VGA_VS),
	.VGA_B(VGA_B),
	.VGA_G(VGA_G),
	.VGA_R(VGA_R),

	/* writes to the frame buf - you need to figure out how x and y or other details provide a translation */
	.the_vga_draw_frame_write_mem_address(the_vga_draw_frame_write_mem_address),
	.the_vga_draw_frame_write_mem_data(the_vga_draw_frame_write_mem_data),
	.the_vga_draw_frame_write_a_pixel(the_vga_draw_frame_write_a_pixel)
);

//reg [15:0]i;
reg [7:0]S;
reg [7:0]NS;

parameter 
	// START 			= 8'd0,
	// W2M is write to memory
	W2M_INIT 		= 8'd1,
	W2M_COND 		= 8'd2,
	W2M_INC 			= 8'd3,
	W2M_DONE 		= 8'd4,
	// The RFM = READ_FROM_MEMOERY reading cycles
	RFM_INIT_START = 8'd5,
	RFM_INIT_WAIT 	= 8'd6,
	RFM_DRAWING 	= 8'd7,
	ERROR 			= 8'hFF;

parameter MEMORY_SIZE = 16'd12; // 160*120 // Number of memory spots ... highly reduced since memory is slow
parameter PIXEL_VIRTUAL_SIZE = 16'd40; // Pixels per spot - therefore 4x4 pixels are drawn per memory location
// REMEMBER: CHANGING WOULD REQUIRE VGA FRAME DRIVER TO CHANGE ALSO


/* ACTUAL VGA RESOLUTION */
parameter VGA_WIDTH = 16'd640; 
parameter VGA_HEIGHT = 16'd480;

/* Our reduced RESOLUTION 160 by 120 needs a memory of 19,200 words each 24 bits wide */
parameter VIRTUAL_PIXEL_WIDTH = VGA_WIDTH/PIXEL_VIRTUAL_SIZE; // 4, 8, 16, 32
parameter VIRTUAL_PIXEL_HEIGHT = VGA_HEIGHT/PIXEL_VIRTUAL_SIZE; // 3, 6, 12, 24 
parameter GRID_SIZE = VIRTUAL_PIXEL_WIDTH*VIRTUAL_PIXEL_HEIGHT;
parameter NUM_BLOCKS = VIRTUAL_PIXEL_WIDTH/2; // if 8 -> 4 init blocks, 4 -> 2 init blocks

parameter INIT = 6'd0,
				START = 6'd1, 
				
				RIGHT_WAIT = 6'd2,
				RIGHT_SHIFT = 6'd3,
				RIGHT_RPT = 6'd4,
				RIGHT_DRAW = 6'd5,
				RIGHT_END = 6'd6,
				
				LEFT_WAIT = 6'd7,
				LEFT_SHIFT = 6'd8,
				LEFT_RPT = 6'd9,
				LEFT_DRAW = 6'd10,
				LEFT_END = 6'd11,
            
				ROW_STOP = 6'd12,
				ROW_UPDT = 6'd13,
				ROW_RPT = 6'd14,
				ROW_DRAW = 6'd15,
				ROW_NEXT = 6'd16,
				ROW_WAIT = 6'd17,
				ROW_END = 6'd18,
				
            WIN = 6'd19,
				LOSE = 6'd20,
            RESET = 6'd21,
				RESET_END = 6'd22;


reg [20:0] idx_location;

reg [VIRTUAL_PIXEL_WIDTH-1'd1:0] draw_row;
reg [VIRTUAL_PIXEL_WIDTH-1'd1:0] curr_row;
reg [VIRTUAL_PIXEL_WIDTH-1'd1:0] prev_row;
reg [VIRTUAL_PIXEL_WIDTH-1'd1:0] comp_row;

reg [20:0] row_idx; // num of rows, minus 1
reg [20:0] col_idx; // num of cols, minus 1
reg [20:0] diff_idx; // difference between col_idx & row_idx

reg [20:0] row_num; // start at row 0, increase by 1.
reg [20:0] col_num; // start at col 0, increase by 1.
reg [20:0] i;

reg [0:0] win;
reg [0:0] lose;

//assign LEDR[VIRTUAL_PIXEL_WIDTH-1'd1:0] = prev_row; // NOTE: there is a slight delay between the blocks displayed and the counter.
assign LEDR[9:8] = {win, lose};
//assign LEDR[9:9] = win;
//assign LEDR[8:8] = lose;

reg [0:0] moving_right;
reg [0:0] moving_left;

reg [9:0] reset_counter;
reg [34:0] counter = 35'd0;

localparam DIVISOR = 25'd15_000_000;// 1 second
localparam WAIT_COUNT = 25'd15_000_000;// 1 second
reg [24:0] speed; 

// Next-state logic
always @(*) begin
    case (S)
        RESET: begin
				 if (counter > GRID_SIZE+1'd1) NS = RESET_END;
				 else NS = RESET;
        end
		  RESET_END: begin
				 NS = INIT;
		  end
        INIT: begin
            NS = START;
        end

        START: begin
            case ({moving_right, moving_left}) 
                3'b10: NS = RIGHT_WAIT;
                3'b01: NS = LEFT_WAIT;
					 default: NS = RIGHT_WAIT;
            endcase
        end
		  
		  RIGHT_WAIT: begin
            if (KEY[3] == 1'b0) NS = ROW_STOP;
            else if (counter == (speed - 1'd1)) NS = RIGHT_SHIFT;
            else NS = RIGHT_WAIT;
        end
		  RIGHT_SHIFT: begin
				NS = RIGHT_RPT;
		  end
		  RIGHT_RPT: begin
				if (i < col_idx - 1'd1) NS = RIGHT_DRAW;
				else if (curr_row[i]) NS = RIGHT_END; //had to invert it, so it would work as intended
				else NS = RIGHT_WAIT;
		  end
		  RIGHT_DRAW: begin
				NS = RIGHT_RPT;
		  end
		  RIGHT_END: begin
				NS = START;
		  end
		  
		  LEFT_WAIT: begin
            if (counter == (speed - 1'd1)) NS = LEFT_SHIFT;
            else NS = LEFT_WAIT;
        end
		  LEFT_SHIFT: begin
				NS = LEFT_RPT;
		  end
		  LEFT_RPT: begin
				if (i > 10'd0) NS = LEFT_DRAW;
				else if (curr_row[i]) NS = LEFT_END; //had to invert it, so it would work as intended
				else NS = LEFT_WAIT;
		  end
		  LEFT_DRAW: begin
				NS = LEFT_RPT;
		  end
		  LEFT_END: begin
				NS = START;
		  end
		  
		  ROW_STOP: begin
				NS = ROW_DRAW;
		  end
		  ROW_RPT: begin
				if (((i < col_idx - 1'd1) && ({moving_right, moving_left} == 2'b10)) || 
				((i > 10'd0) && ({moving_right, moving_left} == 2'b01))) NS = ROW_DRAW;
				else NS = ROW_UPDT;
		  end
		  ROW_DRAW: begin
				NS = ROW_RPT;
		  end
		  ROW_UPDT: begin
				if ((row_num == VIRTUAL_PIXEL_HEIGHT - 1'd1) && ((comp_row) > 20'd0)) NS = WIN;
				else if ((prev_row) == 10'd0 || comp_row > 20'd0) NS = ROW_WAIT;
				else NS = LOSE;
		  end
		  ROW_WAIT: begin
				if (counter == (WAIT_COUNT - 1'd1)) NS = ROW_END;
				else NS = ROW_WAIT;
		  end
		  ROW_END: begin
				NS = START;
		  end
		  
        WIN: begin
            NS = WIN;
        end
		  LOSE: begin
				NS = LOSE;
		  end

        default: NS = INIT;
    endcase
end

// Output and state actions
always @(posedge clk or negedge rst) begin
    if (rst == 1'b0) begin
	 
		  win <= 1'd0;
		  lose <= 1'd0;
	 
        the_vga_draw_frame_write_a_pixel <= 1'b1;
		  counter <= 35'd0;
		  
		  idx_location <= 10'd0;
		  row_num <= 10'd0;
		  
		  comp_row <= 10'd0;
		  prev_row <= 10'd0;
		  
    end else begin
	 
        case (S)
		  
            RESET: begin
					 counter <= counter + 1'd1;
					 
					 the_vga_draw_frame_write_mem_data <= 24'd0;
					 the_vga_draw_frame_write_mem_address <= counter;
            end
				RESET_END: begin
					 {moving_right, moving_left} <= 2'b10;
					 counter <= 35'd0;
					 the_vga_draw_frame_write_a_pixel <= 1'b0;
				end
            INIT: begin
                row_idx <= VIRTUAL_PIXEL_HEIGHT; // 3'd3 (starts at bottom row), could also be d6
                col_idx <= VIRTUAL_PIXEL_WIDTH; // 3'd4 columns, d8
					 diff_idx <= VIRTUAL_PIXEL_WIDTH - VIRTUAL_PIXEL_HEIGHT; // used for keeping track of between
					 
					 speed <= DIVISOR;
					 
					 curr_row <= 16'b0000001111000000;
					 //curr_row <= 8'b00011000;
            end
				START: begin
					 
            end
            
				RIGHT_WAIT: begin
					 counter <= counter + 1'b1;
					 
					 the_vga_draw_frame_write_a_pixel <= 1'b0;
				end
				RIGHT_SHIFT: begin
					 curr_row <= curr_row << 1; //had to invert it, so it would work as intended
					 
					 counter <= 10'd0;
					 
					 the_vga_draw_frame_write_a_pixel <= 1'b0;
					 
					 i <= 10'd0;
				end
				RIGHT_RPT: begin
					 the_vga_draw_frame_write_a_pixel <= 1'b1;
					 
					 if (curr_row[i]) begin
							the_vga_draw_frame_write_mem_data <= 24'hFF0000; 
					 end
					 else the_vga_draw_frame_write_mem_data <= 24'd0;
					 
					 idx_location <= ((col_idx - diff_idx)*i) + (row_idx - 1'd1);
					 the_vga_draw_frame_write_mem_address <= idx_location;
				end
				RIGHT_DRAW: begin
					 the_vga_draw_frame_write_a_pixel <= 1'b1;
					 
					 i <= i + 1'd1;
				end
				RIGHT_END: begin
					 {moving_right, moving_left} <= 2'b01;
					 
					 the_vga_draw_frame_write_a_pixel <= 1'b0;
					 
					 counter <= 10'd0;
				end
				
				LEFT_WAIT: begin
					 counter <= counter + 1'b1;
					 
					 the_vga_draw_frame_write_a_pixel <= 1'b0;
				end
				LEFT_SHIFT: begin
					 curr_row <= curr_row >> 1; //had to invert it, so it would work as intended
					 
					 counter <= 10'd0;
					 
					 the_vga_draw_frame_write_a_pixel <= 1'b0;
					 
					 i <= col_idx - 1'd1;
				end
				LEFT_RPT: begin
					 the_vga_draw_frame_write_a_pixel <= 1'b1;
					 
					 if (curr_row[i]) begin
							the_vga_draw_frame_write_mem_data <= 24'hFF0000; 
					 end
					 else the_vga_draw_frame_write_mem_data <= 24'd0;
					 
					 idx_location <= ((col_idx - diff_idx)*i) + (row_idx - 1'd1);
					 the_vga_draw_frame_write_mem_address <= idx_location;
				end
				LEFT_DRAW: begin
					 the_vga_draw_frame_write_a_pixel <= 1'b1;
				
					 i <= i - 1'd1;
				end
				LEFT_END: begin
					 {moving_right, moving_left} <= 2'b10;
					 
					 the_vga_draw_frame_write_a_pixel <= 1'b0;
					 
					 counter <= 10'd0;
				end
				
				ROW_STOP: begin
					 if (prev_row == 10'd0) comp_row <= (curr_row & curr_row);
					 else comp_row <= (curr_row & prev_row);
					 
					 if ({moving_right, moving_left} == 2'b10) i <= 10'd0;
					 else i <= i <= col_idx - 1'd1;
					 
					 the_vga_draw_frame_write_a_pixel <= 1'b0;
				end
				ROW_RPT: begin
				    the_vga_draw_frame_write_a_pixel <= 1'b1;
					 
					 if (comp_row[i]) the_vga_draw_frame_write_mem_data <= 24'hFF0000; 
					 else the_vga_draw_frame_write_mem_data <= 24'd0;
					 
					 idx_location <= ((col_idx - diff_idx)*i) + (row_idx - 1'd1);
					 the_vga_draw_frame_write_mem_address <= idx_location;
				end
				ROW_DRAW: begin
					 the_vga_draw_frame_write_a_pixel <= 1'b1;
					 
					 if ({moving_right, moving_left} == 2'b10) i <= i + 1'd1;
					 else i <= i - 1'd1;
				end
				ROW_UPDT: begin
					 curr_row <= comp_row;
					 prev_row <= comp_row;
					 
					 counter <= 10'd0;
					 
					 the_vga_draw_frame_write_a_pixel <= 1'b0;
				end
				ROW_WAIT: begin
					 counter <= counter + 1'd1;
				end
				ROW_END: begin
					 row_num <= row_num + 1'd1; // change row_num & row_idx
					 row_idx <= row_idx - 1'd1;
					 
					 speed <= speed - (speed * 25'd1) / 4; // change speed
					 
					 counter <= 10'd0;
				end
				
            WIN: begin
					 win <= 1'd1;
				end
				LOSE: begin
					 lose <= 1'd1;
				end

            default: NS = INIT;
        endcase
    end
end


// State transition logic
always @(posedge clk or negedge rst) begin
    if (rst == 1'b0) begin
        S <= RESET;
    end else begin
        S <= NS;
    end
end


endmodule