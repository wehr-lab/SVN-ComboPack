function [oepathname isrecording]=getOEdatapath(expdate, session, filenum)
%get OE data path from exper
%usage: [oepathname isrecording]=getOEdatapath(expdate, session, filenum)
    gorawdatadir(expdate, session, filenum)
    expfilename=sprintf('%s-%s-%s-%s.mat', expdate, whoami, session, filenum);
    expstructurename=sprintf('exper_%s', filenum);
    if exist(expfilename)==2 %try current directory
        load(expfilename)
        exp=eval(expstructurename);
        try
        isrecording=exp.openephyslinker.param.isrecording.value;
        oepathname=exp.openephyslinker.param.oepathname.value;
        catch
            isrecording=0;
            oepathname='linker was not recording';
        end
    else %try data directory
        cd ../../..
        try
            cd(sprintf('Data-%s-backup',user))
            cd(sprintf('%s-%s',expdate,user))
            cd(sprintf('%s-%s-%s',expdate,user, session))
        end
        if exist(expfilename)==2
            load(expfilename)
            exp=eval(expstructurename);
            isrecording=exp.openephyslinker.param.isrecording.value;
            oepathname=exp.openephyslinker.param.oepathname.value;
        else
            fprintf('\ncould not find exper structure. Cannot get OE file info.')
        end
    end
    if strcmp(oepathname(1),'c')
oepathname(1)='d';
    end
