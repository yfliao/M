function [c tvec]=slidewincorr1(x,y,win)
% 1-D sliding window correlation coefficient.  For a version including 
% lags, checkout slidewincorr.
%
% Usage:
% [c tvec]slidewincorr1(x,y,win)
%
% Inputs
% x,y are input vectors of same length
% win is the window length (integer, >0, <length(x))
% 
% Outputs
% c - vector of correlation coeffs, length(x)-win
% tvec - vector of window center positions

% SCRAPPED- FOR loop seems to be unavoidable.


if ~isvector(x)||~isvector(y)
    error('x and y must be vectors');
end
    
x=x(:);
y=y(:);


[mn mag]=meanmag(x,win);
[mn mag]=meanmag(y,win);
prd=movsum(x.*y,win);


c=






end




function [mn mag]=meanmag(x,n)
    % Computes roaming mean and magnitude of roaming-mean subtracted
    % vector.  Useful as a pre-step to xcorr measurements.
    
    mn=movsum(x,n)/n;
    
    if nargin>1
        mag=nan(1, length(mn));
        for i=1:length(mn)
            mag(i)=sqrt(sum((x(i:i+n-1)-mn(i)).^2));
        end
    end


end


function x=movsum(x,n)
% Retuurns a block of length length(x)-n+1
% It's just the moving sum on the last n samples.

        
    x=cumsum(x);
        
    x=x(n:end)-[0; x(1:end-n)];

end