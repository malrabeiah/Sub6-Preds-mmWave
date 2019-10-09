%================================================================================%
% Main script for training and testing a DL model to predict mmWave (28   
% GHz) beam indecies from sub-6 GHz channels. The script assumes the data
% provided in the form of two (.mat) files: 
%   - dataFile1: Sub-6 data
%   - dataFile2: 28GHz data
% Each .mat is a data structure with the following fields: channels and user 
% locations. Channels should be arranged into a 3D array with the following 
% dimensions: # of antenna elements X # of sub-carriers X # of users. User 
% locations should be a 2D array with the folllowing dimensions: 3 X # of users. 
%  The "options" structure provide control over the type of experiment to run.
% -------------------------------------------------------------------------------
% Author: 
% Muhammad Alrabeiah,
% Sept 2019.
%
%=================================================================================%
clc
clear
close all

tx_power = [-37.3375  -32.3375  -27.3375  -22.3375  -17.3375  -12.3375   -7.3375];
snr_db = [-10.0586   -5.0586   -0.0586    4.9414    9.9414   14.9414   19.9414];
num_ant = [4];% number of sub-6 antennas
num_ant_mm = [64];
accuracy_top1 = zeros(length(num_ant_mm), length(tx_power));
accuracy_top3 = zeros(length(num_ant_mm), length(tx_power));
ave_rate_top1 = zeros(length(num_ant_mm), length(tx_power));
ave_rate_top3 = zeros(length(num_ant_mm), length(tx_power));
ave_upper = zeros(length(num_ant_mm), length(tx_power));
options.figCount = 0;
options.type = 'MLP1';
options.case = 'LOS';
options.expTag = [options.type '_' options.case '_variableSNR'];
options.top_n = 3;
options.valAccuracy = zeros(length(num_ant_mm),length(tx_power));
options.normMethod = 'perDataset';
options.gpuInd = 1;
fprintf('Experiment: %s\n', options.expTag);

