
module trash_control (
    input logic clk,
    input logic reset,
    input logic [1:0] fcs_error,
	 input logic done_in_mac,
    input logic done,
    input logic [2:0] dst_port,
    output logic en,
    output logic sel,
    output logic [2:0] rx_dst_port
  );

  typedef enum {IDLE, MAC_SUCCESS, FCS_SUCCESS, FCS_FAIL} state_t;
  state_t state, next_state;

  
  logic done_in_mac_l; 
  logic [2:0] dst_port_d;
 
  always_ff @(posedge clk) begin
  if (done_in_mac) begin
	done_in_mac_l <= 1;
	dst_port_d <= dst_port;
  end else if (state == MAC_SUCCESS)
	done_in_mac_l <= 0;
  end
  
  
  always_comb
  begin
    next_state = state;
    sel = 0;
    en = 0;
    case (state)
      IDLE:
      begin
			if (done_in_mac_l) begin
			 $display("TRASH_CONTROL: MAC_SUCCESS. rx_dst_port = %0b, en = %0b, sel = %0b", rx_dst_port, en, sel);
          next_state = MAC_SUCCESS;
			 end
			 
      end
		MAC_SUCCESS:
		begin
		  if (fcs_error == 2'b10) begin
		    $display("TRASH_CONTROL: FCS_SUCCESS. rx_dst_port = %0b, en = %0b, sel = %0b", rx_dst_port, en, sel);
          next_state = FCS_SUCCESS;
			  sel = 0;
           en = 0;
			 end
        else if (fcs_error == 2'b11) begin
		    $display("TRASH_CONTROL: FCS_FAIL. rx_dst_port = %0b, en = %0b, sel = %0b", rx_dst_port, en, sel);
          next_state = FCS_FAIL;
			 end
		end
      FCS_SUCCESS:
      begin
		  $display("TRASH_CONTROL: rx_dst_port = %0b, en = %0b, sel = %0b", rx_dst_port, en, sel);
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



  always_ff @(posedge clk)
  begin
    if (reset)
    begin
      rx_dst_port <= 3'b110; // or some invalid default
    end
    else if (state == MAC_SUCCESS && next_state == FCS_SUCCESS)
    begin
      rx_dst_port <= dst_port_d;
    end
	 else if (state == MAC_SUCCESS && next_state == FCS_FAIL)
	 begin
		rx_dst_port <= 3'b110;
	 end
	 else if ( (state == FCS_FAIL || state == FCS_SUCCESS) && next_state == IDLE)
	 begin
		rx_dst_port <= 3'b110;
    end
  end

  always_ff@(posedge clk)
  begin
    if (reset)
    begin
      state <= IDLE;
    end
    else
    begin
      state <= next_state;
    end
  end



endmodule
