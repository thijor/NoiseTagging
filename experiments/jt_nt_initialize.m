function ev = jt_nt_initialize(ev)

%% Main

ev.cfg.main.subject             = bs_gbv(ev,'RunMode','Subject');
txt = textscan(ev.cfg.main.subject,'%c%d');
if isempty(txt{2}); id=1; else id=txt{2}; end
ev.cfg.main.subjectid           = id;
ev.cfg.main.block               = bs_gbv(ev,'Experiment','Block');
ev.cfg.main.stage               = bs_gbv(ev,'Experiment','Stage');
ev.cfg.main.initializetime      = str2double(bs_gbv(ev,'ExperimentDefinitionVars','InitializeTime'));
ev.cfg.main.pretrialtime        = str2double(bs_gbv(ev,'ExperimentDefinitionVars','PreTrialTime'));
ev.cfg.main.trialtime           = str2double(bs_gbv(ev,'ExperimentDefinitionVars','TrialTime'));
ev.cfg.main.segmenttime         = str2double(bs_gbv(ev,'ExperimentDefinitionVars','SegmentTime'));
ev.cfg.main.posttrialtime       = str2double(bs_gbv(ev,'ExperimentDefinitionVars','PostTrialTime'));
ev.cfg.main.intertrialtime      = str2double(bs_gbv(ev,'ExperimentDefinitionVars','InterTrialTime'));
ev.cfg.main.terminatetime       = str2double(bs_gbv(ev,'ExperimentDefinitionVars','TerminateTime'));
ev.cfg.main.maxtime             = str2double(bs_gbv(ev,'ExperimentDefinitionVars','MaxTime'));
ev.cfg.main.maxtrials           = str2double(bs_gbv(ev,'ExperimentDefinitionVars','MaxTrials'));
ev.cfg.main.maxsegments         = round(ev.cfg.main.trialtime/ev.cfg.main.segmenttime);
ev.cfg.main.fs                  = bs_gbv(ev,'eeg','pp.downsample.targetFs');

%% Dataproc

ev.cfg.dataproc.maxsegments     = ev.cfg.main.maxsegments;
ev.cfg.dataproc.capfile         = bs_gbv(ev,'eeg','Cap');
ev.cfg.dataproc.datamarker      = bs_gbv(ev,'DataprocVars','DataMarker');
ev.cfg.dataproc.datasource      = bs_gbv(ev,'DataprocVars','DataSource');
ev.cfg.dataproc.markertype      = bs_gbv(ev,'DataprocVars','MarkerType');
ev.cfg.dataproc.reref           = bs_gbv(ev,'DataprocVars','Rereference');
ev.cfg.dataproc.bands           = bs_gbv(ev,'DataprocVars','FilterBands');
ev.cfg.dataproc.chnthres        = bs_gbv(ev,'DataprocVars','ChnThreshold');
ev.cfg.dataproc.trlthres        = bs_gbv(ev,'DataprocVars','TrlThreshold');
ev.cfg.dataproc.dobufferpreproc = bs_gbv(ev,'DataprocVars','DoBufferPreproc');
ev.cfg.dataproc.doretrain       = bs_gbv(ev,'DataprocVars','DoRetrain');
ev.cfg.dataproc.dosavetrialclassifier = bs_gbv(ev,'DataprocVars','DoSaveTrialClassifier');

%% Stimuli

% Settings
ev.cfg.stimulation.outputdevice = bs_gbv(ev,'StimulationVars','OutputDevice');
ev.cfg.stimulation.rate         = bs_gbv(ev,'StimulationVars','StimulationRate');
ev.cfg.stimulation.synchronous  = bs_gbv(ev,'StimulationVars','Synchronous');
ev.cfg.stimulation.trainclasses = bs_gbv(ev,'StimulationVars','NumTrainClasses');
ev.cfg.stimulation.traincodes   = bs_gbv(ev,'StimulationVars','TrainCodes');
ev.cfg.stimulation.trainsubset  = bs_gbv(ev,'StimulationVars','TrainSubset');
ev.cfg.stimulation.trainlayout  = bs_gbv(ev,'StimulationVars','TrainLayout');
ev.cfg.stimulation.testclasses  = bs_gbv(ev,'StimulationVars','NumTestClasses');
ev.cfg.stimulation.testcodes    = bs_gbv(ev,'StimulationVars','TestCodes');
ev.cfg.stimulation.testsubset   = bs_gbv(ev,'StimulationVars','TestSubset');
ev.cfg.stimulation.testlayout   = bs_gbv(ev,'StimulationVars','TestLayout');

% Set stimulation
if any(strcmpi(ev.cfg.main.stage,{'train','calibrate'}))
    ev.cfg.stimulation.codesfile = ev.cfg.stimulation.traincodes;
    if isnumeric(ev.cfg.stimulation.trainsubset)
        ev.cfg.stimulation.subset = ev.cfg.stimulation.trainsubset;
    else 
        switch ev.cfg.stimulation.trainsubset
            case 'no'
                ev.cfg.stimulation.subset = 1:ev.cfg.stimulation.trainclasses;
            case 'default_36'
                in = load('nt_subset.mat');
                ev.cfg.stimulation.subset = in.subset;
            case 'default_36_oc'
                in = load('nt_subset.mat');
                ev.cfg.stimulation.subset = in.subset(ev.cfg.main.subjectid);
            otherwise
                error('Unknown trainsubset: %s.',ev.cfg.stimulation.trainsubset);
        end
    end
    if isnumeric(ev.cfg.stimulation.trainlayout)
        ev.cfg.stimulation.layout = ev.cfg.stimulation.trainlayout;
    else
        switch ev.cfg.stimulation.trainlayout
            case 'no'
                ev.cfg.stimulation.layout = 1:ev.cfg.stimulation.trainclasses;
            case 'default_36'
                in = load('nt_layout.mat');
                ev.cfg.stimulation.layout = in.layout;
            otherwise
                error('Unknown trainlayout: %s.',ev.cfg.stimulation.trainlayout);
        end
    end