for ant = 1:length(num_ant_mm)% number of antennas to loop over
	fprintf('Number of sub-6 antennas: %d and number of mmWave antennas: %d\n', num_ant(1), num_ant_mm(ant))
    [W,~] = UPA_codebook_generator(1,num_ant_mm(ant),1,1,1,1,0.5);% Beam codebook
	options.codebook = W;
	options.numAnt = [num_ant(1), num_ant_mm(ant)];
	options.numSub = 32;
	options.inputDim = options.numSub*options.numAnt(1);
	options.valPer = 0.3;
	options.inputSize = [1,1,2*options.inputDim];
	options.noisyInput = true;
	options.bandWidth = 0.02;
	options.dataFile1 ='';% The path to the sub-6 data file
    options.dataFile2 ='';% The path to the mmWave data file
    if isempty(options.dataFile1)
		error('Please provide a sub-6 data file!');
	elseif isempty(options.dataFile2)
		error('Please provide a mmWave data file');
	end
	% tarining settings
	options.solver = 'sgdm';
	options.learningRate = 1e-1;
	options.momentum = 0.9;
	options.schedule = 80;
	options.dropLR = 'piecewise';
	options.dropFactor = 0.1;
	options.maxEpoch = 100;
	options.batchSize = 1000;
	options.verbose = 1;
	options.verboseFrequency = 50;
    options.valFreq = 100;
	options.shuffle = 'every-epoch';
	options.weightDecay = 1e-4;
	options.progPlot = 'none';
	for p = 1:length(tx_power)

        fprintf('Pt = %4.2f (dBm)\n', tx_power(p))

		% Prepare dataset:
		% ----------------

		options.transPower = tx_power(p);
		fileName = struct('name',{options.dataFile1,...
		                          options.dataFile2});
		[dataset,options] = dataPrep(fileName, options);% dataset is a 1x2 structure array

		% Build network:
		% --------------

		net = buildNet(options);

		% Train network:
		% --------------

		trainingOpt = trainingOptions(options.solver, ...
		    'InitialLearnRate',options.learningRate,...
		    'LearnRateSchedule',options.dropLR, ...
		    'LearnRateDropFactor',options.dropFactor, ...
		    'LearnRateDropPeriod',options.schedule, ...
		    'MaxEpochs',options.maxEpoch, ...
		    'L2Regularization',options.weightDecay,...
		    'Momentum',options.momentum,...
		    'Shuffle', options.shuffle,...
		    'MiniBatchSize',options.batchSize, ...
		    'ValidationData', {dataset(1).inpVal, dataset(1).labelVal},...
            'ValidationFrequency', options.valFreq,...
		    'Verbose', options.verbose,...
		    'verboseFrequency', options.verboseFrequency,...
		    'Plots',options.progPlot);

		gpuDevice(options.gpuInd)
		[trainedNet, trainInfo] = trainNetwork(dataset.inpTrain, dataset.labelTrain,net,trainingOpt);
		options.valAccuracy(ant,p) = trainInfo.ValidationAccuracy(end);

		% Test network:
		% -------------

		X = dataset.inpVal;
        Y = single( dataset.labelVal );
        [pred,score] = trainedNet.classify(X);
        pred = single( pred );
        highFreqCh = dataset.highFreqChVal;
        hit = 0;
        for user = 1:size(X,4)
            % Top-1 average rate
            H = highFreqCh(:,:,user);
            w = W(:,pred(user));
            rec_power = abs( H'*w ).^2;
            rate_per_sub = log2( 1 + rec_power );
            rate_top1(user) = sum(rate_per_sub)/options.numSub;

            % Top-3 accuracy
            rec_power = abs( H'*W ).^2;
            rate_per_sub = log2( 1 +rec_power );
            ave_rate_per_beam = mean( rate_per_sub, 1);
            [~,ind] = max(ave_rate_per_beam);% the best beam
            [~,sort_ind] = sort( score(user,:), 'descend' );
            three_best_beams = sort_ind(1:options.top_n);
            if any( three_best_beams == ind )
                hit = hit + 1;
            end

            % Top-3 average rate
            rec_power = abs( H'*W(:,three_best_beams) ).^2;
            rate_per_sub = log2( 1+rec_power );
            ave_rate_per_beam = mean(rate_per_sub,1);
            rate_top3(user) = max( ave_rate_per_beam );

        end
        accuracy_top1(ant,p) = options.valAccuracy(ant,p);
        accuracy_top3(ant,p) = 100*(hit/options.numOfVal);
        ave_rate_top1(ant,p) = mean(rate_top1);
        ave_rate_top3(ant,p) = mean(rate_top3);
        ave_upper(ant,p) = mean(dataset.maxRateVal);
        fprintf('Top-1 and Top-3 rates: %5.3f & %5.3f. Upper bound: %5.3f\n', ave_rate_top1(ant,p),ave_rate_top3(ant,p),...
                     mean( dataset.maxRateVal ) );
        fprintf('Top-1 and Top-3 Accuracies: %5.3f%% & %5.3f%%\n', accuracy_top1(ant,p),accuracy_top3(ant,p));

	end

end

% Save performance variables
variable_name = [options.expTag '_results'];
save(variable_name,'accuracy_top1','accuracy_top3','ave_rate_top1','ave_rate_top3','ave_upper')
options.figCount = options.figCount+1;
fig1 = figure(options.figCount);
plot(snr_db, ave_rate_top1(1,:), '-b',...
     snr_db, ave_rate_top3(1,:), '-r',...
     snr_db, ave_upper(1,:), '-.k');
xlabel('SNR (dB)');
ylabel('Spectral Efficiency (bits/sec/Hz)');
grid on
legend('Top-1 achievable rate','Top-3 achievable rate','Upper bound')
name_file = ['ansVSrate_' options.expTag];
saveas(fig1,name_file)

