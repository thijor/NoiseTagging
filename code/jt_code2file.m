function jt_code2file(codes,fname,format)
%jt_code2file(codes,fname,format)
%Converts a matrix of codes to a file.
%
% INPUT
%   codes  = [m n] m samples of n codes
%   fname  = [str] file name to write to
%   format = [str] file format: dlm|txt|xls

codes = double(codes);

switch format
    case 'dlm'
        dlmwrite([fname '.txt'],codes,'delimiter','\t');
    case 'txt'
        fid = fopen([fname '.txt'],'wt');
        for i = 1:size(codes,1)
            fprintf(fid,'%i\t',codes(i,:));
            fprintf(fid,'\n');
        end
        fclose(fid);
    case 'xls'
        xlswrite([fname '.xls'],codes);
end