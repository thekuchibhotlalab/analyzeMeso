function [m,T] = sbxalignxMat(b,idx)

if(length(idx)==1)
    
    A = b(:,:,idx(1));
    %A = squeeze(A(1,:,:));
    m = A;
    T = [0 0];
    
elseif (length(idx)==2)
    
    A = b(:,:,idx(1));
    B = b(:,:,idx(2));
    %A = squeeze(A(1,:,:));
    %B = squeeze(B(1,:,:));
    
    [u v] = fftalignZZ(A,B);
    
    Ar = circshift(A,[u,v]);
    m = (Ar+B)/2;
    T = [[u v] ; [0 0]];
    
else
    
    idx0 = idx(1:floor(end/2));
    idx1 = idx(floor(end/2)+1 : end);
    
    [A,T0] = sbxalignxMat(b,idx0);
    [B,T1] = sbxalignxMat(b,idx1);
    
    [u v] = fftalignZZ(A,B);
    
    Ar = circshift(A,[u, v]);
    m = (Ar+B)/2;
    T = [(ones(size(T0,1),1)*[u v] + T0) ; T1];
    
end

% I changed the rounding problem of N/2 when N is odd
    function [u,v] = fftalignZZ(A,B)
        
        N = min(size(A))-80;    % leave out margin
        
        yidx = round(size(A,1)/2)-round(N/2) + 1 : round(size(A,1)/2)+ round(N/2);
        xidx = round(size(A,2)/2)-round(N/2) + 1 : round(size(A,2)/2)+ round(N/2);
        
        A = A(yidx,xidx);
        B = B(yidx,xidx);
        
        C = fftshift(real(ifft2(fft2(A).*fft2(rot90(B,2)))));
        [~,index] = max(C(:));
        [ii jj] = ind2sub(size(C),index);
        
        u = round(N/2)-ii;
        v = round(N/2)-jj;
        
    end
end



