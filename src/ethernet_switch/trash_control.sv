// ############################################################################
//  Module: trash_control
//  Description: Controller for discarding invalid frames and alignment of done
//               control bit, rx_dst_port and output.				  
// ############################################################################

module trash_control (
	input  logic 	clk,
	input  logic  empty,
	input  logic 	reset,
	input  logic  done_in_mac,
	input  logic  done,
	input  logic [1:0]  fcs_error,
	input  logic [2:0]  dst_port,
	input  logic [7:0] din,
	output logic  en,
	output logic  done_out,
	output logic [2:0] rx_dst_port,
	output logic [7:0] out,
	output logic [7:0] trash
  );
  
  
  // ##########################################################################
  //  Internal Signals
  // ##########################################################################

  typedef enum {IDLE, MAC_SUCCESS, FCS_SUCCESS, FCS_FAIL} state_t;
  state_t state, next_state;

  logic done_in_mac_l; 
  logic [2:0] dst_port_d;
  logic [2:0] rx_dst_port_captured;
  logic sel;
  logic sel_d;
  logic [7:0] out_d;
  logic done_d;
  logic buffer;
  
  // ##########################################################################
  //  Combinational Assignments
  // ##########################################################################  
  
  assign out   = (sel_d ? out_d[7:0] : 8'b0);
  assign trash = (!sel_d ? out_d[7:0] : 8'b0);
  assign done_out  = ((done && !done_d) ? 1 : 0);
  
    
  always_comb
  begin
    next_state = state;
    sel = 0;
    en = 0;
    case (state)
      IDLE:
      begin
			if (done_in_mac_l) begin
          next_state = MAC_SUCCESS;
			 end
			 
      end
		MAC_SUCCESS:
		begin
		  if (fcs_error == 2'b10) begin
          next_state = FCS_SUCCESS;
			  sel = 0;
           en = 1; // changed
			 end
        else if (fcs_error == 2'b11) begin
          next_state = FCS_FAIL;
			 end
		end
      FCS_SUCCESS:
      begin
        if (done) begin
			  sel = 0;
           en = 1;
           next_state = IDLE;
		  end else begin
			  sel = 1;
			  en = 1;
		  end
      end

      FCS_FAIL:
      begin
		  if (done) begin
		    sel = 0;
          en = 1;
          next_state = IDLE;
		  end else begin
			 sel = 0;
          en = 1;
		  end		 
      end
    endcase
  end

  // ##########################################################################
  //  Sequential logic
  // ##########################################################################
  
  always_ff @(posedge  clk) begin
	sel_d <= sel;
	done_d <= done;
	out_d <= din;
  end
  
  
  always_ff @(posedge clk) begin
  if (done_in_mac) begin
	done_in_mac_l <= 1;
	dst_port_d <= dst_port;
  end else if (state == MAC_SUCCESS)
	done_in_mac_l <= 0;
  end
  

  always_ff @(posedge clk)
  begin
    if (state == MAC_SUCCESS && next_state == FCS_SUCCESS)
      rx_dst_port_captured <= dst_port_d;
    if (reset)
    begin
      rx_dst_port <= 3'b110; // or some invalid default
    end
	 else if (state == FCS_FAIL)
		rx_dst_port <= 3'b110;
	 else if ( (state == FCS_FAIL || state == FCS_SUCCESS) && next_state == IDLE)
		rx_dst_port <= 3'b110;
	 else if (state == FCS_SUCCESS)
      rx_dst_port <= rx_dst_port_captured;
  end

  always_ff@(posedge clk)
  begin
    if (reset)
      state <= IDLE;
    else
      state <= next_state;
  end



endmodule
