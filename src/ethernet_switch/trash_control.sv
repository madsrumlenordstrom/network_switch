
module trash_control (
    input logic clk,
    input logic reset,
    input logic [1:0] fcs_error,
    input logic done,
    input logic [2:0] dst_port,
    output logic en,
    output logic sel,
    output logic [2:0] rx_dst_port
  );

  typedef enum {IDLE, FCS_SUCCESS, FCS_FAIL} state_t;
  state_t state, next_state;

  always_comb
  begin
    next_state = state;
    sel = 0;
    en = 0;
    case (state)
      IDLE:
      begin
        if (fcs_error == 2'b10)
        begin
          next_state = FCS_SUCCESS;
        end
        else if (fcs_error == 2'b11)
        begin
          next_state = FCS_FAIL;
        end
        else
        begin
          next_state = IDLE;
        end
      end

      FCS_SUCCESS:
      begin
        sel = 1;
        en = 1;
        if (done)
          next_state = IDLE;
        else
          next_state = FCS_SUCCESS;

      end

      FCS_FAIL:
      begin
        sel = 0;
        en = 1;
        if (done)
          next_state = IDLE;
        else
          next_state = FCS_FAIL;
      end
    endcase
  end



  always_ff @(posedge clk)
  begin
    if (reset)
    begin
      rx_dst_port <= 3'b110; // or some invalid default
    end
    else if (state == IDLE && next_state == FCS_SUCCESS)
    begin
      rx_dst_port <= dst_port;
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
