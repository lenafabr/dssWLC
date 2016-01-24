%-----------------------------------------------
% Tabulate the dssWLC energetic parameters for del=0.01 to del=1
% Optimizing over alpha to get minimal length scale of accuracy
% delvals = delta values
% Resulting parameters are in: ebvals, gvals, eparvals, eperpvals, etavals,
% alphavals
% Structure factor for dssWLC with delta=delvals(dc), for wavevectors klist(dc,:)
% are in Svals(dc,:)
% Corresponding structure factor for continuous chain is in Splain(dc,:)
% Structure factor errors are in errvals(dc,:)
% Length scales of accuracy are in: lscales
% Results are saved in dssWLCparams.mat
% -----------------------------------------------
LMAX=20;
Ycouple = getYcouple(LMAX,'YcoupleSave.mat')
%load('YcoupleSave.mat','Ycouple')
delvals = logspace(-2,0,30);
nd = length(delvals);
nk = 100;
Ltot = 1000;
cutoff=1e-5;

%LMAXvals = 10*ones(size(delvals));
%LMAXvals(1:10) = 13;

for dc = 1:length(delvals)
    del = delvals(dc);
    %if (del<0.015)
    %    LMAXvals(dc) = 13;
    if(del<0.02)
         LMAXvals(dc) = 12;
    elseif (del<0.04)
        LMAXvals(dc) = 10;
    else
        LMAXvals(dc) = 9;
    end
    LMAX = LMAXvals(dc);
    
    
    klist(dc,:) = logspace(log10(1/del/50),log10(1/del*4),nk);       
   
    if (dc==1) 
        alpharange = [0.3,0.7];
    else
        da = min((delvals(dc)-delvals(dc-1))*100,0.2);
        alpharange = [alphavals(dc-1)-da,alphavals(dc-1)+da];
    end
    
    Nseg =Ltot/del;
    [eb,gam,epar,eperp,eta,alphavals(dc),zetau,delt] = dssWLCcalcparams(del,Nseg,'alpha',alpharange,'LMAX',LMAX,'cutoff',cutoff);
    

    % get plain wlc structure factor
    display('Calculating plain WLC structure factor')
    nseg = Ltot/del;
    I = eye(LMAX+1);
    for kc = 1:nk
        Mplain = shearWLCpropagator(klist(dc,kc),del,1,1,0,0,0,LMAX);
        Mtot = ((nseg+1)*I+Mplain^(nseg+2) - Mplain*(nseg+2))*inv(Mplain-I)^2;
        Splain(dc,kc) = 2*Mtot(1,1)/(nseg+1)^2;
    end
    
    display('Calculating length scale')
    [lscales(dc),params, Svals(dc,:)] =dssWLClengthScale(del,alphavals(dc),Ltot,klist(dc,:),Splain(dc,:),Ycouple,cutoff,LMAX);
    
    %[lscales(dc),params,Svals(dc,:)] = dssWLClengthScale(del,alphavals(dc),Ltot,klist(dc,:),Splain(dc,:),Ycouple,cutoff,LMAX);
    
    errvals(dc,:) = abs(Svals(dc,:)-Splain(dc,:))./Splain(dc,:);
    ebvals(dc) = params(1);
    gvals(dc) = params(2);
    eparvals(dc) = 1/params(3);
    eperpvals(dc) = 1/params(4);
    etavals(dc) = params(5);    
    
    [dc del alphavals(dc) ebvals(dc) eperpvals(dc)]
    
    figure(1)
    semilogx(delvals(1:dc),lscales(1:dc),'.-')
    drawnow
    save('dssWLCparams.mat')
end

%% find energetic params for del>1 using fixed alpha
load('dssWLCparams.mat')
delvals = [delvals,1.1:0.1:4];
ndtot = length(delvals);
alphaset = alphavals(nd);
for dc = nd+1:ndtot
    del = delvals(dc);
    [ebvals(dc),gvals(dc),epari,eperpi,etavals(dc),err,plen] = dssWLCminLpParams(del,alphaset);
    eparvals(dc) = 1/epari; 
    eperpvals(dc) = 1/eperpi;
    alphavals(dc) = alphaset;
    [dc del alphavals(dc) eperpvals(dc)]
end

%%
% find appropriate xiu value
for dc = 1:ndtot
    del = delvals(dc);
    eb = ebvals(dc);
    gam = gvals(dc);
    eperp = eperpvals(dc);
    epar = eparvals(dc);
    eta = etavals(dc);
    
    eperph = eperp + eta^2*eb;
    xir = 1;
    xiulist = logspace(-7,1,50);
    L=del;
    pval = 1;
    tfast = zeros(size(xiulist));
    
    for uc = 1:length(xiulist)
        xiu = xiulist(uc);
        [evals,evecs,pareval] = ssWLCdynamics(eb,gam,epar,eperph,eta,L,xir,xiu,50);
        tfast(uc) = -1/evals(end);
    end
    
    dt = diff(log10(tfast));
    lxiu = interp1(dt,log10(xiulist(1:end-1)),(dt(1)+dt(end))/2);
    zetauvals(dc) = 10^lxiu;
    
    % get the appropriate delt
    deltsclvals(dc) = 0.5/(eperp*gam^2*del);
    
    [dc, del, zetauvals(dc), deltsclvals(dc)]
end

%%
% output a space-delimited look-up table of values

lastind = length(ebvals);
datamat = [delvals(1:lastind)',ebvals(1:lastind)',gvals(1:lastind)',eparvals(1:lastind)',...
    eperpvals(1:lastind)', etavals(1:lastind)',zetauvals(1:lastind)',deltsclvals(1:lastind)'];
dlmwrite('dssWLCparams.txt',datamat,' ');
