classdef Predictosaurus < Viewer
% This class provides some standard format in which to do all this fancy
% machine learning / prediction stuff on the data.  
%
% It can:
% Take a filecat object, load data from it, and break it up into test and
% training sets.
%
% Use this test/training sets to train some classifier,
% Use said classifier to make predictions about the data.
% 
% Usage:
% P=Predictosaurus; - Make a Predictosaurus Object;
% P.loadfile;       - Load one of the cat experiments
% P.STAtrain(10);   - Train a Spike-Triggered Average kernel, with lag up to 10
% P.NNtrain(10);    - Train a Neural-Net, considereing lag up to 10.
% P.corrcompute;    - Compute/View the success of each algorithm at predicting spike patterns
    
    properties
        
        name;
        
        S;      % Stimulus: rows are frames, columns are dimensions
        Sb;     % Buffered Stimulus: dimension concatenated for different lags
        
        R;      % Respones: rows are frames, columns are neurons
        
        
        ixtrain; % indeces to train on
        ixtest;  % indeces to test onmat(1:end+lags(i),(i-1)*s(2)+1:i*s(2))
        
        ids
        
        C;      % Classifier structure.
        
        
    end
    
    
    methods
        
        function loadfile(A)
            
            FC=FelineFileFinder.go;
            
            switch FC.type
                case 'whitenoise'
                    
                otherwise
                    error('We don''t yet have a way to deal with these "%s" experiments.  Make one!\n',FC.type);
                    return;
            end

            [stim edges]=FC.StimGrab;
            [spikes id]=FC.loadSpikeInfo;

            %% Divide into sets (training/test)

            div=ceil(length(edges)/2);
            
            u=unique(id);
            R_=nan(length(edges)-1,length(u));
            for i=1:length(u)
               garb=histc(spikes(id==u(i)),edges);
               R_(:,i)=garb(1:end-1);
            end
                        
            stim=permute(stim,[3 1 2]);
            A.S=reshape(stim,size(stim,1),[]);
                        
            A.R=R_;            
            A.name=FC.catName;
            
            A.ixtrain=1:div;
            A.ixtest=div+1:size(A.S,1)-1;            
        end
        
        function STAtrain(A,lags)
            
            
            for i=1:size(A.R,2)
                [A.C.STA.RF{i}]=RevCorrGen(A.S(A.ixtrain,:),A.R(A.ixtrain,i),lags);
            end
            
                   
            A.C.STA.name='RevCorr';
            A.C.STA.trainfun=@A.STAtrain;
            A.C.STA.testfun=@A.STAtest;
            
            
            
        end
        
        function pred=STAtest(A,testIX)
            
            if ~exist('testIX','var'), testIX=A.ixtest; end
            
            fprintf('Predicting...Neuron:');
            pred=zeros(length(testIX),size(A.R,2));
            for i=1:size(A.R,2)
                fprintf('%g..',i);
                
                for j=1:size(A.S,2)
                    pred(:,i)=pred(:,i)+conv(A.S(testIX,j),A.C.STA.RF{i}(:,j),'same');
                end      
            end
            disp Done
                        
        end
        
        function NNtrain(A,lags,nhidden)
           % nhidden - number of hidden units
            
            
            A.Sb=A.stim2buf(A.S,lags);
                        
            net=feedforwardnet(nhidden);
            
                        
            
            net=train(net,A.Sb(A.ixtrain,:)',A.R(A.ixtrain,:)');
            
            A.C.NN.net=net;            
            A.C.NN.name='Neural Net';
            A.C.NN.trainfun=@A.NNtrain;
            A.C.NN.testfun=@A.NNtest;
            
        end
                
        function pred=NNtest(A,testIX)
                        
            if ~exist('testIX','var'), testIX=A.ixtest; end
            
            pred=sim(A.C.NN.net,A.Sb(testIX,:)')';
                        
        end
                
        function pred=booties(A,field,n)
            % Generate n predicted signals based on the predictor function
            % descrived in field being applied to randomly permided
            % versions of the test input.
            
            fprintf('Computing Bootstrap Prediction...');
            pred=nan(length(A.ixtest),size(A.R,2),n);
            for i=1:n
                fprintf('%g..',i);
                pred(:,:,i)=A.C.(field).testfun(A.ixtest(randperm(length(A.ixtest))));                
            end
            disp Done
            
        end
                
        function corrcompute(A)
            
            nfake=50;
            
            
            f=fields(A.C);
            
            ST=struct('title',{},'cReal',{},'cFake',{});
            
            for i=1:length(f)
                
                % Actual results, nSamples x nNeurons
                realdeal=A.R(A.ixtest,:);
                      
                % Best Guess, nSamples x nNeurons
                guess=A.C.(f{i}).testfun();
                
                % Bootstraps, nSamples x nNeurons x nBoots
                fakes=A.booties(f{i},nfake);
                                                
                % 1 x nNeurons prediction matrix
                ST(i).cReal=A.groupCorr(realdeal,guess);
                
                % nBoots x nNeurons bootstrapped-prediction matrix
                ST(i).cFake=A.groupCorr(realdeal,fakes);
                
                % Title
                ST(i).title=A.C.(f{i}).name;
                              
            end
            
            % Do the Plot
            nR=length(ST);
            nC=size(A.R,2);
            h=nan(nR,nC);
            for i=1:nR
                for j=1:nC
                    h(i,j)=subplot(nR,nC,nC*(i-1)+j);
                    
                    hist(ST(i).cFake(:,j),10);
                    addlines(ST(i).cReal(j));
                                        
                    title([ST(i).title ': Neuron ' num2str(j)]);
                    xlabel('Correlation');
                    legend(['Shuffled (' num2str(nfake) ')'],'Prediction');
                end
            end
            
            U=UIlibrary;
            arrayfun(@(i)U.linkmaxes(h(:,i),'x'),1:size(h,2));
            
        end
        
        
        
        
    end  
    
    methods (Static)
        
        function mat=stim2buf(stim,nlags)
            % Take an input matrix (time x dimensions), and expand it so
            % that dimensions include the lags around it, making a matrix
            % of size time x dimensions*(2*nlags+1)
            
            
            s=size(stim);
            mat=zeros(s(1),s(2)*(2*nlags+1));
            
            lags=-nlags:nlags;
            
            for i=1:length(lags)
                
                if lags(i)<0
                    mat(1:end+lags(i),(i-1)*s(2)+1:i*s(2)) = stim(-lags(i)+1:end,:);
                else
                    mat(lags(i)+1:end,(i-1)*s(2)+1:i*s(2)) = stim(1:end-lags(i),:);
                end
               
            end
            
        end
        
        function c=groupCorr(x,y)
            % Correlates columns of x with columns of y.  If one of x,y is
            % 3-D, all c will return an d3 x d2 matrix, where the d's are
            % the depths in that dimension.
            
            
            
            if ndims(x)>ndims(y);
                % Swap em
                z=y;
                y=x;
                x=z;                
            end
                                    
            c=nan(size(y,3),size(y,2));
            
            for j=1:size(y,3)
                c(j,:)=arrayfun(@(i)corr(x(:,i),y(:,i,j)),1:size(x,2));
            end
                            
            
        end
        
    end
    
    
end