else
    ev.cfg.stimulation.codesfile = ev.cfg.stimulation.testcodes;
    ev.cfg.stimulation.subset = ev.classifier.subset.U;
    ev.cfg.stimulation.layout = ev.classifier.layout.U;
end
if ~strcmp(ev.cfg.main.stage,'calibrate')
    in = load(ev.cfg.stimulation.codesfile);
    nbits = ev.cfg.main.trialtime*ev.cfg.stimulation.rate;
    codes = repmat(in.codes,[ceil(nbits/size(in.codes,1)) 1]);
    ev.stimuli = codes(1:nbits,ev.cfg.stimulation.subset(ev.cfg.stimulation.layout))';
end

%% Classifier 

noyes = {'no','yes'};
ev.cfg.classifier.user              = ev.cfg.main.subject;
ev.cfg.classifier.verbosity         = bs_gbv(ev,'ClassifierVars','Verbosity');
ev.cfg.classifier.fs                = ev.cfg.main.fs;
ev.cfg.classifier.capfile           = ev.cfg.dataproc.capfile;
ev.cfg.classifier.nclasses          = ev.cfg.stimulation.testclasses;
ev.cfg.classifier.method            = bs_gbv(ev,'ClassifierVars','Method');
ev.cfg.classifier.supervised        = bs_gbv(ev,'ClassifierVars','Supervised');
ev.cfg.classifier.synchronous       = noyes{ev.cfg.stimulation.synchronous+1};
ev.cfg.classifier.runcorrelation    = bs_gbv(ev,'ClassifierVars','RunCorrelation');
ev.cfg.classifier.cca               = bs_gbv(ev,'ClassifierVars','Cca');
ev.cfg.classifier.L                 = bs_gbv(ev,'ClassifierVars','L');
ev.cfg.classifier.delay             = bs_gbv(ev,'ClassifierVars','Delay');
ev.cfg.classifier.event             = bs_gbv(ev,'ClassifierVars','Event');
ev.cfg.classifier.component         = bs_gbv(ev,'ClassifierVars','Component');
ev.cfg.classifier.lx                = bs_gbv(ev,'ClassifierVars','LambdaX');
ev.cfg.classifier.ly                = bs_gbv(ev,'ClassifierVars','LambdaY');
ev.cfg.classifier.lxamp             = bs_gbv(ev,'ClassifierVars','LambdaXAmp');
ev.cfg.classifier.lyamp             = bs_gbv(ev,'ClassifierVars','LambdaYAmp');
ev.cfg.classifier.lyperc            = bs_gbv(ev,'ClassifierVars','LambdaYPerc');
ev.cfg.classifier.modelonset        = bs_gbv(ev,'ClassifierVars','ModelOnset');
ev.cfg.classifier.subsetV           = ev.cfg.stimulation.subset;
ev.cfg.classifier.subsetU           = ev.cfg.stimulation.testsubset;
ev.cfg.classifier.layoutV           = ev.cfg.stimulation.layout;
ev.cfg.classifier.layoutU           = ev.cfg.stimulation.testlayout;
ev.cfg.classifier.neighbours        = bs_gbv(ev,'ClassifierVars','Neighbours');
ev.cfg.classifier.stopping          = bs_gbv(ev,'ClassifierVars','Stopping');
ev.cfg.classifier.segmenttime       = ev.cfg.main.segmenttime;
ev.cfg.classifier.maxsegments       = ev.cfg.main.maxsegments;
ev.cfg.classifier.forcestop         = bs_gbv(ev,'ClassifierVars','ForceStop');
ev.cfg.classifier.accuracy          = bs_gbv(ev,'ClassifierVars','Accuracy');
ev.cfg.classifier.bound             = bs_gbv(ev,'ClassifierVars','Bound');
ev.cfg.classifier.shifttime         = bs_gbv(ev,'ClassifierVars','ShiftTime');
ev.cfg.classifier.shifttimemax      = bs_gbv(ev,'ClassifierVars','ShiftTimeMax');
ev.cfg.classifier.transfermodel     = bs_gbv(ev,'ClassifierVars','TransferModel');
ev.cfg.classifier.transferfile      = bs_gbv(ev,'ClassifierVars','TransferFile');
ev.cfg.classifier.transfercount     = bs_gbv(ev,'ClassifierVars','TransferCount');
ev.cfg.classifier.covfilter         = bs_gbv(ev,'ClassifierVars','CovFilter');
ev.cfg.classifier.preinvert         = bs_gbv(ev,'ClassifierVars','PreInvert');
ev.cfg.classifier.frstaccuracy      = bs_gbv(ev,'ClassifierVars','FirstAccuracy');
ev.cfg.classifier.frstminsegment    = bs_gbv(ev,'ClassifierVars','FirstMinSegment');
ev.cfg.classifier.freshcalibration  = bs_gbv(ev,'ClassifierVars','FreshCalibration');