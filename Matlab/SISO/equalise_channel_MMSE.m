    % Function:    equalised_symbols_zf
% Description: equalise the channel effecct on the received signal
% Inputs:      z_est                - received subframe without demodulation signal in one row
%              ce_tot                - estimated channel
% Outputs:     equalised symbols

%edit: 25/1/2017
%By  : Ahmed Moustafa

function equalised_symbols = equalise_channel_MMSE(z_est, ce_tot, N0)
    
    [N_ant, M_ap_symb] = size(ce_tot);
    
    noise_matrix = N0*eye(M_ap_symb);
    T = ce_tot' * ce_tot;
    G = inv(T+noise_matrix) * ce_tot';
    G = G.';

    for n=0:M_ap_symb-1
            equalised_symbols(n+1) = z_est(n+1)*G(n+1);
    end
    
end