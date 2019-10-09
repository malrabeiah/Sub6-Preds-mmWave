function [dataset,options] = dataPrep(fileName,options)
%=========================================================================%
% dataPrep is data preparing function.
% INPUTS:
%	fileName: a single-field data struct with data
%		  file paths.
%	options: a MATLAB structure with the experiment settings
% OUTPUTS:
%	dataset: dataset structure for training and validataion data
%	options: updated options structure
%=========================================================================%

len = length(fileName);
d = {};
loc = {};
labels = {};
for i = 1:len% Normalize data
	load(fileName(i).name)
	x = rawData.channel;
    loc(i) = {rawData.userLoc};
    if strcmp( options.case, 'NLOS' ) 
        labels(i) = {rawData.labels};
    end
	d(i) = {x};
end

dataset.data = d;
dataset.userLoc = loc;
dataset.labels = labels;
clear d loc labels

% Shuffling data:
% ---------------
options.numSamples = size( dataset.data{1},3 );
shuffledInd = randperm(options.numSamples);
options.shuffledInd = shuffledInd;
for i = 1:len
    dataset.data{i} = dataset.data{i}(:,:,shuffledInd);
    dataset.userLoc{i} = dataset.userLoc{i}(:,shuffledInd);
end

% Divide data:
% ------------
numTrain = floor( (1 - options.valPer)*options.numSamples );
options.numOfTrain = numTrain;
options.numOfVal = options.numSamples - options.numOfTrain;
sub6Train = dataset.data{1}(:,:,1:numTrain);% Sub-6 training channels
sub6Val = dataset.data{1}(:,:,numTrain+1:end);% Sub-6 validation channels
sub6TrainLoc = dataset.userLoc{1}(:,1:numTrain);% Sub-6 training user locations
sub6ValLoc = dataset.userLoc{1}(:,numTrain+1:end);% Sub-6 validation user locations
dataset.trainInpLoc = sub6TrainLoc;
dataset.valInpLoc = sub6ValLoc;
if len > 1
    highTrain = dataset.data{2}(:,:,1:numTrain);% High training channels
    highVal = dataset.data{2}(:,:,numTrain+1:end);% High validation channels
    highTrainLoc = dataset.userLoc{2}(:,1:numTrain);% High training user locations
    highValLoc = dataset.userLoc{2}(:,numTrain+1:end);% High validation user locations
    dataset.trainOutLoc = highTrainLoc;
    dataset.valOutLoc = highValLoc;
end

% Compute data statistics:
% ------------------------
abs_value = abs( sub6Train );
max_value(1) = max(abs_value(:));
if len > 1
    abs_value = abs( highTrain );
    max_value(2) = max(abs_value(:));
end
options.dataStats = max_value;

%------------------------------------------------------
% Prepare inputs:
% ---------------
sub6Train = sub6Train/options.dataStats(1);% normalize training data
sub6Val = sub6Val/options.dataStats(1);% normalize validation data
X = zeros(1,1,2*options.inputDim,options.numOfTrain);
Y = zeros(1,1,2*options.inputDim,options.numOfVal);
for i = 1:options.numOfTrain
    x = sub6Train(:,:,i);
    x = x(:, 1:options.numSub);
    x = [real(x);imag(x)];
    X(1,1,:,i) = reshape(x, [numel(x),1]);
end
for i = 1:options.numOfVal
    y = sub6Val(:,:,i);
    y = y(:, 1:options.numSub);
    y = [real(y);imag(y)];
    Y(1,1,:,i) = reshape(y, [numel(y),1]);
end
if options.noisyInput
    % Noise power
    NF=5;% Noise figure at the base station
    Pr=30;
    BW=options.bandWidth*1e9; % System bandwidth in Hz
    noise_power_dB=-204+10*log10(BW/options.numSub)+NF; % Noise power in dB
    noise_power=10^(.1*(noise_power_dB));% Noise power
    Pn_r=(noise_power/options.dataStats(1)^2)/2;
    Pn=Pn_r/(10^(.1*(options.transPower-Pr)));
    % Adding noise
    fprintf(['Corrupting channel measurements with ' num2str(Pn) '-variance Gaussian\n'])
    noise_samples = sqrt(Pn)*randn(size(X));% Zero-mean unity-variance noise
    X = X + noise_samples;
    noise_samples = sqrt(Pn)*randn(size(Y));
    Y = Y + noise_samples;
else
    fprintf('Clean channel measurements')
end
dataset.inpTrain = X;
dataset.inpVal = Y;

%-----------------------------------------------------
% Prepare outputs:
% ----------------


highTrain = highTrain(1:options.numAnt(2),1:options.numSub,:)/options.dataStats(2);
highVal = highVal(1:options.numAnt(2),1:options.numSub,:)/options.dataStats(2);
dataset.highFreqChTrain = highTrain;% 
dataset.highFreqChVal = highVal;% 
W = options.codebook;
value_set = 1:size(W,2);
for i = 1:options.numOfTrain
    H = highTrain(:,:,i);
    rec_power = abs( H'*W ).^2;
    rate_per_sub = log2( 1 + rec_power );
    rate_ave = sum(rate_per_sub,1)/options.numSub;
    [r,ind] = max( rate_ave, [], 2 );
    beam_ind(i,1) = ind;
    max_rate(i,1) = r;
end
dataset.labelTrain = categorical( beam_ind, value_set );
dataset.maxRateTrain = max_rate;
beam_ind = [];
max_rate = [];
for i = 1:options.numOfVal
    H = highVal(:,:,i);
    rec_power = abs( H'*W ).^2;
    rate_per_sub = log2( 1 + rec_power );
    rate_ave = sum(rate_per_sub,1)/options.numSub;
    [r,ind] = max( rate_ave, [], 2 );
    beam_ind(i,1) = ind;
    max_rate(i,1) = r;
end
dataset.labelVal = categorical( beam_ind, value_set );
dataset.maxRateVal = max_rate;
dataset = rmfield(dataset,'data');
dataset = rmfield(dataset,'labels');
dataset = rmfield(dataset, 'userLoc');
