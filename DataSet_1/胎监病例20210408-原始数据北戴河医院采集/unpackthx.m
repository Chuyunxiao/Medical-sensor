% ����պ�ϼ�洢��ԭʼ����,��ʾ��
% ԭʼ���ݸ�ʽΪ�� 
%   0xff 0x01 0xfc 0x00 0x06 0x00 => ��ͷ:0xff,̥��:0x01fc,����:0x0006;���:0x00.
clear all;
close all;

[NameFileEcg, PathFileEcg] =uigetfile('*.dat','file ECG');
fid = fopen([PathFileEcg NameFileEcg],'r');
[x,len] = fread(fid,'uint8');
fclose(fid);

maxsmpcnt = floor(len / 6);     %ԭʼ����ͷ�ļ��������Ĳ������� 6:һ��6���ֽڣ�������ͷ��
%maxsmpcnt = min(maxsmpcnt, 4000*60);   
datadpl = zeros(1, maxsmpcnt);      %̥��
datatoco = zeros(1, maxsmpcnt);     %����
datamove = zeros(1, maxsmpcnt);     %�ֶ�̥�����

tmppack = zeros(1,5);
realsmpcnt = 0;           %����������������Ϊ2000Hz
error = 0;
for i = 1 : len-5
    if x(i) == 255    %��ͷ
        realsmpcnt = realsmpcnt + 1;
        tmppack(1) = x(i+1);tmppack(2) = x(i+2); tmppack(3) = x(i+3); tmppack(4) = x(i+4); tmppack(5) = x(i+5);
        datadpl(realsmpcnt) = bitor(bitshift(bitshift(tmppack(1),-1),8), bitor(bitshift(bitand(1,tmppack(1)),7),tmppack(2)));
        datatoco(realsmpcnt) = bitor(bitshift(bitshift(tmppack(3),-1),8), bitor(bitshift(bitand(1,tmppack(3)),7),tmppack(4)));
        datamove(realsmpcnt) = tmppack(5);
        if tmppack(1) == 255 || tmppack(2) == 255 || tmppack(3) == 255 || tmppack(4) == 255 || tmppack(5) == 255
            error = error +1;
        end
    end
end
   
NameFileEcg = replace(NameFileEcg, 'dat', 'fhr');
fid = fopen([PathFileEcg NameFileEcg],'r');
[hr,len] = fread(fid,'int16');
fclose(fid);

figure
subplot(411)
plot(hr); name = replace(NameFileEcg, '.fhr','');title(name);
subplot(412)
plot(datadpl);
subplot(413)
plot(datatoco);
subplot(414)
plot(datamove);