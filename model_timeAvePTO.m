function  varargout = model_timeAvePTO(x,par,iPTO,outputConfig)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% model_timeAvePTO.m function m-file
% AUTHORS:
% Jeremy Simmons (email: simmo536@umn.edu)
% University of Minnesota
% Department of Mechanical Engineering
%
% CREATION DATE:
% 12/31/2021
%
% PURPOSE:
% This function implements several models for wave-powered reverse osmosis.
% The models are simple, static models with that include two-way coupling 
% with the time-averaged simulation results of a WEC; the coupling is set 
% up such that the reaction force from the PTO is a function of the average
% WEC speed (or power absortion) and the average WEC speed (or power 
% absorption) is function of the reaction torque from the PTO.
%
% FILE DEPENDENCY: 
%
% UPDATES:
% 12/31/2021 - created.
% 08/22/2022 - Added constraint on WEC-driven torque to be less than
% max for supplied torque-power data.
%
% Copyright (C) 2022  Jeremy W. Simmons II
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program. If not, see <https://www.gnu.org/licenses/>.
%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    power = @(T_c) interp1(par.T_c_data(par.SS,:),...
                par.PP_w_data(par.SS,:),T_c,'spline');

    switch iPTO
        case {2, 4}
            duty = x(2);
        case {1, 3}
            duty = 1;
    end

    switch iPTO
        case {1 2}            
            p_f = x(1);
            p_h = p_f;
            dp_w = p_h - par.p_c;
            T_c = (duty*par.D_w)*dp_w/par.eta_w;
            PP_w = power(T_c);
            q_perm = (par.S_ro*par.A_w)*(p_f-par.p_osm);
            q_w = PP_w*par.eta_w/dp_w;
            PP_gen = (q_w - q_perm) ...
                *(p_f-par.p_c)*par.eta_pm*par.eta_gen;
            PP_c = q_perm*par.p_c/(par.eta_c*par.eta_m);
            
        case {3 4}
            p_h = x(1);
            dp_w = p_h - par.p_c;
            T_c = (par.D_w)*dp_w/par.eta_w;
            PP_w = power(T_c);
            dp_w = T_c*par.eta_w/par.D_w;
            q_w = PP_w*par.eta_w/dp_w;
            q_perm = q_w/duty;
            p_f = q_perm/(par.S_ro*par.A_w) + par.p_osm;
            PP_gen = q_perm*(((1-duty)*par.p_c + duty*p_h) - p_f)...
                *par.eta_pm*par.eta_gen;
            PP_c = q_perm*par.p_c/(par.eta_c*par.eta_m);
            
    end
    
    switch outputConfig
        case 1
            varargout = {q_perm};
        case 2
            % constraints c <= 0, ceq = 0
            c(1) = PP_c - PP_gen;
            c(2) = p_f - par.p_f_bnds(2);
            c(3) = par.p_f_bnds(1) - p_f;
            c(4) = T_c - par.T_c_data(par.SS,end);
            ceq = [];
            varargout = {c,ceq};
        case 3
            varargout = {q_perm, T_c, PP_w};
    end

end