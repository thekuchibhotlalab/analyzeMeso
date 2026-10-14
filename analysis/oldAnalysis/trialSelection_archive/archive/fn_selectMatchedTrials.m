% HELPTER FUNCTION -- MATCH RT IN TRIALTYPEINFO
function [selected_flags, selected_counts, new_means] = fn_selectMatchedTrials(rt_cell, options)
    % Selects a subset of trials from a cell matrix to match the global average reaction time.
    %
    % INPUTS:
    %   rt_cell - A cell matrix where each element is a vector of reaction times.
    %   options - A struct with fields:
    %             .min_trials_percentage (e.g., 0.5) - Minimum percentage of trials to keep.
    %             .tolerance (e.g., 0.05) - Allowed fractional deviation from the global mean.
    %
    % OUTPUTS:
    %   selected_flags  - Cell array of the same size as rt_cell, containing logical
    %                     vectors indicating which trials were selected.
    %   selected_counts - Matrix of the same size, showing the number of selected trials.
    %   new_means       - Matrix of the same size, showing the new mean reaction time.

    [rows, cols] = size(rt_cell);

    % --- Step 1: Calculate Global Mean Reaction Time ---
    % Concatenate all non-empty trial vectors into a single large vector
    all_trials = cat(1, rt_cell{:});
    if isempty(all_trials)
        error('Input cell array contains no data.');
    end
    global_mean_rt = mean(all_trials);
    fprintf('Global mean reaction time across all trials: %.2f ms\n', global_mean_rt);

    % Define the acceptable range for the new means
    tolerance_value = global_mean_rt * options.tolerance;
    lower_bound = global_mean_rt - tolerance_value;
    upper_bound = global_mean_rt + tolerance_value;
    fprintf('Target range for new means: [%.2f, %.2f] ms\n\n', lower_bound, upper_bound);

    % --- Step 2: Initialize Output Variables ---
    selected_flags = cell(rows, cols);
    selected_counts = NaN(rows, cols);
    new_means = NaN(rows, cols);

    % --- Step 3: Iterate Through Each Condition and Select Trials ---
    for r = 1:rows
        for c = 1:cols
            trials_vector = rt_cell{r, c};

            % Skip if the cell is empty (NaN condition)
            if isempty(trials_vector)
                continue;
            end

            n_original = length(trials_vector);
            min_trials_to_keep = ceil(n_original * options.min_trials_percentage);

            % Keep track of which trials are currently selected
            current_selection_indices = 1:n_original;
            current_trials = trials_vector;
            
            % --- Iterative Removal Loop ---
            % This loop removes one trial at a time to bring the cell's mean
            % closer to the global mean, until it's within tolerance or the
            % minimum number of trials is reached.
            while true
                current_mean = mean(current_trials);
                
                % Check stopping conditions
                if length(current_trials) <= min_trials_to_keep
                    % Stop if we've hit the minimum trial count
                    break; 
                end
                if current_mean >= lower_bound && current_mean <= upper_bound
                    % Stop if the mean is within the target range
                    break;
                end

                % Decide which trial to remove
                if current_mean > global_mean_rt
                    % If mean is too high, removing the LARGEST value will help most.
                    [~, idx_to_remove] = max(current_trials);
                else
                    % If mean is too low, removing the SMALLEST value will help most.
                    [~, idx_to_remove] = min(current_trials);
                end
                
                % Remove the trial from our current selection
                current_trials(idx_to_remove) = [];
                current_selection_indices(idx_to_remove) = []; % Keep original indices aligned
            end

            % --- Step 4: Store the Results for this Condition ---
            % Create the final logical flag vector
            flags = false(1, n_original);
            flags(current_selection_indices) = true;
            
            selected_flags{r, c} = flags;
            selected_counts(r, c) = length(current_trials);
            new_means(r, c) = mean(current_trials);
        end
    end
end