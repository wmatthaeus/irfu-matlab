% "Manual" test/demo of using other files in this package. MCALL = Manual call (convention).
%
%
%
% Created 2017-12-15 by Erik Johansson, IRF Uppsala.
%
function data = engine___MCALL
% PROPOSAL: Replace file by proper "demo"?
% PROPOSAL: Replace file by proper "scenario"?
% PROPOSAL: Add title to figures, ~"GCO500".
% PROPOSAL: Good functionality for repeating commanded events.
%=======================================================================================
% Copied from Dropbox/JUICE/Engineering/Budget_Tables/ju_rpwi_tm_power.m 2018-01-02.
%   case 'GCO500'
%     seqIns = [
%       0    2; ...
%       20   4; ...
%       25   2; ...
%       60   4; ...
%       65   2; ...
%       385  4; ...
%       390  2; ...
%       425  4;
%       430  2;
%       960  1; ...
%       ];
%
%     seqRad = [
%       0    6; ...
%       62   7; ...
%       72   6; ...
%       425  8; ...
%       435 6; ...
%       500  7; ...
%       510  6; ...
%       ];
%     case 'GCO500ext_GC0200'
%       modeTitle = 'GCO500ext/GC0200';
%
%       seqIns = [
%         0    3; ...
%         20   4; ...
%         25   3; ...
%         425  4;
%         430  3;
%         960  1; ...
%         ];
%
%       seqRad = [
%         0    6; ...
%         425  8; ...
%         435 6; ...
%         ];
%=======================================================================================

EngineConstants = TM_power_budget.default_constants();

tBegin = 0;
tEnd   = 24*3600;
InitialStorageState    = struct('queuedSurvBytes', 0, 'queuedRichBytes', 0, 'unclasRichBytes', 0);

    function t = convert_table_min2sec(t)
        t(:,1) = cellfun(@(x) (x*60), t(:,1), 'UniformOutput', false);
    end

scenarioNbr = 2;
switch scenarioNbr
    case 1
        %InitialStorageState.unclasRichBytes = 1000*2^20;
        %InitialStorageState.queuedRichBytes = 1000*2^20;
        %InitialStorageState.queuedSurvBytes = 1000*2^20;
        % GCO500. NOTE: Time in minutes but converted into seconds.
        seqIns = convert_table_min2sec({
            0    'In-situ_slow';
            20   'In-situ_burst';
            25   'In-situ_slow';
            60   'In-situ_burst';
            65   'In-situ_slow';
            385  'In-situ_burst';
            390  'In-situ_slow';
            425  'In-situ_burst';
            430  'In-situ_slow';
            960  'In-situ_low';
            });
        seqRad = convert_table_min2sec({
            0    'Radio_full';
            62   'Radio_burst';
            72   'Radio_full';
            425  'Radar_mode-3';
            435  'Radio_full';
            500  'Radio_burst';
            510  'Radio_full';
            });
        seqClassif = convert_table_min2sec({
            9*60, 2*2^20, 0;
            }); 
        DownlinkSeq = struct('beginSec', {0, 16*3600, 24*3600, (24+16)*3600}, 'bandwidthBps', {0, 3*1740, 0, 3*1740});
        tEnd = 1.5*24*3600;
    case 2
        % Informal, manual test case
        EngineConstants.SystemPrps.storageBytes = 100;
        EngineConstants.InsModeDescrList(end+1) = struct('id', 'test_burst_10+20Byph', 'prodSurvBps', 10*8 / 3600, 'prodRichBps', 20*8 / 3600, 'powerWatt', 5);
        seqIns = {
            0   'test_burst_10+20Byph';
            };
        seqRad = {
            0    'Off';
            };
        seqClassif = {
            3*3600,   10,   0;
            4*3600,    0,  10;
            };        
        %seqClassif = cell(0,3);
        DownlinkSeq = struct('beginSec', {0, 6*3600}, 'bandwidthBps', {0, 100*8/3600});
        tEnd = 12*3600;  % Too high value triggers bug.
