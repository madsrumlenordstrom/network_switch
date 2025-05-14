%% Parameters
SIZE = 32;
INPUT = 8;

ZERO_VEC      = zeros(SIZE-1, 1); 
IDENTITY_MATRIX = eye(SIZE-1);
ZERO_MATRIX   = zeros(SIZE, INPUT); 
POLY          = [0 0 0 0 0 1 0 0 1 1 0 0 0 0 0 1 0 0 0 1 1 1 0 1 1 0 1 1 0 1 1 1];
ZERO_MATRIX_1 = zeros(INPUT, SIZE);
ZERO_MATRIX_1(1,1) = 1;
ROT_MATRIX = cat(2, cat(1, zeros(1,INPUT-1), eye(INPUT-1)), zeros(INPUT,1));
ROT_MATRIX(1, INPUT) = 1;

UPPER_HALF = cat(2, cat(1, cat(2, ZERO_VEC, IDENTITY_MATRIX), flip(POLY)), ZERO_MATRIX);
LOWER_HALF = cat(2, ZERO_MATRIX_1, ROT_MATRIX);

% The overall transformation matrix has (SIZE+INPUT) rows and columns.
TOTAL_SIZE = SIZE + INPUT;
A = cat(1, UPPER_HALF, LOWER_HALF);
A_MATRIX = A^INPUT


fprintf('// ================== SystemVerilog Equations from A_MATRIX ==================\n');
for col = 1:SIZE
    outIndex = col - 1;   % fcs_reg[outIndex] in 0-based indexing
    terms = {};

    % old fcs_reg bits => columns 1..32
    for row = 1:SIZE
        if A_MATRIX(row, col) == 1
            terms{end+1} = sprintf('fcs_reg[%d]', row-1);
        end
    end

    % data_processed bits => columns 33..40
    for row = SIZE+1 : (SIZE + INPUT)
        if A_MATRIX(row, col) == 1
            terms{end+1} = sprintf('data_processed[%d]', row - (SIZE+1));
        end
    end

    % If no terms, it's just 0
    if isempty(terms)
        eq_str = '0';
    else
        eq_str = strjoin(terms, ' ^ ');
    end

    fprintf('fcs_reg[%d] <= %s;\n', outIndex, eq_str);
end
fprintf('// ========================================================================\n');