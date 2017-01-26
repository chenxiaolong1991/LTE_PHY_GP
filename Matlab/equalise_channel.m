% Function:    equalise_channel
% Description: equalise the channel effecct on the received signal
% Inputs:      z_est                - received subframe without demodulation signal in one row
%              ce_tot                - estimated channel
%              dmrs_0                - generated DMRS number 1
%              dmrs_1                - generated DMRS number 2
%              M_pusch_sc            - number of subcarriers allocated to ue
%              N_symbs_per_slot      - number of symbols per slot
% Outputs:     equalised symbols

%edit: 25/1/2017
%By  : Ahmed Moustafa

function equalised_symbols = equalise_channel(z_est, ce_tot)
    [N_ant, M_ap_symb] = size(h);
    for n=0:M_ap_symb-1
            equalised_symbols(n+1) = z_est(n+1)/ce_tot(n+1);
    end

end