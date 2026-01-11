% Step 1: Generate MFECG signal

function mecg_signal_processing(path, debug, varargin)

basePath = 'C:\Users\keyas\OneDrive\Desktop\Biorithm\Tasks';
if ~exist(basePath, "dir")
    mkdir(basePath);
end
if nargin >2, error('Too many inputs to data generation function'),end
slashchar = char('/'*isunix + '\'*(~isunix));
optargs = {[pwd slashchar] 5};  % default values for input arguments
newVals = cellfun(@(x) ~isempty(x), varargin);
optargs(newVals) = varargin(newVals);
[path,debug] = optargs{:};
if ~strcmp(path(end),slashchar), path = [path slashchar];end

paramorig.fs = 1000; % sampling freq
paramorig.n = 180*paramorig.fs; % number of samples

% electrode config set-up

x = pi/12*[3 4 5 6 7 8 9 10]' - pi/2;
y = 0.5*ones(8,1);
xy = repmat([x y],4,1);
z = repmat([-0.1, -0.2, -0.3, -0.4],8,1); 
z = reshape(z,32,1);
abdmleads = [xy z];
refs = [
    -pi/4 0.5 0.4;
    (5/6-0.5)*pi 0.5 0.4
    ];
paramorig.elpos = [abdmleads; refs];

% setting up base subject
noise_types = {'MA','BW','EM'};
for i = 1:5
    paramst = paramorig;
    paramst.mhr = 80 + 20*randn;
    % stationary baseline generation
    paramst.mtypeacc = 'nsr';
    out = run_ecg_generator(paramst, debug);
    out = clean_compress(out);
    paramst = out.param;
    clear out
    for loop = 1:3
        for SNRmn = 0:3:12
            param = paramst;
            param.SNRmn = SNRmn;
            param.ntype = {noise_types{loop}};
            param.noise_fct = {1 + 0.5*randn};
            param.mres = 0.25 + 0.05*randn;
            out = run_ecg_generator(param, debug);
            out = clean_compress(out);
            fname = sprintf('fecgsyn%02d_snr%02ddB_l%d_c0.mat', i, SNRmn, loop);
            %save(fullfile(basePath, fname), 'out');
            S = load(fullfile(basePath, fname));
            out = S.out;
        end
    end
end
end