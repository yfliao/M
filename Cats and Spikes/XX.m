function f=XX(whichone)

    switch whichone
        case 'isiplot'
            f=@isiplot;
        case 'neighbourfind'
            f=@neighbourfind;
        case 'isicomp'
            f=@isicomp;
        case 'kerncorr'
            f=@kerncorr;
        case 'kerncorrTrials'
            f=@kerncorrTrials;
    end
    
%     f.isicomp=@isicomp;
%     f.isiplot=@isiplot;
%     f.intercorr=@intercorr;

end

function isiplot(S)

    maxisi=0.2;

    isi=mean(S.isiPairs{1})';
    cv=S.CVdist{1}';
    
    ix=isi<maxisi;
    
    [N C]=hist3([cv(ix) isi(ix)],'edges',{linspace(0,2,30),linspace(0,maxisi,30)});
    
    figure; 
    colormap(gray);
    
    imagesc(C{2},C{1},N);
    set(gca,'ydir','normal');    
    xlabel 'mean isi';
    ylabel 'CV2';
    title(S.name);

end

function intercorr(S)
    
    R=S.trialCorrMat;
    
    C=S.condTrials;
    
    
    


end

function mlists=isicomp(S)
    % Returns a {nNeurons}(nISIx3) cell array of matrices.  The first
    % column is the first of each pair of ISIs.  The second column is the
    % second of each pair (so in most cases, M(i,1)==M(i-1,2).  The only
    % place this doesn't hold is between trials).  The third column
    % represents the interpolated ISIs from different trials (see the
    % report (section "Renewal Processes" for what I mean by this).
    
    
    
    conds=S.condTrials;
    lists=cell(size(S.T,1),length(conds));
    for k=1:size(lists,2)
        for n=1:size(S.T,1)
            lists{n,k}=onecond(S.T(n,conds{k}));
        end
    end

    mlists=cell(size(lists,1),1);
    for i=1:size(lists,1)
        volls=cellfun(@(x)~isempty(x),lists(i,:)');
        mlists{i}=cell2mat(lists(i,volls)');
    end
    
    
    function M=onecond(tim)
        % tim is a cell array of spike times for repetitions of a stimulus.
        %
        % returns a cell array M of 3xN matrices, where the columns of each
        % matrix correspond to first, second, fakefirst isis.
        % adjacent isi pairs, another containing one fake one and one real
        % one, made up of the interpolation of the two nearest surrounding
        % isis from different trials.
        
        % Make a vector of center-time of the isis.
        t=cellfun(@(x)mean([x(1:end-1) x(2:end)],2),tim,'uniformoutput',false);
        
        
        id=cellfun(@(x,i)i*ones(size(x)),t,num2cell(1:length(t)),'uniformoutput',false);
        ix=cellfun(@(x,i)1:length(x),t,'uniformoutput',false);
        isi=cellfun(@(x)diff(x),tim,'uniformoutput',false);
        
        
        timm=cell2mat(t');
        timm=timm(~isnan(timm));
        
        idm=cell2mat(id');
%         ixm=cell2mat(ix);
        isim=cell2mat(isi');
        
        [t,order]=sort(timm);        
        idms=idm(order);                % sorted list of trial ids
%         ixms=ixms(order);               % sorted list of indeces
        isims=isim(order);              % list of isis sorted by time
        
        [pres posts]=neighbourfind(idms);
        
        
        
%         [seconds firsts fakefirsts]=deal(cell(size(isi)));
        M=cell(size(tim));
        for ii=1:length(tim)
            
            [firsts seconds fakefirsts]=getfakes(ii);
            
            M{ii}=[firsts seconds fakefirsts];
            
        end
        
        M=cell2mat(M(:));
        
        function [firsts seconds fakefirsts]=getfakes(aye)
        
            
            ix=find(idms==aye);
            
            
            seconds=isims(ix(2:end));
            
            ix=ix(1:end-1);
            
            firsts=isims(ix);
            ixpre=pres(ix);
            ixpost=posts(ix);
                        
            valid=~isnan(ix(:)) & ~isnan(ixpre(:)) & ~isnan(ixpost(:));
            
            ix=ix(valid);
            ixpre=ixpre(valid);
            ixpost=ixpost(valid);
            
            % check:
            % idms(ix) % should be all i's
            % idms(ixpre) % should be no i's
            % idms(ixpost) % should be no i's
            
            firsts=firsts(valid);
            seconds=seconds(valid);
            
            % Interpolate to get fake-firsts!
            fakefirsts=((t(ixpost)-t(ix)).*isims(ixpre)+(t(ix)-t(ixpre)).*isims(ixpost))./(t(ixpost)-t(ixpre));
                        
            
        end
        
        
    end

    

    
end

function [pres posts]=neighbourfind(x)
    % given vector x, return two vectors of the same size indicating the
    % next neighbours to the left and right that contain DIFFERENT
    % elements.


    r=length(x):-1:1;
    
    [pres posts]=deal(nan(size(x)));
    previous=1;
    next=length(x);
    for i=2:length(x)
         if x(i)~=x(i-1), previous=i-1;end
         pres(i)=previous;
         if x(r(i))~=x(r(i-1)), next=r(i-1);end
         posts(r(i))=next;
         
    end

end

function [C widths]=kerncorr(S,kern,plotit)
    % Takes a time-series matrix.
    %
    % S: SpikeBanhoff Object
    % kern: vector of kernel widths (seconds)
    % 
    % remember:
    % [xcorr(conv(x,h),conv(y,h)) conv(xcorr(x,y),xcorr(h,h))]
    
    if nargin<3, plotit=false; end
    
    
    widths=round(kern/S.resolution);
    
    TS1=S.TS(:,:,1);
    
    TS2=S.TS(:,:,2);
    
%     TS2=TS2(end:-1:1,:);
    
    C=KernCorr(TS1,TS2,widths,40);
    
    
    widths=widths*S.resolution;
end

function [C widths]=kerncorrTrials(S,kern,cellno)
    % Takes a time-series matrix.
    %
    % S: SpikeBanhoff Object
    % kern: vector of kernel widths (seconds)
    % 
    % remember:
    % [xcorr(conv(x,h),conv(y,h)) conv(xcorr(x,y),xcorr(h,h))]
    
    if nargin<3, cellno=1; end
    
    widths=round(kern/S.resolution);
    
    cT=S.condTrials;
    cTcomp=cellfun(@(x)circshift(x,[0 1]),cT,'uniformoutput',false);
    
    ix1=cell2mat(cT);
    ix2=cell2mat(cTcomp);
    
    TS1=S.TS(:,ix1,cellno);
    TS2=S.TS(:,ix2,cellno);
    
%     TS2=TS2(:,randperm(size(TS2,2)));
    
    C=KernCorr(TS1,TS2,widths,40);
    
    widths=widths*S.resolution;

end