end
InsModeSeq = struct('beginSec', seqIns(:, 1), 'id', seqIns(:, 2));
RadModeSeq = struct('beginSec', seqRad(:, 1), 'id', seqRad (:, 2));
ClassifSeq = struct('timeSec',  seqClassif(:, 1), 'selectedRichBytes', seqClassif(:, 2), 'rejectedRichBytes', seqClassif(:, 3));
tSec   = tBegin:10:tEnd;
tHours = tSec / 60^2;

CommEvents = [];
CommEvents.InsModeSeq  = InsModeSeq;
CommEvents.RadModeSeq  = RadModeSeq;
CommEvents.ClassifSeq  = ClassifSeq;
CommEvents.DownlinkSeq = DownlinkSeq;
[FinalStorageState, StateArrays, Clf] = TM_power_budget.engine(EngineConstants, InitialStorageState, CommEvents, tBegin, tEnd, tSec);

close all
XTICK = [0:2:48];
data = StateArrays;



if 1
    %=====
    figure
    %=====
    h = subplot(3,1,1);
    plot(h, tHours, data.iInsModeDescr, '.');
    ylabel(h, 'In situ mode')
    set(h, 'XTick', XTICK)
    set(h, 'XTickLabel', [])
    set(h, 'YTick', [min(data.iInsModeDescr):max(data.iInsModeDescr)])
    
    h = subplot(3,1,2);
    plot(h, tHours, data.iRadModeDescr, '.');
    ylabel(h, 'Radio mode')
    set(h, 'XTick', XTICK)
    set(h, 'YTick', [min(data.iRadModeDescr):max(data.iRadModeDescr)])
    
    h = subplot(3,1,3);
    plot(h, tHours, data.powerWatt)
    xlabel('Time [h]')
    ylabel('Power [W]')
    set(h, 'XTick', XTICK)
    
    print('-dpng', sprintf('Fig_modes_%i.png', scenarioNbr))
end

if 1
    %=====
    figure
    %=====
    h = subplot(3,1,1);
    %semilogy(h, tHours, data.prodSurvBps+data.prodRichBps)
    semilogy(h, tHours, [data.prodSurvBps', data.prodRichBps'], '-'); legend('Survey', 'Rich')
    ylabel(h, 'Data production [bits/s]')
    set(h, 'XTickLabel', [])
    set(h, 'XTick', XTICK)
    
    h = subplot(3,1,2);
    usedStorageMiB = data.usedStorageBytes / 2^20;
    storageUnclasRichMiB = data.unclasRichBytes / 2^20 * Clf.rich;
    storageQueuedRichMiB = data.queuedRichBytes / 2^20 * Clf.rich;
    storageQueuedSurvMiB = data.queuedSurvBytes / 2^20 * Clf.surv;
    storageSizeMiB = EngineConstants.SystemPrps.storageBytes / 2^20 * ones(size(usedStorageMiB));
    %plot(h, tHours, [storageSizeMiB; usedStorageMiB; storageQueuedSurvMiB; storageUnclasRichMiB; storageQueuedRichMiB])
    %legend('Storage size', 'Total', 'Queued survey', 'Unclas. rich', 'Queued rich')
    plot(h, tHours, [usedStorageMiB; storageQueuedSurvMiB; storageUnclasRichMiB; storageQueuedRichMiB])
    legend('Total', 'Queued survey', 'Unclas. rich', 'Queued rich')
    ylabel(h, 'Used storage [MiB]')
    set(h, 'XTickLabel', [])
    set(h, 'XTick', XTICK)
    
    h = subplot(3,1,3);
    plot(h, tHours, [data.downlinkBps; data.downlinkSurvBps; data.downlinkRichBps])
    legend('Total', 'Survey', 'Rich')
    ylabel(h, 'Downlink [bits/s]')
    set(h, 'XTickLabel', XTICK)
    set(h, 'XTick', XTICK)
    xlabel(h, 'Time [h]')    
    
    print('-dpng', sprintf('Fig_TM_%i.png', scenarioNbr))
end

end
