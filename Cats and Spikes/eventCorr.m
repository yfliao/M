function c=eventCorr(x,t,ev)
% This is an attempt to evaluate the validity of a rate function x, with
% time vector t, as a generating function for a series of events occurring
% at times ev.
%
% x is a vector representing rate.  
% t is one of the following:
%   - A scalar indicating the time between samples of x
%   - A length(x) vector, indicating the time of samples of x
%   - A length(x)+1 vector, indicating the time bins for which x(t) is true
%

if length(t)==length(x)
   md=median(t);
   t=[t-md/2 t(end)+md];
elseif length(t)==1
   t=linspace(0,t*(length(x)+1),length(x)+1);    
end

y=histc(ev,t(:));

c=corr(x(:),y(1:end-1));