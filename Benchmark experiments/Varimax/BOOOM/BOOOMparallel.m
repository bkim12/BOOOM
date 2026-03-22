function [O_opt, fval, comp_time] = BOOOMparallel(objFun, O_initial, MaxTime, MaxRuns, MaxIter, sInitial, rho, TolFun1, TolFun2, phi, DisplayUpdate, DisplayEvery, PrintStepSize, PrintSolution)
% BOOOM: Blackbox optimization over ortogonal matrices



%Parameters defualt settings
if nargin < 3 || isempty(MaxTime), MaxTime = 3600; end
if nargin < 4 || isempty(MaxRuns), MaxRuns = 1000; end
if nargin < 5 || isempty(MaxIter), MaxIter = 10000; end
if nargin < 6 || isempty(sInitial), sInitial = 1; end
if nargin < 7 || isempty(rho), rho = 2; end
if nargin < 8 || isempty(TolFun1), TolFun1 = 10^(-6); end
if nargin < 9 || isempty(TolFun2), TolFun2 = 10^(-10); end
if nargin < 10 || isempty(phi), phi = 10^(-20); end
if nargin < 11 || isempty(DisplayUpdate), DisplayUpdate = 1; end
if nargin < 12 || isempty(DisplayEvery), DisplayEvery = 2; end
if nargin < 13 || isempty(PrintStepSize), PrintStepSize = 1; end
if nargin < 14 || isempty(PrintSolution), PrintSolution = 0; end


thetaInitial = pi*sInitial;
nrows = size(O_initial,1);
[pairs_i, pairs_j] = find(triu(ones(nrows), 1)); % Upper triangular indices
num_rotations = length(pairs_i);
total_moves = 2 * num_rotations;
change_locs = ceil((1:total_moves) / 2);
signs = (-1).^((1:total_moves) + 1);

% Sliced arrays — vectorized from original pairs for 'parfor'
pairs_i_idx_all = pairs_i(change_locs);
pairs_j_idx_all = pairs_j(change_locs);


% objFun
% Fun = @(O) objFun(O);
RunSolnArray = nan(MaxRuns,1);
last_toc = 0;
break_now = 0;
fprintf('========================= BOOOM Starts =======================\n')
tic;

for iii = 1:MaxRuns
    theta = thetaInitial;
    %fprintf('=> Maxtime for the current session: %2f \n', MaxTime);
    %fprintf('nargin = %d\n', nargin);
    if(iii == 1)
        O_updated = O_initial;
    end
    for i = 1:MaxIter
        if(toc > MaxTime)
            break_now = 1;
            fprintf('=> As requested, BOOOM has been terminated after %.2f seconds :( \n', MaxTime);
            fprintf('\n')
            break;
        end
        O = O_updated;
        InitialValue = objFun(O);

        
        %%%% Time display %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        toc_now = toc;
        if(DisplayUpdate == 1)
            if(toc_now - last_toc > DisplayEvery)
                if(PrintStepSize == 1)
                    fprintf('=> Executing Run: %d, iter: %d, current obj. fun. value: %d, current log10(step-size/pi): %.2f. \n', iii, i, InitialValue, log10(theta/pi));
                else
                    fprintf('=> Executing Run: %d, iter: %d, current obj. fun. value: %d. \n', iii, i, InitialValue);
                end
                last_toc = toc_now;
            end
        end

        FunValsMoves = zeros(1, total_moves);

        parfor idx = 1:total_moves
            O_rotated = create_premultiplied_matrix(O, pairs_i_idx_all(idx), pairs_j_idx_all(idx), signs(idx) * theta);
            value = objFun(O_rotated);

            FunValsMoves(idx) = value;
        end

        [minValue, minIndex] = min(FunValsMoves);
        
        CurrentValue = InitialValue;

        if minValue < InitialValue
            base_idx = ceil(minIndex / 2);              % Recover original rotation index
            sign = (-1)^(minIndex + 1);                 % +1 for odd index, -1 for even
            theta_signed = sign * theta;
        
            O_updated = create_premultiplied_matrix(O, pairs_i(base_idx), pairs_j(base_idx), theta_signed);
            CurrentValue = objFun(O_updated);
        end

        if (i > 1)
            if(abs(CurrentValue - InitialValue) < TolFun1)
                if(theta > phi)
                    theta = theta/rho;
                else
                    break;
                end
            end
        end
        %fprintf('\n')
        %fprintf('=> Objective before update: %.2f, Objective after update: %.2f. \n',InitialValue, CurrentValue);
        
        % [InitialValue, CurrentValue]
        
    end
    RunSolnArray(iii) = CurrentValue;
    
    
    if(iii > 1)
        if(abs(RunSolnArray(iii) - RunSolnArray(iii-1)) < TolFun2)
            break;
        end
    end
    if(break_now == 1)
        break;
    end
end



O_opt = O_updated;
fval = objFun(O_opt);
comp_time = toc;

% Final solution
if(PrintSolution == 1)
    fprintf('\n')
    fprintf('=> Final BOOOM solution is: \n');
    disp(O_updated)
end

fprintf('\n')
fprintf('=> Obj. fun. value at BOOOM minima: %d \n',CurrentValue);
fprintf('\n')
fprintf('=> Total time taken: %.4f secs.\n',comp_time);

fprintf('xxxxxxxxxxxxxxxxxxxxxx BOOOM ends xxxxxxxxxxxxxxxxxxxxxxxxxx\n')


end

