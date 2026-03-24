function T_reconstructed = fn_constructTensor(factor_vectors,lambda)

    if ~exist('lambda')
        lambda = 1.0;
    end 


    % 3. Create a rank-1 ktensor object
    % ktensor(lambda, factor_vectors)
    P_component = ktensor(lambda, factor_vectors);
    
    % 4. Convert the ktensor object to a full 3D tensor
    T_reconstructed = full(P_component);

end 