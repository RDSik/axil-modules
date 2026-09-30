/* verilator lint_off TIMESCALEMOD */
module round_robin_arbiter #(
    parameter int MASTER_NUM = 4
) (
    input  logic                          clk_i,
    input  logic                          rst_i,
    input  logic                          ack_i,
    input  logic [        MASTER_NUM-1:0] req_i,
    output logic [        MASTER_NUM-1:0] grant_o,
    output logic [$clog2(MASTER_NUM)-1:0] indx_o
);

    localparam int PTR_WIDTH = $clog2(MASTER_NUM);
    
    logic [    MASTER_NUM-1:0] req_shift;
    logic [    MASTER_NUM-1:0] grant_shift;

    logic [(MASTER_NUM*2)-1:0] req_shift_double;
    logic [(MASTER_NUM*2)-1:0] grant_shift_double;

    logic [     PTR_WIDTH-1:0] ptr;
    logic [     PTR_WIDTH-1:0] ptr_next;

    assign req_shift_double   = {req_i, req_i} >> ptr;
    assign req_shift          = req_shift_double[MASTER_NUM-1:0];

    assign grant_shift_double = {grant_shift, grant_shift} << ptr;
    assign grant_o            = grant_shift_double[(MASTER_NUM*2)-1:MASTER_NUM];

    logic req_detect;
    logic grant_detect;

    always_comb begin
        grant_shift = '0;
        req_detect  = '0;
        for (int i = 0; i < MASTER_NUM; i++) begin
            if (req_shift[i] & ~req_detect) begin
                grant_shift[i] = 1'b1;
                req_detect     = 1'b1;
            end
        end
    end

    always_comb begin
        grant_detect = '0;
        ptr_next     = ptr;
        indx_o       = '0;
        for (int i = 0; i < MASTER_NUM; i++) begin
            if (grant_o[i] & ~grant_detect) begin
                indx_o = PTR_WIDTH'(i);
                if (i == MASTER_NUM - 1) begin
                    ptr_next = '0;
                end else begin
                    ptr_next = PTR_WIDTH'(i + 1);
                end
                grant_detect = 1'b1;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            ptr <= '0;
        end else if (ack_i) begin
            ptr <= ptr_next;
        end
    end

endmodule
module round_robin_arbiter #(
    parameter int MASTER_NUM = 4
) (
    input  logic                          clk_i,
    input  logic                          srst_i,
    input  logic                          ack_i,
    input  logic [        MASTER_NUM-1:0] req_i,
    output logic [        MASTER_NUM-1:0] grant_o,
    output logic                          grant_valid_o,
    output logic [$clog2(MASTER_NUM)-1:0] indx_o
);

    localparam int PTR_WIDTH = $clog2(MASTER_NUM);

    logic [    (MASTER_NUM*2)-1:0] req_shift_double;
    logic [        MASTER_NUM-1:0] req_shift;

    logic [$clog2(MASTER_NUM)-1:0] grant_indx;
    logic [    (MASTER_NUM*2)-1:0] grant_shift_double;
    logic [        MASTER_NUM-1:0] grant_shift;
    logic [        MASTER_NUM-1:0] grant;
    logic                          grant_valid;

    logic [         PTR_WIDTH-1:0] ptr;
    logic [         PTR_WIDTH-1:0] ptr_next;

    assign req_shift_double   = {req_i, req_i} >> ptr;
    assign req_shift          = req_shift_double[MASTER_NUM-1:0];

    assign grant_shift_double = {grant_shift, grant_shift} << ptr;
    assign grant              = grant_shift_double[(MASTER_NUM*2)-1:MASTER_NUM];
    assign grant_valid        = |grant;

    logic req_detect;
    logic grant_detect;

    always_comb begin
        grant_shift = '0;
        req_detect  = '0;
        for (int i = 0; i < MASTER_NUM; i++) begin
            if (req_shift[i] & ~req_detect) begin
                grant_shift[i] = 1'b1;
                req_detect     = 1'b1;
            end
        end
    end

    always_comb begin
        grant_detect = '0;
        ptr_next     = ptr;
        grant_indx   = '0;
        for (int i = 0; i < MASTER_NUM; i++) begin
            if (grant_o[i] & ~grant_detect) begin
                grant_indx = PTR_WIDTH'(i);
                if (i == MASTER_NUM - 1) begin
                    ptr_next = '0;
                end else begin
                    ptr_next = PTR_WIDTH'(i + 1);
                end
                grant_detect = 1'b1;
            end
        end
    end

    lgoic [$clog2(MASTER_NUM)-1:0] locked_indx;
    logic [        MASTER_NUM-1:0] locked_grant;
    logic                          locked;
    logic                          acknowledge;

    assign acknowledge = ack_i & grant_valid_o;

    always_ff @(posedge clk_i) begin
        if (srst_i) begin
            locked <= 1'b0;
        end else begin
            if (acknowledge) begin
                locked <= 1'b0;
            end else if (~locked & grant_valid) begin
                locked <= 1'b1;
            end

        end
    end

    always_ff @(posedge clk_i) begin
        if (srst_i) begin
            locked_indx  <= '0;
            locked_grant <= '0;
        end else if (~locked & grant_valid) begin
            locked_grant <= grant;
            locked_indx  <= grant_indx;
        end
    end

    always_comb begin
        if (locked) begin
            grant_o       = locked_grant;
            indx_o        = locked_indx;
            grant_valid_o = |(locked_grant & req_i);
        end else begin
            grant_o       = grant;
            indx_o        = grant_indx;
            grant_valid_o = grant_valid;
        end
    end

    always_ff @(posedge clk_i) begin
        if (srst_i) begin
            ptr <= '0;
        end else if (acknowledge) begin
            ptr <= ptr_next;
        end
    end

endmodule
